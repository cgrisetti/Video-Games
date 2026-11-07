## Binder tab 2, Quick Magic-Ink Cards, as the card bench of the Cards wireframe
## (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §2, R4, R5) on the Binder's
## 1600 x 900 sheet:
##   left    the Cross at 2.2x: pick a diamond (L, R, L+R); under it, what the
##           chosen diamond's pair does together
##   middle  your hand at your level (the seven slots, the Ink-Well's depth),
##           the chosen diamond and what it costs, and its three layers:
##           1 the Place-Card that frames it, 2 the Ink card (what you do),
##           3 the one Tuck that slides half under it
##   right   the Ink Card Collection for the chosen layer (Cards, Tucks,
##           Place-Cards), every row saying whether it fits and why not
## Left / right picks the diamond, up / down the layer, light opens the
## collection; there up / down chooses, left / right turns the filter, light
## slots the card and dodge goes back. Every change goes to the host at once.
class_name BinderCardBench
extends Control

const LEFT: Rect2 = Rect2(34.0, 252.0, 516.0, 572.0)
const MIDDLE: Rect2 = Rect2(576.0, 252.0, 494.0, 572.0)
const RIGHT: Rect2 = Rect2(1096.0, 252.0, 464.0, 572.0)
## How many collection rows show at once (the list scrolls with the cursor).
const LIST_ROWS: int = 6
const HAND_TILE: Vector2 = Vector2(64.0, 62.0)
const LAYER_NAMES: Array[String] = ["1 · Place-Card · the frame", "2 · Ink card · what you do", "3 · Tuck · slides half under"]
## The collection's filter tabs, in the wireframe's order, and the layer each shows.
const FILTERS: Array[int] = [GrimoireBinderPanel.Layer.CARD, GrimoireBinderPanel.Layer.TUCK, GrimoireBinderPanel.Layer.PLACE]
const TUCK_NOTE: String = "Same Sign as the card: a Maker-Sleight, one stronger move. A different Sign: a Dual-Sign Strike that cracks two gates. The Tuck is never used up."
const RULES_NOTE: String = "No Memory meter: your level sets the hand, Ink-Drops set the cost. 7 slots, 7 different cards. Every row says why it can or can't go in."

var binder: GrimoireBinderPanel
var _cross_box: VBoxContainer
var _pair_text: Label
var _middle: VBoxContainer
var _right: VBoxContainer


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
	_right = BinderKit.column(6)
	BinderKit.place(self, _right, RIGHT.position, RIGHT.size.x)


func refresh() -> void:
	if not is_instance_valid(binder) or not is_instance_valid(binder.actor):
		return
	var synergy: Dictionary = binder.widget.socket_view(binder.selected_socket())["synergy"]
	_pair_text.text = GrimoireBinderPanel._diorama_text(synergy)
	_pair_text.add_theme_color_override(&"font_color", AtelierTheme.GOLD if synergy["is_home_ground_harmony"] else AtelierTheme.INK)
	_fill_middle()
	_fill_collection()


# --- Middle: the hand, the diamond and its three layers ---------------------------------------

func _fill_middle() -> void:
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
		shut.add_child(BinderKit.text("▢ %s. You're Lv %d." % [GrimoireRules.socket_opens_text(socket), level], AtelierTheme.BODY_SIZE, AtelierTheme.INK_DIM))
		_middle.add_child(shut)
		return
	for layer: int in LAYER_NAMES.size():
		_middle.add_child(_layer_row(layer))
	_middle.add_child(BinderKit.text(TUCK_NOTE, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM, MIDDLE.size.x))


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
	var box: PanelContainer = BinderKit.row_box(chosen)
	BinderKit.on_click(box, binder.open_layer.bind(layer))
	var stack: VBoxContainer = BinderKit.column(4)
	box.add_child(stack)
	var top: HBoxContainer = BinderKit.line(8)
	var kicker: Label = BinderKit.kicker(LAYER_NAMES[layer])
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(kicker)
	top.add_child(BinderKit.chip("light · swap" if chosen else "swap", AtelierTheme.GOLD if chosen else AtelierTheme.LINE_DIM))
	stack.add_child(top)
	var held: StringName = binder.layer_copy(layer)
	var card: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(held)) if held != &"" else null
	var title: HBoxContainer = BinderKit.line(8)
	title.add_child(BinderKit.text(card.display_name if card != null else binder.empty_layer_text(layer), BinderKit.NAME_SIZE - 2,
		AtelierTheme.INK if card != null else AtelierTheme.INK_DIM))
	if card != null:
		title.add_child(BinderKit.sign_chip(card.scribe_sign))
	stack.add_child(title)
	var about: String = binder.layer_about(layer, held)
	if about != "":
		stack.add_child(BinderKit.text(about, AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK_MUTED, MIDDLE.size.x - 30.0))
	if layer == GrimoireBinderPanel.Layer.TUCK:
		var spots: HBoxContainer = BinderKit.line(6)
		for spot: Array in binder.tuck_spots():
			var here: bool = bool(spot[1])
			var can: bool = bool(spot[2])
			spots.add_child(BinderKit.chip(String(spot[0]), AtelierTheme.GOLD if here else (AtelierTheme.LINE_DIM if can else AtelierTheme.LINE),
				AtelierTheme.INK if here else (AtelierTheme.INK_MUTED if can else AtelierTheme.INK_DIM)))
		stack.add_child(spots)
	return box


# --- Right: the Ink Card Collection -------------------------------------------------------------

func _fill_collection() -> void:
	BinderKit.clear(_right)
	_right.add_child(BinderKit.text("The Ink Card Collection", BinderKit.NAME_SIZE, AtelierTheme.INK))
	var filters: HBoxContainer = BinderKit.line(6)
	for layer: int in FILTERS:
		var on: bool = binder.bench_layer == layer
		var tab: PanelContainer = BinderKit.panel(AtelierTheme.tab_style(on))
		tab.add_child(BinderKit.text(binder.filter_name(layer), AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK if on else AtelierTheme.INK_MUTED))
		BinderKit.on_click(tab, binder.open_layer.bind(layer))
		filters.add_child(tab)
	_right.add_child(filters)
	var layer: int = binder.bench_layer
	var options: Array[StringName] = binder.layer_options(layer)
	var cursor: int = binder.layer_row(layer)
	var browsing: bool = binder.column != GrimoireBinderPanel.Column.DIAMONDS
	var first: int = clampi(cursor - (LIST_ROWS >> 1), 0, maxi(0, options.size() - LIST_ROWS))
	if first > 0:
		_right.add_child(BinderKit.text("↑ %d more" % first, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	for index: int in range(first, mini(options.size(), first + LIST_ROWS)):
		_right.add_child(_collection_row(layer, options[index], index, browsing and index == cursor))
	var below: int = options.size() - (first + LIST_ROWS)
	if below > 0:
		_right.add_child(BinderKit.text("↓ %d more" % below, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	_right.add_child(BinderKit.text(RULES_NOTE, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM, RIGHT.size.x))


## A row of the collection: the card, its Sign and a note, and a chip saying whether it fits.
func _collection_row(layer: int, copy_key: StringName, index: int, chosen: bool) -> PanelContainer:
	var verdict: Array = binder.fit_verdict(layer, copy_key)
	var box: PanelContainer = BinderKit.row_box(chosen, not bool(verdict[1]), 8.0)
	BinderKit.on_click(box, binder.pick_layer_row.bind(layer, index))
	var split: HBoxContainer = BinderKit.line(8)
	box.add_child(split)
	var stack: VBoxContainer = BinderKit.column(2)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(stack)
	var card: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key)) if copy_key != &"" else null
	stack.add_child(BinderKit.text(card.display_name if card != null else binder.empty_layer_text(layer), AtelierTheme.BODY_SIZE,
		AtelierTheme.INK if card != null else AtelierTheme.INK_MUTED))
	stack.add_child(BinderKit.text(binder.collection_note(layer, copy_key), AtelierTheme.SMALL_SIZE, AtelierTheme.sign_text(card.scribe_sign) if card != null else AtelierTheme.INK_DIM,
		RIGHT.size.x - 140.0))
	var chip_colour: Color = AtelierTheme.GOOD if bool(verdict[1]) else AtelierTheme.BAD
	if String(verdict[0]) == "in use" or String(verdict[0]) == "tucked":
		chip_colour = AtelierTheme.GOLD
	split.add_child(BinderKit.chip(String(verdict[0]), chip_colour))
	return box
