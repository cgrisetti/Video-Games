## The Network Manager (autoload): ENet hosting and joining on port 7777, and
## the raid party roster.
##
## Each player is addressed as "{peer_id}_{device_id}": the network peer (which
## machine) plus the local controller (which pad on that machine). A machine
## can seat up to 4 split-screen players; the whole party is capped at 5.
##
## The host (peer 1) owns the roster. Other peers ask it to seat their
## controllers and receive the full roster back whenever it changes. Offline
## play runs the same code: Godot's offline peer is peer 1 and acts as host.
##
## Each seat carries its equipment kit (a Dictionary of ids). The host picks a
## new seat's kit (kit_picker) and checks every change a player asks for
## (kit_validator); both are set by the level, so this file knows nothing about
## equipment either.
##
## The host can also seat AI companions (set_companions). They sit on the
## host's peer with device ids from COMPANION_DEVICE_BASE up, never count
## against a screen's 4 players, and always give way to people: people take
## the lowest player numbers, and the party cap counts only people.
class_name NetworkManager
extends Node

## The live autoload node. Scripts reach it as `NetworkManager.current` rather than by
## its autoload name, so `godot --check-only -s` (which runs before autoloads
## are registered) can still compile them.
static var current: NetworkManager

signal player_registered(member: PartyMember)
signal player_updated(member: PartyMember)
signal player_unregistered(player_id: StringName)
signal registration_refused(device_id: int, reason: String)
## The host turned down a kit change for one of this machine's controllers.
signal kit_refused(device_id: int, reason: String)
signal status_changed(status: String)

const PORT: int = 7777
const MAX_PARTY_SIZE: int = 5
const MAX_LOCAL_PLAYERS: int = 4
## Other machines that can join a host (the party cap still applies).
const MAX_REMOTE_PEERS: int = 4
const DEFAULT_ADDRESS: String = "127.0.0.1"
## AI companions use device ids from here up (no controller has one this high).
const COMPANION_DEVICE_BASE: int = 100

var roster: Dictionary[StringName, PartyMember] = {}
var status: String = "Offline"
## Chooses a class for a seat that asked for ANY_CLASS: (roster) -> StringName.
## The level sets it; the network layer itself knows nothing about classes.
var class_picker: Callable
## The Secondary Calling id a new seat gets for a class: (class_id: StringName, companion: bool) -> StringName.
var calling_picker: Callable
## The kit a seat gets for a class and Calling: (class_id: StringName, calling: StringName, companion: bool) -> Dictionary.
var kit_picker: Callable
## Why a seat may not wear a kit, or "": (seat: PartyMember, kit: Dictionary) -> String.
var kit_validator: Callable

## Ask for this class to let the host pick one (see class_picker).
const ANY_CLASS: StringName = &""

## Controllers this machine wants seated: device id -> {class_id, assist_mode}.
## Kept so they can be re-seated after joining or leaving a host.
var _local_wishes: Dictionary[int, Dictionary] = {}


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# --- State ----------------------------------------------------------------

func is_online() -> bool:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	return peer != null and not (peer is OfflineMultiplayerPeer) \
		and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## True offline too: the offline peer hosts its own party.
func is_host() -> bool:
	return multiplayer.is_server()


func local_peer_id() -> int:
	return multiplayer.get_unique_id()


func has_peer(peer_id: int) -> bool:
	return peer_id == 1 or multiplayer.get_peers().has(peer_id)


func party_size() -> int:
	return roster.size()


## Seats held by people (not AI companions).
func human_count() -> int:
	var count: int = 0
	for seat: PartyMember in roster.values():
		if not seat.companion:
			count += 1
	return count


func companion_seats() -> Array[PartyMember]:
	var seats: Array[PartyMember] = []
	for seat: PartyMember in ordered_members():
		if seat.companion:
			seats.append(seat)
	return seats


func member(player_id: StringName) -> PartyMember:
	return roster[player_id] if roster.has(player_id) else null


func ordered_members() -> Array[PartyMember]:
	var members: Array[PartyMember] = []
	members.assign(roster.values())
	members.sort_custom(func(a: PartyMember, b: PartyMember) -> bool: return a.slot < b.slot)
	return members


func local_player_count() -> int:
	return _count_for_peer(local_peer_id())


func is_device_seated(device_id: int) -> bool:
	return _local_wishes.has(device_id)


# --- Hosting and joining --------------------------------------------------

func host_game(port: int = PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_REMOTE_PEERS)
	if error != OK:
		_set_status("Couldn't host on port %d (%s)" % [port, error_string(error)])
		return error
	multiplayer.multiplayer_peer = peer
	# The host is peer 1, exactly like offline, so local player ids don't change.
	_set_status("Hosting on port %d" % port)
	return OK


func join_game(address: String = DEFAULT_ADDRESS, port: int = PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		_set_status("Couldn't join %s:%d (%s)" % [address, port, error_string(error)])
		return error
	# Our controllers get new ids from the host once we're connected.
	_clear_roster()
	multiplayer.multiplayer_peer = peer
	_set_status("Joining %s:%d…" % [address, port])
	return OK


func leave_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_status("Offline")
	_clear_roster()
	for device_id: int in _local_wishes.keys():
		var wish: Dictionary = _local_wishes[device_id]
		_server_register(local_peer_id(), device_id, wish["class_id"], wish["assist_mode"])


# --- Seating local controllers --------------------------------------------

## Asks for a party seat for one of this machine's controllers.
func request_local_player(device_id: int, class_id: StringName, assist_mode: int) -> void:
	if not _local_wishes.has(device_id) and local_player_count() >= MAX_LOCAL_PLAYERS:
		registration_refused.emit(device_id, "This screen already has %d players." % MAX_LOCAL_PLAYERS)
		return
	_local_wishes[device_id] = {"class_id": class_id, "assist_mode": assist_mode}
	if is_host():
		_server_register(local_peer_id(), device_id, class_id, assist_mode)
	elif is_online():
		_request_register.rpc_id(1, device_id, class_id, assist_mode)


## Changing class or assist mode re-seats the controller with the new choice.
func update_local_player(device_id: int, class_id: StringName, assist_mode: int) -> void:
	if _local_wishes.has(device_id):
		request_local_player(device_id, class_id, assist_mode)


## Asks for a different Secondary Calling (hold C / L3, or the Scribe Desk).
## The host makes the switch and swaps out any gear the new Calling can't use.
func update_local_calling(device_id: int, calling: StringName) -> void:
	if not _local_wishes.has(device_id):
		return
	if is_host():
		_server_set_calling(local_peer_id(), device_id, calling)
	elif is_online():
		_request_calling.rpc_id(1, device_id, String(calling))


## Asks to wear a different kit (the Scribe Desk). The host checks it.
func update_local_kit(device_id: int, kit: Dictionary) -> void:
	if not _local_wishes.has(device_id):
		return
	if is_host():
		_server_set_kit(local_peer_id(), device_id, kit)
	elif is_online():
		_request_kit.rpc_id(1, device_id, kit)


func drop_local_player(device_id: int) -> void:
	if not _local_wishes.has(device_id):
		return
	_local_wishes.erase(device_id)
	if is_host():
		_server_unregister(PartyMember.make_player_id(local_peer_id(), device_id))
	elif is_online():
		_request_unregister.rpc_id(1, device_id)


## Whether the host would seat another controller from this peer.
func can_register(peer_id: int, device_id: int) -> bool:
	return roster.has(PartyMember.make_player_id(peer_id, device_id)) or _refusal_reason(peer_id) == ""


# --- Host side ------------------------------------------------------------

func _server_register(peer_id: int, device_id: int, class_id: StringName, assist_mode: int) -> bool:
	var player_id: StringName = PartyMember.make_player_id(peer_id, device_id)
	if roster.has(player_id):
		var existing: PartyMember = roster[player_id]
		if class_id == ANY_CLASS:
			class_id = existing.class_id
		if class_id != existing.class_id:
			existing.calling = _pick_calling(class_id, false)
			existing.kit = _pick_kit(class_id, existing.calling, false)
		existing.class_id = class_id
		existing.assist_mode = assist_mode
		player_updated.emit(existing)
		_broadcast_roster()
		return true
	var reason: String = _refusal_reason(peer_id)
	if reason != "":
		if peer_id == local_peer_id():
			registration_refused.emit(device_id, reason)
		elif is_online() and has_peer(peer_id):
			_registration_refused.rpc_id(peer_id, device_id, reason)
		return false
	if class_id == ANY_CLASS and class_picker.is_valid():
		class_id = class_picker.call(roster)
	var seat: PartyMember = PartyMember.new()
	seat.player_id = player_id
	seat.peer_id = peer_id
	seat.device_id = device_id
	seat.class_id = class_id
	seat.assist_mode = assist_mode
	seat.calling = _pick_calling(class_id, false)
	seat.kit = _pick_kit(class_id, seat.calling, false)
	seat.slot = _free_slot(false)
	roster[player_id] = seat
	player_registered.emit(seat)
	_move_companions_off_people()
	_log_party()
	_broadcast_roster()
	return true


## Host only: makes the AI companion seats match `class_ids`, one seat per entry.
func set_companions(class_ids: Array[StringName]) -> void:
	if not is_host():
		return
	var wanted: Array[StringName] = []
	wanted.assign(class_ids)
	var stale: Array[StringName] = []
	for seat: PartyMember in companion_seats():
		var index: int = wanted.find(seat.class_id)
		if index >= 0:
			wanted.remove_at(index)
		else:
			stale.append(seat.player_id)
	for player_id: StringName in stale:
		_server_unregister(player_id)
	for class_id: StringName in wanted:
		_seat_companion(class_id)


func _seat_companion(class_id: StringName) -> void:
	var device_id: int = COMPANION_DEVICE_BASE
	while roster.has(PartyMember.make_player_id(local_peer_id(), device_id)):
		device_id += 1
	var seat: PartyMember = PartyMember.new()
	seat.player_id = PartyMember.make_player_id(local_peer_id(), device_id)
	seat.peer_id = local_peer_id()
	seat.device_id = device_id
	seat.class_id = class_id
	seat.companion = true
	seat.calling = _pick_calling(class_id, true)
	seat.kit = _pick_kit(class_id, seat.calling, true)
	seat.slot = _free_slot(true)
	roster[seat.player_id] = seat
	player_registered.emit(seat)
	_log_party()
	_broadcast_roster()


func _pick_calling(class_id: StringName, companion: bool) -> StringName:
	return calling_picker.call(class_id, companion) if calling_picker.is_valid() else &""


func _pick_kit(class_id: StringName, calling: StringName, companion: bool) -> Dictionary:
	return kit_picker.call(class_id, calling, companion) if kit_picker.is_valid() else {}


func _server_set_calling(peer_id: int, device_id: int, calling: StringName) -> bool:
	var player_id: StringName = PartyMember.make_player_id(peer_id, device_id)
	if not roster.has(player_id) or calling == &"":
		return false
	var seat: PartyMember = roster[player_id]
	seat.calling = calling
	# Gear the new Calling can't use comes off: the class's saved kit or its starter kit goes on.
	if kit_validator.is_valid() and kit_validator.call(seat, seat.kit) != "":
		seat.kit = _pick_kit(seat.class_id, calling, seat.companion)
	player_updated.emit(seat)
	_broadcast_roster()
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_calling(device_id: int, calling: String) -> void:
	if multiplayer.is_server():
		_server_set_calling(multiplayer.get_remote_sender_id(), device_id, StringName(calling))


func _server_set_kit(peer_id: int, device_id: int, kit: Dictionary) -> bool:
	var player_id: StringName = PartyMember.make_player_id(peer_id, device_id)
	if not roster.has(player_id):
		return false
	var seat: PartyMember = roster[player_id]
	var reason: String = kit_validator.call(seat, kit) if kit_validator.is_valid() else ""
	if reason != "":
		if peer_id == local_peer_id():
			kit_refused.emit(device_id, reason)
		elif is_online() and has_peer(peer_id):
			_kit_refused.rpc_id(peer_id, device_id, reason)
		return false
	seat.kit = kit
	player_updated.emit(seat)
	_broadcast_roster()
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_kit(device_id: int, kit: Dictionary) -> void:
	if multiplayer.is_server():
		_server_set_kit(multiplayer.get_remote_sender_id(), device_id, kit)


@rpc("authority", "call_remote", "reliable")
func _kit_refused(device_id: int, reason: String) -> void:
	kit_refused.emit(device_id, reason)


## A person who just joined may have the same player number as a companion:
## the companion moves to the next free one.
func _move_companions_off_people() -> void:
	for seat: PartyMember in companion_seats():
		for other: PartyMember in roster.values():
			if not other.companion and other.slot == seat.slot:
				seat.slot = _free_slot(true)
				player_updated.emit(seat)
				break


func _server_unregister(player_id: StringName) -> void:
	if not roster.has(player_id):
		return
	roster.erase(player_id)
	player_unregistered.emit(player_id)
	_log_party()
	_broadcast_roster()


func _refusal_reason(peer_id: int) -> String:
	if human_count() >= MAX_PARTY_SIZE:
		return "The party is full (%d players)." % MAX_PARTY_SIZE
	if _count_for_peer(peer_id) >= MAX_LOCAL_PLAYERS:
		return "That screen already has %d players." % MAX_LOCAL_PLAYERS
	return ""


## People seated from one peer (companions don't take a screen's places).
func _count_for_peer(peer_id: int) -> int:
	var count: int = 0
	for seat: PartyMember in roster.values():
		if seat.peer_id == peer_id and not seat.companion:
			count += 1
	return count


## The lowest free player number. People may take a companion's number (the
## companion then moves); companions only take numbers nobody holds.
func _free_slot(for_companion: bool) -> int:
	var used: Dictionary[int, bool] = {}
	for seat: PartyMember in roster.values():
		if for_companion or not seat.companion:
			used[seat.slot] = true
	var slot: int = 0
	while used.has(slot):
		slot += 1
	return slot


func _broadcast_roster() -> void:
	if is_online():
		_receive_roster.rpc(_snapshot())


func _snapshot() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for seat: PartyMember in ordered_members():
		entries.append(seat.to_dict())
	return entries


@rpc("any_peer", "call_remote", "reliable")
func _request_register(device_id: int, class_id: StringName, assist_mode: int) -> void:
	if multiplayer.is_server():
		_server_register(multiplayer.get_remote_sender_id(), device_id, class_id, assist_mode)


@rpc("any_peer", "call_remote", "reliable")
func _request_unregister(device_id: int) -> void:
	if multiplayer.is_server():
		_server_unregister(PartyMember.make_player_id(multiplayer.get_remote_sender_id(), device_id))


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive_roster.rpc_id(peer_id, _snapshot())


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var leaving: Array[StringName] = []
	for seat: PartyMember in roster.values():
		if seat.peer_id == peer_id:
			leaving.append(seat.player_id)
	for player_id: StringName in leaving:
		_server_unregister(player_id)


# --- Client side ----------------------------------------------------------

# Untyped on purpose: arrays arriving over the network may not keep their element type.
@rpc("authority", "call_remote", "reliable")
func _receive_roster(entries: Array) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for data: Dictionary in entries:
		var incoming: PartyMember = PartyMember.from_dict(data)
		seen[incoming.player_id] = true
		if roster.has(incoming.player_id):
			var existing: PartyMember = roster[incoming.player_id]
			if existing.class_id != incoming.class_id or existing.slot != incoming.slot or existing.assist_mode != incoming.assist_mode \
					or existing.kit != incoming.kit or existing.calling != incoming.calling:
				existing.companion = incoming.companion
				existing.kit = incoming.kit
				existing.calling = incoming.calling
				existing.class_id = incoming.class_id
				existing.slot = incoming.slot
				existing.assist_mode = incoming.assist_mode
				player_updated.emit(existing)
		else:
			roster[incoming.player_id] = incoming
			player_registered.emit(incoming)
	var gone: Array[StringName] = []
	for player_id: StringName in roster.keys():
		if not seen.has(player_id):
			gone.append(player_id)
	for player_id: StringName in gone:
		roster.erase(player_id)
		player_unregistered.emit(player_id)
	_log_party()


@rpc("authority", "call_remote", "reliable")
func _registration_refused(device_id: int, reason: String) -> void:
	registration_refused.emit(device_id, reason)


func _on_connected_to_server() -> void:
	_set_status("Joined as peer %d" % local_peer_id())
	for device_id: int in _local_wishes.keys():
		var wish: Dictionary = _local_wishes[device_id]
		_request_register.rpc_id(1, device_id, wish["class_id"], wish["assist_mode"])


func _on_connection_failed() -> void:
	_set_status("Couldn't reach the host")
	leave_game.call_deferred()


func _on_server_disconnected() -> void:
	_set_status("The host left")
	leave_game.call_deferred()


func _clear_roster() -> void:
	var ids: Array[StringName] = []
	ids.assign(roster.keys())
	roster.clear()
	for player_id: StringName in ids:
		player_unregistered.emit(player_id)


func _set_status(text: String) -> void:
	status = text
	print("[Net] %s" % text)
	status_changed.emit(text)


func _log_party() -> void:
	var ids: PackedStringArray = PackedStringArray()
	for seat: PartyMember in ordered_members():
		ids.append("%s(%s%s)" % [seat.player_id, seat.class_id, ", bot" if seat.companion else ""])
	print("[Net] Party %d/%d: %s" % [human_count(), MAX_PARTY_SIZE, ", ".join(ids)])
