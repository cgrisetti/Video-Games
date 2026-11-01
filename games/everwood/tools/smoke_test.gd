## Headless smoke test for Everwood. It starts where the game starts, in Hub
## Town, and checks every system end to end:
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
##   - the Chime-Shrine in Bramblebridge: its menu on the keyboard, upgrades for
##     the whole party, refusals, saving and loading (old "shards" saves too)
##   - the Armory & Scribe Desk: weapon, armor and card swaps in place, the
##     chest's card, under-card links and the Grimoire's memory and levels,
##     saved kits; card drops; no orphaned nodes after the round trip
## Run from games/everwood:
##   godot --headless --path . --fixed-fps 60 -s res://tools/smoke_test.gd
## Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const HUB_SCENE: String = "res://src/levels/hub_town.tscn"
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
var _portal_countdowns: int = 0
var _projectiles: Array[StringName] = []
var _invocations: Array[int] = []
## The card copy the seeded boss chest dropped (the desk test equips it).
var _dropped_card: StringName = &""
var _orphans_before: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Everwood smoke test")
	_remove_file(TEST_SAVE_PATH)
	PartyProgress.current.use_save_file(TEST_SAVE_PATH)
	change_scene_to_file(HUB_SCENE)
	await _seconds(0.2)
	_connect_global_signals()

	await _check_hub_and_input_map()
	_check_arsenal_catalog()
	_check_callings()
	await _check_keyboard_is_player_one()
	await _check_walk_over_bramblebridge()
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
	await _check_flow_cancel_and_hit_stop()
	await _check_flow_windows()
	await _check_synergies()
	await _check_ranged_and_armor()
	await _check_card_invocations()
	await _check_poise_and_knockdown()
	await _check_taunt()
	await _check_perfect_guard()
	await _check_healer()
	await _check_shadow_sanctuary()
	await _check_squire_auto_evade()
	await _check_squire_auto_guard()
	await _check_soak_scaling()
	await _check_telegraphs()
	await _check_wipe_resets_fight()
	await _check_companion_backfill()
	await _check_victory_and_loot()
	await _check_chime_shrine()
	await _check_scribe_desk()
	await _check_calling_shortcut_and_fellowship()
	_check_audio_cues()
	NetworkManager.current.leave_game()
	_remove_file(TEST_SAVE_PATH)

	print("%d passed, %d failed" % [_passes, _failures.size()])
	if not _failures.is_empty():
		print("FAILED: " + "; ".join(_failures))
	quit(0 if _failures.is_empty() else 1)


# --- Hub Town, Input Map, hot-join ----------------------------------------

func _check_hub_and_input_map() -> void:
	_check(current_scene is HubTown, "the game starts in Bramblebridge (Hub Town)")
	_check(ProjectSettings.get_setting("application/run/main_scene") == HUB_SCENE, "Hub Town is the main scene")
	_check(InstanceManager.current.instance_id == InstanceManager.HUB_TOWN and InstanceManager.current.is_live(), "Hub Town is the live instance")
	var hub: HubTown = current_scene as HubTown
	_check(hub.level_title() == "Bramblebridge" and hub.raid_portal.title.contains("Cairnsman"),
		"the hub is Bramblebridge, and its Raid Portal leads to the Ring of the Cairnsman")
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
	_check(catalog.armors().size() == 3 and catalog.weapons().size() == 4 and starters == 12 and boss_cards >= 4 and catalog.under_cards().size() == 4,
		"the Arsenal holds 3 armors, 4 weapons, 12 starter lead cards, %d boss cards and 4 under-cards" % boss_cards)
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
			and is_equal_approx(stats.stamina_regen_per_sec, expected[1] + Callings.STOUT_STAMINA_REGEN) \
			and is_equal_approx(stats.roll_distance, expected[2]) and is_equal_approx(stats.perfect_guard_window, expected[3] + Callings.STOUT_PERFECT_GUARD)
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
		"Hunter Bow: 14 m snap-shots, an 18 m piercing draw, cards as 18 m rune arrows (forward lunges planted, back steps kept)")

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
	_check(seen_variants.has(ScribeCardResource.CardVariant.SHINY_FOIL) and seen_variants.has(ScribeCardResource.CardVariant.ASTRAL_PRISM) and rare_seen and not plain_starter,
		"boss chests drop Rare and Legendary cards and Gilded Leaf or Star-Inked Vellum copies (never a Plain Vellum starter card)")


## The 3x3 Callings (06 §3, 07 GDD §1.3), without actors: the nine names,
## each Secondary's numbers, the gear it unlocks, and the roster carrying it.
func _check_callings() -> void:
	var names: Array[String] = []
	for class_id: StringName in Callings.FELLOWSHIP_CLASSES:
		for secondary: int in Callings.SECONDARY_NAMES.size():
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
		"on a 160-health Shield-Sworn in plate: Stout Heart +20 health and -2 stamina/s, Swift Foot +3 stamina/s, Wise Hand -5 health and +2 stamina/s")
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
		"heavy plate waits for a Stout Heart: a Hedge-Runner can't wear it, an Iron-Woodsman can")
	var staff_kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	staff_kit.weapon_id = ArsenalCatalog.SCRIBE_STAFF
	_check(LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK), staff_kit, 1, empty_binder).contains("Wise Hand")
		and LoadoutComposer.kit_problem(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK, Callings.Secondary.WISE_HAND), staff_kit, 1, empty_binder) == "",
		"a staff needs a Wise Hand: a Hearth-Guard may bear one")
	_check(LoadoutComposer.sanitized(ClassLoadouts.player_class(ClassLoadouts.SHIELD_TANK), axe_kit).weapon_id == ArsenalCatalog.LIGHT_SWORD,
		"a save naming gear the Calling can't use falls back to the starter weapon")
	var seat: PartyMember = PartyMember.new()
	seat.class_id = ClassLoadouts.SOUL_TETHER_HEALER
	seat.calling = Callings.Secondary.SWIFT_FOOT
	_check(PartyMember.from_dict(seat.to_dict()).calling == Callings.Secondary.SWIFT_FOOT, "a seat's Calling travels in the party roster")


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
	_check(ScribeCardResource.VARIANT_NAMES == ["Plain Vellum", "Gilded Leaf", "Star-Inked Vellum"]
		and catalog.copy_name(&"moonfall_cleave:shiny_foil") == "Moonfall Cleave (Rare, Gilded Leaf)",
		"card finishes read as Plain Vellum, Gilded Leaf and Star-Inked Vellum")
	_check(ScribeCardResource.copy_variant(&"gale_rush:astral_prism") == ScribeCardResource.CardVariant.ASTRAL_PRISM,
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
	_check(walker.global_position.z <= canal_z - 7.0, "walking north on the stick crosses Bramblebridge to the square (%.1f s)" % waited)
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
	_check(network.member(_pad_id(1)).class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS, "a quick tap of View / Create doesn't change class")
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
	_check(current_scene is DungeonDojo and InstanceManager.current.instance_id == InstanceManager.DUNGEON_DOJO, "the portal moves the party into the Ring of the Cairnsman")
	var ring: DungeonDojo = current_scene as DungeonDojo
	_check(ring.level_title() == "The Doverslap Expedition" and ring.boss.display_name() == "The Cairnsman of Doverslap"
		and ring.exit_portal.title == "Exit: Bramblebridge", "the raid is the Doverslap Expedition, its boss the Cairnsman of Doverslap, its exit to Bramblebridge")
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


# --- The Doverslap Expedition (07 GDD §3) ---------------------------------

## Zone 1's ramp, lanterns, camps, shrine and chest; Zone 2's checkpoint, gale
## and Co-Op Threshold opened every way (two players on the plates, a tank's
## shelter and the bell, a companion taking the second plate); then Zone 3.
func _check_doverslap_expedition() -> void:
	var network: NetworkManager = NetworkManager.current
	var progress: PartyProgress = PartyProgress.current
	_check(dojo.zone == 1 and tank.global_position.z > 70.0 and boss.global_position.distance_to(tank.global_position) > 100.0 and not boss.engaged,
		"the party arrives in Zone 1, the Ariundle Moss-Oaks, far from the Cairnsman, who waits unwoken")
	_check(not (dojo.huds[tank.player_id] as PlayerHUD).boss_bar_visible(), "his health bar stays hidden until the party nears him")
	var camp_one: MinionCamp = dojo.camps[0]
	var camp_two: MinionCamp = dojo.camps[1]
	var built_right: bool = camp_one.minions.size() == 3 and camp_two.minions.size() == 4
	for camp: MinionCamp in dojo.camps:
		for minion: WoodlandMinion in camp.minions:
			built_right = built_right and is_equal_approx(minion.stats.stats.max_health, 65.0) and is_equal_approx(minion.stats.stats.max_poise, 30.0) \
				and minion.is_boss() and not minion.is_raid_boss() and not minion.is_engaged()
	_check(built_right and CombatDirector.current.primary_boss() == boss and CombatDirector.current.enemies().size() == 8,
		"two sleeping woodland camps (3 Bramble-Scuttlers; 3 Holloway Imps and a Scuttler), 65 health and 30 poise each, and the boss is still the boss")
	# Down the holloway on the stick alone: a real 1.8 m ramp, no jump.
	dps.place_at(Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 48.0)))
	dps.input.inject_move(Vector2(0.0, 1.0))
	var waited: float = 0.0
	while waited < 4.0 and dps.global_position.z > 37.5:
		await physics_frame
		waited += 1.0 / 60.0
	dps.input.inject_move(Vector2.ZERO)
	await _seconds(0.2)
	_check(dps.global_position.z <= 37.5 and dps.global_position.y < -1.5 and dps.is_on_floor(), "walking down the ramp into the Sunken Holloway, six feet below the oaks")
	var lantern: WindLantern = dojo.get_node(^"WindLanterns/WindLantern1") as WindLantern
	# The DPS brushed this one on the way down; let it settle first.
	await _seconds(WindLantern.COOLDOWN + 0.1)
	var lantern_chimes: int = lantern.chimes
	healer.place_at(Transform3D(Basis.IDENTITY, Vector3(lantern.global_position.x, -0.5, lantern.global_position.z)))
	await _seconds(0.2)
	_check(lantern.chimes > lantern_chimes and _audio_cues.has(&"lantern"), "brushing past a clay Wind-Lantern makes it chime")
	# The Bramble Camp wakes, a bow shot finds a Scuttler, and clearing it pays Chimes.
	tank.place_at(Transform3D(Basis.IDENTITY, camp_one.global_position + Vector3(0.0, 0.0, 3.0)))
	_face_point(dps, camp_one.global_position, Vector3(0.0, 0.0, 10.0))
	await _seconds(0.3)
	var all_awake: bool = camp_one.alert
	for minion: WoodlandMinion in camp_one.minions:
		all_awake = all_awake and minion.is_engaged()
	_check(all_awake and not camp_two.alert, "walking up wakes the whole Bramble Camp (and only that camp)")
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
		"reaching the Doverslap Gorge moves everyone's respawn to its checkpoint")
	dps.place_at(Transform3D(Basis.IDENTITY, gate.to_global(Vector3(0.0, 0.0, 6.0))))
	await _seconds(0.1)
	var start_z: float = dps.global_position.z
	_check(gate.gale.blast() >= 1, "the Gorge Gale-Jet blows down the lane")
	await _seconds(0.6)
	_check(dps.global_position.z > start_z + 3.0, "and shoves an exposed player back down the bridge")
	_check(CoopGate.plates_needed(1) == 1 and CoopGate.plates_needed(3) == 2 and CoopGate.plates_needed(5) == 2, "the gate needs min(2, party) Rune-Plates")
	# Way one: two players on the plates.
	tank.place_at(Transform3D(Basis.IDENTITY, gate.plates[0].global_position))
	dps.place_at(Transform3D(Basis.IDENTITY, gate.plates[1].global_position))
	await _seconds(CoopGate.PLATE_HOLD_TIME + 0.3)
	_check(gate.is_open and gate.opened_by == CoopGate.Method.RUNE_PLATES and not gate.gale.active,
		"two players holding both Rune-Plates for 2 s open the portcullis, and the gale dies away")
	gate.reset_gate()
	dps.place_at(Transform3D(Basis.IDENTITY, Vector3(6.0, 0.0, 11.0)))
	await _seconds(CoopGate.PLATE_HOLD_TIME + 0.5)
	_check(not gate.is_open, "one plate alone doesn't open it for a party of three")
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
	_check(gate.is_open and gate.opened_by == CoopGate.Method.RUNE_PLATES, "in solo play a companion walks to the second Rune-Plate and the gate opens (%.1f s)" % waited)
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


## Puts an actor at `target + offset`, facing the target.
func _face_point(actor: ActorBase, target: Vector3, offset: Vector3) -> void:
	var where: Vector3 = target + offset
	var to_target: Vector3 = target - where
	to_target.y = 0.0
	actor.place_at(Transform3D(Basis.looking_at(to_target.normalized(), Vector3.UP), where))


# --- The Cross-Grimoire HUD (07 GDD §2) -----------------------------------

## Each player's cross: the right card in each slot, tinted by its Sign, dipped
## until there are pips for it and popping up gold when there are, pulsing when
## pressed; no line of control help along the bottom.
func _check_cross_grimoire_hud() -> void:
	var hud: PlayerHUD = dojo.huds[tank.player_id]
	var cross: CrossGrimoireHUD = hud.cross_grimoire
	_check(cross != null and not hud.has_method("controls_text"), "the HUD is a Cross-Grimoire, and the old line of control help is gone")
	var north: CrossSlot = cross.slot_for_command(Cmd.FORWARD_HEAVY)
	var south: CrossSlot = cross.slot_for_command(Cmd.BACK_HEAVY)
	var east: CrossSlot = cross.slot_for_command(Cmd.TRIGGER_R_SKILL)
	var crown: CrossSlot = cross.slot_for_command(Cmd.TRIGGER_BOTH_ULT)
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var forward: CombatActionResource = tank.loadout.card_action(ScribeCardResource.GrimoireSlot.FORWARD)
	_check(north.title == forward.display_name and south.title == tank.loadout.card_action(1).display_name
		and east.title == tank.loadout.card_action(2).display_name and crown.title == tank.loadout.card_action(3).display_name,
		"north, south, east and the crown hold the Forward, Back, Signature and Ultimate cards")
	_check(north.key_text == "W+K" and south.key_text == "S+K" and east.key_text == "E" and crown.key_text.contains("Q+E"),
		"each slot names its keys: W+K, S+K, E, and R or Q+E for the ultimate")
	_check(north.sign_color == catalog.sign_seal(forward.scribe_sign).color and north.tag_text == "IRON-ROOT" and east.pip_cost == 1 and crown.pip_cost == 3,
		"each card frame is tinted by its Sign (Shield Charge in Iron-Root amber), with its pip cost as gems")
	_check(cross.guard_slot.title == "Guard" and cross.slot_for_command(Cmd.LIGHT).title == tank.loadout.weapon.display_name
		and cross.slot_for_command(Cmd.LIGHT).subtitle.contains("Greatshield"), "the west wing is the Guard, the centre the weapon and the Shield-Sworn's greatshield")
	var pips_before: float = tank.stats.resonance_charge
	tank.stats.resonance_charge = 0.0
	await _seconds(0.5)
	_check(not east.is_ready and is_equal_approx(east.lift(), CrossSlot.UNREADY_DROP) and is_equal_approx(east.modulate.a, CrossSlot.UNREADY_ALPHA)
		and north.is_ready and is_equal_approx(north.lift(), 0.0), "without a pip, Taunt sits dimmed and 6 px low while the free Shield Charge stands ready")
	tank.stats.add_resonance(1.0)
	await _seconds(0.5)
	_check(east.is_ready and east.lift() < 0.1 and not crown.is_ready, "one pip earned: Taunt slides up gold, the 3-pip ultimate still waits")
	tank.stats.resonance_charge = pips_before
	var dps_cross: CrossGrimoireHUD = (dojo.huds[dps.player_id] as PlayerHUD).cross_grimoire
	await _until_idle(dps)
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.FORWARD_HEAVY)
	await physics_frame
	await physics_frame
	_check(dps_cross.slot_for_command(Cmd.FORWARD_HEAVY).is_pulsing(), "pressing Forward + heavy pulses the DPS's north slot")
	tank.input.inject_guard(true)
	await _seconds(0.15)
	_check(cross.guard_slot.lit, "raising the guard lights the Guard wing")
	tank.input.inject_guard(false)
	var healer_cross: CrossGrimoireHUD = (dojo.huds[healer.player_id] as PlayerHUD).cross_grimoire
	_check(healer_cross.actor.tether != null and healer_cross.slot_for_command(Cmd.LIGHT).subtitle.contains("Tether-Lantern"),
		"a Lantern-Bearer's cross carries the Tether-Lantern and the Soul Tether compass")
	_check(is_equal_approx(CrossGrimoireHUD.scale_for(Vector2(1600.0, 900.0)), CrossGrimoireHUD.BASE_SCALE)
		and is_equal_approx(CrossGrimoireHUD.scale_for(Vector2(800.0, 450.0)), CrossGrimoireHUD.MIN_SCALE),
		"the cross scales with the split-screen cell, down to a floor for four players")
	await _until_idle(dps)


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
		"the healer's Sunlit Lance card flies through the staff as a rune bolt and hits from 8 m")
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
	_check(_perfect_guards == guards + 1, "Ironwood Plate's 260 ms window, +30 ms for a Stout Heart: a guard raised 0.27 s early is still perfect")
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
		"in Ranger Leather (200 + 30 ms) the same guard is too early: it just blocks")
	tank.input.inject_guard(false)
	tank.re_equip(ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK))
	await _seconds(0.1)

	dps.stats.heal(dps.stats.stats.max_health)
	var dps_health: float = dps.stats.health
	CombatDirector.current.deliver(_strike(boss, dps, 50.0, 0.0))
	await _seconds(0.05)
	_check(is_equal_approx(dps_health - dps.stats.health, 50.0 * (1.0 - 0.20)), "Ranger Leather takes 20% off a 50-damage hit")
	dps.stats.heal(dps.stats.stats.max_health)
	var light_roll: float = await _measure_roll(dps, ArsenalCatalog.HEARTH_LINEN)
	var heavy_roll: float = await _measure_roll(dps, ArsenalCatalog.IRONWOOD_PLATE)
	dps.re_equip(ClassLoadouts.compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS))
	_check(light_roll > heavy_roll + 1.0, "Hearth-Linen rolls farther than Ironwood Plate (%.1f m against %.1f m)" % [light_roll, heavy_roll])

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
	var foil: ScribeInvocationFX = await _charge_with(ScribeCardResource.CardVariant.SHINY_FOIL)
	_check(foil != null and foil.is_showing_foil() and _audio_cues.count(&"card_chime_foil") > foil_chimes,
		"a Gilded Leaf copy adds two counter-rotating gold rings and a brighter chime")
	await _seconds(tank.loadout.card_action(0).windup_time)
	_check(tank.trail.is_swinging() and tank.trail.colour().is_equal_approx(Color(WeaponTrail.SHINY_COLOR, WeaponTrail.TRAIL_ALPHA)),
		"and its sword swings a gold ribbon trail")
	await _seconds(1.0)

	var astral: ScribeInvocationFX = await _charge_with(ScribeCardResource.CardVariant.ASTRAL_PRISM)
	_check(astral != null and astral.is_showing_dome(), "a Star-Inked Vellum copy raises a starfield dome through the wind-up")
	await _seconds(0.8)
	_check(_active_footprints() >= 2, "and the charge leaves glowing footprints behind the tank")
	await _seconds(ScribeInvocationFX.FOOTPRINT_TIME)
	_check(astral != null and not astral.in_use, "the Star-Inked flourish lasts 2.5 s, then goes back to the pool")

	var shiny_kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	shiny_kit.lead_variants[0] = ScribeCardResource.CardVariant.SHINY_FOIL
	var shiny_charge: CombatActionResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK, shiny_kit).card_action(0)
	var plain_charge: CombatActionResource = ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK).card_action(0)
	_check(is_equal_approx(shiny_charge.damage, plain_charge.damage) and shiny_charge.action_id == plain_charge.action_id,
		"finishes change the look only: a Gilded Leaf Shield Charge hits exactly as hard")
	tank.re_equip(ClassLoadouts.compose(ClassLoadouts.SHIELD_TANK))

	await _until_idle(dps)
	_face_boss(dps, Vector3(0.0, 0.0, 9.0))
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.BACK_HEAVY)
	await _seconds(0.05)
	var shot_fx: ScribeInvocationFX = _active_invocation(dps)
	_check(shot_fx != null and shot_fx.is_showing_muzzle_ring(), "a card fired through the bow charges through a standing rune ring first")
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
		driven = driven and bot.companion != null and bot.input == null and bot.display_name().ends_with("(bot)")
	_check(driven, "each is driven by a CompanionAIComponent and labelled as a bot")
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
	_check(current_scene is HubTown, "the gold portal brings the party back to Bramblebridge")
	_check(root.multiplayer.multiplayer_peer == session and NetworkManager.current.is_online(), "still the same ENet session after the round trip")
	_check(NetworkManager.current.party_size() == 3 and _hub().grid.view_count() == 3, "the whole party is back in town")
	await _seconds(0.2)
	var orphans: int = _orphan_count()
	_check(orphans <= _orphans_before, "no orphaned nodes after Bramblebridge, the Ring and back (%d before, %d after)" % [_orphans_before, orphans])


func _check_audio_cues() -> void:
	var silent: PackedStringArray = PackedStringArray()
	for cue: StringName in AudioCues.CUES:
		if AudioCues.current.stream_for(cue).data.size() < 200:
			silent.append(cue)
	_check(silent.is_empty(), "every audio cue synthesizes %s" % ("" if silent.is_empty() else str(silent)))
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
	_check(NetworkManager.current.companion_seats().is_empty() and hub.actors.size() == 1, "companions only join raids, not Bramblebridge")


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
	_check(is_equal_approx(keyboard.base_stats.max_health, 160.0) and is_equal_approx(keyboard.loadout.stats.stamina_regen_per_sec / PartyProgress.current.multiplier(PartyProgress.STAMINA_REGEN), 18.0 + Callings.SWIFT_STAMINA_REGEN),
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
		"A on the Armor row trades Ironwood Plate for Ranger Leather (and its 200 ms window)")
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
		and is_equal_approx(surged.damage, 20.0 * LoadoutComposer.UNDER_POTENCY_MULTIPLIER * Callings.SWIFT_STRIKE_DAMAGE),
		"back on the Basic Shield Charge the link fits: Iron-Root Link surges it by 20% (and the Swift Foot's 15% on top)")
	for press: int in 5:
		await _tap_key(KEY_S)
	await _tap_key(KEY_D)
	_check(menu.problem().contains("opens at Grimoire Lv 3") and keyboard.loadout.kit.under_ids[1] == &"", "link 2 stays locked until Grimoire Lv 3")
	await _tap_key(KEY_SPACE)
	_check(hud.scribe_desk_menu() == null and not keyboard.input.menu_open, "Space closes the desk")
	var saved: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(PartyProgress.current.kit_for(ClassLoadouts.SHIELD_TANK))
	_check(saved.same_as(keyboard.loadout.kit) and PartyProgress.current.calling_for(ClassLoadouts.SHIELD_TANK) == Callings.Secondary.SWIFT_FOOT,
		"the tank's new kit and Calling are saved for the next session")
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
	_check(lantern.loadout.display_name == "Lantern-Scribe" and lantern.display_name() == "P1 Lantern-Scribe", "a new Lantern-Bearer starts as a Lantern-Scribe")
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
