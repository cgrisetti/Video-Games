## The Doverslap reveal (docs/27 §7): the first time each hero steps onto the
## middle of the Doverslap Gorge Bridge, their own camera eases up and back for
## four seconds to look north over the Sound at the World-Tree on The Crown,
## Rime-Firth and Barrow-Eyot, then eases home. Once per hero per save, never
## mid-fight; each split-screen viewport runs its own.
class_name DoverslapReveal
extends Node3D

const REVEAL_ID: StringName = &"doverslap"

@export var radius: float = 6.0
@export var seconds: float = 4.0
## Where to look, in the island's frame.
@export var look_at_point: Vector3 = Vector3.ZERO

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
		if PartyProgress.current.has_seen_reveal(REVEAL_ID, who):
			continue
		if member.sign_flow != null and member.sign_flow.is_in_combat:
			continue
		var camera: PlayerCamera = level.grid.camera_for(member.player_id) if level.grid != null else null
		if camera == null:
			continue
		camera.reveal(look_at_point, seconds)
		PartyProgress.current.record_reveal(REVEAL_ID, who)
		shown += 1
		var hud: PlayerHUD = PlayerHUD.for_actor(get_tree(), member)
		if hud != null:
			hud.show_banner("THE SOUND", "The World-Tree on The Crown; Rime-Firth west of it, Barrow-Eyot east", Color(0.78, 0.9, 1.0), seconds)
