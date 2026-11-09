## A spirit of the starting zone (13_STARTING_ZONE_ENCOUNTER_DESIGN.md), a kin of
## the First-Quiet (15_THE_MYTHOPOETIC_LENS.md), played from its MobVariantResource
## (Bestiary): a bristle-hob, a hedgerow-hob, a padfoot, a puddle-bucca, an
## Iron-Man, a bramble-lasher, a spore-puff lob, a bog-hulk, a spriggan or the
## Crag-Back Cairn-Drake, each a sculpted, skinned and animated KinFigure in the
## storybook look (docs/30_KIN_DESIGN_LANGUAGE.md), or a dropped-in model.
##
## It keeps to its MobSpawner. An awake one turns on any player within its
## aggro radius; a curious hob (HobSpectrumComponent) only fights back once
## wronged, and a soothed one keeps out of its pack's fights; one in a fight
## calls its pack. Past the spawner's leash (18–25 m) it gives up, walks home
## and mends. A rooted lasher never moves; a ranged one keeps its distance and
## looses shots that boulders stop; the Cairn-Drake walks its patrol round the
## High Road with a heavy bell-stomp and holds its first blow through its
## Challenge-Roar. The host runs it; other peers see a copy. Beaten, it's
## un-boggarted (released, lulled into a cairn, or bowed as a steward) and its
## body sinks away; its spawner grows another later.
class_name WildMob
extends ActorBase

const FACING_DOT: float = 0.75
const HOME_RADIUS: float = 0.8
const FADE_TIME: float = 1.2
const WANDER_RADIUS: float = 4.5
const WANDER_PAUSE: Vector2 = Vector2(4.0, 7.0)
const BAR_DOTS: int = 6
const BAR_COLOR: Color = Color(1.0, 0.45, 0.4)
## Curious hobs' dots are yellow until they're wronged.
const NEUTRAL_BAR_COLOR: Color = Color(1.0, 0.86, 0.35)
## A ranged creature shoots from this share of its range.
const RANGED_KEEP: float = 0.7
## The Cairn-Drake's stomp: every this many seconds while it walks, heard within this many metres.
const STOMP_EVERY: float = 1.1
const STOMP_HEARD: float = 45.0
## Spirits up to this level with no encounter of their own are roadside kin (Tier 0 to Iron-Root).
const ROADSIDE_KIN_MAX_LEVEL: int = 2
## A steward Iron-Man bows this far forward (radians).
const STEWARD_BOW: float = 0.45
## The parts that strike, by body (MobVariantResource.Body): they glow in the blow's Sign through its wind-up.
const ATTACK_LIMBS: Dictionary = {
	MobVariantResource.Body.BOAR: ["Tusk", "Snout"],
	MobVariantResource.Body.SCUTTLER: ["Tail"],
	MobVariantResource.Body.WOLF: ["Muzzle"],
	MobVariantResource.Body.TOAD: ["Jaw"],
	MobVariantResource.Body.HUMANOID: ["Weapon"],
	MobVariantResource.Body.VINE: ["Bloom"],
	MobVariantResource.Body.SHAMBLER: ["Cap"],
	MobVariantResource.Body.HULK: ["Fist"],
	MobVariantResource.Body.WIGHT: ["Weapon"],
	MobVariantResource.Body.BEHEMOTH: ["Head", "Bell"],
}
const AURA_SCALE: float = 0.8

var variant: MobVariantResource
## The spawner it belongs to (set before it enters the tree).
var spawner: MobSpawner
## In a fight right now.
var engaged: bool = false
## Act I's calming rule (docs/29 §5), for kin with `calm_rule`.
var calming: CalmingComponent
## A Stag Hunt's Amber Chime (docs/29 §5): its health dots glow amber while blades are held.
var amber: bool = false
## Its sculpted, animated body (KinFigure); null when a dropped-in model stands in.
var figure: KinFigure
## Host: a Grey-Bark Weevil at its tree's bark this tick (its figure plays the gnaw).
var gnawing: bool = false

var _attack_cooldown: float = 0.0
var _fade_left: float = -1.0
var _bar: Label3D
var _nav: NavSteering = NavSteering.new()
var _wander_target: Vector3 = Vector3.ZERO
var _wander_left: float = 0.0
var _patrol_index: int = 0
## Where it turned to fight (a patroller's leash is measured from here).
var _anchor: Vector3 = Vector3.ZERO
var _stomp_left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## How fast it was seen to move (on every peer, from where it went), for its gait.
var _seen_speed: float = 0.0
var _last_seen: Vector3 = Vector3.INF
## A calmed kin plays its calm before it fades and walks off (KinFigure.CALM_SHOW_TIME).
var _calm_hold: float = -1.0
var _last_flash: float = 0.0


func body_radius() -> float:
	return variant.radius


func body_height() -> float:
	return variant.height


func display_name() -> String:
	match variant.rank:
		MobVariantResource.Rank.RARE:
			return "%s (Rare)" % variant.display_name
		MobVariantResource.Rank.ELITE:
			return "%s (Great-Boggart)" % variant.display_name
	return variant.display_name


func is_engaged() -> bool:
	return engaged and not stats.is_downed


## Its variant's encounter (its Miyamoto tier and lock, 14 GDD §8), else Normal
## and Rare creatures up to Level 2 are Tier 0 roadside kin: an Iron-Root strike cracks them.
func glimmer_encounter_id() -> StringName:
	if variant.encounter_id != &"":
		return variant.encounter_id
	var minor: bool = variant.level <= ROADSIDE_KIN_MAX_LEVEL and variant.rank != MobVariantResource.Rank.BOSS \
		and variant.rank != MobVariantResource.Rank.ELITE
	return ArsenalCatalog.ROADSIDE_KIN if minor else &""


## A rooted lasher sheds its bark where it stands (14 GDD §8).
func can_leap() -> bool:
	return not variant.rooted


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


## Its place on the Hob-to-Boggart Spectrum comes from its variant.
func configure_spirit(spirit: HobSpectrumComponent) -> void:
	spirit.equilibrium = variant.equilibrium
	spirit.resolution = variant.resolution
	spirit.release_form = variant.release_form
	spirit.roars = variant.roars
	spirit.has_maker_seal = variant.has_maker_seal
	spirit.spirit_color = variant.accent_color


func _build_components() -> void:
	super._build_components()
	threat = ThreatComponent.new()
	threat.name = "ThreatComponent"
	add_child(threat)
	_rng.seed = hash(String(player_id))
	if variant.calm_rule:
		calming = CalmingComponent.new()
		calming.setup(self)
		add_child(calming)


func _build_visual() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	_body_material = StorybookMaterial.actor(variant.main_color, variant.eye_color)
	var dropped: Node3D = ActorVisuals.load_model(variant.variant_id)
	if dropped != null:
		visual.add_child(dropped)
	else:
		figure = KinFigure.new()
		figure.build(variant)
		visual.add_child(figure)
		_body_material = figure.material
	_register_attack_limbs()
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
	# Its level and danger at a glance (13_PLAYTEST §2.14).
	EnemyNameplate.attach(self, _name_label.visible)


# --- AI (the host runs it) -----------------------------------------------------

func _gather_intent(delta: float) -> void:
	move_intent = Vector3.ZERO
	gnawing = false
	wants_guard = false
	threat.tick(delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if not can_act() or spawner == null:
		return
	var home: Vector3 = _anchor if variant.patrols else spawn_transform.origin
	_update_engagement(home)
	if not engaged and variant.targets_trees:
		# A Grey-Bark Weevil goes for the nearest cider-bough before any hero (Q02).
		var tree: OrchardTree = OrchardTree.nearest(global_position, spawner.leash + 8.0)
		if tree != null:
			_gnaw(tree, delta)
			return
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
	if spectrum != null and spectrum.is_roaring():
		# The Challenge-Roar: it faces you and bellows, holding its blow.
		turn_toward(to_target, loadout.stats.turn_speed * delta)
		return
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


## Walks to an orchard tree and gnaws its bark (the tree counts its gnawers, OrchardTree).
func _gnaw(tree: OrchardTree, delta: float) -> void:
	var to_tree: Vector3 = tree.global_position - global_position
	to_tree.y = 0.0
	if to_tree.length() > tree.trunk_radius + body_radius() + OrchardTree.GNAW_REACH * 0.6:
		move_intent = _nav.direction(self, tree.global_position, delta) * 0.8
	else:
		turn_toward(to_tree, loadout.stats.turn_speed * delta)
		gnawing = true


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
	var soothed: bool = spectrum != null and spectrum.is_soothed()
	if not engaged and (in_aggro or hurt or (spawner.alert and not soothed)):
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


## The Cairn-Drake's footfalls: a deep bell-stomp, heard by anyone near.
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
		if amber:
			_bar.modulate = StagHuntEncounter.AMBER
	_watch_speed(delta)
	if figure != null:
		if _flash_left > _last_flash + 0.01:
			figure.flinch()
		_last_flash = _flash_left
		if spectrum != null and spectrum.is_steward():
			figure.restore()
		elif stats.is_downed and not figure.is_calming():
			figure.scatter()
		figure.update_for(self, delta, is_hit_stopped())
	if stats.is_downed:
		if _fade_left < 0.0:
			_fade_left = FADE_TIME
			collision_layer = 0
			hurtbox.collision_layer = 0
			_name_label.visible = false
		if spectrum != null and spectrum.is_steward():
			# A steward Iron-Man stands bowed, friendly, until his time is up (his figure bows; a dropped model leans).
			visual.rotation.x = 0.0 if figure != null else STEWARD_BOW
			return
		if figure != null and figure.is_calming():
			# Calmed: it shakes itself off first, then walks away into the hedge as it fades.
			if _calm_hold < 0.0:
				_calm_hold = KinFigure.CALM_SHOW_TIME
				_fade_left = FADE_TIME
			if _calm_hold > 0.0:
				_calm_hold = maxf(0.0, _calm_hold - delta)
				return
			figure.walking_off = true
			visual.position.z -= delta * KinFigure.WALK_OFF_SPEED
		_fade_left = maxf(0.0, _fade_left - delta)
		visual.scale = Vector3.ONE * maxf(0.05, _fade_left / FADE_TIME)
		visual.position.y = -0.4 * (1.0 - _fade_left / FADE_TIME)
		if _fade_left <= 0.0:
			visual.visible = false


## How fast it's seen to go, from where it went (so another peer's copy walks too).
func _watch_speed(delta: float) -> void:
	if _last_seen != Vector3.INF and delta > 0.0:
		var moved: Vector3 = global_position - _last_seen
		moved.y = 0.0
		var seen: float = moved.length() / delta
		_seen_speed = lerpf(_seen_speed, seen if seen < 30.0 else 0.0, 1.0 - exp(-12.0 * delta))
	_last_seen = global_position


## How fast it's going across the ground (as seen on this peer).
func remote_speed() -> float:
	return _seen_speed


## The calm's burst reached this peer (CalmingComponent): its figure washes its grey away.
func on_calm_burst() -> void:
	if figure != null:
		figure.begin_calm()


## The clip its figure is playing (for checks).
func kin_clip() -> StringName:
	return figure.current_clip() if figure != null else &""


func _poses_itself() -> bool:
	return figure != null


## Whether its fall has finished fading (its spawner may clear it away).
func has_faded() -> bool:
	return stats.is_downed and _fade_left == 0.0


# --- Bodies ----------------------------------------------------------------------

## A blow that carries a Sign lights the part that strikes with (14 GDD §8): a Tank reads which Ward-Mantle soaks it.
## A figure names its striking limbs (KinLooks); a dropped-in model's parts are found by name.
func _register_attack_limbs() -> void:
	if variant.blow_sign == ScribeSignResource.Sign.NONE:
		return
	if figure != null:
		for strike: Array in figure.strike_limbs():
			register_aura_limb(strike[0], maxf(0.12, float(strike[1]) * AURA_SCALE))
		return
	var parts: Array = ATTACK_LIMBS.get(variant.body, [])
	for child: Node in visual.find_children("*", "MeshInstance3D", true, false):
		var shape: MeshInstance3D = child as MeshInstance3D
		for part: String in parts:
			if String(shape.name).contains(part):
				var extent: Vector3 = shape.get_aabb().size
				register_aura_limb(shape, maxf(0.12, maxf(extent.x, maxf(extent.y, extent.z)) * AURA_SCALE))
				break
