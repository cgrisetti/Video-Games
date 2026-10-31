extends SceneTree

# A long walk with the fox, to check its choices and path rules without watching: the gnome walks
# up the Glenn, stops a while, waves, jumps, swings its stick, runs back and turns round, and this
# counts what the fox did and checks it kept to the rules. (When the gnome runs past and turns, a
# galloping fox swings round in a curve and is briefly further behind, so the check is that it
# catches up quickly, not that it's never far.) Run from this folder (headless is fine):
#   godot --headless --fixed-fps 60 --path . --script res://tools/fox_walk.gd
# (--fixed-fps 60 lets it run faster than real time.)
# It prints PASS or FAIL for each rule, and exits with 1 if anything failed.

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.menu.close()
	var glen: Node3D = main.glen
	var gnome: CharacterBody3D = glen.gnome
	var fox: CharacterBody3D = glen.fox
	var brain: RefCounted = fox.brain
	print("Things to sniff in the Glenn: %d" % brain.interests.size())
	var seen := {}
	var far := 0.0
	var far_doing := ""
	var behind := 0.0 # How long it's been more than 12 m away this time.
	var longest_behind := 0.0
	var outside := 0
	var blocked := 0.0 # Seconds the fox was roughly between the camera and the gnome.
	var hidden := 0.0 # Seconds the fox covered the gnome on screen without fading.
	var frames := 0
	var reacted_to_wave := false
	var played := false
	var steps: Array = [
		["move_forward", 4.5], ["", 6.0], ["move_left", 1.2], ["", 26.0], ["wave", 4.0], ["jump", 2.5],
		["swing", 4.0], ["move_back", 4.0], ["move_right", 0.8], ["move_forward", 3.0], ["", 8.0],
	]
	for step: Array in steps:
		var action: String = step[0]
		if action.begins_with("move_"):
			Input.action_press(action)
		elif action == "wave":
			gnome.wave()
		elif action == "jump":
			Input.action_press("jump")
		elif action == "swing":
			gnome.swing_stick()
		for tick in int(step[1] * 60.0):
			await physics_frame
			frames += 1
			seen[brain.activity] = seen.get(brain.activity, 0) + 1
			if action == "wave" and brain.activity == "greet":
				reacted_to_wave = true
			if brain.activity == "play":
				played = true
			var away := Vector2(fox.global_position.x - gnome.global_position.x, fox.global_position.z - gnome.global_position.z).length()
			if away > far:
				far = away
				far_doing = brain.activity
			behind = behind + 1.0 / 60.0 if away > 12.0 else 0.0
			longest_behind = maxf(longest_behind, behind)
			if not fox.keep_in.grow(0.05).has_point(Vector2(fox.global_position.x, fox.global_position.z)):
				outside += 1
			var camera: Vector3 = glen.camera_rig.camera.global_position
			var to_fox := Vector2(fox.global_position.x - gnome.global_position.x, fox.global_position.z - gnome.global_position.z)
			var to_camera := Vector2(camera.x - gnome.global_position.x, camera.z - gnome.global_position.z)
			if to_fox.length() < 5.0 and to_fox.normalized().dot(to_camera.normalized()) > 0.85:
				blocked += 1.0 / 60.0
			if brain._hides_gnome() and fox._see_through < 0.3:
				hidden += 1.0 / 60.0
			if not fox.global_position.is_finite():
				_check("the fox's position stays a real number", false)
				quit(1)
				return
		if action.begins_with("move_") or action == "jump":
			Input.action_release(action)
	var total := 0
	for activity in seen:
		total += seen[activity]
	var shares := []
	for activity in seen:
		shares.append("%s %d%%" % [activity, roundi(100.0 * seen[activity] / total)])
	print("What the fox did: ", ", ".join(shares))
	_check("it did at least four different things (%d)" % seen.size(), seen.size() >= 4)
	_check("it never stayed more than 12 m behind for long (longest %.1f s; furthest %.1f m, while: %s)" % [longest_behind, far, far_doing], longest_behind < 2.5 and far < 20.0)
	_check("it stayed inside the Glenn", outside == 0)
	_check("it came to say hello when the gnome waved", reacted_to_wave)
	_check("it never hid the gnome: when it was in the way it faded (%.1f s hidden, %.1f s near the camera's line)" % [hidden, blocked], hidden < 1.0)
	print("(It played with the gnome this time: %s. That's a coin toss, so it isn't checked.)" % ("yes" if played else "no"))
	print("FAILED" if _failed else "ALL PASSED")
	quit(1 if _failed else 0)


func _check(what: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	_failed = _failed or not ok
