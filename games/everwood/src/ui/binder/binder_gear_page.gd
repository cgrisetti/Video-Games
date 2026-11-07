## Binder tab 1, Gear & Weapon, laid out as the Gear wireframe has it
## (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §2, the Menu Wireframes) on
## the Binder's 1600 x 900 sheet:
##   left    the hero: name, Fellowship (role) and Calling; Steward Threat as a
##           sum (Character Lv + the material's rank); the stage; what the kit
##           adds up to; the wards its Seals give
##   middle  the live hero turning in its lit preview, its three Seals named
##           where they glow (crest, script, hem), and the youth body
##   right   the three pieces (weapon, offhand, mantle), each with its Seal:
##           the finish, who pressed it, what it does on that piece, and its
##           Ink-Binding Marks toward the next press
## Up / down (or a click) looks over the pieces and the Calling; it's all
## look-only here: the gear changes at the Scribe Desk, the Seals in the Seal
## Press (light, at a rest point).
class_name BinderGearPage
extends Control

const LEFT: Rect2 = Rect2(40.0, 228.0, 360.0, 600.0)
const MIDDLE: Rect2 = Rect2(424.0, 228.0, 360.0, 600.0)
const RIGHT: Rect2 = Rect2(808.0, 228.0, 752.0, 600.0)
const PIECE_HEIGHT: float = 176.0
const SEAL_WIDTH: float = 300.0
const PREVIEW_BOX: Vector2 = Vector2(360.0, 432.0)
## Where each Seal's glow is named over the preview: the offhand's crest, the weapon's script, the mantle's hem.
const CALLOUT_SPOTS: Array[Vector2] = [Vector2(212.0, 40.0), Vector2(8.0, 150.0), Vector2(196.0, 364.0)]
const CALLOUT_WORDS: Array[String] = ["script", "crest", "hem"]
const PIECE_SEALS: Array[int] = [PlayerLoadoutResource.HandSlot.WEAPON_SEAL, PlayerLoadoutResource.HandSlot.OFFHAND_SEAL,
	PlayerLoadoutResource.HandSlot.MANTLE_SEAL]

var binder: GrimoireBinderPanel
var _hero_box: PanelContainer
var _hero: VBoxContainer
var _middle: VBoxContainer
## Where the Binder's preview frame sits on this page (it moves to the Seal Press with the tab).
var preview_slot: Control
var _callouts: Control
var _body: HBoxContainer
var _pieces: VBoxContainer


func build(owner: GrimoireBinderPanel) -> void:
	binder = owner
	name = "GearPage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = GrimoireBinderPanel.SHEET_SIZE
	_hero_box = BinderKit.row_box(false)
	BinderKit.place(self, _hero_box, LEFT.position, LEFT.size.x)
	BinderKit.on_click(_hero_box, _pick.bind(GrimoireBinderPanel.GearRow.CALLING))
	_hero = BinderKit.column(8)
	_hero_box.add_child(_hero)
	_middle = BinderKit.column(10)
	BinderKit.place(self, _middle, MIDDLE.position, MIDDLE.size.x)
	preview_slot = Control.new()
	preview_slot.name = "PreviewSlot"
	preview_slot.custom_minimum_size = PREVIEW_BOX
	preview_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_middle.add_child(preview_slot)
	_callouts = Control.new()
	_callouts.name = "Callouts"
	_callouts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_callouts.size = PREVIEW_BOX
	preview_slot.add_child(_callouts)
	var caption: Label = BinderKit.text("Live hero · it turns slowly in the lamplight", AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM)
	_middle.add_child(caption)
	_middle.add_child(BinderKit.kicker("Youth body"))
	_body = BinderKit.line(8)
	_middle.add_child(_body)
	_pieces = BinderKit.column(12)
	BinderKit.place(self, _pieces, RIGHT.position, RIGHT.size.x)


## Redraws every box from the hero as it is now.
func refresh() -> void:
	if not is_instance_valid(binder) or not is_instance_valid(binder.actor):
		return
	var calling_chosen: bool = binder.gear_row == GrimoireBinderPanel.GearRow.CALLING
	_hero_box.add_theme_stylebox_override(&"panel", _box_style(calling_chosen))
	_fill_hero()
	_fill_callouts()
	_fill_body()
	_fill_pieces()


func _box_style(chosen: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = AtelierTheme.row_style(chosen)
	style.set_content_margin_all(14.0)
	return style


# --- Left: the hero -----------------------------------------------------------------------

func _fill_hero() -> void:
	BinderKit.clear(_hero)
	var actor: ActorBase = binder.actor
	var loadout: ClassLoadoutResource = actor.loadout
	var player_class: PlayerClassResource = binder._player_class()
	var progress: PartyProgress = PartyProgress.current
	_hero.add_child(BinderKit.text(loadout.display_name, BinderKit.NAME_SIZE + 4, AtelierTheme.INK))
	var calling: String = "Unsworn" if loadout.calling == Callings.UNSWORN else Callings.secondary_name(loadout.calling)
	_hero.add_child(BinderKit.text("%s (%s) · %s" % [player_class.fellowship_name, BinderKit.role_word(loadout.role), calling],
		AtelierTheme.BODY_SIZE - 1, AtelierTheme.INK_MUTED))
	var level: int = progress.character_level(loadout.class_id)
	var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
	var rank: int = tier.gear_threat_rank if tier != null else 0
	var sum: HBoxContainer = BinderKit.line(6)
	sum.alignment = BoxContainer.ALIGNMENT_CENTER
	sum.add_child(BinderKit.number_box(str(level), "Character Lv"))
	sum.add_child(BinderKit.text("+", BinderKit.NAME_SIZE, AtelierTheme.GILT))
	sum.add_child(BinderKit.number_box(str(rank), tier.weapon_material_name if tier != null else "Material"))
	sum.add_child(BinderKit.text("=", BinderKit.NAME_SIZE, AtelierTheme.GILT))
	sum.add_child(BinderKit.number_box(str(progress.steward_threat(loadout.class_id, rank)), "Threat", AtelierTheme.GOLD))
	_hero.add_child(sum)
	var stage: int = actor.seal.progression_stage if actor.seal != null else PlayerLoadoutResource.stage_for_true_level(level)
	_hero.add_child(BinderKit.text("Stage %d · %s" % [stage, PlayerLoadoutResource.STAGE_NAMES[clampi(stage, 0, 4)]],
		AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK_DIM))
	_hero.add_child(BinderKit.kicker("What your kit adds up to"))
	_hero.add_child(BinderKit.stat_grid(_kit_sums(), LEFT.size.x - 30.0))
	_hero.add_child(BinderKit.kicker("Wards from your Seals"))
	var wards: PackedStringArray = _seal_wards()
	if wards.is_empty():
		wards.append("No Seal wards you yet: an offhand Seal does.")
	for ward: String in wards:
		_hero.add_child(BinderKit.text(ward, AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK, LEFT.size.x - 30.0))


## The kit's totals the wireframe lists: Armor Guard, Light / Heavy, Stagger, Breath Recovery, Roll, Perfect Guard.
func _kit_sums() -> Array[PackedStringArray]:
	var actor: ActorBase = binder.actor
	var stats: CharacterStatsResource = actor.stats.stats
	var sums: Array[PackedStringArray] = []
	var tier: EquipmentTierResource = actor.seal.tier() if actor.seal != null else null
	if tier != null:
		var hand: PlayerLoadoutResource = actor.seal.loadout
		var arch: EquipmentTierResource.WeaponArchetype = hand.weapon_archetype as EquipmentTierResource.WeaponArchetype
		var weight: EquipmentTierResource.ArmorWeightClass = hand.armor_weight_class as EquipmentTierResource.ArmorWeightClass
		var armour: EquipmentTierResource = binder.armour_tier()
		sums.append(PackedStringArray(["Armor Guard", "%d%%" % armour.armor_guard_percent(weight)]))
		sums.append(PackedStringArray(["Light / Heavy", "%.1f / %.1f" % [tier.get_weapon_damage(false, arch), tier.get_weapon_damage(true, arch)]]))
		sums.append(PackedStringArray(["Stagger", "×%.2f" % tier.posture_multiplier]))
	sums.append(PackedStringArray(["Health", str(roundi(stats.max_health))]))
	sums.append(PackedStringArray(["Breath Recovery", "%.1f / s" % stats.stamina_regen_per_sec]))
	sums.append(PackedStringArray(["Roll", "%.1f m" % stats.roll_distance]))
	sums.append(PackedStringArray(["Perfect Guard", "%d ms" % roundi(stats.perfect_guard_window * 1000.0)]))
	return sums


## Each Seal that wards off a Sign, as a line: "Star-Tide −30% on guard · no stun".
func _seal_wards() -> PackedStringArray:
	var wards: PackedStringArray = PackedStringArray()
	var hand: PlayerLoadoutResource = binder.actor.seal.loadout if binder.actor.seal != null else null
	if hand == null:
		return wards
	for pressed: Array in hand.seal_slots():
		var card: ScribeCardResource = ArsenalCatalog.current.get_card(pressed[1])
		if card == null:
			continue
		var passive: Dictionary = card.slot_passive(int(pressed[0]))
		var ward: float = float(passive.get("ward", 0.0))
		if ward <= 0.0:
			continue
		var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(card.scribe_sign)
		wards.append("%s −%d%%%s" % [seal.display_name, roundi(ward * 100.0), " · no stun" if bool(passive.get("stun", false)) else ""])
	return wards


# --- Middle: the live hero ------------------------------------------------------------------

func _fill_callouts() -> void:
	BinderKit.clear(_callouts)
	var hand: PlayerLoadoutResource = binder.actor.seal.loadout if binder.actor.seal != null else null
	if hand == null:
		return
	var ids: Array[StringName] = hand.seal_card_ids()
	for index: int in ids.size():
		var card: ScribeCardResource = ArsenalCatalog.current.get_card(ids[index])
		if card == null:
			continue
		var tag: PanelContainer = BinderKit.chip("%s %s" % [_short_name(card.display_name), CALLOUT_WORDS[index]],
			AtelierTheme.sign_fill(card.scribe_sign), AtelierTheme.INK)
		(tag.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color = Color(0.07, 0.05, 0.035, 0.88)
		_callouts.add_child(tag)
		tag.position = CALLOUT_SPOTS[index]


## The last word of a card's name, for a callout ("Ebb-Quay Star-Bell" → "Star-Bell").
static func _short_name(full: String) -> String:
	var words: PackedStringArray = full.split(" ")
	return words[words.size() - 1] if not words.is_empty() else full


func _fill_body() -> void:
	BinderKit.clear(_body)
	var hand: PlayerLoadoutResource = binder.actor.seal.loadout if binder.actor.seal != null else null
	var worn: int = int(hand.body_type) if hand != null else 0
	for index: int in 2:
		var chosen: bool = index == worn
		_body.add_child(BinderKit.chip(["Male Youth", "Female Youth"][index], AtelierTheme.GOLD if chosen else AtelierTheme.LINE_DIM,
			AtelierTheme.INK if chosen else AtelierTheme.INK_DIM))


# --- Right: the three pieces and their Seals -------------------------------------------------

func _fill_pieces() -> void:
	BinderKit.clear(_pieces)
	var rows: Array[Label] = []
	for piece: int in PIECE_SEALS.size():
		rows.append(_add_piece(piece))
	var calling: Label = BinderKit.text(binder.actor.loadout.display_name, 1)
	calling.visible = false
	_pieces.add_child(calling)
	rows.append(calling)
	binder._gear_rows = rows


## One piece's row: what it is and its numbers on the left, its Seal on the right. Returns its name label.
func _add_piece(piece: int) -> Label:
	var actor: ActorBase = binder.actor
	var box: PanelContainer = BinderKit.panel(_box_style(binder.gear_row == piece))
	box.custom_minimum_size = Vector2(RIGHT.size.x, PIECE_HEIGHT)
	BinderKit.on_click(box, _pick.bind(piece))
	_pieces.add_child(box)
	var split: HBoxContainer = BinderKit.line(16)
	box.add_child(split)
	var about: VBoxContainer = BinderKit.column(6)
	about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(about)
	var words: PackedStringArray = binder.piece_words(piece)
	about.add_child(BinderKit.kicker(words[0]))
	var named: Label = BinderKit.text(words[1], BinderKit.NAME_SIZE, AtelierTheme.INK)
	about.add_child(named)
	about.add_child(BinderKit.text(words[2], AtelierTheme.SMALL_SIZE + 1, AtelierTheme.INK_MUTED, RIGHT.size.x - SEAL_WIDTH - 60.0))
	about.add_child(BinderKit.text(words[3], AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM, RIGHT.size.x - SEAL_WIDTH - 60.0))
	split.add_child(_seal_panel(PIECE_SEALS[piece]))
	return named


## A piece's Seal: its finish and who pressed it, its name and Sign, what it does here, and its Marks.
func _seal_panel(slot: int) -> PanelContainer:
	var style: StyleBoxFlat = AtelierTheme.page_style(true)
	style.border_color = AtelierTheme.LINE
	style.set_border_width_all(1)
	style.set_content_margin_all(10.0)
	var box: PanelContainer = BinderKit.panel(style)
	box.custom_minimum_size = Vector2(SEAL_WIDTH, 0.0)
	var stack: VBoxContainer = BinderKit.column(5)
	box.add_child(stack)
	var slot_name: String = GrimoireRules.SEAL_NAMES[slot]
	if not binder.seal_slot_open(slot):
		stack.add_child(BinderKit.kicker("%s Seal" % slot_name, AtelierTheme.INK_DIM))
		stack.add_child(BinderKit.text("▢ Opens at Lv %d" % GrimoireRules.SEAL_OPEN_LEVELS[slot], AtelierTheme.BODY_SIZE, AtelierTheme.INK_DIM))
		return box
	var card_id: StringName = binder.actor.seal.loadout.card_in_slot(slot)
	var card: ScribeCardResource = ArsenalCatalog.current.get_card(card_id)
	if card == null:
		stack.add_child(BinderKit.kicker("%s Seal" % slot_name))
		stack.add_child(BinderKit.text("◇ Empty", AtelierTheme.BODY_SIZE, AtelierTheme.INK_MUTED))
		stack.add_child(BinderKit.text("Press one in the Seal Press at a Hearth-Brazier.", AtelierTheme.SMALL_SIZE, AtelierTheme.INK_DIM, SEAL_WIDTH - 24.0))
		return box
	var progress: PartyProgress = PartyProgress.current
	var finish: int = maxi(progress.best_finish(card_id), 0)
	var key: StringName = ScribeCardResource.copy_key(card_id, finish as ScribeCardResource.CardVariant)
	var maker: String = String(progress.maker_seals.get(key, ""))
	stack.add_child(BinderKit.kicker("%s Seal · %s%s" % [slot_name, ScribeCardResource.VARIANT_NAMES[finish], (" · pressed by " + maker) if maker != "" else ""]))
	var title: HBoxContainer = BinderKit.line(6)
	title.add_child(BinderKit.text(card.display_name, AtelierTheme.BODY_SIZE, AtelierTheme.INK))
	title.add_child(BinderKit.sign_chip(card.scribe_sign))
	stack.add_child(title)
	stack.add_child(BinderKit.text(binder.seal_effect_text(slot), AtelierTheme.SMALL_SIZE, AtelierTheme.INK_MUTED, SEAL_WIDTH - 24.0))
	var needed: int = PartyProgress.marks_needed(key)
	if needed > 0:
		stack.add_child(BinderKit.marks_bar(progress.marks_of(key), needed))
		var next_name: String = ScribeCardResource.VARIANT_NAMES[mini(finish + 1, ScribeCardResource.VARIANT_NAMES.size() - 1)]
		var line_text: String = ("Ready to Press: %s at the Scribery" % next_name) if progress.ready_to_press(key) \
			else "%d / %d Marks → %s" % [progress.marks_of(key), needed, next_name]
		stack.add_child(BinderKit.text(line_text, AtelierTheme.SMALL_SIZE - 1, AtelierTheme.INK_DIM, SEAL_WIDTH - 24.0))
	else:
		stack.add_child(BinderKit.text("Fully pressed: Star-Ink", AtelierTheme.SMALL_SIZE - 1, AtelierTheme.GOOD))
	return box


func _pick(row: int) -> void:
	binder.gear_row = row
	AudioCues.play(&"menu_move")
	binder._refresh()
