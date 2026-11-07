## One island of the Caldera Isles (docs/20_CALDERA_ATLAS_AND_CROWN_BIBLE.md
## Part I §2): its streamed grid, where it sits in The Sound, its level band,
## Sign and Calling, its steading and landmark, and what the Ebb bares on it.
## Registered by id in CalderaAtlas; the island's shape and dressing come from
## its IslandBuilder.
class_name IslandGridResource
extends Resource

## Every island grid is cut into square landblocks this wide (metres).
const CHUNK_SIZE: float = 128.0

@export var isle_id: StringName = &""
@export var display_name: String = ""
## Where it lies from The Crown: "South", "West", "East", "North", "Centre".
@export var compass: String = ""
@export var level_min: int = 1
@export var level_max: int = 6
@export var scribe_sign: ScribeSignResource.Sign = ScribeSignResource.Sign.NONE
## The Calling whose island it is ("Shield-Sworn"), or "" for the hub.
@export var calling_title: String = ""
## Landblocks along x (12 for the outer isles, 8 for The Crown, 16 for Embershore).
@export var chunks: int = 12
## Landblocks along z; 0 means a square grid (Embershore is 16 x 8, docs/27).
@export var chunks_z: int = 0
## The island's centre in The Sound's frame (x, z metres; The Crown at the origin).
@export var sound_position: Vector2 = Vector2.ZERO
@export var steading: String = ""
## The silhouette North Quay sees ("Forge Stacks").
@export var landmark: String = ""
## What the -6 m Ebb bares on its shore.
@export var ebb_reveal: String = ""
## The CalderaWorldState flag its Beacon sets (&"" for Miller's Oak and The Crown).
@export var beacon_flag: StringName = &""
## The current round The Crown its Beacon calms ("Iron Current").
@export var current_name: String = ""
## The WorldVisualCatalog biome whose sky, sun and fog it wears.
@export var visual_biome: StringName = &""
## The AudioCatalog score that plays on it.
@export var music_profile: StringName = &""
@export var accent_color: Color = Color(0.9, 0.8, 0.5)


func chunks_x() -> int:
	return chunks


func chunks_z_count() -> int:
	return chunks_z if chunks_z > 0 else chunks


## The grid's size and half-size in metres, x by z.
func grid_size() -> Vector2:
	return Vector2(float(chunks_x()), float(chunks_z_count())) * CHUNK_SIZE


func half_size() -> Vector2:
	return grid_size() * 0.5


## The grid's longer side (metres), where one number has to do.
func grid_size_m() -> float:
	return maxf(grid_size().x, grid_size().y)


func half_size_m() -> float:
	return grid_size_m() * 0.5


## The lowest and highest landblock index on each axis (the grid is centred on the island).
func chunk_min() -> int:
	@warning_ignore("integer_division")
	return -chunks_x() / 2


func chunk_max() -> int:
	@warning_ignore("integer_division")
	return chunks_x() / 2 - 1


func chunk_min_z() -> int:
	@warning_ignore("integer_division")
	return -chunks_z_count() / 2


func chunk_max_z() -> int:
	@warning_ignore("integer_division")
	return chunks_z_count() / 2 - 1


func level_band() -> String:
	return "Lv %d–%d" % [level_min, level_max]


func contains_chunk(chunk: Vector2i) -> bool:
	return chunk.x >= chunk_min() and chunk.x <= chunk_max() and chunk.y >= chunk_min_z() and chunk.y <= chunk_max_z()


## Whether a spot (x, z) lies inside the grid.
func contains_point(x: float, z: float) -> bool:
	var half: Vector2 = half_size()
	return absf(x) <= half.x and absf(z) <= half.y


static func chunk_of(at: Vector3) -> Vector2i:
	return Vector2i(floori(at.x / CHUNK_SIZE), floori(at.z / CHUNK_SIZE))
