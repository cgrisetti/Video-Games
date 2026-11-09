## The quest tracker: a small gilt-edged page on the right of the hero's view (the
## living storybook atelier look) that always says what to do next and where:
##   QUEST 2 OF 5                              B quest book
##   The Blighted Cider-Boughs
##   (★) Clear the Grey-Bark Weevils from the four groves
##   ● ● ○ ○   2 of 4
##   (➚) The Apple Orchards · 120 m · to your right
## The arrow turns with the camera; inside the place it reads "You're here!".
##
## It watches the quest ledger (on every peer, so a client's tracker cheers too): a step
## finished shows "Done!" in green with a sparkle before the next one slides in, and a
## quest finished tells the HUD to put up the quest-complete card (quest_finished).
class_name QuestTracker
extends Control

signal quest_finished(quest_id: StringName)
signal step_finished(quest_id: StringName, step_text: String)

const SHEET: Vector2 = Vector2(1600.0, 900.0)
const WIDTH: float = 388.0
const RIGHT_MARGIN: float = 22.0
## The card's top, as a share of the view's height (under where a minimap would sit).
const TOP_SHARE: float = 0.24
const MIN_FIT: float = 0.5
## How long "Done!" stays up after a step is finished.
const CHEER_TIME: float = 3.2
## Steps with up to this many to do show a pip each; more show a bar.
const MAX_PIPS: int = 8

var actor: ActorBase
var hud: PlayerHUD
## The step "Done!" is showing for ("" when none).
var cheer_text: String = ""

var _card: PanelContainer
var _number: Label
var _book_key: Label
var _title: Label
var _cheer_row: HBoxContainer
var _cheer_label: Label
var _step_glyph: QuestGlyph
var _step_text: Label
var _progress_row: HBoxContainer
var _pips: Control
var _progress_text: Label
var _where_glyph: QuestGlyph
var _where_text: Label
var _cheer_left: float = 0.0
var _seen: Dictionary = {}
var _quest_id: StringName = &""


func setup(target_actor: ActorBase, on_hud: PlayerHUD) -> void:
	actor = target_actor
	hud = on_hud


func _ready() -> void:
	name = "QuestTracker"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = BinderKit.panel(_card_style())
	_card.name = "Card"
	_card.custom_minimum_size = Vector2(WIDTH, 0.0)
	add_child(_card)
	var stack: VBoxContainer = BinderKit.column(7)
	_card.add_child(stack)
	var top: HBoxContainer = BinderKit.line(8)
	stack.add_child(top)
	_number = BinderKit.kicker("")
	_number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_number)
	var key_chip: PanelContainer = BinderKit.panel(AtelierTheme.chip_style(AtelierTheme.LINE_DIM, AtelierTheme.ROW))
	_book_key = BinderKit.text("", AtelierTheme.SMALL_SIZE - 1, AtelierTheme.INK_MUTED)
	key_chip.add_child(_book_key)
	top.add_child(key_chip)
	_title = BinderKit.text("", BinderKit.NAME_SIZE - 1, AtelierTheme.GOLD, WIDTH - 36.0)
	stack.add_child(_title)
	_cheer_row = BinderKit.line(8)
	_cheer_row.add_child(QuestGlyph.new(QuestGlyph.Mark.DONE, AtelierTheme.GOOD, 26.0))
	_cheer_label = BinderKit.text("", AtelierTheme.BODY_SIZE, AtelierTheme.GOOD, WIDTH - 80.0)
	_cheer_row.add_child(_cheer_label)
	_cheer_row.visible = false
	stack.add_child(_cheer_row)
	var step_row: HBoxContainer = BinderKit.line(10)
	stack.add_child(step_row)
	_step_glyph = QuestGlyph.new(QuestGlyph.Mark.DO, AtelierTheme.GOLD, 36.0)
	_step_glyph.pulse = true
	step_row.add_child(_step_glyph)
	_step_text = BinderKit.text("", AtelierTheme.BODY_SIZE + 2, AtelierTheme.INK, WIDTH - 86.0)
	step_row.add_child(_step_text)
	_progress_row = BinderKit.line(10)
	stack.add_child(_progress_row)
	var indent: Control = Control.new()
	indent.custom_minimum_size = Vector2(36.0, 0.0)
	_progress_row.add_child(indent)
	_pips = Control.new()
	_pips.custom_minimum_size = Vector2(170.0, 20.0)
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.draw.connect(_draw_pips)
	_progress_row.add_child(_pips)
	_progress_text = BinderKit.text("", AtelierTheme.BODY_SIZE, AtelierTheme.GOLD)
	_progress_row.add_child(_progress_text)
	var where_row: HBoxContainer = BinderKit.line(10)
	stack.add_child(where_row)
	_where_glyph = QuestGlyph.new(QuestGlyph.Mark.ARROW, AtelierTheme.GOLD, 36.0)
	where_row.add_child(_where_glyph)
	_where_text = BinderKit.text("", AtelierTheme.BODY_SIZE, AtelierTheme.INK_MUTED, WIDTH - 86.0)
	where_row.add_child(_where_text)
	if QuestManager.current != null:
		QuestManager.current.ledger_changed.connect(_on_ledger_changed)
	_seen = _snapshot()
	_refresh_quest()


func _exit_tree() -> void:
	if QuestManager.current != null and QuestManager.current.ledger_changed.is_connected(_on_ledger_changed):
		QuestManager.current.ledger_changed.disconnect(_on_ledger_changed)


func _process(delta: float) -> void:
	_cheer_left = maxf(0.0, _cheer_left - delta)
	_cheer_row.visible = _cheer_left > 0.0
	_cheer_row.modulate.a = minf(1.0, _cheer_left / 0.6)
	if _cheer_left <= 0.0:
		cheer_text = ""
	var fit: float = clampf(minf(size.x / SHEET.x, size.y / SHEET.y), MIN_FIT, 1.0)
	_card.scale = Vector2.ONE * fit
	_card.reset_size()
	_card.position = Vector2(size.x - (WIDTH + RIGHT_MARGIN) * fit, size.y * TOP_SHARE)
	_refresh_where()


## Whether the tracker has a quest to show.
func has_quest() -> bool:
	return _quest_id != &""


## The tracker's words, top to bottom (for the checks): number, title, step, count, where.
func lines() -> PackedStringArray:
	if not has_quest():
		return PackedStringArray()
	return PackedStringArray([_number.text, _title.text, _step_text.text, _progress_text.text if _progress_row.visible else "", _where_text.text])


func where_text() -> String:
	return _where_text.text


func _refresh_quest() -> void:
	var quests: QuestManager = QuestManager.current
	var quest: QuestDefinition = quests.active_quest() if quests != null else null
	var step: QuestStepResource = quests.active_step() if quests != null else null
	_quest_id = quest.quest_id if quest != null else &""
	_card.visible = quest != null
	if quest == null:
		return
	_number.text = QuestKit.number_line(quest).to_upper()
	_title.text = quest.title
	_book_key.text = "%s quest book" % book_key(actor)
	_step_text.text = step.text if step != null else "Hand it in"
	_step_glyph.mark = QuestGlyph.for_kind(step.kind) if step != null else QuestGlyph.Mark.DO
	_step_glyph.queue_redraw()
	var counted: String = QuestKit.progress_line(quest.quest_id, step)
	_progress_row.visible = counted != ""
	_progress_text.text = counted
	_pips.queue_redraw()
	_refresh_where()


## Where the step is from here, and the arrow turned toward it.
func _refresh_where() -> void:
	if not has_quest() or QuestManager.current == null:
		return
	var spot: Dictionary = QuestKit.where(actor, QuestManager.current.active_step())
	var here: bool = bool(spot["here"])
	_where_glyph.mark = QuestGlyph.Mark.HERE if here else QuestGlyph.Mark.ARROW
	_where_glyph.visible = here or not is_nan(float(spot["turn"]))
	_where_glyph.turn = 0.0 if is_nan(float(spot["turn"])) else float(spot["turn"])
	var words: String = String(spot["words"])
	var place: String = String(spot["name"])
	if here:
		_where_text.text = "%s · You're here!" % place
	elif place != "" and words != "":
		_where_text.text = "%s · %s" % [place, words]
	else:
		_where_text.text = place
	_where_text.add_theme_color_override(&"font_color", AtelierTheme.GOOD if here else AtelierTheme.INK_MUTED)


## The ledger moved: cheer a finished step, tell the HUD about a finished quest, show the new step.
func _on_ledger_changed() -> void:
	var now: Dictionary = _snapshot()
	for quest_id: StringName in ActOneQuests.ORDER:
		var before: Array = _seen.get(quest_id, [QuestManager.QuestState.LOCKED, 0])
		var after: Array = now.get(quest_id, [QuestManager.QuestState.LOCKED, 0])
		if int(before[0]) != QuestManager.QuestState.ACTIVE:
			continue
		var quest: QuestDefinition = ActOneQuests.quest(quest_id)
		if int(after[0]) == QuestManager.QuestState.COMPLETE:
			_cheer(quest_id, quest.step_at(int(before[1])))
			quest_finished.emit(quest_id)
		elif int(after[0]) == QuestManager.QuestState.ACTIVE and int(after[1]) > int(before[1]):
			_cheer(quest_id, quest.step_at(int(before[1])))
	_seen = now
	_refresh_quest()


func _cheer(quest_id: StringName, step: QuestStepResource) -> void:
	if step == null:
		return
	cheer_text = step.text
	_cheer_label.text = "Done! %s" % step.text
	_cheer_left = CHEER_TIME
	step_finished.emit(quest_id, step.text)
	AudioCues.play(&"chime", 1.2)
	var sparkle: CardSparkle = CardSparkle.new(AtelierTheme.GOOD)
	sparkle.position = Vector2(30.0, 90.0)
	_card.add_child(sparkle)


func _snapshot() -> Dictionary:
	var shot: Dictionary = {}
	var quests: QuestManager = QuestManager.current
	if quests == null:
		return shot
	for quest_id: StringName in ActOneQuests.ORDER:
		shot[quest_id] = [int(quests.state_of(quest_id)), quests.step_of(quest_id)]
	return shot


## The quest book's key for this hero: "B" on the keyboard, "Share + ↓" on a pad.
static func book_key(for_actor: ActorBase) -> String:
	if for_actor == null or for_actor.input == null:
		return "B"
	if for_actor.input.is_keyboard():
		return for_actor.input.label(InputComponent.ACTION_QUEST_BOOK)
	return "%s + ↓" % for_actor.input.label(InputComponent.ACTION_CHANGE_CLASS)


func _card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = AtelierTheme.page_style(true)
	style.bg_color = Color(AtelierTheme.PAGE_RAISED, 0.9)
	style.set_content_margin_all(14.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 8
	return style


## A pip per thing to do (gold when done), or a bar for longer counts.
func _draw_pips() -> void:
	var quests: QuestManager = QuestManager.current
	var step: QuestStepResource = quests.active_step() if quests != null else null
	if step == null or step.count <= 1:
		return
	var done: int = quests.count_of(_quest_id)
	if step.count <= MAX_PIPS:
		for index: int in step.count:
			var at: Vector2 = Vector2(10.0 + float(index) * 20.0, 10.0)
			_pips.draw_circle(at, 7.5, AtelierTheme.GOLD if index < done else AtelierTheme.ROW)
			_pips.draw_arc(at, 7.5, 0.0, TAU, 20, AtelierTheme.GILT, 1.5, true)
		return
	var rect: Rect2 = Rect2(0.0, 4.0, 160.0, 12.0)
	_pips.draw_rect(rect, AtelierTheme.ROW)
	_pips.draw_rect(Rect2(rect.position, Vector2(rect.size.x * float(done) / float(step.count), rect.size.y)), AtelierTheme.GOLD)
	_pips.draw_rect(rect, AtelierTheme.GILT, false, 1.5)
