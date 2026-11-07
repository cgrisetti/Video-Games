## Binder tab 2, Quick Magic-Ink Cards, as the card bench of the Cards wireframe
## (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §2, R4, R5), made for a young
## player with the Ink Card Deck (§7), on the Binder's 1600 x 900 sheet:
##   left    the Cross at 2.2x: pick a diamond (L, R, L+R); under it, what the
##           chosen diamond's pair does together
##   middle  on the bench: your hand (the seven slots, the Ink-Well), the chosen
##           diamond and its three layers (1 the frame, a Place-Card; 2 the card,
##           what you do; 3 the helper, a Tuck), and "How does a diamond work?"
##           (DiamondGuide). Choosing cards: the highlighted card big (InkCardFace),
##           what it does in a child's words, and whether it fits
##   right   your cards as a grid of pictures for the chosen layer, each saying
##           with its look whether it's in use, fits, or can't go in yet
## Left / right picks the diamond, up / down the layer, light opens your cards; there
## the arrows move round the grid, light puts the card in (a sparkle where it lands)
## and dodge goes back. Every change goes to the host at once.
class_name BinderCardBench
extends Control

const LEFT: Rect2 = Rect2(34.0, 252.0, 516.0, 572.0)
const MIDDLE: Rect2 = Rect2(576.0, 252.0, 494.0, 572.0)
const RIGHT: Rect2 = Rect2(1096.0, 252.0, 464.0, 572.0)
## The grid of your cards: this many across, this many rows showing (it scrolls with the cursor).
const GRID_COLUMNS: int = 3
const GRID_ROWS: int = 2
const MINI_CARD: Vector2 = Vector2(140.0, 196.0)
const SPOTLIGHT_CARD: Vector2 = Vector2(280.0, 392.0)
const HAND_TILE: Vector2 = Vector2(64.0, 62.0)
const LAYER_NAMES: Array[String] = ["1 · Frame · a Place-Card", "2 · Card · what you do", "3 · Helper · a Tuck underneath"]
## The collection's filter tabs, in the wireframe's order, and the layer each shows.
const FILTERS: Array[int] = [GrimoireBinderPanel.Layer.CARD, GrimoireBinderPanel.Layer.TUCK, GrimoireBinderPanel.Layer.PLACE]
const RULES_NOTE: String = "Your level opens the diamonds, ink pays for the cards. Seven slots, seven different cards."

var binder: GrimoireBinderPanel
var _cross_box: VBoxContainer
var _pair_text: Label
var _middle: VBoxContainer
var _right: VBoxContainer
## The big card in the spotlight while you choose (the celebration flies from here).
var spotlight: InkCardFace


func build(owner: GrimoireBinderPanel) -> void:
	binder = owner
	name = "CardBench"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = GrimoireBinderPanel.SHEET_SIZE
	var cross_panel: PanelContainer = BinderKit.panel(AtelierTheme.page_style())
	BinderKit.place(self, cross_panel, LEFT.position, LEFT.size.x, LEFT.size.y)
	_cross_box = BinderKit.column(14)
	_cross_box.alignment = BoxContainer.ALIGNMENT_CENTER
	cross_panel.add_child(_cross_box)
	var holder: CenterContainer = CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(LEFT.size.x - 40.0, 400.0)
	_cross_box.add_child(holder)
	holder.add_child(binder.widget)
	_pair_text = BinderKit.text("", AtelierTheme.BODY_SIZE - 1, AtelierTheme.INK, LEFT.size.x - 48.0)
	_pair_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cross_box.add_child(_pair_text)
	_middle = BinderKit.column(8)
	BinderKit.place(self, _middle, MIDDLE.position, MIDDLE.size.x)
	_right = BinderKit.column(8)
	BinderKit.place(self, _right, RIGHT.position, RIGHT.size.x)


func refresh() -> void:
	if not is_instance_valid(binder) or not is_instance_valid(binder.actor):
		return
	var synergy: Dictionary = binder.widget.socket_view(binder.selected_socket())["synergy"]
	_pair_text.text = GrimoireBinderPanel._diorama_text(synergy)
	_pair_text.add_theme_color_override(&"font_color", AtelierTheme.GOLD if synergy["is_home_ground_harmony"] else AtelierTheme.INK)
	if binder.column == GrimoireBinderPanel.Column.DIAMONDS:
		spotlight = null
		_fill_bench()
	else:
		_fill_spotlight()
	_fill_collection()


# --- Middle, on the bench: the hand, the diamond and its layers ---------------------------------

func _fill_bench() -> void:
	BinderKit.clear(_middle)
	var progress: PartyProgress = PartyProgress.current
	var level: int = progress.character_level(binder.actor.loadout.class_id)
	var head: HBoxContainer = BinderKit.line(8)
	var hand_line: Label = BinderKit.text("Your hand at Lv %d · %d of 7" % [level, GrimoireRules.slots_open(level)], AtelierTheme.BODY_SIZE, AtelierTheme.INK)
	hand_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hand_line)
	head.add_child(BinderKit.text("Ink-Well: %d drops" % binder.well_depth(), AtelierTheme.BODY_SIZE, AtelierTheme.INK_DROP))
	_middle.add_child(head)
	var strip: HBoxContainer = BinderKit.line(6)
	for tile: Array in binder.hand_tiles():
		strip.add_child(_hand_tile(tile))
	_middle.add_child(strip)
	var socket: int = binder.selected_socket()
	_middle.add_child(BinderKit.text(binder.socket_title(socket), BinderKit.NAME_SIZE, AtelierTheme.GOLD))
	_middle.add_child(BinderKit.text(binder.socket_cost_line(socket), AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK_MUTED))
	if not GrimoireRules.socket_open(socket, level):
		var shut: PanelContainer = BinderKit.row_box(false, true)
		shut.add_child(BinderKit.text("▢ %s. You're Lv %d: keep going, it opens soon!" % [GrimoireRules.socket_opens_text(socket), level],
			AtelierTheme.BODY_SIZE, AtelierTheme.INK_DIM, MIDDLE.size.x - 30.0))
		_middle.add_child(shut)
	else:
		for layer: int in LAYER_NAMES.size():
			_middle.add_child(_layer_row(layer))
	_middle.add_child(_guide_row())


## One of the seven slots: its name, and the card in it (or the level it opens at).
func _hand_tile(tile: Array) -> PanelContainer:
	var open: bool = bool(tile[2])
	var style: StyleBoxFlat = AtelierTheme.chip_style(AtelierTheme.GILT if open else AtelierTheme.LINE, AtelierTheme.PAGE_RAISED if open else AtelierTheme.ROW)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4.0)
	var box: PanelContainer = BinderKit.panel(style)
	box.custom_minimum_size = HAND_TILE
	var stack: VBoxContainer = BinderKit.column(2)
	box.add_child(stack)
	var named: Label = BinderKit.text(String(tile[0]), 10, AtelierTheme.GILT if open else AtelierTheme.INK_DIM)
	named.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(named)
	var held: Label = BinderKit.text(String(tile[1]), 11, AtelierTheme.INK if open else AtelierTheme.INK_DIM, HAND_TILE.x - 8.0)
	held.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(held)
	return box


## A layer of the chosen diamond: what's in it now, and (for the Tuck) where it sits.
func _layer_row(layer: int) -> PanelContainer:
	var chosen: bool = binder.bench_layer == layer
	var box: PanelContainer = BinderKit.row_box(chosen, false, 10.0)
	BinderKit.on_click(box, binder.open_layer.bind(layer))
	var stack: VBoxContainer = BinderKit.column(3)
	box.add_child(stack)
	var top: HBoxContainer = BinderKit.line(8)
	var kicker: Label = BinderKit.kicker(LAYER_NAMES[layer])
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(kicker)
	top.add_child(BinderKit.chip("light · choose" if chosen else "choose", AtelierTheme.GOLD if chosen else AtelierTheme.LINE_DIM))
	stack.add_child(top)
	var held: StringName = binder.layer_copy(layer)
	var card: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(held)) if held != &"" else null
	var title: HBoxContainer = BinderKit.line(8)
	title.add_child(BinderKit.text(card.display_name if card != null else binder.empty_layer_text(layer), BinderKit.NAME_SIZE - 3,
		AtelierTheme.INK if card != null else AtelierTheme.INK_DIM))
	if card != null:
		title.add_child(BinderKit.sign_chip(card.scribe_sign))
	stack.add_child(title)
	var about: String = card.kid_text if card != null and card.kid_text != "" else binder.layer_about(layer, held)
	if about != "":
		stack.add_child(BinderKit.text(about, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_MUTED, MIDDLE.size.x - 30.0))
	if layer == GrimoireBinderPanel.Layer.TUCK:
		var spots: HBoxContainer = BinderKit.line(6)
		for spot: Array in binder.tuck_spots():
			var here: bool = bool(spot[1])
			var can: bool = bool(spot[2])
			spots.add_child(BinderKit.chip(String(spot[0]), AtelierTheme.GOLD if here else (AtelierTheme.LINE_DIM if can else AtelierTheme.LINE),
				AtelierTheme.INK if here else (AtelierTheme.INK_MUTED if can else AtelierTheme.INK_DIM)))
		stack.add_child(spots)
	return box


## The last row on the bench: the picture guide to a diamond.
func _guide_row() -> PanelContainer:
	var chosen: bool = binder.bench_layer == GrimoireBinderPanel.GUIDE_ROW
	var box: PanelContainer = BinderKit.row_box(chosen, false, 10.0)
	BinderKit.on_click(box, binder.show_guide)
	var row: HBoxContainer = BinderKit.line(10)
	box.add_child(row)
	row.add_child(BinderKit.chip("?", AtelierTheme.GOLD))
	row.add_child(BinderKit.text("How does a diamond work?", AtelierTheme.BODY_SIZE + 1, AtelierTheme.GOLD if chosen else AtelierTheme.INK))
	return box


# --- Middle, choosing: the highlighted card, big ---------------------------------------------------

func _fill_spotlight() -> void:
	BinderKit.clear(_middle)
	var layer: int = binder.shown_layer()
	var options: Array[StringName] = binder.layer_options(layer)
	var key: StringName = options[clampi(binder.layer_row(layer), 0, options.size() - 1)]
	var holder: CenterContainer = CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(MIDDLE.size.x, SPOTLIGHT_CARD.y + 8.0)
	_middle.add_child(holder)
	spotlight = InkCardFace.new(key)
	spotlight.custom_minimum_size = SPOTLIGHT_CARD
	spotlight.socket_word = GrimoireRules.SOCKET_NAMES[binder.selected_socket()] if layer == GrimoireBinderPanel.Layer.CARD else ""
	holder.add_child(spotlight)
	var verdict: Array = binder.fit_verdict(layer, key)
	var fits: bool = bool(verdict[1])
	var go: PanelContainer = BinderKit.row_box(fits, not fits, 10.0)
	go.add_child(BinderKit.text(binder.spotlight_words(layer, key, verdict), AtelierTheme.BODY_SIZE + 1, AtelierTheme.GOLD if fits else AtelierTheme.BAD,
		MIDDLE.size.x - 30.0))
	BinderKit.on_click(go, binder.accept)
	_middle.add_child(go)
	var card: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(key)) if key != &"" else null
	if card != null and card.flavor_text != "":
		_middle.add_child(BinderKit.text("“%s”" % card.flavor_text, AtelierTheme.SMALL_SIZE, AtelierTheme.sign_text(card.scribe_sign), MIDDLE.size.x))


# --- Right: your cards as pictures ------------------------------------------------------------------

func _fill_collection() -> void:
	BinderKit.clear(_right)
	var layer: int = binder.shown_layer()
	_right.add_child(BinderKit.text("Your cards", BinderKit.NAME_SIZE, AtelierTheme.INK))
	var filters: HBoxContainer = BinderKit.line(6)
	for shown: int in FILTERS:
		var on: bool = layer == shown
		var tab: PanelContainer = BinderKit.panel(AtelierTheme.tab_style(on))
		tab.add_child(BinderKit.text(binder.filter_name(shown), AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK if on else AtelierTheme.INK_MUTED))
		BinderKit.on_click(tab, binder.open_layer.bind(shown))
		filters.add_child(tab)
	_right.add_child(filters)
	var options: Array[StringName] = binder.layer_options(layer)
	var cursor: int = binder.layer_row(layer)
	var browsing: bool = binder.column != GrimoireBinderPanel.Column.DIAMONDS
	var last_row: int = maxi(0, (options.size() - 1) / GRID_COLUMNS)
	var first_row: int = clampi(cursor / GRID_COLUMNS - (GRID_ROWS - 1), 0, maxi(0, last_row - (GRID_ROWS - 1)))
	var first: int = first_row * GRID_COLUMNS
	if first > 0:
		_right.add_child(BinderKit.text("↑ more cards", AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 10)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right.add_child(grid)
	for index: int in range(first, mini(options.size(), first + GRID_COLUMNS * GRID_ROWS)):
		grid.add_child(_mini_card(layer, options[index], index, browsing and index == cursor))
	if options.size() > first + GRID_COLUMNS * GRID_ROWS:
		_right.add_child(BinderKit.text("↓ more cards", AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	_right.add_child(BinderKit.text(RULES_NOTE, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM, RIGHT.size.x))


## One card in the grid: its picture, and a little ribbon saying "in use", "fits" or why not.
func _mini_card(layer: int, copy_key: StringName, index: int, chosen: bool) -> Control:
	var verdict: Array = binder.fit_verdict(layer, copy_key)
	var stack: VBoxContainer = BinderKit.column(3)
	var face: InkCardFace = InkCardFace.new(copy_key, true)
	face.custom_minimum_size = MINI_CARD
	face.chosen = chosen
	face.shut = not bool(verdict[1])
	BinderKit.on_click(face, binder.pick_layer_row.bind(layer, index))
	stack.add_child(face)
	var said: String = String(verdict[0])
	var colour: Color = AtelierTheme.GOOD if bool(verdict[1]) else AtelierTheme.BAD
	if said == "in use" or said == "tucked":
		colour = AtelierTheme.GOLD
	var ribbon: Label = BinderKit.text(said, AtelierTheme.SMALL_SIZE - 1, colour)
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.custom_minimum_size = Vector2(MINI_CARD.x, 0.0)
	ribbon.clip_text = true
	stack.add_child(ribbon)
	return stack
