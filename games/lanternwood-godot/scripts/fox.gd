@tool
extends CharacterBody3D

# The gnome's fox friend: trots along beside it, swapping sides if it would end up in a hedge,
# and sits and looks up at the gnome when it stands still.

const FOLLOW_SPEED := 8.0
const SIDE_GAP := 1.9 # How far to the side of the gnome it likes to walk.
const TROT_SPEED := 14.0
const GRAVITY := 24.0

const COLORS := {
	"fur": Color("#d9702a"),
	"cream": Color("#f6ead6"),
	"dark": Color("#3a2618"),
	"eyes": Color("#1d1712"),
}

var friend: Node3D # The gnome.
var keep_in := Rect2(-100, -100, 200, 200) # Stay inside this area of x and z.

var _model: Node3D
var _legs: Array[Node3D] = []
var _tail: Node3D
var _head: Node3D
var _side := -1.0
var _trot := 0.0


func _ready() -> void:
	_build_model()
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 0.8
	shape.shape = capsule
	shape.rotation.x = PI / 2.0
	shape.position.y = 0.4
	add_child(shape)


func place(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or friend == null:
		return
	var spot := global_position
	var to_friend := friend.global_position - spot
	if absf(to_friend.x) > 0.8:
		_side = -signf(to_friend.x)
	if friend.global_position.x + _side * SIDE_GAP < keep_in.position.x + 0.5 or friend.global_position.x + _side * SIDE_GAP > keep_in.end.x - 0.5:
		_side = -_side
	var goal := friend.global_position + Vector3(_side * SIDE_GAP, 0, 0.6)
	var offset := Vector3(goal.x - spot.x, 0, goal.z - spot.z)
	var distance := offset.length()
	var speed := 0.0
	var look := Vector3(to_friend.x, 0, to_friend.z)
	if distance > 0.3:
		speed = minf(FOLLOW_SPEED, distance * 2.5) # Trot faster the further behind it is.
		look = offset
	var flat := offset.normalized() * speed
	velocity.x = flat.x
	velocity.z = flat.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	global_position.x = clampf(global_position.x, keep_in.position.x, keep_in.end.x)
	global_position.z = clampf(global_position.z, keep_in.position.y, keep_in.end.y)
	if look.length() > 0.01:
		_model.rotation.y += angle_difference(_model.rotation.y, atan2(look.x, look.z)) * (1.0 - exp(-8.0 * delta))
	_animate(delta, speed / FOLLOW_SPEED)


func _animate(delta: float, pace: float) -> void:
	_trot += delta * TROT_SPEED * maxf(pace, 0.0)
	var stride := sin(_trot) * pace
	for i in _legs.size():
		_legs[i].rotation.x = stride * 0.8 * (1.0 if i % 3 == 0 else -1.0)
	_model.position.y = absf(sin(_trot)) * 0.05 * pace
	_tail.rotation.y = sin(Time.get_ticks_msec() * 0.003) * 0.3 * (1.0 - pace) + sin(_trot) * 0.15
	_tail.rotation.x = lerpf(_tail.rotation.x, -0.25 + pace * 0.35, 1.0 - exp(-5.0 * delta))
	# Standing still, it looks up at its friend.
	_head.rotation.x = lerpf(_head.rotation.x, -0.25 * (1.0 - pace), 1.0 - exp(-4.0 * delta))


func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	var fur := Art.material(COLORS.fur, 0.9, {"rim_enabled": true, "rim": 0.25, "rim_tint": 0.5})
	var cream := Art.material(COLORS.cream, 0.95, {"rim_enabled": true, "rim": 0.25})
	var dark := Art.material(COLORS.dark, 0.8)
	# Body and chest.
	_model.add_child(Art.instance(Art.blob_mesh(0.3, 0.06, 9, Vector3(0.8, 0.75, 1.45)), fur, Vector3(0, 0.5, 0)))
	_model.add_child(Art.sphere(0.17, cream, Vector3(0, 0.47, 0.3), Vector3(1, 1.1, 0.8)))
	# Legs, with dark socks.
	for leg: Vector3 in [Vector3(-0.13, 0.38, 0.28), Vector3(0.13, 0.38, 0.28), Vector3(-0.13, 0.38, -0.28), Vector3(0.13, 0.38, -0.28)]:
		var hip := Node3D.new()
		hip.position = leg
		_model.add_child(hip)
		hip.add_child(Art.cylinder(0.045, 0.05, 0.2, fur, Vector3(0, -0.1, 0), 8))
		hip.add_child(Art.cylinder(0.04, 0.045, 0.18, dark, Vector3(0, -0.28, 0), 8))
		_legs.append(hip)
	# The head: pointed snout, cream cheeks, black nose, big ears.
	_head = Node3D.new()
	_head.position = Vector3(0, 0.72, 0.42)
	_model.add_child(_head)
	_head.add_child(Art.sphere(0.17, fur, Vector3.ZERO, Vector3(1.05, 0.95, 1)))
	var snout := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 0.1
	cone.height = 0.24
	snout.mesh = cone
	snout.material_override = cream
	snout.rotation.x = PI / 2.0
	snout.position = Vector3(0, -0.05, 0.2)
	_head.add_child(snout)
	_head.add_child(Art.sphere(0.03, dark, Vector3(0, -0.04, 0.32)))
	for side: float in [-1.0, 1.0]:
		_head.add_child(Art.sphere(0.022, Art.material(COLORS.eyes, 0.2), Vector3(side * 0.075, 0.04, 0.14)))
		var ear := MeshInstance3D.new()
		var ear_cone := CylinderMesh.new()
		ear_cone.top_radius = 0.0
		ear_cone.bottom_radius = 0.07
		ear_cone.height = 0.17
		ear_cone.radial_segments = 4
		ear.mesh = ear_cone
		ear.material_override = fur
		ear.position = Vector3(side * 0.09, 0.17, -0.02)
		ear.rotation.z = -side * 0.25
		ear.scale = Vector3(1, 1, 0.45)
		_head.add_child(ear)
	# The big bushy tail with its white tip.
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.55, -0.4)
	_model.add_child(_tail)
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in 8:
		var t := i / 7.0
		points.append(Vector3(0, sin(t * 2.2) * 0.25, -t * 0.65))
		radii.append(0.06 + sin(t * PI) * 0.1)
	_tail.add_child(Art.instance(Art.tube_mesh(points, radii, 10), fur))
	_tail.add_child(Art.sphere(0.075, cream, points[6] + Vector3(0, 0, -0.02)))
