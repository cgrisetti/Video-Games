## One stateful thing's line to WorldStateDB: where it's filed (its Landblock
## and id), a way to record its state, and a listener that re-applies the state
## when it changes from outside (the host's word, a latecomer's snapshot, a
## reset of the expedition). The entity holds it; it lets go with the entity.
class_name WorldStateBinding
extends RefCounted

var db: WorldStateDB
var chunk: Vector2i
var entity_id: StringName

var _entity: WeakRef
var _recording: bool = false


func _init(owner_db: WorldStateDB, at_chunk: Vector2i, id: StringName, entity: Node) -> void:
	db = owner_db
	chunk = at_chunk
	entity_id = id
	_entity = weakref(entity)
	db.entity_state_changed.connect(_on_state_changed)


## The state on record ({} for a fresh entity).
func current_state() -> Dictionary:
	return db.get_entity_state(chunk, entity_id) if is_instance_valid(db) else {}


## Records the entity's new state ({} forgets it).
func save(state: Dictionary) -> void:
	if not is_instance_valid(db):
		return
	_recording = true
	db.set_entity_state(chunk, entity_id, state)
	_recording = false


func _on_state_changed(at_chunk: Vector2i, id: StringName, state: Dictionary) -> void:
	if _recording or at_chunk != chunk or id != entity_id:
		return
	var entity: Node = _entity.get_ref() as Node
	if entity != null and entity.has_method(&"apply_persisted_state"):
		entity.call(&"apply_persisted_state", state)
