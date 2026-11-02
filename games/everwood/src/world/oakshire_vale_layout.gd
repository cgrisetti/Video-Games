## Oakshire Vale (12_WORLD_OAKSHIRE_VALE_GDD.md): the starting zone, 1,536 m
## square (12 x 12 Landblocks, chunks (0, 0) to (11, 11)), a 1,280 m floor
## inside a 128 m skirt of cliff and forest.
##
## A pinwheel basin round Oakshire Village on a raised central saddle (+12 m),
## the Scribe's Tor ridge behind it, in concentric rings measured as a rounded
## square (a superellipse) out from the centre:
##   Tier 0  the river and mill basin, 0 to 4 m: a wadeable river (0.4 m deep)
##           arcing west to east south of the village, under the Bridge-Warden's span
##   Tier 1  the settled meadow and the High Road, 4 to 14 m, gently rolling
##   Tier 2  the Bramble Weald and the quarry terraces, 14 to 32 m: shelves with
##           cliffs between them (too steep to climb), the roads ramping through
##   Tier 3  the rim crags, 32 to 65 m: a sheer escarpment with the four dungeon
##           and raid portal aprons recessed into it
## Five petal valleys radiate from the village, each with an S-curve road that
## bends round rock spurs; the High Road rings the meadow between them.
##
## The field is pure functions of (x, z) and fixed tables (field_height), each
## O(1). tools/build_oakshire_vale.gd bakes it to a 2 m grid (FIELD_PATH),
## which sample_height and surface_color read when it's there: exact, seamless
## and fast enough to stream. Clutter, hero trees and waymarkers are placed
## from each chunk's own seed, so the vale always grows back the same.
class_name OakshireValeLayout
extends WorldLayout

enum Petal { WEALD, QUARRY, GLADE, BARROWS, ORCHARD }

const LAYOUT_ID: StringName = &"oakshire_vale"
const CHUNKS: int = 12
const SIZE: float = 1536.0
const CENTER: Vector2 = Vector2(768.0, 768.0)
const LANDBLOCK_FOLDER: String = "res://data/landblocks/oakshire_vale/"
## The baked field (OakshireValeField) and the whole-zone horizon mesh.
const FIELD_PATH: String = "res://data/landblocks/oakshire_vale/field.res"
const HORIZON_PATH: String = "res://data/landblocks/oakshire_vale/horizon.res"
## Metres between the baked field's samples (769 to a side).
const FIELD_STEP: float = 2.0

# --- The rings (superellipse distance from the centre, metres) -----------------
const RING_POWER: float = 4.0
const VILLAGE_RADIUS: float = 62.0
const VILLAGE_HEIGHT: float = 12.0
const BASIN_RADIUS: float = 140.0
const BASIN_HEIGHT: float = 6.0
const MEADOW_OUTER: float = 340.0
const MEADOW_HEIGHT: float = 14.0
const CLIFF_FOOT: float = 600.0
const TERRACE_TOP: float = 31.0
const CLIFF_TOP_RADIUS: float = 614.0
const CLIFF_TOP_HEIGHT: float = 58.0
const SKIRT_HEIGHT: float = 70.0
## Three shelves between the meadow and the cliff, each riser 6% of its band (steeper than 50°).
const TERRACE_COUNT: int = 3
const TERRACE_RISER: float = 0.06
## The meadow rolls by up to this much (slopes of 5° to 12°).
const MEADOW_ROLL: float = 1.6

# --- The petals ------------------------------------------------------------------
const PETAL_NAMES: Array[String] = ["The Bramble Weald", "The East Quarry", "Wayfarer's Glade", "The Barrow Hills", "The Orchard Reach"]
## Bearings in degrees clockwise from north (-Z).
const PETAL_BEARINGS: Array[float] = [40.0, 112.0, 184.0, 256.0, 328.0]
## How far each road sways from its bearing (radians): an S of two 35°–50° bends.
const PETAL_SWAY: Array[float] = [0.2, -0.19, 0.17, -0.21, 0.19]
## The petal camps sit this far out (superellipse distance), beside the road.
const CAMP_DISTANCE: float = 450.0
const CAMP_OFFSET: float = 20.0
const CAMP_RADIUS: float = 17.0
const GLADE_RADIUS: float = 24.0
## The petals with a portal apron at the road's end (the Glade has the Wayfarer's Arch instead).
const APRON_PETALS: Array[int] = [Petal.WEALD, Petal.QUARRY, Petal.BARROWS, Petal.ORCHARD]
const APRON_HALF_WIDTH: float = 11.0
## An apron runs from this far inside the cliff foot to this far into the cliff.
const APRON_INSIDE: float = 16.0
const APRON_INTO_CLIFF: float = 13.0
const APRON_HEIGHT: float = 28.0
const ROAD_START: float = VILLAGE_RADIUS
const ROAD_HALF_WIDTH: float = 3.5
const ROAD_BLEND: float = 9.0
const VALLEY_WIDTH: float = 44.0
## The High Road: a ring through the meadow, wobbling in and out.
const RING_ROAD_DISTANCE: float = 285.0
const RING_ROAD_WOBBLE: float = 20.0
## Rock spurs at each road's bends: how high, how wide, how far off the road.
const SPUR_HEIGHT: float = 9.0
const SPUR_RADIUS: float = 15.0
const SPUR_OFFSET: float = 26.0

# --- The river -------------------------------------------------------------------
const RIVER_POINTS: Array[Vector2] = [Vector2(172.0, 612.0), Vector2(330.0, 700.0), Vector2(560.0, 870.0), Vector2(770.0, 905.0),
	Vector2(980.0, 860.0), Vector2(1200.0, 760.0), Vector2(1364.0, 690.0)]
const RIVER_HALF_WIDTH: float = 6.5
## The water's surface: 0.4 m over the bed, wadeable everywhere.
const RIVER_WATER: float = 0.4
const RIVER_BANK: float = 2.5
const FLOODPLAIN: float = 30.0
const FLOODPLAIN_RISE: float = 0.045
const BANK_SLOPE: float = 0.24
## Near each ford (where a road crosses the river) the banks ease to this (about 9°), within this reach.
const FORD_BANK_SLOPE: float = 0.16
const FORD_REACH: float = 200.0
## The bank's carve reaches this far, fading out over its last 40 m.
const BANK_REACH: float = FLOODPLAIN + 100.0

# --- Landforms -------------------------------------------------------------------
const TOR_CENTER: Vector2 = Vector2(768.0, 650.0)
const TOR_SIZE: Vector2 = Vector2(150.0, 34.0)
const TOR_HEIGHT: float = 24.0
## The Barrow Hills' mounds, between the Barrow camp and Hollow-King's Barrow (kept off the road).
const BARROWS: Array[Vector2] = [Vector2(262.0, 872.0), Vector2(236.0, 842.0), Vector2(282.0, 905.0), Vector2(214.0, 884.0),
	Vector2(246.0, 925.0), Vector2(300.0, 852.0), Vector2(205.0, 845.0)]
const BARROW_HEIGHT: float = 4.5
const BARROW_RADIUS: float = 9.0
## The mill on the river's north bank, east of the bridge.
const MILL_SITE: Vector2 = Vector2(858.0, 868.0)
const MILL_RADIUS: float = 11.0

# --- Dressing ----------------------------------------------------------------------
## Canopy trees per chunk: forest and meadow (12 GDD §3), never closer than this.
const FOREST_TREES: Vector2i = Vector2i(20, 28)
const MEADOW_TREES: Vector2i = Vector2i(3, 6)
const TREE_SPACING: float = 4.5
## Canopies start above this, so the 4.8 m camera sees under them.
const CANOPY_BASE: float = 5.5
const BOULDERS_PER_CHUNK: Vector2i = Vector2i(4, 8)
const BOULDER_SIZE: Vector2 = Vector2(2.5, 8.0)
## A lantern pole and a Scribe runestone every this many metres of road.
const WAYMARK_SPACING: float = 75.0
const WAYMARK_OFFSET: float = 5.0
const HERO_TREE_COUNT: int = 18

const MEADOW_COLOR: Color = Color(0.47, 0.6, 0.31)
const MEADOW_LIGHT: Color = Color(0.6, 0.66, 0.34)
const FLOODPLAIN_COLOR: Color = Color(0.38, 0.56, 0.3)
const BANK_COLOR: Color = Color(0.46, 0.38, 0.27)
const RIVER_BED_COLOR: Color = Color(0.3, 0.42, 0.44)
const ROAD_COLOR: Color = Color(0.58, 0.48, 0.34)
const COBBLE_COLOR: Color = Color(0.6, 0.57, 0.52)
const VILLAGE_GREEN: Color = Color(0.5, 0.62, 0.33)
const WEALD_COLOR: Color = Color(0.3, 0.44, 0.24)
const BRAMBLE_COLOR: Color = Color(0.32, 0.38, 0.22)
const QUARRY_COLOR: Color = Color(0.68, 0.6, 0.48)
const BARROW_GRASS: Color = Color(0.45, 0.5, 0.36)
const ROCK_COLOR: Color = Color(0.52, 0.5, 0.47)
const CRAG_COLOR: Color = Color(0.46, 0.44, 0.4)
const HEATHER_COLOR: Color = Color(0.5, 0.38, 0.48)
const SKIRT_COLOR: Color = Color(0.26, 0.36, 0.22)
const WATER_COLOR: Color = Color(0.36, 0.6, 0.74, 0.72)
const WATERFALL_COLOR: Color = Color(0.78, 0.92, 1.0, 0.7)
const TRUNK_COLOR: Color = Color(0.36, 0.26, 0.18)
const CANOPY_COLOR: Color = Color(0.3, 0.47, 0.25)
const PINE_COLOR: Color = Color(0.22, 0.38, 0.24)
const BOULDER_COLOR: Color = Color(0.56, 0.55, 0.52)
const POLE_COLOR: Color = Color(0.38, 0.28, 0.18)
const LANTERN_GLOW: Color = Color(1.0, 0.72, 0.3)
const RUNESTONE_COLOR: Color = Color(0.55, 0.56, 0.6)
const PETRIFIED_COLOR: Color = Color(0.62, 0.6, 0.58)

const NOISE: FastNoiseLite = preload("res://src/world/landblock_noise.tres")

## The baked field, when there is one (heights, then colours as 3 bytes each).
var _heights: PackedFloat32Array = PackedFloat32Array()
var _colors: PackedByteArray = PackedByteArray()
var _side: int = 0
## Fixed tables worked out once: each road's far end, the spurs, hero trees, waymarks.
var _road_ends: Array[float] = []
var _spurs: Array[Vector2] = []
var _hero_trees: Array[Dictionary] = []
var _waymarks: Array[Dictionary] = []
## Where the roads cross the river (the Bridge-Warden's span is on the Glade road's).
var _fords: Array[Vector2] = []
## Each road's own fords: the petal roads by index, the High Road under -1.
var _road_fords: Dictionary[int, Array] = {}


func _init(use_baked_field: bool = true) -> void:
	for petal: int in PETAL_BEARINGS.size():
		_road_ends.append(_road_end(petal))
	_spurs = _find_spurs()
	_fords = _find_fords()
	_hero_trees = _place_hero_trees()
	_waymarks = _place_waymarks()
	if use_baked_field and ResourceLoader.exists(FIELD_PATH):
		var field: OakshireValeField = load(FIELD_PATH) as OakshireValeField
		if field != null and field.heights.size() == field.side * field.side:
			_heights = field.heights
			_colors = field.colors
			_side = field.side


func layout_id() -> StringName:
	return LAYOUT_ID


func bounds_min() -> Vector2i:
	return Vector2i.ZERO


func bounds_max() -> Vector2i:
	return Vector2i(CHUNKS - 1, CHUNKS - 1)


## Whether the baked 2 m field is in use (it is once the builder has run).
func has_baked_field() -> bool:
	return _side > 0


# --- Sampling ----------------------------------------------------------------------

func sample_height(world_x: float, world_z: float) -> float:
	if _side == 0:
		return field_height(world_x, world_z)
	var gx: float = clampf(world_x / FIELD_STEP, 0.0, _side - 1.001)
	var gz: float = clampf(world_z / FIELD_STEP, 0.0, _side - 1.001)
	var x0: int = int(gx)
	var z0: int = int(gz)
	var fx: float = gx - x0
	var fz: float = gz - z0
	var row: int = z0 * _side + x0
	var top: float = lerpf(_heights[row], _heights[row + 1], fx)
	var bottom: float = lerpf(_heights[row + _side], _heights[row + _side + 1], fx)
	return lerpf(top, bottom, fz)


func surface_color(world_x: float, world_z: float, height: float) -> Color:
	if _side == 0:
		return field_color(world_x, world_z, height)
	var gx: int = clampi(roundi(world_x / FIELD_STEP), 0, _side - 1)
	var gz: int = clampi(roundi(world_z / FIELD_STEP), 0, _side - 1)
	var at: int = (gz * _side + gx) * 3
	return Color8(_colors[at], _colors[at + 1], _colors[at + 2])


## How deep the river's water is at (x, z) (0 on dry ground): its 0.4 m ford wets your feet.
func water_depth(world_x: float, world_z: float) -> float:
	if river_distance(world_x, world_z) > RIVER_HALF_WIDTH + RIVER_BANK + 1.0:
		return 0.0
	return maxf(0.0, RIVER_WATER - sample_height(world_x, world_z))


# --- The field (pure; what the builder bakes) ---------------------------------------

## The ground's height at (x, z), worked out from the vale's landforms.
func field_height(world_x: float, world_z: float) -> float:
	var offset: Vector2 = Vector2(world_x, world_z) - CENTER
	var r: float = offset.length()
	var theta: float = bearing(offset)
	var d: float = ring_distance(offset)
	var h: float = ring_base(d) + _roll(world_x, world_z, d) + _tor(world_x, world_z) + _bumps(world_x, world_z, d)
	# The petal valleys draw the land down to their road's grade.
	var road: Vector3 = nearest_petal_road(r, theta)
	var valley: float = exp(-pow(road.y / (VALLEY_WIDTH + r * 0.05), 2.0)) * smoothstep(ROAD_START, ROAD_START + 50.0, r) \
		* (1.0 - smoothstep(cliff_radius(theta) - 34.0, cliff_radius(theta) - 8.0, r))
	h = lerpf(h, road.z, valley)
	h = _terrace(h, d)
	# Road beds are smooth ramps through the shelves: the petal roads and the High Road.
	var bed: float = road.z
	var lateral: float = road.y
	var ring_lateral: float = absf(d - ring_road_distance(theta)) / maxf(0.5, superellipse_factor(theta))
	if ring_lateral < lateral:
		lateral = ring_lateral
		bed = road_grade(ring_road_distance(theta))
	h = lerpf(h, bed, _road_weight(lateral))
	h = _clearings(h, world_x, world_z, r)
	h = _aprons(h, world_x, world_z)
	# By the river a road keeps its grade, except where it comes down to its own ford.
	var at: Vector2 = Vector2(world_x, world_z)
	var keep: float = maxf(_road_weight(road.y) * (1.0 - _ford_weight(at, _road_fords.get(int(road.x), []))),
		_road_weight(ring_lateral) * (1.0 - _ford_weight(at, _road_fords.get(-1, []))))
	return _river(h, world_x, world_z, d, keep)


## The ground's colour at (x, z) and height `height`.
func field_color(world_x: float, world_z: float, height: float) -> Color:
	var offset: Vector2 = Vector2(world_x, world_z) - CENTER
	var r: float = offset.length()
	var theta: float = bearing(offset)
	var d: float = ring_distance(offset)
	var patch: float = NOISE.get_noise_2d(world_x * 0.5 + 300.0, world_z * 0.5) * 0.5 + 0.5
	var river: float = river_distance(world_x, world_z)
	if river < RIVER_HALF_WIDTH + 0.6 and height < RIVER_WATER + 0.3:
		return RIVER_BED_COLOR
	if river < RIVER_HALF_WIDTH + RIVER_BANK + 1.0:
		return BANK_COLOR
	if r < VILLAGE_RADIUS + 2.0:
		return COBBLE_COLOR.lerp(VILLAGE_GREEN, smoothstep(14.0, 30.0, r) * (1.0 - smoothstep(44.0, 58.0, r)))
	if road_lateral(world_x, world_z) < ROAD_HALF_WIDTH:
		return ROAD_COLOR.lerp(COBBLE_COLOR, 0.25 * patch)
	if d > CLIFF_TOP_RADIUS + 4.0:
		return SKIRT_COLOR.lerp(HEATHER_COLOR, 0.35 * patch)
	if d > CLIFF_FOOT - 1.0 and height > APRON_HEIGHT + 1.5:
		return ROCK_COLOR.lerp(CRAG_COLOR, patch)
	if _on_riser(height, d) or _on_spur(world_x, world_z):
		return ROCK_COLOR.lerp(CRAG_COLOR, patch * 0.6)
	if river < FLOODPLAIN:
		return FLOODPLAIN_COLOR.lerp(MEADOW_COLOR, patch * 0.5)
	if d < MEADOW_OUTER:
		return MEADOW_COLOR.lerp(MEADOW_LIGHT, patch)
	var degrees: float = rad_to_deg(theta)
	if degrees > 85.0 and degrees < 140.0:
		return QUARRY_COLOR.lerp(ROCK_COLOR, patch * 0.5)
	if degrees > 230.0 and degrees < 285.0:
		return BARROW_GRASS.lerp(MEADOW_COLOR, patch * 0.4)
	if degrees > 12.0 and degrees < 72.0:
		return BRAMBLE_COLOR.lerp(WEALD_COLOR, patch)
	return WEALD_COLOR.lerp(MEADOW_COLOR, patch * 0.35)


## The rounded-square distance from the centre the rings are measured in.
static func ring_distance(offset: Vector2) -> float:
	return pow(pow(absf(offset.x), RING_POWER) + pow(absf(offset.y), RING_POWER), 1.0 / RING_POWER)


## How much a direction stretches the rings: d = r * superellipse_factor (1 on the axes, 0.84 on the diagonals).
static func superellipse_factor(theta: float) -> float:
	return pow(pow(absf(sin(theta)), RING_POWER) + pow(absf(cos(theta)), RING_POWER), 1.0 / RING_POWER)


## Radians clockwise from north (-Z), 0 to TAU.
static func bearing(offset: Vector2) -> float:
	return fposmod(atan2(offset.x, -offset.y), TAU)


## The ring heights before any landform: the saddle, the basin, the meadow, the shelves, the cliff and the skirt.
static func ring_base(d: float) -> float:
	if d < VILLAGE_RADIUS:
		return VILLAGE_HEIGHT
	if d < BASIN_RADIUS:
		return lerpf(VILLAGE_HEIGHT, BASIN_HEIGHT, smoothstep(VILLAGE_RADIUS, BASIN_RADIUS, d))
	if d < MEADOW_OUTER:
		return lerpf(BASIN_HEIGHT, MEADOW_HEIGHT, smoothstep(BASIN_RADIUS, MEADOW_OUTER, d))
	if d < CLIFF_FOOT:
		return lerpf(MEADOW_HEIGHT, TERRACE_TOP, (d - MEADOW_OUTER) / (CLIFF_FOOT - MEADOW_OUTER))
	if d < CLIFF_TOP_RADIUS:
		return lerpf(TERRACE_TOP, CLIFF_TOP_HEIGHT, smoothstep(CLIFF_FOOT, CLIFF_TOP_RADIUS, d))
	return lerpf(CLIFF_TOP_HEIGHT, SKIRT_HEIGHT, clampf((d - CLIFF_TOP_RADIUS) / 150.0, 0.0, 1.0))


## A road's bed at superellipse distance d: down from the village into the
## basin, up through the meadow and the shelves to the apron.
static func road_grade(d: float) -> float:
	if d < ROAD_START:
		return VILLAGE_HEIGHT
	if d < BASIN_RADIUS:
		return lerpf(VILLAGE_HEIGHT, 5.2, smoothstep(ROAD_START, BASIN_RADIUS, d))
	if d < MEADOW_OUTER:
		return lerpf(5.2, 13.0, smoothstep(BASIN_RADIUS, MEADOW_OUTER, d))
	return minf(APRON_HEIGHT, lerpf(13.0, APRON_HEIGHT + 1.0, (d - MEADOW_OUTER) / (CLIFF_FOOT - MEADOW_OUTER)))


## Where the cliff foot is along a bearing (Euclidean metres from the centre).
static func cliff_radius(theta: float) -> float:
	return CLIFF_FOOT / superellipse_factor(theta)


func _roll(world_x: float, world_z: float, d: float) -> float:
	var weight: float = smoothstep(BASIN_RADIUS - 30.0, BASIN_RADIUS + 20.0, d) * (1.0 - smoothstep(MEADOW_OUTER - 30.0, MEADOW_OUTER + 40.0, d))
	var crag: float = smoothstep(CLIFF_TOP_RADIUS, CLIFF_TOP_RADIUS + 30.0, d) * 6.0
	return NOISE.get_noise_2d(world_x * 0.55, world_z * 0.55) * (MEADOW_ROLL * weight + crag)


func _tor(world_x: float, world_z: float) -> float:
	var local: Vector2 = (Vector2(world_x, world_z) - TOR_CENTER) / TOR_SIZE
	return TOR_HEIGHT * exp(-local.length_squared())


## Rock spurs at the roads' bends and the barrow mounds in the west.
func _bumps(world_x: float, world_z: float, d: float) -> float:
	var at: Vector2 = Vector2(world_x, world_z)
	var height: float = 0.0
	for spur: Vector2 in _spurs:
		var gap: float = at.distance_squared_to(spur)
		if gap < 3600.0:
			height += SPUR_HEIGHT * exp(-gap / (SPUR_RADIUS * SPUR_RADIUS))
	if d > 300.0 and d < 590.0 and world_x < 420.0:
		for mound: Vector2 in BARROWS:
			var gap: float = at.distance_squared_to(mound)
			if gap < 900.0:
				height += BARROW_HEIGHT * (1.0 - smoothstep(0.0, BARROW_RADIUS * BARROW_RADIUS, gap)) * smoothstep(9.0, 16.0, road_lateral(world_x, world_z))
	return height


func _terrace(h: float, d: float) -> float:
	if d < MEADOW_OUTER - 10.0 or d > CLIFF_FOOT or h <= MEADOW_HEIGHT or h >= TERRACE_TOP:
		return h
	var step: float = (TERRACE_TOP - MEADOW_HEIGHT) / TERRACE_COUNT
	var t: float = (h - MEADOW_HEIGHT) / step
	var shelf: float = floorf(t)
	var riser: float = smoothstep(1.0 - TERRACE_RISER, 1.0, t - shelf)
	return MEADOW_HEIGHT + (shelf + riser) * step


func _on_riser(height: float, d: float) -> bool:
	if d < MEADOW_OUTER or d > CLIFF_FOOT or height <= MEADOW_HEIGHT + 0.3 or height >= TERRACE_TOP - 0.3:
		return false
	var step: float = (TERRACE_TOP - MEADOW_HEIGHT) / TERRACE_COUNT
	var within: float = fposmod(height - MEADOW_HEIGHT, step)
	return within > 0.6 and within < step - 0.6


func _on_spur(world_x: float, world_z: float) -> bool:
	for spur: Vector2 in _spurs:
		if Vector2(world_x, world_z).distance_squared_to(spur) < 100.0:
			return true
	return false


## Flat ground for the village, the petal camps and the mill.
func _clearings(h: float, world_x: float, world_z: float, r: float) -> float:
	var flat: float = lerpf(h, VILLAGE_HEIGHT, 1.0 - smoothstep(VILLAGE_RADIUS - 6.0, VILLAGE_RADIUS + 3.0, r))
	var at: Vector2 = Vector2(world_x, world_z)
	flat = lerpf(flat, road_grade(CAMP_DISTANCE), _camp_weight(at))
	var mill_gap: float = at.distance_to(MILL_SITE)
	if mill_gap < MILL_RADIUS + 8.0:
		flat = lerpf(flat, 1.2, 1.0 - smoothstep(MILL_RADIUS, MILL_RADIUS + 7.0, mill_gap))
	return flat


## How far inside a petal's camp clearing a spot is: 1 inside, 0 beyond its 10 m edge.
func _camp_weight(at: Vector2) -> float:
	var weight: float = 0.0
	for petal: int in PETAL_BEARINGS.size():
		var radius: float = GLADE_RADIUS if petal == Petal.GLADE else CAMP_RADIUS
		weight = maxf(weight, 1.0 - smoothstep(radius, radius + 10.0, at.distance_to(camp_center_2d(petal))))
	return weight


## Each portal apron: a flat floor running into the cliff, its walls the cliff itself.
func _aprons(h: float, world_x: float, world_z: float) -> float:
	for petal: int in APRON_PETALS:
		var local: Vector2 = apron_local(petal, Vector2(world_x, world_z))
		if local.x < -APRON_INSIDE - 8.0 or local.x > APRON_INTO_CLIFF + 1.0 or absf(local.y) > APRON_HALF_WIDTH + 6.0:
			continue
		var inside: float = (1.0 - smoothstep(APRON_HALF_WIDTH - 1.0, APRON_HALF_WIDTH + 1.5, absf(local.y))) \
			* smoothstep(-APRON_INSIDE - 8.0, -APRON_INSIDE, local.x) * (1.0 - smoothstep(APRON_INTO_CLIFF - 1.5, APRON_INTO_CLIFF, local.x))
		h = lerpf(h, APRON_HEIGHT, inside)
	return h


## How much of a road bed a spot this far from the road's middle is: 1 on it, 0 past its blend.
static func _road_weight(lateral: float) -> float:
	return 1.0 - smoothstep(ROAD_HALF_WIDTH + 0.5, ROAD_HALF_WIDTH + ROAD_BLEND, lateral)


## How near one of these fords a spot is, 1 within half a ford's reach to 0 beyond it.
func _ford_weight(at: Vector2, fords: Array) -> float:
	var weight: float = 0.0
	for ford: Vector2 in fords:
		weight = maxf(weight, 1.0 - smoothstep(FORD_REACH * 0.5, FORD_REACH, at.distance_to(ford)))
	return weight


## An apron's own frame: x along its petal's bearing from the cliff foot (into the cliff positive), y sideways.
func apron_local(petal: int, at: Vector2) -> Vector2:
	var theta: float = deg_to_rad(PETAL_BEARINGS[petal])
	var outward: Vector2 = Vector2(sin(theta), -cos(theta))
	var foot: Vector2 = CENTER + outward * cliff_radius(theta)
	var rel: Vector2 = at - foot
	return Vector2(rel.dot(outward), rel.dot(Vector2(-outward.y, outward.x)))


## The river's channel, floodplain and banks cut into the land, easing near the
## fords. A camp keeps its floor, and a road its grade as much as `keep_road` says.
func _river(h: float, world_x: float, world_z: float, d: float, keep_road: float = 0.0) -> float:
	if world_x < RIVER_POINTS[0].x - 30.0 or world_x > RIVER_POINTS[RIVER_POINTS.size() - 1].x + 30.0:
		return h
	var gap: float = river_distance(world_x, world_z)
	if gap > BANK_REACH:
		return h
	var near_ford: float = _ford_weight(Vector2(world_x, world_z), _fords)
	var bed: float
	if gap <= RIVER_HALF_WIDTH:
		bed = 0.0
	elif gap <= RIVER_HALF_WIDTH + RIVER_BANK:
		bed = lerpf(0.0, 0.62, (gap - RIVER_HALF_WIDTH) / RIVER_BANK)
	elif gap <= FLOODPLAIN:
		bed = 0.62 + (gap - RIVER_HALF_WIDTH - RIVER_BANK) * FLOODPLAIN_RISE
	else:
		# Near a ford the banks ease right down, so the road comes down to the water gently.
		var slope: float = lerpf(BANK_SLOPE, FORD_BANK_SLOPE, near_ford)
		bed = 0.62 + (FLOODPLAIN - RIVER_HALF_WIDTH - RIVER_BANK) * FLOODPLAIN_RISE + (gap - FLOODPLAIN) * slope
	# The channel stops at the escarpment (a waterfall in the west, a cave in the
	# east), and the banks' carve fades out over its last 40 m, so it never leaves a step.
	var carve: float = (1.0 - smoothstep(CLIFF_FOOT - 10.0, CLIFF_FOOT - 2.0, d)) * (1.0 - smoothstep(BANK_REACH - 40.0, BANK_REACH, gap)) \
		* (1.0 - maxf(keep_road, _camp_weight(Vector2(world_x, world_z))))
	return lerpf(h, minf(h, bed), carve)


# --- Roads and the river ---------------------------------------------------------------

## A petal road's bearing at radius r (radians): its bearing plus one S of sway.
func road_bearing(petal: int, r: float) -> float:
	var span: float = _road_ends[petal] - ROAD_START
	var t: float = clampf((r - ROAD_START) / span, 0.0, 1.0)
	return deg_to_rad(PETAL_BEARINGS[petal]) + PETAL_SWAY[petal] * sin(TAU * t)


## The road's point at radius r, on the ground.
func road_point(petal: int, r: float) -> Vector3:
	var theta: float = road_bearing(petal, r)
	var at: Vector2 = CENTER + Vector2(sin(theta), -cos(theta)) * r
	return Vector3(at.x, sample_height(at.x, at.y), at.y)


func road_end(petal: int) -> float:
	return _road_ends[petal]


## The nearest petal road to a point at (r, theta): (petal, sideways distance, its bed's height there).
func nearest_petal_road(r: float, theta: float) -> Vector3:
	var best: Vector3 = Vector3(-1.0, INF, VILLAGE_HEIGHT)
	for petal: int in PETAL_BEARINGS.size():
		var end: float = _road_ends[petal]
		var along: float = clampf(r, ROAD_START, end)
		var road_theta: float = road_bearing(petal, along)
		var lateral: float
		if r < ROAD_START or r > end:
			var tip: Vector2 = Vector2(sin(road_theta), -cos(road_theta)) * along
			lateral = tip.distance_to(Vector2(sin(theta), -cos(theta)) * r)
		else:
			var span: float = end - ROAD_START
			var slope: float = r * PETAL_SWAY[petal] * TAU / span * cos(TAU * (r - ROAD_START) / span)
			lateral = r * absf(angle_difference(theta, road_theta)) / sqrt(1.0 + slope * slope)
		if lateral < best.y:
			best = Vector3(petal, lateral, road_grade(along * superellipse_factor(road_theta)))
	return best


## The High Road's distance (superellipse) along a bearing.
static func ring_road_distance(theta: float) -> float:
	return RING_ROAD_DISTANCE + RING_ROAD_WOBBLE * sin(3.0 * theta + 0.7)


## The High Road's middle at a bearing, on the ground.
func ring_road_point(theta: float) -> Vector3:
	var at: Vector2 = _ring_point_2d(theta)
	return Vector3(at.x, sample_height(at.x, at.y), at.y)


## Metres to the nearest road's middle (a petal road or the High Road).
func road_lateral(world_x: float, world_z: float) -> float:
	var offset: Vector2 = Vector2(world_x, world_z) - CENTER
	var theta: float = bearing(offset)
	var petal: float = nearest_petal_road(offset.length(), theta).y
	var ring: float = absf(ring_distance(offset) - ring_road_distance(theta)) / maxf(0.5, superellipse_factor(theta))
	return minf(petal, ring)


## The river's middle at x, and its slope dz/dx: a Hermite curve through
## RIVER_POINTS in x (its slope is continuous, so distances to it are too).
static func river_at(world_x: float) -> Vector2:
	var points: Array[Vector2] = RIVER_POINTS
	var last: int = points.size() - 1
	var x: float = clampf(world_x, points[0].x, points[last].x)
	var segment: int = 0
	while segment < last - 1 and x > points[segment + 1].x:
		segment += 1
	var p1: Vector2 = points[segment]
	var p2: Vector2 = points[segment + 1]
	var span: float = p2.x - p1.x
	var m1: float = _river_tangent(segment)
	var m2: float = _river_tangent(segment + 1)
	var t: float = (x - p1.x) / span
	var t2: float = t * t
	var t3: float = t2 * t
	var z: float = (2.0 * t3 - 3.0 * t2 + 1.0) * p1.y + (t3 - 2.0 * t2 + t) * span * m1 + (-2.0 * t3 + 3.0 * t2) * p2.y + (t3 - t2) * span * m2
	var dz: float = ((6.0 * t2 - 6.0 * t) * p1.y + (3.0 * t2 - 4.0 * t + 1.0) * span * m1 + (-6.0 * t2 + 6.0 * t) * p2.y + (3.0 * t2 - 2.0 * t) * span * m2) / span
	return Vector2(z, dz)


## The curve's slope at a control point (from its neighbours, in x).
static func _river_tangent(index: int) -> float:
	var points: Array[Vector2] = RIVER_POINTS
	var before: Vector2 = points[maxi(index - 1, 0)]
	var after: Vector2 = points[mini(index + 1, points.size() - 1)]
	return (after.y - before.y) / (after.x - before.x)


## Metres from (x, z) to the river's middle: the point projected onto the curve
## (a few steps along its tangent), clamped to its ends.
static func river_distance(world_x: float, world_z: float) -> float:
	var first: float = RIVER_POINTS[0].x
	var end: float = RIVER_POINTS[RIVER_POINTS.size() - 1].x
	var foot: float = clampf(world_x, first, end)
	for step: int in 3:
		var middle: Vector2 = river_at(foot)
		foot = clampf(foot + ((world_x - foot) + middle.y * (world_z - middle.x)) / (1.0 + middle.y * middle.y), first, end)
	return Vector2(world_x - foot, world_z - river_at(foot).x).length()


# --- Places ------------------------------------------------------------------------------

func petal_count() -> int:
	return PETAL_BEARINGS.size()


## The petal camp's middle, beside its road (Wayfarer's Glade straddles its road's end).
func camp_center_2d(petal: int) -> Vector2:
	var theta0: float = deg_to_rad(PETAL_BEARINGS[petal])
	var r: float = CAMP_DISTANCE / superellipse_factor(theta0)
	if petal == Petal.GLADE:
		r = _road_ends[petal]
	var span: float = _road_ends[petal] - ROAD_START
	var t: float = clampf((r - ROAD_START) / span, 0.0, 1.0)
	var theta: float = theta0 + PETAL_SWAY[petal] * sin(TAU * t)
	var at: Vector2 = CENTER + Vector2(sin(theta), -cos(theta)) * r
	if petal == Petal.GLADE:
		return at
	var side: Vector2 = Vector2(cos(theta), sin(theta))
	return at + side * CAMP_OFFSET * (1.0 if PETAL_SWAY[petal] > 0.0 else -1.0)


func camp_center(petal: int) -> Vector3:
	var at: Vector2 = camp_center_2d(petal)
	return Vector3(at.x, sample_height(at.x, at.y), at.y)


## Where a petal's portal stands at the back of its apron, and the way out of it (toward the vale).
func apron_portal(petal: int) -> Transform3D:
	var theta: float = deg_to_rad(PETAL_BEARINGS[petal])
	var outward: Vector2 = Vector2(sin(theta), -cos(theta))
	var at: Vector2 = CENTER + outward * (cliff_radius(theta) + APRON_INTO_CLIFF - 4.0)
	var facing: Vector3 = Vector3(-outward.x, 0.0, -outward.y)
	return Transform3D(Basis.looking_at(facing, Vector3.UP), Vector3(at.x, APRON_HEIGHT, at.y))


## The Bridge-Warden's span: where the Glade road crosses the river, and the road's direction there.
func bridge_transform() -> Transform3D:
	var best_r: float = ROAD_START
	var best_gap: float = INF
	var r: float = ROAD_START
	while r < 260.0:
		var at: Vector3 = road_point(Petal.GLADE, r)
		var gap: float = river_distance(at.x, at.z)
		if gap < best_gap:
			best_gap = gap
			best_r = r
		r += 0.5
	var a: Vector3 = road_point(Petal.GLADE, best_r - 2.0)
	var b: Vector3 = road_point(Petal.GLADE, best_r + 2.0)
	var middle: Vector3 = road_point(Petal.GLADE, best_r)
	var along: Vector3 = Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	return Transform3D(Basis.looking_at(along, Vector3.UP), Vector3(middle.x, RIVER_WATER, middle.z))


func mill_position() -> Vector3:
	return Vector3(MILL_SITE.x, sample_height(MILL_SITE.x, MILL_SITE.y), MILL_SITE.y)


## The 18 hero landmark trees: {"position", "radius" (trunk), "height", "crown", "petrified"}.
func hero_trees() -> Array[Dictionary]:
	return _hero_trees


## Every lantern pole and runestone: {"position", "lantern": bool, "yaw"}.
func waymarks() -> Array[Dictionary]:
	return _waymarks


## Whether a spot is kept clear of trees and boulders (a road, the river, a clearing, an apron or the village).
func is_kept_clear(world_x: float, world_z: float, margin: float) -> bool:
	var at: Vector2 = Vector2(world_x, world_z)
	var offset: Vector2 = at - CENTER
	if offset.length() < VILLAGE_RADIUS + 6.0 + margin:
		return true
	if road_lateral(world_x, world_z) < ROAD_HALF_WIDTH + 2.5 + margin:
		return true
	if world_x > RIVER_POINTS[0].x - 10.0 and world_x < RIVER_POINTS[RIVER_POINTS.size() - 1].x + 10.0 \
			and river_distance(world_x, world_z) < RIVER_HALF_WIDTH + RIVER_BANK + 3.0 + margin:
		return true
	for petal: int in PETAL_BEARINGS.size():
		var radius: float = GLADE_RADIUS if petal == Petal.GLADE else CAMP_RADIUS
		if at.distance_to(camp_center_2d(petal)) < radius + margin:
			return true
	for petal: int in APRON_PETALS:
		var local: Vector2 = apron_local(petal, at)
		if local.x > -APRON_INSIDE - 10.0 - margin and local.x < APRON_INTO_CLIFF and absf(local.y) < APRON_HALF_WIDTH + 2.0 + margin:
			return true
	return at.distance_to(MILL_SITE) < MILL_RADIUS + 4.0 + margin


## How wooded a spot is, 0 (meadow) to 1 (forest): the weald, the crag tops and the skirt are forest.
func forest_weight(world_x: float, world_z: float) -> float:
	var offset: Vector2 = Vector2(world_x, world_z) - CENTER
	var d: float = ring_distance(offset)
	if d < MEADOW_OUTER - 40.0:
		return 0.0
	var degrees: float = rad_to_deg(bearing(offset))
	var weight: float = smoothstep(MEADOW_OUTER - 40.0, MEADOW_OUTER + 30.0, d)
	# The quarry's shelves are bare stone; the barrow hills are open downs.
	if degrees > 88.0 and degrees < 138.0 and d < CLIFF_FOOT:
		weight *= 0.25
	if degrees > 232.0 and degrees < 282.0 and d < CLIFF_FOOT:
		weight *= 0.45
	return weight


# --- Streaming ---------------------------------------------------------------------------

## The whole 12 x 12 grid is walked except the skirt, which is cliff and forest.
func has_collision(chunk: Vector2i) -> bool:
	return chunk.x > 0 and chunk.y > 0 and chunk.x < CHUNKS - 1 and chunk.y < CHUNKS - 1


## No navigation mesh yet: baking whole 128 m chunks at the map's 0.25 m cells
## starved the streaming threads. Creatures and companions walk straight across
## the open vale (NavSteering's fallback); road-band navigation is to come.
func has_navigation(_chunk: Vector2i) -> bool:
	return false


## Boulders, tree trunks, runestones and hero trunks block bodies, cameras and shots (LoS cover).
func solid_pieces(chunk: Vector2i) -> Array[Dictionary]:
	return _chunk_props(chunk)["solids"]


func landblock_path(chunk: Vector2i) -> String:
	var path: String = "%slandblock_%s.tscn" % [LANDBLOCK_FOLDER, WorldGridConfig.chunk_key(chunk)]
	return path if ResourceLoader.exists(path) else ""


func hlod_path(chunk: Vector2i) -> String:
	var path: String = "%shlod_%s.res" % [LANDBLOCK_FOLDER, WorldGridConfig.chunk_key(chunk)]
	return path if ResourceLoader.exists(path) else ""


## The village's four chunks keep their state.
func is_persistent(chunk: Vector2i) -> bool:
	return chunk.x >= 5 and chunk.x <= 6 and chunk.y >= 5 and chunk.y <= 6


# --- Clutter (Layer 2) --------------------------------------------------------------------

enum Prop { TRUNK, CANOPY, PINE, BOULDER, POLE, LANTERN, RUNESTONE, REED, FLOWERS, BRAMBLE }

const PROP_NAMES: Array[String] = ["Trunks", "Canopies", "Pines", "Boulders", "LanternPoles", "Lanterns", "Runestones", "Reeds", "Flowers", "Brambles"]
const PROP_COLORS: Array[Color] = [TRUNK_COLOR, CANOPY_COLOR, PINE_COLOR, BOULDER_COLOR, POLE_COLOR, LANTERN_GLOW, RUNESTONE_COLOR,
	Color(0.55, 0.6, 0.36), Color(0.92, 0.82, 0.5), Color(0.34, 0.36, 0.2)]
const COLOR_JITTER: float = 0.1


func build_clutter_data(chunk: Vector2i) -> Dictionary:
	var props: Dictionary = _chunk_props(chunk)
	var packed: Dictionary = {}
	for kind: int in Prop.size():
		packed[kind] = LandblockClutter._pack(props[kind])
	packed["trees"] = props["trees"]
	return packed


func make_clutter_node(chunk: Vector2i, data: Dictionary) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Clutter_%s" % WorldGridConfig.chunk_key(chunk)
	for kind: int in Prop.size():
		var entry: Dictionary = data[kind]
		var count: int = entry["count"]
		if count == 0:
			continue
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = _prop_mesh(kind)
		multimesh.instance_count = count
		multimesh.buffer = entry["buffer"]
		var instances: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instances.name = PROP_NAMES[kind]
		instances.multimesh = multimesh
		instances.material_override = StorybookMaterial.glowing(LANTERN_GLOW, 2.4) if kind == Prop.LANTERN else LandblockTerrain.material()
		if kind == Prop.REED or kind == Prop.FLOWERS or kind == Prop.BRAMBLE or kind == Prop.LANTERN:
			instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(instances)
	return root


## How many canopy trees a chunk's clutter holds (tests and telemetry).
static func tree_count(data: Dictionary) -> int:
	return int(data.get("trees", 0))


## Everything a chunk grows, from its own seed: {Prop: {"transforms", "colors"}, "solids", "trees", "boulders"}.
func _chunk_props(chunk: Vector2i) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = LandblockClutter.chunk_seed(chunk) ^ 0x0A75
	var placed: Dictionary = {}
	for kind: int in Prop.size():
		var transforms: Array[Transform3D] = []
		placed[kind] = {"transforms": transforms, "colors": PackedColorArray()}
	var solids: Array[Dictionary] = []
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var size: float = WorldGridConfig.CHUNK_SIZE
	# Trees: forest or meadow numbers by how wooded the chunk is, never on a road, the river or a cliff.
	var wooded: float = 0.0
	for gz: int in 5:
		for gx: int in 5:
			wooded += forest_weight(origin.x + (gx + 0.5) * size / 5.0, origin.z + (gz + 0.5) * size / 5.0)
	# A chunk that's partly forest is mostly forest where it's wooded, so it leans to the forest's numbers.
	wooded = pow(wooded / 25.0, 0.45)
	var wanted: int = roundi(lerpf(rng.randi_range(MEADOW_TREES.x, MEADOW_TREES.y), rng.randi_range(FOREST_TREES.x, FOREST_TREES.y), wooded))
	var trunks: Array[Vector2] = []
	var tries: int = 0
	while trunks.size() < wanted and tries < wanted * 24 + 60:
		tries += 1
		var x: float = origin.x + rng.randf() * size
		var z: float = origin.z + rng.randf() * size
		var d: float = ring_distance(Vector2(x, z) - CENTER)
		if rng.randf() > maxf(forest_weight(x, z), 0.14) or (d > CLIFF_FOOT - 4.0 and d < CLIFF_TOP_RADIUS + 4.0):
			continue
		if is_kept_clear(x, z, 1.0) or _crowded(trunks, Vector2(x, z), TREE_SPACING):
			continue
		var y: float = sample_height(x, z)
		if _on_riser(y, d) or _on_spur(x, z):
			continue
		trunks.append(Vector2(x, z))
		var pine: bool = d > CLIFF_TOP_RADIUS or rng.randf() < 0.25 * forest_weight(x, z)
		var height: float = rng.randf_range(6.8, 9.0)
		var girth: float = rng.randf_range(0.85, 1.25)
		_add_prop(placed, Prop.TRUNK, Transform3D(Basis.IDENTITY.scaled(Vector3(girth, height / 6.0, girth)), Vector3(x, y + height * 0.5 - 0.3, z)), rng)
		if pine:
			var tall: float = rng.randf_range(6.0, 9.0)
			_add_prop(placed, Prop.PINE, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(tall * 0.42, tall, tall * 0.42)),
				Vector3(x, y + CANOPY_BASE + tall * 0.5, z)), rng)
		else:
			var crown: float = rng.randf_range(2.6, 4.0)
			_add_prop(placed, Prop.CANOPY, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(crown * 1.15, crown * 0.8, crown)),
				Vector3(x, y + height + crown * 0.35, z)), rng)
		solids.append({"cylinder": Vector2(0.45 * girth, height), "transform": Transform3D(Basis.IDENTITY, Vector3(x, y + height * 0.5, z))})
	# Granite slabs: 4 to 8 a chunk, 2.5 to 8 m, hard cover against missiles.
	var boulders: int = rng.randi_range(BOULDERS_PER_CHUNK.x, BOULDERS_PER_CHUNK.y)
	var placed_boulders: int = 0
	tries = 0
	while placed_boulders < boulders and tries < boulders * 20:
		tries += 1
		var x: float = origin.x + rng.randf() * size
		var z: float = origin.z + rng.randf() * size
		var d: float = ring_distance(Vector2(x, z) - CENTER)
		if is_kept_clear(x, z, 3.0) or _crowded(trunks, Vector2(x, z), 5.0) or (d > CLIFF_FOOT - 6.0 and d < CLIFF_TOP_RADIUS + 4.0):
			continue
		var slab: float = rng.randf_range(BOULDER_SIZE.x, BOULDER_SIZE.y)
		var y: float = sample_height(x, z)
		var yaw: float = rng.randf() * TAU
		_add_prop(placed, Prop.BOULDER, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(slab / 1.2, slab * 0.55, slab * 0.8 / 1.2) * Vector3(1.0, 1.0, 1.2)),
			Vector3(x, y + slab * 0.12, z)), rng)
		solids.append({"cylinder": Vector2(slab * 0.42, slab * 0.6), "transform": Transform3D(Basis.IDENTITY, Vector3(x, y + slab * 0.2, z))})
		placed_boulders += 1
	# Waymarks along the roads.
	for mark: Dictionary in _waymarks:
		var at: Vector3 = mark["position"]
		if WorldGridConfig.world_to_chunk(at) != chunk:
			continue
		var yaw: float = mark["yaw"]
		if mark["lantern"]:
			_add_prop(placed, Prop.POLE, Transform3D(Basis(Vector3.UP, yaw), at + Vector3(0.0, 1.6, 0.0)), rng)
			_add_prop(placed, Prop.LANTERN, Transform3D(Basis(Vector3.UP, yaw), at + Vector3(0.0, 3.25, 0.0)), rng)
		else:
			_add_prop(placed, Prop.RUNESTONE, Transform3D(Basis(Vector3.UP, yaw), at + Vector3(0.0, 0.7, 0.0)), rng)
			solids.append({"box": Vector3(0.7, 1.5, 0.35), "transform": Transform3D(Basis(Vector3.UP, yaw), at + Vector3(0.0, 0.7, 0.0)), "low": true})
	# Hero trunks (the trees themselves are far landmarks, Layer 1).
	for tree: Dictionary in _hero_trees:
		var root_at: Vector3 = tree["position"]
		if WorldGridConfig.world_to_chunk(root_at) == chunk:
			var trunk_height: float = float(tree["height"]) * 0.6
			solids.append({"cylinder": Vector2(tree["radius"], trunk_height), "transform": Transform3D(Basis.IDENTITY, root_at + Vector3(0.0, trunk_height * 0.5, 0.0))})
	_add_ground_dressing(chunk, placed, rng)
	placed["solids"] = solids
	placed["trees"] = trunks.size()
	placed["boulders"] = placed_boulders
	return placed


## Reeds on the river's banks, flowers in the meadow, brambles in the weald (looks only).
func _add_ground_dressing(chunk: Vector2i, placed: Dictionary, rng: RandomNumberGenerator) -> void:
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var size: float = WorldGridConfig.CHUNK_SIZE
	for attempt: int in 220:
		var x: float = origin.x + rng.randf() * size
		var z: float = origin.z + rng.randf() * size
		var offset: Vector2 = Vector2(x, z) - CENTER
		var d: float = ring_distance(offset)
		var river: float = river_distance(x, z) if x > RIVER_POINTS[0].x and x < RIVER_POINTS[RIVER_POINTS.size() - 1].x else INF
		var y: float = sample_height(x, z)
		if river > RIVER_HALF_WIDTH + 1.0 and river < RIVER_HALF_WIDTH + 7.0:
			for blade: int in 4:
				var lean: Basis = Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(), rng.randf_range(0.05, 0.3))
				_add_prop(placed, Prop.REED, Transform3D(lean, Vector3(x + rng.randf_range(-0.4, 0.4), y + 0.55, z + rng.randf_range(-0.4, 0.4))), rng)
			continue
		if is_kept_clear(x, z, 0.0):
			continue
		var degrees: float = rad_to_deg(bearing(offset))
		if d > BASIN_RADIUS and d < MEADOW_OUTER and attempt % 3 == 0:
			var scale: float = rng.randf_range(0.6, 1.2)
			_add_prop(placed, Prop.FLOWERS, Transform3D(Basis.IDENTITY.scaled(Vector3(scale, scale * 0.5, scale)), Vector3(x, y + 0.08, z)), rng)
		elif d > MEADOW_OUTER and d < CLIFF_FOOT - 6.0 and degrees > 12.0 and degrees < 72.0 and attempt % 2 == 0:
			var scale: float = rng.randf_range(0.8, 1.6)
			_add_prop(placed, Prop.BRAMBLE, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * 1.3, scale * 0.7, scale)), Vector3(x, y + 0.2, z)), rng)


static func _crowded(points: Array[Vector2], at: Vector2, spacing: float) -> bool:
	var limit: float = spacing * spacing
	for other: Vector2 in points:
		if other.distance_squared_to(at) < limit:
			return true
	return false


func _add_prop(placed: Dictionary, kind: int, where: Transform3D, rng: RandomNumberGenerator) -> void:
	var entry: Dictionary = placed[kind]
	(entry["transforms"] as Array[Transform3D]).append(where)
	var shade: float = rng.randf_range(-COLOR_JITTER, COLOR_JITTER)
	var colors: PackedColorArray = entry["colors"]
	colors.append(PROP_COLORS[kind].lightened(shade) if shade > 0.0 else PROP_COLORS[kind].darkened(-shade))
	entry["colors"] = colors


static func _prop_mesh(kind: int) -> Mesh:
	match kind:
		Prop.TRUNK:
			var trunk: CylinderMesh = CylinderMesh.new()
			trunk.top_radius = 0.32
			trunk.bottom_radius = 0.48
			trunk.height = 6.0
			trunk.radial_segments = 6
			trunk.rings = 1
			return trunk
		Prop.CANOPY:
			var canopy: SphereMesh = SphereMesh.new()
			canopy.radius = 1.0
			canopy.height = 1.6
			canopy.radial_segments = 8
			canopy.rings = 5
			return canopy
		Prop.PINE:
			var pine: CylinderMesh = CylinderMesh.new()
			pine.top_radius = 0.0
			pine.bottom_radius = 1.0
			pine.height = 1.0
			pine.radial_segments = 7
			pine.rings = 1
			return pine
		Prop.BOULDER:
			var slab: SphereMesh = SphereMesh.new()
			slab.radius = 0.6
			slab.height = 1.0
			slab.radial_segments = 6
			slab.rings = 3
			return slab
		Prop.POLE:
			var pole: BoxMesh = BoxMesh.new()
			pole.size = Vector3(0.18, 3.2, 0.18)
			return pole
		Prop.LANTERN:
			var lantern: BoxMesh = BoxMesh.new()
			lantern.size = Vector3(0.42, 0.55, 0.42)
			return lantern
		Prop.RUNESTONE:
			var stone: BoxMesh = BoxMesh.new()
			stone.size = Vector3(0.7, 1.5, 0.35)
			return stone
		Prop.REED:
			var reed: CylinderMesh = CylinderMesh.new()
			reed.top_radius = 0.01
			reed.bottom_radius = 0.035
			reed.height = 1.1
			reed.radial_segments = 4
			reed.rings = 1
			return reed
		Prop.FLOWERS:
			var tuft: SphereMesh = SphereMesh.new()
			tuft.radius = 0.3
			tuft.height = 0.45
			tuft.radial_segments = 6
			tuft.rings = 3
			return tuft
	var bramble: SphereMesh = SphereMesh.new()
	bramble.radius = 0.6
	bramble.height = 0.9
	bramble.radial_segments = 6
	bramble.rings = 3
	return bramble


# --- Layer 1 extras: hero trees, the river, the waterfall and the cave ---------------------

## Occluders along the escarpment where it crosses a chunk, and along the Scribe's Tor.
func make_occluders(chunk: Vector2i) -> OccluderInstance3D:
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var size: float = WorldGridConfig.CHUNK_SIZE
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var steps: int = 360
	for step: int in steps:
		var a_theta: float = TAU * step / steps
		var b_theta: float = TAU * (step + 1) / steps
		var occluder_d: float = CLIFF_FOOT + 9.0
		var a: Vector2 = CENTER + Vector2(sin(a_theta), -cos(a_theta)) * occluder_d / superellipse_factor(a_theta)
		var b: Vector2 = CENTER + Vector2(sin(b_theta), -cos(b_theta)) * occluder_d / superellipse_factor(b_theta)
		var middle: Vector2 = (a + b) * 0.5
		if WorldGridConfig.world_to_chunk(Vector3(middle.x, 0.0, middle.y)) != chunk or _near_apron(middle):
			continue
		var first: int = vertices.size()
		vertices.append_array(PackedVector3Array([Vector3(a.x, TERRACE_TOP + 4.0, a.y), Vector3(b.x, TERRACE_TOP + 4.0, b.y),
			Vector3(b.x, CLIFF_TOP_HEIGHT - 6.0, b.y), Vector3(a.x, CLIFF_TOP_HEIGHT - 6.0, a.y)]))
		indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	if Rect2(origin.x, origin.z, size, size).has_point(TOR_CENTER):
		var first: int = vertices.size()
		var y: float = BASIN_HEIGHT + TOR_HEIGHT * 0.7
		vertices.append_array(PackedVector3Array([Vector3(TOR_CENTER.x - 90.0, 8.0, TOR_CENTER.y), Vector3(TOR_CENTER.x + 90.0, 8.0, TOR_CENTER.y),
			Vector3(TOR_CENTER.x + 90.0, y, TOR_CENTER.y), Vector3(TOR_CENTER.x - 90.0, y, TOR_CENTER.y)]))
		indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	if vertices.is_empty():
		return null
	var shape: ArrayOccluder3D = ArrayOccluder3D.new()
	shape.set_arrays(vertices, indices)
	var occluder: OccluderInstance3D = OccluderInstance3D.new()
	occluder.name = "Occluders"
	occluder.occluder = shape
	return occluder


func _near_apron(at: Vector2) -> bool:
	for petal: int in APRON_PETALS:
		var local: Vector2 = apron_local(petal, at)
		if absf(local.y) < APRON_HALF_WIDTH + 6.0 and absf(local.x) < 30.0:
			return true
	return false


## The chunk's hero trees (seen three chunks away), its stretch of river water, and the waterfall or the cave.
func make_horizon_landmark(chunk: Vector2i) -> Node3D:
	var holder: Node3D = Node3D.new()
	holder.name = "OakshireLandmarks"
	var merge: LandblockTerrain.MeshMerge = LandblockTerrain.MeshMerge.new()
	for tree: Dictionary in _hero_trees:
		var at: Vector3 = tree["position"]
		if WorldGridConfig.world_to_chunk(at) == chunk:
			add_hero_tree(merge, tree)
	if not merge.is_empty():
		var trees: MeshInstance3D = MeshInstance3D.new()
		trees.name = "HeroTrees"
		trees.mesh = merge.commit()
		trees.material_override = LandblockTerrain.material()
		holder.add_child(trees)
	var water: MeshInstance3D = _water_for(chunk)
	if water != null:
		holder.add_child(water)
	var falls: Node3D = _river_ends_for(chunk)
	if falls != null:
		holder.add_child(falls)
	if holder.get_child_count() == 0:
		holder.free()
		return null
	return holder


## One hero tree into a merge: a broad flared trunk, roots and a layered crown (a petrified oak is bare grey stone).
static func add_hero_tree(merge: LandblockTerrain.MeshMerge, tree: Dictionary) -> void:
	var at: Vector3 = tree["position"]
	var radius: float = tree["radius"]
	var height: float = tree["height"]
	var petrified: bool = tree["petrified"]
	var bark: Color = PETRIFIED_COLOR if petrified else TRUNK_COLOR.darkened(0.1)
	var trunk_height: float = height * 0.62
	merge.add_cylinder(at + Vector3(0.0, trunk_height * 0.5 - 0.5, 0.0), radius * 0.7, radius * 1.25, trunk_height, bark, 12)
	for root: int in 5:
		var angle: float = TAU * root / 5.0 + 0.3
		merge.add_box(at + Vector3(cos(angle) * radius * 1.3, 0.4, sin(angle) * radius * 1.3), Vector3(radius * 0.9, 1.2, radius * 0.6), bark)
	if petrified:
		for limb: int in 4:
			var angle: float = TAU * limb / 4.0 + 0.8
			merge.add_box(at + Vector3(cos(angle) * radius * 1.6, trunk_height * 0.9, sin(angle) * radius * 1.6), Vector3(radius * 2.4, radius * 0.6, radius * 0.6), bark)
		return
	var crown: float = tree["crown"]
	merge.add_cylinder(at + Vector3(0.0, trunk_height + crown * 0.25, 0.0), crown * 0.75, crown * 1.1, crown * 0.6, CANOPY_COLOR.darkened(0.05), 12)
	merge.add_cylinder(at + Vector3(0.0, trunk_height + crown * 0.75, 0.0), crown * 0.45, crown * 0.95, crown * 0.6, CANOPY_COLOR, 12)
	merge.add_cylinder(at + Vector3(0.0, trunk_height + crown * 1.2, 0.0), crown * 0.1, crown * 0.6, crown * 0.5, CANOPY_COLOR.lightened(0.06), 10)


## The river's water over the chunk: a ribbon 0.4 m over the bed, wide enough to meet its banks.
func _water_for(chunk: Vector2i) -> MeshInstance3D:
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var size: float = WorldGridConfig.CHUNK_SIZE
	var start_x: float = maxf(origin.x, RIVER_POINTS[0].x - 6.0)
	var end_x: float = minf(origin.x + size, RIVER_POINTS[RIVER_POINTS.size() - 1].x + 6.0)
	if start_x >= end_x:
		return null
	var vertices: PackedVector3Array = PackedVector3Array()
	var x: float = start_x
	var half: float = RIVER_HALF_WIDTH + RIVER_BANK + 0.6
	while x < end_x:
		var next: float = minf(x + 4.0, end_x)
		var a: Vector2 = river_at(x)
		var b: Vector2 = river_at(next)
		var a_side: Vector2 = Vector2(-a.y, 1.0).normalized() * half
		var b_side: Vector2 = Vector2(-b.y, 1.0).normalized() * half
		var middle_z: float = (a.x + b.x) * 0.5
		if middle_z >= origin.z - 2.0 and middle_z < origin.z + size + 2.0:
			var p0: Vector3 = Vector3(x - a_side.x, RIVER_WATER, a.x - a_side.y)
			var p1: Vector3 = Vector3(x + a_side.x, RIVER_WATER, a.x + a_side.y)
			var p2: Vector3 = Vector3(next - b_side.x, RIVER_WATER, b.x - b_side.y)
			var p3: Vector3 = Vector3(next + b_side.x, RIVER_WATER, b.x + b_side.y)
			vertices.append_array(PackedVector3Array([p0, p2, p1, p1, p2, p3]))
		x = next
	if vertices.is_empty():
		return null
	var normals: PackedVector3Array = PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var water: MeshInstance3D = MeshInstance3D.new()
	water.name = "River"
	water.mesh = mesh
	water.material_override = water_material()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return water


static func water_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = WATER_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.15
	material.metallic_specular = 0.7
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## The waterfall pouring off the west escarpment, and the cave the river runs into in the east.
func _river_ends_for(chunk: Vector2i) -> Node3D:
	var west: Vector2 = RIVER_POINTS[0]
	var east: Vector2 = RIVER_POINTS[RIVER_POINTS.size() - 1]
	var merge: LandblockTerrain.MeshMerge = LandblockTerrain.MeshMerge.new()
	var falls: MeshInstance3D = null
	if WorldGridConfig.world_to_chunk(Vector3(west.x, 0.0, west.y)) == chunk:
		falls = MeshInstance3D.new()
		falls.name = "Waterfall"
		var sheet: BoxMesh = BoxMesh.new()
		sheet.size = Vector3(1.2, CLIFF_TOP_HEIGHT, 11.0)
		falls.mesh = sheet
		falls.material_override = water_material()
		(falls.material_override as StandardMaterial3D).albedo_color = WATERFALL_COLOR
		falls.position = Vector3(west.x - 4.0, CLIFF_TOP_HEIGHT * 0.5, west.y)
		falls.rotation.y = atan2(river_at(west.x).y, 1.0)
		merge.add_cylinder(Vector3(west.x + 2.0, 0.5, west.y), 5.0, 6.0, 1.0, Color(0.92, 0.96, 1.0), 12)
	if WorldGridConfig.world_to_chunk(Vector3(east.x, 0.0, east.y)) == chunk:
		merge.add_cylinder(Vector3(east.x + 6.0, 3.0, east.y), 7.0, 7.0, 4.0, Color(0.08, 0.08, 0.09), 14, true)
		merge.add_box(Vector3(east.x + 4.0, 8.0, east.y), Vector3(3.0, 4.0, 18.0), ROCK_COLOR.darkened(0.2))
	if falls == null and merge.is_empty():
		return null
	var holder: Node3D = Node3D.new()
	holder.name = "RiverEnds"
	if falls != null:
		holder.add_child(falls)
	if not merge.is_empty():
		var rocks: MeshInstance3D = MeshInstance3D.new()
		rocks.name = "FoamAndCave"
		rocks.mesh = merge.commit()
		rocks.material_override = LandblockTerrain.material()
		holder.add_child(rocks)
	return holder


# --- Tables worked out once -------------------------------------------------------------

func _road_end(petal: int) -> float:
	var theta: float = deg_to_rad(PETAL_BEARINGS[petal])
	if petal == Petal.GLADE:
		return CAMP_DISTANCE / superellipse_factor(theta)
	return cliff_radius(theta) - 2.0


## Where each road crosses the river: the petal roads that do, and the High Road's
## two crossings (each road's own are kept in _road_fords too).
func _find_fords() -> Array[Vector2]:
	var fords: Array[Vector2] = []
	for petal: int in PETAL_BEARINGS.size():
		var best: Vector2 = Vector2.ZERO
		var best_gap: float = INF
		var r: float = ROAD_START
		while r < _road_ends[petal]:
			var at: Vector2 = _road_point_2d(petal, r)
			var gap: float = river_distance(at.x, at.y)
			if gap < best_gap:
				best_gap = gap
				best = at
			r += 1.0
		if best_gap < RIVER_HALF_WIDTH:
			fords.append(best)
			_road_fords[petal] = [best]
	var previous_side: float = 0.0
	var steps: int = 1440
	for step: int in steps + 1:
		var at: Vector2 = _ring_point_2d(TAU * step / steps)
		if at.x < RIVER_POINTS[0].x or at.x > RIVER_POINTS[RIVER_POINTS.size() - 1].x:
			continue
		var side: float = signf(at.y - river_at(at.x).x)
		if previous_side != 0.0 and side != previous_side:
			fords.append(at)
			_road_fords.get_or_add(-1, []).append(at)
		previous_side = side
	return fords


## Two spurs a road, on the inside of each bend.
func _find_spurs() -> Array[Vector2]:
	var spurs: Array[Vector2] = []
	for petal: int in PETAL_BEARINGS.size():
		var span: float = _road_ends[petal] - ROAD_START
		for quarter: float in [0.25, 0.75]:
			var r: float = ROAD_START + span * quarter
			var theta: float = road_bearing(petal, r)
			var bulge: float = signf(PETAL_SWAY[petal] * sin(TAU * quarter))
			var inner: float = theta - bulge * SPUR_OFFSET / r
			spurs.append(CENTER + Vector2(sin(inner), -cos(inner)) * r)
	return spurs


## The 18 hero trees (12 GDD §3): three along each petal road where its
## sub-zones change, the Tangled Root-Sanctum's petrified oak, and the two
## mini-boss arenas (the Old Tusk-Crag's meadow and the Alpha Frost-Fang's weald).
func _place_hero_trees() -> Array[Dictionary]:
	var trees: Array[Dictionary] = []
	for petal: int in PETAL_BEARINGS.size():
		var span: float = _road_ends[petal] - ROAD_START
		var stops: Array[float] = [0.3, 0.6, 0.86]
		for index: int in stops.size():
			var r: float = ROAD_START + span * stops[index]
			var theta: float = road_bearing(petal, r)
			var side: float = 1.0 if index % 2 == 0 else -1.0
			var at: Vector2 = CENTER + Vector2(sin(theta), -cos(theta)) * r + Vector2(cos(theta), sin(theta)) * side * 30.0
			if not _hero_spot_ok(at):
				at = CENTER + Vector2(sin(theta), -cos(theta)) * r - Vector2(cos(theta), sin(theta)) * side * 30.0
			trees.append(_hero(at, 2.2 + 0.25 * index, 26.0 + 3.0 * index, 11.0 + index, false))
	var oak: Transform3D = apron_portal(Petal.WEALD)
	var oak_at: Vector2 = Vector2(oak.origin.x, oak.origin.z) + Vector2(oak.basis.z.x, oak.basis.z.z) * 22.0 + Vector2(oak.basis.x.x, oak.basis.x.z) * 16.0
	trees.append(_hero(oak_at, 2.9, 30.0, 0.0, true))
	trees.append(_hero(_sector_point(214.0, 245.0), 2.6, 28.0, 13.0, false))
	trees.append(_hero(_sector_point(150.0, 470.0), 2.6, 30.0, 13.0, false))
	return trees


func _hero(at: Vector2, radius: float, height: float, crown: float, petrified: bool) -> Dictionary:
	return {"position": Vector3(at.x, field_height(at.x, at.y), at.y), "radius": radius, "height": height, "crown": crown, "petrified": petrified}


func _hero_spot_ok(at: Vector2) -> bool:
	return not is_kept_clear(at.x, at.y, 6.0)


## A spot at a bearing (degrees) and superellipse distance, nudged off any road or the river.
func _sector_point(degrees: float, d: float) -> Vector2:
	var theta: float = deg_to_rad(degrees)
	var at: Vector2 = CENTER + Vector2(sin(theta), -cos(theta)) * d / superellipse_factor(theta)
	var nudge: int = 0
	while is_kept_clear(at.x, at.y, 6.0) and nudge < 12:
		theta += 0.03
		at = CENTER + Vector2(sin(theta), -cos(theta)) * d / superellipse_factor(theta)
		nudge += 1
	return at


## A lantern pole and a runestone every 75 m of road, on opposite verges.
func _place_waymarks() -> Array[Dictionary]:
	var marks: Array[Dictionary] = []
	for petal: int in PETAL_BEARINGS.size():
		var travelled: float = 0.0
		var next: float = WAYMARK_SPACING * 0.5
		var r: float = ROAD_START + 4.0
		var previous: Vector2 = _road_point_2d(petal, r)
		while r < _road_ends[petal] - 6.0:
			r += 1.0
			var here: Vector2 = _road_point_2d(petal, r)
			travelled += here.distance_to(previous)
			if travelled >= next:
				_add_waymark_pair(marks, here, (here - previous).normalized(), marks.size())
				next += WAYMARK_SPACING
			previous = here
	var travelled_ring: float = 0.0
	var next_ring: float = WAYMARK_SPACING * 0.5
	var steps: int = 2400
	var last: Vector2 = _ring_point_2d(0.0)
	for step: int in range(1, steps + 1):
		var theta: float = TAU * step / steps
		var here: Vector2 = _ring_point_2d(theta)
		travelled_ring += here.distance_to(last)
		if travelled_ring >= next_ring:
			_add_waymark_pair(marks, here, (here - last).normalized(), marks.size())
			next_ring += WAYMARK_SPACING
		last = here
	return marks


func _add_waymark_pair(marks: Array[Dictionary], at: Vector2, along: Vector2, index: int) -> void:
	var side: Vector2 = Vector2(-along.y, along.x)
	var flip: float = 1.0 if index % 4 == 0 else -1.0
	for lantern: bool in [true, false]:
		var spot: Vector2 = at + side * WAYMARK_OFFSET * (flip if lantern else -flip)
		if world_x_in_river(spot):
			continue
		marks.append({"position": Vector3(spot.x, field_height(spot.x, spot.y), spot.y), "lantern": lantern, "yaw": atan2(along.x, along.y)})


func world_x_in_river(at: Vector2) -> bool:
	return at.x > RIVER_POINTS[0].x and at.x < RIVER_POINTS[RIVER_POINTS.size() - 1].x and river_distance(at.x, at.y) < RIVER_HALF_WIDTH + RIVER_BANK + 1.0


func _road_point_2d(petal: int, r: float) -> Vector2:
	var theta: float = road_bearing(petal, r)
	return CENTER + Vector2(sin(theta), -cos(theta)) * r


func _ring_point_2d(theta: float) -> Vector2:
	var r: float = ring_road_distance(theta) / superellipse_factor(theta)
	return CENTER + Vector2(sin(theta), -cos(theta)) * r
