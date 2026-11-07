## Binder tab 4, the Seal Press, as the Seals wireframe lays it out
## (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md R3, R4, R5, the Contextual
## Slot Rule) on the Binder's 1600 x 900 sheet:
##   top     the three Seals (weapon, offhand, mantle): what's pressed on each,
##           and the level a locked one opens at
##   left    the cards you can press into the chosen slot: finish, Marks, spare
##           copies, and where each one is now ("on the weapon", "in use")
##   middle  the highlighted card slot by slot (what it does on the weapon, the
##           offhand and the mantle), what you lose and gain pressing it here,
##           and its Ink-Binding ladder (Plain Ink, Gilded Leaf, Star-Ink)
##   right   the live hero, and Press / Leave it
## Left / right picks the slot, up / down the card, light presses it, dodge goes
## back to Gear & Weapon. Presses happen at a Hearth-Brazier or the Scribe Desk;
## anywhere else the page is look-only and says so.
class_name BinderSealPressPage
extends Control

const STRIP: Rect2 = Rect2(40.0, 228.0, 1520.0, 76.0)
const LEFT: Rect2 = Rect2(40.0, 320.0, 440.0, 510.0)
const MIDDLE: Rect2 = Rect2(504.0, 320.0, 662.0, 510.0)
const RIGHT: Rect2 = Rect2(1190.0, 320.0, 370.0, 510.0)
const PREVIEW_BOX: Vector2 = Vector2(370.0, 420.0)
const LIST_ROWS: int = 7
const SLOT_HEADS: Array[String] = ["On the weapon", "On the offhand", "On the mantle"]
const PIECE_WORDS: Array[String] = ["weapon", "offhand", "mantle"]
const FINISH_STEPS: Array[String] = ["as it's found", "100 Marks · +15% potency", "250 Marks · +30% and the Maker-Seal"]
const MARKS_NOTE: String = "Calm foes while it's pressed, or feed it a spare copy (+100), then press it at the Scribery. Marks stay on the card when you change gear."

var binder: GrimoireBinderPanel
var _strip: HBoxContainer
var _list: VBoxContainer
var _detail: VBoxContainer
var _right: VBoxContainer
## Where the Binder's preview frame sits while this tab shows.
var preview_slot: Control
var _actions: VBoxContainer


func build(owner: GrimoireBinderPanel) -> void:
	binder = owner
	name = "SealPressPage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = GrimoireBinderPanel.SHEET_SIZE
	_strip = BinderKit.line(12)
	BinderKit.place(self, _strip, STRIP.position, STRIP.size.x)
	_list = BinderKit.column(6)
	BinderKit.place(self, _list, LEFT.position, LEFT.size.x)
	_detail = BinderKit.column(10)
	BinderKit.place(self, _detail, MIDDLE.position, MIDDLE.size.x)
	_right = BinderKit.column(10)
	BinderKit.place(self, _right, RIGHT.position, RIGHT.size.x)
	preview_slot = Control.new()
	preview_slot.name = "PreviewSlot"
	preview_slot.custom_minimum_size = PREVIEW_BOX
	preview_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right.add_child(preview_slot)
	_actions = BinderKit.column(6)
	_right.add_child(_actions)


func refresh() -> void:
	if not is_instance_valid(binder) or not is_instance_valid(binder.actor) or binder.actor.seal == null:
		return
	_fill_strip()
	_fill_list()
	_fill_detail()
	_fill_actions()


# --- Top: the three Seals ---------------------------------------------------------------------

func _fill_strip() -> void:
	BinderKit.clear(_strip)
	var rows: Array[Label] = []
	for slot: int in GrimoireBinderPanel.SEAL_ROWS:
		var chosen: bool = binder.seal_row == slot
		var open: bool = binder.seal_slot_open(slot)
		var box: PanelContainer = BinderKit.row_box(chosen, not open)
		box.custom_minimum_size = Vector2(420.0, STRIP.size.y)
		BinderKit.on_click(box, binder.pick_seal_slot.bind(slot))
		var stack: VBoxContainer = BinderKit.column(2)
		box.add_child(stack)
		stack.add_child(BinderKit.kicker("%s · Lv %d%s" % [PIECE_WORDS[slot], GrimoireRules.SEAL_OPEN_LEVELS[slot], " · chosen" if chosen else ""],
			AtelierTheme.GILT if open else AtelierTheme.INK_DIM))
		var named: Label = BinderKit.text(binder.seal_tile_text(slot), AtelierTheme.BODY_SIZE + 1, AtelierTheme.INK if open else AtelierTheme.INK_DIM)
		named.clip_text = true
		named.custom_minimum_size = Vector2(400.0, 0.0)
		named.tooltip_text = binder.seal_row_text(slot)
		stack.add_child(named)
		rows.append(named)
		_strip.add_child(box)
	var level: int = binder.actor.seal.true_level
	var count: int = 0
	for opens: int in GrimoireRules.SEAL_OPEN_LEVELS:
		count += 1 if level >= opens or GrimoireRules.all_open() else 0
	var summary: Label = BinderKit.text("Seals open: %d of 3 · Stage %d" % [count, binder.actor.seal.progression_stage], AtelierTheme.BODY_SIZE, AtelierTheme.INK_MUTED)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_strip.add_child(summary)
	binder._seal_rows = rows


# --- Left: the cards you can press -------------------------------------------------------------

func _fill_list() -> void:
	BinderKit.clear(_list)
	_list.add_child(BinderKit.text("Cards you can press", BinderKit.NAME_SIZE, AtelierTheme.INK))
	var options: Array[StringName] = binder.seal_options(binder.seal_row)
	var cursor: int = clampi(binder.press_row, 0, maxi(0, options.size() - 1))
	var first: int = clampi(cursor - (LIST_ROWS >> 1), 0, maxi(0, options.size() - LIST_ROWS))
	for index: int in range(first, mini(options.size(), first + LIST_ROWS)):
		_list.add_child(_candidate_row(options[index], index, index == cursor))
	if options.size() > first + LIST_ROWS:
		_list.add_child(BinderKit.text("↓ %d more" % (options.size() - first - LIST_ROWS), AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	_list.add_child(BinderKit.text("Your 7 slots hold 7 different cards: a card on your sword can't also be in your pocket. Pressing a Seal that's on another piece moves it here.",
		AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM, LEFT.size.x))


func _candidate_row(card_id: StringName, index: int, chosen: bool) -> PanelContainer:
	var where: String = binder.seal_whereabouts(card_id)
	var box: PanelContainer = BinderKit.row_box(chosen, false, 8.0)
	box.custom_minimum_size = Vector2(LEFT.size.x, 0.0)
	box.clip_contents = true
	BinderKit.on_click(box, binder.pick_press_row.bind(index))
	var split: HBoxContainer = BinderKit.line(8)
	box.add_child(split)
	var stack: VBoxContainer = BinderKit.column(2)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(stack)
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(card_id)
	if card == null:
		stack.add_child(BinderKit.text("Leave the slot empty", AtelierTheme.BODY_SIZE, AtelierTheme.INK_MUTED))
		stack.add_child(BinderKit.text("No Seal on this piece", AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	else:
		stack.add_child(BinderKit.text(card.display_name, AtelierTheme.BODY_SIZE, AtelierTheme.INK))
		stack.add_child(BinderKit.text(binder.seal_candidate_note(card_id), AtelierTheme.SMALL_SIZE, AtelierTheme.sign_text(card.scribe_sign), LEFT.size.x - 160.0))
	if where != "":
		split.add_child(BinderKit.chip(where, AtelierTheme.GOLD if where.begins_with("on the") else AtelierTheme.LINE_DIM))
	return box


# --- Middle: the card slot by slot ------------------------------------------------------------

func _fill_detail() -> void:
	BinderKit.clear(_detail)
	var card_id: StringName = binder.press_candidate()
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(card_id)
	if card == null:
		_detail.add_child(BinderKit.text("An empty %s" % PIECE_WORDS[binder.seal_row], BinderKit.NAME_SIZE, AtelierTheme.INK))
		_detail.add_child(BinderKit.text("Lifting the Seal leaves the piece plain: no ward, no bonus. Its card goes back to your binder with its Marks.",
			AtelierTheme.BODY_SIZE - 1, AtelierTheme.INK_MUTED, MIDDLE.size.x))
		return
	_detail.add_child(BinderKit.text("%s, slot by slot" % card.display_name, BinderKit.NAME_SIZE, AtelierTheme.INK))
	var columns: HBoxContainer = BinderKit.line(8)
	var flags: Array[int] = [ScribeCardResource.SealSlotMask.SEAL_WEAPON, ScribeCardResource.SealSlotMask.SEAL_OFFHAND_BUCKLER,
		ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR]
	for slot: int in flags.size():
		var here: bool = slot == binder.seal_row
		var style: StyleBoxFlat = AtelierTheme.row_style(here)
		style.set_content_margin_all(10.0)
		var box: PanelContainer = BinderKit.panel(style)
		box.custom_minimum_size = Vector2((MIDDLE.size.x - 16.0) / 3.0, 96.0)
		var stack: VBoxContainer = BinderKit.column(4)
		box.add_child(stack)
		stack.add_child(BinderKit.kicker(SLOT_HEADS[slot] + (" · this slot" if here else "")))
		stack.add_child(BinderKit.text(String(card.slot_passive(flags[slot]).get("text", "")).strip_edges(), AtelierTheme.SMALL_SIZE,
			AtelierTheme.INK, (MIDDLE.size.x - 16.0) / 3.0 - 24.0))
		columns.add_child(box)
	_detail.add_child(columns)
	_detail.add_child(_trade_panel(card_id))
	_detail.add_child(_ladder(card_id))


## What pressing this card here changes: what the piece loses and what it gains.
func _trade_panel(card_id: StringName) -> PanelContainer:
	var style: StyleBoxFlat = AtelierTheme.page_style(true)
	style.set_content_margin_all(12.0)
	var box: PanelContainer = BinderKit.panel(style)
	var stack: VBoxContainer = BinderKit.column(6)
	box.add_child(stack)
	var worn: StringName = binder.actor.seal.loadout.card_in_slot(binder.seal_row)
	stack.add_child(BinderKit.kicker("If you press it onto the %s" % PIECE_WORDS[binder.seal_row]))
	if worn == card_id:
		stack.add_child(BinderKit.text("It's pressed there now.", AtelierTheme.BODY_SIZE - 1, AtelierTheme.INK_MUTED))
		return box
	var pair: HBoxContainer = BinderKit.line(16)
	var lose: VBoxContainer = BinderKit.column(2)
	lose.add_child(BinderKit.kicker("You lose", AtelierTheme.BAD))
	lose.add_child(BinderKit.text(binder.seal_slot_text(worn, binder.seal_row), AtelierTheme.SMALL_SIZE, AtelierTheme.INK, (MIDDLE.size.x - 60.0) * 0.5))
	pair.add_child(lose)
	var gain: VBoxContainer = BinderKit.column(2)
	gain.add_child(BinderKit.kicker("You gain", AtelierTheme.GOOD))
	gain.add_child(BinderKit.text(binder.seal_slot_text(card_id, binder.seal_row), AtelierTheme.SMALL_SIZE, AtelierTheme.INK, (MIDDLE.size.x - 60.0) * 0.5))
	pair.add_child(gain)
	stack.add_child(pair)
	var worn_card: ScribeCardResource = ArsenalCatalog.current.get_card(worn)
	if worn_card != null:
		stack.add_child(BinderKit.text("The %s goes back to your binder with its Marks." % worn_card.display_name, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	return box


## The Ink-Binding ladder: Plain Ink, then 100 Marks to a Gilded Leaf, then 250 to Star-Ink.
func _ladder(card_id: StringName) -> PanelContainer:
	var style: StyleBoxFlat = AtelierTheme.page_style()
	style.set_content_margin_all(12.0)
	var box: PanelContainer = BinderKit.panel(style)
	var stack: VBoxContainer = BinderKit.column(6)
	box.add_child(stack)
	stack.add_child(BinderKit.kicker("Ink-Binding · seasoned in the field, pressed by the Scribe"))
	var progress: PartyProgress = PartyProgress.current
	var finish: int = maxi(progress.best_finish(card_id), 0)
	var steps: HBoxContainer = BinderKit.line(8)
	for step: int in ScribeCardResource.VARIANT_NAMES.size():
		var reached: bool = step <= finish
		var cell: VBoxContainer = BinderKit.column(2)
		cell.custom_minimum_size = Vector2((MIDDLE.size.x - 40.0) / 3.0, 0.0)
		cell.add_child(BinderKit.text(ScribeCardResource.VARIANT_NAMES[step], AtelierTheme.BODY_SIZE - 1, AtelierTheme.GOLD if step == finish else (AtelierTheme.INK if reached else AtelierTheme.INK_DIM)))
		cell.add_child(BinderKit.text(FINISH_STEPS[step], AtelierTheme.SMALL_SIZE - 1, AtelierTheme.INK_MUTED, (MIDDLE.size.x - 40.0) / 3.0))
		steps.add_child(cell)
	stack.add_child(steps)
	var key: StringName = ScribeCardResource.copy_key(card_id, finish as ScribeCardResource.CardVariant)
	var to_next: int = PartyProgress.marks_needed(key)
	if to_next > 0:
		stack.add_child(BinderKit.marks_bar(progress.marks_of(key), to_next))
		stack.add_child(BinderKit.text(binder.seal_marks_text(card_id), AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM))
	stack.add_child(BinderKit.text(MARKS_NOTE, AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM, MIDDLE.size.x - 30.0))
	return box


# --- Right: Press or leave it --------------------------------------------------------------------

func _fill_actions() -> void:
	BinderKit.clear(_actions)
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(binder.press_candidate())
	if card != null:
		var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(card.scribe_sign)
		_actions.add_child(BinderKit.text("%s ink glows along the %s once it's pressed." % [seal.display_name, PIECE_WORDS[binder.seal_row]],
			AtelierTheme.SMALL_SIZE + 1, AtelierTheme.sign_text(card.scribe_sign), RIGHT.size.x))
	if not binder.seal_press_open():
		var shut: PanelContainer = BinderKit.row_box(false, false, 10.0)
		shut.add_child(BinderKit.text("Look only here. %s." % GrimoireBinderPanel.PRESS_SHUT, AtelierTheme.SMALL_SIZE + 1, AtelierTheme.WARN, RIGHT.size.x - 24.0))
		_actions.add_child(shut)
		return
	var press: PanelContainer = BinderKit.row_box(true)
	press.add_child(BinderKit.text("Light · Press onto the %s" % PIECE_WORDS[binder.seal_row].capitalize(), AtelierTheme.BODY_SIZE, AtelierTheme.GOLD))
	BinderKit.on_click(press, binder.press_highlighted)
	_actions.add_child(press)
	var leave: PanelContainer = BinderKit.row_box(false)
	leave.add_child(BinderKit.text("Dodge · Leave it as it is", AtelierTheme.BODY_SIZE, AtelierTheme.INK_MUTED))
	BinderKit.on_click(leave, binder.show_tab.bind(GrimoireBinderPanel.Tab.GEAR))
	_actions.add_child(leave)
