## A hero's directional combo forms (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §8): it
## listens to every posture the hero starts and keeps the last few as tokens
## (LIGHT, HEAVY, FORWARD_HEAVY, ...). When they end in a combo the party has
## learned (ArsenalCatalog.get_unlocked_combos_for_level), that posture is the
## finisher:
## - it carries the hero its step (2.8 m through the gap, 2.6 m back, or a
##   2.2 m orbit round the foe to its flank) instead of its own;
## - a back-vault starts with its evasion frames;
## - and when it lands, the strike names its combo (CombatEvent.combo_id), so
##   the foe's owner adds the finisher's damage, poise and stun, and a martial
##   lock cracks under a Sundering Gap-Leap.
## The HUD's weapon diamond lights a pip for each step on the way
## (combo_step_advanced). A roll, a guard, a stagger or a second's rest starts
## the run over; a finisher keeps its own posture, so one form can flow into the
## next (Light, Light, Forward+Heavy, then R and L+R is a Grand Sign-Flow).
##
## Composition, like SignFlowComponent: it lives beside the action queue on the
## hero's own peer; the combo travels in each strike's event.
class_name ComboChainComponent
extends Node

signal combo_step_advanced(step_index: int, max_steps: int, combo_name: String)
signal combo_finished(combo: ComboChainResource)

## The smoke test's older checks switch combos off (like SignFlowComponent.enabled).
static var enabled: bool = true

## Idle this long between postures and the run starts over.
const RESET_TIME: float = 1.0
## The most postures remembered (the longest form is three).
const MAX_BUFFER: int = 6
const FINISHER_TEXT_COLOR: Color = Color(1.0, 0.95, 0.78)
const FINISHER_TEXT_SIZE: int = 30

var actor: ActorBase
## The run of postures so far, oldest first.
var _combo_buffer: Array[StringName] = []
## What the HUD shows: steps played of the closest form, its length and name.
var step_index: int = 0
var max_steps: int = 0
var combo_name: String = ""
## The finisher playing now: its form and the action it rides (null when none).
var finisher: ComboChainResource
var finisher_action: CombatActionResource

var _idle: float = 0.0
## Which way a flank orbit goes round the foe: +1 to the hero's right, -1 to the left.
var _orbit_side: float = 1.0
var _finishers: int = 0


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "ComboChainComponent"


func _ready() -> void:
	actor.action_queue.action_started.connect(_on_action_started)
	actor.action_queue.action_interrupted.connect(_on_action_interrupted)
	actor.action_queue.action_finished.connect(_on_action_finished)


## Every physics tick on the hero's peer (ActorBase calls it): a second's rest or a raised guard ends the run.
func tick(delta: float) -> void:
	if actor.action_queue.is_busy():
		_idle = 0.0
		return
	_idle += delta
	if (_idle >= RESET_TIME or actor.stats.guarding) and not _combo_buffer.is_empty():
		reset()


## The postures played so far (a copy), oldest first.
func buffer() -> Array[StringName]:
	return _combo_buffer.duplicate()


## Whether the run so far ends with these postures.
func ends_with(tokens: Array[StringName]) -> bool:
	if tokens.size() > _combo_buffer.size():
		return false
	return _combo_buffer.slice(_combo_buffer.size() - tokens.size()) == tokens


## Finishers played since the hero appeared.
func finishers_played() -> int:
	return _finishers


func reset() -> void:
	_combo_buffer.clear()
	_idle = 0.0
	_emit(0, 0, "")


## The forms the party knows now, with this hero's weapon.
func known_combos() -> Array[ComboChainResource]:
	var weapon: EquipmentItemResource = actor.loadout.weapon
	var tier: int = weapon.equipment_tier if weapon != null else EquipmentItemResource.EquipmentTier.TIER_4_RELIC
	return ArsenalCatalog.current.get_unlocked_combos_for_level(PartyProgress.current.trail_level(), tier)


## Whether `action` is the finisher playing now (its step replaces the action's own).
func has_step_for(action: CombatActionResource) -> bool:
	return enabled and finisher != null and action != null and action == finisher_action \
		and (not is_zero_approx(finisher.step_displacement_m) or finisher.triggers_flank_orbit)


## The finisher's step as a world vector (metres across its wind-up and active
## frames): along the facing, or sideways round the foe for a flank orbit.
func step_vector(action: CombatActionResource) -> Vector3:
	if not has_step_for(action):
		return actor.facing_vector() * action.lunge_distance
	if finisher.triggers_flank_orbit:
		var to_foe: Vector3 = actor.direction_to_soft_target()
		if to_foe == Vector3.ZERO:
			to_foe = actor.facing_vector()
		# Tangent to the circle round the foe, re-aimed every tick, so the step curves round it.
		var tangent: Vector3 = Vector3(-to_foe.z, 0.0, to_foe.x) * _orbit_side
		return tangent.normalized() * finisher.step_displacement_m
	return actor.facing_vector() * finisher.step_displacement_m


## A flank orbit keeps the hero turned to the foe as it circles.
func orbits(action: CombatActionResource) -> bool:
	return has_step_for(action) and finisher.triggers_flank_orbit


## The hero's strike is landing (CombatDirector.report_hit, on this peer): a finisher names its combo.
func on_strike_landed(action: CombatActionResource, event: CombatEvent) -> void:
	if enabled and finisher != null and action == finisher_action:
		event.combo_id = finisher.combo_id


func _on_action_started(action: CombatActionResource, _flowed: bool) -> void:
	finisher = null
	finisher_action = null
	if not enabled:
		return
	if action.effect == CombatActionResource.Effect.DODGE:
		reset()
		return
	var token: StringName = ComboChainResource.token_for(action.command, _sideways())
	if token == &"":
		return
	_idle = 0.0
	_combo_buffer.append(token)
	if _combo_buffer.size() > MAX_BUFFER:
		_combo_buffer = _combo_buffer.slice(_combo_buffer.size() - MAX_BUFFER)
	var known: Array[ComboChainResource] = known_combos()
	var done: ComboChainResource = _completed(known)
	if done == null:
		_emit_progress(known)
		return
	finisher = done
	finisher_action = action
	_finishers += 1
	if done.evasion_iframes_ms > 0:
		actor.stats.grant_invulnerability(done.evasion_iframes_ms / 1000.0)
	if done.triggers_flank_orbit:
		_orbit_side = _side_sign()
	_emit(done.step_count(), done.step_count(), done.display_name)
	if actor.is_local_player():
		CombatDirector.current.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.35),
			"%s!" % done.display_name.to_upper(), FINISHER_TEXT_COLOR, FINISHER_TEXT_SIZE)
	combo_finished.emit(done)
	# The finisher's own posture may open the next form.
	_combo_buffer = [token]


## A stagger, a guard dropped into, or being downed cuts the run off.
func _on_action_interrupted(_action: CombatActionResource) -> void:
	finisher = null
	finisher_action = null
	reset()


func _on_action_finished(action: CombatActionResource) -> void:
	if action == finisher_action:
		finisher = null
		finisher_action = null


## The longest known form the run just finished (the later-taught on a tie), or null.
func _completed(known: Array[ComboChainResource]) -> ComboChainResource:
	var best: ComboChainResource = null
	for listed: ComboChainResource in known:
		if listed.completes(_combo_buffer) and (best == null or listed.step_count() >= best.step_count()):
			best = listed
	return best


## The pips for the form the run is furthest into (the first-taught on a tie).
func _emit_progress(known: Array[ComboChainResource]) -> void:
	var best: ComboChainResource = null
	var best_played: int = 0
	for listed: ComboChainResource in known:
		var played: int = listed.steps_played(_combo_buffer)
		if played > best_played:
			best_played = played
			best = listed
	if best == null:
		_emit(0, 0, "")
	else:
		_emit(best_played, best.step_count(), best.display_name)


func _emit(step: int, steps: int, label: String) -> void:
	if step == step_index and steps == max_steps and label == combo_name:
		return
	step_index = step
	max_steps = steps
	combo_name = label
	combo_step_advanced.emit(step, steps, label)


## Heavy with the stick pushed sideways (and not up or down) is a SIDE_HEAVY.
func _sideways() -> bool:
	return actor.input != null and actor.input.stick_side() != 0 and actor.input.stick_direction() == 0


func _side_sign() -> float:
	if actor.input != null and actor.input.stick_side() < 0:
		return -1.0
	return 1.0
