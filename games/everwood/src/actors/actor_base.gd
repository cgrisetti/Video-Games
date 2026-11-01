## Every actor, player or boss, is one CharacterBody3D made of component nodes.
## ActorBase builds the components it needs in code (Code-First Scene Safety),
## wires them together through signals, and ticks them with a hit-stop-aware
## delta so a landed blow freezes just the two actors involved.
class_name ActorBase
extends CharacterBody3D

signal went_down(actor: ActorBase)
signal got_up(actor: ActorBase)

# Physics layers (bit values). Names are in project.godot.
const LAYER_WORLD: int = 1
const LAYER_PLAYERS: int = 2
const LAYER_BOSS: int = 4
const LAYER_PLAYER_HURTBOX: int = 8
const LAYER_BOSS_HURTBOX: int = 16

const GRAVITY: float = 22.0
## How quickly actors reach their wanted speed, in metres per second per second.
const ACCELERATION: float = 40.0
const BODY_RADIUS: float = 0.45
const BODY_HEIGHT: float = 1.7
## Players soft-lock onto the boss within this distance.
const SOFT_LOCK_RANGE: float = 30.0
const GUARD_BREAK_STAGGER: float = 0.9
const DOWNED_RESPAWN_TIME: float = 8.0
const RESPAWN_HEALTH_RATIO: float = 0.5
const FALL_RESPAWN_HEIGHT: float = -10.0
const FLASH_TIME: float = 0.08
## Extra invulnerability after a Lifeline Pull lands, so the yank really saves you.
const PULL_SAFETY_TIME: float = 0.3
const POSE_SHARPNESS: float = 18.0
## A flow-cancel makes the body glow blue-white for a moment (and plays a tick).
const FLOW_GLOW_TIME: float = 0.18
const FLOW_GLOW_COLOR: Color = Color(0.55, 0.8, 1.0)

@export var loadout: ClassLoadoutResource

var player_id: StringName = &""
## The class's own numbers, before the party's Hub Town upgrades (players only).
var base_stats: CharacterStatsResource
var peer_id: int = 1
var device_id: int = 0
var party_slot: int = 0
var spawn_transform: Transform3D = Transform3D.IDENTITY

var stats: StatsComponent
var action_queue: ActionQueueComponent
var state_machine: StateMachine
var hitbox: HitboxComponent
var hurtbox: HurtboxComponent
var net_sync: NetworkSyncComponent
## Local players only.
var input: InputComponent
## Healers only.
var tether: SoulTetherComponent
## Bosses only.
var threat: ThreatComponent
## Something this local player is standing at and can use with light (the Shard Vendor).
var interactable: Interactable

## Where this actor wants to go this tick (world space, length 0..1).
var move_intent: Vector3 = Vector3.ZERO
var wants_guard: bool = false
## Set by this player's camera; movement is relative to it.
var camera_yaw: float = 0.0
## A dodge direction chosen for the actor (the Squire auto-evade sets it).
var evade_direction: Vector3 = Vector3.ZERO
var stagger_time_left: float = 0.0
var downed_time_left: float = 0.0

var visual: Node3D
var _body_material: StandardMaterial3D
var _prop: Node3D
var _name_label: Label3D
var _hit_stop_left: float = 0.0
var _flash_left: float = 0.0
var _flow_glow_left: float = 0.0
var _pull_from: Vector3 = Vector3.ZERO
var _pull_to: Vector3 = Vector3.ZERO
var _pull_time: float = 0.0
var _pull_duration: float = 0.0


# --- Construction ---------------------------------------------------------

## Gives a local player a controller. Call before adding the actor to the tree.
func attach_input(for_device: int, mode: int) -> void:
	input = InputComponent.new()
	input.setup(self, for_device, mode as InputComponent.AssistMode)


func _ready() -> void:
	assert(loadout != null, "ActorBase needs a loadout before it enters the tree")
	if not is_boss():
		base_stats = loadout.stats.duplicate() as CharacterStatsResource
		PartyProgress.current.apply_upgrades(loadout.stats, base_stats)
	_build_body()
	_build_components()
	_build_visual()
	# Components were built after the owner was set, so hand them the same owner.
	set_multiplayer_authority(get_multiplayer_authority(), true)
	CombatDirector.current.register_actor(self)


func _exit_tree() -> void:
	CombatDirector.current.unregister_actor(self)


func body_radius() -> float:
	return BODY_RADIUS


func body_height() -> float:
	return BODY_HEIGHT


func _build_body() -> void:
	collision_layer = LAYER_BOSS if is_boss() else LAYER_PLAYERS
	# Players can't walk through the boss; nobody collides with other players.
	collision_mask = LAYER_WORLD if is_boss() else LAYER_WORLD | LAYER_BOSS
	floor_snap_length = 0.3
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = body_radius()
	capsule.height = body_height()
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = capsule
	collision.position = Vector3(0.0, body_height() * 0.5, 0.0)
	add_child(collision)


func _build_components() -> void:
	stats = StatsComponent.new()
	stats.name = "StatsComponent"
	stats.setup(loadout.stats)
	add_child(stats)
	stats.downed.connect(_on_downed)
	stats.revived.connect(_on_revived)
	stats.poise_broken.connect(_on_poise_broken)

	action_queue = ActionQueueComponent.new()
	action_queue.setup(self)
	add_child(action_queue)
	action_queue.action_started.connect(_on_action_started)
	action_queue.phase_changed.connect(_on_phase_changed)
	action_queue.action_finished.connect(_on_action_finished)

	hitbox = HitboxComponent.new()
	hitbox.setup(self, not is_boss())
	add_child(hitbox)
	hitbox.hurtbox_hit.connect(_on_hurtbox_hit)

	hurtbox = HurtboxComponent.new()
	hurtbox.setup(self, is_boss(), body_radius() + 0.1, body_height())
	add_child(hurtbox)

	net_sync = NetworkSyncComponent.new()
	net_sync.setup(self)
	add_child(net_sync)

	if loadout.has_soul_tethers:
		tether = SoulTetherComponent.new()
		tether.setup(self)
		add_child(tether)

	if input != null:
		add_child(input)
		input.command_issued.connect(_on_command)
		input.tether_slot_pressed.connect(_on_tether_slot)
		apply_assist_mode()

	state_machine = StateMachine.new()
	add_child(state_machine)
	var state_list: Array[ActorState] = [
		IdleState.new(), LocomotionState.new(), AttackState.new(), GuardState.new(),
		DodgeState.new(), StaggerState.new(), DownedState.new(),
	]
	state_machine.setup(self, state_list, &"idle")


## Re-applies the party's upgrades after a purchase, keeping the same share of health.
func refresh_upgrades() -> void:
	if base_stats == null:
		return
	var ratio: float = stats.health_ratio()
	PartyProgress.current.apply_upgrades(loadout.stats, base_stats)
	if not stats.is_downed:
		stats.health = ratio * loadout.stats.max_health
	stats.health_changed.emit(stats.health, loadout.stats.max_health)


## Pushes the input mode's buffer window, flow bonus and auto-chaining into the queue.
func apply_assist_mode() -> void:
	if input == null:
		return
	action_queue.buffer_window = input.buffer_window()
	action_queue.flow_speed_bonus = input.flow_speed_bonus()
	action_queue.assisted_chaining = input.assisted_chaining()


func _build_visual() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = loadout.body_color
	_body_material.roughness = 0.7
	# Emission stays on (black) so a hit flash never swaps shaders mid-fight.
	_body_material.emission_enabled = true
	_body_material.emission = Color.BLACK
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Body"
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = body_radius()
	capsule.height = body_height()
	capsule.material = _body_material
	body.mesh = capsule
	body.position = Vector3(0.0, body_height() * 0.5, 0.0)
	visual.add_child(body)
	# A darker nose shows which way the actor faces.
	var nose: MeshInstance3D = MeshInstance3D.new()
	nose.name = "Nose"
	var nose_mesh: BoxMesh = BoxMesh.new()
	nose_mesh.size = Vector3(0.4, 0.22, 0.4) * (body_radius() / BODY_RADIUS)
	nose_mesh.material = _flat_material(loadout.body_color.darkened(0.55))
	nose.mesh = nose_mesh
	nose.position = Vector3(0.0, body_height() * 0.78, -body_radius() * 0.85)
	visual.add_child(nose)
	_prop = _build_prop()
	if _prop != null:
		visual.add_child(_prop)
	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.text = display_name()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.font_size = 40
	_name_label.outline_size = 10
	_name_label.pixel_size = 0.006 * (body_height() / BODY_HEIGHT)
	_name_label.modulate = loadout.body_color.lightened(0.35)
	_name_label.position = Vector3(0.0, body_height() + 0.45, 0.0)
	add_child(_name_label)


## The class's greybox prop: a shield, a healing orb or a blade.
func _build_prop() -> Node3D:
	var prop: MeshInstance3D = MeshInstance3D.new()
	prop.name = "Prop"
	match loadout.role:
		ClassLoadoutResource.Role.TANK:
			var shield: BoxMesh = BoxMesh.new()
			shield.size = Vector3(0.95, 1.15, 0.14)
			shield.material = _flat_material(Color(0.62, 0.66, 0.74))
			prop.mesh = shield
			prop.position = Vector3(-0.15, 1.0, -0.62)
		ClassLoadoutResource.Role.HEALER:
			var orb: SphereMesh = SphereMesh.new()
			orb.radius = 0.2
			orb.height = 0.4
			var glow: StandardMaterial3D = _flat_material(Color(0.55, 1.0, 0.65))
			glow.emission_enabled = true
			glow.emission = Color(0.4, 1.0, 0.55)
			glow.emission_energy_multiplier = 2.0
			orb.material = glow
			prop.mesh = orb
			prop.position = Vector3(0.55, 1.55, -0.2)
		ClassLoadoutResource.Role.DPS:
			var blade: BoxMesh = BoxMesh.new()
			blade.size = Vector3(0.09, 0.09, 1.25)
			blade.material = _flat_material(Color(0.85, 0.86, 0.9))
			prop.mesh = blade
			prop.position = Vector3(0.5, 1.0, -0.75)
		_:
			return null
	return prop


func _flat_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	return material


# --- Identity -------------------------------------------------------------

func role() -> int:
	return loadout.role


func is_boss() -> bool:
	return loadout.role == ClassLoadoutResource.Role.BOSS


func is_local_player() -> bool:
	return input != null


func display_name() -> String:
	return "P%d %s" % [party_slot + 1, loadout.display_name]


func refresh_name_label() -> void:
	if _name_label != null:
		_name_label.text = display_name()


## Teleports the actor (its spawn point stays where it was).
func place_at(where: Transform3D) -> void:
	global_transform = where
	velocity = Vector3.ZERO
	reset_physics_interpolation()


## Makes `where` this actor's spawn point (where it respawns) and puts it there.
func spawn_at(where: Transform3D) -> void:
	spawn_transform = where
	place_at(where)


# --- Ticking --------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		# Someone else's actor: follow what its owner sends.
		net_sync.tick_copy(delta)
		_update_pose(delta)
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	_flow_glow_left = maxf(0.0, _flow_glow_left - delta)
	if _hit_stop_left > 0.0:
		# Hit-stop: this actor alone freezes for a few frames.
		_hit_stop_left -= delta
		return
	_gather_intent(delta)
	if not is_inside_tree():
		return # Something this tick's input did removed the actor (leaving the party).
	stats.tick(delta, _can_regen_stamina())
	if _pull_duration > 0.0:
		_update_pull(delta)
	else:
		action_queue.tick(delta)
		hitbox.poll()
		state_machine.physics_update(delta)
		if is_on_floor():
			velocity.y = minf(velocity.y, 0.0)
		else:
			velocity.y -= GRAVITY * delta
		move_and_slide()
	if tether != null:
		tether.update_beam()
	net_sync.tick_owner(delta)
	_update_pose(delta)
	if global_position.y < FALL_RESPAWN_HEIGHT:
		respawn()


## Fills move_intent and wants_guard. Players read their controller; bosses override with AI.
func _gather_intent(delta: float) -> void:
	if input == null:
		move_intent = Vector3.ZERO
		wants_guard = false
		return
	input.poll(delta)
	var stick: Vector2 = input.move_input
	var forward: Vector3 = Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right: Vector3 = Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	move_intent = (right * stick.x + forward * stick.y).limit_length(1.0)
	wants_guard = loadout.guard_on_trigger_l and input.is_guard_held()


func _can_regen_stamina() -> bool:
	return (state_machine.is_in(&"idle") or state_machine.is_in(&"locomotion")) and not stats.guarding


func can_act() -> bool:
	return not stats.is_downed and not state_machine.is_in(&"stagger") and _pull_duration <= 0.0


func can_guard() -> bool:
	return loadout.guard_on_trigger_l and not action_queue.is_busy() and can_act()


## What this actor is doing right now, on any peer: copies of other peers'
## actors read what the owner last sent.
func current_action() -> CombatActionResource:
	if is_multiplayer_authority():
		return action_queue.current_action
	if net_sync.remote_action_id == &"":
		return null
	return loadout.action_by_id(net_sync.remote_action_id)


func current_phase() -> ActionQueueComponent.Phase:
	if is_multiplayer_authority():
		return action_queue.phase
	return net_sync.remote_phase


## Drops the current action and stands ready, so a guard can go up at once.
func cancel_action() -> void:
	action_queue.interrupt()
	hitbox.deactivate()
	if state_machine.is_in(&"attack") or state_machine.is_in(&"dodge"):
		state_machine.transition(&"idle")


func apply_hit_stop(duration: float) -> void:
	_hit_stop_left = maxf(_hit_stop_left, duration)


func is_hit_stopped() -> bool:
	return _hit_stop_left > 0.0


# --- Movement helpers (used by the states) -------------------------------

func steer_horizontal(direction: Vector3, speed: float, dt: float) -> void:
	var wanted: Vector3 = Vector3(direction.x, 0.0, direction.z) * speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(wanted, ACCELERATION * dt)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func set_horizontal_velocity(horizontal: Vector3) -> void:
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Turns toward a direction by at most `max_step` radians; returns how far it turned.
func turn_toward(direction: Vector3, max_step: float) -> float:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length() < 0.01 or max_step <= 0.0:
		return 0.0
	var wanted: float = atan2(-flat.x, -flat.z)
	var step: float = clampf(wrapf(wanted - rotation.y, -PI, PI), -max_step, max_step)
	rotation.y += step
	return absf(step)


func facing_vector() -> Vector3:
	return Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))


func dodge_direction() -> Vector3:
	if evade_direction != Vector3.ZERO:
		return evade_direction
	if move_intent.length() > 0.1:
		return move_intent.normalized()
	return -facing_vector()


# --- Targeting ------------------------------------------------------------

## Who this actor's attacks and camera lean toward. Players lock onto the boss.
func soft_target() -> ActorBase:
	var boss: ActorBase = CombatDirector.current.primary_boss()
	if boss == null or boss.stats.is_downed:
		return null
	if boss.global_position.distance_to(global_position) > SOFT_LOCK_RANGE:
		return null
	return boss


func direction_to_soft_target() -> Vector3:
	var target: ActorBase = soft_target()
	if target == null:
		return Vector3.ZERO
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	return to_target.normalized() if to_target.length() > 0.01 else Vector3.ZERO


func distance_to_soft_target() -> float:
	var target: ActorBase = soft_target()
	if target == null:
		return INF
	return target.global_position.distance_to(global_position)


## The party member (yourself included) with the lowest health share below `below`.
func most_hurt_ally(below: float) -> ActorBase:
	var chosen: ActorBase = null
	var lowest: float = below
	for member: ActorBase in CombatDirector.current.party_actors():
		var ratio: float = member.stats.health_ratio()
		if ratio < lowest:
			lowest = ratio
			chosen = member
	return chosen


# --- Commands and actions -------------------------------------------------

func _on_command(command: int) -> void:
	if can_act():
		action_queue.request(command)


func _on_tether_slot(slot: int) -> void:
	if tether != null:
		tether.bind_slot(slot)


## Called by the action queue as Phase A begins: checks the action can go and pays for it.
func try_begin_action(action: CombatActionResource) -> bool:
	if not can_act():
		return false
	match action.effect:
		CombatActionResource.Effect.HOMING_HEAL:
			if tether == null:
				return false
		CombatActionResource.Effect.LIFELINE_PULL:
			if tether == null or tether.tethered_actor() == self:
				return false
	return stats.spend_for(action)


func _on_action_started(action: CombatActionResource, flowed: bool) -> void:
	if stats.guarding:
		stats.end_guard()
	if flowed and is_local_player():
		_flow_glow_left = FLOW_GLOW_TIME
		AudioCues.play(&"flow", 1.0 + (action_queue.speed_scale - 1.0) * 2.0)
	if action.effect == CombatActionResource.Effect.DODGE:
		state_machine.transition(&"dodge")
	else:
		state_machine.transition(&"attack")


func _on_phase_changed(phase: ActionQueueComponent.Phase) -> void:
	var action: CombatActionResource = action_queue.current_action
	if phase == ActionQueueComponent.Phase.ACTIVE and action != null:
		_begin_effect(action)
	else:
		hitbox.deactivate()


func _on_action_finished(_action: CombatActionResource) -> void:
	evade_direction = Vector3.ZERO
	if not action_queue.is_busy() and (state_machine.is_in(&"attack") or state_machine.is_in(&"dodge")):
		state_machine.transition(&"locomotion" if move_intent.length() > 0.1 else &"idle")


## Phase B: what the action actually does.
func _begin_effect(action: CombatActionResource) -> void:
	match action.effect:
		CombatActionResource.Effect.STRIKE:
			hitbox.activate(action)
		CombatActionResource.Effect.DODGE:
			stats.grant_invulnerability(action.active_time / action_queue.speed_scale)
		CombatActionResource.Effect.TAUNT:
			CombatDirector.current.taunt_bosses(self, action.effect_duration)
		CombatActionResource.Effect.SHADOW_SANCTUARY:
			CombatDirector.current.spawn_zone(self, SanctuaryZone.Shape.CONE, action)
		CombatActionResource.Effect.GREEN_SANCTUARY:
			CombatDirector.current.spawn_zone(self, SanctuaryZone.Shape.RING, action)
		CombatActionResource.Effect.HOMING_HEAL:
			CombatDirector.current.launch_homing_heal(self, tether.tethered_actor(), action.heal_amount)
		CombatActionResource.Effect.LIFELINE_PULL:
			CombatDirector.current.lifeline_pull(self, tether.tethered_actor(), action.effect_duration)


func _on_hurtbox_hit(target_hurtbox: HurtboxComponent) -> void:
	var target: ActorBase = target_hurtbox.actor
	var action: CombatActionResource = action_queue.current_action
	if target == null or action == null or target.stats.is_downed:
		return
	CombatDirector.current.report_hit(self, target, action, action_queue.flowed_into_current)


# --- Receiving ------------------------------------------------------------

## Applies a strike on the peer that owns this actor. Returns a StatsComponent.StrikeOutcome.
func receive_strike(event: CombatEvent) -> int:
	var multiplier: float = CombatDirector.current.damage_taken_multiplier(self)
	var outcome: StatsComponent.StrikeOutcome = stats.mitigate_strike(
		event.damage * multiplier, event.poise_damage, _faces_toward(event.origin), event.unavoidable)
	match outcome:
		StatsComponent.StrikeOutcome.GUARD_BROKEN:
			stagger(GUARD_BREAK_STAGGER)
			_flash_left = FLASH_TIME
		StatsComponent.StrikeOutcome.HIT, StatsComponent.StrikeOutcome.GUARDED:
			_flash_left = FLASH_TIME
	return outcome


func receive_heal(amount: float) -> float:
	return stats.heal(amount)


func _faces_toward(point: Vector3) -> bool:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	return to_point.length() < 0.01 or facing_vector().dot(to_point.normalized()) > 0.0


func stagger(seconds: float) -> void:
	action_queue.interrupt()
	hitbox.deactivate()
	stagger_time_left = maxf(stagger_time_left, seconds)
	if not stats.is_downed:
		state_machine.transition(&"stagger")


## Lifeline Pull: glide to `destination` over `duration`, untouchable on the way.
func start_forced_move(destination: Vector3, duration: float) -> void:
	action_queue.interrupt()
	hitbox.deactivate()
	_pull_from = global_position
	_pull_to = destination
	_pull_duration = maxf(0.05, duration)
	_pull_time = 0.0
	velocity = Vector3.ZERO
	stats.grant_invulnerability(_pull_duration + PULL_SAFETY_TIME)
	if not stats.is_downed:
		state_machine.transition(&"idle")


func _update_pull(delta: float) -> void:
	_pull_time += delta
	var t: float = clampf(_pull_time / _pull_duration, 0.0, 1.0)
	global_position = _pull_from.lerp(_pull_to, smoothstep(0.0, 1.0, t))
	velocity = Vector3.ZERO
	if t >= 1.0:
		_pull_duration = 0.0


func _on_poise_broken() -> void:
	stagger(stats.stats.poise_knockdown_time)


func _on_downed() -> void:
	action_queue.interrupt()
	hitbox.deactivate()
	state_machine.transition(&"downed")
	went_down.emit(self)


func _on_revived() -> void:
	if state_machine.is_in(&"downed"):
		state_machine.transition(&"idle")
	got_up.emit(self)


func downed_duration() -> float:
	return DOWNED_RESPAWN_TIME


## When the downed timer runs out. Players get back up at their spawn point.
func recover_from_downed() -> void:
	respawn()


func respawn() -> void:
	if stats.is_downed:
		stats.revive(RESPAWN_HEALTH_RATIO)
	place_at(spawn_transform)
	if state_machine.current_name() != &"idle":
		state_machine.transition(&"idle")


# --- Greybox posing -------------------------------------------------------

func _update_pose(delta: float) -> void:
	var state: StringName = state_machine.current_name() if is_multiplayer_authority() else net_sync.remote_state
	var lean: float = 0.0
	var tilt: float = 0.0
	var height_scale: float = 1.0
	match state:
		&"attack":
			lean = 0.3
			if action_queue.phase == ActionQueueComponent.Phase.WINDUP:
				lean = -0.25
		&"dodge":
			height_scale = 0.65
			lean = 0.4
		&"guard":
			lean = 0.12
			height_scale = 0.9
		&"stagger":
			tilt = sin(Time.get_ticks_msec() * 0.02) * 0.18
			lean = -0.2
		&"downed":
			lean = -1.45
	var blend: float = 1.0 - exp(-POSE_SHARPNESS * delta)
	visual.rotation.x = lerpf(visual.rotation.x, -lean, blend)
	visual.rotation.z = lerpf(visual.rotation.z, tilt, blend)
	visual.scale.y = lerpf(visual.scale.y, height_scale, blend)
	if _flash_left > 0.0:
		_body_material.emission = Color(1.0, 1.0, 1.0) * 0.9
	elif _flow_glow_left > 0.0:
		_body_material.emission = FLOW_GLOW_COLOR * (_flow_glow_left / FLOW_GLOW_TIME) * 1.4
	else:
		_body_material.emission = Color.BLACK
