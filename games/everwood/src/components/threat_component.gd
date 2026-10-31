## A boss's aggro table: who has generated how much threat, and the taunt lock
## that pins the boss on one player for a few seconds.
class_name ThreatComponent
extends Node

signal target_changed(player_id: StringName)
signal taunted(player_id: StringName, duration: float)

## A taunt puts you this far above the current top threat.
const TAUNT_THREAT_BONUS: float = 1.1
## Someone must beat the current target by this much to pull the boss off them.
const PULL_THRESHOLD: float = 1.1

var aggro_table: Dictionary[StringName, float] = {}
var taunt_holder: StringName = &""
var taunt_time_left: float = 0.0
var current_target: StringName = &""


func tick(dt: float) -> void:
	if taunt_time_left > 0.0:
		taunt_time_left -= dt
		if taunt_time_left <= 0.0:
			taunt_time_left = 0.0
			taunt_holder = &""


func add_threat(player_id: StringName, amount: float) -> void:
	if player_id == &"" or amount <= 0.0:
		return
	aggro_table[player_id] = aggro_table.get(player_id, 0.0) + amount


func taunt(player_id: StringName, duration: float) -> void:
	var top: float = 0.0
	for value: float in aggro_table.values():
		top = maxf(top, value)
	aggro_table[player_id] = maxf(aggro_table.get(player_id, 0.0), top * TAUNT_THREAT_BONUS + 1.0)
	taunt_holder = player_id
	taunt_time_left = duration
	taunted.emit(player_id, duration)
	# A taunt turns the boss at once, even mid-knockdown, not on its next decision.
	if current_target != player_id:
		current_target = player_id
		target_changed.emit(player_id)


func threat_of(player_id: StringName) -> float:
	return aggro_table.get(player_id, 0.0)


## Picks who the boss should chase among the players allowed to be targeted.
func top_target(eligible: Array[StringName]) -> StringName:
	var chosen: StringName = &""
	if taunt_holder != &"" and eligible.has(taunt_holder):
		chosen = taunt_holder
	else:
		var best: float = 0.0
		for player_id: StringName in eligible:
			var value: float = aggro_table.get(player_id, 0.0)
			if value > best:
				best = value
				chosen = player_id
		# Sticky aggro: stay on the current target unless someone clearly out-threats them.
		if current_target != &"" and eligible.has(current_target) and chosen != current_target:
			if best < threat_of(current_target) * PULL_THRESHOLD:
				chosen = current_target
	if chosen != current_target:
		current_target = chosen
		target_changed.emit(chosen)
	return chosen


## Players by threat, highest first (for the HUD).
func ranked() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(aggro_table.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return aggro_table[a] > aggro_table[b])
	return ids


func forget(player_id: StringName) -> void:
	aggro_table.erase(player_id)
	if taunt_holder == player_id:
		taunt_holder = &""
		taunt_time_left = 0.0


func clear() -> void:
	aggro_table.clear()
	taunt_holder = &""
	taunt_time_left = 0.0
	current_target = &""
