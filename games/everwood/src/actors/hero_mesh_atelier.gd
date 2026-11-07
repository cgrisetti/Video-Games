## Sculpts heroes and their weapons in code (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md
## §2.3, §5; Stage 5): continuous, multi-ring lofts whose superellipse
## cross-sections are interpolated along Catmull-Rom spines, skinned with 1 to 4
## bone weights per ring to the 24-bone HeroRigBuilder skeleton, so shoulders,
## elbows, hips and knees bend without the gaps of stacked primitives.
##
## A hero is five skinned surfaces, each its own ArrayMesh:
##   mesh_head_heritage     cranium, brow, eyes, nose and ears, the beard (on
##                          Jaw_Beard) and the headgear
##   mesh_torso_coat        the torso and the coat's skirt (split across Hips
##                          and both thighs), and the coat's own build: the
##                          Bramble-Spun Jerkin's quilting, the Hearth-Linen
##                          Coat's sash and bell cuffs, the Hedgerow Wool-Mantle's
##                          dagged capelet and diamond-studded brigandine, the
##                          Iron-Wood Ring-Coat's ring-mail, gorget and bands
##   mesh_pauldrons_tabard  the Calling's shoulders (the Iron-Woodsman's heavy
##                          Iron-Wood bark pauldron left, a stitched-leather cop
##                          right) and the tabard with its embossed Sign crest
##   mesh_limbs_boots       legs, breeches and cuffed hobnailed boots, arms with
##                          flared bracers, mitten-gauntlets (and the
##                          Iron-Woodsman's buckler-bracer)
##   mesh_belt_cloak        the wood-splitter's belt, octagonal buckle, trinkets,
##                          Chimes pouch, and the layered cloak on Cloak_01..03
## Each vertex's colour says what it is (r crevice AO, g worn edge, b material,
## a Sign vein; storybook_hero_atelier.gdshader decodes it), and UV2.x holds its
## height at rest for the Three-Value vertical gradient.
##
## Weapons (build_tiered_weapon) are sculpted for each of the four weapons at
## each of the four tiers, grip at the origin and the blade up +Y, with marker
## nodes for the animator: HaftGripMarker (the off hand's grip on a two-handed
## haft), TrailBase / TrailTip, BowStringMid and the Doverslap relics' SignStoneCore.
##
## A model at res://assets/models/heroes/<calling_id>.glb wins over a sculpted
## hero, and res://assets/models/<item_id>.glb over a sculpted weapon.
class_name HeroMeshAtelier
extends RefCounted

# Material ids (COLOR.b), in the shader's five bands (19B §1): woven cloth
# below 0.3, timber below 0.42, leather below 0.5, metal below 0.7, then skin,
# the face, the beard, hair and the eyes.
const MAT_COAT: float = 0.02
const MAT_BREECHES: float = 0.06
const MAT_TABARD: float = 0.15
const MAT_TUNIC: float = 0.20
const MAT_TRIM: float = 0.235
const MAT_LINEN: float = 0.265
const MAT_ROPE: float = 0.29
const MAT_TIMBER: float = 0.35
const MAT_BARK: float = 0.39
const MAT_LEATHER: float = 0.445
const MAT_BOOT: float = 0.475
const MAT_IRON: float = 0.55
const MAT_RING_MAIL: float = 0.575
const MAT_BRASS: float = 0.62
const MAT_STEEL: float = 0.67
const MAT_SKIN: float = 0.74
const MAT_FACE: float = 0.765
const MAT_BEARD: float = 0.82
const MAT_HAIR: float = 0.86
const MAT_SCLERA: float = 0.90
const MAT_IRIS: float = 0.935
const MAT_EYE: float = 0.97
## The AO under each armour layer's lip, where it steps out over the one beneath.
const UNDER_LIP_AO: float = 0.25
const SHADER: Shader = preload("res://src/actors/shaders/storybook_hero_atelier.gdshader")
const HERO_MODEL_FOLDER: String = "res://assets/models/heroes/"
const REGIONS: Array[StringName] = [&"mesh_head_heritage", &"mesh_torso_coat", &"mesh_pauldrons_tabard", &"mesh_limbs_boots", &"mesh_belt_cloak"]
## Around each ring, and Catmull-Rom steps between control rings.
const SIDES: int = 14
const SUBDIV: int = 2
## Normals lean this far toward a smooth radial proxy, so the cel bands don't
## catch every facet (§2.3).
const PROXY_NORMAL_BLEND: float = 0.35
## The four coats' hems (metres above the ground) and cloak hems.
const COAT_HEMS: Dictionary[StringName, float] = {
	&"armor_bramble_jerkin": 0.64, &"hearth_linen": 0.42, &"ranger_leather": 0.58, &"ironwood_plate": 0.52,
}
const CLOAK_HEMS: Dictionary[StringName, float] = {
	&"armor_bramble_jerkin": 0.86, &"hearth_linen": 0.46, &"ranger_leather": 0.62, &"ironwood_plate": 0.5,
}
## Layer 0's torso, hips to shoulders: (height, half-width, half-depth, centre z).
const TORSO_RINGS: Array[Vector4] = [
	Vector4(0.8, 0.19, 0.15, 0.0), Vector4(0.9, 0.2, 0.155, 0.0), Vector4(1.0, 0.19, 0.145, -0.004), Vector4(1.1, 0.196, 0.148, -0.008),
	Vector4(1.2, 0.216, 0.156, -0.012), Vector4(1.29, 0.236, 0.162, -0.012), Vector4(1.36, 0.226, 0.15, -0.006), Vector4(1.41, 0.14, 0.11, 0.0),
]
## The forged iron, brass and steel every hero's fittings share.
const FORGED_IRON: Color = Color(0.353, 0.384, 0.416)
const FITTING_BRASS: Color = Color(0.769, 0.584, 0.251)
const MILLED_STEEL: Color = Color(0.769, 0.808, 0.831)
## A weapon's haft wood: turned hazel at Tier 1, ash after.
const HAZEL_WOOD: Color = Color(0.70, 0.54, 0.36)
const ASH_WOOD: Color = Color(0.46, 0.33, 0.21)
const HEMP: Color = Color(0.784, 0.710, 0.580)
const LEAF_GREEN: Color = Color(0.30, 0.52, 0.22)
## How the weapon's grip sits in the mitten: the weapon's +Y along the hand's +Z.
const GRIP_MOUNT: Transform3D = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.065, -0.005))
const B = HeroRigBuilder.Bone

static var _surface_cache: Dictionary[String, Array] = {}
static var _weapon_cache: Dictionary[String, ArrayMesh] = {}


# --- Heroes -------------------------------------------------------------------

## The five skinned surfaces of a hero in `look` wearing the coat `coat_id`
## (an armor item id), in REGIONS order. Identical heroes share them.
static func build_hero_surfaces(look: HeroAppearanceResource, coat_id: StringName) -> Array[ArrayMesh]:
	var coat: StringName = coat_id if COAT_HEMS.has(coat_id) else &"ranger_leather"
	var key: String = "%s|%s" % [look.sculpt_key(), coat]
	if _surface_cache.has(key):
		var cached: Array[ArrayMesh] = []
		cached.assign(_surface_cache[key])
		return cached
	if look.is_youth():
		var youth: Array[ArrayMesh] = HeroYouthAtelier.build_surfaces(look)
		_surface_cache[key] = youth
		return youth
	var surfaces: Array[ArrayMesh] = [
		_head_heritage(look),
		_torso_coat(look, coat),
		_pauldrons_tabard(look, coat),
		_limbs_boots(look, coat),
		_belt_cloak(look, coat),
	]
	_surface_cache[key] = surfaces
	return surfaces


## A dropped-in hero model for this look (res://assets/models/heroes/<calling_id>.glb,
## or hero_base.glb), or null.
static func hero_override(look: HeroAppearanceResource) -> Node3D:
	for path: String in [look.glb_override_path, HERO_MODEL_FOLDER + "hero_base.glb"]:
		if path != "" and ResourceLoader.exists(path):
			var scene: PackedScene = load(path) as PackedScene
			if scene != null:
				return scene.instantiate() as Node3D
	return null


## The hero's material: the shader with the look's palette, the Calling's trim and the Fellowship's rim.
static func hero_material(look: HeroAppearanceResource, trim: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"value_1_coat_color", look.value_1_coat_color)
	material.set_shader_parameter(&"value_1_boot_color", look.value_1_boot_color)
	material.set_shader_parameter(&"value_1_breeches_color", look.value_1_breeches_color)
	material.set_shader_parameter(&"calling_trim_color", trim)
	material.set_shader_parameter(&"fellowship_tunic_color", look.value_2_tunic_color)
	material.set_shader_parameter(&"trim_accent_color", trim.lightened(0.3))
	material.set_shader_parameter(&"value_2_timber_leather_color", look.value_2_timber_leather_color)
	material.set_shader_parameter(&"value_2_linen_color", look.value_2_linen_color)
	material.set_shader_parameter(&"rope_color", HEMP)
	material.set_shader_parameter(&"metal_iron_color", FORGED_IRON)
	material.set_shader_parameter(&"metal_brass_color", FITTING_BRASS)
	material.set_shader_parameter(&"metal_steel_color", MILLED_STEEL)
	material.set_shader_parameter(&"equipment_metallic", 0.6)
	material.set_shader_parameter(&"equipment_roughness", 0.45)
	material.set_shader_parameter(&"skin_tone_color", look.skin_tone_color)
	material.set_shader_parameter(&"beard_primary_color", look.beard_primary_color)
	material.set_shader_parameter(&"beard_speckle_color", look.beard_speckle_color)
	material.set_shader_parameter(&"beard_speckle_ratio", look.beard_speckle_ratio)
	material.set_shader_parameter(&"eye_color", look.eye_color)
	material.set_shader_parameter(&"sclera_color", look.sclera_color)
	material.set_shader_parameter(&"iris_color", look.iris_color)
	material.set_shader_parameter(&"leather_color", look.value_2_leather_color)
	material.set_shader_parameter(&"bark_color", look.value_2_timber_leather_color.darkened(0.38))
	material.set_shader_parameter(&"rim_color", look.role_rim_color)
	material.set_shader_parameter(&"rim_strength", StorybookMaterial.ACTOR_RIM)
	material.set_shader_parameter(&"value_3_emission_mult", HeroAppearanceResource.VALUE_3_EMISSION_MULT)
	return material


# --- Weapons ------------------------------------------------------------------

## A weapon type (EquipmentItemResource.WeaponType) sculpted at a tier (1-4),
## ready to mount: the "Weapon" root, grip at its origin, blade up +Y, its
## cutting edge toward -Z, with its markers. `item_id`'s dropped-in .glb wins.
static func build_tiered_weapon(weapon_type: int, tier_level: int, item_id: StringName = &"") -> Node3D:
	var dropped: Node3D = ActorVisuals.load_model(item_id)
	if dropped != null:
		dropped.name = "Weapon"
		return dropped
	var tier: WeaponVisualTierResource = ArsenalCatalog.current.weapon_visual_tier(tier_level)
	var root: Node3D = Node3D.new()
	root.name = "Weapon"
	root.set_meta(&"weapon_type", weapon_type)
	root.set_meta(&"tier_level", tier.tier_level)
	var blade: MeshInstance3D = MeshInstance3D.new()
	blade.name = "Blade"
	blade.mesh = build_tiered_weapon_mesh(weapon_type, tier.tier_level)
	blade.material_override = weapon_material(tier)
	blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(blade)
	var length: float = weapon_length(weapon_type)
	match weapon_type:
		EquipmentItemResource.WeaponType.LIGHT_SWORD:
			_marker(root, "TrailBase", Vector3(0.0, 0.16, -0.01))
			_marker(root, "TrailTip", Vector3(0.0, length, -0.02))
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			_marker(root, "HaftGripMarker", Vector3(0.0, 0.62, 0.0))
			_marker(root, "TrailBase", Vector3(0.0, 0.78, -0.06))
			_marker(root, "TrailTip", Vector3(0.0, 0.94, -0.24 - 0.02 * tier.tier_level))
		EquipmentItemResource.WeaponType.STAFF:
			_marker(root, "HaftGripMarker", Vector3(0.0, 0.46, 0.0))
			_marker(root, "TrailBase", Vector3(0.0, 0.7, 0.0))
			_marker(root, "TrailTip", Vector3(0.0, length, 0.0))
			if not tier.has_sign_stone():
				var seed: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.sphere("SeedGlow", 0.05 + 0.008 * tier.tier_level,
					Vector3(0.0, length - 0.06, 0.0), StorybookMaterial.glowing(Color(0.6, 1.0, 0.68), 1.4 + 0.6 * tier.tier_level)))
				root.add_child(seed)
		EquipmentItemResource.WeaponType.BOW:
			_marker(root, "TrailBase", Vector3(0.0, 0.0, 0.0))
			_marker(root, "TrailTip", Vector3(0.0, length, 0.12))
			_build_bowstring(root, length)
	if tier.has_sign_stone():
		var core: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.sphere("SignStoneCore", 0.045, sign_stone_spot(weapon_type),
			StorybookMaterial.glowing(ArsenalCatalog.SIGN_STONE_COLOR, tier.sign_core_emission * 1.6)))
		core.scale = Vector3(0.8, 1.25, 0.8)
		core.set_meta(&"rest_position", core.position)
		root.add_child(core)
	return root


## How long a weapon is from its grip to its tip (metres).
static func weapon_length(weapon_type: int) -> float:
	match weapon_type:
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			return 1.0
		EquipmentItemResource.WeaponType.STAFF:
			return 1.15
		EquipmentItemResource.WeaponType.BOW:
			return 0.8
	return 0.97


## Where a Doverslap relic's Sign-stone floats, in the weapon's frame.
static func sign_stone_spot(weapon_type: int) -> Vector3:
	match weapon_type:
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			return Vector3(0.0, 0.9, -0.09)
		EquipmentItemResource.WeaponType.STAFF:
			return Vector3(0.0, 1.08, 0.0)
		EquipmentItemResource.WeaponType.BOW:
			return Vector3(0.0, 0.0, -0.035)
	return Vector3(0.0, 0.125, 0.0)


## Whether the weapon is held in both hands (the off hand grips its HaftGripMarker).
static func is_two_handed(weapon_type: int) -> bool:
	return weapon_type == EquipmentItemResource.WeaponType.HEAVY_AXE or weapon_type == EquipmentItemResource.WeaponType.STAFF


## The sculpted mesh of a weapon type at a tier: its tier changes the geometry,
## not just the paint (§5.3).
static func build_tiered_weapon_mesh(weapon_type: int, tier_level: int) -> ArrayMesh:
	var tier: int = clampi(tier_level, 1, 4)
	var key: String = "%d|%d" % [weapon_type, tier]
	if _weapon_cache.has(key):
		return _weapon_cache[key]
	var s: Sculpt = Sculpt.new(false)
	match weapon_type:
		EquipmentItemResource.WeaponType.HEAVY_AXE:
			_sculpt_broad_axe(s, tier)
		EquipmentItemResource.WeaponType.STAFF:
			_sculpt_way_staff(s, tier)
		EquipmentItemResource.WeaponType.BOW:
			_sculpt_longbow(s, tier)
		_:
			_sculpt_falchion(s, tier)
	var mesh: ArrayMesh = s.commit(StringName("weapon_%d_tier_%d" % [weapon_type, tier]))
	_weapon_cache[key] = mesh
	return mesh


## A tier's weapon material: the blade in the tier's metal (or hazel), trim in
## its brass, the grip in its wrap, and its Sign veins faintly lit.
static func weapon_material(tier: WeaponVisualTierResource) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"metal_iron_color", tier.blade_color)
	material.set_shader_parameter(&"metal_brass_color", tier.trim_color)
	material.set_shader_parameter(&"metal_steel_color", tier.blade_color.lightened(0.4))
	material.set_shader_parameter(&"equipment_metallic", tier.metallic)
	material.set_shader_parameter(&"equipment_roughness", tier.roughness)
	material.set_shader_parameter(&"value_2_timber_leather_color", HAZEL_WOOD if tier.tier_level == 1 else ASH_WOOD)
	material.set_shader_parameter(&"value_2_linen_color", tier.grip_color)
	material.set_shader_parameter(&"rope_color", HEMP)
	material.set_shader_parameter(&"value_1_boot_color", Color(0.2, 0.14, 0.1))
	material.set_shader_parameter(&"leather_color", Color(0.42, 0.28, 0.18))
	material.set_shader_parameter(&"fellowship_tunic_color", LEAF_GREEN)
	material.set_shader_parameter(&"active_sign_color", ArsenalCatalog.SIGN_STONE_COLOR)
	material.set_shader_parameter(&"sign_emission_strength", tier.sign_core_emission * 0.5)
	material.set_shader_parameter(&"rim_color", StorybookMaterial.WARM_RIM)
	material.set_shader_parameter(&"rim_strength", PropBuilder.PROP_RIM)
	material.set_meta(&"tier_id", tier.tier_id)
	return material


# --- Props --------------------------------------------------------------------

## The Shield-Sworn's banded oak-and-brass Greatshield, worn on the off-hand forearm.
static func build_greatshield(material: Material) -> Node3D:
	var s: Sculpt = Sculpt.new(false)
	_loft(s, [
		_r(Vector3(-0.03, 0.0, 0.0), 0.29, 0.43, {}, MAT_TIMBER, {"n": 4.0}),
		_r(Vector3(-0.02, 0.0, 0.0), 0.32, 0.46, {}, MAT_TIMBER, {"n": 4.0, "g": 1.0}),
		_r(Vector3(0.02, 0.0, 0.0), 0.32, 0.46, {}, MAT_TIMBER, {"n": 4.0, "g": 1.0}),
		_r(Vector3(0.03, 0.0, 0.0), 0.29, 0.43, {}, MAT_TIMBER, {"n": 4.0, "ao": 0.7}),
	], {"subdiv": 1, "cap_start": true, "cap_end": true, "sides": 20})
	for y: float in [-0.27, 0.27]:
		_loft(s, [_r(Vector3(-0.036, y, -0.31), 0.008, 0.03, {}, MAT_BRASS), _r(Vector3(-0.042, y, 0.0), 0.008, 0.03, {}, MAT_BRASS, {"g": 0.6}),
			_r(Vector3(-0.036, y, 0.31), 0.008, 0.03, {}, MAT_BRASS)], {"subdiv": 3, "sides": 6, "cap_start": true, "cap_end": true})
	_ellipsoid(s, Vector3(-0.045, 0.0, 0.0), Vector3(0.04, 0.07, 0.07), {}, MAT_BRASS, Vector3.LEFT)
	_lozenge(s, Vector3(-0.034, 0.15, 0.0), Vector3.LEFT, 0.07, 0.1, 0.012, {}, MAT_TABARD, 0.6)
	return _prop("Greatshield", "Board", s.commit(&"greatshield"), material)


## The Lantern-Bearers' brass Tether-Lantern, hanging from the hip on a cord; it really glows.
static func build_tether_lantern(material: Material, glow: Color) -> Node3D:
	var s: Sculpt = Sculpt.new(false)
	_loft(s, [_r(Vector3(0.0, 0.0, 0.0), 0.008, 0.008, {}, MAT_ROPE), _r(Vector3(0.0, -0.16, 0.0), 0.008, 0.008, {}, MAT_ROPE)], {"subdiv": 1, "sides": 6})
	_loft(s, [
		_r(Vector3(0.0, -0.15, 0.0), 0.02, 0.02, {}, MAT_BRASS),
		_r(Vector3(0.0, -0.2, 0.0), 0.1, 0.1, {}, MAT_BRASS, {"g": 1.0}),
		_r(Vector3(0.0, -0.22, 0.0), 0.085, 0.085, {}, MAT_BRASS),
		_r(Vector3(0.0, -0.33, 0.0), 0.09, 0.09, {}, MAT_LINEN, {"a": 1.0}),
		_r(Vector3(0.0, -0.43, 0.0), 0.085, 0.085, {}, MAT_BRASS),
		_r(Vector3(0.0, -0.45, 0.0), 0.06, 0.06, {}, MAT_BRASS, {"g": 1.0}),
	], {"sides": 12, "cap_start": true, "cap_end": true,
		"color_fn": func(theta: float, t: float, c: Color) -> Color: return Color(c.r, c.g, MAT_BRASS, 0.0) if cos(theta * 6.0) > 0.7 and t > 0.25 and t < 0.8 else c})
	var lantern: Node3D = _prop("TetherLantern", "Cage", s.commit(&"tether_lantern"), material)
	var flame: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.sphere("Flame", 0.055, Vector3(0.0, -0.32, 0.0), StorybookMaterial.glowing(glow, 3.0)))
	lantern.add_child(flame)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "Light"
	light.light_color = glow
	light.light_energy = 0.8
	light.omni_range = 3.0
	light.position = Vector3(0.0, -0.32, 0.0)
	lantern.add_child(light)
	return lantern


## A quiver for the bow, its arrows fletched in the Calling's colour.
static func build_quiver(material: Material) -> Node3D:
	var s: Sculpt = Sculpt.new(false)
	_loft(s, [
		_r(Vector3(0.0, -0.3, 0.0), 0.045, 0.045, {}, MAT_LEATHER, {"ao": 0.7}),
		_r(Vector3(0.0, -0.26, 0.0), 0.055, 0.055, {}, MAT_BRASS, {"g": 1.0}),
		_r(Vector3(0.0, 0.0, 0.0), 0.058, 0.058, {}, MAT_LEATHER),
		_r(Vector3(0.0, 0.24, 0.0), 0.062, 0.062, {}, MAT_LEATHER),
		_r(Vector3(0.0, 0.27, 0.0), 0.064, 0.064, {}, MAT_BRASS, {"g": 1.0}),
	], {"sides": 10, "cap_start": true, "cap_end": true})
	for index: int in 3:
		var x: float = (float(index) - 1.0) * 0.03
		_loft(s, [_r(Vector3(x, 0.27, 0.0), 0.005, 0.005, {}, MAT_LEATHER), _r(Vector3(x, 0.36, 0.0), 0.005, 0.005, {}, MAT_LEATHER)], {"subdiv": 1, "sides": 5})
		_loft(s, [_r(Vector3(x, 0.33, 0.0), 0.003, 0.022, {}, MAT_TABARD), _r(Vector3(x, 0.42, 0.0), 0.003, 0.012, {}, MAT_TABARD)],
			{"subdiv": 1, "sides": 6, "cap_start": true, "cap_end": true})
	return _prop("Quiver", "Case", s.commit(&"quiver"), material)


## The round oak-and-iron buckler-targe strapped across a Stout Heart Wayfarer's back.
static func build_buckler_targe(material: Material) -> Node3D:
	var s: Sculpt = Sculpt.new(false)
	_loft(s, [
		_r(Vector3(0.0, 0.0, -0.02), 0.17, 0.17, {}, MAT_TIMBER, {"ao": 0.6}),
		_r(Vector3(0.0, 0.0, -0.005), 0.19, 0.19, {}, MAT_IRON, {"g": 1.0}),
		_r(Vector3(0.0, 0.0, 0.015), 0.185, 0.185, {}, MAT_TIMBER),
		_r(Vector3(0.0, 0.0, 0.03), 0.15, 0.15, {}, MAT_TIMBER),
	], {"sides": 18, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	_ellipsoid(s, Vector3(0.0, 0.0, 0.035), Vector3(0.05, 0.05, 0.035), {}, MAT_BRASS, Vector3.BACK)
	return _prop("BucklerTarge", "Targe", s.commit(&"buckler_targe"), material)


## The articulated Scribe Vellum Satchel at the hip; its Flap swings open for a
## card, and its clasp glows in the active Place-Card's Sign.
static func build_scribe_satchel(material: Material) -> Node3D:
	var bag: Sculpt = Sculpt.new(false)
	_loft(bag, [
		_r(Vector3(0.0, 0.0, 0.0), 0.035, 0.11, {}, MAT_LEATHER, {"n": 3.5, "g": 0.6}),
		_r(Vector3(0.0, -0.08, 0.0), 0.045, 0.12, {}, MAT_LEATHER, {"n": 3.5}),
		_r(Vector3(0.0, -0.16, 0.0), 0.04, 0.11, {}, MAT_LEATHER, {"n": 3.5, "ao": 0.7, "g": 0.6}),
	], {"sides": 12, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	var satchel: Node3D = _prop("ScribeSatchel", "Bag", bag.commit(&"satchel_bag"), material)
	var flap_pivot: Node3D = Node3D.new()
	flap_pivot.name = "Flap"
	flap_pivot.position = Vector3(-0.04, 0.0, 0.0)
	satchel.add_child(flap_pivot)
	var flap: Sculpt = Sculpt.new(false)
	_loft(flap, [
		_r(Vector3(0.0, 0.0, 0.0), 0.012, 0.115, {}, MAT_LEATHER, {"n": 4.0, "g": 0.7}),
		_r(Vector3(-0.004, -0.09, 0.0), 0.012, 0.115, {}, MAT_LEATHER, {"n": 4.0, "g": 0.7}),
	], {"subdiv": 1, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	_lozenge(flap, Vector3(-0.016, -0.08, 0.0), Vector3.LEFT, 0.025, 0.03, 0.01, {}, MAT_BRASS, 1.0)
	var flap_mesh: MeshInstance3D = MeshInstance3D.new()
	flap_mesh.name = "FlapMesh"
	flap_mesh.mesh = flap.commit(&"satchel_flap")
	flap_mesh.material_override = material
	flap_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flap_pivot.add_child(flap_mesh)
	return satchel


# --- The five regions ---------------------------------------------------------

static func _head_heritage(look: HeroAppearanceResource) -> ArrayMesh:
	var s: Sculpt = Sculpt.new(true)
	var head: Dictionary = _w([B.HEAD, 1.0])
	# The cranium and the face's planes (19B §2): a projecting brow ridge over
	# orbital sockets recessed 22 mm, zygomatic cheekbones, sunken temples and a
	# narrower jaw, all on the face (-Z).
	var planes_fn: Callable = func(theta: float, _t: float, p: Vector3) -> Vector3:
		var front: float = smoothstep(0.35, 0.85, maxf(0.0, -sin(theta)))
		var side: float = signf(p.x)
		var brow: float = exp(-pow((p.y - 1.628) / 0.011, 2.0)) * exp(-pow(p.x / 0.1, 4.0)) * front
		var socket: float = exp(-pow((p.y - 1.598) / 0.015, 2.0)) * exp(-pow((absf(p.x) - 0.052) / 0.026, 2.0)) * front
		var cheek: float = exp(-pow((p.y - 1.572) / 0.014, 2.0)) * exp(-pow((absf(p.x) - 0.085) / 0.022, 2.0)) * smoothstep(0.1, 0.6, maxf(0.0, -sin(theta)))
		var temple: float = exp(-pow((p.y - 1.632) / 0.02, 2.0)) * exp(-pow((absf(p.x) - 0.12) / 0.02, 2.0))
		var jaw: float = 1.0 - smoothstep(1.49, 1.535, p.y)
		var moved: Vector3 = p + Vector3(0.0, 0.0, -0.005 * brow + 0.022 * socket - 0.008 * cheek)
		moved.x += side * (0.006 * cheek - 0.006 * temple)
		moved.x *= 1.0 - 0.08 * jaw
		return moved
	_loft(s, [
		_r(Vector3(0.0, 1.452, 0.005), 0.066, 0.068, _w([B.NECK, 0.5, B.HEAD, 0.5]), MAT_FACE, {"ao": 0.6}),
		_r(Vector3(0.0, 1.5, -0.012), 0.1, 0.105, _w([B.NECK, 0.12, B.HEAD, 0.88]), MAT_FACE),
		_r(Vector3(0.0, 1.535, -0.018), 0.118, 0.122, head, MAT_FACE),
		_r(Vector3(0.0, 1.56, -0.016), 0.128, 0.132, head, MAT_FACE),
		_r(Vector3(0.0, 1.585, -0.01), 0.137, 0.141, head, MAT_FACE),
		_r(Vector3(0.0, 1.61, -0.006), 0.141, 0.145, head, MAT_FACE),
		_r(Vector3(0.0, 1.635, -0.002), 0.141, 0.145, head, MAT_FACE),
		_r(Vector3(0.0, 1.665, 0.004), 0.138, 0.142, head, MAT_FACE),
		_r(Vector3(0.0, 1.705, 0.01), 0.122, 0.126, head, MAT_FACE),
		_r(Vector3(0.0, 1.735, 0.012), 0.088, 0.092, head, MAT_FACE),
		_r(Vector3(0.0, 1.75, 0.012), 0.03, 0.03, head, MAT_FACE),
	], {"n": 2.2, "cap_end": true, "sides": 24, "subdiv": 3, "offset_fn": planes_fn, "face_zones": true})
	# The three-plane nose: a squared bridge and dorsum down to a warm, rounded tip 42 mm wide, and its wings.
	_loft(s, [
		_r(Vector3(0.0, 1.607, -0.136), 0.009, 0.008, head, MAT_FACE),
		_r(Vector3(0.0, 1.592, -0.149), 0.01, 0.009, head, MAT_FACE),
		_r(Vector3(0.0, 1.576, -0.161), 0.012, 0.01, head, MAT_FACE),
		_r(Vector3(0.0, 1.566, -0.166), 0.012, 0.009, head, MAT_FACE),
	], {"n": 3.2, "sides": 8, "face_zones": true})
	_ellipsoid(s, Vector3(0.0, 1.563, -0.1645), Vector3(0.021, 0.016, 0.012), head, MAT_FACE, Vector3.FORWARD, {}, {"face_zones": true})
	for side: float in [-1.0, 1.0]:
		_ellipsoid(s, Vector3(side * 0.0175, 1.557, -0.158), Vector3(0.01, 0.009, 0.008), head, MAT_FACE, Vector3.FORWARD, {}, {"face_zones": true})
		_eye(s, side, head)
		if look.headgear_style != &"wayfarer_hood_up":
			# Cupped ears: the outer rim, and the hollow of the bowl in shadow.
			_ellipsoid(s, Vector3(side * 0.153, 1.597, 0.012), Vector3(0.011, 0.034, 0.024), head, MAT_FACE, Vector3.RIGHT * side, {}, {"face_zones": true})
			_ellipsoid(s, Vector3(side * 0.16, 1.593, 0.01), Vector3(0.005, 0.019, 0.013), head, MAT_FACE, Vector3.RIGHT * side, {"ao": 0.3}, {"face_zones": true})
	_beard(s, look)
	_headgear(s, look)
	return s.commit(&"mesh_head_heritage")


static func _beard(s: Sculpt, look: HeroAppearanceResource) -> void:
	var jaw: Dictionary = _w([B.JAW_BEARD, 1.0])
	var head: Dictionary = _w([B.HEAD, 1.0])
	match look.beard_style:
		&"woodsman_full_speckled":
			# The full woodsman beard on Jaw_Beard: a jaw mass and three faceted lobes, the centre one longest.
			_loft(s, [
				_r(Vector3(0.0, 1.55, -0.072), 0.128, 0.072, _w([B.HEAD, 0.65, B.JAW_BEARD, 0.35]), MAT_BEARD, {"ao": 0.7}),
				_r(Vector3(0.0, 1.5, -0.094), 0.122, 0.078, _w([B.HEAD, 0.25, B.JAW_BEARD, 0.75]), MAT_BEARD),
				_r(Vector3(0.0, 1.455, -0.108), 0.104, 0.07, jaw, MAT_BEARD),
				_r(Vector3(0.0, 1.425, -0.114), 0.07, 0.05, jaw, MAT_BEARD),
			], {"cap_start": true, "cap_end": true, "sides": 12, "proxy": 0.0})
			_loft(s, [
				_r(Vector3(0.0, 1.47, -0.118), 0.055, 0.04, jaw, MAT_BEARD),
				_r(Vector3(0.0, 1.4, -0.132), 0.05, 0.037, jaw, MAT_BEARD),
				_r(Vector3(0.0, 1.345, -0.141), 0.03, 0.026, jaw, MAT_BEARD),
				_r(Vector3(0.0, 1.305, -0.146), 0.012, 0.01, jaw, MAT_BEARD),
			], {"cap_end": true, "sides": 9, "proxy": 0.0})
			for side: float in [-1.0, 1.0]:
				_loft(s, [
					_r(Vector3(side * 0.062, 1.47, -0.1), 0.04, 0.035, jaw, MAT_BEARD),
					_r(Vector3(side * 0.068, 1.41, -0.112), 0.033, 0.03, jaw, MAT_BEARD),
					_r(Vector3(side * 0.066, 1.36, -0.12), 0.015, 0.014, jaw, MAT_BEARD),
				], {"cap_end": true, "sides": 8, "proxy": 0.0})
		&"braided_hearth":
			_loft(s, [
				_r(Vector3(0.0, 1.55, -0.074), 0.124, 0.066, _w([B.HEAD, 0.65, B.JAW_BEARD, 0.35]), MAT_BEARD, {"ao": 0.7}),
				_r(Vector3(0.0, 1.5, -0.096), 0.112, 0.07, _w([B.HEAD, 0.3, B.JAW_BEARD, 0.7]), MAT_BEARD),
				_r(Vector3(0.0, 1.46, -0.11), 0.08, 0.05, jaw, MAT_BEARD),
				_r(Vector3(0.0, 1.44, -0.115), 0.03, 0.02, jaw, MAT_BEARD),
			], {"cap_start": true, "cap_end": true, "sides": 14})
			var braid_fn: Callable = func(theta: float, t: float) -> float: return 1.0 + 0.25 * sin(t * 40.0 + theta * 2.0)
			for side: float in [-1.0, 1.0]:
				_loft(s, [
					_r(Vector3(side * 0.04, 1.47, -0.118), 0.016, 0.016, jaw, MAT_BEARD),
					_r(Vector3(side * 0.043, 1.4, -0.126), 0.014, 0.014, jaw, MAT_BEARD),
					_r(Vector3(side * 0.045, 1.365, -0.128), 0.016, 0.016, jaw, MAT_BRASS, {"g": 1.0}),
					_r(Vector3(side * 0.046, 1.33, -0.13), 0.008, 0.008, jaw, MAT_BEARD),
				], {"sides": 8, "cap_end": true, "radius_fn": braid_fn})
		&"mustache_sideburns":
			for side: float in [-1.0, 1.0]:
				_loft(s, [_r(Vector3(side * 0.132, 1.63, 0.012), 0.014, 0.01, head, MAT_BEARD), _r(Vector3(side * 0.128, 1.56, -0.02), 0.016, 0.012, head, MAT_BEARD),
					_r(Vector3(side * 0.11, 1.515, -0.05), 0.012, 0.01, head, MAT_BEARD)], {"sides": 6, "cap_start": true, "cap_end": true, "side": Vector3.FORWARD})
	if look.beard_style == &"clean_youth":
		return
	# The two-wing handlebar mustache, proud of the beard, sweeping out and curling up at its tips.
	var lip: Dictionary = _w([B.HEAD, 0.55, B.JAW_BEARD, 0.45])
	for side: float in [-1.0, 1.0]:
		_loft(s, [
			_r(Vector3(side * 0.004, 1.553, -0.168), 0.011, 0.01, lip, MAT_BEARD),
			_r(Vector3(side * 0.032, 1.549, -0.165), 0.013, 0.012, lip, MAT_BEARD),
			_r(Vector3(side * 0.064, 1.54, -0.151), 0.01, 0.009, lip, MAT_BEARD),
			_r(Vector3(side * 0.09, 1.545, -0.129), 0.007, 0.006, lip, MAT_BEARD),
			_r(Vector3(side * 0.103, 1.56, -0.112), 0.003, 0.003, lip, MAT_BEARD),
		], {"sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.UP})


static func _headgear(s: Sculpt, look: HeroAppearanceResource) -> void:
	var head: Dictionary = _w([B.HEAD, 1.0])
	match look.headgear_style:
		&"wayfarer_hood_up":
			# A pine-felt ranger hood drawn up to a 1.85 m peak, framing the face, with a turned brim.
			var opening_fn: Callable = func(theta: float, _t: float, p: Vector3) -> Vector3:
				# The face opening: the front of the hood falls back behind the face.
				if sin(theta) >= -0.2:
					return p
				var open: float = smoothstep(0.135, 0.095, absf(p.x)) * smoothstep(1.465, 1.5, p.y) * smoothstep(1.74, 1.7, p.y)
				return Vector3(p.x, p.y, lerpf(p.z, -0.05, open))
			_loft(s, [
				_r(Vector3(0.0, 1.425, 0.02), 0.2, 0.17, _w([B.CHEST, 0.45, B.NECK, 0.45, B.HEAD, 0.1]), MAT_COAT, {"ao": 0.65}),
				_r(Vector3(0.0, 1.48, 0.02), 0.165, 0.16, _w([B.NECK, 0.5, B.HEAD, 0.5]), MAT_COAT),
				_r(Vector3(0.0, 1.54, 0.012), 0.158, 0.164, head, MAT_COAT),
				_r(Vector3(0.0, 1.62, 0.014), 0.17, 0.174, head, MAT_COAT),
				_r(Vector3(0.0, 1.70, 0.03), 0.158, 0.165, head, MAT_COAT),
				_r(Vector3(0.0, 1.77, 0.056), 0.115, 0.12, head, MAT_COAT),
				_r(Vector3(0.0, 1.82, 0.086), 0.055, 0.06, head, MAT_COAT),
				_r(Vector3(0.0, 1.85, 0.11), 0.012, 0.012, head, MAT_COAT),
			], {"n": 2.2, "cap_end": true, "sides": 16, "offset_fn": opening_fn})
			_loft(s, [
				_r(Vector3(-0.124, 1.49, -0.08), 0.026, 0.022, _w([B.NECK, 0.3, B.HEAD, 0.7]), MAT_COAT, {"g": 0.9}),
				_r(Vector3(-0.138, 1.6, -0.108), 0.028, 0.024, head, MAT_COAT, {"g": 0.9}),
				_r(Vector3(-0.102, 1.712, -0.128), 0.028, 0.024, head, MAT_COAT, {"g": 0.9}),
				_r(Vector3(0.0, 1.748, -0.138), 0.028, 0.024, head, MAT_COAT, {"g": 0.9}),
				_r(Vector3(0.102, 1.712, -0.128), 0.028, 0.024, head, MAT_COAT, {"g": 0.9}),
				_r(Vector3(0.138, 1.6, -0.108), 0.028, 0.024, head, MAT_COAT, {"g": 0.9}),
				_r(Vector3(0.124, 1.49, -0.08), 0.026, 0.022, _w([B.NECK, 0.3, B.HEAD, 0.7]), MAT_COAT, {"g": 0.9}),
			], {"sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.FORWARD})
		&"hood_back_shaved_crown":
			# A shaved crown, the hood folded down round the neck as a collar.
			_loft(s, [
				_r(Vector3(0.0, 1.37, 0.03), 0.19, 0.17, _w([B.CHEST, 1.0]), MAT_COAT, {"ao": 0.7}),
				_r(Vector3(0.0, 1.43, 0.04), 0.175, 0.16, _w([B.CHEST, 0.5, B.NECK, 0.5]), MAT_COAT),
				_r(Vector3(0.0, 1.475, 0.05), 0.135, 0.135, _w([B.NECK, 1.0]), MAT_COAT, {"g": 0.8}),
				_r(Vector3(0.0, 1.495, 0.055), 0.09, 0.09, _w([B.NECK, 1.0]), MAT_COAT),
			], {"sides": 16, "offset_fn": func(theta: float, t: float, p: Vector3) -> Vector3: return p + Vector3(0.0, 0.0, 0.05 * maxf(0.0, sin(theta)) * t)})
		&"stout_kettle_cap":
			_loft(s, [
				_r(Vector3(0.0, 1.645, 0.0), 0.152, 0.158, head, MAT_IRON, {"ao": 0.7}),
				_r(Vector3(0.0, 1.7, 0.0), 0.148, 0.152, head, MAT_IRON),
				_r(Vector3(0.0, 1.762, 0.0), 0.116, 0.12, head, MAT_IRON),
				_r(Vector3(0.0, 1.795, 0.0), 0.058, 0.06, head, MAT_IRON),
				_r(Vector3(0.0, 1.806, 0.0), 0.012, 0.012, head, MAT_IRON),
			], {"cap_end": true, "sides": 16})
			_loft(s, [
				_r(Vector3(0.0, 1.66, 0.0), 0.15, 0.155, head, MAT_BRASS),
				_r(Vector3(0.0, 1.648, 0.0), 0.228, 0.234, head, MAT_BRASS, {"g": 1.0}),
				_r(Vector3(0.0, 1.636, 0.0), 0.15, 0.155, head, MAT_BRASS, {"ao": 0.7}),
			], {"subdiv": 1, "sides": 18})
			# The oak-knot badge on the brow.
			_lozenge(s, Vector3(0.0, 1.69, -0.152), Vector3.FORWARD, 0.028, 0.034, 0.01, head, MAT_BRASS, 0.6)
			if look.headgear_crest:
				_loft(s, [
					_r(Vector3(0.0, 1.71, -0.135), 0.012, 0.03, head, MAT_TABARD),
					_r(Vector3(0.0, 1.835, -0.04), 0.014, 0.05, head, MAT_TABARD, {"g": 0.7}),
					_r(Vector3(0.0, 1.845, 0.06), 0.014, 0.05, head, MAT_TABARD, {"g": 0.7}),
					_r(Vector3(0.0, 1.74, 0.14), 0.012, 0.03, head, MAT_TABARD),
				], {"sides": 8, "n": 3.0, "cap_start": true, "cap_end": true})
		&"scribe_feather_hat":
			_loft(s, [
				_r(Vector3(0.0, 1.7, 0.012), 0.16, 0.162, head, MAT_COAT),
				_r(Vector3(0.0, 1.688, 0.012), 0.27, 0.272, head, MAT_COAT, {"g": 1.0}),
				_r(Vector3(0.0, 1.676, 0.012), 0.16, 0.162, head, MAT_COAT, {"ao": 0.7}),
			], {"subdiv": 1, "sides": 18})
			_loft(s, [
				_r(Vector3(0.0, 1.69, 0.02), 0.154, 0.158, head, MAT_COAT),
				_r(Vector3(0.0, 1.78, 0.05), 0.118, 0.122, head, MAT_COAT),
				_r(Vector3(0.0, 1.88, 0.09), 0.07, 0.072, head, MAT_COAT),
				_r(Vector3(0.0, 1.965, 0.14), 0.024, 0.025, head, MAT_COAT),
				_r(Vector3(0.0, 1.995, 0.162), 0.006, 0.006, head, MAT_COAT),
			], {"cap_end": true, "sides": 14})
			_loft(s, [_r(Vector3(0.0, 1.705, 0.022), 0.156, 0.16, head, MAT_TRIM), _r(Vector3(0.0, 1.73, 0.03), 0.146, 0.15, head, MAT_TRIM, {"g": 0.6})],
				{"subdiv": 1, "sides": 14})
			_loft(s, [
				_r(Vector3(0.15, 1.72, 0.05), 0.026, 0.005, head, MAT_TABARD),
				_r(Vector3(0.19, 1.82, 0.1), 0.032, 0.005, head, MAT_TABARD),
				_r(Vector3(0.205, 1.93, 0.16), 0.026, 0.005, head, MAT_TABARD),
				_r(Vector3(0.19, 2.0, 0.21), 0.006, 0.004, head, MAT_TABARD),
			], {"sides": 6, "cap_start": true, "cap_end": true, "side": Vector3.FORWARD})


static func _torso_coat(look: HeroAppearanceResource, coat: StringName) -> ArrayMesh:
	var s: Sculpt = Sculpt.new(true)
	var surface: float = MAT_TUNIC
	match coat:
		&"hearth_linen":
			surface = MAT_LINEN
		&"ironwood_plate":
			surface = MAT_RING_MAIL
	# Layer 0: the under-tunic (the ring-mail hauberk on the Ring-Coat).
	var torso: Array[Dictionary] = []
	for ring: Vector4 in TORSO_RINGS:
		var y: float = ring.x
		var bones: Dictionary = _torso_bones(y)
		torso.append(_r(Vector3(0.0, y, ring.w), ring.y, ring.z, bones, surface, {"ao": 0.6 if y < 0.85 else 1.0}))
	torso.append(_r(Vector3(0.0, 1.445, 0.0), 0.068, 0.068, _w([B.CHEST, 0.2, B.NECK, 0.8]), MAT_SKIN))
	torso.append(_r(Vector3(0.0, 1.5, 0.004), 0.06, 0.062, _w([B.NECK, 0.5, B.HEAD, 0.5]), MAT_SKIN))
	_loft(s, torso, {"n": 2.4, "cap_start": true, "sides": 16})
	# Layer 0's rolled linen collar at the neck.
	_loft(s, [
		_r(Vector3(0.0, 1.418, 0.0), 0.098, 0.092, _w([B.CHEST, 0.8, B.NECK, 0.2]), MAT_LINEN, {"ao": UNDER_LIP_AO}),
		_r(Vector3(0.0, 1.438, 0.0), 0.11, 0.102, _w([B.CHEST, 0.5, B.NECK, 0.5]), MAT_LINEN, {"g": 0.7}),
		_r(Vector3(0.0, 1.462, 0.0), 0.086, 0.083, _w([B.NECK, 1.0]), MAT_LINEN),
	], {"subdiv": 2, "sides": 16})
	# Layer 1: the coat's skirt, stepping out 18 mm, split up the front over the thighs, a rolled leather hem.
	_skirt(s, coat)
	# Layer 2: the coat's chest protection, stepping out another 20 mm.
	match coat:
		&"ranger_leather":
			_brigandine(s)
			_mantle_capelet(s)
		&"ironwood_plate":
			_breastplate(s)
		&"armor_bramble_jerkin":
			_padded_jack(s)
		&"hearth_linen":
			_pleated_surcoat(s)
	if look.split_hewing_apron:
		# The split-leather hewing apron, divided so each leg kicks free.
		for side: float in [-1.0, 1.0]:
			var thigh: int = B.THIGH_L if side < 0.0 else B.THIGH_R
			_loft(s, [
				_r(Vector3(side * 0.1, 0.93, -0.222), 0.058, 0.012, _w([B.HIPS, 1.0]), MAT_BOOT, {"n": 4.0, "ao": UNDER_LIP_AO}),
				_r(Vector3(side * 0.105, 0.76, -0.244), 0.062, 0.012, _w([B.HIPS, 0.6, thigh, 0.4]), MAT_BOOT, {"n": 4.0}),
				_r(Vector3(side * 0.11, 0.58, -0.258), 0.064, 0.012, _w([B.HIPS, 0.35, thigh, 0.65]), MAT_BOOT, {"n": 4.0, "g": 0.85}),
			], {"sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	return s.commit(&"mesh_torso_coat")


static func _pauldrons_tabard(look: HeroAppearanceResource, coat: StringName) -> ArrayMesh:
	var s: Sculpt = Sculpt.new(true)
	_pauldron(s, -1.0, look.left_pauldron_style, coat)
	_pauldron(s, 1.0, look.right_pauldron_style, coat)
	# The Calling's tabard, front and back; between the apron's halves when there is one.
	var half: float = 0.045 if look.split_hewing_apron else 0.115
	for back: float in [-1.0, 1.0]:
		var z: float = 0.2 * back
		_loft(s, [
			_r(Vector3(0.0, 0.965, z), half, 0.011, _w([B.HIPS, 1.0]), MAT_TABARD, {"n": 4.0, "ao": UNDER_LIP_AO}),
			_r(Vector3(0.0, 0.78, z + 0.022 * back), half * 1.05, 0.011, _w([B.HIPS, 0.7, B.THIGH_L, 0.15, B.THIGH_R, 0.15]), MAT_TABARD, {"n": 4.0}),
			_r(Vector3(0.0, 0.61, z + 0.04 * back), half * 1.1, 0.011, _w([B.HIPS, 0.4, B.THIGH_L, 0.3, B.THIGH_R, 0.3]), MAT_TABARD, {"n": 4.0, "g": 0.9}),
		], {"sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
		# The embossed Sign crest: a raised lozenge whose recessed veins glow in the active Sign.
		_lozenge(s, Vector3(0.0, 0.84, z + 0.028 * back), Vector3(0.0, 0.0, back), half * 0.62, 0.05, 0.01,
			_w([B.HIPS, 0.8, B.THIGH_L, 0.1, B.THIGH_R, 0.1]), MAT_BRASS, 1.0)
	return s.commit(&"mesh_pauldrons_tabard")


static func _pauldron(s: Sculpt, side: float, style: StringName, coat: StringName) -> void:
	var clavicle: int = B.CLAVICLE_L if side < 0.0 else B.CLAVICLE_R
	var upper: int = B.UPPER_ARM_L if side < 0.0 else B.UPPER_ARM_R
	var fore: int = B.FOREARM_L if side < 0.0 else B.FOREARM_R
	var mount: Dictionary = _w([clavicle, 0.35, upper, 0.65])
	var arm: Dictionary = _w([clavicle, 0.1, upper, 0.9])
	var outward: Vector3 = Vector3(side, 0.0, 0.0)
	var plated: bool = coat == &"ironwood_plate"
	var shoulder: Vector3 = HeroRigBuilder.BONE_HEADS[upper]
	var elbow: Vector3 = HeroRigBuilder.BONE_HEADS[fore]
	match style:
		&"iron_wood_bark_pauldron":
			# Three laminated plates of carved Iron-Wood bark in forged-iron rims, each stepping out
			# over the next, an upturned haute-piece guarding the neck, three brass rivets.
			_dome(s, Vector3(side * 0.215, 1.405, 0.0), Vector3(0.11, 0.075, 0.118), mount, MAT_BARK, MAT_IRON, outward)
			_dome(s, Vector3(side * 0.262, 1.352, 0.0), Vector3(0.082, 0.055, 0.104), arm, MAT_BARK, MAT_IRON, outward)
			_dome(s, Vector3(side * 0.292, 1.305, 0.0), Vector3(0.062, 0.045, 0.088), _w([upper, 1.0]), MAT_BARK, MAT_IRON, outward)
			_loft(s, [
				_r(Vector3(side * 0.135, 1.455, -0.085), 0.012, 0.02, mount, MAT_IRON, {"g": 0.8}),
				_r(Vector3(side * 0.125, 1.495, 0.0), 0.012, 0.03, mount, MAT_IRON, {"g": 1.0}),
				_r(Vector3(side * 0.135, 1.455, 0.085), 0.012, 0.02, mount, MAT_IRON, {"g": 0.8}),
			], {"subdiv": 3, "sides": 8, "n": 3.0, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
			for index: int in 3:
				var at: Vector3 = Vector3(side * (0.17 + 0.045 * index), 1.474 - 0.01 * index, -0.05 + 0.05 * index)
				_stud(s, at, Vector3.UP, 0.016, mount, MAT_BRASS)
			# The leather arming-strap buckled round the bicep.
			_band(s, shoulder.lerp(elbow, 0.34), (elbow - shoulder).normalized(), 0.088, 0.09, 0.022, arm, MAT_LEATHER)
			_buckle(s, shoulder.lerp(elbow, 0.34) + Vector3(side * 0.09, 0.0, 0.0), arm, Vector3.FORWARD)
		&"stitched_leather_cop":
			# A compact two-lame stitched-leather axeman's cop, brass-studded, leaving the arm free for overhead cleaves.
			_dome(s, Vector3(side * 0.212, 1.402, 0.0), Vector3(0.08, 0.06, 0.085), mount, MAT_STEEL if plated else MAT_LEATHER, MAT_BOOT, outward)
			_dome(s, Vector3(side * 0.248, 1.357, 0.0), Vector3(0.062, 0.045, 0.074), arm, MAT_STEEL if plated else MAT_LEATHER, MAT_BOOT, outward)
			for index: int in 4:
				var at: Vector3 = Vector3(side * (0.19 + 0.03 * index), 1.455 - 0.012 * index, -0.03 + 0.02 * float(index % 2))
				_stud(s, at, Vector3.UP, 0.008, mount, MAT_BRASS)
		&"broad_warden_pauldron":
			_dome(s, Vector3(side * 0.23, 1.41, 0.0), Vector3(0.13, 0.085, 0.13), mount, MAT_IRON, MAT_BRASS, outward)
			_dome(s, Vector3(side * 0.29, 1.32, 0.0), Vector3(0.08, 0.05, 0.1), arm, MAT_IRON, MAT_BRASS, outward)
			_band(s, shoulder.lerp(elbow, 0.38), (elbow - shoulder).normalized(), 0.086, 0.088, 0.02, arm, MAT_LEATHER)
		&"saffron_stole":
			_loft(s, [
				_r(Vector3(side * 0.11, 1.28, 0.165), 0.055, 0.012, _w([B.CHEST, 1.0]), MAT_TUNIC, {"n": 4.0, "ao": UNDER_LIP_AO}),
				_r(Vector3(side * 0.15, 1.455, 0.03), 0.06, 0.012, _w([B.CHEST, 0.6, clavicle, 0.4]), MAT_TUNIC, {"n": 4.0, "g": 0.6}),
				_r(Vector3(side * 0.135, 1.38, -0.145), 0.058, 0.012, _w([B.CHEST, 1.0]), MAT_TUNIC, {"n": 4.0}),
				_r(Vector3(side * 0.12, 1.12, -0.205), 0.055, 0.012, _w([B.CHEST, 0.4, B.SPINE, 0.6]), MAT_TUNIC, {"n": 4.0, "g": 0.9}),
			], {"sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})


static func _limbs_boots(look: HeroAppearanceResource, coat: StringName) -> ArrayMesh:
	var s: Sculpt = Sculpt.new(true)
	for side: float in [-1.0, 1.0]:
		_leg(s, side, coat)
		_boot(s, side)
		_arm(s, side, coat)
		_mitten(s, side, coat)
	if look.left_pauldron_style == &"iron_wood_bark_pauldron":
		# The Iron-Woodsman's Iron-Wood and brass buckler-bracer, strapped to the left forearm.
		var bracer: Dictionary = _w([B.FOREARM_L, 1.0])
		_loft(s, [
			_r(Vector3(-0.355, 0.96, 0.004), 0.095, 0.095, bracer, MAT_BARK, {"ao": UNDER_LIP_AO}),
			_r(Vector3(-0.367, 0.96, 0.004), 0.108, 0.108, bracer, MAT_BRASS, {"g": 1.0}),
			_r(Vector3(-0.381, 0.96, 0.004), 0.1, 0.1, bracer, MAT_BARK),
			_r(Vector3(-0.387, 0.96, 0.004), 0.07, 0.07, bracer, MAT_BARK),
		], {"sides": 16, "subdiv": 1, "cap_start": true, "cap_end": true})
		_ellipsoid(s, Vector3(-0.392, 0.96, 0.004), Vector3(0.012, 0.032, 0.032), bracer, MAT_IRON, Vector3.LEFT)
		for index: int in 4:
			var angle: float = TAU * float(index) / 4.0 + PI * 0.25
			_stud(s, Vector3(-0.385, 0.96 + sin(angle) * 0.08, 0.004 + cos(angle) * 0.08), Vector3.LEFT, 0.007, bracer, MAT_BRASS)
	return s.commit(&"mesh_limbs_boots")


static func _leg(s: Sculpt, side: float, coat: StringName) -> void:
	var thigh: int = B.THIGH_L if side < 0.0 else B.THIGH_R
	var shin: int = B.SHIN_L if side < 0.0 else B.SHIN_R
	var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
	var x: float = 0.11 * side
	var cloth: float = MAT_BREECHES
	# Layer 0: slate-wool knee-breeches into the boot shaft.
	_loft(s, [
		_r(Vector3(x * 0.95, 0.99, 0.0), 0.125, 0.12, _w([B.HIPS, 0.75, thigh, 0.25]), cloth, {"ao": 0.7}),
		_r(Vector3(x, 0.88, 0.0), 0.118, 0.115, _w([B.HIPS, 0.3, thigh, 0.7]), cloth),
		_r(Vector3(x, 0.73, -0.005), 0.104, 0.1, _w([thigh, 1.0]), cloth),
		_r(Vector3(x * 1.02, 0.6, -0.01), 0.09, 0.09, _w([thigh, 0.85, shin, 0.15]), cloth),
		_r(Vector3(x * 1.04, 0.5, -0.012), 0.084, 0.084, _w([thigh, 0.5, shin, 0.5]), cloth, {"ao": 0.85}),
		_r(Vector3(x * 1.04, 0.44, -0.008), 0.078, 0.081, _w([thigh, 0.12, shin, 0.88]), cloth),
		_r(Vector3(x * 1.05, 0.405, -0.004), 0.074, 0.077, _w([shin, 1.0]), MAT_BOOT, {"ao": 0.6}),
		_r(Vector3(x * 1.06, 0.29, 0.0), 0.075, 0.078, _w([shin, 1.0]), MAT_BOOT),
		_r(Vector3(x * 1.07, 0.2, 0.01), 0.074, 0.077, _w([shin, 0.92, foot, 0.08]), MAT_BOOT),
		_r(Vector3(x * 1.08, 0.12, 0.018), 0.072, 0.078, _w([shin, 0.5, foot, 0.5]), MAT_BOOT),
		_r(Vector3(x * 1.09, 0.07, 0.02), 0.07, 0.078, _w([shin, 0.15, foot, 0.85]), MAT_BOOT),
	], {"cap_end": true})
	# The knee-breeches' buckled garter below the knee.
	_band(s, Vector3(x * 1.04, 0.455, -0.009), Vector3.DOWN, 0.086, 0.089, 0.018, _w([thigh, 0.15, shin, 0.85]), MAT_LEATHER)
	_stud(s, Vector3(x * 1.04 + side * 0.087, 0.455, -0.009), Vector3(side, 0.0, 0.0), 0.007, _w([shin, 1.0]), MAT_BRASS)
	# The folded-down boot top, standing out over the shaft from 0.34 to 0.42 m.
	_loft(s, [
		_r(Vector3(x * 1.05, 0.422, -0.004), 0.086, 0.089, _w([thigh, 0.05, shin, 0.95]), MAT_BOOT, {"g": 0.85}),
		_r(Vector3(x * 1.05, 0.405, -0.002), 0.097, 0.1, _w([shin, 1.0]), MAT_BOOT, {"g": 0.5}),
		_r(Vector3(x * 1.06, 0.355, 0.0), 0.1, 0.103, _w([shin, 1.0]), MAT_BOOT),
		_r(Vector3(x * 1.06, 0.338, 0.0), 0.094, 0.097, _w([shin, 1.0]), MAT_BOOT, {"ao": UNDER_LIP_AO, "g": 0.9}),
	], {"subdiv": 2, "sides": 16})
	if coat == &"ironwood_plate":
		# Plated shin-greaves.
		_loft(s, [
			_r(Vector3(x * 1.06, 0.33, -0.012), 0.082, 0.087, _w([shin, 1.0]), MAT_STEEL, {"g": 1.0}),
			_r(Vector3(x * 1.07, 0.26, -0.014), 0.085, 0.09, _w([shin, 1.0]), MAT_STEEL),
			_r(Vector3(x * 1.08, 0.19, -0.004), 0.082, 0.087, _w([shin, 0.9, foot, 0.1]), MAT_STEEL, {"g": 1.0, "ao": UNDER_LIP_AO}),
		], {"subdiv": 1, "sides": 14})


static func _boot(s: Sculpt, side: float) -> void:
	var shin: int = B.SHIN_L if side < 0.0 else B.SHIN_R
	var foot: int = B.FOOT_L if side < 0.0 else B.FOOT_R
	var x: float = 0.131 * side
	var on_foot: Dictionary = _w([foot, 1.0])
	var sole_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		# The sole, darker underfoot; the toe cap's worn, burnished edge.
		return Color(c.r * 0.55, c.g, c.b, c.a) if sin(theta) < -0.6 else c
	_loft(s, [
		_r(Vector3(x, 0.06, 0.075), 0.06, 0.055, _w([shin, 0.15, foot, 0.85]), MAT_BOOT, {"ao": 0.75}),
		_r(Vector3(x, 0.06, 0.03), 0.072, 0.06, on_foot, MAT_BOOT),
		_r(Vector3(x, 0.058, -0.05), 0.07, 0.052, on_foot, MAT_BOOT),
		_r(Vector3(x * 0.99, 0.055, -0.115), 0.062, 0.045, on_foot, MAT_BOOT, {"g": 0.5}),
		_r(Vector3(x * 0.98, 0.068, -0.16), 0.045, 0.032, on_foot, MAT_BOOT, {"g": 0.9}),
		_r(Vector3(x * 0.97, 0.085, -0.185), 0.018, 0.016, on_foot, MAT_BOOT, {"g": 0.9}),
	], {"n": 3.2, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT, "color_fn": sole_fn})
	# A distinct stacked heel block.
	_loft(s, [_r(Vector3(x, 0.022, 0.085), 0.05, 0.022, _w([shin, 0.1, foot, 0.9]), MAT_BOOT, {"n": 4.0, "ao": 0.5}),
		_r(Vector3(x, 0.022, 0.035), 0.052, 0.022, on_foot, MAT_BOOT, {"n": 4.0, "g": 0.7})], {"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	# Iron hobnails round the sole's welt.
	for index: int in 9:
		var z: float = lerpf(0.06, -0.15, float(index) / 8.0)
		var reach: float = 0.068 * (1.0 - 0.45 * smoothstep(-0.08, -0.15, z))
		for edge: float in [-1.0, 1.0]:
			_stud(s, Vector3(x + edge * reach, 0.009, z), Vector3(edge, -0.5, 0.0).normalized(), 0.006, on_foot, MAT_IRON)


static func _arm(s: Sculpt, side: float, coat: StringName) -> void:
	var clavicle: int = B.CLAVICLE_L if side < 0.0 else B.CLAVICLE_R
	var upper: int = B.UPPER_ARM_L if side < 0.0 else B.UPPER_ARM_R
	var fore: int = B.FOREARM_L if side < 0.0 else B.FOREARM_R
	var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
	var shoulder: Vector3 = HeroRigBuilder.BONE_HEADS[upper]
	var elbow: Vector3 = HeroRigBuilder.BONE_HEADS[fore]
	var wrist: Vector3 = HeroRigBuilder.BONE_HEADS[hand]
	var sleeve: float = MAT_TUNIC
	var bracer: float = MAT_LEATHER
	match coat:
		&"hearth_linen":
			sleeve = MAT_LINEN
			bracer = MAT_TRIM
		&"ranger_leather":
			sleeve = MAT_COAT
		&"ironwood_plate":
			sleeve = MAT_RING_MAIL
			bracer = MAT_STEEL
	var quilted_fn: Callable = func(_theta: float, t: float, c: Color) -> Color:
		return Color(c.r * (0.85 + 0.15 * cos(t * 90.0)), c.g, c.b, c.a) if absf(c.b - MAT_LINEN) < 0.01 else c
	# Layer 0 and 1: the coat sleeve on the upper arm, the quilted linen under-sleeve puffing at the elbow and down the forearm.
	_loft(s, [
		_r(shoulder + Vector3(-0.012 * side, 0.035, 0.0), 0.07, 0.078, _w([clavicle, 0.4, upper, 0.6]), sleeve, {"ao": 0.8}),
		_r(shoulder.lerp(elbow, 0.12), 0.078, 0.08, _w([clavicle, 0.1, upper, 0.9]), sleeve),
		_r(shoulder.lerp(elbow, 0.5), 0.07, 0.072, _w([upper, 1.0]), sleeve),
		_r(shoulder.lerp(elbow, 0.78), 0.066, 0.068, _w([upper, 0.92, fore, 0.08]), sleeve, {"g": 0.8}),
		_r(shoulder.lerp(elbow, 0.84), 0.06, 0.062, _w([upper, 0.85, fore, 0.15]), MAT_LINEN, {"ao": UNDER_LIP_AO}),
		_r(elbow, 0.068, 0.07, _w([upper, 0.5, fore, 0.5]), MAT_LINEN),
		_r(elbow.lerp(wrist, 0.18), 0.064, 0.064, _w([upper, 0.1, fore, 0.9]), MAT_LINEN),
		_r(elbow.lerp(wrist, 0.6), 0.06, 0.056, _w([fore, 1.0]), MAT_LINEN),
		_r(elbow.lerp(wrist, 0.9), 0.056, 0.052, _w([fore, 0.85, hand, 0.15]), MAT_LINEN),
		_r(wrist + Vector3(0.0, 0.005, 0.0), 0.052, 0.048, _w([fore, 0.5, hand, 0.5]), MAT_LINEN, {"ao": 0.7}),
	], {"cap_start": true, "color_fn": quilted_fn})
	# The sleeve's rolled cuff above the elbow, stepping out over the under-sleeve.
	_band(s, shoulder.lerp(elbow, 0.79), (elbow - shoulder).normalized(), 0.073, 0.075, 0.02, _w([upper, 0.9, fore, 0.1]), sleeve)
	# Layer 2: the bracer (a bell cuff on the Linen Coat, a vambrace on the Ring-Coat), stepping out over the forearm, strapped twice.
	var flare: float = 1.25 if coat == &"hearth_linen" else 1.0
	_loft(s, [
		_r(elbow.lerp(wrist, 0.26), 0.072, 0.068, _w([upper, 0.05, fore, 0.95]), bracer, {"ao": UNDER_LIP_AO, "g": 0.7}),
		_r(elbow.lerp(wrist, 0.32), 0.079, 0.074, _w([fore, 1.0]), bracer),
		_r(elbow.lerp(wrist, 0.62), 0.082 * flare, 0.075 * flare, _w([fore, 1.0]), bracer),
		_r(elbow.lerp(wrist, 0.88), 0.076 * flare, 0.068 * flare, _w([fore, 0.85, hand, 0.15]), bracer, {"g": 0.85}),
		_r(elbow.lerp(wrist, 0.92), 0.066 * flare, 0.06 * flare, _w([fore, 0.8, hand, 0.2]), bracer, {"ao": UNDER_LIP_AO}),
	], {"subdiv": 2})
	if coat != &"hearth_linen":
		for at: float in [0.42, 0.74]:
			_band(s, elbow.lerp(wrist, at), (wrist - elbow).normalized(), 0.087, 0.08, 0.016, _w([fore, 1.0]), MAT_BOOT)
			_stud(s, elbow.lerp(wrist, at) + Vector3(side * 0.088, 0.0, 0.0), Vector3(side, 0.0, 0.0), 0.006, _w([fore, 1.0]), MAT_BRASS)
	if coat == &"armor_bramble_jerkin":
		# Stitched rawhide wraps round the forearm.
		for at: float in [0.5, 0.58]:
			_band(s, elbow.lerp(wrist, at), (wrist - elbow).normalized(), 0.086, 0.079, 0.012, _w([fore, 1.0]), MAT_ROPE)


static func _mitten(s: Sculpt, side: float, coat: StringName) -> void:
	var fore: int = B.FOREARM_L if side < 0.0 else B.FOREARM_R
	var hand: int = B.HAND_L if side < 0.0 else B.HAND_R
	var wrist: Vector3 = HeroRigBuilder.BONE_HEADS[hand]
	var down: Vector3 = HeroRigBuilder.rest_direction(hand)
	var tip: Vector3 = HeroRigBuilder.tail_of(hand)
	var glove: float = MAT_BOOT
	var cuff_mat: float = MAT_STEEL if coat == &"ironwood_plate" else MAT_LEATHER
	var on_hand: Dictionary = _w([hand, 1.0])
	# A beveled mitten-gauntlet: the flared cuff, the mitten.
	_loft(s, [
		_r(wrist + down * 0.008, 0.064, 0.058, _w([fore, 0.3, hand, 0.7]), cuff_mat, {"g": 1.0, "ao": UNDER_LIP_AO}),
		_r(wrist + down * 0.025, 0.055, 0.045, on_hand, glove),
		_r(wrist + down * 0.06, 0.06, 0.036, on_hand, glove),
		_r(wrist + down * 0.095, 0.058, 0.034, on_hand, glove),
		_r(wrist + down * 0.12, 0.045, 0.03, on_hand, glove, {"g": 0.5}),
		_r(tip, 0.022, 0.02, on_hand, glove),
	], {"cap_end": true, "side": Vector3.FORWARD, "n": 2.6})
	# Three articulated knuckle plates across the back of the hand, each overlapping the next.
	for plate: int in 3:
		var along: float = 0.04 + 0.027 * float(plate)
		_loft(s, [_r(wrist + down * along + Vector3(side * 0.034, 0.0, 0.0), 0.052 - 0.004 * plate, 0.008, on_hand, MAT_IRON, {"ao": UNDER_LIP_AO}),
			_r(wrist + down * (along + 0.024) + Vector3(side * (0.037 + 0.002 * plate), 0.0, 0.0), 0.054 - 0.004 * plate, 0.008, on_hand, MAT_IRON, {"g": 1.0})],
			{"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.FORWARD, "n": 3.0})
	_loft(s, [
		_r(wrist + down * 0.035 + Vector3(-side * 0.008, 0.0, -0.035), 0.019, 0.017, on_hand, glove),
		_r(wrist + down * 0.065 + Vector3(-side * 0.012, 0.0, -0.058), 0.017, 0.015, on_hand, glove),
		_r(wrist + down * 0.088 + Vector3(-side * 0.014, 0.0, -0.066), 0.01, 0.009, on_hand, glove),
	], {"sides": 8, "cap_end": true})
	# A small iron plate over the thumb.
	_stud(s, wrist + down * 0.06 + Vector3(-side * 0.012, 0.0, -0.068), Vector3(0.0, 0.0, -1.0), 0.012, on_hand, MAT_IRON)


static func _belt_cloak(look: HeroAppearanceResource, coat: StringName) -> ArrayMesh:
	var s: Sculpt = Sculpt.new(true)
	var hips: Dictionary = _w([B.HIPS, 1.0])
	# The cinched wood-splitter's belt over the skirt, its edges rolled and stitched, an octagonal brass buckle.
	_loft(s, [
		_r(Vector3(0.0, 0.895, 0.0), 0.21, 0.17, hips, MAT_LEATHER, {"ao": UNDER_LIP_AO}),
		_r(Vector3(0.0, 0.902, 0.0), 0.232, 0.19, hips, MAT_LEATHER, {"g": 0.85}),
		_r(Vector3(0.0, 0.94, 0.0), 0.234, 0.192, hips, MAT_LEATHER, {"g": 0.5}),
		_r(Vector3(0.0, 0.983, 0.0), 0.232, 0.19, hips, MAT_LEATHER, {"g": 0.85}),
		_r(Vector3(0.0, 0.99, 0.0), 0.21, 0.17, hips, MAT_LEATHER, {"ao": UNDER_LIP_AO}),
	], {"subdiv": 1, "sides": 24})
	_loft(s, [
		_r(Vector3(0.0, 0.942, -0.188), 0.044, 0.04, hips, MAT_BRASS, {"ao": UNDER_LIP_AO}),
		_r(Vector3(0.0, 0.942, -0.2), 0.05, 0.046, hips, MAT_BRASS, {"g": 1.0}),
		_r(Vector3(0.0, 0.942, -0.21), 0.04, 0.036, hips, MAT_BRASS, {"a": 0.5}),
	], {"subdiv": 1, "sides": 8, "cap_end": true})
	# The buckle's tongue and the belt's tip running through.
	_loft(s, [_r(Vector3(0.0, 0.942, -0.212), 0.006, 0.004, hips, MAT_IRON), _r(Vector3(0.055, 0.942, -0.205), 0.005, 0.004, hips, MAT_IRON)],
		{"subdiv": 1, "sides": 5, "cap_start": true, "cap_end": true})
	# The brass Chimes pouch.
	_ellipsoid(s, Vector3(-0.15, 0.87, -0.15), Vector3(0.045, 0.05, 0.035), hips, MAT_LEATHER, Vector3.DOWN, {"g": 0.5})
	_ellipsoid(s, Vector3(-0.15, 0.905, -0.165), Vector3(0.028, 0.012, 0.022), hips, MAT_BRASS, Vector3.UP)
	_trinket(s, look.belt_trinket_id)
	_cloak(s, coat)
	return s.commit(&"mesh_belt_cloak")


## A belt trinket by id, at the right hip.
static func _trinket(s: Sculpt, trinket: StringName) -> void:
	var hips: Dictionary = _w([B.HIPS, 1.0])
	match trinket:
		&"iron_splitting_wedges":
			# Two hanging bog-iron felling wedges and a sandstone whetstone.
			for z: float in [-0.06, 0.04]:
				_loft(s, [_r(Vector3(0.215, 0.88, z), 0.02, 0.028, hips, MAT_IRON, {"n": 4.0, "g": 0.6}),
					_r(Vector3(0.222, 0.8, z), 0.012, 0.03, hips, MAT_IRON, {"n": 4.0}),
					_r(Vector3(0.226, 0.74, z), 0.003, 0.03, hips, MAT_STEEL, {"n": 4.0, "g": 1.0})], {"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true})
			_ellipsoid(s, Vector3(0.19, 0.86, 0.11), Vector3(0.022, 0.06, 0.02), hips, MAT_LINEN, Vector3.DOWN)
		&"brass_bridge_key", &"brass_astrolabe":
			_loft(s, [_r(Vector3(0.22, 0.87, -0.04), 0.035, 0.035, hips, MAT_BRASS), _r(Vector3(0.232, 0.87, -0.04), 0.035, 0.035, hips, MAT_BRASS, {"g": 1.0})],
				{"subdiv": 1, "sides": 12, "cap_start": true, "cap_end": true})
			_loft(s, [_r(Vector3(0.226, 0.84, -0.04), 0.008, 0.008, hips, MAT_BRASS), _r(Vector3(0.226, 0.75, -0.04), 0.008, 0.008, hips, MAT_BRASS)],
				{"subdiv": 1, "sides": 6, "cap_end": true})
		&"brass_hand_bell":
			_loft(s, [_r(Vector3(0.22, 0.88, -0.02), 0.012, 0.012, hips, MAT_TIMBER), _r(Vector3(0.22, 0.83, -0.02), 0.03, 0.03, hips, MAT_BRASS),
				_r(Vector3(0.22, 0.77, -0.02), 0.05, 0.05, hips, MAT_BRASS, {"g": 1.0})], {"sides": 12, "cap_start": true, "cap_end": true})
		&"ember_lamp_flask":
			_loft(s, [_r(Vector3(0.22, 0.9, -0.02), 0.012, 0.012, hips, MAT_BRASS), _r(Vector3(0.22, 0.86, -0.02), 0.04, 0.04, hips, MAT_LINEN, {"a": 0.8}),
				_r(Vector3(0.22, 0.78, -0.02), 0.035, 0.035, hips, MAT_LINEN, {"a": 0.8})], {"sides": 10, "cap_start": true, "cap_end": true})
		_:
			# A small tool case: a whistle, a snare coil, reed pipes or a quill case.
			_loft(s, [_r(Vector3(0.222, 0.9, -0.02), 0.022, 0.022, hips, MAT_TIMBER, {"g": 0.6}), _r(Vector3(0.226, 0.76, -0.02), 0.02, 0.02, hips, MAT_ROPE, {"g": 0.6})],
				{"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true})


## The layered cloak on Cloak_01..03: a curved slab of wool lined in russet
## leather, its hem by coat (a dagged mantle, a long swallowtail, a heavy cape).
static func _cloak(s: Sculpt, coat: StringName) -> void:
	var hem: float = CLOAK_HEMS[coat]
	var path: Array[Dictionary] = [
		_r(Vector3(0.0, 1.43, 0.115), 0.17, 0.0, _w([B.CHEST, 1.0]), MAT_COAT),
		_r(Vector3(0.0, 1.38, 0.155), 0.19, 0.0, _w([B.CHEST, 0.3, B.CLOAK_01, 0.7]), MAT_COAT),
		_r(Vector3(0.0, 1.22, 0.185), 0.22, 0.0, _w([B.CLOAK_01, 1.0]), MAT_COAT),
		_r(Vector3(0.0, 1.06, 0.215), 0.245, 0.0, _w([B.CLOAK_01, 0.45, B.CLOAK_02, 0.55]), MAT_COAT),
	]
	if hem < 1.0:
		path.append(_r(Vector3(0.0, 0.9, 0.235), 0.27, 0.0, _w([B.CLOAK_02, 1.0]), MAT_COAT))
	if hem < 0.8:
		path.append(_r(Vector3(0.0, 0.74, 0.255), 0.29, 0.0, _w([B.CLOAK_02, 0.45, B.CLOAK_03, 0.55]), MAT_COAT))
	if hem < 0.62:
		path.append(_r(Vector3(0.0, 0.6, 0.262), 0.3, 0.0, _w([B.CLOAK_03, 1.0]), MAT_COAT))
	var last: Dictionary = path.back()
	var last_y: float = (last["c"] as Vector3).y
	if last_y - hem > 0.04:
		var bones: Dictionary = _w([B.CLOAK_03, 1.0]) if hem < 0.8 else last["b"]
		path.append(_r(Vector3(0.0, hem, 0.255 + (0.74 - hem) * 0.08), (last["w"] as float) + 0.015, 0.0, bones, MAT_COAT, {"g": 0.8}))
	var swallowtail: bool = coat == &"hearth_linen"
	var dagged: bool = coat == &"ranger_leather"
	var slab_fn: Callable = func(theta: float, _t: float, w: float, _d: float) -> Vector2:
		# A curved slab wrapping the back: the outer arc (away from the body) first, then the lining.
		var arc_radius: float = 0.34
		var reach: float = w / arc_radius
		var thick: float = 0.012
		var outer: bool = theta < PI
		var phi: float = lerpf(-reach, reach, theta / PI) if outer else lerpf(reach, -reach, (theta - PI) / PI)
		var r: float = arc_radius + thick if outer else arc_radius - thick
		return Vector2(r * sin(phi), arc_radius - r * cos(phi))
	var lining_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		return c if theta < PI else Color(c.r * 0.85, c.g, MAT_TABARD, c.a)
	var hem_fn: Callable = func(theta: float, t: float, p: Vector3) -> Vector3:
		var hem_k: float = smoothstep(0.82, 1.0, t)
		if hem_k <= 0.0:
			return p
		# 0 at the cloak's edges, 1 down its middle.
		var across: float = 1.0 - absf(1.0 - 2.0 * fmod(theta, PI) / PI)
		var lift: float = 0.0
		if swallowtail:
			lift = 0.16 * pow(across, 1.5)
		elif dagged:
			lift = 0.035 * maxf(0.0, cos(across * PI * 7.0))
		return p + Vector3(0.0, lift * hem_k, 0.0)
	_loft(s, path, {"sides": 24, "proxy": 0.0, "section": slab_fn, "color_fn": lining_fn, "offset_fn": hem_fn})


## One eye in its socket: an almond of ivory sclera, a hazel-amber iris disc, a
## dark pupil, the dark lash rim along the upper lid, and an expressive brow.
static func _eye(s: Sculpt, side: float, head: Dictionary) -> void:
	_loft(s, [
		_r(Vector3(side * 0.031, 1.5965, -0.127), 0.002, 0.002, head, MAT_SCLERA),
		_r(Vector3(side * 0.04, 1.5975, -0.13), 0.005, 0.008, head, MAT_SCLERA),
		_r(Vector3(side * 0.052, 1.5985, -0.131), 0.006, 0.0105, head, MAT_SCLERA),
		_r(Vector3(side * 0.064, 1.5995, -0.129), 0.005, 0.0085, head, MAT_SCLERA),
		_r(Vector3(side * 0.074, 1.601, -0.124), 0.002, 0.002, head, MAT_SCLERA),
	], {"sides": 10, "cap_start": true, "cap_end": true, "side": Vector3.FORWARD})
	_ellipsoid(s, Vector3(side * 0.052, 1.598, -0.1355), Vector3(0.0085, 0.0085, 0.0022), head, MAT_IRIS, Vector3.FORWARD)
	_ellipsoid(s, Vector3(side * 0.052, 1.598, -0.1378), Vector3(0.0042, 0.0042, 0.0011), head, MAT_EYE, Vector3.FORWARD)
	_loft(s, [
		_r(Vector3(side * 0.03, 1.5995, -0.1295), 0.0025, 0.0025, head, MAT_HAIR),
		_r(Vector3(side * 0.042, 1.6075, -0.1355), 0.0032, 0.0035, head, MAT_HAIR),
		_r(Vector3(side * 0.056, 1.6095, -0.137), 0.0034, 0.0036, head, MAT_HAIR),
		_r(Vector3(side * 0.069, 1.6055, -0.1325), 0.003, 0.0032, head, MAT_HAIR),
		_r(Vector3(side * 0.077, 1.6015, -0.1255), 0.0018, 0.002, head, MAT_HAIR),
	], {"sides": 6, "cap_start": true, "cap_end": true, "side": Vector3.UP})
	# The brow: low and close at the nose, raised at its outer end (a determined, kindly look).
	_loft(s, [
		_r(Vector3(side * 0.02, 1.621, -0.1535), 0.0068, 0.006, head, MAT_HAIR),
		_r(Vector3(side * 0.052, 1.6305, -0.1525), 0.0062, 0.0058, head, MAT_HAIR),
		_r(Vector3(side * 0.086, 1.633, -0.1365), 0.0042, 0.0045, head, MAT_HAIR),
	], {"subdiv": 3, "sides": 6, "cap_start": true, "cap_end": true, "side": Vector3.UP})


## The torso's bones at a height, hips to neck.
static func _torso_bones(y: float) -> Dictionary:
	if y < 0.95:
		return _w([B.HIPS, 1.0 - smoothstep(0.85, 0.95, y) * 0.1, B.SPINE, smoothstep(0.85, 0.95, y) * 0.1])
	if y < 1.15:
		var u: float = smoothstep(0.95, 1.15, y)
		return _w([B.HIPS, 0.4 * (1.0 - u), B.SPINE, 0.6 + 0.2 * u, B.CHEST, 0.2 * u])
	if y < 1.3:
		var v: float = smoothstep(1.15, 1.3, y)
		return _w([B.SPINE, 0.8 * (1.0 - v), B.CHEST, 0.2 + 0.8 * v])
	if y < 1.4:
		return _w([B.CHEST, 1.0])
	return _w([B.CHEST, 0.7, B.NECK, 0.3])


## Layer 0's torso at a height: Vector3(half-width, half-depth, centre z).
static func _torso_at(y: float) -> Vector3:
	var below: Vector4 = TORSO_RINGS[0]
	for ring: Vector4 in TORSO_RINGS:
		if ring.x >= y:
			var u: float = 0.0 if is_equal_approx(ring.x, below.x) else clampf((y - below.x) / (ring.x - below.x), 0.0, 1.0)
			return Vector3(lerpf(below.y, ring.y, u), lerpf(below.z, ring.z, u), lerpf(below.w, ring.w, u))
		below = ring
	return Vector3(below.y, below.z, below.w)


## A point `out` metres off Layer 0's surface at a height, `angle` round from the front (+ toward the hero's right).
static func _torso_point(y: float, angle: float, out: float) -> Vector3:
	var at: Vector3 = _torso_at(y)
	return Vector3(sin(angle) * (at.x + out), y, at.z - cos(angle) * (at.y + out))


## A curved plate standing `out` off Layer 0 from `top` down to `bottom`,
## `half_angle` either side of `facing` (0 the front, PI the back), `thick`
## thick: its underside sits in the AO of its lip, its lower edge rolls bright.
## `ridge` raises a medial ridge down its middle (a beveled breastplate).
static func _torso_shell(s: Sculpt, top: float, bottom: float, out: Vector2, thick: float, half_angle: float, facing: float, material: float,
		ridge: float = 0.0, extra: Dictionary = {}) -> void:
	var rings: Array[Dictionary] = []
	var steps: int = maxi(2, int(ceil((top - bottom) / 0.03)))
	for index: int in steps + 1:
		var u: float = float(index) / float(steps)
		var y: float = lerpf(top, bottom, u)
		var at: Vector3 = _torso_at(y)
		var stand: float = lerpf(out.x, out.y, u)
		var ring: Dictionary = _r(Vector3(0.0, y, at.z), at.x + stand, at.y + stand, _torso_bones(y), material, {"g": 0.85 if index == steps else 0.0})
		ring.merge(extra, true)
		rings.append(ring)
	var centre: float = PI * 0.5 + facing
	var shell_fn: Callable = func(theta: float, _t: float, w: float, d: float) -> Vector2:
		var outer: bool = theta < PI
		var u: float = theta / PI if outer else (theta - PI) / PI
		var phi: float = lerpf(centre - half_angle, centre + half_angle, u) if outer else lerpf(centre + half_angle, centre - half_angle, u)
		var bulge: float = ridge * pow(maxf(0.0, 1.0 - absf(phi - centre) / half_angle), 2.0) if outer else 0.0
		var k: float = thick * 0.5 if outer else -thick * 0.5
		return Vector2(cos(phi) * (w + k + bulge), sin(phi) * (d + k + bulge))
	var lip_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		return c if theta < PI else Color(UNDER_LIP_AO, c.g, c.b, c.a)
	_loft(s, rings, {"subdiv": 1, "sides": 28, "proxy": 0.0, "section": shell_fn, "color_fn": lip_fn})


## Layer 1: the coat's skirt, standing 18 mm off the hips and flaring to its
## hem, split up the front, with side gores and a raised rolled-leather hem.
static func _skirt(s: Sculpt, coat: StringName) -> void:
	var hem: float = COAT_HEMS[coat]
	var cloth: float = MAT_TUNIC
	match coat:
		&"hearth_linen":
			cloth = MAT_LINEN
		&"ranger_leather":
			cloth = MAT_COAT
		&"ironwood_plate":
			cloth = MAT_RING_MAIL
	var split: float = deg_to_rad(12.0)
	var heights: Array[float] = [0.97, 0.9, 0.82, lerpf(0.82, hem, 0.5), hem + 0.03, hem]
	var spans: Array[Vector2] = [Vector2(0.223, 0.183), Vector2(0.236, 0.19), Vector2(0.246, 0.198), Vector2(0.262, 0.21), Vector2(0.276, 0.22), Vector2(0.28, 0.222)]
	var rings: Array[Dictionary] = []
	for index: int in heights.size():
		var extra: Dictionary = {"ao": UNDER_LIP_AO if index == 0 else 1.0}
		rings.append(_r(Vector3(0.0, heights[index], 0.0), spans[index].x, spans[index].y, _w([B.HIPS, 1.0]), cloth, extra))
	var gap: float = split
	var skirt_fn: Callable = func(theta: float, _t: float, w: float, d: float) -> Vector2:
		var outer: bool = theta < PI
		var u: float = theta / PI if outer else (theta - PI) / PI
		# Round from just right of the front split, about the back, to just left of it.
		var from: float = PI * 0.5 + gap
		var to: float = PI * 2.5 - gap
		var phi: float = lerpf(from, to, u) if outer else lerpf(to, from, u)
		var gore: float = 0.006 * pow(maxf(0.0, cos(2.0 * phi)), 6.0)
		var k: float = 0.006 if outer else -0.006
		return Vector2(cos(phi) * (w + k + gore), sin(phi) * (d + k + gore))
	var stride_fn: Callable = func(p: Vector3, t: float, _base: Dictionary) -> Dictionary:
		var lean: float = clampf(p.x / 0.25, -1.0, 1.0)
		var left: float = t * (0.18 + 0.6 * maxf(0.0, -lean))
		var right: float = t * (0.18 + 0.6 * maxf(0.0, lean))
		return {B.HIPS: maxf(0.0, 1.0 - left - right), B.THIGH_L: left, B.THIGH_R: right}
	var lip_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		return c if theta < PI else Color(minf(c.r, 0.55), c.g, c.b, c.a)
	_loft(s, rings, {"subdiv": 1, "sides": 34, "proxy": 0.0, "section": skirt_fn, "weight_at": stride_fn, "color_fn": lip_fn})
	# The rolled-leather hem border, raised 10 mm, round the skirt's edge.
	var border: Array[Dictionary] = []
	var hem_span: Vector2 = spans.back()
	for index: int in 15:
		var phi: float = lerpf(PI * 0.5 + split, PI * 2.5 - split, float(index) / 14.0)
		var at: Vector3 = Vector3(cos(phi) * (hem_span.x + 0.006), hem + 0.006, -sin(phi) * (hem_span.y + 0.006))
		var lean: float = clampf(at.x / 0.25, -1.0, 1.0)
		var bones: Dictionary = {B.HIPS: 0.4, B.THIGH_L: 0.6 * maxf(0.0, -lean) + 0.18, B.THIGH_R: 0.6 * maxf(0.0, lean) + 0.18}
		border.append(_r(at, 0.009, 0.01, bones, MAT_LEATHER, {"g": 0.85}))
	_loft(s, border, {"subdiv": 2, "sides": 6, "cap_start": true, "cap_end": true, "side": Vector3.UP})


## The Hedgerow Wool-Mantle's stitched-leather, iron-studded brigandine plackart:
## six overlapping lames down the chest, brass rivets at their corners, and two
## leather shoulder harnesses crossing the chest through brass roller-buckles.
static func _brigandine(s: Sculpt) -> void:
	var half: float = deg_to_rad(64.0)
	for lame: int in 6:
		var top: float = 1.335 - float(lame) * 0.046
		var bottom: float = top - 0.054
		_torso_shell(s, top, bottom, Vector2(0.024, 0.033), 0.012, half, 0.0, MAT_LEATHER)
		var mid: float = (top + bottom) * 0.5
		for end: float in [-1.0, 1.0]:
			_stud(s, _torso_point(mid, end * (half - 0.12), 0.042), _torso_point(mid, end * (half - 0.12), 0.06) - _torso_point(mid, end * (half - 0.12), 0.042),
				0.009, _torso_bones(mid), MAT_BRASS)
		for column: int in 3:
			var angle: float = (float(column) - 1.0) * 0.42
			_stud(s, _torso_point(mid, angle, 0.04), (_torso_point(mid, angle, 0.06) - _torso_point(mid, angle, 0.04)), 0.006, _torso_bones(mid), MAT_IRON)
	# The shoulder harnesses: over each shoulder and down across the chest to the opposite flank, buckled high.
	for side: float in [-1.0, 1.0]:
		var path: Array[Vector3] = [Vector3(side * 0.13, 1.45, 0.02), _torso_point(1.4, side * 0.55, 0.052), _torso_point(1.33, side * 0.25, 0.05),
			_torso_point(1.24, -side * 0.05, 0.05), _torso_point(1.14, -side * 0.4, 0.05), _torso_point(1.06, -side * 0.8, 0.045)]
		var strap: Array[Dictionary] = []
		for point: Vector3 in path:
			strap.append(_r(point, 0.019, 0.004, _torso_bones(point.y), MAT_LEATHER, {"g": 0.55}))
		var chord: Vector3 = (path.back() - path[1]).normalized()
		_loft(s, strap, {"subdiv": 2, "sides": 6, "cap_start": true, "cap_end": true, "side": Vector3(-chord.y, chord.x, 0.0)})
		_buckle(s, _torso_point(1.33, side * 0.25, 0.058), _torso_bones(1.33), Vector3(-chord.y, chord.x, 0.0).normalized())


## The Wool-Mantle's heavy dagged wool capelet round the shoulders, short at the front to show the brigandine.
static func _mantle_capelet(s: Sculpt) -> void:
	var shoulder_fn: Callable = func(theta: float, t: float, _base: Dictionary) -> Dictionary:
		var reach: float = t * 0.45 * smoothstep(0.6, 0.95, absf(cos(theta)))
		return {B.CHEST: 1.0 - reach, B.UPPER_ARM_L: reach if cos(theta) < 0.0 else 0.0, B.UPPER_ARM_R: reach if cos(theta) > 0.0 else 0.0}
	var dag_fn: Callable = func(theta: float, t: float, p: Vector3) -> Vector3:
		var hem: float = smoothstep(0.7, 1.0, t)
		var front: float = smoothstep(0.3, 0.9, maxf(0.0, sin(theta)))
		return p + Vector3(0.0, (-0.04 * maxf(0.0, cos(theta * 9.0)) + 0.085 * front) * hem, 0.0)
	_loft(s, [
		_r(Vector3(0.0, 1.47, 0.0), 0.1, 0.09, _w([B.NECK, 0.5, B.CHEST, 0.5]), MAT_COAT, {"g": 0.6}),
		_r(Vector3(0.0, 1.43, 0.0), 0.218, 0.178, _w([B.CHEST, 1.0]), MAT_COAT),
		_r(Vector3(0.0, 1.355, 0.0), 0.31, 0.218, _w([B.CHEST, 1.0]), MAT_COAT),
		_r(Vector3(0.0, 1.255, 0.0), 0.334, 0.23, _w([B.CHEST, 1.0]), MAT_COAT, {"g": 1.0}),
	], {"n": 2.2, "sides": 22, "cap_start": true, "weight_fn": shoulder_fn, "offset_fn": dag_fn})


## The Iron-Wood Ring-Coat: a beveled breastplate with a medial ridge over the ring-mail, a high gorget and steel bands.
static func _breastplate(s: Sculpt) -> void:
	_torso_shell(s, 1.36, 1.06, Vector2(0.026, 0.03), 0.014, deg_to_rad(62.0), 0.0, MAT_STEEL, 0.014)
	_torso_shell(s, 1.36, 1.1, Vector2(0.026, 0.028), 0.012, deg_to_rad(70.0), PI, MAT_STEEL)
	_loft(s, [
		_r(Vector3(0.0, 1.37, 0.0), 0.15, 0.13, _w([B.CHEST, 1.0]), MAT_STEEL, {"ao": UNDER_LIP_AO}),
		_r(Vector3(0.0, 1.44, 0.0), 0.112, 0.102, _w([B.CHEST, 0.5, B.NECK, 0.5]), MAT_STEEL),
		_r(Vector3(0.0, 1.505, 0.0), 0.102, 0.097, _w([B.NECK, 1.0]), MAT_STEEL, {"g": 1.0}),
	], {"subdiv": 2, "sides": 16})
	for y: float in [1.075, 1.12]:
		var at: Vector3 = _torso_at(y)
		_loft(s, [_r(Vector3(0.0, y + 0.015, at.z), at.x + 0.034, at.y + 0.034, _torso_bones(y), MAT_STEEL, {"ao": UNDER_LIP_AO}),
			_r(Vector3(0.0, y, at.z), at.x + 0.042, at.y + 0.042, _torso_bones(y), MAT_STEEL, {"g": 1.0}),
			_r(Vector3(0.0, y - 0.015, at.z), at.x + 0.034, at.y + 0.034, _torso_bones(y), MAT_STEEL)], {"subdiv": 1, "sides": 18})


## The Bramble-Spun Jerkin: a diamond-quilted padded jack laced up each side with leather ties.
static func _padded_jack(s: Sculpt) -> void:
	var rings: Array[Dictionary] = []
	for index: int in 12:
		var y: float = lerpf(1.385, 1.03, float(index) / 11.0)
		var at: Vector3 = _torso_at(y)
		rings.append(_r(Vector3(0.0, y, at.z), at.x + 0.02, at.y + 0.02, _torso_bones(y), MAT_TUNIC,
			{"ao": UNDER_LIP_AO if index == 11 else 1.0, "g": 0.6 if index == 0 or index == 11 else 0.0}))
	var quilt_fn: Callable = func(theta: float, t: float, c: Color) -> Color:
		var a: float = sin(theta * 9.0 + t * 26.0)
		var b: float = sin(theta * 9.0 - t * 26.0)
		var stitch: float = 1.0 - smoothstep(0.75, 0.98, maxf(absf(a), absf(b)))
		return Color(c.r * lerpf(0.72, 1.0, stitch), c.g, c.b, c.a)
	var puff_fn: Callable = func(theta: float, t: float) -> float:
		return 1.0 + 0.035 * (1.0 - absf(sin(theta * 9.0 + t * 26.0))) * (1.0 - absf(sin(theta * 9.0 - t * 26.0)))
	_loft(s, rings, {"subdiv": 1, "sides": 36, "n": 2.4, "color_fn": quilt_fn, "radius_fn": puff_fn})
	for side: float in [-1.0, 1.0]:
		for lace: int in 5:
			var y: float = 1.3 - float(lace) * 0.045
			var from: Vector3 = _torso_point(y, side * 1.45, 0.028)
			var to: Vector3 = _torso_point(y - 0.035, side * 1.7, 0.028)
			_loft(s, [_r(from, 0.004, 0.004, _torso_bones(y), MAT_LEATHER, {"g": 0.6}), _r(to, 0.004, 0.004, _torso_bones(y), MAT_LEATHER, {"g": 0.6})],
				{"subdiv": 1, "sides": 5, "cap_start": true, "cap_end": true})
			_loft(s, [_r(_torso_point(y, side * 1.7, 0.028), 0.004, 0.004, _torso_bones(y), MAT_LEATHER), _r(_torso_point(y - 0.035, side * 1.45, 0.028), 0.004, 0.004, _torso_bones(y), MAT_LEATHER)],
				{"subdiv": 1, "sides": 5, "cap_start": true, "cap_end": true})


## The Hearth-Linen Coat: a pleated scribe's surcoat, a short mantle capelet and a brass carillon-clasp at the throat.
static func _pleated_surcoat(s: Sculpt) -> void:
	var rings: Array[Dictionary] = []
	for index: int in 10:
		var y: float = lerpf(1.39, 0.98, float(index) / 9.0)
		var at: Vector3 = _torso_at(y)
		rings.append(_r(Vector3(0.0, y, at.z), at.x + 0.018, at.y + 0.018, _torso_bones(y), MAT_LINEN, {"ao": UNDER_LIP_AO if index == 9 else 1.0}))
	var pleat_fn: Callable = func(theta: float, t: float) -> float: return 1.0 + 0.025 * pow(absf(sin(theta * 11.0)), 3.0) * smoothstep(0.2, 1.0, t)
	_loft(s, rings, {"subdiv": 1, "sides": 44, "n": 2.4, "radius_fn": pleat_fn})
	var short_fn: Callable = func(theta: float, t: float, p: Vector3) -> Vector3:
		return p + Vector3(0.0, 0.05 * smoothstep(0.3, 0.9, maxf(0.0, sin(theta))) * smoothstep(0.6, 1.0, t), 0.0)
	_loft(s, [
		_r(Vector3(0.0, 1.47, 0.0), 0.1, 0.09, _w([B.NECK, 0.5, B.CHEST, 0.5]), MAT_TRIM, {"g": 0.6}),
		_r(Vector3(0.0, 1.425, 0.0), 0.225, 0.18, _w([B.CHEST, 1.0]), MAT_LINEN),
		_r(Vector3(0.0, 1.32, 0.0), 0.3, 0.22, _w([B.CHEST, 1.0]), MAT_TRIM, {"g": 0.9}),
	], {"n": 2.2, "sides": 22, "cap_start": true, "offset_fn": short_fn})
	# The carillon-clasp: a little brass bell at the throat.
	_loft(s, [_r(Vector3(0.0, 1.44, -0.115), 0.008, 0.008, _w([B.CHEST, 1.0]), MAT_BRASS), _r(Vector3(0.0, 1.415, -0.122), 0.018, 0.018, _w([B.CHEST, 1.0]), MAT_BRASS),
		_r(Vector3(0.0, 1.395, -0.124), 0.024, 0.024, _w([B.CHEST, 1.0]), MAT_BRASS, {"g": 1.0, "a": 0.6})], {"sides": 10, "cap_start": true, "cap_end": true})


## A small domed stud (a rivet, a hobnail, a boss) at `center`, standing out along `outward`.
static func _stud(s: Sculpt, center: Vector3, outward: Vector3, radius: float, bones: Dictionary, material: float) -> void:
	var dir: Vector3 = outward.normalized() if outward.length() > 0.0001 else Vector3.UP
	_loft(s, [
		_r(center - dir * radius * 0.3, radius, radius, bones, material, {"ao": UNDER_LIP_AO}),
		_r(center + dir * radius * 0.35, radius * 0.8, radius * 0.8, bones, material, {"g": 0.9}),
		_r(center + dir * radius * 0.7, radius * 0.3, radius * 0.3, bones, material, {"g": 1.0}),
	], {"subdiv": 1, "sides": 6, "cap_end": true, "side": Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD})


## A strap or rolled cuff round a limb: `height` tall along `axis`, standing out to `half_w` x `half_d`, its edges rolled.
static func _band(s: Sculpt, center: Vector3, axis: Vector3, half_w: float, half_d: float, height: float, bones: Dictionary, material: float) -> void:
	var dir: Vector3 = axis.normalized()
	_loft(s, [
		_r(center - dir * height * 0.5, half_w * 0.96, half_d * 0.96, bones, material, {"ao": UNDER_LIP_AO}),
		_r(center - dir * height * 0.25, half_w, half_d, bones, material, {"g": 0.75}),
		_r(center + dir * height * 0.25, half_w, half_d, bones, material, {"g": 0.75}),
		_r(center + dir * height * 0.5, half_w * 0.96, half_d * 0.96, bones, material, {"ao": UNDER_LIP_AO}),
	], {"subdiv": 1, "sides": 14, "side": Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD})


## A brass roller-buckle on a strap: a square frame, a roller along its top bar and a tongue.
static func _buckle(s: Sculpt, center: Vector3, bones: Dictionary, across: Vector3) -> void:
	var x: Vector3 = across.normalized()
	var y: Vector3 = Vector3.UP if absf(x.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
	y = (y - x * x.dot(y)).normalized()
	var half: float = 0.017
	var corners: Array[Vector3] = [center - x * half - y * half, center + x * half - y * half, center + x * half + y * half, center - x * half + y * half]
	for index: int in 4:
		var from: Vector3 = corners[index]
		var to: Vector3 = corners[(index + 1) % 4]
		_loft(s, [_r(from, 0.0035, 0.0035, bones, MAT_BRASS, {"g": 0.9}), _r(to, 0.0035, 0.0035, bones, MAT_BRASS, {"g": 0.9})],
			{"subdiv": 1, "sides": 5, "cap_start": true, "cap_end": true})
	_loft(s, [_r(corners[3] + x * 0.002, 0.006, 0.006, bones, MAT_BRASS, {"g": 1.0}), _r(corners[2] - x * 0.002, 0.006, 0.006, bones, MAT_BRASS, {"g": 1.0})],
		{"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true})
	_loft(s, [_r(center + y * half, 0.0025, 0.0025, bones, MAT_IRON), _r(center - y * half * 0.6, 0.0025, 0.0025, bones, MAT_IRON)],
		{"subdiv": 1, "sides": 4, "cap_start": true, "cap_end": true})


# --- Weapon sculpts (§5.3) -----------------------------------------------------

static func _sculpt_falchion(s: Sculpt, tier: int) -> void:
	var length: float = weapon_length(EquipmentItemResource.WeaponType.LIGHT_SWORD)
	var thick: float = 0.016 if tier == 1 else 0.011
	var fullered: bool = tier >= 3
	var veins: float = 1.0 if tier == 4 else 0.0
	# A broad single-edged blade, its edge toward -Z, a clipped point; diamond in section (chamfered).
	var bevel_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		# A bright honed bevel along the cutting edge (-Z), from Hedgerow Iron up.
		return Color(c.r, 1.0, MAT_STEEL, c.a) if tier >= 2 and sin(theta) < -0.8 else c
	var fuller_fn: Callable = func(theta: float, t: float, p: Vector3) -> Vector3:
		if not fullered or t < 0.12 or t > 0.72:
			return p
		return Vector3(p.x * (1.0 - 0.55 * exp(-pow(sin(theta) / 0.35, 2.0))), p.y, p.z)
	_loft(s, [
		_r(Vector3(0.0, 0.13, 0.0), thick, 0.034, {}, MAT_IRON, {"n": 1.25}),
		_r(Vector3(0.0, 0.4, -0.004), thick, 0.041, {}, MAT_IRON, {"n": 1.25, "a": veins}),
		_r(Vector3(0.0, 0.68, -0.01), thick * 0.95, 0.05, {}, MAT_IRON, {"n": 1.25, "a": veins}),
		_r(Vector3(0.0, 0.84, -0.012), thick * 0.9, 0.046, {}, MAT_IRON, {"n": 1.25}),
		_r(Vector3(0.0, 0.92, 0.0), thick * 0.7, 0.03, {}, MAT_IRON, {"n": 1.25}),
		_r(Vector3(0.0, length, 0.018), 0.003, 0.006, {}, MAT_IRON, {"n": 1.25}),
	], {"sides": 12, "cap_start": true, "cap_end": true, "color_fn": bevel_fn, "offset_fn": fuller_fn})
	_sword_grip(s, tier, 0.125)


## A one-hander's guard, grip and pommel at each tier.
static func _sword_grip(s: Sculpt, tier: int, guard_y: float) -> void:
	var grip_mats: Array[float] = [MAT_ROPE, MAT_TIMBER, MAT_LEATHER, MAT_BOOT]
	var grip_mat: float = grip_mats[tier - 1]
	var wrap_fn: Callable = func(theta: float, t: float, c: Color) -> Color:
		# Criss-cross wraps: hemp cord, oak, a diamond-wrapped ox-hide grip, dark leather.
		var wrap: float = 0.5 + 0.5 * sin(t * 28.0 + theta * (2.0 if tier == 3 else 1.0))
		return Color(lerpf(0.7, 1.0, wrap), c.g, c.b, c.a)
	_loft(s, [_r(Vector3(0.0, -0.09, 0.0), 0.018, 0.018, {}, grip_mat), _r(Vector3(0.0, 0.0, 0.0), 0.02, 0.02, {}, grip_mat),
		_r(Vector3(0.0, guard_y - 0.012, 0.0), 0.018, 0.018, {}, grip_mat)], {"sides": 10, "color_fn": wrap_fn})
	match tier:
		1:
			_loft(s, [_r(Vector3(0.0, guard_y, -0.07), 0.022, 0.018, {}, MAT_TIMBER, {"n": 3.0}), _r(Vector3(0.0, guard_y, 0.07), 0.022, 0.018, {}, MAT_TIMBER, {"n": 3.0, "g": 0.7})],
				{"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
			for y: float in [guard_y - 0.03, guard_y - 0.06]:
				_loft(s, [_r(Vector3(0.0, y + 0.006, 0.0), 0.024, 0.024, {}, MAT_ROPE), _r(Vector3(0.0, y - 0.006, 0.0), 0.024, 0.024, {}, MAT_ROPE, {"g": 0.6})], {"subdiv": 1, "sides": 8})
			_ellipsoid(s, Vector3(0.0, -0.105, 0.0), Vector3(0.024, 0.024, 0.024), {}, MAT_TIMBER, Vector3.DOWN)
			# The sprouting oak-leaf twig tied to the pommel.
			_loft(s, [_r(Vector3(0.0, -0.125, 0.0), 0.004, 0.004, {}, MAT_TIMBER), _r(Vector3(0.02, -0.16, 0.012), 0.016, 0.003, {}, MAT_TUNIC),
				_r(Vector3(0.035, -0.19, 0.02), 0.002, 0.002, {}, MAT_TUNIC)], {"sides": 6, "cap_end": true})
		2:
			_loft(s, [_r(Vector3(0.0, guard_y, -0.095), 0.02, 0.022, {}, MAT_IRON, {"n": 4.0}), _r(Vector3(0.0, guard_y, 0.095), 0.02, 0.022, {}, MAT_IRON, {"n": 4.0, "g": 0.8})],
				{"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
			for side: float in [-1.0, 1.0]:
				_ellipsoid(s, Vector3(side * 0.022, guard_y, 0.0), Vector3(0.008, 0.01, 0.01), {}, MAT_BRASS, Vector3.RIGHT * side)
			_ellipsoid(s, Vector3(0.0, -0.105, 0.0), Vector3(0.026, 0.024, 0.026), {}, MAT_IRON, Vector3.DOWN)
		3:
			# A resonant cast-brass bell-guard.
			_loft(s, [_r(Vector3(0.0, guard_y - 0.03, 0.0), 0.03, 0.03, {}, MAT_BRASS), _r(Vector3(0.0, guard_y, 0.0), 0.068, 0.068, {}, MAT_BRASS, {"g": 1.0}),
				_r(Vector3(0.0, guard_y + 0.012, 0.0), 0.05, 0.05, {}, MAT_BRASS)], {"subdiv": 2, "sides": 16, "cap_start": true, "cap_end": true})
			_ellipsoid(s, Vector3(0.0, -0.105, 0.0), Vector3(0.028, 0.028, 0.028), {}, MAT_BRASS, Vector3.DOWN)
		4:
			# Scroll-forged gilded bronze: curled quillons round an open cage that holds the Sign-stone.
			for side: float in [-1.0, 1.0]:
				_loft(s, [
					_r(Vector3(0.0, guard_y, side * 0.03), 0.014, 0.014, {}, MAT_BRASS),
					_r(Vector3(0.0, guard_y + 0.01, side * 0.1), 0.012, 0.012, {}, MAT_BRASS, {"g": 0.8}),
					_r(Vector3(0.0, guard_y + 0.05, side * 0.12), 0.01, 0.01, {}, MAT_BRASS),
					_r(Vector3(0.0, guard_y + 0.07, side * 0.09), 0.008, 0.008, {}, MAT_BRASS, {"g": 1.0}),
				], {"sides": 8, "cap_end": true})
			for bar: int in 4:
				var angle: float = TAU * float(bar) / 4.0 + PI * 0.25
				var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * 0.04
				_loft(s, [_r(Vector3(0.0, guard_y - 0.03, 0.0) + out * 0.5, 0.006, 0.006, {}, MAT_BRASS), _r(Vector3(0.0, guard_y, 0.0) + out, 0.006, 0.006, {}, MAT_BRASS, {"a": 0.6}),
					_r(Vector3(0.0, guard_y + 0.03, 0.0) + out * 0.5, 0.006, 0.006, {}, MAT_BRASS)], {"sides": 6})
			_ellipsoid(s, Vector3(0.0, -0.105, 0.0), Vector3(0.026, 0.03, 0.026), {}, MAT_BRASS, Vector3.DOWN)


static func _sculpt_broad_axe(s: Sculpt, tier: int) -> void:
	# The long haft: split ash at Tier 1, then oak-and-ash with an iron butt-cap.
	var butt: float = MAT_TIMBER if tier == 1 else MAT_IRON
	_loft(s, [
		_r(Vector3(0.0, -0.13, 0.0), 0.022, 0.022, {}, butt, {"g": 0.8}),
		_r(Vector3(0.0, -0.1, 0.0), 0.024, 0.024, {}, MAT_BOOT if tier > 1 else MAT_ROPE),
		_r(Vector3(0.0, 0.1, 0.0), 0.022, 0.022, {}, MAT_BOOT if tier > 1 else MAT_ROPE),
		_r(Vector3(0.0, 0.14, 0.0), 0.02, 0.02, {}, MAT_TIMBER),
		_r(Vector3(0.0, 0.6, 0.0), 0.019, 0.019, {}, MAT_TIMBER),
		_r(Vector3(0.0, 1.0, 0.0), 0.021, 0.021, {}, MAT_TIMBER),
		_r(Vector3(0.0, 1.03, 0.0), 0.014, 0.014, {}, MAT_TIMBER),
	], {"sides": 10, "cap_start": true, "cap_end": true})
	var head_y: float = 0.91
	match tier:
		1:
			# A lathe-turned hazel wedge-head lashed on with hemp.
			_axe_bit(s, head_y, 0.2, 0.1, 0.03, MAT_IRON, 0.0)
			for y: float in [head_y - 0.06, head_y + 0.06]:
				_loft(s, [_r(Vector3(0.0, y + 0.008, 0.0), 0.028, 0.028, {}, MAT_ROPE), _r(Vector3(0.0, y - 0.008, 0.0), 0.028, 0.028, {}, MAT_ROPE, {"g": 0.6})], {"subdiv": 1, "sides": 8})
		2:
			# A bearded, hand-hammered iron head, a honed bevel, brass rivets in its cheek.
			_axe_bit(s, head_y, 0.22, 0.12, 0.026, MAT_IRON, 0.06)
			_axe_poll(s, head_y, 0.05)
			for z: float in [-0.04, -0.09]:
				for side: float in [-1.0, 1.0]:
					_ellipsoid(s, Vector3(side * 0.025, head_y, z), Vector3(0.007, 0.01, 0.01), {}, MAT_BRASS, Vector3.RIGHT * side)
		3:
			# Reinforced double-bitted wings of milled steel and a brass collar.
			_axe_bit(s, head_y, 0.24, 0.14, 0.024, MAT_IRON, 0.04)
			_axe_bit(s, head_y, -0.14, 0.1, 0.022, MAT_IRON, 0.0)
			_loft(s, [_r(Vector3(0.0, head_y - 0.12, 0.0), 0.026, 0.026, {}, MAT_BRASS), _r(Vector3(0.0, head_y - 0.09, 0.0), 0.03, 0.03, {}, MAT_BRASS, {"g": 1.0}),
				_r(Vector3(0.0, head_y - 0.07, 0.0), 0.026, 0.026, {}, MAT_BRASS)], {"subdiv": 1, "sides": 12})
		4:
			# A gilded bronze crescent with an open axe-eye cage round the Sign-stone.
			_axe_bit(s, head_y, 0.28, 0.24, 0.022, MAT_IRON, 0.08)
			_axe_poll(s, head_y, 0.06)
			_loft(s, [
				_r(Vector3(0.0, head_y + 0.05, -0.09), 0.01, 0.01, {}, MAT_BRASS, {"a": 1.0}),
				_r(Vector3(0.0, head_y, -0.14), 0.01, 0.01, {}, MAT_BRASS, {"a": 1.0}),
				_r(Vector3(0.0, head_y - 0.05, -0.09), 0.01, 0.01, {}, MAT_BRASS, {"a": 1.0}),
				_r(Vector3(0.0, head_y, -0.04), 0.01, 0.01, {}, MAT_BRASS, {"a": 1.0}),
				_r(Vector3(0.0, head_y + 0.05, -0.09), 0.01, 0.01, {}, MAT_BRASS, {"a": 1.0}),
			], {"sides": 6, "subdiv": 3})


## An axe bit from the haft toward -Z (`reach` metres; a negative reach is a back
## bit), `height` tall at its edge, `thick` at the eye, `beard` dropping its lower horn.
static func _axe_bit(s: Sculpt, y: float, reach: float, height: float, thick: float, material: float, beard: float) -> void:
	var dir: float = -signf(reach)
	var span: float = absf(reach)
	var beard_fn: Callable = func(theta: float, t: float, p: Vector3) -> Vector3:
		# The bearded lower horn hooks down toward the edge.
		return p + Vector3(0.0, -beard * t * t * maxf(0.0, -sin(theta)), 0.0)
	_loft(s, [
		_r(Vector3(0.0, y, 0.0), thick, 0.05, {}, material, {"n": 3.0}),
		_r(Vector3(0.0, y, dir * span * 0.45), thick * 0.75, height * 0.55, {}, material, {"n": 3.0}),
		_r(Vector3(0.0, y - beard * 0.5, dir * span * 0.85), thick * 0.4, height * 0.9, {}, material, {"n": 3.0}),
		_r(Vector3(0.0, y - beard * 0.6, dir * span), 0.003, height, {}, MAT_STEEL, {"n": 3.0, "g": 1.0}),
	], {"sides": 10, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT, "offset_fn": beard_fn})


static func _axe_poll(s: Sculpt, y: float, length: float) -> void:
	_loft(s, [_r(Vector3(0.0, y, 0.0), 0.03, 0.045, {}, MAT_IRON, {"n": 4.0}), _r(Vector3(0.0, y, length), 0.028, 0.035, {}, MAT_IRON, {"n": 4.0, "g": 1.0})],
		{"subdiv": 1, "sides": 8, "cap_end": true, "side": Vector3.RIGHT})


static func _sculpt_way_staff(s: Sculpt, tier: int) -> void:
	var length: float = weapon_length(EquipmentItemResource.WeaponType.STAFF)
	# The rowan shaft, a butt-cap and a grip wrap.
	_loft(s, [
		_r(Vector3(0.0, -0.75, 0.0), 0.016, 0.016, {}, MAT_IRON if tier > 1 else MAT_TIMBER, {"g": 1.0}),
		_r(Vector3(0.0, -0.7, 0.0), 0.02, 0.02, {}, MAT_TIMBER),
		_r(Vector3(0.0, -0.06, 0.0), 0.021, 0.021, {}, MAT_LINEN),
		_r(Vector3(0.0, 0.08, 0.0), 0.021, 0.021, {}, MAT_LINEN),
		_r(Vector3(0.0, 0.12, 0.0), 0.02, 0.02, {}, MAT_TIMBER),
		_r(Vector3(0.0, length - 0.15, 0.0), 0.018, 0.018, {}, MAT_TIMBER),
		_r(Vector3(0.0, length - 0.12, 0.0), 0.012, 0.012, {}, MAT_TIMBER),
	], {"sides": 10, "cap_start": true, "cap_end": true})
	var head: float = length - 0.13
	# The forked crook cradling the seed (or, on a relic, the carillon cage round the Sign-stone).
	for side: float in [-1.0, 1.0]:
		var prong: float = MAT_TIMBER if tier == 1 else MAT_BRASS
		_loft(s, [
			_r(Vector3(0.0, head, 0.0), 0.012, 0.012, {}, prong),
			_r(Vector3(side * 0.06, head + 0.08, 0.0), 0.01, 0.01, {}, prong, {"a": 1.0 if tier == 4 else 0.0}),
			_r(Vector3(side * 0.045, head + 0.17, 0.0), 0.008, 0.008, {}, prong, {"g": 0.8}),
			_r(Vector3(side * 0.01, head + 0.2 + 0.03 * float(tier == 4), 0.0), 0.005, 0.005, {}, prong),
		], {"sides": 6, "cap_end": true})
	if tier >= 2:
		for y: float in [head - 0.04, 0.16, -0.62]:
			_loft(s, [_r(Vector3(0.0, y + 0.012, 0.0), 0.024, 0.024, {}, MAT_BRASS), _r(Vector3(0.0, y - 0.012, 0.0), 0.024, 0.024, {}, MAT_BRASS, {"g": 1.0})], {"subdiv": 1, "sides": 10})
	if tier == 3:
		# A brass chime-bell under the crook.
		_loft(s, [_r(Vector3(0.05, head + 0.02, 0.0), 0.006, 0.006, {}, MAT_BRASS), _r(Vector3(0.05, head - 0.03, 0.0), 0.02, 0.02, {}, MAT_BRASS),
			_r(Vector3(0.05, head - 0.07, 0.0), 0.034, 0.034, {}, MAT_BRASS, {"g": 1.0})], {"sides": 12, "cap_start": true, "cap_end": true})
	if tier == 4:
		for side: float in [-1.0, 1.0]:
			_loft(s, [_r(Vector3(0.0, head, 0.0), 0.008, 0.008, {}, MAT_BRASS), _r(Vector3(0.0, head + 0.09, side * 0.06), 0.008, 0.008, {}, MAT_BRASS, {"a": 1.0}),
				_r(Vector3(0.0, head + 0.21, side * 0.01), 0.006, 0.006, {}, MAT_BRASS)], {"sides": 6, "cap_end": true})


static func _sculpt_longbow(s: Sculpt, tier: int) -> void:
	var half: float = weapon_length(EquipmentItemResource.WeaponType.BOW) * (1.0 + 0.04 * float(tier - 1))
	var limb: float = MAT_IRON if tier == 4 else MAT_TIMBER
	# Braced limbs bow away from the string (+Z, the archer's side); the riser is the grip.
	var limb_rings: Array[Dictionary] = []
	for index: int in 9:
		var u: float = lerpf(-1.0, 1.0, float(index) / 8.0)
		var bend: float = 0.12 * (1.0 - u * u)
		var taper: float = 1.0 - 0.55 * absf(u)
		var grip: bool = absf(u) < 0.13
		limb_rings.append(_r(Vector3(0.0, u * half, 0.12 - bend), 0.022 * taper + (0.006 if grip else 0.0), 0.03 * taper + (0.008 if grip else 0.0), {},
			MAT_LINEN if grip else limb, {"g": 0.6 if absf(u) > 0.95 else 0.0}))
	_loft(s, limb_rings, {"sides": 10, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	if tier == 2:
		# Horn-tipped: a curved horn overlay capping each limb's end.
		for sign_y: float in [-1.0, 1.0]:
			_loft(s, [_r(Vector3(0.0, sign_y * half * 0.86, 0.12 - 0.12 * (1.0 - 0.74)), 0.014, 0.02, {}, MAT_LINEN),
				_r(Vector3(0.0, sign_y * half * 0.97, 0.12 - 0.12 * (1.0 - 0.94)), 0.012, 0.016, {}, MAT_LINEN, {"g": 0.8})],
				{"subdiv": 1, "sides": 8, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	if tier >= 3:
		# Steel-backed limbs: a strip down the back of each.
		for sign_y: float in [-1.0, 1.0]:
			var strip: Array[Dictionary] = []
			for index: int in 5:
				var u: float = lerpf(0.18, 0.92, float(index) / 4.0) * sign_y
				strip.append(_r(Vector3(0.0, u * half, 0.12 - 0.12 * (1.0 - u * u) - 0.028 * (1.0 - 0.55 * absf(u))), 0.009, 0.005, {}, MAT_STEEL, {"g": 0.8}))
			_loft(s, strip, {"sides": 6, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT})
	if tier == 4:
		# A gilded cage round the riser that holds the Sign-stone.
		for side: float in [-1.0, 1.0]:
			_loft(s, [_r(Vector3(0.0, 0.09, 0.0), 0.006, 0.006, {}, MAT_BRASS), _r(Vector3(side * 0.045, 0.0, -0.035), 0.006, 0.006, {}, MAT_BRASS, {"a": 1.0}),
				_r(Vector3(0.0, -0.09, 0.0), 0.006, 0.006, {}, MAT_BRASS)], {"sides": 6, "subdiv": 3})
	# Nocks: hemp-bound timber, horn, steel, gilded tips.
	var nocks: Array[float] = [MAT_ROPE, MAT_LINEN, MAT_STEEL, MAT_BRASS]
	var nock: float = nocks[tier - 1]
	for sign_y: float in [-1.0, 1.0]:
		_ellipsoid(s, Vector3(0.0, sign_y * half, 0.12), Vector3(0.016, 0.024, 0.016) * (1.0 + 0.12 * float(tier - 1)), {}, nock, Vector3.UP * sign_y)


static func _build_bowstring(root: Node3D, length: float) -> void:
	var half: float = length
	var string: Node3D = Node3D.new()
	string.name = "BowString"
	root.add_child(string)
	var tier: int = int(root.get_meta(&"tier_level", 1))
	half *= 1.0 + 0.04 * float(tier - 1)
	_marker(string, "NockTop", Vector3(0.0, half, 0.12))
	_marker(string, "NockBottom", Vector3(0.0, -half, 0.12))
	_marker(string, "BowStringMid", Vector3(0.0, 0.0, 0.12))
	var cord: StandardMaterial3D = StandardMaterial3D.new()
	cord.albedo_color = Color(0.95, 0.93, 0.86)
	for part: String in ["StringTop", "StringBottom"]:
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.name = part
		var mesh: CylinderMesh = CylinderMesh.new()
		mesh.top_radius = 0.004
		mesh.bottom_radius = 0.004
		mesh.height = 1.0
		mesh.radial_segments = 4
		mesh.rings = 1
		mesh.material = cord
		segment.mesh = mesh
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		string.add_child(segment)
	update_bowstring(root)


## Lays the bowstring's two segments from each nock to its mid-point (the draw hand moves the mid-point).
static func update_bowstring(weapon: Node3D) -> void:
	var string: Node3D = weapon.get_node_or_null(^"BowString") as Node3D
	if string == null:
		return
	var mid: Vector3 = (string.get_node(^"BowStringMid") as Node3D).position
	for pair: Array in [["StringTop", "NockTop"], ["StringBottom", "NockBottom"]]:
		var segment: MeshInstance3D = string.get_node(NodePath(String(pair[0]))) as MeshInstance3D
		var nock: Vector3 = (string.get_node(NodePath(String(pair[1]))) as Node3D).position
		var span: Vector3 = mid - nock
		var length: float = maxf(span.length(), 0.001)
		var up: Vector3 = span / length
		var side: Vector3 = Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var x: Vector3 = side.cross(up).normalized()
		segment.transform = Transform3D(Basis(x, up * length, up.cross(x).normalized()), (nock + mid) * 0.5)


# --- Loft engine ----------------------------------------------------------------

## A ring of a loft: centre `c`, half-width `w` along the loft's side axis and
## half-depth `d` across it, skinned to `bones` ({bone index: weight}), material `m`.
## `extra` may set "n" (superellipse exponent), "ao", "g" (edge), "a" (vein).
static func _r(c: Vector3, w: float, d: float, bones: Dictionary, m: float, extra: Dictionary = {}) -> Dictionary:
	var ring: Dictionary = {"c": c, "w": w, "d": d, "b": bones, "m": m, "n": 2.0, "ao": 1.0, "g": 0.0, "a": 0.0}
	ring.merge(extra, true)
	return ring


## Bone weights from a flat [bone, weight, bone, weight ...] list.
static func _w(pairs: Array) -> Dictionary:
	var weights: Dictionary = {}
	for index: int in range(0, pairs.size() - 1, 2):
		weights[int(pairs[index])] = float(pairs[index + 1])
	return weights


## The face's portrait zones at a point at rest (19B §2): the malar flush over
## the nose, cheeks and ear tips, the forehead's warm ochre, and the cool
## undertone along the jaw and under the eyes, each 0 to 1.
static func _face_zone(p: Vector3) -> Vector3:
	var front: float = smoothstep(-0.02, -0.09, p.z)
	var forehead: float = smoothstep(1.625, 1.665, p.y) * (1.0 - smoothstep(1.71, 1.74, p.y)) * front
	var nose: float = exp(-pow(p.x / 0.03, 2.0)) * exp(-pow((p.y - 1.575) / 0.03, 2.0)) * smoothstep(-0.12, -0.16, p.z)
	var cheeks: float = exp(-pow((absf(p.x) - 0.08) / 0.03, 2.0)) * exp(-pow((p.y - 1.567) / 0.022, 2.0)) * front
	var ears: float = smoothstep(0.13, 0.15, absf(p.x)) * smoothstep(1.59, 1.625, p.y)
	var malar: float = clampf(nose + cheeks + ears, 0.0, 1.0)
	var under_eyes: float = exp(-pow((absf(p.x) - 0.052) / 0.025, 2.0)) * exp(-pow((p.y - 1.583) / 0.008, 2.0)) * front * 0.6
	var cool: float = clampf((1.0 - smoothstep(1.505, 1.545, p.y)) * front + under_eyes, 0.0, 1.0)
	return Vector3(malar, forehead, cool)


## Lofts closed superellipse rings along a Catmull-Rom spine through `control`.
## Options: "sides", "subdiv", "side" (the width axis's reference), "n",
## "cap_start" / "cap_end", "proxy" (normal blend), and Callables "section"
## (theta, t, w, d) -> Vector2, "radius_fn" (theta, t) -> float, "offset_fn"
## (theta, t, p) -> Vector3, "weight_fn" (theta, t, bones) -> Dictionary,
## "color_fn" (theta, t, color) -> Color; "weight_at" (point, t, bones) -> Dictionary
## (weights by where a vertex is); "face_zones" writes the face's portrait zones
## into its MAT_FACE vertices' UVs; "quilt" stripes the AO for quilting.
static func _loft(s: Sculpt, control: Array[Dictionary], options: Dictionary = {}) -> void:
	var sides: int = options.get("sides", SIDES)
	var subdiv: int = options.get("subdiv", SUBDIV)
	var side_ref: Vector3 = options.get("side", Vector3.RIGHT)
	var proxy: float = options.get("proxy", PROXY_NORMAL_BLEND)
	var section: Callable = options.get("section", Callable())
	var radius_fn: Callable = options.get("radius_fn", Callable())
	var offset_fn: Callable = options.get("offset_fn", Callable())
	var weight_fn: Callable = options.get("weight_fn", Callable())
	var weight_at: Callable = options.get("weight_at", Callable())
	var face_zones: bool = options.get("face_zones", false)
	var color_fn: Callable = options.get("color_fn", Callable())
	var quilt: bool = options.get("quilt", false)
	var exponent_override: float = options.get("n", 0.0)
	var rings: Array[Dictionary] = _subdivide(control, subdiv)
	var count: int = rings.size()
	if count < 2:
		return
	# Frames along the spine.
	var centers: PackedVector3Array = PackedVector3Array()
	for ring: Dictionary in rings:
		centers.append(ring["c"])
	var grid: Array[PackedVector3Array] = []
	var along: PackedFloat32Array = PackedFloat32Array()
	var travelled: float = 0.0
	for i: int in count:
		if i > 0:
			travelled += centers[i].distance_to(centers[i - 1])
		along.append(travelled)
	for i: int in count:
		var ring: Dictionary = rings[i]
		var tangent: Vector3 = (centers[mini(i + 1, count - 1)] - centers[maxi(i - 1, 0)]).normalized()
		if tangent.length_squared() < 0.5:
			tangent = Vector3.UP
		var reference: Vector3 = side_ref
		if absf(tangent.dot(reference.normalized())) > 0.95:
			reference = Vector3.FORWARD if absf(tangent.dot(Vector3.FORWARD)) < 0.95 else Vector3.UP
		var x_axis: Vector3 = (reference - tangent * tangent.dot(reference)).normalized()
		var d_axis: Vector3 = x_axis.cross(tangent).normalized()
		var t: float = along[i] / maxf(travelled, 0.0001)
		var w: float = ring["w"]
		var d: float = ring["d"]
		var n: float = exponent_override if exponent_override > 0.0 else float(ring["n"])
		var points: PackedVector3Array = PackedVector3Array()
		for j: int in sides + 1:
			var theta: float = TAU * float(j % sides) / float(sides)
			var offset2: Vector2
			if section.is_valid():
				offset2 = section.call(theta, t, w, d)
			else:
				var cs: float = cos(theta)
				var sn: float = sin(theta)
				var e: float = 2.0 / n
				offset2 = Vector2(signf(cs) * pow(absf(cs), e) * w, signf(sn) * pow(absf(sn), e) * d)
			if radius_fn.is_valid():
				offset2 *= float(radius_fn.call(theta, t))
			var p: Vector3 = centers[i] + x_axis * offset2.x + d_axis * offset2.y
			if offset_fn.is_valid():
				p = offset_fn.call(theta, t, p)
			points.append(p)
		grid.append(points)
	# Normals by finite differences, turned outward once for the whole loft, leaning to the radial proxy.
	var orientation: float = 1.0
	var probe_ring: int = clampi(count / 2, 0, count - 1)
	var probe_j: int = sides / 4
	var probe_n: Vector3 = _grid_normal(grid, probe_ring, probe_j, sides, count)
	if probe_n.dot(grid[probe_ring][probe_j] - centers[probe_ring]) < 0.0:
		orientation = -1.0
	var first_index: int = s.count
	for i: int in count:
		var ring: Dictionary = rings[i]
		var t: float = along[i] / maxf(travelled, 0.0001)
		var perimeter: float = TAU * sqrt((pow(float(ring["w"]), 2.0) + pow(float(ring["d"]), 2.0)) * 0.5)
		var base_color: Color = Color(ring["ao"], ring["g"], ring["m"], ring["a"])
		if quilt:
			base_color.r *= 0.82 + 0.18 * (0.5 + 0.5 * cos(centers[i].y * TAU / 0.06))
		for j: int in sides + 1:
			var theta: float = TAU * float(j % sides) / float(sides)
			var p: Vector3 = grid[i][j]
			var normal: Vector3 = _grid_normal(grid, i, j, sides, count) * orientation
			var radial: Vector3 = (p - centers[i]).normalized()
			if radial.length_squared() > 0.5 and proxy > 0.0:
				normal = (normal * (1.0 - proxy) + radial * proxy).normalized()
			var color: Color = base_color
			if color_fn.is_valid():
				color = color_fn.call(theta, t, color)
			var bones: Dictionary = ring["b"]
			if weight_fn.is_valid():
				bones = weight_fn.call(theta, t, bones)
			if weight_at.is_valid():
				bones = weight_at.call(p, t, bones)
			var uv: Vector2 = Vector2(float(j) / float(sides) * perimeter, along[i])
			var uv2: Vector2 = Vector2(p.y, t)
			if face_zones and absf(color.b - MAT_FACE) < 0.005:
				# The face's portrait zones ride in its UVs: the malar flush, the forehead's warmth, the jaw's cool.
				var zone: Vector3 = _face_zone(p)
				uv = Vector2(zone.x, zone.y)
				uv2.y = zone.z
			s.vertex(p, normal, uv, uv2, color, bones)
	for i: int in count - 1:
		for j: int in sides:
			var a: int = first_index + i * (sides + 1) + j
			var b: int = a + 1
			var c: int = a + sides + 1
			var e: int = c + 1
			s.tri(a, c, b)
			s.tri(b, c, e)
	if options.get("cap_start", false):
		_cap(s, first_index, rings[0], centers[0], -(centers[1] - centers[0]).normalized(), sides)
	if options.get("cap_end", false):
		_cap(s, first_index + (count - 1) * (sides + 1), rings[count - 1], centers[count - 1], (centers[count - 1] - centers[count - 2]).normalized(), sides)


static func _grid_normal(grid: Array[PackedVector3Array], i: int, j: int, sides: int, count: int) -> Vector3:
	var next_j: int = j + 1 if j < sides else 1
	var prev_j: int = j - 1 if j > 0 else sides - 1
	var around: Vector3 = grid[i][next_j] - grid[i][prev_j]
	var up: Vector3 = grid[mini(i + 1, count - 1)][j] - grid[maxi(i - 1, 0)][j]
	var normal: Vector3 = around.cross(up)
	if normal.length_squared() < 1e-12:
		return Vector3.UP
	return normal.normalized()


## Closes a loft's end with a gently domed fan.
static func _cap(s: Sculpt, ring_start: int, ring: Dictionary, center: Vector3, outward: Vector3, sides: int) -> void:
	var bulge: float = minf(float(ring["w"]), float(ring["d"])) * 0.3
	var tip: Vector3 = center + outward * bulge
	var color: Color = Color(ring["ao"], ring["g"], ring["m"], ring["a"])
	var hub: int = s.vertex(tip, outward, Vector2.ZERO, Vector2(tip.y, 0.0), color, ring["b"])
	for j: int in sides:
		s.tri(hub, ring_start + j, ring_start + j + 1)


## Control rings with Catmull-Rom rings between them.
static func _subdivide(control: Array[Dictionary], steps: int) -> Array[Dictionary]:
	if steps <= 1 or control.size() < 2:
		return control.duplicate()
	var out: Array[Dictionary] = []
	var last: int = control.size() - 1
	for i: int in last:
		var p0: Dictionary = control[maxi(i - 1, 0)]
		var p1: Dictionary = control[i]
		var p2: Dictionary = control[i + 1]
		var p3: Dictionary = control[mini(i + 2, last)]
		for k: int in steps:
			var u: float = float(k) / float(steps)
			if k == 0:
				out.append(p1)
				continue
			var ring: Dictionary = p1.duplicate()
			ring["c"] = _catmull(p0["c"], p1["c"], p2["c"], p3["c"], u)
			for key: String in ["w", "d"]:
				ring[key] = maxf(0.0005, _catmull_f(p0[key], p1[key], p2[key], p3[key], u))
			for key: String in ["n", "ao", "g", "a"]:
				ring[key] = lerpf(p1[key], p2[key], u)
			ring["m"] = p1["m"] if u < 0.5 else p2["m"]
			ring["b"] = _blend_bones(p1["b"], p2["b"], u)
			out.append(ring)
	out.append(control[last])
	return out


static func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)


static func _catmull_f(p0: float, p1: float, p2: float, p3: float, u: float) -> float:
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)


static func _blend_bones(a: Dictionary, b: Dictionary, u: float) -> Dictionary:
	var blended: Dictionary = {}
	for bone: Variant in a:
		blended[bone] = float(a[bone]) * (1.0 - u)
	for bone: Variant in b:
		blended[bone] = float(blended.get(bone, 0.0)) + float(b[bone]) * u
	return blended


## An ellipsoid of half-extents `half` (x, y, z) at `center`, lofted along `axis`.
static func _ellipsoid(s: Sculpt, center: Vector3, half: Vector3, bones: Dictionary, material: float, axis: Vector3, extra: Dictionary = {},
		options: Dictionary = {}) -> void:
	var along: float = absf(axis.normalized().dot(half))
	var dir: Vector3 = axis.normalized()
	var across_w: float = half.x if absf(dir.x) < 0.5 else half.z
	var across_d: float = half.y if absf(dir.y) < 0.5 else half.z
	var rings: Array[Dictionary] = []
	for index: int in 7:
		var u: float = lerpf(-1.0, 1.0, float(index) / 6.0)
		var r: float = sqrt(maxf(0.0, 1.0 - u * u * 0.97))
		rings.append(_r(center + dir * u * along, maxf(0.002, across_w * r), maxf(0.002, across_d * r), bones, material, extra))
	var loft_options: Dictionary = {"subdiv": 1, "sides": 10, "cap_start": true, "cap_end": true, "side": Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD}
	loft_options.merge(options, true)
	_loft(s, rings, loft_options)


## A pauldron's dome: an ellipsoid of half-extents `half` (out, up, across)
## along `outward`, in `material` with a `rim` round its lower edge.
static func _dome(s: Sculpt, center: Vector3, half: Vector3, bones: Dictionary, material: float, rim: float, outward: Vector3) -> void:
	var rings: Array[Dictionary] = []
	for index: int in 7:
		var u: float = lerpf(-1.0, 1.0, float(index) / 6.0)
		var r: float = sqrt(maxf(0.0, 1.0 - u * u * 0.96))
		rings.append(_r(center + outward * u * half.x, maxf(0.002, half.z * r), maxf(0.002, half.y * r), bones, material, {"ao": 0.75 if index == 0 else 1.0}))
	var rim_fn: Callable = func(theta: float, _t: float, c: Color) -> Color:
		# Rimmed round its edge, the rim's worn chamfer catching the light.
		return Color(c.r, 1.0, rim, c.a) if absf(sin(theta)) < 0.3 else c
	_loft(s, rings, {"subdiv": 1, "sides": 16, "cap_start": true, "cap_end": true, "side": Vector3.FORWARD, "color_fn": rim_fn})


## A small raised lozenge (a diamond) facing `facing`: a crest or a badge, its recess lit in the Sign.
static func _lozenge(s: Sculpt, center: Vector3, facing: Vector3, half_w: float, half_h: float, depth: float, bones: Dictionary, material: float, vein: float) -> void:
	var dir: Vector3 = facing.normalized()
	_loft(s, [
		_r(center - dir * depth * 0.5, half_w, half_h, bones, material, {"n": 1.0}),
		_r(center + dir * depth * 0.3, half_w * 0.95, half_h * 0.95, bones, material, {"n": 1.0, "g": 1.0}),
		_r(center + dir * depth * 0.5, half_w * 0.6, half_h * 0.6, bones, material, {"n": 1.0, "a": vein}),
	], {"subdiv": 1, "sides": 8, "cap_end": true, "side": Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD})


static func _marker(parent: Node3D, marker_name: String, where: Vector3) -> Node3D:
	var marker: Node3D = Node3D.new()
	marker.name = marker_name
	marker.position = where
	parent.add_child(marker)
	return marker


static func _prop(prop_name: String, mesh_name: String, mesh: ArrayMesh, material: Material) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = prop_name
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = mesh_name
	body.mesh = mesh
	body.material_override = material
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(body)
	return root


## Builds one surface vertex by vertex: positions, normals, UVs, the material
## colour and (when skinned) 4 bone weights; triangles wind to face their normals.
class Sculpt:
	extends RefCounted

	var tool: SurfaceTool = SurfaceTool.new()
	var count: int = 0
	var skinned: bool = false
	## An optional (Vector3) -> Vector3 that moves every vertex as it's written
	## (the youth's head and extremities, scaled round their joints). Weights,
	## the face's portrait zones and the rest height are taken before it.
	var warp: Callable = Callable()
	var _points: PackedVector3Array = PackedVector3Array()
	var _normals: PackedVector3Array = PackedVector3Array()

	func _init(is_skinned: bool) -> void:
		skinned = is_skinned
		if skinned:
			tool.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	func vertex(p: Vector3, normal: Vector3, uv: Vector2, uv2: Vector2, color: Color, bones: Dictionary) -> int:
		if warp.is_valid():
			p = warp.call(p)
		tool.set_color(color)
		tool.set_uv(uv)
		tool.set_uv2(uv2)
		tool.set_normal(normal)
		if skinned:
			var packed: Array = _top_four(bones)
			tool.set_bones(packed[0])
			tool.set_weights(packed[1])
		tool.add_vertex(p)
		_points.append(p)
		_normals.append(normal)
		count += 1
		return count - 1

	## A triangle that faces the way its vertices' normals do (Godot's front faces wind clockwise).
	func tri(a: int, b: int, c: int) -> void:
		var face: Vector3 = (_points[b] - _points[a]).cross(_points[c] - _points[a])
		var wanted: Vector3 = _normals[a] + _normals[b] + _normals[c]
		if face.dot(wanted) > 0.0:
			tool.add_index(a)
			tool.add_index(c)
			tool.add_index(b)
		else:
			tool.add_index(a)
			tool.add_index(b)
			tool.add_index(c)

	func commit(surface_name: StringName) -> ArrayMesh:
		tool.generate_tangents()
		var mesh: ArrayMesh = tool.commit()
		if mesh.get_surface_count() > 0:
			mesh.surface_set_name(0, String(surface_name))
		return mesh

	static func _top_four(bones: Dictionary) -> Array:
		var pairs: Array[Vector2] = []
		for bone: Variant in bones:
			var weight: float = float(bones[bone])
			if weight > 0.0001:
				pairs.append(Vector2(float(bone), weight))
		pairs.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y > b.y)
		var indices: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
		var weights: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
		var total: float = 0.0
		for index: int in mini(4, pairs.size()):
			total += pairs[index].y
		for index: int in mini(4, pairs.size()):
			indices[index] = int(pairs[index].x)
			weights[index] = pairs[index].y / maxf(total, 0.0001)
		if pairs.is_empty():
			weights[0] = 1.0
		return [indices, weights]
