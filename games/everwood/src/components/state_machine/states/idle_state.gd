## Standing still. Walks when there's movement, guards when L is held.
class_name IdleState
extends ActorState


func state_name() -> StringName:
	return &"idle"


func physics_update(dt: float) -> void:
	actor.steer_horizontal(Vector3.ZERO, actor.loadout.stats.move_speed, dt)
	if actor.wants_guard and actor.can_guard():
		machine.transition(&"guard")
	elif actor.move_intent.length() > 0.1:
		machine.transition(&"locomotion")
