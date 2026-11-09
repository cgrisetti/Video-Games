## A kin's sculpted, animated body (docs/30_KIN_DESIGN_LANGUAGE.md): the
## StorybookFigure of the foes. Its look's skeleton (KinRigBuilder) scaled to the
## variant's height, its one skinned surface (KinSculptor) in the painted kin
## material with the ink line, and a KinAnimator that plays what the WildMob is
## doing on every peer. It also keeps the story's looks: the Un-Inked grey that a
## calm washes off (the dog-roses opening with it), the scatter's grey crumble,
## an Iron-Man's Maker-Seal turning upright, the striking part glowing in its
## blow's Sign, and eyes that blink. Near a hero it poses every frame; further
## off less often (ANIMATE_TIERS), so a full quay of tide-kin stays cheap.
class_name KinFigure
extends Node3D

## [distance from the nearest hero, poses a second] (0 = every frame).
const ANIMATE_TIERS: Array[Vector2] = [Vector2(24.0, 0.0), Vector2(55.0, 20.0), Vector2(110.0, 6.0)]
## Beyond the last tier it holds its pose.
const FAR_HZ: float = 1.0
## The Un-Inked grey and the calm's wash (docs/28 §3.5: cracks at 0 s, colour back by 0.8 s).
const UN_INKED: float = 1.0
const CALM_WASH_TIME: float = 0.9
const SCATTER_GREY_TIME: float = 0.35
## A dog-rose opens over this long once the colour is back.
const BLOOM_TIME: float = 0.7
## The calm plays this long before the kin walks off as it fades (WildMob holds its fade).
const CALM_SHOW_TIME: float = 1.4
## How fast a calmed kin walks off into the hedge as it fades (m/s).
const WALK_OFF_SPEED: float = 1.4
## Looks whose petals are always open (a lasher's rose, a bucca's flower, a thorn-tail's).
const ALWAYS_IN_BLOOM: Array[StringName] = [KinLooks.BRAMBLE_LASHER, KinLooks.PUDDLE_BUCCA, KinLooks.THORN_TAIL]
## The Maker-Seal's plate on an Iron-Man's chest (Chest-bone space) and how fast it turns.
## How big each Iron-Man's cauldron is (KinSculptFolk), so the seal sits on its front.
const SEAL_POT: Dictionary[StringName, float] = {KinLooks.IRON_MAN: 1.0, KinLooks.IRON_FLINGER: 0.8, KinLooks.IRON_GIANT: 1.12}
const SEAL_TURN_SPEED: float = 5.0

var variant: MobVariantResource
var look: StringName = &""
var rig: KinRig
var skeleton: Skeleton3D
var surface: MeshInstance3D
var material: ShaderMaterial
var animator: KinAnimator
## Its sculpted height and the scale that fits it to the variant's.
var fit: float = 1.0
## 1 all grey, 0 its own colours.
var un_inked: float = 0.0
var bloom: float = 0.0
## What the story has done to it: "calming" (washing back), "calmed", "scattered", "restored".
var story: StringName = &""
var seal: MeshInstance3D
## Calmed and shaken off, it walks away as it fades (WildMob sets it).
var walking_off: bool = false

var _strikes: Array[Array] = []
var _clock: float = 0.0
var _blink_seed: float = 0.0
var _since_pose: float = 1.0
var _wash_from: float = 0.0
var _wash_to: float = 0.0
var _wash_left: float = 0.0
var _wash_time: float = 1.0
var _seal_angle: float = 0.0
var _forced: StringName = &""
var _forced_frame: float = -1.0


## Sculpts a variant's look and bakes its clips ahead of time (a spawner does it as it's built).
static func warm(for_variant: MobVariantResource) -> void:
	if ActorVisuals.has_model(for_variant.variant_id):
		return
	var look_id: StringName = KinLooks.look_of(for_variant)
	KinSculptor.mesh(look_id)
	KinAnimator.library(look_id)


## Builds the figure for a variant: skeleton, surface, material, animator, sockets.
func build(for_variant: MobVariantResource) -> void:
	variant = for_variant
	look = KinLooks.look_of(variant)
	name = "KinFigure"
	var spec: Dictionary = KinLooks.spec(look)
	rig = KinSculptor.rig(look)
	skeleton = rig.build_skeleton(KinRigBuilder.SKELETON_NAME)
	fit = variant.height / maxf(float(spec["height"]), 0.05)
	skeleton.scale = Vector3.ONE * fit
	add_child(skeleton)
	material = KinSculptor.material(variant, look)
	surface = MeshInstance3D.new()
	surface.name = "KinSurface"
	surface.mesh = KinSculptor.mesh(look)
	surface.skin = skeleton.get_meta(&"skin") as Skin
	surface.material_override = material
	skeleton.add_child(surface)
	surface.skeleton = surface.get_path_to(skeleton)
	animator = KinAnimator.new()
	animator.setup(look, rig, skeleton)
	add_child(animator)
	_blink_seed = float(hash(String(variant.variant_id)) % 997) * 0.013 + randf() * 3.0
	_clock = randf() * 10.0
	un_inked = UN_INKED if variant.un_inked else 0.0
	bloom = 1.0 if ALWAYS_IN_BLOOM.has(look) or not variant.un_inked else 0.0
	material.set_shader_parameter(&"un_inked", un_inked)
	material.set_shader_parameter(&"bloom", bloom)
	for strike: Array in spec["strikes"]:
		var bone: int = rig.b(strike[0])
		if bone < 0:
			continue
		var socket: BoneAttachment3D = BoneAttachment3D.new()
		socket.name = "Strike_%s" % String(strike[0])
		skeleton.add_child(socket)
		socket.bone_name = String(strike[0])
		var limb: Node3D = Node3D.new()
		limb.name = "StrikeLimb"
		limb.position = Vector3(0.0, rig.bone_length(bone) * 0.6, 0.0)
		socket.add_child(limb)
		_strikes.append([limb, float(strike[1]) * fit])
	if variant.has_maker_seal and rig.has(&"Chest"):
		var plate: BoneAttachment3D = BoneAttachment3D.new()
		plate.name = "MakerSealSocket"
		skeleton.add_child(plate)
		plate.bone_name = "Chest"
		seal = MeshInstance3D.new()
		seal.name = "MakerSealPlate"
		seal.mesh = KinSculptFolk.maker_seal_mesh()
		seal.material_override = material
		seal.position = rig.globals[rig.b(&"Chest")].affine_inverse() * Vector3(0.0, 1.33, -0.3 * float(SEAL_POT.get(look, 1.0)) - 0.025)
		plate.add_child(seal)
	animator.update(0.0, &"idle")


## The limbs its blow strikes with and each one's aura radius, for ActorBase.register_aura_limb.
func strike_limbs() -> Array[Array]:
	return _strikes


## The clip it's playing (for checks).
func current_clip() -> StringName:
	return animator.clip if animator != null else &""


## Plays `clip_name` (at `frame`, or running when -1) whatever the actor does: for previews and checks.
func force_clip(clip_name: StringName, frame: float = -1.0) -> void:
	_forced = clip_name
	_forced_frame = frame


# --- The story's looks -------------------------------------------------------------

## The calm (CalmingComponent's burst, on every peer): the grey cracks and washes off,
## its dog-roses open, and it shakes itself like a wet dog.
func begin_calm() -> void:
	if story == &"calming" or story == &"calmed":
		return
	story = &"calming"
	_wash(0.0, CALM_WASH_TIME)


## Burnt to nothing: it greys right through as it falls.
func scatter() -> void:
	if story != &"":
		return
	story = &"scattered"
	_wash(1.0, SCATTER_GREY_TIME)


## Its colour back without the calm's shake (an Iron-Man bowed as a steward).
func restore() -> void:
	if story == &"calming" or story == &"calmed" or story == &"restored":
		return
	story = &"restored"
	_wash(0.0, CALM_WASH_TIME)


func is_calming() -> bool:
	return story == &"calming" or story == &"calmed"


func _wash(to: float, seconds: float) -> void:
	_wash_from = un_inked
	_wash_to = to
	_wash_time = seconds
	_wash_left = seconds


## A flinch from a blow.
func flinch() -> void:
	if animator != null:
		animator.flinch()


# --- Every frame --------------------------------------------------------------------

## Poses the figure for what `mob` is doing (WildMob._update_pose calls it on every peer).
## `frozen` (a hit-stop) holds every clock.
func update_for(mob: WildMob, delta: float, frozen: bool) -> void:
	var step: float = 0.0 if frozen else delta
	_update_story(step)
	_clock += step
	material.set_shader_parameter(&"eye_blink", 0.0 if story == &"scattered" else HeroMeshAtelier.blink_amount(_clock, _blink_seed))
	var sign_lit: int = mob.attack_aura_sign()
	if sign_lit != ScribeSignResource.Sign.NONE:
		material.set_shader_parameter(&"active_sign_color", ArsenalCatalog.current.sign_seal(sign_lit).color)
		material.set_shader_parameter(&"sign_emission_strength", 1.2 + 0.5 * sin(CombatDirector.game_time() * 14.0))
	else:
		material.set_shader_parameter(&"sign_emission_strength", 0.0)
	if seal != null and mob.spectrum != null:
		var want: float = PI if mob.spectrum.is_maker_seal_upright else 0.0
		_seal_angle = move_toward(_seal_angle, want, SEAL_TURN_SPEED * step)
		seal.rotation.z = _seal_angle
	_since_pose += delta
	var interval: float = _pose_interval(mob)
	if interval > 0.0 and _since_pose < interval and not frozen:
		return
	var elapsed: float = _since_pose
	_since_pose = 0.0
	_pose_mob(mob, 0.0 if frozen else elapsed)


## Poses it with no actor (a preview or a check): the forced clip, or its idle.
func update_preview(delta: float) -> void:
	_update_story(delta)
	_clock += delta
	material.set_shader_parameter(&"eye_blink", HeroMeshAtelier.blink_amount(_clock, _blink_seed))
	var clip: StringName = _forced if _forced != &"" else _idle_clip()
	animator.update(delta, clip, _forced_frame)


func _update_story(step: float) -> void:
	if _wash_left > 0.0:
		_wash_left = maxf(0.0, _wash_left - step)
		un_inked = lerpf(_wash_from, _wash_to, 1.0 - _wash_left / maxf(_wash_time, 0.001))
		material.set_shader_parameter(&"un_inked", un_inked)
	if (story == &"calming" or story == &"calmed" or story == &"restored") and un_inked < 0.25 and bloom < 1.0:
		bloom = minf(1.0, bloom + step / BLOOM_TIME)
		material.set_shader_parameter(&"bloom", bloom)


## How long it may go between poses, by how near the nearest hero is.
func _pose_interval(mob: WildMob) -> float:
	var nearest: float = INF
	if CombatDirector.current != null:
		for member: ActorBase in CombatDirector.current.party_actors():
			nearest = minf(nearest, member.global_position.distance_squared_to(mob.global_position))
	nearest = sqrt(nearest)
	for tier: Vector2 in ANIMATE_TIERS:
		if nearest <= tier.x:
			return 0.0 if tier.y <= 0.0 else 1.0 / tier.y
	return 1.0 / FAR_HZ


func _pose_mob(mob: WildMob, step: float) -> void:
	if _forced != &"":
		animator.update(step, _forced, _forced_frame)
		return
	var state: StringName = mob.state_machine.current_name() if mob.is_multiplayer_authority() else mob.net_sync.remote_state
	var speed: float = Vector2(mob.velocity.x, mob.velocity.z).length()
	if not mob.is_multiplayer_authority():
		speed = mob.remote_speed()
	var spec: Dictionary = KinLooks.spec(look)
	var gait: float = float(spec["gait"]) * fit
	var wanted: StringName = _idle_clip()
	var frame: float = -1.0
	var moving_speed: float = 0.0
	var action: CombatActionResource = mob.current_action()
	if mob.spectrum != null and mob.spectrum.is_steward():
		wanted = &"bow" if KinAnimator.has_clip(look, &"bow") else &"happy"
	elif walking_off:
		wanted = KinAnimator.WALK_BY_LOOK.get(look, &"walk")
		moving_speed = WALK_OFF_SPEED
	elif story == &"calming" or story == &"calmed":
		wanted = &"calmed"
		if animator.clip == &"calmed" and animator.one_shot_progress() >= 1.0:
			story = &"calmed"
	elif mob.stats.is_downed:
		wanted = &"collapse"
	elif mob.stats.is_knocked_down():
		wanted = &"kneel"
	elif state == &"stagger":
		wanted = &"stagger"
	elif action != null and state == &"attack":
		wanted = spec["attack"]
		var phase: int = mob.current_phase()
		var progress: float = animator.watched_progress(action, phase, step)
		if mob.is_multiplayer_authority():
			progress = _phase_progress(mob, action, phase)
		frame = animator.action_frame(wanted, phase, progress)
	elif mob.calming != null and mob.calming.is_wavering():
		wanted = &"waver"
	elif mob.spectrum != null and mob.spectrum.is_roaring():
		wanted = &"roar"
	elif mob.spectrum != null and mob.spectrum.is_soothed():
		wanted = &"happy"
	elif mob.gnawing and KinAnimator.has_clip(look, &"gnaw"):
		wanted = &"gnaw"
	elif speed > KinAnimator.WALK_START_SPEED and not mob.variant.rooted:
		var running: bool = speed >= mob.variant.move_speed * 0.62
		wanted = KinAnimator.RUN_BY_LOOK.get(look, &"run") if running else KinAnimator.WALK_BY_LOOK.get(look, &"walk")
		moving_speed = speed
		if running:
			gait *= 1.7
	animator.update(step, wanted, frame, moving_speed, gait)


func _idle_clip() -> StringName:
	return KinAnimator.IDLE_BY_LOOK.get(look, &"idle")


## How far through its phase the host's own action is, 0 to 1.
static func _phase_progress(mob: WildMob, action: CombatActionResource, phase: int) -> float:
	var length: float = 1.0
	match phase:
		ActionQueueComponent.Phase.WINDUP:
			length = action.windup_time
		ActionQueueComponent.Phase.ACTIVE:
			length = action.active_time
		ActionQueueComponent.Phase.RECOVERY:
			length = mob.action_queue.recovery_time if mob.action_queue.recovery_time > 0.0 else action.recovery_time
	return clampf(mob.action_queue.phase_time / maxf(length, 0.001), 0.0, 1.0)
