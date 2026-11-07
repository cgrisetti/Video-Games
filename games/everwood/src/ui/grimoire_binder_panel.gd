## The Grimoire Binder (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §6, rebuilt to the
## Menu Wireframes of 25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md), opened
## out of combat with a tap of Tab / View on the player's own screen. It is one
## 1600 x 900 sheet in the living storybook atelier look (AtelierTheme, BinderKit),
## scaled to the player's cell: a header, the tabs (Q / E or L1 / R1, or a click),
## a two-part tooltip box saying what's highlighted and what it does, the page,
## and the controls along the foot.
##
##   [1. Gear & Weapon]           BinderGearPage: the hero, Steward Threat as a
##                                sum, the kit's totals and Seal wards; the live
##                                hero turning in a lit preview; the weapon,
##                                offhand and mantle, each with its Seal and
##                                Marks. Light (at a rest point) opens the Seal Press
##   [2. Quick Magic-Ink Cards]   BinderCardBench, where it opens: the Cross at
##                                2.2x, your seven-slot hand and Ink-Well, the
##                                chosen diamond's three layers (Place-Card,
##                                Ink card, Tuck), and the Ink Card Collection
##   [3. Combo Moves]             the directional forms the party knows, with
##                                their buttons, and the ones still to learn
##   [4. Seal Press]              BinderSealPressPage: the three Seals, the cards
##                                you can press, the highlighted card slot by
##                                slot with what you lose and gain, its
##                                Ink-Binding ladder, the preview and Press;
##                                presses only at a Hearth-Brazier or the Scribe Desk
##   [Atlas Map]                  the Wayfarer's Atlas (18 GDD §7.3) in place of
##                                the sheet; dodge there turns back
##
## On the cards tab: left / right picks the diamond (L, R, L+R), up / down the
## layer, light opens the collection; there up / down chooses, left / right
## turns the filter, light slots it and dodge goes back. The mouse works too:
## click a diamond, a layer, a filter or a card. A change the kit's rules allow
## is equipped at once through the host; otherwise the Binder says why.
##
## The preview's lighting is its own: the camera carries a brighter copy of the
## sky and fog with the far world softly blurred, and a warm key light and a
## cool rim light reach only the hero (light cull layer 13, which the hero's
## meshes wear while the Gear tab or the Seal Press shows).
class_name GrimoireBinderPanel
extends Control

signal closed

## LEAVES, DIAMONDS and PLACES keep their old values (the checks name them); TUCKS is the
## collection open on the Tuck layer.
enum Column { LEAVES, DIAMONDS, PLACES, TUCKS }
enum Tab { GEAR, CARDS, COMBOS, SEALS, ATLAS }
## The card bench's three layers, top to bottom.
enum Layer { PLACE, CARD, TUCK }
## The bench's last row, under the layers: "How does a diamond work?" (DiamondGuide).
const GUIDE_ROW: int = 3
const TAB_NAMES: Array[String] = ["1. Gear & Weapon", "2. Quick Magic-Ink Cards", "3. Combo Moves", "4. Seal Press", "Atlas Map"]
## The letter in the header's diamond, by tab (the wireframes' C, E, D...).
const TAB_GLYPHS: Array[String] = ["C", "E", "F", "D", "M"]
## What each tab is for, in the tooltip box and as the tab's mouse tooltip.
const TAB_TOOLTIPS: Array[String] = [
	"Your hero, your weapon and what you wear. Seals change in the Seal Press at a Hearth-Brazier or the Scribe Desk; weapon and armour at the Scribe Desk.",
	"Pick a diamond, then its Place-Card, its card and the one Tuck. Changes go to the host as you make them.",
	"Button patterns your hero has learned. Play one in a row and its last move hits harder.",
	"Press a Seal onto your weapon, offhand and mantle. One card does what its piece is for: hits on the weapon, wards on the offhand, footing on the mantle. Change them at a Hearth-Brazier or the Scribe Desk.",
	"The Wayfarer's Atlas: where you are, and where to go next.",
]
## The line under the header's title, by tab (the wireframes' own words).
const TAB_SUBTITLES: Array[String] = [
	"Tab 1 shows the hero. Seals change at a Hearth-Brazier or the Scribe Desk; weapon and armour at the Scribe Desk.",
	"Pick a diamond, then pick a card for it. Your hero uses it in every fight!",
	"Button patterns your hero has learned. Play one in a row and its last move hits harder.",
	"From Binder tab 1 at a Hearth-Brazier or the Scribe Desk. One card does a different job in each slot.",
	"Where you are, and where to go next.",
]
## A Place-Card's "when": it rides with the diamond's Ink Card.
const PLACE_WHEN: String = "It rides with the Ink Card in this diamond: on the trail (INK READY) and in every cast in a fight."
## A Tuck's "when": it rides under the card above it.
const TUCK_WHEN: String = "It rides under the card above it every time that card is cast, and it's never used up."
## The Gear & Weapon tab's rows.
enum GearRow { WEAPON, OFF_HAND, ARMOR, CALLING }
## The Seal Press's slot shapes: a pressed card, an open empty slot, a slot still locked.
const SEAL_PRESSED: String = "◆"
const SEAL_EMPTY: String = "◇"
const SEAL_LOCKED: String = "▢"
## The Seal Press's slots: the three Seals (PlayerLoadoutResource.HandSlot's first three).
const SEAL_ROWS: Array[int] = [PlayerLoadoutResource.HandSlot.WEAPON_SEAL, PlayerLoadoutResource.HandSlot.OFFHAND_SEAL,
	PlayerLoadoutResource.HandSlot.MANTLE_SEAL]
## How near a Hearth-Brazier or the Scribe Desk the Seal Press opens (metres).
const PRESS_REACH: float = 7.0
const PRESS_SHUT: String = "Seals change at a Hearth-Brazier or the Scribe Desk"
## The groups the rest points join (HearthCampfire, ScribeDesk).
const BRAZIER_GROUP: StringName = &"hearth_braziers"
const DESK_GROUP: StringName = &"scribe_desks"
## What each slot of the hand does (PlayerLoadoutResource.HandSlot order); %s is the trigger's key.
const SEAL_SLOT_TIPS: Array[String] = [
	"Your weapon's seal: its bonus rides every hit you land.",
	"Your off-hand's seal: it wards off blows of its Sign, and their stun.",
	"Your mantle's seal: a steadier stance or a quicker stride.",
	"Your %s card: land a hit, then press %s in the flash to pull it from your pocket. Your strikes carry it.",
	"Tucked under your %s card: it makes that pull stronger.",
	"Your %s card: land a hit, then press %s in the flash to pull it from your pocket. Your strikes carry it.",
	"Tucked under your %s card: it makes that pull stronger.",
]

## The sheet the wireframes are drawn on, scaled to fit the player's cell.
const SHEET_SIZE: Vector2 = Vector2(1600.0, 900.0)
const REFERENCE_SIZE: Vector2 = SHEET_SIZE
const MIN_FIT: float = 0.3
const PAGE_WIDTH: float = 330.0
const TITLE_SIZE: int = 30
const FONT_SIZE: int = 15
const SMALL_FONT_SIZE: int = 12
const TOOLTIP_FONT_SIZE: int = 14
## The tooltip box: across the sheet under the tabs, its heading column this wide.
const TOOLTIP_RECT: Rect2 = Rect2(40.0, 142.0, 1520.0, 76.0)
const TOOLTIP_HEAD_WIDTH: float = 250.0
## The living storybook atelier look (AtelierTheme, 25 GDD §3).
const BACKDROP: Color = Color(0.071, 0.051, 0.035, 0.94)
const PAGE_EDGE: Color = AtelierTheme.GILT
const SELECTED_COLOR: Color = AtelierTheme.GOLD
const ROW_COLOR: Color = AtelierTheme.INK
const DIM_COLOR: Color = AtelierTheme.INK_DIM
const PROBLEM_COLOR: Color = AtelierTheme.BAD
const HARMONY_COLOR: Color = Color(1.0, 0.85, 0.35)
const NOTE_TIME: float = 2.5
## The diamonds in the order left / right steps through them on the card bench: L, R, L+R.
const BENCH_SOCKETS: Array[int] = [ScribeCardResource.DioramaSocket.GUARD, ScribeCardResource.DioramaSocket.SKILL,
	ScribeCardResource.DioramaSocket.ULT]
## The old middle column's rows (kept for the checks that name a diamond by row): the three diamonds, then the Collection.
const DIAMOND_ROWS: Array[int] = [ScribeCardResource.DioramaSocket.ULT, ScribeCardResource.DioramaSocket.GUARD,
	ScribeCardResource.DioramaSocket.SKILL, -1]
## The live preview: its window, the camera's orbit round the hero, and its lights.
const PREVIEW_SIZE: Vector2i = Vector2i(344, 404)
const PREVIEW_LAYER: int = 13
const PREVIEW_DISTANCE: float = 3.2
const PREVIEW_HEIGHT: float = 1.3
const PREVIEW_LOOK_HEIGHT: float = 0.95
const PREVIEW_FOV: float = 36.0
## Radians a second the camera circles the hero.
const PREVIEW_ORBIT_SPEED: float = 0.35
const KEY_LIGHT_COLOR: Color = Color(1.0, 0.88, 0.7)
const KEY_LIGHT_ENERGY: float = 3.0
const RIM_LIGHT_COLOR: Color = Color(0.66, 0.8, 1.0)
const RIM_LIGHT_ENERGY: float = 2.2
## How much brighter and clearer the preview's copy of the sky is.
const PREVIEW_AMBIENT_BOOST: float = 1.35
const PREVIEW_EXPOSURE_BOOST: float = 1.1
const PREVIEW_FOG_SCALE: float = 0.25

var actor: ActorBase
var widget: CrossGrimoireDiamondWidget
## DIAMONDS while the bench picks a diamond and a layer; LEAVES, PLACES or TUCKS while the collection is open on that layer.
var column: int = Column.DIAMONDS
var leaf_row: int = 0
var place_row: int = 0
var tuck_row: int = 0
var diamond_row: int = 2
## The card bench's highlighted layer (Layer).
var bench_layer: int = Layer.CARD
var gear_row: int = GearRow.WEAPON
var combo_row: int = 0
## The Seal Press's chosen slot (PlayerLoadoutResource.HandSlot), and the highlighted card in its list.
var seal_row: int = PlayerLoadoutResource.HandSlot.WEAPON_SEAL
var press_row: int = 0
var folio_open: bool = false
var tab: int = Tab.CARDS
var atlas: WorldMapPanel
## The live preview on the Gear & Weapon tab and the Seal Press.
var preview_viewport: SubViewport
var preview_camera: Camera3D
var key_light: SpotLight3D
var rim_light: OmniLight3D
var _tab_labels: Array[Label] = []
var _tab_panels: Array[PanelContainer] = []
## The tab the Atlas turns back to.
var _page_tab: int = Tab.CARDS
var _preview_angle: float = 0.0
var _lit: Array[GeometryInstance3D] = []

## The sheet everything is drawn on; _root is the part the Atlas hides (the tooltip and the pages).
var _sheet: Control
var _root: Control
var _tabs: HBoxContainer
var _glyph: Label
var _title: Label
var _subtitle: Label
var _tooltip_head: Label
var _tooltip: Label
var _pages: Array[Control] = []
var _gear_page: BinderGearPage
var _bench: BinderCardBench
var _press_page: BinderSealPressPage
var _preview_frame: Control
## The name labels the pages draw (the checks read them): the gear pieces, the Seals, the combo forms.
var _gear_rows: Array[Label] = []
var _seal_rows: Array[Label] = []
var _combo_rows: Array[Label] = []
var _note: Label
var _hint: Label
var _note_left: float = 0.0
## The picture guide to a diamond while it's open, and whether it has shown itself this session.
var _guide: DiamondGuide
static var guide_seen: bool = false


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "GrimoireBinderPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_sheet = Control.new()
	_sheet.name = "Sheet"
	_sheet.size = SHEET_SIZE
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet)
	_build_header()
	_root = Control.new()
	_root.name = "Spread"
	_root.size = SHEET_SIZE
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(_root)
	_root.add_child(_build_tooltip())
	widget = CrossGrimoireDiamondWidget.new()
	widget.name = "Diamonds"
	widget.follow = actor
	widget.set_presentation_mode(CrossGrimoireDiamondWidget.BINDER_SCALE, true)
	widget.grow_from(CrossGrimoireDiamondWidget.HUD_SCALE)
	widget.socket_picked.connect(_on_socket_picked)
	_preview_frame = _build_preview()
	_gear_page = BinderGearPage.new()
	_gear_page.build(self)
	_bench = BinderCardBench.new()
	_bench.build(self)
	var combos: Control = _build_combo_page()
	_press_page = BinderSealPressPage.new()
	_press_page.build(self)
	_pages = [_gear_page, _bench, combos, _press_page]
	for page: Control in _pages:
		_root.add_child(page)
	_note = AtelierTheme.label("", FONT_SIZE + 1, PROBLEM_COLOR)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.position = Vector2(40.0, 826.0)
	_note.size = Vector2(1520.0, 24.0)
	_sheet.add_child(_note)
	_hint = AtelierTheme.label("", SMALL_FONT_SIZE + 1, AtelierTheme.INK_MUTED)
	_hint.position = Vector2(40.0, 858.0)
	_hint.size = Vector2(1520.0, 24.0)
	_sheet.add_child(_hint)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(_on_menu_input)
	if actor != null and actor.seal != null:
		actor.seal.loadout_changed.connect(_on_hand_changed)
	PartyProgress.current.progress_changed.connect(_refresh)
	NetworkManager.current.kit_refused.connect(_on_kit_refused)
	NetworkManager.current.seal_hand_refused.connect(_on_kit_refused)
	_show_page(Tab.CARDS)


## The header (the tab's letter in a gilt diamond, the title and what the tab is for) and the tabs under it.
func _build_header() -> void:
	var diamond: Panel = Panel.new()
	diamond.name = "Glyph"
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = AtelierTheme.PAGE
	style.border_color = AtelierTheme.GILT
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	diamond.add_theme_stylebox_override(&"panel", style)
	diamond.size = Vector2(52.0, 52.0)
	diamond.pivot_offset = Vector2(26.0, 26.0)
	diamond.rotation = PI * 0.25
	diamond.position = Vector2(46.0, 30.0)
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(diamond)
	_glyph = AtelierTheme.label("", 24, AtelierTheme.INK)
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.position = Vector2(46.0, 30.0)
	_glyph.size = Vector2(52.0, 52.0)
	_sheet.add_child(_glyph)
	_title = AtelierTheme.label("", TITLE_SIZE, AtelierTheme.INK)
	_title.position = Vector2(122.0, 24.0)
	_sheet.add_child(_title)
	_subtitle = AtelierTheme.label("", FONT_SIZE, AtelierTheme.INK_MUTED)
	_subtitle.position = Vector2(122.0, 66.0)
	_subtitle.size = Vector2(1430.0, 22.0)
	_subtitle.clip_text = true
	_sheet.add_child(_subtitle)
	_tabs = HBoxContainer.new()
	_tabs.name = "Tabs"
	_tabs.add_theme_constant_override(&"separation", 8)
	_tabs.position = Vector2(40.0, 100.0)
	_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(_tabs)
	for index: int in TAB_NAMES.size():
		var tab_panel: PanelContainer = PanelContainer.new()
		tab_panel.tooltip_text = TAB_TOOLTIPS[index]
		tab_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		tab_panel.gui_input.connect(_on_tab_clicked.bind(index))
		_tabs.add_child(tab_panel)
		_tab_panels.append(tab_panel)
		var tab_label: Label = AtelierTheme.label(TAB_NAMES[index], FONT_SIZE, AtelierTheme.INK_MUTED)
		tab_panel.add_child(tab_label)
		_tab_labels.append(tab_label)
	var keys: Label = AtelierTheme.label("Q / E or L1 / R1: tabs", SMALL_FONT_SIZE + 1, AtelierTheme.INK_MUTED)
	keys.name = "TabKeys"
	keys.position = Vector2(1360.0, 110.0)
	keys.size = Vector2(200.0, 20.0)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sheet.add_child(keys)


## The tooltip box under the tabs: what's highlighted on the left, what it does (and when, and whether it fits) on the right.
func _build_tooltip() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Tooltip"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = AtelierTheme.tooltip_style()
	style.corner_radius_top_left = 0
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override(&"panel", style)
	panel.position = TOOLTIP_RECT.position
	panel.custom_minimum_size = Vector2(TOOLTIP_RECT.size.x, 0.0)
	panel.size = TOOLTIP_RECT.size
	var split: HBoxContainer = HBoxContainer.new()
	split.add_theme_constant_override(&"separation", 18)
	split.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(split)
	_tooltip_head = AtelierTheme.label("", FONT_SIZE, AtelierTheme.GILT)
	_tooltip_head.custom_minimum_size = Vector2(TOOLTIP_HEAD_WIDTH, 0.0)
	_tooltip_head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	split.add_child(_tooltip_head)
	_tooltip = AtelierTheme.label("", TOOLTIP_FONT_SIZE, AtelierTheme.INK)
	_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip.custom_minimum_size = Vector2(TOOLTIP_RECT.size.x - TOOLTIP_HEAD_WIDTH - 60.0, 0.0)
	_tooltip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_tooltip)
	return panel


## The live preview: a window on the shared world, framed like a page.
func _build_preview() -> Control:
	var frame: PanelContainer = PanelContainer.new()
	frame.name = "Preview"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = AtelierTheme.PAGE
	style.border_color = PAGE_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4.0)
	frame.add_theme_stylebox_override(&"panel", style)
	var container: SubViewportContainer = SubViewportContainer.new()
	container.stretch = true
	container.custom_minimum_size = Vector2(PREVIEW_SIZE)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(container)
	preview_viewport = SubViewport.new()
	preview_viewport.name = "PreviewViewport"
	preview_viewport.size = PREVIEW_SIZE
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	if actor != null and actor.is_inside_tree():
		preview_viewport.world_3d = actor.get_world_3d()
	container.add_child(preview_viewport)
	preview_camera = Camera3D.new()
	preview_camera.name = "PreviewCamera"
	preview_camera.fov = PREVIEW_FOV
	preview_camera.set_cull_mask_value(WorldLabelStyle.STATION_LABEL_LAYER, false)
	var focus: CameraAttributesPractical = CameraAttributesPractical.new()
	focus.dof_blur_far_enabled = true
	focus.dof_blur_far_distance = PREVIEW_DISTANCE + 1.5
	focus.dof_blur_far_transition = 3.0
	focus.dof_blur_amount = 0.08
	preview_camera.attributes = focus
	preview_viewport.add_child(preview_camera)
	preview_camera.current = true
	key_light = SpotLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = KEY_LIGHT_COLOR
	key_light.light_energy = KEY_LIGHT_ENERGY
	key_light.spot_range = 7.0
	key_light.spot_angle = 28.0
	key_light.shadow_enabled = false
	key_light.light_cull_mask = 1 << (PREVIEW_LAYER - 1)
	key_light.visible = false
	preview_viewport.add_child(key_light)
	rim_light = OmniLight3D.new()
	rim_light.name = "RimLight"
	rim_light.light_color = RIM_LIGHT_COLOR
	rim_light.light_energy = RIM_LIGHT_ENERGY
	rim_light.omni_range = 3.2
	rim_light.shadow_enabled = false
	rim_light.light_cull_mask = 1 << (PREVIEW_LAYER - 1)
	rim_light.visible = false
	preview_viewport.add_child(rim_light)
	return frame


## Tab 3: one row per combo form, on a page under the tooltip.
func _build_combo_page() -> Control:
	var holder: Control = Control.new()
	holder.name = "CombosPage"
	holder.size = SHEET_SIZE
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var page: VBoxContainer = _page("Combo Moves: How You Flow")
	var panel: Control = page.get_parent() as Control
	panel.custom_minimum_size = Vector2(900.0, 0.0)
	panel.position = Vector2(350.0, 240.0)
	holder.add_child(panel)
	for form: ComboChainResource in ArsenalCatalog.current.combos():
		var row: Label = _label(FONT_SIZE + 2, ROW_COLOR)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_combo_clicked.bind(_combo_rows.size()))
		page.add_child(row)
		_combo_rows.append(row)
	return holder


func _exit_tree() -> void:
	_light_hero(false)
	var progress: PartyProgress = PartyProgress.current
	if progress != null and progress.progress_changed.is_connected(_refresh):
		progress.progress_changed.disconnect(_refresh)
	var network: NetworkManager = NetworkManager.current
	if network != null and network.kit_refused.is_connected(_on_kit_refused):
		network.kit_refused.disconnect(_on_kit_refused)
	if network != null and network.seal_hand_refused.is_connected(_on_kit_refused):
		network.seal_hand_refused.disconnect(_on_kit_refused)
	if is_instance_valid(actor) and actor.seal != null and actor.seal.loadout_changed.is_connected(_on_hand_changed):
		actor.seal.loadout_changed.disconnect(_on_hand_changed)
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
		if actor.input.menu_input.is_connected(_on_menu_input):
			actor.input.menu_input.disconnect(_on_menu_input)


func _process(delta: float) -> void:
	_note_left = maxf(0.0, _note_left - delta)
	_note.modulate.a = minf(1.0, _note_left)
	var fit: float = clampf(minf(size.x / SHEET_SIZE.x, size.y / SHEET_SIZE.y), MIN_FIT, 1.0)
	_sheet.scale = Vector2.ONE * fit
	_sheet.position = (size - SHEET_SIZE * fit) * 0.5
	if _shows_preview(tab):
		_preview_angle = wrapf(_preview_angle + PREVIEW_ORBIT_SPEED * delta, 0.0, TAU)
		_place_preview()


func close() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


## The diamond being worked on.
func selected_socket() -> int:
	return widget.selected_socket


func note_text() -> String:
	return _note.text if _note_left > 0.0 else ""


# --- What the pages offer ------------------------------------------------------

## The Action-Leaf copies (copy keys) the party owns that fit the chosen
## diamond, after an "un-inked" choice (&""): any leaf for L, the Signature or
## Ultimate cards for R and L+R.
func leaf_options() -> Array[StringName]:
	var options: Array[StringName] = [&""]
	var player_class: PlayerClassResource = _player_class()
	var socket: int = selected_socket()
	var slot: int = ScribeCardResource.SOCKET_GRIMOIRE_SLOTS[socket]
	for leaf: ScribeCardResource in ArsenalCatalog.current.action_leaves():
		var fits: bool = LoadoutComposer.fits_diorama(player_class, leaf) if slot < 0 else LoadoutComposer.fits_slot(player_class, leaf, slot)
		if fits:
			options.append_array(_owned_copies(leaf))
	return options


## The Place-Card copies the party owns, after "no Place-Card" (&"").
func place_options() -> Array[StringName]:
	var options: Array[StringName] = [&""]
	for place: ScribeCardResource in ArsenalCatalog.current.place_cards():
		options.append_array(_owned_copies(place))
	return options


## The Tuck cards the party owns, after "no Tuck" (&""): any one slides under R or L+R.
func tuck_options() -> Array[StringName]:
	var options: Array[StringName] = [&""]
	for under: ScribeCardResource in ArsenalCatalog.current.under_cards():
		if LoadoutComposer.owns(under.card_id, 1, PartyProgress.current.collection):
			options.append(under.card_id)
	return options


static func _owned_copies(listed: ScribeCardResource) -> Array[StringName]:
	var copies: Array[StringName] = []
	for variant: int in ScribeCardResource.CardVariant.size():
		var key: StringName = ScribeCardResource.copy_key(listed.card_id, variant as ScribeCardResource.CardVariant)
		if LoadoutComposer.owns(key, 1, PartyProgress.current.collection):
			copies.append(key)
	return copies


## A layer's options in the collection.
func layer_options(layer: int) -> Array[StringName]:
	match layer:
		Layer.PLACE:
			return place_options()
		Layer.TUCK:
			return tuck_options()
	return leaf_options()


## The collection's cursor on a layer.
func layer_row(layer: int) -> int:
	match layer:
		Layer.PLACE:
			return place_row
		Layer.TUCK:
			return tuck_row
	return leaf_row


## The collection column a layer opens (Column).
static func layer_column(layer: int) -> int:
	match layer:
		Layer.PLACE:
			return Column.PLACES
		Layer.TUCK:
			return Column.TUCKS
	return Column.LEAVES


# --- Moving and picking ---------------------------------------------------------

func _on_menu_input(action: StringName) -> void:
	if is_instance_valid(_guide):
		if action == InputComponent.MENU_ACCEPT or action == InputComponent.MENU_BACK:
			_guide.close()
		return
	if action == InputComponent.MENU_TAB_PREV or action == InputComponent.MENU_TAB_NEXT:
		step_tab(-1 if action == InputComponent.MENU_TAB_PREV else 1)
		return
	if tab == Tab.ATLAS and is_instance_valid(atlas):
		if action == InputComponent.MENU_BACK:
			show_grimoire_tab()
		else:
			atlas.handle_menu(action)
		return
	if action == InputComponent.MENU_BACK:
		# Dodge closes a browse first, then the Seal Press goes back to the Gear page, then the Binder closes.
		if tab == Tab.CARDS and column != Column.DIAMONDS:
			column = Column.DIAMONDS
			AudioCues.play(&"menu_move")
			_refresh()
		elif tab == Tab.SEALS:
			show_tab(Tab.GEAR)
		else:
			close()
		return
	match tab:
		Tab.GEAR:
			if action == InputComponent.MENU_UP or action == InputComponent.MENU_DOWN:
				gear_row = wrapi(gear_row + (-1 if action == InputComponent.MENU_UP else 1), 0, GearRow.size())
			elif action == InputComponent.MENU_ACCEPT or action == InputComponent.MENU_RIGHT:
				# At a rest point light opens the Seal Press (the Gear wireframe); the gear itself changes at the Scribe Desk.
				if seal_press_open():
					show_tab(Tab.SEALS)
					return
				_show_note("Change your gear at the Scribe Desk in town. %s." % PRESS_SHUT)
		Tab.COMBOS:
			if action == InputComponent.MENU_UP or action == InputComponent.MENU_DOWN:
				combo_row = wrapi(combo_row + (-1 if action == InputComponent.MENU_UP else 1), 0, maxi(1, _combo_rows.size()))
		Tab.SEALS:
			match action:
				InputComponent.MENU_LEFT, InputComponent.MENU_RIGHT:
					pick_seal_slot(SEAL_ROWS[wrapi(SEAL_ROWS.find(seal_row) + (-1 if action == InputComponent.MENU_LEFT else 1), 0, SEAL_ROWS.size())])
					return
				InputComponent.MENU_UP, InputComponent.MENU_DOWN:
					press_row = wrapi(press_row + (-1 if action == InputComponent.MENU_UP else 1), 0, maxi(1, seal_options(seal_row).size()))
				InputComponent.MENU_ACCEPT:
					press_highlighted()
		_:
			if column == Column.DIAMONDS:
				match action:
					InputComponent.MENU_LEFT, InputComponent.MENU_RIGHT:
						var at: int = BENCH_SOCKETS.find(selected_socket())
						_select_socket(BENCH_SOCKETS[wrapi(at + (-1 if action == InputComponent.MENU_LEFT else 1), 0, BENCH_SOCKETS.size())])
					InputComponent.MENU_UP, InputComponent.MENU_DOWN:
						bench_layer = wrapi(bench_layer + (-1 if action == InputComponent.MENU_UP else 1), 0, GUIDE_ROW + 1)
					InputComponent.MENU_ACCEPT:
						accept()
						return
			else:
				# Your cards are a grid of pictures: the arrows move round it.
				match action:
					InputComponent.MENU_UP:
						_move(-BinderCardBench.GRID_COLUMNS)
					InputComponent.MENU_DOWN:
						_move(BinderCardBench.GRID_COLUMNS)
					InputComponent.MENU_LEFT:
						_move(-1)
					InputComponent.MENU_RIGHT:
						_move(1)
					InputComponent.MENU_ACCEPT:
						accept()
						return
	AudioCues.play(&"menu_move")
	_refresh()


func _move(step: int) -> void:
	match column:
		Column.LEAVES:
			leaf_row = clampi(leaf_row + step, 0, leaf_options().size() - 1)
		Column.PLACES:
			place_row = clampi(place_row + step, 0, place_options().size() - 1)
		Column.TUCKS:
			tuck_row = clampi(tuck_row + step, 0, tuck_options().size() - 1)
		Column.DIAMONDS:
			bench_layer = wrapi(bench_layer + step, 0, GUIDE_ROW + 1)


# --- The tabs ---------------------------------------------------------------------

## The next (step 1) or previous (-1) tab, the Atlas Map after Combo Moves.
func step_tab(step: int) -> void:
	show_tab(wrapi(tab + step, 0, Tab.size()))


## Shows a tab: one of the three pages, or the Atlas Map.
func show_tab(index: int) -> void:
	if index == Tab.ATLAS:
		show_atlas_tab()
	else:
		_show_page(index)
		AudioCues.play(&"menu_move")


## The Atlas Map tab: the Wayfarer's Atlas in place of the pages.
func show_atlas_tab() -> void:
	if tab == Tab.ATLAS:
		return
	tab = Tab.ATLAS
	_light_hero(false)
	_root.visible = false
	var hud: PlayerHUD = PlayerHUD.for_actor(get_tree(), actor) if is_inside_tree() else null
	var level: LevelBase = get_tree().current_scene as LevelBase if is_inside_tree() else null
	if hud != null:
		level = hud._level()
	atlas = WorldMapPanel.new()
	atlas.setup(actor, level, hud, true)
	add_child(atlas)
	move_child(_sheet, -1)
	_refresh_tabs()
	_refresh_header()
	AudioCues.play(&"menu_move")


## Back from the Atlas to the tab it was opened from (Quick Magic-Ink Cards at first).
func show_grimoire_tab() -> void:
	if tab != Tab.ATLAS:
		return
	_show_page(_page_tab)
	AudioCues.play(&"menu_move")


func toggle_atlas_tab() -> void:
	if tab == Tab.ATLAS:
		show_grimoire_tab()
	else:
		show_atlas_tab()


func _show_page(index: int) -> void:
	if is_instance_valid(atlas):
		atlas.queue_free()
	atlas = null
	tab = index
	_page_tab = index
	_root.visible = true
	for page: int in _pages.size():
		_pages[page].visible = page == index
	# The one preview window moves to the page that shows the hero.
	var slot: Control = _press_page.preview_slot if index == Tab.SEALS else _gear_page.preview_slot
	if _preview_frame.get_parent() != slot:
		if _preview_frame.get_parent() != null:
			_preview_frame.get_parent().remove_child(_preview_frame)
		slot.add_child(_preview_frame)
		slot.move_child(_preview_frame, 0)
	_light_hero(_shows_preview(index))
	if _shows_preview(index):
		_place_preview()
	_refresh_tabs()
	_refresh()
	if index == Tab.CARDS and not guide_seen and not GrimoireRules.all_open():
		show_guide()


func _on_tab_clicked(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		show_tab(index)


func _refresh_tabs() -> void:
	for index: int in _tab_labels.size():
		var open: bool = index == tab
		_tab_panels[index].add_theme_stylebox_override(&"panel", AtelierTheme.tab_style(open))
		_tab_labels[index].text = TAB_NAMES[index]
		_tab_labels[index].add_theme_color_override(&"font_color", AtelierTheme.INK if open else AtelierTheme.INK_MUTED)


# --- The live preview ------------------------------------------------------------

## Whether the preview is showing the hero now.
func preview_live() -> bool:
	return _shows_preview(tab) and preview_camera != null and preview_camera.current and key_light.visible and not _lit.is_empty()


## The tabs that show the hero in the preview: Gear & Weapon and the stamping bench.
static func _shows_preview(index: int) -> bool:
	return index == Tab.GEAR or index == Tab.SEALS


## The camera circling the hero at chest height, the key light over its shoulder and the rim light behind the hero.
func _place_preview() -> void:
	if not is_instance_valid(actor) or preview_camera == null or not preview_camera.is_inside_tree():
		return
	var center: Vector3 = actor.global_position + Vector3.UP * PREVIEW_LOOK_HEIGHT
	var facing: Vector3 = -actor.global_basis.z
	facing.y = 0.0
	if facing.length_squared() < 0.01:
		facing = Vector3.FORWARD
	var around: Vector3 = facing.normalized().rotated(Vector3.UP, _preview_angle)
	preview_camera.global_position = actor.global_position + around * PREVIEW_DISTANCE + Vector3.UP * PREVIEW_HEIGHT
	preview_camera.look_at(center, Vector3.UP)
	var side: Vector3 = around.cross(Vector3.UP).normalized()
	key_light.global_position = preview_camera.global_position + side * 1.4 + Vector3.UP * 1.2
	key_light.look_at(center, Vector3.UP)
	rim_light.global_position = actor.global_position - around * 1.1 + Vector3.UP * 1.9


## The preview's lighting: a brighter, clearer copy of the sky on the camera,
## and the key and rim lights on the hero's meshes alone (layer 13) while it shows.
## (The lights go dark before a mesh leaves the layer and come on after it
## joins: the renderer mustn't see a lit mesh change layers, or it keeps a stale pairing.)
func _light_hero(on: bool) -> void:
	if key_light != null:
		key_light.visible = false
		rim_light.visible = false
	for mesh: GeometryInstance3D in _lit:
		if is_instance_valid(mesh):
			mesh.set_layer_mask_value(PREVIEW_LAYER, false)
	_lit.clear()
	if not on or not is_instance_valid(actor):
		return
	for node: Node in actor.find_children("*", "GeometryInstance3D", true, false):
		var mesh: GeometryInstance3D = node as GeometryInstance3D
		mesh.set_layer_mask_value(PREVIEW_LAYER, true)
		_lit.append(mesh)
	key_light.visible = true
	rim_light.visible = true
	if preview_viewport != null and preview_viewport.world_3d == null and actor.is_inside_tree():
		preview_viewport.world_3d = actor.get_world_3d()
	var sky: Environment = actor.get_world_3d().environment if actor.is_inside_tree() else null
	var studio: Environment = sky.duplicate() as Environment if sky != null else Environment.new()
	studio.ambient_light_energy *= PREVIEW_AMBIENT_BOOST
	studio.tonemap_exposure *= PREVIEW_EXPOSURE_BOOST
	studio.fog_density *= PREVIEW_FOG_SCALE
	preview_camera.environment = studio


## Light: slot the highlighted card in the chosen diamond's layer, or (on the bench) open the collection on it.
func accept() -> void:
	if column == Column.DIAMONDS:
		if bench_layer == GUIDE_ROW:
			show_guide()
		else:
			open_layer(bench_layer)
		return
	var layer: int = shown_layer()
	var options: Array[StringName] = layer_options(layer)
	var key: StringName = options[clampi(layer_row(layer), 0, options.size() - 1)]
	if key == layer_copy(layer):
		column = Column.DIAMONDS
		_refresh()
		return
	var from: Vector2 = _sheet_point(_bench.spotlight, BinderCardBench.SPOTLIGHT_CARD * 0.5) if is_instance_valid(_bench.spotlight) else Vector2.ZERO
	var placed: bool = false
	match column:
		Column.LEAVES:
			placed = slot_leaf(key)
		Column.PLACES:
			placed = slot_place(key)
		Column.TUCKS:
			placed = slot_tuck(key)
	if placed:
		column = Column.DIAMONDS
		_celebrate(key, layer, from)
		_refresh()


## The bench's layer that the collection shows (the guide row shows the cards).
func shown_layer() -> int:
	return Layer.CARD if bench_layer >= Layer.size() else bench_layer


## The picture guide to a diamond (DiamondGuide), over the sheet; light or dodge closes it.
func show_guide() -> void:
	if is_instance_valid(_guide):
		return
	guide_seen = true
	_guide = DiamondGuide.new()
	_sheet.add_child(_guide)
	_guide.done.connect(_on_guide_done)
	AudioCues.play(&"menu_move")


func _on_guide_done() -> void:
	_guide = null


## A point on a control, in the sheet's own coordinates.
func _sheet_point(control: Control, local: Vector2) -> Vector2:
	return _sheet.get_global_transform().affine_inverse() * (control.get_global_transform() * local)


## A card just went in: it flies from the spotlight into its diamond, sparkles burst there, a chime,
## and a cheerful line says where it went.
func _celebrate(copy_key: StringName, layer: int, from: Vector2) -> void:
	var socket: int = selected_socket()
	var card: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key)) if copy_key != &"" else null
	var landing: Vector2 = _sheet_point(widget, widget.diamond_center(socket))
	var tint: Color = AtelierTheme.sign_fill(card.scribe_sign) if card != null else AtelierTheme.GOLD
	if card != null and from != Vector2.ZERO:
		var flyer: InkCardFace = InkCardFace.new(copy_key)
		flyer.size = BinderCardBench.SPOTLIGHT_CARD
		flyer.pivot_offset = BinderCardBench.SPOTLIGHT_CARD * 0.5
		flyer.position = from - BinderCardBench.SPOTLIGHT_CARD * 0.5
		_sheet.add_child(flyer)
		var flight: Tween = flyer.create_tween().set_parallel(true)
		flight.tween_property(flyer, ^"position", landing - BinderCardBench.SPOTLIGHT_CARD * 0.5, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.tween_property(flyer, ^"scale", Vector2.ONE * 0.12, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.tween_property(flyer, ^"rotation", 0.6, 0.35)
		flight.chain().tween_callback(flyer.queue_free)
	var sparkle: CardSparkle = CardSparkle.new(tint)
	sparkle.position = landing
	_sheet.add_child(sparkle)
	AudioCues.play(&"card_chime")
	var where: String = GrimoireRules.SOCKET_NAMES[socket]
	if card == null:
		_cheer("Your %s diamond is empty now." % where)
	elif layer == Layer.PLACE:
		_cheer("%s frames your %s card!" % [card.display_name, where])
	elif layer == Layer.TUCK:
		_cheer("%s is tucked under your %s card!" % [card.display_name, where])
	else:
		_cheer("%s is in your %s diamond!" % [card.display_name, where])


## A happy note under the page (in green; a problem note is in red).
func _cheer(text: String) -> void:
	_note.text = text
	_note.add_theme_color_override(&"font_color", AtelierTheme.GOOD)
	_note_left = NOTE_TIME


## The spotlight's call to action: what light will do, or why it can't yet, in plain words.
func spotlight_words(layer: int, copy_key: StringName, verdict: Array) -> String:
	var where: String = GrimoireRules.SOCKET_NAMES[selected_socket()]
	if copy_key == layer_copy(layer):
		return "It's in your %s diamond already!" % where if copy_key != &"" else "This spot is empty now."
	if not bool(verdict[1]):
		var why: String = fit_line(copy_key, layer_column(layer)).get_slice(": ", 1).trim_suffix(".")
		return "Not yet: %s." % why if why != "" else "Not yet."
	if copy_key == &"":
		return "Light: leave it empty."
	match layer:
		Layer.PLACE:
			return "Light: frame your %s card with it!" % where
		Layer.TUCK:
			return "Light: slide it under your %s card!" % where
	return "Light: put it in your %s diamond!" % where


## Opens the collection on a layer (a click on a layer or a filter, or light on the bench).
func open_layer(layer: int) -> void:
	bench_layer = layer
	column = layer_column(layer)
	var worn: StringName = layer_copy(layer)
	var options: Array[StringName] = layer_options(layer)
	var at: int = maxi(0, options.find(worn))
	match layer:
		Layer.PLACE:
			place_row = at
		Layer.TUCK:
			tuck_row = at
		_:
			leaf_row = at
	AudioCues.play(&"menu_move")
	_refresh()


## A click on a collection row: highlight it, then slot it.
func pick_layer_row(layer: int, index: int) -> void:
	bench_layer = layer
	column = layer_column(layer)
	match layer:
		Layer.PLACE:
			place_row = index
		Layer.TUCK:
			tuck_row = index
		_:
			leaf_row = index
	accept()
	_refresh()


## Puts an Action-Leaf copy (&"" un-inks it) in the chosen diamond. Returns whether it was equipped.
func slot_leaf(copy_key: StringName) -> bool:
	var draft: EquipmentLoadoutResource = actor.loadout.kit.copy()
	draft.set_socket_leaf(selected_socket(), ScribeCardResource.copy_card_id(copy_key), ScribeCardResource.copy_variant(copy_key))
	return _equip(draft)


## Frames the chosen diamond with a Place-Card copy (&"" takes the frame away). Returns whether it was equipped.
func slot_place(copy_key: StringName) -> bool:
	var draft: EquipmentLoadoutResource = actor.loadout.kit.copy()
	draft.set_socket_place(selected_socket(), ScribeCardResource.copy_card_id(copy_key), ScribeCardResource.copy_variant(copy_key))
	return _equip(draft)


## Slides a Tuck (&"" lifts it) under the chosen diamond's card: R or L+R, never L, and only one in the hand.
## Returns whether it was equipped.
func slot_tuck(card_id: StringName) -> bool:
	var socket: int = selected_socket()
	if card_id != &"" and socket == GrimoireRules.SOCKET_L:
		_show_note("The L card takes no Tuck: slide it under R or L+R")
		AudioCues.play(&"refuse")
		return false
	var draft: EquipmentLoadoutResource = actor.loadout.kit.copy()
	draft.under_ids[ScribeCardResource.GrimoireSlot.SIGNATURE] = &""
	draft.under_ids[ScribeCardResource.GrimoireSlot.ULTIMATE] = &""
	if card_id != &"":
		draft.under_ids[_tuck_slot_for(socket)] = card_id
	return _equip(draft)


## The kit slot a diamond's Tuck sits in: R's card is the Signature, L+R's the Ultimate.
static func _tuck_slot_for(socket: int) -> int:
	return ScribeCardResource.GrimoireSlot.ULTIMATE if socket == GrimoireRules.SOCKET_LR else ScribeCardResource.GrimoireSlot.SIGNATURE


func _equip(draft: EquipmentLoadoutResource) -> bool:
	var progress: PartyProgress = PartyProgress.current
	var problem: String = LoadoutComposer.kit_problem(_player_class(), draft, progress.grimoire_level(), progress.collection, progress.trail_level())
	if problem != "":
		_show_note(problem)
		AudioCues.play(&"refuse")
		return false
	NetworkManager.current.update_local_kit(actor.device_id, draft.to_dict())
	AudioCues.play(&"equip")
	widget.clear_preview()
	_refresh()
	return true


func _on_socket_picked(socket: int) -> void:
	_select_socket(socket)
	column = Column.DIAMONDS
	_refresh()


func _select_socket(socket: int) -> void:
	widget.selected_socket = socket
	diamond_row = maxi(0, DIAMOND_ROWS.find(socket))
	leaf_row = 0
	place_row = 0
	tuck_row = 0


func _on_kit_refused(device_id: int, reason: String) -> void:
	if is_instance_valid(actor) and device_id == actor.device_id:
		_show_note(reason)


func _show_note(text: String) -> void:
	_note.text = text
	_note.add_theme_color_override(&"font_color", PROBLEM_COLOR)
	_note_left = NOTE_TIME


# --- The card bench's words ------------------------------------------------------------

## What a layer of the chosen diamond holds now (a copy key, a Tuck's card id, or &"").
func layer_copy(layer: int) -> StringName:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	var socket: int = selected_socket()
	match layer:
		Layer.PLACE:
			return ScribeCardResource.copy_key(kit.place_ids[socket], kit.socket_place_variant(socket) as ScribeCardResource.CardVariant) if kit.place_ids[socket] != &"" else &""
		Layer.TUCK:
			return kit.under_ids[_tuck_slot_for(socket)] if socket != GrimoireRules.SOCKET_L else &""
	var leaf: StringName = kit.socket_leaf_id(socket)
	return ScribeCardResource.copy_key(leaf, kit.socket_leaf_variant(socket) as ScribeCardResource.CardVariant) if leaf != &"" else &""


## What an empty layer says.
static func empty_layer_text(layer: int) -> String:
	match layer:
		Layer.PLACE:
			return "No Place-Card"
		Layer.TUCK:
			return "No Tuck"
	return "Un-inked (the weapon's own move)"


## A layer's second line: the Sign, mode and finish of its card, or what a Tuck does with the card above it.
func layer_about(layer: int, copy_key: StringName) -> String:
	if copy_key == &"":
		match layer:
			Layer.TUCK:
				return "L takes no Tuck." if selected_socket() == GrimoireRules.SOCKET_L else "One Tuck in the hand, under R or L+R."
			Layer.CARD:
				return "The weapon swings its own flourish."
		return ""
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var card: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(copy_key))
	if card == null:
		return ""
	var sign_name: String = catalog.sign_seal(card.scribe_sign).display_name
	match layer:
		Layer.PLACE:
			var leaf: ScribeCardResource = catalog.card(actor.loadout.kit.socket_leaf_id(selected_socket()))
			var same: bool = leaf != null and leaf.scribe_sign == card.scribe_sign and card.scribe_sign != ScribeSignResource.Sign.NONE
			return "%s · %s" % [sign_name, "same Sign as its card: Home-Ground Harmony, the coat lasts longer" if same else "frames the card with this place's strength"]
		Layer.TUCK:
			return "%s · %s" % [sign_name, tuck_pairing(card)]
	var told: String = card.description.strip_edges()
	return "%s · %s · %s. %s" % [sign_name, card.mode_name(), ScribeCardResource.VARIANT_NAMES[ScribeCardResource.copy_variant(copy_key)],
		told if told != "" else card_effect(card)]


## What a Tuck does with the chosen diamond's card: a Maker-Sleight on the same Sign, a Dual-Sign Strike on another.
func tuck_pairing(tuck: ScribeCardResource) -> String:
	var leaf: ScribeCardResource = ArsenalCatalog.current.card(actor.loadout.kit.socket_leaf_id(selected_socket()))
	if leaf == null:
		return "slides under whichever card is above it"
	if leaf.scribe_sign == tuck.scribe_sign:
		return "Maker-Sleight with %s (one stronger move)" % leaf.display_name
	return "Dual-Sign Strike with %s (cracks two gates)" % leaf.display_name


## Where the one Tuck can go, as [words, it's here now, it can go here]: under L (never), R, L+R.
func tuck_spots() -> Array[Array]:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	var level: int = PartyProgress.current.character_level(actor.loadout.class_id)
	var under: int = LoadoutComposer.tuck_slot_of(kit)
	var spots: Array[Array] = []
	spots.append(["L takes none", false, false])
	var r_open: bool = GrimoireRules.tuck_open(level) and GrimoireRules.socket_open(GrimoireRules.SOCKET_R, level)
	spots.append(["Under R%s" % (" · now" if under == ScribeCardResource.GrimoireSlot.SIGNATURE else ""),
		under == ScribeCardResource.GrimoireSlot.SIGNATURE, r_open])
	var lr_open: bool = GrimoireRules.tuck_open(level) and GrimoireRules.socket_open(GrimoireRules.SOCKET_LR, level)
	spots.append(["Under L+R%s" % (" · now" if under == ScribeCardResource.GrimoireSlot.ULTIMATE else (" · Lv %d" % GrimoireRules.SOCKET_OPEN_LEVELS[GrimoireRules.SOCKET_LR] if not lr_open else "")),
		under == ScribeCardResource.GrimoireSlot.ULTIMATE, lr_open])
	return spots


## The collection's filter tab for a layer ("Cards for R", "Tucks", "Place-Cards").
func filter_name(layer: int) -> String:
	match layer:
		Layer.PLACE:
			return "Place-Cards"
		Layer.TUCK:
			return "Tucks"
	return "Cards for %s" % GrimoireRules.SOCKET_NAMES[selected_socket()]


## A collection row's second line.
func collection_note(layer: int, copy_key: StringName) -> String:
	if copy_key == &"":
		match layer:
			Layer.PLACE:
				return "the diamond stands bare"
			Layer.TUCK:
				return "nothing under the card"
		return "the weapon's own move"
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var card: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(copy_key))
	if card == null:
		return ""
	var sign_name: String = catalog.sign_seal(card.scribe_sign).display_name
	match layer:
		Layer.TUCK:
			return "%s · %s" % [sign_name, tuck_pairing(card)]
		Layer.PLACE:
			return "%s · %s" % [sign_name, ScribeCardResource.VARIANT_NAMES[ScribeCardResource.copy_variant(copy_key)]]
	var socket: int = selected_socket()
	var cost: int = GrimoireRules.ink_cost(socket, card, layer_copy(Layer.TUCK) != &"")
	return "%s · %s · %s · %d drop%s" % [sign_name, card.mode_name(), ScribeCardResource.VARIANT_NAMES[ScribeCardResource.copy_variant(copy_key)],
		cost, "" if cost == 1 else "s"]


## Whether a collection row goes in, as [the chip's words, it fits]: "in use", "tucked", "fits", or what's in the way.
func fit_verdict(layer: int, copy_key: StringName) -> Array:
	if copy_key == layer_copy(layer):
		return ["tucked" if layer == Layer.TUCK and copy_key != &"" else "in use", true]
	var line: String = fit_line(copy_key, layer_column(layer))
	if line.begins_with("Ready"):
		return ["fits", true]
	var why: String = line.get_slice(": ", 1).trim_suffix(".")
	if why.length() > 24:
		why = why.substr(0, 22) + "…"
	return [why if why != "" else "not yet", false]


## The seven slots of the hand as tiles, [name, what's in it, open]: the three Seals, L, R, the Tuck, L+R.
func hand_tiles() -> Array[Array]:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var level: int = PartyProgress.current.character_level(actor.loadout.class_id)
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	var tiles: Array[Array] = []
	var names: Array[String] = ["Weapon Seal", "Offhand Seal", "Mantle Seal"]
	for slot: int in SEAL_ROWS:
		var card: ScribeCardResource = catalog.get_card(actor.seal.loadout.card_in_slot(slot)) if actor.seal != null and actor.seal.loadout != null else null
		var open: bool = GrimoireRules.seal_open(slot, level)
		tiles.append([names[slot], _tile_word(card, open, GrimoireRules.SEAL_OPEN_LEVELS[slot]), open])
	for socket: int in [GrimoireRules.SOCKET_L, GrimoireRules.SOCKET_R]:
		var open: bool = GrimoireRules.socket_open(socket, level)
		tiles.append(["%s card" % GrimoireRules.SOCKET_NAMES[socket], _tile_word(catalog.card(kit.socket_leaf_id(socket)), open, GrimoireRules.SOCKET_OPEN_LEVELS[socket]), open])
	var tuck_slot: int = LoadoutComposer.tuck_slot_of(kit)
	var tuck: ScribeCardResource = catalog.card(kit.under_ids[tuck_slot]) if tuck_slot >= 0 else null
	tiles.append(["Tuck", _tile_word(tuck, GrimoireRules.tuck_open(level), GrimoireRules.TUCK_OPEN_LEVEL), GrimoireRules.tuck_open(level)])
	var lr_open: bool = GrimoireRules.socket_open(GrimoireRules.SOCKET_LR, level)
	tiles.append(["L+R", _tile_word(catalog.card(kit.socket_leaf_id(GrimoireRules.SOCKET_LR)), lr_open, GrimoireRules.SOCKET_OPEN_LEVELS[GrimoireRules.SOCKET_LR]), lr_open])
	return tiles


static func _tile_word(card: ScribeCardResource, open: bool, opens: int) -> String:
	if not open:
		return "Lv %d" % opens
	return BinderGearPage._short_name(card.display_name) if card != null else "empty"


## The chosen diamond's name and what it's for ("R · your skill").
func socket_title(socket: int) -> String:
	return ["L · your shield card", "R · your attack card", "L+R · your Grand card"][clampi(socket, 0, 2)]


## What casting the chosen diamond's card costs, and its button.
func socket_cost_line(socket: int) -> String:
	var button: String = _key([InputComponent.ACTION_TRIGGER_L, InputComponent.ACTION_TRIGGER_R, InputComponent.ACTION_ULT][clampi(socket, 0, 2)])
	var cost: int = _socket_cost(socket)
	var words: String = _cost_words(cost)
	if socket == GrimoireRules.SOCKET_LR:
		return "%s · %s, the Grand card" % [button, words]
	if socket == GrimoireRules.SOCKET_R:
		return "%s · %s, one more with its Tuck" % [button, words]
	return "%s · tap in the flash after a hit: %s" % [button, words]


## What the chosen diamond's card costs now: Ink-Drops on the Ink-Well, the old pips otherwise.
func _socket_cost(socket: int) -> int:
	if _on_ink_well():
		var card: ScribeCardResource = ArsenalCatalog.current.card(actor.loadout.kit.socket_leaf_id(socket))
		return GrimoireRules.ink_cost(socket, card, socket != GrimoireRules.SOCKET_L and actor.loadout.kit.under_ids[_tuck_slot_for(socket)] != &"")
	return int(ScribeCardResource.SOCKET_PIP_COSTS[socket])


func _cost_words(cost: int) -> String:
	if _on_ink_well():
		return "%d Ink-Drop%s" % [cost, "" if cost == 1 else "s"]
	return "%d pip%s" % [cost, "" if cost == 1 else "s"]


func _on_ink_well() -> bool:
	return is_instance_valid(actor) and actor.stats != null and actor.stats.uses_ink_well()


## How many Ink-Drops the hero's well holds (its stage's depth, with Wise Hand's extra).
func well_depth() -> int:
	if _on_ink_well():
		return actor.stats.stats.max_resonance_pips
	var level: int = PartyProgress.current.character_level(actor.loadout.class_id)
	return GrimoireRules.well_depth(PlayerLoadoutResource.stage_for_true_level(level), _player_class().bonus_memory > 0)


# --- Drawing the pages ------------------------------------------------------------

func _refresh() -> void:
	if not is_instance_valid(actor) or widget == null:
		return
	_refresh_header()
	match tab:
		Tab.GEAR:
			_gear_page.refresh()
			_hint.text = "↑ ↓ look over your gear  ·  %s  ·  dodge or Tab closes  ·  everything here is look-only" % (
				"light opens the Seal Press" if seal_press_open() else "the Seal Press opens at a Hearth-Brazier")
		Tab.COMBOS:
			_refresh_combos()
			_hint.text = "↑ ↓ choose a move  ·  dodge or Tab closes"
		Tab.SEALS:
			press_row = clampi(press_row, 0, maxi(0, seal_options(seal_row).size() - 1))
			_press_page.refresh()
			_hint.text = ("← → weapon, offhand, mantle  ·  ↑ ↓ choose a card  ·  light presses it  ·  dodge goes back to the Binder" if seal_press_open()
				else "← → weapon, offhand, mantle  ·  ↑ ↓ look at a card  ·  look only: %s  ·  dodge goes back" % PRESS_SHUT)
		_:
			_refresh_cards()
	# The box shows what's highlighted; what the tab is for already sits under the title.
	var said: String = tooltip_text_now()
	_tooltip.text = said.trim_suffix("\n" + TAB_TOOLTIPS[tab]) if said != TAB_TOOLTIPS[tab] else said
	_tooltip_head.text = tooltip_heading()
	widget.queue_redraw()


## The header: the tab's letter, its title with the hero or the diamond and the Chimes, and what it's for.
func _refresh_header() -> void:
	var chimes: int = PartyProgress.current.chimes
	_glyph.text = TAB_GLYPHS[tab]
	match tab:
		Tab.GEAR:
			_title.text = "GRIMOIRE BINDER · %s · %d Chimes" % [actor.loadout.display_name, chimes]
		Tab.CARDS:
			_title.text = "GRIMOIRE BINDER · %s card · %d Chimes" % [GrimoireRules.SOCKET_NAMES[selected_socket()], chimes]
		Tab.COMBOS:
			_title.text = "GRIMOIRE BINDER · Combo Moves · %d Chimes" % chimes
		Tab.SEALS:
			_title.text = "SEAL PRESS · %s" % ("open: you're at a rest point" if seal_press_open() else "look only")
		_:
			_title.text = "GRIMOIRE BINDER · Atlas Map"
	_subtitle.text = TAB_SUBTITLES[tab]


func _refresh_cards() -> void:
	var socket: int = selected_socket()
	leaf_row = clampi(leaf_row, 0, leaf_options().size() - 1)
	place_row = clampi(place_row, 0, place_options().size() - 1)
	tuck_row = clampi(tuck_row, 0, tuck_options().size() - 1)
	# Preview what's highlighted in the chosen diamond.
	var view: Dictionary = widget.socket_view(socket)
	widget.clear_preview()
	match column:
		Column.LEAVES:
			var key: StringName = leaf_options()[leaf_row]
			widget.preview_socket(socket, ScribeCardResource.copy_card_id(key), ScribeCardResource.copy_variant(key), view["place"], view["place_variant"])
		Column.PLACES:
			var key: StringName = place_options()[place_row]
			widget.preview_socket(socket, view["leaf"], view["leaf_variant"], ScribeCardResource.copy_card_id(key), ScribeCardResource.copy_variant(key))
	_bench.refresh()
	if column == Column.DIAMONDS:
		_hint.text = "← → pick a diamond  ·  ↑ ↓ pick what to change  ·  light: choose a card  ·  dodge or Tab closes"
	else:
		_hint.text = "arrows: look at your cards  ·  light: put it in  ·  dodge: go back"


## The weapon row: the material's own name, the frame, and its tier of seven ("Barrow-Steel Long-Blade  ·  Falchion  (Tier IV of VII)").
func _weapon_line(weapon: EquipmentItemResource) -> String:
	if weapon == null:
		return "Hands"
	var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
	if tier == null:
		return "%s  (Tier %s)" % [weapon.display_name, CrossGrimoireDiamondWidget.TIER_NUMERALS[clampi(weapon.equipment_tier, 0, 4)]]
	var arch: EquipmentTierResource.WeaponArchetype = actor.seal.loadout.weapon_archetype as EquipmentTierResource.WeaponArchetype
	return "%s  ·  %s  (Tier %s of VII)" % [tier.weapon_name(arch), weapon.display_name, CrossGrimoireDiamondWidget.TIER_NUMERALS[tier.tier_index]]


## The weapon's name now: its material's own blade for the frame ("Barrow-Steel Long-Blade").
func weapon_title() -> String:
	var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
	if tier == null:
		return actor.loadout.weapon.display_name if actor.loadout.weapon != null else "Hands"
	return tier.weapon_name(actor.seal.loadout.weapon_archetype as EquipmentTierResource.WeaponArchetype)


## The tier the hero's armour is forged in (the weapon's when the hand names none).
func armour_tier() -> EquipmentTierResource:
	var tier: EquipmentTierResource = ArsenalCatalog.current.get_tier(actor.seal.loadout.armor_tier_id) if actor.seal != null and actor.seal.loadout != null else null
	return tier if tier != null else (actor.seal.tier() if actor.seal != null else null)


## A piece's four lines on the Gear page: its kind, its name, its numbers, what's next.
func piece_words(piece: int) -> PackedStringArray:
	var loadout: ClassLoadoutResource = actor.loadout
	var progress: PartyProgress = PartyProgress.current
	var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
	var hand: PlayerLoadoutResource = actor.seal.loadout if actor.seal != null else null
	if tier == null or hand == null:
		return PackedStringArray(["Gear", loadout.weapon.display_name if loadout.weapon != null else "Hands", "", ""])
	var arch: EquipmentTierResource.WeaponArchetype = hand.weapon_archetype as EquipmentTierResource.WeaponArchetype
	var frame: WeaponArchetypeResource = ArsenalCatalog.current.archetype_for_weapon_type(loadout.weapon.weapon_type) if loadout.weapon != null else null
	match piece:
		GearRow.WEAPON:
			var next: int = progress.next_promotion(loadout.class_id, PartyProgress.PIECE_WEAPON)
			var ahead: String = "Next: %s, ready to promote at the Scribe Desk." % ArsenalCatalog.current.tier_at(next).weapon_name(arch) if next > 0 \
				else "Next: %s." % progress.promotion_problem(loadout.class_id, PartyProgress.PIECE_WEAPON)
			return PackedStringArray(["Weapon · %s" % (frame.frame_noun if frame != null else "frame"), weapon_title(),
				"Tier %d of 7 · rank %+d · Light %.1f · Heavy %.1f · stagger ×%.2f · %s frame" % [tier.tier_index, tier.gear_threat_rank,
					tier.get_weapon_damage(false, arch), tier.get_weapon_damage(true, arch), tier.posture_multiplier,
					loadout.weapon.display_name if loadout.weapon != null else "no"], ahead])
		GearRow.OFF_HAND:
			var guard: String = "hold L to guard" if loadout.role == ClassLoadoutResource.Role.TANK else (
				"the D-Pad ties it to a friend" if loadout.role == ClassLoadoutResource.Role.HEALER else "it rides with the weapon")
			return PackedStringArray(["Offhand · %s" % off_hand_name(loadout), tier.offhand_name(arch),
				"Tier %d · %s · %s" % [tier.tier_index, tier.weapon_material_name, guard],
				"Bows carry a quiver here, staffs a censer, mauls a Pommel-Knot."])
	var armour: EquipmentTierResource = armour_tier()
	var weight: EquipmentTierResource.ArmorWeightClass = hand.armor_weight_class as EquipmentTierResource.ArmorWeightClass
	var weights: Array[String] = ["Heavy armour", "Medium armour", "Light armour"]
	var next_armour: int = progress.next_promotion(loadout.class_id, PartyProgress.PIECE_ARMOR)
	var later: String = ("Next: %s (%d%%), ready to promote at the Scribe Desk." % [ArsenalCatalog.current.tier_at(next_armour).get_armor_display_name(weight),
		ArsenalCatalog.current.tier_at(next_armour).armor_guard_percent(weight)]) if next_armour > 0 \
		else "Next: %s." % progress.promotion_problem(loadout.class_id, PartyProgress.PIECE_ARMOR)
	return PackedStringArray(["Mantle · %s" % weights[clampi(int(weight), 0, 2)], armour.get_armor_display_name(weight),
		"Tier %d · Armor Guard %d%% · the weight set by your Fellowship" % [armour.tier_index, armour.armor_guard_percent(weight)], later])


## Under the gear rows: Steward Threat as a sum, what the kit adds up to, and each Seal with its Marks.
func gear_summary() -> String:
	var lines: PackedStringArray = PackedStringArray()
	var level: int = PartyProgress.current.character_level(actor.loadout.class_id)
	var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
	var stats: CharacterStatsResource = actor.stats.stats
	if tier != null:
		var arch: EquipmentTierResource.WeaponArchetype = actor.seal.loadout.weapon_archetype as EquipmentTierResource.WeaponArchetype
		var weight: EquipmentTierResource.ArmorWeightClass = actor.seal.loadout.armor_weight_class as EquipmentTierResource.ArmorWeightClass
		var armour_tier: EquipmentTierResource = ArsenalCatalog.current.get_tier(actor.seal.loadout.armor_tier_id)
		if armour_tier == null:
			armour_tier = tier
		lines.append("Lv %d + %s %+d = Steward Threat %d  ·  Stage %d" % [level, tier.weapon_material_name, tier.gear_threat_rank,
			PartyProgress.current.steward_threat(actor.loadout.class_id, tier.gear_threat_rank), actor.seal.progression_stage])
		lines.append("Armor Guard %d%%  ·  Light / Heavy %.1f / %.1f  ·  Stagger ×%.2f" % [armour_tier.armor_guard_percent(weight),
			tier.get_weapon_damage(false, arch), tier.get_weapon_damage(true, arch), tier.posture_multiplier])
	lines.append("Health %d  ·  Breath Recovery %.1f / s  ·  Roll %.1f m  ·  Perfect Guard %d ms" % [roundi(stats.max_health),
		stats.stamina_regen_per_sec, stats.roll_distance, roundi(stats.perfect_guard_window * 1000.0)])
	if actor.seal != null and actor.seal.loadout != null:
		for slot: int in SEAL_ROWS:
			var card_id: StringName = actor.seal.loadout.card_in_slot(slot)
			var listed: ScribeCardResource = ArsenalCatalog.current.get_card(card_id)
			if listed != null:
				lines.append("%s:  %s  ·  %s" % [PlayerLoadoutResource.HAND_SLOT_NAMES[slot], listed.display_name, seal_marks_text(card_id)])
	return "\n".join(lines)


func _refresh_combos() -> void:
	var forms: Array[ComboChainResource] = ArsenalCatalog.current.combos()
	var lines: PackedStringArray = combo_forms_text().split("\n")
	combo_row = clampi(combo_row, 0, maxi(0, forms.size() - 1))
	for index: int in _combo_rows.size():
		var row: Label = _combo_rows[index]
		row.visible = index < forms.size()
		if not row.visible:
			continue
		row.text = ("> " if index == combo_row else "  ") + lines[index].strip_edges()
		var learned: bool = PartyProgress.current.trail_level() >= forms[index].required_level
		row.modulate = SELECTED_COLOR if index == combo_row else (ROW_COLOR if learned else DIM_COLOR)
		row.tooltip_text = combo_tooltip(forms[index])


# --- Tooltips ------------------------------------------------------------------------

## The tooltip box's text right now: what the tab is for, then what the highlighted row does.
func tooltip_text_now() -> String:
	var item: String = ""
	match tab:
		Tab.GEAR:
			item = gear_tooltip(gear_row)
		Tab.COMBOS:
			var forms: Array[ComboChainResource] = ArsenalCatalog.current.combos()
			item = combo_tooltip(forms[combo_row]) if combo_row < forms.size() else ""
		Tab.SEALS:
			item = seal_tooltip(seal_row)
		Tab.CARDS:
			item = _card_tooltip()
	return TAB_TOOLTIPS[tab] if item == "" else "%s\n%s" % [item, TAB_TOOLTIPS[tab]]


## The tooltip box's left column: what kind of thing is highlighted, and its name.
func tooltip_heading() -> String:
	match tab:
		Tab.GEAR:
			var named: Array[String] = [weapon_title(), piece_words(GearRow.OFF_HAND)[1], piece_words(GearRow.ARMOR)[1], actor.loadout.display_name]
			return "HIGHLIGHTED · %s\n%s" % [["WEAPON", "OFFHAND", "MANTLE", "CALLING"][gear_row], named[gear_row]]
		Tab.CARDS:
			var layer: int = shown_layer()
			if column == Column.DIAMONDS:
				return "HIGHLIGHTED · %s\n%s" % [("GUIDE" if bench_layer == GUIDE_ROW else ["PLACE-CARD", "INK CARD", "TUCK"][layer]), socket_title(selected_socket())]
			var key: StringName = layer_options(layer)[clampi(layer_row(layer), 0, layer_options(layer).size() - 1)]
			var card: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(key)) if key != &"" else null
			return "HIGHLIGHTED · %s\n%s" % [["PLACE-CARD", "INK CARD", "TUCK"][layer], card.display_name if card != null else empty_layer_text(layer)]
		Tab.SEALS:
			var seal: ScribeCardResource = ArsenalCatalog.current.get_card(press_candidate())
			return "HIGHLIGHTED · %s SEAL\n%s" % [GrimoireRules.SEAL_NAMES[seal_row].to_upper(), seal.display_name if seal != null else "an empty slot"]
		Tab.COMBOS:
			return "COMBO MOVES"
	return ""


## What a gear row means, in a sentence.
func gear_tooltip(row: int) -> String:
	var loadout: ClassLoadoutResource = actor.loadout
	match row:
		GearRow.WEAPON:
			var weapon: EquipmentItemResource = loadout.weapon
			if weapon == null:
				return "No weapon: your fists."
			var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
			if tier != null:
				var arch: EquipmentTierResource.WeaponArchetype = actor.seal.loadout.weapon_archetype as EquipmentTierResource.WeaponArchetype
				var next: int = PartyProgress.current.next_promotion(loadout.class_id, PartyProgress.PIECE_WEAPON)
				var ahead: String = "Promote it to %s at the Scribe Desk." % ArsenalCatalog.current.tier_at(next).weapon_name(arch) if next > 0 \
					else PartyProgress.current.promotion_problem(loadout.class_id, PartyProgress.PIECE_WEAPON) + "."
				return "%s: Tier %d of 7. Light %.1f, Heavy %.1f, stagger ×%.2f. %s" % [tier.weapon_name(arch), tier.tier_index,
					tier.get_weapon_damage(false, arch), tier.get_weapon_damage(true, arch), tier.posture_multiplier, ahead]
			var told: String = weapon.description.strip_edges()
			return told if told != "" else "Tier %d of the trail's four. Higher tiers hit harder." % weapon.equipment_tier
		GearRow.OFF_HAND:
			match loadout.role:
				ClassLoadoutResource.Role.TANK:
					return "A greatshield: hold L to guard, and the boss keeps its eyes on you."
				ClassLoadoutResource.Role.HEALER:
					return "The Tether-Lantern: the D-Pad ties it to a friend, and your heals go down the tether."
			return "A quiver of arrows." if loadout.is_ranged() else "A scribe's satchel of ink and quills."
		GearRow.ARMOR:
			if loadout.armor == null:
				return "No armour."
			var said: String = loadout.armor.description.strip_edges()
			return said if said != "" else "Heavier armour takes more of each hit; lighter armour rolls further."
		GearRow.CALLING:
			var secondary: SecondaryCallingResource = Callings.secondary(loadout.calling)
			var sub: String = Callings.subtitle(loadout.class_id, loadout.calling)
			if secondary == null:
				return "Unsworn: no Calling yet. One opens at Level %d (hold C, or the Scribe Desk)." % ArsenalCatalog.CALLING_LEVEL
			return ("%s: %s" % [sub, secondary.summary()]) if sub != "" else secondary.summary()
	return ""


## What the Seal in a slot does on that piece (the Contextual Slot Rule), or "".
func seal_effect_text(slot: int) -> String:
	if not seal_slot_open(slot) or actor.seal.loadout == null:
		return ""
	var listed: ScribeCardResource = ArsenalCatalog.current.get_card(actor.seal.loadout.card_in_slot(slot))
	if listed == null:
		return ""
	var flag: int = int(actor.seal.loadout.seal_slots()[slot][0])
	return String(listed.slot_passive(flag).get("text", "")).strip_edges()


## A Seal's finish and its Ink-Binding Marks: "Plain Ink · 62 / 100 Marks", "Gilded Leaf · Ready to Press", "Star-Ink".
func seal_marks_text(card_id: StringName) -> String:
	var progress: PartyProgress = PartyProgress.current
	var finish: int = maxi(progress.best_finish(card_id), 0)
	var key: StringName = ScribeCardResource.copy_key(card_id, finish as ScribeCardResource.CardVariant)
	var named: String = ScribeCardResource.VARIANT_NAMES[finish]
	var needed: int = PartyProgress.marks_needed(key)
	if needed <= 0:
		return named
	if progress.ready_to_press(key):
		return "%s · Ready to Press" % named
	return "%s · %d / %d Marks" % [named, progress.marks_of(key), needed]


## Whether the Seal Press takes changes here: at a Hearth-Brazier or the Scribe Desk (25 GDD §2),
## anywhere in the classic full kits the older checks stand in.
func seal_press_open() -> bool:
	if GrimoireRules.all_open():
		return true
	if not is_instance_valid(actor) or not actor.is_inside_tree():
		return false
	for group: StringName in [BRAZIER_GROUP, DESK_GROUP]:
		for rest: Node in actor.get_tree().get_nodes_in_group(group):
			var spot: Node3D = rest as Node3D
			if spot != null and spot.global_position.distance_to(actor.global_position) <= PRESS_REACH:
				return true
	return false


## One slot's row: "Off-Hand:  ◆ Seal of the Quiet Weir  [Star-Tide]", "Mantle:  ▢ locked · opens at Stage 3 (Lv 11)".
func seal_row_text(slot: int) -> String:
	var slot_name: String = PlayerLoadoutResource.HAND_SLOT_NAMES[slot]
	if not seal_slot_open(slot):
		return "%s:  %s locked · %s" % [slot_name, SEAL_LOCKED, PlayerLoadoutResource.slot_opens_text(slot)]
	var card_id: StringName = actor.seal.loadout.card_in_slot(slot) if actor.seal.loadout != null else &""
	var listed: ScribeCardResource = ArsenalCatalog.current.get_card(card_id)
	if listed == null:
		return "%s:  %s none" % [slot_name, SEAL_EMPTY]
	var lent: bool = card_id == ArsenalCatalog.starting_seal_for_slot(actor.role(), slot) \
		and not ArsenalCatalog.owns_any_finish(card_id, PartyProgress.current.collection)
	return "%s:  %s %s  [%s]%s  ·  %s" % [slot_name, SEAL_PRESSED, listed.display_name, ArsenalCatalog.current.sign_seal(listed.scribe_sign).display_name,
		"  (starter)" if lent else "", seal_marks_text(card_id)]


## What a slot of the hand does, and what is in it; a locked slot says when it opens.
func seal_tooltip(slot: int) -> String:
	if actor.seal == null:
		return ""
	var slot_name: String = PlayerLoadoutResource.HAND_SLOT_NAMES[slot]
	if not seal_slot_open(slot):
		return "Locked: the %s slot %s. Your hero is Lv %d." % [slot_name, PlayerLoadoutResource.slot_opens_text(slot), actor.seal.true_level]
	var tip: String = SEAL_SLOT_TIPS[slot]
	if not PlayerLoadoutResource.is_seal_slot(slot):
		var on_l: bool = slot == PlayerLoadoutResource.HandSlot.L_PRIMARY or slot == PlayerLoadoutResource.HandSlot.L_TUCK
		var key: String = _key(InputComponent.ACTION_TRIGGER_L if on_l else InputComponent.ACTION_TRIGGER_R)
		tip = tip % ([key, key] if tip.count("%s") == 2 else [key])
	var listed: ScribeCardResource = ArsenalCatalog.current.get_card(actor.seal.loadout.card_in_slot(slot)) if actor.seal.loadout != null else null
	if listed == null:
		return "%s Empty: ←/→ presses a card here." % tip
	return "%s %s" % [tip, listed.description.strip_edges()]


# --- The Seal Press ------------------------------------------------------------------

## The cards a slot of the hand cycles through: none (&""), the Fellowship's starting seal, then every seal card the party owns.
func seal_options(slot: int) -> Array[StringName]:
	return ArsenalCatalog.current.seal_options_for_slot(actor.role(), slot, PartyProgress.current.collection)


## Whether a slot of the hand is open at the hero's stage and level.
func seal_slot_open(slot: int) -> bool:
	return is_instance_valid(actor) and actor.seal != null and PlayerLoadoutResource.slot_open(slot, actor.seal.progression_stage, actor.seal.true_level)


## A Seal tile's line: the card's name with its shape, or that the slot is empty or still locked.
func seal_tile_text(slot: int) -> String:
	if not seal_slot_open(slot):
		return "%s opens at Lv %d" % [SEAL_LOCKED, GrimoireRules.SEAL_OPEN_LEVELS[slot]]
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(actor.seal.loadout.card_in_slot(slot)) if actor.seal.loadout != null else null
	return "%s %s" % [SEAL_PRESSED, card.display_name] if card != null else "%s empty" % SEAL_EMPTY


## Picks one of the three Seals (left / right, or a click on its tile); the list starts on the card it holds.
func pick_seal_slot(slot: int) -> void:
	seal_row = slot
	var options: Array[StringName] = seal_options(slot)
	var worn: StringName = actor.seal.loadout.card_in_slot(slot) if actor.seal != null and actor.seal.loadout != null else &""
	press_row = maxi(0, options.find(worn))
	AudioCues.play(&"menu_move")
	_refresh()


## A click on a card in the press's list: highlight it.
func pick_press_row(index: int) -> void:
	press_row = index
	AudioCues.play(&"menu_move")
	_refresh()


## The card highlighted in the press's list (&"" for leaving the slot empty).
func press_candidate() -> StringName:
	var options: Array[StringName] = seal_options(seal_row)
	return options[clampi(press_row, 0, options.size() - 1)] if not options.is_empty() else &""


## Light in the Seal Press: presses the highlighted card into the chosen slot (refused, with why, when the slot
## is locked or the press is shut away from a rest point). Returns whether the hero now wears it.
func press_highlighted() -> bool:
	if not is_instance_valid(actor) or actor.seal == null or actor.seal.loadout == null:
		return false
	if not seal_slot_open(seal_row):
		_show_note("The %s slot %s" % [PlayerLoadoutResource.HAND_SLOT_NAMES[seal_row], PlayerLoadoutResource.slot_opens_text(seal_row)])
		AudioCues.play(&"refuse")
		return false
	if not seal_press_open():
		_show_note(PRESS_SHUT)
		AudioCues.play(&"refuse")
		return false
	return press_seal(seal_row, press_candidate())


## Left / right (or light) on the bench: the highlighted slot's next (or previous) card, pressed at
## once if it fits. A locked slot refuses and says when it opens. Returns whether the hero now wears it.
func step_seal(step: int) -> bool:
	if not is_instance_valid(actor) or actor.seal == null or actor.seal.loadout == null:
		return false
	if not seal_slot_open(seal_row):
		_show_note("The %s slot %s" % [PlayerLoadoutResource.HAND_SLOT_NAMES[seal_row], PlayerLoadoutResource.slot_opens_text(seal_row)])
		AudioCues.play(&"refuse")
		return false
	if not seal_press_open():
		_show_note(PRESS_SHUT)
		AudioCues.play(&"refuse")
		return false
	var options: Array[StringName] = seal_options(seal_row)
	var index: int = options.find(actor.seal.loadout.card_in_slot(seal_row))
	return press_seal(seal_row, options[wrapi(index + step, 0, options.size())])


## Presses a seal card (&"" lifts it) into one slot of the hand. Returns whether the hero now wears it.
func press_seal(slot: int, card_id: StringName) -> bool:
	if not is_instance_valid(actor) or actor.seal == null or actor.seal.loadout == null:
		return false
	var draft: PlayerLoadoutResource = actor.seal.loadout.copy()
	# One card, one place (25 GDD R5): pressing a seal already on another piece moves it here.
	if card_id != &"":
		for other: int in PlayerLoadoutResource.HAND_SLOT_COUNT:
			if other != slot and draft.card_in_slot(other) == card_id:
				draft.set_card_in_slot(other, &"")
	draft.set_card_in_slot(slot, card_id)
	var problem: String = actor.seal.choose_hand(draft)
	if problem != "":
		_show_note(problem)
		AudioCues.play(&"refuse")
		return false
	AudioCues.play(&"equip")
	_refresh()
	return true


## Where a seal card is now, for its chip in the press's list: "on the weapon", "in use" (a socket card), or "".
## (Pressing one that's on another piece moves it here: the list's foot says so.)
func seal_whereabouts(card_id: StringName) -> String:
	if card_id == &"" or actor.seal == null or actor.seal.loadout == null:
		return ""
	var pieces: Array[String] = ["on the weapon", "on the offhand", "on the mantle"]
	for slot: int in SEAL_ROWS:
		if actor.seal.loadout.card_in_slot(slot) == card_id:
			return pieces[slot]
	if LoadoutComposer.socket_cards(actor.loadout.kit).has(card_id):
		return "in use"
	return "free"


## A seal card's second line in the press's list: its Sign, finish, Marks and spare copies.
func seal_candidate_note(card_id: StringName) -> String:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var card: ScribeCardResource = catalog.get_card(card_id)
	if card == null:
		return ""
	var progress: PartyProgress = PartyProgress.current
	var finish: int = progress.best_finish(card_id)
	if finish < 0:
		return "%s · the Fellowship's starting Seal" % catalog.sign_seal(card.scribe_sign).display_name
	var key: StringName = ScribeCardResource.copy_key(card_id, finish as ScribeCardResource.CardVariant)
	var spare: int = maxi(0, progress.copies_of(key) - 1)
	return "%s · %s · %d Marks%s" % [catalog.sign_seal(card.scribe_sign).display_name, ScribeCardResource.VARIANT_NAMES[finish],
		progress.marks_of(key), (" · %d spare cop%s" % [spare, "y" if spare == 1 else "ies"]) if spare > 0 else ""]


## What a seal card does in one slot (the Contextual Slot Rule), or "nothing" for none.
func seal_slot_text(card_id: StringName, slot: int) -> String:
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(card_id)
	if card == null:
		return "Nothing: the slot is empty now."
	var flags: Array[int] = [ScribeCardResource.SealSlotMask.SEAL_WEAPON, ScribeCardResource.SealSlotMask.SEAL_OFFHAND_BUCKLER,
		ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR]
	return "%s: %s" % [card.display_name, String(card.slot_passive(flags[clampi(slot, 0, 2)]).get("text", "")).strip_edges()]


## The hero's hand changed (the bench, the host's answer, a level): the rows follow it.
func _on_hand_changed(_hand: PlayerLoadoutResource) -> void:
	if is_inside_tree():
		_refresh()


## What a combo form does, in a sentence a child can follow.
static func combo_tooltip(form: ComboChainResource) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("Press %s in a row" % form.glyphs())
	var finish: PackedStringArray = PackedStringArray()
	finish.append("the last move hits %.1fx as hard" % form.finisher_damage_mult)
	if form.triggers_flank_orbit:
		finish.append("circles you round to the foe's side")
	elif form.evasion_iframes_ms > 0:
		finish.append("vaults you back out of harm's way")
	elif form.step_displacement_m > 0.0:
		finish.append("carries you %.1f m" % form.step_displacement_m)
	if form.breaks_martial_lock:
		finish.append("cracks a guarded foe open")
	if form.stun_duration_sec > 0.0:
		finish.append("stuns for %.1f s" % form.stun_duration_sec)
	var line: String = "%s: %s." % [", ".join(parts), ", ".join(finish)]
	if PartyProgress.current.trail_level() < form.required_level:
		line += " Learned at Level %d." % form.required_level
	return line


## The highlighted card, Place-Card, Tuck or layer (13_PLAYTEST §2.13), in three
## short lines: what it does; when to use it (on the trail, holding its button
## makes your ink ready for the next fight; in a fight, a tap in the flash after
## a hit casts it); and whether your level and binder take it.
func _card_tooltip() -> String:
	match column:
		Column.LEAVES, Column.PLACES, Column.TUCKS:
			var options: Array[StringName] = layer_options(shown_layer())
			return card_tooltip_for(options[clampi(layer_row(shown_layer()), 0, options.size() - 1)], column)
	var socket: int = DIAMOND_ROWS[diamond_row] if DIAMOND_ROWS[diamond_row] >= 0 else selected_socket()
	var cost: String = _cost_words(_socket_cost(socket))
	match socket:
		ScribeCardResource.DioramaSocket.GUARD:
			return "L: the card that rides your guard. It costs %s.\n%s" % [cost, when_to_use(socket, _socket_cost(socket), _on_ink_well())]
		ScribeCardResource.DioramaSocket.SKILL:
			return "R: your skill. It costs %s.\n%s" % [cost, when_to_use(socket, _socket_cost(socket), _on_ink_well())]
	return "L+R together: your Grand card. It costs %s.\n%s" % [cost, when_to_use(socket, _socket_cost(socket), _on_ink_well())]


## One option in the chosen diamond: what it does, when to use it, and whether it fits now.
func card_tooltip_for(copy_key: StringName, page_column: int) -> String:
	var socket: int = selected_socket()
	var when: String = PLACE_WHEN
	if page_column == Column.LEAVES:
		when = when_to_use(socket, _socket_cost(socket), _on_ink_well())
	elif page_column == Column.TUCKS:
		when = TUCK_WHEN
	return "%s\n%s\n%s" % [_option_tooltip(copy_key, page_column), when, fit_line(copy_key, page_column)]


## When a diamond's card is used: on the trail (Trail-Prep) and in a fight (Sign-Flow), and what it costs.
static func when_to_use(socket: int, cost: int = -1, ink: bool = false) -> String:
	var hold: float = SignFlowComponent.HEARTH_RITE_HOLD_FRAMES / SignFlowComponent.FRAMES_PER_SECOND
	var paid: int = cost if cost >= 0 else int(ScribeCardResource.SOCKET_PIP_COSTS[socket])
	var unit: String = "Ink-Drop" if ink else "pip"
	var button: String = ["L", "R", "L+R"][socket]
	var fight: String = "In a fight (Sign-Flow): land a hit, then tap %s in the flash: %s (%d %s%s)." % [button,
		"a counter-brace" if socket == ScribeCardResource.DioramaSocket.GUARD else "it casts at once", paid, unit, "" if paid == 1 else "s"]
	if socket == ScribeCardResource.DioramaSocket.GUARD:
		return fight + " It never readies on the trail."
	return "On the trail (Trail-Prep, no foe near): hold %s for %.0f s: INK READY, and your next fight opens with it. %s" % [button, hold, fight]


## Whether your level and binder take this option in the chosen diamond, or what stands in the way.
func fit_line(copy_key: StringName, page_column: int) -> String:
	var progress: PartyProgress = PartyProgress.current
	var draft: EquipmentLoadoutResource = actor.loadout.kit.copy()
	var socket: int = selected_socket()
	if page_column == Column.LEAVES:
		draft.set_socket_leaf(socket, ScribeCardResource.copy_card_id(copy_key), ScribeCardResource.copy_variant(copy_key))
	elif page_column == Column.TUCKS:
		draft.under_ids[ScribeCardResource.GrimoireSlot.SIGNATURE] = &""
		draft.under_ids[ScribeCardResource.GrimoireSlot.ULTIMATE] = &""
		if copy_key != &"" and socket != GrimoireRules.SOCKET_L:
			draft.under_ids[_tuck_slot_for(socket)] = copy_key
	else:
		draft.set_socket_place(socket, ScribeCardResource.copy_card_id(copy_key), ScribeCardResource.copy_variant(copy_key))
	# The hero's own level (25 GDD R4): a socket it hasn't opened says when; the hand's rules (one Tuck, seven
	# different cards) speak through the composer; a fit says what the card costs from the Ink-Well (R1).
	var level: int = progress.character_level(actor.loadout.class_id)
	if not GrimoireRules.socket_open(socket, level):
		return "Not yet (you're Lv %d): %s." % [level, GrimoireRules.socket_opens_text(socket)]
	if page_column == Column.TUCKS and copy_key != &"":
		if socket == GrimoireRules.SOCKET_L:
			return "Not yet (you're Lv %d): L takes no Tuck." % level
		if not GrimoireRules.tuck_open(level):
			return "Not yet (you're Lv %d): the Tuck opens at Lv %d." % [level, GrimoireRules.TUCK_OPEN_LEVEL]
	var problem: String = LoadoutComposer.kit_problem(_player_class(), draft, progress.grimoire_level(), progress.collection, progress.trail_level())
	if problem != "":
		return "Not yet (you're Lv %d): %s." % [level, problem]
	if page_column == Column.LEAVES:
		var listed: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key))
		var tucked: bool = socket != GrimoireRules.SOCKET_L and draft.under_ids[_tuck_slot_for(socket)] != &""
		var cost: int = GrimoireRules.ink_cost(socket, listed, tucked)
		return "Ready: it fits your hand at Lv %d and costs %d Ink-Drop%s in %s." % [level, cost, "" if cost == 1 else "s",
			GrimoireRules.SOCKET_NAMES[socket]]
	if page_column == Column.TUCKS:
		return "Ready: it slides under %s at Lv %d (one Tuck in the hand)." % [GrimoireRules.SOCKET_NAMES[socket], level]
	return "Ready: it frames this card at Lv %d." % level


## What an option does, in a sentence: its name, how it shows itself and its Ink-Sign, then the card's own words or its effect.
static func _option_tooltip(copy_key: StringName, page_column: int) -> String:
	if copy_key == &"":
		match page_column:
			Column.LEAVES:
				return "Leave it empty: the weapon's own move plays."
			Column.TUCKS:
				return "No Tuck under this card."
		return "No Place-Card round this diamond."
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var listed: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(copy_key))
	if listed == null:
		return ""
	var seal: ScribeSignResource = catalog.sign_seal(listed.scribe_sign)
	var sign_name: String = "%s Ink-Sign" % seal.display_name if listed.scribe_sign != ScribeSignResource.Sign.NONE else "no Ink-Sign"
	var kind: String = "Place-Card" if listed.is_place_card() else ("Tuck" if listed.is_under() else listed.mode_name())
	var told: String = listed.description.strip_edges()
	return "%s (%s, %s): %s" % [listed.display_name, kind, sign_name, told if told != "" else card_effect(listed)]


## What a card does when it's cast, worked out from its numbers.
static func card_effect(listed: ScribeCardResource) -> String:
	var seal: String = ArsenalCatalog.current.sign_seal(listed.scribe_sign).display_name
	if listed.is_place_card():
		var gifts: PackedStringArray = PackedStringArray()
		if listed.location_bonus_reach_m > 0.0:
			gifts.append("+%.1f m reach" % listed.location_bonus_reach_m)
		if listed.location_bonus_poise > 0.0:
			gifts.append("+%d stagger" % roundi(listed.location_bonus_poise))
		if listed.location_bonus_heal > 0.0:
			gifts.append("+%d healing" % roundi(listed.location_bonus_heal))
		if listed.location_stamina_refund > 0.0:
			gifts.append("%d stamina back" % roundi(listed.location_stamina_refund))
		return "frames the card in its diamond with this place's strength%s, and lasts longer near its own landmark." % (
			(": " + ", ".join(gifts)) if not gifts.is_empty() else "")
	match listed.manifestation_mode:
		ScribeCardResource.ManifestationMode.WARD_MANTLE:
			return "wraps you in an Ink Shield: a %s blow does %d%% less, stuns can't stop you, and friends shelter behind you." % [seal,
				roundi(listed.ward_damage_mitigation_pct * 100.0)]
		ScribeCardResource.ManifestationMode.LANTERN_TETHER:
			return "lends the %s down your tether: friends' hits carry it for %d s and crack its locks." % [seal, roundi(listed.coat_duration_sec)]
	return "coats your weapon in %s ink for %d s: every hit carries it and cracks its locks." % [seal, roundi(listed.coat_duration_sec)]


## What the off hand carries, by Fellowship (07 GDD §4.1).
static func off_hand_name(loadout: ClassLoadoutResource) -> String:
	match loadout.role:
		ClassLoadoutResource.Role.TANK:
			return "Greatshield"
		ClassLoadoutResource.Role.HEALER:
			return "Tether-Lantern"
	return "Quiver" if loadout.is_ranged() else "Scribe Satchel"


func _key(action: StringName) -> String:
	return actor.input.label(action) if actor != null and actor.input != null else InputComponent.binding_label(action, InputComponent.KEYBOARD_DEVICE)


func _on_combo_clicked(event: InputEvent, row: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		combo_row = row
		_refresh()


static func _option_text(copy_key: StringName, page_column: int) -> String:
	if copy_key == &"":
		return "Un-inked (the weapon's own flourish)" if page_column == Column.LEAVES else "No Place-Card"
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var listed: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(copy_key))
	var finish: String = ScribeCardResource.VARIANT_NAMES[ScribeCardResource.copy_variant(copy_key)]
	var seal: String = catalog.sign_seal(listed.scribe_sign).display_name
	if listed.is_place_card():
		return "%s  [%s]  %s" % [listed.display_name, seal, finish]
	return "%s  [%s · %s]  %s" % [listed.display_name, seal, listed.mode_name(), finish]


## What the chosen diamond's pair does, in a sentence: Home-Ground Harmony first when it's there.
static func _diorama_text(synergy: Dictionary) -> String:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var leaf: ScribeCardResource = catalog.card(synergy["action_card_id"])
	var place: ScribeCardResource = catalog.card(synergy["location_card_id"])
	var parts: PackedStringArray = PackedStringArray()
	parts.append(leaf.display_name if leaf != null else "Un-inked")
	parts.append("framed by %s" % place.display_name if place != null else "no Place-Card")
	var lent: PackedStringArray = PackedStringArray()
	if synergy["bonus_poise"] > 0.0:
		lent.append("+%d poise" % roundi(synergy["bonus_poise"]))
	if synergy["bonus_reach_m"] > 0.0:
		lent.append("+%.1f m reach" % synergy["bonus_reach_m"])
	if synergy["bonus_heal"] > 0.0:
		lent.append("mends friends %d" % roundi(synergy["bonus_heal"]))
	if synergy["stamina_refund"] > 0.0:
		lent.append("+%d stamina per Flow-Link" % roundi(synergy["stamina_refund"]))
	var line: String = " ".join(parts)
	if not lent.is_empty():
		line += ": " + ", ".join(lent)
	if synergy["is_home_ground_harmony"]:
		line = "★ HOME-GROUND HARMONY  " + line + "  ·  coat %.1f s" % synergy["coat_duration_sec"]
	else:
		line += "  ·  coat %.1f s" % synergy["coat_duration_sec"]
	return line


## The Combo Forms page: each directional form, its postures, and the trail level that teaches the rest.
static func combo_forms_text() -> String:
	var level: int = PartyProgress.current.trail_level()
	var lines: PackedStringArray = PackedStringArray()
	for form: ComboChainResource in ArsenalCatalog.current.combos():
		if level >= form.required_level:
			lines.append("✓ %s:  %s" % [form.display_name, form.glyphs()])
		else:
			lines.append("  Lv %d: %s (still to learn)" % [form.required_level, form.display_name])
	return "\n".join(lines)


## Every Action-Leaf and Place-Card: found ones with the finishes the party has, unfound ones as a riddle.
static func _folio_text() -> String:
	var progress: PartyProgress = PartyProgress.current
	var lines: PackedStringArray = PackedStringArray()
	var found: int = 0
	var listed: Array[ScribeCardResource] = ArsenalCatalog.current.action_leaves()
	listed.append_array(ArsenalCatalog.current.place_cards())
	for card: ScribeCardResource in listed:
		var finishes: PackedStringArray = PackedStringArray()
		for variant: int in ScribeCardResource.CardVariant.size():
			if progress.owns_card(card.card_id, variant):
				finishes.append(ScribeCardResource.VARIANT_NAMES[variant])
		if finishes.is_empty():
			lines.append("  ? ? ?   [%s]" % ArsenalCatalog.current.sign_seal(card.scribe_sign).display_name)
		else:
			found += 1
			lines.append("  %s: %s" % [card.display_name, " · ".join(finishes)])
	return "INK CARD COLLECTION: %d of %d found\n%s" % [found, listed.size(), "\n".join(lines)]


func _player_class() -> PlayerClassResource:
	return ClassLoadouts.player_class(actor.loadout.class_id, actor.loadout.calling)


func _page(heading: String) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(PAGE_WIDTH, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = AtelierTheme.page_style()
	style.set_content_margin_all(12.0)
	panel.add_theme_stylebox_override(&"panel", style)
	var column_box: VBoxContainer = VBoxContainer.new()
	column_box.add_theme_constant_override(&"separation", 3)
	column_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column_box)
	var title: Label = _label(FONT_SIZE + 2, PAGE_EDGE.lightened(0.25))
	title.text = heading
	column_box.add_child(title)
	return column_box


func _label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override(&"outline_size", 4)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

