## A composed view, shown once (docs/27 §7, docs/33 §3.6): the first time each hero steps within `radius`
## of it, their own camera eases up and back for `seconds` to look out over them at `look_at_point`, then
## eases home, with a banner naming what they see. Once per hero per save, never mid-fight; each
## split-screen viewport runs its own.
## Embershore has two, each a different subject: the Doverslap reveal on the gorge bridge (Level 4: the
## promise, north over The Sound to the World-Tree, Rime-Firth and Barrow-Eyot) and the Mill-Downs reveal
## by the windmill (Level 5: home, back over the worked valley the party has walked, before they leave it).
class_name VistaReveal
extends Node3D

## The reveals' ids in the save (PartyProgress.reveals_seen).
const DOVERSLAP: StringName = &"doverslap"
const MILL_DOWNS: StringName = &"mill_downs"

@export var reveal_id: StringName = DOVERSLAP
@export var radius: float = 6.0
@export var seconds: float = 4.0
## Where to look, in the island's frame.
@export var look_at_point: Vector3 = Vector3.ZERO
@export var banner_title: String = ""
@export var banner_line: String = ""
@export var banner_color: Color = Color(0.78, 0.9, 1.0)

var shown: int = 0


func _physics_process(_delta: float) -> void:
	if CombatDirector.current == null or PartyProgress.current == null:
		return
	var level: LevelBase = get_tree().current_scene as LevelBase
	if level == null:
		return
	for member: ActorBase in CombatDirector.current.party_actors():
		if not member.is_local_player() or member.is_companion:
			continue
		if Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z).length() > radius:
			continue
		var who: StringName = member.loadout.class_id if member.loadout != null else member.player_id
		if PartyProgress.current.has_seen_reveal(reveal_id, who):
			continue
		if member.sign_flow != null and member.sign_flow.is_in_combat:
			continue
		var camera: PlayerCamera = level.grid.camera_for(member.player_id) if level.grid != null else null
		if camera == null:
			continue
		camera.reveal(look_at_point, seconds)
		PartyProgress.current.record_reveal(reveal_id, who)
		shown += 1
		var hud: PlayerHUD = PlayerHUD.for_actor(get_tree(), member)
		if hud != null and banner_title != "":
			hud.show_banner(banner_title, banner_line, banner_color, seconds)
