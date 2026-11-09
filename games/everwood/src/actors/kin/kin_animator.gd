## A kin's frame-locked animation (docs/30_KIN_DESIGN_LANGUAGE.md §8), the heroes'
## HeroCombatAnimator in small. Each look bakes its family's clips (KinClipBook) onto
## its own rest as one procedural AnimationLibrary ("kin_<look>") of rotation tracks
## and the core bone's position and scale, keyed at 60 Hz with cubic interpolation;
## its AnimationPlayer stays inactive. Every update picks the clip for what the kin
## is doing and samples it at the exact frame its state says: a blow's wind-up,
## active and recovery frames are stretched onto the action's own, so the telegraph
## a hero reads is the pose they see; a gait advances with the ground covered, so
## feet never skate. Clips cross-fade, a hit flinches over the rest, and the calm,
## the scatter and a steward's bow play out on every peer.
class_name KinAnimator
extends Node

const FPS: float = 60.0
const SKELETON_PATH: String = KinRigBuilder.SKELETON_NAME
const BLEND_TIME: float = 0.16
const ACTION_BLEND_TIME: float = 0.06
## Below this speed (m/s) it stands; the run takes over from the look's run speed.
const WALK_START_SPEED: float = 0.3
## Looks with their own way of standing and walking.
const IDLE_BY_LOOK: Dictionary[StringName, StringName] = {
	KinLooks.ASH_GRIG: &"idle_crouch", KinLooks.BOG_HULK: &"idle_hunch", KinLooks.TIDE_WIGHT: &"idle_float",
}
const WALK_BY_LOOK: Dictionary[StringName, StringName] = {KinLooks.ASH_GRIG: &"walk_crouch", KinLooks.TIDE_WIGHT: &"walk_float"}
const RUN_BY_LOOK: Dictionary[StringName, StringName] = {KinLooks.ASH_GRIG: &"walk_crouch", KinLooks.TIDE_WIGHT: &"walk_float"}

static var _libraries: Dictionary[StringName, AnimationLibrary] = {}
static var _info: Dictionary[StringName, Dictionary] = {}
## Per look and clip: [track, type, bone] for every track.
static var _tracks: Dictionary[StringName, Dictionary] = {}

var look: StringName = &""
var rig: KinRig
var skeleton: Skeleton3D
var player: AnimationPlayer
## The clip playing as the base pose, and its frame.
var clip: StringName = &"idle"
var clip_frame: float = 0.0
## How many times each clip has started on this kin (for checks).
var played: Dictionary[StringName, int] = {}
## The pose last written: each bone's local rotation, the core bone's offset and scale.
var pose_rotations: Array[Quaternion] = []
var core_offset: Vector3 = Vector3.ZERO
var core_scale: Vector3 = Vector3.ONE

var _core: int = 1
var _rests: Array[Quaternion] = []
var _from_clip: StringName = &""
var _from_frame: float = 0.0
var _blend_left: float = 0.0
var _blend_time: float = BLEND_TIME
var _loop_clock: float = 0.0
var _hold_frame: float = 0.0
var _hold_clip: StringName = &""
var _cycle: float = 0.0
var _hit_frame: float = -1.0
var _watched_action: StringName = &""
var _watched_phase: int = -1
var _watched_clock: float = 0.0


func setup(for_look: StringName, for_rig: KinRig, for_skeleton: Skeleton3D) -> void:
	look = for_look
	rig = for_rig
	skeleton = for_skeleton
	name = "KinAnimator"
	_core = rig.b(KinClipBook.CORE[rig.rig])
	for local: Transform3D in rig.locals:
		_rests.append(local.basis.get_rotation_quaternion())
	pose_rotations = _rests.duplicate()


func _ready() -> void:
	player = AnimationPlayer.new()
	player.name = "KinAnimationPlayer"
	add_child(player)
	player.root_node = player.get_path_to(skeleton.get_parent())
	player.add_animation_library(StringName("kin_" + String(look)), library(look))
	player.active = false


# --- The library ----------------------------------------------------------------

## The look's baked AnimationLibrary (built once a look).
static func library(for_look: StringName) -> AnimationLibrary:
	if not _libraries.has(for_look):
		_bake(for_look)
	return _libraries[for_look]


## A clip's frame data for a look: "frames", "loop", "windup", "active", "hold".
static func clip_info(for_look: StringName, clip_name: StringName) -> Dictionary:
	library(for_look)
	return (_info[for_look] as Dictionary).get(clip_name, {})


static func has_clip(for_look: StringName, clip_name: StringName) -> bool:
	return not clip_info(for_look, clip_name).is_empty()


static func clip_names(for_look: StringName) -> Array[StringName]:
	library(for_look)
	var names: Array[StringName] = []
	names.assign((_info[for_look] as Dictionary).keys())
	return names


static func _bake(for_look: StringName) -> void:
	var r: KinRig = KinSculptor.rig(for_look)
	var family: int = r.rig
	var size: float = float(KinLooks.spec(for_look)["height"]) / KinClipBook.REFERENCE_HEIGHT[family]
	if family == KinRigBuilder.Rig.BIPED:
		size = 1.0
	var core: int = r.b(KinClipBook.CORE[family])
	var rests: Array[Quaternion] = []
	var rest_globals: Array[Quaternion] = []
	for index: int in r.count():
		rests.append(r.locals[index].basis.get_rotation_quaternion())
		rest_globals.append(r.globals[index].basis.get_rotation_quaternion())
	var made: AnimationLibrary = AnimationLibrary.new()
	var infos: Dictionary = {}
	var tracks: Dictionary = {}
	for entry: Array in KinClipBook.clips(family):
		var clip_name: StringName = entry[0]
		var spec: Dictionary = entry[1]
		var frames: int = spec["frames"]
		var animation: Animation = Animation.new()
		animation.length = float(frames) / FPS
		animation.step = 1.0 / FPS
		animation.loop_mode = Animation.LOOP_LINEAR if spec["loop"] else Animation.LOOP_NONE
		var keys: Array = spec["keys"]
		var touched: Dictionary[int, bool] = {}
		for key: Array in keys:
			var pose: Dictionary = key[1]
			for group: String in ["e", "w"]:
				for bone_name: Variant in pose.get(group, {}):
					var bone: int = r.b(StringName(bone_name))
					if bone >= 0:
						touched[bone] = true
		var entries: Array = []
		var bones: Array[int] = []
		bones.assign(touched.keys())
		bones.sort()
		for bone: int in bones:
			var track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, NodePath("%s:%s" % [SKELETON_PATH, r.names[bone]]))
			animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
			for key: Array in keys:
				var pose: Dictionary = key[1]
				var offset: Quaternion = Quaternion.IDENTITY
				var world: Dictionary = pose.get("w", {})
				var turned: Variant = world.get(r.names[bone], world.get(String(r.names[bone]), null))
				if turned != null:
					var q: Quaternion = Quaternion.from_euler((turned as Vector3) * (PI / 180.0))
					offset = rest_globals[bone].inverse() * q * rest_globals[bone]
				var local: Dictionary = pose.get("e", {})
				var bent: Variant = local.get(r.names[bone], local.get(String(r.names[bone]), null))
				if bent != null:
					offset = offset * Quaternion.from_euler((bent as Vector3) * (PI / 180.0))
				animation.rotation_track_insert_key(track, float(key[0]) / FPS, (rests[bone] * offset).normalized())
			entries.append([track, Animation.TYPE_ROTATION_3D, bone])
		var position_track: int = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(position_track, NodePath("%s:%s" % [SKELETON_PATH, r.names[core]]))
		animation.track_set_interpolation_type(position_track, Animation.INTERPOLATION_CUBIC)
		var scale_track: int = animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(scale_track, NodePath("%s:%s" % [SKELETON_PATH, r.names[core]]))
		for key: Array in keys:
			var pose: Dictionary = key[1]
			animation.position_track_insert_key(position_track, float(key[0]) / FPS, r.locals[core].origin + (pose.get("root", Vector3.ZERO) as Vector3) * size)
			animation.scale_track_insert_key(scale_track, float(key[0]) / FPS, pose.get("scale", Vector3.ONE))
		entries.append([position_track, Animation.TYPE_POSITION_3D, core])
		entries.append([scale_track, Animation.TYPE_SCALE_3D, core])
		made.add_animation(clip_name, animation)
		tracks[clip_name] = entries
		infos[clip_name] = {"frames": frames, "loop": spec["loop"], "windup": spec["windup"], "active": spec["active"], "hold": spec["hold"]}
	_libraries[for_look] = made
	_info[for_look] = infos
	_tracks[for_look] = tracks


## A clip's pose at a frame: {"rotations": each bone's local rotation, "offset": the core's offset, "scale"}.
static func sample_pose(for_look: StringName, clip_name: StringName, frame: float) -> Dictionary:
	var r: KinRig = KinSculptor.rig(for_look)
	var rotations: Array[Quaternion] = []
	for local: Transform3D in r.locals:
		rotations.append(local.basis.get_rotation_quaternion())
	var core: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
	_sample(for_look, clip_name, frame, rotations, core)
	return {"rotations": rotations, "offset": core[0], "scale": core[1]}


static func _sample(for_look: StringName, clip_name: StringName, frame: float, rotations: Array[Quaternion], core: Array[Vector3]) -> void:
	var book: AnimationLibrary = library(for_look)
	if not book.has_animation(clip_name):
		return
	var animation: Animation = book.get_animation(clip_name)
	var t: float = clampf(frame / FPS, 0.0, animation.length)
	var r: KinRig = KinSculptor.rig(for_look)
	for entry: Array in (_tracks[for_look] as Dictionary)[clip_name]:
		var track: int = entry[0]
		match int(entry[1]):
			Animation.TYPE_ROTATION_3D:
				rotations[int(entry[2])] = animation.rotation_track_interpolate(track, t).normalized()
			Animation.TYPE_POSITION_3D:
				core[0] = animation.position_track_interpolate(track, t) - r.locals[int(entry[2])].origin
			Animation.TYPE_SCALE_3D:
				core[1] = animation.scale_track_interpolate(track, t)


# --- Playing ---------------------------------------------------------------------

## The clip for this tick from what the kin is doing (KinFigure reads it off the actor),
## sampled and written to the skeleton. `step` 0 holds every clock (a hit-stop).
func update(step: float, wanted: StringName, frame_lock: float = -1.0, speed: float = 0.0, cycle_metres: float = 1.5) -> void:
	if skeleton == null:
		return
	if not has_clip(look, wanted):
		wanted = &"idle"
	var info: Dictionary = clip_info(look, wanted)
	var frames: float = float(info.get("frames", 60))
	if wanted != clip:
		_from_clip = clip
		_from_frame = clip_frame
		_blend_time = ACTION_BLEND_TIME if int(info.get("windup", 0)) > 0 else BLEND_TIME
		_blend_left = _blend_time
		clip = wanted
		played[wanted] = int(played.get(wanted, 0)) + 1
		if info.get("hold", false) or not info.get("loop", false):
			_hold_frame = 0.0
			_hold_clip = wanted
	var frame: float = 0.0
	if frame_lock >= 0.0:
		frame = frame_lock
	elif info.get("loop", false):
		if speed > 0.0:
			# A gait: one cycle a stride's ground, so feet keep to it.
			_cycle = fposmod(_cycle + speed * step / maxf(cycle_metres, 0.05), 1.0)
			frame = _cycle * frames
		else:
			_loop_clock += step * FPS
			frame = fmod(_loop_clock, frames)
	else:
		_hold_frame = minf(_hold_frame + step * FPS, frames)
		frame = _hold_frame
	clip_frame = frame
	var rotations: Array[Quaternion] = _rests.duplicate()
	var core: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
	_sample(look, clip, clip_frame, rotations, core)
	if _blend_left > 0.0 and _from_clip != &"":
		_blend_left = maxf(0.0, _blend_left - step)
		var from_rotations: Array[Quaternion] = _rests.duplicate()
		var from_core: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
		_sample(look, _from_clip, _from_frame, from_rotations, from_core)
		_mix(rotations, core, from_rotations, from_core, 1.0 - _blend_left / maxf(_blend_time, 0.001))
	if _hit_frame >= 0.0:
		# A flinch over whatever it's doing, fading in and out.
		_hit_frame += step * FPS
		var hit_frames: float = float(clip_info(look, &"hit").get("frames", 16))
		if _hit_frame >= hit_frames:
			_hit_frame = -1.0
		else:
			var hit_rotations: Array[Quaternion] = _rests.duplicate()
			var hit_core: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
			_sample(look, &"hit", _hit_frame, hit_rotations, hit_core)
			var weight: float = sin(clampf(_hit_frame / hit_frames, 0.0, 1.0) * PI) * 0.7
			for bone: int in rotations.size():
				rotations[bone] = rotations[bone] * (_rests[bone].inverse() * hit_rotations[bone]).slerp(Quaternion.IDENTITY, 1.0 - weight)
			core[0] += hit_core[0] * weight
	pose_rotations = rotations
	core_offset = core[0]
	core_scale = core[1]
	for bone: int in rotations.size():
		skeleton.set_bone_pose_rotation(bone, rotations[bone])
	skeleton.set_bone_pose_position(_core, rig.locals[_core].origin + core_offset)
	skeleton.set_bone_pose_scale(_core, core_scale)


## A flinch from a blow (on every peer, layered over the clip).
func flinch() -> void:
	if has_clip(look, &"hit"):
		_hit_frame = 0.0
		played[&"hit"] = int(played.get(&"hit", 0)) + 1


## How far a one-shot clip has played, 0 to 1.
func one_shot_progress() -> float:
	var frames: float = float(clip_info(look, clip).get("frames", 1))
	return clampf(_hold_frame / maxf(frames, 1.0), 0.0, 1.0)


## The frame of a blow's clip for an action's phase and how far through it is (the hero's rule).
func action_frame(clip_name: StringName, phase: int, progress: float) -> float:
	var info: Dictionary = clip_info(look, clip_name)
	var frames: float = float(info.get("frames", 1))
	var windup: float = float(info.get("windup", 0))
	var active: float = float(info.get("active", 0))
	var u: float = clampf(progress, 0.0, 1.0)
	if windup <= 0.0:
		return u * frames
	match phase:
		ActionQueueComponent.Phase.WINDUP:
			return u * windup
		ActionQueueComponent.Phase.ACTIVE:
			return lerpf(windup, active, u)
		ActionQueueComponent.Phase.RECOVERY:
			return lerpf(active, frames, u)
	return 0.0


## Another peer's copy has no phase clock of its own: each phase is timed as it's seen.
func watched_progress(action: CombatActionResource, phase: int, step: float) -> float:
	var id: StringName = action.action_id if action != null else &""
	if id != _watched_action or phase != _watched_phase:
		_watched_action = id
		_watched_phase = phase
		_watched_clock = 0.0
	else:
		_watched_clock += step
	if action == null:
		return 0.0
	var length: float = 1.0
	match phase:
		ActionQueueComponent.Phase.WINDUP:
			length = action.windup_time
		ActionQueueComponent.Phase.ACTIVE:
			length = action.active_time
		ActionQueueComponent.Phase.RECOVERY:
			length = action.recovery_time
	return clampf(_watched_clock / maxf(length, 0.001), 0.0, 1.0)


static func _mix(into: Array[Quaternion], into_core: Array[Vector3], from: Array[Quaternion], from_core: Array[Vector3], weight: float) -> void:
	for bone: int in into.size():
		into[bone] = from[bone].slerp(into[bone], weight)
	into_core[0] = from_core[0].lerp(into_core[0], weight)
	into_core[1] = from_core[1].lerp(into_core[1], weight)
