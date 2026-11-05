## The 3-Sign Resonance Barrier across the foot of the One Cliff Stair (docs/20
## Part II §1.3): a shimmering curtain that blocks the only way up the +32 m
## cliff band, with one seal for each of The Crown's trials (Amber, Sea-Azure,
## Twilight-Violet). Each seal lights as its trial is done; with all three
## the curtain falls and the stair is open. While playtesting (--boot-zone,
## F9) light unseals it at once, unsaved.
class_name ResonanceBarrier
extends Interactable

signal unsealed

@export var width: float = 14.0
@export var height: float = 6.0

var _body: StaticBody3D
var _curtain: MeshInstance3D
var _curtain_material: StandardMaterial3D
var _seals: Array[MeshInstance3D] = []
var _label: Label3D
var _was_open: bool = false


func _ready() -> void:
	reach = 3.0
	var frame: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for side: float in [-1.0, 1.0]:
		CalderaKit.add_box(frame, Vector3(side * (width * 0.5 + 0.7), height * 0.5, 0.0), Vector3(1.4, height, 1.6), CalderaKit.BASALT.lightened(0.12))
	CalderaKit.add_box(frame, Vector3(0.0, height + 0.5, 0.0), Vector3(width + 2.8, 1.0, 1.6), CalderaKit.BASALT.lightened(0.18))
	add_child(CalderaKit.mesh_node("Frame", frame))
	_curtain_material = StandardMaterial3D.new()
	_curtain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_curtain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_curtain_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_curtain_material.albedo_color = Color(0.92, 0.84, 1.0, 0.32)
	_curtain = ShapeKit.no_shadow(ShapeKit.box("Curtain", Vector3(width, height, 0.1), Vector3(0.0, height * 0.5, 0.0), _curtain_material))
	add_child(_curtain)
	_body = CalderaKit.solid_box(self, "Seal", Vector3(0.0, height * 0.5, 0.0), Vector3(width + 1.0, height, 1.2))
	var colors: Array[Color] = [CalderaKit.IRON_AMBER, CalderaKit.GALE_AZURE, CalderaKit.TIDE_VIOLET]
	for index: int in 3:
		var disc: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.tilted(ShapeKit.cylinder("SignSeal%d" % index, 0.7, 0.7, 0.12,
			Vector3((float(index) - 1.0) * 2.2, height + 0.5, 0.86), StorybookMaterial.glowing(colors[index], 0.15)), Vector3(PI * 0.5, 0.0, 0.0)))
		add_child(disc)
		_seals.append(disc)
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, height + 2.0, 1.0))
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
	_was_open = is_open()
	_refresh()


func _exit_tree() -> void:
	super._exit_tree()
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


func is_open() -> bool:
	return CalderaWorldState.current != null and CalderaWorldState.current.cliff_stair_open()


## How many of the three trials are done.
func seals_lit() -> int:
	var lit: int = 0
	for trial: StringName in CalderaWorldState.TRIALS:
		lit += 1 if CalderaWorldState.current.trial_complete(trial) else 0
	return lit


func blocks() -> bool:
	return _body.collision_layer != 0


func prompt_for(_actor: ActorBase) -> String:
	if is_open():
		return ""
	if CalderaWorldState.current.playtest:
		return "light: unseal the One Stair (playtest; not saved)"
	return "The One Stair is sealed: %d of 3 trials done" % seals_lit()


func interact(_actor: ActorBase) -> void:
	if is_open() or not CalderaWorldState.current.playtest:
		AudioCues.play(&"refuse")
		return
	for trial: StringName in CalderaWorldState.TRIALS:
		CalderaWorldState.current.complete_trial(trial)


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_refresh()


func _refresh() -> void:
	var trials: Array[StringName] = CalderaWorldState.TRIALS
	var colors: Array[Color] = [CalderaKit.IRON_AMBER, CalderaKit.GALE_AZURE, CalderaKit.TIDE_VIOLET]
	for index: int in 3:
		var done: bool = CalderaWorldState.current != null and CalderaWorldState.current.trial_complete(trials[index])
		_seals[index].material_override = CalderaKit.glow(colors[index], 3.0 if done else 0.15)
	var open: bool = is_open()
	_curtain.visible = not open
	_body.collision_layer = 0 if open else ActorBase.LAYER_WORLD
	reach = 0.0 if open else 3.0
	_label.text = "The One Cliff Stair\n%s" % ("open: climb to the Summit Glade" if open else "sealed by three Signs: %d of 3 trials done" % seals_lit())
	if open and not _was_open:
		AudioCues.play(&"gate")
		unsealed.emit()
	_was_open = open
