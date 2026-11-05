## The hero's frame-locked animation (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §3.3,
## Stage 7). It builds one procedural AnimationLibrary ("hero") of rotation,
## position and scale tracks on the 24-bone skeleton, keyed at 60 Hz, and every
## physics tick picks the clip for what the hero is doing and samples it at the
## exact frame the action's clock says: a clip's wind-up, active and recovery
## frames are stretched onto the action's own wind-up, active and recovery (the
## Flow-Link's +15% speed included), so the pose never drifts from the hit.
##
## Poses are authored by aim: an arm bone points along a direction in the
## chest's frame, a leg bone in the ground's, and a hand turns its weapon's
## haft along a direction; spines, necks and heads take small turns (x pitch,
## positive leaning back; y yaw, positive turning left; z roll, positive
## tipping left). The baker turns those into each bone's local rotation.
##
## The clips:
##   idles and footwork  idle_steward_calm (weapon on the back after 4 s out of
##                       a fight), idle_combat_ready (+ _axe, _staff, _bow),
##                       locomotion_run_cycle (28 f, feet planting on f 4 and 18:
##                       the jaunty woodsman's stride, weapon in a low port),
##                       winded_3rd_light_recovery (33 f, 550 ms)
##   Broad-Axe           axe_light_1, axe_light_2 (51 f), axe_heavy_earth_splitter
##                       (56 f), axe_flourish_r_coppice, axe_ult_lr_heartwood
##   Falchion            falchion_light_1..3, falchion_heavy_advancing_thrust,
##                       falchion_flourish_r_timber_cross, falchion_ult_lr_bramble_whirl
##   Yew Longbow         bow_light_snap_shot_1, _2, bow_heavy_piercing_draw,
##                       bow_flourish_r_vaulting_bough, bow_ult_lr_hail_of_hedgerow
##   Rowan Way-Staff     staff_light_sweep_1, _2, staff_light_bolt,
##                       staff_heavy_resonant_pulse, staff_flourish_r_reed_sweep,
##                       staff_ult_lr_lantern_chime
##   Scribe Cards        card_invoke_forward, _back, _r, _lr (through the
##                       weapon) and card_invoke_at_caster
##   defence             guard_hold, perfect_guard_parry, shadow_sanctuary_brace,
##                       dodge_roll_evade (24 f, 0.40 s)
##   stewardship         hearth_rite_tuck (120 f; 80 f on Star-Inked Vellum, by
##                       the hold's own clock), truce_sign_parley (48 f),
##                       bravery_counter_strike
##   reactions           stagger_reel, downed_slump
##   overlays            overhead_pocket_blessing, offhand_pocket_draw (one arm each)
class_name HeroCombatAnimator
extends Node

## A foot came down in the run cycle (frames 4 and 18).
signal foot_planted(left: bool)

const FPS: float = 60.0
const LIBRARY_NAME: StringName = &"hero"
const SKELETON_PATH: String = "HeroSkeleton3D"
## Cross-fades between clips, and the shorter one into a swing.
const BLEND_TIME: float = 0.12
const ACTION_BLEND_TIME: float = 0.05
## Out of a fight this long, the weapon goes on the back and the hero stands easy.
const CALM_AFTER: float = 4.0
const RUN_CYCLE_FRAMES: int = 28
## How far one full run cycle (two steps) carries the hero at full speed.
const RUN_CYCLE_METRES: float = 2.8
const FOOT_PLANT_FRAMES: Array[int] = [4, 18]
## Below this speed the hero stands; above it the run cycle blends in.
const WALK_START_SPEED: float = 0.4
## The jump (Phase 12 Kaizen, K1): a stride frozen mid-leap, stretched up to
## JUMP_STRETCH tall on the way up and down, and squashed JUMP_LAND_SQUASH
## short (and that much lower) for JUMP_LAND_TIME as the feet land.
const JUMP_RISE_FRAME: float = 7.0
const JUMP_FALL_FRAME: float = 21.0
const JUMP_STRETCH: float = 0.12
const JUMP_LAND_SQUASH: float = 0.16
const JUMP_LAND_DROP: float = 0.08
const JUMP_LAND_TIME: float = 0.18
const B = HeroRigBuilder.Bone
const Weapon = EquipmentItemResource.WeaponType
const Cmd = CombatActionResource.Command
const ARM_R: Array[int] = [B.CLAVICLE_R, B.UPPER_ARM_R, B.FOREARM_R, B.HAND_R]
const ARM_L: Array[int] = [B.CLAVICLE_L, B.UPPER_ARM_L, B.FOREARM_L, B.HAND_L]
## Light chains, heavies and flourishes by action id and weapon.
const LIGHT_CLIPS: Dictionary[StringName, StringName] = {
	&"slash_1": &"falchion_light_1", &"slash_2": &"falchion_light_2", &"slash_3": &"falchion_light_3",
	&"cleave_1": &"axe_light_1", &"cleave_2": &"axe_light_2",
	&"sweep_1": &"staff_light_sweep_1", &"sweep_2": &"staff_light_sweep_2", &"arcane_bolt": &"staff_light_bolt",
	&"snap_shot_1": &"bow_light_snap_shot_1", &"snap_shot_2": &"bow_light_snap_shot_2",
}
const WEAPON_CLIPS: Dictionary[int, Array] = {
	# [light, heavy, R flourish, L+R flourish, ready]
	Weapon.LIGHT_SWORD: [&"falchion_light_1", &"falchion_heavy_advancing_thrust", &"falchion_flourish_r_timber_cross", &"falchion_ult_lr_bramble_whirl", &"idle_combat_ready"],
	Weapon.HEAVY_AXE: [&"axe_light_1", &"axe_heavy_earth_splitter", &"axe_flourish_r_coppice", &"axe_ult_lr_heartwood", &"idle_combat_ready_axe"],
	Weapon.STAFF: [&"staff_light_sweep_1", &"staff_heavy_resonant_pulse", &"staff_flourish_r_reed_sweep", &"staff_ult_lr_lantern_chime", &"idle_combat_ready_staff"],
	Weapon.BOW: [&"bow_light_snap_shot_1", &"bow_heavy_piercing_draw", &"bow_flourish_r_vaulting_bough", &"bow_ult_lr_hail_of_hedgerow", &"idle_combat_ready_bow"],
}
const CARD_CLIPS: Array[StringName] = [&"card_invoke_forward", &"card_invoke_back", &"card_invoke_r", &"card_invoke_lr"]

static var _library: AnimationLibrary
static var _info: Dictionary[StringName, Dictionary] = {}
## Per clip: [track index, track type, bone] for every track.
static var _tracks: Dictionary[StringName, Array] = {}
static var _rest_rotations: Array[Quaternion] = []

var actor: ActorBase
var skeleton: Skeleton3D
var player: AnimationPlayer
## The clip playing as the base pose, and its frame.
var clip: StringName = &"idle_combat_ready"
var clip_frame: float = 0.0
## The weapon is on the back (idle_steward_calm).
var calm: bool = false
## How much the 2-handed grip and the bow draw apply now (the modifier reads these).
var grip_weight: float = 0.0
var draw_weight: float = 0.0
var foot_ik_weight: float = 1.0
## How many times each clip has started, and feet planted, on this hero.
var played: Dictionary[StringName, int] = {}
var feet_planted: int = 0
## The base pose last written: each bone's local rotation, the hips' offset and scale.
var pose_rotations: Array[Quaternion] = []
var hips_offset: Vector3 = Vector3.ZERO
var hips_scale: Vector3 = Vector3.ONE
## How fast the hero is rising (+) or falling (-), fed by ActorVisuals from how it moved (so copies on other peers jump too).
var vertical_speed: float = 0.0
## The landing squash still to play (1 just landed, 0 done), and whether the hero was in the air last tick.
var land_squash: float = 0.0
var airborne: bool = false

var _from_clip: StringName = &""
var _from_frame: float = 0.0
var _blend_left: float = 0.0
var _blend_time: float = BLEND_TIME
var _one_shot: StringName = &""
var _one_shot_frame: float = 0.0
var _overlay: StringName = &""
var _overlay_frame: float = 0.0
var _cycle: float = 0.0
var _idle_frame: float = 0.0
var _since_fight: float = 0.0
var _watched_action: StringName = &""
var _watched_phase: int = -1
var _watched_clock: float = 0.0


func setup(for_actor: ActorBase, for_skeleton: Skeleton3D) -> void:
	actor = for_actor
	skeleton = for_skeleton
	name = "HeroCombatAnimator"


func _ready() -> void:
	player = AnimationPlayer.new()
	player.name = "HeroAnimationPlayer"
	add_child(player)
	player.root_node = player.get_path_to(skeleton.get_parent())
	player.add_animation_library(LIBRARY_NAME, library())
	# The library's tracks are sampled here, frame-locked to the action's clock, so the player itself stays still.
	player.active = false
	pose_rotations = rest_rotations().duplicate()


# --- The library ---------------------------------------------------------------

## The shared procedural AnimationLibrary (built once).
static func library() -> AnimationLibrary:
	if _library == null:
		_library = AnimationLibrary.new()
		for entry: Array in HeroClipBook.clips():
			_add_clip(entry[0], entry[1])
	return _library


## A clip's frame data: "frames", "loop", "windup", "active", "foot_ik", "grip", "draw".
static func clip_info(clip_name: StringName) -> Dictionary:
	library()
	return _info.get(clip_name, {})


static func clip_names() -> Array[StringName]:
	library()
	var names: Array[StringName] = []
	names.assign(_info.keys())
	return names


## A clip's pose at a frame, for checks: {"rotations": Array[Quaternion] (each
## bone's local rotation), "hips": the hips' offset, "scale": the hips' scale}.
static func sample_pose(clip_name: StringName, frame: float) -> Dictionary:
	var rotations: Array[Quaternion] = rest_rotations().duplicate()
	var offset: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
	_sample(clip_name, frame, rotations, offset)
	return {"rotations": rotations, "hips": offset[0], "scale": offset[1]}


## Each bone's rest rotation (the pose an un-keyed bone keeps).
static func rest_rotations() -> Array[Quaternion]:
	if _rest_rotations.is_empty():
		for rest: Transform3D in HeroRigBuilder.local_rests():
			_rest_rotations.append(rest.basis.get_rotation_quaternion())
	return _rest_rotations


static func _add_clip(clip_name: StringName, spec: Dictionary) -> void:
	var frames: int = spec["frames"]
	var animation: Animation = Animation.new()
	animation.length = float(frames) / FPS
	animation.step = 1.0 / FPS
	animation.loop_mode = Animation.LOOP_LINEAR if spec.get("loop", false) else Animation.LOOP_NONE
	var keys: Array = spec["keys"]
	var leg_space: String = spec.get("leg_space", "root")
	var baked: Array[Dictionary] = []
	var bones: Dictionary[int, bool] = {}
	var hips_keyed: bool = false
	var scale_keyed: bool = false
	for key: Array in keys:
		var pose: Dictionary = key[1]
		var rotations: Dictionary = HeroPoseBaker.bake(pose, leg_space)
		baked.append(rotations)
		for bone: int in rotations:
			bones[bone] = true
		hips_keyed = hips_keyed or pose.has("hips")
		scale_keyed = scale_keyed or pose.has("scale")
	var entries: Array = []
	var rests: Array[Quaternion] = rest_rotations()
	var sorted_bones: Array[int] = []
	sorted_bones.assign(bones.keys())
	sorted_bones.sort()
	for bone: int in sorted_bones:
		var track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("%s:%s" % [SKELETON_PATH, HeroRigBuilder.BONE_NAMES[bone]]))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for index: int in keys.size():
			var rotation: Quaternion = baked[index].get(bone, rests[bone])
			animation.rotation_track_insert_key(track, float(keys[index][0]) / FPS, rotation)
		entries.append([track, Animation.TYPE_ROTATION_3D, bone])
	var hips_rest: Vector3 = HeroRigBuilder.local_rests()[B.HIPS].origin
	if hips_keyed:
		var track: int = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("%s:Hips" % SKELETON_PATH))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for key: Array in keys:
			var pose: Dictionary = key[1]
			animation.position_track_insert_key(track, float(key[0]) / FPS, hips_rest + (pose.get("hips", Vector3.ZERO) as Vector3))
		entries.append([track, Animation.TYPE_POSITION_3D, B.HIPS])
	if scale_keyed:
		var track: int = animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(track, NodePath("%s:Hips" % SKELETON_PATH))
		for key: Array in keys:
			var pose: Dictionary = key[1]
			animation.scale_track_insert_key(track, float(key[0]) / FPS, pose.get("scale", Vector3.ONE))
		entries.append([track, Animation.TYPE_SCALE_3D, B.HIPS])
	_library.add_animation(clip_name, animation)
	_tracks[clip_name] = entries
	var info: Dictionary = {
		"frames": frames, "loop": spec.get("loop", false), "windup": spec.get("windup", 0), "active": spec.get("active", 0),
		"foot_ik": spec.get("foot_ik", true), "grip": spec.get("grip", false), "draw": spec.get("draw", false),
	}
	_info[clip_name] = info


# --- Playing -------------------------------------------------------------------

## Plays a full-body one-shot over whatever the hero is doing (a parley, a
## parry, a Bravery Counter), from its first frame.
func play_one_shot(clip_name: StringName) -> void:
	if not _info.has(clip_name):
		return
	_one_shot = clip_name
	_one_shot_frame = 0.0
	_count(clip_name)


## Plays an arm overlay (the Overhead Pocket Blessing on the right arm, the
## Offhand Pocket-Draw on the left) on top of the base pose.
func play_overlay(clip_name: StringName) -> void:
	if not _info.has(clip_name):
		return
	_overlay = clip_name
	_overlay_frame = 0.0
	_count(clip_name)


func overlay_clip() -> StringName:
	return _overlay


func one_shot_clip() -> StringName:
	return _one_shot


## The pose for this tick: picks the clip, samples it frame-locked, blends,
## layers one-shots and overlays, and writes it to the skeleton. `frozen` (a
## hit-stop) holds every clock still.
func update(delta: float, frozen: bool = false) -> void:
	if skeleton == null or not is_inside_tree():
		return
	var step: float = 0.0 if frozen else delta
	var chosen: Array = _choose_clip(step)
	var wanted: StringName = chosen[0]
	var frame: float = chosen[1]
	if wanted != clip:
		_from_clip = clip
		_from_frame = clip_frame
		_blend_time = ACTION_BLEND_TIME if int(clip_info(wanted).get("windup", 0)) > 0 else BLEND_TIME
		_blend_left = _blend_time
		clip = wanted
		_count(wanted)
	clip_frame = frame
	var rotations: Array[Quaternion] = rest_rotations().duplicate()
	var offset: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
	_sample(clip, clip_frame, rotations, offset)
	if _blend_left > 0.0 and _from_clip != &"":
		_blend_left = maxf(0.0, _blend_left - step)
		var from_rotations: Array[Quaternion] = rest_rotations().duplicate()
		var from_offset: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
		_sample(_from_clip, _from_frame, from_rotations, from_offset)
		var weight: float = 1.0 - _blend_left / maxf(_blend_time, 0.001)
		_mix(rotations, offset, from_rotations, from_offset, weight)
	# A full-body one-shot wins over the base clip while it plays.
	if _one_shot != &"":
		_one_shot_frame += step * FPS
		var info: Dictionary = clip_info(_one_shot)
		if _one_shot_frame >= float(info["frames"]):
			_one_shot = &""
		else:
			var shot_rotations: Array[Quaternion] = rest_rotations().duplicate()
			var shot_offset: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
			_sample(_one_shot, _one_shot_frame, shot_rotations, shot_offset)
			var fade: float = smoothstep(0.0, 4.0, _one_shot_frame) * (1.0 - smoothstep(float(info["frames"]) - 6.0, float(info["frames"]), _one_shot_frame))
			_mix(shot_rotations, shot_offset, rotations, offset, fade)
			rotations = shot_rotations
			offset = shot_offset
			foot_ik_weight = 1.0 if info["foot_ik"] else 0.0
	# An arm overlay replaces one arm.
	if _overlay != &"":
		_overlay_frame += step * FPS
		var overlay_info: Dictionary = clip_info(_overlay)
		if _overlay_frame >= float(overlay_info["frames"]):
			_overlay = &""
		else:
			var arm: Array[int] = ARM_R if _overlay == &"overhead_pocket_blessing" else ARM_L
			var over: Array[Quaternion] = rest_rotations().duplicate()
			var unused: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
			_sample(_overlay, _overlay_frame, over, unused)
			var fade_in: float = smoothstep(0.0, 3.0, _overlay_frame) * (1.0 - smoothstep(float(overlay_info["frames"]) - 4.0, float(overlay_info["frames"]), _overlay_frame))
			for bone: int in arm:
				rotations[bone] = rotations[bone].slerp(over[bone], fade_in)
			if _overlay == &"offhand_pocket_draw" or _overlay == &"overhead_pocket_blessing":
				grip_weight = 0.0
	_apply_jump(offset, step)
	pose_rotations = rotations
	hips_offset = offset[0]
	hips_scale = offset[1]
	for bone: int in HeroRigBuilder.BONE_COUNT:
		skeleton.set_bone_pose_rotation(bone, rotations[bone])
	skeleton.set_bone_pose_position(B.HIPS, HeroRigBuilder.local_rests()[B.HIPS].origin + hips_offset)
	skeleton.set_bone_pose_scale(B.HIPS, hips_scale)


## Stretch in the air, squash on landing (on the hips, so the whole hero follows).
func _apply_jump(offset: Array[Vector3], step: float) -> void:
	var state: StringName = actor.state_machine.current_name() if actor.is_multiplayer_authority() else actor.net_sync.remote_state
	var in_air: bool = state == &"jump"
	if in_air:
		var stretch: float = JUMP_STRETCH * clampf(absf(vertical_speed) / ActorBase.JUMP_VELOCITY, 0.25, 1.0)
		offset[1] = offset[1] * Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
	elif airborne:
		land_squash = 1.0
	airborne = in_air
	if land_squash > 0.0:
		offset[1] = offset[1] * Vector3(1.0 + JUMP_LAND_SQUASH * 0.6 * land_squash, 1.0 - JUMP_LAND_SQUASH * land_squash, 1.0 + JUMP_LAND_SQUASH * 0.6 * land_squash)
		offset[0] = offset[0] - Vector3(0.0, JUMP_LAND_DROP * land_squash, 0.0)
		land_squash = maxf(0.0, land_squash - step / JUMP_LAND_TIME)


## [clip, frame] for this tick, and the grip, draw and foot weights.
func _choose_clip(step: float) -> Array:
	var authority: bool = actor.is_multiplayer_authority()
	var state: StringName = actor.state_machine.current_name() if authority else actor.net_sync.remote_state
	var action: CombatActionResource = actor.current_action()
	var phase: int = actor.current_phase()
	var weapon_type: int = actor.loadout.weapon.weapon_type if actor.loadout.weapon != null else Weapon.LIGHT_SWORD
	var family: Array = WEAPON_CLIPS.get(weapon_type, WEAPON_CLIPS[Weapon.LIGHT_SWORD])
	_watch(action, phase, step)
	var fighting: bool = action != null or state == &"guard" or state == &"stagger" or (actor.sign_flow != null and actor.sign_flow.is_in_combat)
	_since_fight = 0.0 if fighting else _since_fight + step
	calm = _since_fight >= CALM_AFTER and weapon_type != Weapon.BOW
	draw_weight = 0.0
	foot_ik_weight = 1.0
	var picked: StringName = family[4]
	var frame: float = 0.0
	match state:
		&"downed":
			picked = &"downed_slump"
			frame = _loop_frame(picked, step)
		&"stagger":
			picked = &"stagger_reel"
			frame = _loop_frame(picked, step)
		&"dodge", &"attack":
			if action != null:
				picked = clip_for_action(action, weapon_type)
				frame = _action_frame(picked, action, phase)
				if action.command == Cmd.LIGHT and phase == ActionQueueComponent.Phase.RECOVERY and authority and actor.action_queue.winded:
					picked = &"winded_3rd_light_recovery"
					frame = clampf(_phase_progress(action, phase) * 33.0, 0.0, 33.0)
				if clip_info(picked).get("draw", false):
					draw_weight = smoothstep(0.0, 1.0, _phase_progress(action, phase)) if phase == ActionQueueComponent.Phase.WINDUP else 0.0
		&"guard":
			picked = &"guard_hold"
			frame = _loop_frame(picked, step)
		&"jump":
			picked = &"locomotion_run_cycle"
			frame = JUMP_RISE_FRAME if vertical_speed > 0.0 else JUMP_FALL_FRAME
		_:
			var rite: float = actor.input.hearth_rite_progress() if actor.input != null else 0.0
			if rite > 0.0:
				picked = &"hearth_rite_tuck"
				frame = rite * float(clip_info(picked)["frames"])
			else:
				var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
				if speed > WALK_START_SPEED:
					picked = &"locomotion_run_cycle"
					frame = _run_frame(speed, step)
				else:
					picked = &"idle_steward_calm" if calm else family[4]
					frame = _loop_frame(picked, step)
	var info: Dictionary = clip_info(picked)
	foot_ik_weight = 1.0 if info.get("foot_ik", true) and state != &"jump" else 0.0
	var two_handed: bool = HeroMeshAtelier.is_two_handed(weapon_type)
	# On the run the weapon rides one-handed in the low port, so the off hand swings free.
	grip_weight = 1.0 if two_handed and not calm and info.get("grip", false) else 0.0
	return [picked, frame]


## The clip an action plays for a weapon.
func clip_for_action(action: CombatActionResource, weapon_type: int) -> StringName:
	var family: Array = WEAPON_CLIPS.get(weapon_type, WEAPON_CLIPS[Weapon.LIGHT_SWORD])
	if action.effect == CombatActionResource.Effect.DODGE:
		return &"dodge_roll_evade"
	if action.effect == CombatActionResource.Effect.SHADOW_SANCTUARY:
		return &"shadow_sanctuary_brace"
	if action.uninked:
		return family[3] if action.command == Cmd.TRIGGER_BOTH_ULT else family[2]
	if action.is_card():
		var card: ScribeCardResource = ArsenalCatalog.current.card(action.card_id)
		if card != null and card.delivery == ScribeCardResource.Delivery.AT_CASTER:
			return &"card_invoke_at_caster"
		return CARD_CLIPS[clampi(action.grimoire_slot, 0, CARD_CLIPS.size() - 1)]
	if LIGHT_CLIPS.has(action.action_id):
		return LIGHT_CLIPS[action.action_id]
	if action.command == Cmd.LIGHT:
		return family[0]
	return family[1]


## Where in a clip an action is: its wind-up, active and recovery frames
## stretched onto the action's own (so 51 axe frames fit any swing's timing).
func _action_frame(clip_name: StringName, action: CombatActionResource, phase: int) -> float:
	var info: Dictionary = clip_info(clip_name)
	var frames: float = float(info.get("frames", 1))
	var windup: float = float(info.get("windup", 0))
	var active: float = float(info.get("active", 0))
	if windup <= 0.0:
		return clampf(_phase_progress(action, phase) * frames, 0.0, frames)
	var u: float = clampf(_phase_progress(action, phase), 0.0, 1.0)
	match phase:
		ActionQueueComponent.Phase.WINDUP:
			return u * windup
		ActionQueueComponent.Phase.ACTIVE:
			return lerpf(windup, active, u)
		ActionQueueComponent.Phase.RECOVERY:
			return lerpf(active, frames, u)
	return 0.0


## How far through its current phase an action is, 0 to 1.
func _phase_progress(action: CombatActionResource, phase: int) -> float:
	var elapsed: float = actor.action_queue.phase_time if actor.is_multiplayer_authority() else _watched_clock
	var length: float = 1.0
	match phase:
		ActionQueueComponent.Phase.WINDUP:
			length = action.windup_time
		ActionQueueComponent.Phase.ACTIVE:
			length = action.active_time
		ActionQueueComponent.Phase.RECOVERY:
			length = actor.action_queue.recovery_time if actor.is_multiplayer_authority() and actor.action_queue.recovery_time > 0.0 else action.recovery_time
	return clampf(elapsed / maxf(length, 0.001), 0.0, 1.0)


## Another peer's copy has no phase clock of its own: time each phase as it's seen.
func _watch(action: CombatActionResource, phase: int, step: float) -> void:
	var id: StringName = action.action_id if action != null else &""
	if id != _watched_action or phase != _watched_phase:
		_watched_action = id
		_watched_phase = phase
		_watched_clock = 0.0
	else:
		_watched_clock += step


func _loop_frame(clip_name: StringName, step: float) -> float:
	_idle_frame += step * FPS
	var frames: float = float(clip_info(clip_name).get("frames", 60))
	return fmod(_idle_frame, frames)


## The run cycle advances with distance, so feet never skate; plants call out on frames 4 and 18.
func _run_frame(speed: float, step: float) -> float:
	var before: float = _cycle * RUN_CYCLE_FRAMES
	_cycle = fmod(_cycle + speed * step / RUN_CYCLE_METRES, 1.0)
	var after: float = _cycle * RUN_CYCLE_FRAMES
	for plant: int in FOOT_PLANT_FRAMES:
		var crossed: bool = (before < plant and after >= plant) if after >= before else (before < plant or after >= plant)
		if crossed:
			feet_planted += 1
			foot_planted.emit(plant == FOOT_PLANT_FRAMES[0])
	return after


func _count(clip_name: StringName) -> void:
	played[clip_name] = played.get(clip_name, 0) + 1


static func _sample(clip_name: StringName, frame: float, rotations: Array[Quaternion], offset: Array[Vector3]) -> void:
	var book: AnimationLibrary = library()
	var animation: Animation = book.get_animation(clip_name) if book.has_animation(clip_name) else null
	if animation == null:
		return
	var t: float = clampf(frame / FPS, 0.0, animation.length)
	var rest_hips: Vector3 = HeroRigBuilder.local_rests()[B.HIPS].origin
	for entry: Array in _tracks[clip_name]:
		var track: int = entry[0]
		match int(entry[1]):
			Animation.TYPE_ROTATION_3D:
				rotations[int(entry[2])] = animation.rotation_track_interpolate(track, t).normalized()
			Animation.TYPE_POSITION_3D:
				offset[0] = animation.position_track_interpolate(track, t) - rest_hips
			Animation.TYPE_SCALE_3D:
				offset[1] = animation.scale_track_interpolate(track, t)


## Blends `into` toward `from` by (1 - weight): weight 1 keeps `into`.
static func _mix(into: Array[Quaternion], into_offset: Array[Vector3], from: Array[Quaternion], from_offset: Array[Vector3], weight: float) -> void:
	for bone: int in into.size():
		into[bone] = from[bone].slerp(into[bone], weight)
	into_offset[0] = from_offset[0].lerp(into_offset[0], weight)
	into_offset[1] = from_offset[1].lerp(into_offset[1], weight)
