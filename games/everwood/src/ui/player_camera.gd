## One split-screen player's third-person camera. In the assisted modes it
## soft-locks: it swings round behind the player to keep the boss in view.
## The right stick, the arrow keys or the mouse turn it; in the assisted modes
## the soft-lock takes over again a moment after you let go.
class_name PlayerCamera
extends Camera3D

const DISTANCE: float = 8.0
const HEIGHT: float = 5.0
const LOOK_HEIGHT: float = 1.3
const FOLLOW_SHARPNESS: float = 10.0
## Radians per second at full stick.
const ORBIT_SPEED: float = 2.6
const SOFT_LOCK_SHARPNESS: float = 3.0
## Closer than this to the boss, the soft-lock stops swinging (it would spin).
const LOCK_MIN_DISTANCE: float = 2.5
const FIELD_OF_VIEW: float = 62.0
## After you turn the camera yourself, the soft-lock waits this long before swinging back.
const LOCK_RESUME_DELAY: float = 1.2
## How far in front of a wall or pillar the camera stops when one is in the way.
const WALL_CLEARANCE: float = 0.4

var actor: ActorBase
var yaw: float = 0.0

var _focus: Vector3 = Vector3.ZERO
var _manual_hold: float = 0.0


func follow(target_actor: ActorBase) -> void:
	actor = target_actor
	yaw = target_actor.rotation.y
	_focus = target_actor.global_position


func _ready() -> void:
	name = "PlayerCamera"
	fov = FIELD_OF_VIEW
	near = 0.1
	far = 300.0
	# Moved every rendered frame from the actor's interpolated position.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	current = true
	if is_instance_valid(actor):
		_focus = actor.global_position
		_place()


func _process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	var orbit: float = actor.input.camera_orbit_input if actor.input != null else 0.0
	var mouse_yaw: float = actor.input.take_mouse_yaw() if actor.input != null else 0.0
	var soft_lock: bool = actor.input == null or actor.input.soft_lock_camera()
	_manual_hold = maxf(0.0, _manual_hold - delta)
	if absf(orbit) > 0.01 or absf(mouse_yaw) > 0.0:
		yaw -= orbit * ORBIT_SPEED * delta
		yaw += mouse_yaw
		_manual_hold = LOCK_RESUME_DELAY
	elif soft_lock and _manual_hold <= 0.0:
		var boss: ActorBase = actor.soft_target()
		if boss != null:
			var to_boss: Vector3 = boss.global_position - actor.global_position
			to_boss.y = 0.0
			if to_boss.length() > LOCK_MIN_DISTANCE:
				yaw = lerp_angle(yaw, atan2(-to_boss.x, -to_boss.z), 1.0 - exp(-SOFT_LOCK_SHARPNESS * delta))
	actor.camera_yaw = yaw
	var target: Vector3 = actor.get_global_transform_interpolated().origin
	_focus = _focus.lerp(target, 1.0 - exp(-FOLLOW_SHARPNESS * delta))
	_place()


func _place() -> void:
	var look_point: Vector3 = _focus + Vector3.UP * LOOK_HEIGHT
	var wanted: Vector3 = _focus + Vector3(sin(yaw), 0.0, cos(yaw)) * DISTANCE + Vector3.UP * HEIGHT
	global_position = _clear_of_walls(look_point, wanted)
	look_at(look_point)


## Pulls the camera in front of any pillar or wall between it and the player.
func _clear_of_walls(from: Vector3, to: Vector3) -> Vector3:
	var world: World3D = get_world_3d()
	if world == null:
		return to
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, ActorBase.LAYER_WORLD)
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	var hit_point: Vector3 = hit["position"]
	return hit_point + (from - to).normalized() * WALL_CLEARANCE
