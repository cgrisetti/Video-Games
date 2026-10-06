extends CanvasLayer

# The menu: a start screen when the game opens, and the pause menu during play, with pages for
# Settings and How to play. It works the way console game menus do:
#   - Esc or P (keyboard), Options (controller) opens and closes it.
#   - Up and down choose a row, left and right change a setting, Enter or ✕ picks, Esc or ○ goes back.
#   - The mouse works too: point at a row to choose it, click to pick it.
#   - The game pauses by itself if you switch to another window or your controller comes unplugged.
# While it's open the world stands still, and the music goes quiet and muffled.

signal play_pressed
signal quit_pressed

const VOLUME_STEP := 0.05
const CHOICES := {
	"music_on": [[true, "On"], [false, "Off"]],
	"music_style": [["forest", "Forest"], ["8bit", "8-bit"]],
	"invert_x": [[false, "Off"], [true, "On"]],
	"invert_y": [[false, "Off"], [true, "On"]],
	"graphics": [["low", "Low"], ["medium", "Medium"], ["high", "High"]],
	"fullscreen": [[false, "Off"], [true, "On"]],
}

var is_open := false
var _starting := true
var _page := "main"
var _pages := {}
var _title: Label
var _notice: Label
var _hints: HBoxContainer
var _resume: Button
var _rows_for_setting := {} # Setting name -> the control that shows it.
var _came_from := {} # Page -> the button that led to it, to land on when coming back.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build()
	InputHints.device_changed.connect(func(_c: bool) -> void: _show_hints())
	Settings.changed.connect(func(_n: String) -> void: _show_settings())
	visible = false


func open(start := false, message := "") -> void:
	_starting = start
	is_open = true
	visible = true
	get_tree().paused = true
	Sound.set_paused(true)
	_resume.text = "Play" if start else "Resume"
	show_notice(message)
	_show_page("main")


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	Sound.set_paused(false)
	if _starting:
		_starting = false
		play_pressed.emit()


func show_notice(message: String) -> void:
	_notice.text = message
	_notice.visible = message != ""


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("pause") and not (event is InputEventJoypadButton):
		_go_back() # Esc or P: back a page, or close from the main page.
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		close() # Options closes straight away, like on a console.
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("back") or event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()


func _go_back() -> void:
	if _page != "main":
		_show_page("main")
	else:
		close()


func _show_page(name: String) -> void:
	var from := _page
	_page = name
	_title.text = {"settings": "Settings", "how-to-play": "How to play"}.get(name, "Lanternwood" if _starting else "Paused")
	for key in _pages:
		_pages[key].visible = key == name
	_show_hints()
	_show_settings()
	# Coming back to the main page, land on the row that led away from it.
	var land: Control = _came_from.get(from) if name == "main" else null
	if land == null or not land.is_visible_in_tree():
		land = _first_row(_pages[name])
	if land:
		land.grab_focus.call_deferred()


func _first_row(page: Control) -> Control:
	for node in page.find_children("*", "Control", true, false):
		if node.focus_mode == Control.FOCUS_ALL and node.is_visible_in_tree():
			return node
	return null


# --- Building the pages ---

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.1, 0.06, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = preload("res://ui/theme.tres")
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(620, 0)
	center.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	_title = _label("Lanternwood", "Title")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_notice = _label("", "Notice")
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_notice)
	column.add_child(HSeparator.new())

	# Main: Play/Resume, Settings, How to play, Quit.
	var main := _page_box(column, "main")
	_resume = _button(main, "Play", close)
	_came_from["settings"] = _button(main, "Settings", _show_page.bind("settings"))
	_came_from["how-to-play"] = _button(main, "How to play", _show_page.bind("how-to-play"))
	_button(main, "Quit", func() -> void: quit_pressed.emit())

	# Settings.
	var settings := _page_box(column, "settings")
	settings.add_child(_label("Sound", "SettingGroup"))
	_choice_row(settings, "Music", "music_on")
	_slider_row(settings, "Music volume", "music_volume")
	_slider_row(settings, "Sound volume", "sound_volume")
	_choice_row(settings, "Music style", "music_style")
	settings.add_child(_label("Camera", "SettingGroup"))
	_slider_row(settings, "Camera speed", "camera_speed", 0.25, 2.0, 0.25)
	_choice_row(settings, "Flip left and right", "invert_x")
	_choice_row(settings, "Flip up and down", "invert_y")
	settings.add_child(_label("Picture", "SettingGroup"))
	_choice_row(settings, "Graphics", "graphics")
	_choice_row(settings, "Full screen", "fullscreen")
	_button(settings, "Back", _go_back)

	# How to play.
	var help := _page_box(column, "how-to-play")
	var goal := _label("Follow the forest path. Behind the gates, archways and openings along it are games to play. Walk up to one and press F (□ on a controller) to see what's there, then press it again to go in.", "Soft")
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.custom_minimum_size.x = 560
	help.add_child(goal)
	var table := GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 26)
	table.add_theme_constant_override("v_separation", 6)
	help.add_child(table)
	for row in [
		["", "Keyboard", "Controller"],
		["Move", "W A S D or arrows", "Left stick or D-pad"],
		["Jump", "Space", "✕"],
		["Swing stick", "F", "□"],
		["Go through a gate", "F, then F", "□, then □"],
		["Turn the camera", "Q  E", "Right stick"],
		["Look up or down", "T  G", "Right stick"],
		["Pause", "Esc or P", "Options"],
		["Music on/off", "M", "In Settings"],
	]:
		for cell in row:
			table.add_child(_label(cell, "Soft" if row[0] == "" else "Label"))
	_button(help, "Back", _go_back)

	column.add_child(HSeparator.new())
	_hints = HBoxContainer.new()
	_hints.alignment = BoxContainer.ALIGNMENT_CENTER
	_hints.add_theme_constant_override("separation", 22)
	column.add_child(_hints)


func _page_box(parent: Control, name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)
	_pages[name] = box
	return box


func _label(text: String, variation := "Label") -> Label:
	var made := Label.new()
	made.text = text
	made.theme_type_variation = variation
	return made


func _button(parent: Control, text: String, action: Callable) -> Button:
	var made := Button.new()
	made.text = text
	made.alignment = HORIZONTAL_ALIGNMENT_LEFT
	made.pressed.connect(func() -> void:
		Sound.play_pop()
		action.call())
	made.mouse_entered.connect(made.grab_focus) # Pointing at a row chooses it.
	parent.add_child(made)
	return made


# A setting changed with left and right: "Music style   ‹ Forest ›".
func _choice_row(parent: Control, text: String, setting: String) -> void:
	var row := _row(parent, text)
	var value := Button.new()
	value.custom_minimum_size.x = 190
	value.alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	value.pressed.connect(_step_choice.bind(setting, 1))
	value.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_step_choice(setting, -1 if event.is_action_pressed("ui_left") else 1)
			value.accept_event())
	_hook_row(row, value)
	_rows_for_setting[setting] = value


func _step_choice(setting: String, step: int) -> void:
	var options: Array = CHOICES[setting]
	var at := 0
	for i in options.size():
		if options[i][0] == Settings.get_value(setting):
			at = i
	Settings.set_value(setting, options[posmod(at + step, options.size())][0])
	Sound.play_pop()


# A setting with a slider: volumes and camera speed. Left and right nudge it.
func _slider_row(parent: Control, text: String, setting: String, low := 0.0, high := 1.0, step := VOLUME_STEP) -> void:
	var row := _row(parent, text)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.custom_minimum_size = Vector2(190, 26)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set_value(setting, value)
		if setting == "sound_volume":
			Sound.play_pop()) # A sample, so you can hear how loud the effects are now.
	var amount := _label("", "Soft")
	amount.custom_minimum_size.x = 64
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.get_child(0).add_child(amount)
	_hook_row(row, slider)
	slider.set_meta("amount", amount)
	_rows_for_setting[setting] = slider


func _row(parent: Control, text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "RowPanel"
	parent.add_child(panel)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	panel.add_child(line)
	var name_label := _label(text, "RowLabel")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	return panel


# The whole row lights up when its control is chosen, and pointing anywhere on it chooses it.
func _hook_row(row: PanelContainer, control: Control) -> void:
	row.get_child(0).add_child(control)
	control.focus_entered.connect(func() -> void: row.theme_type_variation = "ChosenRow")
	control.focus_exited.connect(func() -> void: row.theme_type_variation = "RowPanel")
	row.mouse_entered.connect(control.grab_focus)
	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and control is Button:
			control.pressed.emit())


func _show_settings() -> void:
	for setting in _rows_for_setting:
		var control: Control = _rows_for_setting[setting]
		var value: Variant = Settings.get_value(setting)
		if control is HSlider:
			control.set_value_no_signal(value)
			var amount: Label = control.get_meta("amount")
			amount.text = ("%d%%" % roundi(value * 100.0)) if setting.ends_with("volume") else ("%.2f×" % value).replace(".00", "").replace("0×", "×")
		else:
			for option in CHOICES[setting]:
				if option[0] == value:
					control.text = "‹  %s  ›" % option[1]


# The button hints along the bottom, for whichever the player is using.
func _show_hints() -> void:
	for child in _hints.get_children():
		child.queue_free()
	var close_word := "Play" if _starting else "Resume"
	var hints := [["✕", "Select"], ["○", "Back"], ["Options", close_word]] if InputHints.using_controller else [["↑ ↓", "Choose"], ["← →", "Change"], ["Enter", "Select"], ["Esc", "Back"]]
	for hint in hints:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 6)
		pair.add_child(_label(hint[0], "KeyCap"))
		pair.add_child(_label(hint[1], "Soft"))
		_hints.add_child(pair)
