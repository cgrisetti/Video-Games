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

const ISLE_OAKSHIRE_HOLM: StringName = &"isle_oakshire_holm"
const ISLE_IRON_NESS: StringName = &"isle_iron_ness"
const ISLE_BARROW_EYOT: StringName = &"isle_barrow_eyot"
const ISLE_RIME_FIRTH: StringName = &"isle_rime_firth"
const ISLE_THE_CROWN: StringName = &"isle_the_crown"
const ISLES: Array[StringName] = [ISLE_OAKSHIRE_HOLM, ISLE_IRON_NESS, ISLE_BARROW_EYOT, ISLE_RIME_FIRTH, ISLE_THE_CROWN]

const SEAM_WEST_STRAIT: StringName = &"seam_west_strait"
const SEAM_EEL_SPIT: StringName = &"seam_eel_spit"
const SEAM_SALT_ROAD: StringName = &"seam_salt_road"
const SEAM_CROWN_LANDING: StringName = &"seam_crown_landing"
const SEAMS: Array[StringName] = [SEAM_WEST_STRAIT, SEAM_EEL_SPIT, SEAM_SALT_ROAD, SEAM_CROWN_LANDING]

## Arrival points every builder may name.
const ARRIVE_ORCHARDS: StringName = &"lee_shore_orchards"
const ARRIVE_NORTH_QUAY: StringName = &"north_quay"
const ARRIVE_ROOT_SANCTUM: StringName = &"root_sanctum"
const ARRIVE_SOUTH_BAY: StringName = &"south_bay_landing"
const ARRIVE_BEACON: StringName = &"beacon"
const ARRIVE_QUAY: StringName = &"quay"
const ARRIVE_SUMMIT: StringName = &"summit_glade"

## The friction isles' lanes all reopen once the Root-Sanctum is cleared.
const LANES_DARK_LINE: String = "The lane is dark. Clear the Root-Sanctum in Miller's Oak (Lv 6) to open it."
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
		ISLE_OAKSHIRE_HOLM:
			made = OakshireHolmBuilder.new(_isles[id])
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
	_isle(ISLE_OAKSHIRE_HOLM, "Miller's Oak", "South", 1, 6, ScribeSignResource.Sign.SIGN_WARM_HEARTH, "", 12, Vector2(0.0, 1600.0),
		"Hearthstead Market", "Windmill", "Old Quay Market", &"", "", WorldVisualCatalog.OAKSHIRE_WICK, &"oakshire_vale",
		Color(0.96, 0.78, 0.36))
	_isle(ISLE_IRON_NESS, "Iron-Ness", "West", 6, 10, ScribeSignResource.Sign.SIGN_IRON_ROOT, "Shield-Sworn", 12, Vector2(-1650.0, 350.0),
		"Forge-Gorge", "Forge Stacks", "Raid Gate A: the Under-Forge Abyss", CalderaWorldState.BEACON_IRON, "Iron Current",
		WorldVisualCatalog.QUARRY_WICK, &"dover_slap_falls", Color(0.86, 0.52, 0.26))
	_isle(ISLE_BARROW_EYOT, "Barrow-Eyot", "East", 8, 12, ScribeSignResource.Sign.SIGN_STAR_TIDE, "Lantern-Bearers", 12, Vector2(1650.0, 550.0),
		"Lantern Staithe", "Bell-Tower", "Raid Gate C: the Sunken Cathedral", CalderaWorldState.BEACON_TIDE, "Tide Current",
		WorldVisualCatalog.NINE_STONES_CROSSING, &"moss_oak_hollow", Color(0.62, 0.48, 0.86))
	_isle(ISLE_RIME_FIRTH, "Rime-Firth", "North", 10, 14, ScribeSignResource.Sign.SIGN_RIME_GALE, "Wayfarers", 12, Vector2(100.0, -1600.0),
		"Gale-Hall", "Snow Peak", "Raid Gate B: the Frost-Peak Aerie", CalderaWorldState.BEACON_GALE, "Gale Current",
		WorldVisualCatalog.GULL_WICK_HAVEN, &"dover_slap_falls", Color(0.48, 0.72, 0.92))
	_isle(ISLE_THE_CROWN, "The Crown", "Centre", 15, 20, ScribeSignResource.Sign.NONE, "", 8, Vector2.ZERO,
		"Lantern-Bearers' Waypost", "World-Tree", "The Sea-Door to the Heart", &"", "",
		WorldVisualCatalog.SUNKEN_CROWN_FALLS, &"cairnsmans_vigil", Color(0.98, 0.84, 0.42))
	_seam(SEAM_WEST_STRAIT, "The West Strait", LoadSeamResource.SeamSkin.WALKABLE_CAUSEWAY, false,
		ISLE_OAKSHIRE_HOLM, Vector3(-600.0, 1.0, -96.0), ISLE_IRON_NESS, Vector3(250.0, 1.0, 512.0),
		CalderaWorldState.ROOT_SANCTUM_CLEARED, LANES_DARK_LINE)
	_seam(SEAM_EEL_SPIT, "Eel Spit", LoadSeamResource.SeamSkin.WALKABLE_CAUSEWAY, true,
		ISLE_OAKSHIRE_HOLM, Vector3(600.0, 0.8, -96.0), ISLE_BARROW_EYOT, Vector3(-260.0, 0.8, 458.0),
		CalderaWorldState.ROOT_SANCTUM_CLEARED, LANES_DARK_LINE)
	_seam(SEAM_SALT_ROAD, "The Salt Road", LoadSeamResource.SeamSkin.LANTERN_SKIFF, false,
		ISLE_OAKSHIRE_HOLM, Vector3(30.0, 1.6, -426.0), ISLE_RIME_FIRTH, Vector3(60.0, 1.6, 470.0),
		CalderaWorldState.ROOT_SANCTUM_CLEARED, LANES_DARK_LINE)
	_seam(SEAM_CROWN_LANDING, "The Crown Landing", LoadSeamResource.SeamSkin.LANTERN_SKIFF, false,
		ISLE_OAKSHIRE_HOLM, Vector3(50.0, 1.6, -426.0), ISLE_THE_CROWN, Vector3(0.0, 1.6, 414.0),
		CalderaWorldState.CROWN_LANDING, CROWN_SHUT_LINE)


static func _isle(id: StringName, label: String, compass: String, low: int, high: int, scribe_sign: int, calling: String, chunks: int,
		sound_position: Vector2, steading: String, landmark: String, ebb: String, beacon: StringName, current_name: String,
		biome: StringName, music: StringName, accent: Color) -> void:
	var made: IslandGridResource = IslandGridResource.new()
	made.isle_id = id
	made.display_name = label
	made.compass = compass
	made.level_min = low
	made.level_max = high
	made.scribe_sign = scribe_sign as ScribeSignResource.Sign
	made.calling_title = calling
	made.chunks = chunks
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
		isle_b: StringName, anchor_b: Vector3, gate: StringName, closed_line: String) -> void:
	var made: LoadSeamResource = LoadSeamResource.new()
	made.seam_id = id
	made.display_name = label
	made.skin = skin
	made.shingle = shingle
	made.isle_a = isle_a
	made.anchor_a = anchor_a
	made.isle_b = isle_b
	made.anchor_b = anchor_b
	made.direction = Vector2(0.0, -1.0)
	made.gate_flag = gate
	made.closed_line = closed_line
	_seams[id] = made
