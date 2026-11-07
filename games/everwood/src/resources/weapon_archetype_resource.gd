## One of the four base armaments (docs/everwood_equipment_grimoire_architecture.md
## Part II §2.2): the permanent frame a hero keeps from Miller's Oak to the
## Old Quay's ebb, promoted through the seven material tiers rather than
## replaced. It names the Tier 1 "make-play" arm the homestead starts with, the
## trail weapon type it channels through, and the armour weight its Calling
## wears. Registered by id in the ArsenalCatalog (Gate 4).
##   WEAPON_SWORD_BOARD    Orchard-Stick & Bark-Buckler     the Shield-Sworn
##   WEAPON_GREAT_MALLET   Cooper's Cider-Mallet            Wayfarer melee
##   WEAPON_BOUGH_BOW      Bent-Twig Bough & Reed-Shafts    Wayfarer ranged
##   WEAPON_LANTERN_STAFF  Rowan-Crook & Tallow-Jar         the Lantern-Bearers
class_name WeaponArchetypeResource
extends Resource

@export var archetype_id: StringName = &"WEAPON_SWORD_BOARD"
@export var archetype: EquipmentTierResource.WeaponArchetype = EquipmentTierResource.WeaponArchetype.WEAPON_SWORD_BOARD
## The trail weapon type the frame channels its strikes and cards through (EquipmentItemResource.WeaponType).
@export var weapon_type: EquipmentItemResource.WeaponType = EquipmentItemResource.WeaponType.LIGHT_SWORD
## The armour weight the frame's Calling wears.
@export var armor_weight_class: EquipmentTierResource.ArmorWeightClass = EquipmentTierResource.ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN
## "Shield-Sworn", "Wayfarer Melee", "Wayfarer Ranged", "Lantern-Bearer".
@export var calling_label: String = "Shield-Sworn"
## The Tier 1 homestead arm, and what it looks like.
@export var homestead_name: String = "Orchard-Stick & Bark-Buckler"
@export_multiline var homestead_blurb: String = ""
## What a later tier's material is forged into: "Bog-Bronze Blade & Buckler".
@export var frame_noun: String = "Blade & Buckler"
## How the two blows read on this frame: Light / Heavy, Quick / Drawn, Light / Mend.
@export var light_label: String = "Light"
@export var heavy_label: String = "Heavy"
## What the first hour teaches with it.
@export_multiline var teaching_goal: String = ""


func is_ranged() -> bool:
	return weapon_type == EquipmentItemResource.WeaponType.BOW or weapon_type == EquipmentItemResource.WeaponType.STAFF


## The arm's name at a tier: the homestead name at Tier 1, the material on the frame after.
func tier_weapon_name(tier: EquipmentTierResource) -> String:
	if tier == null:
		return homestead_name
	if not tier.weapon_names.is_empty():
		return tier.weapon_name(archetype)
	if tier.tier_index <= 1:
		return homestead_name
	return "%s %s" % [tier.weapon_material_name, frame_noun]


## The offhand this frame seals at a tier (the maul's is its Pommel-Knot).
func tier_offhand_name(tier: EquipmentTierResource) -> String:
	return tier.offhand_name(archetype) if tier != null else "Offhand"


## "2-3 dmg (Light: 2, Heavy: 3)" at a tier.
func damage_label(tier: EquipmentTierResource) -> String:
	if tier == null:
		return ""
	var light: float = tier.get_weapon_damage(false, archetype)
	var heavy: float = tier.get_weapon_damage(true, archetype)
	var mend: float = tier.get_lantern_mend(archetype)
	if mend > 0.0:
		return "%.1f dmg + %.1f Hearth-Mend" % [light, mend]
	return "%.1f-%.1f dmg (%s: %.1f, %s: %.1f)" % [light, heavy, light_label, light, heavy_label, heavy]
