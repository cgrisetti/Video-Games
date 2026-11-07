## The Landblock grid (10_WORLD_ARCHITECTURE.md §2): every world position maps
## to a 128 m x 128 m Landblock (a chunk, Vector2i(x, z)) and every Landblock to
## a 1024 m Region of 8 x 8, in O(1). Chunk (0, 0) covers X and Z in [0, 128).
##
## The streaming radii are Chebyshev distances in chunks from the nearest
## player (the union over every split-screen and network player), each with a
## wider unload radius so a player dancing on a seam never makes chunks thrash.
class_name WorldGridConfig
extends RefCounted

const CHUNK_SIZE: float = 128.0
const REGION_CHUNKS: int = 8
const REGION_SIZE: float = 1024.0

## Layer 3 (interactive gameplay) and Layer 4 (navigation): the 3 x 3 around a player.
const LOAD_GAMEPLAY_RADIUS: int = 1
const UNLOAD_GAMEPLAY_RADIUS: int = 2
## Layer 2 (instanced clutter and foliage).
const LOAD_CLUTTER_RADIUS: int = 2
const UNLOAD_CLUTTER_RADIUS: int = 3
## Layer 1 (terrain and the HLOD horizon).
const LOAD_HLOD_RADIUS: int = 3
const UNLOAD_HLOD_RADIUS: int = 4

## Main-thread time the streaming queue may spend attaching nodes each frame (2 ms).
const FRAME_BUDGET_USEC: int = 2000
## Seconds between streaming decisions (the 5 Hz heartbeat).
const STREAM_HEARTBEAT: float = 0.2

## The Doverslap Falls world's bounds, inclusive: the Bramble-Bridge-to-Doverslap corridor
## (x = 0, z = 0 to -3) and the ring of crags around it (x = -1 and 1, z = 1 and -4).
const BOUNDS_MIN: Vector2i = Vector2i(-1, -4)
const BOUNDS_MAX: Vector2i = Vector2i(1, 1)

## The world being streamed. Its WorldGridManager picks it (use_layout) before
## anything streams; until then it's Doverslap Falls corridor, which the level
## builder and the tests use. Read from worker threads, never changed while
## a world is streaming.
static var layout: WorldLayout = DoverslapLayout.new()


## Switches to the layout named `id` (DoverslapLayout.LAYOUT_ID, OakshireValeLayout.LAYOUT_ID).
static func use_layout(id: StringName) -> void:
	if layout != null and layout.layout_id() == id:
		return
	match id:
		OakshireValeLayout.LAYOUT_ID:
			layout = OakshireValeLayout.new()
		_:
			layout = DoverslapLayout.new()


static func world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / CHUNK_SIZE), floori(pos.z / CHUNK_SIZE))


## The chunk's north-west corner (smallest X and Z), on the ground plane.
static func chunk_to_world_origin(chunk: Vector2i) -> Vector3:
	return Vector3(chunk.x * CHUNK_SIZE, 0.0, chunk.y * CHUNK_SIZE)


static func chunk_to_world_center(chunk: Vector2i) -> Vector3:
	return chunk_to_world_origin(chunk) + Vector3(CHUNK_SIZE * 0.5, 0.0, CHUNK_SIZE * 0.5)


static func world_to_region(pos: Vector3) -> Vector2i:
	var chunk: Vector2i = world_to_chunk(pos)
	return Vector2i(floori(float(chunk.x) / REGION_CHUNKS), floori(float(chunk.y) / REGION_CHUNKS))


static func chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## The distance to the nearest focus (the union of every player's radius); a
## large number when there's nobody to stream around.
static func min_chebyshev_to_focuses(chunk: Vector2i, focus_chunks: Array[Vector2i]) -> int:
	var nearest: int = 1 << 30
	for focus: Vector2i in focus_chunks:
		nearest = mini(nearest, chebyshev_distance(chunk, focus))
	return nearest


static func in_bounds(chunk: Vector2i) -> bool:
	var low: Vector2i = layout.bounds_min()
	var high: Vector2i = layout.bounds_max()
	return chunk.x >= low.x and chunk.x <= high.x and chunk.y >= low.y and chunk.y <= high.y


## Every chunk of the current world, row by row from the north.
static func all_chunks() -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	var low: Vector2i = layout.bounds_min()
	var high: Vector2i = layout.bounds_max()
	for z: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			chunks.append(Vector2i(x, z))
	return chunks


## The world-space box a chunk covers, from `bottom` up `height` metres.
static func chunk_aabb(chunk: Vector2i, bottom: float, height: float) -> AABB:
	return AABB(chunk_to_world_origin(chunk) + Vector3(0.0, bottom, 0.0), Vector3(CHUNK_SIZE, height, CHUNK_SIZE))


## "0_-1", for node and file names.
static func chunk_key(chunk: Vector2i) -> String:
	return "%d_%d" % [chunk.x, chunk.y]
