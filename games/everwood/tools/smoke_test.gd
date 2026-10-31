## Headless smoke test for Everwood's combat stack. It loads the Dungeon Dojo,
## seats a Shield Tank, Soul-Tether Healer and Flow DPS, drives them with
## scripted input and checks each Milestone 3 and 4 mechanic actually happens.
## Run from games/everwood:
##   godot --headless --path . --fixed-fps 60 -s res://tools/smoke_test.gd
## Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const DOJO_SCENE: String = "res://src/levels/dungeon_dojo.tscn"
## Simulated seconds to wait for the boss to cast both telegraph kinds.
const TELEGRAPH_TIMEOUT: float = 45.0

const Cmd = CombatActionResource.Command

var dojo: DungeonDojo
var boss: BossDummy
var tank: ActorBase
var healer: ActorBase
var dps: ActorBase

var _passes: int = 0
var _failures: PackedStringArray = PackedStringArray()
var _hit_stops: int = 0
var _flow_speed_scales: Array[float] = []
var _primers: Array[int] = []
var _synergies: Array[String] = []
var _cross_class_synergies: int = 0
var _perfect_guards: int = 0
var _outcomes: Array[int] = []
var _telegraph_kinds: Dictionary[int, int] = {}
var _telegraph_hits: int = 0
var _refusals: PackedStringArray = PackedStringArray()
var _healer_states: Array[StringName] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Everwood smoke test")
	_ensure_autoloads()
	dojo = (load(DOJO_SCENE) as PackedScene).instantiate() as DungeonDojo
	root.add_child(dojo)
	await _seconds(0.1)
	boss = dojo.boss
	_connect_signals()

	await _check_party_and_split_screen()
	_stage_party()
	await _seconds(0.3)
	await _check_flow_cancel_and_hit_stop()
	await _check_prime_and_detonate()
	await _check_taunt()
	await _check_perfect_guard()
	await _check_healer()
	await _check_shadow_sanctuary()
	await _check_squire_auto_evade()
	await _check_telegraphs()
	await _check_boss_reset()

	print("%d passed, %d failed" % [_passes, _failures.size()])
	if not _failures.is_empty():
		print("FAILED: " + "; ".join(_failures))
	quit(0 if _failures.is_empty() else 1)


# --- Checks ---------------------------------------------------------------

func _check_party_and_split_screen() -> void:
	var network: NetworkManager = NetworkManager.current
	_check(PartyMember.make_player_id(2187, 3) == &"2187_3", "composite player id is {peer}_{device}")
	_check(network.roster.has(&"1_0"), "keyboard player seated as 1_0")
	network.request_local_player(1, ClassLoadouts.SOUL_TETHER_HEALER, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.1)
	_check(network.party_size() == 3, "three players seated (got %d)" % network.party_size())
	_check(dojo.grid.view_count() == 3, "split-screen shows 3 views")
	_check(dojo.grid.get_node("Cells").get_child_count() == 4, "3 players get a 4th raid-view cell")
	var shared: bool = true
	for viewport: SubViewport in dojo.grid.viewports():
		shared = shared and viewport.world_3d == dojo.get_world_3d()
	_check(shared, "every SubViewport renders the one shared World3D")

	network.request_local_player(3, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.ADVENTURER)
	await _seconds(0.05)
	_check(dojo.grid.view_count() == 4, "4 local players get 4 views")
	network.request_local_player(4, ClassLoadouts.SHIELD_TANK, InputComponent.AssistMode.ADVENTURER)
	_check(network.party_size() == 4 and _refusals.size() == 1, "a 5th local controller is refused (4 per screen)")
	_check(network._server_register(99, 0, ClassLoadouts.SHIELD_TANK, 0), "a remote player takes the 5th party seat")
	_check(not network._server_register(98, 0, ClassLoadouts.SHIELD_TANK, 0), "a 6th player is refused (party of 5)")
	_check(network.party_size() == 5, "party capped at 5")
	network._server_unregister(&"99_0")
	network.drop_local_player(3)
	await _seconds(0.05)
	_check(network.party_size() == 3 and dojo.grid.view_count() == 3, "leaving players free their seats and views")

	tank = dojo.actors[&"1_0"]
	healer = dojo.actors[&"1_1"]
	dps = dojo.actors[&"1_2"]
	_check(tank.loadout.class_id == ClassLoadouts.SHIELD_TANK and tank.input != null, "Shield Tank built on ActorBase with an InputComponent")
	_check(healer.tether != null, "Soul-Tether Healer has a Soul Tether")
	_check(dps.input.assist_mode == InputComponent.AssistMode.MASTER and is_equal_approx(dps.action_queue.buffer_window, 0.4),
		"Master mode uses the 400 ms buffer")
	_check(is_equal_approx(healer.action_queue.buffer_window, 0.55) and healer.action_queue.assisted_chaining,
		"Adventurer mode uses the 550 ms buffer and auto-chaining")


func _check_flow_cancel_and_hit_stop() -> void:
	var boss_health: float = boss.stats.health
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.26)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.9)
	_check(not _flow_speed_scales.is_empty(), "a buffered light flow-cancels the recovery")
	_check(not _flow_speed_scales.is_empty() and is_equal_approx(_flow_speed_scales[0], 1.15), "Master flow-cancel earns +15% speed")
	_check(_hit_stops > 0, "landed hits trigger hit-stop")
	_check(boss.stats.health < boss_health, "the boss takes damage from a hitbox overlap")
	_check(boss.threat.threat_of(dps.player_id) > 0.0, "hits add to the boss's aggro table")


func _check_prime_and_detonate() -> void:
	await _until_idle(dps)
	_reset_boss_poise()
	dps.input.inject_command(Cmd.FORWARD_HEAVY)
	await _seconds(0.7)
	_check(_primers.has(CombatActionResource.Synergy.STAGGER), "Rising Drive primes Stagger")
	await _until_idle(tank)
	var poise_before: float = boss.stats.poise
	tank.input.inject_command(Cmd.HEAVY)
	await _seconds(1.3)
	_check(_synergies.has("SHATTERPOINT  x1.5 CROSS-CLASS"), "the tank's slam detonates it as a cross-class Shatterpoint")
	_check(_cross_class_synergies > 0, "cross-class detonation is flagged")
	_check(poise_before - boss.stats.poise >= 90.0 or boss.stats.is_knocked_down(), "Shatterpoint adds the bonus poise damage")


func _check_taunt() -> void:
	await _until_idle(tank)
	boss.threat.add_threat(dps.player_id, 5000.0)
	await _seconds(0.1)
	tank.stats.add_resonance(1.0)
	tank.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(0.7)
	_check(boss.threat.taunt_holder == tank.player_id, "Taunt locks the boss onto the tank")
	_check(boss.threat.current_target == tank.player_id, "the boss's target follows the taunt")


func _check_perfect_guard() -> void:
	await _until_idle(tank)
	_reset_boss_poise()
	var threat_before: float = boss.threat.threat_of(tank.player_id)
	var health_before: float = tank.stats.health
	tank.input.inject_guard(true)
	await _seconds(0.05)
	_check(tank.state_machine.is_in(&"guard"), "holding L raises the tank's Active Guard")
	CombatDirector.current.deliver(CombatEvent.strike_from(boss, tank, boss.loadout.openers[0]))
	await _seconds(0.1)
	_check(_perfect_guards == 1, "a guard raised within 200 ms is a Perfect Guard")
	_check(is_equal_approx(tank.stats.health, health_before), "a Perfect Guard takes no damage")
	_check(is_equal_approx(boss.stats.poise, boss.stats.stats.max_poise - CombatDirector.PERFECT_GUARD_POISE), "a Perfect Guard deals 50 poise to the attacker")
	_check(boss.threat.threat_of(tank.player_id) - threat_before >= CombatDirector.PERFECT_GUARD_THREAT, "a Perfect Guard generates big threat")
	await _seconds(0.3)
	CombatDirector.current.deliver(CombatEvent.strike_from(boss, tank, boss.loadout.openers[0]))
	await _seconds(0.05)
	_check(_outcomes.has(StatsComponent.StrikeOutcome.GUARDED), "a late guard still blocks, for stamina")
	tank.input.inject_guard(false)


func _check_healer() -> void:
	# Out of the boss's swing arc, so a swipe can't hide the heal.
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(8.0, 0.0, 9.0)))
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(4.0, 0.0, 11.0)))
	await _until_idle(healer)
	dps.stats.take_damage(40.0)
	var hurt_health: float = dps.stats.health
	healer.tether.bind_actor(dps)
	healer.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(1.2)
	_check(dps.stats.health > hurt_health, "a homing heal flies down the Soul Tether")
	_check(healer.tether.slot_arrow_for(dps.player_id) != "•", "D-Pad slots point at party members")

	await _until_idle(healer)
	healer.stats.add_resonance(1.0)
	healer.input.inject_command(Cmd.TRIGGER_R_HOLD)
	await _seconds(0.6)
	_check(_count_zones(SanctuaryZone.Shape.RING) >= 1, "holding R drops a Green Sanctuary ring")

	await _until_idle(healer)
	dps.place_at(Transform3D(Basis.IDENTITY, healer.global_position + Vector3(9.0, 0.0, 0.0)))
	healer.stats.add_resonance(2.0)
	healer.input.inject_command(Cmd.TRIGGER_BOTH_ULT)
	await _seconds(0.9)
	_check(dps.global_position.distance_to(healer.global_position) < 3.0, "Lifeline Pull yanks the tethered ally to the healer")

	dps.stats.take_damage(9999.0)
	await _seconds(0.05)
	_check(dps.state_machine.is_in(&"downed"), "out of health means downed")
	CombatDirector.current.apply_heal(healer, dps, 20.0)
	await _seconds(0.1)
	_check(not dps.stats.is_downed and dps.state_machine.is_in(&"idle"), "a heal brings a downed ally back")


func _check_shadow_sanctuary() -> void:
	await _until_idle(tank)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 3.0)))
	tank.input.inject_command(Cmd.BACK_HEAVY)
	await _seconds(0.6)
	_check(_count_zones(SanctuaryZone.Shape.CONE) >= 1, "back + heavy raises a Shadow Sanctuary cone")
	healer.place_at(Transform3D(Basis.IDENTITY, tank.global_position + Vector3(0.0, 0.0, 3.0)))
	await _seconds(0.05)
	_check(is_equal_approx(CombatDirector.current.damage_taken_multiplier(healer), 0.4), "allies behind the tank take 60% less damage")
	_check(is_equal_approx(CombatDirector.current.damage_taken_multiplier(tank), 1.0), "the cone doesn't shield the tank itself")


func _check_squire_auto_evade() -> void:
	await _until_idle(healer)
	healer.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
	healer.apply_assist_mode()
	healer.place_at(Transform3D(Basis.IDENTITY, Vector3(14.0, 0.0, 10.0)))
	healer.stats.stamina = healer.stats.stats.max_stamina
	var decal: RaidTelegraphDecal = RaidTelegraphDecal.new()
	decal.configure(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT, 3.5, 1.2, null)
	dojo.telegraphs_root.add_child(decal)
	decal.global_position = healer.global_position + Vector3(0.6, 0.0, 0.0)
	_healer_states.clear()
	await _seconds(1.4)
	_check(_healer_states.has(&"dodge"), "Squire Gambit auto-evades a red telegraph at 85% fill")
	_check(not decal.is_inside_tree() or not decal.contains(healer.global_position), "the auto-evade rolls out of the red zone")
	healer.input.assist_mode = InputComponent.AssistMode.ADVENTURER
	healer.apply_assist_mode()


func _check_telegraphs() -> void:
	# Bring everyone back to the boss so it stays engaged while it casts.
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
		actor.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(randf_range(-3.0, 3.0), 0.0, 4.0)))
	var waited: float = 0.0
	while waited < TELEGRAPH_TIMEOUT and not (_telegraph_kinds.has(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT) and _telegraph_kinds.has(RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK)):
		await _seconds(0.5)
		waited += 0.5
		# Keep the party alive: a wipe resets the fight and restarts the cast cycle.
		for actor: ActorBase in [tank, healer, dps]:
			actor.stats.heal(actor.stats.stats.max_health)
	_check(_telegraph_kinds.has(RaidTelegraphDecal.Kind.CRIMSON_DODGE_OUT), "the boss casts CRIMSON_DODGE_OUT")
	_check(_telegraph_kinds.has(RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK), "the boss casts GOLD_PARTY_SOAK")
	await _seconds(BossDummy.SOAK_CAST_TIME + 1.0)
	_check(_telegraph_hits > 0, "telegraphs resolve into damage on the players inside")


func _check_boss_reset() -> void:
	# The party heads back to the spawn pads, out of aggro range, so the reset sticks.
	for actor: ActorBase in [tank, healer, dps]:
		actor.respawn()
	boss.stats.take_damage(boss.stats.health)
	await _seconds(0.05)
	_check(boss.state_machine.is_in(&"downed"), "the boss can be defeated")
	await _seconds(BossDummy.DEFEAT_RESET_TIME + 0.3)
	_check(not boss.stats.is_downed and is_equal_approx(boss.stats.health, boss.stats.stats.max_health), "the dojo boss rises again at full health")
	_check(boss.threat.aggro_table.is_empty(), "its aggro table resets")
	if not boss.threat.aggro_table.is_empty():
		print("    aggro after reset: %s, boss at %s, engaged=%s" % [boss.threat.aggro_table, boss.global_position, boss.engaged])
		for actor: ActorBase in [tank, healer, dps]:
			print("    %s at %s (%.1f m from boss)" % [actor.player_id, actor.global_position, actor.global_position.distance_to(boss.global_position)])


# --- Helpers --------------------------------------------------------------

## In -s mode autoloads may not exist yet; add them under their autoload names.
func _ensure_autoloads() -> void:
	if NetworkManager.current == null:
		var network: NetworkManager = NetworkManager.new()
		network.name = "Network"
		root.add_child(network)
	if CombatDirector.current == null:
		var director: CombatDirector = CombatDirector.new()
		director.name = "Combat"
		root.add_child(director)


func _connect_signals() -> void:
	var director: CombatDirector = CombatDirector.current
	director.hit_stop_applied.connect(func(_duration: float) -> void: _hit_stops += 1)
	director.primer_applied.connect(func(_target: ActorBase, primer: int) -> void: _primers.append(primer))
	director.synergy_detonated.connect(func(_target: ActorBase, _primer: int, cross_class: bool, label: String) -> void:
		_synergies.append(label)
		if cross_class:
			_cross_class_synergies += 1)
	director.perfect_guard_landed.connect(func(_defender: ActorBase) -> void: _perfect_guards += 1)
	director.hit_resolved.connect(func(event: CombatEvent, outcome: int) -> void:
		_outcomes.append(outcome)
		if event.unavoidable:
			_telegraph_hits += 1)
	director.telegraph_cast.connect(func(decal: RaidTelegraphDecal) -> void:
		_telegraph_kinds[decal.kind] = _telegraph_kinds.get(decal.kind, 0) + 1)
	NetworkManager.current.registration_refused.connect(func(_device: int, reason: String) -> void: _refusals.append(reason))


## Puts the party in front of the boss, facing it, with signals hooked up.
func _stage_party() -> void:
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 2.6)))
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(-1.2, 0.0, 2.6)))
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(2.5, 0.0, 6.0)))
	for actor: ActorBase in [tank, healer, dps]:
		actor.input.inject_move(Vector2.ZERO)
	dps.action_queue.flow_cancelled.connect(func(_from: CombatActionResource, _to: CombatActionResource) -> void:
		_flow_speed_scales.append(dps.action_queue.speed_scale))
	healer.state_machine.state_changed.connect(func(_from: StringName, to: StringName) -> void: _healer_states.append(to))


func _reset_boss_poise() -> void:
	boss.stats.knockdown_time_left = 0.0
	boss.stats.poise = boss.stats.stats.max_poise
	boss.stagger_time_left = 0.0


func _count_zones(shape: SanctuaryZone.Shape) -> int:
	var count: int = 0
	for child: Node in dojo.effects_root.get_children():
		var zone: SanctuaryZone = child as SanctuaryZone
		if zone != null and zone.shape == shape:
			count += 1
	return count


func _until_idle(actor: ActorBase) -> void:
	var waited: float = 0.0
	while (actor.action_queue.is_busy() or not actor.can_act()) and waited < 3.0:
		await physics_frame
		waited += 1.0 / 60.0


func _seconds(duration: float) -> void:
	for frame: int in ceili(duration * 60.0):
		await physics_frame


func _check(ok: bool, label: String) -> void:
	if ok:
		_passes += 1
		print("  PASS  " + label)
	else:
		_failures.append(label)
		print("  FAIL  " + label)
