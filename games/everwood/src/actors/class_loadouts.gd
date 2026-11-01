## The playable classes (the Holy Trinity) and the raid boss. A class is a
## role, base numbers and a starter kit; what it swings and casts comes from
## its equipment and Scribe Cards (ArsenalCatalog), combined by
## LoadoutComposer. The boss has no kit: its loadout is built here directly.
class_name ClassLoadouts
extends RefCounted

const SHIELD_TANK: StringName = &"shield_tank"
const SOUL_TETHER_HEALER: StringName = &"soul_tether_healer"
const DIRECTIONAL_FLOW_DPS: StringName = &"directional_flow_dps"
const RAID_BOSS_DUMMY: StringName = &"raid_boss_dummy"
const PLAYER_CLASSES: Array[StringName] = [SHIELD_TANK, SOUL_TETHER_HEALER, DIRECTIONAL_FLOW_DPS]
## The Dojo Warden's swing (the Squire auto-guard and companions watch for it).
const BOSS_SWIPE: StringName = &"boss_crushing_swipe"

const TANK_COLOR: Color = Color(0.32, 0.52, 0.9)
const HEALER_COLOR: Color = Color(0.34, 0.76, 0.46)
const DPS_COLOR: Color = Color(0.92, 0.5, 0.22)
## The Cairnsman's river-stone grey.
const BOSS_COLOR: Color = Color(0.47, 0.45, 0.41)

const Cmd = CombatActionResource.Command


static func player_class(class_id: StringName) -> PlayerClassResource:
	match class_id:
		SHIELD_TANK:
			return _shield_tank()
		SOUL_TETHER_HEALER:
			return _soul_tether_healer()
		DIRECTIONAL_FLOW_DPS:
			return _flow_dps()
	push_warning("ClassLoadouts: unknown class %s, using the DPS" % class_id)
	return _flow_dps()


## A class wearing a kit, ready for an actor (no kit means its starter kit).
static func compose(class_id: StringName, kit: EquipmentLoadoutResource = null) -> ClassLoadoutResource:
	return LoadoutComposer.compose(player_class(class_id), kit)


static func starter_kit(class_id: StringName) -> EquipmentLoadoutResource:
	return player_class(class_id).starter_kit.copy()


static func next_class(class_id: StringName) -> StringName:
	var index: int = PLAYER_CLASSES.find(class_id)
	return PLAYER_CLASSES[(index + 1) % PLAYER_CLASSES.size()]


# --- Shield Tank ------------------------------------------------------------
# Holds the boss with threat and an Active Guard in Ironwood Plate (the widest
# Perfect Guard window). Sword & Buckler; Shield Charge, Shadow Sanctuary,
# Taunt and Bulwark Quake.

static func _shield_tank() -> PlayerClassResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 160.0
	stats.threat_modifier = 3.0
	stats.guard_damage_reduction = 0.85
	stats.guard_stamina_per_damage = 0.5
	stats.move_speed = 5.6
	stats.guard_move_speed = 2.6
	return _class(SHIELD_TANK, "Shield Tank", ClassLoadoutResource.Role.TANK, TANK_COLOR, stats, false,
		EquipmentLoadoutResource.make(ArsenalCatalog.IRONWOOD_PLATE, ArsenalCatalog.LIGHT_SWORD,
			[ArsenalCatalog.SHIELD_CHARGE, ArsenalCatalog.SHADOW_SANCTUARY, ArsenalCatalog.TAUNT, ArsenalCatalog.BULWARK_QUAKE]))


# --- Soul-Tether Healer -----------------------------------------------------
# D-Pad binds a Soul Tether to a party member. Hearth-Linen and the Scribe
# Staff; Sunlit Lance (Warm-Hearth primer), Green Sanctuary, Homing Heal and
# Lifeline Pull.

static func _soul_tether_healer() -> PlayerClassResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 110.0
	stats.threat_modifier = 0.8
	stats.guard_damage_reduction = 0.5
	stats.guard_stamina_per_damage = 0.7
	stats.move_speed = 6.0
	return _class(SOUL_TETHER_HEALER, "Soul-Tether Healer", ClassLoadoutResource.Role.HEALER, HEALER_COLOR, stats, true,
		EquipmentLoadoutResource.make(ArsenalCatalog.HEARTH_LINEN, ArsenalCatalog.SCRIBE_STAFF,
			[ArsenalCatalog.SUNLIT_LANCE, ArsenalCatalog.GREEN_SANCTUARY, ArsenalCatalog.HOMING_HEAL, ArsenalCatalog.LIFELINE_PULL]))


# --- Flow DPS ---------------------------------------------------------------
# The primer specialist. Ranger Leather and the Wind-Ash Bow; Rising Drive
# (Iron-Root), Frost Crescent (Rime-Gale), Gale Rush (Star-Tide) and Tempest Flow.

static func _flow_dps() -> PlayerClassResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 100.0
	stats.move_speed = 6.6
	return _class(DIRECTIONAL_FLOW_DPS, "Flow DPS", ClassLoadoutResource.Role.DPS, DPS_COLOR, stats, false,
		EquipmentLoadoutResource.make(ArsenalCatalog.RANGER_LEATHER, ArsenalCatalog.HUNTER_BOW,
			[ArsenalCatalog.RISING_DRIVE, ArsenalCatalog.FROST_CRESCENT, ArsenalCatalog.GALE_RUSH, ArsenalCatalog.TEMPEST_FLOW]))


static func _class(id: StringName, label: String, role: ClassLoadoutResource.Role, color: Color, stats: CharacterStatsResource,
		tethers: bool, kit: EquipmentLoadoutResource) -> PlayerClassResource:
	var made: PlayerClassResource = PlayerClassResource.new()
	made.class_id = id
	made.display_name = label
	made.role = role
	made.body_color = color
	made.base_stats = stats
	made.has_soul_tethers = tethers
	made.starter_kit = kit
	return made


# --- Raid Boss Dummy --------------------------------------------------------

static func raid_boss_dummy() -> ClassLoadoutResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	# BossDummy rescales health to the party when a fight starts; this is the 3-player value.
	stats.max_health = BossDummy.HEALTH_BASE + BossDummy.HEALTH_PER_PLAYER * 3.0
	stats.max_poise = 120.0
	stats.poise_regen_per_sec = 15.0
	stats.poise_regen_delay = 3.0
	stats.poise_knockdown_time = 5.0
	stats.knockdown_damage_taken = 1.25
	stats.move_speed = 3.6
	stats.turn_speed = 2.6

	# A long, readable wind-up: the tank's cue to raise a Perfect Guard.
	var swipe: CombatActionResource = CombatActionResource.new()
	swipe.action_id = BOSS_SWIPE
	swipe.display_name = "Crushing Swipe"
	swipe.command = Cmd.LIGHT
	swipe.windup_time = 0.85
	swipe.active_time = 0.15
	swipe.recovery_time = 0.9
	swipe.stamina_cost = 0.0
	swipe.damage = 24.0
	swipe.reach = 2.6
	swipe.hit_radius = 2.2
	swipe.hit_stop_scale = 1.5
	swipe.resonance_gain = 0.0

	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = RAID_BOSS_DUMMY
	loadout.display_name = BossDummy.DISPLAY_NAME
	loadout.role = ClassLoadoutResource.Role.BOSS
	loadout.body_color = BOSS_COLOR
	loadout.stats = stats
	loadout.openers = [swipe]
	return loadout
