## The Seal-and-Tuck Grimoire's 3-Stage Verification Suite
## (docs/everwood_equipment_grimoire_architecture.md Part II §6.8), run by
## tools/smoke_test.gd after the Phase 12 Kaizen checks (the party stands in
## the Caldera Isles) and on its own by tools/run_equipment_grimoire_checks.gd:
##   Stage 1  the Philological Linter gate: exactly seven material tiers, four
##            armaments and four seal cards, every name of the master table on
##            them, and not one of Gate 3's banned words among them (nor the
##            Lens's); the older arsenal untouched (13 starters, 20 weapons)
##   Stage 2  the maths and progression gate: a Lv 1 Orchard-Stick's 2 and 3
##            (the mallet's 3 and 4, the bough's 2 and 3, the crook's 2 and a
##            3 mend), the Quiet Weir on a Forge-Iron buckler (46 of a 100
##            Star-Tide blow, unstunned; 81 of Iron-Root), Renown 40 <-> True
##            Level 20, the shader floats of all seven tiers, the four stages
##            and the hands they open, a Tier 7 blade's 78 to 108 under the
##            Ember-Bough, a Tier 7 party's 35-50 s cadence on the Elder
##            Cairn-Drake's 1,200 posture and a stick's 12-15 s on a Bramble-Mite
##   Stage 3  the split-screen and network gate: the live hero's hand by level,
##            the Wingfeather youth rig, the seal materials on one set of
##            meshes across seven tiers, the Seal Ledger under 8% of the cell
##            with the cross still four diamonds, a Pocket-Pull that leaves
##            every Camera3D untouched and flips the ledger's card, a ward on a
##            Star-Tide blow in play, the posture gate by stage, the Gambit
##            Assist, and a 7-card hand that crosses the network as Strings and ints
extends RefCounted

const Slot = PlayerLoadoutResource.TriggerSlot
const Arch = EquipmentTierResource.WeaponArchetype
## The Google Doc's master table (§2): weapon material, then heavy, medium and light armour.
const TIER_NAMES: Array[Array] = [
	["Orchard-Wood", "Oak-Bark & Boiled-Hide", "Bracken-Pelt Jerkin", "Mended-Linen Smock"],
	["Bog-Bronze", "Kettle-Link Coat", "Boiled-Buckskin Coat", "Orchard-Wool Mantle"],
	["Forge-Iron", "Forge-Plate Harness", "Briar-Studded Brigandine", "Nettle-Weave Mantle"],
	["Barrow-Steel", "Barrow-Mail & Pauldrons", "Firth-Seal Coat", "Moth-Silk Mantle"],
	["Rime-Silver", "Rime-Clad Plate", "Frost-Stag Pelt-Coat", "Gossamer-Spun Mantle"],
	["Saffron-Gold", "Cairn-Scale Great-Plate", "Wyrm-Hide Coat", "Sun-Loomed Mantle"],
	["Star-Glass & Heart-Crag", "Heart-Crag & Ember-Clad Plate", "Gale-Drake Scale-Coat", "Star-Ink Great-Mantle"],
]
## Armor Guard by weight (heavy, medium, light) and the tier's Light blow and rank.
const TIER_GUARDS: Array[Array] = [[8, 5, 3], [16, 12, 8], [24, 18, 13], [32, 24, 18], [40, 30, 23], [46, 35, 27], [52, 40, 32]]
const TIER_LIGHTS: Array[float] = [2.4, 5.5, 9.5, 14.5, 20.5, 27.5, 36.0]
const TIER_RANKS: Array[int] = [0, 3, 6, 10, 13, 16, 20]
## The recipe table (§2): albedo, metallic, roughness, rim strength, rim tint, emissive pulse.
const TIER_RECIPES: Array[Array] = [
	["#7A5438", 0.00, 0.88, 0.18, "#D2B48C", 0.00],
	["#9E6B3B", 0.72, 0.46, 0.25, "#F4A460", 0.00],
	["#5E666E", 0.85, 0.38, 0.30, "#B0C4DE", 0.00],
	["#8A99AD", 0.90, 0.28, 0.38, "#C9D6E3", 0.04],
	["#C9E2F2", 0.94, 0.20, 0.52, "#E0FFFF", 0.08],
	["#E5B546", 0.96, 0.16, 0.65, "#FFFACD", 0.15],
	["#3D355E", 0.98, 0.12, 0.85, "#9370DB", 0.55],
]
const HOMESTEAD_NAMES: Array[String] = ["Orchard-Stick & Bark-Buckler", "Cooper's Cider-Mallet", "Bent-Twig Bough & Reed-Shafts", "Rowan-Crook & Tallow-Jar"]
## The Google Doc's four seals, in SEAL_CARD_IDS order (ids keep the Seal-and-Tuck branch's spellings).
const SEAL_NAMES: Array[String] = ["Ebb-Quay Star-Bell", "Cider-Hearth Ember", "Old-Hob's Root-Bind", "Firth-Squall Feather"]
## The split-screen cells the ledger must fit under 8% of: one, two (either way) and four players.
const CELLS: Array[Vector2] = [Vector2(1600.0, 900.0), Vector2(800.0, 900.0), Vector2(1600.0, 450.0), Vector2(800.0, 450.0), Vector2(640.0, 360.0)]

var tree: SceneTree
var check: Callable
var level: LevelBase


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	level = tree.current_scene as LevelBase
	var seals_were: bool = EquipmentSealComponent.enabled
	var gate_was: bool = EquipmentSealComponent.graduated_apm_enabled
	EquipmentSealComponent.enabled = true
	EquipmentSealComponent.graduated_apm_enabled = false
	print("  [Gate 1/3] the Philological Linter")
	_stage_1_philological_linter_gate()
	print("  [Gate 2/3] the maths and the progression ladder")
	_stage_2_math_and_stagger_cadence_gate()
	print("  [Gate 3/3] the split-screen and the network")
	await _stage_3_split_screen_and_network_schema_gate()
	EquipmentSealComponent.graduated_apm_enabled = gate_was
	EquipmentSealComponent.enabled = seals_were


# --- Helpers --------------------------------------------------------------------------

func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds * 60.0)))


func _keyboard_hero() -> ActorBase:
	if level == null:
		return null
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and actor.input != null and actor.input.device_id == InputComponent.KEYBOARD_DEVICE:
			return actor
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player():
			return actor
	return null


static func _hand(tier_id: StringName, archetype: int = Arch.WEAPON_SWORD_BOARD) -> PlayerLoadoutResource:
	var hand: PlayerLoadoutResource = PlayerLoadoutResource.new()
	hand.equipped_tier_id = tier_id
	hand.weapon_archetype = archetype
	return hand


## The doc's endgame raid hand: three seals and four invocations.
static func _raid_hand() -> PlayerLoadoutResource:
	var hand: PlayerLoadoutResource = _hand(ArsenalCatalog.TIER_7_STAR_GLASS)
	hand.weapon_seal_card_id = ArsenalCatalog.CARD_EMBER_BOUGH
	hand.offhand_seal_card_id = ArsenalCatalog.CARD_QUIET_WEIR
	hand.mantle_seal_card_id = ArsenalCatalog.CARD_OLD_ROOT_BASTION
	hand.slot_l_primary_id = ArsenalCatalog.CARD_QUIET_WEIR
	hand.slot_l_tuck_id = ArsenalCatalog.CARD_WEST_WIND_PROMISE
	hand.slot_r_primary_id = ArsenalCatalog.CARD_EMBER_BOUGH
	hand.slot_r_tuck_id = ArsenalCatalog.CARD_OLD_ROOT_BASTION
	return hand


# --- Stage 1: the Philological Linter gate ----------------------------------------------------

func _stage_1_philological_linter_gate() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var tiers: Array[EquipmentTierResource] = catalog.get_all_tiers()
	var ids_ok: bool = tiers.size() == EquipmentTierResource.TIER_COUNT
	var names_ok: bool = tiers.size() == TIER_NAMES.size()
	var bands_ok: bool = true
	for index: int in mini(tiers.size(), TIER_NAMES.size()):
		var tier: EquipmentTierResource = tiers[index]
		ids_ok = ids_ok and tier.tier_id == ArsenalCatalog.MATERIAL_TIER_IDS[index] and tier.tier_index == index + 1
		names_ok = names_ok and Array(tier.display_names()).slice(0, 4) == TIER_NAMES[index] and tier.weapon_names.size() == 4 \
			and tier.offhand_names.size() == 4 and is_equal_approx(tier.base_light_damage, TIER_LIGHTS[index]) \
			and tier.gear_threat_rank == TIER_RANKS[index] and tier.armor_guard_percent(0) == TIER_GUARDS[index][0] \
			and tier.armor_guard_percent(1) == TIER_GUARDS[index][1] and tier.armor_guard_percent(2) == TIER_GUARDS[index][2]
		bands_ok = bands_ok and tier.min_true_level <= tier.max_true_level and tier.min_renown_rank <= tier.max_renown_rank \
			and tier.max_renown_rank <= ArsenalCatalog.MAX_RENOWN_RANK
	check.call(ids_ok, "exactly seven material tiers, TIER_1_HOMESTEAD to TIER_7_STAR_GLASS, numbered 1 to 7")
	check.call(names_ok, "the Google Doc's ladder stands on the seven tiers: its 28 material and armour names (Tier 7's mantle reads Star-Ink, by Gate 6), four arms and four offhands a tier (the maul's Pommel-Knot), Light 2.4 to 36.0, ranks +0 to +20, Armor Guard 8/5/3% to 52/40/32%")
	check.call(bands_ok and tiers[0].true_level_band() == Vector2i(1, 4) and tiers[3].true_level_band() == Vector2i(11, 13)
		and tiers[6].true_level_band() == Vector2i(20, 20) and tiers[6].renown_rank_band() == Vector2i(38, 40)
		and tiers[6].weapon_name(Arch.WEAPON_SWORD_BOARD) == "Star-Glass Steward-Blade & Heart-Crag Bulwark"
		and tiers[0].offhand_name(Arch.WEAPON_GREAT_MALLET) == "Oak-Knot Pommel",
		"every tier's level and Threat bands run Lv 1-4 / Threat 1-7 up to Lv 20 / Threat 38-40; Tier 7's shield is the Heart-Crag Bulwark, the Orchard maul seals its Oak-Knot Pommel")
	var arms: Array[WeaponArchetypeResource] = catalog.weapon_archetypes()
	var arms_ok: bool = arms.size() == 4
	for index: int in mini(arms.size(), 4):
		arms_ok = arms_ok and arms[index].archetype_id == ArsenalCatalog.WEAPON_ARCHETYPE_IDS[index] and arms[index].archetype == index \
			and arms[index].homestead_name == HOMESTEAD_NAMES[index]
	check.call(arms_ok and catalog.archetype_for_weapon_type(EquipmentItemResource.WeaponType.HEAVY_AXE).archetype == Arch.WEAPON_GREAT_MALLET
		and catalog.archetype_for_weapon_type(EquipmentItemResource.WeaponType.BOW).archetype == Arch.WEAPON_BOUGH_BOW
		and catalog.archetype_for_weapon_type(EquipmentItemResource.WeaponType.STAFF).archetype == Arch.WEAPON_LANTERN_STAFF,
		"four base armaments with their Tier 1 homestead arms, each channelled by its trail weapon type")
	var seals: Array[ScribeCardResource] = catalog.seal_cards()
	var seals_ok: bool = seals.size() == 4
	var not_leads: bool = true
	for index: int in mini(seals.size(), 4):
		var seal: ScribeCardResource = seals[index]
		seals_ok = seals_ok and seal.card_id == ArsenalCatalog.SEAL_CARD_IDS[index] and seal.display_name == SEAL_NAMES[index] \
			and seal.can_stamp_into_slot(ScribeCardResource.SealSlotMask.SEAL_WEAPON) and seal.can_stamp_into_slot(ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR) \
			and seal.passive_ward_sign == ScribeSignResource.id_of(seal.scribe_sign) and seal.resonance_pip_cost == 1 and seal.drop_weight == 0.0
		not_leads = not_leads and not seal.is_lead() and not seal.is_under() and not seal.is_place_card() and not seal.is_action_leaf()
	var slot_rule: bool = true
	for seal: ScribeCardResource in seals:
		var on_weapon: Dictionary = seal.slot_passive(ScribeCardResource.SealSlotMask.SEAL_WEAPON)
		var on_mantle: Dictionary = seal.slot_passive(ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR)
		slot_rule = slot_rule and seal.slot_passives.size() == 3 and is_equal_approx(float(on_mantle["ward"]), 0.20) and bool(on_mantle["stun"]) \
			and float(on_weapon["ward"]) == 0.0 and String(on_weapon["text"]) != String(on_mantle["text"])
	check.call(seals_ok and slot_rule, "four seal cards, the Ebb-Quay Star-Bell, the Cider-Hearth Ember, Old-Hob's Root-Bind and the Firth-Squall Feather, each stampable on any piece; each does a different job on each piece (the Contextual Slot Rule): -20% of its Sign and no stun on the mantle, none of that on the blade")
	var starters: int = 0
	for card: ScribeCardResource in catalog.cards():
		if card.is_lead() and card.starter:
			starters += 1
	check.call(not_leads and starters == 13 and catalog.weapons().size() == 20 and catalog.under_cards().size() == 4 and catalog.lead_cards(2).size() >= 3,
		"the seal cards are a kind of their own: the 13 starters, 20 weapons, 4 under-cards and the Grimoire slots' choices are as they were")
	# Gate 3: the doc's banned words (and the Lens's) off every name a player reads here.
	var shown: PackedStringArray = PackedStringArray()
	for tier: EquipmentTierResource in tiers:
		shown.append_array(tier.display_names())
		shown.append(tier.unlock_source)
	for arm: WeaponArchetypeResource in arms:
		shown.append_array(PackedStringArray([arm.homestead_name, arm.homestead_blurb, arm.teaching_goal, arm.calling_label, arm.frame_noun]))
	for seal: ScribeCardResource in seals:
		shown.append_array(PackedStringArray([seal.display_name, seal.description, String(seal.deep_ink_script_id), String(seal.active_action_id)]))
	var elder: BossEncounterResource = catalog.encounter(ArsenalCatalog.ELDER_CAIRN_DRAKE)
	if elder != null:
		shown.append_array(PackedStringArray([elder.display_name, elder.hud_rhyme_couplet]))
	var offenders: PackedStringArray = PackedStringArray()
	for text: String in shown:
		var lowered: String = text.to_lower()
		for banned: String in ArsenalCatalog.BANNED_LINTER_WORDS:
			if lowered.contains(banned):
				offenders.append("%s (%s)" % [text, banned])
	check.call(offenders.is_empty() and shown.size() >= 49,
		"Gate 3: none of %d tier, armament and seal names says construct, rune, aspect, wharf, silt, lamellar, hauberk, rubric, platinum or the like%s"
		% [shown.size(), "" if offenders.is_empty() else " (found: %s)" % "; ".join(offenders)])
	check.call(elder != null and elder.encounter_level == ArsenalCatalog.MAX_TRUE_LEVEL and elder.is_four_gate_boss()
		and ArsenalCatalog.compute_renown_from_true_level(elder.encounter_level) == 40 and elder.is_countered_by(ScribeSignResource.Sign.SIGN_STAR_TIDE),
		"the Elder Cairn-Drake is registered at True Level 20, so its plate reads Rank 40, a four-gate boss Star-Tide counters")


# --- Stage 2: the maths and progression gate --------------------------------------------------

func _stage_2_math_and_stagger_cadence_gate() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var stick: PlayerLoadoutResource = _hand(ArsenalCatalog.TIER_1_HOMESTEAD)
	var mallet: PlayerLoadoutResource = _hand(ArsenalCatalog.TIER_1_HOMESTEAD, Arch.WEAPON_GREAT_MALLET)
	var bough: PlayerLoadoutResource = _hand(ArsenalCatalog.TIER_1_HOMESTEAD, Arch.WEAPON_BOUGH_BOW)
	var crook: PlayerLoadoutResource = _hand(ArsenalCatalog.TIER_1_HOMESTEAD, Arch.WEAPON_LANTERN_STAFF)
	var tier_1: EquipmentTierResource = catalog.get_tier(ArsenalCatalog.TIER_1_HOMESTEAD)
	check.call(is_equal_approx(tier_1.get_weapon_damage(false, Arch.WEAPON_SWORD_BOARD), 2.4) and is_equal_approx(tier_1.get_weapon_damage(true, Arch.WEAPON_SWORD_BOARD), 3.5)
		and catalog.evaluate_hit_damage(stick, false, false) == 2 and catalog.evaluate_hit_damage(stick, true, false) == 4,
		"a Lv 1 Orchard-Wood Stick deals 2.4 light and 3.5 heavy (2 and 4 a blow)")
	check.call(is_equal_approx(tier_1.get_weapon_damage(false, Arch.WEAPON_GREAT_MALLET), 3.0) and catalog.evaluate_hit_damage(mallet, false, false) == 3
		and catalog.evaluate_hit_damage(bough, false, false) == 2 and catalog.evaluate_hit_damage(crook, false, false) == 2
		and is_equal_approx(tier_1.get_lantern_mend(Arch.WEAPON_LANTERN_STAFF), 3.5),
		"the Cooper's Mallet hits 3.0 (the maul's heft), the Bent-Twig Bow and the Rowan Walking-Stick 2, with a 3.5 Hearth-Mend")
	var mite: float = catalog.estimate_time_to_beat(stick, ArsenalCatalog.BRAMBLE_MITE_HP)
	check.call(mite >= ArsenalCatalog.HOMESTEAD_FIGHT_MIN_SEC and mite <= ArsenalCatalog.HOMESTEAD_FIGHT_MAX_SEC
		and catalog.estimate_time_to_beat(stick, ArsenalCatalog.BOULDER_BADGER_HP) > mite,
		"honest stick swings take a Bramble-Mite's 25 health down in %.1f s (12 to 15), a Boulder-Badger's 45 longer" % mite)
	# The shield example (§4.1): the Quiet Weir on a Forge-Iron buckler.
	var warden: PlayerLoadoutResource = _hand(ArsenalCatalog.TIER_3_FORGE_IRON)
	warden.offhand_seal_card_id = ArsenalCatalog.CARD_QUIET_WEIR
	var star_hit: Dictionary = catalog.evaluate_incoming_hit(warden, 100, &"SIGN_STAR_TIDE")
	var root_hit: Dictionary = catalog.evaluate_incoming_hit(warden, 100, &"SIGN_IRON_ROOT")
	check.call(bool(star_hit["stun_immune"]) and int(star_hit["final_damage"]) <= 50 and int(star_hit["final_damage"]) == 46
		and not bool(root_hit["stun_immune"]) and int(root_hit["final_damage"]) == 76,
		"a Forge-Plate Shield-Sworn with the Star-Bell on the buckler takes a 100 Star-Tide blow for %d (24%% Armor Guard and the 30%% ward), unstunned, and an Iron-Root one for %d"
		% [int(star_hit["final_damage"]), int(root_hit["final_damage"])])
	var controller: EquipmentSealComponent = EquipmentSealComponent.new()
	controller.loadout = warden
	var by_controller: Dictionary = controller.evaluate_incoming_hit(catalog, 100, &"SIGN_STAR_TIDE")
	check.call(by_controller == star_hit and is_equal_approx(controller.get_passive_ward_mitigation(&"SIGN_STAR_TIDE"), 0.30)
		and controller.grants_stun_immunity_against(&"SIGN_STAR_TIDE") and not controller.grants_stun_immunity_against(&"SIGN_RIME_GALE"),
		"the seal component reckons the same blow, a 30% Star-Tide ward on the buckler with its stun immunity")
	controller.free()
	# The Dual-Readout curve (§5.1).
	check.call(ArsenalCatalog.compute_true_level_from_renown(40) == 20 and ArsenalCatalog.compute_true_level_from_renown(1) == 1
		and ArsenalCatalog.compute_true_level_from_renown(7) == 4 and ArsenalCatalog.compute_true_level_from_renown(39) == 20
		and ArsenalCatalog.compute_renown_from_true_level(20) == 40 and ArsenalCatalog.compute_renown_from_true_level(1) == 2
		and catalog.tier_for_renown(40).tier_id == ArsenalCatalog.TIER_7_STAR_GLASS and catalog.tier_for_true_level(10).tier_id == ArsenalCatalog.TIER_3_FORGE_IRON
		and catalog.tier_for_true_level(5).tier_id == ArsenalCatalog.TIER_2_BOG_BRONZE and catalog.tier_for_true_level(4).tier_id == ArsenalCatalog.TIER_1_HOMESTEAD and catalog.tier_for_true_level(1).tier_id == ArsenalCatalog.TIER_1_HOMESTEAD,
		"Renown Rank 40 is True Level 20 (and Rank 1 Level 1, 7 Level 4, 39 Level 20); Level 20 reads Rank 40; Lv 4 still wears Orchard-Wood, Lv 5 Bog-Bronze, Lv 10 Forge-Iron, Rank 40 Star-Glass")
	# The recipe table (§3.2), float for float.
	var recipes_ok: bool = true
	var tiers: Array[EquipmentTierResource] = catalog.get_all_tiers()
	for index: int in mini(tiers.size(), TIER_RECIPES.size()):
		var tier: EquipmentTierResource = tiers[index]
		var row: Array = TIER_RECIPES[index]
		recipes_ok = recipes_ok and tier.albedo_tint.is_equal_approx(Color(String(row[0]))) and is_equal_approx(tier.metallic, float(row[1])) \
			and is_equal_approx(tier.roughness, float(row[2])) and is_equal_approx(tier.rim_strength, float(row[3])) \
			and tier.rim_tint.is_equal_approx(Color(String(row[4]))) and is_equal_approx(tier.emissive_pulse_strength, float(row[5])) \
			and tier.shader_uniforms().size() == 7
	check.call(recipes_ok, "the seven tiers' shader recipes match the table: albedo, metallic, roughness, rim strength, rim tint and emissive pulse")
	# The Graduated APM ladder (§5.2).
	check.call(PlayerLoadoutResource.stage_for_true_level(1) == 1 and PlayerLoadoutResource.stage_for_true_level(5) == 1
		and PlayerLoadoutResource.stage_for_true_level(6) == 2 and PlayerLoadoutResource.stage_for_true_level(10) == 2
		and PlayerLoadoutResource.stage_for_true_level(11) == 3 and PlayerLoadoutResource.stage_for_true_level(16) == 3
		and PlayerLoadoutResource.stage_for_true_level(17) == 4 and PlayerLoadoutResource.stage_for_true_level(20) == 4
		and ArsenalCatalog.compute_progression_stage(ArsenalCatalog.compute_true_level_from_renown(40)) == 4,
		"the four stages sit on the Google Doc's Lv 1-5, 6-10, 11-16 and 17-20")
	var raid: PlayerLoadoutResource = _raid_hand()
	var mid: PlayerLoadoutResource = _hand(ArsenalCatalog.TIER_3_FORGE_IRON)
	mid.weapon_seal_card_id = ArsenalCatalog.CARD_EMBER_BOUGH
	mid.offhand_seal_card_id = ArsenalCatalog.CARD_QUIET_WEIR
	mid.slot_l_primary_id = ArsenalCatalog.CARD_QUIET_WEIR
	mid.slot_r_primary_id = ArsenalCatalog.CARD_EMBER_BOUGH
	var seals_only: PlayerLoadoutResource = mid.copy()
	seals_only.slot_l_primary_id = &""
	seals_only.slot_r_primary_id = &""
	var twice: PlayerLoadoutResource = seals_only.copy()
	twice.mantle_seal_card_id = twice.weapon_seal_card_id
	check.call(PlayerLoadoutResource.MAX_CARDS == 7 and not raid.validate_loadout_for_stage(4) and not mid.validate_loadout_for_stage(4)
		and seals_only.validate_loadout_for_stage(2) and not seals_only.validate_loadout_for_stage(1)
		and not twice.validate_loadout_for_stage(4) and GrimoireRules.duplicate_title(twice.seal_card_ids()) == twice.weapon_seal_card_id
		and GrimoireRules.slots_open(1) == 0 and GrimoireRules.slots_open(12) == 6 and GrimoireRules.slots_open(17) == 7,
		"the hand keeps Seals only (the L, R and L+R cards and the Tuck live in the Cross): two Seals fit Stage 2, not Stage 1; a hand with old pocket cards is refused; no seal twice; 0 of 7 slots at Lv 1, 6 at Lv 12, all 7 at Lv 17")
	var tank: StringName = ClassLoadouts.SHIELD_TANK
	var sword: int = EquipmentItemResource.WeaponType.LIGHT_SWORD
	var at_1: PlayerLoadoutResource = catalog.default_seal_loadout(tank, ClassLoadoutResource.Role.TANK, sword, &"bridge_warden", 1, 0)
	var at_3: PlayerLoadoutResource = catalog.default_seal_loadout(tank, ClassLoadoutResource.Role.TANK, sword, &"bridge_warden", 3, 1)
	var at_4: PlayerLoadoutResource = catalog.default_seal_loadout(tank, ClassLoadoutResource.Role.TANK, sword, &"bridge_warden", 4, 2)
	var at_6: PlayerLoadoutResource = catalog.default_seal_loadout(tank, ClassLoadoutResource.Role.TANK, sword, &"bridge_warden", 6, 3)
	var at_11: PlayerLoadoutResource = catalog.default_seal_loadout(tank, ClassLoadoutResource.Role.TANK, sword, &"bridge_warden", 11, 0)
	var at_20: PlayerLoadoutResource = catalog.default_seal_loadout(tank, ClassLoadoutResource.Role.TANK, sword, &"bridge_warden", 20, 0)
	check.call(at_1.seal_count() == 0 and at_3.seal_count() == 1 and at_3.weapon_seal_card_id == ArsenalCatalog.CARD_OLD_ROOT_BASTION
		and at_4.seal_count() == 1 and at_6.seal_count() == 2 and at_6.offhand_seal_card_id == ArsenalCatalog.CARD_QUIET_WEIR
		and at_11.seal_count() == 3 and at_11.mantle_seal_card_id == ArsenalCatalog.CARD_WEST_WIND_PROMISE
		and at_20.seal_count() == 3 and at_20.equipped_tier_id == ArsenalCatalog.TIER_7_STAR_GLASS
		and at_1.active_count() + at_6.active_count() + at_11.active_count() + at_20.active_count() == 0
		and at_1.validate_loadout_for_stage(1) and at_6.validate_loadout_for_stage(2) and at_11.validate_loadout_for_stage(3) and at_20.validate_loadout_for_stage(4),
		"a Shield-Sworn's Seals grow with its level: none at Lv 1, Old-Hob's Root-Bind on the weapon at 3, the Star-Bell on the buckler at 6, the Feather on the mantle at 11")
	check.call(at_1.body_type == PlayerLoadoutResource.YouthBodyType.BODY_MALE_YOUTH and at_3.body_type == PlayerLoadoutResource.YouthBodyType.BODY_FEMALE_YOUTH
		and at_1.armor_weight_class == EquipmentTierResource.ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN and at_1.weapon_archetype == Arch.WEAPON_SWORD_BOARD
		and catalog.default_seal_loadout(ClassLoadouts.SOUL_TETHER_HEALER, ClassLoadoutResource.Role.HEALER, EquipmentItemResource.WeaponType.STAFF, &"bell_keeper", 10, 0).armor_weight_class
			== EquipmentTierResource.ArmorWeightClass.ARMOR_LIGHT_LANTERN_BEARER,
		"even seats are Male Youths and odd seats Female; a tank wears heavy and holds the Sword & Board, a mender wears light")
	# Tier 7 under the Ember-Bough (§5.1): 75 to 115 a combo strike.
	var apex: PlayerLoadoutResource = catalog.default_seal_loadout(ClassLoadouts.DIRECTIONAL_FLOW_DPS, ClassLoadoutResource.Role.DPS, sword, &"hedge_runner", 20, 1)
	var apex_light: int = catalog.evaluate_hit_damage(apex, false, true, ArsenalCatalog.CARD_EMBER_BOUGH, false)
	var apex_heavy: int = catalog.evaluate_hit_damage(apex, true, true, ArsenalCatalog.CARD_EMBER_BOUGH, false)
	var apex_tucked: int = catalog.evaluate_hit_damage(apex, true, true, ArsenalCatalog.CARD_EMBER_BOUGH, true)
	var apex_plain: int = catalog.evaluate_hit_damage(apex, true, false)
	check.call(apex.weapon_seal_card_id == ArsenalCatalog.CARD_EMBER_BOUGH and apex_light == 62 and apex_heavy == 87 and apex_tucked == 105 and apex_plain == 56,
		"a Tier 7 Star-Glass blade (36.0 light, 52.2 heavy) with the Ember-Bough pressed on it strikes for 56, and under its Pocket-Pull coat 62, 87 and 105 with a tuck")
	# The stagger cadence (§5.1): four Tier 7 heroes on the Elder Cairn-Drake's 1,200 posture.
	var party: Array[PlayerLoadoutResource] = [
		at_20,
		catalog.default_seal_loadout(ClassLoadouts.SOUL_TETHER_HEALER, ClassLoadoutResource.Role.HEALER, EquipmentItemResource.WeaponType.STAFF, &"bell_keeper", 20, 1),
		apex,
		catalog.default_seal_loadout(ClassLoadouts.DIRECTIONAL_FLOW_DPS, ClassLoadoutResource.Role.DPS, EquipmentItemResource.WeaponType.HEAVY_AXE, &"iron_woodsman", 20, 3),
	]
	var plain_party: Array[PlayerLoadoutResource] = []
	for member: PlayerLoadoutResource in party:
		var bare: PlayerLoadoutResource = member.copy()
		bare.weapon_seal_card_id = &""
		bare.offhand_seal_card_id = &""
		bare.mantle_seal_card_id = &""
		plain_party.append(bare)
	var sealed_cadence: float = catalog.estimate_stagger_seconds(party)
	var plain_cadence: float = catalog.estimate_stagger_seconds(plain_party)
	check.call(sealed_cadence >= ArsenalCatalog.STAGGER_CADENCE_MIN_SEC and sealed_cadence <= ArsenalCatalog.STAGGER_CADENCE_MAX_SEC
		and plain_cadence >= ArsenalCatalog.STAGGER_CADENCE_MIN_SEC and plain_cadence <= ArsenalCatalog.STAGGER_CADENCE_MAX_SEC and sealed_cadence < plain_cadence,
		"a Tier 7 party breaks the Rank 40 Elder Cairn-Drake's 1,200 posture every %.1f s sealed and %.1f s bare (35 to 50)" % [sealed_cadence, plain_cadence])
	# The posture gate, by stage, on a bare component (the hero's is checked live).
	var gate: EquipmentSealComponent = EquipmentSealComponent.new()
	EquipmentSealComponent.graduated_apm_enabled = true
	gate.progression_stage = 1
	var stage_1: bool = not gate.is_directional_attack_unlocked(EquipmentSealComponent.DirectionalAttack.FORWARD_HEAVY_LUNGE) \
		and gate.gate_command(CombatActionResource.Command.FORWARD_HEAVY) == CombatActionResource.Command.HEAVY \
		and gate.gate_command(CombatActionResource.Command.BACK_HEAVY) == CombatActionResource.Command.HEAVY \
		and gate.gate_command(CombatActionResource.Command.LIGHT) == CombatActionResource.Command.LIGHT
	gate.progression_stage = 2
	var stage_2: bool = gate.gate_command(CombatActionResource.Command.FORWARD_HEAVY) == CombatActionResource.Command.FORWARD_HEAVY \
		and not gate.is_directional_attack_unlocked(EquipmentSealComponent.DirectionalAttack.SIDE_LIGHT_FLANK) \
		and GrimoireRules.socket_open_at(GrimoireRules.SOCKET_R, 4) and not GrimoireRules.socket_open_at(GrimoireRules.SOCKET_R, 3) \
		and GrimoireRules.socket_open_at(GrimoireRules.SOCKET_L, 6) and not GrimoireRules.socket_open_at(GrimoireRules.SOCKET_L, 5)
	gate.progression_stage = 3
	var stage_3: bool = gate.is_directional_attack_unlocked(EquipmentSealComponent.DirectionalAttack.SIDE_LIGHT_FLANK) \
		and GrimoireRules.TUCK_OPEN_LEVEL == 11 and not GrimoireRules.socket_open_at(GrimoireRules.SOCKET_LR, 16)
	gate.progression_stage = 4
	var stage_4: bool = GrimoireRules.socket_open_at(GrimoireRules.SOCKET_LR, 17)
	EquipmentSealComponent.graduated_apm_enabled = false
	gate.progression_stage = 1
	var gate_off: bool = gate.is_directional_attack_unlocked(EquipmentSealComponent.DirectionalAttack.SIDE_LIGHT_FLANK) \
		and gate.gate_command(CombatActionResource.Command.FORWARD_HEAVY) == CombatActionResource.Command.FORWARD_HEAVY
	gate.free()
	check.call(stage_1 and stage_2 and stage_3 and stage_4 and gate_off,
		"the Graduated APM gate: Forward and Back heavies fall back to the plain heavy until Stage 2, the flank waits for 3; the sockets open by level (R at 4, L at 6, the Tuck at 11, L+R at 17); off, every posture is open")


# --- Stage 3: the split-screen and network gate ----------------------------------------------

func _stage_3_split_screen_and_network_schema_gate() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var hero: ActorBase = _keyboard_hero()
	if hero == null or hero.seal == null or hero.visuals == null or not hero.visuals.has_rig():
		check.call(false, "a local hero with a rig and a seal component stands in the Caldera Isles for the Stage 3 checks")
		return
	hero.seal.debug_stage_override = 0
	hero.seal.clear_custom_loadout()
	await _frames(2)
	var hand: PlayerLoadoutResource = hero.seal.loadout
	# The live hero wears the tier its Fellowship was promoted to at the Forge, never past its level's.
	var hero_class: StringName = hero.loadout.class_id
	var expected_tier: EquipmentTierResource = catalog.tier_at(mini(PartyProgress.current.promoted_tier(hero_class, PartyProgress.PIECE_WEAPON),
		catalog.tier_for_true_level(PartyProgress.current.character_level(hero_class)).tier_index))
	var expected_stage: int = PlayerLoadoutResource.stage_for_true_level(PartyProgress.current.character_level(hero.loadout.class_id))
	check.call(hand != null and hand.equipped_tier_id == expected_tier.tier_id and hero.seal.progression_stage == expected_stage
		and hand.validate_loadout_for_stage(expected_stage) and hand.seal_count() == PlayerLoadoutResource.seals_open_at_stage(expected_stage)
		and hand.active_count() == PlayerLoadoutResource.actives_open_at_stage(expected_stage) and hero.seal.true_level == PartyProgress.current.character_level(hero.loadout.class_id)
		and hero.seal.renown_rank() == ArsenalCatalog.compute_renown_from_true_level(PartyProgress.current.character_level(hero.loadout.class_id)),
		"the hero wears the hand its level earned: %s at Stage %d (Renown %d), %d seals and %d invocations"
		% [expected_tier.weapon_material_name, expected_stage, hero.seal.renown_rank(), hand.seal_count(), hand.active_count()])
	# The Wingfeather youth rig (§2.1).
	var scales: Dictionary = hero.visuals.get_current_youth_scales()
	var head_scale: Vector3 = hero.visuals.skeleton.get_bone_pose_scale(HeroRigBuilder.Bone.HEAD)
	var hand_scale: Vector3 = hero.visuals.skeleton.get_bone_pose_scale(HeroRigBuilder.Bone.HAND_L)
	check.call(scales.get("head", Vector3.ZERO) == Vector3(1.22, 1.22, 1.22) and scales.get("weapon", Vector3.ZERO) == Vector3(1.25, 1.25, 1.25)
		and scales.get("hand", Vector3.ZERO) == Vector3(1.28, 1.28, 1.28) and scales.get("foot", Vector3.ZERO) == Vector3(1.18, 1.18, 1.18)
		and head_scale.is_equal_approx(Vector3(1.22, 1.22, 1.22)) and hand_scale.is_equal_approx(Vector3(1.28, 1.28, 1.28))
		and hero.visuals.youth_body_type() == hand.body_type and is_equal_approx(float(scales.get("heads_tall", 0.0)), 5.5),
		"the Wingfeather youth rig: the head 1.22x, the hands 1.28x, the boots 1.18x and the weapon 1.25x, as bone scales on the same rig, 5.5 heads tall")
	var bare: ActorVisuals = ActorVisuals.new()
	bare.apply_wingfeather_youth_proportions(PlayerLoadoutResource.YouthBodyType.BODY_FEMALE_YOUTH)
	var bare_scales: Dictionary = bare.get_current_youth_scales()
	check.call(bare_scales["head"] == Vector3(1.22, 1.22, 1.22) and bare_scales["weapon"] == Vector3(1.25, 1.25, 1.25)
		and bare_scales["mantle"] == Vector3(1.08, 1.0, 1.08) and bare_scales["shoulder"] == Vector3(0.96, 1.0, 1.0),
		"a Female Youth flares her mantle 8%; the scales read the same off a bare puppet")
	bare.free()
	# One set of meshes across seven tiers (§3.2): only the uniforms change.
	var state: Dictionary = hero.visuals.seal_state()
	var meshes_before: int = hero.visuals.find_children("*", "MeshInstance3D", true, false).size()
	var recipes_live: bool = true
	var materials: Array[ShaderMaterial] = hero.visuals.seal_materials()
	for tier: EquipmentTierResource in catalog.get_all_tiers():
		var dressed: PlayerLoadoutResource = hand.copy()
		dressed.equipped_tier_id = tier.tier_id
		hero.visuals.apply_equipment_tier_and_seals(catalog, dressed)
		for material: ShaderMaterial in materials:
			recipes_live = recipes_live and (material.get_shader_parameter(&"albedo_tint") as Color).is_equal_approx(tier.albedo_tint) \
				and is_equal_approx(float(material.get_shader_parameter(&"metallic")), tier.metallic) \
				and is_equal_approx(float(material.get_shader_parameter(&"emissive_pulse_strength")), tier.emissive_pulse_strength)
	var meshes_after: int = hero.visuals.find_children("*", "MeshInstance3D", true, false).size()
	hero.seal.apply_visuals()
	var blade: MeshInstance3D = hero.visuals.weapon().get_node_or_null(^"Blade") as MeshInstance3D if hero.visuals.weapon() != null else null
	var pass_on_blade: bool = blade != null and blade.material_override != null and blade.material_override.next_pass == materials[0]
	check.call(state.get("tier_id", &"") == expected_tier.tier_id and recipes_live and meshes_before == meshes_after and meshes_before > 0
		and pass_on_blade and is_equal_approx(float(materials[0].get_shader_parameter(&"base_blend")), ActorVisuals.WEAPON_SEAL_BLEND)
		and bool(materials[0].get_shader_parameter(&"has_scribe_seal")) == (hand.weapon_seal_card_id != &"")
		and bool(materials[1].get_shader_parameter(&"has_scribe_seal")) == (hand.offhand_seal_card_id != &""),
		"all seven tiers dress the same %d meshes by uniforms alone; the weapon wears the seal shader as a pass over its sculpt, the seals light their pieces" % meshes_before)
	# The Seal Ledger (§6.8), under 8% of every cell, and the cross still four diamonds.
	var hud: PlayerHUD = level.huds.get(hero.player_id) as PlayerHUD
	var cross: CrossGrimoireHUD = hud.cross_grimoire if hud != null else null
	if cross == null:
		check.call(false, "the hero has a Cross-Grimoire HUD for the ledger checks")
		return
	var ledger: Control = cross.seal_ledger()
	await _frames(2)
	var shares_ok: bool = true
	var worst: float = 0.0
	for cell: Vector2 in CELLS:
		var share: float = CrossGrimoireHUD.ledger_area_share(cell)
		worst = maxf(worst, share)
		shares_ok = shares_ok and share < CrossGrimoireHUD.LEDGER_MAX_SHARE
	var live_share: float = cross.ledger_rect().get_area() / maxf(cross.size.x * cross.size.y, 1.0) if cross.size.x > 0.0 else 0.0
	var labels: Array[Node] = cross.find_children("*", "Label", true, false)
	var widgets: Array[Node] = cross.find_children("*", "CrossGrimoireDiamondWidget", true, false)
	check.call(ledger != null and ledger.visible and ledger.name == &"SealLedger" and shares_ok and live_share < CrossGrimoireHUD.LEDGER_MAX_SHARE
		and labels.is_empty() and widgets.size() == 1 and cross.ledger_rect().position.x < cross.size.x * 0.5 and cross.ledger_rect().end.y <= cross.size.y + 0.5,
		"the Seal Ledger sits in the bottom-left corner at most %.1f%% of any cell (%.1f%% of this one), with no labels and the cross still one diamond widget"
		% [worst * 100.0, live_share * 100.0])
	# The Pocket-Pull (§4.2): camera untouched, the ledger's card flipped, the trail in the card's ink.
	hero.input.release_script()
	hero.action_queue.interrupt()
	await _frames(12)
	var camera: PlayerCamera = level.camera_for_seat(hero.party_slot + 1)
	var before_transform: Transform3D = camera.global_transform if camera != null else Transform3D.IDENTITY
	var before_fov: float = camera.fov if camera != null else 0.0
	var before_pulses: int = camera.dolly_pulses() if camera != null else 0
	var shared: Camera3D = Camera3D.new()
	shared.position = Vector3(0.0, 4.8, 6.2)
	shared.fov = 55.0
	var shared_before: Transform3D = shared.transform
	hero.stats.add_resonance(3.0)
	hero.seal.flow_link_timer = EquipmentSealComponent.FLOW_LINK_WINDOW_SEC
	var pulls_before: int = hero.visuals.pocket_pull_count()
	var pips_before: int = hero.stats.resonance_pips()
	var pulled: Dictionary = hero.seal.try_trigger_pocket_pull_invocation(Slot.R)
	# The seven-card hand (22 GDD R5): R's own socket card comes out of the pouch.
	var r_leaf: StringName = hero.seal.socket_card_id(GrimoireRules.SOCKET_R)
	var pulled_card: ScribeCardResource = catalog.get_card(r_leaf)
	var sign_ink: Color = catalog.sign_seal(pulled_card.scribe_sign).color if pulled_card != null else Color.BLACK
	check.call(bool(pulled.get("success", false)) and pulled.get("card_id", &"") == r_leaf and bool(pulled.get("leaf_pull", false))
		and hero.stats.resonance_pips() == pips_before - int(pulled.get("ink_cost", 99)) and hero.visuals.is_flourishing()
		and hero.visuals.pocket_pull_count() == pulls_before + 1 and hero.seal.invocations() >= 1
		and cross.is_card_flipping() and cross.flipping_slot() == Slot.R and hero.trail.ink_override().is_equal_approx(sign_ink)
		and is_equal_approx(hero.visuals.seal_flare(), ActorVisuals.POCKET_PULL_FLARE),
		"R in the window pulls its own socket card, the %s: its cost spent, the flourish on, the seals flaring to 2.2, the ledger's R card flipping, the trail in its Sign's ink"
		% (pulled_card.display_name if pulled_card != null else "card"))
	await _frames(POCKET_PULL_HALF_FRAMES)
	var card_up: bool = hero.visuals.is_card_out() or hero.visuals.card_peak_height() > 0.0
	await _seconds(0.25)
	var camera_still: bool = camera == null or (is_equal_approx(camera.fov, before_fov) and camera.dolly_pulses() == before_pulses
		and camera.global_transform.origin.distance_to(before_transform.origin) < 0.05 and camera.global_transform.basis.is_equal_approx(before_transform.basis))
	check.call(camera_still and shared.transform == shared_before and is_equal_approx(shared.fov, 55.0) and not hero.visuals.is_flourishing()
		and hero.visuals.seal_flare() > 0.0 and hero.visuals.seal_flare() <= ActorVisuals.POCKET_PULL_AFTERGLOW and not cross.is_card_flipping()
		and cross.card_flips() >= 1 and card_up and hero.visuals.card_peak_height() <= ActorVisuals.POCKET_PULL_CARD_CAP + 0.001,
		"the flourish is over in 0.30 s with the player's camera and a bare Camera3D exactly where they were; the card rose to %.2f m (under 2.5), the afterglow fades"
		% hero.visuals.card_peak_height())
	shared.free()
	hero.seal.flow_link_timer = 0.0
	var refused_window: Dictionary = hero.seal.try_trigger_pocket_pull_invocation(Slot.R)
	hero.seal.flow_link_timer = EquipmentSealComponent.FLOW_LINK_WINDOW_SEC
	hero.stats.add_resonance(3.0)
	var refused_grand: Dictionary = hero.seal.try_trigger_pocket_pull_invocation(Slot.L_AND_R)
	var grand_reason: String = String(refused_grand.get("reason", ""))
	check.call(not bool(refused_window.get("success", true)) and refused_window.get("reason", "") == EquipmentSealComponent.REASON_NO_WINDOW
		and (GrimoireRules.all_open() or expected_stage >= 4 or (not bool(refused_grand.get("success", true)) and grand_reason == EquipmentSealComponent.REASON_LOCKED)),
		"with the window shut a pull is refused; the L+R Grand card waits for Lv 17 (%s)" % grand_reason)
	hero.seal.flow_link_timer = 0.0
	# A ward in play (§4.1): the Quiet Weir on the buckler against a Star-Tide blow.
	var warded: PlayerLoadoutResource = hand.copy()
	warded.offhand_seal_card_id = ArsenalCatalog.CARD_QUIET_WEIR
	hero.seal.set_loadout(warded)
	var blow: CombatEvent = CombatEvent.new()
	blow.kind = CombatEvent.Kind.STRIKE
	blow.attacker_path = hero.get_path()
	blow.target_path = hero.get_path()
	blow.damage = 100.0
	blow.scribe_sign = ScribeSignResource.Sign.SIGN_STAR_TIDE
	var warded_before: int = hero.seal.warded_blows()
	hero.seal.filter_incoming(blow)
	var star_ward: float = hero.seal.get_passive_ward_mitigation(&"SIGN_STAR_TIDE")
	var ward_ok: bool = is_equal_approx(blow.damage, 100.0 * (1.0 - star_ward)) and star_ward >= 0.30 and hero.seal.shrugs_off_stagger() \
		and hero.seal.warded_blows() == warded_before + 1
	# A blow of a Sign none of the hand's seals ward lands whole (which Sign that is depends on the role's hand).
	var unwarded: int = ScribeSignResource.Sign.NONE
	for candidate: int in [ScribeSignResource.Sign.SIGN_IRON_ROOT, ScribeSignResource.Sign.SIGN_RIME_GALE, ScribeSignResource.Sign.SIGN_WARM_HEARTH]:
		if hero.seal.get_passive_ward_mitigation(ScribeSignResource.id_of(candidate)) <= 0.0:
			unwarded = candidate
			break
	var plain_blow: CombatEvent = CombatEvent.new()
	plain_blow.kind = CombatEvent.Kind.STRIKE
	plain_blow.damage = 100.0
	plain_blow.scribe_sign = unwarded
	hero.seal.filter_incoming(plain_blow)
	check.call(ward_ok and unwarded != ScribeSignResource.Sign.NONE and is_equal_approx(plain_blow.damage, 100.0)
		and hero.seal.loadout.offhand_seal_card_id == ArsenalCatalog.CARD_QUIET_WEIR
		and hero.visuals.seal_state().get("offhand_seal", &"") == ArsenalCatalog.CARD_QUIET_WEIR,
		"the Star-Bell on the buckler takes a 100 Star-Tide blow to %d (its 30%% ward, more if the mantle wards Star-Tide too) and shrugs its stun; a %s blow lands whole; the crest shows the new seal"
		% [roundi(100.0 * (1.0 - star_ward)), ArsenalCatalog.current.sign_seal(unwarded).display_name])
	# A Weapon Seal shapes the hero's own strikes on the foe's owner: the flat bonus, and a pull's coat by id.
	var swing: CombatEvent = CombatEvent.new()
	swing.kind = CombatEvent.Kind.STRIKE
	swing.damage = 10.0
	swing.poise_damage = 10.0
	hero.seal.shape_outgoing(swing)
	var weapon_seal: ScribeCardResource = catalog.get_card(hero.seal.loadout.weapon_seal_card_id)
	var flat: int = int(weapon_seal.slot_passive(ScribeCardResource.SealSlotMask.SEAL_WEAPON)["flat"]) if weapon_seal != null else 0
	check.call(is_equal_approx(swing.damage, 10.0 + float(flat)) and is_equal_approx(swing.poise_damage, 10.0 * hero.seal.passive_posture_break_mult()),
		"on the foe's owner a strike carries the Weapon Seal's +%d and its x%.2f stagger (the slot's own passive)"
		% [flat, hero.seal.passive_posture_break_mult()])
	hero.seal.clear_custom_loadout()
	# The 1-Button Gambit Assist: the Squire's button pulls when the window is open and the pips are there.
	var assist_was: bool = hero.seal.input_gambit_assist
	hero.seal.input_gambit_assist = true
	hero.stats.add_resonance(3.0)
	hero.seal.flow_link_timer = EquipmentSealComponent.FLOW_LINK_WINDOW_SEC
	var pulls_before_gambit: int = hero.seal.invocations()
	var assist: Dictionary = hero.seal.execute_one_button_gambit()
	var handled: bool = bool(assist.get("handled", false)) or int(assist.get("command", -1)) == CombatActionResource.Command.TRIGGER_R_SKILL
	hero.seal.flow_link_timer = 0.0
	var idle_assist: Dictionary = hero.seal.execute_one_button_gambit()
	hero.seal.input_gambit_assist = assist_was
	check.call(handled and (hero.seal.invocations() > pulls_before_gambit or int(assist.get("command", -1)) >= 0)
		and not bool(idle_assist.get("handled", true)) and int(idle_assist.get("command", 0)) == -1 and idle_assist.get("action_id", &"") == EquipmentSealComponent.GAMBIT_ACTION,
		"the Gambit Assist pulls a card (or rides the R cast) in an open window with pips in hand, and leaves the swing to the Squire's picker otherwise")
	await _seconds(0.35)
	# The posture gate on the live hero, by debug stage.
	EquipmentSealComponent.graduated_apm_enabled = true
	hero.seal.debug_stage_override = 1
	hero.seal.refresh()
	var gated: bool = hero.seal.gate_command(CombatActionResource.Command.FORWARD_HEAVY) == CombatActionResource.Command.HEAVY and hero.seal.progression_stage == 1 \
		and hero.seal.loadout.seal_count() <= 1 and hero.seal.loadout.active_count() == 0
	hero.seal.debug_stage_override = 3
	hero.seal.refresh()
	var opened: bool = hero.seal.gate_command(CombatActionResource.Command.FORWARD_HEAVY) == CombatActionResource.Command.FORWARD_HEAVY \
		and hero.seal.is_directional_attack_unlocked(EquipmentSealComponent.DirectionalAttack.SIDE_LIGHT_FLANK) and hero.seal.loadout.seal_count() >= 2
	EquipmentSealComponent.graduated_apm_enabled = false
	hero.seal.debug_stage_override = 0
	hero.seal.refresh()
	check.call(gated and opened and hero.seal.progression_stage == expected_stage and hero.seal.loadout.validate_loadout_for_stage(expected_stage),
		"forced to Stage 1 the hero's Forward heavy falls back to the plain heavy and its Seals shrink to one; at Stage 3 the flank opens and the Seals come back; the level's stage comes back")
	# Network (Gate 4): the hand as Strings and ints, the RPCs there, a JSON round trip.
	var raid: PlayerLoadoutResource = _raid_hand()
	var data: Dictionary = raid.to_network_dict()
	var primitives: bool = data.size() == 13
	for value: Variant in data.values():
		primitives = primitives and typeof(value) in [TYPE_INT, TYPE_STRING]
	var json_back: PlayerLoadoutResource = PlayerLoadoutResource.from_dict(JSON.parse_string(JSON.stringify(data)) as Dictionary)
	var copy_back: PlayerLoadoutResource = PlayerLoadoutResource.new()
	copy_back.from_network_dict(hand.to_network_dict())
	check.call(primitives and json_back.same_as(raid) and json_back.get_total_equipped_card_count() == 7 and copy_back.same_as(hand)
		and hero.seal.has_method(&"sync_loadout_rpc") and hero.seal.has_method(&"trigger_pocket_pull_rpc")
		and ScribeSignResource.from_id(ScribeSignResource.id_of(ScribeSignResource.Sign.SIGN_RIME_GALE)) == ScribeSignResource.Sign.SIGN_RIME_GALE,
		"a hand crosses the network as 13 Strings and ints (a JSON round trip keeps all 7 cards), on sync_loadout_rpc and trigger_pocket_pull_rpc; Signs travel as ids")
	var pulled_copy: int = hero.visuals.pocket_pull_count()
	hero.seal.trigger_pocket_pull_rpc(ArsenalCatalog.CARD_QUIET_WEIR, Slot.L, 0)
	check.call(hero.visuals.pocket_pull_count() == pulled_copy + 1 and hero.visuals.is_flourishing(),
		"a pull named over the network (a card id and two ints) plays the same flourish on a copy")
	await _seconds(0.35)
	hero.seal.flow_link_timer = 0.0


const POCKET_PULL_HALF_FRAMES: int = 8
