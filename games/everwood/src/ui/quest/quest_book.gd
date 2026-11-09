## The quest book: one gilt-edged page down the left of the hero's view (the living
## storybook atelier look), with the world still showing to its right. B opens and closes
## it (on a pad, hold Share and tap D-Pad ↓); it opens over play, never mid-fight.
##
##   left    Act I's five quests, each with its seal: a green tick when done, a gold star
##           for the one under way, a "?" for those still to come (named once they open)
##   right   the chosen quest: who asked, its story in a young player's words, its steps
##           (done ones ticked, the one under way lit with its count and where it is, the
##           rest kept a surprise), and what finishing it gives
##   bottom  "Show me the way": the firefly trail to the step under way, and the book
##           closes so the hero can follow it
## Up / down choose a quest (a click works too), light shows the way, dodge closes.
class_name QuestBook
extends Control

signal closed

const SHEET: Vector2 = Vector2(1600.0, 900.0)
const PAGE: Rect2 = Rect2(36.0, 64.0, 780.0, 790.0)
const LIST_AT: Vector2 = Vector2(64.0, 176.0)
const LIST_WIDTH: float = 248.0
const DETAIL_AT: Vector2 = Vector2(336.0, 176.0)
const DETAIL_WIDTH: float = 452.0
const MIN_FIT: float = 0.42

var actor: ActorBase
var hud: PlayerHUD
## The quest the page is open at (an index into ActOneQuests.ORDER).
var selected: int = 0

var _sheet: Control
var _summary: Label
var _list: VBoxContainer
var _detail: VBoxContainer
var _way_row: PanelContainer
var _hint: Label


func setup(target_actor: ActorBase, on_hud: PlayerHUD) -> void:
	actor = target_actor
	hud = on_hud


func _ready() -> void:
	name = "QuestBook"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet = Control.new()
	_sheet.name = "Sheet"
	_sheet.size = SHEET
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet)
	var page: PanelContainer = BinderKit.panel(_page_style())
	page.name = "Page"
	BinderKit.place(_sheet, page, PAGE.position, PAGE.size.x, PAGE.size.y)
	var ribbon: Control = Control.new()
	ribbon.name = "Ribbon"
	ribbon.size = SHEET
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.draw.connect(_draw_ribbon.bind(ribbon))
	_sheet.add_child(ribbon)
	var heading: VBoxContainer = BinderKit.column(2)
	heading.position = Vector2(64.0, 86.0)
	_sheet.add_child(heading)
	heading.add_child(BinderKit.kicker("Quest book"))
	heading.add_child(BinderKit.text("Act I · The Fading Margin", AtelierTheme.TITLE_SIZE + 4, AtelierTheme.GOLD))
	_summary = BinderKit.text("", AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK_MUTED)
	_summary.position = Vector2(470.0, 128.0)
	_summary.size = Vector2(250.0, 20.0)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sheet.add_child(_summary)
	_list = BinderKit.column(10)
	_list.name = "Quests"
	_list.position = LIST_AT
	_list.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	_sheet.add_child(_list)
	_detail = BinderKit.column(10)
	_detail.name = "Detail"
	_detail.position = DETAIL_AT
	_detail.custom_minimum_size = Vector2(DETAIL_WIDTH, 0.0)
	_sheet.add_child(_detail)
	_way_row = BinderKit.row_box(true, false, 12.0)
	_way_row.name = "ShowTheWay"
	BinderKit.place(_sheet, _way_row, Vector2(64.0, 742.0), LIST_WIDTH + 18.0 + DETAIL_WIDTH, 0.0)
	BinderKit.on_click(_way_row, show_the_way)
	_hint = BinderKit.text("", AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK_MUTED)
	_hint.position = Vector2(64.0, 812.0)
	_sheet.add_child(_hint)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(_on_menu_input)
	if QuestManager.current != null:
		QuestManager.current.ledger_changed.connect(_refresh)
		var now: int = ActOneQuests.ORDER.find(QuestManager.current.active_quest_id())
		selected = now if now >= 0 else _last_open()
	_refresh()


func _exit_tree() -> void:
	if QuestManager.current != null and QuestManager.current.ledger_changed.is_connected(_refresh):
		QuestManager.current.ledger_changed.disconnect(_refresh)
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
		if actor.input.menu_input.is_connected(_on_menu_input):
			actor.input.menu_input.disconnect(_on_menu_input)


func _process(_delta: float) -> void:
	var fit: float = clampf(minf(size.x / SHEET.x, size.y / SHEET.y), MIN_FIT, 1.0)
	_sheet.scale = Vector2.ONE * fit
	_sheet.position = Vector2(0.0, (size.y - SHEET.y * fit) * 0.5)


func close() -> void:
	if is_queued_for_deletion():
		return
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


func select(index: int) -> void:
	selected = clampi(index, 0, ActOneQuests.ORDER.size() - 1)
	AudioCues.play(&"menu_move")
	_refresh()


## Lights the firefly trail to the step under way and closes the book so the hero can follow it.
## Returns whether there was a way to show.
func show_the_way() -> bool:
	if not _shows_way():
		AudioCues.play(&"refuse")
		return false
	QuestKit.show_the_way(hud)
	AudioCues.play(&"chime")
	close()
	if hud != null:
		hud.show_banner("FOLLOW THE FIREFLIES", "They'll lead you to %s" % ActOnePlaces.display_name(QuestManager.current.active_step().place_id),
			AtelierTheme.GOLD, 2.5)
	return true


## The quest's seal in the book: done, under way, or still to come.
func seal_of(index: int) -> QuestGlyph.Mark:
	var quests: QuestManager = QuestManager.current
	if quests == null:
		return QuestGlyph.Mark.LATER
	match quests.state_of(ActOneQuests.ORDER[index]):
		QuestManager.QuestState.COMPLETE:
			return QuestGlyph.Mark.DONE
		QuestManager.QuestState.ACTIVE:
			return QuestGlyph.Mark.NOW
	return QuestGlyph.Mark.LATER


## The detail page's words, top to bottom (for the checks).
func detail_text() -> String:
	var words: PackedStringArray = PackedStringArray()
	_gather(_detail, words)
	return "\n".join(words)


func way_text() -> String:
	return _gather_one(_way_row)


func _on_menu_input(action: StringName) -> void:
	match action:
		InputComponent.MENU_UP:
			select(wrapi(selected - 1, 0, ActOneQuests.ORDER.size()))
		InputComponent.MENU_DOWN:
			select(wrapi(selected + 1, 0, ActOneQuests.ORDER.size()))
		InputComponent.MENU_ACCEPT:
			show_the_way()
		InputComponent.MENU_BACK:
			close()


func _refresh() -> void:
	if not is_inside_tree():
		return
	var quests: QuestManager = QuestManager.current
	var done: int = 0
	for quest_id: StringName in ActOneQuests.ORDER:
		if quests != null and quests.is_complete(quest_id):
			done += 1
	var level: int = PartyProgress.level_for_xp(PartyProgress.current.xp) if PartyProgress.current != null else 0
	_summary.text = ("%d of %d done" % [done, ActOneQuests.ORDER.size()]) + (" · Level %d" % level if level > 0 else "")
	_build_list()
	_build_detail()
	_build_way()


func _build_list() -> void:
	BinderKit.clear(_list)
	for index: int in ActOneQuests.ORDER.size():
		var quest: QuestDefinition = ActOneQuests.quest(ActOneQuests.ORDER[index])
		var seal: QuestGlyph.Mark = seal_of(index)
		var chosen: bool = index == selected
		var row: PanelContainer = BinderKit.row_box(chosen, seal == QuestGlyph.Mark.LATER, 10.0)
		var line: HBoxContainer = BinderKit.line(10)
		row.add_child(line)
		var glyph: QuestGlyph = QuestGlyph.new(seal, AtelierTheme.GOLD if seal == QuestGlyph.Mark.NOW else AtelierTheme.GILT, 38.0)
		glyph.pulse = seal == QuestGlyph.Mark.NOW
		line.add_child(glyph)
		var words: VBoxContainer = BinderKit.column(0)
		line.add_child(words)
		words.add_child(BinderKit.kicker("Quest %d" % quest.number, AtelierTheme.GOLD if seal == QuestGlyph.Mark.NOW else AtelierTheme.GILT))
		var known: bool = seal != QuestGlyph.Mark.LATER
		words.add_child(BinderKit.text(quest.title if known else "A quest to come", AtelierTheme.BODY_SIZE, AtelierTheme.INK if known else AtelierTheme.INK_DIM,
			LIST_WIDTH - 82.0))
		var at: int = index
		BinderKit.on_click(row, func() -> void: select(at))
		_list.add_child(row)


func _build_detail() -> void:
	BinderKit.clear(_detail)
	var quests: QuestManager = QuestManager.current
	var quest: QuestDefinition = ActOneQuests.quest(ActOneQuests.ORDER[selected])
	var seal: QuestGlyph.Mark = seal_of(selected)
	if seal == QuestGlyph.Mark.LATER:
		_detail.add_child(BinderKit.text("? ? ?", BinderKit.BIG_SIZE, AtelierTheme.INK_DIM))
		_detail.add_child(BinderKit.text("Finish the quests before this one to find out what happens next!", AtelierTheme.BODY_SIZE + 1, AtelierTheme.INK_MUTED,
			DETAIL_WIDTH))
		return
	_detail.add_child(BinderKit.text(quest.title, BinderKit.NAME_SIZE + 4, AtelierTheme.GOLD, DETAIL_WIDTH))
	var who: HBoxContainer = BinderKit.line(8)
	who.add_child(QuestGlyph.new(QuestGlyph.Mark.TALK, AtelierTheme.GILT, 26.0))
	who.add_child(BinderKit.text("From %s" % QuestKit.giver(quest), AtelierTheme.BODY_SIZE, AtelierTheme.INK_MUTED))
	var state_word: String = "Done!" if seal == QuestGlyph.Mark.DONE else "Doing now"
	who.add_child(BinderKit.chip(state_word, AtelierTheme.GOOD if seal == QuestGlyph.Mark.DONE else AtelierTheme.GOLD))
	_detail.add_child(who)
	_detail.add_child(BinderKit.text(QuestKit.story(quest), AtelierTheme.BODY_SIZE + 1, AtelierTheme.INK, DETAIL_WIDTH))
	_detail.add_child(BinderKit.kicker("What to do"))
	var on_step: int = quests.step_of(quest.quest_id) if seal == QuestGlyph.Mark.NOW else quest.steps.size()
	for index: int in quest.steps.size():
		if index > on_step:
			break
		_detail.add_child(_step_row(quest, quest.steps[index], index < on_step))
	if on_step < quest.steps.size() - 1:
		var later: HBoxContainer = BinderKit.line(10)
		later.add_child(QuestGlyph.new(QuestGlyph.Mark.LATER, AtelierTheme.LINE_DIM, 30.0))
		later.add_child(BinderKit.text("More to discover...", AtelierTheme.BODY_SIZE, AtelierTheme.INK_DIM))
		_detail.add_child(later)
	_detail.add_child(BinderKit.kicker("What you get"))
	var gifts: HFlowContainer = HFlowContainer.new()
	gifts.add_theme_constant_override(&"h_separation", 6)
	gifts.add_theme_constant_override(&"v_separation", 6)
	gifts.custom_minimum_size = Vector2(DETAIL_WIDTH, 0.0)
	gifts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gifts.add_child(BinderKit.chip("+%d XP" % quest.xp_reward, AtelierTheme.GOLD))
	gifts.add_child(BinderKit.chip("Reach Level %d" % quest.level_to, AtelierTheme.GOLD))
	for gift: String in QuestKit.gifts(quest):
		gifts.add_child(BinderKit.chip(gift, AtelierTheme.INK_DROP, AtelierTheme.INK_DROP_EDGE))
	_detail.add_child(gifts)


## One step: ticked when done; the one under way lit, with its count and where it is.
func _step_row(quest: QuestDefinition, step: QuestStepResource, done: bool) -> Control:
	if done:
		var line: HBoxContainer = BinderKit.line(10)
		line.add_child(QuestGlyph.new(QuestGlyph.Mark.DONE, AtelierTheme.GOOD, 30.0))
		line.add_child(BinderKit.text(step.text, AtelierTheme.BODY_SIZE, AtelierTheme.INK_DIM, DETAIL_WIDTH - 44.0))
		return line
	var row: PanelContainer = BinderKit.row_box(true, false, 10.0)
	var stack: VBoxContainer = BinderKit.column(4)
	row.add_child(stack)
	var top: HBoxContainer = BinderKit.line(10)
	stack.add_child(top)
	var glyph: QuestGlyph = QuestGlyph.new(QuestGlyph.for_kind(step.kind), AtelierTheme.GOLD, 34.0)
	glyph.pulse = true
	top.add_child(glyph)
	top.add_child(BinderKit.text(step.text, AtelierTheme.BODY_SIZE + 2, AtelierTheme.INK, DETAIL_WIDTH - 80.0))
	var counted: String = QuestKit.progress_line(quest.quest_id, step)
	var spot: Dictionary = QuestKit.where(actor, step)
	var where: String = String(spot["name"])
	if bool(spot["here"]):
		where += " · You're here!"
	elif String(spot["words"]) != "":
		where += " · %s" % spot["words"]
	var under: String = ("Done so far: %s   " % counted if counted != "" else "") + ("Where: %s" % where if where != "" else "")
	if under != "":
		stack.add_child(BinderKit.text(under, AtelierTheme.BODY_SIZE - 1, AtelierTheme.GOOD if bool(spot["here"]) else AtelierTheme.GILT, DETAIL_WIDTH - 40.0))
	return row


func _build_way() -> void:
	BinderKit.clear(_way_row)
	var line: HBoxContainer = BinderKit.line(12)
	_way_row.add_child(line)
	var open: bool = _shows_way()
	line.add_child(TalkBox.key_chip(_label(InputComponent.ACTION_LIGHT), open))
	line.add_child(QuestGlyph.new(QuestGlyph.Mark.GO, AtelierTheme.GOLD if open else AtelierTheme.LINE_DIM, 30.0))
	var words: String = "Show me the way! (the fireflies will lead you)" if open else (
		"Pick the quest you're doing to see the way" if seal_of(selected) != QuestGlyph.Mark.NOW else "This step happens wherever you are")
	line.add_child(BinderKit.text(words, AtelierTheme.HEADING_SIZE, AtelierTheme.INK if open else AtelierTheme.INK_DIM))
	_way_row.modulate.a = 1.0 if open else 0.7
	_hint.text = "%s / %s choose a quest  ·  %s show the way  ·  %s or %s close" % [_label(InputComponent.ACTION_MOVE_FORWARD),
		_label(InputComponent.ACTION_MOVE_BACK), _label(InputComponent.ACTION_LIGHT), _label(InputComponent.ACTION_DODGE), QuestTracker.book_key(actor)]


## Whether "Show me the way" works on the open page: the quest under way, with a place to go.
func _shows_way() -> bool:
	var quests: QuestManager = QuestManager.current
	if quests == null or seal_of(selected) != QuestGlyph.Mark.NOW:
		return false
	var step: QuestStepResource = quests.active_step()
	return step != null and ActOnePlaces.has_place(step.place_id)


func _last_open() -> int:
	var last: int = 0
	for index: int in ActOneQuests.ORDER.size():
		if seal_of(index) != QuestGlyph.Mark.LATER:
			last = index
	return last


func _label(action: StringName) -> String:
	return actor.input.label(action) if is_instance_valid(actor) and actor.input != null else "?"


func _page_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = AtelierTheme.page_style(false)
	style.bg_color = Color(AtelierTheme.PAGE, 0.95)
	style.set_border_width_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 16
	return style


## A gilt bookmark ribbon hanging from the page's top edge, and a rule under the heading.
func _draw_ribbon(on: Control) -> void:
	var x: float = PAGE.end.x - 70.0
	on.draw_colored_polygon(PackedVector2Array([Vector2(x, PAGE.position.y - 10.0), Vector2(x + 30.0, PAGE.position.y - 10.0), Vector2(x + 30.0, PAGE.position.y + 66.0),
		Vector2(x + 15.0, PAGE.position.y + 54.0), Vector2(x, PAGE.position.y + 66.0)]), Color("#8C2F2A"))
	on.draw_line(Vector2(x + 4.0, PAGE.position.y - 10.0), Vector2(x + 4.0, PAGE.position.y + 60.0), Color("#B4524A"), 2.0)
	on.draw_line(Vector2(64.0, 156.0), Vector2(PAGE.end.x - 28.0, 156.0), AtelierTheme.LINE, 1.5)
	on.draw_line(Vector2(DETAIL_AT.x - 14.0, 172.0), Vector2(DETAIL_AT.x - 14.0, 728.0), AtelierTheme.LINE, 1.0)


static func _gather(node: Node, into: PackedStringArray) -> void:
	for child: Node in node.get_children():
		if child is Label:
			into.append((child as Label).text)
		_gather(child, into)


static func _gather_one(node: Node) -> String:
	var words: PackedStringArray = PackedStringArray()
	_gather(node, words)
	return " ".join(words)
