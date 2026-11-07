## One of the seven folkloric material tiers (the Google Doc *Everwood
## Equipment & Grimoire Architecture* §2, 22 GDD §2): what a hero's weapon,
## offhand and armour are made of, the Character Levels that may wear it, the
## Steward Threat it reads (Character Level plus the tier's rank), its flat
## damage and Armor Guard, and the parametric PBR recipe equipment_seal.gdshader
## paints it with. A tier is paint, never geometry: one mesh per archetype
## serves all seven (Gate 2, the Musk Razor; Gate 5, code-first reuse). A hero
## is promoted to a tier at the Forge once its level opens it (PartyProgress).
##
##   Tier  Material                Lv      Threat  Rank  Light  Earned
##   1     Orchard-Wood            1-4     1-7     +0    2.4    Miller's Oak
##   2     Bog-Bronze              5-7     8-13    +3    5.5    the Barrows, Hearthstead
##   3     Forge-Iron              8-10    14-19   +6    9.5    Iron-Ness
##   4     Barrow-Steel            11-13   20-25   +10   14.5   Barrow-Eyot
##   5     Rime-Silver             14-16   26-31   +13   20.5   Rime-Firth
##   6     Saffron-Gold            17-19   32-37   +16   27.5   The Crown
##   7     Star-Glass & Heart-Crag 20      38-40   +20   36.0   the Old Quay's ebb
##
## Tiers are data registered by id in the ArsenalCatalog (Gate 4).
class_name EquipmentTierResource
extends Resource

## The four base armaments, one per Calling seat (and the Wayfarers' two).
enum WeaponArchetype { WEAPON_SWORD_BOARD = 0, WEAPON_GREAT_MALLET = 1, WEAPON_BOUGH_BOW = 2, WEAPON_LANTERN_STAFF = 3 }
## The three armour weights, one per Fellowship.
enum ArmorWeightClass { ARMOR_HEAVY_SHIELD_SWORN = 0, ARMOR_MEDIUM_WAYFARER = 1, ARMOR_LIGHT_LANTERN_BEARER = 2 }

## The Great-Mallet's heft: this share more on every blow (a Cooper's Mallet 3.0 to the stick's 2.4).
const MALLET_HEFT: float = 0.25
## Each armour class's share of the tier's mitigation, and the most it may reach: Heavy, Medium, Light.
const CLASS_MITIGATION_SCALE: Array[float] = [1.25, 1.0, 0.82]
const CLASS_MITIGATION_CAP: Array[float] = [0.65, 0.55, 0.45]
const ARCHETYPE_NAMES: Array[String] = ["Sword & Board", "Great-Mallet", "Bough-Bow", "Lantern-Staff"]
const WEIGHT_CLASS_NAMES: Array[String] = ["Heavy", "Medium", "Light"]
const TIER_COUNT: int = 7

@export_group("Identity & Progression")
@export var tier_id: StringName = &"TIER_1_HOMESTEAD"
@export_range(1, 7) var tier_index: int = 1
@export var weapon_material_name: String = "Orchard-Wood"
@export var heavy_armor_name: String = "Oak-Bark & Boiled-Hide"
@export var medium_armor_name: String = "Bracken-Pelt Jerkin"
@export var light_armor_name: String = "Mended-Linen Smock"
@export var unlock_island_id: StringName = &"ISLAND_OAKSHIRE_HOLM"
## Where in the Caldera the tier is earned, as the market stall reads it.
@export var unlock_source: String = "Miller's Oak (Homestead Start)"
## The Character Levels the tier is forged for (promotion opens at the first).
@export var min_true_level: int = 1
@export var max_true_level: int = 4
## The Steward Threat a hero in this tier reads (Character Level + rank). The
## field names are the old Renown Rank's, kept for saves and the checks.
@export var min_renown_rank: int = 1
@export var max_renown_rank: int = 7
## What the tier adds to Steward Threat: +0 at Orchard-Wood to +20 at Star-Glass.
@export var gear_threat_rank: int = 0

@export_group("Deterministic Combat Math")
@export var base_light_damage: float = 2.4
@export var base_heavy_damage: float = 3.5
## The stagger a tier's blows carry, as the Binder reads it (x1.00 to x3.00).
@export var posture_multiplier: float = 1.0
@export var base_posture_damage: float = 14.0
@export_range(0.0, 0.75) var base_damage_mitigation: float = 0.04
@export var bonus_max_hp: int = 0
## Armor Guard by weight (heavy, medium, light): the share of a blow the armour takes.
@export var armor_guard: PackedFloat32Array = PackedFloat32Array([0.08, 0.05, 0.03])

@export_group("Names")
## The arm at this tier for each archetype (WeaponArchetype order): sword and buckler, maul, bow, staff.
@export var weapon_names: PackedStringArray = PackedStringArray()
## The offhand piece each archetype seals at this tier: the buckler, the maul's
## Pommel-Knot, the quiver, the lantern-censer (22 GDD R6: every weapon has three Seals).
@export var offhand_names: PackedStringArray = PackedStringArray()

@export_group("Parametric Shader Recipe (ActorVisuals)")
@export var albedo_tint: Color = Color(0.55, 0.35, 0.17, 1.0)
@export_range(0.0, 1.0) var metallic: float = 0.0
@export_range(0.0, 1.0) var roughness: float = 0.88
@export_range(0.0, 1.0) var rim_strength: float = 0.15
@export var rim_tint: Color = Color(0.82, 0.71, 0.55, 1.0)
@export_range(0.0, 2.0) var normal_scale: float = 1.0
@export_range(0.0, 2.0) var emissive_pulse_strength: float = 0.0


## The flat damage of one blow: the tier's light or heavy, with the Great-Mallet's heft on top.
func get_weapon_damage(is_heavy_attack: bool, archetype: WeaponArchetype) -> float:
	var raw_dmg: float = base_heavy_damage if is_heavy_attack else base_light_damage
	if archetype == WeaponArchetype.WEAPON_GREAT_MALLET:
		raw_dmg *= 1.0 + MALLET_HEFT
	return snappedf(raw_dmg, 0.1)


## The Lantern-Staff mends this much with its heavy (a Tier 1 Rowan-Crook: 2 damage and 3 mending); 0 for any other arm.
func get_lantern_mend(archetype: WeaponArchetype) -> float:
	return base_heavy_damage if archetype == WeaponArchetype.WEAPON_LANTERN_STAFF else 0.0


## The arm's name at this tier for an archetype ("Barrow-Steel Long-Blade & Heater-Shield").
func weapon_name(archetype: WeaponArchetype) -> String:
	return weapon_names[archetype] if archetype < weapon_names.size() else weapon_material_name


## The offhand piece an archetype seals at this tier ("Heater-Shield", "Oak-Knot Pommel").
func offhand_name(archetype: WeaponArchetype) -> String:
	return offhand_names[archetype] if archetype < offhand_names.size() else "Offhand"


## The Armor Guard a weight wears at this tier, as a whole percent (32 for Barrow-Mail).
func armor_guard_percent(weight_class: ArmorWeightClass) -> int:
	return roundi(get_mitigation_for_class(weight_class) * 100.0)


func get_armor_display_name(weight_class: ArmorWeightClass) -> String:
	match weight_class:
		ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN:
			return heavy_armor_name
		ArmorWeightClass.ARMOR_MEDIUM_WAYFARER:
			return medium_armor_name
		ArmorWeightClass.ARMOR_LIGHT_LANTERN_BEARER:
			return light_armor_name
	return medium_armor_name


## The share of a blow this tier's armour takes off, by weight: heavy plate takes 1.25x the tier's base, light cloth 0.82x.
func get_mitigation_for_class(weight_class: ArmorWeightClass) -> float:
	if armor_guard.size() == 3 and weight_class >= 0 and weight_class < 3:
		return armor_guard[weight_class]
	match weight_class:
		ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN:
			return clampf(base_damage_mitigation * CLASS_MITIGATION_SCALE[0], 0.0, CLASS_MITIGATION_CAP[0])
		ArmorWeightClass.ARMOR_MEDIUM_WAYFARER:
			return clampf(base_damage_mitigation * CLASS_MITIGATION_SCALE[1], 0.0, CLASS_MITIGATION_CAP[1])
		ArmorWeightClass.ARMOR_LIGHT_LANTERN_BEARER:
			return clampf(base_damage_mitigation * CLASS_MITIGATION_SCALE[2], 0.0, CLASS_MITIGATION_CAP[2])
	return base_damage_mitigation


## The band of True Levels the tier is forged for, and the Renown Ranks shown for them.
func true_level_band() -> Vector2i:
	return Vector2i(min_true_level, max_true_level)


func renown_rank_band() -> Vector2i:
	return Vector2i(min_renown_rank, max_renown_rank)


func covers_true_level(true_level: int) -> bool:
	return true_level >= min_true_level and true_level <= max_true_level


## "Tier 3: Forge-Iron", for the Binder and the stalls.
func tier_label() -> String:
	return "Tier %d: %s" % [tier_index, weapon_material_name]


## "Lv 11-13 · Threat 20-25".
func band_label() -> String:
	if min_true_level == max_true_level:
		return "Lv %d · Threat %d-%d" % [min_true_level, min_renown_rank, max_renown_rank]
	return "Lv %d-%d · Threat %d-%d" % [min_true_level, max_true_level, min_renown_rank, max_renown_rank]


## Every name a player reads for this tier, for the linters.
func display_names() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray([weapon_material_name, heavy_armor_name, medium_armor_name, light_armor_name])
	names.append_array(weapon_names)
	names.append_array(offhand_names)
	return names


## The shader's tier uniforms, by name (what ActorVisuals sets and the checks read).
func shader_uniforms() -> Dictionary:
	return {
		"albedo_tint": albedo_tint,
		"metallic": metallic,
		"roughness": roughness,
		"rim_strength": rim_strength,
		"rim_tint": rim_tint,
		"normal_scale": normal_scale,
		"emissive_pulse_strength": emissive_pulse_strength,
	}
