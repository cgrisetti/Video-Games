## Builds the playable class loadouts (and the boss's) in code. Every class is
## a posture-driven 6-skill loadout: light, heavy, dodge and the L / R / L+R
## triggers, with BDO directional heavies and flow links between skills.
class_name ClassLoadouts
extends RefCounted

const SHIELD_TANK: StringName = &"shield_tank"
const SOUL_TETHER_HEALER: StringName = &"soul_tether_healer"
const DIRECTIONAL_FLOW_DPS: StringName = &"directional_flow_dps"
const RAID_BOSS_DUMMY: StringName = &"raid_boss_dummy"
const PLAYER_CLASSES: Array[StringName] = [SHIELD_TANK, SOUL_TETHER_HEALER, DIRECTIONAL_FLOW_DPS]

const TANK_COLOR: Color = Color(0.32, 0.52, 0.9)
const HEALER_COLOR: Color = Color(0.34, 0.76, 0.46)
const DPS_COLOR: Color = Color(0.92, 0.5, 0.22)
const BOSS_COLOR: Color = Color(0.4, 0.17, 0.2)

const Cmd = CombatActionResource.Command
const Fx = CombatActionResource.Effect
const Syn = CombatActionResource.Synergy


static func by_id(class_id: StringName) -> ClassLoadoutResource:
	match class_id:
		SHIELD_TANK:
			return shield_tank()
		SOUL_TETHER_HEALER:
			return soul_tether_healer()
		DIRECTIONAL_FLOW_DPS:
			return directional_flow_dps()
		RAID_BOSS_DUMMY:
			return raid_boss_dummy()
	push_warning("ClassLoadouts: unknown class %s, using the DPS" % class_id)
	return directional_flow_dps()


static func next_class(class_id: StringName) -> StringName:
	var index: int = PLAYER_CLASSES.find(class_id)
	return PLAYER_CLASSES[(index + 1) % PLAYER_CLASSES.size()]


# --- Shield Tank ------------------------------------------------------------
# Holds the boss with threat and an Active Guard. A Perfect Guard (raised within
# 200 ms of a hit) costs nothing and staggers the boss. Back + heavy raises a
# Shadow Sanctuary cone that shields everyone standing behind you.

static func shield_tank() -> ClassLoadoutResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 160.0
	stats.threat_modifier = 3.0
	stats.guard_damage_reduction = 0.85
	stats.guard_stamina_per_damage = 0.5
	stats.can_perfect_guard = true
	stats.move_speed = 5.6
	stats.guard_move_speed = 2.6

	var bash_1: CombatActionResource = _strike(&"tank_bash_1", "Shield Bash", Cmd.LIGHT, 0.18, 0.12, 0.42, 8.0, 8.0)
	bash_1.poise_damage = 4.0
	bash_1.resonance_gain = 0.25
	var bash_2: CombatActionResource = _strike(&"tank_bash_2", "Shield Bash II", Cmd.LIGHT, 0.16, 0.12, 0.42, 8.0, 9.0)
	bash_2.poise_damage = 5.0
	bash_2.resonance_gain = 0.25
	var bash_3: CombatActionResource = _strike(&"tank_bash_3", "Shield Bash III", Cmd.LIGHT, 0.22, 0.14, 0.55, 10.0, 12.0)
	bash_3.poise_damage = 10.0
	bash_3.hit_stop_scale = 1.5
	bash_3.resonance_gain = 0.3
	var slam: CombatActionResource = _strike(&"tank_overhead_slam", "Overhead Slam", Cmd.HEAVY, 0.45, 0.15, 0.65, 22.0, 18.0)
	slam.poise_damage = 30.0
	slam.detonates = true
	slam.hit_stop_scale = 2.0
	slam.reach = 1.8
	slam.hit_radius = 1.6
	var charge: CombatActionResource = _strike(&"tank_shield_charge", "Shield Charge", Cmd.FORWARD_HEAVY, 0.25, 0.25, 0.5, 20.0, 12.0)
	charge.poise_damage = 20.0
	charge.lunge_distance = 5.0
	charge.detonates = true
	charge.hit_stop_scale = 1.5
	var sanctuary: CombatActionResource = _support(&"tank_shadow_sanctuary", "Shadow Sanctuary", Cmd.BACK_HEAVY, Fx.SHADOW_SANCTUARY, 0.35, 0.1, 0.5)
	sanctuary.stamina_cost = 25.0
	sanctuary.effect_radius = 7.0
	sanctuary.effect_duration = 6.0
	var taunt: CombatActionResource = _support(&"tank_taunt", "Taunt", Cmd.TRIGGER_R_SKILL, Fx.TAUNT, 0.2, 0.1, 0.3)
	taunt.resonance_cost = 1
	taunt.effect_duration = 6.0
	var quake: CombatActionResource = _strike(&"tank_bulwark_quake", "Bulwark Quake", Cmd.TRIGGER_BOTH_ULT, 0.6, 0.2, 0.8, 0.0, 30.0)
	quake.resonance_cost = 3
	quake.poise_damage = 60.0
	quake.reach = 0.0
	quake.hit_radius = 3.5
	quake.detonates = true
	quake.hit_stop_scale = 2.5
	quake.resonance_gain = 0.0

	bash_1.flow_links = _ids([bash_2, slam, charge, sanctuary])
	bash_2.flow_links = _ids([bash_3, slam, charge, sanctuary])
	bash_3.flow_links = _ids([slam, charge, sanctuary])
	charge.flow_links = _ids([bash_2, slam])
	slam.flow_links = _ids([bash_1, charge])

	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = SHIELD_TANK
	loadout.display_name = "Shield Tank"
	loadout.role = ClassLoadoutResource.Role.TANK
	loadout.body_color = TANK_COLOR
	loadout.stats = stats
	loadout.openers = [bash_1, slam, charge, sanctuary, taunt, quake]
	loadout.combo_actions = [bash_2, bash_3]
	loadout.dodge = _dodge()
	loadout.guard_on_trigger_l = true
	loadout.trigger_l_label = "hold: Guard"
	loadout.trigger_r_label = "Taunt (1 pip)"
	loadout.ult_label = "Bulwark Quake (3 pips)"
	return loadout


# --- Soul-Tether Healer -----------------------------------------------------
# D-Pad binds a Soul Tether to a party member. R sends a homing heal down the
# tether without breaking your lock on the boss; holding R drops a Green
# Sanctuary ring; L+R is the Lifeline Pull that yanks your tether to safety.

static func soul_tether_healer() -> ClassLoadoutResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 110.0
	stats.threat_modifier = 0.8
	stats.guard_damage_reduction = 0.5
	stats.guard_stamina_per_damage = 0.7
	stats.move_speed = 6.0

	var jab_1: CombatActionResource = _strike(&"healer_jab_1", "Staff Jab", Cmd.LIGHT, 0.16, 0.1, 0.4, 7.0, 6.0)
	jab_1.resonance_gain = 0.3
	var jab_2: CombatActionResource = _strike(&"healer_jab_2", "Staff Jab II", Cmd.LIGHT, 0.16, 0.1, 0.45, 7.0, 7.0)
	jab_2.resonance_gain = 0.3
	var burst: CombatActionResource = _strike(&"healer_radiant_burst", "Radiant Burst", Cmd.HEAVY, 0.4, 0.15, 0.6, 20.0, 10.0)
	burst.poise_damage = 8.0
	burst.reach = 0.0
	burst.hit_radius = 2.8
	burst.detonates = true
	burst.resonance_gain = 0.3
	var heal: CombatActionResource = _support(&"healer_homing_heal", "Homing Heal", Cmd.TRIGGER_R_SKILL, Fx.HOMING_HEAL, 0.12, 0.05, 0.3)
	heal.stamina_cost = 12.0
	heal.heal_amount = 22.0
	var ring: CombatActionResource = _support(&"healer_green_sanctuary", "Green Sanctuary", Cmd.TRIGGER_R_HOLD, Fx.GREEN_SANCTUARY, 0.3, 0.1, 0.45)
	ring.resonance_cost = 1
	ring.heal_amount = 8.0
	ring.effect_radius = 4.5
	ring.effect_duration = 6.0
	var lifeline: CombatActionResource = _support(&"healer_lifeline_pull", "Lifeline Pull", Cmd.TRIGGER_BOTH_ULT, Fx.LIFELINE_PULL, 0.12, 0.08, 0.4)
	lifeline.resonance_cost = 2
	lifeline.effect_duration = 0.4

	jab_1.flow_links = _ids([jab_2, burst])
	jab_2.flow_links = _ids([jab_1, burst])
	burst.flow_links = _ids([jab_1])

	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = SOUL_TETHER_HEALER
	loadout.display_name = "Soul-Tether Healer"
	loadout.role = ClassLoadoutResource.Role.HEALER
	loadout.body_color = HEALER_COLOR
	loadout.stats = stats
	loadout.openers = [jab_1, burst, heal, ring, lifeline]
	loadout.combo_actions = [jab_2]
	loadout.dodge = _dodge()
	loadout.guard_on_trigger_l = true
	loadout.has_soul_tethers = true
	loadout.trigger_l_label = "hold: Guard"
	loadout.trigger_r_label = "Homing Heal, hold: Green Sanctuary (1 pip)"
	loadout.ult_label = "Lifeline Pull (2 pips)"
	return loadout


# --- Directional Flow DPS ---------------------------------------------------
# Long BDO chains where the stick decides the next move. Forward + heavy primes
# Stagger, back + heavy primes Frost, L primes Radiant: teammates detonate them.

static func directional_flow_dps() -> ClassLoadoutResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 100.0
	stats.move_speed = 6.6

	var cut_1: CombatActionResource = _strike(&"dps_flow_cut_1", "Flow Cut", Cmd.LIGHT, 0.12, 0.1, 0.36, 6.0, 9.0)
	cut_1.resonance_gain = 0.25
	var cut_2: CombatActionResource = _strike(&"dps_flow_cut_2", "Flow Cut II", Cmd.LIGHT, 0.12, 0.1, 0.36, 6.0, 10.0)
	cut_2.resonance_gain = 0.25
	var cut_3: CombatActionResource = _strike(&"dps_flow_cut_3", "Flow Cut III", Cmd.LIGHT, 0.16, 0.12, 0.5, 8.0, 13.0)
	cut_3.hit_stop_scale = 1.3
	cut_3.resonance_gain = 0.3
	var drive: CombatActionResource = _strike(&"dps_rising_drive", "Rising Drive", Cmd.FORWARD_HEAVY, 0.24, 0.14, 0.5, 18.0, 16.0)
	drive.poise_damage = 12.0
	drive.lunge_distance = 3.5
	drive.primer = Syn.STAGGER
	var crescent: CombatActionResource = _strike(&"dps_frost_crescent", "Frost Crescent", Cmd.BACK_HEAVY, 0.28, 0.16, 0.5, 18.0, 14.0)
	crescent.lunge_distance = -1.5
	crescent.reach = 1.4
	crescent.hit_radius = 2.0
	crescent.primer = Syn.FROST
	var cleave: CombatActionResource = _strike(&"dps_cleave", "Cleave", Cmd.HEAVY, 0.32, 0.14, 0.55, 16.0, 20.0)
	cleave.poise_damage = 10.0
	cleave.hit_stop_scale = 1.4
	var mark: CombatActionResource = _strike(&"dps_radiant_mark", "Radiant Mark", Cmd.TRIGGER_L_SKILL, 0.2, 0.1, 0.35, 14.0, 6.0)
	mark.reach = 2.6
	mark.hit_radius = 1.6
	mark.primer = Syn.RADIANT
	var rush: CombatActionResource = _strike(&"dps_gale_rush", "Gale Rush", Cmd.TRIGGER_R_SKILL, 0.1, 0.2, 0.4, 0.0, 22.0)
	rush.resonance_cost = 1
	rush.lunge_distance = 6.0
	rush.resonance_gain = 0.0
	var tempest: CombatActionResource = _strike(&"dps_tempest_flow", "Tempest Flow", Cmd.TRIGGER_BOTH_ULT, 0.5, 0.3, 0.7, 0.0, 55.0)
	tempest.resonance_cost = 3
	tempest.poise_damage = 25.0
	tempest.reach = 0.5
	tempest.hit_radius = 3.2
	tempest.hit_stop_scale = 2.5
	tempest.resonance_gain = 0.0

	cut_1.flow_links = _ids([cut_2, drive, crescent, cleave, mark])
	cut_2.flow_links = _ids([cut_3, drive, crescent, cleave, mark])
	cut_3.flow_links = _ids([drive, crescent, cleave, mark, rush])
	drive.flow_links = _ids([cut_1, crescent, mark])
	crescent.flow_links = _ids([drive, cut_1, mark])
	mark.flow_links = _ids([cut_1, drive, crescent])
	cleave.flow_links = _ids([cut_1])
	rush.flow_links = _ids([cut_1, tempest])

	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = DIRECTIONAL_FLOW_DPS
	loadout.display_name = "Flow DPS"
	loadout.role = ClassLoadoutResource.Role.DPS
	loadout.body_color = DPS_COLOR
	loadout.stats = stats
	loadout.openers = [cut_1, cleave, drive, crescent, mark, rush, tempest]
	loadout.combo_actions = [cut_2, cut_3]
	loadout.dodge = _dodge()
	loadout.trigger_l_label = "Radiant Mark"
	loadout.trigger_r_label = "Gale Rush (1 pip)"
	loadout.ult_label = "Tempest Flow (3 pips)"
	return loadout


# --- Raid Boss Dummy --------------------------------------------------------

static func raid_boss_dummy() -> ClassLoadoutResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 2400.0
	stats.max_poise = 100.0
	stats.poise_knockdown_time = 5.0
	stats.move_speed = 3.6
	stats.turn_speed = 2.6

	# A long, readable wind-up: the tank's cue to raise a Perfect Guard.
	var swipe: CombatActionResource = _strike(&"boss_crushing_swipe", "Crushing Swipe", Cmd.LIGHT, 0.85, 0.15, 0.9, 0.0, 28.0)
	swipe.reach = 2.6
	swipe.hit_radius = 2.2
	swipe.hit_stop_scale = 1.5
	swipe.resonance_gain = 0.0

	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = RAID_BOSS_DUMMY
	loadout.display_name = "Dojo Warden"
	loadout.role = ClassLoadoutResource.Role.BOSS
	loadout.body_color = BOSS_COLOR
	loadout.stats = stats
	loadout.openers = [swipe]
	return loadout


# --- Builders -------------------------------------------------------------

static func _ids(actions: Array[CombatActionResource]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for action: CombatActionResource in actions:
		ids.append(action.action_id)
	return ids


static func _strike(id: StringName, label: String, command: CombatActionResource.Command,
		windup: float, active: float, recovery: float, stamina: float, damage: float) -> CombatActionResource:
	var action: CombatActionResource = CombatActionResource.new()
	action.action_id = id
	action.display_name = label
	action.command = command
	action.effect = Fx.STRIKE
	action.windup_time = windup
	action.active_time = active
	action.recovery_time = recovery
	action.stamina_cost = stamina
	action.damage = damage
	return action


static func _support(id: StringName, label: String, command: CombatActionResource.Command, effect: CombatActionResource.Effect,
		windup: float, active: float, recovery: float) -> CombatActionResource:
	var action: CombatActionResource = _strike(id, label, command, windup, active, recovery, 0.0, 0.0)
	action.effect = effect
	action.resonance_gain = 0.0
	return action


static func _dodge() -> CombatActionResource:
	var roll: CombatActionResource = _support(&"dodge_roll", "Dodge Roll", Cmd.DODGE, Fx.DODGE, 0.03, 0.32, 0.22)
	roll.stamina_cost = 20.0
	roll.lunge_distance = 4.6
	return roll
