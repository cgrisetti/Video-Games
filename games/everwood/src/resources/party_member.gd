## One seat in the raid party, as the Network Manager's roster records it.
## `player_id` is the composite "{peer_id}_{device_id}" address. An AI
## companion's seat belongs to the host, on a device id no controller uses.
class_name PartyMember
extends RefCounted

var player_id: StringName = &""
var peer_id: int = 1
var device_id: int = 0
var class_id: StringName = &""
## The Secondary Calling by its ArsenalCatalog id (&"swift_foot"); empty until the host picks one.
var calling: StringName = &""
var assist_mode: int = 0
## Join order across the whole party; decides spawn point and Soul Tether slot.
var slot: int = 0
## An AI companion filling a role, not a person.
var companion: bool = false
## The seat's equipment kit as EquipmentLoadoutResource.to_dict() ids (an opaque
## Dictionary here, so the network layer doesn't need to know what's in it).
var kit: Dictionary = {}
## The Seal-and-Tuck hand the player chose at the Binder's stamping bench, as
## PlayerLoadoutResource.to_network_dict() Strings and ints ({} wears the role's default).
var seal_hand: Dictionary = {}


static func make_player_id(for_peer: int, for_device: int) -> StringName:
	return StringName("%d_%d" % [for_peer, for_device])


func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"peer_id": peer_id,
		"device_id": device_id,
		"class_id": class_id,
		"calling": String(calling),
		"assist_mode": assist_mode,
		"slot": slot,
		"companion": companion,
		"kit": kit,
		"seal_hand": seal_hand,
	}


static func from_dict(data: Dictionary) -> PartyMember:
	var member: PartyMember = PartyMember.new()
	member.peer_id = int(data.get("peer_id", 1))
	member.device_id = int(data.get("device_id", 0))
	member.player_id = make_player_id(member.peer_id, member.device_id)
	member.class_id = StringName(data.get("class_id", &""))
	member.calling = StringName(str(data.get("calling", "")))
	member.assist_mode = int(data.get("assist_mode", 0))
	member.slot = int(data.get("slot", 0))
	member.companion = bool(data.get("companion", false))
	member.kit = data.get("kit", {}) as Dictionary
	member.seal_hand = data.get("seal_hand", {}) as Dictionary
	return member


func display_label() -> String:
	return "P%d" % (slot + 1)
