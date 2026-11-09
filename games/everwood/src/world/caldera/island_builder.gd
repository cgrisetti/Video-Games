## What one Caldera island is (docs/20 Part I and II): its ground as a height
## field, its colours, what grows where, its named places and arrivals, and
## the structures it builds when it becomes the active island.
##
## The field is the island's own base shape (_base_height, per island) with
## two kinds of feature pressed into it: ramps (a road, a stair, a gully,
## blended to a straight grade between two points) and pads (a flat place at
## a set height: a quay, a market green, a trial's arena, a cove the Ebb bares).
## Paths don't shape the field. Each road is laid over it once, when the island
## is built (docs/26): every leg between two control points is routed across a
## 5 m grid by AStarGrid2D, steering round slopes and water and wandering a
## little on open ground, then straightened, rounded and resampled. The ground
## shader draws the laid roads per pixel from road_textures() (smooth edges,
## cobbles laid along the road, earthen footpaths); the scatter, meadow, map and
## coast read the same roads as segments. Everything that samples the field is
## pure and safe on a worker thread; the build_* methods make nodes on the main thread.
##
## Each island lives in its own frame: its grid centred on the origin, north
## at -Z, the sea at y = CalderaWorldState.sea_level_y.
class_name IslandBuilder
extends RefCounted

## What the scatter grows (one MultiMesh per species per landblock). The worked land's
## kinds (docs/32) follow the first fourteen: the valley's other trees, the runs a field
## boundary is laid in (a hedge, a dry-stone wall, a rail fence, a wattle hurdle, each a
## piece a few metres long set end to end along the line), and what a field is left with.
enum Species { ORCHARD_TREE, OAK_TREE, PINE_TREE, SNOW_PINE, REED_CLUMP, ROCK, BOULDER, BASALT_SPIRE, FERN_TUFT, ASH_TREE, WILLOW_TREE,
	GORSE_BUSH, HEATHER_CLUMP, ROWAN_TREE,
	BEECH_TREE, ELM_TREE, CHESTNUT_TREE, BIRCH_TREE, POPLAR_TREE, HAWTHORN_TREE, ALDER_TREE, POLLARD_WILLOW, PLUM_TREE, PEAR_TREE, YEW_TREE,
	HOLLY_TREE,
	HEDGE_RUN, HEDGE_BLOOM, WALL_RUN, WALL_TUMBLE, FENCE_RUN, HURDLE_RUN, FIELD_GATE, STILE,
	HAYCOCK, STOOK, CROP_ROW, BEAN_ROW, BRAMBLE_BUSH, TROUGH, SCARECROW, FIELD_OAK, FIELD_ASH, SCOTS_PINE }
const SPECIES_COUNT: int = 44
## Trunk and stone radii that block the way inside the loaded window (0: walk through).
const SOLID_RADIUS: Array[float] = [0.3, 0.55, 0.35, 0.35, 0.0, 0.0, 0.9, 0.8, 0.0, 0.4, 0.6, 0.0, 0.0, 0.3,
	0.5, 0.45, 0.55, 0.2, 0.3, 0.2, 0.3, 0.5, 0.2, 0.22, 0.5,
	0.2,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.55, 0.35, 0.3]
## The runs that block the way as a low box along their length (width, height, depth in metres, on the
## low-scenery layer: a hero hops them, a camera sees over them); a hedge is leaves and lets everyone through.
const SOLID_BOX: Dictionary[int, Vector3] = {Species.WALL_RUN: Vector3(3.2, 0.8, 0.6), Species.FENCE_RUN: Vector3(3.2, 0.8, 0.16),
	Species.HURDLE_RUN: Vector3(2.4, 0.8, 0.14), Species.TROUGH: Vector3(1.8, 0.5, 0.6)}

## Landblock mesh resolutions: the loaded window (2 m) and the whole-island stand-in (8 m).
const NEAR_QUADS: int = 64
const FAR_QUADS: int = 16
## Collider samples per landblock side (every metre, the last shared with the next landblock).
const COLLISION_SIDE: int = 129
## Skirts hang this far below every landblock edge so neighbours of either resolution never show a crack.
const SKIRT_DEPTH: float = 6.0
## Scatter candidates a landblock rolls (each island keeps the share it wants).
const SCATTER_TRIES: int = 260
## The meadow (docs/24_PAINTED_WORLD_PASS.md §4): grass tufts in natural clumps
## and wildflowers in little drifts over every near landblock's open ground,
## in cells MEADOW_CELLS a side so only the ones near a camera are drawn.
const MEADOW_CELLS: int = 4
const MEADOW_CLUMPS: int = 1150
const MEADOW_FLOWER_CLUMPS: int = 340
## Which flower each drift is (CalderaKit.Flower), by share.
const MEADOW_FLOWER_SHARES: Array[float] = [0.34, 0.28, 0.12, 0.1, 0.16]

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
## Laying roads (docs/26): the routing grid's cell; legs shorter than this stay straight.
const ROUTE_CELL: float = 5.0
const ROUTE_MIN_LEG: float = 24.0
## A cell's cost is 1, plus ROUTE_SLOPE_COST per (tenth of grade past ROUTE_EASY_GRADE)
## squared, plus up to ROUTE_WANDER from a slow noise (the gentle wander of a road
## over open ground); near a road already laid it costs ROUTE_TRUNK of that, so roads share trunks.
const ROUTE_SLOPE_COST: float = 3.0
const ROUTE_EASY_GRADE: float = 0.1
const ROUTE_WANDER: float = 0.6
const ROUTE_TRUNK: float = 0.55
const ROUTE_TRUNK_REACH: float = 6.0
## Cells steeper than this grade, or deeper than ROUTE_DEEP, are never crossed; ground lower
## than ROUTE_DRY (the beach, a fen's shallows) costs ROUTE_WET, so a road fords only where it must.
const ROUTE_STEEP: float = 0.55
const ROUTE_DRY: float = 0.5
const ROUTE_DEEP: float = -0.8
const ROUTE_WET: float = 40.0
## The routed line is straightened to within this many metres, then rounded.
const ROUTE_SIMPLIFY: float = 3.0
const ROUTE_ROUNDING: int = 3
## Then relaxed this many times (each point eased toward its neighbours), so no bend is a hairpin.
const ROUTE_RELAX: int = 48
## A drawn road's points lie this far apart; the segments the scatter, meadow and map read, this far.
const ROAD_STEP: float = 3.0
const PATH_STEP: float = 6.0
const COARSE_STEP: float = 24.0
## Roads this narrow or narrower are earthen footpaths; wider ones are cobbled.
const DIRT_HALF_WIDTH: float = 1.7
## The shader's road lookup: cells this wide, each listing the road segments within reach.
const ROAD_CELL: float = 16.0
const ROAD_REACH: float = 3.5
const ROAD_MAX_PER_CELL: int = 48
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
## Which way the party faces on arriving (a yaw about +Y; 0 faces -Z, north).
var arrival_yaws: Dictionary[StringName, float] = {}

var _noise: FastNoiseLite
var _detail: FastNoiseLite
## Pads, 5 floats each: x, z, radius, blend, height.
var _pads: PackedFloat32Array = PackedFloat32Array()
## Ramps, 8 floats each: from x, y, z, to x, y, z, half width, blend.
var _ramps: PackedFloat32Array = PackedFloat32Array()
## Painted paths, 5 floats a segment: from x, z, to x, z, half width.
var _paths: PackedFloat32Array = PackedFloat32Array()
## Roads as asked for ({"points", "half_width", "route"}), laid over the ground after _define().
var _road_plans: Array[Dictionary] = []
## The laid roads, as drawn: [{"points": PackedVector2Array (ROAD_STEP apart), "half_width": float}].
var laid_roads: Array[Dictionary] = []
var _road_textures: Dictionary = {}
## The laid roads as long segments (COARSE_STEP apart) for the coast's keep grid and the inlets, which only need them roughly.
var _coarse_paths: PackedFloat32Array = PackedFloat32Array()
## Heights on the routing lattice (every ROUTE_CELL metres), shared by every leg while the roads are laid.
var _route_heights: Dictionary[Vector2i, float] = {}
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
	_lay_roads()
	_prepare_coast()
	_relay_wet_roads()
	for id: StringName in arrivals.keys():
		var at: Vector3 = arrivals[id]
		arrivals[id] = Vector3(at.x, height_at(at.x, at.z), at.z)


# --- What each island fills in ------------------------------------------------

## Lays out the island's pads, ramps, paths, places and arrivals (called once from _init).
func _define() -> void:
	pass


## The ground's three levels of detail, as quads along a 128 m landblock: the
## window's (near), a ring round it (mid; 0 for none) and the far stand-in's.
## Procedural isles sample their field, so they keep 2 m near and 8 m far;
## Embershore reads a 1 m heightmap and shows 1 m, 2 m and 4 m (docs/27 §4).
func lod_quads() -> PackedInt32Array:
	return PackedInt32Array([NEAR_QUADS, 0, FAR_QUADS])


## Whether every landblock keeps its collider from the moment the island is
## live (Embershore: the heightmap already holds it), or only the window does.
func collision_resident() -> bool:
	return false


## A landblock's collider heights (COLLISION_SIDE a side, every metre) straight
## from the island's data, or empty to sample them from the ground mesh.
func collision_heights_for(_chunk: Vector2i) -> PackedFloat32Array:
	return PackedFloat32Array()


## A laid road's surface at a spot: 0 cobbled setts, 1 packed earth, or -1 to go
## by its width (narrow roads are earthen). Embershore cobbles only its villages.
func road_surface_at(_x: float, _z: float, _half_width: float) -> int:
	return -1


## Whether a spot lies past the island's sealed edge (Embershore's Deep-Hush): the tide turns a party back from there.
func beyond_seal(_x: float, _z: float) -> bool:
	return false


## The island's ground before pads and ramps.
func _base_height(_x: float, _z: float) -> float:
	return -10.0


## The ground's colour before paths: `up` is the ground normal's y (1 flat, 0 sheer).
func _ground_color(_x: float, _z: float, height: float, up: float) -> Color:
	return shore_or(height, up, Color(0.42, 0.56, 0.3), Color(0.5, 0.48, 0.44))


## What grows at a spot (a Species, or -1). `roll` is a fair 0..1 die.
## The way a field is worked at a spot, for the ground shader's furrows and rows (docs/32 §4):
## x and y are the row's direction scaled by how strongly it shows (0: none), z the rows'
## spacing in metres and w their tone (-1 a darker furrow, +1 a green row of crop).
func ground_tilth(_x: float, _z: float) -> Vector4:
	return Vector4.ZERO


## Whether this island's ground carries tilth (its landblock meshes then carry it in their UVs).
func has_tilth() -> bool:
	return false


## How the meadow grows at a spot besides its lushness: x the tufts' height, y the share of the
## usual wildflowers, z how ripe (0 green-tipped grass, 1 straw to the tip: standing grain).
func _meadow_style(_x: float, _z: float) -> Vector3:
	return Vector3(1.0, 1.0, 0.0)


## Which wildflower each drift is, by share (CalderaKit.Flower order; they sum to 1). An isle with a colour
## field of its own leans its drifts to it (docs/33 §3.3).
func meadow_flower_shares() -> Array[float]:
	return MEADOW_FLOWER_SHARES


## The island's colour as the other isles see it (its far silhouette): its ground's, unless its plants read
## as one mass of colour from afar (docs/33 §3.3).
func far_color(x: float, z: float, height: float, up: float) -> Color:
	return surface_color(x, z, height, up)


## Where the island's Beacon stands (its ground, in the island's frame), or Vector3.INF for an isle with none.
func beacon_spot() -> Vector3:
	return Vector3.INF


## The corridor's stage a spot is in (its sky, fog and music): the named place, unless the island
## keeps smaller places inside its stages (a steading in a valley).
func stage_name_at(at: Vector3) -> String:
	return place_name_at(at)


## Whether folk live at a named place (the mosaics' Peace and Mellow lean on it).
func is_settled_place(_place_name: String) -> bool:
	return false


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


## Asks for a road through `points`. With `route` each leg is laid over the
## ground by the best way (a road that must keep to a ramp, or a curve already
## drawn smooth like The Crown's Ring Path, passes false and is only rounded).
func add_path(points: PackedVector2Array, half_width: float = 1.6, route: bool = true) -> void:
	if points.size() >= 2:
		_road_plans.append({"points": points, "half_width": half_width, "route": route})


func add_place(place_name: String, at: Vector3, radius: float) -> void:
	places.append({"name": place_name, "at": at, "radius": radius})


func add_arrival(id: StringName, at: Vector2, facing: Vector2 = Vector2.ZERO) -> void:
	arrivals[id] = Vector3(at.x, 0.0, at.y)
	if facing.length() > 0.001:
		# Heroes face -Z: a yaw of atan2(-x, -z) turns them toward `facing`.
		arrival_yaws[id] = atan2(-facing.x, -facing.y)


## The way the party faces at an arrival, as a basis.
func arrival_basis(id: StringName) -> Basis:
	return Basis(Vector3.UP, arrival_yaws.get(id, 0.0))


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
	# A row of four across the way the party faces, further rows behind.
	var facing: Basis = arrival_basis(id)
	@warning_ignore("integer_division")
	var spread: Vector3 = facing.x * (float(slot % 4) - 1.5) * 2.4 + facing.z * float(slot / 4) * 2.4
	var x: float = at.x + spread.x
	var z: float = at.z + spread.z
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


## A vertex's colour: the ground alone. Roads aren't painted into the vertices any
## more (their edges followed the 2 m triangles); the ground shader draws them.
func _paint(x: float, z: float, height: float, up: float, _paths_near: PackedFloat32Array) -> Color:
	return _ground_color(x, z, height, up)


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


# --- Laying the roads (docs/26) --------------------------------------------------------

## Lays every road asked for over the ground, in the order asked, into
## laid_roads (drawn) and _paths (the segments the rest of the island reads).
func _lay_roads() -> void:
	laid_roads.clear()
	_paths = PackedFloat32Array()
	_road_textures = {}
	_route_heights.clear()
	for plan: Dictionary in _road_plans:
		laid_roads.append({"points": _lay_road(plan), "half_width": float(plan["half_width"])})
		_append_segments(laid_roads[laid_roads.size() - 1])
	_route_heights.clear()
	_coarse_paths = PackedFloat32Array()
	for road: Dictionary in laid_roads:
		var rough: PackedVector2Array = _resample(road["points"], COARSE_STEP)
		for index: int in rough.size() - 1:
			_coarse_paths.append_array(PackedFloat32Array([rough[index].x, rough[index].y, rough[index + 1].x, rough[index + 1].y, float(road["half_width"]) + 1.0]))


func _lay_road(plan: Dictionary) -> PackedVector2Array:
	var points: PackedVector2Array = plan["points"]
	var laid: PackedVector2Array = PackedVector2Array([points[0]])
	if bool(plan["route"]):
		for index: int in points.size() - 1:
			laid.append_array(_route_leg(points[index], points[index + 1]).slice(1))
		var routed: PackedVector2Array = _resample(_round_line(laid, ROUTE_ROUNDING), ROAD_STEP)
		laid = _keep_dry(laid, _relax_line(routed, ROUTE_RELAX))
	else:
		laid = _round_line(points, 2)
	return _resample(laid, ROAD_STEP)


func _append_segments(road: Dictionary) -> void:
	var coarse: PackedVector2Array = _resample(road["points"], PATH_STEP)
	var half: float = float(road["half_width"])
	for index: int in coarse.size() - 1:
		_paths.append_array(PackedFloat32Array([coarse[index].x, coarse[index].y, coarse[index + 1].x, coarse[index + 1].y, half]))


## Once the coast is shaped (its bays and pools can only be known after the
## roads are laid, since it keeps clear of them), a routed road that now runs
## through water away from its ends is laid again over the final ground.
func _relay_wet_roads() -> void:
	var changed: bool = false
	for index: int in laid_roads.size():
		var plan: Dictionary = _road_plans[index]
		if not bool(plan["route"]):
			continue
		var points: PackedVector2Array = laid_roads[index]["points"]
		var wet: bool = false
		for at: Vector2 in points:
			if at.distance_to(points[0]) > 40.0 and at.distance_to(points[points.size() - 1]) > 40.0 and height_at(at.x, at.y) < 0.0:
				wet = true
				break
		if wet:
			_route_heights.clear()
			laid_roads[index] = {"points": _lay_road(plan), "half_width": float(plan["half_width"])}
			changed = true
	_route_heights.clear()
	if changed:
		_paths = PackedFloat32Array()
		_road_textures = {}
		for road: Dictionary in laid_roads:
			_append_segments(road)


## The best way from `a` to `b` over the ground: round the steep and the wet, a
## little wander on open ground, and along roads already laid where they help.
func _route_leg(a: Vector2, b: Vector2) -> PackedVector2Array:
	var length: float = a.distance_to(b)
	if length < ROUTE_MIN_LEG or _leg_on_ramp(a, b):
		return PackedVector2Array([a, b])
	var margin: float = clampf(length * 0.3, 24.0, 80.0)
	var grown: Rect2 = Rect2(a, Vector2.ZERO).expand(b).grow(margin)
	# The box sits on the island-wide lattice, so legs that overlap share their heights.
	var corner: Vector2i = Vector2i(int(floor(grown.position.x / ROUTE_CELL)), int(floor(grown.position.y / ROUTE_CELL)))
	var box: Rect2 = Rect2(Vector2(corner) * ROUTE_CELL, grown.size)
	var cols: int = int(ceil(box.size.x / ROUTE_CELL)) + 2
	var rows: int = int(ceil(box.size.y / ROUTE_CELL)) + 2
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(cols * rows)
	for row: int in rows:
		for col: int in cols:
			var key: Vector2i = corner + Vector2i(col, row)
			if not _route_heights.has(key):
				_route_heights[key] = height_at(key.x * ROUTE_CELL, key.y * ROUTE_CELL)
			heights[row * cols + col] = _route_heights[key]
	var trunk: PackedByteArray = _trunk_cells(box, cols, rows)
	var start: Vector2i = _route_cell(a, box, cols, rows)
	var goal: Vector2i = _route_cell(b, box, cols, rows)
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, cols, rows)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.update()
	for row: int in rows:
		for col: int in cols:
			var index: int = row * cols + col
			var h: float = heights[index]
			var dx: float = heights[row * cols + mini(col + 1, cols - 1)] - heights[row * cols + maxi(col - 1, 0)]
			var dz: float = heights[mini(row + 1, rows - 1) * cols + col] - heights[maxi(row - 1, 0) * cols + col]
			var grade: float = Vector2(dx, dz).length() / (2.0 * ROUTE_CELL)
			var cell: Vector2i = Vector2i(col, row)
			var at_end: bool = cell.distance_to(start) < 3.0 or cell.distance_to(goal) < 3.0
			if not at_end and (h < ROUTE_DEEP or grade > ROUTE_STEEP):
				grid.set_point_solid(cell)
				continue
			var x: float = box.position.x + col * ROUTE_CELL
			var z: float = box.position.y + row * ROUTE_CELL
			var steep: float = maxf(0.0, grade - ROUTE_EASY_GRADE) / 0.1
			var weight: float = 1.0 + ROUTE_SLOPE_COST * steep * steep + ROUTE_WANDER * (0.5 + 0.5 * _noise.get_noise_2d(x * 2.2, z * 2.2))
			if h < ROUTE_DRY and not at_end:
				weight += ROUTE_WET
			if trunk[index] == 1:
				weight *= ROUTE_TRUNK
			grid.set_point_weight_scale(cell, weight)
	# Water narrower than a cell can slip between two dry cell centres: walk the line,
	# close the cells round any wet spot and route again (twice at most).
	var points: PackedVector2Array = PackedVector2Array([a, b])
	for attempt: int in 3:
		var cells: Array[Vector2i] = grid.get_id_path(start, goal)
		if cells.size() < 2:
			return PackedVector2Array([a, b]) if attempt == 0 else points
		points = PackedVector2Array([a])
		for index: int in range(1, cells.size() - 1):
			points.append(box.position + Vector2(cells[index]) * ROUTE_CELL)
		points.append(b)
		var closed: int = 0
		for index: int in points.size() - 1:
			var span: float = points[index].distance_to(points[index + 1])
			for step: int in int(span / 2.0):
				var at: Vector2 = points[index].lerp(points[index + 1], (float(step) + 0.5) * 2.0 / span)
				if at.distance_to(a) < 15.0 or at.distance_to(b) < 15.0 or height_at(at.x, at.y) >= ROUTE_DEEP:
					continue
				var cell: Vector2i = _route_cell(at, box, cols, rows)
				for dz: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var near: Vector2i = cell + Vector2i(dx, dz)
						if grid.is_in_boundsv(near) and near != start and near != goal and not grid.is_point_solid(near):
							grid.set_point_solid(near)
							closed += 1
		if closed == 0:
			break
	return simplify_line(points, ROUTE_SIMPLIFY)


func _route_cell(at: Vector2, box: Rect2, cols: int, rows: int) -> Vector2i:
	return Vector2i(clampi(roundi((at.x - box.position.x) / ROUTE_CELL), 0, cols - 1), clampi(roundi((at.y - box.position.y) / ROUTE_CELL), 0, rows - 1))


## The routing grid's cells within ROUTE_TRUNK_REACH of a road already laid.
func _trunk_cells(box: Rect2, cols: int, rows: int) -> PackedByteArray:
	var trunk: PackedByteArray = PackedByteArray()
	trunk.resize(cols * rows)
	var index: int = 0
	while index < _paths.size():
		var a: Vector2 = Vector2(_paths[index], _paths[index + 1])
		var b: Vector2 = Vector2(_paths[index + 2], _paths[index + 3])
		index += 5
		var reach: Rect2 = Rect2(a, Vector2.ZERO).expand(b).grow(ROUTE_TRUNK_REACH)
		if not reach.intersects(box):
			continue
		var c0: int = maxi(0, int(floor((reach.position.x - box.position.x) / ROUTE_CELL)))
		var c1: int = mini(cols - 1, int(ceil((reach.end.x - box.position.x) / ROUTE_CELL)))
		var r0: int = maxi(0, int(floor((reach.position.y - box.position.y) / ROUTE_CELL)))
		var r1: int = mini(rows - 1, int(ceil((reach.end.y - box.position.y) / ROUTE_CELL)))
		for row: int in range(r0, r1 + 1):
			for col: int in range(c0, c1 + 1):
				var at: Vector2 = box.position + Vector2(col, row) * ROUTE_CELL
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) <= ROUTE_TRUNK_REACH:
					trunk[row * cols + col] = 1
	return trunk


## Whether a leg mostly runs along a ramp (a built road's grade): such a leg keeps to it.
func _leg_on_ramp(a: Vector2, b: Vector2) -> bool:
	var on: int = 0
	for step: int in 5:
		var at: Vector2 = a.lerp(b, (float(step) + 0.5) / 5.0)
		var index: int = 0
		while index < _ramps.size():
			var from: Vector2 = Vector2(_ramps[index], _ramps[index + 2])
			var to: Vector2 = Vector2(_ramps[index + 3], _ramps[index + 5])
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, from, to)) <= _ramps[index + 6] + 1.0:
				on += 1
				break
			index += 8
	return on >= 3


## A line straightened to within `tolerance` metres (Ramer-Douglas-Peucker), its ends kept.
static func simplify_line(points: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var keep: PackedByteArray = PackedByteArray()
	keep.resize(points.size())
	keep[0] = 1
	keep[points.size() - 1] = 1
	var spans: Array[Vector2i] = [Vector2i(0, points.size() - 1)]
	while not spans.is_empty():
		var span: Vector2i = spans.pop_back()
		var worst: float = -1.0
		var at: int = -1
		for index: int in range(span.x + 1, span.y):
			var off: float = points[index].distance_to(Geometry2D.get_closest_point_to_segment(points[index], points[span.x], points[span.y]))
			if off > worst:
				worst = off
				at = index
		if at >= 0 and worst > tolerance:
			keep[at] = 1
			spans.append(Vector2i(span.x, at))
			spans.append(Vector2i(at, span.y))
	var out: PackedVector2Array = PackedVector2Array()
	for index: int in points.size():
		if keep[index] == 1:
			out.append(points[index])
	return out


## A line with its corners cut `iterations` times (Chaikin), its ends kept.
static func _round_line(points: PackedVector2Array, iterations: int) -> PackedVector2Array:
	var line: PackedVector2Array = points
	for _pass: int in iterations:
		if line.size() < 3:
			return line
		var out: PackedVector2Array = PackedVector2Array([line[0]])
		for index: int in line.size() - 1:
			out.append(line[index].lerp(line[index + 1], 0.25))
			out.append(line[index].lerp(line[index + 1], 0.75))
		out.append(line[line.size() - 1])
		line = out
	return line


## A line eased `passes` times, each point halfway toward its neighbours' middle, its ends kept.
static func _relax_line(points: PackedVector2Array, passes: int) -> PackedVector2Array:
	var line: PackedVector2Array = points
	for _pass: int in passes:
		var out: PackedVector2Array = line.duplicate()
		for index: int in range(1, line.size() - 1):
			out[index] = line[index] * 0.5 + (line[index - 1] + line[index + 1]) * 0.25
		line = out
	return line


## A smoothed line, eased back onto the routed one (`raw`, which keeps to dry
## ground) wherever rounding or relaxing cut a corner into water (a fen pool, an
## inlet): the points round each wet one blend back over eight steps either side.
func _keep_dry(raw: PackedVector2Array, smooth: PackedVector2Array) -> PackedVector2Array:
	var back: PackedFloat32Array = PackedFloat32Array()
	back.resize(smooth.size())
	var reach: int = 8
	for index: int in smooth.size():
		if height_at(smooth[index].x, smooth[index].y) >= ROUTE_DRY:
			continue
		for near: int in range(maxi(0, index - reach), mini(smooth.size(), index + reach + 1)):
			back[near] = maxf(back[near], 1.0 - float(absi(near - index)) / float(reach + 1))
	var out: PackedVector2Array = smooth.duplicate()
	for index: int in out.size():
		if back[index] > 0.0:
			var on_raw: Vector2 = smooth[index]
			var best: float = INF
			for step: int in raw.size() - 1:
				var at: Vector2 = Geometry2D.get_closest_point_to_segment(smooth[index], raw[step], raw[step + 1])
				if at.distance_to(smooth[index]) < best:
					best = at.distance_to(smooth[index])
					on_raw = at
			out[index] = smooth[index].lerp(on_raw, smoothstep(0.0, 1.0, back[index]))
	return out


## Points every `step` metres along a line, its ends kept.
static func _resample(points: PackedVector2Array, step: float) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var out: PackedVector2Array = PackedVector2Array([points[0]])
	var carried: float = 0.0
	for index: int in points.size() - 1:
		var a: Vector2 = points[index]
		var b: Vector2 = points[index + 1]
		var length: float = a.distance_to(b)
		var along: float = step - carried
		while along < length:
			out.append(a.lerp(b, along / length))
			along += step
		carried = length - (along - step)
	if out[out.size() - 1].distance_to(points[points.size() - 1]) > 0.5:
		out.append(points[points.size() - 1])
	else:
		out[out.size() - 1] = points[points.size() - 1]
	return out


## The nearest point on a laid road to `near`: {"at": Vector2, "along": Vector2 (unit), "half_width": float}, empty if there are none.
func nearest_road(near: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = INF
	for road: Dictionary in laid_roads:
		var points: PackedVector2Array = road["points"]
		for index: int in points.size() - 1:
			var at: Vector2 = Geometry2D.get_closest_point_to_segment(near, points[index], points[index + 1])
			var d: float = near.distance_to(at)
			if d < best_d:
				best_d = d
				best = {"at": at, "along": (points[index + 1] - points[index]).normalized(), "half_width": float(road["half_width"])}
	return best


## A spot on the ground beside the laid road nearest `near`: `side` (+1 or -1) of it, `gap` metres past its edge.
func roadside(near: Vector2, side: float = 1.0, gap: float = 1.6) -> Vector3:
	var road: Dictionary = nearest_road(near)
	if road.is_empty():
		return ground(near.x, near.y)
	var along: Vector2 = road["along"]
	var spot: Vector2 = Vector2(road["at"]) + Vector2(-along.y, along.x) * side * (float(road["half_width"]) + gap)
	return ground(spot.x, spot.y)


## The laid roads for the ground shader (docs/26), built once: the segments
## (two RGBA float texels each: a.xz b.xz, then half width, distance along the
## road at a, kind 0 cobbled / 1 earthen), a grid of ROAD_CELL cells over the
## island (each its offset and count in the index list) and the index list.
## {"segs", "cells", "index": ImageTexture, "grid": Vector4 (origin x, z, cell, 1), "dims": Vector2i}.
func road_textures() -> Dictionary:
	if not _road_textures.is_empty():
		return _road_textures
	var segs: PackedFloat32Array = PackedFloat32Array()
	for road: Dictionary in laid_roads:
		var points: PackedVector2Array = road["points"]
		var half: float = float(road["half_width"])
		var along: float = 0.0
		for index: int in points.size() - 1:
			var middle: Vector2 = (points[index] + points[index + 1]) * 0.5
			var surface: int = road_surface_at(middle.x, middle.y, half)
			var kind: float = float(surface) if surface >= 0 else (1.0 if half <= DIRT_HALF_WIDTH else 0.0)
			segs.append_array(PackedFloat32Array([points[index].x, points[index].y, points[index + 1].x, points[index + 1].y, half, along, kind, 0.0]))
			along += points[index].distance_to(points[index + 1])
	@warning_ignore("integer_division")
	var count: int = segs.size() / 8
	var half_side: Vector2 = isle.half_size() + Vector2.ONE * ROAD_CELL
	var origin: Vector2 = -half_side
	var dims_x: int = int(ceil(half_side.x * 2.0 / ROAD_CELL))
	var dims_z: int = int(ceil(half_side.y * 2.0 / ROAD_CELL))
	var lists: Array[PackedInt32Array] = []
	lists.resize(dims_x * dims_z)
	for index: int in count:
		var a: Vector2 = Vector2(segs[index * 8], segs[index * 8 + 1])
		var b: Vector2 = Vector2(segs[index * 8 + 2], segs[index * 8 + 3])
		var reach: Rect2 = Rect2(a, Vector2.ZERO).expand(b).grow(segs[index * 8 + 4] + ROAD_REACH)
		var c0: int = clampi(int(floor((reach.position.x - origin.x) / ROAD_CELL)), 0, dims_x - 1)
		var c1: int = clampi(int(floor((reach.end.x - origin.x) / ROAD_CELL)), 0, dims_x - 1)
		var r0: int = clampi(int(floor((reach.position.y - origin.y) / ROAD_CELL)), 0, dims_z - 1)
		var r1: int = clampi(int(floor((reach.end.y - origin.y) / ROAD_CELL)), 0, dims_z - 1)
		for row: int in range(r0, r1 + 1):
			for col: int in range(c0, c1 + 1):
				if lists[row * dims_x + col].size() < ROAD_MAX_PER_CELL:
					lists[row * dims_x + col].append(index)
	var seg_image: Image = Image.create_empty(512, maxi(1, int(ceil(float(count) / 256.0))), false, Image.FORMAT_RGBAF)
	for index: int in count:
		@warning_ignore("integer_division")
		var y: int = index / 256
		var x: int = (index % 256) * 2
		seg_image.set_pixel(x, y, Color(segs[index * 8], segs[index * 8 + 1], segs[index * 8 + 2], segs[index * 8 + 3]))
		seg_image.set_pixel(x + 1, y, Color(segs[index * 8 + 4], segs[index * 8 + 5], segs[index * 8 + 6], 0.0))
	var listed: PackedFloat32Array = PackedFloat32Array()
	var cell_image: Image = Image.create_empty(dims_x, dims_z, false, Image.FORMAT_RGF)
	for row: int in dims_z:
		for col: int in dims_x:
			var list: PackedInt32Array = lists[row * dims_x + col]
			cell_image.set_pixel(col, row, Color(float(listed.size()), float(list.size()), 0.0))
			for each: int in list:
				listed.append(float(each))
	var index_image: Image = Image.create_empty(1024, maxi(1, int(ceil(float(listed.size()) / 1024.0))), false, Image.FORMAT_RF)
	for index: int in listed.size():
		@warning_ignore("integer_division")
		index_image.set_pixel(index % 1024, index / 1024, Color(listed[index], 0.0, 0.0))
	_road_textures = {"segs": ImageTexture.create_from_image(seg_image), "cells": ImageTexture.create_from_image(cell_image),
		"index": ImageTexture.create_from_image(index_image), "grid": Vector4(origin.x, origin.y, ROAD_CELL, 1.0), "dims": Vector2i(dims_x, dims_z),
		"segments": count}
	return _road_textures


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
		var half: Vector2 = isle.half_size()
		push *= COAST_HEADLAND_SHARE * (1.0 - smoothstep(-190.0, -70.0, maxf(absf(x) - half.x, absf(z) - half.y)))
	return push


## How much of the plain shore is kept at a spot (1 beside a pad, ramp, path, arrival, place or anchor; 0 free to reshape).
func coast_kept(x: float, z: float) -> float:
	if _keep_side == 0:
		return 1.0
	var half: Vector2 = isle.half_size()
	var fx: float = clampf((x + half.x) / COAST_KEEP_CELL, 0.0, float(_keep_side - 1) - 0.001)
	var fz: float = clampf((z + half.y) / COAST_KEEP_CELL, 0.0, float(_keep_side - 1) - 0.001)
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
	while index < _coarse_paths.size():
		keepers.append_array(_coarse_paths.slice(index, index + 5))
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
	while index < _coarse_paths.size():
		var a: Vector2 = Vector2(_coarse_paths[index], _coarse_paths[index + 1])
		var b: Vector2 = Vector2(_coarse_paths[index + 2], _coarse_paths[index + 3])
		best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) - _coarse_paths[index + 4])
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
func build_chunk_data(chunk: Vector2i, quads: int, with_collision: bool, with_scatter: bool, with_meadow: bool = false) -> Dictionary:
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
	# The tilth (docs/32 §4): the rows' direction and strength in UV, their spacing and tone in UV2.
	var tilled: bool = has_tilth()
	var rows: PackedVector2Array = PackedVector2Array()
	var tones: PackedVector2Array = PackedVector2Array()
	if tilled:
		rows.resize(side * side + side * 4)
		tones.resize(side * side + side * 4)
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
			if tilled:
				var tilth: Vector4 = ground_tilth(x, z)
				rows[index] = Vector2(tilth.x, tilth.y)
				tones[index] = Vector2(tilth.z, tilth.w)
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
			if tilled:
				rows[cursor] = rows[top]
				tones[cursor] = tones[top]
			cursor += 1
		for i: int in quads:
			var a: int = edges[edge][i]
			var b: int = edges[edge][i + 1]
			var c: int = start + i
			var d: int = start + i + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d, a, b, c, b, d, c]))
	var data: Dictionary = {"vertices": vertices, "normals": normals, "colors": colors, "indices": indices}
	if tilled:
		data["rows"] = rows
		data["tones"] = tones
	if with_collision:
		data["collision_heights"] = _collision_heights(heights, apron, quads)
	if with_scatter:
		data["scatter"] = _scatter(chunk, origin, pads, ramps, paths)
	if with_collision or with_meadow:
		data["meadow"] = _meadow(chunk, origin, pads, ramps, paths)
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


## How lush the meadow is at a spot, 0 (none) to 1: open, gently sloping
## ground above the shore. An island can grow less of it (a crag, a beach).
func _meadow_lushness(_x: float, _z: float, height: float, up: float) -> float:
	if height < 1.4 or up < 0.8:
		return 0.0
	return smoothstep(0.8, 0.92, up)


## A near landblock's meadow, cell by cell: [{"grass": Array of Transform3D,
## "colors": Array of Color (the ground's own colour at each tuft's root),
## "flowers": Array of [kind, Array of Transform3D]}]. Pure: a worker thread builds it.
func _meadow(chunk: Vector2i, origin: Vector2, pads: PackedFloat32Array, ramps: PackedFloat32Array, paths: PackedFloat32Array) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("meadow:%s:%d:%d" % [isle.isle_id, chunk.x, chunk.y])
	var size: float = IslandGridResource.CHUNK_SIZE
	var cell_size: float = size / float(MEADOW_CELLS)
	var cells: Array = []
	for index: int in MEADOW_CELLS * MEADOW_CELLS:
		var flowers: Array = []
		for kind: int in MEADOW_FLOWER_SHARES.size():
			flowers.append([])
		cells.append({"grass": [], "colors": [], "flowers": flowers})
	# Grass in clumps, thicker where the meadow runs lush (a slow field of patches).
	for clump: int in MEADOW_CLUMPS:
		var cx: float = origin.x + rng.randf() * size
		var cz: float = origin.y + rng.randf() * size
		var patch: float = 0.5 + 0.5 * _detail.get_noise_2d(cx * 0.9, cz * 0.9)
		var tufts: int = rng.randi_range(3, 5) + int(patch * 6.0)
		var reach: float = rng.randf_range(0.5, 1.3)
		for tuft: int in tufts:
			var x: float = cx + rng.randf_range(-reach, reach)
			var z: float = cz + rng.randf_range(-reach, reach)
			var yaw: float = rng.randf() * TAU
			var grow: float = rng.randf_range(0.75, 1.15) + patch * 0.45
			if not Rect2(origin, Vector2(size, size)).has_point(Vector2(x, z)):
				continue
			var placed: Dictionary = _meadow_spot(x, z, pads, ramps, paths)
			if placed.is_empty() or rng.randf() > float(placed["lush"]):
				continue
			var cell: Dictionary = cells[_meadow_cell(x - origin.x, z - origin.y, cell_size)]
			var style: Vector3 = placed["style"]
			# Standing grain is sown thick: a ripe tuft spreads half again as wide as a meadow's.
			var spread: float = grow * (1.0 + 0.5 * style.z)
			(cell["grass"] as Array).append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(spread, grow * rng.randf_range(0.85, 1.25) * style.x, spread)),
				Vector3(x, float(placed["h"]) - 0.03, z)))
			# An Array, not a PackedColorArray: a packed array read out of a Dictionary is a copy.
			# The colour's alpha tells the blade how green its tip ripens (0: straw to the tip, standing grain).
			var root: Color = placed["color"]
			root.a = 1.0 - style.z
			(cell["colors"] as Array).append(root)
	# Wildflowers in little drifts of one kind.
	var shares: Array[float] = meadow_flower_shares()
	for drift: int in MEADOW_FLOWER_CLUMPS:
		var cx: float = origin.x + rng.randf() * size
		var cz: float = origin.y + rng.randf() * size
		var pick: float = rng.randf()
		var kind: int = 0
		while kind < shares.size() - 1 and pick > shares[kind]:
			pick -= shares[kind]
			kind += 1
		for bloom: int in rng.randi_range(3, 9):
			var x: float = cx + rng.randf_range(-0.9, 0.9)
			var z: float = cz + rng.randf_range(-0.9, 0.9)
			if not Rect2(origin, Vector2(size, size)).has_point(Vector2(x, z)):
				continue
			var placed: Dictionary = _meadow_spot(x, z, pads, ramps, paths)
			if placed.is_empty() or float(placed["lush"]) < 0.5 or rng.randf() > (placed["style"] as Vector3).y:
				continue
			var grow: float = rng.randf_range(0.8, 1.25)
			var cell: Dictionary = cells[_meadow_cell(x - origin.x, z - origin.y, cell_size)]
			((cell["flowers"] as Array)[kind] as Array).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * grow),
				Vector3(x, float(placed["h"]) - 0.02, z)))
	return cells


## Whether the meadow grows at (x, z) and how: {"h", "lush", "color"}, or {} off it (a path, a cliff, the shore).
func _meadow_spot(x: float, z: float, pads: PackedFloat32Array, ramps: PackedFloat32Array, paths: PackedFloat32Array) -> Dictionary:
	if _path_weight(x, z, paths) > 0.05:
		return {}
	var h: float = _height(x, z, pads, ramps)
	var dx: float = _height(x + 0.6, z, pads, ramps) - _height(x - 0.6, z, pads, ramps)
	var dz: float = _height(x, z + 0.6, pads, ramps) - _height(x, z - 0.6, pads, ramps)
	var up: float = Vector3(-dx / 1.2, 1.0, -dz / 1.2).normalized().y
	var lush: float = _meadow_lushness(x, z, h, up)
	if lush <= 0.0:
		return {}
	return {"h": h, "lush": lush, "color": _paint(x, z, h, up, paths), "style": _meadow_style(x, z)}


static func _meadow_cell(local_x: float, local_z: float, cell_size: float) -> int:
	var column: int = clampi(int(local_x / cell_size), 0, MEADOW_CELLS - 1)
	var row: int = clampi(int(local_z / cell_size), 0, MEADOW_CELLS - 1)
	return row * MEADOW_CELLS + column


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
