## The kin's clips (docs/30_KIN_DESIGN_LANGUAGE.md §8), authored once per skeleton
## family by bone name, keyed at 60 Hz, and baked by KinAnimator into each look's
## own AnimationLibrary (its rest differs, its clips don't). A key's pose:
##   "e"     {bone: Vector3 degrees}  a turn in the bone's own frame (KinRig's rules:
##                                    +X swings a hanging limb forward, leans an
##                                    upright bone back, lifts a forward one, droops
##                                    one pointing back; +Z turns a forward bone left)
##   "w"     {bone: Vector3 degrees}  a turn about the model's own axes at the bone
##                                    (+Y turns a right leg forward, +Z lifts it)
##   "root"  Vector3                  the core bone's offset (Hips, Body or Base), in
##                                    metres at the family's reference size
##   "scale" Vector3                  the core bone's scale (squash and stretch)
## Left bones mirror the right as (x, -y, -z) when a pose names only the right.
## Every family has: idle, walk, run, hit, stagger, kneel (its posture broken),
## waver (worn down, ready to be calmed), collapse (scattered), calmed (the calm's
## shake and settle), happy (a soothed hob's dance) and its blows; the two-legged
## add bow (a steward's), the weevils gnaw, and the big kin roar.
class_name KinClipBook
extends RefCounted

const R = KinRigBuilder.Rig
## Each family's core bone (the "root" and "scale" keys move it).
const CORE: Dictionary[int, StringName] = {R.QUADRUPED: &"Hips", R.HEXAPOD: &"Body", R.BIPED: &"Hips", R.STALK: &"Base", R.BLOB: &"Base"}
## The size the family's "root" offsets were authored at (a look scales them by its height over this).
const REFERENCE_HEIGHT: Dictionary[int, float] = {R.QUADRUPED: 1.1, R.HEXAPOD: 0.62, R.BIPED: 1.75, R.STALK: 2.0, R.BLOB: 1.6}
## A walk and a run cycle's frames (the run is quicker); how far a cycle carries comes from the look.
const WALK_FRAMES: int = 48
const RUN_FRAMES: int = 26


## Every clip a family has: [name, spec], spec {"frames", "loop", "windup", "active", "hold", "keys": [[frame, pose]...]}.
static func clips(rig: int) -> Array:
	match rig:
		R.HEXAPOD:
			return _hexapod()
		R.BIPED:
			return _biped()
		R.STALK:
			return _stalk()
		R.BLOB:
			return _blob()
	return _quadruped()


# --- Helpers ---------------------------------------------------------------------

static func _clip(frames: int, keys: Array, loop: bool = false, windup: int = 0, active: int = 0, hold: bool = false) -> Dictionary:
	return {"frames": frames, "loop": loop, "windup": windup, "active": active, "hold": hold, "keys": keys}


## A pose naming right-side bones gets their left partners mirrored in.
static func _p(e: Dictionary, root: Vector3 = Vector3.ZERO, w: Dictionary = {}, scale: Vector3 = Vector3.ONE) -> Dictionary:
	return {"e": _mirrored(e), "w": _mirrored(w), "root": root, "scale": scale}


static func _mirrored(turns: Dictionary) -> Dictionary:
	var out: Dictionary = turns.duplicate()
	for bone: Variant in turns:
		var text: String = String(bone)
		var left: String = ""
		for pair: Array in [["_R", "_L"], ["_FR", "_FL"], ["_HR", "_HL"], ["R1", "L1"], ["R2", "L2"], ["R3", "L3"]]:
			if text.ends_with(pair[0]):
				left = text.substr(0, text.length() - String(pair[0]).length()) + pair[1]
				break
		if left != "" and not turns.has(StringName(left)) and not turns.has(left):
			var v: Vector3 = turns[bone]
			out[StringName(left)] = Vector3(v.x, -v.y, -v.z)
	return out


## Keys sampled from `pose_at(phase 0..1) -> Dictionary` every `step` frames over `frames`.
static func _sampled(frames: int, step: int, pose_at: Callable) -> Array:
	var keys: Array = []
	var frame: int = 0
	while frame <= frames:
		keys.append([frame, pose_at.call(float(frame) / float(frames))])
		frame += step
	if int(keys[keys.size() - 1][0]) != frames:
		keys.append([frames, pose_at.call(1.0)])
	return keys


## A leg's swing in a gait at phase `q` (0..1): [forward angle -1..1, lift 0..1], swinging for the first `share`.
static func _stride(q: float, share: float) -> Vector2:
	q = fposmod(q, 1.0)
	if q < share:
		var u: float = q / share
		return Vector2(lerpf(-1.0, 1.0, smoothstep(0.0, 1.0, u)), sin(u * PI))
	return Vector2(lerpf(1.0, -1.0, (q - share) / (1.0 - share)), 0.0)


## A tremble: -1..1 flipping every few frames.
static func _shiver(frame: float, rate: float) -> float:
	return sin(frame * rate) * cos(frame * rate * 0.37)


# --- Four legs ------------------------------------------------------------------------

static func _quad_gait(q: float, phases: Array, share: float, reach: float, bob: float, flex: float) -> Dictionary:
	var e: Dictionary = {}
	var legs: Array = [["FL", phases[0]], ["FR", phases[1]], ["HL", phases[2]], ["HR", phases[3]]]
	for leg: Array in legs:
		var s: Vector2 = _stride(q + float(leg[1]), share)
		var tag: String = leg[0]
		if tag.begins_with("F"):
			e[StringName("Upper_" + tag)] = Vector3(s.x * reach, 0.0, 0.0)
			e[StringName("Fore_" + tag)] = Vector3(-s.y * flex * 1.1 + maxf(0.0, -s.x) * 6.0, 0.0, 0.0)
			e[StringName("Paw_" + tag)] = Vector3(-s.y * flex * 1.2 + s.x * 8.0, 0.0, 0.0)
		else:
			e[StringName("Thigh_" + tag)] = Vector3(s.x * reach * 0.9, 0.0, 0.0)
			e[StringName("Shank_" + tag)] = Vector3(-s.y * flex * 0.8, 0.0, 0.0)
			e[StringName("Hock_" + tag)] = Vector3(s.y * flex * 1.1, 0.0, 0.0)
			e[StringName("Paw_" + tag)] = Vector3(-s.y * flex * 0.8 + s.x * 6.0, 0.0, 0.0)
	var wave: float = sin(q * TAU)
	e[&"Spine"] = Vector3(sin(q * TAU * 2.0) * bob * 40.0, wave * 3.0, 0.0)
	e[&"Neck"] = Vector3(cos(q * TAU * 2.0) * bob * 60.0, -wave * 3.0, 0.0)
	e[&"Head"] = Vector3(-cos(q * TAU * 2.0) * bob * 40.0, 0.0, 0.0)
	e[&"Tail_1"] = Vector3(-8.0, 0.0, wave * 10.0)
	e[&"Tail_2"] = Vector3(-4.0, 0.0, sin(q * TAU - 0.7) * 12.0)
	e[&"Tail_3"] = Vector3(0.0, 0.0, sin(q * TAU - 1.4) * 14.0)
	e[&"Ear_R"] = Vector3(sin(q * TAU * 2.0) * 4.0, 0.0, 0.0)
	return {"e": e, "w": {}, "root": Vector3(0.0, -absf(cos(q * TAU)) * bob, 0.0), "scale": Vector3.ONE}


static func _quadruped() -> Array:
	var list: Array = []
	list.append([&"idle", _clip(180, _sampled(180, 10, func(p: float) -> Dictionary:
		var breath: float = sin(p * TAU * 3.0)
		var glance: float = sin(p * TAU) * 14.0 + sin(p * TAU * 2.0 + 1.0) * 5.0
		var flick: float = 18.0 * smoothstep(0.62, 0.65, p) * (1.0 - smoothstep(0.68, 0.72, p))
		return _p({&"Chest": Vector3(breath * 1.6, 0.0, 0.0), &"Neck": Vector3(4.0 + breath * 1.5, 0.0, glance * 0.5),
			&"Head": Vector3(-3.0, 0.0, glance * 0.6), &"Jaw": Vector3(-2.0 - breath, 0.0, 0.0),
			&"Ear_R": Vector3(-flick, 0.0, 0.0), &"Ear_L": Vector3(sin(p * TAU * 2.0) * 4.0, 0.0, 0.0),
			&"Tail_1": Vector3(-6.0, 0.0, sin(p * TAU * 2.0) * 9.0), &"Tail_2": Vector3(-3.0, 0.0, sin(p * TAU * 2.0 - 0.6) * 9.0),
			&"Tail_3": Vector3(0.0, 0.0, sin(p * TAU * 2.0 - 1.2) * 10.0)}, Vector3(0.0, breath * 0.004, 0.0))), true)])
	list.append([&"walk", _clip(WALK_FRAMES, _sampled(WALK_FRAMES, 4, func(p: float) -> Dictionary:
		return _quad_gait(p, [0.25, 0.75, 0.0, 0.5], 0.36, 22.0, 0.012, 34.0)), true)])
	list.append([&"run", _clip(RUN_FRAMES, _sampled(RUN_FRAMES, 2, func(p: float) -> Dictionary:
		var pose: Dictionary = _quad_gait(p, [0.5, 0.6, 0.0, 0.1], 0.44, 34.0, 0.035, 48.0)
		pose["e"][&"Spine"] = Vector3(sin(p * TAU) * 7.0, 0.0, 0.0)
		pose["e"][&"Chest"] = Vector3(-sin(p * TAU) * 5.0, 0.0, 0.0)
		pose["root"] = Vector3(0.0, sin(p * TAU) * 0.035, 0.0)
		return pose), true)])
	# A bite: drawn back low on its haunches, then the lunge and the snap.
	list.append([&"attack_bite", _clip(50, [
		[0, _p({})],
		[14, _p({&"Neck": Vector3(-14.0, 0.0, 0.0), &"Head": Vector3(6.0, 0.0, 0.0), &"Jaw": Vector3(-8.0, 0.0, 0.0), &"Ear_R": Vector3(30.0, 0.0, 0.0),
			&"Thigh_HR": Vector3(14.0, 0.0, 0.0), &"Shank_HR": Vector3(-14.0, 0.0, 0.0), &"Upper_FR": Vector3(-10.0, 0.0, 0.0)}, Vector3(0.0, -0.05, 0.07))],
		[26, _p({&"Neck": Vector3(-18.0, 0.0, 0.0), &"Head": Vector3(10.0, 0.0, 0.0), &"Jaw": Vector3(-30.0, 0.0, 0.0), &"Ear_R": Vector3(35.0, 0.0, 0.0),
			&"Thigh_HR": Vector3(20.0, 0.0, 0.0), &"Shank_HR": Vector3(-20.0, 0.0, 0.0), &"Upper_FR": Vector3(-14.0, 0.0, 0.0)}, Vector3(0.0, -0.07, 0.09))],
		[30, _p({&"Neck": Vector3(12.0, 0.0, 0.0), &"Head": Vector3(-10.0, 0.0, 0.0), &"Jaw": Vector3(-34.0, 0.0, 0.0), &"Ear_R": Vector3(20.0, 0.0, 0.0),
			&"Upper_FR": Vector3(28.0, 0.0, 0.0), &"Thigh_HR": Vector3(-24.0, 0.0, 0.0)}, Vector3(0.0, 0.02, -0.16))],
		[34, _p({&"Neck": Vector3(10.0, 0.0, 0.0), &"Head": Vector3(-8.0, 0.0, 0.0), &"Jaw": Vector3(2.0, 0.0, 0.0),
			&"Upper_FR": Vector3(22.0, 0.0, 0.0), &"Thigh_HR": Vector3(-18.0, 0.0, 0.0)}, Vector3(0.0, 0.0, -0.14))],
		[50, _p({})],
	], false, 26, 32)])
	# A gore: head down, tusks low, then the toss.
	list.append([&"attack_gore", _clip(50, [
		[0, _p({})],
		[26, _p({&"Neck": Vector3(-14.0, 0.0, 0.0), &"Head": Vector3(-22.0, 0.0, 0.0), &"Spine": Vector3(-4.0, 0.0, 0.0),
			&"Thigh_HR": Vector3(18.0, 0.0, 0.0), &"Shank_HR": Vector3(-16.0, 0.0, 0.0)}, Vector3(0.0, -0.05, 0.08))],
		[31, _p({&"Neck": Vector3(18.0, 0.0, 8.0), &"Head": Vector3(24.0, 0.0, 6.0), &"Jaw": Vector3(-12.0, 0.0, 0.0), &"Upper_FR": Vector3(20.0, 0.0, 0.0)},
			Vector3(0.0, 0.04, -0.16))],
		[36, _p({&"Neck": Vector3(10.0, 0.0, 4.0), &"Head": Vector3(12.0, 0.0, 0.0)}, Vector3(0.0, 0.01, -0.12))],
		[50, _p({})],
	], false, 26, 32)])
	# A toad's lunge: squat right down, then spring forward with the jaw agape.
	list.append([&"attack_lunge", _clip(52, [
		[0, _p({})],
		[26, _p({&"Thigh_HR": Vector3(16.0, 0.0, 0.0), &"Shank_HR": Vector3(-20.0, 0.0, 0.0), &"Upper_FR": Vector3(-16.0, 0.0, 0.0),
			&"Fore_FR": Vector3(20.0, 0.0, 0.0), &"Head": Vector3(10.0, 0.0, 0.0)}, Vector3(0.0, -0.06, 0.05))],
		[32, _p({&"Thigh_HR": Vector3(-34.0, 0.0, 0.0), &"Hock_HR": Vector3(-30.0, 0.0, 0.0), &"Upper_FR": Vector3(36.0, 0.0, 0.0), &"Jaw": Vector3(-34.0, 0.0, 0.0),
			&"Head": Vector3(14.0, 0.0, 0.0)}, Vector3(0.0, 0.12, -0.22))],
		[38, _p({&"Upper_FR": Vector3(20.0, 0.0, 0.0), &"Jaw": Vector3(0.0, 0.0, 0.0)}, Vector3(0.0, 0.0, -0.18))],
		[52, _p({})],
	], false, 26, 34)])
	# The Stag's antler sweep: reared and turned, then the great sideways sweep.
	list.append([&"attack_antlers", _clip(64, [
		[0, _p({})],
		[34, _p({&"Spine": Vector3(8.0, 0.0, 0.0), &"Chest": Vector3(8.0, 0.0, 0.0), &"Neck": Vector3(-8.0, 0.0, 20.0), &"Head": Vector3(-24.0, 0.0, 12.0),
			&"Upper_FR": Vector3(30.0, 0.0, 0.0), &"Fore_FR": Vector3(-50.0, 0.0, 0.0), &"Thigh_HR": Vector3(10.0, 0.0, 0.0)}, Vector3(0.0, 0.02, 0.06))],
		[42, _p({&"Spine": Vector3(-4.0, 0.0, 0.0), &"Neck": Vector3(-12.0, 0.0, -26.0), &"Head": Vector3(-26.0, 0.0, -16.0), &"Upper_FR": Vector3(10.0, 0.0, 0.0)},
			Vector3(0.0, -0.03, -0.1))],
		[48, _p({&"Neck": Vector3(-6.0, 0.0, -14.0), &"Head": Vector3(-12.0, 0.0, -8.0)}, Vector3(0.0, -0.02, -0.06))],
		[64, _p({})],
	], false, 34, 44)])
	list.append([&"roar", _clip(70, [
		[0, _p({})],
		[16, _p({&"Neck": Vector3(26.0, 0.0, 0.0), &"Head": Vector3(22.0, 0.0, 0.0), &"Jaw": Vector3(-36.0, 0.0, 0.0), &"Chest": Vector3(6.0, 0.0, 0.0),
			&"Ear_R": Vector3(30.0, 0.0, 0.0), &"Tail_1": Vector3(-20.0, 0.0, 0.0)}, Vector3(0.0, 0.02, 0.04))],
		[54, _p({&"Neck": Vector3(28.0, 0.0, 4.0), &"Head": Vector3(24.0, 0.0, -4.0), &"Jaw": Vector3(-38.0, 0.0, 0.0), &"Chest": Vector3(7.0, 0.0, 0.0),
			&"Ear_R": Vector3(32.0, 0.0, 0.0), &"Tail_1": Vector3(-22.0, 0.0, 0.0)}, Vector3(0.0, 0.02, 0.04))],
		[70, _p({})],
	])])
	list.append([&"hit", _clip(16, [[0, _p({})], [4, _p({&"Neck": Vector3(14.0, 0.0, 8.0), &"Head": Vector3(10.0, 0.0, 0.0), &"Spine": Vector3(-4.0, 0.0, 0.0),
		&"Ear_R": Vector3(30.0, 0.0, 0.0)}, Vector3(0.0, 0.0, 0.05))], [16, _p({})]])])
	list.append([&"stagger", _clip(48, _sampled(48, 4, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return _p({&"Spine": Vector3(0.0, sway * 6.0, sway * 6.0), &"Neck": Vector3(-10.0, 0.0, -sway * 16.0), &"Head": Vector3(-6.0, 0.0, -sway * 10.0),
			&"Upper_FR": Vector3(sway * 10.0, 0.0, -6.0), &"Thigh_HR": Vector3(-sway * 8.0, 0.0, -6.0), &"Ear_R": Vector3(28.0, 0.0, 0.0),
			&"Jaw": Vector3(-10.0, 0.0, 0.0)}, Vector3(sway * 0.02, -0.03, 0.0))), true)])
	# Its posture broken: down on its forelegs, head low, swaying.
	list.append([&"kneel", _clip(60, _sampled(60, 6, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return _p({&"Spine": Vector3(-10.0, 0.0, sway * 3.0), &"Chest": Vector3(-8.0, 0.0, 0.0), &"Upper_FR": Vector3(48.0, 0.0, 0.0), &"Fore_FR": Vector3(-92.0, 0.0, 0.0),
			&"Paw_FR": Vector3(-40.0, 0.0, 0.0), &"Thigh_HR": Vector3(14.0, 0.0, 0.0), &"Shank_HR": Vector3(-20.0, 0.0, 0.0), &"Hock_HR": Vector3(14.0, 0.0, 0.0),
			&"Neck": Vector3(-26.0, 0.0, sway * 8.0), &"Head": Vector3(-14.0, 0.0, sway * 6.0), &"Jaw": Vector3(-8.0, 0.0, 0.0),
			&"Ear_R": Vector3(34.0, 0.0, 0.0), &"Tail_1": Vector3(26.0, 0.0, 0.0)}, Vector3(0.0, -0.17, 0.03))), true)])
	# Worn down: trembling, head low, ears flat, tail tucked; it waits for a gentle hand.
	list.append([&"waver", _clip(48, _sampled(48, 3, func(p: float) -> Dictionary:
		var shake: float = _shiver(p * 48.0, 1.7)
		return _p({&"Spine": Vector3(-3.0, 0.0, shake * 2.0), &"Neck": Vector3(-22.0, 0.0, shake * 3.0), &"Head": Vector3(-12.0, 0.0, shake * 2.0),
			&"Ear_R": Vector3(40.0, 0.0, 6.0), &"Tail_1": Vector3(38.0, 0.0, 0.0), &"Tail_2": Vector3(20.0, 0.0, 0.0), &"Thigh_HR": Vector3(10.0, 0.0, 0.0),
			&"Shank_HR": Vector3(-14.0, 0.0, 0.0), &"Upper_FR": Vector3(4.0, 0.0, 0.0)}, Vector3(0.0, -0.04, 0.0))), true)])
	# Scattered: the legs go and it sinks down.
	list.append([&"collapse", _clip(36, [
		[0, _p({})],
		[14, _p({&"Upper_FR": Vector3(40.0, 0.0, -10.0), &"Fore_FR": Vector3(-70.0, 0.0, 0.0), &"Thigh_HR": Vector3(-30.0, 0.0, -10.0), &"Shank_HR": Vector3(30.0, 0.0, 0.0),
			&"Neck": Vector3(-20.0, 0.0, 10.0), &"Head": Vector3(-10.0, 0.0, 0.0), &"Spine": Vector3(0.0, 0.0, 10.0)}, Vector3(0.0, -0.18, 0.0))],
		[36, _p({&"Upper_FR": Vector3(60.0, 0.0, -24.0), &"Fore_FR": Vector3(-100.0, 0.0, 0.0), &"Thigh_HR": Vector3(-50.0, 0.0, -24.0), &"Shank_HR": Vector3(50.0, 0.0, 0.0),
			&"Neck": Vector3(-34.0, 0.0, 16.0), &"Head": Vector3(-14.0, 0.0, 8.0), &"Spine": Vector3(0.0, 0.0, 14.0), &"Tail_1": Vector3(30.0, 0.0, 0.0),
			&"Ear_R": Vector3(40.0, 0.0, 0.0), &"Jaw": Vector3(-6.0, 0.0, 0.0)}, Vector3(0.0, -0.36, 0.0))],
	], false, 0, 0, true)])
	# Calmed (docs/28 §3.5): it freezes, shakes like a wet dog, wags once, and stands easy.
	var calmed_keys: Array = [[0, _p({&"Neck": Vector3(-20.0, 0.0, 0.0), &"Head": Vector3(-10.0, 0.0, 0.0)}, Vector3(0.0, -0.04, 0.0))],
		[12, _p({&"Neck": Vector3(-6.0, 0.0, 0.0), &"Head": Vector3(0.0, 0.0, 0.0)})]]
	for index: int in 8:
		var side: float = 1.0 if index % 2 == 0 else -1.0
		calmed_keys.append([16 + index * 4, _p({&"Chest": Vector3(0.0, side * 10.0, side * 14.0), &"Spine": Vector3(0.0, -side * 8.0, -side * 10.0),
			&"Neck": Vector3(4.0, 0.0, side * 18.0), &"Head": Vector3(0.0, side * 10.0, side * 14.0), &"Ear_R": Vector3(-side * 30.0, 0.0, 20.0),
			&"Ear_L": Vector3(side * 30.0, 0.0, -20.0), &"Tail_1": Vector3(-20.0, 0.0, -side * 20.0)})])
	calmed_keys.append([52, _p({&"Neck": Vector3(10.0, 0.0, 0.0), &"Head": Vector3(6.0, 0.0, 0.0), &"Tail_1": Vector3(-28.0, 0.0, 30.0)})])
	calmed_keys.append([60, _p({&"Neck": Vector3(10.0, 0.0, 0.0), &"Head": Vector3(6.0, 0.0, 0.0), &"Tail_1": Vector3(-28.0, 0.0, -30.0)})])
	calmed_keys.append([68, _p({&"Neck": Vector3(10.0, 0.0, 0.0), &"Head": Vector3(6.0, 0.0, 0.0), &"Tail_1": Vector3(-28.0, 0.0, 26.0)})])
	calmed_keys.append([84, _p({&"Neck": Vector3(8.0, 0.0, 0.0), &"Head": Vector3(4.0, 0.0, 0.0), &"Tail_1": Vector3(-14.0, 0.0, 0.0)})])
	list.append([&"calmed", _clip(84, calmed_keys, false, 0, 0, true)])
	list.append([&"happy", _clip(30, _sampled(30, 3, func(p: float) -> Dictionary:
		return _p({&"Neck": Vector3(12.0, 0.0, sin(p * TAU) * 10.0), &"Head": Vector3(8.0, 0.0, 0.0), &"Tail_1": Vector3(-30.0, 0.0, sin(p * TAU * 2.0) * 34.0),
			&"Tail_2": Vector3(-10.0, 0.0, sin(p * TAU * 2.0 - 0.8) * 20.0), &"Ear_R": Vector3(-10.0, 0.0, 0.0), &"Jaw": Vector3(-14.0, 0.0, 0.0),
			&"Upper_FR": Vector3(sin(p * TAU) * 16.0, 0.0, 0.0)}, Vector3(0.0, absf(sin(p * TAU)) * 0.04, 0.0))), true)])
	return list


# --- Six legs ------------------------------------------------------------------------

static func _hex_gait(q: float, reach: float, lift: float, bob: float) -> Dictionary:
	var w: Dictionary = {}
	var e: Dictionary = {}
	for pair: int in [1, 2, 3]:
		for side: float in [-1.0, 1.0]:
			var tag: String = ("L%d" if side < 0.0 else "R%d") % pair
			# The tripods: L1, R2, L3 together, then R1, L2, R3.
			var tripod: float = 0.0 if (pair % 2 == 1) == (side < 0.0) else 0.5
			var s: Vector2 = _stride(q + tripod, 0.42)
			w[StringName("Coxa_" + tag)] = Vector3(0.0, s.x * reach * side, s.y * lift * side)
			e[StringName("Tibia_" + tag)] = Vector3(-s.y * lift * 0.6, 0.0, 0.0)
	e[&"Head"] = Vector3(sin(q * TAU * 2.0) * 2.0, 0.0, sin(q * TAU) * 3.0)
	e[&"Antenna_R"] = Vector3(sin(q * TAU * 2.0) * 8.0, 0.0, 0.0)
	e[&"Antenna_L"] = Vector3(sin(q * TAU * 2.0 + 1.0) * 8.0, 0.0, 0.0)
	e[&"Abdomen"] = Vector3(0.0, 0.0, sin(q * TAU) * 3.0)
	e[&"Tail_1"] = Vector3(0.0, 0.0, sin(q * TAU) * 6.0)
	return {"e": e, "w": w, "root": Vector3(sin(q * TAU) * 0.004, absf(sin(q * TAU * 2.0)) * bob, 0.0), "scale": Vector3.ONE}


static func _hexapod() -> Array:
	var list: Array = []
	list.append([&"idle", _clip(150, _sampled(150, 10, func(p: float) -> Dictionary:
		var breath: float = sin(p * TAU * 3.0)
		var twitch: float = 20.0 * smoothstep(0.4, 0.43, p) * (1.0 - smoothstep(0.47, 0.5, p))
		return _p({&"Head": Vector3(breath * 2.0, 0.0, sin(p * TAU) * 8.0), &"Snout": Vector3(breath * 2.0, 0.0, 0.0),
			&"Antenna_R": Vector3(sin(p * TAU * 2.0) * 10.0 + twitch, 0.0, 0.0), &"Antenna_L": Vector3(sin(p * TAU * 2.0 + 1.3) * 10.0, 0.0, 0.0),
			&"Abdomen": Vector3(breath * 2.0, 0.0, 0.0), &"Tail_1": Vector3(breath * 3.0, 0.0, sin(p * TAU) * 6.0), &"Tail_2": Vector3(breath * 4.0, 0.0, 0.0),
			&"Tibia_R1": Vector3(sin(p * TAU) * 3.0, 0.0, 0.0)}, Vector3(0.0, breath * 0.003, 0.0),
			{&"Coxa_R1": Vector3(0.0, 0.0, 6.0 + breath * 2.0)})), true)])
	list.append([&"walk", _clip(32, _sampled(32, 2, func(p: float) -> Dictionary: return _hex_gait(p, 18.0, 16.0, 0.006)), true)])
	list.append([&"run", _clip(18, _sampled(18, 2, func(p: float) -> Dictionary: return _hex_gait(p, 24.0, 20.0, 0.01)), true)])
	# A weevil's jab: reared up on its back legs, snout high, then down hard.
	list.append([&"attack_jab", _clip(46, [
		[0, _p({})],
		[24, _p({&"Body": Vector3(18.0, 0.0, 0.0), &"Head": Vector3(26.0, 0.0, 0.0), &"Snout": Vector3(10.0, 0.0, 0.0), &"Antenna_R": Vector3(-20.0, 0.0, 0.0)},
			Vector3(0.0, 0.03, 0.05), {&"Coxa_R1": Vector3(0.0, -10.0, 22.0)})],
		[29, _p({&"Body": Vector3(-8.0, 0.0, 0.0), &"Head": Vector3(-30.0, 0.0, 0.0), &"Snout": Vector3(-14.0, 0.0, 0.0)}, Vector3(0.0, -0.02, -0.08))],
		[34, _p({&"Body": Vector3(-4.0, 0.0, 0.0), &"Head": Vector3(-16.0, 0.0, 0.0)}, Vector3(0.0, -0.01, -0.06))],
		[46, _p({})],
	], false, 24, 30)])
	# A scuttler's snip: both claws raised and opened wide, then snapped shut ahead.
	list.append([&"attack_snip", _clip(46, [
		[0, _p({}, Vector3.ZERO, {&"Coxa_R1": Vector3(0.0, 0.0, 8.0)})],
		[24, _p({&"Tibia_R1": Vector3(30.0, 0.0, 0.0), &"Foot_R1": Vector3(26.0, 0.0, 0.0), &"Body": Vector3(8.0, 0.0, 0.0)}, Vector3(0.0, 0.02, 0.04),
			{&"Coxa_R1": Vector3(0.0, 18.0, 36.0)})],
		[29, _p({&"Tibia_R1": Vector3(-16.0, 0.0, 0.0), &"Foot_R1": Vector3(-20.0, 0.0, 0.0), &"Body": Vector3(-6.0, 0.0, 0.0)}, Vector3(0.0, -0.01, -0.08),
			{&"Coxa_R1": Vector3(0.0, -24.0, -4.0)})],
		[34, _p({&"Foot_R1": Vector3(-10.0, 0.0, 0.0)}, Vector3(0.0, 0.0, -0.05), {&"Coxa_R1": Vector3(0.0, -16.0, 0.0)})],
		[46, _p({}, Vector3.ZERO, {&"Coxa_R1": Vector3(0.0, 0.0, 8.0)})],
	], false, 24, 30)])
	# A thorn-tail's sting: the tail drawn right back, then whipped over its head.
	list.append([&"attack_tail", _clip(46, [
		[0, _p({})],
		[24, _p({&"Tail_1": Vector3(28.0, 0.0, 0.0), &"Tail_2": Vector3(30.0, 0.0, 0.0), &"Body": Vector3(-6.0, 0.0, 0.0), &"Head": Vector3(-8.0, 0.0, 0.0)},
			Vector3(0.0, -0.02, 0.03))],
		[29, _p({&"Tail_1": Vector3(-40.0, 0.0, 0.0), &"Tail_2": Vector3(-46.0, 0.0, 0.0), &"Body": Vector3(6.0, 0.0, 0.0), &"Head": Vector3(-12.0, 0.0, 0.0)},
			Vector3(0.0, 0.0, -0.06))],
		[34, _p({&"Tail_1": Vector3(-30.0, 0.0, 0.0), &"Tail_2": Vector3(-30.0, 0.0, 0.0)}, Vector3(0.0, 0.0, -0.04))],
		[46, _p({})],
	], false, 24, 30)])
	list.append([&"gnaw", _clip(24, _sampled(24, 3, func(p: float) -> Dictionary:
		var bite: float = absf(sin(p * TAU * 2.0))
		return _p({&"Head": Vector3(-14.0 - bite * 14.0, 0.0, sin(p * TAU) * 6.0), &"Snout": Vector3(-6.0 - bite * 8.0, 0.0, 0.0), &"Body": Vector3(-4.0, 0.0, 0.0),
			&"Antenna_R": Vector3(-10.0 + bite * 12.0, 0.0, 0.0)}, Vector3(0.0, -0.01, -0.02 * bite))), true)])
	list.append([&"roar", _clip(60, [[0, _p({})], [16, _p({&"Body": Vector3(16.0, 0.0, 0.0), &"Head": Vector3(24.0, 0.0, 0.0), &"Antenna_R": Vector3(-30.0, 0.0, 0.0)},
		Vector3.ZERO, {&"Coxa_R1": Vector3(0.0, 10.0, 30.0)})], [44, _p({&"Body": Vector3(16.0, 0.0, 0.0), &"Head": Vector3(26.0, 0.0, 0.0)}, Vector3.ZERO,
		{&"Coxa_R1": Vector3(0.0, 12.0, 32.0)})], [60, _p({})]])])
	list.append([&"hit", _clip(14, [[0, _p({})], [4, _p({&"Body": Vector3(-8.0, 0.0, 6.0), &"Head": Vector3(16.0, 0.0, 0.0), &"Antenna_R": Vector3(-24.0, 0.0, 0.0)},
		Vector3(0.0, 0.01, 0.04))], [14, _p({})]])])
	list.append([&"stagger", _clip(40, _sampled(40, 4, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return _p({&"Body": Vector3(0.0, sway * 8.0, sway * 10.0), &"Head": Vector3(-10.0, 0.0, -sway * 14.0), &"Antenna_R": Vector3(-20.0, 0.0, 10.0)},
			Vector3(sway * 0.015, -0.02, 0.0), {&"Coxa_R2": Vector3(0.0, 0.0, -sway * 10.0)})), true)])
	# Its posture broken: legs splayed out flat, body down on the ground.
	list.append([&"kneel", _clip(60, _sampled(60, 6, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return _p({&"Head": Vector3(-18.0, 0.0, sway * 6.0), &"Antenna_R": Vector3(-30.0, 0.0, 10.0), &"Tibia_R1": Vector3(20.0, 0.0, 0.0), &"Tibia_R2": Vector3(20.0, 0.0, 0.0),
			&"Tibia_R3": Vector3(20.0, 0.0, 0.0), &"Body": Vector3(0.0, 0.0, sway * 3.0)}, Vector3(0.0, -0.1, 0.0),
			{&"Coxa_R1": Vector3(0.0, 0.0, 22.0), &"Coxa_R2": Vector3(0.0, 0.0, 24.0), &"Coxa_R3": Vector3(0.0, 0.0, 22.0)})), true)])
	list.append([&"waver", _clip(42, _sampled(42, 3, func(p: float) -> Dictionary:
		var shake: float = _shiver(p * 42.0, 1.9)
		return _p({&"Head": Vector3(-16.0, 0.0, shake * 4.0), &"Antenna_R": Vector3(-34.0, 0.0, 8.0), &"Body": Vector3(-3.0, 0.0, shake * 3.0),
			&"Tail_1": Vector3(14.0, 0.0, 0.0)}, Vector3(0.0, -0.03, 0.0), {&"Coxa_R2": Vector3(0.0, 0.0, 8.0)})), true)])
	list.append([&"collapse", _clip(32, [[0, _p({})], [32, _p({&"Head": Vector3(-24.0, 0.0, 10.0), &"Antenna_R": Vector3(-40.0, 0.0, 20.0),
		&"Tibia_R1": Vector3(50.0, 0.0, 0.0), &"Tibia_R2": Vector3(50.0, 0.0, 0.0), &"Tibia_R3": Vector3(50.0, 0.0, 0.0), &"Body": Vector3(0.0, 0.0, 12.0)},
		Vector3(0.0, -0.16, 0.0), {&"Coxa_R1": Vector3(0.0, 0.0, 34.0), &"Coxa_R2": Vector3(0.0, 0.0, 36.0), &"Coxa_R3": Vector3(0.0, 0.0, 34.0)})]], false, 0, 0, true)])
	var calmed_keys: Array = [[0, _p({&"Head": Vector3(-16.0, 0.0, 0.0)}, Vector3(0.0, -0.03, 0.0))], [10, _p({})]]
	for index: int in 6:
		var side: float = 1.0 if index % 2 == 0 else -1.0
		calmed_keys.append([14 + index * 4, _p({&"Body": Vector3(0.0, side * 10.0, side * 10.0), &"Head": Vector3(10.0, side * 12.0, 0.0),
			&"Antenna_R": Vector3(side * 26.0, 0.0, 0.0), &"Antenna_L": Vector3(-side * 26.0, 0.0, 0.0)})])
	calmed_keys.append([50, _p({&"Head": Vector3(12.0, 0.0, 0.0), &"Antenna_R": Vector3(16.0, 0.0, 0.0)})])
	calmed_keys.append([70, _p({&"Head": Vector3(6.0, 0.0, 0.0)})])
	list.append([&"calmed", _clip(70, calmed_keys, false, 0, 0, true)])
	list.append([&"happy", _clip(28, _sampled(28, 2, func(p: float) -> Dictionary:
		var pose: Dictionary = _hex_gait(p, 10.0, 22.0, 0.02)
		pose["e"][&"Head"] = Vector3(16.0, 0.0, sin(p * TAU) * 12.0)
		return pose), true)])
	return list


# --- Two legs (the heroes' skeleton) ------------------------------------------------

static func _biped_gait(q: float, reach: float, flex: float, arm: float, bob: float, lean: float) -> Dictionary:
	var e: Dictionary = {}
	var left: Vector2 = _stride(q, 0.42)
	var right: Vector2 = _stride(q + 0.5, 0.42)
	e[&"Thigh_L"] = Vector3(left.x * reach, 0.0, 0.0)
	e[&"Shin_L"] = Vector3(-left.y * flex - maxf(0.0, -left.x) * 8.0, 0.0, 0.0)
	e[&"Foot_L"] = Vector3(left.y * flex * 0.35 - left.x * 6.0, 0.0, 0.0)
	e[&"Thigh_R"] = Vector3(right.x * reach, 0.0, 0.0)
	e[&"Shin_R"] = Vector3(-right.y * flex - maxf(0.0, -right.x) * 8.0, 0.0, 0.0)
	e[&"Foot_R"] = Vector3(right.y * flex * 0.35 - right.x * 6.0, 0.0, 0.0)
	e[&"UpperArm_R"] = Vector3(-right.x * arm, 0.0, -6.0)
	e[&"UpperArm_L"] = Vector3(-left.x * arm, 0.0, 6.0)
	e[&"Forearm_R"] = Vector3(14.0 + maxf(0.0, -right.x) * arm * 0.5, 0.0, 0.0)
	e[&"Forearm_L"] = Vector3(14.0 + maxf(0.0, -left.x) * arm * 0.5, 0.0, 0.0)
	e[&"Spine"] = Vector3(-lean, sin(q * TAU) * 5.0, 0.0)
	e[&"Chest"] = Vector3(0.0, -sin(q * TAU) * 7.0, 0.0)
	e[&"Head"] = Vector3(lean * 0.6, sin(q * TAU) * 3.0, 0.0)
	e[&"Cloak_01"] = Vector3(10.0, 0.0, sin(q * TAU) * 6.0)
	e[&"Cloak_02"] = Vector3(8.0, 0.0, sin(q * TAU - 0.6) * 8.0)
	e[&"Cloak_03"] = Vector3(6.0, 0.0, sin(q * TAU - 1.2) * 10.0)
	return {"e": e, "w": {}, "root": Vector3(0.0, -absf(cos(q * TAU)) * bob, 0.0), "scale": Vector3.ONE}


static func _biped() -> Array:
	var list: Array = []
	list.append([&"idle", _clip(180, _sampled(180, 10, func(p: float) -> Dictionary:
		var breath: float = sin(p * TAU * 3.0)
		var glance: float = sin(p * TAU) * 12.0
		return _p({&"Spine": Vector3(breath * 1.0, 0.0, 0.0), &"Chest": Vector3(breath * 1.5, 0.0, 0.0), &"Neck": Vector3(0.0, glance * 0.4, 0.0),
			&"Head": Vector3(-2.0, glance * 0.6, 0.0), &"UpperArm_R": Vector3(4.0, 0.0, -6.0 - breath), &"Forearm_R": Vector3(12.0, 0.0, 0.0),
			&"Thigh_R": Vector3(2.0, 0.0, -2.0), &"Shin_R": Vector3(-4.0, 0.0, 0.0), &"Cloak_01": Vector3(4.0, 0.0, sin(p * TAU * 2.0) * 3.0),
			&"Cloak_02": Vector3(2.0, 0.0, sin(p * TAU * 2.0 - 0.6) * 4.0), &"Cloak_03": Vector3(0.0, 0.0, sin(p * TAU * 2.0 - 1.2) * 5.0)},
			Vector3(0.0, breath * 0.004, 0.0))), true)])
	# The Ash-Grig's crouch, the Bog-Hulk's hunch, the Tide-Wight's float.
	list.append([&"idle_crouch", _clip(120, _sampled(120, 8, func(p: float) -> Dictionary:
		var breath: float = sin(p * TAU * 3.0)
		var glance: float = sin(p * TAU) * 16.0 + sin(p * TAU * 3.0) * 4.0
		return _p({&"Thigh_R": Vector3(46.0, 0.0, -10.0), &"Shin_R": Vector3(-82.0, 0.0, 0.0), &"Foot_R": Vector3(34.0, 0.0, 0.0),
			&"Spine": Vector3(-16.0 + breath * 2.0, 0.0, 0.0), &"Chest": Vector3(-6.0, 0.0, 0.0), &"Head": Vector3(18.0, glance, sin(p * TAU * 2.0) * 6.0),
			&"UpperArm_R": Vector3(24.0, 0.0, -14.0), &"Forearm_R": Vector3(40.0, 0.0, 0.0), &"Hand_R": Vector3(10.0, 0.0, 0.0),
			&"Cloak_02": Vector3(-30.0, 0.0, sin(p * TAU * 2.0) * 20.0), &"Cloak_03": Vector3(-20.0, 0.0, sin(p * TAU * 2.0 - 1.0) * 26.0)},
			Vector3(0.0, -0.24, 0.04))), true)])
	list.append([&"idle_hunch", _clip(150, _sampled(150, 10, func(p: float) -> Dictionary:
		var breath: float = sin(p * TAU * 2.0)
		return _p({&"Spine": Vector3(-16.0 + breath * 2.0, 0.0, 0.0), &"Chest": Vector3(-12.0 + breath * 2.5, 0.0, 0.0), &"Neck": Vector3(14.0, sin(p * TAU) * 8.0, 0.0),
			&"Head": Vector3(14.0, sin(p * TAU) * 10.0, 0.0), &"Clavicle_R": Vector3(8.0, 0.0, 0.0), &"UpperArm_R": Vector3(16.0, 0.0, -8.0),
			&"Forearm_R": Vector3(10.0 + breath * 2.0, 0.0, 0.0), &"Thigh_R": Vector3(16.0, 0.0, -6.0), &"Shin_R": Vector3(-28.0, 0.0, 0.0), &"Foot_R": Vector3(12.0, 0.0, 0.0)},
			Vector3(0.0, -0.07 + breath * 0.006, 0.0))), true)])
	list.append([&"idle_float", _clip(160, _sampled(160, 8, func(p: float) -> Dictionary:
		var bob: float = sin(p * TAU * 2.0)
		return _p({&"Spine": Vector3(-4.0, 0.0, 0.0), &"Head": Vector3(-6.0, sin(p * TAU) * 14.0, 0.0), &"UpperArm_R": Vector3(22.0 + bob * 4.0, 0.0, -10.0),
			&"Forearm_R": Vector3(30.0, 0.0, 0.0), &"Hand_R": Vector3(20.0, 0.0, 0.0), &"Thigh_R": Vector3(10.0, 0.0, 0.0), &"Shin_R": Vector3(-20.0, 0.0, 0.0),
			&"Cloak_01": Vector3(6.0, 0.0, sin(p * TAU * 2.0) * 4.0), &"Cloak_02": Vector3(10.0, 0.0, sin(p * TAU * 2.0 - 0.7) * 6.0),
			&"Cloak_03": Vector3(12.0, 0.0, sin(p * TAU * 2.0 - 1.4) * 8.0)}, Vector3(0.0, 0.07 + bob * 0.035, 0.0))), true)])
	list.append([&"walk", _clip(WALK_FRAMES, _sampled(WALK_FRAMES, 4, func(p: float) -> Dictionary:
		return _biped_gait(p, 24.0, 44.0, 18.0, 0.02, 3.0)), true)])
	list.append([&"run", _clip(RUN_FRAMES, _sampled(RUN_FRAMES, 2, func(p: float) -> Dictionary:
		return _biped_gait(p, 36.0, 70.0, 30.0, 0.04, 10.0)), true)])
	list.append([&"walk_crouch", _clip(30, _sampled(30, 2, func(p: float) -> Dictionary:
		var pose: Dictionary = _biped_gait(p, 30.0, 50.0, 24.0, 0.03, 18.0)
		for side: String in ["_L", "_R"]:
			pose["e"][StringName("Thigh" + side)] += Vector3(40.0, 0.0, 0.0)
			pose["e"][StringName("Shin" + side)] += Vector3(-70.0, 0.0, 0.0)
			pose["e"][StringName("Foot" + side)] += Vector3(28.0, 0.0, 0.0)
		pose["e"][&"Head"] = Vector3(24.0, 0.0, 0.0)
		pose["e"][&"Cloak_02"] = Vector3(-34.0, 0.0, sin(p * TAU) * 22.0)
		pose["root"] = Vector3(0.0, -0.22 - absf(cos(p * TAU)) * 0.03, 0.0)
		return pose), true)])
	list.append([&"walk_float", _clip(60, _sampled(60, 6, func(p: float) -> Dictionary:
		var bob: float = sin(p * TAU)
		return _p({&"Spine": Vector3(-10.0, bob * 3.0, 0.0), &"Head": Vector3(4.0, 0.0, 0.0), &"UpperArm_R": Vector3(-10.0, 0.0, -14.0), &"Forearm_R": Vector3(20.0, 0.0, 0.0),
			&"Thigh_R": Vector3(-14.0, 0.0, 0.0), &"Shin_R": Vector3(-24.0, 0.0, 0.0), &"Cloak_01": Vector3(16.0, 0.0, bob * 5.0),
			&"Cloak_02": Vector3(22.0, 0.0, sin(p * TAU - 0.7) * 8.0), &"Cloak_03": Vector3(26.0, 0.0, sin(p * TAU - 1.4) * 10.0)},
			Vector3(0.0, 0.08 + bob * 0.03, 0.0))), true)])
	# An overhand throw (an Ash-Grig's cinder, a Clod-Flinger's clod).
	list.append([&"attack_throw", _clip(48, [
		[0, _p({})],
		[26, _p({&"UpperArm_R": Vector3(-30.0, 0.0, -70.0), &"Forearm_R": Vector3(100.0, 0.0, 0.0), &"Hand_R": Vector3(30.0, 0.0, 0.0), &"Spine": Vector3(6.0, -24.0, 0.0),
			&"Chest": Vector3(4.0, -12.0, 0.0), &"UpperArm_L": Vector3(40.0, 0.0, 20.0), &"Head": Vector3(0.0, 20.0, 0.0), &"Thigh_L": Vector3(20.0, 0.0, 0.0),
			&"Shin_L": Vector3(-20.0, 0.0, 0.0)}, Vector3(0.0, -0.03, 0.04))],
		[31, _p({&"UpperArm_R": Vector3(120.0, 0.0, -20.0), &"Forearm_R": Vector3(10.0, 0.0, 0.0), &"Hand_R": Vector3(-20.0, 0.0, 0.0), &"Spine": Vector3(-14.0, 20.0, 0.0),
			&"Chest": Vector3(-6.0, 10.0, 0.0), &"UpperArm_L": Vector3(-20.0, 0.0, 10.0), &"Head": Vector3(6.0, -10.0, 0.0), &"Thigh_R": Vector3(-10.0, 0.0, 0.0)},
			Vector3(0.0, -0.02, -0.06))],
		[36, _p({&"UpperArm_R": Vector3(70.0, 0.0, -10.0), &"Forearm_R": Vector3(10.0, 0.0, 0.0), &"Spine": Vector3(-10.0, 12.0, 0.0)}, Vector3(0.0, -0.01, -0.04))],
		[48, _p({})],
	], false, 26, 32)])
	# A two-fisted slam (an Iron-Man's, a Bog-Hulk's, a Spriggan's).
	list.append([&"attack_slam", _clip(60, [
		[0, _p({})],
		[32, _p({&"UpperArm_R": Vector3(160.0, 0.0, 14.0), &"Forearm_R": Vector3(50.0, 0.0, 0.0), &"Spine": Vector3(14.0, 0.0, 0.0), &"Chest": Vector3(10.0, 0.0, 0.0),
			&"Head": Vector3(-10.0, 0.0, 0.0), &"Thigh_R": Vector3(10.0, 0.0, 0.0), &"Shin_R": Vector3(-14.0, 0.0, 0.0)}, Vector3(0.0, 0.02, 0.06))],
		[38, _p({&"UpperArm_R": Vector3(60.0, 0.0, 10.0), &"Forearm_R": Vector3(10.0, 0.0, 0.0), &"Spine": Vector3(-24.0, 0.0, 0.0), &"Chest": Vector3(-16.0, 0.0, 0.0),
			&"Head": Vector3(18.0, 0.0, 0.0), &"Thigh_R": Vector3(30.0, 0.0, 0.0), &"Shin_R": Vector3(-46.0, 0.0, 0.0), &"Foot_R": Vector3(14.0, 0.0, 0.0)},
			Vector3(0.0, -0.14, -0.08))],
		[46, _p({&"UpperArm_R": Vector3(54.0, 0.0, 10.0), &"Forearm_R": Vector3(14.0, 0.0, 0.0), &"Spine": Vector3(-20.0, 0.0, 0.0), &"Chest": Vector3(-12.0, 0.0, 0.0),
			&"Head": Vector3(14.0, 0.0, 0.0), &"Thigh_R": Vector3(26.0, 0.0, 0.0), &"Shin_R": Vector3(-40.0, 0.0, 0.0), &"Foot_R": Vector3(12.0, 0.0, 0.0)},
			Vector3(0.0, -0.12, -0.07))],
		[60, _p({})],
	], false, 32, 40)])
	# A cold sweep of the arm across (a Tide-Wight's).
	list.append([&"attack_sweep", _clip(52, [
		[0, _p({})],
		[28, _p({&"UpperArm_R": Vector3(70.0, 0.0, -70.0), &"Forearm_R": Vector3(20.0, 0.0, 0.0), &"Spine": Vector3(4.0, -30.0, 0.0), &"Chest": Vector3(0.0, -16.0, 0.0),
			&"Head": Vector3(0.0, 24.0, 0.0), &"UpperArm_L": Vector3(30.0, 0.0, 14.0)}, Vector3(0.0, 0.0, 0.04))],
		[34, _p({&"UpperArm_R": Vector3(80.0, 0.0, 50.0), &"Forearm_R": Vector3(10.0, 0.0, 0.0), &"Spine": Vector3(-8.0, 30.0, 0.0), &"Chest": Vector3(-4.0, 18.0, 0.0),
			&"Head": Vector3(0.0, -18.0, 0.0), &"UpperArm_L": Vector3(-10.0, 0.0, 30.0)}, Vector3(0.0, -0.02, -0.06))],
		[40, _p({&"UpperArm_R": Vector3(60.0, 0.0, 40.0), &"Spine": Vector3(-6.0, 22.0, 0.0)}, Vector3(0.0, -0.01, -0.04))],
		[52, _p({})],
	], false, 28, 34)])
	list.append([&"roar", _clip(70, [[0, _p({})], [18, _p({&"UpperArm_R": Vector3(30.0, 0.0, -80.0), &"Forearm_R": Vector3(30.0, 0.0, 0.0), &"Spine": Vector3(14.0, 0.0, 0.0),
		&"Chest": Vector3(10.0, 0.0, 0.0), &"Head": Vector3(26.0, 0.0, 0.0), &"Jaw_Beard": Vector3(-20.0, 0.0, 0.0)}, Vector3(0.0, 0.02, 0.0))],
		[52, _p({&"UpperArm_R": Vector3(34.0, 0.0, -84.0), &"Forearm_R": Vector3(34.0, 0.0, 0.0), &"Spine": Vector3(15.0, 0.0, 0.0), &"Chest": Vector3(11.0, 0.0, 0.0),
		&"Head": Vector3(28.0, 0.0, 0.0), &"Jaw_Beard": Vector3(-22.0, 0.0, 0.0)}, Vector3(0.0, 0.02, 0.0))], [70, _p({})]])])
	list.append([&"hit", _clip(16, [[0, _p({})], [4, _p({&"Spine": Vector3(12.0, 0.0, 4.0), &"Chest": Vector3(8.0, 0.0, 0.0), &"Head": Vector3(14.0, 0.0, -6.0),
		&"UpperArm_R": Vector3(-14.0, 0.0, -14.0)}, Vector3(0.0, 0.0, 0.05))], [16, _p({})]])])
	list.append([&"stagger", _clip(48, _sampled(48, 4, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return _p({&"Spine": Vector3(6.0, 0.0, sway * 10.0), &"Chest": Vector3(4.0, 0.0, sway * 6.0), &"Head": Vector3(-10.0, 0.0, -sway * 14.0),
			&"UpperArm_R": Vector3(10.0, 0.0, -20.0 - sway * 10.0), &"Thigh_R": Vector3(sway * 10.0, 0.0, -4.0), &"Shin_R": Vector3(-14.0, 0.0, 0.0)},
			Vector3(sway * 0.04, -0.04, 0.0))), true)])
	# Its posture broken: down on one knee, head bowed, swaying.
	list.append([&"kneel", _clip(60, _sampled(60, 6, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return {"e": {&"Thigh_R": Vector3(84.0, 0.0, -6.0), &"Shin_R": Vector3(-92.0, 0.0, 0.0), &"Foot_R": Vector3(20.0, 0.0, 0.0),
			&"Thigh_L": Vector3(-8.0, 0.0, 4.0), &"Shin_L": Vector3(-96.0, 0.0, 0.0), &"Foot_L": Vector3(-30.0, 0.0, 0.0),
			&"Spine": Vector3(-22.0, 0.0, sway * 4.0), &"Chest": Vector3(-10.0, 0.0, 0.0), &"Neck": Vector3(-10.0, 0.0, 0.0), &"Head": Vector3(-18.0, 0.0, sway * 8.0),
			&"UpperArm_R": Vector3(24.0, 0.0, -8.0), &"Forearm_R": Vector3(30.0, 0.0, 0.0), &"UpperArm_L": Vector3(14.0, 0.0, 10.0), &"Forearm_L": Vector3(10.0, 0.0, 0.0)},
			"w": {}, "root": Vector3(0.0, -0.42, 0.06), "scale": Vector3.ONE}), true)])
	list.append([&"waver", _clip(48, _sampled(48, 3, func(p: float) -> Dictionary:
		var shake: float = _shiver(p * 48.0, 1.6)
		return _p({&"Spine": Vector3(-12.0, 0.0, shake * 3.0), &"Chest": Vector3(-6.0, 0.0, 0.0), &"Head": Vector3(-20.0, 0.0, shake * 4.0),
			&"UpperArm_R": Vector3(6.0, 0.0, -4.0), &"Forearm_R": Vector3(6.0, 0.0, 0.0), &"Thigh_R": Vector3(12.0, 0.0, 0.0), &"Shin_R": Vector3(-22.0, 0.0, 0.0)},
			Vector3(shake * 0.01, -0.06, 0.0))), true)])
	list.append([&"collapse", _clip(40, [[0, _p({})],
		[16, _p({&"Thigh_R": Vector3(60.0, 0.0, -10.0), &"Shin_R": Vector3(-90.0, 0.0, 0.0), &"Spine": Vector3(-20.0, 0.0, 6.0), &"Head": Vector3(-16.0, 0.0, 0.0),
			&"UpperArm_R": Vector3(10.0, 0.0, -10.0)}, Vector3(0.0, -0.4, 0.0))],
		[40, _p({&"Thigh_R": Vector3(90.0, 0.0, -20.0), &"Shin_R": Vector3(-120.0, 0.0, 0.0), &"Spine": Vector3(-40.0, 0.0, 10.0), &"Chest": Vector3(-20.0, 0.0, 0.0),
			&"Head": Vector3(-24.0, 0.0, 10.0), &"UpperArm_R": Vector3(-6.0, 0.0, -16.0)}, Vector3(0.0, -0.7, 0.0))]], false, 0, 0, true)])
	list.append([&"calmed", _clip(80, [[0, _p({&"Head": Vector3(-16.0, 0.0, 0.0), &"Spine": Vector3(-10.0, 0.0, 0.0)}, Vector3(0.0, -0.05, 0.0))],
		[14, _p({&"Head": Vector3(10.0, 0.0, 0.0), &"Spine": Vector3(4.0, 0.0, 0.0)})],
		[20, _p({&"Head": Vector3(6.0, 20.0, 10.0)})], [26, _p({&"Head": Vector3(6.0, -20.0, -10.0)})], [32, _p({&"Head": Vector3(6.0, 16.0, 8.0)})],
		[38, _p({&"Head": Vector3(6.0, -10.0, 0.0)})],
		[56, _p({&"Spine": Vector3(-24.0, 0.0, 0.0), &"Neck": Vector3(-14.0, 0.0, 0.0), &"Head": Vector3(-14.0, 0.0, 0.0), &"UpperArm_R": Vector3(46.0, 0.0, 30.0),
			&"Forearm_R": Vector3(80.0, 0.0, 0.0)})],
		[80, _p({&"Spine": Vector3(-4.0, 0.0, 0.0), &"Head": Vector3(6.0, 0.0, 0.0)})]], false, 0, 0, true)])
	# A steward's bow: a hand to its chest, head down, standing easy.
	list.append([&"bow", _clip(120, _sampled(120, 10, func(p: float) -> Dictionary:
		var breath: float = sin(p * TAU * 2.0)
		return {"e": {&"Spine": Vector3(-24.0 + breath, 0.0, 0.0), &"Chest": Vector3(-8.0, 0.0, 0.0), &"Neck": Vector3(-12.0, 0.0, 0.0), &"Head": Vector3(-14.0, 0.0, 0.0),
			&"UpperArm_R": Vector3(44.0, 0.0, 26.0), &"Forearm_R": Vector3(86.0, 0.0, 0.0), &"Hand_R": Vector3(0.0, 0.0, 20.0),
			&"UpperArm_L": Vector3(4.0, 0.0, 6.0), &"Forearm_L": Vector3(10.0, 0.0, 0.0), &"Thigh_R": Vector3(-6.0, 0.0, 0.0), &"Thigh_L": Vector3(4.0, 0.0, 0.0)},
			"w": {}, "root": Vector3(0.0, -0.01, 0.02), "scale": Vector3.ONE}), true)])
	list.append([&"happy", _clip(36, _sampled(36, 3, func(p: float) -> Dictionary:
		var hop: float = absf(sin(p * TAU))
		return _p({&"UpperArm_R": Vector3(30.0 + hop * 60.0, 0.0, -40.0), &"Forearm_R": Vector3(40.0, 0.0, 0.0), &"Head": Vector3(10.0, sin(p * TAU) * 16.0, 0.0),
			&"Spine": Vector3(4.0, sin(p * TAU) * 10.0, 0.0), &"Thigh_R": Vector3(hop * 20.0, 0.0, 0.0), &"Shin_R": Vector3(-hop * 30.0, 0.0, 0.0)},
			Vector3(0.0, hop * 0.06, 0.0))), true)])
	return list


# --- Stalks ---------------------------------------------------------------------------

static func _stalk_wave(p: float, sway: float, lean: float) -> Dictionary:
	var e: Dictionary = {}
	for index: int in 5:
		e[StringName("Stalk_%d" % (index + 1))] = Vector3(lean + sin(p * TAU + index * 0.7) * sway * 0.6, 0.0, sin(p * TAU + index * 0.55) * sway)
	return e


static func _stalk() -> Array:
	var list: Array = []
	var idle: Callable = func(p: float) -> Dictionary:
		var e: Dictionary = _stalk_wave(p, 3.0, 0.0)
		e[&"Head"] = Vector3(sin(p * TAU * 2.0) * 4.0, 0.0, sin(p * TAU) * 10.0)
		var w: Dictionary = {&"Whip_R1": Vector3(0.0, sin(p * TAU) * 8.0, 6.0 + sin(p * TAU * 2.0) * 6.0),
			&"Whip_R2": Vector3(0.0, sin(p * TAU - 0.8) * 12.0, -10.0 + sin(p * TAU * 2.0 - 0.8) * 10.0),
			&"Whip_L1": Vector3(0.0, -sin(p * TAU + 1.0) * 8.0, -6.0 - sin(p * TAU * 2.0 + 1.0) * 6.0),
			&"Whip_L2": Vector3(0.0, -sin(p * TAU + 0.2) * 12.0, 10.0 - sin(p * TAU * 2.0 + 0.2) * 10.0)}
		return {"e": e, "w": w, "root": Vector3.ZERO, "scale": Vector3.ONE}
	list.append([&"idle", _clip(160, _sampled(160, 8, idle), true)])
	list.append([&"walk", _clip(60, _sampled(60, 6, func(p: float) -> Dictionary:
		var pose: Dictionary = idle.call(p)
		pose["e"] = _stalk_wave(p, 6.0, -3.0)
		return pose), true)])
	list.append([&"run", _clip(40, _sampled(40, 4, func(p: float) -> Dictionary:
		var pose: Dictionary = idle.call(p)
		pose["e"] = _stalk_wave(p, 8.0, -5.0)
		return pose), true)])
	# A lash: reared back with both whips raised, then thrown forward and cracked down.
	var reared: Dictionary = _stalk_wave(0.0, 0.0, 9.0)
	reared[&"Head"] = Vector3(14.0, 0.0, 0.0)
	var struck: Dictionary = _stalk_wave(0.0, 0.0, -14.0)
	struck[&"Head"] = Vector3(-20.0, 0.0, 0.0)
	list.append([&"attack_lash", _clip(52, [
		[0, {"e": {}, "w": {}, "root": Vector3.ZERO, "scale": Vector3.ONE}],
		[30, {"e": reared, "w": _mirrored({&"Whip_R1": Vector3(0.0, -30.0, 50.0), &"Whip_R2": Vector3(0.0, -20.0, 40.0)}), "root": Vector3(0.0, 0.02, 0.06),
			"scale": Vector3(0.96, 1.06, 0.96)}],
		[35, {"e": struck, "w": _mirrored({&"Whip_R1": Vector3(0.0, 40.0, -20.0), &"Whip_R2": Vector3(0.0, 40.0, -40.0)}), "root": Vector3(0.0, -0.02, -0.08),
			"scale": Vector3(1.04, 0.95, 1.04)}],
		[40, {"e": _stalk_wave(0.0, 0.0, -8.0), "w": _mirrored({&"Whip_R1": Vector3(0.0, 30.0, -10.0), &"Whip_R2": Vector3(0.0, 24.0, -24.0)}),
			"root": Vector3(0.0, 0.0, -0.05), "scale": Vector3.ONE}],
		[52, {"e": {}, "w": {}, "root": Vector3.ZERO, "scale": Vector3.ONE}],
	], false, 30, 36)])
	list.append([&"roar", _clip(60, [[0, _p({})], [16, {"e": reared, "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, 60.0), &"Whip_R2": Vector3(0.0, 0.0, 40.0)}),
		"root": Vector3.ZERO, "scale": Vector3(0.95, 1.08, 0.95)}], [44, {"e": reared, "w": _mirrored({&"Whip_R1": Vector3(0.0, 4.0, 62.0)}), "root": Vector3.ZERO,
		"scale": Vector3(0.95, 1.08, 0.95)}], [60, _p({})]])])
	list.append([&"hit", _clip(16, [[0, _p({})], [4, {"e": _stalk_wave(0.0, 0.0, 8.0), "w": {}, "root": Vector3(0.0, 0.0, 0.04), "scale": Vector3(1.04, 0.96, 1.04)}],
		[16, _p({})]])])
	list.append([&"stagger", _clip(44, _sampled(44, 4, func(p: float) -> Dictionary:
		var e: Dictionary = _stalk_wave(p, 10.0, -4.0)
		e[&"Head"] = Vector3(-14.0, 0.0, sin(p * TAU) * 16.0)
		return {"e": e, "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, -20.0)}), "root": Vector3.ZERO, "scale": Vector3.ONE}), true)])
	list.append([&"kneel", _clip(60, _sampled(60, 6, func(p: float) -> Dictionary:
		var e: Dictionary = _stalk_wave(p, 3.0, -11.0)
		e[&"Head"] = Vector3(-24.0, 0.0, sin(p * TAU) * 6.0)
		return {"e": e, "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, -34.0), &"Whip_R2": Vector3(0.0, 0.0, -20.0)}), "root": Vector3(0.0, -0.08, 0.0),
			"scale": Vector3(1.05, 0.9, 1.05)}), true)])
	list.append([&"waver", _clip(42, _sampled(42, 3, func(p: float) -> Dictionary:
		var shake: float = _shiver(p * 42.0, 1.8)
		var e: Dictionary = _stalk_wave(p, 2.0, -7.0)
		e[&"Head"] = Vector3(-16.0, 0.0, shake * 5.0)
		return {"e": e, "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, -24.0 + shake * 4.0)}), "root": Vector3.ZERO, "scale": Vector3.ONE}), true)])
	list.append([&"collapse", _clip(40, [[0, _p({})], [40, {"e": _stalk_wave(0.0, 0.0, -22.0), "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, -50.0),
		&"Whip_R2": Vector3(0.0, 0.0, -30.0)}), "root": Vector3(0.0, -0.4, 0.0), "scale": Vector3(1.1, 0.7, 1.1)}]], false, 0, 0, true)])
	list.append([&"calmed", _clip(80, [[0, {"e": _stalk_wave(0.0, 0.0, -8.0), "w": {}, "root": Vector3.ZERO, "scale": Vector3.ONE}],
		[30, {"e": _stalk_wave(0.0, 0.0, 6.0), "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, 30.0)}), "root": Vector3.ZERO, "scale": Vector3(0.97, 1.05, 0.97)}],
		[80, {"e": _stalk_wave(0.0, 0.0, 2.0), "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, -10.0)}), "root": Vector3.ZERO, "scale": Vector3.ONE}]], false, 0, 0, true)])
	list.append([&"happy", _clip(36, _sampled(36, 3, func(p: float) -> Dictionary:
		var e: Dictionary = _stalk_wave(p, 12.0, 0.0)
		return {"e": e, "w": _mirrored({&"Whip_R1": Vector3(0.0, 0.0, 30.0 + sin(p * TAU * 2.0) * 20.0)}), "root": Vector3.ZERO, "scale": Vector3.ONE}), true)])
	return list


# --- Mounds -------------------------------------------------------------------------------

static func _blob() -> Array:
	var list: Array = []
	list.append([&"idle", _clip(150, _sampled(150, 10, func(p: float) -> Dictionary:
		var breath: float = sin(p * TAU * 3.0)
		return {"e": _mirrored({&"Belly": Vector3(breath * 1.5, 0.0, sin(p * TAU) * 3.0), &"Crown": Vector3(breath * 2.0, 0.0, -sin(p * TAU) * 2.0),
			&"Cap": Vector3(0.0, sin(p * TAU) * 12.0, 0.0), &"Drip_1": Vector3(sin(p * TAU * 2.0) * 6.0, 0.0, 0.0), &"Drip_2": Vector3(sin(p * TAU * 2.0 - 0.6) * 8.0, 0.0, 0.0)}),
			"w": _mirrored({&"Arm_R1": Vector3(0.0, sin(p * TAU) * 6.0, breath * 4.0)}), "root": Vector3.ZERO,
			"scale": Vector3(1.0 - breath * 0.02, 1.0 + breath * 0.03, 1.0 - breath * 0.02)}), true)])
	var waddle: Callable = func(p: float, size: float) -> Dictionary:
		var side: float = sin(p * TAU)
		var lift_r: float = maxf(0.0, sin(p * TAU))
		var lift_l: float = maxf(0.0, -sin(p * TAU))
		return {"e": {&"Belly": Vector3(-4.0, 0.0, side * 8.0 * size), &"Crown": Vector3(-3.0, 0.0, -side * 5.0 * size), &"Foot_R": Vector3(lift_r * 30.0, 0.0, 0.0),
			&"Foot_L": Vector3(lift_l * 30.0, 0.0, 0.0), &"Drip_1": Vector3(10.0, 0.0, -side * 10.0), &"Drip_2": Vector3(8.0, 0.0, -side * 12.0)},
			"w": _mirrored({&"Arm_R1": Vector3(0.0, -side * 18.0 * size, 10.0)}), "root": Vector3(side * 0.03 * size, (lift_r + lift_l) * 0.03 * size, 0.0),
			"scale": Vector3(1.0 + absf(side) * 0.03, 1.0 - absf(side) * 0.04, 1.0 + absf(side) * 0.03)}
	list.append([&"walk", _clip(44, _sampled(44, 4, func(p: float) -> Dictionary: return waddle.call(p, 1.0)), true)])
	list.append([&"run", _clip(28, _sampled(28, 2, func(p: float) -> Dictionary: return waddle.call(p, 1.4)), true)])
	# A slap: drawn up and back, the right arm high, then down across with all its weight.
	list.append([&"attack_slap", _clip(50, [
		[0, _p({})],
		[28, {"e": {&"Belly": Vector3(10.0, 0.0, 8.0), &"Crown": Vector3(8.0, 0.0, 0.0)}, "w": {&"Arm_R1": Vector3(0.0, -20.0, 90.0), &"Arm_R2": Vector3(0.0, 0.0, 40.0)},
			"root": Vector3(0.0, 0.02, 0.06), "scale": Vector3(0.94, 1.1, 0.94)}],
		[33, {"e": {&"Belly": Vector3(-14.0, 0.0, -6.0), &"Crown": Vector3(-12.0, 0.0, 0.0)}, "w": {&"Arm_R1": Vector3(0.0, 40.0, -20.0), &"Arm_R2": Vector3(0.0, 20.0, -30.0)},
			"root": Vector3(0.0, -0.04, -0.1), "scale": Vector3(1.1, 0.88, 1.1)}],
		[38, {"e": {&"Belly": Vector3(-10.0, 0.0, -4.0)}, "w": {&"Arm_R1": Vector3(0.0, 30.0, -14.0)}, "root": Vector3(0.0, -0.02, -0.08), "scale": Vector3(1.05, 0.94, 1.05)}],
		[50, _p({})],
	], false, 28, 34)])
	# A puff: squashed right down, then up and out in a cloud.
	list.append([&"attack_puff", _clip(50, [
		[0, _p({})],
		[28, {"e": {&"Cap": Vector3(-10.0, 0.0, 0.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, -20.0)}), "root": Vector3(0.0, -0.04, 0.0), "scale": Vector3(1.16, 0.78, 1.16)}],
		[33, {"e": {&"Cap": Vector3(8.0, 0.0, 0.0), &"Crown": Vector3(6.0, 0.0, 0.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, 50.0)}), "root": Vector3(0.0, 0.1, 0.0),
			"scale": Vector3(0.88, 1.2, 0.88)}],
		[40, {"e": {}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, 20.0)}), "root": Vector3(0.0, 0.03, 0.0), "scale": Vector3(0.96, 1.05, 0.96)}],
		[50, _p({})],
	], false, 28, 34)])
	list.append([&"roar", _clip(60, [[0, _p({})], [16, {"e": {&"Crown": Vector3(14.0, 0.0, 0.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, 70.0)}),
		"root": Vector3.ZERO, "scale": Vector3(0.92, 1.14, 0.92)}], [44, {"e": {&"Crown": Vector3(15.0, 0.0, 0.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 4.0, 72.0)}),
		"root": Vector3.ZERO, "scale": Vector3(0.92, 1.14, 0.92)}], [60, _p({})]])])
	list.append([&"hit", _clip(16, [[0, _p({})], [4, {"e": {&"Crown": Vector3(14.0, 0.0, 6.0)}, "w": {}, "root": Vector3(0.0, 0.0, 0.05), "scale": Vector3(1.12, 0.86, 1.12)}],
		[10, {"e": {}, "w": {}, "root": Vector3.ZERO, "scale": Vector3(0.96, 1.05, 0.96)}], [16, _p({})]])])
	list.append([&"stagger", _clip(44, _sampled(44, 4, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return {"e": {&"Belly": Vector3(0.0, 0.0, sway * 12.0), &"Crown": Vector3(-8.0, 0.0, sway * 8.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, -10.0 + sway * 10.0)}),
			"root": Vector3(sway * 0.03, 0.0, 0.0), "scale": Vector3(1.05, 0.94, 1.05)}), true)])
	list.append([&"kneel", _clip(60, _sampled(60, 6, func(p: float) -> Dictionary:
		var sway: float = sin(p * TAU)
		return {"e": {&"Crown": Vector3(-20.0, 0.0, sway * 5.0), &"Cap": Vector3(-14.0, 0.0, 0.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, -30.0)}),
			"root": Vector3(0.0, -0.05, 0.0), "scale": Vector3(1.18, 0.78, 1.18)}), true)])
	list.append([&"waver", _clip(42, _sampled(42, 3, func(p: float) -> Dictionary:
		var shake: float = _shiver(p * 42.0, 1.8)
		return {"e": {&"Crown": Vector3(-14.0, 0.0, shake * 4.0), &"Belly": Vector3(0.0, 0.0, shake * 3.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, -24.0)}),
			"root": Vector3.ZERO, "scale": Vector3(1.08 + shake * 0.02, 0.9, 1.08 + shake * 0.02)}), true)])
	list.append([&"collapse", _clip(40, [[0, _p({})], [40, {"e": {&"Crown": Vector3(-30.0, 0.0, 10.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, -50.0)}),
		"root": Vector3(0.0, -0.06, 0.0), "scale": Vector3(1.5, 0.32, 1.5)}]], false, 0, 0, true)])
	list.append([&"calmed", _clip(80, [[0, {"e": {&"Crown": Vector3(-14.0, 0.0, 0.0)}, "w": {}, "root": Vector3.ZERO, "scale": Vector3(1.1, 0.88, 1.1)}],
		[16, {"e": {&"Crown": Vector3(8.0, 0.0, 0.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, 50.0)}), "root": Vector3(0.0, 0.04, 0.0), "scale": Vector3(0.92, 1.12, 0.92)}],
		[24, {"e": {&"Belly": Vector3(0.0, 0.0, 10.0)}, "w": {}, "root": Vector3.ZERO, "scale": Vector3(1.06, 0.95, 1.06)}],
		[32, {"e": {&"Belly": Vector3(0.0, 0.0, -10.0)}, "w": {}, "root": Vector3.ZERO, "scale": Vector3(1.0, 1.0, 1.0)}],
		[80, {"e": {&"Crown": Vector3(4.0, 0.0, 0.0)}, "w": {}, "root": Vector3.ZERO, "scale": Vector3.ONE}]], false, 0, 0, true)])
	list.append([&"happy", _clip(30, _sampled(30, 3, func(p: float) -> Dictionary:
		var hop: float = absf(sin(p * TAU))
		return {"e": {&"Belly": Vector3(0.0, 0.0, sin(p * TAU) * 10.0)}, "w": _mirrored({&"Arm_R1": Vector3(0.0, 0.0, 40.0 + hop * 30.0)}),
			"root": Vector3(0.0, hop * 0.08, 0.0), "scale": Vector3(1.0 - hop * 0.05, 1.0 + hop * 0.08, 1.0 - hop * 0.05)}), true)])
	return list
