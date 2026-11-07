## The Arsenal Catalog (autoload "Arsenal"): every Scribe Sign, armor, weapon
## and Scribe Card in the game, indexed by StringName id
## (05_ARSENAL_AND_CARDS_GDD.md). Kits, the roster, save files and RPCs name
## things by id and look them up here, so every peer resolves an id to the
## same data.
##
## Adding a card or a weapon is one register call below, or a .tres card file
## dropped in CARD_FOLDER. Nothing that plays cards or weapons changes.
##
## It also holds the Trail of the Four Signs (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md
## §5): four tiers of each weapon, the Level 1 kit each Fellowship starts in,
## and what each milestone level grants.
##
## And Sign-Flow (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md): every lead card is an
## Action-Leaf with a manifestation (Weapon-Coat, Ward-Mantle, Lantern-Tether),
## the four Place-Cards that frame them, the dioramas they make together
## (compute_diorama_synergy), and every foe's BossEncounterResource: its threat
## tier, level, counter Signs and Glimmer-Spot window.
##
## And the Phase 12 Kaizen pass (14 GDD §8): the five directional combo forms
## (ComboChainResource, get_unlocked_combos_for_level), each role's coat (a
## Tank's Ward-Mantle shrugs off stuns; a Support's leaf shares its ink), the
## Miyamoto tiers of every foe with their locks, and the henchmen a boss can
## summon in its second gate.
##
## And the Seal-and-Tuck Grimoire (docs/everwood_equipment_grimoire_architecture.md
## Part II): the seven material tiers (EquipmentTierResource) a frame is
## promoted through, the four base armaments (WeaponArchetypeResource), the
## seal cards pressed onto gear and pulled from the pouch, the Rank 40 Elder
## Cairn-Drake, the Dual-Readout level maths (True Level 1-20 inside, Renown
## Rank 1-40 on the banners), evaluate_hit_damage and evaluate_incoming_hit,
## and the default hand a hero wears by stage (default_seal_loadout).
class_name ArsenalCatalog
extends Node

## The live autoload node (see NetworkManager.current for why).
static var current: ArsenalCatalog

## Card resources saved as .tres files here are registered at startup too.
const CARD_FOLDER: String = "res://data/cards/"
## Odds of a chest card being a Plain Vellum, Gilded Leaf or Star-Inked Vellum copy.
## A dropped card's finish (25 GDD R3): nine in ten Plain Ink, one in ten Gilded Leaf;
## Star-Ink never drops, it is pressed.
const VARIANT_ODDS: Array[float] = [0.9, 0.1, 0.0]

# Armor
const HEARTH_LINEN: StringName = &"hearth_linen"
const RANGER_LEATHER: StringName = &"ranger_leather"
const IRONWOOD_PLATE: StringName = &"ironwood_plate"
## The trail's first coat: every Fellowship's Level 1 armor.
const BRAMBLE_JERKIN: StringName = &"armor_bramble_jerkin"
# The classic weapons (05 GDD §2.2): Bramble-Bridge steel, with the base numbers
# every trail tier is a multiple of.
const LIGHT_SWORD: StringName = &"light_sword"
const HEAVY_AXE: StringName = &"heavy_axe"
const SCRIBE_STAFF: StringName = &"scribe_staff"
const HUNTER_BOW: StringName = &"hunter_bow"
# The trail's weapons (11 GDD §5.1). Tier 1: Apprentice Timber.
const HAZEL_FALCHION: StringName = &"weapon_hazel_falchion"
const ASH_BROADAXE: StringName = &"weapon_ash_broadaxe"
const REED_WAYSTAFF: StringName = &"weapon_reed_waystaff"
const WILLOW_LONGBOW: StringName = &"weapon_willow_longbow"
# Tier 2: Hedgerow Iron.
const IRON_FALCHION: StringName = &"weapon_iron_falchion"
const COPPICE_BROADAXE: StringName = &"weapon_coppice_broadaxe"
const COPPER_WAYSTAFF: StringName = &"weapon_copper_waystaff"
const HORN_LONGBOW: StringName = &"weapon_horn_longbow"
# Tier 3: Bramble-Bridge Steel.
const BRAMBLE_FALCHION: StringName = &"weapon_bramble_falchion"
const MILL_BROADAXE: StringName = &"weapon_mill_broadaxe"
const SCRIBE_WAYSTAFF: StringName = &"weapon_scribe_waystaff"
const WEALD_LONGBOW: StringName = &"weapon_weald_longbow"
# Tier 4: Doverslap Relic.
const CAIRNSMAN_FALCHION: StringName = &"weapon_cairnsman_falchion"
const DOVERSLAP_BROADAXE: StringName = &"weapon_doverslap_broadaxe"
const CARILLON_WAYSTAFF: StringName = &"weapon_carillon_waystaff"
const GORGE_LONGBOW: StringName = &"weapon_gorge_longbow"
## The trail's weapons by tier (index 0 is Tier 1), each list in WeaponType
## order: Falchion, Broad-Axe, Way-Staff, Longbow.
const TIER_WEAPONS: Array[Array] = [
	[HAZEL_FALCHION, ASH_BROADAXE, REED_WAYSTAFF, WILLOW_LONGBOW],
	[IRON_FALCHION, COPPICE_BROADAXE, COPPER_WAYSTAFF, HORN_LONGBOW],
	[BRAMBLE_FALCHION, MILL_BROADAXE, SCRIBE_WAYSTAFF, WEALD_LONGBOW],
	[CAIRNSMAN_FALCHION, DOVERSLAP_BROADAXE, CARILLON_WAYSTAFF, GORGE_LONGBOW],
]
## The classic weapon of each WeaponType: the template its tiers scale.
const CLASSIC_WEAPONS: Array[StringName] = [LIGHT_SWORD, HEAVY_AXE, SCRIBE_STAFF, HUNTER_BOW]
## Each tier's name, opening level, damage and poise multiplier and palette (11 GDD §5.1), Tier 1 first.
const TIER_NAMES: Array[String] = ["Apprentice Timber", "Hedgerow Iron", "Bramble-Bridge Steel", "Doverslap Relic"]
const TIER_LEVELS: Array[int] = [1, 2, 5, 10]
const TIER_MULTIPLIERS: Array[float] = [1.0, 1.2, 1.45, 1.75]
## Unvarnished hazel, hammered dark iron, milled steel, gilded Carillon bronze.
const TIER_BLADES: Array[Color] = [Color(0.651, 0.482, 0.357), Color(0.353, 0.384, 0.416), Color(0.769, 0.808, 0.831), Color(0.898, 0.757, 0.345)]
## Hemp cord #C8B594, brass rivets #B88B3A, a brass bell-guard #D4A84E, star-etched steel round the Sign-stone (19 GDD §5.3).
const TIER_TRIMS: Array[Color] = [Color(0.784, 0.710, 0.580), Color(0.722, 0.545, 0.227), Color(0.831, 0.659, 0.306), Color(0.79, 0.83, 0.86)]
## The grip: hemp-wrapped hazel, an oak grip, dyed leather, dark leather.
const TIER_GRIPS: Array[Color] = [Color(0.851, 0.765, 0.604), Color(0.478, 0.322, 0.188), Color(0.2, 0.32, 0.36), Color(0.29, 0.2, 0.15)]
const TIER_METALLIC: Array[float] = [0.0, 0.55, 0.8, 0.9]
const TIER_ROUGHNESS: Array[float] = [0.78, 0.52, 0.32, 0.22]
## Each tier's look as a WeaponVisualTierResource id (19 GDD §5.3), and how brightly its Sign-stone core glows.
const TIER_IDS: Array[StringName] = [&"apprentice_timber", &"hedgerow_iron", &"bramble_bridge_steel", &"dover_slap_relic"]
const TIER_SIGN_CORE_EMISSION: Array[float] = [0.0, 0.2, 0.5, 1.8]
## What each tier adds to the sculpt.
const TIER_CRAFT_NOTES: Array[String] = [
	"Lathe-turned hazel with chamfered edges, criss-cross hemp cord and an oak-leaf twig at the pommel.",
	"Hand-hammered dark iron with a bright honed bevel, an ash haft, a squared guard and brass rivets.",
	"Fuller-grooved milled steel, reinforced wings, a cast-brass bell-guard and a diamond-wrapped grip.",
	"Scroll-forged gilded bronze round an open cage that holds a turning Sign-stone core.",
]
# The heroes' looks (19 GDD §5.4): four heritage dye presets for couch co-op, one per seat.
const TIZZI_WED_PINE: StringName = &"tizzi_wed_pine"
const GULL_WICK_SLATE: StringName = &"gull_wick_slate"
const BARLEY_BRIDGE_RUSSET: StringName = &"barley_bridge_russet"
const BARROW_CRAG_HEATHER: StringName = &"barrow_crag_heather"
## The youth's own heather-blue cape (not a seat dye: the first seat keeps it).
const YOUTH_HEATHER: StringName = &"youth_heather"
const HERITAGE_DYES: Array[StringName] = [TIZZI_WED_PINE, GULL_WICK_SLATE, BARLEY_BRIDGE_RUSSET, BARROW_CRAG_HEATHER]
## The Doverslap relics' glowing Sign-stone.
const SIGN_STONE_COLOR: Color = Color(1.0, 0.9, 0.62)
## Each WeaponType's Un-Inked Martial Flourishes (11 GDD §4.1): R, then L+R.
const UNINKED_NAMES: Array[Array] = [
	["Timber-Cross Slash", "Bramble-Whirl Flurry"],
	["Coppice-Splitter Slam", "Heartwood Sundering"],
	["Reed-Sweep Gust", "Lantern-Keeper's Chime"],
	["Vaulting Bough-Shot", "Hail of the Hedgerow"],
]
# Starter lead cards (three per Grimoire slot: one each from the tank, healer and DPS kits)
const SHIELD_CHARGE: StringName = &"shield_charge"
const RISING_DRIVE: StringName = &"rising_drive"
const SUNLIT_LANCE: StringName = &"sunlit_lance"
const SHADOW_SANCTUARY: StringName = &"shadow_sanctuary"
const FROST_CRESCENT: StringName = &"frost_crescent"
const GREEN_SANCTUARY: StringName = &"green_sanctuary"
const TAUNT: StringName = &"taunt"
const HOMING_HEAL: StringName = &"homing_heal"
const GALE_RUSH: StringName = &"gale_rush"
const BULWARK_QUAKE: StringName = &"bulwark_quake"
const LIFELINE_PULL: StringName = &"lifeline_pull"
const TEMPEST_FLOW: StringName = &"tempest_flow"
## The Wayfarers' first Plain Vellum R card on the trail (Level 3).
const RIME_LASH: StringName = &"rime_lash"
# Boss-drop lead cards
const MOONFALL_CLEAVE: StringName = &"moonfall_cleave"
const EMBER_AEGIS: StringName = &"ember_aegis"
const STARLIT_VOLLEY: StringName = &"starlit_volley"
const DAWNBREAKER: StringName = &"dawnbreaker"
# Uncommon cards found on the Doverslap Falls Expedition (the Wayfarer's Chest).
const HOLLOWAY_LUNGE: StringName = &"holloway_lunge"
const ROOT_SNARE_STEP: StringName = &"root_snare_step"
const LANTERN_MOTE: StringName = &"lantern_mote"
const GORGE_GALE: StringName = &"gorge_gale"
# Under-cards
const IRON_ROOT_LINK: StringName = &"iron_root_link"
const RIME_GALE_LINK: StringName = &"rime_gale_link"
const WARM_HEARTH_LINK: StringName = &"warm_hearth_link"
const STAR_TIDE_LINK: StringName = &"star_tide_link"
# Action-Leaves the Reed-Light Scribery inscribes (14 GDD §4.1): with the cards
# above, every Sign has a Weapon-Coat, a Ward-Mantle and a Lantern-Tether leaf.
const OAK_KNOT_TETHER: StringName = &"leaf_oak_knot_tether"
const RIME_MANTLE_BASH: StringName = &"leaf_rime_mantle_bash"
const MIST_LANTERN_MEND: StringName = &"leaf_mist_lantern_mend"
const EMBER_COAT_CUT: StringName = &"leaf_ember_coat_cut"
const HEARTH_MANTLE_BRACE: StringName = &"leaf_hearth_mantle_brace"
const STAR_THREAD_MEND: StringName = &"leaf_star_thread_mend"
## The lead cards that manifest as a Ward-Mantle or a Lantern-Tether; every other lead card is a Weapon-Coat.
const WARD_MANTLE_LEAVES: Array[StringName] = [SHIELD_CHARGE, SHADOW_SANCTUARY, TAUNT, BULWARK_QUAKE, EMBER_AEGIS,
	RIME_MANTLE_BASH, HEARTH_MANTLE_BRACE]
const LANTERN_TETHER_LEAVES: Array[StringName] = [SUNLIT_LANCE, GREEN_SANCTUARY, HOMING_HEAL, LIFELINE_PULL, DAWNBREAKER,
	LANTERN_MOTE, OAK_KNOT_TETHER, MIST_LANTERN_MEND, STAR_THREAD_MEND]
# The four Place-Cards (14 GDD §4.2), one per Sign, each charted from a landmark.
const ARIUNDLE_MOSS_OAKS: StringName = &"loc_ariundle_moss_oaks"
const DOVERSLAP_GORGE: StringName = &"loc_doverslap_gorge"
const BRAMBLEBRIDGE_MILL: StringName = &"loc_bramblebridge_mill"
const BARROW_CRAG_TOR: StringName = &"loc_barrow_crag_tor"
const PLACE_CARDS: Array[StringName] = [ARIUNDLE_MOSS_OAKS, DOVERSLAP_GORGE, BRAMBLEBRIDGE_MILL, BARROW_CRAG_TOR]
## A Sign-Flow coat with no Action-Leaf (an un-inked socket) lasts this long.
const UNINKED_COAT_DURATION: float = 8.0
## The un-inked colour (warm ivory-gold), as ActorVisuals channels it.
const UNINKED_INK: Color = Color(1.0, 0.9, 0.62)
# Encounters (14 GDD §3), by threat tier.
const ROADSIDE_KIN: StringName = &"roadside_kin"
const SCREE_WORM: StringName = &"scree_worm"
## The starting zone's locked kin (Miyamoto Tiers 1 and 2), by family.
const FROST_FANG_KIN: StringName = &"frost_fang_padfoot"
const IRON_MAN_KIN: StringName = &"furrow_iron_man_rust"
const BRAMBLE_HOB_KIN: StringName = &"bramble_hob_bark"
const SPRIGGAN_KIN: StringName = &"crag_spriggan_shield"
const CRAG_BACK_DRAKE: StringName = &"crag_back_cairn_drake"
const SHINGLE_SCRAY: StringName = &"shingle_scray"
const CAIRNSMAN: StringName = &"cairnsman"
const GALE_BUCCA: StringName = &"gale_bucca"
const FURROW_IRON_MAN: StringName = &"furrow_iron_man"
const CAIRN_DRAKE: StringName = &"cairn_drake"
const TOR_SLEEPER: StringName = &"tor_sleeper"
const OLD_HOB: StringName = &"old_hob"

# The directional combo forms (ComboChainResource), in the order the trail teaches them.
const COMBO_APPRENTICE_THREE_BEAT: StringName = &"combo_apprentice_three_beat"
const COMBO_SUNDERING_GAP_LEAP: StringName = &"combo_sundering_gap_leap"
const COMBO_WAYFARER_VAULT_STRIKE: StringName = &"combo_wayfarer_vault_strike"
const COMBO_WHIRLING_FLANK_SWEEP: StringName = &"combo_whirling_flank_sweep"
const COMBO_GRAND_SIGN_FLOW: StringName = &"combo_grand_sign_flow"

# Henchmen a boss can summon (BossEncounterResource.gate_2_henchman_id): a WoodlandMinion.Kind each.
const HENCHMAN_SCREE_WORM: StringName = &"mob_scree_worm"
const HENCHMAN_BRAMBLE_HOB: StringName = &"mob_bramble_hob"
const HENCHMAN_WISP_BOGGLE: StringName = &"mob_wisp_boggle"

# The Seal-and-Tuck Grimoire (docs/everwood_equipment_grimoire_architecture.md Part II).
## Words Gate 3 (the Four Philological Linter Rules) keeps off every tier, armament and seal card.
const BANNED_LINTER_WORDS: PackedStringArray = [
	"construct", "rune", "aspect", "wharf", "silt",
	"lamellar", "hauberk", "rubric", "inscription",
	"vibranium", "palladium", "platinum", "cannabis", "chain mail",
]
## The seven material tiers (§3.1), Tier 1 first.
const TIER_1_HOMESTEAD: StringName = &"TIER_1_HOMESTEAD"
const TIER_2_BOG_BRONZE: StringName = &"TIER_2_BOG_BRONZE"
const TIER_3_FORGE_IRON: StringName = &"TIER_3_FORGE_IRON"
const TIER_4_BARROW_STEEL: StringName = &"TIER_4_BARROW_STEEL"
const TIER_5_RIME_SILVER: StringName = &"TIER_5_RIME_SILVER"
const TIER_6_SAFFRON_GOLD: StringName = &"TIER_6_SAFFRON_GOLD"
const TIER_7_STAR_GLASS: StringName = &"TIER_7_STAR_GLASS"
## The Seal-and-Tuck branch's tier ids, read back as the tier now at their place on the ladder.
const LEGACY_TIER_IDS: Dictionary[StringName, StringName] = {
	&"TIER_4_RIME_SILVER": TIER_4_BARROW_STEEL, &"TIER_5_SAFFRON_GOLD": TIER_5_RIME_SILVER,
	&"TIER_6_CAIRN_HEART": TIER_6_SAFFRON_GOLD, &"TIER_7_STAR_HEART": TIER_7_STAR_GLASS,
}
const MATERIAL_TIER_IDS: Array[StringName] = [TIER_1_HOMESTEAD, TIER_2_BOG_BRONZE, TIER_3_FORGE_IRON, TIER_4_BARROW_STEEL,
	TIER_5_RIME_SILVER, TIER_6_SAFFRON_GOLD, TIER_7_STAR_GLASS]
## The four base armaments (§2.2), in EquipmentTierResource.WeaponArchetype order.
const WEAPON_SWORD_BOARD: StringName = &"WEAPON_SWORD_BOARD"
const WEAPON_GREAT_MALLET: StringName = &"WEAPON_GREAT_MALLET"
const WEAPON_BOUGH_BOW: StringName = &"WEAPON_BOUGH_BOW"
const WEAPON_LANTERN_STAFF: StringName = &"WEAPON_LANTERN_STAFF"
const WEAPON_ARCHETYPE_IDS: Array[StringName] = [WEAPON_SWORD_BOARD, WEAPON_GREAT_MALLET, WEAPON_BOUGH_BOW, WEAPON_LANTERN_STAFF]
## The canonical seal cards (§6.4), one per Sign.
const CARD_QUIET_WEIR: StringName = &"CARD_QUIET_WEIR"
const CARD_EMBER_BOUGH: StringName = &"CARD_EMBER_BOUGH"
const CARD_OLD_ROOT_BASTION: StringName = &"CARD_OLD_ROOT_BASTION"
const CARD_WEST_WIND_PROMISE: StringName = &"CARD_WEST_WIND_PROMISE"
const SEAL_CARD_IDS: Array[StringName] = [CARD_QUIET_WEIR, CARD_EMBER_BOUGH, CARD_OLD_ROOT_BASTION, CARD_WEST_WIND_PROMISE]
## The Rank 40 apex threat (§5.1): True Level 20, 18,500 health, 1,200 posture.
const ELDER_CAIRN_DRAKE: StringName = &"elder_cairn_drake"
const ELDER_CAIRN_DRAKE_HP: float = 18500.0
const ELDER_CAIRN_DRAKE_POSTURE: float = 1200.0
## The homestead's first foes (§5.1): a Bramble-Mite and an awakened Boulder-Badger.
const BRAMBLE_MITE_HP: float = 25.0
const BOULDER_BADGER_HP: float = 45.0
## The Dual-Readout curve: True Level 1-20 inside the maths, Renown Rank 1-40 (two a level) on every banner.
const MAX_TRUE_LEVEL: int = 20
const MAX_RENOWN_RANK: int = 40
const RENOWN_PER_TRUE_LEVEL: int = 2
## Seal wards and tier armour together never take more than this off a blow.
const WARD_CAP: float = 0.80
## A raid boss's poise must break every 35 to 50 s (04_BALANCE.md); a homestead foe falls to a stick in 12 to 15 s.
const STAGGER_CADENCE_MIN_SEC: float = 35.0
const STAGGER_CADENCE_MAX_SEC: float = 50.0
const HOMESTEAD_FIGHT_MIN_SEC: float = 12.0
const HOMESTEAD_FIGHT_MAX_SEC: float = 15.0
## Posture-bearing heavies a raiding hero lands a second (one every eleven, between roars and rolls), and a child's honest stick swings.
const RAID_POSTURE_STRIKES_PER_SEC: float = 0.09
const HOMESTEAD_STRIKES_PER_SEC: float = 0.65
## What the Reed-Light Scribery asks for a seal card (bought once, it fits every slot).
const SEAL_CHIME_COST: int = 40
## Each role's default hand, auto-stamped by stage until a player chooses their own at the Binder's
## stamping bench: the weapon, off-hand and mantle seals, then the L primary, L tuck, R primary and
## R tuck (by ClassLoadoutResource.Role). Each slot's card is the Fellowship's starting seal there,
## which the bench always offers in that slot (like a starter Ink Card, it needs no copy).
const ROLE_SEAL_HANDS: Dictionary[int, Array] = {
	# Weapon, offhand and mantle: three different seals (25 GDD R5). The four pocket slots
	# are empty: the L, R and L+R cards live in the kit's sockets now.
	ClassLoadoutResource.Role.TANK: [CARD_OLD_ROOT_BASTION, CARD_QUIET_WEIR, CARD_WEST_WIND_PROMISE, &"", &"", &"", &""],
	ClassLoadoutResource.Role.HEALER: [CARD_WEST_WIND_PROMISE, CARD_EMBER_BOUGH, CARD_QUIET_WEIR, &"", &"", &"", &""],
	ClassLoadoutResource.Role.DPS: [CARD_EMBER_BOUGH, CARD_OLD_ROOT_BASTION, CARD_WEST_WIND_PROMISE, &"", &"", &"", &""],
}

# The Secondary Callings (06 §3, 07 GDD §1.3), in column order.
const STOUT_HEART: StringName = &"stout_heart"
const SWIFT_FOOT: StringName = &"swift_foot"
const WISE_HAND: StringName = &"wise_hand"

# The Trail of the Four Signs (11 GDD §5.2).
const MAX_TRAIL_LEVEL: int = 10
## The levels that grant something.
const MILESTONE_LEVELS: Array[int] = [2, 3, 5, 7, 10]
## The Under-Card link beneath R opens here; the Secondary Callings at CALLING_LEVEL.
const UNDER_TUCK_LEVEL: int = 7
const CALLING_LEVEL: int = 10
## Each Fellowship's trail, by ClassLoadoutResource.Role (Tank, Mender, DPS):
## the weapon type it starts with, its Forward and Back cards (in the grimoire
## from Level 1), and the R card (Level 3), L+R card (Level 5) and Under-Card
## (Level 7) the trail grants it.
const ROLE_WEAPON_TYPES: Array[int] = [EquipmentItemResource.WeaponType.LIGHT_SWORD, EquipmentItemResource.WeaponType.STAFF,
	EquipmentItemResource.WeaponType.BOW]
const ROLE_FORWARD_CARDS: Array[StringName] = [SHIELD_CHARGE, SUNLIT_LANCE, RISING_DRIVE]
const ROLE_BACK_CARDS: Array[StringName] = [SHADOW_SANCTUARY, GREEN_SANCTUARY, FROST_CRESCENT]
const ROLE_R_CARDS: Array[StringName] = [TAUNT, HOMING_HEAL, RIME_LASH]
const ROLE_ULT_CARDS: Array[StringName] = [BULWARK_QUAKE, LIFELINE_PULL, TEMPEST_FLOW]
const ROLE_UNDER_CARDS: Array[StringName] = [IRON_ROOT_LINK, WARM_HEARTH_LINK, STAR_TIDE_LINK]

const Cmd = CombatActionResource.Command
const Fx = CombatActionResource.Effect
const Sign = ScribeSignResource.Sign
const Slot = ScribeCardResource.GrimoireSlot
const Part = PropPartResource.Shape
const Tier = BossEncounterResource.MiyamotoTier
const Key = BossEncounterResource.LockKeyType

var _signs: Dictionary[int, ScribeSignResource] = {}
var _secondaries: Dictionary[StringName, SecondaryCallingResource] = {}
var _callings: Dictionary[StringName, CallingResource] = {}
var _secondary_order: Array[StringName] = []
var _items: Dictionary[StringName, EquipmentItemResource] = {}
var _cards: Dictionary[StringName, ScribeCardResource] = {}
var _encounters: Dictionary[StringName, BossEncounterResource] = {}
var _combos: Dictionary[StringName, ComboChainResource] = {}
var _combo_order: Array[StringName] = []
## Henchman id -> WoodlandMinion.Kind.
var _henchmen: Dictionary[StringName, int] = {}
# Registration order, so menus and drop rolls are the same on every peer.
var _item_order: Array[StringName] = []
var _card_order: Array[StringName] = []
var _weapon_tiers: Array[WeaponVisualTierResource] = []
var _appearances: Dictionary[StringName, HeroAppearanceResource] = {}
var _appearance_order: Array[StringName] = []
## The Unsworn Level 1 youth's look, one per Fellowship row (21_WINGFEATHER_YOUTH_HERO.md).
var _youths: Array[HeroAppearanceResource] = []
var _dyes: Dictionary[StringName, HeroAppearanceResource] = {}
## The Seal-and-Tuck Grimoire's registries, in registration order.
var _tiers: Dictionary[StringName, EquipmentTierResource] = {}
var _tier_order: Array[StringName] = []
var _archetypes: Dictionary[StringName, WeaponArchetypeResource] = {}
var _archetype_order: Array[StringName] = []


func _init() -> void:
	_build_signs()
	_build_material_tiers()
	_build_weapon_archetypes()
	_build_weapon_visual_tiers()
	_build_armor()
	_build_weapons()
	_build_tier_weapons()
	_build_lead_cards()
	_build_under_cards()
	_build_action_leaves()
	_build_place_cards()
	_build_seal_cards()
	_build_callings()
	_build_hero_appearances()
	_build_encounters()
	_build_combos()
	_build_henchmen()
	_load_card_folder()


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


# --- Lookups --------------------------------------------------------------

func sign_seal(scribe_sign: int) -> ScribeSignResource:
	return _signs.get(scribe_sign, _signs[Sign.NONE])


func item(id: StringName) -> EquipmentItemResource:
	return _items.get(id, null)


func card(id: StringName) -> ScribeCardResource:
	return _cards.get(id, null)


# --- The Seal-and-Tuck Grimoire (docs/everwood_equipment_grimoire_architecture.md) -------

## A material tier by id (&"TIER_3_FORGE_IRON"), or null.
func get_tier(tier_id: StringName) -> EquipmentTierResource:
	return _tiers.get(LEGACY_TIER_IDS.get(tier_id, tier_id), null)


## The tier at a place on the ladder (1 to 7), or null.
func tier_at(index: int) -> EquipmentTierResource:
	return _tiers.get(_tier_order[index - 1], null) if index >= 1 and index <= _tier_order.size() else null


## The seven tiers, Tier 1 first.
func get_all_tiers() -> Array[EquipmentTierResource]:
	var list: Array[EquipmentTierResource] = []
	for id: StringName in _tier_order:
		list.append(_tiers[id])
	return list


func material_tiers() -> Array[EquipmentTierResource]:
	return get_all_tiers()


## The tier forged for a True Level: Lv 1-3 Tier 1, 4-6 Tier 2, 7-10 Tier 3 ... Lv 20 Tier 7.
func tier_for_true_level(true_level: int) -> EquipmentTierResource:
	var level: int = clampi(true_level, 1, MAX_TRUE_LEVEL)
	var reached: EquipmentTierResource = null
	for tier: EquipmentTierResource in get_all_tiers():
		if tier.covers_true_level(level):
			return tier
		if tier.min_true_level <= level:
			reached = tier
	return reached if reached != null else get_tier(TIER_1_HOMESTEAD)


## The tier a banner's Renown Rank (1..40) wears.
func tier_for_renown(renown_rank: int) -> EquipmentTierResource:
	return tier_for_true_level(compute_true_level_from_renown(renown_rank))


## A card by id, as the Grimoire names the call (the same as card()).
func get_card(card_id: StringName) -> ScribeCardResource:
	return card(card_id)


func get_all_cards() -> Array[ScribeCardResource]:
	return cards()


## The seal cards (pressed onto gear before battle, pulled from the pouch in it), in registration order.
func seal_cards() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_seal_card():
			list.append(listed)
	return list


## A base armament by id (&"WEAPON_GREAT_MALLET"), or null.
func weapon_archetype(archetype_id: StringName) -> WeaponArchetypeResource:
	return _archetypes.get(archetype_id, null)


## The four armaments, in WeaponArchetype order.
func weapon_archetypes() -> Array[WeaponArchetypeResource]:
	var list: Array[WeaponArchetypeResource] = []
	for id: StringName in _archetype_order:
		list.append(_archetypes[id])
	return list


## The armament a trail weapon type channels: a Falchion is the Sword & Board, a Broad-Axe the
## Great-Mallet, a Longbow the Bough-Bow, a Way-Staff the Lantern-Staff.
func archetype_for_weapon_type(weapon_type: int) -> WeaponArchetypeResource:
	for listed: WeaponArchetypeResource in weapon_archetypes():
		if listed.weapon_type == weapon_type:
			return listed
	return weapon_archetype(WEAPON_SWORD_BOARD)


## The armament for an EquipmentTierResource.WeaponArchetype value.
func archetype_for_enum(archetype: int) -> WeaponArchetypeResource:
	return weapon_archetype(WEAPON_ARCHETYPE_IDS[clampi(archetype, 0, WEAPON_ARCHETYPE_IDS.size() - 1)])


## A Secondary Calling by id (&"swift_foot"), or null.
func secondary_calling(id: StringName) -> SecondaryCallingResource:
	return _secondaries.get(id, null)


## The Secondary Calling in a column of the matrix (Callings.Secondary), or null.
func secondary_at(column: int) -> SecondaryCallingResource:
	return _secondaries[_secondary_order[column]] if column >= 0 and column < _secondary_order.size() else null


## The Secondary Callings in column order.
func secondary_callings() -> Array[SecondaryCallingResource]:
	var list: Array[SecondaryCallingResource] = []
	for id: StringName in _secondary_order:
		list.append(_secondaries[id])
	return list


## The Calling a Fellowship becomes with a Secondary (by id), or null.
func calling_for(fellowship_class_id: StringName, secondary_id: StringName) -> CallingResource:
	for listed: CallingResource in _callings.values():
		if listed.fellowship_class_id == fellowship_class_id and listed.secondary_id == secondary_id:
			return listed
	return null


## Every registered Calling.
func callings() -> Array[CallingResource]:
	var list: Array[CallingResource] = []
	list.assign(_callings.values())
	return list

# --- Heroes' looks (19 GDD §5) ----------------------------------------------

## A weapon tier's look, 1 to 4 (Apprentice Timber to Doverslap Relic).
func weapon_visual_tier(tier: int) -> WeaponVisualTierResource:
	return _weapon_tiers[clampi(tier, 1, _weapon_tiers.size()) - 1]


func weapon_visual_tiers() -> Array[WeaponVisualTierResource]:
	return _weapon_tiers.duplicate()


## A Calling's look by its calling_id (&"iron_woodsman"), or null.
func hero_appearance(calling_id: StringName) -> HeroAppearanceResource:
	return _appearances.get(calling_id, null)


## Every Calling's look, in the Callings' order.
func hero_appearances() -> Array[HeroAppearanceResource]:
	var list: Array[HeroAppearanceResource] = []
	for id: StringName in _appearance_order:
		list.append(_appearances[id])
	return list


## A heritage dye preset by id (&"gull_wick_slate"), or null.
func heritage_dye(dye_id: StringName) -> HeroAppearanceResource:
	return _dyes.get(dye_id, null)


func heritage_dyes() -> Array[HeroAppearanceResource]:
	var list: Array[HeroAppearanceResource] = []
	for id: StringName in HERITAGE_DYES:
		list.append(_dyes[id])
	return list


## How a seat looks: its Calling's look (an Unsworn hero wears their
## Fellowship's own column, Bridge-Warden, Hedge-Runner or Lantern-Scribe) in
## its seat's heritage dye, so siblings on the couch in the same Calling still
## read apart. P1 wears the Calling's own dye.
func hero_appearance_for_seat(fellowship_class_id: StringName, column: int, party_slot: int) -> HeroAppearanceResource:
	var resolved: int = column if Callings.is_valid(column) else Callings.default_secondary(fellowship_class_id)
	var calling: CallingResource = calling_for(fellowship_class_id, Callings.id_of(resolved))
	var look: HeroAppearanceResource = hero_appearance(calling.calling_id) if calling != null else null
	if look == null:
		look = hero_appearance(&"iron_woodsman")
	if party_slot <= 0:
		return look
	var own: int = HERITAGE_DYES.find(look.coat_dye_preset)
	return look.with_dye(_dyes[HERITAGE_DYES[(maxi(own, 0) + party_slot) % HERITAGE_DYES.size()]])


func armors() -> Array[EquipmentItemResource]:
	return _items_in(EquipmentItemResource.ItemSlot.ARMOR)


func weapons() -> Array[EquipmentItemResource]:
	return _items_in(EquipmentItemResource.ItemSlot.WEAPON)


## Every card in registration order.
func cards() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for id: StringName in _card_order:
		list.append(_cards[id])
	return list


## The lead cards that fit one Grimoire slot.
func lead_cards(slot: int) -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_lead() and listed.slot == slot:
			list.append(listed)
	return list


func under_cards() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_under():
			list.append(listed)
	return list


## Every Action-Leaf (every lead card), in registration order.
func action_leaves() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_action_leaf():
			list.append(listed)
	return list


## The Place-Cards, in registration order.
func place_cards() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_place_card():
			list.append(listed)
	return list


## What the Reed-Light Scribery inscribes: the Common Action-Leaves nobody
## starts with. Uncommon trail finds and boss drops stay earned on the raid.
func scribery_leaves() -> Array[ScribeCardResource]:
	var list: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in action_leaves():
		if not listed.starter and listed.rarity == ScribeCardResource.CardRarity.COMMON and listed.chime_cost > 0:
			list.append(listed)
	return list


## The most poise any Place-Card lends a strike, at its finest finish (the cap on what another peer may claim).
func max_place_poise() -> float:
	var most: float = 0.0
	for place: ScribeCardResource in place_cards():
		most = maxf(most, place.location_bonus_poise)
	return most * ScribeCardResource.finish_potency(ScribeCardResource.CardVariant.STAR_INKED_VELLUM)


## A diorama pair (14 GDD §4): an Action-Leaf framed by a Place-Card, either
## of which may be empty (&""). Returns what a Sign-Flow coat of it does:
##   scribe_sign, manifestation_mode   from the leaf (Sign.NONE and Weapon-Coat when un-inked)
##   place_sign, is_home_ground_harmony   true when leaf and place share a Sign
##   coat_duration_sec                 the leaf's, x the place's home-ground multiplier on harmony
##   bonus_reach_m, bonus_poise, bonus_heal, stamina_refund   what the place lends
##     (x its finish's potency: Gilded Leaf +10%, Star-Inked Vellum +20%)
##   ink_color, ambient_color          the leaf's Sign colour and the place's tint
##   shares_ink, grants_stun_immunity, ward_mitigation, ward_reflected_poise,
##   one_and_done_mult                 what the leaf's role does with its coat (14 GDD §8)
func compute_diorama_synergy(action_card_id: StringName, location_card_id: StringName,
		action_variant: int = ScribeCardResource.CardVariant.STANDARD, location_variant: int = ScribeCardResource.CardVariant.STANDARD) -> Dictionary:
	var action: ScribeCardResource = card(action_card_id)
	var place: ScribeCardResource = card(location_card_id)
	var place_potency: float = ScribeCardResource.finish_potency(location_variant)
	var inked: bool = action != null and action.is_action_leaf()
	var framed: bool = place != null and place.is_place_card()
	var leaf_sign: int = action.scribe_sign if inked else Sign.NONE
	var place_sign: int = place.scribe_sign if framed else Sign.NONE
	var harmony: bool = inked and framed and leaf_sign != Sign.NONE and leaf_sign == place_sign
	var duration: float = action.coat_duration_sec if inked else UNINKED_COAT_DURATION
	if harmony:
		duration *= place.home_ground_duration_mult
	var ink: Color = sign_seal(leaf_sign).color if leaf_sign != Sign.NONE else UNINKED_INK
	return {
		"action_card_id": action.card_id if inked else &"",
		"location_card_id": place.card_id if framed else &"",
		"scribe_sign": leaf_sign,
		"manifestation_mode": action.manifestation_mode if inked else ScribeCardResource.ManifestationMode.WEAPON_COAT,
		"place_sign": place_sign,
		"is_home_ground_harmony": harmony,
		"coat_duration_sec": duration,
		"bonus_reach_m": place.location_bonus_reach_m if framed else 0.0,
		"bonus_poise": place.location_bonus_poise * place_potency if framed else 0.0,
		"bonus_heal": place.location_bonus_heal * place_potency if framed else 0.0,
		"stamina_refund": place.location_stamina_refund * place_potency if framed else 0.0,
		"ink_color": ink,
		"ambient_color": sign_seal(place_sign).color if framed else ink,
		"action_variant": action_variant if inked else ScribeCardResource.CardVariant.STANDARD,
		"location_variant": location_variant if framed else ScribeCardResource.CardVariant.STANDARD,
		"shares_ink": inked and action.shares_ink(),
		"grants_stun_immunity": inked and action.grants_stun_immunity,
		"ward_mitigation": action.ward_damage_mitigation_pct if inked else 0.0,
		"ward_reflected_poise": action.ward_reflected_poise if inked else 0.0,
		"one_and_done_mult": action.one_and_done_finisher_mult if inked else 1.0,
	}


## A foe's encounter by id (&"cairnsman"), or null.
func encounter(id: StringName) -> BossEncounterResource:
	return _encounters.get(id, null)


func encounters() -> Array[BossEncounterResource]:
	var list: Array[BossEncounterResource] = []
	list.assign(_encounters.values())
	return list


## A combo form by id (&"combo_sundering_gap_leap"), or null.
func combo(id: StringName) -> ComboChainResource:
	return _combos.get(id, null)


## Every combo form, in the order the trail teaches them.
func combos() -> Array[ComboChainResource]:
	var list: Array[ComboChainResource] = []
	for id: StringName in _combo_order:
		list.append(_combos[id])
	return list


## The combo forms the party knows at this trail level (with a weapon of `weapon_tier`, 1-4).
func get_unlocked_combos_for_level(player_level: int, weapon_tier: int = EquipmentItemResource.EquipmentTier.TIER_4_RELIC) -> Array[ComboChainResource]:
	var list: Array[ComboChainResource] = []
	for listed: ComboChainResource in combos():
		if listed.is_unlocked(player_level, weapon_tier):
			list.append(listed)
	return list


## The WoodlandMinion.Kind a henchman id summons (-1 when there's no such henchman).
func henchman_kind(id: StringName) -> int:
	return _henchmen.get(id, -1)


## How a card copy reads in menus and banners: "Moonfall Cleave (Rare, Gilded Leaf)".
func copy_name(copy_key: StringName) -> String:
	var named: ScribeCardResource = card(ScribeCardResource.copy_card_id(copy_key))
	if named == null:
		return String(copy_key)
	var variant: ScribeCardResource.CardVariant = ScribeCardResource.copy_variant(copy_key)
	var extras: PackedStringArray = PackedStringArray()
	if named.rarity >= ScribeCardResource.CardRarity.RARE:
		extras.append(named.rarity_name())
	if variant != ScribeCardResource.CardVariant.STANDARD:
		extras.append(ScribeCardResource.VARIANT_NAMES[variant])
	return named.display_name if extras.is_empty() else "%s (%s)" % [named.display_name, ", ".join(extras)]


## The trail weapon of a WeaponType at a tier (1-4).
static func tier_weapon_id(weapon_type: int, tier: int) -> StringName:
	return TIER_WEAPONS[clampi(tier, 1, TIER_WEAPONS.size()) - 1][weapon_type]


# --- The Trail of the Four Signs (11 GDD §5) --------------------------------

## The Level 1 kit for a Primary Fellowship's role (ClassLoadoutResource.Role):
## its Tier 1 weapon, the Bramble-Spun Jerkin, its Forward and Back cards, and
## an un-inked R, L+R and Under-Card link (R and L+R fire Un-Inked Martial Flourishes).
func get_default_level_one_loadout_for_role(primary_role: int) -> Dictionary:
	var row: int = _trail_row(primary_role)
	return {
		"weapon_id": tier_weapon_id(ROLE_WEAPON_TYPES[row], 1),
		"armor_id": BRAMBLE_JERKIN,
		"forward_card_id": ROLE_FORWARD_CARDS[row],
		"back_card_id": ROLE_BACK_CARDS[row],
		"r_card_id": &"",
		"ult_card_id": &"",
		"under_card_id": &"",
	}


## What reaching `level` grants a Fellowship's role ({} for a level with no milestone):
##   2  its Tier 2 weapon           3  its first Plain Vellum R card
##   5  its Tier 3 weapon and L+R card
##   7  an Under-Card for the link beneath R
##   10 its Tier 4 relic, and the Secondary Callings open
func get_milestone_grant_for_level(level: int, primary_role: int) -> Dictionary:
	var row: int = _trail_row(primary_role)
	var weapon_type: int = ROLE_WEAPON_TYPES[row]
	match level:
		2:
			return {"level": level, "weapon_id": tier_weapon_id(weapon_type, 2)}
		3:
			return {"level": level, "r_card_id": ROLE_R_CARDS[row]}
		5:
			return {"level": level, "weapon_id": tier_weapon_id(weapon_type, 3), "ult_card_id": ROLE_ULT_CARDS[row]}
		7:
			return {"level": level, "under_card_id": ROLE_UNDER_CARDS[row]}
		10:
			return {"level": level, "weapon_id": tier_weapon_id(weapon_type, 4), "unlocks_secondary_calling": true}
	return {}


## Smart auto-slot (11 GDD §6): puts a milestone's grant into a kit where the
## slot is still at its starter state. A granted weapon replaces a lower tier
## (of the weapon type already carried, so a Wayfarer with a Broad-Axe gets the
## better Broad-Axe); a card fills R or L+R only while it's empty; an Under-Card
## fills the link beneath R only while it's empty. Returns what went in, by name.
func apply_milestone_grant(kit: EquipmentLoadoutResource, grant: Dictionary) -> PackedStringArray:
	var slotted: PackedStringArray = PackedStringArray()
	var granted: EquipmentItemResource = item(grant.get("weapon_id", &""))
	if granted != null:
		var worn: EquipmentItemResource = item(kit.weapon_id)
		if worn == null or worn.equipment_tier < granted.equipment_tier:
			kit.weapon_id = tier_weapon_id(worn.weapon_type if worn != null else granted.weapon_type, granted.equipment_tier)
			slotted.append(item(kit.weapon_id).display_name)
	for entry: Array in [["r_card_id", Slot.SIGNATURE], ["ult_card_id", Slot.ULTIMATE]]:
		var lead: ScribeCardResource = card(grant.get(entry[0], &""))
		if lead != null and kit.lead_ids[entry[1]] == &"":
			kit.lead_ids[entry[1]] = lead.card_id
			kit.lead_variants[entry[1]] = ScribeCardResource.CardVariant.STANDARD
			slotted.append(lead.display_name)
	var under: ScribeCardResource = card(grant.get("under_card_id", &""))
	if under != null and kit.under_ids[Slot.SIGNATURE] == &"":
		kit.under_ids[Slot.SIGNATURE] = under.card_id
		slotted.append(under.display_name)
	return slotted


## The kit a Fellowship's role wears at a trail level: the Level 1 kit with
## every milestone up to `level` auto-slotted in.
func trail_kit_for_role(primary_role: int, level: int) -> EquipmentLoadoutResource:
	var start: Dictionary = get_default_level_one_loadout_for_role(primary_role)
	var kit: EquipmentLoadoutResource = EquipmentLoadoutResource.make(start["armor_id"], start["weapon_id"],
		[start["forward_card_id"], start["back_card_id"], start["r_card_id"], start["ult_card_id"]])
	for milestone: int in MILESTONE_LEVELS:
		if milestone <= level:
			apply_milestone_grant(kit, get_milestone_grant_for_level(milestone, primary_role))
	return kit


## A role's row in the trail tables (bosses read as Wayfarers).
static func _trail_row(primary_role: int) -> int:
	match primary_role:
		ClassLoadoutResource.Role.TANK:
			return 0
		ClassLoadoutResource.Role.HEALER:
			return 1
	return 2


# --- The Dual-Readout curve and the Seal-and-Tuck maths (§5.1, §6.4) ----------------

## Maps a banner's Renown Rank (1..40) to the True Level the maths run on (1..20): Rank 40 is Level 20, Rank 1 Level 1.
static func compute_true_level_from_renown(renown_rank: int) -> int:
	return clampi(int(ceil(float(renown_rank) * 0.5)), 1, MAX_TRUE_LEVEL)


## Maps a True Level (1..20) to the Renown Rank shown for it (2..40).
static func compute_renown_from_true_level(true_level: int) -> int:
	return clampi(true_level * RENOWN_PER_TRUE_LEVEL, 1, MAX_RENOWN_RANK)


## The progression stage a True Level plays at: 1-5, 6-10, 11-15, 16-20 (§5.2).
static func compute_progression_stage(true_level: int) -> int:
	return PlayerLoadoutResource.stage_for_true_level(true_level)


## One blow's flat damage, the whole ladder in one function: the tier's light or
## heavy on the hand's armament, a Weapon Seal's flat bonus, and an active
## Pocket-Pull's multiplier (1.2x more under an Under-Card Tuck). A Lv 1
## Orchard-Stick: 2 or 3. A Tier 7 Star-Glass blade under the Ember-Bough's coat: 78 to 108.
func evaluate_hit_damage(loadout: PlayerLoadoutResource, is_heavy_attack: bool, is_active_invocation: bool,
		active_card_id: StringName = &"", has_tuck_synergy: bool = false) -> int:
	var tier: EquipmentTierResource = get_tier(loadout.equipped_tier_id) if loadout != null else null
	if tier == null:
		return 2
	var dmg: float = float(tier.get_weapon_damage(is_heavy_attack, loadout.weapon_archetype as EquipmentTierResource.WeaponArchetype))
	if loadout.weapon_seal_card_id != &"":
		var w_seal: ScribeCardResource = get_card(loadout.weapon_seal_card_id)
		if w_seal != null:
			dmg += float(w_seal.slot_passive(ScribeCardResource.SealSlotMask.SEAL_WEAPON)["flat"])
	if is_active_invocation and active_card_id != &"":
		var active_card: ScribeCardResource = get_card(active_card_id)
		if active_card != null:
			dmg *= active_card.active_damage_mult
			if has_tuck_synergy:
				dmg *= ScribeCardResource.TUCK_SYNERGY_DAMAGE_MULT
	return maxi(1, int(round(dmg)))


## What a foe's blow of `incoming_sign` (&"SIGN_STAR_TIDE") does to a hand: the
## tier's armour mitigation for its weight class plus every stamped seal's ward
## against that Sign (together never past WARD_CAP), and whether a seal shrugs
## the stun off. A Forge-Iron buckler stamped with the Quiet Weir takes a
## 100-damage Star-Tide blow for 46, unstunned.
func evaluate_incoming_hit(loadout: PlayerLoadoutResource, raw_damage: int, incoming_sign: StringName) -> Dictionary:
	var tier: EquipmentTierResource = null
	if loadout != null:
		tier = get_tier(loadout.armor_tier_id if loadout.armor_tier_id != &"" else loadout.equipped_tier_id)
	var mitigation: float = 0.04
	if tier != null:
		mitigation = tier.get_mitigation_for_class(loadout.armor_weight_class as EquipmentTierResource.ArmorWeightClass)
	var stun_immune: bool = false
	if loadout != null:
		for pressed: Array in loadout.seal_slots():
			var seal_card: ScribeCardResource = get_card(pressed[1])
			if seal_card != null and seal_card.wards_in_slot(pressed[0], incoming_sign):
				var passive: Dictionary = seal_card.slot_passive(pressed[0])
				mitigation = clampf(mitigation + float(passive["ward"]), 0.0, WARD_CAP)
				if bool(passive["stun"]):
					stun_immune = true
	var final_damage: int = maxi(1, int(round(float(raw_damage) * (1.0 - mitigation))))
	return {"final_damage": final_damage, "mitigation_applied": mitigation, "stun_immune": stun_immune}


## The strongest posture-break multiplier among a hand's seals (1.0 with none).
func posture_break_mult_of(loadout: PlayerLoadoutResource) -> float:
	var mult: float = 1.0
	if loadout == null:
		return mult
	for pressed: Array in loadout.seal_slots():
		var seal_card: ScribeCardResource = get_card(pressed[1])
		if seal_card != null:
			mult = maxf(mult, float(seal_card.slot_passive(pressed[0])["posture"]))
	return mult


## A party's posture damage a second against a raid boss, by the cadence model: each
## hero's tier posture, times its seals' posture-break multiplier, at RAID_POSTURE_STRIKES_PER_SEC.
func evaluate_party_posture_dps(loadouts: Array[PlayerLoadoutResource]) -> float:
	var total: float = 0.0
	for hand: PlayerLoadoutResource in loadouts:
		var tier: EquipmentTierResource = get_tier(hand.equipped_tier_id)
		if tier != null:
			total += tier.base_posture_damage * posture_break_mult_of(hand) * RAID_POSTURE_STRIKES_PER_SEC
	return total


## Seconds a party takes to break a posture pool (the Elder Cairn-Drake's 1,200 by default): the stagger cadence.
func estimate_stagger_seconds(loadouts: Array[PlayerLoadoutResource], posture_pool: float = ELDER_CAIRN_DRAKE_POSTURE) -> float:
	var dps: float = evaluate_party_posture_dps(loadouts)
	return INF if dps <= 0.0 else posture_pool / dps


## Seconds of honest swings a hand takes to beat `hit_points` (a Bramble-Mite's 25): light and heavy blows in turn.
func estimate_time_to_beat(loadout: PlayerLoadoutResource, hit_points: float, strikes_per_sec: float = HOMESTEAD_STRIKES_PER_SEC) -> float:
	# The tier's own decimals (2.4 and 3.5 on the Orchard-Stick), not the rounded blows.
	var tier: EquipmentTierResource = get_tier(loadout.equipped_tier_id) if loadout != null else null
	var arch: EquipmentTierResource.WeaponArchetype = loadout.weapon_archetype as EquipmentTierResource.WeaponArchetype if loadout != null else EquipmentTierResource.WeaponArchetype.WEAPON_SWORD_BOARD
	var per_blow: float = (tier.get_weapon_damage(false, arch) + tier.get_weapon_damage(true, arch)) * 0.5 if tier != null else 2.0
	return hit_points / maxf(per_blow * strikes_per_sec, 0.001)


## The hand a hero wears until the Binder has a stamping bench: the tier its True
## Level forged, its armament and its Fellowship's armour weight, and its role's
## seals and invocations (ROLE_SEAL_HANDS), trimmed to what its stage has opened.
## Odd seats are Female Youths, even seats Male, until a hero picks. A playtest's
## `stage_override` (1 to 4) opens the ladder's slots regardless of the level.
func default_seal_loadout(class_id: StringName, role: int, weapon_type: int, calling_id: StringName, true_level: int,
		party_slot: int = 0, stage_override: int = 0, use_promotions: bool = false) -> PlayerLoadoutResource:
	var hand: PlayerLoadoutResource = PlayerLoadoutResource.new()
	var level: int = clampi(true_level, 1, MAX_TRUE_LEVEL)
	var archetype: WeaponArchetypeResource = archetype_for_weapon_type(weapon_type)
	hand.body_type = posmod(party_slot, 2) as PlayerLoadoutResource.YouthBodyType
	hand.calling_id = calling_id if calling_id != &"" else class_id
	hand.weapon_archetype = archetype.archetype if archetype != null else EquipmentTierResource.WeaponArchetype.WEAPON_SWORD_BOARD
	hand.armor_weight_class = weight_class_for_role(role)
	# The tiers the Forge promoted this Fellowship's pieces to, never past what its level opens.
	var level_tier: int = tier_for_true_level(level).tier_index
	var progress: PartyProgress = PartyProgress.current
	var weapon_tier: int = level_tier
	var armor_tier: int = level_tier
	if use_promotions and progress != null and stage_override <= 0:
		weapon_tier = mini(progress.promoted_tier(class_id, PartyProgress.PIECE_WEAPON), level_tier)
		armor_tier = mini(progress.promoted_tier(class_id, PartyProgress.PIECE_ARMOR), level_tier)
	hand.equipped_tier_id = tier_at(weapon_tier).tier_id
	hand.armor_tier_id = tier_at(armor_tier).tier_id
	var picks: Array = ROLE_SEAL_HANDS.get(role, ROLE_SEAL_HANDS[ClassLoadoutResource.Role.DPS])
	hand.weapon_seal_card_id = picks[0]
	hand.offhand_seal_card_id = picks[1]
	hand.mantle_seal_card_id = picks[2]
	hand.slot_l_primary_id = picks[3]
	hand.slot_l_tuck_id = picks[4]
	hand.slot_r_primary_id = picks[5]
	hand.slot_r_tuck_id = picks[6]
	var stage: int = stage_override if stage_override > 0 else compute_progression_stage(level)
	hand.trim_to_stage(stage, level)
	return hand


# --- The Binder's stamping bench ------------------------------------------------------------

## A Fellowship's starting seal in one of the hand's seven slots (PlayerLoadoutResource.HandSlot), &"" for none.
static func starting_seal_for_slot(role: int, slot: int) -> StringName:
	var picks: Array = ROLE_SEAL_HANDS.get(role, ROLE_SEAL_HANDS[ClassLoadoutResource.Role.DPS])
	return picks[slot] if slot >= 0 and slot < picks.size() else &""


## Whether the party has a copy of a card in any finish.
static func owns_any_finish(card_id: StringName, collection: Dictionary[StringName, int]) -> bool:
	for variant: int in ScribeCardResource.CardVariant.size():
		if LoadoutComposer.owns(ScribeCardResource.copy_key(card_id, variant as ScribeCardResource.CardVariant), 1, collection):
			return true
	return false


## Whether a hero of `role` may press a seal card into a slot: the party owns a copy, or it is the
## Fellowship's starting seal for that slot (lent, like a starter Ink Card).
func seal_available(card_id: StringName, role: int, slot: int, collection: Dictionary[StringName, int]) -> bool:
	var listed: ScribeCardResource = get_card(card_id)
	if listed == null or not listed.is_seal_card():
		return false
	if PlayerLoadoutResource.is_seal_slot(slot) and not listed.can_stamp_into_slot(PlayerLoadoutResource.seal_flag_for_slot(slot)):
		return false
	return card_id == starting_seal_for_slot(role, slot) or owns_any_finish(card_id, collection)


## What a slot cycles through on the bench: none (&""), the Fellowship's starting seal for it,
## then every other seal card the party owns, in SEAL_CARD_IDS order.
func seal_options_for_slot(role: int, slot: int, collection: Dictionary[StringName, int]) -> Array[StringName]:
	var options: Array[StringName] = [&""]
	var starter: StringName = starting_seal_for_slot(role, slot)
	if starter != &"" and seal_available(starter, role, slot, collection):
		options.append(starter)
	for card_id: StringName in SEAL_CARD_IDS:
		if not options.has(card_id) and seal_available(card_id, role, slot, collection):
			options.append(card_id)
	return options


## Why a hero of `role` may not wear `hand` at a stage and level, in a few plain words ("" when it may):
## every card is a seal card the party owns (or the Fellowship's starting seal for that slot), pressed
## only where it fits, in a slot the ladder has opened (PlayerLoadoutResource.slot_open), and the hand
## fits the stage's counts (validate_loadout_for_stage). The host asks this of every hand a player sends.
func seal_hand_problem(hand: PlayerLoadoutResource, role: int, stage: int, true_level: int, collection: Dictionary[StringName, int]) -> String:
	if hand == null:
		return "No hand to wear"
	for slot: int in PlayerLoadoutResource.HAND_SLOT_COUNT:
		var card_id: StringName = hand.card_in_slot(slot)
		if card_id == &"":
			continue
		var slot_name: String = PlayerLoadoutResource.HAND_SLOT_NAMES[slot]
		var listed: ScribeCardResource = get_card(card_id)
		if not PlayerLoadoutResource.is_seal_slot(slot):
			return "The %s slot %s" % [slot_name, PlayerLoadoutResource.slot_opens_text(slot)]
		if listed == null or not listed.is_seal_card():
			return "Only seal cards go in the %s slot" % slot_name
		if not PlayerLoadoutResource.slot_open(slot, stage, true_level):
			return "The %s slot %s" % [slot_name, PlayerLoadoutResource.slot_opens_text(slot)]
		if PlayerLoadoutResource.is_seal_slot(slot) and not listed.can_stamp_into_slot(PlayerLoadoutResource.seal_flag_for_slot(slot)):
			return "%s can't go on the %s" % [listed.display_name, slot_name]
		if not seal_available(card_id, role, slot, collection):
			return "Get %s at the Reed-Light Scribery first" % listed.display_name
	var twice: StringName = GrimoireRules.duplicate_title(hand.seal_card_ids())
	if twice != &"":
		return "%s is already pressed on another piece" % get_card(twice).display_name
	if not hand.validate_loadout_for_stage(stage):
		return "Too many cards for Stage %d" % stage
	return ""


## A trail level opened new slots: fills each slot that opens at `level` and is still empty with the
## Fellowship's starting seal, the way a milestone auto-slots a kit. Returns whether anything went in.
func apply_seal_milestone(hand: PlayerLoadoutResource, role: int, level: int) -> bool:
	var before: int = maxi(1, level - 1)
	var stage_before: int = compute_progression_stage(before)
	var stage_now: int = compute_progression_stage(level)
	var filled: bool = false
	for slot: int in PlayerLoadoutResource.HAND_SLOT_COUNT:
		if hand.card_in_slot(slot) != &"" or PlayerLoadoutResource.slot_open(slot, stage_before, before) \
				or not PlayerLoadoutResource.slot_open(slot, stage_now, level):
			continue
		var starter: StringName = starting_seal_for_slot(role, slot)
		if starter != &"":
			hand.set_card_in_slot(slot, starter)
			filled = true
	return filled


## The armour weight a role wears (EquipmentTierResource.ArmorWeightClass): tanks heavy, menders light, the rest medium.
static func weight_class_for_role(role: int) -> int:
	match role:
		ClassLoadoutResource.Role.TANK:
			return EquipmentTierResource.ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN
		ClassLoadoutResource.Role.HEALER:
			return EquipmentTierResource.ArmorWeightClass.ARMOR_LIGHT_LANTERN_BEARER
	return EquipmentTierResource.ArmorWeightClass.ARMOR_MEDIUM_WAYFARER


## A fresh dodge roll; the armor sets how far it carries (DodgeState).
func dodge_template() -> CombatActionResource:
	var roll: CombatActionResource = _support(&"dodge_roll", "Dodge Roll", Cmd.DODGE, Fx.DODGE, 0.03, 0.32, 0.22)
	roll.stamina_cost = 20.0
	return roll


## A boss chest's card: a weighted pick from every droppable card, with a rolled
## variant. Starter cards are free in Standard, so they always drop as Shiny or
## Astral copies. Returns the copy key. The host rolls; peers are told the key.
func roll_card_drop(rng: RandomNumberGenerator) -> StringName:
	var total: float = 0.0
	for listed: ScribeCardResource in cards():
		total += listed.drop_weight
	var pick: float = rng.randf() * total
	var chosen: ScribeCardResource = null
	for listed: ScribeCardResource in cards():
		if listed.drop_weight <= 0.0:
			continue
		chosen = listed
		pick -= listed.drop_weight
		if pick <= 0.0:
			break
	var variant: ScribeCardResource.CardVariant = roll_variant(rng)
	if chosen.starter and variant == ScribeCardResource.CardVariant.STANDARD:
		variant = ScribeCardResource.CardVariant.GILDED_LEAF
	return ScribeCardResource.copy_key(chosen.card_id, variant)


## A card of one rarity (the Wayfarer's Chest gives an Uncommon one), evenly
## picked, with a rolled variant. Returns the copy key.
func roll_card_of_rarity(rng: RandomNumberGenerator, rarity: ScribeCardResource.CardRarity) -> StringName:
	var pool: Array[ScribeCardResource] = []
	for listed: ScribeCardResource in cards():
		if listed.is_lead() and listed.rarity == rarity:
			pool.append(listed)
	if pool.is_empty():
		return &""
	var chosen: ScribeCardResource = pool[rng.randi() % pool.size()]
	return ScribeCardResource.copy_key(chosen.card_id, roll_variant(rng))


func roll_variant(rng: RandomNumberGenerator) -> ScribeCardResource.CardVariant:
	var roll: float = rng.randf()
	for variant: int in VARIANT_ODDS.size():
		roll -= VARIANT_ODDS[variant]
		if roll < 0.0:
			return variant as ScribeCardResource.CardVariant
	return ScribeCardResource.CardVariant.STANDARD


# --- Registering ----------------------------------------------------------

func register_sign(seal: ScribeSignResource) -> void:
	_signs[seal.scribe_sign] = seal


func register_item(added: EquipmentItemResource) -> void:
	assert(added.item_id != &"", "ArsenalCatalog: an item needs an id")
	if not _items.has(added.item_id):
		_item_order.append(added.item_id)
	_items[added.item_id] = added


func register_secondary_calling(added: SecondaryCallingResource) -> void:
	if not _secondaries.has(added.calling_id):
		_secondary_order.append(added.calling_id)
	_secondaries[added.calling_id] = added


func register_calling(added: CallingResource) -> void:
	_callings[added.calling_id] = added


func register_combo(added: ComboChainResource) -> void:
	if not _combos.has(added.combo_id):
		_combo_order.append(added.combo_id)
	_combos[added.combo_id] = added


func register_henchman(id: StringName, kind: int) -> void:
	_henchmen[id] = kind


func register_tier(added: EquipmentTierResource) -> void:
	assert(added.tier_id != &"", "ArsenalCatalog: a material tier needs an id")
	if not _tiers.has(added.tier_id):
		_tier_order.append(added.tier_id)
	_tiers[added.tier_id] = added


func register_weapon_archetype(added: WeaponArchetypeResource) -> void:
	assert(added.archetype_id != &"", "ArsenalCatalog: an armament needs an id")
	if not _archetypes.has(added.archetype_id):
		_archetype_order.append(added.archetype_id)
	_archetypes[added.archetype_id] = added


func register_encounter(added: BossEncounterResource) -> void:
	assert(added.encounter_id != &"", "ArsenalCatalog: an encounter needs an id")
	_encounters[added.encounter_id] = added


func register_card(added: ScribeCardResource) -> void:
	if added.card_id == &"" or (added.is_lead() and added.template == null):
		push_warning("ArsenalCatalog: skipped a card with no id or no action")
		return
	if not _cards.has(added.card_id):
		_card_order.append(added.card_id)
	_cards[added.card_id] = added


func _items_in(slot: EquipmentItemResource.ItemSlot) -> Array[EquipmentItemResource]:
	var list: Array[EquipmentItemResource] = []
	for id: StringName in _item_order:
		if _items[id].item_slot == slot:
			list.append(_items[id])
	return list


func _load_card_folder() -> void:
	if not DirAccess.dir_exists_absolute(CARD_FOLDER):
		return
	for file: String in ResourceLoader.list_directory(CARD_FOLDER):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var loaded: ScribeCardResource = load(CARD_FOLDER + file) as ScribeCardResource
			if loaded != null:
				register_card(loaded)


# --- The Four Scribe Signs (06 GDD §2) -----------------------------------

func _build_signs() -> void:
	register_sign(_seal(Sign.NONE, "Plain", "", "", Color(0.9, 0.9, 0.9), ScribeSignResource.Glyph.RING, &""))
	# Iron-Root (amber / ochre): the poise and stagger lever.
	var iron_root: ScribeSignResource = _seal(Sign.SIGN_IRON_ROOT, "Iron-Root", "Sign of Iron-Root", "SHATTERPOINT", Color(0.93, 0.6, 0.22),
		ScribeSignResource.Glyph.GEAR, &"seal_iron_root")
	iron_root.bonus_poise = 45.0
	iron_root.bonus_hit_stop = 1.0
	register_sign(iron_root)
	# Rime-Gale (sea-azure): the elemental burst lever.
	var rime_gale: ScribeSignResource = _seal(Sign.SIGN_RIME_GALE, "Rime-Gale", "Sign of Rime-Gale", "GLACIAL RUPTURE", Color(0.35, 0.72, 0.95),
		ScribeSignResource.Glyph.STAR, &"seal_rime_gale")
	rime_gale.bonus_damage = 45.0
	rime_gale.burst_radius = 4.0
	register_sign(rime_gale)
	# Warm-Hearth (saffron-gold): the mending and shelter lever.
	var warm_hearth: ScribeSignResource = _seal(Sign.SIGN_WARM_HEARTH, "Warm-Hearth", "Sign of Warm-Hearth", "DAWNBURST", Color(1.0, 0.76, 0.28),
		ScribeSignResource.Glyph.SUN, &"seal_warm_hearth")
	warm_hearth.party_heal = 20.0
	register_sign(warm_hearth)
	# Star-Tide (twilight-violet): the tempo and resource lever.
	var star_tide: ScribeSignResource = _seal(Sign.SIGN_STAR_TIDE, "Star-Tide", "Sign of Star-Tide", "ASTRAL CHORUS", Color(0.6, 0.45, 0.95),
		ScribeSignResource.Glyph.MOON, &"seal_star_tide")
	star_tide.party_stamina = 25.0
	star_tide.party_pips = 0.5
	register_sign(star_tide)


func _seal(scribe_sign: Sign, label: String, seal_name: String, detonation: String, color: Color,
		glyph: ScribeSignResource.Glyph, sound: StringName) -> ScribeSignResource:
	var seal: ScribeSignResource = ScribeSignResource.new()
	seal.scribe_sign = scribe_sign
	seal.display_name = label
	seal.seal_name = seal_name
	seal.detonation_name = detonation
	seal.color = color
	seal.glyph = glyph
	seal.sound = sound
	return seal


# --- Armor (05 GDD §2.1) --------------------------------------------------

func _build_armor() -> void:
	var linen: EquipmentItemResource = _armor(HEARTH_LINEN, "Hearth-Linen Coat", EquipmentItemResource.ArmorWeight.LIGHT, 0.10, 27.5, 5.2, 0.20,
		"Light and quick: long rolls and fast stamina for healers and archers.")
	linen.prop_parts = [PropPartResource.make(Part.CYLINDER, Vector3(0.5, 0.14, 0.5), Vector3(0.0, 1.5, 0.0), Color(0.93, 0.88, 0.76))]
	register_item(linen)
	var leather: EquipmentItemResource = _armor(RANGER_LEATHER, "Hedgerow Wool-Mantle", EquipmentItemResource.ArmorWeight.MEDIUM, 0.20, 22.0, 4.6, 0.20,
		"The all-rounder: fair protection, fair footwork.")
	leather.prop_parts = [
		PropPartResource.make(Part.CYLINDER, Vector3(0.49, 0.14, 0.49), Vector3(0.0, 0.95, 0.0), Color(0.42, 0.28, 0.16)),
		PropPartResource.make(Part.BOX, Vector3(0.12, 0.6, 0.06), Vector3(0.2, 1.25, -0.43), Color(0.42, 0.28, 0.16), Vector3(0.0, 0.0, -25.0)),
	]
	register_item(leather)
	var plate: EquipmentItemResource = _armor(IRONWOOD_PLATE, "Iron-Wood Ring-Coat", EquipmentItemResource.ArmorWeight.HEAVY, 0.35, 18.0, 3.8, 0.26,
		"A heavy iron-wood ring-coat for the front line: shrugs off blows, rolls short, and widens the Perfect Guard window.")
	var iron: Color = Color(0.55, 0.57, 0.6)
	plate.prop_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.34, 0.16, 0.42), Vector3(-0.42, 1.45, 0.0), iron, Vector3(0.0, 0.0, 18.0)),
		PropPartResource.make(Part.BOX, Vector3(0.34, 0.16, 0.42), Vector3(0.42, 1.45, 0.0), iron, Vector3(0.0, 0.0, -18.0)),
		PropPartResource.make(Part.BOX, Vector3(0.62, 0.5, 0.1), Vector3(0.0, 1.05, -0.44), iron.darkened(0.15)),
	]
	register_item(plate)
	# The trail's first coat (11 GDD §5.2): woven bramble-fibre over hemp, worn by everyone at Level 1.
	var jerkin: EquipmentItemResource = _armor(BRAMBLE_JERKIN, "Bramble-Spun Jerkin", EquipmentItemResource.ArmorWeight.MEDIUM, 0.15, 24.0, 4.8, 0.22,
		"Woven bramble-fibre over hemp: the trail's first coat. Forgiving footwork for a first expedition.")
	jerkin.prop_parts = [
		PropPartResource.make(Part.CYLINDER, Vector3(0.49, 0.1, 0.49), Vector3(0.0, 0.95, 0.0), Color(0.55, 0.42, 0.24)),
		PropPartResource.make(Part.BOX, Vector3(0.1, 0.55, 0.05), Vector3(-0.18, 1.2, -0.42), Color(0.36, 0.42, 0.22), Vector3(0.0, 0.0, 20.0)),
	]
	register_item(jerkin)


func _armor(id: StringName, label: String, weight: EquipmentItemResource.ArmorWeight, mitigation: float, regen: float,
		roll: float, perfect_guard: float, blurb: String) -> EquipmentItemResource:
	var armor: EquipmentItemResource = EquipmentItemResource.new()
	armor.item_id = id
	armor.display_name = label
	armor.item_slot = EquipmentItemResource.ItemSlot.ARMOR
	armor.armor_weight = weight
	armor.mitigation = mitigation
	armor.stamina_regen_per_sec = regen
	armor.roll_distance = roll
	armor.perfect_guard_window = perfect_guard
	armor.description = blurb
	return armor


# --- Weapons (05 GDD §2.2) ------------------------------------------------

func _build_weapons() -> void:
	var steel: Color = Color(0.85, 0.86, 0.9)
	var wood: Color = Color(0.45, 0.3, 0.18)

	var sword: EquipmentItemResource = _weapon(LIGHT_SWORD, "Falchion", EquipmentItemResource.WeaponType.LIGHT_SWORD,
		EquipmentItemResource.DeliveryVector.MELEE, "A crisp three-cut chain and an advancing thrust. Cards land as Sign-wreathed cuts.")
	var slash_1: CombatActionResource = _strike(&"slash_1", "Slash", Cmd.LIGHT, 0.15, 0.1, 0.3, 10.0, 8.0)
	slash_1.poise_damage = 4.0
	slash_1.resonance_gain = 0.07
	var slash_2: CombatActionResource = _strike(&"slash_2", "Slash II", Cmd.LIGHT, 0.15, 0.1, 0.3, 10.0, 9.0)
	slash_2.poise_damage = 5.0
	slash_2.resonance_gain = 0.07
	var slash_3: CombatActionResource = _strike(&"slash_3", "Slash III", Cmd.LIGHT, 0.15, 0.1, 0.3, 10.0, 12.0)
	slash_3.poise_damage = 10.0
	slash_3.hit_stop_scale = 1.4
	slash_3.resonance_gain = 0.08
	var thrust: CombatActionResource = _strike(&"advancing_thrust", "Advancing Thrust", Cmd.HEAVY, 0.35, 0.15, 0.55, 18.0, 18.0)
	thrust.poise_damage = 15.0
	thrust.lunge_distance = 2.0
	thrust.reach = 2.0
	thrust.hit_stop_scale = 1.6
	thrust.resonance_gain = 0.12
	sword.light_chain = [slash_1, slash_2, slash_3]
	sword.heavy = thrust
	sword.trail_color = Color(0.95, 0.96, 1.0, 0.8)
	sword.trail_base = Vector3(0.5, 1.0, -0.25)
	sword.trail_tip = Vector3(0.5, 1.0, -1.3)
	# A broad, single-edged falchion with a clipped point, a brass guard and pommel.
	var brass: Color = Color(0.86, 0.66, 0.3)
	sword.prop_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.17, 0.86), Vector3(0.48, 1.0, -0.82), steel),
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.13, 0.26), Vector3(0.48, 1.03, -1.31), steel, Vector3(22.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.32, 0.06, 0.07), Vector3(0.48, 1.0, -0.36), brass),
		PropPartResource.make(Part.CYLINDER, Vector3(0.035, 0.22, 0.035), Vector3(0.48, 1.0, -0.24), Color(0.38, 0.24, 0.14), Vector3(90.0, 0.0, 0.0)),
		PropPartResource.make(Part.SPHERE, Vector3(0.05, 0.05, 0.05), Vector3(0.48, 1.0, -0.12), brass),
	]
	register_item(sword)

	var axe: EquipmentItemResource = _weapon(HEAVY_AXE, "Broad-Axe", EquipmentItemResource.WeaponType.HEAVY_AXE,
		EquipmentItemResource.DeliveryVector.MELEE, "Two deliberate, wide cleaves and an earth-splitting heavy. Slow, heavy, honest.")
	var cleave_1: CombatActionResource = _strike(&"cleave_1", "Wide Cleave", Cmd.LIGHT, 0.3, 0.15, 0.4, 16.0, 14.0)
	cleave_1.poise_damage = 10.0
	cleave_1.reach = 1.8
	cleave_1.hit_radius = 1.8
	cleave_1.hit_stop_scale = 1.4
	cleave_1.resonance_gain = 0.09
	var cleave_2: CombatActionResource = _strike(&"cleave_2", "Wide Cleave II", Cmd.LIGHT, 0.3, 0.15, 0.4, 16.0, 17.0)
	cleave_2.poise_damage = 14.0
	cleave_2.reach = 1.8
	cleave_2.hit_radius = 1.8
	cleave_2.hit_stop_scale = 1.5
	cleave_2.resonance_gain = 0.09
	var splitter: CombatActionResource = _strike(&"earth_splitter", "Earth-Splitter", Cmd.HEAVY, 0.55, 0.15, 0.65, 24.0, 28.0)
	splitter.poise_damage = 35.0
	splitter.reach = 2.0
	splitter.hit_radius = 1.6
	splitter.hit_stop_scale = 2.2
	splitter.resonance_gain = 0.12
	axe.light_chain = [cleave_1, cleave_2]
	axe.heavy = splitter
	axe.trail_color = Color(1.0, 0.85, 0.7, 0.8)
	axe.trail_base = Vector3(0.5, 1.05, -0.5)
	axe.trail_tip = Vector3(0.5, 1.15, -1.45)
	# A long oak haft with a leather grip and a wide, bearded broad-axe head.
	var axe_steel: Color = Color(0.58, 0.6, 0.64)
	axe.prop_parts = [
		PropPartResource.make(Part.CYLINDER, Vector3(0.05, 1.6, 0.05), Vector3(0.5, 1.0, -0.6), wood, Vector3(90.0, 0.0, 0.0)),
		PropPartResource.make(Part.CYLINDER, Vector3(0.062, 0.26, 0.062), Vector3(0.5, 1.0, -0.2), Color(0.32, 0.2, 0.12), Vector3(90.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.62, 0.36), Vector3(0.5, 1.14, -1.24), axe_steel),
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.26, 0.2), Vector3(0.5, 0.86, -1.17), axe_steel, Vector3(-20.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.06, 0.12, 0.2), Vector3(0.5, 1.1, -1.48), axe_steel.darkened(0.2)),
	]
	register_item(axe)

	var staff: EquipmentItemResource = _weapon(SCRIBE_STAFF, "Rowan Way-Staff", EquipmentItemResource.WeaponType.STAFF,
		EquipmentItemResource.DeliveryVector.RANGED_BOLT, "Two sweeps and an arcane bolt; a grounded pulse. Cards fly as bolts, sanctuaries grow 25%.")
	var sweep_1: CombatActionResource = _strike(&"sweep_1", "Staff Sweep", Cmd.LIGHT, 0.16, 0.1, 0.4, 7.0, 7.0)
	sweep_1.resonance_gain = 0.06
	var sweep_2: CombatActionResource = _strike(&"sweep_2", "Staff Sweep II", Cmd.LIGHT, 0.16, 0.1, 0.45, 7.0, 7.0)
	sweep_2.resonance_gain = 0.06
	var bolt: CombatActionResource = _shot(&"arcane_bolt", "Arcane Bolt", Cmd.LIGHT, 0.22, 0.08, 0.4, 10.0, 10.0, 12.0, 22.0)
	bolt.resonance_gain = 0.07
	var pulse: CombatActionResource = _strike(&"resonant_pulse", "Resonant Pulse", Cmd.HEAVY, 0.4, 0.15, 0.6, 20.0, 16.0)
	pulse.poise_damage = 8.0
	pulse.reach = 0.0
	pulse.hit_radius = 2.8
	pulse.resonance_gain = 0.1
	staff.light_chain = [sweep_1, sweep_2, bolt]
	staff.heavy = pulse
	staff.card_range = 12.0
	staff.projectile_speed = 22.0
	staff.projectile_radius = 0.38
	staff.support_radius_multiplier = 1.25
	staff.projectile_parts = [PropPartResource.make(Part.SPHERE, Vector3(0.24, 0.24, 0.24), Vector3.ZERO, Color(0.6, 1.0, 0.75), Vector3.ZERO, 3.0)]
	# A rowan way-staff: a reddish forked crook cradling a glowing seed, rowan berries and a ribbon.
	var rowan: Color = Color(0.56, 0.33, 0.2)
	staff.prop_parts = [
		PropPartResource.make(Part.CYLINDER, Vector3(0.045, 1.9, 0.04), Vector3(0.55, 1.0, -0.2), rowan),
		PropPartResource.make(Part.CYLINDER, Vector3(0.03, 0.34, 0.02), Vector3(0.48, 2.06, -0.2), rowan, Vector3(0.0, 0.0, 28.0)),
		PropPartResource.make(Part.CYLINDER, Vector3(0.03, 0.34, 0.02), Vector3(0.62, 2.06, -0.2), rowan, Vector3(0.0, 0.0, -28.0)),
		PropPartResource.make(Part.SPHERE, Vector3(0.13, 0.13, 0.13), Vector3(0.55, 2.04, -0.2), Color(0.6, 1.0, 0.68), Vector3.ZERO, 2.0),
		PropPartResource.make(Part.SPHERE, Vector3(0.045, 0.045, 0.045), Vector3(0.49, 1.82, -0.16), Color(0.85, 0.18, 0.15)),
		PropPartResource.make(Part.SPHERE, Vector3(0.045, 0.045, 0.045), Vector3(0.52, 1.77, -0.24), Color(0.85, 0.18, 0.15)),
		PropPartResource.make(Part.BOX, Vector3(0.02, 0.32, 0.07), Vector3(0.6, 1.72, -0.2), Color(0.95, 0.85, 0.5), Vector3(0.0, 0.0, -10.0)),
	]
	register_item(staff)

	var bow: EquipmentItemResource = _weapon(HUNTER_BOW, "Yew Longbow", EquipmentItemResource.WeaponType.BOW,
		EquipmentItemResource.DeliveryVector.RANGED_ARROW, "Stepping snap-shots and a planted, piercing draw. Cards fly as Sign-arrows.")
	var snap_1: CombatActionResource = _shot(&"snap_shot_1", "Snap-Shot", Cmd.LIGHT, 0.14, 0.08, 0.34, 10.0, 8.0, 14.0, 34.0)
	snap_1.lunge_distance = -0.6
	snap_1.resonance_gain = 0.06
	var snap_2: CombatActionResource = _shot(&"snap_shot_2", "Snap-Shot II", Cmd.LIGHT, 0.14, 0.08, 0.34, 10.0, 9.0, 14.0, 34.0)
	snap_2.lunge_distance = -0.6
	snap_2.resonance_gain = 0.06
	var draw: CombatActionResource = _shot(&"piercing_draw", "Piercing Draw", Cmd.HEAVY, 0.5, 0.1, 0.5, 20.0, 24.0, 18.0, 42.0)
	draw.poise_damage = 20.0
	draw.pierces = true
	draw.hit_stop_scale = 1.8
	draw.resonance_gain = 0.12
	bow.light_chain = [snap_1, snap_2]
	bow.heavy = draw
	bow.card_range = 18.0
	bow.projectile_speed = 38.0
	bow.projectile_radius = 0.3
	bow.projectile_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.07, 0.9), Vector3.ZERO, Color(0.75, 0.6, 0.4), Vector3.ZERO, 0.6),
		PropPartResource.make(Part.BOX, Vector3(0.16, 0.16, 0.16), Vector3(0.0, 0.0, -0.48), Color(0.9, 0.95, 1.0), Vector3(0.0, 45.0, 0.0), 3.0),
		PropPartResource.make(Part.BOX, Vector3(0.2, 0.03, 0.2), Vector3(0.0, 0.0, 0.4), Color(0.95, 0.9, 0.8), Vector3.ZERO, 1.0),
	]
	# A tall yew longbow: golden limbs, a leather grip, brass nocks and a pale string.
	var yew: Color = Color(0.66, 0.48, 0.26)
	bow.prop_parts = [
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.86, 0.07), Vector3(-0.5, 1.53, -0.42), yew, Vector3(-16.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.05, 0.86, 0.07), Vector3(-0.5, 0.77, -0.42), yew, Vector3(16.0, 0.0, 0.0)),
		PropPartResource.make(Part.BOX, Vector3(0.07, 0.2, 0.09), Vector3(-0.5, 1.15, -0.46), Color(0.34, 0.22, 0.13)),
		PropPartResource.make(Part.SPHERE, Vector3(0.035, 0.035, 0.035), Vector3(-0.5, 1.94, -0.3), Color(0.86, 0.66, 0.3)),
		PropPartResource.make(Part.SPHERE, Vector3(0.035, 0.035, 0.035), Vector3(-0.5, 0.36, -0.3), Color(0.86, 0.66, 0.3)),
		PropPartResource.make(Part.CYLINDER, Vector3(0.008, 1.5, 0.008), Vector3(-0.5, 1.15, -0.27), Color(0.95, 0.95, 0.9)),
	]
	register_item(bow)
	# The classics are Bramble-Bridge steel with the base numbers, open from Level 5.
	for classic: EquipmentItemResource in [sword, axe, staff, bow]:
		classic.equipment_tier = EquipmentItemResource.EquipmentTier.TIER_3_STEEL
		classic.required_level = TIER_LEVELS[2]
		classic.blade_albedo = TIER_BLADES[2]
		classic.trim_albedo = TIER_TRIMS[2]
		classic.metallic_factor = TIER_METALLIC[2]
		classic.roughness_factor = TIER_ROUGHNESS[2]
		classic.uninked_r_skill_name = UNINKED_NAMES[classic.weapon_type][0]
		classic.uninked_ult_name = UNINKED_NAMES[classic.weapon_type][1]


# --- The trail's weapons (11 GDD §5.1) --------------------------------------

## Four tiers of each weapon type. Each takes its classic's moves, with damage
## and poise scaled by the tier, and is drawn in the tier's palette: wood with
## hemp cord, dark iron with brass rivets, milled steel with a brass bell-guard,
## and gilded relic bronze with a glowing Sign-stone. Metal blades and trims
## catch a glint band (storybook_cel_light.gdshaderinc).
func _build_tier_weapons() -> void:
	var names: Array[Array] = [
		["Turned-Hazel Falchion", "Split-Ash Broad-Axe", "Reed-Light Way-Staff", "Willow-Coppice Longbow"],
		["Hedgerow Iron Falchion", "Coppice-Forged Broad-Axe", "Copper-Shod Way-Staff", "Horn-Tipped Yew Longbow"],
		["Bramble-Steel Falchion", "Mill-Forged Broad-Axe", "Scribe-Banded Way-Staff", "Weald-Ranger Yew Longbow"],
		["Cairnsman's Span-Blade", "Doverslap Cleaver-Axe", "Arch-Scribe's Carillon Staff", "Gorge-Wind Greatbow"],
	]
	var blurbs: PackedStringArray = [
		"Lathe-turned practice arms bound in hemp cord.",
		"Hammered hedgerow iron on an oak grip, riveted in brass.",
		"Bright milled steel from the Bramble-Bridge forge, with a brass bell-guard.",
		"A Doverslap relic of gilded Carillon bronze and star-etched steel, a Sign-stone glowing in its pommel.",
	]
	for tier_index: int in TIER_WEAPONS.size():
		for weapon_type: int in CLASSIC_WEAPONS.size():
			var classic: EquipmentItemResource = item(CLASSIC_WEAPONS[weapon_type])
			var weapon: EquipmentItemResource = _weapon(TIER_WEAPONS[tier_index][weapon_type], names[tier_index][weapon_type],
				classic.weapon_type, classic.delivery, "%s %s" % [blurbs[tier_index], classic.description])
			_scale_to_tier(weapon, classic, tier_index)
			weapon.prop_parts = _tier_parts(weapon_type, tier_index)
			register_item(weapon)


## Copies the classic's moves and delivery, scaled to a tier, and sets the tier's data.
func _scale_to_tier(weapon: EquipmentItemResource, classic: EquipmentItemResource, tier_index: int) -> void:
	var multiplier: float = TIER_MULTIPLIERS[tier_index]
	weapon.equipment_tier = (tier_index + 1) as EquipmentItemResource.EquipmentTier
	weapon.required_level = TIER_LEVELS[tier_index]
	weapon.damage_multiplier = multiplier
	weapon.blade_albedo = TIER_BLADES[tier_index]
	weapon.trim_albedo = TIER_TRIMS[tier_index]
	weapon.metallic_factor = TIER_METALLIC[tier_index]
	weapon.roughness_factor = TIER_ROUGHNESS[tier_index]
	weapon.uninked_r_skill_name = UNINKED_NAMES[classic.weapon_type][0]
	weapon.uninked_ult_name = UNINKED_NAMES[classic.weapon_type][1]
	var chain: Array[CombatActionResource] = []
	for template: CombatActionResource in classic.light_chain:
		chain.append(_scaled_action(template, multiplier))
	weapon.light_chain = chain
	weapon.heavy = _scaled_action(classic.heavy, multiplier)
	weapon.card_range = classic.card_range
	weapon.projectile_speed = classic.projectile_speed
	weapon.projectile_radius = classic.projectile_radius
	weapon.projectile_parts = classic.projectile_parts
	weapon.support_radius_multiplier = classic.support_radius_multiplier
	weapon.trail_base = classic.trail_base
	weapon.trail_tip = classic.trail_tip
	weapon.trail_color = classic.trail_color.lerp(TIER_BLADES[tier_index].lightened(0.4), 0.5)


static func _scaled_action(template: CombatActionResource, multiplier: float) -> CombatActionResource:
	var action: CombatActionResource = template.duplicate() as CombatActionResource
	action.damage *= multiplier
	action.poise_damage *= multiplier
	return action


## A weapon type's parts in a tier's palette, with the tier's own touches.
func _tier_parts(weapon_type: int, tier_index: int) -> Array[PropPartResource]:
	var blade: Color = TIER_BLADES[tier_index]
	var trim: Color = TIER_TRIMS[tier_index]
	var grip: Color = TIER_GRIPS[tier_index]
	var metal: float = TIER_METALLIC[tier_index]
	var rough: float = TIER_ROUGHNESS[tier_index]
	# Timber trims are hemp cord, not metal; every later tier's trim is.
	var trim_metal: float = 0.0 if tier_index == 0 else maxf(metal, 0.6)
	var wood: Color = Color(0.56, 0.4, 0.26) if tier_index == 0 else Color(0.45, 0.3, 0.18)
	var parts: Array[PropPartResource] = []
	match weapon_type:
		EquipmentItemResource.WeaponType.LIGHT_SWORD:
			var thick: float = 0.07 if tier_index == 0 else 0.05
			parts.append(_metal(Part.BOX, Vector3(thick, 0.17, 0.86), Vector3(0.48, 1.0, -0.82), blade, metal, rough))
			parts.append(_metal(Part.BOX, Vector3(thick, 0.13, 0.26), Vector3(0.48, 1.03, -1.31), blade, metal, rough, Vector3(22.0, 0.0, 0.0)))
			parts.append(_metal(Part.BOX, Vector3(0.32 + 0.04 * tier_index, 0.06, 0.07), Vector3(0.48, 1.0, -0.36), trim, trim_metal, rough))
			parts.append(PropPartResource.make(Part.CYLINDER, Vector3(0.035, 0.22, 0.035), Vector3(0.48, 1.0, -0.24), grip, Vector3(90.0, 0.0, 0.0)))
			_add_tier_touches(parts, tier_index, Vector3(0.48, 1.0, -0.12), Vector3(0.48, 1.0, -0.36), Vector3(0.48, 1.0, -0.82), trim, trim_metal, rough)
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			parts.append(PropPartResource.make(Part.CYLINDER, Vector3(0.05, 1.6, 0.05), Vector3(0.5, 1.0, -0.6), wood, Vector3(90.0, 0.0, 0.0)))
			parts.append(PropPartResource.make(Part.CYLINDER, Vector3(0.062, 0.26, 0.062), Vector3(0.5, 1.0, -0.2), grip, Vector3(90.0, 0.0, 0.0)))
			parts.append(_metal(Part.BOX, Vector3(0.09 if tier_index == 0 else 0.07, 0.62, 0.36), Vector3(0.5, 1.14, -1.24), blade, metal, rough))
			parts.append(_metal(Part.BOX, Vector3(0.07, 0.26, 0.2), Vector3(0.5, 0.86, -1.17), blade, metal, rough, Vector3(-20.0, 0.0, 0.0)))
			parts.append(_metal(Part.BOX, Vector3(0.06, 0.12, 0.2), Vector3(0.5, 1.1, -1.48), trim, trim_metal, rough))
			_add_tier_touches(parts, tier_index, Vector3(0.5, 1.0, -0.06), Vector3(0.5, 1.0, -1.0), Vector3(0.5, 1.14, -1.24), trim, trim_metal, rough)
		EquipmentItemResource.WeaponType.STAFF:
			# The shaft stays wood at every tier; the tier shows in its fittings.
			parts.append(PropPartResource.make(Part.CYLINDER, Vector3(0.045, 1.9, 0.04), Vector3(0.55, 1.0, -0.2), wood))
			parts.append(_metal(Part.CYLINDER, Vector3(0.03, 0.34, 0.02), Vector3(0.48, 2.06, -0.2), blade if tier_index > 0 else wood, metal, rough, Vector3(0.0, 0.0, 28.0)))
			parts.append(_metal(Part.CYLINDER, Vector3(0.03, 0.34, 0.02), Vector3(0.62, 2.06, -0.2), blade if tier_index > 0 else wood, metal, rough, Vector3(0.0, 0.0, -28.0)))
			parts.append(PropPartResource.make(Part.SPHERE, Vector3(0.13, 0.13, 0.13), Vector3(0.55, 2.04, -0.2), Color(0.6, 1.0, 0.68), Vector3.ZERO, 1.0 + tier_index * 0.6))
			parts.append(PropPartResource.make(Part.BOX, Vector3(0.02, 0.32, 0.07), Vector3(0.6, 1.72, -0.2), trim, Vector3(0.0, 0.0, -10.0)))
			parts.append(PropPartResource.make(Part.CYLINDER, Vector3(0.05, 0.12, 0.05), Vector3(0.55, 0.9, -0.2), grip))
			_add_tier_touches(parts, tier_index, Vector3(0.55, 0.08, -0.2), Vector3(0.55, 1.86, -0.2), Vector3(0.55, 2.28, -0.2), trim, trim_metal, rough)
		EquipmentItemResource.WeaponType.BOW:
			var reach: float = 1.0 + 0.06 * tier_index
			parts.append(_metal(Part.BOX, Vector3(0.05, 0.86 * reach, 0.07), Vector3(-0.5, 1.15 + 0.38 * reach, -0.42), blade if tier_index == 3 else wood, metal if tier_index == 3 else 0.0, rough, Vector3(-16.0, 0.0, 0.0)))
			parts.append(_metal(Part.BOX, Vector3(0.05, 0.86 * reach, 0.07), Vector3(-0.5, 1.15 - 0.38 * reach, -0.42), blade if tier_index == 3 else wood, metal if tier_index == 3 else 0.0, rough, Vector3(16.0, 0.0, 0.0)))
			parts.append(PropPartResource.make(Part.BOX, Vector3(0.07, 0.2, 0.09), Vector3(-0.5, 1.15, -0.46), grip))
			# Nocks: hemp-bound timber, then horn, steel and gilded tips.
			var tip: Color = trim if tier_index != 1 else Color(0.85, 0.8, 0.68)
			parts.append(_metal(Part.SPHERE, Vector3(0.035 + 0.008 * tier_index, 0.0, 0.0), Vector3(-0.5, 1.15 + 0.79 * reach, -0.3), tip, trim_metal, rough))
			parts.append(_metal(Part.SPHERE, Vector3(0.035 + 0.008 * tier_index, 0.0, 0.0), Vector3(-0.5, 1.15 - 0.79 * reach, -0.3), tip, trim_metal, rough))
			parts.append(PropPartResource.make(Part.CYLINDER, Vector3(0.008, 1.5 * reach, 0.008), Vector3(-0.5, 1.15, -0.27), Color(0.95, 0.95, 0.9)))
			if tier_index >= 2:
				# Steel-backed limbs, a strip down each.
				for side: float in [1.0, -1.0]:
					parts.append(_metal(Part.BOX, Vector3(0.02, 0.7 * reach, 0.02), Vector3(-0.5, 1.15 + side * 0.38 * reach, -0.47), blade, metal, rough, Vector3(-16.0 * side, 0.0, 0.0)))
			if tier_index == 3:
				parts.append(PropPartResource.make(Part.SPHERE, Vector3(0.05, 0.05, 0.05), Vector3(-0.5, 1.15, -0.52), SIGN_STONE_COLOR, Vector3.ZERO, 2.5))
	return parts


## Each tier's extra touch at the pommel, the guard and the blade: a hemp knot,
## brass rivets, a brass bell-guard, or a glowing Sign-stone with a steel fuller.
func _add_tier_touches(parts: Array[PropPartResource], tier_index: int, pommel: Vector3, guard: Vector3, blade_mid: Vector3,
		trim: Color, trim_metal: float, rough: float) -> void:
	match tier_index:
		0:
			parts.append(PropPartResource.make(Part.SPHERE, Vector3(0.05, 0.0, 0.0), pommel, TIER_TRIMS[0]))
		1:
			parts.append(_metal(Part.SPHERE, Vector3(0.05, 0.0, 0.0), pommel, TIER_BLADES[1], TIER_METALLIC[1], rough))
			for side: float in [-1.0, 1.0]:
				parts.append(_metal(Part.SPHERE, Vector3(0.025, 0.0, 0.0), guard + Vector3(0.04, side * 0.03, side * 0.1), trim, trim_metal, rough))
		2:
			parts.append(_metal(Part.SPHERE, Vector3(0.055, 0.0, 0.0), pommel, trim, trim_metal, rough))
			parts.append(_metal(Part.CYLINDER, Vector3(0.11, 0.04, 0.11), guard, trim, trim_metal, rough, Vector3(90.0, 0.0, 0.0)))
		3:
			parts.append(PropPartResource.make(Part.SPHERE, Vector3(0.065, 0.0, 0.0), pommel, SIGN_STONE_COLOR, Vector3.ZERO, 2.5))
			parts.append(_metal(Part.BOX, Vector3(0.075, 0.03, 0.6), blade_mid, trim, trim_metal, rough))


static func _metal(shape: PropPartResource.Shape, size: Vector3, offset: Vector3, color: Color, metal: float, rough: float,
		rotation: Vector3 = Vector3.ZERO) -> PropPartResource:
	return PropPartResource.make(shape, size, offset, color, rotation).finished(metal, rough)


func _weapon(id: StringName, label: String, type: EquipmentItemResource.WeaponType, delivery: EquipmentItemResource.DeliveryVector,
		blurb: String) -> EquipmentItemResource:
	var weapon: EquipmentItemResource = EquipmentItemResource.new()
	weapon.item_id = id
	weapon.display_name = label
	weapon.item_slot = EquipmentItemResource.ItemSlot.WEAPON
	weapon.weapon_type = type
	weapon.delivery = delivery
	weapon.description = blurb
	return weapon


# --- Lead cards (05 GDD §3.1) ---------------------------------------------

func _build_lead_cards() -> void:
	# Forward + Heavy: gap-closers and offensive primers.
	var charge: CombatActionResource = _strike(SHIELD_CHARGE, "Shield Charge", Cmd.FORWARD_HEAVY, 0.25, 0.25, 0.5, 20.0, 20.0)
	charge.poise_damage = 20.0
	charge.lunge_distance = 5.0
	charge.detonates = true
	charge.hit_stop_scale = 1.5
	charge.resonance_gain = 0.12
	_lead(charge, Slot.FORWARD, Sign.SIGN_IRON_ROOT, "Charge through the gap behind your shield. Detonates seals.")
	var drive: CombatActionResource = _strike(RISING_DRIVE, "Rising Drive", Cmd.FORWARD_HEAVY, 0.24, 0.14, 0.5, 18.0, 16.0)
	drive.poise_damage = 12.0
	drive.lunge_distance = 3.5
	drive.primer = Sign.SIGN_IRON_ROOT
	_lead(drive, Slot.FORWARD, Sign.SIGN_IRON_ROOT, "A rising lunge that stamps the Sign of Iron-Root.")
	var lance: CombatActionResource = _strike(SUNLIT_LANCE, "Sunlit Lance", Cmd.FORWARD_HEAVY, 0.2, 0.1, 0.35, 14.0, 6.0)
	lance.reach = 2.6
	lance.hit_radius = 1.6
	lance.primer = Sign.SIGN_WARM_HEARTH
	_lead(lance, Slot.FORWARD, Sign.SIGN_WARM_HEARTH, "A lance of morning light that stamps the Sign of Warm-Hearth.")

	# Back + Heavy: retreats, sanctuaries and counter primers.
	var shadow: CombatActionResource = _support(SHADOW_SANCTUARY, "Shadow Sanctuary", Cmd.BACK_HEAVY, Fx.SHADOW_SANCTUARY, 0.35, 0.1, 0.5)
	shadow.stamina_cost = 25.0
	shadow.effect_radius = 7.0
	shadow.effect_duration = 6.0
	_lead(shadow, Slot.BACK, Sign.SIGN_STAR_TIDE, "A shield cone behind you: allies inside take 60% less damage.", ScribeCardResource.Delivery.AT_CASTER)
	var crescent: CombatActionResource = _strike(FROST_CRESCENT, "Frost Crescent", Cmd.BACK_HEAVY, 0.28, 0.16, 0.5, 18.0, 14.0)
	crescent.lunge_distance = -1.5
	crescent.reach = 1.4
	crescent.hit_radius = 2.0
	crescent.primer = Sign.SIGN_RIME_GALE
	_lead(crescent, Slot.BACK, Sign.SIGN_RIME_GALE, "Step back through a frost arc that stamps the Sign of Rime-Gale.")
	var ring: CombatActionResource = _support(GREEN_SANCTUARY, "Green Sanctuary", Cmd.BACK_HEAVY, Fx.GREEN_SANCTUARY, 0.3, 0.1, 0.45)
	ring.resonance_cost = 1
	ring.heal_amount = 8.0
	ring.effect_radius = 4.5
	ring.effect_duration = 6.0
	_lead(ring, Slot.BACK, Sign.SIGN_WARM_HEARTH, "A healing ring on the floor (1 pip).", ScribeCardResource.Delivery.AT_CASTER)

	# R: the signature role card.
	var taunt: CombatActionResource = _support(TAUNT, "Taunt", Cmd.TRIGGER_R_SKILL, Fx.TAUNT, 0.2, 0.1, 0.3)
	taunt.resonance_cost = 1
	taunt.effect_duration = 6.0
	_lead(taunt, Slot.SIGNATURE, Sign.SIGN_IRON_ROOT, "Lock the boss onto you for 6 s (1 pip).", ScribeCardResource.Delivery.AT_CASTER)
	var heal: CombatActionResource = _support(HOMING_HEAL, "Homing Heal", Cmd.TRIGGER_R_SKILL, Fx.HOMING_HEAL, 0.12, 0.05, 0.3)
	heal.stamina_cost = 12.0
	heal.heal_amount = 22.0
	var heal_card: ScribeCardResource = _lead(heal, Slot.SIGNATURE, Sign.SIGN_WARM_HEARTH, "A heal that flies down your Soul Tether.", ScribeCardResource.Delivery.AT_CASTER)
	heal_card.needs_soul_tether = true
	var rush: CombatActionResource = _strike(GALE_RUSH, "Gale Rush", Cmd.TRIGGER_R_SKILL, 0.1, 0.2, 0.4, 0.0, 22.0)
	rush.resonance_cost = 1
	rush.lunge_distance = 6.0
	rush.resonance_gain = 0.0
	rush.primer = Sign.SIGN_STAR_TIDE
	_lead(rush, Slot.SIGNATURE, Sign.SIGN_STAR_TIDE, "A moonlit dash that stamps the Sign of Star-Tide (1 pip).")
	# The Wayfarers' first R card on the trail (11 GDD §5.2, Level 3). A trail
	# grant, kept out of chest drops so the drop table stays as it was.
	var lash: CombatActionResource = _strike(RIME_LASH, "Rime-Lash", Cmd.TRIGGER_R_SKILL, 0.2, 0.2, 0.24, 0.0, 20.0)
	lash.resonance_cost = 1
	lash.poise_damage = 10.0
	lash.lunge_distance = 1.5
	lash.reach = 2.2
	lash.hit_radius = 1.6
	lash.resonance_gain = 0.0
	lash.primer = Sign.SIGN_RIME_GALE
	_lead(lash, Slot.SIGNATURE, Sign.SIGN_RIME_GALE, "A whip of frost-wind that stamps the Sign of Rime-Gale (1 pip).").drop_weight = 0.0

	# L + R: the ultimate.
	var quake: CombatActionResource = _strike(BULWARK_QUAKE, "Bulwark Quake", Cmd.TRIGGER_BOTH_ULT, 0.6, 0.2, 0.8, 0.0, 30.0)
	quake.resonance_cost = 3
	quake.poise_damage = 60.0
	quake.reach = 0.0
	quake.hit_radius = 3.5
	quake.detonates = true
	quake.hit_stop_scale = 2.5
	quake.resonance_gain = 0.0
	_lead(quake, Slot.ULTIMATE, Sign.SIGN_IRON_ROOT, "Slam the ground around you; detonates seals (3 pips).", ScribeCardResource.Delivery.AT_CASTER)
	var pull: CombatActionResource = _support(LIFELINE_PULL, "Lifeline Pull", Cmd.TRIGGER_BOTH_ULT, Fx.LIFELINE_PULL, 0.12, 0.08, 0.4)
	pull.resonance_cost = 2
	pull.effect_duration = 0.4
	var pull_card: ScribeCardResource = _lead(pull, Slot.ULTIMATE, Sign.SIGN_WARM_HEARTH, "Yank your tethered ally to safety (2 pips).", ScribeCardResource.Delivery.AT_CASTER)
	pull_card.needs_soul_tether = true
	var tempest: CombatActionResource = _strike(TEMPEST_FLOW, "Tempest Flow", Cmd.TRIGGER_BOTH_ULT, 0.5, 0.3, 0.7, 0.0, 55.0)
	tempest.resonance_cost = 3
	tempest.poise_damage = 25.0
	tempest.reach = 0.5
	tempest.hit_radius = 3.2
	tempest.hit_stop_scale = 2.5
	tempest.resonance_gain = 0.0
	_lead(tempest, Slot.ULTIMATE, Sign.SIGN_RIME_GALE, "A whirling storm of cuts all around you (3 pips).", ScribeCardResource.Delivery.AT_CASTER)

	# Boss drops: collected from the Dojo Warden's chest, not in the starter kit.
	var moonfall: CombatActionResource = _strike(MOONFALL_CLEAVE, "Moonfall Cleave", Cmd.FORWARD_HEAVY, 0.3, 0.15, 0.5, 20.0, 24.0)
	moonfall.poise_damage = 18.0
	moonfall.lunge_distance = 3.0
	moonfall.primer = Sign.SIGN_STAR_TIDE
	moonfall.hit_stop_scale = 1.6
	_boss_drop(_lead(moonfall, Slot.FORWARD, Sign.SIGN_STAR_TIDE, "A falling crescent that stamps the Sign of Star-Tide."), ScribeCardResource.CardRarity.RARE)
	var aegis: CombatActionResource = _support(EMBER_AEGIS, "Bulwark of Embers", Cmd.BACK_HEAVY, Fx.SHADOW_SANCTUARY, 0.3, 0.1, 0.45)
	aegis.stamina_cost = 22.0
	aegis.effect_radius = 8.5
	aegis.effect_duration = 7.0
	_boss_drop(_lead(aegis, Slot.BACK, Sign.SIGN_IRON_ROOT, "A wider, longer shield cone of banked embers.", ScribeCardResource.Delivery.AT_CASTER),
		ScribeCardResource.CardRarity.RARE)
	var volley: CombatActionResource = _strike(STARLIT_VOLLEY, "Starlit Volley", Cmd.TRIGGER_R_SKILL, 0.15, 0.15, 0.4, 0.0, 26.0)
	volley.resonance_cost = 1
	volley.primer = Sign.SIGN_RIME_GALE
	volley.resonance_gain = 0.0
	_boss_drop(_lead(volley, Slot.SIGNATURE, Sign.SIGN_RIME_GALE, "A burst of starlight that stamps the Sign of Rime-Gale (1 pip)."),
		ScribeCardResource.CardRarity.RARE)
	var dawn: CombatActionResource = _strike(DAWNBREAKER, "Dawnbreaker", Cmd.TRIGGER_BOTH_ULT, 0.55, 0.25, 0.75, 0.0, 48.0)
	dawn.resonance_cost = 3
	dawn.poise_damage = 40.0
	dawn.reach = 0.0
	dawn.hit_radius = 4.0
	dawn.detonates = true
	dawn.primer = Sign.SIGN_WARM_HEARTH
	dawn.hit_stop_scale = 2.6
	dawn.resonance_gain = 0.0
	var dawn_card: ScribeCardResource = _lead(dawn, Slot.ULTIMATE, Sign.SIGN_WARM_HEARTH,
		"A sunrise around you: detonates the old seal and stamps the Sign of Warm-Hearth (3 pips).", ScribeCardResource.Delivery.AT_CASTER)
	_boss_drop(dawn_card, ScribeCardResource.CardRarity.LEGENDARY)
	dawn_card.drop_weight = 1.0

	# Expedition finds: Uncommon cards from the Wayfarer's Chest, one per slot
	# (never in the boss's chest).
	var holloway: CombatActionResource = _strike(HOLLOWAY_LUNGE, "Holloway Lunge", Cmd.FORWARD_HEAVY, 0.24, 0.14, 0.5, 18.0, 17.0)
	holloway.poise_damage = 10.0
	holloway.lunge_distance = 3.0
	holloway.primer = Sign.SIGN_RIME_GALE
	_trail_find(_lead(holloway, Slot.FORWARD, Sign.SIGN_RIME_GALE, "A low lunge down the holloway that stamps the Sign of Rime-Gale."))
	var snare: CombatActionResource = _strike(ROOT_SNARE_STEP, "Root-Snare Step", Cmd.BACK_HEAVY, 0.26, 0.16, 0.5, 16.0, 14.0)
	snare.poise_damage = 16.0
	snare.lunge_distance = -1.5
	snare.reach = 1.4
	snare.hit_radius = 2.0
	snare.primer = Sign.SIGN_IRON_ROOT
	_trail_find(_lead(snare, Slot.BACK, Sign.SIGN_IRON_ROOT, "Step back as roots snatch at the foe, stamping the Sign of Iron-Root."))
	var mote: CombatActionResource = _strike(LANTERN_MOTE, "Lantern Mote", Cmd.TRIGGER_R_SKILL, 0.15, 0.12, 0.4, 0.0, 20.0)
	mote.resonance_cost = 1
	mote.reach = 2.4
	mote.hit_radius = 1.8
	mote.resonance_gain = 0.0
	mote.primer = Sign.SIGN_WARM_HEARTH
	_trail_find(_lead(mote, Slot.SIGNATURE, Sign.SIGN_WARM_HEARTH, "A Wind-Lantern's warm mote that stamps the Sign of Warm-Hearth (1 pip)."))
	var gale: CombatActionResource = _strike(GORGE_GALE, "Gorge Gale", Cmd.TRIGGER_BOTH_ULT, 0.5, 0.25, 0.7, 0.0, 42.0)
	gale.resonance_cost = 3
	gale.poise_damage = 35.0
	gale.reach = 0.0
	gale.hit_radius = 3.4
	gale.hit_stop_scale = 2.2
	gale.resonance_gain = 0.0
	gale.primer = Sign.SIGN_STAR_TIDE
	_trail_find(_lead(gale, Slot.ULTIMATE, Sign.SIGN_STAR_TIDE, "Doverslap Falls' gale bursts out around you, stamping the Sign of Star-Tide (3 pips).",
		ScribeCardResource.Delivery.AT_CASTER))


func _lead(template: CombatActionResource, slot: Slot, scribe_sign: Sign, blurb: String,
		delivery: ScribeCardResource.Delivery = ScribeCardResource.Delivery.THROUGH_WEAPON) -> ScribeCardResource:
	var lead: ScribeCardResource = ScribeCardResource.new()
	lead.card_id = template.action_id
	lead.display_name = template.display_name
	lead.description = blurb
	lead.kind = ScribeCardResource.LinkRole.LEAD
	lead.slot = slot
	lead.scribe_sign = scribe_sign
	lead.delivery = delivery
	lead.template = template
	lead.template.scribe_sign = scribe_sign
	lead.rarity = ScribeCardResource.CardRarity.BASIC
	lead.starter = true
	lead.drop_weight = 1.0
	register_card(lead)
	return lead


## An Uncommon card found on the expedition: not a starter, never in the boss's chest.
func _trail_find(lead: ScribeCardResource) -> void:
	lead.rarity = ScribeCardResource.CardRarity.UNCOMMON
	lead.starter = false
	lead.drop_weight = 0.0


func _boss_drop(lead: ScribeCardResource, rarity: ScribeCardResource.CardRarity) -> void:
	lead.rarity = rarity
	lead.starter = false
	lead.drop_weight = 3.0


# --- The 3x3 Callings (06 §3, 07 GDD §1.3) ---------------------------------

## The three Secondary Callings and the nine Callings they make with the
## Fellowships. The names are the Creative Director's (06 §3, chosen
## 2026-11-01); a rename is one line here.
func _build_callings() -> void:
	var stout: SecondaryCallingResource = _secondary(STOUT_HEART, "Stout Heart", "+Defender", Color(0.769, 0.584, 0.251))
	stout.health_bonus = 20.0
	stout.stamina_regen_bonus = -2.0
	stout.poise_damage_multiplier = 1.25
	stout.perfect_guard_bonus = 0.03
	stout.unlocked_armor_weights = [EquipmentItemResource.ArmorWeight.HEAVY]
	var swift: SecondaryCallingResource = _secondary(SWIFT_FOOT, "Swift Foot", "+Striker", Color(0.231, 0.549, 0.322))
	swift.stamina_regen_bonus = 3.0
	swift.strike_damage_multiplier = 1.15
	swift.unlocked_weapon_types = [EquipmentItemResource.WeaponType.BOW, EquipmentItemResource.WeaponType.HEAVY_AXE]
	var wise: SecondaryCallingResource = _secondary(WISE_HAND, "Wise Hand", "+Magic", Color(0.494, 0.322, 0.722))
	wise.health_bonus = -5.0
	wise.stamina_regen_bonus = 2.0
	wise.resonance_gain_multiplier = 1.2
	wise.heal_multiplier = 1.2
	wise.bonus_memory = 1
	wise.unlocked_weapon_types = [EquipmentItemResource.WeaponType.STAFF]
	_calling(&"bridge_warden", "Bridge-Warden", "Keeper of the Stone-Span", ClassLoadouts.SHIELD_TANK, STOUT_HEART)
	_calling(&"weald_captain", "Weald-Captain", "Vanguard of the Green Company", ClassLoadouts.SHIELD_TANK, SWIFT_FOOT)
	_calling(&"hearth_guard", "Hearth-Guard", "Watcher of the Kindled Stone", ClassLoadouts.SHIELD_TANK, WISE_HAND)
	_calling(&"iron_woodsman", "Iron-Woodsman", "Hewn-Hand of the High Pines", ClassLoadouts.DIRECTIONAL_FLOW_DPS, STOUT_HEART)
	_calling(&"hedge_runner", "Hedge-Runner", "Outrider of the Bramble-Ways", ClassLoadouts.DIRECTIONAL_FLOW_DPS, SWIFT_FOOT)
	_calling(&"sign_seeker", "Sign-Seeker", "Journeyman of the Four Ink-Signs", ClassLoadouts.DIRECTIONAL_FLOW_DPS, WISE_HAND)
	_calling(&"bell_keeper", "Bell-Keeper", "Ringer of the Sanctuary Chime", ClassLoadouts.SOUL_TETHER_HEALER, STOUT_HEART)
	_calling(&"wind_mender", "Wind-Mender", "Weather-Worker of the Sound", ClassLoadouts.SOUL_TETHER_HEALER, SWIFT_FOOT)
	_calling(&"lantern_scribe", "Lantern-Scribe", "Bearer of the Reed-Light", ClassLoadouts.SOUL_TETHER_HEALER, WISE_HAND)


func _secondary(id: StringName, label: String, tag: String, trim: Color) -> SecondaryCallingResource:
	var secondary: SecondaryCallingResource = SecondaryCallingResource.new()
	secondary.calling_id = id
	secondary.column = _secondary_order.size()
	secondary.display_name = label
	secondary.tag = tag
	secondary.trim_color = trim
	register_secondary_calling(secondary)
	return secondary


func _calling(id: StringName, label: String, subtitle: String, fellowship_class_id: StringName, secondary_id: StringName) -> void:
	var calling: CallingResource = CallingResource.new()
	calling.calling_id = id
	calling.display_name = label
	calling.subtitle = subtitle
	calling.fellowship_class_id = fellowship_class_id
	calling.secondary_id = secondary_id
	register_calling(calling)


# --- Heroes' looks (19 GDD §5.3, §5.4) ----------------------------------------

## The four weapon tiers' looks, from the trail's tier tables above.
func _build_weapon_visual_tiers() -> void:
	for index: int in TIER_IDS.size():
		var tier: WeaponVisualTierResource = WeaponVisualTierResource.new()
		tier.tier_id = TIER_IDS[index]
		tier.tier_level = index + 1
		tier.display_name = TIER_NAMES[index]
		tier.opens_at_level = TIER_LEVELS[index]
		tier.stat_multiplier = TIER_MULTIPLIERS[index]
		tier.blade_color = TIER_BLADES[index]
		tier.trim_color = TIER_TRIMS[index]
		tier.grip_color = TIER_GRIPS[index]
		tier.metallic = TIER_METALLIC[index]
		tier.roughness = TIER_ROUGHNESS[index]
		tier.sign_core_emission = TIER_SIGN_CORE_EMISSION[index]
		tier.craft_note = TIER_CRAFT_NOTES[index]
		_weapon_tiers.append(tier)


## Each Calling's silhouette (§5.4) and the four heritage dyes. The
## Iron-Woodsman is the flagship: a raised Wayfarer hood, the bark-brown beard
## speckled ash-gray, a heavy Iron-Wood bark pauldron on the bracing left
## shoulder and a stitched-leather cop on the hewing right, iron splitting
## wedges at the belt and a buckler-targe across the back.
func _build_hero_appearances() -> void:
	var pine: Color = Color(0.180, 0.251, 0.169)
	_dye(TIZZI_WED_PINE, "Tizzi-Wed Pine", pine)
	_dye(GULL_WICK_SLATE, "Gull-Wick Slate", Color(0.180, 0.227, 0.282))
	_dye(BARLEY_BRIDGE_RUSSET, "Barley-Bridge Russet", Color(0.290, 0.180, 0.133))
	_dye(BARROW_CRAG_HEATHER, "Barrow-Crag Heather", Color(0.243, 0.180, 0.267))
	# Shield-Sworn: kettle-caps, broad warden pauldrons, braids or a soldier's mustache.
	var warden: HeroAppearanceResource = _look(&"bridge_warden", 0, &"stout_kettle_cap", &"braided_hearth", &"broad_warden_pauldron",
		&"broad_warden_pauldron", &"brass_bridge_key", GULL_WICK_SLATE, Color(0.86, 0.68, 0.56), Color(0.42, 0.30, 0.18))
	warden.headgear_crest = true
	var captain: HeroAppearanceResource = _look(&"weald_captain", 0, &"stout_kettle_cap", &"mustache_sideburns", &"broad_warden_pauldron",
		&"stitched_leather_cop", &"oak_signal_whistle", TIZZI_WED_PINE, Color(0.78, 0.58, 0.45), Color(0.24, 0.17, 0.12))
	captain.headgear_crest = true
	_look(&"hearth_guard", 0, &"stout_kettle_cap", &"braided_hearth", &"broad_warden_pauldron", &"saffron_stole", &"ember_lamp_flask",
		BARLEY_BRIDGE_RUSSET, Color(0.62, 0.44, 0.32), Color(0.16, 0.12, 0.10))
	# Wayfarers: hoods, leather cops, belts of trade-tools.
	var woodsman: HeroAppearanceResource = _look(&"iron_woodsman", 1, &"wayfarer_hood_up", &"woodsman_full_speckled", &"iron_wood_bark_pauldron",
		&"stitched_leather_cop", &"iron_splitting_wedges", TIZZI_WED_PINE, Color(0.86, 0.68, 0.56), Color(0.290, 0.196, 0.133))
	woodsman.appearance_id = &"iron_woodsman_default"
	woodsman.back_buckler_targe = true
	woodsman.split_hewing_apron = true
	_look(&"hedge_runner", 1, &"wayfarer_hood_up", &"clean_youth", &"stitched_leather_cop", &"stitched_leather_cop", &"hedge_snare_coil",
		BARROW_CRAG_HEATHER, Color(0.92, 0.76, 0.64), Color(0.52, 0.34, 0.18))
	_look(&"sign_seeker", 1, &"hood_back_shaved_crown", &"mustache_sideburns", &"stitched_leather_cop", &"none", &"brass_astrolabe",
		GULL_WICK_SLATE, Color(0.70, 0.52, 0.40), Color(0.20, 0.15, 0.12))
	# Lantern-Bearers: feather-hats and saffron stoles.
	_look(&"bell_keeper", 2, &"scribe_feather_hat", &"braided_hearth", &"saffron_stole", &"stitched_leather_cop", &"brass_hand_bell",
		BARLEY_BRIDGE_RUSSET, Color(0.80, 0.60, 0.46), Color(0.58, 0.56, 0.54))
	_look(&"wind_mender", 2, &"scribe_feather_hat", &"clean_youth", &"saffron_stole", &"saffron_stole", &"reed_pipes",
		TIZZI_WED_PINE, Color(0.94, 0.80, 0.68), Color(0.62, 0.42, 0.22))
	_look(&"lantern_scribe", 2, &"scribe_feather_hat", &"mustache_sideburns", &"saffron_stole", &"none", &"quill_case",
		BARROW_CRAG_HEATHER, Color(0.66, 0.48, 0.36), Color(0.30, 0.22, 0.16))
	_build_youth_looks()


## The Level 1 youth (21_WINGFEATHER_YOUTH_HERO.md §2): a 14-year-old in
## homespun, the same for every Fellowship but for the neckerchief and
## stocking stripes (the Fellowship's tunic colour) and the silhouette rim. A
## heather-blue half-cape, russet breeches patched in sage, cream linen, saddle
## braces, a chestnut mop.
func _build_youth_looks() -> void:
	for row: int in 3:
		var look: HeroAppearanceResource = HeroAppearanceResource.new()
		look.body_build = HeroAppearanceResource.BODY_YOUTH
		look.appearance_id = StringName("youth_%s" % ["shield_sworn", "wayfarer", "lantern_bearer"][row])
		look.calling_id = Callings.UNSWORN_ID
		look.display_name = "Unsworn Youth"
		look.heritage_id = &"oakshire_homestead"
		look.coat_dye_preset = YOUTH_HEATHER
		look.value_1_coat_color = Color(0.231, 0.29, 0.4)
		look.value_1_breeches_color = Color(0.478, 0.227, 0.18)
		look.value_1_boot_color = Color(0.29, 0.2, 0.141)
		look.value_2_linen_color = Color(0.863, 0.812, 0.714)
		look.value_2_leather_color = Color(0.627, 0.416, 0.29)
		look.value_2_timber_leather_color = Color(0.612, 0.447, 0.314)
		look.value_2_tunic_color = HeroAppearanceResource.FELLOWSHIP_TUNICS[row]
		look.role_rim_color = HeroAppearanceResource.FELLOWSHIP_RIMS[row]
		look.patch_color = Color(0.494, 0.604, 0.416)
		look.skin_tone_color = Color(0.91, 0.725, 0.588)
		# Chestnut hair (the shader draws hair at 70% of this).
		look.beard_primary_color = Color(0.56, 0.34, 0.19)
		look.iris_color = Color(0.36, 0.42, 0.22)
		look.headgear_style = &"wind_tousled_mop"
		look.beard_style = &"clean_youth"
		look.left_pauldron_style = &"none"
		look.right_pauldron_style = &"none"
		look.belt_trinket_id = &"drawstring_pouch"
		look.back_buckler_targe = false
		look.split_hewing_apron = false
		look.glb_override_path = "res://assets/models/heroes/youth.glb"
		_youths.append(look)


## The Unsworn youth's look for a seat: the Fellowship's youth in the seat's heritage dye on the cape.
func youth_appearance_for_seat(fellowship_class_id: StringName, party_slot: int) -> HeroAppearanceResource:
	var look: HeroAppearanceResource = _youths[clampi(Callings.fellowship_row(fellowship_class_id), 0, _youths.size() - 1)]
	if party_slot <= 0:
		return look
	return look.with_dye(_dyes[HERITAGE_DYES[(party_slot - 1) % HERITAGE_DYES.size()]])


func youth_appearances() -> Array[HeroAppearanceResource]:
	return _youths.duplicate()


func _dye(id: StringName, label: String, wool: Color) -> void:
	var dye: HeroAppearanceResource = HeroAppearanceResource.new()
	dye.appearance_id = id
	dye.calling_id = &""
	dye.display_name = label
	dye.coat_dye_preset = id
	dye.value_1_coat_color = wool
	_dyes[id] = dye


func _look(calling_id: StringName, row: int, headgear: StringName, beard: StringName, left: StringName, right: StringName,
		trinket: StringName, dye: StringName, skin: Color, beard_color: Color) -> HeroAppearanceResource:
	var calling: CallingResource = _callings[calling_id]
	var look: HeroAppearanceResource = HeroAppearanceResource.new()
	look.appearance_id = StringName("%s_default" % calling_id)
	look.calling_id = calling_id
	look.display_name = calling.display_name
	look.heritage_id = &"tizzi_wed_green" if row == 1 else (&"gull_wick_grey" if row == 0 else &"barley_bridge_gold")
	look.coat_dye_preset = dye
	look.value_1_coat_color = _dyes[dye].value_1_coat_color
	look.value_2_tunic_color = HeroAppearanceResource.FELLOWSHIP_TUNICS[row]
	look.role_rim_color = HeroAppearanceResource.FELLOWSHIP_RIMS[row]
	look.headgear_style = headgear
	look.beard_style = beard
	look.left_pauldron_style = left
	look.right_pauldron_style = right
	look.belt_trinket_id = trinket
	look.skin_tone_color = skin
	look.beard_primary_color = beard_color
	look.back_buckler_targe = calling.secondary_id == STOUT_HEART and row != 0
	look.split_hewing_apron = row == 1
	look.glb_override_path = "res://assets/models/heroes/%s.glb" % calling_id
	_appearances[calling_id] = look
	_appearance_order.append(calling_id)
	return look


# --- Under-cards (05 GDD §3.1) --------------------------------------------

func _build_under_cards() -> void:
	_under(IRON_ROOT_LINK, "Iron-Root Link", Sign.SIGN_IRON_ROOT, ScribeCardResource.UnderVerb.POTENCY_SURGE,
		"Potency Surge: +20% damage, healing and poise.")
	_under(RIME_GALE_LINK, "Rime-Gale Link", Sign.SIGN_RIME_GALE, ScribeCardResource.UnderVerb.SIGN_INFUSION,
		"Sign Infusion: the card's hits stamp the Sign of Rime-Gale.")
	_under(WARM_HEARTH_LINK, "Warm-Hearth Link", Sign.SIGN_WARM_HEARTH, ScribeCardResource.UnderVerb.HEARTH_ECHO,
		"Hearth Echo: heals bounce 50% to a friend, sanctuaries restore stamina, hits return stamina.")
	_under(STAR_TIDE_LINK, "Star-Tide Link", Sign.SIGN_STAR_TIDE, ScribeCardResource.UnderVerb.SIGN_INFUSION,
		"Sign Infusion: the card's hits stamp the Sign of Star-Tide.")


func _under(id: StringName, label: String, scribe_sign: Sign, verb: ScribeCardResource.UnderVerb, blurb: String) -> void:
	var under: ScribeCardResource = ScribeCardResource.new()
	under.card_id = id
	under.display_name = label
	under.description = blurb
	under.kind = ScribeCardResource.LinkRole.UNDER
	under.scribe_sign = scribe_sign
	under.verb = verb
	under.rarity = ScribeCardResource.CardRarity.COMMON
	under.starter = true
	register_card(under)


# --- Sign-Flow: Action-Leaves and Place-Cards (14 GDD §4) -------------------

## Every lead card is an Action-Leaf; the tank's and the healer's cards
## manifest as Ward-Mantles and Lantern-Tethers, the rest as Weapon-Coats. Six
## Common leaves the Scribery inscribes give every Sign all three manifestations.
## They are R cards (1 pip), registered last so the desk's older choices keep their order.
func _build_action_leaves() -> void:
	var oak: CombatActionResource = _support(OAK_KNOT_TETHER, "Oak-Knot Tether", Cmd.TRIGGER_R_SKILL, Fx.HOMING_HEAL, 0.12, 0.05, 0.3)
	oak.stamina_cost = 12.0
	oak.heal_amount = 18.0
	_scribery_leaf(_lead(oak, Slot.SIGNATURE, Sign.SIGN_IRON_ROOT, "A heal that runs down your Soul Tether, knotted with oak-strength.",
		ScribeCardResource.Delivery.AT_CASTER)).needs_soul_tether = true
	var bash: CombatActionResource = _strike(RIME_MANTLE_BASH, "Rime-Mantle Bash", Cmd.TRIGGER_R_SKILL, 0.18, 0.18, 0.3, 0.0, 18.0)
	bash.resonance_cost = 1
	bash.poise_damage = 18.0
	bash.lunge_distance = 1.5
	bash.reach = 1.8
	bash.resonance_gain = 0.0
	bash.primer = Sign.SIGN_RIME_GALE
	_scribery_leaf(_lead(bash, Slot.SIGNATURE, Sign.SIGN_RIME_GALE, "A frost-crusted shield bash that stamps the Sign of Rime-Gale (1 pip)."))
	var mist: CombatActionResource = _support(MIST_LANTERN_MEND, "Mist-Lantern Mend", Cmd.TRIGGER_R_SKILL, Fx.HOMING_HEAL, 0.12, 0.05, 0.3)
	mist.stamina_cost = 12.0
	mist.heal_amount = 20.0
	_scribery_leaf(_lead(mist, Slot.SIGNATURE, Sign.SIGN_RIME_GALE, "A cool river-mist heal that drifts down your Soul Tether.",
		ScribeCardResource.Delivery.AT_CASTER)).needs_soul_tether = true
	var ember: CombatActionResource = _strike(EMBER_COAT_CUT, "Ember-Coat Cut", Cmd.TRIGGER_R_SKILL, 0.18, 0.18, 0.28, 0.0, 22.0)
	ember.resonance_cost = 1
	ember.poise_damage = 8.0
	ember.lunge_distance = 1.5
	ember.reach = 2.0
	ember.hit_radius = 1.6
	ember.resonance_gain = 0.0
	ember.primer = Sign.SIGN_WARM_HEARTH
	_scribery_leaf(_lead(ember, Slot.SIGNATURE, Sign.SIGN_WARM_HEARTH, "An ember-glowing cut that stamps the Sign of Warm-Hearth (1 pip)."))
	var brace: CombatActionResource = _strike(HEARTH_MANTLE_BRACE, "Hearth-Mantle Brace", Cmd.TRIGGER_R_SKILL, 0.2, 0.18, 0.3, 0.0, 14.0)
	brace.resonance_cost = 1
	brace.poise_damage = 20.0
	brace.reach = 1.6
	brace.hit_radius = 2.0
	brace.resonance_gain = 0.0
	brace.primer = Sign.SIGN_WARM_HEARTH
	_scribery_leaf(_lead(brace, Slot.SIGNATURE, Sign.SIGN_WARM_HEARTH, "Plant your shield in a ring of hearth-warmth, stamping the Sign of Warm-Hearth (1 pip)."))
	var thread: CombatActionResource = _support(STAR_THREAD_MEND, "Star-Thread Mend", Cmd.TRIGGER_R_SKILL, Fx.HOMING_HEAL, 0.12, 0.05, 0.3)
	thread.stamina_cost = 12.0
	thread.heal_amount = 18.0
	_scribery_leaf(_lead(thread, Slot.SIGNATURE, Sign.SIGN_STAR_TIDE, "A twilight heal that spins down your Soul Tether like a thread of stars.",
		ScribeCardResource.Delivery.AT_CASTER)).needs_soul_tether = true
	for id: StringName in WARD_MANTLE_LEAVES:
		card(id).manifestation_mode = ScribeCardResource.ManifestationMode.WARD_MANTLE
	for id: StringName in LANTERN_TETHER_LEAVES:
		card(id).manifestation_mode = ScribeCardResource.ManifestationMode.LANTERN_TETHER
	# Each role's coat (14 GDD §8): a Tank's Ward-Mantle shrugs off stuns and throws
	# poise back; a Support's leaf shares its ink with the party and wards against stuns.
	for leaf: ScribeCardResource in action_leaves():
		match leaf.role_delivery:
			ScribeCardResource.RoleDelivery.TANK_WARD_MANTLE:
				leaf.grants_stun_immunity = true
			ScribeCardResource.RoleDelivery.SUPPORT_INK_SHARE:
				leaf.shares_ink_to_party = true
				leaf.grants_stun_immunity = true


## A Common leaf the Scribery inscribes: not a starter, never in a chest.
func _scribery_leaf(leaf: ScribeCardResource) -> ScribeCardResource:
	leaf.rarity = ScribeCardResource.CardRarity.COMMON
	leaf.starter = false
	leaf.drop_weight = 0.0
	return leaf


## The four Place-Cards (14 GDD §4.2), charted at the Reed-Light Scribery.
func _build_place_cards() -> void:
	var oaks: ScribeCardResource = _place(ARIUNDLE_MOSS_OAKS, "Moss-Oak Hollow", Sign.SIGN_IRON_ROOT, &"ariundle_trail_chime_post",
		"Root-Bind: mossy oak bark sprouts on the blade; every coated strike lands 15 more poise.")
	oaks.location_bonus_poise = 15.0
	var gorge: ScribeCardResource = _place(DOVERSLAP_GORGE, "Doverslap Bridge", Sign.SIGN_RIME_GALE, &"doverslap_gatehouse",
		"Gorge-Draft: a sweeping river-mist arc reaches 0.8 m further.")
	gorge.location_bonus_reach_m = 0.8
	var mill: ScribeCardResource = _place(BRAMBLEBRIDGE_MILL, "Bramble-Bridge Hearth-Mill", Sign.SIGN_WARM_HEARTH, &"bramblebridge_green",
		"Mill-Warmth: casting pulses a warm ember ring that mends friends within 4 m for 10.")
	mill.location_bonus_heal = 10.0
	var tor: ScribeCardResource = _place(BARROW_CRAG_TOR, "Barrow-Crag-Crossing", Sign.SIGN_STAR_TIDE, &"ring_of_the_cairnsman",
		"Star-Spark: violet starlight on the weapon gives back 8 stamina on every Flow-Link cancel.")
	tor.location_stamina_refund = 8.0


func _place(id: StringName, label: String, scribe_sign: Sign, landmark: StringName, blurb: String) -> ScribeCardResource:
	var place: ScribeCardResource = ScribeCardResource.new()
	place.card_id = id
	place.display_name = label
	place.description = blurb
	place.card_kind = ScribeCardResource.CardKind.LOCATION_PLACE
	place.scribe_sign = scribe_sign
	place.location_landmark_id = landmark
	place.rarity = ScribeCardResource.CardRarity.COMMON
	register_card(place)
	return place


# --- The seven material tiers and four armaments (docs/everwood_equipment_grimoire_architecture.md §2-§3) ---

## Each tier's names, bands, flat numbers and shader recipe, from the Google
## Doc's master table (§2): weapons in archetype order (sword and buckler, maul,
## bow, staff), the offhand each seals (the maul's Pommel-Knot, 25 GDD R6),
## armour by weight, Armor Guard by weight, and the recipe. Tier 7's light
## mantle reads "Star-Ink Great-Mantle" (Gate 6 retired "Vellum"), and its
## shield the Heart-Crag Bulwark (the Creative Director's ruling for "Aegis").
func _build_material_tiers() -> void:
	_register_tier(TIER_1_HOMESTEAD, 1, "Orchard-Wood", "Oak-Bark & Boiled-Hide", "Bracken-Pelt Jerkin", "Mended-Linen Smock",
		&"ISLAND_OAKSHIRE_HOLM", "Miller's Oak (homestead chests)", 1, 4, 1, 7, 0, 2.4, 3.5, 1.00, 14.0, [0.08, 0.05, 0.03], 0,
		["Orchard-Wood Stick & Bark-Buckler", "Cooper's Split-Rail Mallet", "Bent-Twig Bow & Reed-Shafts", "Rowan Walking-Stick & Tallow-Jar"],
		["Bark-Buckler", "Oak-Knot Pommel", "Reed-Shaft Quiver", "Tallow-Jar"],
		Color("#7A5438"), 0.00, 0.88, 0.18, Color("#D2B48C"), 1.40, 0.00)
	_register_tier(TIER_2_BOG_BRONZE, 2, "Bog-Bronze", "Kettle-Link Coat", "Boiled-Buckskin Coat", "Orchard-Wool Mantle",
		&"ISLAND_BARROW_EYOT", "the Miller's Oak Barrows and the Hearthstead stall", 5, 7, 8, 13, 3, 5.5, 8.0, 1.20, 20.0, [0.16, 0.12, 0.08], 25,
		["Bog-Bronze Short-Blade & Bossed-Buckler", "Peat-Cutter's Bronze Broad-Axe", "Ash-Bough Bow & Goose-Fletch", "Hazel-Crook & Brass-Lantern"],
		["Bossed-Buckler", "Bog-Bronze Pommel-Knot", "Goose-Fletch Quiver", "Brass-Lantern"],
		Color("#9E6B3B"), 0.72, 0.46, 0.25, Color("#F4A460"), 1.15, 0.00)
	_register_tier(TIER_3_FORGE_IRON, 3, "Forge-Iron", "Forge-Plate Harness", "Briar-Studded Brigandine", "Nettle-Weave Mantle",
		&"ISLAND_IRON_NESS", "Iron-Ness (Cinder-Hollow smelters)", 8, 10, 14, 19, 6, 9.5, 13.8, 1.45, 28.0, [0.24, 0.18, 0.13], 65,
		["Forge-Iron Broad-Sword & Rim-Shield", "Iron-Ness Felling Greataxe", "Yew-Stave Longbow & Bodkin-Quiver", "Iron-Shod Staff & Beacon-Glass"],
		["Rim-Shield", "Forge-Iron Pommel-Knot", "Bodkin-Quiver", "Beacon-Glass"],
		Color("#5E666E"), 0.85, 0.38, 0.30, Color("#B0C4DE"), 1.00, 0.00)
	_register_tier(TIER_4_BARROW_STEEL, 4, "Barrow-Steel", "Barrow-Mail & Pauldrons", "Firth-Seal Coat", "Moth-Silk Mantle",
		&"ISLAND_BARROW_EYOT", "Barrow-Eyot (standing-stone vaults)", 11, 13, 20, 25, 10, 14.5, 21.0, 1.75, 36.0, [0.32, 0.24, 0.18], 120,
		["Barrow-Steel Long-Blade & Heater-Shield", "Cairn-Cleaver Greataxe", "Horn-Backed Recurve & Broad-Head", "Cairn-Ash Staff & Hearth-Vessel"],
		["Heater-Shield", "Barrow-Steel Pommel-Knot", "Broad-Head Quiver", "Hearth-Vessel"],
		Color("#8A99AD"), 0.90, 0.28, 0.38, Color("#C9D6E3"), 0.85, 0.04)
	_register_tier(TIER_5_RIME_SILVER, 5, "Rime-Silver", "Rime-Clad Plate", "Frost-Stag Pelt-Coat", "Gossamer-Spun Mantle",
		&"ISLAND_RIME_FIRTH", "Rime-Firth (Gale-Haven looms)", 14, 16, 26, 31, 13, 20.5, 29.7, 2.10, 46.0, [0.40, 0.30, 0.23], 190,
		["Rime-Silver Knight-Blade & Kite-Buckler", "Firth-Frost Bearded Greataxe", "Frost-Whale Baleen Bow", "Silver-Bough Crook & Rime-Lantern"],
		["Kite-Buckler", "Rime-Silver Pommel-Knot", "Frost-Fletch Quiver", "Rime-Lantern"],
		Color("#C9E2F2"), 0.94, 0.20, 0.52, Color("#E0FFFF"), 0.70, 0.08)
	_register_tier(TIER_6_SAFFRON_GOLD, 6, "Saffron-Gold", "Cairn-Scale Great-Plate", "Wyrm-Hide Coat", "Sun-Loomed Mantle",
		&"ISLAND_THE_CROWN", "The Crown (Sun-Crossing guilds)", 17, 19, 32, 37, 16, 27.5, 39.9, 2.50, 58.0, [0.46, 0.35, 0.27], 280,
		["Saffron-Gold Sun-Blade & Crest-Shield", "Gilded-Crag Great-Halberd", "Golden-Yew Greatbow", "Saffron-Gilded Staff & Sun-Censer"],
		["Crest-Shield", "Saffron-Gold Pommel-Knot", "Golden-Fletch Quiver", "Sun-Censer"],
		Color("#E5B546"), 0.96, 0.16, 0.65, Color("#FFFACD"), 0.65, 0.15)
	_register_tier(TIER_7_STAR_GLASS, 7, "Star-Glass & Heart-Crag", "Heart-Crag & Ember-Clad Plate", "Gale-Drake Scale-Coat", "Star-Ink Great-Mantle",
		&"ISLAND_OLD_QUAY_EBB", "the Old Quay Market (Ebb-Tide raid artificers)", 20, 20, 38, 40, 20, 36.0, 52.2, 3.00, 72.0, [0.52, 0.40, 0.32], 400,
		["Star-Glass Steward-Blade & Heart-Crag Bulwark", "World-Root Sundering Greataxe", "Star-Chord Wind-Bow", "First-Tree Bough & Star-Tide Lantern"],
		["Heart-Crag Bulwark", "Heart-Crag Pommel-Stone", "Star-Chord Quiver", "Star-Tide Lantern"],
		Color("#3D355E"), 0.98, 0.12, 0.85, Color("#9370DB"), 0.50, 0.55)


func _register_tier(t_id: StringName, idx: int, w_name: String, h_name: String, m_name: String, l_name: String,
		island: StringName, source: String, min_lv: int, max_lv: int, min_threat: int, max_threat: int, rank: int,
		l_dmg: float, h_dmg: float, posture_mult: float, p_dmg: float, guard: Array, hp_bonus: int,
		weapons: Array, offhands: Array,
		albedo: Color, metal: float, rough: float, rim_s: float, rim_c: Color, normal: float, emissive: float) -> void:
	var tier: EquipmentTierResource = EquipmentTierResource.new()
	tier.tier_id = t_id
	tier.tier_index = idx
	tier.weapon_material_name = w_name
	tier.heavy_armor_name = h_name
	tier.medium_armor_name = m_name
	tier.light_armor_name = l_name
	tier.unlock_island_id = island
	tier.unlock_source = source
	tier.min_true_level = min_lv
	tier.max_true_level = max_lv
	tier.min_renown_rank = min_threat
	tier.max_renown_rank = max_threat
	tier.gear_threat_rank = rank
	tier.base_light_damage = l_dmg
	tier.base_heavy_damage = h_dmg
	tier.posture_multiplier = posture_mult
	tier.base_posture_damage = p_dmg
	tier.armor_guard = PackedFloat32Array(guard)
	tier.base_damage_mitigation = float(guard[1])
	tier.bonus_max_hp = hp_bonus
	tier.weapon_names = PackedStringArray(weapons)
	tier.offhand_names = PackedStringArray(offhands)
	tier.albedo_tint = albedo
	tier.metallic = metal
	tier.roughness = rough
	tier.rim_strength = rim_s
	tier.rim_tint = rim_c
	tier.normal_scale = normal
	tier.emissive_pulse_strength = emissive
	register_tier(tier)


## The four base armaments and their Tier 1 homestead arms (§2.2).
func _build_weapon_archetypes() -> void:
	const Arch = EquipmentTierResource.WeaponArchetype
	const Weight = EquipmentTierResource.ArmorWeightClass
	_archetype(WEAPON_SWORD_BOARD, Arch.WEAPON_SWORD_BOARD, EquipmentItemResource.WeaponType.LIGHT_SWORD, Weight.ARMOR_HEAVY_SHIELD_SWORN,
		"Shield-Sworn", "Orchard-Stick & Bark-Buckler", "Blade & Buckler", "Light", "Heavy",
		"A bark-stripped applewood stick paired with a thick slab of knotted oak-bark bound with twine.",
		"Teaches blocking, PARRY & STRIKE timing as a boulder-beast roars its challenge, and protecting siblings.")
	_archetype(WEAPON_GREAT_MALLET, Arch.WEAPON_GREAT_MALLET, EquipmentItemResource.WeaponType.HEAVY_AXE, Weight.ARMOR_MEDIUM_WAYFARER,
		"Wayfarer Melee", "Cooper's Cider-Mallet", "Great-Mallet", "Light", "Heavy",
		"An oversized two-handed wooden barrel-mallet with a hickory handle and twine-wrapped head.",
		"Teaches heavy posture-stagger swings and Forward + Heavy gap-closers against stone hides.")
	_archetype(WEAPON_BOUGH_BOW, Arch.WEAPON_BOUGH_BOW, EquipmentItemResource.WeaponType.BOW, Weight.ARMOR_MEDIUM_WAYFARER,
		"Wayfarer Ranged", "Bent-Twig Bough & Reed-Shafts", "Bough-Bow", "Quick", "Drawn",
		"A supple yew-bough strung with waxed linen twine, firing whittled river-reed arrows.",
		"Teaches spacing, the Glowing Spot's target lock, and safe off-angle posture chipping.")
	_archetype(WEAPON_LANTERN_STAFF, Arch.WEAPON_LANTERN_STAFF, EquipmentItemResource.WeaponType.STAFF, Weight.ARMOR_LIGHT_LANTERN_BEARER,
		"Lantern-Bearer", "Rowan-Crook & Tallow-Jar", "Lantern-Crook", "Light", "Mend",
		"A crooked rowan walking-stick with a warm firefly-and-tallow glass jar swinging from its notch.",
		"Teaches keeping the Warm-Hearth tether alive and soothing restless creatures back to their lulled cairns.")


func _archetype(id: StringName, archetype: EquipmentTierResource.WeaponArchetype, weapon_type: EquipmentItemResource.WeaponType,
		weight: EquipmentTierResource.ArmorWeightClass, calling_label: String, homestead: String, frame: String, light: String, heavy: String,
		blurb: String, goal: String) -> void:
	var added: WeaponArchetypeResource = WeaponArchetypeResource.new()
	added.archetype_id = id
	added.archetype = archetype
	added.weapon_type = weapon_type
	added.armor_weight_class = weight
	added.calling_label = calling_label
	added.homestead_name = homestead
	added.frame_noun = frame
	added.light_label = light
	added.heavy_label = heavy
	added.homestead_blurb = blurb
	added.teaching_goal = goal
	register_weapon_archetype(added)


# --- The seal cards (docs/everwood_equipment_grimoire_architecture.md §4, §6.4) -------------------

## Four seals, one a Sign (the Google Doc §3): each may be pressed on any of the
## three pieces and does a different job on each (the Contextual Slot Rule,
## slot_passives). Never in a chest: the Reed-Light Scribery sells them
## (SEAL_CHIME_COST) and the Seal Press presses them. Ids keep the Seal-and-Tuck
## branch's spellings. Numbers the doc gives are kept; where it names a feel the
## code has no lever for yet (attack speed, a Bramble-Slow patch, a pulse), the
## nearest lever stands in and the text says what the doc means [tuning TBD].
func _build_seal_cards() -> void:
	const Foil = ScribeCardResource.FoilGrade
	const W = ScribeCardResource.SealSlotMask.SEAL_WEAPON
	const O = ScribeCardResource.SealSlotMask.SEAL_OFFHAND_BUCKLER
	const M = ScribeCardResource.SealSlotMask.SEAL_MANTLE_ARMOR
	var bell: ScribeCardResource = _seal_card(CARD_QUIET_WEIR, "Ebb-Quay Star-Bell", Sign.SIGN_STAR_TIDE, Foil.FOIL_PLAIN_VELLUM, &"SCRIPT_STAR_WARD",
		Color("#5C4AE4"), Color("#B388EB"), 0.30, true, 0, 1.10, 1.0,
		ScribeCardResource.MODE_WARD_MANTLE, 1, &"ACTION_SHIELD_CHARGE_RELEASE", 1.45, 45.0, &"TUCK_STAR_NOVA_PULSE",
		"A Star-Tide bell-seal: it wards Star-Tide on the offhand and the mantle, and rings stagger on the blade.")
	bell.slot_passives = {
		W: {"ward": 0.0, "stun": false, "posture": 1.10, "text": "Strikes carry Star-Tide; every 4th hit chimes for bonus stagger."},
		O: {"ward": 0.30, "stun": true, "text": "Guarding cuts Star-Tide beams 30% and stops stun. Censer: 20% longer tether."},
		M: {"ward": 0.20, "stun": true, "text": "-20% from Star-Tide waves. No Deep-Hush silence."},
	}
	var ember: ScribeCardResource = _seal_card(CARD_EMBER_BOUGH, "Cider-Hearth Ember", Sign.SIGN_WARM_HEARTH, Foil.FOIL_PLAIN_VELLUM, &"SCRIPT_HEARTH_VOW",
		Color("#F26419"), Color("#F6AE2D"), 0.20, true, 4, 1.18, 1.0,
		ScribeCardResource.MODE_WEAPON_COAT, 1, &"ACTION_FLAME_BLADE_COAT", 1.55, 50.0, &"TUCK_EMBER_FLARE_TRAIL",
		"A Warm-Hearth ember-seal: Ember-Burn on the blade, a hearth pulse on the offhand, a ward on the mantle.")
	ember.slot_passives = {
		W: {"ward": 0.0, "stun": false, "flat": 4, "posture": 1.18, "text": "Your swings catch Warm-Hearth ink: a stacking Ember-Burn, 18% more stagger wear."},
		O: {"ward": 0.10, "stun": false, "text": "Buckler: PARRY & STRIKE! lets out a 3 m Warm-Hearth pulse. Censer: your tethered friend gets 12% more healing."},
		M: {"ward": 0.20, "stun": true, "text": "-20% from Warm-Hearth cinders. Heal 1.5% a second near braziers."},
	}
	var root_bind: ScribeCardResource = _seal_card(CARD_OLD_ROOT_BASTION, "Old-Hob's Root-Bind", Sign.SIGN_IRON_ROOT, Foil.FOIL_PLAIN_VELLUM, &"SCRIPT_ROOT_BIND",
		Color("#D9822B"), Color("#3B7A57"), 0.20, true, 0, 1.25, 1.0,
		ScribeCardResource.MODE_WARD_MANTLE, 1, &"ACTION_ROOT_ANCHOR_SLAM", 1.40, 55.0, &"TUCK_ROOT_QUAKE_BIND",
		"An Iron-Root bind-seal: stagger on the blade, a rooted guard on the offhand, a ward on the mantle.")
	root_bind.slot_passives = {
		W: {"ward": 0.0, "stun": false, "posture": 1.25, "text": "+25% Iron-Root stagger. Heavy finishers leave a 3 s Bramble-Slow patch."},
		O: {"ward": 0.10, "stun": true, "text": "Guarding soaks the knockback and roots attackers for 1.5 s. Quiver or censer: heavy shots pin flying Mites."},
		M: {"ward": 0.20, "stun": true, "text": "-20% from Iron-Root blows. No Crag-Stagger."},
	}
	var feather: ScribeCardResource = _seal_card(CARD_WEST_WIND_PROMISE, "Firth-Squall Feather", Sign.SIGN_RIME_GALE, Foil.FOIL_PLAIN_VELLUM, &"SCRIPT_GALE_STRIDE",
		Color("#4BC4E5"), Color("#E2F3F8"), 0.20, true, 2, 1.0, 1.0,
		ScribeCardResource.MODE_LANTERN_TETHER, 1, &"ACTION_GALE_TETHER_HASTE", 1.35, 40.0, &"TUCK_GALE_STRIDE_ECHO",
		"A Rime-Gale feather-seal: speed on the blade, a longer step on the offhand, a ward on the mantle.")
	feather.slot_passives = {
		W: {"ward": 0.0, "stun": false, "flat": 2, "text": "+15% speed on Light chains, and Rime-Gale stagger."},
		O: {"ward": 0.0, "stun": false, "stride": 1.15, "text": "Buckler: Shield-Step goes 35% further. Quiver or censer: shots pierce one more."},
		M: {"ward": 0.20, "stun": true, "text": "-20% from Rime-Gale squalls. No Frost-Slow on ice."},
	}


func _seal_card(id: StringName, label: String, scribe_sign: Sign, foil: ScribeCardResource.FoilGrade, script: StringName,
		ink: Color, ink_edge: Color, ward: float, stun_immune: bool, flat: int, posture_mult: float, stride_mult: float,
		mode: int, pips: int, action: StringName, dmg_mult: float, posture_bonus: float, tuck: StringName, blurb: String) -> ScribeCardResource:
	var seal: ScribeCardResource = ScribeCardResource.new()
	seal.card_id = id
	seal.display_name = label
	seal.description = blurb
	seal.kind = ScribeCardResource.LinkRole.LEAD
	seal.card_kind = ScribeCardResource.CardKind.EQUIPMENT_SEAL
	seal.scribe_sign = scribe_sign
	seal.rarity = ScribeCardResource.CardRarity.COMMON
	seal.starter = false
	seal.drop_weight = 0.0
	seal.foil_grade = foil
	seal.allowed_seal_slots = ScribeCardResource.SealSlotMask.SEAL_ANY_EQUIPMENT
	seal.deep_ink_script_id = script
	seal.ink_primary_color = ink
	seal.ink_secondary_color = ink_edge
	seal.passive_ward_sign = ScribeSignResource.id_of(scribe_sign)
	seal.passive_ward_mitigation = ward
	seal.grants_sign_stun_immunity = stun_immune
	seal.passive_flat_damage_bonus = flat
	seal.passive_posture_break_mult = posture_mult
	seal.passive_move_speed_mult = stride_mult
	seal.manifestation_mode = mode as ScribeCardResource.ManifestationMode
	seal.resonance_pip_cost = pips
	seal.active_action_id = action
	seal.active_damage_mult = dmg_mult
	seal.active_posture_damage_bonus = posture_bonus
	seal.active_buff_duration_sec = 8.0
	seal.under_card_tuck_synergy_id = tuck
	seal.chime_cost = SEAL_CHIME_COST
	register_card(seal)
	return seal


# --- Encounters: Miyamoto tiers, locks and Glimmer-Spots (14 GDD §3, §8) ------------

## Every foe's encounter. Tier 0 kin are always open to Iron-Root; Tier 1 kin
## leap back and lock at 75%, Tier 2 at every gate; the bosses open a
## Glimmer-Spot during their pattern, tightening from the base window to the
## floor as the family sees it (12 frames a sighting, five sightings), across
## their four gates.
func _build_encounters() -> void:
	_encounter(ROADSIDE_KIN, "Roadside Pebbles & Minor Kin", Tier.TIER_0_PUNCHING_BAG, 1, [Sign.SIGN_IRON_ROOT], 0, 0, "", "")
	_encounter(SCREE_WORM, "Scree-Worm", Tier.TIER_0_PUNCHING_BAG, 2, [Sign.SIGN_IRON_ROOT], 0, 0, "", "")
	# Tier 1: the starting zone's locked kin, one lock each at 75%.
	_locked(_encounter(FROST_FANG_KIN, "Frost-Fang Padfoot", Tier.TIER_1_SINGLE_EVADE, 3, [], 0, 0, "", "pounce"), Key.MARTIAL_COMBO_KEY)
	_locked(_encounter(IRON_MAN_KIN, "Furrow Iron-Man", Tier.TIER_1_SINGLE_EVADE, 3, [Sign.SIGN_WARM_HEARTH], 0, 0, "", "plough-stamp"),
		Key.ELEMENTAL_INK_KEY)
	_locked(_encounter(BRAMBLE_HOB_KIN, "Bramble-Hob", Tier.TIER_1_SINGLE_EVADE, 4, [], 0, 0, "", "lash"), Key.MARTIAL_COMBO_KEY)
	_locked(_encounter(SPRIGGAN_KIN, "Crag-Spriggan", Tier.TIER_1_SINGLE_EVADE, 5, [Sign.SIGN_IRON_ROOT], 0, 0, "", "shield-brace"),
		Key.ELEMENTAL_INK_KEY)
	# Tier 2: the roaming Crag-Back locks at each gate, a new key every time.
	var drake: BossEncounterResource = _locked(_encounter(CRAG_BACK_DRAKE, "The Crag-Back Cairn-Drake", Tier.TIER_2_MULTI_LOCK, 6,
		[Sign.SIGN_WARM_HEARTH], 0, 0, "", "coil"), Key.MARTIAL_COMBO_KEY)
	drake.gate_weakness_signs = [Sign.NONE, Sign.NONE, Sign.SIGN_WARM_HEARTH, Sign.SIGN_IRON_ROOT]
	_locked(_encounter(SHINGLE_SCRAY, "Shingle-Scray", Tier.TIER_2_MULTI_LOCK, 7, [Sign.SIGN_RIME_GALE], 210, 150, "", "dive"),
		Key.ELEMENTAL_INK_KEY)
	# Tier 3: the milestone bosses' four gates.
	var cairnsman: BossEncounterResource = _encounter(CAIRNSMAN, "The Cairnsman of Doverslap Falls", Tier.TIER_3_FOUR_GATE_BOSS, 5,
		[Sign.SIGN_IRON_ROOT, Sign.SIGN_STAR_TIDE], 180, 120,
		"When the cairn-core glows and the old stones roar,\nring Iron-Root or Star-Tide and he'll stand no more!", "roar")
	# Gate 2's core answers Star-Tide, the Tempest's Warm-Hearth, and the Seal-Turn Iron-Root.
	cairnsman.gate_weakness_signs = [Sign.NONE, Sign.SIGN_STAR_TIDE, Sign.SIGN_WARM_HEARTH, Sign.SIGN_IRON_ROOT]
	cairnsman.gate_2_henchman_id = HENCHMAN_BRAMBLE_HOB
	_encounter(GALE_BUCCA, "The Gale-Bucca", Tier.TIER_3_FOUR_GATE_BOSS, 10, [Sign.SIGN_STAR_TIDE], 180, 120,
		"When the Bucca spreads wide its storm-feathered wings,\nsing Star-Tide inside where the wild weather sings!", "wing-spread")
	_encounter(FURROW_IRON_MAN, "The Furrow Iron-Man", Tier.TIER_3_FOUR_GATE_BOSS, 15,
		[Sign.SIGN_WARM_HEARTH, Sign.SIGN_IRON_ROOT], 120, 75,
		"Warm the rust with Hearth-light, then turn him round with Root:\nthe ploughman's iron giant will stand down at your boot!", "plough-stamp")
	_encounter(CAIRN_DRAKE, "The Cairn-Drake", Tier.TIER_3_FOUR_GATE_BOSS, 25,
		[Sign.SIGN_WARM_HEARTH, Sign.SIGN_IRON_ROOT], 120, 75,
		"When the drake curls tight round its hoard of grey stone,\nsing Hearth to the heart and it sleeps on its own.", "coil")
	_encounter(TOR_SLEEPER, "The Tor-Sleeper", Tier.TIER_3_FOUR_GATE_BOSS, 50,
		[Sign.SIGN_IRON_ROOT, Sign.SIGN_RIME_GALE, Sign.SIGN_WARM_HEARTH, Sign.SIGN_STAR_TIDE], 75, 45,
		"Mantle, then tether, then strike with your Sign:\nthe Tor-Sleeper wakes when the three fall in line.", "yawn")
	_encounter(OLD_HOB, "Old-Hob-of-the-Hill", Tier.TIER_3_FOUR_GATE_BOSS, 60,
		[Sign.SIGN_IRON_ROOT, Sign.SIGN_RIME_GALE, Sign.SIGN_WARM_HEARTH, Sign.SIGN_STAR_TIDE], 75, 45,
		"Old-Hob hums low on his hill of moss:\nmantle, tether and Sign, or the whole trail is lost.", "hum")
	# The Seal-and-Tuck Grimoire's apex (docs/everwood_equipment_grimoire_architecture.md §5.1):
	# True Level 20, so its threat plate reads Rank 40; a buckler sealed with Star-Tide shrugs its roars off.
	var elder: BossEncounterResource = _encounter(ELDER_CAIRN_DRAKE, "The Elder Cairn-Drake", Tier.TIER_3_FOUR_GATE_BOSS, MAX_TRUE_LEVEL,
		[Sign.SIGN_STAR_TIDE, Sign.SIGN_IRON_ROOT], 120, 75,
		"When the Elder Drake rears where the ebb-tide runs low,\nseal Star-Tide on your buckler and break him with Root!", "roar")
	elder.gate_weakness_signs = [Sign.NONE, Sign.SIGN_STAR_TIDE, Sign.SIGN_RIME_GALE, Sign.SIGN_IRON_ROOT]
	elder.gate_2_henchman_id = HENCHMAN_SCREE_WORM


func _encounter(id: StringName, label: String, tier: BossEncounterResource.MiyamotoTier, level: int, counters: Array[int],
		base_frames: int, floor_frames: int, couplet: String, pattern: String) -> BossEncounterResource:
	var added: BossEncounterResource = BossEncounterResource.new()
	added.encounter_id = id
	added.display_name = label
	added.miyamoto_tier = tier
	added.encounter_level = level
	added.weakness_counter_signs = counters
	added.base_glimmer_window_frames = base_frames
	added.floor_glimmer_window_frames = floor_frames
	added.hud_rhyme_couplet = couplet
	added.opening_pattern = pattern
	register_encounter(added)
	return added


func _locked(added: BossEncounterResource, key: BossEncounterResource.LockKeyType) -> BossEncounterResource:
	added.primary_lock_type = key
	return added


# --- Combo forms (14 GDD §8) ---------------------------------------------------

## The five directional combo forms, one every few trail levels (Lv 1, 2, 4, 6
## and 8), built from the postures every hero already has.
func _build_combos() -> void:
	var three: ComboChainResource = _combo(COMBO_APPRENTICE_THREE_BEAT, "Apprentice's Three-Beat", [ComboChainResource.LIGHT, ComboChainResource.LIGHT, ComboChainResource.HEAVY], 1,
		"Two quick cuts and a heavy one: the finisher steps in 1.2 m for 1.5x damage and 15 more poise.")
	three.step_displacement_m = 1.2
	var leap: ComboChainResource = _combo(COMBO_SUNDERING_GAP_LEAP, "Sundering Gap-Leap", [ComboChainResource.LIGHT, ComboChainResource.LIGHT, ComboChainResource.FORWARD_HEAVY], 2,
		"Leap 2.8 m through the gap and stun the foe for 1.2 s: it cracks a martial lock.")
	leap.step_displacement_m = 2.8
	leap.stun_duration_sec = 1.2
	leap.breaks_martial_lock = true
	var vault: ComboChainResource = _combo(COMBO_WAYFARER_VAULT_STRIKE, "Wayfarer's Vault-Strike", [ComboChainResource.LIGHT, ComboChainResource.LIGHT, ComboChainResource.BACK_HEAVY], 4,
		"Strike as you vault 2.6 m back, untouchable for 200 ms.")
	vault.step_displacement_m = -2.6
	vault.evasion_iframes_ms = 200
	var sweep: ComboChainResource = _combo(COMBO_WHIRLING_FLANK_SWEEP, "Whirling Flank-Sweep", [ComboChainResource.HEAVY, ComboChainResource.SIDE_HEAVY], 6,
		"A heavy, then Heavy with the stick sideways: orbit 2.2 m round the foe to its flank for 20 more poise.")
	sweep.step_displacement_m = 2.2
	sweep.triggers_flank_orbit = true
	sweep.finisher_poise_damage = 20.0
	var grand: ComboChainResource = _combo(COMBO_GRAND_SIGN_FLOW, "Grand Sign-Flow", [ComboChainResource.FORWARD_HEAVY, ComboChainResource.R_SKILL, ComboChainResource.LR_ULT], 8,
		"Forward+Heavy, R, then L+R: the Sign detonation riding the finisher reaches 25% further.")
	grand.finisher_damage_mult = 1.0
	grand.finisher_poise_damage = 0.0
	grand.step_displacement_m = 0.0
	grand.detonation_radius_mult = 1.25


func _combo(id: StringName, label: String, sequence: Array[StringName], level: int, blurb: String) -> ComboChainResource:
	var added: ComboChainResource = ComboChainResource.new()
	added.combo_id = id
	added.display_name = label
	added.description = blurb
	added.input_sequence = sequence
	added.required_level = level
	register_combo(added)
	return added


## The kin a boss can call in its second gate. A Scree-Worm henchman wears the
## Bramble-Hob's thorny body until the worms have bodies of their own.
func _build_henchmen() -> void:
	register_henchman(HENCHMAN_SCREE_WORM, WoodlandMinion.Kind.SCUTTLER)
	register_henchman(HENCHMAN_BRAMBLE_HOB, WoodlandMinion.Kind.SCUTTLER)
	register_henchman(HENCHMAN_WISP_BOGGLE, WoodlandMinion.Kind.IMP)


# --- Action builders ------------------------------------------------------

func _strike(id: StringName, label: String, command: CombatActionResource.Command,
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


func _shot(id: StringName, label: String, command: CombatActionResource.Command, windup: float, active: float, recovery: float,
		stamina: float, damage: float, flight_range: float, speed: float) -> CombatActionResource:
	var action: CombatActionResource = _strike(id, label, command, windup, active, recovery, stamina, damage)
	action.delivery = CombatActionResource.Delivery.PROJECTILE
	action.projectile_range = flight_range
	action.projectile_speed = speed
	return action


func _support(id: StringName, label: String, command: CombatActionResource.Command, effect: CombatActionResource.Effect,
		windup: float, active: float, recovery: float) -> CombatActionResource:
	var action: CombatActionResource = _strike(id, label, command, windup, active, recovery, 0.0, 0.0)
	action.effect = effect
	action.resonance_gain = 0.0
	return action
