## The Armory & Scribe Desk menu, drawn over one player's split-screen cell and
## driven by that player's own controller (05_ARSENAL_AND_CARDS_GDD.md §2–3, and
## the Desk & Forge wireframe of 22_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md):
## up / down picks a row, left / right (or light) changes it, dodge closes.
##   Fellowship · Calling · Armor · Weapon · Promote weapon & offhand · Promote
##   armour · Draft a card
## Who you are and what your gear is made of. The cards moved to the Binder (tab
## 2) and the Seals to the Seal Press (tab 4). Promote climbs the Fellowship's
## material ladder one tier at the Forge once its Character Level opens the next
## tier (PartyProgress.request_promotion); the Seals and their Marks come across.
## Draft spends three creature rubbings on a Plain Ink copy of a card the party
## has none of (PartyProgress.request_draft). There's no trade row: the family
## shares one binder, so a card one player finds is everyone's already.
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
## The living storybook atelier look (AtelierTheme, 22 GDD §3).
const SELECTED_COLOR: Color = AtelierTheme.GOLD
const LOCKED_COLOR: Color = AtelierTheme.INK_DIM
const PROBLEM_COLOR: Color = AtelierTheme.BAD
const GOOD_COLOR: Color = AtelierTheme.GOOD
const BORDER_COLOR: Color = AtelierTheme.GILT
const NOTE_TIME: float = 2.5
const ROW_FELLOWSHIP: int = 0
const ROW_CALLING: int = 1
const ROW_ARMOR: int = 2
const ROW_WEAPON: int = 3
const ROW_PROMOTE_WEAPON: int = 4
const ROW_PROMOTE_ARMOR: int = 5
const ROW_DRAFT: int = 6
const ROW_CLOSE: int = 7
const ROW_COUNT: int = 8

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
## The card the Draft row would draft (an index into draft_options()).
var _draft_pick: int = 0


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
	add_theme_stylebox_override(&"panel", AtelierTheme.page_style())
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var title: Label = _label(TITLE_SIZE)
	title.text = "THE ARMORY & SCRIBE DESK"
	title.modulate = BORDER_COLOR.lightened(0.2)
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
	_hint.modulate = AtelierTheme.INK_MUTED
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


## Light changes the row (forward through its options), drafts on the Draft row, or closes on Close.
func accept() -> void:
	if selected == ROW_CLOSE:
		close()
	elif selected == ROW_DRAFT:
		draft_card()
	else:
		cycle(1)


# --- The Forge and the rubbings -------------------------------------------------

## Promotes a piece (PartyProgress.PIECE_WEAPON or PIECE_ARMOR) one material tier through the host,
## or says why it can't. Returns whether the host was asked.
func promote(piece: StringName) -> bool:
	var progress: PartyProgress = PartyProgress.current
	var class_id: StringName = actor.loadout.class_id
	_problem = progress.promotion_problem(class_id, piece)
	if _problem != "":
		AudioCues.play(&"refuse")
		_refresh()
		return false
	var reached: EquipmentTierResource = ArsenalCatalog.current.tier_at(progress.promoted_tier(class_id, piece) + 1)
	progress.request_promotion(class_id, piece)
	AudioCues.play(&"equip")
	_show_note("Promoted to %s at the Forge" % reached.weapon_material_name, true)
	_refresh()
	return true


## The cards three rubbings could draft: every lead card the party has no copy of.
func draft_options() -> Array[StringName]:
	var choices: Array[StringName] = []
	for card: ScribeCardResource in ArsenalCatalog.current.cards():
		if card.is_lead() and PartyProgress.current.best_finish(card.card_id) < 0:
			choices.append(card.card_id)
	return choices


## The card the Draft row shows now, or &"".
func draft_choice() -> StringName:
	var choices: Array[StringName] = draft_options()
	return choices[clampi(_draft_pick, 0, choices.size() - 1)] if not choices.is_empty() else &""


## Spends three rubbings on a Plain Ink copy of the Draft row's card. Returns whether the host was asked.
func draft_card() -> bool:
	var progress: PartyProgress = PartyProgress.current
	var card_id: StringName = draft_choice()
	if card_id == &"" or not progress.can_draft(card_id):
		_problem = "Needs %d rubbings (you have %d)" % [PartyProgress.DRAFT_RUBBINGS, progress.rubbings] if card_id != &"" \
			else "The binder already holds every card"
		AudioCues.play(&"refuse")
		_refresh()
		return false
	progress.request_draft(card_id)
	_problem = ""
	AudioCues.play(&"card_chime")
	_show_note("Drafted a Plain Ink %s" % ArsenalCatalog.current.card(card_id).display_name, true)
	_refresh()
	return true


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
	if selected == ROW_PROMOTE_WEAPON or selected == ROW_PROMOTE_ARMOR:
		if step > 0:
			promote(PartyProgress.PIECE_WEAPON if selected == ROW_PROMOTE_WEAPON else PartyProgress.PIECE_ARMOR)
		return
	if selected == ROW_DRAFT:
		var choices: Array[StringName] = draft_options()
		if not choices.is_empty():
			_draft_pick = wrapi(_draft_pick + step, 0, choices.size())
			AudioCues.play(&"menu_move")
		_refresh()
		return
	var options: Array[StringName] = options_for(selected)
	if options.is_empty():
		return
	var index: int = options.find(_current_option(selected))
	_set_option(selected, options[wrapi(index + step, 0, options.size())])
	var progress: PartyProgress = PartyProgress.current
	_problem = LoadoutComposer.kit_problem(_player_class, draft, progress.grimoire_level(), progress.collection, progress.trail_level())
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
	if not PartyProgress.current.callings_unlocked():
		_show_note("The Secondary Callings open at Level %d" % ArsenalCatalog.CALLING_LEVEL, false)
		AudioCues.play(&"refuse")
		return
	var next: int = wrapi(Callings.resolve(actor.loadout.class_id, actor.loadout.calling) + step, 0, Callings.count())
	AudioCues.play(&"equip")
	NetworkManager.current.update_local_calling(actor.device_id, Callings.id_of(next))


## What a row can be set to: item ids (those the trail has opened).
func options_for(row: int) -> Array[StringName]:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var options: Array[StringName] = []
	var trail_level: int = PartyProgress.current.trail_level()
	if row == ROW_ARMOR:
		for item: EquipmentItemResource in catalog.armors():
			if item.required_level <= trail_level:
				options.append(item.item_id)
	elif row == ROW_WEAPON:
		for item: EquipmentItemResource in catalog.weapons():
			if item.required_level <= trail_level:
				options.append(item.item_id)
	return options


func _current_option(row: int) -> StringName:
	if row == ROW_ARMOR:
		return draft.armor_id
	if row == ROW_WEAPON:
		return draft.weapon_id
	return &""


func _set_option(row: int, option: StringName) -> void:
	if row == ROW_ARMOR:
		draft.armor_id = option
	elif row == ROW_WEAPON:
		draft.weapon_id = option


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
	var progress: PartyProgress = PartyProgress.current
	var level: int = progress.character_level(actor.loadout.class_id)
	var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
	var rank: int = tier.gear_threat_rank if tier != null else 0
	_header.text = "Lv %d  ·  Steward Threat %d  ·  %d rubbings  ·  %d Chimes  ·  Cards in the Binder, Seals in the Seal Press" % [level,
		progress.steward_threat(actor.loadout.class_id, rank), progress.rubbings, progress.chimes]
	for row: int in ROW_COUNT:
		var label: Label = _rows[row]
		var cursor: String = "▶ " if row == selected else "   "
		label.text = cursor + _row_text(row, level)
		label.modulate = SELECTED_COLOR if row == selected else (LOCKED_COLOR if _row_shut(row) else AtelierTheme.INK)
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
		if _player_class.calling == Callings.UNSWORN:
			return "Calling:  Unsworn  ·  opens at Level %d" % ArsenalCatalog.CALLING_LEVEL
		return "Calling:  %s  ·  %s" % [_player_class.display_name, Callings.secondary_label(_player_class.calling)]
	if row == ROW_ARMOR:
		return "Armor:  %s%s" % [_item_name(draft.armor_id), _lock_note(draft.armor_id)]
	if row == ROW_WEAPON:
		return "Weapon frame:  %s%s" % [_item_name(draft.weapon_id), _lock_note(draft.weapon_id)]
	if row == ROW_PROMOTE_WEAPON or row == ROW_PROMOTE_ARMOR:
		return _promote_row_text(row)
	if row == ROW_DRAFT:
		var card_id: StringName = draft_choice()
		if card_id == &"":
			return "Draft a card:  the binder holds every card"
		return "Draft a card:  %d rubbings → Plain Ink %s  (you have %d)" % [PartyProgress.DRAFT_RUBBINGS, catalog.card(card_id).display_name,
			PartyProgress.current.rubbings]
	return "Close"


## "Promote weapon & offhand:  Forge-Iron → Barrow-Steel", or why not yet.
func _promote_row_text(row: int) -> String:
	var progress: PartyProgress = PartyProgress.current
	var piece: StringName = PartyProgress.PIECE_WEAPON if row == ROW_PROMOTE_WEAPON else PartyProgress.PIECE_ARMOR
	var heading: String = "Promote weapon & offhand" if row == ROW_PROMOTE_WEAPON else "Promote armour"
	var now: int = progress.promoted_tier(actor.loadout.class_id, piece)
	var from: EquipmentTierResource = ArsenalCatalog.current.tier_at(now)
	if now >= EquipmentTierResource.TIER_COUNT:
		return "%s:  %s, the top of the ladder" % [heading, from.weapon_material_name]
	var to: EquipmentTierResource = ArsenalCatalog.current.tier_at(now + 1)
	var problem: String = progress.promotion_problem(actor.loadout.class_id, piece)
	return "%s:  %s → %s%s" % [heading, from.weapon_material_name, to.weapon_material_name, ("  ·  " + problem) if problem != "" else ""]


## Whether a row can't be used yet (drawn dim): a promotion the level hasn't opened, or nothing to draft.
func _row_shut(row: int) -> bool:
	if row == ROW_PROMOTE_WEAPON:
		return PartyProgress.current.promotion_problem(actor.loadout.class_id, PartyProgress.PIECE_WEAPON) != ""
	if row == ROW_PROMOTE_ARMOR:
		return PartyProgress.current.promotion_problem(actor.loadout.class_id, PartyProgress.PIECE_ARMOR) != ""
	if row == ROW_DRAFT:
		var card_id: StringName = draft_choice()
		return card_id == &"" or not PartyProgress.current.can_draft(card_id)
	return false


func _detail_text(row: int, catalog: ArsenalCatalog) -> String:
	if row == ROW_FELLOWSHIP:
		return "Your raid seat. Changing it changes who you are: the Shield-Sworn hold the boss, the Wayfarers strike and stamp Signs, the Lantern-Bearers mend down their Soul Tethers."
	if row == ROW_CALLING:
		if _player_class.calling == Callings.UNSWORN:
			return "%s, %s. At Level %d you choose a Secondary Calling: Stout Heart, Swift Foot or Wise Hand." % [_player_class.display_name,
				_player_class.calling_subtitle, ArsenalCatalog.CALLING_LEVEL]
		return "%s, %s. %s: %s." % [_player_class.display_name, _player_class.calling_subtitle, Callings.secondary_name(_player_class.calling),
			Callings.summary(_player_class.calling)]
	if row == ROW_ARMOR:
		var armor: EquipmentItemResource = catalog.item(draft.armor_id)
		return "%d%% Armor Guard · %.1f Breath Recovery a second · %.1f m roll · %d ms Perfect Guard. %s" % [roundi(armor.mitigation * 100.0),
			armor.stamina_regen_per_sec, armor.roll_distance, roundi(armor.perfect_guard_window * 1000.0), armor.description]
	if row == ROW_WEAPON:
		return "%s A frame keeps its tier when you change it." % catalog.item(draft.weapon_id).description.strip_edges()
	if row == ROW_PROMOTE_WEAPON or row == ROW_PROMOTE_ARMOR:
		return _promote_detail(row)
	if row == ROW_DRAFT:
		return "For a card the creatures keep not dropping: calm foes leave rubbings, and %d draft a Plain Ink copy of a card the party has none of. ←/→ picks the card, light drafts it." % PartyProgress.DRAFT_RUBBINGS
	return "Back to Bramble-Bridge."


## What a promotion changes: the next tier's numbers against the worn tier's, and what it takes.
func _promote_detail(row: int) -> String:
	var progress: PartyProgress = PartyProgress.current
	var class_id: StringName = actor.loadout.class_id
	var weapon_row: bool = row == ROW_PROMOTE_WEAPON
	var now: int = progress.promoted_tier(class_id, PartyProgress.PIECE_WEAPON if weapon_row else PartyProgress.PIECE_ARMOR)
	if now >= EquipmentTierResource.TIER_COUNT or actor.seal == null or actor.seal.loadout == null:
		return "Star-Glass and Heart-Crag: nothing finer to forge."
	var from: EquipmentTierResource = ArsenalCatalog.current.tier_at(now)
	var to: EquipmentTierResource = ArsenalCatalog.current.tier_at(now + 1)
	var hand: PlayerLoadoutResource = actor.seal.loadout
	var tail: String = " Your Seals and their Ink-Binding Marks come across: nothing to farm twice. Opens at Lv %d. Cost %d Chimes." % [to.min_true_level,
		PartyProgress.PROMOTE_CHIME_COST[now + 1]]
	if weapon_row:
		var arch: EquipmentTierResource.WeaponArchetype = hand.weapon_archetype as EquipmentTierResource.WeaponArchetype
		return "The same frame, re-forged in %s (%s): it never breaks. Light %.1f → %.1f · Heavy %.1f → %.1f · Stagger ×%.2f → ×%.2f · Steward Threat %d → %d.%s" % [
			to.weapon_material_name, to.weapon_name(arch), from.get_weapon_damage(false, arch), to.get_weapon_damage(false, arch),
			from.get_weapon_damage(true, arch), to.get_weapon_damage(true, arch), from.posture_multiplier, to.posture_multiplier,
			progress.steward_threat(class_id, from.gear_threat_rank), progress.steward_threat(class_id, to.gear_threat_rank), tail]
	var weight: EquipmentTierResource.ArmorWeightClass = hand.armor_weight_class as EquipmentTierResource.ArmorWeightClass
	return "%s → %s, the weight set by your Fellowship. Armor Guard %d%% → %d%%.%s" % [from.get_armor_display_name(weight),
		to.get_armor_display_name(weight), from.armor_guard_percent(weight), to.armor_guard_percent(weight), tail]


## "  (needs Swift Foot)" when the Calling can't use an item, else "".
func _lock_note(id: StringName) -> String:
	var item: EquipmentItemResource = ArsenalCatalog.current.item(id)
	if item == null or _player_class.allows(item):
		return ""
	var unlock: int = Callings.unlocked_by(item)
	return "  (needs %s)" % Callings.secondary_name(unlock) if unlock >= 0 else "  (not for this Fellowship)"


func _item_name(id: StringName) -> String:
	var item: EquipmentItemResource = ArsenalCatalog.current.item(id)
	return item.display_name if item != null else String(id)



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
