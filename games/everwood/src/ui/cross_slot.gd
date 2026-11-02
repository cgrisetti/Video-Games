## One slot of the Cross-Grimoire HUD (07_EXPEDITION_HUD_AND_ART_GDD.md §2): a
## card-shaped tile a child can read by shape, colour and motion.
##   - its frame is tinted by its card's Sign (amber, sea-azure, saffron, violet)
##   - an Under-Card linked beneath shows as a ribbon in the bottom-right corner
##     in the Under-Card's Sign colour
##   - a card that needs more Resonance Pips than you have sits dimmed and 6 px
##     low; the moment you have enough it slides up and its border turns gold
##   - pressing or buffering its move pops it to 1.35x over 180 ms with a white
##     flash (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md §4.2, Layer 4)
##   - when a teammate's seal waits within reach and you have the pip, the R
##     slot wears a bright golden ring (`detonate_ready`)
## The slot draws itself; CrossGrimoireHUD positions it and feeds it numbers.
class_name CrossSlot
extends Control

enum Look { CARD, GUARD, WEAPON, ULTIMATE, ROLL }
enum Icon { NONE, SHIELD, STAR, SWORD, AXE, STAFF, BOW, ROLL }

## How far an unaffordable card sits below its place, in pixels.
const UNREADY_DROP: float = 6.0
const UNREADY_ALPHA: float = 0.6
const LIFT_SPEED: float = 12.0
const PULSE_TIME: float = 0.18
const PULSE_SCALE: float = 1.35
## The gold flash when a card becomes ready.
const READY_FLASH_TIME: float = 0.5
const CORNER: int = 10
const BORDER: int = 3
const READY_BORDER: int = 5
const RIBBON_SIZE: float = 20.0
const KEY_FONT_SIZE: int = 14
const TAG_FONT_SIZE: int = 12
const TITLE_FONT_SIZE: int = 16
const SMALL_FONT_SIZE: int = 12
## Long names shrink to fit their slot, but no smaller than this.
const MIN_FONT_SIZE: int = 10
const BACK_COLOR: Color = Color(0.07, 0.07, 0.1, 0.82)
const GOLD: Color = Color(1.0, 0.82, 0.3)
const DIM_GOLD: Color = Color(0.45, 0.42, 0.36)
const TEXT_COLOR: Color = Color(1.0, 0.98, 0.94)
const KEY_COLOR: Color = Color(0.85, 0.88, 1.0)
const OUTLINE: Color = Color(0.0, 0.0, 0.0, 0.85)

var look: Look = Look.CARD
var icon: Icon = Icon.NONE
## The button(s) that fire it: "W+K", "↑△".
var key_text: String = ""
## The card (or weapon) name along the bottom.
var title: String = ""
## A line under the title in small print ("Perfect 0.26 s").
var subtitle: String = ""
## The Sign's short name ("IRON-ROOT") and colour.
var tag_text: String = ""
var sign_color: Color = Color(0.9, 0.9, 0.9)
## The linked Under-Card's colour; transparent when nothing is linked.
var under_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var pip_cost: int = 0
## Enough pips (or stamina, for the roll) to use it right now.
var is_ready: bool = true
## Highlighted for its own reason (a guard that's up, a tether bound).
var lit: bool = false
## R only: a teammate's seal is close and you have the pip to detonate it.
var detonate_ready: bool = false

var _lift: float = 0.0
var _pulse_left: float = 0.0
var _ready_flash_left: float = 0.0
var _home: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Where the slot rests (its top-left corner) before the readiness drop.
func place(home: Vector2, slot_size: Vector2) -> void:
	_home = home
	size = slot_size
	custom_minimum_size = slot_size
	pivot_offset = slot_size * 0.5
	position = home + Vector2(0.0, _lift)


## Updates whether it can be used; becoming usable plays the gold pop.
func set_ready(ready_now: bool) -> void:
	if ready_now and not is_ready and pip_cost > 0:
		_ready_flash_left = READY_FLASH_TIME
	is_ready = ready_now


## The press-or-buffer pop: 1.35x and a crisp white flash for 180 ms.
func pulse() -> void:
	_pulse_left = PULSE_TIME


func is_pulsing() -> bool:
	return _pulse_left > 0.0


## Pixels below its resting place right now (0 when ready, 6 when not).
func lift() -> float:
	return _lift


func _process(delta: float) -> void:
	var wanted: float = 0.0 if is_ready else UNREADY_DROP
	_lift = lerpf(_lift, wanted, 1.0 - exp(-LIFT_SPEED * delta))
	if absf(_lift - wanted) < 0.05:
		_lift = wanted
	position = _home + Vector2(0.0, _lift)
	_pulse_left = maxf(0.0, _pulse_left - delta)
	_ready_flash_left = maxf(0.0, _ready_flash_left - delta)
	var pop: float = _pulse_left / PULSE_TIME
	scale = Vector2.ONE * lerpf(1.0, PULSE_SCALE, pop)
	modulate.a = 1.0 if is_ready else UNREADY_ALPHA
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var font: Font = ThemeDB.fallback_font
	var golden: bool = (is_ready and pip_cost > 0 and look != Look.ROLL) or lit
	_rounded(rect, BACK_COLOR, true, 0)
	if golden and is_ready:
		# A ready card glows softly outside its gold border, so it never reads as amber Iron-Root.
		_rounded(rect.grow(3.0), Color(GOLD, 0.35), false, 4)
	if _ready_flash_left > 0.0:
		_rounded(rect.grow(4.0), Color(GOLD, 0.55 * _ready_flash_left / READY_FLASH_TIME), false, 6)
	_rounded(rect, GOLD if golden else sign_color, false, READY_BORDER if golden else BORDER)
	if detonate_ready:
		# A bright golden ring that breathes, so the combo can't be missed.
		var breath: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		_rounded(rect.grow(6.0 + 3.0 * breath), Color(GOLD.lightened(0.3), 0.75 + 0.25 * breath), false, 5)
	if _pulse_left > 0.0:
		_rounded(rect, Color(1.0, 1.0, 1.0, 0.55 * _pulse_left / PULSE_TIME), true, 0)
	var pad: float = 8.0
	# Top line: the button, and the pip cost as gems on the right.
	_text(font, Vector2(pad, pad + KEY_FONT_SIZE), key_text, KEY_FONT_SIZE, KEY_COLOR, size.x - pad * 2.0, HORIZONTAL_ALIGNMENT_LEFT)
	for gem: int in pip_cost:
		var center: Vector2 = Vector2(size.x - pad - 7.0 - gem * 13.0, pad + 7.0)
		_diamond(center, 6.0, GOLD if is_ready else DIM_GOLD, true)
	var icon_center: Vector2 = Vector2(pad + 14.0, size.y * 0.58)
	var text_left: float = pad
	if icon != Icon.NONE:
		_draw_icon(icon_center, 13.0)
		text_left = pad + 32.0
	if tag_text != "":
		_text(font, Vector2(text_left, size.y * 0.5 + 2.0), "[%s]" % tag_text, TAG_FONT_SIZE, sign_color.lightened(0.25), size.x - text_left - pad, HORIZONTAL_ALIGNMENT_LEFT)
	var title_y: float = size.y - pad - (SMALL_FONT_SIZE + 2.0 if subtitle != "" else 0.0)
	_text(font, Vector2(text_left, title_y), title, TITLE_FONT_SIZE, TEXT_COLOR, size.x - text_left - pad, HORIZONTAL_ALIGNMENT_LEFT)
	if subtitle != "":
		_text(font, Vector2(text_left, size.y - pad + 1.0), subtitle, SMALL_FONT_SIZE, Color(TEXT_COLOR, 0.75), size.x - text_left - pad, HORIZONTAL_ALIGNMENT_LEFT)
	if under_color.a > 0.0:
		var corner: Vector2 = size
		draw_colored_polygon(PackedVector2Array([corner, corner - Vector2(RIBBON_SIZE, 0.0), corner - Vector2(0.0, RIBBON_SIZE)]), under_color)
		draw_polyline(PackedVector2Array([corner - Vector2(RIBBON_SIZE, 0.0), corner - Vector2(0.0, RIBBON_SIZE)]), Color(1.0, 1.0, 1.0, 0.7), 1.5)


func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, width: float, align: HorizontalAlignment) -> void:
	var fitted: int = font_size
	while fitted > MIN_FONT_SIZE and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > width:
		fitted -= 1
	draw_string_outline(font, at, text, align, width, fitted, 4, OUTLINE, TextServer.JUSTIFICATION_NONE)
	draw_string(font, at, text, align, width, fitted, color, TextServer.JUSTIFICATION_NONE)


func _rounded(rect: Rect2, color: Color, filled: bool, width: int) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.set_corner_radius_all(CORNER)
	box.anti_aliasing = true
	if filled:
		box.bg_color = color
	else:
		box.draw_center = false
		box.border_color = color
		box.set_border_width_all(width)
	draw_style_box(box, rect)


func _diamond(center: Vector2, radius: float, color: Color, filled: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius * 0.75, 0.0),
		center + Vector2(0.0, radius), center + Vector2(-radius * 0.75, 0.0)])
	if filled:
		draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, Color(0.0, 0.0, 0.0, 0.6), 1.5)


## Simple, chunky shapes a pre-reader knows: a shield, a star, a sword, an axe,
## a staff, a bow and a rolling arrow.
func _draw_icon(center: Vector2, r: float) -> void:
	var ink: Color = sign_color.lightened(0.35)
	match icon:
		Icon.SHIELD:
			var shield: PackedVector2Array = PackedVector2Array([center + Vector2(-r, -r), center + Vector2(r, -r), center + Vector2(r, 0.1 * r),
				center + Vector2(0.0, r * 1.15), center + Vector2(-r, 0.1 * r)])
			draw_colored_polygon(shield, ink)
			draw_line(center + Vector2(0.0, -r * 0.8), center + Vector2(0.0, r * 0.8), BACK_COLOR, 2.5)
		Icon.STAR:
			var star: PackedVector2Array = PackedVector2Array()
			for point: int in 10:
				var radius: float = r * (1.15 if point % 2 == 0 else 0.5)
				var angle: float = -PI * 0.5 + TAU * point / 10.0
				star.append(center + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(star, GOLD)
		Icon.SWORD:
			draw_line(center + Vector2(-r * 0.8, r * 0.8), center + Vector2(r * 0.9, -r * 0.9), ink, 4.0)
			draw_line(center + Vector2(-r * 0.75, r * 0.15), center + Vector2(-r * 0.15, r * 0.75), ink, 4.0)
		Icon.AXE:
			draw_line(center + Vector2(-r * 0.6, r), center + Vector2(r * 0.4, -r), ink, 3.5)
			draw_colored_polygon(PackedVector2Array([center + Vector2(r * 0.1, -r), center + Vector2(r * 1.1, -r * 0.6),
				center + Vector2(r * 0.9, r * 0.2), center + Vector2(-r * 0.1, -r * 0.2)]), ink)
		Icon.STAFF:
			draw_line(center + Vector2(-r * 0.5, r), center + Vector2(r * 0.4, -r * 0.6), ink, 3.5)
			draw_circle(center + Vector2(r * 0.55, -r * 0.8), r * 0.38, GOLD)
		Icon.BOW:
			draw_arc(center + Vector2(-r * 0.3, 0.0), r, -PI * 0.42, PI * 0.42, 12, ink, 3.5)
			var top: Vector2 = center + Vector2(-r * 0.3, 0.0) + Vector2(cos(-PI * 0.42), sin(-PI * 0.42)) * r
			var bottom: Vector2 = center + Vector2(-r * 0.3, 0.0) + Vector2(cos(PI * 0.42), sin(PI * 0.42)) * r
			draw_line(top, bottom, Color(1.0, 1.0, 1.0, 0.8), 1.5)
		Icon.ROLL:
			draw_arc(center, r * 0.85, 0.3, TAU - 0.6, 16, ink, 3.5)
			var tip: Vector2 = center + Vector2(cos(TAU - 0.6), sin(TAU - 0.6)) * r * 0.85
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-5.0, -6.0), tip + Vector2(6.0, -1.0), tip + Vector2(-2.0, 6.0)]), ink)
