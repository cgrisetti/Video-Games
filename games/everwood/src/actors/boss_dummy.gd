## The Dojo Warden: the first raid boss, a training dummy that fights back.
##
## - Chases whoever tops its aggro table (ThreatComponent) and swings a
##   Crushing Swipe with a long, readable wind-up.
## - Every few seconds it casts a raid telegraph, alternating:
##     Crimson Bloom     (CRIMSON_DODGE_OUT) a red puddle under every player: get out
##     Golden Communion  (GOLD_PARTY_SOAK)   a gold circle on one player: stack in to share it
## - Heavy hits and Perfect Guards drain its poise; at zero it's knocked down for 5 s.
## - Defeated, it stays down and signals `defeated`: the dojo plays the victory
##   and drops a reward chest (DungeonDojo).
##
## The host simulates the boss; other peers see a synced copy and the same telegraphs.
class_name BossDummy
extends ActorBase

signal cast_started(cast_name: String, duration: float)
## Health reached zero (on the host, which simulates the boss).
signal defeated

const DISPLAY_NAME: String = "Dojo Warden"
## Health scales with the party when a fight starts: base + per player.
const HEALTH_BASE: float = 900.0
const HEALTH_PER_PLAYER: float = 500.0
const BOSS_RADIUS: float = 1.2
const BOSS_HEIGHT: float = 3.6
## Players this close draw it into the fight.
const AGGRO_RADIUS: float = 16.0
## Players further than this from its spawn point can't hold it (it resets).
const LEASH_RADIUS: float = 30.0
const BODY_PULL_THREAT: float = 1.0
const MELEE_RANGE: float = 3.4
const SWIPE_COOLDOWN: float = 2.8
## The swipe starts only when the boss is roughly facing its target.
const SWIPE_FACING_DOT: float = 0.8
const FIRST_CAST_DELAY: float = 8.0
const CAST_INTERVAL: float = 10.0
const CRIMSON_NAME: String = "Crimson Bloom"
const CRIMSON_RADIUS: float = 3.5
const CRIMSON_CAST_TIME: float = 3.0
const CRIMSON_DAMAGE: float = 35.0
const SOAK_NAME: String = "Golden Communion"
const SOAK_RADIUS: float = 3.2
const SOAK_CAST_TIME: float = 4.0
const SOAK_TOTAL_DAMAGE: float = 90.0
const SOAK_FAIL_DAMAGE: float = 30.0
## A soak needs this many players inside (or the whole party, if smaller).
const SOAK_REQUIRED_PLAYERS: int = 2
const WINDUP_GLOW: Color = Color(1.0, 0.25, 0.1)

## Where telegraph decals are spawned (the level sets this).
var telegraphs_root: Node3D
var cast_name: String = ""
var cast_duration: float = 0.0
var cast_started_at: float = -1.0
var engaged: bool = false
## Beaten for good: it stays down until the party leaves the instance.
var vanquished: bool = false

var _cast_timer: float = FIRST_CAST_DELAY
var _next_cast: RaidTelegraphDecal.Kind = RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT
var _swipe_cooldown: float = 0.0


func body_radius() -> float:
	return BOSS_RADIUS


func body_height() -> float:
	return BOSS_HEIGHT


func display_name() -> String:
	return DISPLAY_NAME


func _build_components() -> void:
	super._build_components()
	threat = ThreatComponent.new()
	threat.name = "ThreatComponent"
	add_child(threat)
	stats.poise_broken.connect(_on_boss_poise_broken)
	stats.downed.connect(_on_boss_defeated)


func _build_visual() -> void:
	super._build_visual()
	# The HUD's boss bar already names it; a floating tag would cover the aggro line.
	_name_label.visible = false


## Horns and a glowing visor on the greybox body.
func _build_prop() -> Node3D:
	var prop: Node3D = Node3D.new()
	prop.name = "Prop"
	for side: float in [-1.0, 1.0]:
		var horn: MeshInstance3D = MeshInstance3D.new()
		var horn_mesh: CylinderMesh = CylinderMesh.new()
		horn_mesh.top_radius = 0.02
		horn_mesh.bottom_radius = 0.18
		horn_mesh.height = 1.0
		horn_mesh.material = _flat_material(Color(0.85, 0.8, 0.7))
		horn.mesh = horn_mesh
		horn.position = Vector3(side * 0.7, BOSS_HEIGHT + 0.1, 0.0)
		horn.rotation = Vector3(0.0, 0.0, -side * 0.5)
		prop.add_child(horn)
	var visor: MeshInstance3D = MeshInstance3D.new()
	var visor_mesh: BoxMesh = BoxMesh.new()
	visor_mesh.size = Vector3(1.3, 0.22, 0.2)
	var glow: StandardMaterial3D = _flat_material(Color(1.0, 0.3, 0.2))
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.25, 0.15)
	glow.emission_energy_multiplier = 3.0
	visor_mesh.material = glow
	visor.mesh = visor_mesh
	visor.position = Vector3(0.0, BOSS_HEIGHT * 0.8, -BOSS_RADIUS * 0.85)
	prop.add_child(visor)
	return prop


## The boss locks onto whoever tops its aggro table.
func soft_target() -> ActorBase:
	if threat == null or threat.current_target == &"":
		return null
	var target: ActorBase = CombatDirector.current.get_actor(threat.current_target)
	return target if target != null and not target.stats.is_downed else null


func is_casting() -> bool:
	return cast_started_at >= 0.0 and cast_progress() < 1.0


func cast_progress() -> float:
	if cast_started_at < 0.0 or cast_duration <= 0.0:
		return 1.0
	return clampf((CombatDirector.game_time() - cast_started_at) / cast_duration, 0.0, 1.0)


# --- AI (runs only on the boss's owner) ------------------------------------

func _gather_intent(delta: float) -> void:
	move_intent = Vector3.ZERO
	wants_guard = false
	threat.tick(delta)
	if not can_act():
		return
	var eligible: Array[StringName] = _eligible_targets()
	if eligible.is_empty():
		if engaged:
			_reset_fight()
		return
	if not engaged:
		var nearest: ActorBase = _nearest_player(eligible, AGGRO_RADIUS)
		if nearest == null:
			return
		threat.add_threat(nearest.player_id, BODY_PULL_THREAT)
		engaged = true
		_cast_timer = FIRST_CAST_DELAY
		scale_health_to_party(CombatDirector.current.party_actors().size())
	var target_id: StringName = threat.top_target(eligible)
	if target_id == &"":
		var nearest_any: ActorBase = _nearest_player(eligible, INF)
		threat.add_threat(nearest_any.player_id, BODY_PULL_THREAT)
		target_id = threat.top_target(eligible)
	var target: ActorBase = CombatDirector.current.get_actor(target_id)
	if target == null:
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	if is_casting():
		turn_toward(to_target, loadout.stats.turn_speed * 0.5 * delta)
		return
	_cast_timer -= delta
	_swipe_cooldown -= delta
	if action_queue.is_busy():
		return
	if _cast_timer <= 0.0:
		_begin_cast()
		return
	if to_target.length() > MELEE_RANGE - 0.4:
		move_intent = to_target.normalized()
	else:
		turn_toward(to_target, loadout.stats.turn_speed * delta)
		if _swipe_cooldown <= 0.0 and facing_vector().dot(to_target.normalized()) >= SWIPE_FACING_DOT:
			_swipe_cooldown = SWIPE_COOLDOWN
			action_queue.request(CombatActionResource.Command.LIGHT)


func _eligible_targets() -> Array[StringName]:
	var ids: Array[StringName] = []
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.global_position.distance_to(spawn_transform.origin) <= LEASH_RADIUS:
			ids.append(member.player_id)
	return ids


func _nearest_player(ids: Array[StringName], within: float) -> ActorBase:
	var best: ActorBase = null
	var best_distance: float = within
	for player_id: StringName in ids:
		var member: ActorBase = CombatDirector.current.get_actor(player_id)
		if member == null:
			continue
		var distance: float = member.global_position.distance_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best = member
	return best


func _begin_cast() -> void:
	var kind: RaidTelegraphDecal.Kind = _next_cast
	_next_cast = RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK if kind == RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT else RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT
	_cast_timer = CAST_INTERVAL
	var alive: Array[ActorBase] = CombatDirector.current.alive_party()
	if alive.is_empty():
		return
	var centers: PackedVector3Array = PackedVector3Array()
	var follow_id: String = ""
	if kind == RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT:
		for member: ActorBase in alive:
			centers.append(member.global_position)
	else:
		var chosen: ActorBase = alive[randi() % alive.size()]
		centers.append(chosen.global_position)
		follow_id = String(chosen.player_id)
	_cast_telegraphs(kind, centers, follow_id)
	# Only peers that have this instance loaded have a boss to receive it.
	for peer_id: int in InstanceManager.current.live_remote_peers():
		_cast_telegraphs.rpc_id(peer_id, kind, centers, follow_id)


## Runs on every peer so everyone sees the same decals; only the owner resolves damage.
@rpc("authority", "call_local", "reliable")
func _cast_telegraphs(kind: int, centers: PackedVector3Array, follow_id: String) -> void:
	var crimson: bool = kind == RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT
	cast_name = CRIMSON_NAME if crimson else SOAK_NAME
	cast_duration = CRIMSON_CAST_TIME if crimson else SOAK_CAST_TIME
	cast_started_at = CombatDirector.game_time()
	cast_started.emit(cast_name, cast_duration)
	AudioCues.play(&"telegraph", 1.0 if crimson else 0.8)
	if telegraphs_root == null:
		return
	var follow: ActorBase = CombatDirector.current.get_actor(StringName(follow_id)) if follow_id != "" else null
	for center: Vector3 in centers:
		var decal: RaidTelegraphDecal = RaidTelegraphDecal.new()
		decal.configure(kind as RaidTelegraphDecal.Kind, CRIMSON_RADIUS if crimson else SOAK_RADIUS, cast_duration, follow)
		telegraphs_root.add_child(decal)
		decal.global_position = Vector3(center.x, 0.0, center.z)
		if is_multiplayer_authority():
			decal.resolved.connect(_on_telegraph_resolved)


func _on_telegraph_resolved(decal: RaidTelegraphDecal, inside: Array[ActorBase]) -> void:
	if vanquished:
		return
	if decal.kind == RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT:
		for member: ActorBase in inside:
			CombatDirector.current.deliver(_telegraph_strike(member, CRIMSON_DAMAGE))
		return
	var alive: Array[ActorBase] = CombatDirector.current.alive_party()
	var required: int = mini(SOAK_REQUIRED_PLAYERS, alive.size())
	if not inside.is_empty() and inside.size() >= required:
		var share: float = SOAK_TOTAL_DAMAGE / inside.size()
		for member: ActorBase in inside:
			CombatDirector.current.deliver(_telegraph_strike(member, share))
		CombatDirector.current.announce(decal.global_position + Vector3.UP * 2.0, "Soaked! %d each" % roundi(share), RaidTelegraphDecal.GOLD_COLOR, &"soak_ok")
	else:
		for member: ActorBase in alive:
			CombatDirector.current.deliver(_telegraph_strike(member, SOAK_FAIL_DAMAGE))
		CombatDirector.current.announce(decal.global_position + Vector3.UP * 2.0, "Soak failed! Stack in the gold", Color(1.0, 0.4, 0.3), &"soak_fail")


## Telegraph damage depends only on where you stand: guards and rolls don't stop it.
func _telegraph_strike(target: ActorBase, damage: float) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.STRIKE
	event.attacker_path = get_path()
	event.target_path = target.get_path()
	event.attacker_player_id = player_id
	event.attacker_role = role()
	event.damage = damage
	event.hit_stop_scale = 0.5
	event.origin = global_position
	event.unavoidable = true
	return event


func _on_boss_poise_broken() -> void:
	CombatDirector.current.announce(global_position + Vector3.UP * (BOSS_HEIGHT + 1.0), "KNOCKDOWN!  x%.2f damage" % stats.stats.knockdown_damage_taken, Color(1.0, 0.85, 0.3), &"knockdown")


func _on_boss_defeated() -> void:
	mark_vanquished()
	CombatDirector.current.announce(global_position + Vector3.UP * (BOSS_HEIGHT + 1.0), "%s defeated!" % DISPLAY_NAME, Color(1.0, 0.95, 0.6))
	defeated.emit()


## Every peer calls this when the boss falls: no more casts, and players can
## walk over its body to reach the chest.
func mark_vanquished() -> void:
	vanquished = true
	cast_started_at = -1.0
	collision_layer = 0


## A beaten boss never gets up again in this instance.
func downed_duration() -> float:
	return INF


## Sets max health for a party of `players` (at full health, so only between fights).
func scale_health_to_party(players: int) -> void:
	stats.stats.max_health = HEALTH_BASE + HEALTH_PER_PLAYER * maxi(1, players)
	stats.health = stats.stats.max_health
	stats.health_changed.emit(stats.health, stats.stats.max_health)


## Back to the start: full health and poise, an empty aggro table, home spot.
func _reset_fight() -> void:
	engaged = false
	threat.clear()
	cast_started_at = -1.0
	_cast_timer = FIRST_CAST_DELAY
	_next_cast = RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT
	stats.heal(stats.stats.max_health)
	stats.poise = stats.stats.max_poise
	stats.poise_changed.emit(stats.poise, stats.stats.max_poise)
	place_at(spawn_transform)


func _update_pose(delta: float) -> void:
	super._update_pose(delta)
	# The visor and body glow hotter through the swipe's wind-up: a readable tell.
	if action_queue.phase == ActionQueueComponent.Phase.WINDUP and _flash_left <= 0.0:
		_body_material.emission = WINDUP_GLOW * action_queue.progress() * 2.0
