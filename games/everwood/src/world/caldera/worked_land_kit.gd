## The worked land's scatter (docs/32_EMBERSHORE_THE_WORKED_LAND.md §5, §6): the
## valley's other trees, the runs a field boundary is laid in, and what a field
## is left with. CalderaKit asks here for any species past the first fourteen:
## `stand_in` adds its one-draw far shape (vertex colours), `sculpt` its near
## mesh in the atelier's crafts and swaying foliage.
##
## A run (a hedge, a wall, a fence, a hurdle) is a piece a few metres long lying
## along +X, its middle at the origin and its foot on the ground: the builder
## sets them end to end along a boundary and tilts each to the slope. Trees keep
## the sightline contract (docs/17 §4.3): no leaf under 2.4 m.
class_name WorkedLandKit
extends RefCounted

const Species = IslandBuilder.Species
const Craft = ProceduralTextureAtelier.Set

## A run's length along a boundary (hedges, walls and fences) and a hurdle's.
const RUN_LENGTH: float = 3.2
const HURDLE_LENGTH: float = 2.4
## How far a full crown's under-dome hangs below its middle, as a share of its radius (the crown's middle is set
## this far over the combat sightline, so no leaf comes under it).
const UNDER_CROWN: float = 0.62
## A crown is a handful of big lobes, not a score of small ones: a field tree is seen across a field, four to a screen.
const UNDER_LOBES: int = 4
## Corners round a far pad of needles (`_far_pad`).
const PAD_SIDES: int = 5
## A hedge stands chest-high and a wall knee-high (docs/17 §2.1: 0.9 m at most, so a hero hops it).
const HEDGE_HEIGHT: float = 1.3
const WALL_HEIGHT: float = 0.8
## A field gate's opening between its posts.
const GATE_WIDTH: float = 3.4

const FIELDSTONE: Color = Color(0.6, 0.58, 0.54)
const SILVER_TIMBER: Color = Color(0.55, 0.52, 0.47)
const STRAW: Color = Color(0.74, 0.64, 0.4)
const HAWTHORN_DARK: Color = Color(0.15, 0.29, 0.14)
const HAWTHORN_LIGHT: Color = Color(0.37, 0.54, 0.24)

const TREES: Array[int] = [Species.ORCHARD_TREE, Species.OAK_TREE, Species.PINE_TREE, Species.SNOW_PINE, Species.ASH_TREE, Species.WILLOW_TREE,
	Species.ROWAN_TREE, Species.FIELD_OAK, Species.FIELD_ASH, Species.SCOTS_PINE, Species.BEECH_TREE, Species.ELM_TREE, Species.CHESTNUT_TREE, Species.BIRCH_TREE, Species.POPLAR_TREE, Species.HAWTHORN_TREE,
	Species.ALDER_TREE, Species.POLLARD_WILLOW, Species.PLUM_TREE, Species.PEAR_TREE, Species.YEW_TREE, Species.HOLLY_TREE]
## The worked land's own trees (each sculpted here).
const NEW_TREES: Array[int] = [Species.FIELD_OAK, Species.FIELD_ASH, Species.BEECH_TREE, Species.ELM_TREE, Species.CHESTNUT_TREE, Species.BIRCH_TREE, Species.POPLAR_TREE,
	Species.HAWTHORN_TREE, Species.ALDER_TREE, Species.POLLARD_WILLOW, Species.PLUM_TREE, Species.PEAR_TREE, Species.YEW_TREE, Species.HOLLY_TREE]
## Small things: sculpted near, gone past their reach, no stand-in and no shadow.
const SMALL: Array[int] = [Species.CROP_ROW, Species.BEAN_ROW, Species.BRAMBLE_BUSH, Species.STILE, Species.TROUGH, Species.SCARECROW, Species.FIELD_GATE,
	Species.HURDLE_RUN]
## A run's sculpted mesh hands over to its stand-in sooner than a tree's does (a hedge is low and there are miles of it).
const RUNS: Array[int] = [Species.HEDGE_RUN, Species.HEDGE_BLOOM, Species.WALL_RUN, Species.WALL_TUMBLE, Species.FENCE_RUN, Species.HURDLE_RUN,
	Species.FIELD_GATE, Species.STILE, Species.HAYCOCK, Species.STOOK, Species.TROUGH, Species.SCARECROW]
## Each is measured from a landblock's middle to a camera (ArchipelagoStreamer._add_scatter), so every run and
## tree of the landblocks about a hero is sculpted and no stand-in shows nearer than about 40 m (a hedge) or 64 m (a tree).
const RUN_HANDOVER: float = 96.0
## Past this a landblock's far runs aren't drawn at all (a hedge half a mile off is under a pixel tall).
const RUN_REACH: float = 720.0
const TREE_HANDOVER: float = 128.0
## A sculpted tree throws no shadow of its own (its triangles would be drawn again for every split of the sun's
## shadow, in every hero's view): the landblock's stand-ins throw it instead, drawn this much smaller so the
## sculpted crown stands clear of them in the light.
const SHADOW_PROXY: Vector3 = Vector3(0.78, 0.95, 0.78)
## The kinds whose far stand-ins are merged, a landblock at a time, into one mesh for the trees and one for the rest.
const MERGED_FAR: Array[int] = [Species.FIELD_OAK, Species.FIELD_ASH, Species.SCOTS_PINE, Species.BEECH_TREE, Species.ELM_TREE, Species.CHESTNUT_TREE, Species.BIRCH_TREE, Species.POPLAR_TREE,
	Species.HAWTHORN_TREE, Species.ALDER_TREE, Species.POLLARD_WILLOW, Species.PLUM_TREE, Species.PEAR_TREE, Species.YEW_TREE, Species.HOLLY_TREE,
	Species.HEDGE_RUN, Species.HEDGE_BLOOM, Species.WALL_RUN, Species.WALL_TUMBLE, Species.FENCE_RUN, Species.HAYCOCK, Species.STOOK]
## How far each is drawn (metres; the rest are drawn at any distance).
const REACH: Dictionary[int, float] = {Species.CROP_ROW: 100.0, Species.BEAN_ROW: 130.0, Species.BRAMBLE_BUSH: 160.0, Species.STOOK: 420.0,
	Species.HAYCOCK: 620.0, Species.TROUGH: 120.0, Species.SCARECROW: 200.0, Species.STILE: 120.0, Species.FIELD_GATE: 170.0,
	Species.HURDLE_RUN: 150.0, Species.FENCE_RUN: 520.0}
const NO_SHADOW: Array[int] = [Species.CROP_ROW, Species.BEAN_ROW, Species.BRAMBLE_BUSH, Species.STILE, Species.TROUGH, Species.HURDLE_RUN, Species.HEDGE_RUN,
	Species.HEDGE_BLOOM, Species.FENCE_RUN, Species.STOOK, Species.HAYCOCK, Species.FIELD_GATE, Species.SCARECROW, Species.WALL_RUN, Species.WALL_TUMBLE]

## Each tree's leaves, dark below and light above.
const LEAVES: Dictionary[int, Array] = {
	Species.FIELD_OAK: [Color(0.2, 0.37, 0.18), Color(0.47, 0.63, 0.29)],
	Species.FIELD_ASH: [Color(0.3, 0.44, 0.22), Color(0.6, 0.7, 0.4)],
	Species.SCOTS_PINE: [Color(0.1, 0.22, 0.16), Color(0.26, 0.4, 0.26)],
	Species.BEECH_TREE: [Color(0.24, 0.4, 0.16), Color(0.62, 0.72, 0.3)],
	Species.ELM_TREE: [Color(0.16, 0.32, 0.16), Color(0.4, 0.58, 0.26)],
	Species.CHESTNUT_TREE: [Color(0.18, 0.36, 0.14), Color(0.46, 0.64, 0.26)],
	Species.BIRCH_TREE: [Color(0.36, 0.5, 0.22), Color(0.72, 0.8, 0.42)],
	Species.POPLAR_TREE: [Color(0.22, 0.4, 0.18), Color(0.5, 0.66, 0.3)],
	Species.HAWTHORN_TREE: [Color(0.2, 0.36, 0.18), Color(0.42, 0.58, 0.28)],
	Species.ALDER_TREE: [Color(0.14, 0.3, 0.16), Color(0.3, 0.5, 0.24)],
	Species.POLLARD_WILLOW: [Color(0.36, 0.48, 0.26), Color(0.66, 0.74, 0.42)],
	Species.PLUM_TREE: [Color(0.24, 0.4, 0.22), Color(0.48, 0.62, 0.34)],
	Species.PEAR_TREE: [Color(0.26, 0.42, 0.2), Color(0.54, 0.68, 0.32)],
	Species.YEW_TREE: [Color(0.07, 0.16, 0.1), Color(0.16, 0.3, 0.18)],
	Species.HOLLY_TREE: [Color(0.08, 0.2, 0.1), Color(0.2, 0.4, 0.2)],
}

static var _dots: Array = []


static func is_tree(species: int) -> bool:
	return TREES.has(species)


# --- Far stand-ins ---------------------------------------------------------------------------------------

## A species' one-draw stand-in, added to `into` (foot at the origin). False for a species that isn't the worked land's.
static func stand_in(species: int, into: LandblockTerrain.MeshMerge) -> bool:
	var leaf: Color = Color.WHITE
	if LEAVES.has(species):
		leaf = (LEAVES[species][0] as Color).lerp(LEAVES[species][1], 0.6)
	match species:
		Species.FIELD_OAK:
			# A field oak: a short, thick bole under a broad round head, wider than it is tall.
			_far_tree(into, 0.5, 3.6, Color(0.4, 0.31, 0.23), Vector3(0.0, 6.4, 0.0), Vector3(4.6, 3.5, 4.6), leaf)
			_far_ball(into, Vector3(2.3, 5.5, 1.0), Vector3(2.4, 1.9, 2.4), leaf.darkened(0.12))
		Species.FIELD_ASH:
			_far_tree(into, 0.3, 5.2, Color(0.52, 0.5, 0.45), Vector3(0.0, 7.0, 0.0), Vector3(2.9, 3.4, 2.9), leaf)
		Species.SCOTS_PINE:
			# A Scots pine: a long bare stem, ruddy toward the top, forking under a flat dark head with a lighter crest.
			# It is this shape at every distance (as the rowan is): its stands are a hundred trees to a landblock.
			into.add_cylinder(Vector3(0.0, 4.2, 0.0), 0.18, 0.34, 8.4, Color(0.5, 0.31, 0.22), 5)
			var dark: Color = LEAVES[species][0]
			var light: Color = LEAVES[species][1]
			# Three pads of needles, each a low dome that leans its own way, so no two heads in a stand sit alike.
			_far_pad(into, Vector3(0.3, 8.0, 0.0), Vector3(3.0, 1.7, 2.7), Vector3(0.12, 0.0, 0.06), dark, dark.lerp(light, 0.7))
			_far_pad(into, Vector3(-1.2, 9.0, -0.7), Vector3(1.9, 1.3, 1.8), Vector3(-0.1, 1.1, -0.16), dark.lerp(light, 0.15), light)
			_far_pad(into, Vector3(1.3, 9.2, 1.0), Vector3(1.5, 1.05, 1.4), Vector3(0.14, 2.3, 0.12), dark.lerp(light, 0.1), light.lightened(0.05))
		Species.BEECH_TREE:
			_far_tree(into, 0.4, 5.0, Color(0.52, 0.52, 0.48), Vector3(0.0, 7.2, 0.0), Vector3(3.6, 3.4, 3.6), leaf)
		Species.ELM_TREE:
			_far_tree(into, 0.35, 5.6, Color(0.38, 0.32, 0.26), Vector3(0.0, 8.0, 0.0), Vector3(2.7, 4.2, 2.7), leaf)
		Species.CHESTNUT_TREE:
			_far_tree(into, 0.48, 4.0, Color(0.4, 0.33, 0.26), Vector3(0.0, 6.6, 0.0), Vector3(4.2, 3.6, 4.2), leaf)
			_far_ball(into, Vector3(0.4, 9.2, 0.2), Vector3(1.6, 0.9, 1.6), Color(0.86, 0.9, 0.7))
		Species.BIRCH_TREE:
			_far_tree(into, 0.13, 5.4, Color(0.9, 0.9, 0.86), Vector3(0.0, 6.2, 0.0), Vector3(1.7, 2.6, 1.7), leaf)
		Species.POPLAR_TREE:
			_far_tree(into, 0.27, 4.0, Color(0.44, 0.4, 0.34), Vector3(0.0, 8.8, 0.0), Vector3(1.5, 5.6, 1.5), leaf)
		Species.HAWTHORN_TREE:
			# In blossom: its head is paler than its leaf from far off.
			_far_tree(into, 0.16, 3.0, Color(0.36, 0.3, 0.24), Vector3(0.0, 4.4, 0.0), Vector3(1.8, 1.6, 1.8), leaf.lerp(Color(0.97, 0.96, 0.92), 0.38))
		Species.ALDER_TREE:
			_far_tree(into, 0.26, 4.0, Color(0.3, 0.27, 0.24), Vector3(0.0, 6.4, 0.0), Vector3(2.1, 3.6, 2.1), leaf)
		Species.POLLARD_WILLOW:
			_far_tree(into, 0.5, 3.0, Color(0.42, 0.36, 0.28), Vector3(0.0, 4.7, 0.0), Vector3(2.0, 1.9, 2.0), leaf)
		Species.PLUM_TREE:
			_far_tree(into, 0.17, 3.2, CalderaKit.TIMBER, Vector3(0.0, 4.3, 0.0), Vector3(1.7, 1.5, 1.7), leaf.lerp(Color(0.46, 0.24, 0.5), 0.14))
		Species.PEAR_TREE:
			_far_tree(into, 0.18, 3.3, CalderaKit.TIMBER, Vector3(0.0, 4.8, 0.0), Vector3(1.4, 2.0, 1.4), leaf.lerp(Color(0.82, 0.78, 0.32), 0.14))
		Species.YEW_TREE:
			_far_tree(into, 0.62, 3.2, Color(0.4, 0.27, 0.22), Vector3(0.0, 4.8, 0.0), Vector3(3.3, 2.5, 3.3), leaf)
		Species.HOLLY_TREE:
			_far_tree(into, 0.16, 2.9, Color(0.4, 0.38, 0.34), Vector3(0.0, 4.5, 0.0), Vector3(1.3, 2.1, 1.3), leaf)
		Species.HEDGE_RUN, Species.HEDGE_BLOOM:
			# Far off a hedge is a line across a field: one long low lump a run (there are three thousand in a view),
			# paler along its top where the blossom is.
			var green: Color = HAWTHORN_DARK.lerp(HAWTHORN_LIGHT, 0.5 if species == Species.HEDGE_RUN else 0.72)
			_far_loaf(into, Vector3(RUN_LENGTH * 1.04, HEDGE_HEIGHT * 0.96, 1.0), 0.5, green.darkened(0.12), green.lightened(0.06))
		Species.WALL_RUN:
			_far_loaf(into, Vector3(RUN_LENGTH, WALL_HEIGHT, 0.56), 0.8, FIELDSTONE.darkened(0.08), FIELDSTONE.lightened(0.06))
		Species.WALL_TUMBLE:
			_far_loaf(into, Vector3(2.2, 0.44, 0.7), 0.7, FIELDSTONE.darkened(0.14), FIELDSTONE.darkened(0.02))
		Species.FENCE_RUN:
			CalderaKit.add_box(into, Vector3(0.0, 0.78, 0.0), Vector3(RUN_LENGTH, 0.1, 0.06), SILVER_TIMBER.lightened(0.06))
		Species.HURDLE_RUN:
			CalderaKit.add_box(into, Vector3(0.0, 0.42, 0.0), Vector3(HURDLE_LENGTH, 0.72, 0.07), Color(0.52, 0.42, 0.28))
			for x: float in [-HURDLE_LENGTH * 0.5, HURDLE_LENGTH * 0.5]:
				CalderaKit.add_box(into, Vector3(x, 0.46, 0.0), Vector3(0.07, 0.92, 0.07), Color(0.4, 0.31, 0.2))
		Species.FIELD_GATE:
			for side: float in [-1.0, 1.0]:
				CalderaKit.add_box(into, Vector3(side * (GATE_WIDTH * 0.5 + 0.18), 0.62, 0.0), Vector3(0.34, 1.24, 0.34), FIELDSTONE.lightened(0.05))
			# The gate stands open, swung back from its hinge post.
			CalderaKit.add_box(into, Vector3(-GATE_WIDTH * 0.5 + 0.2, 0.62, 1.5), Vector3(0.08, 0.95, 3.0), SILVER_TIMBER)
		Species.STILE:
			for side: float in [-1.0, 1.0]:
				CalderaKit.add_box(into, Vector3(side * 0.42, 0.5, 0.0), Vector3(0.14, 1.0, 0.56), FIELDSTONE.lightened(0.04))
			CalderaKit.add_box(into, Vector3(0.0, 0.16, 0.0), Vector3(0.6, 0.32, 0.9), FIELDSTONE.darkened(0.06))
		Species.HAYCOCK:
			CalderaKit.add_cone(into, Vector3.ZERO, 1.0, 1.7, STRAW, 5)
		Species.STOOK:
			CalderaKit.add_cone(into, Vector3.ZERO, 0.52, 1.4, Color(0.78, 0.64, 0.3), 4)
		Species.TROUGH:
			CalderaKit.add_box(into, Vector3(0.0, 0.26, 0.0), Vector3(1.8, 0.52, 0.62), FIELDSTONE.darkened(0.04))
			CalderaKit.add_box(into, Vector3(0.0, 0.5, 0.0), Vector3(1.56, 0.04, 0.4), Color(0.2, 0.32, 0.38))
		Species.SCARECROW:
			CalderaKit.add_box(into, Vector3(0.0, 0.95, 0.0), Vector3(0.09, 1.9, 0.09), SILVER_TIMBER.darkened(0.2))
			CalderaKit.add_box(into, Vector3(0.0, 1.45, 0.0), Vector3(1.5, 0.08, 0.08), SILVER_TIMBER.darkened(0.2))
			CalderaKit.add_box(into, Vector3(0.0, 1.2, 0.0), Vector3(0.6, 0.72, 0.24), Color(0.36, 0.42, 0.54))
			CalderaKit.add_sphere(into, Vector3(0.0, 1.82, 0.0), 0.2, Color(0.76, 0.66, 0.48), 1.0, 6)
			CalderaKit.add_cone(into, Vector3(0.0, 1.94, 0.0), 0.34, 0.36, Color(0.34, 0.26, 0.2), 7)
		_:
			return false
	return true


## A far run in ten triangles: a loaf lying along +X (two leaning sides, a narrower top, two ends), `size` long,
## high and thick at its foot, `taper` as wide at its top; darker below than above.
static func _far_loaf(into: LandblockTerrain.MeshMerge, size: Vector3, taper: float, low: Color, high: Color) -> void:
	var half: Vector3 = size * 0.5
	var top: float = half.z * taper
	var corners: Array[Vector3] = [Vector3(-half.x, 0.0, -half.z), Vector3(half.x, 0.0, -half.z), Vector3(half.x, 0.0, half.z), Vector3(-half.x, 0.0, half.z),
		Vector3(-half.x, size.y, -top), Vector3(half.x, size.y, -top), Vector3(half.x, size.y, top), Vector3(-half.x, size.y, top)]
	# Each face: its four corners (wound to face out) and whether it is the top.
	var faces: Array[PackedInt32Array] = [PackedInt32Array([3, 2, 6, 7]), PackedInt32Array([1, 0, 4, 5]), PackedInt32Array([7, 6, 5, 4]),
		PackedInt32Array([0, 3, 7, 4]), PackedInt32Array([2, 1, 5, 6])]
	for face: PackedInt32Array in faces:
		var a: Vector3 = corners[face[0]]
		var b: Vector3 = corners[face[1]]
		var c: Vector3 = corners[face[2]]
		var d: Vector3 = corners[face[3]]
		var normal: Vector3 = (c - a).cross(b - a).normalized()
		for point: Vector3 in [a, b, c, a, c, d]:
			into.vertices.append(point)
			into.normals.append(normal)
			into.colors.append(low.lerp(high, clampf(point.y / maxf(size.y, 0.01), 0.0, 1.0)))


## A far tree in two shapes: a five-sided bole to `tall` and one faceted head. A valley's worth of them is in every view.
static func _far_tree(into: LandblockTerrain.MeshMerge, girth: float, tall: float, bark: Color, head_at: Vector3, head: Vector3, leaf: Color) -> void:
	into.add_cylinder(Vector3(0.0, tall * 0.5, 0.0), girth * 0.6, girth, tall, bark, 5)
	_far_ball(into, head_at, head, leaf)


## A far pad of needles in twenty triangles: a five-sided dome over a shallow hollow underside, `radii` wide and
## high, turned by `lean` (radians about x, y and z), dark beneath and light on top.
static func _far_pad(into: LandblockTerrain.MeshMerge, at: Vector3, radii: Vector3, lean: Vector3, low: Color, high: Color) -> void:
	var frame: Transform3D = Transform3D(Basis.from_euler(lean) * Basis.from_scale(radii), at)
	var apex: Vector3 = frame * Vector3(0.0, 1.0, 0.0)
	var under: Vector3 = frame * Vector3(0.0, -0.22, 0.0)
	var shoulder: Array[Vector3] = []
	var rim: Array[Vector3] = []
	for index: int in PAD_SIDES:
		var turn: float = TAU * float(index) / float(PAD_SIDES)
		# Every other corner stands a little further out, so the rim isn't a ruled pentagon.
		var reach: float = 1.0 if index % 2 == 0 else 0.86
		shoulder.append(frame * Vector3(cos(turn) * 0.64 * reach, 0.62, sin(turn) * 0.64 * reach))
		rim.append(frame * Vector3(cos(turn) * reach, 0.0, sin(turn) * reach))
	var middle: Vector3 = frame * Vector3(0.0, 0.3, 0.0)
	for index: int in PAD_SIDES:
		var next: int = (index + 1) % PAD_SIDES
		_far_face(into, middle, [apex, shoulder[index], shoulder[next]], [high, high, high])
		_far_face(into, middle, [shoulder[index], rim[index], rim[next]], [high, low.lerp(high, 0.35), low.lerp(high, 0.35)])
		_far_face(into, middle, [shoulder[index], rim[next], shoulder[next]], [high, low.lerp(high, 0.35), high])
		_far_face(into, middle, [under, rim[next], rim[index]], [low.darkened(0.25), low, low])


## One flat triangle of a far shape, wound and lit to face away from `middle`.
static func _far_face(into: LandblockTerrain.MeshMerge, middle: Vector3, corners: Array[Vector3], tints: Array[Color]) -> void:
	var order: PackedInt32Array = PackedInt32Array([0, 1, 2])
	var normal: Vector3 = (corners[2] - corners[0]).cross(corners[1] - corners[0]).normalized()
	if normal.dot((corners[0] + corners[1] + corners[2]) / 3.0 - middle) < 0.0:
		order = PackedInt32Array([0, 2, 1])
		normal = -normal
	for index: int in order:
		into.vertices.append(corners[index])
		into.normals.append(normal)
		into.colors.append(tints[index])


static func _far_ball(into: LandblockTerrain.MeshMerge, at: Vector3, radii: Vector3, color: Color) -> void:
	var ball: SphereMesh = SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 5
	ball.rings = 2
	into.add_arrays(ball.get_mesh_arrays(), Transform3D(Basis.from_scale(radii), at), color)


# --- Sculpted near meshes --------------------------------------------------------------------------------

## A species' near mesh, added to `parts`. False for a species that isn't the worked land's (or has none).
static func sculpt(species: int, parts: WorldAssetCatalog.Parts) -> bool:
	match species:
		Species.FIELD_OAK:
			_broadleaf(parts, species, 10.0, 0.66, 4, 9, Vector3(1.28, 0.9, 1.28), WorldAssetCatalog.BARK, 37, 0.4)
		Species.FIELD_ASH:
			_broadleaf(parts, species, 10.4, 0.36, 3, 7, Vector3(0.92, 1.16, 0.92), Color(0.52, 0.5, 0.45), 39, 0.34)
		Species.BEECH_TREE:
			_broadleaf(parts, species, 11.0, 0.5, 4, 9, Vector3(1.08, 1.0, 1.08), Color(0.5, 0.5, 0.46), 41, 0.38)
		Species.ELM_TREE:
			_broadleaf(parts, species, 12.0, 0.44, 3, 8, Vector3(0.82, 1.34, 0.82), WorldAssetCatalog.BARK, 43, 0.34)
		Species.CHESTNUT_TREE:
			var crown: Vector3 = _broadleaf(parts, species, 10.0, 0.62, 4, 9, Vector3(1.2, 0.92, 1.2), WorldAssetCatalog.BARK, 47, 0.4)
			_dot_crown(parts, crown + Vector3(0.0, 1.2, 0.0), 4.2, 10, Vector3(0.11, 0.3, 0.11), [Color(0.97, 0.95, 0.85)], 4701, true)
		Species.BIRCH_TREE:
			_broadleaf(parts, species, 8.6, 0.2, 3, 7, Vector3(0.74, 1.2, 0.74), Color(0.9, 0.89, 0.84), 53, 0.34)
		Species.POPLAR_TREE:
			_poplar(parts)
		Species.ALDER_TREE:
			_broadleaf(parts, species, 9.4, 0.34, 3, 7, Vector3(0.78, 1.3, 0.78), Color(0.28, 0.25, 0.22), 59, 0.34)
		Species.YEW_TREE:
			var crown: Vector3 = _broadleaf(parts, species, 7.6, 0.72, 4, 9, Vector3(1.3, 0.8, 1.3), Color(0.42, 0.26, 0.2), 61, 0.42)
			_dot_crown(parts, crown, 3.4, 8, Vector3.ONE * 0.07, [Color(0.82, 0.14, 0.12)], 6101, false)
		Species.HAWTHORN_TREE:
			_small_tree(parts, species, 4.9, 0.2, Vector3.ONE, [Color(0.98, 0.97, 0.94), Color(0.97, 0.86, 0.88)], 16, 0.09, 67)
		Species.PLUM_TREE:
			_small_tree(parts, species, 4.7, 0.2, Vector3.ONE, [Color(0.42, 0.2, 0.48), Color(0.56, 0.3, 0.56)], 12, 0.1, 71)
		Species.PEAR_TREE:
			_small_tree(parts, species, 5.6, 0.22, Vector3(0.8, 1.2, 0.8), [Color(0.82, 0.78, 0.3), Color(0.7, 0.74, 0.3)], 10, 0.11, 73)
		Species.HOLLY_TREE:
			_small_tree(parts, species, 5.0, 0.18, Vector3(0.76, 1.22, 0.76), [Color(0.84, 0.14, 0.12)], 12, 0.06, 79)
		Species.POLLARD_WILLOW:
			_pollard(parts)
		Species.HEDGE_RUN:
			_hedge(parts, false)
		Species.HEDGE_BLOOM:
			_hedge(parts, true)
		Species.WALL_RUN:
			_wall(parts, false)
		Species.WALL_TUMBLE:
			_wall(parts, true)
		Species.FENCE_RUN:
			_fence(parts)
		Species.HURDLE_RUN:
			_hurdle(parts)
		Species.FIELD_GATE:
			_gate(parts)
		Species.STILE:
			_stile(parts)
		Species.HAYCOCK:
			_haycock(parts)
		Species.STOOK:
			_stook(parts)
		Species.CROP_ROW:
			_crop_row(parts)
		Species.BEAN_ROW:
			_bean_row(parts)
		Species.BRAMBLE_BUSH:
			_bramble(parts)
		Species.TROUGH:
			_trough(parts)
		Species.SCARECROW:
			_scarecrow(parts)
		_:
			return false
	return true


static func _bark(tint: Color) -> Material:
	return WorldVisualCatalog.craft(Craft.HEWN_TIMBER, tint, true, 0.3)


## A broadleaf like CalderaKit's (a gnarled trunk forking above the sightline under a leaf-cloud
## crown), its crown stretched by `shape` about its own middle and its bark tinted. Returns the crown's middle.
static func _broadleaf(parts: WorldAssetCatalog.Parts, species: int, tall: float, girth: float, boughs: int, lobes: int, shape: Vector3,
		bark: Color, seed_value: int, spread: float = 0.3) -> Vector3:
	var leaves: Array = LEAVES[species]
	var trunk: ArrayMesh = ShapeKit.make_gnarled_trunk_mesh(tall * 0.62, girth, girth * 0.42, boughs, seed_value)
	parts.add_mesh(trunk, Transform3D.IDENTITY, [_bark(bark)])
	var crown_at: Vector3 = trunk.get_meta(ShapeKit.META_CROWN_CENTER) as Vector3
	var radius: float = tall * spread
	# The crown comes down round the boughs as low as the combat sightline lets it: an open-grown tree, not a
	# pole with a tuft. Its lowest leaf still stays over a hero's head.
	crown_at.y = ZoneBiomeResource.MAX_OBSTACLE_SIGHTLINE_M + radius * shape.y * UNDER_CROWN + 0.1
	var canopy: Material = WorldVisualCatalog.canopy(Color.WHITE, tall, 0.16, true)
	_full_crown(parts, crown_at, radius, lobes, shape, leaves, seed_value, canopy)
	return crown_at


## A whole crown: ShapeKit's leaf-cloud dome above, and a shallower dome of the same leaf hung under it
## (darker toward its foot), so the tree is round all the way down instead of a flat-bottomed umbrella.
static func _full_crown(parts: WorldAssetCatalog.Parts, at: Vector3, radius: float, lobes: int, shape: Vector3, leaves: Array, seed_value: int,
		canopy: Material, under_lobes: int = UNDER_LOBES) -> void:
	var dark: Color = leaves[0]
	var light: Color = leaves[1]
	var upper: ArrayMesh = ShapeKit.make_leaf_cloud_crown(Vector3.ZERO, radius, lobes, seed_value, dark.lerp(light, 0.3), light, 0, 1.6, lobes)
	parts.add_mesh(upper, Transform3D(Basis.from_scale(shape), at), [canopy])
	# Turned over (a half turn, so its faces still face out): what was its sunlit top is now the crown's shaded foot.
	var under: ArrayMesh = ShapeKit.make_leaf_cloud_crown(Vector3.ZERO, radius * 0.92, under_lobes, seed_value + 17, dark.lerp(light, 0.3), dark.darkened(0.12), 0, 1.6,
		under_lobes)
	parts.add_mesh(under, Transform3D(Basis(Vector3.RIGHT, PI) * Basis.from_scale(Vector3(shape.x, shape.y * 0.52, shape.z)), at + Vector3(0.0, radius * shape.y * 0.1, 0.0)),
		[canopy])


## A small tree (a thorn, a plum, a pear, a holly): a short forked trunk under a round crown dotted with blossom or fruit.
static func _small_tree(parts: WorldAssetCatalog.Parts, species: int, tall: float, girth: float, shape: Vector3, dots: Array, dot_count: int,
		dot_size: float, seed_value: int) -> void:
	var leaves: Array = LEAVES[species]
	var trunk: ArrayMesh = ShapeKit.make_gnarled_trunk_mesh(maxf(3.6, tall * 0.72), girth, girth * 0.5, 3, seed_value)
	parts.add_mesh(trunk, Transform3D.IDENTITY, [_bark(WorldAssetCatalog.BARK.lerp(Color(0.4, 0.38, 0.34), 0.4))])
	var radius: float = tall * 0.36
	var crown_at: Vector3 = (trunk.get_meta(ShapeKit.META_CROWN_CENTER) as Vector3) + Vector3(0.0, 0.3, 0.0)
	crown_at.y = maxf(crown_at.y, ZoneBiomeResource.MAX_OBSTACLE_SIGHTLINE_M + radius * 0.9 * shape.y * UNDER_CROWN + 0.1)
	var canopy: Material = WorldVisualCatalog.canopy(Color.WHITE, tall, 0.18, true)
	_full_crown(parts, crown_at, radius * 0.9, 6, shape, leaves, seed_value, canopy, 3)
	_dot_crown(parts, crown_at, radius * 0.86, dot_count, Vector3.ONE * dot_size, dots, seed_value * 9 + 1, false, shape)


## Blossom, fruit or berries on a crown's skin: `count` dots in `colors`, on its upper half only when `top`.
static func _dot_crown(parts: WorldAssetCatalog.Parts, center: Vector3, radius: float, count: int, size: Vector3, colors: Array, seed_value: int,
		top: bool, shape: Vector3 = Vector3.ONE) -> void:
	var canopy: Material = WorldVisualCatalog.canopy(Color.WHITE, 6.0, 0.16, true)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for index: int in count:
		var direction: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.25 if top else -0.2, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		parts.add_arrays(_dot_arrays(), Transform3D(Basis.from_scale(size), center + direction * shape * radius * 0.95), canopy, colors[index % colors.size()])


## A poplar: a straight stem under a tall, narrow flame of leaves (the valley's line-tree).
static func _poplar(parts: WorldAssetCatalog.Parts) -> void:
	var tall: float = 14.0
	var leaves: Array = LEAVES[Species.POPLAR_TREE]
	parts.add_mesh(ShapeKit.make_gnarled_trunk_mesh(tall * 0.8, 0.34, 0.1, 0, 83), Transform3D.IDENTITY, [_bark(Color(0.44, 0.4, 0.34))])
	var canopy: Material = WorldVisualCatalog.canopy(Color.WHITE, tall, 0.22, true)
	var crown: ArrayMesh = ShapeKit.make_leaf_cloud_crown(Vector3.ZERO, 2.5, 8, 83, leaves[0], leaves[1], 0, 1.6, 8)
	parts.add_mesh(crown, Transform3D(Basis.from_scale(Vector3(0.62, 2.35, 0.62)), Vector3(0.0, 8.9, 0.0)), [canopy])


## A pollard willow: a stout, knuckled bole cut at head height, a shock of whippy shoots above it.
static func _pollard(parts: WorldAssetCatalog.Parts) -> void:
	var leaves: Array = LEAVES[Species.POLLARD_WILLOW]
	var bark: Material = _bark(Color(0.42, 0.36, 0.28))
	parts.add_mesh(ShapeKit.make_gnarled_trunk_mesh(3.3, 0.56, 0.44, 0, 89), Transform3D.IDENTITY, [bark])
	parts.sphere(0.6, Vector3(0.0, 3.2, 0.0), bark, Vector3(1.0, 0.72, 1.0), 8)
	var canopy: Material = WorldVisualCatalog.canopy(Color.WHITE, 6.0, 0.34, true)
	# Shoots: thin blades fanning up and out from the knuckle, then a light crown over them.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8901
	for shoot: int in 10:
		var angle: float = TAU * float(shoot) / 10.0 + rng.randf_range(-0.15, 0.15)
		var lean: float = rng.randf_range(0.25, 0.8)
		var tip: Vector3 = Vector3(cos(angle) * lean * 2.2, 3.4 + rng.randf_range(1.6, 2.6), sin(angle) * lean * 2.2)
		parts.blade(Vector3(cos(angle) * 0.3, 3.4, sin(angle) * 0.3), tip, 0.2, leaves[0], leaves[1], canopy)
	parts.add_mesh(ShapeKit.make_leaf_cloud_crown(Vector3.ZERO, 1.9, 7, 89, leaves[0], leaves[1], 0, 1.6, 7),
		Transform3D(Basis.from_scale(Vector3(1.0, 0.72, 1.0)), Vector3(0.0, 5.0, 0.0)), [canopy])


## A laid hawthorn hedge, 3.2 m of it: woody stems at its foot, a lumpy wall of leaves that leans
## from heroes pushing through, may blossom and dog-rose on the blooming kind.
static func _hedge(parts: WorldAssetCatalog.Parts, bloom: bool) -> void:
	var leaf: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.6, 0.06, 0.45)
	var wood: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.34, 0.27, 0.2))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9100 + int(bloom)
	for stem: int in 2:
		var x: float = lerpf(-RUN_LENGTH * 0.3, RUN_LENGTH * 0.3, float(stem))
		parts.beam(Vector3(x, -0.1, rng.randf_range(-0.1, 0.1)), Vector3(x + rng.randf_range(0.3, 0.6), 0.62, rng.randf_range(-0.12, 0.12)), 0.09, wood)
	# Its dark heart, so no daylight shows through between the leaves.
	parts.add_arrays(WorldAssetCatalog.primitive_arrays("box", func() -> PrimitiveMesh: return BoxMesh.new()),
		Transform3D(Basis.from_scale(Vector3(RUN_LENGTH * 0.84, HEDGE_HEIGHT - 0.5, 0.56)), Vector3(0.0, (HEDGE_HEIGHT - 0.5) * 0.5, 0.0)), leaf, HAWTHORN_DARK.darkened(0.2))
	# Six faceted lumps of leaf, each its own size and turned its own way, from the grass to chest height: a hedge
	# is clipped, and there are a hundred runs of it about a hero, so it is a couple of hundred triangles.
	for lump: int in 6:
		var x: float = lerpf(-RUN_LENGTH * 0.5 + 0.3, RUN_LENGTH * 0.5 - 0.3, float(lump) / 5.0) + rng.randf_range(-0.08, 0.08)
		var radii: Vector3 = Vector3(rng.randf_range(0.5, 0.64), rng.randf_range(0.5, 0.66), rng.randf_range(0.46, 0.58))
		var high: bool = lump % 2 == 0
		_leaf_lump(parts, Vector3(x, (HEDGE_HEIGHT - radii.y * 0.96) if high else radii.y * 0.72, rng.randf_range(-0.07, 0.07) + (0.0 if high else (0.16 if lump % 4 == 1 else -0.16))),
			radii, rng.randf() * TAU, HAWTHORN_DARK if high else HAWTHORN_DARK.darkened(0.1), HAWTHORN_LIGHT if high else HAWTHORN_DARK.lerp(HAWTHORN_LIGHT, 0.6), leaf)
	# A whip or two grown out of the top since it was last laid.
	for whip: int in 2:
		var x: float = rng.randf_range(-RUN_LENGTH * 0.4, RUN_LENGTH * 0.4)
		parts.blade(Vector3(x, HEDGE_HEIGHT - 0.3, 0.0), Vector3(x + rng.randf_range(-0.2, 0.2), HEDGE_HEIGHT + rng.randf_range(0.2, 0.5), rng.randf_range(-0.15, 0.15)), 0.16,
			HAWTHORN_DARK, HAWTHORN_LIGHT.lightened(0.1), leaf)
	if bloom:
		var may: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.6, 0.06, 0.45)
		for dot: int in 7:
			var x: float = rng.randf_range(-RUN_LENGTH * 0.46, RUN_LENGTH * 0.46)
			var side: float = 1.0 if dot % 2 == 0 else -1.0
			var rose: bool = dot % 5 == 0
			var tint: Color = Color(0.95, 0.56, 0.66) if rose else Color(0.98, 0.97, 0.94)
			parts.add_arrays(_dot_arrays(), Transform3D(Basis.from_scale(Vector3.ONE * (0.085 if rose else 0.07)),
				Vector3(x, rng.randf_range(0.7, HEDGE_HEIGHT + 0.02), side * rng.randf_range(0.42, 0.56))), may, tint)


## A faceted lump of leaf (36 triangles): a low ball stretched to `radii` and turned by `yaw`, shaded dark at its
## foot to light on top like ShapeKit's leaf-clouds.
static func _leaf_lump(parts: WorldAssetCatalog.Parts, at: Vector3, radii: Vector3, yaw: float, dark: Color, light: Color, material: Material) -> void:
	var arrays: Array = WorldAssetCatalog.primitive_arrays("sphere:lump", func() -> PrimitiveMesh:
		var made: SphereMesh = SphereMesh.new()
		made.radius = 1.0
		made.height = 2.0
		made.radial_segments = 6
		made.rings = 3
		return made)
	var shaded: Array = arrays.duplicate()
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var shades: PackedColorArray = PackedColorArray()
	for point: Vector3 in points:
		shades.append(dark.lerp(light, clampf(point.y * 0.5 + 0.5, 0.0, 1.0)))
	shaded[Mesh.ARRAY_COLOR] = shades
	parts.add_arrays(shaded, Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(radii), at), material)


static func _dot_arrays() -> Array:
	if _dots.is_empty():
		var ball: SphereMesh = SphereMesh.new()
		ball.radius = 1.0
		ball.height = 2.0
		ball.radial_segments = 4
		ball.rings = 1
		_dots = ball.get_mesh_arrays()
	return _dots


## A dry-stone wall, 3.2 m of it: three courses of fitted stones, each its own length, under a
## cock-and-hen coping (stones set on edge, tall and short by turns), moss on its weather side.
## The tumbled kind has lost its coping and half its top course, and its stones lie in the grass.
static func _wall(parts: WorldAssetCatalog.Parts, tumbled: bool) -> void:
	var stone: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE, false, 0.62 if tumbled else 0.42)
	var pale: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.lightened(0.1), false, 0.3)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9300 + int(tumbled)
	var courses: int = 1 if tumbled else 2
	var course_height: float = (WALL_HEIGHT - 0.2) / 2.0
	for course: int in courses:
		var x: float = -RUN_LENGTH * 0.5
		var batter: float = 0.6 - 0.05 * course
		while x < RUN_LENGTH * 0.5 - 0.05:
			var length: float = minf(rng.randf_range(0.6, 1.1), RUN_LENGTH * 0.5 - x)
			if tumbled and rng.randf() < 0.3:
				x += length
				continue
			parts.box(Vector3(length - 0.03, course_height - 0.02, batter * rng.randf_range(0.9, 1.0)),
				Vector3(x + length * 0.5, (course + 0.5) * course_height, rng.randf_range(-0.03, 0.03)), stone if rng.randf() < 0.7 else pale,
				Vector3(0.0, rng.randf_range(-0.05, 0.05), 0.0))
			x += length
	if tumbled:
		for fallen: int in 5:
			var side: float = 1.0 if fallen % 2 == 0 else -1.0
			parts.box(Vector3(rng.randf_range(0.26, 0.5), rng.randf_range(0.14, 0.24), rng.randf_range(0.2, 0.36)),
				Vector3(rng.randf_range(-RUN_LENGTH * 0.45, RUN_LENGTH * 0.45), 0.08, side * rng.randf_range(0.5, 1.0)), stone,
				Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3)))
	else:
		# The coping: stones on edge, leaning the same way, tall and short by turns.
		var x: float = -RUN_LENGTH * 0.5
		var index: int = 0
		while x < RUN_LENGTH * 0.5 - 0.04:
			var thick: float = minf(rng.randf_range(0.3, 0.48), RUN_LENGTH * 0.5 - x)
			var tall: float = 0.26 if index % 2 == 0 else 0.17
			parts.box(Vector3(thick - 0.015, tall, 0.46), Vector3(x + thick * 0.5, WALL_HEIGHT - 0.2 + tall * 0.5 - 0.01, 0.0),
				pale if index % 3 == 0 else stone, Vector3(0.0, 0.0, -0.16))
			x += thick
			index += 1
	# Its foot sinks into a low mossy footing, so it never floats on a slope.
	parts.box(Vector3(RUN_LENGTH, 0.2, 0.74), Vector3(0.0, 0.02, 0.0), WorldVisualCatalog.craft(Craft.MEADOW_TURF, WorldVisualCatalog.MOSS.lerp(FIELDSTONE, 0.3)))


## A split-rail fence, 3.2 m of it: two weathered posts (the next run brings the third) and two crooked rails.
static func _fence(parts: WorldAssetCatalog.Parts) -> void:
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, SILVER_TIMBER)
	var dark: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, SILVER_TIMBER.darkened(0.18))
	for x: float in [-RUN_LENGTH * 0.5, 0.0]:
		parts.box(Vector3(0.13, 1.08, 0.13), Vector3(x, 0.5, 0.0), dark, Vector3(0.0, 0.3, 0.03 if x < 0.0 else -0.04))
	for rail: int in 2:
		var y: float = 0.42 + rail * 0.36
		parts.beam(Vector3(-RUN_LENGTH * 0.5, y + 0.02, 0.07), Vector3(0.0, y - 0.02, 0.07), 0.085, timber)
		parts.beam(Vector3(0.0, y - 0.02, -0.07), Vector3(RUN_LENGTH * 0.5, y + 0.03, -0.07), 0.085, timber)


## A wattle hurdle, 2.4 m of it: hazel rods woven in and out of seven stakes.
static func _hurdle(parts: WorldAssetCatalog.Parts) -> void:
	var rod: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.56, 0.45, 0.3))
	var stake: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.4, 0.31, 0.2))
	var stakes: int = 4
	for index: int in stakes:
		var x: float = lerpf(-HURDLE_LENGTH * 0.5, HURDLE_LENGTH * 0.5, float(index) / float(stakes - 1))
		parts.box(Vector3(0.06, 0.92 if index % 3 == 0 else 0.84, 0.06), Vector3(x, 0.44, 0.0), stake)
	# The weave: three bands of rods, each bowed the other way round the stakes.
	for row: int in 3:
		var y: float = 0.2 + row * 0.24
		var weave: float = 0.05 if row % 2 == 0 else -0.05
		parts.beam(Vector3(-HURDLE_LENGTH * 0.5, y, weave), Vector3(0.0, y, -weave), 0.19, rod)
		parts.beam(Vector3(0.0, y, -weave), Vector3(HURDLE_LENGTH * 0.5, y, weave), 0.19, rod)


## A field gate: two granite gateposts 3.4 m apart and a five-barred gate standing open on the hinge post.
static func _gate(parts: WorldAssetCatalog.Parts) -> void:
	var stone: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.lightened(0.06), false, 0.35)
	var timber: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, SILVER_TIMBER)
	for side: float in [-1.0, 1.0]:
		parts.cylinder(0.15, 0.2, 1.3, Vector3(side * (GATE_WIDTH * 0.5 + 0.18), 0.62, 0.0), stone, 5, Vector3(0.0, 0.4, side * 0.03))
	# The leaf, hung on the west post and swung back a little past square.
	var hinge: Vector3 = Vector3(-GATE_WIDTH * 0.5 + 0.02, 0.0, 0.1)
	var swing: Basis = Basis(Vector3.UP, deg_to_rad(-80.0))
	var leaf: float = GATE_WIDTH - 0.2
	for bar: int in 5:
		var y: float = 0.2 + bar * 0.2 + (0.04 if bar == 4 else 0.0)
		parts.beam(hinge + swing * Vector3(0.0, y, 0.0), hinge + swing * Vector3(leaf, y, 0.0), 0.07 if bar != 4 else 0.09, timber)
	for upright: float in [0.0, leaf * 0.5, leaf]:
		parts.beam(hinge + swing * Vector3(upright, 0.14, 0.0), hinge + swing * Vector3(upright, 1.1, 0.0), 0.08, timber)
	parts.beam(hinge + swing * Vector3(0.0, 0.2, 0.0), hinge + swing * Vector3(leaf, 1.02, 0.0), 0.06, timber)


## A squeeze stile through a wall: two upright slabs a stride apart and a step stone between them.
static func _stile(parts: WorldAssetCatalog.Parts) -> void:
	var stone: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.lightened(0.04), false, 0.4)
	for side: float in [-1.0, 1.0]:
		parts.box(Vector3(0.14, 1.05, 0.56), Vector3(side * 0.46, 0.5, 0.0), stone, Vector3(0.0, 0.0, side * -0.06))
	parts.box(Vector3(0.62, 0.2, 1.0), Vector3(0.0, 0.08, 0.0), stone)


## A haycock: a rounded heap of new hay, raked up to dry, a wisp or two at its foot.
static func _haycock(parts: WorldAssetCatalog.Parts) -> void:
	var hay: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, STRAW, false, 0.0, true)
	var pale: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, STRAW.lightened(0.1), false, 0.0, true)
	parts.sphere(0.95, Vector3(0.0, 0.55, 0.0), hay, Vector3(1.0, 1.02, 1.0), 7)
	parts.sphere(0.6, Vector3(0.0, 1.16, 0.0), pale, Vector3(1.0, 0.8, 1.0), 6)
	parts.cylinder(0.9, 1.08, 0.3, Vector3(0.0, 0.12, 0.0), hay, 7)
	var blades: Material = WorldVisualCatalog.foliage(Color.WHITE, 0.6, 0.3, 0.6)
	for wisp: int in 4:
		var angle: float = TAU * float(wisp) / 4.0 + 0.3
		parts.blade(Vector3(cos(angle) * 0.9, 0.0, sin(angle) * 0.9), Vector3(cos(angle) * 1.35, 0.26, sin(angle) * 1.35), 0.16,
			STRAW.darkened(0.1), STRAW.lightened(0.12), blades)


## A stook: six sheaves of cut corn stood on their butts and leaned head to head to dry.
static func _stook(parts: WorldAssetCatalog.Parts) -> void:
	var straw: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.78, 0.64, 0.32), false, 0.0, true)
	var ears: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.3, 0.12, 0.3)
	for sheaf: int in 4:
		var side: float = 1.0 if sheaf % 2 == 0 else -1.0
		var x: float = (float(sheaf / 2) - 0.5) * 0.46
		var foot: Vector3 = Vector3(x, 0.0, side * 0.34)
		var head: Vector3 = Vector3(x, 1.08, side * 0.06)
		var lean: Vector3 = (head - foot).normalized()
		var turn: Basis = Basis(Quaternion(Vector3.UP, lean))
		var arrays: Array = WorldAssetCatalog.primitive_arrays("cylinder:0.450:5", func() -> PrimitiveMesh:
			var made: CylinderMesh = CylinderMesh.new()
			made.top_radius = 0.45
			made.bottom_radius = 1.0
			made.height = 1.0
			made.radial_segments = 5
			made.rings = 1
			return made)
		parts.add_arrays(arrays, Transform3D(turn * Basis.from_scale(Vector3(0.2, 1.1, 0.2)), (foot + head) * 0.5), straw)
		# The band, and the ears splaying out above it.
		parts.add_arrays(arrays, Transform3D(turn * Basis.from_scale(Vector3(0.115, 0.07, 0.115)), foot.lerp(head, 0.68)), straw, Color(0.7, 0.7, 0.7))
		for ear: int in 3:
			var angle: float = TAU * float(ear) / 3.0 + sheaf
			var out: Vector3 = (lean + Vector3(cos(angle), 0.0, sin(angle)) * 0.5).normalized()
			parts.blade(head - lean * 0.06, head + out * 0.36, 0.14, Color(0.72, 0.58, 0.28), Color(0.9, 0.78, 0.42), ears)


## Three metres of a root crop: a row of leafy tops along +X that part as a hero wades through.
static func _crop_row(parts: WorldAssetCatalog.Parts) -> void:
	var leaf: Material = WorldVisualCatalog.foliage(Color.WHITE, 0.6, 0.25, 1.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9700
	for plant: int in 4:
		var at: Vector3 = Vector3(-1.12 + plant * 0.75 + rng.randf_range(-0.06, 0.06), 0.0, rng.randf_range(-0.05, 0.05))
		var blue: float = rng.randf()
		for blade: int in 4:
			var angle: float = TAU * float(blade) / 4.0 + plant * 0.7
			var reach: float = rng.randf_range(0.28, 0.4)
			parts.blade(at, at + Vector3(cos(angle) * reach, rng.randf_range(0.2, 0.34), sin(angle) * reach), 0.34,
				Color(0.2, 0.36, 0.22).lerp(Color(0.22, 0.34, 0.3), blue), Color(0.48, 0.66, 0.36).lerp(Color(0.5, 0.64, 0.5), blue), leaf)


## A wigwam of bean poles tied at the top, the vines up it in leaf and scarlet flower.
static func _bean_row(parts: WorldAssetCatalog.Parts) -> void:
	var pole: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, Color(0.5, 0.4, 0.28))
	var leaf: Material = WorldVisualCatalog.foliage(Color.WHITE, 2.0, 0.08, 0.4)
	var top: Vector3 = Vector3(0.0, 2.05, 0.0)
	for index: int in 5:
		var angle: float = TAU * float(index) / 5.0
		var foot: Vector3 = Vector3(cos(angle) * 0.55, 0.0, sin(angle) * 0.55)
		parts.beam(foot, top + (top - foot).normalized() * 0.25, 0.04, pole)
		_leaf_lump(parts, foot.lerp(top, 0.46), Vector3(0.2, 0.62, 0.2), angle, Color(0.2, 0.38, 0.18), Color(0.46, 0.64, 0.3), leaf)
		parts.add_arrays(_dot_arrays(), Transform3D(Basis.from_scale(Vector3.ONE * 0.05), foot.lerp(top, 0.6) + Vector3(0.0, 0.1, 0.0)), leaf,
			Color(0.9, 0.2, 0.16))


## A bramble thicket: arching canes over a low tangle of leaf, a dog-rose or two in it.
static func _bramble(parts: WorldAssetCatalog.Parts) -> void:
	var leaf: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.2, 0.12, 0.6)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9900
	for lump: int in 4:
		var angle: float = TAU * float(lump) / 4.0 + 0.5
		var size: float = rng.randf_range(0.48, 0.64)
		_leaf_lump(parts, Vector3(cos(angle) * 0.6, 0.36, sin(angle) * 0.6), Vector3(size * 1.2, size * 0.74, size * 1.2), angle, Color(0.14, 0.26, 0.14),
			Color(0.34, 0.48, 0.24), leaf)
	for cane: int in 4:
		var angle: float = TAU * float(cane) / 4.0
		var reach: float = rng.randf_range(1.0, 1.6)
		parts.blade(Vector3(cos(angle) * 0.2, 0.3, sin(angle) * 0.2), Vector3(cos(angle) * reach, rng.randf_range(0.3, 0.9), sin(angle) * reach), 0.12,
			Color(0.3, 0.2, 0.22), Color(0.36, 0.5, 0.26), leaf)
	for rose: int in 3:
		var angle: float = rng.randf() * TAU
		parts.add_arrays(_dot_arrays(), Transform3D(Basis.from_scale(Vector3.ONE * 0.075),
			Vector3(cos(angle) * rng.randf_range(0.4, 0.9), rng.randf_range(0.55, 0.8), sin(angle) * rng.randf_range(0.4, 0.9))), leaf, Color(0.95, 0.56, 0.66))


## A stone trough: one block hollowed for water, moss at its foot.
static func _trough(parts: WorldAssetCatalog.Parts) -> void:
	var stone: Material = WorldVisualCatalog.craft(Craft.CRAG_GRANITE, FIELDSTONE.darkened(0.04), false, 0.5)
	parts.box(Vector3(1.8, 0.16, 0.62), Vector3(0.0, 0.08, 0.0), stone)
	for side: float in [-1.0, 1.0]:
		parts.box(Vector3(1.8, 0.4, 0.11), Vector3(0.0, 0.34, side * 0.255), stone)
		parts.box(Vector3(0.12, 0.4, 0.4), Vector3(side * 0.84, 0.34, 0.0), stone)
	parts.box(Vector3(1.58, 0.03, 0.4), Vector3(0.0, 0.45, 0.0), WorldVisualCatalog.painted(Color(0.2, 0.34, 0.4)))


## A scarecrow: a cross of poles in an old coat, a sack for a head under a slouch hat, straw at the cuffs.
static func _scarecrow(parts: WorldAssetCatalog.Parts) -> void:
	var pole: Material = WorldVisualCatalog.craft(Craft.HEWN_TIMBER, SILVER_TIMBER.darkened(0.2))
	var coat: Material = WorldVisualCatalog.painted(Color(0.34, 0.4, 0.52))
	var patch: Material = WorldVisualCatalog.painted(Color(0.62, 0.3, 0.24))
	var sack: Material = WorldVisualCatalog.painted(Color(0.76, 0.66, 0.48))
	var hat: Material = WorldVisualCatalog.painted(Color(0.32, 0.25, 0.2))
	var straw: Material = WorldVisualCatalog.foliage(Color.WHITE, 1.9, 0.2, 0.0)
	parts.box(Vector3(0.09, 1.95, 0.09), Vector3(0.0, 0.95, 0.0), pole)
	parts.box(Vector3(1.56, 0.08, 0.08), Vector3(0.0, 1.46, 0.0), pole, Vector3(0.0, 0.0, 0.05))
	parts.box(Vector3(0.62, 0.78, 0.26), Vector3(0.0, 1.18, 0.0), coat)
	for side: float in [-1.0, 1.0]:
		parts.box(Vector3(0.5, 0.2, 0.2), Vector3(side * 0.52, 1.44, 0.0), coat, Vector3(0.0, 0.0, side * 0.05))
		for wisp: int in 4:
			parts.blade(Vector3(side * 0.76, 1.44, 0.0), Vector3(side * 1.0, 1.36 + wisp * 0.07, (wisp - 1.5) * 0.08), 0.07, STRAW.darkened(0.1), STRAW, straw)
	parts.box(Vector3(0.16, 0.16, 0.02), Vector3(0.12, 1.06, 0.14), patch)
	parts.sphere(0.2, Vector3(0.0, 1.82, 0.0), sack, Vector3(1.0, 1.1, 1.0), 8)
	parts.cylinder(0.36, 0.38, 0.04, Vector3(0.0, 1.96, 0.0), hat, 10, Vector3(0.1, 0.0, 0.06))
	parts.cylinder(0.14, 0.2, 0.26, Vector3(0.0, 2.08, 0.0), hat, 8, Vector3(0.1, 0.0, 0.06))
