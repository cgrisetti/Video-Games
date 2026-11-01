## A player's equipment kit (05_ARSENAL_AND_CARDS_GDD.md §2–3): an armor, a
## weapon, four lead cards (with the variant of each copy) and four under-cards
## linked beneath them. Ids only, so a kit is a few short strings on the
## network, in the roster and in save files; LoadoutComposer turns it into
## actions by looking the ids up in the ArsenalCatalog.
class_name EquipmentLoadoutResource
extends Resource

const SLOT_COUNT: int = 4

@export var armor_id: StringName = &""
@export var weapon_id: StringName = &""
## One per Grimoire slot (Forward, Back, Signature, Ultimate).
@export var lead_ids: Array[StringName] = [&"", &"", &"", &""]
## A ScribeCardResource.CardVariant per lead card.
@export var lead_variants: Array[int] = [0, 0, 0, 0]
## &"" is an empty link.
@export var under_ids: Array[StringName] = [&"", &"", &"", &""]


static func make(armor: StringName, weapon: StringName, leads: Array[StringName]) -> EquipmentLoadoutResource:
	var kit: EquipmentLoadoutResource = EquipmentLoadoutResource.new()
	kit.armor_id = armor
	kit.weapon_id = weapon
	for slot: int in mini(SLOT_COUNT, leads.size()):
		kit.lead_ids[slot] = leads[slot]
	return kit


## A separate copy (arrays included), safe to edit.
func copy() -> EquipmentLoadoutResource:
	return from_dict(to_dict())


func lead_variant(slot: int) -> ScribeCardResource.CardVariant:
	return lead_variants[slot] as ScribeCardResource.CardVariant


func lead_copy_key(slot: int) -> StringName:
	return ScribeCardResource.copy_key(lead_ids[slot], lead_variant(slot))


func linked_under_count() -> int:
	var count: int = 0
	for under: StringName in under_ids:
		if under != &"":
			count += 1
	return count


func same_as(other: EquipmentLoadoutResource) -> bool:
	return other != null and to_dict() == other.to_dict()


## Plain strings and ints: safe for RPCs, ConfigFile and JSON alike.
func to_dict() -> Dictionary:
	var leads: Array[String] = []
	var unders: Array[String] = []
	for slot: int in SLOT_COUNT:
		leads.append(String(lead_ids[slot]))
		unders.append(String(under_ids[slot]))
	return {
		"armor": String(armor_id),
		"weapon": String(weapon_id),
		"leads": leads,
		"variants": lead_variants.duplicate(),
		"unders": unders,
	}


## Reads a kit back, tolerating missing keys and short arrays (old saves, bad packets).
static func from_dict(data: Dictionary) -> EquipmentLoadoutResource:
	var kit: EquipmentLoadoutResource = EquipmentLoadoutResource.new()
	kit.armor_id = StringName(str(data.get("armor", "")))
	kit.weapon_id = StringName(str(data.get("weapon", "")))
	var leads: Array = data.get("leads", []) as Array
	var variants: Array = data.get("variants", []) as Array
	var unders: Array = data.get("unders", []) as Array
	for slot: int in SLOT_COUNT:
		if slot < leads.size():
			kit.lead_ids[slot] = StringName(str(leads[slot]))
		if slot < variants.size():
			kit.lead_variants[slot] = clampi(int(variants[slot]), 0, ScribeCardResource.CardVariant.size() - 1)
		if slot < unders.size():
			kit.under_ids[slot] = StringName(str(unders[slot]))
	return kit
