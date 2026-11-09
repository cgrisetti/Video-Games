## The film's skip prompt (docs/31): a ring that fills while the host holds the pause / menu
## button (no new button: Gate 2), with a short line beside it ("Hold Esc to skip", or for
## everyone else "Host can skip"). It sits in its parent's bottom-right corner.
class_name SkipRing
extends Control

## The ring and its text at 1080p.
const RADIUS_AT_1080P: float = 22.0
const WIDTH_AT_1080P: float = 5.0
const TEXT_AT_1080P: int = 26
const MARGIN_AT_1080P: float = 40.0
const GAP_AT_1080P: float = 14.0
## The ring's dim when nobody's holding.
const IDLE_ALPHA: float = 0.55

## 0 to 1: how far the hold has come.
var progress: float = 0.0
var line: String = ""
var fill: Color = Color("#F2B749")
var back: Color = Color(0.17, 0.14, 0.12, 0.6)
var font: Font
var _scale: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Puts the ring in the bottom-right of a rect of `area` (its height sets the 1080p scale).
func place(area: Vector2) -> void:
	_scale = area.y / 1080.0
	var radius: float = RADIUS_AT_1080P * _scale
	var margin: float = MARGIN_AT_1080P * _scale
	size = Vector2(radius * 2.0, radius * 2.0)
	position = area - Vector2(margin + size.x, margin + size.y)
	modulate.a = 1.0 if progress > 0.0 else IDLE_ALPHA
	queue_redraw()


func _draw() -> void:
	var radius: float = RADIUS_AT_1080P * _scale
	var width: float = maxf(1.5, WIDTH_AT_1080P * _scale)
	var centre: Vector2 = size * 0.5
	draw_arc(centre, radius - width * 0.5, 0.0, TAU, 48, back, width, true)
	if progress > 0.0:
		draw_arc(centre, radius - width * 0.5, -PI * 0.5, -PI * 0.5 + TAU * clampf(progress, 0.0, 1.0), 48, fill, width, true)
	if line == "" or font == null:
		return
	var text_size: int = maxi(8, roundi(TEXT_AT_1080P * _scale))
	var extent: Vector2 = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_size)
	var at: Vector2 = Vector2(-GAP_AT_1080P * _scale - extent.x, centre.y + extent.y * 0.3)
	draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_size, maxi(2, roundi(5.0 * _scale)), back)
	draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_size, Color("#F4EFE6"))
