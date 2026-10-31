class_name FoxBrain
extends RefCounted

# What the fox decides to do. It isn't on a lead: every few seconds it picks something from a short
# list, weighted by what the gnome is up to, and does it in its own time:
#   follow  - trot along beside and a little ahead of where the gnome is heading, wandering a bit
#   explore - go and sniff something interesting nearby (a pumpkin, a lantern post, a rock)
#   sniff   - stop, nose to the ground, tail swishing
#   pounce  - crouch, wiggle, and leap nose-first into the long grass
#   sit     - sit and watch the gnome, ears swivelling
#   lie     - lie down with its tail curled round, if the gnome has been still a long while
#   play    - a play bow and a dash round the gnome, when the gnome jumps or swings its stick
#   greet   - bound over, sit and wag, when the gnome waves
# A loose leash keeps it near: it's happy anywhere within LEASH metres of the gnome, heads back
# beyond that, gallops back from further, and if it's ever left far behind (after a gate) it simply
# reappears nearby. It keeps out of the camera's view of the gnome, and inside the Glenn.

const COMFORT := Vector2(1.6, 7.0) # Closest and furthest it likes to be from the gnome.
const GALLOP_BACK := 12.0
const REAPPEAR := 30.0
const PREDICT := 0.9 # Seconds ahead it guesses where the gnome is going.
const INTEREST_REACH := 11.0 # How far from the gnome something can be and still be worth a sniff.
const PLAY_COOLDOWN := 9.0

var fox: CharacterBody3D
var gnome: CharacterBody3D
var camera: Node3D
var interests: Array[Vector3] = [] # Things worth sniffing.

var activity := "follow"
var _time_left := 0.0 # How long the current activity goes on.
var _spot := Vector3.ZERO # Where the current activity happens.
var _side := 1.0 # Which side of the gnome it likes to be: +1 its right, -1 its left.
var _gnome_still := 0.0 # How long the gnome has been standing still.
var _play_cooldown := 0.0
var _greeted := false
var _greet_soon := false # The gnome waved mid-pounce: say hello as soon as it lands.
var _clock := 0.0
var _drift := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


func _init(the_fox: CharacterBody3D, the_gnome: CharacterBody3D, the_camera: Node3D) -> void:
	fox = the_fox
	gnome = the_gnome
	camera = the_camera
	_drift.frequency = 0.15
	_rng.randomize()
	_drift.seed = _rng.randi()
	gnome.waved.connect(_on_waved)


func reset() -> void:
	_start("follow", 2.0)


func think(delta: float) -> void:
	_clock += delta
	_play_cooldown -= delta
	var gnome_speed := Vector2(gnome.velocity.x, gnome.velocity.z).length()
	_gnome_still = _gnome_still + delta if gnome_speed < 0.4 else 0.0
	var away := _flat(gnome.global_position - fox.global_position).length()
	fox.fade(_hides_gnome())

	# The leash, which wins over everything else.
	if away > REAPPEAR:
		fox.place(_clamp(gnome.global_position - _forward() * 2.0 + _right() * _side * 2.0))
		_start("follow", 2.0)
		return
	if away > COMFORT.y and activity not in ["follow", "greet", "play"] and not fox.is_pouncing():
		_start("follow", 3.0)
	# The gnome's off: drop what it's doing and come along.
	if gnome_speed > 2.5 and away > 3.0 and activity in ["sit", "lie", "sniff", "explore", "pounce"] and not fox.is_pouncing():
		_start("follow", 3.0)

	# Something exciting nearby? A jump or a stick swing is an invitation to play.
	if _play_cooldown <= 0.0 and away < 6.0 and activity in ["follow", "sit", "sniff", "explore"] and (gnome.is_swinging() or not gnome.is_on_floor()):
		_play_cooldown = PLAY_COOLDOWN
		if _rng.randf() < 0.6:
			_start("play", 3.2)

	if _greet_soon and not fox.is_pouncing():
		_greet_soon = false
		_start("greet")
	_time_left -= delta
	if _time_left <= 0.0 and not fox.is_pouncing():
		_choose()
	# Settling down somewhere? Not in front of the camera.
	if activity in ["sit", "lie", "sniff", "explore", "pounce"] and _in_view(fox.global_position) and not fox.is_pouncing():
		fox.set_pose("stand")
		fox.walk_to(_out_of_view(fox.global_position), fox.TROT_SPEED)
		fox.look_toward(gnome.global_position + Vector3(0, 1.0, 0))
		return
	call("_do_" + activity, delta, away, gnome_speed)


# Pick what to do next, weighted by what the gnome is doing.
func _choose() -> void:
	var moving := Vector2(gnome.velocity.x, gnome.velocity.z).length() > 1.5
	var weights := {}
	if moving:
		weights = {"follow": 1.0, "sniff": 0.08, "explore": 0.06}
	elif _gnome_still < 4.0:
		weights = {"follow": 0.35, "sit": 0.35, "sniff": 0.2, "explore": 0.2}
	elif _gnome_still < 14.0:
		weights = {"sit": 0.3, "sniff": 0.2, "explore": 0.45, "pounce": 0.2, "follow": 0.1}
	else:
		weights = {"lie": 0.6, "sit": 0.15, "explore": 0.15, "pounce": 0.1}
	if weights.has("explore") and _interest_near() == Vector3.INF:
		weights.erase("explore")
	var total := 0.0
	for choice in weights:
		total += weights[choice]
	var roll := _rng.randf() * total
	for choice in weights:
		roll -= weights[choice]
		if roll <= 0.0:
			_start(choice)
			return
	_start("follow")


func _start(what: String, how_long := -1.0) -> void:
	activity = what
	fox.set_pose("stand")
	fox.wag(0.0)
	fox.face(Vector3.INF)
	var durations := {"follow": Vector2(3.0, 6.0), "sniff": Vector2(1.8, 3.5), "sit": Vector2(4.0, 9.0), "lie": Vector2(8.0, 16.0), "explore": Vector2(6.0, 9.0), "pounce": Vector2(5.0, 6.0), "play": Vector2(3.0, 3.5), "greet": Vector2(3.5, 4.5)}
	var span: Vector2 = durations.get(what, Vector2(3.0, 5.0))
	_time_left = how_long if how_long > 0.0 else _rng.randf_range(span.x, span.y)
	match what:
		"explore":
			_spot = _interest_near()
		"pounce":
			_spot = _out_of_view(fox.global_position + Vector3(sin(fox.heading()), 0, cos(fox.heading())) * 2.5 + Vector3(_rng.randfn(), 0, _rng.randfn()) * 0.8)
		"sniff":
			_spot = fox.global_position
		"play":
			_spot = Vector3.ZERO
			_greeted = false
		"greet":
			_greeted = false


# --- Each activity, every frame ---

func _do_follow(_delta: float, away: float, gnome_speed: float) -> void:
	# Aim for a spot beside and a little ahead of where the gnome will be, drifting about.
	var ahead := gnome.global_position + _flat(gnome.velocity) * PREDICT
	var lead := clampf(gnome_speed / 7.0, 0.0, 1.0)
	var wander := Vector3(_drift.get_noise_2d(_clock, 0.0), 0, _drift.get_noise_2d(0.0, _clock)) * 1.6
	var goal := ahead + _right() * _side * lerpf(2.4, 2.0, lead) + _forward() * lerpf(0.0, 1.4, lead) + wander
	goal = _out_of_view(_clamp(goal))
	# Swap sides if this side is hemmed in by the hedge.
	if _clamp(goal).distance_to(goal) > 0.5:
		_side = -_side
	var pace: float = fox.TROT_SPEED
	if away > GALLOP_BACK * 0.7 or gnome_speed > 5.0:
		pace = fox.GALLOP_SPEED
	elif gnome_speed < 1.0:
		pace = fox.WALK_SPEED * 1.4
	if away < COMFORT.x + 0.4 and gnome_speed < 1.0:
		fox.hold() # Close enough: wait here.
		fox.face(gnome.global_position)
	elif _in_view(fox.global_position) and away > 2.0:
		fox.walk_to(_out_of_view(fox.global_position), pace) # Step out of the camera's way first.
	else:
		fox.walk_to(goal, pace)
	fox.look_toward(gnome.global_position + Vector3(0, 1.0, 0) if fmod(_clock, 5.0) < 1.6 else fox.global_position + Vector3(sin(fox.heading()), 0.4, cos(fox.heading())) * 3.0)
	fox.wag(0.2 if gnome_speed < 1.0 and away < 4.0 else 0.0)


func _do_sniff(_delta: float, _away: float, _gnome_speed: float) -> void:
	fox.hold()
	fox.set_pose("sniff")
	fox.look_toward(_spot + Vector3(sin(fox.heading()), 0, cos(fox.heading())) * 0.9)
	fox.wag(0.1)


func _do_explore(_delta: float, _away: float, _gnome_speed: float) -> void:
	if _spot == Vector3.INF:
		_start("follow")
		return
	var close := _flat(_spot - fox.global_position).length() < 1.3
	if close:
		fox.hold()
		fox.face(_spot)
		fox.set_pose("sniff")
		fox.look_toward(_spot + Vector3(0, 0.2, 0))
	else:
		fox.set_pose("stand")
		fox.walk_to(_spot - _flat(_spot - fox.global_position).normalized() * 0.9, fox.TROT_SPEED * 0.8)
		fox.look_toward(_spot + Vector3(0, 0.5, 0))


func _do_sit(_delta: float, away: float, _gnome_speed: float) -> void:
	if away > COMFORT.y * 0.7:
		fox.set_pose("stand")
		fox.walk_to(_clamp(gnome.global_position + _flat(fox.global_position - gnome.global_position).normalized() * 3.0), fox.TROT_SPEED)
		return
	fox.hold()
	fox.face(gnome.global_position)
	fox.set_pose("sit")
	# Watch the gnome, glancing off at things now and then.
	var glance := fmod(_clock, 6.0) > 4.5
	fox.look_toward(gnome.global_position + Vector3(0, 1.0, 0) if not glance else fox.global_position + Vector3(_drift.get_noise_1d(_clock * 3.0) * 6.0, 0.8, 4.0))


func _do_lie(_delta: float, _away: float, gnome_speed: float) -> void:
	if gnome_speed > 1.0:
		_start("follow") # Up again when the gnome moves off.
		return
	fox.hold()
	fox.set_pose("lie")
	fox.look_toward(gnome.global_position + Vector3(0, 0.6, 0))


func _do_pounce(_delta: float, _away: float, _gnome_speed: float) -> void:
	if fox.is_pouncing():
		return
	var to_spot := _flat(_spot - fox.global_position)
	if to_spot.length() > 2.8:
		fox.set_pose("stand")
		fox.walk_to(_spot, fox.WALK_SPEED * 1.5)
	elif _time_left > 0.8:
		# Creep up, ears pricked, then go.
		fox.hold()
		fox.face(_spot)
		fox.set_pose("stalk")
		fox.look_toward(_spot)
		if absf(angle_difference(fox.heading(), atan2(to_spot.x, to_spot.z))) < 0.15:
			fox.pounce(_spot)
			_time_left = 3.2


func _do_play(delta: float, away: float, _gnome_speed: float) -> void:
	# A play bow facing the gnome, then a quick dash round it.
	if not _greeted:
		fox.hold()
		fox.face(gnome.global_position)
		fox.set_pose("bow")
		fox.wag(1.0)
		fox.look_toward(gnome.global_position + Vector3(0, 0.8, 0))
		if _time_left < 2.0:
			_greeted = true
		return
	fox.set_pose("stand")
	fox.wag(0.8)
	_spot.x += delta * 2.2 # Angle round the gnome.
	var around := gnome.global_position + Vector3(sin(_spot.x), 0, cos(_spot.x)) * clampf(away, 2.5, 3.5)
	fox.walk_to(_clamp(around), fox.GALLOP_SPEED * 0.8)
	fox.look_toward(gnome.global_position + Vector3(0, 0.6, 0))


func _do_greet(_delta: float, away: float, _gnome_speed: float) -> void:
	var front := _out_of_view(gnome.global_position + Vector3(sin(gnome.facing()), 0, cos(gnome.facing())) * 2.0)
	fox.look_toward(gnome.global_position + Vector3(0, 1.1, 0))
	fox.wag(1.0)
	if _flat(front - fox.global_position).length() > 0.6 and not _greeted:
		fox.set_pose("stand")
		fox.walk_to(front, fox.GALLOP_SPEED if away > 5.0 else fox.TROT_SPEED)
	else:
		_greeted = true
		fox.hold()
		fox.face(gnome.global_position)
		fox.set_pose("sit")


func _on_waved() -> void:
	if fox.is_pouncing():
		_greet_soon = true
	else:
		_start("greet")


# --- Helpers ---

# Something to sniff near the gnome, picked at random from the closest few.
func _interest_near() -> Vector3:
	var near: Array[Vector3] = []
	for spot in interests:
		if _flat(spot - gnome.global_position).length() < INTEREST_REACH and keep_in().has_point(Vector2(spot.x, spot.z)) and not _in_view(spot):
			near.append(spot)
	if near.is_empty():
		return Vector3.INF
	return near[_rng.randi() % near.size()]


func keep_in() -> Rect2:
	return fox.keep_in


func _clamp(at: Vector3) -> Vector3:
	var rect := keep_in()
	return Vector3(clampf(at.x, rect.position.x + 0.6, rect.end.x - 0.6), at.y, clampf(at.z, rect.position.y + 0.6, rect.end.y - 0.6))


# Is a spot in the way of the camera's view of the gnome?
func _in_view(at: Vector3) -> bool:
	if camera == null:
		return false
	var to_camera := _flat(camera.global_position - gnome.global_position).normalized()
	var offset := _flat(at - gnome.global_position)
	return offset.length() < 6.0 and offset.normalized().dot(to_camera) > 0.6


# Is the fox actually covering the gnome on screen? (Then it fades, so you can still see the gnome.)
func _hides_gnome() -> bool:
	var view := camera as Camera3D
	if view == null:
		return false
	var fox_middle := fox.global_position + Vector3(0, 0.7, 0)
	var gnome_middle := gnome.global_position + Vector3(0, 0.7, 0)
	if view.is_position_behind(fox_middle) or view.global_position.distance_to(fox_middle) > view.global_position.distance_to(gnome_middle):
		return false
	var apart := view.unproject_position(fox_middle).distance_to(view.unproject_position(gnome_middle))
	return apart < view.get_viewport().get_visible_rect().size.y * 0.09


# Keep out of the line between the camera and the gnome, so the fox never hides the player.
func _out_of_view(at: Vector3) -> Vector3:
	if camera == null:
		return at
	var to_camera := _flat(camera.global_position - gnome.global_position).normalized()
	var offset := _flat(at - gnome.global_position)
	if _in_view(at):
		var across := Vector3(-to_camera.z, 0, to_camera.x) * (1.0 if offset.dot(Vector3(-to_camera.z, 0, to_camera.x)) >= 0.0 else -1.0)
		at = gnome.global_position + across * 2.4 - to_camera * 0.5
	return _clamp(at)


func _forward() -> Vector3:
	return Vector3(sin(gnome.facing()), 0, cos(gnome.facing()))


func _right() -> Vector3:
	var forward := _forward()
	return Vector3(-forward.z, 0, forward.x)


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)
