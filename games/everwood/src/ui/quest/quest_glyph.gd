## A small painted mark for the quest screens, drawn in code in the atelier's gilt and ink:
## what a step asks for (a speech bubble to talk, a heart to calm, a flag to go somewhere,
## a star to do something, a crown for a big foe, a flame to help someone, a satchel to
## carry), a quest's seal (done, under way, still to come) and the "this way" arrow.
class_name QuestGlyph
extends Control

enum Mark { TALK, CALM, GO, DO, BIG_FOE, HELP, CARRY, DONE, NOW, LATER, ARROW, HERE }

const INK_LINE: Color = Color("#2A1A0C")

var mark: Mark = Mark.DO
var tint: Color = AtelierTheme.GOLD
## The arrow's turn (radians, 0 = straight ahead / up the screen, + = to the right).
var turn: float = 0.0
## A soft pulse (the arrow and the "now" star breathe).
var pulse: bool = false

var _age: float = 0.0


func _init(which: Mark = Mark.DO, colour: Color = AtelierTheme.GOLD, across: float = 34.0) -> void:
	mark = which
	tint = colour
	custom_minimum_size = Vector2(across, across)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The mark for a step's kind (QuestStepResource.Kind).
static func for_kind(kind: QuestStepResource.Kind) -> Mark:
	match kind:
		QuestStepResource.Kind.TALK_TO:
			return Mark.TALK
		QuestStepResource.Kind.CALM:
			return Mark.CALM
		QuestStepResource.Kind.REACH_PLACE:
			return Mark.GO
		QuestStepResource.Kind.BOSS_OUTCOME:
			return Mark.BIG_FOE
		QuestStepResource.Kind.NPC_RESTORED:
			return Mark.HELP
		QuestStepResource.Kind.ITEM:
			return Mark.CARRY
	return Mark.DO


func _process(delta: float) -> void:
	if pulse or mark == Mark.ARROW or mark == Mark.HERE:
		_age += delta
		queue_redraw()


func _draw() -> void:
	var middle: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5
	var breathe: float = 1.0 + (0.06 * sin(_age * 4.0) if pulse else 0.0)
	match mark:
		Mark.ARROW:
			_arrow(middle, r)
			return
		Mark.HERE:
			draw_circle(middle, r * 0.92, Color(AtelierTheme.GOOD, 0.22))
			draw_arc(middle, r * 0.92, 0.0, TAU, 32, AtelierTheme.GOOD, 2.0, true)
			draw_circle(middle, r * 0.32 * (1.0 + 0.2 * sin(_age * 5.0)), AtelierTheme.GOOD)
			return
	# A gilt medallion behind every other mark.
	var ground: Color = AtelierTheme.ROW_CHOSEN if mark != Mark.LATER else AtelierTheme.ROW
	draw_circle(middle, r * 0.96 * breathe, ground)
	draw_arc(middle, r * 0.96 * breathe, 0.0, TAU, 40, tint, maxf(1.5, r * 0.1), true)
	var s: float = r * 0.55
	match mark:
		Mark.TALK:
			_bubble(middle, s)
		Mark.CALM:
			_heart(middle, s)
		Mark.GO:
			_flag(middle, s)
		Mark.DO, Mark.NOW:
			draw_colored_polygon(star_points(middle, s * (1.05 if mark == Mark.NOW else 0.95), s * 0.42), tint)
		Mark.BIG_FOE:
			_crown(middle, s)
		Mark.HELP:
			_flame(middle, s)
		Mark.CARRY:
			_satchel(middle, s)
		Mark.DONE:
			draw_polyline(PackedVector2Array([middle + Vector2(-s * 0.7, 0.0), middle + Vector2(-s * 0.15, s * 0.55), middle + Vector2(s * 0.8, -s * 0.6)]),
				AtelierTheme.GOOD, maxf(2.5, r * 0.22), true)
		Mark.LATER:
			var font: Font = ThemeDB.fallback_font
			var px: int = int(r * 1.1)
			draw_string(font, middle + Vector2(-r, px * 0.36), "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, px, AtelierTheme.INK_DIM)


## A five-pointed star's outline (centre, outer and inner radius).
static func star_points(middle: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in 10:
		var angle: float = -PI * 0.5 + float(index) * PI / 5.0
		var reach: float = outer if index % 2 == 0 else inner
		points.append(middle + Vector2(cos(angle), sin(angle)) * reach)
	return points


func _bubble(middle: Vector2, s: float) -> void:
	var box: PackedVector2Array = PackedVector2Array()
	for index: int in 24:
		var angle: float = float(index) / 24.0 * TAU
		box.append(middle + Vector2(cos(angle) * s, sin(angle) * s * 0.72 - s * 0.12))
	draw_colored_polygon(box, tint)
	draw_colored_polygon(PackedVector2Array([middle + Vector2(-s * 0.45, s * 0.42), middle + Vector2(-s * 0.7, s * 0.95), middle + Vector2(-s * 0.05, s * 0.5)]), tint)
	for dot: int in 3:
		draw_circle(middle + Vector2((float(dot) - 1.0) * s * 0.45, -s * 0.12), s * 0.12, INK_LINE)


func _heart(middle: Vector2, s: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in 40:
		var t: float = float(index) / 40.0 * TAU
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(middle + Vector2(x, y + 2.0) * (s / 16.0))
	draw_colored_polygon(points, Color("#F29B8F") if tint == AtelierTheme.GOLD else tint)


func _flag(middle: Vector2, s: float) -> void:
	draw_line(middle + Vector2(-s * 0.55, -s * 0.9), middle + Vector2(-s * 0.55, s * 0.95), tint, maxf(2.0, s * 0.16), true)
	draw_colored_polygon(PackedVector2Array([middle + Vector2(-s * 0.5, -s * 0.9), middle + Vector2(s * 0.85, -s * 0.55), middle + Vector2(-s * 0.5, -s * 0.15)]), tint)


func _crown(middle: Vector2, s: float) -> void:
	draw_colored_polygon(PackedVector2Array([middle + Vector2(-s * 0.9, s * 0.6), middle + Vector2(-s * 0.9, -s * 0.5), middle + Vector2(-s * 0.45, 0.0),
		middle + Vector2(0.0, -s * 0.8), middle + Vector2(s * 0.45, 0.0), middle + Vector2(s * 0.9, -s * 0.5), middle + Vector2(s * 0.9, s * 0.6)]), tint)
	draw_circle(middle + Vector2(0.0, s * 0.25), s * 0.14, INK_LINE)


func _flame(middle: Vector2, s: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in 30:
		var t: float = float(index) / 30.0 * TAU
		var y: float = -cos(t)
		var width: float = sin(t) * (0.55 + 0.25 * y) * (1.0 - maxf(0.0, -y) * 0.6)
		points.append(middle + Vector2(width * s, y * s * 0.95 + s * 0.1))
	draw_colored_polygon(points, Color("#F2A65A"))
	draw_circle(middle + Vector2(0.0, s * 0.4), s * 0.3, Color("#FFE29A"))


func _satchel(middle: Vector2, s: float) -> void:
	draw_arc(middle + Vector2(0.0, -s * 0.3), s * 0.45, PI, TAU, 16, tint, maxf(2.0, s * 0.14), true)
	draw_rect(Rect2(middle + Vector2(-s * 0.8, -s * 0.3), Vector2(s * 1.6, s * 1.1)), tint)
	draw_rect(Rect2(middle + Vector2(-s * 0.8, -s * 0.3), Vector2(s * 1.6, s * 0.45)), tint.darkened(0.25))
	draw_circle(middle + Vector2(0.0, s * 0.15), s * 0.13, INK_LINE)


## The "this way" arrow, turned toward the place, breathing gently.
func _arrow(middle: Vector2, r: float) -> void:
	var grow: float = 1.0 + 0.07 * sin(_age * 4.0)
	draw_circle(middle, r * 0.96, Color(AtelierTheme.ROW_CHOSEN, 0.9))
	draw_arc(middle, r * 0.96, 0.0, TAU, 40, AtelierTheme.GILT, 2.0, true)
	var points: PackedVector2Array = PackedVector2Array([Vector2(0.0, -0.78), Vector2(0.5, 0.05), Vector2(0.18, 0.0), Vector2(0.18, 0.6),
		Vector2(-0.18, 0.6), Vector2(-0.18, 0.0), Vector2(-0.5, 0.05)])
	var turned: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		turned.append(middle + (point * r * 0.82 * grow).rotated(turn))
	draw_colored_polygon(turned, tint)
	var edge: PackedVector2Array = turned.duplicate()
	edge.append(turned[0])
	draw_polyline(edge, INK_LINE, 1.5, true)
