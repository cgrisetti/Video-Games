## The talk box: a conversation with one of the townsfolk, along the bottom of the hero's
## view in the living storybook atelier look, with the world still showing above it.
## Their portrait sits in a gilt medallion on the box's corner with their name on a plate,
## and what they say writes itself out and stays up until the player moves on: nothing
## fades away on a timer.
##
## Beside the words, a short list of choices (up / down to choose, light to pick, a click
## works too):
##   Tell me more     their next line (on the last one: "Say that again", which starts over
##                    with whatever they have to say now)
##   What do I do?    the step under way in one plain sentence, where it is, and the firefly
##                    trail set toward it
##   Goodbye          ends the talk (dodge does too)
## Light while the words are still writing finishes them at once. Hearing a townsperson's
## last line counts as speaking to them for the quest (EverwoodNPC.heard_all).
class_name TalkBox
extends Control

signal closed

enum Choice { MORE, AGAIN, WHAT, BYE }

const SHEET: Vector2 = Vector2(1600.0, 900.0)
const BOX: Rect2 = Rect2(170.0, 610.0, 1260.0, 250.0)
const PORTRAIT_AT: Vector2 = Vector2(262.0, 642.0)
const PORTRAIT_RADIUS: float = 96.0
const WORDS_AT: Vector2 = Vector2(392.0, 648.0)
const WORDS_WIDTH: float = 640.0
const WORDS_SIZE: int = 25
const CHOICES_AT: Vector2 = Vector2(1066.0, 640.0)
const CHOICES_WIDTH: float = 336.0
## Letters per second as the words write themselves out.
const LETTERS_PER_SECOND: float = 55.0
## The talk ends by itself if the hero ends up this far away (a shove, a fall).
const LEAVE_DISTANCE: float = 6.0
const MIN_FIT: float = 0.42
const FORGED_INK: Color = Color(0.78, 0.78, 0.76)
const CHOICE_WORDS: Array[String] = ["Tell me more", "Say that again", "What do I do?", "Goodbye"]

var actor: ActorBase
var npc: EverwoodNPC
var hud: PlayerHUD
## The lines this talk is reading (taken when it opens, or when it starts over).
var lines: PackedStringArray = PackedStringArray()
## The line on show (-1 while the "What do I do?" answer is up).
var line_index: int = 0
## Every line has been heard at least once in this talk.
var heard_everything: bool = false
var cursor: int = 0

var _choices: Array[Choice] = []
var _sheet: Control
var _portrait: Control
var _name: Label
var _title: Label
var _quest_chip: PanelContainer
var _quest_chip_text: Label
var _words: Label
var _dots: Control
var _choice_list: VBoxContainer
var _hint: Label
var _speaker: String = ""
var _speaker_npc: EverwoodNPC
var _shown: float = 0.0
var _age: float = 0.0
var _resume_at: int = 0


func setup(target_actor: ActorBase, talk_to: EverwoodNPC, on_hud: PlayerHUD) -> void:
	actor = target_actor
	npc = talk_to
	hud = on_hud


func _ready() -> void:
	name = "TalkBox"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet = Control.new()
	_sheet.name = "Sheet"
	_sheet.size = SHEET
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet)
	var shade: Control = Control.new()
	shade.name = "Shade"
	shade.size = SHEET
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(_draw_shade.bind(shade))
	_sheet.add_child(shade)
	var box: PanelContainer = BinderKit.panel(_box_style())
	box.name = "Box"
	BinderKit.place(_sheet, box, BOX.position, BOX.size.x, BOX.size.y)
	_portrait = Control.new()
	_portrait.name = "Portrait"
	_portrait.position = PORTRAIT_AT - Vector2.ONE * (PORTRAIT_RADIUS + 8.0)
	_portrait.size = Vector2.ONE * (PORTRAIT_RADIUS + 8.0) * 2.0
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.draw.connect(_draw_portrait)
	_sheet.add_child(_portrait)
	var plate: PanelContainer = BinderKit.panel(_plate_style())
	plate.name = "NamePlate"
	var plate_line: HBoxContainer = BinderKit.line(12)
	plate.add_child(plate_line)
	_name = BinderKit.text("", BinderKit.NAME_SIZE + 2, AtelierTheme.GOLD)
	plate_line.add_child(_name)
	_title = BinderKit.text("", AtelierTheme.BODY_SIZE, AtelierTheme.INK_MUTED)
	plate_line.add_child(_title)
	plate.position = Vector2(372.0, 584.0)
	_sheet.add_child(plate)
	_quest_chip = BinderKit.panel(AtelierTheme.chip_style(AtelierTheme.GOOD, AtelierTheme.PAGE_RAISED))
	_quest_chip.name = "QuestChip"
	var chip_line: HBoxContainer = BinderKit.line(6)
	_quest_chip.add_child(chip_line)
	chip_line.add_child(QuestGlyph.new(QuestGlyph.Mark.NOW, AtelierTheme.GOLD, 22.0))
	_quest_chip_text = BinderKit.text("", AtelierTheme.SMALL_SIZE + 2, AtelierTheme.GOOD)
	chip_line.add_child(_quest_chip_text)
	_sheet.add_child(_quest_chip)
	_words = BinderKit.text("", WORDS_SIZE, AtelierTheme.INK, WORDS_WIDTH)
	_words.name = "Words"
	_words.position = WORDS_AT
	_words.size = Vector2(WORDS_WIDTH, 150.0)
	_words.add_theme_constant_override(&"line_spacing", 6)
	_sheet.add_child(_words)
	_dots = Control.new()
	_dots.name = "PageDots"
	_dots.position = Vector2(WORDS_AT.x, 818.0)
	_dots.size = Vector2(WORDS_WIDTH, 24.0)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.draw.connect(_draw_dots)
	_sheet.add_child(_dots)
	_choice_list = BinderKit.column(10)
	_choice_list.name = "Choices"
	_choice_list.position = CHOICES_AT
	_choice_list.custom_minimum_size = Vector2(CHOICES_WIDTH, 0.0)
	_sheet.add_child(_choice_list)
	_hint = BinderKit.text("", AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK_MUTED)
	_hint.position = Vector2(BOX.position.x + 20.0, BOX.end.y + 8.0)
	_sheet.add_child(_hint)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(_on_menu_input)
	_start_over()


func _exit_tree() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
		if actor.input.menu_input.is_connected(_on_menu_input):
			actor.input.menu_input.disconnect(_on_menu_input)


func _process(delta: float) -> void:
	_age += delta
	var fit: float = clampf(minf(size.x / SHEET.x, size.y / SHEET.y), MIN_FIT, 1.0)
	_sheet.scale = Vector2.ONE * fit
	_sheet.position = Vector2((size.x - SHEET.x * fit) * 0.5, size.y - SHEET.y * fit)
	if is_typing():
		_shown = minf(float(_words.get_total_character_count()), _shown + LETTERS_PER_SECOND * delta)
		_words.visible_characters = int(_shown)
	_portrait.queue_redraw()
	_dots.queue_redraw()
	if _should_end():
		close()


## The talk ends on its own when the townsperson is gone, the hero is pulled away or a fight starts.
func _should_end() -> bool:
	if not is_instance_valid(npc) or not is_instance_valid(actor) or not npc.is_inside_tree() or not actor.is_inside_tree():
		return true
	if actor.sign_flow != null and actor.sign_flow.is_in_combat:
		return true
	return actor.global_position.distance_to(npc.global_position) > LEAVE_DISTANCE


# --- Reading (also for the checks) ----------------------------------------------------------------

func is_typing() -> bool:
	return _words.visible_characters >= 0 and _shown < float(_words.get_total_character_count())


func finish_typing() -> void:
	_shown = float(_words.get_total_character_count())
	_words.visible_characters = -1


## The words on show (all of them, written out or not).
func page_words() -> String:
	return _words.text


func speaker() -> String:
	return _speaker


## The choices on offer, in order, as shown.
func choices() -> PackedStringArray:
	var words: PackedStringArray = PackedStringArray()
	for choice: Choice in _choices:
		words.append(CHOICE_WORDS[choice])
	return words


func is_last_line() -> bool:
	return line_index >= lines.size() - 1


# --- Doing ----------------------------------------------------------------------------------------

## Light: finish the words if they're still writing, otherwise pick the chosen choice.
func accept() -> void:
	if is_typing():
		finish_typing()
		return
	if cursor >= 0 and cursor < _choices.size():
		choose(_choices[cursor])


func choose(choice: Choice) -> void:
	match choice:
		Choice.MORE:
			next_line()
		Choice.AGAIN:
			_start_over()
		Choice.WHAT:
			_answer_what_to_do()
		Choice.BYE:
			close()


## Their next line (from the "What do I do?" answer, back to where the talk had got to).
func next_line() -> void:
	if line_index < 0:
		_show_line(_resume_at)
	elif line_index < lines.size() - 1:
		_show_line(line_index + 1)
	else:
		_start_over()


func move_cursor(step: int) -> void:
	if _choices.is_empty():
		return
	cursor = wrapi(cursor + step, 0, _choices.size())
	AudioCues.play(&"menu_move")
	_build_choices()


func close() -> void:
	if is_queued_for_deletion():
		return
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


func _on_menu_input(action: StringName) -> void:
	match action:
		InputComponent.MENU_UP:
			move_cursor(-1)
		InputComponent.MENU_DOWN:
			move_cursor(1)
		InputComponent.MENU_ACCEPT:
			accept()
		InputComponent.MENU_BACK:
			close()


func _start_over() -> void:
	lines = npc.current_lines() if is_instance_valid(npc) else PackedStringArray()
	if lines.is_empty():
		lines = PackedStringArray(["Good day to you."])
	heard_everything = false
	_show_line(0)


func _show_line(index: int) -> void:
	line_index = clampi(index, 0, lines.size() - 1)
	_resume_at = line_index
	var parsed: PackedStringArray = EverwoodNPC.parse_line(lines[line_index], npc.npc_name)
	_set_page(parsed[0], parsed[1])
	if is_last_line() and not heard_everything:
		heard_everything = true
		npc.heard_all(actor)
	_choices = [Choice.AGAIN if is_last_line() else Choice.MORE, Choice.WHAT, Choice.BYE]
	cursor = 0
	_build_choices()
	AudioCues.play(&"menu_move", 0.9)


func _answer_what_to_do() -> void:
	line_index = -1
	_set_page(npc.npc_name, QuestKit.what_to_do(actor))
	if QuestKit.show_the_way(hud):
		AudioCues.play(&"chime")
	_choices = [Choice.MORE, Choice.BYE]
	cursor = 0
	_build_choices()


## Puts a page up: who's speaking (their plate and portrait) and their words, writing out from the start.
func _set_page(who: String, words: String) -> void:
	_speaker = who
	_speaker_npc = npc.talk_partner(who) if is_instance_valid(npc) else null
	var shown: EverwoodNPC = _speaker_npc if _speaker_npc != null else npc
	var forged: bool = shown != null and shown.is_forged()
	# A partner's short name ("Tenar-Moss") reads as their whole name and title on the plate.
	var full: String = shown.npc_name if shown != null and (shown == npc or _speaker_npc != null) and shown.npc_name.contains(who) else who
	_name.text = full
	_name.add_theme_color_override(&"font_color", FORGED_INK if forged else AtelierTheme.GOLD)
	_title.text = shown.title if shown != null and shown.npc_name == full else ""
	_words.text = words
	_words.add_theme_color_override(&"font_color", FORGED_INK if forged else AtelierTheme.INK)
	_shown = 0.0
	_words.visible_characters = 0
	_refresh_quest_chip()
	_hint.text = "%s / %s choose  ·  %s pick  ·  %s goodbye" % [_label(InputComponent.ACTION_MOVE_FORWARD), _label(InputComponent.ACTION_MOVE_BACK),
		_label(InputComponent.ACTION_LIGHT), _label(InputComponent.ACTION_DODGE)]


## A green chip over the box when this townsperson is part of the quest under way.
func _refresh_quest_chip() -> void:
	var quests: QuestManager = QuestManager.current
	var quest: QuestDefinition = quests.active_quest() if quests != null else null
	var wanted: bool = false
	if quest != null and is_instance_valid(npc):
		var step: QuestStepResource = quests.active_step()
		wanted = (step != null and step.target == npc.npc_id) or QuestKit.giver(quest) == npc.npc_name
	_quest_chip.visible = wanted
	if wanted:
		_quest_chip_text.text = "Part of your quest: %s" % quest.title
		_quest_chip.reset_size()
		_quest_chip.position = Vector2(BOX.end.x - _quest_chip.get_combined_minimum_size().x - 18.0, 586.0)


func _build_choices() -> void:
	BinderKit.clear(_choice_list)
	for index: int in _choices.size():
		var choice: Choice = _choices[index]
		var chosen: bool = index == cursor
		var row: PanelContainer = BinderKit.row_box(chosen, false, 10.0)
		var line: HBoxContainer = BinderKit.line(10)
		row.add_child(line)
		line.add_child(key_chip(_label(InputComponent.ACTION_LIGHT) if chosen else "", chosen))
		line.add_child(QuestGlyph.new(_glyph_for(choice), AtelierTheme.GOLD if chosen else AtelierTheme.GILT, 28.0))
		line.add_child(BinderKit.text(CHOICE_WORDS[choice], AtelierTheme.HEADING_SIZE + 1, AtelierTheme.INK if chosen else AtelierTheme.INK_MUTED))
		var which: Choice = choice
		var at: int = index
		BinderKit.on_click(row, func() -> void:
			cursor = at
			choose(which))
		_choice_list.add_child(row)


## The button to press, in a small gilt box (empty and dim on the rows not chosen).
static func key_chip(key: String, lit: bool) -> PanelContainer:
	var style: StyleBoxFlat = AtelierTheme.chip_style(AtelierTheme.GOLD if lit else AtelierTheme.LINE, AtelierTheme.PAGE if lit else AtelierTheme.ROW)
	style.set_corner_radius_all(6)
	var box: PanelContainer = BinderKit.panel(style)
	box.custom_minimum_size = Vector2(38.0, 34.0)
	var word: Label = BinderKit.text(key, AtelierTheme.BODY_SIZE + 1, AtelierTheme.GOLD)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(word)
	return box


static func _glyph_for(choice: Choice) -> QuestGlyph.Mark:
	match choice:
		Choice.WHAT:
			return QuestGlyph.Mark.GO
		Choice.BYE:
			return QuestGlyph.Mark.DONE
	return QuestGlyph.Mark.TALK


func _label(action: StringName) -> String:
	return actor.input.label(action) if is_instance_valid(actor) and actor.input != null else "?"


# --- Drawing --------------------------------------------------------------------------------------

func _box_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = AtelierTheme.page_style(true)
	style.bg_color = AtelierTheme.PAGE_RAISED
	style.set_border_width_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 14
	return style


static func _plate_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = AtelierTheme.chip_style(AtelierTheme.GILT, AtelierTheme.PAGE)
	style.set_border_width_all(2)
	style.set_corner_radius_all(AtelierTheme.RADIUS)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


## A soft dusk along the bottom of the view so the box reads over bright grass.
func _draw_shade(on: Control) -> void:
	var clear_ink: Color = Color(0.05, 0.035, 0.02, 0.0)
	var dusk: Color = Color(0.05, 0.035, 0.02, 0.55)
	on.draw_polygon(PackedVector2Array([Vector2(0.0, 520.0), Vector2(SHEET.x, 520.0), Vector2(SHEET.x, SHEET.y), Vector2(0.0, SHEET.y)]),
		PackedColorArray([clear_ink, clear_ink, dusk, dusk]))


## The speaker's portrait: a bust in their own colours (greyed while Forged) in a gilt medallion.
func _draw_portrait() -> void:
	var shown: EverwoodNPC = _speaker_npc if _speaker_npc != null else npc
	var middle: Vector2 = _portrait.size * 0.5
	var r: float = PORTRAIT_RADIUS
	_portrait.draw_circle(middle, r + 6.0, AtelierTheme.GILT)
	_portrait.draw_circle(middle, r, Color("#3B2B1C"))
	_portrait.draw_circle(middle + Vector2(0.0, -r * 0.18), r * 0.78, Color("#4A3826"))
	if shown == null or not is_instance_valid(shown):
		return
	var forged: bool = shown.is_forged()
	var body: Color = shown.body_color
	var accent: Color = shown.accent_color
	var skin: Color = TownsfolkNPC.SKIN if not forged else EverwoodNPC._greyed(TownsfolkNPC.SKIN)
	var talking: float = 0.0 if not is_typing() else absf(sin(_age * 14.0))
	# Shoulders and a collar.
	var shoulders: PackedVector2Array = PackedVector2Array()
	for index: int in 25:
		var angle: float = PI + float(index) / 24.0 * PI
		shoulders.append(middle + Vector2(cos(angle) * r * 0.78, r * 0.95 + sin(angle) * r * 0.5))
	_portrait.draw_colored_polygon(shoulders, body)
	_portrait.draw_colored_polygon(PackedVector2Array([middle + Vector2(-r * 0.28, r * 0.42), middle + Vector2(0.0, r * 0.72), middle + Vector2(r * 0.28, r * 0.42)]), accent)
	# Head, hair, a hood or cap in the accent.
	var head: Vector2 = middle + Vector2(0.0, -r * 0.05)
	_portrait.draw_circle(head + Vector2(0.0, r * 0.38), r * 0.16, skin.darkened(0.08))
	_portrait.draw_circle(head, r * 0.4, skin)
	_portrait.draw_arc(head, r * 0.42, PI * 1.05, PI * 1.95, 24, accent.darkened(0.15), r * 0.16, true)
	# Rosy cheeks, eyes that blink, a smile that moves while they talk.
	_portrait.draw_circle(head + Vector2(-r * 0.2, r * 0.1), r * 0.07, Color(0.92, 0.55, 0.5, 0.45 if not forged else 0.0))
	_portrait.draw_circle(head + Vector2(r * 0.2, r * 0.1), r * 0.07, Color(0.92, 0.55, 0.5, 0.45 if not forged else 0.0))
	var blink: bool = fmod(_age + float(shown.npc_seed) * 0.37, 3.6) < 0.12
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = head + Vector2(side * r * 0.15, -r * 0.04)
		if blink:
			_portrait.draw_line(eye + Vector2(-r * 0.05, 0.0), eye + Vector2(r * 0.05, 0.0), QuestGlyph.INK_LINE, 2.0, true)
		else:
			_portrait.draw_circle(eye, r * 0.05, QuestGlyph.INK_LINE)
	var mouth: Vector2 = head + Vector2(0.0, r * 0.2)
	if forged:
		_portrait.draw_line(mouth + Vector2(-r * 0.1, 0.0), mouth + Vector2(r * 0.1, 0.0), QuestGlyph.INK_LINE, 2.0, true)
	else:
		_portrait.draw_arc(mouth + Vector2(0.0, -r * 0.05), r * (0.1 + 0.03 * talking), 0.2, PI - 0.2, 12, Color("#8A3A30"), 2.5 + 3.0 * talking, true)
	if forged:
		_portrait.draw_circle(middle, r, Color(0.7, 0.7, 0.68, 0.25))
	_portrait.draw_arc(middle, r + 6.0, 0.0, TAU, 64, AtelierTheme.GOLD, 2.0, true)


## A dot per line (the one on show in gold), and a bobbing "more" mark once the words are out.
func _draw_dots() -> void:
	var count: int = lines.size()
	for index: int in count:
		var at: Vector2 = Vector2(10.0 + float(index) * 22.0, 12.0)
		var on_it: bool = index == line_index
		var heard: bool = index <= line_index or heard_everything
		_dots.draw_circle(at, 7.0 if on_it else 5.0, AtelierTheme.GOLD if on_it else (AtelierTheme.GILT if heard else AtelierTheme.LINE))
	if not is_typing():
		var bob: float = sin(_age * 5.0) * 3.0
		var tip: Vector2 = Vector2(WORDS_WIDTH - 12.0, 16.0 + bob)
		_dots.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-9.0, -11.0), tip + Vector2(9.0, -11.0)]), AtelierTheme.GOLD)
