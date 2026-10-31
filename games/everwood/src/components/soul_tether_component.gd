## The healer's Soul Tether. D-Pad Up / Right / Down / Left bind the tether to
## the four other party members (in join order); homing heals and the Lifeline
## Pull go to whoever is tethered. With no one else around it tethers yourself.
class_name SoulTetherComponent
extends Node

signal tether_changed(player_id: StringName)

const SLOT_ARROWS: Array[String] = ["↑", "→", "↓", "←"]
const BEAM_RADIUS: float = 0.04
const BEAM_HEIGHT: float = 1.1
const BEAM_COLOR: Color = Color(0.45, 1.0, 0.6, 0.55)

var actor: ActorBase
var tethered_id: StringName = &""

var _beam: MeshInstance3D


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "SoulTetherComponent"
	_beam = MeshInstance3D.new()
	_beam.name = "TetherBeam"
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = BEAM_RADIUS
	cylinder.bottom_radius = BEAM_RADIUS
	cylinder.height = 1.0
	cylinder.radial_segments = 6
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = BEAM_COLOR
	cylinder.material = material
	_beam.mesh = cylinder
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.top_level = true
	_beam.visible = false
	actor.add_child.call_deferred(_beam)


## The four allies the D-Pad slots point at, in party join order.
func allies() -> Array[ActorBase]:
	var result: Array[ActorBase] = []
	for member: ActorBase in CombatDirector.current.party_actors():
		if member != actor:
			result.append(member)
	return result


func bind_slot(slot: int) -> bool:
	var list: Array[ActorBase] = allies()
	if slot < 0 or slot >= list.size():
		return false
	bind_actor(list[slot])
	return true


func bind_actor(target: ActorBase) -> void:
	if target == null or target.player_id == tethered_id:
		return
	tethered_id = target.player_id
	tether_changed.emit(tethered_id)


func tethered_actor() -> ActorBase:
	var target: ActorBase = CombatDirector.current.get_actor(tethered_id)
	if target == null:
		var list: Array[ActorBase] = allies()
		target = list[0] if not list.is_empty() else actor
		tethered_id = target.player_id
		tether_changed.emit(tethered_id)
	return target


func slot_arrow_for(player_id: StringName) -> String:
	var list: Array[ActorBase] = allies()
	for index: int in mini(list.size(), SLOT_ARROWS.size()):
		if list[index].player_id == player_id:
			return SLOT_ARROWS[index]
	return "•"


## Stretches the beam between the healer and the tethered ally.
func update_beam() -> void:
	if _beam == null or not _beam.is_inside_tree():
		return
	var target: ActorBase = tethered_actor()
	if target == null or target == actor:
		_beam.visible = false
		return
	var from: Vector3 = actor.global_position + Vector3.UP * BEAM_HEIGHT
	var to: Vector3 = target.global_position + Vector3.UP * BEAM_HEIGHT
	var length: float = from.distance_to(to)
	if length < 0.2:
		_beam.visible = false
		return
	_beam.visible = true
	var mid: Vector3 = (from + to) * 0.5
	var up: Vector3 = (to - from) / length
	var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
	var forward: Vector3 = side.cross(up).normalized()
	_beam.global_transform = Transform3D(Basis(side, up * length, forward), mid)
