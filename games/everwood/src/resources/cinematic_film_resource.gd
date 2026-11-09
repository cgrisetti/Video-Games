## A whole film (docs/31): the opening prologue is the first. Its shots end to end on one
## clock, its caption style and palette, when control comes back, who may skip and how,
## the late-joiner's recap, and where it hands the player over. Built from the timeline
## JSON by CinematicCatalog (the JSON is the source of truth: no number here is typed by hand).
class_name CinematicFilmResource
extends Resource

const EASE_LINEAR: StringName = &"linear"
const EASE_IN_OUT_SINE: StringName = &"in_out_sine"
const EASE_IN_OUT_CUBIC: StringName = &"in_out_cubic"
const EASE_OUT_CUBIC: StringName = &"out_cubic"
const EASE_OUT_BACK: StringName = &"out_back"
## The curves the timeline may name.
const EASES: Array[StringName] = [EASE_LINEAR, EASE_IN_OUT_SINE, EASE_IN_OUT_CUBIC, EASE_OUT_CUBIC, EASE_OUT_BACK]
## out_back's overshoot (the classic 1.70158).
const BACK_OVERSHOOT: float = 1.70158

@export var film_id: StringName = &""
@export var version: int = 0
@export var duration_s: float = 0.0
@export var resolution_ref: Vector2i = Vector2i(1920, 1080)
@export var narrator: String = ""
## The folder the timeline's art paths start from (res://, ending in /).
@export var source_folder: String = ""

@export_group("Captions")
@export var caption_font: String = ""
@export var caption_size_px_at_1080p: int = 0
@export var caption_color: Color = Color.BLACK
## The ribbon behind the words, its opacity in alpha.
@export var caption_ribbon_color: Color = Color.WHITE
@export var caption_position: StringName = &""
@export var captions_always_on: bool = true

@export_group("Shots")
@export var palette: Dictionary[StringName, Color] = {}
@export var shots: Array[CinematicShotResource] = []
## Control comes back at this second.
@export var control_unlock_s: float = 0.0

@export_group("Skip")
## "host_only", "seat_1", "host_peer".
@export var skip_who: StringName = &""
@export var skip_local_host: StringName = &""
@export var skip_online_host: StringName = &""
@export var skip_input: String = ""
@export var skip_hold_s: float = 0.0
@export var skip_non_host_hint: String = ""
@export var skip_result: String = ""

@export_group("Recap")
@export var recap_for: String = ""
## Each recap page's plate name, in order (the plate file's name without its extension).
@export var recap_plates: PackedStringArray = PackedStringArray()
@export var recap_seconds_per_plate: float = 0.0
@export var recap_captions: bool = true
@export var recap_skippable_by: String = ""
@export var recap_scope: String = ""

@export_group("Hand-over")
## The player-facing name of where the film hands over ("Embershore").
@export var spawn_zone_name: String = ""
@export var spawn_sub_zone: String = ""
## The marker the spawn should face ("OrchardGate").
@export var spawn_face_toward: StringName = &""
## The design's proposed spots (the World Map Bible's frame; NAN where it gave no height).
@export var spawn_proposed_m: Vector3 = Vector3.ZERO
@export var orchard_gate_proposed_m: Vector3 = Vector3.ZERO
@export var spawn_framing_goal: String = ""
## The camera rig's numbers as the design quoted them (doc 18): the live rig is read at run time.
@export var rig_pitch_deg: float = 0.0
@export var rig_height_m: float = 0.0
@export var rig_boom_m: float = 0.0


## `t` (0 to 1) along a named curve; an unknown name runs straight.
static func eased(curve: StringName, t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	match curve:
		EASE_IN_OUT_SINE:
			return -(cos(PI * x) - 1.0) * 0.5
		EASE_IN_OUT_CUBIC:
			return 4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) * 0.5
		EASE_OUT_CUBIC:
			return 1.0 - pow(1.0 - x, 3.0)
		EASE_OUT_BACK:
			var c3: float = BACK_OVERSHOOT + 1.0
			return 1.0 + c3 * pow(x - 1.0, 3.0) + BACK_OVERSHOOT * pow(x - 1.0, 2.0)
	return x


## The shot on screen at `at_s` (the last one from its start on; the first before 0).
func shot_at(at_s: float) -> CinematicShotResource:
	var found: CinematicShotResource = shots[0] if not shots.is_empty() else null
	for shot: CinematicShotResource in shots:
		if at_s >= shot.start_s:
			found = shot
	return found


## The shot after `shot`, or null.
func next_shot(shot: CinematicShotResource) -> CinematicShotResource:
	var at: int = shots.find(shot)
	return shots[at + 1] if at >= 0 and at + 1 < shots.size() else null


## The live 3D shot (the dive), or null.
func live_shot() -> CinematicShotResource:
	for shot: CinematicShotResource in shots:
		if shot.is_live():
			return shot
	return null


## Every caption of every shot, in order.
func all_captions() -> Array[CinematicCaptionResource]:
	var list: Array[CinematicCaptionResource] = []
	for shot: CinematicShotResource in shots:
		list.append_array(shot.captions)
	list.sort_custom(func(a: CinematicCaptionResource, b: CinematicCaptionResource) -> bool: return a.start_s < b.start_s)
	return list


## The caption showing at `at_s`, or null.
func caption_at(at_s: float) -> CinematicCaptionResource:
	for caption: CinematicCaptionResource in all_captions():
		if caption.covers(at_s):
			return caption
	return null


## Every audio cue of every shot, in time order.
func all_cues() -> Array[CinematicCueResource]:
	var list: Array[CinematicCueResource] = []
	for shot: CinematicShotResource in shots:
		list.append_array(shot.cues)
	list.sort_custom(func(a: CinematicCueResource, b: CinematicCueResource) -> bool: return a.at_s < b.at_s)
	return list


## The first effect of a kind anywhere in the film, or null.
func effect(effect_kind: StringName) -> CinematicEffectResource:
	for shot: CinematicShotResource in shots:
		var found: CinematicEffectResource = shot.effect(effect_kind)
		if found != null:
			return found
	return null


## The recap's pages: each recap plate's shot, in the recap's order (a plate no shot draws is skipped).
func recap_shots() -> Array[CinematicShotResource]:
	var list: Array[CinematicShotResource] = []
	for plate_name: String in recap_plates:
		for shot: CinematicShotResource in shots:
			if shot.any_plate().get_file().get_basename() == plate_name:
				list.append(shot)
				break
	return list


## A palette colour by its name ("hush_grey"), or `fallback`.
func colour(colour_name: StringName, fallback: Color = Color.WHITE) -> Color:
	return palette.get(colour_name, fallback)
