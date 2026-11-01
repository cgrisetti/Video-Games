## The Bronze Bridge-Bell Winch before the Sinaya Gatehouse portcullis
## (07_EXPEDITION_HUD_AND_ART_GDD.md §3, Zone 2). The gale out of the gatehouse
## blows right across it, so it can only be rung from shelter: stand inside a
## Shield-Sworn's Shadow Sanctuary and press light, and the gate opens.
## Built in code; CoopGate owns it and decides.
class_name BellWinch
extends Interactable

signal ring_requested(actor: ActorBase)

const FRAME_COLOR: Color = Color(0.4, 0.28, 0.17)
const BELL_COLOR: Color = Color(0.72, 0.5, 0.24)
const FRAME_HEIGHT: float = 2.6

var _bell: Node3D


func _ready() -> void:
	reach = 2.4
	var timber: StandardMaterial3D = StandardMaterial3D.new()
	timber.albedo_color = FRAME_COLOR
	timber.roughness = 0.85
	for side: float in [-1.0, 1.0]:
		add_child(_box("Post", Vector3(0.18, FRAME_HEIGHT, 0.18), Vector3(side * 0.7, FRAME_HEIGHT * 0.5, 0.0), timber))
	add_child(_box("Beam", Vector3(1.7, 0.18, 0.2), Vector3(0.0, FRAME_HEIGHT, 0.0), timber))
	var drum: CylinderMesh = CylinderMesh.new()
	drum.top_radius = 0.22
	drum.bottom_radius = 0.22
	drum.height = 1.2
	drum.material = timber
	var winch: MeshInstance3D = MeshInstance3D.new()
	winch.name = "Drum"
	winch.mesh = drum
	winch.position = Vector3(0.0, 1.0, 0.0)
	winch.rotation = Vector3(0.0, 0.0, PI * 0.5)
	add_child(winch)
	_bell = Node3D.new()
	_bell.name = "Bell"
	_bell.position = Vector3(0.0, FRAME_HEIGHT - 0.1, 0.0)
	add_child(_bell)
	var bronze: StandardMaterial3D = StandardMaterial3D.new()
	bronze.albedo_color = BELL_COLOR
	bronze.metallic = 0.7
	bronze.roughness = 0.35
	var cup: CylinderMesh = CylinderMesh.new()
	cup.top_radius = 0.16
	cup.bottom_radius = 0.38
	cup.height = 0.55
	cup.material = bronze
	var bell: MeshInstance3D = MeshInstance3D.new()
	bell.name = "Cup"
	bell.mesh = cup
	bell.position = Vector3(0.0, -0.35, 0.0)
	_bell.add_child(bell)


## Swings the bell (every peer, when the gate opens by the winch).
func ring() -> void:
	AudioCues.play(&"bell")
	var swing: Tween = create_tween()
	swing.tween_property(_bell, "rotation:z", 0.6, 0.15)
	swing.tween_property(_bell, "rotation:z", -0.45, 0.3)
	swing.tween_property(_bell, "rotation:z", 0.0, 0.4)


func prompt_for(actor: ActorBase) -> String:
	if CombatDirector.current.is_sheltered(actor):
		return "%s: ring the Bridge-Bell" % actor.input.label(InputComponent.ACTION_LIGHT)
	return "The gale is too strong! Stand in a Shield-Sworn's Shadow Sanctuary to ring the bell"


func interact(actor: ActorBase) -> void:
	ring_requested.emit(actor)


func _box(box_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var box: MeshInstance3D = MeshInstance3D.new()
	box.name = box_name
	box.mesh = mesh
	box.position = where
	return box
