## The Wayfarer's minimap (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §7.2),
## top-right of each player's HUD: 124 px across with one or two players, 92 px
## with three or four. A 160 m window of the level's parchment map, north up,
## centred on its hero, framed by an octagonal brass Chime-Ring lettered N, E, S
## and W, with a wedge for where the camera looks. On it:
##   P1 to P5    gems in each seat's colour (held to the rim past 80 m)
##   Hush-Cracks slate blots while open, Saffron-Gold cairn stars once calmed
##   glyphs     bells for the shrines, a quill for the desks, a ring for portals
##   a pin      the place the hero pinned on the Atlas
## Under it a ribbon names the sub-zone and the chunk, "Oakshire-Wick · (Chunk 6, 6)",
## and counts the cracks: "Hush-Cracks: 3/9 Calmed".
class_name WayfarerMinimapWidget
extends Control

const SIZE_FEW: float = 124.0
const SIZE_MANY: float = 92.0
## Metres of world across the window, and how far from the hero a gem still shows where it is.
const WINDOW_M: float = 160.0
const RIM_REACH_M: float = 80.0
const MARGIN: float = 14.0
const RIBBON_HEIGHT: float = 30.0
const RIM_WIDTH: float = 5.0
const BRASS: Color = Color("#B08A3E")
const BRASS_LIGHT: Color = Color("#E2C47A")
const BRASS_DARK: Color = Color("#5E4520")
const SLATE: Color = Color("#48505E")
const SLATE_VIOLET: Color = Color("#6A5F8E")
const SAFFRON_GOLD: Color = Color("#E8B64A")
const NORTH_RED: Color = Color("#B8483A")
const WEDGE_COLOR: Color = Color(1.0, 0.97, 0.86, 0.32)
const WEDGE_HALF_ANGLE: float = deg_to_rad(32.0)
const GLYPH_COLORS: Array[Color] = [Color("#3E8C86"), Color("#8A5A2E"), Color("#7A56C2")]
const RIBBON_COLOR: Color = Color(0.17, 0.12, 0.08, 0.86)
const TEXT_COLOR: Color = Color("#F3E9CF")
## The seats' colours, P1 to P5.
const SEAT_COLORS: Array[Color] = [Color(0.32, 0.52, 0.9), Color(0.34, 0.76, 0.46), Color(0.92, 0.5, 0.22), Color(0.7, 0.45, 0.9),
	Color(0.95, 0.82, 0.3)]
const REDRAW_TIME: float = 0.1
const LIST_TIME: float = 1.0

var actor: ActorBase
var level: LevelBase
var map: ImageTexture

var _cracks: Array[Dictionary] = []
var _glyphs: Array[Dictionary] = []
var _redraw_left: float = 0.0
var _list_left: float = 0.0
var _ribbon: String = ""
var _calmed_text: String = ""


func setup(target_actor: ActorBase, target_level: LevelBase) -> void:
	actor = target_actor
	level = target_level


func _ready() -> void:
	name = "WayfarerMinimap"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	_fit()
	if level != null:
		map = CartographyBaker.cached_map(level)
		if map == null:
			CartographyBaker.request_level_map(level, _on_map_ready)


func _on_map_ready(texture: ImageTexture) -> void:
	map = texture
	queue_redraw()


## How wide the window is now: 124 px with one or two players on this machine, 92 px with more.
func window_size() -> float:
	var views: int = get_tree().get_nodes_in_group(PlayerHUD.GROUP).size() if is_inside_tree() else 1
	return SIZE_FEW if views <= 2 else SIZE_MANY


func _fit() -> void:
	var side: float = window_size()
	size = Vector2(side, side + RIBBON_HEIGHT)
	position = Vector2(-side - MARGIN, MARGIN)
	offset_left = -side - MARGIN
	offset_right = -MARGIN
	offset_top = MARGIN
	offset_bottom = MARGIN + side + RIBBON_HEIGHT


func _process(delta: float) -> void:
	CartographyBaker.poll()
	if not is_instance_valid(actor):
		return
	_list_left -= delta
	if _list_left <= 0.0:
		_list_left = LIST_TIME
		_refresh_lists()
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = REDRAW_TIME
		_fit()
		_refresh_ribbon()
		queue_redraw()


func _refresh_lists() -> void:
	if level == null:
		return
	_cracks = CartographyBaker.cracks(level)
	_glyphs = CartographyBaker.glyphs(get_tree())


func _refresh_ribbon() -> void:
	var at: Vector3 = actor.global_position
	var zone: WorldMapZoneResource = WorldVisualCatalog.map_zone_at(level.instance_id(), Vector2(at.x, at.z)) if level != null else null
	var chunk: Vector2i = WorldGridConfig.world_to_chunk(at)
	_ribbon = "%s · (Chunk %d, %d)" % [zone.display_name if zone != null else "The Wilds", chunk.x, chunk.y]
	var calmed: int = 0
	for crack: Dictionary in _cracks:
		calmed += 1 if crack["calmed"] else 0
	_calmed_text = "Hush-Cracks: %d/%d Calmed" % [calmed, _cracks.size()]


## The ribbon's place line ("<Sub-Zone> · (Chunk X, Z)") and its crack count ("Hush-Cracks: X/Y Calmed").
func ribbon_text() -> String:
	_refresh_ribbon()
	return _ribbon


func calmed_text() -> String:
	_refresh_lists()
	_refresh_ribbon()
	return _calmed_text


## The cracks drawn now: [{"id", "at", "calmed"}] (tests).
func drawn_cracks() -> Array[Dictionary]:
	_refresh_lists()
	return _cracks


## Where a world spot lands in the window (pixels from its top-left), held to the rim past RIM_REACH_M.
func to_window(world: Vector3) -> Vector2:
	var side: float = window_size()
	var center: Vector2 = Vector2(side, side) * 0.5
	var radius: float = side * 0.5 - RIM_WIDTH - 3.0
	var offset: Vector2 = Vector2(world.x - actor.global_position.x, world.z - actor.global_position.z)
	if offset.length() > RIM_REACH_M:
		offset = offset.normalized() * RIM_REACH_M
	return center + offset / (WINDOW_M * 0.5) * radius


## The window's octagon (flat edges north, east, south and west).
static func octagon(center: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for corner: int in 8:
		var angle: float = PI / 8.0 + corner * PI / 4.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius / cos(PI / 8.0))
	return points


func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var side: float = window_size()
	var center: Vector2 = Vector2(side, side) * 0.5
	var radius: float = side * 0.5 - RIM_WIDTH
	var outline: PackedVector2Array = octagon(center, radius)
	# The parchment window, a 160 m square of the map under the octagon.
	var me: Vector2 = Vector2(actor.global_position.x, actor.global_position.z)
	if map != null:
		var uvs: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in outline:
			uvs.append(CartographyBaker.world_to_uv(map, me + (point - center) / radius * WINDOW_M * 0.5))
		draw_colored_polygon(outline, Color.WHITE, uvs, map)
	else:
		draw_colored_polygon(outline, CartographyBaker.PARCHMENT)
	# Where the camera looks.
	var view: PlayerCamera = level.camera_for_seat(actor.party_slot + 1) if level != null else null
	var yaw: float = view.yaw if view != null else actor.camera_yaw
	var ahead: Vector2 = Vector2(-sin(yaw), -cos(yaw))
	var wedge: PackedVector2Array = PackedVector2Array([center])
	for step: int in 7:
		var angle: float = -WEDGE_HALF_ANGLE + WEDGE_HALF_ANGLE * 2.0 * step / 6.0
		wedge.append(center + ahead.rotated(angle) * radius * 0.92)
	draw_colored_polygon(wedge, WEDGE_COLOR)
	# The Hush-Cracks: slate blots, or Saffron-Gold cairn stars once calmed.
	for crack: Dictionary in _cracks:
		var at: Vector2 = crack["at"]
		if at.distance_to(me) > WINDOW_M * 0.5:
			continue
		var spot: Vector2 = to_window(Vector3(at.x, 0.0, at.y))
		if crack["calmed"]:
			draw_colored_polygon(star(spot, 5.5, 2.4), SAFFRON_GOLD)
			draw_polyline(star(spot, 5.5, 2.4) + PackedVector2Array([star(spot, 5.5, 2.4)[0]]), BRASS_DARK, 1.0)
		else:
			draw_circle(spot, 5.0, SLATE)
			draw_arc(spot, 5.5, 0.0, TAU, 14, SLATE_VIOLET, 1.5)
	for glyph: Dictionary in _glyphs:
		var at: Vector2 = glyph["at"]
		if at.distance_to(me) > WINDOW_M * 0.5:
			continue
		draw_glyph(self, to_window(Vector3(at.x, 0.0, at.y)), int(glyph["glyph"]), 4.0)
	# The pin.
	var hud: PlayerHUD = PlayerHUD.for_actor(get_tree(), actor)
	if hud != null and hud.has_pin():
		var pin: Vector2 = to_window(Vector3(hud.pinned_target_xz.x, 0.0, hud.pinned_target_xz.y))
		draw_circle(pin, 3.5, SAFFRON_GOLD)
		draw_arc(pin, 5.5, 0.0, TAU, 14, BRASS_DARK, 1.5)
	# The party's gems, this hero's last (on top).
	var party: Array[ActorBase] = CombatDirector.current.alive_party()
	party.sort_custom(func(a: ActorBase, b: ActorBase) -> bool: return a != actor and b == actor)
	for member: ActorBase in party:
		var spot: Vector2 = to_window(member.global_position)
		var tint: Color = SEAT_COLORS[clampi(member.party_slot, 0, SEAT_COLORS.size() - 1)]
		var gem: float = 4.5 if member == actor else 3.6
		draw_colored_polygon(PackedVector2Array([spot + Vector2(0.0, -gem), spot + Vector2(gem, 0.0), spot + Vector2(0.0, gem), spot + Vector2(-gem, 0.0)]), tint)
		draw_polyline(PackedVector2Array([spot + Vector2(0.0, -gem), spot + Vector2(gem, 0.0), spot + Vector2(0.0, gem), spot + Vector2(-gem, 0.0),
			spot + Vector2(0.0, -gem)]), Color(1.0, 1.0, 1.0, 0.9) if member == actor else BRASS_DARK, 1.2)
	# The brass Chime-Ring and its letters.
	var ring: PackedVector2Array = octagon(center, radius + RIM_WIDTH * 0.5)
	ring.append(ring[0])
	draw_polyline(ring, BRASS, RIM_WIDTH, true)
	var inner: PackedVector2Array = octagon(center, radius - 0.5)
	inner.append(inner[0])
	draw_polyline(inner, BRASS_DARK, 1.0, true)
	var outer: PackedVector2Array = octagon(center, radius + RIM_WIDTH)
	outer.append(outer[0])
	draw_polyline(outer, BRASS_LIGHT, 1.0, true)
	var font: Font = ThemeDB.fallback_font
	var letters: Dictionary[String, Vector2] = {"N": Vector2(0.0, -1.0), "E": Vector2(1.0, 0.0), "S": Vector2(0.0, 1.0), "W": Vector2(-1.0, 0.0)}
	for letter: String in letters:
		var spot: Vector2 = center + letters[letter] * (radius + RIM_WIDTH * 0.5)
		draw_circle(spot, 6.5, BRASS_DARK)
		draw_string(font, spot + Vector2(-6.5, 4.0), letter, HORIZONTAL_ALIGNMENT_CENTER, 13.0, 10, NORTH_RED.lightened(0.2) if letter == "N" else TEXT_COLOR)
	# The ribbon.
	var band: Rect2 = Rect2(Vector2(-14.0, side + 2.0), Vector2(side + 28.0, RIBBON_HEIGHT - 4.0))
	draw_rect(band, RIBBON_COLOR)
	draw_rect(band, BRASS, false, 1.0)
	draw_string(font, band.position + Vector2(0.0, 11.0), _ribbon, HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 10, TEXT_COLOR)
	draw_string(font, band.position + Vector2(0.0, 23.0), _calmed_text, HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 10, SAFFRON_GOLD)


## A five-pointed star (a calmed crack's cairn).
static func star(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for corner: int in 10:
		var angle: float = -PI * 0.5 + corner * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * (outer if corner % 2 == 0 else inner))
	return points


## A map glyph on `canvas`: a bell (a shrine), a quill-and-page (a desk) or a ring (a portal), `size` px.
static func draw_glyph(canvas: CanvasItem, at: Vector2, glyph: int, size: float) -> void:
	var tint: Color = GLYPH_COLORS[clampi(glyph, 0, GLYPH_COLORS.size() - 1)]
	match glyph:
		CartographyBaker.Glyph.DESK:
			canvas.draw_rect(Rect2(at - Vector2(size, size * 0.7), Vector2(size * 2.0, size * 1.4)), Color(0.96, 0.93, 0.84))
			canvas.draw_rect(Rect2(at - Vector2(size, size * 0.7), Vector2(size * 2.0, size * 1.4)), tint, false, 1.2)
			canvas.draw_line(at + Vector2(-size * 0.6, size * 0.9), at + Vector2(size * 0.9, -size * 1.1), tint, 1.4)
		CartographyBaker.Glyph.PORTAL:
			canvas.draw_arc(at, size, 0.0, TAU, 16, tint, 2.0)
			canvas.draw_circle(at, size * 0.4, tint.lightened(0.3))
		CartographyBaker.Glyph.QUEST:
			WorldMapPanel.draw_node_icon(canvas, at, CartographyBaker.NodeKind.QUEST, size)
		CartographyBaker.Glyph.BEACON:
			WorldMapPanel.draw_node_icon(canvas, at, CartographyBaker.NodeKind.BEACON, size)
		_:
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -size), at + Vector2(size * 0.85, size * 0.6),
				at + Vector2(-size * 0.85, size * 0.6)]), tint)
			canvas.draw_circle(at + Vector2(0.0, size * 0.85), size * 0.3, tint.lightened(0.3))
