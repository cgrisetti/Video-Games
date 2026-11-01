## One of the nine Callings (06_WORLD_AND_CALLINGS.md §3): a Fellowship (its
## class) taking one Secondary Calling, and the names that pair goes by. Pure
## data, registered in the ArsenalCatalog by id (&"weald_captain").
class_name CallingResource
extends Resource

@export var calling_id: StringName = &""
## "Weald-Captain", and its subtitle, "Vanguard of the Green Company".
@export var display_name: String = ""
@export var subtitle: String = ""
## The Fellowship (a class id) and the Secondary Calling (an id) it combines.
@export var fellowship_class_id: StringName = &""
@export var secondary_id: StringName = &""
