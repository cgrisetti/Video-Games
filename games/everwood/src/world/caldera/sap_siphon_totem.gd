## A Sap-Siphon Totem in the Tide Grottos (docs/20 Part II area 5): an old
## carved sluice-stone weeping Miller's Oak's violet sap into the sea, the
## source of the blight-mist on the grotto floor. A Star-Tide or Warm-Hearth
## detonation (Astral Chorus, Dawnburst) or card within its reach cleanses
## it: the sap stops and it glows Saffron-Gold.
class_name SapSiphonTotem
extends Node3D

signal cleansed_now(totem: SapSiphonTotem)

const REACH: float = 9.0
const CLEANSING_SIGNS: Array[int] = [ScribeSignResource.Sign.SIGN_STAR_TIDE, ScribeSignResource.Sign.SIGN_WARM_HEARTH]

var cleansed: bool = false

var _sap: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(stone, Vector3.ZERO, 0.6, 0.9, 3.2, CalderaKit.DARK_STONE, 6)
	for ring: int in 3:
		CalderaKit.add_post(stone, Vector3(0.0, 0.7 + ring * 0.9, 0.0), 0.95, 0.95, 0.18, CalderaKit.BASALT, 6)
	add_child(CalderaKit.mesh_node("Stone", stone))
	_sap = CalderaKit.glow_sphere(self, "Sap", Vector3(0.0, 3.4, 0.0), 0.42, CalderaKit.SAP_VIOLET, 2.4)
	_light = CalderaKit.light(self, "Glow", Vector3(0.0, 2.6, 0.0), CalderaKit.SAP_VIOLET, 1.6, 8.0)
	CalderaKit.solid_cylinder(self, "Body", Vector3.ZERO, 0.8, 3.2, ActorBase.LAYER_LOW_SCENERY)
	CombatDirector.current.synergy_detonated.connect(_on_detonated)
	CombatDirector.current.card_invoked.connect(_on_card_invoked)


func _exit_tree() -> void:
	var director: CombatDirector = CombatDirector.current
	if director == null:
		return
	if director.synergy_detonated.is_connected(_on_detonated):
		director.synergy_detonated.disconnect(_on_detonated)
	if director.card_invoked.is_connected(_on_card_invoked):
		director.card_invoked.disconnect(_on_card_invoked)


func cleanse() -> void:
	if cleansed:
		return
	cleansed = true
	_sap.material_override = CalderaKit.glow(CalderaKit.HEARTH_SAFFRON, 2.0)
	_light.light_color = CalderaKit.HEARTH_SAFFRON
	AudioCues.play(&"shrine")
	CombatDirector.current.announce(global_position + Vector3.UP * 4.0, "Sap-Siphon cleansed", CalderaKit.HEARTH_SAFFRON)
	cleansed_now.emit(self)


func _on_detonated(target: ActorBase, primer: int, _cross: bool, _label: String) -> void:
	if not cleansed and CLEANSING_SIGNS.has(primer) and is_instance_valid(target) and target.global_position.distance_to(global_position) <= REACH:
		cleanse()


func _on_card_invoked(caster: ActorBase, action: CombatActionResource, _variant: int) -> void:
	if not cleansed and action != null and CLEANSING_SIGNS.has(int(action.scribe_sign)) and is_instance_valid(caster) \
			and caster.global_position.distance_to(global_position) <= REACH:
		cleanse()
