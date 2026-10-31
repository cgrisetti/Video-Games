## Base for one state of an actor's state machine.
class_name ActorState
extends Node

var actor: ActorBase
var machine: StateMachine


func state_name() -> StringName:
	return &"state"


func enter(_from_state: StringName) -> void:
	pass


func exit(_to_state: StringName) -> void:
	pass


func physics_update(_dt: float) -> void:
	pass
