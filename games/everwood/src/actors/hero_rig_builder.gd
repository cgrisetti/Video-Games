## The canonical 24-bone hero skeleton (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §3.1),
## built in code so every hero, and any drop-in .glb retargeted to it, shares
## one layout, parent before child:
##    0 Root          ground projection          12 UpperArm_R  (11)
##    1 Hips          centre of mass (0)         13 Forearm_R   (12)
##    2 Spine         (1)                        14 Hand_R      (13)  MainHandSocket
##    3 Chest         (2)  BackStowSocket        15 Thigh_L     (1)
##    4 Neck          (3)                        16 Shin_L      (15)
##    5 Head          (4)                        17 Foot_L      (16)
##    6 Jaw_Beard     (5)  the beard's spring    18 Thigh_R     (1)
##    7 Clavicle_L    (3)                        19 Shin_R      (18)
##    8 UpperArm_L    (7)                        20 Foot_R      (19)
##    9 Forearm_L     (8)                        21 Cloak_01    (3)   the cloak's springs
##   10 Hand_L        (9)  OffHandSocket         22 Cloak_02    (21)
##   11 Clavicle_R    (3)                        23 Cloak_03    (22)
## Hips carries the HipSatchelSocket. The four sockets are read-only
## BoneAttachment3Ds (override_pose stays false, so they never fight the
## StorybookKinematicsModifier3D).
##
## Heroes face -Z with their right hand at +X, 4.5 heads tall to a 1.75 m crown.
## Every bone's local +Y points along it toward its child (a leaf toward its
## tail); its local X is the model's +X where it can be, so a positive turn
## about X swings a hanging limb forward and leans an upright bone back.
## The clavicles keep their local Z forward instead, so a positive X turn
## pulls the shoulder forward. Poses on the left side mirror the right as
## (x, -y, -z).
class_name HeroRigBuilder
extends RefCounted

enum Bone {
	ROOT, HIPS, SPINE, CHEST, NECK, HEAD, JAW_BEARD,
	CLAVICLE_L, UPPER_ARM_L, FOREARM_L, HAND_L,
	CLAVICLE_R, UPPER_ARM_R, FOREARM_R, HAND_R,
	THIGH_L, SHIN_L, FOOT_L, THIGH_R, SHIN_R, FOOT_R,
	CLOAK_01, CLOAK_02, CLOAK_03,
}

const BONE_COUNT: int = 24
const SKELETON_NAME: String = "HeroSkeleton3D"
const BONE_NAMES: Array[StringName] = [
	&"Root", &"Hips", &"Spine", &"Chest", &"Neck", &"Head", &"Jaw_Beard",
	&"Clavicle_L", &"UpperArm_L", &"Forearm_L", &"Hand_L",
	&"Clavicle_R", &"UpperArm_R", &"Forearm_R", &"Hand_R",
	&"Thigh_L", &"Shin_L", &"Foot_L", &"Thigh_R", &"Shin_R", &"Foot_R",
	&"Cloak_01", &"Cloak_02", &"Cloak_03",
]
const BONE_PARENTS: Array[int] = [-1, 0, 1, 2, 3, 4, 5, 3, 7, 8, 9, 3, 11, 12, 13, 1, 15, 16, 1, 18, 19, 3, 21, 22]
## Each bone's head at rest, in model space (metres).
const BONE_HEADS: Array[Vector3] = [
	Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.94, 0.0), Vector3(0.0, 1.06, 0.0), Vector3(0.0, 1.24, 0.0),
	Vector3(0.0, 1.42, 0.0), Vector3(0.0, 1.49, -0.01), Vector3(0.0, 1.45, -0.11),
	Vector3(-0.04, 1.38, -0.01), Vector3(-0.21, 1.37, 0.0), Vector3(-0.27, 1.08, 0.01), Vector3(-0.30, 0.83, -0.01),
	Vector3(0.04, 1.38, -0.01), Vector3(0.21, 1.37, 0.0), Vector3(0.27, 1.08, 0.01), Vector3(0.30, 0.83, -0.01),
	Vector3(-0.11, 0.90, 0.0), Vector3(-0.115, 0.50, -0.01), Vector3(-0.12, 0.09, 0.02),
	Vector3(0.11, 0.90, 0.0), Vector3(0.115, 0.50, -0.01), Vector3(0.12, 0.09, 0.02),
	Vector3(0.0, 1.38, 0.15), Vector3(0.0, 1.06, 0.21), Vector3(0.0, 0.74, 0.25),
]
## Where a leaf bone (one with no child to point at) points, in model space.
const LEAF_TAILS: Dictionary[int, Vector3] = {
	Bone.HEAD: Vector3(0.0, 1.75, -0.01),
	Bone.JAW_BEARD: Vector3(0.0, 1.30, -0.14),
	Bone.HAND_L: Vector3(-0.31, 0.70, -0.02),
	Bone.HAND_R: Vector3(0.31, 0.70, -0.02),
	Bone.FOOT_L: Vector3(-0.12, 0.03, -0.15),
	Bone.FOOT_R: Vector3(0.12, 0.03, -0.15),
	Bone.CLOAK_03: Vector3(0.0, 0.42, 0.28),
}
## The child each non-leaf bone points at (its first child in the table).
const BONE_AIMS: Dictionary[int, int] = {
	Bone.ROOT: Bone.HIPS, Bone.HIPS: Bone.SPINE, Bone.SPINE: Bone.CHEST, Bone.CHEST: Bone.NECK, Bone.NECK: Bone.HEAD,
	Bone.CLAVICLE_L: Bone.UPPER_ARM_L, Bone.UPPER_ARM_L: Bone.FOREARM_L, Bone.FOREARM_L: Bone.HAND_L,
	Bone.CLAVICLE_R: Bone.UPPER_ARM_R, Bone.UPPER_ARM_R: Bone.FOREARM_R, Bone.FOREARM_R: Bone.HAND_R,
	Bone.THIGH_L: Bone.SHIN_L, Bone.SHIN_L: Bone.FOOT_L, Bone.THIGH_R: Bone.SHIN_R, Bone.SHIN_R: Bone.FOOT_R,
	Bone.CLOAK_01: Bone.CLOAK_02, Bone.CLOAK_02: Bone.CLOAK_03,
}
## The four sockets: name, bone.
const SOCKETS: Array[Array] = [
	["MainHandSocket", Bone.HAND_R], ["OffHandSocket", Bone.HAND_L], ["BackStowSocket", Bone.CHEST], ["HipSatchelSocket", Bone.HIPS],
]
const MAIN_HAND_SOCKET: StringName = &"MainHandSocket"
const OFF_HAND_SOCKET: StringName = &"OffHandSocket"
const BACK_STOW_SOCKET: StringName = &"BackStowSocket"
const HIP_SATCHEL_SOCKET: StringName = &"HipSatchelSocket"
## Bones on the left whose poses mirror the right's: left -> right.
const MIRRORS: Dictionary[int, int] = {
	Bone.CLAVICLE_L: Bone.CLAVICLE_R, Bone.UPPER_ARM_L: Bone.UPPER_ARM_R, Bone.FOREARM_L: Bone.FOREARM_R, Bone.HAND_L: Bone.HAND_R,
	Bone.THIGH_L: Bone.THIGH_R, Bone.SHIN_L: Bone.SHIN_R, Bone.FOOT_L: Bone.FOOT_R,
}

static var _rest_cache: Array[Transform3D] = []
static var _global_rest_cache: Array[Transform3D] = []


## The skeleton, its 24 bones at rest, the hero's shared Skin, and the four sockets.
static func build_hero_skeleton() -> Skeleton3D:
	var skeleton: Skeleton3D = Skeleton3D.new()
	skeleton.name = SKELETON_NAME
	for index: int in BONE_COUNT:
		skeleton.add_bone(String(BONE_NAMES[index]))
	var rests: Array[Transform3D] = local_rests()
	for index: int in BONE_COUNT:
		if BONE_PARENTS[index] >= 0:
			skeleton.set_bone_parent(index, BONE_PARENTS[index])
		skeleton.set_bone_rest(index, rests[index])
	skeleton.reset_bone_poses()
	# The animator writes the pose, then advances the skeleton itself so the modifiers run on it that same tick.
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.set_meta(&"skin", skeleton.create_skin_from_rest_transforms())
	for socket: Array in SOCKETS:
		var attachment: BoneAttachment3D = BoneAttachment3D.new()
		attachment.name = socket[0]
		skeleton.add_child(attachment)
		attachment.bone_name = String(BONE_NAMES[socket[1]])
		attachment.override_pose = false
	return skeleton


## The Skin build_hero_skeleton made for this skeleton (shared by all its surfaces).
static func skin_of(skeleton: Skeleton3D) -> Skin:
	return skeleton.get_meta(&"skin", null) as Skin


static func bone_name(bone: int) -> StringName:
	return BONE_NAMES[bone]


static func socket(skeleton: Skeleton3D, socket_name: StringName) -> BoneAttachment3D:
	return skeleton.get_node_or_null(NodePath(String(socket_name))) as BoneAttachment3D


## Every bone's rest relative to its parent.
static func local_rests() -> Array[Transform3D]:
	if _rest_cache.is_empty():
		var globals: Array[Transform3D] = global_rests()
		for index: int in BONE_COUNT:
			var parent: int = BONE_PARENTS[index]
			_rest_cache.append(globals[index] if parent < 0 else globals[parent].affine_inverse() * globals[index])
	return _rest_cache


## Every bone's rest in model space: its head, its +Y along the bone.
static func global_rests() -> Array[Transform3D]:
	if _global_rest_cache.is_empty():
		for index: int in BONE_COUNT:
			_global_rest_cache.append(Transform3D(_rest_basis(index), BONE_HEADS[index]))
	return _global_rest_cache


## Where a bone points at rest, in model space (a unit vector).
static func rest_direction(bone: int) -> Vector3:
	return (tail_of(bone) - BONE_HEADS[bone]).normalized()


## The far end of a bone at rest: its child's head, or its leaf tail.
static func tail_of(bone: int) -> Vector3:
	if BONE_AIMS.has(bone):
		return BONE_HEADS[BONE_AIMS[bone]]
	return LEAF_TAILS.get(bone, BONE_HEADS[bone] + Vector3.UP * 0.1)


## A bone's length at rest.
static func bone_length(bone: int) -> float:
	return BONE_HEADS[bone].distance_to(tail_of(bone))


static func _rest_basis(bone: int) -> Basis:
	var y: Vector3 = rest_direction(bone)
	if bone == Bone.CLAVICLE_L or bone == Bone.CLAVICLE_R:
		# Clavicles lie along X, so their roll comes from forward: local Z points the hero's way.
		var forward: Vector3 = Vector3.FORWARD
		var x: Vector3 = y.cross(forward).normalized()
		return Basis(x, y, x.cross(y)).orthonormalized()
	var reference: Vector3 = Vector3.RIGHT
	if absf(y.dot(reference)) > 0.95:
		reference = Vector3.FORWARD
	var side: Vector3 = (reference - y * y.dot(reference)).normalized()
	return Basis(side, y, side.cross(y)).orthonormalized()
