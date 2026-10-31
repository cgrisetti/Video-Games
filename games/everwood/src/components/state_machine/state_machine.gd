## A finite state machine for one actor. States are child nodes; the actor
## ticks it with its own (hit-stop aware) delta.
class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

var actor: ActorBase
var current: ActorState
var states: Dictionary[StringName, ActorState] = {}


func setup(owner_actor: ActorBase, state_list: Array[ActorState], initial: StringName) -> void:
	actor = owner_actor
	name = "StateMachine"
	for state: ActorState in state_list:
		state.actor = owner_actor
		state.machine = self
		state.name = String(state.state_name())
		states[state.state_name()] = state
		add_child(state)
	current = states[initial]
	current.enter(&"")


func current_name() -> StringName:
	return current.state_name() if current != null else &""


func is_in(state_name: StringName) -> bool:
	return current != null and current.state_name() == state_name


## Switches state. Re-entering the same state restarts it (a flow-cancel into a new attack).
func transition(to_state: StringName) -> void:
	if not states.has(to_state):
		push_error("StateMachine: no state named %s" % to_state)
		return
	var from_state: StringName = current_name()
	if current != null:
		current.exit(to_state)
	current = states[to_state]
	current.enter(from_state)
	state_changed.emit(from_state, to_state)


func physics_update(dt: float) -> void:
	if current != null:
		current.physics_update(dt)
