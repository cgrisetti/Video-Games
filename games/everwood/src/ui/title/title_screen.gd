## The title screen (docs/22_TITLE_SCREEN_AND_TALES.md), the game's main scene:
## the Everwood wordmark over a living storybook picture (TitleDiorama), and a
## menu of New Game, Continue and Quit.
##   New Game  asks for the hero's name (or suggests one), begins a fresh
##             Level 1 tale in a new save file (PartyProgress.begin_new_tale)
##             and walks into the Caldera Isles at the orchard lane.
##   Continue  lists every tale on this machine (SaveSlots), newest played
##             first, and plays the one chosen.
## Mouse, keyboard and pad all work (the ui_* actions); Escape or B goes back.
## A launch with game options after `--` (`--save=`, `--instance=`,
## `--players=`, `--screenshot=` ...) skips the title, so tools and tests run
## as before.
class_name TitleScreen
extends Node3D

## A tale has been chosen: its save file is in use and the game is about to start.
signal tale_begun(path: String)

const GAME_INSTANCE: StringName = InstanceManager.CALDERA_ISLES
## The title's music: the orchard hamlet's acoustic suite.
const MUSIC_PROFILE: StringName = &"honey_wick"
const MUSIC_DB: float = -6.0
const MENU_ITEMS: Array[String] = ["New Game", "Continue", "Quit"]
const NAME_PROMPT: String = "What is your hero called?"
const PARCHMENT: Color = Color("#EFE6D2")
const PARCHMENT_LIGHT: Color = Color("#FBF6E8")
const PARCHMENT_TEXT: Color = Color("#F7EFDA")
const INK: Color = Color("#3A2818")
const INK_SOFT: Color = Color("#6B5440")
const SAFFRON_GOLD: Color = Color("#E8B64A")
## The menu's leading diamond (as in the Options menu).
const FOCUS_MARK: String = "◆  "
const IDLE_MARK: String = "    "
## Tests set this false: a chosen tale then stays on the title instead of loading the Caldera.
static var start_game_on_begin: bool = true

var diorama: TitleDiorama
var wordmark: EverwoodWordmark
var menu: VBoxContainer
var new_game_panel: PanelContainer
var continue_panel: PanelContainer
var name_field: LineEdit
var name_note: Label
var tale_list: VBoxContainer
var hint: Label
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _music: AudioStreamPlayer
var _starting: bool = false
var _menu_font: SystemFont
var _body_font: SystemFont


## Whether this launch shows the title (false when the command line asks for the game straight away).
static func wants_title(user_args: PackedStringArray) -> bool:
	for arg: String in user_args:
		if arg.begins_with("--"):
			return false
	return true


func _ready() -> void:
	if not wants_title(OS.get_cmdline_user_args()):
		_skip_to_game.call_deferred()
		return
	_rng.randomize()
	_menu_font = EverwoodWordmark.serif(600)
	_body_font = EverwoodWordmark.serif(500)
	diorama = TitleDiorama.new()
	diorama.name = "Diorama"
	add_child(diorama)
	_build_ui()
	_play_music()
	refresh()
	_focus_menu()


func _skip_to_game() -> void:
	get_tree().change_scene_to_file(InstanceManager.scene_path(GAME_INSTANCE))


# --- Building ---------------------------------------------------------------------------------

func _build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "TitleUI"
	add_child(layer)
	var root: Control = Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	# A soft shade down the left, so the wordmark and menu sit on the picture.
	var shade: TextureRect = TextureRect.new()
	shade.name = "Shade"
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.1, 0.07, 0.05, 0.62))
	gradient.set_color(1, Color(0.1, 0.07, 0.05, 0.0))
	gradient.add_point(0.55, Color(0.1, 0.07, 0.05, 0.3))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	shade.texture = texture
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.anchor_right = 0.62
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	wordmark = EverwoodWordmark.new()
	wordmark.name = "Wordmark"
	wordmark.anchor_left = 0.065
	wordmark.anchor_right = 0.6
	wordmark.anchor_top = 0.08
	wordmark.anchor_bottom = 0.44
	root.add_child(wordmark)
	menu = VBoxContainer.new()
	menu.name = "Menu"
	menu.anchor_left = 0.075
	menu.anchor_top = 0.5
	menu.anchor_right = 0.4
	menu.anchor_bottom = 0.86
	menu.add_theme_constant_override("separation", 6)
	root.add_child(menu)
	for label: String in MENU_ITEMS:
		var item: Button = _menu_button(label)
		menu.add_child(item)
	(menu.get_child(0) as Button).pressed.connect(open_new_game)
	(menu.get_child(1) as Button).pressed.connect(open_continue)
	(menu.get_child(2) as Button).pressed.connect(_quit)
	new_game_panel = _build_new_game(root)
	continue_panel = _build_continue(root)
	hint = Label.new()
	hint.name = "Hint"
	hint.anchor_left = 0.075
	hint.anchor_top = 0.93
	hint.anchor_right = 0.9
	hint.anchor_bottom = 0.98
	hint.add_theme_font_override(&"font", _body_font)
	hint.add_theme_font_size_override(&"font_size", 16)
	hint.add_theme_color_override(&"font_color", Color(PARCHMENT_TEXT, 0.8))
	hint.add_theme_color_override(&"font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	hint.add_theme_constant_override(&"shadow_offset_y", 1)
	root.add_child(hint)


func _menu_button(label: String) -> Button:
	var item: Button = Button.new()
	item.name = label.replace(" ", "")
	item.text = IDLE_MARK + label
	item.set_meta(&"label", label)
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.focus_mode = Control.FOCUS_ALL
	item.flat = true
	item.add_theme_font_override(&"font", _menu_font)
	item.add_theme_font_size_override(&"font_size", 38)
	item.add_theme_color_override(&"font_color", PARCHMENT_TEXT)
	item.add_theme_color_override(&"font_hover_color", SAFFRON_GOLD)
	item.add_theme_color_override(&"font_focus_color", SAFFRON_GOLD)
	item.add_theme_color_override(&"font_pressed_color", SAFFRON_GOLD)
	item.add_theme_color_override(&"font_hover_pressed_color", SAFFRON_GOLD)
	item.add_theme_color_override(&"font_disabled_color", Color(PARCHMENT_TEXT, 0.35))
	item.add_theme_color_override(&"font_outline_color", Color(INK, 0.85))
	item.add_theme_constant_override(&"outline_size", 6)
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled", &"hover_pressed"]:
		item.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	item.focus_entered.connect(_on_item_focus.bind(item, true))
	item.focus_exited.connect(_on_item_focus.bind(item, false))
	item.mouse_entered.connect(_on_item_hover.bind(item))
	return item


func _on_item_hover(item: Button) -> void:
	if not item.disabled:
		item.grab_focus()


func _on_item_focus(item: Button, focused: bool) -> void:
	item.text = (FOCUS_MARK if focused else IDLE_MARK) + str(item.get_meta(&"label", item.text.strip_edges()))
	if focused:
		AudioCues.play(&"menu_move")


## A parchment card, like a page of the storybook, holding `content`.
func _card(root: Control, card_name: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = card_name
	card.anchor_left = 0.07
	card.anchor_right = 0.47
	card.anchor_top = 0.47
	card.anchor_bottom = 0.9
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0.0, 6.0)
	style.set_content_margin_all(26.0)
	card.add_theme_stylebox_override(&"panel", style)
	card.visible = false
	root.add_child(card)
	return card


func _heading(text: String, font_size: int = 34) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override(&"font", _menu_font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", INK)
	return label


func _body(text: String, font_size: int = 20) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override(&"font", _body_font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", INK_SOFT)
	return label


## An ink button on the parchment, ringed in gold when it has focus.
func _card_button(text: String) -> Button:
	var button: Button = Button.new()
	button.name = text.replace(" ", "").replace("'", "") if text != "" else "CardButton"
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override(&"font", _menu_font)
	button.add_theme_font_size_override(&"font_size", 22)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		button.add_theme_color_override(state, PARCHMENT_TEXT)
	button.add_theme_color_override(&"font_disabled_color", Color(PARCHMENT_TEXT, 0.4))
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = INK
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(12.0)
	normal.content_margin_left = 20.0
	normal.content_margin_right = 20.0
	var focus: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	focus.border_color = SAFFRON_GOLD
	focus.set_border_width_all(3)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = INK.lightened(0.15)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	button.add_theme_stylebox_override(&"focus", focus)
	button.add_theme_stylebox_override(&"disabled", normal)
	button.focus_entered.connect(func() -> void: AudioCues.play(&"menu_move"))
	return button


func _build_new_game(root: Control) -> PanelContainer:
	var card: PanelContainer = _card(root, "NewGameCard")
	card.anchor_bottom = 0.8
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	column.add_child(_heading("A New Tale"))
	column.add_child(_body("A youth of Oakshire Holm wakes among the orchards. %s" % NAME_PROMPT))
	name_field = LineEdit.new()
	name_field.name = "HeroName"
	name_field.max_length = SaveSlots.MAX_NAME_LENGTH
	name_field.placeholder_text = "Type a name"
	name_field.add_theme_font_override(&"font", _menu_font)
	name_field.add_theme_font_size_override(&"font_size", 30)
	name_field.add_theme_color_override(&"font_color", INK)
	name_field.add_theme_color_override(&"font_placeholder_color", Color(INK_SOFT, 0.55))
	name_field.add_theme_color_override(&"caret_color", INK)
	var field: StyleBoxFlat = StyleBoxFlat.new()
	field.bg_color = PARCHMENT_LIGHT
	field.border_color = INK_SOFT
	field.set_border_width_all(2)
	field.set_corner_radius_all(6)
	field.set_content_margin_all(10.0)
	var field_focus: StyleBoxFlat = field.duplicate() as StyleBoxFlat
	field_focus.border_color = SAFFRON_GOLD.darkened(0.15)
	field_focus.set_border_width_all(3)
	name_field.add_theme_stylebox_override(&"normal", field)
	name_field.add_theme_stylebox_override(&"focus", field_focus)
	name_field.text_submitted.connect(func(_text: String) -> void: begin_new_tale())
	name_field.text_changed.connect(func(_text: String) -> void: name_note.text = "")
	column.add_child(name_field)
	name_note = _body("", 17)
	name_note.name = "NameNote"
	column.add_child(name_note)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var suggest: Button = _card_button("Suggest a Name")
	suggest.pressed.connect(suggest_name)
	var begin: Button = _card_button("Begin the Tale")
	begin.pressed.connect(begin_new_tale)
	var back: Button = _card_button("Back")
	back.pressed.connect(close_panels)
	row.add_child(begin)
	row.add_child(suggest)
	row.add_child(back)
	return card


func _build_continue(root: Control) -> PanelContainer:
	var card: PanelContainer = _card(root, "ContinueCard")
	card.anchor_bottom = 0.92
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	column.add_child(_heading("Choose a Tale"))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	tale_list = VBoxContainer.new()
	tale_list.name = "Tales"
	tale_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tale_list.add_theme_constant_override("separation", 8)
	scroll.add_child(tale_list)
	var back: Button = _card_button("Back")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(close_panels)
	column.add_child(back)
	return card


## One tale in the Continue list: the hero's name, then its level, Chimes and when it was last played.
func _tale_button(tale: Dictionary) -> Button:
	var button: Button = _card_button("")
	button.name = "Tale"
	button.custom_minimum_size = Vector2(0.0, 74.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta(&"path", tale["path"])
	var lines: VBoxContainer = VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lines.offset_left = 20.0
	lines.offset_top = 8.0
	lines.add_theme_constant_override("separation", 0)
	button.add_child(lines)
	var title: Label = Label.new()
	title.text = str(tale["name"])
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_override(&"font", _menu_font)
	title.add_theme_font_size_override(&"font_size", 26)
	title.add_theme_color_override(&"font_color", PARCHMENT_TEXT)
	lines.add_child(title)
	var detail: Label = Label.new()
	detail.text = tale_detail(tale)
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_theme_font_override(&"font", _body_font)
	detail.add_theme_font_size_override(&"font_size", 17)
	detail.add_theme_color_override(&"font_color", Color(SAFFRON_GOLD, 0.95))
	lines.add_child(detail)
	button.pressed.connect(continue_tale.bind(str(tale["path"])))
	return button


## "Level 3 · 120 Chimes · played 2 hours ago" (and "the family's older save" for that one).
static func tale_detail(tale: Dictionary) -> String:
	var parts: PackedStringArray = ["Level %d" % int(tale["level"]), "%d Chimes" % int(tale["chimes"]), "played %s" % SaveSlots.when_text(int(tale["last_played"]))]
	if bool(tale.get("family", false)):
		parts.append("the family's older save")
	return " · ".join(parts)


# --- Doing --------------------------------------------------------------------------------------

## Re-reads the tales: Continue is only offered when there's one to continue.
func refresh() -> void:
	var tales: Array[Dictionary] = SaveSlots.list()
	(menu.get_child(1) as Button).disabled = tales.is_empty()
	for child: Node in tale_list.get_children():
		tale_list.remove_child(child)
		child.queue_free()
	for tale: Dictionary in tales:
		tale_list.add_child(_tale_button(tale))
	_show_hint()


func open_new_game() -> void:
	menu.visible = false
	continue_panel.visible = false
	new_game_panel.visible = true
	name_field.text = ""
	name_note.text = ""
	name_field.grab_focus()
	_show_hint()


func open_continue() -> void:
	refresh()
	if tale_list.get_child_count() == 0:
		return
	menu.visible = false
	new_game_panel.visible = false
	continue_panel.visible = true
	(tale_list.get_child(0) as Button).grab_focus()
	_show_hint()


func close_panels() -> void:
	new_game_panel.visible = false
	continue_panel.visible = false
	menu.visible = true
	_focus_menu()
	_show_hint()


func suggest_name() -> void:
	name_field.text = SaveSlots.suggest_name(_rng, name_field.text)
	name_field.caret_column = name_field.text.length()
	name_note.text = ""


## New Game: a fresh Level 1 tale in its own save file, named for the hero.
func begin_new_tale() -> void:
	if _starting:
		return
	var hero: String = SaveSlots.clean_name(name_field.text)
	if hero == "":
		name_note.text = "Your hero needs a name: type one, or pick Suggest a Name."
		name_field.grab_focus()
		return
	SaveSlots.ensure_folder()
	var path: String = SaveSlots.new_slot_path(hero)
	if PartyProgress.current.begin_new_tale(path, hero) != OK:
		name_note.text = "That tale couldn't be written down. Try again?"
		return
	_begin(path)


## Continue: plays the chosen tale's save file.
func continue_tale(path: String) -> void:
	if _starting:
		return
	PartyProgress.current.end_playtest()
	PartyProgress.current.endgame_kits_for_testing = false
	PartyProgress.current.use_save_file(path)
	_begin(path)


func _begin(path: String) -> void:
	_starting = true
	AudioCues.play(&"chime")
	tale_begun.emit(path)
	if not start_game_on_begin:
		_starting = false
		return
	if _music != null:
		create_tween().tween_property(_music, "volume_db", -40.0, InstanceManager.FADE_TIME)
	InstanceManager.current.change_instance(GAME_INSTANCE)


func _quit() -> void:
	get_tree().quit()


func _focus_menu() -> void:
	if menu != null and menu.visible:
		(menu.get_child(0) as Button).grab_focus()


func _show_hint() -> void:
	if hint == null:
		return
	if new_game_panel.visible:
		hint.text = "Type your hero's name · Enter begins · Escape or B goes back"
	elif continue_panel.visible:
		hint.text = "↑/↓ choose a tale · Enter or A plays it · Escape or B goes back"
	else:
		hint.text = "↑/↓ choose · Enter or A selects"


func _unhandled_input(event: InputEvent) -> void:
	if new_game_panel == null:
		return
	if event.is_action_pressed(&"ui_cancel") and (new_game_panel.visible or continue_panel.visible):
		close_panels()
		get_viewport().set_input_as_handled()


func _play_music() -> void:
	var path: String = AudioDirector.sync_path(MUSIC_PROFILE)
	if not ResourceLoader.exists(path):
		return
	_music = AudioStreamPlayer.new()
	_music.name = "TitleMusic"
	_music.stream = load(path) as AudioStream
	_music.bus = &"Music" if AudioServer.get_bus_index(&"Music") >= 0 else &"Master"
	_music.volume_db = MUSIC_DB
	add_child(_music)
	_music.play()
