@tool
extends CharacterBody3D

# The gnome's fox friend: an oversized red fox with a kind, whimsical face, like David the Gnome's
# fox. This is its body: how it looks and how it moves. What it decides to do (follow, explore,
# sniff, sit, pounce, play) is in fox_brain.gd, which steers this body each frame.
#
# It's built on a skeleton of pivots like the gnome: hips and shoulders on a body that tips and
# drops (to sit, lie, sniff or bow), a neck and head that look at things, ears that perk and
# swivel, a springy tail, and four legs. Each leg is two bones that bend to keep its paw on a
# target spot on the ground (two-bone "inverse kinematics"), so the paws plant properly whether
# it's walking, trotting, galloping, sitting, lying down or pouncing.

# How it moves. Speeds are in metres a second; the gnome runs at 7.
const WALK_SPEED := 1.4
const TROT_SPEED := 4.0
const GALLOP_SPEED := 9.5
const ACCELERATION := 13.0
const BRAKING := 14.0
const TURN_RATE := Vector2(4.5, 2.2) # Radians a second it can turn: slow, and at a gallop.
const ARRIVE := 1.6 # Slows down this many metres a second for every metre short of where it's going.
const GRAVITY := 24.0
# Its legs: [cycles a second, part of each step a paw is on the ground, how high a paw lifts], and
# when in the cycle each leg steps: front left, front right, back left, back right.
const GAITS := {
	"walk": [1.5, 0.65, 0.07, [0.25, 0.75, 0.0, 0.5]],
	"trot": [2.6, 0.5, 0.13, [0.0, 0.5, 0.5, 0.0]],
	"gallop": [3.2, 0.36, 0.2, [0.5, 0.6, 0.0, 0.1]],
}
# How it holds itself in each pose: [hip height, body tip (+ nose down), neck tip, front paws
# forward, back paws forward, back paws out to the side].
const POSES := {
	"stand": [0.8, 0.0, 0.0, 0.0, 0.0, 0.0],
	"sit": [0.5, -0.62, -0.25, 0.0, 0.3, 0.06],
	"lie": [0.3, 0.06, 0.15, 0.42, 0.28, 0.16],
	"sniff": [0.78, 0.2, 0.85, -0.05, 0.0, 0.0],
	"bow": [0.84, 0.48, 0.1, 0.32, 0.0, 0.0], # Play bow: chest down, tail up.
	"stalk": [0.62, 0.06, 0.45, 0.05, 0.0, 0.03],
}
const POUNCE := {"crouch": 0.9, "leap": 0.65, "nose_down": 0.9, "up": 0.5}

const COLORS := {
	"fur": Color("#d9702a"),
	"fur_shade": Color("#8e3e14"),
	"cream": Color("#f6ead6"),
	"cream_shade": Color("#cbb89c"),
	"dark": Color("#3a2618"),
	"nose": Color("#1d1410"),
	"eyes": Color("#24170f"),
	"tongue": Color("#e77f86"),
}
const FRONT_LEFT := 0
const FRONT_RIGHT := 1
const BACK_LEFT := 2
const BACK_RIGHT := 3
const LEG_LENGTHS := [Vector2(0.34, 0.42), Vector2(0.34, 0.42), Vector2(0.37, 0.47), Vector2(0.37, 0.47)]

var friend: Node3D # The gnome.
var keep_in := Rect2(-100, -100, 200, 200) # Stay inside this area of x and z.
var brain: RefCounted # Set by the Glen: decides what to do (fox_brain.gd).

var speed := 0.0 # How fast it's going now.
var _goal := Vector3.ZERO
var _goal_speed := 0.0
var _face := Vector3.INF # A spot to turn towards when it's standing still.
var _look := Vector3.INF # A spot to look at.
var _pose := "stand"
var _wag := 0.0 # How happily the tail wags, 0 to 1.
var _heading := 0.0
var _turning := 0.0
var _gallop_time := 0.0
var _pant := 0.0
var _see_through := 0.0 # Fades while it's between the camera and the gnome.
var _meshes: Array[GeometryInstance3D] = []

var _model: Node3D
var _rig: Node3D
var _body: Node3D
var _neck: Node3D
var _head: Node3D
var _jaw: Node3D
var _ears: Array[Node3D] = []
var _eyes: Array[Node3D] = []
var _tail: Node3D
var _tail_pieces: Array[Node3D] = []
var _tail_bend: Array[Vector2] = []
var _tail_bend_speed: Array[Vector2] = []
var _legs: Array = [] # Each: [hip, knee, paw].
var _hip_spots: Array[Vector3] = [] # Where each leg joins the body, in the body's own space.

var _time := 0.0
var _phase := 0.0
var _gait_mix := {"walk": 1.0, "trot": 0.0, "gallop": 0.0}
var _posture := [0.8, 0.0, 0.0, 0.0, 0.0, 0.0]
var _head_turn := Vector2.ZERO
var _ear_twitch := Vector2.ZERO
var _next_twitch := 1.0
var _next_blink := 2.0
var _blink := -1.0
var _pounce := -1.0 # Seconds into a pounce, or -1.
var _pounce_from := Vector3.ZERO
var _pounce_to := Vector3.ZERO
var _last_velocity := Vector3.ZERO
var _sway := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_build_model()
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	shape.shape = capsule
	shape.rotation.x = PI / 2.0
	shape.position = Vector3(0, capsule.radius, 0.05) # Its underside touches the ground.
	add_child(shape)
	# The fox bumps into the world, but the gnome walks straight through it (it's a friend).
	collision_layer = 2
	collision_mask = 1
	_goal = global_position


func place(at: Vector3, facing := 0.0) -> void:
	global_position = at
	_heading = facing
	velocity = Vector3.ZERO
	speed = 0.0
	_goal = at
	_goal_speed = 0.0
	_pounce = -1.0
	_last_velocity = Vector3.ZERO


# --- What the brain can ask for ---

func walk_to(at: Vector3, how_fast: float) -> void:
	_goal = at
	_goal_speed = how_fast


func hold() -> void:
	_goal = global_position
	_goal_speed = 0.0


func face(at: Vector3) -> void:
	_face = at


func look_toward(at: Vector3) -> void:
	_look = at


func set_pose(name: String) -> void:
	_pose = name


func wag(amount: float) -> void:
	_wag = amount


# Let the camera see through it (it's in the way of the gnome).
func fade(faded: bool) -> void:
	var goal := 0.6 if faded else 0.0
	if absf(goal - _see_through) < 0.01:
		return
	_see_through = move_toward(_see_through, goal, get_process_delta_time() * 3.0)
	for mesh in _meshes:
		if mesh.material_override is ShaderMaterial and mesh.material_override.shader == FUR_SHADER:
			mesh.set_instance_shader_parameter("fade", _see_through) # A stipple (see fur.gdshader).
		else:
			mesh.transparency = _see_through


func pounce(at: Vector3) -> bool:
	if _pounce >= 0.0 or not is_on_floor():
		return false
	_pounce = 0.0
	_pounce_from = global_position
	var reach := Vector3(at.x - global_position.x, 0, at.z - global_position.z).limit_length(2.6)
	_pounce_to = global_position + reach
	_heading = atan2(reach.x, reach.z)
	return true


func is_pouncing() -> bool:
	return _pounce >= 0.0


func distance_to_goal() -> float:
	return Vector2(_goal.x - global_position.x, _goal.z - global_position.z).length()


func heading() -> float:
	return _heading


# --- Moving ---

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or friend == null:
		return
	if brain:
		brain.think(delta)
	if _pounce >= 0.0:
		_move_pounce(delta)
		return
	var flat := Vector3(_goal.x - global_position.x, 0, _goal.z - global_position.z)
	var distance := flat.length()
	var wanted := 0.0
	var turn := 0.0
	if distance > 0.15 and _goal_speed > 0.0:
		var bearing := _avoid(atan2(flat.x, flat.z))
		turn = angle_difference(_heading, bearing)
		wanted = minf(_goal_speed, distance * ARRIVE)
		# Way off to the side: slow down and curve round, the way an animal does.
		wanted *= clampf(1.25 - absf(turn) / PI * 1.5, 0.12, 1.0)
	elif _face != Vector3.INF:
		var to_face := _face - global_position
		if Vector2(to_face.x, to_face.z).length() > 0.3:
			turn = angle_difference(_heading, atan2(to_face.x, to_face.z))
	var max_turn := lerpf(TURN_RATE.x, TURN_RATE.y, clampf(speed / GALLOP_SPEED, 0.0, 1.0)) * delta
	var step := clampf(turn, -max_turn, max_turn)
	_heading = wrapf(_heading + step, -PI, PI)
	_turning = _damp(_turning, step / delta, 8.0, delta)
	speed = move_toward(speed, wanted, (ACCELERATION if wanted > speed else BRAKING) * delta)
	velocity.x = sin(_heading) * speed
	velocity.z = cos(_heading) * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	speed = minf(speed, Vector2(get_real_velocity().x, get_real_velocity().z).length() + 0.5) # Not running on the spot.
	global_position.x = clampf(global_position.x, keep_in.position.x, keep_in.end.x)
	global_position.z = clampf(global_position.z, keep_in.position.y, keep_in.end.y)
	_gallop_time = _gallop_time + delta if speed > 7.0 else maxf(_gallop_time - delta * 0.5, 0.0)
	if speed < 0.5 and _gallop_time > 1.5:
		_pant = 5.0 # Out of breath after a good run.
		_gallop_time = 0.0


# Feel ahead with three whiskers (left, middle, right) and steer away from whatever's there (rocks,
# lantern posts, gates). Something dead ahead turns it toward whichever side the goal is on. And if
# it's already touching something, it slides along it rather than pushing into it.
func _avoid(bearing: float) -> float:
	if is_on_wall():
		var wall := get_wall_normal()
		var along := Vector3(-wall.z, 0, wall.x)
		var want := Vector3(sin(bearing), 0, cos(bearing))
		if along.dot(want) < 0.0:
			along = -along
		return atan2(along.x, along.z)
	if speed < 0.5:
		return bearing
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 0.5, 0)
	var reach := 1.0 + speed * 0.25
	var push := 0.0
	for side: float in [-1.0, 0.0, 1.0]:
		var angle := _heading + side * 0.45
		var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3(sin(angle), 0, cos(angle)) * reach, 1, [get_rid()])
		var hit := space.intersect_ray(ray)
		if hit:
			var closeness := 1.0 - from.distance_to(hit.position) / reach
			var away_from := side if side != 0.0 else signf(angle_difference(_heading, bearing) + 0.001)
			push -= away_from * closeness * (1.5 if side == 0.0 else 1.0)
	return bearing + push * 1.2


# A pounce: crouch and wiggle, leap in an arc, nose-dive into the grass, then pop back up.
func _move_pounce(delta: float) -> void:
	_pounce += delta
	var leap_start: float = POUNCE.crouch
	var leap_end: float = leap_start + POUNCE.leap
	speed = 0.0
	velocity = Vector3.ZERO
	if _pounce > leap_start and _pounce < leap_end:
		var t := (_pounce - leap_start) / POUNCE.leap
		var at := _pounce_from.lerp(_pounce_to, t)
		at.y = _pounce_from.y + sin(t * PI) * 1.05
		global_position = at
	elif _pounce >= leap_end:
		global_position = Vector3(_pounce_to.x, _pounce_from.y, _pounce_to.z)
	if _pounce > leap_end + POUNCE.nose_down + POUNCE.up:
		_pounce = -1.0


# --- Animation ---

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_model.rotation.y = _heading
	_update_posture(delta)
	_update_legs(delta)
	_update_head(delta)
	_update_tail(delta)
	_pose_skeleton()


func _update_posture(delta: float) -> void:
	var goal: Array = POSES.get(_pose, POSES.stand)
	if speed > 0.6:
		goal = POSES.stand # Sitting or lying only when still.
	var sharpness := 6.0 if _pose in ["sit", "lie"] else 9.0
	for i in _posture.size():
		_posture[i] = _damp(_posture[i], goal[i], sharpness, delta)
	var hip_height: float = _posture[0]
	var tip: float = _posture[1]
	# Speed changes the gait: walk, trot, gallop.
	var pace := maxf(speed, absf(_turning) * 0.35)
	var mix := {
		"walk": 1.0 - smoothstep(2.0, 3.0, pace),
		"trot": smoothstep(2.0, 3.0, pace) * (1.0 - smoothstep(6.0, 7.5, pace)),
		"gallop": smoothstep(6.0, 7.5, pace),
	}
	for gait in _gait_mix:
		_gait_mix[gait] = _damp(_gait_mix[gait], mix[gait], 6.0, delta)
	var cadence := 0.0
	for gait in GAITS:
		cadence += GAITS[gait][0] * _gait_mix[gait]
	if pace > 0.08:
		_phase = fmod(_phase + delta * cadence * clampf(pace / 1.2, 0.6, 1.0), 1.0)
	var bounce := 0.0
	var rock := 0.0
	if pace > 0.08:
		bounce = -0.025 * cos(_phase * TAU * 2.0) * _gait_mix.trot + 0.06 * sin(_phase * TAU) * _gait_mix.gallop
		rock = 0.12 * sin(_phase * TAU + 0.6) * _gait_mix.gallop
	var breathing := 0.008 * sin(_time * (2.0 if _pant <= 0.0 else 9.0))

	# The pounce, laid over the top.
	var lift := 0.0
	var wiggle := 0.0
	if _pounce >= 0.0:
		var crouch := smoothstep(0.0, 0.3, _pounce) * (1.0 - smoothstep(POUNCE.crouch - 0.05, POUNCE.crouch + 0.1, _pounce))
		var leap := (_pounce - POUNCE.crouch) / POUNCE.leap
		var down := smoothstep(POUNCE.crouch + POUNCE.leap * 0.85, POUNCE.crouch + POUNCE.leap, _pounce) * (1.0 - smoothstep(POUNCE.crouch + POUNCE.leap + POUNCE.nose_down, POUNCE.crouch + POUNCE.leap + POUNCE.nose_down + POUNCE.up, _pounce))
		hip_height = lerpf(hip_height, 0.6, crouch)
		wiggle = sin(_pounce * 28.0) * 0.08 * crouch # Bottom wiggle before the leap.
		if leap > 0.0 and leap < 1.0:
			tip = lerpf(-0.55, 1.0, smoothstep(0.0, 1.0, leap))
		tip = lerpf(tip, 0.85, down)
		hip_height = lerpf(hip_height, 0.85, down)
	_rig.position = Vector3(wiggle * 0.5, lift, 0)
	_body.position.y = hip_height + bounce + breathing
	_body.rotation.x = tip + rock
	_body.rotation.z = clampf(-_turning * 0.04 * speed / TROT_SPEED, -0.18, 0.18) + wiggle
	_pant = maxf(_pant - delta, 0.0)


# Each paw has a spot on the ground; each leg bends to reach it.
func _update_legs(delta: float) -> void:
	var cycle := [0.0, 0.0, 0.0, 0.0]
	var duty := 0.0
	var lift := 0.0
	var cadence := 0.0
	for gait in GAITS:
		var weight: float = _gait_mix[gait]
		cadence += GAITS[gait][0] * weight
		duty += GAITS[gait][1] * weight
		lift += GAITS[gait][2] * weight
		for leg in 4:
			cycle[leg] += GAITS[gait][3][leg] * weight
	var pace := maxf(speed, absf(_turning) * 0.35)
	var stride := clampf(pace / maxf(cadence, 0.5), 0.0, 1.35) * smoothstep(0.05, 0.3, pace)
	var sitting: float = clampf(-_posture[1] / 0.62, 0.0, 1.0)
	for leg in 4:
		var front := leg < 2
		var side := 1.0 if leg % 2 == 0 else -1.0 # Left is +x.
		var hip: Node3D = _legs[leg][0]
		var knee: Node3D = _legs[leg][1]
		var paw: Node3D = _legs[leg][2]
		# Where the paw goes, in the fox's own space (it faces +z).
		var rest_z := 0.43 if front else -0.38
		var spot := Vector3(side * (0.15 if front else 0.17), 0.0, rest_z)
		spot.z += _posture[3] if front else _posture[4]
		spot.x += side * (0.0 if front else _posture[5])
		var t := fmod(_phase + cycle[leg], 1.0)
		if stride > 0.0 and _pounce < 0.0:
			if t < duty:
				spot.z += stride * (0.5 - t / duty)
			else:
				var u := (t - duty) / (1.0 - duty)
				spot.z += stride * (-0.5 + smoothstep(0.0, 1.0, u))
				spot.y += lift * sin(u * PI)
		if _pounce >= 0.0:
			var leap := (_pounce - POUNCE.crouch) / POUNCE.leap
			if leap > 0.0 and leap < 1.0:
				# In the air: back legs stretch out behind, front paws reach for the landing.
				spot += Vector3(0, 0.35, -0.35) if not front else Vector3(0, 0.15 + 0.3 * (1.0 - leap), 0.3)
		# Sitting: front legs stand straight up, under the chest.
		if front and sitting > 0.0:
			spot.z = lerpf(spot.z, 0.3, sitting)
		var target := _model.global_transform * spot
		var lengths: Vector2 = LEG_LENGTHS[leg]
		_reach(hip, knee, target, lengths, front)
		# Keep the paw flat on the ground.
		paw.rotation.x = -(_body.rotation.x + hip.rotation.x + knee.rotation.x)


# Two-bone leg: bend `hip` and `knee` so the end of the leg reaches `target` (in the world).
# Front legs bend backward at the elbow; back legs bend forward at the knee.
func _reach(hip: Node3D, knee: Node3D, target: Vector3, lengths: Vector2, front: bool) -> void:
	var parent: Node3D = hip.get_parent()
	var local := parent.global_transform.affine_inverse() * target - hip.position
	var reach := Vector2(local.y, local.z)
	var distance := clampf(reach.length(), absf(lengths.x - lengths.y) + 0.02, lengths.x + lengths.y - 0.005)
	# The angle of the line from hip to paw. A leg pointing straight down is 0; positive swings it back.
	var line := atan2(-reach.y, -reach.x)
	var a := lengths.x
	var b := lengths.y
	var at_hip := acos(clampf((a * a + distance * distance - b * b) / (2.0 * a * distance), -1.0, 1.0))
	var at_knee := acos(clampf((a * a + b * b - distance * distance) / (2.0 * a * b), -1.0, 1.0))
	if front:
		hip.rotation.x = line + at_hip
		knee.rotation.x = -(PI - at_knee)
	else:
		hip.rotation.x = line - at_hip
		knee.rotation.x = PI - at_knee


func _update_head(delta: float) -> void:
	# Turn the head toward whatever it's looking at, within what a neck can do.
	# Worked out level with the ground, whatever the body is doing; the neck makes up for the body's tip.
	var want := Vector2.ZERO
	if _look != Vector3.INF:
		var local := _model.global_basis.inverse() * (_look - _head.global_position)
		want.x = clampf(atan2(local.x, local.z), -1.0, 1.0)
		want.y = clampf(-atan2(local.y, Vector2(local.x, local.z).length()), -0.6, 0.7)
	_head_turn = _head_turn.lerp(want, 1.0 - exp(-5.0 * delta))
	var sniffing := sin(_time * 14.0) * 0.04 if _pose == "sniff" and speed < 0.5 else 0.0
	var level := 0.3 if _pounce >= 0.0 else 1.0 # In a pounce the head dives with the body.
	_neck.rotation = Vector3(_posture[2] - _body.rotation.x * level + _head_turn.y * 0.5, _head_turn.x * 0.6, 0.0)
	_head.rotation = Vector3(_head_turn.y * 0.5 + sniffing, _head_turn.x * 0.4, -_head_turn.x * 0.15 + sin(_time * 0.7) * 0.06 * float(speed < 0.3))
	# Ears: perk up when looking at something, flatten a little at a gallop, twitch now and then.
	_next_twitch -= delta
	if _next_twitch <= 0.0:
		_next_twitch = _rng.randf_range(1.5, 4.0)
		_ear_twitch = Vector2(_rng.randf_range(-0.5, 0.5), _rng.randf_range(-0.3, 0.3))
	_ear_twitch = _ear_twitch.lerp(Vector2.ZERO, 1.0 - exp(-3.0 * delta))
	var flatten: float = -0.5 * _gait_mix.gallop + 0.15 * _wag
	for side in 2:
		var s := 1.0 if side == 0 else -1.0
		_ears[side].rotation = Vector3(flatten + (_ear_twitch.y if side == 0 else 0.0), s * (_head_turn.x * 0.3 + _ear_twitch.x * float(side == 0)), s * -0.28)
	# Blink.
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.0
		_next_blink = _rng.randf_range(2.0, 5.0)
	var shut := 0.0
	if _blink >= 0.0:
		_blink += delta / 0.18
		shut = sin(clampf(_blink, 0.0, 1.0) * PI)
		if _blink >= 1.0:
			_blink = -1.0
	if _pounce >= 0.0 and _pounce > POUNCE.crouch + POUNCE.leap * 0.8:
		shut = maxf(shut, 0.85) # Eyes scrunched shut in the grass.
	for eye in _eyes:
		eye.scale.y = lerpf(1.0, 0.1, shut)
	# Panting after a run: mouth open, tongue out, quick breaths.
	var open := 0.0 if _pant <= 0.0 else 0.22 + 0.06 * sin(_time * 18.0)
	_jaw.rotation.x = _damp(_jaw.rotation.x, open, 12.0, delta)


# The tail: carried low when relaxed, streaming out at a gallop, up and wagging when happy, curled
# round when lying down. It's springy, so it swings behind every move.
func _update_tail(delta: float) -> void:
	var lying: float = clampf((0.8 - _posture[0]) / 0.5, 0.0, 1.0) * float(_pose == "lie")
	var lift: float = -0.35 + 0.35 * _gait_mix.gallop + 0.2 * _gait_mix.trot + 0.45 * _wag + 0.6 * float(_pose == "bow")
	if _pounce >= 0.0:
		lift = 0.9
	_tail.rotation.x = _damp(_tail.rotation.x, -PI / 2.0 - 0.45 + lift - 0.8 * lying, 6.0, delta)
	var wag_speed := 9.0 + 6.0 * _wag
	_tail.rotation.y = sin(_time * wag_speed) * (0.08 + 0.45 * _wag) * (1.0 - lying) + 0.9 * lying
	var moved := (velocity - _last_velocity) / maxf(delta, 0.001)
	_last_velocity = velocity
	_sway = _sway.lerp((_model.global_basis.inverse() * moved).limit_length(40.0), 1.0 - exp(-10.0 * delta))
	for i in _tail_pieces.size():
		var goal := Vector2(_sway.z * 0.006 + _sway.y * 0.004, -_sway.x * 0.006 + 0.35 * lying) * (1.0 + i * 0.4)
		goal.x += [-0.15, 0.0, 0.12, 0.25, 0.3][i] * (1.0 - lying) # Rest shape: dips, then curves up at the tip.
		var spring := (goal - _tail_bend[i]) * 90.0 - _tail_bend_speed[i] * 8.0
		_tail_bend_speed[i] += spring * delta
		_tail_bend[i] += _tail_bend_speed[i] * delta
		_tail_pieces[i].rotation = Vector3(_tail_bend[i].x, 0.0, _tail_bend[i].y)


static func _damp(from: float, to: float, sharpness: float, delta: float) -> float:
	return lerpf(from, to, 1.0 - exp(-sharpness * delta))


# --- The model ---
# One seamless skin (models/fox_body.res, baked from fox_shape.gd by tools/make_fox.gd) wrapped
# over a Godot Skeleton3D. The animation above moves a tree of pivots; every frame the skeleton's
# bones copy them, and the skin bends with the bones. Only the eyes, nose and tongue are separate.

const BODY_MESH := "res://models/fox_body.res"
const JAW_MESH := "res://models/fox_jaw.res"
const FUR_SHADER := preload("res://shaders/fur.gdshader")

var _bones: Array[Node3D] = [] # The pivots, in the skeleton's order (FoxShape.BONES).
var _skeleton: Skeleton3D


func _build_model() -> void:
	_build_skeleton()
	var fur := ShaderMaterial.new()
	fur.shader = FUR_SHADER
	_skeleton = Skeleton3D.new()
	_model.add_child(_skeleton)
	for i in _bones.size():
		var pivot := _bones[i]
		_skeleton.add_bone(FoxShape.BONES[i])
		var parent := _bones.find(pivot.get_parent())
		_skeleton.set_bone_parent(i, parent)
		_skeleton.set_bone_rest(i, pivot.transform)
	_skeleton.reset_bone_poses()
	if ResourceLoader.exists(BODY_MESH):
		var skin := Skin.new()
		for i in _bones.size():
			skin.add_bind(i, _skeleton.get_bone_global_rest(i).affine_inverse())
		var body := MeshInstance3D.new()
		body.name = "Skin"
		body.mesh = load(BODY_MESH)
		body.material_override = fur
		body.skin = skin
		_skeleton.add_child(body)
		body.skeleton = body.get_path_to(_skeleton)
		_jaw.add_child(Art.instance(load(JAW_MESH), fur))
	else:
		push_warning("The fox's skin hasn't been baked yet: run tools/make_fox.gd.")

	# The face: big kind eyes with a sparkle, set into the skin, a shiny black nose, and a tongue
	# that shows when it pants.
	var nose := Art.material(COLORS.nose, 0.25, {"metallic_specular": 0.9})
	for side in 2:
		var s := 1.0 if side == 0 else -1.0
		var eye := _pivot(_head, Vector3(s * 0.086, 0.04, 0.172))
		var ball := Art.sphere(0.044, Art.material(COLORS.eyes, 0.12, {"metallic_specular": 1.0}), Vector3.ZERO, Vector3(1.05, 1.0, 0.55))
		ball.rotation.z = s * 0.22 # A gentle almond tilt.
		eye.add_child(ball)
		eye.add_child(Art.sphere(0.011, Art.glow_material(Color.WHITE, 0.7), Vector3(-s * 0.01, 0.014, 0.02)))
		eye.add_child(Art.sphere(0.005, Art.glow_material(Color.WHITE, 0.5), Vector3(s * 0.012, -0.01, 0.021)))
		_eyes.append(eye)
	_head.add_child(Art.sphere(0.045, nose, Vector3(0, -0.06, 0.405), Vector3(1.1, 0.85, 0.9)))
	_jaw.add_child(Art.sphere(0.035, Art.material(COLORS.tongue, 0.5), Vector3(0, 0.0, 0.2), Vector3(0.9, 0.35, 1.4)))
	for mesh in _model.find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(mesh)


# The tree of pivots the animation moves; the skeleton's bones follow it. The bake tool
# (tools/make_fox.gd) builds this too, to know where each joint stands.
func _build_skeleton() -> void:
	var named := {}
	_model = _pivot(self, Vector3.ZERO, "Model")
	_rig = _pivot(_model, Vector3.ZERO)
	named.rig = _rig
	# The body hangs from its hips (at the back), so tipping it lifts or lowers the chest.
	_body = _pivot(_rig, Vector3(0, 0.8, -0.42))
	named.body = _body
	for leg in 4:
		var front := leg < 2
		var side := 1.0 if leg % 2 == 0 else -1.0
		var lengths: Vector2 = LEG_LENGTHS[leg]
		var hip := _pivot(_body, Vector3(side * (0.15 if front else 0.16), -0.08 if front else -0.06, 0.85 if front else 0.0))
		var knee := _pivot(hip, Vector3(0, -lengths.x, 0))
		var paw := _pivot(knee, Vector3(0, -lengths.y, 0))
		_legs.append([hip, knee, paw])
		named["leg%d_upper" % leg] = hip
		named["leg%d_lower" % leg] = knee
		named["leg%d_paw" % leg] = paw
	_neck = _pivot(_body, Vector3(0, 0.14, 0.92))
	named.neck = _neck
	_head = _pivot(_neck, Vector3(0, 0.26, 0.12))
	_head.scale = Vector3.ONE * 1.12 # A big head, for storybook proportions.
	named.head = _head
	_jaw = _pivot(_head, Vector3(0, -0.08, 0.1))
	named.jaw = _jaw
	for side in 2:
		var ear := _pivot(_head, Vector3((1.0 if side == 0 else -1.0) * 0.12, 0.13, -0.03))
		_ears.append(ear)
		named["ear%d" % side] = ear
	_tail = _pivot(_body, Vector3(0, 0.1, -0.14))
	_tail.rotation.x = -PI / 2.0 - 0.45
	named.tail = _tail
	var holder := _tail
	for i in 5:
		var piece := _pivot(holder, Vector3.ZERO if i == 0 else Vector3(0, FoxShape.TAIL_PIECE, 0))
		_tail_pieces.append(piece)
		_tail_bend.append(Vector2.ZERO)
		_tail_bend_speed.append(Vector2.ZERO)
		named["tail%d" % i] = piece
		holder = piece
	for bone: String in FoxShape.BONES:
		_bones.append(named[bone])


# Where a joint stands on the fox, standing still, in the fox's own space (for the bake tool).
func rest_of(bone: String) -> Transform3D:
	var pivot: Node3D = _bones[FoxShape.BONES.find(bone)]
	var place := pivot.transform
	var parent := pivot.get_parent() as Node3D
	while parent and parent != _model:
		place = parent.transform * place
		parent = parent.get_parent() as Node3D
	return place


# Copy every pivot onto its bone, so the skin follows the animation.
func _pose_skeleton() -> void:
	if _skeleton == null:
		return
	for i in _bones.size():
		var pivot := _bones[i]
		_skeleton.set_bone_pose_position(i, pivot.position)
		_skeleton.set_bone_pose_rotation(i, pivot.quaternion)
		_skeleton.set_bone_pose_scale(i, pivot.scale)


func _pivot(parent: Node3D, at: Vector3, name := "") -> Node3D:
	var made := Node3D.new()
	if name:
		made.name = name
	made.position = at
	parent.add_child(made)
	return made
