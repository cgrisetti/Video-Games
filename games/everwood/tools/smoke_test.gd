## Headless smoke test for Everwood. It starts in the legacy Hub Town
## (deprecated/legacy_maps/, where the classic combat checks live) and checks
## every system end to end, finishing in the game's world, the Caldera Isles:
##   - the Arsenal (Phase 7): the catalog, armor weights, the four weapons,
##     under-card mutations, kit round trips and the Grimoire's rules
##   - the Input Map, the keyboard as Player 1 and pads hot-joining (faked
##     presses and plug-ins, one device at a time), D-Pad tethers and chords
##   - party caps, then the Raid Portal into the Ring of the Cairnsman while hosting ENet
##   - combat: flow-cancels and their windows, hit-stop, all four Sign seal
##     detonations and their rewards and cues, bow and staff shots, the effect
##     pool, armor in play (Perfect Guard window, mitigation, rolls), strikes
##     crossing the network as ids, Hearth Echo, card invocations and their
##     Plain Vellum / Gilded Leaf / Star-Inked Vellum flourishes, poise, taunt, Perfect Guard,
##     heals, Lifeline, Shadow Sanctuary, Squire auto-evade and auto-guard,
##     soak scaling for small parties, telegraphs, wipes
##   - AI companions backfilling missing roles, fighting by their Gambits and
##     stepping aside when people rejoin
##   - the victory: slow motion, the banner, the reward chest and its Chimes,
##     and the gold portal home with the same ENet session still up
##   - the Chime-Shrine in Bramble-Bridge: its menu on the keyboard, upgrades for
##     the whole party, refusals, saving and loading (old "shards" saves too)
##   - the Armory & Scribe Desk: weapon, armor and card swaps in place, the
##     chest's card, under-card links and the Grimoire's memory and levels,
##     saved kits; card drops; no orphaned nodes after the round trip
##   - then the legacy seamless Landblock world (deprecated/legacy_maps/bramble_bridge_corridor/test_world_grid.gd): grid
##     maths, streaming layers and HLOD swaps up the corridor, the 2 ms queue,
##     WorldStateDB persistence and snapshots, navigation across a seam
##   - then legacy Oakshire Vale (deprecated/legacy_maps/oakshire_vale/test_oakshire_vale.gd): its rings, roads,
##     trees and boulders, townsfolk, portal aprons and spawners, then walking
##     it from Wayfarer-Green into the village, through the ford and up to a
##     sealed portal
##   - the adaptive score (tools/test_adaptive_audio.gd): buses, the catalog
##     and code-built stems, each zone's score up the trail, the station
##     ambience, then in Oakshire Vale the 32-voice pool, the four combat
##     stages and the Sign stingers (the Cairnsman's stagger window and the
##     gate's plate harmonies are checked in the expedition)
##   - the Living Storybook Atelier (tools/test_world_visuals.gd): the
##     biome, kit and succession catalog, the atelier's texture arrays, the
##     world shaders, crafted ground and clutter, low walls, gentle ramps and
##     sightline fades, the 3 km camera and horizon ring, a Hush-Crack sealed
##     into a cairn, the kit build queue; then in Oakshire Vale each part's
##     biome, the village's and petals' landmarks and Pippin-Green's furrows
##   - the Phase 12 Kaizen pass (14 GDD §8): directional combo forms, the
##     Overhead Pocket Blessing and Offhand Pocket-Draw, the One-and-Done, the
##     Tank's Ward-Mantle and the Support's Aegis Ward and Ink-Share, Miyamoto
##     armour-drops and locks, a practice Cairnsman's four gates, Gilding
##     potency and the shared Grimoire widget's pips, growth and Combo Forms
##   - and the Mythopoetic Lens (tools/test_mythopoetic_lens.gd): the four
##     Linter Rules over every name the game shows, the six-zone atlas, the
##     Hob-to-Boggart Spectrum (parley, turning boggart, the three
##     un-boggartings, the Maker-Seal, the Challenge-Roar) and the Chime-Post
##     ribbon and Hearth-Rite border
##   - and last the Caldera Isles (tools/test_caldera_isles.gd): five island
##     grids and four seams, the eight world-state booleans, the boot zones,
##     walking the causeways and gliding the skiff lanes, the Beacons, The
##     Crown's seven areas and three trials, and the Harmonic Bell's Ebb
##   - then the Phase 12 Combat Kaizen refinement (tools/test_phase12_kaizen.gd):
##     jump on ✕, roll on ○, sprint on L3, the Share-button playtest switcher,
##     the diamond-only HUD, the Grimoire's tabs and the playground names
## Run from games/everwood:
##   godot --headless --path . --fixed-fps 60 -s res://tools/smoke_test.gd
## Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const HUB_SCENE: String = "res://deprecated/legacy_maps/hub_town/hub_town.tscn"
## Hosting on a spare port, so a game left running on 7777 doesn't clash.
const TEST_PORT: int = 7791
## Fake pads use high indices so a real pad plugged into this machine can't collide.
const FAKE_PADS: Array[int] = [5, 6, 7, 8]
const PORTAL_TIMEOUT: float = 8.0
## Simulated seconds to wait for the boss to cast both telegraph kinds.
const TELEGRAPH_TIMEOUT: float = 50.0
## Simulated seconds of fighting alongside companions.
const COMPANION_FIGHT_TIME: float = 8.0
## Simulated seconds the companion Tank may wait for a swipe to Perfect Guard.
const COMPANION_GUARD_TIME: float = 20.0
## The test's own save file, so it never touches the real one.
const TEST_SAVE_PATH: String = "user://smoke_test_progress.cfg"

const Cmd = CombatActionResource.Command
const Sign = ScribeSignResource.Sign
const Diorama = ScribeCardResource.DioramaSocket
const Manifest = ScribeCardResource.ManifestationMode

var dojo: DungeonDojo
var boss: BossDummy
var tank: ActorBase
var healer: ActorBase
var dps: ActorBase

var _passes: int = 0
var _failures: PackedStringArray = PackedStringArray()
var _commands: Dictionary[StringName, Array] = {}
var _hit_stops: int = 0
var _flow_speed_scales: Array[float] = []
var _primers: Array[int] = []
var _synergies: Array[String] = []
var _cross_class_synergies: int = 0
var _perfect_guards: int = 0
var _companion_perfect_guards: int = 0
var _outcomes: Array[int] = []
var _telegraph_kinds: Dictionary[int, int] = {}
var _telegraph_hits: int = 0
var _refusals: PackedStringArray = PackedStringArray()
var _healer_states: Array[StringName] = []
var _cue_sounds: Array[StringName] = []
var _audio_cues: Array[StringName] = []
## Stingers the AudioDirector played (cadences, fanfares, Sign chords).
var _stingers_heard: Array[StringName] = []
var _portal_countdowns: int = 0
var _projectiles: Array[StringName] = []
var _invocations: Array[int] = []
## The card copy the seeded boss chest dropped (the desk test equips it).
var _dropped_card: StringName = &""
var _orphans_before: int = 0
## The seamless world's checks (tools/test_world_grid.gd), run last.
const WORLD_GRID_CHECKS: GDScript = preload("res://deprecated/legacy_maps/bramble_bridge_corridor/test_world_grid.gd")
## Oakshire Vale's checks (tools/test_oakshire_vale.gd), after the seamless world's.
const OAKSHIRE_VALE_CHECKS: GDScript = preload("res://deprecated/legacy_maps/oakshire_vale/test_oakshire_vale.gd")
## The Mythopoetic Lens's checks (tools/test_mythopoetic_lens.gd), last, in Oakshire Vale.
const MYTHOPOETIC_LENS_CHECKS: GDScript = preload("res://tools/test_mythopoetic_lens.gd")
## The adaptive score's checks (tools/test_adaptive_audio.gd): the trail's in the seamless world, the rest in Oakshire Vale.
const ADAPTIVE_AUDIO_CHECKS: GDScript = preload("res://tools/test_adaptive_audio.gd")
## The Living Storybook Atelier's checks (tools/test_world_visuals.gd): the world's in the seamless world, the vale's in Oakshire Vale.
const WORLD_VISUALS_CHECKS: GDScript = preload("res://tools/test_world_visuals.gd")
## Phase 18's checks (tools/test_pastoral_cartography.gd): the camera, labels, sculpted world and the Wayfarer's map, in every instance.
const PASTORAL_CHECKS: GDScript = preload("res://tools/test_pastoral_cartography.gd")
var _pastoral: RefCounted = PASTORAL_CHECKS.new()
## Phase 19's checks (tools/test_hero_rig.gd): the solo Iron-Woodsman boot first, the hero rig in the expedition, companions in Oakshire Vale.
const HERO_RIG_CHECKS: GDScript = preload("res://tools/test_hero_rig.gd")
## The Caldera Isles' checks (tools/test_caldera_isles.gd), last: the game's world since docs/20.
const CALDERA_CHECKS: GDScript = preload("res://tools/test_caldera_isles.gd")
## The Phase 12 Combat Kaizen refinement's checks (tools/test_phase12_kaizen.gd): jump, sprint, the playtest switcher, the diamond HUD, the Grimoire's tabs, the playground names.
const KAIZEN_CHECKS: GDScript = preload("res://tools/test_phase12_kaizen.gd")
## Phase 12.5's playtest-feedback checks (tools/test_playtest_feedback.gd), last: options, the map, arms, foliage, coasts, badges.
const PLAYTEST_CHECKS: GDScript = preload("res://tools/test_playtest_feedback.gd")
const TEST_SETTINGS_PATH: String = "user://smoke_test_settings.json"
var _hero_rig: RefCounted = HERO_RIG_CHECKS.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Everwood smoke test")
	_remove_file(TEST_SAVE_PATH)
	PartyProgress.current.use_save_file(TEST_SAVE_PATH)
	# The machine's settings too: the smoke test never touches the real settings file.
	SaveManager.remove(TEST_SETTINGS_PATH)
	SettingsManager.current.use_settings_file(TEST_SETTINGS_PATH)
	# The older checks play the classic full kits at trail Level 10, against foes
	# without their Braced Front Guard; the Phase 11 combat check sets up its own.
	PartyProgress.current.apply_full_endgame_kit_for_testing()
	BracedGuardComponent.enabled = false
	# Sign-Flow and Glimmer-Spots too: the Phase 12 check switches them on for itself.
	SignFlowComponent.enabled = false
	GlimmerSpotComponent.enabled = false
	# Parleys and Challenge-Roars too: the Mythopoetic Lens check switches them on.
	HobSpectrumComponent.enabled = false
	# Combo forms, armour-drops and boss gates too: the Phase 12 Kaizen check switches them on.
	ComboChainComponent.enabled = false
	PostureEscalationComponent.enabled = false
	BossGateComponent.enabled = false
	change_scene_to_file(HUB_SCENE)
	await _seconds(0.2)
	_connect_global_signals()
	# A default boot is the solo Iron-Woodsman (Phase 19); then the classic trinity's tank takes the keyboard.
	await _hero_rig.run_boot(self, _check)

	await _check_hub_and_input_map()
	_check_arsenal_catalog()
	_check_callings()
	await _check_keyboard_is_player_one()
	await _check_walk_over_bramblebridge()
	await _pastoral.run_hub(self, _check)
	await _check_hot_join_and_pad_mapping()
	await _seat_trinity()
	await _check_party_caps()
	await _seconds(0.1)
	_orphans_before = _orphan_count()
	await _check_portal_into_dojo()
	await _check_doverslap_expedition()
	_stage_party()
	await _seconds(0.3)
	await _check_cross_grimoire_hud()
	await _pastoral.run_dojo(self, _check)
	await _check_storybook_art()
	await _hero_rig.run_rig(self, _check, tank, healer, dps, boss)
	await _check_flow_cancel_and_hit_stop()
	await _check_flow_windows()
	await _check_synergies()
	await _check_ranged_and_armor()
	await _check_card_invocations()
	await _check_poise_and_knockdown()
	await _check_taunt()
	await _check_perfect_guard()
	_check(tank.visuals.animator.played.get(&"perfect_guard_parry", 0) > 0, "a Perfect Guard plays the deflecting perfect_guard_parry bash on the rig")
	await _check_healer()
	await _check_shadow_sanctuary()
	await _check_squire_auto_evade()
	await _check_squire_auto_guard()
	await _check_soak_scaling()
	await _check_telegraphs()
	await _check_wipe_resets_fight()
	await _check_gale_beam()
	await _check_squire_beam_assist()
	await _check_companion_backfill()
	await _check_phase_11_combat_onboarding_and_flanking()
	await test_phase_12_sign_flow_and_grimoire_ux()
	await test_phase_12_miyamoto_posture_trinity_and_grimoire_ux()
	await _check_victory_and_loot()
	await _check_chime_shrine()
	await _check_scribe_desk()
	await _check_calling_shortcut_and_fellowship()
	await _check_reed_light_scribery()
	_check_audio_cues()
	NetworkManager.current.leave_game()
	await WORLD_GRID_CHECKS.new().run(self, _check)
	var audio: RefCounted = ADAPTIVE_AUDIO_CHECKS.new()
	await audio.run_corridor(self, _check)
	var visuals: RefCounted = WORLD_VISUALS_CHECKS.new()
	await visuals.run_world(self, _check)
	await _pastoral.run_world(self, _check)
	await OAKSHIRE_VALE_CHECKS.new().run(self, _check)
	await visuals.run_vale(self, _check)
	await _pastoral.run_vale(self, _check)
	await MYTHOPOETIC_LENS_CHECKS.new().run(self, _check)
	await audio.run_vale(self, _check)
	await _hero_rig.run_vale(self, _check)
	# The Caldera Isles last (docs/20): the boot, the seams, the Beacons, The Crown's seven areas, the trials and the Ebb.
	await CALDERA_CHECKS.new().run(self, _check)
	# The Phase 12 Combat Kaizen refinement (K1 to K5) on Hearthstead Market's green.
	await KAIZEN_CHECKS.new().run(self, _check)
	await PLAYTEST_CHECKS.new().run(self, _check)
	_remove_file(TEST_SAVE_PATH)
	SaveManager.remove(TEST_SETTINGS_PATH)

	print("%d passed, %d failed" % [_passes, _failures.size()])
	if _failures.is_empty():
		print("ALL SMOKE TESTS PASSED")
	else:
		print("FAILED: " + "; ".join(_failures))
	quit(0 if _failures.is_empty() else 1)


# --- Hub Town, Input Map, hot-join ----------------------------------------

func _check_hub_and_input_map() -> void:
	_check(current_scene is HubTown, "the smoke test starts in Bramble-Bridge (Hub Town)")
	_check(ProjectSettings.get_setting("application/run/main_scene") == InstanceManager.scene_path(InstanceManager.CALDERA_ISLES)
		and InstanceManager.scene_path(InstanceManager.HUB_TOWN) == HUB_SCENE and HUB_SCENE.begins_with("res://deprecated/legacy_maps/"),
		"the game starts in the Caldera Isles; legacy Hub Town is still an instance of its own in deprecated/legacy_maps/ (the tests start there)")
	_check(InstanceManager.instance_for_name("bramblebridge") == InstanceManager.EVERWOOD_WORLD and InstanceManager.instance_for_name("Hub") == InstanceManager.HUB_TOWN
		and InstanceManager.instance_for_name("hub_town") == InstanceManager.HUB_TOWN and InstanceManager.instance_for_name("oakshire_vale") == InstanceManager.OAKSHIRE_VALE
		and InstanceManager.instance_for_name("caldera") == InstanceManager.CALDERA_ISLES and InstanceManager.instance_for_name("oakshire") == InstanceManager.CALDERA_ISLES
		and InstanceManager.instance_for_name("expedition") == InstanceManager.DUNGEON_DOJO and InstanceManager.instance_for_name("nowhere") == &"",
		"--instance=caldera (or oakshire) is the Caldera Isles; the legacy maps answer to bramblebridge, hub and oakshire_vale; a name it doesn't know leaves the start in the Caldera Isles")
	_check(InstanceManager.current.instance_id == InstanceManager.HUB_TOWN and InstanceManager.current.is_live(), "Hub Town is the live instance")
	var hub: HubTown = current_scene as HubTown
	_check(hub.level_title() == "Bramble-Bridge" and hub.raid_portal.title.contains("Dover-Slap-Falls Expedition"),
		"the hub is Bramble-Bridge, and its Raid Portal is labelled for the Dover-Slap-Falls Expedition")
	var actions: Array[StringName] = [InputComponent.ACTION_MOVE_LEFT, InputComponent.ACTION_MOVE_RIGHT,
		InputComponent.ACTION_MOVE_FORWARD, InputComponent.ACTION_MOVE_BACK, InputComponent.ACTION_CAMERA_LEFT,
		InputComponent.ACTION_CAMERA_RIGHT, InputComponent.ACTION_JOIN]
	actions.append_array(InputComponent.BUTTON_ACTIONS)
	var missing: PackedStringArray = PackedStringArray()
	for action: StringName in actions:
		if not InputMap.has_action(action):
			missing.append(action)
	_check(missing.is_empty(), "every player action is in project.godot's Input Map %s" % ("" if missing.is_empty() else str(missing)))
	_check(InputComponent.binding_label(InputComponent.ACTION_LIGHT, 0) == "J", "keyboard light reads as J")
	_check(InputComponent.binding_label(InputComponent.ACTION_LIGHT, FAKE_PADS[0] + 1) == "X"
		and InputComponent.binding_label(InputComponent.ACTION_TRIGGER_L, FAKE_PADS[0] + 1) == "LT", "a generic pad reads as Xbox letters")
	var house: WorldKitInstance = hub.get_node(^"Town/House1/Kit") as WorldKitInstance
	if house != null:
		house.build()
	var walls: MeshInstance3D = house.kit.get_node_or_null(^"Static") as MeshInstance3D if house != null and house.kit != null else null
	var crafted: ShaderMaterial = walls.mesh.surface_get_material(0) as ShaderMaterial if walls != null else null
	_check(crafted != null and crafted.shader == WorldVisualCatalog.TRIPLANAR_SHADER and house.kit_id == WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE,
		"Bramble-Bridge's houses are stepped-gable kits in the storybook world shader (crafted, cel-lit)")
	_check(InputComponent._pad_button_name(JOY_BUTTON_X, InputComponent.PadFamily.PLAYSTATION) == "□"
		and InputComponent._pad_button_name(JOY_BUTTON_A, InputComponent.PadFamily.PLAYSTATION) == "✕", "a PlayStation pad reads as shapes")


# --- The Arsenal (Phase 7), without actors ---------------------------------

func _check_arsenal_catalog() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var starters: int = 0
	var boss_cards: int = 0
	for card: ScribeCardResource in catalog.cards():
		if card.is_lead():
			if card.starter:
				starters += 1
			else:
				boss_cards += 1
	_check(catalog.armors().size() == 4 and catalog.weapons().size() == 20 and starters == 13 and boss_cards >= 4 and catalog.under_cards().size() == 4,
		"the Arsenal holds 4 armors, 20 weapons (4 classic, 16 on the trail), 13 starter lead cards, %d boss cards and 4 under-cards" % boss_cards)
	var choices: bool = true
	for slot: int in EquipmentLoadoutResource.SLOT_COUNT:
		choices = choices and catalog.lead_cards(slot).size() >= 3
	_check(choices, "every Grimoire slot has at least three lead cards to choose from")

	var armor_table: Dictionary[StringName, Array] = {
		ArsenalCatalog.HEARTH_LINEN: [0.10, 27.5, 5.2, 0.20],
		ArsenalCatalog.RANGER_LEATHER: [0.20, 22.0, 4.6, 0.20],
		ArsenalCatalog.IRONWOOD_PLATE: [0.35, 18.0, 3.8, 0.26],
	}
	var armor_ok: bool = true
	# A Bridge-Warden may wear all three; its Stout Heart takes 2 stamina a second and adds 30 ms.
	for armor_id: StringName in armor_table:
		var stats: CharacterStatsResource = _compose(ClassLoadouts.SHIELD_TANK, armor_id, &"", Callings.Secondary.STOUT_HEART).stats
		var expected: Array = armor_table[armor_id]
		armor_ok = armor_ok and is_equal_approx(stats.damage_mitigation, expected[0]) \
			and is_equal_approx(stats.stamina_regen_per_sec, expected[1] + _secondary(ArsenalCatalog.STOUT_HEART).stamina_regen_bonus) \
			and is_equal_approx(stats.roll_distance, expected[2]) \
			and is_equal_approx(stats.perfect_guard_window, expected[3] + _secondary(ArsenalCatalog.STOUT_HEART).perfect_guard_bonus)
	_check(armor_ok, "Light / Medium / Heavy armor: 10/20/35% mitigation, 27.5/22/18 stamina a second, 5.2/4.6/3.8 m rolls, 200/200/260 ms Perfect Guard (before the Calling)")

	# Weapon numbers as they stand, on a Sign-Seeker (a Wise Hand changes no damage or poise).
	var sword: ClassLoadoutResource = _compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS, &"", ArsenalCatalog.LIGHT_SWORD, Callings.Secondary.WISE_HAND)
	var sword_light: CombatActionResource = sword.opener_for(Cmd.LIGHT)
	var sword_heavy: CombatActionResource = sword.opener_for(Cmd.HEAVY)
	var sword_card: CombatActionResource = sword.card_action(ScribeCardResource.GrimoireSlot.FORWARD)
	_check(sword.combo_actions.size() == 2 and is_equal_approx(sword_light.total_time(), 0.55) and not sword_light.is_projectile()
		and sword_heavy.detonates and is_equal_approx(sword_heavy.damage, 18.0) and sword_card.trail and not sword_card.is_projectile(),
		"Sword & Buckler: three 0.55 s cuts, an 18-damage thrust that detonates, and cards swung with a ribbon trail")
	var axe: ClassLoadoutResource = _compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS, &"", ArsenalCatalog.HEAVY_AXE, Callings.Secondary.WISE_HAND)
	var cleave: CombatActionResource = axe.opener_for(Cmd.LIGHT)
	var splitter: CombatActionResource = axe.opener_for(Cmd.HEAVY)
	_check(axe.combo_actions.size() == 1 and is_equal_approx(cleave.total_time(), 0.85) and is_equal_approx(cleave.stamina_cost, 16.0)
		and is_equal_approx(splitter.damage, 28.0) and is_equal_approx(splitter.poise_damage, 35.0), "Greataxe: two 0.85 s cleaves for 16 stamina, a 28-damage, 35-poise Earth-Splitter")
	var staff: ClassLoadoutResource = _compose(ClassLoadouts.SOUL_TETHER_HEALER, &"", ArsenalCatalog.SCRIBE_STAFF)
	var staff_chain: Array[CombatActionResource] = [staff.opener_for(Cmd.LIGHT)]
	staff_chain.append_array(staff.combo_actions)
	var lance: CombatActionResource = staff.card_action(ScribeCardResource.GrimoireSlot.FORWARD)
	var ring: CombatActionResource = staff.card_action(ScribeCardResource.GrimoireSlot.BACK)
	_check(staff_chain.size() == 3 and not staff_chain[0].is_projectile() and staff_chain[2].is_projectile() and is_equal_approx(staff_chain[2].projectile_range, 12.0)
		and lance.is_projectile() and is_equal_approx(lance.projectile_range, 12.0) and is_equal_approx(ring.effect_radius, 4.5 * 1.25),
		"Scribe Staff: two sweeps then a 12 m bolt, cards fired as 12 m bolts, sanctuaries 25% wider")
	var bow: ClassLoadoutResource = _compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS, &"", ArsenalCatalog.HUNTER_BOW, Callings.Secondary.WISE_HAND)
	var snap: CombatActionResource = bow.opener_for(Cmd.LIGHT)
	var draw: CombatActionResource = bow.opener_for(Cmd.HEAVY)
	var drive: CombatActionResource = bow.card_action(ScribeCardResource.GrimoireSlot.FORWARD)
	var crescent: CombatActionResource = bow.card_action(ScribeCardResource.GrimoireSlot.BACK)
	_check(snap.is_projectile() and is_equal_approx(snap.projectile_range, 14.0) and draw.pierces and is_equal_approx(draw.projectile_range, 18.0)
		and drive.is_projectile() and is_equal_approx(drive.projectile_range, 18.0) and is_equal_approx(drive.lunge_distance, 0.0) and crescent.lunge_distance < 0.0,
		"Hunter Bow: 14 m snap-shots, an 18 m piercing draw, cards as 18 m Sign-arrows (forward lunges planted, back steps kept)")

	var surged: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.DIRECTIONAL_FLOW_DPS)
	surged.under_ids[0] = ArsenalCatalog.IRON_ROOT_LINK
	var surge: CombatActionResource = ClassLoadouts.compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS, surged).card_action(0)
	var plain_drive: CombatActionResource = ClassLoadouts.compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS).card_action(0)
	_check(is_equal_approx(surge.damage, plain_drive.damage * 1.2) and is_equal_approx(surge.poise_damage, plain_drive.poise_damage * 1.2),
		"Iron-Root Link (Potency Surge) makes Rising Drive hit 20% harder in damage and poise")
	var infused: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	infused.under_ids[0] = ArsenalCatalog.STAR_TIDE_LINK
	var charge: CombatActionResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, infused).card_action(0)
	_check(charge.primer == Sign.SIGN_STAR_TIDE and charge.scribe_sign == Sign.SIGN_STAR_TIDE, "Star-Tide Link (Sign Infusion) makes Shield Charge stamp the Sign of Star-Tide")
	var echoed: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SOUL_TETHER_HEALER)
	echoed.under_ids[1] = ArsenalCatalog.WARM_HEARTH_LINK
	echoed.under_ids[2] = ArsenalCatalog.WARM_HEARTH_LINK
	var echo_kit: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SOUL_TETHER_HEALER, echoed)
	_check(is_equal_approx(echo_kit.card_action(2).echo_heal_ratio, 0.5) and is_equal_approx(echo_kit.card_action(1).zone_stamina_per_second, 8.0),
		"Warm-Hearth Link (Hearth Echo): Homing Heal bounces 50%, Green Sanctuary restores 8 stamina a second")

	var kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	var json_kit: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(JSON.parse_string(JSON.stringify(kit.to_dict())) as Dictionary)
	_check(json_kit.same_as(kit), "a kit is a few ids that survive a JSON round trip (ready for save files)")
	var first: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, kit)
	var second: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, kit)
	var same: bool = first.openers.size() == second.openers.size()
	for index: int in first.openers.size():
		same = same and first.openers[index].action_id == second.openers[index].action_id and is_equal_approx(first.openers[index].damage, second.openers[index].damage)
	_check(same, "composing the same kit twice gives the same action ids and numbers (what lets peers name actions by id)")
	var broken: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.DIRECTIONAL_FLOW_DPS)
	broken.weapon_id = &"no_such_weapon"
	broken.lead_ids[0] = ArsenalCatalog.TAUNT
	broken.lead_ids[2] = ArsenalCatalog.HOMING_HEAL
	var fixed: EquipmentLoadoutResource = LoadoutComposer.sanitized(ClassLoadouts.player_class(ClassLoadouts.DIRECTIONAL_FLOW_DPS), broken)
	_check(fixed.weapon_id == ArsenalCatalog.HUNTER_BOW and fixed.lead_ids[0] == ArsenalCatalog.RISING_DRIVE and fixed.lead_ids[2] == ArsenalCatalog.GALE_RUSH,
		"unknown items, cards in the wrong slot and tether cards on a class without tethers fall back to the starter kit")

	var tank_class: PlayerClassResource = ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK)
	var empty_binder: Dictionary[StringName, int] = {}
	var linked: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	linked.under_ids[0] = ArsenalCatalog.IRON_ROOT_LINK
	var rare: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	rare.lead_ids[0] = ArsenalCatalog.MOONFALL_CLEAVE
	_check(LoadoutComposer.grimoire_level(0) == 1 and LoadoutComposer.grimoire_level(9) == 5 and LoadoutComposer.under_slots(1) == 0
		and LoadoutComposer.under_slots(5) == 4 and LoadoutComposer.memory_capacity(1) == 6,
		"the Grimoire starts at Lv 1 (6 memory, no under-card links) and reaches Lv 5 (14 memory, 4 links)")
	_check(LoadoutComposer.kit_problem(tank_class, kit, 1, empty_binder) == "" and LoadoutComposer.kit_problem(tank_class, linked, 1, empty_binder).contains("Lv 2")
		and LoadoutComposer.kit_problem(tank_class, linked, 2, empty_binder) == "" and LoadoutComposer.kit_problem(tank_class, rare, 2, empty_binder).begins_with("Not in the binder"),
		"the starter kit always fits; under-cards wait for their level; a boss card must be collected first")
	_check_four_signs_and_finishes()
	var drops: RandomNumberGenerator = RandomNumberGenerator.new()
	drops.seed = 7
	var seen_variants: Dictionary[int, bool] = {}
	var rare_seen: bool = false
	var plain_starter: bool = false
	for roll: int in 300:
		var key: StringName = catalog.roll_card_drop(drops)
		var dropped: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(key))
		var variant: int = ScribeCardResource.copy_variant(key)
		seen_variants[variant] = true
		rare_seen = rare_seen or dropped.rarity >= ScribeCardResource.CardRarity.RARE
		plain_starter = plain_starter or (dropped.starter and variant == ScribeCardResource.CardVariant.STANDARD)
	_check(seen_variants.has(ScribeCardResource.CardVariant.GILDED_LEAF) and seen_variants.has(ScribeCardResource.CardVariant.STAR_INKED_VELLUM) and rare_seen and not plain_starter,
		"boss chests drop Rare and Legendary cards and Gilded Leaf or Star-Ink copies (never a Plain Ink starter card)")


## The 3x3 Callings (06 §3, 07 GDD §1.3), without actors: the nine names,
## each Secondary's numbers, the gear it unlocks, and the roster carrying it.
func _check_callings() -> void:
	var names: Array[String] = []
	for class_id: StringName in Callings.FELLOWSHIP_CLASSES:
		for secondary: int in Callings.count():
			names.append(Callings.calling_name(class_id, secondary))
	_check(names == ["Bridge-Warden", "Weald-Captain", "Hearth-Guard", "Iron-Woodsman", "Hedge-Runner", "Sign-Seeker", "Bell-Keeper", "Wind-Mender", "Lantern-Scribe"],
		"the 3x3 matrix names all nine Callings: the Shield-Sworn, Wayfarers and Lantern-Bearers, each with a Stout Heart, Swift Foot or Wise Hand")
	_check(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK).display_name == "Bridge-Warden"
		and ClassLoadouts.player_class(ClassLoadouts.DIRECTIONAL_FLOW_DPS).display_name == "Hedge-Runner"
		and ClassLoadouts.player_class(ClassLoadouts.SOUL_TETHER_HEALER).display_name == "Lantern-Scribe",
		"each Fellowship starts in its own column: Bridge-Warden, Hedge-Runner, Lantern-Scribe")
	var warden: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, null, Callings.Secondary.STOUT_HEART)
	var captain: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, null, Callings.Secondary.SWIFT_FOOT)
	var guard: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, null, Callings.Secondary.WISE_HAND)
	_check(is_equal_approx(warden.stats.max_health, 180.0) and is_equal_approx(captain.stats.max_health, 160.0) and is_equal_approx(guard.stats.max_health, 155.0)
		and is_equal_approx(warden.stats.stamina_regen_per_sec, 16.0) and is_equal_approx(captain.stats.stamina_regen_per_sec, 21.0)
		and is_equal_approx(guard.stats.stamina_regen_per_sec, 20.0),
		"on a 160-health Shield-Sworn in a ring-coat: Stout Heart +20 health and -2 stamina/s, Swift Foot +3 stamina/s, Wise Hand -5 health and +2 stamina/s")
	var warden_charge: CombatActionResource = warden.card_action(0)
	var captain_charge: CombatActionResource = captain.card_action(0)
	var guard_charge: CombatActionResource = guard.card_action(0)
	_check(is_equal_approx(warden_charge.poise_damage, guard_charge.poise_damage * 1.25) and is_equal_approx(captain_charge.damage, guard_charge.damage * 1.15)
		and is_equal_approx(warden.stats.perfect_guard_window, 0.29) and is_equal_approx(captain.stats.perfect_guard_window, 0.26),
		"a Stout Heart hits poise 25% harder and holds a Perfect Guard 30 ms longer; a Swift Foot strikes 15% harder")
	var scribe: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SOUL_TETHER_HEALER, null, Callings.Secondary.WISE_HAND)
	var bell_keeper: ClassLoadoutResource = ClassLoadouts.compose(ClassLoadouts.SOUL_TETHER_HEALER, null, Callings.Secondary.STOUT_HEART)
	_check(is_equal_approx(scribe.card_action(2).heal_amount, bell_keeper.card_action(2).heal_amount * 1.2) and is_equal_approx(scribe.stats.resonance_gain_multiplier, 1.2)
		and is_equal_approx(bell_keeper.stats.resonance_gain_multiplier, 1.0) and LoadoutComposer.memory_capacity(1, ClassLoadouts.player_class(ClassLoadouts.SOUL_TETHER_HEALER).bonus_memory) == 7,
		"a Wise Hand heals 20% more, earns 20% more pips and holds one more Grimoire Memory")
	var empty_binder: Dictionary[StringName, int] = {}
	var axe_kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	axe_kit.weapon_id = ArsenalCatalog.HEAVY_AXE
	_check(LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK, Callings.Secondary.STOUT_HEART), axe_kit, 1, empty_binder).contains("needs a Swift Foot (+DPS) Calling")
		and LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK, Callings.Secondary.SWIFT_FOOT), axe_kit, 1, empty_binder) == "",
		"a Bridge-Warden can't carry the Greataxe (it needs a Swift Foot); a Weald-Captain can")
	var plate_kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.DIRECTIONAL_FLOW_DPS)
	plate_kit.armor_id = ArsenalCatalog.IRONWOOD_PLATE
	_check(LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.DIRECTIONAL_FLOW_DPS), plate_kit, 1, empty_binder).contains("needs a Stout Heart (+Tank)")
		and LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.DIRECTIONAL_FLOW_DPS, Callings.Secondary.STOUT_HEART), plate_kit, 1, empty_binder) == "",
		"the heavy ring-coat waits for a Stout Heart: a Hedge-Runner can't wear it, an Iron-Woodsman can")
	var staff_kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	staff_kit.weapon_id = ArsenalCatalog.SCRIBE_STAFF
	_check(LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK), staff_kit, 1, empty_binder).contains("Wise Hand")
		and LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK, Callings.Secondary.WISE_HAND), staff_kit, 1, empty_binder) == "",
		"a staff needs a Wise Hand: a Hearth-Guard may bear one")
	_check(LoadoutComposer.sanitized(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK), axe_kit).weapon_id == ArsenalCatalog.LIGHT_SWORD,
		"a save naming gear the Calling can't use falls back to the starter weapon")
	var seat: PartyMember = PartyMember.new()
	seat.class_id = ClassLoadouts.SOUL_TETHER_HEALER
	seat.calling = ArsenalCatalog.SWIFT_FOOT
	_check(seat.to_dict()["calling"] == "swift_foot" and PartyMember.from_dict(seat.to_dict()).calling == ArsenalCatalog.SWIFT_FOOT,
		"a seat's Calling travels in the party roster as a short id (\"swift_foot\")")
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var weald: CallingResource = catalog.calling_for(ClassLoadouts.SHIELD_TANK, ArsenalCatalog.SWIFT_FOOT)
	_check(catalog.callings().size() == 9 and catalog.secondary_callings().size() == 3 and weald != null and weald.calling_id == &"weald_captain"
		and weald.subtitle == "Vanguard of the Green Company" and catalog.secondary_calling(ArsenalCatalog.WISE_HAND).bonus_memory == 1
		and Callings.column_of(ArsenalCatalog.WISE_HAND) == Callings.Secondary.WISE_HAND and Callings.id_of(Callings.Secondary.STOUT_HEART) == ArsenalCatalog.STOUT_HEART,
		"the Arsenal registers the 3 Secondary Callings and all 9 Callings as typed data, by id (08 Gate 4)")
	_check(catalog.secondary_calling(ArsenalCatalog.STOUT_HEART).summary().contains("+20 health") and catalog.secondary_calling(ArsenalCatalog.SWIFT_FOOT).summary().contains("unlocks bow"),
		"each Secondary describes itself for the Scribe Desk from its numbers")


## Phase 8 (06_WORLD_AND_CALLINGS.md §2): the Four Scribe Signs, their
## detonations, the starter cards mapped onto them, and the card finishes.
func _check_four_signs_and_finishes() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var expected: Dictionary[int, Array] = {
		Sign.SIGN_IRON_ROOT: ["Sign of Iron-Root", "SHATTERPOINT"],
		Sign.SIGN_RIME_GALE: ["Sign of Rime-Gale", "GLACIAL RUPTURE"],
		Sign.SIGN_WARM_HEARTH: ["Sign of Warm-Hearth", "DAWNBURST"],
		Sign.SIGN_STAR_TIDE: ["Sign of Star-Tide", "ASTRAL CHORUS"],
	}
	var named: bool = true
	for scribe_sign: int in expected:
		var seal: ScribeSignResource = catalog.sign_seal(scribe_sign)
		named = named and seal.scribe_sign == scribe_sign and seal.seal_name == expected[scribe_sign][0] and seal.detonation_name == expected[scribe_sign][1]
	_check(named, "the Four Signs: Iron-Root -> Shatterpoint, Rime-Gale -> Glacial Rupture, Warm-Hearth -> Dawnburst, Star-Tide -> Astral Chorus")
	var iron_root: ScribeSignResource = catalog.sign_seal(Sign.SIGN_IRON_ROOT)
	var rime_gale: ScribeSignResource = catalog.sign_seal(Sign.SIGN_RIME_GALE)
	var warm_hearth: ScribeSignResource = catalog.sign_seal(Sign.SIGN_WARM_HEARTH)
	var star_tide: ScribeSignResource = catalog.sign_seal(Sign.SIGN_STAR_TIDE)
	_check(is_equal_approx(iron_root.bonus_poise, 45.0) and is_equal_approx(rime_gale.bonus_damage, 45.0) and is_equal_approx(warm_hearth.party_heal, 20.0)
		and is_equal_approx(warm_hearth.party_radius, 10.0) and is_equal_approx(star_tide.party_stamina, 25.0) and is_equal_approx(star_tide.party_pips, 0.5),
		"each Sign detonates for its §2 numbers: +45 poise, +45 burst damage, a 20 HP heal in 10 m, +25 stamina and +½ pip in 10 m")
	var primed: Dictionary[int, bool] = {}
	var every_card_signed: bool = true
	for card: ScribeCardResource in catalog.cards():
		every_card_signed = every_card_signed and card.scribe_sign != Sign.NONE
		if card.is_lead() and card.starter and card.primes():
			primed[card.template.primer] = true
	_check(every_card_signed and primed.size() == 4, "every card belongs to one of the Four Signs, and each Sign has a starter primer card")
	var linked: Dictionary[int, bool] = {}
	for under: ScribeCardResource in catalog.under_cards():
		linked[under.scribe_sign] = true
	_check(linked.size() == 4, "one under-card for each Sign: Iron-Root, Rime-Gale, Warm-Hearth and Star-Tide Links")
	_check("|".join(ScribeCardResource.VARIANT_NAMES) == "Plain Ink|Gilded Leaf|Star-Ink"
		and catalog.copy_name(&"moonfall_cleave:shiny_foil") == "Moonfall Cleave (Rare, Gilded Leaf)",
		"card finishes read as Plain Ink, Gilded Leaf and Star-Ink")
	_check(ScribeCardResource.copy_variant(&"gale_rush:astral_prism") == ScribeCardResource.CardVariant.STAR_INKED_VELLUM,
		"save files keep the Phase 7 finish keys, so existing binders still load")


## A class composed with one item swapped in (&"" keeps the starter's).
func _compose(class_id: StringName, armor_id: StringName, weapon_id: StringName, calling: int = -1) -> ClassLoadoutResource:
	var kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(class_id)
	if armor_id != &"":
		kit.armor_id = armor_id
	if weapon_id != &"":
		kit.weapon_id = weapon_id
	return ClassLoadouts.compose(class_id, kit, calling)


func _check_keyboard_is_player_one() -> void:
	var network: NetworkManager = NetworkManager.current
	# Clear any real pad seated at launch, so the test doesn't depend on what's plugged in.
	for seat: PartyMember in network.ordered_members():
		if seat.device_id != InputComponent.KEYBOARD_DEVICE:
			network.drop_local_player(seat.device_id)
	await _seconds(0.05)
	var keyboard: PartyMember = network.member(&"1_0")
	_check(keyboard != null and keyboard.slot == 0 and network.party_size() == 1, "keyboard and mouse is seated as Player 1 (1_0)")
	_check(_hub().grid.view_count() == 1, "one player fills the screen")
	_capture(_hub().actors[&"1_0"])
	_key(KEY_J, true)
	await _seconds(0.05)
	_key(KEY_J, false)
	_check(_commands_of(&"1_0").has(Cmd.LIGHT), "J on the keyboard is Player 1's light attack")

	_key(KEY_ENTER, true)
	await _seconds(LevelBase.LEAVE_HOLD_TIME + 0.2)
	_key(KEY_ENTER, false)
	await _seconds(0.05)
	_check(not network.roster.has(&"1_0") and _hub().grid.view_count() == 0, "holding Enter leaves the party")
	_key(KEY_ENTER, true)
	await _seconds(0.05)
	_key(KEY_ENTER, false)
	await _seconds(0.05)
	_check(network.roster.has(&"1_0") and network.member(&"1_0").slot == 0, "tapping Enter rejoins as Player 1")


## No jump button: Player 1 walks from the spawn green over the stone arch to
## the village square on the stick alone, with the desk, shrine and portal
## across the canal (07 GDD §1.1).
func _check_walk_over_bramblebridge() -> void:
	var hub: HubTown = current_scene as HubTown
	var walker: ActorBase = hub.actors[&"1_0"]
	var canal_z: float = hub.get_node(^"Town/Bramblebridge").global_position.z
	for spawn: Node in hub.spawn_points.get_children():
		if (spawn as Node3D).global_position.z <= canal_z:
			_check(false, "every spawn pad is on the south green")
	_check(hub.scribe_desk.global_position.z < canal_z and hub.chime_shrine.global_position.z < canal_z
		and hub.raid_portal.global_position.z < hub.scribe_desk.global_position.z,
		"the desk and the Chime-Shrine stand across the canal, the Raid Portal beyond them at the forest gate")
	_check(absf(walker.floor_snap_length - 0.35) < 0.001 and absf(walker.floor_max_angle - deg_to_rad(50.0)) < 0.001, "actors stick to ramps up to 50 degrees")
	walker.place_at(Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, canal_z + 8.0)))
	walker.input.inject_move(Vector2(0.0, 1.0))
	var highest: float = 0.0
	var waited: float = 0.0
	while waited < 5.0 and walker.global_position.z > canal_z - 7.0:
		await physics_frame
		waited += 1.0 / 60.0
		highest = maxf(highest, walker.global_position.y)
	walker.input.inject_move(Vector2.ZERO)
	_check(walker.global_position.z <= canal_z - 7.0, "walking north on the stick crosses Bramble-Bridge to the square (%.1f s)" % waited)
	_check(highest > 0.75 and highest < 1.2, "over the arch's crown (%.2f m up), not around or under it" % highest)
	walker.input.release_script()
	walker.respawn()


func _check_hot_join_and_pad_mapping() -> void:
	var network: NetworkManager = NetworkManager.current
	var hub: LevelBase = _hub()
	Input.joy_connection_changed.emit(FAKE_PADS[0], true)
	await _seconds(0.05)
	_check(network.roster.has(_pad_id(0)) and hub.grid.view_count() == 2, "plugging in a pad hot-joins Player 2 and splits the screen in two")
	Input.joy_connection_changed.emit(FAKE_PADS[1], true)
	await _seconds(0.05)
	_check(hub.grid.view_count() == 3 and hub.grid.get_node("Cells").get_child_count() == 4, "a second pad makes 3 views plus the raid view")
	Input.joy_connection_changed.emit(FAKE_PADS[2], true)
	await _seconds(0.05)
	_check(hub.grid.view_count() == 4, "a third pad makes a 2 x 2 grid")
	Input.joy_connection_changed.emit(FAKE_PADS[3], true)
	await _seconds(0.05)
	_check(hub.grid.view_count() == 4 and not _refusals.is_empty(), "a fifth controller is refused (4 per screen)")
	_check(network.member(_pad_id(0)).class_id == ClassLoadouts.SOUL_TETHER_HEALER
		and network.member(_pad_id(1)).class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS
		and network.member(_pad_id(2)).class_id == ClassLoadouts.SHIELD_TANK, "hot-joined players fill out the trinity")

	var pad_tank: int = FAKE_PADS[2]
	var tank_id: StringName = _pad_id(2)
	for index: int in 3:
		_capture(hub.actors[_pad_id(index)])
	_pad_button(pad_tank, JOY_BUTTON_X, true)
	await _seconds(0.05)
	_pad_button(pad_tank, JOY_BUTTON_X, false)
	_check(_commands_of(tank_id).has(Cmd.LIGHT) and not _commands_of(_pad_id(0)).has(Cmd.LIGHT),
		"X / □ on one pad is that player's light attack, and only theirs")
	await _press_heavy_with_stick(pad_tank, -1.0)
	_check(_commands_of(tank_id).back() == Cmd.FORWARD_HEAVY, "stick up + Y / △ is Forward + Heavy")
	await _press_heavy_with_stick(pad_tank, 1.0)
	_check(_commands_of(tank_id).back() == Cmd.BACK_HEAVY, "stick down + Y / △ is Back + Heavy")
	_pad_axis(pad_tank, JOY_AXIS_LEFT_Y, -1.0)
	await _seconds(0.05)
	_pad_axis(pad_tank, JOY_AXIS_LEFT_Y, 0.0)
	await _seconds(0.05)
	_pad_button(pad_tank, JOY_BUTTON_Y, true)
	await _seconds(0.05)
	_pad_button(pad_tank, JOY_BUTTON_Y, false)
	_check(_commands_of(tank_id).back() == Cmd.FORWARD_HEAVY, "a quick flick up, then Y / △, still counts as Forward + Heavy")
	await _seconds(0.3)
	await _press_heavy_with_stick(pad_tank, 0.0)
	_check(_commands_of(tank_id).back() == Cmd.HEAVY, "Y / △ with the stick centred is a plain heavy")
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_LEFT, 1.0)
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _seconds(0.1)
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_LEFT, 0.0)
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check(_commands_of(tank_id).back() == Cmd.TRIGGER_BOTH_ULT, "LT + RT / L2 + R2 together is the ultimate")

	var pad_healer: int = FAKE_PADS[0]
	var pad_healer_actor: ActorBase = hub.actors[_pad_id(0)]
	var allies: Array[ActorBase] = pad_healer_actor.tether.allies()
	_pad_button(pad_healer, JOY_BUTTON_DPAD_RIGHT, true)
	await _seconds(0.05)
	_pad_button(pad_healer, JOY_BUTTON_DPAD_RIGHT, false)
	_check(allies.size() == 3 and pad_healer_actor.tether.tethered_id == allies[1].player_id, "D-Pad → tethers the healer to the second ally")
	_pad_button(pad_healer, JOY_BUTTON_DPAD_UP, true)
	await _seconds(0.05)
	_pad_button(pad_healer, JOY_BUTTON_DPAD_UP, false)
	_check(pad_healer_actor.tether.tethered_id == allies[0].player_id, "D-Pad ↑ tethers the first ally")

	var pad_dps: int = FAKE_PADS[1]
	_pad_button(pad_dps, JOY_BUTTON_BACK, true)
	await _seconds(0.2)
	_pad_button(pad_dps, JOY_BUTTON_BACK, false)
	await _seconds(0.05)
	var tapped_binder: bool = (hub.huds[_pad_id(1)] as PlayerHUD).binder_panel() != null
	_check(network.member(_pad_id(1)).class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS and tapped_binder,
		"a quick tap of View / Create doesn't change class: it opens the Grimoire Binder")
	_pad_button(pad_dps, JOY_BUTTON_BACK, true)
	await _seconds(0.1)
	_pad_button(pad_dps, JOY_BUTTON_BACK, false)
	await _seconds(0.05)
	_pad_button(pad_dps, JOY_BUTTON_BACK, true)
	await _seconds(InputComponent.MENU_HOLD_TIME + 0.15)
	_pad_button(pad_dps, JOY_BUTTON_BACK, false)
	await _seconds(0.05)
	_check(network.member(_pad_id(1)).class_id == ClassLoadouts.SHIELD_TANK and hub.actors[_pad_id(1)].loadout.class_id == ClassLoadouts.SHIELD_TANK,
		"holding View / Create changes class")

	for index: int in [2, 1, 0]:
		Input.joy_connection_changed.emit(FAKE_PADS[index], false)
	await _seconds(0.05)
	_check(network.party_size() == 1 and hub.grid.view_count() == 1, "unplugging pads drops those players and merges the screen back")


## The keyboard player, plus a healer and a DPS on devices 1 and 2, driven by script.
func _seat_trinity() -> void:
	var network: NetworkManager = NetworkManager.current
	network.request_local_player(1, ClassLoadouts.SOUL_TETHER_HEALER, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.05)
	_check(network.member(&"1_0").class_id == ClassLoadouts.SHIELD_TANK and network.party_size() == 3, "a Shield Tank, Soul-Tether Healer and Flow DPS are seated")


func _check_party_caps() -> void:
	var network: NetworkManager = NetworkManager.current
	_check(PartyMember.make_player_id(2187, 3) == &"2187_3", "composite player id is {peer}_{device}")
	_check(network._server_register(99, 0, ClassLoadouts.SHIELD_TANK, 0), "a remote player takes the 4th seat")
	_check(network._server_register(98, 0, ClassLoadouts.SHIELD_TANK, 0), "a second remote player takes the 5th seat")
	_check(not network._server_register(97, 0, ClassLoadouts.SHIELD_TANK, 0) and network.party_size() == 5, "a 6th player is refused (party of 5)")
	network._server_unregister(&"99_0")
	network._server_unregister(&"98_0")
	await _seconds(0.05)
	_check(network.party_size() == 3, "leaving players free their seats")


func _check_portal_into_dojo() -> void:
	var network: NetworkManager = NetworkManager.current
	_check(network.host_game(TEST_PORT) == OK and network.is_online(), "hosting an ENet session on a test port")
	var session: MultiplayerPeer = root.multiplayer.multiplayer_peer
	var hub: HubTown = current_scene as HubTown
	hub.raid_portal.countdown_started.connect(func() -> void: _portal_countdowns += 1)
	_gather_on(hub.raid_portal, hub)
	await _until_live_in(InstanceManager.DUNGEON_DOJO)
	_check(_portal_countdowns == 1, "the whole party on the Raid Portal starts its countdown")
	_check(current_scene is DungeonDojo and InstanceManager.current.instance_id == InstanceManager.DUNGEON_DOJO, "the portal moves the party onto the Dover-Slap-Falls Expedition")
	var ring: DungeonDojo = current_scene as DungeonDojo
	_check(ring.level_title() == "The Dover-Slap-Falls Expedition" and ring.boss.display_name() == "The Cairnsman of Dover-Slap-Falls"
		and ring.exit_portal.title == "Exit: Bramble-Bridge", "the raid is the Dover-Slap-Falls Expedition, its boss the Cairnsman of Dover-Slap-Falls, its exit to Bramble-Bridge")
	_check(root.multiplayer.multiplayer_peer == session and network.is_online(), "the ENet session survives the instance change")
	dojo = current_scene as DungeonDojo
	boss = dojo.boss
	_check(network.party_size() == 3 and dojo.actors.size() == 3 and dojo.grid.view_count() == 3, "the party and its split-screen views arrive intact")
	tank = dojo.actors[&"1_0"]
	healer = dojo.actors[&"1_1"]
	dps = dojo.actors[&"1_2"]
	_check(dps.input.assist_mode == InputComponent.AssistMode.MASTER and is_equal_approx(dps.action_queue.buffer_window, 0.4),
		"assist modes carry across (Master: 400 ms buffer)")
	_check(is_equal_approx(healer.action_queue.buffer_window, 0.55) and healer.action_queue.assisted_chaining,
		"Adventurer mode: 550 ms buffer and auto-chaining")


# --- The Dover-Slap-Falls Expedition (07 GDD §3) ---------------------------------

## Zone 1's ramp, lanterns, camps, shrine and chest; Zone 2's checkpoint, gale
## and Co-Op Threshold opened every way (two players on the plates, a tank's
## shelter and the bell, a companion taking the second plate); then Zone 3.
func _check_doverslap_expedition() -> void:
	var network: NetworkManager = NetworkManager.current
	var progress: PartyProgress = PartyProgress.current
	_check(dojo.zone == 1 and tank.global_position.z > 70.0 and boss.global_position.distance_to(tank.global_position) > 100.0 and not boss.engaged,
		"the party arrives in Zone 1, Moss-Oak-Hollow, far from the Cairnsman, who waits unwoken")
	_check(not (dojo.huds[tank.player_id] as PlayerHUD).boss_bar_visible(), "his health bar stays hidden until the party nears him")
	var camp_one: MinionCamp = dojo.camps[0]
	var camp_two: MinionCamp = dojo.camps[1]
	var built_right: bool = camp_one.minions.size() == 3 and camp_two.minions.size() == 4
	for camp: MinionCamp in dojo.camps:
		for minion: WoodlandMinion in camp.minions:
			built_right = built_right and is_equal_approx(minion.stats.stats.max_health, 65.0) and is_equal_approx(minion.stats.stats.max_poise, 30.0) \
				and minion.is_boss() and not minion.is_raid_boss() and not minion.is_engaged()
	_check(built_right and CombatDirector.current.primary_boss() == boss and CombatDirector.current.enemies().size() == 8,
		"two sleeping woodland camps (3 Bramble-Hobs; 3 Wisp-Boggles and a Scuttler), 65 health and 30 poise each, and the boss is still the boss")
	# Down the holloway on the stick alone: a real 1.8 m ramp, no jump.
	dps.place_at(Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 48.0)))
	dps.input.inject_move(Vector2(0.0, 1.0))
	var waited: float = 0.0
	while waited < 4.0 and dps.global_position.z > 37.5:
		await physics_frame
		waited += 1.0 / 60.0
	dps.input.inject_move(Vector2.ZERO)
	await _seconds(0.2)
	_check(dps.global_position.z <= 37.5 and dps.global_position.y < -1.5 and dps.is_on_floor(), "walking down the ramp into Rush-Light-Hollow, six feet below the oaks")
	var lantern: WindLantern = dojo.get_node(^"WindLanterns/WindLantern1") as WindLantern
	# The DPS brushed this one on the way down; let it settle first.
	await _seconds(WindLantern.COOLDOWN + 0.1)
	var lantern_chimes: int = lantern.chimes
	healer.place_at(Transform3D(Basis.IDENTITY, Vector3(lantern.global_position.x, -0.5, lantern.global_position.z)))
	await _seconds(0.2)
	_check(lantern.chimes > lantern_chimes and _audio_cues.has(&"lantern"), "brushing past a clay Wind-Lantern makes it chime")
	# The Bramble Hush-Crack wakes, a bow shot finds a Scuttler, and clearing it pays Chimes.
	tank.place_at(Transform3D(Basis.IDENTITY, camp_one.global_position + Vector3(0.0, 0.0, 3.0)))
	_face_point(dps, camp_one.global_position, Vector3(0.0, 0.0, 10.0))
	await _seconds(0.3)
	var all_awake: bool = camp_one.alert
	for minion: WoodlandMinion in camp_one.minions:
		all_awake = all_awake and minion.is_engaged()
	_check(all_awake and not camp_two.alert, "walking up wakes the whole Bramble Hush-Crack (and only that camp)")
	var nearest: ActorBase = dps.soft_target()
	_check(nearest is WoodlandMinion, "the DPS's soft-lock picks the nearest woken minion")
	dps.stats.stamina = dps.stats.stats.max_stamina
	var shots: int = _projectiles.count(dps.player_id)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.9)
	var hurt: bool = false
	for minion: WoodlandMinion in camp_one.minions:
		hurt = hurt or minion.stats.health < minion.stats.stats.max_health
	_check(_projectiles.count(dps.player_id) > shots and hurt, "a bow shot flies to a Scuttler and hurts it")
	var chimes_before: int = progress.chimes
	for minion: WoodlandMinion in camp_one.minions:
		CombatDirector.current.deliver(_strike(tank, minion, 500.0, 0.0))
	await _seconds(0.3)
	_check(camp_one.is_cleared and progress.chimes == chimes_before + DungeonDojo.CAMP_CHIMES, "clearing the camp pays the party %d Chimes" % DungeonDojo.CAMP_CHIMES)
	await _seconds(WoodlandMinion.FADE_TIME + 0.2)
	var faded: bool = true
	for minion: WoodlandMinion in camp_one.minions:
		faded = faded and minion.collision_layer == 0 and not minion.visual.visible and not minion.is_targetable()
	_check(faded, "beaten minions shrink into the moss and are gone")
	var released: bool = not camp_one.minions.is_empty()
	for minion: WoodlandMinion in camp_one.minions:
		released = released and minion.spectrum != null and minion.spectrum.state == HobSpectrumComponent.SpiritState.STATE_UNBOGGART_RELEASE
	_check(released, "beaten Bramble-Hobs are un-boggarted, not slain: each flies off a hedge-wren (STATE_UNBOGGART_RELEASE)")
	# The Water-Shrine refreshes the whole party.
	tank.stats.take_damage(60.0)
	tank.stats.stamina = 10.0
	healer.stats.take_damage(30.0)
	dps.place_at(Transform3D(Basis.IDENTITY, dojo.water_shrine.global_position + Vector3(0.0, 0.0, 1.3)))
	await _seconds(0.3)
	_check(is_equal_approx(tank.stats.health, tank.stats.stats.max_health) and is_equal_approx(tank.stats.stamina, tank.stats.stats.max_stamina)
		and is_equal_approx(healer.stats.health, healer.stats.stats.max_health) and dojo.water_shrine.is_resting(),
		"walking through the Water-Shrine's mist restores the whole party to full health and stamina")
	_check(not camp_two.alert, "the imp camp beyond the shrine sleeps on")
	# The Wayfarer's Chest in the alcove.
	chimes_before = progress.chimes
	dps.place_at(Transform3D(Basis.IDENTITY, dojo.wayfarer_chest.global_position + Vector3(0.9, 0.0, 0.0)))
	await _seconds(0.3)
	var found: StringName = dojo.wayfarer_chest.card_key
	var found_card: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(found))
	_check(dojo.wayfarer_chest.is_open and progress.chimes == chimes_before + DungeonDojo.WAYFARER_CHEST_CHIMES
		and found_card != null and found_card.rarity == ScribeCardResource.CardRarity.UNCOMMON and progress.copies_of(found) == 1,
		"the Wayfarer's Chest in the alcove pays %d Chimes and an Uncommon card: %s" % [DungeonDojo.WAYFARER_CHEST_CHIMES, ArsenalCatalog.current.copy_name(found)])
	# Zone 2: the checkpoint moves, and the gale blows down the bridge.
	var gate: CoopGate = dojo.coop_gate
	tank.place_at(Transform3D(Basis.IDENTITY, Vector3(-6.0, 0.0, 11.0)))
	healer.place_at(Transform3D(Basis.IDENTITY, Vector3(6.0, 0.0, 11.0)))
	await _seconds(0.1)
	_check(dojo.zone == 2 and absf(tank.spawn_transform.origin.z - dojo.checkpoint_transform(2, tank.party_slot).origin.z) < 0.1,
		"reaching Dover-Slap-Falls moves everyone's respawn to its checkpoint")
	dps.place_at(Transform3D(Basis.IDENTITY, gate.to_global(Vector3(0.0, 0.0, 6.0))))
	await _seconds(0.1)
	var start_z: float = dps.global_position.z
	_check(gate.gale.blast() >= 1, "the Gorge Gale-Jet blows down the lane")
	await _seconds(0.6)
	_check(dps.global_position.z > start_z + 3.0, "and shoves an exposed player back down the bridge")
	_check(CoopGate.plates_needed(1) == 1 and CoopGate.plates_needed(3) == 2 and CoopGate.plates_needed(5) == 2, "the gate needs min(2, party) Maker-Seal Plates")
	# Way one: two players on the plates.
	tank.place_at(Transform3D(Basis.IDENTITY, gate.plates[0].global_position))
	dps.place_at(Transform3D(Basis.IDENTITY, gate.plates[1].global_position))
	await _seconds(CoopGate.PLATE_HOLD_TIME + 0.3)
	_check(gate.is_open and gate.opened_by == CoopGate.Method.RUNE_PLATES and not gate.gale.active,
		"two players holding both Maker-Seal Plates for 2 s open the portcullis, and the gale dies away")
	gate.reset_gate()
	dps.place_at(Transform3D(Basis.IDENTITY, Vector3(6.0, 0.0, 11.0)))
	await _seconds(CoopGate.PLATE_HOLD_TIME + 0.5)
	_check(not gate.is_open, "one plate alone doesn't open it for a party of three")
	var drone: AudioStreamPlayer3D = gate.get_node(^"Ambience_gate_drone") as AudioStreamPlayer3D
	var counter: AudioStreamPlayer3D = gate.get_node(^"Ambience_gate_counter") as AudioStreamPlayer3D
	_check(is_zero_approx(drone.volume_db) and counter.volume_db <= -79.0 and _stingers_heard.has(&"gate_fanfare"),
		"one Maker-Seal Plate held hums the A2-E3 drone (the counter-line waits for the second), and the open gate rang its A Lydian fanfare")
	# Way two: a Shield-Sworn shelters the bell-ringer from the gale.
	await _until_idle(tank)
	tank.place_at(Transform3D(Basis.IDENTITY, gate.to_global(Vector3(0.0, 0.0, 2.2))))
	dps.place_at(Transform3D(Basis.IDENTITY, gate.to_global(Vector3(0.0, 0.0, 4.2))))
	await _seconds(0.1)
	gate.winch.interact(dps)
	await _seconds(0.1)
	_check(not gate.is_open and gate.winch.prompt_for(dps).contains("too strong"), "out in the gale, the Bridge-Bell can't be rung")
	tank.stats.stamina = tank.stats.stats.max_stamina
	tank.input.inject_command(Cmd.BACK_HEAVY)
	await _seconds(0.7)
	_check(CombatDirector.current.is_sheltered(dps) and CombatDirector.current.is_sheltered(tank) and gate.gale.blast() == 0,
		"behind the tank's Shadow Sanctuary the gale can't touch them")
	gate.winch.interact(dps)
	await _seconds(0.1)
	_check(gate.is_open and gate.opened_by == CoopGate.Method.BELL_WINCH and _audio_cues.has(&"bell"),
		"sheltered, a teammate rings the Bronze Bridge-Bell and the gate opens")
	# Way three: alone with companions, a bot takes the second plate.
	gate.reset_gate()
	network.drop_local_player(1)
	network.drop_local_player(2)
	await _seconds(0.2)
	_check(_companions().size() == 2, "with only the tank left, companions join at the Gorge checkpoint")
	tank.place_at(Transform3D(Basis.IDENTITY, gate.plates[0].global_position))
	waited = 0.0
	while waited < 10.0 and not gate.is_open:
		await _seconds(0.25)
		waited += 0.25
	_check(gate.is_open and gate.opened_by == CoopGate.Method.RUNE_PLATES, "in solo play a companion walks to the second Maker-Seal Plate and the gate opens (%.1f s)" % waited)
	network.request_local_player(1, ClassLoadouts.SOUL_TETHER_HEALER, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.2)
	healer = dojo.actors[&"1_1"]
	dps = dojo.actors[&"1_2"]
	_check(network.companion_seats().is_empty() and dojo.actors.size() == 3, "the people come back and the companions step aside")
	# Zone 3: through the gatehouse to the Ring of the Cairnsman.
	tank.place_at(Transform3D(Basis.IDENTITY, gate.to_global(Vector3(0.0, 0.0, -6.0))))
	await _seconds(0.1)
	_check(dojo.zone == 3 and absf(healer.spawn_transform.origin.z - dojo.checkpoint_transform(3, healer.party_slot).origin.z) < 0.1,
		"through the gatehouse, Zone 3: everyone now gets back up at the Ring's causeway")
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
		actor.stats.stamina = actor.stats.stats.max_stamina


## A Secondary Calling's registered data.
func _secondary(id: StringName) -> SecondaryCallingResource:
	return ArsenalCatalog.current.secondary_calling(id)


## Puts an actor at `target + offset`, facing the target.
func _face_point(actor: ActorBase, target: Vector3, offset: Vector3) -> void:
	var where: Vector3 = target + offset
	var to_target: Vector3 = target - where
	to_target.y = 0.0
	actor.place_at(Transform3D(Basis.looking_at(to_target.normalized(), Vector3.UP), where))


# --- The Cross-Grimoire HUD (07 GDD §2) -----------------------------------

## Each player's cross is the four diamonds (K3): their own kit and weapon,
## their own keys, dimmed until there are pips, flashing when pressed, L lit
## while guarding; no line of control help along the bottom.
func _check_cross_grimoire_hud() -> void:
	var hud: PlayerHUD = dojo.huds[tank.player_id]
	var cross: CrossGrimoireHUD = hud.cross_grimoire
	_check(cross != null and not hud.has_method("controls_text"), "the HUD is a Cross-Grimoire, and the old line of control help is gone")
	var diamonds: CrossGrimoireDiamondWidget = cross.diorama
	var kit: EquipmentLoadoutResource = tank.loadout.kit
	_check(diamonds.follow == tank and diamonds.weapon == tank.loadout.weapon
		and diamonds.socket_view(Diorama.SKILL)["leaf"] == kit.socket_leaf_id(Diorama.SKILL)
		and diamonds.socket_view(Diorama.ULT)["leaf"] == kit.socket_leaf_id(Diorama.ULT),
		"the diamonds follow the tank: their weapon at the foot, and R and L+R hold the kit's cards")
	_check(",".join(diamonds.key_texts) == "Q,E,R", "each diamond carries its own key on the keyboard: Q, E, and R for the ultimate")
	_check(CrossGrimoireHUD.diamond_for_command(Cmd.FORWARD_HEAVY) == CrossGrimoireDiamondWidget.WEAPON
		and CrossGrimoireHUD.diamond_for_command(Cmd.TRIGGER_L_SKILL) == Diorama.GUARD
		and CrossGrimoireHUD.diamond_for_command(Cmd.TRIGGER_R_SKILL) == Diorama.SKILL
		and CrossGrimoireHUD.diamond_for_command(Cmd.TRIGGER_BOTH_ULT) == Diorama.ULT
		and CrossGrimoireHUD.diamond_for_command(Cmd.DODGE) == -1,
		"every swing lights the weapon diamond, L, R and L+R their own, and a roll none")
	var pips_before: float = tank.stats.resonance_charge
	tank.stats.resonance_charge = 0.0
	await _seconds(0.2)
	_check(not diamonds.socket_ready(Diorama.SKILL) and not diamonds.socket_ready(Diorama.ULT), "without a pip, R and L+R sit dimmed")
	tank.stats.add_resonance(1.0)
	await _seconds(0.2)
	_check(diamonds.socket_ready(Diorama.SKILL) and not diamonds.socket_ready(Diorama.ULT), "one pip earned: R brightens, the 3-pip L+R still waits")
	tank.stats.resonance_charge = pips_before
	var dps_cross: CrossGrimoireHUD = (dojo.huds[dps.player_id] as PlayerHUD).cross_grimoire
	await _until_idle(dps)
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.FORWARD_HEAVY)
	await physics_frame
	await physics_frame
	_check(dps_cross.diorama.is_pulsing(CrossGrimoireDiamondWidget.WEAPON), "pressing Forward + heavy flashes the DPS's weapon diamond")
	tank.input.inject_guard(true)
	await _seconds(0.15)
	_check(diamonds.guard_lit, "raising the guard lights the L diamond")
	tank.input.inject_guard(false)
	var healer_cross: CrossGrimoireHUD = (dojo.huds[healer.player_id] as PlayerHUD).cross_grimoire
	_check(healer_cross.shows_tether_compass() and not cross.shows_tether_compass(), "a Lantern-Bearer's cross carries the Soul Tether compass")
	_check(is_equal_approx(CrossGrimoireHUD.scale_for(Vector2(1600.0, 900.0)), CrossGrimoireHUD.BASE_SCALE)
		and is_equal_approx(CrossGrimoireHUD.scale_for(Vector2(800.0, 450.0)), CrossGrimoireHUD.MIN_SCALE),
		"the cross scales with the split-screen cell, down to a floor for four players")
	await _until_idle(dps)


# --- Storybook art (07 GDD §4, 19 GDD) ----------------------------------------

## Heroes are sculpted 24-bone rigs that read by Fellowship and Calling, wear
## the hero shader, flash on a hit, and would pick up a dropped-in .glb.
func _check_storybook_art() -> void:
	var shield: Node = tank.visuals.socket(HeroRigBuilder.OFF_HAND_SOCKET).find_child("Greatshield", true, false) if tank.visuals.has_rig() else null
	_check(tank.visuals.has_rig() and shield != null and tank.visuals.features.get("headgear") == &"stout_kettle_cap"
		and tank.visuals.features.get("left_pauldron") == &"broad_warden_pauldron" and tank.visuals.features.get("coat") == ArsenalCatalog.IRONWOOD_PLATE,
		"the Shield-Sworn wears a kettle-cap, broad warden pauldrons, the Iron-Wood Ring-Coat and a banded Greatshield on the off forearm")
	var lantern: Node = healer.visuals.find_child("TetherLantern", true, false)
	_check(lantern != null and lantern.find_child("Light", true, false) is OmniLight3D and healer.visuals.features.get("headgear") == &"scribe_feather_hat",
		"the Lantern-Bearer wears a pointed scribe feather-hat and carries a Tether-Lantern that really glows")
	_check(dps.visuals.find_child("Quiver", true, false) != null and dps.visuals.features.get("headgear") == &"wayfarer_hood_up"
		and dps.visuals.skeleton.find_bone("Cloak_03") == HeroRigBuilder.Bone.CLOAK_03 and dps.visuals.find_child("ScribeSatchel", true, false) != null,
		"the Wayfarer has a hood, a three-bone travel cloak, a quiver for the bow and the Scribe Vellum Satchel at the hip")
	var blade: MeshInstance3D = tank.find_child("Weapon", true, false).get_node(^"Blade") as MeshInstance3D
	_check(tank.visuals.body_material.shader == HeroMeshAtelier.SHADER and (blade.material_override as ShaderMaterial).shader == HeroMeshAtelier.SHADER,
		"heroes and their weapons wear the storybook hero shader (two-band light, rim glow)")
	var tabards_match: bool = true
	for hero: ActorBase in [tank, dps, healer]:
		var calling: SecondaryCallingResource = Callings.secondary(Callings.resolve(hero.loadout.class_id, hero.loadout.calling))
		tabards_match = tabards_match and hero.visuals.body_material.get_shader_parameter(&"calling_trim_color") == calling.trim_color
	_check(tabards_match, "every hero wears a tabard, front and back, in their Secondary Calling's colour")
	var skeleton: Skeleton3D = tank.visuals.skeleton
	var hem: Vector3 = skeleton.global_transform * (skeleton.get_bone_global_pose(HeroRigBuilder.Bone.CLOAK_03).origin
		+ skeleton.get_bone_global_pose(HeroRigBuilder.Bone.CLOAK_03).basis.y.normalized() * HeroRigBuilder.bone_length(HeroRigBuilder.Bone.CLOAK_03))
	var tank_standing: Transform3D = tank.global_transform
	tank.stats.stamina = tank.stats.stats.max_stamina
	tank.input.inject_command(Cmd.HEAVY)
	var reach: float = 0.0
	for frame: int in 30:
		await physics_frame
		reach = minf(reach, tank.to_local(tank.visuals.socket(HeroRigBuilder.MAIN_HAND_SOCKET).global_position).z)
	await _until_idle(tank)
	tank.place_at(tank_standing)
	_check(tank.to_local(hem).z > 0.2 and reach < -0.3,
		"the cloak hangs behind the hero, clear of the body, and the sword arm reaches forward into a thrust (%.2f m)" % -reach)
	_check(tank.loadout.weapon.display_name == "Falchion" and dps.loadout.weapon.display_name == "Yew Longbow"
		and healer.loadout.weapon.display_name == "Rowan Way-Staff", "the weapons are the Falchion, Yew Longbow and Rowan Way-Staff")
	CombatDirector.current.deliver(_strike(boss, dps, 1.0, 0.0))
	await physics_frame
	await physics_frame
	var glow: Color = dps.visuals.body_material.get_shader_parameter(&"glow")
	_check(glow.r > 0.5, "a hit flashes the whole hero white")
	_check(ActorVisuals.model_path(ClassLoadouts.SHIELD_TANK) == "res://assets/models/shield_tank.glb"
		and not ActorVisuals.has_model(ClassLoadouts.SHIELD_TANK) and ActorVisuals.load_model(ClassLoadouts.SHIELD_TANK) == null
		and HeroMeshAtelier.hero_override(ArsenalCatalog.current.hero_appearance(&"bridge_warden")) == null,
		"a model dropped at res://assets/models/<id>.glb or assets/models/heroes/<calling_id>.glb would replace the sculpted hero (none is there now)")
	var torso: Mesh = tank.visuals.surfaces[1].mesh
	var leather: EquipmentLoadoutResource = tank.loadout.kit.copy()
	leather.armor_id = ArsenalCatalog.RANGER_LEATHER
	tank.re_equip(ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, leather, tank.loadout.calling))
	await physics_frame
	_check(tank.visuals.features.get("coat") == ArsenalCatalog.RANGER_LEATHER and tank.visuals.surfaces[1].mesh != torso,
		"a new coat re-sculpts the hero (the ring-coat off, the Hedgerow Wool-Mantle on)")
	tank.re_equip(ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, null, tank.loadout.calling))
	var core: Node = boss.find_child("AmberCore", true, false)
	_check(boss.find_child("ArmLeft", true, false) != null and boss.find_child("ArmRight", true, false) != null and core != null
		and boss.find_child("BellRope3", true, false) != null, "the Cairnsman has boulder fists on timber arms, a glowing amber core and swinging bell-ropes")
	await _seconds(0.2)


# --- Combat ---------------------------------------------------------------

func _check_flow_cancel_and_hit_stop() -> void:
	var boss_health: float = boss.stats.health
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.26)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.9)
	_check(not _flow_speed_scales.is_empty(), "a buffered light flow-cancels the recovery")
	_check(not _flow_speed_scales.is_empty() and is_equal_approx(_flow_speed_scales[0], 1.15), "Master flow-cancel earns +15% speed")
	_check(_hit_stops > 0, "landed hits trigger hit-stop")
	_check(boss.stats.health < boss_health, "the boss takes damage from a hitbox overlap")
	_check(boss.threat.threat_of(dps.player_id) > 0.0, "hits add to the boss's aggro table")
	_check(is_equal_approx(boss.stats.stats.max_health, BossDummy.HEALTH_BASE + BossDummy.HEALTH_PER_PLAYER * 3.0), "the boss's health scales to a party of 3")
	boss.scale_health_to_party(1)
	var solo: float = boss.stats.stats.max_health
	boss.scale_health_to_party(5)
	var five: float = boss.stats.stats.max_health
	boss.scale_health_to_party(3)
	_check(is_equal_approx(solo, 1400.0) and is_equal_approx(five, 3400.0), "solo 1400 hp, party of 5 3400 hp")


## The Phase C buffer window: 400 ms in Master, 550 ms assisted, never in wind-up.
func _check_flow_windows() -> void:
	boss.set_physics_process(false)
	await _until_idle(dps)
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(12.0, 0.0, 10.0)))
	dps.stats.stamina = dps.stats.stats.max_stamina
	var flows: int = _flow_speed_scales.size()
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.08)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.8)
	_check(_flow_speed_scales.size() == flows, "a press during wind-up is too early to buffer")
	# Press times come from the weapon's Heavy, so the check holds for any weapon.
	var heavy: CombatActionResource = dps.loadout.opener_for(Cmd.HEAVY)
	var early: float = heavy.windup_time + 0.1
	var late: float = heavy.total_time() - 0.3
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.HEAVY)
	await _seconds(early)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(heavy.total_time() + 0.5)
	_check(_flow_speed_scales.size() == flows, "Master: a press %.2f s before the end is outside the 400 ms window" % (heavy.total_time() - early))
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.HEAVY)
	await _seconds(late)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(heavy.total_time())
	_check(_flow_speed_scales.size() == flows + 1 and is_equal_approx(_flow_speed_scales.back(), 1.15), "Master: inside the window it flows at +15%")
	NetworkManager.current.update_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.ADVENTURER)
	await _seconds(0.05)
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.HEAVY)
	await _seconds(early)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(heavy.total_time() + 0.5)
	_check(_flow_speed_scales.size() == flows + 2 and is_equal_approx(_flow_speed_scales.back(), 1.0), "Adventurer: the same press is inside its 550 ms window, with no speed bonus")
	NetworkManager.current.update_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.05)
	boss.set_physics_process(true)


## All four Sign seals, each stamped by one class's card (fired through its
## bow or staff) and detonated by another class's Heavy, rewarding both players.
func _check_synergies() -> void:
	boss.set_physics_process(false) # Hold the boss still so everyone stays in reach.
	await _detonate(dps, Cmd.FORWARD_HEAVY, tank, Sign.SIGN_IRON_ROOT, "SHATTERPOINT  x1.5 CROSS-HARMONY")
	_check(boss.stats.is_knocked_down() or boss.stats.poise <= boss.stats.stats.max_poise - 90.0, "Shatterpoint adds the bonus poise damage")
	_reset_boss_poise()
	var health_before: float = boss.stats.health
	await _detonate(dps, Cmd.BACK_HEAVY, healer, Sign.SIGN_RIME_GALE, "GLACIAL RUPTURE  x1.5 CROSS-HARMONY")
	var rupture: ScribeSignResource = ArsenalCatalog.current.sign_seal(Sign.SIGN_RIME_GALE)
	_check(health_before - boss.stats.health >= rupture.bonus_damage * CombatDirector.CROSS_HARMONY_MULTIPLIER, "Glacial Rupture adds the bonus damage")
	_reset_boss_poise()
	dps.stats.take_damage(40.0)
	var hurt_health: float = dps.stats.health
	await _detonate(healer, Cmd.FORWARD_HEAVY, tank, Sign.SIGN_WARM_HEARTH, "DAWNBURST  x1.5 CROSS-HARMONY")
	_check(dps.stats.health > hurt_health, "Dawnburst heals the party around the boss")
	_reset_boss_poise()
	dps.stats.add_resonance(1.0)
	healer.stats.stamina = 10.0
	healer.stats.resonance_charge = 0.0
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(4.0, 0.0, 5.0)))
	var chorus: ScribeSignResource = ArsenalCatalog.current.sign_seal(Sign.SIGN_STAR_TIDE)
	await _detonate(dps, Cmd.TRIGGER_R_SKILL, tank, Sign.SIGN_STAR_TIDE, "ASTRAL CHORUS  x1.5 CROSS-HARMONY", 1.0)
	_check(healer.stats.stamina >= 10.0 + chorus.party_stamina * CombatDirector.CROSS_HARMONY_MULTIPLIER - 0.5,
		"Astral Chorus restores +%d stamina to the party within 10 m" % roundi(chorus.party_stamina * CombatDirector.CROSS_HARMONY_MULTIPLIER))
	_check(healer.stats.resonance_charge >= chorus.party_pips * CombatDirector.CROSS_HARMONY_MULTIPLIER - 0.01,
		"Astral Chorus grants +¾ pip to the party (the healer wasn't even in the combo)")
	_check(_cross_class_synergies >= 4, "cross-harmony detonations are flagged")
	boss.set_physics_process(true)


func _detonate(primer_actor: ActorBase, primer_command: int, detonator: ActorBase, scribe_sign: int, label: String, pips_before: float = 0.0) -> void:
	await _until_idle(primer_actor)
	await _until_idle(detonator)
	_face_boss(primer_actor, Vector3(-1.4, 0.0, 2.6))
	_face_boss(detonator, Vector3(1.3, 0.0, 2.4))
	for actor: ActorBase in [primer_actor, detonator]:
		actor.stats.stamina = actor.stats.stats.max_stamina
		actor.stats.resonance_charge = 0.0
	primer_actor.stats.resonance_charge = pips_before
	var rewards_before: int = _cue_sounds.count(&"reward")
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(scribe_sign)
	primer_actor.input.inject_command(primer_command)
	await _seconds(0.75)
	_check(_primers.has(scribe_sign), "%s's %s card stamps the %s seal" % [primer_actor.loadout.display_name, PlayerHUD.command_name(primer_command), seal.seal_name])
	detonator.input.inject_command(Cmd.HEAVY)
	await _seconds(1.4)
	_check(_synergies.has(label), "%s's Heavy detonates it as %s" % [detonator.loadout.display_name, label])
	_check(primer_actor.stats.resonance_charge >= 0.7 and detonator.stats.resonance_charge >= 0.7,
		"%s rewards both players (+¾ pip each)" % seal.detonation_name)
	_check(_cue_sounds.count(&"reward") - rewards_before >= 2 and _audio_cues.has(seal.sound), "%s shows a burst on both players and plays its sound" % seal.detonation_name)


## Phase 7, in the fight: bow and staff shots, the effect pool, armor at work,
## strikes crossing the network as action ids, and a Hearth Echo heal.
func _check_ranged_and_armor() -> void:
	boss.set_physics_process(false)
	_reset_boss_poise()
	await _until_idle(dps)
	_face_boss(dps, Vector3(0.0, 0.0, 9.0))
	dps.stats.stamina = dps.stats.stats.max_stamina
	var health_before: float = boss.stats.health
	var shots: int = _projectiles.count(dps.player_id)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.8)
	_check(_projectiles.count(dps.player_id) > shots and boss.stats.health < health_before, "a Snap-Shot arrow flies 9 m and hits the boss")
	await _until_idle(healer)
	_face_boss(healer, Vector3(3.0, 0.0, 7.5))
	healer.stats.stamina = healer.stats.stats.max_stamina
	health_before = boss.stats.health
	shots = _projectiles.count(healer.player_id)
	healer.input.inject_command(Cmd.FORWARD_HEAVY)
	await _seconds(0.8)
	_check(_projectiles.count(healer.player_id) > shots and boss.stats.health < health_before,
		"the healer's Sunlit Lance card flies through the staff as a Sign-bolt and hits from 8 m")
	var pool: FxPool = CombatDirector.current.fx_pool
	var made: int = pool.made_count
	for volley: int in 6:
		dps.stats.stamina = dps.stats.stats.max_stamina
		dps.input.inject_command(Cmd.LIGHT)
		await _seconds(0.7)
	_check(pool.made_count == made and pool.active_count() == 0 and pool.idle_count() >= 1, "landed shots go back to the effect pool and are reused (no new nodes)")

	await _until_idle(tank)
	_reset_boss_poise()
	tank.input.inject_guard(true)
	await _seconds(0.27)
	var guards: int = _perfect_guards
	CombatDirector.current.deliver(CombatEvent.strike_from(boss, tank, boss.loadout.openers[0]))
	await _seconds(0.1)
	_check(_perfect_guards == guards + 1, "Iron-Wood Ring-Coat's 260 ms window, +30 ms for a Stout Heart: a guard raised 0.27 s early is still perfect")
	tank.input.inject_guard(false)
	await _seconds(0.3)
	tank.re_equip(_compose(ClassLoadouts.SHIELD_TANK, ArsenalCatalog.RANGER_LEATHER, &""))
	await _until_idle(tank)
	tank.input.inject_guard(true)
	await _seconds(0.27)
	var outcomes: int = _outcomes.size()
	CombatDirector.current.deliver(CombatEvent.strike_from(boss, tank, boss.loadout.openers[0]))
	await _seconds(0.1)
	_check(_perfect_guards == guards + 1 and _outcomes.slice(outcomes).has(StatsComponent.StrikeOutcome.GUARDED),
		"in Hedgerow Wool-Mantle (200 + 30 ms) the same guard is too early: it just blocks")
	tank.input.inject_guard(false)
	tank.re_equip(ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK))
	await _seconds(0.1)

	dps.stats.heal(dps.stats.stats.max_health)
	var dps_health: float = dps.stats.health
	CombatDirector.current.deliver(_strike(boss, dps, 50.0, 0.0))
	await _seconds(0.05)
	_check(is_equal_approx(dps_health - dps.stats.health, 50.0 * (1.0 - 0.20)), "Hedgerow Wool-Mantle takes 20% off a 50-damage hit")
	dps.stats.heal(dps.stats.stats.max_health)
	var light_roll: float = await _measure_roll(dps, ArsenalCatalog.HEARTH_LINEN)
	var heavy_roll: float = await _measure_roll(dps, ArsenalCatalog.IRONWOOD_PLATE)
	dps.re_equip(ClassLoadouts.compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS))
	_check(light_roll > heavy_roll + 1.0, "Hearth-Linen rolls farther than Iron-Wood Ring-Coat (%.1f m against %.1f m)" % [light_roll, heavy_roll])

	var arrow: CombatActionResource = dps.loadout.opener_for(Cmd.LIGHT)
	var packet: Dictionary = CombatEvent.strike_from(dps, boss, arrow).to_dict()
	var arrived: CombatEvent = CombatEvent.from_dict(packet)
	_check(packet.has("action_id") and not packet.has("damage") and arrived.resolve_action(dps) and is_equal_approx(arrived.damage, arrow.damage)
		and is_equal_approx(arrived.reach, arrow.projectile_range), "a strike crosses the network as an action id; the target's owner reads the numbers from its own copy")

	var echo_kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SOUL_TETHER_HEALER)
	echo_kit.under_ids[2] = ArsenalCatalog.WARM_HEARTH_LINK
	healer.re_equip(ClassLoadouts.compose(ClassLoadouts.SOUL_TETHER_HEALER, echo_kit))
	await _until_idle(healer)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(6.0, 0.0, 8.0)))
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(8.0, 0.0, 8.0)))
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(7.0, 0.0, 12.0)))
	tank.stats.take_damage(60.0)
	dps.stats.take_damage(60.0)
	var dps_hurt: float = dps.stats.health
	healer.stats.stamina = healer.stats.stats.max_stamina
	healer.tether.bind_actor(tank)
	healer.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(1.2)
	_check(dps.stats.health > dps_hurt, "Hearth Echo: the healer's Homing Heal on the tank bounces half to the hurt DPS beside it")
	healer.re_equip(ClassLoadouts.compose(ClassLoadouts.SOUL_TETHER_HEALER))
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	boss.set_physics_process(true)
	_stage_party()


## Every card invocation shows its seal and vellum card; Gilded Leaf and
## Star-Inked Vellum copies add their flourishes; none of it changes the numbers.
func _check_card_invocations() -> void:
	boss.set_physics_process(false)
	_reset_boss_poise()
	var standard: ScribeInvocationFX = await _charge_with(ScribeCardResource.CardVariant.STANDARD)
	_check(_invocations.back() == ScribeCardResource.CardVariant.STANDARD and standard != null and not standard.is_showing_foil() and not standard.is_showing_dome(),
		"invoking Shield Charge blooms the Sign of Iron-Root and flips a vellum card over the tank's shoulder")
	await _seconds(ScribeInvocationFX.SEAL_TIME + 0.2)
	_check(standard != null and not standard.in_use, "the Standard flourish ends after 0.6 s and goes back to the effect pool")

	var foil_chimes: int = _audio_cues.count(&"card_chime_foil")
	var foil: ScribeInvocationFX = await _charge_with(ScribeCardResource.CardVariant.GILDED_LEAF)
	_check(foil != null and foil.is_showing_foil() and _audio_cues.count(&"card_chime_foil") > foil_chimes,
		"a Gilded Leaf copy adds two counter-rotating gold rings and a brighter chime")
	await _seconds(tank.loadout.card_action(0).windup_time)
	_check(tank.trail.is_swinging() and tank.trail.colour().is_equal_approx(Color(WeaponTrail.SHINY_COLOR, WeaponTrail.TRAIL_ALPHA)),
		"and its sword swings a gold ribbon trail")
	await _seconds(1.0)

	var astral: ScribeInvocationFX = await _charge_with(ScribeCardResource.CardVariant.STAR_INKED_VELLUM)
	_check(astral != null and astral.is_showing_dome(), "a Star-Inked Vellum copy raises a starfield dome through the wind-up")
	await _seconds(0.8)
	_check(_active_footprints() >= 2, "and the charge leaves glowing footprints behind the tank")
	await _seconds(ScribeInvocationFX.FOOTPRINT_TIME)
	_check(astral != null and not astral.in_use, "the Star-Inked flourish lasts 2.5 s, then goes back to the pool")

	var shiny_kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	shiny_kit.lead_variants[0] = ScribeCardResource.CardVariant.GILDED_LEAF
	var shiny_charge: CombatActionResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, shiny_kit).card_action(0)
	var plain_charge: CombatActionResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK).card_action(0)
	_check(is_equal_approx(shiny_charge.damage, plain_charge.damage * 1.1) and shiny_charge.action_id == plain_charge.action_id,
		"a finish adds potency (14 GDD §8): a Gilded Leaf Shield Charge hits 10% harder (%.1f vs %.1f), with the same action id" % [shiny_charge.damage,
			plain_charge.damage])
	tank.re_equip(ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK))

	await _until_idle(dps)
	_face_boss(dps, Vector3(0.0, 0.0, 9.0))
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.BACK_HEAVY)
	await _seconds(0.05)
	var shot_fx: ScribeInvocationFX = _active_invocation(dps)
	_check(shot_fx != null and shot_fx.is_showing_muzzle_ring(), "a card fired through the bow charges through a standing Sign ring first")
	await _seconds(1.0)
	boss.set_physics_process(true)
	_stage_party()


## The tank, re-equipped with a Shield Charge copy of `variant`, charges the boss;
## returns its invocation effect.
func _charge_with(variant: ScribeCardResource.CardVariant) -> ScribeInvocationFX:
	var kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	kit.lead_variants[0] = variant
	tank.re_equip(ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, kit))
	await _until_idle(tank)
	_face_boss(tank, Vector3(0.0, 0.0, 7.5))
	tank.stats.stamina = tank.stats.stats.max_stamina
	tank.input.inject_command(Cmd.FORWARD_HEAVY)
	await _seconds(0.05)
	return _active_invocation(tank)


func _active_invocation(caster: ActorBase) -> ScribeInvocationFX:
	for child: Node in CombatDirector.current.fx_pool.get_children():
		var fx: ScribeInvocationFX = child as ScribeInvocationFX
		if fx != null and fx.in_use and fx.caster == caster:
			return fx
	return null


func _active_footprints() -> int:
	var count: int = 0
	for child: Node in CombatDirector.current.fx_pool.get_children():
		var footprint: GlowFootprint = child as GlowFootprint
		if footprint != null and footprint.in_use:
			count += 1
	return count


## How far a roll carries the actor in a given armor (in open floor, rolling back),
## as an Iron-Woodsman (a Stout Heart may wear any armor).
func _measure_roll(actor: ActorBase, armor_id: StringName) -> float:
	actor.re_equip(_compose(actor.loadout.class_id, armor_id, &"", Callings.Secondary.STOUT_HEART))
	await _until_idle(actor)
	actor.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(14.0, 0.0, 6.0)))
	actor.input.inject_move(Vector2.ZERO)
	actor.stats.stamina = actor.stats.stats.max_stamina
	await _seconds(0.1)
	var start: Vector3 = actor.global_position
	actor.input.inject_command(Cmd.DODGE)
	await _seconds(1.2)
	return Vector2(actor.global_position.x - start.x, actor.global_position.z - start.z).length()


func _check_poise_and_knockdown() -> void:
	_reset_boss_poise()
	CombatDirector.current.deliver(_strike(tank, boss, 0.0, 30.0))
	await _seconds(1.0)
	_check(is_equal_approx(boss.stats.poise, boss.stats.stats.max_poise - 30.0), "poise holds for a moment after a hit")
	await _seconds(boss.stats.stats.poise_regen_delay + 0.6)
	_check(boss.stats.poise >= boss.stats.stats.max_poise - 10.0, "then it regenerates, so a break needs a focused burst")
	CombatDirector.current.deliver(_strike(tank, boss, 0.0, 500.0))
	await _seconds(0.05)
	var before: float = boss.stats.health
	CombatDirector.current.deliver(_strike(tank, boss, 40.0, 0.0))
	await _seconds(0.05)
	_check(boss.stats.is_knocked_down() and is_equal_approx(before - boss.stats.health, 50.0), "a knocked-down boss takes x1.25 damage")
	# The Cairnsman's suite and its Poise-Stagger Lydian window (16 GDD §5.3, Stage C).
	var score: AudioDirector = AudioDirector.current
	score.wait_for_renders()
	score.evaluate_now()
	var flourish_path: String = AudioCatalog.boss(ArsenalCatalog.CAIRNSMAN).stagger_stinger_path
	var flourish: AudioStreamOggVorbis = load(flourish_path) as AudioStreamOggVorbis if ResourceLoader.exists(flourish_path) else null
	_check(score.state == AudioDirector.AcousticState.BOSS and score.stagger_window and score.get_active_profile_id() == &"cairnsmans_vigil"
		and is_zero_approx(score.get_stem_target_db(1)) and is_equal_approx(score.get_stem_target_db(3), -14.0) and score.get_stem_target_db(2) <= -17.9
		and _stingers_heard.has(&"poise_stagger_flourish") and flourish != null and not flourish.loop,
		"knocked down, the Cairnsman's Vigil opens its Poise-Stagger window: the D Lydian triumph stem swells to 0 dB, the minor counterpoint drops to %.0f dB and the percussion 14 dB, under the acoustic harp, accordion and carillon flourish (boss engaged: %s)" % [
			score.get_stem_target_db(2), boss.engaged])
	_reset_boss_poise()


func _check_taunt() -> void:
	_stage_party()
	await _until_idle(tank)
	boss.threat.add_threat(dps.player_id, 5000.0)
	await _seconds(0.1)
	tank.stats.add_resonance(1.0)
	tank.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(0.7)
	_check(boss.threat.taunt_holder == tank.player_id, "Taunt locks the boss onto the tank")
	_check(boss.threat.current_target == tank.player_id, "the boss's target follows the taunt")


func _check_perfect_guard() -> void:
	# The test throws the swipes: the boss's own swings mustn't land in the window too.
	boss.set_physics_process(false)
	boss.cancel_action()
	await _until_idle(tank)
	_reset_boss_poise()
	var guards_before: int = _perfect_guards
	tank.stats.resonance_charge = 0.0
	var threat_before: float = boss.threat.threat_of(tank.player_id)
	var health_before: float = tank.stats.health
	tank.input.inject_guard(true)
	await _seconds(0.05)
	_check(tank.state_machine.is_in(&"guard"), "holding L raises the tank's Active Guard")
	CombatDirector.current.deliver(CombatEvent.strike_from(boss, tank, boss.loadout.openers[0]))
	await _seconds(0.1)
	_check(_perfect_guards == guards_before + 1, "a guard raised within 200 ms is a Perfect Guard")
	_check(is_equal_approx(tank.stats.health, health_before), "a Perfect Guard takes no damage")
	_check(is_equal_approx(boss.stats.poise, boss.stats.stats.max_poise - CombatDirector.PERFECT_GUARD_POISE), "a Perfect Guard deals 50 poise to the attacker")
	_check(boss.threat.threat_of(tank.player_id) - threat_before >= CombatDirector.PERFECT_GUARD_THREAT, "a Perfect Guard generates big threat")
	_check(tank.stats.resonance_charge >= CombatDirector.PERFECT_GUARD_RESONANCE, "a Perfect Guard earns half a pip")
	await _seconds(0.3)
	CombatDirector.current.deliver(CombatEvent.strike_from(boss, tank, boss.loadout.openers[0]))
	await _seconds(0.05)
	_check(_outcomes.has(StatsComponent.StrikeOutcome.GUARDED), "a late guard still blocks, for stamina")
	tank.input.inject_guard(false)
	boss.set_physics_process(true)


func _check_healer() -> void:
	# Out of the boss's swing arc, so a swipe can't hide the heal.
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(8.0, 0.0, 9.0)))
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(4.0, 0.0, 11.0)))
	await _until_idle(healer)
	healer.stats.resonance_charge = 0.0
	dps.stats.take_damage(40.0)
	var hurt_health: float = dps.stats.health
	healer.tether.bind_actor(dps)
	healer.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(1.2)
	_check(dps.stats.health > hurt_health, "a homing heal flies down the Soul Tether")
	_check(healer.stats.resonance_charge > 0.1, "healing fills the healer's resonance")
	_check(healer.tether.slot_arrow_for(dps.player_id) != "•", "D-Pad slots point at party members")

	await _until_idle(healer)
	healer.stats.add_resonance(1.0)
	healer.input.inject_command(Cmd.BACK_HEAVY)
	await _seconds(0.6)
	_check(_count_zones(SanctuaryZone.Shape.RING) >= 1, "Back + Heavy plays the healer's Green Sanctuary card: a healing ring")

	await _until_idle(healer)
	dps.place_at(Transform3D(Basis.IDENTITY, healer.global_position + Vector3(9.0, 0.0, 0.0)))
	healer.stats.add_resonance(2.0)
	healer.input.inject_command(Cmd.TRIGGER_BOTH_ULT)
	await _seconds(0.9)
	_check(dps.global_position.distance_to(healer.global_position) < 3.0, "Lifeline Pull yanks the tethered ally to the healer")

	dps.stats.take_damage(9999.0)
	await _seconds(0.05)
	_check(dps.state_machine.is_in(&"downed"), "out of health means downed")
	CombatDirector.current.apply_heal(healer, dps, 20.0)
	await _seconds(0.1)
	_check(not dps.stats.is_downed and dps.state_machine.is_in(&"idle"), "a heal brings a downed ally back")


func _check_shadow_sanctuary() -> void:
	await _until_idle(tank)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 3.0)))
	tank.input.inject_command(Cmd.BACK_HEAVY)
	await _seconds(0.6)
	_check(_count_zones(SanctuaryZone.Shape.CONE) >= 1, "back + heavy raises a Shadow Sanctuary cone")
	healer.place_at(Transform3D(Basis.IDENTITY, tank.global_position + Vector3(0.0, 0.0, 3.0)))
	await _seconds(0.05)
	_check(is_equal_approx(CombatDirector.current.damage_taken_multiplier(healer), 0.4), "allies behind the tank take 60% less damage")
	_check(is_equal_approx(CombatDirector.current.damage_taken_multiplier(tank), 1.0), "the cone doesn't shield the tank itself")


func _check_squire_auto_evade() -> void:
	await _until_idle(healer)
	healer.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
	healer.apply_assist_mode()
	healer.place_at(Transform3D(Basis.IDENTITY, Vector3(14.0, 0.0, 10.0)))
	healer.stats.stamina = healer.stats.stats.max_stamina
	var decal: RaidTelegraphDecal = RaidTelegraphDecal.new()
	decal.configure(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT, 3.5, 1.2, null)
	dojo.telegraphs_root.add_child(decal)
	decal.global_position = healer.global_position + Vector3(0.6, 0.0, 0.0)
	_healer_states.clear()
	await _seconds(1.4)
	_check(_healer_states.has(&"dodge"), "Squire Gambit auto-evades a red telegraph at 85% fill")
	_check(not decal.is_inside_tree() or not decal.contains(healer.global_position), "the auto-evade rolls out of the red zone")
	healer.input.assist_mode = InputComponent.AssistMode.ADVENTURER
	healer.apply_assist_mode()


## Squire Gambit guards the boss's Crushing Swipe for you (with 25+ stamina);
## L is Guard for every class now, so the Squire DPS guards too; and at range
## Squire fires whatever reaches (a bow shot, a card bolt) instead of running in.
func _check_squire_auto_guard() -> void:
	boss.set_physics_process(false) # The test starts each swipe itself.
	boss.cancel_action()
	await _until_idle(tank)
	_reset_boss_poise()
	boss.threat.taunt(tank.player_id, 5.0)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.4))
	tank.input.inject_guard(false)
	tank.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
	tank.apply_assist_mode()
	tank.stats.stamina = tank.stats.stats.max_stamina
	await _seconds(0.1)
	_check(not tank.state_machine.is_in(&"guard"), "no swipe, no guard")
	var outcomes_before: int = _outcomes.size()
	boss.action_queue.request(Cmd.LIGHT)
	await _seconds(0.1)
	_check(tank.input.is_auto_guarding() and tank.state_machine.is_in(&"guard"), "Squire Gambit raises the guard as the boss winds up its Crushing Swipe")
	boss.set_physics_process(true)
	await _seconds(1.2)
	_check(_outcomes.slice(outcomes_before).has(StatsComponent.StrikeOutcome.GUARDED), "the swipe lands on the raised guard")
	_check(not tank.input.is_auto_guarding() and not tank.state_machine.is_in(&"guard"), "and the guard drops once the swing is over")

	boss.set_physics_process(false)
	boss.cancel_action()
	await _until_idle(tank)
	tank.stats.stamina = InputComponent.AUTO_GUARD_MIN_STAMINA - 5.0
	boss.action_queue.request(Cmd.LIGHT)
	await _seconds(0.1)
	_check(not tank.input.is_auto_guarding() and not tank.state_machine.is_in(&"guard"), "with under 25 stamina there's no auto-guard")
	boss.cancel_action()
	tank.input.assist_mode = InputComponent.AssistMode.ADVENTURER
	tank.apply_assist_mode()
	tank.stats.stamina = tank.stats.stats.max_stamina

	await _until_idle(dps)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 9.0))
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.2))
	dps.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
	dps.apply_assist_mode()
	dps.stats.stamina = dps.stats.stats.max_stamina
	boss.action_queue.request(Cmd.LIGHT)
	await _seconds(0.1)
	_check(dps.input.is_auto_guarding() and dps.state_machine.is_in(&"guard"), "L is Guard for every class now, so a Squire DPS auto-guards too")
	boss.cancel_action()
	await _until_idle(dps)
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 9.0))
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 9.0 + Vector3(2.0, 0.0, 0.0)))
	var bow_pick: CombatActionResource = dps.loadout.opener_for(dps.input._squire_pick() as CombatActionResource.Command)
	_check(bow_pick != null and bow_pick.is_projectile() and bow_pick.reach_distance() >= 9.0,
		"Squire with a bow at 9 m shoots from where it stands (%s)" % (bow_pick.display_name if bow_pick != null else "nothing"))
	var staff_pick: int = healer.input._squire_pick()
	var staff_action: CombatActionResource = healer.loadout.opener_for(staff_pick as CombatActionResource.Command)
	_check(staff_pick == Cmd.FORWARD_HEAVY and staff_action.is_projectile(), "Squire with a staff out of sweep reach fires its Sunlit Lance card as a bolt")
	dps.input.assist_mode = InputComponent.AssistMode.MASTER
	dps.apply_assist_mode()
	boss.set_physics_process(true)


## Golden Communion needs max(1, standing / 2) players inside and hurts 30 per
## standing player (up to 90), so a 2-player couch can always clear it.
func _check_soak_scaling() -> void:
	var required: Array[int] = []
	for players: int in range(1, 6):
		required.append(BossDummy.soak_required(players))
	_check(required == [1, 1, 1, 2, 2], "a soak needs max(1, players / 2) inside: %s for 1 to 5 players" % str(required))
	_check(is_equal_approx(BossDummy.soak_total_damage(2), 60.0) and is_equal_approx(BossDummy.soak_total_damage(5), 90.0),
		"soak damage is 30 per standing player, up to 90")
	# Earlier zones (a Shadow Sanctuary cone) would soften the numbers below.
	for child: Node in dojo.effects_root.get_children():
		if child is SanctuaryZone:
			child.queue_free()
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	dps.stats.take_damage(9999.0) # Two left standing: a 2-player couch.
	await _seconds(0.05)
	var decal: RaidTelegraphDecal = RaidTelegraphDecal.new()
	decal.configure(RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK, BossDummy.SOAK_RADIUS, BossDummy.SOAK_CAST_TIME, null)
	dojo.telegraphs_root.add_child(decal)
	decal.global_position = tank.global_position
	var tank_before: float = tank.stats.health
	var healer_before: float = healer.stats.health
	var alone: Array[ActorBase] = [tank]
	boss._on_telegraph_resolved(decal, alone)
	await _seconds(0.05)
	_check(is_equal_approx(tank_before - tank.stats.health, 60.0 * (1.0 - tank.loadout.stats.damage_mitigation)) and is_equal_approx(healer.stats.health, healer_before),
		"with 2 standing, one player soaking alone clears it (60 damage before armor, nobody else hurt)")
	var nobody: Array[ActorBase] = []
	boss._on_telegraph_resolved(decal, nobody)
	await _seconds(0.05)
	_check(is_equal_approx(healer_before - healer.stats.health, BossDummy.SOAK_FAIL_DAMAGE * (1.0 - healer.loadout.stats.damage_mitigation)),
		"an empty soak fails: 30 to everyone standing (before armor)")
	decal.queue_free()
	CombatDirector.current.apply_heal(healer, dps, dps.stats.stats.max_health)
	await _seconds(0.1)


func _check_telegraphs() -> void:
	# Bring everyone back to the boss so it stays engaged while it casts.
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
		actor.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(randf_range(-3.0, 3.0), 0.0, 4.0)))
	var waited: float = 0.0
	while waited < TELEGRAPH_TIMEOUT and not (_telegraph_kinds.has(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT) and _telegraph_kinds.has(RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK)):
		await _seconds(0.5)
		waited += 0.5
		# Keep the party alive: a wipe resets the fight and restarts the cast cycle.
		for actor: ActorBase in [tank, healer, dps]:
			actor.stats.heal(actor.stats.stats.max_health)
	_check(_telegraph_kinds.has(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT), "the boss casts CRIMSON_DODGE_OUT")
	_check(_telegraph_kinds.has(RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK), "the boss casts GOLD_PARTY_SOAK")
	await _seconds(BossDummy.SOAK_CAST_TIME + 1.0)
	_check(_telegraph_hits > 0, "telegraphs resolve into damage on the players inside")


## The whole party down: the boss goes home at full health with an empty aggro table.
func _check_wipe_resets_fight() -> void:
	_reset_boss_poise()
	for actor: ActorBase in [tank, healer, dps]:
		actor.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 4.0)))
	await _seconds(0.3)
	boss.stats.take_damage(150.0)
	_check(boss.engaged and boss.stats.health < boss.stats.stats.max_health, "the boss is mid-fight and hurt")
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.take_damage(9999.0)
	await _seconds(0.3)
	_check(not boss.engaged and is_equal_approx(boss.stats.health, boss.stats.stats.max_health) and boss.threat.aggro_table.is_empty(),
		"a party wipe resets the fight (full health, empty aggro table)")
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	await _seconds(0.1)


## Fewer than 3 people: AI companions fill the missing trinity roles, fight by
## their Gambit lists, and step aside when people come back.
## The Cairnsman's Phase 2 (07 GDD §3, Zone 3): at half health Dover-Slap-Falls
## Gale-Beam joins its casts, aimed at the tank. Behind the tank's Shadow
## Sanctuary nobody is hurt and everyone earns half a pip; out in the lane it hits
## for 40 (before armor) and throws you back.
func _check_gale_beam() -> void:
	_reset_boss_poise()
	await _until_idle(tank)
	_face_boss(tank, Vector3(0.0, 0.0, 2.6))
	_face_boss(dps, Vector3(0.0, 0.0, 5.5))
	_face_boss(healer, Vector3(0.0, 0.0, 12.5))
	for actor: ActorBase in [tank, healer, dps]:
		actor.input.inject_move(Vector2.ZERO)
	boss.threat.taunt(tank.player_id, 30.0)
	await _seconds(0.3)
	_check(boss.engaged and not boss.phase_two, "a fresh fight starts in Phase 1")
	boss.stats.health = boss.stats.stats.max_health * 0.45
	await _seconds(0.2)
	_check(boss.phase_two and boss._cast_after(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT) == RaidTelegraphDecal.Kind.BLUE_BEHIND_TANK
		and boss._cast_after(RaidTelegraphDecal.Kind.BLUE_BEHIND_TANK) != RaidTelegraphDecal.Kind.BLUE_BEHIND_TANK,
		"at half health the Cairnsman enters Phase 2: the Gale-Beam comes between his other casts")
	var beam: RaidTelegraphDecal = null
	var waited: float = 0.0
	while waited < 4.0 and beam == null:
		await physics_frame
		waited += 1.0 / 60.0
		beam = CombatDirector.current.beam_telegraph()
	_check(beam != null and beam.follow_target == tank and boss.cast_name == "Dover-Slap Gale-Beam" and is_equal_approx(beam.cast_time, 3.2),
		"the Dover-Slap Gale-Beam: a blue lane from the boss to the tank with a shield pillar, cast over 3.2 s")
	if beam == null:
		return
	await physics_frame
	_check((dojo.huds[tank.player_id] as PlayerHUD).callout() == "RAISE SHADOW SANCTUARY!"
		and (dojo.huds[healer.player_id] as PlayerHUD).callout() == "STAND BEHIND THE TANK!",
		"under the boss frame, the tank's HUD says raise Shadow Sanctuary and everyone else's says stand behind the tank")
	tank.stats.stamina = tank.stats.stats.max_stamina
	tank.input.inject_command(Cmd.BACK_HEAVY)
	dps.stats.resonance_charge = 0.0
	healer.stats.heal(healer.stats.stats.max_health)
	dps.stats.heal(dps.stats.stats.max_health)
	await _seconds(0.6)
	_check(beam.contains(dps.global_position) and beam.contains(healer.global_position) and CombatDirector.current.is_sheltered(dps)
		and not CombatDirector.current.is_sheltered(healer), "the DPS stands in the tank's cone; the healer stands out in the lane")
	var dps_health: float = dps.stats.health
	var healer_health: float = healer.stats.health
	var healer_distance: float = healer.global_position.distance_to(boss.global_position)
	await _seconds(BossDummy.BEAM_CAST_TIME - beam.elapsed + 0.5)
	_check(is_equal_approx(dps.stats.health, dps_health) and is_equal_approx(dps.stats.resonance_charge, BossDummy.BEAM_SHELTER_PIPS),
		"behind the shield the DPS takes nothing and earns half a pip")
	_check(healer_health - healer.stats.health >= BossDummy.BEAM_DAMAGE * 0.75 and healer.global_position.distance_to(boss.global_position) > healer_distance + 2.0,
		"out in the lane the healer is hit hard (%d) and thrown back" % roundi(healer_health - healer.stats.health))
	boss._reset_fight()
	boss.threat.clear()
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	await _seconds(0.1)


## 08 Gate 5: a Squire-mode child survives the Gale-Beam. Aimed at a Squire
## tank facing the wrong way, it turns and raises Shadow Sanctuary itself; a
## Squire archer left out in the lane rolls clear before the torrent.
func _check_squire_beam_assist() -> void:
	var tank_mode: InputComponent.AssistMode = tank.input.assist_mode
	var dps_mode: InputComponent.AssistMode = dps.input.assist_mode
	for actor: ActorBase in [tank, dps]:
		actor.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
		actor.apply_assist_mode()
	_reset_boss_poise()
	await _until_idle(tank)
	# The tank stands in front of the boss but faces away from it.
	tank.place_at(Transform3D(Basis.looking_at(Vector3(0.0, 0.0, 1.0), Vector3.UP), boss.global_position + Vector3(0.0, 0.0, 2.8)))
	_face_boss(dps, Vector3(0.0, 0.0, 13.0))
	_face_boss(healer, Vector3(9.0, 0.0, 4.0))
	for actor: ActorBase in [tank, healer, dps]:
		actor.input.inject_move(Vector2.ZERO)
		actor.stats.heal(actor.stats.stats.max_health)
		actor.stats.stamina = actor.stats.stats.max_stamina
	boss.threat.taunt(tank.player_id, 30.0)
	await _seconds(0.3)
	boss.stats.health = boss.stats.stats.max_health * 0.45
	boss._next_cast = RaidTelegraphDecal.Kind.BLUE_BEHIND_TANK
	boss._cast_timer = 0.0
	var beam: RaidTelegraphDecal = null
	var waited: float = 0.0
	while waited < 4.0 and beam == null:
		await physics_frame
		waited += 1.0 / 60.0
		beam = CombatDirector.current.beam_telegraph()
	_check(beam != null and beam.follow_target == tank and beam.contains(dps.global_position), "a Gale-Beam is aimed at the Squire tank, with the Squire archer out in its lane")
	if beam == null:
		return
	var dps_health: float = dps.stats.health
	await _seconds(BossDummy.BEAM_CAST_TIME + 0.4)
	_check(CombatDirector.current.has_zone_from(tank.player_id) and tank.facing_vector().dot((boss.global_position - tank.global_position).normalized()) > 0.9,
		"Squire Gambit turns the tank to the boss and raises Shadow Sanctuary for it")
	_check(is_equal_approx(dps.stats.health, dps_health), "the Squire archer rolls out of the lane before the torrent and takes nothing")
	for actor: ActorBase in [tank, dps]:
		actor.input.assist_mode = tank_mode if actor == tank else dps_mode
		actor.apply_assist_mode()
	boss._reset_fight()
	boss.threat.clear()
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	await _seconds(0.1)


func _check_companion_backfill() -> void:
	var network: NetworkManager = NetworkManager.current
	_check(network.companion_seats().is_empty(), "a full trinity of people needs no companions")
	network.drop_local_player(1)
	network.drop_local_player(2)
	await _seconds(0.1)
	var bot_healer: ActorBase = _companion_with(ClassLoadoutResource.Role.HEALER)
	var bot_dps: ActorBase = _companion_with(ClassLoadoutResource.Role.DPS)
	_check(network.human_count() == 1 and _companions().size() == 2 and bot_healer != null and bot_dps != null,
		"with one person left, companions fill in as the Healer and the DPS")
	_check(dojo.grid.view_count() == 1 and dojo.huds.size() == 1, "companions get no split-screen view or HUD")
	var driven: bool = true
	for bot: ActorBase in _companions():
		driven = driven and bot.companion != null and bot.input == null and bot.is_companion and bot.display_name().begins_with("P%d · " % (bot.party_slot + 1)) and not bot.display_name().contains("(bot)")
	_check(driven, "each is driven by a CompanionAIComponent, its nameplate \"P# · <Fellowship>\" like any hero's (18 GDD §6.2: no \"(bot)\")")
	_check(network.local_player_count() == 1 and network.party_size() == 3, "they fill the party without taking a screen's player places")

	# A fight: the tank holds the boss while the companions do their jobs.
	_reset_boss_poise()
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.6))
	tank.input.inject_move(Vector2.ZERO)
	boss.threat.taunt(tank.player_id, COMPANION_FIGHT_TIME)
	tank.stats.take_damage(80.0)
	var heals_before: int = _audio_cues.count(&"heal")
	var dps_gambits: Dictionary[int, bool] = {}
	var waited: float = 0.0
	while waited < COMPANION_FIGHT_TIME:
		await _seconds(0.25)
		waited += 0.25
		dps_gambits[bot_dps.companion.current_gambit] = true
		if tank.stats.health < 50.0:
			tank.stats.heal(80.0) # Keep the test's tank up (a direct heal, so it isn't counted below).
	_check(_audio_cues.count(&"heal") > heals_before, "the companion healer heals the hurt tank")
	_check(boss.threat.threat_of(bot_dps.player_id) > 0.0 and (dps_gambits.has(CompanionAIComponent.Gambit.ATTACK)
		or dps_gambits.has(CompanionAIComponent.Gambit.PRIME)), "the companion DPS fights the boss with its bow")

	# The last person switches to DPS: a companion Tank takes the front.
	network.update_local_player(InputComponent.KEYBOARD_DEVICE, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.ADVENTURER)
	await _seconds(0.1)
	var bot_tank: ActorBase = _companion_with(ClassLoadoutResource.Role.TANK)
	_check(bot_tank != null and _companion_with(ClassLoadoutResource.Role.HEALER) != null and _companions().size() == 2,
		"switching the last person to DPS swaps the companion DPS for a companion Tank")
	_reset_boss_poise()
	bot_tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.4))
	boss.threat.taunt(bot_tank.player_id, COMPANION_FIGHT_TIME)
	var guards_before: int = _companion_perfect_guards
	waited = 0.0
	# Hit-stop from the bots' own blows and the boss's telegraph casts both hold its swing back, so allow a few swings' time.
	while waited < COMPANION_GUARD_TIME and _companion_perfect_guards == guards_before:
		await _seconds(0.25)
		waited += 0.25
		# A Stout Heart's poise hits would keep the boss knocked down; it has to swing for this.
		if boss.stats.is_knocked_down():
			_reset_boss_poise()
	_check(_companion_perfect_guards > guards_before, "the companion Tank times a Perfect Guard on the Crushing Swipe (%.1f s)" % waited)
	# The Gale-Beam at the bot tank: it raises Shadow Sanctuary, and the bot healer gets behind it.
	var beam_healer: ActorBase = _companion_with(ClassLoadoutResource.Role.HEALER)
	_reset_boss_poise() # That Perfect Guard may have knocked it down, and a knocked-down boss casts nothing.
	boss.threat.taunt(bot_tank.player_id, COMPANION_FIGHT_TIME)
	boss._next_cast = RaidTelegraphDecal.Kind.BLUE_BEHIND_TANK
	boss._cast_timer = 0.0
	waited = 0.0
	var sheltered_healer: bool = false
	while waited < 6.0 and not (CombatDirector.current.has_zone_from(bot_tank.player_id) and sheltered_healer):
		await _seconds(0.1)
		waited += 0.1
		sheltered_healer = sheltered_healer or CombatDirector.current.is_sheltered(beam_healer)
	_check(CombatDirector.current.has_zone_from(bot_tank.player_id), "against the Gale-Beam the companion Tank turns to the boss and raises Shadow Sanctuary")
	_check(sheltered_healer, "and the companion healer gets behind its shield")

	# People come back: the companions step aside and the player numbers are theirs again.
	network.update_local_player(InputComponent.KEYBOARD_DEVICE, ClassLoadouts.SHIELD_TANK, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(1, ClassLoadouts.SOUL_TETHER_HEALER, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.1)
	_check(network.companion_seats().is_empty() and network.human_count() == 3 and dojo.actors.size() == 3,
		"when people rejoin, the companions step aside")
	_check(network.member(&"1_1").slot == 1 and network.member(&"1_2").slot == 2, "and the people get players 2 and 3 back")
	tank = dojo.actors[&"1_0"]
	healer = dojo.actors[&"1_1"]
	dps = dojo.actors[&"1_2"]


# --- Phase 11 combat track -----------------------------------------------

## The kinetic loop, Martial Imbuement and the Trail of the Four Signs
## (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md): the four weapon tiers, a Level 1
## party in timber with an un-inked R and L+R, the winded third Light and the
## Flow-Link Pulse, the Braced Front Guard and the Flank Breach, the trail's
## milestones auto-slotting at Levels 2 to 10, and a card's Sign Ring, badge
## and the teammate's detonation prompt. Puts the classic Level 10 kits back after.
func _check_phase_11_combat_onboarding_and_flanking() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var progress: PartyProgress = PartyProgress.current
	var network: NetworkManager = NetworkManager.current
	var director: CombatDirector = CombatDirector.current

	# The four tiers: their levels, multipliers and materials.
	var tiers_ok: bool = true
	var blades: Array[Color] = []
	for tier: int in range(1, 5):
		blades.append(catalog.item(ArsenalCatalog.tier_weapon_id(EquipmentItemResource.WeaponType.LIGHT_SWORD, tier)).blade_albedo)
		for weapon_type: int in ArsenalCatalog.CLASSIC_WEAPONS.size():
			var weapon: EquipmentItemResource = catalog.item(ArsenalCatalog.tier_weapon_id(weapon_type, tier))
			var classic: EquipmentItemResource = catalog.item(ArsenalCatalog.CLASSIC_WEAPONS[weapon_type])
			tiers_ok = tiers_ok and weapon != null and weapon.weapon_type == classic.weapon_type and int(weapon.equipment_tier) == tier \
				and weapon.required_level == ArsenalCatalog.TIER_LEVELS[tier - 1] \
				and is_equal_approx(weapon.heavy.damage, classic.heavy.damage * ArsenalCatalog.TIER_MULTIPLIERS[tier - 1]) \
				and is_equal_approx(weapon.metallic_factor, ArsenalCatalog.TIER_METALLIC[tier - 1])
	var distinct: bool = true
	for index: int in blades.size():
		for other: int in range(index + 1, blades.size()):
			distinct = distinct and not blades[index].is_equal_approx(blades[other])
	_check(tiers_ok and distinct, "16 trail weapons in four tiers (Level 1/2/5/10, 1.0/1.2/1.45/1.75x the classic's damage), each tier its own blade colour and metal")
	var hazel: EquipmentItemResource = catalog.item(ArsenalCatalog.HAZEL_FALCHION)
	var relic: EquipmentItemResource = catalog.item(ArsenalCatalog.CAIRNSMAN_FALCHION)
	var wooden: bool = true
	for part: PropPartResource in hazel.prop_parts:
		wooden = wooden and is_zero_approx(part.metal) and is_zero_approx(part.glow)
	var relic_metal: bool = false
	var relic_stone: bool = false
	for part: PropPartResource in relic.prop_parts:
		relic_metal = relic_metal or part.metal >= 0.9
		relic_stone = relic_stone or part.glow > 0.0
	var probe: Node3D = PropBuilder.build(relic.prop_parts, null, "Probe")
	var blade_material: ShaderMaterial = ((probe.get_child(0) as MeshInstance3D).mesh as PrimitiveMesh).material as ShaderMaterial
	var glinting: bool = blade_material != null and is_equal_approx(float(blade_material.get_shader_parameter(&"metal")), 0.9)
	probe.free()
	_check(wooden and relic_metal and relic_stone and glinting and hazel.uninked_r_skill_name == "Timber-Cross Slash",
		"the Turned-Hazel Falchion is plain wood; the Cairnsman's Span-Blade is 0.9-metal relic bronze with a glowing Sign-stone")
	var start: Dictionary = catalog.get_default_level_one_loadout_for_role(ClassLoadoutResource.Role.TANK)
	_check(start["weapon_id"] == ArsenalCatalog.HAZEL_FALCHION and start["armor_id"] == ArsenalCatalog.BRAMBLE_JERKIN and start["r_card_id"] == &""
		and start["ult_card_id"] == &"" and start["under_card_id"] == &"", "a Level 1 Shield-Sworn starts with the Turned-Hazel Falchion, the Bramble-Spun Jerkin and an empty R and L+R")
	var tank_role: int = ClassLoadoutResource.Role.TANK
	_check(catalog.get_milestone_grant_for_level(2, tank_role)["weapon_id"] == ArsenalCatalog.IRON_FALCHION
		and catalog.get_milestone_grant_for_level(3, ClassLoadoutResource.Role.DPS)["r_card_id"] == ArsenalCatalog.RIME_LASH
		and catalog.get_milestone_grant_for_level(5, tank_role)["ult_card_id"] == ArsenalCatalog.BULWARK_QUAKE
		and catalog.get_milestone_grant_for_level(7, tank_role)["under_card_id"] == ArsenalCatalog.IRON_ROOT_LINK
		and catalog.get_milestone_grant_for_level(10, tank_role)["unlocks_secondary_calling"] and catalog.get_milestone_grant_for_level(4, tank_role).is_empty(),
		"milestones: Tier 2 at Level 2, an R card at 3, Tier 3 and an L+R card at 5, an Under-Card at 7, Tier 4 and the Callings at 10")
	_check(PartyProgress.level_for_xp(PartyProgress.XP_PER_MOB * 7 + PartyProgress.XP_PER_GATE) == 5
		and PartyProgress.level_for_xp((PartyProgress.XP_PER_MOB * 7 + PartyProgress.XP_PER_GATE + PartyProgress.XP_PER_BOSS) * 2) == 10,
		"one expedition (7 mobs at 35 XP and the gate at 80) reaches Level 5 at the Gatehouse; a second, with the Cairnsman at 200, reaches Level 10")

	# Back to Level 1: the party in timber, Unsworn, with an un-inked R and L+R.
	var callings_before: Dictionary[StringName, StringName] = {}
	for actor: ActorBase in [tank, healer, dps]:
		callings_before[actor.player_id] = network.member(actor.player_id).calling
	var saved_kits: Dictionary = progress.kits.duplicate(true)
	var saved_callings: Dictionary = progress.callings.duplicate()
	progress.endgame_kits_for_testing = false
	progress.xp = 0
	BracedGuardComponent.enabled = true
	boss.set_physics_process(false)
	_reset_boss_poise()
	for actor: ActorBase in [tank, healer, dps]:
		await _until_idle(actor)
		network.update_local_calling(actor.device_id, Callings.UNSWORN_ID)
		network.update_local_kit(actor.device_id, progress.trail_kit(actor.loadout.class_id))
	await _seconds(0.1)
	var tank_r: CombatActionResource = tank.loadout.opener_for(Cmd.TRIGGER_R_SKILL)
	var tank_ult: CombatActionResource = tank.loadout.opener_for(Cmd.TRIGGER_BOTH_ULT)
	_check(tank.loadout.weapon.item_id == ArsenalCatalog.HAZEL_FALCHION and tank.loadout.armor.item_id == ArsenalCatalog.BRAMBLE_JERKIN
		and healer.loadout.weapon.item_id == ArsenalCatalog.REED_WAYSTAFF and dps.loadout.weapon.item_id == ArsenalCatalog.WILLOW_LONGBOW
		and tank.loadout.kit.lead_ids[2] == &"" and tank.loadout.kit.lead_ids[3] == &"" and tank.loadout.display_name == "Shield-Sworn",
		"at Level 1 the party carries Tier 1 timber in the Bramble-Spun Jerkin, Unsworn, with R and L+R empty")
	var hud_r: CrossGrimoireDiamondWidget = dojo.huds[&"1_0"].cross_grimoire.diorama
	_check(tank_r.uninked and tank_r.display_name == "Timber-Cross Slash" and tank_r.resonance_cost == 1 and tank_ult.display_name == "Bramble-Whirl Flurry"
		and tank_ult.resonance_cost == 3 and hud_r.socket_view(Diorama.SKILL)["leaf"] == &"" and dps.loadout.opener_for(Cmd.TRIGGER_R_SKILL).pierces
		and is_equal_approx(healer.loadout.opener_for(Cmd.TRIGGER_R_SKILL).heal_amount, LoadoutComposer.STAFF_FLOURISH_HEAL),
		"an empty R is the weapon's Un-Inked Martial Flourish (1 pip; L+R 3 pips), an empty diamond on the Cross-Grimoire: a bow's pierces, a staff's mends")
	var stops: Array[float] = []
	var stop_hook: Callable = func(duration: float) -> void: stops.append(duration)
	director.hit_stop_applied.connect(stop_hook)
	_face_boss(tank, Vector3(0.0, 0.0, 3.6))
	tank.stats.resonance_charge = 1.0
	var boss_health: float = boss.stats.health
	tank.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(0.3)
	var swelled: float = tank.visuals.weapon_scale()
	await _seconds(0.5)
	var heavy_stop: bool = false
	for duration: float in stops:
		heavy_stop = heavy_stop or is_equal_approx(duration, CombatDirector.HIT_STOP_HEAVY)
	_check(tank.stats.resonance_charge < 0.01 and swelled > 1.8 and is_equal_approx(boss_health - boss.stats.health, 18.0 * 1.6) and heavy_stop,
		"with 1 pip, R swings the Timber-Cross Slash: the falchion swells to %.1fx, hits for 1.6x the Heavy, and freezes 100 ms" % swelled)

	# The kinetic loop: three Lights in place wind the third; weaving F+H in the window is a Flow-Link Pulse.
	await _until_idle(tank)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(14.0, 0.0, 12.0)))
	var pulses: Array[int] = []
	var pulse_hook: Callable = func(_from: CombatActionResource, command: int) -> void: pulses.append(command)
	tank.action_queue.flow_link_pulsed.connect(pulse_hook)
	tank.stats.stamina = tank.stats.stats.max_stamina
	tank.stats.resonance_charge = 0.0
	var stepped_from: Vector3 = tank.global_position
	tank.input.inject_command(Cmd.LIGHT)
	await _until_recovery_of(tank, null)
	var first: CombatActionResource = tank.action_queue.current_action
	tank.input.inject_command(Cmd.LIGHT)
	await _until_recovery_of(tank, first)
	var second: CombatActionResource = tank.action_queue.current_action
	tank.input.inject_command(Cmd.LIGHT)
	await _until_recovery_of(tank, second)
	var queue: ActionQueueComponent = tank.action_queue
	_check(_flat(tank.global_position - stepped_from) > ActorBase.STEP_LIGHT_M * 2.5, "every Light steps the hero forward (%.1f m over three)" % _flat(tank.global_position - stepped_from))
	_check(queue.winded and is_equal_approx(queue.recovery_time, ActorBase.STATIC_MASH_RECOVERY_MS / 1000.0),
		"the third Light in place is winded: 550 ms of recovery")
	var stamina_before: float = tank.stats.stamina
	var charge_from: Vector3 = tank.global_position
	tank.input.inject_command(Cmd.FORWARD_HEAVY)
	await _seconds(1.0)
	var charge_cost: float = tank.loadout.opener_for(Cmd.FORWARD_HEAVY).stamina_cost
	_check(pulses.has(Cmd.FORWARD_HEAVY) and is_equal_approx(tank.stats.stamina, stamina_before - charge_cost + ActorBase.FLOW_LINK_STAMINA_REFUND)
		and is_equal_approx(tank.stats.resonance_charge, ActorBase.FLOW_LINK_BONUS_PIP) and _flat(tank.global_position - charge_from) >= ActorBase.STEP_FORWARD_HEAVY_M,
		"weaving Forward+Heavy into its first 220 ms is a Flow-Link Pulse: +8 stamina, +0.15 pip, and a %.1f m charge" % _flat(tank.global_position - charge_from))
	tank.action_queue.flow_link_pulsed.disconnect(pulse_hook)

	# The Braced Front Guard: three frontal hits raise it; the front takes 30%; a flank breaks it.
	await _until_idle(tank)
	boss.rotation = Vector3.ZERO
	var guard: BracedGuardComponent = boss.braced_guard
	guard._frontal_hits.clear()
	_face_boss(tank, Vector3(0.0, 0.0, -2.6))
	_face_boss(dps, Vector3(0.0, 0.0, 3.0))
	for hit: int in BracedGuardComponent.BRACED_GUARD_HIT_THRESHOLD:
		director.deliver(_strike(tank, boss, 10.0, 2.0))
		await _seconds(0.05)
	var buckler: Node3D = boss.get_node_or_null(^"BracedBuckler") as Node3D
	_check(guard.is_braced and buckler != null and buckler.visible, "three frontal hits within 4 s raise the amber Braced Front Buckler")
	_reset_boss_poise()
	var health_before: float = boss.stats.health
	var poise_before: float = boss.stats.poise
	director.deliver(_strike(tank, boss, 20.0, 10.0))
	_check(is_equal_approx(health_before - boss.stats.health, 20.0 * BracedGuardComponent.BRACED_FRONT_DAMAGE_MULT)
		and is_equal_approx(poise_before - boss.stats.poise, 10.0 * BracedGuardComponent.BRACED_FRONT_POISE_MULT),
		"braced, a frontal hit deals 30% damage and half poise")
	poise_before = boss.stats.poise
	var crack: CombatEvent = _strike(tank, boss, 0.0, 10.0)
	crack.scribe_sign = Sign.SIGN_IRON_ROOT
	director.deliver(crack)
	_check(is_equal_approx(poise_before - boss.stats.poise, 10.0 * BracedGuardComponent.TANK_GUARD_POISE_MULT), "a Shield-Sworn's Iron-Root strike cracks it from the front at 2x poise")
	health_before = boss.stats.health
	poise_before = boss.stats.poise
	var flank: CombatEvent = _strike(dps, boss, 20.0, 0.0)
	flank.command = Cmd.FORWARD_HEAVY
	director.deliver(flank)
	_check(is_equal_approx(health_before - boss.stats.health, 20.0 * BracedGuardComponent.FLANK_BREACH_DAMAGE_MULT)
		and is_equal_approx(poise_before - boss.stats.poise, BracedGuardComponent.FLANK_BREACH_BONUS_POISE) and not guard.is_braced,
		"a Forward+Heavy on its rear is a Flank Breach: 1.35x damage, +20 poise, and the guard shatters")
	_reset_boss_poise()
	await _until_idle(tank)
	_face_boss(tank, Vector3(0.0, 0.0, -2.6))
	for hit: int in BracedGuardComponent.BRACED_GUARD_HIT_THRESHOLD:
		director.deliver(_strike(tank, boss, 5.0, 0.0))
	var shove_at: Vector3 = boss.global_position + boss.facing_vector() * (boss.body_radius() + BracedGuardComponent.SHOVE_RADIUS * 0.5)
	var shove: RaidTelegraphDecal = null
	var braced_wait: float = 0.0
	while shove == null and braced_wait < BracedGuardComponent.SHOVE_DELAY_S + 0.5:
		await physics_frame
		braced_wait += 1.0 / 60.0
		shove = director.hostile_telegraph_at(shove_at, 0.0)
	# The circle frees itself once it has flashed, so note it now.
	var shove_seen: bool = shove != null
	var tank_spot: Vector3 = tank.global_position
	await _seconds(BracedGuardComponent.SHOVE_WINDUP_S + 0.5)
	var thrown: float = _flat(tank.global_position - tank_spot)
	_check(guard.is_braced and shove_seen and absf(braced_wait - BracedGuardComponent.SHOVE_DELAY_S) < 0.1 and thrown >= BracedGuardComponent.SHOVE_DISTANCE * 0.8,
		"after %.1f s braced it telegraphs a red 2.5 m shield-shove that throws the front-masher back %.1f m" % [braced_wait, thrown])
	guard._lower()
	_reset_boss_poise()

	# The trail: each milestone auto-slots into the slot still at its starter state.
	await _until_idle(healer)
	var healer_kit: EquipmentLoadoutResource = healer.loadout.kit.copy()
	healer_kit.lead_ids[2] = ArsenalCatalog.TAUNT
	network.update_local_kit(healer.device_id, healer_kit.to_dict())
	await _seconds(0.05)
	progress.award_xp(PartyProgress.LEVEL_XP[1] - progress.xp)
	await _seconds(0.1)
	var pennant: Node3D = tank.visuals.milestone_pennant()
	_check(progress.trail_level() == 2 and tank.loadout.weapon.item_id == ArsenalCatalog.IRON_FALCHION and dps.loadout.weapon.item_id == ArsenalCatalog.HORN_LONGBOW
		and healer.loadout.weapon.item_id == ArsenalCatalog.COPPER_WAYSTAFF and pennant != null and dojo.huds[&"1_0"].banner_title() == "LEVEL 2!",
		"Level 2: Hedgerow Iron goes straight into every hand, under a Wayfarer Pennant and a LEVEL 2! banner")
	progress.award_xp(PartyProgress.LEVEL_XP[2] - progress.xp)
	await _seconds(0.1)
	_check(tank.loadout.kit.lead_ids[2] == ArsenalCatalog.TAUNT and dps.loadout.kit.lead_ids[2] == ArsenalCatalog.RIME_LASH
		and healer.loadout.kit.lead_ids[2] == ArsenalCatalog.TAUNT and dps.loadout.opener_for(Cmd.TRIGGER_R_SKILL).scribe_sign == Sign.SIGN_RIME_GALE,
		"Level 3: a Plain Vellum R card slots into every empty R (Taunt, Rime-Lash); the healer's own pick stays")
	progress.award_xp(PartyProgress.LEVEL_XP[4] - progress.xp)
	await _seconds(0.1)
	_check(progress.trail_level() == 5 and tank.loadout.weapon.item_id == ArsenalCatalog.BRAMBLE_FALCHION and tank.loadout.kit.lead_ids[3] == ArsenalCatalog.BULWARK_QUAKE
		and dps.loadout.kit.lead_ids[3] == ArsenalCatalog.TEMPEST_FLOW and healer.loadout.kit.lead_ids[3] == ArsenalCatalog.LIFELINE_PULL,
		"Level 5: Bramble-Bridge Steel and an L+R card")
	progress.award_xp(PartyProgress.LEVEL_XP[6] - progress.xp)
	await _seconds(0.1)
	_check(tank.loadout.kit.under_ids[2] == ArsenalCatalog.IRON_ROOT_LINK and dps.loadout.kit.under_ids[2] == ArsenalCatalog.STAR_TIDE_LINK
		and healer.loadout.kit.under_ids[2] == ArsenalCatalog.WARM_HEARTH_LINK, "Level 7: an Under-Card tucks in beneath R")
	_check(network.member(tank.player_id).calling == Callings.UNSWORN_ID, "below Level 10 the Secondary Callings stay locked")
	progress.award_xp(PartyProgress.LEVEL_XP.back() - progress.xp)
	await _seconds(0.1)
	_check(progress.trail_level() == 10 and tank.loadout.weapon.item_id == ArsenalCatalog.CAIRNSMAN_FALCHION and dps.loadout.weapon.item_id == ArsenalCatalog.GORGE_LONGBOW
		and Callings.is_valid(tank.loadout.calling) and tank.loadout.display_name != "Shield-Sworn",
		"Level 10: a Dover-Slap relic, and the Secondary Calling opens (%s)" % tank.loadout.display_name)

	# A card's Sign: the bow swells Sea-Azure, the Ring and badge mark the foe, the tank is prompted to detonate.
	await _until_idle(dps)
	await _until_idle(tank)
	var tank_kit: EquipmentLoadoutResource = tank.loadout.kit.copy()
	tank_kit.lead_ids[2] = &""
	network.update_local_kit(tank.device_id, tank_kit.to_dict())
	_face_boss(dps, Vector3(1.5, 0.0, 8.0))
	_face_boss(tank, Vector3(0.0, 0.0, 3.6))
	dps.stats.resonance_charge = 1.0
	tank.stats.resonance_charge = 0.0
	dps.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(0.25)
	var dps_swell: float = dps.visuals.weapon_scale()
	# The Level 7 Star-Tide Link (Sign Infusion) makes Rime-Lash stamp Star-Tide.
	var lash_sign: int = dps.loadout.opener_for(Cmd.TRIGGER_R_SKILL).scribe_sign
	var lash_seal: ScribeSignResource = catalog.sign_seal(lash_sign)
	var tinted: bool = dps.visuals._channel_color.is_equal_approx(lash_seal.color)
	await _seconds(0.8)
	var mark: SignMark = director.sign_mark_on(boss)
	var badge_height: float = mark._badge.global_position.y - boss.global_position.y if mark != null else 0.0
	_check(lash_sign == Sign.SIGN_STAR_TIDE and dps_swell > 1.8 and tinted and mark != null and mark.scribe_sign == lash_sign
		and is_equal_approx(badge_height, boss.body_height() + SignMark.BADGE_HEIGHT) and is_equal_approx(SignMark.RING_RADIUS * 2.0, 2.5),
		"Rime-Lash (infused by its Star-Tide Link) swells the bow to %.1fx in its Sign's colour and stamps a 2.5 m Sign Ring with a badge 2.2 m over the boss" % dps_swell)
	var cross: CrossGrimoireHUD = dojo.huds[&"1_0"].cross_grimoire
	await _seconds(0.05)
	var no_pip: bool = not cross.detonate_prompt()
	tank.stats.resonance_charge = 1.0
	await _seconds(0.05)
	_check(no_pip and cross.detonate_prompt() and cross.diorama.detonate_ready,
		"with a pip in hand the tank's R diamond rings gold: detonate the sign")
	stops.clear()
	tank.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(0.6)
	var detonation_stop: bool = false
	for duration: float in stops:
		detonation_stop = detonation_stop or duration >= CombatDirector.HIT_STOP_DETONATION - 0.001
	_check(_synergies.back().begins_with(lash_seal.detonation_name) and director.sign_mark_on(boss) == null and detonation_stop
		and cross.verb_text().begins_with(lash_seal.detonation_name),
		"the tank's flourish detonates it: %s with a 180 ms freeze, the ring gone and the name over the cross" % lash_seal.detonation_name)
	director.hit_stop_applied.disconnect(stop_hook)

	# Back to the classic Level 10 kits for the checks that follow.
	BracedGuardComponent.enabled = false
	for actor: ActorBase in [tank, healer, dps]:
		await _until_idle(actor)
	progress.apply_full_endgame_kit_for_testing()
	for actor: ActorBase in [tank, healer, dps]:
		network.update_local_calling(actor.device_id, callings_before[actor.player_id])
		network.update_local_kit(actor.device_id, ClassLoadouts.starter_kit(actor.loadout.class_id).to_dict())
	await _seconds(0.1)
	progress.kits.assign(saved_kits)
	progress.callings.assign(saved_callings)
	progress.save()
	boss.set_physics_process(true)
	_reset_boss_poise()


# --- Phase 12: Sign-Flow, dioramas, Glimmer-Spots and the Scribery (14 GDD) -----

## Sign-Flow ("Coat, Break, Turn!"), the Action-Leaf + Place-Card dioramas, the
## 0-pip Hearth-Rite, threat-tiered Glimmer-Spots and Bravery Counters, the
## Squire's buffered counter, and the shared diamond widget in the HUD, the
## Grimoire Binder and the Scribery's counter. Played in the Cairnsman's ring.
func test_phase_12_sign_flow_and_grimoire_ux() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var progress: PartyProgress = PartyProgress.current
	var network: NetworkManager = NetworkManager.current
	var director: CombatDirector = CombatDirector.current
	var chimes_before: int = progress.chimes
	var collection_before: Dictionary = progress.collection.duplicate()
	SignFlowComponent.enabled = true
	GlimmerSpotComponent.enabled = true
	boss.set_physics_process(false)
	boss.engaged = true
	_reset_boss_poise()
	for actor: ActorBase in [tank, healer, dps]:
		await _until_idle(actor)
		actor.stats.heal(actor.stats.stats.max_health)

	# Schema: every Sign has all three manifestations; the four Place-Cards; old finish keys still read.
	var coverage: bool = true
	for scribe_sign: int in [Sign.SIGN_IRON_ROOT, Sign.SIGN_RIME_GALE, Sign.SIGN_WARM_HEARTH, Sign.SIGN_STAR_TIDE]:
		for mode: int in [Manifest.WEAPON_COAT, Manifest.WARD_MANTLE, Manifest.LANTERN_TETHER]:
			var found: bool = false
			for leaf: ScribeCardResource in catalog.action_leaves():
				found = found or (leaf.scribe_sign == scribe_sign and leaf.manifestation_mode == mode and leaf.card_kind == ScribeCardResource.CardKind.ACTION_LEAF)
			coverage = coverage and found
	var oaks: ScribeCardResource = catalog.card(ArsenalCatalog.ARIUNDLE_MOSS_OAKS)
	var gorge: ScribeCardResource = catalog.card(ArsenalCatalog.DOVERSLAP_GORGE)
	var mill: ScribeCardResource = catalog.card(ArsenalCatalog.BRAMBLEBRIDGE_MILL)
	var tor: ScribeCardResource = catalog.card(ArsenalCatalog.BARROW_CRAG_TOR)
	_check(coverage and catalog.place_cards().size() == 4 and oaks.card_kind == ScribeCardResource.CardKind.LOCATION_PLACE
		and oaks.scribe_sign == Sign.SIGN_IRON_ROOT and is_equal_approx(oaks.location_bonus_poise, 15.0)
		and gorge.scribe_sign == Sign.SIGN_RIME_GALE and is_equal_approx(gorge.location_bonus_reach_m, 0.8)
		and mill.scribe_sign == Sign.SIGN_WARM_HEARTH and is_equal_approx(mill.location_bonus_heal, 10.0)
		and tor.scribe_sign == Sign.SIGN_STAR_TIDE and is_equal_approx(tor.location_stamina_refund, 8.0) and oaks.chime_cost == 25
		and not oaks.is_lead() and not oaks.is_under() and catalog.under_cards().size() == 4,
		"every Sign has an Ink Blade, Ink Shield and Lantern-Tether Ink Card; the four Place-Cards carry their Signs and bonuses")
	var old_kit: Dictionary = {"armor": "ironwood_plate", "weapon": "light_sword", "leads": ["shield_charge", "shadow_sanctuary", "taunt", "bulwark_quake"],
		"variants": [1, 0, 0, 0], "unders": ["", "", "", ""]}
	var read_back: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(old_kit)
	_check(ScribeCardResource.variant_for_key("shiny_foil") == ScribeCardResource.CardVariant.GILDED_LEAF
		and ScribeCardResource.copy_variant(&"taunt:astral_prism") == ScribeCardResource.CardVariant.STAR_INKED_VELLUM
		and "|".join(ScribeCardResource.VARIANT_NAMES) == "Plain Ink|Gilded Leaf|Star-Ink"
		and ScribeCardResource.variant_for_key("Star-Inked Vellum") == ScribeCardResource.CardVariant.STAR_INKED_VELLUM
		and read_back.lead_variants[0] == 1 and read_back.guard_leaf_id == &"" and read_back.place_ids == [&"", &"", &""],
		"old saves still read: standard / shiny_foil / astral_prism (and the old finish names) are Plain Ink, Gilded Leaf and Star-Ink, and old kits get empty dioramas")

	# Diorama synergy: Iron-Root on Iron-Root ground is Home-Ground Harmony.
	var harmony: Dictionary = catalog.compute_diorama_synergy(ArsenalCatalog.RISING_DRIVE, ArsenalCatalog.ARIUNDLE_MOSS_OAKS)
	var stranger: Dictionary = catalog.compute_diorama_synergy(ArsenalCatalog.RISING_DRIVE, ArsenalCatalog.DOVERSLAP_GORGE)
	_check(harmony["is_home_ground_harmony"] and is_equal_approx(harmony["coat_duration_sec"], 10.0) and is_equal_approx(harmony["bonus_poise"], 15.0)
		and harmony["scribe_sign"] == Sign.SIGN_IRON_ROOT and not stranger["is_home_ground_harmony"] and is_equal_approx(stranger["coat_duration_sec"], 8.0)
		and is_equal_approx(stranger["bonus_reach_m"], 0.8),
		"Rising Drive framed by Moss-Oak-Hollow is Home-Ground Harmony: a 10.0 s coat (1.25x) and +15 poise; on the Gorge Bridge it's 8.0 s with +0.8 m reach")

	# The scaling formulas, at 60 frames a second.
	var worm: BossEncounterResource = catalog.encounter(ArsenalCatalog.SCREE_WORM)
	var bucca: BossEncounterResource = catalog.encounter(ArsenalCatalog.GALE_BUCCA)
	var hob: BossEncounterResource = catalog.encounter(ArsenalCatalog.OLD_HOB)
	_check(worm.encounter_level == 2 and worm.get_scaled_glimmer_frames(0) == BossEncounterResource.ALWAYS_OPEN_FRAMES
		and bucca.encounter_level == 10 and bucca.get_scaled_glimmer_frames(0) == 180 and bucca.get_scaled_glimmer_frames(5) == 120
		and bucca.get_scaled_glimmer_frames(9) == 120 and hob.encounter_level == 60 and hob.get_scaled_glimmer_frames(5) == 45
		and is_equal_approx(hob.get_impact_multiplier(), 5.0) and is_equal_approx(hob.bravery_counter_poise(), 525.0)
		and is_equal_approx(catalog.encounter(ArsenalCatalog.ROADSIDE_KIN).get_impact_multiplier(), 1.25 + 3.75 * pow(1.0 / 60.0, 1.6)),
		"windows: a Scree-Worm is always open; the Gale-Bucca (Lv 10) opens 180 frames, 120 by its fifth sighting; Old Hob (Lv 60) 45, with a 5.0x impact")

	# Give the tank a diorama: Taunt (Iron-Root, Ward-Mantle) in R framed by the Moss-Oaks, Shadow Sanctuary (Star-Tide) in L.
	progress.collection[ArsenalCatalog.ARIUNDLE_MOSS_OAKS] = 1
	var diorama_kit: EquipmentLoadoutResource = tank.loadout.kit.copy()
	diorama_kit.set_socket_place(Diorama.SKILL, ArsenalCatalog.ARIUNDLE_MOSS_OAKS, 0)
	diorama_kit.set_socket_leaf(Diorama.GUARD, ArsenalCatalog.SHADOW_SANCTUARY, 0)
	network.update_local_kit(tank.device_id, diorama_kit.to_dict())
	await _seconds(0.05)
	var flow: SignFlowComponent = tank.sign_flow
	var hud: PlayerHUD = dojo.huds[tank.player_id]
	_check(tank.loadout.kit.place_ids[Diorama.SKILL] == ArsenalCatalog.ARIUNDLE_MOSS_OAKS and tank.loadout.kit.guard_leaf_id == ArsenalCatalog.SHADOW_SANCTUARY
		and flow.socket_synergy(Diorama.SKILL)["is_home_ground_harmony"] and hud.cross_grimoire.diorama.socket_view(Diorama.SKILL)["place"] == ArsenalCatalog.ARIUNDLE_MOSS_OAKS,
		"the tank's R diamond frames Taunt (Iron-Root) with Moss-Oak-Hollow, shown on the HUD's diamonds; L holds Shadow Sanctuary")

	# 0-pip Hearth-Rite Tuck: hold R out of combat for 120 frames.
	var issued: Array[int] = []
	var issued_hook: Callable = func(command: int) -> void: issued.append(command)
	tank.input.command_issued.connect(issued_hook)
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(10.0, 0.0, 10.0)))
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 26.0)))
	tank.input.inject_move(Vector2.ZERO)
	await _seconds(0.1)
	tank.stats.resonance_charge = 0.4
	# The hold starts in this physics step: after 89 more steps it has been held 89 frames, after 90 it's done.
	tank.input.inject_hold(InputComponent.ACTION_TRIGGER_R, true)
	for frame: int in SignFlowComponent.HEARTH_RITE_HOLD_FRAMES - 1:
		await physics_frame
	var early: bool = flow.has_hearth_rite_tuck
	var holding: float = tank.input.hearth_rite_progress()
	await physics_frame
	_check(not flow.is_in_combat and not early and holding > 0.95 and flow.has_hearth_rite_tuck and flow.opening_strike_empowered
		and is_equal_approx(tank.stats.resonance_charge, 1.0) and not issued.has(Cmd.TRIGGER_R_SKILL),
		"out of combat, holding R for 120 frames is the Hearth-Rite Tuck: it costs no pip, tops the tank up to 1.0 and empowers the opening strike")
	_check(is_equal_approx(tank.visuals.weapon_scale(), SignFlowComponent.TRAIL_COAT_SCALE) and flow.active_trail_coat_sign == Sign.SIGN_IRON_ROOT
		and flow.active_location_card_id == ArsenalCatalog.ARIUNDLE_MOSS_OAKS and tank.visuals.sign_coat_look() == SignFlowComponent.CoatLook.TRAIL_TUCK,
		"the falchion glows at %.2fx in the Moss-Oaks' tint, carrying Iron-Root into the next fight" % tank.visuals.weapon_scale())
	tank.input.inject_hold(InputComponent.ACTION_TRIGGER_R, false)
	await _seconds(0.1)
	tank.input.inject_hold(InputComponent.ACTION_TRIGGER_R, true)
	await _seconds(0.3)
	tank.input.inject_hold(InputComponent.ACTION_TRIGGER_R, false)
	await _seconds(0.1)
	_check(issued.count(Cmd.TRIGGER_R_SKILL) == 1, "a short press of R out of combat still fires R, on letting go")
	tank.stats.resonance_charge = 2.0
	flow.begin_hearth_rite(Diorama.SKILL)
	var astral_kit: EquipmentLoadoutResource = tank.loadout.kit.copy()
	astral_kit.lead_variants[ScribeCardResource.GrimoireSlot.SIGNATURE] = ScribeCardResource.CardVariant.STAR_INKED_VELLUM
	var astral_frames: int = 0
	var real_kit: EquipmentLoadoutResource = tank.loadout.kit
	tank.loadout.kit = astral_kit
	astral_frames = flow.hearth_rite_hold_frames(Diorama.SKILL)
	tank.loadout.kit = real_kit
	_check(is_equal_approx(tank.stats.resonance_charge, 2.0) and astral_frames == SignFlowComponent.STAR_INKED_HOLD_FRAMES,
		"with 2 pips the rite keeps both (it never costs one), and a Star-Inked Vellum leaf needs only 60 frames")

	# The opening strike in the fight discharges the blessing: Iron-Root, its seal, and the Moss-Oaks' poise.
	# (The healer holds the DPS on the Soul Tether, not the tank: a tethered ally gets The Lantern's Promise's longer window.)
	healer.tether.bind_actor(dps)
	var resolved: Array[CombatEvent] = []
	var resolved_hook: Callable = func(event: CombatEvent, _outcome: int) -> void: resolved.append(event)
	director.hit_resolved.connect(resolved_hook)
	var stops: Array[float] = []
	var stop_hook: Callable = func(duration: float) -> void: stops.append(duration)
	director.hit_stop_applied.connect(stop_hook)
	await _until_idle(tank)
	_face_boss(tank, Vector3(0.0, 0.0, 2.6))
	tank.input.inject_move(Vector2.ZERO)
	await _seconds(0.1)
	var in_fight: bool = flow.is_in_combat and absf(flow.trail_coat_timer - (SignFlowComponent.TRAIL_COAT_COMBAT_GRACE - 0.1)) < 0.05
	tank.stats.resonance_charge = 1.0
	resolved.clear()
	tank.input.inject_command(Cmd.LIGHT)
	var waited: float = 0.0
	while flow.flow_window_left <= 0.0 and waited < 1.0:
		await physics_frame
		waited += 1.0 / 60.0
	var opening: CombatEvent = resolved.back() if not resolved.is_empty() else null
	_check(in_fight and opening != null and opening.coat_sign == Sign.SIGN_IRON_ROOT and is_equal_approx(opening.coat_poise, 15.0)
		and opening.primer == Sign.SIGN_IRON_ROOT and director.primer_on(boss) == Sign.SIGN_IRON_ROOT and not flow.has_hearth_rite_tuck,
		"in the fight the opening Light discharges it: Iron-Root's seal on the Cairnsman and the Moss-Oaks' +15 poise, and the glow is spent")

	# In-combat Sign-Flow: R tapped in the Flow-Link Window casts at once and coats the hero.
	_check(flow.flow_window_left > 0.0 and flow.flow_window_frames() == SignFlowComponent.FLOW_WINDOW_FRAMES,
		"landing the Light opens a 14-frame Flow-Link Window")
	# Lambdas copy plain locals, so the frames go in a dictionary.
	var r_frames: Dictionary = {"started": -1, "active": -1}
	var start_hook: Callable = func(action: CombatActionResource, _flowed: bool) -> void:
		if action.command == Cmd.TRIGGER_R_SKILL:
			r_frames["started"] = Engine.get_physics_frames()
	var phase_hook: Callable = func(phase: ActionQueueComponent.Phase) -> void:
		if phase == ActionQueueComponent.Phase.ACTIVE and tank.action_queue.current_action != null \
				and tank.action_queue.current_action.command == Cmd.TRIGGER_R_SKILL and int(r_frames["active"]) < 0:
			r_frames["active"] = Engine.get_physics_frames()
	tank.action_queue.action_started.connect(start_hook)
	tank.action_queue.phase_changed.connect(phase_hook)
	var cones_before: int = _count_zones(SanctuaryZone.Shape.CONE)
	var casts_before: int = flow.sign_flow_casts()
	stops.clear()
	tank.input.inject_command(Cmd.TRIGGER_R_SKILL)
	var biggest: float = 1.0
	for frame: int in 40:
		await physics_frame
		biggest = maxf(biggest, tank.visuals.weapon_scale())
	var ring: bool = false
	for child: Node in dojo.effects_root.get_children():
		ring = ring or String(child.name).begins_with("SignFlowRing")
	var freeze: bool = false
	for duration: float in stops:
		freeze = freeze or is_equal_approx(duration, SignFlowComponent.SIGN_FLOW_HIT_STOP)
	var r_lag: int = int(r_frames["active"]) - int(r_frames["started"])
	_check(flow.sign_flow_casts() == casts_before + 1 and int(r_frames["started"]) >= 0 and int(r_frames["active"]) >= 0 and r_lag <= 1,
		"R tapped in the window casts Taunt with no wind-up (active %d frame after it starts)" % r_lag)
	_check(biggest >= SignFlowComponent.SIGN_FLOW_SCALE - 0.05 and freeze and ring and flow.coat_sign == Sign.SIGN_IRON_ROOT
		and flow.coat_mode == Manifest.WARD_MANTLE and flow.coat_time_left > 9.0 and _count_zones(SanctuaryZone.Shape.CONE) == cones_before + 1,
		"the cast flares the falchion to %.1fx, freezes the foe 110 ms, stamps a 2.5 m Sign ring, and Taunt's Ward-Mantle coats the tank for 10 s with a shelter cone" % biggest)
	tank.action_queue.action_started.disconnect(start_hook)
	tank.action_queue.phase_changed.disconnect(phase_hook)
	await _until_idle(tank)
	resolved.clear()
	tank.input.inject_command(Cmd.LIGHT)
	await _seconds(0.4)
	var coated: CombatEvent = resolved.back() if not resolved.is_empty() else null
	_check(coated != null and coated.coat_sign == Sign.SIGN_IRON_ROOT and is_equal_approx(coated.coat_poise, 15.0),
		"while coated even a plain Light carries Iron-Root and the Moss-Oaks' poise")
	# L tapped in the window: a Counter-Brace from the L diamond.
	await _until_idle(tank)
	tank.stats.resonance_charge = 1.5
	tank.input.inject_command(Cmd.LIGHT)
	waited = 0.0
	while flow.flow_window_left <= 0.0 and waited < 1.0:
		await physics_frame
		waited += 1.0 / 60.0
	var braces: int = flow.sign_flow_casts()
	var pips_before_brace: float = tank.stats.resonance_charge
	tank.input.inject_guard(true)
	await _seconds(0.1)
	tank.input.inject_guard(false)
	_check(flow.sign_flow_casts() == braces + 1 and flow.coat_sign == Sign.SIGN_STAR_TIDE and pips_before_brace - tank.stats.resonance_charge > 0.9,
		"L tapped in the window is a 1-pip Counter-Brace: Shadow Sanctuary's Star-Tide coats the tank")
	# A coat framed by the Gorge Bridge reaches 0.8 m further.
	await _until_idle(tank)
	flow.coat_synergy = catalog.compute_diorama_synergy(ArsenalCatalog.RISING_DRIVE, ArsenalCatalog.DOVERSLAP_GORGE)
	var light: CombatActionResource = tank.loadout.opener_for(Cmd.LIGHT)
	tank.hitbox.activate(light)
	var gorge_reach: float = -tank.hitbox.position.z
	tank.hitbox.deactivate()
	flow.coat_time_left = 0.01
	_check(is_equal_approx(gorge_reach, light.reach + 0.8), "a coat framed by Dover-Slap-Bridge reaches 0.8 m further (Gorge-Draft)")
	# The window's length: 18 frames near a Lantern-Bearer, 9 alone in Dread-Chill.
	healer.place_at(Transform3D(Basis.IDENTITY, tank.global_position + Vector3(2.0, 0.0, 0.0)))
	var promise: int = flow.flow_window_frames()
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(10.0, 0.0, 10.0)))
	healer.stats.is_downed = true
	dps.stats.is_downed = true
	var dread: int = flow.flow_window_frames()
	healer.stats.is_downed = false
	dps.stats.is_downed = false
	_check(promise == SignFlowComponent.LANTERNS_PROMISE_WINDOW_FRAMES and dread == SignFlowComponent.DREAD_CHILL_WINDOW_FRAMES,
		"the window is 18 frames within 5.5 m of a Lantern-Bearer (The Lantern's Promise) and 9 alone (Dread-Chill)")

	# Tier 1 kin: any Iron-Root strike cracks them for 1.25x poise, with no text.
	var minion: WoodlandMinion = dojo.camps[0].minions[0] if not dojo.camps.is_empty() and not dojo.camps[0].minions.is_empty() else null
	await _until_idle(tank)
	_reset_boss_poise()
	var glimmer: GlimmerSpotComponent = boss.glimmer
	glimmer.encounter = worm
	resolved.clear()
	var iron: CombatEvent = _strike(dps, boss, 5.0, 20.0)
	iron.scribe_sign = Sign.SIGN_IRON_ROOT
	director.deliver(iron)
	var star: CombatEvent = _strike(dps, boss, 5.0, 20.0)
	star.scribe_sign = Sign.SIGN_STAR_TIDE
	director.deliver(star)
	_check(minion != null and minion.glimmer != null and minion.glimmer.encounter.encounter_id == ArsenalCatalog.ROADSIDE_KIN and glimmer.is_open()
		and resolved.size() == 2 and is_equal_approx(resolved[0].poise_damage, 25.0) and is_equal_approx(resolved[1].poise_damage, 20.0)
		and hud.rhyme_text() == "",
		"a Tier 1 Scree-Worm (Lv 2) is always open: an Iron-Root strike's 20 poise lands as 25 (1.25x), Star-Tide's as 20, and no rhyme shows")

	# Tier 3: the Gale-Bucca (Lv 10) opens 180 frames, tightens with each sighting, and hides its rhyme from the third.
	_reset_boss_poise()
	glimmer.encounter = bucca
	progress.pattern_seen.erase(ArsenalCatalog.GALE_BUCCA)
	var first_frames: int = glimmer.open_window()
	await physics_frame
	var first_rhyme: String = hud.rhyme_text()
	var first_left: float = glimmer.time_left()
	resolved.clear()
	var countered: Array[String] = []
	var counter_hook: Callable = func(_target: ActorBase, _sign: int, label: String) -> void: countered.append(label)
	director.bravery_countered.connect(counter_hook)
	var tide: CombatEvent = _strike(dps, boss, 5.0, 10.0)
	tide.scribe_sign = Sign.SIGN_STAR_TIDE
	director.deliver(tide)
	var saved: ConfigFile = ConfigFile.new()
	saved.load(TEST_SAVE_PATH)
	var saved_seen: int = int((saved.get_value("glimmer", "seen", {}) as Dictionary).get("gale_bucca", 0))
	_check(first_frames == 180 and absf(first_left - 3.0) < 0.05 and first_rhyme == bucca.hud_rhyme_couplet and progress.pattern_seen_count(ArsenalCatalog.GALE_BUCCA) == 1
		and saved_seen == 1, "the Gale-Bucca's first wing-spread opens a 180-frame (3.0 s) Star-Tide Glimmer-Spot, the rhyme on the HUD, the sighting saved")
	_check(not countered.is_empty() and countered.back().begins_with("PARRY & STRIKE") and countered.back().contains("ASTRAL CHORUS") and not glimmer.is_open()
		and not resolved.is_empty() and is_equal_approx(resolved.back().poise_damage, 105.0 * bucca.get_impact_multiplier()),
		"a Star-Tide strike in it is a Parry & Strike: (60 + 45) x %.2f = %.0f poise, Astral Chorus, and the spot shuts" % [bucca.get_impact_multiplier(),
			resolved.back().poise_damage if not resolved.is_empty() else 0.0])
	var tightening: Array[int] = [first_frames]
	var rhymes: Array[String] = [first_rhyme]
	for sighting: int in 2:
		tightening.append(glimmer.open_window())
		await physics_frame
		rhymes.append(hud.rhyme_text())
		glimmer.close()
	progress.pattern_seen[ArsenalCatalog.GALE_BUCCA] = 5
	var fifth: int = glimmer.open_window()
	_check(tightening == [180, 168, 156] and rhymes[1] != "" and rhymes[2] == "" and fifth == 120,
		"each sighting tightens it by 12 frames (180, 168, 156), the rhyme goes quiet from the third, and from the fifth it holds at 120 (2.0 s)")
	resolved.clear()
	var wrong: CombatEvent = _strike(dps, boss, 5.0, 10.0)
	wrong.scribe_sign = Sign.SIGN_RIME_GALE
	director.deliver(wrong)
	_check(glimmer.is_open() and is_equal_approx(resolved.back().poise_damage, 10.0), "a Sign that doesn't counter it (Rime-Gale) is just a hit")
	glimmer.close()
	# Lv 60: 45 frames and a 5.0x impact.
	_reset_boss_poise()
	glimmer.encounter = hob
	progress.pattern_seen[ArsenalCatalog.OLD_HOB] = 5
	var hob_frames: int = glimmer.open_window()
	resolved.clear()
	var root_strike: CombatEvent = _strike(tank, boss, 5.0, 10.0)
	root_strike.scribe_sign = Sign.SIGN_IRON_ROOT
	director.deliver(root_strike)
	_check(hob_frames == 45 and not resolved.is_empty() and is_equal_approx(resolved.back().poise_damage, 525.0),
		"Old Hob (Lv 60), seen five times, opens only 45 frames (0.75 s), and an Iron-Root Bravery Counter lands 105 x 5.0 = 525 poise")
	await _seconds(0.1)

	# The Cairnsman's own roar opens his spot (Tier 3, Lv 5, Iron-Root or Star-Tide).
	_reset_boss_poise()
	glimmer.encounter = catalog.encounter(ArsenalCatalog.CAIRNSMAN)
	glimmer.close()
	progress.pattern_seen.erase(ArsenalCatalog.CAIRNSMAN)
	boss._cast_timer = 0.05
	boss.set_physics_process(true)
	waited = 0.0
	while not glimmer.is_open() and waited < 2.0:
		await physics_frame
		waited += 1.0 / 60.0
	boss.set_physics_process(false)
	_check(glimmer.is_open() and absf(glimmer.time_left() - 3.0) < 0.1 and progress.pattern_seen_count(ArsenalCatalog.CAIRNSMAN) == 1
		and hud.rhyme_text().contains("Iron-Root"), "the Cairnsman roars into his cast and his amber core opens for 180 frames, with his rhyme on the HUD")
	glimmer.close()

	# Squire Gambit: a press up to 90 frames before the roar is buffered and fires on its first frame.
	await _until_idle(dps)
	var dps_mode: InputComponent.AssistMode = dps.input.assist_mode
	dps.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
	dps.apply_assist_mode()
	_face_boss(dps, Vector3(-1.5, 0.0, 3.5))
	dps.stats.resonance_charge = 2.0
	var dps_commands: Array[int] = []
	var dps_hook: Callable = func(command: int) -> void: dps_commands.append(command)
	dps.input.command_issued.connect(dps_hook)
	director.expect_glimmer(boss, 1.0)
	var accepting: bool = boss.glimmer.accepts_buffer()
	dps.input._issue_attack(Cmd.LIGHT)
	var buffered: bool = glimmer.is_buffered(dps.player_id) and dps_commands.is_empty()
	await _seconds(0.5)
	countered.clear()
	glimmer.open_window()
	var fired_at_once: bool = dps_commands.has(Cmd.TRIGGER_R_SKILL)
	await _seconds(0.8)
	_check(accepting and buffered and fired_at_once and not countered.is_empty(),
		"a Squire's press 1.0 s before the roar is buffered; their Gale Rush (Star-Tide) fires on the opening's first frame and lands a Bravery Counter")
	dps.input.command_issued.disconnect(dps_hook)
	dps.input.assist_mode = dps_mode
	dps.apply_assist_mode()
	director.bravery_countered.disconnect(counter_hook)

	# The Scribery's counter (opened here from the HUD) and the shared diamonds.
	await _until_idle(tank)
	hud.open_scribery_shop()
	var shop: ScriberyShopPanel = hud.scribery_panel()
	progress.chimes = 200
	progress.save()
	shop.select_tab(ScriberyShopPanel.Tab.CHART)
	shop.widget.selected_socket = Diorama.ULT
	shop.select_option(ArsenalCatalog.BARROW_CRAG_TOR)
	await physics_frame
	await physics_frame
	var previewing: bool = tank.visuals.sign_coat_look() == SignFlowComponent.CoatLook.TRAIL_TUCK and tank.visuals.weapon_scale() > 1.3
	var charted: bool = shop.buy()
	await _seconds(0.1)
	saved.load(TEST_SAVE_PATH)
	var hud_widget: CrossGrimoireDiamondWidget = hud.cross_grimoire.diorama
	_check(shop.widget.display_scale == CrossGrimoireDiamondWidget.BINDER_SCALE and shop.widget.interactive
		and hud_widget.display_scale == CrossGrimoireDiamondWidget.HUD_SCALE and not hud_widget.interactive and previewing,
		"the Scribery shows the HUD's own CrossGrimoireDiamondWidget at 2.2x (interactive; the HUD's is 1.0x), and a highlighted card coats the puppet as a preview")
	_check(charted and progress.chimes == 175 and progress.owns_card(ArsenalCatalog.BARROW_CRAG_TOR)
		and int((saved.get_value("cards", "collection", {}) as Dictionary).get("loc_barrow_crag_tor", 0)) == 1 and int(saved.get_value("party", "chimes", 0)) == 175
		and tank.loadout.kit.place_ids[Diorama.ULT] == ArsenalCatalog.BARROW_CRAG_TOR
		and shop.widget.socket_view(Diorama.ULT)["place"] == ArsenalCatalog.BARROW_CRAG_TOR and hud_widget.socket_view(Diorama.ULT)["place"] == ArsenalCatalog.BARROW_CRAG_TOR,
		"charting the Barrow-Crag-Crossing takes 25 Chimes, saves it, and frames L+R in both the shop's diamonds and the HUD's")
	shop.select_tab(ScriberyShopPanel.Tab.GILD)
	var on_press: bool = shop.select_option(ArsenalCatalog.TAUNT)
	var gilded: bool = shop.buy()
	await _seconds(0.1)
	saved.load(TEST_SAVE_PATH)
	_check(on_press and gilded and progress.chimes == 125 and progress.owns_card(ArsenalCatalog.TAUNT, ScribeCardResource.CardVariant.GILDED_LEAF)
		and int((saved.get_value("cards", "collection", {}) as Dictionary).get("taunt:shiny_foil", 0)) == 1
		and tank.loadout.kit.lead_variants[ScribeCardResource.GrimoireSlot.SIGNATURE] == ScribeCardResource.CardVariant.GILDED_LEAF
		and shop.widget.kit.socket_leaf_variant(Diorama.SKILL) == ScribeCardResource.CardVariant.GILDED_LEAF
		and hud_widget.socket_view(Diorama.SKILL)["leaf_variant"] == ScribeCardResource.CardVariant.GILDED_LEAF
		and shop.widget.socket_view(Diorama.SKILL)["leaf_variant"] == ScribeCardResource.CardVariant.STAR_INKED_VELLUM
		and PartyProgress.gilding_cost(&"taunt:shiny_foil") == 120,
		"the Gilding Press turns the worn Taunt from Plain Ink to Gilded Leaf for 50 Chimes: saved, worn, gold-trimmed on the HUD, and the press now previews Star-Ink (120)")
	shop.close()
	await _seconds(0.05)
	_check(hud.scribery_panel() == null and not tank.input.menu_open, "closing the counter hands the controller back")

	# The Grimoire Binder: not mid-fight; out of it, the same diamonds at 2.2x between the two pages.
	var refused: bool = not hud.open_binder()
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 26.0)))
	await _seconds(0.1)
	hud.toggle_binder()
	var binder: GrimoireBinderPanel = hud.binder_panel()
	_check(refused and binder != null and binder.widget is CrossGrimoireDiamondWidget and binder.widget.display_scale == CrossGrimoireDiamondWidget.BINDER_SCALE
		and binder.widget.interactive, "the Grimoire Binder won't open mid-fight; out of it, it grows the same diamonds to 2.2x")
	binder.widget.selected_socket = Diorama.GUARD
	var placed: bool = binder.slot_place(ArsenalCatalog.BARROW_CRAG_TOR)
	await _seconds(0.05)
	var guard_view: Dictionary = binder.widget.socket_view(Diorama.GUARD)
	_check(placed and binder.place_options().has(ArsenalCatalog.BARROW_CRAG_TOR) and binder.leaf_options().has(ArsenalCatalog.SHADOW_SANCTUARY)
		and guard_view["place"] == ArsenalCatalog.BARROW_CRAG_TOR and guard_view["synergy"]["is_home_ground_harmony"]
		and hud_widget.socket_view(Diorama.GUARD)["synergy"]["is_home_ground_harmony"] and GrimoireBinderPanel._folio_text().begins_with("INK CARD COLLECTION"),
		"from the Place-Cards page the Star-Tor frames L behind Shadow Sanctuary: Star-Tide on Star-Tide, Home-Ground Harmony in the Binder and on the HUD")
	hud.toggle_binder()
	await _seconds(0.05)
	_check(hud.binder_panel() == null and not tank.input.menu_open, "toggling again closes the Binder")

	# Back as we were, Sign-Flow and Glimmer-Spots off again for the checks that follow.
	tank.input.command_issued.disconnect(issued_hook)
	director.hit_resolved.disconnect(resolved_hook)
	director.hit_stop_applied.disconnect(stop_hook)
	SignFlowComponent.enabled = false
	GlimmerSpotComponent.enabled = false
	glimmer.encounter = catalog.encounter(ArsenalCatalog.CAIRNSMAN)
	glimmer.close()
	progress.pattern_seen.clear()
	progress.chimes = chimes_before
	progress.collection.assign(collection_before)
	for actor: ActorBase in [tank, healer, dps]:
		await _until_idle(actor)
		network.update_local_kit(actor.device_id, ClassLoadouts.starter_kit(actor.loadout.class_id).to_dict())
		actor.stats.heal(actor.stats.stats.max_health)
	progress.save()
	await _seconds(0.1)
	_stage_party()
	_reset_boss_poise()
	boss.set_physics_process(true)


## The Phase 12 Kaizen pass (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §8), in the
## Ring with the trinity: directional combo forms (the Sundering Gap-Leap and
## the Wayfarer's Vault-Strike, with the HUD's pips), the Overhead Pocket
## Blessing and the Offhand Pocket-Draw with its camera pulse, the One-and-Done,
## the Tank's Ward-Mantle against an Iron-Root swipe, the Support's Aegis Ward
## and Ink-Share against a Furrow Iron-Man's rust, Miyamoto armour-drops and
## locks (Tier 1 and 2), a practice Cairnsman through all four gates, the
## window and impact maths, Gilding potency, and the shared Grimoire widget
## across the HUD, the Binder and the Scribery.
func test_phase_12_miyamoto_posture_trinity_and_grimoire_ux() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var progress: PartyProgress = PartyProgress.current
	var network: NetworkManager = NetworkManager.current
	var director: CombatDirector = CombatDirector.current
	var chimes_before: int = progress.chimes
	var collection_before: Dictionary = progress.collection.duplicate()
	SignFlowComponent.enabled = true
	GlimmerSpotComponent.enabled = true
	ComboChainComponent.enabled = true
	PostureEscalationComponent.enabled = true
	BossGateComponent.enabled = true
	# The real Cairnsman stands still and keeps his gates shut: a practice Cairnsman plays them below.
	boss.set_physics_process(false)
	boss.gates.set_physics_process(false)
	boss.engaged = true
	_reset_boss_poise()
	for actor: ActorBase in [tank, healer, dps]:
		await _until_idle(actor)
		actor.stats.heal(actor.stats.stats.max_health)
		actor.stats.restore_stamina(actor.stats.stats.max_stamina)
		actor.sign_flow.ward_blessing_left = 0.0
		actor.sign_flow.aegis_ward = false
		actor.combo.reset()
	var resolved: Array[CombatEvent] = []
	var resolved_hook: Callable = func(event: CombatEvent, _outcome: int) -> void: resolved.append(event)
	director.hit_resolved.connect(resolved_hook)
	var stops: Array[float] = []
	var stop_hook: Callable = func(duration: float) -> void: stops.append(duration)
	director.hit_stop_applied.connect(stop_hook)

	# --- Schema: five combo forms, every Sign in every role, the Miyamoto tiers ---
	var forms: Array[ComboChainResource] = catalog.combos()
	var leap: ComboChainResource = catalog.combo(ArsenalCatalog.COMBO_SUNDERING_GAP_LEAP)
	var vault: ComboChainResource = catalog.combo(ArsenalCatalog.COMBO_WAYFARER_VAULT_STRIKE)
	var sweep: ComboChainResource = catalog.combo(ArsenalCatalog.COMBO_WHIRLING_FLANK_SWEEP)
	var grand: ComboChainResource = catalog.combo(ArsenalCatalog.COMBO_GRAND_SIGN_FLOW)
	_check(forms.size() == 5 and catalog.get_unlocked_combos_for_level(1).size() == 1 and catalog.get_unlocked_combos_for_level(2).size() == 2
		and catalog.get_unlocked_combos_for_level(8).size() == 5 and leap.input_sequence == [&"LIGHT", &"LIGHT", &"FORWARD_HEAVY"]
		and is_equal_approx(leap.step_displacement_m, 2.8) and is_equal_approx(leap.stun_duration_sec, 1.2) and leap.breaks_martial_lock
		and vault.evasion_iframes_ms == 200 and is_equal_approx(vault.step_displacement_m, -2.6) and sweep.triggers_flank_orbit
		and is_equal_approx(sweep.finisher_poise_damage, 20.0) and sweep.input_sequence == [&"HEAVY", &"SIDE_HEAVY"]
		and is_equal_approx(grand.detonation_radius_mult, 1.25) and grand.required_level == 8,
		"five combo forms are registered by id, taught at Lv 1, 2, 4, 6 and 8: the Gap-Leap (+2.8 m, 1.2 s stun, cracks martial locks), the Vault-Strike (-2.6 m, 200 ms i-frames), the Flank-Sweep (+20 poise) and the Grand Sign-Flow (+25% detonation)")
	var roles: bool = true
	for scribe_sign: int in [Sign.SIGN_IRON_ROOT, Sign.SIGN_RIME_GALE, Sign.SIGN_WARM_HEARTH, Sign.SIGN_STAR_TIDE]:
		for delivery: int in [ScribeCardResource.RoleDelivery.DPS_WEAPON_COAT, ScribeCardResource.RoleDelivery.TANK_WARD_MANTLE,
				ScribeCardResource.RoleDelivery.SUPPORT_INK_SHARE]:
			var found: bool = false
			for leaf: ScribeCardResource in catalog.action_leaves():
				found = found or (leaf.scribe_sign == scribe_sign and leaf.role_delivery == delivery
					and (delivery != ScribeCardResource.RoleDelivery.TANK_WARD_MANTLE or leaf.grants_stun_immunity)
					and (delivery != ScribeCardResource.RoleDelivery.SUPPORT_INK_SHARE or (leaf.shares_ink_to_party and leaf.grants_stun_immunity)))
			roles = roles and found
	var heal_leaf: ScribeCardResource = catalog.card(ArsenalCatalog.HOMING_HEAL)
	_check(roles and heal_leaf.shares_ink() and is_equal_approx(heal_leaf.ward_damage_mitigation_pct, 0.8) and is_equal_approx(heal_leaf.ward_reflected_poise, 60.0)
		and is_equal_approx(heal_leaf.one_and_done_finisher_mult, 3.2) and catalog.card(ArsenalCatalog.TAUNT).role_delivery == ScribeCardResource.RoleDelivery.TANK_WARD_MANTLE,
		"every Sign has a DPS Ink Blade, a stun-immune Tank Ink Shield and a Support Ink-Share card; leaves carry the 80% ward, 60 reflected poise and 3.2x One-and-Done")
	var worm: BossEncounterResource = catalog.encounter(ArsenalCatalog.SCREE_WORM)
	var iron_kin: BossEncounterResource = catalog.encounter(ArsenalCatalog.IRON_MAN_KIN)
	var drake_kin: BossEncounterResource = catalog.encounter(ArsenalCatalog.CRAG_BACK_DRAKE)
	var cairnsman: BossEncounterResource = catalog.encounter(ArsenalCatalog.CAIRNSMAN)
	var bucca: BossEncounterResource = catalog.encounter(ArsenalCatalog.GALE_BUCCA)
	var hob: BossEncounterResource = catalog.encounter(ArsenalCatalog.OLD_HOB)
	_check(worm.miyamoto_tier == BossEncounterResource.MiyamotoTier.TIER_0_PUNCHING_BAG and worm.get_scaled_glimmer_frames(0) == 999999
		and iron_kin.miyamoto_tier == BossEncounterResource.MiyamotoTier.TIER_1_SINGLE_EVADE and iron_kin.primary_lock_type == BossEncounterResource.LockKeyType.ELEMENTAL_INK_KEY
		and drake_kin.miyamoto_tier == BossEncounterResource.MiyamotoTier.TIER_2_MULTI_LOCK and drake_kin.lock_thresholds().size() == 3
		and cairnsman.miyamoto_tier == BossEncounterResource.MiyamotoTier.TIER_3_FOUR_GATE_BOSS and cairnsman.gate_thresholds == [0.75, 0.5, 0.25]
		and Bestiary.variant(&"soot_paw_cutthroat").encounter_id == ArsenalCatalog.IRON_MAN_KIN and is_equal_approx(iron_kin.uninked_physical_mult, 0.5),
		"Miyamoto tiers: a Scree-Worm is a Tier 0 punching bag (always open), the Iron-Men lock at Tier 1 (a rust ink lock), the Crag-Back at every gate (Tier 2), the Cairnsman has four gates")
	_check(bucca.get_scaled_glimmer_frames(0) == 180 and absf(bucca.get_scaled_glimmer_seconds(0) - 3.0) < 0.001
		and hob.get_scaled_glimmer_frames(5) == 45 and absf(hob.get_scaled_glimmer_seconds(5) - 0.75) < 0.001
		and is_equal_approx(hob.get_impact_multiplier(), 5.0) and is_equal_approx(hob.bravery_counter_poise(), 525.0),
		"window scaling: 180 frames (3.0 s) at Lv 10 unseen, 45 frames (0.75 s) at Lv 60 seen five times, with a 5.0x impact (525 poise)")

	# --- 1. Directional combos, played on the controller ---
	_check(progress.trail_level() >= grand.required_level, "the party's trail Lv %d knows every combo form" % progress.trail_level())
	var pips_seen: Array[Vector2i] = []
	var names_seen: Array[String] = []
	var pip_hook: Callable = func(step: int, steps: int, combo_name: String) -> void:
		pips_seen.append(Vector2i(step, steps))
		names_seen.append(combo_name)
	dps.combo.combo_step_advanced.connect(pip_hook)
	var hud: PlayerHUD = dojo.huds[dps.player_id]
	var hud_widget: CrossGrimoireDiamondWidget = hud.cross_grimoire.diorama
	# 12 m out, facing the boss, so the finisher's step runs straight and lands nowhere.
	_face_boss(dps, Vector3(0.0, 0.0, 12.0))
	dps.input.inject_move(Vector2.ZERO)
	await _seconds(0.1)
	var step_log: Dictionary = {"from": Vector3.ZERO, "to": Vector3.ZERO, "facing": Vector3.ZERO, "iframes": 0.0}
	var step_start: Callable = func(action: CombatActionResource, _flowed: bool) -> void:
		if action.command == Cmd.FORWARD_HEAVY or action.command == Cmd.BACK_HEAVY:
			step_log["from"] = dps.global_position
			step_log["facing"] = dps.facing_vector()
			step_log["iframes"] = dps.stats._invulnerable_left
	var step_end: Callable = func(phase: ActionQueueComponent.Phase) -> void:
		var current: CombatActionResource = dps.action_queue.current_action
		if phase == ActionQueueComponent.Phase.RECOVERY and current != null \
				and (current.command == Cmd.FORWARD_HEAVY or current.command == Cmd.BACK_HEAVY):
			step_log["to"] = dps.global_position
	dps.action_queue.action_started.connect(step_start)
	dps.action_queue.phase_changed.connect(step_end)
	await _play(dps, Cmd.LIGHT)
	var after_one: Vector2i = hud_widget.combo_pips()
	await _play(dps, Cmd.LIGHT)
	var after_two: Vector2i = hud_widget.combo_pips()
	var finishers_before: int = dps.combo.finishers_played()
	await _play(dps, Cmd.FORWARD_HEAVY)
	var leap_step: Vector3 = (step_log["to"] as Vector3) - (step_log["from"] as Vector3)
	leap_step.y = 0.0
	_check(after_one == Vector2i(1, 3) and after_two == Vector2i(2, 3) and pips_seen.has(Vector2i(3, 3)) and names_seen.has(leap.display_name)
		and dps.combo.finishers_played() == finishers_before + 1,
		"Light, Light, Forward+Heavy: the HUD's weapon diamond lights o - o - > (1/3, 2/3) and the Sundering Gap-Leap finishes")
	_check(absf(leap_step.length() - 2.8) < 0.25 and leap_step.normalized().dot(step_log["facing"]) > 0.9,
		"the Gap-Leap's finisher lunges %.2f m forward (2.8)" % leap_step.length())
	await _seconds(1.2)
	await _play(dps, Cmd.LIGHT)
	await _play(dps, Cmd.LIGHT)
	await _play(dps, Cmd.BACK_HEAVY)
	var vault_step: Vector3 = (step_log["to"] as Vector3) - (step_log["from"] as Vector3)
	vault_step.y = 0.0
	_check(absf(vault_step.length() - 2.6) < 0.25 and vault_step.normalized().dot(step_log["facing"]) < -0.9
		and float(step_log["iframes"]) >= 0.19 and names_seen.has(vault.display_name),
		"Light, Light, Back+Heavy is the Wayfarer's Vault-Strike: %.2f m back (2.6) with %.0f ms of evasion frames" % [vault_step.length(),
			float(step_log["iframes"]) * 1000.0])
	dps.action_queue.action_started.disconnect(step_start)
	dps.action_queue.phase_changed.disconnect(step_end)
	await _seconds(1.2)
	_check(hud_widget.combo_pips() == Vector2i.ZERO, "a second's rest starts the run over: the pips go dark")
	# The finisher's numbers land on the foe's owner from its id: 1.5x damage, +15 poise and the 1.2 s stun.
	_reset_boss_poise()
	var leap_hit: CombatEvent = _strike(dps, boss, 20.0, 10.0)
	leap_hit.combo_id = leap.combo_id
	leap_hit.command = Cmd.FORWARD_HEAVY
	resolved.clear()
	boss.stagger_time_left = 0.0
	director.deliver(leap_hit)
	_check(not resolved.is_empty() and is_equal_approx(resolved.back().damage, 30.0) and is_equal_approx(resolved.back().poise_damage, 25.0)
		and absf(boss.stagger_time_left - 1.2) < 0.02 and resolved.back().breaks_martial_lock,
		"a landed Gap-Leap finisher deals 1.5x (20 -> 30), +15 poise and stuns the Cairnsman 1.2 s, cracking a martial lock")
	boss.stagger_time_left = 0.0
	boss.stats.heal(boss.stats.stats.max_health)
	dps.combo.combo_step_advanced.disconnect(pip_hook)

	# --- 2. The two card choreographies ---
	# Out of combat: hold R 120 frames for the Overhead Pocket Blessing (no pip spent).
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 26.0)))
	dps.input.inject_move(Vector2.ZERO)
	await _seconds(0.1)
	dps.stats.resonance_charge = 0.3
	var flow: SignFlowComponent = dps.sign_flow
	var blessings: int = dps.visuals.choreography_count(ActorVisuals.Choreography.OVERHEAD_BLESSING)
	dps.input.inject_hold(InputComponent.ACTION_TRIGGER_R, true)
	for frame: int in SignFlowComponent.HEARTH_RITE_HOLD_FRAMES:
		await physics_frame
	dps.input.inject_hold(InputComponent.ACTION_TRIGGER_R, false)
	var blessing_started: bool = dps.visuals.choreography() == ActorVisuals.Choreography.OVERHEAD_BLESSING
	await _seconds(0.6)
	var mid_blessing: bool = dps.visuals.is_card_out() and dps.visuals.is_ink_pouring() and not dps.visuals.is_weapon_drawn()
	await _seconds(1.0)
	_check(not flow.is_in_combat and flow.has_hearth_rite_tuck and blessing_started and mid_blessing
		and dps.visuals.choreography_count(ActorVisuals.Choreography.OVERHEAD_BLESSING) == blessings + 1
		and dps.visuals.card_peak_height() > 1.8 and dps.visuals.card_peak_height() <= 2.6 and dps.visuals.is_weapon_drawn()
		and dps.visuals.choreography() == ActorVisuals.Choreography.NONE,
		"holding R out of combat plays the Overhead Pocket Blessing: weapon put away, the vellum card raised to %.2f m (<= 2.6) under a column of ink, weapon drawn again" % dps.visuals.card_peak_height())
	_check(is_equal_approx(dps.stats.resonance_charge, 1.0) and flow.opening_strike_empowered and is_equal_approx(flow.ward_blessing_mitigation(), 0.15)
		and is_equal_approx(dps.visuals.weapon_scale(), SignFlowComponent.TRAIL_COAT_SCALE),
		"the blessing costs 0 pips, tops up to 1.0, empowers the opening strike, glows the bow at 1.35x and grants a 15% Ward Blessing")
	var swipe: CombatActionResource = boss.loadout.action_by_id(ClassLoadouts.BOSS_SWIPE)
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 2.4)))
	await _seconds(0.05)
	var blessed_before: float = dps.stats.health
	director.deliver(CombatEvent.strike_from(boss, dps, swipe))
	var blessed_hit: float = blessed_before - dps.stats.health
	flow.ward_blessing_left = 0.0
	dps.stats.heal(dps.stats.stats.max_health)
	var plain_before: float = dps.stats.health
	director.deliver(CombatEvent.strike_from(boss, dps, swipe))
	var plain_hit: float = plain_before - dps.stats.health
	dps.stats.heal(dps.stats.stats.max_health)
	_check(plain_hit > 0.0 and absf(blessed_hit / plain_hit - 0.85) < 0.01 and flow.ward_attuned_id == boss.player_id,
		"the Ward Blessing turns toward the first foe that strikes (the Cairnsman): his swipe does 15%% less (%.1f vs %.1f)" % [blessed_hit, plain_hit])
	# In combat: a Light that lands opens the Flow-Link Window; R tapped in it is the Offhand Pocket-Draw.
	_face_boss(dps, Vector3(0.0, 0.0, 2.4))
	dps.input.inject_move(Vector2.ZERO)
	await _until_idle(dps)
	dps.stats.resonance_charge = 1.0
	dps.input.inject_command(Cmd.LIGHT)
	var waited: float = 0.0
	while flow.flow_window_left <= 0.0 and waited < 1.5:
		await physics_frame
		waited += 1.0 / 60.0
	var camera: PlayerCamera = dojo.grid.camera_for(dps.player_id)
	var pulses_before: int = camera.dolly_pulses() if camera != null else 0
	var draws: int = dps.visuals.choreography_count(ActorVisuals.Choreography.POCKET_DRAW)
	stops.clear()
	dps.input.inject_command(Cmd.TRIGGER_R_SKILL)
	var biggest: float = 1.0
	var drew: bool = false
	for frame: int in 40:
		await physics_frame
		biggest = maxf(biggest, dps.visuals.weapon_scale())
		drew = drew or dps.visuals.choreography() == ActorVisuals.Choreography.POCKET_DRAW and dps.visuals.is_card_out()
	var froze: bool = false
	for duration: float in stops:
		froze = froze or is_equal_approx(duration, SignFlowComponent.SIGN_FLOW_HIT_STOP)
	_check(drew and dps.visuals.choreography_count(ActorVisuals.Choreography.POCKET_DRAW) == draws + 1 and biggest >= 1.95 and froze
		and flow.coat_time_left > 7.0 and flow.coat_mode == Manifest.WEAPON_COAT and flow.coat_sign == Sign.SIGN_STAR_TIDE,
		"R tapped in the Flow-Link Window: the off hand sweeps the card along the bow, a 110 ms hit-stop, and a 2.0x Star-Tide Weapon-Coat")
	_check(camera != null and camera.dolly_pulses() == pulses_before + 1 and camera.dolly_peak() > 0.3 and camera.dolly_peak() <= 0.351,
		"and the split-screen camera dolly-pulses %.2f m toward the shoulder and back over 120 ms" % (camera.dolly_peak() if camera != null else 0.0))
	# L+R while the Weapon-Coat burns: the One-and-Done Seal-Breaker.
	await _until_idle(dps)
	_reset_boss_poise()
	_face_boss(dps, Vector3(0.0, 0.0, 2.2))
	dps.stats.resonance_charge = 3.0
	var ult: CombatActionResource = dps.loadout.opener_for(Cmd.TRIGGER_BOTH_ULT)
	var dones: int = flow.one_and_dones()
	var detonations: Array[String] = []
	var detonation_hook: Callable = func(_target: ActorBase, _primer: int, _cross: bool, label: String) -> void: detonations.append(label)
	director.synergy_detonated.connect(detonation_hook)
	resolved.clear()
	dps.input.inject_command(Cmd.TRIGGER_BOTH_ULT)
	await _seconds(0.9)
	var finisher: CombatEvent = null
	for event: CombatEvent in resolved:
		if event.one_and_done:
			finisher = event
	_check(flow.one_and_dones() == dones + 1 and flow.coat_time_left <= 0.0 and finisher != null
		and is_equal_approx(finisher.damage, ult.damage * 3.2) and finisher.coat_sign == Sign.SIGN_STAR_TIDE and finisher.cracks_lock
		and dps.stats.resonance_charge < 1.01,
		"L+R (3 pips) spends the Weapon-Coat on a One-and-Done: %s lands 3.2x (%.0f), cracking whatever lock or gate is up" % [ult.display_name,
			finisher.damage if finisher != null else 0.0])
	var chorus: bool = false
	for label: String in detonations:
		chorus = chorus or (label.contains("ONE-AND-DONE") and label.contains("ASTRAL CHORUS"))
	_check(chorus, "and its Four-Sign detonation rings out: Star-Tide's Astral Chorus")
	director.synergy_detonated.disconnect(detonation_hook)
	boss.stats.heal(boss.stats.stats.max_health)
	_reset_boss_poise()

	# --- 3. The Trinity: Tank Ward-Mantle, Support Aegis Ward and Ink-Share ---
	await _until_idle(tank)
	_face_boss(tank, Vector3(0.0, 0.0, 2.6))
	tank.input.inject_move(Vector2.ZERO)
	tank.input.inject_guard(false)
	await _seconds(0.1)
	tank.sign_flow._cast(Diorama.SKILL)
	var mantled: bool = tank.sign_flow.is_mantled() and tank.sign_flow.coat_sign == Sign.SIGN_IRON_ROOT
	var warded_before: int = tank.sign_flow.warded_hits
	var tank_before: float = tank.stats.health
	var boss_poise_before: float = boss.stats.poise
	var reflected: Array[float] = []
	var reflect_hook: Callable = func(_defender: ActorBase, _attacker: ActorBase, poise: float) -> void: reflected.append(poise)
	director.poise_reflected.connect(reflect_hook)
	director.deliver(CombatEvent.strike_from(boss, tank, swipe))
	var warded_hit: float = tank_before - tank.stats.health
	tank.stagger(1.0)
	var shrugged: bool = tank.stagger_time_left <= 0.0
	tank.sign_flow._clear_coat()
	tank.stats.heal(tank.stats.stats.max_health)
	var bare_before: float = tank.stats.health
	director.deliver(CombatEvent.strike_from(boss, tank, swipe))
	var bare_hit: float = bare_before - tank.stats.health
	tank.stats.heal(tank.stats.stats.max_health)
	_check(mantled and swipe.scribe_sign == Sign.SIGN_IRON_ROOT and bare_hit > 0.0 and absf(warded_hit / bare_hit - 0.2) < 0.01
		and tank.sign_flow.warded_hits == warded_before + 1 and shrugged,
		"an Iron-Root Ward-Mantle against the Cairnsman's Iron-Root swipe soaks 80%% (%.1f instead of %.1f) and shrugs off the stun" % [warded_hit, bare_hit])
	_check(reflected == [60.0] and absf((boss_poise_before - boss.stats.poise) - 60.0) < 0.5 and director.has_zone_from(tank.player_id),
		"the ward throws 60 poise back at the Cairnsman and the 4 m shelter cone stands behind the tank")
	director.poise_reflected.disconnect(reflect_hook)
	_reset_boss_poise()
	tank.stagger_time_left = 0.0
	# The Support: a Soul Tether link wards the DPS; an Ink-Share leaf lends Warm-Hearth against a Furrow Iron-Man's rust.
	var iron_man: WildMob = _practice_mob(&"soot_paw_cutthroat", boss.global_position + Vector3(9.0, 0.0, 9.0))
	await _seconds(0.1)
	_place_beside(dps, iron_man, 2.0)
	healer.place_at(Transform3D(Basis.IDENTITY, iron_man.global_position + Vector3(-8.0, 0.0, 0.0)))
	healer.input.inject_move(Vector2.ZERO)
	await _seconds(0.2)
	var plain_light: CombatActionResource = dps.loadout.opener_for(Cmd.LIGHT)
	flow._clear_coat()
	flow._end_tuck()
	resolved.clear()
	var full_before: float = iron_man.stats.health
	director.report_hit(dps, iron_man, plain_light, false)
	var full_hit: float = full_before - iron_man.stats.health
	var expected_full: float = plain_light.damage * (1.0 - iron_man.variant.mitigation)
	iron_man.stats.take_damage(iron_man.stats.health - iron_man.stats.stats.max_health * 0.74)
	var leap_from: Vector3 = iron_man.global_position
	await _seconds(0.7)
	var posture: PostureEscalationComponent = iron_man.posture
	var plates: int = 0
	for child: Node in iron_man.get_parent().get_children():
		if String(child.name).begins_with("ShedPlate"):
			plates += 1
	var warm: Color = catalog.sign_seal(Sign.SIGN_WARM_HEARTH).color
	_check(absf(full_hit - expected_full) < 0.01 and posture.state == PostureEscalationComponent.PostureState.STATE_EVASIVE_ARMOR_DROP
		and absf(posture.last_leap_distance - 3.0) < 0.05 and absf(iron_man.global_position.distance_to(leap_from) - 3.0) < 0.2 and plates >= 1
		and posture.is_ring_lit() and posture.lock_color() == warm and posture.lock_signs == [Sign.SIGN_WARM_HEARTH],
		"a Tier 1 Iron-Man takes full damage (%.0f) down to 75%%, then leaps 3 m back, sheds a plate and lights a Saffron-Gold Glimmer-Spot ring" % full_hit)
	var rust_before: float = iron_man.stats.health
	director.report_hit(dps, iron_man, plain_light, false)
	var rust_hit: float = rust_before - iron_man.stats.health
	_check(absf(rust_hit - expected_full * 0.5) < 0.01 and posture.is_locked(),
		"locked in rust, an un-inked Light clanks for half (%.1f), so nobody is ever stuck" % rust_hit)
	await _until_idle(healer)
	healer.tether.tethered_id = &""
	healer.tether.bind_actor(dps)
	await _seconds(0.05)
	var aegis: bool = dps.sign_flow.aegis_ward
	var promise: int = dps.sign_flow.flow_window_frames()
	healer.stats.resonance_charge = 2.0
	healer.stats.restore_stamina(healer.stats.stats.max_stamina)
	var shares: Array[int] = []
	var share_hook: Callable = func(_support: ActorBase, scribe_sign: int, _recipients: Array[ActorBase]) -> void: shares.append(scribe_sign)
	director.ink_shared.connect(share_hook)
	healer.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(0.3)
	_check(aegis and promise == SignFlowComponent.LANTERNS_PROMISE_WINDOW_FRAMES and healer.sign_flow.is_in_combat,
		"binding the Soul Tether wards the DPS (an Aegis Ward) and gives them The Lantern's Promise (18 frames) from 8 m away")
	_check(shares == [Sign.SIGN_WARM_HEARTH] and dps.sign_flow.shared_party_sign_override == Sign.SIGN_WARM_HEARTH
		and dps.sign_flow.ink_share_left > 7.0 and healer.tether.is_pulsing(),
		"the Support's Homing Heal is an Ink-Share: Warm-Hearth pulses down the Soul Tether, lent to the DPS for 8 s")
	director.ink_shared.disconnect(share_hook)
	var stagger_with_aegis: bool = false
	dps.stagger(0.8)
	stagger_with_aegis = dps.stagger_time_left <= 0.0 and not dps.sign_flow.aegis_ward
	resolved.clear()
	var inked_before: float = iron_man.stats.health
	await _until_idle(dps)
	director.report_hit(dps, iron_man, plain_light, false)
	var inked_hit: float = inked_before - iron_man.stats.health
	var inked: CombatEvent = resolved.back() if not resolved.is_empty() else null
	_check(inked != null and inked.coat_sign == Sign.SIGN_WARM_HEARTH and inked.ink_share_from == healer.player_id
		and absf(inked_hit - expected_full) < 0.01 and posture.state == PostureEscalationComponent.PostureState.STATE_LOCK_CRACKED
		and posture.locks_cracked == 1 and absf(inked.poise_damage - iron_kin.bravery_counter_poise()) < 0.01
		and absf(iron_man.stagger_time_left - 2.5) < 0.05 and iron_man.spectrum.is_maker_seal_exposed,
		"the DPS's plain Light now strikes as Warm-Hearth: full damage again (%.0f, 0.5x -> 1.0x), a Bravery Counter (%.0f poise, 2.5 s stun) and the Iron-Man's Maker-Seal opens" % [inked_hit,
			inked.poise_damage if inked != null else 0.0])
	_check(stagger_with_aegis, "and the Aegis Ward shrugged off the DPS's next stun, then was spent")
	iron_man.queue_free()
	# A Tier 1 martial lock (the Frost-Fang Padfoot) cracks under the Gap-Leap; a Tier 2 Crag-Back locks again at each gate.
	var padfoot: WildMob = _practice_mob(&"alpha_frost_fang", boss.global_position + Vector3(-9.0, 0.0, 9.0))
	await _seconds(0.1)
	padfoot.stats.take_damage(padfoot.stats.health - padfoot.stats.stats.max_health * 0.74)
	await _seconds(0.7)
	var martial: PostureEscalationComponent = padfoot.posture
	var white_gold: bool = martial.is_locked() and martial.lock_type == BossEncounterResource.LockKeyType.MARTIAL_COMBO_KEY \
		and martial.lock_color() == PostureEscalationComponent.MARTIAL_COLOR and martial.wants_martial_key()
	var gap: CombatEvent = _strike(dps, padfoot, 10.0, 0.0)
	gap.combo_id = leap.combo_id
	gap.command = Cmd.FORWARD_HEAVY
	director.deliver(gap)
	_check(white_gold and martial.state == PostureEscalationComponent.PostureState.STATE_LOCK_CRACKED and padfoot.stagger_time_left >= 2.4,
		"a Frost-Fang Padfoot's martial lock glows white-gold; the Sundering Gap-Leap cracks it with a Bravery Counter and a 2.5 s stun")
	padfoot.queue_free()
	var drake: WildMob = _practice_mob(&"crag_back_behemoth", boss.global_position + Vector3(0.0, 0.0, 16.0))
	await _seconds(0.1)
	drake.stats.take_damage(drake.stats.health - drake.stats.stats.max_health * 0.74)
	await _seconds(0.7)
	var first_key: int = drake.posture.lock_type
	var breaker: CombatEvent = _strike(dps, drake, 10.0, 0.0)
	breaker.one_and_done = true
	breaker.finisher_card_id = ArsenalCatalog.GALE_RUSH
	breaker.coat_sign = Sign.SIGN_STAR_TIDE
	breaker.command = Cmd.TRIGGER_BOTH_ULT
	director.deliver(breaker)
	var cracked_by_breaker: bool = drake.posture.state == PostureEscalationComponent.PostureState.STATE_LOCK_CRACKED
	drake.stats.take_damage(drake.stats.health - drake.stats.stats.max_health * 0.49)
	await _seconds(0.7)
	_check(first_key == BossEncounterResource.LockKeyType.MARTIAL_COMBO_KEY and cracked_by_breaker and drake.posture.is_locked()
		and drake.posture.lock_type == BossEncounterResource.LockKeyType.ELEMENTAL_INK_KEY and drake.posture.lock_signs == [Sign.SIGN_WARM_HEARTH]
		and drake.posture.locks_shown == 2,
		"the Tier 2 Crag-Back locks at 75% (martial: a One-and-Done cracks it) and again at 50% with a Warm-Hearth ink lock")
	drake.queue_free()

	# --- 4. A practice Cairnsman through his four gates ---
	var ring: Node3D = Node3D.new()
	ring.name = "PracticeRing"
	dojo.add_child(ring)
	var practice: BossDummy = BossDummy.new()
	practice.name = "PracticeCairnsman"
	practice.player_id = &"practice_cairnsman"
	practice.loadout = ClassLoadouts.raid_boss_dummy()
	practice.telegraphs_root = boss.telegraphs_root
	practice.set_multiplayer_authority(1)
	ring.add_child(practice)
	practice.spawn_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(-8.0, 0.0, 0.0)))
	practice.set_physics_process(false)
	practice.engaged = true
	practice.scale_health_to_party(1)
	var defeated: Array[bool] = []
	var defeated_hook: Callable = func() -> void: defeated.append(true)
	practice.defeated.connect(defeated_hook)
	progress.pattern_seen.erase(ArsenalCatalog.CAIRNSMAN)
	_place_beside(dps, practice, 3.0)
	await _seconds(0.1)
	var gates: BossGateComponent = practice.gates
	var max_health: float = practice.stats.stats.max_health
	_check(gates.is_active() and gates.gate == 0 and practice.glimmer.active_weakness() == [Sign.SIGN_IRON_ROOT, Sign.SIGN_STAR_TIDE],
		"Gate 1 (The Measure, 100-75%): the Cairnsman's Glimmer-Spot answers Iron-Root or Star-Tide")
	practice.stats.take_damage(max_health * 0.26)
	await _seconds(0.1)
	var summoned: int = gates.summons.standing_count() if is_instance_valid(gates.summons) else 0
	var leap_back: float = practice._pull_from.distance_to(practice._pull_to)
	# Its physics is paused for the test, so the leap's untouchable frames would never run out.
	practice._pull_duration = 0.0
	practice.stats._invulnerable_left = 0.0
	var shielded: float = practice.stats.health
	director.deliver(_strike(dps, practice, 100.0, 0.0))
	var aegis_hit: float = shielded - practice.stats.health
	director.deliver(_strike(dps, practice, 99999.0, 0.0))
	var held_at: float = practice.stats.health / max_health
	_check(gates.gate == 1 and gates.aegis_up and summoned == 3 and absf(leap_back - 3.0) < 0.05 and absf(aegis_hit - 10.0) < 0.5
		and held_at > 0.5 and held_at < 0.52 and not practice.glimmer.is_open(),
		"Gate 2 (The Summons, at 75%%): he leaps 3 m back behind a 90%% Aegis Mantle (100 lands as %.0f), three Bramble-Hobs answer, and he can't fall past 50%% while it stands" % aegis_hit)
	for minion: WoodlandMinion in gates.summons.minions:
		minion.stats.take_damage(minion.stats.health)
	await _seconds(0.1)
	await physics_frame
	_check(not gates.aegis_up and practice.glimmer.is_open() and practice.glimmer.active_weakness() == [Sign.SIGN_STAR_TIDE]
		and hud.rhyme_text() != "" and hud.rhyme_badges() == PackedStringArray(["◆ Star-Tide"]),
		"un-boggarting the henchmen shatters the mantle and opens Gate 2's Glimmer-Spot (Star-Tide), its rhyme on the HUD with a Star-Tide badge")
	practice.glimmer.close()
	practice.stats.take_damage(practice.stats.health - max_health * 0.49)
	await _seconds(0.1)
	_check(gates.gate == 2 and practice.phase_two and practice._next_cast == RaidTelegraphDecal.Kind.BLUE_BEHIND_TANK
		and practice.glimmer.is_countered_now(Sign.SIGN_WARM_HEARTH) and not practice.glimmer.is_countered_now(Sign.SIGN_IRON_ROOT),
		"Gate 3 (The Tempest, at 50%): the arena's Gale-Beam (BLUE_BEHIND_TANK) is next, and his weakness shifts to Warm-Hearth")
	var seen_before: int = progress.pattern_seen_count(ArsenalCatalog.CAIRNSMAN)
	var seal_frames: int = cairnsman.get_scaled_glimmer_frames(seen_before)
	practice.stats.take_damage(practice.stats.health - max_health * 0.24)
	await _seconds(0.1)
	_check(gates.gate == 3 and gates.is_roaring() and gates.is_seal_exposed() and gates.is_seal_showing() and not gates.seal_upright
		and absf(practice.glimmer.time_left() - (seal_frames / 60.0 - 0.1)) < 0.05,
		"Gate 4 (The Seal-Turn, at 25%%): a Challenge-Roar, and his inverted Maker-Seal shows for %d frames (seen %d times before)" % [seal_frames, seen_before])
	var wrong: CombatEvent = _strike(dps, practice, 5.0, 0.0)
	wrong.scribe_sign = Sign.SIGN_STAR_TIDE
	director.deliver(wrong)
	var still_inverted: bool = not gates.seal_upright and not practice.stats.is_downed
	var root_turn: CombatEvent = _strike(tank, practice, 5.0, 0.0)
	root_turn.scribe_sign = Sign.SIGN_IRON_ROOT
	director.deliver(root_turn)
	await _seconds(0.3)
	var cairn: UnboggartFx = ring.get_node_or_null(^"LulledCairn") as UnboggartFx
	_check(still_inverted and gates.seal_upright and gates.seals_turned == 1 and gates.state == BossGateComponent.GateState.STATE_UNBOGGART_RELEASE
		and practice.vanquished and defeated == [true] and practice.spectrum.state == HobSpectrumComponent.SpiritState.STATE_LULLED_CAIRN and cairn != null,
		"a Star-Tide strike leaves the seal be; an Iron-Root strike spins it right-way up: STATE_UNBOGGART_RELEASE, the fight won at 24%, and he's lulled into his cairn")
	ring.queue_free()

	# --- 5. Dioramas, Gilding potency, and one widget across the HUD, Binder and Scribery ---
	var harmony: Dictionary = catalog.compute_diorama_synergy(ArsenalCatalog.RISING_DRIVE, ArsenalCatalog.ARIUNDLE_MOSS_OAKS)
	var gilded_place: Dictionary = catalog.compute_diorama_synergy(ArsenalCatalog.RISING_DRIVE, ArsenalCatalog.ARIUNDLE_MOSS_OAKS,
		ScribeCardResource.CardVariant.STANDARD, ScribeCardResource.CardVariant.GILDED_LEAF)
	_check(harmony["is_home_ground_harmony"] and is_equal_approx(harmony["coat_duration_sec"], 10.0) and is_equal_approx(harmony["bonus_poise"], 15.0)
		and is_equal_approx(gilded_place["bonus_poise"], 16.5),
		"Moss-Oak-Hollow behind an Iron-Root Action-Leaf is Home-Ground Harmony: a 10.0 s coat and +15 poise (16.5 from a Gilded Leaf Place-Card)")
	var dps_class: PlayerClassResource = ClassLoadouts.player_class(dps.loadout.class_id, dps.loadout.calling)
	var plain_kit: EquipmentLoadoutResource = dps.loadout.kit.copy()
	var gilded_kit: EquipmentLoadoutResource = plain_kit.copy()
	gilded_kit.lead_variants[ScribeCardResource.GrimoireSlot.SIGNATURE] = ScribeCardResource.CardVariant.GILDED_LEAF
	var star_kit: EquipmentLoadoutResource = plain_kit.copy()
	star_kit.lead_variants[ScribeCardResource.GrimoireSlot.SIGNATURE] = ScribeCardResource.CardVariant.STAR_INKED_VELLUM
	var plain_r: float = LoadoutComposer.compose(dps_class, plain_kit).opener_for(Cmd.TRIGGER_R_SKILL).damage
	var gilded_r: float = LoadoutComposer.compose(dps_class, gilded_kit).opener_for(Cmd.TRIGGER_R_SKILL).damage
	var star_r: float = LoadoutComposer.compose(dps_class, star_kit).opener_for(Cmd.TRIGGER_R_SKILL).damage
	_check(plain_r > 0.0 and is_equal_approx(gilded_r, plain_r * 1.1) and is_equal_approx(star_r, plain_r * 1.2),
		"the Gilding Press adds potency: Gale Rush hits %.1f Plain, %.1f Gilded Leaf (+10%%), %.1f Star-Inked Vellum (+20%%)" % [plain_r, gilded_r, star_r])
	# Gild the DPS's worn Gale Rush at the Scribery: the shop's, the HUD's and the Binder's diamonds all show it.
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 26.0)))
	await _seconds(0.1)
	progress.chimes = 300
	progress.save()
	hud.open_scribery_shop()
	var shop: ScriberyShopPanel = hud.scribery_panel()
	var previews: int = shop.previews_played
	var draws_before: int = dps.visuals.choreography_count(ActorVisuals.Choreography.POCKET_DRAW)
	shop.select_tab(ScriberyShopPanel.Tab.GILD)
	var picked: bool = shop.select_option(ArsenalCatalog.GALE_RUSH)
	await physics_frame
	var preview_drew: bool = shop.previews_played > previews and dps.visuals.choreography_count(ActorVisuals.Choreography.POCKET_DRAW) > draws_before
	var gilded: bool = shop.buy()
	await _seconds(0.1)
	_check(picked and preview_drew and gilded and progress.owns_card(ArsenalCatalog.GALE_RUSH, ScribeCardResource.CardVariant.GILDED_LEAF)
		and dps.loadout.kit.lead_variants[ScribeCardResource.GrimoireSlot.SIGNATURE] == ScribeCardResource.CardVariant.GILDED_LEAF
		and hud_widget.socket_view(Diorama.SKILL)["leaf_variant"] == ScribeCardResource.CardVariant.GILDED_LEAF
		and shop.widget.kit.socket_leaf_variant(Diorama.SKILL) == ScribeCardResource.CardVariant.GILDED_LEAF
		and is_equal_approx(dps.loadout.opener_for(Cmd.TRIGGER_R_SKILL).damage, plain_r * 1.1),
		"picking Gale Rush at the Gilding Press plays the pocket-draw preview on the DPS's puppet; gilding it (+10%%) shows on the shop's and the HUD's diamonds and in the swing")
	shop.close()
	await _seconds(0.05)
	hud.toggle_binder()
	var binder: GrimoireBinderPanel = hud.binder_panel()
	var opening_scale: float = binder.widget.draw_scale() if binder != null else 0.0
	await _seconds(0.3)
	_check(binder != null and binder.widget.display_scale == CrossGrimoireDiamondWidget.BINDER_SCALE and binder.widget.interactive
		and opening_scale < CrossGrimoireDiamondWidget.BINDER_SCALE - 0.3 and is_equal_approx(binder.widget.draw_scale(), CrossGrimoireDiamondWidget.BINDER_SCALE)
		and binder.widget.socket_view(Diorama.SKILL)["leaf_variant"] == ScribeCardResource.CardVariant.GILDED_LEAF
		and hud_widget.display_scale == CrossGrimoireDiamondWidget.HUD_SCALE and not hud_widget.interactive
		and GrimoireBinderPanel.combo_forms_text().contains("✓ Sundering Gap-Leap:  Light → Light → ↑+Heavy"),
		"the Binder grows the same widget from %.1fx to 2.2x over 220 ms, shows the Gilded Gale Rush, and lists the Combo Forms the party knows" % opening_scale)
	hud.toggle_binder()
	await _seconds(0.05)

	# Back as we were, and the new systems off again for the checks that follow.
	director.hit_resolved.disconnect(resolved_hook)
	director.hit_stop_applied.disconnect(stop_hook)
	SignFlowComponent.enabled = false
	GlimmerSpotComponent.enabled = false
	ComboChainComponent.enabled = false
	PostureEscalationComponent.enabled = false
	BossGateComponent.enabled = false
	boss.gates.set_physics_process(true)
	boss.glimmer.close()
	progress.pattern_seen.clear()
	progress.chimes = chimes_before
	progress.collection.assign(collection_before)
	if healer.tether != null:
		healer.tether.bind_slot(0)
	for actor: ActorBase in [tank, healer, dps]:
		await _until_idle(actor)
		network.update_local_kit(actor.device_id, ClassLoadouts.starter_kit(actor.loadout.class_id).to_dict())
		actor.stats.heal(actor.stats.stats.max_health)
		actor.stagger_time_left = 0.0
		actor.sign_flow._end_ink_share()
		actor.sign_flow._clear_coat()
		actor.sign_flow._end_tuck()
		actor.sign_flow.aegis_ward = false
		actor.sign_flow.ward_blessing_left = 0.0
	progress.save()
	await _seconds(0.1)
	boss.stats.heal(boss.stats.stats.max_health)
	_stage_party()
	_reset_boss_poise()
	boss.set_physics_process(true)


## Plays one posture on a hero's controller and waits for it to finish.
func _play(actor: ActorBase, command: int) -> void:
	actor.input.inject_command(command)
	await physics_frame
	await physics_frame
	await _until_idle(actor)


## A starting-zone spirit dropped into the Ring as a practice dummy: no spawner, so it stands still; awake, so it counts as a fight.
func _practice_mob(variant_id: StringName, where: Vector3) -> WildMob:
	var mob: WildMob = WildMob.new()
	mob.variant = Bestiary.variant(variant_id)
	mob.loadout = Bestiary.loadout(mob.variant)
	mob.name = "Practice%s" % String(variant_id).to_pascal_case()
	mob.player_id = StringName("practice_%s" % variant_id)
	mob.set_multiplayer_authority(1)
	dojo.actors_root.add_child(mob)
	mob.spawn_at(Transform3D(Basis.IDENTITY, where))
	mob.engaged = true
	return mob


## Puts `actor` `distance` metres in front of `target`, facing it.
func _place_beside(actor: ActorBase, target: ActorBase, distance: float) -> void:
	var where: Vector3 = target.global_position + Vector3(0.0, 0.0, distance)
	actor.place_at(Transform3D(Basis.looking_at((target.global_position - where).normalized(), Vector3.UP), where))
	actor.input.inject_move(Vector2.ZERO)


## The Reed-Light Scribery on Bramble-Bridge's square: under the 3.2 m sightline
## cap, its prompt, and light at the counter opens the shop on your own screen.
func _check_reed_light_scribery() -> void:
	var hub: HubTown = current_scene as HubTown
	var keyboard: ActorBase = hub.actors[&"1_0"]
	var hud: PlayerHUD = hub.huds[&"1_0"]
	var station: ScriberyStation = hub.get_node_or_null(^"ReedLightScribery") as ScriberyStation
	keyboard.input.release_script()
	var lights: int = 0
	if station != null:
		for child: Node in station.find_children("*", "OmniLight3D", true, false):
			lights += 1
	_check(station != null and station.tallest_point() <= 3.0 and station.tallest_point() > 2.5 and lights == 4
		and station.get_node_or_null(^"VellumPressWheel") != null,
		"the Reed-Light Scribery stands on the square: a stepped-gable pavilion %.2f m tall (under the 3.2 m cap), a Vellum Press-Wheel and four Deep-Ink Vat Lanterns"
		% (station.tallest_point() if station != null else 0.0))
	if station == null:
		return
	var front: Vector3 = -station.global_basis.z
	keyboard.place_at(Transform3D(Basis.IDENTITY, station.global_position + front * 2.4))
	await _seconds(0.1)
	_check(keyboard.interactable == station and hud.prompt_text().contains("Reed-Light Scribery"), "at its counter the prompt names the Reed-Light Scribery")
	await _tap_key(KEY_J)
	_check(hud.scribery_panel() != null and keyboard.input.menu_open and not keyboard.action_queue.is_busy(), "J at the counter opens the Scribery's three tabs")
	await _tap_key(KEY_SPACE)
	_check(hud.scribery_panel() == null, "Space closes it")
	await _tap_key(KEY_TAB)
	var opened: bool = hud.binder_panel() != null
	await _tap_key(KEY_TAB)
	_check(opened and hud.binder_panel() == null and hub.actors[&"1_0"] == keyboard and keyboard.loadout.class_id == ClassLoadouts.SHIELD_TANK,
		"a tap of Tab opens the Grimoire Binder and another closes it (holding Tab still changes Fellowship)")


## Waits until `actor` is in the recovery of an action other than `previous`.
func _until_recovery_of(actor: ActorBase, previous: CombatActionResource) -> void:
	var waited: float = 0.0
	while waited < 2.0 and not (actor.action_queue.phase == ActionQueueComponent.Phase.RECOVERY and actor.action_queue.current_action != previous):
		await physics_frame
		waited += 1.0 / 60.0


static func _flat(offset: Vector3) -> float:
	return Vector2(offset.x, offset.z).length()


func _companions() -> Array[ActorBase]:
	var bots: Array[ActorBase] = []
	for actor: ActorBase in dojo.actors.values():
		if actor.is_companion:
			bots.append(actor)
	return bots


func _companion_with(role: int) -> ActorBase:
	for bot: ActorBase in _companions():
		if bot.role() == role:
			return bot
	return null


## Beating the boss: slow motion, a banner, a chest of Chimes, and the gold portal home.
func _check_victory_and_loot() -> void:
	var session: MultiplayerPeer = root.multiplayer.multiplayer_peer
	var chimes_before: int = PartyProgress.current.chimes
	var level_before: int = PartyProgress.current.grimoire_level()
	# A seed whose chest card is a Gilded Leaf or Star-Inked boss card for the Forward slot.
	var seed: int = _seed_for_forward_boss_card()
	PartyProgress.current.drop_rng.seed = seed
	var probe: RandomNumberGenerator = RandomNumberGenerator.new()
	probe.seed = seed
	var expected_card: StringName = ArsenalCatalog.current.roll_card_drop(probe)
	# Everyone back on the spawn pads, well clear of where the chest lands.
	for actor: ActorBase in [tank, healer, dps]:
		actor.respawn()
		actor.input.inject_move(Vector2.ZERO)
	boss.stats.take_damage(boss.stats.health)
	await _seconds(0.1)
	_check(dojo.victory and boss.vanquished and boss.state_machine.is_in(&"downed"), "defeating the Cairnsman starts the victory")
	var cairn: UnboggartFx = boss.get_parent().get_node_or_null(^"LulledCairn") as UnboggartFx
	_check(boss.spectrum != null and boss.spectrum.state == HobSpectrumComponent.SpiritState.STATE_LULLED_CAIRN and cairn != null
		and is_inf(cairn.linger), "the Cairnsman isn't slain: he's lulled back into a mossy river-cairn that stays (STATE_LULLED_CAIRN)")
	_check(is_equal_approx(Engine.time_scale, DungeonDojo.VICTORY_TIME_SCALE), "the win plays out in slow motion (x0.2)")
	_check(dojo.chest != null and dojo.chest.is_inside_tree(), "a reward chest drops into the arena")
	_check(PartyProgress.current.grimoire_level() == level_before + 1, "the win raises the Grimoire to Lv %d" % (level_before + 1))
	var banners: int = 0
	for hud: PlayerHUD in dojo.huds.values():
		if hud.banner_title() == "VICTORY!":
			banners += 1
	_check(banners == 3, "every player's HUD shows the VICTORY! banner")
	await _seconds(DungeonDojo.VICTORY_SLOWMO_TIME)
	_check(is_equal_approx(Engine.time_scale, 1.0), "2 s later the game is back to normal speed")
	await _seconds(1.0)
	_check(boss.stats.is_downed and not dojo.chest.is_open, "the boss stays down and the chest waits to be opened")
	dps.place_at(Transform3D(Basis.IDENTITY, dojo.chest.global_position + Vector3(0.8, 0.0, 0.8)))
	await _seconds(0.2)
	_check(dojo.chest.is_open, "walking up to the chest opens it")
	var paid: int = DungeonDojo.chest_chimes(3)
	_check(PartyProgress.current.chimes == chimes_before + paid, "the chest pays the party %d Chimes" % paid)
	_dropped_card = expected_card
	_check(dojo.chest.card_key == expected_card and PartyProgress.current.copies_of(expected_card) == 1,
		"and a collectible card for the binder: %s" % ArsenalCatalog.current.copy_name(expected_card))
	_check((dojo.huds[tank.player_id] as PlayerHUD).banner_title() == "+%d CHIMES" % paid, "the banner shows the Chimes earned")
	var saved: ConfigFile = ConfigFile.new()
	_check(saved.load(TEST_SAVE_PATH) == OK and int(saved.get_value("party", "chimes", 0)) == chimes_before + paid, "the Chimes are saved for next time")
	var coins: ChimeBurst = dojo.chest.get_node_or_null(^"ChimeBurst") as ChimeBurst
	_check(coins != null, "brass Chimes burst out of the chest toward the party")
	_check(dojo.exit_portal.is_recalling(), "the gold exit portal starts calling the party home")
	await _until_live_in(InstanceManager.HUB_TOWN)
	_check(current_scene is HubTown, "the gold portal brings the party back to Bramble-Bridge")
	_check(root.multiplayer.multiplayer_peer == session and NetworkManager.current.is_online(), "still the same ENet session after the round trip")
	_check(NetworkManager.current.party_size() == 3 and _hub().grid.view_count() == 3, "the whole party is back in town")
	await _seconds(0.2)
	var orphans: int = _orphan_count()
	_check(orphans <= _orphans_before, "no orphaned nodes after Bramble-Bridge, the Ring and back (%d before, %d after)" % [_orphans_before, orphans])


func _check_audio_cues() -> void:
	var silent: PackedStringArray = PackedStringArray()
	var acoustic: int = 0
	for cue: StringName in AudioCues.CUES:
		if AudioCues.current.stream_for(cue).data.size() < 200:
			silent.append(cue)
		acoustic += 1 if AudioCues.baked_stream(cue) != null else 0
	# The musical cues are baked acoustic recordings; hits, shots, the gale, the beam and splashes stay synthesized.
	_check(silent.is_empty() and acoustic >= 28, "every audio cue sounds, %d of %d of them acoustic recordings %s" % [acoustic, AudioCues.CUES.size(),
		"" if silent.is_empty() else str(silent)])
	var expected: Array[StringName] = [&"flow", &"hit", &"perfect_guard", &"telegraph", &"heal", &"join", &"portal", &"portal_charge",
		&"victory", &"chest", &"chime", &"purchase", &"refuse", &"menu_move", &"shot", &"card_chime", &"card_chime_foil", &"card_chime_astral"]
	var unheard: PackedStringArray = PackedStringArray()
	for cue: StringName in expected:
		if not _audio_cues.has(cue):
			unheard.append(cue)
	_check(unheard.is_empty(), "flows, hits, guards, telegraphs, heals, joins, portals, the victory, the chest, its Chimes and the shrine all play their cues %s" % (
		"" if unheard.is_empty() else str(unheard)))


# --- Hub Town upgrades ----------------------------------------------------

## The Chime-Shrine: walk up, press J, spend the chest's Chimes on upgrades for everyone.
func _check_chime_shrine() -> void:
	var hub: HubTown = current_scene as HubTown
	var progress: PartyProgress = PartyProgress.current
	var keyboard: ActorBase = hub.actors[&"1_0"]
	var hud: PlayerHUD = hub.huds[&"1_0"]
	keyboard.input.release_script()
	var front: Vector3 = -hub.chime_shrine.global_basis.z
	keyboard.place_at(Transform3D(Basis.IDENTITY, hub.chime_shrine.global_position + front * 1.6))
	await _seconds(0.1)
	_check(keyboard.interactable == hub.chime_shrine and hud.prompt_text().contains("Chime-Shrine"), "standing at the shrine shows the Chime-Shrine prompt")
	await _tap_key(KEY_J)
	var menu: HubUpgradeMenu = hud.upgrade_menu()
	_check(menu != null and keyboard.input.menu_open and not keyboard.action_queue.is_busy(), "J at the shrine opens the upgrade menu instead of swinging")
	# Exactly the boss chest's Chimes (the camps and the Wayfarer's Chest paid more), so the prices below add up.
	progress.chimes = DungeonDojo.chest_chimes(3)
	var chimes: int = progress.chimes
	var tank_health: float = keyboard.stats.stats.max_health
	var healer_health: float = hub.actors[&"1_1"].stats.stats.max_health
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 1 and progress.chimes == chimes - PartyProgress.UPGRADE_BASE_COST,
		"J buys Max Health level 1 for %d Chimes" % PartyProgress.UPGRADE_BASE_COST)
	_check(is_equal_approx(keyboard.stats.stats.max_health, tank_health * 1.1) and is_equal_approx(hub.actors[&"1_1"].stats.stats.max_health, healer_health * 1.1),
		"everyone's max health grows by 10%")
	_check(is_equal_approx(keyboard.stats.health, keyboard.stats.stats.max_health), "and they stay at full health")
	var regen: float = keyboard.stats.stats.stamina_regen_per_sec
	await _tap_key(KEY_S)
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.STAMINA_REGEN) == 1 and is_equal_approx(keyboard.stats.stats.stamina_regen_per_sec, regen * 1.1),
		"S then J buys Stamina Regen (+10% stamina per second)")
	await _tap_key(KEY_W)
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 2 and progress.chimes == chimes - 16, "Max Health level 2 costs 8 Chimes")
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 2 and progress.chimes == 0 and menu.note_text().begins_with("Not enough Chimes"),
		"without enough Chimes the purchase is refused")
	await _tap_key(KEY_SPACE)
	_check(hud.upgrade_menu() == null and not keyboard.input.menu_open and not keyboard.state_machine.is_in(&"dodge"), "Space closes the menu without rolling")
	var saved: ConfigFile = ConfigFile.new()
	_check(saved.load(TEST_SAVE_PATH) == OK and int(saved.get_value("upgrades", "max_health", 0)) == 2
		and int(saved.get_value("upgrades", "stamina_regen", 0)) == 1, "the upgrades are saved")
	progress.load_save()
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 2 and progress.level_of(PartyProgress.STAMINA_REGEN) == 1 and progress.chimes == 0,
		"and load back next session")
	# A save from before the rename still opens its pouch.
	var old_save: ConfigFile = ConfigFile.new()
	old_save.load(TEST_SAVE_PATH)
	old_save.erase_section_key("party", "chimes")
	old_save.set_value("party", "shards", 7)
	old_save.save(TEST_SAVE_PATH)
	progress.load_save()
	_check(progress.chimes == 7, "an old save's Dojo Shards load as Chimes")
	progress.chimes = 0
	progress.save()
	NetworkManager.current.update_local_player(2, ClassLoadouts.SHIELD_TANK, InputComponent.AssistMode.MASTER)
	await _seconds(0.05)
	_check(is_equal_approx(hub.actors[&"1_2"].stats.stats.max_health, ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK).base_stats.max_health * 1.2),
		"a player who changes class starts with the upgrades too")
	NetworkManager.current.drop_local_player(1)
	NetworkManager.current.drop_local_player(2)
	await _seconds(0.1)
	_check(NetworkManager.current.companion_seats().is_empty() and hub.actors.size() == 1, "companions only join raids, not Bramble-Bridge")


# --- Armory & Scribe Desk -------------------------------------------------

## The desk, by keyboard: weapon, armor and card swaps in place; the chest's
## card; an under-card refused for memory, then fitting; a locked link; and
## the kit saved for the class's next seat.
func _check_scribe_desk() -> void:
	var hub: HubTown = current_scene as HubTown
	var network: NetworkManager = NetworkManager.current
	var keyboard: ActorBase = hub.actors[&"1_0"]
	var hud: PlayerHUD = hub.huds[&"1_0"]
	keyboard.input.release_script()
	var front: Vector3 = -hub.scribe_desk.global_basis.z
	keyboard.place_at(Transform3D(Basis.IDENTITY, hub.scribe_desk.global_position + front * 1.8))
	await _seconds(0.1)
	_check(keyboard.interactable == hub.scribe_desk and hud.prompt_text().contains("Scribe Desk"), "standing at the desk shows the Armory & Scribe Desk prompt")
	await _tap_key(KEY_J)
	var menu: ScribeDeskMenu = hud.scribe_desk_menu()
	_check(menu != null and keyboard.input.menu_open and not keyboard.action_queue.is_busy(), "J at the desk opens it (instead of swinging)")
	var weapon_before: StringName = keyboard.loadout.weapon.item_id
	await _tap_key(KEY_D)
	_check(keyboard.loadout.weapon.item_id == weapon_before and menu.problem().contains("needs a Swift Foot (+DPS) Calling"),
		"a Bridge-Warden can't take up the Greataxe: the desk says it needs a Swift Foot Calling")
	await _tap_key(KEY_W)
	await _tap_key(KEY_W)
	await _tap_key(KEY_D)
	await _seconds(0.05)
	_check(keyboard.loadout.display_name == "Weald-Captain" and keyboard.loadout.calling == Callings.Secondary.SWIFT_FOOT
		and hub.actors[&"1_0"] == keyboard and hud.scribe_desk_menu() == menu, "D on the Calling row makes the tank a Weald-Captain (Swift Foot) in place")
	_check(is_equal_approx(keyboard.base_stats.max_health, 160.0) and is_equal_approx(keyboard.loadout.stats.stamina_regen_per_sec / PartyProgress.current.multiplier(PartyProgress.STAMINA_REGEN), 18.0 + _secondary(ArsenalCatalog.SWIFT_FOOT).stamina_regen_bonus),
		"a Weald-Captain trades the Stout Heart's +20 health for +3 stamina a second")
	await _tap_key(KEY_S)
	await _tap_key(KEY_S)
	await _tap_key(KEY_D)
	_check(keyboard.loadout.weapon.item_id != weapon_before and hub.actors[&"1_0"] == keyboard and hud.scribe_desk_menu() == menu,
		"with a Swift Foot, D on the Weapon row swaps the weapon in place: the same character, view and open menu")
	_check(keyboard.loadout.weapon.item_id == ArsenalCatalog.HEAVY_AXE and keyboard.loadout.opener_for(Cmd.LIGHT).action_id == &"heavy_axe/cleave_1",
		"the tank now swings the Greataxe's cleaves")
	await _tap_key(KEY_W)
	await _tap_key(KEY_A)
	_check(keyboard.loadout.armor.item_id == ArsenalCatalog.RANGER_LEATHER and is_equal_approx(keyboard.loadout.stats.perfect_guard_window, 0.2),
		"A on the Armor row trades Iron-Wood Ring-Coat for Hedgerow Wool-Mantle (and its 200 ms window)")
	await _tap_key(KEY_S)
	await _tap_key(KEY_S)
	for press: int in 6:
		if keyboard.loadout.kit.lead_copy_key(0) == _dropped_card:
			break
		await _tap_key(KEY_D)
	_check(keyboard.loadout.kit.lead_copy_key(0) == _dropped_card and keyboard.loadout.card_action(0).card_id == ScribeCardResource.copy_card_id(_dropped_card),
		"the chest's %s goes into the Forward slot" % ArsenalCatalog.current.copy_name(_dropped_card))
	for press: int in 4:
		await _tap_key(KEY_S)
	await _tap_key(KEY_D)
	_check(menu.problem().begins_with("Needs 9 Grimoire Memory") and keyboard.loadout.kit.under_ids[0] == &"",
		"an Under-Card under that Rare card needs more memory than Lv 2 holds: refused, nothing changes")
	for press: int in 4:
		await _tap_key(KEY_W)
	for press: int in 6:
		if keyboard.loadout.kit.lead_copy_key(0) == ArsenalCatalog.SHIELD_CHARGE:
			break
		await _tap_key(KEY_D)
	var surged: CombatActionResource = keyboard.loadout.card_action(0)
	_check(keyboard.loadout.kit.under_ids[0] == ArsenalCatalog.IRON_ROOT_LINK
		and is_equal_approx(surged.damage, 20.0 * LoadoutComposer.UNDER_POTENCY_MULTIPLIER * _secondary(ArsenalCatalog.SWIFT_FOOT).strike_damage_multiplier),
		"back on the Basic Shield Charge the link fits: Iron-Root Link surges it by 20% (and the Swift Foot's 15% on top)")
	for press: int in 5:
		await _tap_key(KEY_S)
	await _tap_key(KEY_D)
	_check(menu.problem().contains("opens at Grimoire Lv 3") and keyboard.loadout.kit.under_ids[1] == &"", "link 2 stays locked until Grimoire Lv 3")
	await _tap_key(KEY_SPACE)
	_check(hud.scribe_desk_menu() == null and not keyboard.input.menu_open, "Space closes the desk")
	var saved: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(PartyProgress.current.kit_for(ClassLoadouts.SHIELD_TANK))
	var calling_save: ConfigFile = ConfigFile.new()
	calling_save.load(TEST_SAVE_PATH)
	_check(saved.same_as(keyboard.loadout.kit) and PartyProgress.current.calling_for(ClassLoadouts.SHIELD_TANK) == ArsenalCatalog.SWIFT_FOOT
		and str((calling_save.get_value("callings", "by_class", {}) as Dictionary).get("shield_tank", "")) == "swift_foot",
		"the tank's new kit and Calling are saved for the next session (the Calling as its id)")
	network.request_local_player(1, ClassLoadouts.SHIELD_TANK, InputComponent.AssistMode.ADVENTURER)
	await _seconds(0.1)
	var second: ActorBase = hub.actors.get(&"1_1") as ActorBase
	_check(second != null and second.loadout.kit.same_as(keyboard.loadout.kit) and second.loadout.display_name == "Weald-Captain",
		"a new Shield-Sworn seat starts as a Weald-Captain in the party's saved tank kit")
	network.drop_local_player(1)
	await _seconds(0.05)


## Hold C for the next Calling (its gear comes off if it can't use it), then
## the desk's Fellowship row: a new character, and the desk reopens for it.
func _check_calling_shortcut_and_fellowship() -> void:
	var hub: HubTown = current_scene as HubTown
	var keyboard: ActorBase = hub.actors[&"1_0"]
	keyboard.input.release_script()
	_key(KEY_C, true)
	await _seconds(InputComponent.MENU_HOLD_TIME + 0.15)
	_key(KEY_C, false)
	await _seconds(0.05)
	_check(hub.actors[&"1_0"] == keyboard and keyboard.loadout.calling == Callings.Secondary.WISE_HAND and keyboard.loadout.display_name == "Hearth-Guard",
		"holding C cycles the Calling in place: the Weald-Captain becomes a Hearth-Guard (Wise Hand)")
	_check(keyboard.loadout.weapon.item_id == ArsenalCatalog.LIGHT_SWORD, "the Greataxe, which needs a Swift Foot, comes off for the starter sword")
	var front: Vector3 = -hub.scribe_desk.global_basis.z
	keyboard.place_at(Transform3D(Basis.IDENTITY, hub.scribe_desk.global_position + front * 1.8))
	await _seconds(0.1)
	await _tap_key(KEY_J)
	for press: int in ScribeDeskMenu.ROW_WEAPON:
		await _tap_key(KEY_W)
	await _tap_key(KEY_D)
	await _seconds(0.1)
	var lantern: ActorBase = hub.actors[&"1_0"]
	var reopened: ScribeDeskMenu = (hub.huds[&"1_0"] as PlayerHUD).scribe_desk_menu()
	_check(lantern != keyboard and lantern.loadout.class_id == ClassLoadouts.SOUL_TETHER_HEALER and lantern.tether != null
		and reopened != null and reopened.selected == ScribeDeskMenu.ROW_FELLOWSHIP,
		"on the desk's Fellowship row, D makes P1 a Lantern-Bearer: a new character, and the desk reopens on their screen")
	_check(lantern.loadout.display_name == "Lantern-Scribe" and lantern.display_name() == "P1 · Lantern-Scribe", "a new Lantern-Bearer starts as a Lantern-Scribe")
	await _tap_key(KEY_A)
	await _seconds(0.1)
	var back: ActorBase = hub.actors[&"1_0"]
	_check(back.loadout.class_id == ClassLoadouts.SHIELD_TANK and back.loadout.display_name == "Hearth-Guard",
		"A takes P1 back to the Shield-Sworn, as the Hearth-Guard they last chose")
	await _tap_key(KEY_SPACE)
	_check((hub.huds[&"1_0"] as PlayerHUD).scribe_desk_menu() == null, "Space closes the reopened desk")


## The first drop seed whose chest card is a Gilded Leaf or Star-Inked copy of a boss card for the Forward slot.
func _seed_for_forward_boss_card() -> int:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for seed: int in range(1, 5000):
		rng.seed = seed
		var key: StringName = catalog.roll_card_drop(rng)
		var card: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(key))
		if not card.starter and card.slot == ScribeCardResource.GrimoireSlot.FORWARD and ScribeCardResource.copy_variant(key) != ScribeCardResource.CardVariant.STANDARD:
			return seed
	return 1


func _orphan_count() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))


# --- Helpers --------------------------------------------------------------

func _connect_global_signals() -> void:
	var director: CombatDirector = CombatDirector.current
	AudioDirector.current.stinger_played.connect(func(id: StringName, _notes: PackedInt32Array) -> void: _stingers_heard.append(id))
	director.hit_stop_applied.connect(func(_duration: float) -> void: _hit_stops += 1)
	director.primer_applied.connect(func(_target: ActorBase, primer: int) -> void: _primers.append(primer))
	director.synergy_detonated.connect(func(_target: ActorBase, _primer: int, cross_class: bool, label: String) -> void:
		_synergies.append(label)
		if cross_class:
			_cross_class_synergies += 1)
	director.perfect_guard_landed.connect(func(defender: ActorBase) -> void:
		_perfect_guards += 1
		if defender.is_companion:
			_companion_perfect_guards += 1)
	director.hit_resolved.connect(func(event: CombatEvent, outcome: int) -> void:
		_outcomes.append(outcome)
		if event.unavoidable:
			_telegraph_hits += 1)
	director.telegraph_cast.connect(func(decal: RaidTelegraphDecal) -> void:
		_telegraph_kinds[decal.kind] = _telegraph_kinds.get(decal.kind, 0) + 1)
	director.cue_shown.connect(func(_at: Vector3, cue: StringName) -> void: _cue_sounds.append(cue))
	director.projectile_fired.connect(func(attacker: ActorBase, _action: CombatActionResource) -> void: _projectiles.append(attacker.player_id))
	director.card_invoked.connect(func(_caster: ActorBase, _action: CombatActionResource, variant: int) -> void: _invocations.append(variant))
	AudioCues.current.cue_played.connect(func(cue: StringName) -> void: _audio_cues.append(cue))
	NetworkManager.current.registration_refused.connect(func(_device: int, reason: String) -> void: _refusals.append(reason))


## Puts the party in front of the boss, facing it, with scripted input and signals hooked up.
func _stage_party() -> void:
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 2.6)))
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(-1.2, 0.0, 2.6)))
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(2.5, 0.0, 6.0)))
	for actor: ActorBase in [tank, healer, dps]:
		actor.input.inject_move(Vector2.ZERO)
	if not dps.action_queue.flow_cancelled.is_connected(_on_dps_flow):
		dps.action_queue.flow_cancelled.connect(_on_dps_flow)
	if not healer.state_machine.state_changed.is_connected(_on_healer_state):
		healer.state_machine.state_changed.connect(_on_healer_state)


func _on_dps_flow(_from: CombatActionResource, _to: CombatActionResource) -> void:
	_flow_speed_scales.append(dps.action_queue.speed_scale)


func _on_healer_state(_from: StringName, to: StringName) -> void:
	_healer_states.append(to)


func _face_boss(actor: ActorBase, offset: Vector3) -> void:
	var where: Vector3 = boss.global_position + offset
	var to_boss: Vector3 = boss.global_position - where
	to_boss.y = 0.0
	actor.place_at(Transform3D(Basis.looking_at(to_boss.normalized(), Vector3.UP), where))


## Everyone onto a portal's platform, spread around its centre.
func _gather_on(portal: RaidPortal, level: LevelBase) -> void:
	var index: int = 0
	for actor: ActorBase in level.actors.values():
		var angle: float = TAU * index / maxf(1.0, level.actors.size())
		actor.place_at(Transform3D(Basis.IDENTITY, portal.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 1.0))
		if actor.input != null:
			actor.input.inject_move(Vector2.ZERO)
		index += 1


func _until_live_in(id: StringName) -> void:
	var waited: float = 0.0
	while waited < PORTAL_TIMEOUT and not (InstanceManager.current.instance_id == id and InstanceManager.current.is_live() and current_scene is LevelBase \
			and (current_scene as LevelBase).instance_id() == id):
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(0.1)


func _strike(attacker: ActorBase, target: ActorBase, damage: float, poise: float) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.STRIKE
	event.attacker_path = attacker.get_path()
	event.target_path = target.get_path()
	event.attacker_player_id = attacker.player_id
	event.attacker_role = attacker.role()
	event.damage = damage
	event.poise_damage = poise
	event.origin = attacker.global_position
	return event


func _hub() -> LevelBase:
	return current_scene as LevelBase


func _pad_id(index: int) -> StringName:
	return PartyMember.make_player_id(1, FAKE_PADS[index] + 1)


func _capture(actor: ActorBase) -> void:
	_commands[actor.player_id] = []
	actor.input.command_issued.connect(_on_command.bind(actor.player_id))


func _on_command(command: int, player_id: StringName) -> void:
	_commands[player_id].append(command)


func _commands_of(player_id: StringName) -> Array:
	return _commands.get(player_id, [])


func _press_heavy_with_stick(pad: int, stick_y: float) -> void:
	_pad_axis(pad, JOY_AXIS_LEFT_Y, stick_y)
	await _seconds(0.05)
	_pad_button(pad, JOY_BUTTON_Y, true)
	await _seconds(0.05)
	_pad_button(pad, JOY_BUTTON_Y, false)
	_pad_axis(pad, JOY_AXIS_LEFT_Y, 0.0)
	await _seconds(0.05)


func _tap_key(key: Key) -> void:
	_key(key, true)
	await _seconds(0.05)
	_key(key, false)
	await _seconds(0.05)


func _key(key: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


func _pad_button(pad: int, button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = pad
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _pad_axis(pad: int, axis: JoyAxis, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = pad
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _reset_boss_poise() -> void:
	boss.stats.knockdown_time_left = 0.0
	boss.stats.poise = boss.stats.stats.max_poise
	boss.stagger_time_left = 0.0
	# A hit-stop banked while its physics was paused (a card's 140 ms) would otherwise freeze its timers.
	boss._hit_stop_left = 0.0


func _count_zones(shape: SanctuaryZone.Shape) -> int:
	var count: int = 0
	for child: Node in dojo.effects_root.get_children():
		var zone: SanctuaryZone = child as SanctuaryZone
		if zone != null and zone.shape == shape:
			count += 1
	return count


func _until_idle(actor: ActorBase) -> void:
	var waited: float = 0.0
	while (actor.action_queue.is_busy() or not actor.can_act()) and waited < 3.0:
		await physics_frame
		waited += 1.0 / 60.0


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _seconds(duration: float) -> void:
	for frame: int in ceili(duration * 60.0):
		await physics_frame


func _check(ok: bool, label: String) -> void:
	if ok:
		_passes += 1
		print("  PASS  " + label)
	else:
		_failures.append(label)
		print("  FAIL  " + label)
