extends SceneTree

# A quick check that the Glen works: the gnome walks and jumps, the openings show their prompt
# and card, and the menu opens and closes. Run from this folder:
#   godot --headless --path . --script res://tools/smoke_test.gd
# It prints PASS or FAIL for each check, and exits with 1 if anything failed.

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(5)
	var glen: Node3D = main.glen
	var menu: CanvasLayer = main.menu
	var hud: CanvasLayer = main.hud
	_check("start screen is up and the game is paused", menu.is_open and paused)
	menu.close()
	await _frames(2)
	_check("Play closes the menu", not menu.is_open and not paused)

	var gnome: CharacterBody3D = glen.gnome
	var start: Vector3 = gnome.global_position
	await _seconds(0.6)
	_check("the Glenn's name shows as you arrive", hud._banner.modulate.a > 0.3)
	await _seconds(5.0)
	_check("and fades away again", hud._banner.modulate.a < 0.05)
	Input.action_press("move_forward")
	await _seconds(1.0)
	Input.action_release("move_forward")
	_check("walking forward moves the gnome north (%.1f m)" % (start.z - gnome.global_position.z), start.z - gnome.global_position.z > 4.0)

	await _seconds(0.3)
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	await _seconds(0.25)
	_check("jumping lifts the gnome off the ground (%.2f m)" % gnome.global_position.y, gnome.global_position.y > 0.6)
	await _seconds(1.0)
	_check("the gnome lands again", gnome.is_on_floor())

	# Stand at Berry Rush's gate.
	var gate: Node = glen.get_node("Openings/BerryRushGate")
	gnome.place(gate.spot(), 0.0)
	await _frames(3)
	_check("standing at a gate shows its prompt", hud._prompt.visible and hud._prompt_text.text == "Berry Rush")
	_tap("interact")
	await _frames(2)
	_check("pressing F shows the game's card", hud._card.visible and hud._card_title.text == "Berry Rush")
	var played := [""]
	glen.play_requested.connect(func(game: String) -> void: played[0] = game)
	_tap("interact")
	await _frames(2)
	_check("pressing F again goes in", played[0] == "berry-rush" and not hud._card.visible)

	# A shut opening.
	gnome.place(glen.get_node("Openings/Arbor").spot(), 0.0)
	await _frames(3)
	_check("a shut opening says Coming soon", hud._prompt_text.text == "Coming soon")
	_tap("interact")
	await _frames(2)
	_check("and doesn't open a card", not hud._card.visible)

	# Away from openings, F swings the stick.
	gnome.place(Vector3(0, 0.05, 5), 0.0)
	await _frames(3)
	_check("away from openings there's no prompt", not hud._prompt.visible)
	_tap("interact")
	await _frames(2)
	_check("F swings the stick", gnome._swing >= 0.0)

	_tap("pause")
	await _frames(2)
	_check("Esc opens the pause menu", menu.is_open and paused)
	_tap("pause")
	await _frames(2)
	_check("Esc again closes it", not menu.is_open and not paused)

	root.get_node("Settings").set_value("graphics", "low")
	await _frames(3)
	_check("switching graphics to Low keeps the game running", is_instance_valid(glen) and glen._grass_material != null)
	root.get_node("Settings").set_value("graphics", "high")
	print("FAILED" if _failed else "ALL PASSED")
	quit(1 if _failed else 0)


func _check(what: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	_failed = _failed or not ok


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
