extends SceneTree

# Writes Lanternwood's controls (the input map) and audio buses into project.godot and
# default_bus_layout.tres. Run once from this folder:
#   godot --headless --path . --script res://tools/make_project.gd
# You can also change controls by hand in the editor: Project > Project Settings > Input Map.

const STICK_DEAD_ZONE := 0.2

func _init() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1600)
	ProjectSettings.set_setting("display/window/size/viewport_height", 900)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 2)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/screen_space_aa", 1)
	ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", Color("#2a3a2e"))
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/size", 4096)
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 3)
	ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 3)
	ProjectSettings.set_setting("audio/buses/default_bus_layout", "res://default_bus_layout.tres")
	ProjectSettings.set_setting("autoload/Settings", "*res://scripts/autoload/settings.gd")
	ProjectSettings.set_setting("autoload/InputHints", "*res://scripts/autoload/input_hints.gd")
	ProjectSettings.set_setting("autoload/Sound", "*res://scripts/autoload/sound.gd")

	# Controller buttons use Godot's layout, which matches Xbox names. On a PlayStation controller:
	# button 0 is ✕, 1 is ○, 2 is □, 3 is △, 6 is Options.
	_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1), _button(JOY_BUTTON_DPAD_LEFT)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1), _button(JOY_BUTTON_DPAD_RIGHT)])
	_action("move_forward", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1), _button(JOY_BUTTON_DPAD_UP)])
	_action("move_back", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1), _button(JOY_BUTTON_DPAD_DOWN)])
	_action("jump", [_key(KEY_SPACE), _button(JOY_BUTTON_A)])
	_action("interact", [_key(KEY_F), _button(JOY_BUTTON_X)]) # Swing the stick, or go through a gate.
	_action("pause", [_key(KEY_ESCAPE), _key(KEY_P), _button(JOY_BUTTON_START)])
	_action("back", [_button(JOY_BUTTON_B)]) # Put away a game card (Esc does it too, through "pause").
	_action("look_left", [_key(KEY_Q), _axis(JOY_AXIS_RIGHT_X, -1)])
	_action("look_right", [_key(KEY_E), _axis(JOY_AXIS_RIGHT_X, 1)])
	_action("look_up", [_key(KEY_T), _axis(JOY_AXIS_RIGHT_Y, -1)])
	_action("look_down", [_key(KEY_G), _axis(JOY_AXIS_RIGHT_Y, 1)])
	_action("toggle_music", [_key(KEY_M)])
	_action("screenshot", [_key(KEY_F12)])
	print("project.godot: ", ProjectSettings.save())

	# Audio buses: Music (muffled while paused) and Effects, both under Master.
	AudioServer.bus_count = 1
	AudioServer.add_bus(1)
	AudioServer.set_bus_name(1, "Music")
	AudioServer.set_bus_send(1, "Master")
	var muffle := AudioEffectLowPassFilter.new()
	muffle.cutoff_hz = 700.0
	AudioServer.add_bus_effect(1, muffle)
	AudioServer.set_bus_effect_enabled(1, 0, false)
	AudioServer.add_bus(2)
	AudioServer.set_bus_name(2, "Effects")
	AudioServer.set_bus_send(2, "Master")
	print("bus layout: ", ResourceSaver.save(AudioServer.generate_bus_layout(), "res://default_bus_layout.tres"))
	quit()

func _action(name: String, events: Array) -> void:
	var setting := {"deadzone": STICK_DEAD_ZONE, "events": events}
	ProjectSettings.set_setting("input/" + name, setting)

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = -1 # Any keyboard.
	event.physical_keycode = code
	return event

func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1 # Any controller.
	event.button_index = index
	return event

func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = direction
	return event
