## A woodland kin of the First-Quiet on the Dover-Slap-Falls trail
## (07_EXPEDITION_HUD_AND_ART_GDD.md §3, Zone 1; 15_THE_MYTHOPOETIC_LENS.md): a
## Bramble-Hob, a thorny bramble ball on twig legs, or a Wisp-Boggle, a hunched
## moss-grey sprite with lantern eyes. They slumber round their Hush-Crack
## (MinionCamp) until a player comes near or one of them is hit, then the
## whole crack's kin charge whoever tops its threat table (a tank's taunt works
## on them too). 65 health and 30 poise: cleaves, bow volleys and Sign
## detonations (Glacial Rupture splashes them) sweep them up.
##
## They're on the enemy side (the boss role and layers), owned by the host;
## other peers see synced copies. Beaten, they're un-boggarted: a Bramble-Hob
## flies off a hedge-wren, a Wisp-Boggle rises as a warm path-light, and the
## bramble-ball or moss husk they wore shrinks into the moss for the rest of
## the expedition.
class_name WoodlandMinion
extends ActorBase

enum Kind { SCUTTLER, IMP }

const KIND_NAMES: Array[String] = ["Bramble-Hob", "Wisp-Boggle"]
const HEALTH: float = 65.0
const POISE: float = 30.0
const RADII: Array[float] = [0.55, 0.4]
const HEIGHTS: Array[float] = [0.9, 1.35]
const ATTACK_RANGE: float = 1.9
const ATTACK_COOLDOWN: float = 1.5
## Attacks start only when roughly facing the target.
const FACING_DOT: float = 0.75
## They chase no further than this from their camp.
const LEASH_RADIUS: float = 18.0
const HOME_RADIUS: float = 0.6
const FADE_TIME: float = 1.2
## The health dots over their heads.
const BAR_DOTS: int = 6
const BAR_COLOR: Color = Color(1.0, 0.45, 0.4)
const EYE_COLORS: Array[Color] = [Color(1.0, 0.45, 0.15), Color(1.0, 0.85, 0.35)]
const THORN_COLOR: Color = Color(0.5, 0.36, 0.2)
const TWIG_COLOR: Color = Color(0.32, 0.24, 0.16)

var kind: Kind = Kind.SCUTTLER
## The camp that wakes it and that it guards (set before it enters the tree).
var camp: MinionCamp

var _attack_cooldown: float = 0.0
var _fade_left: float = -1.0
var _bar: Label3D
var _legs: Array[Node3D] = []
## Finds the way round banks and walls (the navigation map), straight in the open.
var _nav: NavSteering = NavSteering.new()


func body_radius() -> float:
	return RADII[kind]


func body_height() -> float:
	return HEIGHTS[kind]


func display_name() -> String:
	return KIND_NAMES[kind]


func is_engaged() -> bool:
	return camp != null and camp.alert and not stats.is_downed


## The expedition's minions are Tier 1 kin (14 GDD §3): an Iron-Root strike cracks them for 1.25x poise.
func glimmer_encounter_id() -> StringName:
	return ArsenalCatalog.ROADSIDE_KIN


## Beaten minions stay beaten.
func downed_duration() -> float:
	return INF


## Awakened kin, un-boggarted when beaten: a hedge-wren or a path-light.
func configure_spirit(spirit: HobSpectrumComponent) -> void:
	spirit.release_form = HobSpectrumComponent.ReleaseForm.HEDGE_WREN if kind == Kind.SCUTTLER else HobSpectrumComponent.ReleaseForm.PATH_LIGHT
	spirit.spirit_color = EYE_COLORS[kind]


func _build_components() -> void:
	super._build_components()
	threat = ThreatComponent.new()
	threat.name = "ThreatComponent"
	add_child(threat)


## Its own little body instead of the player capsule, all sharing one material
## so a hit flashes the whole creature.
func _build_visual() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	_body_material = StorybookMaterial.actor(loadout.body_color, EYE_COLORS[kind])
	var dropped: Node3D = ActorVisuals.load_model(loadout.class_id)
	if dropped != null:
		visual.add_child(dropped)
	elif kind == Kind.SCUTTLER:
		_build_scuttler()
	else:
		_build_imp()
	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.visible = false
	add_child(_name_label)
	_bar = Label3D.new()
	_bar.name = "HealthDots"
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.no_depth_test = true
	_bar.font_size = 32
	_bar.outline_size = 8
	_bar.pixel_size = 0.006
	_bar.modulate = BAR_COLOR
	_bar.position = Vector3(0.0, body_height() + 0.35, 0.0)
	add_child(_bar)


## A thorny bramble ball on six twig legs, with two ember eyes.
func _build_scuttler() -> void:
	var radius: float = RADII[Kind.SCUTTLER]
	visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", radius, Vector3(0.0, 0.5, 0.0), _body_material), Vector3(1.0, 0.75, 1.0)))
	var thorns: Material = _flat_material(THORN_COLOR)
	for index: int in 10:
		var angle: float = TAU * float(index) / 10.0
		var thorn: MeshInstance3D = ShapeKit.cone("Thorn%d" % index, 0.07, 0.3, Vector3.ZERO, thorns)
		var out: Vector3 = Vector3(cos(angle), 0.35 if index % 2 == 0 else -0.1, sin(angle)).normalized()
		thorn.position = Vector3(0.0, 0.5, 0.0) + out * radius * 0.85
		thorn.basis = _pointing(out)
		visual.add_child(thorn)
	var twig: Material = _flat_material(TWIG_COLOR)
	for index: int in 6:
		var side: float = -1.0 if index < 3 else 1.0
		var leg: Node3D = Node3D.new()
		leg.name = "Leg%d" % index
		leg.position = Vector3(side * radius * 0.6, 0.4, (float(index % 3) - 1.0) * radius * 0.6)
		var bone: MeshInstance3D = ShapeKit.cylinder("Twig", 0.035, 0.035, 0.55, Vector3.ZERO, twig, 8)
		bone.position = Vector3(side * 0.18, -0.18, 0.0)
		bone.rotation = Vector3(0.0, 0.0, side * 0.9)
		leg.add_child(bone)
		visual.add_child(leg)
		_legs.append(leg)
	_add_eyes(Vector3(0.14, 0.6, -radius * 0.82), 0.07)


## A hunched moss-grey imp: a round body, a big head with pointed ears, lantern eyes and little arms.
func _build_imp() -> void:
	visual.add_child(ShapeKit.stretched(ShapeKit.sphere("Body", 0.36, Vector3(0.0, 0.5, 0.0), _body_material), Vector3(1.0, 1.25, 0.9)))
	visual.add_child(ShapeKit.sphere("Head", 0.3, Vector3(0.0, 1.02, -0.08), _body_material))
	var ear_material: Material = _flat_material(loadout.body_color.darkened(0.25))
	for side: float in [-1.0, 1.0]:
		var ear: MeshInstance3D = ShapeKit.cone("Ear", 0.09, 0.32, Vector3.ZERO, ear_material)
		ear.position = Vector3(side * 0.24, 1.2, -0.05)
		ear.rotation = Vector3(0.0, 0.0, -side * 0.7)
		visual.add_child(ear)
		var arm: MeshInstance3D = ShapeKit.cylinder("Arm", 0.06, 0.06, 0.45, Vector3.ZERO, _body_material, 8)
		arm.position = Vector3(side * 0.36, 0.52, -0.12)
		arm.rotation = Vector3(0.5, 0.0, side * 0.5)
		visual.add_child(arm)
		var foot: MeshInstance3D = ShapeKit.stretched(ShapeKit.sphere("Foot", 0.1, Vector3(side * 0.16, 0.08, -0.04), ear_material), Vector3(1.0, 0.6, 1.4))
		visual.add_child(foot)
	_add_eyes(Vector3(0.11, 1.06, -0.33), 0.065)


func _add_eyes(right_eye: Vector3, size: float) -> void:
	var glow: StandardMaterial3D = StorybookMaterial.glowing(EYE_COLORS[kind], 3.0)
	for side: float in [-1.0, 1.0]:
		visual.add_child(ShapeKit.sphere("Eye", size, Vector3(right_eye.x * side, right_eye.y, right_eye.z), glow))


# --- AI (runs only on the host, which owns minions) ------------------------

func _gather_intent(delta: float) -> void:
	move_intent = Vector3.ZERO
	wants_guard = false
	threat.tick(delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if not can_act() or camp == null:
		return
	var target: ActorBase = _pick_target() if camp.alert else null
	if target == null:
		_go_home(delta)
		return
	if action_queue.is_busy():
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > ATTACK_RANGE - 0.3:
		move_intent = _nav.direction(self, target.global_position, delta)
		return
	turn_toward(to_target, loadout.stats.turn_speed * delta)
	if _attack_cooldown <= 0.0 and facing_vector().dot(to_target.normalized()) >= FACING_DOT:
		_attack_cooldown = ATTACK_COOLDOWN
		action_queue.request(CombatActionResource.Command.LIGHT)


## Whoever tops its aggro table among standing players near the camp, else the nearest of them.
func _pick_target() -> ActorBase:
	var eligible: Array[StringName] = []
	var nearest: ActorBase = null
	var nearest_distance: float = INF
	for member: ActorBase in CombatDirector.current.alive_party():
		if _flat_distance(member.global_position, camp.global_position) > LEASH_RADIUS:
			continue
		eligible.append(member.player_id)
		var distance: float = _flat_distance(member.global_position, global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = member
	var top: StringName = threat.top_target(eligible)
	var chosen: ActorBase = CombatDirector.current.get_actor(top) if top != &"" else null
	return chosen if chosen != null else nearest


## Nobody to chase: walk back to its spot in camp, and mend there.
func _go_home(delta: float) -> void:
	var to_home: Vector3 = spawn_transform.origin - global_position
	to_home.y = 0.0
	if to_home.length() > HOME_RADIUS:
		move_intent = _nav.direction(self, spawn_transform.origin, delta) * clampf(to_home.length(), 0.4, 1.0)
		return
	if stats.health < stats.stats.max_health:
		stats.heal(stats.stats.max_health)
	threat.clear()


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- Look -----------------------------------------------------------------

func _update_pose(delta: float) -> void:
	super._update_pose(delta)
	var ratio: float = stats.health_ratio()
	_bar.visible = not stats.is_downed and (is_engaged() or ratio < 1.0)
	if _bar.visible:
		var lit: int = ceili(ratio * BAR_DOTS)
		_bar.text = "●".repeat(lit) + "○".repeat(BAR_DOTS - lit)
	# A Scuttler's legs skitter while it moves.
	var stride: float = sin(Time.get_ticks_msec() * 0.03) * 0.35 if Vector2(velocity.x, velocity.z).length() > 0.3 else 0.0
	for index: int in _legs.size():
		_legs[index].rotation.x = stride * (1.0 if index % 2 == 0 else -1.0)
	if stats.is_downed:
		if _fade_left < 0.0:
			_fade_left = FADE_TIME
			collision_layer = 0
			hurtbox.collision_layer = 0
		_fade_left = maxf(0.0, _fade_left - delta)
		visual.scale = Vector3.ONE * maxf(0.05, _fade_left / FADE_TIME)
		visual.position.y = -0.4 * (1.0 - _fade_left / FADE_TIME)
		if _fade_left <= 0.0:
			visual.visible = false


## A basis whose +Y (where a cone points) runs along `direction`.
static func _pointing(direction: Vector3) -> Basis:
	var up: Vector3 = direction.normalized()
	var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(side, up, side.cross(up))
