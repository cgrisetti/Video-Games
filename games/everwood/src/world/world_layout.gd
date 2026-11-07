## What one seamless world is (10_WORLD_ARCHITECTURE.md, 12_WORLD_OAKSHIRE_VALE_GDD.md):
## its bounds, its ground, what grows on it and which landblocks fill it. The
## Landblock streaming (WorldGridManager, LandblockTerrain, LandblockClutter)
## asks the current layout (WorldGridConfig.layout) instead of knowing any one
## world, so the Bramble-Bridge-to-Doverslap corridor (DoverslapLayout) and Oakshire
## Vale (OakshireValeLayout) stream through the same code.
##
## Every method is pure and safe on a worker thread, except the make_* ones,
## which build nodes on the main thread.
class_name WorldLayout
extends RefCounted

## What a spot shows on the Wayfarer's map (18 GDD §7.1).
enum MapFeature { GROUND, ROAD, WATER }


## The id a world's grid manager names its layout by (WorldGridConfig.use_layout).
func layout_id() -> StringName:
	return &""


## The bounded world, inclusive, in chunks.
func bounds_min() -> Vector2i:
	return Vector2i.ZERO


func bounds_max() -> Vector2i:
	return Vector2i.ZERO


## The world rectangle the Wayfarer's map shows (x, z): the whole bounded world by default.
func map_rect() -> Rect2:
	var low: Vector3 = WorldGridConfig.chunk_to_world_origin(bounds_min())
	var high: Vector3 = WorldGridConfig.chunk_to_world_origin(bounds_max() + Vector2i.ONE)
	return Rect2(low.x, low.z, high.x - low.x, high.z - low.z)


## What the map shows at (x, z), whose height is `height` (MapFeature).
func map_feature(_world_x: float, _world_z: float, _height: float) -> int:
	return MapFeature.GROUND


## The footprints and Hush-Cracks the world's level builder listed for the map, or "".
func cartography_path() -> String:
	return ""


## The ground's height at world (x, z): continuous everywhere, so chunks meet without seams.
func sample_height(_world_x: float, _world_z: float) -> float:
	return 0.0


## The ground's colour at world (x, z), whose height is `height`.
func surface_color(_world_x: float, _world_z: float, _height: float) -> Color:
	return Color(0.4, 0.5, 0.3)


## Whether a chunk can be walked on: it gets a terrain collider when its gameplay streams in.
func has_collision(_chunk: Vector2i) -> bool:
	return false


## Whether a chunk bakes navigation (Layer 4).
func has_navigation(chunk: Vector2i) -> bool:
	return has_collision(chunk)


## The navigation source triangles of a chunk's ground (spilling past its edges so tiles meet).
func nav_faces(_chunk: Vector2i) -> PackedVector3Array:
	return PackedVector3Array()


## Solid props on a walkable chunk, beside its height map: [{"box": size} or
## {"cylinder": Vector2(radius, height)}, "transform": Transform3D, "low": bool]
## ("low" ones go on the low-scenery layer, the rest block cameras and shots too).
func solid_pieces(_chunk: Vector2i) -> Array[Dictionary]:
	var none: Array[Dictionary] = []
	return none


## The chunk's landblock (its gameplay layer) and HLOD mesh, or "" for none.
func landblock_path(_chunk: Vector2i) -> String:
	return ""


func hlod_path(_chunk: Vector2i) -> String:
	return ""


## Chunks whose state outlives a fresh run (WorldStateDB.reset_expedition keeps them).
func is_persistent(_chunk: Vector2i) -> bool:
	return false


## Layer 2: the chunk's clutter, packed for MultiMeshes (worker thread), and its node (main thread).
func build_clutter_data(_chunk: Vector2i) -> Dictionary:
	return {}


func make_clutter_node(chunk: Vector2i, _data: Dictionary) -> Node3D:
	var empty: Node3D = Node3D.new()
	empty.name = "Clutter_%s" % WorldGridConfig.chunk_key(chunk)
	return empty


## The rest of Layer 1 (main thread): occluders, far landmarks and water; null for none.
func make_occluders(_chunk: Vector2i) -> OccluderInstance3D:
	return null


func make_horizon_landmark(_chunk: Vector2i) -> Node3D:
	return null
