## The Caldera's one seam scene with two skins (docs/20 Part I §3; the Musk
## Razor's "1 seam scene, 2 skins"):
##
##   Skin A, a walkable causeway or shingle spit (the West Strait, Eel Spit):
##   as the Soul Tether centroid walks out along the 128 m corridor, sea-fog
##   rolls in (the sea, the sky and the horizon silhouettes fade into it); at
##   the corridor's middle, in the thickest fog, the departing island unloads,
##   the next one streams in and the party is moved into its frame without a
##   step lost; the fog thins again as they walk ashore.
##
##   Skin B, a Lantern-Skiff bell lane (the Salt Road, the Crown Landing): a
##   rung Chime-Bell seats the whole party on a skiff, the cameras lift, and it
##   glides six seconds over the mist-shrouded Sound, swapping islands at the
##   halfway mark, and docks at the far quay.
##
## The host decides every crossing; the level tells every peer to make it.
class_name SeamTransitionController
extends Node

signal mist_changed(amount: float)
signal skiff_started(seam_id: StringName)
signal crossing_finished(seam_id: StringName, to_isle: StringName)

## The fog's rise from either shore along a corridor (metres from the shore).
const MIST_START: float = 18.0
const MIST_FULL: float = 50.0
## The centroid counts as on a corridor this far either side of its line.
const CORRIDOR_REACH: float = 14.0
## The swap happens this far past the middle (so a party standing on it doesn't flicker).
const SWAP_MARGIN: float = 2.0
const SKIFF_SECONDS: float = 6.0
## How far the cameras lift for the glide (degrees).
const SKIFF_CAMERA_PITCH: float = 30.0
## The skiff's seats (its frame, bow toward -Z).
const DECK_SPOTS: Array[Vector3] = [Vector3(-0.7, 0.7, -2.4), Vector3(0.7, 0.7, -2.4), Vector3(-0.7, 0.7, 0.2), Vector3(0.7, 0.7, 0.2), Vector3(0.0, 0.7, 2.6)]

var level: CalderaArchipelagoWorld
var mist: float = 0.0
## Crossings finished this session (tests and the telemetry line).
var crossings: int = 0
## The skiff glide under way, or null.
var skiff_seam: LoadSeamResource
var skiff_time: float = 0.0

var _skiff_from: StringName = &""
var _skiff_swapped: bool = false
var _skiff: Node3D
var _pitches: Dictionary[int, float] = {}


## How thick the sea-fog is `s` metres along a corridor `length` long.
static func mist_at(length: float, s: float) -> float:
	return smoothstep(MIST_START, MIST_FULL, s) * smoothstep(MIST_START, MIST_FULL, length - s)


func _physics_process(delta: float) -> void:
	if level == null or level.streamer.builder == null:
		return
	if skiff_seam != null:
		_glide(delta)
		return
	var isle_id: StringName = level.streamer.active_isle
	var centroid: Vector3 = level.tether_centroid()
	var thickest: float = 0.0
	for seam: LoadSeamResource in CalderaAtlas.seams_of(isle_id):
		if seam.skin != LoadSeamResource.SeamSkin.WALKABLE_CAUSEWAY or seam.corridor_offset(isle_id, centroid) > CORRIDOR_REACH:
			continue
		var s: float = seam.corridor_s(isle_id, centroid)
		if s < -4.0 or s > seam.length_m + 4.0:
			continue
		thickest = maxf(thickest, mist_at(seam.length_m, s))
		var half: float = seam.length_m * 0.5
		var past: bool = s > half + SWAP_MARGIN if isle_id == seam.isle_a else s < half - SWAP_MARGIN
		if past and level.may_decide():
			level.request_seam_swap(seam.seam_id, isle_id)
			break
	_set_mist(thickest)


func _set_mist(amount: float) -> void:
	if is_equal_approx(amount, mist):
		return
	mist = amount
	level.streamer.set_mist(amount)
	if WorldAtmosphereDirector.current != null:
		WorldAtmosphereDirector.current.seam_mist = amount
	mist_changed.emit(amount)


## A walkable seam's swap (every peer, told by the host): the party walks on in the other island's frame.
func swap_walkable(seam: LoadSeamResource, from_isle: StringName) -> void:
	var to_isle: StringName = seam.other(from_isle)
	level.swap_island(to_isle, seam.remap_offset(from_isle), &"arrival" if to_isle != CalderaAtlas.ISLE_OAKSHIRE_HOLM else &"")
	crossings += 1
	crossing_finished.emit(seam.seam_id, to_isle)


# --- Skin B: the Lantern-Skiff ----------------------------------------------------------

## Starts the six-second glide (every peer, told by the host).
func start_skiff(seam: LoadSeamResource, from_isle: StringName) -> void:
	if skiff_seam != null:
		return
	skiff_seam = seam
	skiff_time = 0.0
	_skiff_from = from_isle
	_skiff_swapped = false
	_skiff = Node3D.new()
	_skiff.name = "LanternSkiff"
	var hull: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_skiff(hull)
	_skiff.add_child(CalderaKit.mesh_node("Hull", hull))
	CalderaKit.light(_skiff, "Lantern", Vector3(0.0, 3.0, -4.6), CalderaKit.SAFFRON, 2.2, 14.0)
	level.add_child(_skiff)
	_pitches.clear()
	for seat: int in range(1, 6):
		var pitch: float = level.get_camera_pitch_degrees(seat)
		if not is_nan(pitch):
			_pitches[seat] = pitch
			level.set_camera_pitch_degrees(seat, SKIFF_CAMERA_PITCH)
	AudioCues.play(&"portal_charge")
	_place_skiff()
	skiff_started.emit(seam.seam_id)


func is_gliding() -> bool:
	return skiff_seam != null


func _glide(delta: float) -> void:
	skiff_time += delta
	var t: float = clampf(skiff_time / SKIFF_SECONDS, 0.0, 1.0)
	if not _skiff_swapped and t >= 0.5:
		_skiff_swapped = true
		level.swap_island(skiff_seam.other(_skiff_from), skiff_seam.remap_offset(_skiff_from), &"")
	_place_skiff()
	var s: float = _corridor_s()
	_set_mist(maxf(mist_at(skiff_seam.length_m, s), 0.35 * sin(t * PI)))
	if t >= 1.0:
		_dock()


func _corridor_s() -> float:
	var t: float = clampf(skiff_time / SKIFF_SECONDS, 0.0, 1.0)
	return skiff_seam.length_m * t if _skiff_from == skiff_seam.isle_a else skiff_seam.length_m * (1.0 - t)


func _place_skiff() -> void:
	var isle_id: StringName = level.streamer.active_isle
	var at: Vector3 = skiff_seam.point_at(isle_id, _corridor_s())
	var travel: Vector3 = skiff_seam.direction_3d() if _skiff_from == skiff_seam.isle_a else -skiff_seam.direction_3d()
	var sea: float = CalderaWorldState.current.sea_level_y if CalderaWorldState.current != null else 0.0
	var bob: float = 0.15 * sin(skiff_time * 2.2)
	_skiff.global_transform = Transform3D(Basis(Vector3.UP, atan2(-travel.x, -travel.z)).rotated(travel.cross(Vector3.UP).normalized(), 0.02 * sin(skiff_time * 1.7)),
		Vector3(at.x, sea + 0.1 + bob, at.z))
	var seat: int = 0
	for actor: ActorBase in level.party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		var spot: Vector3 = _skiff.global_transform * DECK_SPOTS[seat % DECK_SPOTS.size()]
		actor.place_at(Transform3D(_skiff.global_transform.basis.orthonormalized(), spot))
		seat += 1


func _dock() -> void:
	var to_isle: StringName = skiff_seam.other(_skiff_from)
	var arrival: StringName = CalderaAtlas.ARRIVE_NORTH_QUAY
	match to_isle:
		CalderaAtlas.ISLE_THE_CROWN:
			arrival = CalderaAtlas.ARRIVE_SOUTH_BAY
		CalderaAtlas.ISLE_RIME_FIRTH:
			arrival = CalderaAtlas.ARRIVE_QUAY
	level.place_party_at(arrival)
	for seat: int in _pitches:
		level.set_camera_pitch_degrees(seat, _pitches[seat])
	_pitches.clear()
	_skiff.queue_free()
	_skiff = null
	var seam_id: StringName = skiff_seam.seam_id
	skiff_seam = null
	_set_mist(0.0)
	crossings += 1
	AudioCues.play(&"portal")
	crossing_finished.emit(seam_id, to_isle)
