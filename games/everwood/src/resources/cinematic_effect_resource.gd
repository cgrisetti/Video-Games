## One effect a film's shot draws (docs/31), as the timeline JSON names it: a page fading
## in from parchment, a pop-up rising, a gold glow pulsing, violet spreading, the sea
## rising, the grey draining across, a windmill's sails turning, mist creeping, the title
## card inking on, or the Chime-Post ribbon. Times are on the film's clock in seconds.
##
## Pure data: PrologueFilm draws each kind; a kind it doesn't know is skipped with a warning.
class_name CinematicEffectResource
extends Resource

const FADE_FROM_PARCHMENT: StringName = &"fade_from_parchment"
const POPUP_RISE: StringName = &"popup_rise"
const GLOW_PULSE: StringName = &"glow_pulse"
const TINT_SPREAD: StringName = &"tint_spread"
const WATER_RISE: StringName = &"water_rise"
const GREY_DRAIN_SWEEP: StringName = &"grey_drain_sweep"
const WINDMILL_SAIL_SPIN: StringName = &"windmill_sail_spin"
const MIST_CREEP: StringName = &"mist_creep"
const TITLE_CARD: StringName = &"title_card"
const CHIME_POST_RIBBON: StringName = &"chime_post_ribbon"
## Every kind the film knows how to draw.
const KINDS: Array[StringName] = [FADE_FROM_PARCHMENT, POPUP_RISE, GLOW_PULSE, TINT_SPREAD, WATER_RISE, GREY_DRAIN_SWEEP,
	WINDMILL_SAIL_SPIN, MIST_CREEP, TITLE_CARD, CHIME_POST_RIBBON]

@export var kind: StringName = &""
## When it runs; end_s < 0 means "to the end of its shot" (the windmill turns all shot long).
@export var start_s: float = 0.0
@export var end_s: float = -1.0
## Its colour (alpha 0 when the timeline gives none).
@export var color: Color = Color(0.0, 0.0, 0.0, 0.0)
## How its progress eases (CinematicFilmResource.eased).
@export var ease_curve: StringName = &"linear"
## Where it centres, as a fraction of the plate: tint_spread's origin, the windmill's pivot.
@export var origin: Vector2 = Vector2(0.5, 0.5)
## popup_rise: how far below its place the page starts (fraction of the plate's height).
@export var offset_y_frac: float = 0.0
## glow_pulse: one breath, in seconds.
@export var period_s: float = 0.0
## water_rise: how far the sea climbs (fraction of the plate's height).
@export var rise_frac: float = 0.0
## grey_drain_sweep's "direction" or mist_creep's "from" (right_to_left, left_edge ...).
@export var direction: StringName = &""
## grey_drain_sweep: the grey's edge at the end (fraction of the plate's width).
@export var end_edge_x_frac: float = 0.0
## windmill_sail_spin: degrees a second.
@export var deg_per_s: float = 0.0
## title_card: its lines and each line's font name.
@export var lines: PackedStringArray = PackedStringArray()
@export var fonts: PackedStringArray = PackedStringArray()
## title_card: inking on, and fading out.
@export var ink_on_start_s: float = 0.0
@export var ink_on_duration_s: float = 0.0
@export var fade_out_start_s: float = 0.0
@export var fade_out_end_s: float = 0.0
## chime_post_ribbon: the rhyme, and how long it stays as the timeline says it.
@export var text: String = ""
@export var persist_until: String = ""
## chime_post_ribbon: the seconds of play `persist_until` names ("... or 20 s of play" -> 20).
@export var persist_play_s: float = 0.0
## A note for whoever builds it (the grey drain's "reuse the hush shader").
@export var note: String = ""


func has_color() -> bool:
	return color.a > 0.0


## How far through it is at `at_s`, 0 to 1 (eased), against `shot_end` when it has no end of its own.
func progress(at_s: float, shot_end: float) -> float:
	var finish: float = end_s if end_s >= 0.0 else shot_end
	if finish <= start_s:
		return 1.0 if at_s >= start_s else 0.0
	return CinematicFilmResource.eased(ease_curve, clampf((at_s - start_s) / (finish - start_s), 0.0, 1.0))
