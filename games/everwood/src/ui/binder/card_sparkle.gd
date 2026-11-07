## A burst of gold sparkles where a card snaps into its diamond (the card bench's little
## celebration): stars fly out, spin and fade in under a second, then it frees itself.
class_name CardSparkle
extends Control

const LIFE: float = 0.9
const STARS: int = 14
const REACH: float = 120.0

var tint: Color = AtelierTheme.GOLD
var _age: float = 0.0


func _init(colour: Color = AtelierTheme.GOLD) -> void:
	tint = colour
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = _age / LIFE
	var ease_out: float = 1.0 - pow(1.0 - t, 3.0)
	draw_circle(Vector2.ZERO, 70.0 * ease_out, Color(tint, 0.25 * (1.0 - t)))
	for star: int in STARS:
		var angle: float = float(star) / float(STARS) * TAU + t * 1.2
		var reach: float = REACH * ease_out * (0.6 + 0.4 * float(star % 3) / 2.0)
		var at: Vector2 = Vector2(cos(angle), sin(angle)) * reach
		var size_px: float = 11.0 * (1.0 - t)
		var colour: Color = Color(tint if star % 2 == 0 else Color("#FFF6DA"), 1.0 - t)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -size_px), at + Vector2(size_px * 0.3, -size_px * 0.3), at + Vector2(size_px, 0),
			at + Vector2(size_px * 0.3, size_px * 0.3), at + Vector2(0, size_px), at + Vector2(-size_px * 0.3, size_px * 0.3), at + Vector2(-size_px, 0),
			at + Vector2(-size_px * 0.3, -size_px * 0.3)]), colour)
