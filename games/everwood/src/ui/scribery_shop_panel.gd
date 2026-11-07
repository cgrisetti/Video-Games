## The Reed-Light Scribery's counter (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §6), on
## the player's own screen. Four tabs along the top, the player's own
## Cross-Grimoire diamonds at 2.2x along the bottom:
##   Inscribe Action-Leaves   the Scribery's Common leaves, for Chimes
##   Chart Place-Cards        the four Place-Cards, for Chimes (one frames every diamond)
##   Seal Cards               the four seal cards, for Chimes (made once, each fits
##                            every slot of the hand at the Binder's stamping bench);
##                            highlighting one has the hero pull it from the pouch
##   The Gilding Press        a finer finish for a card the party owns:
##                            Plain Vellum to Gilded Leaf (50), to Star-Inked Vellum (120)
## Highlighting a card shows it in the diamonds and, on the hero's own puppet
## standing at the press, plays the Offhand Pocket-Draw and the blade igniting
## in the coat it would give (14 GDD §8), then holds the Hearth-Rite's glow. A
## finer finish adds potency: Gilded Leaf +10%, Star-Inked Vellum +20% and a
## quicker Hearth-Rite. A new leaf goes
## into an empty R; a new Place-Card frames the chosen diamond if it has no
## frame; a pressed finish replaces the copy the hero wears. Left / right
## changes tab, up / down picks, light buys, dodge closes; the mouse works too.
class_name ScriberyShopPanel
extends Control

signal closed

enum Tab { INSCRIBE, CHART, SEALS, GILD }

const TAB_NAMES: Array[String] = ["Make Ink Cards", "Chart Place-Cards", "Seal Cards", "The Gilding Press"]
const LIST_WIDTH: float = 620.0
const TITLE_SIZE: int = 24
const FONT_SIZE: int = 15
const SMALL_FONT_SIZE: int = 12
const REFERENCE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const MIN_FIT: float = 0.45
## The living storybook atelier look (AtelierTheme, 24 GDD §3), one book with the Binder and the Desk.
const BACKDROP: Color = AtelierTheme.BACKDROP
const EDGE_COLOR: Color = AtelierTheme.GILT
const SELECTED_COLOR: Color = AtelierTheme.GOLD
const ROW_COLOR: Color = AtelierTheme.INK
const DIM_COLOR: Color = AtelierTheme.INK_DIM
const GOOD_COLOR: Color = AtelierTheme.GOOD
const PROBLEM_COLOR: Color = AtelierTheme.BAD
const NOTE_TIME: float = 2.5

const Socket = ScribeCardResource.DioramaSocket

var actor: ActorBase
var widget: CrossGrimoireDiamondWidget
var tab: int = Tab.INSCRIBE
var row: int = 0

var _root: VBoxContainer
var _title: Label
var _tabs: Array[Label] = []
var _rows: Array[Label] = []
var _list: VBoxContainer
var _detail: Label
var _note: Label
var _note_left: float = 0.0
## A purchase on its way through the host, slotted once the binder has it: {copy_key, socket, kind}.
var _pending_slot: Dictionary = {}
## Pocket-draw previews played on the shopper's puppet since the counter opened.
var previews_played: int = 0


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "ScriberyShopPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_root = VBoxContainer.new()
	_root.name = "Counter"
	_root.add_theme_constant_override(&"separation", 6)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_title = _label(TITLE_SIZE, EDGE_COLOR.lightened(0.3))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_title)
	var tab_row: HBoxContainer = HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override(&"separation", 22)
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tab_row)
	for index: int in TAB_NAMES.size():
		var tab_label: Label = _label(FONT_SIZE + 2, ROW_COLOR)
		tab_label.mouse_filter = Control.MOUSE_FILTER_STOP
		tab_label.gui_input.connect(_on_tab_clicked.bind(index))
		tab_row.add_child(tab_label)
		_tabs.append(tab_label)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = AtelierTheme.page_style()
	style.set_content_margin_all(12.0)
	panel.add_theme_stylebox_override(&"panel", style)
	_root.add_child(panel)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 3)
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_list)
	_detail = _label(FONT_SIZE, ROW_COLOR)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_detail)
	_note = _label(FONT_SIZE, GOOD_COLOR)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_note)
	widget = CrossGrimoireDiamondWidget.new()
	widget.name = "Diamonds"
	widget.follow = actor
	widget.set_display_scale(CrossGrimoireDiamondWidget.BINDER_SCALE, true)
	widget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	widget.socket_picked.connect(_on_socket_picked)
	_root.add_child(widget)
	var hint: Label = _label(SMALL_FONT_SIZE, Color(0.82, 0.84, 0.9))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "←/→ tabs · ↑/↓ choose · light buys · dodge closes · click a diamond to choose where a Place-Card goes"
	_root.add_child(hint)
	if actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(_on_menu_input)
	PartyProgress.current.progress_changed.connect(_on_progress_changed)
	_refresh()


func _exit_tree() -> void:
	var progress: PartyProgress = PartyProgress.current
	if progress != null and progress.progress_changed.is_connected(_on_progress_changed):
		progress.progress_changed.disconnect(_on_progress_changed)
	if is_instance_valid(actor):
		if actor.input != null:
			actor.input.menu_open = false
			if actor.input.menu_input.is_connected(_on_menu_input):
				actor.input.menu_input.disconnect(_on_menu_input)
		if actor.sign_flow != null:
			actor.sign_flow.restore_look()


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


func note_text() -> String:
	return _note.text if _note_left > 0.0 else ""


# --- What's for sale -----------------------------------------------------------

## The rows of the open tab: card ids to inscribe or chart, or copy keys to gild.
func options() -> Array[StringName]:
	var listed: Array[StringName] = []
	match tab:
		Tab.INSCRIBE:
			for leaf: ScribeCardResource in ArsenalCatalog.current.scribery_leaves():
				listed.append(leaf.card_id)
		Tab.CHART:
			for place: ScribeCardResource in ArsenalCatalog.current.place_cards():
				listed.append(place.card_id)
		Tab.SEALS:
			for seal_card: ScribeCardResource in ArsenalCatalog.current.seal_cards():
				listed.append(seal_card.card_id)
		Tab.GILD:
			listed = gildable_copies()
	return listed


## The copies the press can take: what the hero wears in their diamonds first,
## then every other Action-Leaf and Place-Card the party owns below Star-Inked Vellum.
func gildable_copies() -> Array[StringName]:
	var listed: Array[StringName] = []
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	for socket: int in [Socket.SKILL, Socket.ULT, Socket.GUARD]:
		_add_gildable(listed, ScribeCardResource.copy_key(kit.socket_leaf_id(socket), kit.socket_leaf_variant(socket)))
		_add_gildable(listed, ScribeCardResource.copy_key(kit.place_ids[socket], kit.socket_place_variant(socket)))
	var cards: Array[ScribeCardResource] = ArsenalCatalog.current.action_leaves()
	cards.append_array(ArsenalCatalog.current.place_cards())
	for listed_card: ScribeCardResource in cards:
		var finish: int = PartyProgress.current.best_finish(listed_card.card_id)
		if finish >= 0:
			_add_gildable(listed, ScribeCardResource.copy_key(listed_card.card_id, finish as ScribeCardResource.CardVariant))
	return listed


static func _add_gildable(listed: Array[StringName], copy_key: StringName) -> void:
	if ScribeCardResource.copy_card_id(copy_key) == &"" or listed.has(copy_key):
		return
	if ScribeCardResource.copy_variant(copy_key) >= ScribeCardResource.CardVariant.STAR_INKED_VELLUM:
		return
	if LoadoutComposer.owns(copy_key, 1, PartyProgress.current.collection):
		listed.append(copy_key)


# --- Choosing and buying ---------------------------------------------------------

func _on_menu_input(action: StringName) -> void:
	match action:
		InputComponent.MENU_LEFT:
			select_tab(wrapi(tab - 1, 0, TAB_NAMES.size()))
		InputComponent.MENU_RIGHT:
			select_tab(wrapi(tab + 1, 0, TAB_NAMES.size()))
		InputComponent.MENU_UP:
			select_row(row - 1)
		InputComponent.MENU_DOWN:
			select_row(row + 1)
		InputComponent.MENU_ACCEPT:
			buy()
		InputComponent.MENU_BACK:
			close()


func select_tab(index: int) -> void:
	tab = index
	row = 0
	AudioCues.play(&"menu_move")
	_refresh()


func select_row(index: int) -> void:
	var count: int = options().size()
	row = wrapi(index, 0, maxi(1, count))
	AudioCues.play(&"menu_move")
	_refresh()


## Selects the row holding `id` (a card id, or a copy key on the press); false if it isn't on this tab.
func select_option(id: StringName) -> bool:
	var index: int = options().find(id)
	if index < 0:
		return false
	select_row(index)
	return true


## Light: inscribe, chart or gild the highlighted row. Returns whether the host was asked.
func buy() -> bool:
	var listed: Array[StringName] = options()
	if listed.is_empty():
		return false
	var choice: StringName = listed[clampi(row, 0, listed.size() - 1)]
	var progress: PartyProgress = PartyProgress.current
	if tab == Tab.GILD:
		if not progress.can_gild(choice):
			var short: int = PartyProgress.marks_needed(choice) - progress.marks_of(choice)
			_refuse("Needs %d more Ink-Binding Marks" % short if short > 0 else "Not ready to press")
			return false
		_pending_slot = {"copy_key": _finer(choice), "replaces": choice}
		# The Scribe's Maker-Seal: who pressed it (24 GDD R3).
		var presser: String = actor.display_name().get_slice(" ", 0) if is_instance_valid(actor) else ""
		progress.request_gild(choice, presser)
	else:
		if not progress.can_inscribe(choice):
			var have: bool = progress.owns_card(choice)
			_refuse("Already charted" if tab == Tab.CHART and have else ("Already made" if tab == Tab.SEALS and have
				else "Needs %d Chimes" % progress.scribery_cost(choice)))
			return false
		_pending_slot = {"copy_key": ScribeCardResource.copy_key(choice, ScribeCardResource.CardVariant.STANDARD), "replaces": &""}
		progress.request_inscribe(choice)
	AudioCues.play(&"purchase")
	_on_progress_changed()
	return true


## Once the binder has the new copy: a leaf fills an empty R, a Place-Card an
## empty frame on the chosen diamond, a pressed finish replaces the copy worn.
func _on_progress_changed() -> void:
	if not _pending_slot.is_empty() and LoadoutComposer.owns(_pending_slot["copy_key"], 1, PartyProgress.current.collection):
		var key: StringName = _pending_slot["copy_key"]
		var replaces: StringName = _pending_slot["replaces"]
		_pending_slot = {}
		_slot_new_copy(key, replaces)
	_refresh()


func _slot_new_copy(copy_key: StringName, replaces: StringName) -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var listed: ScribeCardResource = catalog.card(ScribeCardResource.copy_card_id(copy_key))
	var variant: int = ScribeCardResource.copy_variant(copy_key)
	var draft: EquipmentLoadoutResource = actor.loadout.kit.copy()
	var player_class: PlayerClassResource = ClassLoadouts.player_class(actor.loadout.class_id, actor.loadout.calling)
	var changed: bool = false
	if replaces != &"":
		for socket: int in EquipmentLoadoutResource.SOCKET_COUNT:
			if ScribeCardResource.copy_key(draft.socket_leaf_id(socket), draft.socket_leaf_variant(socket)) == replaces:
				draft.set_socket_leaf(socket, listed.card_id, variant)
				changed = true
			if ScribeCardResource.copy_key(draft.place_ids[socket], draft.socket_place_variant(socket)) == replaces:
				draft.set_socket_place(socket, listed.card_id, variant)
				changed = true
	elif listed.is_place_card():
		if draft.place_ids[widget.selected_socket] == &"":
			draft.set_socket_place(widget.selected_socket, listed.card_id, variant)
			changed = true
	elif draft.socket_leaf_id(Socket.SKILL) == &"" and LoadoutComposer.fits_slot(player_class, listed, ScribeCardResource.GrimoireSlot.SIGNATURE):
		draft.set_socket_leaf(Socket.SKILL, listed.card_id, variant)
		changed = true
	var verb: String = "Pressed" if replaces != &"" else ("Charted" if listed.is_place_card() else "Made")
	if listed.is_seal_card():
		# A seal goes on at the Binder's stamping bench, not into the diamonds.
		_show_note("Made %s: press it on your gear in the Binder (tab 4)" % listed.display_name, GOOD_COLOR)
		return
	_show_note("%s %s" % [verb, catalog.copy_name(copy_key)], GOOD_COLOR)
	if not changed:
		return
	var progress: PartyProgress = PartyProgress.current
	if LoadoutComposer.kit_problem(player_class, draft, progress.grimoire_level(), progress.collection, progress.trail_level()) == "":
		NetworkManager.current.update_local_kit(actor.device_id, draft.to_dict())


static func _finer(copy_key: StringName) -> StringName:
	return ScribeCardResource.copy_key(ScribeCardResource.copy_card_id(copy_key),
		mini(ScribeCardResource.copy_variant(copy_key) + 1, ScribeCardResource.CardVariant.STAR_INKED_VELLUM) as ScribeCardResource.CardVariant)


func _on_socket_picked(_socket: int) -> void:
	_refresh()


func _on_tab_clicked(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		select_tab(index)


func _on_row_clicked(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		row = index
		buy()


func _refuse(reason: String) -> void:
	AudioCues.play(&"refuse")
	_show_note(reason, PROBLEM_COLOR)


func _show_note(text: String, color: Color) -> void:
	_note.text = text
	_note.modulate = Color(color, 1.0)
	_note_left = NOTE_TIME


# --- Drawing ----------------------------------------------------------------------

func _refresh() -> void:
	if not is_instance_valid(actor) or widget == null:
		return
	var progress: PartyProgress = PartyProgress.current
	_title.text = "THE REED-LIGHT SCRIBERY  ·  %d Chimes" % progress.chimes
	for index: int in _tabs.size():
		_tabs[index].text = ("[ %s ]" if index == tab else "  %s  ") % TAB_NAMES[index]
		_tabs[index].modulate = SELECTED_COLOR if index == tab else DIM_COLOR
	var listed: Array[StringName] = options()
	row = clampi(row, 0, maxi(0, listed.size() - 1))
	while _rows.size() < listed.size():
		var line: Label = _label(FONT_SIZE, ROW_COLOR)
		line.mouse_filter = Control.MOUSE_FILTER_STOP
		line.gui_input.connect(_on_row_clicked.bind(_rows.size()))
		_list.add_child(line)
		_rows.append(line)
	for index: int in _rows.size():
		_rows[index].visible = index < listed.size()
		if index < listed.size():
			_rows[index].text = ("> " if index == row else "  ") + _row_text(listed[index])
			_rows[index].modulate = SELECTED_COLOR if index == row else ROW_COLOR
	if listed.is_empty():
		_detail.text = "Nothing to press yet: make or chart a card first."
		widget.clear_preview()
		return
	_preview(listed[row])


func _row_text(id: StringName) -> String:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var progress: PartyProgress = PartyProgress.current
	if tab == Tab.GILD:
		var finer: int = ScribeCardResource.copy_variant(_finer(id))
		var marks: String = "Ready to Press" if progress.ready_to_press(id) else "%d / %d Marks" % [progress.marks_of(id), PartyProgress.marks_needed(id)]
		return "%s: %s → %s (+%d%% potency)   %s" % [catalog.card(ScribeCardResource.copy_card_id(id)).display_name,
			ScribeCardResource.VARIANT_NAMES[ScribeCardResource.copy_variant(id)], ScribeCardResource.VARIANT_NAMES[finer],
			roundi((ScribeCardResource.finish_potency(finer) - 1.0) * 100.0), marks]
	var listed: ScribeCardResource = catalog.card(id)
	var seal: String = catalog.sign_seal(listed.scribe_sign).display_name
	var kind: String = seal if listed.is_place_card() else "%s · %s" % [seal, listed.mode_name()]
	var owned: int = progress.copies_of(ScribeCardResource.copy_key(id, ScribeCardResource.CardVariant.STANDARD))
	var status: String = ("charted ✓" if owned > 0 else "%d Chimes" % listed.chime_cost) if listed.is_place_card() \
		else "%d Chimes%s" % [listed.chime_cost, "  (have %d)" % owned if owned > 0 else ""]
	if listed.is_seal_card():
		status = "made ✓" if owned > 0 else "%d Chimes" % listed.chime_cost
	var tether: String = "  needs a Soul Tether" if listed.needs_soul_tether and not actor.loadout.has_soul_tethers else ""
	return "%s  [%s]  %s%s" % [listed.display_name, kind, status, tether]


## The highlighted card in the diamonds and, on the hero's puppet, the coat it would give.
func _preview(id: StringName) -> void:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	var key: StringName = id if tab == Tab.GILD else ScribeCardResource.copy_key(id, ScribeCardResource.CardVariant.STANDARD)
	var shown: StringName = _finer(key) if tab == Tab.GILD else key
	var listed: ScribeCardResource = ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(shown))
	if listed.is_seal_card():
		_preview_seal(listed)
		return
	var socket: int = widget.selected_socket
	if listed.is_action_leaf():
		socket = _socket_wearing(key, Socket.SKILL)
		widget.selected_socket = socket
		widget.preview_socket(socket, listed.card_id, ScribeCardResource.copy_variant(shown), kit.place_ids[socket], kit.place_variants[socket])
	else:
		socket = _socket_framed_by(key, socket)
		widget.selected_socket = socket
		widget.preview_socket(socket, kit.socket_leaf_id(socket), kit.socket_leaf_variant(socket), listed.card_id, ScribeCardResource.copy_variant(shown))
	var synergy: Dictionary = widget.socket_view(socket)["synergy"]
	_detail.text = "%s  ·  %s%s" % [listed.description, ScribeCardResource.SOCKET_NAMES[socket],
		"  ·  ★ Home-Ground Harmony" if synergy["is_home_ground_harmony"] else ""]
	# The puppet shows the coat this pairing gives, as the Hearth-Rite would (on this screen only).
	var inked: int = synergy["scribe_sign"] if synergy["scribe_sign"] != ScribeSignResource.Sign.NONE else synergy["place_sign"]
	var director: CombatDirector = CombatDirector.current
	director.show_sign_coat_here(actor, SignFlowComponent.CoatLook.FLARE, inked, synergy["manifestation_mode"], synergy["location_card_id"],
		SignFlowComponent.SIGN_FLOW_FLARE_TIME)
	director.show_sign_coat_here(actor, SignFlowComponent.CoatLook.TRAIL_TUCK, inked, synergy["manifestation_mode"],
		synergy["location_card_id"], 0.0)
	previews_played += 1


## A seal card: what it does pressed and pulled, and the hero pulling it from the pouch (on this screen only).
func _preview_seal(listed: ScribeCardResource) -> void:
	widget.clear_preview()
	_detail.text = "%s  ·  %s seal, %s when pulled" % [listed.description, ArsenalCatalog.current.sign_seal(listed.scribe_sign).display_name,
		listed.mode_name()]
	if EquipmentSealComponent.enabled and actor.visuals != null and actor.visuals.has_rig():
		actor.visuals.play_pocket_pull_flourish(ArsenalCatalog.current, listed.card_id, PlayerLoadoutResource.TriggerSlot.R)
	previews_played += 1


## The socket whose leaf is this copy (the default when none is).
func _socket_wearing(copy_key: StringName, default_socket: int) -> int:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	for socket: int in [Socket.SKILL, Socket.ULT, Socket.GUARD]:
		if ScribeCardResource.copy_key(kit.socket_leaf_id(socket), kit.socket_leaf_variant(socket)) == copy_key:
			return socket
	return default_socket


func _socket_framed_by(copy_key: StringName, default_socket: int) -> int:
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	if ScribeCardResource.copy_key(kit.place_ids[default_socket], kit.socket_place_variant(default_socket)) == copy_key:
		return default_socket
	for socket: int in [Socket.SKILL, Socket.ULT, Socket.GUARD]:
		if ScribeCardResource.copy_key(kit.place_ids[socket], kit.socket_place_variant(socket)) == copy_key:
			return socket
	return default_socket


func _label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override(&"outline_size", 4)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
