extends Node3D

# The camera: follows the gnome from behind and above, and turns round it with Q and E (or the
# right stick) and tilts with T and G. Settings can flip either direction and change the speed.
# It can shake (a bonk), and turn and zoom in on something for a moment (the worm that caught you).

const DISTANCE := 9.0
const LOOK_ABOVE := 1.6 # Aim this far above the gnome, so the sky and treetops show.
const FOLLOW_SHARPNESS := 5.0
const TURN_SPEED := 1.8 # Radians a second, at camera speed 1.
const PITCH_LIMITS := Vector2(-0.95, -0.12) # From looking well down on the gnome to nearly level.
const DEFAULT_PITCH := -0.52
const SHAKE_MOVE := 0.22 # How far the picture moves at the strongest shake, in metres...
const SHAKE_TURN := 0.03 # ...and how much it rolls, in radians.
const SHAKE_FADE := 2.2 # How fast a shake dies away (a full one lasts about half a second).
const FOCUS_ZOOM := 0.55 # Zoomed in on something, the view narrows to this share of its usual width.
const FOCUS_SPEED := 4.0 # How quickly it turns and zooms to it, in real time.

@export var target: Node3D

var yaw := 0.0
var pitch := DEFAULT_PITCH
var focus: Variant = null # A point to turn and zoom in on, or null.

var _trauma := 0.0 # How shaken it is, 0 to 1. The shake grows with the square, so small knocks stay small.
var _focused := 0.0 # How far it's turned and zoomed toward `focus`, 0 to 1.
var _base_fov := 0.0

@onready var camera: Camera3D = $Camera3D


func snap() -> void:
	if target:
		global_position = target.global_position
	_place_camera()


func reset_view(facing_yaw := 0.0) -> void:
	yaw = facing_yaw
	pitch = DEFAULT_PITCH
	focus = null
	_focused = 0.0
	_trauma = 0.0
	snap()


func _ready() -> void:
	_base_fov = camera.fov


# A knock: 0 to 1, adding to any shake already going.
func shake(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if target == null:
		return
	var speed: float = TURN_SPEED * Settings.get_value("camera_speed")
	var turn := Input.get_axis("look_left", "look_right")
	var tilt := Input.get_axis("look_down", "look_up")
	if Settings.get_value("invert_x"):
		turn = -turn
	if Settings.get_value("invert_y"):
		tilt = -tilt
	yaw -= turn * speed * delta
	pitch = clampf(pitch - tilt * speed * 0.6 * delta, PITCH_LIMITS.x, PITCH_LIMITS.y)
	global_position = global_position.lerp(target.global_position, 1.0 - exp(-FOLLOW_SHARPNESS * delta))
	# Zooming in on something happens in real time, even in slow motion.
	var real := delta / maxf(Engine.time_scale, 0.001)
	_focused = move_toward(_focused, 1.0 if focus != null else 0.0, FOCUS_SPEED * real * (1.0 - _focused * 0.7))
	_trauma = maxf(_trauma - SHAKE_FADE * delta, 0.0)
	_place_camera()


func _place_camera() -> void:
	var look_at_point := global_position + Vector3(0, LOOK_ABOVE, 0)
	var back := Vector3(0, 0, DISTANCE).rotated(Vector3.RIGHT, pitch).rotated(Vector3.UP, yaw)
	camera.global_position = look_at_point + back
	if focus != null and _focused > 0.0:
		var eased := smoothstep(0.0, 1.0, _focused)
		look_at_point = look_at_point.lerp(focus, eased)
		camera.fov = lerpf(_base_fov, _base_fov * FOCUS_ZOOM, eased)
	elif _base_fov > 0.0:
		camera.fov = _base_fov
	camera.look_at(look_at_point)
	# The shake: a quick, smooth jiggle sideways, up and down, and a little roll.
	var strength := _trauma * _trauma
	var time := Time.get_ticks_msec() / 1000.0
	camera.h_offset = SHAKE_MOVE * strength * sin(time * 47.0) * cos(time * 13.0)
	camera.v_offset = SHAKE_MOVE * strength * sin(time * 41.0 + 1.3) * cos(time * 17.0)
	camera.rotate_object_local(Vector3.FORWARD, SHAKE_TURN * strength * sin(time * 37.0 + 2.1))
