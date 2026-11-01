## Authoritative resource and mitigation math for one actor: health, stamina,
## resonance pips, poise, guarding and invulnerable frames (02_COMBAT_GDD.md §1).
## Armor shows up here through the stats it sets: damage mitigation, stamina
## regen and the Perfect Guard window (05_ARSENAL_AND_CARDS_GDD.md §2.1).
class_name StatsComponent
extends Node

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal resonance_changed(pips: int, charge: float)
signal poise_changed(current: float, maximum: float)
signal poise_broken
signal knockdown_ended
signal downed
signal revived

enum StrikeOutcome { HIT, GUARDED, PERFECT_GUARD, GUARD_BROKEN, EVADED }

var stats: CharacterStatsResource
var health: float = 100.0
var stamina: float = 100.0
## Fractional pips: 2.5 means two full pips and one half-filled.
var resonance_charge: float = 0.0
var poise: float = 0.0
var knockdown_time_left: float = 0.0
var is_downed: bool = false
var guarding: bool = false
var guard_started_at: float = 0.0
var last_damage_taken: float = 0.0

var _regen_delay_left: float = 0.0
var _poise_regen_delay_left: float = 0.0
var _invulnerable_left: float = 0.0


func setup(base_stats: CharacterStatsResource) -> void:
	stats = base_stats
	health = stats.max_health
	stamina = stats.max_stamina
	poise = stats.max_poise
	resonance_charge = 0.0
	is_downed = false
	knockdown_time_left = 0.0


## Swaps in new base stats (a re-equip), keeping the same share of health.
func rebind(base_stats: CharacterStatsResource, health_ratio_after: float) -> void:
	stats = base_stats
	if not is_downed:
		health = clampf(health_ratio_after, 0.0, 1.0) * stats.max_health
	stamina = minf(stamina, stats.max_stamina)
	health_changed.emit(health, stats.max_health)
	stamina_changed.emit(stamina, stats.max_stamina)


func tick(dt: float, can_regen_stamina: bool) -> void:
	_invulnerable_left = maxf(0.0, _invulnerable_left - dt)
	_regen_delay_left = maxf(0.0, _regen_delay_left - dt)
	if can_regen_stamina and _regen_delay_left <= 0.0 and stamina < stats.max_stamina:
		stamina = minf(stats.max_stamina, stamina + stats.stamina_regen_per_sec * dt)
		stamina_changed.emit(stamina, stats.max_stamina)
	_poise_regen_delay_left = maxf(0.0, _poise_regen_delay_left - dt)
	if knockdown_time_left <= 0.0 and _poise_regen_delay_left <= 0.0 and poise < stats.max_poise and stats.poise_regen_per_sec > 0.0:
		poise = minf(stats.max_poise, poise + stats.poise_regen_per_sec * dt)
		poise_changed.emit(poise, stats.max_poise)
	if knockdown_time_left > 0.0:
		knockdown_time_left -= dt
		if knockdown_time_left <= 0.0:
			knockdown_time_left = 0.0
			poise = stats.max_poise
			poise_changed.emit(poise, stats.max_poise)
			knockdown_ended.emit()


# --- Spending -------------------------------------------------------------

func can_afford(action: CombatActionResource) -> bool:
	return stamina >= action.stamina_cost and resonance_pips() >= action.resonance_cost


## Pays an action's stamina and resonance up front (Phase A). False if it can't.
func spend_for(action: CombatActionResource) -> bool:
	if is_downed or not can_afford(action):
		return false
	if action.stamina_cost > 0.0:
		stamina -= action.stamina_cost
		_regen_delay_left = stats.stamina_regen_delay
		stamina_changed.emit(stamina, stats.max_stamina)
	if action.resonance_cost > 0:
		resonance_charge -= float(action.resonance_cost)
		resonance_changed.emit(resonance_pips(), resonance_charge)
	return true


## Stamina handed back by a card or a sanctuary (Astral Chorus, Hearth Echo).
func restore_stamina(amount: float) -> void:
	if amount <= 0.0 or is_downed:
		return
	stamina = minf(stats.max_stamina, stamina + amount)
	stamina_changed.emit(stamina, stats.max_stamina)


func resonance_pips() -> int:
	return floori(resonance_charge + 0.0001)


func add_resonance(amount: float) -> void:
	var cap: float = float(stats.max_resonance_pips)
	resonance_charge = clampf(resonance_charge + amount, 0.0, cap)
	resonance_changed.emit(resonance_pips(), resonance_charge)


# --- Guard and i-frames ---------------------------------------------------

func begin_guard() -> void:
	guarding = true
	guard_started_at = CombatDirector.game_time()


func end_guard() -> void:
	guarding = false


func grant_invulnerability(seconds: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, seconds)


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Works out what a strike does after guards and i-frames, applies it, and says how it went.
func mitigate_strike(raw_damage: float, poise_damage: float, from_front: bool, unavoidable: bool) -> StrikeOutcome:
	last_damage_taken = 0.0
	if is_downed:
		return StrikeOutcome.EVADED
	if not unavoidable and is_invulnerable():
		return StrikeOutcome.EVADED
	# Armor takes its share first; guards then work on what's left.
	raw_damage *= 1.0 - stats.damage_mitigation
	if is_knocked_down():
		raw_damage *= stats.knockdown_damage_taken
	if not unavoidable and guarding and from_front:
		var since_guard: float = CombatDirector.game_time() - guard_started_at
		if stats.can_perfect_guard and since_guard <= stats.perfect_guard_window:
			return StrikeOutcome.PERFECT_GUARD
		var stamina_cost: float = raw_damage * stats.guard_stamina_per_damage
		if stamina >= stamina_cost:
			stamina -= stamina_cost
			_regen_delay_left = stats.stamina_regen_delay
			stamina_changed.emit(stamina, stats.max_stamina)
			take_damage(raw_damage * (1.0 - stats.guard_damage_reduction))
			return StrikeOutcome.GUARDED
		stamina = 0.0
		stamina_changed.emit(stamina, stats.max_stamina)
		take_damage(raw_damage)
		return StrikeOutcome.GUARD_BROKEN
	take_damage(raw_damage)
	damage_poise(poise_damage)
	return StrikeOutcome.HIT


# --- Health and poise -----------------------------------------------------

func take_damage(amount: float) -> float:
	if is_downed or amount <= 0.0:
		return 0.0
	var dealt: float = minf(amount, health)
	health -= dealt
	last_damage_taken = dealt
	health_changed.emit(health, stats.max_health)
	if health <= 0.0:
		health = 0.0
		is_downed = true
		guarding = false
		downed.emit()
	return dealt


func heal(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	if is_downed:
		revive(minf(amount, stats.max_health) / stats.max_health)
		return amount
	var healed: float = minf(amount, stats.max_health - health)
	health += healed
	health_changed.emit(health, stats.max_health)
	return healed


func revive(health_ratio_after: float) -> void:
	is_downed = false
	health = clampf(health_ratio_after, 0.05, 1.0) * stats.max_health
	stamina = stats.max_stamina
	health_changed.emit(health, stats.max_health)
	stamina_changed.emit(stamina, stats.max_stamina)
	revived.emit()


## Returns true when this hit broke the poise gauge (starts the knockdown).
func damage_poise(amount: float) -> bool:
	if stats.max_poise <= 0.0 or amount <= 0.0 or knockdown_time_left > 0.0:
		return false
	poise = maxf(0.0, poise - amount)
	_poise_regen_delay_left = stats.poise_regen_delay
	poise_changed.emit(poise, stats.max_poise)
	if poise <= 0.0:
		knockdown_time_left = stats.poise_knockdown_time
		poise_broken.emit()
		return true
	return false


func is_knocked_down() -> bool:
	return knockdown_time_left > 0.0


func health_ratio() -> float:
	return health / stats.max_health if stats.max_health > 0.0 else 0.0
