## The Master Atlas as data (docs/20_CALDERA_ATLAS_AND_CROWN_BIBLE.md Part I;
## docs/atlas_sources/02_master_atlas_caldera_isles.pdf): five island grids,
## four load seams, and where each island sits in The Sound.
##
## The Sound's frame puts The Crown at the origin with north at -Z. Island
## grids never overlap there, and every island's landmark lies within the
## Caldera cameras' reach of North Quay, so the horizon impostors stand where
## the atlas draws them. Each island also has its own local frame (its grid
## centred on the origin); only one island is ever loaded, at the origin.
class_name CalderaAtlas
extends RefCounted

const ISLE_EMBERSHORE: StringName = &"isle_embershore"
## The starting isle's old name (Oakshire Holm, then Miller's Oak): the same island, kept so older code and saves still find it.
const ISLE_OAKSHIRE_HOLM: StringName = ISLE_EMBERSHORE
const ISLE_IRON_NESS: StringName = &"isle_iron_ness"
const ISLE_BARROW_EYOT: StringName = &"isle_barrow_eyot"
const ISLE_RIME_FIRTH: StringName = &"isle_rime_firth"
const ISLE_THE_CROWN: StringName = &"isle_the_crown"
const ISLES: Array[StringName] = [ISLE_EMBERSHORE, ISLE_IRON_NESS, ISLE_BARROW_EYOT, ISLE_RIME_FIRTH, ISLE_THE_CROWN]

const SEAM_WEST_STRAIT: StringName = &"seam_west_strait"
const SEAM_EEL_SPIT: StringName = &"seam_eel_spit"
const SEAM_SALT_ROAD: StringName = &"seam_salt_road"
const SEAM_CROWN_LANDING: StringName = &"seam_crown_landing"
const SEAMS: Array[StringName] = [SEAM_WEST_STRAIT, SEAM_EEL_SPIT, SEAM_SALT_ROAD, SEAM_CROWN_LANDING]

## Arrival points every builder may name. The start's id is from before the Level 1 spawn
## moved into Lee-Shore Orchards (docs/29 §4); kept so saves and tools still find it.
const ARRIVE_START: StringName = &"bramblebridge_green"
## The start's other name (the Lee-Shore Orchards), the same arrival.
const ARRIVE_ORCHARDS: StringName = ARRIVE_START
const ARRIVE_NORTH_QUAY: StringName = &"north_quay"
const ARRIVE_ROOT_SANCTUM: StringName = &"root_sanctum"
const ARRIVE_SOUTH_BAY: StringName = &"south_bay_landing"
const ARRIVE_BEACON: StringName = &"beacon"
const ARRIVE_QUAY: StringName = &"quay"
const ARRIVE_SUMMIT: StringName = &"summit_glade"

## The friction isles' lanes all reopen once the Root-Sanctum is cleared.
const LANES_DARK_LINE: String = "The lane is dark. Clear the Root-Sanctum in Embershore (Lv 6) to open it."
const CROWN_SHUT_LINE: String = "The Crown's currents run wild. Light all three Beacons to calm them."

static var _isles: Dictionary[StringName, IslandGridResource] = {}
static var _seams: Dictionary[StringName, LoadSeamResource] = {}
static var _builders: Dictionary[StringName, IslandBuilder] = {}


static func isle(id: StringName) -> IslandGridResource:
	_ensure()
	return _isles.get(id, null)


static func isles() -> Array[IslandGridResource]:
	_ensure()
	var list: Array[IslandGridResource] = []
	for id: StringName in ISLES:
		list.append(_isles[id])
	return list


static func seam(id: StringName) -> LoadSeamResource:
	_ensure()
	return _seams.get(id, null)


static func seams() -> Array[LoadSeamResource]:
	_ensure()
	var list: Array[LoadSeamResource] = []
	for id: StringName in SEAMS:
		list.append(_seams[id])
	return list


## The seams with an end on `isle_id`.
static func seams_of(isle_id: StringName) -> Array[LoadSeamResource]:
	var list: Array[LoadSeamResource] = []
	for each: LoadSeamResource in seams():
		if each.touches(isle_id):
			list.append(each)
	return list


## The island's builder (made once, on the main thread; its sampling is then safe on workers).
static func builder_for(id: StringName) -> IslandBuilder:
	_ensure()
	if _builders.has(id):
		return _builders[id]
	var made: IslandBuilder
	match id:
		ISLE_EMBERSHORE:
			made = EmbershoreBuilder.new(_isles[id])
		ISLE_THE_CROWN:
			made = CrownHeartCragBuilder.new(_isles[id])
		ISLE_IRON_NESS, ISLE_BARROW_EYOT, ISLE_RIME_FIRTH:
			made = FrictionIslesBuilder.new(_isles[id])
		_:
			return null
	_builders[id] = made
	return made


## Where island `other` sits seen from island `from`'s frame (its centre, y = 0).
static func offset_between(from: StringName, other: StringName) -> Vector3:
	var a: Vector2 = isle(from).sound_position
	var b: Vector2 = isle(other).sound_position
	return Vector3(b.x - a.x, 0.0, b.y - a.y)


## Every name the Caldera shows a player (the Lens's Rule 4 check reads these).
static func shown_names() -> Array[String]:
	var names: Array[String] = []
	for each: IslandGridResource in isles():
		names.append_array([each.display_name, each.steading, each.landmark, each.ebb_reveal, each.current_name, each.calling_title])
	for each: LoadSeamResource in seams():
		names.append_array([each.display_name, each.closed_line])
	names.append_array([LANES_DARK_LINE, CROWN_SHUT_LINE])
	for id: StringName in ISLES:
		for place: Dictionary in builder_for(id).places:
			names.append(String(place["name"]))
	return names


static func _ensure() -> void:
	if not _isles.is_empty():
		return
	# Embershore (docs/27): a 2:1 grid, 16 x 8 landblocks, 1,850 m south of The Crown so its corners clear the outer isles' grids.
	_isle(ISLE_EMBERSHORE, "Embershore", "South", 1, 6, ScribeSignResource.Sign.SIGN_WARM_HEARTH, "", 16, Vector2(0.0, 1850.0),
		"Hearthstead", "Windmill", "The Old Quay", &"", "", WorldVisualCatalog.OAKSHIRE_WICK, &"millers_holm",
		Color(0.96, 0.78, 0.36), 8)
	# The three Friction Isles each wear their own light (docs/33 §3.3-3.4); their music is still borrowed (docs/20 Part III §2.9).
	_isle(ISLE_IRON_NESS, "Iron-Ness", "West", 6, 10, ScribeSignResource.Sign.SIGN_IRON_ROOT, "Shield-Sworn", 12, Vector2(-1650.0, 350.0),
		"Forge-Gorge", "Forge Stacks", "Raid Gate A: the Under-Forge Abyss", CalderaWorldState.BEACON_IRON, "Iron Current",
		WorldVisualCatalog.IRON_NESS, &"dover_slap_falls", Color(0.86, 0.52, 0.26))
	_isle(ISLE_BARROW_EYOT, "Barrow-Eyot", "East", 8, 12, ScribeSignResource.Sign.SIGN_STAR_TIDE, "Lantern-Bearers", 12, Vector2(1650.0, 550.0),
		"Lantern Staithe", "Bell-Tower", "Raid Gate C: the Sunken Cathedral", CalderaWorldState.BEACON_TIDE, "Tide Current",
		WorldVisualCatalog.BARROW_EYOT, &"moss_oak_hollow", Color(0.62, 0.48, 0.86))
	_isle(ISLE_RIME_FIRTH, "Rime-Firth", "North", 10, 14, ScribeSignResource.Sign.SIGN_RIME_GALE, "Wayfarers", 12, Vector2(100.0, -1600.0),
		"Gale-Hall", "Snow Peak", "Raid Gate B: the Frost-Peak Aerie", CalderaWorldState.BEACON_GALE, "Gale Current",
		WorldVisualCatalog.RIME_FIRTH, &"dover_slap_falls", Color(0.48, 0.72, 0.92))
	# The Crown plays its Audio Mosaic all over the isle (docs/16 §7, Clay's choice of 2026-11-06); a profile
	# that isn't a mosaic here brings back its five shore suites (docs/23 §7, CrownHeartCragBuilder.music_at).
	_isle(ISLE_THE_CROWN, "The Crown", "Centre", 13, 14, ScribeSignResource.Sign.NONE, "", 8, Vector2.ZERO,
		"Lantern-Bearers' Waypost", "World-Tree", "The Sea-Door to the Heart", &"", "",
		WorldVisualCatalog.SUNKEN_CROWN_FALLS, &"crown_island", Color(0.98, 0.84, 0.42))
	# Embershore's ends and directions come from its generator (docs/27 §1: causeways and skiffs), in its own frame.
	# A causeway's deck is level from shore to shore at Embershore's head height; the far isle's arrival pad rises to meet it.
	_seam(SEAM_WEST_STRAIT, "The West Strait", LoadSeamResource.SeamSkin.WALKABLE_CAUSEWAY, false,
		ISLE_EMBERSHORE, Vector3(-918.19, 1.86, -286.72), ISLE_IRON_NESS, Vector3(250.0, 1.86, 512.0),
		CalderaWorldState.ROOT_SANCTUM_CLEARED, LANES_DARK_LINE, Vector2(-0.8768, -0.4809))
	_seam(SEAM_EEL_SPIT, "Eel Spit", LoadSeamResource.SeamSkin.WALKABLE_CAUSEWAY, true,
		ISLE_EMBERSHORE, Vector3(967.68, 4.77, -382.29), ISLE_BARROW_EYOT, Vector3(-260.0, 4.77, 458.0),
		CalderaWorldState.ROOT_SANCTUM_CLEARED, LANES_DARK_LINE, Vector2(0.7624, -0.647))
	_seam(SEAM_SALT_ROAD, "The Salt Road", LoadSeamResource.SeamSkin.LANTERN_SKIFF, false,
		ISLE_EMBERSHORE, Vector3(47.79, 1.6, -262.83), ISLE_RIME_FIRTH, Vector3(60.0, 1.6, 470.0),
		CalderaWorldState.ROOT_SANCTUM_CLEARED, LANES_DARK_LINE, Vector2(0.7428, -0.6695))
	_seam(SEAM_CROWN_LANDING, "The Crown Landing", LoadSeamResource.SeamSkin.LANTERN_SKIFF, false,
		ISLE_EMBERSHORE, Vector3(37.55, 1.6, -262.83), ISLE_THE_CROWN, Vector3(0.0, 1.6, 414.0),
		CalderaWorldState.CROWN_LANDING, CROWN_SHUT_LINE, Vector2(0.0, -1.0))


static func _isle(id: StringName, label: String, compass: String, low: int, high: int, scribe_sign: int, calling: String, chunks: int,
		sound_position: Vector2, steading: String, landmark: String, ebb: String, beacon: StringName, current_name: String,
		biome: StringName, music: StringName, accent: Color, chunks_z: int = 0) -> void:
	var made: IslandGridResource = IslandGridResource.new()
	made.isle_id = id
	made.display_name = label
	made.compass = compass
	made.level_min = low
	made.level_max = high
	made.scribe_sign = scribe_sign as ScribeSignResource.Sign
	made.calling_title = calling
	made.chunks = chunks
	made.chunks_z = chunks_z
	made.sound_position = sound_position
	made.steading = steading
	made.landmark = landmark
	made.ebb_reveal = ebb
	made.beacon_flag = beacon
	made.current_name = current_name
	made.visual_biome = biome
	made.music_profile = music
	made.accent_color = accent
	_isles[id] = made


static func _seam(id: StringName, label: String, skin: LoadSeamResource.SeamSkin, shingle: bool, isle_a: StringName, anchor_a: Vector3,
		isle_b: StringName, anchor_b: Vector3, gate: StringName, closed_line: String, direction: Vector2 = Vector2(0.0, -1.0)) -> void:
	var made: LoadSeamResource = LoadSeamResource.new()
	made.seam_id = id
	made.display_name = label
	made.skin = skin
	made.shingle = shingle
	made.isle_a = isle_a
	made.anchor_a = anchor_a
	made.isle_b = isle_b
	made.anchor_b = anchor_b
	made.direction = direction.normalized()
	made.gate_flag = gate
	made.closed_line = closed_line
	_seams[id] = made
