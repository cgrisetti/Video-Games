## The Dungeon Dojo: a greybox raid instance with the first boss, the Dojo
## Warden, and an exit portal back to Hub Town. Seating, hot-join and the
## split-screen grid come from LevelBase; this adds the boss and the victory.
##
## Beating the Warden plays 2 s of slow motion, puts a victory banner on every
## player's screen and drops a reward chest. Opening the chest pays the party
## its Dojo Shards (PartyProgress), and the gold exit portal calls everyone home.
class_name DungeonDojo
extends LevelBase

# Demo bots (--demo) stand on a ring in front of the boss.
const DEMO_RING_RADIUS: float = 3.0
const VICTORY_TIME_SCALE: float = 0.2
## Real seconds of slow motion (not slowed down themselves).
const VICTORY_SLOWMO_TIME: float = 2.0
## The chest lands this far in front of the fallen boss.
const CHEST_OFFSET: float = 4.5
const CHEST_SHARDS_BASE: int = 10
const CHEST_SHARDS_PER_PLAYER: int = 2
## Seconds after the chest opens before the exit portal takes everyone home.
const RECALL_DELAY: float = 5.0
const VICTORY_COLOR: Color = Color(1.0, 0.86, 0.4)

@onready var boss_spawn: Marker3D = $BossSpawn
@onready var exit_portal: RaidPortal = $ExitPortal

var boss: BossDummy
var chest: RewardChest
var victory: bool = false


## Dojo Shards in the chest for a party of `players`.
static func chest_shards(players: int) -> int:
	return CHEST_SHARDS_BASE + CHEST_SHARDS_PER_PLAYER * maxi(1, players)


func instance_id() -> StringName:
	return InstanceManager.DUNGEON_DOJO


func level_title() -> String:
	return "Dungeon Dojo"


func level_hint() -> String:
	if chest != null and chest.is_open:
		return "Victory! The gold portal is taking you home"
	if victory:
		return "Victory! Walk up to the reward chest"
	return "Stand in the exit portal together to go back to Hub Town"


## AI companions fill missing trinity roles in here.
func wants_companions() -> bool:
	return true


func _setup_level() -> void:
	boss = BossDummy.new()
	boss.name = "Boss"
	boss.player_id = &"boss"
	boss.loadout = ClassLoadouts.raid_boss_dummy()
	boss.telegraphs_root = telegraphs_root
	boss.set_multiplayer_authority(1)
	actors_root.add_child(boss)
	boss.spawn_at(boss_spawn.global_transform)
	boss.defeated.connect(_on_boss_defeated)


func _exit_tree() -> void:
	super._exit_tree()
	# Leaving mid-slow-motion must not leave the next instance slowed down.
	Engine.time_scale = 1.0


func _on_player_unregistered(player_id: StringName) -> void:
	super._on_player_unregistered(player_id)
	if boss != null and boss.threat != null:
		boss.threat.forget(player_id)


# --- Victory --------------------------------------------------------------

## The host saw the boss fall: every peer with the dojo loaded plays the win.
func _on_boss_defeated() -> void:
	if victory or not NetworkManager.current.is_host():
		return
	var spot: Vector3 = boss.global_position + boss.facing_vector() * CHEST_OFFSET
	spot.y = 0.0
	var shards: int = chest_shards(NetworkManager.current.human_count())
	_begin_victory(spot, shards)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_begin_victory.rpc_id(peer_id, spot, shards)


@rpc("authority", "call_local", "reliable")
func _begin_victory(spot: Vector3, shards: int) -> void:
	if victory:
		return
	victory = true
	boss.mark_vanquished()
	for decal: Node in telegraphs_root.get_children():
		decal.queue_free()
	_play_slow_motion()
	AudioCues.play(&"victory")
	chest = RewardChest.new()
	chest.name = "RewardChest"
	chest.shards = shards
	effects_root.add_child(chest)
	chest.global_position = spot
	chest.opened.connect(_on_chest_opened)
	for hud: PlayerHUD in huds.values():
		hud.show_banner("VICTORY!", "The %s is defeated. Walk up to the reward chest!" % BossDummy.DISPLAY_NAME, VICTORY_COLOR)


## Time slows to a fifth for 2 real seconds. The timer ignores the time scale
## and calls Engine directly, so it ends even if the dojo is gone by then.
func _play_slow_motion() -> void:
	Engine.time_scale = VICTORY_TIME_SCALE
	var timer: SceneTreeTimer = get_tree().create_timer(VICTORY_SLOWMO_TIME, true, false, true)
	timer.timeout.connect(Engine.set_time_scale.bind(1.0))


## Runs on every peer when the chest opens; the host also pays out the shards.
func _on_chest_opened(opener_id: StringName, shards: int) -> void:
	if NetworkManager.current.is_host():
		PartyProgress.current.award_shards(shards)
	var opener: ActorBase = CombatDirector.current.get_actor(opener_id)
	var who: String = opener.display_name().get_slice(" ", 0) if opener != null else "Someone"
	for hud: PlayerHUD in huds.values():
		hud.show_banner("+%d DOJO SHARDS" % shards, "%s opened the chest! Pouch: %d shards to spend in Hub Town.\nHeading home..." % [
			who, PartyProgress.current.shards], VICTORY_COLOR)
	exit_portal.recall(RECALL_DELAY)


# --- Demo and report ------------------------------------------------------

func _demo_post_for(actor: ActorBase) -> Vector3:
	var angle: float = (float(actor.party_slot) - 1.5) * 0.7
	return boss.global_position + Vector3(sin(angle), 0.0, cos(angle)) * DEMO_RING_RADIUS


func _demo_attacks() -> bool:
	return not victory


func _report_extra() -> String:
	return "boss %d/%d hp%s, " % [roundi(boss.stats.health), roundi(boss.stats.stats.max_health), " (victory)" if victory else ""]
