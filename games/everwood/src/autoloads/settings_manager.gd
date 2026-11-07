## The machine's settings (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.1–2.3), the
## autoload "Settings": what the Options menu changes, saved as JSON in
## user://everwood_settings.json through SaveManager, and applied at once:
##   Audio      the main, music, effects and ambience volumes (an amplifier at
##              the end of each of AudioDirector's buses, so its own ducking stays its own)
##   Video      window or full screen, vertical sync, a frame cap, the 3D render
##              scale, the cameras' field of view, and (25 GDD §2, the Options
##              wireframe) how far you see, how thick the grass and flowers grow
##              and how sharp the hand-painted textures draw
##   Controls   invert Y (stick and mouse), camera speed, mouse sensitivity and
##              which pad's button names to show
##   Gameplay   toggle sprint (L3 / Shift starts a sprint that keeps going until
##              you steer sideways or back, stop, or press it again), enemy
##              level badges, the camera's push on a Sign-Flow cast, and the
##              numbers that pop off a hit, the rhyme ribbon's size and the
##              INK READY border (25 GDD §2)
## Settings belong to the machine, not to a player or the family's progress.
## The smoke test points them at its own scratch file (use_settings_file).
class_name SettingsManager
extends Node

signal changed(key: StringName)

enum WindowMode { WINDOWED, FULLSCREEN, BORDERLESS }
enum PadGlyphs { AUTO, PLAYSTATION, XBOX }
enum WorldDetail { NEAR, MID, FULL }
enum GrassDensity { FEW, SOME, LOTS }
enum CraftTextures { SOFT, SHARP }
enum RibbonSize { NORMAL, LARGE }

const SETTINGS_PATH: String = "user://everwood_settings.json"
const VERSION: int = 1
## Every setting, in the order the Options menu lists them.
const KEYS: Array[StringName] = [&"master_volume", &"music_volume", &"effects_volume", &"ambience_volume",
	&"window_mode", &"vsync", &"frame_cap", &"render_scale", &"field_of_view",
	&"world_detail", &"grass_density", &"craft_textures",
	&"invert_y_axis", &"camera_speed", &"mouse_sensitivity", &"pad_glyphs",
	&"toggle_sprint_mode", &"enemy_level_badges", &"camera_pulse",
	&"damage_numbers", &"rhyme_ribbon_size", &"ink_ready_border"]
## The choices that cycle (left / right), and how many each has.
const CHOICES: Dictionary[StringName, int] = {
	&"window_mode": 3, &"pad_glyphs": 3, &"world_detail": 3, &"grass_density": 3, &"craft_textures": 2, &"rhyme_ribbon_size": 2,
}
## How far the cameras see at each World detail, as a share of the place's own horizon
## (Full: far villages and woods out to 512 m and the isles' horizon to 2.5 km).
const VIEW_DISTANCE_SCALES: Array[float] = [0.3, 0.6, 1.0]
## How much grass and flowers each Grass & flowers setting grows, as a share of the most.
const GRASS_SCALES: Array[float] = [0.4, 0.7, 1.0]
## The texture mipmap bias at each Craft textures setting (Soft draws smaller mips: kinder on a laptop).
const TEXTURE_BIASES: Array[float] = [1.0, 0.0]
## The rhyme ribbon's font size at Normal and Large (read aloud).
const RIBBON_FONT_SIZES: Array[int] = [21, 28]
## Cameras join this group so a World detail change reaches every view.
const CAMERA_GROUP: StringName = &"player_cameras"
## Each number's range: [low, high, step].
const RANGES: Dictionary[StringName, Vector3] = {
	&"master_volume": Vector3(0.0, 1.0, 0.05), &"music_volume": Vector3(0.0, 1.0, 0.05), &"effects_volume": Vector3(0.0, 1.0, 0.05),
	&"ambience_volume": Vector3(0.0, 1.0, 0.05), &"render_scale": Vector3(0.5, 1.0, 0.05), &"field_of_view": Vector3(50.0, 80.0, 1.0),
	&"camera_speed": Vector3(0.5, 2.0, 0.1), &"mouse_sensitivity": Vector3(0.25, 3.0, 0.05),
}
## The frame caps on offer (0: none).
const FRAME_CAPS: Array[int] = [0, 30, 60, 120, 144]
## Which buses each volume turns (AudioDirector.BUS_NAMES).
const VOLUME_BUSES: Dictionary[StringName, Array] = {
	&"master_volume": [&"Master"], &"music_volume": [&"Music"], &"effects_volume": [&"CombatSFX", &"SignTelegraphs"],
	&"ambience_volume": [&"Ambience3D"],
}
## Split-screen grids join this group so a render-scale change reaches every view.
const GRID_GROUP: StringName = &"split_screen_grids"

static var current: SettingsManager

# --- Audio ---
@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var music_volume: float = 1.0
@export_range(0.0, 1.0) var effects_volume: float = 1.0
@export_range(0.0, 1.0) var ambience_volume: float = 1.0
# --- Video ---
@export var window_mode: WindowMode = WindowMode.WINDOWED
@export var vsync: bool = true
@export var frame_cap: int = 0
@export_range(0.5, 1.0) var render_scale: float = 1.0
@export_range(50.0, 80.0) var field_of_view: float = 62.0
# --- Controls ---
@export var invert_y_axis: bool = false
@export_range(0.5, 2.0) var camera_speed: float = 1.0
@export_range(0.25, 3.0) var mouse_sensitivity: float = 1.0
@export var pad_glyphs: PadGlyphs = PadGlyphs.AUTO
# --- Gameplay ---
@export var toggle_sprint_mode: bool = true
@export var enemy_level_badges: bool = true
@export var camera_pulse: bool = true
@export var damage_numbers: bool = true
@export var rhyme_ribbon_size: RibbonSize = RibbonSize.NORMAL
@export var ink_ready_border: bool = true
# --- Video, the world (25 GDD §2) ---
@export var world_detail: WorldDetail = WorldDetail.FULL
@export var grass_density: GrassDensity = GrassDensity.LOTS
@export var craft_textures: CraftTextures = CraftTextures.SHARP

var _path: String = SETTINGS_PATH
var _defaults: Dictionary = {}
var _amplifiers: Dictionary[StringName, AudioEffectAmplify] = {}


func _enter_tree() -> void:
	current = self
	if _defaults.is_empty():
		_defaults = to_dict()


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	load_settings()
	apply_all()


# --- Reading (static, so code runs before the autoload exists too) ---------------

static func invert_y() -> bool:
	return current != null and current.invert_y_axis


static func toggle_sprint() -> bool:
	return current == null or current.toggle_sprint_mode


static func camera_speed_scale() -> float:
	return current.camera_speed if current != null else 1.0


static func mouse_scale() -> float:
	return current.mouse_sensitivity if current != null else 1.0


static func fov() -> float:
	return current.field_of_view if current != null else 62.0


static func badges_shown() -> bool:
	return current == null or current.enemy_level_badges


static func pulse_on() -> bool:
	return current == null or current.camera_pulse


static func glyphs() -> PadGlyphs:
	return current.pad_glyphs if current != null else PadGlyphs.AUTO


## How far the cameras see, as a share of the place's horizon (1.0 with no settings).
static func view_distance_scale() -> float:
	return VIEW_DISTANCE_SCALES[current.world_detail] if current != null else 1.0


## How much grass and flowers grow, as a share of the most.
static func grass_scale() -> float:
	return GRASS_SCALES[current.grass_density] if current != null else 1.0


static func texture_bias() -> float:
	return TEXTURE_BIASES[current.craft_textures] if current != null else 0.0


static func damage_numbers_shown() -> bool:
	return current == null or current.damage_numbers


static func ribbon_font_size() -> int:
	return RIBBON_FONT_SIZES[current.rhyme_ribbon_size] if current != null else RIBBON_FONT_SIZES[0]


static func ink_ready_border_shown() -> bool:
	return current == null or current.ink_ready_border


# --- Files ---------------------------------------------------------------------------

## Reads the settings file (missing values keep their defaults).
func load_settings() -> void:
	var data: Dictionary = SaveManager.load_json(_path)
	for key: StringName in KEYS:
		if data.has(String(key)):
			_assign(key, data[String(key)])


func save_settings() -> Error:
	var data: Dictionary = to_dict()
	data["version"] = VERSION
	return SaveManager.save_json(_path, data)


## Every setting by name (JSON-ready).
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for key: StringName in KEYS:
		data[String(key)] = get(key)
	return data


## Points the settings at another file (the smoke test's scratch file), starting from the defaults.
func use_settings_file(path: String) -> void:
	_path = path
	for key: StringName in KEYS:
		_assign(key, _defaults.get(String(key)))
	load_settings()
	apply_all()


func settings_path() -> String:
	return _path


## Changes one setting, applies it, saves the file and tells the listeners.
func set_value(key: StringName, value: Variant) -> void:
	if not KEYS.has(key):
		push_warning("Settings: no setting called %s" % key)
		return
	_assign(key, value)
	apply(key)
	save_settings()
	changed.emit(key)


## Steps a setting one notch (`step` -1 or 1): a toggle flips, a choice cycles, a number moves by its step.
func step_value(key: StringName, step: int) -> void:
	var now: Variant = get(key)
	if now is bool:
		set_value(key, not now)
	elif key == &"frame_cap":
		set_value(key, FRAME_CAPS[wrapi(FRAME_CAPS.find(int(now)) + step, 0, FRAME_CAPS.size())])
	elif CHOICES.has(key):
		set_value(key, wrapi(int(now) + step, 0, CHOICES[key]))
	elif RANGES.has(key):
		var range_of: Vector3 = RANGES[key]
		set_value(key, clampf(snappedf(float(now) + range_of.z * step, range_of.z), range_of.x, range_of.y))


## Puts every setting back as it came (and saves).
func reset_to_defaults() -> void:
	for key: StringName in KEYS:
		_assign(key, _defaults.get(String(key)))
	apply_all()
	save_settings()
	changed.emit(&"")


func _assign(key: StringName, value: Variant) -> void:
	if value == null:
		return
	var now: Variant = get(key)
	if now is bool:
		set(key, bool(value))
	elif now is int:
		var number: int = int(value)
		if key == &"frame_cap":
			number = number if FRAME_CAPS.has(number) else 0
		elif CHOICES.has(key):
			number = clampi(number, 0, CHOICES[key] - 1)
		set(key, number)
	elif now is float:
		var range_of: Vector3 = RANGES.get(key, Vector3(-INF, INF, 0.0))
		set(key, clampf(float(value), range_of.x, range_of.y))


# --- Applying -------------------------------------------------------------------------

func apply_all() -> void:
	for key: StringName in KEYS:
		apply(key)


func apply(key: StringName) -> void:
	if VOLUME_BUSES.has(key):
		_apply_volume(key)
		return
	var windowed: bool = DisplayServer.get_name() != "headless"
	match key:
		&"window_mode":
			if windowed and is_inside_tree():
				var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED
				if window_mode == WindowMode.FULLSCREEN:
					mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
				elif window_mode == WindowMode.BORDERLESS:
					mode = DisplayServer.WINDOW_MODE_FULLSCREEN
				if DisplayServer.window_get_mode() != mode:
					DisplayServer.window_set_mode(mode)
		&"vsync":
			if windowed:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		&"frame_cap":
			# The smoke test runs with --fixed-fps; a cap there would only slow it.
			if windowed:
				Engine.max_fps = frame_cap
		&"render_scale":
			if is_inside_tree():
				get_tree().root.scaling_3d_scale = render_scale
				for grid: Node in get_tree().get_nodes_in_group(GRID_GROUP):
					grid.call(&"apply_render_scale", render_scale)
		&"world_detail":
			if is_inside_tree():
				for camera: Node in get_tree().get_nodes_in_group(CAMERA_GROUP):
					camera.call(&"apply_view_distance")
		&"craft_textures":
			if is_inside_tree():
				get_tree().root.texture_mipmap_bias = texture_bias()
				for grid: Node in get_tree().get_nodes_in_group(GRID_GROUP):
					grid.call(&"apply_texture_bias", texture_bias())


## Turns one volume's buses with an amplifier at the end of each (silence at 0).
func _apply_volume(key: StringName) -> void:
	var linear: float = float(get(key))
	var gain: float = -80.0 if linear <= 0.001 else maxf(linear_to_db(linear), -80.0)
	for bus_name: StringName in VOLUME_BUSES[key]:
		var bus: int = AudioServer.get_bus_index(bus_name)
		if bus < 0:
			continue
		var amplifier: AudioEffectAmplify = _amplifiers.get(bus_name, null)
		var present: bool = false
		if amplifier != null:
			for index: int in AudioServer.get_bus_effect_count(bus):
				present = present or AudioServer.get_bus_effect(bus, index) == amplifier
		if not present:
			amplifier = AudioEffectAmplify.new()
			_amplifiers[bus_name] = amplifier
			# At the end of the bus's chain: AudioDirector's own effects keep their places.
			AudioServer.add_bus_effect(bus, amplifier, -1)
		amplifier.volume_db = gain


## The amplifier gain on a bus right now (tests), or NAN when there is none.
func volume_db_on(bus_name: StringName) -> float:
	var amplifier: AudioEffectAmplify = _amplifiers.get(bus_name, null)
	return amplifier.volume_db if amplifier != null else NAN
