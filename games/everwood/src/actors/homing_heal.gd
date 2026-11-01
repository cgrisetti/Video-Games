## A glowing heal that flies from the healer to their Soul Tether, curving in
## like a homing missile. Only the target's own peer applies the heal.
class_name HomingHeal
extends Node3D

const SPEED: float = 15.0
const TURN_SHARPNESS: float = 9.0
const ARRIVE_DISTANCE: float = 0.7
const LIFETIME: float = 3.0
const AIM_HEIGHT: float = 1.1
const COLOR: Color = Color(0.45, 1.0, 0.6)

var healer: ActorBase
var target: ActorBase
var amount: float = 0.0
## Hearth Echo: this share of the heal bounces on to the next hurt ally.
var echo: float = 0.0

var _velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0


func configure(from_healer: ActorBase, to_target: ActorBase, heal_amount: float, heal_echo: float) -> void:
	healer = from_healer
	target = to_target
	amount = heal_amount
	echo = heal_echo
	# Launch upward and forward so the arc reads as "flying to you".
	_velocity = (from_healer.facing_vector() + Vector3.UP * 0.8).normalized() * SPEED


func _ready() -> void:
	name = "HomingHeal"
	var orb: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = COLOR
	glow.emission_enabled = true
	glow.emission = COLOR
	glow.emission_energy_multiplier = 3.0
	sphere.material = glow
	orb.mesh = sphere
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(orb)


func _physics_process(delta: float) -> void:
	_age += delta
	if not is_instance_valid(target) or _age > LIFETIME:
		queue_free()
		return
	var aim: Vector3 = target.global_position + Vector3.UP * AIM_HEIGHT
	var to_aim: Vector3 = aim - global_position
	if to_aim.length() <= ARRIVE_DISTANCE:
		if target.is_multiplayer_authority():
			CombatDirector.current.apply_heal(healer, target, amount, echo)
		queue_free()
		return
	var wanted: Vector3 = to_aim.normalized() * SPEED
	_velocity = _velocity.lerp(wanted, 1.0 - exp(-TURN_SHARPNESS * delta))
	global_position += _velocity * delta
