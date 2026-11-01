## The 3x3 Matrix of Callings (06_WORLD_AND_CALLINGS.md §3, 07 GDD §1.3).
##
## A hero's Primary Fellowship is their class, which sets their raid seat
## (Tank, DPS or Mender). Their Secondary Calling (Stout Heart, Swift Foot or
## Wise Hand) is one composable modifier on top: a little health, stamina and
## potency, and the gear it unlocks. Together they name the Calling: a
## Shield-Sworn with a Swift Foot is a Weald-Captain.
##
## All nine names are in NAMES, the one place to rename them. The numbers are
## named constants below; ClassLoadouts applies them to the class
## (PlayerClassResource) and LoadoutComposer to its actions.
class_name Callings
extends RefCounted

enum Secondary { STOUT_HEART, SWIFT_FOOT, WISE_HAND }

## The matrix's rows, in order: the Shield-Sworn (Tank), the Wayfarers (DPS)
## and the Lantern-Bearers (Magic), by class id.
const FELLOWSHIP_CLASSES: Array[StringName] = [&"shield_tank", &"directional_flow_dps", &"soul_tether_healer"]
const FELLOWSHIP_NAMES: Array[String] = ["The Shield-Sworn", "The Wayfarers", "The Lantern-Bearers"]
## One member of each Fellowship, for "P1 is now a Wayfarer".
const FELLOWSHIP_MEMBERS: Array[String] = ["Shield-Sworn", "Wayfarer", "Lantern-Bearer"]
const SECONDARY_NAMES: Array[String] = ["Stout Heart", "Swift Foot", "Wise Hand"]
const SECONDARY_TAGS: Array[String] = ["+Tank", "+DPS", "+Magic"]
## The nine Callings, row by row (Fellowship) then column by column (Secondary),
## as the Creative Director named them (06 §3, chosen 2026-11-01).
const NAMES: Array[String] = [
	"Bridge-Warden", "Weald-Captain", "Hearth-Guard",
	"Iron-Woodsman", "Hedge-Runner", "Sign-Seeker",
	"Bell-Keeper", "Wind-Mender", "Lantern-Scribe",
]
const SUBTITLES: Array[String] = [
	"Keeper of the Stone-Span", "Vanguard of the Green Company", "Watcher of the Kindled Stone",
	"Hewn-Hand of the High Pines", "Outrider of the Bramble-Ways", "Journeyman of the Four Signs",
	"Ringer of the Sanctuary Chime", "Weather-Worker of the Sound", "Bearer of the Reed-Light",
]

# Stout Heart (+Tank): sturdier and steadier, a little slower to breathe.
const STOUT_HEALTH: float = 20.0
const STOUT_STAMINA_REGEN: float = -2.0
const STOUT_POISE_DAMAGE: float = 1.25
const STOUT_PERFECT_GUARD: float = 0.03
# Swift Foot (+DPS): quicker breath and harder hits.
const SWIFT_STAMINA_REGEN: float = 3.0
const SWIFT_STRIKE_DAMAGE: float = 1.15
# Wise Hand (+Magic): pips and mending, and room for one more card.
const WISE_HEALTH: float = -5.0
const WISE_STAMINA_REGEN: float = 2.0
const WISE_PIP_GAIN: float = 1.2
const WISE_HEAL_POTENCY: float = 1.2
const WISE_MEMORY: int = 1

const Weapon = EquipmentItemResource.WeaponType
const Weight = EquipmentItemResource.ArmorWeight

## Gear anyone may use: the sword, and light or medium armor.
const COMMON_WEAPONS: Array[int] = [Weapon.LIGHT_SWORD]
const COMMON_ARMOR: Array[int] = [Weight.LIGHT, Weight.MEDIUM]
## What each Secondary unlocks. A Fellowship always has its own column's gear
## too (the Shield-Sworn wear plate, Wayfarers carry bows and axes,
## Lantern-Bearers bear staves), so its double-down Calling adds no gear, only numbers.
const UNLOCKED_WEAPONS: Array[Array] = [[], [Weapon.BOW, Weapon.HEAVY_AXE], [Weapon.STAFF]]
const UNLOCKED_ARMOR: Array[Array] = [[Weight.HEAVY], [], []]


## The class's row in the matrix (an unknown class reads as a Wayfarer).
static func fellowship_row(class_id: StringName) -> int:
	var row: int = FELLOWSHIP_CLASSES.find(class_id)
	return row if row >= 0 else Secondary.SWIFT_FOOT


## A new seat's Calling: its own Fellowship's column (Bridge-Warden, Hedge-Runner, Lantern-Scribe).
static func default_secondary(class_id: StringName) -> int:
	return fellowship_row(class_id)


static func is_valid(secondary: int) -> bool:
	return secondary >= 0 and secondary < SECONDARY_NAMES.size()


## `secondary` if it's a real Calling column, otherwise the class's default.
static func resolve(class_id: StringName, secondary: int) -> int:
	return secondary if is_valid(secondary) else default_secondary(class_id)


static func next_secondary(secondary: int) -> int:
	return wrapi(secondary + 1, 0, SECONDARY_NAMES.size())


static func calling_name(class_id: StringName, secondary: int) -> String:
	return NAMES[fellowship_row(class_id) * 3 + resolve(class_id, secondary)]


static func subtitle(class_id: StringName, secondary: int) -> String:
	return SUBTITLES[fellowship_row(class_id) * 3 + resolve(class_id, secondary)]


static func fellowship_name(class_id: StringName) -> String:
	return FELLOWSHIP_NAMES[fellowship_row(class_id)]


static func fellowship_member(class_id: StringName) -> String:
	return FELLOWSHIP_MEMBERS[fellowship_row(class_id)]


## "Swift Foot (+DPS)".
static func secondary_label(secondary: int) -> String:
	return "%s (%s)" % [SECONDARY_NAMES[secondary], SECONDARY_TAGS[secondary]] if is_valid(secondary) else ""


## Weapon types (EquipmentItemResource.WeaponType) this Fellowship and Calling may carry.
static func allowed_weapons(class_id: StringName, secondary: int) -> Array[int]:
	var allowed: Array[int] = COMMON_WEAPONS.duplicate()
	for column: int in [fellowship_row(class_id), resolve(class_id, secondary)]:
		for weapon_type: int in UNLOCKED_WEAPONS[column]:
			if not allowed.has(weapon_type):
				allowed.append(weapon_type)
	return allowed


## Armor weights (EquipmentItemResource.ArmorWeight) this Fellowship and Calling may wear.
static func allowed_armor(class_id: StringName, secondary: int) -> Array[int]:
	var allowed: Array[int] = COMMON_ARMOR.duplicate()
	for column: int in [fellowship_row(class_id), resolve(class_id, secondary)]:
		for weight: int in UNLOCKED_ARMOR[column]:
			if not allowed.has(weight):
				allowed.append(weight)
	return allowed


## The Secondary that unlocks an item, or -1 if anyone may use it.
static func unlocked_by(item: EquipmentItemResource) -> int:
	for column: int in SECONDARY_NAMES.size():
		if item.is_weapon() and UNLOCKED_WEAPONS[column].has(item.weapon_type):
			return column
		if item.is_armor() and UNLOCKED_ARMOR[column].has(item.armor_weight):
			return column
	return -1


## What a Secondary adds, in a line for the Scribe Desk.
static func summary(secondary: int) -> String:
	match secondary:
		Secondary.STOUT_HEART:
			return "+%d health, %d stamina a second, +%d%% poise damage, +%d ms Perfect Guard, and heavy plate" % [
				roundi(STOUT_HEALTH), roundi(STOUT_STAMINA_REGEN), roundi((STOUT_POISE_DAMAGE - 1.0) * 100.0), roundi(STOUT_PERFECT_GUARD * 1000.0)]
		Secondary.SWIFT_FOOT:
			return "+%d stamina a second, +%d%% strike damage, and bows and axes" % [roundi(SWIFT_STAMINA_REGEN), roundi((SWIFT_STRIKE_DAMAGE - 1.0) * 100.0)]
		Secondary.WISE_HAND:
			return "%d health, +%d stamina a second, +%d%% pips and healing, +%d Grimoire Memory, and staves" % [
				roundi(WISE_HEALTH), roundi(WISE_STAMINA_REGEN), roundi((WISE_PIP_GAIN - 1.0) * 100.0), WISE_MEMORY]
	return ""


## Turns a plain class into one of its three Callings: its name, its numbers
## and its gear. ClassLoadouts calls this on a fresh class.
static func apply(made: PlayerClassResource, secondary: int) -> void:
	var column: int = resolve(made.class_id, secondary)
	made.calling = column
	made.fellowship_name = fellowship_name(made.class_id)
	made.display_name = calling_name(made.class_id, column)
	made.calling_subtitle = subtitle(made.class_id, column)
	made.allowed_weapon_types = allowed_weapons(made.class_id, column)
	made.allowed_armor_weights = allowed_armor(made.class_id, column)
	match column:
		Secondary.STOUT_HEART:
			made.base_stats.max_health += STOUT_HEALTH
			made.stamina_regen_bonus = STOUT_STAMINA_REGEN
			made.poise_damage_multiplier = STOUT_POISE_DAMAGE
			made.perfect_guard_bonus = STOUT_PERFECT_GUARD
		Secondary.SWIFT_FOOT:
			made.stamina_regen_bonus = SWIFT_STAMINA_REGEN
			made.strike_damage_multiplier = SWIFT_STRIKE_DAMAGE
		Secondary.WISE_HAND:
			made.base_stats.max_health += WISE_HEALTH
			made.stamina_regen_bonus = WISE_STAMINA_REGEN
			made.base_stats.resonance_gain_multiplier = WISE_PIP_GAIN
			made.heal_multiplier = WISE_HEAL_POTENCY
			made.bonus_memory = WISE_MEMORY
