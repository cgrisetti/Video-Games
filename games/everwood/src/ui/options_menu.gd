## The Options menu (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.1–2.3): Esc on the
## keyboard, a tap of Options / Menu on a pad, over the player's own screen. Four
## tabs, stepped with Q / E or L1 / R1 (or a click):
##   Audio     main, music, effects and world-sound volumes
##   Video     display mode, vertical sync, frame cap, render scale, field of view
##   Controls  invert Y, camera speed, mouse sensitivity, pad button names, and
##             a keyboard and a PlayStation / Xbox pad drawn with what each key
##             and button does, read from the Input Map so they never go stale
##   Gameplay  toggle sprint, enemy level badges, the camera's push on a cast
## Up / down choose a row, left / right change it (light flips a switch), and
## Esc, Options or dodge closes it. The mouse works too: click a row's arrows.
## Every change saves at once (SettingsManager). The settings are the machine's,
## so they reach every player on this screen; developer tools live elsewhere
## (DevAdminPanel), never here.
class_name OptionsMenu
extends Control

signal closed

enum Tab { AUDIO, VIDEO, CONTROLS, GAMEPLAY }
enum Category { MOVE, FIGHT, CARDS, PARTY, MENUS }

const TAB_NAMES: Array[String] = ["Audio", "Video", "Controls", "Gameplay"]
const ROWS: Array[Array] = [
	[&"master_volume", &"music_volume", &"effects_volume", &"ambience_volume"],
	[&"window_mode", &"vsync", &"frame_cap", &"render_scale", &"field_of_view"],
	[&"invert_y_axis", &"camera_speed", &"mouse_sensitivity", &"pad_glyphs"],
	[&"toggle_sprint_mode", &"enemy_level_badges", &"camera_pulse"],
]
## The last row of every tab puts every setting back.
const RESET_ROW: StringName = &"reset"
const NAMES: Dictionary[StringName, String] = {
	&"master_volume": "Main volume", &"music_volume": "Music", &"effects_volume": "Sound effects", &"ambience_volume": "World sounds",
	&"window_mode": "Display", &"vsync": "Vertical sync", &"frame_cap": "Frame cap", &"render_scale": "Render scale",
	&"field_of_view": "Field of view", &"invert_y_axis": "Invert Y (camera up and down)", &"camera_speed": "Camera speed",
	&"mouse_sensitivity": "Mouse sensitivity", &"pad_glyphs": "Pad button names", &"toggle_sprint_mode": "Toggle sprint",
	&"enemy_level_badges": "Enemy level badges", &"camera_pulse": "Camera push on card casts", RESET_ROW: "Put everything back",
}
const HINTS: Dictionary[StringName, String] = {
	&"master_volume": "Everything you hear.", &"music_volume": "The band that plays where you are.",
	&"effects_volume": "Swings, hits, cards and chimes.", &"ambience_volume": "Wind, water, birds and the sounds of each place.",
	&"window_mode": "A window, the whole screen, or the whole screen without a border.", &"vsync": "Stops the picture tearing when the camera swings.",
	&"frame_cap": "Holds the game to a frame rate (kinder on laptops).", &"render_scale": "Lower draws the world at fewer pixels: faster, softer.",
	&"field_of_view": "How wide the camera sees.", &"invert_y_axis": "Push up to look down, on the stick and the mouse.",
	&"camera_speed": "How fast the stick and the keys turn and tilt the camera.", &"mouse_sensitivity": "How far the camera turns for each nudge of the mouse.",
	&"pad_glyphs": "Show PlayStation shapes or Xbox letters (or whatever pad you have).",
	&"toggle_sprint_mode": "On: click L3 / Shift once and keep running until you turn aside, stop, or click again. Off: hold it.",
	&"enemy_level_badges": "A badge like [Lv. 3] or [Lv. 10 Elite] over every foe.",
	&"camera_pulse": "The little push toward your shoulder when you cast a card.", RESET_ROW: "Every setting back as it came (light to do it).",
}
const BACKDROP: Color = Color(0.03, 0.03, 0.05, 0.74)
const PAGE_COLOR: Color = Color(0.13, 0.1, 0.08, 0.95)
const PAGE_EDGE: Color = Color(0.85, 0.7, 0.42)
const ROW_COLOR: Color = Color(0.95, 0.92, 0.85)
const DIM_COLOR: Color = Color(0.62, 0.6, 0.56)
const SELECTED_COLOR: Color = Color(1.0, 0.88, 0.5)
const BAR_FILL: Color = Color(0.86, 0.66, 0.3)
const BAR_BACK: Color = Color(0.06, 0.05, 0.04, 0.9)
const TITLE_SIZE: int = 26
const FONT_SIZE: int = 17
const SMALL_FONT_SIZE: int = 13
const ROW_WIDTH: float = 640.0
const REFERENCE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const MIN_FIT: float = 0.42
## Each kind of control's colour on the diagrams.
const CATEGORY_COLORS: Array[Color] = [Color(0.36, 0.66, 0.92), Color(0.9, 0.4, 0.32), Color(0.68, 0.48, 0.94), Color(0.96, 0.78, 0.34),
	Color(0.84, 0.82, 0.74)]
const CATEGORY_NAMES: Array[String] = ["Move & camera", "Fight", "Ink cards", "Party", "Menus"]
## What each action is called on the diagrams, and its kind. Developer keys (F2) are left off.
const ACTION_NAMES: Dictionary[StringName, Array] = {
	InputComponent.ACTION_MOVE_FORWARD: ["Move", Category.MOVE], InputComponent.ACTION_MOVE_BACK: ["Move", Category.MOVE],
	InputComponent.ACTION_MOVE_LEFT: ["Move", Category.MOVE], InputComponent.ACTION_MOVE_RIGHT: ["Move", Category.MOVE],
	InputComponent.ACTION_CAMERA_LEFT: ["Turn camera", Category.MOVE], InputComponent.ACTION_CAMERA_RIGHT: ["Turn camera", Category.MOVE],
	InputComponent.ACTION_CAMERA_PITCH_UP: ["Tilt camera", Category.MOVE], InputComponent.ACTION_CAMERA_PITCH_DOWN: ["Tilt camera", Category.MOVE],
	InputComponent.ACTION_MOUSE_LOOK: ["Mouse-look", Category.MOVE], InputComponent.ACTION_SPRINT: ["Sprint", Category.MOVE],
	InputComponent.ACTION_JUMP: ["Jump", Category.MOVE], InputComponent.ACTION_DODGE: ["Roll", Category.FIGHT],
	InputComponent.ACTION_LIGHT: ["Light attack", Category.FIGHT], InputComponent.ACTION_HEAVY: ["Heavy attack", Category.FIGHT],
	InputComponent.ACTION_TRIGGER_L: ["Guard · L card", Category.CARDS], InputComponent.ACTION_TRIGGER_R: ["R card", Category.CARDS],
	InputComponent.ACTION_ULT: ["Big move (L+R)", Category.CARDS],
	InputComponent.ACTION_TETHER_UP: ["Soul Tether", Category.PARTY], InputComponent.ACTION_TETHER_RIGHT: ["Soul Tether", Category.PARTY],
	InputComponent.ACTION_TETHER_DOWN: ["Soul Tether", Category.PARTY], InputComponent.ACTION_TETHER_LEFT: ["Soul Tether", Category.PARTY],
	InputComponent.ACTION_CHANGE_CLASS: ["Grimoire (tap) · Fellowship (hold)", Category.MENUS],
	InputComponent.ACTION_CHANGE_MODE: ["Map (tap) · Assist mode (hold)", Category.MENUS],
	InputComponent.ACTION_CHANGE_CALLING: ["Calling (hold)", Category.MENUS],
	InputComponent.ACTION_OPTIONS: ["Options", Category.MENUS], InputComponent.ACTION_JOIN: ["Join (tap) · Leave (hold)", Category.PARTY],
}

var actor: ActorBase
var tab: int = Tab.AUDIO
var row: int = 0

var _root: VBoxContainer
var _tab_labels: Array[Label] = []
var _rows_box: VBoxContainer
var _row_nodes: Array[Control] = []
var _hint: Label
var _diagram: ControlsDiagram
var _was_captured: bool = false


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "OptionsMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_root = VBoxContainer.new()
	_root.name = "Book"
	_root.add_theme_constant_override(&"separation", 10)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var title: Label = _label(TITLE_SIZE, PAGE_EDGE.lightened(0.3))
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(title)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override(&"separation", 26)
	_root.add_child(tabs)
	for index: int in TAB_NAMES.size():
		var tab_label: Label = _label(FONT_SIZE + 2, ROW_COLOR)
		tab_label.mouse_filter = Control.MOUSE_FILTER_STOP
		tab_label.gui_input.connect(_on_tab_clicked.bind(index))
		tabs.add_child(tab_label)
		_tab_labels.append(tab_label)
	var page: PanelContainer = PanelContainer.new()
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAGE_COLOR
	style.border_color = PAGE_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16.0)
	page.add_theme_stylebox_override(&"panel", style)
	_root.add_child(page)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(column)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override(&"separation", 4)
	_rows_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_rows_box)
	_diagram = ControlsDiagram.new()
	_diagram.name = "ControlsDiagram"
	_diagram.custom_minimum_size = Vector2(ROW_WIDTH * 1.9, 300.0)
	_diagram.device_id = actor.device_id if actor != null else InputComponent.KEYBOARD_DEVICE
	column.add_child(_diagram)
	_hint = _label(SMALL_FONT_SIZE + 1, Color(0.82, 0.84, 0.9))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(ROW_WIDTH, 0.0)
	_root.add_child(_hint)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(handle_menu)
		if actor.device_id == InputComponent.KEYBOARD_DEVICE:
			_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if SettingsManager.current != null:
		SettingsManager.current.changed.connect(_on_setting_changed)
	_rebuild()
	AudioCues.play(&"menu_move")


func _exit_tree() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
		if actor.input.menu_input.is_connected(handle_menu):
			actor.input.menu_input.disconnect(handle_menu)
	if SettingsManager.current != null and SettingsManager.current.changed.is_connected(_on_setting_changed):
		SettingsManager.current.changed.disconnect(_on_setting_changed)
	if _was_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func close() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


func _process(_delta: float) -> void:
	var fit: float = clampf(minf(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y), MIN_FIT, 1.0)
	_root.scale = Vector2.ONE * fit
	_root.size = _root.get_combined_minimum_size()
	_root.position = (size - _root.size * fit) * 0.5


# --- What's on the page --------------------------------------------------------------

## The keys of the rows on the open tab (the reset row last).
func rows() -> Array[StringName]:
	var list: Array[StringName] = []
	list.assign(ROWS[tab])
	list.append(RESET_ROW)
	return list


## The highlighted row's key.
func selected_key() -> StringName:
	var list: Array[StringName] = rows()
	return list[clampi(row, 0, list.size() - 1)]


## A setting's value as the menu shows it ("80%", "On", "Full screen").
static func value_text(key: StringName) -> String:
	var settings: SettingsManager = SettingsManager.current
	if settings == null or key == RESET_ROW:
		return ""
	var value: Variant = settings.get(key)
	match key:
		&"master_volume", &"music_volume", &"effects_volume", &"ambience_volume", &"render_scale":
			return "%d%%" % roundi(float(value) * 100.0)
		&"field_of_view":
			return "%d°" % roundi(float(value))
		&"camera_speed":
			return "%.1fx" % float(value)
		&"mouse_sensitivity":
			return "%.2fx" % float(value)
		&"frame_cap":
			return "No cap" if int(value) == 0 else "%d fps" % int(value)
		&"window_mode":
			return ["Window", "Full screen", "Borderless"][clampi(int(value), 0, 2)]
		&"pad_glyphs":
			return ["Match my pad", "PlayStation", "Xbox"][clampi(int(value), 0, 2)]
		&"toggle_sprint_mode":
			return "Click to keep running" if bool(value) else "Hold to sprint"
		&"enemy_level_badges":
			return "Shown" if bool(value) else "Hidden"
	return "On" if value is bool and bool(value) else ("Off" if value is bool else str(value))


func _rebuild() -> void:
	for index: int in _tab_labels.size():
		_tab_labels[index].text = ("◆ %s" if index == tab else "%s") % TAB_NAMES[index]
		_tab_labels[index].modulate = SELECTED_COLOR if index == tab else DIM_COLOR
	for node: Control in _row_nodes:
		node.queue_free()
	_row_nodes.clear()
	var list: Array[StringName] = rows()
	row = clampi(row, 0, list.size() - 1)
	for index: int in list.size():
		var line: Control = _make_row(list[index], index)
		_rows_box.add_child(line)
		_row_nodes.append(line)
	_diagram.visible = tab == Tab.CONTROLS
	_diagram.queue_redraw()
	_refresh()


func _make_row(key: StringName, index: int) -> Control:
	var line: HBoxContainer = HBoxContainer.new()
	line.custom_minimum_size = Vector2(ROW_WIDTH, 30.0)
	line.add_theme_constant_override(&"separation", 12)
	line.mouse_filter = Control.MOUSE_FILTER_STOP
	line.gui_input.connect(_on_row_clicked.bind(index))
	var name_label: Label = _label(FONT_SIZE, ROW_COLOR)
	name_label.name = "Name"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = NAMES.get(key, String(key))
	line.add_child(name_label)
	if SettingsManager.RANGES.has(key):
		var bar: ProgressBar = ProgressBar.new()
		bar.name = "Bar"
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(150.0, 10.0)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = BAR_FILL
		fill.set_corner_radius_all(3)
		var back: StyleBoxFlat = StyleBoxFlat.new()
		back.bg_color = BAR_BACK
		back.set_corner_radius_all(3)
		bar.add_theme_stylebox_override(&"fill", fill)
		bar.add_theme_stylebox_override(&"background", back)
		var range_of: Vector3 = SettingsManager.RANGES[key]
		bar.min_value = range_of.x
		bar.max_value = range_of.y
		bar.step = 0.0
		line.add_child(bar)
	var value: Label = _label(FONT_SIZE, SELECTED_COLOR)
	value.name = "Value"
	value.custom_minimum_size = Vector2(210.0, 0.0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(value)
	return line


## Fills every row's value, bar and highlight, and the hint.
func _refresh() -> void:
	var list: Array[StringName] = rows()
	for index: int in _row_nodes.size():
		var line: Control = _row_nodes[index]
		var key: StringName = list[index]
		var chosen: bool = index == row
		(line.get_node(^"Name") as Label).modulate = SELECTED_COLOR if chosen else ROW_COLOR
		(line.get_node(^"Value") as Label).text = ("◀ %s ▶" % value_text(key)) if chosen and key != RESET_ROW else value_text(key)
		var bar: ProgressBar = line.get_node_or_null(^"Bar") as ProgressBar
		if bar != null and SettingsManager.current != null:
			bar.value = float(SettingsManager.current.get(key))
	var device: int = actor.device_id if actor != null else InputComponent.KEYBOARD_DEVICE
	var keys_hint: String = "↑/↓ choose · ←/→ change · %s / %s tabs · %s or %s closes" % [
		InputComponent.binding_label(InputComponent.ACTION_TRIGGER_L, device), InputComponent.binding_label(InputComponent.ACTION_TRIGGER_R, device),
		InputComponent.binding_label(InputComponent.ACTION_OPTIONS, device), InputComponent.binding_label(InputComponent.ACTION_DODGE, device)]
	_hint.text = "%s\n%s" % [HINTS.get(selected_key(), ""), keys_hint]


# --- Moving and changing ---------------------------------------------------------------

func handle_menu(action: StringName) -> void:
	match action:
		InputComponent.MENU_UP:
			row = wrapi(row - 1, 0, rows().size())
		InputComponent.MENU_DOWN:
			row = wrapi(row + 1, 0, rows().size())
		InputComponent.MENU_LEFT:
			change(selected_key(), -1)
		InputComponent.MENU_RIGHT:
			change(selected_key(), 1)
		InputComponent.MENU_ACCEPT:
			change(selected_key(), 1)
		InputComponent.MENU_TAB_PREV:
			set_tab(wrapi(tab - 1, 0, TAB_NAMES.size()))
			return
		InputComponent.MENU_TAB_NEXT:
			set_tab(wrapi(tab + 1, 0, TAB_NAMES.size()))
			return
		InputComponent.MENU_BACK:
			close()
			return
	AudioCues.play(&"menu_move")
	_refresh()


func set_tab(index: int) -> void:
	tab = clampi(index, 0, TAB_NAMES.size() - 1)
	row = 0
	AudioCues.play(&"menu_move")
	_rebuild()


## Steps a setting one notch (the reset row resets everything).
func change(key: StringName, step: int) -> void:
	var settings: SettingsManager = SettingsManager.current
	if settings == null:
		return
	if key == RESET_ROW:
		if step > 0:
			settings.reset_to_defaults()
		return
	settings.step_value(key, step)


func _on_setting_changed(_key: StringName) -> void:
	_refresh()
	_diagram.queue_redraw()


func _on_tab_clicked(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		set_tab(index)


## A click picks the row; a click on its value's left half turns it down, the right half up.
func _on_row_clicked(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	row = index
	var line: Control = _row_nodes[index]
	var value: Control = line.get_node(^"Value") as Control
	var at: float = click.position.x
	if at >= value.position.x:
		change(selected_key(), -1 if at < value.position.x + value.size.x * 0.5 else 1)
	_refresh()
	accept_event()


func _label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override(&"outline_size", 4)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# --- The Controls tab's drawings -----------------------------------------------------------

## What each key and pad button does, as [names, category] (read from the Input Map).
static func keyboard_bindings() -> Dictionary[int, Array]:
	var found: Dictionary[int, Array] = {}
	for action: StringName in ACTION_NAMES:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			var key: InputEventKey = event as InputEventKey
			if key != null:
				var code: int = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
				_note(found, code, ACTION_NAMES[action])
	return found


## The pad's controls: JoyButton numbers, and the sticks and triggers as -1 to -4 (see ControlsDiagram.STICK_*).
static func pad_bindings() -> Dictionary[int, Array]:
	var found: Dictionary[int, Array] = {}
	for action: StringName in ACTION_NAMES:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			var button: InputEventJoypadButton = event as InputEventJoypadButton
			if button != null:
				_note(found, int(button.button_index), ACTION_NAMES[action])
			var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
			if motion != null:
				var slot: int = ControlsDiagram.LEFT_STICK
				match motion.axis:
					JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
						slot = ControlsDiagram.RIGHT_STICK
					JOY_AXIS_TRIGGER_LEFT:
						slot = ControlsDiagram.LEFT_TRIGGER
					JOY_AXIS_TRIGGER_RIGHT:
						slot = ControlsDiagram.RIGHT_TRIGGER
				_note(found, slot, ACTION_NAMES[action])
	return found


static func _note(found: Dictionary[int, Array], slot: int, named: Array) -> void:
	if not found.has(slot):
		found[slot] = [PackedStringArray(), int(named[1])]
	var names: PackedStringArray = found[slot][0]
	if not names.has(String(named[0])):
		names.append(String(named[0]))
	found[slot][0] = names


## The keyboard and the pad, drawn in code with each control coloured by what kind of thing it does.
class ControlsDiagram:
	extends Control

	const LEFT_STICK: int = -1
	const RIGHT_STICK: int = -2
	const LEFT_TRIGGER: int = -3
	const RIGHT_TRIGGER: int = -4
	const KEY: float = 25.0
	const GAP: float = 3.0
	## A 60% keyboard plus the arrows and Page keys: [label, keycode, width in keys] rows.
	const KEY_ROWS: Array[Array] = [
		[["Esc", KEY_ESCAPE, 1.0], ["1", KEY_1, 1.0], ["2", KEY_2, 1.0], ["3", KEY_3, 1.0], ["4", KEY_4, 1.0], ["5", KEY_5, 1.0], ["6", KEY_6, 1.0],
			["7", KEY_7, 1.0], ["8", KEY_8, 1.0], ["9", KEY_9, 1.0], ["0", KEY_0, 1.0], ["PgUp", KEY_PAGEUP, 1.4]],
		[["Tab", KEY_TAB, 1.5], ["Q", KEY_Q, 1.0], ["W", KEY_W, 1.0], ["E", KEY_E, 1.0], ["R", KEY_R, 1.0], ["T", KEY_T, 1.0], ["Y", KEY_Y, 1.0],
			["U", KEY_U, 1.0], ["I", KEY_I, 1.0], ["O", KEY_O, 1.0], ["P", KEY_P, 1.0], ["[", KEY_BRACKETLEFT, 1.0], ["]", KEY_BRACKETRIGHT, 1.0]],
		[["Caps", KEY_CAPSLOCK, 1.8], ["A", KEY_A, 1.0], ["S", KEY_S, 1.0], ["D", KEY_D, 1.0], ["F", KEY_F, 1.0], ["G", KEY_G, 1.0], ["H", KEY_H, 1.0],
			["J", KEY_J, 1.0], ["K", KEY_K, 1.0], ["L", KEY_L, 1.0], [";", KEY_SEMICOLON, 1.0], ["Enter", KEY_ENTER, 1.8]],
		[["Shift", KEY_SHIFT, 2.3], ["Z", KEY_Z, 1.0], ["X", KEY_X, 1.0], ["C", KEY_C, 1.0], ["V", KEY_V, 1.0], ["B", KEY_B, 1.0], ["N", KEY_N, 1.0],
			["M", KEY_M, 1.0], [",", KEY_COMMA, 1.0], [".", KEY_PERIOD, 1.0], ["PgDn", KEY_PAGEDOWN, 1.4], ["↑", KEY_UP, 1.0]],
		[["Ctrl", KEY_CTRL, 1.5], ["Alt", KEY_ALT, 1.3], ["Space", KEY_SPACE, 6.0], ["Alt", KEY_ALT, 1.3], ["←", KEY_LEFT, 1.0],
			["↓", KEY_DOWN, 1.0], ["→", KEY_RIGHT, 1.0]],
	]

	var device_id: int = InputComponent.KEYBOARD_DEVICE

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var half: float = size.x * 0.5
		_draw_keyboard(font, Vector2(4.0, 4.0))
		_draw_pad(font, Rect2(Vector2(half + 8.0, 0.0), Vector2(half - 12.0, size.y)))

	## Which pad family to draw: the Options setting, else this player's pad, else PlayStation.
	func pad_family() -> InputComponent.PadFamily:
		match SettingsManager.glyphs():
			SettingsManager.PadGlyphs.PLAYSTATION:
				return InputComponent.PadFamily.PLAYSTATION
			SettingsManager.PadGlyphs.XBOX:
				return InputComponent.PadFamily.XBOX
		if device_id != InputComponent.KEYBOARD_DEVICE:
			return InputComponent.pad_family_of(device_id)
		return InputComponent.PadFamily.PLAYSTATION

	func _draw_keyboard(font: Font, origin: Vector2) -> void:
		var bound: Dictionary[int, Array] = OptionsMenu.keyboard_bindings()
		var y: float = origin.y
		for key_row: Array in KEY_ROWS:
			var x: float = origin.x
			for cap: Array in key_row:
				var width: float = KEY * float(cap[2]) + GAP * (float(cap[2]) - 1.0)
				var box: Rect2 = Rect2(Vector2(x, y), Vector2(width, KEY))
				var code: int = int(cap[1])
				var lit: bool = bound.has(code)
				var tint: Color = OptionsMenu.CATEGORY_COLORS[int(bound[code][1])] if lit else Color(0.24, 0.21, 0.18)
				draw_rect(box, tint.darkened(0.15) if lit else tint)
				draw_rect(box, Color(0.05, 0.04, 0.03), false, 1.0)
				draw_string(font, box.position + Vector2(0.0, KEY * 0.68), String(cap[0]), HORIZONTAL_ALIGNMENT_CENTER, width,
					10 if String(cap[0]).length() > 2 else 12, Color(0.06, 0.05, 0.04) if lit else Color(0.7, 0.67, 0.6))
				x += width + GAP
			y += KEY + GAP
		# The mouse beside the keys.
		var mouse: Rect2 = Rect2(Vector2(origin.x + 14.0 * (KEY + GAP) + 6.0, origin.y + KEY * 1.2), Vector2(KEY * 1.6, KEY * 2.4))
		draw_rect(mouse, Color(0.24, 0.21, 0.18))
		draw_rect(Rect2(mouse.position, Vector2(mouse.size.x * 0.5, mouse.size.y * 0.4)), OptionsMenu.CATEGORY_COLORS[Category.FIGHT].darkened(0.15))
		draw_rect(Rect2(mouse.position + Vector2(mouse.size.x * 0.5, 0.0), Vector2(mouse.size.x * 0.5, mouse.size.y * 0.4)),
			OptionsMenu.CATEGORY_COLORS[Category.FIGHT].darkened(0.35))
		draw_rect(mouse, Color(0.05, 0.04, 0.03), false, 1.0)
		draw_string(font, mouse.position + Vector2(-8.0, mouse.size.y + 13.0), "Light · Heavy", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.85, 0.82, 0.75))
		# What the lit keys do, in two columns under the board.
		var lines: PackedStringArray = PackedStringArray()
		var colors: Array[Color] = []
		var by_name: Dictionary[String, PackedStringArray] = {}
		var name_color: Dictionary[String, Color] = {}
		for code: int in bound:
			for action_name: String in bound[code][0]:
				if not by_name.has(action_name):
					by_name[action_name] = PackedStringArray()
					name_color[action_name] = OptionsMenu.CATEGORY_COLORS[int(bound[code][1])]
				by_name[action_name].append(OS.get_keycode_string(code))
		for action_name: String in by_name:
			lines.append("%s  %s" % [" ".join(by_name[action_name]), action_name])
			colors.append(name_color[action_name])
		var top: float = y + 8.0
		for index: int in lines.size():
			var at: Vector2 = Vector2(origin.x + (index % 2) * 230.0, top + (index / 2) * 15.0)
			draw_rect(Rect2(at + Vector2(0.0, -8.0), Vector2(8.0, 8.0)), colors[index])
			draw_string(font, at + Vector2(12.0, 0.0), lines[index], HORIZONTAL_ALIGNMENT_LEFT, 214.0, 11, Color(0.88, 0.86, 0.8))

	func _draw_pad(font: Font, area: Rect2) -> void:
		var family: InputComponent.PadFamily = pad_family()
		var playstation: bool = family == InputComponent.PadFamily.PLAYSTATION
		var bound: Dictionary[int, Array] = OptionsMenu.pad_bindings()
		var center: Vector2 = area.position + Vector2(area.size.x * 0.5, 120.0)
		var body: Color = Color(0.3, 0.27, 0.24) if playstation else Color(0.24, 0.27, 0.24)
		# The body and its two grips.
		draw_colored_polygon(PackedVector2Array([center + Vector2(-120.0, -40.0), center + Vector2(120.0, -40.0), center + Vector2(150.0, 10.0),
			center + Vector2(165.0, 70.0), center + Vector2(140.0, 95.0), center + Vector2(95.0, 60.0), center + Vector2(-95.0, 60.0),
			center + Vector2(-140.0, 95.0), center + Vector2(-165.0, 70.0), center + Vector2(-150.0, 10.0)]), body)
		var title: String = "PlayStation pad" if playstation else "Xbox pad"
		draw_string(font, area.position + Vector2(0.0, 12.0), title, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 13, Color(0.9, 0.86, 0.76))
		# Shoulders and triggers, top.
		var spots: Dictionary[int, Vector2] = {
			LEFT_TRIGGER: center + Vector2(-110.0, -66.0), JOY_BUTTON_LEFT_SHOULDER: center + Vector2(-110.0, -50.0),
			RIGHT_TRIGGER: center + Vector2(110.0, -66.0), JOY_BUTTON_RIGHT_SHOULDER: center + Vector2(110.0, -50.0),
			LEFT_STICK: center + Vector2(-58.0, 32.0), RIGHT_STICK: center + Vector2(58.0, 32.0),
			JOY_BUTTON_LEFT_STICK: center + Vector2(-58.0, 32.0), JOY_BUTTON_RIGHT_STICK: center + Vector2(58.0, 32.0),
			JOY_BUTTON_DPAD_UP: center + Vector2(-100.0, -12.0), JOY_BUTTON_DPAD_DOWN: center + Vector2(-100.0, 16.0),
			JOY_BUTTON_DPAD_LEFT: center + Vector2(-114.0, 2.0), JOY_BUTTON_DPAD_RIGHT: center + Vector2(-86.0, 2.0),
			JOY_BUTTON_Y: center + Vector2(100.0, -16.0), JOY_BUTTON_A: center + Vector2(100.0, 20.0),
			JOY_BUTTON_X: center + Vector2(82.0, 2.0), JOY_BUTTON_B: center + Vector2(118.0, 2.0),
			JOY_BUTTON_BACK: center + Vector2(-34.0, -18.0), JOY_BUTTON_START: center + Vector2(34.0, -18.0),
		}
		for slot: int in [LEFT_TRIGGER, RIGHT_TRIGGER]:
			draw_rect(Rect2(spots[slot] - Vector2(24.0, 7.0), Vector2(48.0, 12.0)), _tint(bound, slot))
		for slot: int in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
			draw_rect(Rect2(spots[slot] - Vector2(26.0, 5.0), Vector2(52.0, 10.0)), _tint(bound, slot))
		for slot: int in [LEFT_STICK, RIGHT_STICK]:
			draw_circle(spots[slot], 17.0, Color(0.12, 0.11, 0.1))
			draw_circle(spots[slot], 12.0, _tint(bound, slot))
		for slot: int in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
			draw_rect(Rect2(spots[slot] - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), _tint(bound, slot))
		for slot: int in [JOY_BUTTON_Y, JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_B]:
			draw_circle(spots[slot], 9.0, _tint(bound, slot))
			draw_string(font, spots[slot] + Vector2(-9.0, 5.0), InputComponent._pad_button_name(slot as JoyButton, family), HORIZONTAL_ALIGNMENT_CENTER,
				18.0, 12, Color(0.06, 0.05, 0.04))
		for slot: int in [JOY_BUTTON_BACK, JOY_BUTTON_START]:
			draw_rect(Rect2(spots[slot] - Vector2(9.0, 4.0), Vector2(18.0, 8.0)), _tint(bound, slot))
		# Callouts: the left half's controls to the left, the right half's to the right.
		var names: Dictionary[int, String] = {
			LEFT_TRIGGER: "L2" if playstation else "LT", RIGHT_TRIGGER: "R2" if playstation else "RT",
			LEFT_STICK: "Left stick", RIGHT_STICK: "Right stick",
		}
		var left_order: Array[int] = [LEFT_TRIGGER, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_BACK, JOY_BUTTON_DPAD_UP, LEFT_STICK, JOY_BUTTON_LEFT_STICK]
		var right_order: Array[int] = [RIGHT_TRIGGER, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_START, JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_A,
			JOY_BUTTON_X, RIGHT_STICK, JOY_BUTTON_RIGHT_STICK]
		_callouts(font, bound, spots, names, family, left_order, area.position.x + 2.0, area.position.y + 150.0 + 70.0, true)
		_callouts(font, bound, spots, names, family, right_order, area.end.x - 2.0, area.position.y + 150.0 + 70.0 - 30.0, false)

	func _callouts(font: Font, bound: Dictionary[int, Array], spots: Dictionary[int, Vector2], names: Dictionary[int, String],
			family: InputComponent.PadFamily, order: Array[int], edge_x: float, top: float, left: bool) -> void:
		var y: float = top
		for slot: int in order:
			if not bound.has(slot):
				continue
			var label: String = names.get(slot, "")
			if label == "":
				label = "D-Pad" if slot == JOY_BUTTON_DPAD_UP else InputComponent._pad_button_name(slot as JoyButton, family)
			var text: String = "%s  %s" % [label, " · ".join(bound[slot][0])]
			var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11).x
			var at: Vector2 = Vector2(edge_x if left else edge_x - width, y)
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, OptionsMenu.CATEGORY_COLORS[int(bound[slot][1])].lightened(0.25))
			draw_line(Vector2(at.x + (width + 2.0 if left else -2.0), y - 4.0), spots[slot], Color(0.8, 0.76, 0.66, 0.5), 1.0)
			y += 15.0

	func _tint(bound: Dictionary[int, Array], slot: int) -> Color:
		return OptionsMenu.CATEGORY_COLORS[int(bound[slot][1])] if bound.has(slot) else Color(0.4, 0.38, 0.35)
