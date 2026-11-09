## The opening film (docs/31): thirty seconds played full screen over the loading world, then
## handed straight over to the player's own camera, with no cut, load screen or camera pop.
##
##   Shots 1-5  a 2D storybook layer: each shot's plate, panned and zoomed and drawn with its
##              effects (PrologueKit, storybook_plate.gdshader), crossfading or turning the
##              page into the next, while the world streams in underneath.
##   Shot 6     the page dissolves into the live world: a Camera3D in the lead player's own
##              view starts at the timeline's offset above and behind their camera rig and
##              eases onto the rig's exact pose, read every frame, never typed in; at the
##              dive's end the rig's camera becomes current. The title card inks on and fades,
##              the Chime-Post ribbon unfurls, and control comes back at control_unlock_s.
##
## Captions are always on. Each audio cue is posted at its time (cue_fired); nothing plays.
## TODO(docs/31): Master Alf-Wright waving his lantern at the gate in shot 6 (his NPC has no wave clip yet).
## The lead's view is spotlit (alone, full screen) until the film ends, when split-screen
## starts. PrologueDirector decides who sees the film, holds the players and runs the skip;
## this layer only draws it, on the film's own clock (`elapsed`).
class_name PrologueFilm
extends CanvasLayer

## A cue's time has come (PrologueDirector posts it to the score).
signal cue_fired(cue: CinematicCueResource)
## The Chime-Post ribbon's time has come: show `text` under `heading` for `seconds`.
signal ribbon_due(heading: String, text: String, seconds: float)
## The rig's camera is current: the film is now the player's own view.
signal handed_off
## The film is over (skipped or not); control comes back now.
signal finished(skipped: bool)

## Over the split-screen views and HUDs, under the instance fade (100) and the Ebb (60).
const LAYER: int = 50
## The streamer finishes its last jobs this long before the page starts to dissolve (under the still page).
const SETTLE_LEAD_S: float = 0.5
## The title card's two lines at 1080p (EVERWOOD, The Caldera Isles).
const TITLE_SIZES_AT_1080P: Array[int] = [112, 46]
## The film's clock moves at most this far in one frame, so a hitch slows it rather than skipping a beat.
const MAX_STEP_S: float = 0.1
## The title's top and its parchment halo at 1080p.
const TITLE_TOP_FRAC: float = 0.16
const TITLE_HALO_AT_1080P: int = 14

var film: CinematicFilmResource
## Seconds into the film.
var elapsed: float = 0.0
## A client playing the host's film (in step with the host; only the host can skip).
var follower: bool = false
## The local player whose camera rig the film hands over to.
var lead: ActorBase
var rig: PlayerCamera
var grid: SplitScreenViewportGrid
## The level's "finish streaming now": returns how many streaming jobs were still waiting.
var settle: Callable = Callable()
var dive_camera: Camera3D
var is_handed_off: bool = false
var ended: bool = false
var was_skipped: bool = false
## The dive's last transform and the rig's at the hand-off (the checks compare them), and
## the field-of-view gap there.
var handoff_dive: Transform3D = Transform3D.IDENTITY
var handoff_rig: Transform3D = Transform3D.IDENTITY
var handoff_fov_gap: float = 0.0
## Whether the zone has been settled before the dissolve, and how many jobs were still waiting then.
var settled: bool = false
var pending_at_settle: int = -1
## Every cue posted so far, in order.
var cues_fired: Array[StringName] = []
var ribbon_sent: bool = false
## The skip hold's progress (0 to 1) and the line beside the ring.
var skip_progress: float = 0.0

var _live: CinematicShotResource
var _title_effect: CinematicEffectResource
var _ribbon_effect: CinematicEffectResource
var _dissolve_start: float = 0.0
var _cues: Array[CinematicCueResource] = []
var _next_cue: int = 0
var _root: Control
var _bottom: ColorRect
var _top: ColorRect
var _caption: PanelContainer
var _title_box: VBoxContainer
var _title_lines: Array[Label] = []
var _ring: SkipRing
var _hint_text: String = ""
var _hint_left: float = 0.0
var _plates: Dictionary[String, Texture2D] = {}
var _requested: Dictionary[String, bool] = {}


## `start_at`: where on the film's clock to start (a client joining the host's film part-way).
func setup(the_film: CinematicFilmResource, lead_actor: ActorBase, view_grid: SplitScreenViewportGrid, as_follower: bool,
		start_at: float = 0.0, settle_zone: Callable = Callable()) -> void:
	film = the_film
	lead = lead_actor
	grid = view_grid
	follower = as_follower
	elapsed = maxf(0.0, start_at)
	settle = settle_zone


func _ready() -> void:
	name = "PrologueFilm"
	layer = LAYER
	process_priority = 10
	_live = film.live_shot()
	_title_effect = film.effect(CinematicEffectResource.TITLE_CARD)
	_ribbon_effect = film.effect(CinematicEffectResource.CHIME_POST_RIBBON)
	_dissolve_start = _live.start_s if _live != null else film.control_unlock_s
	for shot: CinematicShotResource in film.shots:
		if film.next_shot(shot) == _live and _live != null and shot.transition_kind == CinematicShotResource.PAGE_DISSOLVE_TO_3D:
			_dissolve_start = shot.transition_window().x
	_cues = film.all_cues()
	# A film joined part-way never posts the cues it missed.
	while _next_cue < _cues.size() and _cues[_next_cue].at_s < elapsed:
		_next_cue += 1
	_build()
	_request_plates()
	_take_the_view()
	_advance()


func _exit_tree() -> void:
	# A plate still loading on a worker is collected (a pending load leaks at exit).
	for path: String in _requested.keys():
		ResourceLoader.load_threaded_get(path)
	_requested.clear()
	_give_back_the_view()


func _process(delta: float) -> void:
	if ended:
		return
	_hint_left = maxf(0.0, _hint_left - delta)
	elapsed += minf(delta, MAX_STEP_S)
	_advance()


## Jumps the film's clock to `at_s` (the checks), posting the cues on the way.
func seek(at_s: float) -> void:
	if ended:
		return
	elapsed = maxf(elapsed, at_s)
	_advance()


## Skip (the host's 1.5 s hold, or the host's word over the network): straight to the end state.
func skip_to_end() -> void:
	if ended:
		return
	elapsed = maxf(elapsed, film.control_unlock_s)
	_end(true)


func set_skip_progress(progress: float) -> void:
	skip_progress = clampf(progress, 0.0, 1.0)


## Shows `text` beside the ring for `seconds` ("Host can skip" when someone else holds pause).
func flash_hint(text: String, seconds: float = 2.5) -> void:
	_hint_text = text
	_hint_left = seconds


## The line beside the skip ring now.
func skip_line() -> String:
	if _hint_left > 0.0:
		return _hint_text
	if follower:
		return film.skip_non_host_hint
	var device: int = lead.device_id if is_instance_valid(lead) else InputComponent.KEYBOARD_DEVICE
	return "Hold %s to skip" % InputComponent.binding_label(InputComponent.ACTION_OPTIONS, device)


## The caption on screen now ("" when none).
func caption_text() -> String:
	return (_caption.get_node(^"Words") as Label).text if _caption.visible else ""


## Whether the title card shows now, and the share of it inked on.
func title_shown() -> bool:
	return _title_box.visible


func title_inked() -> float:
	return _title_lines[0].visible_ratio if not _title_lines.is_empty() else 0.0


## Whether a storybook page still covers (part of) the screen.
func page_shown() -> bool:
	return _bottom.visible or _top.visible


# --- Building --------------------------------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.name = "Film"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_bottom = PrologueKit.make_page("PageUnder")
	_root.add_child(_bottom)
	_top = PrologueKit.make_page("PageOver")
	_root.add_child(_top)
	_title_box = VBoxContainer.new()
	_title_box.name = "TitleCard"
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_title_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_box.visible = false
	_root.add_child(_title_box)
	if _title_effect != null:
		for index: int in _title_effect.lines.size():
			var line: Label = Label.new()
			line.text = _title_effect.lines[index]
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var font_name: String = _title_effect.fonts[index] if index < _title_effect.fonts.size() else film.caption_font
			line.add_theme_font_override(&"font", CinematicCatalog.font(font_name))
			line.add_theme_color_override(&"font_color", film.colour(&"ink", Color("#2B2420")))
			var halo: Color = film.colour(&"parchment", Color("#F4EFE6"))
			halo.a = 0.8
			line.add_theme_color_override(&"font_outline_color", halo)
			_title_box.add_child(line)
			_title_lines.append(line)
	_caption = PrologueKit.make_caption(film)
	_root.add_child(_caption)
	_ring = SkipRing.new()
	_ring.name = "SkipRing"
	_ring.font = CinematicCatalog.font("Alegreya Sans Bold")
	_ring.fill = film.colour(&"warm_hearth_gold", _ring.fill)
	_root.add_child(_ring)


## Every plate starts loading on a worker now; each is collected the first time it's drawn.
func _request_plates() -> void:
	for shot: CinematicShotResource in film.shots:
		var path: String = shot.plate_path
		if path == "" or _requested.has(path) or not ResourceLoader.exists(path):
			continue
		if ResourceLoader.load_threaded_request(path) == OK:
			_requested[path] = true


func _plate(path: String) -> Texture2D:
	if _plates.has(path):
		return _plates[path]
	var texture: Texture2D = null
	if _requested.has(path):
		_requested.erase(path)
		texture = ResourceLoader.load_threaded_get(path) as Texture2D
	elif ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_plates[path] = texture
	return texture


## The lead's view alone, full screen; its HUD waits; the dive camera current in it.
func _take_the_view() -> void:
	if not is_instance_valid(lead) or grid == null:
		return
	grid.set_spotlight(lead.player_id)
	var overlay: Control = grid.overlay_for(lead.player_id)
	if overlay != null:
		overlay.visible = false
	rig = grid.camera_for(lead.player_id)
	var viewport: SubViewport = grid.viewport_for(lead.player_id)
	if rig == null or viewport == null or _live == null:
		return
	dive_camera = Camera3D.new()
	dive_camera.name = "PrologueDiveCamera"
	dive_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	viewport.add_child(dive_camera)
	_match_lens()
	dive_camera.current = true
	_place_dive_camera()


func _give_back_the_view() -> void:
	if is_instance_valid(dive_camera):
		dive_camera.queue_free()
	dive_camera = null
	if is_instance_valid(rig) and not rig.current:
		rig.make_current()
	if grid != null and is_instance_valid(grid) and is_instance_valid(lead):
		if grid.spotlight == lead.player_id:
			grid.set_spotlight(&"")
		var overlay: Control = grid.overlay_for(lead.player_id)
		if overlay != null:
			overlay.visible = true


# --- Playing -----------------------------------------------------------------------------------

func _advance() -> void:
	_post_cues()
	_settle_zone()
	_draw_pages()
	_draw_caption()
	_draw_title()
	_draw_ring()
	if not is_handed_off:
		_place_dive_camera()
		if _live != null and elapsed >= _live.dive_end_s:
			_hand_off()
	if not ribbon_sent and _ribbon_effect != null and elapsed >= _ribbon_effect.start_s:
		_send_ribbon()
	if elapsed >= film.control_unlock_s:
		_end(false)


func _post_cues() -> void:
	while _next_cue < _cues.size() and _cues[_next_cue].at_s <= elapsed:
		var cue: CinematicCueResource = _cues[_next_cue]
		_next_cue += 1
		cues_fired.append(cue.cue_id)
		cue_fired.emit(cue)


## Just before the page starts to dissolve, whatever the streamer still has on its way is
## finished (under the still page), so the dive never meets a hole or a load screen.
func _settle_zone() -> void:
	if settled or elapsed < _dissolve_start - SETTLE_LEAD_S:
		return
	settled = true
	if settle.is_valid():
		pending_at_settle = int(settle.call())


## The pages on screen: one shot's, or two through a hand-over (a crossfade, a page turn,
## the dissolve into the live world); none once the live shot has the screen.
func _draw_pages() -> void:
	var area: Vector2 = _area()
	_bottom.visible = false
	_top.visible = false
	for shot: CinematicShotResource in film.shots:
		var window: Vector2 = shot.transition_window()
		if shot.transition_kind == &"" or elapsed < window.x or elapsed >= window.y:
			continue
		var into: CinematicShotResource = film.next_shot(shot)
		var share: float = clampf((elapsed - window.x) / maxf(window.y - window.x, 0.001), 0.0, 1.0)
		match shot.transition_kind:
			CinematicShotResource.CROSSFADE:
				_show_page(_bottom, shot, area)
				if into != null and not into.is_live():
					_show_page(_top, into, area)
					(_top.material as ShaderMaterial).set_shader_parameter(&"opacity", share)
			CinematicShotResource.PAGE_TURN:
				if into != null and not into.is_live():
					_show_page(_bottom, into, area)
				_show_page(_top, shot, area)
				(_top.material as ShaderMaterial).set_shader_parameter(&"turn", share)
			_:
				# The dissolve (and any hand-over this film doesn't know): the page wears away.
				_show_page(_top, shot, area)
				(_top.material as ShaderMaterial).set_shader_parameter(&"dissolve", share)
		return
	var now: CinematicShotResource = film.shot_at(elapsed)
	if now != null and not now.is_live() and elapsed < film.control_unlock_s:
		_show_page(_bottom, now, area)


func _show_page(page: ColorRect, shot: CinematicShotResource, area: Vector2) -> void:
	PrologueKit.frame_page(page, film, shot, _plate(shot.plate_path), elapsed, true, area)
	page.visible = true


func _draw_caption() -> void:
	var caption: CinematicCaptionResource = film.caption_at(elapsed)
	PrologueKit.show_caption(_caption, film, caption.text if caption != null else "", PrologueKit.caption_alpha(caption, elapsed), _area())


func _draw_title() -> void:
	if _title_effect == null or _title_lines.is_empty():
		_title_box.visible = false
		return
	var inked: float = clampf((elapsed - _title_effect.ink_on_start_s) / maxf(_title_effect.ink_on_duration_s, 0.001), 0.0, 1.0)
	var fade_span: float = maxf(_title_effect.fade_out_end_s - _title_effect.fade_out_start_s, 0.001)
	var left: float = 1.0 - clampf((elapsed - _title_effect.fade_out_start_s) / fade_span, 0.0, 1.0)
	_title_box.visible = elapsed >= _title_effect.ink_on_start_s and left > 0.0
	if not _title_box.visible:
		return
	var ui_scale: float = _area().y / 1080.0
	_title_box.offset_top = _area().y * TITLE_TOP_FRAC
	for index: int in _title_lines.size():
		var line: Label = _title_lines[index]
		var at_1080: int = TITLE_SIZES_AT_1080P[mini(index, TITLE_SIZES_AT_1080P.size() - 1)]
		line.add_theme_font_size_override(&"font_size", maxi(8, roundi(at_1080 * ui_scale)))
		line.add_theme_constant_override(&"outline_size", maxi(2, roundi(TITLE_HALO_AT_1080P * ui_scale)))
		# It inks on letter by letter, then fades.
		line.visible_ratio = inked
		line.modulate.a = left


func _draw_ring() -> void:
	_ring.visible = not is_handed_off
	if not _ring.visible:
		return
	_ring.progress = 0.0 if follower else skip_progress
	_ring.line = skip_line()
	_ring.place(_area())


# --- The dive and the hand-off ----------------------------------------------------------

## The dive camera's pose now: the timeline's start offset in the rig's frame (x right, y up,
## z back, levelled to the rig's heading) eased onto the rig's live pose, looking at what the
## rig looks at, its turn settling onto the rig's own as it lands.
func _place_dive_camera() -> void:
	if not is_instance_valid(dive_camera) or not is_instance_valid(rig) or _live == null:
		return
	_match_lens()
	var target: Transform3D = rig.global_transform
	var landed: float = _live.dive_progress(elapsed)
	var start: Vector3 = dive_start_position(target, _live.dive_start_offset)
	var at: Vector3 = start.lerp(target.origin, landed)
	var look: Vector3 = rig.look_point()
	var facing: Quaternion = target.basis.get_rotation_quaternion()
	if (look - at).length() > 0.05:
		facing = Basis.looking_at(look - at, Vector3.UP).get_rotation_quaternion()
	var turn: Quaternion = facing.slerp(target.basis.get_rotation_quaternion(), pow(landed, 3.0))
	dive_camera.global_transform = Transform3D(Basis(turn), at)


## Where the dive starts for a rig at `target`: `offset` metres right, up and back of it, in its
## heading's level frame.
static func dive_start_position(target: Transform3D, offset: Vector3) -> Vector3:
	var forward: Vector3 = -target.basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	return target.origin + right * offset.x + Vector3.UP * offset.y - forward * offset.z


func _match_lens() -> void:
	if not is_instance_valid(dive_camera) or not is_instance_valid(rig):
		return
	dive_camera.fov = rig.fov
	dive_camera.near = rig.near
	dive_camera.far = rig.far
	dive_camera.cull_mask = rig.cull_mask
	dive_camera.keep_aspect = rig.keep_aspect
	dive_camera.projection = rig.projection
	dive_camera.h_offset = rig.h_offset
	dive_camera.v_offset = rig.v_offset
	dive_camera.environment = rig.environment
	dive_camera.attributes = rig.attributes


## The dive has landed: its last pose is recorded beside the rig's, and the rig's camera is current.
func _hand_off() -> void:
	if is_handed_off:
		return
	is_handed_off = true
	if is_instance_valid(dive_camera) and is_instance_valid(rig):
		_place_dive_camera()
		handoff_dive = dive_camera.global_transform
		handoff_rig = rig.global_transform
		handoff_fov_gap = absf(dive_camera.fov - rig.fov)
		rig.make_current()
		dive_camera.queue_free()
		dive_camera = null
	if grid != null and is_instance_valid(lead):
		var overlay: Control = grid.overlay_for(lead.player_id)
		if overlay != null:
			overlay.visible = true
	handed_off.emit()


## How far the dive's last frame was from the rig at the hand-off: metres, and degrees.
func handoff_error() -> Vector2:
	var metres: float = handoff_dive.origin.distance_to(handoff_rig.origin)
	var turn: Quaternion = handoff_dive.basis.get_rotation_quaternion().inverse() * handoff_rig.basis.get_rotation_quaternion()
	return Vector2(metres, rad_to_deg(turn.normalized().get_angle()))


func _send_ribbon() -> void:
	ribbon_sent = true
	if _ribbon_effect == null:
		return
	# It stays through the rest of the film and then `persist_play_s` of play (or until the gate).
	var seconds: float = maxf(0.0, film.control_unlock_s - elapsed) + _ribbon_effect.persist_play_s
	ribbon_due.emit(film.spawn_zone_name, _ribbon_effect.text, seconds)


func _end(skipped: bool) -> void:
	if ended:
		return
	ended = true
	was_skipped = skipped
	_hand_off()
	if not ribbon_sent:
		_send_ribbon()
	_root.visible = false
	_give_back_the_view()
	finished.emit(skipped)
	queue_free()


func _area() -> Vector2:
	var area: Vector2 = _root.size if _root != null else Vector2.ZERO
	if area.x < 1.0 or area.y < 1.0:
		area = get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1600.0, 900.0)
	return area
