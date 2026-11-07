## A hero's Seals and the frame they're pressed on (24_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md;
## the Google Doc *Everwood Equipment & Grimoire Architecture* §3): the material
## tiers its weapon and armour were promoted to, its youth silhouette, and the
## three Equipment Seals pressed onto the weapon, the offhand (buckler, quiver,
## censer or a maul's Pommel-Knot) and the mantle. Each opens at a Character
## Level (Lv 3, 6, 11) and no title is pressed twice.
##
## The rest of the seven-card hand lives in the kit's sockets: the L, R and L+R
## cards and the one Tuck (EquipmentLoadoutResource, LoadoutComposer). The four
## pocket fields below are the Seal-and-Tuck branch's, kept so its saves read;
## they never open any more.
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
## The Google Doc's bands: Stage 3 runs to Lv 16, Stage 4 is Lv 17 to 20.
const STAGE_MAX_LEVELS: Array[int] = [0, 5, 10, 16, 20]
## How many seal slots each stage opens (index = stage): the weapon's (Lv 3), the offhand's
## (Lv 6), the mantle's (Lv 11). The hand's four pocket slots never open any more: the L, R
## and L+R cards and the Tuck live in the kit's sockets (24 GDD R4, R5).
const SEALS_OPEN: Array[int] = [0, 1, 2, 3, 3]
const ACTIVES_OPEN: Array[int] = [0, 0, 0, 0, 0]
## The level each slot opens at, in HandSlot order (the four pocket slots: never).
const SLOT_OPEN_LEVELS: Array[int] = [3, 6, 11, 99, 99, 99, 99]
const BODY_TYPE_NAMES: Array[String] = ["Male Youth", "Female Youth"]
const TRIGGER_NAMES: Array[String] = ["L", "R", "L+R"]
const HAND_SLOT_COUNT: int = 7
## What the bench calls each slot (HandSlot order).
const HAND_SLOT_NAMES: Array[String] = ["Weapon", "Off-Hand", "Mantle", "L", "L tuck", "R", "R tuck"]

@export var body_type: YouthBodyType = YouthBodyType.BODY_MALE_YOUTH
@export var calling_id: StringName = &"CALLING_SHIELD_SWORN"
@export var weapon_archetype: int = EquipmentTierResource.WeaponArchetype.WEAPON_SWORD_BOARD
@export var armor_weight_class: int = EquipmentTierResource.ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN
## The weapon's (and its offhand's) material tier, promoted at the Forge.
@export var equipped_tier_id: StringName = &"TIER_1_HOMESTEAD"
## The armour's material tier, promoted on its own (24 GDD §2). Empty reads as the weapon's.
@export var armor_tier_id: StringName = &""

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


## Each pressed seal with the slot it sits in: [[SealSlotMask flag, card id], ...].
func seal_slots() -> Array[Array]:
	return [[ScribeCardResource.SealSlotMask.SEAL_WEAPON, weapon_seal_card_id],
		[ScribeCardResource.SealSlotMask.SEAL_OFFHAND_BUCKLER, offhand_seal_card_id],
		[ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR, mantle_seal_card_id]]


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


## Whether a slot is open at a stage and level, exactly as trim_to_stage leaves it: the
## level must reach the slot's (GrimoireRules), and a playtest's forced stage caps it.
static func slot_open(slot: int, stage: int, true_level: int) -> bool:
	if slot < 0 or slot >= HAND_SLOT_COUNT:
		return false
	var opens: int = SLOT_OPEN_LEVELS[slot]
	return true_level >= opens and stage >= stage_for_true_level(opens)


## The Character Level that opens a slot: Lv 3 the weapon Seal, 6 the offhand's, 11 the mantle's.
static func slot_open_level(slot: int) -> int:
	return SLOT_OPEN_LEVELS[clampi(slot, 0, HAND_SLOT_COUNT - 1)]


## When a locked slot opens, in a few words: "opens at Lv 6".
static func slot_opens_text(slot: int) -> String:
	var opens: int = slot_open_level(slot)
	return "opens at Lv %d" % opens if opens <= STAGE_MAX_LEVELS[STAGE_APEX] else "is in the Cross now"


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


## Whether the hand fits a stage's slots: no more seals than it opened, no pocket cards,
## and no title twice (24 GDD R5).
func validate_loadout_for_stage(progression_stage: int) -> bool:
	var stage: int = clampi(progression_stage, STAGE_HOMESTEAD, STAGE_APEX)
	return seal_count() <= seals_open_at_stage(stage) and active_count() == 0 \
		and GrimoireRules.duplicate_title(seal_card_ids()) == &""


## Takes off whatever the level (and a playtest's forced stage) hasn't opened yet.
func trim_to_stage(progression_stage: int, true_level: int = STAGE_MAX_LEVELS[STAGE_APEX]) -> void:
	var stage: int = clampi(progression_stage, STAGE_HOMESTEAD, STAGE_APEX)
	for slot: int in HAND_SLOT_COUNT:
		if not slot_open(slot, stage, true_level):
			set_card_in_slot(slot, &"")


# --- Across the network and into saves (Gate 4) --------------------------------------

## Strings and ints only.
func to_network_dict() -> Dictionary:
	return {
		"body_type": int(body_type),
		"calling_id": String(calling_id),
		"weapon_archetype": int(weapon_archetype),
		"armor_weight_class": int(armor_weight_class),
		"equipped_tier_id": String(equipped_tier_id),
		"armor_tier_id": String(armor_tier_id),
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
	armor_tier_id = StringName(str(data.get("armor_tier_id", "")))
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
