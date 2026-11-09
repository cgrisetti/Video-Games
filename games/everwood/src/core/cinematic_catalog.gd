## Every film by id (docs/31; Gate 4's schema-first registry): today the opening prologue.
## A film is a CinematicFilmResource built from its timeline JSON, the source of truth for
## every time, caption, camera move, effect and audio cue, so no number is copied into code.
## The JSON's art paths ("art/storyboards/shot01_ring.png") start from the film's folder.
##
## Static, built on first use, like AudioCatalog. Also reads a film's .srt (the checks hold
## its words to the JSON's) and hands out the film's fonts (IM FELL English and Alegreya
## Sans, SIL OFL, in res://assets/fonts/) by the names the timeline uses.
class_name CinematicCatalog
extends RefCounted

## The opening film ("prologue"): 30 seconds from the ring of isles to the player's own camera.
const PROLOGUE: StringName = &"opening_cinematic_prologue"
const PROLOGUE_FOLDER: String = "res://assets/cinematics/prologue/"
const PROLOGUE_TIMELINE: String = PROLOGUE_FOLDER + "data/opening_cinematic_timeline.json"
const PROLOGUE_CAPTIONS: String = PROLOGUE_FOLDER + "data/opening_cinematic.en.srt"
## Each film's timeline JSON...
const TIMELINES: Dictionary[StringName, String] = {PROLOGUE: PROLOGUE_TIMELINE}
## ...and the folder its art paths start from.
const FOLDERS: Dictionary[StringName, String] = {PROLOGUE: PROLOGUE_FOLDER}
## The fonts by the names the timeline uses.
const FONT_FILES: Dictionary[String, String] = {
	"IM FELL English": "res://assets/fonts/IMFeENrm28P.ttf",
	"IM FELL English Italic": "res://assets/fonts/IMFeENit28P.ttf",
	"IM FELL English SC": "res://assets/fonts/IMFeENsc28P.ttf",
	"Alegreya Sans": "res://assets/fonts/AlegreyaSans-Regular.ttf",
	"Alegreya Sans Bold": "res://assets/fonts/AlegreyaSans-Bold.ttf",
}
## "... or 20 s of play": the seconds a persist_until line names.
const PLAY_SECONDS_PATTERN: String = "([0-9]+(?:\\.[0-9]+)?)\\s*s of play"

static var _films: Dictionary[StringName, CinematicFilmResource] = {}
static var _fonts: Dictionary[String, Font] = {}
static var _built: bool = false


static func film(id: StringName) -> CinematicFilmResource:
	_ensure()
	return _films.get(id, null)


static func films() -> Array[CinematicFilmResource]:
	_ensure()
	var list: Array[CinematicFilmResource] = []
	list.assign(_films.values())
	return list


static func register(found: CinematicFilmResource) -> void:
	if found != null and found.film_id != &"":
		_films[found.film_id] = found


static func _ensure() -> void:
	if _built:
		return
	_built = true
	for id: StringName in TIMELINES:
		var built: CinematicFilmResource = load_timeline(TIMELINES[id], FOLDERS.get(id, ""))
		if built == null:
			push_warning("CinematicCatalog: couldn't read %s" % TIMELINES[id])
			continue
		if built.film_id != id:
			push_warning("CinematicCatalog: %s calls itself '%s', registered as '%s'" % [TIMELINES[id], built.film_id, id])
			built.film_id = id
		register(built)


# --- Reading a timeline ------------------------------------------------------------------

## Reads a timeline JSON file into a film (null if it can't be read).
static func load_timeline(path: String, folder: String) -> CinematicFilmResource:
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return null
	return from_dictionary(parsed as Dictionary, folder)


## Builds a film from a timeline's parsed JSON. `folder` is where its art paths start.
static func from_dictionary(data: Dictionary, folder: String) -> CinematicFilmResource:
	var made: CinematicFilmResource = CinematicFilmResource.new()
	made.film_id = StringName(str(data.get("id", "")))
	made.version = int(data.get("version", 0))
	made.duration_s = float(data.get("duration_s", 0.0))
	made.resolution_ref = _vec2i(data.get("resolution_ref", []), Vector2i(1920, 1080))
	made.narrator = str(data.get("narrator", ""))
	made.source_folder = folder
	var style: Dictionary = data.get("caption_style", {}) as Dictionary
	made.caption_font = str(style.get("font", ""))
	made.caption_size_px_at_1080p = int(style.get("size_px_at_1080p", 0))
	made.caption_color = _colour(style.get("color", ""), Color.BLACK)
	var ribbon: Color = _colour(style.get("ribbon_color", ""), Color.WHITE)
	ribbon.a = float(style.get("ribbon_opacity", 1.0))
	made.caption_ribbon_color = ribbon
	made.caption_position = StringName(str(style.get("position", "")))
	made.captions_always_on = bool(style.get("always_on", true))
	var palette: Dictionary = data.get("palette", {}) as Dictionary
	for colour_name: Variant in palette:
		made.palette[StringName(str(colour_name))] = _colour(palette[colour_name], Color.WHITE)
	for raw: Variant in data.get("shots", []) as Array:
		if raw is Dictionary:
			made.shots.append(_shot(raw as Dictionary, folder))
	made.shots.sort_custom(func(a: CinematicShotResource, b: CinematicShotResource) -> bool: return a.start_s < b.start_s)
	made.control_unlock_s = float(data.get("control_unlock_s", made.duration_s))
	var skip: Dictionary = data.get("skip", {}) as Dictionary
	made.skip_who = StringName(str(skip.get("who", "")))
	made.skip_local_host = StringName(str(skip.get("local_host", "")))
	made.skip_online_host = StringName(str(skip.get("online_host", "")))
	made.skip_input = str(skip.get("input", ""))
	made.skip_hold_s = float(skip.get("hold_s", 0.0))
	made.skip_non_host_hint = str(skip.get("non_host_hint", ""))
	made.skip_result = str(skip.get("on_skip", ""))
	var recap: Dictionary = data.get("recap", {}) as Dictionary
	made.recap_for = str(recap.get("for", ""))
	made.recap_plates = PackedStringArray(recap.get("plates", []) as Array)
	made.recap_seconds_per_plate = float(recap.get("seconds_per_plate", 0.0))
	made.recap_captions = bool(recap.get("captions", true))
	made.recap_skippable_by = str(recap.get("skippable_by", ""))
	made.recap_scope = str(recap.get("scope", ""))
	var spawn: Dictionary = data.get("spawn", {}) as Dictionary
	made.spawn_zone_name = str(spawn.get("display_zone_name", ""))
	made.spawn_sub_zone = str(spawn.get("sub_zone", ""))
	made.spawn_face_toward = StringName(str(spawn.get("face_toward", "")))
	made.spawn_proposed_m = _vec3(spawn.get("proposed_position_local_m", []))
	made.orchard_gate_proposed_m = _vec3(spawn.get("orchard_gate_proposed_local_m", []))
	made.spawn_framing_goal = str(spawn.get("framing_goal", ""))
	var rig: Dictionary = data.get("camera_rig_constants_ref", {}) as Dictionary
	made.rig_pitch_deg = float(rig.get("default_pitch_deg", 0.0))
	made.rig_height_m = float(rig.get("default_height_m", 0.0))
	made.rig_boom_m = float(rig.get("boom_m", 0.0))
	return made


static func _shot(data: Dictionary, folder: String) -> CinematicShotResource:
	var shot: CinematicShotResource = CinematicShotResource.new()
	shot.index = int(data.get("index", 0))
	shot.shot_id = StringName(str(data.get("id", "")))
	shot.title = str(data.get("title", ""))
	shot.start_s = float(data.get("start_s", 0.0))
	shot.end_s = float(data.get("end_s", 0.0))
	shot.layer = StringName(str(data.get("layer", CinematicShotResource.LAYER_STORYBOOK)))
	if data.has("plate"):
		shot.plate_path = folder + str(data["plate"])
	if data.has("plate_reference"):
		shot.reference_plate_path = folder + str(data["plate_reference"])
	var camera: Dictionary = data.get("camera", {}) as Dictionary
	shot.camera_kind = StringName(str(camera.get("type", CinematicShotResource.CAMERA_PAN_ZOOM)))
	shot.camera_ease = StringName(str(camera.get("ease", CinematicFilmResource.EASE_LINEAR)))
	var from: Dictionary = camera.get("from", {}) as Dictionary
	var to: Dictionary = camera.get("to", {}) as Dictionary
	shot.pan_from_scale = float(from.get("scale", 1.0))
	shot.pan_from_center = _vec2(from.get("center", []), Vector2(0.5, 0.5))
	shot.pan_to_scale = float(to.get("scale", shot.pan_from_scale))
	shot.pan_to_center = _vec2(to.get("center", []), shot.pan_from_center)
	shot.dive_start_s = float(camera.get("start_s", shot.start_s))
	shot.dive_end_s = float(camera.get("end_s", shot.end_s))
	shot.dive_start_offset = _vec3(camera.get("start_offset_from_rig_m", []), Vector3.ZERO)
	shot.dive_offset_space = str(camera.get("start_offset_space", ""))
	var tolerance: Dictionary = camera.get("handoff_tolerance", {}) as Dictionary
	shot.handoff_position_m = float(tolerance.get("position_m", shot.handoff_position_m))
	shot.handoff_angle_deg = float(tolerance.get("angle_deg", shot.handoff_angle_deg))
	var transition: Dictionary = data.get("transition_out", {}) as Dictionary
	shot.transition_kind = StringName(str(transition.get("type", "")))
	shot.transition_s = float(transition.get("duration_s", 0.0))
	for raw: Variant in data.get("effects", []) as Array:
		if raw is Dictionary:
			shot.effects.append(_effect(raw as Dictionary))
	for raw: Variant in data.get("captions", []) as Array:
		if raw is Dictionary:
			var caption: Dictionary = raw as Dictionary
			shot.captions.append(CinematicCaptionResource.make(float(caption.get("start_s", 0.0)), float(caption.get("end_s", 0.0)),
				str(caption.get("text", ""))))
	for raw: Variant in data.get("cues", []) as Array:
		if raw is Dictionary:
			var cue: Dictionary = raw as Dictionary
			shot.cues.append(CinematicCueResource.make(StringName(str(cue.get("id", ""))), float(cue.get("t_s", 0.0))))
	return shot


static func _effect(data: Dictionary) -> CinematicEffectResource:
	var made: CinematicEffectResource = CinematicEffectResource.new()
	made.kind = StringName(str(data.get("type", "")))
	made.start_s = float(data.get("start_s", data.get("ink_on_start_s", 0.0)))
	made.end_s = float(data.get("end_s", -1.0))
	made.color = _colour(data.get("color", ""), Color(0.0, 0.0, 0.0, 0.0))
	made.ease_curve = StringName(str(data.get("ease", CinematicFilmResource.EASE_LINEAR)))
	made.origin = _vec2(data.get("origin", data.get("pivot_frac", [])), Vector2(0.5, 0.5))
	made.offset_y_frac = float(data.get("offset_y_frac", 0.0))
	made.period_s = float(data.get("period_s", 0.0))
	made.rise_frac = float(data.get("rise_frac", 0.0))
	made.direction = StringName(str(data.get("direction", data.get("from", ""))))
	made.end_edge_x_frac = float(data.get("end_edge_x_frac", 0.0))
	made.deg_per_s = float(data.get("deg_per_s", 0.0))
	made.lines = PackedStringArray(data.get("lines", []) as Array)
	made.fonts = PackedStringArray(data.get("font", []) as Array) if data.get("font", null) is Array else PackedStringArray()
	made.ink_on_start_s = float(data.get("ink_on_start_s", 0.0))
	made.ink_on_duration_s = float(data.get("ink_on_duration_s", 0.0))
	made.fade_out_start_s = float(data.get("fade_out_start_s", 0.0))
	made.fade_out_end_s = float(data.get("fade_out_end_s", 0.0))
	made.text = str(data.get("text", ""))
	made.persist_until = str(data.get("persist_until", ""))
	made.persist_play_s = play_seconds(made.persist_until)
	made.note = str(data.get("note", ""))
	if made.kind == CinematicEffectResource.TITLE_CARD:
		made.end_s = made.fade_out_end_s
	return made


## The seconds of play a persist_until line names ("player reaches OrchardGate or 20 s of play" -> 20; 0 when none).
static func play_seconds(line: String) -> float:
	var pattern: RegEx = RegEx.create_from_string(PLAY_SECONDS_PATTERN)
	var found: RegExMatch = pattern.search(line)
	return found.get_string(1).to_float() if found != null else 0.0


# --- Reading captions (.srt) -------------------------------------------------------------

## A SubRip file's captions, in order (empty if it can't be read).
static func read_srt(path: String) -> Array[CinematicCaptionResource]:
	var list: Array[CinematicCaptionResource] = []
	if not FileAccess.file_exists(path):
		return list
	var text: String = FileAccess.get_file_as_string(path).replace("\r\n", "\n").replace("\r", "\n")
	for block: String in text.split("\n\n", false):
		var rows: PackedStringArray = block.strip_edges().split("\n")
		var timing: int = -1
		for index: int in rows.size():
			if rows[index].contains("-->"):
				timing = index
				break
		if timing < 0:
			continue
		var ends: PackedStringArray = rows[timing].split("-->")
		var words: PackedStringArray = rows.slice(timing + 1)
		list.append(CinematicCaptionResource.make(srt_seconds(ends[0]), srt_seconds(ends[1]), "\n".join(words).strip_edges()))
	return list


## "00:00:04,700" -> 4.7.
static func srt_seconds(stamp: String) -> float:
	var parts: PackedStringArray = stamp.strip_edges().replace(",", ".").split(":")
	if parts.size() != 3:
		return 0.0
	return parts[0].to_float() * 3600.0 + parts[1].to_float() * 60.0 + parts[2].to_float()


# --- Fonts and plates --------------------------------------------------------------------

## A font by the timeline's name for it (a serif system font when it has no file here).
static func font(font_name: String) -> Font:
	if _fonts.has(font_name):
		return _fonts[font_name]
	var found: Font = null
	var path: String = FONT_FILES.get(font_name, "")
	if path != "" and ResourceLoader.exists(path):
		found = load(path) as Font
	if found == null:
		var system: SystemFont = SystemFont.new()
		system.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
		system.font_italic = font_name.contains("Italic")
		found = system
	_fonts[font_name] = found
	return found


static func _colour(value: Variant, fallback: Color) -> Color:
	var text: String = str(value) if value != null else ""
	return Color.from_string(text, fallback) if text != "" else fallback


static func _vec2(value: Variant, fallback: Vector2) -> Vector2:
	var list: Array = value as Array if value is Array else []
	if list.size() < 2 or list[0] == null or list[1] == null:
		return fallback
	return Vector2(float(list[0]), float(list[1]))


static func _vec2i(value: Variant, fallback: Vector2i) -> Vector2i:
	var list: Array = value as Array if value is Array else []
	return Vector2i(int(list[0]), int(list[1])) if list.size() >= 2 else fallback


## A JSON triple; a null entry (a height "from terrain") reads as NAN.
static func _vec3(value: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	var list: Array = value as Array if value is Array else []
	if list.size() < 3:
		return fallback
	var axes: Array[float] = []
	for entry: Variant in list.slice(0, 3):
		axes.append(NAN if entry == null else float(entry))
	return Vector3(axes[0], axes[1], axes[2])
