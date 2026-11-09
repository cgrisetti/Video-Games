## The kin's skeletons, built in code from a look's proportions (docs/30 §6).
## Five families share every clip in KinClipBook by bone name:
##   QUADRUPED  26 bones: Root, Hips, Spine, Chest, Neck, Head, Jaw, Ear_L/R,
##              Tail_1..3, the forelegs (Upper, Fore, Paw _FL/_FR) and the hind
##              legs (Thigh, Shank, Hock, Paw _HL/_HR). Hounds, padfoots,
##              bristle-hobs, buccas, the Taproot Stag, the Cairn-Drake.
##   HEXAPOD    27 bones: Root, Body, Abdomen, Tail_1/2, Head, Snout,
##              Antenna_L/R, and six legs (Coxa, Tibia, Foot by pair 1 to 3,
##              L/R). Weevils, barnacle scuttlers, thorn-tails.
##   BIPED      the heroes' own 24 bones at their own rest (HeroRigBuilder),
##              scaled to the kin's height: Ash-Grigs, Iron-Men, Tide-Wights,
##              Spriggans, Bog-Hulks. The cloak bones carry a tail or a robe.
##   STALK      12 bones: Root, Base, Stalk_1..5, Head, and two whips
##              (Whip_L1/L2, Whip_R1/R2). Root-Lurkers, Bramble-Lashers.
##   BLOB       13 bones: Root, Base, Belly, Crown, Cap, the arms (Arm_L1/L2,
##              Arm_R1/R2), the feet (Foot_L/R) and two drips. Sap-Boggarts,
##              Spore-Puff Lobs.
class_name KinRigBuilder
extends RefCounted

enum Rig { QUADRUPED, HEXAPOD, BIPED, STALK, BLOB }

const SKELETON_NAME: String = "KinSkeleton3D"


## The rig for a look's frame (KinLooks): {"rig": Rig, and the family's points}.
static func build(frame: Dictionary) -> KinRig:
	match int(frame.get("rig", Rig.QUADRUPED)):
		Rig.HEXAPOD:
			return hexapod(frame)
		Rig.BIPED:
			return biped()
		Rig.STALK:
			return stalk(frame)
		Rig.BLOB:
			return blob(frame)
	return quadruped(frame)


## Four legs. Points are the right side's (the left mirrors them): "hips", "chest",
## "neck", "head", "snout", "ear", "ear_tip", "tail" (three points and a tip),
## "shoulder", "elbow", "wrist", "toe_f", "hip", "knee", "hock", "fetlock", "toe_h".
static func quadruped(f: Dictionary) -> KinRig:
	var r: KinRig = KinRig.new()
	r.rig = Rig.QUADRUPED
	var hips: Vector3 = f["hips"]
	var chest: Vector3 = f["chest"]
	r.add(&"Root", &"", Vector3.ZERO)
	r.add(&"Hips", &"Root", hips)
	r.add(&"Spine", &"Hips", hips.lerp(chest, 0.5) + Vector3.UP * float(f.get("arch", 0.04)))
	r.add(&"Chest", &"Spine", chest)
	r.add(&"Neck", &"Chest", f["neck"])
	r.add(&"Head", &"Neck", f["head"])
	r.add(&"Jaw", &"Head", (f["head"] as Vector3).lerp(f["snout"], 0.35) + Vector3.DOWN * float(f.get("jaw_drop", 0.03)))
	r.tail(&"Jaw", f["snout"])
	for side: float in [-1.0, 1.0]:
		var s: String = "_L" if side < 0.0 else "_R"
		r.add(StringName("Ear" + s), &"Head", _m(f["ear"], side))
		r.tail(StringName("Ear" + s), _m(f["ear_tip"], side))
	var tail: Array = f["tail"]
	r.add(&"Tail_1", &"Hips", tail[0])
	r.add(&"Tail_2", &"Tail_1", tail[1])
	r.add(&"Tail_3", &"Tail_2", tail[2])
	r.tail(&"Tail_3", tail[3])
	for side: float in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		r.add(StringName("Upper_F" + s), &"Chest", _m(f["shoulder"], side))
		r.add(StringName("Fore_F" + s), StringName("Upper_F" + s), _m(f["elbow"], side))
		r.add(StringName("Paw_F" + s), StringName("Fore_F" + s), _m(f["wrist"], side))
		r.tail(StringName("Paw_F" + s), _m(f["toe_f"], side))
	for side: float in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		r.add(StringName("Thigh_H" + s), &"Hips", _m(f["hip"], side))
		r.add(StringName("Shank_H" + s), StringName("Thigh_H" + s), _m(f["knee"], side))
		r.add(StringName("Hock_H" + s), StringName("Shank_H" + s), _m(f["hock"], side))
		r.add(StringName("Paw_H" + s), StringName("Hock_H" + s), _m(f["fetlock"], side))
		r.tail(StringName("Paw_H" + s), _m(f["toe_h"], side))
	r.finish()
	return r


## Six legs: "body", "abdomen" (and "abdomen_tip"), "tail" (two points and a tip, or
## none), "head", "snout" (and "snout_tip"), "antenna" and "antenna_tip", and each
## right leg pair i (1 front to 3 back) as "leg1" .. "leg3": [coxa, knee, ankle, toe].
static func hexapod(f: Dictionary) -> KinRig:
	var r: KinRig = KinRig.new()
	r.rig = Rig.HEXAPOD
	r.add(&"Root", &"", Vector3.ZERO)
	r.add(&"Body", &"Root", f["body"])
	r.add(&"Abdomen", &"Body", f["abdomen"])
	var tail: Array = f.get("tail", [])
	if tail.size() >= 3:
		r.add(&"Tail_1", &"Abdomen", tail[0])
		r.add(&"Tail_2", &"Tail_1", tail[1])
		r.tail(&"Tail_2", tail[2])
	else:
		r.add(&"Tail_1", &"Abdomen", f["abdomen_tip"])
		r.add(&"Tail_2", &"Tail_1", (f["abdomen_tip"] as Vector3) + Vector3.BACK * 0.02)
		r.tail(&"Tail_2", (f["abdomen_tip"] as Vector3) + Vector3.BACK * 0.04)
	r.add(&"Head", &"Body", f["head"])
	r.add(&"Snout", &"Head", f["snout"])
	r.tail(&"Snout", f["snout_tip"])
	for side: float in [-1.0, 1.0]:
		var s: String = "_L" if side < 0.0 else "_R"
		r.add(StringName("Antenna" + s), &"Head", _m(f["antenna"], side))
		r.tail(StringName("Antenna" + s), _m(f["antenna_tip"], side))
	for pair: int in [1, 2, 3]:
		var leg: Array = f["leg%d" % pair]
		for side: float in [-1.0, 1.0]:
			var s: String = "L%d" % pair if side < 0.0 else "R%d" % pair
			r.add(StringName("Coxa_" + s), &"Body", _m(leg[0], side))
			r.add(StringName("Tibia_" + s), StringName("Coxa_" + s), _m(leg[1], side))
			r.add(StringName("Foot_" + s), StringName("Tibia_" + s), _m(leg[2], side))
			r.tail(StringName("Foot_" + s), _m(leg[3], side))
	r.finish()
	return r


## The heroes' own 24-bone rest (HeroRigBuilder): hero poses bake straight onto it.
static func biped() -> KinRig:
	var r: KinRig = KinRig.new()
	r.rig = Rig.BIPED
	for index: int in HeroRigBuilder.BONE_COUNT:
		var parent: int = HeroRigBuilder.BONE_PARENTS[index]
		r.add(HeroRigBuilder.BONE_NAMES[index], HeroRigBuilder.BONE_NAMES[parent] if parent >= 0 else &"", HeroRigBuilder.BONE_HEADS[index])
	for bone: int in HeroRigBuilder.LEAF_TAILS:
		r.leaf_tails[bone] = HeroRigBuilder.LEAF_TAILS[bone]
	r.finish(HeroRigBuilder.global_rests())
	return r


## A stalk out of the ground: "base", "stalk" (five points), "head", "head_tip",
## and the right whip "whip" [root, mid, tip] (the left mirrors it).
static func stalk(f: Dictionary) -> KinRig:
	var r: KinRig = KinRig.new()
	r.rig = Rig.STALK
	r.add(&"Root", &"", Vector3.ZERO)
	r.add(&"Base", &"Root", f["base"])
	var points: Array = f["stalk"]
	var parent: StringName = &"Base"
	for index: int in 5:
		var bone_name: StringName = StringName("Stalk_%d" % (index + 1))
		r.add(bone_name, parent, points[index])
		parent = bone_name
	r.add(&"Head", parent, f["head"])
	r.tail(&"Head", f["head_tip"])
	var whip: Array = f["whip"]
	for side: float in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		r.add(StringName("Whip_%s1" % s), StringName("Stalk_%d" % int(f.get("whip_from", 2))), _m(whip[0], side))
		r.add(StringName("Whip_%s2" % s), StringName("Whip_%s1" % s), _m(whip[1], side))
		r.tail(StringName("Whip_%s2" % s), _m(whip[2], side))
	r.finish()
	return r


## A mound: "base", "belly", "crown", "cap", "cap_tip", the right arm "arm"
## [shoulder, elbow, hand tip], the right foot "foot" [hip, toe], and "drip" [top, tip].
static func blob(f: Dictionary) -> KinRig:
	var r: KinRig = KinRig.new()
	r.rig = Rig.BLOB
	r.add(&"Root", &"", Vector3.ZERO)
	r.add(&"Base", &"Root", f["base"])
	r.add(&"Belly", &"Base", f["belly"])
	r.add(&"Crown", &"Belly", f["crown"])
	r.add(&"Cap", &"Crown", f["cap"])
	r.tail(&"Cap", f["cap_tip"])
	var arm: Array = f["arm"]
	var foot: Array = f["foot"]
	for side: float in [-1.0, 1.0]:
		var s: String = "L" if side < 0.0 else "R"
		r.add(StringName("Arm_%s1" % s), &"Belly", _m(arm[0], side))
		r.add(StringName("Arm_%s2" % s), StringName("Arm_%s1" % s), _m(arm[1], side))
		r.tail(StringName("Arm_%s2" % s), _m(arm[2], side))
	for side: float in [-1.0, 1.0]:
		var s: String = "_L" if side < 0.0 else "_R"
		r.add(StringName("Foot" + s), &"Base", _m(foot[0], side))
		r.tail(StringName("Foot" + s), _m(foot[1], side))
	var drip: Array = f["drip"]
	r.add(&"Drip_1", &"Belly", drip[0])
	r.add(&"Drip_2", &"Drip_1", drip[0].lerp(drip[1], 0.5))
	r.tail(&"Drip_2", drip[1])
	r.finish()
	return r


## A right-side point mirrored to the left when `side` is negative.
static func _m(point: Vector3, side: float) -> Vector3:
	return Vector3(point.x * (1.0 if side > 0.0 else -1.0), point.y, point.z)
