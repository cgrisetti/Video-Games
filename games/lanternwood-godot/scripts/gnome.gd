@tool
extends CharacterBody3D

# The player: a little gnome in the style of David the Gnome, with a tall red hat that flops over
# at the tip, a big white beard, a blue tunic and a walking stick. Runs, jumps, swings its stick.
# Movement is relative to the camera, so pushing up always walks away from you.

signal landed

# Tweak these to change how the gnome moves.
const MOVE_SPEED := 7.0
const ACCELERATION := 40.0 # How quickly it gets up to speed (and stops).
const JUMP_SPEED := 8.5
const GRAVITY := 24.0
const TURN_SPEED := 12.0 # How quickly it turns to face the way it's running.
const COYOTE_TIME := 0.12 # A jump still works this long after running off an edge.
const RUN_CYCLE_SPEED := 13.0
const LEG_SWING := 0.85
const ARM_SWING := 0.75
const RUN_BOUNCE := 0.07
const SWING_TIME := 0.5 # Seconds for one whole stick swing.
# The stick swing, as key poses: [when 0-1, arm forward(-)/back(+), arm out(-)/across(+), body twist].
const SWING_POSES := [
	[0.0, 0.0, -0.15, 0.0],
	[0.22, -2.3, -0.55, -0.7],
	[0.4, -0.7, -0.1, -0.45],
	[0.6, -0.6, 0.3, 0.8],
	[1.0, 0.0, -0.15, 0.0],
]

const COLORS := {
	"hat": Color("#c8261c"),
	"skin": Color("#f1c6a2"),
	"cheek": Color("#e89a86"),
	"beard": Color("#f5f2ea"),
	"tunic": Color("#2f68b0"),
	"belt": Color("#5b3a1f"),
	"buckle": Color("#e2bd45"),
	"trousers": Color("#d6c196"),
	"boots": Color("#3a2a22"),
	"stick": Color("#7a5230"),
	"eyes": Color("#1d1712"),
}

var camera_yaw := 0.0 # Set by the camera rig: which way "forward" is.
var can_move := true

var _model: Node3D
var _body: Node3D
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _hat_tip: Node3D
var _stride := 0.0
var _swing := -1.0 # How far through a stick swing (0-1), or -1 when not swinging.
var _air_time := 0.0
var _squash := 1.0


func _ready() -> void:
	_build_model()
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.1
	shape.shape = capsule
	shape.position.y = 0.55
	add_child(shape)
	floor_snap_length = 0.3


func place(at: Vector3, facing: float) -> void:
	global_position = at
	_model.rotation.y = facing
	velocity = Vector3.ZERO


func facing() -> float:
	return _model.rotation.y


# Start a stick swing, if one isn't already going. Returns true if it started.
func swing_stick() -> bool:
	if _swing >= 0.0:
		return false
	_swing = 0.0
	return true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var push := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if can_move else Vector2.ZERO
	var move := Vector3(push.x, 0, push.y).rotated(Vector3.UP, camera_yaw)
	var target := move * MOVE_SPEED
	var flat := Vector3(velocity.x, 0, velocity.z).move_toward(target, ACCELERATION * delta)
	velocity.x = flat.x
	velocity.z = flat.z
	if move.length() > 0.05:
		var turn := angle_difference(_model.rotation.y, atan2(move.x, move.z))
		_model.rotation.y += turn * (1.0 - exp(-TURN_SPEED * delta))

	# Jump and fall.
	if is_on_floor():
		_air_time = 0.0
	else:
		_air_time += delta
	if can_move and Input.is_action_just_pressed("jump") and _air_time < COYOTE_TIME:
		velocity.y = JUMP_SPEED
		_air_time = COYOTE_TIME
		_squash = 1.15
	velocity.y -= GRAVITY * delta
	var falling := velocity.y
	var was_in_air := not is_on_floor()
	move_and_slide()
	if was_in_air and is_on_floor() and falling < -4.0:
		_squash = 0.82
		landed.emit()
	_animate(delta, flat.length() / MOVE_SPEED)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _swing >= 0.0:
		_swing += delta / SWING_TIME
		if _swing >= 1.0:
			_swing = -1.0


# Legs and arms swing while running, the gnome bobs with each step, squashes on landing, and its
# hat tip trails behind.
func _animate(delta: float, pace: float) -> void:
	var in_air := not is_on_floor()
	if pace > 0.05 and not in_air:
		_stride += delta * RUN_CYCLE_SPEED * lerpf(0.6, 1.0, pace)
	else:
		_stride = lerpf(_stride, roundf(_stride / PI) * PI, 1.0 - exp(-10.0 * delta))
	var swing := sin(_stride) * pace
	if in_air:
		_legs[0].rotation.x = lerpf(_legs[0].rotation.x, -0.6, 1.0 - exp(-12.0 * delta))
		_legs[1].rotation.x = lerpf(_legs[1].rotation.x, 0.3, 1.0 - exp(-12.0 * delta))
	else:
		_legs[0].rotation.x = swing * LEG_SWING
		_legs[1].rotation.x = -swing * LEG_SWING
	_arms[0].rotation.x = -swing * ARM_SWING + (-1.6 if in_air else 0.0) * 0.5
	_squash = lerpf(_squash, 1.0, 1.0 - exp(-10.0 * delta))
	_body.position.y = absf(sin(_stride)) * RUN_BOUNCE * pace
	_body.scale = Vector3(1.0 / sqrt(_squash), _squash, 1.0 / sqrt(_squash))
	_body.rotation.x = 0.12 * pace # Lean into the run.
	_hat_tip.rotation.x = lerpf(_hat_tip.rotation.x, 0.25 + 0.5 * pace + (0.4 if in_air and velocity.y < 0 else 0.0), 1.0 - exp(-6.0 * delta))
	# The right arm holds the stick: it swings it when asked, or swings along with the run.
	var pose := _swing_pose(_swing) if _swing >= 0.0 else [0.0, swing * ARM_SWING, -0.15, 0.0]
	_arms[1].rotation = Vector3(pose[1], 0.0, pose[2])
	_body.rotation.y = pose[3]


func _swing_pose(t: float) -> Array:
	for i in SWING_POSES.size() - 1:
		var a: Array = SWING_POSES[i]
		var b: Array = SWING_POSES[i + 1]
		if t <= b[0]:
			var k := smoothstep(0.0, 1.0, (t - a[0]) / (b[0] - a[0]))
			return [t, lerpf(a[1], b[1], k), lerpf(a[2], b[2], k), lerpf(a[3], b[3], k)]
	return SWING_POSES[-1]


# --- The model, built from rounded shapes ---

func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	_body = Node3D.new()
	_model.add_child(_body)
	var cloth := func(color: Color) -> StandardMaterial3D: return Art.material(color, 0.9, {"rim_enabled": true, "rim": 0.35, "rim_tint": 0.6})
	var skin := Art.material(COLORS.skin, 0.6, {"rim_enabled": true, "rim": 0.5, "rim_tint": 0.3, "subsurf_scatter_enabled": true, "subsurf_scatter_strength": 0.3})

	# Legs: trousers and boots, swinging from the hips.
	for side: float in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(side * 0.1, 0.4, 0)
		_body.add_child(hip)
		hip.add_child(Art.cylinder(0.075, 0.085, 0.28, cloth.call(COLORS.trousers), Vector3(0, -0.14, 0), 10))
		hip.add_child(Art.sphere(0.1, Art.material(COLORS.boots, 0.55), Vector3(0, -0.33, 0.04), Vector3(0.9, 0.7, 1.3)))
		_legs.append(hip)

	# The tunic, flaring out at the hem, with a belt and buckle.
	var tunic := Art.cylinder(0.19, 0.3, 0.46, cloth.call(COLORS.tunic), Vector3(0, 0.6, 0), 18)
	_body.add_child(tunic)
	var belt := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.235
	torus.outer_radius = 0.275
	belt.mesh = torus
	belt.material_override = Art.material(COLORS.belt, 0.6)
	belt.position.y = 0.5
	belt.scale = Vector3(1, 0.6, 1)
	_body.add_child(belt)
	_body.add_child(Art.box(Vector3(0.09, 0.07, 0.03), Art.material(COLORS.buckle, 0.3, {"metallic": 0.8}), Vector3(0, 0.5, 0.265)))

	# Arms: sleeves and hands, from the shoulders. The right hand holds the stick.
	for side: float in [-1.0, 1.0]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(side * 0.22, 0.76, 0)
		_body.add_child(shoulder)
		var sleeve := Art.cylinder(0.06, 0.075, 0.3, cloth.call(COLORS.tunic), Vector3(side * 0.03, -0.14, 0), 10)
		sleeve.rotation.z = side * 0.18
		shoulder.add_child(sleeve)
		shoulder.add_child(Art.sphere(0.06, skin, Vector3(side * 0.06, -0.32, 0)))
		if side > 0.0:
			var stick := Node3D.new()
			stick.position = Vector3(0.06, -0.32, 0)
			stick.rotation.x = 1.0
			shoulder.add_child(stick)
			stick.add_child(Art.cylinder(0.022, 0.03, 1.0, Art.bark_material(COLORS.stick, 4.0), Vector3(0, 0.25, 0), 7))
			stick.add_child(Art.sphere(0.06, Art.material(Color("#6aa045"), 0.7), Vector3(0.03, 0.72, 0), Vector3(0.5, 1.0, 0.25)))
		_arms.append(shoulder)

	# The head: round face, button nose, rosy cheeks, little eyes, and a big beard.
	var head := Node3D.new()
	head.position.y = 0.96
	_body.add_child(head)
	head.add_child(Art.sphere(0.165, skin, Vector3.ZERO))
	head.add_child(Art.sphere(0.055, Art.material(COLORS.cheek, 0.55), Vector3(0, -0.01, 0.16)))
	for side: float in [-1.0, 1.0]:
		head.add_child(Art.sphere(0.022, Art.material(COLORS.eyes, 0.2, {"metallic_specular": 1.0}), Vector3(side * 0.065, 0.04, 0.145)))
		head.add_child(Art.sphere(0.035, Art.material(COLORS.cheek, 0.7), Vector3(side * 0.1, -0.03, 0.12), Vector3(1, 0.7, 0.5)))
		var brow := Art.sphere(0.035, Art.material(COLORS.beard, 0.9), Vector3(side * 0.07, 0.085, 0.14), Vector3(1.4, 0.5, 0.6))
		head.add_child(brow)
	var beard := Art.instance(Art.blob_mesh(0.2, 0.12, 4, Vector3(0.95, 1.15, 0.6)), Art.material(COLORS.beard, 0.95, {"rim_enabled": true, "rim": 0.6}), Vector3(0, -0.17, 0.08))
	head.add_child(beard)
	head.add_child(Art.sphere(0.09, Art.material(COLORS.beard, 0.95), Vector3(0, -0.04, 0.12), Vector3(1.6, 0.6, 0.8))) # Moustache.

	# The hat: a tall cone that flops over at the tip. The tip is its own piece, so it can trail.
	var hat := Art.material(COLORS.hat, 0.85, {"rim_enabled": true, "rim": 0.4, "rim_tint": 0.5})
	var cone := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in 6:
		var t := i / 5.0
		cone.append(Vector3(0, t * 0.38, -t * t * 0.04))
		radii.append(lerpf(0.185, 0.08, t))
	head.add_child(Art.instance(Art.tube_mesh(cone, radii, 16), hat, Vector3(0, 0.06, 0)))
	_hat_tip = Node3D.new()
	_hat_tip.position = Vector3(0, 0.44, -0.04)
	head.add_child(_hat_tip)
	var tip_points := PackedVector3Array()
	var tip_radii := PackedFloat32Array()
	for i in 6:
		var t := i / 5.0
		tip_points.append(Vector3(0, t * 0.22, -t * t * 0.16))
		tip_radii.append(lerpf(0.08, 0.008, t))
	_hat_tip.add_child(Art.instance(Art.tube_mesh(tip_points, tip_radii, 12), hat))
