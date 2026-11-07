## "How a diamond works": the card bench's picture guide for a young player
## (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §7). One big diamond taken apart,
## each part numbered, and six short steps beside it that use the same numbers.
## It opens by itself the first time the cards tab shows in a session (away from the
## older checks' classic full kits) and from the bench's "How does a diamond work?"
## row; light, dodge or a click closes it.
class_name DiamondGuide
extends Control

signal done

const SHEET: Vector2 = Vector2(1600.0, 900.0)
const PANEL: Rect2 = Rect2(140.0, 150.0, 1320.0, 640.0)
const PICTURE: Rect2 = Rect2(190.0, 230.0, 520.0, 500.0)
const STEPS: Array[String] = [
	"Your Cross has three diamonds: L, R and L+R. Each one holds one card. Press its button to use it!",
	"The picture in the middle is your card. It's what you do: a swing for R, a shield for L.",
	"The frame around it is a Place-Card. If its colour matches your card, you get a gold star and a stronger card.",
	"A little helper card can hide underneath: the Tuck. It makes the card above it stronger.",
	"The purple dots show how much ink it costs. Your ink fills up when you calm foes and rest by a fire.",
	"In a fight: hit a foe, then press the diamond's button when the gold flash shines!",
]
## Where each numbered tag sits on the picture (in the picture's own 520 x 500 space).
const TAGS: Array[Vector2] = [Vector2(260.0, 468.0), Vector2(305.0, 215.0), Vector2(428.0, 140.0), Vector2(146.0, 380.0), Vector2(322.0, 38.0), Vector2(90.0, 96.0)]

var _age: float = 0.0


func _ready() -> void:
	name = "DiamondGuide"
	size = SHEET
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0.05, 0.035, 0.025, 0.82)
	veil.size = SHEET
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var page: PanelContainer = BinderKit.panel(AtelierTheme.page_style(true))
	page.position = PANEL.position
	page.custom_minimum_size = PANEL.size
	page.size = PANEL.size
	add_child(page)
	var picture: Control = Control.new()
	picture.name = "Picture"
	picture.position = PICTURE.position
	picture.size = PICTURE.size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.draw.connect(_draw_picture.bind(picture))
	add_child(picture)
	var words: VBoxContainer = BinderKit.column(14)
	words.position = Vector2(760.0, 190.0)
	words.custom_minimum_size = Vector2(660.0, 0.0)
	add_child(words)
	words.add_child(BinderKit.text("How a diamond works", BinderKit.BIG_SIZE + 4, AtelierTheme.GOLD))
	for index: int in STEPS.size():
		var row: HBoxContainer = BinderKit.line(12)
		row.add_child(_number(index + 1))
		row.add_child(BinderKit.text(STEPS[index], AtelierTheme.BODY_SIZE + 3, AtelierTheme.INK, 590.0))
		words.add_child(row)
	var go: PanelContainer = BinderKit.row_box(true)
	go.add_child(BinderKit.text("Light: Got it!", AtelierTheme.BODY_SIZE + 4, AtelierTheme.GOLD))
	BinderKit.on_click(go, close)
	words.add_child(go)
	BinderKit.on_click(self, close)


func _process(delta: float) -> void:
	_age += delta
	var picture: Control = get_node_or_null(^"Picture") as Control
	if picture != null:
		picture.queue_redraw()


func close() -> void:
	AudioCues.play(&"menu_move")
	done.emit()
	queue_free()


## A gold numbered disc (the steps and the picture's tags share them).
static func _number(value: int) -> PanelContainer:
	var style: StyleBoxFlat = AtelierTheme.chip_style(AtelierTheme.GOLD, AtelierTheme.ROW_CHOSEN)
	style.set_corner_radius_all(16)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	var disc: PanelContainer = BinderKit.panel(style)
	disc.add_child(BinderKit.text(str(value), AtelierTheme.BODY_SIZE + 2, AtelierTheme.GOLD))
	return disc


## One diamond taken apart: the Place-Card frame, the card in the middle, the Tuck peeking under it,
## the ink dots on top, the button on its tip, and a little gold flash that comes and goes.
func _draw_picture(on: Control) -> void:
	var center: Vector2 = Vector2(260.0, 230.0)
	var iron: Color = AtelierTheme.sign_fill(ScribeSignResource.Sign.SIGN_IRON_ROOT)
	var hearth: Color = AtelierTheme.sign_fill(ScribeSignResource.Sign.SIGN_WARM_HEARTH)
	var font: Font = ThemeDB.fallback_font
	# 4: the Tuck, peeking out under the card's frame.
	_diamond(on, center + Vector2(0.0, 132.0), 74.0, Color("#2A2018"), hearth, 4.0)
	# 3: the Place-Card frame.
	_diamond(on, center, 165.0, Color("#1E1711"), iron, 8.0)
	# 2: the card itself.
	_diamond(on, center, 102.0, Color("#2C1A0C"), AtelierTheme.GILT, 5.0)
	for stone: int in 3:
		var at: Vector2 = center + Vector2(0.0, 34.0 - float(stone) * 22.0)
		on.draw_circle(at, 28.0 - float(stone) * 7.0, InkCardFace.STONE[stone])
	on.draw_polyline(InkCardFace._quad(center + Vector2(-52, -52), center + Vector2(0, -30), center + Vector2(48, 38)), AtelierTheme.sign_text(ScribeSignResource.Sign.SIGN_IRON_ROOT), 8.0, true)
	# 5: the ink dots on top.
	for dot: int in 2:
		var at: Vector2 = center + Vector2(-16.0 + float(dot) * 32.0, -188.0)
		on.draw_circle(at, 13.0, InkCardFace.DROP_EDGE)
		on.draw_circle(at, 10.0, InkCardFace.DROP)
	# 1: the button on its tip.
	on.draw_string(font, center + Vector2(-30.0, 150.0), "R", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 34, AtelierTheme.INK)
	# 6: the gold flash that tells you "now!"
	var flash: float = 0.5 + 0.5 * sin(_age * 4.0)
	on.draw_arc(center, 196.0, 0.0, TAU, 64, Color(AtelierTheme.GOLD, 0.25 + 0.5 * flash), 6.0)
	for index: int in TAGS.size():
		var at: Vector2 = TAGS[index]
		on.draw_circle(at, 19.0, AtelierTheme.ROW_CHOSEN)
		on.draw_arc(at, 19.0, 0.0, TAU, 32, AtelierTheme.GOLD, 3.0)
		on.draw_string(font, at + Vector2(-19.0, 8.0), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, 38.0, 22, AtelierTheme.GOLD)


static func _diamond(on: Control, center: Vector2, half: float, fill: Color, edge: Color, width: float) -> void:
	var points: PackedVector2Array = PackedVector2Array([center + Vector2(0, -half), center + Vector2(half, 0), center + Vector2(0, half), center + Vector2(-half, 0)])
	on.draw_colored_polygon(points, fill)
	points.append(points[0])
	on.draw_polyline(points, edge, width, true)
