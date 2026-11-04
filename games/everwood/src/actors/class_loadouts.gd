## The playable classes (the Holy Trinity, the three Primary Fellowships) and
## the raid boss. A class is a role, base numbers and a starter kit; its
## Secondary Calling (Callings) is applied on top, and what it swings and casts
## comes from its equipment and Scribe Cards (ArsenalCatalog), combined by
## LoadoutComposer. The boss has no kit: its loadout is built here directly.
class_name ClassLoadouts
extends RefCounted

const SHIELD_TANK: StringName = &"shield_tank"
const SOUL_TETHER_HEALER: StringName = &"soul_tether_healer"
const DIRECTIONAL_FLOW_DPS: StringName = &"directional_flow_dps"
const RAID_BOSS_DUMMY: StringName = &"raid_boss_dummy"
## Moss-Oak-Hollow's woodland kin (WoodlandMinion), by WoodlandMinion.Kind.
const MINION_CLASSES: Array[StringName] = [&"bramble_scuttler", &"bog_imp"]
const PLAYER_CLASSES: Array[StringName] = [SHIELD_TANK, SOUL_TETHER_HEALER, DIRECTIONAL_FLOW_DPS]
## The playtest boot (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md, Stage 1):
## Player 1 starts as the Iron-Woodsman ("Hewn-Hand of the High Pines"), a
## Wayfarer with a Stout Heart, sworn from Level 1, in the Hedgerow Wool-Mantle
## with a Broad-Axe, alone (LevelBase.solo_iron_woodsman_boot).
const SOLO_BOOT_CLASS: StringName = DIRECTIONAL_FLOW_DPS
const SOLO_BOOT_CALLING: StringName = &"stout_heart"
const SOLO_BOOT_ARMOR: StringName = &"ranger_leather"
const SOLO_BOOT_WEAPON_TYPE: int = EquipmentItemResource.WeaponType.HEAVY_AXE
## The Dojo Warden's swing (the Squire auto-guard and companions watch for it).
const BOSS_SWIPE: StringName = &"boss_crushing_swipe"

const TANK_COLOR: Color = Color(0.32, 0.52, 0.9)
const HEALER_COLOR: Color = Color(0.34, 0.76, 0.46)
const DPS_COLOR: Color = Color(0.92, 0.5, 0.22)
## The Cairnsman's river-stone grey.
const BOSS_COLOR: Color = Color(0.47, 0.45, 0.41)
## Bramble-green Scuttlers and moss-grey Wisp-Boggles.
const MINION_COLORS: Array[Color] = [Color(0.36, 0.42, 0.22), Color(0.5, 0.56, 0.47)]

const Cmd = CombatActionResource.Command


## A class as one of its three Callings (`secondary` -1: its own column, the default).
static func player_class(class_id: StringName, secondary: int = -1) -> PlayerClassResource:
	var made: PlayerClassResource
	match class_id:
		SHIELD_TANK:
			made = _shield_tank()
		SOUL_TETHER_HEALER:
			made = _soul_tether_healer()
		DIRECTIONAL_FLOW_DPS:
			made = _flow_dps()
		_:
			push_warning("ClassLoadouts: unknown class %s, using the DPS" % class_id)
			made = _flow_dps()
	Callings.apply(made, secondary)
	return made


## A class and Calling wearing a kit, ready for an actor (no kit means its starter kit).
static func compose(class_id: StringName, kit: EquipmentLoadoutResource = null, secondary: int = -1) -> ClassLoadoutResource:
	return LoadoutComposer.compose(player_class(class_id, secondary), kit)


static func starter_kit(class_id: StringName) -> EquipmentLoadoutResource:
	return player_class(class_id).starter_kit.copy()


static func next_class(class_id: StringName) -> StringName:
	var index: int = PLAYER_CLASSES.find(class_id)
	return PLAYER_CLASSES[(index + 1) % PLAYER_CLASSES.size()]


# --- Shield Tank (the Shield-Sworn) -----------------------------------------
# Holds the boss with threat and an Active Guard in Iron-Wood Ring-Coat (the widest
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
	return _class(SHIELD_TANK, ClassLoadoutResource.Role.TANK, TANK_COLOR, stats, false,
		EquipmentLoadoutResource.make(ArsenalCatalog.IRONWOOD_PLATE, ArsenalCatalog.LIGHT_SWORD,
			[ArsenalCatalog.SHIELD_CHARGE, ArsenalCatalog.SHADOW_SANCTUARY, ArsenalCatalog.TAUNT, ArsenalCatalog.BULWARK_QUAKE]))


# --- Soul-Tether Healer (the Lantern-Bearers) ------------------------------
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
	return _class(SOUL_TETHER_HEALER, ClassLoadoutResource.Role.HEALER, HEALER_COLOR, stats, true,
		EquipmentLoadoutResource.make(ArsenalCatalog.HEARTH_LINEN, ArsenalCatalog.SCRIBE_STAFF,
			[ArsenalCatalog.SUNLIT_LANCE, ArsenalCatalog.GREEN_SANCTUARY, ArsenalCatalog.HOMING_HEAL, ArsenalCatalog.LIFELINE_PULL]))


# --- Flow DPS (the Wayfarers) -----------------------------------------------
# The primer specialist. Hedgerow Wool-Mantle and the Wind-Ash Bow; Rising Drive
# (Iron-Root), Frost Crescent (Rime-Gale), Gale Rush (Star-Tide) and Tempest Flow.

static func _flow_dps() -> PlayerClassResource:
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = 100.0
	stats.move_speed = 6.6
	return _class(DIRECTIONAL_FLOW_DPS, ClassLoadoutResource.Role.DPS, DPS_COLOR, stats, false,
		EquipmentLoadoutResource.make(ArsenalCatalog.RANGER_LEATHER, ArsenalCatalog.HUNTER_BOW,
			[ArsenalCatalog.RISING_DRIVE, ArsenalCatalog.FROST_CRESCENT, ArsenalCatalog.GALE_RUSH, ArsenalCatalog.TEMPEST_FLOW]))


static func _class(id: StringName, role: ClassLoadoutResource.Role, color: Color, stats: CharacterStatsResource,
		tethers: bool, kit: EquipmentLoadoutResource) -> PlayerClassResource:
	var made: PlayerClassResource = PlayerClassResource.new()
	made.class_id = id
	made.display_name = Callings.fellowship_member(id)
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
	# Boulder fists: an Iron-Root blow, so the fists glow amber through the wind-up and an Iron-Root Ward-Mantle soaks it.
	swipe.scribe_sign = ScribeSignResource.Sign.SIGN_IRON_ROOT

	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = RAID_BOSS_DUMMY
	loadout.display_name = BossDummy.DISPLAY_NAME
	loadout.role = ClassLoadoutResource.Role.BOSS
	loadout.body_color = BOSS_COLOR
	loadout.stats = stats
	loadout.openers = [swipe]
	return loadout


# --- Woodland minions (07 GDD §3, Zone 1) ------------------------------------

## A Bramble-Hob (quick, a darting nip) or a Wisp-Boggle (slower, a
## heavier claw). Both have 65 health and 30 poise: built to be swept up by
## cleaves, volleys and Sign detonations on the way to the boss.
static func woodland_minion(kind: int) -> ClassLoadoutResource:
	var imp: bool = kind == WoodlandMinion.Kind.IMP
	var stats: CharacterStatsResource = CharacterStatsResource.new()
	stats.max_health = WoodlandMinion.HEALTH
	stats.max_poise = WoodlandMinion.POISE
	stats.poise_regen_per_sec = 10.0
	stats.poise_regen_delay = 2.5
	stats.poise_knockdown_time = 2.0
	stats.knockdown_damage_taken = 1.25
	stats.move_speed = 3.6 if imp else 4.6
	stats.turn_speed = 7.0

	var strike: CombatActionResource = CombatActionResource.new()
	strike.action_id = StringName("%s_strike" % MINION_CLASSES[kind])
	strike.display_name = "Claw" if imp else "Nip"
	strike.command = Cmd.LIGHT
	strike.windup_time = 0.55 if imp else 0.4
	strike.active_time = 0.12
	strike.recovery_time = 0.6 if imp else 0.45
	strike.stamina_cost = 0.0
	strike.damage = 10.0 if imp else 7.0
	strike.reach = 1.3
	strike.hit_radius = 0.9
	strike.hit_stop_scale = 0.8
	strike.resonance_gain = 0.0

	var loadout: ClassLoadoutResource = ClassLoadoutResource.new()
	loadout.class_id = MINION_CLASSES[kind]
	loadout.display_name = WoodlandMinion.KIND_NAMES[kind]
	loadout.role = ClassLoadoutResource.Role.BOSS
	loadout.body_color = MINION_COLORS[kind]
	loadout.stats = stats
	loadout.openers = [strike]
	return loadout
