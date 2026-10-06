@tool
class_name Props
extends RefCounted

# The little things along the path: lanterns, rocks, finger-posts, mushrooms and pumpkins.

const LANTERN_HEIGHT := 1.85
const LANTERN_ARM := 0.42
const LANTERN_LIGHT := Color("#ffb052") # Warm, like candlelight through paper.
const WOOD := Color("#6b4a32")
const DARK_WOOD := Color("#3e2c20")
const SIGN_WOOD := Color("#b08a5a")


# A paper lantern hanging from a little wooden post, out along +x, casting real warm light.
# The light is kept in its "light" meta, so the Glen can make it flicker.
static func lantern(cast_shadows := false) -> Node3D:
	var root := Node3D.new()
	root.name = "Lantern"
	var wood := Art.bark_material(DARK_WOOD, 3.0)
	root.add_child(Art.cylinder(0.045, 0.07, LANTERN_HEIGHT, wood, Vector3(0, LANTERN_HEIGHT / 2.0, 0), 8))
	var arm := Art.cylinder(0.03, 0.03, LANTERN_ARM + 0.06, wood, Vector3(LANTERN_ARM / 2.0, LANTERN_HEIGHT - 0.06, 0), 6)
	arm.rotation.z = PI / 2.0
	root.add_child(arm)
	var hang := Vector3(LANTERN_ARM, LANTERN_HEIGHT - 0.36, 0)
	root.add_child(Art.cylinder(0.006, 0.006, 0.14, Art.material(Color("#2a2018")), hang + Vector3(0, 0.25, 0), 4))
	# The paper globe, with dark ribs and a cap and foot.
	root.add_child(Art.sphere(0.17, Art.glow_material(Color("#ffc878"), 3.2), hang, Vector3(1, 1.2, 1)))
	for i in 3:
		var rib := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.165
		torus.outer_radius = 0.18
		torus.rings = 20
		rib.mesh = torus
		rib.material_override = Art.material(Color("#7a3a1e"))
		rib.position = hang + Vector3(0, (i - 1) * 0.1, 0)
		rib.scale = Vector3(1, 1, 1) * (1.0 - absf(i - 1) * 0.22)
		root.add_child(rib)
	root.add_child(Art.cylinder(0.07, 0.09, 0.05, Art.material(Color("#2e2118")), hang + Vector3(0, 0.21, 0), 10))
	root.add_child(Art.cylinder(0.08, 0.06, 0.04, Art.material(Color("#2e2118")), hang - Vector3(0, 0.21, 0), 10))
	var light := OmniLight3D.new()
	light.light_color = LANTERN_LIGHT
	light.light_energy = 1.6
	light.omni_range = 6.0
	light.omni_attenuation = 1.4
	light.light_volumetric_fog_energy = 2.0
	light.shadow_enabled = cast_shadows
	light.position = hang
	root.add_child(light)
	root.set_meta("light", light)
	_add_post_body(root, 0.1, LANTERN_HEIGHT)
	return root


# A rounded, mossy boulder you can jump up onto.
static func rock(rng: RandomNumberGenerator, width := 1.0, height := 0.7) -> Node3D:
	var root := Node3D.new()
	root.name = "Rock"
	var mesh := Art.blob_mesh(1.0, 0.28, rng.randi(), Vector3(width, height, width * rng.randf_range(0.8, 1.1)))
	var stone := Art.instance(mesh, Art.rock_material(Color("#8d877c"), Color("#5f7a2c")))
	stone.position.y = height * 0.25 # Sunk a little into the ground.
	stone.rotation.y = rng.randf() * TAU
	root.add_child(stone)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_convex_shape(true, true)
	shape.position = stone.position
	shape.rotation = stone.rotation
	body.add_child(shape)
	root.add_child(body)
	return root


# A finger-post pointing toward `side` (-1 west, 1 east), with the game's name on its arm.
static func fingerpost(title: String, side: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Fingerpost"
	var wood := Art.bark_material(WOOD, 2.5)
	root.add_child(Art.cylinder(0.06, 0.07, 1.9, wood, Vector3(0, 0.95, 0), 8))
	root.add_child(Art.sphere(0.075, wood, Vector3(0, 1.92, 0)))
	var arm := Node3D.new()
	arm.position = Vector3(side * 0.55, 1.55, 0)
	root.add_child(arm)
	var board := Art.box(Vector3(1.05, 0.24, 0.05), Art.bark_material(SIGN_WOOD, 4.0))
	arm.add_child(board)
	# The pointed end.
	var point := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.24, 0.2, 0.05)
	point.mesh = prism
	point.material_override = Art.bark_material(SIGN_WOOD, 4.0)
	point.position = Vector3(side * 0.62, 0, 0)
	point.rotation.z = -side * PI / 2.0
	arm.add_child(point)
	for face: float in [1.0, -1.0]:
		var text := Art.label(title, 40)
		text.position = Vector3(0, 0, face * 0.03)
		text.rotation.y = 0.0 if face > 0.0 else PI
		arm.add_child(text)
	_add_post_body(root, 0.1, 1.9)
	return root


# A cluster of toadstools: red caps with white spots.
static func mushrooms(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Mushrooms"
	var stem := Art.material(Color("#efe6d2"), 0.8)
	var cap := Art.material(Color("#c2341f"), 0.45, {"rim_enabled": true, "rim": 0.3})
	var spot := Art.material(Color("#fbf5e6"), 0.6)
	for i in rng.randi_range(2, 4):
		var size := rng.randf_range(0.6, 1.2)
		var at := Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
		var height := 0.16 * size
		root.add_child(Art.cylinder(0.025 * size, 0.035 * size, height, stem, at + Vector3(0, height / 2.0, 0), 8))
		var top := at + Vector3(0, height, 0)
		root.add_child(Art.sphere(0.09 * size, cap, top, Vector3(1, 0.55, 1)))
		for k in 4:
			var angle := TAU * k / 4.0 + rng.randf()
			root.add_child(Art.sphere(0.014 * size, spot, top + Vector3(cos(angle) * 0.055, 0.035, sin(angle) * 0.055) * size))
	return root


# A ribbed pumpkin with a curly stem, like the ones piled up all over Pottsfield.
static func pumpkin(rng: RandomNumberGenerator, size := 1.0) -> Node3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	sphere.radial_segments = 32
	sphere.rings = 14
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var v := vertices[i]
		var ribs := 1.0 - 0.08 * absf(sin(atan2(v.z, v.x) * 5.0))
		vertices[i] = Vector3(v.x * ribs, v.y * 0.72, v.z * ribs)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var tool := SurfaceTool.new()
	tool.create_from_arrays(arrays)
	tool.index()
	tool.generate_normals()
	var root := Node3D.new()
	root.name = "Pumpkin"
	var orange := Color("#e07a22").lerp(Color("#f2a33a"), rng.randf())
	var body := Art.instance(tool.commit(), Art.material(orange, 0.5, {"rim_enabled": true, "rim": 0.25}), Vector3(0, 0.2, 0))
	root.add_child(body)
	var stem := Art.cylinder(0.025, 0.04, 0.12, Art.bark_material(Color("#5a6a2a"), 3.0), Vector3(0, 0.45, 0), 6)
	stem.rotation.z = rng.randf_range(-0.4, 0.4)
	root.add_child(stem)
	root.scale = Vector3.ONE * size
	root.rotation.y = rng.randf() * TAU
	return root


# An old tree stump with a ring of moss.
static func stump(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Stump"
	var radius := rng.randf_range(0.3, 0.45)
	root.add_child(Art.cylinder(radius * 0.9, radius * 1.25, 0.45, Art.bark_material(Color("#6a5240"), 1.2), Vector3(0, 0.22, 0), 12))
	root.add_child(Art.cylinder(radius * 0.88, radius * 0.88, 0.02, Art.material(Color("#c4a273")), Vector3(0, 0.455, 0), 12))
	return root


# A blossom for the meadow: a little five-petalled flower, flat-ish, coloured per instance.
static func blossom_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for petal in 5:
		var angle := TAU * petal / 5.0
		var out := Vector3(cos(angle), 0, sin(angle))
		var side := out.cross(Vector3.UP) * 0.03
		var tip := out * 0.07 + Vector3(0, 0.015, 0)
		for v: Vector3 in [Vector3.ZERO, tip + side, tip - side]:
			tool.set_normal(Vector3.UP)
			tool.set_color(Color(1, 1, 1) if v != Vector3.ZERO else Color(1.0, 0.85, 0.3))
			tool.add_vertex(v)
	return tool.commit()


# Something thin and solid, so the gnome bumps into posts instead of walking through them.
static func _add_post_body(root: Node3D, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	shape.position.y = height / 2.0
	body.add_child(shape)
	root.add_child(body)
