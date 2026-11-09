## Forging Fog (Q05's Blighted Taproot Stag; docs/28 §7.4, docs/29 §5): a hero
## caught in it has one or two of their Cross's card sockets greyed over with a
## padlock for a while. A fogged socket won't play (EquipmentSealComponent) and
## reads padlocked on the HUD. Hearth-Ward clears it.
##
## Kept on every peer (the encounter tells them all), by hero id and socket
## (GrimoireRules.SOCKET_L / _R / _LR), with the game time it lifts at.
class_name CardFog
extends RefCounted

static var _fogged: Dictionary = {}


## Greys `sockets` over on a hero for `seconds`.
static func fog(player_id: StringName, sockets: Array[int], seconds: float) -> void:
	var until: float = CombatDirector.game_time() + seconds
	var held: Dictionary = _fogged.get(String(player_id), {})
	for socket: int in sockets:
		held[socket] = maxf(float(held.get(socket, 0.0)), until)
	_fogged[String(player_id)] = held


static func clear(player_id: StringName) -> void:
	_fogged.erase(String(player_id))


static func is_fogged(player_id: StringName, socket: int) -> bool:
	var held: Dictionary = _fogged.get(String(player_id), {})
	return float(held.get(socket, 0.0)) > CombatDirector.game_time()


## The sockets fogged on a hero right now.
static func fogged_sockets(player_id: StringName) -> Array[int]:
	var found: Array[int] = []
	var held: Dictionary = _fogged.get(String(player_id), {})
	for socket: Variant in held:
		if float(held[socket]) > CombatDirector.game_time():
			found.append(int(socket))
	return found


static func any_fogged(player_id: StringName) -> bool:
	return not fogged_sockets(player_id).is_empty()


static func reset() -> void:
	_fogged.clear()
