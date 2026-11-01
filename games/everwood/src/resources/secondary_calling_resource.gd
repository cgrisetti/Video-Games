## One of the three Secondary Callings (06_WORLD_AND_CALLINGS.md §3, 07 GDD §1.3):
## the composable modifier a hero takes on top of their Fellowship. Pure data,
## registered in the ArsenalCatalog by id (&"swift_foot"); the party roster and
## save files carry only that id. Callings applies it to a class.
class_name SecondaryCallingResource
extends Resource

@export var calling_id: StringName = &""
## Its column in the 3x3 matrix (Callings.Secondary).
@export var column: int = 0
## "Swift Foot", and the seat it leans toward: "+DPS".
@export var display_name: String = ""
@export var tag: String = ""
## The puppet's trim and tabard colour.
@export var trim_color: Color = Color.WHITE

@export_group("Modifiers")
@export var health_bonus: float = 0.0
## Added to the armor's stamina regen (per second).
@export var stamina_regen_bonus: float = 0.0
## Added to the armor's Perfect Guard window (seconds).
@export var perfect_guard_bonus: float = 0.0
@export var strike_damage_multiplier: float = 1.0
@export var poise_damage_multiplier: float = 1.0
@export var heal_multiplier: float = 1.0
## Every pip earned is multiplied by this.
@export var resonance_gain_multiplier: float = 1.0
@export var bonus_memory: int = 0

@export_group("Gear it unlocks")
## EquipmentItemResource.WeaponType and ArmorWeight values.
@export var unlocked_weapon_types: Array[int] = []
@export var unlocked_armor_weights: Array[int] = []


## "Swift Foot (+DPS)".
func label() -> String:
	return "%s (%s)" % [display_name, tag]


## What it adds, in a line for the Scribe Desk, worked out from the numbers.
func summary() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if health_bonus != 0.0:
		parts.append("%+d health" % roundi(health_bonus))
	if stamina_regen_bonus != 0.0:
		parts.append("%+d stamina a second" % roundi(stamina_regen_bonus))
	if strike_damage_multiplier != 1.0:
		parts.append("%+d%% strike damage" % roundi((strike_damage_multiplier - 1.0) * 100.0))
	if poise_damage_multiplier != 1.0:
		parts.append("%+d%% poise damage" % roundi((poise_damage_multiplier - 1.0) * 100.0))
	if perfect_guard_bonus != 0.0:
		parts.append("%+d ms Perfect Guard" % roundi(perfect_guard_bonus * 1000.0))
	if resonance_gain_multiplier != 1.0:
		parts.append("%+d%% pips" % roundi((resonance_gain_multiplier - 1.0) * 100.0))
	if heal_multiplier != 1.0:
		parts.append("%+d%% healing" % roundi((heal_multiplier - 1.0) * 100.0))
	if bonus_memory != 0:
		parts.append("%+d Grimoire Memory" % bonus_memory)
	var gear: PackedStringArray = PackedStringArray()
	for weight: int in unlocked_armor_weights:
		gear.append(String(EquipmentItemResource.ArmorWeight.keys()[weight]).to_lower() + " armor")
	for weapon_type: int in unlocked_weapon_types:
		gear.append(String(EquipmentItemResource.WeaponType.keys()[weapon_type]).replace("_", " ").to_lower())
	if not gear.is_empty():
		parts.append("unlocks " + " and ".join(gear))
	return ", ".join(parts)
