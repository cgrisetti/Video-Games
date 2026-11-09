## One shot of a film (docs/31): its stretch of the film's clock, what it shows (a 2D
## storybook plate panned and zoomed, or the live 3D world with a camera diving into the
## player's own camera rig), its effects, how it hands over to the next shot, and its
## captions and audio cues. Read from the timeline JSON by CinematicCatalog.
class_name CinematicShotResource
extends Resource

## The two layers a shot can be on.
const LAYER_STORYBOOK: StringName = &"storybook_2d"
const LAYER_LIVE: StringName = &"live_3d"
## The two camera kinds.
const CAMERA_PAN_ZOOM: StringName = &"pan_zoom"
const CAMERA_DIVE_TO_RIG: StringName = &"camera3d_dive_to_rig"
## The three hand-overs to the next shot.
const CROSSFADE: StringName = &"crossfade"
const PAGE_TURN: StringName = &"page_turn"
const PAGE_DISSOLVE_TO_3D: StringName = &"page_dissolve_to_3d"

@export var index: int = 0
@export var shot_id: StringName = &""
@export var title: String = ""
@export var start_s: float = 0.0
@export var end_s: float = 0.0
@export var layer: StringName = LAYER_STORYBOOK
## The plate drawn on screen (res:// path), for a storybook shot.
@export var plate_path: String = ""
## A live shot's composition reference (res:// path): drawn only in the late-joiner's recap.
@export var reference_plate_path: String = ""

@export_group("Camera")
@export var camera_kind: StringName = CAMERA_PAN_ZOOM
## pan_zoom: the plate's framing at the shot's start and end (scale 1 = the plate covers the screen).
@export var pan_from_scale: float = 1.0
@export var pan_from_center: Vector2 = Vector2(0.5, 0.5)
@export var pan_to_scale: float = 1.0
@export var pan_to_center: Vector2 = Vector2(0.5, 0.5)
@export var camera_ease: StringName = &"linear"
## camera3d_dive_to_rig: when the dive runs, and where it starts from in the rig's frame
## (x right, y up, z back) before easing to the rig's exact pose.
@export var dive_start_s: float = 0.0
@export var dive_end_s: float = 0.0
@export var dive_start_offset: Vector3 = Vector3.ZERO
@export var dive_offset_space: String = ""
## The hand-off's tolerance: the dive's last frame and the rig's pose may differ by no more than these.
@export var handoff_position_m: float = 0.01
@export var handoff_angle_deg: float = 0.1

@export_group("Hand-over and words")
@export var transition_kind: StringName = &""
@export var transition_s: float = 0.0
@export var effects: Array[CinematicEffectResource] = []
@export var captions: Array[CinematicCaptionResource] = []
@export var cues: Array[CinematicCueResource] = []


func is_live() -> bool:
	return layer == LAYER_LIVE


## The plate to draw for this shot: its own, or (a live shot) its composition reference.
func any_plate() -> String:
	return plate_path if plate_path != "" else reference_plate_path


## How far through the shot's framing it is at `at_s`, 0 to 1 (eased; held before and after).
func camera_progress(at_s: float) -> float:
	if end_s <= start_s:
		return 1.0
	return CinematicFilmResource.eased(camera_ease, clampf((at_s - start_s) / (end_s - start_s), 0.0, 1.0))


## The dive's progress at `at_s`, 0 to 1 (eased).
func dive_progress(at_s: float) -> float:
	if dive_end_s <= dive_start_s:
		return 1.0 if at_s >= dive_start_s else 0.0
	return CinematicFilmResource.eased(camera_ease, clampf((at_s - dive_start_s) / (dive_end_s - dive_start_s), 0.0, 1.0))


## The first effect of a kind (null when the shot has none).
func effect(effect_kind: StringName) -> CinematicEffectResource:
	for found: CinematicEffectResource in effects:
		if found.kind == effect_kind:
			return found
	return null


## The hand-over's window around the shot's end: [start, end] seconds (empty when it has none).
func transition_window() -> Vector2:
	if transition_kind == &"" or transition_s <= 0.0:
		return Vector2(end_s, end_s)
	return Vector2(end_s - transition_s * 0.5, end_s + transition_s * 0.5)
