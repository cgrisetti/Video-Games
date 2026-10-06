extends Node

# Everything the player can change in the Settings menu, saved between visits in
# user://settings.cfg (on a Mac: ~/Library/Application Support/Godot/app_userdata/Lanternwood).
# Anything that cares listens for `changed`, so the menu only has to call set_value().

signal changed(name: String)

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"music_on": true,
	"music_volume": 0.7, # 0 (silent) to 1 (full).
	"music_style": "forest", # "forest" or "8bit".
	"sound_volume": 0.8,
	"invert_x": false, # Turn the camera the other way when looking left and right...
	"invert_y": false, # ...or up and down (some people expect up to look down, like a plane's stick).
	"camera_speed": 1.0, # How quickly the camera turns: 0.25 to 2.
	"graphics": "high", # "low", "medium" or "high": see glen.gd apply_graphics().
	"fullscreen": false,
}

var values := DEFAULTS.duplicate()


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for key in DEFAULTS:
			values[key] = file.get_value("settings", key, DEFAULTS[key])
	_apply_window()


func get_value(name: String) -> Variant:
	return values[name]


func set_value(name: String, value: Variant) -> void:
	if values[name] == value:
		return
	values[name] = value
	if name == "music_volume" and value > 0.0:
		values.music_on = true # Moving the volume turns the music back on.
	if name == "fullscreen":
		_apply_window()
	_save()
	changed.emit(name)


func _apply_window() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _save() -> void:
	var file := ConfigFile.new()
	for key in values:
		file.set_value("settings", key, values[key])
	file.save(PATH)
