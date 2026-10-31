extends CanvasLayer

# The Top 10 board, shown at the end of each round: a page from the storybook with the ten best,
# a line saying how the round went, and, for a score that makes the board, a place to write your
# name (up to 10 letters; "Gnome" if you leave it blank). "Reset leaderboard" in the corner asks
# once more before it wipes the board. Play again or go back to the Glenn from here, or switch
# fields (Berry Rush: Today's Glade, or back to a new field every round).

signal play_again
signal return_to_glenn
signal switch_pressed

const RANK_COLORS := [Color("#c99a2e"), Color("#9a9a9a"), Color("#b0703a")] # Gold, silver, bronze.

var is_showing := false
var _board := ""
var _pending := -1.0 # A score waiting for its name, or -1.
var _just_saved := -1 # The row just written, to light it up.
var _card: PanelContainer
var _title: Label
var _result: Label
var _rows: VBoxContainer
var _name: LineEdit
var _again: Button
var _switch: Button
var _reset: Button
var _reset_armed := false


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.theme = preload("res://ui/theme.tres")
	add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(560, 0)
	center.add_child(_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_card.add_child(column)
	_title = _label("", "Title")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_result = _label("", "Notice")
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_result)
	column.add_child(HSeparator.new())
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 2)
	column.add_child(_rows)
	column.add_child(HSeparator.new())
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	column.add_child(buttons)
	_again = Button.new()
	_again.text = "Play again"
	_again.pressed.connect(func() -> void:
		Sound.play_pop()
		play_again.emit())
	buttons.add_child(_again)
	_switch = Button.new()
	_switch.pressed.connect(func() -> void:
		Sound.play_pop()
		switch_pressed.emit())
	buttons.add_child(_switch)
	var back := Button.new()
	back.text = "Return to the Glenn"
	back.pressed.connect(func() -> void:
		Sound.play_pop()
		return_to_glenn.emit())
	buttons.add_child(back)
	_reset = Button.new()
	_reset.text = "Reset leaderboard"
	_reset.flat = true
	_reset.theme_type_variation = "Soft"
	_reset.add_theme_font_size_override("font_size", 15)
	_reset.size_flags_horizontal = Control.SIZE_SHRINK_END
	_reset.pressed.connect(_on_reset)
	column.add_child(_reset)
	visible = false


# Show the board at the end of a round. `score` is the time, or -1 if the round ended without one.
# `story` is said first: how the round went. `switch_text`, if any, labels the switch-fields button.
func show_board(board: String, score: float, story := "", switch_text := "") -> void:
	_board = board
	_switch.text = switch_text
	_switch.visible = switch_text != ""
	_pending = -1.0
	_just_saved = -1
	var message := ""
	if score <= 0.0:
		message = Scores.words(board, "no_score")
	elif Scores.qualifies(board, score):
		_pending = score
		var best := Scores.best(board)
		var key := "new_best" if best.is_empty() or Scores.is_better(board, score, best.score) else "top_ten"
		message = Scores.words(board, key) % Scores.format(board, score)
	else:
		message = Scores.words(board, "not_top_ten") % Scores.format(board, score)
	_title.text = Scores.BOARDS[board].title
	_result.text = (story + " " + message).strip_edges()
	_end_reset_question()
	_render()
	visible = true
	is_showing = true
	_card.pivot_offset = _card.size / 2.0
	_card.scale = Vector2(0.94, 0.94)
	_card.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "scale", Vector2.ONE, 0.25)
	tween.tween_property(_card, "modulate:a", 1.0, 0.2)
	(_name if _name else _again).grab_focus.call_deferred()


# Put the board away. A score still waiting for its name is saved with whatever's been typed.
func hide_board() -> void:
	if _pending > 0.0:
		_save_pending()
	visible = false
	is_showing = false


func _render() -> void:
	for child in _rows.get_children():
		child.queue_free()
	_name = null
	var list: Array = Scores.entries(_board).duplicate()
	var pending_rank := -1
	if _pending > 0.0:
		pending_rank = Scores.rank_for(_board, _pending)
		list.insert(pending_rank, {"name": "", "score": _pending})
	for i in Scores.SIZE:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var rank := _label("%d" % (i + 1), "RowLabel")
		rank.custom_minimum_size.x = 34
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if i < RANK_COLORS.size():
			rank.add_theme_color_override("font_color", RANK_COLORS[i])
		row.add_child(rank)
		var panel := PanelContainer.new()
		panel.theme_type_variation = "ChosenRow" if i == pending_rank or i == _just_saved else "RowPanel"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		panel.add_child(line)
		row.add_child(panel)
		if i >= list.size():
			var empty := _label("· · ·", "Soft")
			empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(empty)
			line.add_child(_label("–", "Soft"))
		elif i == pending_rank:
			_name = LineEdit.new()
			_name.max_length = Scores.NAME_LENGTH
			_name.placeholder_text = "Your name"
			_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_name.text_submitted.connect(func(_text: String) -> void: _save_pending())
			line.add_child(_name)
			var save := Button.new()
			save.text = "Save"
			save.pressed.connect(_save_pending)
			line.add_child(save)
			line.add_child(_label(Scores.format(_board, _pending), "RowLabel"))
		else:
			var name := _label(list[i].name, "RowLabel")
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(name)
			line.add_child(_label(Scores.format(_board, list[i].score), "RowLabel"))
		_rows.add_child(row)


func _save_pending() -> void:
	if _pending <= 0.0:
		return
	var name := _name.text if _name else ""
	_just_saved = Scores.add(_board, name, _pending)
	_pending = -1.0
	Sound.play_chime()
	_result.text = Scores.words(_board, "saved") % Scores.entries(_board)[_just_saved].name
	_render()
	_again.grab_focus.call_deferred()


# The reset link asks once more, in case of a stray click.
func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset.text = "Really? Click again to reset"
		get_tree().create_timer(3.0, true, false, true).timeout.connect(_end_reset_question)
		return
	_end_reset_question()
	Scores.reset(_board)
	_just_saved = -1
	_render()


func _end_reset_question() -> void:
	_reset_armed = false
	_reset.text = "Reset leaderboard"


func _label(text: String, variation: String) -> Label:
	var made := Label.new()
	made.text = text
	made.theme_type_variation = variation
	return made
