extends Node

# Lanternwood: starts in the Glenn with the start screen up, and handles pausing, the menu, and
# what happens when you go through a gate. (The mini-games haven't moved over from the three.js
# version yet, so their gates say so for now.)
#
# For testing from the command line, after "--": --skip-menu, --page=settings, --at=x,z,camera_turn,
# --screenshot=path.png --wait=seconds (saves the screen after a few seconds, then quits).

@onready var glen: Glen = $Glen
@onready var hud: CanvasLayer = $HUD
@onready var menu: CanvasLayer = $Menu

var _options := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_options[parts[0]] = parts[1] if parts.size() > 1 else ""
	glen.hud = hud
	glen.play_requested.connect(_on_play)
	menu.play_pressed.connect(func() -> void: hud.show_banner("The Glenn", "Lanternwood"))
	menu.quit_pressed.connect(func() -> void: get_tree().quit())
	Input.joy_connection_changed.connect(_on_controller_changed)
	glen.enter()
	if _options.has("at"):
		var at: PackedFloat64Array = _options.at.split_floats(",")
		glen.gnome.place(Vector3(at[0], 0.05, at[1]), PI)
		glen.camera_rig.reset_view(deg_to_rad(at[2]) if at.size() > 2 else 0.0)
	if _options.has("skip-menu"):
		hud.show_banner("The Glenn", "Lanternwood")
	else:
		menu.open(true)
		if _options.has("page"):
			menu._show_page(_options.page)
	if _options.has("screenshot"):
		_take_screenshot(_options.screenshot)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not menu.is_open:
		if not glen.dismiss():
			menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_music"):
		Settings.set_value("music_on", not Settings.get_value("music_on"))
		hud.show_toast("Music on" if Settings.get_value("music_on") else "Music off")
	elif event.is_action_pressed("screenshot"):
		var path := "user://lanternwood-%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
		get_viewport().get_texture().get_image().save_png(path)
		hud.show_toast("Saved a picture")


# Pause by itself when the player looks away: another window, or an unplugged controller.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not menu.is_open and not _options.has("screenshot"):
		menu.open()


func _on_controller_changed(_device: int, connected: bool) -> void:
	if connected:
		hud.show_toast("Controller connected")
		menu.show_notice("")
	elif not menu.is_open:
		menu.open(false, "Your controller came unplugged. Plug it back in, or carry on with the keyboard.")


func _on_play(game: String) -> void:
	hud.show_toast("%s is on its way to this version of Lanternwood!" % Glen.GAMES[game].title)


func _take_screenshot(path: String) -> void:
	var seconds := float(_options.get("wait", "4"))
	await get_tree().create_timer(seconds, true, false, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("Saved ", path)
	get_tree().quit()
