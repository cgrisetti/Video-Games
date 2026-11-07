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
## While a menu is open on this player's screen (the Chime-Shrine), the same
## controller drives the menu instead of the character (menu_input).
##
## Sign-Flow (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §5) reuses the same buttons:
## out of combat, R and L+R wait to see if they're held; held 120 frames they're
## the Hearth-Rite (hearth_rite_held), let go sooner they fire as usual. A tap
## of Tab / View (whose hold changes Fellowship) opens the Grimoire Binder.
##
## Moving about (Phase 12 Kaizen, K1): ✕ / A (Space) jumps, ○ / B (L) rolls, and
## holding L3 / LS (Left Shift) while moving sprints. In a menu, jump and roll
## both back out, as the roll alone used to.
##
## The camera (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §6):
## the right stick's Y (deadzone 0.15), PageUp / [ and PageDown / ] pitch it
## (camera_pitch_input, +1 looks up); the mouse's Y pitches it while the right
## button is held or mouse-look is on (V toggles it). A tap of M / R3 (whose
## hold changes assist mode) opens the Wayfarer's Atlas.
class_name InputComponent
extends Node

signal command_issued(command: int)
signal tether_slot_pressed(slot: int)
signal class_cycle_requested
signal mode_cycle_requested
signal calling_cycle_requested
## Jump was pressed (out of a menu).
signal jump_requested
## The playtest switcher's next (+1) or previous (-1) class and level (F2, or hold Share and tap D-Pad → / ←).
signal playtest_cycle_requested(step: int)
## R or L+R held out of combat for the Hearth-Rite's time (the command names which).
signal hearth_rite_held(command: int)
## A tap of the Fellowship button: the Grimoire Binder opens (or closes).
signal binder_requested
## A tap of the assist-mode button (M / R3): the Wayfarer's Atlas opens (or closes).
signal atlas_requested
## A tap of Esc or Options / Menu: the Options menu opens (or, over another menu, that menu closes).
signal options_requested
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
const ACTION_JUMP: StringName = &"player_jump"
const ACTION_SPRINT: StringName = &"player_sprint"
## The playtest switcher (K2): F2 on the keyboard; on a pad it's the Share chord.
const ACTION_PLAYTEST_CYCLE: StringName = &"player_playtest_cycle"
const ACTION_TRIGGER_L: StringName = &"player_trigger_l"
const ACTION_TRIGGER_R: StringName = &"player_trigger_r"
const ACTION_ULT: StringName = &"player_ult"
const ACTION_TETHER_UP: StringName = &"player_tether_up"
const ACTION_TETHER_RIGHT: StringName = &"player_tether_right"
const ACTION_TETHER_DOWN: StringName = &"player_tether_down"
const ACTION_TETHER_LEFT: StringName = &"player_tether_left"
const ACTION_CHANGE_CLASS: StringName = &"player_change_class"
const ACTION_CHANGE_MODE: StringName = &"player_change_mode"
const ACTION_CHANGE_CALLING: StringName = &"player_change_calling"
const ACTION_JOIN: StringName = &"player_join"
## The Options menu (13_PLAYTEST §2.1): Esc, or a tap of a seated pad's Options / Menu (Start).
const ACTION_OPTIONS: StringName = &"player_options"
## Camera pitch and mouse-look (18 GDD §6).
const ACTION_CAMERA_PITCH_UP: StringName = &"cam_pitch_up"
const ACTION_CAMERA_PITCH_DOWN: StringName = &"cam_pitch_down"
const ACTION_MOUSE_LOOK: StringName = &"cam_mouse_look"
## The right stick's Y has its own, finer deadzone.
const PITCH_STICK_DEADZONE: float = 0.15
## Radians of pitch per pixel of mouse movement.
const MOUSE_PITCH_SENSITIVITY: float = 0.0035
## D-Pad Up / Right / Down / Left: Soul Tether slots 0..3.
const TETHER_ACTIONS: Array[StringName] = [ACTION_TETHER_UP, ACTION_TETHER_RIGHT, ACTION_TETHER_DOWN, ACTION_TETHER_LEFT]
const BUTTON_ACTIONS: Array[StringName] = [
	ACTION_LIGHT, ACTION_HEAVY, ACTION_DODGE, ACTION_TRIGGER_L, ACTION_TRIGGER_R, ACTION_ULT,
	ACTION_TETHER_UP, ACTION_TETHER_RIGHT, ACTION_TETHER_DOWN, ACTION_TETHER_LEFT,
	ACTION_CHANGE_CLASS, ACTION_CHANGE_MODE, ACTION_CHANGE_CALLING, ACTION_JUMP, ACTION_SPRINT, ACTION_PLAYTEST_CYCLE, ACTION_OPTIONS,
]

const MENU_UP: StringName = &"up"
const MENU_DOWN: StringName = &"down"
const MENU_ACCEPT: StringName = &"accept"
const MENU_BACK: StringName = &"back"
const MENU_LEFT: StringName = &"left"
const MENU_RIGHT: StringName = &"right"
## L / R (Q / E on the keyboard) in a menu: the previous and next tab (the Grimoire Binder's).
const MENU_TAB_PREV: StringName = &"tab_prev"
const MENU_TAB_NEXT: StringName = &"tab_next"
## Heavy in a menu: a menu's second action (the map turns between its Zone and World views).
const MENU_ALT: StringName = &"alt"

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
## Class, Calling and mode change only after a deliberate hold, so a bumped
## Select doesn't swap a child's class mid-fight.
const MENU_HOLD_TIME: float = 0.6
const MASTER_BUFFER_WINDOW: float = 0.40
const ASSISTED_BUFFER_WINDOW: float = 0.55
const MASTER_FLOW_SPEED_BONUS: float = 0.15
## Squire Gambit dodges out of a red telegraph (or an unsheltered Gale-Beam lane) once it is this full.
const AUTO_EVADE_FILL: float = 0.85
## A Squire tank the Gale-Beam is aimed at raises Shadow Sanctuary once the beam is this full
## (early enough for the wind-up, and before the lane locks).
const AUTO_SHELTER_FILL: float = 0.25
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
## Sprint is held (L3 / LS, Left Shift) and no menu is open.
var sprint_held: bool = false
## Sprint was pressed this tick (the toggle sprint's click, 13_PLAYTEST §2.3).
var sprint_pressed: bool = false
var camera_orbit_input: float = 0.0
## The camera's pitch: +1 looks up, -1 down (stick, or the pitch keys).
var camera_pitch_input: float = 0.0
## Invert-Y (18 GDD §6.1, optional): the stick's and the mouse's pitch turn the other way.
var invert_pitch: bool = false
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
var _mouse_pitch: float = 0.0
var _mouse_look_held: bool = false
var _menu_stick: int = 0
var _menu_stick_x: int = 0
## False on the first tick a menu is open: whatever is already held then
## (the press that opened it, or a new character's menu reopening) is ignored.
var _menu_armed: bool = false
# Tests and bots drive the component through these instead of a device.
var _scripted: bool = false
var _scripted_commands: Array[int] = []
var _scripted_move: Vector2 = Vector2.ZERO
var _scripted_guard: bool = false
## Buttons a test holds down (inject_hold), read as if pressed on the device.
var _scripted_held: Dictionary[StringName, bool] = {}
## The trigger press waiting out the chord window has been held this long.
var _pending_elapsed: float = 0.0
## An R or L+R held out of combat, on its way to the Hearth-Rite (-1 when none).
var _rite_command: int = -1
var _rite_buttons: Array[StringName] = []
var _rite_time: float = 0.0
var _rite_fired: bool = false
## Share was used for the playtest chord this press.
var _share_chorded: bool = false
var _primed: bool = false
## Buttons that were already down when this controller was made: no tap or hold from them until they're let go.
var _spent: Dictionary[StringName, bool] = {}


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
	# The Options menu can name every pad's buttons one way.
	match SettingsManager.glyphs():
		SettingsManager.PadGlyphs.PLAYSTATION:
			return PadFamily.PLAYSTATION
		SettingsManager.PadGlyphs.XBOX:
			return PadFamily.XBOX
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


## Camera pitch from mouse movement since the last call, radians (+ tilts the view down).
func take_mouse_pitch() -> float:
	var pitch: float = _mouse_pitch
	_mouse_pitch = 0.0
	return pitch


## Whether the mouse steers the camera now: mouse-look on (the mouse captured) or the right button held.
static func mouse_looking() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)


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


## Holds a button down (or lets it go) as if on the device, so timed holds play
## through the real trigger logic (the smoke test's Hearth-Rite).
func inject_hold(action: StringName, held: bool) -> void:
	_scripted = true
	_scripted_held[action] = held


## Hands the player back to their real controller.
func release_script() -> void:
	_scripted = false
	_scripted_commands.clear()
	_scripted_move = Vector2.ZERO
	_scripted_guard = false
	_scripted_held.clear()


## How far an R or L+R hold has come toward the Hearth-Rite, 0 to 1 (0 when none is held).
func hearth_rite_progress() -> float:
	if _rite_command < 0 or _rite_fired or actor.sign_flow == null:
		return 0.0
	return clampf(_rite_time / actor.sign_flow.hearth_rite_hold_seconds(_rite_socket()), 0.0, 1.0)


## The socket an R or L+R hold prepares (-1 when none is held).
func hearth_rite_socket() -> int:
	return _rite_socket() if _rite_command >= 0 and not _rite_fired else -1


## A Squire's buffered counter fires on the Glimmer-Spot's first frame: R, cast at once as Sign-Flow.
func fire_buffered_counter() -> void:
	if actor.action_queue.is_busy() and actor.action_queue.phase != ActionQueueComponent.Phase.ACTIVE:
		actor.cancel_action()
	if actor.sign_flow != null:
		actor.sign_flow.arm(CombatActionResource.Command.TRIGGER_R_SKILL)
	command_issued.emit(CombatActionResource.Command.TRIGGER_R_SKILL)


# --- Polling --------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if device_id != KEYBOARD_DEVICE or _scripted:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_yaw -= motion.relative.x * MOUSE_SENSITIVITY * SettingsManager.mouse_scale()
	if motion != null and not menu_open and mouse_looking():
		_mouse_pitch += motion.relative.y * MOUSE_PITCH_SENSITIVITY * SettingsManager.mouse_scale() * (-1.0 if SettingsManager.invert_y() else 1.0)


func poll(dt: float) -> void:
	_was_held = _held
	_held = _read_buttons()
	if not _primed:
		# A fresh controller (a new seat, or the same player re-seated by a class change)
		# takes buttons already down as held, not pressed, so one press never fires twice.
		_primed = true
		_was_held = _held.duplicate()
		for action: StringName in _held:
			if _held[action]:
				_spent[action] = true
	if _scripted:
		move_input = _scripted_move
		camera_orbit_input = 0.0
		camera_pitch_input = 0.0
	else:
		move_input = _read_move()
		camera_orbit_input = _read_orbit()
		camera_pitch_input = _read_pitch()
		_poll_mouse_look()
	_remember_stick_direction()
	sprint_held = false
	sprint_pressed = false
	# Invert Y follows the Options menu (13_PLAYTEST §2.2).
	invert_pitch = SettingsManager.invert_y()
	if menu_open:
		if _menu_armed:
			_poll_menu()
		else:
			_arm_menu()
		move_input = Vector2.ZERO
		camera_orbit_input = 0.0
		camera_pitch_input = 0.0
		return
	_menu_armed = false
	_update_auto_guard()
	sprint_held = _held.get(ACTION_SPRINT, false)
	sprint_pressed = _pressed(ACTION_SPRINT)
	if _pressed(ACTION_JUMP):
		jump_requested.emit()
	if _pressed(ACTION_PLAYTEST_CYCLE):
		playtest_cycle_requested.emit(1)
	# Share (Create / View) held, the D-Pad's → and ← step the playtest switcher, and the press is spent:
	# no Binder on its release, no Fellowship change at its hold.
	var share_held: bool = _held.get(ACTION_CHANGE_CLASS, false)
	if share_held and (_pressed(ACTION_TETHER_RIGHT) or _pressed(ACTION_TETHER_LEFT)):
		playtest_cycle_requested.emit(1 if _pressed(ACTION_TETHER_RIGHT) else -1)
		_share_chorded = true
	if not share_held and not _was_held.get(ACTION_CHANGE_CLASS, false):
		_share_chorded = false
	if _tapped(ACTION_OPTIONS):
		options_requested.emit()
	_held_for(ACTION_OPTIONS, dt)
	if _tapped(ACTION_CHANGE_CLASS) and not _share_chorded:
		binder_requested.emit()
	if _held_for(ACTION_CHANGE_CLASS, dt) and not _share_chorded:
		class_cycle_requested.emit()
	if _tapped(ACTION_CHANGE_MODE):
		atlas_requested.emit()
	if _held_for(ACTION_CHANGE_MODE, dt):
		mode_cycle_requested.emit()
	if _held_for(ACTION_CHANGE_CALLING, dt):
		calling_cycle_requested.emit()
	for slot: int in TETHER_ACTIONS.size():
		if _pressed(TETHER_ACTIONS[slot]) and not share_held:
			tether_slot_pressed.emit(slot)
	if _pressed(ACTION_LIGHT):
		_issue_attack(CombatActionResource.Command.LIGHT)
	if _pressed(ACTION_HEAVY):
		_issue_attack(CombatActionResource.Command.HEAVY)
	if _pressed(ACTION_DODGE):
		_issue(CombatActionResource.Command.DODGE)
	_update_hearth_rite(dt)
	if _pressed(ACTION_ULT):
		if _can_prepare():
			_start_rite(CombatActionResource.Command.TRIGGER_BOTH_ULT, [ACTION_ULT], dt)
		else:
			_issue(CombatActionResource.Command.TRIGGER_BOTH_ULT)
	_update_triggers(dt)
	_update_auto_evade(dt)

	while not _scripted_commands.is_empty():
		_issue(_scripted_commands.pop_front())


## Takes in what's held as a menu opens, so only fresh presses drive it.
func _arm_menu() -> void:
	_menu_armed = true
	_menu_stick = 1 if move_input.y > DIRECTIONAL_THRESHOLD else (-1 if move_input.y < -DIRECTIONAL_THRESHOLD else 0)
	_menu_stick_x = 1 if move_input.x > DIRECTIONAL_THRESHOLD else (-1 if move_input.x < -DIRECTIONAL_THRESHOLD else 0)
	for action: StringName in BUTTON_ACTIONS:
		_was_held[action] = _held.get(action, false)


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
	if _pressed(ACTION_TRIGGER_L):
		menu_input.emit(MENU_TAB_PREV)
	if _pressed(ACTION_TRIGGER_R):
		menu_input.emit(MENU_TAB_NEXT)
	if _pressed(ACTION_DODGE) or _pressed(ACTION_JUMP):
		menu_input.emit(MENU_BACK)
	if _pressed(ACTION_HEAVY):
		menu_input.emit(MENU_ALT)
	if _tapped(ACTION_CHANGE_CLASS):
		binder_requested.emit()
	if _tapped(ACTION_CHANGE_MODE):
		atlas_requested.emit()
	if _tapped(ACTION_OPTIONS):
		options_requested.emit()
	# Esc / Options' hold time counts in a menu too, so a long hold (leaving the party) isn't a tap.
	if not _held.get(ACTION_OPTIONS, false):
		_hold_time[ACTION_OPTIONS] = 0.0
	else:
		_hold_time[ACTION_OPTIONS] = _hold_time.get(ACTION_OPTIONS, 0.0) + get_physics_process_delta_time()
	# The assist-mode button's hold time still counts while a menu is open (so its tap reads).
	if not _held.get(ACTION_CHANGE_MODE, false):
		_hold_time[ACTION_CHANGE_MODE] = 0.0
	else:
		_hold_time[ACTION_CHANGE_MODE] = _hold_time.get(ACTION_CHANGE_MODE, 0.0) + get_physics_process_delta_time()


func _issue(command: int) -> void:
	# While the Squire auto-guard holds the shield up, mashed attacks wait.
	if _auto_guard and command != CombatActionResource.Command.DODGE:
		return
	command_issued.emit(command)


func _issue_attack(base: int) -> void:
	# Light next to the shrine or the desk uses it instead of swinging.
	if base == CombatActionResource.Command.LIGHT and is_instance_valid(actor.interactable):
		actor.interactable.interact(actor)
		return
	if assist_mode == AssistMode.SQUIRE_GAMBIT:
		if _squire_buffer_counter():
			return
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


## +1 when the stick is pushed right, -1 for left, 0 otherwise: Heavy with the
## stick sideways (and not up or down) is a SIDE_HEAVY to the combo forms.
func stick_side() -> int:
	if absf(move_input.y) > DIRECTIONAL_THRESHOLD:
		return 0
	if move_input.x > DIRECTIONAL_THRESHOLD:
		return 1
	if move_input.x < -DIRECTIONAL_THRESHOLD:
		return -1
	return 0


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
		var held_for: float = _pending_elapsed + dt if _pending_trigger != &"" else dt
		_pending_trigger = &""
		_r_tracking = false
		_chord_lock = true
		if _can_prepare():
			_start_rite(CombatActionResource.Command.TRIGGER_BOTH_ULT, [ACTION_TRIGGER_L, ACTION_TRIGGER_R], held_for)
		else:
			_issue(CombatActionResource.Command.TRIGGER_BOTH_ULT)
		return
	if l_pressed:
		_pending_trigger = ACTION_TRIGGER_L
		_pending_time = CHORD_WINDOW
		_pending_elapsed = 0.0
	elif r_pressed:
		_pending_trigger = ACTION_TRIGGER_R
		_pending_time = CHORD_WINDOW
		_pending_elapsed = 0.0

	if _pending_trigger != &"":
		_pending_time -= dt
		_pending_elapsed += dt
		if _pending_time <= 0.0:
			var which: StringName = _pending_trigger
			_pending_trigger = &""
			if which == ACTION_TRIGGER_L:
				# A guard class holds L as a posture instead (see is_guard_held).
				if not actor.loadout.guard_on_trigger_l:
					_issue(CombatActionResource.Command.TRIGGER_L_SKILL)
			elif _can_prepare() and r_held:
				_start_rite(CombatActionResource.Command.TRIGGER_R_SKILL, [ACTION_TRIGGER_R], _pending_elapsed)
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


## Out of combat, R and L+R can become the Hearth-Rite (SignFlowComponent).
func _can_prepare() -> bool:
	return SignFlowComponent.enabled and actor.sign_flow != null and actor.sign_flow.can_prepare()


func _rite_socket() -> int:
	return ScribeCardResource.DioramaSocket.ULT if _rite_command == CombatActionResource.Command.TRIGGER_BOTH_ULT \
		else ScribeCardResource.DioramaSocket.SKILL


## An R or L+R out of combat waits while it's held: `held_for` is how long it already has been.
func _start_rite(command: int, buttons: Array[StringName], held_for: float) -> void:
	_rite_command = command
	_rite_buttons = buttons
	_rite_time = held_for
	_rite_fired = false


## Held the Hearth-Rite Tuck's time (120 frames, 80 on Star-Inked Vellum): the rite.
## Let go sooner, or a fight starts, and it's the move as usual.
func _update_hearth_rite(dt: float) -> void:
	if _rite_command < 0:
		return
	var still_held: bool = true
	for button: StringName in _rite_buttons:
		still_held = still_held and _held.get(button, false)
	if _rite_fired:
		if not still_held:
			_rite_command = -1
		return
	if not still_held or not _can_prepare():
		var command: int = _rite_command
		_rite_command = -1
		_issue(command)
		return
	_rite_time += dt
	if _rite_time >= actor.sign_flow.hearth_rite_hold_seconds(_rite_socket()) - 0.001:
		_rite_fired = true
		hearth_rite_held.emit(_rite_command)


## Squire Gambit (14 GDD §3): a press within 90 frames before a boss's
## Glimmer-Spot opens is held for it, if the R card's Sign cracks that boss;
## the R then fires on the opening's first frame. True when the press was taken.
func _squire_buffer_counter() -> bool:
	var target: ActorBase = actor.soft_target()
	if target == null or target.glimmer == null:
		return false
	if target.glimmer.is_buffered(actor.player_id):
		return true
	var counter: CombatActionResource = actor.loadout.opener_for(CombatActionResource.Command.TRIGGER_R_SKILL)
	if counter == null or counter.effect != CombatActionResource.Effect.STRIKE or not actor.stats.can_afford(counter):
		return false
	var sign_id: int = counter.primer if counter.primer != ScribeSignResource.Sign.NONE else counter.scribe_sign
	if not target.glimmer.is_countered_now(sign_id):
		return false
	return target.glimmer.buffer_squire_counter(actor)


## Squire Gambit safety net: roll out of a red telegraph that's nearly full.
func _update_auto_evade(dt: float) -> void:
	_auto_evade_cooldown = maxf(0.0, _auto_evade_cooldown - dt)
	if assist_mode != AssistMode.SQUIRE_GAMBIT or _auto_evade_cooldown > 0.0:
		return
	if _shelter_from_beam():
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


## Squire Gambit and the Gale-Beam (08 Gate 5: an assisted child must survive
## every mechanic): a tank the beam is aimed at turns to the boss and raises
## Shadow Sanctuary for everyone; anyone else caught in the lane outside a
## shield rolls out sideways at the last moment. True when it acted.
func _shelter_from_beam() -> bool:
	var beam: RaidTelegraphDecal = CombatDirector.current.beam_telegraph()
	if beam == null or not beam.contains(actor.global_position) or CombatDirector.current.is_sheltered(actor):
		return false
	var cone: CombatActionResource = actor.loadout.card_action(ScribeCardResource.GrimoireSlot.BACK)
	if beam.follow_target == actor and cone != null and cone.effect == CombatActionResource.Effect.SHADOW_SANCTUARY \
			and beam.fill_ratio() >= AUTO_SHELTER_FILL and actor.stats.can_afford(cone) and actor.can_act():
		if is_instance_valid(beam.origin_actor):
			actor.turn_toward(beam.origin_actor.global_position - actor.global_position, PI)
		if actor.action_queue.is_busy() and actor.action_queue.phase != ActionQueueComponent.Phase.ACTIVE:
			actor.cancel_action()
		_auto_evade_cooldown = AUTO_EVADE_COOLDOWN
		_issue(CombatActionResource.Command.BACK_HEAVY)
		return true
	if beam.fill_ratio() < AUTO_EVADE_FILL or actor.stats.stamina < actor.loadout.dodge.stamina_cost:
		return false
	var across: Vector3 = beam.global_basis.x.normalized()
	var side: float = signf(across.dot(actor.global_position - beam.global_position))
	actor.cancel_action()
	actor.evade_direction = across * (side if side != 0.0 else 1.0)
	_auto_evade_cooldown = AUTO_EVADE_COOLDOWN
	_issue(CombatActionResource.Command.DODGE)
	return true


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
	# A martial lock on the foe and two Lights already in: Forward+Heavy finishes
	# the Sundering Gap-Leap that cracks it (14 GDD §8), so a Squire is never stuck.
	if target != null and target.posture != null and target.posture.wants_martial_key() and actor.combo != null \
			and actor.combo.ends_with([ComboChainResource.LIGHT, ComboChainResource.LIGHT]) \
			and actor.loadout.has_opener(CombatActionResource.Command.FORWARD_HEAVY):
		return CombatActionResource.Command.FORWARD_HEAVY
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


## Let go this tick after a press shorter than a hold (the Fellowship button's tap).
func _tapped(action: StringName) -> bool:
	if _is_spent(action):
		return false
	return _was_held.get(action, false) and not _held.get(action, false) and _hold_time.get(action, 0.0) < MENU_HOLD_TIME


## Whether `action` is still the press this controller started with (clears once it's let go).
func _is_spent(action: StringName) -> bool:
	if not _spent.has(action):
		return false
	if not _held.get(action, false) and not _was_held.get(action, false):
		_spent.erase(action)
		return false
	return true


## True once, the moment `action` has been held for MENU_HOLD_TIME.
func _held_for(action: StringName, dt: float) -> bool:
	if _is_spent(action):
		_hold_time[action] = 0.0
		return false
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
		held.assign(_scripted_held)
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


## The camera's pitch input: +1 looks up (stick up, PageUp or [), -1 down.
func _read_pitch() -> float:
	var pitch: float = action_strength(ACTION_CAMERA_PITCH_UP, device_id) - action_strength(ACTION_CAMERA_PITCH_DOWN, device_id)
	if device_id == KEYBOARD_DEVICE:
		return clampf(pitch, -1.0, 1.0)
	if absf(pitch) < PITCH_STICK_DEADZONE:
		return 0.0
	return signf(pitch) * minf(1.0, inverse_lerp(PITCH_STICK_DEADZONE, 1.0, absf(pitch))) * (-1.0 if invert_pitch else 1.0)


## V toggles mouse-look (keyboard player): the mouse is captured and steers the camera, or let go.
func _poll_mouse_look() -> void:
	if device_id != KEYBOARD_DEVICE:
		return
	var held: bool = action_strength(ACTION_MOUSE_LOOK, device_id) >= PRESS_THRESHOLD
	if held and not _mouse_look_held and not menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	_mouse_look_held = held


func _apply_deadzone(stick: Vector2) -> Vector2:
	var length: float = stick.length()
	if length < STICK_DEADZONE:
		return Vector2.ZERO
	return stick / length * minf(1.0, inverse_lerp(STICK_DEADZONE, 1.0, length))
