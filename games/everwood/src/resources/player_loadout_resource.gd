## A hero's Seal-and-Tuck Grimoire hand (docs/everwood_equipment_grimoire_architecture.md
## Part II §4-§5): the material tier they wear, their youth silhouette, and the
## 7-Card Pre-Raid Hand, partitioned so nothing scrolls mid-fight (the Musk Razor):
##
##   Layer 1  three Equipment Seals pressed onto the 3D gear before battle
##            (weapon, off-hand / buckler, mantle): a Deep-Ink script, a Sign
##            ward, a flat bonus, and the card's foil in the shader
##   Layer 2  four Active Invocations on the direct triggers: L and R each
##            hold a primary card and an Under-Card Tuck beneath it; L+R is
##            the Grand Invocation of both primaries (Stage 4)
##
## The Graduated APM ladder opens the slots by progression stage
## (validate_loadout_for_stage): Stage 1 one seal and the L card, Stage 2 two
## and two, Stage 3 three and three (the first tuck), Stage 4 everything.
##
## Ids only: to_network_dict is Strings and ints, so a hand crosses ENet and
## save files as a few short keys and every peer resolves them in the
## ArsenalCatalog (Gate 4).
class_name PlayerLoadoutResource
extends Resource

## The two Wingfeather youth silhouettes: the same rig, hitbox and pace, different cuts.
enum YouthBodyType { BODY_MALE_YOUTH = 0, BODY_FEMALE_YOUTH = 1 }
## The direct triggers that fire an invocation: L, R, and both together.
enum TriggerSlot { L = 0, R = 1, L_AND_R = 2 }
## The seven slots of the hand, one row each on the Binder's stamping bench, in
## ArsenalCatalog.ROLE_SEAL_HANDS order: the three seals, then L, its tuck, R and its tuck.
enum HandSlot { WEAPON_SEAL = 0, OFFHAND_SEAL = 1, MANTLE_SEAL = 2, L_PRIMARY = 3, L_TUCK = 4, R_PRIMARY = 5, R_TUCK = 6 }

const SEAL_SLOT_COUNT: int = 3
const ACTIVE_SLOT_COUNT: int = 4
## The whole hand: 3 seals and 4 invocations, never more.
const MAX_CARDS: int = 7
## The four progression stages (§5.2) and the True Level bands they cover.
const STAGE_HOMESTEAD: int = 1
const STAGE_FIRST_FRICTION: int = 2
const STAGE_CONVERGENCE: int = 3
const STAGE_APEX: int = 4
const STAGE_NAMES: Array[String] = ["", "Homestead Onboarding", "First Friction Isle", "Three Isles Convergence", "Apex & Endgame Raids"]
const STAGE_MAX_LEVELS: Array[int] = [0, 5, 10, 15, 20]
## How many seal slots and active slots each stage opens (index = stage).
const SEALS_OPEN: Array[int] = [0, 1, 2, 3, 3]
const ACTIVES_OPEN: Array[int] = [0, 1, 2, 3, 4]
## Within Stage 1: the first Pocket-Pull card comes at Lv 3, the off-hand seal at Lv 4.
const FIRST_POCKET_PULL_LEVEL: int = 3
const OFFHAND_SEAL_LEVEL: int = 4
const BODY_TYPE_NAMES: Array[String] = ["Male Youth", "Female Youth"]
const TRIGGER_NAMES: Array[String] = ["L", "R", "L+R"]
const HAND_SLOT_COUNT: int = 7
## What the bench calls each slot (HandSlot order).
const HAND_SLOT_NAMES: Array[String] = ["Weapon", "Off-Hand", "Mantle", "L", "L tuck", "R", "R tuck"]
## The stage each slot opens at (HandSlot order), as trim_to_stage takes them off: the
## off-hand seal and the L card in Stage 1 (at Lv 4 and Lv 3), the weapon seal and R at
## Stage 2, the mantle seal and the L tuck at Stage 3, the R tuck at Stage 4.
const SLOT_OPEN_STAGES: Array[int] = [2, 1, 3, 1, 3, 2, 4]

@export var body_type: YouthBodyType = YouthBodyType.BODY_MALE_YOUTH
@export var calling_id: StringName = &"CALLING_SHIELD_SWORN"
@export var weapon_archetype: int = EquipmentTierResource.WeaponArchetype.WEAPON_SWORD_BOARD
@export var armor_weight_class: int = EquipmentTierResource.ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN
@export var equipped_tier_id: StringName = &"TIER_1_HOMESTEAD"

@export_group("Layer 1: 3 Pre-Battle Equipment Seals")
@export var weapon_seal_card_id: StringName = &""
@export var offhand_seal_card_id: StringName = &""
@export var mantle_seal_card_id: StringName = &""

@export_group("Layer 2: 4 Active Grimoire Trigger Slots")
@export var slot_l_primary_id: StringName = &""
@export var slot_l_tuck_id: StringName = &""
@export var slot_r_primary_id: StringName = &""
@export var slot_r_tuck_id: StringName = &""


# --- The hand ---------------------------------------------------------------------

## The three seals in slot order (weapon, off-hand, mantle), &"" where none is pressed.
func seal_card_ids() -> Array[StringName]:
	return [weapon_seal_card_id, offhand_seal_card_id, mantle_seal_card_id]


## The four invocations in slot order (L, L tuck, R, R tuck).
func active_card_ids() -> Array[StringName]:
	return [slot_l_primary_id, slot_l_tuck_id, slot_r_primary_id, slot_r_tuck_id]


func get_all_equipped_card_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for cid: StringName in seal_card_ids() + active_card_ids():
		if cid != &"":
			result.append(cid)
	return result


func get_total_equipped_card_count() -> int:
	return get_all_equipped_card_ids().size()


func seal_count() -> int:
	var count: int = 0
	for cid: StringName in seal_card_ids():
		if cid != &"":
			count += 1
	return count


func active_count() -> int:
	var count: int = 0
	for cid: StringName in active_card_ids():
		if cid != &"":
			count += 1
	return count


func has_seal_card(card_id: StringName) -> bool:
	return card_id != &"" and seal_card_ids().has(card_id)


func has_active_card(card_id: StringName) -> bool:
	return card_id != &"" and active_card_ids().has(card_id)


## The seal pressed into a slot (ScribeCardResource.SealSlotMask flag), &"" for none.
func seal_in_slot(slot_flag: int) -> StringName:
	match slot_flag:
		ScribeCardResource.SealSlotMask.SEAL_WEAPON:
			return weapon_seal_card_id
		ScribeCardResource.SealSlotMask.SEAL_OFFHAND_BUCKLER:
			return offhand_seal_card_id
		ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR:
			return mantle_seal_card_id
	return &""


func set_seal_in_slot(slot_flag: int, card_id: StringName) -> void:
	match slot_flag:
		ScribeCardResource.SealSlotMask.SEAL_WEAPON:
			weapon_seal_card_id = card_id
		ScribeCardResource.SealSlotMask.SEAL_OFFHAND_BUCKLER:
			offhand_seal_card_id = card_id
		ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR:
			mantle_seal_card_id = card_id


## The card in one of the seven slots (HandSlot), &"" for none.
func card_in_slot(slot: int) -> StringName:
	match slot:
		HandSlot.WEAPON_SEAL:
			return weapon_seal_card_id
		HandSlot.OFFHAND_SEAL:
			return offhand_seal_card_id
		HandSlot.MANTLE_SEAL:
			return mantle_seal_card_id
		HandSlot.L_PRIMARY:
			return slot_l_primary_id
		HandSlot.L_TUCK:
			return slot_l_tuck_id
		HandSlot.R_PRIMARY:
			return slot_r_primary_id
		HandSlot.R_TUCK:
			return slot_r_tuck_id
	return &""


func set_card_in_slot(slot: int, card_id: StringName) -> void:
	match slot:
		HandSlot.WEAPON_SEAL:
			weapon_seal_card_id = card_id
		HandSlot.OFFHAND_SEAL:
			offhand_seal_card_id = card_id
		HandSlot.MANTLE_SEAL:
			mantle_seal_card_id = card_id
		HandSlot.L_PRIMARY:
			slot_l_primary_id = card_id
		HandSlot.L_TUCK:
			slot_l_tuck_id = card_id
		HandSlot.R_PRIMARY:
			slot_r_primary_id = card_id
		HandSlot.R_TUCK:
			slot_r_tuck_id = card_id


## Takes the seven cards from another hand and keeps this one's tier, frame, armour and silhouette
## (a saved hand's cards on the hand the hero's level forged).
func take_cards_from(other: PlayerLoadoutResource) -> void:
	for slot: int in HAND_SLOT_COUNT:
		set_card_in_slot(slot, other.card_in_slot(slot) if other != null else &"")


## The three seal slots come first; the other four are the invocations.
static func is_seal_slot(slot: int) -> bool:
	return slot >= HandSlot.WEAPON_SEAL and slot <= HandSlot.MANTLE_SEAL


## A seal slot's ScribeCardResource.SealSlotMask flag (SEAL_NONE for an invocation slot).
static func seal_flag_for_slot(slot: int) -> int:
	return ScribeCardResource.SEAL_SLOT_FLAGS[slot] if is_seal_slot(slot) else ScribeCardResource.SealSlotMask.SEAL_NONE


## Whether a slot is open at a stage and level, exactly as trim_to_stage leaves it.
static func slot_open(slot: int, stage: int, true_level: int) -> bool:
	if slot < 0 or slot >= HAND_SLOT_COUNT:
		return false
	var opens: int = SLOT_OPEN_STAGES[slot]
	if stage != opens:
		return stage > opens
	if stage != STAGE_HOMESTEAD:
		return true
	return true_level >= (OFFHAND_SEAL_LEVEL if slot == HandSlot.OFFHAND_SEAL else FIRST_POCKET_PULL_LEVEL)


## The first True Level that opens a slot: Lv 3 the L card, Lv 4 the off-hand seal, Lv 6, 11 and 16 the rest.
static func slot_open_level(slot: int) -> int:
	var opens: int = SLOT_OPEN_STAGES[clampi(slot, 0, HAND_SLOT_COUNT - 1)]
	if opens == STAGE_HOMESTEAD:
		return OFFHAND_SEAL_LEVEL if slot == HandSlot.OFFHAND_SEAL else FIRST_POCKET_PULL_LEVEL
	return STAGE_MAX_LEVELS[opens - 1] + 1


## When a locked slot opens, in a few words: "opens at Lv 4", "opens at Stage 3 (Lv 11)".
static func slot_opens_text(slot: int) -> String:
	var opens: int = SLOT_OPEN_STAGES[clampi(slot, 0, HAND_SLOT_COUNT - 1)]
	if opens == STAGE_HOMESTEAD:
		return "opens at Lv %d" % slot_open_level(slot)
	return "opens at Stage %d (Lv %d)" % [opens, slot_open_level(slot)]


## The card a trigger fires: L's and R's primaries; L+R's is the L primary, with the R primary as its partner.
func primary_for_trigger(trigger_slot: int) -> StringName:
	match trigger_slot:
		TriggerSlot.L:
			return slot_l_primary_id
		TriggerSlot.R:
			return slot_r_primary_id
		TriggerSlot.L_AND_R:
			return slot_l_primary_id
	return &""


## The Under-Card tucked beneath a trigger's primary (L+R's tuck is the R primary).
func tuck_for_trigger(trigger_slot: int) -> StringName:
	match trigger_slot:
		TriggerSlot.L:
			return slot_l_tuck_id
		TriggerSlot.R:
			return slot_r_tuck_id
		TriggerSlot.L_AND_R:
			return slot_r_primary_id
	return &""


# --- The Graduated APM ladder (§5.2) ------------------------------------------------

## The progression stage a True Level plays at: 1-5, 6-10, 11-15, 16-20.
static func stage_for_true_level(true_level: int) -> int:
	var level: int = clampi(true_level, 1, STAGE_MAX_LEVELS[STAGE_APEX])
	for stage: int in range(STAGE_HOMESTEAD, STAGE_APEX + 1):
		if level <= STAGE_MAX_LEVELS[stage]:
			return stage
	return STAGE_APEX


static func stage_name(stage: int) -> String:
	return STAGE_NAMES[clampi(stage, 0, STAGE_APEX)]


static func seals_open_at_stage(stage: int) -> int:
	return SEALS_OPEN[clampi(stage, 0, STAGE_APEX)]


static func actives_open_at_stage(stage: int) -> int:
	return ACTIVES_OPEN[clampi(stage, 0, STAGE_APEX)]


## Under-Card Tucks open at Stage 3; the L+R Grand Invocation at Stage 4.
static func tucks_open_at_stage(stage: int) -> bool:
	return stage >= STAGE_CONVERGENCE


static func grand_invocation_open_at_stage(stage: int) -> bool:
	return stage >= STAGE_APEX


## Whether a trigger is live at a stage: L from Stage 1, R from Stage 2, L+R from Stage 4.
static func trigger_open_at_stage(trigger_slot: int, stage: int) -> bool:
	match trigger_slot:
		TriggerSlot.L:
			return stage >= STAGE_HOMESTEAD
		TriggerSlot.R:
			return stage >= STAGE_FIRST_FRICTION
		TriggerSlot.L_AND_R:
			return stage >= STAGE_APEX
	return false


## Whether the hand fits a stage's slots: how many seals and invocations it
## may hold, and no tucks before Stage 3 (the doc's exact rule).
func validate_loadout_for_stage(progression_stage: int) -> bool:
	var seals: int = seal_count()
	var actives: int = active_count()
	match progression_stage:
		1:
			return seals <= 1 and actives <= 1
		2:
			return seals <= 2 and actives <= 2 and slot_l_tuck_id == &"" and slot_r_tuck_id == &""
		3:
			return seals <= 3 and actives <= 3
		4:
			return seals <= 3 and actives <= 4
		_:
			return false


## Takes off whatever a stage (and, in Stage 1, a level) hasn't opened yet, in
## the order the ladder opens them: the off-hand seal (Lv 4), then the weapon
## seal, then the mantle; the L card (Lv 3), then R, then the L tuck, then the R tuck.
func trim_to_stage(progression_stage: int, true_level: int = STAGE_MAX_LEVELS[STAGE_APEX]) -> void:
	var stage: int = clampi(progression_stage, STAGE_HOMESTEAD, STAGE_APEX)
	var seals_open: int = seals_open_at_stage(stage)
	var actives_open: int = actives_open_at_stage(stage)
	if stage == STAGE_HOMESTEAD:
		if true_level < OFFHAND_SEAL_LEVEL:
			seals_open = 0
		if true_level < FIRST_POCKET_PULL_LEVEL:
			actives_open = 0
	if seals_open < 1:
		offhand_seal_card_id = &""
	if seals_open < 2:
		weapon_seal_card_id = &""
	if seals_open < 3:
		mantle_seal_card_id = &""
	if actives_open < 1:
		slot_l_primary_id = &""
	if actives_open < 2:
		slot_r_primary_id = &""
	if actives_open < 3:
		slot_l_tuck_id = &""
	if actives_open < 4:
		slot_r_tuck_id = &""


# --- Across the network and into saves (Gate 4) --------------------------------------

## Strings and ints only.
func to_network_dict() -> Dictionary:
	return {
		"body_type": int(body_type),
		"calling_id": String(calling_id),
		"weapon_archetype": int(weapon_archetype),
		"armor_weight_class": int(armor_weight_class),
		"equipped_tier_id": String(equipped_tier_id),
		"weapon_seal": String(weapon_seal_card_id),
		"offhand_seal": String(offhand_seal_card_id),
		"mantle_seal": String(mantle_seal_card_id),
		"slot_l_primary": String(slot_l_primary_id),
		"slot_l_tuck": String(slot_l_tuck_id),
		"slot_r_primary": String(slot_r_primary_id),
		"slot_r_tuck": String(slot_r_tuck_id),
	}


## Reads a hand back, tolerating missing keys (an older peer, a bad packet).
func from_network_dict(data: Dictionary) -> void:
	body_type = clampi(int(data.get("body_type", 0)), 0, YouthBodyType.size() - 1) as YouthBodyType
	calling_id = StringName(str(data.get("calling_id", "CALLING_SHIELD_SWORN")))
	weapon_archetype = clampi(int(data.get("weapon_archetype", 0)), 0, EquipmentTierResource.WeaponArchetype.size() - 1)
	armor_weight_class = clampi(int(data.get("armor_weight_class", 0)), 0, EquipmentTierResource.ArmorWeightClass.size() - 1)
	equipped_tier_id = StringName(str(data.get("equipped_tier_id", "TIER_1_HOMESTEAD")))
	weapon_seal_card_id = StringName(str(data.get("weapon_seal", "")))
	offhand_seal_card_id = StringName(str(data.get("offhand_seal", "")))
	mantle_seal_card_id = StringName(str(data.get("mantle_seal", "")))
	slot_l_primary_id = StringName(str(data.get("slot_l_primary", "")))
	slot_l_tuck_id = StringName(str(data.get("slot_l_tuck", "")))
	slot_r_primary_id = StringName(str(data.get("slot_r_primary", "")))
	slot_r_tuck_id = StringName(str(data.get("slot_r_tuck", "")))


static func from_dict(data: Dictionary) -> PlayerLoadoutResource:
	var hand: PlayerLoadoutResource = PlayerLoadoutResource.new()
	hand.from_network_dict(data)
	return hand


## A separate copy, safe to edit.
func copy() -> PlayerLoadoutResource:
	return from_dict(to_network_dict())


func same_as(other: PlayerLoadoutResource) -> bool:
	return other != null and to_network_dict() == other.to_network_dict()
