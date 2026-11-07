## The Everwood wordmark (docs/22_TITLE_SCREEN_AND_TALES.md §2), drawn in code
## like the rest of the storybook UI: a small parchment kicker, "EVERWOOD" in
## a letterpress serif, Saffron-Gold on a deep-ink outline with a warm shadow,
## an oak-sprig flourish beneath (a rule curling at both ends, oak leaves and an
## acorn at its heart) and the line from the vision, "The old rhymes are true."
class_name EverwoodWordmark
extends Control

const TITLE: String = "EVERWOOD"
const KICKER: String = "A TALE OF THE CALDERA ISLES"
const TAGLINE: String = "The old rhymes are true."
## The storybook UI's palette (the map's ink and parchment, the minimap's Saffron-Gold).
const SAFFRON_GOLD: Color = Color("#E8B64A")
const GOLD_LIGHT: Color = Color("#F8DE8C")
const INK: Color = Color("#3A2818")
const PARCHMENT: Color = Color("#F7EFDA")
const SHADOW: Color = Color(0.08, 0.05, 0.03, 0.5)
const LEAF_GREEN: Color = Color("#7FA05A")
## Letterpress serifs, in order of preference; any serif will do.
const SERIF_FONTS: PackedStringArray = ["Iowan Old Style", "Palatino", "Hoefler Text", "Baskerville", "Georgia", "Book Antiqua", "Times New Roman", "serif"]

var _title_font: FontVariation
var _small_font: FontVariation
var _italic_font: SystemFont
## The wordmark rises in over its first moments.
var _age: float = 0.0


## A serif from the system (the game ships no font files), at a weight, italic or not.
static func serif(weight: int = 400, italic: bool = false) -> SystemFont:
	var font: SystemFont = SystemFont.new()
	font.font_names = SERIF_FONTS
	font.font_weight = weight
	font.font_italic = italic
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_font = FontVariation.new()
	_title_font.base_font = serif(700)
	_small_font = FontVariation.new()
	_small_font.base_font = serif(600)
	_italic_font = serif(400, true)


func _process(delta: float) -> void:
	if _age < 2.0:
		_age += delta
		queue_redraw()


func _draw() -> void:
	var title_size: int = maxi(24, int(size.y * 0.4))
	_title_font.spacing_glyph = int(title_size * 0.06)
	_small_font.spacing_glyph = int(title_size * 0.06)
	var rise: float = ease(clampf(_age / 1.2, 0.0, 1.0), 0.35)
	var fade: Color = Color(1.0, 1.0, 1.0, rise)
	var drop: float = (1.0 - rise) * 18.0
	# The kicker, between two short rules.
	var kicker_size: int = maxi(10, int(title_size * 0.17))
	var kicker_width: float = _small_font.get_string_size(KICKER, HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_size).x
	var title_width: float = _title_font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var left: float = 0.0
	var mid: float = left + title_width * 0.5
	var kicker_y: float = size.y * 0.16 + drop
	var kicker_x: float = mid - kicker_width * 0.5
	draw_string(_small_font, Vector2(kicker_x + 1.5, kicker_y + 2.0), KICKER, HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_size, SHADOW * fade)
	draw_string(_small_font, Vector2(kicker_x, kicker_y), KICKER, HORIZONTAL_ALIGNMENT_LEFT, -1, kicker_size, PARCHMENT * fade)
	var rule_y: float = kicker_y - kicker_size * 0.33
	for side: float in [-1.0, 1.0]:
		var from: float = mid + side * (kicker_width * 0.5 + 14.0)
		draw_line(Vector2(from, rule_y), Vector2(from + side * title_size * 0.5, rule_y), SAFFRON_GOLD * fade, 2.0, true)
		_diamond(Vector2(from + side * title_size * 0.55, rule_y), 4.0, SAFFRON_GOLD * fade)
	# EVERWOOD: shadow, ink outline, a light top edge, then the gold.
	var base: Vector2 = Vector2(left, size.y * 0.16 + title_size * 1.02 + drop)
	var outline: int = maxi(4, int(title_size * 0.085))
	draw_string_outline(_title_font, base + Vector2(4.0, 7.0), TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, outline, SHADOW * fade)
	draw_string(_title_font, base + Vector2(4.0, 7.0), TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, SHADOW * fade)
	draw_string_outline(_title_font, base, TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, outline, INK * fade)
	draw_string(_title_font, base + Vector2(0.0, -2.0), TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, GOLD_LIGHT * fade)
	draw_string(_title_font, base + Vector2(0.0, 1.0), TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, SAFFRON_GOLD * fade)
	# The oak-sprig flourish beneath.
	var flourish_y: float = base.y + title_size * 0.32
	_flourish(Vector2(mid, flourish_y), title_width * 0.46, title_size * 0.16, fade)
	# The tagline.
	var tag_size: int = maxi(12, int(title_size * 0.22))
	var tag_width: float = _italic_font.get_string_size(TAGLINE, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size).x
	var tag_at: Vector2 = Vector2(mid - tag_width * 0.5, flourish_y + title_size * 0.42)
	draw_string(_italic_font, tag_at + Vector2(1.5, 2.0), TAGLINE, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size, SHADOW * fade)
	draw_string(_italic_font, tag_at, TAGLINE, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_size, PARCHMENT * fade)


## A rule that curls up at both ends, two oak leaves either side of an acorn at its heart.
func _flourish(center: Vector2, reach: float, scale: float, fade: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var points: PackedVector2Array = PackedVector2Array()
		for index: int in 25:
			var u: float = float(index) / 24.0
			points.append(center + Vector2(side * (scale * 1.4 + u * (reach - scale * 1.4)), -sin(u * PI) * scale * 0.18))
		draw_polyline(points, INK * fade, 5.0, true)
		draw_polyline(points, SAFFRON_GOLD * fade, 2.5, true)
		# The curl at the end of the rule.
		var tip: Vector2 = points[points.size() - 1]
		var curl_center: Vector2 = tip + Vector2(0.0, -scale * 0.42)
		var start_angle: float = PI * 0.5
		draw_arc(curl_center, scale * 0.42, start_angle, start_angle + side * PI * 1.5, 18, INK * fade, 5.0, true)
		draw_arc(curl_center, scale * 0.42, start_angle, start_angle + side * PI * 1.5, 18, SAFFRON_GOLD * fade, 2.5, true)
		# Two oak leaves either side of the acorn.
		_oak_leaf(center + Vector2(side * scale * 1.15, -scale * 0.12), side * 0.35 + (0.0 if side > 0.0 else PI), scale * 1.25, fade)
		_oak_leaf(center + Vector2(side * scale * 0.95, scale * 0.28), side * -0.5 + (0.0 if side > 0.0 else PI), scale * 0.95, fade)
	# The acorn: a cup and a nut.
	var nut: PackedVector2Array = PackedVector2Array()
	for index: int in 16:
		var a: float = TAU * float(index) / 16.0
		nut.append(center + Vector2(cos(a) * scale * 0.34, scale * 0.12 + sin(a) * scale * 0.46))
	draw_colored_polygon(nut, SAFFRON_GOLD * fade)
	draw_polyline(nut + PackedVector2Array([nut[0]]), INK * fade, 2.0, true)
	var cup: PackedVector2Array = PackedVector2Array()
	for index: int in 13:
		var a: float = PI + PI * float(index) / 12.0
		cup.append(center + Vector2(cos(a) * scale * 0.44, -scale * 0.08 + sin(a) * scale * 0.3))
	draw_colored_polygon(cup, Color("#8A5A2E") * fade)
	draw_polyline(cup + PackedVector2Array([cup[0]]), INK * fade, 2.0, true)
	draw_line(center + Vector2(0.0, -scale * 0.38), center + Vector2(scale * 0.08, -scale * 0.55), INK * fade, 2.5, true)


## A lobed oak leaf from `base`, pointing at `angle`, `length` long.
func _oak_leaf(base: Vector2, angle: float, length: float, fade: Color) -> void:
	var along: Vector2 = Vector2(cos(angle), sin(angle))
	var across: Vector2 = Vector2(-along.y, along.x)
	var outline: PackedVector2Array = PackedVector2Array()
	var steps: int = 28
	for index: int in steps + 1:
		var u: float = float(index) / float(steps)
		var lobe: float = 1.0 + 0.28 * absf(sin(u * PI * 3.5))
		var width: float = sin(u * PI) * length * 0.26 * lobe
		outline.append(base + along * u * length + across * width)
	for index: int in range(steps - 1, 0, -1):
		var u: float = float(index) / float(steps)
		var lobe: float = 1.0 + 0.28 * absf(sin(u * PI * 3.5))
		var width: float = sin(u * PI) * length * 0.26 * lobe
		outline.append(base + along * u * length - across * width)
	draw_colored_polygon(outline, LEAF_GREEN * fade)
	draw_polyline(outline + PackedVector2Array([outline[0]]), INK * fade, 2.0, true)
	draw_line(base, base + along * length * 0.92, SAFFRON_GOLD * fade, 1.5, true)


func _diamond(at: Vector2, r: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -r), at + Vector2(r, 0.0), at + Vector2(0.0, r), at + Vector2(-r, 0.0)]), color)
