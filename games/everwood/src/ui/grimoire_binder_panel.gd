## The Grimoire Binder (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §6), opened out of
## combat with a tap of Tab / View on the player's own screen. The HUD's
## Cross-Grimoire diamonds grow to 2.2x in the middle, between two pages:
##   left   "Action-Leaves: What You Do"   picking one slots it into the
##          chosen diamond's inner portrait
##   right  "Place-Cards: Where You Stand"  picking one frames the chosen
##          diamond, with a Home-Ground Harmony preview when the Signs match
## The middle column picks the diamond (L+R, L, R) or opens the Collection
## Folio: every card and finish, found or still to find.
##
## Left / right moves between the pages and the diamonds, up / down along
## them, light picks, dodge (or Tab again) closes. The mouse works too: click a
## diamond, then a card. A change the kit's rules allow is equipped at once
## through the host, as the Scribe Desk does; otherwise the binder says why.
class_name GrimoireBinderPanel
extends Control

signal closed

enum Column { LEAVES, DIAMONDS, PLACES }

const PAGE_WIDTH: float = 330.0
const TITLE_SIZE: int = 24
const FONT_SIZE: int = 15
const SMALL_FONT_SIZE: int = 12
## The panel is laid out for a cell this big and scales with the player's cell.
const REFERENCE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const MIN_FIT: float = 0.45
const BACKDROP: Color = Color(0.03, 0.03, 0.05, 0.72)
const PAGE_COLOR: Color = Color(0.13, 0.1, 0.08, 0.94)
const PAGE_EDGE: Color = Color(0.85, 0.7, 0.42)
const SELECTED_COLOR: Color = Color(1.0, 0.88, 0.5)
const ROW_COLOR: Color = Color(0.95, 0.92, 0.85)
const DIM_COLOR: Color = Color(0.6, 0.58, 0.55)
const PROBLEM_COLOR: Color = Color(1.0, 0.55, 0.45)
const HARMONY_COLOR: Color = Color(1.0, 0.85, 0.35)
const NOTE_TIME: float = 2.5
## The middle column's rows, top to bottom: the three diamonds as they sit in the cross, then the Folio.
const DIAMOND_ROWS: Array[int] = [ScribeCardResource.DioramaSocket.ULT, ScribeCardResource.DioramaSocket.GUARD,
	ScribeCardResource.DioramaSocket.SKILL, -1]

var actor: ActorBase
var widget: CrossGrimoireDiamondWidget
var column: int = Column.DIAMONDS
var leaf_row: int = 0
var place_row: int = 0
var diamond_row: int = 2
var folio_open: bool = false

var _root: Control
var _title: Label
var _leaf_page: VBoxContainer
var _place_page: VBoxContainer
var _leaf_rows: Array[Label] = []
var _place_rows: Array[Label] = []
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
	var spread: HBoxContainer = HBoxContainer.new()
	spread.alignment = BoxContainer.ALIGNMENT_CENTER
	spread.add_theme_constant_override(&"separation", 18)
	spread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(spread)
	_leaf_page = _page("Action-Leaves: What You Do")
	spread.add_child(_leaf_page.get_parent())
	widget = CrossGrimoireDiamondWidget.new()
	widget.name = "Diamonds"
	widget.follow = actor
	widget.set_display_scale(CrossGrimoireDiamondWidget.BINDER_SCALE, true)
	widget.socket_picked.connect(_on_socket_picked)
	spread.add_child(widget)
	_place_page = _page("Place-Cards: Where You Stand")
	spread.add_child(_place_page.get_parent())
	_detail = _label(FONT_SIZE, ROW_COLOR)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_detail)
	_folio = _label(SMALL_FONT_SIZE, ROW_COLOR)
	_folio.visible = false
	_root.add_child(_folio)
	_note = _label(FONT_SIZE, PROBLEM_COLOR)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_note)
	_hint = _label(SMALL_FONT_SIZE, Color(0.82, 0.84, 0.9))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "←/→ pages and diamonds · ↑/↓ choose · light picks · dodge or Tab closes"
	_root.add_child(_hint)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(_on_menu_input)
	PartyProgress.current.progress_changed.connect(_refresh)
	NetworkManager.current.kit_refused.connect(_on_kit_refused)
	_refresh()


func _exit_tree() -> void:
	var progress: PartyProgress = PartyProgress.current
	if progress != null and progress.progress_changed.is_connected(_refresh):
		progress.progress_changed.disconnect(_refresh)
	var network: NetworkManager = NetworkManager.current
	if network != null and network.kit_refused.is_connected(_on_kit_refused):
		network.kit_refused.disconnect(_on_kit_refused)
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
	_root.position = (size - _root.size * fit) * 0.5


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
		InputComponent.MENU_BACK:
			close()
			return
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
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var socket: int = selected_socket()
	_title.text = "GRIMOIRE BINDER  ·  %s  ·  %d Chimes" % [ScribeCardResource.SOCKET_NAMES[socket], PartyProgress.current.chimes]
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
	var middle: String = "Collection Folio" if DIAMOND_ROWS[diamond_row] < 0 else ScribeCardResource.SOCKET_NAMES[DIAMOND_ROWS[diamond_row]]
	_hint.text = "%s  ·  ←/→ pages and diamonds · ↑/↓ choose · light picks · dodge or Tab closes" % (
		("> " + middle) if column == Column.DIAMONDS else ["Action-Leaves", "", "Place-Cards"][column])
	widget.queue_redraw()


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
	return "COLLECTION FOLIO: %d of %d found\n%s" % [found, listed.size(), "\n".join(lines)]


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
