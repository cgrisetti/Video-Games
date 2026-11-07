## One of the Trail of the Four Signs' weapon tiers as it looks
## (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §5.3, 04_BALANCE.md): its
## blade and trim, how metallic and rough it is, and how strongly its Sign-stone
## glows. HeroMeshAtelier sculpts every weapon at every tier from these, and
## the ArsenalCatalog copies the palette onto each tier's EquipmentItemResource.
##   Tier 1 Apprentice Timber     Lv 1   1.00x  turned hazel and hemp cord
##   Tier 2 Hedgerow Iron         Lv 2   1.20x  dark forged iron, brass rivets
##   Tier 3 Bramble-Bridge Steel  Lv 5   1.45x  milled steel, a brass bell-guard
##   Tier 4 Doverslap Relic      Lv 10  1.75x  gilded bronze round a glowing Sign-stone
class_name WeaponVisualTierResource
extends Resource

@export var tier_id: StringName = &"apprentice_timber"
## 1 to 4 (EquipmentItemResource.EquipmentTier).
@export var tier_level: int = 1
@export var display_name: String = "Apprentice Timber"
@export var opens_at_level: int = 1
@export var stat_multiplier: float = 1.0
@export var blade_color: Color = Color(0.651, 0.482, 0.357)
@export var trim_color: Color = Color(0.784, 0.710, 0.580)
## The grip's wrap: hemp, oak, dyed leather or dark leather.
@export var grip_color: Color = Color(0.851, 0.765, 0.604)
@export_range(0.0, 1.0) var metallic: float = 0.0
@export_range(0.0, 1.0) var roughness: float = 0.78
## How brightly the weapon's Sign-stone core and fuller veins glow (0 for none).
@export var sign_core_emission: float = 0.0
## What the tier adds to the sculpt, in a line.
@export var craft_note: String = ""


## Whether the tier's weapons carry the levitating Sign-stone core.
func has_sign_stone() -> bool:
	return sign_core_emission >= 1.0


## Whether the blade is metal (every tier past timber).
func is_metal() -> bool:
	return metallic > 0.0
