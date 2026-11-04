## One split-screen player's third-person camera. In the assisted modes it
## soft-locks: it swings round behind the player to keep the boss in view.
## The right stick, the arrow keys or the mouse turn it; in the assisted modes
## the soft-lock takes over again a moment after you let go.
##
## It pitches too (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §6):
## the right stick's Y, PageUp / [ and PageDown / ], or the mouse's Y (while
## the right button is held or mouse-look is on) tilt it from -12 degrees
## (looking up at a crag or a canopy) to +52 (looking down over a fight). From
## +22 (where it starts, its eye 4.8 m up) to +52 it rides a 6.8 m boom; below
## +18 its pivot drops to 1.65 m on a 3.6 m boom, over the hero's shoulder; it
## never sinks within 0.45 m of the ground. Station signs drop out of its view
## while its player has a modal open (the Binder, the Scribery, the Atlas).
##
## A Sign-Flow cast dolly-pulses it (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §8): a
## smooth 0.35 m push toward the hero's shoulder and back over 120 ms, so the
## Offhand Pocket-Draw lands with a beat on that player's screen alone.
class_name PlayerCamera
extends Camera3D

## The classic framing's numbers (kept for the dolly-pulse's shoulder and older checks).
const DISTANCE: float = 8.0
const HEIGHT: float = 5.0
const LOOK_HEIGHT: float = 1.3
## Pitch (18 GDD §6), degrees above the pivot's level (positive looks down on the hero).
const CAM_DEFAULT_PITCH_DEG: float = 22.0
const CAM_MIN_PITCH_DEG: float = -12.0
const CAM_MAX_PITCH_DEG: float = 52.0
## Radians a second at full stick (or a held pitch key).
const CAM_PITCH_SPEED: float = 1.85
## The eye's height over the hero's feet at the default pitch...
const CAM_DEFAULT_HEIGHT_M: float = 4.8
## ...on this boom from +22 to +52 degrees...
const CAM_HIGH_BOOM_M: float = 6.8
## ...and below +18 degrees, over the shoulder: this pivot height on this boom.
const CAM_LOW_PIVOT_HEIGHT_M: float = 1.65
const CAM_LOW_BOOM_M: float = 3.6
const CAM_LOW_BELOW_DEG: float = 18.0
## The camera never sinks closer than this above the ground under it.
const CAM_GROUND_CLEARANCE_M: float = 0.45
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
const DOLLY_PULSE_DISTANCE: float = 0.35
const DOLLY_PULSE_TIME: float = 0.12
## The shoulder the pulse pushes toward: up and to the right of the hero's feet.
const SHOULDER_HEIGHT: float = 1.45
const SHOULDER_SIDE: float = 0.3

var actor: ActorBase
var yaw: float = 0.0
## Degrees, CAM_MIN_PITCH_DEG to CAM_MAX_PITCH_DEG.
var pitch_degrees: float = CAM_DEFAULT_PITCH_DEG

var _focus: Vector3 = Vector3.ZERO
var _manual_hold: float = 0.0
var _dolly_left: float = 0.0
var _dolly_peak: float = 0.0
var _pulses: int = 0
var _listening_to: SignFlowComponent


func follow(target_actor: ActorBase) -> void:
	actor = target_actor
	yaw = target_actor.rotation.y
	_focus = target_actor.global_position


func _ready() -> void:
	name = "PlayerCamera"
	fov = FIELD_OF_VIEW
	near = 0.1
	# Ring 3's horizon stands out to 2.3 km (17 GDD §6.1).
	far = WorldAtmosphereDirector.CAMERA_FAR
	# Moved every rendered frame from the actor's interpolated position.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	current = true
	if is_instance_valid(actor):
		_focus = actor.global_position
		_place()


## The Sign-Flow cast's push toward the shoulder and back.
func dolly_pulse() -> void:
	_dolly_left = DOLLY_PULSE_TIME
	_dolly_peak = 0.0
	_pulses += 1


## How far the pulse has pushed the camera in right now (0 to 0.35 m).
func dolly_offset() -> float:
	if _dolly_left <= 0.0:
		return 0.0
	return DOLLY_PULSE_DISTANCE * sin(PI * (1.0 - _dolly_left / DOLLY_PULSE_TIME))


## The furthest the last pulse pushed in, and how many have played.
func dolly_peak() -> float:
	return _dolly_peak


func dolly_pulses() -> int:
	return _pulses


func _on_sign_flow_cast(_socket: int, _scribe_sign: int) -> void:
	dolly_pulse()


func _process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	if actor.sign_flow != null and _listening_to != actor.sign_flow:
		_listening_to = actor.sign_flow
		actor.sign_flow.sign_flow_cast.connect(_on_sign_flow_cast)
	_dolly_left = maxf(0.0, _dolly_left - delta)
	var orbit: float = actor.input.camera_orbit_input if actor.input != null else 0.0
	var mouse_yaw: float = actor.input.take_mouse_yaw() if actor.input != null else 0.0
	if actor.input != null:
		var tilt: float = actor.input.camera_pitch_input
		var mouse_pitch: float = actor.input.take_mouse_pitch()
		if absf(tilt) > 0.0 or absf(mouse_pitch) > 0.0:
			set_pitch_degrees(pitch_degrees - rad_to_deg(tilt * CAM_PITCH_SPEED * delta) + rad_to_deg(mouse_pitch))
		# Station signs drop out of this player's view while their modal is open.
		set_cull_mask_value(WorldLabelStyle.STATION_LABEL_LAYER, not actor.input.menu_open)
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


## Tilts the camera to `degrees` (held between -12 and +52).
func set_pitch_degrees(degrees: float) -> void:
	pitch_degrees = clampf(degrees, CAM_MIN_PITCH_DEG, CAM_MAX_PITCH_DEG)


## Where the camera pivots, over the hero's feet, at a pitch: 1.65 m below +18
## degrees, rising to hold the eye at 4.8 m at +22 and above.
static func pivot_height(degrees: float) -> float:
	var high: float = CAM_DEFAULT_HEIGHT_M - CAM_HIGH_BOOM_M * sin(deg_to_rad(CAM_DEFAULT_PITCH_DEG))
	return lerpf(CAM_LOW_PIVOT_HEIGHT_M, high, smoothstep(CAM_LOW_BELOW_DEG, CAM_DEFAULT_PITCH_DEG, degrees))


## How long the boom is at a pitch: 3.6 m below +18 degrees, 6.8 m from +22.
static func boom_length(degrees: float) -> float:
	return lerpf(CAM_LOW_BOOM_M, CAM_HIGH_BOOM_M, smoothstep(CAM_LOW_BELOW_DEG, CAM_DEFAULT_PITCH_DEG, degrees))


## The pivot's height over the hero's feet now.
func current_pivot_height() -> float:
	return pivot_height(pitch_degrees)


func _place() -> void:
	var pitch: float = deg_to_rad(pitch_degrees)
	var boom: float = boom_length(pitch_degrees)
	var look_point: Vector3 = _focus + Vector3.UP * pivot_height(pitch_degrees)
	var wanted: Vector3 = look_point + Vector3(sin(yaw), 0.0, cos(yaw)) * boom * cos(pitch) + Vector3.UP * boom * sin(pitch)
	global_position = _above_ground(_clear_of_walls(look_point, wanted))
	var push: float = dolly_offset()
	if push > 0.0:
		var shoulder: Vector3 = _focus + Vector3.UP * SHOULDER_HEIGHT + Vector3(cos(yaw), 0.0, -sin(yaw)) * SHOULDER_SIDE
		global_position = global_position.move_toward(shoulder, push)
		_dolly_peak = maxf(_dolly_peak, push)
	look_at(look_point)


## Lifts the camera clear of the ground (or a roof) under it, by CAM_GROUND_CLEARANCE_M.
func _above_ground(at: Vector3) -> Vector3:
	var floor_y: float = ground_height_under(at)
	if is_nan(floor_y):
		return at
	return Vector3(at.x, maxf(at.y, floor_y + CAM_GROUND_CLEARANCE_M), at.z)


## The ground's height under a spot (the world's colliders, read straight down), or NAN if there's none.
func ground_height_under(at: Vector3) -> float:
	var world: World3D = get_world_3d()
	if world == null:
		return NAN
	var top: Vector3 = Vector3(at.x, maxf(at.y, _focus.y) + 3.0, at.z)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 80.0, ActorBase.LAYER_WORLD)
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	return NAN if hit.is_empty() else (hit["position"] as Vector3).y


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
