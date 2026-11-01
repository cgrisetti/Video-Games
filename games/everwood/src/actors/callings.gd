## The 3x3 Matrix of Callings (06_WORLD_AND_CALLINGS.md §3, 07 GDD §1.3).
##
## A hero's Primary Fellowship is their class, which sets their raid seat
## (Tank, DPS or Mender). Their Secondary Calling (Stout Heart, Swift Foot or
## Wise Hand) is one composable modifier on top: a little health, stamina and
## potency, and the gear it unlocks. Together they name the Calling: a
## Shield-Sworn with a Swift Foot is a Weald-Captain.
##
## The Secondaries and the nine Callings are typed data registered in the
## ArsenalCatalog by id (SecondaryCallingResource, CallingResource; 08 Gate 4).
## This class reads them: it turns a class and a column into a Calling, applies
## a Secondary to a class (ClassLoadouts calls it), and converts between the
## column code works with and the id the roster and save files carry.
class_name Callings
extends RefCounted

## The matrix's columns, in the order the ArsenalCatalog registers them.
enum Secondary { STOUT_HEART, SWIFT_FOOT, WISE_HAND }

## The matrix's rows, in order: the Shield-Sworn (Tank), the Wayfarers (DPS)
## and the Lantern-Bearers (Magic), by class id. A Fellowship's own column is
## the one with the same index (the Shield-Sworn's is Stout Heart).
const FELLOWSHIP_CLASSES: Array[StringName] = [&"shield_tank", &"directional_flow_dps", &"soul_tether_healer"]
const FELLOWSHIP_NAMES: Array[String] = ["The Shield-Sworn", "The Wayfarers", "The Lantern-Bearers"]
## One member of each Fellowship, for "P1 is now a Wayfarer".
const FELLOWSHIP_MEMBERS: Array[String] = ["Shield-Sworn", "Wayfarer", "Lantern-Bearer"]

const Weapon = EquipmentItemResource.WeaponType
const Weight = EquipmentItemResource.ArmorWeight

## Gear anyone may use: the sword, and light or medium armor.
const COMMON_WEAPONS: Array[int] = [Weapon.LIGHT_SWORD]
const COMMON_ARMOR: Array[int] = [Weight.LIGHT, Weight.MEDIUM]


## The class's row in the matrix (an unknown class reads as a Wayfarer).
static func fellowship_row(class_id: StringName) -> int:
	var row: int = FELLOWSHIP_CLASSES.find(class_id)
	return row if row >= 0 else Secondary.SWIFT_FOOT


## A new seat's Calling: its own Fellowship's column (Bridge-Warden, Hedge-Runner, Lantern-Scribe).
static func default_secondary(class_id: StringName) -> int:
	return fellowship_row(class_id)


## How many Secondary Callings are registered (three).
static func count() -> int:
	return ArsenalCatalog.current.secondary_callings().size()


static func is_valid(column: int) -> bool:
	return column >= 0 and column < count()


## `column` if it's a registered Secondary, otherwise the class's default.
static func resolve(class_id: StringName, column: int) -> int:
	return column if is_valid(column) else default_secondary(class_id)


static func next_secondary(column: int) -> int:
	return wrapi(column + 1, 0, count())


## The id the roster and save files carry for a column (&"" if there's none).
static func id_of(column: int) -> StringName:
	var found: SecondaryCallingResource = ArsenalCatalog.current.secondary_at(column)
	return found.calling_id if found != null else &""


## The column for an id (-1 for an unknown or empty one).
static func column_of(id: StringName) -> int:
	var found: SecondaryCallingResource = ArsenalCatalog.current.secondary_calling(id)
	return found.column if found != null else -1


static func secondary(column: int) -> SecondaryCallingResource:
	return ArsenalCatalog.current.secondary_at(column)


## The Calling a class becomes in a column (its own column if `column` isn't one).
static func calling(class_id: StringName, column: int) -> CallingResource:
	return ArsenalCatalog.current.calling_for(class_id, id_of(resolve(class_id, column)))


static func calling_name(class_id: StringName, column: int) -> String:
	var found: CallingResource = calling(class_id, column)
	return found.display_name if found != null else fellowship_member(class_id)


static func subtitle(class_id: StringName, column: int) -> String:
	var found: CallingResource = calling(class_id, column)
	return found.subtitle if found != null else ""


static func fellowship_name(class_id: StringName) -> String:
	return FELLOWSHIP_NAMES[fellowship_row(class_id)]


static func fellowship_member(class_id: StringName) -> String:
	return FELLOWSHIP_MEMBERS[fellowship_row(class_id)]


## "Swift Foot".
static func secondary_name(column: int) -> String:
	return secondary(column).display_name if is_valid(column) else ""


## "Swift Foot (+DPS)".
static func secondary_label(column: int) -> String:
	return secondary(column).label() if is_valid(column) else ""


## What a Secondary adds, in a line for the Scribe Desk.
static func summary(column: int) -> String:
	return secondary(column).summary() if is_valid(column) else ""


## Weapon types (EquipmentItemResource.WeaponType) this Fellowship and Calling may carry:
## the common ones, its own column's and the Calling's.
static func allowed_weapons(class_id: StringName, column: int) -> Array[int]:
	var allowed: Array[int] = COMMON_WEAPONS.duplicate()
	for from: int in [fellowship_row(class_id), resolve(class_id, column)]:
		for weapon_type: int in secondary(from).unlocked_weapon_types:
			if not allowed.has(weapon_type):
				allowed.append(weapon_type)
	return allowed


## Armor weights (EquipmentItemResource.ArmorWeight) this Fellowship and Calling may wear.
static func allowed_armor(class_id: StringName, column: int) -> Array[int]:
	var allowed: Array[int] = COMMON_ARMOR.duplicate()
	for from: int in [fellowship_row(class_id), resolve(class_id, column)]:
		for weight: int in secondary(from).unlocked_armor_weights:
			if not allowed.has(weight):
				allowed.append(weight)
	return allowed


## The column whose Secondary unlocks an item, or -1 if anyone may use it.
static func unlocked_by(item: EquipmentItemResource) -> int:
	for found: SecondaryCallingResource in ArsenalCatalog.current.secondary_callings():
		if item.is_weapon() and found.unlocked_weapon_types.has(item.weapon_type):
			return found.column
		if item.is_armor() and found.unlocked_armor_weights.has(item.armor_weight):
			return found.column
	return -1


## Turns a plain class into one of its three Callings: its name, its numbers
## and its gear. ClassLoadouts calls this on a fresh class.
static func apply(made: PlayerClassResource, column: int) -> void:
	var resolved: int = resolve(made.class_id, column)
	var modifier: SecondaryCallingResource = secondary(resolved)
	made.calling = resolved
	made.fellowship_name = fellowship_name(made.class_id)
	made.display_name = calling_name(made.class_id, resolved)
	made.calling_subtitle = subtitle(made.class_id, resolved)
	made.allowed_weapon_types = allowed_weapons(made.class_id, resolved)
	made.allowed_armor_weights = allowed_armor(made.class_id, resolved)
	made.base_stats.max_health += modifier.health_bonus
	made.base_stats.resonance_gain_multiplier = modifier.resonance_gain_multiplier
	made.stamina_regen_bonus = modifier.stamina_regen_bonus
	made.perfect_guard_bonus = modifier.perfect_guard_bonus
	made.strike_damage_multiplier = modifier.strike_damage_multiplier
	made.poise_damage_multiplier = modifier.poise_damage_multiplier
	made.heal_multiplier = modifier.heal_multiplier
	made.bonus_memory = modifier.bonus_memory
