class_name BerryRush
extends Node3D

# Berry Rush: Lanternwood's first game. A raspberry glade ringed by a hedge, with a creek, three
# hungry rainbow inch worms, and a golden raspberry to finish. You come in through the garden gate
# at the south end. "Ready…", then "Go!": pick all 9 raspberries, then follow the fox to the golden
# one, as fast as you can, without an inch worm catching you. Swing your stick at a worm's head to
# stun it (it gets up a little faster). The fastest times go in the Top 10.
#
# Everything about how the game plays is the same as the three.js Berry Rush; the field is new.
# The field and its obstacles are in field.gd, the creek in creek.gd, the worms in inch_worm.gd.

signal leave_requested # Back to the Glenn.

# Tweak these to change how the game feels.
const BERRY_COUNT := 9 # Pick these, then find the golden raspberry to finish.
const READY_TIME := 1.6 # Seconds of "Ready…" before a round starts, when you come in through the gate.
const RESULTS_DELAY := 1.3 # Seconds to enjoy the golden raspberry popping before the Top 10 comes up.
const BERRY_FLOAT := 0.9 # How high the berries float (some over the creek, so you'll have to wade).
const BERRY_TOUCH := 1.0 # How close the middle of the gnome has to come to pick one...
const GOLDEN_TOUCH := 1.3 # ...or the golden one.
const GNOME_MIDDLE := 0.6 # The height of the middle of the gnome, where things touch it.
const WORM_COUNT := 3 # Each starts in a different quarter of the field.
const WORM_MAX_SPEED := 0.9 # A worm's fastest moment, as a share of the gnome's top speed...
const WORM_TOP_SPEED := 0.99 # ...rising with each bonk, up to this.
const WORM_SAFE_DISTANCE := 10.0 # Worms never start closer than this to the gnome.
const WORM_CATCH_DISTANCE := 0.75
const STICK_REACH := 0.44 # How close the stick has to come to a worm's head to bonk it.
const DANGER_FAR := 9.0 # The danger music creeps in when a worm is this close...
const DANGER_NEAR := 3.0 # ...and is at full strength this close.
const FOX_LEAD_SPEED := 0.05 # How slowly the fox leads the way to the golden raspberry, as a share of the gnome's speed.
const HINT := "Follow the fox to the golden raspberry!"
const GOAL := "Pick all 9 raspberries, then follow the fox to the golden one, as fast as you can. Don't let an inch worm catch you! Swing your stick (F, or □) at a worm's head to stun it, though it gets back up a little faster. The creek slows everyone down. R starts the round over."

var hud: Node # Set by main.gd.
var scoreboard: Node

var hold_worms := false # For tests: the worms stay put and can't catch anyone.
var collected := 0
var elapsed := 0.0
var finished := false
var caught_by_worm := false

var _berries: Array[Node3D] = []
var _bobs := {} # Berry -> [float height, bob offset].
var _golden: Node3D
var _golden_out := false
var _golden_height := 0.0
var _worms: Array[InchWorm] = []
var _world_time := 0.0
var _results_in := 0.0
var _ready_in := 0.0

@onready var field: BerryField = $Field
@onready var gnome: CharacterBody3D = $Gnome
@onready var fox: CharacterBody3D = $Fox
@onready var camera_rig: Node3D = $CameraRig
@onready var environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var effects: BerryEffects = $Effects
@onready var _air: Node3D = $Air


func _ready() -> void:
	# The Glenn's haze, but lighter: across an open field you need to spot berries far off.
	var air: Environment = environment.environment.duplicate()
	air.fog_density = 0.0035
	air.volumetric_fog_density = 0.0055
	environment.environment = air
	gnome.can_wave = false
	camera_rig.target = gnome
	fox.friend = gnome
	var keep := BerryField.PLAY_HALF - 0.5
	fox.keep_in = Rect2(-keep, -keep, keep * 2.0, keep * 2.0)
	fox.brain = FoxBrain.new(fox, gnome, camera_rig.camera)
	fox.brain.lead_speed = gnome.MOVE_SPEED * FOX_LEAD_SPEED
	_golden = Raspberry.make_golden()
	_golden.visible = false
	add_child(_golden)
	for i in WORM_COUNT:
		var worm := InchWorm.new()
		worm.field = field
		worm.target = gnome
		add_child(worm)
		_worms.append(worm)
	var detail: Dictionary = Glen.DETAIL[Settings.get_value("graphics")]
	_air.add_child(Atmosphere.fireflies(detail.fireflies))
	_air.add_child(Atmosphere.falling_leaves(detail.leaves))
	Settings.changed.connect(func(name: String) -> void:
		if name == "graphics" and is_inside_tree():
			apply_graphics())


# --- Coming and going (see main.gd) ---

# Main hands over the things on screen that every area shares.
func setup(the_hud: Node, the_scoreboard: Node) -> void:
	hud = the_hud
	scoreboard = the_scoreboard
	scoreboard.play_again.connect(func() -> void: if is_inside_tree(): restart())
	scoreboard.return_to_glenn.connect(func() -> void: if is_inside_tree(): leave_requested.emit())


# Coming in through the gate: a fresh round, with "Ready…" and "Go!".
func enter(_from := "") -> void:
	apply_graphics()
	restart()
	_ready_in = READY_TIME
	hud.show_banner("Berry Rush", "Ready…", true)


# Going back to the Glenn: put the Top 10 away and let the danger music fade.
func leave() -> void:
	scoreboard.hide_board()
	hud.hide_banner()
	hud.hide_hint()
	Sound.set_danger(0.0)


# Pausing by itself (when you switch windows) only makes sense mid-round.
func can_pause() -> bool:
	return not finished


# A round has started and isn't over, so leaving would lose it.
func round_in_progress() -> bool:
	return not finished and elapsed > 0.0


func apply_graphics() -> void:
	var level: String = Settings.get_value("graphics")
	Glen.apply_quality(level, environment.environment, sun, get_viewport())
	field.grow_grass(level)


# --- A round ---

func restart() -> void:
	effects.clear()
	hud.hide_banner()
	_ready_in = 0.0
	gnome.place(Vector3(0, field.floor_at(0, BerryField.START_Z) + 0.05, BerryField.START_Z), PI)
	camera_rig.reset_view(0.0)
	collected = 0
	elapsed = 0.0
	finished = false
	caught_by_worm = false
	_results_in = 0.0
	_golden_out = false
	_golden.visible = false
	scoreboard.hide_board()
	hud.hide_hint()
	field.rng.randomize()
	field.place_obstacles()
	_place_berries()
	_place_worms()
	fox.place(gnome.global_position + Vector3(-1.9, 0, 0.6), PI)
	fox.brain.reset()
	_update_hud()


func _place_berries() -> void:
	for berry in _berries:
		berry.queue_free()
	_berries.clear()
	_bobs.clear()
	var half := BerryField.PLAY_HALF - 1.5
	var rng := field.rng
	for i in BERRY_COUNT:
		var x := 0.0
		var z := 0.0
		for attempt in 200:
			x = rng.randf_range(-half, half)
			z = rng.randf_range(-half, half)
			# Clear of the start, the trees, rocks and logs, and the bridges.
			if Vector2(x, z - BerryField.START_Z).length() >= 3.0 and not field.is_near_obstacle(x, z, 1.0) and not Creek.is_near_bridge(x, z, 1.0, field.bridges):
				break
		var berry := Raspberry.make()
		var height := Creek.terrain_height(x, z) + BERRY_FLOAT
		berry.position = Vector3(x, height, z)
		add_child(berry)
		_berries.append(berry)
		_bobs[berry] = [height, rng.randf() * TAU]


# The golden raspberry appears once all the others are picked, in one of the three quarters of the
# field the gnome isn't in, on dry, open ground. The fox catches its scent.
func _spawn_golden() -> void:
	var here := Vector2(signf(gnome.global_position.x) if gnome.global_position.x != 0.0 else 1.0, signf(gnome.global_position.z) if gnome.global_position.z != 0.0 else 1.0)
	var others := []
	for quarter: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		if quarter != here:
			others.append(quarter)
	var pick: Vector2 = others[field.rng.randi() % others.size()]
	var half := BerryField.PLAY_HALF - 1.5
	var x := 0.0
	var z := 0.0
	for attempt in 200:
		x = pick.x * field.rng.randf_range(1.5, half)
		z = pick.y * field.rng.randf_range(1.5, half)
		if Creek.distance(x, z) > Creek.HALF_WIDTH + 0.5 and not Creek.is_near_bridge(x, z, 1.0, field.bridges) and not field.is_near_obstacle(x, z, 1.2):
			break
	_golden_height = Creek.terrain_height(x, z) + 1.0
	_golden.position = Vector3(x, _golden_height, z)
	_golden.visible = true
	_golden_out = true
	fox.brain.point_to(_golden.position)
	hud.show_hint(HINT)


# Give each worm its own quarter of the field, at a random spot there, lying flat and facing the middle.
func _place_worms() -> void:
	var quarters := []
	var far := BerryField.PLAY_HALF - 4.0
	for worm in _worms:
		if quarters.is_empty():
			quarters = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
		var quarter: Vector2 = quarters.pop_at(field.rng.randi() % quarters.size())
		var head := Vector3.ZERO
		var tail := Vector3.ZERO
		for attempt in 100:
			head = Vector3(quarter.x * field.rng.randf_range(1.0, far), 0, quarter.y * field.rng.randf_range(1.0, far))
			tail = head.normalized() * (head.length() + InchWorm.LENGTH)
			var safe := Vector2(head.x, head.z - BerryField.START_Z).length() >= WORM_SAFE_DISTANCE
			if safe and worm._is_clear(tail, head):
				break
		worm.place(head, tail, gnome.MOVE_SPEED * WORM_MAX_SPEED, gnome.MOVE_SPEED * WORM_TOP_SPEED)


# Either way a round ends, the Top 10 comes up: straight away if a worm caught you, or after a
# moment to enjoy the golden raspberry popping if you picked it.
func _win() -> void:
	finished = true
	_results_in = RESULTS_DELAY


func _caught(worm: InchWorm) -> void:
	if caught_by_worm:
		return # Two worms can reach the gnome in the same moment.
	finished = true
	caught_by_worm = true
	Sound.play_chomp(worm.head_position)
	scoreboard.show_board("berry-rush", -1.0)


func _pick(berry: Node3D, golden: bool, on_gone: Callable) -> void:
	collected += 1
	Sound.play_berry(collected, golden)
	effects.pop(berry, collected, golden, field.floor_at(berry.global_position.x, berry.global_position.z), on_gone)
	hud.bump_berries()


func _update_hud() -> void:
	hud.set_berries(collected, BERRY_COUNT + 1, collected >= BERRY_COUNT)
	hud.set_time(elapsed)


# --- Controls ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if not caught_by_worm and _ready_in <= 0.0 and gnome.swing_stick():
			Sound.play_swing()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and finished and event is InputEventJoypadButton:
		restart() # Options on the Top 10 plays again, as in the three.js game.
		get_viewport().set_input_as_handled()


# --- Every frame ---

func _process(delta: float) -> void:
	_world_time += delta
	field.flicker_lanterns(_world_time)
	# "Ready…" then "Go!": until then the gnome waits at the start and nothing moves.
	var ready := _ready_in <= 0.0
	if not ready:
		_ready_in -= delta
		if _ready_in <= 0.0:
			hud.set_banner_subtitle("Go!", 0.8)
	gnome.can_move = ready and not caught_by_worm and not scoreboard.is_showing
	gnome.speed_scale = Creek.SLOWDOWN if gnome.is_on_floor() and field.in_water(gnome.global_position.x, gnome.global_position.z) else 1.0
	gnome.camera_yaw = camera_rig.yaw
	var middle := gnome.global_position + Vector3(0, GNOME_MIDDLE, 0)

	# Bob and spin the raspberries, and pick any the gnome touches.
	for i in range(_berries.size() - 1, -1, -1):
		var berry := _berries[i]
		var bob: Array = _bobs[berry]
		berry.rotation.y += 1.5 * delta
		berry.position.y = bob[0] + sin(_world_time * 2.5 + bob[1]) * 0.08
		if not finished and ready and berry.global_position.distance_to(middle) < BERRY_TOUCH:
			_berries.remove_at(i)
			_pick(berry, false, berry.queue_free)
			if collected == BERRY_COUNT:
				_spawn_golden()

	# The golden raspberry bobs, spins and shines. Picking it finishes the round.
	if _golden_out:
		_golden.rotation.y += 1.2 * delta
		_golden.position.y = _golden_height + sin(_world_time * 2.0) * 0.12
		var rays: MeshInstance3D = _golden.get_meta("rays")
		rays.set_instance_shader_parameter("turn", _world_time * 0.4)
		rays.scale = Vector3.ONE * (1.0 + sin(_world_time * 3.0) * 0.07)
		if not finished and _golden.global_position.distance_to(middle) < GOLDEN_TOUCH:
			_golden_out = false
			hud.hide_hint()
			fox.brain.stop_pointing()
			_pick(_golden, true, func() -> void: _golden.visible = false)
			_win()
	if _results_in > 0.0:
		_results_in -= delta
		if _results_in <= 0.0:
			scoreboard.show_board("berry-rush", elapsed)

	# A swing of the stick that catches an inch worm on the head stuns it.
	if not finished and gnome.is_striking():
		for worm in _worms:
			if worm.is_dazed():
				continue
			for point in gnome.stick_points():
				if point.distance_to(worm.head_position) < InchWorm.RADIUS * 1.25 + STICK_REACH:
					worm.stun()
					Sound.play_bonk(worm.head_position)
					break

	# The inch worms crawl after the gnome until the round is over. Dazed worms can't catch anyone.
	var nearest := INF
	for worm in _worms:
		worm.update(delta, not finished and ready and not hold_worms)
		if not finished and ready and not hold_worms and not worm.is_dazed() and worm.head_position.distance_to(middle) < WORM_CATCH_DISTANCE:
			_caught(worm)
		if not worm.is_dazed():
			nearest = minf(nearest, worm.head_position.distance_to(middle))
	# Music: the danger layer swells as the nearest wide-awake worm creeps closer.
	Sound.set_danger(0.0 if finished else 1.0 - smoothstep(DANGER_NEAR, DANGER_FAR, nearest))

	if not finished and ready:
		elapsed += delta
	_update_hud()
	field.fade_trees(camera_rig.camera, middle, delta)
	field.push_grass(gnome.global_position)
	_air.global_position = Vector3(gnome.global_position.x, 0, gnome.global_position.z)
