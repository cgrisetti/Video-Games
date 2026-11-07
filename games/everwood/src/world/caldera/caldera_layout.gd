## The live Caldera island seen through the WorldLayout contract, so the
## systems that ask WorldGridConfig.layout (a spawner placing its pack on the
## ground, ambient flocks, the Wayfarer's Atlas) work on whichever island the
## ArchipelagoStreamer has live. The streamer swaps in a new one per island.
class_name CalderaLayout
extends WorldLayout

var builder: IslandBuilder


func _init(island: IslandBuilder) -> void:
	builder = island


func layout_id() -> StringName:
	return StringName("caldera_%s" % String(builder.isle.isle_id).trim_prefix("isle_"))


func bounds_min() -> Vector2i:
	return Vector2i(builder.isle.chunk_min(), builder.isle.chunk_min_z())


func bounds_max() -> Vector2i:
	return Vector2i(builder.isle.chunk_max(), builder.isle.chunk_max_z())


func map_rect() -> Rect2:
	var half: Vector2 = builder.isle.half_size()
	return Rect2(-half, half * 2.0)


func map_feature(world_x: float, world_z: float, height: float) -> int:
	var sea: float = CalderaWorldState.current.sea_level_y if CalderaWorldState.current != null else 0.0
	if height < sea:
		return MapFeature.WATER
	return MapFeature.ROAD if builder.on_path(world_x, world_z) else MapFeature.GROUND


func sample_height(world_x: float, world_z: float) -> float:
	return builder.height_at(world_x, world_z)


func surface_color(world_x: float, world_z: float, height: float) -> Color:
	return builder.surface_color(world_x, world_z, height, 1.0)
