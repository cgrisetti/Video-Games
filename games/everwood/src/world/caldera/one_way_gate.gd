## A gate across a road that opens from one side only and then stays open
## (docs/27 §7, §9: Embershore's Downs Gate, barred from Mill-Downs until a
## party comes up to it from Hearthstead). Posts, two leaves and a bar like a
## lane gate; a party member standing on its open side within OPEN_REACH sets
## its world flag (the host decides), and the flag swings it open everywhere.
class_name OneWayGate
extends Node3D

signal opened

const OPEN_REACH: float = 6.0

## The CalderaWorldState flag that keeps it open.
@export var flag: StringName = &""
@export var width: float = 6.0
## The side it opens from, in its own frame (+Z is its local front).
@export var open_side: Vector3 = Vector3(0.0, 0.0, 1.0)
@export var closed_line: String = "Barred from this side"
@export var open_line: String = "Open"

var _body: StaticBody3D
var _leaves: Array[Node3D] = []
var _label: Label3D


func _ready() -> void:
	var posts: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for side: float in [-1.0, 1.0]:
		CalderaKit.add_post(posts, Vector3(side * (width * 0.5 + 0.3), 0.0, 0.0), 0.3, 0.36, 3.2, CalderaKit.STONE, 6)
		CalderaKit.add_box(posts, Vector3(side * (width * 0.5 + 0.3), 3.3, 0.0), Vector3(0.9, 0.3, 0.9), CalderaKit.DARK_STONE)
	add_child(CalderaKit.mesh_node("Posts", posts))
	for side: float in [-1.0, 1.0]:
		var hinge: Node3D = Node3D.new()
		hinge.name = "Leaf%s" % ("L" if side < 0.0 else "R")
		hinge.position = Vector3(side * width * 0.5, 0.0, 0.0)
		add_child(hinge)
		var boards: LandblockTerrain.MeshMerge = CalderaKit.merge()
		for index: int in 3:
			CalderaKit.add_box(boards, Vector3(-side * (0.5 + index * 0.95), 1.1, 0.0), Vector3(0.9, 2.1, 0.12), CalderaKit.TIMBER)
		CalderaKit.add_beam(boards, Vector3(-side * 0.2, 0.4, 0.08), Vector3(-side * (width * 0.5 - 0.2), 1.9, 0.08), 0.14, CalderaKit.DARK_TIMBER)
		hinge.add_child(CalderaKit.mesh_node("Boards", boards))
		_leaves.append(hinge)
	_body = CalderaKit.solid_box(self, "Bar", Vector3(0.0, 1.2, 0.0), Vector3(width, 2.4, 0.5))
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, 3.9, 0.0))
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
	_refresh()


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


func is_open() -> bool:
	return CalderaWorldState.current != null and CalderaWorldState.current.get_flag(flag)


func blocks() -> bool:
	return _body.collision_layer != 0


func _physics_process(_delta: float) -> void:
	if is_open() or CombatDirector.current == null:
		return
	var open_dir: Vector3 = (global_transform.basis * open_side).normalized()
	for member: ActorBase in CombatDirector.current.party_actors():
		var offset: Vector3 = member.global_position - global_position
		if offset.length() <= OPEN_REACH and offset.dot(open_dir) > 0.8:
			if CalderaWorldState.current.set_flag(flag, true):
				opened.emit()
			return


func _on_flag_changed(changed: StringName, _value: bool) -> void:
	if changed == flag:
		_refresh()


func _refresh() -> void:
	var open: bool = is_open()
	_body.collision_layer = 0 if open else ActorBase.LAYER_WORLD
	for index: int in _leaves.size():
		_leaves[index].rotation.y = (1.6 if index == 0 else -1.6) if open else 0.0
	_label.text = open_line if open else closed_line
