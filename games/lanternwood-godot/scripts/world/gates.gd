@tool
class_name Gates
extends RefCounted

# The ways out of the Glenn, one kind of opening per game: a garden gate, a leafy hedge arch, a
# rose arbor, a rustic trailhead, and the old garden door at the far end. Each stands at 0, 0, 0
# with its gap running along x (OPENING wide) and its front, with the sign, facing +z, toward the
# path. Open ones lead somewhere; shut ones are signed "Coming soon" and boarded up.

const OPENING := 2.4 # How wide the gap in the hedge is.
const STONE := Color("#a59c8c")
const MOSS := Color("#5f7a2c")


static func build(kind: String, title: String, open: bool, rng: RandomNumberGenerator) -> Node3D:
	var model: Node3D
	match kind:
		"gate": model = garden_gate(title, open)
		"arch": model = hedge_arch(title, open, rng)
		"arbor": model = arbor(title, open, rng)
		"trail": model = trailhead(title, open)
		"door": model = garden_door(title, open)
		_: model = Node3D.new()
	model.name = kind.capitalize()
	if not open:
		model.add_child(_blocker())
	return model


# Stone pillars with a picket gate, swung wide open when there's a game behind it.
static func garden_gate(title: String, open: bool) -> Node3D:
	var root := Node3D.new()
	var x := OPENING / 2.0 + 0.3
	for side: float in [-1.0, 1.0]:
		root.add_child(_pillar(Vector3(side * x, 0, 0), 1.7))
	var wood := Art.bark_material(Color("#d8cdb4"), 4.0) # Weathered, white-washed pickets.
	var hinge := Node3D.new()
	hinge.position = Vector3(-OPENING / 2.0 - 0.05, 0, 0.1)
	hinge.rotation.y = -1.9 if open else 0.0
	root.add_child(hinge)
	var width := OPENING + 0.05
	for rail_y: float in [0.35, 0.95]:
		hinge.add_child(Art.box(Vector3(width, 0.08, 0.05), wood, Vector3(width / 2.0, rail_y, 0)))
	for i in 7:
		var px := (i + 0.5) * width / 7.0
		hinge.add_child(Art.box(Vector3(0.12, 1.15, 0.04), wood, Vector3(px, 0.68, 0.035)))
		var tip := Art.box(Vector3(0.085, 0.085, 0.04), wood, Vector3(px, 1.27, 0.035))
		tip.rotation.z = PI / 4.0
		hinge.add_child(tip)
	# An iron arch over the top, from pillar to pillar, with the sign hanging from it.
	var curve := PackedVector3Array()
	var thickness := PackedFloat32Array()
	for i in 17:
		var angle := PI * i / 16.0
		curve.append(Vector3(cos(angle) * x, 1.95 + sin(angle) * 0.75, 0))
		thickness.append(0.03)
	root.add_child(Art.instance(Art.tube_mesh(curve, thickness, 6), Art.material(Color("#2b2622"), 0.5, {"metallic": 0.6})))
	root.add_child(_hanging_sign(title, Vector3(0, 2.25, 0.05), 1.3))
	return root


# A tall arch of hedge over the gap, with the sign hanging under its crown.
static func hedge_arch(title: String, _open: bool, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := OPENING / 2.0 + 0.45
	var steps := 9
	for i in steps + 1:
		var angle := PI * i / steps
		var at := Vector3(cos(angle) * radius, 2.0 + sin(angle) * 1.05, 0)
		Art.add_leaf_cards(leaves, rng, at, Vector3(0.6, 0.55, 0.75), 30, 0.7, 0.6)
	for side: float in [-1.0, 1.0]:
		Art.add_leaf_cards(leaves, rng, Vector3(side * radius, 1.1, 0), Vector3(0.55, 1.2, 0.75), 50, 0.75, 0.7)
	var colors: Array = Foliage.GREENS.hedge
	root.add_child(Art.instance(leaves.commit(), Art.leaf_material("broad", colors[0], colors[1], 0.4)))
	root.add_child(_hanging_sign(title, Vector3(0, 2.35, 0.85), 1.2))
	return root


# A wooden rose arbor: four posts, beams across the top, and climbing roses.
static func arbor(title: String, _open: bool, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var wood := Art.bark_material(Color("#7a5a3c"), 3.0)
	var x := OPENING / 2.0 + 0.15
	for side: float in [-1.0, 1.0]:
		for depth: float in [-0.45, 0.45]:
			root.add_child(Art.box(Vector3(0.13, 2.4, 0.13), wood, Vector3(side * x, 1.2, depth)))
	for depth: float in [-0.45, 0.45]:
		root.add_child(Art.box(Vector3(OPENING + 0.9, 0.14, 0.1), wood, Vector3(0, 2.42, depth)))
	for i in 7:
		root.add_child(Art.box(Vector3(0.07, 0.07, 1.3), wood, Vector3(lerpf(-x - 0.2, x + 0.2, i / 6.0), 2.52, 0)))
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		Art.add_leaf_cards(leaves, rng, Vector3(side * x, 1.4, 0), Vector3(0.35, 1.1, 0.6), 34, 0.55, 0.3)
	Art.add_leaf_cards(leaves, rng, Vector3(0, 2.6, 0), Vector3(1.7, 0.3, 0.8), 50, 0.6, 0.3)
	root.add_child(Art.instance(leaves.commit(), Art.leaf_material("small", Color("#7fa043"), Color("#24401a"), 0.5)))
	var roses := Art.material(Color("#d9667a"), 0.5)
	for i in 26:
		var spot := Vector3(rng.randf_range(-x - 0.3, x + 0.3), 2.62 + rng.randf_range(-0.1, 0.18), rng.randf_range(-0.6, 0.6))
		if i < 10:
			spot = Vector3((1.0 if i % 2 == 0 else -1.0) * x + rng.randf_range(-0.2, 0.2), rng.randf_range(0.6, 2.3), rng.randf_range(-0.5, 0.55))
		root.add_child(Art.sphere(rng.randf_range(0.05, 0.08), roses, spot))
	var board := _sign(title, 1.5)
	board.position = Vector3(0, 2.15, 0.53)
	root.add_child(board)
	return root


# Two rough log posts with a plank across the top: the start of a trail off into the woods.
static func trailhead(title: String, _open: bool) -> Node3D:
	var root := Node3D.new()
	var wood := Art.bark_material(Color("#6b5038"), 1.2)
	var x := OPENING / 2.0 + 0.1
	for side: float in [-1.0, 1.0]:
		root.add_child(Art.cylinder(0.12, 0.15, 2.3, wood, Vector3(side * x, 1.15, 0), 9))
	var beam := Art.cylinder(0.09, 0.09, OPENING + 0.7, wood, Vector3(0, 2.25, 0), 8)
	beam.rotation.z = PI / 2.0
	root.add_child(beam)
	root.add_child(_hanging_sign(title, Vector3(0, 1.95, 0.05), 1.5))
	return root


# The old garden door: a stretch of mossy stone wall with an arched wooden door, standing open
# when the maze behind it is ready.
static func garden_door(title: String, open: bool) -> Node3D:
	var root := Node3D.new()
	var stone := Art.rock_material(Color("#b3a58c"), MOSS)
	var x := OPENING / 2.0 + 0.55
	for side: float in [-1.0, 1.0]:
		root.add_child(Art.box(Vector3(1.1, 2.9, 1.2), stone, Vector3(side * x, 1.45, 0)))
		root.add_child(Art.box(Vector3(1.25, 0.16, 1.32), stone, Vector3(side * x, 2.98, 0)))
	# A rounded arch of stone over the doorway, resting on the two walls.
	var curve := PackedVector3Array()
	var thickness := PackedFloat32Array()
	for i in 17:
		var angle := PI * i / 16.0
		curve.append(Vector3(cos(angle) * (x - 0.1), 2.95 + sin(angle) * 0.9, 0))
		thickness.append(0.32)
	var arch := Art.instance(Art.tube_mesh(curve, thickness, 10), stone)
	arch.scale = Vector3(1, 1, 1.8)
	root.add_child(arch)
	# Ivy tumbling over the top.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ivy := SurfaceTool.new()
	ivy.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var at := Vector3(lerpf(-x - 0.3, x + 0.3, i / 6.0), 3.1 + rng.randf_range(-0.1, 0.2), rng.randf_range(-0.2, 0.3))
		Art.add_leaf_cards(ivy, rng, at, Vector3(0.6, 0.45, 0.75), 22, 0.45, 0.5)
	for side: float in [-1.0, 1.0]:
		Art.add_leaf_cards(ivy, rng, Vector3(side * (x + 0.35), 1.9, 0.45), Vector3(0.35, 1.0, 0.3), 26, 0.4, 0.4)
	root.add_child(Art.instance(ivy.commit(), Art.leaf_material("small", Color("#86a848"), Color("#1f3818"), 0.4)))
	var hinge := Node3D.new()
	hinge.position = Vector3(-OPENING / 2.0 + 0.05, 0, 0.45)
	hinge.rotation.y = -1.6 if open else 0.0
	root.add_child(hinge)
	var door_width := OPENING - 0.1
	var planks := Art.bark_material(Color("#6a4a2e"), 2.0)
	for i in 5:
		hinge.add_child(Art.box(Vector3(door_width / 5.0 - 0.015, 2.5, 0.08), planks, Vector3((i + 0.5) * door_width / 5.0, 1.25, 0)))
	var iron := Art.material(Color("#2b2622"), 0.45, {"metallic": 0.7})
	for strap_y: float in [0.5, 2.0]:
		hinge.add_child(Art.box(Vector3(door_width * 0.8, 0.07, 0.02), iron, Vector3(door_width * 0.4, strap_y, 0.05)))
	hinge.add_child(Art.sphere(0.05, Art.material(Color("#c9a23a"), 0.3, {"metallic": 0.9}), Vector3(door_width - 0.25, 1.2, 0.08)))
	var board := _sign(title, 1.6)
	board.position = Vector3(0, 3.55, 0.66)
	root.add_child(board)
	for side: float in [-1.0, 1.0]:
		var lamp := Props.lantern()
		lamp.position = Vector3(side * (x + 0.2), 1.0, 0.75)
		lamp.scale = Vector3.ONE * 0.75
		lamp.rotation.y = PI / 2.0
		root.add_child(lamp)
	return root


# A short, squat stone pillar with a cap.
static func _pillar(at: Vector3, height: float) -> Node3D:
	var root := Node3D.new()
	root.position = at
	var stone := Art.rock_material(STONE, MOSS)
	root.add_child(Art.box(Vector3(0.5, height, 0.5), stone, Vector3(0, height / 2.0, 0)))
	root.add_child(Art.box(Vector3(0.62, 0.12, 0.62), stone, Vector3(0, height + 0.06, 0)))
	root.add_child(Art.sphere(0.17, stone, Vector3(0, height + 0.27, 0)))
	return root


# A wooden board with lettering on its front.
static func _sign(text: String, width: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(Art.box(Vector3(width, 0.36, 0.06), Art.bark_material(Props.SIGN_WOOD, 4.0)))
	var letters := Art.label(text, 52)
	letters.position.z = 0.035
	root.add_child(letters)
	return root


# A sign hanging on two little chains, at `at` (the middle of the board).
static func _hanging_sign(text: String, at: Vector3, width: float) -> Node3D:
	var root := _sign(text, width)
	root.position = at
	for side: float in [-1.0, 1.0]:
		root.add_child(Art.cylinder(0.008, 0.008, 0.3, Art.material(Color("#2b2622")), Vector3(side * width * 0.38, 0.32, 0), 4))
	return root


# Planks nailed across a shut opening, and something solid to stop you.
static func _blocker() -> Node3D:
	var root := Node3D.new()
	root.name = "Shut"
	var wood := Art.bark_material(Color("#8a6a48"), 3.0)
	for angle: float in [0.32, -0.32]:
		var plank := Art.box(Vector3(OPENING + 0.4, 0.16, 0.05), wood, Vector3(0, 0.95, 0.3))
		plank.rotation.z = angle
		root.add_child(plank)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(OPENING, 2.4, 0.4)
	shape.shape = box
	shape.position = Vector3(0, 1.2, 0)
	body.add_child(shape)
	root.add_child(body)
	return root
