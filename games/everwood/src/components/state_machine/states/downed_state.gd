## Out of health. Players get back up after a short wait (or sooner if healed);
## the dojo boss resets.
class_name DownedState
extends ActorState


func state_name() -> StringName:
	return &"downed"


func enter(_from_state: StringName) -> void:
	actor.downed_time_left = actor.downed_duration()


func physics_update(dt: float) -> void:
	actor.steer_horizontal(Vector3.ZERO, actor.loadout.stats.move_speed, dt)
	if not actor.stats.is_downed:
		machine.transition(&"idle")
		return
	actor.downed_time_left -= dt
	if actor.downed_time_left <= 0.0:
		actor.recover_from_downed()
		machine.transition(&"idle")
