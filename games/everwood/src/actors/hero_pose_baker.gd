## Turns an authored hero pose into each touched bone's local rotation on the
## 24-bone skeleton (HeroCombatAnimator's clips; 19 GDD §3.3).
##
## A pose is a Dictionary of parts:
##   "e"     {bone: Vector3 degrees}  a turn in the bone's own frame (spines,
##                                    necks, heads, hips: x pitch with positive
##                                    leaning back, y yaw with positive turning
##                                    left, z roll with positive tipping left)
##   "aim"   {bone: Vector3}          point the bone along a direction: arm bones
##                                    in the chest's frame, leg bones in the
##                                    ground's (or the hips', for spins and rolls)
##   "wpn"   {hand: Vector3}          turn the hand so its weapon's haft points
##                                    along a direction in the chest's frame
##   "hips"  Vector3                  the hips' offset from rest (metres)
##   "scale" Vector3                  the hips' scale (impact squash-and-stretch)
class_name HeroPoseBaker
extends RefCounted

const B = HeroRigBuilder.Bone
const ARM_BONES: Array[int] = [B.CLAVICLE_L, B.UPPER_ARM_L, B.FOREARM_L, B.HAND_L, B.CLAVICLE_R, B.UPPER_ARM_R, B.FOREARM_R, B.HAND_R]
const LEG_BONES: Array[int] = [B.THIGH_L, B.SHIN_L, B.FOOT_L, B.THIGH_R, B.SHIN_R, B.FOOT_R]
## Left and right partners, for mirroring a pose.
const PARTNERS: Dictionary[int, int] = {
	B.CLAVICLE_L: B.CLAVICLE_R, B.UPPER_ARM_L: B.UPPER_ARM_R, B.FOREARM_L: B.FOREARM_R, B.HAND_L: B.HAND_R,
	B.THIGH_L: B.THIGH_R, B.SHIN_L: B.SHIN_R, B.FOOT_L: B.FOOT_R,
	B.CLAVICLE_R: B.CLAVICLE_L, B.UPPER_ARM_R: B.UPPER_ARM_L, B.FOREARM_R: B.FOREARM_L, B.HAND_R: B.HAND_L,
	B.THIGH_R: B.THIGH_L, B.SHIN_R: B.SHIN_L, B.FOOT_R: B.FOOT_L,
}


## {bone: local pose rotation (rest included)} for every bone the pose touches.
## `leg_space` is "root" (legs aim in the ground's frame) or "hips".
static func bake(pose: Dictionary, leg_space: String = "root") -> Dictionary:
	var rests: Array[Transform3D] = HeroRigBuilder.local_rests()
	var globals: Array[Basis] = []
	globals.resize(HeroRigBuilder.BONE_COUNT)
	var eulers: Dictionary = pose.get("e", {})
	var aims: Dictionary = pose.get("aim", {})
	var weapons: Dictionary = pose.get("wpn", {})
	var baked: Dictionary = {}
	for bone: int in HeroRigBuilder.BONE_COUNT:
		var parent: int = HeroRigBuilder.BONE_PARENTS[bone]
		var parent_basis: Basis = globals[parent] if parent >= 0 else Basis.IDENTITY
		var basis: Basis = parent_basis * rests[bone].basis
		var touched: bool = false
		if eulers.has(bone):
			var turn: Vector3 = eulers[bone]
			basis = basis * Basis.from_euler(Vector3(deg_to_rad(turn.x), deg_to_rad(turn.y), deg_to_rad(turn.z)))
			touched = true
		if aims.has(bone):
			var want: Vector3 = (_space(bone, globals, leg_space) * (aims[bone] as Vector3)).normalized()
			basis = Basis(arc(basis.y.normalized(), want)) * basis
			touched = true
		if weapons.has(bone):
			var haft: Vector3 = (_space(bone, globals, leg_space) * (weapons[bone] as Vector3)).normalized()
			var y: Vector3 = basis.y.normalized()
			var z: Vector3 = haft - y * y.dot(haft)
			if z.length() > 0.05:
				z = z.normalized()
				basis = Basis(y.cross(z), y, z)
			touched = true
		globals[bone] = basis.orthonormalized()
		if touched:
			baked[bone] = (parent_basis.orthonormalized().inverse() * globals[bone]).get_rotation_quaternion().normalized()
	return baked


## The shortest turn taking direction `from` to `to` (both unit vectors).
static func arc(from: Vector3, to: Vector3) -> Quaternion:
	var dot: float = from.dot(to)
	if dot > 0.99999:
		return Quaternion.IDENTITY
	if dot < -0.99999:
		var axis: Vector3 = from.cross(Vector3.RIGHT)
		if axis.length_squared() < 0.0001:
			axis = from.cross(Vector3.UP)
		return Quaternion(axis.normalized(), PI)
	return Quaternion(from, to)


## A pose built from parts: later parts win, and their "e", "aim" and "wpn" bones merge.
static func compose(parts: Array) -> Dictionary:
	var pose: Dictionary = {"e": {}, "aim": {}, "wpn": {}}
	for part: Dictionary in parts:
		for key: String in ["e", "aim", "wpn"]:
			if part.has(key):
				(pose[key] as Dictionary).merge(part[key], true)
		for key: String in ["hips", "scale"]:
			if part.has(key):
				pose[key] = part[key]
	return pose


## The pose mirrored left to right: partners swap, directions flip across the
## body's middle, and turns keep their pitch but flip their yaw and roll.
static func mirror(pose: Dictionary) -> Dictionary:
	var mirrored: Dictionary = {"e": {}, "aim": {}, "wpn": {}}
	for key: String in ["e", "aim", "wpn"]:
		var part: Dictionary = pose.get(key, {})
		for bone: int in part:
			var value: Vector3 = part[bone]
			var to: int = PARTNERS.get(bone, bone)
			(mirrored[key] as Dictionary)[to] = Vector3(value.x, -value.y, -value.z) if key == "e" else Vector3(-value.x, value.y, value.z)
	if pose.has("hips"):
		var hips: Vector3 = pose["hips"]
		mirrored["hips"] = Vector3(-hips.x, hips.y, hips.z)
	if pose.has("scale"):
		mirrored["scale"] = pose["scale"]
	return mirrored


static func _space(bone: int, globals: Array[Basis], leg_space: String) -> Basis:
	if ARM_BONES.has(bone):
		return globals[B.CHEST].orthonormalized()
	if LEG_BONES.has(bone):
		return globals[B.HIPS].orthonormalized() if leg_space == "hips" else globals[B.ROOT].orthonormalized()
	return globals[B.ROOT].orthonormalized()
