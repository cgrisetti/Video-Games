extends CanvasLayer

# What's on screen during play: the prompt at an opening ("F  Berry Rush"), a game's card, short
# messages, the area's name as you arrive, and the controls along the bottom.

const TOAST_SECONDS := 1.8
const BANNER_SECONDS := 2.6

var _prompt: PanelContainer
var _prompt_key: Label
var _prompt_text: Label
var _card: PanelContainer
var _card_title: Label
var _card_blurb: Label
var _card_play: Label
var _card_close: Label
var _toast: PanelContainer
var _toast_text: Label
var _banner: VBoxContainer
var _banner_title: Label
var _banner_subtitle: Label
var _controls: Label
var _tweens := {}


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = preload("res://ui/theme.tres")
	add_child(root)

	# The area's name, big, near the top as you arrive.
	_banner = VBoxContainer.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.position.y = 90
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner_title = _label("", "BannerTitle")
	_banner_subtitle = _label("", "BannerSubtitle")
	_banner.add_child(_banner_title)
	_banner.add_child(_banner_subtitle)
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	# The prompt at an opening, near the bottom.
	_prompt = _pill()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position.y -= 130
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	_prompt_key = _label("F", "KeyCap")
	_prompt_text = _label("", "HudLabel")
	line.add_child(_prompt_key)
	line.add_child(_prompt_text)
	_prompt.add_child(line)
	_prompt.visible = false
	root.add_child(_prompt)

	# A game's card: its name, what to do, and "press again to play".
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(520, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_card_title = _label("", "Title")
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_blurb = _label("", "Label")
	_card_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var best := _label("This game is on its way to the new Lanternwood.", "Soft")
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 30)
	_card_play = _label("F", "KeyCap")
	_card_close = _label("Esc", "KeyCap")
	for pair in [[_card_play, "Play"], [_card_close, "Not now"]]:
		var hint := HBoxContainer.new()
		hint.add_theme_constant_override("separation", 8)
		hint.add_child(pair[0])
		hint.add_child(_label(pair[1], "Label"))
		buttons.add_child(hint)
	for child in [_card_title, _card_blurb, best, HSeparator.new(), buttons]:
		column.add_child(child)
	_card.add_child(column)
	_card.visible = false
	center.add_child(_card)

	# Short messages, near the top.
	_toast = _pill()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y += 40
	_toast_text = _label("", "HudLabel")
	_toast.add_child(_toast_text)
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	# The controls, along the bottom.
	_controls = _label("", "HudLabel")
	_controls.add_theme_font_size_override("font_size", 18)
	_controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_controls.position += Vector2(24, -44)
	_controls.modulate.a = 0.85
	root.add_child(_controls)
	_show_controls()
	InputHints.device_changed.connect(func(_c: bool) -> void:
		_show_controls()
		_prompt_key.text = InputHints.glyph("interact"))


func show_prompt(text: String) -> void:
	_prompt_key.text = InputHints.glyph("interact")
	_prompt_text.text = text
	if not _prompt.visible:
		_prompt.visible = true
		_fade(_prompt, 1.0, 0.15)


func hide_prompt() -> void:
	_prompt.visible = false


func show_card(game: Dictionary) -> void:
	_card_title.text = game.title
	_card_blurb.text = game.blurb
	_card_play.text = InputHints.glyph("interact")
	_card_close.text = InputHints.glyph("back")
	_card.visible = true
	_card.pivot_offset = _card.size / 2.0
	_card.scale = Vector3.ONE.x * Vector2(0.94, 0.94)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "scale", Vector2.ONE, 0.2)


func hide_card() -> void:
	_card.visible = false


func show_toast(text: String) -> void:
	_toast_text.text = text
	var tween := _fade(_toast, 1.0, 0.15)
	tween.tween_interval(TOAST_SECONDS)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


func show_banner(title: String, subtitle: String) -> void:
	_banner_title.text = title
	_banner_subtitle.text = subtitle
	var tween := _fade(_banner, 1.0, 0.8)
	tween.tween_interval(BANNER_SECONDS)
	tween.tween_property(_banner, "modulate:a", 0.0, 1.2)


func _show_controls() -> void:
	if InputHints.using_controller:
		_controls.text = "Left stick  move     ✕  jump     □  swing     Right stick  camera     Options  pause"
	else:
		_controls.text = "WASD  move     Space  jump     F  swing     Q E  camera     Esc  pause"


func _fade(node: CanvasItem, to: float, seconds: float) -> Tween:
	if _tweens.has(node) and _tweens[node].is_valid():
		_tweens[node].kill()
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", to, seconds)
	_tweens[node] = tween
	return tween


func _pill() -> PanelContainer:
	var made := PanelContainer.new()
	made.theme_type_variation = "HudPill"
	made.grow_horizontal = Control.GROW_DIRECTION_BOTH
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return made


func _label(text: String, variation: String) -> Label:
	var made := Label.new()
	made.text = text
	made.theme_type_variation = variation
	made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return made
