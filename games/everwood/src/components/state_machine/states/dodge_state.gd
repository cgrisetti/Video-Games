## A roll. The actor is invulnerable during the dodge's active frames; ground
## telegraphs still hit if you roll into one, so roll out. How far it carries
## comes from the equipped armor (stats.roll_distance): long in Hearth-Linen,
## short in Ironwood Plate.
class_name DodgeState
extends ActorState

var _direction: Vector3 = Vector3.ZERO


func state_name() -> StringName:
	return &"dodge"


func enter(_from_state: StringName) -> void:
	_direction = actor.dodge_direction()


func physics_update(dt: float) -> void:
	var queue: ActionQueueComponent = actor.action_queue
	var action: CombatActionResource = queue.current_action
	if action == null:
		actor.steer_horizontal(Vector3.ZERO, actor.loadout.stats.move_speed, dt)
		return
	var rolling: bool = queue.phase == ActionQueueComponent.Phase.WINDUP or queue.phase == ActionQueueComponent.Phase.ACTIVE
	var roll_time: float = action.windup_time + action.active_time
	if rolling and roll_time > 0.0:
		actor.set_horizontal_velocity(_direction * actor.loadout.stats.roll_distance / roll_time)
	else:
		actor.steer_horizontal(Vector3.ZERO, actor.loadout.stats.move_speed, dt)
