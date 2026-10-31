## Can't act: a broken guard for a player, a poise knockdown for a boss.
class_name StaggerState
extends ActorState


func state_name() -> StringName:
	return &"stagger"


func physics_update(dt: float) -> void:
	actor.steer_horizontal(Vector3.ZERO, actor.loadout.stats.move_speed, dt)
	actor.stagger_time_left -= dt
	if actor.stagger_time_left <= 0.0 and not actor.stats.is_knocked_down():
		actor.stagger_time_left = 0.0
		machine.transition(&"idle")
