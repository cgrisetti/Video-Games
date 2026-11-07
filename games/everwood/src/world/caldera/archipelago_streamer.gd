## Streams the Caldera Isles (docs/20 Part I; the Musk Razor's 5 grids, 4
## seams): exactly one island grid is live at a time, at the origin.
##
##   - Every landblock of the live island shows a light 8 m stand-in (with its
##     trees, reeds and stones), so the whole island reads from anywhere on it.
##   - A 3 x 3 window of landblocks round the Soul Tether centroid (the middle
##     of the party), plus the landblock under every hero, gets the 2 m ground
##     and its collider; it follows the party and drops what falls behind.
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
	var near: bool
	var task_id: int = -1
	var data: Dictionary = {}

	func run() -> void:
		data = builder.build_chunk_data(chunk, IslandBuilder.NEAR_QUADS if near else IslandBuilder.FAR_QUADS, near, not near)


## One landblock of the live island and its nodes.
class LoadedChunk:
	extends RefCounted

	var chunk: Vector2i
	var root: Node3D
	var far_mesh: MeshInstance3D
	var near_mesh: MeshInstance3D
	var body: StaticBody3D
	## Species -> Array of Transform3D (for trunk colliders in the window).
	var scatter: Dictionary = {}
	var far_job: ChunkJob
	var near_job: ChunkJob


## An island's far silhouette heights, built on a worker thread.
class ImpostorJob:
	extends RefCounted

	var builder: IslandBuilder
	var task_id: int = -1
	var arrays: Array = []

	func run() -> void:
		var half: float = builder.isle.half_size_m()
		var step: float = ArchipelagoStreamer.IMPOSTOR_STEP
		var side: int = int(half * 2.0 / step) + 1
		var vertices: PackedVector3Array = PackedVector3Array()
		var colors: PackedColorArray = PackedColorArray()
		vertices.resize(side * side)
		colors.resize(side * side)
		for row: int in side:
			for column: int in side:
				var x: float = -half + column * step
				var z: float = -half + row * step
				var h: float = builder.height_at(x, z)
				vertices[row * side + column] = Vector3(x, h, z)
				colors[row * side + column] = builder.surface_color(x, z, h, 1.0 if h > 1.5 else 0.9)
		var normals: PackedVector3Array = PackedVector3Array()
		normals.resize(side * side)
		for row: int in side:
			for column: int in side:
				var left: float = vertices[row * side + maxi(column - 1, 0)].y
				var right: float = vertices[row * side + mini(column + 1, side - 1)].y
				var back: float = vertices[maxi(row - 1, 0) * side + column].y
				var front: float = vertices[mini(row + 1, side - 1) * side + column].y
				normals[row * side + column] = Vector3((left - right) / (2.0 * step), 1.0, (back - front) / (2.0 * step)).normalized()
		var indices: PackedInt32Array = PackedInt32Array()
		for row: int in side - 1:
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
	WorldGridConfig.layout = CalderaLayout.new(builder)
	structures = Node3D.new()
	structures.name = "Island_%s" % String(isle_id).trim_prefix("isle_")
	add_child(structures)
	builder.build_structures(structures)
	var low: int = builder.isle.chunk_min()
	var high: int = builder.isle.chunk_max()
	for x: int in range(low, high + 1):
		for z: int in range(low, high + 1):
			var record: LoadedChunk = LoadedChunk.new()
			record.chunk = Vector2i(x, z)
			record.root = Node3D.new()
			record.root.name = "Landblock_%d_%d" % [x, z]
			_terrain.add_child(record.root)
			chunks[record.chunk] = record
			record.far_job = _dispatch(record.chunk, false)
	focus_points = focus.duplicate()
	_build_impostors()
	_refresh_sea()
	load_now(focus)
	island_activated.emit(isle_id)


## Builds, right now, the window round `points` (the first is the centroid) and the
## landblock under each, and every far stand-in still on its way.
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
			var job: ChunkJob = _make_job(chunk, true)
			job.run()
			_finish(job)


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


## How many landblocks have their window ground, their stand-in, or a job on the way (tests, telemetry).
func counts() -> Dictionary:
	var near: int = 0
	var far: int = 0
	for record: LoadedChunk in chunks.values():
		near += 1 if record.near_mesh != null else 0
		far += 1 if record.far_mesh != null else 0
	return {"near": near, "far": far, "pending": _jobs.size(), "chunks": chunks.size(),
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


func _update_window() -> void:
	for chunk: Vector2i in _wanted_near():
		var record: LoadedChunk = chunks.get(chunk, null)
		if record != null and record.near_mesh == null and record.near_job == null:
			record.near_job = _dispatch(chunk, true)
	for record: LoadedChunk in chunks.values():
		if record.near_mesh != null and not _keeps(record.chunk):
			_drop_near(record)


func _drop_near(record: LoadedChunk) -> void:
	record.near_mesh.queue_free()
	record.near_mesh = null
	if record.body != null:
		record.body.queue_free()
		record.body = null
	if record.far_mesh != null:
		record.far_mesh.visible = true
	collision_changed.emit(record.chunk, false)


# --- Jobs ------------------------------------------------------------------------------

func _make_job(chunk: Vector2i, near: bool) -> ChunkJob:
	var job: ChunkJob = ChunkJob.new()
	job.isle_id = active_isle
	job.builder = builder
	job.chunk = chunk
	job.near = near
	return job


func _dispatch(chunk: Vector2i, near: bool) -> ChunkJob:
	var job: ChunkJob = _make_job(chunk, near)
	job.task_id = WorkerThreadPool.add_task(job.run, false, "Caldera %s %s" % ["near" if near else "far", chunk])
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
	if job.near:
		if record.near_job == job:
			record.near_job = null
		if record.near_mesh != null:
			return
		record.near_mesh = _ground_mesh("Near", job.data)
		record.root.add_child(record.near_mesh)
		record.body = _collider(job.chunk, job.data, record.scatter)
		record.root.add_child(record.body)
		if record.far_mesh != null:
			record.far_mesh.visible = false
		near_builds += 1
		collision_changed.emit(job.chunk, true)
	else:
		if record.far_job == job:
			record.far_job = null
		if record.far_mesh != null:
			return
		record.far_mesh = _ground_mesh("Far", job.data)
		record.far_mesh.visible = record.near_mesh == null
		record.root.add_child(record.far_mesh)
		record.scatter = job.data.get("scatter", {}) as Dictionary
		_add_scatter(record)
		far_builds += 1


func _ground_mesh(node_name: String, data: Dictionary) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = data["normals"]
	arrays[Mesh.ARRAY_COLOR] = data["colors"]
	arrays[Mesh.ARRAY_INDEX] = data["indices"]
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, WorldVisualCatalog.terrain())
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = node_name
	ground.mesh = mesh
	return ground


## The window's collider: the ground as a height map on the low-scenery layer, and the trunks and stones that block the way.
func _collider(chunk: Vector2i, data: Dictionary, scatter: Dictionary) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = ActorBase.LAYER_LOW_SCENERY
	body.collision_mask = 0
	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = IslandBuilder.COLLISION_SIDE
	shape.map_depth = IslandBuilder.COLLISION_SIDE
	shape.map_data = data["collision_heights"]
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	var size: float = IslandGridResource.CHUNK_SIZE
	collision.position = Vector3(chunk.x * size + size * 0.5, 0.0, chunk.y * size + size * 0.5)
	body.add_child(collision)
	var solids: StaticBody3D = StaticBody3D.new()
	solids.name = "Solids"
	solids.collision_layer = ActorBase.LAYER_WORLD
	solids.collision_mask = 0
	for species: Variant in scatter:
		var radius: float = IslandBuilder.SOLID_RADIUS[int(species)]
		if radius <= 0.0:
			continue
		for where: Transform3D in scatter[species] as Array:
			var trunk: CollisionShape3D = CollisionShape3D.new()
			var cylinder: CylinderShape3D = CylinderShape3D.new()
			cylinder.radius = radius * where.basis.get_scale().x
			cylinder.height = 3.0
			trunk.shape = cylinder
			trunk.position = where.origin + Vector3(0.0, 1.5, 0.0)
			solids.add_child(trunk)
	if solids.get_child_count() > 0:
		body.add_child(solids)
	else:
		solids.free()
	return body


## A landblock's scatter, one MultiMesh per species: within CalderaKit.ATELIER_RANGE
## of a camera the sculpted atelier mesh (oak clumps, willows, pines, layered
## ferns...), past it the one-draw stand-in; small scatter is gone past SMALL_RANGE.
func _add_scatter(record: LoadedChunk) -> void:
	for species: Variant in record.scatter:
		var spots: Array = record.scatter[species] as Array
		if spots.is_empty():
			continue
		var kind: int = int(species)
		var small: bool = CalderaKit.is_small(kind)
		var atelier: ArrayMesh = CalderaKit.atelier_mesh(kind)
		if atelier != null:
			var near: MultiMeshInstance3D = _scatter_node("Atelier_%d" % kind, atelier, spots)
			near.visibility_range_end = CalderaKit.SMALL_RANGE if small else CalderaKit.ATELIER_RANGE
			near.visibility_range_end_margin = CalderaKit.ATELIER_MARGIN
			if small:
				near.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			record.root.add_child(near)
			if small:
				continue
		var node: MultiMeshInstance3D = _scatter_node("Scatter_%d" % kind, CalderaKit.species_mesh(kind), spots)
		node.material_override = CalderaKit.vertex_material()
		if atelier != null:
			node.visibility_range_begin = CalderaKit.ATELIER_RANGE
			node.visibility_range_begin_margin = CalderaKit.ATELIER_MARGIN
		elif small:
			node.visibility_range_end = CalderaKit.SMALL_RANGE
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		record.root.add_child(node)


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
			# Miller's Oak answers each trial even from the far quays: its boughs share the live tree's materials.
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
