## The Chime-Shrine's upgrade menu, drawn over one player's split-screen cell
## and driven by that player's own controller: up / down to choose, light to
## buy, dodge to close. Upgrades are shared by the whole party, last between
## sessions and scale everyone's base stats (PartyProgress).
class_name HubUpgradeMenu
extends PanelContainer

signal closed

const WIDTH: float = 470.0
const TITLE_SIZE: int = 26
const FONT_SIZE: int = 17
const SMALL_FONT_SIZE: int = 13
const SELECTED_COLOR: Color = Color(1.0, 0.86, 0.4)
const DIM_COLOR: Color = Color(0.8, 0.82, 0.9)
const PANEL_COLOR: Color = Color(0.07, 0.07, 0.1, 0.92)
const BORDER_COLOR: Color = Color(1.0, 0.8, 0.42)
## Seconds a "Bought!" or "Not enough Chimes" note stays up.
const NOTE_TIME: float = 2.5

var actor: ActorBase
var selected: int = 0

var _chimes_label: Label
var _rows: Array[Label] = []
var _note_label: Label
var _hint_label: Label
var _note_left: float = 0.0


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "HubUpgradeMenu"
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.45
	anchor_bottom = 0.45
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(WIDTH, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16.0)
	add_theme_stylebox_override(&"panel", style)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var title: Label = _label(TITLE_SIZE)
	title.text = "CHIME-SHRINE"
	title.modulate = BORDER_COLOR.lightened(0.3)
	column.add_child(title)
	_chimes_label = _label(FONT_SIZE)
	column.add_child(_chimes_label)
	for index: int in option_count():
		var row: Label = _label(FONT_SIZE)
		column.add_child(row)
		_rows.append(row)
	_note_label = _label(FONT_SIZE)
	column.add_child(_note_label)
	_hint_label = _label(SMALL_FONT_SIZE)
	_hint_label.modulate = DIM_COLOR
	column.add_child(_hint_label)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(_on_menu_input)
	PartyProgress.current.progress_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	var progress: PartyProgress = PartyProgress.current
	if progress != null and progress.progress_changed.is_connected(_refresh):
		progress.progress_changed.disconnect(_refresh)
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
		if actor.input.menu_input.is_connected(_on_menu_input):
			actor.input.menu_input.disconnect(_on_menu_input)


func _process(delta: float) -> void:
	_note_left = maxf(0.0, _note_left - delta)
	_note_label.modulate.a = minf(1.0, _note_left)


## Every upgrade, plus Close at the bottom.
func option_count() -> int:
	return PartyProgress.UPGRADES.size() + 1


func move_cursor(step: int) -> void:
	selected = wrapi(selected + step, 0, option_count())
	AudioCues.play(&"menu_move")
	_refresh()


func accept() -> void:
	if selected >= PartyProgress.UPGRADES.size():
		close()
		return
	var progress: PartyProgress = PartyProgress.current
	var id: StringName = PartyProgress.UPGRADES[selected]
	var upgrade: String = PartyProgress.upgrade_name(id)
	if progress.is_maxed(id):
		_show_note("%s is fully upgraded" % upgrade, false)
	elif not progress.can_buy(id):
		_show_note("Not enough Chimes: %s costs %d" % [upgrade, progress.cost_of(id)], false)
	else:
		var next_level: int = progress.level_of(id) + 1
		progress.request_purchase(id)
		_show_note("Bought %s level %d!" % [upgrade, next_level], true)
	_refresh()


func close() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


func note_text() -> String:
	return _note_label.text if _note_left > 0.0 else ""


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


func _show_note(text: String, good: bool) -> void:
	_note_label.text = text
	_note_label.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.65) if good else Color(1.0, 0.55, 0.45))
	_note_left = NOTE_TIME
	AudioCues.play(&"purchase" if good else &"refuse")


func _refresh() -> void:
	var progress: PartyProgress = PartyProgress.current
	_chimes_label.text = "Chimes in the pouch: %d" % progress.chimes
	for index: int in _rows.size():
		var row: Label = _rows[index]
		var cursor: String = "▶ " if index == selected else "   "
		if index >= PartyProgress.UPGRADES.size():
			row.text = cursor + "Close"
		else:
			var id: StringName = PartyProgress.UPGRADES[index]
			var price: String = "MAX" if progress.is_maxed(id) else "%d Chimes" % progress.cost_of(id)
			row.text = "%s%s   Lv %d/%d   %s\n      %s" % [cursor, PartyProgress.upgrade_name(id), progress.level_of(id),
				PartyProgress.MAX_UPGRADE_LEVEL, price, PartyProgress.upgrade_blurb(id)]
		row.modulate = SELECTED_COLOR if index == selected else Color.WHITE
	if actor != null and actor.input != null:
		var input: InputComponent = actor.input
		var choose: String = "%s/%s" % [input.label(InputComponent.ACTION_MOVE_FORWARD), input.label(InputComponent.ACTION_MOVE_BACK)] \
			if input.is_keyboard() else "Stick or D-Pad"
		_hint_label.text = "%s choose · %s buy · %s close" % [choose, input.label(InputComponent.ACTION_LIGHT), input.label(InputComponent.ACTION_DODGE)]


func _label(size: int) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override(&"outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
