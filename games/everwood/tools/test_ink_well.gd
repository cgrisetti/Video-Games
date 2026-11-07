## The seven-card hand and the Ink-Well (24_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md
## R1, R2, R4, R5), run by tools/smoke_test.gd on Hearthstead Market's green after
## the Seal-and-Tuck checks:
##   1  the rules table: what a card costs in Ink-Drops, how deep the well is at
##      each stage (and with Wise Hand), the level each slot opens at, one title once
##   2  a live hero under the real rules (the classic full kits switched off for
##      the check): its well as deep as its level allows and full, a swing that
##      fills nothing, a refill that does, a Hearth-Brazier that fills it, R's
##      card costing what the table says, and its sockets locked and opened by level
extends RefCounted

var tree: SceneTree
var check: Callable
var level: LevelBase


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	level = tree.current_scene as LevelBase
	print("  [Ink-Well] the seven-card hand and the Ink-Well")
	_check_rules()
	await _check_live_hero()


func _frames(count: int) -> void:
	for index: int in count:
		await tree.process_frame


func _keyboard_hero() -> ActorBase:
	if level == null:
		return null
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id == InputComponent.KEYBOARD_DEVICE:
			return actor
	return null


# --- 1: the rules table ----------------------------------------------------------------

func _check_rules() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var basic: ScribeCardResource = catalog.card(ArsenalCatalog.TAUNT)
	var mid: ScribeCardResource = null
	for card: ScribeCardResource in catalog.cards():
		if card.is_lead() and card.rarity >= ScribeCardResource.CardRarity.UNCOMMON:
			mid = card
			break
	check.call(basic != null and mid != null and GrimoireRules.ink_cost(GrimoireRules.SOCKET_R, basic, false) == 1
		and GrimoireRules.ink_cost(GrimoireRules.SOCKET_R, basic, true) == 2 and GrimoireRules.ink_cost(GrimoireRules.SOCKET_L, mid, false) == 2
		and GrimoireRules.ink_cost(GrimoireRules.SOCKET_LR, basic, false) == 3,
		"Ink-Drops: a basic L or R card costs 1, a mid-tier card (%s) or a card with its Tuck 2, the L+R Grand card 3"
		% (mid.display_name if mid != null else "none"))
	check.call(GrimoireRules.well_depth(1, false) == 4 and GrimoireRules.well_depth(2, false) == 6 and GrimoireRules.well_depth(3, false) == 8
		and GrimoireRules.well_depth(4, false) == 10 and GrimoireRules.well_depth(1, true) == 5 and GrimoireRules.well_depth(2, true) == 7
		and GrimoireRules.well_depth(3, true) == 10 and GrimoireRules.well_depth(4, true) == 12,
		"the Ink-Well holds 4, 6, 8 and 10 drops at Stages 1 to 4, and 5, 7, 10 and 12 with Wise Hand")
	check.call(GrimoireRules.SEAL_OPEN_LEVELS == [3, 6, 11] and GrimoireRules.SOCKET_OPEN_LEVELS == [6, 4, 17] and GrimoireRules.TUCK_OPEN_LEVEL == 11
		and GrimoireRules.slots_open(2) == 0 and GrimoireRules.slots_open(3) == 1 and GrimoireRules.slots_open(4) == 2
		and GrimoireRules.slots_open(6) == 4 and GrimoireRules.slots_open(11) == 6 and GrimoireRules.slots_open(17) == 7,
		"the slots open by Character Level: nothing at 1 and 2, the weapon Seal at 3, R at 4, the offhand Seal and L at 6 (4 of 7), the mantle Seal and the Tuck at 11 (6), L+R at 17 (all 7)")
	var kit: EquipmentLoadoutResource = ClassLoadouts.starter_kit(ClassLoadouts.SHIELD_TANK)
	kit.guard_leaf_id = ArsenalCatalog.TAUNT
	kit.lead_ids[ScribeCardResource.GrimoireSlot.SIGNATURE] = ArsenalCatalog.TAUNT
	check.call(GrimoireRules.duplicate_title(LoadoutComposer.socket_cards(kit)) == ArsenalCatalog.TAUNT,
		"seven slots, seven different cards: Taunt in both L and R is caught")


# --- 2: a live hero under the real rules -----------------------------------------------

func _check_live_hero() -> void:
	var hero: ActorBase = _keyboard_hero()
	var seat: PartyMember = NetworkManager.current.member(hero.player_id) if hero != null else null
	if hero == null or seat == null:
		check.call(false, "a seated keyboard hero for the Ink-Well checks")
		return
	var progress: PartyProgress = PartyProgress.current
	var classic: bool = progress.endgame_kits_for_testing
	progress.endgame_kits_for_testing = false
	hero.re_equip(level._compose_for(seat))
	await _frames(2)
	var hero_level: int = progress.character_level(seat.class_id)
	var stage: int = PlayerLoadoutResource.stage_for_true_level(hero_level)
	var wise: bool = ClassLoadouts.player_class(seat.class_id, Callings.column_of(seat.calling)).bonus_memory > 0
	var depth: int = GrimoireRules.well_depth(stage, wise)
	var stats: StatsComponent = hero.stats
	stats.resonance_charge = float(stats.stats.max_resonance_pips)
	var full: float = stats.resonance_charge
	stats.resonance_charge = 1.0
	stats.add_resonance(1.0)
	var after_swing: float = stats.resonance_charge
	CombatDirector.current.refill_ink(2.0)
	await _frames(2)
	var after_refill: float = stats.resonance_charge
	CombatDirector.current.refresh_party()
	await _frames(2)
	check.call(stats.uses_ink_well() and stats.stats.max_resonance_pips == depth and is_equal_approx(full, float(depth))
		and is_equal_approx(after_swing, 1.0) and is_equal_approx(after_refill, 3.0) and is_equal_approx(stats.resonance_charge, float(depth)),
		"a Lv %d hero runs on a %d-drop Ink-Well: a swing fills nothing, a calm's refill pours 2 back, a Hearth-Brazier fills it" % [hero_level, depth])
	var r_action: CombatActionResource = hero.loadout.opener_for(CombatActionResource.Command.TRIGGER_R_SKILL)
	var r_card: ScribeCardResource = ArsenalCatalog.current.card(hero.loadout.kit.lead_ids[ScribeCardResource.GrimoireSlot.SIGNATURE])
	var tucked: bool = hero.loadout.kit.under_ids[ScribeCardResource.GrimoireSlot.SIGNATURE] != &""
	var r_cost_ok: bool = r_card == null or r_action.resonance_cost == GrimoireRules.ink_cost(GrimoireRules.SOCKET_R, r_card, tucked)
	var lr_locked: bool = hero_level >= 17 or hero.loadout.kit.lead_ids[ScribeCardResource.GrimoireSlot.ULTIMATE] == &""
	var l_open: bool = (hero_level >= 6) == (hero.loadout.kit.guard_leaf_id != &"" or seat.kit.get("guard_leaf", "") == "")
	check.call(r_cost_ok and lr_locked and l_open,
		"its R card costs what the table says (%s), L+R stays locked below Lv 17, and L opens at Lv 6" % (r_card.display_name if r_card != null else "no card"))
	progress.endgame_kits_for_testing = classic
	hero.re_equip(level._compose_for(seat))
	await _frames(2)
	check.call(not hero.stats.uses_ink_well() or not classic, "back in the classic full kit, the hero runs on the old pips again")
