## Committed to an action. During wind-up (Phase A) the actor may turn up to
## 45 degrees toward its target; wind-up and active frames carry the lunge.
class_name AttackState
extends ActorState

const WINDUP_TURN_LIMIT: float = PI / 4.0 # 45 degrees
const WINDUP_TURN_SPEED: float = 10.0

var _turn_budget: float = 0.0


func state_name() -> StringName:
	return &"attack"


func enter(_from_state: StringName) -> void:
	_turn_budget = WINDUP_TURN_LIMIT


func physics_update(dt: float) -> void:
	var queue: ActionQueueComponent = actor.action_queue
	var action: CombatActionResource = queue.current_action
	if action == null:
		actor.steer_horizontal(Vector3.ZERO, actor.loadout.stats.move_speed, dt)
		return
	if queue.phase == ActionQueueComponent.Phase.WINDUP and _turn_budget > 0.0:
		var to_target: Vector3 = actor.direction_to_soft_target()
		if to_target != Vector3.ZERO:
			_turn_budget -= actor.turn_toward(to_target, minf(WINDUP_TURN_SPEED * dt, _turn_budget))
	var lunging: bool = queue.phase == ActionQueueComponent.Phase.WINDUP or queue.phase == ActionQueueComponent.Phase.ACTIVE
	var lunge_time: float = action.windup_time + action.active_time
	if lunging and absf(action.lunge_distance) > 0.0 and lunge_time > 0.0:
		var speed: float = action.lunge_distance / lunge_time * queue.speed_scale
		actor.set_horizontal_velocity(actor.facing_vector() * speed)
	else:
		actor.steer_horizontal(Vector3.ZERO, actor.loadout.stats.move_speed, dt)
