## The hero's living storybook motion (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §3.2,
## Stage 6), layered on HeroCombatAnimator's pose every tick, in pure GDScript:
##   - the cloak (Cloak_01..03) and beard (Jaw_Beard) on analytical damped
##     springs: each step is the exact solution of x'' = -w^2 (x - target) - 2 z w x',
##     so the swing is the same at 30, 60 or 144 frames a second; the cloak
##     trails with speed and wind and is held outside a 0.26 m body capsule,
##     so it never passes through the back or legs
##   - leaning up to 0.24 rad into the run and banking up to 0.26 rad into turns
##   - a 3.2 Hz winded chest heave and shoulder droop under 25% stamina or after
##     a winded third Light
##   - analytical two-bone foot-plant IK on slopes, ramps and bridges (the hips
##     drop half the difference between the feet), the off hand riding a
##     two-hander's HaftGripMarker, and the bow hand drawing the string to the jaw
##   - the chest (25%) and head (65%, within 55 degrees of yaw and 28 of pitch)
##     turning toward a curious hob or an open Glimmer-Spot within 8 m
##   - through a hit-stop, a 45 Hz micro-tremor in the chest and weapon hand,
##     and volume-preserving squash-and-stretch of the hips: (1/sqrt(s), s, 1/sqrt(s))
## It deliberately isn't Godot's SpringBoneSimulator3D (frame-rate dependent,
## godot#103229, and wrong under bone scale), and keeps a readiness guard at
## the top of each step (godot#106463). Inputs are set by ActorVisuals each
## tick; the skeleton runs it when ActorVisuals advances it.
class_name StorybookKinematicsModifier3D
extends SkeletonModifier3D

const B = HeroRigBuilder.Bone
const CLOAK_OMEGA: float = 14.0
const CLOAK_ZETA: float = 0.72
const BEARD_OMEGA: float = 22.0
const BEARD_ZETA: float = 0.55
const BODY_OMEGA: float = 10.0
## The body capsule the cloak stays outside: from the knees to the shoulders, about the spine.
const BODY_CAPSULE_RADIUS: float = 0.26
const BODY_CAPSULE_FORWARD: float = 0.06
const BODY_CAPSULE_BOTTOM: float = 0.42
const LEAN_MAX: float = 0.24
const BANK_MAX: float = 0.26
const WINDED_STAMINA: float = 0.25
const WINDED_HZ: float = 3.2
const LOOK_RANGE: float = 8.0
const LOOK_YAW_MAX: float = 0.9599
const LOOK_PITCH_MAX: float = 0.4887
const LOOK_CHEST_SHARE: float = 0.25
const LOOK_HEAD_SHARE: float = 0.65
const TREMOR_HZ: float = 45.0
const TREMOR_ANGLE: float = 0.05
## A heavy hit-stop (100 ms and more) squashes the hips to 0.86, a light one to 0.93.
const HEAVY_SQUASH: float = 0.86
const LIGHT_SQUASH: float = 0.93
const HEAVY_HIT_STOP: float = 0.09
const ANKLE_HEIGHT: float = 0.09
## An animated ankle this close to the floor is planted.
const PLANT_HEIGHT: float = 0.07
const PELVIS_DROP_MAX: float = 0.3
## The off hand's wrist sits this far back from the grip, toward its shoulder.
const GRIP_WRIST_BACK: float = 0.07
const CLOAK_BONES: Array[int] = [B.CLOAK_01, B.CLOAK_02, B.CLOAK_03]
const CLOAK_REST_FLARE: Array[float] = [0.1, 0.07, 0.05]
const CLOAK_SPEED_FLARE: Array[float] = [0.42, 0.22, 0.16]

# --- Inputs (ActorVisuals sets these each tick) ---
## The hero's velocity in world space, and its full run speed.
var velocity: Vector3 = Vector3.ZERO
var move_speed: float = 6.0
## How far past a run the lean may go (1 a run; ActorVisuals raises it while sprinting).
var lean_reach: float = 1.0
var stamina_ratio: float = 1.0
var winded: bool = false
## Ground heights under each foot, relative to the hero's origin, and whether it stands on the ground.
var ground_left: float = 0.0
var ground_right: float = 0.0
var grounded: bool = true
var foot_ik_weight: float = 1.0
## The two-handed grip: how much it applies, and where the haft's grip is in Hand_R's frame.
var grip_weight: float = 0.0
var grip_in_hand: Transform3D = Transform3D.IDENTITY
## The bow hand's draw toward the jaw, 0 to 1.
var draw_weight: float = 0.0
## Something worth looking at (world space), or none.
var look_target: Vector3 = Vector3.ZERO
var has_look_target: bool = false
## A hit-stop: seconds left, and how long it was in all (100 ms and more is heavy).
var hit_stop_left: float = 0.0
var hit_stop_duration: float = 0.0
## The world's wind (xz direction, w strength).
var wind: Vector4 = Vector4(0.8, 0.0, 0.6, 0.35)
## 0 while a clip owns the whole body (a roll, the kneel); 1 otherwise.
var lean_weight: float = 1.0

# --- What it did last step (for the HUD's tests and debug) ---
var steps: int = 0
var cloak_pitch: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var cloak_roll: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var cloak_pushes: int = 0
var beard_pitch: float = 0.0
var lean: float = 0.0
var bank: float = 0.0
var heave: float = 0.0
var look_weight: float = 0.0
var tremor: float = 0.0
var squash: float = 1.0
var pelvis_drop: float = 0.0
## How far the off hand's wrist ended from its grip target (-1 when not gripping).
var grip_error: float = -1.0
var draw_error: float = -1.0
## How far each planted ankle ended from the ground target.
var foot_errors: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
## The cloak chain's lowest point's distance from the body capsule's axis (model space).
var cloak_clearance: float = 1.0

var _cloak_x: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cloak_roll_x: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _beard: Vector2 = Vector2.ZERO
var _beard_roll: Vector2 = Vector2.ZERO
var _lean: Vector2 = Vector2.ZERO
var _bank: Vector2 = Vector2.ZERO
var _look: Vector2 = Vector2.ZERO
var _look_yaw: Vector2 = Vector2.ZERO
var _look_pitch: Vector2 = Vector2.ZERO
var _drop: Vector2 = Vector2.ZERO
var _squash: Vector2 = Vector2(1.0, 0.0)
var _winded_weight: Vector2 = Vector2.ZERO
var _clock: float = 0.0
var _tremor_clock: float = 0.0
var _last_yaw: float = NAN
var _last_head_forward: Vector3 = Vector3.FORWARD
var _last_hips_y: float = NAN
var _was_stopped: bool = false
var _last_usec: int = 0


## The exact step of a damped spring from (x, v) toward `target` over `dt`: Vector2(x, v).
static func spring_step(state: Vector2, target: float, omega: float, zeta: float, dt: float) -> Vector2:
	if dt <= 0.0:
		return state
	var y0: float = state.x - target
	var v0: float = state.y
	if zeta < 0.999:
		var damped: float = omega * sqrt(1.0 - zeta * zeta)
		var decay: float = exp(-zeta * omega * dt)
		var c: float = cos(damped * dt)
		var s: float = sin(damped * dt)
		var y: float = decay * (y0 * c + (v0 + zeta * omega * y0) / damped * s)
		var v: float = decay * (v0 * c - (zeta * omega * v0 + omega * omega * y0) / damped * s)
		return Vector2(target + y, v)
	var e: float = exp(-omega * dt)
	return Vector2(target + (y0 + (v0 + omega * y0) * dt) * e, (v0 - omega * (v0 + omega * y0) * dt) * e)


func _process_modification_with_delta(delta: float) -> void:
	if not is_inside_tree():
		return
	_solve(delta)


## The older entry point some builds call: the same step, timed by the clock.
func _process_modification() -> void:
	if not is_inside_tree():
		return
	var now: int = Time.get_ticks_usec()
	var delta: float = 0.0 if _last_usec == 0 else clampf(float(now - _last_usec) / 1000000.0, 0.0, 0.1)
	_last_usec = now
	_solve(delta)


func _solve(dt: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or skeleton.get_bone_count() != HeroRigBuilder.BONE_COUNT:
		return
	steps += 1
	_clock += dt
	var rot: Array[Quaternion] = []
	var pos: Array[Vector3] = []
	for bone: int in HeroRigBuilder.BONE_COUNT:
		rot.append(skeleton.get_bone_pose_rotation(bone))
		pos.append(skeleton.get_bone_pose_position(bone))
	var hips_scale: Vector3 = skeleton.get_bone_pose_scale(B.HIPS)
	var frame: Basis = skeleton.global_transform.basis.orthonormalized()
	var local_velocity: Vector3 = frame.inverse() * velocity
	var forward_speed: float = -local_velocity.z
	var side_speed: float = local_velocity.x
	var yaw: float = frame.get_euler().y
	var yaw_rate: float = 0.0 if is_nan(_last_yaw) or dt <= 0.0 else wrapf(yaw - _last_yaw, -PI, PI) / dt
	_last_yaw = yaw
	var run: float = clampf(Vector2(local_velocity.x, local_velocity.z).length() / maxf(move_speed, 0.1), 0.0, 1.0)

	# Lean into the run, bank into the turn.
	_lean = spring_step(_lean, -LEAN_MAX * clampf(forward_speed / maxf(move_speed, 0.1), -0.5, lean_reach) * lean_weight, BODY_OMEGA, 1.0, dt)
	_bank = spring_step(_bank, clampf(yaw_rate * 0.1 * run, -BANK_MAX, BANK_MAX) * lean_weight, BODY_OMEGA, 1.0, dt)
	lean = _lean.x
	bank = _bank.x
	rot[B.SPINE] = rot[B.SPINE] * Quaternion(Vector3.RIGHT, lean * 0.6) * Quaternion(Vector3.BACK, bank * 0.55)
	rot[B.CHEST] = rot[B.CHEST] * Quaternion(Vector3.RIGHT, lean * 0.4) * Quaternion(Vector3.BACK, bank * 0.45)

	# Winded: the chest heaves at 3.2 Hz and the shoulders droop.
	_winded_weight = spring_step(_winded_weight, 1.0 if winded or stamina_ratio < WINDED_STAMINA else 0.0, 8.0, 1.0, dt)
	heave = sin(_clock * TAU * WINDED_HZ) * _winded_weight.x
	rot[B.CHEST] = rot[B.CHEST] * Quaternion(Vector3.RIGHT, 0.07 * heave)
	rot[B.CLAVICLE_L] = rot[B.CLAVICLE_L] * Quaternion(Vector3.BACK, (0.06 * heave - 0.06 * _winded_weight.x))
	rot[B.CLAVICLE_R] = rot[B.CLAVICLE_R] * Quaternion(Vector3.BACK, -(0.06 * heave - 0.06 * _winded_weight.x))

	# Look toward a curious hob or an open Glimmer-Spot.
	var look_yaw_target: float = 0.0
	var look_pitch_target: float = 0.0
	var looking: bool = false
	if has_look_target:
		var local_target: Vector3 = skeleton.global_transform.affine_inverse() * look_target
		var eyes: Vector3 = Vector3(0.0, 1.6, 0.0) + pos[B.HIPS] - HeroRigBuilder.local_rests()[B.HIPS].origin
		var toward: Vector3 = local_target - eyes
		if toward.length() <= LOOK_RANGE and toward.length() > 0.3:
			looking = true
			look_yaw_target = clampf(atan2(-toward.x, -toward.z), -LOOK_YAW_MAX, LOOK_YAW_MAX)
			look_pitch_target = clampf(atan2(toward.y, Vector2(toward.x, toward.z).length()), -LOOK_PITCH_MAX, LOOK_PITCH_MAX)
	_look = spring_step(_look, 1.0 if looking else 0.0, 7.0, 1.0, dt)
	_look_yaw = spring_step(_look_yaw, look_yaw_target, 9.0, 1.0, dt)
	_look_pitch = spring_step(_look_pitch, look_pitch_target, 9.0, 1.0, dt)
	look_weight = _look.x
	if look_weight > 0.001:
		var yaw_turn: float = _look_yaw.x * look_weight
		var pitch_turn: float = _look_pitch.x * look_weight
		rot[B.CHEST] = rot[B.CHEST] * Quaternion(Vector3.UP, yaw_turn * LOOK_CHEST_SHARE) * Quaternion(Vector3.RIGHT, pitch_turn * LOOK_CHEST_SHARE)
		rot[B.HEAD] = rot[B.HEAD] * Quaternion(Vector3.UP, yaw_turn * LOOK_HEAD_SHARE) * Quaternion(Vector3.RIGHT, pitch_turn * LOOK_HEAD_SHARE)

	# Hit-stop: a 45 Hz micro-tremor, and the impact squash held, then sprung back.
	var stopped: bool = hit_stop_left > 0.0
	if stopped and not _was_stopped:
		_squash = Vector2(HEAVY_SQUASH if maxf(hit_stop_duration, hit_stop_left) >= HEAVY_HIT_STOP else LIGHT_SQUASH, 0.0)
		_tremor_clock = 0.0
	_was_stopped = stopped
	if stopped:
		_tremor_clock += dt
		tremor = TREMOR_ANGLE * sin(TAU * TREMOR_HZ * _tremor_clock)
		rot[B.CHEST] = rot[B.CHEST] * Quaternion(Vector3.UP, tremor)
		rot[B.HAND_R] = rot[B.HAND_R] * Quaternion(Vector3.RIGHT, tremor * 1.5)
	else:
		tremor = 0.0
		_squash = spring_step(_squash, 1.0, 18.0, 0.4, dt)
	squash = clampf(_squash.x, 0.6, 1.3)

	# The hips drop half the difference between the feet on a slope.
	var drop_target: float = 0.0
	if grounded and foot_ik_weight > 0.0:
		drop_target = -minf(PELVIS_DROP_MAX, 0.5 * absf(ground_left - ground_right))
	_drop = spring_step(_drop, drop_target, 14.0, 1.0, dt)
	pelvis_drop = _drop.x
	pos[B.HIPS].y += pelvis_drop

	# Feet planted on the ground under them.
	if foot_ik_weight > 0.0:
		var sides: Array[Array] = [[B.THIGH_L, B.SHIN_L, B.FOOT_L, ground_left], [B.THIGH_R, B.SHIN_R, B.FOOT_R, ground_right]]
		for index: int in 2:
			var leg: Array = sides[index]
			var globals: Array[Transform3D] = _globals(rot, pos)
			var ankle: Vector3 = globals[int(leg[2])].origin
			var floor_y: float = ANKLE_HEIGHT + float(leg[3])
			var planted: float = 1.0 - smoothstep(PLANT_HEIGHT * 0.5, PLANT_HEIGHT * 1.6, ankle.y - ANKLE_HEIGHT)
			var target_y: float = lerpf(ankle.y, floor_y, planted * foot_ik_weight)
			target_y = maxf(target_y, lerpf(ankle.y, floor_y, foot_ik_weight))
			var target: Vector3 = Vector3(ankle.x, target_y, ankle.z)
			foot_errors[index] = 0.0
			if target.distance_to(ankle) > 0.001:
				foot_errors[index] = _two_bone(rot, pos, int(leg[0]), int(leg[1]), int(leg[2]), target, Vector3(0.0, 0.0, -1.0), true)

	# The off hand rides a two-hander's haft; the bow hand draws to the jaw.
	grip_error = -1.0
	if grip_weight > 0.001:
		var globals: Array[Transform3D] = _globals(rot, pos)
		var grip: Vector3 = (globals[B.HAND_R] * grip_in_hand).origin
		var shoulder: Vector3 = globals[B.UPPER_ARM_L].origin
		var wrist_target: Vector3 = grip + (shoulder - grip).normalized() * GRIP_WRIST_BACK
		var wrist: Vector3 = globals[B.HAND_L].origin
		grip_error = _two_bone(rot, pos, B.UPPER_ARM_L, B.FOREARM_L, B.HAND_L, wrist.lerp(wrist_target, grip_weight), Vector3(-0.5, -0.6, 0.4), false)
		_point_hand(rot, pos, B.HAND_L, grip)
	draw_error = -1.0
	if draw_weight > 0.001:
		var globals: Array[Transform3D] = _globals(rot, pos)
		var jaw: Vector3 = globals[B.JAW_BEARD].origin + globals[B.CHEST].basis.x.normalized() * 0.07 + Vector3(0.0, -0.03, 0.0)
		var wrist: Vector3 = globals[B.HAND_R].origin
		draw_error = _two_bone(rot, pos, B.UPPER_ARM_R, B.FOREARM_R, B.HAND_R, wrist.lerp(jaw, draw_weight), Vector3(0.6, -0.2, 0.6), false)

	# The cloak trails with speed and the wind, flutters, and stays outside the body.
	var wind_local: Vector3 = frame.inverse() * Vector3(wind.x, 0.0, wind.z) * wind.w
	var speed_back: float = clampf(forward_speed / maxf(move_speed, 0.1), 0.0, 1.3)
	for index: int in 3:
		var flutter: float = sin(_clock * 7.3 + float(index) * 1.7) * 0.05 * (0.25 + speed_back) + sin(_clock * 2.1 + float(index)) * 0.02
		var pitch_target: float = -(CLOAK_REST_FLARE[index] + CLOAK_SPEED_FLARE[index] * speed_back + 0.25 * maxf(0.0, wind_local.z)) + flutter
		var roll_target: float = clampf(-side_speed / maxf(move_speed, 0.1) * 0.25 + yaw_rate * 0.03 * float(index + 1) + wind_local.x * 0.12, -0.4, 0.4)
		_cloak_x[index] = spring_step(_cloak_x[index], pitch_target, CLOAK_OMEGA, CLOAK_ZETA, dt)
		_cloak_roll_x[index] = spring_step(_cloak_roll_x[index], roll_target, CLOAK_OMEGA, CLOAK_ZETA, dt)
	var base_cloak: Array[Quaternion] = [rot[B.CLOAK_01], rot[B.CLOAK_02], rot[B.CLOAK_03]]
	cloak_pushes = 0
	for attempt: int in 8:
		for index: int in 3:
			rot[CLOAK_BONES[index]] = base_cloak[index] * Quaternion(Vector3.RIGHT, _cloak_x[index].x) * Quaternion(Vector3.BACK, _cloak_roll_x[index].x)
		var deepest: int = _cloak_inside_body(rot, pos)
		if deepest < 0:
			break
		# Push the bone above the point that went in back out, and let the spring keep it there.
		var pushed: int = maxi(deepest - 1, 0)
		_cloak_x[pushed] = Vector2(_cloak_x[pushed].x - 0.08, minf(_cloak_x[pushed].y, 0.0))
		cloak_pushes += 1
	for index: int in 3:
		cloak_pitch[index] = _cloak_x[index].x
		cloak_roll[index] = _cloak_roll_x[index].x

	# The beard swings behind the head's own motion.
	var head_forward: Vector3 = (_globals(rot, pos)[B.HEAD].basis * Vector3.FORWARD).normalized()
	var pitch_rate: float = 0.0 if dt <= 0.0 else (head_forward.y - _last_head_forward.y) / dt
	var turn_rate: float = 0.0 if dt <= 0.0 else _last_head_forward.cross(head_forward).y / dt
	_last_head_forward = head_forward
	# The stride's bounce flicks it too: it trails the hips' rise and fall by about two frames (19B).
	var hips_rise: float = 0.0 if dt <= 0.0 or is_nan(_last_hips_y) else (pos[B.HIPS].y - _last_hips_y) / dt
	_last_hips_y = pos[B.HIPS].y
	_beard = spring_step(_beard, clampf(0.05 * pitch_rate - 0.04 * forward_speed / maxf(move_speed, 0.1) - 0.12 * hips_rise, -0.35, 0.35),
		BEARD_OMEGA, BEARD_ZETA, dt)
	_beard_roll = spring_step(_beard_roll, clampf(-0.05 * turn_rate, -0.3, 0.3), BEARD_OMEGA, BEARD_ZETA, dt)
	beard_pitch = _beard.x
	rot[B.JAW_BEARD] = rot[B.JAW_BEARD] * Quaternion(Vector3.RIGHT, beard_pitch) * Quaternion(Vector3.BACK, _beard_roll.x)

	for bone: int in HeroRigBuilder.BONE_COUNT:
		skeleton.set_bone_pose_rotation(bone, rot[bone].normalized())
	skeleton.set_bone_pose_position(B.HIPS, pos[B.HIPS])
	var root: float = 1.0 / sqrt(maxf(squash, 0.01))
	skeleton.set_bone_pose_scale(B.HIPS, hips_scale * Vector3(root, squash, root))


## Every bone's transform in the skeleton's space, from local rotations and positions.
static func _globals(rot: Array[Quaternion], pos: Array[Vector3]) -> Array[Transform3D]:
	var globals: Array[Transform3D] = []
	globals.resize(HeroRigBuilder.BONE_COUNT)
	for bone: int in HeroRigBuilder.BONE_COUNT:
		var local: Transform3D = Transform3D(Basis(rot[bone]), pos[bone])
		var parent: int = HeroRigBuilder.BONE_PARENTS[bone]
		globals[bone] = globals[parent] * local if parent >= 0 else local
	return globals


## Analytical two-bone IK (Law of Cosines): turns `upper` and `lower` so the
## head of `end` reaches `target`, bending in the plane the middle joint already
## bends in (or toward `pole`). `keep_end` holds the end bone's orientation
## (a foot stays flat). Returns how far short it fell.
static func _two_bone(rot: Array[Quaternion], pos: Array[Vector3], upper: int, lower: int, end: int, target: Vector3, pole: Vector3, keep_end: bool) -> float:
	var globals: Array[Transform3D] = _globals(rot, pos)
	var a: Vector3 = globals[upper].origin
	var b: Vector3 = globals[lower].origin
	var c: Vector3 = globals[end].origin
	var first: float = a.distance_to(b)
	var second: float = b.distance_to(c)
	var reach: Vector3 = target - a
	if reach.length() < 0.001 or first < 0.001 or second < 0.001:
		return 0.0
	var dir: Vector3 = reach.normalized()
	var distance: float = clampf(reach.length(), absf(first - second) + 0.001, first + second - 0.001)
	var bend: Vector3 = (b - a) - dir * dir.dot(b - a)
	if bend.length() < 0.01:
		bend = pole - dir * dir.dot(pole)
	bend = bend.normalized()
	var cos_a: float = clampf((first * first + distance * distance - second * second) / (2.0 * first * distance), -1.0, 1.0)
	var new_b: Vector3 = a + (dir * cos_a + bend * sqrt(1.0 - cos_a * cos_a)) * first
	var new_c: Vector3 = a + dir * distance
	var turn_upper: Quaternion = HeroPoseBaker.arc((b - a).normalized(), (new_b - a).normalized())
	var upper_global: Basis = Basis(turn_upper) * globals[upper].basis
	var lower_from: Vector3 = (turn_upper * (c - b)).normalized()
	var turn_lower: Quaternion = HeroPoseBaker.arc(lower_from, (new_c - new_b).normalized())
	var lower_global: Basis = Basis(turn_lower) * Basis(turn_upper) * globals[lower].basis
	var parent: int = HeroRigBuilder.BONE_PARENTS[upper]
	rot[upper] = (globals[parent].basis.inverse() * upper_global).get_rotation_quaternion()
	rot[lower] = (upper_global.inverse() * lower_global).get_rotation_quaternion()
	if keep_end:
		rot[end] = (lower_global.inverse() * globals[end].basis).get_rotation_quaternion()
	return new_c.distance_to(target)


## Turns a hand so it points from its wrist toward `point` (the grip on the haft).
static func _point_hand(rot: Array[Quaternion], pos: Array[Vector3], hand: int, point: Vector3) -> void:
	var globals: Array[Transform3D] = _globals(rot, pos)
	var wrist: Vector3 = globals[hand].origin
	var want: Vector3 = point - wrist
	if want.length() < 0.01:
		return
	var turned: Basis = Basis(HeroPoseBaker.arc(globals[hand].basis.y.normalized(), want.normalized())) * globals[hand].basis
	rot[hand] = (globals[HeroRigBuilder.BONE_PARENTS[hand]].basis.inverse() * turned).get_rotation_quaternion()


## The deepest cloak point inside the body capsule (1 = Cloak_02's head, 2 =
## Cloak_03's head, 3 = the hem), or -1; it also records the cloak's clearance.
func _cloak_inside_body(rot: Array[Quaternion], pos: Array[Vector3]) -> int:
	var globals: Array[Transform3D] = _globals(rot, pos)
	var top: Vector3 = globals[B.CHEST].origin + Vector3(0.0, 0.16, -BODY_CAPSULE_FORWARD)
	var bottom: Vector3 = Vector3(globals[B.HIPS].origin.x, BODY_CAPSULE_BOTTOM, globals[B.HIPS].origin.z - BODY_CAPSULE_FORWARD)
	var hem: Vector3 = globals[B.CLOAK_03].origin + globals[B.CLOAK_03].basis.y.normalized() * HeroRigBuilder.bone_length(B.CLOAK_03)
	var points: Array[Vector3] = [globals[B.CLOAK_02].origin, globals[B.CLOAK_03].origin, hem]
	var deepest: int = -1
	var worst: float = 0.0
	cloak_clearance = INF
	for index: int in points.size():
		var axis: Vector3 = Geometry3D.get_closest_point_to_segment(points[index], bottom, top)
		var distance: float = points[index].distance_to(axis)
		cloak_clearance = minf(cloak_clearance, distance)
		var depth: float = BODY_CAPSULE_RADIUS - distance
		if depth > worst:
			worst = depth
			deepest = index + 1
	return deepest
