## One luminous footprint a Star-Inked Vellum card leaves behind its caster
## (05 GDD §3.3): a small glowing oval that fades away. Pooled.
class_name GlowFootprint
extends PooledFx

const LIFETIME: float = 1.0
const SIZE: Vector2 = Vector2(0.16, 0.3)
const GLOW: float = 3.0
const FLOOR_OFFSET: float = 0.03

var _age: float = 0.0
var _material: StandardMaterial3D


static func make() -> GlowFootprint:
	var print_mark: GlowFootprint = GlowFootprint.new()
	print_mark.name = "GlowFootprint"
	print_mark._material = StandardMaterial3D.new()
	print_mark._material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	print_mark._material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	print_mark._material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	print_mark._material.emission_enabled = true
	print_mark._material.emission_energy_multiplier = GLOW
	var oval: CylinderMesh = CylinderMesh.new()
	oval.top_radius = 0.5
	oval.bottom_radius = 0.5
	oval.height = 0.01
	oval.radial_segments = 16
	oval.material = print_mark._material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = oval
	mesh.scale = Vector3(SIZE.x, 1.0, SIZE.y)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	print_mark.add_child(mesh)
	return print_mark


func place(where: Vector3, facing: float, colour: Color) -> void:
	global_position = Vector3(where.x, where.y + FLOOR_OFFSET, where.z)
	rotation = Vector3(0.0, facing, 0.0)
	_age = 0.0
	_material.albedo_color = colour
	_material.emission = colour


func _process(delta: float) -> void:
	_age += delta
	_material.albedo_color.a = 1.0 - clampf(_age / LIFETIME, 0.0, 1.0)
	if _age >= LIFETIME:
		finish()
