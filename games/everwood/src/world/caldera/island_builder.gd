## What one Caldera island is (docs/20 Part I and II): its ground as a height
## field, its colours, what grows where, its named places and arrivals, and
## the structures it builds when it becomes the active island.
##
## The field is the island's own base shape (_base_height, per island) with
## two kinds of feature pressed into it: ramps (a road, a stair, a gully,
## blended to a straight grade between two points) and pads (a flat place at
## a set height: a quay, a market green, a trial's arena, a cove the Ebb bares).
## Paths are only painted. Everything that samples the field is pure and safe
## on a worker thread; the build_* methods make nodes on the main thread.
##
## Each island lives in its own frame: its grid centred on the origin, north
## at -Z, the sea at y = CalderaWorldState.sea_level_y.
class_name IslandBuilder
extends RefCounted

## What the scatter grows (one MultiMesh per species per landblock).
enum Species { ORCHARD_TREE, OAK_TREE, PINE_TREE, SNOW_PINE, REED_CLUMP, ROCK, BOULDER, BASALT_SPIRE, FERN_TUFT, ASH_TREE, WILLOW_TREE }
const SPECIES_COUNT: int = 11
## Trunk and stone radii that block the way inside the loaded window (0: walk through).
const SOLID_RADIUS: Array[float] = [0.3, 0.55, 0.35, 0.35, 0.0, 0.0, 0.9, 0.8, 0.0, 0.4, 0.6]

## Landblock mesh resolutions: the loaded window (2 m) and the whole-island stand-in (8 m).
const NEAR_QUADS: int = 64
const FAR_QUADS: int = 16
## Collider samples per landblock side (every metre, the last shared with the next landblock).
const COLLISION_SIDE: int = 129
## Skirts hang this far below every landblock edge so neighbours of either resolution never show a crack.
const SKIRT_DEPTH: float = 6.0
## Scatter candidates a landblock rolls (each island keeps the share it wants).
const SCATTER_TRIES: int = 260

## Organic coasts (docs/13 K4): in the coastal band (plain shore distance
## COAST_BAND_FROM to 1 and a little beyond) the plain ellipse's shore is pushed
## into bays and headlands by a few broad angular lobes, mid-sized coves and a
## ragged rocky edge. Headlands reach out only COAST_HEADLAND_SHARE as far as bays
## reach in, and never near the island grid's edge (the shelf stays deep there).
const COAST_BAND_FROM: float = 0.55
const COAST_BAND_TO: float = 0.9
const COAST_LOBES: int = 3
const COAST_LOBE_AMP: float = 0.09
const COAST_COVE_AMP: float = 0.13
const COAST_RAGGED_AMP: float = 0.04
const COAST_HEADLAND_SHARE: float = 0.5
## Nothing is reshaped near a pad, ramp, path, arrival, named place or causeway
## anchor: fully kept within the feature's reach plus COAST_KEEP_PAD, eased back over COAST_KEEP_FADE.
const COAST_KEEP_CELL: float = 16.0
const COAST_KEEP_PAD: float = 14.0
const COAST_KEEP_FADE: float = 70.0
## River inlets: a few winding channels run in from the open shore, tapering
## from INLET_MOUTH_HALF to INLET_HEAD_HALF metres, their beds from INLET_MOUTH_BED
## to INLET_HEAD_BED (under the Long Flood; the Ebb bares them).
const INLET_MIN: int = 2
const INLET_MAX: int = 4
const INLET_LENGTH: Vector2 = Vector2(80.0, 150.0)
const INLET_MOUTH_HALF: float = 15.0
const INLET_HEAD_HALF: float = 4.0
const INLET_MOUTH_BED: float = -3.0
const INLET_HEAD_BED: float = -0.8
## The banks ease back to the land over this share of the half width (at least INLET_BANK_MIN metres).
const INLET_BANK_SHARE: float = 1.6
const INLET_BANK_MIN: float = 12.0
## Inlet mouths stand at least this far apart, and this far from any path.
const INLET_SPACING: float = 260.0
const INLET_PATH_CLEARANCE: float = 45.0

const SAND: Color = Color(0.86, 0.79, 0.62)
const WET_SAND: Color = Color(0.56, 0.52, 0.42)
const SEA_BED: Color = Color(0.32, 0.38, 0.36)
const SHINGLE: Color = Color(0.62, 0.6, 0.56)
const PATH_COLOR: Color = Color(0.7, 0.62, 0.46)

var isle: IslandGridResource
## Named places: {"name": String, "at": Vector3, "radius": float}. Walking into one names it.
var places: Array[Dictionary] = []
## Where a party arrives (by CalderaAtlas.ARRIVE_* id), on the ground.
var arrivals: Dictionary[StringName, Vector3] = {}

var _noise: FastNoiseLite
var _detail: FastNoiseLite
## Pads, 5 floats each: x, z, radius, blend, height.
var _pads: PackedFloat32Array = PackedFloat32Array()
## Ramps, 8 floats each: from x, y, z, to x, y, z, half width, blend.
var _ramps: PackedFloat32Array = PackedFloat32Array()
## Painted paths, 5 floats a segment: from x, z, to x, z, half width.
var _paths: PackedFloat32Array = PackedFloat32Array()
## River inlets, 8 floats a segment: from x, z, to x, z, half width at each end, bed height at each end.
var _inlets: PackedFloat32Array = PackedFloat32Array()
## The coast's angular lobes, 3 floats each: harmonic, amplitude, phase.
var _lobes: PackedFloat32Array = PackedFloat32Array()
## How much of the plain shore is kept (1 near features, 0 free), every COAST_KEEP_CELL metres over the grid.
var _keep: PackedFloat32Array = PackedFloat32Array()
var _keep_side: int = 0
var _coast_ready: bool = false


func _init(grid: IslandGridResource) -> void:
	isle = grid
	_noise = FastNoiseLite.new()
	_noise.seed = hash(String(grid.isle_id)) % 100000
	_noise.frequency = 0.0035
	_noise.fractal_octaves = 3
	_detail = FastNoiseLite.new()
	_detail.seed = _noise.seed + 17
	_detail.frequency = 0.02
	_detail.fractal_octaves = 2
	_define()
	_prepare_coast()
	for id: StringName in arrivals.keys():
		var at: Vector3 = arrivals[id]
		arrivals[id] = Vector3(at.x, height_at(at.x, at.z), at.z)


# --- What each island fills in ------------------------------------------------

## Lays out the island's pads, ramps, paths, places and arrivals (called once from _init).
func _define() -> void:
	pass


## The island's ground before pads and ramps.
func _base_height(_x: float, _z: float) -> float:
	return -10.0


## The ground's colour before paths: `up` is the ground normal's y (1 flat, 0 sheer).
func _ground_color(_x: float, _z: float, height: float, up: float) -> Color:
	return shore_or(height, up, Color(0.42, 0.56, 0.3), Color(0.5, 0.48, 0.44))


## What grows at a spot (a Species, or -1). `roll` is a fair 0..1 die.
func _scatter_species(_x: float, _z: float, _height: float, _up: float, _roll: float) -> int:
	return -1


## Builds the island's structures, people, landmarks and encounters under `root` (main thread).
func build_structures(_root: Node3D) -> void:
	pass


## The island's plain elliptical shore as {"center": Vector2, "semi": Vector2}, or {} when its coast is its own (no reshaping, no inlets).
func _coast_shape() -> Dictionary:
	return {}


## The highest ground (metres) a river inlet may cut through: low shores take rivers; a cliff isle may take a firth.
func _inlet_max_rise() -> float:
	return 16.0


## A merged far silhouette of the island's landmark, in its own frame (for other islands' horizons).
func landmark_silhouette(_merge: LandblockTerrain.MeshMerge) -> void:
	pass


# --- Laying out ----------------------------------------------------------------

func add_pad(at: Vector2, radius: float, height: float, blend: float = 6.0) -> void:
	_pads.append_array(PackedFloat32Array([at.x, at.y, radius, blend, height]))


func add_ramp(from: Vector3, to: Vector3, half_width: float, blend: float = 4.0) -> void:
	_ramps.append_array(PackedFloat32Array([from.x, from.y, from.z, to.x, to.y, to.z, half_width, blend]))


func add_path(points: PackedVector2Array, half_width: float = 1.6) -> void:
	for index: int in points.size() - 1:
		_paths.append_array(PackedFloat32Array([points[index].x, points[index].y, points[index + 1].x, points[index + 1].y, half_width]))


func add_place(place_name: String, at: Vector3, radius: float) -> void:
	places.append({"name": place_name, "at": at, "radius": radius})


func add_arrival(id: StringName, at: Vector2) -> void:
	arrivals[id] = Vector3(at.x, 0.0, at.y)


# --- Sampling (pure, worker-safe) --------------------------------------------------

func height_at(x: float, z: float) -> float:
	return _height(x, z, _pads, _ramps)


func ground(x: float, z: float) -> Vector3:
	return Vector3(x, height_at(x, z), z)


## The ground's normal y at a spot, from the field 1 m around it.
func up_at(x: float, z: float) -> float:
	var dx: float = height_at(x + 1.0, z) - height_at(x - 1.0, z)
	var dz: float = height_at(x, z + 1.0) - height_at(x, z - 1.0)
	return Vector3(-dx * 0.5, 1.0, -dz * 0.5).normalized().y


func surface_color(x: float, z: float, height: float, up: float) -> Color:
	return _paint(x, z, height, up, _paths)


## Whether a spot lies on a painted path.
func on_path(x: float, z: float) -> bool:
	return _path_weight(x, z, _paths) > 0.5


## The named place a spot is in (the nearest whose reach holds it), or the island's name.
func place_name_at(at: Vector3) -> String:
	var best: String = isle.display_name
	var best_share: float = 1.0
	for place: Dictionary in places:
		var spot: Vector3 = place["at"]
		var share: float = Vector2(at.x - spot.x, at.z - spot.z).length() / float(place["radius"])
		if share < best_share:
			best_share = share
			best = String(place["name"])
	return best


func place(place_name: String) -> Dictionary:
	for each: Dictionary in places:
		if String(each["name"]) == place_name:
			return each
	return {}


## A party member's spot at an arrival (spread in a row of four, `slot` from 0), on the ground.
func arrival_spot(id: StringName, slot: int = 0) -> Vector3:
	var at: Vector3 = arrivals.get(id, arrivals.values()[0] if not arrivals.is_empty() else Vector3.ZERO)
	var x: float = at.x + (float(slot % 4) - 1.5) * 2.4
	@warning_ignore("integer_division")
	var z: float = at.z + float(slot / 4) * 2.4
	return Vector3(x, height_at(x, z) + 0.1, z)


func _height(x: float, z: float, pads: PackedFloat32Array, ramps: PackedFloat32Array) -> float:
	var h: float = _base_height(x, z)
	if not _inlets.is_empty():
		h = _carve_inlets(x, z, h)
	var index: int = 0
	while index < ramps.size():
		var ax: float = ramps[index]
		var az: float = ramps[index + 2]
		var abx: float = ramps[index + 3] - ax
		var abz: float = ramps[index + 5] - az
		var length2: float = maxf(abx * abx + abz * abz, 0.0001)
		var t: float = clampf(((x - ax) * abx + (z - az) * abz) / length2, 0.0, 1.0)
		var px: float = x - (ax + abx * t)
		var pz: float = z - (az + abz * t)
		var reach: float = ramps[index + 6] + ramps[index + 7]
		var d2: float = px * px + pz * pz
		if d2 < reach * reach:
			var weight: float = 1.0 - smoothstep(ramps[index + 6], reach, sqrt(d2))
			h = lerpf(h, lerpf(ramps[index + 1], ramps[index + 4], t), weight)
		index += 8
	index = 0
	while index < pads.size():
		var dx: float = x - pads[index]
		var dz: float = z - pads[index + 1]
		var reach: float = pads[index + 2] + pads[index + 3]
		var d2: float = dx * dx + dz * dz
		if d2 < reach * reach:
			var weight: float = 1.0 - smoothstep(pads[index + 2], reach, sqrt(d2))
			h = lerpf(h, pads[index + 4], weight)
		index += 5
	return h


func _paint(x: float, z: float, height: float, up: float, paths: PackedFloat32Array) -> Color:
	var color: Color = _ground_color(x, z, height, up)
	var on: float = _path_weight(x, z, paths)
	if on > 0.0 and height > 0.4 and up > 0.8:
		color = color.lerp(PATH_COLOR.lerp(color, 0.15 * _detail.get_noise_2d(x * 3.0, z * 3.0)), on)
	return color


func _path_weight(x: float, z: float, paths: PackedFloat32Array) -> float:
	var best: float = 0.0
	var index: int = 0
	while index < paths.size():
		var ax: float = paths[index]
		var az: float = paths[index + 1]
		var abx: float = paths[index + 2] - ax
		var abz: float = paths[index + 3] - az
		var length2: float = maxf(abx * abx + abz * abz, 0.0001)
		var t: float = clampf(((x - ax) * abx + (z - az) * abz) / length2, 0.0, 1.0)
		var px: float = x - (ax + abx * t)
		var pz: float = z - (az + abz * t)
		var half: float = paths[index + 4]
		var d2: float = px * px + pz * pz
		if d2 < (half + 0.8) * (half + 0.8):
			best = maxf(best, 1.0 - smoothstep(half - 0.6, half + 0.8, sqrt(d2)))
		index += 5
	return best


## Only the pads, ramps and paths that can touch `rect` (grown by their reach), for a landblock's samples.
func _features_near(rect: Rect2) -> Array[PackedFloat32Array]:
	var pads: PackedFloat32Array = PackedFloat32Array()
	var index: int = 0
	while index < _pads.size():
		var reach: float = _pads[index + 2] + _pads[index + 3]
		if rect.grow(reach).has_point(Vector2(_pads[index], _pads[index + 1])):
			pads.append_array(_pads.slice(index, index + 5))
		index += 5
	var ramps: PackedFloat32Array = PackedFloat32Array()
	index = 0
	while index < _ramps.size():
		var reach: float = _ramps[index + 6] + _ramps[index + 7]
		var box: Rect2 = Rect2(Vector2(_ramps[index], _ramps[index + 2]), Vector2.ZERO).expand(Vector2(_ramps[index + 3], _ramps[index + 5])).grow(reach)
		if box.intersects(rect):
			ramps.append_array(_ramps.slice(index, index + 8))
		index += 8
	var paths: PackedFloat32Array = PackedFloat32Array()
	index = 0
	while index < _paths.size():
		var box: Rect2 = Rect2(Vector2(_paths[index], _paths[index + 1]), Vector2.ZERO).expand(Vector2(_paths[index + 2], _paths[index + 3])).grow(_paths[index + 4] + 1.0)
		if box.intersects(rect):
			paths.append_array(_paths.slice(index, index + 5))
		index += 5
	return [pads, ramps, paths]


# --- Shared shapes for the islands ---------------------------------------------------

## How far out a spot lies on an elliptical coast (1 at the shore), its edge
## wandering by `wobble`; once the coast is prepared, reshaped in the coastal band
## into bays, headlands and a ragged edge (see COAST_*).
func ellipse_q(x: float, z: float, center: Vector2, semi: Vector2, wobble: float) -> float:
	var offset: Vector2 = Vector2((x - center.x) / semi.x, (z - center.y) / semi.y)
	var plain: float = offset.length() * (1.0 + wobble * _noise.get_noise_2d(x * 0.6, z * 0.6))
	if not _coast_ready or plain <= COAST_BAND_FROM or plain >= 1.5:
		return plain
	var band: float = smoothstep(COAST_BAND_FROM, COAST_BAND_TO, plain) * (1.0 - smoothstep(1.3, 1.5, plain))
	var free: float = 1.0 - coast_kept(x, z)
	if band * free <= 0.0:
		return plain
	return plain * (1.0 + _coast_push(x, z, offset.angle()) * band * free)


## The coast's push at a spot: above 0 the sea bites in (a bay), below 0 the land reaches out (a headland).
func _coast_push(x: float, z: float, angle: float) -> float:
	var push: float = 0.0
	var index: int = 0
	while index < _lobes.size():
		push += _lobes[index + 1] * sin(_lobes[index] * angle + _lobes[index + 2])
		index += 3
	push += COAST_COVE_AMP * _noise.get_noise_2d(x * 1.7 + 311.0, z * 1.7 - 97.0)
	push += COAST_RAGGED_AMP * (_detail.get_noise_2d(x * 0.7, z * 0.7) + 0.2 * _detail.get_noise_2d(x * 2.1 + 50.0, z * 2.1 - 20.0))
	if push < 0.0:
		var half: float = isle.half_size_m()
		push *= COAST_HEADLAND_SHARE * (1.0 - smoothstep(half - 190.0, half - 70.0, maxf(absf(x), absf(z))))
	return push


## How much of the plain shore is kept at a spot (1 beside a pad, ramp, path, arrival, place or anchor; 0 free to reshape).
func coast_kept(x: float, z: float) -> float:
	if _keep_side == 0:
		return 1.0
	var half: float = isle.half_size_m()
	var fx: float = clampf((x + half) / COAST_KEEP_CELL, 0.0, float(_keep_side - 1) - 0.001)
	var fz: float = clampf((z + half) / COAST_KEEP_CELL, 0.0, float(_keep_side - 1) - 0.001)
	var x0: int = int(fx)
	var z0: int = int(fz)
	var tx: float = fx - x0
	var tz: float = fz - z0
	var at: int = z0 * _keep_side + x0
	return lerpf(lerpf(_keep[at], _keep[at + 1], tx), lerpf(_keep[at + _keep_side], _keep[at + _keep_side + 1], tx), tz)


## Whether the island's shore is reshaped (its builder gave a plain shape).
func has_organic_coast() -> bool:
	return _coast_ready


## The river inlets' centre lines, 2 points each (mouth, then head), as island-frame x-z.
func inlet_lines() -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	var index: int = 0
	var line: PackedVector2Array = PackedVector2Array()
	while index < _inlets.size():
		if line.is_empty():
			line.append(Vector2(_inlets[index], _inlets[index + 1]))
		line.append(Vector2(_inlets[index + 2], _inlets[index + 3]))
		# A new inlet starts where a segment doesn't continue the last one.
		var next: int = index + 8
		if next >= _inlets.size() or not Vector2(_inlets[next], _inlets[next + 1]).is_equal_approx(Vector2(_inlets[index + 2], _inlets[index + 3])):
			lines.append(line)
			line = PackedVector2Array()
		index += 8
	return lines


## Builds the keep grid, the coast's lobes and the river inlets (once, after _define).
func _prepare_coast() -> void:
	var shape: Dictionary = _coast_shape()
	if shape.is_empty():
		return
	var center: Vector2 = shape["center"]
	var semi: Vector2 = shape["semi"]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("coast:%s" % isle.isle_id)
	var harmonics: Array[int] = [2, 3, 4, 5, 6]
	for lobe: int in COAST_LOBES:
		var pick: int = harmonics.pop_at(rng.randi_range(0, harmonics.size() - 1))
		_lobes.append_array(PackedFloat32Array([float(pick), COAST_LOBE_AMP * rng.randf_range(0.6, 1.0), rng.randf() * TAU]))
	_build_keep_grid()
	_coast_ready = true
	_lay_inlets(center, semi, rng)


## The keepers (x0, z0, x1, z1, reach) as segments: pads and arrivals as points.
func _coast_keepers() -> PackedFloat32Array:
	var keepers: PackedFloat32Array = PackedFloat32Array()
	var index: int = 0
	while index < _pads.size():
		keepers.append_array(PackedFloat32Array([_pads[index], _pads[index + 1], _pads[index], _pads[index + 1], _pads[index + 2] + _pads[index + 3]]))
		index += 5
	index = 0
	while index < _ramps.size():
		keepers.append_array(PackedFloat32Array([_ramps[index], _ramps[index + 2], _ramps[index + 3], _ramps[index + 5], _ramps[index + 6] + _ramps[index + 7]]))
		index += 8
	index = 0
	while index < _paths.size():
		keepers.append_array(PackedFloat32Array([_paths[index], _paths[index + 1], _paths[index + 2], _paths[index + 3], _paths[index + 4]]))
		index += 5
	for at: Vector3 in arrivals.values():
		keepers.append_array(PackedFloat32Array([at.x, at.z, at.x, at.z, 20.0]))
	for each: Dictionary in places:
		var spot: Vector3 = each["at"]
		keepers.append_array(PackedFloat32Array([spot.x, spot.z, spot.x, spot.z, minf(float(each["radius"]), 40.0)]))
	for seam: LoadSeamResource in CalderaAtlas.seams_of(isle.isle_id):
		var anchor: Vector3 = seam.anchor(isle.isle_id)
		keepers.append_array(PackedFloat32Array([anchor.x, anchor.z, anchor.x, anchor.z, 40.0]))
	return keepers


func _build_keep_grid() -> void:
	var half: float = isle.half_size_m()
	_keep_side = int(ceil(half * 2.0 / COAST_KEEP_CELL)) + 1
	_keep.resize(_keep_side * _keep_side)
	_keep.fill(0.0)
	var keepers: PackedFloat32Array = _coast_keepers()
	for row: int in _keep_side:
		var z: float = -half + row * COAST_KEEP_CELL
		for column: int in _keep_side:
			var x: float = -half + column * COAST_KEEP_CELL
			var kept: float = 0.0
			var index: int = 0
			while index < keepers.size() and kept < 1.0:
				var reach: float = keepers[index + 4] + COAST_KEEP_PAD
				var outer: float = reach + COAST_KEEP_FADE
				var ax: float = keepers[index]
				var az: float = keepers[index + 1]
				var bx: float = keepers[index + 2]
				var bz: float = keepers[index + 3]
				if x < minf(ax, bx) - outer or x > maxf(ax, bx) + outer or z < minf(az, bz) - outer or z > maxf(az, bz) + outer:
					index += 5
					continue
				var abx: float = bx - ax
				var abz: float = bz - az
				var t: float = clampf(((x - ax) * abx + (z - az) * abz) / maxf(abx * abx + abz * abz, 0.0001), 0.0, 1.0)
				var d: float = Vector2(x - (ax + abx * t), z - (az + abz * t)).length()
				kept = maxf(kept, 1.0 - smoothstep(reach, outer, d))
				index += 5
			_keep[row * _keep_side + column] = kept


## Lays INLET_MIN to INLET_MAX river inlets on free, low stretches of the open shore, well clear of paths and each other.
func _lay_inlets(center: Vector2, semi: Vector2, rng: RandomNumberGenerator) -> void:
	var candidates: Array[Dictionary] = []
	var steps: int = 64
	for step: int in steps:
		var angle: float = TAU * (float(step) + rng.randf_range(-0.3, 0.3)) / steps
		var direction: Vector2 = Vector2(cos(angle) * semi.x, sin(angle) * semi.y)
		# Walk out along the ray to the reshaped shore (the first spot at sea level).
		var shore: float = -1.0
		var share: float = 0.6
		while share < 1.45:
			var at: Vector2 = center + direction * share
			if _base_height(at.x, at.y) < 0.0:
				shore = share
				break
			share += 0.01
		if shore < 0.0:
			continue
		var mouth: Vector2 = center + direction * shore
		var inward: Vector2 = (center - mouth).normalized()
		var length: float = rng.randf_range(INLET_LENGTH.x, INLET_LENGTH.y)
		var head: Vector2 = mouth + inward * length
		var free: bool = true
		var low: float = 0.0
		for sample: int in 6:
			var along: Vector2 = mouth.lerp(head, float(sample) / 5.0)
			if coast_kept(along.x, along.y) > 0.02 or _path_distance(along) < INLET_PATH_CLEARANCE:
				free = false
				break
			low = maxf(low, _base_height(along.x, along.y))
		# The plain must stay well inland of the head (no channel cuts an island through).
		var head_plain: float = Vector2((head.x - center.x) / semi.x, (head.y - center.y) / semi.y).length()
		if not free or head_plain < 0.45 or low > _inlet_max_rise():
			continue
		candidates.append({"mouth": mouth, "head": head, "score": low + rng.randf() * 4.0})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) < float(b["score"]))
	var wanted: int = rng.randi_range(INLET_MIN, INLET_MAX)
	var mouths: Array[Vector2] = []
	for candidate: Dictionary in candidates:
		if mouths.size() >= wanted:
			break
		var mouth: Vector2 = candidate["mouth"]
		var near_other: bool = false
		for other: Vector2 in mouths:
			if other.distance_to(mouth) < INLET_SPACING:
				near_other = true
		if near_other:
			continue
		mouths.append(mouth)
		_add_inlet(mouth, candidate["head"], rng)


## One inlet: three winding segments from a little offshore of the mouth to the head.
func _add_inlet(mouth: Vector2, head: Vector2, rng: RandomNumberGenerator) -> void:
	var inward: Vector2 = (head - mouth).normalized()
	var side: Vector2 = inward.orthogonal()
	var points: Array[Vector2] = [mouth - inward * 24.0]
	for bend: int in [1, 2]:
		points.append(mouth.lerp(head, float(bend) / 3.0) + side * rng.randf_range(-14.0, 14.0))
	points.append(head)
	for index: int in points.size() - 1:
		var t0: float = float(index) / float(points.size() - 1)
		var t1: float = float(index + 1) / float(points.size() - 1)
		_inlets.append_array(PackedFloat32Array([points[index].x, points[index].y, points[index + 1].x, points[index + 1].y,
			lerpf(INLET_MOUTH_HALF, INLET_HEAD_HALF, t0), lerpf(INLET_MOUTH_HALF, INLET_HEAD_HALF, t1),
			lerpf(INLET_MOUTH_BED, INLET_HEAD_BED, t0), lerpf(INLET_MOUTH_BED, INLET_HEAD_BED, t1)]))


func _path_distance(at: Vector2) -> float:
	var best: float = INF
	var index: int = 0
	while index < _paths.size():
		var a: Vector2 = Vector2(_paths[index], _paths[index + 1])
		var b: Vector2 = Vector2(_paths[index + 2], _paths[index + 3])
		best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) - _paths[index + 4])
		index += 5
	return best


## The ground cut down to an inlet's bed where a channel runs (never raised), its banks easing back to the land.
func _carve_inlets(x: float, z: float, h: float) -> float:
	var index: int = 0
	while index < _inlets.size():
		var ax: float = _inlets[index]
		var az: float = _inlets[index + 1]
		var abx: float = _inlets[index + 2] - ax
		var abz: float = _inlets[index + 3] - az
		var widest: float = maxf(_inlets[index + 4], _inlets[index + 5])
		var reach: float = widest + maxf(widest * INLET_BANK_SHARE, INLET_BANK_MIN)
		if x > minf(ax, ax + abx) - reach and x < maxf(ax, ax + abx) + reach and z > minf(az, az + abz) - reach and z < maxf(az, az + abz) + reach:
			var t: float = clampf(((x - ax) * abx + (z - az) * abz) / maxf(abx * abx + abz * abz, 0.0001), 0.0, 1.0)
			var d: float = Vector2(x - (ax + abx * t), z - (az + abz * t)).length()
			var half: float = lerpf(_inlets[index + 4], _inlets[index + 5], t)
			var bank: float = maxf(half * INLET_BANK_SHARE, INLET_BANK_MIN)
			var bed: float = lerpf(_inlets[index + 6], _inlets[index + 7], t)
			if d < half + bank and bed < h:
				# A rounded channel floor, then banks easing back up to the land.
				var floor_shape: float = bed + 1.4 * smoothstep(0.0, half, d) * (d / maxf(half, 0.01))
				var weight: float = 1.0 - smoothstep(half, half + bank, d)
				h = minf(h, lerpf(h, floor_shape, weight))
		index += 8
	return h


## Below the shore (q > 1): the shelf drops to the Sound's floor.
func sea_floor(q: float) -> float:
	return -1.5 - 20.0 * smoothstep(1.0, 1.32, q)


## A sand beach at sea level, rock where the ground is steep, `turf` elsewhere.
func shore_or(height: float, up: float, turf: Color, rock: Color) -> Color:
	if height < -1.0:
		return SEA_BED.lerp(WET_SAND, clampf((height + 8.0) / 7.0, 0.0, 1.0))
	if height < 1.4 and up > 0.8:
		return WET_SAND.lerp(SAND, clampf((height + 1.0) / 1.6, 0.0, 1.0))
	if up < 0.74:
		return rock
	return turf.lerp(rock, smoothstep(0.86, 0.74, up))


func noise(x: float, z: float) -> float:
	return _noise.get_noise_2d(x, z)


func detail(x: float, z: float) -> float:
	return _detail.get_noise_2d(x, z)


# --- Landblock data (worker-safe) -----------------------------------------------------

## One landblock's ground at `quads` cells a side: vertices, normals, colours,
## indices (skirts included), and when asked the collider's heights (every
## metre) and the scatter (Species -> Array of Transform3D).
func build_chunk_data(chunk: Vector2i, quads: int, with_collision: bool, with_scatter: bool) -> Dictionary:
	var size: float = IslandGridResource.CHUNK_SIZE
	var origin: Vector2 = Vector2(chunk.x * size, chunk.y * size)
	var step: float = size / float(quads)
	var near: Array[PackedFloat32Array] = _features_near(Rect2(origin, Vector2(size, size)).grow(step * 2.0))
	var pads: PackedFloat32Array = near[0]
	var ramps: PackedFloat32Array = near[1]
	var paths: PackedFloat32Array = near[2]
	var side: int = quads + 1
	var apron: int = side + 2
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(apron * apron)
	for row: int in apron:
		for column: int in apron:
			heights[row * apron + column] = _height(origin.x + (column - 1) * step, origin.y + (row - 1) * step, pads, ramps)
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	vertices.resize(side * side + side * 4)
	normals.resize(side * side + side * 4)
	colors.resize(side * side + side * 4)
	for row: int in side:
		for column: int in side:
			var at: int = (row + 1) * apron + column + 1
			var x: float = origin.x + column * step
			var z: float = origin.y + row * step
			var index: int = row * side + column
			var h: float = heights[at]
			vertices[index] = Vector3(x, h, z)
			var slope_x: float = (heights[at + 1] - heights[at - 1]) / (2.0 * step)
			var slope_z: float = (heights[at + apron] - heights[at - apron]) / (2.0 * step)
			var normal: Vector3 = Vector3(-slope_x, 1.0, -slope_z).normalized()
			normals[index] = normal
			var painted: Color = _paint(x, z, h, normal.y, paths)
			var rise: float = maxf(maxf(heights[at + 1], heights[at - 1]), maxf(heights[at + apron], heights[at - apron])) - h
			painted.a = 1.0 - LandblockTerrain.cliff_toe(rise, step, normal.y)
			colors[index] = painted
	var indices: PackedInt32Array = PackedInt32Array()
	for row: int in quads:
		for column: int in quads:
			var a: int = row * side + column
			indices.append_array(PackedInt32Array([a, a + 1, a + side, a + 1, a + side + 1, a + side]))
	# Skirts: each edge's vertices again, SKIRT_DEPTH lower, stitched to the edge (both faces wound outward).
	var edges: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
	for i: int in side:
		edges[0].append(i)
		edges[1].append((side - 1) * side + i)
		edges[2].append(i * side)
		edges[3].append(i * side + side - 1)
	var cursor: int = side * side
	for edge: int in 4:
		var start: int = cursor
		for i: int in side:
			var top: int = edges[edge][i]
			vertices[cursor] = vertices[top] - Vector3(0.0, SKIRT_DEPTH, 0.0)
			normals[cursor] = normals[top]
			colors[cursor] = colors[top].darkened(0.2)
			cursor += 1
		for i: int in quads:
			var a: int = edges[edge][i]
			var b: int = edges[edge][i + 1]
			var c: int = start + i
			var d: int = start + i + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d, a, b, c, b, d, c]))
	var data: Dictionary = {"vertices": vertices, "normals": normals, "colors": colors, "indices": indices}
	if with_collision:
		data["collision_heights"] = _collision_heights(heights, apron, quads)
	if with_scatter:
		data["scatter"] = _scatter(chunk, origin, pads, ramps, paths)
	return data


## The collider's heights every metre (129 to a side), from the mesh samples where they fall on a metre and bilinear between.
func _collision_heights(heights: PackedFloat32Array, apron: int, quads: int) -> PackedFloat32Array:
	var collision: PackedFloat32Array = PackedFloat32Array()
	collision.resize(COLLISION_SIDE * COLLISION_SIDE)
	var per_cell: float = float(quads) / float(COLLISION_SIDE - 1)
	for row: int in COLLISION_SIDE:
		var fz: float = row * per_cell
		var z0: int = mini(int(fz), quads - 1)
		var tz: float = fz - z0
		for column: int in COLLISION_SIDE:
			var fx: float = column * per_cell
			var x0: int = mini(int(fx), quads - 1)
			var tx: float = fx - x0
			var a: float = heights[(z0 + 1) * apron + x0 + 1]
			var b: float = heights[(z0 + 1) * apron + x0 + 2]
			var c: float = heights[(z0 + 2) * apron + x0 + 1]
			var d: float = heights[(z0 + 2) * apron + x0 + 2]
			collision[row * COLLISION_SIDE + column] = lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)
	return collision


func _scatter(chunk: Vector2i, origin: Vector2, pads: PackedFloat32Array, ramps: PackedFloat32Array, paths: PackedFloat32Array) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d" % [isle.isle_id, chunk.x, chunk.y])
	var grown: Dictionary = {}
	var size: float = IslandGridResource.CHUNK_SIZE
	for attempt: int in SCATTER_TRIES:
		var x: float = origin.x + rng.randf() * size
		var z: float = origin.y + rng.randf() * size
		var roll: float = rng.randf()
		var yaw: float = rng.randf() * TAU
		var scale: float = rng.randf_range(0.8, 1.3)
		var h: float = _height(x, z, pads, ramps)
		var dx: float = _height(x + 1.0, z, pads, ramps) - _height(x - 1.0, z, pads, ramps)
		var dz: float = _height(x, z + 1.0, pads, ramps) - _height(x, z - 1.0, pads, ramps)
		var up: float = Vector3(-dx * 0.5, 1.0, -dz * 0.5).normalized().y
		if _path_weight(x, z, paths) > 0.0:
			continue
		var species: int = _scatter_species(x, z, h, up, roll)
		if species < 0:
			continue
		if not grown.has(species):
			grown[species] = []
		(grown[species] as Array).append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), Vector3(x, h - 0.05, z)))
	return grown
