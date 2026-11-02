## Decoupled persistence (10_WORLD_ARCHITECTURE.md §4.2): what the world
## remembers about its stateful things, kept apart from the nodes that show
## them, so a chunk can unload and stream back in (or a family member can
## join mid-expedition) without losing a cleared camp, an opened chest, a
## resting shrine or a raised gate.
##
## Keyed by Landblock (Vector2i) -> entity id (StringName) -> state delta
## (Dictionary of plain values). The host is the authority: what it records is
## sent to every peer, and a peer that loads in late asks it for the whole
## snapshot. Each level that has stateful things adds one, named "WorldState",
## so its RPC path is the same on every peer.
##
## `world_time` is the store's own clock (seconds since it started, the host's
## when synced), so a shrine's "resting until" means the same on every peer.
class_name WorldStateDB
extends Node

signal entity_state_changed(chunk: Vector2i, entity_id: StringName, state: Dictionary)
signal snapshot_imported

const NODE_NAME: String = "WorldState"
const SNAPSHOT_VERSION: int = 1

var world_time: float = 0.0

var _chunk_deltas: Dictionary[Vector2i, Dictionary] = {}


func _ready() -> void:
	name = NODE_NAME
	InstanceManager.current.instance_live.connect(_on_instance_live)


func _exit_tree() -> void:
	var instances: InstanceManager = InstanceManager.current
	if instances != null and instances.instance_live.is_connected(_on_instance_live):
		instances.instance_live.disconnect(_on_instance_live)


func _process(delta: float) -> void:
	world_time += delta


# --- The store --------------------------------------------------------------

## Records an entity's state (replacing the last one). On the host it also goes to every peer.
func set_entity_state(chunk: Vector2i, entity_id: StringName, state: Dictionary) -> void:
	_store(chunk, entity_id, state)
	if NetworkManager.current.is_host():
		for peer_id: int in InstanceManager.current.live_remote_peers():
			_receive_entity_state.rpc_id(peer_id, chunk, String(entity_id), state)


func get_entity_state(chunk: Vector2i, entity_id: StringName, default_state: Dictionary = {}) -> Dictionary:
	var deltas: Dictionary = _chunk_deltas.get(chunk, {})
	return (deltas[entity_id] as Dictionary).duplicate(true) if deltas.has(entity_id) else default_state.duplicate(true)


func has_entity_state(chunk: Vector2i, entity_id: StringName) -> bool:
	return _chunk_deltas.has(chunk) and (_chunk_deltas[chunk] as Dictionary).has(entity_id)


## How many entity states are on record (the telemetry badge's "Deltas").
func delta_count() -> int:
	var count: int = 0
	for deltas: Dictionary in _chunk_deltas.values():
		count += deltas.size()
	return count


## Forgets the expedition (camps, chests, shrines, gates, the boss) for a fresh
## run, keeping the village's persistent chunks. On the host every peer forgets too.
func clear_expedition_transient_state() -> void:
	_clear_transient()
	if NetworkManager.current.is_host():
		for peer_id: int in InstanceManager.current.live_remote_peers():
			_receive_clear.rpc_id(peer_id)


## Everything on record, with plain keys ("0,-1" and String ids) so it travels
## in one RPC (or a JSON file) and reads back the same.
func export_snapshot() -> Dictionary:
	var chunks: Dictionary = {}
	for chunk: Vector2i in _chunk_deltas:
		var entities: Dictionary = {}
		var deltas: Dictionary = _chunk_deltas[chunk]
		for entity_id: StringName in deltas:
			entities[String(entity_id)] = (deltas[entity_id] as Dictionary).duplicate(true)
		chunks["%d,%d" % [chunk.x, chunk.y]] = entities
	return {"version": SNAPSHOT_VERSION, "world_time": world_time, "chunks": chunks}


## Replaces the store with a snapshot (a latecomer's sync), then tells every bound entity.
func import_snapshot(snapshot: Dictionary) -> void:
	var before: Array[Array] = _entries()
	_chunk_deltas.clear()
	world_time = float(snapshot.get("world_time", world_time))
	var chunks: Dictionary = snapshot.get("chunks", {}) as Dictionary
	for key: Variant in chunks:
		var parts: PackedStringArray = str(key).split(",")
		if parts.size() != 2:
			continue
		var chunk: Vector2i = Vector2i(parts[0].to_int(), parts[1].to_int())
		var entities: Dictionary = chunks[key] as Dictionary
		for entity_id: Variant in entities:
			_store(chunk, StringName(str(entity_id)), entities[entity_id] as Dictionary, false)
	# Anything that was on record and isn't any more goes back to its fresh state.
	for entry: Array in before:
		if not has_entity_state(entry[0], entry[1]):
			entity_state_changed.emit(entry[0], entry[1], {})
	for entry: Array in _entries():
		entity_state_changed.emit(entry[0], entry[1], get_entity_state(entry[0], entry[1]))
	snapshot_imported.emit()


## Hooks a stateful thing up: it gets a binding to record through, and its
## state is applied straight away (before it's ever drawn). Things without a
## `persist_id` or `bind_persistence` stay unbound.
func bind(entity: Node, chunk: Vector2i, entity_id: StringName = &"") -> WorldStateBinding:
	var id: StringName = entity_id
	if id == &"" and &"persist_id" in entity:
		id = entity.get(&"persist_id") as StringName
	if id == &"" or not entity.has_method(&"bind_persistence"):
		return null
	var binding: WorldStateBinding = WorldStateBinding.new(self, chunk, id, entity)
	entity.call(&"bind_persistence", binding)
	return binding


# --- Inside ----------------------------------------------------------------

func _store(chunk: Vector2i, entity_id: StringName, state: Dictionary, announce: bool = true) -> void:
	if state.is_empty():
		if _chunk_deltas.has(chunk):
			(_chunk_deltas[chunk] as Dictionary).erase(entity_id)
			if (_chunk_deltas[chunk] as Dictionary).is_empty():
				_chunk_deltas.erase(chunk)
	else:
		if not _chunk_deltas.has(chunk):
			_chunk_deltas[chunk] = {}
		(_chunk_deltas[chunk] as Dictionary)[entity_id] = state.duplicate(true)
	if announce:
		entity_state_changed.emit(chunk, entity_id, state.duplicate(true))


func _clear_transient() -> void:
	for entry: Array in _entries():
		if not LandblockManifest.is_persistent(entry[0]):
			_store(entry[0], entry[1], {})


## Every (chunk, id) on record.
func _entries() -> Array[Array]:
	var entries: Array[Array] = []
	for chunk: Vector2i in _chunk_deltas:
		for entity_id: StringName in (_chunk_deltas[chunk] as Dictionary):
			entries.append([chunk, entity_id])
	return entries


@rpc("authority", "call_remote", "reliable")
func _receive_entity_state(chunk: Vector2i, entity_id: String, state: Dictionary) -> void:
	_store(chunk, StringName(entity_id), state)


@rpc("authority", "call_remote", "reliable")
func _receive_clear() -> void:
	_clear_transient()


## A peer that just loaded in asks the host for everything it missed.
func _on_instance_live(_id: StringName) -> void:
	if is_inside_tree() and not NetworkManager.current.is_host() and NetworkManager.current.is_online():
		_request_snapshot.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _request_snapshot() -> void:
	if multiplayer.is_server():
		_receive_snapshot.rpc_id(multiplayer.get_remote_sender_id(), export_snapshot())


@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(snapshot: Dictionary) -> void:
	import_snapshot(snapshot)
