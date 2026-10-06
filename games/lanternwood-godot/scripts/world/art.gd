@tool
class_name Art
extends RefCounted

# Shared building blocks for Lanternwood's scenery: materials, lumpy organic shapes, and the
# leaf textures, all made in code so there are no art files to keep in step. Everything in
# scripts/world/ uses these, so a change here (a leaf shape, a bark colour) shows up everywhere.
# The look is described in STYLE_GUIDE.md.

const LEAVES_SHADER := preload("res://shaders/leaves.gdshader")
const BARK_SHADER := preload("res://shaders/bark.gdshader")
const ROCK_SHADER := preload("res://shaders/rock.gdshader")

static var _materials := {}
static var _leaf_textures := {}


# A plain material, shared between everything with the same settings.
static func material(color: Color, roughness := 0.85, extra := {}) -> StandardMaterial3D:
	var key := "%s %s %s" % [color.to_html(), roughness, extra]
	if not _materials.has(key):
		var made := StandardMaterial3D.new()
		made.albedo_color = color
		made.roughness = roughness
		for property in extra:
			made.set(property, extra[property])
		_materials[key] = made
	return _materials[key]


# Glowing material for lantern paper, windows and fireflies.
static func glow_material(color: Color, energy := 2.0) -> StandardMaterial3D:
	return material(color, 0.6, {"emission_enabled": true, "emission": color, "emission_energy_multiplier": energy})


# Wood: the bark shader with this colour, striped along the length of the piece.
static func bark_material(color: Color, stripes := 1.0) -> ShaderMaterial:
	var key := "bark %s %s" % [color.to_html(), stripes]
	if not _materials.has(key):
		var made := ShaderMaterial.new()
		made.shader = BARK_SHADER
		made.set_shader_parameter("bark_color", color)
		made.set_shader_parameter("stripe_scale", stripes)
		_materials[key] = made
	return _materials[key]


static func rock_material(color: Color, moss: Color) -> ShaderMaterial:
	var key := "rock %s %s" % [color.to_html(), moss.to_html()]
	if not _materials.has(key):
		var made := ShaderMaterial.new()
		made.shader = ROCK_SHADER
		made.set_shader_parameter("rock_color", color)
		made.set_shader_parameter("moss_color", moss)
		_materials[key] = made
	return _materials[key]


# Leaves: cards of leaf clusters that sway in the wind and glow when the sun is behind them.
# `kind` picks the leaf shape: "broad" (oak, hedge), "small" (birch), "needle" (pine), "fern".
static func leaf_material(kind: String, tip: Color, base: Color, sway := 1.0) -> ShaderMaterial:
	var key := "leaves %s %s %s %s" % [kind, tip.to_html(), base.to_html(), sway]
	if not _materials.has(key):
		var made := ShaderMaterial.new()
		made.shader = LEAVES_SHADER
		made.set_shader_parameter("leaf_texture", leaf_texture(kind))
		made.set_shader_parameter("tip_color", tip)
		made.set_shader_parameter("base_color", base)
		made.set_shader_parameter("sway", sway)
		_materials[key] = made
	return _materials[key]


# A card's worth of leaves, drawn into a texture: white where there's a leaf (with darker veins
# and edges), clear in between. The shader colours it.
static func leaf_texture(kind: String) -> ImageTexture:
	if _leaf_textures.has(kind):
		return _leaf_textures[kind]
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"needle":
			for i in 70:
				var start := Vector2(rng.randf_range(0.1, 0.9), rng.randf_range(0.15, 0.95)) * size
				var angle := rng.randf_range(-2.4, -0.7)
				_draw_leaf(image, start, angle, rng.randf_range(0.18, 0.3) * size, 0.035 * size, rng.randf_range(0.75, 1.0), true)
		"fern":
			for side: float in [-1.0, 1.0]:
				for i in 14:
					var t := float(i) / 14.0
					var start := Vector2(0.5 * size, (0.95 - t * 0.85) * size)
					var angle := -PI / 2 + side * (1.15 - t * 0.4)
					_draw_leaf(image, start, angle, (0.32 - t * 0.2) * size, (0.07 - t * 0.03) * size, rng.randf_range(0.8, 1.0), false)
		_:
			var count := 26 if kind == "broad" else 40
			var length := 0.24 if kind == "broad" else 0.15
			for i in count:
				var start := Vector2(rng.randf_range(0.18, 0.82), rng.randf_range(0.18, 0.82)) * size
				var angle := rng.randf_range(-PI, PI)
				_draw_leaf(image, start, angle, rng.randf_range(0.8, 1.2) * length * size, length * 0.45 * size, rng.randf_range(0.7, 1.0), false)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_leaf_textures[kind] = texture
	return texture


# One leaf: an almond shape from `start` along `angle`, lighter in the middle, with a midrib.
static func _draw_leaf(image: Image, start: Vector2, angle: float, length: float, width: float, shade: float, thin: bool) -> void:
	var along := Vector2.from_angle(angle)
	var across := along.orthogonal()
	var size := image.get_width()
	var reach := length + width
	var low := (start - Vector2(reach, reach)).floor()
	var high := (start + Vector2(reach, reach)).ceil()
	for y in range(maxi(int(low.y), 0), mini(int(high.y), size)):
		for x in range(maxi(int(low.x), 0), mini(int(high.x), size)):
			var offset := Vector2(x, y) - start
			var t := offset.dot(along) / length
			if t < 0.0 or t > 1.0:
				continue
			var half := width * (sin(t * PI) if not thin else 1.0 - t * 0.6)
			var side := absf(offset.dot(across))
			if side > half:
				continue
			var edge := side / maxf(half, 0.001)
			var value := shade * (1.0 - 0.35 * edge * edge) * (0.8 + 0.2 * t)
			if side < 0.9 and not thin:
				value *= 0.78 # The midrib.
			var old := image.get_pixel(x, y)
			if old.a > 0.0 and old.r > value:
				continue # A leaf already in front.
			image.set_pixel(x, y, Color(value, value, value, 1.0))


# A lumpy, rounded shape (a rock, a bush's core, a hill), from a sphere pushed in and out by noise.
static func blob_mesh(radius: float, lumpiness: float, seed: int, squash := Vector3.ONE, rings := 12) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = rings * 2
	sphere.rings = rings
	var arrays := sphere.get_mesh_arrays()
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 1.1 / radius
	noise.fractal_octaves = 3
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var v := vertices[i]
		var push := 1.0 + lumpiness * noise.get_noise_3dv(v)
		vertices[i] = v * push * squash
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var tool := SurfaceTool.new()
	tool.create_from_arrays(arrays)
	# Seams at the sphere's edge share positions, so weld them for smooth shading.
	tool.index()
	tool.generate_normals()
	return tool.commit()


# A trunk or branch: a tapering tube that leans and bends a little as it rises.
# `points` is the path from bottom to top; `radii` the thickness at each point.
static func tube_mesh(points: PackedVector3Array, radii: PackedFloat32Array, sides := 9) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := 0.0
	for i in points.size():
		var forward := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side := forward.cross(Vector3.FORWARD if absf(forward.y) > 0.9 else Vector3.UP).normalized()
		var up := side.cross(forward).normalized()
		if i > 0:
			length += points[i].distance_to(points[i - 1])
		for s in sides + 1:
			var a := TAU * s / sides
			var normal := (side * cos(a) + up * sin(a)).normalized()
			tool.set_normal(normal)
			tool.set_uv(Vector2(float(s) / sides, length))
			tool.add_vertex(points[i] + normal * radii[i])
	var ring := sides + 1
	for i in points.size() - 1:
		for s in sides:
			var a := i * ring + s
			var b := a + ring
			tool.add_index(a)
			tool.add_index(b)
			tool.add_index(a + 1)
			tool.add_index(a + 1)
			tool.add_index(b)
			tool.add_index(b + 1)
	return tool.commit()


# Leaf cards spread through a rounded volume (a tree's crown, a bush, a hedge): each card faces
# roughly outward, and its normal points away from the middle of the volume, so the whole crown
# shades like one soft, leafy ball instead of a mess of flat cards.
# `center` and `radii` describe the volume; COLOR.r carries how far out a card is (outer cards
# sway more in the wind).
static func add_leaf_cards(tool: SurfaceTool, rng: RandomNumberGenerator, center: Vector3, radii: Vector3, count: int, card_size: float, shell := 0.55) -> void:
	for i in count:
		# A spot in the outer part of the volume, where leaves catch the light.
		var direction := Vector3(rng.randfn(), rng.randfn() * 0.8, rng.randfn()).normalized()
		var depth := lerpf(shell, 1.0, sqrt(rng.randf()))
		var spot := center + direction * radii * depth
		var normal := ((spot - center) / (radii * radii)).normalized()
		# Face outward, twisted a little at random, with some cards tilted toward the sky.
		var facing := (normal + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.0, 0.6), rng.randf_range(-0.6, 0.6))).normalized()
		var right := facing.cross(Vector3.UP if absf(facing.y) < 0.95 else Vector3.RIGHT).normalized().rotated(facing, rng.randf_range(-PI, PI))
		var up := right.cross(facing).normalized()
		var half := card_size * rng.randf_range(0.75, 1.25) * 0.5
		var corners := [spot - right * half - up * half, spot + right * half - up * half, spot + right * half + up * half, spot - right * half + up * half]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		var color := Color(depth, rng.randf(), 0.0)
		for k: int in [0, 1, 2, 0, 2, 3]:
			tool.set_color(color)
			tool.set_normal(normal)
			tool.set_uv(uvs[k])
			tool.add_vertex(corners[k])


# A MeshInstance3D with this mesh and material, placed at `at`.
static func instance(mesh: Mesh, mat: Material = null, at := Vector3.ZERO, shadows := true) -> MeshInstance3D:
	var made := MeshInstance3D.new()
	made.mesh = mesh
	if mat:
		made.material_override = mat
	made.position = at
	if not shadows:
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made


static func box(size: Vector3, mat: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return instance(mesh, mat, at)


static func cylinder(radius_top: float, radius_bottom: float, height: float, mat: Material, at := Vector3.ZERO, sides := 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_top
	mesh.bottom_radius = radius_bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return instance(mesh, mat, at)


static func sphere(radius: float, mat: Material, at := Vector3.ZERO, squash := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	var made := instance(mesh, mat, at)
	made.scale = squash
	return made


# A sign's lettering, in the storybook serif.
static func label(text: String, size := 64, color := Color("#3b2a1a")) -> Label3D:
	var made := Label3D.new()
	made.text = text
	made.font = book_font(true)
	made.font_size = size
	made.pixel_size = 0.004
	made.modulate = color
	made.outline_size = 0
	made.double_sided = false
	made.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	made.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return made


static func book_font(title := false) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Luminari", "Palatino", "Palatino Linotype", "Georgia", "serif"] if title else ["Palatino", "Palatino Linotype", "Book Antiqua", "Georgia", "serif"])
	return font
