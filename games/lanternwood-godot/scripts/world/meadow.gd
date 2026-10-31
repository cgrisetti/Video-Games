@tool
class_name Meadow
extends RefCounted

# The ground and everything growing on it: the meadow floor with paths worn into it, thousands of
# grass tufts that sway and part around your feet, wildflowers, and far-off hills in the haze.

const GROUND_SHADER := preload("res://shaders/ground.gdshader")
const GRASS_SHADER := preload("res://shaders/grass.gdshader")
const MASK_PIXELS := 512
const GRASS_PATCH := 6.0 # Grass is grown in patches this many metres across, so far ones can be simpler.
const GRASS_NEAR := 22.0 # Full tufts out to here from the camera; simpler, sparser ones beyond.
const GRASS_FAR := 58.0 # Past here the haze hides it, so it isn't drawn.
const FAR_KEEP := 0.7 # The share of tufts kept in the far patches (they're drawn a little wider).
const BLOSSOM_COLORS := [Color("#f6f1e4"), Color("#f2d24b"), Color("#b79be0"), Color("#e98aa0"), Color("#f39a4a")]


# The mask the ground shader reads: red where a path is worn into the grass (from
# `path_distance(x, z)`, 0 at the path's edge), green where the hedges shade the ground
# (from `hedge_distance(x, z)`). It covers `size` metres, centred on the middle of the Glen.
static func path_mask(size: float, path_distance: Callable, hedge_distance: Callable) -> ImageTexture:
	var image := Image.create(MASK_PIXELS, MASK_PIXELS, false, Image.FORMAT_RGBA8)
	for py in MASK_PIXELS:
		for px in MASK_PIXELS:
			var x := (px + 0.5) / MASK_PIXELS * size - size / 2.0
			var z := (py + 0.5) / MASK_PIXELS * size - size / 2.0
			var worn := 1.0 - smoothstep(-0.3, 0.35, path_distance.call(x, z))
			var shade := 1.0 - smoothstep(0.0, 1.6, hedge_distance.call(x, z))
			image.set_pixel(px, py, Color(worn, shade, 0.0, 1.0))
	return ImageTexture.create_from_image(image)


# Ground that's flat where you play and rises gently, rolling, into the woods: `outside(x, z)` is
# how far a spot is outside the play area (negative inside).
static func rolling(outside: Callable) -> Callable:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.04
	return func(x: float, z: float) -> float:
		var rise := smoothstep(2.0, 14.0, outside.call(x, z))
		return rise * (0.6 + noise.get_noise_2d(x, z) * 1.6 + 0.8)


# The ground, `size` metres across, shaped by `height_at(x, z)`. `solid` gives it a flat floor to
# stand on; an area with hills or a creek in it adds its own (see BerryField).
static func ground(size: float, mask: ImageTexture, height_at: Callable, solid := true, detail := 120) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = detail
	plane.subdivide_depth = detail
	var arrays := plane.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var v := vertices[i]
		vertices[i].y = height_at.call(v.x, v.z)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var tool := SurfaceTool.new()
	tool.create_from_arrays(arrays)
	tool.generate_normals()
	tool.generate_tangents()
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("path_mask", mask)
	material.set_shader_parameter("mask_origin", Vector2(-size / 2.0, -size / 2.0))
	material.set_shader_parameter("mask_size", size)
	var made := Art.instance(tool.commit(), material)
	made.name = "Ground"
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if solid:
		# Something to stand on (the Glen itself is flat).
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = WorldBoundaryShape3D.new()
		body.add_child(shape)
		made.add_child(body)
	return made


# Grass tufts scattered over the meadow. `spot_weight(x, z)` says how thick the grass is at a spot
# (0 none, 1 full height), so it thins out along the paths. `height_at(x, z)` is the ground height.
# Each patch is grown twice: full five-blade tufts for close up, and a sparser set of simpler
# three-blade tufts for further away. Godot swaps between them by distance from the camera, so the
# GPU isn't drawing millions of tiny blades that are only a pixel wide.
static func grass(count: int, area: Rect2, rng: RandomNumberGenerator, spot_weight: Callable, height_at: Callable, material: ShaderMaterial = null) -> Array[MultiMeshInstance3D]:
	var tufts: Array[MultiMeshInstance3D] = []
	if material == null:
		material = ShaderMaterial.new()
		material.shader = GRASS_SHADER
	var columns := maxi(1, ceili(area.size.x / GRASS_PATCH))
	var rows := maxi(1, ceili(area.size.y / GRASS_PATCH))
	var transforms := []
	for i in columns * rows:
		transforms.append([])
	var attempts := count * 2
	var placed := 0
	for i in attempts:
		if placed >= count:
			break
		var x := rng.randf_range(area.position.x, area.end.x)
		var z := rng.randf_range(area.position.y, area.end.y)
		var weight: float = spot_weight.call(x, z)
		if weight <= 0.05 or rng.randf() > weight + 0.15:
			continue
		var height := rng.randf_range(0.6, 1.25) * lerpf(0.4, 1.0, weight)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(1.0, height, 1.0) * rng.randf_range(0.85, 1.2))
		var cell_x := clampi(int((x - area.position.x) / GRASS_PATCH), 0, columns - 1)
		var cell_z := clampi(int((z - area.position.y) / GRASS_PATCH), 0, rows - 1)
		transforms[cell_z * columns + cell_x].append(Transform3D(basis, Vector3(x, height_at.call(x, z), z)))
		placed += 1
	var near_mesh := _tuft_mesh(5, 4)
	var far_mesh := _tuft_mesh(3, 2)
	for list in transforms:
		if list.is_empty():
			continue
		var dryness := []
		for k in list.size():
			dryness.append(clampf(rng.randf() * rng.randf() * 1.3, 0.0, 1.0))
		var near := _patch(near_mesh, list, dryness, 1.0)
		near.material_override = material
		near.visibility_range_end = GRASS_NEAR
		near.visibility_range_end_margin = 2.0
		tufts.append(near)
		# The far set: every so often a tuft, a bit wider to fill the gaps.
		var far_list := []
		var far_dryness := []
		for k in list.size():
			if fmod(k * 0.618034, 1.0) < FAR_KEEP:
				far_list.append(list[k])
				far_dryness.append(dryness[k])
		if far_list.is_empty():
			continue
		var far := _patch(far_mesh, far_list, far_dryness, 1.0 / sqrt(FAR_KEEP))
		far.material_override = material
		far.visibility_range_begin = GRASS_NEAR
		far.visibility_range_begin_margin = 2.0
		far.visibility_range_end = GRASS_FAR
		tufts.append(far)
	return tufts


static func _patch(mesh: Mesh, transforms: Array, dryness: Array, widen: float) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for k in transforms.size():
		var placed: Transform3D = transforms[k]
		placed.basis = placed.basis.scaled_local(Vector3(widen, 1.0, widen))
		multimesh.set_instance_transform(k, placed)
		multimesh.set_instance_custom_data(k, Color(dryness[k], 0, 0, 0))
	var made := MultiMeshInstance3D.new()
	made.name = "Grass"
	made.multimesh = multimesh
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made


# Wildflowers dotted through the grass.
static func flowers(count: int, area: Rect2, rng: RandomNumberGenerator, spot_weight: Callable, height_at: Callable) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = Props.blossom_mesh()
	var spots := []
	var tries := 0
	while spots.size() < count and tries < count * 20:
		tries += 1
		var x := rng.randf_range(area.position.x, area.end.x)
		var z := rng.randf_range(area.position.y, area.end.y)
		var weight: float = spot_weight.call(x, z)
		if weight < 0.6:
			continue
		# Flowers grow in drifts: a few close together.
		for k in rng.randi_range(3, 7):
			var at := Vector3(x + rng.randfn() * 0.5, 0, z + rng.randfn() * 0.5)
			at.y = height_at.call(at.x, at.z) + rng.randf_range(0.18, 0.32)
			spots.append([at, BLOSSOM_COLORS[rng.randi() % BLOSSOM_COLORS.size()] if k == 0 or rng.randf() < 0.3 else null])
	multimesh.instance_count = spots.size()
	var color: Color = BLOSSOM_COLORS[0]
	for i in spots.size():
		if spots[i][1] != null:
			color = spots[i][1]
		var basis := Basis(Vector3.UP, rng.randf() * TAU).rotated(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)).scaled(Vector3.ONE * rng.randf_range(0.7, 1.3))
		multimesh.set_instance_transform(i, Transform3D(basis, spots[i][0]))
		multimesh.set_instance_color(i, color)
	var made := MultiMeshInstance3D.new()
	made.name = "Flowers"
	made.multimesh = multimesh
	made.material_override = Art.material(Color.WHITE, 0.6, {"vertex_color_use_as_albedo": true, "cull_mode": BaseMaterial3D.CULL_DISABLED, "backlight_enabled": true, "backlight": Color(0.4, 0.35, 0.3)})
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	made.visibility_range_end = 60.0
	return made


# Rolling hills far off round the edge of the world, softened by the haze.
static func far_hills(inner: float, outer: float, seed: int) -> MeshInstance3D:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var around := 96
	var rings := 8
	for a in around:
		for r in rings:
			var corners := []
			for c: Array in [[a, r], [a + 1, r], [a + 1, r + 1], [a, r + 1]]:
				var angle: float = TAU * c[0] / around
				var distance: float = lerpf(inner, outer, float(c[1]) / rings)
				var x := cos(angle) * distance
				var z := sin(angle) * distance
				var rise := sin(float(c[1]) / rings * PI * 0.5)
				corners.append(Vector3(x, (4.0 + noise.get_noise_2d(x, z) * 14.0 + 10.0) * rise, z))
			for k: int in [0, 2, 1, 0, 3, 2]:
				tool.add_vertex(corners[k])
	tool.generate_normals()
	var made := Art.instance(tool.commit(), Art.material(Color("#56703a"), 1.0), Vector3(0, -0.5, 0), false)
	made.name = "FarHills"
	return made


# One tuft: `blades` blades, each a tapering strip of `rows` pieces that curves over toward its tip.
static func _tuft_mesh(blades: int, rows: int) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for blade in blades:
		var angle := TAU * blade / blades + rng.randf_range(-0.4, 0.4)
		var out := Vector3(cos(angle), 0, sin(angle))
		var root := out * rng.randf_range(0.0, 0.07)
		var side := out.cross(Vector3.UP).normalized()
		var height := rng.randf_range(0.28, 0.42)
		var lean := rng.randf_range(0.06, 0.16)
		var width := rng.randf_range(0.025, 0.035) * (5.0 / blades) ** 0.5
		var previous := []
		for r in rows + 1:
			var t := float(r) / rows
			var center := root + out * lean * t * t + Vector3(0, height * t, 0)
			var half := width * (1.0 - t)
			var row := [center - side * half, center + side * half, t]
			if r > 0:
				var a: Array = previous
				var quad := [a[0], a[1], row[1], row[0]]
				var heights := [a[2], a[2], row[2], row[2]]
				for k: int in [0, 1, 2, 0, 2, 3]:
					tool.set_uv(Vector2(0.0, heights[k]))
					tool.set_normal(-out)
					tool.add_vertex(quad[k])
			previous = row
	return tool.commit()
