## The Wayfarer's Vellum Atlas (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §7.3):
## the whole level's parchment map over the player's view, opened out of combat
## with a tap of M / R3 (or from the Grimoire Binder's "Atlas Map" tab). Each
## place of the level wears a hand-lettered banner callout with its Cooper Sign;
## the party's gems, every Hush-Crack (a slate blot, or a Saffron-Gold cairn star
## once calmed) and the shrines, desks and portals are drawn on it.
##
## Left / right (the D-Pad, the stick or the arrow keys) choose a place; light,
## Enter or a click pins it (a click pins the very spot), and a firefly trail
## (WayfarerTrailGuideFX) leads the hero there; dodge, M or Esc closes it.
class_name CartographyAtlasPanel
extends Control

signal closed
signal pinned(target_xz: Vector2)

const BACKDROP: Color = Color(0.03, 0.03, 0.05, 0.74)
const FRAME_COLOR: Color = Color("#B08A3E")
const FRAME_DARK: Color = Color("#5E4520")
const INK: Color = Color("#4A3524")
const BANNER: Color = Color("#F7EFDA")
const SELECTED: Color = Color("#E8B64A")
const TITLE_SIZE: int = 22
const CALLOUT_SIZE: int = 14
const HINT_SIZE: int = 12
## The map fills this share of the panel (keeping its shape).
const MAP_SHARE: Vector2 = Vector2(0.86, 0.74)
const SIGN_COLORS: Array[Color] = [Color("#C8423A"), Color("#3E7FB8"), Color("#4E9A48"), Color("#8E6A3A"), Color("#7A56C2")]

var actor: ActorBase
var level: LevelBase
var hud: PlayerHUD
## Drawn inside the Grimoire Binder's tab (the Binder owns the menu input then).
var embedded: bool = false
var map: ImageTexture
## The place whose callout is chosen (an index into zones()).
var selected: int = 0

var _zones: Array[WorldMapZoneResource] = []
var _cracks: Array[Dictionary] = []
var _glyphs: Array[Dictionary] = []
var _map_rect: Rect2 = Rect2()
var _was_captured: bool = false
var _refresh_left: float = 0.0


func setup(target_actor: ActorBase, target_level: LevelBase, owner_hud: PlayerHUD, in_binder: bool = false) -> void:
	actor = target_actor
	level = target_level
	hud = owner_hud
	embedded = in_binder


func _ready() -> void:
	name = "CartographyAtlasPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if level != null:
		_zones = WorldVisualCatalog.map_zones(level.instance_id())
		map = CartographyBaker.cached_map(level)
		if map == null:
			CartographyBaker.request_level_map(level, _on_map_ready)
	_refresh()
	if not embedded and actor != null and actor.input != null:
		actor.input.menu_open = true
		actor.input.menu_input.connect(handle_menu)
	if actor != null and actor.device_id == InputComponent.KEYBOARD_DEVICE:
		# The cursor comes back so the map can be clicked.
		_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioCues.play(&"menu_move")


func _exit_tree() -> void:
	if not embedded and is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
		if actor.input.menu_input.is_connected(handle_menu):
			actor.input.menu_input.disconnect(handle_menu)
	if _was_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_map_ready(texture: ImageTexture) -> void:
	map = texture
	queue_redraw()


func close() -> void:
	if not embedded and is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


## The places the Atlas has callouts for.
func zones() -> Array[WorldMapZoneResource]:
	return _zones


## The chosen place's callout, or null.
func selected_zone() -> WorldMapZoneResource:
	return _zones[selected] if selected >= 0 and selected < _zones.size() else null


## Up / down / left / right choose a place, light pins it, dodge closes.
func handle_menu(action: StringName) -> void:
	match action:
		InputComponent.MENU_LEFT, InputComponent.MENU_UP:
			select_step(-1)
		InputComponent.MENU_RIGHT, InputComponent.MENU_DOWN:
			select_step(1)
		InputComponent.MENU_ACCEPT:
			pin_selected()
		InputComponent.MENU_BACK:
			if not embedded:
				close()
			return
	queue_redraw()


func select_step(step: int) -> void:
	if _zones.is_empty():
		return
	selected = wrapi(selected + step, 0, _zones.size())
	AudioCues.play(&"menu_move")
	queue_redraw()


## Pins the chosen place: the firefly trail leads there.
func pin_selected() -> void:
	var zone: WorldMapZoneResource = selected_zone()
	if zone != null:
		pin(zone.world_center_xz)


## Pins a world spot (x, z).
func pin(target_xz: Vector2) -> void:
	if hud != null:
		hud.set_pin(target_xz)
	AudioCues.play(&"chime")
	pinned.emit(target_xz)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and _map_rect.has_point(click.position) and map != null:
		var uv: Vector2 = (click.position - _map_rect.position) / _map_rect.size
		var world: Rect2 = CartographyBaker.world_rect(map)
		pin(world.position + uv * world.size)
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or actor == null or actor.device_id != InputComponent.KEYBOARD_DEVICE:
		return
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		pin_selected()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_ESCAPE and not embedded:
		close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	CartographyBaker.poll()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh()
	queue_redraw()


func _refresh() -> void:
	_refresh_left = 0.5
	if level == null:
		return
	_cracks = CartographyBaker.cracks(level)
	_glyphs = CartographyBaker.glyphs(get_tree())


## Where a world spot lands on the drawn map (panel pixels).
func to_panel(world_xz: Vector2) -> Vector2:
	if map == null:
		return _map_rect.get_center()
	return _map_rect.position + CartographyBaker.world_to_uv(map, world_xz) * _map_rect.size


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if not embedded:
		draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	var area: Vector2 = size * MAP_SHARE
	var world: Rect2 = CartographyBaker.world_rect(map) if map != null else Rect2(0.0, 0.0, 1.0, 1.0)
	var aspect: float = world.size.x / maxf(world.size.y, 0.001)
	var fit: Vector2 = Vector2(area.x, area.x / aspect) if area.x / aspect <= area.y else Vector2(area.y * aspect, area.y)
	_map_rect = Rect2((size - fit) * 0.5 + Vector2(0.0, 10.0), fit)
	var title: String = "The Wayfarer's Atlas"
	if level != null and not _zones.is_empty():
		title = "The Wayfarer's Atlas: %s" % _zones[0].display_name
	draw_string(font, Vector2(0.0, _map_rect.position.y - 16.0), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, TITLE_SIZE, BANNER)
	draw_rect(_map_rect.grow(6.0), FRAME_DARK)
	draw_rect(_map_rect.grow(4.0), FRAME_COLOR)
	if map != null:
		draw_texture_rect(map, _map_rect, false)
	else:
		draw_rect(_map_rect, CartographyBaker.PARCHMENT)
		draw_string(font, _map_rect.get_center(), "The map unrolls...", HORIZONTAL_ALIGNMENT_CENTER, -1.0, CALLOUT_SIZE, INK)
	# The cracks, the glyphs, the party.
	for crack: Dictionary in _cracks:
		var spot: Vector2 = to_panel(crack["at"])
		if crack["calmed"]:
			draw_colored_polygon(WayfarerMinimapWidget.star(spot, 8.0, 3.4), WayfarerMinimapWidget.SAFFRON_GOLD)
		else:
			draw_circle(spot, 7.0, WayfarerMinimapWidget.SLATE)
			draw_arc(spot, 8.0, 0.0, TAU, 18, WayfarerMinimapWidget.SLATE_VIOLET, 2.0)
	for glyph: Dictionary in _glyphs:
		WayfarerMinimapWidget.draw_glyph(self, to_panel(glyph["at"]), int(glyph["glyph"]), 6.0)
	for member: ActorBase in CombatDirector.current.alive_party():
		var spot: Vector2 = to_panel(Vector2(member.global_position.x, member.global_position.z))
		var tint: Color = WayfarerMinimapWidget.SEAT_COLORS[clampi(member.party_slot, 0, 4)]
		draw_circle(spot, 6.0 if member == actor else 5.0, tint)
		draw_arc(spot, 6.5, 0.0, TAU, 16, Color.WHITE if member == actor else FRAME_DARK, 1.5)
		draw_string(font, spot + Vector2(-12.0, -9.0), "P%d" % (member.party_slot + 1), HORIZONTAL_ALIGNMENT_CENTER, 24.0, HINT_SIZE, INK)
	# The callouts: a hand-lettered banner for each place, its Cooper Sign's colour on its tails.
	for index: int in _zones.size():
		var zone: WorldMapZoneResource = _zones[index]
		var spot: Vector2 = to_panel(zone.world_center_xz + zone.landmark_label_offset)
		var width: float = font.get_string_size(zone.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, CALLOUT_SIZE).x + 18.0
		var banner: Rect2 = Rect2(spot - Vector2(width * 0.5, 10.0), Vector2(width, 20.0))
		var tails: Color = SIGN_COLORS[clampi(zone.primary_scribe_sign, 0, SIGN_COLORS.size() - 1)]
		for side: float in [-1.0, 1.0]:
			var edge: float = banner.position.x if side < 0.0 else banner.end.x
			draw_colored_polygon(PackedVector2Array([Vector2(edge, banner.position.y + 3.0), Vector2(edge + side * 9.0, banner.position.y + 1.0),
				Vector2(edge + side * 5.0, banner.get_center().y + 1.0), Vector2(edge + side * 9.0, banner.end.y + 1.0), Vector2(edge, banner.end.y - 3.0)]), tails)
		draw_rect(banner, SELECTED if index == selected else BANNER)
		draw_rect(banner, FRAME_DARK, false, 1.5 if index == selected else 1.0)
		draw_string(font, banner.position + Vector2(0.0, 15.0), zone.display_name, HORIZONTAL_ALIGNMENT_CENTER, width, CALLOUT_SIZE, INK)
	# The pin.
	if hud != null and hud.has_pin():
		var pin_at: Vector2 = to_panel(hud.pinned_target_xz)
		draw_line(pin_at, pin_at + Vector2(0.0, -16.0), FRAME_DARK, 2.0)
		draw_circle(pin_at + Vector2(0.0, -16.0), 5.0, SELECTED)
	var zone_now: WorldMapZoneResource = selected_zone()
	var line: String = "%s · %s" % [zone_now.display_name, zone_now.cooper_sign_title] if zone_now != null else ""
	draw_string(font, Vector2(0.0, _map_rect.end.y + 22.0), line, HORIZONTAL_ALIGNMENT_CENTER, size.x, CALLOUT_SIZE, BANNER)
	draw_string(font, Vector2(0.0, _map_rect.end.y + 40.0),
		"←/→ choose a place · light or Enter pins it (or click the map) · dodge, M or Esc closes", HORIZONTAL_ALIGNMENT_CENTER, size.x,
		HINT_SIZE, Color(0.82, 0.84, 0.9))
