## The first seamless world (10_WORLD_ARCHITECTURE.md): Bramblebridge and the
## Doverslap corridor north of it, x = 0 and z = 0 to -3 with a ring of crags
## round it. Its shape lives in LandblockManifest and LandblockTerrain's
## corridor functions, its clutter in LandblockClutter; this hands them to the
## streaming.
class_name DoverslapLayout
extends WorldLayout

const LAYOUT_ID: StringName = &"doverslap"


func layout_id() -> StringName:
	return LAYOUT_ID


func bounds_min() -> Vector2i:
	return WorldGridConfig.BOUNDS_MIN


func bounds_max() -> Vector2i:
	return WorldGridConfig.BOUNDS_MAX


func sample_height(world_x: float, world_z: float) -> float:
	return LandblockTerrain.corridor_height(world_x, world_z)


func surface_color(world_x: float, world_z: float, height: float) -> Color:
	return LandblockTerrain.corridor_surface_color(world_x, world_z, height)


## Only the corridor is walked; the crags round it are scenery.
func has_collision(chunk: Vector2i) -> bool:
	return LandblockManifest.is_corridor(chunk)


func nav_faces(chunk: Vector2i) -> PackedVector3Array:
	return LandblockTerrain.corridor_nav_faces(chunk)


## The low dry-stone walls along the trails.
func solid_pieces(chunk: Vector2i) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	for piece: Transform3D in LandblockTerrain.trail_wall_pieces(chunk):
		pieces.append({"box": Vector3(0.6, LandblockTerrain.TRAIL_WALL_HEIGHT, LandblockTerrain.TRAIL_WALL_PIECE), "transform": piece, "low": true})
	return pieces


func landblock_path(chunk: Vector2i) -> String:
	return LandblockManifest.landblock_path(chunk)


func hlod_path(chunk: Vector2i) -> String:
	return LandblockManifest.hlod_path(chunk)


func is_persistent(chunk: Vector2i) -> bool:
	return LandblockManifest.is_persistent(chunk)


func build_clutter_data(chunk: Vector2i) -> Dictionary:
	return LandblockClutter.build_clutter_data(chunk)


func make_clutter_node(chunk: Vector2i, data: Dictionary) -> Node3D:
	return LandblockClutter.make_clutter_node(chunk, data)


func make_occluders(chunk: Vector2i) -> OccluderInstance3D:
	return LandblockTerrain.make_occluders(chunk)


func make_horizon_landmark(chunk: Vector2i) -> Node3D:
	return LandblockTerrain.make_horizon_landmark(chunk)
