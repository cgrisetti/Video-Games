## A quick burst of light at an actor: a ring racing out across the floor and a
## column rising through them, in the cue's colour. Marks synergy rewards and
## Perfect Guards so everyone can see who earned what.
class_name CueBurst
extends Node3D

const LIFETIME: float = 0.75
const RING_START_RADIUS: float = 0.4
const RING_END_RADIUS: float = 2.8
const COLUMN_HEIGHT: float = 3.6
const GLOW: float = 2.5

var color: Color = Color.WHITE

var _age: float = 0.0
var _ring: MeshInstance3D
var _column: MeshInstance3D
var _material: StandardMaterial3D


func configure(burst_color: Color) -> void:
	color = burst_color


func _ready() -> void:
	name = "CueBurst"
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = color
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = GLOW
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.88
	torus.outer_radius = 1.0
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.material_override = _material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = Vector3(0.0, 0.08, 0.0)
	add_child(_ring)
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 0.55
	cone.height = COLUMN_HEIGHT
	_column = MeshInstance3D.new()
	_column.mesh = cone
	_column.material_override = _material
	_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_column.position = Vector3(0.0, COLUMN_HEIGHT * 0.5, 0.0)
	add_child(_column)
	_process(0.0)


func _process(delta: float) -> void:
	_age += delta
	var t: float = clampf(_age / LIFETIME, 0.0, 1.0)
	var radius: float = lerpf(RING_START_RADIUS, RING_END_RADIUS, 1.0 - pow(1.0 - t, 3.0))
	_ring.scale = Vector3(radius, 1.0, radius)
	_column.scale = Vector3(1.0 - t * 0.6, 0.3 + t * 0.7, 1.0 - t * 0.6)
	_material.albedo_color.a = (1.0 - t) * 0.85
	if t >= 1.0:
		queue_free()
