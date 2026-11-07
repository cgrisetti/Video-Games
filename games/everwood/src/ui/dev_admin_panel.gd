## The Developer Tools (13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.13): everything
## that is for testing the game, kept apart from what belongs to the player.
## The Grimoire Binder holds the hero's gear, cards, combos and map, and the
## Options menu the player's settings; neither shows a test tool. This panel
## opens on its own key (F1, or hold Share and tap D-Pad ↑) and looks nothing
## like them: a dark workbench under a yellow-and-black hazard band, in a
## typewriter face, saying plainly that it isn't part of the game.
##
## It gathers the test tools that were scattered over keys and the old top
## banner: the debug hero switch (F2), ending a playtest, the Caldera's
## playtest warp (F9), hosting, joining and leaving a network game (F5, F6,
## F7), and the lines the banner used to show (the level's hint and keys, the
## network status). ↑/↓ choose, light (Enter) does it, dodge (Esc) or F1 closes.
class_name DevAdminPanel
extends Control

signal closed

enum Tool { DEBUG_NEXT, DEBUG_PREVIOUS, END_PLAYTEST, WARP, HOST, JOIN, LEAVE, CLOSE }
const TOOL_NAMES: Array[String] = [
	"Debug hero: next Calling and level",
	"Debug hero: previous",
	"End the playtest (back to the saved level)",
	"Playtest warp: Oakshire Holm ⇄ The Crown",
	"Host a network game",
	"Join a network game",
	"Leave the network game",
	"Close the Developer Tools",
]
const TOOL_KEYS: Array[String] = ["F2 · Share + D-Pad →", "Share + D-Pad ←", "", "F9", "F5", "F6", "F7", "F1 · Esc"]
const TITLE: String = "DEVELOPER TOOLS"
const SUBTITLE: String = "For testing the game: not part of your hero's gear, cards, combos or map. Playtest changes are never saved."
## The workbench's look: charcoal, hazard yellow and a typewriter face.
const BACKDROP: Color = Color(0.02, 0.02, 0.03, 0.8)
const BENCH_COLOR: Color = Color(0.11, 0.115, 0.13, 0.97)
const HAZARD_YELLOW: Color = Color(1.0, 0.8, 0.12)
const HAZARD_BLACK: Color = Color(0.08, 0.08, 0.08)
const ROW_COLOR: Color = Color(0.86, 0.88, 0.9)
const KEY_COLOR: Color = Color(0.6, 0.64, 0.7)
const SELECTED_COLOR: Color = Color(1.0, 0.84, 0.25)
const DIM_COLOR: Color = Color(0.45, 0.47, 0.5)
const MONO_FONTS: PackedStringArray = ["Menlo", "Consolas", "DejaVu Sans Mono", "Liberation Mono", "monospace"]
const BENCH_WIDTH: float = 760.0
const HAZARD_HEIGHT: float = 18.0
const STRIPE_WIDTH: float = 22.0
const TITLE_SIZE: int = 26
const FONT_SIZE: int = 16
const SMALL_FONT_SIZE: int = 13
const REFERENCE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const MIN_FIT: float = 0.45

var actor: ActorBase
var level: LevelBase
var row: int = 0
## The last tool's result, under the rows.
var report: String = ""

var _bench: PanelContainer
var _rows: Array[Label] = []
var _info: Label
var _report: Label
var _mono: SystemFont
var _was_captured: bool = false


func setup(target_actor: ActorBase, target_level: LevelBase) -> void:
	actor = target_actor
	level = target_level


func _ready() -> void:
	name = "DevAdminPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_mono = SystemFont.new()
	_mono.font_names = MONO_FONTS
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_bench = PanelContainer.new()
	_bench.name = "Workbench"
	_bench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BENCH_COLOR
	style.border_color = HAZARD_YELLOW
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(18.0)
	style.content_margin_top = 18.0 + HAZARD_HEIGHT
	_bench.add_theme_stylebox_override(&"panel", style)
	add_child(_bench)
	_bench.draw.connect(_draw_hazard_band)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	column.custom_minimum_size = Vector2(BENCH_WIDTH, 0.0)
	_bench.add_child(column)
	var title: Label = _label(TITLE_SIZE, HAZARD_YELLOW)
	title.text = "⚠ " + TITLE
	column.add_child(title)
	var subtitle: Label = _label(SMALL_FONT_SIZE, KEY_COLOR)
	subtitle.text = SUBTITLE
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)
	column.add_child(HSeparator.new())
	for index: int in Tool.size():
		var line: Label = _label(FONT_SIZE, ROW_COLOR)
		line.mouse_filter = Control.MOUSE_FILTER_STOP
		line.gui_input.connect(_on_row_clicked.bind(index))
		column.add_child(line)
		_rows.append(line)
	_report = _label(SMALL_FONT_SIZE, SELECTED_COLOR)
	_report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_report)
	column.add_child(HSeparator.new())
	_info = _label(SMALL_FONT_SIZE, KEY_COLOR)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_info)
	var hint: Label = _label(SMALL_FONT_SIZE, DIM_COLOR)
	hint.text = "↑/↓ choose · light or Enter does it · dodge, Esc or F1 closes"
	column.add_child(hint)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(handle_menu)
		if actor.device_id == InputComponent.KEYBOARD_DEVICE:
			_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()
	AudioCues.play(&"menu_move")


func _exit_tree() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
		if actor.input.menu_input.is_connected(handle_menu):
			actor.input.menu_input.disconnect(handle_menu)
		if actor.device_id == InputComponent.KEYBOARD_DEVICE and _was_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func close() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


func _process(_delta: float) -> void:
	var fit: float = clampf(minf(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y), MIN_FIT, 1.0)
	_bench.scale = Vector2.ONE * fit
	_bench.size = _bench.get_combined_minimum_size()
	_bench.position = (size - _bench.size * fit) * 0.5
	_info.text = info_text()


## The tools this level offers right now, in order (the warp only in the Caldera, ending a playtest only during one).
func tools() -> Array[int]:
	var offered: Array[int] = [Tool.DEBUG_NEXT, Tool.DEBUG_PREVIOUS]
	if PartyProgress.current != null and PartyProgress.current.playtest:
		offered.append(Tool.END_PLAYTEST)
	if level is CalderaArchipelagoWorld:
		offered.append(Tool.WARP)
	offered.append_array([Tool.HOST, Tool.JOIN, Tool.LEAVE, Tool.CLOSE])
	return offered


func selected_tool() -> int:
	var offered: Array[int] = tools()
	return offered[clampi(row, 0, offered.size() - 1)]


## What the old top banner showed, and the playtest's state.
func info_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	var banner: String = level.debug_banner_text() if level != null else ""
	if banner != "":
		lines.append(banner)
	var progress: PartyProgress = PartyProgress.current
	if progress != null:
		lines.append("Playtest: %s · trail Level %d · Grimoire Lv %d" % ["on (nothing is saved)" if progress.playtest else "off",
			progress.trail_level(), progress.grimoire_level()])
	lines.append("%d frames a second" % roundi(Engine.get_frames_per_second()))
	return "\n".join(lines)


func handle_menu(action: StringName) -> void:
	var offered: Array[int] = tools()
	match action:
		InputComponent.MENU_UP:
			row = wrapi(row - 1, 0, offered.size())
		InputComponent.MENU_DOWN:
			row = wrapi(row + 1, 0, offered.size())
		InputComponent.MENU_ACCEPT:
			use(selected_tool())
			return
		InputComponent.MENU_BACK:
			close()
			return
		_:
			return
	AudioCues.play(&"menu_move")
	_refresh()


## Does a tool (the same thing its key does).
func use(tool: int) -> void:
	var device: int = actor.device_id if actor != null else InputComponent.KEYBOARD_DEVICE
	match tool:
		Tool.DEBUG_NEXT, Tool.DEBUG_PREVIOUS:
			if level != null:
				level._on_playtest_cycle(1 if tool == Tool.DEBUG_NEXT else -1, device)
			report = level._notice if level != null else ""
			# The switch rebuilt the hero: this panel belongs to the old one.
			if not is_instance_valid(actor) or actor.is_queued_for_deletion():
				close()
				return
		Tool.END_PLAYTEST:
			PartyProgress.current.end_playtest()
			PlaytestSwitcher.reset()
			if CalderaWorldState.current != null:
				CalderaWorldState.current.playtest = false
			report = "The playtest is over: back to trail Level %d." % PartyProgress.current.trail_level()
		Tool.WARP:
			var caldera: CalderaArchipelagoWorld = level as CalderaArchipelagoWorld
			if caldera != null and caldera.may_decide():
				caldera.playtest_warp()
				report = "Warped the party."
		Tool.HOST:
			NetworkManager.current.host_game()
			report = NetworkManager.current.status
		Tool.JOIN:
			NetworkManager.current.join_game(level._join_address if level != null else "127.0.0.1")
			report = NetworkManager.current.status
		Tool.LEAVE:
			NetworkManager.current.leave_game()
			report = NetworkManager.current.status
		Tool.CLOSE:
			close()
			return
	AudioCues.play(&"equip")
	row = clampi(row, 0, tools().size() - 1)
	_refresh()


func _refresh() -> void:
	var offered: Array[int] = tools()
	row = clampi(row, 0, offered.size() - 1)
	for index: int in _rows.size():
		var at: int = offered.find(index)
		var line: Label = _rows[index]
		line.visible = at >= 0
		if at < 0:
			continue
		var keys: String = TOOL_KEYS[index]
		line.text = "%s %-46s %s" % ["▶" if at == row else " ", TOOL_NAMES[index], ("[%s]" % keys) if keys != "" else ""]
		line.modulate = SELECTED_COLOR if at == row else ROW_COLOR
	_report.text = report
	_report.visible = report != ""


func _on_row_clicked(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var at: int = tools().find(index)
	if at < 0:
		return
	row = at
	use(index)


## The yellow-and-black hazard band across the bench's top.
func _draw_hazard_band() -> void:
	var width: float = _bench.size.x
	_bench.draw_rect(Rect2(0.0, 0.0, width, HAZARD_HEIGHT), HAZARD_BLACK)
	var x: float = -HAZARD_HEIGHT
	while x < width:
		# Each slanted stripe, kept inside the band.
		var stripe: PackedVector2Array = PackedVector2Array()
		for corner: Vector2 in [Vector2(x, HAZARD_HEIGHT), Vector2(x + STRIPE_WIDTH * 0.5, HAZARD_HEIGHT),
				Vector2(x + STRIPE_WIDTH * 0.5 + HAZARD_HEIGHT, 0.0), Vector2(x + HAZARD_HEIGHT, 0.0)]:
			stripe.append(Vector2(clampf(corner.x, 0.0, width), corner.y))
		# (A stripe clamped flat against an edge has no area left to draw.)
		if stripe[1].x - stripe[0].x + stripe[2].x - stripe[3].x > 0.5:
			_bench.draw_colored_polygon(stripe, HAZARD_YELLOW)
		x += STRIPE_WIDTH
	_bench.draw_rect(Rect2(0.0, 0.0, width, HAZARD_HEIGHT), HAZARD_BLACK, false, 2.0)


func _label(font_size: int, color: Color) -> Label:
	var made: Label = Label.new()
	made.add_theme_font_override(&"font", _mono)
	made.add_theme_font_size_override(&"font_size", font_size)
	made.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	made.add_theme_constant_override(&"outline_size", 3)
	made.modulate = color
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return made
