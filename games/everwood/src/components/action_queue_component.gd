## Runs one action at a time through the four-phase pipeline (02_COMBAT_GDD.md §2):
##   A  Wind-up   stamina paid, turn toward target, no cancels
##   B  Active    hitbox live
##   C  Buffer    the last 400-550 ms capture the next press (2-slot KOTOR queue)
##   D  Recovery  skipped entirely if a valid follow-up was buffered (flow-cancel)
## Phase C overlaps the end of B and D, so it is a window, not a separate phase.
##
## Heroes also play by the kinetic loop's rules (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md
## §3.1, `kinetic_rules`): a third Light in a row with nothing woven in is
## winded (ActorBase.STATIC_MASH_RECOVERY_MS of recovery, cancellable only in
## the Flow-Link window, and only into a directional Heavy, R, L+R or a roll);
## and cancelling a 2nd or 3rd Light inside that window into one of those, or
## a guard, is a Flow-Link Pulse.
class_name ActionQueueComponent
extends Node

signal action_started(action: CombatActionResource, flowed: bool)
signal phase_changed(phase: Phase)
signal action_finished(action: CombatActionResource)
signal action_interrupted(action: CombatActionResource)
signal buffer_changed(commands: Array[int])
signal flow_cancelled(from_action: CombatActionResource, to_action: CombatActionResource)
signal action_rejected(command: int)
## A Flow-Link Pulse: a 2nd or 3rd Light cancelled in time into `to_command`
## (a directional Heavy, R, L+R or a roll; Command.TRIGGER_L_SKILL for a guard).
signal flow_link_pulsed(from_action: CombatActionResource, to_command: int)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

const BUFFER_SLOTS: int = 2
## Idle this long between Lights and the streak starts over.
const STREAK_RESET_TIME: float = 1.0
## What a Light's recovery can be cancelled into for a Flow-Link Pulse (a guard counts too).
const PULSE_COMMANDS: Array[int] = [CombatActionResource.Command.FORWARD_HEAVY, CombatActionResource.Command.BACK_HEAVY,
	CombatActionResource.Command.TRIGGER_R_SKILL, CombatActionResource.Command.TRIGGER_BOTH_ULT, CombatActionResource.Command.DODGE]

var actor: ActorBase
var current_action: CombatActionResource
var phase: Phase = Phase.IDLE
## Time spent in the current phase, in action time (already sped up by flow bonuses).
var phase_time: float = 0.0
## 1.0 normally; 1.15 after a Master-mode flow-cancel.
var speed_scale: float = 1.0
var flowed_into_current: bool = false
var buffer: Array[int] = []
## Real seconds before the end of an action that presses start being captured.
var buffer_window: float = 0.4
## Speed bonus a flow-cancel grants (Master mode earns +15%).
var flow_speed_bonus: float = 0.0
## Assisted modes: a press that isn't an exact flow link picks the nearest one.
var assisted_chaining: bool = false
## Heroes: the Static Mash Penalty and Flow-Link Pulses apply (ActorBase sets it).
var kinetic_rules: bool = false
## Lights in a row with no heavy, card, guard or roll between them.
var lights_in_a_row: int = 0
## The current action's recovery: its own, or longer when it's winded.
var recovery_time: float = 0.0
## The current action is a winded third Light.
var winded: bool = false

var _idle_time: float = 0.0


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "ActionQueueComponent"


func is_busy() -> bool:
	return phase != Phase.IDLE


func request(input_command: int) -> void:
	if phase == Phase.IDLE:
		_start_opener(input_command)
		return
	if not is_buffer_open() or buffer.size() >= BUFFER_SLOTS:
		return
	buffer.append(input_command)
	buffer_changed.emit(buffer)
	if phase == Phase.RECOVERY:
		_try_flow_from_buffer()


## Phase C: presses are captured only in the last `buffer_window` seconds, never during wind-up.
func is_buffer_open() -> bool:
	if phase == Phase.IDLE or phase == Phase.WINDUP:
		return false
	return time_remaining() / speed_scale <= buffer_window


func time_remaining() -> float:
	if current_action == null:
		return 0.0
	match phase:
		Phase.WINDUP:
			return current_action.windup_time - phase_time + current_action.active_time + recovery_time
		Phase.ACTIVE:
			return current_action.active_time - phase_time + recovery_time
		Phase.RECOVERY:
			return recovery_time - phase_time
	return 0.0


## Fraction of the current action that has played, 0..1 (for poses and HUD).
func progress() -> float:
	if current_action == null:
		return 0.0
	var total: float = current_action.windup_time + current_action.active_time + recovery_time
	return 0.0 if total <= 0.0 else 1.0 - time_remaining() / total


## The Flow-Link window: the first FLOW_LINK_WINDOW_MS of a Light's recovery.
func is_flow_link_window() -> bool:
	return phase == Phase.RECOVERY and current_action != null and current_action.command == CombatActionResource.Command.LIGHT \
		and phase_time <= ActorBase.FLOW_LINK_WINDOW_MS / 1000.0


## A guard raised in the Flow-Link window drops the Light at once (a pulse if
## it was the 2nd or 3rd in a row). Returns whether it did.
func cancel_into_guard() -> bool:
	if not kinetic_rules or not is_flow_link_window():
		return false
	if lights_in_a_row >= 2:
		flow_link_pulsed.emit(current_action, CombatActionResource.Command.TRIGGER_L_SKILL)
	lights_in_a_row = 0
	interrupt()
	return true


## A guard or anything else that isn't a Light breaks the streak.
func break_streak() -> void:
	lights_in_a_row = 0


func tick(dt: float) -> void:
	if phase == Phase.IDLE:
		_idle_time += dt
		if _idle_time >= STREAK_RESET_TIME:
			lights_in_a_row = 0
		return
	phase_time += dt * speed_scale
	match phase:
		Phase.WINDUP:
			if phase_time >= current_action.windup_time:
				_enter_phase(Phase.ACTIVE, phase_time - current_action.windup_time)
		Phase.ACTIVE:
			if phase_time >= current_action.active_time:
				_enter_phase(Phase.RECOVERY, phase_time - current_action.active_time)
				_try_flow_from_buffer()
		Phase.RECOVERY:
			if phase_time >= recovery_time:
				_finish()
			elif winded:
				_try_flow_from_buffer()


## Stops the current action at once (stagger, knockdown, being downed).
func interrupt() -> void:
	var was: CombatActionResource = current_action
	buffer.clear()
	buffer_changed.emit(buffer)
	if phase == Phase.IDLE:
		return
	phase = Phase.IDLE
	current_action = null
	speed_scale = 1.0
	winded = false
	_idle_time = 0.0
	phase_changed.emit(Phase.IDLE)
	action_interrupted.emit(was)


func _enter_phase(next_phase: Phase, carry_time: float) -> void:
	phase = next_phase
	phase_time = carry_time
	phase_changed.emit(next_phase)


func _finish() -> void:
	var finished: CombatActionResource = current_action
	if winded:
		# The winded swing ends the streak: the next Light starts a fresh one.
		lights_in_a_row = 0
	winded = false
	_idle_time = 0.0
	phase = Phase.IDLE
	current_action = null
	speed_scale = 1.0
	phase_changed.emit(Phase.IDLE)
	action_finished.emit(finished)
	# A press that wasn't a flow link waits in the queue and starts fresh now.
	if phase == Phase.IDLE and not buffer.is_empty():
		var queued: int = buffer.pop_front()
		buffer_changed.emit(buffer)
		_start_opener(queued)


func _try_flow_from_buffer() -> void:
	if phase != Phase.RECOVERY or buffer.is_empty():
		return
	if winded and not is_flow_link_window():
		return # Winded: the press waits for the recovery to end.
	var next_action: CombatActionResource = _follow_up_for(buffer[0])
	if next_action == null:
		return
	if winded and not PULSE_COMMANDS.has(next_action.command):
		return
	var queued: int = buffer.pop_front()
	buffer_changed.emit(buffer)
	# Dodging out of recovery is a cancel, but not a flow: no speed bonus.
	_start(next_action, queued != CombatActionResource.Command.DODGE)


func _follow_up_for(input_command: int) -> CombatActionResource:
	if input_command == CombatActionResource.Command.DODGE:
		return actor.loadout.dodge
	var link: CombatActionResource = actor.loadout.flow_link(current_action, input_command)
	if link == null and assisted_chaining:
		link = _auto_chain(input_command)
	return link


## Adventurer / Squire: light picks the first strike link, heavy the first heavy link.
func _auto_chain(input_command: int) -> CombatActionResource:
	var wants_heavy: bool = input_command == CombatActionResource.Command.HEAVY \
		or input_command == CombatActionResource.Command.FORWARD_HEAVY \
		or input_command == CombatActionResource.Command.BACK_HEAVY
	for link: CombatActionResource in actor.loadout.flow_links_of(current_action):
		if link.effect != CombatActionResource.Effect.STRIKE:
			continue
		if input_command == CombatActionResource.Command.LIGHT:
			return link
		if wants_heavy and link.is_heavy_family():
			return link
	return null


func _start_opener(input_command: int) -> void:
	var action: CombatActionResource = actor.loadout.opener_for(input_command as CombatActionResource.Command)
	if action == null:
		action_rejected.emit(input_command)
		return
	_start(action, false)


func _start(action: CombatActionResource, flowed: bool) -> bool:
	if not actor.try_begin_action(action):
		action_rejected.emit(action.command)
		return false
	var previous: CombatActionResource = current_action
	var from_window: bool = is_flow_link_window()
	if kinetic_rules:
		_count_streak(previous, from_window, action)
	recovery_time = action.recovery_time
	if winded:
		recovery_time = maxf(action.recovery_time, ActorBase.STATIC_MASH_RECOVERY_MS / 1000.0)
	_idle_time = 0.0
	current_action = action
	phase = Phase.WINDUP
	phase_time = 0.0
	flowed_into_current = flowed
	speed_scale = 1.0 + (flow_speed_bonus if flowed else 0.0)
	if flowed and previous != null:
		flow_cancelled.emit(previous, action)
	action_started.emit(action, flowed)
	phase_changed.emit(Phase.WINDUP)
	return true


## The Static Mash Penalty and the Flow-Link Pulse, as `action` starts.
func _count_streak(previous: CombatActionResource, from_window: bool, action: CombatActionResource) -> void:
	if action.command == CombatActionResource.Command.LIGHT:
		lights_in_a_row += 1
		winded = lights_in_a_row >= 3
		return
	if from_window and lights_in_a_row >= 2 and PULSE_COMMANDS.has(action.command):
		flow_link_pulsed.emit(previous, action.command)
	lights_in_a_row = 0
	winded = false
