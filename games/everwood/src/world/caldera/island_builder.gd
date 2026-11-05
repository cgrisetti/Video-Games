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
enum Species { ORCHARD_TREE, OAK_TREE, PINE_TREE, SNOW_PINE, REED_CLUMP, ROCK, BOULDER, BASALT_SPIRE, FERN_TUFT, ASH_TREE }
const SPECIES_COUNT: int = 10
## Trunk and stone radii that block the way inside the loaded window (0: walk through).
const SOLID_RADIUS: Array[float] = [0.3, 0.5, 0.35, 0.35, 0.0, 0.0, 0.9, 0.8, 0.0, 0.4]

## Landblock mesh resolutions: the loaded window (2 m) and the whole-island stand-in (8 m).
const NEAR_QUADS: int = 64
const FAR_QUADS: int = 16
## Collider samples per landblock side (every metre, the last shared with the next landblock).
const COLLISION_SIDE: int = 129
## Skirts hang this far below every landblock edge so neighbours of either resolution never show a crack.
const SKIRT_DEPTH: float = 6.0
## Scatter candidates a landblock rolls (each island keeps the share it wants).
const SCATTER_TRIES: int = 260

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

## How far out a spot lies on an elliptical coast (1 at the shore), its edge wandering by `wobble`.
func ellipse_q(x: float, z: float, center: Vector2, semi: Vector2, wobble: float) -> float:
	var q: float = Vector2((x - center.x) / semi.x, (z - center.y) / semi.y).length()
	return q * (1.0 + wobble * _noise.get_noise_2d(x * 0.6, z * 0.6))


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
