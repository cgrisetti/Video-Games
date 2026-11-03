## The Landblock streaming controller (10_WORLD_ARCHITECTURE.md §3 and §4.1).
##
## Five times a second it takes every human player's position (all
## split-screen views, and network peers' players too, so every peer streams
## the same chunks) and works out each chunk's Chebyshev distance to the
## nearest of them. That union decides each chunk's layers, with a wider
## radius to unload than to load so nobody on a seam makes chunks thrash:
##   UNLOADED -> HORIZON_HLOD   (Layer 1: terrain, the HLOD proxy, occluders)
##            -> VISUAL_CLUTTER (Layer 2: instanced clutter)
##            -> FULL_GAMEPLAY  (Layer 3: the landblock's walls, camps,
##                               chests, shrines, gate, desk and boss marker,
##                               and the terrain collider; Layer 4: navigation)
##
## Heavy work stays off the main thread: terrain and clutter are computed on
## worker threads, landblock scenes and HLOD meshes stream in through
## ResourceLoader's threaded loading (like a WoW .adt; every request is
## collected, even at exit), and landblocks are instantiated on workers. The main thread only
## attaches the results, through `_instantiation_queue`, spending at most
## FRAME_BUDGET_USEC (2 ms) a frame; big containers go in child by child.
## A chunk's HLOD proxy hides the moment its gameplay layer is in and shows
## again when it leaves.
##
## Each stateful entity (in the "landblock_entities" group) is bound to the
## level's WorldStateDB the moment it's attached, so a camp cleared, a chest
## opened, a shrine resting or a gate raised before the chunk unloaded is
## still that way when it streams back in. The level hears about entities
## through entity_attached / entity_detached.
##
## prime() loads the gameplay around a spot at once (the level's start, a
## teleport home), like a loading screen; everything else streams.
class_name WorldGridManager
extends Node3D

signal chunk_state_changed(chunk: Vector2i, new_state: int)
signal entity_attached(entity: Node, chunk: Vector2i)
signal entity_detached(entity: Node, chunk: Vector2i)

enum ChunkState { UNLOADED, HORIZON_HLOD, VISUAL_CLUTTER, FULL_GAMEPLAY }

const STATE_NAMES: Array[String] = ["UNLOADED", "HORIZON_HLOD", "VISUAL_CLUTTER", "FULL_GAMEPLAY"]
const ENTITY_GROUP: StringName = &"landblock_entities"
## A plain container with more nodes than this under it goes in child by child.
const PIECE_NODE_LIMIT: int = 24
## Instantiate landblock scenes on a worker thread (false: on the main thread, in one go).
const THREADED_INSTANTIATION: bool = true

## Which world this streams (WorldGridConfig.use_layout picks it before anything streams).
@export var layout_id: StringName = DoverslapLayout.LAYOUT_ID
## The level's store of entity state (set before the first prime).
var world_state: WorldStateDB
## Positions streamed around besides the party's (none in play).
var extra_focus: Array[Vector3] = []
## True when the Terrain3D GDExtension draws the ground (Mode A).
var use_terrain3d: bool = false
## Draw the ground with the built-in meshes even when Terrain3D is installed
## (tests, comparisons; `--terrain=builtin` on the command line sets it too).
static var force_builtin_terrain: bool = false
## The most main-thread time one frame's queue took (microseconds), and the last frame's.
var peak_frame_usec: int = 0
var last_frame_usec: int = 0
## The longest single queued step so far (microseconds).
var peak_step_usec: int = 0

var _chunks: Dictionary[Vector2i, Chunk] = {}
var _instantiation_queue: Array[Callable] = []
var _jobs: Array[StreamJob] = []
var _bakes: Array[ChunkNavBuilder.BakeJob] = []
## Landblock scenes and HLOD meshes, once loaded (small; kept for the session).
var _resource_cache: Dictionary[String, Resource] = {}
## Paths being loaded in the background, and the callbacks waiting on each.
var _resource_waiters: Dictionary[String, Array] = {}
var _focus_chunks: Array[Vector2i] = []
var _heartbeat_left: float = 0.0
var _chunks_root: Node3D
var _badge: WorldTelemetryBadge
var _terrain3d: Node3D
## Terrain3D regions changed and its textures need one refresh (queued once).
var _terrain3d_dirty: bool = false


## One Landblock's runtime record.
class Chunk:
	extends RefCounted

	var coord: Vector2i
	var root: Node3D
	var state: int = 0
	var terrain_data: Dictionary = {}
	var terrain: Node3D
	var hlod: MeshInstance3D
	var hlod_mesh: ArrayMesh
	var clutter: Node3D
	var ground: StaticBody3D
	var gameplay: Node3D
	var nav_region: NavigationRegion3D
	var nav_ready: bool = false
	var entities: Array[Node] = []
	var has_terrain: bool = false
	var has_clutter: bool = false
	var has_gameplay: bool = false
	var terrain_pending: bool = false
	var clutter_pending: bool = false
	var gameplay_pending: bool = false
	## Bumped when a layer unloads, so its in-flight jobs and queued attaches are dropped.
	var terrain_generation: int = 0
	var clutter_generation: int = 0
	var gameplay_generation: int = 0

	func _init(at: Vector2i) -> void:
		coord = at


## Work done on a worker thread: a chunk's terrain or clutter data, or a landblock instance.
class StreamJob:
	extends RefCounted

	enum Kind { TERRAIN, CLUTTER, INSTANCE }

	var kind: Kind
	var chunk: Vector2i
	var generation: int
	var task_id: int = -1
	var scene: PackedScene
	## A terrain job builds a Terrain3D region instead of a mesh.
	var terrain3d: bool = false
	var result: Variant

	func _init(job_kind: Kind, at: Vector2i, layer_generation: int) -> void:
		kind = job_kind
		chunk = at
		generation = layer_generation

	func run() -> void:
		match kind:
			Kind.TERRAIN:
				result = WorldGridManager.terrain_data_for(chunk, terrain3d)
			Kind.CLUTTER:
				result = WorldGridConfig.layout.build_clutter_data(chunk)
			Kind.INSTANCE:
				result = scene.instantiate()


func _ready() -> void:
	WorldGridConfig.use_layout(layout_id)
	_chunks_root = Node3D.new()
	_chunks_root.name = "Chunks"
	add_child(_chunks_root)
	for coord: Vector2i in WorldGridConfig.all_chunks():
		_chunks[coord] = Chunk.new(coord)
	ChunkNavBuilder.configure_map(get_world_3d().navigation_map)
	if OS.get_cmdline_user_args().has("--terrain=builtin"):
		force_builtin_terrain = true
	if LandblockTerrain.terrain3d_available() and not force_builtin_terrain:
		_terrain3d = LandblockTerrain.make_terrain3d(self)
		add_child(_terrain3d)
		LandblockTerrain.configure_terrain3d(_terrain3d)
		use_terrain3d = true


func _exit_tree() -> void:
	# Worker tasks must be waited on, and nodes they made freed.
	for job: StreamJob in _jobs:
		if job.task_id >= 0:
			WorkerThreadPool.wait_for_task_completion(job.task_id)
		if job.result is Node and not (job.result as Node).is_inside_tree():
			(job.result as Node).free()
	_jobs.clear()
	for bake: ChunkNavBuilder.BakeJob in _bakes:
		bake.wait()
	_bakes.clear()
	# Every background load is collected, or the loader keeps hold of it past exit.
	for path: String in _resource_waiters:
		ResourceLoader.load_threaded_get(path)
	_resource_waiters.clear()
	_instantiation_queue.clear()


func _process(delta: float) -> void:
	_heartbeat_left -= delta
	if _heartbeat_left <= 0.0:
		_heartbeat_left = WorldGridConfig.STREAM_HEARTBEAT
		update_streaming()
		_scale_ai_ticks()
		_follow_with_clipmap()
	_poll_jobs()
	_drain_queue()


## Terrain3D's detailed LODs centre on Player 1 (one clipmap; other split-screen views see its coarser rings).
func _follow_with_clipmap() -> void:
	if _terrain3d == null:
		return
	LandblockTerrain.keep_terrain3d_untextured_view_off(_terrain3d)
	var target: Node3D = self
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.is_local_player() and not member.is_companion:
			target = member
			break
	if _terrain3d.get(&"clipmap_target") != target:
		_terrain3d.set(&"clipmap_target", target)


# --- Deciding ---------------------------------------------------------------

## Works out every chunk's layers from where the players are now (the heartbeat calls this).
func update_streaming() -> void:
	var focus: Array[Vector2i] = _gather_focus_chunks()
	if not focus.is_empty():
		_focus_chunks = focus
	if _focus_chunks.is_empty():
		return
	for coord: Vector2i in _chunks:
		_advance(_chunks[coord], WorldGridConfig.min_chebyshev_to_focuses(coord, _focus_chunks))


## Where to stream around: every human player (local or remote), plus extra_focus.
func focus_positions() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_companion:
			points.append(member.global_position)
	points.append_array(extra_focus)
	return points


func _gather_focus_chunks() -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	for point: Vector3 in focus_positions():
		var chunk: Vector2i = WorldGridConfig.world_to_chunk(point)
		if not chunks.has(chunk):
			chunks.append(chunk)
	return chunks


## The layers `chunk` should have at distance `distance`, with hysteresis, and the loads and unloads to get there.
func _advance(chunk: Chunk, distance: int) -> void:
	var keep_gameplay: bool = chunk.has_gameplay or chunk.gameplay_pending
	var wants_gameplay: bool = distance <= WorldGridConfig.LOAD_GAMEPLAY_RADIUS or (keep_gameplay and distance <= WorldGridConfig.UNLOAD_GAMEPLAY_RADIUS)
	var keep_clutter: bool = chunk.has_clutter or chunk.clutter_pending
	var wants_clutter: bool = wants_gameplay or distance <= WorldGridConfig.LOAD_CLUTTER_RADIUS \
		or (keep_clutter and distance <= WorldGridConfig.UNLOAD_CLUTTER_RADIUS)
	var keep_terrain: bool = chunk.has_terrain or chunk.terrain_pending
	var wants_terrain: bool = wants_clutter or distance <= WorldGridConfig.LOAD_HLOD_RADIUS \
		or (keep_terrain and distance <= WorldGridConfig.UNLOAD_HLOD_RADIUS)
	if not wants_gameplay and keep_gameplay:
		_unload_gameplay(chunk)
	if not wants_clutter and keep_clutter:
		_unload_clutter(chunk)
	if not wants_terrain and keep_terrain:
		_unload_terrain(chunk)
	if wants_terrain and not keep_terrain:
		_start_terrain(chunk)
	if wants_clutter and not keep_clutter:
		_start_clutter(chunk)
	if wants_gameplay and not keep_gameplay:
		_start_gameplay(chunk)


# --- Loading ------------------------------------------------------------------

func _start_terrain(chunk: Chunk) -> void:
	chunk.terrain_pending = true
	var generation: int = chunk.terrain_generation
	var job: StreamJob = StreamJob.new(StreamJob.Kind.TERRAIN, chunk.coord, generation)
	job.terrain3d = use_terrain3d
	_run_job(job)
	var on_hlod: Callable = func(resource: Resource) -> void:
		if generation == chunk.terrain_generation:
			chunk.hlod_mesh = resource as ArrayMesh
			_instantiation_queue.append(func() -> void: _attach_hlod(chunk, generation))
	_request(WorldGridConfig.layout.hlod_path(chunk.coord), on_hlod)


func _start_clutter(chunk: Chunk) -> void:
	chunk.clutter_pending = true
	_run_job(StreamJob.new(StreamJob.Kind.CLUTTER, chunk.coord, chunk.clutter_generation))


## Gameplay needs the terrain's data (for its collider); it carries on from there once that's in.
func _start_gameplay(chunk: Chunk) -> void:
	chunk.gameplay_pending = true
	if chunk.has_terrain:
		_continue_gameplay(chunk)


func _continue_gameplay(chunk: Chunk) -> void:
	var generation: int = chunk.gameplay_generation
	_instantiation_queue.append(func() -> void: _attach_ground(chunk, generation))
	var path: String = WorldGridConfig.layout.landblock_path(chunk.coord)
	if path == "" or not ResourceLoader.exists(path):
		_instantiation_queue.append(func() -> void: _finish_gameplay(chunk, generation))
		return
	var on_landblock: Callable = func(resource: Resource) -> void:
		if not chunk.gameplay_pending or generation != chunk.gameplay_generation:
			return
		if resource is PackedScene:
			_instantiate(chunk, resource as PackedScene)
		else:
			_instantiation_queue.append(func() -> void: _finish_gameplay(chunk, generation))
	_request(path, on_landblock)


## Loads `path` in the background (once, however many ask) and calls
## `on_loaded` with it on the main thread (null if it failed); straight away if it's in already.
func _request(path: String, on_loaded: Callable) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	if _resource_cache.has(path):
		on_loaded.call(_resource_cache[path])
		return
	if not _resource_waiters.has(path):
		_resource_waiters[path] = []
		ResourceLoader.load_threaded_request(path)
	(_resource_waiters[path] as Array).append(on_loaded)


func _instantiate(chunk: Chunk, scene: PackedScene) -> void:
	var job: StreamJob = StreamJob.new(StreamJob.Kind.INSTANCE, chunk.coord, chunk.gameplay_generation)
	job.scene = scene
	if THREADED_INSTANTIATION:
		_run_job(job)
	else:
		job.run()
		_on_job_done(job)


func _run_job(job: StreamJob) -> void:
	job.task_id = WorkerThreadPool.add_task(job.run, false, "Landblock %s" % WorldGridConfig.chunk_key(job.chunk))
	_jobs.append(job)


func _poll_jobs() -> void:
	for path: String in _resource_waiters.keys():
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		var waiters: Array = _resource_waiters[path]
		_resource_waiters.erase(path)
		var resource: Resource = ResourceLoader.load_threaded_get(path)
		if resource == null:
			push_warning("WorldGridManager: couldn't load %s" % path)
		else:
			_resource_cache[path] = resource
		for waiter: Variant in waiters:
			(waiter as Callable).call(resource)
	var bake_index: int = 0
	while bake_index < _bakes.size():
		if _bakes[bake_index].finish_if_done():
			_bakes.remove_at(bake_index)
		else:
			bake_index += 1
	var index: int = 0
	while index < _jobs.size():
		var job: StreamJob = _jobs[index]
		if not WorkerThreadPool.is_task_completed(job.task_id):
			index += 1
			continue
		WorkerThreadPool.wait_for_task_completion(job.task_id)
		_jobs.remove_at(index)
		_on_job_done(job)


func _on_job_done(job: StreamJob) -> void:
	var chunk: Chunk = _chunks[job.chunk]
	match job.kind:
		StreamJob.Kind.TERRAIN:
			if job.generation != chunk.terrain_generation:
				return
			var data: Dictionary = job.result
			var generation: int = job.generation
			# The ground mesh, then the HLOD proxy and the rest, as separate steps.
			_instantiation_queue.append(func() -> void: _attach_terrain(chunk, data, generation, false))
			_instantiation_queue.append(func() -> void: _attach_horizon(chunk, generation))
		StreamJob.Kind.CLUTTER:
			if job.generation != chunk.clutter_generation:
				return
			var data: Dictionary = job.result
			var generation: int = job.generation
			_instantiation_queue.append(func() -> void: _attach_clutter(chunk, data, generation))
		StreamJob.Kind.INSTANCE:
			var landblock: Node3D = job.result as Node3D
			if job.generation != chunk.gameplay_generation or not chunk.gameplay_pending:
				if landblock != null:
					landblock.free()
				return
			_queue_landblock(chunk, landblock)


## The terrain data a chunk needs: the mesh (or with `terrain3d`, its Terrain3D
## region), plus, where the world is walked, the collider, its solid props and
## the navigation source (pure; worker-safe).
static func terrain_data_for(chunk: Vector2i, terrain3d: bool = false) -> Dictionary:
	var layout: WorldLayout = WorldGridConfig.layout
	var walkable: bool = layout.has_collision(chunk)
	var data: Dictionary = LandblockTerrain.build_chunk_data(chunk, walkable, terrain3d)
	if walkable:
		data["solids"] = layout.solid_pieces(chunk)
	if layout.has_navigation(chunk):
		data["nav_faces"] = layout.nav_faces(chunk)
	return data


# --- Attaching (inside the frame budget) ----------------------------------------

func _drain_queue() -> void:
	var start: int = Time.get_ticks_usec()
	while not _instantiation_queue.is_empty():
		var step: Callable = _instantiation_queue.pop_front()
		var step_start: int = Time.get_ticks_usec()
		step.call()
		peak_step_usec = maxi(peak_step_usec, Time.get_ticks_usec() - step_start)
		if Time.get_ticks_usec() - start >= WorldGridConfig.FRAME_BUDGET_USEC:
			break
	last_frame_usec = Time.get_ticks_usec() - start
	peak_frame_usec = maxi(peak_frame_usec, last_frame_usec)


func _chunk_root(chunk: Chunk) -> Node3D:
	if chunk.root == null:
		chunk.root = Node3D.new()
		chunk.root.name = "Chunk_%s" % WorldGridConfig.chunk_key(chunk.coord)
		_chunks_root.add_child(chunk.root)
	return chunk.root


## Layer 1: the ground (the chunk's mesh, or its Terrain3D region), and with
## `with_horizon` the HLOD proxy, occluders and landmark in the same step.
func _attach_terrain(chunk: Chunk, data: Dictionary, generation: int, with_horizon: bool) -> void:
	if generation != chunk.terrain_generation:
		return
	var holder: Node3D = Node3D.new()
	holder.name = "Horizon"
	if use_terrain3d:
		var maps: Array[Image] = []
		maps.assign(data.get("terrain3d_maps", []))
		LandblockTerrain.bind_terrain3d_region(_terrain3d, LandblockTerrain.make_terrain3d_region(chunk.coord, maps))
		data.erase("terrain3d_maps")
		_mark_terrain3d_dirty()
	else:
		holder.add_child(LandblockTerrain.make_terrain_node(chunk.coord, data))
	_chunk_root(chunk).add_child(holder)
	chunk.terrain = holder
	chunk.terrain_data = data
	chunk.has_terrain = true
	chunk.terrain_pending = false
	if with_horizon:
		_attach_horizon(chunk, generation)
	_update_state(chunk)
	if chunk.gameplay_pending and chunk.gameplay == null and chunk.ground == null:
		_continue_gameplay(chunk)


## The rest of Layer 1: the occluders, any far landmark, and the HLOD proxy if its mesh is in.
func _attach_horizon(chunk: Chunk, generation: int) -> void:
	if generation != chunk.terrain_generation or chunk.terrain == null:
		return
	var occluders: OccluderInstance3D = WorldGridConfig.layout.make_occluders(chunk.coord)
	if occluders != null:
		chunk.terrain.add_child(occluders)
	var landmark: Node3D = WorldGridConfig.layout.make_horizon_landmark(chunk.coord)
	if landmark != null:
		chunk.terrain.add_child(landmark)
	_attach_hlod(chunk, generation)


## The HLOD proxy, once both the ground and its mesh are in (shown unless gameplay is).
func _attach_hlod(chunk: Chunk, generation: int) -> void:
	if generation != chunk.terrain_generation or chunk.terrain == null or chunk.hlod != null or chunk.hlod_mesh == null:
		return
	chunk.hlod = LandblockTerrain.make_hlod_proxy(chunk.hlod_mesh)
	chunk.hlod.visible = not chunk.has_gameplay
	chunk.terrain.add_child(chunk.hlod)


func _attach_clutter(chunk: Chunk, data: Dictionary, generation: int) -> void:
	if generation != chunk.clutter_generation:
		return
	chunk.clutter = WorldGridConfig.layout.make_clutter_node(chunk.coord, data)
	_chunk_root(chunk).add_child(chunk.clutter)
	chunk.has_clutter = true
	chunk.clutter_pending = false
	_update_state(chunk)


func _attach_ground(chunk: Chunk, generation: int) -> void:
	if generation != chunk.gameplay_generation or not chunk.terrain_data.has("collision_heights"):
		return
	chunk.ground = LandblockTerrain.make_collision_node(chunk.coord, chunk.terrain_data)
	_chunk_root(chunk).add_child(chunk.ground)


## Splits a landblock into pieces and queues them: its root first, then each
## top-level child (big plain containers emptied and their children queued
## after them), then the finishing step.
func _queue_landblock(chunk: Chunk, landblock: Node3D) -> void:
	var generation: int = chunk.gameplay_generation
	var pieces: Array[Array] = []
	_split_into_pieces(landblock, pieces)
	var attach_root: Callable = func() -> void:
		if generation != chunk.gameplay_generation:
			landblock.free()
			return
		landblock.add_to_group(ChunkNavBuilder.source_group(chunk.coord))
		_chunk_root(chunk).add_child(landblock)
		chunk.gameplay = landblock
	_instantiation_queue.append(attach_root)
	for piece: Array in pieces:
		var node: Node = piece[0]
		var parent: Node = piece[1]
		var attach_piece: Callable = func() -> void:
			if generation != chunk.gameplay_generation:
				node.free()
				return
			parent.add_child(node)
			_announce_entities(chunk, node)
		_instantiation_queue.append(attach_piece)
	_instantiation_queue.append(func() -> void: _finish_gameplay(chunk, generation))


func _split_into_pieces(node: Node, pieces: Array[Array]) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.owner = null
		pieces.append([child, node])
		if child.get_script() == null and child.get_class() == "Node3D" and _count_nodes(child) > PIECE_NODE_LIMIT:
			_split_into_pieces(child, pieces)


static func _count_nodes(node: Node) -> int:
	var count: int = 1
	for child: Node in node.get_children():
		count += _count_nodes(child)
	return count


## Binds each entity under `node` to WorldStateDB (its state applies before
## it's drawn) and tells the level.
func _announce_entities(chunk: Chunk, node: Node) -> void:
	var found: Array[Node] = []
	if node.is_in_group(ENTITY_GROUP):
		found.append(node)
	for child: Node in node.find_children("*", "", true, false):
		if child.is_in_group(ENTITY_GROUP):
			found.append(child)
	for entity: Node in found:
		if world_state != null:
			world_state.bind(entity, chunk.coord)
		chunk.entities.append(entity)
		entity_attached.emit(entity, chunk.coord)


func _finish_gameplay(chunk: Chunk, generation: int) -> void:
	if generation != chunk.gameplay_generation:
		return
	chunk.has_gameplay = true
	chunk.gameplay_pending = false
	if chunk.hlod != null:
		chunk.hlod.visible = false
	_bake_navigation(chunk)
	_update_state(chunk)


func _bake_navigation(chunk: Chunk) -> void:
	if not WorldGridConfig.layout.has_navigation(chunk.coord) or chunk.nav_region != null:
		return
	var region: NavigationRegion3D = NavigationRegion3D.new()
	region.name = "Navigation"
	_chunk_root(chunk).add_child(region)
	chunk.nav_region = region
	chunk.nav_ready = false
	var generation: int = chunk.gameplay_generation
	var faces: PackedVector3Array = chunk.terrain_data.get("nav_faces", PackedVector3Array())
	var on_baked: Callable = func() -> void:
		if generation == chunk.gameplay_generation:
			chunk.nav_ready = true
	# Parsed relative to the chunk's node (at the world origin), from its landblock's group.
	_bakes.append(ChunkNavBuilder.bake_region(region, _chunk_root(chunk), faces, ChunkNavBuilder.chunk_area(chunk.coord), on_baked,
		ChunkNavBuilder.source_group(chunk.coord)))


## Bakes a chunk's navigation again (after the Dover-Slap Gatehouse's portcullis sinks).
func rebake_navigation(coord: Vector2i) -> void:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	if chunk == null or not chunk.has_gameplay or chunk.nav_region == null:
		return
	chunk.nav_region.queue_free()
	chunk.nav_region = null
	_bake_navigation(chunk)


# --- Unloading ----------------------------------------------------------------

func _unload_gameplay(chunk: Chunk) -> void:
	chunk.gameplay_generation += 1
	chunk.has_gameplay = false
	chunk.gameplay_pending = false
	for entity: Node in chunk.entities:
		if is_instance_valid(entity):
			entity_detached.emit(entity, chunk.coord)
	chunk.entities.clear()
	if chunk.nav_region != null:
		chunk.nav_region.queue_free()
		chunk.nav_region = null
	chunk.nav_ready = false
	var ground: StaticBody3D = chunk.ground
	chunk.ground = null
	if ground != null:
		_instantiation_queue.append(func() -> void: ground.queue_free())
	var landblock: Node3D = chunk.gameplay
	chunk.gameplay = null
	if landblock != null:
		# Gone at once (nothing in it runs or shows); freed piece by piece.
		landblock.visible = false
		landblock.process_mode = Node.PROCESS_MODE_DISABLED
		for child: Node in landblock.get_children():
			var free_piece: Callable = func() -> void:
				if is_instance_valid(child):
					child.get_parent().remove_child(child)
					child.queue_free()
			_instantiation_queue.append(free_piece)
		var free_root: Callable = func() -> void:
			if is_instance_valid(landblock):
				landblock.queue_free()
		_instantiation_queue.append(free_root)
	if chunk.hlod != null:
		chunk.hlod.visible = true
	_update_state(chunk)


func _unload_clutter(chunk: Chunk) -> void:
	chunk.clutter_generation += 1
	chunk.has_clutter = false
	chunk.clutter_pending = false
	var clutter: Node3D = chunk.clutter
	chunk.clutter = null
	if clutter != null:
		_instantiation_queue.append(func() -> void: clutter.queue_free())
	_update_state(chunk)


func _unload_terrain(chunk: Chunk) -> void:
	chunk.terrain_generation += 1
	chunk.has_terrain = false
	chunk.terrain_pending = false
	chunk.terrain_data = {}
	chunk.hlod = null
	chunk.hlod_mesh = null
	var terrain: Node3D = chunk.terrain
	chunk.terrain = null
	if terrain != null:
		_instantiation_queue.append(func() -> void: terrain.queue_free())
	if use_terrain3d:
		var coord: Vector2i = chunk.coord
		var unbind: Callable = func() -> void:
			LandblockTerrain.unbind_terrain3d_region(_terrain3d, coord)
			_mark_terrain3d_dirty()
		_instantiation_queue.append(unbind)
	_update_state(chunk)


## Queues one Terrain3D texture refresh for however many regions change before it runs.
func _mark_terrain3d_dirty() -> void:
	if _terrain3d_dirty:
		return
	_terrain3d_dirty = true
	var refresh: Callable = func() -> void:
		_terrain3d_dirty = false
		LandblockTerrain.refresh_terrain3d(_terrain3d)
	_instantiation_queue.append(refresh)


func _update_state(chunk: Chunk) -> void:
	var state: int = ChunkState.UNLOADED
	if chunk.has_gameplay:
		state = ChunkState.FULL_GAMEPLAY
	elif chunk.has_clutter:
		state = ChunkState.VISUAL_CLUTTER
	elif chunk.has_terrain:
		state = ChunkState.HORIZON_HLOD
	if state != chunk.state:
		chunk.state = state
		chunk_state_changed.emit(chunk.coord, state)


# --- Loading at once ------------------------------------------------------------

## Loads every chunk within the gameplay radius of `points` completely, right
## now (a loading screen: the level's start, a teleport), then streams the rest.
func prime(points: Array[Vector3]) -> void:
	var focus: Array[Vector2i] = []
	for point: Vector3 in points:
		var at: Vector2i = WorldGridConfig.world_to_chunk(point)
		if not focus.has(at):
			focus.append(at)
	for coord: Vector2i in _chunks:
		if WorldGridConfig.min_chebyshev_to_focuses(coord, focus) <= WorldGridConfig.LOAD_GAMEPLAY_RADIUS:
			_load_now(_chunks[coord])
	if _terrain3d_dirty:
		_terrain3d_dirty = false
		LandblockTerrain.refresh_terrain3d(_terrain3d)
	_focus_chunks = focus
	update_streaming()


## Whether the ground under `point` has streamed in (its chunk's collider is there).
func has_ground_at(point: Vector3) -> bool:
	var coord: Vector2i = WorldGridConfig.world_to_chunk(point)
	return _chunks.has(coord) and _chunks[coord].ground != null


func _load_now(chunk: Chunk) -> void:
	if not chunk.has_terrain:
		chunk.terrain_generation += 1
		chunk.hlod_mesh = _load_cached(WorldGridConfig.layout.hlod_path(chunk.coord)) as ArrayMesh
		_attach_terrain(chunk, terrain_data_for(chunk.coord, use_terrain3d), chunk.terrain_generation, true)
	if not chunk.has_clutter:
		chunk.clutter_generation += 1
		_attach_clutter(chunk, WorldGridConfig.layout.build_clutter_data(chunk.coord), chunk.clutter_generation)
	if chunk.has_gameplay:
		return
	if chunk.gameplay_pending:
		_unload_gameplay(chunk)
	chunk.gameplay_generation += 1
	var generation: int = chunk.gameplay_generation
	chunk.gameplay_pending = true
	_attach_ground(chunk, generation)
	var path: String = WorldGridConfig.layout.landblock_path(chunk.coord)
	if path != "" and ResourceLoader.exists(path):
		var landblock: Node3D = (_load_cached(path) as PackedScene).instantiate() as Node3D
		landblock.add_to_group(ChunkNavBuilder.source_group(chunk.coord))
		_chunk_root(chunk).add_child(landblock)
		chunk.gameplay = landblock
		_announce_entities(chunk, landblock)
	_finish_gameplay(chunk, generation)


## Loads `path` now, on the main thread (or takes it from the cache).
func _load_cached(path: String) -> Resource:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _resource_cache.has(path):
		_resource_cache[path] = load(path)
	return _resource_cache[path]


## Runs the queue and finishes worker jobs until nothing's left (or `max_frames` passes); tests.
func flush(max_frames: int = 600) -> void:
	for frame: int in max_frames:
		_poll_jobs()
		var saved: Array[Callable] = _instantiation_queue.duplicate()
		_instantiation_queue.clear()
		for step: Callable in saved:
			step.call()
		if is_idle():
			return
		OS.delay_msec(1)


## Starts the expedition over: forgets its state (keeping the village's) and
## rebuilds every loaded expedition chunk from scratch.
func reset_expedition() -> void:
	if world_state != null:
		world_state.clear_expedition_transient_state()
	for coord: Vector2i in _chunks:
		var chunk: Chunk = _chunks[coord]
		if WorldGridConfig.layout.is_persistent(coord) or not (chunk.has_gameplay or chunk.gameplay_pending):
			continue
		_unload_gameplay(chunk)
	update_streaming()


# --- Reading the grid -------------------------------------------------------------

func get_chunk_state(coord: Vector2i) -> int:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	return chunk.state if chunk != null else ChunkState.UNLOADED


## Whether the chunk's HLOD proxy is loaded and on show.
func is_hlod_visible(coord: Vector2i) -> bool:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	return chunk != null and chunk.has_terrain and is_instance_valid(chunk.hlod) and chunk.hlod.visible


func has_hlod_proxy(coord: Vector2i) -> bool:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	return chunk != null and is_instance_valid(chunk.hlod)


func is_navigation_ready(coord: Vector2i) -> bool:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	return chunk != null and chunk.nav_ready


## The chunk's attached landblock (null unless its gameplay layer is in).
func gameplay_root(coord: Vector2i) -> Node3D:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	return chunk.gameplay if chunk != null and chunk.has_gameplay else null


func chunk_node(coord: Vector2i) -> Node3D:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	return chunk.root if chunk != null else null


## The entities attached in a chunk right now.
func entities_in(coord: Vector2i) -> Array[Node]:
	var chunk: Chunk = _chunks.get(coord) as Chunk
	return chunk.entities.duplicate() if chunk != null else []


func queue_depth() -> int:
	return _instantiation_queue.size()


## Nothing waiting: no queued attaches, no worker jobs, no scenes loading (navigation bakes may still run).
func is_idle() -> bool:
	return _instantiation_queue.is_empty() and _jobs.is_empty() and _resource_waiters.is_empty()


func focus_chunks() -> Array[Vector2i]:
	return _focus_chunks.duplicate()


## The numbers the telemetry badge shows (and tests read).
func get_streaming_metrics() -> Dictionary:
	var focus_chunk: Vector2i = _focus_chunks[0] if not _focus_chunks.is_empty() else Vector2i.ZERO
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.is_local_player() and not member.is_companion:
			focus_chunk = WorldGridConfig.world_to_chunk(member.global_position)
			break
	var active: int = 0
	var clutter: int = 0
	var terrain: int = 0
	var hlod: int = 0
	var states: Dictionary = {}
	for coord: Vector2i in _chunks:
		var chunk: Chunk = _chunks[coord]
		active += 1 if chunk.has_gameplay else 0
		clutter += 1 if chunk.has_clutter else 0
		terrain += 1 if chunk.has_terrain else 0
		hlod += 1 if is_hlod_visible(coord) else 0
		states[WorldGridConfig.chunk_key(coord)] = STATE_NAMES[chunk.state]
	return {"focus_chunk": focus_chunk, "active": active, "clutter": clutter, "terrain": terrain, "hlod": hlod,
		"queue": _instantiation_queue.size(), "jobs": _jobs.size() + _resource_waiters.size(),
		"deltas": world_state.delta_count() if world_state != null else 0, "peak_frame_usec": peak_frame_usec, "peak_step_usec": peak_step_usec,
		"focus_count": _focus_chunks.size(), "states": states, "terrain_mode": "Terrain3D" if use_terrain3d else "built-in"}


## Terrain3D's node in Mode A (null with the built-in meshes).
func terrain3d_node() -> Node3D:
	return _terrain3d


# --- Telemetry and AI --------------------------------------------------------------

## Puts the F4 telemetry badge on `canvas` (hidden until shown).
func attach_badge(canvas: Node) -> WorldTelemetryBadge:
	if _badge == null:
		_badge = WorldTelemetryBadge.new()
		_badge.setup(self)
		canvas.add_child(_badge)
	return _badge


func set_telemetry_visible(shown: bool) -> void:
	if _badge != null:
		_badge.visible = shown
		_badge.refresh()


func is_telemetry_visible() -> bool:
	return _badge != null and _badge.visible


## Host: far-off enemies think less often, or rest (ChunkNavBuilder).
func _scale_ai_ticks() -> void:
	if not NetworkManager.current.is_host():
		return
	var humans: Array[ActorBase] = []
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_companion:
			humans.append(member)
	if not humans.is_empty():
		ChunkNavBuilder.apply_tick_scaling(CombatDirector.current.enemies(), humans)
