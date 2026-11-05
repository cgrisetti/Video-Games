## Off the ground on a jump (Phase 12 Kaizen, K1): launched at
## ActorBase.JUMP_VELOCITY, steering in the air at the hero's running (or
## sprinting) pace, and back to a walk or a stand once the feet touch down.
class_name JumpState
extends ActorState

## Don't call it a landing in the first frames, while the hero is still leaving the floor.
const MIN_AIR_TIME: float = 0.08

var airborne_time: float = 0.0


func state_name() -> StringName:
	return &"jump"


func enter(_from_state: StringName) -> void:
	airborne_time = 0.0
	actor.launch_jump()


func physics_update(dt: float) -> void:
	airborne_time += dt
	actor.steer_horizontal(actor.move_intent, actor.locomotion_speed(), dt)
	actor.turn_toward(actor.move_intent, actor.loadout.stats.turn_speed * dt)
	if airborne_time >= MIN_AIR_TIME and actor.is_on_floor() and actor.velocity.y <= 0.0:
		actor.land_jump()
		machine.transition(&"locomotion" if actor.move_intent.length() > 0.1 else &"idle")
