## A brass Chime-Bell on a quay (docs/20 Part I §3, Skin B): ring it with
## light and, once its lane is open, a Lantern-Skiff carries the whole party
## across The Sound in a six-second glide (SeamTransitionController). While the
## lane is closed it says why. North Quay has two: the Salt Road to Rime-Firth
## and the Crown Landing to The Crown; each far quay has its bell home.
class_name SkiffBell
extends Interactable

signal rung(actor: ActorBase, bell: SkiffBell)

@export var seam_id: StringName = &""

var swing: float = 0.0
var _bell: Node3D


func _ready() -> void:
	reach = 2.8
	add_to_group(&"map_glyphs")
	var frame: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(frame, Vector3(-0.9, 0.0, 0.0), 0.12, 0.14, 2.9, CalderaKit.DARK_TIMBER, 6)
	CalderaKit.add_post(frame, Vector3(0.9, 0.0, 0.0), 0.12, 0.14, 2.9, CalderaKit.DARK_TIMBER, 6)
	CalderaKit.add_box(frame, Vector3(0.0, 2.95, 0.0), Vector3(2.2, 0.22, 0.3), CalderaKit.TIMBER)
	add_child(CalderaKit.mesh_node("Frame", frame))
	_bell = Node3D.new()
	_bell.name = "Bell"
	_bell.position = Vector3(0.0, 2.85, 0.0)
	add_child(_bell)
	var bronze: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_cone(bronze, Vector3(0.0, -0.95, 0.0), 0.55, 0.85, CalderaKit.BRASS, 12)
	CalderaKit.add_post(bronze, Vector3(0.0, -1.0, 0.0), 0.62, 0.62, 0.14, CalderaKit.BRASS.darkened(0.15), 12)
	CalderaKit.add_sphere(bronze, Vector3(0.0, -1.1, 0.0), 0.12, CalderaKit.DARK_STONE, 1.0, 6)
	_bell.add_child(CalderaKit.mesh_node("Bronze", bronze))
	var current: LoadSeamResource = seam()
	if current != null:
		CalderaKit.sign_label(self, "Sign", "%s\nring the Chime-Bell for the Lantern-Skiff" % current.display_name, Vector3(0.0, 3.6, 0.0))


func seam() -> LoadSeamResource:
	return CalderaAtlas.seam(seam_id)


func is_open() -> bool:
	var current: LoadSeamResource = seam()
	return current != null and CalderaWorldState.current != null and CalderaWorldState.current.lane_open(current.gate_flag)


func prompt_for(_actor: ActorBase) -> String:
	var current: LoadSeamResource = seam()
	if current == null:
		return ""
	if not is_open():
		return current.closed_line
	return "light: ring the Chime-Bell · %s" % current.display_name


func interact(actor: ActorBase) -> void:
	swing = 1.0
	AudioCues.play(&"bell")
	if not is_open():
		AudioCues.play(&"refuse")
		CombatDirector.current.announce(global_position + Vector3.UP * 3.2, seam().closed_line if seam() != null else "", Color(1.0, 0.7, 0.5))
		return
	rung.emit(actor, self)


func _process(delta: float) -> void:
	if swing <= 0.0:
		return
	swing = maxf(0.0, swing - delta * 0.5)
	_bell.rotation.x = sin(swing * 18.0) * 0.5 * swing
