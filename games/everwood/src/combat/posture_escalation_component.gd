## The Miyamoto Posture Escalation on a foe (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §8),
## played from its BossEncounterResource the same way for any foe:
##
## - TIER_0_PUNCHING_BAG kin never lock (GlimmerSpotComponent cracks them under Iron-Root).
## - A TIER_1_SINGLE_EVADE foe fights in STATE_ATTACKING_POSTURE, taking full
##   damage, until it drops to 75% health. Then, in STATE_EVASIVE_ARMOR_DROP,
##   it leaps 3 m back over 220 ms (a rooted foe stays put), an armour plate
##   falls from it, and a Glimmer-Spot ring lights on its body: white-gold for
##   a MARTIAL_COMBO_KEY, the Sign's colour for an ELEMENTAL_INK_KEY.
## - While it's locked, the key cracks it: a stunning combo (the Sundering
##   Gap-Leap) for a martial lock, a strike in the lock's Sign (a Weapon-Coat,
##   or a Support's Ink-Share) for an ink lock, or a One-and-Done for either.
##   That's a Bravery Counter: (60 + 45) x M(L) poise, a 2.5 s stun, and the
##   Sign's detonation. Then it's STATE_LOCK_CRACKED and takes full damage.
## - A plain blow on a locked foe still lands, at half damage with a dull
##   clank, so an unprepared hero alone can always grind it down.
## - A TIER_2_MULTI_LOCK foe does all this again at each gate threshold
##   (75%, 50%, 25%), each lock its own key.
##
## The foe's owner decides when it locks and judges strikes; every peer sees
## the leap (synced position), the falling plate and the ring.
class_name PostureEscalationComponent
extends Node3D

signal armor_dropped(lock_type: int)
signal lock_cracked(lock_type: int)

## The smoke test's older checks switch it off (like GlimmerSpotComponent.enabled).
static var enabled: bool = true

enum PostureState { STATE_ATTACKING_POSTURE, STATE_EVASIVE_ARMOR_DROP, STATE_LOCK_CRACKED }

const Key = BossEncounterResource.LockKeyType

## The back-leap takes 220 ms (and the foe can't be touched mid-leap).
const LEAP_TIME: float = 0.22
## A wall or boulder this close behind cuts the leap short.
const LEAP_CLEARANCE: float = 0.4
const MARTIAL_COLOR: Color = Color(1.0, 0.95, 0.78)
const CLANK_COLOR: Color = Color(0.55, 0.55, 0.58)
const RING_THICKNESS: float = 0.07
const RING_SPIN: float = 1.6
const RING_ENERGY: float = 3.2
## The shed plate falls for this long, then lies where it fell this long.
const PLATE_FALL_TIME: float = 0.45
const PLATE_LINGER: float = 6.0
const PLATE_COLOR: Color = Color(0.42, 0.4, 0.38)

var actor: ActorBase
var state: PostureState = PostureState.STATE_ATTACKING_POSTURE
## The lock showing now: its key and, for an ink lock, the Signs that crack it.
var lock_type: BossEncounterResource.LockKeyType = Key.NONE
var lock_signs: Array[int] = []
var locks_shown: int = 0
var locks_cracked: int = 0
## How far the last leap carried it.
var last_leap_distance: float = 0.0

## The next lock threshold to watch (an index into the encounter's lock_thresholds).
var _next_lock: int = 0
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _age: float = 0.0


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "PostureEscalation"


func _ready() -> void:
	_ring_material = StorybookMaterial.glowing(MARTIAL_COLOR, RING_ENERGY)
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var radius: float = actor.body_radius() * 1.05
	_ring = ShapeKit.no_shadow(ShapeKit.torus("GlimmerRing", radius - RING_THICKNESS, radius, Vector3.ZERO, _ring_material))
	_ring.visible = false
	add_child(_ring)
	# Round the chest, where the plate came off.
	position = Vector3(0.0, actor.body_height() * 0.55, 0.0)


func encounter() -> BossEncounterResource:
	return actor.glimmer.encounter if actor.glimmer != null else null


## Locked now: the key cracks it, plain blows clank for half.
func is_locked() -> bool:
	return state == PostureState.STATE_EVASIVE_ARMOR_DROP


## A Squire's smart pick finishes the Sundering Gap-Leap when this is true.
func wants_martial_key() -> bool:
	return enabled and is_locked() and lock_type == Key.MARTIAL_COMBO_KEY


## The ring's colour: white-gold for a martial lock, the Sign's for an ink lock.
func lock_color() -> Color:
	if lock_type == Key.ELEMENTAL_INK_KEY and not lock_signs.is_empty():
		return ArsenalCatalog.current.sign_seal(lock_signs[0]).color
	return MARTIAL_COLOR


func is_ring_lit() -> bool:
	return _ring != null and _ring.visible


func _process(delta: float) -> void:
	_age += delta
	if _ring.visible:
		_ring.rotation = Vector3(PI * 0.5, _ring.rotation.y + RING_SPIN * delta, 0.0)
		var pulse: float = 1.0 + 0.12 * sin(_age * 10.0)
		_ring.scale = Vector3.ONE * pulse


func _physics_process(_delta: float) -> void:
	var met: BossEncounterResource = encounter()
	if not enabled or met == null or not met.has_armor_drop() or not actor.is_multiplayer_authority():
		return
	if actor.is_beaten():
		if state != PostureState.STATE_ATTACKING_POSTURE or _next_lock > 0:
			_reset_everywhere()
		return
	# Back to full health (it gave up the chase and mended): it fights fresh again.
	if _next_lock > 0 and actor.stats.health_ratio() >= 0.999 and not actor.is_engaged():
		_reset_everywhere()
		return
	var thresholds: Array[float] = met.lock_thresholds()
	if _next_lock < thresholds.size() and actor.stats.health_ratio() <= thresholds[_next_lock] + 0.0001:
		_drop_armor(_next_lock)
		_next_lock += 1


## Owner: the foe leaps back, sheds a plate and shows lock `index`'s key, on every peer.
func _drop_armor(index: int) -> void:
	var met: BossEncounterResource = encounter()
	var key: BossEncounterResource.LockKeyType = met.lock_type_at(index)
	var signs: Array[int] = met.lock_signs_at(index)
	last_leap_distance = 0.0
	if actor.can_leap() and met.evade_leap_distance_m > 0.0:
		_leap_back(met.evade_leap_distance_m)
	var sign_list: PackedInt32Array = PackedInt32Array(signs)
	_show_lock(key, sign_list)
	CombatDirector.current.show_cue(actor, lock_color(), &"knockdown")
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_show_lock_remote.rpc_id(peer_id, key, sign_list)


## A quick hop away from whoever it's fighting (straight back if nobody), cut short by anything solid behind it.
func _leap_back(distance: float) -> void:
	var away: Vector3 = -actor.facing_vector()
	var foe: ActorBase = actor.soft_target()
	if foe != null:
		var from_foe: Vector3 = actor.global_position - foe.global_position
		from_foe.y = 0.0
		if from_foe.length() > 0.05:
			away = from_foe.normalized()
	var reach: float = distance
	var world: World3D = actor.get_world_3d()
	if world != null:
		var chest: Vector3 = actor.global_position + Vector3.UP * actor.body_height() * 0.5
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(chest, chest + away * (distance + actor.body_radius()),
			ActorBase.LAYER_WORLD | ActorBase.LAYER_LOW_SCENERY)
		var hit: Dictionary = world.direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			reach = maxf(0.0, chest.distance_to(hit["position"]) - actor.body_radius() - LEAP_CLEARANCE)
	last_leap_distance = reach
	if reach > 0.05:
		actor.start_forced_move(actor.global_position + away * reach, LEAP_TIME)


@rpc("authority", "call_remote", "reliable")
func _show_lock_remote(key: int, signs: PackedInt32Array) -> void:
	_show_lock(key as BossEncounterResource.LockKeyType, signs)


## Every peer: the plate falls and the ring lights in the key's colour.
func _show_lock(key: BossEncounterResource.LockKeyType, signs: PackedInt32Array) -> void:
	state = PostureState.STATE_EVASIVE_ARMOR_DROP
	lock_type = key
	lock_signs.clear()
	for each: int in signs:
		lock_signs.append(each)
	locks_shown += 1
	var color: Color = lock_color()
	_ring_material.albedo_color = color
	_ring_material.emission = color
	_ring.visible = true
	_shed_plate()
	armor_dropped.emit(key)


## An outer plate drops off the chest, tumbles to the ground and lies there a while.
func _shed_plate() -> void:
	var holder: Node = actor.get_parent()
	if holder == null or not actor.is_inside_tree():
		return
	var plate: ShedPlate = ShedPlate.new()
	plate.name = "ShedPlate"
	var size: Vector3 = Vector3(actor.body_radius() * 1.2, actor.body_height() * 0.3, 0.08)
	plate.mesh_node = ShapeKit.box("Plate", size, Vector3.ZERO, StorybookMaterial.make(PLATE_COLOR, StorybookMaterial.ACTOR_RIM * 0.6, PLATE_COLOR.lightened(0.3)))
	plate.add_child(plate.mesh_node)
	holder.add_child(plate)
	plate.global_position = actor.global_position + Vector3.UP * actor.body_height() * 0.55 + actor.facing_vector() * actor.body_radius()
	plate.rotation.y = actor.rotation.y
	plate.ground_y = actor.global_position.y + size.z * 0.5


## The foe's owner judges a strike while it's locked (ActorBase.receive_strike).
## The key cracks the lock (a Bravery Counter, true); any other blow clanks for half.
func filter_strike(event: CombatEvent) -> bool:
	if not enabled or not is_locked() or event.unavoidable or actor.stats.is_invulnerable():
		return false
	var met: BossEncounterResource = encounter()
	if met == null:
		return false
	var fits: bool = event.cracks_lock
	match lock_type:
		Key.MARTIAL_COMBO_KEY:
			fits = fits or event.breaks_martial_lock
		Key.ELEMENTAL_INK_KEY:
			fits = fits or lock_signs.has(event.counter_sign())
	if fits:
		_crack(event, met)
		return true
	# Unprepared: half damage, a dull clank, and nobody is ever stuck.
	event.damage *= met.uninked_physical_mult
	CombatDirector.current.show_cue(actor, CLANK_COLOR, &"clank")
	return false


func _crack(event: CombatEvent, met: BossEncounterResource) -> void:
	var cracked: BossEncounterResource.LockKeyType = lock_type
	var counter_sign: int = event.counter_sign() if cracked == Key.ELEMENTAL_INK_KEY else ScribeSignResource.Sign.NONE
	event.poise_damage = met.bravery_counter_poise()
	event.stun_seconds = maxf(event.stun_seconds, BossEncounterResource.LOCK_COUNTER_STUN)
	locks_cracked += 1
	CombatDirector.current.bravery_counter(actor, event, counter_sign, met, "LOCK CRACKED" if counter_sign == ScribeSignResource.Sign.NONE else "")
	_show_cracked()
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_show_cracked_remote.rpc_id(peer_id)
	lock_cracked.emit(cracked)


@rpc("authority", "call_remote", "reliable")
func _show_cracked_remote() -> void:
	_show_cracked()


func _show_cracked() -> void:
	SignMark.shockwave(CombatDirector.current.effects_root, actor.global_position, lock_color())
	state = PostureState.STATE_LOCK_CRACKED
	_ring.visible = false


func _reset_everywhere() -> void:
	_reset()
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_reset_remote.rpc_id(peer_id)


@rpc("authority", "call_remote", "reliable")
func _reset_remote() -> void:
	_reset()


func _reset() -> void:
	state = PostureState.STATE_ATTACKING_POSTURE
	lock_type = Key.NONE
	lock_signs.clear()
	_next_lock = 0
	if _ring != null:
		_ring.visible = false


## A shed armour plate: it tumbles to the ground, lies there, then sinks away.
class ShedPlate extends Node3D:
	var mesh_node: MeshInstance3D
	var ground_y: float = 0.0
	var _age: float = 0.0
	var _start_y: float = 0.0

	func _ready() -> void:
		_start_y = global_position.y

	func _process(delta: float) -> void:
		_age += delta
		var fall: float = clampf(_age / PostureEscalationComponent.PLATE_FALL_TIME, 0.0, 1.0)
		global_position.y = lerpf(_start_y, ground_y, fall * fall)
		rotation.x = -PI * 0.5 * fall
		var gone: float = _age - PostureEscalationComponent.PLATE_FALL_TIME - PostureEscalationComponent.PLATE_LINGER
		if gone > 0.0:
			global_position.y = ground_y - gone * 0.3
			if gone > 1.0:
				queue_free()
