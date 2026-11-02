## A wild creature of the starting zone (13_STARTING_ZONE_ENCOUNTER_DESIGN.md),
## played from its MobVariantResource (Bestiary): a boar, a scuttler, a wolf, a
## toad, an outlaw, a vine, a shambler, a bog-hulk, a wight or the Crag-Back
## Behemoth, each built in code from simple shapes in the storybook look.
##
## It keeps to its MobSpawner. A hostile one turns on any player within its
## aggro radius; a neutral one (the meadow vermin) only fights back once hurt;
## one in a fight calls its pack. Past the spawner's leash (18–25 m) it gives
## up, walks home and mends. A rooted vine never moves; a ranged one keeps its
## distance and looses shots that boulders stop; the Behemoth walks its patrol
## round the High Road with a heavy bell-stomp. The host runs it; other peers
## see a copy. When it falls it fades, and its spawner grows another later.
class_name WildMob
extends ActorBase

const FACING_DOT: float = 0.75
const HOME_RADIUS: float = 0.8
const FADE_TIME: float = 1.2
const WANDER_RADIUS: float = 4.5
const WANDER_PAUSE: Vector2 = Vector2(4.0, 7.0)
const BAR_DOTS: int = 6
const BAR_COLOR: Color = Color(1.0, 0.45, 0.4)
## Neutral creatures' dots are yellow until they're riled.
const NEUTRAL_BAR_COLOR: Color = Color(1.0, 0.86, 0.35)
## A ranged creature shoots from this share of its range.
const RANGED_KEEP: float = 0.7
## The Behemoth's stomp: every this many seconds while it walks, heard within this many metres.
const STOMP_EVERY: float = 1.1
const STOMP_HEARD: float = 45.0

var variant: MobVariantResource
## The spawner it belongs to (set before it enters the tree).
var spawner: MobSpawner
## In a fight right now.
var engaged: bool = false

var _attack_cooldown: float = 0.0
var _fade_left: float = -1.0
var _bar: Label3D
var _legs: Array[Node3D] = []
var _nav: NavSteering = NavSteering.new()
var _wander_target: Vector3 = Vector3.ZERO
var _wander_left: float = 0.0
var _patrol_index: int = 0
## Where it turned to fight (a patroller's leash is measured from here).
var _anchor: Vector3 = Vector3.ZERO
var _stomp_left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func body_radius() -> float:
	return variant.radius


func body_height() -> float:
	return variant.height


func display_name() -> String:
	match variant.rank:
		MobVariantResource.Rank.RARE:
			return "%s (Rare)" % variant.display_name
		MobVariantResource.Rank.ELITE:
			return "%s (Elite)" % variant.display_name
	return variant.display_name


func is_engaged() -> bool:
	return engaged and not stats.is_downed


## Fallen creatures stay down; their spawner grows a fresh one.
func downed_duration() -> float:
	return INF


## The trail pays a mini-boss like a boss.
func trail_xp() -> int:
	return PartyProgress.XP_PER_BOSS if variant.rank == MobVariantResource.Rank.BOSS else PartyProgress.XP_PER_MOB


## Its shots and swings lean toward whoever it's fighting.
func soft_target() -> ActorBase:
	if threat == null:
		return null
	var top: StringName = threat.current_target
	return CombatDirector.current.get_actor(top) if top != &"" else null


func _build_components() -> void:
	super._build_components()
	threat = ThreatComponent.new()
	threat.name = "ThreatComponent"
	add_child(threat)
	_rng.seed = hash(String(player_id))


func _build_visual() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	_body_material = StorybookMaterial.actor(variant.main_color, variant.eye_color)
	var dropped: Node3D = ActorVisuals.load_model(variant.variant_id)
	if dropped != null:
		visual.add_child(dropped)
	else:
		_build_creature()
	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.visible = variant.rank != MobVariantResource.Rank.COMMON
	_name_label.text = display_name()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.font_size = 34
	_name_label.outline_size = 9
	_name_label.pixel_size = 0.007
	_name_label.modulate = variant.eye_color.lightened(0.3)
	_name_label.position = Vector3(0.0, body_height() + 0.75, 0.0)
	add_child(_name_label)
	_bar = Label3D.new()
	_bar.name = "HealthDots"
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.no_depth_test = true
	_bar.font_size = 32
	_bar.outline_size = 8
	_bar.pixel_size = 0.006
	_bar.position = Vector3(0.0, body_height() + 0.35, 0.0)
	add_child(_bar)


# --- AI (the host runs it) -----------------------------------------------------

func _gather_intent(delta: float) -> void:
	move_intent = Vector3.ZERO
	wants_guard = false
	threat.tick(delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if not can_act() or spawner == null:
		return
	var home: Vector3 = _anchor if variant.patrols else spawn_transform.origin
	_update_engagement(home)
	if not engaged:
		_idle(delta, home)
		return
	var target: ActorBase = _pick_target(home)
	if target == null:
		engaged = false
		return
	threat.add_threat(target.player_id, 0.0)
	if action_queue.is_busy():
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	var reach: float = variant.projectile_range * RANGED_KEEP if variant.ranged \
		else variant.reach + variant.hit_radius * 0.6 + body_radius() + target.body_radius() * 0.5
	if distance > reach and not variant.rooted:
		move_intent = _nav.direction(self, target.global_position, delta)
		_stomp(delta)
		return
	if variant.ranged and distance < reach * 0.45 and not variant.rooted:
		# Too close: step back to shooting range.
		move_intent = -to_target.normalized()
	turn_toward(to_target, loadout.stats.turn_speed * delta)
	if distance <= reach + 0.2 and _attack_cooldown <= 0.0 and facing_vector().dot(to_target.normalized()) >= FACING_DOT:
		_attack_cooldown = variant.cooldown
		action_queue.request(CombatActionResource.Command.LIGHT)


## Hostile ones turn on a player in their aggro radius; any turns on a player
## once hurt or once its pack is fighting. Nobody within the leash: home again.
func _update_engagement(home: Vector3) -> void:
	var near_home: bool = false
	var in_aggro: bool = false
	for member: ActorBase in CombatDirector.current.alive_party():
		if _flat_distance(member.global_position, home) <= spawner.leash:
			near_home = true
			if variant.aggro_radius > 0.0 and _flat_distance(member.global_position, global_position) <= variant.aggro_radius:
				in_aggro = true
	if not near_home:
		if engaged:
			engaged = false
			threat.clear()
		return
	var hurt: bool = stats.health < stats.stats.max_health - 0.5
	if not engaged and (in_aggro or hurt or spawner.alert):
		engaged = true
		_anchor = global_position if variant.patrols else spawn_transform.origin


func _pick_target(home: Vector3) -> ActorBase:
	var eligible: Array[StringName] = []
	var nearest: ActorBase = null
	var nearest_distance: float = INF
	for member: ActorBase in CombatDirector.current.alive_party():
		if _flat_distance(member.global_position, home) > spawner.leash:
			continue
		eligible.append(member.player_id)
		var distance: float = _flat_distance(member.global_position, global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = member
	var top: StringName = threat.top_target(eligible)
	var chosen: ActorBase = CombatDirector.current.get_actor(top) if top != &"" else null
	return chosen if chosen != null else nearest


## Out of a fight: walk home and mend, then wander near it (a patroller walks its round).
func _idle(delta: float, home: Vector3) -> void:
	if variant.rooted:
		if stats.health < stats.stats.max_health:
			stats.heal(stats.stats.max_health)
		return
	if variant.patrols and spawner.patrol.size() >= 2:
		var stop: Vector3 = spawner.patrol[_patrol_index % spawner.patrol.size()]
		var to_stop: Vector3 = stop - global_position
		to_stop.y = 0.0
		if to_stop.length() < 2.0:
			_patrol_index += 1
		else:
			move_intent = _nav.direction(self, stop, delta) * 0.6
			_stomp(delta)
		_anchor = global_position
		if stats.health < stats.stats.max_health:
			stats.heal(stats.stats.max_health * 0.05 * delta)
		return
	var to_home: Vector3 = home - global_position
	to_home.y = 0.0
	if to_home.length() > WANDER_RADIUS + 2.0:
		move_intent = _nav.direction(self, home, delta) * clampf(to_home.length(), 0.4, 1.0)
		return
	if stats.health < stats.stats.max_health:
		stats.heal(stats.stats.max_health)
		threat.clear()
	_wander_left -= delta
	if _wander_left <= 0.0:
		_wander_left = _rng.randf_range(WANDER_PAUSE.x, WANDER_PAUSE.y)
		var angle: float = _rng.randf() * TAU
		_wander_target = home + Vector3(cos(angle), 0.0, sin(angle)) * _rng.randf_range(0.5, WANDER_RADIUS)
	var to_wander: Vector3 = _wander_target - global_position
	to_wander.y = 0.0
	if to_wander.length() > 0.6 and _wander_left < WANDER_PAUSE.x - 1.0:
		move_intent = to_wander.normalized() * 0.35


## The Behemoth's footfalls: a deep bell-stomp, heard by anyone near.
func _stomp(delta: float) -> void:
	if not variant.stomps:
		return
	_stomp_left -= delta
	if _stomp_left > 0.0:
		return
	_stomp_left = STOMP_EVERY
	var nearest: float = INF
	for member: ActorBase in CombatDirector.current.party_actors():
		if member.is_local_player():
			nearest = minf(nearest, global_position.distance_to(member.global_position))
	if nearest <= STOMP_HEARD:
		AudioCues.play(&"bell", 0.42, lerpf(-2.0, -22.0, nearest / STOMP_HEARD))


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- Look ------------------------------------------------------------------------

func _update_pose(delta: float) -> void:
	super._update_pose(delta)
	var ratio: float = stats.health_ratio()
	_bar.visible = not stats.is_downed and (is_engaged() or ratio < 1.0 or variant.aggro_radius <= 0.0)
	if _bar.visible:
		var lit: int = ceili(ratio * BAR_DOTS)
		_bar.text = "●".repeat(lit) + "○".repeat(BAR_DOTS - lit)
		_bar.modulate = NEUTRAL_BAR_COLOR if variant.aggro_radius <= 0.0 and not is_engaged() else BAR_COLOR
	var stride: float = sin(Time.get_ticks_msec() * 0.02) * 0.4 if Vector2(velocity.x, velocity.z).length() > 0.3 else 0.0
	for index: int in _legs.size():
		_legs[index].rotation.x = stride * (1.0 if index % 2 == 0 else -1.0)
	if stats.is_downed:
		if _fade_left < 0.0:
			_fade_left = FADE_TIME
			collision_layer = 0
			hurtbox.collision_layer = 0
			_name_label.visible = false
		_fade_left = maxf(0.0, _fade_left - delta)
		visual.scale = Vector3.ONE * maxf(0.05, _fade_left / FADE_TIME)
		visual.position.y = -0.4 * (1.0 - _fade_left / FADE_TIME)
		if _fade_left <= 0.0:
			visual.visible = false


## Whether its fall has finished fading (its spawner may clear it away).
func has_faded() -> bool:
	return stats.is_downed and _fade_left == 0.0


# --- Bodies ----------------------------------------------------------------------

func _build_creature() -> void:
	var r: float = variant.radius
	var h: float = variant.height
	var accent: Material = _flat_material(variant.accent_color)
	match variant.body:
		MobVariantResource.Body.BOAR:
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", r, Vector3(0.0, h * 0.55, 0.1), _body_material), Vector3(1.0, 0.85, 1.5)))
			visual.add_child(ShapeKit.sphere("Head", r * 0.6, Vector3(0.0, h * 0.55, -r * 1.25), _body_material))
			visual.add_child(ShapeKit.cylinder("Snout", r * 0.25, r * 0.3, r * 0.4, Vector3(0.0, h * 0.5, -r * 1.75), accent, 8))
			for side: float in [-1.0, 1.0]:
				visual.add_child(ShapeKit.tilted(ShapeKit.cone("Tusk", r * 0.08, r * 0.5, Vector3(side * r * 0.28, h * 0.42, -r * 1.7), accent), Vector3(-1.2, 0.0, side * 0.4)))
			visual.add_child(ShapeKit.box("Bristles", Vector3(r * 0.25, r * 0.3, r * 1.8), Vector3(0.0, h * 0.55 + r * 0.8, 0.1), accent))
			_add_legs(4, r * 0.55, r * 0.7, h * 0.45, accent)
			_add_eyes(Vector3(r * 0.25, h * 0.66, -r * 1.65), r * 0.1)
		MobVariantResource.Body.SCUTTLER:
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", r, Vector3(0.0, h * 0.55, 0.0), _body_material), Vector3(1.0, 0.7, 1.2)))
			for index: int in 8:
				var angle: float = TAU * index / 8.0
				visual.add_child(ShapeKit.tilted(ShapeKit.cone("Thorn%d" % index, r * 0.12, r * 0.55, Vector3(cos(angle) * r * 0.8, h * 0.7, sin(angle) * r * 0.9), accent),
					Vector3(sin(angle) * 0.8, 0.0, -cos(angle) * 0.8)))
			visual.add_child(ShapeKit.tilted(ShapeKit.cone("Tail", r * 0.18, r * 1.4, Vector3(0.0, h * 0.75, r * 1.3), accent), Vector3(1.0, 0.0, 0.0)))
			_add_legs(6, r * 0.6, r * 0.6, h * 0.45, accent)
			_add_eyes(Vector3(r * 0.25, h * 0.66, -r * 0.95), r * 0.13)
		MobVariantResource.Body.WOLF:
			visual.add_child(ShapeKit.tilted(ShapeKit.capsule("Body", r * 0.55, r * 2.4, Vector3(0.0, h * 0.62, 0.0), _body_material), Vector3(PI * 0.5, 0.0, 0.0)))
			visual.add_child(ShapeKit.sphere("Head", r * 0.45, Vector3(0.0, h * 0.82, -r * 1.35), _body_material))
			visual.add_child(ShapeKit.tilted(ShapeKit.cone("Muzzle", r * 0.22, r * 0.55, Vector3(0.0, h * 0.76, -r * 1.75), accent), Vector3(-PI * 0.5, 0.0, 0.0)))
			for side: float in [-1.0, 1.0]:
				visual.add_child(ShapeKit.cone("Ear", r * 0.12, r * 0.35, Vector3(side * r * 0.25, h * 1.02, -r * 1.3), accent))
			visual.add_child(ShapeKit.tilted(ShapeKit.cone("Tail", r * 0.16, r * 1.1, Vector3(0.0, h * 0.7, r * 1.5), accent), Vector3(1.2, 0.0, 0.0)))
			_add_legs(4, r * 0.4, r * 0.8, h * 0.5, accent)
			_add_eyes(Vector3(r * 0.18, h * 0.88, -r * 1.7), r * 0.08)
		MobVariantResource.Body.TOAD:
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", r, Vector3(0.0, h * 0.45, 0.0), _body_material), Vector3(1.25, 0.7, 1.1)))
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Belly", r * 0.8, Vector3(0.0, h * 0.35, -r * 0.2), accent), Vector3(1.2, 0.6, 1.0)))
			visual.add_child(ShapeKit.box("Jaw", Vector3(r * 1.4, r * 0.18, r * 0.4), Vector3(0.0, h * 0.38, -r * 0.95), accent))
			for side: float in [-1.0, 1.0]:
				visual.add_child(ShapeKit.sphere("EyeBump", r * 0.28, Vector3(side * r * 0.5, h * 0.82, -r * 0.6), _body_material))
				visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Haunch", r * 0.42, Vector3(side * r * 0.9, h * 0.3, r * 0.4), _body_material), Vector3(1.0, 0.8, 1.4)))
			_add_eyes(Vector3(r * 0.5, h * 0.9, -r * 0.78), r * 0.12)
		MobVariantResource.Body.HUMANOID:
			_build_biped(r, h, accent, false)
		MobVariantResource.Body.WIGHT:
			_build_biped(r, h, accent, true)
		MobVariantResource.Body.VINE:
			var thorn: Material = _flat_material(variant.accent_color.darkened(0.2))
			for index: int in 5:
				var lean: Vector3 = Vector3(sin(index * 1.3) * 0.25, 0.0, cos(index * 1.7) * 0.25)
				var stalk: MeshInstance3D = ShapeKit.cylinder("Stalk%d" % index, r * 0.12, r * 0.3, h * (0.7 + 0.08 * index), Vector3(lean.x, h * 0.4, lean.z), _body_material, 6)
				stalk.rotation = Vector3(lean.z * 1.4, 0.0, -lean.x * 1.4)
				visual.add_child(stalk)
			visual.add_child(ShapeKit.sphere("Bloom", r * 0.55, Vector3(0.0, h * 0.95, 0.0), accent))
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Roots", r * 1.2, Vector3(0.0, 0.1, 0.0), thorn), Vector3(1.0, 0.25, 1.0)))
			_add_eyes(Vector3(r * 0.2, h * 0.98, -r * 0.48), r * 0.1)
		MobVariantResource.Body.SHAMBLER:
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", r, Vector3(0.0, h * 0.5, 0.0), _body_material), Vector3(1.0, 1.15, 0.95)))
			for index: int in 6:
				var angle: float = TAU * index / 6.0
				visual.add_child(ShapeKit.sphere("Puff%d" % index, r * 0.32, Vector3(cos(angle) * r * 0.75, h * 0.85, sin(angle) * r * 0.7), accent))
			visual.add_child(ShapeKit.sphere("Cap", r * 0.6, Vector3(0.0, h * 1.0, 0.0), accent))
			_add_legs(2, r * 0.4, r * 0.5, h * 0.35, _body_material)
			_add_eyes(Vector3(r * 0.25, h * 0.62, -r * 0.92), r * 0.1)
		MobVariantResource.Body.HULK:
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", r, Vector3(0.0, h * 0.55, 0.0), _body_material), Vector3(1.1, 1.1, 0.9)))
			visual.add_child(ShapeKit.sphere("Head", r * 0.45, Vector3(0.0, h * 0.95, -r * 0.35), _body_material))
			for side: float in [-1.0, 1.0]:
				var arm: MeshInstance3D = ShapeKit.capsule("Arm", r * 0.28, h * 0.7, Vector3(side * r * 1.05, h * 0.45, -r * 0.1), accent)
				arm.rotation.z = side * 0.25
				visual.add_child(arm)
				visual.add_child(ShapeKit.sphere("Fist", r * 0.32, Vector3(side * r * 1.15, h * 0.12, -r * 0.15), accent))
			for index: int in 7:
				var angle: float = TAU * index / 7.0
				visual.add_child(ShapeKit.box("Moss%d" % index, Vector3(r * 0.4, r * 0.15, r * 0.4), Vector3(cos(angle) * r * 0.7, h * 0.8, sin(angle) * r * 0.6), accent))
			_add_legs(2, r * 0.45, r * 0.6, h * 0.35, accent)
			_add_eyes(Vector3(r * 0.16, h * 1.0, -r * 0.75), r * 0.08)
		_:
			# The Crag-Back Behemoth: a great grey shell of stacked crag on four columns, moss on its back.
			visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Shell", r, Vector3(0.0, h * 0.62, 0.0), _body_material), Vector3(1.15, 0.8, 1.45)))
			for index: int in 6:
				var along: float = float(index) / 5.0 - 0.5
				visual.add_child(ShapeKit.box("Crag%d" % index, Vector3(r * 0.55, r * 0.5, r * 0.45), Vector3(sin(index * 2.1) * r * 0.35, h * 0.95 + r * 0.15, along * r * 2.2), accent))
			visual.add_child(ShapeKit.sphere("Head", r * 0.45, Vector3(0.0, h * 0.55, -r * 1.55), _body_material))
			visual.add_child(ShapeKit.torus("Bell", r * 0.18, r * 0.28, Vector3(0.0, h * 0.32, -r * 1.65), _flat_material(Color(0.82, 0.64, 0.3))))
			_add_legs(4, r * 0.7, r * 0.9, h * 0.55, _body_material)
			_add_eyes(Vector3(r * 0.2, h * 0.62, -r * 1.95), r * 0.09)


## An outlaw (a hood and a sling or cudgel) or a wight (a tarnished helm, a shield and a pale glow).
func _build_biped(r: float, h: float, accent: Material, wight: bool) -> void:
	visual.add_child(ShapeKit.cylinder("Torso", r * 0.75, r * 0.95, h * 0.42, Vector3(0.0, h * 0.58, 0.0), _body_material, 10))
	visual.add_child(ShapeKit.sphere("Head", r * 0.48, Vector3(0.0, h * 0.88, 0.0), _flat_material(variant.main_color.lightened(0.25) if wight else Color(0.9, 0.76, 0.62))))
	if wight:
		visual.add_child(ShapeKit.cylinder("Helm", r * 0.5, r * 0.55, r * 0.4, Vector3(0.0, h * 0.95, 0.0), accent, 10))
		visual.add_child(ShapeKit.box("Shield", Vector3(r * 0.15, h * 0.4, r * 1.1), Vector3(-r * 1.0, h * 0.52, -r * 0.2), accent))
	else:
		visual.add_child(ShapeKit.tilted(ShapeKit.cone("Hood", r * 0.55, r * 0.8, Vector3(0.0, h * 0.98, 0.05), accent), Vector3(-0.2, 0.0, 0.0)))
	visual.add_child(ShapeKit.box("Weapon", Vector3(r * 0.16, r * 0.16, h * 0.45), Vector3(r * 0.95, h * 0.55, -r * 0.6), accent))
	_add_legs(2, r * 0.4, r * 0.3, h * 0.4, _body_material)
	_add_eyes(Vector3(r * 0.18, h * 0.9, -r * 0.42), r * 0.08)


func _add_legs(count: int, spread: float, along: float, length: float, material: Material) -> void:
	for index: int in count:
		@warning_ignore("integer_division")
		var pair: int = index / 2
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var rows: int = maxi(1, ceili(count / 2.0))
		var z: float = (float(pair) / maxf(1.0, rows - 1.0) - 0.5) * along * 2.0 if rows > 1 else 0.0
		var leg: Node3D = Node3D.new()
		leg.name = "Leg%d" % index
		leg.position = Vector3(side * spread, length, z)
		leg.add_child(ShapeKit.cylinder("Bone", length * 0.14, length * 0.12, length, Vector3(0.0, -length * 0.5, 0.0), material, 6))
		visual.add_child(leg)
		_legs.append(leg)


func _add_eyes(right_eye: Vector3, size: float) -> void:
	var glow: StandardMaterial3D = StorybookMaterial.glowing(variant.eye_color, 2.0)
	for side: float in [-1.0, 1.0]:
		visual.add_child(ShapeKit.sphere("Eye", size, Vector3(right_eye.x * side, right_eye.y, right_eye.z), glow))
