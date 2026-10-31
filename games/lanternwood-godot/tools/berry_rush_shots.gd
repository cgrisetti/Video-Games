extends SceneTree

# Photos of Berry Rush on one sheet: the start, the field from above, a bridge over the creek, an
# inch worm up close, the golden raspberry, and the Top 10. For checking how a change looks.
# Needs a real window. Run from this folder:
#   godot --path . --script res://tools/berry_rush_shots.gd -- --out=/tmp/berry-rush.png

const TILE := Vector2i(800, 450)
const COLUMNS := 3

var _main: Node
var _sheet: Image
var _count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		options[parts[0]] = parts[1] if parts.size() > 1 else ""
	root.get_node("Settings").values.music_on = false
	DisplayServer.window_move_to_foreground()
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_main.menu.close()
	_main.go_to("berry-rush")
	while _main._switching:
		await process_frame
	var game: Node3D = _main.area
	_sheet = Image.create(TILE.x * COLUMNS, TILE.y * 2, false, Image.FORMAT_RGBA8)
	await _seconds(2.5)
	await _snap("the start, from the game camera")

	var camera := Camera3D.new()
	camera.fov = 50.0
	camera.far = 400.0
	game.add_child(camera)
	camera.current = true
	camera.global_position = Vector3(0, 34, 30)
	camera.look_at(Vector3(0, 0, -2))
	await _seconds(0.5)
	await _snap("the field from above")

	var bridge: Dictionary = game.field.bridges[0]
	var spot: Vector3 = bridge.center
	camera.global_position = spot + Vector3(-5, 2.6, 5)
	camera.look_at(spot + Vector3(0, 0.4, 0))
	await _seconds(0.4)
	await _snap("a bridge over the creek")

	var worm = game._worms[0]
	camera.fov = 35.0
	for i in 40:
		camera.global_position = worm.head_position + Vector3(2.4, 1.3, 2.4)
		camera.look_at(worm.head_position.lerp(worm.tail, 0.3))
		await process_frame
	await _snap("an inch worm")

	camera.fov = 45.0
	for berry in game._berries.duplicate():
		game._berries.erase(berry)
		berry.queue_free()
	game.collected = game.BERRY_COUNT
	game._spawn_golden()
	var golden: Node3D = game._golden
	for i in 90:
		camera.global_position = golden.global_position + Vector3(0, 2.4, 4.0)
		camera.look_at(golden.global_position)
		await process_frame
	await _snap("the golden raspberry")

	camera.current = false
	game.finished = true
	game.elapsed = 47.3
	_main.scoreboard.show_board("berry-rush", 47.3)
	await _seconds(0.6)
	await _snap("the Top 10")
	_sheet.save_png(options.get("out", "user://berry-rush.png"))
	print("Saved ", options.get("out", "user://berry-rush.png"))
	_main.scoreboard.hide_board()
	quit()


func _snap(what: String) -> void:
	if _main.menu.is_open:
		_main.menu.close() # The game pauses itself if the window loses focus.
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(TILE.x, int(TILE.x * float(image.get_height()) / image.get_width()))
	_sheet.blit_rect(image, Rect2i(0, (image.get_height() - TILE.y) / 2, TILE.x, TILE.y), Vector2i(_count % COLUMNS * TILE.x, _count / COLUMNS * TILE.y))
	_count += 1
	print("  ", what)


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
