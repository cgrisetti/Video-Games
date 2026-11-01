## One local player's HUD, drawn over their split-screen cell: the boss's
## health, poise, cast and aggro along the top; your health, stamina,
## resonance pips, queued input and Soul Tether bottom-left; your controls
## along the bottom. A big banner in the middle marks moments the whole party
## shares (a victory, the loot). Next to the Shard Vendor a prompt says what
## light does, and its upgrade menu opens over this view.
class_name PlayerHUD
extends Control

const MARGIN: float = 14.0
const BOSS_BAR_WIDTH: float = 0.56
const PLAYER_BAR_WIDTH: float = 240.0
const FONT_SIZE: int = 17
const SMALL_FONT_SIZE: int = 13
const HEALTH_COLOR: Color = Color(0.85, 0.22, 0.24)
const STAMINA_COLOR: Color = Color(0.95, 0.8, 0.3)
const POISE_COLOR: Color = Color(0.95, 0.65, 0.25)
const CAST_COLOR: Color = Color(0.75, 0.55, 1.0)
const BAR_BACK: Color = Color(0.06, 0.06, 0.08, 0.75)
## Room left for the dojo's banner when this cell touches the top of the screen.
const BANNER_CLEARANCE: float = 52.0
const FLASH_TIME: float = 0.6
const TETHER_COLOR: Color = Color(0.5, 1.0, 0.62)
## A resonance jump at least this big (a reward, not a hit) makes the pips flash.
const REWARD_FLASH_PIPS: float = 0.4
const BANNER_TITLE_SIZE: int = 44
## Real seconds for the banner to fade in (it ignores slow motion).
const BANNER_FADE_TIME: float = 0.3

var actor: ActorBase

var _top_panel: VBoxContainer
var _boss_label: Label
var _boss_health: ProgressBar
var _boss_poise: ProgressBar
var _cast_bar: ProgressBar
var _cast_label: Label
var _aggro_label: Label
var _class_label: Label
var _kit_label: Label
var _health: ProgressBar
var _stamina: ProgressBar
var _pips_label: Label
var _queue_label: Label
var _tether_label: Label
var _status_label: Label
var _controls_label: Label
var _flow_label: Label
var _compass_labels: Array[Label] = []
var _banner: VBoxContainer
var _banner_title: Label
var _banner_subtitle: Label
var _prompt_label: Label
## The menu open over this view (the Shard Vendor's or the Scribe Desk's).
var _menu: Control
var _flow_flash_left: float = 0.0
var _pips_flash_left: float = 0.0
var _last_resonance: float = 0.0


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "PlayerHUD"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top: VBoxContainer = VBoxContainer.new()
	top.anchor_left = 0.5 - BOSS_BAR_WIDTH * 0.5
	top.anchor_right = 0.5 + BOSS_BAR_WIDTH * 0.5
	top.offset_top = MARGIN
	top.add_theme_constant_override(&"separation", 3)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_top_panel = top
	_boss_label = _label(FONT_SIZE)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_boss_label)
	_boss_health = _bar(HEALTH_COLOR, 14.0)
	top.add_child(_boss_health)
	_boss_poise = _bar(POISE_COLOR, 5.0)
	top.add_child(_boss_poise)
	_cast_label = _label(SMALL_FONT_SIZE)
	_cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_cast_label)
	_cast_bar = _bar(CAST_COLOR, 8.0)
	top.add_child(_cast_bar)
	_aggro_label = _label(SMALL_FONT_SIZE)
	_aggro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_aggro_label)

	var bottom: VBoxContainer = VBoxContainer.new()
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = MARGIN
	bottom.offset_bottom = -MARGIN - 34.0
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.custom_minimum_size = Vector2(PLAYER_BAR_WIDTH, 0.0)
	bottom.add_theme_constant_override(&"separation", 3)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	_status_label = _label(FONT_SIZE)
	bottom.add_child(_status_label)
	_tether_label = _label(SMALL_FONT_SIZE)
	bottom.add_child(_tether_label)
	_queue_label = _label(SMALL_FONT_SIZE)
	bottom.add_child(_queue_label)
	_class_label = _label(FONT_SIZE)
	bottom.add_child(_class_label)
	_kit_label = _label(SMALL_FONT_SIZE)
	_kit_label.modulate = Color(1.0, 1.0, 1.0, 0.85)
	bottom.add_child(_kit_label)
	_health = _bar(HEALTH_COLOR, 14.0)
	bottom.add_child(_health)
	_stamina = _bar(STAMINA_COLOR, 8.0)
	bottom.add_child(_stamina)
	_pips_label = _label(FONT_SIZE)
	bottom.add_child(_pips_label)

	_controls_label = _label(SMALL_FONT_SIZE)
	_controls_label.anchor_top = 1.0
	_controls_label.anchor_bottom = 1.0
	_controls_label.anchor_right = 1.0
	_controls_label.offset_left = MARGIN
	_controls_label.offset_right = -MARGIN
	_controls_label.offset_top = -MARGIN - 32.0
	_controls_label.offset_bottom = -6.0
	_controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_controls_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	add_child(_controls_label)

	# "FLOW" pops up mid-screen when a buffered follow-up skips the recovery.
	_flow_label = _label(30)
	_flow_label.anchor_left = 0.5
	_flow_label.anchor_right = 0.5
	_flow_label.anchor_top = 0.62
	_flow_label.anchor_bottom = 0.62
	_flow_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flow_label.modulate = Color(0.6, 0.85, 1.0, 0.0)
	add_child(_flow_label)

	_banner = VBoxContainer.new()
	_banner.name = "Banner"
	_banner.anchor_left = 0.06
	_banner.anchor_right = 0.94
	_banner.anchor_top = 0.2
	_banner.anchor_bottom = 0.2
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)
	_banner_title = _label(BANNER_TITLE_SIZE)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_title)
	_banner_subtitle = _label(FONT_SIZE)
	_banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_subtitle)

	_prompt_label = _label(FONT_SIZE)
	_prompt_label.anchor_left = 0.5
	_prompt_label.anchor_right = 0.5
	_prompt_label.anchor_top = 0.7
	_prompt_label.anchor_bottom = 0.7
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.modulate = Color(0.75, 0.9, 1.0)
	_prompt_label.visible = false
	add_child(_prompt_label)
	if actor != null:
		actor.action_queue.flow_cancelled.connect(_on_flow_cancelled)
		_last_resonance = actor.stats.resonance_charge
		if actor.tether != null:
			add_child(_build_tether_compass())


func _process(_delta: float) -> void:
	if not is_instance_valid(actor) or actor.stats == null:
		return
	_top_panel.offset_top = MARGIN + (BANNER_CLEARANCE if get_global_rect().position.y < 1.0 else 0.0)
	_refresh_boss()
	_refresh_player()


## Opens the Shard Vendor's upgrade menu over this player's view.
func open_upgrade_menu() -> void:
	if _live_menu() != null:
		return
	var menu: HubUpgradeMenu = HubUpgradeMenu.new()
	menu.setup(actor)
	_menu = menu
	add_child(menu)


## Opens the Armory & Scribe Desk menu over this player's view.
func open_scribe_desk() -> void:
	if _live_menu() != null:
		return
	var menu: ScribeDeskMenu = ScribeDeskMenu.new()
	menu.setup(actor)
	_menu = menu
	add_child(menu)


func upgrade_menu() -> HubUpgradeMenu:
	return _live_menu() as HubUpgradeMenu


func scribe_desk_menu() -> ScribeDeskMenu:
	return _live_menu() as ScribeDeskMenu


func _live_menu() -> Control:
	return _menu if is_instance_valid(_menu) and not _menu.is_queued_for_deletion() else null


## What pressing light does here, or "" when there's nothing to use.
func prompt_text() -> String:
	return _prompt_label.text if _prompt_label.visible else ""


## A big centred message for the whole party, like VICTORY!
func show_banner(title: String, subtitle: String, color: Color) -> void:
	_banner_title.text = title
	_banner_title.modulate = color
	_banner_subtitle.text = subtitle
	_banner.visible = true
	_banner.modulate.a = 0.0
	var fade: Tween = create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_property(_banner, "modulate:a", 1.0, BANNER_FADE_TIME)


func hide_banner() -> void:
	_banner.visible = false


## The banner's title, or "" when it's hidden.
func banner_title() -> String:
	return _banner_title.text if _banner.visible else ""


func _refresh_boss() -> void:
	var boss: BossDummy = CombatDirector.current.primary_boss() as BossDummy
	# No boss here (Hub Town), or it's beaten: no bars to show.
	_top_panel.visible = boss != null and boss.stats != null and not boss.vanquished
	if not _top_panel.visible:
		return
	var primer: int = CombatDirector.current.primer_on(boss)
	var title: String = boss.display_name()
	if boss.stats.is_downed:
		title += " (defeated)"
	elif boss.stats.is_knocked_down():
		title += " (KNOCKED DOWN)"
	if primer != ScribeSignResource.Sign.NONE:
		title += "  ·  %s seal" % ArsenalCatalog.current.sign_seal(primer).seal_name
	_boss_label.text = title
	_boss_health.max_value = boss.stats.stats.max_health
	_boss_health.value = boss.stats.health
	_boss_poise.max_value = boss.stats.stats.max_poise
	_boss_poise.value = boss.stats.poise
	var casting: bool = boss.is_casting()
	_cast_bar.visible = casting
	_cast_label.visible = casting
	if casting:
		_cast_label.text = "Casting %s" % boss.cast_name
		_cast_bar.max_value = 1.0
		_cast_bar.value = boss.cast_progress()
	var target_id: StringName = boss.threat.current_target if boss.threat != null else &""
	if target_id == &"":
		_aggro_label.text = "Walk up to the Cairnsman to start the fight"
		_aggro_label.modulate = Color.WHITE
	elif target_id == actor.player_id:
		_aggro_label.text = "Aggro: on YOU" + ("" if actor.role() == ClassLoadoutResource.Role.TANK else "  (let the tank taunt it back)")
		_aggro_label.modulate = Color(1.0, 0.55, 0.45)
	else:
		var holder: ActorBase = CombatDirector.current.get_actor(target_id)
		_aggro_label.text = "Aggro: %s" % (holder.display_name() if holder != null else String(target_id))
		_aggro_label.modulate = Color(0.85, 0.9, 1.0)


func _refresh_player() -> void:
	var stats: StatsComponent = actor.stats
	var mode: String = actor.input.mode_name() if actor.input != null else ""
	_class_label.text = "%s  ·  %s  ·  %s" % [actor.display_name(), mode, actor.input.device_label() if actor.input != null else ""]
	var loadout: ClassLoadoutResource = actor.loadout
	_kit_label.visible = loadout.weapon != null and loadout.armor != null
	if _kit_label.visible:
		_kit_label.text = "%s  ·  %s  ·  Grimoire Lv %d" % [loadout.weapon.display_name, loadout.armor.display_name, PartyProgress.current.grimoire_level()]
	_class_label.modulate = actor.loadout.body_color.lightened(0.3)
	_health.max_value = stats.stats.max_health
	_health.value = stats.health
	_stamina.max_value = stats.stats.max_stamina
	_stamina.value = stats.stamina
	var pips: int = stats.resonance_pips()
	var dots: String = ""
	for index: int in stats.stats.max_resonance_pips:
		if index < pips:
			dots += "● "
		elif index == pips and stats.resonance_charge - pips > 0.01:
			dots += "◐ "
		else:
			dots += "○ "
	_pips_label.text = "Resonance  " + dots

	var queue: ActionQueueComponent = actor.action_queue
	var queued: PackedStringArray = PackedStringArray()
	for command: int in queue.buffer:
		queued.append(command_name(command))
	var line: String = ""
	if queue.current_action != null:
		line = queue.current_action.display_name
		if queue.flowed_into_current:
			line += "  (FLOW%s)" % (" +15%" if queue.speed_scale > 1.0 else "")
	if not queued.is_empty():
		line += "   Queued ▶ " + ", ".join(queued)
	_queue_label.text = line

	_tether_label.visible = actor.tether != null
	if actor.tether != null:
		var tethered: ActorBase = actor.tether.tethered_actor()
		if tethered != null:
			_tether_label.text = "Soul Tether %s %s (%d%%)" % [
				actor.tether.slot_arrow_for(tethered.player_id), tethered.display_name(), roundi(tethered.stats.health_ratio() * 100.0)]

	var status: String = ""
	if stats.is_downed:
		status = "Downed: back up in %ds (a heal brings you back sooner)" % ceili(actor.downed_time_left)
	elif actor.state_machine.is_in(&"stagger"):
		status = "Staggered!"
	elif stats.guarding:
		status = "Guarding"
	_status_label.text = status
	_controls_label.text = controls_text()
	_prompt_label.visible = is_instance_valid(actor.interactable) and _live_menu() == null
	if _prompt_label.visible:
		_prompt_label.text = actor.interactable.prompt_for(actor)
	_refresh_flashes()
	_refresh_tether_compass()


func _on_flow_cancelled(_from: CombatActionResource, _to: CombatActionResource) -> void:
	_flow_flash_left = FLASH_TIME
	var bonus: float = actor.action_queue.speed_scale - 1.0
	_flow_label.text = "FLOW  +%d%% speed" % roundi(bonus * 100.0) if bonus > 0.0 else "FLOW"


func _refresh_flashes() -> void:
	var delta: float = get_process_delta_time()
	_flow_flash_left = maxf(0.0, _flow_flash_left - delta)
	_flow_label.modulate.a = _flow_flash_left / FLASH_TIME
	var charge: float = actor.stats.resonance_charge
	if charge - _last_resonance >= REWARD_FLASH_PIPS:
		_pips_flash_left = FLASH_TIME
	_last_resonance = charge
	_pips_flash_left = maxf(0.0, _pips_flash_left - delta)
	var glow: float = _pips_flash_left / FLASH_TIME
	_pips_label.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.9, 0.4), glow)
	_pips_label.scale = Vector2.ONE * (1.0 + glow * 0.25)


## The healer's D-Pad compass: which direction tethers whom, with their health.
func _build_tether_compass() -> Control:
	var compass: GridContainer = GridContainer.new()
	compass.name = "TetherCompass"
	compass.columns = 3
	compass.anchor_left = 1.0
	compass.anchor_right = 1.0
	compass.anchor_top = 1.0
	compass.anchor_bottom = 1.0
	compass.offset_left = -MARGIN - 330.0
	compass.offset_right = -MARGIN
	compass.offset_top = -MARGIN - 150.0
	compass.offset_bottom = -MARGIN - 40.0
	compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Up, right, down, left sit in the middle cells of a 3 x 3 grid around the D-Pad.
	var cell_for_slot: Array[int] = [1, 5, 7, 3]
	var cells: Array[Control] = []
	for index: int in 9:
		var cell: Label = _label(SMALL_FONT_SIZE)
		cell.custom_minimum_size = Vector2(110.0, 0.0)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		compass.add_child(cell)
		cells.append(cell)
	(cells[4] as Label).text = "✚"
	for slot: int in cell_for_slot.size():
		_compass_labels.append(cells[cell_for_slot[slot]] as Label)
	return compass


func _refresh_tether_compass() -> void:
	if actor.tether == null:
		return
	var allies: Array[ActorBase] = actor.tether.allies()
	for slot: int in _compass_labels.size():
		var label: Label = _compass_labels[slot]
		if slot >= allies.size():
			label.text = "%s —" % SoulTetherComponent.SLOT_ARROWS[slot]
			label.modulate = Color(1.0, 1.0, 1.0, 0.4)
			continue
		var ally: ActorBase = allies[slot]
		var tethered: bool = ally.player_id == actor.tether.tethered_id
		label.text = "%s %s\n%s %d%%" % [SoulTetherComponent.SLOT_ARROWS[slot], ally.display_name().get_slice(" ", 0),
			ally.loadout.display_name.get_slice(" ", 0), roundi(ally.stats.health_ratio() * 100.0)]
		label.modulate = TETHER_COLOR if tethered else Color(1.0, 1.0, 1.0, 0.85)


## The controls line, named from the Input Map for this player's own device:
## keys for the keyboard player, Xbox letters or PlayStation shapes for pads.
func controls_text() -> String:
	if actor.input == null:
		return ""
	var input: InputComponent = actor.input
	var loadout: ClassLoadoutResource = actor.loadout
	var keyboard: bool = input.is_keyboard()
	var light: String = input.label(InputComponent.ACTION_LIGHT)
	var heavy: String = input.label(InputComponent.ACTION_HEAVY)
	var trigger_l: String = input.label(InputComponent.ACTION_TRIGGER_L)
	var trigger_r: String = input.label(InputComponent.ACTION_TRIGGER_R)
	var up: String = input.label(InputComponent.ACTION_MOVE_FORWARD) if keyboard else "↑"
	var down: String = input.label(InputComponent.ACTION_MOVE_BACK) if keyboard else "↓"
	var attacks: String = "%s or %s: smart attack" % [light, heavy]
	if input.assist_mode != InputComponent.AssistMode.SQUIRE_GAMBIT:
		attacks = "%s light · %s heavy · %s+%s %s · %s+%s %s" % [light, heavy, up, heavy, loadout.forward_label, down, heavy, loadout.back_label]
	var ult_keys: String = "%s+%s" % [trigger_l, trigger_r]
	if keyboard:
		ult_keys = "%s or %s" % [input.label(InputComponent.ACTION_ULT), ult_keys]
	var tethers: String = ""
	if loadout.has_soul_tethers:
		tethers = " · %s tether" % ("1-4" if keyboard else "D-Pad")
	return "%s move · %s · %s dodge · %s %s · %s %s · %s %s%s · %s · hold %s: class · hold %s: mode" % [
		"WASD" if keyboard else "Stick", attacks, input.label(InputComponent.ACTION_DODGE),
		trigger_l, loadout.trigger_l_label, trigger_r, loadout.trigger_r_label, ult_keys, loadout.ult_label, tethers,
		"Mouse or ←/→ camera" if keyboard else "Right stick camera",
		input.label(InputComponent.ACTION_CHANGE_CLASS), input.label(InputComponent.ACTION_CHANGE_MODE)]


static func command_name(command: int) -> String:
	match command:
		CombatActionResource.Command.LIGHT:
			return "Light"
		CombatActionResource.Command.HEAVY:
			return "Heavy"
		CombatActionResource.Command.FORWARD_HEAVY:
			return "Fwd+Heavy"
		CombatActionResource.Command.BACK_HEAVY:
			return "Back+Heavy"
		CombatActionResource.Command.DODGE:
			return "Dodge"
		CombatActionResource.Command.TRIGGER_L_SKILL:
			return "L"
		CombatActionResource.Command.TRIGGER_R_SKILL:
			return "R"
		CombatActionResource.Command.TRIGGER_R_HOLD:
			return "Hold R"
		CombatActionResource.Command.TRIGGER_BOTH_ULT:
			return "L+R"
	return "?"


func _label(size: int) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override(&"outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _bar(color: Color, height: float) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = BAR_BACK
	back.set_corner_radius_all(3)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override(&"background", back)
	bar.add_theme_stylebox_override(&"fill", fill)
	return bar
