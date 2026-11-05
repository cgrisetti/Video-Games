## The timber gate across a causeway's shore end (the West Strait, Eel Spit):
## barred while its lane is dark, swung open once the lane is open. A sign
## says what opens it.
class_name LaneGate
extends Node3D

@export var seam_id: StringName = &""
@export var width: float = 7.0

var _body: StaticBody3D
var _leaves: Array[Node3D] = []
var _label: Label3D


func _ready() -> void:
	var posts: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for side: float in [-1.0, 1.0]:
		CalderaKit.add_post(posts, Vector3(side * (width * 0.5 + 0.3), 0.0, 0.0), 0.28, 0.34, 3.0, CalderaKit.DARK_TIMBER, 6)
		CalderaKit.glow_sphere(self, "Lamp%s" % ("L" if side < 0.0 else "R"), Vector3(side * (width * 0.5 + 0.3), 3.2, 0.0), 0.2, CalderaKit.SAFFRON, 2.2)
	add_child(CalderaKit.mesh_node("Posts", posts))
	for side: float in [-1.0, 1.0]:
		var hinge: Node3D = Node3D.new()
		hinge.name = "Leaf%s" % ("L" if side < 0.0 else "R")
		hinge.position = Vector3(side * width * 0.5, 0.0, 0.0)
		add_child(hinge)
		var boards: LandblockTerrain.MeshMerge = CalderaKit.merge()
		for index: int in 4:
			CalderaKit.add_box(boards, Vector3(-side * (0.45 + index * 0.85), 1.1, 0.0), Vector3(0.8, 2.0, 0.12), CalderaKit.TIMBER)
		CalderaKit.add_beam(boards, Vector3(-side * 0.2, 0.5, 0.08), Vector3(-side * 3.3, 1.8, 0.08), 0.14, CalderaKit.DARK_TIMBER)
		hinge.add_child(CalderaKit.mesh_node("Boards", boards))
		_leaves.append(hinge)
	_body = CalderaKit.solid_box(self, "Bar", Vector3(0.0, 1.2, 0.0), Vector3(width, 2.4, 0.5))
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, 3.6, 0.0))
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
	_refresh()


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


func is_open() -> bool:
	var seam: LoadSeamResource = CalderaAtlas.seam(seam_id)
	return seam != null and CalderaWorldState.current != null and CalderaWorldState.current.lane_open(seam.gate_flag)


func blocks() -> bool:
	return _body.collision_layer != 0


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_refresh()


func _refresh() -> void:
	var open: bool = is_open()
	_body.collision_layer = 0 if open else ActorBase.LAYER_WORLD
	for index: int in _leaves.size():
		_leaves[index].rotation.y = (1.6 if index == 0 else -1.6) if open else 0.0
	var seam: LoadSeamResource = CalderaAtlas.seam(seam_id)
	if seam != null:
		_label.text = "%s\n%s" % [seam.display_name, "open: walk on into the sea-mist" if open else seam.closed_line]
