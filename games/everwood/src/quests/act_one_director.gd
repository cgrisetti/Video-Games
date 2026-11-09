## Act I on Embershore (Z1_EMB; docs/28, docs/29 §4): what the five quests
## stand on, built into the isle by EmbershoreBuilder and kept in step with the
## quest ledger on every peer.
##
##   The cast        Master Alf-Wright (the orchard gate in Q01, then his
##                   wright's yard, the Feast green in Q05), Reeve Nokes and
##                   Dame Tenar-Moss (the orchard gate), Miller Hob (the mill;
##                   Forged until Q03's Hearth-Warmth)
##   Q01             three Bramble-Hound packs on Lee-Shore Orchards' grey edge;
##                   "THE GREEN IS LIT" when the party brings the colour home
##   Q02             the four groves (OrchardGrove) with their Root-Shrines
##   Q03             the Ash-Grigs in Hob's granary, the Furrow Iron-Man's Stag
##                   Hunt on the stone bridge (the bridge mended or the Rusted
##                   Iron-Man rising 10 minutes after a scatter), Hob's hearth
##   Q04             the tide-bell on North Quay (a timed Ebb-Tide window), the
##                   tide's kin in three waves on the Old Quay, the three sea-locks
##                   rung deep, warm, bright on the beat, the vault and its plaque
##   Q05             the Root-Sanctum under the Elder Oak (RootSanctum), its exit
##                   by the weir, and the Great Cake on the Feast green
##
## The host keeps every rule; each peer builds the same nodes and grows the same
## packs from the shared ledger, so paths match for the network.
class_name ActOneDirector
extends Node3D

const Kind = QuestStepResource.Kind

## How often the host checks where the heroes stand.
const PLACE_POLL: float = 0.25
## The cast's spots (Embershore's frame, x and z).
const ALF_AT_GATE: Vector2 = Vector2(-579.0, 188.0)
const ALF_AT_YARD: Vector2 = Vector2(-634.0, 255.0)
const ALF_AT_FEAST: Vector2 = Vector2(-588.0, 251.0)
const NOKES_AT_GATE: Vector2 = Vector2(-596.0, 199.0)
const NOKES_AT_GREEN: Vector2 = Vector2(-599.0, 262.0)
const TENAR_AT_GATE: Vector2 = Vector2(-590.0, 193.0)
const HOB_AT_MILL: Vector2 = Vector2(-512.0, 251.0)
## Q01's three hound packs on the orchard's grey edge (west, north, south-west).
const HOUND_PACKS: Array[Vector2] = [Vector2(-790.0, 90.0), Vector2(-560.0, 40.0), Vector2(-660.0, 190.0)]
## Q02's clutches by grove (Root, Leaf, Flower, Seed).
const CLUTCHES: Array[Array] = [
	[&"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil"],
	[&"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil"],
	[&"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil"],
	[&"grey_bark_weevil_great", &"grey_bark_weevil", &"grey_bark_weevil", &"grey_bark_weevil"],
]
## Q03: the granary's Ash-Grigs, and where the Iron-Man stands (the stone bridge's north foot).
const GRANARY_AT: Vector2 = Vector2(-500.0, 246.0)
const GUARDIAN_AT: Vector2 = Vector2(-588.5, 204.0)
const HEARTH_AT: Vector2 = Vector2(-515.0, 254.0)
## Q04: the tide-bell on the pier, the three sea-locks along the Old Quay's seaward edge, the vault at its back.
const TIDE_BELL_AT: Vector3 = Vector3(41.0, 1.6, -242.0)
const QUAY_FLOOR: float = -4.5
const SEA_LOCKS: Array[Vector2] = [Vector2(24.0, -259.0), Vector2(39.0, -259.0), Vector2(54.0, -259.0)]
const LOCK_NAMES: Array[String] = ["Deep", "Warm", "Bright"]
const VAULT_AT: Vector2 = Vector2(39.0, -244.5)
## The chain's beat: two bars of 6/8 at 104 (2.31 s), four with one or two heroes; a Squire seat two more.
const BAR_SECONDS: float = 2.0 * 60.0 / 104.0
const CHAIN_BARS: int = 2
const CHAIN_BARS_SMALL_PARTY: int = 4
const SQUIRE_EXTRA_BARS: int = 2
## The three waves on the shelf (seconds into the ebb, and who comes).
const WAVES: Array[Array] = [
	[0.0, [&"barnacle_scuttler", &"barnacle_scuttler", &"barnacle_scuttler", &"barnacle_scuttler"]],
	[40.0, [&"barnacle_scuttler", &"barnacle_scuttler", &"barnacle_scuttler", &"tide_wraith"]],
	[80.0, [&"tide_wraith", &"tide_wraith", &"barnacle_scuttler", &"barnacle_scuttler"]],
]
## The Feast green's Great Cake.
const CAKE_AT: Vector2 = Vector2(-591.0, 249.0)
## The six-line verse on the vault's bronze plaque (docs/28 §6.2; original to this game).
const PLAQUE_VERSE: String = "Grey on the quay and the bells all drowned:\nfive hands and the sea's own hand make six.\nDeep bell first, where the weed grows round;\nwarm bell next, by the lantern-wicks;\nbright bell last, where the gulls fly free,\nand the bronze will sing the grey to sea."
const GOLD: Color = Color(1.0, 0.84, 0.42)
const BANNER_TIME: float = 5.0
## Marks (QuestManager.mark) the world keeps.
const MARK_BRIDGE_MENDED: StringName = &"bridge_mended"
const MARK_WAVES_HELD: StringName = &"old_quay_waves_held"
const MARK_BELLS_RUNG: StringName = &"old_quay_bells_rung"

var builder: IslandBuilder
var alf: EverwoodNPC
var nokes: EverwoodNPC
var tenar: EverwoodNPC
var hob: EverwoodNPC
var hound_packs: Array[MobSpawner] = []
var groves: Array[OrchardGrove] = []
var granary: MobSpawner
var guardian: MobSpawner
var hearth: QuestInteractable
var tide_bell: QuestInteractable
var sea_locks: Array[QuestInteractable] = []
var vault: QuestInteractable
var cake: QuestInteractable
var sanctum: RootSanctum
var bridge_rubble: Node3D
var waves: Array[MobSpawner] = []
## Host: the Rusted Iron-Man rises when this runs out (-1: none due).
var rusted_left: float = -1.0
## Host: the World Buff's time left (the Iron-Man calmed).
var world_buff_left: float = 0.0
## Host: the sea-locks rung so far in the chain, and when the last one rang.
var chain_progress: int = 0
var chain_last_at: float = -1.0

var _poll_left: float = 0.0
var _wave_clock: float = -1.0
var _guardian_rusted: bool = false


func build(root: Node3D, island: IslandBuilder) -> void:
	builder = island
	name = "ActOne"
	root.add_child(self)
	_build_cast()
	for index: int in HOUND_PACKS.size():
		var pack: MobSpawner = MobSpawner.new()
		pack.name = "BrambleHounds%d" % (index + 1)
		pack.territory = "Lee-Shore Orchards"
		pack.variant_ids = [Bestiary.BRAMBLE_HOUND, Bestiary.BRAMBLE_HOUND, Bestiary.BRAMBLE_HOUND]
		pack.leash = 22.0
		pack.position = _ground(HOUND_PACKS[index])
		pack.add_to_group(&"caldera_streamed_spawners")
		add_child(pack)
		hound_packs.append(pack)
	_build_groves()
	_build_bridge()
	_build_quays()
	sanctum = RootSanctum.new()
	add_child(sanctum)
	var door: Vector3 = ActOnePlaces.centre(ActOnePlaces.DUNGEON_ROOT_SANCTUM)
	sanctum.build(_ground(Vector2(door.x, door.z)))
	sanctum.exit_ring.destination = (island as EmbershoreBuilder).arrival_spot(CalderaAtlas.ARRIVE_ROOT_SANCTUM) if island is EmbershoreBuilder \
		else ActOnePlaces.centre(ActOnePlaces.WEIR)
	sanctum.exit_ring.crossed.connect(_on_sanctum_exit)
	cake = _point("GreatCake", _ground(CAKE_AT), "light: take a slice of the Great Cake", 0, func() -> bool: return _on_step(ActOneQuests.Q05, &"feast"), _feast)
	add_child(ShapeKit.cylinder("CakeTier1", 0.7, 0.7, 0.35, cake.position + Vector3(0.0, 0.9, 0.0), StorybookMaterial.make(Color(0.96, 0.9, 0.78)), 16))
	add_child(ShapeKit.cylinder("CakeTier2", 0.48, 0.48, 0.3, cake.position + Vector3(0.0, 1.22, 0.0), StorybookMaterial.make(Color(0.98, 0.86, 0.5)), 16))


func _ready() -> void:
	var quests: QuestManager = QuestManager.current
	if quests != null:
		quests.quest_started.connect(_on_quest_started)
		quests.unlocked.connect(_on_unlocked)
		quests.quest_completed.connect(_on_quest_completed)
	if CalderaWorldState.current != null:
		CalderaWorldState.current.tide_changed.connect(_on_tide_changed)


func _exit_tree() -> void:
	ActorBase.world_boon_speed = 1.0
	var quests: QuestManager = QuestManager.current
	if quests != null and quests.quest_started.is_connected(_on_quest_started):
		quests.quest_started.disconnect(_on_quest_started)
		quests.unlocked.disconnect(_on_unlocked)
		quests.quest_completed.disconnect(_on_quest_completed)
	if CalderaWorldState.current != null and CalderaWorldState.current.tide_changed.is_connected(_on_tide_changed):
		CalderaWorldState.current.tide_changed.disconnect(_on_tide_changed)


func _physics_process(delta: float) -> void:
	var quests: QuestManager = QuestManager.current
	if quests == null or CombatDirector.current == null:
		return
	var host: bool = NetworkManager.current.is_host()
	if host and not quests.act_one_started() and not CombatDirector.current.party_actors().is_empty():
		quests.start_act_one()
	_sync_world()
	if not host:
		return
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = PLACE_POLL
		_report_places()
	_tick_rusted(delta)
	_tick_world_buff(delta)
	_tick_waves(delta)


# --- Keeping the world in step with the ledger (every peer) ----------------------------

func _sync_world() -> void:
	var quests: QuestManager = QuestManager.current
	var active: StringName = quests.active_quest_id()
	# The cast stand where the story needs them.
	var alf_spot: Vector2 = ALF_AT_YARD
	if active == ActOneQuests.Q01 or (active == ActOneQuests.Q02 and not _on_step(ActOneQuests.Q02, &"bench")) or active == &"" and not quests.act_one_started():
		alf_spot = ALF_AT_GATE
	elif _on_step(ActOneQuests.Q05, &"feast"):
		alf_spot = ALF_AT_FEAST
	_stand(alf, alf_spot)
	_stand(nokes, NOKES_AT_GREEN if _on_step(ActOneQuests.Q05, &"feast") else NOKES_AT_GATE)
	hob.set_state(EverwoodNPC.NpcState.FORGED if hob_forged() else EverwoodNPC.NpcState.RESTORED)
	# Q03's granary thieves and the guardian on the bridge.
	_gate(granary_wanted(), "Granary")
	_gate(guardian_wanted(), "Guardian")
	if guardian != null and not guardian.mobs.is_empty() and is_instance_valid(guardian.mobs[0]) and StagHuntEncounter.of(guardian.mobs[0]) == null:
		_attach_hunt(guardian.mobs[0])
	bridge_rubble.visible = quests.mark(MARK_BRIDGE_MENDED) == 0 and not quests.is_complete(ActOneQuests.Q03)
	# Q05's door opens while the Sanctum is the step, and the Sanctum wakes while heroes are in it.
	sanctum.entrance.enabled = active == ActOneQuests.Q05 and not _on_step(ActOneQuests.Q05, &"feast")
	var inside: bool = false
	for member: ActorBase in CombatDirector.current.party_actors():
		inside = inside or RootSanctum.contains(member.global_position)
	if inside and active == ActOneQuests.Q05:
		sanctum.wake()
		if sanctum.stag_spawner.mobs.size() > 0 and is_instance_valid(sanctum.stag_spawner.mobs[0]):
			sanctum.attach_encounter(sanctum.stag_spawner.mobs[0])
		if NetworkManager.current.is_host() and _on_step(ActOneQuests.Q05, &"descend"):
			QuestManager.current.report(Kind.EVENT, ActOneQuests.EVENT_SANCTUM_ENTERED)


## Whether Hob is still Forged: until Q03's hearth step is done.
func hob_forged() -> bool:
	var quests: QuestManager = QuestManager.current
	if quests.is_complete(ActOneQuests.Q03):
		return false
	return true


func granary_wanted() -> bool:
	return _on_step(ActOneQuests.Q03, &"granary")


func guardian_wanted() -> bool:
	var quests: QuestManager = QuestManager.current
	return quests.active_quest_id() == ActOneQuests.Q03 and (_on_step(ActOneQuests.Q03, &"hob") or _on_step(ActOneQuests.Q03, &"bridge") \
		or _on_step(ActOneQuests.Q03, &"iron_man") or _on_step(ActOneQuests.Q03, &"hearth"))


func _gate(wanted: bool, which: String) -> void:
	var spawner: MobSpawner = granary if which == "Granary" else guardian
	if wanted and spawner == null:
		spawner = MobSpawner.new()
		spawner.name = which
		if which == "Granary":
			spawner.territory = "The Old Watermill"
			spawner.variant_ids = [Bestiary.ASH_GREMLIN, Bestiary.ASH_GREMLIN, Bestiary.ASH_GREMLIN, Bestiary.ASH_GREMLIN, Bestiary.ASH_GREMLIN]
			spawner.leash = 24.0
			spawner.respawn_time = Vector2(25.0, 40.0)
			spawner.position = _ground(GRANARY_AT)
		else:
			spawner.territory = "The Stone Bridge"
			spawner.variant_ids = [Bestiary.RUSTED_IRON_MAN if _guardian_rusted else Bestiary.FURROW_IRON_MAN_GUARDIAN]
			spawner.leash = 26.0
			spawner.respawn_time = Vector2(1.0e9, 1.0e9)
			spawner.position = _ground(GUARDIAN_AT)
		add_child(spawner)
		spawner.spawn_mobs()
		if which == "Granary":
			granary = spawner
		else:
			guardian = spawner
	elif not wanted and spawner != null:
		spawner.despawn_mobs()
		spawner.queue_free()
		if which == "Granary":
			granary = null
		else:
			guardian = null


func _attach_hunt(mob: WildMob) -> void:
	var hunt: StagHuntEncounter = StagHuntEncounter.new()
	hunt.setup(mob, ActOneQuests.BOSS_FURROW_IRON_MAN)
	hunt.resolved.connect(_on_hunt_resolved)
	mob.add_child(hunt)


func _stand(npc: EverwoodNPC, spot: Vector2) -> void:
	var at: Vector3 = _ground(spot)
	if Vector2(npc.global_position.x - at.x, npc.global_position.z - at.z).length() > 0.5:
		npc.global_position = at


# --- The host's rules ---------------------------------------------------------------

func _report_places() -> void:
	for member: ActorBase in CombatDirector.current.party_actors():
		for place_id: StringName in ActOnePlaces.places_at(member.global_position):
			QuestManager.current.report(Kind.REACH_PLACE, place_id)


func _on_quest_started(quest_id: StringName) -> void:
	match quest_id:
		ActOneQuests.Q01:
			_announce("LEE-SHORE AWAKENING", "The orchard's edges have gone grey. Master Alf-Wright waits at the orchard gate.", GOLD)
		ActOneQuests.Q02:
			_announce("THE BLIGHTED CIDER-BOUGHS", "Voices at the orchard gate: Reeve Nokes wants the grey trees down.", GOLD)
		ActOneQuests.Q03:
			# The mill falls silent as Q03 begins (docs/28 §9 call 5): the Elder Oak's roots choke the weir.
			CalderaWorldState.current.set_flag(CalderaWorldState.WHEEL_STOPPED, true)
			_announce("THE SILENT MILL", "Ash-Grigs are in Miller Hob's granary, and something is smashing the stone bridge.", GOLD)
		ActOneQuests.Q04:
			_announce("SIX SHALL TURN IT BACK", "The quay bell's tongue lies in the Old Quay's vault. Ring the tide out at North Quay.", GOLD)
		ActOneQuests.Q05:
			_announce("THE ROOT-SANCTUM", "NOKES: Every great oak has sap. Every great feast has syrup.\nHe has cracked the Elder Oak's seal-stone. Grey mist pours from its roots.", GOLD)


func _on_unlocked(unlock_id: StringName) -> void:
	match unlock_id:
		ActOneQuests.UNLOCK_STEM_SOLO_BASSOON:
			# The Tier 1 Flicker-Wick moment (docs/28 §3.6): the green's lanterns relight.
			_announce("THE GREEN IS LIT", "Flicker-Wick: a solo bassoon joins the waterwheel", GOLD)
			AudioCues.play(&"bell")
		ActOneQuests.UNLOCK_SCRIBE_CRAFTING:
			_announce("MAKE INK CARDS", "Alf-Wright's bench is open: brush in Living Cider-Resin, press a card to Gilded Leaf", GOLD)
		ActOneQuests.UNLOCK_DUAL_SLOT:
			_announce("YOUR R DIAMOND IS OPEN", "A Seal and an Active together: ring a chime-post to set your cards", GOLD)
		ActOneQuests.UNLOCK_TIDAL_HOROLOGIUM:
			_announce("THE QUAY BELL RINGS", "The Tidal Horologium: the tide's turn, in the corner of your view near the quays", GOLD)
		ActOneQuests.UNLOCK_CAUSEWAYS:
			CalderaWorldState.current.clear_root_sanctum()


func _on_quest_completed(quest_id: StringName) -> void:
	if quest_id == ActOneQuests.Q05:
		_announce("THE STAR IN THE CAKE", "A little tin star warms in every hand and opens into a card: the Fay-Star Seal.\nALF-WRIGHT: It's borrowed, mind. Stars always are.", GOLD)


## Host: Q03's Stag Hunt ended.
func _on_hunt_resolved(branch: StringName, _entry: Dictionary) -> void:
	if branch == StagHuntEncounter.BRANCH_STAG:
		QuestManager.current.set_mark(MARK_BRIDGE_MENDED, 1)
		QuestManager.current.add_item(ActOneQuests.ITEM_WARMTH_EMBER, 1)
		world_buff_left = StagHuntEncounter.WORLD_BUFF_SECONDS
		_set_boon(1.1)
		rusted_left = -1.0
	else:
		rusted_left = StagHuntEncounter.RUSTED_RESPAWN_SECONDS


func _tick_rusted(delta: float) -> void:
	if rusted_left < 0.0:
		return
	rusted_left -= delta
	if rusted_left <= 0.0:
		force_rusted_rise()


## Host (and tests): the scattered Iron-Man re-forms as the Rusted Iron-Man on the bridge.
func force_rusted_rise() -> void:
	rusted_left = -1.0
	if NetworkManager.current.is_online():
		_rusted_everywhere.rpc()
	else:
		_rusted_everywhere()


@rpc("authority", "call_local", "reliable")
func _rusted_everywhere() -> void:
	_guardian_rusted = true
	if guardian != null:
		guardian.despawn_mobs()
		guardian.queue_free()
		guardian = null
	_gate(guardian_wanted(), "Guardian")
	if NetworkManager.current.is_host():
		_announce("THE RUSTED IRON-MAN RISES", "Angry and rusted, he blocks the stone bridge. Calm him this time.", Color(0.9, 0.5, 0.3))


func _tick_world_buff(delta: float) -> void:
	if world_buff_left <= 0.0:
		return
	world_buff_left -= delta
	if world_buff_left <= 0.0:
		_set_boon(1.0)


func _set_boon(speed: float) -> void:
	if NetworkManager.current.is_online():
		_boon_everywhere.rpc(speed)
	else:
		_boon_everywhere(speed)


@rpc("authority", "call_local", "reliable")
func _boon_everywhere(speed: float) -> void:
	ActorBase.world_boon_speed = speed


## Host: the Warmth-Ember into Hob's cold hearth.
func _warm_hearth(_by: StringName) -> void:
	if QuestManager.current.item_count(ActOneQuests.ITEM_WARMTH_EMBER) <= 0:
		return
	QuestManager.current.add_item(ActOneQuests.ITEM_WARMTH_EMBER, -1)
	hob.restore()
	_announce("HEARTH-WARMTH", "The ember catches. Colour floods the mill from the hearth outwards. Hob looks up.", GOLD)
	QuestManager.current.report(Kind.NPC_RESTORED, ActOneQuests.NPC_MILLER_HOB)


# --- Q04: the tide, the waves, the bells, the vault (host) -----------------------------

func _ring_tide(_by: StringName) -> void:
	if CalderaWorldState.current.start_ebb_window():
		_announce("THE TIDE IS GOING OUT", "The sea falls six metres: the Old Quay bares for four minutes", Color(0.7, 0.88, 1.0))


func _on_tide_changed(tide: int) -> void:
	if not NetworkManager.current.is_host():
		return
	if tide == CalderaWorldState.Tide.EBB:
		QuestManager.current.report(Kind.EVENT, ActOneQuests.EVENT_TIDE_EBB)
		_wave_clock = 0.0
	elif tide == CalderaWorldState.Tide.FLOODING:
		_announce("THE TIDE IS TURNING", "ALF-WRIGHT: Ring them now or wait for the next one.", Color(0.7, 0.88, 1.0))
	elif tide == CalderaWorldState.Tide.HIGH:
		_wave_clock = -1.0
		_clear_waves()
		chain_progress = 0


func _tick_waves(delta: float) -> void:
	var quests: QuestManager = QuestManager.current
	if _wave_clock < 0.0 or quests.mark(MARK_WAVES_HELD) > 0 or not (_on_step(ActOneQuests.Q04, &"waves") or _on_step(ActOneQuests.Q04, &"ebb")):
		return
	_wave_clock += delta
	for index: int in WAVES.size():
		if index >= waves.size() and _wave_clock >= float(WAVES[index][0]):
			_raise_wave(index)
	if waves.size() == WAVES.size():
		var standing: int = 0
		for wave: MobSpawner in waves:
			standing += wave.standing_count()
		if standing == 0:
			hold_waves()


func _raise_wave(index: int) -> void:
	if NetworkManager.current.is_online():
		_wave_everywhere.rpc(index)
	else:
		_wave_everywhere(index)


@rpc("authority", "call_local", "reliable")
func _wave_everywhere(index: int) -> void:
	if index < waves.size():
		return
	var wave: MobSpawner = MobSpawner.new()
	wave.name = "QuayWave%d" % (index + 1)
	wave.territory = "The Old Quay"
	var ids: Array[StringName] = []
	for id: Variant in WAVES[index][1]:
		ids.append(StringName(String(id)))
	wave.variant_ids = ids
	wave.leash = 26.0
	wave.respawn_time = Vector2(1.0e9, 1.0e9)
	wave.own_floor = true
	wave.position = Vector3(SEA_LOCKS[index].x, QUAY_FLOOR, SEA_LOCKS[index].y + 6.0)
	add_child(wave)
	wave.spawn_mobs()
	waves.append(wave)


## Host (and tests): the shelf is held against the tide's kin.
func hold_waves() -> void:
	QuestManager.current.set_mark(MARK_WAVES_HELD, 1)
	_announce("THE OLD QUAY IS HELD", "Now the plaque: deep bell first, warm bell next, bright bell last", Color(0.7, 0.88, 1.0))
	QuestManager.current.report(Kind.EVENT, ActOneQuests.EVENT_EBB_WAVES_HELD)


func _clear_waves() -> void:
	if NetworkManager.current.is_online():
		_clear_waves_everywhere.rpc()
	else:
		_clear_waves_everywhere()


@rpc("authority", "call_local", "reliable")
func _clear_waves_everywhere() -> void:
	for wave: MobSpawner in waves:
		wave.despawn_mobs()
		wave.queue_free()
	waves.clear()


## Host: a sea-lock's bell was rung (the Resonance Bell card, 1 Ink-Drop).
func ring_lock(index: int, _by: StringName = &"") -> void:
	var now: float = CombatDirector.game_time()
	var lock_at: Vector3 = sea_locks[index].global_position + Vector3.UP * 2.6
	var in_time: bool = chain_progress == 0 or now - chain_last_at <= chain_window()
	if index != chain_progress or not in_time:
		chain_progress = 0
		CombatDirector.current.announce(lock_at, "CLANG: read the plaque again. Deep, warm, bright.", Color(0.7, 0.7, 0.68), &"refuse")
		return
	chain_progress += 1
	chain_last_at = now
	CombatDirector.current.announce(lock_at, ["F", "A", "C"][index], GOLD, &"bell")
	if chain_progress < SEA_LOCKS.size():
		return
	chain_progress = 0
	QuestManager.current.set_mark(MARK_BELLS_RUNG, 1)
	CombatDirector.current.refill_ink(2, sea_locks[1].global_position, 30.0)
	_announce("THE CHORD RINGS OUT", "ALF-WRIGHT: Hear that? That's the island's own voice. The vault is open.", GOLD)
	QuestManager.current.report(Kind.EVENT, ActOneQuests.EVENT_BELL_CHAIN_RUNG)


## The chain's window: two bars, four with one or two heroes, two more with a Squire seat.
func chain_window() -> float:
	var party: Array[ActorBase] = CombatDirector.current.alive_party()
	var bars: int = CHAIN_BARS_SMALL_PARTY if party.size() <= 2 else CHAIN_BARS
	for member: ActorBase in party:
		if member.input != null and member.input.assist_mode == InputComponent.AssistMode.SQUIRE_GAMBIT:
			bars += SQUIRE_EXTRA_BARS
			break
	return float(bars) * BAR_SECONDS


func _open_vault(_by: StringName) -> void:
	_announce("THE BRONZE CARILLON TONGUE", "Green with age, taller than a child. Carry it home to the quay bell.", GOLD)
	QuestManager.current.add_item(ActOneQuests.RELIC_BRONZE_CARILLON_TONGUE, 1)


# --- Q05: out by the weir, and the Feast (host) ---------------------------------------

func _on_sanctum_exit(_threshold: PartyThreshold) -> void:
	if not NetworkManager.current.is_host():
		return
	# Out by the weir: the sap pushes the roots off it and the wheel turns again (docs/28 §7.5).
	CalderaWorldState.current.clear_root_sanctum()
	_announce("THE MILL-WHEEL TURNS", "HOB: She's turning! Listen to her! Listen!", GOLD)


func _feast(_by: StringName) -> void:
	_announce("THE GREAT AUTUMN FEAST", "NOKES: Some will tell you it was magic. Faery! Ha! Faery is for nurseries.\nThis Feast was saved by a firm hand and a good list.", GOLD)
	QuestManager.current.report(Kind.EVENT, ActOneQuests.EVENT_FEAST_COMPLETE)


# --- Building ------------------------------------------------------------------------

func _build_cast() -> void:
	alf = _npc("AlfWright", ActOneQuests.NPC_ALF_WRIGHT, "Master Alf-Wright", "Master of the Wright's Yard", ALF_AT_GATE, Color(0.46, 0.36, 0.26), Color(0.86, 0.7, 0.42), 31,
		_alf_lines)
	nokes = _npc("ReeveNokes", ActOneQuests.NPC_REEVE_NOKES, "Reeve Nokes", "Reeve of Bramblebridge", NOKES_AT_GATE, Color(0.62, 0.2, 0.22), Color(0.96, 0.8, 0.3), 37,
		_nokes_lines)
	tenar = _npc("DameTenarMoss", ActOneQuests.NPC_DAME_TENAR_MOSS, "Dame Tenar-Moss", "Herbalist", TENAR_AT_GATE, Color(0.36, 0.5, 0.32), Color(0.78, 0.66, 0.44), 41,
		_tenar_lines)
	hob = _npc("MillerHob", ActOneQuests.NPC_MILLER_HOB, "Miller Hob", "Miller", HOB_AT_MILL, Color(0.72, 0.66, 0.54), Color(0.5, 0.4, 0.3), 43, _hob_lines, true)
	hearth = _point("HobsHearth", _ground(HEARTH_AT), "light: HEARTH-WARMTH, the Warmth-Ember into Hob's cold hearth", 2,
		func() -> bool: return _on_step(ActOneQuests.Q03, &"hearth") and QuestManager.current.item_count(ActOneQuests.ITEM_WARMTH_EMBER) > 0, _warm_hearth)
	add_child(ShapeKit.cylinder("HearthStones", 0.8, 0.9, 0.5, hearth.position + Vector3(0.0, 0.25, 0.0), StorybookMaterial.make(Color(0.4, 0.38, 0.36)), 10))


func _npc(node_name: String, id: StringName, label: String, role_title: String, spot: Vector2, body: Color, accent: Color, seed_value: int,
		lines: Callable, forged: bool = false) -> EverwoodNPC:
	var npc: EverwoodNPC = EverwoodNPC.new()
	npc.name = node_name
	npc.npc_id = id
	npc.npc_name = label
	npc.title = role_title
	npc.hub = "Bramblebridge"
	npc.role = TownsfolkNPC.Role.QUEST_GIVER
	npc.set_colors(body, accent, forged)
	npc.npc_seed = seed_value
	npc.dialogue = lines
	npc.position = _ground(spot)
	add_child(npc)
	return npc


func _build_groves() -> void:
	var trees: PackedVector2Array = (builder as EmbershoreBuilder).points_of("orchard_trees") if builder is EmbershoreBuilder else PackedVector2Array()
	for index: int in ActOnePlaces.GROVES.size():
		var grove_id: StringName = ActOnePlaces.GROVES[index]
		var middle: Vector3 = ActOnePlaces.centre(grove_id)
		var oldest: Vector2 = Vector2(middle.x, middle.z)
		var best: float = INF
		for tree: Vector2 in trees:
			var distance: float = tree.distance_to(Vector2(middle.x, middle.z))
			if distance < best:
				best = distance
				oldest = tree
		var grove: OrchardGrove = OrchardGrove.new()
		grove.position = _ground(Vector2(middle.x, middle.z))
		add_child(grove)
		var clutch: Array[StringName] = []
		for id: Variant in CLUTCHES[index]:
			clutch.append(StringName(String(id)))
		grove.setup(grove_id, clutch, _ground(oldest))
		groves.append(grove)


func _build_bridge() -> void:
	bridge_rubble = Node3D.new()
	bridge_rubble.name = "BridgeRubble"
	add_child(bridge_rubble)
	var bridge: Vector3 = ActOnePlaces.centre(ActOnePlaces.NORTH_QUAY_BRIDGE)
	var deck: float = _ground(GUARDIAN_AT).y
	var stone: Material = StorybookMaterial.make(Color(0.56, 0.54, 0.5))
	for index: int in 5:
		var side: float = -1.0 if index % 2 == 0 else 1.0
		bridge_rubble.add_child(ShapeKit.box("Stone%d" % index, Vector3(0.7, 0.5, 0.6), Vector3(bridge.x + side * 2.6, deck + 0.25, bridge.z - 6.0 + index * 3.0), stone))


func _build_quays() -> void:
	tide_bell = _point("TideBell", TIDE_BELL_AT, "light: ring the tide-bell (the sea will fall)", 0,
		func() -> bool: return _on_step(ActOneQuests.Q04, &"ebb") and CalderaWorldState.current != null and CalderaWorldState.current.tide() == CalderaWorldState.Tide.HIGH,
		_ring_tide)
	add_child(ShapeKit.cylinder("TideBellPost", 0.12, 0.12, 2.4, TIDE_BELL_AT + Vector3(0.0, 1.2, 0.0), StorybookMaterial.make(Color(0.4, 0.3, 0.2)), 8))
	add_child(ShapeKit.cone("TideBellBronze", 0.32, 0.5, TIDE_BELL_AT + Vector3(0.0, 2.2, 0.0), StorybookMaterial.make(Color(0.72, 0.52, 0.28))))
	for index: int in SEA_LOCKS.size():
		var at: Vector3 = Vector3(SEA_LOCKS[index].x, QUAY_FLOOR, SEA_LOCKS[index].y)
		var which: int = index
		var lock: QuestInteractable = _point("SeaLock%s" % LOCK_NAMES[index], at, "light: ring the %s bell (Resonance Bell)" % LOCK_NAMES[index], 1,
			func() -> bool: return _on_step(ActOneQuests.Q04, &"bells") and CalderaWorldState.current.ebb_window_open(), func(by: StringName) -> void: ring_lock(which, by))
		add_child(ShapeKit.cylinder("LockWheel%d" % index, 0.6, 0.6, 0.2, at + Vector3(0.0, 1.2, 0.0), StorybookMaterial.make(Color(0.42, 0.44, 0.4)), 12))
		sea_locks.append(lock)
	vault = _point("Vault", Vector3(VAULT_AT.x, QUAY_FLOOR, VAULT_AT.y), "light: open the vault and lift the Bronze Carillon Tongue", 0,
		func() -> bool: return _on_step(ActOneQuests.Q04, &"tongue") and CalderaWorldState.current.ebb_window_open(), _open_vault)
	CalderaKit.sign_label(self, "QuayPlaque", "The Old Quay's bronze plaque\n" + PLAQUE_VERSE, Vector3(VAULT_AT.x, QUAY_FLOOR + 2.8, VAULT_AT.y))


func _point(node_name: String, at: Vector3, text: String, cost: int, open: Callable, use: Callable) -> QuestInteractable:
	var point: QuestInteractable = QuestInteractable.new()
	point.name = node_name
	point.prompt = text
	point.drop_cost = cost
	point.reach = 3.0
	point.available = open
	point.on_used = use
	point.position = at
	add_child(point)
	return point


func _ground(spot: Vector2) -> Vector3:
	return builder.ground(spot.x, spot.y) if builder != null else Vector3(spot.x, 0.0, spot.y)


func _on_step(quest_id: StringName, step_id: StringName) -> bool:
	return QuestManager.current != null and QuestManager.current.is_on_step(quest_id, step_id)


func _announce(title: String, line: String, color: Color) -> void:
	if NetworkManager.current.is_online() and NetworkManager.current.is_host():
		_announce_everywhere.rpc(title, line, color)
	else:
		_announce_everywhere(title, line, color)


@rpc("authority", "call_local", "reliable")
func _announce_everywhere(title: String, line: String, color: Color) -> void:
	var level: LevelBase = get_tree().current_scene as LevelBase if is_inside_tree() else null
	if level == null:
		return
	for hud: PlayerHUD in level.huds.values():
		hud.show_banner(title, line, color, BANNER_TIME)


# --- What the cast say (docs/28's script, by the step under way) -----------------------

func _alf_lines() -> PackedStringArray:
	var quests: QuestManager = QuestManager.current
	if _on_step(ActOneQuests.Q01, &"wake") or _on_step(ActOneQuests.Q01, &"meet_alf"):
		return PackedStringArray(["There you are. The edges have gone grey again.",
			"Look at the grass by the hedge. Like a word on a window read from the wrong side: you know it, and you don't.",
			"Take these. A stick for the hedge, a buckler for the bramble, and a Calming Seal.",
			"Wear a hound down first. When it wavers, step in and press light. Don't break it. Calm it."])
	if quests.active_quest_id() == ActOneQuests.Q01:
		return PackedStringArray(["Wear them down, then calm them. Six should bring the colour back.", "Then home to the green. Let's see it lit."])
	if _on_step(ActOneQuests.Q02, &"bench"):
		return PackedStringArray(["Resin. Good. A tree keeps its best summers in its sap.",
			"Every hound you calmed wrote a mark along your Seal's edge. Brush a little resin in.",
			"That's a card that's ready. Press it: Gilded Leaf. Same card, more of it.",
			"And this one's new: the Breaching Seal. For chains and rusted things. Hardest on a two-handed swing.",
			"The Dame was right. You can't make a good card out of a thing you don't understand."])
	if quests.active_quest_id() == ActOneQuests.Q02:
		return PackedStringArray(["Mind the Dame. She knows every tree by four names."])
	if _on_step(ActOneQuests.Q03, &"bridge") or _on_step(ActOneQuests.Q03, &"iron_man"):
		return PackedStringArray(["That's no foe. That's the old furrow-tender. Someone's turned his seal.",
			"Wear him down. Don't knock him down. When he kneels, hold your blades and finish together."])
	if quests.active_quest_id() == ActOneQuests.Q03:
		return PackedStringArray(["Fill your wells on the granary thieves. You'll want every drop on that bridge."])
	if quests.active_quest_id() == ActOneQuests.Q04:
		return PackedStringArray(["Read the plaque on the Old Quay. Deep, warm, bright.", "And mind the tide. It doesn't wait for anyone."])
	if quests.active_quest_id() == ActOneQuests.Q05:
		return PackedStringArray(["Down you go. Take everything you've learned."])
	return PackedStringArray(["It's borrowed, mind. Stars always are. One day you'll know who needs it next."])


func _nokes_lines() -> PackedStringArray:
	if QuestManager.current.active_quest_id() == ActOneQuests.Q02:
		return PackedStringArray(["NOKES: Grey trees, grey apples. Chop them, I say. Firewood for the Feast!",
			"TENAR-MOSS: You'll chop nothing, Reeve. Those trees are older than your chain of office.",
			"NOKES: Sentiment! I have a list. The list says firewood."])
	return PackedStringArray(["NOKES: Sensible management, that's what this island needs. And syrup."])


func _tenar_lines() -> PackedStringArray:
	if QuestManager.current.active_quest_id() == ActOneQuests.Q02:
		return PackedStringArray(["Root, leaf, flower, seed. Learn all four and the tree will tell you its name.",
			"The grey is in the bark: Grey-Bark Weevils. Clear them, and spare the trunks.",
			"Then give each Root-Shrine what you carry. Ael-Voran. It isn't an order. It means: be what you were."])
	return PackedStringArray(["Fog forgets. A hearth remembers."])


func _hob_lines() -> PackedStringArray:
	if hob_forged():
		return PackedStringArray(["Flour's in the loft. Wheel's stopped. That's all.", "Daughter? I don't... There's a cup. It has a W on it.", "You can go."])
	return PackedStringArray(["Wren. My Wren. She took the lantern-ferry to The Crown when the grey came.",
		"I'd forgotten her laugh. It hurts to remember her. I'd rather hurt.",
		"The bell they took to the Old Quay... ring it home, and she'll hear it across the water."])
