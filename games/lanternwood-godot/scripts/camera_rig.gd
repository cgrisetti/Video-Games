extends Node3D

# The camera: follows the gnome from behind and above, and turns round it with Q and E (or the
# right stick) and tilts with T and G. Settings can flip either direction and change the speed.

const DISTANCE := 9.0
const LOOK_ABOVE := 1.6 # Aim this far above the gnome, so the sky and treetops show.
const FOLLOW_SHARPNESS := 5.0
const TURN_SPEED := 1.8 # Radians a second, at camera speed 1.
const PITCH_LIMITS := Vector2(-0.95, -0.12) # From looking well down on the gnome to nearly level.
const DEFAULT_PITCH := -0.52

@export var target: Node3D

var yaw := 0.0
var pitch := DEFAULT_PITCH

@onready var camera: Camera3D = $Camera3D


func snap() -> void:
	if target:
		global_position = target.global_position
	_place_camera()


func reset_view(facing_yaw := 0.0) -> void:
	yaw = facing_yaw
	pitch = DEFAULT_PITCH
	snap()


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
	_place_camera()


func _place_camera() -> void:
	var look_at_point := global_position + Vector3(0, LOOK_ABOVE, 0)
	var back := Vector3(0, 0, DISTANCE).rotated(Vector3.RIGHT, pitch).rotated(Vector3.UP, yaw)
	camera.global_position = look_at_point + back
	camera.look_at(look_at_point)
