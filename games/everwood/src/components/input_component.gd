## Reads one local controller and turns it into commands, in one of three
## assist modes (02_COMBAT_GDD.md §4):
##   Master         full manual chords, 400 ms buffer, +15% flow speed
##   Adventurer     550 ms buffer, soft-lock camera, basic auto-combo chaining
##   Squire Gambit  one-button smart combos and an auto-evade safety net
##
## Bindings live in project.godot's Input Map (written by
## tools/build_input_map.gd). Every action listens on every device; this
## component evaluates them for its own device only, so four players can share
## one machine. Device 0 is the keyboard and mouse; joypad n is device n + 1.
##
## While a menu is open on this player's screen (the Shard Vendor), the same
## controller drives the menu instead of the character (menu_input).
class_name InputComponent
extends Node

signal command_issued(command: int)
signal tether_slot_pressed(slot: int)
signal class_cycle_requested
signal mode_cycle_requested
## Up / down / accept / back for an open menu (MENU_* below).
signal menu_input(action: StringName)

enum AssistMode { MASTER, ADVENTURER, SQUIRE_GAMBIT }
enum PadFamily { KEYBOARD, XBOX, PLAYSTATION }

# Input Map action names (see tools/build_input_map.gd for the bindings).
const ACTION_MOVE_LEFT: StringName = &"player_move_left"
const ACTION_MOVE_RIGHT: StringName = &"player_move_right"
const ACTION_MOVE_FORWARD: StringName = &"player_move_forward"
const ACTION_MOVE_BACK: StringName = &"player_move_back"
const ACTION_CAMERA_LEFT: StringName = &"player_camera_left"
const ACTION_CAMERA_RIGHT: StringName = &"player_camera_right"
const ACTION_LIGHT: StringName = &"player_light"
const ACTION_HEAVY: StringName = &"player_heavy"
const ACTION_DODGE: StringName = &"player_dodge"
const ACTION_TRIGGER_L: StringName = &"player_trigger_l"
const ACTION_TRIGGER_R: StringName = &"player_trigger_r"
const ACTION_ULT: StringName = &"player_ult"
const ACTION_TETHER_UP: StringName = &"player_tether_up"
const ACTION_TETHER_RIGHT: StringName = &"player_tether_right"
const ACTION_TETHER_DOWN: StringName = &"player_tether_down"
const ACTION_TETHER_LEFT: StringName = &"player_tether_left"
const ACTION_CHANGE_CLASS: StringName = &"player_change_class"
const ACTION_CHANGE_MODE: StringName = &"player_change_mode"
const ACTION_JOIN: StringName = &"player_join"
## D-Pad Up / Right / Down / Left: Soul Tether slots 0..3.
const TETHER_ACTIONS: Array[StringName] = [ACTION_TETHER_UP, ACTION_TETHER_RIGHT, ACTION_TETHER_DOWN, ACTION_TETHER_LEFT]
const BUTTON_ACTIONS: Array[StringName] = [
	ACTION_LIGHT, ACTION_HEAVY, ACTION_DODGE, ACTION_TRIGGER_L, ACTION_TRIGGER_R, ACTION_ULT,
	ACTION_TETHER_UP, ACTION_TETHER_RIGHT, ACTION_TETHER_DOWN, ACTION_TETHER_LEFT,
	ACTION_CHANGE_CLASS, ACTION_CHANGE_MODE,
]

const MENU_UP: StringName = &"up"
const MENU_DOWN: StringName = &"down"
const MENU_ACCEPT: StringName = &"accept"
const MENU_BACK: StringName = &"back"
const MENU_LEFT: StringName = &"left"
const MENU_RIGHT: StringName = &"right"

const MODE_NAMES: Array[String] = ["Master", "Adventurer", "Squire Gambit"]
const KEYBOARD_DEVICE: int = 0
const STICK_DEADZONE: float = 0.22
## Analog triggers press past this and release below the lower value, so a
## half-squeezed trigger doesn't flicker on and off.
const PRESS_THRESHOLD: float = 0.5
const RELEASE_THRESHOLD: float = 0.3
## L and R pressed this close together read as the ultimate (both triggers).
const CHORD_WINDOW: float = 0.12
## Holding R this long fires the R-hold skill (the healer's Green Sanctuary).
const R_HOLD_TIME: float = 0.45
## Class and mode change only after a deliberate hold, so a bumped Select
## doesn't swap a child's class mid-fight.
const MENU_HOLD_TIME: float = 0.6
const MASTER_BUFFER_WINDOW: float = 0.40
const ASSISTED_BUFFER_WINDOW: float = 0.55
const MASTER_FLOW_SPEED_BONUS: float = 0.15
## Squire Gambit dodges out of a red telegraph once it is this full.
const AUTO_EVADE_FILL: float = 0.85
const AUTO_EVADE_COOLDOWN: float = 0.8
## Squire Gambit raises the guard through the boss's Crushing Swipe with at least this much stamina.
const AUTO_GUARD_MIN_STAMINA: float = 25.0
## Metres beyond the swipe's reach that still count as in its way.
const AUTO_GUARD_MARGIN: float = 1.0
## Beyond this distance (and the heavy's own reach) the assisted modes open
## with a gap-closing forward heavy.
const GAP_CLOSE_DISTANCE: float = 4.5
## Squire Gambit, out of reach: the first of these that can reach the target and
## is affordable fires (a ranged heavy, or a card shot through a bow or staff).
const RANGED_PICKS: Array[int] = [
	CombatActionResource.Command.HEAVY, CombatActionResource.Command.FORWARD_HEAVY, CombatActionResource.Command.BACK_HEAVY,
]
## Squire DPS cycles the primer cards in these Grimoire slots.
const PRIMER_SLOTS: Array[int] = [
	ScribeCardResource.GrimoireSlot.FORWARD, ScribeCardResource.GrimoireSlot.BACK, ScribeCardResource.GrimoireSlot.SIGNATURE,
]
## Squire healer heals anyone below this share of their health.
const SQUIRE_HEAL_BELOW: float = 0.7
## Stick up / down past this (screen-relative) turns heavy into a forward / back heavy.
const DIRECTIONAL_THRESHOLD: float = 0.5
## A flick of the stick this recently still counts for the chord, so
## "flick, then press heavy" works as well as holding the stick.
const CHORD_MEMORY: float = 0.15
## Radians the camera turns per pixel of mouse movement (keyboard player).
const MOUSE_SENSITIVITY: float = 0.004

var device_id: int = KEYBOARD_DEVICE
var assist_mode: AssistMode = AssistMode.ADVENTURER
var actor: ActorBase
## Stick or WASD, x = right, y = forward, relative to this player's camera.
var move_input: Vector2 = Vector2.ZERO
var camera_orbit_input: float = 0.0
## A menu is open on this player's screen: buttons go to menu_input instead.
var menu_open: bool = false

var _held: Dictionary[StringName, bool] = {}
var _was_held: Dictionary[StringName, bool] = {}
var _hold_time: Dictionary[StringName, float] = {}
var _pending_trigger: StringName = &""
var _pending_time: float = 0.0
var _chord_lock: bool = false
var _r_tracking: bool = false
var _r_held_time: float = 0.0
var _r_hold_fired: bool = false
var _auto_evade_cooldown: float = 0.0
var _auto_guard: bool = false
var _squire_primer_turn: int = 0
var _last_forward_at: float = -INF
var _last_back_at: float = -INF
var _mouse_yaw: float = 0.0
var _menu_stick: int = 0
var _menu_stick_x: int = 0
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


# --- Reading the Input Map for one device ---------------------------------

## How hard `action` is pressed (0..1) on one device: the keyboard and mouse
## (device 0) or one pad. Used by players and by levels for join buttons.
static func action_strength(action: StringName, for_device: int) -> float:
	if not InputMap.has_action(action):
		return 0.0
	var strongest: float = 0.0
	for event: InputEvent in InputMap.action_get_events(action):
		strongest = maxf(strongest, _event_strength(event, for_device))
	return strongest


static func _event_strength(event: InputEvent, for_device: int) -> float:
	if for_device == KEYBOARD_DEVICE:
		var key: InputEventKey = event as InputEventKey
		if key != null:
			if key.physical_keycode != KEY_NONE:
				return 1.0 if Input.is_physical_key_pressed(key.physical_keycode) else 0.0
			return 1.0 if Input.is_key_pressed(key.keycode) else 0.0
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse != null:
			return 1.0 if Input.is_mouse_button_pressed(mouse.button_index) else 0.0
		return 0.0
	var pad: int = for_device - 1
	var button: InputEventJoypadButton = event as InputEventJoypadButton
	if button != null:
		return 1.0 if Input.is_joy_button_pressed(pad, button.button_index) else 0.0
	var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
	if motion != null:
		return clampf(Input.get_joy_axis(pad, motion.axis) * signf(motion.axis_value), 0.0, 1.0)
	return 0.0


## Which button layout to name in the HUD: Xbox letters or PlayStation shapes.
static func pad_family_of(for_device: int) -> PadFamily:
	if for_device == KEYBOARD_DEVICE:
		return PadFamily.KEYBOARD
	var pad_name: String = Input.get_joy_name(for_device - 1).to_lower()
	for hint: String in ["playstation", "dualsense", "dualshock", "ps3", "ps4", "ps5", "sony"]:
		if pad_name.contains(hint):
			return PadFamily.PLAYSTATION
	return PadFamily.XBOX


## The name of the first binding of `action` for a device's kind ("J", "□", "LT").
## Read from the Input Map, so the HUD stays right if a binding changes.
static func binding_label(action: StringName, for_device: int) -> String:
	if not InputMap.has_action(action):
		return "?"
	var family: PadFamily = pad_family_of(for_device)
	for event: InputEvent in InputMap.action_get_events(action):
		if family == PadFamily.KEYBOARD:
			var key: InputEventKey = event as InputEventKey
			if key != null:
				return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
		else:
			var button: InputEventJoypadButton = event as InputEventJoypadButton
			if button != null:
				return _pad_button_name(button.button_index, family)
			var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
			if motion != null and (motion.axis == JOY_AXIS_TRIGGER_LEFT or motion.axis == JOY_AXIS_TRIGGER_RIGHT):
				var left: bool = motion.axis == JOY_AXIS_TRIGGER_LEFT
				if family == PadFamily.PLAYSTATION:
					return "L2" if left else "R2"
				return "LT" if left else "RT"
	return "?"


static func _pad_button_name(button: JoyButton, family: PadFamily) -> String:
	var playstation: bool = family == PadFamily.PLAYSTATION
	match button:
		JOY_BUTTON_A:
			return "✕" if playstation else "A"
		JOY_BUTTON_B:
			return "○" if playstation else "B"
		JOY_BUTTON_X:
			return "□" if playstation else "X"
		JOY_BUTTON_Y:
			return "△" if playstation else "Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "L1" if playstation else "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "R1" if playstation else "RB"
		JOY_BUTTON_BACK:
			return "Create" if playstation else "View"
		JOY_BUTTON_START:
			return "Options" if playstation else "Menu"
		JOY_BUTTON_RIGHT_STICK:
			return "R3" if playstation else "RS"
		JOY_BUTTON_LEFT_STICK:
			return "L3" if playstation else "LS"
		JOY_BUTTON_DPAD_UP:
			return "D-Pad ↑"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-Pad →"
		JOY_BUTTON_DPAD_DOWN:
			return "D-Pad ↓"
		JOY_BUTTON_DPAD_LEFT:
			return "D-Pad ←"
	return "Button %d" % button


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
	return "Keyboard & mouse" if device_id == KEYBOARD_DEVICE else "Pad %d" % device_id


func is_keyboard() -> bool:
	return device_id == KEYBOARD_DEVICE


func pad_family() -> PadFamily:
	return pad_family_of(device_id)


func label(action: StringName) -> String:
	return binding_label(action, device_id)


## L held as a posture (Active Guard), once it's clear it isn't half of an ult
## chord, or the Squire auto-guard holding it up for you.
func is_guard_held() -> bool:
	if _auto_guard:
		return true
	if _scripted:
		return _scripted_guard
	return _held.get(ACTION_TRIGGER_L, false) and not _chord_lock and _pending_trigger != ACTION_TRIGGER_L


func is_auto_guarding() -> bool:
	return _auto_guard


## Camera yaw from mouse movement since the last call (keyboard player only).
func take_mouse_yaw() -> float:
	var yaw: float = _mouse_yaw
	_mouse_yaw = 0.0
	return yaw


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


## Hands the player back to their real controller.
func release_script() -> void:
	_scripted = false
	_scripted_commands.clear()
	_scripted_move = Vector2.ZERO
	_scripted_guard = false


# --- Polling --------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if device_id != KEYBOARD_DEVICE or _scripted:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_yaw -= motion.relative.x * MOUSE_SENSITIVITY


func poll(dt: float) -> void:
	_was_held = _held
	_held = _read_buttons()
	if _scripted:
		move_input = _scripted_move
		camera_orbit_input = 0.0
	else:
		move_input = _read_move()
		camera_orbit_input = _read_orbit()
	_remember_stick_direction()
	if menu_open:
		_poll_menu()
		move_input = Vector2.ZERO
		camera_orbit_input = 0.0
		return
	_update_auto_guard()

	if _held_for(ACTION_CHANGE_CLASS, dt):
		class_cycle_requested.emit()
	if _held_for(ACTION_CHANGE_MODE, dt):
		mode_cycle_requested.emit()
	for slot: int in TETHER_ACTIONS.size():
		if _pressed(TETHER_ACTIONS[slot]):
			tether_slot_pressed.emit(slot)
	if _pressed(ACTION_LIGHT):
		_issue_attack(CombatActionResource.Command.LIGHT)
	if _pressed(ACTION_HEAVY):
		_issue_attack(CombatActionResource.Command.HEAVY)
	if _pressed(ACTION_DODGE):
		_issue(CombatActionResource.Command.DODGE)
	if _pressed(ACTION_ULT):
		_issue(CombatActionResource.Command.TRIGGER_BOTH_ULT)
	_update_triggers(dt)
	_update_auto_evade(dt)

	while not _scripted_commands.is_empty():
		_issue(_scripted_commands.pop_front())


## Stick, WASD or the D-Pad move the cursor (up / down) and change a value
## (left / right), light accepts, dodge backs out.
func _poll_menu() -> void:
	var stick: int = 0
	if move_input.y > DIRECTIONAL_THRESHOLD:
		stick = 1
	elif move_input.y < -DIRECTIONAL_THRESHOLD:
		stick = -1
	if stick != 0 and stick != _menu_stick:
		menu_input.emit(MENU_UP if stick > 0 else MENU_DOWN)
	_menu_stick = stick
	var side: int = 0
	if move_input.x > DIRECTIONAL_THRESHOLD:
		side = 1
	elif move_input.x < -DIRECTIONAL_THRESHOLD:
		side = -1
	if side != 0 and side != _menu_stick_x:
		menu_input.emit(MENU_RIGHT if side > 0 else MENU_LEFT)
	_menu_stick_x = side
	if _pressed(ACTION_TETHER_UP):
		menu_input.emit(MENU_UP)
	if _pressed(ACTION_TETHER_DOWN):
		menu_input.emit(MENU_DOWN)
	if _pressed(ACTION_TETHER_LEFT):
		menu_input.emit(MENU_LEFT)
	if _pressed(ACTION_TETHER_RIGHT):
		menu_input.emit(MENU_RIGHT)
	if _pressed(ACTION_LIGHT):
		menu_input.emit(MENU_ACCEPT)
	if _pressed(ACTION_DODGE):
		menu_input.emit(MENU_BACK)


func _issue(command: int) -> void:
	# While the Squire auto-guard holds the shield up, mashed attacks wait.
	if _auto_guard and command != CombatActionResource.Command.DODGE:
		return
	command_issued.emit(command)


func _issue_attack(base: int) -> void:
	# Light next to a stall uses it (opens the Shard Vendor) instead of swinging.
	if base == CombatActionResource.Command.LIGHT and is_instance_valid(actor.interactable):
		actor.interactable.interact(actor)
		return
	if assist_mode == AssistMode.SQUIRE_GAMBIT:
		_issue(_squire_pick())
		return
	var command: int = base
	if base == CombatActionResource.Command.HEAVY:
		var direction: int = stick_direction()
		if direction > 0:
			command = CombatActionResource.Command.FORWARD_HEAVY
		elif direction < 0:
			command = CombatActionResource.Command.BACK_HEAVY
		elif assist_mode == AssistMode.ADVENTURER and not actor.action_queue.is_busy() \
				and actor.distance_to_soft_target() > maxf(GAP_CLOSE_DISTANCE, _reach_of(CombatActionResource.Command.HEAVY)) \
				and actor.loadout.has_opener(CombatActionResource.Command.FORWARD_HEAVY):
			command = CombatActionResource.Command.FORWARD_HEAVY
	_issue(command)


## +1 when the stick is (or was just) pushed up the screen, -1 for down, 0 otherwise.
## Screen-relative, like W and S: "forward" is always away from your camera.
func stick_direction() -> int:
	if move_input.y > DIRECTIONAL_THRESHOLD:
		return 1
	if move_input.y < -DIRECTIONAL_THRESHOLD:
		return -1
	var now: float = CombatDirector.game_time()
	var forward_recent: bool = now - _last_forward_at <= CHORD_MEMORY
	var back_recent: bool = now - _last_back_at <= CHORD_MEMORY
	if forward_recent and (not back_recent or _last_forward_at >= _last_back_at):
		return 1
	if back_recent:
		return -1
	return 0


func _remember_stick_direction() -> void:
	var now: float = CombatDirector.game_time()
	if move_input.y > DIRECTIONAL_THRESHOLD:
		_last_forward_at = now
	elif move_input.y < -DIRECTIONAL_THRESHOLD:
		_last_back_at = now


## Triggers wait a moment for the other trigger so that L+R reads as the ult.
func _update_triggers(dt: float) -> void:
	var l_held: bool = _held.get(ACTION_TRIGGER_L, false)
	var r_held: bool = _held.get(ACTION_TRIGGER_R, false)
	if _chord_lock:
		if not l_held and not r_held:
			_chord_lock = false
		return
	var l_pressed: bool = _pressed(ACTION_TRIGGER_L)
	var r_pressed: bool = _pressed(ACTION_TRIGGER_R)
	var chord: bool = (l_pressed and (r_pressed or _pending_trigger == ACTION_TRIGGER_R)) \
		or (r_pressed and _pending_trigger == ACTION_TRIGGER_L)
	if chord:
		_pending_trigger = &""
		_r_tracking = false
		_chord_lock = true
		_issue(CombatActionResource.Command.TRIGGER_BOTH_ULT)
		return
	if l_pressed:
		_pending_trigger = ACTION_TRIGGER_L
		_pending_time = CHORD_WINDOW
	elif r_pressed:
		_pending_trigger = ACTION_TRIGGER_R
		_pending_time = CHORD_WINDOW

	if _pending_trigger != &"":
		_pending_time -= dt
		if _pending_time <= 0.0:
			var which: StringName = _pending_trigger
			_pending_trigger = &""
			if which == ACTION_TRIGGER_L:
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


## Squire Gambit safety net: when the boss winds up its Crushing Swipe at you,
## raise the guard if there's stamina for it, and hold it until the swing is
## over. A class with no guard (the DPS) rolls clear instead.
func _update_auto_guard() -> void:
	var boss: BossDummy = actor.soft_target() as BossDummy
	if assist_mode != AssistMode.SQUIRE_GAMBIT or boss == null or not boss.swipe_threatens(actor, AUTO_GUARD_MARGIN):
		_auto_guard = false
		return
	if _auto_guard or actor.stats.stamina < AUTO_GUARD_MIN_STAMINA:
		return
	# A swing still winding up or recovering is dropped so the guard (or roll) goes now.
	var mid_swing: bool = actor.action_queue.phase == ActionQueueComponent.Phase.ACTIVE
	if actor.loadout.guard_on_trigger_l:
		_auto_guard = true
		if not mid_swing:
			actor.cancel_action()
	elif _auto_evade_cooldown <= 0.0 and not mid_swing and actor.stats.stamina >= actor.loadout.dodge.stamina_cost:
		actor.cancel_action()
		var away: Vector3 = actor.global_position - boss.global_position
		away.y = 0.0
		actor.evade_direction = away.normalized() if away.length() > 0.1 else -actor.facing_vector()
		_auto_evade_cooldown = AUTO_EVADE_COOLDOWN
		_issue(CombatActionResource.Command.DODGE)


## Squire Gambit: one button, and the game picks the smartest move for your
## role and weapon. Everything it picks is read from the loadout, so it plays
## any kit: a ranged weapon fires from where you stand, a melee one closes in.
func _squire_pick() -> int:
	var target: ActorBase = actor.soft_target()
	var distance: float = actor.distance_to_soft_target()
	match actor.role():
		ClassLoadoutResource.Role.HEALER:
			var hurt: ActorBase = actor.most_hurt_ally(SQUIRE_HEAL_BELOW)
			if hurt != null and actor.tether != null and actor.loadout.has_opener(CombatActionResource.Command.TRIGGER_R_SKILL):
				actor.tether.bind_actor(hurt)
				return CombatActionResource.Command.TRIGGER_R_SKILL
		ClassLoadoutResource.Role.TANK:
			if target != null and target.threat != null and target.threat.current_target != &"" \
					and target.threat.current_target != actor.player_id and actor.stats.resonance_pips() >= 1:
				return CombatActionResource.Command.TRIGGER_R_SKILL
		ClassLoadoutResource.Role.DPS:
			if target != null and CombatDirector.current.primer_on(target) == ScribeSignResource.Sign.NONE:
				var primers: Array[int] = []
				for slot: int in PRIMER_SLOTS:
					var card: CombatActionResource = actor.loadout.card_action(slot)
					if card != null and card.primer != ScribeSignResource.Sign.NONE and _can_use(card.command, distance):
						primers.append(card.command)
				if not primers.is_empty():
					_squire_primer_turn = (_squire_primer_turn + 1) % primers.size()
					return primers[_squire_primer_turn]
	# Out of reach: whatever can reach it (a ranged heavy, a card fired through
	# the weapon), or else close the gap with the forward card.
	if target != null and distance > _reach_of(CombatActionResource.Command.LIGHT):
		for command: int in RANGED_PICKS:
			if _can_use(command, distance):
				return command
		if actor.loadout.has_opener(CombatActionResource.Command.FORWARD_HEAVY):
			return CombatActionResource.Command.FORWARD_HEAVY
	return CombatActionResource.Command.LIGHT


## How far the action a command starts can reach (0 if it starts none).
func _reach_of(command: int) -> float:
	var action: CombatActionResource = actor.loadout.opener_for(command as CombatActionResource.Command)
	return action.reach_distance() if action != null else 0.0


func _can_use(command: int, distance: float) -> bool:
	var action: CombatActionResource = actor.loadout.opener_for(command as CombatActionResource.Command)
	return action != null and action.reach_distance() >= distance and actor.stats.can_afford(action)


# --- Devices --------------------------------------------------------------

func _pressed(action: StringName) -> bool:
	return _held.get(action, false) and not _was_held.get(action, false)


## True once, the moment `action` has been held for MENU_HOLD_TIME.
func _held_for(action: StringName, dt: float) -> bool:
	if not _held.get(action, false):
		_hold_time[action] = 0.0
		return false
	var before: float = _hold_time.get(action, 0.0)
	var after: float = before + dt
	_hold_time[action] = after
	return before < MENU_HOLD_TIME and after >= MENU_HOLD_TIME


func _read_buttons() -> Dictionary[StringName, bool]:
	var held: Dictionary[StringName, bool] = {}
	if _scripted:
		return held
	for action: StringName in BUTTON_ACTIONS:
		var threshold: float = RELEASE_THRESHOLD if _held.get(action, false) else PRESS_THRESHOLD
		held[action] = action_strength(action, device_id) >= threshold
	return held


func _read_move() -> Vector2:
	var stick: Vector2 = Vector2(
		action_strength(ACTION_MOVE_RIGHT, device_id) - action_strength(ACTION_MOVE_LEFT, device_id),
		action_strength(ACTION_MOVE_FORWARD, device_id) - action_strength(ACTION_MOVE_BACK, device_id))
	if device_id == KEYBOARD_DEVICE:
		return stick.limit_length(1.0)
	return _apply_deadzone(stick)


func _read_orbit() -> float:
	var orbit: float = action_strength(ACTION_CAMERA_RIGHT, device_id) - action_strength(ACTION_CAMERA_LEFT, device_id)
	if device_id == KEYBOARD_DEVICE:
		return orbit
	return _apply_deadzone(Vector2(orbit, 0.0)).x


func _apply_deadzone(stick: Vector2) -> Vector2:
	var length: float = stick.length()
	if length < STICK_DEADZONE:
		return Vector2.ZERO
	return stick / length * minf(1.0, inverse_lerp(STICK_DEADZONE, 1.0, length))
