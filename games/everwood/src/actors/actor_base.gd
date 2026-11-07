## Every actor, player or boss, is one CharacterBody3D made of component nodes.
## ActorBase builds the components it needs in code (Code-First Scene Safety),
## wires them together through signals, and ticks them with a hit-stop-aware
## delta so a landed blow freezes just the two actors involved.
##
## What a player swings and casts comes from its compiled loadout (equipment
## and Scribe Cards, LoadoutComposer). Nothing here knows a weapon or a card by
## name: props are built from the items' parts, and a strike either swings the
## hitbox or fires a projectile, as its action says. A player is drawn as a
## sculpted 24-bone storybook hero (ActorVisuals, 19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md)
## that the animator and kinematics pose every tick, hit-stops included; enemies
## draw their own bodies.
##
## The Phase 12 Kaizen pass (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §8) adds three
## components: heroes track their directional combo forms (ComboChainComponent),
## foes with a Miyamoto tier leap back and lock (PostureEscalationComponent), and
## a four-gate raid boss plays its gates (BossGateComponent). An enemy blow that
## carries a Sign lights its limb in that colour through the wind-up, so a Tank
## knows which Ward-Mantle soaks it.
class_name ActorBase
extends CharacterBody3D

signal went_down(actor: ActorBase)
signal got_up(actor: ActorBase)
## Off the ground on a jump, and back down (K1).
signal jumped(actor: ActorBase)
signal landed(actor: ActorBase)

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
## Phase 12 Kaizen (K1): a jump leaves the ground at this many metres a second
## (about 0.96 m high and 0.6 s in the air under GRAVITY).
const JUMP_VELOCITY: float = 6.5
## Holding sprint while moving runs this much faster and drains this much stamina a second.
const SPRINT_SPEED_SCALE: float = 1.5
const SPRINT_STAMINA_PER_SEC: float = 12.0
## Stamina doesn't start coming back until sprinting has stopped this long.
const SPRINT_REGEN_HOLD: float = 0.4
## Toggle Sprint (13_PLAYTEST §2.3): it keeps going while the stick is at least
## this share forward (about 55 degrees either side of straight ahead), and ends
## after the hero has stood still this long.
const SPRINT_KEEP_FORWARD: float = 0.57
const SPRINT_STOP_GRACE: float = 0.35
## The stick has to be this far over to sprint.
const SPRINT_MIN_STICK: float = 0.2
## How quickly actors reach their wanted speed, in metres per second per second.
const ACCELERATION: float = 40.0
const BODY_RADIUS: float = 0.45
const BODY_HEIGHT: float = 1.7
## Nameplates (18 GDD §6.2): 2.25 m up, staggered 0.22 m by seat; companions' fade to 35% near the leader out of combat.
const NAMEPLATE_BASE_HEIGHT: float = 2.25
const NAMEPLATE_STAGGER: float = 0.22
const COMPANION_PLATE_FADED_ALPHA: float = 0.35
const COMPANION_PLATE_FADE_RADIUS: float = 4.0
## Plates stagger by seat only while another hero stands this close.
const NAMEPLATE_CROWD_RADIUS: float = 3.0
## Players soft-lock onto an enemy already in the fight within this distance...
const SOFT_LOCK_RANGE: float = 30.0
## ...and onto one still asleep (a quiet camp, a boss not yet woken) only this close.
const PASSIVE_LOCK_RANGE: float = 12.0
const GUARD_BREAK_STAGGER: float = 0.9
const DOWNED_RESPAWN_TIME: float = 8.0
const RESPAWN_HEALTH_RATIO: float = 0.5
const FALL_RESPAWN_HEIGHT: float = -10.0
## Below this an actor has fallen out of the world and gets back up at its spawn
## point. A level whose ground goes deeper (the Caldera's Sap Galleries at -15 m)
## lowers it while it's loaded.
static var fall_respawn_height: float = FALL_RESPAWN_HEIGHT
## Walking over Bramble-Bridge's arch and the expedition's ramps (07 GDD §1.1).
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
## Foes: a spirit of the First-Quiet on the Hob-to-Boggart Spectrum (15 GDD §6.1).
var spectrum: HobSpectrumComponent
## Heroes: the directional combo forms (14 GDD §8).
var combo: ComboChainComponent
## Foes with an encounter: the Miyamoto armour-drop and its locks (14 GDD §8).
var posture: PostureEscalationComponent
## Raid bosses: the four gates (14 GDD §8).
var gates: BossGateComponent
## Something this local player is standing at and can use with light (the Chime-Shrine).
var interactable: Interactable

## Where this actor wants to go this tick (world space, length 0..1).
var move_intent: Vector3 = Vector3.ZERO
## Running half again as fast on sprint (K1); jumps made this session.
var sprinting: bool = false
## A toggled sprint is under way (Toggle Sprint; it outlives the click).
var sprint_latched: bool = false
var _sprint_still: float = 0.0
var jumps: int = 0
var _sprint_spent: bool = false
var _launching: bool = false
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
## Melee players: the ribbon a Sign-wreathed strike draws.
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
## Enemies: limbs that glow in a blow's Sign through its wind-up (register_aura_limb), and their glowing shells.
var _aura_shells: Array[MeshInstance3D] = []
var _aura_material: StandardMaterial3D
var _aura_sign: int = ScribeSignResource.Sign.NONE


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
			posture = PostureEscalationComponent.new()
			posture.setup(self)
			add_child(posture)
			if is_raid_boss():
				gates = BossGateComponent.new()
				gates.setup(self)
				add_child(gates)
		spectrum = HobSpectrumComponent.new()
		spectrum.setup(self)
		add_child(spectrum)

	if loadout.has_soul_tethers:
		tether = SoulTetherComponent.new()
		tether.setup(self)
		add_child(tether)

	if input != null:
		add_child(input)
		input.command_issued.connect(_on_command)
		input.tether_slot_pressed.connect(_on_tether_slot)
		input.jump_requested.connect(_on_jump_requested)
		apply_assist_mode()

	if not is_boss():
		sign_flow = SignFlowComponent.new()
		sign_flow.setup(self)
		add_child(sign_flow)
		combo = ComboChainComponent.new()
		combo.setup(self)
		add_child(combo)

	if companion != null:
		add_child(companion)
		# Companions chain combos the way an Adventurer-mode player does.
		action_queue.buffer_window = InputComponent.ASSISTED_BUFFER_WINDOW
		action_queue.assisted_chaining = true

	state_machine = StateMachine.new()
	add_child(state_machine)
	var state_list: Array[ActorState] = [
		IdleState.new(), LocomotionState.new(), AttackState.new(), GuardState.new(),
		DodgeState.new(), StaggerState.new(), DownedState.new(), JumpState.new(),
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
	_name_label.position = Vector3(0.0, nameplate_height(false), 0.0)
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
## A sculpted hero mounts its tiered weapon in hand on the rig instead.
func _build_prop() -> Node3D:
	if loadout.weapon == null and loadout.armor == null:
		return null
	if visuals != null and visuals.has_rig():
		_weapon_prop = visuals.mount_weapon(loadout.weapon)
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


## Enemies: beaten, so its spirit is un-boggarted (the raid boss: vanquished).
func is_beaten() -> bool:
	return stats.is_downed


## Enemies: whether it can leap back when it sheds its armour (a rooted lasher can't).
func can_leap() -> bool:
	return true


## Raid bosses: a four-gate boss just entered `gate` (BossGateComponent; 1 is
## the Summons, 2 the Tempest, 3 the Seal-Turn). Each boss plays its own part.
func on_boss_gate(_gate: int) -> void:
	pass


## Enemies: where this spirit stands on the Hob-to-Boggart Spectrum and how
## it's un-boggarted (15 GDD §6.1). By default an awakened boggart, released
## as a hedge-wren.
func configure_spirit(_spirit: HobSpectrumComponent) -> void:
	pass


func is_local_player() -> bool:
	return input != null


## A hero's nameplate (18 GDD §6.2): "P2 · Bell-Keeper", companion or not.
func display_name() -> String:
	return "P%d · %s" % [party_slot + 1, loadout.display_name]


func refresh_name_label() -> void:
	if _name_label != null:
		_name_label.text = display_name()


## How high a hero's nameplate floats (18 GDD §6.2): 2.25 m for a hero of the
## standard build, and while another hero stands within 3 m (`crowded`)
## staggered 0.22 m by seat (seat % 3), so a huddled party's plates never overlap.
func nameplate_height(crowded: bool = true) -> float:
	return NAMEPLATE_BASE_HEIGHT * (body_height() / BODY_HEIGHT) + (float(party_slot % 3) * NAMEPLATE_STAGGER if crowded else 0.0)


## A hero's nameplate staggers by seat while the party crowds round; out of
## combat, a companion's fades to 35% within 4 m of the party's leader, so a
## crowd at the shrine stays readable (18 GDD §6.2).
func _update_nameplate(delta: float) -> void:
	if _name_label == null or (input == null and not is_companion):
		return
	var leader: ActorBase = null
	var crowded: bool = false
	for member: ActorBase in CombatDirector.current.alive_party():
		if leader == null and not member.is_companion:
			leader = member
		if member != self and member.global_position.distance_to(global_position) <= NAMEPLATE_CROWD_RADIUS:
			crowded = true
	_name_label.position.y = move_toward(_name_label.position.y, nameplate_height(crowded), delta * 1.5)
	if not is_companion:
		return
	var calm: bool = sign_flow == null or not sign_flow.is_in_combat
	var close: bool = leader != null and leader.global_position.distance_to(global_position) <= COMPANION_PLATE_FADE_RADIUS
	var wanted: float = COMPANION_PLATE_FADED_ALPHA if calm and close else 1.0
	_name_label.modulate.a = move_toward(_name_label.modulate.a, wanted, delta * 3.0)


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
	_update_nameplate(delta)
	if not is_multiplayer_authority():
		# Someone else's actor: follow what its owner sends.
		net_sync.tick_copy(delta)
		_update_pose(delta)
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	_flow_glow_left = maxf(0.0, _flow_glow_left - delta)
	if _hit_stop_left > 0.0:
		# Hit-stop: this actor alone freezes for a few frames (its hero trembles through it).
		_hit_stop_left -= delta
		if visuals != null:
			visuals.update_rig(delta, Vector3.ZERO, true)
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
	_update_sprint(delta)
	stats.tick(delta, _can_regen_stamina())
	if sign_flow != null:
		sign_flow.tick(delta)
	if combo != null:
		combo.tick(delta)
	if _pull_duration > 0.0:
		_update_pull(delta)
	else:
		action_queue.tick(delta)
		hitbox.poll()
		state_machine.physics_update(delta)
		# The frame a jump launches, the floor doesn't hold the hero down.
		if is_on_floor() and not _launching:
			velocity.y = minf(velocity.y, 0.0)
		elif not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		_launching = false
	if tether != null:
		tether.update_beam()
	net_sync.tick_owner(delta)
	_update_pose(delta)
	if global_position.y < fall_respawn_height:
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
	return (state_machine.is_in(&"idle") or state_machine.is_in(&"locomotion") or state_machine.is_in(&"jump")) and not stats.guarding and not sprinting


# --- Jump and sprint (Phase 12 Kaizen, K1) --------------------------------

## How fast this actor runs right now: its stats' pace, half again while sprinting.
func locomotion_speed() -> float:
	return loadout.stats.move_speed * (SPRINT_SPEED_SCALE if sprinting else 1.0)


## A hero on the ground, standing or running, and free to act can jump.
func can_jump() -> bool:
	return is_on_floor() and can_act() and (state_machine.is_in(&"idle") or state_machine.is_in(&"locomotion"))


func _on_jump_requested() -> void:
	if can_jump():
		state_machine.transition(&"jump")


## JumpState: up she goes.
func launch_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_launching = true
	jumps += 1
	jumped.emit(self)


## JumpState: feet back on the ground.
func land_jump() -> void:
	landed.emit(self)


## Sprint while it's held, the hero is moving on their feet and there's stamina;
## run dry and it stops until sprint is let go. With Toggle Sprint on (the
## Options menu's default, 13_PLAYTEST §2.3) a click of L3 / Shift starts a
## sprint that keeps going until the hero steers sideways or back, stands still
## for a moment, runs dry, or the button is clicked again.
func _update_sprint(delta: float) -> void:
	var held: bool = input != null and input.sprint_held
	if input != null and SettingsManager.toggle_sprint():
		if input.sprint_pressed:
			sprint_latched = not sprint_latched
			_sprint_still = 0.0
		if sprint_latched and _sprint_breaks(delta):
			sprint_latched = false
		held = sprint_latched
	else:
		sprint_latched = false
	if not held:
		_sprint_spent = false
	var on_feet: bool = state_machine.is_in(&"locomotion") or state_machine.is_in(&"jump")
	var wants: bool = held and not _sprint_spent and on_feet and move_intent.length() > SPRINT_MIN_STICK and not stats.is_downed
	if not wants or stats.stamina <= 0.0:
		if wants:
			_sprint_spent = true
			sprint_latched = false
		sprinting = false
		return
	sprinting = true
	stats.drain_stamina(SPRINT_STAMINA_PER_SEC * delta, SPRINT_REGEN_HOLD)
	if stats.stamina <= 0.0:
		sprinting = false
		_sprint_spent = true
		sprint_latched = false


## Whether the hero's steering ends a toggled sprint: mostly sideways or back
## (less than SPRINT_KEEP_FORWARD of the stick forward), or standing still for SPRINT_STOP_GRACE.
func _sprint_breaks(delta: float) -> bool:
	var stick: Vector2 = input.move_input
	if stick.length() < SPRINT_MIN_STICK:
		_sprint_still += delta
		return _sprint_still >= SPRINT_STOP_GRACE
	_sprint_still = 0.0
	return stick.y < stick.length() * SPRINT_KEEP_FORWARD


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
	if visuals != null:
		visuals.note_hit_stop(duration)


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


## How far, and which way, `action` carries the actor across its wind-up and
## active frames: its own lunge along the facing, or a combo finisher's step.
func posture_step(action: CombatActionResource) -> Vector3:
	if combo != null and combo.has_step_for(action):
		return combo.step_vector(action)
	return facing_vector() * action.lunge_distance


## A flank-orbit finisher circles the foe, kept turned toward it.
func posture_orbits(action: CombatActionResource) -> bool:
	return combo != null and combo.orbits(action)


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
## A foe's gates, Glimmer-Spot and lock judge it first; a hero's Ward-Mantle and
## Ward Blessing soften it.
func receive_strike(event: CombatEvent) -> int:
	if braced_guard != null:
		braced_guard.filter_strike(event)
	# A Seal-Turn in a boss's fourth gate settles the strike before its Glimmer-Spot sees it.
	var countered: bool = gates != null and gates.filter_strike(event)
	if glimmer != null and not countered:
		countered = glimmer.filter_strike(event)
	if posture != null and not countered:
		posture.filter_strike(event)
	if sign_flow != null:
		sign_flow.filter_incoming(event)
	var multiplier: float = CombatDirector.current.damage_taken_multiplier(self)
	var outcome: StatsComponent.StrikeOutcome = stats.mitigate_strike(
		event.damage * multiplier, event.poise_damage, _faces_toward(event.origin), event.unavoidable)
	if sign_flow != null:
		sign_flow.after_incoming(event, outcome)
	if gates != null:
		gates.after_strike(event, outcome)
	match outcome:
		StatsComponent.StrikeOutcome.GUARD_BROKEN:
			stagger(GUARD_BREAK_STAGGER)
			_flash_left = FLASH_TIME
		StatsComponent.StrikeOutcome.HIT, StatsComponent.StrikeOutcome.GUARDED:
			_flash_left = FLASH_TIME
		StatsComponent.StrikeOutcome.PERFECT_GUARD:
			if visuals != null:
				visuals.play_perfect_guard_parry()
	return outcome


func receive_heal(amount: float) -> float:
	return stats.heal(amount)


func _faces_toward(point: Vector3) -> bool:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	return to_point.length() < 0.01 or facing_vector().dot(to_point.normalized()) > 0.0


func stagger(seconds: float) -> void:
	# A Ward-Mantle or a Support's Aegis Ward shrugs the stun off (14 GDD §8).
	if sign_flow != null and sign_flow.shrugs_off_stagger():
		return
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


# --- Enemy attack auras (14 GDD §8, the Tank's loop) --------------------------

## Enemies: a limb (a fist, a jaw, a weapon) that glows in its blow's Sign
## through the wind-up. A shell `radius` round it carries the glow.
func register_aura_limb(limb: Node3D, radius: float) -> void:
	if _aura_material == null:
		_aura_material = StorybookMaterial.glowing(Color.WHITE, 2.6)
		_aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var shell: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.sphere("AttackAura", radius, Vector3.ZERO, _aura_material))
	shell.visible = false
	limb.add_child(shell)
	_aura_shells.append(shell)


## The Sign glowing on this foe's limbs right now (Sign.NONE when none is).
func attack_aura_sign() -> int:
	return _aura_sign


## Lit through the wind-up of a blow that carries a Sign, on every peer.
func _update_attack_aura() -> void:
	var action: CombatActionResource = current_action()
	var lit: int = ScribeSignResource.Sign.NONE
	if action != null and action.scribe_sign != ScribeSignResource.Sign.NONE and not stats.is_downed \
			and current_phase() == ActionQueueComponent.Phase.WINDUP:
		lit = action.scribe_sign
	if lit != _aura_sign:
		_aura_sign = lit
		for shell: MeshInstance3D in _aura_shells:
			shell.visible = lit != ScribeSignResource.Sign.NONE
	if lit != ScribeSignResource.Sign.NONE:
		var color: Color = ArsenalCatalog.current.sign_seal(lit).color
		var pulse: float = 0.45 + 0.2 * sin(CombatDirector.game_time() * 14.0)
		_aura_material.albedo_color = Color(color, pulse)
		_aura_material.emission = color


# --- Greybox posing -------------------------------------------------------

func _update_pose(delta: float) -> void:
	if visuals != null and visuals.has_rig():
		_update_rig_pose(delta)
		return
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
		# A Sign-wreathed strike sweeps the weapon through the trail's arc.
		_weapon_prop.rotation.y = trail.swing_angle
	if visuals != null:
		# R and L+R swell the weapon into its Sign's glowing silhouette (any peer: copies read the owner's action).
		visuals.update_channel(delta, current_action())
	if not _aura_shells.is_empty():
		_update_attack_aura()
	if _flash_left > 0.0:
		_set_glow(Color(1.0, 1.0, 1.0) * 0.9)
	elif _flow_glow_left > 0.0:
		_set_glow(FLOW_GLOW_COLOR * (_flow_glow_left / FLOW_GLOW_TIME) * 1.4)
	else:
		_set_glow(Color.BLACK)
	if visuals != null:
		# Worked out from how far it moved, so a networked copy's cape streams too.
		var moved: Vector3 = (global_position - _last_pose_position) / maxf(delta, 0.0001)
		visuals.update_rig(delta, moved if moved.length() < 30.0 else Vector3.ZERO)
	_last_pose_position = global_position


## A sculpted hero poses itself (HeroCombatAnimator and StorybookKinematicsModifier3D):
## the weapon's swell and Sign looks, the glow, then the rig, every peer.
func _update_rig_pose(delta: float) -> void:
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	visuals.update_channel(delta, current_action())
	if _flash_left > 0.0:
		_set_glow(Color(1.0, 1.0, 1.0) * 0.9)
	elif _flow_glow_left > 0.0:
		_set_glow(FLOW_GLOW_COLOR * (_flow_glow_left / FLOW_GLOW_TIME) * 1.4)
	else:
		_set_glow(Color.BLACK)
	# Worked out from how far it moved, so a networked copy's cloak streams too.
	var moved: Vector3 = (global_position - _last_pose_position) / maxf(delta, 0.0001)
	visuals.update_rig(delta, moved if moved.length() < 30.0 else Vector3.ZERO)
	_last_pose_position = global_position
