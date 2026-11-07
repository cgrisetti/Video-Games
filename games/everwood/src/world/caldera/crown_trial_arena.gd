## One of The Crown's three open-air capstone trials (docs/20 Part II §2,
## areas 3 to 5; "each trial is a remix, not a new system"): an arena on its
## shore with its foes (a MobSpawner pack that never regrows: guards and a
## capstone boss from the Bestiary's Crown kin) and its shore's hazard:
##
##   Trial of the Anvil (Iron Shore W)   posture and Shatterpoint: the
##       Anvil-Warden Colossus shrugs off chip damage until its poise breaks
##   Trial of the Gale (Gale Cliffs N)   mobility and wind-shear: Breach Gales
##       sweep the arena (BreachGale); shelter behind the Old Sanctum walls or
##       dodge through them
##   Trial of the Tide (Tide Grottos E)  darkness and cleansing: blight-mist
##       drains stamina outside a sanctuary until the three Sap-Siphon Totems
##       are cleansed with Star-Tide or Warm-Hearth (SapSiphonTotem)
##
## Its foes grow when its landblock streams into the window and leave if it
## streams out unfinished. When every foe is beaten the host completes the
## trial (CalderaWorldState.complete_trial): a bough blooms and a seal lights.
class_name CrownTrialArena
extends Node3D

signal trial_completed(trial: StringName)

## Blight-mist drains this much stamina a second outside a sanctuary, until the totems are cleansed.
const BLIGHT_DRAIN: float = 9.0
## ...and holds stamina's regen off while it does.
const BLIGHT_HOLD: float = 0.25

@export var trial_id: StringName = &""
@export var title: String = ""
@export var pillar: String = ""
@export var arena_radius: float = 30.0
@export var variant_ids: Array[StringName] = []
@export var accent: Color = Color(0.9, 0.6, 0.2)

var spawner: MobSpawner
var gale: BreachGale
var totems: Array[SapSiphonTotem] = []
var spawned: bool = false

var _label: Label3D


func _ready() -> void:
	add_to_group(&"map_glyphs")
	add_to_group(&"caldera_streamed")
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(stone, Vector3(0.0, 0.0, 0.0), 1.6, 2.2, 0.8, CalderaKit.DARK_STONE, 12)
	CalderaKit.add_post(stone, Vector3(0.0, 0.8, 0.0), 0.5, 0.7, 2.4, CalderaKit.PALE_STONE, 6)
	add_child(CalderaKit.mesh_node("TrialStone", stone))
	CalderaKit.glow_sphere(self, "TrialMark", Vector3(0.0, 3.5, 0.0), 0.5, accent, 1.6)
	_label = CalderaKit.sign_label(self, "Sign", "", Vector3(0.0, 4.6, 0.0))
	spawner = MobSpawner.new()
	spawner.name = "Foes"
	spawner.territory = title
	spawner.variant_ids = variant_ids
	spawner.leash = arena_radius + 8.0
	spawner.respawn_time = Vector2(1.0e9, 1.0e9)
	spawner.position = Vector3(0.0, 0.0, -arena_radius * 0.35)
	add_child(spawner)
	if CalderaWorldState.current != null:
		CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
	_refresh_label()


func _exit_tree() -> void:
	if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
		CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)


func is_complete() -> bool:
	return CalderaWorldState.current != null and CalderaWorldState.current.trial_complete(trial_id)


func foes_standing() -> int:
	return spawner.standing_count()


## Its landblock got its collider: the foes grow (unless the trial is done).
func stream_in() -> void:
	if spawned or is_complete():
		return
	spawned = true
	spawner.spawn_mobs()


## Its landblock left the window unfinished: the foes go, to grow afresh next time.
func stream_out() -> void:
	if not spawned:
		return
	spawned = false
	spawner.despawn_mobs()


func blight_active() -> bool:
	if trial_id != CalderaWorldState.TRIAL_TIDE or is_complete() or not spawned:
		return false
	for totem: SapSiphonTotem in totems:
		if not totem.cleansed:
			return true
	return false


func _physics_process(delta: float) -> void:
	if gale != null:
		gale.active = spawned and not is_complete()
	if not spawned or is_complete():
		return
	if blight_active():
		for member: ActorBase in CombatDirector.current.party_actors():
			if not member.is_multiplayer_authority() or member.stats.is_downed or not _inside(member.global_position):
				continue
			if CombatDirector.current.in_sanctuary(member.global_position):
				continue
			member.stats.drain_stamina(BLIGHT_DRAIN * delta, BLIGHT_HOLD)
	var host: bool = not NetworkManager.current.is_online() or NetworkManager.current.is_host()
	if host and not spawner.mobs.is_empty() and spawner.standing_count() == 0:
		CalderaWorldState.current.complete_trial(trial_id)
		trial_completed.emit(trial_id)


func _inside(at: Vector3) -> bool:
	return Vector2(at.x - global_position.x, at.z - global_position.z).length() <= arena_radius


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_refresh_label()


func _refresh_label() -> void:
	_label.text = "%s\n%s" % [title, "complete: its bough blooms on Miller's Oak" if is_complete() else pillar]
