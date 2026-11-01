## The Cross-Grimoire HUD (07_EXPEDITION_HUD_AND_ART_GDD.md §2), bottom-centre
## in each player's split-screen cell, laid out like the hands that press it:
##
##            [ pips ]   Calling title   [ Chimes ]
##   [ health ]        [ ↑ Forward card ]        [ stamina ]
##   [ Guard  ]        [ weapon + off-hand ]     [ Signature card ]
##   [ Roll   ]        [ ↓ Back card ]           [ ★ Ultimate card ]
##
## plus, for Lantern-Bearers, a little D-Pad compass of Soul Tethers beside the
## Guard wing. Cards are tinted by their Sign, dip and dim until you have the
## pips for them, pop gold when you do, and pulse when you press or buffer
## them (CrossSlot). Everything is drawn in code from the actor's loadout,
## so a Scribe Desk swap or a new Calling shows at once.
class_name CrossGrimoireHUD
extends Control

const SLOT_SIZE: Vector2 = Vector2(150.0, 70.0)
const GAP: float = 8.0
const MARGIN: float = 12.0
## The cross is drawn at BASE_SCALE in a cell this big, and grows or shrinks with the cell.
const REFERENCE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const BASE_SCALE: float = 0.95
const MIN_SCALE: float = 0.55
const MAX_SCALE: float = 1.2
const HEALTH_COLOR: Color = Color(0.9, 0.24, 0.26)
const STAMINA_COLOR: Color = Color(0.98, 0.8, 0.28)
const BAR_BACK: Color = Color(0.06, 0.06, 0.08, 0.8)
const BAR_HEIGHT: float = 16.0
const GOLD: Color = Color(1.0, 0.82, 0.3)
const COIN_COLOR: Color = Color(0.93, 0.72, 0.32)
const TETHER_COLOR: Color = Color(0.5, 1.0, 0.62)
const TITLE_FONT_SIZE: int = 22
const FONT_SIZE: int = 15
const SMALL_FONT_SIZE: int = 12
const OUTLINE: Color = Color(0.0, 0.0, 0.0, 0.85)
## A resonance jump at least this big (a reward, not a hit) makes the pip gems flash.
const REWARD_FLASH_PIPS: float = 0.4
const FLASH_TIME: float = 0.6
const COMPASS_RADIUS: float = 30.0
const COMPASS_DOT: float = 15.0

var actor: ActorBase
## Slots by the command that fires them (LIGHT also names the weapon hub).
var slots: Dictionary[int, CrossSlot] = {}
var guard_slot: CrossSlot
var roll_slot: CrossSlot
## Shown above the cross when something's wrong (downed, staggered).
var status_text: String = ""

var _cross: Control
var _seen_loadout: ClassLoadoutResource
var _was_guarding: bool = false
var _last_resonance: float = 0.0
var _pips_flash_left: float = 0.0


func setup(target_actor: ActorBase) -> void:
	actor = target_actor


func _ready() -> void:
	name = "CrossGrimoire"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cross = Control.new()
	_cross.name = "Cross"
	_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cross.draw.connect(_draw_status)
	add_child(_cross)
	var layout: Array = [
		[CombatActionResource.Command.FORWARD_HEAVY, CrossSlot.Look.CARD, Vector2i(0, -1)],
		[CombatActionResource.Command.BACK_HEAVY, CrossSlot.Look.CARD, Vector2i(0, 1)],
		[CombatActionResource.Command.TRIGGER_R_SKILL, CrossSlot.Look.CARD, Vector2i(1, 0)],
		[CombatActionResource.Command.TRIGGER_BOTH_ULT, CrossSlot.Look.ULTIMATE, Vector2i(1, 1)],
		[CombatActionResource.Command.LIGHT, CrossSlot.Look.WEAPON, Vector2i(0, 0)],
	]
	for entry: Array in layout:
		var slot: CrossSlot = _make_slot(entry[1], entry[2])
		slots[entry[0]] = slot
	guard_slot = _make_slot(CrossSlot.Look.GUARD, Vector2i(-1, 0))
	guard_slot.icon = CrossSlot.Icon.SHIELD
	guard_slot.sign_color = Color(0.7, 0.78, 0.95)
	roll_slot = _make_slot(CrossSlot.Look.ROLL, Vector2i(-1, 1))
	roll_slot.icon = CrossSlot.Icon.ROLL
	roll_slot.sign_color = Color(0.75, 0.9, 1.0)
	roll_slot.title = "Roll"
	if actor != null:
		actor.action_queue.action_started.connect(_on_action_started)
		actor.action_queue.buffer_changed.connect(_on_buffer_changed)
		_last_resonance = actor.stats.resonance_charge
		_refresh_loadout()


func _make_slot(look: CrossSlot.Look, cell: Vector2i) -> CrossSlot:
	var slot: CrossSlot = CrossSlot.new()
	slot.name = "Slot%s" % CrossSlot.Look.keys()[look].capitalize()
	slot.look = look
	slot.place(_cell_rect(cell).position, SLOT_SIZE)
	_cross.add_child(slot)
	return slot


## The slot rectangle of grid cell (column, row), the centre cell at the origin.
static func _cell_rect(cell: Vector2i) -> Rect2:
	var top_left: Vector2 = Vector2(cell.x * (SLOT_SIZE.x + GAP), cell.y * (SLOT_SIZE.y + GAP)) - SLOT_SIZE * 0.5
	return Rect2(top_left, SLOT_SIZE)


## The scale the cross is drawn at in a cell of `cell_size`.
static func scale_for(cell_size: Vector2) -> float:
	var fit: float = minf(cell_size.x / REFERENCE_SIZE.x, cell_size.y / REFERENCE_SIZE.y)
	return clampf(BASE_SCALE * fit, MIN_SCALE, MAX_SCALE)


## The slot a command lights up (light and heavy both live on the weapon hub).
func slot_for_command(command: int) -> CrossSlot:
	match command:
		CombatActionResource.Command.HEAVY:
			return slots.get(CombatActionResource.Command.LIGHT)
		CombatActionResource.Command.DODGE:
			return roll_slot
		CombatActionResource.Command.TRIGGER_L_SKILL:
			return guard_slot
	return slots.get(command)


func _process(delta: float) -> void:
	if not is_instance_valid(actor) or actor.stats == null:
		return
	var cross_scale: float = scale_for(size)
	_cross.scale = Vector2.ONE * cross_scale
	var bottom_extent: float = SLOT_SIZE.y * 1.5 + GAP
	_cross.position = Vector2(size.x * 0.5, size.y - MARGIN - bottom_extent * cross_scale)
	if actor.loadout != _seen_loadout:
		_refresh_loadout()
	var pips: int = actor.stats.resonance_pips()
	for command: int in slots:
		var slot: CrossSlot = slots[command]
		slot.set_ready(pips >= slot.pip_cost)
	var guarding: bool = actor.stats.guarding
	if guarding and not _was_guarding:
		guard_slot.pulse()
	_was_guarding = guarding
	guard_slot.lit = guarding
	roll_slot.set_ready(actor.stats.stamina >= actor.loadout.dodge.stamina_cost)
	var charge: float = actor.stats.resonance_charge
	if charge - _last_resonance >= REWARD_FLASH_PIPS:
		_pips_flash_left = FLASH_TIME
	_last_resonance = charge
	_pips_flash_left = maxf(0.0, _pips_flash_left - delta)
	status_text = _status()
	_cross.queue_redraw()


## Reads every slot's name, keys, Sign colour, pip cost and Under-Card from the loadout.
func _refresh_loadout() -> void:
	_seen_loadout = actor.loadout
	var loadout: ClassLoadoutResource = actor.loadout
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var input: InputComponent = actor.input
	for command: int in [CombatActionResource.Command.FORWARD_HEAVY, CombatActionResource.Command.BACK_HEAVY,
			CombatActionResource.Command.TRIGGER_R_SKILL, CombatActionResource.Command.TRIGGER_BOTH_ULT]:
		var slot: CrossSlot = slots[command]
		var action: CombatActionResource = loadout.opener_for(command as CombatActionResource.Command)
		slot.key_text = _keys_for(command, input)
		slot.title = action.display_name if action != null else "-"
		slot.pip_cost = action.resonance_cost if action != null else 0
		var seal: ScribeSignResource = catalog.sign_seal(action.scribe_sign if action != null else ScribeSignResource.Sign.NONE)
		slot.sign_color = seal.color
		slot.tag_text = seal.display_name.to_upper() if action != null and action.scribe_sign != ScribeSignResource.Sign.NONE else ""
		slot.icon = CrossSlot.Icon.STAR if command == CombatActionResource.Command.TRIGGER_BOTH_ULT else CrossSlot.Icon.NONE
		slot.under_color = Color(0.0, 0.0, 0.0, 0.0)
		if action != null and action.grimoire_slot >= 0 and loadout.kit != null:
			var under: ScribeCardResource = catalog.card(loadout.kit.under_ids[action.grimoire_slot])
			if under != null:
				slot.under_color = catalog.sign_seal(under.scribe_sign).color
	var hub: CrossSlot = slots[CombatActionResource.Command.LIGHT]
	hub.key_text = "%s Light · %s Heavy" % [_label(input, InputComponent.ACTION_LIGHT), _label(input, InputComponent.ACTION_HEAVY)]
	hub.title = loadout.weapon.display_name if loadout.weapon != null else "Hands"
	hub.subtitle = _off_hand_name(loadout)
	hub.sign_color = loadout.body_color.lightened(0.25)
	hub.icon = _weapon_icon(loadout.weapon)
	guard_slot.key_text = "%s hold" % _label(input, InputComponent.ACTION_TRIGGER_L)
	guard_slot.title = "Guard"
	guard_slot.subtitle = "Perfect %.2f s" % loadout.stats.perfect_guard_window
	roll_slot.key_text = _label(input, InputComponent.ACTION_DODGE)
	roll_slot.pip_cost = 0


## "W+K" for the keyboard, "↑△" / "↑Y" for pads, read from the Input Map.
func _keys_for(command: int, input: InputComponent) -> String:
	var heavy: String = _label(input, InputComponent.ACTION_HEAVY)
	var keyboard: bool = input == null or input.is_keyboard()
	match command:
		CombatActionResource.Command.FORWARD_HEAVY:
			return ("%s+%s" % [_label(input, InputComponent.ACTION_MOVE_FORWARD), heavy]) if keyboard else "↑%s" % heavy
		CombatActionResource.Command.BACK_HEAVY:
			return ("%s+%s" % [_label(input, InputComponent.ACTION_MOVE_BACK), heavy]) if keyboard else "↓%s" % heavy
		CombatActionResource.Command.TRIGGER_R_SKILL:
			return _label(input, InputComponent.ACTION_TRIGGER_R)
		CombatActionResource.Command.TRIGGER_BOTH_ULT:
			var both: String = "%s+%s" % [_label(input, InputComponent.ACTION_TRIGGER_L), _label(input, InputComponent.ACTION_TRIGGER_R)]
			return ("%s or %s" % [_label(input, InputComponent.ACTION_ULT), both]) if keyboard else both
	return ""


func _label(input: InputComponent, action: StringName) -> String:
	return input.label(action) if input != null else InputComponent.binding_label(action, InputComponent.KEYBOARD_DEVICE)


static func _weapon_icon(weapon: EquipmentItemResource) -> CrossSlot.Icon:
	if weapon == null:
		return CrossSlot.Icon.NONE
	match weapon.weapon_type:
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			return CrossSlot.Icon.AXE
		EquipmentItemResource.WeaponType.STAFF:
			return CrossSlot.Icon.STAFF
		EquipmentItemResource.WeaponType.BOW:
			return CrossSlot.Icon.BOW
	return CrossSlot.Icon.SWORD


## What the off hand carries, by Fellowship (07 GDD §4.1).
static func _off_hand_name(loadout: ClassLoadoutResource) -> String:
	match loadout.role:
		ClassLoadoutResource.Role.TANK:
			return "+ Greatshield"
		ClassLoadoutResource.Role.HEALER:
			return "+ Tether-Lantern"
	return "+ Quiver" if loadout.is_ranged() else "+ Scribe Satchel"


func _status() -> String:
	if actor.stats.is_downed:
		return "Downed: back up in %ds" % ceili(actor.downed_time_left)
	if actor.state_machine.is_in(&"stagger"):
		return "Staggered!"
	return ""


func _on_action_started(action: CombatActionResource, _flowed: bool) -> void:
	var slot: CrossSlot = slot_for_command(action.command)
	if slot != null:
		slot.pulse()


func _on_buffer_changed(commands: Array[int]) -> void:
	if commands.is_empty():
		return
	var slot: CrossSlot = slot_for_command(commands[commands.size() - 1])
	if slot != null:
		slot.pulse()


# --- The status arc ----------------------------------------------------------

## Health and stamina over the top corners, the Calling's name between the pip
## gems and the Chimes, and the Soul Tether compass for Lantern-Bearers.
func _draw_status() -> void:
	if not is_instance_valid(actor) or actor.stats == null:
		return
	var font: Font = ThemeDB.fallback_font
	var stats: StatsComponent = actor.stats
	var health_cell: Rect2 = _cell_rect(Vector2i(-1, -1))
	var stamina_cell: Rect2 = _cell_rect(Vector2i(1, -1))
	_bar(health_cell, stats.health, stats.stats.max_health, HEALTH_COLOR, true, font)
	_bar(stamina_cell, stats.stamina, stats.stats.max_stamina, STAMINA_COLOR, false, font)
	var top: float = _cell_rect(Vector2i(0, -1)).position.y - 10.0
	var title_width: float = SLOT_SIZE.x * 3.0 + GAP * 2.0
	_text(font, Vector2(-title_width * 0.5, top), actor.loadout.display_name, TITLE_FONT_SIZE, actor.loadout.body_color.lightened(0.4), title_width,
		HORIZONTAL_ALIGNMENT_CENTER)
	# Three Resonance Pip gems, filling as they charge.
	var flash: float = _pips_flash_left / FLASH_TIME
	var full: int = stats.resonance_pips()
	var gem_y: float = top - 8.0
	for gem: int in stats.stats.max_resonance_pips:
		var center: Vector2 = Vector2(health_cell.position.x + 16.0 + gem * 26.0, gem_y)
		var radius: float = 10.0 * (1.0 + flash * 0.25)
		var fill: float = clampf(stats.resonance_charge - gem, 0.0, 1.0)
		_gem(center, radius, fill, gem < full)
	# The party's Chimes: a brass octagon and the count.
	var coin_center: Vector2 = Vector2(stamina_cell.end.x - 70.0, gem_y)
	var octagon: PackedVector2Array = PackedVector2Array()
	for corner: int in 8:
		var angle: float = PI / 8.0 + TAU * corner / 8.0
		octagon.append(coin_center + Vector2(cos(angle), sin(angle)) * 10.0)
	_cross.draw_colored_polygon(octagon, COIN_COLOR)
	_cross.draw_rect(Rect2(coin_center - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), Color(0.15, 0.1, 0.05))
	_text(font, coin_center + Vector2(15.0, 6.0), str(PartyProgress.current.chimes), FONT_SIZE, COIN_COLOR.lightened(0.3), 60.0, HORIZONTAL_ALIGNMENT_LEFT)
	if status_text != "":
		_text(font, Vector2(-title_width * 0.5, top - 34.0), status_text, TITLE_FONT_SIZE, Color(1.0, 0.55, 0.45), title_width, HORIZONTAL_ALIGNMENT_CENTER)
	if actor.tether != null:
		_draw_compass(font)


func _bar(cell: Rect2, value: float, maximum: float, color: Color, heart: bool, font: Font) -> void:
	var bar: Rect2 = Rect2(Vector2(cell.position.x + 26.0, cell.end.y - BAR_HEIGHT - 6.0), Vector2(cell.size.x - 30.0, BAR_HEIGHT))
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = BAR_BACK
	back.set_corner_radius_all(5)
	_cross.draw_style_box(back, bar.grow(2.0))
	var ratio: float = clampf(value / maxf(1.0, maximum), 0.0, 1.0)
	if ratio > 0.0:
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(4)
		_cross.draw_style_box(fill, Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)))
	var icon_center: Vector2 = Vector2(cell.position.x + 12.0, bar.get_center().y)
	if heart:
		_cross.draw_circle(icon_center + Vector2(-4.0, -3.0), 5.5, color)
		_cross.draw_circle(icon_center + Vector2(4.0, -3.0), 5.5, color)
		_cross.draw_colored_polygon(PackedVector2Array([icon_center + Vector2(-9.5, -1.0), icon_center + Vector2(9.5, -1.0), icon_center + Vector2(0.0, 10.0)]), color)
	else:
		_cross.draw_colored_polygon(PackedVector2Array([icon_center + Vector2(2.0, -11.0), icon_center + Vector2(-6.0, 1.0), icon_center + Vector2(0.0, 1.0),
			icon_center + Vector2(-2.0, 11.0), icon_center + Vector2(6.0, -2.0), icon_center + Vector2(0.0, -2.0)]), color)
	_text(font, Vector2(bar.position.x, bar.position.y - 4.0), "%d/%d" % [roundi(value), roundi(maximum)], SMALL_FONT_SIZE, Color.WHITE, bar.size.x,
		HORIZONTAL_ALIGNMENT_LEFT)


func _gem(center: Vector2, radius: float, fill: float, full: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius * 0.75, 0.0),
		center + Vector2(0.0, radius), center + Vector2(-radius * 0.75, 0.0)])
	_cross.draw_colored_polygon(points, Color(0.1, 0.1, 0.14, 0.85))
	if fill > 0.0:
		# A charging gem fills from the bottom up.
		var lit: PackedVector2Array = points
		if fill < 1.0:
			var level: float = center.y + radius - fill * radius * 2.0
			var band: PackedVector2Array = PackedVector2Array([Vector2(center.x - radius, level), Vector2(center.x + radius, level),
				Vector2(center.x + radius, center.y + radius), Vector2(center.x - radius, center.y + radius)])
			var clipped: Array[PackedVector2Array] = Geometry2D.intersect_polygons(points, band)
			lit = clipped[0] if not clipped.is_empty() else PackedVector2Array()
		if lit.size() >= 3:
			_cross.draw_colored_polygon(lit, GOLD if full else GOLD.darkened(0.25))
	var outline: PackedVector2Array = points.duplicate()
	outline.append(points[0])
	_cross.draw_polyline(outline, GOLD.lightened(0.3) if full else Color(0.6, 0.6, 0.65), 1.5)


## The Lantern-Bearer's D-Pad: who each direction tethers, coloured by their health.
func _draw_compass(font: Font) -> void:
	var guard_cell: Rect2 = _cell_rect(Vector2i(-1, 0))
	var center: Vector2 = Vector2(guard_cell.position.x - COMPASS_RADIUS - COMPASS_DOT - 10.0, 0.0)
	var allies: Array[ActorBase] = actor.tether.allies()
	var directions: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	_cross.draw_circle(center, 5.0, GOLD)
	for slot: int in directions.size():
		var dot: Vector2 = center + directions[slot] * COMPASS_RADIUS
		if slot >= allies.size():
			_cross.draw_arc(dot, COMPASS_DOT, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.25), 2.0)
			continue
		var ally: ActorBase = allies[slot]
		var health: float = ally.stats.health_ratio()
		var tethered: bool = ally.player_id == actor.tether.tethered_id
		_cross.draw_circle(dot, COMPASS_DOT, Color(0.08, 0.08, 0.1, 0.85))
		_cross.draw_arc(dot, COMPASS_DOT - 2.0, -PI * 0.5, -PI * 0.5 + TAU * health, 24, HEALTH_COLOR.lerp(TETHER_COLOR, health), 4.0)
		if tethered:
			_cross.draw_arc(dot, COMPASS_DOT + 3.0, 0.0, TAU, 24, TETHER_COLOR, 3.0)
		_text(font, dot + Vector2(-COMPASS_DOT, 4.0), ally.display_name().get_slice(" ", 0), SMALL_FONT_SIZE, Color.WHITE, COMPASS_DOT * 2.0,
			HORIZONTAL_ALIGNMENT_CENTER)


func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, width: float, align: HorizontalAlignment) -> void:
	_cross.draw_string_outline(font, at, text, align, width, font_size, 5, OUTLINE)
	_cross.draw_string(font, at, text, align, width, font_size, color)
