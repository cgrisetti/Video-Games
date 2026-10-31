class_name Raspberry
extends RefCounted

# Raspberries to pick: a plump cone of glossy little drupelets with a green leafy cap, and the
# golden raspberry, the same berry in shining gold, bigger, with rays of sunshine fanning out
# behind it and a warm glow lighting the ground round it. The meshes are built once and shared.

const BERRY := Color("#c8255a")
const GOLD := Color("#ffc23c")

static var _berry_mesh: ArrayMesh
static var _cap_mesh: ArrayMesh
static var _sunburst: ImageTexture


static func make() -> Node3D:
	var root := Node3D.new()
	root.name = "Raspberry"
	var juicy := Art.material(BERRY, 0.3, {"clearcoat_enabled": true, "clearcoat": 0.7, "clearcoat_roughness": 0.2, "rim_enabled": true, "rim": 0.4, "rim_tint": 0.6, "subsurf_scatter_enabled": true, "subsurf_scatter_strength": 0.4})
	root.add_child(Art.instance(berry_mesh(), juicy))
	root.add_child(Art.instance(cap_mesh(), Art.material(Color("#4e8f36"), 0.7, {"rim_enabled": true, "rim": 0.3})))
	return root


# The golden raspberry. Its rays are kept in its "rays" meta (so the game can turn them) and its
# glow in "glow".
static func make_golden() -> Node3D:
	var root := Node3D.new()
	root.name = "GoldenRaspberry"
	var berry := Node3D.new()
	berry.scale = Vector3.ONE * 1.35
	var gold := Art.material(GOLD, 0.25, {"metallic": 0.6, "emission_enabled": true, "emission": Color("#7a5200"), "emission_energy_multiplier": 1.2, "rim_enabled": true, "rim": 0.5})
	berry.add_child(Art.instance(berry_mesh(), gold))
	berry.add_child(Art.instance(cap_mesh(), Art.material(Color("#b8c94a"), 0.5, {"emission_enabled": true, "emission": Color("#2a3300")})))
	root.add_child(berry)
	# The rays always face the camera, so they look the same from every side.
	var rays := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(3.4, 3.4)
	rays.mesh = quad
	var shine := ShaderMaterial.new()
	shine.shader = preload("res://shaders/rays.gdshader")
	shine.set_shader_parameter("rays", sunburst())
	rays.material_override = shine
	rays.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rays)
	var glow := OmniLight3D.new()
	glow.light_color = Color("#ffd36b")
	glow.light_energy = 2.5
	glow.omni_range = 5.0
	root.add_child(glow)
	root.set_meta("rays", rays)
	root.set_meta("glow", glow)
	return root


# Rings of little round drupelets, widest near the top and narrowing to a rounded tip, round a
# core that fills the gaps, all in one mesh so each berry is quick to draw.
static func berry_mesh() -> ArrayMesh:
	if _berry_mesh:
		return _berry_mesh
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_sphere(tool, Vector3(0, -0.07, 0), Vector3(0.27, 0.3, 0.27), 16)
	var bump := 0.1
	var rings := 7
	for ring in rings + 1:
		var t := float(ring) / rings # 0 at the top, 1 at the tip.
		var y := 0.22 - t * 0.6
		var radius := 0.34 * sin(PI * (0.25 + 0.7 * t))
		var count := maxi(1, roundi(TAU * radius / (bump * 1.7)))
		for i in count:
			var angle := (i + (ring % 2) * 0.5) / count * TAU # Every other ring is turned half a step.
			_add_sphere(tool, Vector3(cos(angle) * radius, y, sin(angle) * radius), Vector3.ONE * bump * (1.0 - 0.15 * t), 8)
	_berry_mesh = tool.commit()
	return _berry_mesh


# Five little leaves spreading out from the top, and a short stem.
static func cap_mesh() -> ArrayMesh:
	if _cap_mesh:
		return _cap_mesh
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.025
	stem.bottom_radius = 0.035
	stem.height = 0.16
	stem.radial_segments = 6
	tool.append_from(stem, 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.38, 0)))
	for i in 5:
		var leaf := CylinderMesh.new()
		leaf.top_radius = 0.0
		leaf.bottom_radius = 0.08
		leaf.height = 0.28
		leaf.radial_segments = 6
		var place := Transform3D(Basis.IDENTITY.scaled(Vector3(0.4, 1.0, 1.0)), Vector3.ZERO)
		place = Transform3D(Basis(Vector3.BACK, -PI / 2.0 - 0.35), Vector3.ZERO) * place
		place = Transform3D(Basis.IDENTITY, Vector3(0.13, 0.3, 0)) * place
		place = Transform3D(Basis(Vector3.UP, TAU * i / 5.0), Vector3.ZERO) * place
		tool.append_from(leaf, 0, place)
	tool.generate_normals()
	_cap_mesh = tool.commit()
	return _cap_mesh


static func _add_sphere(tool: SurfaceTool, at: Vector3, radii: Vector3, segments: int) -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	tool.append_from(sphere, 0, Transform3D(Basis.IDENTITY.scaled(radii * 2.0), at))


# Rays of sunshine: a soft glow with long and short rays round it, painted once.
static func sunburst() -> ImageTexture:
	if _sunburst:
		return _sunburst
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var middle := size / 2.0
	for y in size:
		for x in size:
			var offset := Vector2(x + 0.5 - middle, y + 0.5 - middle)
			var r := offset.length() / middle
			var angle := offset.angle()
			var glow := clampf(1.0 - r, 0.0, 1.0)
			var color := Color(1.0, 0.95, 0.75, 0.9 * glow * glow)
			# 24 rays, alternately long and short, each a thin wedge that fades along its length.
			var sector := fposmod(angle / TAU * 24.0, 1.0)
			var which := int(fposmod(angle / TAU * 24.0, 24.0))
			var long := which % 2 == 0
			var reach := 0.97 if long else 0.55
			var wedge := 1.0 - smoothstep(0.0, 0.32 if long else 0.24, absf(sector - 0.5) * 2.0 - 0.6)
			var ray := wedge * clampf(1.0 - r / reach, 0.0, 1.0)
			color = color.blend(Color(1.0, 0.86, 0.45, 0.85 * ray))
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	_sunburst = ImageTexture.create_from_image(image)
	return _sunburst
