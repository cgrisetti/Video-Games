## Layer 4 of a Landblock (10_WORLD_ARCHITECTURE.md §4.3): chunked navigation
## and the AI tick scaler.
##
## Every loaded gameplay chunk gets its own NavigationRegion3D, baked off the
## main thread from its landblock's colliders (walls, houses, banks, piers,
## the bridge deck) and the terrain floor. Each bake is clipped to its chunk
## but sees a few metres past it, and the world's navigation map joins edges
## that meet within half a metre, so paths run straight across the seams: out
## of Bramblebridge's gate into the Moss-Oaks, up the holloway, over the gorge
## bridge. The classic Dojo bakes one region for its whole expedition the same way.
##
## Companions and woodland minions follow those paths (NavSteering), falling
## back to walking straight at their goal in the open or before a bake is done.
##
## The tick scaler lets far-off AI rest: within 35 m of a player an enemy thinks
## every physics tick, from 35 to 90 m ten times a second, and past 90 m it's
## dormant (its physics stops) until someone comes near. Enemies in a fight
## always think at full rate.
class_name ChunkNavBuilder
extends RefCounted

const CELL_SIZE: float = 0.25
const CELL_HEIGHT: float = 0.25
const EDGE_CONNECTION_MARGIN: float = 0.5
## The agent, rounded to whole cells (a body is 0.45 m round and 1.7 m tall, and steps up 0.35 m).
const AGENT_RADIUS: float = 0.5
const AGENT_HEIGHT: float = 1.75
const AGENT_MAX_CLIMB: float = 0.25
## Walkable slopes: the 13° ramps, the trails and the arch, with room to spare.
const AGENT_MAX_SLOPE: float = 40.0
## An unwalkable border round each bake (inside its area, which is grown by
## this much), so tiles keep their full width up to the chunk's edge and meet.
const BORDER_SIZE: float = 1.0
const EDGE_MAX_ERROR: float = 0.9
const BAKE_HEIGHT: float = 80.0
const BAKE_BOTTOM: float = -30.0

const FULL_TICK_RADIUS: float = 35.0
const REDUCED_TICK_RADIUS: float = 90.0
const REDUCED_TICK_INTERVAL: float = 0.1


## The world's navigation map, set up so chunk tiles stitch: 0.25 m cells, 0.5 m edge joins.
static func configure_map(map: RID) -> void:
	NavigationServer3D.map_set_cell_size(map, CELL_SIZE)
	NavigationServer3D.map_set_cell_height(map, CELL_HEIGHT)
	NavigationServer3D.map_set_edge_connection_margin(map, EDGE_CONNECTION_MARGIN)


## A navigation mesh to bake over `area` (parsing static colliders on the world and low-scenery layers).
static func new_navigation_mesh(area: AABB) -> NavigationMesh:
	var navmesh: NavigationMesh = NavigationMesh.new()
	navmesh.cell_size = CELL_SIZE
	navmesh.cell_height = CELL_HEIGHT
	navmesh.agent_radius = AGENT_RADIUS
	navmesh.agent_height = AGENT_HEIGHT
	navmesh.agent_max_climb = AGENT_MAX_CLIMB
	navmesh.agent_max_slope = AGENT_MAX_SLOPE
	navmesh.edge_max_error = EDGE_MAX_ERROR
	navmesh.border_size = BORDER_SIZE
	navmesh.filter_baking_aabb = area
	navmesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navmesh.geometry_collision_mask = ActorBase.LAYER_WORLD | ActorBase.LAYER_LOW_SCENERY
	navmesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	return navmesh


## One bake running on a worker thread. Its owner polls it (finish_if_done)
## and waits for it before going away, so nothing is left running at exit.
class BakeJob:
	extends RefCounted

	var navmesh: NavigationMesh
	var source: NavigationMeshSourceGeometryData3D
	var task_id: int = -1
	var _region: WeakRef
	var _done: Callable

	func _init(region: NavigationRegion3D, mesh: NavigationMesh, geometry: NavigationMeshSourceGeometryData3D, done: Callable) -> void:
		_region = weakref(region)
		navmesh = mesh
		source = geometry
		_done = done

	func run() -> void:
		NavigationServer3D.bake_from_source_geometry_data(navmesh, source)

	func start() -> void:
		task_id = WorkerThreadPool.add_task(run, false, "Navigation bake")

	## Main thread: hands the mesh to its region (if it's still there) once baked. True when finished.
	func finish_if_done() -> bool:
		if not WorkerThreadPool.is_task_completed(task_id):
			return false
		WorkerThreadPool.wait_for_task_completion(task_id)
		var region: NavigationRegion3D = _region.get_ref() as NavigationRegion3D
		if region != null:
			region.navigation_mesh = navmesh
			if _done.is_valid():
				_done.call()
		_done = Callable()
		return true

	## Blocks until the worker is done (leaving the scene); the mesh is dropped.
	func wait() -> void:
		WorkerThreadPool.wait_for_task_completion(task_id)
		_done = Callable()


## Bakes `region` over `area` from the colliders under `parse_root` (or, with
## `source_group`, under the nodes in that group) plus `extra_faces`
## (world-space triangles: the terrain floor). Geometry is parsed relative to
## `parse_root`, so it should sit at the world origin. Parsing happens now, on
## the main thread; the bake runs on a worker. Poll the returned job each frame
## (finish_if_done): `done` runs on the main thread once the region has its mesh.
static func bake_region(region: NavigationRegion3D, parse_root: Node, extra_faces: PackedVector3Array, area: AABB, done: Callable,
		source_group: StringName = &"") -> BakeJob:
	var navmesh: NavigationMesh = new_navigation_mesh(area)
	if source_group != &"":
		navmesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
		navmesh.geometry_source_group_name = source_group
	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	if parse_root != null:
		NavigationServer3D.parse_source_geometry_data(navmesh, source, parse_root)
	if not extra_faces.is_empty():
		source.add_faces(extra_faces, Transform3D.IDENTITY)
	var job: BakeJob = BakeJob.new(region, navmesh, source, done)
	job.start()
	return job


## The group a chunk's landblock joins so its colliders are parsed for navigation.
static func source_group(chunk: Vector2i) -> StringName:
	return StringName("nav_source_%s" % WorldGridConfig.chunk_key(chunk))


## A chunk's world-space bake area: the chunk grown by the unwalkable bake
## border, so its mesh ends exactly on the chunk's edges and meets its neighbours'.
static func chunk_area(chunk: Vector2i) -> AABB:
	var area: AABB = WorldGridConfig.chunk_aabb(chunk, BAKE_BOTTOM, BAKE_HEIGHT)
	return AABB(area.position - Vector3(BORDER_SIZE, 0.0, BORDER_SIZE), area.size + Vector3(BORDER_SIZE * 2.0, 0.0, BORDER_SIZE * 2.0))


## A path over the map from `from` to `to`, or empty when there's no mesh yet.
static func path_between(map: RID, from: Vector3, to: Vector3) -> PackedVector3Array:
	if not map.is_valid() or NavigationServer3D.map_get_regions(map).is_empty() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(map, from, to, true)


# --- AI tick scaling ------------------------------------------------------

## Seconds between an AI's thoughts at `distance` from the nearest player: 0
## every tick, REDUCED_TICK_INTERVAL in the middle band, -1 for dormant.
static func tick_interval_for(distance: float) -> float:
	if distance <= FULL_TICK_RADIUS:
		return 0.0
	if distance <= REDUCED_TICK_RADIUS:
		return REDUCED_TICK_INTERVAL
	return -1.0


## Host: sets every enemy's thinking rate from its distance to the nearest of
## `players` (enemies in a fight always think at full rate).
static func apply_tick_scaling(enemies: Array[ActorBase], players: Array[ActorBase]) -> void:
	for enemy: ActorBase in enemies:
		if not enemy.is_multiplayer_authority():
			continue
		var nearest: float = INF
		for player: ActorBase in players:
			nearest = minf(nearest, enemy.global_position.distance_to(player.global_position))
		var interval: float = 0.0 if enemy.is_engaged() else tick_interval_for(nearest)
		enemy.set_physics_process(interval >= 0.0)
		enemy.ai_tick_interval = maxf(interval, 0.0)
