extends SceneTree
func _initialize() -> void:
	_go.call_deferred()
func _go() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.menu.close()
	var started := Time.get_ticks_msec()
	main.go_to("berry-rush")
	while main._switching:
		await process_frame
	print("switched in %d ms; area: %s" % [Time.get_ticks_msec() - started, main.area_name])
	var game = main.area
	for i in 150: await physics_frame
	print("ready gone: ", game._ready_in <= 0.0, " berries: ", game._berries.size(), " worms: ", game._worms.size(), " obstacles: ", game.field.obstacles.size(), " elapsed %.2f" % game.elapsed)
	print("gnome at ", game.gnome.global_position.snapped(Vector3.ONE * 0.01), " on floor ", game.gnome.is_on_floor())
	quit()
