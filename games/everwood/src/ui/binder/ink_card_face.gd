## One Ink card's face, painted in code (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §7,
## the "Everwood Ink Card Deck" page): its Sign's colours, its name and Ink-Drop cost,
## its picture, what kind of card it is, what it does in a child's words, and the
## diamond it goes in. The eight deck cards paint their own pictures (art_motif);
## every other card paints its Sign's glyph over a blade or a shield. A Gilded Leaf
## copy shimmers along its edge and a Star-Ink copy twinkles.
##   full   the whole card (the card bench's spotlight, a new card's reveal)
##   mini   the picture, the name and the cost (the collection's grid)
## An empty face (&"") is a blank card: "Leave it empty".
class_name InkCardFace
extends Control

## The face's shape: five wide by seven tall.
const ASPECT: float = 7.0 / 5.0
## The picture is painted on a 300 x 240 canvas and scaled into its box.
const ART_SIZE: Vector2 = Vector2(300.0, 240.0)
const PAPER: Color = Color("#F2ECE1")
const DEEP_INK: Color = Color("#120D09")
const STONE: Array[Color] = [Color("#6E5D49"), Color("#8A7660"), Color("#A08A70"), Color("#B89E7E")]
## The deep ground under each Sign (ScribeSignResource.Sign order after NONE).
const SIGN_DEEP: Array[Color] = [Color("#2C1A0C"), Color("#0C2230"), Color("#2E220A"), Color("#1E1236")]
const DROP: Color = Color("#B993F2")
const DROP_EDGE: Color = Color("#E4DBFF")

## Which copy to paint (a copy key: the card id, with its finish).
var copy_key: StringName = &""
var mini: bool = false
## Highlighted in a grid: a gold ring round it.
var chosen: bool = false
## Dimmed when it can't go in right now.
var shut: bool = false
## The diamond it goes in ("R", "L", "L+R", "" for none).
var socket_word: String = ""
var _age: float = 0.0


func _init(key: StringName = &"", small: bool = false) -> void:
	copy_key = key
	mini = small
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_copy(key: StringName, socket: String = "") -> void:
	copy_key = key
	socket_word = socket
	queue_redraw()


func _process(delta: float) -> void:
	# The finer finishes shimmer, so they're redrawn as they glint.
	_age += delta
	if _finish() > 0 and is_visible_in_tree():
		queue_redraw()


func card() -> ScribeCardResource:
	return ArsenalCatalog.current.card(ScribeCardResource.copy_card_id(copy_key)) if copy_key != &"" and ArsenalCatalog.current != null else null


func _finish() -> int:
	return ScribeCardResource.copy_variant(copy_key) if copy_key != &"" else 0


func _fill(card: ScribeCardResource) -> Color:
	return AtelierTheme.sign_fill(card.scribe_sign) if card != null else AtelierTheme.LINE_DIM


func _deep(card: ScribeCardResource) -> Color:
	var index: int = (card.scribe_sign - 1) if card != null else -1
	return SIGN_DEEP[index] if index >= 0 and index < SIGN_DEEP.size() else AtelierTheme.PAGE_RAISED


func _draw() -> void:
	var listed: ScribeCardResource = card()
	var fill: Color = _fill(listed)
	var deep: Color = _deep(listed)
	var font: Font = ThemeDB.fallback_font
	var w: float = size.x
	var h: float = size.y
	var unit: float = w / 300.0
	# The card: its deep ground and its Sign's edge.
	var face: StyleBoxFlat = StyleBoxFlat.new()
	face.bg_color = deep
	face.border_color = fill
	face.set_border_width_all(maxi(2, roundi(4.0 * unit)))
	face.set_corner_radius_all(roundi(18.0 * unit))
	draw_style_box(face, Rect2(Vector2.ZERO, size))
	if listed == null:
		_draw_blank(font, unit)
		return
	# The band: its glyph, its name, its Ink-Drop dots.
	var band_h: float = h * (0.13 if not mini else 0.0)
	var art_top: float = h * 0.13 if not mini else w * 0.06
	if not mini:
		_draw_glyph(Vector2(w * 0.09, band_h * 0.55), 15.0 * unit, listed.scribe_sign, fill)
		draw_string(font, Vector2(w * 0.17, band_h * 0.74), listed.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			_fit_size(font, listed.display_name, w * 0.62, roundi(24.0 * unit)), PAPER)
		_draw_cost(Vector2(w * 0.93, band_h * 0.52), listed, unit)
	# The picture.
	var art_h: float = h * (0.47 if not mini else 0.6)
	var art_rect: Rect2 = Rect2(Vector2(w * 0.05, art_top), Vector2(w * 0.9, art_h))
	_draw_art(art_rect, listed, fill, deep)
	var frame: StyleBoxFlat = StyleBoxFlat.new()
	frame.draw_center = false
	frame.border_color = fill
	frame.set_border_width_all(maxi(1, roundi(2.0 * unit)))
	frame.set_corner_radius_all(roundi(10.0 * unit))
	draw_style_box(frame, art_rect)
	if mini:
		# The name and the cost under the picture.
		var name_y: float = art_rect.end.y + h * 0.13
		draw_string(font, Vector2(w * 0.06, name_y), listed.display_name, HORIZONTAL_ALIGNMENT_CENTER, w * 0.88,
			_fit_size(font, listed.display_name, w * 0.88, roundi(30.0 * unit)), PAPER)
		_draw_cost(Vector2(w * 0.5 + 9.0 * unit * (_cost_of(listed) - 1), name_y + h * 0.1), listed, unit * 1.4, true)
	else:
		# What kind it is, and what it does in a child's words.
		var kind_y: float = art_rect.end.y + h * 0.055
		var mode: String = ScribeCardResource.MODE_NAMES[listed.manifestation_mode]
		var kind: String = "%s · %s" % [ArsenalCatalog.current.sign_seal(listed.scribe_sign).display_name, mode]
		draw_string(font, Vector2(w * 0.06, kind_y), kind.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w * 0.62, roundi(13.0 * unit), AtelierTheme.sign_text(listed.scribe_sign))
		draw_string(font, Vector2(w * 0.06, kind_y), listed.rarity_name().to_upper(), HORIZONTAL_ALIGNMENT_RIGHT, w * 0.88, roundi(13.0 * unit), AtelierTheme.INK_MUTED)
		var said: String = listed.kid_text if listed.kid_text != "" else listed.description
		draw_multiline_string(font, Vector2(w * 0.06, kind_y + h * 0.055), said, HORIZONTAL_ALIGNMENT_LEFT, w * 0.72, roundi(15.0 * unit), 5, PAPER)
	if socket_word != "" and not mini:
		_draw_socket_badge(Vector2(w * 0.88, h * 0.9), 22.0 * unit, fill, socket_word, font)
	_draw_finish(unit)
	if shut:
		var veil: StyleBoxFlat = StyleBoxFlat.new()
		veil.bg_color = Color(0.05, 0.035, 0.025, 0.55)
		veil.set_corner_radius_all(roundi(18.0 * unit))
		draw_style_box(veil, Rect2(Vector2.ZERO, size))
	if chosen:
		var ring: StyleBoxFlat = StyleBoxFlat.new()
		ring.draw_center = false
		ring.border_color = AtelierTheme.GOLD
		ring.set_border_width_all(maxi(3, roundi(6.0 * unit)))
		ring.set_corner_radius_all(roundi(20.0 * unit))
		ring.expand_margin_left = 4.0
		ring.expand_margin_right = 4.0
		ring.expand_margin_top = 4.0
		ring.expand_margin_bottom = 4.0
		draw_style_box(ring, Rect2(Vector2.ZERO, size))


## The blank card: "Leave it empty".
func _draw_blank(font: Font, unit: float) -> void:
	var w: float = size.x
	var h: float = size.y
	draw_dashed_line(Vector2(w * 0.2, h * 0.3), Vector2(w * 0.8, h * 0.3), AtelierTheme.LINE_DIM, 2.0 * unit, 8.0 * unit)
	draw_string(font, Vector2(w * 0.05, h * 0.52), "Leave it", HORIZONTAL_ALIGNMENT_CENTER, w * 0.9, roundi((30.0 if mini else 26.0) * unit), AtelierTheme.INK_MUTED)
	draw_string(font, Vector2(w * 0.05, h * 0.62), "empty", HORIZONTAL_ALIGNMENT_CENTER, w * 0.9, roundi((30.0 if mini else 26.0) * unit), AtelierTheme.INK_MUTED)
	if chosen:
		var ring: StyleBoxFlat = StyleBoxFlat.new()
		ring.draw_center = false
		ring.border_color = AtelierTheme.GOLD
		ring.set_border_width_all(maxi(3, roundi(6.0 * unit)))
		ring.set_corner_radius_all(roundi(20.0 * unit))
		draw_style_box(ring, Rect2(Vector2.ZERO, size))


## The biggest font size up to `size` at which `words` fit in `width`.
static func _fit_size(font: Font, words: String, width: float, size: int) -> int:
	var fitted: int = size
	while fitted > 8 and font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x > width:
		fitted -= 1
	return fitted


static func _cost_of(listed: ScribeCardResource) -> int:
	var socket: int = GrimoireRules.SOCKET_L if listed.slot != ScribeCardResource.GrimoireSlot.SIGNATURE else GrimoireRules.SOCKET_R
	if listed.slot == ScribeCardResource.GrimoireSlot.ULTIMATE:
		socket = GrimoireRules.SOCKET_LR
	return GrimoireRules.ink_cost(socket, listed, false)


func _draw_cost(right_center: Vector2, listed: ScribeCardResource, unit: float, centred: bool = false) -> void:
	var cost: int = _cost_of(listed)
	for dot: int in cost:
		var at: Vector2 = right_center - Vector2(float(dot) * 18.0 * unit, 0.0)
		if centred:
			at = right_center - Vector2(float(dot) * 18.0 * unit, 0.0)
		draw_circle(at, 7.5 * unit, DROP_EDGE)
		draw_circle(at, 6.0 * unit, DROP)


## A finer copy's shine: a Gilded Leaf's gold edge glints round the card; a Star-Ink copy twinkles.
func _draw_finish(unit: float) -> void:
	var finish: int = _finish()
	if finish <= 0:
		return
	var w: float = size.x
	var h: float = size.y
	var edge: StyleBoxFlat = StyleBoxFlat.new()
	edge.draw_center = false
	edge.border_color = Color(1.0, 0.86, 0.45, 0.55 + 0.35 * sin(_age * 3.0))
	edge.set_border_width_all(maxi(2, roundi(3.0 * unit)))
	edge.set_corner_radius_all(roundi(18.0 * unit))
	draw_style_box(edge, Rect2(Vector2.ZERO, size).grow(-3.0 * unit))
	if finish >= 2:
		for twinkle: int in 6:
			var phase: float = fmod(_age * 0.8 + float(twinkle) * 0.37, 1.0)
			var at: Vector2 = Vector2(w * fmod(0.17 + float(twinkle) * 0.29, 0.9) + w * 0.05, h * fmod(0.11 + float(twinkle) * 0.41, 0.85) + h * 0.05)
			_sparkle(at, (3.0 + 6.0 * sin(phase * PI)) * unit, Color(1.0, 0.97, 0.85, sin(phase * PI)))


func _draw_socket_badge(center: Vector2, half: float, fill: Color, word: String, font: Font) -> void:
	var diamond: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -half), center + Vector2(half, 0.0), center + Vector2(0.0, half), center + Vector2(-half, 0.0)])
	draw_colored_polygon(diamond, AtelierTheme.PAGE)
	diamond.append(diamond[0])
	draw_polyline(diamond, fill, maxf(2.0, half * 0.1))
	draw_string(font, center + Vector2(-half, half * 0.3), word, HORIZONTAL_ALIGNMENT_CENTER, half * 2.0, roundi(half * (0.8 if word.length() < 3 else 0.55)), PAPER)


# --- Glyphs ---------------------------------------------------------------------------------------

## The Sign's glyph: a gear for Iron-Root, a star for Rime-Gale, a sun for Warm-Hearth, a moon for Star-Tide.
func _draw_glyph(center: Vector2, radius: float, scribe_sign: int, color: Color) -> void:
	match scribe_sign:
		ScribeSignResource.Sign.SIGN_IRON_ROOT:
			for tooth: int in 8:
				var angle: float = float(tooth) * TAU / 8.0
				var out: Vector2 = Vector2(cos(angle), sin(angle))
				var side: Vector2 = out.orthogonal() * radius * 0.2
				draw_colored_polygon(PackedVector2Array([center + out * radius * 0.7 - side, center + out * radius * 1.15 - side,
					center + out * radius * 1.15 + side, center + out * radius * 0.7 + side]), color)
			draw_circle(center, radius * 0.85, color)
			draw_circle(center, radius * 0.36, DEEP_INK)
		ScribeSignResource.Sign.SIGN_RIME_GALE:
			var points: PackedVector2Array = PackedVector2Array()
			for corner: int in 12:
				var angle: float = -PI * 0.5 + float(corner) * PI / 6.0
				points.append(center + Vector2(cos(angle), sin(angle)) * radius * (1.15 if corner % 2 == 0 else 0.42))
			draw_colored_polygon(points, color)
		ScribeSignResource.Sign.SIGN_WARM_HEARTH:
			for ray: int in 10:
				var angle: float = float(ray) * TAU / 10.0
				draw_line(center + Vector2(cos(angle), sin(angle)) * radius * 0.75, center + Vector2(cos(angle), sin(angle)) * radius * 1.2, color, radius * 0.2)
			draw_circle(center, radius * 0.6, color)
		ScribeSignResource.Sign.SIGN_STAR_TIDE:
			_crescent(center, radius * 1.05, color, Color(0, 0, 0, 0))
		_:
			draw_arc(center, radius * 0.8, 0.0, TAU, 24, color, radius * 0.2)


## A crescent moon: a disc with a smaller disc clipped out of its right side.
func _crescent(center: Vector2, radius: float, color: Color, _behind: Color) -> void:
	for piece: PackedVector2Array in crescent_points(center, radius):
		draw_colored_polygon(piece, color)


static func crescent_points(center: Vector2, radius: float) -> Array[PackedVector2Array]:
	var moon: PackedVector2Array = PackedVector2Array()
	var bite: PackedVector2Array = PackedVector2Array()
	for step: int in 32:
		var angle: float = float(step) / 32.0 * TAU
		moon.append(center + Vector2(cos(angle), sin(angle)) * radius)
		bite.append(center + Vector2(radius * 0.42, -radius * 0.12) + Vector2(cos(angle), sin(angle)) * radius * 0.82)
	var pieces: Array[PackedVector2Array] = []
	pieces.assign(Geometry2D.clip_polygons(moon, bite))
	return pieces


func _sparkle(at: Vector2, size_px: float, color: Color) -> void:
	if size_px <= 0.5:
		return
	draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -size_px), at + Vector2(size_px * 0.25, -size_px * 0.25), at + Vector2(size_px, 0.0),
		at + Vector2(size_px * 0.25, size_px * 0.25), at + Vector2(0.0, size_px), at + Vector2(-size_px * 0.25, size_px * 0.25),
		at + Vector2(-size_px, 0.0), at + Vector2(-size_px * 0.25, -size_px * 0.25)]), color)


# --- The pictures -----------------------------------------------------------------------------------

## A quadratic curve through three points, as a line of points.
static func _quad(a: Vector2, control: Vector2, b: Vector2, steps: int = 18) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in steps + 1:
		var t: float = float(step) / float(steps)
		points.append(a.lerp(control, t).lerp(control.lerp(b, t), t))
	return points


static func _cubic(a: Vector2, c1: Vector2, c2: Vector2, b: Vector2, steps: int = 24) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in steps + 1:
		var t: float = float(step) / float(steps)
		var ab: Vector2 = a.lerp(c1, t)
		var bc: Vector2 = c1.lerp(c2, t)
		var cd: Vector2 = c2.lerp(b, t)
		points.append(ab.lerp(bc, t).lerp(bc.lerp(cd, t), t))
	return points


## The picture box: a glowing ground, two ink-wash hills, then the card's own motif (on a 300 x 240 canvas).
func _draw_art(box: Rect2, listed: ScribeCardResource, fill: Color, deep: Color) -> void:
	var text: Color = AtelierTheme.sign_text(listed.scribe_sign)
	var k: float = minf(box.size.x / ART_SIZE.x, box.size.y / ART_SIZE.y)
	var origin: Vector2 = box.position + (box.size - ART_SIZE * k) * 0.5
	draw_rect(box, deep)
	# A soft glow behind the motif.
	for ring: int in 6:
		draw_circle(box.get_center() - Vector2(0.0, box.size.y * 0.1), box.size.y * (0.6 - float(ring) * 0.09), Color(fill, 0.07 + float(ring) * 0.02))
	draw_set_transform(origin, 0.0, Vector2(k, k))
	var hills: PackedVector2Array = _quad(Vector2(0, 190), Vector2(60, 160), Vector2(150, 182))
	hills.append_array(_quad(Vector2(150, 182), Vector2(230, 168), Vector2(300, 172)))
	hills.append(Vector2(300, 240))
	hills.append(Vector2(0, 240))
	draw_colored_polygon(hills, Color(deep.darkened(0.3), 0.95))
	var low: PackedVector2Array = _quad(Vector2(0, 212), Vector2(160, 190), Vector2(300, 202))
	low.append(Vector2(300, 240))
	low.append(Vector2(0, 240))
	draw_colored_polygon(low, Color(DEEP_INK, 0.6))
	match listed.art_motif:
		&"cairn":
			_motif_cairn(fill, text)
		&"hedge":
			_motif_hedge(fill, text)
		&"squall":
			_motif_squall(fill, text)
		&"mantle":
			_motif_mantle(fill, text)
		&"ember":
			_motif_ember(fill, text)
		&"hearth":
			_motif_hearth(fill, text)
		&"thrust":
			_motif_thrust(fill, text)
		&"weir":
			_motif_weir(fill, text)
		_:
			_motif_plain(listed, fill, text)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in 28:
		var angle: float = float(step) / 28.0 * TAU
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _flake(at: Vector2, size_px: float, color: Color) -> void:
	for spoke: int in 3:
		var angle: float = float(spoke) * PI / 3.0 + PI * 0.5
		var out: Vector2 = Vector2(cos(angle), sin(angle)) * size_px
		draw_line(at - out, at + out, color, 2.0)


func _motif_cairn(fill: Color, text: Color) -> void:
	_ellipse(Vector2(150, 192), Vector2(62, 20), STONE[0])
	_ellipse(Vector2(148, 162), Vector2(48, 18), STONE[1])
	_ellipse(Vector2(152, 136), Vector2(34, 14), STONE[2])
	_ellipse(Vector2(150, 114), Vector2(20, 10), STONE[3])
	var slash: PackedVector2Array = _quad(Vector2(58, 58), Vector2(150, 90), Vector2(236, 200))
	draw_polyline(slash, text, 10.0, true)
	draw_polyline(slash, Color("#FFF2D8"), 3.0, true)
	_sparkle(Vector2(206, 160), 9.0, text)
	_sparkle(Vector2(230, 122), 6.0, text)
	_sparkle(Vector2(182, 186), 5.0, Color("#FFF2D8"))


func _motif_hedge(fill: Color, text: Color) -> void:
	var shield: PackedVector2Array = PackedVector2Array([Vector2(150, 40), Vector2(218, 62), Vector2(214, 140)])
	shield.append_array(_quad(Vector2(214, 140), Vector2(206, 188), Vector2(150, 214)))
	shield.append_array(_quad(Vector2(150, 214), Vector2(94, 188), Vector2(86, 140)))
	shield.append(Vector2(82, 62))
	draw_colored_polygon(shield, Color("#3A2414"))
	shield.append(shield[0])
	draw_polyline(shield, fill, 5.0, true)
	for row: int in 5:
		var y: float = 76.0 + float(row) * 26.0
		draw_polyline(_quad(Vector2(96, y), Vector2(150, y - 20.0), Vector2(204, y + 6.0)), text, 5.0, true)
		_ellipse(Vector2(112.0 + float(row) * 18.0, y - 4.0), Vector2(7, 4), Color("#7FA05A"))
	draw_polyline(_quad(Vector2(150, 214), Vector2(138, 226), Vector2(120, 232)), text, 4.0, true)
	draw_polyline(_quad(Vector2(150, 214), Vector2(164, 228), Vector2(186, 232)), text, 4.0, true)


func _motif_squall(fill: Color, text: Color) -> void:
	var whip: PackedVector2Array = _cubic(Vector2(40, 170), Vector2(90, 60), Vector2(150, 200), Vector2(200, 100))
	whip.append_array(_cubic(Vector2(200, 100), Vector2(230, 40), Vector2(270, 60), Vector2(262, 40)))
	draw_polyline(whip, Color(fill, 0.75), 12.0, true)
	draw_polyline(whip, Color("#E8F6FF"), 3.0, true)
	for streak: int in 4:
		draw_line(Vector2(30.0 + float(streak) * 50.0, 70.0 + float(streak) * 22.0), Vector2(70.0 + float(streak) * 50.0, 64.0 + float(streak) * 22.0), Color(text, 0.6), 2.0)
	_flake(Vector2(258, 46), 16.0, Color("#E8F6FF"))
	_flake(Vector2(70, 120), 9.0, text)
	_flake(Vector2(214, 170), 11.0, text)


func _motif_mantle(_fill: Color, text: Color) -> void:
	var cloak: PackedVector2Array = _quad(Vector2(110, 52), Vector2(150, 40), Vector2(190, 52))
	cloak.append(Vector2(222, 196))
	cloak.append_array(_quad(Vector2(222, 196), Vector2(150, 214), Vector2(78, 196)))
	draw_colored_polygon(cloak, Color("#16384C"))
	cloak.append(cloak[0])
	draw_polyline(cloak, text, 4.0, true)
	draw_polyline(_quad(Vector2(110, 52), Vector2(150, 72), Vector2(190, 52)), Color("#E8F6FF"), 6.0, true)
	_flake(Vector2(126, 110), 10.0, Color("#E8F6FF"))
	_flake(Vector2(176, 140), 13.0, text)
	_flake(Vector2(140, 168), 8.0, Color("#E8F6FF"))
	_flake(Vector2(190, 92), 7.0, text)
	_flake(Vector2(108, 152), 7.0, text)


func _motif_ember(fill: Color, text: Color) -> void:
	draw_rect(Rect2(132, 118, 36, 84), Color("#EFE2C4"))
	draw_rect(Rect2(132, 118, 36, 12), Color("#D9C8A2"))
	draw_line(Vector2(150, 118), Vector2(150, 104), Color("#3A2A14"), 3.0)
	var flame: PackedVector2Array = _quad(Vector2(150, 52), Vector2(174, 86), Vector2(158, 104))
	flame.append_array(_quad(Vector2(158, 104), Vector2(150, 112), Vector2(142, 104)))
	flame.append_array(_quad(Vector2(142, 104), Vector2(126, 86), Vector2(150, 52)))
	draw_colored_polygon(flame, fill)
	var heart: PackedVector2Array = _quad(Vector2(150, 74), Vector2(162, 92), Vector2(154, 102))
	heart.append_array(_quad(Vector2(154, 102), Vector2(150, 106), Vector2(146, 102)))
	heart.append_array(_quad(Vector2(146, 102), Vector2(138, 92), Vector2(150, 74)))
	draw_colored_polygon(heart, Color("#FFF2C8"))
	draw_polyline(_quad(Vector2(60, 190), Vector2(150, 150), Vector2(248, 74)), Color(text, 0.9), 6.0, true)
	# Embers rising, drifting with the card's own clock.
	for ember: int in 4:
		var rise: float = fmod(_age * 0.25 + float(ember) * 0.27, 1.0)
		draw_circle(Vector2(104.0 + float(ember) * 38.0, 96.0 - rise * 50.0), 3.5 * (1.0 - rise), Color(text, 1.0 - rise))


func _motif_hearth(fill: Color, _text: Color) -> void:
	var arch: PackedVector2Array = PackedVector2Array([Vector2(70, 206), Vector2(70, 110)])
	arch.append_array(_quad(Vector2(70, 110), Vector2(150, 40), Vector2(230, 110)))
	arch.append(Vector2(230, 206))
	draw_colored_polygon(arch, Color("#4A3A2A"))
	var mouth: PackedVector2Array = PackedVector2Array([Vector2(100, 206), Vector2(100, 128)])
	mouth.append_array(_quad(Vector2(100, 128), Vector2(150, 82), Vector2(200, 128)))
	mouth.append(Vector2(200, 206))
	draw_colored_polygon(mouth, Color("#160E06"))
	draw_circle(Vector2(150, 176), 48.0, Color(fill, 0.25))
	var flame: PackedVector2Array = _quad(Vector2(120, 204), Vector2(116, 160), Vector2(138, 146))
	flame.append_array(_quad(Vector2(138, 146), Vector2(134, 170), Vector2(150, 176)))
	flame.append_array(_quad(Vector2(150, 176), Vector2(148, 140), Vector2(168, 124)))
	flame.append_array(_quad(Vector2(168, 124), Vector2(166, 160), Vector2(182, 170)))
	flame.append_array(_quad(Vector2(182, 170), Vector2(186, 190), Vector2(178, 204)))
	draw_colored_polygon(flame, fill)
	draw_rect(Rect2(92, 200, 116, 8), Color("#6E4B2E"))


func _motif_thrust(fill: Color, text: Color) -> void:
	_crescent(Vector2(212, 70), 34.0, text, Color(0, 0, 0, 0))
	for wave: int in 2:
		var y: float = 186.0 + float(wave) * 18.0
		var line: PackedVector2Array = PackedVector2Array()
		for step: int in 31:
			var x: float = float(step) * 10.0
			line.append(Vector2(x, y + sin(x / 40.0 * PI + _age * 1.5) * 7.0))
		draw_polyline(line, Color(fill if wave == 0 else text, 0.8 - float(wave) * 0.2), 4.0 - float(wave), true)
	draw_line(Vector2(56, 196), Vector2(214, 92), Color("#E9E2F8"), 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(214, 92), Vector2(236, 72), Vector2(222, 100)]), Color("#E9E2F8"))
	_sparkle(Vector2(236, 120), 7.0, Color("#E9E2F8"))
	_sparkle(Vector2(90, 80), 6.0, text)
	_sparkle(Vector2(150, 60), 4.0, text)


func _motif_weir(fill: Color, text: Color) -> void:
	_crescent(Vector2(150, 64), 28.0, text, Color(0, 0, 0, 0))
	draw_polyline(_quad(Vector2(58, 150), Vector2(150, 96), Vector2(242, 150)), Color(fill, 0.8), 6.0, true)
	for post: int in 7:
		draw_rect(Rect2(66.0 + float(post) * 26.0, 150, 10, 48), STONE[0])
		draw_rect(Rect2(66.0 + float(post) * 26.0, 150, 10, 6), STONE[2])
	for ripple: int in 2:
		draw_arc(Vector2(150, 210.0 + float(ripple) * 12.0), 110.0 - float(ripple) * 30.0, PI * 0.05, PI * 0.95, 24, Color(text, 0.5 - float(ripple) * 0.15), 2.0)
	_sparkle(Vector2(104, 120), 5.0, Color("#E9E2F8"))
	_sparkle(Vector2(200, 112), 6.0, Color("#E9E2F8"))


## Any card without its own picture: its Sign's glyph, big, over a blade (an Ink Blade) or a shield (an Ink Shield).
func _motif_plain(listed: ScribeCardResource, fill: Color, text: Color) -> void:
	if listed.manifestation_mode == ScribeCardResource.ManifestationMode.WARD_MANTLE:
		var shield: PackedVector2Array = PackedVector2Array([Vector2(150, 52), Vector2(206, 70), Vector2(202, 132)])
		shield.append_array(_quad(Vector2(202, 132), Vector2(194, 178), Vector2(150, 198)))
		shield.append_array(_quad(Vector2(150, 198), Vector2(106, 178), Vector2(98, 132)))
		shield.append(Vector2(94, 70))
		draw_colored_polygon(shield, Color(fill, 0.25))
		shield.append(shield[0])
		draw_polyline(shield, text, 4.0, true)
	else:
		draw_line(Vector2(84, 196), Vector2(214, 66), Color("#E9E2F8"), 7.0)
		draw_line(Vector2(96, 160), Vector2(124, 188), text, 6.0)
	_draw_glyph(Vector2(150, 124), 30.0, listed.scribe_sign, fill)
