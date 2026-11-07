## One of the seven folkloric material tiers
## (docs/everwood_equipment_grimoire_architecture.md Part II §3): what a
## Calling's weapon and armour are made of through a band of True Levels (and
## the Renown Ranks shown for them), the flat damage and mitigation that go
## with it, and the parametric PBR recipe equipment_seal.gdshader paints it
## with. A tier is paint, never geometry: one mesh per archetype serves all
## seven (Gate 2, the Musk Razor; Gate 5, code-first reuse).
##
##   Tier 1  Orchard-Wood           Lv 1-3    Rank 1-5    Oakshire Holm
##   Tier 2  Bog-Bronze             Lv 4-6    Rank 6-10   Barrow-Eyot
##   Tier 3  Forge-Iron             Lv 7-10   Rank 11-18  Iron-Ness
##   Tier 4  Rime-Silver            Lv 11-13  Rank 19-25  Rime-Firth
##   Tier 5  Saffron-Gold           Lv 14-16  Rank 26-32  the Convergence
##   Tier 6  Cairn-Heart            Lv 17-19  Rank 33-37  The Crown
##   Tier 7  Star-Glass & Ember-Iron  Lv 20   Rank 38-40  the Old Quay's ebb
##
## Tiers are data registered by id in the ArsenalCatalog (Gate 4).
class_name EquipmentTierResource
extends Resource

## The four base armaments, one per Calling seat (and the Wayfarers' two).
enum WeaponArchetype { WEAPON_SWORD_BOARD = 0, WEAPON_GREAT_MALLET = 1, WEAPON_BOUGH_BOW = 2, WEAPON_LANTERN_STAFF = 3 }
## The three armour weights, one per Fellowship.
enum ArmorWeightClass { ARMOR_HEAVY_SHIELD_SWORN = 0, ARMOR_MEDIUM_WAYFARER = 1, ARMOR_LIGHT_LANTERN_BEARER = 2 }

## The Great-Mallet's heft: this share more on every blow (at least 1 point).
const MALLET_HEFT: float = 0.22
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
@export var unlock_source: String = "Oakshire Holm (Homestead Start)"
@export var min_true_level: int = 1
@export var max_true_level: int = 3
@export var min_renown_rank: int = 1
@export var max_renown_rank: int = 5

@export_group("Deterministic Combat Math")
@export var base_light_damage: int = 2
@export var base_heavy_damage: int = 3
@export var base_posture_damage: float = 14.0
@export_range(0.0, 0.75) var base_damage_mitigation: float = 0.04
@export var bonus_max_hp: int = 0

@export_group("Parametric Shader Recipe (ActorVisuals)")
@export var albedo_tint: Color = Color(0.55, 0.35, 0.17, 1.0)
@export_range(0.0, 1.0) var metallic: float = 0.0
@export_range(0.0, 1.0) var roughness: float = 0.88
@export_range(0.0, 1.0) var rim_strength: float = 0.15
@export var rim_tint: Color = Color(0.82, 0.71, 0.55, 1.0)
@export_range(0.0, 2.0) var normal_scale: float = 1.0
@export_range(0.0, 2.0) var emissive_pulse_strength: float = 0.0


## The flat damage of one blow: the tier's light or heavy, with the Great-Mallet's heft on top.
func get_weapon_damage(is_heavy_attack: bool, archetype: WeaponArchetype) -> int:
	var raw_dmg: int = base_heavy_damage if is_heavy_attack else base_light_damage
	if archetype == WeaponArchetype.WEAPON_GREAT_MALLET:
		raw_dmg += maxi(1, int(round(float(raw_dmg) * MALLET_HEFT)))
	return raw_dmg


## The Lantern-Staff mends this much with its heavy (a Tier 1 Rowan-Crook: 2 damage and 3 mending); 0 for any other arm.
func get_lantern_mend(archetype: WeaponArchetype) -> int:
	return base_heavy_damage if archetype == WeaponArchetype.WEAPON_LANTERN_STAFF else 0


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


## "Lv 7-10 · Rank 11-18".
func band_label() -> String:
	if min_true_level == max_true_level:
		return "Lv %d · Rank %d-%d" % [min_true_level, min_renown_rank, max_renown_rank]
	return "Lv %d-%d · Rank %d-%d" % [min_true_level, max_true_level, min_renown_rank, max_renown_rank]


## Every name a player reads for this tier, for the linters.
func display_names() -> PackedStringArray:
	return PackedStringArray([weapon_material_name, heavy_armor_name, medium_armor_name, light_armor_name])


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
