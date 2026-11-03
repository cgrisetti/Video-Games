## Bramble-Bridge's watermill wheel (06_WORLD_AND_CALLINGS.md §1; kit_watermill_wheel of
## 17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4.1): a 4.4 m oak wheel of 12
## spokes and 24 angled bucket-paddles bound in iron, turning in the canal
## with a ring of splashes where its paddles strike the water. It builds itself
## in code (one shared mesh) and spins around its local Y axis; the level
## builder stands it on its side and sets the mill-race flume beside it.
class_name WatermillWheel
extends Node3D

const RADIUS: float = 2.2
const THICKNESS: float = 0.8
## Radians per second.
const SPIN_SPEED: float = 0.55
const SPLASH_COLOR: Color = Color(0.92, 0.97, 1.0, 0.7)

var _wheel: MeshInstance3D


func _ready() -> void:
	_wheel = MeshInstance3D.new()
	_wheel.name = "Wheel"
	_wheel.mesh = WorldAssetCatalog.watermill_wheel_mesh(RADIUS, THICKNESS)
	add_child(_wheel)
	add_child(_splashes())


func _process(delta: float) -> void:
	_wheel.rotate_object_local(Vector3.UP, SPIN_SPEED * delta)


## White water thrown up where the paddles bite (it sits at the wheel's foot, so it's not spun).
func _splashes() -> CPUParticles3D:
	var splash: CPUParticles3D = CPUParticles3D.new()
	splash.name = "Splash"
	# The builder stands the wheel on its side, so its local +Z points straight down to its foot.
	splash.position = Vector3(0.0, 0.0, RADIUS * 0.85)
	splash.amount = 16
	splash.lifetime = 0.9
	splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	splash.emission_box_extents = Vector3(0.6, THICKNESS * 0.5, 0.1)
	splash.direction = Vector3(0.0, 0.0, -1.0)
	splash.spread = 40.0
	splash.initial_velocity_min = 0.8
	splash.initial_velocity_max = 1.6
	splash.gravity = Vector3(0.0, -6.0, 0.0)
	splash.local_coords = false
	var drop: SphereMesh = SphereMesh.new()
	drop.radius = 0.06
	drop.height = 0.12
	drop.radial_segments = 6
	drop.rings = 3
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = SPLASH_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = material
	splash.mesh = drop
	splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return splash
