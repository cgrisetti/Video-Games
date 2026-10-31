## Active Guard (L held): slow steps, facing the target. A guard raised within
## 200 ms of a hit is a Perfect Guard if the class can do one.
class_name GuardState
extends ActorState


func state_name() -> StringName:
	return &"guard"


func enter(_from_state: StringName) -> void:
	actor.stats.begin_guard()


func exit(_to_state: StringName) -> void:
	actor.stats.end_guard()


func physics_update(dt: float) -> void:
	var stats: CharacterStatsResource = actor.loadout.stats
	actor.steer_horizontal(actor.move_intent, stats.guard_move_speed, dt)
	var to_target: Vector3 = actor.direction_to_soft_target()
	actor.turn_toward(to_target if to_target != Vector3.ZERO else actor.move_intent, stats.turn_speed * dt)
	if not actor.wants_guard:
		machine.transition(&"locomotion" if actor.move_intent.length() > 0.1 else &"idle")
