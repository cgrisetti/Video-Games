## Braced Front Guard (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §3.2): why a party
## can't clump in front of a foe and mash. Every enemy has one.
##
## Three hits on its front 120° within 4 s and it raises an amber timber-and-
## brass buckler across that cone for 5 s. While braced:
##   - hits on the front deal 30% damage and half poise, with a dull clunk;
##     a Shield-Sworn's Iron-Root strikes, or any strike of a +Tank (Stout
##     Heart) Shield-Sworn, crack it instead at 2x poise, and a knockdown
##     shatters it
##   - a Forward+Heavy, Back+Heavy, R or L+R landed on its unguarded rear and
##     sides (the other 240°) is a Flank Breach: 1.35x damage, +20 poise, and
##     the guard shatters
##   - after 1.8 s it telegraphs a 2.5 m red shield-shove in front of it that
##     knocks back whoever is still mashing there, unless they shelter behind
##     the tank's Shadow Sanctuary
## The enemy's owner runs it; every peer sees the buckler and the shove.
class_name BracedGuardComponent
extends Node

signal braced_changed(braced: bool)
signal flank_breached(attacker_id: StringName)

const BRACED_GUARD_HIT_THRESHOLD: int = 3
## Frontal hits count while they're this recent...
const BRACED_GUARD_WINDOW_S: float = 4.0
## ...and the guard stays up this long.
const BRACED_GUARD_DURATION_S: float = 5.0
const BRACED_FRONT_DAMAGE_MULT: float = 0.30
const BRACED_FRONT_POISE_MULT: float = 0.5
## A Shield-Sworn cracking the guard from the front.
const TANK_GUARD_POISE_MULT: float = 2.0
const FLANK_BREACH_DAMAGE_MULT: float = 1.35
const FLANK_BREACH_BONUS_POISE: float = 20.0
## The front cone is 120° wide: hits within 60° of the facing.
const FRONT_HALF_ANGLE_DEGREES: float = 60.0
## The counter-shove: telegraphed this long into the brace, for this long, this big.
const SHOVE_DELAY_S: float = 1.8
const SHOVE_WINDUP_S: float = 0.8
const SHOVE_RADIUS: float = 2.5
const SHOVE_DISTANCE: float = 3.0
const SHOVE_TIME: float = 0.25
const SHOVE_DAMAGE: float = 8.0
const BUCKLER_COLOR: Color = Color(1.0, 0.66, 0.2)
const TIMBER_COLOR: Color = Color(0.46, 0.31, 0.18)
const BRASS_COLOR: Color = Color(0.88, 0.68, 0.3)
const BUCKLER_PLANKS: int = 5
const DEFLECT_COLOR: Color = Color(0.72, 0.72, 0.74)

## The older smoke checks measure raw hits on a foe standing still; they turn
## this off, and the Phase 11 check turns it back on. The game never changes it.
static var enabled: bool = true

var actor: ActorBase
var is_braced: bool = false

var _frontal_hits: Array[float] = []
var _braced_left: float = 0.0
var _braced_for: float = 0.0
var _shove_cast: bool = false
var _buckler: Node3D


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "BracedGuard"


func _ready() -> void:
	actor.stats.poise_broken.connect(_on_poise_broken)


func _physics_process(delta: float) -> void:
	if not is_braced or not actor.is_multiplayer_authority():
		return
	_braced_left -= delta
	_braced_for += delta
	if actor.stats.is_downed or _braced_left <= 0.0:
		_lower()
		return
	if not _shove_cast and _braced_for >= SHOVE_DELAY_S:
		_shove_cast = true
		var center: Vector3 = actor.global_position + actor.facing_vector() * (actor.body_radius() + SHOVE_RADIUS * 0.5)
		_cast_shove(center)
		for peer_id: int in InstanceManager.current.live_remote_peers():
			_cast_shove.rpc_id(peer_id, center)


## Whether a point is on the guarded front: within 60° of where the enemy faces.
func is_front(point: Vector3) -> bool:
	var to_point: Vector3 = point - actor.global_position
	to_point.y = 0.0
	if to_point.length() < 0.01:
		return true
	return actor.facing_vector().dot(to_point.normalized()) >= cos(deg_to_rad(FRONT_HALF_ANGLE_DEGREES))


## On the owner, before the strike lands (ActorBase.receive_strike): counts
## frontal hits toward the brace, or applies the brace and the Flank Breach.
func filter_strike(event: CombatEvent) -> void:
	if not enabled or event.unavoidable or event.attacker_role == ClassLoadoutResource.Role.BOSS:
		return
	var front: bool = is_front(event.origin)
	if not is_braced:
		if front and (event.damage > 0.0 or event.poise_damage > 0.0):
			_count_frontal_hit()
		return
	if front:
		event.damage *= BRACED_FRONT_DAMAGE_MULT
		event.poise_damage *= TANK_GUARD_POISE_MULT if _cracks_guard(event) else BRACED_FRONT_POISE_MULT
		AudioCues.play_at(&"hit", actor.global_position, 0.55, -2.0)
		CombatDirector.current.show_float_text(_above(), "CLUNK", DEFLECT_COLOR, 30)
	elif breaks_flank(event):
		event.damage *= FLANK_BREACH_DAMAGE_MULT
		event.poise_damage += FLANK_BREACH_BONUS_POISE
		flank_breached.emit(event.attacker_player_id)
		CombatDirector.current.announce(_above() + Vector3.UP * 0.5, "FLANK BREACH!", BUCKLER_COLOR, &"knockdown")
		_lower()


## The moves that breach a flank: the directional Heavies, R and L+R.
static func breaks_flank(event: CombatEvent) -> bool:
	return event.command == CombatActionResource.Command.FORWARD_HEAVY or event.command == CombatActionResource.Command.BACK_HEAVY \
		or event.command == CombatActionResource.Command.TRIGGER_R_SKILL or event.command == CombatActionResource.Command.TRIGGER_BOTH_ULT


## A Shield-Sworn cracks the guard from the front with an Iron-Root strike, or with any strike as a +Tank.
func _cracks_guard(event: CombatEvent) -> bool:
	if event.attacker_role != ClassLoadoutResource.Role.TANK:
		return false
	if event.scribe_sign == ScribeSignResource.Sign.SIGN_IRON_ROOT or event.primer == ScribeSignResource.Sign.SIGN_IRON_ROOT:
		return true
	var attacker: ActorBase = CombatDirector.current.get_actor(event.attacker_player_id)
	return attacker != null and attacker.loadout.calling == Callings.Secondary.STOUT_HEART


func _count_frontal_hit() -> void:
	var now: float = CombatDirector.game_time()
	_frontal_hits.append(now)
	while not _frontal_hits.is_empty() and now - _frontal_hits[0] > BRACED_GUARD_WINDOW_S:
		_frontal_hits.pop_front()
	if _frontal_hits.size() >= BRACED_GUARD_HIT_THRESHOLD:
		_raise()


func _raise() -> void:
	_frontal_hits.clear()
	_braced_left = BRACED_GUARD_DURATION_S
	_braced_for = 0.0
	_shove_cast = false
	_share_braced(true)


func _lower() -> void:
	_braced_left = 0.0
	_frontal_hits.clear()
	_share_braced(false)


## A knockdown shatters the guard (the Shield-Sworn's way through the front).
func _on_poise_broken() -> void:
	if is_braced and actor.is_multiplayer_authority():
		_lower()


func _share_braced(on: bool) -> void:
	_set_braced(on)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_set_braced.rpc_id(peer_id, on)


@rpc("authority", "call_remote", "reliable")
func _set_braced(on: bool) -> void:
	if on == is_braced:
		return
	is_braced = on
	_show_buckler(on)
	if on:
		AudioCues.play(&"equip", 0.6)
		CombatDirector.current.show_float_text(_above(), "BRACED!", BUCKLER_COLOR, 34)
	braced_changed.emit(on)


## The red shield-shove circle in front of it, on every peer; the owner resolves it.
@rpc("authority", "call_remote", "reliable")
func _cast_shove(center: Vector3) -> void:
	var root: Node3D = CombatDirector.current.effects_root
	if root == null or not root.is_inside_tree():
		return
	var decal: RaidTelegraphDecal = RaidTelegraphDecal.new()
	decal.configure(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT, SHOVE_RADIUS, SHOVE_WINDUP_S, null)
	root.add_child(decal)
	decal.global_position = Vector3(center.x, actor.global_position.y, center.z)
	AudioCues.play(&"telegraph", 1.3)
	if actor.is_multiplayer_authority():
		decal.resolved.connect(_on_shove_resolved)


## Whoever still stands in the circle is shoved back, unless they shelter behind the tank's Shadow Sanctuary.
func _on_shove_resolved(_decal: RaidTelegraphDecal, inside: Array[ActorBase]) -> void:
	if actor.stats.is_downed:
		return
	var director: CombatDirector = CombatDirector.current
	for member: ActorBase in inside:
		if director.is_sheltered(member):
			director.show_cue(member, RaidTelegraphDecal.BLUE_COLOR, &"soak_ok")
			continue
		var event: CombatEvent = CombatEvent.new()
		event.kind = CombatEvent.Kind.STRIKE
		event.attacker_path = actor.get_path()
		event.target_path = member.get_path()
		event.attacker_player_id = actor.player_id
		event.attacker_role = actor.role()
		event.damage = SHOVE_DAMAGE
		event.hit_stop_scale = 0.5
		event.origin = actor.global_position
		event.unavoidable = true
		director.deliver(event)
		var away: Vector3 = member.global_position - actor.global_position
		away.y = 0.0
		away = away.normalized() if away.length() > 0.01 else actor.facing_vector()
		director.shove(member, member.global_position + away * SHOVE_DISTANCE, SHOVE_TIME)


func _above() -> Vector3:
	return actor.global_position + Vector3.UP * (actor.body_height() + 0.4)


## The amber timber-and-brass buckler arc across the front 120°, built the first time it's raised.
func _show_buckler(on: bool) -> void:
	if _buckler == null:
		_buckler = _build_buckler()
		actor.add_child(_buckler)
	_buckler.visible = on
	if on:
		_buckler.scale = Vector3.ONE * 0.6
		var pop: Tween = _buckler.create_tween()
		pop.tween_property(_buckler, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _build_buckler() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BracedBuckler"
	var radius: float = actor.body_radius() + 0.4
	var height: float = maxf(0.8, actor.body_height() * 0.6)
	var arc: float = deg_to_rad(FRONT_HALF_ANGLE_DEGREES * 2.0)
	var plank_width: float = radius * arc / BUCKLER_PLANKS * 1.08
	var timber: StandardMaterial3D = _material(TIMBER_COLOR, BUCKLER_COLOR, 0.9)
	var brass: StandardMaterial3D = _material(BRASS_COLOR, BUCKLER_COLOR, 1.6)
	for index: int in BUCKLER_PLANKS:
		# Planks round the front (-Z), from one edge of the cone to the other.
		var angle: float = -arc * 0.5 + arc * (index + 0.5) / BUCKLER_PLANKS
		var where: Vector3 = Vector3(sin(angle), 0.0, -cos(angle)) * radius
		var plank: MeshInstance3D = _box(Vector3(plank_width, height, 0.1), timber)
		plank.position = where + Vector3.UP * (height * 0.5 + 0.1)
		plank.rotation.y = -angle
		root.add_child(plank)
		for band_y: float in [0.22, 0.78]:
			var band: MeshInstance3D = _box(Vector3(plank_width * 1.02, 0.08, 0.13), brass)
			band.position = where + Vector3.UP * (height * band_y + 0.1)
			band.rotation.y = -angle
			root.add_child(band)
	return root


static func _box(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	box.material = material
	mesh.mesh = box
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


static func _material(color: Color, glow: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = glow
	material.emission_energy_multiplier = energy * 0.5
	return material
