## A Friction Isle's Beacon as the other isles see it (docs/14 §6.4, docs/33 §3.1): on the isle's far
## silhouette, a fire in the Beacon's colour and a column of smoke leaning with the wind, burning only while
## the Beacon is lit. By day a beacon reads by its smoke, with its fire as the spark at its foot. From any
## quay the party sees which isles they have brought back, and the one they're bound for next stays dark.
## One glow and a dozen puffs, so it's cheap on every peer.
class_name FarBeacon
extends Node3D

## The fire stands this high over the Beacon's ground (metres, before the silhouette's lift): the brazier's top.
const FIRE_ABOVE_GROUND: float = 9.0
## The fire's glow. At 1.6 to 2.8 km it's a few pixels across, so it's big and bright.
const FIRE_RADIUS: float = 4.0
const FIRE_ENERGY: float = 4.0
## The smoke column: puffs, each one's life (seconds), its climb (m/s, then a gentle lift), its size (metres
## across) and the wind's lean (the Caldera's world wind blows from the Breach, north-west to south-east).
const SMOKE_PUFFS: int = 14
const SMOKE_LIFETIME: float = 9.0
const SMOKE_CLIMB: Vector2 = Vector2(1.5, 3.0)
const SMOKE_LIFT: Vector3 = Vector3(1.0, 1.3, 0.75)
const SMOKE_PUFF: Vector2 = Vector2(8.0, 20.0)
const SMOKE_COLOR: Color = Color(0.56, 0.54, 0.52, 0.5)

@export var isle_id: StringName = &""

var fire: MeshInstance3D
var smoke: CPUParticles3D


func _ready() -> void:
	name = "FarBeacon"
	var isle: IslandGridResource = CalderaAtlas.isle(isle_id)
	var flame: Color = isle.accent_color if isle != null else CalderaKit.SAFFRON
	fire = CalderaKit.glow_sphere(self, "Fire", Vector3.ZERO, FIRE_RADIUS, flame.lerp(CalderaKit.SAFFRON, 0.5), FIRE_ENERGY)
	smoke = _make_smoke()
	add_child(smoke)
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
	_refresh()


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


func is_lit() -> bool:
	var isle: IslandGridResource = CalderaAtlas.isle(isle_id)
	return isle != null and isle.beacon_flag != &"" and CalderaWorldState.current != null \
		and CalderaWorldState.current.get_flag(isle.beacon_flag)


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_refresh()


func _refresh() -> void:
	var lit: bool = is_lit()
	visible = lit
	smoke.emitting = lit


func _make_smoke() -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.name = "Smoke"
	particles.position = Vector3(0.0, FIRE_RADIUS, 0.0)
	particles.amount = SMOKE_PUFFS
	particles.lifetime = SMOKE_LIFETIME
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = FIRE_RADIUS
	particles.direction = Vector3.UP
	particles.spread = 10.0
	particles.gravity = SMOKE_LIFT
	particles.initial_velocity_min = SMOKE_CLIMB.x
	particles.initial_velocity_max = SMOKE_CLIMB.y
	particles.scale_amount_min = SMOKE_PUFF.x
	particles.scale_amount_max = SMOKE_PUFF.y
	var puff: SphereMesh = SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 6
	puff.rings = 3
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = SMOKE_COLOR
	material.vertex_color_use_as_albedo = true
	puff.material = material
	particles.mesh = puff
	# Each puff thickens as it leaves the fire and thins away as it climbs.
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.15, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(fade.get_point_count() - 1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = fade
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles
