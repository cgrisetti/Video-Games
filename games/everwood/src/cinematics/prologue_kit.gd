## What the opening film and its recap share (docs/31): a storybook page (a rect drawn by
## storybook_plate.gdshader), framing a page for a shot at a moment, the shot's effects, and
## the caption ribbon.
##
## Every time, colour and amount comes from the film's timeline. The few numbers here are
## what the timeline doesn't give: where things sit on the placeholder plates (the sea's
## surface on shot 4, the windmill's reach on shot 5) and how far an open-ended effect goes.
class_name PrologueKit
extends RefCounted

const PLATE_SHADER: Shader = preload("res://src/cinematics/storybook_plate.gdshader")
## The plates' shape (1920 x 1080).
const PLATE_ASPECT: float = 16.0 / 9.0
## water_rise: the sea's surface on the placeholder Un-Inking plate (a fraction of its height).
## TODO(docs/31): re-measure when the final shot 4 plate lands.
const SEA_LINE_FRAC: float = 0.555
## windmill_sail_spin on the placeholder Embershore plate: the sails' reach (plate heights), the
## tower's half width under the hub (plate heights), and the windmill's name kept still (x0, y0, x1, y1).
## TODO(docs/31): re-measure when the final shot 5 plate lands (or give the sails a layer of their own).
const SAIL_RADIUS: float = 0.14
const SAIL_TOWER_HALF: float = 0.035
const SAIL_KEEP: Vector4 = Vector4(0.155, 0.1, 0.285, 0.15)
## tint_spread: how far the colour has spread by its end (plate heights).
const TINT_REACH: float = 0.75
## mist_creep: how far in from its edge the mist has crept by its end (plate widths).
const MIST_REACH: float = 0.42
## glow_pulse: the gold's strength at the top of a breath.
const GLOW_PEAK: float = 0.35
## Captions fade in and out over this long, inside their own window.
const CAPTION_FADE_S: float = 0.25
## The caption ribbon sits this far above the bottom (a fraction of the height), at most this wide.
const CAPTION_BOTTOM_FRAC: float = 0.06
const CAPTION_MAX_WIDTH_FRAC: float = 0.9
## The ribbon's padding and corners at 1080p.
const CAPTION_PAD_X_AT_1080P: float = 34.0
const CAPTION_PAD_Y_AT_1080P: float = 12.0
const CAPTION_CORNER_AT_1080P: int = 10
## Where a caption ribbon keeps its words unbroken (its label holds them wrapped).
const WORDS_META: StringName = &"caption_words"

static var _warned: Dictionary[StringName, bool] = {}


## A blank page: a full-rect ColorRect with its own plate material.
static func make_page(page_name: String) -> ColorRect:
	var page: ColorRect = ColorRect.new()
	page.name = page_name
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = PLATE_SHADER
	page.material = material
	page.visible = false
	return page


## Frames `page` (filling a rect of `area`) on `shot`'s plate at `at_s` on the film's clock,
## its effects drawn when `with_effects`.
static func frame_page(page: ColorRect, film: CinematicFilmResource, shot: CinematicShotResource, plate: Texture2D,
		at_s: float, with_effects: bool, area: Vector2) -> void:
	var material: ShaderMaterial = page.material as ShaderMaterial
	var rect_aspect: float = area.x / area.y if area.x >= 1.0 and area.y >= 1.0 else PLATE_ASPECT
	var progress: float = shot.camera_progress(at_s)
	var zoom: float = lerpf(shot.pan_from_scale, shot.pan_to_scale, progress)
	material.set_shader_parameter(&"plate", plate)
	material.set_shader_parameter(&"plate_aspect", PLATE_ASPECT)
	material.set_shader_parameter(&"rect_aspect", rect_aspect)
	material.set_shader_parameter(&"zoom", zoom)
	material.set_shader_parameter(&"center", held_on_page(shot.pan_from_center.lerp(shot.pan_to_center, progress), zoom, rect_aspect))
	material.set_shader_parameter(&"parchment", film.colour(&"parchment", Color("#F4EFE6")))
	material.set_shader_parameter(&"ink", film.colour(&"ink", Color("#2B2420")))
	_clear_effects(material)
	if with_effects:
		for effect: CinematicEffectResource in shot.effects:
			_apply(material, effect, shot, at_s)


## The framing's centre kept where the page still covers the rect (never past the plate's edge).
static func held_on_page(center: Vector2, zoom: float, rect_aspect: float) -> Vector2:
	var window: Vector2 = Vector2(1.0, PLATE_ASPECT / rect_aspect) if rect_aspect >= PLATE_ASPECT else Vector2(rect_aspect / PLATE_ASPECT, 1.0)
	var half: Vector2 = window / maxf(zoom, 0.001) * 0.5
	return Vector2(clampf(center.x, half.x, 1.0 - half.x) if half.x < 0.5 else 0.5, clampf(center.y, half.y, 1.0 - half.y) if half.y < 0.5 else 0.5)


static func _clear_effects(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"opacity", 1.0)
	material.set_shader_parameter(&"lift", 0.0)
	material.set_shader_parameter(&"blank", 0.0)
	material.set_shader_parameter(&"glow", 0.0)
	material.set_shader_parameter(&"tint_radius", 0.0)
	material.set_shader_parameter(&"sea_rise", 0.0)
	material.set_shader_parameter(&"hush_edge", 2.0)
	material.set_shader_parameter(&"mist_edge", -1.0)
	material.set_shader_parameter(&"sail_pivot", Vector2(-10.0, -10.0))
	material.set_shader_parameter(&"dissolve", 0.0)
	material.set_shader_parameter(&"turn", 0.0)


static func _apply(material: ShaderMaterial, effect: CinematicEffectResource, shot: CinematicShotResource, at_s: float) -> void:
	var progress: float = effect.progress(at_s, shot.end_s)
	var started: bool = at_s >= effect.start_s
	match effect.kind:
		CinematicEffectResource.FADE_FROM_PARCHMENT:
			material.set_shader_parameter(&"blank", 1.0 - progress)
		CinematicEffectResource.POPUP_RISE:
			material.set_shader_parameter(&"lift", effect.offset_y_frac * (1.0 - progress))
		CinematicEffectResource.GLOW_PULSE:
			var running: bool = started and (effect.end_s < 0.0 or at_s <= effect.end_s)
			if running and effect.period_s > 0.0:
				var breath: float = 0.5 - 0.5 * cos(TAU * (at_s - effect.start_s) / effect.period_s)
				material.set_shader_parameter(&"glow", GLOW_PEAK * breath)
				material.set_shader_parameter(&"glow_color", effect.color)
		CinematicEffectResource.TINT_SPREAD:
			if started:
				material.set_shader_parameter(&"tint_radius", TINT_REACH * progress)
				material.set_shader_parameter(&"tint_origin", effect.origin)
				material.set_shader_parameter(&"tint_color", effect.color)
		CinematicEffectResource.WATER_RISE:
			material.set_shader_parameter(&"sea_line", SEA_LINE_FRAC)
			material.set_shader_parameter(&"sea_rise", effect.rise_frac * progress)
		CinematicEffectResource.GREY_DRAIN_SWEEP:
			if started:
				# The grey sweeps right to left: its edge runs from the page's right side to end_edge_x_frac.
				material.set_shader_parameter(&"hush_edge", lerpf(1.0, effect.end_edge_x_frac, progress))
				material.set_shader_parameter(&"hush_color", effect.color if effect.has_color() else Color("#6E7880"))
		CinematicEffectResource.WINDMILL_SAIL_SPIN:
			material.set_shader_parameter(&"sail_pivot", effect.origin)
			material.set_shader_parameter(&"sail_angle", deg_to_rad(effect.deg_per_s * maxf(0.0, at_s - shot.start_s)))
			material.set_shader_parameter(&"sail_radius", SAIL_RADIUS)
			material.set_shader_parameter(&"sail_tower_half", SAIL_TOWER_HALF)
			material.set_shader_parameter(&"sail_keep", SAIL_KEEP)
		CinematicEffectResource.MIST_CREEP:
			if started:
				material.set_shader_parameter(&"mist_edge", MIST_REACH * progress)
				material.set_shader_parameter(&"mist_color", effect.color if effect.has_color() else Color("#6E7880"))
		CinematicEffectResource.TITLE_CARD, CinematicEffectResource.CHIME_POST_RIBBON:
			pass # Drawn over the live world by PrologueFilm, not on a page.
		_:
			if not _warned.has(effect.kind):
				_warned[effect.kind] = true
				push_warning("PrologueKit: the timeline names an effect this film can't draw yet: '%s'" % effect.kind)


# --- Captions ------------------------------------------------------------------------------

## The caption ribbon: parchment behind ink, in the timeline's caption style (hidden until shown).
static func make_caption(film: CinematicFilmResource) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Caption"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = film.caption_ribbon_color
	panel.add_theme_stylebox_override(&"panel", back)
	var label: Label = Label.new()
	label.name = "Words"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# The ribbon wraps its own words (wrap_words): a Label's autowrap measures before it has a width.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override(&"font", CinematicCatalog.font(film.caption_font))
	label.add_theme_color_override(&"font_color", film.caption_color)
	panel.add_child(label)
	panel.visible = false
	return panel


## Shows `text` on the ribbon at `alpha`, sized for a rect of `area` (its height sets the 1080p scale).
static func show_caption(panel: PanelContainer, film: CinematicFilmResource, text: String, alpha: float, area: Vector2) -> void:
	var label: Label = panel.get_node(^"Words") as Label
	if text == "" or alpha <= 0.0:
		panel.visible = false
		return
	var ui_scale: float = area.y / 1080.0
	var font_size: int = maxi(8, roundi(float(film.caption_size_px_at_1080p) * ui_scale))
	var pad: Vector2 = Vector2(CAPTION_PAD_X_AT_1080P, CAPTION_PAD_Y_AT_1080P) * ui_scale
	var back: StyleBoxFlat = panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	back.content_margin_left = pad.x
	back.content_margin_right = pad.x
	back.content_margin_top = pad.y
	back.content_margin_bottom = pad.y
	back.set_corner_radius_all(maxi(2, roundi(CAPTION_CORNER_AT_1080P * ui_scale)))
	label.add_theme_font_size_override(&"font_size", font_size)
	var font: Font = label.get_theme_font(&"font")
	var wrapped: String = wrap_words(font, text, font_size, area.x * CAPTION_MAX_WIDTH_FRAC - pad.x * 2.0)
	if label.text != wrapped:
		label.text = wrapped
	panel.set_meta(WORDS_META, text)
	panel.reset_size()
	panel.position = Vector2((area.x - panel.size.x) * 0.5, area.y * (1.0 - CAPTION_BOTTOM_FRAC) - panel.size.y)
	panel.modulate = Color(1.0, 1.0, 1.0, alpha)
	panel.visible = true


## The words on a caption ribbon now, as the timeline wrote them ("" when it's hidden).
static func caption_words(panel: PanelContainer) -> String:
	return str(panel.get_meta(WORDS_META, "")) if panel.visible else ""


## `text` broken into lines no wider than `width` at `font_size` (a word wider than that keeps its own line).
static func wrap_words(font: Font, text: String, font_size: int, width: float) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var line: String = ""
	for word: String in text.split(" ", false):
		var longer: String = word if line == "" else line + " " + word
		if line != "" and font.get_string_size(longer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width:
			lines.append(line)
			line = word
		else:
			line = longer
	if line != "":
		lines.append(line)
	return "\n".join(lines)


## A caption's fade at `at_s` inside its window (0 outside it).
static func caption_alpha(caption: CinematicCaptionResource, at_s: float) -> float:
	if caption == null or not caption.covers(at_s):
		return 0.0
	return clampf(minf(at_s - caption.start_s, caption.end_s - at_s) / CAPTION_FADE_S, 0.0, 1.0)
