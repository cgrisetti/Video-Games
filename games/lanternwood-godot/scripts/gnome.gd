@tool
extends CharacterBody3D

# The player: a little gnome in the style of David the Gnome. A tall red felt hat that flops over at
# the tip, a big round nose, bushy brows, and a white beard that wraps round to his ears; a blue
# knitted tunic, rolled trousers, leather boots, and his walking stick in his right hand.
#
# He's built from rounded pieces hung on a skeleton of pivots (hips, spine, chest, neck, head;
# shoulder, elbow and hand; hip, knee and boot), and every move is worked out in code, so there are
# no animation files. He breathes and blinks and glances about, runs with bending knees and pumping
# arms, crouches, stretches and tucks when he jumps, swings his stick with a happy hop and a trail
# of sparkles, waves to the fox (R or △), and if you leave him be, he leans on his stick or strokes
# his beard. His hat tip and beard swing and settle behind his moves.
# Movement is relative to the camera, so pushing up always walks away from you.

signal landed
signal waved # The fox listens for this.

# Tweak these to change how the gnome moves.
const MOVE_SPEED := 7.0
const ACCELERATION := 40.0 # How quickly he gets up to speed (and stops).
const JUMP_SPEED := 8.5
const GRAVITY := 24.0
const TURN_SPEED := 12.0 # How quickly he turns to face the way he's running.
const COYOTE_TIME := 0.12 # A jump still works this long after running off an edge.
# ...and how he looks doing it.
const RUN_CYCLE_SPEED := 13.0
const LEG_SWING := 0.8
const KNEE_BEND := 1.25
const ARM_SWING := 0.75
const RUN_BOUNCE := 0.06
const RUN_LEAN := 0.16
const TURN_BANK := 0.045 # How far he leans into a turn.
const SWING_TIME := 0.55 # Seconds for one whole stick swing.
const WAVE_TIME := 1.8
const FIDGET_AFTER := 5.0 # Seconds standing still before he leans on his stick or strokes his beard.
const FIDGET_TIME := 3.6
# The stick swing, as key poses: [when 0-1, stick arm forward(-)/back(+), stick arm out(-)/across(+),
# elbow bend, body twist, hop height, free arm flung out].
const SWING_POSES := [
	[0.0, -0.2, 0.0, 0.5, 0.0, 0.0, 0.0],
	[0.25, -2.7, -0.55, 0.9, -0.75, 0.03, 0.35], # Wind up: stick high over his shoulder.
	[0.42, -1.0, -0.2, 0.15, -0.3, 0.17, 1.25], # Whoosh: a hop, the other arm flung out.
	[0.62, -0.5, 0.45, 0.1, 0.85, 0.08, 1.0], # Follow through, across his body.
	[1.0, -0.2, 0.0, 0.5, 0.0, 0.0, 0.0],
]
const STRIKE := Vector2(0.28, 0.72) # The part of the swing when sparkles fly off the stick.

const COLORS := {
	"hat": Color("#c8261c"),
	"skin": Color("#f1c6a2"),
	"nose": Color("#eda88c"),
	"cheek": Color("#e8907e"),
	"beard": Color("#f5f2ea"),
	"beard_shade": Color("#c9c0b0"),
	"tunic": Color("#2f68b0"),
	"trim": Color("#244f88"),
	"belt": Color("#5b3a1f"),
	"buckle": Color("#e2bd45"),
	"trousers": Color("#d6c196"),
	"boots": Color("#3a2a22"),
	"stick": Color("#7a5230"),
	"eyes": Color("#1d1712"),
	"dust": Color("#d8c39a"),
}
const SPARKLE_COLORS := [Color("#ffe27a"), Color("#ffffff"), Color("#ffb3d9")]
const LEFT := 0 # Index into the arm and leg arrays. His left is +x, as he faces +z.
const RIGHT := 1

var camera_yaw := 0.0 # Set by the camera rig: which way "forward" is.
var can_move := true

var _model: Node3D # Turns to face the way he's going.
var _rig: Node3D # Bobs, hops and squashes.
var _hips: Node3D
var _spine: Node3D
var _chest: Node3D
var _neck: Node3D
var _head: Node3D
var _thighs: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _feet: Array[Node3D] = []
var _shoulders: Array[Node3D] = []
var _elbows: Array[Node3D] = []
var _stick: Node3D
var _stick_tip: Node3D
var _hat: Node3D
var _hat_tips: Array[Node3D] = []
var _beard: Node3D
var _eyes: Array[Node3D] = []
var _brows: Array[Node3D] = []

var _time := 0.0
var _stride := 0.0
var _swing := -1.0 # How far through a stick swing (0-1), or -1 when not swinging.
var _wave := -1.0
var _air_time := 0.0
var _squash := 1.0
var _land_dip := 0.0
var _turn_rate := 0.0
var _pace := 0.0 # 0 standing to 1 full speed, smoothed.
var _air := 0.0 # 0 on the ground to 1 in the air, smoothed.
var _still := 0.0 # Seconds standing still.
var _fidget := -1.0 # How far through a fidget, or -1.
var _fidget_kind := 0
var _next_blink := 2.0
var _blink := -1.0
var _glance := Vector2.ZERO # Where he's looking: turn and tilt of the head.
var _glance_goal := Vector2.ZERO
var _next_glance := 2.0
var _last_head := Vector3.ZERO
var _head_velocity := Vector3.ZERO
var _sway := Vector3.ZERO # How his soft bits are being flung, in his own space.
var _hat_bend: Array[Vector2] = []
var _hat_bend_speed: Array[Vector2] = []
var _beard_bend := 0.0
var _beard_speed := 0.0
var _last_step := 0
var _puffs: Array = [] # Dust and sparkles: [node, age, life, velocity, grow].
var _next_puff := 0
var _rng := RandomNumberGenerator.new()


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
	_build_puffs()


func place(at: Vector3, facing: float) -> void:
	global_position = at
	_model.rotation.y = facing
	velocity = Vector3.ZERO
	_last_head = Vector3.ZERO


func facing() -> float:
	return _model.rotation.y


# Start a stick swing, if one isn't already going. Returns true if it started.
func swing_stick() -> bool:
	if _swing >= 0.0:
		return false
	_swing = 0.0
	_wave = -1.0
	_rest()
	return true


# Tip his hat and wave. Returns true if he started.
func wave() -> bool:
	if _wave >= 0.0 or _swing >= 0.0:
		return false
	_wave = 0.0
	_rest()
	waved.emit()
	return true


func is_waving() -> bool:
	return _wave >= 0.0


func is_swinging() -> bool:
	return _swing >= 0.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var push := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if can_move else Vector2.ZERO
	var move := Vector3(push.x, 0, push.y).rotated(Vector3.UP, camera_yaw)
	var target := move * MOVE_SPEED
	var flat := Vector3(velocity.x, 0, velocity.z).move_toward(target, ACCELERATION * delta)
	velocity.x = flat.x
	velocity.z = flat.z
	var turned := 0.0
	if move.length() > 0.05:
		turned = angle_difference(_model.rotation.y, atan2(move.x, move.z)) * (1.0 - exp(-TURN_SPEED * delta))
		_model.rotation.y += turned
	_turn_rate = lerpf(_turn_rate, turned / delta, 1.0 - exp(-8.0 * delta))

	# Jump and fall.
	if is_on_floor():
		_air_time = 0.0
	else:
		_air_time += delta
	if can_move and Input.is_action_just_pressed("jump") and _air_time < COYOTE_TIME:
		velocity.y = JUMP_SPEED
		_air_time = COYOTE_TIME
		_squash = 1.18
		_rest()
		_puff_dust(global_position, 3, 0.6)
	if can_move and Input.is_action_just_pressed("wave"):
		wave()
	velocity.y -= GRAVITY * delta
	var falling := velocity.y
	var was_in_air := not is_on_floor()
	move_and_slide()
	if was_in_air and is_on_floor() and falling < -4.0:
		_squash = 0.8
		_land_dip = clampf(-falling / 12.0, 0.4, 1.0)
		_puff_dust(global_position, 7, 1.0)
		landed.emit()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if _swing >= 0.0:
		_swing += delta / SWING_TIME
		if _swing >= 1.0:
			_swing = -1.0
	if _wave >= 0.0:
		_wave += delta / WAVE_TIME
		if _wave >= 1.0:
			_wave = -1.0
	_animate(delta)
	_update_puffs(delta)


# Stop fidgeting and look straight ahead again.
func _rest() -> void:
	_still = 0.0
	_fidget = -1.0


# --- Animation ---

func _animate(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length() / MOVE_SPEED
	var in_air := not is_on_floor() and _air_time > 0.05
	_pace = _damp(_pace, speed if not in_air else _pace, 10.0, delta)
	_air = _damp(_air, 1.0 if in_air else 0.0, 14.0, delta)
	var run := _pace * (1.0 - _air)
	var idle := (1.0 - _pace) * (1.0 - _air)
	if run > 0.05:
		_stride += delta * RUN_CYCLE_SPEED * lerpf(0.65, 1.0, _pace)
	else:
		_stride = _damp(_stride, roundf(_stride / PI) * PI, 8.0, delta)
	var stride := sin(_stride)
	_step_dust(run)
	_update_idle(delta, idle)

	# Legs: swing from the hips, knees bend as each leg comes forward, feet stay level.
	var rising := clampf(velocity.y / JUMP_SPEED, -1.0, 1.0)
	for side in 2:
		var phase := stride * (1.0 if side == RIGHT else -1.0)
		var forward := cos(_stride) * (1.0 if side == RIGHT else -1.0)
		var thigh := -phase * LEG_SWING * run
		var knee := (0.15 + KNEE_BEND * maxf(0.0, forward)) * run + 0.06 * idle
		# In the air: one knee up as he rises, both reaching down as he falls.
		var air_thigh := lerpf(-0.3, -1.25 if side == LEFT else -0.55, maxf(rising, 0.0))
		var air_knee := lerpf(0.3, 1.7 if side == LEFT else 0.9, maxf(rising, 0.0))
		thigh = lerpf(thigh, air_thigh, _air) - 0.5 * _land_dip
		knee = lerpf(knee, air_knee, _air) + 1.0 * _land_dip
		_thighs[side].rotation.x = thigh
		_knees[side].rotation.x = knee
		_feet[side].rotation.x = -(thigh + knee) * 0.75

	# Body: bob with each step, lean into the run and into turns, squash and stretch.
	_squash = _damp(_squash, 1.0, 9.0, delta)
	_land_dip = _damp(_land_dip, 0.0, 7.0, delta)
	var hop := 0.0
	var twist := sin(_stride) * 0.14 * run
	var swing_pose := _swing_pose(_swing) if _swing >= 0.0 else []
	if not swing_pose.is_empty():
		twist += swing_pose[4]
		hop = swing_pose[5]
	_rig.position.y = absf(cos(_stride)) * RUN_BOUNCE * run - 0.09 * _land_dip + hop + 0.012 * sin(_time * 2.2) * idle
	_rig.scale = Vector3(1.0 / sqrt(_squash), _squash, 1.0 / sqrt(_squash))
	_spine.rotation.x = RUN_LEAN * run + 0.1 * _air * maxf(rising, 0.0) - 0.12 * _air * maxf(-rising, 0.0) + 0.18 * _land_dip
	_spine.rotation.z = clampf(-_turn_rate * TURN_BANK * _pace, -0.3, 0.3)
	_spine.rotation.y = twist
	_chest.scale = Vector3.ONE * (1.0 + 0.018 * sin(_time * 2.2) * idle) # Breathing.

	# Head: steady against the bob and lean, glancing about when he's still.
	_neck.rotation.x = -_spine.rotation.x * 0.6 - 0.05 * sin(_stride * 2.0) * run - 0.18 * _air * maxf(rising, 0.0) + _glance.y
	_neck.rotation.y = -twist * 0.7 + _glance.x
	_neck.rotation.z = -_spine.rotation.z * 0.5 + sin(_stride) * 0.05 * run

	_animate_arms(delta, stride, run, idle, swing_pose)
	_animate_face(delta)
	_animate_soft_bits(delta, run)


func _animate_arms(delta: float, stride: float, run: float, idle: float, swing_pose: Array) -> void:
	# [forward(-)/back(+), out, elbow] for each arm, built up from the layers below.
	var arms := []
	for side in 2:
		var out := 1.0 if side == LEFT else -1.0 # Rotating z this way swings that arm outward.
		var swing := stride * ARM_SWING * (1.0 if side == RIGHT else -1.0) # Opposite to that side's leg.
		var pose := Vector3(swing * run + 0.05 * idle, out * (0.12 + 0.05 * run), 0.25 * idle + (0.5 + 0.35 * _pace) * run)
		# In the air: arms up and out for balance.
		pose = pose.lerp(Vector3(-0.9, out * 1.25, 0.45), _air)
		arms.append(pose)
	# Standing, the stick hand plants the stick a little in front.
	arms[RIGHT] = arms[RIGHT].lerp(Vector3(-0.3, -0.12, 0.55), idle)
	var stick_tilt := lerpf(0.12, 0.5, run) # How far the stick leans forward from upright.

	# Fidgets: leaning on the stick, or stroking his beard.
	if _fidget >= 0.0:
		var k := sin(clampf(_fidget, 0.0, 1.0) * PI)
		k = minf(k * 2.0, 1.0) * idle
		if _fidget_kind == 0:
			arms[RIGHT] = arms[RIGHT].lerp(Vector3(-0.55, -0.05, 0.25), k)
			arms[LEFT] = arms[LEFT].lerp(Vector3(-0.2, 0.55, 1.9), k) # Hand on hip.
			_spine.rotation.x += 0.1 * k
			_spine.rotation.z += 0.08 * k
			stick_tilt = lerpf(stick_tilt, 0.35, k)
		else:
			var stroke := sin(_time * 5.0) * 0.25
			arms[LEFT] = arms[LEFT].lerp(Vector3(-1.05, -0.35, 2.05 + stroke), k)
			_neck.rotation.x += (-0.12 + stroke * 0.3) * k
			_neck.rotation.z += 0.12 * k

	# The wave: hand to hat brim, tip the hat, then a big wave overhead.
	var hat_lift := 0.0
	if _wave >= 0.0:
		var w := _wave
		var tip_hat := smoothstep(0.0, 0.14, w) * (1.0 - smoothstep(0.3, 0.42, w))
		var overhead := smoothstep(0.32, 0.45, w) * (1.0 - smoothstep(0.86, 1.0, w))
		var flap := sin((w - 0.45) / 0.41 * TAU * 3.0) if w > 0.45 and w < 0.86 else 0.0
		arms[LEFT] = arms[LEFT].lerp(Vector3(-2.35, 0.25, 1.75), tip_hat)
		arms[LEFT] = arms[LEFT].lerp(Vector3(-2.85, 0.35 + 0.3 * flap, 0.35 + 0.25 * flap), overhead)
		hat_lift = smoothstep(0.08, 0.18, w) * (1.0 - smoothstep(0.24, 0.34, w))
		_neck.rotation.x += 0.18 * tip_hat - 0.1 * overhead
		_neck.rotation.z += 0.1 * overhead
		_rig.position.y += 0.05 * sin(clampf(w / 0.12, 0.0, 1.0) * PI)
	_hat.position.y = lerpf(_hat.position.y, 0.09 + 0.09 * hat_lift, 1.0 - exp(-25.0 * delta))
	_hat.rotation.x = lerpf(_hat.rotation.x, -0.2 + 0.45 * hat_lift, 1.0 - exp(-25.0 * delta))

	# The stick swing takes over the stick arm, and flings the other one out.
	if not swing_pose.is_empty():
		arms[RIGHT] = Vector3(swing_pose[1], swing_pose[2], swing_pose[3])
		arms[LEFT] = arms[LEFT].lerp(Vector3(-0.6, 1.25, 0.3), swing_pose[6] / 1.25)
		if _swing > STRIKE.x and _swing < STRIKE.y:
			_sparkle(_stick_tip.global_position)

	for side in 2:
		_shoulders[side].rotation = Vector3(arms[side].x, 0.0, arms[side].y)
		_elbows[side].rotation.x = -arms[side].z
	# The stick stays near upright whatever his arm is doing, except in a swing, when it carries on
	# from his arm like a club.
	var hold: float = -(arms[RIGHT].x - arms[RIGHT].z) + stick_tilt
	_stick.rotation.x = lerpf(_stick.rotation.x, PI - 0.9 if not swing_pose.is_empty() else hold, 1.0 - exp(-20.0 * delta))


# Blinking, glancing about, and the brows going up when something's exciting.
func _animate_face(delta: float) -> void:
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.0
		_next_blink = _rng.randf_range(1.8, 4.5)
	var shut := 0.0
	if _blink >= 0.0:
		_blink += delta / 0.16
		shut = sin(clampf(_blink, 0.0, 1.0) * PI)
		if _blink >= 1.0:
			_blink = -1.0
	for eye in _eyes:
		eye.scale.y = lerpf(1.0, 0.12, shut)
	var raised := maxf(_air, 1.0 if _wave >= 0.0 or _swing >= 0.0 else 0.0)
	for side in 2:
		_brows[side].position.y = _damp(_brows[side].position.y, 0.1 + 0.03 * raised, 12.0, delta)


func _update_idle(delta: float, idle: float) -> void:
	if idle > 0.9 and _swing < 0.0 and _wave < 0.0:
		_still += delta
	else:
		_rest()
	_next_glance -= delta
	if _next_glance <= 0.0:
		_next_glance = _rng.randf_range(1.6, 4.0)
		_glance_goal = Vector2(_rng.randf_range(-0.65, 0.65), _rng.randf_range(-0.2, 0.12)) if _still > 1.0 else Vector2.ZERO
	if _still < 1.0:
		_glance_goal = Vector2.ZERO
	_glance = _glance.lerp(_glance_goal, 1.0 - exp(-5.0 * delta))
	if _fidget < 0.0 and _still > FIDGET_AFTER:
		_fidget = 0.0
		_fidget_kind = (_fidget_kind + 1) % 2
	if _fidget >= 0.0:
		_fidget += delta / FIDGET_TIME
		if _fidget >= 1.0:
			_fidget = -1.0
			_still = 1.0 # A while before the next one.


# The hat tip and beard are springy: they lag behind his moves, swing and settle.
func _animate_soft_bits(delta: float, run: float) -> void:
	var head := _head.global_position
	if _last_head == Vector3.ZERO:
		_last_head = head
	var moved := (head - _last_head) / maxf(delta, 0.001)
	var pushed := (moved - _head_velocity) / maxf(delta, 0.001)
	_head_velocity = moved
	_last_head = head
	var local := _model.global_basis.inverse() * pushed
	_sway = _sway.lerp(local.limit_length(60.0), 1.0 - exp(-12.0 * delta))
	for i in _hat_tips.size():
		var looseness := 1.0 + i * 0.6
		var goal := Vector2(-_sway.z * 0.006 - _sway.y * 0.004 - 0.3 * run, _sway.x * 0.006) * looseness
		var spring := (goal - _hat_bend[i]) * 120.0 - _hat_bend_speed[i] * 9.0
		_hat_bend_speed[i] += spring * delta
		_hat_bend[i] += _hat_bend_speed[i] * delta
		_hat_bend[i] = _hat_bend[i].clamp(Vector2(-0.9, -0.6), Vector2(0.5, 0.6))
		var rest: Vector2 = [Vector2(-0.35, 0.3), Vector2(-0.55, 0.45), Vector2(-0.65, 0.55)][i] # Flopped back and to one side.
		_hat_tips[i].rotation = Vector3(rest.x + _hat_bend[i].x, 0.0, rest.y + _hat_bend[i].y)
	var beard_goal := clampf(-_sway.z * 0.003 + _sway.y * 0.002, -0.35, 0.35)
	_beard_speed += ((beard_goal - _beard_bend) * 160.0 - _beard_speed * 12.0) * delta
	_beard_bend += _beard_speed * delta
	_beard.rotation.x = _beard_bend


func _swing_pose(t: float) -> Array:
	for i in SWING_POSES.size() - 1:
		var a: Array = SWING_POSES[i]
		var b: Array = SWING_POSES[i + 1]
		if t <= b[0]:
			var k := smoothstep(0.0, 1.0, (t - a[0]) / (b[0] - a[0]))
			var pose := []
			for j in a.size():
				pose.append(lerpf(a[j], b[j], k))
			return pose
	return SWING_POSES[-1]


static func _damp(from: float, to: float, sharpness: float, delta: float) -> float:
	return lerpf(from, to, 1.0 - exp(-sharpness * delta))


# --- Dust and sparkles ---
# A small pool of puffs that live in the world (not on the gnome), so they stay where they were made.

func _build_puffs() -> void:
	var dust := StandardMaterial3D.new()
	dust.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust.albedo_texture = Atmosphere._soft_dot()
	dust.albedo_color = COLORS.dust
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var gem := SphereMesh.new() # Four sides and two rings make a little diamond.
	gem.radius = 0.035
	gem.height = 0.07
	gem.radial_segments = 4
	gem.rings = 2
	for i in 40:
		var made := MeshInstance3D.new()
		made.top_level = true
		made.visible = false
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if i < 16:
			made.mesh = quad
			made.material_override = dust
		else:
			made.mesh = gem
			made.material_override = Art.glow_material(SPARKLE_COLORS[i % 3], 3.0)
		add_child(made)
		_puffs.append([made, 0.0, 0.0, Vector3.ZERO, 0.0])


func _spawn(first: int, last: int, at: Vector3, life: float, drift: Vector3, size: float) -> MeshInstance3D:
	for tries in last - first:
		var i := first + (_next_puff + tries) % (last - first)
		var puff: Array = _puffs[i]
		if puff[1] >= puff[2]:
			_next_puff = (_next_puff + tries + 1) % (last - first)
			var node: MeshInstance3D = puff[0]
			node.global_position = at
			node.scale = Vector3.ONE * size
			node.visible = true
			puff[1] = 0.0
			puff[2] = life
			puff[3] = drift
			puff[4] = size
			return node
	return null


func _puff_dust(at: Vector3, count: int, strength: float) -> void:
	for i in count:
		var angle := TAU * i / count + _rng.randf() * 0.6
		var out := Vector3(cos(angle), 0.0, sin(angle))
		_spawn(0, 16, at + out * 0.15 + Vector3(0, 0.08, 0), _rng.randf_range(0.45, 0.7), out * 0.9 * strength + Vector3(0, 0.35, 0), 0.18 * strength)


# A little puff at each footfall while running.
func _step_dust(run: float) -> void:
	var step := int(floor((_stride + PI / 2.0) / PI)) # Each time a foot comes down.
	if step != _last_step and run > 0.5 and is_on_floor():
		var side := 1.0 if step % 2 == 0 else -1.0
		var foot := global_position + _model.global_basis.x * side * 0.1
		_spawn(0, 16, foot + Vector3(0, 0.06, 0), 0.45, -velocity * 0.05 + Vector3(0, 0.25, 0), 0.12)
	_last_step = step


func _sparkle(at: Vector3) -> void:
	for i in 2:
		var spark := _spawn(16, 40, at + Vector3(_rng.randfn(), _rng.randfn(), _rng.randfn()) * 0.05, _rng.randf_range(0.35, 0.6), Vector3(_rng.randfn(), _rng.randf_range(0.5, 1.5), _rng.randfn()) * 0.6, 1.0)
		if spark:
			spark.rotation = Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * TAU


func _update_puffs(delta: float) -> void:
	for puff: Array in _puffs:
		var node: MeshInstance3D = puff[0]
		if not node.visible:
			continue
		puff[1] += delta
		var t: float = puff[1] / puff[2]
		if t >= 1.0:
			node.visible = false
			continue
		var drift: Vector3 = puff[3]
		node.global_position += drift * delta
		puff[3] = drift * exp(-3.0 * delta)
		if node.mesh is QuadMesh:
			node.scale = Vector3.ONE * puff[4] * (1.0 + 2.2 * t)
			node.transparency = lerpf(0.45, 1.0, t)
		else:
			node.scale = Vector3.ONE * (1.0 - t)
			node.rotation.y += delta * 8.0


# --- The model, built from rounded pieces on a skeleton of pivots ---

func _build_model() -> void:
	var cloth := func(color: Color, weave := Art.FELT, scale := 1.0, fuzz := 0.4, extra := {}) -> ShaderMaterial:
		return Art.cloth_material(color, weave, scale, fuzz, extra)
	var skin := Art.material(COLORS.skin, 0.6, {"rim_enabled": true, "rim": 0.45, "rim_tint": 0.4, "subsurf_scatter_enabled": true, "subsurf_scatter_strength": 0.35})
	var nose_skin := Art.material(COLORS.nose, 0.5, {"rim_enabled": true, "rim": 0.4, "rim_tint": 0.4, "subsurf_scatter_enabled": true, "subsurf_scatter_strength": 0.4})
	var hair: ShaderMaterial = cloth.call(COLORS.beard, Art.HAIR, 1.0, 0.6, {"shade_color": COLORS.beard_shade, "translucency": 0.25})
	var hat: ShaderMaterial = cloth.call(COLORS.hat, Art.FELT, 1.0, 0.3)
	var tunic: ShaderMaterial = cloth.call(COLORS.tunic, Art.KNIT, 1.0, 0.35)
	var trim: ShaderMaterial = cloth.call(COLORS.trim, Art.KNIT, 1.4, 0.3)
	var trousers: ShaderMaterial = cloth.call(COLORS.trousers, Art.FELT, 1.6, 0.3)
	var leather: ShaderMaterial = cloth.call(COLORS.boots, Art.LEATHER, 1.0, 0.2, {"softness": 0.65})
	var belt_leather: ShaderMaterial = cloth.call(COLORS.belt, Art.LEATHER, 1.6, 0.2, {"softness": 0.6})

	_model = _pivot(self, Vector3.ZERO, "Model")
	_rig = _pivot(_model, Vector3.ZERO)
	_hips = _pivot(_rig, Vector3(0, 0.43, 0))

	# Legs: trousers with rolled cuffs, and round-toed boots.
	for side in 2:
		var x := 0.095 if side == LEFT else -0.095
		var thigh := _pivot(_hips, Vector3(x, 0, 0))
		thigh.add_child(Art.cylinder(0.07, 0.08, 0.17, trousers, Vector3(0, -0.085, 0), 12))
		var knee := _pivot(thigh, Vector3(0, -0.17, 0))
		knee.add_child(Art.sphere(0.07, trousers, Vector3.ZERO))
		knee.add_child(Art.cylinder(0.063, 0.07, 0.09, trousers, Vector3(0, -0.045, 0), 12))
		knee.add_child(Art.cylinder(0.076, 0.074, 0.04, trousers, Vector3(0, -0.095, 0), 12)) # The rolled cuff.
		var foot := _pivot(knee, Vector3(0, -0.13, 0))
		foot.add_child(Art.cylinder(0.068, 0.064, 0.07, leather, Vector3(0, -0.02, 0), 12))
		foot.add_child(Art.sphere(0.085, leather, Vector3(0, -0.075, 0.035), Vector3(0.92, 0.72, 1.4)))
		foot.add_child(Art.sphere(0.05, leather, Vector3(0, -0.07, 0.125), Vector3(0.95, 0.85, 0.9))) # A round toe.
		_thighs.append(thigh)
		_knees.append(knee)
		_feet.append(foot)

	# The tunic: knitted, flaring at the hem, with a darker band, a belt and a brass buckle.
	_spine = _pivot(_hips, Vector3.ZERO)
	var profile := PackedVector3Array()
	var radii := PackedFloat32Array()
	for row: Vector2 in [Vector2(-0.15, 0.27), Vector2(-0.08, 0.262), Vector2(0.02, 0.238), Vector2(0.1, 0.226), Vector2(0.2, 0.222), Vector2(0.3, 0.21), Vector2(0.38, 0.17), Vector2(0.44, 0.09)]:
		profile.append(Vector3(0, row.x, 0))
		radii.append(row.y)
	var body := Art.instance(Art.tube_mesh(profile, radii, 20), tunic)
	body.scale = Vector3(1, 1, 0.92)
	_spine.add_child(body)
	_spine.add_child(_ring(0.255, 0.285, trim, Vector3(0, -0.13, 0), Vector3(1, 0.55, 0.92)))
	_spine.add_child(_ring(0.215, 0.248, belt_leather, Vector3(0, 0.06, 0), Vector3(1, 0.75, 0.92)))
	_spine.add_child(Art.box(Vector3(0.085, 0.07, 0.025), Art.material(COLORS.buckle, 0.3, {"metallic": 0.85}), Vector3(0, 0.06, 0.222)))
	_spine.add_child(Art.box(Vector3(0.045, 0.034, 0.03), Art.material(COLORS.belt, 0.6), Vector3(0, 0.06, 0.224)))
	_chest = _pivot(_spine, Vector3(0, 0.26, 0))

	# Arms: knitted sleeves with cuffs, bending at the elbow, and his hands. The stick is in his right.
	for side in 2:
		var x := 0.2 if side == LEFT else -0.2
		var shoulder := _pivot(_chest, Vector3(x, 0.1, 0))
		shoulder.add_child(Art.sphere(0.072, tunic, Vector3.ZERO))
		shoulder.add_child(Art.cylinder(0.058, 0.066, 0.15, tunic, Vector3(0, -0.075, 0), 12))
		var elbow := _pivot(shoulder, Vector3(0, -0.15, 0))
		elbow.add_child(Art.sphere(0.058, tunic, Vector3.ZERO))
		elbow.add_child(Art.cylinder(0.053, 0.058, 0.09, tunic, Vector3(0, -0.045, 0), 12))
		elbow.add_child(Art.cylinder(0.066, 0.064, 0.04, trim, Vector3(0, -0.1, 0), 12))
		var hand := _pivot(elbow, Vector3(0, -0.15, 0))
		hand.add_child(Art.sphere(0.052, skin, Vector3(0, -0.01, 0.0), Vector3(0.9, 1.05, 0.85)))
		hand.add_child(Art.sphere(0.022, skin, Vector3(-x * 0.16, 0.0, 0.035)))
		if side == RIGHT:
			_stick = _pivot(hand, Vector3(0, -0.01, 0))
			var bark := Art.bark_material(COLORS.stick, 4.0)
			_stick.add_child(Art.cylinder(0.022, 0.03, 1.2, bark, Vector3(0, 0.12, 0), 8))
			_stick.add_child(Art.instance(Art.blob_mesh(0.042, 0.2, 5), bark, Vector3(0, 0.75, 0)))
			_stick.add_child(Art.sphere(0.045, Art.material(Color("#6aa045"), 0.7), Vector3(0.04, 0.68, 0), Vector3(0.45, 1.0, 0.22)))
			_stick.add_child(Art.sphere(0.035, Art.material(Color("#83b552"), 0.7), Vector3(-0.03, 0.64, 0.01), Vector3(0.45, 1.0, 0.22)))
			_stick_tip = _pivot(_stick, Vector3(0, 0.74, 0))
		_shoulders.append(shoulder)
		_elbows.append(elbow)

	# The head: round face, a big Nisse nose, rosy cheeks, bright little eyes, bushy brows, and ears.
	_neck = _pivot(_chest, Vector3(0, 0.17, 0))
	_head = _pivot(_neck, Vector3(0, 0.16, 0))
	_head.add_child(Art.sphere(0.18, skin, Vector3.ZERO, Vector3(1, 0.97, 1)))
	_head.add_child(Art.sphere(0.07, nose_skin, Vector3(0, -0.012, 0.185)))
	for side in 2:
		var s := 1.0 if side == LEFT else -1.0
		_head.add_child(Art.sphere(0.048, Art.material(COLORS.cheek, 0.6), Vector3(s * 0.1, -0.035, 0.132), Vector3(1, 0.8, 0.6)))
		var eye := _pivot(_head, Vector3(s * 0.068, 0.047, 0.157))
		eye.add_child(Art.sphere(0.023, Art.material(COLORS.eyes, 0.15, {"metallic_specular": 1.0}), Vector3.ZERO, Vector3(1, 1.2, 0.6)))
		eye.add_child(Art.sphere(0.0075, Art.glow_material(Color.WHITE, 0.6), Vector3(-s * 0.006, 0.01, 0.013)))
		_eyes.append(eye)
		var brow := _pivot(_head, Vector3(s * 0.075, 0.1, 0.148))
		var tuft := Art.instance(Art.blob_mesh(0.04, 0.25, 30 + side), hair, Vector3.ZERO)
		tuft.scale = Vector3(1.6, 0.6, 0.8)
		tuft.rotation.z = s * -0.28
		brow.add_child(tuft)
		_brows.append(brow)
		_head.add_child(Art.sphere(0.05, skin, Vector3(s * 0.172, 0.0, -0.005), Vector3(0.45, 0.85, 0.65)))

	# White hair: a puff at the back and tufts over the ears, so he's still himself from behind.
	_head.add_child(Art.instance(Art.blob_mesh(0.15, 0.18, 12, Vector3(1.22, 0.58, 0.78)), hair, Vector3(0, -0.03, -0.1)))
	for side in 2:
		var s := 1.0 if side == LEFT else -1.0
		_head.add_child(Art.instance(Art.blob_mesh(0.075, 0.2, 13 + side), hair, Vector3(s * 0.15, 0.02, -0.06)))
		# The beard wraps round from the chin to the ears.
		_head.add_child(Art.instance(Art.blob_mesh(0.1, 0.15, 15 + side, Vector3(0.75, 1.05, 1.0)), hair, Vector3(s * 0.125, -0.06, -0.01)))
		var moustache := Art.instance(Art.blob_mesh(0.05, 0.15, 17 + side, Vector3(1.5, 0.62, 0.75)), hair, Vector3(s * 0.052, -0.075, 0.175))
		moustache.rotation.z = s * 0.3
		_head.add_child(moustache)
	_beard = _pivot(_head, Vector3(0, -0.07, 0.09))
	_beard.add_child(Art.instance(Art.blob_mesh(0.19, 0.12, 4, Vector3(1.0, 1.3, 0.62)), hair, Vector3(0, -0.13, 0.0)))

	# The hat: a tall felt cone, tipped back, whose tip is a springy chain of three pieces.
	_hat = _pivot(_head, Vector3(0, 0.09, 0))
	_hat.rotation.x = -0.2
	var cone := PackedVector3Array()
	var cone_radii := PackedFloat32Array()
	for i in 7:
		var t := i / 6.0
		cone.append(Vector3(0, t * 0.32, -t * t * 0.04))
		cone_radii.append(lerpf(0.198, 0.088, t) + 0.006 * sin(t * PI))
	_hat.add_child(Art.instance(Art.tube_mesh(cone, cone_radii, 20), hat))
	var holder := _hat
	var at := Vector3(0, 0.32, -0.04)
	for piece: Vector3 in [Vector3(0.088, 0.066, 0.15), Vector3(0.066, 0.042, 0.14), Vector3(0.042, 0.01, 0.13)]:
		var tip := _pivot(holder, at)
		tip.add_child(Art.sphere(piece.x, hat, Vector3.ZERO)) # Fills the fold, so no seam shows.
		var points := PackedVector3Array([Vector3.ZERO, Vector3(0, piece.z * 0.5, 0), Vector3(0, piece.z, 0)])
		var widths := PackedFloat32Array([piece.x, lerpf(piece.x, piece.y, 0.5), piece.y])
		tip.add_child(Art.instance(Art.tube_mesh(points, widths, 16), hat))
		_hat_tips.append(tip)
		_hat_bend.append(Vector2.ZERO)
		_hat_bend_speed.append(Vector2.ZERO)
		holder = tip
		at = Vector3(0, piece.z, 0)
	# Close the felt over the point.
	holder.add_child(Art.sphere(0.008, hat, at))


func _pivot(parent: Node3D, at: Vector3, name := "") -> Node3D:
	var made := Node3D.new()
	if name:
		made.name = name
	made.position = at
	parent.add_child(made)
	return made


func _ring(inner: float, outer: float, mat: Material, at: Vector3, squash: Vector3) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 24
	var made := Art.instance(torus, mat, at)
	made.scale = squash
	return made
