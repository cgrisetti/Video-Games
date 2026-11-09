## Streams the Caldera Isles (docs/20 Part I; the Musk Razor's 5 grids, 4
## seams): exactly one island grid is live at a time, at the origin.
##
##   - Every landblock of the live island shows a light far stand-in (8 m on
##     the procedural isles, 4 m on Embershore) with its trees, reeds and
##     stones, so the whole island reads from anywhere on it.
##   - A 3 x 3 window of landblocks round the Soul Tether centroid (the middle
##     of the party), plus the landblock under every hero, gets the near ground
##     (2 m, or 1 m on Embershore) and its collider; it follows the party and
##     drops what falls behind. An isle with a mid level of detail (Embershore's
##     2 m) shows it in a ring round the window (docs/27 §4).
##   - An isle whose collision is resident (Embershore: its heightmap is the
##     collider) keeps every landblock's collider from the moment it's live.
##   - The other four islands stand on the horizon across The Sound as
##     impostor silhouettes with their landmarks, where the Master Atlas draws them.
##   - One sea plane, at CalderaWorldState.sea_level_y, carries the three
##     currents round The Crown, which calm as their Beacons are lit.
##
## Ground data is built on worker threads (IslandBuilder.build_chunk_data) and
## finished here on the main thread a slice at a time; load_now() builds what's
## missing at once (arrivals, catching a fall, tests).
class_name ArchipelagoStreamer
extends Node3D

signal island_activated(isle_id: StringName)
signal island_deactivating(isle_id: StringName)
signal collision_changed(chunk: Vector2i, loaded: bool)

## Landblocks round the centroid's that get the 2 m ground (1: a 3 x 3 window).
const WINDOW_RADIUS: int = 1
## A loaded landblock is dropped once it's further than this from the centroid's (and no hero stands on it).
const KEEP_RADIUS: int = 2
## The mid level of detail's ring round the window, and where it's dropped.
const MID_RADIUS: int = 2
const MID_KEEP_RADIUS: int = 3
## Levels of detail (IslandBuilder.lod_quads): the window, the ring round it, the far stand-in.
const LOD_NEAR: int = 0
const LOD_MID: int = 1
const LOD_FAR: int = 2
## Microseconds a frame spent turning finished worker data into nodes.
const FINISH_BUDGET_USEC: int = 3000
const SEA_SIZE: float = 16000.0
## The impostor silhouettes' sample spacing (metres).
const IMPOSTOR_STEP: float = 24.0
## Far silhouettes stand this much taller than life, so a 60 m landmark still reads at 2-3 km.
const IMPOSTOR_LIFT: float = 1.6
const SEA_SHADER: Shader = preload("res://src/world/shaders/caldera_sea.gdshader")
const IMPOSTOR_SHADER: Shader = preload("res://src/world/shaders/caldera_impostor.gdshader")


## A landblock's data being built on a worker thread.
class ChunkJob:
	extends RefCounted

	var isle_id: StringName
	var builder: IslandBuilder
	var chunk: Vector2i
	## LOD_NEAR, LOD_MID or LOD_FAR.
	var level: int = LOD_FAR
	var task_id: int = -1
	var data: Dictionary = {}

	func run() -> void:
		var quads: int = builder.lod_quads()[level]
		var near: bool = level == LOD_NEAR
		data = builder.build_chunk_data(chunk, quads, near and not builder.collision_resident(), level == LOD_FAR, near)


## One landblock of the live island and its nodes.
class LoadedChunk:
	extends RefCounted

	var chunk: Vector2i
	var root: Node3D
	var far_mesh: MeshInstance3D
	var mid_mesh: MeshInstance3D
	var near_mesh: MeshInstance3D
	var body: StaticBody3D
	## Species -> Array of Transform3D (for trunk colliders in the window).
	var scatter: Dictionary = {}
	## Whether the trunks and stones have their colliders on the body yet.
	var solids_added: bool = false
	## The near landblock's meadow of grass and wildflowers (docs/24 §4).
	var meadow: Node3D
	var far_job: ChunkJob
	var mid_job: ChunkJob
	var near_job: ChunkJob

	## Each level shows only while nothing finer is there.
	func show_finest() -> void:
		if mid_mesh != null:
			mid_mesh.visible = near_mesh == null
		if far_mesh != null:
			far_mesh.visible = near_mesh == null and mid_mesh == null


## An island's far silhouette heights, built on a worker thread.
class ImpostorJob:
	extends RefCounted

	var builder: IslandBuilder
	var task_id: int = -1
	var arrays: Array = []

	func run() -> void:
		var half: Vector2 = builder.isle.half_size()
		var step: float = ArchipelagoStreamer.IMPOSTOR_STEP
		var side: int = int(half.x * 2.0 / step) + 1
		var rows: int = int(half.y * 2.0 / step) + 1
		var vertices: PackedVector3Array = PackedVector3Array()
		var colors: PackedColorArray = PackedColorArray()
		vertices.resize(side * rows)
		colors.resize(side * rows)
		for row: int in rows:
			for column: int in side:
				var x: float = -half.x + column * step
				var z: float = -half.y + row * step
				var h: float = builder.height_at(x, z)
				vertices[row * side + column] = Vector3(x, h, z)
				colors[row * side + column] = builder.surface_color(x, z, h, 1.0 if h > 1.5 else 0.9)
		var normals: PackedVector3Array = PackedVector3Array()
		normals.resize(side * rows)
		for row: int in rows:
			for column: int in side:
				var left: float = vertices[row * side + maxi(column - 1, 0)].y
				var right: float = vertices[row * side + mini(column + 1, side - 1)].y
				var back: float = vertices[maxi(row - 1, 0) * side + column].y
				var front: float = vertices[mini(row + 1, rows - 1) * side + column].y
				normals[row * side + column] = Vector3((left - right) / (2.0 * step), 1.0, (back - front) / (2.0 * step)).normalized()
		var indices: PackedInt32Array = PackedInt32Array()
		for row: int in rows - 1:
			for column: int in side - 1:
				var a: int = row * side + column
				if vertices[a].y < -4.0 and vertices[a + 1].y < -4.0 and vertices[a + side].y < -4.0 and vertices[a + side + 1].y < -4.0:
					continue
				indices.append_array(PackedInt32Array([a, a + 1, a + side, a + 1, a + side + 1, a + side]))
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices


## Built once a session per island (they never change).
static var _impostor_meshes: Dictionary[StringName, ArrayMesh] = {}

var active_isle: StringName = &""
var builder: IslandBuilder
## Every landblock of the live island.
var chunks: Dictionary[Vector2i, LoadedChunk] = {}
## Where the party is (the level sets these every physics frame): the centroid first, then each hero.
var focus_points: Array[Vector3] = []
var structures: Node3D
var sea: MeshInstance3D
var sea_material: ShaderMaterial
var impostor_material: ShaderMaterial
var impostors: Node3D
## Landblocks whose window ground was built (for tests and the telemetry line).
var near_builds: int = 0
var far_builds: int = 0

var _terrain: Node3D
var _jobs: Array[ChunkJob] = []
var _mist: float = 0.0


func _ready() -> void:
	_terrain = Node3D.new()
	_terrain.name = "Terrain"
	add_child(_terrain)
	impostors = Node3D.new()
	impostors.name = "Impostors"
	add_child(impostors)
	_build_sea()
	var state: CalderaWorldState = CalderaWorldState.current
	if state != null:
		state.sea_level_changed.connect(_on_sea_level_changed)
		state.flag_changed.connect(_on_flag_changed)


func _exit_tree() -> void:
	_wait_for_jobs()
	_apply_roads(null)


func _process(_delta: float) -> void:
	if builder == null:
		return
	_finish_jobs(false)
	_update_window()


# --- The live island ---------------------------------------------------------------

## Makes `isle_id` the live island, its window round `focus` loaded at once.
func activate_island(isle_id: StringName, focus: Array[Vector3]) -> void:
	if isle_id == active_isle:
		load_now(focus)
		return
	_deactivate()
	active_isle = isle_id
	builder = CalderaAtlas.builder_for(isle_id)
	_apply_roads(builder)
	WorldGridConfig.layout = CalderaLayout.new(builder)
	structures = Node3D.new()
	structures.name = "Island_%s" % String(isle_id).trim_prefix("isle_")
	add_child(structures)
	builder.build_structures(structures)
	var resident: bool = builder.collision_resident()
	for x: int in range(builder.isle.chunk_min(), builder.isle.chunk_max() + 1):
		for z: int in range(builder.isle.chunk_min_z(), builder.isle.chunk_max_z() + 1):
			var record: LoadedChunk = LoadedChunk.new()
			record.chunk = Vector2i(x, z)
			record.root = Node3D.new()
			record.root.name = "Landblock_%d_%d" % [x, z]
			_terrain.add_child(record.root)
			chunks[record.chunk] = record
			if resident:
				# The whole island's colliders at once, straight from its data (docs/27 §4).
				var resident_heights: PackedFloat32Array = builder.collision_heights_for(record.chunk)
				if not resident_heights.is_empty():
					record.body = _ground_body(record.chunk, resident_heights)
					record.root.add_child(record.body)
			record.far_job = _dispatch(record.chunk, LOD_FAR)
	focus_points = focus.duplicate()
	_build_impostors()
	_refresh_sea()
	load_now(focus)
	island_activated.emit(isle_id)


## Builds, right now, the window round `points` (the first is the centroid) and the
## landblock under each, the mid ring round the window, and every far stand-in still on its way.
func load_now(points: Array[Vector3]) -> void:
	if builder == null:
		return
	if not points.is_empty():
		focus_points = points.duplicate()
	_finish_jobs(true)
	for chunk: Vector2i in _wanted_near():
		var record: LoadedChunk = chunks.get(chunk, null)
		if record == null or record.near_mesh != null:
			continue
		if record.near_job != null:
			WorkerThreadPool.wait_for_task_completion(record.near_job.task_id)
			_jobs.erase(record.near_job)
			_finish(record.near_job)
		else:
			var job: ChunkJob = _make_job(chunk, LOD_NEAR)
			job.run()
			_finish(job)
	# The mid ring round the window arrives with it, so an arrival leaves no job on the way.
	for chunk: Vector2i in _wanted_mid():
		var record: LoadedChunk = chunks.get(chunk, null)
		if record != null and record.mid_mesh == null and record.mid_job == null:
			record.mid_job = _dispatch(chunk, LOD_MID)
	_finish_jobs(true)


## Whether the ground under `at` has its collider.
func has_ground_at(at: Vector3) -> bool:
	var record: LoadedChunk = chunks.get(IslandGridResource.chunk_of(at), null)
	return record != null and record.body != null


## Builds the ground under `at` now if it isn't there (a respawn, a fall).
func ensure_ground_at(at: Vector3) -> void:
	if has_ground_at(at):
		return
	var points: Array[Vector3] = [at]
	points.append_array(focus_points)
	load_now(points)


func height_at(x: float, z: float) -> float:
	return builder.height_at(x, z) if builder != null else 0.0


## How many landblocks have their window ground, their mid ring, their stand-in, their collider, or a job on the way (tests, telemetry).
func counts() -> Dictionary:
	var near: int = 0
	var mid: int = 0
	var far: int = 0
	var bodies: int = 0
	for record: LoadedChunk in chunks.values():
		near += 1 if record.near_mesh != null else 0
		mid += 1 if record.mid_mesh != null else 0
		far += 1 if record.far_mesh != null else 0
		bodies += 1 if record.body != null else 0
	return {"near": near, "mid": mid, "far": far, "bodies": bodies, "pending": _jobs.size(), "chunks": chunks.size(),
		"terrain_nodes": _terrain.get_child_count(), "impostors": impostors.get_child_count()}


## Sea-fog on a seam (0 clear, 1 thick): the sea and the horizon silhouettes fade into it.
func set_mist(amount: float) -> void:
	_mist = clampf(amount, 0.0, 1.0)
	if sea_material != null:
		sea_material.set_shader_parameter(&"mist", _mist)
	if impostor_material != null:
		impostor_material.set_shader_parameter(&"mist", _mist)


func mist() -> float:
	return _mist


# --- Window --------------------------------------------------------------------------

func _wanted_near() -> Dictionary[Vector2i, bool]:
	var wanted: Dictionary[Vector2i, bool] = {}
	if builder == null or focus_points.is_empty():
		return wanted
	var middle: Vector2i = IslandGridResource.chunk_of(focus_points[0])
	for dx: int in range(-WINDOW_RADIUS, WINDOW_RADIUS + 1):
		for dz: int in range(-WINDOW_RADIUS, WINDOW_RADIUS + 1):
			var chunk: Vector2i = middle + Vector2i(dx, dz)
			if builder.isle.contains_chunk(chunk):
				wanted[chunk] = true
	for index: int in range(1, focus_points.size()):
		var under: Vector2i = IslandGridResource.chunk_of(focus_points[index])
		if builder.isle.contains_chunk(under):
			wanted[under] = true
	return wanted


func _keeps(chunk: Vector2i) -> bool:
	if focus_points.is_empty():
		return true
	var middle: Vector2i = IslandGridResource.chunk_of(focus_points[0])
	if absi(chunk.x - middle.x) <= KEEP_RADIUS and absi(chunk.y - middle.y) <= KEEP_RADIUS:
		return true
	for index: int in range(1, focus_points.size()):
		if IslandGridResource.chunk_of(focus_points[index]) == chunk:
			return true
	return false


## The mid ring: landblocks within MID_RADIUS of the centroid's that aren't in the window.
func _wanted_mid() -> Dictionary[Vector2i, bool]:
	var wanted: Dictionary[Vector2i, bool] = {}
	if builder == null or focus_points.is_empty() or builder.lod_quads()[LOD_MID] <= 0:
		return wanted
	var near: Dictionary[Vector2i, bool] = _wanted_near()
	var middle: Vector2i = IslandGridResource.chunk_of(focus_points[0])
	for dx: int in range(-MID_RADIUS, MID_RADIUS + 1):
		for dz: int in range(-MID_RADIUS, MID_RADIUS + 1):
			var chunk: Vector2i = middle + Vector2i(dx, dz)
			if builder.isle.contains_chunk(chunk) and not near.has(chunk):
				wanted[chunk] = true
	return wanted


func _keeps_mid(chunk: Vector2i) -> bool:
	if focus_points.is_empty():
		return true
	var middle: Vector2i = IslandGridResource.chunk_of(focus_points[0])
	return absi(chunk.x - middle.x) <= MID_KEEP_RADIUS and absi(chunk.y - middle.y) <= MID_KEEP_RADIUS


func _update_window() -> void:
	for chunk: Vector2i in _wanted_near():
		var record: LoadedChunk = chunks.get(chunk, null)
		if record != null and record.near_mesh == null and record.near_job == null:
			record.near_job = _dispatch(chunk, LOD_NEAR)
	for chunk: Vector2i in _wanted_mid():
		var record: LoadedChunk = chunks.get(chunk, null)
		if record != null and record.mid_mesh == null and record.mid_job == null:
			record.mid_job = _dispatch(chunk, LOD_MID)
	for record: LoadedChunk in chunks.values():
		if record.near_mesh != null and not _keeps(record.chunk):
			_drop_near(record)
		if record.mid_mesh != null and not _keeps_mid(record.chunk):
			record.mid_mesh.queue_free()
			record.mid_mesh = null
			record.show_finest()


func _drop_near(record: LoadedChunk) -> void:
	record.near_mesh.queue_free()
	record.near_mesh = null
	if record.meadow != null:
		record.meadow.queue_free()
		record.meadow = null
	# A resident collider stays; a window collider goes with its ground.
	if record.body != null and not builder.collision_resident():
		record.body.queue_free()
		record.body = null
		record.solids_added = false
	record.show_finest()
	collision_changed.emit(record.chunk, false)


# --- Jobs ------------------------------------------------------------------------------

func _make_job(chunk: Vector2i, level: int) -> ChunkJob:
	var job: ChunkJob = ChunkJob.new()
	job.isle_id = active_isle
	job.builder = builder
	job.chunk = chunk
	job.level = level
	return job


func _dispatch(chunk: Vector2i, level: int) -> ChunkJob:
	var job: ChunkJob = _make_job(chunk, level)
	job.task_id = WorkerThreadPool.add_task(job.run, false, "Caldera %s %s" % [["near", "mid", "far"][level], chunk])
	_jobs.append(job)
	return job


## Turns finished jobs into nodes: all of them (and waits for the rest) when `block`, else within the frame budget.
func _finish_jobs(block: bool) -> void:
	if _jobs.is_empty():
		return
	var start: int = Time.get_ticks_usec()
	var index: int = 0
	while index < _jobs.size():
		var job: ChunkJob = _jobs[index]
		if not block and not WorkerThreadPool.is_task_completed(job.task_id):
			index += 1
			continue
		WorkerThreadPool.wait_for_task_completion(job.task_id)
		_jobs.remove_at(index)
		_finish(job)
		if not block and Time.get_ticks_usec() - start > FINISH_BUDGET_USEC:
			return


func _wait_for_jobs() -> void:
	for job: ChunkJob in _jobs:
		WorkerThreadPool.wait_for_task_completion(job.task_id)
	_jobs.clear()


func _finish(job: ChunkJob) -> void:
	if job.isle_id != active_isle:
		return
	var record: LoadedChunk = chunks.get(job.chunk, null)
	if record == null:
		return
	match job.level:
		LOD_NEAR:
			if record.near_job == job:
				record.near_job = null
			if record.near_mesh != null:
				return
			record.near_mesh = _ground_mesh("Near", job.data)
			record.root.add_child(record.near_mesh)
			if record.body == null:
				record.body = _ground_body(job.chunk, job.data["collision_heights"])
				record.root.add_child(record.body)
			_add_solids(record)
			record.meadow = _meadow_node(job.data.get("meadow", []) as Array)
			record.root.add_child(record.meadow)
			record.show_finest()
			near_builds += 1
			collision_changed.emit(job.chunk, true)
		LOD_MID:
			if record.mid_job == job:
				record.mid_job = null
			if record.mid_mesh != null:
				return
			record.mid_mesh = _ground_mesh("Mid", job.data)
			record.root.add_child(record.mid_mesh)
			record.show_finest()
		LOD_FAR:
			if record.far_job == job:
				record.far_job = null
			if record.far_mesh != null:
				return
			record.far_mesh = _ground_mesh("Far", job.data)
			record.root.add_child(record.far_mesh)
			record.scatter = job.data.get("scatter", {}) as Dictionary
			_add_scatter(record)
			_add_solids(record)
			record.show_finest()
			far_builds += 1


func _ground_mesh(node_name: String, data: Dictionary) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = data["normals"]
	arrays[Mesh.ARRAY_COLOR] = data["colors"]
	arrays[Mesh.ARRAY_INDEX] = data["indices"]
	# The worked land's tilth (docs/32 §4): the rows' direction in UV, their spacing and tone in UV2.
	if data.has("rows"):
		arrays[Mesh.ARRAY_TEX_UV] = data["rows"]
		arrays[Mesh.ARRAY_TEX_UV2] = data["tones"]
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, WorldVisualCatalog.terrain())
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = node_name
	ground.mesh = mesh
	return ground


## A landblock's collider: the ground as a height map on the low-scenery layer.
func _ground_body(chunk: Vector2i, collision_heights: PackedFloat32Array) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = ActorBase.LAYER_LOW_SCENERY
	body.collision_mask = 0
	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = IslandBuilder.COLLISION_SIDE
	shape.map_depth = IslandBuilder.COLLISION_SIDE
	shape.map_data = collision_heights
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	var size: float = IslandGridResource.CHUNK_SIZE
	collision.position = Vector3(chunk.x * size + size * 0.5, 0.0, chunk.y * size + size * 0.5)
	body.add_child(collision)
	return body


## The trunks and stones that block the way, once a landblock has both its collider and its scatter (and only inside the window).
func _add_solids(record: LoadedChunk) -> void:
	if record.solids_added or record.body == null or record.near_mesh == null or record.scatter.is_empty():
		return
	record.solids_added = true
	var solids: StaticBody3D = StaticBody3D.new()
	solids.name = "Solids"
	solids.collision_layer = ActorBase.LAYER_WORLD
	solids.collision_mask = 0
	# Walls, fences and hurdles: a low box along each run, on the low-scenery layer (heroes hop them, cameras see over).
	var low: StaticBody3D = StaticBody3D.new()
	low.name = "LowSolids"
	low.collision_layer = ActorBase.LAYER_LOW_SCENERY
	low.collision_mask = 0
	for species: Variant in record.scatter:
		var kind: int = int(species)
		if IslandBuilder.SOLID_BOX.has(kind):
			var size: Vector3 = IslandBuilder.SOLID_BOX[kind]
			for where: Transform3D in record.scatter[species] as Array:
				var scale: Vector3 = where.basis.get_scale()
				var run: CollisionShape3D = CollisionShape3D.new()
				var box: BoxShape3D = BoxShape3D.new()
				box.size = Vector3(size.x * scale.x, size.y * scale.y, size.z * scale.z)
				run.shape = box
				var turn: Basis = where.basis.orthonormalized()
				run.transform = Transform3D(turn, where.origin + turn.y * box.size.y * 0.5)
				low.add_child(run)
			continue
		var radius: float = IslandBuilder.SOLID_RADIUS[kind]
		if radius <= 0.0:
			continue
		for where: Transform3D in record.scatter[species] as Array:
			var trunk: CollisionShape3D = CollisionShape3D.new()
			var cylinder: CylinderShape3D = CylinderShape3D.new()
			cylinder.radius = radius * where.basis.get_scale().x
			cylinder.height = 3.0
			trunk.shape = cylinder
			trunk.position = where.origin + Vector3(0.0, 1.5, 0.0)
			solids.add_child(trunk)
	if solids.get_child_count() > 0:
		record.body.add_child(solids)
	else:
		solids.free()
	if low.get_child_count() > 0:
		record.body.add_child(low)
	else:
		low.free()


## A landblock's scatter, one MultiMesh per species: within CalderaKit.ATELIER_RANGE
## of a camera the sculpted atelier mesh (oak clumps, willows, pines, layered
## ferns...), past it the one-draw stand-in; small scatter is gone past SMALL_RANGE.
## A dense stand (CalderaKit.DENSE_STAND trees of one species or more: the Moss-Oaks)
## is grouped into DENSE_CELL m cells that each hand over at DENSE_ATELIER_RANGE
## instead, so only the cells round a camera draw sculpted (docs/27 §8).
func _add_scatter(record: LoadedChunk) -> void:
	# The worked land's trees and runs (docs/32 §9): sculpted while a camera is near the landblock, and past that
	# every kind's stand-ins merged into one mesh for the trees and one for the runs, a draw each. Every node of
	# the landblock measures its distance from the landblock's own box, so they all hand over together.
	var box: AABB = AABB()
	var far_trees: LandblockTerrain.MeshMerge = null
	var far_runs: LandblockTerrain.MeshMerge = null
	# While its trees are sculpted, a landblock's shadows are thrown by their stand-ins (WorkedLandKit.SHADOW_PROXY).
	var tree_shadows: LandblockTerrain.MeshMerge = null
	# The kinds with no sculpted mesh (a Scots pine) are their far shape at every distance.
	var plain_trees: LandblockTerrain.MeshMerge = null
	for species: Variant in record.scatter:
		var spots: Array = record.scatter[species] as Array
		if spots.is_empty():
			continue
		var kind: int = int(species)
		if WorkedLandKit.MERGED_FAR.has(kind):
			if box.size == Vector3.ZERO:
				box = _landblock_box(record)
			if CalderaKit.atelier_mesh(kind) == null:
				if plain_trees == null:
					plain_trees = CalderaKit.merge()
				_merge_stand_ins(plain_trees, kind, spots)
				continue
			var near: MultiMeshInstance3D = _scatter_node("Atelier_%d" % kind, CalderaKit.atelier_mesh(kind), spots)
			near.visibility_range_end = CalderaKit.handover(kind)
			near.visibility_range_end_margin = CalderaKit.ATELIER_MARGIN
			near.custom_aabb = box
			if not CalderaKit.casts_shadow(kind) or CalderaKit.is_tree(kind):
				near.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			record.root.add_child(near)
			if CalderaKit.is_tree(kind):
				if far_trees == null:
					far_trees = CalderaKit.merge()
					tree_shadows = CalderaKit.merge()
				_merge_stand_ins(far_trees, kind, spots)
				_merge_stand_ins(tree_shadows, kind, spots, Basis.from_scale(WorkedLandKit.SHADOW_PROXY))
			else:
				if far_runs == null:
					far_runs = CalderaKit.merge()
				_merge_stand_ins(far_runs, kind, spots)
			continue
		if CalderaKit.atelier_mesh(kind) != null and not CalderaKit.is_small(kind) and CalderaKit.is_tree(kind) and spots.size() >= CalderaKit.DENSE_STAND:
			var cells: Dictionary[Vector2i, Array] = _stand_cells(spots)
			for cell: Vector2i in cells:
				_add_stand(record, kind, cells[cell], "%d_%d_%d" % [kind, cell.x, cell.y], CalderaKit.DENSE_ATELIER_RANGE)
		else:
			_add_stand(record, kind, spots, str(kind), CalderaKit.handover(kind))
	if far_trees != null:
		record.root.add_child(_far_node("FarTrees", far_trees, WorkedLandKit.TREE_HANDOVER, box, true))
		var shadows: MeshInstance3D = _far_node("NearTreeShadows", tree_shadows, 0.0, box, true)
		shadows.visibility_range_begin_margin = 0.0
		shadows.visibility_range_end = WorkedLandKit.TREE_HANDOVER
		shadows.visibility_range_end_margin = CalderaKit.ATELIER_MARGIN
		shadows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		record.root.add_child(shadows)
	if far_runs != null:
		var runs: MeshInstance3D = _far_node("FarRuns", far_runs, WorkedLandKit.RUN_HANDOVER, box, false)
		runs.visibility_range_end = WorkedLandKit.RUN_REACH
		runs.visibility_range_end_margin = 24.0
		record.root.add_child(runs)
	if plain_trees != null:
		var plain: MeshInstance3D = _far_node("PlainTrees", plain_trees, 0.0, box, true)
		plain.visibility_range_begin_margin = 0.0
		record.root.add_child(plain)


## A landblock's box: its 128 m square, from under its lowest scatter to over its tallest tree.
func _landblock_box(record: LoadedChunk) -> AABB:
	var size: float = IslandGridResource.CHUNK_SIZE
	var low: float = INF
	var high: float = -INF
	for species: Variant in record.scatter:
		for where: Transform3D in record.scatter[species] as Array:
			low = minf(low, where.origin.y)
			high = maxf(high, where.origin.y)
	if low == INF:
		low = 0.0
		high = 0.0
	return AABB(Vector3(record.chunk.x * size, low - 4.0, record.chunk.y * size), Vector3(size, high - low + 24.0, size))


## Adds a kind's stand-in at every spot to a landblock's far mesh (its own vertex colours kept).
static func _merge_stand_ins(into: LandblockTerrain.MeshMerge, kind: int, spots: Array, shrink: Basis = Basis.IDENTITY) -> void:
	var stand_in: ArrayMesh = CalderaKit.species_mesh(kind)
	if stand_in.get_surface_count() == 0:
		return
	var arrays: Array = stand_in.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var directions: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var shades: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	for spot: Variant in spots:
		var where: Transform3D = spot as Transform3D
		where.basis = where.basis * shrink
		into.vertices.append_array(where * points)
		into.normals.append_array(Transform3D(where.basis.orthonormalized(), Vector3.ZERO) * directions)
		into.colors.append_array(shades)


func _far_node(node_name: String, merged: LandblockTerrain.MeshMerge, handover: float, box: AABB, shadows: bool) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = node_name
	node.mesh = merged.commit()
	node.material_override = CalderaKit.vertex_material()
	node.visibility_range_begin = handover
	node.visibility_range_begin_margin = CalderaKit.ATELIER_MARGIN
	node.custom_aabb = box
	if not shadows:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## One stand of a species at `spots`: its sculpted atelier MultiMesh (when the species has one)
## handing over to its stand-in at `handover` metres, both named by `suffix`.
func _add_stand(record: LoadedChunk, kind: int, spots: Array, suffix: String, handover: float) -> void:
	var small: bool = CalderaKit.is_small(kind)
	var atelier: ArrayMesh = CalderaKit.atelier_mesh(kind)
	var reach: float = CalderaKit.species_reach(kind)
	if atelier != null:
		var near: MultiMeshInstance3D = _scatter_node("Atelier_" + suffix, atelier, spots)
		near.visibility_range_end = (reach if reach > 0.0 else CalderaKit.SMALL_RANGE) if small else handover
		near.visibility_range_end_margin = CalderaKit.ATELIER_MARGIN
		if small or not CalderaKit.casts_shadow(kind):
			near.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		record.root.add_child(near)
		if small:
			return
	var node: MultiMeshInstance3D = _scatter_node("Scatter_" + suffix, CalderaKit.species_mesh(kind), spots)
	node.material_override = CalderaKit.vertex_material()
	if atelier != null:
		node.visibility_range_begin = handover
		node.visibility_range_begin_margin = CalderaKit.ATELIER_MARGIN
		# A stand-in is small on screen by the time it shows: only the trees' still throw shadows.
		if not CalderaKit.is_tree(kind) or not CalderaKit.casts_shadow(kind):
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif small:
		node.visibility_range_end = CalderaKit.SMALL_RANGE
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if reach > 0.0 and not small:
		node.visibility_range_end = reach
		node.visibility_range_end_margin = CalderaKit.ATELIER_MARGIN
	record.root.add_child(node)


## A dense stand's spots grouped into CalderaKit.DENSE_CELL m cells, by cell column and row.
static func _stand_cells(spots: Array) -> Dictionary[Vector2i, Array]:
	var cells: Dictionary[Vector2i, Array] = {}
	for spot: Variant in spots:
		var at: Vector3 = (spot as Transform3D).origin
		var cell: Vector2i = Vector2i(floori(at.x / CalderaKit.DENSE_CELL), floori(at.z / CalderaKit.DENSE_CELL))
		if not cells.has(cell):
			cells[cell] = []
		(cells[cell] as Array).append(spot)
	return cells


## A near landblock's meadow (IslandBuilder._meadow): per 32 m cell a MultiMesh of
## grass tufts, rooted in the ground's colour, and one per wildflower, each drawn
## only within CalderaKit.MEADOW_CELL_RANGE of a camera and fading out per pixel.
func _meadow_node(cells: Array) -> Node3D:
	var meadow: Node3D = Node3D.new()
	meadow.name = "Meadow"
	var grass_material: Material = WorldVisualCatalog.grass_blades(CalderaKit.MEADOW_GRASS_TIP, CalderaKit.MEADOW_FADE_M)
	var flower_material: Material = WorldVisualCatalog.foliage(Color.WHITE, 0.6, 0.35, 0.0, false, CalderaKit.MEADOW_FADE_M)
	for index: int in cells.size():
		var cell: Dictionary = cells[index]
		var grass: Array = cell.get("grass", [])
		if not grass.is_empty():
			var colors: Array = cell.get("colors", [])
			var multi: MultiMesh = MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.use_colors = true
			multi.mesh = CalderaKit.meadow_grass_mesh()
			multi.instance_count = grass.size()
			for at: int in grass.size():
				multi.set_instance_transform(at, grass[at] as Transform3D)
				multi.set_instance_color(at, colors[at] as Color if at < colors.size() else Color.WHITE)
			meadow.add_child(_meadow_cell_node("Grass_%d" % index, multi, grass_material))
		var flowers: Array = cell.get("flowers", [])
		for kind: int in flowers.size():
			var spots: Array = flowers[kind]
			if spots.is_empty():
				continue
			var bloom: MultiMesh = MultiMesh.new()
			bloom.transform_format = MultiMesh.TRANSFORM_3D
			bloom.mesh = CalderaKit.meadow_flower_mesh(kind)
			bloom.instance_count = spots.size()
			for at: int in spots.size():
				bloom.set_instance_transform(at, spots[at] as Transform3D)
			meadow.add_child(_meadow_cell_node("Flowers_%d_%d" % [index, kind], bloom, flower_material))
	return meadow


func _meadow_cell_node(node_name: String, multi: MultiMesh, material: Material) -> MultiMeshInstance3D:
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = multi
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = CalderaKit.MEADOW_CELL_RANGE
	node.visibility_range_end_margin = 8.0
	return node


func _scatter_node(node_name: String, mesh: ArrayMesh, spots: Array) -> MultiMeshInstance3D:
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = spots.size()
	for index: int in spots.size():
		multi.set_instance_transform(index, spots[index] as Transform3D)
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = multi
	return node


func _deactivate() -> void:
	if active_isle == &"":
		return
	island_deactivating.emit(active_isle)
	_wait_for_jobs()
	for record: LoadedChunk in chunks.values():
		if record.body != null:
			collision_changed.emit(record.chunk, false)
		_terrain.remove_child(record.root)
		record.root.queue_free()
	chunks.clear()
	if structures != null:
		remove_child(structures)
		structures.queue_free()
		structures = null
	builder = null
	active_isle = &""


## Hands the live island's laid roads to the ground shader (docs/26), or none
## (null: the shared terrain material draws vertex-painted roads again elsewhere).
static func _apply_roads(live: IslandBuilder) -> void:
	var terrain: ShaderMaterial = WorldVisualCatalog.terrain()
	if live == null:
		terrain.set_shader_parameter(&"road_grid", Vector4.ZERO)
		return
	var data: Dictionary = live.road_textures()
	terrain.set_shader_parameter(&"road_segs", data["segs"])
	terrain.set_shader_parameter(&"road_cells", data["cells"])
	terrain.set_shader_parameter(&"road_index", data["index"])
	terrain.set_shader_parameter(&"road_dims", data["dims"])
	terrain.set_shader_parameter(&"road_grid", data["grid"])


# --- The Sound: sea and horizon -----------------------------------------------------------

func _build_sea() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(SEA_SIZE, SEA_SIZE)
	sea_material = ShaderMaterial.new()
	sea_material.shader = SEA_SHADER
	sea = MeshInstance3D.new()
	sea.name = "Sea"
	sea.mesh = plane
	sea.material_override = sea_material
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
	impostor_material = ShaderMaterial.new()
	impostor_material.shader = IMPOSTOR_SHADER
	_on_sea_level_changed(CalderaWorldState.current.sea_level_y if CalderaWorldState.current != null else 0.0)


func _refresh_sea() -> void:
	var state: CalderaWorldState = CalderaWorldState.current
	if state == null or active_isle == &"":
		return
	var crown: Vector3 = CalderaAtlas.offset_between(active_isle, CalderaAtlas.ISLE_THE_CROWN)
	sea_material.set_shader_parameter(&"crown_center", Vector2(crown.x, crown.z))
	sea_material.set_shader_parameter(&"iron_wild", 0.0 if state.beacon_iron else 1.0)
	sea_material.set_shader_parameter(&"tide_wild", 0.0 if state.beacon_tide else 1.0)
	sea_material.set_shader_parameter(&"gale_wild", 0.0 if state.beacon_gale else 1.0)
	sea_material.set_shader_parameter(&"star_tide", 0.0 if state.ebb_unlocked else 1.0)


## How rough each current runs right now (1 wild, 0 calm), for tests.
func current_wildness() -> Dictionary:
	return {"iron": float(sea_material.get_shader_parameter(&"iron_wild")), "tide": float(sea_material.get_shader_parameter(&"tide_wild")),
		"gale": float(sea_material.get_shader_parameter(&"gale_wild"))}


func _on_sea_level_changed(sea_y: float) -> void:
	sea.position = Vector3(0.0, sea_y, 0.0)


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_refresh_sea()


func _build_impostors() -> void:
	for child: Node in impostors.get_children():
		impostors.remove_child(child)
		child.queue_free()
	var waiting: Array[ImpostorJob] = []
	for isle_id: StringName in CalderaAtlas.ISLES:
		if isle_id == active_isle or _impostor_meshes.has(isle_id):
			continue
		var job: ImpostorJob = ImpostorJob.new()
		job.builder = CalderaAtlas.builder_for(isle_id)
		job.task_id = WorkerThreadPool.add_task(job.run, false, "Caldera impostor %s" % isle_id)
		waiting.append(job)
	for job: ImpostorJob in waiting:
		WorkerThreadPool.wait_for_task_completion(job.task_id)
		var mesh: ArrayMesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, job.arrays)
		var landmark: LandblockTerrain.MeshMerge = CalderaKit.merge()
		job.builder.landmark_silhouette(landmark)
		if not landmark.is_empty():
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = landmark.vertices
			arrays[Mesh.ARRAY_NORMAL] = landmark.normals
			arrays[Mesh.ARRAY_COLOR] = landmark.colors
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_impostor_meshes[job.builder.isle.isle_id] = mesh
	for isle_id: StringName in CalderaAtlas.ISLES:
		if isle_id == active_isle:
			continue
		var node: MeshInstance3D = MeshInstance3D.new()
		node.name = "Impostor_%s" % String(isle_id).trim_prefix("isle_")
		node.mesh = _impostor_meshes[isle_id]
		node.material_override = impostor_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.position = CalderaAtlas.offset_between(active_isle, isle_id)
		node.scale = Vector3(1.0, IMPOSTOR_LIFT, 1.0)
		node.set_meta(&"isle_id", isle_id)
		impostors.add_child(node)
		if isle_id == CalderaAtlas.ISLE_THE_CROWN:
			# The World-Tree answers each trial even from the far quays: its boughs share the live tree's materials.
			var far_tree: Node3D = WorldTree.make_far_crown()
			far_tree.position = CrownHeartCragBuilder.WORLD_TREE_AT
			# Lifted with the island, and as broad as it is tall.
			far_tree.scale = Vector3(IMPOSTOR_LIFT, 1.0, IMPOSTOR_LIFT)
			node.add_child(far_tree)


## The impostor standing for `isle_id` (null for the live island).
func impostor_for(isle_id: StringName) -> MeshInstance3D:
	for child: Node in impostors.get_children():
		if child.get_meta(&"isle_id", &"") == isle_id:
			return child as MeshInstance3D
	return null
