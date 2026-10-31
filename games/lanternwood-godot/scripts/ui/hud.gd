extends CanvasLayer

# What's on screen during play: the prompt at an opening ("F  Berry Rush"), a game's card, short
# messages, the area's name as you arrive, and the controls along the bottom. In a game, the pills
# at the top left: raspberries picked and the clock in Berry Rush, and a hint when there is one.

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
var _card_best: Label
var _pills: VBoxContainer
var _berry_pill: PanelContainer
var _berry_label: Label
var _timer_label: Label
var _medals: RichTextLabel
var _medal_pill: PanelContainer
var _split: Label
const MEDAL_COLORS := {"gold": Color("#f2c14e"), "silver": Color("#d6dbe2"), "bronze": Color("#d9935a")}
var _hint: PanelContainer
var _hint_label: Label
var _area := "glen"
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
	var best := _label("", "Soft")
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_best = best
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

	# In a game: pills at the top left.
	_pills = VBoxContainer.new()
	_pills.position = Vector2(24, 22)
	_pills.add_theme_constant_override("separation", 10)
	root.add_child(_pills)
	_berry_pill = _pill()
	_berry_label = _icon_pill(_berry_pill, _berry_icon())
	var berry_row := HBoxContainer.new()
	berry_row.add_theme_constant_override("separation", 12)
	berry_row.add_child(_berry_pill)
	var split_pill := _pill() # "−1.4s" against gold pace, after each berry.
	split_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_split = _label("", "HudLabel")
	split_pill.add_child(_split)
	split_pill.modulate.a = 0.0
	berry_row.add_child(split_pill)
	_pills.add_child(berry_row)
	var timer_pill := _pill()
	_timer_label = _icon_pill(timer_pill, _clock_icon())
	_pills.add_child(timer_pill)
	_medal_pill = _pill()
	_medals = RichTextLabel.new()
	_medals.bbcode_enabled = true
	_medals.fit_content = true
	_medals.autowrap_mode = TextServer.AUTOWRAP_OFF
	_medals.scroll_active = false
	_medals.add_theme_font_override("normal_font", Art.book_font())
	_medals.add_theme_font_size_override("normal_font_size", 18)
	_medals.add_theme_color_override("default_color", Color("#f3ead6"))
	_medal_pill.add_child(_medals)
	_pills.add_child(_medal_pill)
	for pill: Control in [_berry_pill, timer_pill, _medal_pill]:
		pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN # Each pill as wide as its words.
	_hint = _pill()
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_hint_label = _label("", "HudLabel")
	_hint.add_child(_hint_label)
	_hint.visible = false
	_pills.add_child(_hint)
	_pills.visible = false

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


func show_card(game: Dictionary, best := "This game is on its way to the new Lanternwood.") -> void:
	_card_title.text = game.title
	_card_blurb.text = game.blurb
	_card_best.text = best
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


# The area's name, big, near the top. With `hold`, it stays up until set_banner_subtitle() or hide_banner().
func show_banner(title: String, subtitle: String, hold := false) -> void:
	_banner_title.text = title
	_banner_subtitle.text = subtitle
	var tween := _fade(_banner, 1.0, 0.8 if not hold else 0.25)
	if not hold:
		tween.tween_interval(BANNER_SECONDS)
		tween.tween_property(_banner, "modulate:a", 0.0, 1.2)


# Change the banner's second line ("Ready…" to "Go!"), then let it fade after `seconds`.
func set_banner_subtitle(subtitle: String, seconds: float) -> void:
	_banner_subtitle.text = subtitle
	_banner_subtitle.pivot_offset = _banner_subtitle.size / 2.0
	_banner_subtitle.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(_banner_subtitle, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	var tween := _fade(_banner, 1.0, 0.05)
	tween.tween_interval(seconds)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


func hide_banner() -> void:
	_fade(_banner, 0.0, 0.2)


# Which area we're in, for the pills and the controls along the bottom.
func set_area(area: String) -> void:
	_area = area
	_pills.visible = area == "berry-rush"
	_hint.visible = false
	hide_prompt()
	hide_card()
	_show_controls()


func set_berries(picked: int, total: int, golden: bool) -> void:
	_berry_label.text = "%d / %d" % [picked, total]
	_berry_label.add_theme_color_override("font_color", Color("#ffd55a") if golden else Color("#ffc2d4"))


# A little bump on the berry counter, when one is picked.
func bump_berries() -> void:
	_berry_pill.pivot_offset = _berry_pill.size / 2.0
	_berry_pill.scale = Vector2(1.18, 1.18)
	create_tween().tween_property(_berry_pill, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# The clock, in the colour of the medal you're still on track for.
func set_time(seconds: float, medal := "") -> void:
	_timer_label.text = Scores.format_time(seconds)
	if MEDAL_COLORS.has(medal):
		_timer_label.add_theme_color_override("font_color", MEDAL_COLORS[medal])
	else:
		_timer_label.remove_theme_color_override("font_color")


# This field's medal times, under the clock.
# The medal times for this field. `tag` goes first (Today's Glade).
func show_medals(gold: float, silver: float, bronze: float, tag := "") -> void:
	_medals.text = ("[color=#ffd55a]%s[/color]    " % tag if tag != "" else "") + "[color=#%s]●[/color] %s    [color=#%s]●[/color] %s    [color=#%s]●[/color] %s" % [
		MEDAL_COLORS.gold.to_html(false), Scores.format_time(gold), MEDAL_COLORS.silver.to_html(false), Scores.format_time(silver), MEDAL_COLORS.bronze.to_html(false), Scores.format_time(bronze)]


# How far ahead of gold pace (negative) or behind (positive), beside the berry counter.
func show_split(seconds: float) -> void:
	var pill: Control = _split.get_parent()
	if absf(seconds) < 0.05:
		_split.text = "±0.0s"
		_split.add_theme_color_override("font_color", Color("#f3ead6"))
	else:
		_split.text = ("−%.1fs" % -seconds) if seconds < 0.0 else ("+%.1fs" % seconds)
		_split.add_theme_color_override("font_color", Color("#9be38a") if seconds < 0.0 else Color("#ff9a8a"))
	var tween := _fade(pill, 1.0, 0.1)
	tween.tween_interval(1.6)
	tween.tween_property(pill, "modulate:a", 0.0, 0.5)


func show_hint(text: String) -> void:
	_hint_label.text = text
	if not _hint.visible:
		_hint.visible = true
		_hint.modulate.a = 0.0
		_fade(_hint, 1.0, 0.3)


func hide_hint() -> void:
	_hint.visible = false


func _show_controls() -> void:
	var in_game := _area != "glen" # In a game, R restarts the round instead of waving.
	if InputHints.using_controller:
		_controls.text = "Left stick  move     ✕  jump     □  swing     %sRight stick  camera     Options  pause" % ("" if in_game else "△  wave     ")
	else:
		_controls.text = "WASD  move     Space  jump     F  swing     %s     Q E  camera     Esc  pause" % ("R  restart" if in_game else "R  wave")


# A pill with a little picture before its words. Returns the words, to change later.
func _icon_pill(pill: PanelContainer, icon: Texture2D) -> Label:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.custom_minimum_size = Vector2(26, 26)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	line.add_child(picture)
	var words := _label("", "HudLabel")
	words.custom_minimum_size.x = 86
	line.add_child(words)
	pill.add_child(line)
	return words


# A little raspberry: a cluster of round drupelets under a green cap.
static func _berry_icon() -> ImageTexture:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dots := [Vector2(32, 26), Vector2(22, 30), Vector2(42, 30), Vector2(27, 39), Vector2(37, 39), Vector2(32, 48), Vector2(32, 34)]
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var color := Color(0, 0, 0, 0)
			for dot: Vector2 in dots:
				var d := p.distance_to(dot)
				if d < 9.0:
					var light := 1.0 - p.distance_to(dot + Vector2(-3, -3)) / 12.0
					color = Color("#c8325f").lerp(Color("#f07fa0"), clampf(light, 0.0, 1.0) * 0.6)
			var leaf := absf(p.x - 32.0) < 13.0 - (p.y - 14.0) * 1.4 and p.y > 12.0 and p.y < 22.0
			if leaf and absf(fmod(p.x - 32.0 + 40.0, 8.0) - 4.0) < 3.0:
				color = Color("#4e8f36")
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


# A little clock: a round face with two hands and a button on top.
static func _clock_icon() -> ImageTexture:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var ink := Color("#4a3826")
	var middle := Vector2(32, 35)
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(middle)
			var color := Color(0, 0, 0, 0)
			if absf(d - 21.0) < 3.0:
				color = ink
			elif d < 18.0:
				color = Color("#fbf4df")
			var to := p - middle
			if absf(to.x) < 2.2 and to.y < 0.0 and to.y > -14.0:
				color = ink # The minute hand, pointing up.
			if absf(to.y) < 2.2 and to.x > 0.0 and to.x < 10.0:
				color = ink # The hour hand, pointing right.
			if absf(p.x - 32.0) < 6.0 and p.y > 6.0 and p.y < 11.0:
				color = ink # The button on top.
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


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
