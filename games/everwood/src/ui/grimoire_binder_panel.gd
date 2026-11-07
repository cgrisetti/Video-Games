## The Grimoire Binder (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §6), opened out of
## combat with a tap of Tab / View on the player's own screen. Since the Phase
## 12 Kaizen pass (K4) it has numbered tabs, plus the Atlas Map, stepped
## with Q / E on the keyboard or L / R on a pad (or a click on the tab):
##
##   [1. Gear & Weapon]           the hero turning slowly in a lit preview
##                                window (the live hero, not a copy), with
##                                their weapon and its tier, off-hand, armour
##                                and Calling; change them at the Scribe Desk
##   [2. Quick Magic-Ink Cards]   the spread it opens on: the HUD's diamonds
##                                grow to 2.2x between two pages, Ink Cards
##                                (what you do) on the left and Place-Cards
##                                (where you stand) on the right; the middle
##                                column picks the diamond (L+R, L, R) or opens
##                                the Ink Card Collection
##   [3. Combo Moves]             the directional forms the party knows, with
##                                their buttons, and the ones still to learn
##   [4. Seals & Pocket Cards]    the stamping bench beside the same live
##                                preview: the three seals pressed on the
##                                weapon, off-hand and mantle, and the four
##                                pocket cards (L, its tuck, R, its tuck);
##                                up / down picks a slot, left / right (or
##                                light) changes its card among none, the
##                                Fellowship's starting seal and every seal
##                                card the party owns; the hero wears it at
##                                once and the host keeps it for the
##                                Fellowship (EquipmentSealComponent.choose_hand).
##                                A slot the ladder hasn't opened is locked and
##                                says when it opens
##
## A tooltip box under the tabs says what the tab is for and what the
## highlighted row does, in plain words, for a pad as much as the mouse (rows
## and tabs carry the same text as mouse tooltips too).
##
## On the cards tab: left / right moves between the pages and the diamonds,
## up / down along them, light picks, dodge (or Tab again) closes. The mouse
## works too: click a diamond, then a card. A change the kit's rules allow is
## equipped at once through the host, as the Scribe Desk does; otherwise the
## binder says why.
##
## The Atlas Map tab (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §7.3)
## turns the spread into the Wayfarer's Atlas (a tap of M / R3, or a click on the
## tab); dodge there turns back to the tab you came from.
##
## The preview's lighting is its own: the camera carries a brighter copy of the
## sky and fog with the far world softly blurred, and a warm key light and a
## cool rim light reach only the hero (light cull layer 13, which the hero's
## meshes wear while the Gear tab shows).
class_name GrimoireBinderPanel
extends Control

signal closed

enum Column { LEAVES, DIAMONDS, PLACES }
enum Tab { GEAR, CARDS, COMBOS, SEALS, ATLAS }
const TAB_NAMES: Array[String] = ["1. Gear & Weapon", "2. Quick Magic-Ink Cards", "3. Combo Moves", "4. Seals & Pocket Cards", "Atlas Map"]
## What each tab is for, in the tooltip box and as the tab's mouse tooltip.
const TAB_TOOLTIPS: Array[String] = [
	"Your hero, your weapon and what you wear. Change them at the Scribe Desk in town.",
	"Slot Ink Cards into your diamonds: L guards, R is your skill, L+R your big move. A Place-Card framing a card makes it stronger.",
	"Button patterns your hero has learned. Play one in a row and its last move hits harder.",
	"Press seal cards onto your weapon, off-hand and mantle, and choose the cards you pull from your pocket after a hit. Your hero wears them at once.",
	"The Wayfarer's Atlas: where you are, and where to go next.",
]
## A Place-Card's "when": it rides with the diamond's Ink Card.
const PLACE_WHEN: String = "It rides with the Ink Card in this diamond: on the trail (INK READY) and in every cast in a fight."
## The Gear & Weapon tab's rows.
enum GearRow { WEAPON, OFF_HAND, ARMOR, CALLING }
## The stamping bench's slot shapes: a pressed card, an open empty slot, a slot still locked.
const SEAL_PRESSED: String = "◆"
const SEAL_EMPTY: String = "◇"
const SEAL_LOCKED: String = "▢"
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

const PAGE_WIDTH: float = 330.0
const TITLE_SIZE: int = 24
const FONT_SIZE: int = 15
const SMALL_FONT_SIZE: int = 12
const TOOLTIP_FONT_SIZE: int = 14
## The panel is laid out for a cell this big and scales with the player's cell.
const REFERENCE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const MIN_FIT: float = 0.45
const BACKDROP: Color = Color(0.03, 0.03, 0.05, 0.72)
const PAGE_COLOR: Color = Color(0.13, 0.1, 0.08, 0.94)
const PAGE_EDGE: Color = Color(0.85, 0.7, 0.42)
const TOOLTIP_COLOR: Color = Color(0.2, 0.16, 0.1, 0.94)
const SELECTED_COLOR: Color = Color(1.0, 0.88, 0.5)
const ROW_COLOR: Color = Color(0.95, 0.92, 0.85)
const DIM_COLOR: Color = Color(0.6, 0.58, 0.55)
const PROBLEM_COLOR: Color = Color(1.0, 0.55, 0.45)
const HARMONY_COLOR: Color = Color(1.0, 0.85, 0.35)
const NOTE_TIME: float = 2.5
## The middle column's rows, top to bottom: the three diamonds as they sit in the cross, then the Collection.
const DIAMOND_ROWS: Array[int] = [ScribeCardResource.DioramaSocket.ULT, ScribeCardResource.DioramaSocket.GUARD,
	ScribeCardResource.DioramaSocket.SKILL, -1]
## The live preview: its window, the camera's orbit round the hero, and its lights.
const PREVIEW_SIZE: Vector2i = Vector2i(300, 380)
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
var column: int = Column.DIAMONDS
var leaf_row: int = 0
var place_row: int = 0
var diamond_row: int = 2
var gear_row: int = GearRow.WEAPON
var combo_row: int = 0
## The stamping bench's highlighted slot (PlayerLoadoutResource.HandSlot).
var seal_row: int = PlayerLoadoutResource.HandSlot.WEAPON_SEAL
var folio_open: bool = false
var tab: int = Tab.CARDS
var atlas: WorldMapPanel
## The live preview on the Gear & Weapon tab.
var preview_viewport: SubViewport
var preview_camera: Camera3D
var key_light: SpotLight3D
var rim_light: OmniLight3D
var _tab_labels: Array[Label] = []
## The tab the Atlas turns back to.
var _page_tab: int = Tab.CARDS
var _preview_angle: float = 0.0
var _lit: Array[GeometryInstance3D] = []

var _root: Control
var _tabs: HBoxContainer
## The tallest page seen, so every tab's page (and the tab bar over it) starts on the same line.
var _tallest: float = 0.0
var _title: Label
var _tooltip: Label
var _pages: Array[Control] = []
var _leaf_page: VBoxContainer
var _place_page: VBoxContainer
var _leaf_rows: Array[Label] = []
var _place_rows: Array[Label] = []
var _gear_rows: Array[Label] = []
var _gear_stats: Label
## The Gear & Weapon page and the stamping bench share one row with the live preview.
var _gear_panel: Control
var _seal_panel: Control
var _seal_rows: Array[Label] = []
var _seal_stats: Label
var _combo_rows: Array[Label] = []
var _detail: Label
var _note: Label
var _hint: Label
var _folio: Label
var _note_left: float = 0.0


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
	_root = VBoxContainer.new()
	_root.name = "Spread"
	_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_theme_constant_override(&"separation", 8)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_title = _label(TITLE_SIZE, PAGE_EDGE.lightened(0.3))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_title)
	_root.add_child(_build_tooltip())
	_pages.append(_build_gear_page())
	_pages.append(_build_cards_page())
	_pages.append(_build_combo_page())
	for page: Control in _pages:
		_root.add_child(page)
	_note = _label(FONT_SIZE, PROBLEM_COLOR)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_note)
	_hint = _label(SMALL_FONT_SIZE, Color(0.82, 0.84, 0.9))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_hint)
	# The tabs, just above the title (clear of the level's notices along the top of the screen).
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override(&"separation", 22)
	add_child(tabs)
	_tabs = tabs
	for index: int in TAB_NAMES.size():
		var tab_label: Label = _label(FONT_SIZE + 2, ROW_COLOR)
		tab_label.text = TAB_NAMES[index]
		tab_label.tooltip_text = TAB_TOOLTIPS[index]
		tab_label.mouse_filter = Control.MOUSE_FILTER_STOP
		tab_label.gui_input.connect(_on_tab_clicked.bind(index))
		tabs.add_child(tab_label)
		_tab_labels.append(tab_label)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(_on_menu_input)
	if actor != null and actor.seal != null:
		actor.seal.loadout_changed.connect(_on_hand_changed)
	PartyProgress.current.progress_changed.connect(_refresh)
	NetworkManager.current.kit_refused.connect(_on_kit_refused)
	NetworkManager.current.seal_hand_refused.connect(_on_kit_refused)
	_show_page(Tab.CARDS)


## The tooltip box under the title: what the tab is for and what the highlighted row does.
func _build_tooltip() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Tooltip"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(PAGE_WIDTH * 2.6, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = TOOLTIP_COLOR
	style.border_color = PAGE_EDGE.darkened(0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override(&"panel", style)
	_tooltip = _label(TOOLTIP_FONT_SIZE, ROW_COLOR)
	_tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip.custom_minimum_size = Vector2(PAGE_WIDTH * 2.6 - 16.0, 0.0)
	panel.add_child(_tooltip)
	return panel


## Tab 1: the lit preview window beside the gear rows. Tab 4's stamping bench shares the row and the
## preview, standing where the gear rows stand.
func _build_gear_page() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "GearPage"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_build_preview())
	var page: VBoxContainer = _page("Gear & Weapon")
	for index: int in GearRow.size():
		var gear: Label = _label(FONT_SIZE, ROW_COLOR)
		gear.mouse_filter = Control.MOUSE_FILTER_STOP
		gear.gui_input.connect(_on_gear_clicked.bind(index))
		page.add_child(gear)
		_gear_rows.append(gear)
	_gear_stats = _label(SMALL_FONT_SIZE, DIM_COLOR.lightened(0.2))
	page.add_child(_gear_stats)
	_gear_panel = page.get_parent() as Control
	row.add_child(_gear_panel)
	_seal_panel = _build_seal_bench()
	row.add_child(_seal_panel)
	return row


## Tab 4: the stamping bench, a row per slot of the hand: the three seals on the gear, then the four pocket cards.
func _build_seal_bench() -> Control:
	var page: VBoxContainer = _page("Seals & Pocket Cards")
	var panel: Control = page.get_parent() as Control
	panel.name = "SealBench"
	panel.custom_minimum_size = Vector2(PAGE_WIDTH * 1.45, 0.0)
	for slot: int in PlayerLoadoutResource.HAND_SLOT_COUNT:
		if slot == PlayerLoadoutResource.HandSlot.WEAPON_SEAL or slot == PlayerLoadoutResource.HandSlot.L_PRIMARY:
			var heading: Label = _label(SMALL_FONT_SIZE, PAGE_EDGE.lightened(0.15))
			heading.text = "Seals on your gear" if slot == PlayerLoadoutResource.HandSlot.WEAPON_SEAL else "Pocket cards: pull one after a hit"
			page.add_child(heading)
		var line: Label = _label(FONT_SIZE, ROW_COLOR)
		line.mouse_filter = Control.MOUSE_FILTER_STOP
		line.gui_input.connect(_on_seal_clicked.bind(slot))
		page.add_child(line)
		_seal_rows.append(line)
	_seal_stats = _label(SMALL_FONT_SIZE, DIM_COLOR.lightened(0.2))
	page.add_child(_seal_stats)
	panel.visible = false
	return panel


## The live preview: a window on the shared world, framed like a page.
func _build_preview() -> Control:
	var frame: PanelContainer = PanelContainer.new()
	frame.name = "Preview"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAGE_COLOR
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


## Tab 2: the spread of Ink Cards, diamonds and Place-Cards, with the pair's line and the Collection under it.
func _build_cards_page() -> Control:
	var column_box: VBoxContainer = VBoxContainer.new()
	column_box.name = "CardsPage"
	column_box.add_theme_constant_override(&"separation", 8)
	column_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spread: HBoxContainer = HBoxContainer.new()
	spread.alignment = BoxContainer.ALIGNMENT_CENTER
	spread.add_theme_constant_override(&"separation", 18)
	spread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column_box.add_child(spread)
	_leaf_page = _page("Ink Cards: What You Do")
	spread.add_child(_leaf_page.get_parent())
	widget = CrossGrimoireDiamondWidget.new()
	widget.name = "Diamonds"
	widget.follow = actor
	widget.set_presentation_mode(CrossGrimoireDiamondWidget.BINDER_SCALE, true)
	widget.grow_from(CrossGrimoireDiamondWidget.HUD_SCALE)
	widget.socket_picked.connect(_on_socket_picked)
	spread.add_child(widget)
	_place_page = _page("Place-Cards: Where You Stand")
	spread.add_child(_place_page.get_parent())
	_detail = _label(FONT_SIZE, ROW_COLOR)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column_box.add_child(_detail)
	_folio = _label(SMALL_FONT_SIZE, ROW_COLOR)
	_folio.visible = false
	column_box.add_child(_folio)
	return column_box


## Tab 3: one row per combo form.
func _build_combo_page() -> Control:
	var page: VBoxContainer = _page("Combo Moves: How You Flow")
	var panel: Control = page.get_parent() as Control
	panel.name = "CombosPage"
	panel.custom_minimum_size = Vector2(PAGE_WIDTH * 2.0, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for form: ComboChainResource in ArsenalCatalog.current.combos():
		var row: Label = _label(FONT_SIZE, ROW_COLOR)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_combo_clicked.bind(_combo_rows.size()))
		page.add_child(row)
		_combo_rows.append(row)
	return panel


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
	var fit: float = clampf(minf(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y), MIN_FIT, 1.0)
	_root.scale = Vector2.ONE * fit
	_root.size = _root.get_combined_minimum_size()
	if _root.visible:
		_tallest = maxf(_tallest, _root.size.y)
	_tabs.scale = Vector2.ONE * fit
	_tabs.size = _tabs.get_combined_minimum_size()
	var top: float = maxf((_tabs.size.y + 18.0) * fit, (size.y - _tallest * fit) * 0.5)
	_root.position = Vector2((size.x - _root.size.x * fit) * 0.5, top)
	_tabs.position = Vector2((size.x - _tabs.size.x * fit) * 0.5, top - (_tabs.size.y + 10.0) * fit)
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


static func _owned_copies(listed: ScribeCardResource) -> Array[StringName]:
	var copies: Array[StringName] = []
	for variant: int in ScribeCardResource.CardVariant.size():
		var key: StringName = ScribeCardResource.copy_key(listed.card_id, variant as ScribeCardResource.CardVariant)
		if LoadoutComposer.owns(key, 1, PartyProgress.current.collection):
			copies.append(key)
	return copies


# --- Moving and picking ---------------------------------------------------------

func _on_menu_input(action: StringName) -> void:
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
		close()
		return
	match tab:
		Tab.GEAR:
			if action == InputComponent.MENU_UP or action == InputComponent.MENU_DOWN:
				gear_row = wrapi(gear_row + (-1 if action == InputComponent.MENU_UP else 1), 0, GearRow.size())
			elif action == InputComponent.MENU_ACCEPT:
				_show_note("Change your gear at the Scribe Desk in town.")
		Tab.COMBOS:
			if action == InputComponent.MENU_UP or action == InputComponent.MENU_DOWN:
				combo_row = wrapi(combo_row + (-1 if action == InputComponent.MENU_UP else 1), 0, maxi(1, _combo_rows.size()))
		Tab.SEALS:
			match action:
				InputComponent.MENU_UP, InputComponent.MENU_DOWN:
					seal_row = wrapi(seal_row + (-1 if action == InputComponent.MENU_UP else 1), 0, PlayerLoadoutResource.HAND_SLOT_COUNT)
				InputComponent.MENU_LEFT:
					step_seal(-1)
				InputComponent.MENU_RIGHT, InputComponent.MENU_ACCEPT:
					step_seal(1)
		_:
			match action:
				InputComponent.MENU_LEFT:
					column = maxi(Column.LEAVES, column - 1)
				InputComponent.MENU_RIGHT:
					column = mini(Column.PLACES, column + 1)
				InputComponent.MENU_UP:
					_move(-1)
				InputComponent.MENU_DOWN:
					_move(1)
				InputComponent.MENU_ACCEPT:
					accept()
	AudioCues.play(&"menu_move")
	_refresh()


func _move(step: int) -> void:
	match column:
		Column.LEAVES:
			leaf_row = wrapi(leaf_row + step, 0, leaf_options().size())
		Column.PLACES:
			place_row = wrapi(place_row + step, 0, place_options().size())
		Column.DIAMONDS:
			diamond_row = wrapi(diamond_row + step, 0, DIAMOND_ROWS.size())
			if DIAMOND_ROWS[diamond_row] >= 0:
				_select_socket(DIAMOND_ROWS[diamond_row])


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
	move_child(get_node("Tabs"), -1)
	_refresh_tabs()
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
		_pages[page].visible = page == (Tab.GEAR if index == Tab.SEALS else index)
	_gear_panel.visible = index != Tab.SEALS
	_seal_panel.visible = index == Tab.SEALS
	_light_hero(_shows_preview(index))
	if _shows_preview(index):
		_place_preview()
	_refresh_tabs()
	_refresh()


func _on_tab_clicked(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		show_tab(index)


func _refresh_tabs() -> void:
	for index: int in _tab_labels.size():
		_tab_labels[index].modulate = SELECTED_COLOR if index == tab else DIM_COLOR
		_tab_labels[index].text = ("◆ %s" if index == tab else "%s") % TAB_NAMES[index]


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


## Light: slot the highlighted leaf or place into the chosen diamond, or pick a diamond, or open the Folio.
func accept() -> void:
	match column:
		Column.LEAVES:
			slot_leaf(leaf_options()[clampi(leaf_row, 0, leaf_options().size() - 1)])
		Column.PLACES:
			slot_place(place_options()[clampi(place_row, 0, place_options().size() - 1)])
		Column.DIAMONDS:
			if DIAMOND_ROWS[diamond_row] < 0:
				folio_open = not folio_open
			else:
				column = Column.LEAVES


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
	diamond_row = DIAMOND_ROWS.find(socket)
	_refresh()


func _select_socket(socket: int) -> void:
	widget.selected_socket = socket
	leaf_row = 0
	place_row = 0


func _on_row_clicked(event: InputEvent, page: int, row: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	column = page
	if page == Column.LEAVES:
		leaf_row = row
	else:
		place_row = row
	accept()
	_refresh()


func _on_kit_refused(device_id: int, reason: String) -> void:
	if is_instance_valid(actor) and device_id == actor.device_id:
		_show_note(reason)


func _show_note(text: String) -> void:
	_note.text = text
	_note_left = NOTE_TIME


# --- Drawing the pages ------------------------------------------------------------

func _refresh() -> void:
	if not is_instance_valid(actor) or widget == null:
		return
	var chimes: int = PartyProgress.current.chimes
	var tabs: String = "%s / %s: tabs" % [_key(InputComponent.ACTION_TRIGGER_L), _key(InputComponent.ACTION_TRIGGER_R)]
	match tab:
		Tab.GEAR:
			_title.text = "GRIMOIRE BINDER  ·  %s  ·  %d Chimes" % [actor.loadout.display_name, chimes]
			_refresh_gear()
			_hint.text = "%s  ·  ↑/↓ look over your gear  ·  dodge or Tab closes" % tabs
		Tab.COMBOS:
			_title.text = "GRIMOIRE BINDER  ·  Combo Moves  ·  %d Chimes" % chimes
			_refresh_combos()
			_hint.text = "%s  ·  ↑/↓ choose a move  ·  dodge or Tab closes" % tabs
		Tab.SEALS:
			_title.text = "GRIMOIRE BINDER  ·  Seals & Pocket Cards  ·  %d Chimes" % chimes
			_refresh_seals()
			_hint.text = "%s  ·  ↑/↓ choose a slot  ·  ←/→ or light change its card  ·  dodge or Tab closes" % tabs
		_:
			_refresh_cards(chimes, tabs)
	_tooltip.text = tooltip_text_now()
	widget.queue_redraw()


func _refresh_cards(chimes: int, tabs: String) -> void:
	var socket: int = selected_socket()
	_title.text = "GRIMOIRE BINDER  ·  %s  ·  %d Chimes" % [ScribeCardResource.SOCKET_NAMES[socket], chimes]
	var leaves: Array[StringName] = leaf_options()
	var places: Array[StringName] = place_options()
	leaf_row = clampi(leaf_row, 0, leaves.size() - 1)
	place_row = clampi(place_row, 0, places.size() - 1)
	_fill_rows(_leaf_page, _leaf_rows, leaves, Column.LEAVES, leaf_row, actor.loadout.kit.socket_leaf_id(socket), actor.loadout.kit.socket_leaf_variant(socket))
	_fill_rows(_place_page, _place_rows, places, Column.PLACES, place_row, actor.loadout.kit.place_ids[socket], actor.loadout.kit.socket_place_variant(socket))
	# Preview what's highlighted in the chosen diamond.
	var view: Dictionary = widget.socket_view(socket)
	widget.clear_preview()
	match column:
		Column.LEAVES:
			var key: StringName = leaves[leaf_row]
			widget.preview_socket(socket, ScribeCardResource.copy_card_id(key), ScribeCardResource.copy_variant(key), view["place"], view["place_variant"])
		Column.PLACES:
			var key: StringName = places[place_row]
			widget.preview_socket(socket, view["leaf"], view["leaf_variant"], ScribeCardResource.copy_card_id(key), ScribeCardResource.copy_variant(key))
	_detail.text = _diorama_text(widget.socket_view(socket)["synergy"])
	_detail.modulate = HARMONY_COLOR if widget.socket_view(socket)["synergy"]["is_home_ground_harmony"] else ROW_COLOR
	_folio.visible = folio_open
	if folio_open:
		_folio.text = _folio_text()
	var middle: String = "Ink Card Collection" if DIAMOND_ROWS[diamond_row] < 0 else ScribeCardResource.SOCKET_NAMES[DIAMOND_ROWS[diamond_row]]
	_hint.text = "%s  ·  %s  ·  ←/→ pages and diamonds · ↑/↓ choose · light picks · dodge or Tab closes" % [tabs,
		("> " + middle) if column == Column.DIAMONDS else ["Ink Cards", "", "Place-Cards"][column]]


func _refresh_gear() -> void:
	var loadout: ClassLoadoutResource = actor.loadout
	var weapon: EquipmentItemResource = loadout.weapon
	var texts: Array[String] = [
		"Weapon:  %s" % (("%s  (Tier %s)" % [weapon.display_name, CrossGrimoireDiamondWidget.TIER_NUMERALS[clampi(weapon.equipment_tier, 0, 4)]]) if weapon != null else "Hands"),
		"Off-hand:  %s" % off_hand_name(loadout),
		"Armour:  %s" % (loadout.armor.display_name if loadout.armor != null else "None"),
		"Calling:  %s" % loadout.display_name,
	]
	for index: int in _gear_rows.size():
		var row: Label = _gear_rows[index]
		row.text = ("> " if index == gear_row else "  ") + texts[index]
		row.modulate = SELECTED_COLOR if index == gear_row else ROW_COLOR
		row.tooltip_text = gear_tooltip(index)
	if loadout.stats != null:
		_gear_stats.text = "Health %d  ·  Stamina %d  ·  Perfect guard %.2f s" % [roundi(actor.stats.stats.max_health), roundi(actor.stats.stats.max_stamina),
			loadout.stats.perfect_guard_window]


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


## What a gear row means, in a sentence.
func gear_tooltip(row: int) -> String:
	var loadout: ClassLoadoutResource = actor.loadout
	match row:
		GearRow.WEAPON:
			var weapon: EquipmentItemResource = loadout.weapon
			if weapon == null:
				return "No weapon: your fists."
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


## The stamping bench's rows: each slot, its card (or none), and the shape that says which.
func _refresh_seals() -> void:
	for slot: int in _seal_rows.size():
		var line: Label = _seal_rows[slot]
		line.text = ("> " if slot == seal_row else "  ") + seal_row_text(slot)
		line.modulate = SELECTED_COLOR if slot == seal_row else (ROW_COLOR if seal_slot_open(slot) else DIM_COLOR)
		line.tooltip_text = seal_tooltip(slot)
	if actor.seal == null or actor.seal.loadout == null:
		_seal_stats.text = ""
		return
	var hand: PlayerLoadoutResource = actor.seal.loadout
	var tier: EquipmentTierResource = actor.seal.tier()
	_seal_stats.text = "Stage %d · Lv %d · %s gear  ·  %d seals, %d pocket cards" % [actor.seal.progression_stage, actor.seal.true_level,
		tier.weapon_material_name if tier != null else "Orchard-Wood", hand.seal_count(), hand.active_count()]


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
	return "%s:  %s %s  [%s]%s" % [slot_name, SEAL_PRESSED, listed.display_name, ArsenalCatalog.current.sign_seal(listed.scribe_sign).display_name,
		"  (starter)" if lent else ""]


## What a slot of the hand does, and what is in it; a locked slot says when it opens.
func seal_tooltip(slot: int) -> String:
	if actor.seal == null:
		return ""
	var slot_name: String = PlayerLoadoutResource.HAND_SLOT_NAMES[slot]
	if not seal_slot_open(slot):
		return "Locked: the %s slot %s. Your party is Lv %d." % [slot_name, PlayerLoadoutResource.slot_opens_text(slot), actor.seal.true_level]
	var tip: String = SEAL_SLOT_TIPS[slot]
	if not PlayerLoadoutResource.is_seal_slot(slot):
		var on_l: bool = slot == PlayerLoadoutResource.HandSlot.L_PRIMARY or slot == PlayerLoadoutResource.HandSlot.L_TUCK
		var key: String = _key(InputComponent.ACTION_TRIGGER_L if on_l else InputComponent.ACTION_TRIGGER_R)
		tip = tip % ([key, key] if tip.count("%s") == 2 else [key])
	var listed: ScribeCardResource = ArsenalCatalog.current.get_card(actor.seal.loadout.card_in_slot(slot)) if actor.seal.loadout != null else null
	if listed == null:
		return "%s Empty: ←/→ presses a card here." % tip
	return "%s %s" % [tip, listed.description.strip_edges()]


# --- The stamping bench ------------------------------------------------------------

## The cards a slot of the hand cycles through: none (&""), the Fellowship's starting seal, then every seal card the party owns.
func seal_options(slot: int) -> Array[StringName]:
	return ArsenalCatalog.current.seal_options_for_slot(actor.role(), slot, PartyProgress.current.collection)


## Whether a slot of the hand is open at the hero's stage and level.
func seal_slot_open(slot: int) -> bool:
	return is_instance_valid(actor) and actor.seal != null and PlayerLoadoutResource.slot_open(slot, actor.seal.progression_stage, actor.seal.true_level)


## Left / right (or light) on the bench: the highlighted slot's next (or previous) card, pressed at
## once if it fits. A locked slot refuses and says when it opens. Returns whether the hero now wears it.
func step_seal(step: int) -> bool:
	if not is_instance_valid(actor) or actor.seal == null or actor.seal.loadout == null:
		return false
	if not seal_slot_open(seal_row):
		_show_note("The %s slot %s" % [PlayerLoadoutResource.HAND_SLOT_NAMES[seal_row], PlayerLoadoutResource.slot_opens_text(seal_row)])
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
	# One card, one place (22 GDD R5): pressing a seal already on another piece moves it here.
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


func _on_seal_clicked(event: InputEvent, slot: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		seal_row = slot
		step_seal(1)
		_refresh()


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


## The highlighted Ink Card, Place-Card or diamond (13_PLAYTEST §2.13), in three
## short lines: what it does; when to use it (on the trail, holding its button
## makes your ink ready for the next fight; in a fight, a tap in the flash after
## a hit casts it); and whether your level and binder take it.
func _card_tooltip() -> String:
	match column:
		Column.LEAVES:
			var leaves: Array[StringName] = leaf_options()
			return card_tooltip_for(leaves[clampi(leaf_row, 0, leaves.size() - 1)], Column.LEAVES)
		Column.PLACES:
			var places: Array[StringName] = place_options()
			return card_tooltip_for(places[clampi(place_row, 0, places.size() - 1)], Column.PLACES)
	var socket: int = DIAMOND_ROWS[diamond_row]
	match socket:
		ScribeCardResource.DioramaSocket.GUARD:
			return "L: the card that rides your guard.\n" + when_to_use(socket)
		ScribeCardResource.DioramaSocket.SKILL:
			return "R: your skill. It costs one pip.\n" + when_to_use(socket)
		ScribeCardResource.DioramaSocket.ULT:
			return "L+R together: your big move. It costs three pips.\n" + when_to_use(socket)
	return "Every Ink Card and Place-Card you've found, and the ones still out there."


## One option in the chosen diamond: what it does, when to use it, and whether it fits now.
func card_tooltip_for(copy_key: StringName, page_column: int) -> String:
	var socket: int = selected_socket()
	var when: String = when_to_use(socket) if page_column == Column.LEAVES else PLACE_WHEN
	return "%s\n%s\n%s" % [_option_tooltip(copy_key, page_column), when, fit_line(copy_key, page_column)]


## When a diamond's card is used: on the trail (Trail-Prep) and in a fight (Sign-Flow).
static func when_to_use(socket: int) -> String:
	var hold: float = SignFlowComponent.HEARTH_RITE_HOLD_FRAMES / SignFlowComponent.FRAMES_PER_SECOND
	var pips: int = int(ScribeCardResource.SOCKET_PIP_COSTS[socket])
	var button: String = ["L", "R", "L+R"][socket]
	var fight: String = "In a fight (Sign-Flow): land a hit, then tap %s in the flash: %s (%d pip%s)." % [button,
		"a counter-brace" if socket == ScribeCardResource.DioramaSocket.GUARD else "it casts at once", pips, "" if pips == 1 else "s"]
	if socket == ScribeCardResource.DioramaSocket.GUARD:
		return fight + " It never readies on the trail."
	return "On the trail (Trail-Prep, no foe near): hold %s for %.0f s: INK READY, and your next fight opens with it. %s" % [button, hold, fight]


## Whether your level and binder take this option in the chosen diamond, or what stands in the way.
func fit_line(copy_key: StringName, page_column: int) -> String:
	var progress: PartyProgress = PartyProgress.current
	var draft: EquipmentLoadoutResource = actor.loadout.kit.copy()
	if page_column == Column.LEAVES:
		draft.set_socket_leaf(selected_socket(), ScribeCardResource.copy_card_id(copy_key), ScribeCardResource.copy_variant(copy_key))
	else:
		draft.set_socket_place(selected_socket(), ScribeCardResource.copy_card_id(copy_key), ScribeCardResource.copy_variant(copy_key))
	var problem: String = LoadoutComposer.kit_problem(_player_class(), draft, progress.grimoire_level(), progress.collection, progress.trail_level())
	if problem != "":
		return "Not yet (you're Level %d, Grimoire Lv %d): %s." % [progress.trail_level(), progress.grimoire_level(), problem]
	return "Ready: it fits your binder at Level %d (Grimoire Lv %d)." % [progress.trail_level(), progress.grimoire_level()]


## What an option does, in a sentence: its name, how it shows itself and its Ink-Sign, then the card's own words or its effect.
static func _option_tooltip(copy_key: StringName, page_column: int) -> String:
	if copy_key == &"":
		return "Leave it empty: the weapon's own move plays." if page_column == Column.LEAVES else "No Place-Card round this diamond."
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var listed: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(copy_key))
	if listed == null:
		return ""
	var seal: ScribeSignResource = catalog.sign_seal(listed.scribe_sign)
	var sign_name: String = "%s Ink-Sign" % seal.display_name if listed.scribe_sign != ScribeSignResource.Sign.NONE else "no Ink-Sign"
	var kind: String = "Place-Card" if listed.is_place_card() else listed.mode_name()
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


func _on_gear_clicked(event: InputEvent, row: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		gear_row = row
		_refresh()


func _on_combo_clicked(event: InputEvent, row: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		combo_row = row
		_refresh()


func _fill_rows(page: VBoxContainer, rows: Array[Label], options: Array[StringName], page_column: int, cursor: int,
		worn_id: StringName, worn_variant: int) -> void:
	while rows.size() < options.size():
		var row: Label = _label(FONT_SIZE, ROW_COLOR)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_clicked.bind(page_column, rows.size()))
		page.add_child(row)
		rows.append(row)
	for index: int in rows.size():
		var row: Label = rows[index]
		row.visible = index < options.size()
		if not row.visible:
			continue
		var key: StringName = options[index]
		var worn: bool = ScribeCardResource.copy_card_id(key) == worn_id and (key == &"" or ScribeCardResource.copy_variant(key) == worn_variant)
		var mark: String = "> " if column == page_column and index == cursor else "  "
		row.text = "%s%s%s" % [mark, _option_text(key, page_column), "  (worn)" if worn else ""]
		row.tooltip_text = card_tooltip_for(key, page_column)
		row.modulate = SELECTED_COLOR if column == page_column and index == cursor else (ROW_COLOR if worn or key != &"" else DIM_COLOR)


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
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAGE_COLOR
	style.border_color = PAGE_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
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
