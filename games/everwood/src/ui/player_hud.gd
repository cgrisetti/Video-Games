## One local player's HUD, drawn over their split-screen cell: the boss's
## health, poise, cast and aggro along the top, and the Cross-Grimoire HUD
## bottom-centre (CrossGrimoireHUD: health, stamina, pips, Chimes and every
## move's slot, readable by shape and colour). A big banner in the middle marks
## moments the whole party shares (a victory, the loot). Next to the
## Chime-Shrine or the Scribe Desk a prompt says what light does, and their
## menus open over this view.
class_name PlayerHUD
extends Control

const MARGIN: float = 14.0
const BOSS_BAR_WIDTH: float = 0.56
const FONT_SIZE: int = 17
const SMALL_FONT_SIZE: int = 13
const HEALTH_COLOR: Color = Color(0.85, 0.22, 0.24)
const POISE_COLOR: Color = Color(0.95, 0.65, 0.25)
const CAST_COLOR: Color = Color(0.75, 0.55, 1.0)
const BAR_BACK: Color = Color(0.06, 0.06, 0.08, 0.75)
## The boss's bars show once it's in the fight or within this many metres.
const BOSS_BAR_RANGE: float = 36.0
## Room left for the level's banner when this cell touches the top of the screen.
const BANNER_CLEARANCE: float = 52.0
const FLASH_TIME: float = 0.6
const BANNER_TITLE_SIZE: int = 44
## Real seconds for the banner to fade in (it ignores slow motion).
const BANNER_FADE_TIME: float = 0.3

var actor: ActorBase
## The bottom-centre cross of move slots and gauges.
var cross_grimoire: CrossGrimoireHUD

var _top_panel: VBoxContainer
var _boss_label: Label
var _boss_health: ProgressBar
var _boss_poise: ProgressBar
var _cast_bar: ProgressBar
var _cast_label: Label
var _aggro_label: Label
var _flow_label: Label
var _banner: VBoxContainer
var _banner_title: Label
var _banner_subtitle: Label
var _prompt_label: Label
## The menu open over this view (the Chime-Shrine's or the Scribe Desk's).
var _menu: Control
var _flow_flash_left: float = 0.0


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

	cross_grimoire = CrossGrimoireHUD.new()
	cross_grimoire.setup(actor)
	add_child(cross_grimoire)

	# "FLOW" pops up mid-screen when a buffered follow-up skips the recovery.
	_flow_label = _label(30)
	_flow_label.anchor_left = 0.5
	_flow_label.anchor_right = 0.5
	_flow_label.anchor_top = 0.42
	_flow_label.anchor_bottom = 0.42
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
	_prompt_label.anchor_top = 0.52
	_prompt_label.anchor_bottom = 0.52
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.modulate = Color(0.75, 0.9, 1.0)
	_prompt_label.visible = false
	add_child(_prompt_label)
	if actor != null:
		actor.action_queue.flow_cancelled.connect(_on_flow_cancelled)


func _process(_delta: float) -> void:
	if not is_instance_valid(actor) or actor.stats == null:
		return
	_top_panel.offset_top = MARGIN + (BANNER_CLEARANCE if get_global_rect().position.y < 1.0 else 0.0)
	_refresh_boss()
	_refresh_player()


## Opens the Chime-Shrine's upgrade menu over this player's view.
func open_upgrade_menu() -> void:
	if _live_menu() != null:
		return
	var menu: HubUpgradeMenu = HubUpgradeMenu.new()
	menu.setup(actor)
	_menu = menu
	add_child(menu)


## Opens the Armory & Scribe Desk menu over this player's view (`row`: where its cursor starts).
func open_scribe_desk(row: int = -1) -> void:
	if _live_menu() != null:
		return
	var menu: ScribeDeskMenu = ScribeDeskMenu.new()
	menu.setup(actor, row)
	_menu = menu
	add_child(menu)


## The boss's bars are up (it's in the fight, or near).
func boss_bar_visible() -> bool:
	return _top_panel.visible


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
	# No boss here (Bramblebridge), it's beaten, or it's still zones away: no bars to show.
	_top_panel.visible = boss != null and boss.stats != null and not boss.vanquished \
		and (boss.engaged or boss.global_position.distance_to(actor.global_position) <= BOSS_BAR_RANGE)
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
	_prompt_label.visible = is_instance_valid(actor.interactable) and _live_menu() == null
	if _prompt_label.visible:
		_prompt_label.text = actor.interactable.prompt_for(actor)
	_refresh_flashes()


func _on_flow_cancelled(_from: CombatActionResource, _to: CombatActionResource) -> void:
	_flow_flash_left = FLASH_TIME
	var bonus: float = actor.action_queue.speed_scale - 1.0
	_flow_label.text = "FLOW  +%d%% speed" % roundi(bonus * 100.0) if bonus > 0.0 else "FLOW"


func _refresh_flashes() -> void:
	var delta: float = get_process_delta_time()
	_flow_flash_left = maxf(0.0, _flow_flash_left - delta)
	_flow_label.modulate.a = _flow_flash_left / FLASH_TIME


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
