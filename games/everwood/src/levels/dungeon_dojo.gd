## The Doverslap Falls Expedition (07_EXPEDITION_HUD_AND_ART_GDD.md §3): the raid, three
## zones end to end (its files and network id keep the old name, Dungeon Dojo):
##   Zone 1  Moss-Oak Hollow and Rush-Light-Hollow: two woodland
##           minion camps (each pays a few Chimes when cleared), the Wayfarer's
##           Water-Shrine, Wind-Lanterns, and the Wayfarer's Chest in the
##           alcove (Chimes and an Uncommon Scribe Card)
##   Zone 2  Doverslap Bridge and the Doverslap Gatehouse's Co-Op
##           Threshold (CoopGate): two Maker-Seal Plates, or a Shield-Sworn's
##           Shadow Sanctuary and the Bell-Winch, open the portcullis
##   Zone 3  the Ring of the Cairnsman and its boss, The Cairnsman of Doverslap Falls
## Reaching a zone moves everyone's respawn to its checkpoint. Seating,
## hot-join and the split-screen grid come from LevelBase.
##
## Its camps, Water-Shrine, Wayfarer's Chest and gate are bound to a
## WorldStateDB (filed under the seamless world's chunks), so someone joining
## mid-expedition is sent all of it: cleared camps, an opened chest, a resting
## shrine, an open gate. One navigation mesh, baked off the main thread when
## it loads (and again once the gate's portcullis has sunk), lets companions
## and minions find their way round the walls (ChunkNavBuilder).
##
## Beating the Cairnsman plays 2 s of slow motion, puts a victory banner on every
## player's screen, raises the Grimoire a level and drops a reward chest.
## Opening the chest pays the party its Chimes and a collectible Scribe
## Card (PartyProgress), and the gold exit portal calls everyone home.
##
## Command line (after --), for trying things out: --zone=2 or --zone=3 starts
## the party at that zone's checkpoint (3 opens the gate), --boss-health=0.4
## sets the Cairnsman's health share when its fight starts.
class_name DungeonDojo
extends LevelBase

# Demo bots (--demo) stand on a ring in front of their foe.
const DEMO_RING_RADIUS: float = 3.0
## The expedition's map: the Moss-Oaks (z 90) to the Ring's north wall (z -74), the gorge's cliffs either side.
const MAP_RECT: Rect2 = Rect2(-28.0, -78.0, 56.0, 172.0)
const VICTORY_TIME_SCALE: float = 0.2
## Real seconds of slow motion (not slowed down themselves).
const VICTORY_SLOWMO_TIME: float = 2.0
## The chest lands this far in front of the fallen boss.
const CHEST_OFFSET: float = 4.5
const CHEST_CHIMES_BASE: int = 10
const CHEST_CHIMES_PER_PLAYER: int = 2
## A cleared minion camp pays this many Chimes.
const CAMP_CHIMES: int = 3
## The Wayfarer's Chest in the Moss-Oaks' alcove.
const WAYFARER_CHEST_CHIMES: int = 15
## Seconds after the chest opens before the exit portal takes everyone home.
const RECALL_DELAY: float = 5.0
const VICTORY_COLOR: Color = Color(1.0, 0.86, 0.4)
const CHECKPOINT_COLOR: Color = Color(0.7, 0.9, 1.0)
## Real seconds a passing banner (a new zone, the gate, the Wayfarer's Chest) stays up.
const PASSING_BANNER_TIME: float = 4.0
## A zone starts once anyone in the party is past this line (north is -Z).
const ZONE_TWO_Z: float = 15.0
const ZONE_THREE_Z: float = -17.0
const ZONE_NAMES: Array[String] = ["", "Moss-Oak Hollow", "Doverslap Bridge", "The Ring of the Cairnsman"]
## Checkpoint pads sit this far apart across the path.
const CHECKPOINT_SPACING: float = 1.5
## The whole expedition, for its navigation bake.
const NAV_AREA: AABB = AABB(Vector3(-40.0, -30.0, -80.0), Vector3(80.0, 70.0, 175.0))

@onready var boss_spawn: Marker3D = $BossSpawn
@onready var exit_portal: RaidPortal = $ExitPortal
@onready var camps: Array[MinionCamp] = [$CampOne as MinionCamp, $CampTwo as MinionCamp]
@onready var water_shrine: WaterShrine = $WaterShrine
@onready var coop_gate: CoopGate = $CoopGate
@onready var checkpoints: Dictionary[int, Marker3D] = {2: $Checkpoints/Zone2 as Marker3D, 3: $Checkpoints/Zone3 as Marker3D}

var boss: BossDummy
var chest: RewardChest
var wayfarer_chest: RewardChest
var victory: bool = false
var world_state: WorldStateDB
var navigation: NavigationRegion3D
var _navigation_bake: ChunkNavBuilder.BakeJob
## The furthest zone the party has reached (1 to 3).
var zone: int = 1

static var _start_zone: int = 1
static var _start_boss_health: float = -1.0
static var _dev_args_read: bool = false
var _boss_health_applied: bool = false


## Chimes in the boss's chest for a party of `players`.
static func chest_chimes(players: int) -> int:
	return CHEST_CHIMES_BASE + CHEST_CHIMES_PER_PLAYER * maxi(1, players)


func instance_id() -> StringName:
	return InstanceManager.DUNGEON_DOJO


## The expedition end to end: the Moss-Oaks, the gorge and the Ring (18 GDD §7.1).
func map_rect() -> Rect2:
	return MAP_RECT


## The trail from the Moss-Oaks through the holloway, over the trestle and up the causeway.
func map_paths() -> Array[Dictionary]:
	var trail: Array[Dictionary] = [{"points": PackedVector2Array([Vector2(0.0, 90.0), Vector2(0.0, -34.0)]), "half_width": 2.0}]
	return trail


func level_title() -> String:
	return "The Doverslap Falls Expedition"


func home_place() -> String:
	return ZONE_NAMES[1]


## Each zone plays the score of its place on the seamless trail.
func music_profile_at(position: Vector3) -> StringName:
	return LandblockManifest.ZONE_MUSIC[_zone_at(position.z)]


## Zone 1 is the trail's Moss-Oak Hollow moved to the origin, so its sunken lane blends at the same depth.
func music_world_z(position: Vector3) -> float:
	return position.z + LandblockManifest.MOSS_OAKS_ORIGIN.z if _zone_at(position.z) == 1 else position.z


## The zone a spot is in, by how far north it is.
func _zone_at(z: float) -> int:
	if z < ZONE_THREE_Z:
		return 3
	return 2 if z < ZONE_TWO_Z else 1


func level_hint() -> String:
	if chest != null and chest.is_open:
		return "Victory! The gold portal is taking you home"
	if victory:
		return "Victory! Walk up to the reward chest"
	match zone:
		1:
			return "%s: clear the bramble camps, drink at the Water-Shrine, find the Wayfarer's Chest, then down the holloway" % ZONE_NAMES[1]
		2:
			if coop_gate.is_open:
				return "%s: the gate is open. On to the Ring of the Cairnsman!" % ZONE_NAMES[2]
			return "%s: stand on both Maker-Seal Plates together, or ring the Bridge-Bell in a Shield-Sworn's Shadow Sanctuary" % ZONE_NAMES[2]
	return "%s: face the Cairnsman of Doverslap Falls" % ZONE_NAMES[3]


## AI companions fill missing trinity roles in here.
func wants_companions() -> bool:
	return true


func _setup_level() -> void:
	_read_dev_args()
	boss = BossDummy.new()
	boss.name = "Boss"
	boss.player_id = &"boss"
	boss.loadout = ClassLoadouts.raid_boss_dummy()
	boss.telegraphs_root = telegraphs_root
	boss.set_multiplayer_authority(1)
	actors_root.add_child(boss)
	boss.spawn_at(boss_spawn.global_transform)
	boss.defeated.connect(_on_boss_defeated)
	for camp: MinionCamp in camps:
		camp.spawn_minions()
		camp.cleared.connect(_on_camp_cleared)
	wayfarer_chest = RewardChest.new()
	wayfarer_chest.name = "WayfarerChest"
	wayfarer_chest.title = "Wayfarer's Chest"
	wayfarer_chest.drop_in = false
	wayfarer_chest.chimes = WAYFARER_CHEST_CHIMES
	wayfarer_chest.card_roller = roll_wayfarer_card
	effects_root.add_child(wayfarer_chest)
	wayfarer_chest.global_transform = ($WayfarerChestSpot as Marker3D).global_transform
	wayfarer_chest.opened.connect(_on_wayfarer_chest_opened)
	coop_gate.opened.connect(_on_gate_opened)
	world_state = WorldStateDB.new()
	add_child(world_state)
	for stateful: Node in [camps[0], camps[1], water_shrine, coop_gate]:
		world_state.bind(stateful, LandblockManifest.dojo_chunk(stateful.get(&"persist_id") as StringName))
	world_state.bind(wayfarer_chest, LandblockManifest.dojo_chunk(LandblockManifest.WAYFARER_CHEST), LandblockManifest.WAYFARER_CHEST)
	_bake_navigation()


## One navigation mesh for the whole expedition, baked on a worker thread.
func _bake_navigation() -> void:
	ChunkNavBuilder.configure_map(get_world_3d().navigation_map)
	if navigation != null:
		navigation.queue_free()
	navigation = NavigationRegion3D.new()
	navigation.name = "Navigation"
	add_child(navigation)
	if _navigation_bake != null:
		_navigation_bake.wait()
	_navigation_bake = ChunkNavBuilder.bake_region(navigation, self, PackedVector3Array(), NAV_AREA, Callable())


## --zone and --boss-health, read once per run.
static func _read_dev_args() -> void:
	if _dev_args_read:
		return
	_dev_args_read = true
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			_start_zone = clampi(arg.get_slice("=", 1).to_int(), 1, 3)
		elif arg.begins_with("--boss-health="):
			_start_boss_health = clampf(arg.get_slice("=", 1).to_float(), 0.05, 1.0)


func _exit_tree() -> void:
	super._exit_tree()
	# Leaving mid-slow-motion must not leave the next instance slowed down.
	Engine.time_scale = 1.0
	if _navigation_bake != null:
		_navigation_bake.wait()
		_navigation_bake = null


func _on_player_unregistered(player_id: StringName) -> void:
	super._on_player_unregistered(player_id)
	for enemy: ActorBase in CombatDirector.current.enemies():
		if enemy.threat != null:
			enemy.threat.forget(player_id)


func _physics_process(_delta: float) -> void:
	if _start_zone > 1 and InstanceManager.current.is_live() and not actors.is_empty():
		_jump_to_zone(_start_zone)
		_start_zone = 1
	var reached: int = _furthest_zone()
	if reached > zone:
		zone = reached
		_move_respawns_to(zone)
		for hud: PlayerHUD in huds.values():
			hud.show_banner(ZONE_NAMES[zone].to_upper(), "Checkpoint: you'll get back up here.", CHECKPOINT_COLOR, PASSING_BANNER_TIME)
			hud.enter_place(ZONE_NAMES[zone])
	if _start_boss_health > 0.0 and not _boss_health_applied and boss.engaged and NetworkManager.current.is_host():
		_boss_health_applied = true
		boss.stats.health = boss.stats.stats.max_health * _start_boss_health
	_steer_companions_to_plates()
	if _navigation_bake != null and _navigation_bake.finish_if_done():
		_navigation_bake = null


# --- Zones and checkpoints ------------------------------------------------

func _furthest_zone() -> int:
	var furthest: int = zone
	for actor: ActorBase in actors.values():
		var z: float = actor.global_position.z
		if z < ZONE_THREE_Z and coop_gate.is_open:
			furthest = maxi(furthest, 3)
		elif z < ZONE_TWO_Z:
			furthest = maxi(furthest, 2)
	return furthest


## Everyone's respawn point moves to the zone's checkpoint pads.
func _move_respawns_to(reached: int) -> void:
	for actor: ActorBase in actors.values():
		actor.spawn_transform = checkpoint_transform(reached, actor.party_slot)


## Where party slot `slot` respawns once the party reaches `reached` (zone 2 or 3).
func checkpoint_transform(reached: int, slot: int) -> Transform3D:
	var marker: Marker3D = checkpoints[clampi(reached, 2, 3)]
	@warning_ignore("integer_division")
	var row: int = slot / 4
	var column: float = float(slot % 4) - 1.5
	return marker.global_transform.translated(Vector3(column * CHECKPOINT_SPACING, 0.0, SPAWN_ROW_SPACING * row))


## Someone joining mid-expedition starts at the party's latest checkpoint.
func _spawn_transform(slot: int) -> Transform3D:
	return checkpoint_transform(zone, slot) if zone >= 2 else super._spawn_transform(slot)


## --zone: puts the party straight at a later zone (zone 3 opens the gate).
func _jump_to_zone(target: int) -> void:
	if target >= 3 and NetworkManager.current.is_host():
		coop_gate.open(CoopGate.Method.BELL_WINCH)
	zone = target
	for actor: ActorBase in actors.values():
		actor.spawn_at(checkpoint_transform(target, actor.party_slot))


# --- Camps, the shrine and the Wayfarer's Chest ---------------------------

## Every peer sees the Chimes scatter; the host pays them into the pouch.
func _on_camp_cleared(camp: MinionCamp) -> void:
	celebrate_camp(camp, effects_root)


## A cleared camp's payout and its Chimes bursting out to the party (the seamless world uses it too).
static func celebrate_camp(camp: MinionCamp, effects: Node3D) -> void:
	if NetworkManager.current.is_host():
		PartyProgress.current.award_chimes(CAMP_CHIMES)
	var coins: ChimeBurst = ChimeBurst.new()
	var catchers: Array[Node3D] = []
	for member: ActorBase in CombatDirector.current.alive_party():
		catchers.append(member)
	coins.configure(CAMP_CHIMES, catchers)
	effects.add_child(coins)
	coins.global_position = camp.global_position + Vector3.UP * 0.8
	AudioCues.play(&"camp_cleared")
	CombatDirector.current.show_float_text(camp.global_position + Vector3.UP * 2.5, "%s cleared!  +%d Chimes" % [camp.camp_name, CAMP_CHIMES],
		VICTORY_COLOR, CombatDirector.ANNOUNCE_TEXT_SIZE)


## Host: the alcove chest's card, an Uncommon one, rolled when it opens (with
## its own dice, so it never changes what the boss's chest drops).
static func roll_wayfarer_card() -> StringName:
	return ArsenalCatalog.current.roll_card_of_rarity(PartyProgress.current.trail_rng, ScribeCardResource.CardRarity.UNCOMMON)


func _on_wayfarer_chest_opened(opener_id: StringName, chimes: int, card_key: StringName) -> void:
	if NetworkManager.current.is_host():
		PartyProgress.current.award_chimes(chimes)
		PartyProgress.current.award_card(card_key)
	var opener: ActorBase = CombatDirector.current.get_actor(opener_id)
	var who: String = opener.display_name().get_slice(" ", 0) if opener != null else "Someone"
	for hud: PlayerHUD in huds.values():
		hud.show_banner("+%d CHIMES" % chimes, "%s found the Wayfarer's Chest! New card: %s." % [who, ArsenalCatalog.current.copy_name(card_key)], VICTORY_COLOR,
			PASSING_BANNER_TIME)


# --- The Co-Op Threshold --------------------------------------------------

func _on_gate_opened(method: int) -> void:
	var how: String = "The Maker-Seal Plates hum together" if method == CoopGate.Method.RUNE_PLATES else "The Bridge-Bell rings out"
	for hud: PlayerHUD in huds.values():
		hud.show_banner("THE GATE OPENS", "%s, and the Doverslap Gatehouse's portcullis sinks away." % how, CHECKPOINT_COLOR, PASSING_BANNER_TIME)
	for actor: ActorBase in actors.values():
		if actor.companion != null:
			actor.companion.has_assigned_post = false
	# Once the portcullis has sunk, the way through is baked into the navigation.
	get_tree().create_timer(CoopGate.PORTCULLIS_SINK_TIME + 0.3).timeout.connect(_rebake_after_gate)


func _rebake_after_gate() -> void:
	if is_inside_tree():
		_bake_navigation()


## Host: while someone holds one Maker-Seal Plate and the other needs a body, the
## nearest companion goes and stands on it.
func _steer_companions_to_plates() -> void:
	if not NetworkManager.current.is_host() or zone != 2:
		return
	steer_companions_to_plates(coop_gate, actors)


static func steer_companions_to_plates(coop_gate: CoopGate, actors: Dictionary[StringName, ActorBase]) -> void:
	var free: RunePlate = coop_gate.plate_needing_help()
	var helper: ActorBase = null
	if free != null:
		var nearest: float = INF
		for actor: ActorBase in actors.values():
			if actor.companion != null and not actor.stats.is_downed and actor.global_position.distance_to(free.global_position) < nearest:
				nearest = actor.global_position.distance_to(free.global_position)
				helper = actor
	for actor: ActorBase in actors.values():
		if actor.companion == null:
			continue
		actor.companion.has_assigned_post = actor == helper
		if actor == helper:
			actor.companion.assigned_post = free.global_position


# --- Victory --------------------------------------------------------------

## The host saw the boss fall: every peer with the expedition loaded plays the win.
func _on_boss_defeated() -> void:
	if victory or not NetworkManager.current.is_host():
		return
	var spot: Vector3 = boss.global_position + boss.facing_vector() * CHEST_OFFSET
	spot.y = 0.0
	var chimes: int = chest_chimes(NetworkManager.current.human_count())
	var card_key: String = String(ArsenalCatalog.current.roll_card_drop(PartyProgress.current.drop_rng))
	PartyProgress.current.record_victory()
	# Entered through Embershore's Root-Sanctum: the Cairnsman lulled clears it, and the trade lanes go dark (docs/20 Part I §1.4).
	if InstanceManager.current.home_instance == InstanceManager.CALDERA_ISLES and CalderaWorldState.current != null:
		CalderaWorldState.current.clear_root_sanctum()
	_begin_victory(spot, chimes, card_key)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_begin_victory.rpc_id(peer_id, spot, chimes, card_key)


@rpc("authority", "call_local", "reliable")
func _begin_victory(spot: Vector3, chimes: int, card_key: String) -> void:
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
	chest.chimes = chimes
	chest.card_key = StringName(card_key)
	effects_root.add_child(chest)
	chest.global_position = spot
	chest.opened.connect(_on_chest_opened)
	for hud: PlayerHUD in huds.values():
		hud.show_banner("VICTORY!", "The %s is defeated. Walk up to the reward chest!" % BossDummy.DISPLAY_NAME, VICTORY_COLOR)


## Time slows to a fifth for 2 real seconds. The timer ignores the time scale
## and calls Engine directly, so it ends even if the level is gone by then.
func _play_slow_motion() -> void:
	Engine.time_scale = VICTORY_TIME_SCALE
	var timer: SceneTreeTimer = get_tree().create_timer(VICTORY_SLOWMO_TIME, true, false, true)
	timer.timeout.connect(Engine.set_time_scale.bind(1.0))


## Runs on every peer when the chest opens; the host also pays out the Chimes and the card.
func _on_chest_opened(opener_id: StringName, chimes: int, card_key: StringName) -> void:
	if NetworkManager.current.is_host():
		PartyProgress.current.award_chimes(chimes)
		PartyProgress.current.award_card(card_key)
	var opener: ActorBase = CombatDirector.current.get_actor(opener_id)
	var who: String = opener.display_name().get_slice(" ", 0) if opener != null else "Someone"
	for hud: PlayerHUD in huds.values():
		hud.show_banner("+%d CHIMES" % chimes, "%s opened the chest! New card: %s. Grimoire Lv %d.\nHeading home..." % [
			who, ArsenalCatalog.current.copy_name(card_key), PartyProgress.current.grimoire_level()], VICTORY_COLOR)
	exit_portal.recall(RECALL_DELAY)


# --- Demo and report ------------------------------------------------------

## A --demo bot heads for its Maker-Seal Plate while the gate is sealed in Zone 2,
## else the nearest woken or nearby minion, else the boss.
func _demo_post_for(actor: ActorBase) -> Vector3:
	if zone == 2 and not coop_gate.is_open:
		return coop_gate.plates[actor.party_slot % coop_gate.plates.size()].global_position
	var nearest: ActorBase = null
	var best: float = 25.0
	for enemy: ActorBase in CombatDirector.current.enemies():
		if enemy.is_raid_boss() or not enemy.is_targetable():
			continue
		var distance: float = enemy.global_position.distance_to(actor.global_position)
		if distance < best:
			best = distance
			nearest = enemy
	var target: Vector3 = boss.global_position
	if nearest != null:
		target = nearest.global_position
	var angle: float = (float(actor.party_slot) - 1.5) * 0.7
	return target + Vector3(sin(angle), 0.0, cos(angle)) * DEMO_RING_RADIUS


func _demo_attacks() -> bool:
	return not victory


func _report_extra() -> String:
	var standing: int = 0
	for camp: MinionCamp in camps:
		standing += camp.standing_count()
	return "boss %d/%d hp%s, zone %d, %d kin standing, gate %s, " % [roundi(boss.stats.health), roundi(boss.stats.stats.max_health),
		" (victory)" if victory else "", zone, standing, "open" if coop_gate.is_open else "sealed"]
