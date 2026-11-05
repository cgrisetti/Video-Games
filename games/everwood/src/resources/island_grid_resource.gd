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
## Landblocks per side (12 for the outer isles, 8 for The Crown).
@export var chunks: int = 12
## The island's centre in The Sound's frame (x, z metres; The Crown at the origin).
@export var sound_position: Vector2 = Vector2.ZERO
@export var steading: String = ""
## The silhouette North Quay sees ("Forge Stacks").
@export var landmark: String = ""
## What the -6 m Ebb bares on its shore.
@export var ebb_reveal: String = ""
## The CalderaWorldState flag its Beacon sets (&"" for Oakshire Holm and The Crown).
@export var beacon_flag: StringName = &""
## The current round The Crown its Beacon calms ("Iron Current").
@export var current_name: String = ""
## The WorldVisualCatalog biome whose sky, sun and fog it wears.
@export var visual_biome: StringName = &""
## The AudioCatalog score that plays on it.
@export var music_profile: StringName = &""
@export var accent_color: Color = Color(0.9, 0.8, 0.5)


func grid_size_m() -> float:
	return float(chunks) * CHUNK_SIZE


func half_size_m() -> float:
	return grid_size_m() * 0.5


## The lowest and highest landblock index on each axis (the grid is centred on the island).
func chunk_min() -> int:
	@warning_ignore("integer_division")
	return -chunks / 2


func chunk_max() -> int:
	@warning_ignore("integer_division")
	return chunks / 2 - 1


func level_band() -> String:
	return "Lv %d–%d" % [level_min, level_max]


func contains_chunk(chunk: Vector2i) -> bool:
	return chunk.x >= chunk_min() and chunk.x <= chunk_max() and chunk.y >= chunk_min() and chunk.y <= chunk_max()


static func chunk_of(at: Vector3) -> Vector2i:
	return Vector2i(floori(at.x / CHUNK_SIZE), floori(at.z / CHUNK_SIZE))
