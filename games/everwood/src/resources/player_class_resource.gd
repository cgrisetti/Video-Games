## A playable class of the Holy Trinity, already turned into one of its three
## Callings (Callings.apply): its role, base numbers, the kit it starts with,
## and what its Secondary Calling adds: potency, stamina, memory and the gear
## it may use. What it swings and casts comes from its equipment and Scribe
## Cards; LoadoutComposer combines the two into the ClassLoadoutResource an
## actor runs.
class_name PlayerClassResource
extends Resource

## The Primary Fellowship (it also picks the raid seat and the starter kit).
@export var class_id: StringName = &""
## The Calling's name ("Weald-Captain").
@export var display_name: String = ""
@export var role: ClassLoadoutResource.Role = ClassLoadoutResource.Role.DPS
@export var body_color: Color = Color.WHITE
## Health, threat and guard numbers; armor adds mitigation, stamina regen,
## roll distance and the Perfect Guard window on top.
@export var base_stats: CharacterStatsResource
## D-Pad binds Soul Tethers to party members (healers).
@export var has_soul_tethers: bool = false
@export var starter_kit: EquipmentLoadoutResource

@export_group("Calling")
## The Secondary Calling (Callings.Secondary).
@export var calling: int = 0
@export var fellowship_name: String = ""
@export var calling_subtitle: String = ""
## Added to the armor's stamina regen (per second).
@export var stamina_regen_bonus: float = 0.0
## Added to the armor's Perfect Guard window (seconds).
@export var perfect_guard_bonus: float = 0.0
## Multiply every strike's damage, every hit's poise damage, and every heal.
@export var strike_damage_multiplier: float = 1.0
@export var poise_damage_multiplier: float = 1.0
@export var heal_multiplier: float = 1.0
## Extra Grimoire Memory.
@export var bonus_memory: int = 0
## Weapon types and armor weights this Calling may use (EquipmentItemResource enums).
@export var allowed_weapon_types: Array[int] = []
@export var allowed_armor_weights: Array[int] = []


func allows(item: EquipmentItemResource) -> bool:
	if item == null:
		return false
	if item.is_weapon():
		return allowed_weapon_types.has(item.weapon_type)
	return allowed_armor_weights.has(item.armor_weight)
