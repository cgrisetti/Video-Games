## Reads one local controller and turns it into commands, in one of three
## assist modes (02_COMBAT_GDD.md §4):
##   Master         full manual chords, 400 ms buffer, +15% flow speed
##   Adventurer     550 ms buffer, soft-lock camera, basic auto-combo chaining
##   Squire Gambit  one-button smart combos and an auto-evade safety net
## Device 0 is the keyboard; joypad n is device n + 1.
class_name InputComponent
extends Node

signal command_issued(command: int)
signal tether_slot_pressed(slot: int)
signal class_cycle_requested
signal mode_cycle_requested

enum AssistMode { MASTER, ADVENTURER, SQUIRE_GAMBIT }

const MODE_NAMES: Array[String] = ["Master", "Adventurer", "Squire Gambit"]
const KEYBOARD_DEVICE: int = 0
const STICK_DEADZONE: float = 0.22
const TRIGGER_THRESHOLD: float = 0.45
## L and R pressed this close together read as the ultimate (both triggers).
const CHORD_WINDOW: float = 0.09
## Holding R this long fires the R-hold skill (the healer's Green Sanctuary).
const R_HOLD_TIME: float = 0.45
const MASTER_BUFFER_WINDOW: float = 0.40
const ASSISTED_BUFFER_WINDOW: float = 0.55
const MASTER_FLOW_SPEED_BONUS: float = 0.15
## Squire Gambit dodges out of a red telegraph once it is this full.
const AUTO_EVADE_FILL: float = 0.85
const AUTO_EVADE_COOLDOWN: float = 0.8
## Beyond this distance the assisted modes open with a gap-closing forward heavy.
const GAP_CLOSE_DISTANCE: float = 4.5
## Squire healer heals anyone below this share of their health.
const SQUIRE_HEAL_BELOW: float = 0.7
## Stick past this toward/away from the target turns heavy into a directional heavy.
const DIRECTIONAL_THRESHOLD: float = 0.5

var device_id: int = KEYBOARD_DEVICE
var assist_mode: AssistMode = AssistMode.ADVENTURER
var actor: ActorBase
## Stick or WASD, x = right, y = forward, relative to this player's camera.
var move_input: Vector2 = Vector2.ZERO
var camera_orbit_input: float = 0.0

var _held: Dictionary[StringName, bool] = {}
var _was_held: Dictionary[StringName, bool] = {}
var _pending_trigger: StringName = &""
var _pending_time: float = 0.0
var _chord_lock: bool = false
var _r_tracking: bool = false
var _r_held_time: float = 0.0
var _r_hold_fired: bool = false
var _auto_evade_cooldown: float = 0.0
var _squire_primer_turn: int = 0
# Tests and bots drive the component through these instead of a device.
var _scripted: bool = false
var _scripted_commands: Array[int] = []
var _scripted_move: Vector2 = Vector2.ZERO
var _scripted_guard: bool = false


func setup(owner_actor: ActorBase, for_device: int, mode: AssistMode) -> void:
	actor = owner_actor
	device_id = for_device
	assist_mode = mode
	name = "InputComponent"


# --- Mode rules -----------------------------------------------------------

func buffer_window() -> float:
	return MASTER_BUFFER_WINDOW if assist_mode == AssistMode.MASTER else ASSISTED_BUFFER_WINDOW


func flow_speed_bonus() -> float:
	return MASTER_FLOW_SPEED_BONUS if assist_mode == AssistMode.MASTER else 0.0


func assisted_chaining() -> bool:
	return assist_mode != AssistMode.MASTER


func soft_lock_camera() -> bool:
	return assist_mode != AssistMode.MASTER


func mode_name() -> String:
	return MODE_NAMES[assist_mode]


func device_label() -> String:
	return "Keyboard" if device_id == KEYBOARD_DEVICE else "Pad %d" % device_id


func is_keyboard() -> bool:
	return device_id == KEYBOARD_DEVICE


## L held as a posture (Active Guard), once it's clear it isn't half of an ult chord.
func is_guard_held() -> bool:
	if _scripted:
		return _scripted_guard
	return _held.get(&"trigger_l", false) and not _chord_lock and _pending_trigger != &"trigger_l"


# --- Scripted input -------------------------------------------------------

func inject_command(command: int) -> void:
	_scripted = true
	_scripted_commands.append(command)


func inject_move(direction: Vector2) -> void:
	_scripted = true
	_scripted_move = direction.limit_length(1.0)


func inject_guard(held: bool) -> void:
	_scripted = true
	_scripted_guard = held


# --- Polling --------------------------------------------------------------

func poll(dt: float) -> void:
	_was_held = _held
	_held = _read_buttons()
	if _scripted:
		move_input = _scripted_move
		camera_orbit_input = 0.0
	else:
		move_input = _read_move()
		camera_orbit_input = _read_orbit()

	if _pressed(&"class"):
		class_cycle_requested.emit()
	if _pressed(&"mode"):
		mode_cycle_requested.emit()
	for slot: int in 4:
		if _pressed(StringName("tether_%d" % slot)):
			tether_slot_pressed.emit(slot)
	if _pressed(&"light"):
		_issue_attack(CombatActionResource.Command.LIGHT)
	if _pressed(&"heavy"):
		_issue_attack(CombatActionResource.Command.HEAVY)
	if _pressed(&"dodge"):
		_issue(CombatActionResource.Command.DODGE)
	if _pressed(&"ult"):
		_issue(CombatActionResource.Command.TRIGGER_BOTH_ULT)
	_update_triggers(dt)
	_update_auto_evade(dt)

	while not _scripted_commands.is_empty():
		_issue(_scripted_commands.pop_front())


func _issue(command: int) -> void:
	command_issued.emit(command)


func _issue_attack(base: int) -> void:
	if assist_mode == AssistMode.SQUIRE_GAMBIT:
		_issue(_squire_pick())
		return
	var command: int = base
	if base == CombatActionResource.Command.HEAVY:
		var direction: int = actor.directional_intent(DIRECTIONAL_THRESHOLD)
		if direction > 0:
			command = CombatActionResource.Command.FORWARD_HEAVY
		elif direction < 0:
			command = CombatActionResource.Command.BACK_HEAVY
		elif assist_mode == AssistMode.ADVENTURER and not actor.action_queue.is_busy() \
				and actor.distance_to_soft_target() > GAP_CLOSE_DISTANCE \
				and actor.loadout.has_opener(CombatActionResource.Command.FORWARD_HEAVY):
			command = CombatActionResource.Command.FORWARD_HEAVY
	_issue(command)


## Triggers wait a moment for the other trigger so that L+R reads as the ult.
func _update_triggers(dt: float) -> void:
	var l_held: bool = _held.get(&"trigger_l", false)
	var r_held: bool = _held.get(&"trigger_r", false)
	if _chord_lock:
		if not l_held and not r_held:
			_chord_lock = false
		return
	var l_pressed: bool = _pressed(&"trigger_l")
	var r_pressed: bool = _pressed(&"trigger_r")
	var chord: bool = (l_pressed and (r_pressed or _pending_trigger == &"trigger_r")) \
		or (r_pressed and _pending_trigger == &"trigger_l")
	if chord:
		_pending_trigger = &""
		_r_tracking = false
		_chord_lock = true
		_issue(CombatActionResource.Command.TRIGGER_BOTH_ULT)
		return
	if l_pressed:
		_pending_trigger = &"trigger_l"
		_pending_time = CHORD_WINDOW
	elif r_pressed:
		_pending_trigger = &"trigger_r"
		_pending_time = CHORD_WINDOW

	if _pending_trigger != &"":
		_pending_time -= dt
		if _pending_time <= 0.0:
			var which: StringName = _pending_trigger
			_pending_trigger = &""
			if which == &"trigger_l":
				# A guard class holds L as a posture instead (see is_guard_held).
				if not actor.loadout.guard_on_trigger_l:
					_issue(CombatActionResource.Command.TRIGGER_L_SKILL)
			elif actor.loadout.has_opener(CombatActionResource.Command.TRIGGER_R_HOLD):
				_r_tracking = true
				_r_held_time = CHORD_WINDOW
				_r_hold_fired = false
			else:
				_issue(CombatActionResource.Command.TRIGGER_R_SKILL)

	if _r_tracking:
		if r_held:
			_r_held_time += dt
			if not _r_hold_fired and _r_held_time >= R_HOLD_TIME:
				_r_hold_fired = true
				_issue(CombatActionResource.Command.TRIGGER_R_HOLD)
		else:
			if not _r_hold_fired:
				_issue(CombatActionResource.Command.TRIGGER_R_SKILL)
			_r_tracking = false


## Squire Gambit safety net: roll out of a red telegraph that's nearly full.
func _update_auto_evade(dt: float) -> void:
	_auto_evade_cooldown = maxf(0.0, _auto_evade_cooldown - dt)
	if assist_mode != AssistMode.SQUIRE_GAMBIT or _auto_evade_cooldown > 0.0:
		return
	var danger: RaidTelegraphDecal = CombatDirector.current.hostile_telegraph_at(actor.global_position, AUTO_EVADE_FILL)
	if danger == null or actor.stats.stamina < actor.loadout.dodge.stamina_cost:
		return
	var away: Vector3 = actor.global_position - danger.global_position
	away.y = 0.0
	if away.length() < 0.1:
		away = -actor.facing_vector()
	actor.evade_direction = away.normalized()
	_auto_evade_cooldown = AUTO_EVADE_COOLDOWN
	_issue(CombatActionResource.Command.DODGE)


## Squire Gambit: one button, and the game picks the smartest move for your role.
func _squire_pick() -> int:
	var target: ActorBase = actor.soft_target()
	var distance: float = actor.distance_to_soft_target()
	match actor.role():
		ClassLoadoutResource.Role.HEALER:
			var hurt: ActorBase = actor.most_hurt_ally(SQUIRE_HEAL_BELOW)
			if hurt != null and actor.tether != null:
				actor.tether.bind_actor(hurt)
				return CombatActionResource.Command.TRIGGER_R_SKILL
		ClassLoadoutResource.Role.TANK:
			if target != null and target.threat != null and target.threat.current_target != &"" \
					and target.threat.current_target != actor.player_id and actor.stats.resonance_pips() >= 1:
				return CombatActionResource.Command.TRIGGER_R_SKILL
		ClassLoadoutResource.Role.DPS:
			if target != null and distance <= GAP_CLOSE_DISTANCE and CombatDirector.current.primer_on(target) == CombatActionResource.Synergy.NONE:
				var primers: Array[int] = [
					CombatActionResource.Command.FORWARD_HEAVY,
					CombatActionResource.Command.BACK_HEAVY,
					CombatActionResource.Command.TRIGGER_L_SKILL,
				]
				_squire_primer_turn = (_squire_primer_turn + 1) % primers.size()
				return primers[_squire_primer_turn]
	if distance > GAP_CLOSE_DISTANCE and actor.loadout.has_opener(CombatActionResource.Command.FORWARD_HEAVY):
		return CombatActionResource.Command.FORWARD_HEAVY
	return CombatActionResource.Command.LIGHT


# --- Devices --------------------------------------------------------------

func _pressed(button: StringName) -> bool:
	return _held.get(button, false) and not _was_held.get(button, false)


func _read_buttons() -> Dictionary[StringName, bool]:
	var held: Dictionary[StringName, bool] = {}
	if _scripted:
		return held
	if device_id == KEYBOARD_DEVICE:
		held[&"light"] = Input.is_physical_key_pressed(KEY_J)
		held[&"heavy"] = Input.is_physical_key_pressed(KEY_K)
		held[&"dodge"] = Input.is_physical_key_pressed(KEY_SPACE)
		held[&"trigger_l"] = Input.is_physical_key_pressed(KEY_Q)
		held[&"trigger_r"] = Input.is_physical_key_pressed(KEY_E)
		held[&"ult"] = Input.is_physical_key_pressed(KEY_R)
		held[&"tether_0"] = Input.is_physical_key_pressed(KEY_1)
		held[&"tether_1"] = Input.is_physical_key_pressed(KEY_2)
		held[&"tether_2"] = Input.is_physical_key_pressed(KEY_3)
		held[&"tether_3"] = Input.is_physical_key_pressed(KEY_4)
		held[&"class"] = Input.is_physical_key_pressed(KEY_TAB)
		held[&"mode"] = Input.is_physical_key_pressed(KEY_M)
		return held
	var pad: int = device_id - 1
	held[&"light"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_X)
	held[&"heavy"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_Y)
	held[&"dodge"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_A) or Input.is_joy_button_pressed(pad, JOY_BUTTON_B)
	held[&"trigger_l"] = Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_THRESHOLD \
		or Input.is_joy_button_pressed(pad, JOY_BUTTON_LEFT_SHOULDER)
	held[&"trigger_r"] = Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_THRESHOLD \
		or Input.is_joy_button_pressed(pad, JOY_BUTTON_RIGHT_SHOULDER)
	held[&"ult"] = false
	held[&"tether_0"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_UP)
	held[&"tether_1"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_RIGHT)
	held[&"tether_2"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_DOWN)
	held[&"tether_3"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_LEFT)
	held[&"class"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_BACK)
	held[&"mode"] = Input.is_joy_button_pressed(pad, JOY_BUTTON_RIGHT_STICK)
	return held


func _read_move() -> Vector2:
	if device_id == KEYBOARD_DEVICE:
		var keys: Vector2 = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S)))
		return keys.limit_length(1.0)
	var pad: int = device_id - 1
	var stick: Vector2 = Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), -Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
	return _apply_deadzone(stick)


func _read_orbit() -> float:
	if device_id == KEYBOARD_DEVICE:
		return float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
	var pad: int = device_id - 1
	return _apply_deadzone(Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), 0.0)).x


func _apply_deadzone(stick: Vector2) -> Vector2:
	var length: float = stick.length()
	if length < STICK_DEADZONE:
		return Vector2.ZERO
	return stick / length * minf(1.0, inverse_lerp(STICK_DEADZONE, 1.0, length))
