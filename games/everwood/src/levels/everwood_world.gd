## The seamless world (10_WORLD_ARCHITECTURE.md): Bramble-Bridge and the
## Dover-Slap-Falls Expedition as one bounded world of 128 m Landblocks, streamed
## round every player (WorldGridManager), with no loading screen between town
## and the Cairnsman.
##
## The party wakes round the Kindle-Fire's campfire (Chunk (0, 1)), south
## of the village; standing by the fire warms everyone to full, like the
## Water-Shrine. The walled lane runs east, then north through Oakshire
## Commons to Bramble-Bridge's south gate and over the canal bridge. Once anyone
## reaches the village square, the square (by the Scribe Desk and Chime-Shrine)
## is where the party gets back up and where a raid brings it home, for the
## rest of this run of the game. The Armory &
## Scribe Desk and the Chime-Shrine work as in the hub, and the Raid Portal
## still warps the party into the instanced expedition (dungeon_dojo), whose
## exit brings them back here. Or walk north through the open Forest Gate,
## under the Moss-Oak Great Arch, into Moss-Oak-Hollow (0, -1), down the
## Rush-Light-Hollow, over Dover-Slap-Bridge and through the Dover-Slap
## Gatehouse (0, -2), and up the causeway to the Ring of the Cairnsman (0, -3).
## Reaching each zone moves everyone's respawn to its checkpoint; AI
## companions fill missing roles once anyone has left the village. Beating the
## Cairnsman drops his chest, and opening it opens a gold portal that brings
## everyone home to the green and starts the expedition afresh.
##
## Cleared camps, opened chests, the shrine's and the campfire's rest, the
## open gate and the fallen Cairnsman live in the level's WorldStateDB, so they stay that way
## while their chunks stream out and back in, and latecomers are sent them.
##
## F4 (or --telemetry on the command line) shows the Landblock telemetry badge.
class_name EverwoodWorld
extends LevelBase

const TITLE: String = "Tizzi-Wed-Green"
const CHECKPOINT_COLOR: Color = DungeonDojo.CHECKPOINT_COLOR
const VICTORY_COLOR: Color = DungeonDojo.VICTORY_COLOR
const PASSING_BANNER_TIME: float = DungeonDojo.PASSING_BANNER_TIME
const RECALL_PORTAL_COLOR: Color = Color(0.95, 0.8, 0.4)
## The gold portal home opens this far from the boss's chest, toward the causeway.
const RECALL_PORTAL_OFFSET: Vector3 = Vector3(0.0, 0.0, 7.0)
const RING_CHUNK: Vector2i = Vector2i(0, -3)
const GORGE_CHUNK: Vector2i = Vector2i(0, -2)
## Demo bots (--demo) walk north by these, after the zone's own business.
const DEMO_WAYPOINTS: Array[Vector3] = [Vector3(48.0, 0.0, 177.0), Vector3(62.0, 0.0, 166.0), Vector3(64.0, 0.0, 100.0), Vector3(64.0, 0.0, 40.0),
	Vector3(64.0, 0.0, 10.0), Vector3(64.0, 0.0, -20.0), Vector3(64.0, -1.8, -70.0), Vector3(64.0, 3.0, -140.0),
	Vector3(64.0, 3.0, -170.0), Vector3(64.0, 6.0, -280.0)]

## Whether the party has reached Bramble-Bridge's square since the game started:
## from then on it gets back up there, and a raid brings it home there. It
## outlives the level (a trip to the instanced raid reloads it).
static var town_square_reached: bool = false

@onready var grid_manager: WorldGridManager = $World

var world_state: WorldStateDB
## The furthest zone the party has reached (0: still in Bramble-Bridge, 1 to 3: the expedition's zones).
var zone: int = 0
var boss: BossDummy
var chest: RewardChest
var wayfarer_chest: RewardChest
var recall_portal: RaidPortal
var camps: Array[MinionCamp] = []
var coop_gate: CoopGate
var water_shrine: WaterShrine
var campfire: HearthCampfire
var raid_portal: RaidPortal
var chime_shrine: ChimeShrine
var scribe_desk: ScribeDesk
var victory: bool = false

## Whether any person has left the village (companions come along then).
var _outside: bool = false


func instance_id() -> StringName:
	return InstanceManager.EVERWOOD_WORLD


func level_title() -> String:
	return TITLE


func home_place() -> String:
	return "Honey-Wick"


func music_profile_at(position: Vector3) -> StringName:
	return LandblockManifest.music_profile_at(position)


func level_hint() -> String:
	if chest != null and is_instance_valid(chest) and chest.is_open:
		return "Victory! The gold portal is taking you home to Bramble-Bridge"
	if victory:
		return "Victory! Walk up to the reward chest"
	match zone:
		0:
			if not town_square_reached:
				return "The Kindle-Fire: stand by the campfire to warm up, then follow the walled lane east and north through Honey-Wick into Bramble-Bridge\n%s" % HubTown.CHANGE_KEYS
			return "Walk north through the Forest Gate into Moss-Oak-Hollow, or take the Raid Portal to the instanced expedition · Chime-Shrine: %d Chimes · Scribe Desk: armor, weapons, cards and Calling\n%s" % [
				PartyProgress.current.chimes, HubTown.CHANGE_KEYS]
		1:
			return "%s: clear the bramble camps, drink at the Water-Shrine, find the Wayfarer's Chest, then down the holloway" % LandblockManifest.ZONE_NAMES[1]
		2:
			if gate_is_open():
				return "%s: the gate is open. On up the causeway to the Ring of the Cairnsman!" % LandblockManifest.ZONE_NAMES[2]
			return "%s: stand on both Maker-Seal Plates together, or ring the Bridge-Bell in a Shield-Sworn's Shadow Sanctuary" % LandblockManifest.ZONE_NAMES[2]
	return "%s: face the Cairnsman of Dover-Slap-Falls" % LandblockManifest.ZONE_NAMES[3]


## Companions fill missing roles once anyone has walked out of the village.
func wants_companions() -> bool:
	return _outside


func _setup_level() -> void:
	world_state = WorldStateDB.new()
	add_child(world_state)
	grid_manager.world_state = world_state
	grid_manager.entity_attached.connect(_on_entity_attached)
	grid_manager.entity_detached.connect(_on_entity_detached)
	grid_manager.attach_badge($Screens)
	if OS.get_cmdline_user_args().has("--telemetry"):
		grid_manager.set_telemetry_visible(true)
	grid_manager.prime(_town_spots())


func _process(delta: float) -> void:
	super._process(delta)
	if _key_pressed(KEY_F4):
		grid_manager.set_telemetry_visible(not grid_manager.is_telemetry_visible())


func _physics_process(_delta: float) -> void:
	var outside: bool = false
	for actor: ActorBase in actors.values():
		outside = outside or (not actor.is_companion and actor.global_position.z < LandblockManifest.ZONE_ONE_Z)
	if outside != _outside:
		_outside = outside
		_queue_companion_refresh()
	if not town_square_reached and _square_reached():
		_promote_town_checkpoint()
	var reached: int = _furthest_zone()
	if reached > zone:
		zone = reached
		_move_respawns_to(zone)
		for hud: PlayerHUD in huds.values():
			hud.show_banner(LandblockManifest.ZONE_NAMES[zone].to_upper(), "Checkpoint: you'll get back up here.", CHECKPOINT_COLOR, PASSING_BANNER_TIME)
			hud.enter_place(LandblockManifest.ZONE_NAMES[zone])
	if NetworkManager.current.is_host() and zone == 2 and coop_gate != null:
		DungeonDojo.steer_companions_to_plates(coop_gate, actors)


func _exit_tree() -> void:
	super._exit_tree()
	# Leaving mid-slow-motion must not leave the next instance slowed down.
	Engine.time_scale = 1.0


func _on_player_unregistered(player_id: StringName) -> void:
	super._on_player_unregistered(player_id)
	for enemy: ActorBase in CombatDirector.current.enemies():
		if enemy.threat != null:
			enemy.threat.forget(player_id)


## Whether the Dover-Slap Gatehouse stands open (from the gate if its chunk is in, else from the record).
func gate_is_open() -> bool:
	if coop_gate != null and is_instance_valid(coop_gate):
		return coop_gate.is_open
	return bool(world_state.get_entity_state(GORGE_CHUNK, LandblockManifest.SINAYA_GATE).get("opened", false))


# --- Zones and checkpoints ------------------------------------------------

func _furthest_zone() -> int:
	var furthest: int = zone
	for actor: ActorBase in actors.values():
		var z: float = actor.global_position.z
		if z < LandblockManifest.ZONE_THREE_Z and gate_is_open():
			furthest = maxi(furthest, 3)
		elif z < LandblockManifest.ZONE_TWO_Z:
			furthest = maxi(furthest, 2)
		elif z < LandblockManifest.ZONE_ONE_Z and not actor.is_companion:
			furthest = maxi(furthest, 1)
	return furthest


func _move_respawns_to(reached: int) -> void:
	for actor: ActorBase in actors.values():
		actor.spawn_transform = checkpoint_transform(reached, actor.party_slot)


## Where party slot `slot` respawns once the party reaches `reached` (1 to 3).
func checkpoint_transform(reached: int, slot: int) -> Transform3D:
	var spot: Vector3 = [LandblockManifest.CHECKPOINT_ONE, LandblockManifest.CHECKPOINT_TWO, LandblockManifest.CHECKPOINT_THREE][clampi(reached, 1, 3) - 1]
	@warning_ignore("integer_division")
	var row: int = slot / 4
	var column: float = float(slot % 4) - 1.5
	return Transform3D(Basis.IDENTITY, spot + Vector3(column * DungeonDojo.CHECKPOINT_SPACING, 0.0, SPAWN_ROW_SPACING * row))


## Someone joining mid-expedition starts at the party's latest checkpoint.
func _spawn_transform(slot: int) -> Transform3D:
	return checkpoint_transform(zone, slot) if zone >= 1 else town_transform(slot)


## Where party slot `slot` starts or gets back up in town: round the campfire
## (the spawn points) until the square is reached, then in the square.
func town_transform(slot: int) -> Transform3D:
	if not town_square_reached:
		return super._spawn_transform(slot)
	@warning_ignore("integer_division")
	var row: int = slot / 4
	var column: float = float(slot % 4) - 1.5
	return Transform3D(Basis.IDENTITY, LandblockManifest.TOWN_SQUARE_SPAWN + Vector3(column * DungeonDojo.CHECKPOINT_SPACING, 0.0, SPAWN_ROW_SPACING * row))


func _town_spots() -> Array[Vector3]:
	var spots: Array[Vector3] = []
	for slot: int in 4:
		spots.append(town_transform(slot).origin)
	return spots


## Anyone (not a companion) over the canal bridge into the square, or the record says so (a latecomer).
func _square_reached() -> bool:
	for actor: ActorBase in actors.values():
		if not actor.is_companion and actor.global_position.z < LandblockManifest.SQUARE_Z:
			return true
	return world_state.has_entity_state(Vector2i(0, 0), LandblockManifest.TOWN_CHECKPOINT)


## The square becomes where the party gets back up (and comes home to from a raid).
func _promote_town_checkpoint() -> void:
	town_square_reached = true
	if NetworkManager.current.is_host():
		world_state.set_entity_state(Vector2i(0, 0), LandblockManifest.TOWN_CHECKPOINT, {"reached": true})
	if zone == 0:
		for actor: ActorBase in actors.values():
			actor.spawn_transform = town_transform(actor.party_slot)
	for hud: PlayerHUD in huds.values():
		hud.show_banner("BRAMBLE-BRIDGE", "Checkpoint: you'll get back up here, by the Scribe Desk and the Chime-Shrine.", CHECKPOINT_COLOR, PASSING_BANNER_TIME)
		hud.enter_place("Bramble-Bridge")


# --- Landblock entities ---------------------------------------------------------

## A stateful thing streamed in (already bound to WorldStateDB): wire it up.
func _on_entity_attached(entity: Node, chunk: Vector2i) -> void:
	if entity is ChimeShrine:
		chime_shrine = entity as ChimeShrine
		chime_shrine.menu_requested.connect(_on_shrine_menu_requested)
	elif entity is ScribeDesk:
		scribe_desk = entity as ScribeDesk
		scribe_desk.menu_requested.connect(_on_desk_menu_requested)
	elif entity is RaidPortal:
		raid_portal = entity as RaidPortal
	elif entity is MinionCamp:
		var camp: MinionCamp = entity as MinionCamp
		camps.append(camp)
		camp.cleared.connect(_on_camp_cleared)
		camp.spawn_minions()
	elif entity is WaterShrine:
		water_shrine = entity as WaterShrine
	elif entity is HearthCampfire:
		campfire = entity as HearthCampfire
	elif entity is CoopGate:
		coop_gate = entity as CoopGate
		coop_gate.opened.connect(_on_gate_opened)
	elif entity.name == &"WayfarerChestSpot":
		_place_wayfarer_chest(entity as Node3D, chunk)
	elif entity.name == &"BossSpawn":
		_place_boss(entity as Node3D, chunk)


## Its chunk is streaming out: forget it (its nodes go with the chunk; the boss lives elsewhere, so he goes now).
func _on_entity_detached(entity: Node, _chunk: Vector2i) -> void:
	if entity is MinionCamp:
		camps.erase(entity)
	elif entity == coop_gate:
		coop_gate = null
	elif entity == water_shrine:
		water_shrine = null
	elif entity == campfire:
		campfire = null
	elif entity == chime_shrine:
		chime_shrine = null
	elif entity == scribe_desk:
		scribe_desk = null
	elif entity == raid_portal:
		raid_portal = null
	elif entity.name == &"WayfarerChestSpot":
		wayfarer_chest = null
	elif entity.name == &"BossSpawn":
		_remove_boss()
		chest = null
		recall_portal = null


func _on_shrine_menu_requested(actor: ActorBase) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	if hud != null:
		hud.open_upgrade_menu()


func _on_desk_menu_requested(actor: ActorBase) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	if hud != null:
		hud.open_scribe_desk()


func _on_camp_cleared(camp: MinionCamp) -> void:
	DungeonDojo.celebrate_camp(camp, effects_root)


## The Wayfarer's Chest waits at its spot in the alcove (it streams with its chunk, and remembers being opened).
func _place_wayfarer_chest(spot: Node3D, chunk: Vector2i) -> void:
	wayfarer_chest = RewardChest.new()
	wayfarer_chest.name = "WayfarerChest"
	wayfarer_chest.title = "Wayfarer's Chest"
	wayfarer_chest.drop_in = false
	wayfarer_chest.chimes = DungeonDojo.WAYFARER_CHEST_CHIMES
	wayfarer_chest.card_roller = DungeonDojo.roll_wayfarer_card
	spot.get_parent().add_child(wayfarer_chest)
	wayfarer_chest.global_transform = spot.global_transform
	world_state.bind(wayfarer_chest, chunk, LandblockManifest.WAYFARER_CHEST)
	wayfarer_chest.opened.connect(_on_wayfarer_chest_opened)


func _on_wayfarer_chest_opened(opener_id: StringName, chimes: int, card_key: StringName) -> void:
	if NetworkManager.current.is_host():
		PartyProgress.current.award_chimes(chimes)
		PartyProgress.current.award_card(card_key)
	for hud: PlayerHUD in huds.values():
		hud.show_banner("+%d CHIMES" % chimes, "%s found the Wayfarer's Chest! New card: %s." % [_who(opener_id), ArsenalCatalog.current.copy_name(card_key)],
			VICTORY_COLOR, PASSING_BANNER_TIME)


func _on_gate_opened(method: int) -> void:
	var how: String = "The Maker-Seal Plates hum together" if method == CoopGate.Method.RUNE_PLATES else "The Bridge-Bell rings out"
	for hud: PlayerHUD in huds.values():
		hud.show_banner("THE GATE OPENS", "%s, and the Dover-Slap Gatehouse's portcullis sinks away." % how, CHECKPOINT_COLOR, PASSING_BANNER_TIME)
	for actor: ActorBase in actors.values():
		if actor.companion != null:
			actor.companion.has_assigned_post = false
	get_tree().create_timer(CoopGate.PORTCULLIS_SINK_TIME + 0.3).timeout.connect(grid_manager.rebake_navigation.bind(GORGE_CHUNK))


func _who(player_id: StringName) -> String:
	var actor: ActorBase = CombatDirector.current.get_actor(player_id)
	return actor.display_name().get_slice(" ", 0) if actor != null else "Someone"


# --- The Cairnsman ---------------------------------------------------------------

## The Ring streamed in: the Cairnsman takes his place, unless he's already
## fallen this run (then only his chest is there, open or not).
func _place_boss(spot: Node3D, chunk: Vector2i) -> void:
	var record: Dictionary = world_state.get_entity_state(chunk, LandblockManifest.CAIRNSMAN)
	if bool(record.get("defeated", false)):
		victory = true
		var where: Array = record.get("spot", [spot.global_position.x, spot.global_position.y, spot.global_position.z])
		_place_reward_chest(Vector3(float(where[0]), float(where[1]), float(where[2])), int(record.get("chimes", 0)), str(record.get("card", "")), false)
		return
	boss = BossDummy.new()
	boss.name = "Boss"
	boss.player_id = &"boss"
	boss.loadout = ClassLoadouts.raid_boss_dummy()
	boss.telegraphs_root = telegraphs_root
	boss.set_multiplayer_authority(1)
	actors_root.add_child(boss)
	boss.spawn_at(spot.global_transform)
	boss.defeated.connect(_on_boss_defeated)


func _remove_boss() -> void:
	if boss != null and is_instance_valid(boss):
		actors_root.remove_child(boss)
		boss.queue_free()
	boss = null
	for decal: Node in telegraphs_root.get_children():
		decal.queue_free()


## The host saw the boss fall: every peer plays the win, and the world remembers it.
func _on_boss_defeated() -> void:
	if victory or not NetworkManager.current.is_host():
		return
	var spot: Vector3 = boss.global_position + boss.facing_vector() * DungeonDojo.CHEST_OFFSET
	spot.y = boss.spawn_transform.origin.y
	var chimes: int = DungeonDojo.chest_chimes(NetworkManager.current.human_count())
	var card_key: String = String(ArsenalCatalog.current.roll_card_drop(PartyProgress.current.drop_rng))
	PartyProgress.current.record_victory()
	world_state.set_entity_state(RING_CHUNK, LandblockManifest.CAIRNSMAN, {"defeated": true, "spot": [spot.x, spot.y, spot.z], "chimes": chimes, "card": card_key})
	_begin_victory(spot, chimes, card_key)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_begin_victory.rpc_id(peer_id, spot, chimes, card_key)


@rpc("authority", "call_local", "reliable")
func _begin_victory(spot: Vector3, chimes: int, card_key: String) -> void:
	if victory:
		return
	victory = true
	if boss != null and is_instance_valid(boss):
		boss.mark_vanquished()
	for decal: Node in telegraphs_root.get_children():
		decal.queue_free()
	Engine.time_scale = DungeonDojo.VICTORY_TIME_SCALE
	get_tree().create_timer(DungeonDojo.VICTORY_SLOWMO_TIME, true, false, true).timeout.connect(Engine.set_time_scale.bind(1.0))
	AudioCues.play(&"victory")
	_place_reward_chest(spot, chimes, card_key, true)
	for hud: PlayerHUD in huds.values():
		hud.show_banner("VICTORY!", "The %s is defeated. Walk up to the reward chest!" % BossDummy.DISPLAY_NAME, VICTORY_COLOR)


## The boss's chest, in the Ring's Landblock (so it streams with it) and remembered.
func _place_reward_chest(spot: Vector3, chimes: int, card_key: String, drop: bool) -> void:
	var holder: Node3D = grid_manager.gameplay_root(RING_CHUNK)
	chest = RewardChest.new()
	chest.name = "RewardChest"
	chest.chimes = chimes
	chest.card_key = StringName(card_key)
	chest.drop_in = drop
	(holder if holder != null else effects_root).add_child(chest)
	chest.global_position = spot
	world_state.bind(chest, RING_CHUNK, LandblockManifest.CAIRNSMAN_CHEST)
	chest.opened.connect(_on_chest_opened)


func _on_chest_opened(opener_id: StringName, chimes: int, card_key: StringName) -> void:
	if NetworkManager.current.is_host():
		PartyProgress.current.award_chimes(chimes)
		PartyProgress.current.award_card(card_key)
	for hud: PlayerHUD in huds.values():
		hud.show_banner("+%d CHIMES" % chimes, "%s opened the chest! New card: %s. Grimoire Lv %d.\nHeading home..." % [
			_who(opener_id), ArsenalCatalog.current.copy_name(card_key), PartyProgress.current.grimoire_level()], VICTORY_COLOR)
	var holder: Node3D = grid_manager.gameplay_root(RING_CHUNK)
	recall_portal = RaidPortal.new()
	recall_portal.name = "RecallPortal"
	recall_portal.title = "Home: Bramble-Bridge"
	recall_portal.portal_color = RECALL_PORTAL_COLOR
	(holder if holder != null else effects_root).add_child(recall_portal)
	recall_portal.global_position = chest.global_position + RECALL_PORTAL_OFFSET
	recall_portal.party_entered.connect(_on_recall)
	recall_portal.recall(DungeonDojo.RECALL_DELAY)


## The gold portal: everyone back to town (the square), and the expedition starts afresh
## (every peer rebuilds its own chunks and moves its own players).
func _on_recall(_target: StringName) -> void:
	victory = false
	zone = 0
	chest = null
	recall_portal = null
	grid_manager.reset_expedition()
	grid_manager.prime(_town_spots())
	for actor: ActorBase in actors.values():
		if actor.is_multiplayer_authority():
			actor.spawn_at(town_transform(actor.party_slot))
	for hud: PlayerHUD in huds.values():
		hud.show_banner("BRAMBLE-BRIDGE", "Home again. The expedition waits beyond the Forest Gate.", CHECKPOINT_COLOR, PASSING_BANNER_TIME)


# --- Demo and report ------------------------------------------------------

## A --demo bot heads for its Maker-Seal Plate while the gate is sealed, else the
## nearest woken minion, else the boss, else the next waypoint north.
func _demo_post_for(actor: ActorBase) -> Vector3:
	if zone == 2 and coop_gate != null and not coop_gate.is_open:
		return coop_gate.plates[actor.party_slot % coop_gate.plates.size()].global_position
	for enemy: ActorBase in CombatDirector.current.enemies():
		if enemy.is_targetable() and enemy.global_position.distance_to(actor.global_position) < 25.0:
			return enemy.global_position
	for waypoint: Vector3 in DEMO_WAYPOINTS:
		if waypoint.z < actor.global_position.z - 3.0:
			return waypoint
	return actor.global_position


func _demo_attacks() -> bool:
	return not victory


func _report_extra() -> String:
	var metrics: Dictionary = grid_manager.get_streaming_metrics()
	var boss_text: String = "boss %d/%d hp, " % [roundi(boss.stats.health), roundi(boss.stats.stats.max_health)] if boss != null and is_instance_valid(boss) else ""
	return "%szone %d, gate %s, %s, " % [boss_text, zone, "open" if gate_is_open() else "sealed", WorldTelemetryBadge.text_for(metrics)]
