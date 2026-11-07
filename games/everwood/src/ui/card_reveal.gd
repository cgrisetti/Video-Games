## "A NEW CARD!": a deck card the party just found, shown on each player's own screen
## (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §7). The card springs up out of a
## burst of light in its Sign's colour, turning rays behind it, with its name, what it
## does, and where to find it now (the Binder). It doesn't take the controls: play
## goes on, and it fades away on its own after a few seconds.
class_name CardReveal
extends Control

const SHOW_TIME: float = 4.5
const GROW_TIME: float = 0.45
const FADE_TIME: float = 0.6
const CARD_SIZE: Vector2 = Vector2(250.0, 350.0)
const RAYS: int = 16

var copy_key: StringName = &""
var _age: float = 0.0
var _face: InkCardFace
var _title: Label
var _under: Label


func setup(key: StringName) -> void:
	copy_key = key


func _ready() -> void:
	name = "CardReveal"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face = InkCardFace.new(copy_key)
	_face.size = CARD_SIZE
	_face.pivot_offset = CARD_SIZE * 0.5
	var listed: ScribeCardResource = _face.card()
	_face.socket_word = "R" if listed != null and listed.slot == ScribeCardResource.GrimoireSlot.SIGNATURE else "L"
	add_child(_face)
	_title = AtelierTheme.label("A NEW CARD!", 34, AtelierTheme.GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_title.add_theme_constant_override(&"outline_size", 8)
	add_child(_title)
	_under = AtelierTheme.label("%s is in your Binder. Press Tab to put it in a diamond!" % (listed.display_name if listed != null else "It"),
		18, AtelierTheme.INK)
	_under.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_under.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_under.add_theme_constant_override(&"outline_size", 6)
	add_child(_under)
	AudioCues.play(&"card_chime")


func _process(delta: float) -> void:
	_age += delta
	if _age >= SHOW_TIME:
		queue_free()
		return
	var fit: float = clampf(minf(size.x / 1600.0, size.y / 900.0) * 1.6, 0.45, 1.2)
	var grow: float = clampf(_age / GROW_TIME, 0.0, 1.0)
	# A little overshoot as it springs up.
	var spring: float = 1.0 + sin(grow * PI) * 0.12 if grow < 1.0 else 1.0
	var scale_now: float = fit * grow * spring
	_face.scale = Vector2.ONE * maxf(0.01, scale_now)
	_face.rotation = (1.0 - grow) * -0.35
	_face.position = size * 0.5 - CARD_SIZE * 0.5
	var fade: float = clampf((SHOW_TIME - _age) / FADE_TIME, 0.0, 1.0)
	modulate.a = fade
	_title.size = Vector2(size.x, 40.0)
	_title.position = Vector2(0.0, size.y * 0.5 - CARD_SIZE.y * 0.5 * fit - 56.0)
	_under.size = Vector2(size.x, 30.0)
	_under.position = Vector2(0.0, size.y * 0.5 + CARD_SIZE.y * 0.5 * fit + 14.0)
	queue_redraw()


## Turning rays of light behind the card, in its Sign's colour.
func _draw() -> void:
	var listed: ScribeCardResource = _face.card() if _face != null else null
	var tint: Color = AtelierTheme.sign_fill(listed.scribe_sign) if listed != null else AtelierTheme.GOLD
	var center: Vector2 = size * 0.5
	var reach: float = minf(size.x, size.y) * 0.62 * clampf(_age / GROW_TIME, 0.0, 1.0)
	draw_circle(center, reach * 0.55, Color(tint, 0.22))
	for ray: int in RAYS:
		var angle: float = float(ray) / float(RAYS) * TAU + _age * 0.5
		var spread: float = PI / float(RAYS) * 0.45
		draw_colored_polygon(PackedVector2Array([center, center + Vector2(cos(angle - spread), sin(angle - spread)) * reach,
			center + Vector2(cos(angle + spread), sin(angle + spread)) * reach]), Color(tint, 0.18 if ray % 2 == 0 else 0.1))
