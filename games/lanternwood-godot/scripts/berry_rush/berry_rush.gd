class_name BerryRush
extends Node3D

# Berry Rush: Lanternwood's first game. A raspberry glade ringed by a hedge, with a creek, three
# hungry rainbow inch worms, and a golden raspberry to finish. You come in through the garden gate
# at the south end. "Ready…", then "Go!": pick all 9 raspberries, then follow the fox to the golden
# one, as fast as you can, without an inch worm catching you. Swing your stick at a worm's head to
# stun it (it gets up a little faster). The fastest times go in the Top 10.
# The worms start asleep and wake one at a time as you pick berries, so the pressure builds toward
# the golden raspberry.
# The big moments land: a bonk freezes the picture for a blink with a little shake, and a worm
# catching you plays out in slow motion, zoomed in on the worm. (Shaking can be turned off in Settings.)
# Today's Glade: the same field for everyone all day (its layout comes from the date), with its own
# Top 10 that starts fresh each day. Switch to it from the menu or the Top 10.
#
# Everything about how the game plays is the same as the three.js Berry Rush; the field is new.
# The field and its obstacles are in field.gd, the creek in creek.gd, the worms in inch_worm.gd.

signal leave_requested # Back to the Glenn.

# Tweak these to change how the game feels.
const BERRY_COUNT := 9 # Pick these, then find the golden raspberry to finish.
const READY_TIME := 1.6 # Seconds of "Ready…" before a round starts, when you come in through the gate.
const RESULTS_DELAY := 1.3 # Seconds to enjoy the golden raspberry popping before the Top 10 comes up.
const BERRY_FLOAT := 0.9 # How high the berries float (some over the creek, so you'll have to wade).
const BERRY_SPACING := 5.0 # Berries are never closer together than this.
const WORM_BERRY_GAP := 4.0 # Worms never start this close to a berry.
# Medal times for each field, worked out from a sensible route through its berries ("par": that
# route at full speed, as the crow flies) times these. A spread-out field gets easier medal times.
const MEDALS := {"gold": 1.8, "silver": 2.4, "bronze": 3.2}
const GOLDEN_LEG := 15.0 # The golden raspberry's not out yet when the route is planned: allow this far.
const MEDAL_WORDS := {"gold": "Gold medal!", "silver": "Silver medal!", "bronze": "Bronze medal!"}
const BERRY_TOUCH := 1.0 # How close the middle of the gnome has to come to pick one...
const GOLDEN_TOUCH := 1.3 # ...or the golden one.
const GNOME_MIDDLE := 0.6 # The height of the middle of the gnome, where things touch it.
const WORM_COUNT := 3 # Each starts in a different quarter of the field.
const WAKE_AFTER := [0, 3, 6] # A worm wakes at "Go!", the next after your 3rd berry, the last after your 6th.
const WORM_MAX_SPEED := 0.9 # A worm's fastest moment, as a share of the gnome's top speed...
const WORM_TOP_SPEED := 0.99 # ...rising with each bonk, up to this.
const WORM_SAFE_DISTANCE := 10.0 # Worms never start closer than this to the gnome.
const WORM_CATCH_DISTANCE := 0.75
const STICK_REACH := 0.44 # How close the stick has to come to a worm's head to bonk it.
const DANGER_FAR := 9.0 # The danger music creeps in when a worm is this close...
const DANGER_NEAR := 3.0 # ...and is at full strength this close.
const HIT_STOP := 0.06 # Real seconds the picture all but freezes when the stick lands...
const BONK_SHAKE := 0.55 # ...with this much shake (0 to 1).
const CAUGHT_SLOW := 0.3 # Caught by a worm: time runs this slow...
const CAUGHT_TIME := 1.2 # ...for this many real seconds, zoomed in on the worm, then the Top 10 comes up.
const CAUGHT_SHAKE := 0.4
const FOX_LEAD_SPEED := 0.85 # How fast the fox lopes ahead to the golden raspberry, as a share of the gnome's speed.
const HINT := "Follow the fox to the golden raspberry!"
const GOAL := "Pick all 9 raspberries, then follow the fox to the golden one, as fast as you can. The inch worms wake up one by one as you pick: don't let one catch you! Swing your stick (F, or □) at a worm's head to stun it, though it gets back up a little faster. The creek slows everyone down. R starts the round over. Try Today's Glade too (from this menu or the Top 10): one field all day, the same for everyone, with its own Top 10."

var hud: Node # Set by main.gd.
var scoreboard: Node

var hold_worms := false # For tests: the worms stay put and can't catch anyone.
var layout_seed := 0 # The round's layout comes from this: the same seed always makes the same field.
var daily := false # Playing Today's Glade.
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
var _caught_in := 0.0 # Real seconds of slow motion left before the Top 10, after being caught.
var _time_turn := 0 # Which slow-down is the latest, so an older one doesn't put time back early.
var _compass: BerryCompass
var medal_times := {} # "gold", "silver", "bronze" -> seconds, for this field.
var _gold_splits := PackedFloat32Array() # Gold pace: when each berry should be picked by.

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
	# The berry compass, over the game but under the menus.
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	_compass = BerryCompass.new()
	_compass.camera = camera_rig.camera
	layer.add_child(_compass)
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
	scoreboard.switch_pressed.connect(func() -> void: if is_inside_tree(): set_daily(not daily))


# Coming in through the gate: a fresh round, with "Ready…" and "Go!".
func enter(_from := "") -> void:
	apply_graphics()
	restart()
	_ready_in = READY_TIME
	hud.show_banner(_title(), "Ready…", true)


# Switch between Today's Glade and a new field every round, starting a fresh round with "Ready…".
func set_daily(on: bool) -> void:
	daily = on
	restart()
	_ready_in = READY_TIME
	hud.show_banner(_title(), "Ready…", true)


# The menu's own row for Berry Rush: switching fields.
func menu_row() -> Dictionary:
	return {"text": "Play a new field" if daily else "Play Today's Glade", "action": set_daily.bind(not daily)}


# Which Top 10 this round goes in.
func board() -> String:
	return "berry-rush-daily" if daily else "berry-rush"


# Today's Glade's layout, from the date: the same all day, for everyone.
static func daily_seed(date: String) -> int:
	return ("Berry Rush " + date).hash() & 0x7fffffff


func _title() -> String:
	return "Today's Glade" if daily else "Berry Rush"


func _switch_text() -> String:
	return "A new field" if daily else "Today's Glade"


# Going back to the Glenn: put the Top 10 away and let the danger music fade.
func leave() -> void:
	_set_time(1.0)
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

# A new round. With `layout` it uses that seed for the field; otherwise a new one.
func restart(layout := -1) -> void:
	_set_time(1.0)
	_caught_in = 0.0
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
	if layout >= 0:
		layout_seed = layout
	elif daily:
		layout_seed = daily_seed(Scores.today())
	else:
		layout_seed = randi()
	field.rng.seed = layout_seed
	field.place_obstacles()
	_place_berries()
	_place_worms()
	_plan_medals()
	fox.place(gnome.global_position + Vector3(-1.9, 0, 0.6), PI)
	fox.brain.reset()
	_update_hud()


# The raspberries, spread fairly: the field is split into a 3 × 3 grid with one berry in each
# square, never two close together, and one of them always floats over the creek (a choice: wade
# for it, or go round). Every berry is clear of the start, the trees, rocks and logs, and the bridges.
func _place_berries() -> void:
	for berry in _berries:
		berry.queue_free()
	_berries.clear()
	_bobs.clear()
	var rng := field.rng
	var half := BerryField.PLAY_HALF - 1.5
	var cell := half * 2.0 / 3.0
	var cells := []
	for row in 3:
		for column in 3:
			cells.append(Vector2(column, row))
	# The square the creek crosses most gets the berry over the water.
	var wet_cell := -1
	var wettest := 0
	for i in cells.size():
		var wet := 0
		for k in 25:
			var p := _in_cell(cells[i], cell, half, Vector2((k % 5 + 0.5) / 5.0, (k / 5 + 0.5) / 5.0))
			if Creek.distance(p.x, p.y) < Creek.BED_HALF_WIDTH:
				wet += 1
		if wet > wettest:
			wettest = wet
			wet_cell = i
	var spots: Array[Vector2] = []
	for i in cells.size():
		var spot := Vector2.INF
		for attempt in 120:
			var p := _in_cell(cells[i], cell, half, Vector2(rng.randf_range(0.08, 0.92), rng.randf_range(0.08, 0.92)))
			if i == wet_cell and attempt < 80 and Creek.distance(p.x, p.y) > Creek.BED_HALF_WIDTH * 0.8:
				continue # Keep looking for a spot over the water first.
			if _good_berry_spot(p, spots, BERRY_SPACING if attempt < 90 else 2.0):
				spot = p
				break
		if spot == Vector2.INF:
			# This square's too crowded (trees, the creek): anywhere fair in the field will do.
			for attempt in 300:
				var p := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
				if _good_berry_spot(p, spots, 3.0 if attempt < 200 else 1.5):
					spot = p
					break
		if spot == Vector2.INF:
			continue
		spots.append(spot)
		var berry := Raspberry.make()
		var height := Creek.terrain_height(spot.x, spot.y) + BERRY_FLOAT
		berry.position = Vector3(spot.x, height, spot.y)
		add_child(berry)
		_berries.append(berry)
		_bobs[berry] = [height, rng.randf() * TAU]


func _in_cell(cell: Vector2, size: float, half: float, at: Vector2) -> Vector2:
	return Vector2(-half + (cell.x + at.x) * size, -half + (cell.y + at.y) * size)


func _good_berry_spot(p: Vector2, others: Array[Vector2], spacing: float) -> bool:
	if Vector2(p.x, p.y - BerryField.START_Z).length() < 3.0:
		return false
	if field.is_near_obstacle(p.x, p.y, 1.0) or Creek.is_near_bridge(p.x, p.y, 1.0, field.bridges):
		return false
	for other in others:
		if other.distance_to(p) < spacing:
			return false
	return true


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
			for berry in _berries:
				if Vector2(berry.position.x - head.x, berry.position.z - head.z).length() < WORM_BERRY_GAP:
					safe = false
			if safe and worm._is_clear(tail, head):
				break
		worm.place(head, tail, gnome.MOVE_SPEED * WORM_MAX_SPEED, gnome.MOVE_SPEED * WORM_TOP_SPEED)
		worm.sleep()


# Wake the worms in turn, as the berries are picked (WAKE_AFTER). The one furthest from the gnome
# gets up, so a worm never wakes right on top of you. A worm you bonk awake early counts.
func _wake_worms() -> void:
	var due := 0
	for after: int in WAKE_AFTER:
		if collected >= after:
			due += 1
	var awake := 0
	for worm in _worms:
		if not worm.asleep:
			awake += 1
	while awake < due:
		var furthest: InchWorm = null
		for worm in _worms:
			if worm.asleep and (furthest == null or worm.head_position.distance_to(gnome.global_position) > furthest.head_position.distance_to(gnome.global_position)):
				furthest = worm
		if furthest == null:
			return
		furthest.wake()
		awake += 1


# Either way a round ends, the Top 10 comes up: straight away if a worm caught you, or after a
# moment to enjoy the golden raspberry popping if you picked it.
func _win() -> void:
	finished = true
	_results_in = RESULTS_DELAY


# The medal this time earns ("gold", "silver", "bronze"), or "" for none.
func medal_for(time: float) -> String:
	for medal in ["gold", "silver", "bronze"]:
		if time <= medal_times.get(medal, 0.0):
			return medal
	return ""


# Plan a sensible route: from the start to the nearest berry, then the nearest one from there, and
# so on, then on to the golden raspberry. That route at the gnome's full speed is "par", and the
# medal times are par times MEDALS. Gold pace is when each berry would be picked on a gold run.
func _plan_medals() -> void:
	var at := Vector2(0, BerryField.START_Z)
	var left: Array[Vector2] = []
	for berry in _berries:
		left.append(Vector2(berry.position.x, berry.position.z))
	var legs := PackedFloat32Array()
	while not left.is_empty():
		var nearest := 0
		for i in left.size():
			if left[i].distance_to(at) < left[nearest].distance_to(at):
				nearest = i
		var leg := left[nearest].distance_to(at)
		if Creek.distance((left[nearest].x + at.x) / 2.0, (left[nearest].y + at.y) / 2.0) < Creek.HALF_WIDTH:
			leg += Creek.HALF_WIDTH * 2.0 * (1.0 / Creek.SLOWDOWN - 1.0) # Wading is slow.
		legs.append(leg)
		at = left.pop_at(nearest)
	legs.append(GOLDEN_LEG)
	var total := 0.0
	for leg in legs:
		total += leg
	var par: float = total / gnome.MOVE_SPEED
	for medal in MEDALS:
		medal_times[medal] = ceilf(par * MEDALS[medal])
	_gold_splits.clear()
	var so_far := 0.0
	for leg in legs:
		so_far += leg
		_gold_splits.append(medal_times.gold * so_far / total)
	hud.show_medals(medal_times.gold, medal_times.silver, medal_times.bronze, "Today's Glade" if daily else "")


# Caught! Time slows and the camera turns and zooms in on the worm, then the Top 10 comes up.
func _caught(worm: InchWorm) -> void:
	if caught_by_worm:
		return # Two worms can reach the gnome in the same moment.
	finished = true
	caught_by_worm = true
	Sound.play_chomp(worm.head_position)
	camera_rig.focus = worm.head_position
	_shake(CAUGHT_SHAKE)
	_set_time(CAUGHT_SLOW, CAUGHT_TIME)
	_caught_in = CAUGHT_TIME


# Slow time down (or all but stop it) for `real_seconds` of real time, or put it back with 1.0.
func _set_time(scale: float, real_seconds := 0.0) -> void:
	_time_turn += 1
	Engine.time_scale = scale
	if scale < 1.0 and real_seconds > 0.0:
		var turn := _time_turn
		get_tree().create_timer(real_seconds, true, false, true).timeout.connect(func() -> void:
			if turn == _time_turn:
				Engine.time_scale = 1.0)


func _shake(amount: float) -> void:
	if Settings.get_value("screen_shake"):
		camera_rig.shake(amount)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _pick(berry: Node3D, golden: bool, on_gone: Callable) -> void:
	collected += 1
	Sound.play_berry(collected, golden)
	effects.pop(berry, collected, golden, field.floor_at(berry.global_position.x, berry.global_position.z), on_gone)
	hud.bump_berries()
	# How you're doing against gold pace.
	if collected <= _gold_splits.size():
		hud.show_split(elapsed - _gold_splits[collected - 1])


func _update_hud() -> void:
	hud.set_berries(collected, BERRY_COUNT + 1, collected >= BERRY_COUNT)
	hud.set_time(elapsed, medal_for(elapsed) if not caught_by_worm else "")


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
			scoreboard.show_board(board(), elapsed, MEDAL_WORDS.get(medal_for(elapsed), ""), _switch_text())
	if _caught_in > 0.0:
		_caught_in -= delta / maxf(Engine.time_scale, 0.001) # Real time, through the slow motion.
		if _caught_in <= 0.0:
			_set_time(1.0)
			scoreboard.show_board(board(), -1.0, "", _switch_text())

	# A swing of the stick that catches an inch worm on the head stuns it.
	if not finished and gnome.is_striking():
		for worm in _worms:
			if worm.is_dazed():
				continue
			for point in gnome.stick_points():
				if point.distance_to(worm.head_position) < InchWorm.RADIUS * 1.25 + STICK_REACH:
					worm.stun()
					Sound.play_bonk(worm.head_position)
					_shake(BONK_SHAKE)
					if not caught_by_worm:
						_set_time(0.03, HIT_STOP) # A blink of a freeze, so the bonk lands.
					break

	# The inch worms wake in turn and crawl after the gnome until the round is over. Sleeping and
	# dazed worms can't catch anyone.
	if not finished and ready and not hold_worms:
		_wake_worms()
	var nearest := INF
	for worm in _worms:
		worm.update(delta, not finished and ready and not hold_worms)
		if not finished and ready and not hold_worms and not worm.is_dazed() and not worm.is_sleeping() and worm.head_position.distance_to(middle) < WORM_CATCH_DISTANCE:
			_caught(worm)
		if not worm.is_dazed() and not worm.asleep:
			nearest = minf(nearest, worm.head_position.distance_to(middle))
		if not finished and ready and not hold_worms and worm.notice(worm.head_position.distance_to(middle)):
			Sound.play_alert(worm.head_position) # "!": it's seen you.
	# Music: the danger layer swells as the nearest wide-awake worm creeps closer.
	Sound.set_danger(0.0 if finished else 1.0 - smoothstep(DANGER_NEAR, DANGER_FAR, nearest))

	if not finished and ready:
		elapsed += delta
	_update_hud()
	_compass.visible = not finished and not scoreboard.is_showing
	_compass.berries = _berries
	_compass.golden = _golden if _golden_out else null
	_compass.from = gnome.global_position
	field.fade_trees(camera_rig.camera, middle, delta)
	field.push_grass(gnome.global_position)
	_air.global_position = Vector3(gnome.global_position.x, 0, gnome.global_position.z)
