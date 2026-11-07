## A milestone boss's four gates (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §8), played
## from its BossEncounterResource (TIER_3_FOUR_GATE_BOSS) the same way for any boss:
##
##   Gate 1  100-75%  The Measure    its own blows and casts, and one Glimmer-Spot
##                                   opening (gate_weakness_signs[0], else its counters)
##   Gate 2  75-50%   The Summons    it leaps back, raises an Aegis Mantle (it takes
##                                   a tenth of the damage) and calls three henchmen;
##                                   un-boggarting them (or a One-and-Done) shatters
##                                   the mantle and opens Gate 2's spot. Its health
##                                   can't slip past 50% while the mantle stands.
##   Gate 3  50-25%   The Tempest    its arena telegraphs (the Cairnsman's Gale-Beam)
##                                   and a shifted weakness: Tank Ward-Mantle, Support
##                                   Ink-Share and DPS combos together
##   Gate 4  25-0%    The Seal-Turn  a Challenge-Roar (it holds its blows 45 frames)
##                                   and its inverted Maker-Seal shows for the scaled
##                                   window (180 frames at Lv 10, 45 at Lv 60). A strike
##                                   of the gate's Sign, or a One-and-Done, spins the
##                                   seal right-way up: STATE_UNBOGGART_RELEASE, the
##                                   fight is won and the spirit resolves (the
##                                   Cairnsman is lulled into his cairn). Missed, the
##                                   seal hides until its next roar; and worn all the
##                                   way down, the boss is beaten the plain way.
##
## The boss's owner runs the gates and tells the other peers, which show the
## mantle, the summons and the seal.
class_name BossGateComponent
extends Node3D

signal gate_entered(gate: int)
signal aegis_shattered
signal seal_turned

## The smoke test's older checks switch the gates off (like GlimmerSpotComponent.enabled).
static var enabled: bool = true

enum GateState { GATE_1_MEASURE, GATE_2_SUMMONS, GATE_3_TEMPEST, GATE_4_SEAL_TURN, STATE_UNBOGGART_RELEASE }

const SUMMONS_GATE: int = 1
const TEMPEST_GATE: int = 2
const SEAL_GATE: int = 3
## Behind the Aegis Mantle it takes a tenth of the damage (90% less).
const AEGIS_DAMAGE_TAKEN: float = 0.1
const LEAP_BACK_M: float = 3.0
const LEAP_TIME: float = 0.3
## The henchmen gather this far in front of it.
const SUMMON_AHEAD: float = 3.2
const CHALLENGE_ROAR_FRAMES: int = 45
const FRAMES_PER_SECOND: float = 60.0
const AEGIS_COLOR: Color = Color(0.55, 0.82, 1.0)
## The mantle's shell stands from the ground to here, under the 3.2 m sightline cap.
const AEGIS_TOP: float = 3.0
const SEAL_SIZE: float = 0.38
const SEAL_TURN_TIME: float = 0.4
## The Maker-Seal's colours, as HobSpectrumComponent shows an Iron-Man's.
const SEAL_INVERTED_COLOR: Color = Color(0.42, 0.36, 0.32)
const SEAL_EXPOSED_COLOR: Color = Color(1.0, 0.76, 0.28)
const SEAL_UPRIGHT_COLOR: Color = Color(1.0, 0.9, 0.55)
const ROAR_COLOR: Color = Color(1.0, 0.42, 0.36)
const GATE_COLORS: Array[Color] = [Color(1.0, 0.86, 0.36), Color(0.55, 0.82, 1.0), Color(1.0, 0.45, 0.36), Color(1.0, 0.76, 0.28)]

var actor: ActorBase
## The gate it's in (0 is Gate 1) and what that means now.
var gate: int = 0
var state: GateState = GateState.GATE_1_MEASURE
var aegis_up: bool = false
## Gate 2's henchmen (a summoned MinionCamp), or null.
var summons: MinionCamp
var seal_upright: bool = false
var seals_turned: int = 0

var _roar_left: float = 0.0
var _release_pending: bool = false
var _summon_wave: int = 0
var _aegis: Node3D
var _aegis_material: StandardMaterial3D
var _seal_pivot: Node3D
var _seal: MeshInstance3D
var _seal_material: StandardMaterial3D
var _seal_turn_left: float = 0.0
var _age: float = 0.0


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "BossGates"


func _ready() -> void:
	_build_aegis()
	_build_seal()


func encounter() -> BossEncounterResource:
	return actor.glimmer.encounter if actor.glimmer != null else null


## Playing its gates now: switched on, and its encounter is a four-gate boss.
func is_active() -> bool:
	var met: BossEncounterResource = encounter()
	return enabled and met != null and met.is_four_gate_boss()


## True through Gate 4's Challenge-Roar: it holds its blows.
func is_roaring() -> bool:
	return is_active() and _roar_left > 0.0


func damage_taken_multiplier() -> float:
	return AEGIS_DAMAGE_TAKEN if aegis_up and is_active() else 1.0


## Its Glimmer-Spot may open (not while the Aegis Mantle stands).
func allows_glimmer() -> bool:
	return not (aegis_up and is_active())


## The inverted Maker-Seal is showing: a strike of the gate's Sign turns it.
func is_seal_exposed() -> bool:
	return is_active() and gate == SEAL_GATE and not seal_upright and actor.glimmer.is_open()


func gate_name() -> String:
	return BossEncounterResource.GATE_NAMES[clampi(gate, 0, BossEncounterResource.GATE_COUNT - 1)]


func _process(delta: float) -> void:
	_age += delta
	if _aegis.visible:
		_aegis_material.albedo_color = Color(AEGIS_COLOR, 0.2 + 0.08 * sin(_age * 5.0))
		_aegis.rotate_y(0.6 * delta)
	_seal_pivot.visible = is_active() and gate >= SEAL_GATE and not actor.stats.is_downed or _seal_turn_left > 0.0
	if _seal_pivot.visible:
		var color: Color = SEAL_UPRIGHT_COLOR if seal_upright else (SEAL_EXPOSED_COLOR if actor.glimmer.is_open() else SEAL_INVERTED_COLOR)
		_seal_material.albedo_color = color
		_seal_material.emission = color
	if _seal_turn_left > 0.0:
		_seal_turn_left = maxf(0.0, _seal_turn_left - delta)
	# Pointing down while inverted; the turn spins it half round, in its own plane, to point up.
	var turn: float = 1.0 - _seal_turn_left / SEAL_TURN_TIME if seal_upright else 0.0
	_seal.rotation = Vector3(0.0, PI * smoothstep(0.0, 1.0, turn), 0.0)


func _physics_process(delta: float) -> void:
	_roar_left = maxf(0.0, _roar_left - delta)
	if not is_active() or not actor.is_multiplayer_authority() or state == GateState.STATE_UNBOGGART_RELEASE:
		return
	if actor.is_beaten() or not actor.is_engaged():
		return
	var met: BossEncounterResource = encounter()
	if aegis_up:
		# The Summons can't be skipped: the boss holds above the Tempest's threshold until the mantle shatters.
		var floor_health: float = _aegis_floor_health()
		if actor.stats.health < floor_health:
			actor.stats.health = floor_health
			actor.stats.health_changed.emit(actor.stats.health, actor.stats.stats.max_health)
		if not is_instance_valid(summons) or summons.standing_count() == 0:
			_shatter_aegis()
		return
	if met.gate_for_health(actor.stats.health_ratio()) > gate:
		_enter_gate(gate + 1)


## Health the boss keeps while its Aegis Mantle stands: just over the Tempest's threshold.
func _aegis_floor_health() -> float:
	var met: BossEncounterResource = encounter()
	var share: float = met.gate_thresholds[TEMPEST_GATE - 1] if met != null and met.gate_thresholds.size() >= TEMPEST_GATE else 0.0
	return share * actor.stats.stats.max_health + 1.0


# --- Gates (the owner) ---------------------------------------------------------

func _enter_gate(next: int) -> void:
	_tell_all(&"_show_gate", [next])
	var above: Vector3 = actor.global_position + Vector3.UP * (actor.body_height() + 1.0)
	var director: CombatDirector = CombatDirector.current
	director.announce(above, "GATE %d: %s" % [next + 1, BossEncounterResource.GATE_NAMES[next].to_upper()], GATE_COLORS[next], &"bell")
	match next:
		SUMMONS_GATE:
			_leap_back()
			_tell_all(&"_show_aegis", [true])
			_summon_wave += 1
			var met: BossEncounterResource = encounter()
			var kind: int = ArsenalCatalog.current.henchman_kind(met.gate_2_henchman_id)
			if kind < 0:
				push_warning("BossGateComponent: no henchman %s; a Bramble-Hob answers instead" % met.gate_2_henchman_id)
				kind = WoodlandMinion.Kind.SCUTTLER
			var at: Vector3 = actor.global_position + actor.facing_vector() * SUMMON_AHEAD
			_tell_all(&"_spawn_summons", [at, kind, maxi(1, met.gate_2_henchman_count), _summon_wave])
		TEMPEST_GATE:
			var shifted: Array[int] = actor.glimmer.active_weakness()
			if not shifted.is_empty():
				var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(shifted[0])
				director.announce(above + Vector3.UP * 0.6, "Its weakness shifts to %s!" % seal.display_name, seal.color)
		SEAL_GATE:
			_tell_all(&"_show_roar", [CHALLENGE_ROAR_FRAMES / FRAMES_PER_SECOND])
			director.announce(above + Vector3.UP * 0.6, "CHALLENGE-ROAR!", ROAR_COLOR)
			actor.glimmer.open_window()
	actor.on_boss_gate(next)
	gate_entered.emit(next)


## Gate 2: a quick leap away from whoever it's fighting.
func _leap_back() -> void:
	var foe: ActorBase = actor.soft_target()
	var away: Vector3 = -actor.facing_vector()
	if foe != null:
		var from_foe: Vector3 = actor.global_position - foe.global_position
		from_foe.y = 0.0
		if from_foe.length() > 0.05:
			away = from_foe.normalized()
	actor.start_forced_move(actor.global_position + away * LEAP_BACK_M, LEAP_TIME)


func _shatter_aegis() -> void:
	_tell_all(&"_show_aegis", [false])
	CombatDirector.current.announce(actor.global_position + Vector3.UP * (actor.body_height() + 1.0), "BULWARK MANTLE SHATTERED!", AEGIS_COLOR,
		&"knockdown")
	# Gate 2's own Glimmer-Spot opens at once.
	actor.glimmer.open_window()
	aegis_shattered.emit()


## The foe's owner judges a strike (ActorBase.receive_strike, before the
## Glimmer-Spot): a One-and-Done shatters the Aegis Mantle; in Gate 4 a strike of
## the gate's Sign (or a One-and-Done) while the seal shows turns it. True when it turned the seal.
func filter_strike(event: CombatEvent) -> bool:
	if not is_active() or state == GateState.STATE_UNBOGGART_RELEASE or event.unavoidable:
		return false
	if aegis_up and event.cracks_lock:
		_shatter_aegis()
		return false
	if aegis_up:
		# Behind the mantle no blow, however big, takes it past the Tempest's threshold.
		var scale: float = AEGIS_DAMAGE_TAKEN * (1.0 - actor.stats.stats.damage_mitigation)
		if actor.stats.is_knocked_down():
			scale *= actor.stats.stats.knockdown_damage_taken
		var room: float = actor.stats.health - _aegis_floor_health()
		event.damage = minf(event.damage, maxf(0.0, room) / maxf(0.0001, scale))
	if not is_seal_exposed():
		return false
	if event.cracks_lock or encounter().is_countered_in_gate(event.counter_sign(), SEAL_GATE):
		_release_pending = true
		seals_turned += 1
		_tell_all(&"_show_seal_turn", [])
		CombatDirector.current.announce(actor.global_position + Vector3.UP * (actor.body_height() + 1.0), "SEAL-TURN!  THE MAKER-SEAL STANDS RIGHT-WAY UP",
			SEAL_UPRIGHT_COLOR, &"seal_iron_root")
		seal_turned.emit()
		return true
	return false


## After the strike lands: a turned seal releases the spirit, and the fight is won.
func after_strike(_event: CombatEvent, _outcome: int) -> void:
	if not _release_pending:
		return
	_release_pending = false
	_tell_all(&"_show_release", [])
	CombatDirector.current.announce(actor.global_position + Vector3.UP * (actor.body_height() + 1.6), "%s is un-boggarted!" % actor.display_name(),
		SEAL_UPRIGHT_COLOR, &"victory")
	if not actor.stats.is_downed:
		actor.stats.take_damage(actor.stats.health)


## Back to Gate 1 (the boss's fight reset, a wipe): no mantle, no summons, the seal hidden.
func reset() -> void:
	if actor.is_multiplayer_authority():
		_tell_all(&"_show_reset", [])
	else:
		_show_reset()


## Runs `method` here and on every peer that has the instance loaded.
func _tell_all(method: StringName, args: Array) -> void:
	callv(method, args)
	for peer_id: int in InstanceManager.current.live_remote_peers():
		var call_args: Array = [peer_id, method]
		call_args.append_array(args)
		callv(&"rpc_id", call_args)


# --- What every peer shows -----------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func _show_gate(next: int) -> void:
	gate = next
	state = next as GateState


@rpc("authority", "call_remote", "reliable")
func _show_aegis(on: bool) -> void:
	aegis_up = on
	_aegis.visible = on
	if not on:
		SignMark.shockwave(CombatDirector.current.effects_root, actor.global_position, AEGIS_COLOR)


@rpc("authority", "call_remote", "reliable")
func _spawn_summons(at: Vector3, kind: int, count: int, wave: int) -> void:
	_clear_summons()
	var holder: Node = actor.get_parent()
	if holder == null:
		return
	var camp: MinionCamp = MinionCamp.new()
	camp.name = "GateSummons%d" % wave
	camp.summoned = true
	camp.camp_name = "Summoned kin"
	var kinds: Array[int] = []
	for index: int in count:
		kinds.append(kind)
	camp.kinds = kinds
	holder.add_child(camp)
	camp.global_position = at
	camp.spawn_minions()
	summons = camp


@rpc("authority", "call_remote", "reliable")
func _show_roar(seconds: float) -> void:
	_roar_left = seconds


@rpc("authority", "call_remote", "reliable")
func _show_seal_turn() -> void:
	seal_upright = true
	_seal_turn_left = SEAL_TURN_TIME
	if actor.glimmer != null:
		actor.glimmer.close()
	SignMark.shockwave(CombatDirector.current.effects_root, actor.global_position, SEAL_UPRIGHT_COLOR)


@rpc("authority", "call_remote", "reliable")
func _show_release() -> void:
	state = GateState.STATE_UNBOGGART_RELEASE
	aegis_up = false
	_aegis.visible = false
	_clear_summons()


@rpc("authority", "call_remote", "reliable")
func _show_reset() -> void:
	gate = 0
	state = GateState.GATE_1_MEASURE
	aegis_up = false
	seal_upright = false
	_roar_left = 0.0
	_release_pending = false
	_seal_turn_left = 0.0
	_aegis.visible = false
	_clear_summons()


func _clear_summons() -> void:
	if is_instance_valid(summons):
		summons.queue_free()
	summons = null


# --- Looks -----------------------------------------------------------------------

## The Aegis Mantle: a glassy shell from the ground to 3.0 m, banded at the waist.
func _build_aegis() -> void:
	_aegis = Node3D.new()
	_aegis.name = "AegisMantle"
	_aegis_material = StorybookMaterial.glowing(AEGIS_COLOR, 1.4)
	_aegis_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aegis_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aegis_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var radius: float = actor.body_radius() * 1.6
	_aegis.add_child(ShapeKit.no_shadow(ShapeKit.cylinder("Shell", radius, radius * 1.1, AEGIS_TOP, Vector3(0.0, AEGIS_TOP * 0.5, 0.0), _aegis_material, 20)))
	var band: StandardMaterial3D = StorybookMaterial.glowing(AEGIS_COLOR, 3.0)
	_aegis.add_child(ShapeKit.no_shadow(ShapeKit.torus("Band", radius * 1.02, radius * 1.1, Vector3(0.0, AEGIS_TOP * 0.5, 0.0), band)))
	_aegis.visible = false
	add_child(_aegis)


## The Maker-Seal on its chest: a glowing triangle facing out, pointing down until it's turned.
func _build_seal() -> void:
	_seal_pivot = Node3D.new()
	_seal_pivot.name = "MakerSeal"
	_seal_pivot.position = Vector3(0.0, actor.body_height() * 0.62, -actor.body_radius() * 1.02)
	_seal_pivot.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_seal_pivot.visible = false
	add_child(_seal_pivot)
	_seal_material = StorybookMaterial.glowing(SEAL_INVERTED_COLOR, 2.6)
	_seal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_seal = ShapeKit.no_shadow(ShapeKit.cylinder("Triangle", SEAL_SIZE, SEAL_SIZE, 0.06, Vector3.ZERO, _seal_material, 3))
	_seal_pivot.add_child(_seal)


## Whether the Maker-Seal shows on its chest now, and which way it points.
func is_seal_showing() -> bool:
	return _seal_pivot != null and _seal_pivot.visible
