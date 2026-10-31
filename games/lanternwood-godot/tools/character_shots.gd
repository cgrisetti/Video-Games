extends SceneTree

# Photos of the gnome or the fox, close up from several sides and in the middle of their moves, put
# together on one sheet. For checking how a change to a character looks. Needs a real window (not
# headless). Run from this folder:
#   godot --path . --rendering-method forward_plus --script res://tools/character_shots.gd -- --who=gnome --out=/tmp/gnome.png

const TILE := Vector2i(800, 500)
const COLUMNS := 3

var _glen: Node3D
var _camera: Camera3D
var _subject: Node3D
var _view := [0.0, 2.6, 1.0, 0.8] # Around (radians from the front), distance, height, look-at height.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		options[parts[0]] = parts[1] if parts.size() > 1 else ""
	var who: String = options.get("who", "gnome")
	root.get_node("Settings").values.music_on = false
	DisplayServer.window_move_to_foreground()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.menu.close()
	main.hud.visible = false
	_glen = main.glen
	_glen.gnome.place(Vector3(_glen.path_x(26.0), 0.05, 26.0), PI * 0.85)
	_glen.fox.place(_glen.gnome.global_position + Vector3(-2.2, 0, 1.0))
	_camera = Camera3D.new()
	_camera.fov = 40.0
	_glen.add_child(_camera)
	_camera.current = true
	_subject = _glen.gnome if who == "gnome" else _glen.fox
	await _seconds(2.0) # Shaders.

	var sheet := Image.create(TILE.x * COLUMNS, TILE.y * 3, false, Image.FORMAT_RGBA8)
	var shots: Array = _gnome_shots() if who == "gnome" else _fox_shots()
	for i in shots.size():
		var shot: Array = shots[i]
		_view = shot[1]
		await shot[2].call()
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		image.resize(TILE.x, int(TILE.x * float(image.get_height()) / image.get_width()))
		sheet.blit_rect(image, Rect2i(0, (image.get_height() - TILE.y) / 2, TILE.x, TILE.y), Vector2i(i % COLUMNS * TILE.x, i / COLUMNS * TILE.y))
		print("  ", shot[0])
	sheet.save_png(options.get("out", "user://%s.png" % who))
	print("Saved ", options.get("out", "user://%s.png" % who))
	quit()


func _gnome_shots() -> Array:
	var gnome: CharacterBody3D = _glen.gnome
	return [
		["standing, from the front", [0.0, 2.4, 1.0, 0.85], func() -> void: await _seconds(1.2)],
		["from behind, like the game camera", [PI * 0.85, 3.2, 1.9, 0.9], func() -> void: await _seconds(0.3)],
		["from the side", [PI * 0.5, 2.6, 0.9, 0.8], func() -> void: await _seconds(0.3)],
		["running", [PI * 0.4, 3.0, 1.0, 0.8], func() -> void:
			Input.action_press("move_left")
			await _seconds(0.55)
			Input.action_release("move_left")],
		["jumping", [PI * 0.3, 3.2, 1.0, 1.2], func() -> void:
			await _seconds(0.8)
			Input.action_press("jump")
			await _seconds(0.3)
			Input.action_release("jump")
			print("    (%.2f m off the ground, in the air %.0f%%)" % [gnome.global_position.y, gnome._air * 100.0])],
		["swinging the stick", [PI * 0.15, 3.0, 1.0, 0.9], func() -> void:
			await _seconds(1.0)
			gnome.swing_stick()
			await _seconds(gnome.SWING_TIME * 0.45)],
		["tipping his hat", [PI * 0.1, 2.4, 1.1, 1.0], func() -> void:
			await _seconds(0.8)
			gnome.wave()
			await _seconds(gnome.WAVE_TIME * 0.17)],
		["waving", [PI * 0.1, 2.6, 1.1, 1.0], func() -> void: await _seconds(gnome.WAVE_TIME * 0.4)],
		["after a while, a fidget", [PI * 0.12, 2.4, 1.0, 0.85], func() -> void: await _seconds(gnome.FIDGET_AFTER + 1.6)],
	]


func _fox_shots() -> Array:
	var fox: CharacterBody3D = _glen.fox
	return [
		["standing, from the front", [0.0, 3.0, 1.2, 0.7], func() -> void: await _seconds(0.5)],
		["from the side", [PI * 0.5, 3.4, 1.0, 0.7], func() -> void: await _seconds(0.3)],
		["from behind", [PI * 0.85, 3.4, 1.8, 0.7], func() -> void: await _seconds(0.3)],
		["with the gnome", [PI * 0.6, 5.0, 2.0, 0.8], func() -> void: await _seconds(0.3)],
		["trotting", [PI * 0.5, 3.6, 1.0, 0.7], func() -> void:
			Input.action_press("move_forward")
			await _seconds(0.9)
			Input.action_release("move_forward")],
		["after a while", [PI * 0.3, 3.4, 1.4, 0.6], func() -> void: await _seconds(6.0)],
	]


func _process(_delta: float) -> bool:
	if _camera and _subject:
		var model: Node3D = _subject.get_node("Model")
		var around: float = model.global_rotation.y + _view[0]
		var at: Vector3 = _subject.global_position
		_camera.global_position = at + Vector3(sin(around) * _view[1], _view[2], cos(around) * _view[1])
		_camera.look_at(at + Vector3(0, _view[3], 0))
	return false


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
