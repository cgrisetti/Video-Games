## The Armory & Scribe Desk menu, drawn over one player's split-screen cell and
## driven by that player's own controller (05_ARSENAL_AND_CARDS_GDD.md §2–3):
## up / down picks a row, left / right (or light) changes it, dodge closes.
##   Fellowship · Calling · Armor · Weapon · the four lead cards · the four under-card links
## The Fellowship (your class) and Calling (07 GDD §1.3) change at once; a new
## Fellowship is a new character, and the desk reopens for it. The rest edits
## a draft of your kit. Whenever the draft follows the rules (gear your Calling
## may use, an owned copy, an open link, enough memory) it asks the host to
## equip it and your character changes in place; otherwise the row says why
## and nothing changes.
class_name ScribeDeskMenu
extends PanelContainer

signal closed

const WIDTH: float = 560.0
const TITLE_SIZE: int = 22
const FONT_SIZE: int = 15
const SMALL_FONT_SIZE: int = 12
const SELECTED_COLOR: Color = Color(0.85, 0.75, 1.0)
const LOCKED_COLOR: Color = Color(0.6, 0.6, 0.66)
const PROBLEM_COLOR: Color = Color(1.0, 0.55, 0.45)
const GOOD_COLOR: Color = Color(0.6, 1.0, 0.65)
const PANEL_COLOR: Color = Color(0.07, 0.06, 0.1, 0.93)
const BORDER_COLOR: Color = Color(0.72, 0.55, 1.0)
const NOTE_TIME: float = 2.5
const ROW_FELLOWSHIP: int = 0
const ROW_CALLING: int = 1
const ROW_ARMOR: int = 2
const ROW_WEAPON: int = 3
const ROW_FIRST_LEAD: int = 4
const ROW_FIRST_LINK: int = 8
const ROW_CLOSE: int = 12
const ROW_COUNT: int = 13

var actor: ActorBase
var selected: int = ROW_WEAPON
## The kit being edited; equipped whenever it's allowed.
var draft: EquipmentLoadoutResource

var _player_class: PlayerClassResource
## The loadout the draft was copied from: a new one (a new Calling) resets the draft.
var _seen_loadout: ClassLoadoutResource
var _problem: String = ""
var _header: Label
var _rows: Array[Label] = []
var _detail: Label
var _note: Label
var _hint: Label
var _note_left: float = 0.0


## `start_row` reopens the desk where it was (after a Fellowship change); -1 starts on the Weapon row.
func setup(target_actor: ActorBase, start_row: int = -1) -> void:
	actor = target_actor
	if start_row >= 0 and start_row < ROW_COUNT:
		selected = start_row


func _ready() -> void:
	name = "ScribeDeskMenu"
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
	style.set_content_margin_all(12.0)
	add_theme_stylebox_override(&"panel", style)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var title: Label = _label(TITLE_SIZE)
	title.text = "ARMORY & SCRIBE DESK"
	title.modulate = BORDER_COLOR.lightened(0.3)
	column.add_child(title)
	_header = _label(SMALL_FONT_SIZE)
	column.add_child(_header)
	for index: int in ROW_COUNT:
		var row: Label = _label(FONT_SIZE)
		column.add_child(row)
		_rows.append(row)
	_detail = _label(SMALL_FONT_SIZE)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(WIDTH - 24.0, 0.0)
	column.add_child(_detail)
	_note = _label(FONT_SIZE)
	column.add_child(_note)
	_hint = _label(SMALL_FONT_SIZE)
	_hint.modulate = Color(0.8, 0.82, 0.9)
	column.add_child(_hint)
	if actor != null:
		_sync_from_actor()
		if actor.input != null:
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
	if is_instance_valid(actor) and actor.loadout != _seen_loadout:
		_sync_from_actor()
		_refresh()


## Starts the draft from what the character wears now, under its current Calling.
func _sync_from_actor() -> void:
	_seen_loadout = actor.loadout
	_player_class = ClassLoadouts.player_class(actor.loadout.class_id, actor.loadout.calling)
	draft = actor.loadout.kit.copy()
	_problem = ""


# --- Moving around --------------------------------------------------------

func move_cursor(step: int) -> void:
	selected = wrapi(selected + step, 0, ROW_COUNT)
	AudioCues.play(&"menu_move")
	_refresh()


## Light changes the row (forward through its options), or closes on Close.
func accept() -> void:
	if selected == ROW_CLOSE:
		close()
	else:
		cycle(1)


func close() -> void:
	if is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


## The draft's problem, or "" when it's what you're wearing.
func problem() -> String:
	return _problem


func note_text() -> String:
	return _note.text if _note_left > 0.0 else ""


func _on_menu_input(action: StringName) -> void:
	match action:
		InputComponent.MENU_UP:
			move_cursor(-1)
		InputComponent.MENU_DOWN:
			move_cursor(1)
		InputComponent.MENU_LEFT:
			cycle(-1)
		InputComponent.MENU_RIGHT:
			cycle(1)
		InputComponent.MENU_ACCEPT:
			accept()
		InputComponent.MENU_BACK:
			close()


# --- Changing the kit -----------------------------------------------------

## Steps the selected row to its next (or previous) option and, if the kit is
## allowed, asks the host to equip it.
func cycle(step: int) -> void:
	if selected == ROW_FELLOWSHIP:
		_cycle_fellowship(step)
		return
	if selected == ROW_CALLING:
		_cycle_calling(step)
		return
	var options: Array[StringName] = options_for(selected)
	if options.is_empty():
		return
	var index: int = options.find(_current_option(selected))
	_set_option(selected, options[wrapi(index + step, 0, options.size())])
	var progress: PartyProgress = PartyProgress.current
	_problem = LoadoutComposer.kit_problem(_player_class, draft, progress.grimoire_level(), progress.collection)
	if _problem == "":
		NetworkManager.current.update_local_kit(actor.device_id, draft.to_dict())
		AudioCues.play(&"equip")
	else:
		AudioCues.play(&"refuse")
	_refresh()


## The next Fellowship: a new class, so a new character (LevelBase reopens the desk for it).
func _cycle_fellowship(step: int) -> void:
	var classes: Array[StringName] = ClassLoadouts.PLAYER_CLASSES
	var next: StringName = classes[wrapi(classes.find(actor.loadout.class_id) + step, 0, classes.size())]
	var mode: int = actor.input.assist_mode if actor.input != null else InputComponent.AssistMode.ADVENTURER
	AudioCues.play(&"equip")
	# Deferred: this runs inside the character's own input step, and a new class replaces it.
	NetworkManager.current.update_local_player.call_deferred(actor.device_id, next, mode)


## The next Secondary Calling: the same character, re-equipped in place.
func _cycle_calling(step: int) -> void:
	var next: int = wrapi(Callings.resolve(actor.loadout.class_id, actor.loadout.calling) + step, 0, Callings.SECONDARY_NAMES.size())
	AudioCues.play(&"equip")
	NetworkManager.current.update_local_calling(actor.device_id, next)


## What a row can be set to: item ids, lead-card copy keys (starter cards plus
## every copy in the binder that fits the slot), or under-card ids ("" = empty).
func options_for(row: int) -> Array[StringName]:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var options: Array[StringName] = []
	if row == ROW_ARMOR:
		for item: EquipmentItemResource in catalog.armors():
			options.append(item.item_id)
	elif row == ROW_WEAPON:
		for item: EquipmentItemResource in catalog.weapons():
			options.append(item.item_id)
	elif _is_lead_row(row):
		var slot: int = row - ROW_FIRST_LEAD
		for card: ScribeCardResource in catalog.lead_cards(slot):
			if not LoadoutComposer.fits_slot(_player_class, card, slot):
				continue
			for variant: int in ScribeCardResource.CardVariant.size():
				var key: StringName = ScribeCardResource.copy_key(card.card_id, variant as ScribeCardResource.CardVariant)
				if LoadoutComposer.owns(key, 1, PartyProgress.current.collection):
					options.append(key)
	elif _is_link_row(row):
		options.append(&"")
		for card: ScribeCardResource in catalog.under_cards():
			if LoadoutComposer.owns(card.card_id, 1, PartyProgress.current.collection):
				options.append(card.card_id)
	return options


func _current_option(row: int) -> StringName:
	if row == ROW_ARMOR:
		return draft.armor_id
	if row == ROW_WEAPON:
		return draft.weapon_id
	if _is_lead_row(row):
		return draft.lead_copy_key(row - ROW_FIRST_LEAD)
	if _is_link_row(row):
		return draft.under_ids[row - ROW_FIRST_LINK]
	return &""


func _set_option(row: int, option: StringName) -> void:
	if row == ROW_ARMOR:
		draft.armor_id = option
	elif row == ROW_WEAPON:
		draft.weapon_id = option
	elif _is_lead_row(row):
		var slot: int = row - ROW_FIRST_LEAD
		draft.lead_ids[slot] = ScribeCardResource.copy_card_id(option)
		draft.lead_variants[slot] = ScribeCardResource.copy_variant(option)
	elif _is_link_row(row):
		draft.under_ids[row - ROW_FIRST_LINK] = option


func _on_kit_refused(device_id: int, reason: String) -> void:
	if not is_instance_valid(actor) or device_id != actor.device_id:
		return
	draft = actor.loadout.kit.copy()
	_problem = ""
	_show_note(reason, false)
	_refresh()


# --- Drawing --------------------------------------------------------------

func _refresh() -> void:
	if draft == null:
		return
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var level: int = PartyProgress.current.grimoire_level()
	_header.text = "Grimoire Lv %d  ·  Memory %d / %d  ·  Under-Card links open: %d of %d" % [level, LoadoutComposer.memory_used(draft),
		LoadoutComposer.memory_capacity(level, _player_class.bonus_memory), LoadoutComposer.under_slots(level), EquipmentLoadoutResource.SLOT_COUNT]
	for row: int in ROW_COUNT:
		var label: Label = _rows[row]
		var cursor: String = "▶ " if row == selected else "   "
		label.text = cursor + _row_text(row, level)
		var locked: bool = _is_link_row(row) and row - ROW_FIRST_LINK >= LoadoutComposer.under_slots(level)
		label.modulate = SELECTED_COLOR if row == selected else (LOCKED_COLOR if locked else Color.WHITE)
	if _problem != "":
		_detail.text = _problem
		_detail.add_theme_color_override(&"font_color", PROBLEM_COLOR)
	else:
		_detail.text = _detail_text(selected, catalog)
		_detail.remove_theme_color_override(&"font_color")
	if actor != null and actor.input != null:
		var input: InputComponent = actor.input
		var keys: String = "%s/%s choose · %s/%s change" % [input.label(InputComponent.ACTION_MOVE_FORWARD), input.label(InputComponent.ACTION_MOVE_BACK),
			input.label(InputComponent.ACTION_MOVE_LEFT), input.label(InputComponent.ACTION_MOVE_RIGHT)] \
			if input.is_keyboard() else "Stick or D-Pad: choose and change"
		_hint.text = "%s · %s next · %s close" % [keys, input.label(InputComponent.ACTION_LIGHT), input.label(InputComponent.ACTION_DODGE)]


func _row_text(row: int, level: int) -> String:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	if row == ROW_FELLOWSHIP:
		return "Fellowship:  %s" % _player_class.fellowship_name
	if row == ROW_CALLING:
		return "Calling:  %s  ·  %s" % [_player_class.display_name, Callings.secondary_label(_player_class.calling)]
	if row == ROW_ARMOR:
		return "Armor:  %s%s" % [_item_name(draft.armor_id), _lock_note(draft.armor_id)]
	if row == ROW_WEAPON:
		return "Weapon:  %s%s" % [_item_name(draft.weapon_id), _lock_note(draft.weapon_id)]
	if _is_lead_row(row):
		var slot: int = row - ROW_FIRST_LEAD
		return "%s card:  %s" % [ScribeCardResource.SLOT_NAMES[slot], catalog.copy_name(draft.lead_copy_key(slot))]
	if _is_link_row(row):
		var link: int = row - ROW_FIRST_LINK
		if link >= LoadoutComposer.under_slots(level):
			return "Link %d:  locked (Grimoire Lv %d)" % [link + 1, link + 2]
		var under: ScribeCardResource = catalog.card(draft.under_ids[link])
		return "Link %d:  %s" % [link + 1, under.display_name if under != null else "empty"]
	return "Close"


func _detail_text(row: int, catalog: ArsenalCatalog) -> String:
	if row == ROW_FELLOWSHIP:
		return "Your raid seat. Changing it changes who you are: the Shield-Sworn hold the boss, the Wayfarers strike and stamp Signs, the Lantern-Bearers mend down their Soul Tethers."
	if row == ROW_CALLING:
		return "%s, %s. %s: %s." % [_player_class.display_name, _player_class.calling_subtitle, Callings.SECONDARY_NAMES[_player_class.calling],
			Callings.summary(_player_class.calling)]
	if row == ROW_ARMOR:
		var armor: EquipmentItemResource = catalog.item(draft.armor_id)
		return "%d%% mitigation · %.1f stamina/s · %.1f m roll · %d ms Perfect Guard. %s" % [roundi(armor.mitigation * 100.0),
			armor.stamina_regen_per_sec, armor.roll_distance, roundi(armor.perfect_guard_window * 1000.0), armor.description]
	if row == ROW_WEAPON:
		return catalog.item(draft.weapon_id).description
	if _is_lead_row(row):
		var slot: int = row - ROW_FIRST_LEAD
		var lead: ScribeCardResource = catalog.card(draft.lead_ids[slot])
		var seal: ScribeSignResource = catalog.sign_seal(lead.scribe_sign)
		return "%s · %s · %s · memory %d. %s" % [seal.display_name, lead.rarity_name(),
			ScribeCardResource.VARIANT_NAMES[draft.lead_variants[slot]], lead.memory_cost(), lead.description]
	if _is_link_row(row):
		var under: ScribeCardResource = catalog.card(draft.under_ids[row - ROW_FIRST_LINK])
		if under == null:
			return "Slide an Under-Card beneath this slot's lead card to change it with one verb."
		return "Memory %d. %s" % [under.memory_cost(), under.description]
	return "Back to Bramblebridge."


## "  (needs Swift Foot)" when the Calling can't use an item, else "".
func _lock_note(id: StringName) -> String:
	var item: EquipmentItemResource = ArsenalCatalog.current.item(id)
	if item == null or _player_class.allows(item):
		return ""
	var unlock: int = Callings.unlocked_by(item)
	return "  (needs %s)" % Callings.SECONDARY_NAMES[unlock] if unlock >= 0 else "  (not for this Fellowship)"


func _item_name(id: StringName) -> String:
	var item: EquipmentItemResource = ArsenalCatalog.current.item(id)
	return item.display_name if item != null else String(id)


func _is_lead_row(row: int) -> bool:
	return row >= ROW_FIRST_LEAD and row < ROW_FIRST_LINK


func _is_link_row(row: int) -> bool:
	return row >= ROW_FIRST_LINK and row < ROW_CLOSE


func _show_note(text: String, good: bool) -> void:
	_note.text = text
	_note.add_theme_color_override(&"font_color", GOOD_COLOR if good else PROBLEM_COLOR)
	_note_left = NOTE_TIME


func _label(size: int) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override(&"outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
