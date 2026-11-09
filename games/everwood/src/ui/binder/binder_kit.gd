## The Grimoire Binder's building blocks in the living storybook atelier look
## (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §3, the Menu Wireframes):
## pages, panels, small-caps kickers, chips, a Marks bar, stat grids and the
## click helper. The Gear & Weapon page, the card bench and the Seal Press
## build every box from these, so the three read as one book.
class_name BinderKit
extends RefCounted

const KICKER_SIZE: int = 12
const NAME_SIZE: int = 22
const BIG_SIZE: int = 30
const MARKS_BAR_HEIGHT: float = 8.0


## A box placed at a spot on the 1600 x 900 sheet (the wireframes' own coordinates).
static func place(parent: Control, child: Control, at: Vector2, width: float, height: float = 0.0) -> Control:
	parent.add_child(child)
	child.position = at
	child.custom_minimum_size = Vector2(width, height)
	child.size = Vector2(width, maxf(height, child.get_combined_minimum_size().y))
	return child


## A panel round some content: a page (raised or not), or a row (chosen or not).
static func panel(style: StyleBoxFlat) -> PanelContainer:
	var box: PanelContainer = PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(&"panel", style)
	return box


## A row box: gilt-edged and warm when chosen, a thin line when not, dim when it can't be used.
static func row_box(chosen: bool, shut: bool = false, margin: float = 12.0) -> PanelContainer:
	var style: StyleBoxFlat = AtelierTheme.row_style(chosen)
	style.set_content_margin_all(margin)
	if shut and not chosen:
		style.bg_color = AtelierTheme.ROW.darkened(0.25)
		style.border_color = AtelierTheme.LINE.darkened(0.3)
	return panel(style)


static func column(separation: int = 6) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


static func line(separation: int = 8) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override(&"separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


## Words in the book's ink; with a width they wrap.
static func text(words: String, size: int = AtelierTheme.BODY_SIZE, color: Color = AtelierTheme.INK, wrap_width: float = 0.0) -> Label:
	var made: Label = AtelierTheme.label(words, size, color)
	if wrap_width > 0.0:
		made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		made.custom_minimum_size = Vector2(wrap_width, 0.0)
	return made


## The small gilt heading over a box ("WEAPON · SWORD & BUCKLER").
static func kicker(words: String, color: Color = AtelierTheme.GILT) -> Label:
	return text(words.to_upper(), KICKER_SIZE, color)


## A small rounded chip ("in use", "Lv 13", "fits") in a colour.
static func chip(words: String, edge: Color, ink: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var box: PanelContainer = panel(AtelierTheme.chip_style(edge))
	box.add_child(text(words, AtelierTheme.SMALL_SIZE, ink if ink.a > 0.0 else edge))
	return box


## A chip in a Sign's colour, named for the Sign ("Iron-Root").
static func sign_chip(scribe_sign: int) -> PanelContainer:
	var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(scribe_sign)
	return chip(seal.display_name if seal != null and scribe_sign != ScribeSignResource.Sign.NONE else "no Sign",
		AtelierTheme.sign_fill(scribe_sign), AtelierTheme.sign_text(scribe_sign))


## The Ink-Binding Marks bar: how far a card is toward its next press.
static func marks_bar(value: int, needed: int) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = maxf(1.0, float(needed))
	bar.value = float(mini(value, maxi(needed, 1)))
	bar.custom_minimum_size = Vector2(0.0, MARKS_BAR_HEIGHT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = AtelierTheme.INK_DROP if value < needed else AtelierTheme.GOOD
	fill.set_corner_radius_all(4)
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = Color(0.06, 0.05, 0.04, 0.95)
	back.border_color = AtelierTheme.LINE
	back.set_border_width_all(1)
	back.set_corner_radius_all(4)
	bar.add_theme_stylebox_override(&"fill", fill)
	bar.add_theme_stylebox_override(&"background", back)
	return bar


## Two columns of name and value ("Armor Guard  32%"), the value in gold.
static func stat_grid(pairs: Array[PackedStringArray], width: float) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pair: PackedStringArray in pairs:
		var named: Label = text(pair[0], AtelierTheme.BODY_SIZE - 1, AtelierTheme.INK_MUTED)
		named.custom_minimum_size = Vector2(width * 0.6, 0.0)
		grid.add_child(named)
		var value: Label = text(pair[1], AtelierTheme.BODY_SIZE, AtelierTheme.GOLD)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(value)
	return grid


## A number in a gilt box with its caption under it (the Threat sum's "12 / CHARACTER LV").
static func number_box(number: String, caption: String, accent: Color = AtelierTheme.GILT) -> PanelContainer:
	var style: StyleBoxFlat = AtelierTheme.chip_style(accent, AtelierTheme.PAGE_RAISED)
	style.set_corner_radius_all(AtelierTheme.RADIUS)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	var box: PanelContainer = panel(style)
	var stack: VBoxContainer = column(0)
	box.add_child(stack)
	var big: Label = text(number, BIG_SIZE, AtelierTheme.INK)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(big)
	var under: Label = text(caption.to_upper(), 10, accent)
	under.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(under)
	return box


## A left click on a control calls `then`.
static func on_click(control: Control, then: Callable) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.gui_input.connect(BinderKit._clicked.bind(then))


static func _clicked(event: InputEvent, then: Callable) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		then.call()


## Frees a container's children now (a page rebuilding its boxes).
static func clear(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


## The role's word on screen (25 GDD R7): Defender, Striker or Mender.
static func role_word(role: int) -> String:
	match role:
		ClassLoadoutResource.Role.TANK:
			return "Defender"
		ClassLoadoutResource.Role.HEALER:
			return "Mender"
	return "Striker"
