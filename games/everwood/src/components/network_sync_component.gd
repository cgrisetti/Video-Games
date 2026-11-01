## Keeps an actor in step across the network. The peer that owns the actor sends
## its position, facing, state, gauges and current action a few times a second;
## every other peer glides its copy toward them.
class_name NetworkSyncComponent
extends Node

const SEND_RATE: float = 20.0
const POSITION_SHARPNESS: float = 14.0
## Copies further off than this snap instead of gliding (respawns, pulls).
const SNAP_DISTANCE: float = 6.0

var actor: ActorBase
var remote_state: StringName = &"idle"
## The owner's current action and its phase (so other peers see a boss wind up).
var remote_action_id: StringName = &""
var remote_phase: ActionQueueComponent.Phase = ActionQueueComponent.Phase.IDLE

var _send_accum: float = 0.0
var _target_position: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _has_state: bool = false


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "NetworkSync"


func tick_owner(delta: float) -> void:
	if not NetworkManager.current.is_online() or not InstanceManager.current.is_live():
		return
	_send_accum += delta
	if _send_accum < 1.0 / SEND_RATE:
		return
	_send_accum = 0.0
	var gauges: PackedFloat32Array = PackedFloat32Array([
		actor.stats.health, actor.stats.stamina, actor.stats.poise, actor.stats.resonance_charge, actor.stats.stats.max_health])
	var action: CombatActionResource = actor.action_queue.current_action
	var action_id: StringName = action.action_id if action != null else &""
	# Only peers with this instance loaded have a copy of the actor to update.
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_receive_state.rpc_id(peer_id, actor.global_position, actor.rotation.y, actor.state_machine.current_name(), gauges,
			action_id, actor.action_queue.phase)


func tick_copy(delta: float) -> void:
	if not _has_state:
		return
	if actor.global_position.distance_to(_target_position) > SNAP_DISTANCE:
		actor.global_position = _target_position
		actor.reset_physics_interpolation()
	else:
		var blend: float = 1.0 - exp(-POSITION_SHARPNESS * delta)
		actor.global_position = actor.global_position.lerp(_target_position, blend)
		actor.rotation.y = lerp_angle(actor.rotation.y, _target_yaw, blend)


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_state(position: Vector3, yaw: float, state: StringName, gauges: PackedFloat32Array, action_id: StringName, phase: int) -> void:
	_target_position = position
	_target_yaw = yaw
	remote_state = state
	remote_action_id = action_id
	remote_phase = phase as ActionQueueComponent.Phase
	_has_state = true
	if gauges.size() >= 4:
		actor.stats.health = gauges[0]
		actor.stats.stamina = gauges[1]
		actor.stats.poise = gauges[2]
		actor.stats.resonance_charge = gauges[3]
		actor.stats.is_downed = state == &"downed"
	if gauges.size() >= 5:
		# The boss's max health scales with the party on the host.
		actor.stats.stats.max_health = gauges[4]
