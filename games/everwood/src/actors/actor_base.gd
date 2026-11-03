## Every actor, player or boss, is one CharacterBody3D made of component nodes.
## ActorBase builds the components it needs in code (Code-First Scene Safety),
## wires them together through signals, and ticks them with a hit-stop-aware
## delta so a landed blow freezes just the two actors involved.
##
## What a player swings and casts comes from its compiled loadout (equipment
## and Scribe Cards, LoadoutComposer). Nothing here knows a weapon or a card by
## name: props are built from the items' parts, and a strike either swings the
## hitbox or fires a projectile, as its action says. A player is drawn as a
## storybook puppet (ActorVisuals); enemies draw their own bodies.
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
## Knee-high walls, rails, parapets and holloway banks: bodies bump into them,
## but cameras see past them (PlayerCamera only pulls in for LAYER_WORLD).
const LAYER_LOW_SCENERY: int = 32

const GRAVITY: float = 22.0
## How quickly actors reach their wanted speed, in metres per second per second.
const ACCELERATION: float = 40.0
const BODY_RADIUS: float = 0.45
const BODY_HEIGHT: float = 1.7
## Players soft-lock onto an enemy already in the fight within this distance...
const SOFT_LOCK_RANGE: float = 30.0
## ...and onto one still asleep (a quiet camp, a boss not yet woken) only this close.
const PASSIVE_LOCK_RANGE: float = 12.0
const GUARD_BREAK_STAGGER: float = 0.9
const DOWNED_RESPAWN_TIME: float = 8.0
const RESPAWN_HEALTH_RATIO: float = 0.5
const FALL_RESPAWN_HEIGHT: float = -10.0
## Walking over Bramblebridge's arch and the expedition's ramps (07 GDD §1.1).
const FLOOR_SNAP_LENGTH: float = 0.35
const FLOOR_MAX_ANGLE_DEGREES: float = 50.0
const FLASH_TIME: float = 0.08
## Extra invulnerability after a Lifeline Pull lands, so the yank really saves you.
const PULL_SAFETY_TIME: float = 0.3
const POSE_SHARPNESS: float = 18.0
## A flow-cancel makes the body glow blue-white for a moment (and plays a tick).
const FLOW_GLOW_TIME: float = 0.18
const FLOW_GLOW_COLOR: Color = Color(0.55, 0.8, 1.0)
## The kinetic loop (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §3.1): every posture
## steps the hero along its facing (LoadoutComposer gives a melee strike with no
## lunge of its own these), so nobody stands still and clicks.
const STEP_LIGHT_M: float = 0.6
const STEP_HEAVY_M: float = 1.2
const STEP_FORWARD_HEAVY_M: float = 2.8
const STEP_BACK_HEAVY_M: float = -2.4
## The Static Mash Penalty: a third Light in a row, with no heavy, card, guard
## or dodge woven in, is winded for this long instead of its own recovery.
const STATIC_MASH_RECOVERY_MS: int = 550
## The Flow-Link window: the first 220 ms of a Light's recovery. Cancelling the
## 2nd or 3rd Light there into Forward+Heavy, Back+Heavy, R, L+R, a guard or a
## roll is a Flow-Link Pulse: stamina back and a little pip.
const FLOW_LINK_WINDOW_MS: int = 220
const FLOW_LINK_STAMINA_REFUND: float = 8.0
const FLOW_LINK_BONUS_PIP: float = 0.15
## The pulse's white-gold ring at the waist.
const FLOW_LINK_COLOR: Color = Color(1.0, 0.93, 0.7)

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
## An AI companion's brain (only on the host, which runs companions).
var companion: CompanionAIComponent
## True on every peer for an AI companion's actor.
var is_companion: bool = false
## Healers only.
var tether: SoulTetherComponent
## Bosses only.
var threat: ThreatComponent
## Enemies only: the Braced Front Guard (11 GDD §3.2).
var braced_guard: BracedGuardComponent
## Heroes: Sign-Flow, the Hearth-Rite and coats (14 GDD §2, §5).
var sign_flow: SignFlowComponent
## Foes with an encounter: the Glimmer-Spot a Bravery Counter cracks (14 GDD §2–3).
var glimmer: GlimmerSpotComponent
## Something this local player is standing at and can use with light (the Chime-Shrine).
var interactable: Interactable

## Where this actor wants to go this tick (world space, length 0..1).
var move_intent: Vector3 = Vector3.ZERO
## Seconds between this actor's AI thoughts (0: every physics tick). The world's
## AI tick scaler slows far-off enemies (ChunkNavBuilder); the body still moves every tick.
var ai_tick_interval: float = 0.0
var wants_guard: bool = false
## Set by this player's camera; movement is relative to it.
var camera_yaw: float = 0.0
## A dodge direction chosen for the actor (the Squire auto-evade sets it).
var evade_direction: Vector3 = Vector3.ZERO
var stagger_time_left: float = 0.0
var downed_time_left: float = 0.0

var visual: Node3D
## Players: the storybook puppet (its parts, cape and off-hand).
var visuals: ActorVisuals
## Melee players: the ribbon a rune-wreathed strike draws.
var trail: WeaponTrail
## Enemies: the body's material, lit by hit flashes and wind-up tells.
var _body_material: Material
var _glow: Color = Color.BLACK
var _last_pose_position: Vector3 = Vector3.ZERO
var _prop: Node3D
var _weapon_prop: Node3D
var _name_label: Label3D
var _hit_stop_left: float = 0.0
var _flash_left: float = 0.0
var _flow_glow_left: float = 0.0
var _pull_from: Vector3 = Vector3.ZERO
var _pull_to: Vector3 = Vector3.ZERO
var _pull_time: float = 0.0
var _pull_duration: float = 0.0
var _ai_clock: float = 0.0


# --- Construction ---------------------------------------------------------

## Gives a local player a controller. Call before adding the actor to the tree.
func attach_input(for_device: int, mode: int) -> void:
	input = InputComponent.new()
	input.setup(self, for_device, mode as InputComponent.AssistMode)


## Hands this actor to an AI companion brain. Call before adding it to the tree.
func attach_companion() -> void:
	is_companion = true
	companion = CompanionAIComponent.new()
	companion.setup(self)


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
	collision_mask = LAYER_WORLD | LAYER_LOW_SCENERY if is_boss() else LAYER_WORLD | LAYER_LOW_SCENERY | LAYER_BOSS
	# No jump button (Space rolls), so slopes and bridges must be walkable: stay
	# glued to ramps, climb anything up to 50 degrees, and keep pace on slopes.
	floor_snap_length = FLOOR_SNAP_LENGTH
	floor_max_angle = deg_to_rad(FLOOR_MAX_ANGLE_DEGREES)
	floor_constant_speed = true
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
	# Heroes play by the kinetic loop's rules (11 GDD §3.1); enemies swing as they always have.
	action_queue.kinetic_rules = not is_boss()
	action_queue.flow_link_pulsed.connect(_on_flow_link_pulsed)

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

	if is_boss():
		braced_guard = BracedGuardComponent.new()
		braced_guard.setup(self)
		add_child(braced_guard)
		var encounter: BossEncounterResource = ArsenalCatalog.current.encounter(glimmer_encounter_id())
		if encounter != null:
			glimmer = GlimmerSpotComponent.new()
			glimmer.setup(self, encounter)
			add_child(glimmer)

	if loadout.has_soul_tethers:
		tether = SoulTetherComponent.new()
		tether.setup(self)
		add_child(tether)

	if input != null:
		add_child(input)
		input.command_issued.connect(_on_command)
		input.tether_slot_pressed.connect(_on_tether_slot)
		apply_assist_mode()

	if not is_boss():
		sign_flow = SignFlowComponent.new()
		sign_flow.setup(self)
		add_child(sign_flow)

	if companion != null:
		add_child(companion)
		# Companions chain combos the way an Adventurer-mode player does.
		action_queue.buffer_window = InputComponent.ASSISTED_BUFFER_WINDOW
		action_queue.assisted_chaining = true

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
	if is_boss():
		_build_capsule_body()
	else:
		visuals = ActorVisuals.new()
		visuals.setup(self)
		visual.add_child(visuals)
	_prop = _build_prop()
	if _prop != null:
		visual.add_child(_prop)
	if loadout.weapon != null:
		trail = WeaponTrail.new()
		trail.setup(self)
		add_child(trail)
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


## An enemy's plain body: a cel capsule with a darker nose showing which way it faces.
func _build_capsule_body() -> void:
	_body_material = StorybookMaterial.actor(loadout.body_color, loadout.body_color)
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


## What the actor holds (and, without a puppet to show it, wears), drawn from its items.
func _build_prop() -> Node3D:
	if loadout.weapon == null and loadout.armor == null:
		return null
	var prop: Node3D = Node3D.new()
	prop.name = "Prop"
	if loadout.armor != null and visuals == null:
		prop.add_child(PropBuilder.build(loadout.armor.prop_parts, loadout.armor.model, "Armor", loadout.armor.item_id))
	if loadout.weapon != null:
		_weapon_prop = PropBuilder.build(loadout.weapon.prop_parts, loadout.weapon.model, "Weapon", loadout.weapon.item_id)
		prop.add_child(_weapon_prop)
		if visuals != null:
			visuals.set_weapon(_weapon_prop, loadout.weapon)
	return prop


## Swaps in a new compiled loadout (the Scribe Desk) without replacing the
## actor, so its view, HUD and any open menu stay put.
func re_equip(new_loadout: ClassLoadoutResource) -> void:
	action_queue.interrupt()
	hitbox.deactivate()
	var ratio: float = stats.health_ratio()
	loadout = new_loadout
	base_stats = loadout.stats.duplicate() as CharacterStatsResource
	PartyProgress.current.apply_upgrades(loadout.stats, base_stats)
	stats.rebind(loadout.stats, ratio)
	if _prop != null:
		visual.remove_child(_prop)
		_prop.queue_free()
	_weapon_prop = null
	if visuals != null:
		visuals.rebuild()
		_glow = Color.BLACK
	_prop = _build_prop()
	if _prop != null:
		visual.add_child(_prop)
	if input != null:
		apply_assist_mode()
	if not stats.is_downed:
		state_machine.transition(&"idle")


## A cel material for a part of this actor, rimmed in its colour.
func _flat_material(color: Color) -> Material:
	return StorybookMaterial.make(color, StorybookMaterial.ACTOR_RIM * 0.6, loadout.body_color.lightened(0.35))


## Lights the body up (a hit flash, a flow glow, a wind-up tell); black turns it off.
func _set_glow(color: Color) -> void:
	if color == _glow:
		return
	_glow = color
	if visuals != null:
		visuals.set_glow(color)
	elif _body_material != null:
		StorybookMaterial.set_glow(_body_material, color)


# --- Identity -------------------------------------------------------------

func role() -> int:
	return loadout.role


## On the enemy side (the raid boss and its minions share the boss role and layers).
func is_boss() -> bool:
	return loadout.role == ClassLoadoutResource.Role.BOSS


## The instance's raid boss itself, not a minion (BossDummy says yes).
func is_raid_boss() -> bool:
	return false


## Enemies: the trail XP it pays when it falls (11 GDD §5.2): a mob 35, the raid boss 200.
func trail_xp() -> int:
	return PartyProgress.XP_PER_BOSS if is_raid_boss() else PartyProgress.XP_PER_MOB


## Enemies: the BossEncounterResource id its Glimmer-Spot plays (&"" for none).
func glimmer_encounter_id() -> StringName:
	return &""


## Enemies: in the fight right now (a woken camp, an engaged boss). Players always are.
func is_engaged() -> bool:
	return true


## Enemies: still worth aiming at (not beaten, not fading away).
func is_targetable() -> bool:
	return not stats.is_downed


func is_local_player() -> bool:
	return input != null


func display_name() -> String:
	return "P%d %s%s" % [party_slot + 1, loadout.display_name, " (bot)" if is_companion else ""]


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
	if ai_tick_interval <= 0.0:
		_gather_intent(delta)
	else:
		_ai_clock += delta
		if _ai_clock >= ai_tick_interval:
			_gather_intent(_ai_clock)
			_ai_clock = 0.0
	if not is_inside_tree():
		return # Something this tick's input did removed the actor (leaving the party).
	stats.tick(delta, _can_regen_stamina())
	if sign_flow != null:
		sign_flow.tick(delta)
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


## Fills move_intent and wants_guard. Players read their controller, companions
## ask their Gambit brain; bosses override this with their own AI.
func _gather_intent(delta: float) -> void:
	if companion != null:
		companion.think(delta)
		return
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

## Who this actor's attacks and camera lean toward: the nearest enemy, as far
## as SOFT_LOCK_RANGE once it's in the fight, PASSIVE_LOCK_RANGE before.
func soft_target() -> ActorBase:
	var best: ActorBase = null
	var best_distance: float = INF
	for enemy: ActorBase in CombatDirector.current.enemies():
		if not enemy.is_targetable():
			continue
		var distance: float = enemy.global_position.distance_to(global_position)
		var reach: float = SOFT_LOCK_RANGE if enemy.is_engaged() else PASSIVE_LOCK_RANGE
		if distance <= reach and distance < best_distance:
			best_distance = distance
			best = enemy
	return best


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
		if sign_flow != null:
			sign_flow.note_command(command)
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
	if action.is_card():
		CombatDirector.current.invoke_card(self, action)
	if flowed and is_local_player():
		_flow_glow_left = FLOW_GLOW_TIME
		AudioCues.play(&"flow", 1.0 + (action_queue.speed_scale - 1.0) * 2.0)
	if action.effect == CombatActionResource.Effect.DODGE:
		state_machine.transition(&"dodge")
	else:
		state_machine.transition(&"attack")


## A Flow-Link Pulse (11 GDD §3.1): stamina back, a little pip, and a
## white-gold ring at the waist on every screen.
func _on_flow_link_pulsed(_from: CombatActionResource, _to_command: int) -> void:
	stats.restore_stamina(FLOW_LINK_STAMINA_REFUND)
	stats.add_resonance(FLOW_LINK_BONUS_PIP)
	CombatDirector.current.show_flow_link(self)


## The Wayfarer Pennant over this hero for a new trail level (11 GDD §6).
func show_milestone_pennant(level: int, granted: String) -> void:
	if visuals != null:
		visuals.show_milestone_pennant(level, granted)


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
			if action.is_projectile():
				CombatDirector.current.launch_projectile(self, action, action_queue.flowed_into_current)
			else:
				hitbox.activate(action)
			if action.heal_amount > 0.0:
				# The Way-Staff's flourishes: a warm gust mends the most hurt ally near you.
				CombatDirector.current.mend_most_hurt(self, action.heal_amount, action.effect_radius)
		CombatActionResource.Effect.DODGE:
			stats.grant_invulnerability(action.active_time / action_queue.speed_scale)
		CombatActionResource.Effect.TAUNT:
			CombatDirector.current.taunt_bosses(self, action.effect_duration)
		CombatActionResource.Effect.SHADOW_SANCTUARY:
			CombatDirector.current.spawn_zone(self, SanctuaryZone.Shape.CONE, action)
		CombatActionResource.Effect.GREEN_SANCTUARY:
			CombatDirector.current.spawn_zone(self, SanctuaryZone.Shape.RING, action)
		CombatActionResource.Effect.HOMING_HEAL:
			CombatDirector.current.launch_homing_heal(self, tether.tethered_actor(), action.heal_amount, action.echo_heal_ratio)
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
	if braced_guard != null:
		braced_guard.filter_strike(event)
	if glimmer != null:
		glimmer.filter_strike(event)
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
	if _weapon_prop != null and trail != null:
		# A rune-wreathed strike sweeps the weapon through the trail's arc.
		_weapon_prop.rotation.y = trail.swing_angle
	if visuals != null:
		# R and L+R swell the weapon into its Sign's glowing silhouette (any peer: copies read the owner's action).
		visuals.update_channel(delta, current_action())
	if _flash_left > 0.0:
		_set_glow(Color(1.0, 1.0, 1.0) * 0.9)
	elif _flow_glow_left > 0.0:
		_set_glow(FLOW_GLOW_COLOR * (_flow_glow_left / FLOW_GLOW_TIME) * 1.4)
	else:
		_set_glow(Color.BLACK)
	if visuals != null:
		# Worked out from how far it moved, so a networked copy's cape streams too.
		var moved: Vector3 = (global_position - _last_pose_position) / maxf(delta, 0.0001)
		visuals.update_motion(delta, moved if moved.length() < 30.0 else Vector3.ZERO, loadout.stats.move_speed)
	_last_pose_position = global_position
