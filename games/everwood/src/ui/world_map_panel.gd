## The map (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.4–2.5; it grew from the
## Wayfarer's Atlas of 18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §7.3):
## the parchment map over the player's view, opened out of combat with a tap of
## M / R3, or from the Grimoire Binder's Atlas Map tab.
##   - a header naming where you are ("Oakshire Holm · Lv 1–6 · Hearthstead
##     Market"), and the Zone Map / World Map tabs: the island you're on, or
##     all five isles of the Caldera (on a single-map level, a close crop of
##     the place you're in, or the whole map)
##   - named towns, quest-givers, dungeons and raid doors, crossings, shrines,
##     ink desks, portals and beacons, each with its own mark, and a legend
##   - your own arrow, turning as you turn; the party's gems; the Hush-Cracks
##   - a way-marker: choose a mark with the D-Pad, the stick or the arrow keys
##     and press light or Enter, or click any mark (or any spot) on the map.
##     A firefly trail leads you there; a mark on another island leads you to
##     the crossing that heads there first. Mark it again to take it away.
## Heavy (or Q / E, L1 / R1 outside the Binder) turns between the Zone and
## World Maps; Esc, Options, dodge or M closes it.
class_name WorldMapPanel
extends Control

signal closed
signal pinned(target_xz: Vector2)
signal marked(label: String)

const MapScope = CartographyBaker.MapScope
const NodeKind = CartographyBaker.NodeKind

const BACKDROP: Color = Color(0.03, 0.03, 0.05, 0.76)
const FRAME_COLOR: Color = Color("#B08A3E")
const FRAME_DARK: Color = Color("#5E4520")
const INK: Color = Color("#4A3524")
const PARCHMENT_TEXT: Color = Color("#F7EFDA")
const SELECTED: Color = Color("#E8B64A")
const MARKER_COLOR: Color = Color("#E0503A")
const ARROW_COLOR: Color = Color("#FFF4D6")
const TITLE_SIZE: int = 22
const LABEL_SIZE: int = 13
const TOWN_SIZE: int = 15
const ISLE_SIZE: int = 20
const HINT_SIZE: int = 12
const LEGEND_WIDTH: float = 200.0
const HEADER_HEIGHT: float = 64.0
const FOOTER_HEIGHT: float = 46.0
## A click this close to a mark picks the mark rather than the spot.
const NODE_HIT_PX: float = 16.0
## Each kind's colour (CartographyBaker.NodeKind order).
const KIND_COLORS: Array[Color] = [Color("#C48A2E"), Color("#F2C230"), Color("#9A2E2A"), Color("#3E8C86"), Color("#8A5A2E"),
	Color("#7A56C2"), Color("#2F7FA0"), Color("#E07A2E"), Color("#6E6252"), Color("#4A3524")]
## Marks whose names show without being chosen (the rest name themselves when chosen).
const ALWAYS_NAMED: Array[int] = [NodeKind.TOWN, NodeKind.DUNGEON, NodeKind.ISLE, NodeKind.CROSSING]

var actor: ActorBase
var level: LevelBase
var hud: PlayerHUD
## Drawn inside the Grimoire Binder's tab (the Binder owns the menu input then).
var embedded: bool = false
var scope: CartographyBaker.MapScope = MapScope.ZONE
var map: ImageTexture
var nodes: Array[Dictionary] = []
## The chosen mark (an index into nodes), or -1.
var selected: int = -1

var _cracks: Array[Dictionary] = []
var _map_rect: Rect2 = Rect2()
var _view: Rect2 = Rect2()
var _scope_tabs: Array[Rect2] = []
var _was_captured: bool = false
var _refresh_left: float = 0.0


func setup(target_actor: ActorBase, target_level: LevelBase, owner_hud: PlayerHUD, in_binder: bool = false) -> void:
	actor = target_actor
	level = target_level
	hud = owner_hud
	embedded = in_binder


func _ready() -> void:
	name = "WorldMapPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_scope()
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


func close() -> void:
	if not embedded and is_instance_valid(actor) and actor.input != null:
		actor.input.menu_open = false
	closed.emit()
	queue_free()


# --- Scope and marks --------------------------------------------------------------------

## Shows the Zone Map or the World Map.
func set_scope(to: CartographyBaker.MapScope) -> void:
	scope = to
	AudioCues.play(&"menu_move")
	_load_scope()


func toggle_scope() -> void:
	set_scope(MapScope.WORLD if scope == MapScope.ZONE else MapScope.ZONE)


func _load_scope() -> void:
	if level == null:
		return
	map = CartographyBaker.cached_map(level, scope)
	if map == null:
		CartographyBaker.request_level_map(level, _on_map_ready.bind(scope), scope)
	nodes = CartographyBaker.map_nodes(level, scope)
	_cracks.clear()
	if scope == MapScope.ZONE or not CartographyBaker.is_archipelago(level):
		_cracks = CartographyBaker.cracks(level)
	selected = _nearest_node(hero_map_position())
	queue_redraw()


func _on_map_ready(texture: ImageTexture, for_scope: CartographyBaker.MapScope) -> void:
	if for_scope == scope:
		map = texture
		queue_redraw()


## The hero's spot in this scope's map frame.
func hero_map_position() -> Vector2:
	if actor == null or level == null:
		return Vector2.ZERO
	return CartographyBaker.to_map_frame(level, scope, Vector2(actor.global_position.x, actor.global_position.z))


## The chosen mark, or {}.
func selected_node() -> Dictionary:
	return nodes[selected] if selected >= 0 and selected < nodes.size() else {}


## The marks of one kind (tests and the legend).
func nodes_of(kind: CartographyBaker.NodeKind) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for node: Dictionary in nodes:
		if int(node["kind"]) == kind:
			found.append(node)
	return found


func _nearest_node(at: Vector2) -> int:
	var best: int = -1
	var best_distance: float = INF
	for index: int in nodes.size():
		var distance: float = (nodes[index]["at"] as Vector2).distance_to(at)
		if distance < best_distance:
			best = index
			best_distance = distance
	return best


## Up / down / left / right move to the nearest mark that way; light marks it;
## heavy (and Q / E outside the Binder) turns between the maps; dodge closes.
func handle_menu(action: StringName) -> void:
	match action:
		InputComponent.MENU_LEFT:
			move_selection(Vector2.LEFT)
		InputComponent.MENU_RIGHT:
			move_selection(Vector2.RIGHT)
		InputComponent.MENU_UP:
			move_selection(Vector2.UP)
		InputComponent.MENU_DOWN:
			move_selection(Vector2.DOWN)
		InputComponent.MENU_ACCEPT:
			mark_selected()
		InputComponent.MENU_ALT:
			toggle_scope()
		InputComponent.MENU_TAB_PREV, InputComponent.MENU_TAB_NEXT:
			if not embedded:
				toggle_scope()
		InputComponent.MENU_BACK:
			if not embedded:
				close()
			return
	queue_redraw()


## Moves the choice to the nearest mark in a direction on the map (north up), or round the list.
func move_selection(direction: Vector2) -> void:
	if nodes.is_empty():
		return
	if selected < 0:
		selected = 0
		return
	var from: Vector2 = nodes[selected]["at"]
	var best: int = -1
	var best_score: float = INF
	for index: int in nodes.size():
		if index == selected:
			continue
		var offset: Vector2 = (nodes[index]["at"] as Vector2) - from
		var reach: float = offset.length()
		if reach < 0.01:
			continue
		var along: float = offset.dot(direction) / reach
		if along < 0.5:
			continue
		var score: float = reach * (2.0 - along)
		if score < best_score:
			best_score = score
			best = index
	selected = best if best >= 0 else wrapi(selected + (1 if direction.x + direction.y > 0.0 else -1), 0, nodes.size())
	AudioCues.play(&"menu_move")
	queue_redraw()


## Sets the way-marker on the chosen mark (or takes it away if it's already there).
func mark_selected() -> void:
	var node: Dictionary = selected_node()
	if not node.is_empty():
		mark_node(node)


func mark_node(node: Dictionary) -> void:
	if hud == null:
		return
	var label: String = String(node["label"])
	if hud.has_waymarker() and String(hud.waymarker.get("label", "")) == label:
		hud.clear_waymarker()
		AudioCues.play(&"menu_move")
		queue_redraw()
		return
	var isle: StringName = node.get("isle", &"")
	var local: Vector2 = node["local"]
	if int(node["kind"]) == NodeKind.ISLE:
		# An island marks its town (its steading), or its middle.
		var town: Dictionary = _town_of(isle)
		local = town.get("local", Vector2.ZERO)
		label = "%s (%s)" % [String(node["label"]), String(town.get("label", "its middle"))]
	hud.set_waymarker(label, isle, local)
	AudioCues.play(&"chime")
	pinned.emit(hud.pinned_target_xz)
	marked.emit(label)
	queue_redraw()


func _town_of(isle: StringName) -> Dictionary:
	for node: Dictionary in nodes:
		if int(node["kind"]) == NodeKind.TOWN and node.get("isle", &"") == isle:
			return node
	return {}


## Sets the way-marker on a spot of this map (a click on open ground).
func mark_spot(map_at: Vector2) -> void:
	if hud == null or level == null:
		return
	var isle: StringName = CartographyBaker.active_isle(level)
	var local: Vector2 = CartographyBaker.from_map_frame(level, scope, map_at)
	if scope == MapScope.WORLD and CartographyBaker.is_archipelago(level):
		for each: IslandGridResource in CalderaAtlas.isles():
			var offset: Vector2 = map_at - each.sound_position
			if absf(offset.x) <= each.grid_size_m() * 0.5 and absf(offset.y) <= each.grid_size_m() * 0.5:
				isle = each.isle_id
				local = offset
	hud.set_waymarker("Marked spot", isle, local)
	AudioCues.play(&"chime")
	pinned.emit(hud.pinned_target_xz)
	marked.emit("Marked spot")
	queue_redraw()


## Kept from the Atlas: pins a spot in the level's own frame (the tests).
func pin(target_xz: Vector2) -> void:
	if hud != null:
		hud.set_waymarker("Marked spot", CartographyBaker.active_isle(level) if level != null else &"", target_xz)
	pinned.emit(target_xz)
	queue_redraw()


## A click on a mark marks it; on open map, marks the spot; on a scope tab, turns to it.
func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	for index: int in _scope_tabs.size():
		if _scope_tabs[index].has_point(click.position):
			set_scope(index as CartographyBaker.MapScope)
			accept_event()
			return
	if not _map_rect.has_point(click.position) or _view.size.x <= 0.0:
		return
	var hit: int = node_at(click.position)
	if hit >= 0:
		selected = hit
		mark_node(nodes[hit])
	else:
		mark_spot(from_panel(click.position))
	accept_event()


## The mark under a point of the panel (within NODE_HIT_PX), or -1.
func node_at(point: Vector2) -> int:
	var best: int = -1
	var best_distance: float = NODE_HIT_PX
	for index: int in nodes.size():
		var distance: float = to_panel(nodes[index]["at"]).distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = index
	return best


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or actor == null or actor.device_id != InputComponent.KEYBOARD_DEVICE:
		return
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER:
		mark_selected()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	CartographyBaker.poll()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = 0.5
		if level != null and (scope == MapScope.ZONE or not CartographyBaker.is_archipelago(level)):
			_cracks = CartographyBaker.cracks(level)
	queue_redraw()


## Where a spot of this map's frame lands on the panel.
func to_panel(map_at: Vector2) -> Vector2:
	if _view.size.x <= 0.0:
		return _map_rect.get_center()
	return _map_rect.position + (map_at - _view.position) / _view.size * _map_rect.size


func from_panel(point: Vector2) -> Vector2:
	return _view.position + (point - _map_rect.position) / _map_rect.size * _view.size


# --- Drawing ------------------------------------------------------------------------------

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if not embedded:
		draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	var hero: Vector2 = Vector2(actor.global_position.x, actor.global_position.z) if actor != null else Vector2.ZERO
	_view = CartographyBaker.view_rect(level, scope, map, hero) if level != null and map != null else Rect2()
	var area: Rect2 = Rect2(Vector2(16.0, HEADER_HEIGHT + 8.0), Vector2(size.x - LEGEND_WIDTH - 40.0, size.y - HEADER_HEIGHT - FOOTER_HEIGHT - 16.0))
	var aspect: float = _view.size.x / maxf(_view.size.y, 0.001) if _view.size.x > 0.0 else 1.0
	var fit: Vector2 = Vector2(area.size.x, area.size.x / aspect) if area.size.x / aspect <= area.size.y else Vector2(area.size.y * aspect, area.size.y)
	_map_rect = Rect2(area.position + (area.size - fit) * 0.5, fit)
	_draw_header(font, hero)
	draw_rect(_map_rect.grow(6.0), FRAME_DARK)
	draw_rect(_map_rect.grow(4.0), FRAME_COLOR)
	if map != null and _view.size.x > 0.0:
		var whole: Rect2 = CartographyBaker.world_rect(map)
		var texel: Vector2 = Vector2(map.get_width(), map.get_height()) / whole.size
		draw_texture_rect_region(map, _map_rect, Rect2((_view.position - whole.position) * texel, _view.size * texel))
	else:
		draw_rect(_map_rect, CartographyBaker.PARCHMENT)
		draw_string(font, _map_rect.get_center(), "The map unrolls...", HORIZONTAL_ALIGNMENT_CENTER, -1.0, LABEL_SIZE, INK)
	_draw_cracks()
	_draw_nodes(font)
	_draw_party(font)
	_draw_marker(font)
	_draw_legend(font)
	var chosen: Dictionary = selected_node()
	var line: String = ""
	if not chosen.is_empty():
		line = String(chosen["label"]) + (" · %s" % chosen["note"] if String(chosen.get("note", "")) != "" else "")
	draw_string(font, Vector2(16.0, size.y - FOOTER_HEIGHT + 16.0), line, HORIZONTAL_ALIGNMENT_LEFT, size.x - LEGEND_WIDTH - 40.0, LABEL_SIZE + 1, PARCHMENT_TEXT)
	var keys: String = "←→↑↓ choose · light, Enter or a click: way-marker (again: take it away) · heavy%s: Zone ⇄ World Map · Esc, M or dodge closes" % (
		"" if embedded else " or Q / E")
	draw_string(font, Vector2(16.0, size.y - FOOTER_HEIGHT + 34.0), keys, HORIZONTAL_ALIGNMENT_LEFT, size.x - 32.0, HINT_SIZE, Color(0.82, 0.84, 0.9))


func _draw_header(font: Font, hero: Vector2) -> void:
	var title: String = CartographyBaker.map_title(level, scope, hero) if level != null else "The Map"
	draw_string(font, Vector2(16.0, 30.0), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 300.0, TITLE_SIZE, PARCHMENT_TEXT)
	_scope_tabs.clear()
	var names: Array[String] = ["Zone Map", "World Map"]
	var x: float = size.x - 270.0
	for index: int in names.size():
		var tab: Rect2 = Rect2(Vector2(x + index * 128.0, 12.0), Vector2(120.0, 28.0))
		_scope_tabs.append(tab)
		var chosen: bool = index == int(scope)
		draw_rect(tab, SELECTED if chosen else Color(0.16, 0.13, 0.1, 0.9))
		draw_rect(tab, FRAME_COLOR, false, 1.5)
		draw_string(font, tab.position + Vector2(0.0, 19.0), names[index], HORIZONTAL_ALIGNMENT_CENTER, tab.size.x, LABEL_SIZE + 1,
			INK if chosen else PARCHMENT_TEXT)


func _draw_cracks() -> void:
	for crack: Dictionary in _cracks:
		var spot: Vector2 = to_panel(CartographyBaker.to_map_frame(level, scope, crack["at"]))
		if not _map_rect.has_point(spot):
			continue
		if crack["calmed"]:
			draw_colored_polygon(WayfarerMinimapWidget.star(spot, 7.0, 3.0), WayfarerMinimapWidget.SAFFRON_GOLD)
		else:
			draw_circle(spot, 6.0, WayfarerMinimapWidget.SLATE)
			draw_arc(spot, 7.0, 0.0, TAU, 16, WayfarerMinimapWidget.SLATE_VIOLET, 2.0)


func _draw_nodes(font: Font) -> void:
	var shown: Array[int] = []
	for index: int in nodes.size():
		var node: Dictionary = nodes[index]
		var spot: Vector2 = to_panel(node["at"])
		if not _map_rect.grow(4.0).has_point(spot):
			continue
		var kind: int = int(node["kind"])
		if kind != NodeKind.ISLE:
			draw_node_icon(self, spot, kind, 7.0)
		if index == selected:
			draw_arc(spot, 13.0, 0.0, TAU, 24, SELECTED, 2.5)
		if kind in ALWAYS_NAMED or index == selected:
			shown.append(index)
	_draw_labels(font, shown)


## The marks' names, kept from piling on each other: the chosen mark first, then
## isles, towns, dungeons and quests, crossings, the rest; each tries above its
## mark, then below, right and left, inside the map's frame, and a name with no
## room is left off (its mark still shows, and choosing it names it). Only an
## isle's name and the chosen mark's are always written.
func _draw_labels(font: Font, shown: Array[int]) -> void:
	shown.sort_custom(func(a: int, b: int) -> bool: return _label_rank(a) < _label_rank(b))
	var taken: Array[Rect2] = []
	for index: int in shown:
		var spot: Vector2 = to_panel(nodes[index]["at"])
		if int(nodes[index]["kind"]) != NodeKind.ISLE:
			taken.append(Rect2(spot - Vector2(8.0, 8.0), Vector2(16.0, 16.0)))
	for index: int in shown:
		var node: Dictionary = nodes[index]
		var kind: int = int(node["kind"])
		var spot: Vector2 = to_panel(node["at"])
		var text_size: int = ISLE_SIZE if kind == NodeKind.ISLE else (TOWN_SIZE if kind == NodeKind.TOWN else LABEL_SIZE)
		var label: String = String(node["label"])
		var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_size).x
		var tall: float = float(text_size)
		# Baseline positions: above, below, right, left (an isle's name sits on its middle first).
		var tries: Array[Vector2] = [spot + Vector2(-width * 0.5, -12.0), spot + Vector2(-width * 0.5, tall + 12.0),
			spot + Vector2(12.0, tall * 0.35), spot + Vector2(-width - 12.0, tall * 0.35)]
		if kind == NodeKind.ISLE:
			tries.push_front(spot + Vector2(-width * 0.5, 6.0))
		var placed: bool = false
		for at: Vector2 in tries:
			var box: Rect2 = Rect2(at + Vector2(0.0, -tall), Vector2(width, tall + 4.0)).grow(2.0)
			var clear: bool = _map_rect.encloses(box)
			for other: Rect2 in taken:
				if other.intersects(box) and not other.has_point(spot):
					clear = false
					break
			if clear or (at == tries[tries.size() - 1] and (index == selected or kind == NodeKind.ISLE)):
				var draw_at: Vector2 = at if clear else tries[0]
				draw_string_outline(font, draw_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_size, 4, Color(0.97, 0.93, 0.84, 0.9))
				draw_string(font, draw_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_size, INK)
				taken.append(Rect2(draw_at + Vector2(0.0, -tall), Vector2(width, tall + 4.0)))
				placed = true
				break
		if not placed:
			continue


## Which names get room first (lower first).
func _label_rank(index: int) -> int:
	if index == selected:
		return 0
	match int(nodes[index]["kind"]):
		NodeKind.ISLE:
			return 1
		NodeKind.TOWN:
			return 2
		NodeKind.DUNGEON, NodeKind.QUEST:
			return 3
		NodeKind.CROSSING:
			return 4
	return 5


func _draw_party(font: Font) -> void:
	if CombatDirector.current == null or level == null:
		return
	for member: ActorBase in CombatDirector.current.alive_party():
		if member == actor:
			continue
		var spot: Vector2 = to_panel(CartographyBaker.to_map_frame(level, scope, Vector2(member.global_position.x, member.global_position.z)))
		var tint: Color = WayfarerMinimapWidget.SEAT_COLORS[clampi(member.party_slot, 0, 4)]
		draw_circle(spot, 5.0, tint)
		draw_arc(spot, 5.5, 0.0, TAU, 14, FRAME_DARK, 1.5)
		draw_string(font, spot + Vector2(-12.0, -8.0), "P%d" % (member.party_slot + 1), HORIZONTAL_ALIGNMENT_CENTER, 24.0, HINT_SIZE, INK)
	if actor != null:
		draw_player_arrow(self, to_panel(hero_map_position()), actor.rotation.y, 11.0)


func _draw_marker(font: Font) -> void:
	if hud == null or not hud.has_waymarker() or level == null:
		return
	var marker: Dictionary = hud.waymarker
	var isle: StringName = marker.get("isle", &"")
	var local: Vector2 = marker.get("local", Vector2.ZERO)
	var at: Vector2 = local
	if CartographyBaker.is_archipelago(level):
		if scope == MapScope.WORLD:
			at = CalderaAtlas.isle(isle).sound_position + local if isle != &"" else CartographyBaker.to_map_frame(level, scope, local)
		elif isle != CartographyBaker.active_isle(level):
			at = hud.pinned_target_xz
	var spot: Vector2 = to_panel(at)
	if _map_rect.grow(2.0).has_point(spot):
		draw_line(spot, spot + Vector2(0.0, -20.0), FRAME_DARK, 2.0)
		draw_colored_polygon(PackedVector2Array([spot + Vector2(0.0, -20.0), spot + Vector2(13.0, -15.5), spot + Vector2(0.0, -11.0)]), MARKER_COLOR)
	var away: float = Vector2(actor.global_position.x, actor.global_position.z).distance_to(hud.pinned_target_xz) if actor != null and hud.has_pin() else 0.0
	var via: String = String(marker.get("via", ""))
	var text: String = "Way-marker: %s%s · %d m" % [marker.get("label", ""), (" (take %s first)" % via) if via != "" else "", roundi(away)]
	draw_string(font, Vector2(16.0, HEADER_HEIGHT - 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, size.x - LEGEND_WIDTH - 40.0, LABEL_SIZE, MARKER_COLOR.lightened(0.3))


## The legend: each kind of mark this map shows, plus you, the party, the cracks and the way-marker.
func _draw_legend(font: Font) -> void:
	var box: Rect2 = Rect2(Vector2(size.x - LEGEND_WIDTH - 16.0, HEADER_HEIGHT + 8.0), Vector2(LEGEND_WIDTH, 0.0))
	var present: Array[int] = []
	for node: Dictionary in nodes:
		var kind: int = int(node["kind"])
		if kind != NodeKind.ISLE and not present.has(kind):
			present.append(kind)
	present.sort()
	var rows: int = present.size() + 4
	box.size.y = 34.0 + rows * 20.0
	draw_rect(box, Color(0.13, 0.1, 0.08, 0.92))
	draw_rect(box, FRAME_COLOR, false, 1.5)
	draw_string(font, box.position + Vector2(10.0, 22.0), "Legend", HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOWN_SIZE, PARCHMENT_TEXT)
	var y: float = box.position.y + 44.0
	for kind: int in present:
		draw_node_icon(self, Vector2(box.position.x + 18.0, y - 4.0), kind, 6.0)
		draw_string(font, Vector2(box.position.x + 34.0, y), CartographyBaker.NODE_KIND_NAMES[kind], HORIZONTAL_ALIGNMENT_LEFT, -1.0, LABEL_SIZE, PARCHMENT_TEXT)
		y += 20.0
	draw_player_arrow(self, Vector2(box.position.x + 18.0, y - 4.0), 0.0, 8.0)
	draw_string(font, Vector2(box.position.x + 34.0, y), "You (the way you face)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, LABEL_SIZE, PARCHMENT_TEXT)
	y += 20.0
	draw_circle(Vector2(box.position.x + 18.0, y - 4.0), 5.0, WayfarerMinimapWidget.SEAT_COLORS[1])
	draw_string(font, Vector2(box.position.x + 34.0, y), "Your party", HORIZONTAL_ALIGNMENT_LEFT, -1.0, LABEL_SIZE, PARCHMENT_TEXT)
	y += 20.0
	draw_circle(Vector2(box.position.x + 18.0, y - 4.0), 5.0, WayfarerMinimapWidget.SLATE)
	draw_string(font, Vector2(box.position.x + 34.0, y), "Hush-Crack (gold star: calmed)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, LABEL_SIZE, PARCHMENT_TEXT)
	y += 20.0
	var flag: Vector2 = Vector2(box.position.x + 14.0, y + 2.0)
	draw_line(flag, flag + Vector2(0.0, -14.0), FRAME_DARK, 2.0)
	draw_colored_polygon(PackedVector2Array([flag + Vector2(0.0, -14.0), flag + Vector2(9.0, -11.0), flag + Vector2(0.0, -8.0)]), MARKER_COLOR)
	draw_string(font, Vector2(box.position.x + 34.0, y), "Way-marker", HORIZONTAL_ALIGNMENT_LEFT, -1.0, LABEL_SIZE, PARCHMENT_TEXT)


## The hero's arrow at `at`, pointing the way a facing of `yaw` looks (north up).
static func draw_player_arrow(canvas: CanvasItem, at: Vector2, yaw: float, length: float) -> void:
	var points: PackedVector2Array = arrow_points(at, yaw, length)
	canvas.draw_colored_polygon(points, ARROW_COLOR)
	canvas.draw_polyline(points + PackedVector2Array([points[0]]), Color(0.18, 0.12, 0.08), 2.0)


## The arrow's corners, its tip first: a hero facing -Z (yaw 0) points up the map, one turned left (yaw +90°) points left.
static func arrow_points(at: Vector2, yaw: float, length: float) -> PackedVector2Array:
	var ahead: Vector2 = Vector2(-sin(yaw), -cos(yaw))
	var side: Vector2 = Vector2(-ahead.y, ahead.x)
	return PackedVector2Array([at + ahead * length, at - ahead * length * 0.55 + side * length * 0.62, at - ahead * length * 0.2,
		at - ahead * length * 0.55 - side * length * 0.62])


## A map mark of a kind, `size` px round, at `at`.
static func draw_node_icon(canvas: CanvasItem, at: Vector2, kind: int, size: float) -> void:
	var tint: Color = KIND_COLORS[clampi(kind, 0, KIND_COLORS.size() - 1)]
	var ink: Color = Color(0.18, 0.12, 0.08)
	match kind:
		NodeKind.TOWN:
			var walls: Rect2 = Rect2(at + Vector2(-size, -size * 0.2), Vector2(size * 2.0, size * 1.2))
			canvas.draw_rect(walls, tint)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-size * 1.25, -size * 0.2), at + Vector2(0.0, -size * 1.3),
				at + Vector2(size * 1.25, -size * 0.2)]), tint.darkened(0.3))
			canvas.draw_rect(walls, ink, false, 1.0)
		NodeKind.QUEST:
			canvas.draw_circle(at, size, tint)
			canvas.draw_arc(at, size, 0.0, TAU, 16, ink, 1.2)
			canvas.draw_rect(Rect2(at + Vector2(-size * 0.14, -size * 0.65), Vector2(size * 0.28, size * 0.75)), ink)
			canvas.draw_circle(at + Vector2(0.0, size * 0.48), size * 0.16, ink)
		NodeKind.DUNGEON:
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-size, size), at + Vector2(-size, -size * 0.2), at + Vector2(-size * 0.6, -size * 0.85),
				at + Vector2(0.0, -size), at + Vector2(size * 0.6, -size * 0.85), at + Vector2(size, -size * 0.2), at + Vector2(size, size)]), tint)
			canvas.draw_rect(Rect2(at + Vector2(-size * 0.4, -size * 0.1), Vector2(size * 0.8, size * 1.1)), ink)
		NodeKind.CROSSING:
			canvas.draw_circle(at, size, Color(0.95, 0.92, 0.84))
			canvas.draw_arc(at, size, 0.0, TAU, 16, tint, 2.0)
			canvas.draw_line(at + Vector2(-size * 0.6, 0.0), at + Vector2(size * 0.6, 0.0), tint, 2.0)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(size * 0.75, 0.0), at + Vector2(size * 0.3, -size * 0.35), at + Vector2(size * 0.3, size * 0.35)]), tint)
		NodeKind.BEACON:
			canvas.draw_rect(Rect2(at + Vector2(-size * 0.35, -size * 0.1), Vector2(size * 0.7, size * 1.1)), Color(0.78, 0.75, 0.68))
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -size * 1.2), at + Vector2(size * 0.55, -size * 0.1), at + Vector2(-size * 0.55, -size * 0.1)]), tint)
		NodeKind.LANDMARK:
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -size * 0.8), at + Vector2(size * 0.8, 0.0), at + Vector2(0.0, size * 0.8),
				at + Vector2(-size * 0.8, 0.0)]), tint)
		NodeKind.DESK:
			WayfarerMinimapWidget.draw_glyph(canvas, at, CartographyBaker.Glyph.DESK, size)
		NodeKind.PORTAL:
			WayfarerMinimapWidget.draw_glyph(canvas, at, CartographyBaker.Glyph.PORTAL, size)
		NodeKind.SHRINE:
			WayfarerMinimapWidget.draw_glyph(canvas, at, CartographyBaker.Glyph.SHRINE, size)
