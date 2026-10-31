extends SceneTree

# Plays Berry Rush without a window and checks it works the way the three.js game did: going in
# through the gate, "Ready…" then "Go!", the field's rules, wading, picking every raspberry, the
# golden raspberry and the fox pointing the way, the Top 10, bonking and being caught by a worm,
# the danger music, restarting, the menu, and going back to the Glenn. Run from this folder:
#   godot --headless --fixed-fps 60 --path . --script res://tools/berry_rush_test.gd
# It prints PASS or FAIL for each check, and exits with 1 if anything failed. (Scores go in a test
# file, not your real Top 10.)

var _failed := false
var _main: Node
var _game: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Scores").reset("berry-rush")
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await _frames(3)
	_main.menu.close()
	var glen: Node3D = _main.glen
	glen.gnome.place(glen.get_node("Openings/BerryRushGate").spot(), 0.0)
	await _frames(3)
	_tap("interact")
	await _frames(2)
	_check("the Berry Rush card shows the best time", _main.hud._card_best.text == "No best time yet. Be the first!")
	_tap("interact")
	await _frames(2)
	while _main._switching:
		await process_frame
	_game = _main.area
	var gnome: CharacterBody3D = _game.gnome
	var hud: Node = _main.hud
	_check("going through the gate brings you to Berry Rush", _main.area_name == "berry-rush")
	_check("it says Ready…", hud._banner_subtitle.text == "Ready…" and hud._banner.modulate.a > 0.5)
	var start: Vector3 = gnome.global_position
	Input.action_press("move_forward")
	await _seconds(1.0)
	_check("you can't move before Go! (moved %.2f m)" % start.distance_to(gnome.global_position), start.distance_to(gnome.global_position) < 0.05 and _game.elapsed == 0.0)
	await _seconds(0.8)
	Input.action_release("move_forward")
	_check("then it says Go! and the clock starts", hud._banner_subtitle.text == "Go!" and _game.elapsed > 0.0)
	# The berry compass (upgrade 2): turned away from the field, the 3 nearest berries get badges.
	_game.camera_rig.reset_view(PI)
	await _frames(3)
	_check("facing away, the berry compass points to the 3 nearest berries", _game._compass._badges.size() == 3)
	_game.camera_rig.reset_view(0.0)

	# The field.
	var field: Node3D = _game.field
	var trees := 0
	var too_close := false
	for tree in field._trees:
		if tree.node.visible:
			trees += 1
			if Vector2(tree.node.position.x, tree.node.position.z - 4.0).length() < 4.0:
				too_close = true
	_check("trees, rocks and logs are scattered (%d trees, %d rocks, %d logs)" % [trees, field._rocks.size(), field._logs.size()], trees >= 10 and field._rocks.size() >= 8 and field._logs.size() >= 2)
	_check("nothing grows where you start", not too_close)
	var berries_ok: bool = _game._berries.size() == 9
	for berry in _game._berries:
		if Vector2(berry.position.x, berry.position.z - 4.0).length() < 3.0:
			berries_ok = false
	_check("there are 9 raspberries, none right at the start", berries_ok)
	# Fair layouts (upgrade 1): one berry in each square of a 3 × 3 grid, spread apart, one over the creek.
	var squares := {}
	var closest := INF
	var over_water := 0
	var half: float = field.PLAY_HALF - 1.5
	for berry in _game._berries:
		squares[Vector2i(clampi(int((berry.position.x + half) / (half * 2.0 / 3.0)), 0, 2), clampi(int((berry.position.z + half) / (half * 2.0 / 3.0)), 0, 2))] = true
		if Creek.distance(berry.position.x, berry.position.z) < Creek.BED_HALF_WIDTH:
			over_water += 1
		for other in _game._berries:
			if other != berry:
				closest = minf(closest, Vector2(berry.position.x - other.position.x, berry.position.z - other.position.z).length())
	_check("the berries are spread out, one in each ninth of the field (%d squares; closest pair %.1f m)" % [squares.size(), closest], squares.size() == 9 and closest >= 2.0)
	_check("and at least one floats over the creek (%d)" % over_water, over_water >= 1)
	var worm_gap := INF
	for worm in _game._worms:
		for berry in _game._berries:
			worm_gap = minf(worm_gap, Vector2(worm.head.x - berry.position.x, worm.head.z - berry.position.z).length())
	_check("no worm starts right by a berry (closest %.1f m)" % worm_gap, worm_gap >= 4.0)
	var seed_now: int = _game.layout_seed
	_game.restart(seed_now)
	var first := _layout()
	await _frames(2)
	_game.restart(seed_now)
	_check("the same seed makes the same field", _layout() == first)
	_game.restart()
	var counts := []
	for i in 12:
		_game.restart()
		counts.append(_game._berries.size())
	_check("every field gets all 9 berries (12 new fields: %s)" % str(counts), counts.count(9) == 12)
	_game._ready_in = 0.0
	var quarters := {}
	var worms_far := true
	for worm in _game._worms:
		quarters[Vector2(signf(worm.head.x), signf(worm.head.z))] = true
		if Vector2(worm.head.x, worm.head.z - 4.0).length() < 10.0:
			worms_far = false
	_check("3 inch worms, each in its own quarter, at least 10 m away", _game._worms.size() == 3 and quarters.size() == 3 and worms_far)

	# Wading, and picking every berry, with the worms held still so they don't end the round first.
	_game.hold_worms = true
	var wet := _find_water(field)
	gnome.place(wet, 0.0)
	await _frames(4)
	Input.action_press("move_forward")
	await _seconds(0.25) # Up to speed, still in the middle of the creek.
	var wading: float = Vector2(gnome.velocity.x, gnome.velocity.z).length()
	Input.action_release("move_forward")
	_check("the creek slows you to 60%% (%.1f m/s of %.1f)" % [wading, gnome.MOVE_SPEED], absf(wading - gnome.MOVE_SPEED * 0.6) < 0.3)

	# Pick every raspberry, quickly, before a worm arrives.
	var fox: CharacterBody3D = _game.fox
	for attempt in 60: # (Wading may already have picked one.)
		if _game._berries.is_empty():
			break
		var berry: Node3D = _game._berries[0]
		gnome.place(berry.global_position - Vector3(0, _game.GNOME_MIDDLE, 0), 0.0)
		await _frames(2)
		if attempt > 20 and berry in _game._berries:
			print("  (can't reach the berry at %s: the gnome is at %s)" % [berry.global_position.snapped(Vector3.ONE * 0.01), gnome.global_position.snapped(Vector3.ONE * 0.01)])
	_check("picking all 9 counts them (%d)" % _game.collected, _game.collected == 9 and hud._berry_label.text == "9 / 10")
	var medals: Dictionary = _game.medal_times
	_check("the field has medal times (gold %s, silver %s, bronze %s)" % [medals.gold, medals.silver, medals.bronze], medals.gold > 5.0 and medals.gold < medals.silver and medals.silver < medals.bronze and hud._medals.text.contains(root.get_node("Scores").format_time(medals.gold)))
	_check("each berry shows how you're doing against gold pace (%s)" % hud._split.text, hud._split.text.begins_with("−") or hud._split.text.begins_with("+") or hud._split.text.begins_with("±"))
	var golden: Node3D = _game._golden
	var gnome_quarter := Vector2(signf(gnome.global_position.x), signf(gnome.global_position.z))
	var golden_quarter := Vector2(signf(golden.position.x), signf(golden.position.z))
	_check("then the golden raspberry appears, in another quarter", golden.visible and golden_quarter != gnome_quarter)
	_check("with the hint to follow the fox", hud._hint.visible and hud._hint_label.text == "Follow the fox to the golden raspberry!")
	await _frames(3)
	_check("the fox points at it", fox.brain.activity == "point")
	await _seconds(1.7)
	_check("then leads the way", fox.brain.activity == "lead")
	# A finale that flows (upgrade 3): the fox lopes ahead at your pace, and waits if you fall behind.
	gnome.place(fox.global_position + Vector3(1.0, 0, 1.0), 0.0)
	var fox_from: Vector3 = fox.global_position
	await _seconds(2.0) # (It may have to turn round first.)
	var moved: float = Vector2(fox.global_position.x - fox_from.x, fox.global_position.z - fox_from.z).length()
	_check("the fox lopes ahead toward it (%.1f m in 2 seconds)" % moved, moved > 5.0 or Vector2(golden.position.x - fox.global_position.x, golden.position.z - fox.global_position.z).length() < 2.5)
	var beam: Node = golden.get_node_or_null("Sunbeam")
	_check("and a shaft of sunlight rises over it", beam != null and beam.mesh.height > 20.0)
	var time_before: float = _game.elapsed
	gnome.place(golden.global_position - Vector3(0, _game.GNOME_MIDDLE, 0), 0.0)
	await _frames(3)
	_check("picking the golden raspberry wins the round", _game.finished and _game.collected == 10 and not _main.scoreboard.is_showing)
	await _seconds(1.5)
	var board: Node = _main.scoreboard
	_check("and the Top 10 comes up with your time", board.is_showing and board._pending > 0.0 and absf(board._pending - time_before) < 0.2)
	_check("saying it's a new fastest time, with the medal you won (%s)" % board._result.text.left(40), board._result.text.begins_with("Gold medal! A new fastest time"))
	board._name.text = "Tester"
	board._save_pending()
	var saved: Array = root.get_node("Scores").entries("berry-rush")
	_check("writing your name puts you in the book", saved.size() == 1 and saved[0].name == "Tester" and board._result.text == "Well picked, Tester!")

	# Restart.
	_game.hold_worms = false
	_tap("restart")
	await _frames(3)
	_check("R starts a new round", not _game.finished and _game.collected == 0 and not board.is_showing and _game._berries.size() == 9)

	# Bonk a worm.
	await _seconds(0.3)
	var worm = _game._worms[0]
	var facing: float = atan2(worm.head_position.x - worm.tail.x, worm.head_position.z - worm.tail.z)
	var front: Vector3 = worm.head_position + Vector3(sin(facing), 0, cos(facing)) * 1.0
	gnome.place(Vector3(front.x, field.floor_at(front.x, front.z) + 0.05, front.z), facing + PI)
	var speed_before: float = worm.top_speed
	gnome.swing_stick()
	var bonked := false
	for i in 40:
		await physics_frame
		gnome.place(Vector3(front.x, field.floor_at(front.x, front.z) + 0.05, front.z), facing + PI)
		if worm.is_dazed():
			bonked = true
			break
	_check("a swing that catches a worm's head stuns it", bonked)
	await _frames(2)
	_check("stars circle its head while it's dazed, and it looks crosser", worm._stars.visible and worm.bonks == 1 and worm._brows[0].visible)
	_check("and it'll get up 5%% faster (%.2f → %.2f m/s)" % [speed_before, worm.top_speed], absf(worm.top_speed - speed_before * 1.05) < 0.01)
	gnome.place(Vector3(0, field.floor_at(0, 4) + 0.05, 4), PI)
	_game.hold_worms = true # Hold the other worms still while we wait (the dazed one's clock still runs).
	await _seconds(5.5)
	_check("after 5 s it's back up", not worm.is_dazed())
	_game.hold_worms = false

	# The danger music, then being caught.
	var near: Vector3 = worm.head_position
	worm._locked = false
	gnome.place(Vector3(near.x + 2.0, field.floor_at(near.x + 2.0, near.z) + 0.05, near.z), 0.0)
	await _frames(2)
	_check("a worm that notices you pops a \"!\" over its head (upgrade 5)", worm.is_alerting() and worm._alert.visible)
	_check("the danger music swells when a worm is close", root.get_node("Sound")._danger_goal > 0.5)
	for i in 30:
		gnome.place(Vector3(worm.head_position.x, field.floor_at(worm.head_position.x, worm.head_position.z) + 0.05, worm.head_position.z), 0.0)
		await physics_frame
		if _game.caught_by_worm:
			break
	_check("touching an awake worm ends the round", _game.caught_by_worm and _game.finished)
	await _frames(2)
	_check("and the Top 10 says the worm got you", board.is_showing and board._result.text.begins_with("The inch worm got you!"))
	_check("a finished round doesn't pause by itself", not _game.can_pause())

	# The menu, mid-round.
	_tap("restart")
	await _seconds(1.0)
	_main.menu.open()
	await _frames(2)
	_check("the menu has Restart round and Return to the Glenn", _main.menu._game_rows[0].visible and _main.menu._game_rows[1].visible and not _main.menu._glenn_rows[0].visible)
	_main.menu._game_rows[1].pressed.emit()
	await _frames(2)
	_check("leaving mid-round asks first", _main.menu._page == "leave")
	_main.menu._show_page("main")
	_main.menu.close()

	# Back to the Glenn from the Top 10.
	_game.finished = true
	board.show_board("berry-rush", -1.0)
	board.return_to_glenn.emit()
	await _frames(2)
	while _main._switching:
		await process_frame
	var gate_spot: Vector3 = glen.get_node("Openings/BerryRushGate").spot()
	_check("Return to the Glenn takes you back out of the gate", _main.area_name == "glen" and glen.gnome.global_position.distance_to(gate_spot) < 1.0 and not board.is_showing)
	_check("where the gate's card now shows the best time", await _gate_card_best() == "Best time: %s, by Tester" % root.get_node("Scores").format_time(saved[0].score))
	print("FAILED" if _failed else "ALL PASSED")
	root.get_node("Scores").reset("berry-rush")
	quit(1 if _failed else 0)


# Where everything is, as text, for comparing two fields.
func _layout() -> String:
	var parts := []
	for berry in _game._berries:
		parts.append(str(berry.position.snapped(Vector3.ONE * 0.01)))
	for worm in _game._worms:
		parts.append(str(worm.head.snapped(Vector3.ONE * 0.01)))
	for obstacle in _game.field.obstacles:
		parts.append(str(obstacle.position.snapped(Vector3.ONE * 0.01)))
	return ",".join(parts)


func _gate_card_best() -> String:
	_tap("interact")
	await _frames(2)
	var text: String = _main.hud._card_best.text
	_tap("back")
	return text


# The middle of the creek, somewhere clear of the bridges.
func _find_water(field: Node3D) -> Vector3:
	for step in 60:
		var along := -14.0 + step * 0.5
		var across := Creek.middle_at(along)
		var x := (across - along) / sqrt(2.0)
		var z := (across + along) / sqrt(2.0)
		if field.in_water(x, z) and not Creek.is_near_bridge(x, z, 2.5, field.bridges) and not field.is_near_obstacle(x, z, 1.5):
			return Vector3(x, field.floor_at(x, z) + 0.05, z)
	return Vector3.ZERO


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
