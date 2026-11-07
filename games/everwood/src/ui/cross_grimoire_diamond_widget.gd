## The Cross-Grimoire's four diamonds (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §6):
## one geometry for the combat HUD, the Grimoire Binder and the Reed-Light
## Scribery, so a child who learns it once reads it everywhere.
##
##                  ◇  TOP: L+R Ult
##   ◇ LEFT: L Guard               ◇ RIGHT: R Skill
##                  ◇  BOTTOM: the equipped weapon
##
## Each card diamond is a diorama. Its outer panoramic frame is the Place-Card,
## filled in the place's Sign palette with its landscape in the corners: oak
## trees for Moss-Oak Hollow, a bridge arch for Doverslap Falls, a
## waterwheel for the Bramble-Bridge Hearth-Mill, crags under a star for the
## Barrow-Crag-Crossing. Its inner portrait is the Action-Leaf: its Sign's
## colour, an icon for its manifestation (a blade for a Weapon-Coat, a shield
## for a Ward-Mantle, a lantern for a Lantern-Tether) and its finish's trim
## (Plain Vellum ivory, Gilded Leaf gold, Star-Inked Vellum violet and gold with
## stars). A gold star on the frame marks Home-Ground Harmony.
##
## set_presentation_mode(1.3, false) is the HUD's compact cross; (2.2, true) is
## the Binder's and the Scribery's, where a diamond can be picked with the mouse
## (socket_picked). Everything is drawn at the display scale, so text stays
## sharp; the Binder grows it there from the HUD's size over 220 ms
## (grow_from), drawn from the middle while its place in the layout is already 2.2x.
##
## The bottom weapon diamond (14 GDD §8) shows the weapon's tier (I to IV) and,
## for a hero, the live combo-chain pips: one per step of the form they're
## playing, a gold arrow for its finisher (o - o - >).
##
## Since the Phase 12 Kaizen pass (K3) the diamonds are the whole combat HUD, so
## following a hero they also carry what the old slot grid did, without words:
## a press (or a buffered one) flashes its diamond, a card whose pips aren't
## there yet sits dimmed, L glows shield-blue while guarding, and R rings gold
## while a teammate's seal waits nearby to be detonated.
class_name CrossGrimoireDiamondWidget
extends Control

signal socket_picked(socket: int)

## The weapon diamond's index, after the three card sockets (ScribeCardResource.DioramaSocket).
const WEAPON: int = 3
const DIAMOND_COUNT: int = 4
## Half-diagonal of a diamond and its centre's distance from the cross's middle, at scale 1.
const RADIUS: float = 34.0
const SPREAD: float = 40.0
## The base size, room for the diamonds and their key badges.
const BASE_SIZE: Vector2 = Vector2(172.0, 172.0)
## The portrait is this share of the frame.
const PORTRAIT_SHARE: float = 0.58
## The combat HUD draws it a little larger than the base since K3, when it became the whole HUD.
const HUD_SCALE: float = 1.3
const BINDER_SCALE: float = 2.2
const KEY_FONT_SIZE: int = 11
const FRAME_BORDER: float = 2.0
const EMPTY_FRAME: Color = Color(0.17, 0.16, 0.18, 0.88)
const EMPTY_EDGE: Color = Color(0.55, 0.53, 0.5, 0.8)
const PARCHMENT: Color = Color(0.96, 0.92, 0.8)
const GOLD: Color = Color(1.0, 0.82, 0.3)
const STAR_INK: Color = Color(0.58, 0.4, 0.95)
const OUTLINE: Color = Color(0.0, 0.0, 0.0, 0.85)
const UNINKED: Color = Color(1.0, 0.9, 0.62)
const SELECT_COLOR: Color = Color(1.0, 0.9, 0.45)
## The Binder grows the widget from the HUD's size to its own over this long.
const GROW_TIME: float = 0.22
const PIP_RADIUS: float = 3.4
const PIP_GAP: float = 11.0
const PIP_EMPTY: Color = Color(0.32, 0.3, 0.28, 0.95)
const TIER_NUMERALS: Array[String] = ["", "I", "II", "III", "IV"]
const PULSE_TIME: float = 0.28
const UNREADY_DIM: Color = Color(0.02, 0.02, 0.04, 0.5)
const GUARD_GLOW: Color = Color(0.7, 0.82, 1.0)
## Socket key badges, in DioramaSocket order (the HUD swaps in the hero's own keys).
const KEYS: Array[String] = ["L", "R", "L+R"]

const Socket = ScribeCardResource.DioramaSocket
const Mode = ScribeCardResource.ManifestationMode
const Variant = ScribeCardResource.CardVariant

var display_scale: float = HUD_SCALE
## What each socket's badge says: KEYS, or the followed hero's own buttons ("Q", "E", "R" on the keyboard).
var key_texts: Array[String] = KEYS.duplicate()
var interactive: bool = false
## The HUD's live marks (K3): R's gold detonate ring and L's guard glow.
var detonate_ready: bool = false
var guard_lit: bool = false
var _pulses: Array[float] = [0.0, 0.0, 0.0, 0.0]
## The socket the Binder or Scribery is working on (a bright breathing outline when interactive).
var selected_socket: int = Socket.SKILL
## What it shows: a kit and a weapon, or (with follow) a hero's own, read every frame.
var kit: EquipmentLoadoutResource
var weapon: EquipmentItemResource
var follow: ActorBase

## A highlighted card shown in one socket before it's slotted: {socket, leaf, leaf_variant, place, place_variant}.
var _preview: Dictionary = {}
var _age: float = 0.0
## The grow animation: the scale it started from and the time left (0 when it's done).
var _grow_from: float = 1.0
var _grow_left: float = 0.0
## The scale this frame is drawn at (display_scale, or on its way there).
var _ds: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_display_scale(display_scale, interactive)


## The one control for every use (Rule of Three, 08 GDD Stage 5): 1.0 and not
## interactive in the HUD, 2.2 and interactive in the Binder and Scribery.
func set_presentation_mode(scale_factor: float, is_interactive: bool) -> void:
	set_display_scale(scale_factor, is_interactive)


## Grows the drawing from `from_scale` to the display scale over `seconds` (the Binder's 220 ms opening).
func grow_from(from_scale: float, seconds: float = GROW_TIME) -> void:
	_grow_from = maxf(0.1, from_scale)
	_grow_left = maxf(0.0, seconds)
	queue_redraw()


## The scale the widget is drawn at right now (it reaches display_scale once a grow ends).
func draw_scale() -> float:
	if _grow_left <= 0.0:
		return display_scale
	var t: float = 1.0 - _grow_left / GROW_TIME
	return lerpf(_grow_from, display_scale, ease(clampf(t, 0.0, 1.0), 0.4))


## Flashes a diamond (a socket, or WEAPON) for a press or a buffered press.
func pulse(index: int) -> void:
	if index >= 0 and index < _pulses.size():
		_pulses[index] = PULSE_TIME


func is_pulsing(index: int) -> bool:
	return index >= 0 and index < _pulses.size() and _pulses[index] > 0.0


## Whether the followed hero has the pips for a socket's card (always, with no hero).
func socket_ready(socket: int) -> bool:
	if not is_instance_valid(follow) or follow.stats == null:
		return true
	return follow.stats.resonance_charge >= ScribeCardResource.SOCKET_PIP_COSTS[socket]


## The combo-chain pips the weapon diamond shows now: steps played and the form's length (0, 0 for none).
func combo_pips() -> Vector2i:
	if is_instance_valid(follow) and follow.combo != null:
		return Vector2i(follow.combo.step_index, follow.combo.max_steps)
	return Vector2i.ZERO


func set_display_scale(scale_factor: float, is_interactive: bool) -> void:
	display_scale = maxf(0.1, scale_factor)
	interactive = is_interactive
	custom_minimum_size = BASE_SIZE * display_scale
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	queue_redraw()


## Shows a kit (the Binder's draft, a shop preview) instead of a hero's own.
func show_kit(shown: EquipmentLoadoutResource, shown_weapon: EquipmentItemResource) -> void:
	kit = shown
	weapon = shown_weapon
	queue_redraw()


## Shows `socket` with this leaf and place until clear_preview (the Scribery's highlighted card).
func preview_socket(socket: int, leaf_id: StringName, leaf_variant: int, place_id: StringName, place_variant: int) -> void:
	_preview = {"socket": socket, "leaf": leaf_id, "leaf_variant": leaf_variant, "place": place_id, "place_variant": place_variant}
	queue_redraw()


func clear_preview() -> void:
	_preview = {}
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	_grow_left = maxf(0.0, _grow_left - delta)
	for index: int in _pulses.size():
		_pulses[index] = maxf(0.0, _pulses[index] - delta)
	if is_instance_valid(follow) and follow.loadout != null:
		kit = follow.loadout.kit
		weapon = follow.loadout.weapon
	queue_redraw()


# --- What each diamond shows -------------------------------------------------

## What a socket shows right now (its preview, or the kit): leaf and place ids
## and finishes, and the diorama's synergy. The HUD, Binder and Scribery read it
## the same way, and so does the smoke test.
func socket_view(socket: int) -> Dictionary:
	var leaf_id: StringName = &""
	var leaf_variant: int = Variant.STANDARD
	var place_id: StringName = &""
	var place_variant: int = Variant.STANDARD
	var shown: EquipmentLoadoutResource = _shown_kit()
	if shown != null:
		leaf_id = shown.socket_leaf_id(socket)
		leaf_variant = shown.socket_leaf_variant(socket)
		place_id = shown.place_ids[socket]
		place_variant = shown.place_variants[socket]
	if not _preview.is_empty() and _preview["socket"] == socket:
		leaf_id = _preview["leaf"]
		leaf_variant = _preview["leaf_variant"]
		place_id = _preview["place"]
		place_variant = _preview["place_variant"]
	return {
		"leaf": leaf_id,
		"leaf_variant": leaf_variant,
		"place": place_id,
		"place_variant": place_variant,
		"synergy": ArsenalCatalog.current.compute_diorama_synergy(leaf_id, place_id),
	}


## The followed hero's kit as it is right now (so a panel can read it the moment it opens), or the kit shown.
func _shown_kit() -> EquipmentLoadoutResource:
	if is_instance_valid(follow) and follow.loadout != null:
		return follow.loadout.kit
	return kit


## A diamond's centre in this control's own pixels (a socket, or WEAPON), drawn from the middle as it grows.
func diamond_center(index: int) -> Vector2:
	var middle: Vector2 = BASE_SIZE * 0.5 * display_scale
	var offsets: Array[Vector2] = [Vector2(-SPREAD, 0.0), Vector2(SPREAD, 0.0), Vector2(0.0, -SPREAD), Vector2(0.0, SPREAD)]
	return middle + offsets[index] * draw_scale()


func diamond_radius() -> float:
	return RADIUS * draw_scale()


## The diamond (socket or WEAPON) under a point in this control's pixels, or -1.
func diamond_at(point: Vector2) -> int:
	for index: int in DIAMOND_COUNT:
		var offset: Vector2 = point - diamond_center(index)
		if absf(offset.x) + absf(offset.y) <= diamond_radius():
			return index
	return -1


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if not interactive or click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var picked: int = diamond_at(click.position)
	if picked >= 0 and picked != WEAPON:
		selected_socket = picked
		socket_picked.emit(picked)
		accept_event()


# --- Drawing ------------------------------------------------------------------

func _draw() -> void:
	_ds = draw_scale()
	for socket: int in EquipmentLoadoutResource.SOCKET_COUNT:
		_draw_socket(socket)
	_draw_weapon()


func _draw_socket(socket: int) -> void:
	var view: Dictionary = socket_view(socket)
	var synergy: Dictionary = view["synergy"]
	var center: Vector2 = diamond_center(socket)
	var outer: float = diamond_radius()
	var inner: float = outer * PORTRAIT_SHARE
	var place: ScribeCardResource = ArsenalCatalog.current.card(view["place"])
	var leaf: ScribeCardResource = ArsenalCatalog.current.card(view["leaf"])
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	# The outer panoramic frame: the Place-Card.
	if place != null:
		var palette: Color = catalog.sign_seal(place.scribe_sign).color
		draw_colored_polygon(_diamond(center, outer), palette.darkened(0.35))
		draw_colored_polygon(_diamond(center + Vector2(0.0, outer * 0.12), outer * 0.84), palette.darkened(0.15))
		_draw_landscape(place, center, outer, palette.darkened(0.6))
		_outline(center, outer, _finish_color(view["place_variant"], palette.lightened(0.3)), FRAME_BORDER * _ds)
	else:
		draw_colored_polygon(_diamond(center, outer), EMPTY_FRAME)
		_dashed_outline(center, outer, EMPTY_EDGE)
	# The inner portrait: the Action-Leaf.
	var ink: Color = catalog.sign_seal(leaf.scribe_sign).color if leaf != null else UNINKED
	draw_colored_polygon(_diamond(center, inner), Color(0.07, 0.07, 0.1, 0.95))
	draw_colored_polygon(_diamond(center, inner * 0.86), ink.darkened(0.25) if leaf != null else Color(0.24, 0.22, 0.2, 0.95))
	_draw_mode_icon(leaf.manifestation_mode if leaf != null else -1, center, inner * 0.55, ink.lightened(0.45) if leaf != null else Color(UNINKED, 0.7))
	_draw_finish(view["leaf_variant"] if leaf != null else -1, center, inner)
	if synergy["is_home_ground_harmony"]:
		_star(center + Vector2(outer * 0.5, -outer * 0.5), outer * 0.2, GOLD)
	# The key badge, and the live state of the HUD's hero.
	_draw_key(socket, center, outer)
	_draw_live(socket, center, outer)
	_draw_hud_marks(socket, center, outer)
	if interactive and socket == selected_socket:
		var breath: float = 0.5 + 0.5 * sin(_age * 5.0)
		_outline(center, outer + 4.0 * _ds, Color(SELECT_COLOR, 0.65 + 0.35 * breath), (2.0 + breath) * _ds)


## The HUD's hero: a Hearth-Rite hold filling round the diamond, its blessing
## glowing, a Sign-Flow coat's ink, the Flow-Link Window's white-gold flash,
## and a gold beat when a foe's open Glimmer-Spot is this socket's to crack.
func _draw_live(socket: int, center: Vector2, outer: float) -> void:
	if not is_instance_valid(follow) or follow.sign_flow == null:
		return
	var flow: SignFlowComponent = follow.sign_flow
	var line: float = 3.0 * _ds
	if follow.input != null and follow.input.hearth_rite_socket() == socket:
		_partial_outline(center, outer + 3.0 * _ds, follow.input.hearth_rite_progress(), GOLD, line)
	if flow.has_hearth_rite_tuck and flow.active_socket == socket:
		var glow: float = 0.6 + 0.4 * sin(_age * 4.0)
		var tint: Color = ArsenalCatalog.current.compute_diorama_synergy(&"", flow.active_location_card_id)["ambient_color"] \
			if flow.active_location_card_id != &"" else GOLD
		_outline(center, outer + 2.0 * _ds, Color(tint.lightened(0.3), glow), line)
	if flow.coat_time_left > 0.0 and flow.coat_sign != ScribeSignResource.Sign.NONE \
			and socket_view(socket)["synergy"]["scribe_sign"] == flow.coat_sign:
		var share: float = flow.coat_time_left / maxf(0.1, flow.coat_synergy.get("coat_duration_sec", 1.0))
		_partial_outline(center, outer + 3.0 * _ds, share, ArsenalCatalog.current.sign_seal(flow.coat_sign).color.lightened(0.3), line)
	if flow.is_flow_window_open() and follow.stats.resonance_charge >= ScribeCardResource.SOCKET_PIP_COSTS[socket]:
		_outline(center, outer * 0.62, Color(1.0, 0.96, 0.82, 0.9), line)
	if _counters_open_glimmer(socket):
		var beat: float = 0.5 + 0.5 * sin(_age * 9.0)
		_outline(center, outer + 6.0 * _ds, Color(GOLD, beat), line)


## The HUD's own marks on a diamond (K3): dimmed until its pips are there, L's guard glow, R's detonate ring, a press's flash.
func _draw_hud_marks(index: int, center: Vector2, outer: float) -> void:
	if not is_instance_valid(follow) or interactive:
		return
	var line: float = 3.0 * _ds
	if index < WEAPON and not socket_ready(index):
		draw_colored_polygon(_diamond(center, outer), UNREADY_DIM)
	if index == Socket.GUARD and guard_lit:
		_outline(center, outer + 2.0 * _ds, GUARD_GLOW, line)
	if index == Socket.SKILL and detonate_ready:
		var beat: float = 0.55 + 0.45 * sin(_age * 8.0)
		_outline(center, outer + 5.0 * _ds, Color(GOLD.lightened(0.2), beat), line * 1.4)
		_star(center + Vector2(outer * 0.62, outer * 0.62), outer * 0.18, GOLD)
	if is_pulsing(index):
		var t: float = _pulses[index] / PULSE_TIME
		_outline(center, outer + (1.0 - t) * 9.0 * _ds, Color(1.0, 0.97, 0.86, t), line)


## Whether a foe near the HUD's hero has an open Glimmer-Spot this socket's Sign cracks.
func _counters_open_glimmer(socket: int) -> bool:
	var scribe_sign: int = socket_view(socket)["synergy"]["scribe_sign"]
	if scribe_sign == ScribeSignResource.Sign.NONE:
		return false
	for enemy: ActorBase in CombatDirector.current.enemies():
		if enemy.glimmer != null and not enemy.glimmer.encounter.is_always_open() and enemy.glimmer.is_open() \
				and enemy.glimmer.is_countered_now(scribe_sign) \
				and enemy.global_position.distance_to(follow.global_position) <= SignFlowComponent.COMBAT_RADIUS:
			return true
	return false


func _draw_weapon() -> void:
	var center: Vector2 = diamond_center(WEAPON)
	var outer: float = diamond_radius()
	var body: Color = follow.loadout.body_color if is_instance_valid(follow) else Color(0.6, 0.62, 0.7)
	draw_colored_polygon(_diamond(center, outer), Color(0.07, 0.07, 0.1, 0.9))
	draw_colored_polygon(_diamond(center, outer * 0.86), body.darkened(0.45))
	var tier_trim: Color = weapon.trim_albedo if weapon != null else PARCHMENT
	_outline(center, outer, tier_trim, FRAME_BORDER * _ds)
	_draw_weapon_icon(center, outer * 0.42, weapon.weapon_type if weapon != null else -1, body.lightened(0.5))
	if weapon != null and weapon.is_weapon():
		# The trail tier, I to IV, in the right corner.
		var font: Font = ThemeDB.fallback_font
		var font_size: int = roundi(KEY_FONT_SIZE * 0.9 * _ds)
		var at: Vector2 = center + Vector2(outer * 0.18, outer * 0.12)
		var numeral: String = TIER_NUMERALS[clampi(weapon.equipment_tier, 0, TIER_NUMERALS.size() - 1)]
		draw_string_outline(font, at, numeral, HORIZONTAL_ALIGNMENT_CENTER, outer * 0.9, font_size, roundi(3 * _ds), OUTLINE)
		draw_string(font, at, numeral, HORIZONTAL_ALIGNMENT_CENTER, outer * 0.9, font_size, tier_trim.lightened(0.3))
	_draw_combo_pips(center, outer)
	_draw_hud_marks(WEAPON, center, outer)


## The live combo-chain pips under the weapon diamond: o - o - > (steps played lit gold, the finisher an arrow).
func _draw_combo_pips(center: Vector2, outer: float) -> void:
	var pips: Vector2i = combo_pips()
	if pips.y <= 0:
		return
	var gap: float = PIP_GAP * _ds
	var radius: float = PIP_RADIUS * _ds
	var row_y: float = center.y + outer + 5.0 * _ds
	var first_x: float = center.x - gap * (pips.y - 1) * 0.5
	for step: int in pips.y:
		var at: Vector2 = Vector2(first_x + gap * step, row_y)
		var lit: bool = step < pips.x
		var color: Color = GOLD if lit else PIP_EMPTY
		if step > 0:
			draw_line(Vector2(at.x - gap + radius, row_y), Vector2(at.x - radius, row_y), Color(GOLD if lit else PIP_EMPTY, 0.85), maxf(1.0, _ds))
		if step == pips.y - 1:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-radius, -radius * 1.2), at + Vector2(radius * 1.4, 0.0),
				at + Vector2(-radius, radius * 1.2)]), color)
		else:
			draw_circle(at, radius, color)


func _draw_key(socket: int, center: Vector2, outer: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = roundi(KEY_FONT_SIZE * _ds)
	var text: String = key_texts[socket] if socket < key_texts.size() else KEYS[socket]
	# In the frame's top corner, where every diamond keeps it clear of the landscape.
	var at: Vector2 = center + Vector2(-outer, -outer * 0.5)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, outer * 2.0, font_size, roundi(4 * _ds), OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, outer * 2.0, font_size, PARCHMENT)
	# Pip gems: one for L and R, three for L+R.
	var pips: int = roundi(ScribeCardResource.SOCKET_PIP_COSTS[socket])
	for gem: int in pips:
		var gem_center: Vector2 = center + Vector2((gem - (pips - 1) * 0.5) * 8.0 * _ds, -outer - 2.0 * _ds)
		draw_colored_polygon(_diamond(gem_center, 3.6 * _ds), GOLD)


## A finish's trim round the portrait: Plain Vellum's ivory edge, Gilded Leaf's
## double gold, Star-Inked Vellum's violet edge with a gold line and three stars.
func _draw_finish(variant: int, center: Vector2, inner: float) -> void:
	var line: float = FRAME_BORDER * _ds
	match variant:
		Variant.GILDED_LEAF:
			_outline(center, inner, GOLD, line * 1.6)
			_outline(center, inner * 0.84, Color(GOLD, 0.8), line * 0.6)
		Variant.STAR_INKED_VELLUM:
			_outline(center, inner, STAR_INK, line * 1.8)
			_outline(center, inner * 0.84, GOLD, line * 0.7)
			for point: Vector2 in [Vector2(-0.55, -0.2), Vector2(0.5, -0.32), Vector2(0.1, 0.55)]:
				_star(center + point * inner, inner * 0.09, GOLD.lightened(0.3))
		Variant.STANDARD:
			_outline(center, inner, PARCHMENT, line)
		_:
			_dashed_outline(center, inner, EMPTY_EDGE)


## A Place-Card's landscape in the frame's side and bottom corners (the top one
## holds the key), in its darkest shade.
func _draw_landscape(place: ScribeCardResource, center: Vector2, outer: float, ink: Color) -> void:
	var left: Vector2 = center + Vector2(-outer * 0.74, 0.0)
	var right: Vector2 = center + Vector2(outer * 0.74, 0.0)
	var bottom: Vector2 = center + Vector2(0.0, outer * 0.74)
	var r: float = outer * 0.13
	match place.card_id:
		ArsenalCatalog.ARIUNDLE_MOSS_OAKS:
			for spot: Vector2 in [left, right, bottom]:
				_tree(spot, r, ink)
		ArsenalCatalog.DOVERSLAP_GORGE:
			draw_arc(bottom + Vector2(0.0, r * 0.9), r * 1.5, PI, TAU, 16, ink, maxf(1.0, r * 0.45))
			draw_line(bottom + Vector2(-r * 1.8, -r * 0.6), bottom + Vector2(r * 1.8, -r * 0.6), ink, maxf(1.0, r * 0.35))
			for spot: Vector2 in [left, right]:
				_waves(spot, r, ink)
		ArsenalCatalog.BRAMBLEBRIDGE_MILL:
			_wheel(right, r * 1.2, ink)
			_gable(left, r, ink)
			_waves(bottom, r, ink)
		ArsenalCatalog.BARROW_CRAG_TOR:
			_crag(left, r, ink)
			_crag(right, r, ink)
			_star(bottom, r * 0.9, ink.lightened(0.7))
		_:
			_leaf(bottom, r, ink)


func _draw_mode_icon(mode: int, center: Vector2, r: float, ink: Color) -> void:
	var line: float = maxf(1.5, r * 0.22)
	match mode:
		Mode.WEAPON_COAT:
			draw_line(center + Vector2(-r * 0.7, r * 0.7), center + Vector2(r * 0.75, -r * 0.75), ink, line)
			draw_line(center + Vector2(-r * 0.65, r * 0.1), center + Vector2(-r * 0.1, r * 0.65), ink, line)
		Mode.WARD_MANTLE:
			draw_colored_polygon(PackedVector2Array([center + Vector2(-r * 0.75, -r * 0.7), center + Vector2(r * 0.75, -r * 0.7),
				center + Vector2(r * 0.75, r * 0.05), center + Vector2(0.0, r * 0.85), center + Vector2(-r * 0.75, r * 0.05)]), ink)
		Mode.LANTERN_TETHER:
			draw_arc(center + Vector2(0.0, -r * 0.55), r * 0.3, PI, TAU, 10, ink, line * 0.7)
			draw_rect(Rect2(center + Vector2(-r * 0.45, -r * 0.45), Vector2(r * 0.9, r * 1.05)), ink)
			draw_circle(center + Vector2(0.0, r * 0.08), r * 0.25, Color(1.0, 0.95, 0.75))
		_:
			draw_arc(center, r * 0.6, 0.0, TAU, 16, ink, line * 0.6)


func _draw_weapon_icon(center: Vector2, r: float, weapon_type: int, ink: Color) -> void:
	var line: float = maxf(1.5, r * 0.22)
	match weapon_type:
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			draw_line(center + Vector2(-r * 0.6, r), center + Vector2(r * 0.4, -r), ink, line)
			draw_colored_polygon(PackedVector2Array([center + Vector2(r * 0.1, -r), center + Vector2(r * 1.1, -r * 0.6),
				center + Vector2(r * 0.9, r * 0.2), center + Vector2(-r * 0.1, -r * 0.2)]), ink)
		EquipmentItemResource.WeaponType.STAFF:
			draw_line(center + Vector2(-r * 0.5, r), center + Vector2(r * 0.4, -r * 0.6), ink, line)
			draw_circle(center + Vector2(r * 0.55, -r * 0.8), r * 0.38, GOLD)
		EquipmentItemResource.WeaponType.BOW:
			draw_arc(center + Vector2(-r * 0.3, 0.0), r, -PI * 0.42, PI * 0.42, 12, ink, line)
			draw_line(center + Vector2(-r * 0.3, 0.0) + Vector2(cos(-PI * 0.42), sin(-PI * 0.42)) * r,
				center + Vector2(-r * 0.3, 0.0) + Vector2(cos(PI * 0.42), sin(PI * 0.42)) * r, Color(1.0, 1.0, 1.0, 0.8), line * 0.4)
		EquipmentItemResource.WeaponType.LIGHT_SWORD:
			draw_line(center + Vector2(-r * 0.8, r * 0.8), center + Vector2(r * 0.9, -r * 0.9), ink, line)
			draw_line(center + Vector2(-r * 0.75, r * 0.15), center + Vector2(-r * 0.15, r * 0.75), ink, line)
		_:
			draw_circle(center, r * 0.4, ink)


# --- Shapes -------------------------------------------------------------------

static func _diamond(center: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0.0, -r), center + Vector2(r, 0.0), center + Vector2(0.0, r), center + Vector2(-r, 0.0)])


func _outline(center: Vector2, r: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = _diamond(center, r)
	points.append(points[0])
	draw_polyline(points, color, width, true)


## The diamond's edge drawn from the top corner, clockwise, `share` of the way round.
func _partial_outline(center: Vector2, r: float, share: float, color: Color, width: float) -> void:
	if share <= 0.0:
		return
	var corners: PackedVector2Array = _diamond(center, r)
	corners.append(corners[0])
	var points: PackedVector2Array = PackedVector2Array([corners[0]])
	var left: float = clampf(share, 0.0, 1.0) * 4.0
	for edge: int in 4:
		if left <= 0.0:
			break
		points.append(corners[edge].lerp(corners[edge + 1], minf(1.0, left)))
		left -= 1.0
	draw_polyline(points, color, width, true)


func _dashed_outline(center: Vector2, r: float, color: Color) -> void:
	var corners: PackedVector2Array = _diamond(center, r)
	corners.append(corners[0])
	for edge: int in 4:
		draw_dashed_line(corners[edge], corners[edge + 1], color, maxf(1.0, _ds * 1.5), 4.0 * _ds)


func _star(center: Vector2, r: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for point: int in 10:
		var radius: float = r * (1.0 if point % 2 == 0 else 0.45)
		var angle: float = -PI * 0.5 + TAU * point / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)


func _tree(at: Vector2, r: float, color: Color) -> void:
	draw_rect(Rect2(at + Vector2(-r * 0.18, -r * 0.1), Vector2(r * 0.36, r * 0.9)), color)
	draw_circle(at + Vector2(0.0, -r * 0.4), r * 0.75, color)


func _leaf(at: Vector2, r: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -r), at + Vector2(r * 0.6, 0.0), at + Vector2(0.0, r), at + Vector2(-r * 0.6, 0.0)]), color)


func _waves(at: Vector2, r: float, color: Color) -> void:
	for row: int in 2:
		var y: float = (row - 0.5) * r * 0.7
		draw_arc(at + Vector2(-r * 0.5, y), r * 0.5, PI, TAU, 8, color, maxf(1.0, r * 0.25))
		draw_arc(at + Vector2(r * 0.5, y), r * 0.5, 0.0, PI, 8, color, maxf(1.0, r * 0.25))


func _wheel(at: Vector2, r: float, color: Color) -> void:
	draw_arc(at, r, 0.0, TAU, 16, color, maxf(1.0, r * 0.22))
	for spoke: int in 4:
		var angle: float = TAU * spoke / 8.0 + _age * 0.8
		draw_line(at - Vector2(cos(angle), sin(angle)) * r, at + Vector2(cos(angle), sin(angle)) * r, color, maxf(1.0, r * 0.16))


func _gable(at: Vector2, r: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-r, r * 0.8), at + Vector2(-r, -r * 0.1), at + Vector2(-r * 0.5, -r * 0.1),
		at + Vector2(-r * 0.5, -r * 0.55), at + Vector2(0.0, -r * 0.55), at + Vector2(0.0, -r), at + Vector2(r * 0.5, -r * 0.55),
		at + Vector2(r, -r * 0.1), at + Vector2(r, r * 0.8)]), color)


func _crag(at: Vector2, r: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 1.1, r * 0.8), at + Vector2(-r * 0.4, -r * 0.3), at + Vector2(-r * 0.1, r * 0.1),
		at + Vector2(r * 0.35, -r * 0.9), at + Vector2(r * 1.1, r * 0.8)]), color)


func _finish_color(variant: int, fallback: Color) -> Color:
	match variant:
		Variant.GILDED_LEAF:
			return GOLD
		Variant.STAR_INKED_VELLUM:
			return STAR_INK.lerp(GOLD, 0.35)
	return fallback
