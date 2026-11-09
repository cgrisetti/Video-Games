## Embershore's worked land, as data (docs/32_EMBERSHORE_THE_WORKED_LAND.md):
## what tools/worldgen/embershore_settle.py laid over the generator's island and
## wrote into world/embershore/settle:
##
##   settlement.json    steadings, village plots, tracks, fields, boundaries,
##                      trees, props and flocks, in the generator's metres
##   mask_landuse.png   what each square metre is used for (Use), 2048 x 1024
##   mask_tilth.png     the direction a field is worked in (1..255 = 0..pi; 0 none)
##
## EmbershoreBuilder reads the ground's colour, tilth and meadow from the masks,
## lays the tracks as paths, and takes each landblock's share of the scatter from
## here: the trees, the boundary runs set end to end along each line and tilted
## to the slope (with their gateways left open), and what the fields are left
## with. EmbershoreSteadings builds the homes, yards and stock from the same file.
## Everything is in the island's frame once loaded (EmbershoreBuilder.to_local).
class_name EmbershoreSettlement
extends RefCounted

const Species = IslandBuilder.Species

const DIR: String = "res://world/embershore/settle/"
const FILE: String = DIR + "settlement.json"
const COLUMNS: int = 2048
const ROWS: int = 1024
## What a square metre is used for (the generator script's LANDUSE ids).
enum Use { WILD, PASTURE, HAY, BARLEY, PLOUGH, ROOTS, STUBBLE, FALLOW, ORCHARD, YARD, GARDEN, GREEN, WATER_MEADOW, COMMON, VERGE }

const TREE_SPECIES: Dictionary[String, int] = {"oak": Species.FIELD_OAK, "ash": Species.FIELD_ASH, "beech": Species.BEECH_TREE, "elm": Species.ELM_TREE,
	"chestnut": Species.CHESTNUT_TREE, "birch": Species.BIRCH_TREE, "poplar": Species.POPLAR_TREE, "hawthorn": Species.HAWTHORN_TREE,
	"alder": Species.ALDER_TREE, "willow": Species.WILLOW_TREE, "pollard": Species.POLLARD_WILLOW, "pine": Species.SCOTS_PINE,
	"rowan": Species.ROWAN_TREE, "plum": Species.PLUM_TREE, "pear": Species.PEAR_TREE, "apple": Species.ORCHARD_TREE, "yew": Species.YEW_TREE,
	"holly": Species.HOLLY_TREE, "hazel": Species.HAWTHORN_TREE}
const PROP_SPECIES: Dictionary[String, int] = {"haycock": Species.HAYCOCK, "stook": Species.STOOK, "crop_row": Species.CROP_ROW,
	"bean_row": Species.BEAN_ROW, "bramble": Species.BRAMBLE_BUSH, "trough": Species.TROUGH, "scarecrow": Species.SCARECROW}
## A field gate's gap in a boundary, and a stile's.
const GATE_GAP: float = WorkedLandKit.GATE_WIDTH + 0.8
const STILE_GAP: float = 1.1
## A run shorter than this is left out (a stub of hedge between two gateways).
const SHORTEST_RUN: float = 1.1
## One hedge run in this many is in blossom.
const BLOOM_SHARE: float = 0.24
## A tumbled wall has lost this share of its runs.
const TUMBLED_MISSING: float = 0.3

var loaded: bool = false
var data: Dictionary = {}
var use: PackedByteArray = PackedByteArray()
var tilth: PackedByteArray = PackedByteArray()
## Each landblock's share of the scatter: chunk -> { Species -> Array of Transform3D }.
var _scatter: Dictionary[Vector2i, Dictionary] = {}
## What was laid, for the docs and the checks: runs by species, gateways, stiles, trees.
var counts: Dictionary[String, int] = {}


func load_files() -> void:
	if loaded:
		return
	var text: String = FileAccess.get_file_as_string(FILE)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	data = parsed if parsed is Dictionary else {}
	use = _mask("mask_landuse.png")
	tilth = _mask("mask_tilth.png")
	loaded = not data.is_empty() and use.size() == COLUMNS * ROWS and tilth.size() == COLUMNS * ROWS
	if not loaded:
		push_warning("EmbershoreSettlement: %s is missing; run tools/worldgen/embershore_settle.py" % DIR)
		use = PackedByteArray()
		tilth = PackedByteArray()


func _mask(file_name: String) -> PackedByteArray:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(DIR + file_name)
	var image: Image = Image.new()
	if bytes.is_empty() or image.load_png_from_buffer(bytes) != OK or image.get_width() != COLUMNS or image.get_height() != ROWS:
		return PackedByteArray()
	image.convert(Image.FORMAT_L8)
	return image.get_data()


## What the ground is used for at a spot (island frame).
func use_at(x: float, z: float) -> int:
	if use.is_empty():
		return Use.WILD
	var column: int = int(x - EmbershoreBuilder.ORIGIN.x)
	var row: int = int(z - EmbershoreBuilder.ORIGIN.y)
	if column < 0 or row < 0 or column >= COLUMNS or row >= ROWS:
		return Use.WILD
	return use[row * COLUMNS + column]


## The way a field is worked at a spot (a unit vector along its rows), or zero where none is.
func row_at(x: float, z: float) -> Vector2:
	var value: int = row_byte(x, z)
	if value == 0:
		return Vector2.ZERO
	var angle: float = float(value - 1) / 253.0 * PI
	return Vector2(cos(angle), sin(angle))


func row_byte(x: float, z: float) -> int:
	if tilth.is_empty():
		return 0
	var column: int = int(x - EmbershoreBuilder.ORIGIN.x)
	var row: int = int(z - EmbershoreBuilder.ORIGIN.y)
	if column < 0 or row < 0 or column >= COLUMNS or row >= ROWS:
		return 0
	return tilth[row * COLUMNS + column]


func list(key: String) -> Array:
	var found: Variant = data.get(key, [])
	return found as Array if found is Array else []


static func at2(entry: Variant) -> Vector2:
	var pair: Array = entry as Array
	return EmbershoreBuilder.to_local(Vector2(float(pair[0]), float(pair[1])))


static func facing_of(entry: Dictionary) -> Vector2:
	var pair: Array = entry.get("facing", [0.0, 1.0])
	return Vector2(float(pair[0]), float(pair[1])).normalized()


## A list of generator (x, z) pairs as island-frame points.
static func points_of(entries: Variant) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for entry: Variant in entries as Array:
		points.append(at2(entry))
	return points


## The scatter a landblock takes from the worked land (shared arrays: read, never changed).
func scatter_in(chunk: Vector2i) -> Dictionary:
	return _scatter.get(chunk, {})


# --- Laying the scatter -------------------------------------------------------------------------------

## Sets every tree, boundary run and field piece on the ground, by landblock. `height` gives the ground (x, z) -> y.
func lay_scatter(height: Callable) -> void:
	_scatter.clear()
	counts.clear()
	if not loaded:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3200 + int(data.get("seed", 7))
	for tree: Variant in list("trees"):
		var entry: Array = tree as Array
		var species: int = TREE_SPECIES.get(String(entry[2]), Species.ASH_TREE)
		var at: Vector2 = EmbershoreBuilder.to_local(Vector2(float(entry[0]), float(entry[1])))
		var ground: float = float(height.call(at.x, at.y))
		if ground < 0.6:
			continue
		var scale: float = maxf(0.85, float(entry[3]))
		_add(species, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale), Vector3(at.x, ground - 0.05, at.y)))
		_count("trees")
	for boundary: Variant in list("boundaries"):
		_lay_boundary(boundary as Dictionary, height, rng)
	# A hill farm's sheepfold, and the old folds on the common: a ring of wall with a way in.
	for steading: Variant in list("steadings"):
		for building: Variant in (steading as Dictionary).get("buildings", []):
			if String((building as Dictionary).get("kind", "")) == "fold":
				_lay_boundary(_ring(building as Dictionary, 4.4, "wall"), height, rng)
	for prop: Variant in list("props"):
		if String((prop as Dictionary).get("kind", "")) == "fold_ruin":
			_lay_boundary(_ring(prop as Dictionary, 4.0, "wall_tumbled"), height, rng)
	for prop: Variant in list("props"):
		var entry: Dictionary = prop as Dictionary
		var kind: String = String(entry.get("kind", ""))
		if not PROP_SPECIES.has(kind):
			continue
		var at: Vector2 = at2(entry["at"])
		var way: Vector2 = facing_of(entry)
		var species: int = PROP_SPECIES[kind]
		if species == Species.HAYCOCK or species == Species.STOOK or species == Species.BRAMBLE_BUSH or species == Species.SCARECROW:
			# Stood on the ground, turned any way (a stook's row runs with the field's).
			var yaw: float = atan2(way.x, way.y) + (rng.randf_range(-0.2, 0.2) if species == Species.STOOK else rng.randf() * TAU)
			var size: float = rng.randf_range(0.85, 1.15)
			_add(species, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size), Vector3(at.x, float(height.call(at.x, at.y)) - 0.03, at.y)))
		else:
			# Laid along the field's rows and tilted to the slope.
			var half: float = 1.5 if species != Species.TROUGH else 0.9
			var where: Transform3D = _run_transform(at - way * half, at + way * half, half * 2.0, height, Vector2(1.0, 1.0))
			if species == Species.BEAN_ROW:
				where = Transform3D(Basis(Vector3.UP, rng.randf() * TAU), where.origin)
			_add(species, where)
		_count(kind)


func _lay_boundary(boundary: Dictionary, height: Callable, rng: RandomNumberGenerator) -> void:
	var kind: String = String(boundary.get("kind", ""))
	var species: int = -1
	var piece: float = WorkedLandKit.RUN_LENGTH
	match kind:
		"hedge":
			species = Species.HEDGE_RUN
		"wall":
			species = Species.WALL_RUN
		"wall_tumbled":
			species = Species.WALL_TUMBLE
		"fence":
			species = Species.FENCE_RUN
		"hurdle":
			species = Species.HURDLE_RUN
			piece = WorkedLandKit.HURDLE_LENGTH
		_:
			return
	var points: PackedVector2Array = points_of(boundary.get("points", []))
	if points.size() < 2:
		return
	var along: PackedFloat32Array = PackedFloat32Array([0.0])
	for index: int in range(1, points.size()):
		along.append(along[index - 1] + points[index - 1].distance_to(points[index]))
	var total: float = along[along.size() - 1]
	# The gateways: a field gate stands in a gap wide enough for it, a stile in a narrow one, a plain gap stays as drawn.
	var open: Array[Vector2] = []
	for gap: Variant in boundary.get("gaps", []):
		var entry: Array = gap as Array
		var middle: float = (float(entry[0]) + float(entry[1])) * 0.5
		var width: float = float(entry[1]) - float(entry[0])
		var what: String = String(entry[2])
		if what == "gate":
			width = GATE_GAP
		elif what == "stile":
			width = STILE_GAP
		if middle - width * 0.5 < 0.3 or middle + width * 0.5 > total - 0.3:
			continue
		open.append(Vector2(middle - width * 0.5, middle + width * 0.5))
		if what == "gate" or what == "stile":
			var a: Vector2 = _point_along(points, along, middle - 0.5)
			var b: Vector2 = _point_along(points, along, middle + 0.5)
			_add(Species.FIELD_GATE if what == "gate" else Species.STILE, _run_transform(a, b, 1.0, height, Vector2(1.0, 1.0)))
			_count("gates" if what == "gate" else "stiles")
		else:
			_count("gaps")
	open.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var from: float = 0.0
	var solid: Array[Vector2] = []
	for gap: Vector2 in open:
		if gap.x > from:
			solid.append(Vector2(from, gap.x))
		from = maxf(from, gap.y)
	if from < total:
		solid.append(Vector2(from, total))
	for stretch: Vector2 in solid:
		var length: float = stretch.y - stretch.x
		if length < SHORTEST_RUN:
			continue
		var runs: int = maxi(1, roundi(length / piece))
		var each: float = length / float(runs)
		for run: int in runs:
			if species == Species.WALL_TUMBLE and rng.randf() < TUMBLED_MISSING:
				continue
			var a: Vector2 = _point_along(points, along, stretch.x + each * run)
			var b: Vector2 = _point_along(points, along, stretch.x + each * (run + 1))
			var kind_here: int = species
			var grow: Vector2 = Vector2(1.0, 1.0)
			if species == Species.HEDGE_RUN:
				# A hedge is never one height: each run its own, some in blossom, some turned about.
				grow = Vector2(rng.randf_range(0.86, 1.22), rng.randf_range(0.92, 1.2))
				if rng.randf() < BLOOM_SHARE:
					kind_here = Species.HEDGE_BLOOM
				if rng.randf() < 0.5:
					var swap: Vector2 = a
					a = b
					b = swap
			elif species == Species.WALL_RUN:
				grow = Vector2(rng.randf_range(0.94, 1.06), 1.0)
			_add(kind_here, _run_transform(a, b, piece, height, grow))
			_count(Species.keys()[species])
	_count("boundary_m", int(total))


## A ring of boundary round an entry's spot (generator metres, as _lay_boundary reads them), open toward its facing.
static func _ring(entry: Dictionary, radius: float, kind: String) -> Dictionary:
	var centre: Array = entry["at"]
	var facing: Vector2 = facing_of(entry)
	var start: float = atan2(facing.y, facing.x)
	var points: Array = []
	for step: int in 25:
		var angle: float = start + TAU * float(step) / 24.0
		points.append([float(centre[0]) + cos(angle) * radius, float(centre[1]) + sin(angle) * radius])
	var around: float = TAU * radius
	return {"kind": kind, "points": points, "gaps": [[around * 0.5 - 1.0, around * 0.5 + 1.0, "gap"]]}


## A run from `a` to `b` on the ground: its length stretched to fit, its foot following the slope.
## `grow`: x its height, y its thickness.
static func _run_transform(a: Vector2, b: Vector2, piece: float, height: Callable, grow: Vector2) -> Transform3D:
	var from: Vector3 = Vector3(a.x, float(height.call(a.x, a.y)), a.y)
	var to: Vector3 = Vector3(b.x, float(height.call(b.x, b.y)), b.y)
	var along: Vector3 = to - from
	var length: float = maxf(along.length(), 0.01)
	var x_axis: Vector3 = along / length
	var up: Vector3 = (Vector3.UP - x_axis * Vector3.UP.dot(x_axis)).normalized()
	var z_axis: Vector3 = x_axis.cross(up)
	return Transform3D(Basis(x_axis * (length / piece), up * grow.x, z_axis * grow.y), (from + to) * 0.5 - up * 0.04)


static func _point_along(points: PackedVector2Array, along: PackedFloat32Array, s: float) -> Vector2:
	var total: float = along[along.size() - 1]
	var at: float = clampf(s, 0.0, total)
	var low: int = 0
	var high: int = along.size() - 1
	while high - low > 1:
		var middle: int = (low + high) >> 1
		if along[middle] <= at:
			low = middle
		else:
			high = middle
	var span: float = along[high] - along[low]
	return points[low].lerp(points[high], (at - along[low]) / span if span > 0.0001 else 0.0)


func _add(species: int, where: Transform3D) -> void:
	var chunk: Vector2i = IslandGridResource.chunk_of(where.origin)
	if not _scatter.has(chunk):
		_scatter[chunk] = {}
	var block: Dictionary = _scatter[chunk]
	if not block.has(species):
		block[species] = []
	(block[species] as Array).append(where)


func _count(what: String, by: int = 1) -> void:
	counts[what] = int(counts.get(what, 0)) + by
