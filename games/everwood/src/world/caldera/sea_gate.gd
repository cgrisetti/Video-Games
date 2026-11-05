## A sealed gate the Ebb bares (docs/20 Part I §2, Part II area 7): a
## barnacled sea-arch at -4.5 m on an outer shore, under the Long Flood's sea
## until the Harmonic Bell rings and the water falls to -6 m. The three friction
## isles each hide a raid gate (A: the Under-Forge Abyss, B: the Frost-Peak
## Aerie, C: the Sunken Cathedral); The Crown's east shore hides the Sea-Door
## to the Heart. Its red seal glows once bared. A gate's raid that isn't built
## yet says so; the Sea-Door's threshold leads down into the Sap Galleries.
class_name SeaGate
extends Node3D

## The gate's floor (metres; the arch stands on it).
@export var floor_y: float = -4.5
@export var title: String = ""
## What lies beyond, once bared ("its raid is the next milestone", "down to the Sap Galleries").
@export var beyond: String = ""
## Which way the gate faces (out to sea).
@export var facing_yaw: float = 0.0
@export var width: float = 4.4
@export var height: float = 3.8

## The threshold through it (the Sea-Door's), enabled once bared; null for a sealed raid gate.
var threshold: PartyThreshold

var _label: Label3D
var _seal_glow: MeshInstance3D


func _ready() -> void:
	add_to_group(&"caldera_ebb_reveals")
	add_to_group(&"map_glyphs")
	var arch: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_arch(arch, Vector3.ZERO, width, height, facing_yaw, CalderaKit.DARK_STONE.lerp(CalderaKit.STONE, 0.3))
	var back: Vector3 = -Vector3(sin(facing_yaw), 0.0, cos(facing_yaw))
	CalderaKit.add_box(arch, back * 0.9 + Vector3(0.0, height * 0.42, 0.0), Vector3(width + 0.4, height * 0.84, 0.4).rotated(Vector3.UP, 0.0),
		Color(0.08, 0.06, 0.1), facing_yaw)
	for index: int in 10:
		var angle: float = TAU * float(index) / 10.0
		var crust: Vector3 = Vector3(cos(angle) * (width * 0.5 + 0.8), 0.4 + absf(sin(angle)) * 1.6, sin(angle) * 0.6).rotated(Vector3.UP, facing_yaw)
		CalderaKit.add_sphere(arch, crust, 0.35, Color(0.7, 0.72, 0.66), 0.6, 5)
	CalderaKit.add_raid_seal(arch, Vector3(0.0, height - 1.5, 0.0) + Vector3(sin(facing_yaw), 0.0, cos(facing_yaw)) * 0.85, 0.9, facing_yaw)
	add_child(CalderaKit.mesh_node("Arch", arch))
	_seal_glow = CalderaKit.glow_sphere(self, "SealGlow", Vector3(0.0, height - 1.5, 0.0) + Vector3(sin(facing_yaw), 0.0, cos(facing_yaw)) * 1.3,
		0.35, CalderaKit.RAID_RED, 3.0)
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, height + 2.6, 0.0) + Vector3(sin(facing_yaw), 0.0, cos(facing_yaw)) * 1.5)
	if CalderaWorldState.current != null:
		CalderaWorldState.current.sea_level_changed.connect(_on_sea_level_changed)
	_refresh()


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.sea_level_changed.is_connected(_on_sea_level_changed):
		CalderaWorldState.current.sea_level_changed.disconnect(_on_sea_level_changed)


## Bared: the Ebb has come and the sea stands below the gate's floor.
func is_bared() -> bool:
	var state: CalderaWorldState = CalderaWorldState.current
	return state != null and state.ebb_unlocked and state.sea_level_y <= global_position.y - 0.5


## Whether the sea stands over the gate's floor right now.
func is_submerged() -> bool:
	var state: CalderaWorldState = CalderaWorldState.current
	return state == null or state.sea_level_y > global_position.y


func _on_sea_level_changed(_sea_y: float) -> void:
	_refresh()


func _refresh() -> void:
	var bared: bool = is_bared()
	_seal_glow.visible = bared
	_label.visible = not is_submerged()
	_label.text = "%s\n%s" % [title, beyond if bared else "under the Long Flood"]
	if threshold != null:
		threshold.enabled = bared
