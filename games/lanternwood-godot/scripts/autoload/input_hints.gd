extends Node

# Which the player used last, the keyboard or a controller, so prompts can show the right
# button: "F" on the keyboard, "□" on a PlayStation controller. Things that show a button
# listen for `device_changed` and ask glyph() for the name.

signal device_changed(using_controller: bool)

const KEYBOARD := {
	"interact": "F", "jump": "Space", "pause": "Esc", "back": "Esc", "confirm": "Enter",
	"move": "W A S D", "look": "Q E  T G", "toggle_music": "M",
}
const CONTROLLER := {
	"interact": "□", "jump": "✕", "pause": "Options", "back": "○", "confirm": "✕",
	"move": "Left stick", "look": "Right stick", "toggle_music": "",
}

var using_controller := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var controller := using_controller
	if event is InputEventKey or event is InputEventMouseButton:
		controller = false
	elif event is InputEventJoypadButton:
		controller = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		controller = true
	if controller != using_controller:
		using_controller = controller
		device_changed.emit(using_controller)


func glyph(action: String) -> String:
	return (CONTROLLER if using_controller else KEYBOARD).get(action, action)
