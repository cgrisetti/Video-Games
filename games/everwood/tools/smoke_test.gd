## Headless smoke test for Everwood. It starts where the game starts, in Hub
## Town, and checks every system end to end:
##   - the Input Map, the keyboard as Player 1 and pads hot-joining (faked
##     presses and plug-ins, one device at a time), D-Pad tethers and chords
##   - party caps, then the Raid Portal into the Dungeon Dojo while hosting ENet
##   - combat: flow-cancels and their windows, hit-stop, all three cross-class
##     detonations and their rewards and cues, poise, taunt, Perfect Guard,
##     heals, Lifeline, Shadow Sanctuary, Squire auto-evade and auto-guard,
##     soak scaling for small parties, telegraphs, wipes
##   - AI companions backfilling missing roles, fighting by their Gambits and
##     stepping aside when people rejoin
##   - the victory: slow motion, the banner, the reward chest and its Dojo
##     Shards, and the gold portal home with the same ENet session still up
##   - the Shard Vendor in Hub Town: its menu on the keyboard, upgrades for
##     the whole party, refusals, saving and loading
## Run from games/everwood:
##   godot --headless --path . --fixed-fps 60 -s res://tools/smoke_test.gd
## Exits 0 when every check passes, 1 otherwise.
extends SceneTree

const HUB_SCENE: String = "res://src/levels/hub_town.tscn"
## Hosting on a spare port, so a game left running on 7777 doesn't clash.
const TEST_PORT: int = 7791
## Fake pads use high indices so a real pad plugged into this machine can't collide.
const FAKE_PADS: Array[int] = [5, 6, 7, 8]
const PORTAL_TIMEOUT: float = 8.0
## Simulated seconds to wait for the boss to cast both telegraph kinds.
const TELEGRAPH_TIMEOUT: float = 50.0
## Simulated seconds of fighting alongside companions.
const COMPANION_FIGHT_TIME: float = 8.0
## The test's own save file, so it never touches the real one.
const TEST_SAVE_PATH: String = "user://smoke_test_progress.cfg"

const Cmd = CombatActionResource.Command

var dojo: DungeonDojo
var boss: BossDummy
var tank: ActorBase
var healer: ActorBase
var dps: ActorBase

var _passes: int = 0
var _failures: PackedStringArray = PackedStringArray()
var _commands: Dictionary[StringName, Array] = {}
var _hit_stops: int = 0
var _flow_speed_scales: Array[float] = []
var _primers: Array[int] = []
var _synergies: Array[String] = []
var _cross_class_synergies: int = 0
var _perfect_guards: int = 0
var _companion_perfect_guards: int = 0
var _outcomes: Array[int] = []
var _telegraph_kinds: Dictionary[int, int] = {}
var _telegraph_hits: int = 0
var _refusals: PackedStringArray = PackedStringArray()
var _healer_states: Array[StringName] = []
var _cue_sounds: Array[StringName] = []
var _audio_cues: Array[StringName] = []
var _portal_countdowns: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Everwood smoke test")
	_remove_file(TEST_SAVE_PATH)
	PartyProgress.current.use_save_file(TEST_SAVE_PATH)
	change_scene_to_file(HUB_SCENE)
	await _seconds(0.2)
	_connect_global_signals()

	await _check_hub_and_input_map()
	await _check_keyboard_is_player_one()
	await _check_hot_join_and_pad_mapping()
	await _seat_trinity()
	await _check_party_caps()
	await _check_portal_into_dojo()
	_stage_party()
	await _seconds(0.3)
	await _check_flow_cancel_and_hit_stop()
	await _check_flow_windows()
	await _check_synergies()
	await _check_poise_and_knockdown()
	await _check_taunt()
	await _check_perfect_guard()
	await _check_healer()
	await _check_shadow_sanctuary()
	await _check_squire_auto_evade()
	await _check_squire_auto_guard()
	await _check_soak_scaling()
	await _check_telegraphs()
	await _check_wipe_resets_fight()
	await _check_companion_backfill()
	await _check_victory_and_loot()
	await _check_shard_vendor()
	_check_audio_cues()
	NetworkManager.current.leave_game()
	_remove_file(TEST_SAVE_PATH)

	print("%d passed, %d failed" % [_passes, _failures.size()])
	if not _failures.is_empty():
		print("FAILED: " + "; ".join(_failures))
	quit(0 if _failures.is_empty() else 1)


# --- Hub Town, Input Map, hot-join ----------------------------------------

func _check_hub_and_input_map() -> void:
	_check(current_scene is HubTown, "the game starts in Hub Town")
	_check(ProjectSettings.get_setting("application/run/main_scene") == HUB_SCENE, "Hub Town is the main scene")
	_check(InstanceManager.current.instance_id == InstanceManager.HUB_TOWN and InstanceManager.current.is_live(), "Hub Town is the live instance")
	var actions: Array[StringName] = [InputComponent.ACTION_MOVE_LEFT, InputComponent.ACTION_MOVE_RIGHT,
		InputComponent.ACTION_MOVE_FORWARD, InputComponent.ACTION_MOVE_BACK, InputComponent.ACTION_CAMERA_LEFT,
		InputComponent.ACTION_CAMERA_RIGHT, InputComponent.ACTION_JOIN]
	actions.append_array(InputComponent.BUTTON_ACTIONS)
	var missing: PackedStringArray = PackedStringArray()
	for action: StringName in actions:
		if not InputMap.has_action(action):
			missing.append(action)
	_check(missing.is_empty(), "every player action is in project.godot's Input Map %s" % ("" if missing.is_empty() else str(missing)))
	_check(InputComponent.binding_label(InputComponent.ACTION_LIGHT, 0) == "J", "keyboard light reads as J")
	_check(InputComponent.binding_label(InputComponent.ACTION_LIGHT, FAKE_PADS[0] + 1) == "X"
		and InputComponent.binding_label(InputComponent.ACTION_TRIGGER_L, FAKE_PADS[0] + 1) == "LT", "a generic pad reads as Xbox letters")
	_check(InputComponent._pad_button_name(JOY_BUTTON_X, InputComponent.PadFamily.PLAYSTATION) == "□"
		and InputComponent._pad_button_name(JOY_BUTTON_A, InputComponent.PadFamily.PLAYSTATION) == "✕", "a PlayStation pad reads as shapes")


func _check_keyboard_is_player_one() -> void:
	var network: NetworkManager = NetworkManager.current
	# Clear any real pad seated at launch, so the test doesn't depend on what's plugged in.
	for seat: PartyMember in network.ordered_members():
		if seat.device_id != InputComponent.KEYBOARD_DEVICE:
			network.drop_local_player(seat.device_id)
	await _seconds(0.05)
	var keyboard: PartyMember = network.member(&"1_0")
	_check(keyboard != null and keyboard.slot == 0 and network.party_size() == 1, "keyboard and mouse is seated as Player 1 (1_0)")
	_check(_hub().grid.view_count() == 1, "one player fills the screen")
	_capture(_hub().actors[&"1_0"])
	_key(KEY_J, true)
	await _seconds(0.05)
	_key(KEY_J, false)
	_check(_commands_of(&"1_0").has(Cmd.LIGHT), "J on the keyboard is Player 1's light attack")

	_key(KEY_ENTER, true)
	await _seconds(LevelBase.LEAVE_HOLD_TIME + 0.2)
	_key(KEY_ENTER, false)
	await _seconds(0.05)
	_check(not network.roster.has(&"1_0") and _hub().grid.view_count() == 0, "holding Enter leaves the party")
	_key(KEY_ENTER, true)
	await _seconds(0.05)
	_key(KEY_ENTER, false)
	await _seconds(0.05)
	_check(network.roster.has(&"1_0") and network.member(&"1_0").slot == 0, "tapping Enter rejoins as Player 1")


func _check_hot_join_and_pad_mapping() -> void:
	var network: NetworkManager = NetworkManager.current
	var hub: LevelBase = _hub()
	Input.joy_connection_changed.emit(FAKE_PADS[0], true)
	await _seconds(0.05)
	_check(network.roster.has(_pad_id(0)) and hub.grid.view_count() == 2, "plugging in a pad hot-joins Player 2 and splits the screen in two")
	Input.joy_connection_changed.emit(FAKE_PADS[1], true)
	await _seconds(0.05)
	_check(hub.grid.view_count() == 3 and hub.grid.get_node("Cells").get_child_count() == 4, "a second pad makes 3 views plus the raid view")
	Input.joy_connection_changed.emit(FAKE_PADS[2], true)
	await _seconds(0.05)
	_check(hub.grid.view_count() == 4, "a third pad makes a 2 x 2 grid")
	Input.joy_connection_changed.emit(FAKE_PADS[3], true)
	await _seconds(0.05)
	_check(hub.grid.view_count() == 4 and not _refusals.is_empty(), "a fifth controller is refused (4 per screen)")
	_check(network.member(_pad_id(0)).class_id == ClassLoadouts.SOUL_TETHER_HEALER
		and network.member(_pad_id(1)).class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS
		and network.member(_pad_id(2)).class_id == ClassLoadouts.SHIELD_TANK, "hot-joined players fill out the trinity")

	var pad_tank: int = FAKE_PADS[2]
	var tank_id: StringName = _pad_id(2)
	for index: int in 3:
		_capture(hub.actors[_pad_id(index)])
	_pad_button(pad_tank, JOY_BUTTON_X, true)
	await _seconds(0.05)
	_pad_button(pad_tank, JOY_BUTTON_X, false)
	_check(_commands_of(tank_id).has(Cmd.LIGHT) and not _commands_of(_pad_id(0)).has(Cmd.LIGHT),
		"X / □ on one pad is that player's light attack, and only theirs")
	await _press_heavy_with_stick(pad_tank, -1.0)
	_check(_commands_of(tank_id).back() == Cmd.FORWARD_HEAVY, "stick up + Y / △ is Forward + Heavy")
	await _press_heavy_with_stick(pad_tank, 1.0)
	_check(_commands_of(tank_id).back() == Cmd.BACK_HEAVY, "stick down + Y / △ is Back + Heavy")
	_pad_axis(pad_tank, JOY_AXIS_LEFT_Y, -1.0)
	await _seconds(0.05)
	_pad_axis(pad_tank, JOY_AXIS_LEFT_Y, 0.0)
	await _seconds(0.05)
	_pad_button(pad_tank, JOY_BUTTON_Y, true)
	await _seconds(0.05)
	_pad_button(pad_tank, JOY_BUTTON_Y, false)
	_check(_commands_of(tank_id).back() == Cmd.FORWARD_HEAVY, "a quick flick up, then Y / △, still counts as Forward + Heavy")
	await _seconds(0.3)
	await _press_heavy_with_stick(pad_tank, 0.0)
	_check(_commands_of(tank_id).back() == Cmd.HEAVY, "Y / △ with the stick centred is a plain heavy")
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_LEFT, 1.0)
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _seconds(0.1)
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_LEFT, 0.0)
	_pad_axis(pad_tank, JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check(_commands_of(tank_id).back() == Cmd.TRIGGER_BOTH_ULT, "LT + RT / L2 + R2 together is the ultimate")

	var pad_healer: int = FAKE_PADS[0]
	var pad_healer_actor: ActorBase = hub.actors[_pad_id(0)]
	var allies: Array[ActorBase] = pad_healer_actor.tether.allies()
	_pad_button(pad_healer, JOY_BUTTON_DPAD_RIGHT, true)
	await _seconds(0.05)
	_pad_button(pad_healer, JOY_BUTTON_DPAD_RIGHT, false)
	_check(allies.size() == 3 and pad_healer_actor.tether.tethered_id == allies[1].player_id, "D-Pad → tethers the healer to the second ally")
	_pad_button(pad_healer, JOY_BUTTON_DPAD_UP, true)
	await _seconds(0.05)
	_pad_button(pad_healer, JOY_BUTTON_DPAD_UP, false)
	_check(pad_healer_actor.tether.tethered_id == allies[0].player_id, "D-Pad ↑ tethers the first ally")

	var pad_dps: int = FAKE_PADS[1]
	_pad_button(pad_dps, JOY_BUTTON_BACK, true)
	await _seconds(0.2)
	_pad_button(pad_dps, JOY_BUTTON_BACK, false)
	await _seconds(0.05)
	_check(network.member(_pad_id(1)).class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS, "a quick tap of View / Create doesn't change class")
	_pad_button(pad_dps, JOY_BUTTON_BACK, true)
	await _seconds(InputComponent.MENU_HOLD_TIME + 0.15)
	_pad_button(pad_dps, JOY_BUTTON_BACK, false)
	await _seconds(0.05)
	_check(network.member(_pad_id(1)).class_id == ClassLoadouts.SHIELD_TANK and hub.actors[_pad_id(1)].loadout.class_id == ClassLoadouts.SHIELD_TANK,
		"holding View / Create changes class")

	for index: int in [2, 1, 0]:
		Input.joy_connection_changed.emit(FAKE_PADS[index], false)
	await _seconds(0.05)
	_check(network.party_size() == 1 and hub.grid.view_count() == 1, "unplugging pads drops those players and merges the screen back")


## The keyboard player, plus a healer and a DPS on devices 1 and 2, driven by script.
func _seat_trinity() -> void:
	var network: NetworkManager = NetworkManager.current
	network.request_local_player(1, ClassLoadouts.SOUL_TETHER_HEALER, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.05)
	_check(network.member(&"1_0").class_id == ClassLoadouts.SHIELD_TANK and network.party_size() == 3, "a Shield Tank, Soul-Tether Healer and Flow DPS are seated")


func _check_party_caps() -> void:
	var network: NetworkManager = NetworkManager.current
	_check(PartyMember.make_player_id(2187, 3) == &"2187_3", "composite player id is {peer}_{device}")
	_check(network._server_register(99, 0, ClassLoadouts.SHIELD_TANK, 0), "a remote player takes the 4th seat")
	_check(network._server_register(98, 0, ClassLoadouts.SHIELD_TANK, 0), "a second remote player takes the 5th seat")
	_check(not network._server_register(97, 0, ClassLoadouts.SHIELD_TANK, 0) and network.party_size() == 5, "a 6th player is refused (party of 5)")
	network._server_unregister(&"99_0")
	network._server_unregister(&"98_0")
	await _seconds(0.05)
	_check(network.party_size() == 3, "leaving players free their seats")


func _check_portal_into_dojo() -> void:
	var network: NetworkManager = NetworkManager.current
	_check(network.host_game(TEST_PORT) == OK and network.is_online(), "hosting an ENet session on a test port")
	var session: MultiplayerPeer = root.multiplayer.multiplayer_peer
	var hub: HubTown = current_scene as HubTown
	hub.raid_portal.countdown_started.connect(func() -> void: _portal_countdowns += 1)
	_gather_on(hub.raid_portal, hub)
	await _until_live_in(InstanceManager.DUNGEON_DOJO)
	_check(_portal_countdowns == 1, "the whole party on the Raid Portal starts its countdown")
	_check(current_scene is DungeonDojo and InstanceManager.current.instance_id == InstanceManager.DUNGEON_DOJO, "the portal moves the party into the Dungeon Dojo")
	_check(root.multiplayer.multiplayer_peer == session and network.is_online(), "the ENet session survives the instance change")
	dojo = current_scene as DungeonDojo
	boss = dojo.boss
	_check(network.party_size() == 3 and dojo.actors.size() == 3 and dojo.grid.view_count() == 3, "the party and its split-screen views arrive intact")
	tank = dojo.actors[&"1_0"]
	healer = dojo.actors[&"1_1"]
	dps = dojo.actors[&"1_2"]
	_check(dps.input.assist_mode == InputComponent.AssistMode.MASTER and is_equal_approx(dps.action_queue.buffer_window, 0.4),
		"assist modes carry across (Master: 400 ms buffer)")
	_check(is_equal_approx(healer.action_queue.buffer_window, 0.55) and healer.action_queue.assisted_chaining,
		"Adventurer mode: 550 ms buffer and auto-chaining")


# --- Combat ---------------------------------------------------------------

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
	_check(is_equal_approx(boss.stats.stats.max_health, BossDummy.HEALTH_BASE + BossDummy.HEALTH_PER_PLAYER * 3.0), "the boss's health scales to a party of 3")
	boss.scale_health_to_party(1)
	var solo: float = boss.stats.stats.max_health
	boss.scale_health_to_party(5)
	var five: float = boss.stats.stats.max_health
	boss.scale_health_to_party(3)
	_check(is_equal_approx(solo, 1400.0) and is_equal_approx(five, 3400.0), "solo 1400 hp, party of 5 3400 hp")


## The Phase C buffer window: 400 ms in Master, 550 ms assisted, never in wind-up.
func _check_flow_windows() -> void:
	boss.set_physics_process(false)
	await _until_idle(dps)
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(12.0, 0.0, 10.0)))
	dps.stats.stamina = dps.stats.stats.max_stamina
	var flows: int = _flow_speed_scales.size()
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.08)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(0.8)
	_check(_flow_speed_scales.size() == flows, "a press during wind-up is too early to buffer")
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.HEAVY)
	await _seconds(0.5)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(1.2)
	_check(_flow_speed_scales.size() == flows, "Master: a press 0.51 s before the end is outside the 400 ms window")
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.HEAVY)
	await _seconds(0.75)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(1.0)
	_check(_flow_speed_scales.size() == flows + 1 and is_equal_approx(_flow_speed_scales.back(), 1.15), "Master: inside the window it flows at +15%")
	NetworkManager.current.update_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.ADVENTURER)
	await _seconds(0.05)
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.HEAVY)
	await _seconds(0.5)
	dps.input.inject_command(Cmd.LIGHT)
	await _seconds(1.2)
	_check(_flow_speed_scales.size() == flows + 2 and is_equal_approx(_flow_speed_scales.back(), 1.0), "Adventurer: the same press is inside its 550 ms window, with no speed bonus")
	NetworkManager.current.update_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.05)
	boss.set_physics_process(true)


## All three primers, each detonated by a different class, rewarding both players.
func _check_synergies() -> void:
	boss.set_physics_process(false) # Hold the boss still so everyone stays in reach.
	await _detonate(Cmd.FORWARD_HEAVY, tank, CombatActionResource.Synergy.STAGGER, "SHATTERPOINT  x1.5 CROSS-CLASS", &"synergy_stagger")
	_check(boss.stats.is_knocked_down() or boss.stats.poise <= boss.stats.stats.max_poise - 90.0, "Shatterpoint adds the bonus poise damage")
	_reset_boss_poise()
	var health_before: float = boss.stats.health
	await _detonate(Cmd.BACK_HEAVY, healer, CombatActionResource.Synergy.FROST, "GLACIAL RUPTURE  x1.5 CROSS-CLASS", &"synergy_frost")
	_check(health_before - boss.stats.health >= CombatDirector.FROST_BONUS_DAMAGE * CombatDirector.CROSS_CLASS_MULTIPLIER, "Glacial Rupture adds the bonus damage")
	healer.stats.take_damage(40.0)
	var hurt_health: float = healer.stats.health
	await _detonate(Cmd.TRIGGER_L_SKILL, tank, CombatActionResource.Synergy.RADIANT, "DAWNBURST  x1.5 CROSS-CLASS", &"synergy_radiant")
	_check(healer.stats.health > hurt_health, "Dawnburst heals the party around the boss")
	_check(_cross_class_synergies >= 3, "cross-class detonations are flagged")
	boss.set_physics_process(true)


func _detonate(primer_command: int, detonator: ActorBase, primer: int, label: String, sound: StringName) -> void:
	await _until_idle(dps)
	await _until_idle(detonator)
	_face_boss(dps, Vector3(-1.4, 0.0, 2.6))
	_face_boss(detonator, Vector3(1.3, 0.0, 2.4))
	for actor: ActorBase in [dps, detonator]:
		actor.stats.stamina = actor.stats.stats.max_stamina
		actor.stats.resonance_charge = 0.0
	var rewards_before: int = _cue_sounds.count(&"reward")
	dps.input.inject_command(primer_command)
	await _seconds(0.75)
	_check(_primers.has(primer), "%s primes %s" % [PlayerHUD.command_name(primer_command), CombatDirector.current.synergy_primer_name(primer)])
	detonator.input.inject_command(Cmd.HEAVY)
	await _seconds(1.4)
	_check(_synergies.has(label), "%s detonates it as %s" % [detonator.loadout.display_name, label])
	_check(dps.stats.resonance_charge >= 0.7 and detonator.stats.resonance_charge >= 0.7,
		"%s rewards both players (+¾ pip each)" % CombatDirector.current.synergy_name(primer))
	_check(_cue_sounds.count(&"reward") - rewards_before >= 2 and _audio_cues.has(sound), "%s shows a burst on both players and plays its sound" % CombatDirector.current.synergy_name(primer))


func _check_poise_and_knockdown() -> void:
	_reset_boss_poise()
	CombatDirector.current.deliver(_strike(tank, boss, 0.0, 30.0))
	await _seconds(1.0)
	_check(is_equal_approx(boss.stats.poise, boss.stats.stats.max_poise - 30.0), "poise holds for a moment after a hit")
	await _seconds(boss.stats.stats.poise_regen_delay + 0.6)
	_check(boss.stats.poise >= boss.stats.stats.max_poise - 10.0, "then it regenerates, so a break needs a focused burst")
	CombatDirector.current.deliver(_strike(tank, boss, 0.0, 500.0))
	await _seconds(0.05)
	var before: float = boss.stats.health
	CombatDirector.current.deliver(_strike(tank, boss, 40.0, 0.0))
	await _seconds(0.05)
	_check(boss.stats.is_knocked_down() and is_equal_approx(before - boss.stats.health, 50.0), "a knocked-down boss takes x1.25 damage")
	_reset_boss_poise()


func _check_taunt() -> void:
	_stage_party()
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
	tank.stats.resonance_charge = 0.0
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
	_check(tank.stats.resonance_charge >= CombatDirector.PERFECT_GUARD_RESONANCE, "a Perfect Guard earns half a pip")
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
	healer.stats.resonance_charge = 0.0
	dps.stats.take_damage(40.0)
	var hurt_health: float = dps.stats.health
	healer.tether.bind_actor(dps)
	healer.input.inject_command(Cmd.TRIGGER_R_SKILL)
	await _seconds(1.2)
	_check(dps.stats.health > hurt_health, "a homing heal flies down the Soul Tether")
	_check(healer.stats.resonance_charge > 0.1, "healing fills the healer's resonance")
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


## Squire Gambit guards the boss's Crushing Swipe for you (with 25+ stamina);
## a Squire DPS, who has no guard, rolls clear instead.
func _check_squire_auto_guard() -> void:
	boss.set_physics_process(false) # The test starts each swipe itself.
	boss.cancel_action()
	await _until_idle(tank)
	_reset_boss_poise()
	boss.threat.taunt(tank.player_id, 5.0)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.4))
	tank.input.inject_guard(false)
	tank.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
	tank.apply_assist_mode()
	tank.stats.stamina = tank.stats.stats.max_stamina
	await _seconds(0.1)
	_check(not tank.state_machine.is_in(&"guard"), "no swipe, no guard")
	var outcomes_before: int = _outcomes.size()
	boss.action_queue.request(Cmd.LIGHT)
	await _seconds(0.1)
	_check(tank.input.is_auto_guarding() and tank.state_machine.is_in(&"guard"), "Squire Gambit raises the guard as the boss winds up its Crushing Swipe")
	boss.set_physics_process(true)
	await _seconds(1.2)
	_check(_outcomes.slice(outcomes_before).has(StatsComponent.StrikeOutcome.GUARDED), "the swipe lands on the raised guard")
	_check(not tank.input.is_auto_guarding() and not tank.state_machine.is_in(&"guard"), "and the guard drops once the swing is over")

	boss.set_physics_process(false)
	boss.cancel_action()
	await _until_idle(tank)
	tank.stats.stamina = InputComponent.AUTO_GUARD_MIN_STAMINA - 5.0
	boss.action_queue.request(Cmd.LIGHT)
	await _seconds(0.1)
	_check(not tank.input.is_auto_guarding() and not tank.state_machine.is_in(&"guard"), "with under 25 stamina there's no auto-guard")
	boss.cancel_action()
	tank.input.assist_mode = InputComponent.AssistMode.ADVENTURER
	tank.apply_assist_mode()
	tank.stats.stamina = tank.stats.stats.max_stamina

	await _until_idle(dps)
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 9.0))
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.2))
	dps.input.assist_mode = InputComponent.AssistMode.SQUIRE_GAMBIT
	dps.apply_assist_mode()
	dps.stats.stamina = dps.stats.stats.max_stamina
	var start: Vector3 = dps.global_position
	boss.action_queue.request(Cmd.LIGHT)
	await _seconds(0.1)
	_check(dps.state_machine.is_in(&"dodge"), "a Squire DPS, with no guard, rolls clear of the swipe")
	await _seconds(0.4)
	_check(not boss.swipe_threatens(dps, 0.0) and dps.global_position.distance_to(boss.global_position) > start.distance_to(boss.global_position),
		"the roll takes it out of reach")
	boss.cancel_action()
	dps.input.assist_mode = InputComponent.AssistMode.MASTER
	dps.apply_assist_mode()
	boss.set_physics_process(true)


## Golden Communion needs max(1, standing / 2) players inside and hurts 30 per
## standing player (up to 90), so a 2-player couch can always clear it.
func _check_soak_scaling() -> void:
	var required: Array[int] = []
	for players: int in range(1, 6):
		required.append(BossDummy.soak_required(players))
	_check(required == [1, 1, 1, 2, 2], "a soak needs max(1, players / 2) inside: %s for 1 to 5 players" % str(required))
	_check(is_equal_approx(BossDummy.soak_total_damage(2), 60.0) and is_equal_approx(BossDummy.soak_total_damage(5), 90.0),
		"soak damage is 30 per standing player, up to 90")
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	dps.stats.take_damage(9999.0) # Two left standing: a 2-player couch.
	await _seconds(0.05)
	var decal: RaidTelegraphDecal = RaidTelegraphDecal.new()
	decal.configure(RaidTelegraphDecal.Kind.GOLD_PARTY_SOAK, BossDummy.SOAK_RADIUS, BossDummy.SOAK_CAST_TIME, null)
	dojo.telegraphs_root.add_child(decal)
	decal.global_position = tank.global_position
	var tank_before: float = tank.stats.health
	var healer_before: float = healer.stats.health
	var alone: Array[ActorBase] = [tank]
	boss._on_telegraph_resolved(decal, alone)
	await _seconds(0.05)
	_check(is_equal_approx(tank_before - tank.stats.health, 60.0) and is_equal_approx(healer.stats.health, healer_before),
		"with 2 standing, one player soaking alone clears it (60 damage, nobody else hurt)")
	var nobody: Array[ActorBase] = []
	boss._on_telegraph_resolved(decal, nobody)
	await _seconds(0.05)
	_check(is_equal_approx(healer_before - healer.stats.health, BossDummy.SOAK_FAIL_DAMAGE), "an empty soak fails: 30 to everyone standing")
	decal.queue_free()
	CombatDirector.current.apply_heal(healer, dps, dps.stats.stats.max_health)
	await _seconds(0.1)


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


## The whole party down: the boss goes home at full health with an empty aggro table.
func _check_wipe_resets_fight() -> void:
	_reset_boss_poise()
	for actor: ActorBase in [tank, healer, dps]:
		actor.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 4.0)))
	await _seconds(0.3)
	boss.stats.take_damage(150.0)
	_check(boss.engaged and boss.stats.health < boss.stats.stats.max_health, "the boss is mid-fight and hurt")
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.take_damage(9999.0)
	await _seconds(0.3)
	_check(not boss.engaged and is_equal_approx(boss.stats.health, boss.stats.stats.max_health) and boss.threat.aggro_table.is_empty(),
		"a party wipe resets the fight (full health, empty aggro table)")
	for actor: ActorBase in [tank, healer, dps]:
		actor.stats.heal(actor.stats.stats.max_health)
	await _seconds(0.1)


## Fewer than 3 people: AI companions fill the missing trinity roles, fight by
## their Gambit lists, and step aside when people come back.
func _check_companion_backfill() -> void:
	var network: NetworkManager = NetworkManager.current
	_check(network.companion_seats().is_empty(), "a full trinity of people needs no companions")
	network.drop_local_player(1)
	network.drop_local_player(2)
	await _seconds(0.1)
	var bot_healer: ActorBase = _companion_with(ClassLoadoutResource.Role.HEALER)
	var bot_dps: ActorBase = _companion_with(ClassLoadoutResource.Role.DPS)
	_check(network.human_count() == 1 and _companions().size() == 2 and bot_healer != null and bot_dps != null,
		"with one person left, companions fill in as the Healer and the DPS")
	_check(dojo.grid.view_count() == 1 and dojo.huds.size() == 1, "companions get no split-screen view or HUD")
	var driven: bool = true
	for bot: ActorBase in _companions():
		driven = driven and bot.companion != null and bot.input == null and bot.display_name().ends_with("(bot)")
	_check(driven, "each is driven by a CompanionAIComponent and labelled as a bot")
	_check(network.local_player_count() == 1 and network.party_size() == 3, "they fill the party without taking a screen's player places")

	# A fight: the tank holds the boss while the companions do their jobs.
	_reset_boss_poise()
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.6))
	tank.input.inject_move(Vector2.ZERO)
	boss.threat.taunt(tank.player_id, COMPANION_FIGHT_TIME)
	tank.stats.take_damage(80.0)
	var heals_before: int = _audio_cues.count(&"heal")
	var dps_gambits: Dictionary[int, bool] = {}
	var waited: float = 0.0
	while waited < COMPANION_FIGHT_TIME:
		await _seconds(0.25)
		waited += 0.25
		dps_gambits[bot_dps.companion.current_gambit] = true
		if tank.stats.health < 50.0:
			tank.stats.heal(80.0) # Keep the test's tank up (a direct heal, so it isn't counted below).
	_check(_audio_cues.count(&"heal") > heals_before, "the companion healer heals the hurt tank")
	_check(boss.threat.threat_of(bot_dps.player_id) > 0.0 and (dps_gambits.has(CompanionAIComponent.Gambit.ATTACK)
		or dps_gambits.has(CompanionAIComponent.Gambit.PRIME)), "the companion DPS closes in and hits the boss")

	# The last person switches to DPS: a companion Tank takes the front.
	network.update_local_player(InputComponent.KEYBOARD_DEVICE, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.ADVENTURER)
	await _seconds(0.1)
	var bot_tank: ActorBase = _companion_with(ClassLoadoutResource.Role.TANK)
	_check(bot_tank != null and _companion_with(ClassLoadoutResource.Role.HEALER) != null and _companions().size() == 2,
		"switching the last person to DPS swaps the companion DPS for a companion Tank")
	_reset_boss_poise()
	bot_tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + boss.facing_vector() * 2.4))
	boss.threat.taunt(bot_tank.player_id, COMPANION_FIGHT_TIME)
	var guards_before: int = _companion_perfect_guards
	waited = 0.0
	while waited < COMPANION_FIGHT_TIME and _companion_perfect_guards == guards_before:
		await _seconds(0.25)
		waited += 0.25
	_check(_companion_perfect_guards > guards_before, "the companion Tank times a Perfect Guard on the Crushing Swipe")

	# People come back: the companions step aside and the player numbers are theirs again.
	network.update_local_player(InputComponent.KEYBOARD_DEVICE, ClassLoadouts.SHIELD_TANK, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(1, ClassLoadouts.SOUL_TETHER_HEALER, InputComponent.AssistMode.ADVENTURER)
	network.request_local_player(2, ClassLoadouts.DIRECTIONAL_FLOW_DPS, InputComponent.AssistMode.MASTER)
	await _seconds(0.1)
	_check(network.companion_seats().is_empty() and network.human_count() == 3 and dojo.actors.size() == 3,
		"when people rejoin, the companions step aside")
	_check(network.member(&"1_1").slot == 1 and network.member(&"1_2").slot == 2, "and the people get players 2 and 3 back")
	tank = dojo.actors[&"1_0"]
	healer = dojo.actors[&"1_1"]
	dps = dojo.actors[&"1_2"]


func _companions() -> Array[ActorBase]:
	var bots: Array[ActorBase] = []
	for actor: ActorBase in dojo.actors.values():
		if actor.is_companion:
			bots.append(actor)
	return bots


func _companion_with(role: int) -> ActorBase:
	for bot: ActorBase in _companions():
		if bot.role() == role:
			return bot
	return null


## Beating the boss: slow motion, a banner, a chest of shards, and the gold portal home.
func _check_victory_and_loot() -> void:
	var session: MultiplayerPeer = root.multiplayer.multiplayer_peer
	var shards_before: int = PartyProgress.current.shards
	# Everyone back on the spawn pads, well clear of where the chest lands.
	for actor: ActorBase in [tank, healer, dps]:
		actor.respawn()
		actor.input.inject_move(Vector2.ZERO)
	boss.stats.take_damage(boss.stats.health)
	await _seconds(0.1)
	_check(dojo.victory and boss.vanquished and boss.state_machine.is_in(&"downed"), "defeating the Dojo Warden starts the victory")
	_check(is_equal_approx(Engine.time_scale, DungeonDojo.VICTORY_TIME_SCALE), "the win plays out in slow motion (x0.2)")
	_check(dojo.chest != null and dojo.chest.is_inside_tree(), "a reward chest drops into the arena")
	var banners: int = 0
	for hud: PlayerHUD in dojo.huds.values():
		if hud.banner_title() == "VICTORY!":
			banners += 1
	_check(banners == 3, "every player's HUD shows the VICTORY! banner")
	await _seconds(DungeonDojo.VICTORY_SLOWMO_TIME)
	_check(is_equal_approx(Engine.time_scale, 1.0), "2 s later the game is back to normal speed")
	await _seconds(1.0)
	_check(boss.stats.is_downed and not dojo.chest.is_open, "the boss stays down and the chest waits to be opened")
	dps.place_at(Transform3D(Basis.IDENTITY, dojo.chest.global_position + Vector3(0.8, 0.0, 0.8)))
	await _seconds(0.2)
	_check(dojo.chest.is_open, "walking up to the chest opens it")
	var paid: int = DungeonDojo.chest_shards(3)
	_check(PartyProgress.current.shards == shards_before + paid, "the chest pays the party %d Dojo Shards" % paid)
	_check((dojo.huds[tank.player_id] as PlayerHUD).banner_title() == "+%d DOJO SHARDS" % paid, "the banner shows the shards earned")
	var saved: ConfigFile = ConfigFile.new()
	_check(saved.load(TEST_SAVE_PATH) == OK and int(saved.get_value("party", "shards", 0)) == shards_before + paid, "the shards are saved for next time")
	_check(dojo.exit_portal.is_recalling(), "the gold exit portal starts calling the party home")
	await _until_live_in(InstanceManager.HUB_TOWN)
	_check(current_scene is HubTown, "the gold portal brings the party back to Hub Town")
	_check(root.multiplayer.multiplayer_peer == session and NetworkManager.current.is_online(), "still the same ENet session after the round trip")
	_check(NetworkManager.current.party_size() == 3 and _hub().grid.view_count() == 3, "the whole party is back in town")


func _check_audio_cues() -> void:
	var silent: PackedStringArray = PackedStringArray()
	for cue: StringName in AudioCues.CUES:
		if AudioCues.current.stream_for(cue).data.size() < 200:
			silent.append(cue)
	_check(silent.is_empty(), "every audio cue synthesizes %s" % ("" if silent.is_empty() else str(silent)))
	var expected: Array[StringName] = [&"flow", &"hit", &"perfect_guard", &"telegraph", &"heal", &"join", &"portal", &"portal_charge",
		&"victory", &"chest", &"purchase", &"refuse", &"menu_move"]
	var unheard: PackedStringArray = PackedStringArray()
	for cue: StringName in expected:
		if not _audio_cues.has(cue):
			unheard.append(cue)
	_check(unheard.is_empty(), "flows, hits, guards, telegraphs, heals, joins, portals, the victory, the chest and the vendor all play their cues %s" % (
		"" if unheard.is_empty() else str(unheard)))


# --- Hub Town upgrades ----------------------------------------------------

## The Shard Vendor: walk up, press J, spend the chest's shards on upgrades for everyone.
func _check_shard_vendor() -> void:
	var hub: HubTown = current_scene as HubTown
	var progress: PartyProgress = PartyProgress.current
	var keyboard: ActorBase = hub.actors[&"1_0"]
	var hud: PlayerHUD = hub.huds[&"1_0"]
	keyboard.input.release_script()
	var front: Vector3 = -hub.shard_vendor.global_basis.z
	keyboard.place_at(Transform3D(Basis.IDENTITY, hub.shard_vendor.global_position + front * 1.6))
	await _seconds(0.1)
	_check(keyboard.interactable == hub.shard_vendor and hud.prompt_text().contains("Shard Vendor"), "standing at the stall shows the Shard Vendor prompt")
	await _tap_key(KEY_J)
	var menu: HubUpgradeMenu = hud.upgrade_menu()
	_check(menu != null and keyboard.input.menu_open and not keyboard.action_queue.is_busy(), "J at the stall opens the upgrade menu instead of swinging")
	var shards: int = progress.shards
	var tank_health: float = keyboard.stats.stats.max_health
	var healer_health: float = hub.actors[&"1_1"].stats.stats.max_health
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 1 and progress.shards == shards - PartyProgress.UPGRADE_BASE_COST,
		"J buys Max Health level 1 for %d shards" % PartyProgress.UPGRADE_BASE_COST)
	_check(is_equal_approx(keyboard.stats.stats.max_health, tank_health * 1.1) and is_equal_approx(hub.actors[&"1_1"].stats.stats.max_health, healer_health * 1.1),
		"everyone's max health grows by 10%")
	_check(is_equal_approx(keyboard.stats.health, keyboard.stats.stats.max_health), "and they stay at full health")
	var regen: float = keyboard.stats.stats.stamina_regen_per_sec
	await _tap_key(KEY_S)
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.STAMINA_REGEN) == 1 and is_equal_approx(keyboard.stats.stats.stamina_regen_per_sec, regen * 1.1),
		"S then J buys Stamina Regen (+10% stamina per second)")
	await _tap_key(KEY_W)
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 2 and progress.shards == shards - 16, "Max Health level 2 costs 8 shards")
	await _tap_key(KEY_J)
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 2 and progress.shards == 0 and menu.note_text().begins_with("Not enough shards"),
		"without enough shards the purchase is refused")
	await _tap_key(KEY_SPACE)
	_check(hud.upgrade_menu() == null and not keyboard.input.menu_open and not keyboard.state_machine.is_in(&"dodge"), "Space closes the menu without rolling")
	var saved: ConfigFile = ConfigFile.new()
	_check(saved.load(TEST_SAVE_PATH) == OK and int(saved.get_value("upgrades", "max_health", 0)) == 2
		and int(saved.get_value("upgrades", "stamina_regen", 0)) == 1, "the upgrades are saved")
	progress.load_save()
	_check(progress.level_of(PartyProgress.MAX_HEALTH) == 2 and progress.level_of(PartyProgress.STAMINA_REGEN) == 1 and progress.shards == 0,
		"and load back next session")
	NetworkManager.current.update_local_player(2, ClassLoadouts.SHIELD_TANK, InputComponent.AssistMode.MASTER)
	await _seconds(0.05)
	_check(is_equal_approx(hub.actors[&"1_2"].stats.stats.max_health, ClassLoadouts.shield_tank().stats.max_health * 1.2),
		"a player who changes class starts with the upgrades too")
	NetworkManager.current.drop_local_player(1)
	NetworkManager.current.drop_local_player(2)
	await _seconds(0.1)
	_check(NetworkManager.current.companion_seats().is_empty() and hub.actors.size() == 1, "companions only join raids, not Hub Town")


# --- Helpers --------------------------------------------------------------

func _connect_global_signals() -> void:
	var director: CombatDirector = CombatDirector.current
	director.hit_stop_applied.connect(func(_duration: float) -> void: _hit_stops += 1)
	director.primer_applied.connect(func(_target: ActorBase, primer: int) -> void: _primers.append(primer))
	director.synergy_detonated.connect(func(_target: ActorBase, _primer: int, cross_class: bool, label: String) -> void:
		_synergies.append(label)
		if cross_class:
			_cross_class_synergies += 1)
	director.perfect_guard_landed.connect(func(defender: ActorBase) -> void:
		_perfect_guards += 1
		if defender.is_companion:
			_companion_perfect_guards += 1)
	director.hit_resolved.connect(func(event: CombatEvent, outcome: int) -> void:
		_outcomes.append(outcome)
		if event.unavoidable:
			_telegraph_hits += 1)
	director.telegraph_cast.connect(func(decal: RaidTelegraphDecal) -> void:
		_telegraph_kinds[decal.kind] = _telegraph_kinds.get(decal.kind, 0) + 1)
	director.cue_shown.connect(func(_at: Vector3, cue: StringName) -> void: _cue_sounds.append(cue))
	AudioCues.current.cue_played.connect(func(cue: StringName) -> void: _audio_cues.append(cue))
	NetworkManager.current.registration_refused.connect(func(_device: int, reason: String) -> void: _refusals.append(reason))


## Puts the party in front of the boss, facing it, with scripted input and signals hooked up.
func _stage_party() -> void:
	tank.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 2.6)))
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(-1.2, 0.0, 2.6)))
	healer.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(2.5, 0.0, 6.0)))
	for actor: ActorBase in [tank, healer, dps]:
		actor.input.inject_move(Vector2.ZERO)
	if not dps.action_queue.flow_cancelled.is_connected(_on_dps_flow):
		dps.action_queue.flow_cancelled.connect(_on_dps_flow)
	if not healer.state_machine.state_changed.is_connected(_on_healer_state):
		healer.state_machine.state_changed.connect(_on_healer_state)


func _on_dps_flow(_from: CombatActionResource, _to: CombatActionResource) -> void:
	_flow_speed_scales.append(dps.action_queue.speed_scale)


func _on_healer_state(_from: StringName, to: StringName) -> void:
	_healer_states.append(to)


func _face_boss(actor: ActorBase, offset: Vector3) -> void:
	var where: Vector3 = boss.global_position + offset
	var to_boss: Vector3 = boss.global_position - where
	to_boss.y = 0.0
	actor.place_at(Transform3D(Basis.looking_at(to_boss.normalized(), Vector3.UP), where))


## Everyone onto a portal's platform, spread around its centre.
func _gather_on(portal: RaidPortal, level: LevelBase) -> void:
	var index: int = 0
	for actor: ActorBase in level.actors.values():
		var angle: float = TAU * index / maxf(1.0, level.actors.size())
		actor.place_at(Transform3D(Basis.IDENTITY, portal.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 1.0))
		if actor.input != null:
			actor.input.inject_move(Vector2.ZERO)
		index += 1


func _until_live_in(id: StringName) -> void:
	var waited: float = 0.0
	while waited < PORTAL_TIMEOUT and not (InstanceManager.current.instance_id == id and InstanceManager.current.is_live() and current_scene is LevelBase \
			and (current_scene as LevelBase).instance_id() == id):
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(0.1)


func _strike(attacker: ActorBase, target: ActorBase, damage: float, poise: float) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.kind = CombatEvent.Kind.STRIKE
	event.attacker_path = attacker.get_path()
	event.target_path = target.get_path()
	event.attacker_player_id = attacker.player_id
	event.attacker_role = attacker.role()
	event.damage = damage
	event.poise_damage = poise
	event.origin = attacker.global_position
	return event


func _hub() -> LevelBase:
	return current_scene as LevelBase


func _pad_id(index: int) -> StringName:
	return PartyMember.make_player_id(1, FAKE_PADS[index] + 1)


func _capture(actor: ActorBase) -> void:
	_commands[actor.player_id] = []
	actor.input.command_issued.connect(_on_command.bind(actor.player_id))


func _on_command(command: int, player_id: StringName) -> void:
	_commands[player_id].append(command)


func _commands_of(player_id: StringName) -> Array:
	return _commands.get(player_id, [])


func _press_heavy_with_stick(pad: int, stick_y: float) -> void:
	_pad_axis(pad, JOY_AXIS_LEFT_Y, stick_y)
	await _seconds(0.05)
	_pad_button(pad, JOY_BUTTON_Y, true)
	await _seconds(0.05)
	_pad_button(pad, JOY_BUTTON_Y, false)
	_pad_axis(pad, JOY_AXIS_LEFT_Y, 0.0)
	await _seconds(0.05)


func _tap_key(key: Key) -> void:
	_key(key, true)
	await _seconds(0.05)
	_key(key, false)
	await _seconds(0.05)


func _key(key: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)


func _pad_button(pad: int, button: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = pad
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _pad_axis(pad: int, axis: JoyAxis, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = pad
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


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


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


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
