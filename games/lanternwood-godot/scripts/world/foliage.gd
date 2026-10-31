@tool
class_name Foliage
extends RefCounted

# Trees, bushes, ferns and hedges. Each is a trunk or core, with crowns of leaf cards (see
# Art.add_leaf_cards) that shade like soft, rounded masses and move in the wind.
# The colours here are the woods' palette: see STYLE_GUIDE.md before changing them.

# Leaf colours: [sunlit tip, shaded inside].
const GREENS := {
	"oak": [Color("#9cb54a"), Color("#26401a")],
	"oak_deep": [Color("#7f9e3c"), Color("#1d3516")],
	"birch": [Color("#c3cf5a"), Color("#4b6224")],
	"pine": [Color("#5f8a52"), Color("#14271c")],
	"amber": [Color("#e6a43a"), Color("#6b3a14")],
	"rust": [Color("#d0602a"), Color("#5a2412")],
	"gold": [Color("#ecc84a"), Color("#7a5a1a")],
	"hedge": [Color("#7fa043"), Color("#1a3014")],
	"bush": [Color("#8fae4a"), Color("#22391a")],
	"fern": [Color("#93b54e"), Color("#3a5a22")],
}
const BARK := {
	"oak": Color("#5e4a3a"),
	"birch": Color("#e8e2d4"),
	"pine": Color("#5a3e2c"),
}


# A tree of the given kind ("oak", "birch" or "pine"), `size` 1 for an ordinary one.
# `palette` picks the leaf colours from GREENS (autumn trees use "amber", "rust" or "gold").
static func tree(kind: String, rng: RandomNumberGenerator, size := 1.0, palette := "") -> Node3D:
	var root := Node3D.new()
	root.name = kind.capitalize()
	match kind:
		"birch":
			_birch(root, rng, size, palette if palette else "birch")
		"pine":
			_pine(root, rng, size)
		_:
			_oak(root, rng, size, palette if palette else ("oak" if rng.randf() < 0.6 else "oak_deep"))
	return root


# An oak: a thick, leaning trunk that splits into a few boughs, each holding up a big rounded crown.
static func _oak(root: Node3D, rng: RandomNumberGenerator, size: float, palette: String) -> void:
	var height := rng.randf_range(2.2, 3.0) * size
	var lean := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)) * size
	var trunk_top := Vector3(0, height, 0) + lean
	var bark := Art.bark_material(BARK.oak, 1.0)
	root.add_child(Art.instance(_trunk(Vector3.ZERO, trunk_top, 0.32 * size, 0.2 * size, rng), bark))
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var boughs := rng.randi_range(3, 4)
	var crown_center := trunk_top + Vector3(0, 1.3 * size, 0)
	for i in boughs:
		var angle := TAU * i / boughs + rng.randf_range(-0.4, 0.4)
		var out := Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(1.0, 1.6) * size
		var tip := trunk_top + out + Vector3(0, rng.randf_range(0.9, 1.5) * size, 0)
		root.add_child(Art.instance(_trunk(trunk_top - Vector3(0, 0.2, 0), tip, 0.17 * size, 0.07 * size, rng), bark))
		var radii := Vector3(1.5, 1.05, 1.5) * size * rng.randf_range(0.85, 1.15)
		Art.add_leaf_cards(leaves, rng, tip + Vector3(0, 0.35 * size, 0), radii, int(85 * size), 1.25 * size)
	Art.add_leaf_cards(leaves, rng, crown_center + Vector3(0, 0.5 * size, 0), Vector3(1.8, 1.2, 1.8) * size, int(110 * size), 1.35 * size)
	var colors: Array = GREENS[palette]
	root.add_child(Art.instance(leaves.commit(), Art.leaf_material("broad", colors[0], colors[1])))


# A birch: a slender, pale trunk with a light, airy crown that rustles in the breeze.
static func _birch(root: Node3D, rng: RandomNumberGenerator, size: float, palette: String) -> void:
	var height := rng.randf_range(4.0, 5.2) * size
	var top := Vector3(rng.randf_range(-0.5, 0.5), height, rng.randf_range(-0.5, 0.5)) * Vector3(size, 1, size)
	root.add_child(Art.instance(_trunk(Vector3.ZERO, top, 0.13 * size, 0.05 * size, rng), Art.bark_material(BARK.birch, 2.0)))
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var at := top.lerp(Vector3(0, height * 0.45, 0), i * 0.28) + Vector3(rng.randf_range(-0.4, 0.4), 0.3, rng.randf_range(-0.4, 0.4)) * size
		Art.add_leaf_cards(leaves, rng, at, Vector3(1.1, 0.9, 1.1) * size * (1.0 - i * 0.12), int(55 * size), 0.9 * size, 0.4)
	var colors: Array = GREENS[palette]
	root.add_child(Art.instance(leaves.commit(), Art.leaf_material("small", colors[0], colors[1], 1.6)))


# A pine: a straight trunk with tiers of drooping needle boughs, narrowing to a point.
static func _pine(root: Node3D, rng: RandomNumberGenerator, size: float) -> void:
	var height := rng.randf_range(5.0, 6.5) * size
	root.add_child(Art.instance(_trunk(Vector3.ZERO, Vector3(0, height, 0), 0.22 * size, 0.04 * size, rng), Art.bark_material(BARK.pine, 1.4)))
	var needles := SurfaceTool.new()
	needles.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tiers := 6
	for i in tiers:
		var t := float(i) / tiers
		var y := lerpf(1.2, height - 0.3, t) * 1.0
		var radius := lerpf(1.9, 0.45, t) * size
		Art.add_leaf_cards(needles, rng, Vector3(0, y, 0), Vector3(radius, 0.55 * size, radius), int(lerpf(70, 18, t) * size), 1.0 * size, 0.6)
	var colors: Array = GREENS.pine
	root.add_child(Art.instance(needles.commit(), Art.leaf_material("needle", colors[0], colors[1], 0.6)))


# A trunk or bough from `from` to `to`, wobbling a little along the way.
static func _trunk(from: Vector3, to: Vector3, bottom_radius: float, top_radius: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	var steps := 6
	var wobble := from.distance_to(to) * 0.06
	for i in steps + 1:
		var t := float(i) / steps
		var bend := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * wobble * sin(t * PI)
		points.append(from.lerp(to, t) + bend)
		# Flared at the foot, like real roots.
		radii.append(lerpf(bottom_radius, top_radius, t) * (1.0 + 0.6 * exp(-t * 12.0)))
	return Art.tube_mesh(points, radii)


# A round, leafy bush.
static func bush(rng: RandomNumberGenerator, size := 1.0, palette := "bush") -> Node3D:
	var root := Node3D.new()
	root.name = "Bush"
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rng.randi_range(2, 3):
		var at := Vector3(rng.randf_range(-0.5, 0.5), 0.55, rng.randf_range(-0.5, 0.5)) * size
		Art.add_leaf_cards(leaves, rng, at, Vector3(0.8, 0.6, 0.8) * size, int(40 * size), 0.8 * size, 0.3)
	var colors: Array = GREENS[palette]
	root.add_child(Art.instance(leaves.commit(), Art.leaf_material("broad", colors[0], colors[1], 0.7)))
	return root


# A fern: fronds arching out from the middle.
static func fern(rng: RandomNumberGenerator, size := 1.0) -> Node3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fronds := rng.randi_range(5, 8)
	for i in fronds:
		var angle := TAU * i / fronds + rng.randf_range(-0.3, 0.3)
		var out := Vector3(cos(angle), 0, sin(angle))
		var length := rng.randf_range(0.6, 0.9) * size
		var width := length * 0.45
		var side := out.cross(Vector3.UP)
		# A frond: a strip that rises then droops, made of two quads.
		var base := Vector3(0, 0.02, 0)
		var middle := out * length * 0.55 + Vector3(0, length * 0.55, 0)
		var tip := out * length + Vector3(0, length * 0.25, 0)
		var rows := [[base, 0.0, 1.0], [middle, 0.6, 0.5], [tip, 1.0, 0.0]]
		for r in 2:
			var a: Array = rows[r]
			var b: Array = rows[r + 1]
			var quad := [a[0] - side * width * 0.5, a[0] + side * width * 0.5, b[0] + side * width * 0.5, b[0] - side * width * 0.5]
			var uvs := [Vector2(0, a[2]), Vector2(1, a[2]), Vector2(1, b[2]), Vector2(0, b[2])]
			for k: int in [0, 1, 2, 0, 2, 3]:
				tool.set_color(Color(0.4 + 0.6 * (a[1] if k < 2 else b[1]), rng.randf(), 0))
				tool.set_normal((Vector3.UP + out * 0.4).normalized())
				tool.set_uv(uvs[k])
				tool.add_vertex(quad[k])
	var colors: Array = GREENS.fern
	var made := Art.instance(tool.commit(), Art.leaf_material("fern", colors[0], colors[1], 0.8))
	made.name = "Fern"
	return made


# A straight run of clipped hedge from `from` to `to` (on the ground), solid to walk into.
# It's a row of overlapping leafy puffs around a dark core, so the top and sides are soft and lumpy.
static func hedge(from: Vector3, to: Vector3, thickness: float, height: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Hedge"
	var length := from.distance_to(to)
	var along := (to - from).normalized()
	var middle := (from + to) / 2.0
	root.position = middle
	root.rotation.y = atan2(along.x, along.z)
	# The core, to stop you seeing through the leaves.
	var core := Art.box(Vector3(thickness * 0.7, height * 0.85, length - 0.2), Art.material(Color("#1b2c15"), 1.0), Vector3(0, height * 0.425, 0))
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(core)
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var puffs := maxi(1, int(length / 0.8))
	for i in puffs:
		var z := lerpf(-length / 2.0 + 0.4, length / 2.0 - 0.4, (i + 0.5) / puffs) if puffs > 1 else 0.0
		var at := Vector3(0, height * rng.randf_range(0.5, 0.55), z)
		var radii := Vector3(thickness * 0.56, height * 0.56, 0.7) * rng.randf_range(0.95, 1.08)
		Art.add_leaf_cards(leaves, rng, at, radii, int(70 * height / 2.5), 0.55, 0.8)
		# A skirt of leaves along the bottom, so the hedge meets the grass without a dark gap.
		Art.add_leaf_cards(leaves, rng, Vector3(0, height * 0.18, z), Vector3(thickness * 0.6, height * 0.22, 0.7), 16, 0.45, 0.7)
	var colors: Array = GREENS.hedge
	root.add_child(Art.instance(leaves.commit(), Art.leaf_material("small", colors[0], colors[1], 0.35)))
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(thickness, height, length)
	shape.shape = box
	shape.position.y = height / 2.0
	body.add_child(shape)
	root.add_child(body)
	return root
