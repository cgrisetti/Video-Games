## One kin's skeleton at rest (docs/30_KIN_DESIGN_LANGUAGE.md §6): its bones'
## names, parents and heads in model space, built by KinRigBuilder from a kin
## look's proportions. The same conventions as the heroes' HeroRigBuilder:
## kin face -Z with their right side at +X; every bone's local +Y points along
## it toward its child (a leaf toward its tail), and its local X is the model's
## +X where it can be, so a positive turn about X swings a hanging limb forward,
## leans an upright bone back, lifts a bone that points forward and droops one
## that points back; a positive turn about Z turns a forward bone to its left.
## Two-legged kin wear the heroes' own 24-bone rest, so hero poses fit them.
class_name KinRig
extends RefCounted

## Which family of skeleton (KinRigBuilder.Rig).
var rig: int = 0
var names: Array[StringName] = []
var parents: PackedInt32Array = PackedInt32Array()
var heads: PackedVector3Array = PackedVector3Array()
## Where a leaf bone (one with no child to point at) points.
var leaf_tails: Dictionary[int, Vector3] = {}
## Each bone's rest in model space and relative to its parent.
var globals: Array[Transform3D] = []
var locals: Array[Transform3D] = []
## Left bone -> right partner, for mirrored poses.
var mirrors: Dictionary[int, int] = {}

var _index: Dictionary[StringName, int] = {}
var _aims: Dictionary[int, int] = {}


## Adds a bone (its parent by name, &"" for the root) with its head at `head`.
func add(bone_name: StringName, parent_name: StringName, head: Vector3) -> int:
	var index: int = names.size()
	names.append(bone_name)
	parents.append(_index.get(parent_name, -1) if parent_name != &"" else -1)
	heads.append(head)
	_index[bone_name] = index
	return index


## A leaf bone's tail (where it points).
func tail(bone_name: StringName, where: Vector3) -> void:
	leaf_tails[_index[bone_name]] = where


## The bone's index by name (-1 when this skeleton has none).
func b(bone_name: StringName) -> int:
	return _index.get(bone_name, -1)


func has(bone_name: StringName) -> bool:
	return _index.has(bone_name)


func count() -> int:
	return names.size()


## Works out every rest once the bones are in. `fixed` (the heroes' own) wins when given.
func finish(fixed: Array[Transform3D] = []) -> void:
	_aims.clear()
	for index: int in names.size():
		var parent: int = parents[index]
		if parent >= 0 and not _aims.has(parent):
			_aims[parent] = index
	globals.clear()
	locals.clear()
	for index: int in names.size():
		globals.append(fixed[index] if not fixed.is_empty() else Transform3D(_rest_basis(index), heads[index]))
	for index: int in names.size():
		var parent: int = parents[index]
		locals.append(globals[index] if parent < 0 else globals[parent].affine_inverse() * globals[index])
	mirrors.clear()
	for index: int in names.size():
		var text: String = String(names[index])
		for pair: Array in [["_L", "_R"], ["_FL", "_FR"], ["_HL", "_HR"], ["L1", "R1"], ["L2", "R2"], ["L3", "R3"]]:
			if text.ends_with(pair[0]):
				var partner: StringName = StringName(text.substr(0, text.length() - String(pair[0]).length()) + pair[1])
				if _index.has(partner):
					mirrors[index] = _index[partner]


## The far end of a bone at rest: its first child's head, or its leaf tail.
func tail_of(bone: int) -> Vector3:
	if _aims.has(bone):
		return heads[_aims[bone]]
	return leaf_tails.get(bone, heads[bone] + Vector3.UP * 0.1)


func bone_length(bone: int) -> float:
	return heads[bone].distance_to(tail_of(bone))


## The middle of a bone at rest (where an aura shell or a socket sits).
func middle_of(bone: int) -> Vector3:
	return (heads[bone] + tail_of(bone)) * 0.5


## The skeleton at rest, its shared Skin (meta "skin"), posed by hand (KinAnimator writes it).
func build_skeleton(skeleton_name: String) -> Skeleton3D:
	var skeleton: Skeleton3D = Skeleton3D.new()
	skeleton.name = skeleton_name
	for bone_name: StringName in names:
		skeleton.add_bone(String(bone_name))
	for index: int in names.size():
		if parents[index] >= 0:
			skeleton.set_bone_parent(index, parents[index])
		skeleton.set_bone_rest(index, locals[index])
	skeleton.reset_bone_poses()
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.set_meta(&"skin", skeleton.create_skin_from_rest_transforms())
	return skeleton


func _rest_basis(bone: int) -> Basis:
	var y: Vector3 = (tail_of(bone) - heads[bone]).normalized()
	if y.length_squared() < 0.5:
		y = Vector3.UP
	var reference: Vector3 = Vector3.RIGHT
	if absf(y.dot(reference)) > 0.95:
		reference = Vector3.FORWARD
	var side: Vector3 = (reference - y * y.dot(reference)).normalized()
	return Basis(side, y, side.cross(y)).orthonormalized()
