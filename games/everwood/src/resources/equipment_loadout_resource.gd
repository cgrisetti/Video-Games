## A player's equipment kit (05_ARSENAL_AND_CARDS_GDD.md §2–3): an armor, a
## weapon, four lead cards (with the variant of each copy) and four under-cards
## linked beneath them. Ids only, so a kit is a few short strings on the
## network, in the roster and in save files; LoadoutComposer turns it into
## actions by looking the ids up in the ArsenalCatalog.
##
## It also holds the Sign-Flow dioramas (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §4):
## the three diamond sockets L, R and L+R each pair an Action-Leaf with a
## Place-Card. R's and L+R's leaves are the Signature and Ultimate lead cards;
## L has a leaf of its own (its Counter-Brace). Kits saved before Phase 12
## read back with empty dioramas.
class_name EquipmentLoadoutResource
extends Resource

const SLOT_COUNT: int = 4
const SOCKET_COUNT: int = 3

@export var armor_id: StringName = &""
@export var weapon_id: StringName = &""
## One per Grimoire slot (Forward, Back, Signature, Ultimate).
@export var lead_ids: Array[StringName] = [&"", &"", &"", &""]
## A ScribeCardResource.CardVariant per lead card.
@export var lead_variants: Array[int] = [0, 0, 0, 0]
## &"" is an empty link.
@export var under_ids: Array[StringName] = [&"", &"", &"", &""]
## The L socket's Action-Leaf (&"": an un-inked guard) and its copy's finish.
@export var guard_leaf_id: StringName = &""
@export var guard_leaf_variant: int = 0
## The Place-Card framing each socket (L, R, L+R; &"" for none) and its copy's finish.
@export var place_ids: Array[StringName] = [&"", &"", &""]
@export var place_variants: Array[int] = [0, 0, 0]


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


## The Action-Leaf in a diorama socket (ScribeCardResource.DioramaSocket), &"" when un-inked.
func socket_leaf_id(socket: int) -> StringName:
	var slot: int = ScribeCardResource.SOCKET_GRIMOIRE_SLOTS[socket]
	return guard_leaf_id if slot < 0 else lead_ids[slot]


func socket_leaf_variant(socket: int) -> ScribeCardResource.CardVariant:
	var slot: int = ScribeCardResource.SOCKET_GRIMOIRE_SLOTS[socket]
	return (guard_leaf_variant if slot < 0 else lead_variants[slot]) as ScribeCardResource.CardVariant


func set_socket_leaf(socket: int, card_id: StringName, variant: int) -> void:
	var slot: int = ScribeCardResource.SOCKET_GRIMOIRE_SLOTS[socket]
	if slot < 0:
		guard_leaf_id = card_id
		guard_leaf_variant = variant
	else:
		lead_ids[slot] = card_id
		lead_variants[slot] = variant


func socket_place_variant(socket: int) -> ScribeCardResource.CardVariant:
	return place_variants[socket] as ScribeCardResource.CardVariant


func set_socket_place(socket: int, card_id: StringName, variant: int) -> void:
	place_ids[socket] = card_id
	place_variants[socket] = variant if card_id != &"" else 0


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
	var places: Array[String] = []
	for socket: int in SOCKET_COUNT:
		places.append(String(place_ids[socket]))
	return {
		"armor": String(armor_id),
		"weapon": String(weapon_id),
		"leads": leads,
		"variants": lead_variants.duplicate(),
		"unders": unders,
		"guard_leaf": String(guard_leaf_id),
		"guard_variant": guard_leaf_variant,
		"places": places,
		"place_variants": place_variants.duplicate(),
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
	var last_variant: int = ScribeCardResource.CardVariant.size() - 1
	kit.guard_leaf_id = StringName(str(data.get("guard_leaf", "")))
	kit.guard_leaf_variant = clampi(int(data.get("guard_variant", 0)), 0, last_variant)
	var places: Array = data.get("places", []) as Array
	var place_variants_read: Array = data.get("place_variants", []) as Array
	for socket: int in SOCKET_COUNT:
		if socket < places.size():
			kit.place_ids[socket] = StringName(str(places[socket]))
		if socket < place_variants_read.size():
			kit.place_variants[socket] = clampi(int(place_variants_read[socket]), 0, last_variant)
	return kit
