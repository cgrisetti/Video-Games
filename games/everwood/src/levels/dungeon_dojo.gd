## The Dungeon Dojo: a greybox raid instance with the first boss, the Dojo
## Warden, and an exit portal back to Hub Town. Seating, hot-join and the
## split-screen grid come from LevelBase; this adds the boss.
class_name DungeonDojo
extends LevelBase

# Demo bots (--demo) stand on a ring in front of the boss.
const DEMO_RING_RADIUS: float = 3.0

@onready var boss_spawn: Marker3D = $BossSpawn

var boss: BossDummy


func instance_id() -> StringName:
	return InstanceManager.DUNGEON_DOJO


func level_title() -> String:
	return "Dungeon Dojo"


func level_hint() -> String:
	return "Stand in the exit portal together to go back to Hub Town"


func _setup_level() -> void:
	boss = BossDummy.new()
	boss.name = "Boss"
	boss.player_id = &"boss"
	boss.loadout = ClassLoadouts.raid_boss_dummy()
	boss.telegraphs_root = telegraphs_root
	boss.set_multiplayer_authority(1)
	actors_root.add_child(boss)
	boss.spawn_at(boss_spawn.global_transform)


func _on_player_unregistered(player_id: StringName) -> void:
	super._on_player_unregistered(player_id)
	if boss != null and boss.threat != null:
		boss.threat.forget(player_id)


func _demo_post_for(actor: ActorBase) -> Vector3:
	var angle: float = (float(actor.party_slot) - 1.5) * 0.7
	return boss.global_position + Vector3(sin(angle), 0.0, cos(angle)) * DEMO_RING_RADIUS


func _demo_attacks() -> bool:
	return true


func _report_extra() -> String:
	return "boss %d/%d hp, " % [roundi(boss.stats.health), roundi(boss.stats.stats.max_health)]
