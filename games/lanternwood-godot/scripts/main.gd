extends Node

# Lanternwood: starts in the Glenn with the start screen up, and handles pausing, the menu, and
# going through a gate into a game and back. Each place you can be (the Glenn, Berry Rush) is an
# "area": only one is in the scene at a time, and the others wait, so coming back is quick. An
# area can have enter(from), leave(), restart(), can_pause() and round_in_progress().
# (Only Berry Rush has moved over from the three.js version so far; the other gates say so.)
#
# For testing from the command line, after "--": --skip-menu, --page=settings, --at=x,z,camera_turn,
# --screenshot=path.png --wait=seconds (saves the screen after a few seconds, then quits).

const GAMES := {"berry-rush": preload("res://scenes/berry_rush.tscn")}
const FADE_SECONDS := 0.35

@onready var glen: Glen = $Glen
@onready var hud: CanvasLayer = $HUD
@onready var menu: CanvasLayer = $Menu
@onready var scoreboard: CanvasLayer = $Scoreboard

var area: Node # The area the gnome is in now.
var area_name := "glen"
var _areas := {}
var _switching := false
var _fade: ColorRect
var _options := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_options[parts[0]] = parts[1] if parts.size() > 1 else ""
	glen.hud = hud
	glen.play_requested.connect(_on_play)
	area = glen
	_areas.glen = glen
	menu.restart_pressed.connect(func() -> void: if area.has_method("restart"): area.restart())
	menu.leave_pressed.connect(go_to.bind("glen"))
	get_viewport().size_changed.connect(func() -> void: Glen.fit_resolution(Settings.get_value("graphics"), get_viewport()))
	var cover := CanvasLayer.new()
	cover.layer = 30
	_fade = ColorRect.new()
	_fade.color = Color("#0d0a06")
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	cover.add_child(_fade)
	add_child(cover)
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
	if event.is_action_pressed("pause") and not menu.is_open and not _switching:
		if area != glen or not glen.dismiss():
			menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_music"):
		Settings.set_value("music_on", not Settings.get_value("music_on"))
		hud.show_toast("Music on" if Settings.get_value("music_on") else "Music off")
	elif event.is_action_pressed("screenshot"):
		var path := "user://lanternwood-%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
		get_viewport().get_texture().get_image().save_png(path)
		hud.show_toast("Saved a picture")


# Pause by itself when the player looks away: another window, or an unplugged controller. (In a
# game, only mid-round: a finished round has nothing to pause.)
func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT or menu == null or menu.is_open or _switching or _options.has("screenshot"):
		return # (The window can lose focus before everything is set up, or halfway through a fade.)
	if area and area.has_method("can_pause") and not area.can_pause():
		return
	menu.open()


func _on_controller_changed(_device: int, connected: bool) -> void:
	if connected:
		hud.show_toast("Controller connected")
		menu.show_notice("")
	elif not menu.is_open:
		menu.open(false, "Your controller came unplugged. Plug it back in, or carry on with the keyboard.")


func _on_play(game: String) -> void:
	if GAMES.has(game):
		go_to(game)
	else:
		hud.show_toast("%s is on its way to this version of Lanternwood!" % Glen.GAMES[game].title)


# Go to an area ("glen" or a game): fade out, swap, fade in. Coming back to the Glenn, the gnome
# arrives in front of the gate it went through.
func go_to(name: String) -> void:
	if _switching or name == area_name:
		return
	_switching = true
	var from := area_name
	await _fade_to(1.0)
	if area.has_method("leave"):
		area.leave()
	remove_child(area)
	if not _areas.has(name):
		var made: Node = GAMES[name].instantiate()
		made.setup(hud, scoreboard)
		made.leave_requested.connect(go_to.bind("glen"))
		_areas[name] = made
	area = _areas[name]
	area_name = name
	add_child(area)
	move_child(area, 0)
	hud.set_area(name)
	var in_game := name != "glen"
	menu.set_game(in_game, Callable(area, "round_in_progress") if in_game else Callable(), area.GOAL if in_game else menu.GLENN_GOAL)
	area.enter(from)
	await _fade_to(0.0)
	_switching = false


# Free the areas that were waiting out of the scene (the one in the scene goes with it).
func _exit_tree() -> void:
	for name in _areas:
		if _areas[name] != area:
			_areas[name].free()


func _fade_to(alpha: float) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Finishes even if something pauses the game.
	tween.tween_property(_fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished


func _take_screenshot(path: String) -> void:
	var seconds := float(_options.get("wait", "4"))
	await get_tree().create_timer(seconds, true, false, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("Saved ", path)
	get_tree().quit()
