## The opening film's recap (docs/31) for a new hero who drops in late: the film's plates as a
## page-flip in that player's own view (their split-screen cell), a set time each with its
## shot's caption, while everyone else keeps playing. The player can skip it by holding their
## own pause / menu button (PrologueDirector reads the hold); it ends on its own after the
## last page. Its pages are the timeline's recap plates, each panned the way its shot pans.
class_name PrologueRecap
extends Control

## The recap is over (skipped or not): its player is let go.
signal finished(skipped: bool)

## How long a page takes to turn into the next, inside its time.
const FLIP_S: float = 0.3

var film: CinematicFilmResource
var actor: ActorBase
var elapsed: float = 0.0
var ended: bool = false
var was_skipped: bool = false
var skip_progress: float = 0.0
## Each page's shot, in the recap's order.
var pages: Array[CinematicShotResource] = []

var _under: ColorRect
var _over: ColorRect
var _caption: PanelContainer
var _ring: SkipRing
var _plates: Dictionary[String, Texture2D] = {}
var _requested: Dictionary[String, bool] = {}


func setup(the_film: CinematicFilmResource, for_actor: ActorBase) -> void:
	film = the_film
	actor = for_actor


func _ready() -> void:
	name = "PrologueRecap"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages = film.recap_shots()
	# Every page starts loading on a worker now, so play never stalls on a plate.
	for shot: CinematicShotResource in pages:
		var path: String = shot.any_plate()
		if path != "" and not _requested.has(path) and ResourceLoader.exists(path) and ResourceLoader.load_threaded_request(path) == OK:
			_requested[path] = true
	_under = PrologueKit.make_page("PageUnder")
	add_child(_under)
	_over = PrologueKit.make_page("PageOver")
	add_child(_over)
	_caption = PrologueKit.make_caption(film)
	add_child(_caption)
	_ring = SkipRing.new()
	_ring.name = "SkipRing"
	_ring.font = CinematicCatalog.font("Alegreya Sans Bold")
	_ring.fill = film.colour(&"warm_hearth_gold", _ring.fill)
	add_child(_ring)
	_draw_now()


func _process(delta: float) -> void:
	if ended:
		return
	elapsed += delta
	if elapsed >= length():
		_end(false)
		return
	_draw_now()


## The whole recap's length: a page per plate, each `recap_seconds_per_plate`.
func length() -> float:
	return film.recap_seconds_per_plate * float(pages.size())


## The page showing now (0 first).
func page_index() -> int:
	if film.recap_seconds_per_plate <= 0.0:
		return 0
	return clampi(int(elapsed / film.recap_seconds_per_plate), 0, maxi(0, pages.size() - 1))


func caption_text() -> String:
	return (_caption.get_node(^"Words") as Label).text if _caption.visible else ""


func set_skip_progress(progress: float) -> void:
	skip_progress = clampf(progress, 0.0, 1.0)


## Its player held pause long enough: straight to the end.
func skip() -> void:
	_end(true)


## Jumps the recap's clock to `at_s` (the checks).
func seek(at_s: float) -> void:
	elapsed = maxf(elapsed, at_s)
	if elapsed >= length():
		_end(false)
	else:
		_draw_now()


func _draw_now() -> void:
	if pages.is_empty():
		_end(false)
		return
	var area: Vector2 = size if size.x >= 1.0 and size.y >= 1.0 else get_parent_area_size()
	var per: float = maxf(film.recap_seconds_per_plate, 0.001)
	var index: int = page_index()
	var into_page: float = elapsed - per * float(index)
	_show(_under, index, into_page / per, area)
	_over.visible = false
	# The last moments of a page turn it over onto the next one.
	if index + 1 < pages.size() and into_page > per - FLIP_S:
		_show(_under, index + 1, 0.0, area)
		_show(_over, index, 1.0, area)
		(_over.material as ShaderMaterial).set_shader_parameter(&"turn", (into_page - (per - FLIP_S)) / FLIP_S)
	var shot: CinematicShotResource = pages[index]
	var words: PackedStringArray = PackedStringArray()
	if film.recap_captions:
		for caption: CinematicCaptionResource in shot.captions:
			words.append(caption.text)
	var fade: float = clampf(minf(into_page, per - into_page) / PrologueKit.CAPTION_FADE_S, 0.0, 1.0)
	PrologueKit.show_caption(_caption, film, " ".join(words), fade, area)
	_ring.progress = skip_progress
	_ring.line = "Hold %s to skip" % InputComponent.binding_label(InputComponent.ACTION_OPTIONS,
		actor.device_id if is_instance_valid(actor) else InputComponent.KEYBOARD_DEVICE)
	_ring.place(area)


## Shows page `index` at `share` (0 to 1) of its own pan, without the film's effects.
func _show(page: ColorRect, index: int, share: float, area: Vector2) -> void:
	var shot: CinematicShotResource = pages[index]
	var at_s: float = lerpf(shot.start_s, shot.end_s, clampf(share, 0.0, 1.0))
	PrologueKit.frame_page(page, film, shot, _plate(shot.any_plate()), at_s, false, area)
	page.visible = true


func _exit_tree() -> void:
	for path: String in _requested.keys():
		ResourceLoader.load_threaded_get(path)
	_requested.clear()


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


func _end(skipped: bool) -> void:
	if ended:
		return
	ended = true
	was_skipped = skipped
	visible = false
	finished.emit(skipped)
	queue_free()
