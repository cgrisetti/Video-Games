## Act I's checks (docs/29 §8), run on the live Embershore by
## tools/test_caldera_isles.gd right after Embershore's own checks (so by the
## smoke test and tools/run_caldera_checks.gd):
##   1  the ledger: Q01 to Q05 on the Bible's 14-level spine, and the curve
##   2  the places: every Act I POI on Embershore's real ground, the spawn in Lee-Shore Orchards
##   3  the kin: Act I's twelve on the calming rule, the Lens names on screen
##   4  the world: the cast, the packs, the groves, the quays and the Sanctum built
##   5  Q01: Alf-Wright's word gives the Calming Seal; a worn-down hound is
##      calmed with light (Ink-Drops, the quest's count); one burnt down scatters
##      (Chimes, no count); the green lit; Level 2 at 400 XP
##   6  Q02: the groves' weevils, a tree gnawed to nothing starting its grove
##      again, the Root-Shrines' Ael-Voran and resin, the bench; Level 3
##   7  Q03: the wheel stops, the granary, Hob Forged; the Iron-Man scattered
##      (the Rabbit: -15) and risen rusted; the kneel, the Amber Chime (health
##      locked), the Deep-Ink finisher (the Stag: +135); Hob restored; the
##      Seal-and-Active pair at Level 4
##   8  Q04: the tide-bell's window, the waves, the bells rung out of order and
##      late (reset) then deep, warm, bright; the vault; the Horologium; Level 5
##   9  Q05: the Sanctum's chambers (the two valves together), the Taproot
##      Stag's floor, chains, Forging Fog and Hearth-Ward, the Naming; out by
##      the weir; the Feast; Level 6 at 3,800 XP
##  10  saving: the ledger round-trips, and an old-curve save keeps its levels
extends RefCounted

const Kind = QuestStepResource.Kind
const QUEST_UI: GDScript = preload("res://tools/test_quest_ui.gd")

var check: Callable
var level: CalderaArchipelagoWorld
var tree: SceneTree
var builder: EmbershoreBuilder
var director: ActOneDirector
var quests: QuestManager
var progress: PartyProgress
var state: CalderaWorldState

var _saved_xp: int = 0
var _saved_hero_xp: Dictionary[StringName, int] = {}


func run(live_level: CalderaArchipelagoWorld, checker: Callable, scene_tree: SceneTree) -> void:
	check = checker
	level = live_level
	tree = scene_tree
	builder = CalderaAtlas.builder_for(CalderaAtlas.ISLE_EMBERSHORE) as EmbershoreBuilder
	quests = QuestManager.current
	progress = PartyProgress.current
	state = CalderaWorldState.current
	_check_ledger()
	_check_kin()
	director = level.streamer.structures.find_child("ActOne", true, false) as ActOneDirector
	if director == null or quests == null or builder == null:
		check.call(false, "Act I is built into Embershore (ActOneDirector) and the QuestManager autoload is live")
		return
	_check_places()
	_check_world()
	# A fresh Act I on a Level 1 party (the checks' endgame party is put back afterwards).
	_saved_xp = progress.xp
	_saved_hero_xp = progress.hero_xp.duplicate()
	progress.xp = 0
	for class_id: StringName in progress.hero_xp:
		progress.hero_xp[class_id] = 0
	quests.reset_for_testing()
	quests.start_act_one()
	# The quest screens first (they reset the ledger and start Act I afresh when done).
	await QUEST_UI.new().run(level, check, tree, director, _p1())
	await _check_q01()
	await _check_q02()
	await _check_q03()
	await _check_q04()
	await _check_q05()
	_check_saving()
	await _tidy()


# --- 1: the ledger --------------------------------------------------------------------------------

func _check_ledger() -> void:
	var levels: Array[int] = []
	var xps: Array[int] = []
	var cumulative: Array[int] = []
	var steps: int = 0
	for quest: QuestDefinition in ActOneQuests.all():
		levels.append(quest.level_to)
		xps.append(quest.xp_reward)
		cumulative.append(quest.cumulative_xp)
		steps += quest.steps.size()
	var curve_ok: bool = PartyProgress.LEVEL_XP.size() == PartyProgress.MAX_CHARACTER_LEVEL and PartyProgress.XP_CEILING == 30500
	for row: Array in ActOneQuests.LEDGER:
		var reached: int = int(row[3])
		curve_ok = curve_ok and PartyProgress.level_for_xp(int(row[5])) == reached
	check.call(ActOneQuests.ORDER.size() == 5 and levels == [2, 3, 4, 5, 6] and xps == [400, 500, 700, 900, 1300] and cumulative == [400, 900, 1600, 2500, 3800]
		and steps == 21 and ActOneQuests.quest(ActOneQuests.Q01).zone_id == &"Z1_EMB" and curve_ok,
		"the ledger: Q01 to Q05 on Embershore (Z1_EMB), %d steps, +400 / 500 / 700 / 900 / 1,300 XP to Levels 2 to 6, and every row of the Bible's Master Quest Ledger lands on its level of the 14-level spine (cap 30,500 XP)"
		% steps)


# --- 2: the places --------------------------------------------------------------------------------

func _check_places() -> void:
	var off: PackedStringArray = PackedStringArray()
	for place_id: Variant in ActOnePlaces.PLACES:
		# The Old Quay's shelf and North Quay's pier stand over the sea floor; the Sanctum is under the ground.
		if place_id == ActOnePlaces.OLD_QUAY_EBB_SHELF or place_id == ActOnePlaces.DUNGEON_ROOT_SANCTUM or place_id == ActOnePlaces.NORTH_QUAY:
			continue
		var middle: Vector3 = ActOnePlaces.centre(StringName(place_id))
		var ground: float = builder.ground(middle.x, middle.z).y
		var band: Vector2 = ActOnePlaces.band(StringName(place_id))
		if ground < band.x - 1.5 or ground > band.y + 1.5:
			off.append("%s %.1f m" % [ActOnePlaces.display_name(StringName(place_id)), ground])
	var spawn: Vector3 = builder.arrival_spot(CalderaAtlas.ARRIVE_START, 0)
	check.call(off.is_empty() and ActOnePlaces.contains(ActOnePlaces.LEE_SHORE_ORCHARDS, spawn) and not ActOnePlaces.contains(ActOnePlaces.HEARTHSTEAD_MARKET, spawn)
		and ActOnePlaces.bible_elevation(ActOnePlaces.GROVE_SEED) == 45.0 and ActOnePlaces.bible_elevation(ActOnePlaces.OLD_QUAY_EBB_SHELF) == -6.0,
		"the places: every Act I spot stands on Embershore's real ground within its band (the Bible's +15 to +45 m tiers are 6 to 18 m here), and the Level 1 spawn is in Lee-Shore Orchards%s"
		% ("" if off.is_empty() else " (off: %s)" % ", ".join(off)))


# --- 3: the kin -----------------------------------------------------------------------------------

func _check_kin() -> void:
	var kin: Array[MobVariantResource] = Bestiary.family_of(MobVariantResource.Family.EMBERSHORE_ACT_ONE)
	var all_calm: bool = kin.size() == 12
	for variant: MobVariantResource in kin:
		all_calm = all_calm and variant.calm_rule
	check.call(all_calm and Bestiary.variant(Bestiary.ASH_GREMLIN).display_name == "Ash-Grig" and Bestiary.variant(Bestiary.TIDE_WRAITH).display_name == "Tide-Wight"
		and Bestiary.variant(Bestiary.SAP_ELEMENTAL).display_name == "Sap-Boggart" and Bestiary.variant(Bestiary.GREY_BARK_WEEVIL).targets_trees
		and Bestiary.variant(Bestiary.TIDE_WRAITH).stamina_slow > 0.0 and Bestiary.variant(Bestiary.FURROW_IRON_MAN_GUARDIAN).has_maker_seal
		and Bestiary.variant(Bestiary.FURROW_IRON_MAN_GUARDIAN).scatter_chimes == StagHuntEncounter.RABBIT_SCRAP,
		"Act I's twelve kin keep the calming rule; the brief's Ash-Gremlin, Tide-Wraith and Sap-Elemental read Ash-Grig, Tide-Wight and Sap-Boggart on screen; weevils go for trees, Tide-Wights chill, the Iron-Man wears his seal and scatters for 25 Chimes")


# --- 4: the world built ---------------------------------------------------------------------------

func _check_world() -> void:
	var problems: PackedStringArray = PackedStringArray()
	for npc: EverwoodNPC in [director.alf, director.nokes, director.tenar, director.hob]:
		if npc == null or not npc.is_inside_tree():
			problems.append("a townsperson missing")
	if director.hound_packs.size() != 3 or director.groves.size() != 4:
		problems.append("%d hound packs, %d groves" % [director.hound_packs.size(), director.groves.size()])
	for grove: OrchardGrove in director.groves:
		if grove.tree == null or grove.shrine == null:
			problems.append("%s has no tree or shrine" % grove.name)
	if director.sea_locks.size() != 3 or director.vault == null or director.tide_bell == null or director.cake == null:
		problems.append("the quays or the cake missing")
	if director.sanctum == null or director.sanctum.entrance == null or director.sanctum.chambers.size() != 3:
		problems.append("the Sanctum missing")
	if level.streamer.structures.find_child("QuayPlaque", true, false) == null:
		problems.append("no plaque")
	check.call(problems.is_empty() and director.hob.is_forged() and not director.alf.is_forged(),
		"Act I stands on Embershore: Alf-Wright, Nokes, Tenar-Moss and a Forged Miller Hob, three hound packs, four groves with their trees and Root-Shrines, the tide-bell, three sea-locks, the vault and its plaque, the Great Cake and the Root-Sanctum%s"
		% ("" if problems.is_empty() else ": " + "; ".join(problems)))


# --- 5: Q01 ---------------------------------------------------------------------------------------

func _check_q01() -> void:
	var p1: ActorBase = _p1()
	_place_party(builder.arrival_spot(CalderaAtlas.ARRIVE_START, 0))
	await _seconds(0.6)
	var on_alf: bool = quests.is_on_step(ActOneQuests.Q01, &"meet_alf")
	var refused: bool = not CalmingComponent.seal_in_hand()
	_talk(director.alf, p1)
	var sealed: bool = quests.has_unlock(ActOneQuests.UNLOCK_CALMING_SEAL) and quests.is_on_step(ActOneQuests.Q01, &"calm_hounds")
	check.call(on_alf and refused and sealed and quests.tracker_line().contains("Bramble-Hounds"),
		"Q01: waking in Lee-Shore Orchards asks for Master Alf-Wright; a wavering hound can't be calmed before his word, and his word gives the Calming Seal and the hounds to calm")
	# A worn-down hound, calmed with light.
	var pack: MobSpawner = director.hound_packs[0]
	pack.spawn_mobs()
	await _frames(2)
	var hound: WildMob = pack.mobs[0]
	_place_party(hound.global_position + Vector3(2.0, 0.0, 0.0))
	await _frames(2)
	hound.stats.take_damage(hound.stats.health * 0.8)
	p1.stats.add_resonance(-99.0)
	var drops_before: int = p1.stats.resonance_pips()
	var wavering: bool = hound.calming.is_wavering()
	hound.calming.interact(p1)
	await _frames(2)
	# The checks' classic endgame kits run on the old pips, not the Ink-Well: only a well-hero must see drops come back.
	var paid: bool = not p1.stats.uses_ink_well() or p1.stats.resonance_pips() > drops_before
	var calmed: bool = hound.calming.was_calmed and hound.stats.is_downed and paid and quests.count_of(ActOneQuests.Q01) == 1
	# One burnt to nothing only scatters.
	var chimes_before: int = progress.chimes
	var other: WildMob = pack.mobs[1]
	other.stats.take_damage(other.stats.health + 10.0)
	await _frames(2)
	var scattered: bool = other.stats.is_downed and not other.calming.was_calmed and progress.chimes == chimes_before + Bestiary.variant(Bestiary.BRAMBLE_HOUND).scatter_chimes \
		and quests.count_of(ActOneQuests.Q01) == 1
	check.call(wavering and calmed and scattered,
		"Q01: a hound worn under a quarter wavers and light calms it (the Recovery burst, Ink-Drops into the well, 1 of 6); one burnt to nothing only scatters (2 Chimes, no count) [wavering %s, calmed %s/%s, paid %s, count %d, scattered %s, chimes +%d]"
		% [wavering, hound.calming.was_calmed, hound.stats.is_downed, paid, quests.count_of(ActOneQuests.Q01), scattered, progress.chimes - chimes_before])
	# Five more calms finish the step; the green lights.
	var calmed_count: int = 1
	for spawner: MobSpawner in [pack, director.hound_packs[1], director.hound_packs[2]]:
		spawner.spawn_mobs()
		await _frames(1)
		for mob: WildMob in spawner.mobs:
			if calmed_count >= 6 or not is_instance_valid(mob) or mob.stats.is_downed:
				continue
			mob.stats.take_damage(mob.stats.health * 0.9)
			mob.calming.calm_entity(p1.player_id)
			calmed_count += 1
	await _frames(2)
	var to_green: bool = quests.is_on_step(ActOneQuests.Q01, &"green")
	_place_party(ActOnePlaces.centre(ActOnePlaces.HEARTHSTEAD_MARKET))
	await _seconds(0.6)
	check.call(to_green and quests.is_complete(ActOneQuests.Q01) and quests.has_unlock(ActOneQuests.UNLOCK_STEM_SOLO_BASSOON)
		and progress.trail_level() == 2 and progress.xp == 400 and quests.active_quest_id() == ActOneQuests.Q02,
		"Q01: six hounds calmed, the green lit (the Flicker-Wick bassoon), Level 2 at exactly 400 XP (calms paid part, the hand-in the rest), and Q02 begins (Lv %d, %d XP)"
		% [progress.trail_level(), progress.xp])


# --- 6: Q02 ---------------------------------------------------------------------------------------

func _check_q02() -> void:
	var p1: ActorBase = _p1()
	_place_party(ActOnePlaces.centre(ActOnePlaces.ORCHARD_GATE))
	await _frames(2)
	_talk(director.tenar, p1)
	var groves_step: bool = quests.is_on_step(ActOneQuests.Q02, &"groves")
	await _frames(2)
	var raised: int = 0
	for grove: OrchardGrove in director.groves:
		raised += 1 if grove.spawner != null and grove.tree.protected else 0
	# A tree gnawed to nothing starts its grove again.
	var leaf: OrchardGrove = director.groves[1]
	var first_clutch: MobSpawner = leaf.spawner
	leaf.tree.gnaw(OrchardTree.MAX_BARK + 1.0)
	await _frames(3)
	var restarted: bool = leaf.tree.times_felled == 1 and leaf.spawner != null and leaf.spawner != first_clutch and leaf.state() == 0
	check.call(groves_step and raised == 4 and restarted,
		"Q02: Tenar-Moss sends the party to the four groves, whose weevils come up and go for the oldest trees; a tree gnawed to nothing goes grey and its grove starts again")
	for grove: OrchardGrove in director.groves:
		_place_party(grove.tree.global_position + Vector3(3.0, 0.0, 3.0))
		await _frames(2)
		for mob: WildMob in grove.spawner.mobs:
			if is_instance_valid(mob) and not mob.stats.is_downed:
				mob.stats.take_damage(mob.stats.health * 0.9)
				mob.calming.calm_entity(p1.player_id)
		await _frames(3)
	var cleared: bool = quests.is_on_step(ActOneQuests.Q02, &"shrines")
	for grove: OrchardGrove in director.groves:
		cleared = cleared and grove.state() == OrchardGrove.CLEAR
	# Each hero in reach pours three drops; the shrine speaks Ael-Voran.
	var root: OrchardGrove = director.groves[0]
	_place_party(root.shrine.global_position + Vector3(1.0, 0.0, 0.0))
	await _frames(3)
	var heroes: int = 0
	for member: ActorBase in level.party_in_order():
		if member.global_position.distance_to(root.shrine.global_position) <= OrchardGrove.SHRINE_REACH and not member.stats.is_downed:
			heroes += 1
	var partial: bool = true
	for pour: int in OrchardGrove.DROPS_PER_HERO * heroes:
		if pour == OrchardGrove.DROPS_PER_HERO * heroes - 1:
			partial = root.state() == OrchardGrove.CLEAR
		root.shrine.use_as(p1.player_id)
	var lit: bool = partial and root.state() == OrchardGrove.LIT and quests.item_count(ActOneQuests.ITEM_LIVING_CIDER_RESIN) == OrchardGrove.RESIN_PER_SHRINE
	for index: int in range(1, 4):
		director.groves[index].light_shrine()
	await _frames(2)
	var bench: bool = quests.is_on_step(ActOneQuests.Q02, &"bench") and quests.item_count(ActOneQuests.ITEM_LIVING_CIDER_RESIN) == 12
	_place_party(ActOnePlaces.centre(ActOnePlaces.WRIGHTS_YARD))
	await _frames(3)
	_talk(director.alf, p1)
	check.call(cleared and lit and bench and quests.is_complete(ActOneQuests.Q02) and quests.has_unlock(ActOneQuests.UNLOCK_SCRIBE_CRAFTING)
		and quests.has_unlock(ActOneQuests.UNLOCK_BREACHING_SEAL) and progress.trail_level() == 3,
		"Q02: every grove cleared; a Root-Shrine waits for three drops from each of the %d heroes in reach, then Ael-Voran blooms it and gives 3 Living Cider-Resin (12 in all); Alf-Wright's bench opens Make Ink Cards and the Breaching Seal; Level 3 (%d XP)"
		% [heroes, progress.xp])


# --- 7: Q03 ---------------------------------------------------------------------------------------

func _check_q03() -> void:
	var p1: ActorBase = _p1()
	await _frames(3)
	var wheel: bool = state.wheel_stopped
	_place_party(ActOnePlaces.centre(ActOnePlaces.OLD_WATERMILL))
	await _frames(3)
	var grigs: int = director.granary.mobs.size() if director.granary != null else 0
	if director.granary != null:
		for mob: WildMob in director.granary.mobs:
			mob.stats.take_damage(mob.stats.health * 0.9)
			mob.calming.calm_entity(p1.player_id)
	await _frames(3)
	var forged_words: String = director.hob.current_lines()[0] if director.hob_forged() else ""
	_talk(director.hob, p1)
	check.call(wheel and grigs == 5 and director.granary == null and quests.is_on_step(ActOneQuests.Q03, &"bridge") and director.hob.is_forged()
		and forged_words.begins_with("Flour's in the loft"),
		"Q03: the mill-wheel stops as Q03 begins; five Ash-Grigs calmed in the granary; Miller Hob stands grey and speaks flat (\"%s\")" % forged_words)
	_place_party(ActOnePlaces.centre(ActOnePlaces.NORTH_QUAY_BRIDGE))
	await _seconds(0.6)
	var at_bridge: bool = quests.is_on_step(ActOneQuests.Q03, &"iron_man")
	# The Rabbit: burnt to nothing, he scatters, and rises rusted ten minutes on.
	var guardian: WildMob = director.guardian.mobs[0] if director.guardian != null and not director.guardian.mobs.is_empty() else null
	var hunt: StagHuntEncounter = StagHuntEncounter.of(guardian)
	var chimes_before: int = progress.chimes
	if guardian != null:
		_place_party(guardian.global_position + Vector3(3.0, 0.0, 0.0))
		await _frames(2)
		guardian.stats.take_damage(guardian.stats.health + 10.0)
	await _frames(3)
	var rabbit: Dictionary = progress.stag_hunts.back() if not progress.stag_hunts.is_empty() else {}
	check.call(at_bridge and hunt != null and hunt.phase == StagHuntEncounter.Phase.RESOLVED and str(rabbit.get("branch", "")) == "rabbit"
		and int(rabbit.get("net_utility", 0)) == StagHuntEncounter.RABBIT_NET and int(rabbit.get("hazard", 0)) == StagHuntEncounter.RABBIT_HAZARD
		and progress.chimes == chimes_before + StagHuntEncounter.RABBIT_SCRAP and director.rusted_left > StagHuntEncounter.RUSTED_RESPAWN_SECONDS - 5.0
		and quests.is_on_step(ActOneQuests.Q03, &"iron_man"),
		"Q03, the Rabbit: the Iron-Man burnt to nothing scatters (25 Chimes, -40 hazard, -15 net, logged), the Rusted Iron-Man is due in 10 minutes, and the quest waits [hunt %s, %s, chimes +%d, rusted in %.0f s]"
		% [hunt != null, rabbit, progress.chimes - chimes_before, director.rusted_left])
	director.force_rusted_rise()
	await _frames(3)
	guardian = director.guardian.mobs[0] if director.guardian != null and not director.guardian.mobs.is_empty() else null
	hunt = StagHuntEncounter.of(guardian)
	var rusted: bool = guardian != null and guardian.variant.variant_id == Bestiary.RUSTED_IRON_MAN and hunt != null
	if not rusted:
		check.call(false, "Q03: the Rusted Iron-Man rises with his Stag Hunt")
		return
	_place_party(guardian.global_position + Vector3(3.0, 0.0, 0.0))
	await _frames(2)
	# The Stag: a kneel missed once, then the chime, blades held, Deep-Ink from every hero in reach.
	hunt.force_kneel()
	var kneeled: bool = hunt.phase == StagHuntEncounter.Phase.KNEELING and hunt.bearer != &""
	hunt._missed()
	var missed: bool = hunt.phase == StagHuntEncounter.Phase.FIGHTING and is_equal_approx(guardian.stats.poise, guardian.stats.stats.max_poise * StagHuntEncounter.MISSED_POSTURE)
	hunt.force_kneel()
	hunt.ring_chime(hunt.bearer)
	var health_before: float = guardian.stats.health
	guardian.stats.take_damage(200.0)
	var held: bool = hunt.phase == StagHuntEncounter.Phase.AMBER and guardian.stats.health_locked and guardian.amber and is_equal_approx(guardian.stats.health, health_before)
	var pourers: Array[ActorBase] = hunt.heroes_in_reach()
	for member: ActorBase in pourers:
		hunt.pour(member.player_id)
	await _frames(3)
	var stag: Dictionary = progress.stag_hunts.back() if not progress.stag_hunts.is_empty() else {}
	check.call(rusted and kneeled and missed and held and guardian.calming.was_calmed and str(stag.get("branch", "")) == "stag"
		and int(stag.get("net_utility", 0)) == StagHuntEncounter.STAG_NET and int(stag.get("world_buff", 0)) == StagHuntEncounter.STAG_WORLD_BUFF
		and quests.is_on_step(ActOneQuests.Q03, &"hearth") and quests.item_count(ActOneQuests.ITEM_WARMTH_EMBER) == 1
		and quests.mark(ActOneDirector.MARK_BRIDGE_MENDED) == 1 and is_equal_approx(ActorBase.world_boon_speed, 1.1),
		"Q03, the Stag: posture broken he kneels (a missed window stands him up with half his posture); the Lantern-Bearer's Amber Chime locks his health amber; Deep-Ink from all %d heroes in reach calms him (+120 World Buff, +135 net, logged): the bridge mended, +10%% speed, the Warmth-Ember"
		% pourers.size())
	_place_party(ActOnePlaces.centre(ActOnePlaces.OLD_WATERMILL))
	await _frames(3)
	director.hearth.use_as(p1.player_id)
	await _frames(2)
	var restored_words: String = director.hob.current_lines()[0]
	check.call(not director.hob.is_forged() and restored_words.begins_with("Wren") and quests.is_complete(ActOneQuests.Q03)
		and quests.has_unlock(ActOneQuests.UNLOCK_DUAL_SLOT) and quests.has_unlock(ActOneQuests.UNLOCK_HEARTH_WARMTH) and progress.trail_level() == 4
		and GrimoireRules.seal_open(0, 4) and GrimoireRules.socket_open_at(GrimoireRules.SOCKET_R, 4) and not GrimoireRules.socket_open_at(GrimoireRules.SOCKET_R, 3),
		"Q03: Hearth-Warmth at Hob's hearth restores him (\"%s\"); Level 4 opens the R card beside Lv 3's weapon Seal: the Seal-and-Active pair (the brief's Dual Active/Seal Slot)"
		% restored_words)


# --- 8: Q04 ---------------------------------------------------------------------------------------

func _check_q04() -> void:
	var p1: ActorBase = _p1()
	await _frames(2)
	var high: bool = state.tide() == CalderaWorldState.Tide.HIGH and is_equal_approx(state.sea_level_y, 0.0)
	director.tide_bell.use_as(p1.player_id)
	var ebbing: bool = state.tide() == CalderaWorldState.Tide.EBBING
	state.advance_window_for_testing(CalderaWorldState.EBB_WINDOW_FALL + 1.0)
	await _frames(3)
	var out: bool = state.ebb_window_open() and is_equal_approx(state.sea_level_y, CalderaWorldState.SEA_LEVEL_EBB) and not state.ebb_unlocked \
		and quests.is_on_step(ActOneQuests.Q04, &"waves") and state.tide_dial_text().begins_with("EBB-TIDE")
	var wave: MobSpawner = director.waves[0] if not director.waves.is_empty() else null
	var first_wave: bool = wave != null and wave.own_floor and not wave.mobs.is_empty() and absf(wave.mobs[0].global_position.y - ActOneDirector.QUAY_FLOOR) < 1.5
	check.call(high and ebbing and out and first_wave,
		"Q04: the tide-bell opens a timed Ebb-Tide (never the Bell's permanent ebb): the sea falls 6 m in 20 s, the Horologium reads EBB-TIDE, and the first wave of the tide's kin comes up on the Old Quay's shelf")
	director.hold_waves()
	await _frames(2)
	var bells_step: bool = quests.is_on_step(ActOneQuests.Q04, &"bells")
	director.ring_lock(1)
	var wrong_reset: bool = director.chain_progress == 0
	director.ring_lock(0)
	director.chain_last_at = CombatDirector.game_time() - 30.0
	director.ring_lock(1)
	var late_reset: bool = director.chain_progress == 0
	director.ring_lock(0)
	director.ring_lock(1)
	director.ring_lock(2)
	await _frames(2)
	var rung: bool = quests.is_on_step(ActOneQuests.Q04, &"tongue") and quests.mark(ActOneDirector.MARK_BELLS_RUNG) == 1
	director.vault.use_as(p1.player_id)
	await _frames(2)
	var window: float = director.chain_window()
	check.call(bells_step and wrong_reset and late_reset and rung and quests.is_complete(ActOneQuests.Q04)
		and quests.item_count(ActOneQuests.RELIC_BRONZE_CARILLON_TONGUE) == 1 and quests.has_unlock(ActOneQuests.UNLOCK_TIDAL_HOROLOGIUM)
		and progress.trail_level() == 5 and window > 2.0,
		"Q04: the shelf held; a bell out of order or late clangs the chain back (window %.2f s); deep, warm, bright rings the chord, the vault gives the Bronze Carillon Tongue, the Horologium opens, Level 5"
		% window)
	state.advance_window_for_testing(CalderaWorldState.EBB_WINDOW_OUT + CalderaWorldState.EBB_WINDOW_FLOOD + 1.0)
	await _frames(3)
	check.call(state.tide() == CalderaWorldState.Tide.HIGH and is_equal_approx(state.sea_level_y, 0.0) and director.waves.is_empty(),
		"Q04: four minutes out, the tide floods back over 30 s to high water and the shelf's waves are gone")


# --- 9: Q05 ---------------------------------------------------------------------------------------

func _check_q05() -> void:
	var p1: ActorBase = _p1()
	var sanctum: RootSanctum = director.sanctum
	await _frames(2)
	var door_open: bool = sanctum.entrance.enabled
	_place_party_exact(RootSanctum.ARRIVAL)
	await _frames(4)
	var inside: bool = quests.is_on_step(ActOneQuests.Q05, &"chambers")
	# Chamber 1: calm the gallery's pulls.
	for spawner: MobSpawner in sanctum.chambers[0]:
		for mob: WildMob in spawner.mobs:
			if is_instance_valid(mob) and not mob.stats.is_downed:
				mob.stats.take_damage(mob.stats.health * 0.9)
				mob.calming.calm_entity(p1.player_id)
	await _frames(3)
	var gallery: bool = sanctum.cleared[0] and quests.count_of(ActOneQuests.Q05) == 1
	# Chamber 2: one valve alone re-greys; both together clear it.
	var first: WildMob = sanctum.valve_spawners[0].mobs[0]
	first.calming.calm_entity(p1.player_id)
	await _seconds(RootSanctum.VALVE_WINDOW + 1.0)
	var regreyed: bool = not sanctum.cleared[1] and sanctum.valve_spawners[0].standing_count() == 1
	for valve: MobSpawner in sanctum.valve_spawners:
		var mob: WildMob = valve.mobs[0]
		if not mob.stats.is_downed:
			mob.calming.calm_entity(p1.player_id)
	await _frames(3)
	var valves: bool = sanctum.cleared[1]
	for spawner: MobSpawner in sanctum.chambers[2]:
		for mob: WildMob in spawner.mobs:
			if is_instance_valid(mob) and not mob.stats.is_downed:
				mob.calming.calm_entity(p1.player_id)
	await _frames(4)
	var stag: WildMob = sanctum.stag_spawner.mobs[0] if not sanctum.stag_spawner.mobs.is_empty() else null
	var encounter: TaprootStagEncounter = sanctum.stag_encounter
	check.call(door_open and inside and gallery and regreyed and valves and sanctum.cleared[2] and quests.is_on_step(ActOneQuests.Q05, &"stag")
		and stag != null and encounter != null,
		"Q05: the Root-Sanctum's door opens; inside, the Sap-Gallery calmed, a valve calmed alone re-greys and both together run the sap again, the hall's Root-Lurkers calmed: three chambers, and the Taproot Stag wakes")
	if stag == null or encounter == null:
		return
	_place_party_exact(stag.global_position + Vector3(3.0, 0.0, 0.0))
	await _frames(2)
	stag.stats.take_damage(stag.stats.stats.max_health * 5.0)
	var floored: bool = not stag.stats.is_downed and stag.stats.health >= stag.stats.stats.max_health * TaprootStagEncounter.HEALTH_FLOOR - 0.5
	encounter.force_kneel()
	encounter.strike_chain(EquipmentItemResource.WeaponType.HEAVY_AXE, true)
	var two_hand: bool = encounter.chains_broken == 1
	encounter.force_kneel()
	encounter.strike_chain(EquipmentItemResource.WeaponType.LIGHT_SWORD, true)
	encounter.strike_chain(EquipmentItemResource.WeaponType.LIGHT_SWORD, true)
	var one_hand_holds: bool = encounter.chains_broken == 1
	encounter.strike_chain(EquipmentItemResource.WeaponType.LIGHT_SWORD, true)
	var fog_phase: bool = encounter.chains_broken == 2 and encounter.phase == TaprootStagEncounter.Phase.FOG
	check.call(floored and two_hand and one_hand_holds and fog_phase,
		"Q05: no scatter here (the Stag's health stops at a tenth while a chain holds); kneeling, its glowing chain breaks to one two-handed Breaching heavy, to three one-handed; two chains gone, the Forging Fog begins")
	# Forging Fog greys a card over; Hearth-Ward clears it and keeps it off.
	CardFog.reset()
	encounter.fog_hero(p1)
	var fogged: Array[int] = CardFog.fogged_sockets(p1.player_id)
	var locked: bool = not fogged.is_empty() and p1.seal != null and not p1.seal.is_trigger_slot_unlocked(EquipmentSealComponent.SOCKET_TRIGGERS[fogged[0]])
	_place_party_exact(encounter.brazier.global_position + Vector3(1.0, 0.0, 0.0))
	await _frames(2)
	encounter.brazier.use_as(p1.player_id)
	var cleared: bool = not CardFog.any_fogged(p1.player_id)
	encounter.fog_hero(p1)
	var warded: bool = not CardFog.any_fogged(p1.player_id)
	check.call(locked and cleared and warded,
		"Q05: Forging Fog padlocks %d of P1's card sockets (they won't play); the Hearth-Brazier's Hearth-Ward clears it and keeps it off for 6 s" % fogged.size())
	encounter.force_kneel()
	encounter.strike_chain(EquipmentItemResource.WeaponType.HEAVY_AXE, true)
	var taproot: bool = encounter.phase == TaprootStagEncounter.Phase.TAPROOT
	encounter.force_kneel()
	encounter.strike_chain(EquipmentItemResource.WeaponType.STAFF, true)
	var naming: bool = encounter.phase == TaprootStagEncounter.Phase.NAMING and stag.stats.health_locked
	_place_party_exact(stag.global_position + Vector3(3.0, 0.0, 0.0))
	await _frames(2)
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.global_position.distance_to(stag.global_position) <= TaprootStagEncounter.NAMING_REACH:
			encounter.pour_name(member.player_id)
	await _frames(3)
	var named: bool = stag.calming.was_calmed and encounter.phase == TaprootStagEncounter.Phase.RESOLVED and quests.is_on_step(ActOneQuests.Q05, &"feast")
	check.call(taproot and naming and named and sanctum.exit_ring.enabled,
		"Q05: the third chain wakes the Taproot's Root-Lurkers; the fourth sinks the Stag for the Naming, and every hero in reach pours three drops: ELDERHART, calmed; the way out by the weir opens")
	sanctum.exit_ring.crossed.emit(sanctum.exit_ring)
	await _frames(4)
	var weir: bool = state.root_sanctum_cleared and not RootSanctum.contains(p1.global_position)
	_place_party(ActOnePlaces.centre(ActOnePlaces.HEARTHSTEAD_MARKET))
	await _frames(3)
	director.cake.use_as(p1.player_id)
	await _frames(3)
	var all_done: bool = true
	for quest_id: StringName in ActOneQuests.ORDER:
		all_done = all_done and quests.is_complete(quest_id)
	check.call(weir and all_done and quests.has_unlock(ActOneQuests.UNLOCK_FAY_STAR_SEAL) and quests.has_unlock(ActOneQuests.UNLOCK_CAUSEWAYS)
		and progress.trail_level() == 6 and progress.xp == 3800 and quests.active_quest_id() == &"" and progress.stag_hunts.size() == 3,
		"Q05: out by the weir the Root-Sanctum is cleared (the wheel turns, the causeways open); the Great Cake's star is the Fay-Star Seal; all five quests done at Level 6 with exactly 3,800 XP (%d) and three Stag Hunts in the ledger"
		% progress.xp)


# --- 10: saving -----------------------------------------------------------------------------------

func _check_saving() -> void:
	var path: String = "user://act_one_round_trip.cfg"
	var writer: PartyProgress = PartyProgress.new()
	writer.save_path = path
	writer.xp = progress.xp
	writer.quest_log = progress.quest_log.duplicate(true)
	writer.unlocks = progress.unlocks.duplicate()
	writer.items = progress.items.duplicate()
	writer.stag_hunts = progress.stag_hunts.duplicate(true)
	writer.save()
	var reader: PartyProgress = PartyProgress.new()
	reader.save_path = path
	reader.load_save()
	var round_trip: bool = reader.quest_log == progress.quest_log and reader.unlocks == progress.unlocks and reader.stag_hunts.size() == 3 and reader.xp == 3800
	# A save from the old 20-level curve: its heroes keep the levels they had reached.
	var old: ConfigFile = ConfigFile.new()
	old.set_value("trail", "xp", PartyProgress.OLD_LEVEL_XP[5])
	old.set_value("heroes", "xp", {"shield_tank": PartyProgress.OLD_LEVEL_XP[19], "soul_tether_healer": PartyProgress.OLD_LEVEL_XP[2] + 10})
	old.save(path)
	reader.load_save()
	var migrated: bool = reader.xp == PartyProgress.LEVEL_XP[5] and reader.trail_level() == 6 and reader.character_level(&"shield_tank") == 14 \
		and reader.character_level(&"soul_tether_healer") == 3 and PartyProgress.xp_on_spine(PartyProgress.OLD_LEVEL_XP[19]) == PartyProgress.LEVEL_XP[13]
	writer.free()
	reader.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check.call(round_trip and migrated,
		"saving: the quest ledger, unlocks, items and Stag Hunts round-trip; an old-curve save keeps its heroes' levels on the 14-level spine (old Lv 6 is Lv 6, old Lv 20 is Lv 14)")


# --- Helpers --------------------------------------------------------------------------------------

func _tidy() -> void:
	quests.reset_for_testing()
	state.reset_for_testing()
	CardFog.reset()
	ActorBase.world_boon_speed = 1.0
	director.rusted_left = -1.0
	director.world_buff_left = 0.0
	director.sanctum.sleep()
	progress.xp = _saved_xp
	for class_id: StringName in _saved_hero_xp:
		progress.hero_xp[class_id] = _saved_hero_xp[class_id]
	# Walk the window away and back, so the landblocks Act I's places loaded round the start are let go.
	_place_party(ActOnePlaces.centre(ActOnePlaces.HEARTHSTEAD))
	level.streamer.load_now([level.tether_centroid()])
	await _frames(20)
	level.place_party_at(CalderaAtlas.ARRIVE_START)
	level.streamer.load_now([level.tether_centroid()])
	await _frames(20)


## Hears a townsperson out: the first press opens the talk box, each one after reads the next
## line, and the box is closed again afterwards (TalkBox stays up until goodbye).
func _talk(npc: EverwoodNPC, actor: ActorBase) -> void:
	var lines: int = npc.current_lines().size()
	for index: int in lines:
		npc.interact(actor)
	var hud: PlayerHUD = PlayerHUD.for_actor(tree, actor)
	if hud != null and hud.talk_box() != null:
		hud.talk_box().close()


func _party() -> Array[ActorBase]:
	var members: Array[ActorBase] = []
	for actor: ActorBase in level.party_in_order():
		if actor.is_multiplayer_authority() and actor.is_local_player() and not actor.is_companion:
			members.append(actor)
	return members


func _p1() -> ActorBase:
	var party: Array[ActorBase] = _party()
	return party[0] if not party.is_empty() else null


## Stands the whole party round a spot on the ground.
func _place_party(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in level.party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		var spot: Vector3 = at + Vector3((float(seat % 4) - 1.5) * 1.6, 0.0, 0.0)
		level.streamer.ensure_ground_at(spot)
		spot.y = level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, spot))
		seat += 1


## Stands the party at exactly this height (underground, in the Sanctum).
func _place_party_exact(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in level.party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		actor.place_at(Transform3D(Basis.IDENTITY, at + Vector3((float(seat % 4) - 1.5) * 1.6, 0.2, 0.0)))
		seat += 1


func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds * 60.0)))
