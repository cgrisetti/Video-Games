## Every clip in the hero's AnimationLibrary, as key poses at 60 Hz frames
## (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §3.3, Stage 7). HeroCombatAnimator
## bakes them (HeroPoseBaker) into rotation, position and scale tracks.
##
## A clip is {"frames", "keys": [[frame, pose] ...]} with, for an action,
## "windup" and "active" (the frames where its wind-up and active phases end,
## stretched onto the action's real timing), and flags: "loop", "foot_ik"
## (the feet plant on the ground), "grip" (a two-hander's off hand rides its
## haft), "draw" (the bow hand pulls to the jaw through the wind-up), and
## "leg_space" ("hips" for spins and rolls, so the legs turn with the body).
## Directions are in the chest's frame for arms (forward is -Z, right +X) and
## the ground's for legs.
class_name HeroClipBook
extends RefCounted

const B = HeroRigBuilder.Bone

# --- Parts ---------------------------------------------------------------------

const FEET_FLAT: Dictionary = {"aim": {B.FOOT_L: Vector3(0.0, -0.32, -0.95), B.FOOT_R: Vector3(0.0, -0.32, -0.95)}}
const LEGS_CALM: Dictionary = {"aim": {B.THIGH_L: Vector3(-0.04, -1.0, -0.03), B.SHIN_L: Vector3(-0.03, -1.0, 0.02),
	B.THIGH_R: Vector3(0.12, -1.0, 0.05), B.SHIN_R: Vector3(0.1, -1.0, 0.08)}, "e": {B.HIPS: Vector3(0.0, 0.0, 3.0)}}
const LEGS_READY: Dictionary = {"aim": {B.THIGH_L: Vector3(-0.12, -1.0, -0.22), B.SHIN_L: Vector3(-0.08, -1.0, 0.03),
	B.THIGH_R: Vector3(0.15, -1.0, 0.17), B.SHIN_R: Vector3(0.1, -1.0, 0.3)}, "hips": Vector3(0.0, -0.05, 0.0)}
const LEGS_LUNGE: Dictionary = {"aim": {B.THIGH_L: Vector3(-0.1, -0.8, -0.6), B.SHIN_L: Vector3(-0.05, -1.0, 0.05),
	B.THIGH_R: Vector3(0.12, -0.85, 0.5), B.SHIN_R: Vector3(0.1, -0.55, 0.85)}, "hips": Vector3(0.0, -0.14, 0.0)}
const LEGS_WIDE: Dictionary = {"aim": {B.THIGH_L: Vector3(-0.4, -1.0, -0.1), B.SHIN_L: Vector3(-0.22, -1.0, 0.06),
	B.THIGH_R: Vector3(0.4, -1.0, 0.1), B.SHIN_R: Vector3(0.22, -1.0, 0.14)}, "hips": Vector3(0.0, -0.13, 0.0)}
const LEGS_RISE: Dictionary = {"aim": {B.THIGH_L: Vector3(-0.08, -1.0, -0.08), B.SHIN_L: Vector3(-0.06, -1.0, 0.0),
	B.THIGH_R: Vector3(0.1, -1.0, 0.06), B.SHIN_R: Vector3(0.08, -1.0, 0.04),
	B.FOOT_L: Vector3(0.0, -0.9, -0.45), B.FOOT_R: Vector3(0.0, -0.9, -0.45)}, "hips": Vector3(0.0, 0.05, 0.0)}
const LEGS_KNEEL: Dictionary = {"aim": {B.THIGH_R: Vector3(0.1, -1.0, 0.05), B.SHIN_R: Vector3(0.08, -0.15, 1.0), B.FOOT_R: Vector3(0.0, -1.0, 0.2),
	B.THIGH_L: Vector3(-0.1, -0.05, -1.0), B.SHIN_L: Vector3(-0.05, -1.0, 0.0), B.FOOT_L: Vector3(0.0, -0.32, -0.95)}, "hips": Vector3(0.0, -0.42, 0.0)}
const LEGS_TUCK: Dictionary = {"aim": {B.THIGH_L: Vector3(-0.08, -0.25, -1.0), B.SHIN_L: Vector3(-0.05, -1.0, 0.3),
	B.THIGH_R: Vector3(0.08, -0.25, -1.0), B.SHIN_R: Vector3(0.05, -1.0, 0.3)}}
const LEGS_SLUMP: Dictionary = {"aim": {B.THIGH_L: Vector3(-0.15, -0.2, -1.0), B.SHIN_L: Vector3(-0.1, -1.0, -0.3),
	B.THIGH_R: Vector3(0.15, -0.2, -1.0), B.SHIN_R: Vector3(0.1, -1.0, -0.3)}, "hips": Vector3(0.0, -0.6, 0.0)}
const TORSO_READY: Dictionary = {"e": {B.SPINE: Vector3(-6.0, 0.0, 0.0), B.CHEST: Vector3(-2.0, -6.0, 0.0), B.NECK: Vector3(0.0, 3.0, 0.0), B.HEAD: Vector3(2.0, 4.0, 0.0)}}
const TORSO_CALM: Dictionary = {"e": {B.SPINE: Vector3(-1.0, 0.0, -2.0), B.CHEST: Vector3(1.0, 0.0, 1.0), B.HEAD: Vector3(0.0, 6.0, 0.0)}}
const R_HANG: Dictionary = {"aim": {B.UPPER_ARM_R: Vector3(0.12, -1.0, 0.02), B.FOREARM_R: Vector3(0.08, -1.0, -0.12)}}
const L_HANG: Dictionary = {"aim": {B.UPPER_ARM_L: Vector3(-0.12, -1.0, 0.02), B.FOREARM_L: Vector3(-0.08, -1.0, -0.12)}}
const R_SWORD: Dictionary = {"aim": {B.UPPER_ARM_R: Vector3(0.32, -0.62, -0.5), B.FOREARM_R: Vector3(0.06, 0.18, -1.0)}, "wpn": {B.HAND_R: Vector3(0.04, 0.9, -0.45)}}
const L_SHIELD: Dictionary = {"aim": {B.UPPER_ARM_L: Vector3(-0.32, -0.62, -0.5), B.FOREARM_L: Vector3(0.45, 0.12, -0.85)}}
const R_AXE: Dictionary = {"aim": {B.UPPER_ARM_R: Vector3(0.26, -0.8, -0.3), B.FOREARM_R: Vector3(-0.2, 0.05, -1.0)}, "wpn": {B.HAND_R: Vector3(-0.45, 0.8, -0.25)}}
const L_GRIP: Dictionary = {"aim": {B.UPPER_ARM_L: Vector3(-0.12, -0.7, -0.55), B.FOREARM_L: Vector3(0.45, 0.2, -0.8)}}
const R_STAFF: Dictionary = {"aim": {B.UPPER_ARM_R: Vector3(0.26, -0.75, -0.3), B.FOREARM_R: Vector3(-0.15, 0.0, -1.0)}, "wpn": {B.HAND_R: Vector3(-0.12, 1.0, -0.05)}}
const R_BOW: Dictionary = {"aim": {B.UPPER_ARM_R: Vector3(0.18, -0.9, 0.05), B.FOREARM_R: Vector3(0.05, -0.55, -0.75)}}
const L_BOW: Dictionary = {"aim": {B.UPPER_ARM_L: Vector3(-0.2, -0.85, -0.4), B.FOREARM_L: Vector3(-0.05, -0.45, -1.0)}, "wpn": {B.HAND_L: Vector3(0.0, 1.0, 0.12)}}
## The left hand at the hip satchel, and holding a card up before the face.
const L_SATCHEL: Dictionary = {"aim": {B.UPPER_ARM_L: Vector3(-0.35, -0.85, 0.35), B.FOREARM_L: Vector3(-0.05, -0.6, 0.8)}}
const L_CARD_UP: Dictionary = {"aim": {B.UPPER_ARM_L: Vector3(-0.35, 0.2, -0.9), B.FOREARM_L: Vector3(0.35, 0.75, -0.55)}}
## A weapon thrust straight out ahead.
const R_THRUST: Dictionary = {"aim": {B.UPPER_ARM_R: Vector3(0.05, 0.05, -1.0), B.FOREARM_R: Vector3(0.0, 0.02, -1.0)}, "wpn": {B.HAND_R: Vector3(0.0, 0.02, -1.0)}}
## Both arms raised overhead.
const ARMS_OVERHEAD: Dictionary = {"aim": {B.UPPER_ARM_R: Vector3(0.15, 1.0, -0.1), B.FOREARM_R: Vector3(-0.2, 0.95, -0.1), B.UPPER_ARM_L: Vector3(-0.15, 1.0, -0.1),
	B.FOREARM_L: Vector3(0.2, 0.95, -0.1)}, "wpn": {B.HAND_R: Vector3(0.0, 1.0, -0.2)}}


# --- The book --------------------------------------------------------------------

## Every clip: [name, spec].
static func clips() -> Array[Array]:
	var book: Array[Array] = []
	_idles(book)
	_broad_axe(book)
	_falchion(book)
	_longbow(book)
	_way_staff(book)
	_cards(book)
	_defence(book)
	_stewardship(book)
	_reactions(book)
	_youth(book)
	return book


static func _p(parts: Array) -> Dictionary:
	return HeroPoseBaker.compose(parts)


static func _e(turns: Dictionary) -> Dictionary:
	return {"e": turns}


static func _aim(aims: Dictionary) -> Dictionary:
	return {"aim": aims}


static func _wpn(hand: int, haft: Vector3) -> Dictionary:
	return {"wpn": {hand: haft}}


static func _hips(offset: Vector3) -> Dictionary:
	return {"hips": offset}


static func _clip(book: Array[Array], clip_name: String, frames: int, keys: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {"frames": frames, "keys": keys}
	spec.merge(extra, true)
	book.append([StringName(clip_name), spec])


static func _action(windup: int, active: int, extra: Dictionary = {}) -> Dictionary:
	var spec: Dictionary = {"windup": windup, "active": active}
	spec.merge(extra, true)
	return spec


## A turn of the hips about Y (degrees), for spins.
static func _spin(degrees: float) -> Dictionary:
	return {"e": {B.HIPS: Vector3(0.0, degrees, 0.0)}}


# --- Idles and footwork ----------------------------------------------------------

static func _idles(book: Array[Array]) -> void:
	var calm: Dictionary = _p([LEGS_CALM, FEET_FLAT, TORSO_CALM, R_HANG, L_HANG])
	var calm_breath: Dictionary = _p([calm, _e({B.CHEST: Vector3(3.0, 0.0, 1.0), B.HEAD: Vector3(-2.0, 12.0, 0.0), B.HIPS: Vector3(0.0, 0.0, 3.5)}), _hips(Vector3(0.0, -0.01, 0.0))])
	_clip(book, "idle_steward_calm", 120, [[0, calm], [60, calm_breath], [120, calm]], {"loop": true})
	for entry: Array in [["idle_combat_ready", R_SWORD, L_SHIELD], ["idle_combat_ready_axe", R_AXE, L_GRIP],
			["idle_combat_ready_staff", R_STAFF, L_GRIP], ["idle_combat_ready_bow", R_BOW, L_BOW]]:
		var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, entry[1], entry[2]])
		var breath: Dictionary = _p([ready, _e({B.CHEST: Vector3(1.0, -6.0, 0.0), B.SPINE: Vector3(-7.0, 0.0, 0.0)}), _hips(Vector3(0.0, -0.065, 0.0))])
		_clip(book, entry[0], 90, [[0, ready], [45, breath], [90, ready]], {"loop": true, "grip": true})
	# The jaunty woodsman's run (19B §2, Pillar 2).
	_run_cycle(book)
	# Winded after a third Light in a row: hands toward the knees, the chest heaving.
	var ready_sword: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_SWORD, L_SHIELD])
	var slump: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.1, 0.0)),
		_e({B.SPINE: Vector3(-18.0, 0.0, 0.0), B.CHEST: Vector3(-8.0, 0.0, 0.0), B.HEAD: Vector3(16.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.3, -0.8, -0.45), B.FOREARM_R: Vector3(0.05, -0.95, -0.25),
			B.UPPER_ARM_L: Vector3(-0.3, -0.8, -0.45), B.FOREARM_L: Vector3(-0.05, -0.95, -0.25)})])
	var heave: Dictionary = _p([slump, _e({B.SPINE: Vector3(-10.0, 0.0, 0.0), B.CHEST: Vector3(2.0, 0.0, 0.0), B.HEAD: Vector3(10.0, 0.0, 0.0),
		B.CLAVICLE_L: Vector3(0.0, 0.0, 8.0), B.CLAVICLE_R: Vector3(0.0, 0.0, -8.0)})])
	_clip(book, "winded_3rd_light_recovery", 33, [[0, ready_sword], [6, slump], [16, heave], [26, slump], [33, ready_sword]])


# --- The run (19B, Pillar 2) ------------------------------------------------------

## The run's frames and, at each, the pelvis: its offset (x weight shift over
## the planted boot, y the contact squash and the push-off loft), its yaw
## (degrees; the leading leg's hip forward) and its roll (the swing side dropping).
const RUN_FRAMES: Array[int] = [0, 2, 4, 7, 11, 14, 16, 18, 21, 25, 28]
const RUN_HIPS: Array[Vector2] = [Vector2(0.0, 0.02), Vector2(-0.012, -0.01), Vector2(-0.025, -0.045), Vector2(-0.035, -0.035), Vector2(-0.02, 0.055),
	Vector2(0.0, 0.02), Vector2(0.012, -0.01), Vector2(0.025, -0.045), Vector2(0.035, -0.035), Vector2(0.02, 0.055), Vector2(0.0, 0.02)]
const RUN_YAW: Array[float] = [-4.4, -7.4, -10.3, -5.9, 0.0, 4.4, 7.4, 10.3, 5.9, 0.0, -4.4]
const RUN_ROLL: Array[float] = [0.0, -2.0, -4.0, -6.5, -3.0, 0.0, 2.0, 4.0, 6.5, 3.0, 0.0]
## The legs' beat at each frame, and which leg leads it (-1 left, 1 right).
const RUN_BEATS: Array[String] = ["reach", "heel", "contact", "cushion", "loft", "reach", "heel", "contact", "cushion", "loft", "reach"]
const RUN_LEADS: Array[float] = [-1.0, -1.0, -1.0, -1.0, -1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0]
## The arms' counter-balance swing, the off arm's way (-1 back, the left leg
## leading; 1 forward); the weapon arm swings the other way (13_PLAYTEST §2.12).
const RUN_SWING: Array[float] = [-0.6, -0.85, -1.0, -0.7, 0.0, 0.6, 0.85, 1.0, 0.7, 0.0, -0.6]
## The leading boot pitched up 24 degrees on heel-strike, half that at contact; flat;
## the trailing ankle snapped 31 degrees down on toe-off.
const FOOT_HEEL: Vector3 = Vector3(0.0, 0.094, -0.996)
const FOOT_CONTACT: Vector3 = Vector3(0.0, -0.115, -0.993)
const FOOT_FLAT: Vector3 = Vector3(0.0, -0.32, -0.95)
const FOOT_TOE_OFF: Vector3 = Vector3(0.0, -0.762, -0.648)
## The legs run 35 mm wider a side than they stand.
const RUN_THIGH_OUT: float = 0.07
const RUN_SHIN_OUT: float = 0.03


## The athletic woodsman's stride: a crisp 3-frame contact squash at each boot
## plant (frames 4 and 18) springing into a buoyant loft (11 and 25), weight
## shifting over the planted boot, the pelvis rolling and yawing while the chest
## counter-twists and rolls its shoulders, the head held steady; the weapon
## carried one-handed in a 30-degree diagonal low port across the hip, bouncing
## 3 frames behind the pelvis, while the off arm swings to counter-balance;
## heel-strike, roll-through and toe-off, the knee whipped high into the next stride.
static func _run_cycle(book: Array[Array]) -> void:
	var keys: Array = []
	for index: int in RUN_FRAMES.size():
		var yaw: float = RUN_YAW[index]
		var roll: float = RUN_ROLL[index]
		var squash: float = clampf(-RUN_HIPS[index].y / 0.045, 0.0, 1.0)
		var chest_pitch: float = lerpf(-4.0, -6.0, squash) + 2.0 * clampf(RUN_HIPS[index].y / 0.055, 0.0, 1.0)
		var pose: Dictionary = _p([
			_run_legs(RUN_BEATS[index], RUN_LEADS[index]),
			_hips(Vector3(RUN_HIPS[index].x, RUN_HIPS[index].y, 0.0)),
			_e({B.HIPS: Vector3(0.0, yaw, roll), B.SPINE: Vector3(-5.0, -0.4 * yaw, -0.6 * roll), B.CHEST: Vector3(chest_pitch, -1.2 * yaw, -0.7 * roll),
				B.NECK: Vector3(0.0, 0.2 * yaw, 0.0), B.HEAD: Vector3(-0.35 * (chest_pitch + 4.0), 0.42 * yaw, 0.25 * roll)}),
			_run_weapon_swing(-RUN_SWING[index]),
			_run_swing(RUN_SWING[index]),
		])
		keys.append([RUN_FRAMES[index], pose])
	_clip(book, "locomotion_run_cycle", 28, keys, {"loop": true})


## The legs at a beat of the stride for the leading leg (`lead` -1 left, 1 right).
static func _run_legs(beat: String, lead: float) -> Dictionary:
	var trail: float = -lead
	var lead_thigh: int = B.THIGH_L if lead < 0.0 else B.THIGH_R
	var lead_shin: int = B.SHIN_L if lead < 0.0 else B.SHIN_R
	var lead_foot: int = B.FOOT_L if lead < 0.0 else B.FOOT_R
	var trail_thigh: int = B.THIGH_R if lead < 0.0 else B.THIGH_L
	var trail_shin: int = B.SHIN_R if lead < 0.0 else B.SHIN_L
	var trail_foot: int = B.FOOT_R if lead < 0.0 else B.FOOT_L
	var lo: float = lead * RUN_THIGH_OUT
	var ls: float = lead * RUN_SHIN_OUT
	var to: float = trail * RUN_THIGH_OUT
	var ts: float = trail * RUN_SHIN_OUT
	var aims: Dictionary = {}
	match beat:
		"reach":
			aims = {lead_thigh: Vector3(lo, -0.8, -0.6), lead_shin: Vector3(ls, -0.95, -0.12), lead_foot: Vector3(0.0, -0.1, -1.0),
				trail_thigh: Vector3(to, -0.9, 0.42), trail_shin: Vector3(ts, -0.72, 0.7), trail_foot: Vector3(0.0, -0.7, -0.7)}
		"heel":
			aims = {lead_thigh: Vector3(lo, -0.85, -0.52), lead_shin: Vector3(ls, -1.0, -0.18), lead_foot: FOOT_HEEL,
				trail_thigh: Vector3(to, -0.92, 0.38), trail_shin: Vector3(ts, -0.62, 0.78), trail_foot: FOOT_TOE_OFF}
		"contact":
			aims = {lead_thigh: Vector3(lo, -0.92, -0.38), lead_shin: Vector3(ls, -1.0, -0.04), lead_foot: FOOT_CONTACT,
				trail_thigh: Vector3(to, -0.95, 0.3), trail_shin: Vector3(ts, -0.5, 0.86), trail_foot: FOOT_TOE_OFF}
		"cushion":
			aims = {lead_thigh: Vector3(lo, -1.0, -0.12), lead_shin: Vector3(ls, -1.0, 0.12), lead_foot: FOOT_FLAT,
				trail_thigh: Vector3(to, -0.95, 0.05), trail_shin: Vector3(ts, -0.35, 0.94), trail_foot: Vector3(0.0, -0.6, -0.8)}
		"loft":
			# The planted leg pushes off behind; the swing knee whips up 0.78 rad.
			aims = {lead_thigh: Vector3(lo, -0.95, 0.25), lead_shin: Vector3(ls, -0.85, 0.5), lead_foot: Vector3(0.0, -0.6, -0.8),
				trail_thigh: Vector3(to, -0.71, -0.7), trail_shin: Vector3(ts, -1.0, 0.15), trail_foot: Vector3(0.0, -0.2, -0.98)}
	return {"aim": aims}


## The weapon arm's athletic swing (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.12):
## the off arm's arc mirrored and swung the other way, the elbow bent, the
## weapon carried point-forward and a little up (no longer parked at the hip).
static func _run_weapon_swing(swing: float) -> Dictionary:
	var middle_upper: Vector3 = Vector3(0.2, -1.0, 0.0)
	var middle_fore: Vector3 = Vector3(0.02, -0.75, -0.55)
	var upper: Vector3 = middle_upper.lerp(Vector3(0.18, -0.86, -0.46) if swing > 0.0 else Vector3(0.2, -0.88, 0.42), absf(swing))
	var fore: Vector3 = middle_fore.lerp(Vector3(-0.2, -0.3, -0.93) if swing > 0.0 else Vector3(0.1, -0.82, 0.2), absf(swing))
	var haft: Vector3 = Vector3(0.12, 0.4, -0.91).lerp(Vector3(0.16, 0.62, -0.77) if swing > 0.0 else Vector3(0.1, 0.12, -0.99), absf(swing))
	return {"aim": {B.UPPER_ARM_R: upper, B.FOREARM_R: fore}, "wpn": {B.HAND_R: haft}}


## The off arm's counter-balance arc: back while the left leg leads, forward and across while the right does.
static func _run_swing(swing: float) -> Dictionary:
	var middle_upper: Vector3 = Vector3(-0.2, -1.0, 0.0)
	var middle_fore: Vector3 = Vector3(-0.02, -0.75, -0.55)
	var upper: Vector3 = middle_upper.lerp(Vector3(-0.18, -0.86, -0.46) if swing > 0.0 else Vector3(-0.2, -0.88, 0.42), absf(swing))
	var fore: Vector3 = middle_fore.lerp(Vector3(0.2, -0.3, -0.93) if swing > 0.0 else Vector3(-0.1, -0.82, 0.2), absf(swing))
	return {"aim": {B.UPPER_ARM_L: upper, B.FOREARM_L: fore}}


# --- The Broad-Axe -------------------------------------------------------------

static func _broad_axe(book: Array[Array]) -> void:
	var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_AXE, L_GRIP])
	# Light 1: a right-to-left diagonal timber-felling hew off a 38-degree hip coil.
	var coil: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.08, 0.0)),
		_e({B.HIPS: Vector3(0.0, -12.0, 0.0), B.SPINE: Vector3(-4.0, -20.0, 0.0), B.CHEST: Vector3(4.0, -22.0, 0.0), B.HEAD: Vector3(0.0, 30.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.55, 0.45, 0.4), B.FOREARM_R: Vector3(0.05, 0.95, 0.25)}), _wpn(B.HAND_R, Vector3(0.25, 0.45, 0.85))])
	var taut: Dictionary = _p([coil, _e({B.CHEST: Vector3(6.0, -26.0, 0.0)})])
	var hew: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, _hips(Vector3(0.0, -0.12, 0.0)),
		_e({B.SPINE: Vector3(-10.0, 4.0, 0.0), B.CHEST: Vector3(-8.0, 8.0, 0.0), B.HEAD: Vector3(-4.0, -8.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.2, 0.05, -1.0), B.FOREARM_R: Vector3(-0.25, -0.15, -1.0)}), _wpn(B.HAND_R, Vector3(-0.45, 0.1, -0.9))])
	var through: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, _hips(Vector3(0.0, -0.15, 0.0)),
		_e({B.HIPS: Vector3(0.0, 14.0, 0.0), B.SPINE: Vector3(-14.0, 20.0, 0.0), B.CHEST: Vector3(-10.0, 22.0, 0.0), B.HEAD: Vector3(-4.0, -30.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(-0.55, -0.5, -0.65), B.FOREARM_R: Vector3(-0.85, -0.5, -0.3)}), _wpn(B.HAND_R, Vector3(-0.75, -0.55, 0.3))])
	var settle: Dictionary = _p([through, _e({B.SPINE: Vector3(-10.0, 16.0, 0.0)})])
	_clip(book, "axe_light_1", 51, [[0, ready], [12, coil], [18, taut], [22, hew], [27, through], [38, settle], [51, ready]], _action(18, 27, {"grip": true}))
	# Light 2: a low-to-high reverse undercut, the hips dropping 0.16 m.
	var low: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.16, 0.0)),
		_e({B.HIPS: Vector3(0.0, 12.0, 0.0), B.SPINE: Vector3(-14.0, 18.0, 0.0), B.CHEST: Vector3(-6.0, 20.0, 0.0), B.HEAD: Vector3(0.0, -25.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(-0.35, -0.85, -0.2), B.FOREARM_R: Vector3(-0.6, -0.6, -0.3)}), _wpn(B.HAND_R, Vector3(-0.55, -0.65, 0.45))])
	var low_taut: Dictionary = _p([low, _e({B.SPINE: Vector3(-16.0, 22.0, 0.0)})])
	var undercut: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.1, 0.0)), _e({B.SPINE: Vector3(-6.0, 0.0, 0.0), B.CHEST: Vector3(-4.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.15, -0.35, -1.0), B.FOREARM_R: Vector3(0.05, 0.2, -1.0)}), _wpn(B.HAND_R, Vector3(0.0, 0.4, -1.0))])
	var high: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.02, 0.0)),
		_e({B.HIPS: Vector3(0.0, -10.0, 0.0), B.SPINE: Vector3(4.0, -18.0, 0.0), B.CHEST: Vector3(8.0, -24.0, 0.0), B.HEAD: Vector3(-6.0, 20.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.5, 0.65, -0.35), B.FOREARM_R: Vector3(0.35, 0.85, -0.15)}), _wpn(B.HAND_R, Vector3(0.3, 0.85, 0.35))])
	_clip(book, "axe_light_2", 51, [[0, ready], [12, low], [18, low_taut], [22, undercut], [27, high], [38, high], [51, ready]], _action(18, 27, {"grip": true}))
	# The Earth-Splitter: up onto the toes with the axe hoisted overhead, the torso
	# arched back, then the whole body jackknifes and slams it into the earth.
	var hoist: Dictionary = _p([LEGS_RISE, _e({B.SPINE: Vector3(14.0, 0.0, 0.0), B.CHEST: Vector3(12.0, 0.0, 0.0), B.HEAD: Vector3(-8.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.12, 1.0, 0.18), B.FOREARM_R: Vector3(0.02, 0.55, 0.9)}), _wpn(B.HAND_R, Vector3(0.0, 0.15, 1.0))])
	var arched: Dictionary = _p([hoist, _e({B.SPINE: Vector3(18.0, 0.0, 0.0), B.CHEST: Vector3(14.0, 0.0, 0.0)})])
	var falling: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, _hips(Vector3(0.0, -0.05, 0.0)), _e({B.SPINE: Vector3(-22.0, 0.0, 0.0), B.CHEST: Vector3(-16.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.1, 0.25, -1.0), B.FOREARM_R: Vector3(0.0, -0.35, -1.0)}), _wpn(B.HAND_R, Vector3(0.0, -0.15, -1.0))])
	var impact: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, _hips(Vector3(0.0, -0.2, 0.0)), {"scale": Vector3(1.078, 0.86, 1.078)},
		_e({B.SPINE: Vector3(-34.0, 0.0, 0.0), B.CHEST: Vector3(-20.0, 0.0, 0.0), B.HEAD: Vector3(16.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.08, -0.5, -0.85), B.FOREARM_R: Vector3(0.0, -0.75, -0.65)}), _wpn(B.HAND_R, Vector3(0.0, -0.85, -0.5))])
	var planted: Dictionary = _p([impact, {"scale": Vector3.ONE}])
	_clip(book, "axe_heavy_earth_splitter", 56, [[0, ready], [14, hoist], [23, arched], [26, falling], [29, impact], [38, planted], [56, ready]],
		_action(23, 29, {"grip": true}))
	# R un-inked: the Coppice-Splitter Slam, a 360-degree ring cleave into a slam.
	var out_right: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.08, 0.0)), _e({B.CHEST: Vector3(0.0, -45.0, 0.0), B.SPINE: Vector3(-6.0, -15.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.95, 0.0, 0.2), B.FOREARM_R: Vector3(0.95, 0.05, -0.2)}), _wpn(B.HAND_R, Vector3(1.0, 0.05, 0.0))])
	var whirl: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.1, 0.0)), _e({B.SPINE: Vector3(-6.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.95, 0.05, -0.2), B.FOREARM_R: Vector3(0.9, 0.05, -0.45)}), _wpn(B.HAND_R, Vector3(0.75, 0.05, -0.65))])
	var slam: Dictionary = _p([impact, {"scale": Vector3(1.06, 0.89, 1.06)}])
	_clip(book, "axe_flourish_r_coppice", 64, [[0, ready], [14, out_right], [20, out_right], [27, _p([whirl, _spin(120.0)])],
		[33, _p([whirl, _spin(240.0)])], [36, _p([hoist, _spin(300.0)])], [40, _p([slam, _spin(360.0)])], [48, planted], [64, ready]],
		_action(20, 40, {"grip": true, "leg_space": "hips"}))
	# L+R un-inked: Heartwood Sundering, a double whirl into a seismic slam.
	var big_slam: Dictionary = _p([impact, {"scale": Vector3(1.09, 0.84, 1.09)}, _hips(Vector3(0.0, -0.24, 0.0))])
	var keys: Array = [[0, ready], [12, out_right], [30, out_right]]
	for index: int in 6:
		keys.append([34 + index * 4, _p([whirl, _spin(120.0 * float(index + 1))])])
	keys.append_array([[62, _p([arched, _spin(720.0)])], [68, _p([big_slam, _spin(720.0)])], [80, planted], [90, ready]])
	_clip(book, "axe_ult_lr_heartwood", 90, keys, _action(30, 68, {"grip": true, "leg_space": "hips"}))


# --- The Falchion ----------------------------------------------------------------

static func _falchion(book: Array[Array]) -> void:
	var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_SWORD, L_SHIELD])
	var high_right: Dictionary = _p([ready, _e({B.CHEST: Vector3(4.0, -18.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.6, 0.55, 0.1), B.FOREARM_R: Vector3(0.3, 0.95, -0.1)}), _wpn(B.HAND_R, Vector3(0.2, 0.6, 0.75))])
	var mid_cut: Dictionary = _p([ready, _e({B.CHEST: Vector3(-6.0, 8.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.1, 0.1, -1.0), B.FOREARM_R: Vector3(-0.3, -0.3, -1.0)}), _wpn(B.HAND_R, Vector3(-0.4, -0.3, -0.9))])
	var low_left: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, TORSO_READY, L_SHIELD, _hips(Vector3(0.0, -0.08, 0.0)),
		_e({B.CHEST: Vector3(-8.0, 20.0, 0.0), B.SPINE: Vector3(-6.0, 10.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(-0.5, -0.55, -0.6), B.FOREARM_R: Vector3(-0.8, -0.5, -0.3)}), _wpn(B.HAND_R, Vector3(-0.7, -0.6, 0.3))])
	# Light 1: a high diagonal slash.
	_clip(book, "falchion_light_1", 33, [[0, ready], [6, high_right], [9, high_right], [12, mid_cut], [15, low_left], [24, low_left], [33, ready]], _action(9, 15))
	# Light 2: a quick backhand sweep, left to right.
	var back_left: Dictionary = _p([ready, _e({B.CHEST: Vector3(0.0, 24.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(-0.5, -0.2, -0.6), B.FOREARM_R: Vector3(-0.95, 0.05, -0.1)}), _wpn(B.HAND_R, Vector3(-0.6, 0.0, 0.8))])
	var across: Dictionary = _p([ready, _e({B.CHEST: Vector3(0.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.15, -0.1, -1.0), B.FOREARM_R: Vector3(0.1, 0.0, -1.0)}), _wpn(B.HAND_R, Vector3(0.0, 0.0, -1.0))])
	var out_right: Dictionary = _p([ready, _e({B.CHEST: Vector3(0.0, -26.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.95, -0.1, -0.2), B.FOREARM_R: Vector3(0.95, 0.0, 0.25)}), _wpn(B.HAND_R, Vector3(0.7, 0.0, 0.7))])
	_clip(book, "falchion_light_2", 33, [[0, ready], [6, back_left], [9, back_left], [12, across], [15, out_right], [24, out_right], [33, ready]], _action(9, 15))
	# Light 3: a spinning flourish cut.
	var extended: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, L_SHIELD,
		_aim({B.UPPER_ARM_R: Vector3(1.0, 0.05, -0.1), B.FOREARM_R: Vector3(1.0, 0.05, -0.2)}), _wpn(B.HAND_R, Vector3(0.85, 0.0, -0.55))])
	_clip(book, "falchion_light_3", 33, [[0, ready], [6, back_left], [9, extended], [11, _p([extended, _spin(120.0)])], [13, _p([extended, _spin(240.0)])],
		[15, _p([low_left, _spin(360.0)])], [24, low_left], [33, ready]], _action(9, 15, {"leg_space": "hips"}))
	# Heavy: the Advancing Thrust, a fencer's long lunge with the off arm counterbalancing behind.
	var chamber: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.08, 0.0)), _e({B.CHEST: Vector3(0.0, -30.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.6, -0.3, 0.6), B.FOREARM_R: Vector3(0.2, 0.0, -1.0), B.UPPER_ARM_L: Vector3(-0.5, -0.3, 0.7),
			B.FOREARM_L: Vector3(-0.5, 0.4, 0.6)}), _wpn(B.HAND_R, Vector3(0.0, 0.05, -1.0))])
	var lunge: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, R_THRUST, _hips(Vector3(0.0, -0.2, 0.0)),
		_e({B.CHEST: Vector3(-10.0, 10.0, 0.0), B.SPINE: Vector3(-14.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_L: Vector3(-0.6, 0.1, 0.75), B.FOREARM_L: Vector3(-0.7, 0.3, 0.6)})])
	_clip(book, "falchion_heavy_advancing_thrust", 63, [[0, ready], [15, chamber], [21, chamber], [30, lunge], [42, lunge], [63, ready]], _action(21, 30))
	# R un-inked: the Timber-Cross Slash, two diagonal cuts in an X.
	var high_left: Dictionary = _p([ready, _e({B.CHEST: Vector3(4.0, 18.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(-0.3, 0.7, -0.1), B.FOREARM_R: Vector3(-0.5, 0.85, -0.1)}), _wpn(B.HAND_R, Vector3(-0.4, 0.6, 0.65))])
	_clip(book, "falchion_flourish_r_timber_cross", 60, [[0, ready], [10, high_right], [20, high_right], [24, low_left], [28, high_left],
		[32, out_right], [44, out_right], [60, ready]], _action(20, 32))
	# L+R un-inked: the Bramble-Whirl Flurry, two spinning sweeps into a cross cut.
	var keys: Array = [[0, ready], [16, back_left], [30, extended]]
	for index: int in 6:
		keys.append([32 + index * 2, _p([extended, _spin(120.0 * float(index + 1))])])
	keys.append_array([[46, _p([low_left, _spin(720.0)])], [60, low_left], [80, ready]])
	_clip(book, "falchion_ult_lr_bramble_whirl", 80, keys, _action(30, 46, {"leg_space": "hips"}))


# --- The Yew Longbow -------------------------------------------------------------

static func _longbow(book: Array[Array]) -> void:
	var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_BOW, L_BOW])
	# The canted storybook archer: side-on, the bow tipped 22 degrees so the face shows.
	var aim: Dictionary = _p([LEGS_WIDE, FEET_FLAT,
		_e({B.HIPS: Vector3(0.0, -35.0, 0.0), B.SPINE: Vector3(-4.0, -20.0, 0.0), B.CHEST: Vector3(0.0, -20.0, 6.0), B.NECK: Vector3(0.0, 8.0, 0.0), B.HEAD: Vector3(0.0, 62.0, 0.0)}),
		_aim({B.UPPER_ARM_L: Vector3(-0.96, 0.06, -0.27), B.FOREARM_L: Vector3(-0.96, 0.06, -0.27),
			B.UPPER_ARM_R: Vector3(0.85, 0.18, 0.45), B.FOREARM_R: Vector3(-0.92, 0.25, -0.25)}), _wpn(B.HAND_L, Vector3(-0.37, 0.93, 0.0))])
	var release: Dictionary = _p([aim, _hips(Vector3(0.0, -0.1, 0.0)), _aim({B.UPPER_ARM_R: Vector3(0.9, 0.25, 0.35), B.FOREARM_R: Vector3(0.4, 0.5, 0.75)})])
	_clip(book, "bow_light_snap_shot_1", 34, [[0, ready], [8, aim], [13, release], [22, release], [34, ready]], _action(8, 13, {"draw": true}))
	var aim_low: Dictionary = _p([aim, _e({B.CHEST: Vector3(-4.0, -22.0, 10.0)})])
	_clip(book, "bow_light_snap_shot_2", 34, [[0, ready], [8, aim_low], [13, release], [22, release], [34, ready]], _action(8, 13, {"draw": true}))
	# The Piercing Draw: planted wide, a long, deep draw.
	var deep: Dictionary = _p([aim, _hips(Vector3(0.0, -0.16, 0.0)), _e({B.SPINE: Vector3(-6.0, -22.0, 0.0)})])
	_clip(book, "bow_heavy_piercing_draw", 66, [[0, ready], [12, aim], [30, deep], [36, release], [50, release], [66, ready]], _action(30, 36, {"draw": true}))
	# R un-inked: the Vaulting Bough-Shot, a crouch, a vault back and a shot in the air.
	var crouch: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.25, 0.0)), _e({B.SPINE: Vector3(-20.0, 0.0, 0.0)}), R_BOW, L_BOW])
	var vault: Dictionary = _p([aim, LEGS_TUCK, _hips(Vector3(0.0, 0.1, 0.0)), _e({B.HIPS: Vector3(30.0, -35.0, 0.0)})])
	_clip(book, "bow_flourish_r_vaulting_bough", 60, [[0, ready], [10, crouch], [18, crouch], [24, vault], [30, _p([vault, release])], [44, crouch], [60, ready]],
		_action(18, 30, {"draw": true, "leg_space": "hips", "foot_ik": false}))
	# L+R un-inked: Hail of the Hedgerow, arrows loosed high into the sky.
	var sky: Dictionary = _p([aim, _e({B.SPINE: Vector3(14.0, -20.0, 0.0), B.HEAD: Vector3(-20.0, 62.0, 0.0)}),
		_aim({B.UPPER_ARM_L: Vector3(-0.6, 0.75, -0.25), B.FOREARM_L: Vector3(-0.6, 0.75, -0.25)})])
	_clip(book, "bow_ult_lr_hail_of_hedgerow", 80, [[0, ready], [16, aim], [30, sky], [34, _p([sky, release])], [38, sky], [44, _p([sky, release])],
		[60, release], [80, ready]], _action(30, 44, {"draw": true}))


# --- The Rowan Way-Staff ---------------------------------------------------------

static func _way_staff(book: Array[Array]) -> void:
	var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_STAFF, L_GRIP])
	var swing_right: Dictionary = _p([ready, _e({B.CHEST: Vector3(0.0, -24.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.7, -0.3, 0.2), B.FOREARM_R: Vector3(0.6, 0.1, -0.6)}), _wpn(B.HAND_R, Vector3(0.85, 0.3, -0.3))])
	var swing_left: Dictionary = _p([ready, _e({B.CHEST: Vector3(0.0, 24.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(-0.1, -0.4, -0.9), B.FOREARM_R: Vector3(-0.6, -0.1, -0.8)}), _wpn(B.HAND_R, Vector3(-0.9, 0.15, -0.35))])
	var low_left: Dictionary = _p([swing_left, _hips(Vector3(0.0, -0.1, 0.0)), _wpn(B.HAND_R, Vector3(-0.85, -0.35, -0.35))])
	var low_right: Dictionary = _p([swing_right, _hips(Vector3(0.0, -0.1, 0.0)), _wpn(B.HAND_R, Vector3(0.85, -0.3, -0.35))])
	# Two figure-eight quarterstaff sweeps.
	_clip(book, "staff_light_sweep_1", 40, [[0, ready], [8, swing_right], [10, swing_right], [16, swing_left], [28, swing_left], [40, ready]], _action(10, 16, {"grip": true}))
	_clip(book, "staff_light_sweep_2", 43, [[0, ready], [8, low_left], [10, low_left], [16, low_right], [28, low_right], [43, ready]], _action(10, 16, {"grip": true}))
	# The bolt: a planted one-handed extension, the staff's head levelled at the foe.
	var drawn_back: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, L_HANG, _e({B.CHEST: Vector3(0.0, -14.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.5, -0.2, 0.5), B.FOREARM_R: Vector3(0.2, 0.3, -0.9)}), _wpn(B.HAND_R, Vector3(0.0, 1.0, -0.3))])
	var levelled: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, _e({B.CHEST: Vector3(-6.0, 6.0, 0.0), B.SPINE: Vector3(-8.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.15, 0.25, -1.0), B.FOREARM_R: Vector3(0.05, 0.2, -1.0), B.UPPER_ARM_L: Vector3(-0.5, -0.4, 0.6),
			B.FOREARM_L: Vector3(-0.4, -0.2, 0.7)}), _wpn(B.HAND_R, Vector3(0.0, 0.3, -1.0))])
	_clip(book, "staff_light_bolt", 42, [[0, ready], [13, drawn_back], [18, levelled], [30, levelled], [42, ready]], _action(13, 18))
	# The Resonant Pulse: the staff raised upright, then its butt-cap struck into the flagstones.
	var raised: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, 0.03, 0.0)), _e({B.SPINE: Vector3(4.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.2, 0.9, -0.3), B.FOREARM_R: Vector3(0.0, 1.0, -0.1)}), _wpn(B.HAND_R, Vector3(0.0, 1.0, 0.0))])
	var struck: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.14, 0.0)), {"scale": Vector3(1.04, 0.92, 1.04)}, _e({B.SPINE: Vector3(-12.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.2, -0.3, -0.9), B.FOREARM_R: Vector3(0.0, -0.6, -0.8)}), _wpn(B.HAND_R, Vector3(0.0, 1.0, 0.0))])
	var rang: Dictionary = _p([struck, {"scale": Vector3.ONE}])
	_clip(book, "staff_heavy_resonant_pulse", 69, [[0, ready], [18, raised], [24, raised], [30, struck], [33, struck], [45, rang], [69, ready]], _action(24, 33, {"grip": true}))
	# R un-inked: the Reed-Sweep Gust, a wide low sweep.
	_clip(book, "staff_flourish_r_reed_sweep", 60, [[0, ready], [12, low_right], [20, low_right], [26, _p([low_left, _spin(-40.0)])], [32, low_left],
		[44, low_left], [60, ready]], _action(20, 32, {"grip": true}))
	# L+R un-inked: the Lantern-Keeper's Chime, the staff raised high and rung into the ground.
	var high_ring: Dictionary = _p([raised, ARMS_OVERHEAD, _e({B.SPINE: Vector3(10.0, 0.0, 0.0), B.CHEST: Vector3(8.0, 0.0, 0.0)}), _wpn(B.HAND_R, Vector3(0.0, 1.0, -0.1))])
	_clip(book, "staff_ult_lr_lantern_chime", 80, [[0, ready], [16, raised], [30, high_ring], [38, struck], [44, struck], [60, rang], [80, ready]], _action(30, 44, {"grip": true}))


# --- Scribe Cards ---------------------------------------------------------------

static func _cards(book: Array[Array]) -> void:
	var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_SWORD, L_SHIELD])
	var satchel: Dictionary = _p([ready, L_SATCHEL, _e({B.CHEST: Vector3(0.0, 10.0, 0.0)})])
	var card_up: Dictionary = _p([ready, L_CARD_UP, _e({B.HEAD: Vector3(-6.0, 4.0, 0.0)})])
	var touch: Dictionary = _p([ready, _e({B.CHEST: Vector3(0.0, -12.0, 0.0)}),
		_aim({B.UPPER_ARM_L: Vector3(0.1, -0.35, -0.95), B.FOREARM_L: Vector3(0.75, 0.15, -0.65)})])
	# Through the weapon, each slot its own delivery: a thrust, a low back-step sweep, an overhead chop, a wide arc.
	var deliveries: Array[Dictionary] = [
		_p([LEGS_LUNGE, FEET_FLAT, R_THRUST, L_SHIELD, _e({B.SPINE: Vector3(-12.0, 0.0, 0.0)})]),
		_p([LEGS_WIDE, FEET_FLAT, L_SHIELD, _e({B.CHEST: Vector3(-6.0, 26.0, 0.0)}), _aim({B.UPPER_ARM_R: Vector3(-0.4, -0.6, -0.6), B.FOREARM_R: Vector3(-0.8, -0.4, -0.3)}),
			_wpn(B.HAND_R, Vector3(-0.8, -0.3, 0.4))]),
		_p([LEGS_LUNGE, FEET_FLAT, L_SHIELD, _e({B.SPINE: Vector3(-24.0, 0.0, 0.0)}), _aim({B.UPPER_ARM_R: Vector3(0.08, -0.4, -0.9), B.FOREARM_R: Vector3(0.0, -0.7, -0.7)}),
			_wpn(B.HAND_R, Vector3(0.0, -0.8, -0.6))]),
		_p([LEGS_WIDE, FEET_FLAT, L_SHIELD, _e({B.CHEST: Vector3(0.0, -34.0, 0.0)}), _aim({B.UPPER_ARM_R: Vector3(0.95, 0.1, -0.2), B.FOREARM_R: Vector3(0.9, 0.2, 0.3)}),
			_wpn(B.HAND_R, Vector3(0.7, 0.2, 0.7))]),
	]
	var names: Array[String] = ["card_invoke_forward", "card_invoke_back", "card_invoke_r", "card_invoke_lr"]
	for index: int in names.size():
		_clip(book, names[index], 48, [[0, ready], [6, satchel], [12, card_up], [16, touch], [21, deliveries[index]], [26, deliveries[index]],
			[38, deliveries[index]], [48, ready]], _action(16, 26))
	# At the caster: the card raised overhead in both hands, then planted, arms flung wide.
	var overhead: Dictionary = _p([ready, ARMS_OVERHEAD, _e({B.SPINE: Vector3(8.0, 0.0, 0.0)})])
	var radiate: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.1, 0.0)), _e({B.SPINE: Vector3(-6.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.9, -0.4, -0.2), B.FOREARM_R: Vector3(0.95, -0.2, -0.2), B.UPPER_ARM_L: Vector3(-0.9, -0.4, -0.2),
			B.FOREARM_L: Vector3(-0.95, -0.2, -0.2)}), _wpn(B.HAND_R, Vector3(0.6, 0.6, -0.4))])
	_clip(book, "card_invoke_at_caster", 48, [[0, ready], [6, satchel], [14, overhead], [16, overhead], [20, radiate], [26, radiate], [38, radiate], [48, ready]],
		_action(16, 26))


# --- Defence --------------------------------------------------------------------

static func _defence(book: Array[Array]) -> void:
	var guard: Dictionary = _p([LEGS_WIDE, FEET_FLAT, _hips(Vector3(0.0, -0.12, 0.0)), _e({B.SPINE: Vector3(-8.0, 0.0, 0.0), B.CHEST: Vector3(-2.0, -10.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.35, -0.45, -0.6), B.FOREARM_R: Vector3(-0.45, 0.4, -0.75), B.UPPER_ARM_L: Vector3(-0.3, -0.45, -0.75),
			B.FOREARM_L: Vector3(0.3, 0.25, -0.9)}), _wpn(B.HAND_R, Vector3(-0.6, 0.75, -0.1))])
	var guard_breath: Dictionary = _p([guard, _hips(Vector3(0.0, -0.135, 0.0)), _e({B.CHEST: Vector3(0.0, -10.0, 0.0)})])
	_clip(book, "guard_hold", 30, [[0, guard], [15, guard_breath], [30, guard]], {"loop": true, "grip": true})
	# The Perfect Guard: the shoulder snaps forward in a deflecting bash.
	var bash: Dictionary = _p([guard, _hips(Vector3(0.0, -0.14, 0.0)), _e({B.CHEST: Vector3(-6.0, 14.0, 0.0), B.SPINE: Vector3(-12.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_L: Vector3(-0.1, -0.1, -1.0), B.FOREARM_L: Vector3(0.05, 0.05, -1.0)}), _wpn(B.HAND_R, Vector3(-0.3, 0.5, -0.8))])
	_clip(book, "perfect_guard_parry", 18, [[0, guard], [5, bash], [10, bash], [18, guard]])
	# Shadow Sanctuary: crouched behind the planted guard, both hands bracing.
	var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_SWORD, L_SHIELD])
	var brace: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, _hips(Vector3(0.0, -0.2, 0.0)), _e({B.SPINE: Vector3(-16.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_L: Vector3(-0.2, -0.6, -0.8), B.FOREARM_L: Vector3(0.2, -0.3, -0.95), B.UPPER_ARM_R: Vector3(0.25, -0.55, -0.8),
			B.FOREARM_R: Vector3(-0.3, -0.2, -0.95)}), _wpn(B.HAND_R, Vector3(-0.2, 0.8, -0.4))])
	_clip(book, "shadow_sanctuary_brace", 48, [[0, ready], [12, brace], [16, brace], [26, brace], [40, brace], [48, ready]], _action(16, 26))
	# The dodge roll: a tucked forward somersault, out into a low crouch (0.32 s untouchable).
	var tuck: Dictionary = _p([LEGS_TUCK, _e({B.SPINE: Vector3(-30.0, 0.0, 0.0), B.CHEST: Vector3(-20.0, 0.0, 0.0), B.HEAD: Vector3(-20.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.25, -0.6, -0.75), B.FOREARM_R: Vector3(-0.25, 0.35, -0.85), B.UPPER_ARM_L: Vector3(-0.25, -0.6, -0.75),
			B.FOREARM_L: Vector3(0.25, 0.35, -0.85)})])
	var crouch: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.16, 0.0)), _e({B.SPINE: Vector3(-14.0, 0.0, 0.0)}), R_HANG, L_HANG])
	_clip(book, "dodge_roll_evade", 24, [[0, _p([crouch, _hips(Vector3(0.0, -0.1, 0.0))])], [2, _p([tuck, _hips(Vector3(0.0, -0.3, 0.0)), _e({B.HIPS: Vector3(-50.0, 0.0, 0.0)})])],
		[7, _p([tuck, _hips(Vector3(0.0, -0.42, 0.0)), _e({B.HIPS: Vector3(-140.0, 0.0, 0.0)})])],
		[12, _p([tuck, _hips(Vector3(0.0, -0.48, 0.0)), _e({B.HIPS: Vector3(-230.0, 0.0, 0.0)})])],
		[17, _p([tuck, _hips(Vector3(0.0, -0.38, 0.0)), _e({B.HIPS: Vector3(-320.0, 0.0, 0.0)})])],
		[19, _p([tuck, _hips(Vector3(0.0, -0.3, 0.0)), _e({B.HIPS: Vector3(-360.0, 0.0, 0.0)})])], [24, crouch]],
		_action(2, 19, {"leg_space": "hips", "foot_ik": false}))


# --- Stewardship ------------------------------------------------------------------

static func _stewardship(book: Array[Array]) -> void:
	var ready: Dictionary = _p([LEGS_READY, FEET_FLAT, TORSO_READY, R_SWORD, L_SHIELD])
	# The Hearth-Rite Tuck: down on the right knee, the weapon across the left;
	# a vellum card drawn from the satchel and swept along it; then up, the weapon hoisted high.
	var kneel: Dictionary = _p([LEGS_KNEEL, _e({B.SPINE: Vector3(-8.0, 0.0, 0.0)}), L_SATCHEL,
		_aim({B.UPPER_ARM_R: Vector3(0.25, -0.75, -0.5), B.FOREARM_R: Vector3(-0.55, -0.25, -0.8)}), _wpn(B.HAND_R, Vector3(-0.95, 0.05, -0.2))])
	var card_drawn: Dictionary = _p([kneel, L_CARD_UP, _e({B.HEAD: Vector3(-10.0, -10.0, 0.0)})])
	var at_base: Dictionary = _p([kneel, _aim({B.UPPER_ARM_L: Vector3(-0.1, -0.55, -0.8), B.FOREARM_L: Vector3(0.6, -0.3, -0.75)}), _e({B.HEAD: Vector3(-18.0, 10.0, 0.0)})])
	var swept: Dictionary = _p([kneel, _aim({B.UPPER_ARM_L: Vector3(-0.55, -0.5, -0.65), B.FOREARM_L: Vector3(-0.6, -0.35, -0.7)}), _e({B.HEAD: Vector3(-18.0, 20.0, 0.0)})])
	var rising: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.15, 0.0)), R_SWORD, L_HANG])
	var hoisted: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, 0.0, 0.0)), ARMS_OVERHEAD, _e({B.SPINE: Vector3(6.0, 0.0, 0.0)})])
	_clip(book, "hearth_rite_tuck", 120, [[0, ready], [20, kneel], [40, card_drawn], [70, at_base], [95, swept], [108, rising], [120, hoisted]], {"foot_ik": false})
	# The Truce-Sign Parley: weapon grounded, a hand on the heart, a warm bow, the Sign-leaf raised.
	var calm: Dictionary = _p([LEGS_CALM, FEET_FLAT, TORSO_CALM, R_HANG, L_HANG])
	var heart: Dictionary = _p([calm, _aim({B.UPPER_ARM_R: Vector3(0.3, -0.65, -0.55), B.FOREARM_R: Vector3(-0.85, 0.35, -0.3)}), _wpn(B.HAND_R, Vector3(0.1, -0.9, -0.3))])
	var bow: Dictionary = _p([heart, _e({B.SPINE: Vector3(-30.0, 0.0, 0.0), B.CHEST: Vector3(-8.0, 0.0, 0.0), B.HEAD: Vector3(-10.0, 0.0, 0.0)})])
	var leaf: Dictionary = _p([heart, _aim({B.UPPER_ARM_L: Vector3(-0.2, 1.0, -0.1), B.FOREARM_L: Vector3(-0.05, 1.0, 0.0)}),
		_e({B.SPINE: Vector3(-4.0, 0.0, 0.0), B.HEAD: Vector3(8.0, 0.0, 0.0)})])
	_clip(book, "truce_sign_parley", 48, [[0, ready], [10, heart], [20, bow], [30, heart], [38, leaf], [44, leaf], [48, calm]])
	# The Bravery Counter: coiled, then a lunging Sign-charged strike into the Glimmer-Spot.
	var coiled: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.1, 0.0)), _e({B.CHEST: Vector3(0.0, -30.0, 0.0)}), L_SHIELD,
		_aim({B.UPPER_ARM_R: Vector3(0.6, -0.2, 0.6), B.FOREARM_R: Vector3(0.3, 0.1, -0.95)}), _wpn(B.HAND_R, Vector3(0.0, 0.1, -1.0))])
	var strike: Dictionary = _p([LEGS_LUNGE, FEET_FLAT, R_THRUST, L_SHIELD, _hips(Vector3(0.0, -0.2, 0.0)), {"scale": Vector3(1.05, 0.9, 1.05)},
		_e({B.SPINE: Vector3(-16.0, 0.0, 0.0), B.CHEST: Vector3(-6.0, 12.0, 0.0)})])
	_clip(book, "bravery_counter_strike", 40, [[0, coiled], [8, strike], [16, _p([strike, {"scale": Vector3.ONE}])], [28, ready], [40, ready]])


# --- Reactions and overlays --------------------------------------------------------

static func _reactions(book: Array[Array]) -> void:
	var reel: Dictionary = _p([LEGS_READY, FEET_FLAT, _hips(Vector3(0.0, -0.04, 0.0)),
		_e({B.SPINE: Vector3(12.0, 0.0, 4.0), B.CHEST: Vector3(8.0, 0.0, 0.0), B.HEAD: Vector3(14.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.6, -0.5, 0.5), B.FOREARM_R: Vector3(0.5, -0.3, 0.6), B.UPPER_ARM_L: Vector3(-0.6, -0.5, 0.5), B.FOREARM_L: Vector3(-0.5, -0.3, 0.6)})])
	var sway: Dictionary = _p([reel, _e({B.SPINE: Vector3(8.0, 0.0, -4.0), B.HEAD: Vector3(10.0, 0.0, 6.0)})])
	_clip(book, "stagger_reel", 24, [[0, reel], [12, sway], [24, reel]], {"loop": true})
	var slumped: Dictionary = _p([LEGS_SLUMP, _e({B.SPINE: Vector3(-25.0, 0.0, 0.0), B.CHEST: Vector3(-15.0, 0.0, 0.0), B.HEAD: Vector3(-25.0, 0.0, 0.0)}),
		_aim({B.UPPER_ARM_R: Vector3(0.25, -1.0, -0.25), B.FOREARM_R: Vector3(0.1, -1.0, -0.4), B.UPPER_ARM_L: Vector3(-0.25, -1.0, -0.25),
			B.FOREARM_L: Vector3(-0.1, -1.0, -0.4)})])
	var breath: Dictionary = _p([slumped, _e({B.CHEST: Vector3(-11.0, 0.0, 0.0)})])
	_clip(book, "downed_slump", 60, [[0, slumped], [30, breath], [60, slumped]], {"loop": true, "foot_ik": false})
	# The Overhead Pocket Blessing (right arm): to the coat pocket, up overhead with the card, back.
	var pocket_r: Dictionary = _p([R_HANG, _aim({B.UPPER_ARM_R: Vector3(0.3, -0.8, -0.25), B.FOREARM_R: Vector3(-0.55, -0.4, -0.75)})])
	var overhead: Dictionary = _p([_aim({B.UPPER_ARM_R: Vector3(0.12, 1.0, 0.05), B.FOREARM_R: Vector3(0.04, 1.0, 0.04)}), _wpn(B.HAND_R, Vector3(0.0, 0.0, -1.0))])
	_clip(book, "overhead_pocket_blessing", 90, [[0, R_HANG], [15, pocket_r], [33, overhead], [63, overhead], [78, pocket_r], [90, R_HANG]])
	# The Offhand Pocket-Draw (left arm): to the pocket, the card swept along the weapon, back.
	var pocket_l: Dictionary = _p([_aim({B.UPPER_ARM_L: Vector3(-0.3, -0.85, -0.3), B.FOREARM_L: Vector3(0.45, -0.45, -0.75)})])
	var sweep: Dictionary = _p([_aim({B.UPPER_ARM_L: Vector3(0.15, -0.05, -1.0), B.FOREARM_L: Vector3(0.75, 0.35, -0.55)})])
	_clip(book, "offhand_pocket_draw", 25, [[0, L_SHIELD], [5, pocket_l], [18, sweep], [25, L_SHIELD]])
	# The Pocket-Pull flourish (left arm, 18 frames, the Seal-and-Tuck Grimoire): the hand darts to the
	# pouch by frame 5, whips the card high overhead by 12, and slams its light into the weapon by 18.
	var raise: Dictionary = _p([_aim({B.UPPER_ARM_L: Vector3(-0.2, 1.0, -0.15), B.FOREARM_L: Vector3(0.1, 1.0, -0.1)})])
	var slam: Dictionary = _p([_aim({B.UPPER_ARM_L: Vector3(0.1, -0.2, -1.0), B.FOREARM_L: Vector3(0.6, 0.1, -0.75)})])
	_clip(book, "pocket_pull_flourish", 18, [[0, L_SHIELD], [5, pocket_l], [12, raise], [16, slam], [18, L_SHIELD]])


# --- The Level 1 youth (21_WINGFEATHER_YOUTH_HERO.md §3) ----------------------------

## The youth's gaits: [frames, thigh swing (rad), thigh lean forward, knee bend
## in stance, extra knee fold in swing, pelvis bob, sway, arm swing, elbow
## bend, spine pitch (deg), head pitch (deg), pelvis yaw (deg)].
const YOUTH_WALK_GAIT: Array[float] = [40.0, 0.36, 0.02, 0.08, 0.92, 0.011, 0.012, 0.36, 0.22, -2.0, 2.0, 6.0]
const YOUTH_RUN_GAIT: Array[float] = [26.0, 0.6, 0.16, 0.24, 1.5, 0.022, 0.008, 0.6, 1.35, -10.0, 8.0, 9.0]


static func _youth(book: Array[Array]) -> void:
	_youth_idle(book)
	_youth_gait(book, "locomotion_youth_walk", YOUTH_WALK_GAIT, false)
	_youth_gait(book, "locomotion_youth_run", YOUTH_RUN_GAIT, true)
	_youth_draws(book)


## A country youth at ease: weight on the right hip, the right thumb hooked
## in a brace, the left arm easy. Breathes; looks off left across the
## orchard; glances back over the right shoulder; settles.
static func _youth_idle(book: Array[Array]) -> void:
	var legs: Dictionary = _aim({B.THIGH_R: Vector3(0.05, -1.0, 0.01), B.SHIN_R: Vector3(0.04, -1.0, 0.02),
		B.THIGH_L: Vector3(-0.12, -1.0, -0.08), B.SHIN_L: Vector3(-0.07, -1.0, 0.07)})
	var thumb_in_brace: Dictionary = _aim({B.UPPER_ARM_R: Vector3(0.25, -0.95, 0.15), B.FOREARM_R: Vector3(-0.63, 0.5, -0.58),
		B.HAND_R: Vector3(-0.2, -0.9, -0.35)})
	var easy_left: Dictionary = _aim({B.UPPER_ARM_L: Vector3(-0.11, -1.0, 0.03), B.FOREARM_L: Vector3(-0.04, -0.95, -0.28)})
	var base: Dictionary = _p([legs, FEET_FLAT, thumb_in_brace, easy_left, _hips(Vector3(0.022, -0.008, 0.0)),
		_e({B.HIPS: Vector3(0.0, -4.0, 3.5), B.SPINE: Vector3(-1.0, 1.0, -2.0), B.CHEST: Vector3(0.5, 2.0, -2.0), B.HEAD: Vector3(2.0, 2.0, 4.0)})])
	var breathe: Dictionary = _p([base, _e({B.HIPS: Vector3(0.0, -4.0, 3.5), B.SPINE: Vector3(-0.5, 1.0, -2.0), B.CHEST: Vector3(3.0, 2.0, -2.0),
		B.HEAD: Vector3(0.0, 2.0, 4.0), B.CLAVICLE_L: Vector3(0.0, 0.0, 3.0), B.CLAVICLE_R: Vector3(0.0, 0.0, -3.0)}), _hips(Vector3(0.022, -0.004, 0.0))])
	var look_left: Dictionary = _p([base, _e({B.HIPS: Vector3(0.0, -2.0, 3.0), B.SPINE: Vector3(-1.0, 4.0, -1.5), B.CHEST: Vector3(2.0, 8.0, -1.0),
		B.NECK: Vector3(0.0, 8.0, 0.0), B.HEAD: Vector3(-6.0, 22.0, 2.0)})])
	var look_back: Dictionary = _p([base, _hips(Vector3(0.016, -0.01, 0.0)),
		_e({B.HIPS: Vector3(0.0, -8.0, 2.5), B.SPINE: Vector3(-1.0, -6.0, -2.0), B.CHEST: Vector3(1.0, -10.0, -2.0), B.NECK: Vector3(0.0, -10.0, 0.0),
			B.HEAD: Vector3(4.0, -26.0, -3.0)}),
		_aim({B.UPPER_ARM_L: Vector3(-0.16, -1.0, -0.06), B.FOREARM_L: Vector3(-0.02, -0.9, -0.4)})])
	var settle: Dictionary = _p([base, _hips(Vector3(0.026, -0.012, 0.0)), _e({B.HIPS: Vector3(0.0, -5.0, 4.0), B.CHEST: Vector3(1.5, 1.0, -2.5),
		B.HEAD: Vector3(3.0, -4.0, 6.0)})])
	_clip(book, "idle_youth_calm", 240, [[0, base], [30, breathe], [62, look_left], [88, look_left], [112, breathe], [146, look_back],
		[168, look_back], [196, settle], [220, breathe], [240, base]], {"loop": true})


## One of the youth's gaits, sampled every few frames from smooth curves: the
## left heel strikes on frame 0 and the right halfway, the stance hip rides
## high (the walk) or the body squashes through stance and lofts between
## steps (the run); the pelvis yaws and rolls, the chest counter-turns, the
## arms swing against the legs (pumping, elbows bent, on the run).
static func _youth_gait(book: Array[Array], clip_name: String, gait: Array[float], run: bool) -> void:
	var frames: int = int(gait[0])
	var keys: Array = []
	var samples: int = 13 if run else 10
	for index: int in samples + 1:
		var p: float = float(index) / float(samples)
		var frame: int = roundi(p * float(frames))
		var phase_l: float = TAU * p + PI * 0.5
		var aims: Dictionary = {}
		for side: float in [-1.0, 1.0]:
			var phase: float = phase_l if side < 0.0 else phase_l + PI
			var thigh_angle: float = gait[2] + gait[1] * sin(phase)
			var swing: float = maxf(0.0, cos(phase))
			var knee: float = gait[3] + gait[4] * pow(swing, 1.3)
			if run:
				# The heel kicks up behind as the leg leaves the ground.
				knee += 0.5 * _bump(phase, PI * 1.5 + 0.5, 0.5)
			var out: float = side * (0.035 if run else 0.025)
			aims[B.THIGH_L if side < 0.0 else B.THIGH_R] = Vector3(out, -cos(thigh_angle), -sin(thigh_angle))
			aims[B.SHIN_L if side < 0.0 else B.SHIN_R] = Vector3(out * 0.6, -cos(thigh_angle - knee), -sin(thigh_angle - knee))
			var toe: float = -0.33 + 0.43 * _bump(phase, PI * 0.5, 0.45) - 0.5 * _bump(phase, PI * 1.5 - 0.25, 0.42) + 0.18 * swing
			aims[B.FOOT_L if side < 0.0 else B.FOOT_R] = Vector3(0.0, sin(toe), -cos(toe))
			# The arm on this side swings with the other leg.
			var arm_phase: float = phase + PI
			var beta: float = gait[7] * sin(arm_phase)
			var elbow: float = gait[8] + (0.25 if run else 0.18) * maxf(0.0, sin(arm_phase))
			var across: float = (0.06 if run else 0.0) * maxf(0.0, sin(arm_phase))
			aims[B.UPPER_ARM_L if side < 0.0 else B.UPPER_ARM_R] = Vector3(side * (0.13 - across), -cos(beta), -sin(beta))
			aims[B.FOREARM_L if side < 0.0 else B.FOREARM_R] = Vector3(side * (0.08 - across * 1.5), -cos(beta + elbow), -sin(beta + elbow))
		var stance_l: float = sin(phase_l - PI * 0.5)
		var bob: float = 0.0
		if run:
			# Squashed through the stance (phase_l at PI and 2 PI), lofted between steps.
			bob = -gait[5] * 0.6 - gait[5] * cos(2.0 * (phase_l - PI))
		else:
			bob = -gait[5] * cos(2.0 * (phase_l - PI * 0.5)) - gait[5] * 0.4
		var yaw: float = -gait[11] * sin(phase_l)
		var roll: float = -3.0 * stance_l * (0.6 if run else 1.0)
		var pose: Dictionary = _p([
			{"aim": aims},
			_hips(Vector3(-gait[6] * stance_l, bob, 0.0)),
			_e({B.HIPS: Vector3(0.0, yaw, roll), B.SPINE: Vector3(gait[9], -0.5 * yaw, -0.5 * roll),
				B.CHEST: Vector3(gait[9] * 0.4 + (1.5 if run else 0.5) * absf(stance_l), -1.3 * yaw, -0.6 * roll),
				B.NECK: Vector3(0.0, 0.3 * yaw, 0.0), B.HEAD: Vector3(gait[10], 0.5 * yaw, 0.3 * roll)}),
		])
		keys.append([frame, pose])
	_clip(book, clip_name, frames, keys, {"loop": true})


## How close `phase` is to `center` round the circle: 1 there, falling off over `width` radians.
static func _bump(phase: float, center: float, width: float) -> float:
	var gap: float = wrapf(phase - center, -PI, PI)
	return exp(-pow(gap / width, 2.0))


## The draw as a fight starts (arm overlays): the left hand reaches back over
## the shoulder for the bow and brings it round to the ready; the right hand
## reaches behind the hip for a tool at the belt and brings it up.
static func _youth_draws(book: Array[Array]) -> void:
	var hang_l: Dictionary = _p([_aim({B.UPPER_ARM_L: Vector3(-0.12, -1.0, 0.02), B.FOREARM_L: Vector3(-0.06, -0.95, -0.2)})])
	var over_shoulder: Dictionary = _p([_aim({B.UPPER_ARM_L: Vector3(-0.3, 0.55, 0.55), B.FOREARM_L: Vector3(0.25, 0.85, 0.35)}),
		_wpn(B.HAND_L, Vector3(0.6, -0.2, 0.75))])
	var round_front: Dictionary = _p([_aim({B.UPPER_ARM_L: Vector3(-0.35, -0.45, -0.75), B.FOREARM_L: Vector3(-0.1, -0.2, -1.0)}), _wpn(B.HAND_L, Vector3(0.0, 1.0, 0.0))])
	var ready_l: Dictionary = _p([L_BOW])
	_clip(book, "youth_draw_tool_l", 18, [[0, hang_l], [6, over_shoulder], [12, round_front], [18, ready_l]])
	var hang_r: Dictionary = _p([_aim({B.UPPER_ARM_R: Vector3(0.12, -1.0, 0.02), B.FOREARM_R: Vector3(0.06, -0.95, -0.2)})])
	var behind_hip: Dictionary = _p([_aim({B.UPPER_ARM_R: Vector3(0.3, -0.8, 0.5), B.FOREARM_R: Vector3(0.1, -0.5, 0.86)}), _wpn(B.HAND_R, Vector3(0.0, -0.4, 0.9))])
	var bring_up: Dictionary = _p([_aim({B.UPPER_ARM_R: Vector3(0.35, -0.7, -0.3), B.FOREARM_R: Vector3(0.1, 0.4, -0.9)}), _wpn(B.HAND_R, Vector3(0.0, 0.9, -0.4))])
	var ready_r: Dictionary = _p([R_SWORD])
	_clip(book, "youth_draw_tool_r", 18, [[0, hang_r], [6, behind_hip], [12, bring_up], [18, ready_r]])
