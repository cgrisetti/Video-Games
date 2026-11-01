## A playable class of the Holy Trinity: its role, base numbers and the kit
## it starts with. What it swings and casts comes from its equipment and Scribe
## Cards; LoadoutComposer combines the two into the ClassLoadoutResource an
## actor runs.
class_name PlayerClassResource
extends Resource

@export var class_id: StringName = &""
@export var display_name: String = ""
@export var role: ClassLoadoutResource.Role = ClassLoadoutResource.Role.DPS
@export var body_color: Color = Color.WHITE
## Health, threat and guard numbers; armor adds mitigation, stamina regen,
## roll distance and the Perfect Guard window on top.
@export var base_stats: CharacterStatsResource
## D-Pad binds Soul Tethers to party members (healers).
@export var has_soul_tethers: bool = false
@export var starter_kit: EquipmentLoadoutResource
