## Embershore, the starting isle (docs/27_EMBERSHORE_MASTER_V2.md; Zone 1,
## Lv 1-6): 2,048 x 1,024 m, 16 x 8 landblocks, built from one heightmap that
## tools/worldgen/embershore_gen.py (seed 7) writes into world/embershore/gen/engine:
##
##   embershore_height_f32.raw   2049 x 1025 float32 heights at 1 m (row 0 north)
##   mask_*.png                  land, moss_oaks, road, river, cliff, beach, rain_shadow_dry at 1 m
##   embershore_features.json    every landmark, path, river, bridge, tree, house, field,
##                               sea stack, sleeper, causeway, skiff route and trigger, in metres
##
## The generator's frame has its origin at the north-west corner (X east, Z
## south, Y up, sea at 0); the island's frame, like every Caldera isle's, is
## centred on the origin, so local = generator - (1024, 512) (`to_local`).
##
## The land came first: the coast is where the heightmap meets the sea, the
## River Bramble and the River Dover run in the valleys it carved, and every
## path is the cheapest walk the generator found (laid here as drawn, never
## re-routed). The corridor runs west to east: Bramblebridge, the Ariundle
## Moss-Oaks, the Sunken Holloway over the rim shoulder, the Doverslap Gorge
## Bridge, the Coast Road past Seal Cove and Sunward Cove, then Hearthstead and
## North Quay; the Root-Sanctum waits under the Elder Oak's roots.
##
## Act I (docs/28, docs/29) lives here too: ActOneDirector builds the quests'
## cast, packs, groves, the bridge's Stag Hunt, the quays and the Root-Sanctum
## carved under the Elder Oak, and the Level 1 spawn is in Lee-Shore Orchards
## (the orchard north of the stone bridge, at its south gate on the lane).
class_name EmbershoreBuilder
extends IslandBuilder

const GEN_DIR: String = "res://world/embershore/gen/engine/"
const HEIGHTS_FILE: String = GEN_DIR + "embershore_height_f32.raw"
const FEATURES_FILE: String = GEN_DIR + "embershore_features.json"
const MASK_NAMES: Array[StringName] = [&"land", &"moss_oaks", &"road", &"river", &"cliff", &"beach", &"rain_shadow_dry"]
## The heightmap's vertices (2049 x 1025 at 1 m) and the masks' cells (2048 x 1024).
const HEIGHT_COLUMNS: int = 2049
const HEIGHT_ROWS: int = 1025
const MASK_COLUMNS: int = 2048
const MASK_ROWS: int = 1024
## Generator metres to the island's frame: local = generator + ORIGIN.
const ORIGIN: Vector2 = Vector2(-1024.0, -512.0)
## The sea floor beyond the heightmap's edge.
const SEA_FLOOR: float = -14.0
## The ground's levels of detail: 1 m in the window, 2 m in a ring round it, 4 m far (docs/27 §4).
const LOD: PackedInt32Array = [128, 64, 32]

## The villages: cobbled streets within these reaches of their middles (docs/27 §8).
const BRAMBLEBRIDGE_AT: Vector2 = Vector2(-587.0, 203.0)
const BRAMBLEBRIDGE_COBBLES: float = 70.0
const HEARTHSTEAD_AT: Vector2 = Vector2(39.0, -195.0)
const HEARTHSTEAD_COBBLES: float = 95.0
## The Moss-Oaks' sessile oaks: the generator's canopy radius over the oak stand-in's, as a scale.
const OAK_STAND_IN_RADIUS: float = 2.9
## The Level 1 start (the Bible's Lee-Shore Orchards, docs/29 §4): the lane at the orchard's south
## gate, just over the stone bridge from the green. The party faces south-east, to the orchard gate
## and Master Alf-Wright waiting there (the Creative Director, 2026-11-09; docs/31 §12.3): in the
## hero's camera Alf stands at the right third's edge and the gate (the bridge's foot) at the right
## side, where the opening film hands over. The World-Tree is behind them.
const START_AT: Vector2 = Vector2(-584.0, 182.0)
const START_FACING: Vector2 = Vector2(0.766, 0.643)
## Bramblebridge's green and its chime-post (the checkpoint; the Feast green in Act I).
const GREEN_AT: Vector2 = Vector2(-593.92, 257.71)
## North Quay: the timber pier's root at the foot of Hearthstead's bluff and its head 30 m out in the bay (deck 1.6 m).
## The party arrives on the pier head's crosspiece, where the two skiff lanes berth.
const PIER_ROOT: Vector3 = Vector3(37.55, 1.6, -237.23)
const PIER_HEAD_Z: float = -267.23
const PIER_DECK: float = 1.6
const PIER_WIDTH: float = 8.0
const QUAY_ARRIVAL: Vector2 = Vector2(37.55, -263.23)

var heights: PackedFloat32Array = PackedFloat32Array()
var masks: Dictionary[StringName, PackedByteArray] = {}
var features: Dictionary = {}
## Every landmark by its generator name, in the island's frame (x, y, z).
var poi: Dictionary[StringName, Vector3] = {}
## Whether the generator's files were found (the island is flat sea without them).
var loaded: bool = false

## The generator's trees, bucketed by landblock: [x, z, scale, species].
var _trees: Dictionary[Vector2i, Array] = {}


# --- The generator's data ---------------------------------------------------------------

## Generator metres (x, z) to the island's frame.
static func to_local(at: Vector2) -> Vector2:
	return at + ORIGIN


static func to_local3(xyz: Array) -> Vector3:
	return Vector3(float(xyz[0]) + ORIGIN.x, float(xyz[1]), float(xyz[2]) + ORIGIN.y)


static func from_local(at: Vector2) -> Vector2:
	return at - ORIGIN


func _load_data() -> void:
	if loaded:
		return
	var raw: PackedByteArray = FileAccess.get_file_as_bytes(HEIGHTS_FILE)
	if raw.size() != HEIGHT_COLUMNS * HEIGHT_ROWS * 4:
		push_warning("EmbershoreBuilder: %s is missing or the wrong size (%d bytes); run tools/worldgen/embershore_gen.py" % [HEIGHTS_FILE, raw.size()])
		heights = PackedFloat32Array()
		heights.resize(HEIGHT_COLUMNS * HEIGHT_ROWS)
		heights.fill(SEA_FLOOR)
	else:
		heights = raw.to_float32_array()
	for mask_name: StringName in MASK_NAMES:
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(GEN_DIR + "mask_%s.png" % mask_name)
		var image: Image = Image.new()
		var cells: PackedByteArray = PackedByteArray()
		if bytes.is_empty() or image.load_png_from_buffer(bytes) != OK or image.get_width() != MASK_COLUMNS or image.get_height() != MASK_ROWS:
			cells.resize(MASK_COLUMNS * MASK_ROWS)
		else:
			image.convert(Image.FORMAT_L8)
			cells = image.get_data()
		masks[mask_name] = cells
	var text: String = FileAccess.get_file_as_string(FEATURES_FILE)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	features = parsed if parsed is Dictionary else {}
	for key: Variant in features.get("poi", {}):
		var entry: Dictionary = features["poi"][key]
		if entry.has("at"):
			poi[StringName(String(key))] = to_local3(entry["at"])
	_bucket_trees()
	loaded = raw.size() == HEIGHT_COLUMNS * HEIGHT_ROWS * 4


func _bucket_trees() -> void:
	_trees.clear()
	for tree: Variant in features.get("moss_oaks_trees", []):
		var at: Vector2 = to_local(Vector2(float(tree[0]), float(tree[1])))
		_bucket_tree(at, float(tree[2]) / OAK_STAND_IN_RADIUS, Species.OAK_TREE)
	for tree: Variant in features.get("orchard_trees", []):
		_bucket_tree(to_local(Vector2(float(tree[0]), float(tree[1]))), 1.0, Species.ORCHARD_TREE)


func _bucket_tree(at: Vector2, scale: float, species: int) -> void:
	var chunk: Vector2i = IslandGridResource.chunk_of(Vector3(at.x, 0.0, at.y))
	if not _trees.has(chunk):
		_trees[chunk] = []
	_trees[chunk].append([at.x, at.y, scale, species])


## A mask's value (0 to 1) at a spot.
func mask(mask_name: StringName, x: float, z: float) -> float:
	var cells: PackedByteArray = masks.get(mask_name, PackedByteArray())
	if cells.is_empty():
		return 0.0
	var column: int = clampi(int(x - ORIGIN.x), 0, MASK_COLUMNS - 1)
	var row: int = clampi(int(z - ORIGIN.y), 0, MASK_ROWS - 1)
	return float(cells[row * MASK_COLUMNS + column]) / 255.0


## A landmark's spot (the generator's name), on the ground.
func landmark(key: StringName) -> Vector3:
	return poi.get(key, Vector3.ZERO)


## A road's drawn points (the generator's x, y, z) in the island's frame.
func road_points(road_name: String) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for point: Variant in (features.get("roads", {}).get(road_name, {}) as Dictionary).get("points", []):
		points.append(to_local3(point))
	return points


## A river's points (x, z, bed_y, surface_y, width) in the island's frame.
func river_points(river_name: String) -> Array[PackedFloat32Array]:
	var rows: Array[PackedFloat32Array] = []
	for point: Variant in (features.get("rivers", {}).get(river_name, {}) as Dictionary).get("points", []):
		var at: Vector2 = to_local(Vector2(float(point[0]), float(point[1])))
		rows.append(PackedFloat32Array([at.x, at.y, float(point[2]), float(point[3]), float(point[4])]))
	return rows


## A list of generator (x, z) pairs as island-frame points.
func points_of(key: String) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for point: Variant in features.get(key, []):
		points.append(to_local(Vector2(float(point[0]), float(point[1]))))
	return points


# --- Laying out the island --------------------------------------------------------------

func _define() -> void:
	_load_data()
	# The paths, as the generator graded them (their beds are already in the heightmap: never re-routed, only drawn).
	var widths: Dictionary[String, float] = {"lane": 2.5, "hollow": 2.5, "gate": 2.5, "coast": 2.5, "downs": 1.5, "strait": 1.5, "eel": 1.5}
	for road_name: String in ["lane", "hollow", "gate", "coast", "downs", "strait", "eel"]:
		var flat: PackedVector2Array = PackedVector2Array()
		for point: Vector3 in road_points(road_name):
			flat.append(Vector2(point.x, point.z))
		if flat.size() >= 2:
			add_path(flat, widths[road_name], false)
	# The corridor's stages and the places along it (docs/27 §7, §9).
	add_place("Bramblebridge", Vector3(BRAMBLEBRIDGE_AT.x, 12.0, BRAMBLEBRIDGE_AT.y), 150.0)
	add_place("Bramblemouth", Vector3(-960.0, 1.0, 150.0), 70.0)
	add_place("Lee-Shore Orchards", Vector3(-650.0, 14.0, 80.0), 110.0)
	add_place("The Ariundle Moss-Oaks", Vector3(-89.0, 12.0, 222.0), 330.0)
	add_place("The Elder Oak", landmark(&"elder_oak"), 34.0)
	add_place("The Root-Sanctum", landmark(&"root_sanctum_entrance"), 40.0)
	add_place("The Bramble Spring", landmark(&"bramble_spring"), 24.0)
	add_place("The Dover Spring", landmark(&"dover_spring"), 24.0)
	add_place("The Sunken Holloway", Vector3(390.0, 30.0, 110.0), 230.0)
	add_place("The Rim Shoulder", landmark(&"holloway_rim_shoulder"), 40.0)
	add_place("Doverslap Gorge Bridge", landmark(&"doverslap_gorge_floor") + Vector3(0.0, 17.0, 0.0), 60.0)
	add_place("Doverslap Gorge", Vector3(840.0, 10.0, -20.0), 150.0)
	add_place("The Doverslap Gatehouse", landmark(&"doverslap_gatehouse"), 40.0)
	add_place("The Coast Road", Vector3(380.0, 10.0, -300.0), 230.0)
	add_place("Seal Cove", landmark(&"seal_cove"), 60.0)
	add_place("Sunward Cove", landmark(&"sunward_cove"), 60.0)
	add_place("The Eel Junction", landmark(&"eel_junction"), 50.0)
	add_place("Hearthstead", Vector3(HEARTHSTEAD_AT.x, 22.0, HEARTHSTEAD_AT.y), 120.0)
	add_place("North Quay", Vector3(PIER_ROOT.x, 1.6, PIER_ROOT.z - 10.0), 50.0)
	add_place("The Old Quay", Vector3(24.0, -4.5, -252.6), 36.0)
	add_place("Mill-Downs", landmark(&"mill_downs_windmill"), 180.0)
	add_place("The Downs Gate", landmark(&"downs_gate"), 30.0)
	add_place("Strait Lane", Vector3(-470.0, 8.0, -250.0), 170.0)
	add_place("The West Strait", landmark(&"west_strait_head"), 60.0)
	add_place("Eel Spit", landmark(&"eel_spit_head"), 70.0)
	add_place("The South Cliffs", Vector3(-24.0, 40.0, 438.0), 300.0)
	add_place("The First-Quiet Crags", Vector3(726.0, 60.0, 248.0), 200.0)
	# The start, North Quay's shore end, and the Root-Sanctum's way out at the mill weir.
	add_arrival(CalderaAtlas.ARRIVE_START, START_AT, START_FACING)
	add_arrival(CalderaAtlas.ARRIVE_NORTH_QUAY, QUAY_ARRIVAL, Vector2(0.0, -1.0))
	var weir: Vector3 = landmark(&"bramble_weir")
	add_arrival(CalderaAtlas.ARRIVE_ROOT_SANCTUM, Vector2(weir.x, weir.z + 10.0), Vector2(-0.6, 0.8))


## North Quay's arrival stands on the pier's deck, not on the sea floor under it.
func arrival_spot(id: StringName, slot: int = 0) -> Vector3:
	var spot: Vector3 = super(id, slot)
	if id == CalderaAtlas.ARRIVE_NORTH_QUAY:
		spot.y = PIER_DECK + 0.1
	return spot


func lod_quads() -> PackedInt32Array:
	return LOD


func collision_resident() -> bool:
	return true


## A landblock's collider straight from the heightmap: it is already 1 m data, 129 vertices a side.
func collision_heights_for(chunk: Vector2i) -> PackedFloat32Array:
	var column0: int = chunk.x * int(IslandGridResource.CHUNK_SIZE) - int(ORIGIN.x)
	var row0: int = chunk.y * int(IslandGridResource.CHUNK_SIZE) - int(ORIGIN.y)
	if column0 < 0 or row0 < 0 or column0 + COLLISION_SIDE > HEIGHT_COLUMNS or row0 + COLLISION_SIDE > HEIGHT_ROWS:
		return PackedFloat32Array()
	var out: PackedFloat32Array = PackedFloat32Array()
	for row: int in COLLISION_SIDE:
		var start: int = (row0 + row) * HEIGHT_COLUMNS + column0
		out.append_array(heights.slice(start, start + COLLISION_SIDE))
	return out


## The Deep-Hush (docs/27 §4): the sea past the south-east seal, within 160 m of its line.
func beyond_seal(x: float, z: float) -> bool:
	return EmbershoreWater.beyond_seal(points_of("boundary_seal"), Vector2(x, z), 160.0)


## Cobbles through the two villages; packed earth everywhere else, however wide the road.
func road_surface_at(x: float, z: float, _half_width: float) -> int:
	var at: Vector2 = Vector2(x, z)
	if at.distance_to(BRAMBLEBRIDGE_AT) < BRAMBLEBRIDGE_COBBLES or at.distance_to(HEARTHSTEAD_AT) < HEARTHSTEAD_COBBLES:
		return 0
	return 1


# --- The ground ---------------------------------------------------------------------------

## The heightmap, bilinear; the sea floor past its edge.
func _base_height(x: float, z: float) -> float:
	var gx: float = x - ORIGIN.x
	var gz: float = z - ORIGIN.y
	if gx < 0.0 or gz < 0.0 or gx > float(HEIGHT_COLUMNS - 1) or gz > float(HEIGHT_ROWS - 1):
		return SEA_FLOOR
	var column: int = mini(int(gx), HEIGHT_COLUMNS - 2)
	var row: int = mini(int(gz), HEIGHT_ROWS - 2)
	var fx: float = gx - float(column)
	var fz: float = gz - float(row)
	var index: int = row * HEIGHT_COLUMNS + column
	var top: float = lerpf(heights[index], heights[index + 1], fx)
	var bottom: float = lerpf(heights[index + HEIGHT_COLUMNS], heights[index + HEIGHT_COLUMNS + 1], fx)
	return lerpf(top, bottom, fz)


## The coast is the heightmap's own.
func _coast_shape() -> Dictionary:
	return {}


## The ground's painted colour (docs/27 §4): ash-loam soil under dry golden grass
## in the northern rain shadow and lush damp green to the south, moss and leaf
## litter under the Moss-Oaks, silt and pebbles in the river beds, banded ochre
## and grey tuff on the cliffs, pale sand in the northern coves and shingle at
## Bramblemouth and on the Eel Spit. The shader lays its crafts over these.
func _ground_color(x: float, z: float, height: float, up: float) -> Color:
	var dry: float = mask(&"rain_shadow_dry", x, z)
	var wood: float = mask(&"moss_oaks", x, z)
	var patch: float = 0.5 + 0.5 * detail(x * 0.6, z * 0.6)
	var lush: Color = Color(0.33, 0.52, 0.24).lerp(Color(0.4, 0.58, 0.27), patch)
	var golden: Color = Color(0.5, 0.58, 0.28).lerp(Color(0.56, 0.62, 0.3), patch)
	var turf: Color = lush.lerp(golden, dry)
	# Ash-loam shows through where the turf thins: on steeper banks and in the dry north's bare patches.
	var loam: Color = Color(0.42, 0.32, 0.22)
	var thin: float = smoothstep(0.92, 0.84, up) * 0.6 + dry * smoothstep(0.7, 0.9, detail(x * 0.25 + 40.0, z * 0.25)) * 0.5
	turf = turf.lerp(loam, clampf(thin, 0.0, 0.7))
	# The Moss-Oaks' floor: moss, leaf litter and ferns.
	var litter: Color = Color(0.3, 0.42, 0.2).lerp(Color(0.38, 0.3, 0.2), smoothstep(0.55, 0.8, patch))
	turf = turf.lerp(litter, wood * 0.85)
	# River beds: silt and pebbles (a pale, grey tone the shader lays sand over).
	var river: float = mask(&"river", x, z)
	if river > 0.0 and height < 20.0:
		turf = turf.lerp(Color(0.58, 0.56, 0.5), river * 0.9)
	# The cliffs' tuff, in ochre and grey bands by height.
	var band: float = 0.5 + 0.5 * sin(height * 1.3 + 0.8 * detail(x * 0.4, z * 0.4))
	var tuff: Color = Color(0.6, 0.48, 0.32).lerp(Color(0.5, 0.5, 0.48), band)
	var cliff: float = maxf(mask(&"cliff", x, z), smoothstep(0.78, 0.66, up))
	# Shingle (greyer) at Bramblemouth and on the Eel Spit; pale sand in the northern coves.
	var shingle: float = smoothstep(560.0, 700.0, absf(x)) if z < 200.0 and x > 0.0 or z > 100.0 and x < 0.0 else 0.0
	var sand: Color = Color(0.86, 0.79, 0.62).lerp(Color(0.68, 0.66, 0.6), shingle)
	if mask(&"beach", x, z) > 0.5 and up > 0.8:
		return sand
	return shore_or(height, up, turf.lerp(tuff, cliff * 0.6), tuff)


## Small scatter by the land's own masks (the generator places every tree):
## ferns and mossy boulders under the oaks, hazel and rowan at the wood's edge,
## reeds and willows by the rivers, stones on the cliffs, gorse and heather on
## the rim and the south-east crags.
func _scatter_species(x: float, z: float, height: float, up: float, roll: float) -> int:
	var at: Vector2 = Vector2(x, z)
	if at.distance_to(BRAMBLEBRIDGE_AT) < 90.0 or at.distance_to(HEARTHSTEAD_AT) < 110.0 or at.distance_to(Vector2(PIER_ROOT.x, PIER_ROOT.z)) < 40.0:
		return -1
	var river: float = mask(&"river", x, z)
	var near_river: bool = river > 0.0 or mask(&"river", x + 6.0, z) > 0.0 or mask(&"river", x - 6.0, z) > 0.0 \
		or mask(&"river", x, z + 6.0) > 0.0 or mask(&"river", x, z - 6.0) > 0.0
	if height < 1.2:
		return Species.REED_CLUMP if roll < 0.12 and (near_river or mask(&"beach", x, z) < 0.5) else -1
	if river > 0.0:
		return -1
	if up < 0.66 or mask(&"cliff", x, z) > 0.5:
		return Species.ROCK if roll < 0.14 else (Species.BOULDER if roll < 0.17 else -1)
	var wood: float = mask(&"moss_oaks", x, z)
	if wood > 0.5:
		if roll < 0.26:
			return Species.FERN_TUFT
		return Species.BOULDER if roll < 0.285 else (Species.ROCK if roll < 0.31 else -1)
	var edge: bool = mask(&"moss_oaks", x + 12.0, z) > 0.5 or mask(&"moss_oaks", x - 12.0, z) > 0.5 or mask(&"moss_oaks", x, z + 12.0) > 0.5 \
		or mask(&"moss_oaks", x, z - 12.0) > 0.5
	if edge:
		if roll < 0.03:
			return Species.ROWAN_TREE
		return Species.ASH_TREE if roll < 0.055 else (Species.FERN_TUFT if roll < 0.12 else -1)
	if near_river and height < 6.0:
		return Species.WILLOW_TREE if roll < 0.05 else (Species.REED_CLUMP if roll < 0.14 else -1)
	if height > 28.0:
		# The rim and the south-east crags: gorse, heather and stone.
		return Species.GORSE_BUSH if roll < 0.07 else (Species.HEATHER_CLUMP if roll < 0.22 else (Species.ROCK if roll < 0.25 else -1))
	var dry: float = mask(&"rain_shadow_dry", x, z)
	if roll < 0.012 * (1.0 - dry) + 0.004:
		return Species.ASH_TREE
	return Species.ROCK if roll < 0.02 else -1


## The random scatter, then the generator's trees that stand in this landblock.
func _scatter(chunk: Vector2i, origin: Vector2, pads: PackedFloat32Array, ramps: PackedFloat32Array, paths: PackedFloat32Array) -> Dictionary:
	var grown: Dictionary = super(chunk, origin, pads, ramps, paths)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("trees:%d:%d" % [chunk.x, chunk.y])
	for tree: Array in _trees.get(chunk, []):
		var species: int = int(tree[3])
		var x: float = float(tree[0])
		var z: float = float(tree[1])
		var h: float = _height(x, z, pads, ramps)
		if h < 0.5:
			continue
		if not grown.has(species):
			grown[species] = []
		var scale: float = float(tree[2]) * rng.randf_range(0.92, 1.08)
		(grown[species] as Array).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale), Vector3(x, h - 0.05, z)))
	return grown


## The meadow runs golden and thin in the dry north, lush in the south, and thins to moss under the oaks.
func _meadow_lushness(x: float, z: float, height: float, up: float) -> float:
	var base: float = super(x, z, height, up)
	if base <= 0.0 or mask(&"river", x, z) > 0.0 or mask(&"beach", x, z) > 0.5 or mask(&"cliff", x, z) > 0.5:
		return 0.0
	base *= 1.0 - 0.5 * mask(&"rain_shadow_dry", x, z)
	base *= 1.0 - 0.7 * mask(&"moss_oaks", x, z)
	return base


func landmark_silhouette(into: LandblockTerrain.MeshMerge) -> void:
	var mill: Vector3 = landmark(&"mill_downs_windmill")
	CalderaKit.add_windmill_silhouette(into, ground(mill.x, mill.z))


# --- Structures ----------------------------------------------------------------------------

## The kin along the corridor, by stage (docs/13 §2, docs/27 §9): each pack a MobSpawner
## beside a path (18-25 m leash), grown as its landblock streams in.
##   Lv 1-2 Bramblebridge and the orchards: Curious Weald-Wights (parley first)
##   Lv 2-3 the Ariundle Moss-Oaks and the Bramble: Padfoot Boggarts
##   Lv 3-4 the Sunken Holloway and the gorge: Furrow Iron-Men in three-spirit pulls
##   Lv 4-5 the Coast Road and its coves: Bramble-Hobs, a Bog-Hulk at Seal Cove
##   Lv 5   Mill-Downs: Crag-Spriggans at the Downs Gate
##   Lv 6   under the Elder Oak: the Root-Sanctum's briar guard
const ENCOUNTERS: Array[Dictionary] = [
	{"name": "OrchardHobs1", "road": "lane", "at": 0.12, "side": 1.0, "place": "Lee-Shore Orchards", "pack": [&"cider_thief_bristleboar", &"cider_thief_bristleboar"]},
	{"name": "OrchardHobs2", "road": "lane", "at": 0.24, "side": -1.0, "place": "Lee-Shore Orchards", "pack": [&"thorn_tail_scuttler", &"cider_thief_bristleboar"]},
	{"name": "OrchardHobs3", "road": "lane", "at": 0.36, "side": 1.0, "place": "Lee-Shore Orchards", "pack": [&"cider_thief_bristleboar", &"thorn_tail_scuttler", &"old_tusk_crag"]},
	{"name": "MossPadfoots1", "road": "lane", "at": 0.58, "side": -1.0, "place": "The Ariundle Moss-Oaks", "pack": [&"grey_pelt_prowler", &"grey_pelt_prowler"]},
	{"name": "MossPadfoots2", "road": "lane", "at": 0.74, "side": 1.0, "place": "The Ariundle Moss-Oaks", "pack": [&"river_snapper_toad", &"grey_pelt_prowler"]},
	{"name": "MossPadfoots3", "road": "hollow", "at": 0.1, "side": -1.0, "place": "The Ariundle Moss-Oaks", "pack": [&"grey_pelt_prowler", &"river_snapper_toad", &"alpha_frost_fang"]},
	{"name": "HollowayIronMen1", "road": "hollow", "at": 0.42, "side": 1.0, "place": "The Sunken Holloway", "pack": [&"soot_paw_cutthroat", &"soot_paw_cutthroat", &"quarry_sling_shotter"]},
	{"name": "HollowayIronMen2", "road": "hollow", "at": 0.64, "side": -1.0, "place": "The Sunken Holloway", "pack": [&"foreman_iron_gavel", &"soot_paw_cutthroat", &"quarry_sling_shotter"]},
	{"name": "GorgeIronMen", "road": "hollow", "at": 0.86, "side": 1.0, "place": "The Rim Shoulder", "pack": [&"soot_paw_cutthroat", &"quarry_sling_shotter", &"quarry_sling_shotter"]},
	{"name": "CoastBrambleHobs1", "road": "coast", "at": 0.2, "side": -1.0, "place": "The Coast Road", "pack": [&"bramble_lasher_vine", &"spore_puff_shambler"]},
	{"name": "SealCoveHulk", "road": "coast", "at": 0.4, "side": -1.0, "place": "Seal Cove", "pack": [&"bog_hulk_tangler", &"bramble_lasher_vine"]},
	{"name": "CoastBrambleHobs2", "road": "coast", "at": 0.66, "side": 1.0, "place": "The Coast Road", "pack": [&"bramble_lasher_vine", &"bramble_lasher_vine", &"spore_puff_shambler"]},
	{"name": "DownsSpriggans1", "road": "downs", "at": 0.08, "side": -1.0, "place": "Mill-Downs", "pack": [&"risen_shield_sworn_husk", &"hollow_scribe_acolyte"]},
	{"name": "DownsSpriggans2", "road": "downs", "at": 0.2, "side": 1.0, "place": "Mill-Downs", "pack": [&"risen_shield_sworn_husk", &"risen_shield_sworn_husk", &"barrow_warden_knell"]},
	{"name": "SanctumBriar", "road": "lane", "at": 0.9, "side": 1.0, "place": "The Root-Sanctum", "pack": [&"bramble_lasher_vine", &"bog_hulk_tangler"]},
]
## A pack stands this far off its path.
const PACK_OFFSET: float = 18.0


func _build_encounters(root: Node3D) -> void:
	for spec: Dictionary in ENCOUNTERS:
		var points: PackedVector3Array = road_points(String(spec["road"]))
		if points.size() < 2:
			continue
		var index: int = clampi(int(float(spec["at"]) * float(points.size() - 1)), 1, points.size() - 2)
		var along: Vector2 = Vector2(points[index + 1].x - points[index - 1].x, points[index + 1].z - points[index - 1].z).normalized()
		var across: Vector2 = Vector2(-along.y, along.x) * float(spec["side"])
		var at: Vector2 = Vector2(points[index].x, points[index].z) + across * PACK_OFFSET
		var spot: Vector3 = ground(at.x, at.y)
		if spot.y < 1.0 or mask(&"river", at.x, at.y) > 0.0:
			# Off the far bank or in the water: stand on the other side.
			at = Vector2(points[index].x, points[index].z) - across * PACK_OFFSET
			spot = ground(at.x, at.y)
		var pack: MobSpawner = MobSpawner.new()
		pack.name = String(spec["name"])
		pack.territory = String(spec["place"])
		var ids: Array[StringName] = []
		for id: Variant in spec["pack"]:
			ids.append(StringName(String(id)))
		pack.variant_ids = ids
		pack.leash = 20.0
		pack.position = spot
		pack.add_to_group(&"caldera_streamed_spawners")
		root.add_child(pack)

func build_structures(root: Node3D) -> void:
	EmbershoreWater.build(root, self)
	EmbershoreLandmarks.build(root, self)
	_build_start(root)
	_build_cottages(root, "bramblebridge_houses", "Bramblebridge", 20)
	_build_cottages(root, "hearthstead_houses", "Hearthstead", 60)
	_build_hearthstead(root)
	_build_encounters(root)
	_build_north_quay(root)
	_build_old_quay(root)
	_build_root_sanctum(root)
	ActOneDirector.new().build(root, self)
	for seam_id: StringName in [CalderaAtlas.SEAM_WEST_STRAIT, CalderaAtlas.SEAM_EEL_SPIT]:
		CalderaCauseway.build(root, CalderaAtlas.seam(seam_id), isle.isle_id)


func _build_start(root: Node3D) -> void:
	var post: ChimePost = ChimePost.new()
	post.name = "StartChimePost"
	post.place = "Bramble-Bridge"
	post.checkpoint = true
	post.position = ground(GREEN_AT.x + 3.0, GREEN_AT.y + 1.0)
	root.add_child(post)
	CalderaKit.sign_label(root, "StartSign", "Bramblebridge\nEmbershore · Lv 1-2 · the stone bridge lies north", ground(GREEN_AT.x, GREEN_AT.y - 6.0) + Vector3(0.0, 2.6, 0.0))
	CalderaKit.sign_label(root, "OrchardSign", "Lee-Shore Orchards\nEmbershore · Lv 1 · Master Alf-Wright waits at the gate", ground(START_AT.x + 4.0, START_AT.y + 4.0) + Vector3(0.0, 2.6, 0.0))


## A village's cottages where the generator set them (docs/27 §7: twelve each), each facing its
## village's middle, with what a family leaves about a cottage (docs/24 §5).
func _build_cottages(root: Node3D, key: String, village: String, seed_from: int) -> void:
	var middle: Vector2 = BRAMBLEBRIDGE_AT if village == "Bramblebridge" else HEARTHSTEAD_AT
	var houses: PackedVector2Array = points_of(key)
	for index: int in houses.size():
		var at: Vector2 = houses[index]
		var spot: Vector3 = ground(at.x, at.y)
		var toward: Vector2 = middle - at
		var yaw: float = atan2(toward.x, toward.y)
		var house: WorldKitInstance = WorldKitInstance.make("%sHouse%d" % [village, index], WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, spot, yaw,
			{"seed_value": seed_from + index})
		if index == 0:
			house.name = "%sInn" % village
			house.scale = Vector3.ONE * 1.3
		root.add_child(house)
		CalderaKit.solid_box(root, "%sHouseBody%d" % [village, index], spot + Vector3(0.0, 2.5, 0.0), Vector3(6.0, 5.0, 6.0), yaw)
		CalderaKit.lived_in_clutter(root, "%sHouseClutter%d" % [village, index], spot, seed_from * 10 + index, 4, 4.6, 6.4, ground)


## Hearthstead's market: the three lane stalls along the green's north side, shuttered until their Beacons burn
## (the village itself, its Scribe table and chime-post follow in docs/27's settlements pass).
func _build_hearthstead(root: Node3D) -> void:
	var at: Vector3 = landmark(&"hearthstead_market")
	CalderaKit.sign_label(root, "MarketSign", "Hearthstead\nevery lane runs through here", ground(at.x, at.z) + Vector3(0.0, 3.4, 12.0))
	var stalls: Array[Dictionary] = [
		{"flag": CalderaWorldState.BEACON_IRON, "name": "The Iron Stall", "vendor": "Bryn Ironside", "title": "Iron-Ness smith",
			"wares": TownsfolkNPC.Wares.ARMOR, "note": "iron from Iron-Ness: Ring-Coats and Kettle-Caps", "accent": CalderaKit.IRON_AMBER},
		{"flag": CalderaWorldState.BEACON_TIDE, "name": "The Lantern Stall", "vendor": "Ellis Wickmoor", "title": "Lantern Staithe chandler",
			"wares": TownsfolkNPC.Wares.APOTHECARY, "note": "lamp-oil from Barrow-Eyot: lanterns lit, wounds mended", "accent": CalderaKit.TIDE_VIOLET},
		{"flag": CalderaWorldState.BEACON_GALE, "name": "The Provisions Stall", "vendor": "Saoirse Galebrook", "title": "Gale-Hall factor",
			"wares": TownsfolkNPC.Wares.BANKER, "note": "fuel and provisions from Rime-Firth: the Chime-Vault", "accent": CalderaKit.GALE_AZURE},
	]
	for index: int in stalls.size():
		var spec: Dictionary = stalls[index]
		var stall: TradeStall = TradeStall.new()
		stall.name = ["IronStall", "LanternStall", "ProvisionsStall"][index]
		stall.lane_flag = spec["flag"]
		stall.stall_name = spec["name"]
		stall.vendor_name = spec["vendor"]
		stall.vendor_title = spec["title"]
		stall.wares = spec["wares"]
		stall.wares_note = spec["note"]
		stall.accent = spec["accent"]
		stall.position = ground(at.x - 14.0 + index * 14.0, at.z - 18.0)
		stall.rotation.y = PI
		root.add_child(stall)


func _build_north_quay(root: Node3D) -> void:
	var dock: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var head: Vector3 = Vector3(PIER_ROOT.x, PIER_DECK, PIER_HEAD_Z)
	CalderaKit.add_pier(dock, PIER_ROOT, head, PIER_WIDTH, PIER_DECK)
	# The pier head: a crosspiece with a berth at each end for the two skiff lanes.
	CalderaKit.add_box(dock, Vector3(PIER_ROOT.x, PIER_DECK - 0.2, PIER_HEAD_Z + 4.0), Vector3(30.0, 0.4, 10.0), CalderaKit.TIMBER)
	for x: float in [-14.0, -5.0, 5.0, 14.0]:
		CalderaKit.add_post(dock, Vector3(PIER_ROOT.x + x, -10.0, PIER_HEAD_Z + 8.6), 0.24, 0.28, 12.4, CalderaKit.DARK_TIMBER, 6)
	root.add_child(CalderaKit.mesh_node("NorthQuayPier", dock))
	var length: float = PIER_ROOT.z - PIER_HEAD_Z
	CalderaKit.solid_box(root, "PierDeck", Vector3(PIER_ROOT.x, PIER_DECK - 0.2, (PIER_ROOT.z + PIER_HEAD_Z) * 0.5), Vector3(PIER_WIDTH, 0.4, length), 0.0, ActorBase.LAYER_LOW_SCENERY)
	CalderaKit.solid_box(root, "PierHead", Vector3(PIER_ROOT.x, PIER_DECK - 0.2, PIER_HEAD_Z + 4.0), Vector3(30.0, 0.4, 10.0), 0.0, ActorBase.LAYER_LOW_SCENERY)
	for seam_id: StringName in [CalderaAtlas.SEAM_SALT_ROAD, CalderaAtlas.SEAM_CROWN_LANDING]:
		var seam: LoadSeamResource = CalderaAtlas.seam(seam_id)
		var berth: Vector3 = seam.anchor(isle.isle_id)
		var bell: SkiffBell = SkiffBell.new()
		bell.name = "SaltRoadBell" if seam_id == CalderaAtlas.SEAM_SALT_ROAD else "CrownLandingBell"
		bell.seam_id = seam_id
		bell.position = Vector3(berth.x + (3.0 if seam_id == CalderaAtlas.SEAM_SALT_ROAD else -3.0), PIER_DECK, PIER_HEAD_Z + 2.0)
		bell.rotation.y = PI
		root.add_child(bell)
		var skiff: LandblockTerrain.MeshMerge = CalderaKit.merge()
		CalderaKit.add_skiff(skiff)
		var moored: MeshInstance3D = CalderaKit.mesh_node("Skiff_%s" % String(seam_id).trim_prefix("seam_"), skiff)
		moored.position = Vector3(berth.x + (6.0 if seam_id == CalderaAtlas.SEAM_SALT_ROAD else -6.0), -1.5, PIER_HEAD_Z - 2.0)
		root.add_child(moored)
	CalderaKit.sign_label(root, "QuaySign", "North Quay\nThe Sound: the World-Tree across the water", ground(PIER_ROOT.x - 9.0, PIER_ROOT.z + 10.0) + Vector3(0.0, 2.8, 0.0))


## The Old Quay: the drowned stone platform at -4.5 m beside the pier, bared when the Ebb drops the sea to -6 m.
func _build_old_quay(root: Node3D) -> void:
	var market: OldQuayMarket = OldQuayMarket.new()
	market.name = "OldQuayMarket"
	market.position = Vector3(24.0, -4.5, -252.6)
	root.add_child(market)


## The Root-Sanctum's door among the Elder Oak's roots. Act I's Q05 (docs/29 §4) carves the
## Sanctum itself under the oak (RootSanctum, built by ActOneDirector): the party walks into
## the door's ring together. The old Cairnsman expedition stays reachable as --instance=expedition.
func _build_root_sanctum(root: Node3D) -> void:
	var at: Vector3 = landmark(&"root_sanctum_entrance")
	at = ground(at.x, at.z)
	CalderaKit.sign_label(root, "SanctumSign", "The Root-Sanctum · Lv 5-6\nthe seal-stone is cracked: gather in the ring to go down; the way out is the mill weir",
		at + Vector3(0.0, 4.2, 0.0))
