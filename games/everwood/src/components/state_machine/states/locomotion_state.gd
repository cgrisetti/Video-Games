## Walking and running, turning to face the way you're going.
class_name LocomotionState
extends ActorState


func state_name() -> StringName:
	return &"locomotion"


func physics_update(dt: float) -> void:
	var stats: CharacterStatsResource = actor.loadout.stats
	actor.steer_horizontal(actor.move_intent, actor.locomotion_speed(), dt)
	actor.turn_toward(actor.move_intent, stats.turn_speed * dt)
	if actor.wants_guard and actor.can_guard():
		machine.transition(&"guard")
	elif actor.move_intent.length() <= 0.1:
		machine.transition(&"idle")
