## Phase 19's checks (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §6.2, Stage 8),
## run by tools/smoke_test.gd:
##   run_boot  first, in Bramble-Bridge's hub, before anything else: a default
##             boot seats one hero alone (no AI companions, one full-screen
##             view), and Player 1 is the Iron-Woodsman (a Wayfarer with a Stout
##             Heart, 120 health) in the Hedgerow Wool-Mantle with a Broad-Axe;
##             a solo party needs one Maker-Seal Plate and meets a 1,400-health
##             Cairnsman. Then it seats the classic trinity's tank on the
##             keyboard and turns companions on for the older checks.
##   run_rig   in the expedition, on the trinity: the weapon-tier and hero-look
##             registries and their Three-Value bands; the 24-bone skeleton in
##             parent-first order, its Skin and four read-only sockets; five
##             skinned surfaces on every hero; the speckled woodsman beard on
##             Jaw_Beard; four coats and four weapons at four tiers, each its own
##             sculpt; the shader's uniforms; the clip library's 60 Hz frames;
##             the springs' frame-rate invariance; then the DPS as the
##             Iron-Woodsman with a Broad-Axe: axe_light_1 and the Earth-Splitter
##             frame-locked to their actions, the off hand on the haft, the run's
##             foot-plants and cloak, a dodge roll, a hit-stop's tremor and
##             squash, the parry and parley one-shots, and the 120-frame
##             Hearth-Rite Tuck ending at a 1.35x weapon; and Phase 19B's polish:
##             the micro-surfaces (twill and fuzz, timber grain, burnished
##             leather, hammered metal, the face's zones, its scatter and the
##             eyes' catchlight), the anatomical head, the stepped armour layers
##             and the jaunty run
##   run_vale  last, in Oakshire Vale: companions stay home unless backfill is
##             turned on, and the Truce-Sign the Lens check waved played its bow
extends RefCounted

const B = HeroRigBuilder.Bone
const Cmd = CombatActionResource.Command
const Weapon = EquipmentItemResource.WeaponType
const Phase = ActionQueueComponent.Phase
const CLIPS: Array[String] = [
	"idle_steward_calm", "idle_combat_ready", "idle_combat_ready_axe", "idle_combat_ready_staff", "idle_combat_ready_bow", "locomotion_run_cycle",
	"winded_3rd_light_recovery", "axe_light_1", "axe_light_2", "axe_heavy_earth_splitter", "axe_flourish_r_coppice", "axe_ult_lr_heartwood",
	"falchion_light_1", "falchion_light_2", "falchion_light_3", "falchion_heavy_advancing_thrust", "falchion_flourish_r_timber_cross",
	"falchion_ult_lr_bramble_whirl", "bow_light_snap_shot_1", "bow_light_snap_shot_2", "bow_heavy_piercing_draw", "bow_flourish_r_vaulting_bough",
	"bow_ult_lr_hail_of_hedgerow", "staff_light_sweep_1", "staff_light_sweep_2", "staff_light_bolt", "staff_heavy_resonant_pulse",
	"staff_flourish_r_reed_sweep", "staff_ult_lr_lantern_chime", "card_invoke_forward", "card_invoke_back", "card_invoke_r", "card_invoke_lr",
	"card_invoke_at_caster", "guard_hold", "perfect_guard_parry", "shadow_sanctuary_brace", "dodge_roll_evade", "hearth_rite_tuck",
	"truce_sign_parley", "bravery_counter_strike", "stagger_reel", "downed_slump", "overhead_pocket_blessing", "offhand_pocket_draw",
]
const SHADER_UNIFORMS: Array[String] = [
	"value_1_coat_color", "value_1_boot_color", "calling_trim_color", "fellowship_tunic_color", "value_2_timber_leather_color", "value_2_linen_color",
	"metal_iron_color", "metal_brass_color", "metal_steel_color", "equipment_metallic", "equipment_roughness", "skin_tone_color",
	"beard_primary_color", "beard_speckle_color", "beard_speckle_ratio", "biome_turf_bounce", "rim_color", "rim_strength", "glow",
	"active_sign_color", "sign_emission_strength", "dread_chill_frost", "lantern_promise_warmth", "camera_fade_distance",
]

var tree: SceneTree
var check: Callable


# --- The solo boot (Stage 1) ---------------------------------------------------

func run_boot(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	var level: LevelBase = tree.current_scene as LevelBase
	var network: NetworkManager = NetworkManager.current
	# A pad plugged in at launch would sit down too; this is the keyboard's boot.
	for seat: PartyMember in network.ordered_members():
		if seat.device_id != InputComponent.KEYBOARD_DEVICE and not seat.companion:
			network.drop_local_player(seat.device_id)
	await _frames(3)
	var p1: ActorBase = level.actors.get(&"1_0") as ActorBase
	var people: int = 0
	for seat: PartyMember in network.ordered_members():
		people += 0 if seat.companion else 1
	check.call(p1 != null and level.actors.size() == 1 and people == 1 and network.companion_seats().is_empty() and not LevelBase.auto_backfill_companions,
		"a default boot seats exactly one hero, Player 1, and no AI companions (%d people, %d bots)" % [people, network.companion_seats().size()])
	if p1 == null:
		return
	var stout: SecondaryCallingResource = ArsenalCatalog.current.secondary_calling(ArsenalCatalog.STOUT_HEART)
	check.call(p1.loadout.class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS and Callings.id_of(p1.loadout.calling) == ArsenalCatalog.STOUT_HEART
		and p1.loadout.display_name == "Iron-Woodsman" and p1.loadout.calling_subtitle == "Hewn-Hand of the High Pines"
		and is_equal_approx(p1.loadout.stats.max_health, 120.0) and is_equal_approx(stout.poise_damage_multiplier, 1.25)
		and is_equal_approx(p1.loadout.stats.perfect_guard_window, 0.2 + 0.03),
		"Player 1 is the Iron-Woodsman, \"Hewn-Hand of the High Pines\": a Wayfarer with a Stout Heart, 120 health, +25%% poise, a 230 ms Perfect Guard (%s)"
		% p1.loadout.display_name)
	check.call(p1.loadout.armor != null and p1.loadout.armor.item_id == ArsenalCatalog.RANGER_LEATHER and p1.loadout.weapon != null
		and p1.loadout.weapon.weapon_type == Weapon.HEAVY_AXE and p1.visuals.has_rig() and p1.visuals.features.get("headgear") == &"wayfarer_hood_up",
		"...in the Hedgerow Wool-Mantle with a Broad-Axe (%s), a sculpted, hooded hero" % (p1.loadout.weapon.display_name if p1.loadout.weapon != null else "none"))
	var cells: GridContainer = level.grid.get_node(^"Cells") as GridContainer
	check.call(level.grid.view_count() == 1 and cells.columns == 1 and level.grid.get_node(^"Cells").get_child_count() == 1,
		"one hero fills the screen: a single full-screen 1x1 view")
	check.call(CoopGate.plates_needed(1) == 1 and CoopGate.plates_needed(3) == 2
		and is_equal_approx(BossDummy.HEALTH_BASE + BossDummy.HEALTH_PER_PLAYER * 1.0, 1400.0),
		"a solo party needs one Maker-Seal Plate (min(2, party)) and meets a 900 + 500 = 1,400-health Cairnsman")
	check.call(LevelBase.wants_companions_flag(PackedStringArray(["--with-companions"])) and not LevelBase.wants_companions_flag(PackedStringArray()),
		"--with-companions on the command line asks for AI companions")
	# The older checks seat the classic trinity: companions on, and the keyboard back on the Shield-Sworn.
	LevelBase.solo_iron_woodsman_boot = false
	level.set_companion_backfill_enabled(true)
	network.update_local_player(InputComponent.KEYBOARD_DEVICE, ClassLoadouts.SHIELD_TANK, p1.input.assist_mode)
	await _frames(3)
	var tank: ActorBase = level.actors.get(&"1_0") as ActorBase
	check.call(tank != null and tank.loadout.class_id == ClassLoadouts.SHIELD_TANK and LevelBase.auto_backfill_companions,
		"a test that wants companions turns backfill on (set_companion_backfill_enabled), and the keyboard takes up the Shield-Sworn")


# --- The rig (Stages 2-7) ---------------------------------------------------------

func run_rig(scene_tree: SceneTree, checker: Callable, tank: ActorBase, healer: ActorBase, dps: ActorBase, boss: ActorBase) -> void:
	tree = scene_tree
	check = checker
	_check_registries()
	_check_skeleton()
	_check_surfaces(tank, healer, dps)
	_check_arsenal_sculpts()
	_check_shader_and_library()
	_check_material_fidelity()
	_check_facial_sculpt()
	_check_tectonic_armor()
	_check_jaunty_run()
	await _check_iron_woodsman(dps, boss)


func _check_registries() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var tiers: Array[WeaponVisualTierResource] = catalog.weapon_visual_tiers()
	var ids: Array[StringName] = [&"apprentice_timber", &"hedgerow_iron", &"bramble_bridge_steel", &"dover_slap_relic"]
	var expected: Array[Array] = [[1, 1.0, 0.0, 0.78, 0.0, "a67b5b"], [2, 1.2, 0.55, 0.52, 0.2, "5a626a"], [5, 1.45, 0.8, 0.32, 0.5, "c4ced4"],
		[10, 1.75, 0.9, 0.22, 1.8, "e5c158"]]
	var tiers_ok: bool = tiers.size() == 4
	for index: int in mini(tiers.size(), 4):
		var tier: WeaponVisualTierResource = tiers[index]
		var want: Array = expected[index]
		tiers_ok = tiers_ok and tier.tier_id == ids[index] and tier.tier_level == index + 1 and tier.opens_at_level == want[0]
		tiers_ok = tiers_ok and is_equal_approx(tier.stat_multiplier, want[1]) and is_equal_approx(tier.metallic, want[2])
		tiers_ok = tiers_ok and is_equal_approx(tier.roughness, want[3]) and is_equal_approx(tier.sign_core_emission, want[4])
		tiers_ok = tiers_ok and tier.blade_color.to_html(false) == want[5]
		var falchion: EquipmentItemResource = catalog.item(ArsenalCatalog.tier_weapon_id(Weapon.LIGHT_SWORD, index + 1))
		tiers_ok = tiers_ok and falchion.trim_albedo.is_equal_approx(tier.trim_color) and is_equal_approx(falchion.roughness_factor, tier.roughness)
	var trims_ok: bool = tiers.size() == 4 and tiers[0].trim_color.to_html(false) == "c8b594" and tiers[1].trim_color.to_html(false) == "b88b3a" \
		and tiers[2].trim_color.to_html(false) == "d4a84e" and tiers[3].has_sign_stone() and not tiers[2].has_sign_stone()
	check.call(tiers_ok and trims_ok,
		"four WeaponVisualTierResources, Apprentice Timber to Dover-Slap Relic: Level 1/2/5/10, 1.0/1.2/1.45/1.75x, metal 0/0.55/0.8/0.9, rough 0.78/0.52/0.32/0.22, Sign-stone 0/0.2/0.5/1.8, the brief's blades and trims, copied onto every tier's weapons")
	var looks: Array[HeroAppearanceResource] = catalog.hero_appearances()
	var every_calling: bool = looks.size() == 9
	for calling: CallingResource in catalog.callings():
		every_calling = every_calling and catalog.hero_appearance(calling.calling_id) != null
	var dyes: Array[HeroAppearanceResource] = catalog.heritage_dyes()
	var dye_ids: Array[StringName] = []
	var dyes_grounded: bool = dyes.size() == 4
	for dye: HeroAppearanceResource in dyes:
		dye_ids.append(dye.coat_dye_preset)
		dyes_grounded = dyes_grounded and HeroAppearanceResource.value_band(dye.value_1_coat_color) == 1
	check.call(every_calling and _same(dye_ids, [&"tizzi_wed_pine", &"gull_wick_slate", &"barley_bridge_russet", &"barrow_crag_heather"]) and dyes_grounded,
		"nine HeroAppearanceResources (one per Calling) and four heritage dyes (Tizzi-Wed Pine, Gull-Wick Slate, Barley-Bridge Russet, Barrow-Crag Heather), every wool in Value 1")
	var woodsman: HeroAppearanceResource = catalog.hero_appearance(&"iron_woodsman")
	check.call(woodsman.appearance_id == &"iron_woodsman_default" and woodsman.heritage_id == &"tizzi_wed_green" and woodsman.coat_dye_preset == &"tizzi_wed_pine"
		and woodsman.value_1_coat_color.to_html(false) == "2e402b" and woodsman.value_1_boot_color.to_html(false) == "36281e"
		and woodsman.value_2_timber_leather_color.to_html(false) == "9c7250" and woodsman.value_2_linen_color.to_html(false) == "d6c7b2"
		and woodsman.beard_primary_color.to_html(false) == "4a3222" and woodsman.beard_speckle_color.to_html(false) == "b8c0c8"
		and is_equal_approx(woodsman.beard_speckle_ratio, 0.28) and woodsman.headgear_style == &"wayfarer_hood_up" and woodsman.beard_style == &"woodsman_full_speckled"
		and woodsman.left_pauldron_style == &"iron_wood_bark_pauldron" and woodsman.right_pauldron_style == &"stitched_leather_cop"
		and woodsman.belt_trinket_id == &"iron_splitting_wedges" and woodsman.back_buckler_targe,
		"the Iron-Woodsman's look: #2E402B pine-wool, #36281E bog-leather, #9C7250 hazel, #D6C7B2 gambeson, a #4A3222 beard 28% speckled #B8C0C8, a raised hood, a bark pauldron left and a leather cop right, splitting wedges and a buckler-targe")
	var bands: Array[int] = [HeroAppearanceResource.value_band(woodsman.value_1_coat_color), HeroAppearanceResource.value_band(woodsman.value_1_boot_color),
		HeroAppearanceResource.value_band(woodsman.value_2_timber_leather_color)]
	check.call(_same(bands, [1, 1, 2]) and woodsman.value_2_linen_color.get_luminance() > HeroAppearanceResource.VALUE_2_LUMINANCE_MIN
		and woodsman.beard_speckle_color.get_luminance() > woodsman.beard_primary_color.get_luminance() + 0.5,
		"the Three-Value Harmony: coat and boots in Value 1 (0.16-0.38), hewn hazel in Value 2 (0.45-0.74), the gambeson lighter still, the ash-gray speckles bright against the bark-brown beard")
	# Siblings on the couch in the same Calling read apart.
	var p2: HeroAppearanceResource = catalog.hero_appearance_for_seat(ClassLoadouts.DIRECTIONAL_FLOW_DPS, Callings.Secondary.STOUT_HEART, 1)
	check.call(p2.calling_id == &"iron_woodsman" and p2.coat_dye_preset != woodsman.coat_dye_preset and not p2.value_1_coat_color.is_equal_approx(woodsman.value_1_coat_color),
		"a second Iron-Woodsman on the couch wears the next heritage dye (%s)" % p2.coat_dye_preset)


func _check_skeleton() -> void:
	var rig: Skeleton3D = HeroRigBuilder.build_hero_skeleton()
	var names_ok: bool = rig.get_bone_count() == 24
	var order_ok: bool = rig.get_bone_count() == 24 and rig.get_bone_parent(0) == -1
	for bone: int in rig.get_bone_count():
		names_ok = names_ok and rig.get_bone_name(bone) == String(HeroRigBuilder.BONE_NAMES[bone])
		if bone > 0:
			order_ok = order_ok and rig.get_bone_parent(bone) >= 0 and rig.get_bone_parent(bone) < bone and rig.get_bone_parent(bone) == HeroRigBuilder.BONE_PARENTS[bone]
	var skin: Skin = HeroRigBuilder.skin_of(rig)
	var binds_ok: bool = skin != null and skin.get_bind_count() == 24
	for bind: int in (skin.get_bind_count() if skin != null else 0):
		binds_ok = binds_ok and skin.get_bind_bone(bind) == bind
	var sockets: Array[String] = []
	for entry: Array in HeroRigBuilder.SOCKETS:
		var socket: BoneAttachment3D = HeroRigBuilder.socket(rig, StringName(entry[0]))
		if socket != null and not socket.override_pose and socket.bone_name == String(HeroRigBuilder.BONE_NAMES[entry[1]]):
			sockets.append(socket.name)
	check.call(names_ok and order_ok, "HeroRigBuilder.build_hero_skeleton() makes 24 bones, Root to Cloak_03, every parent before its child (parent_idx < bone_idx)")
	check.call(binds_ok and _same(sockets, ["MainHandSocket", "OffHandSocket", "BackStowSocket", "HipSatchelSocket"]),
		"its Skin binds all 24 bones from their rests (create_skin_from_rest_transforms), and four read-only sockets ride Hand_R, Hand_L, Chest and Hips (override_pose false)")
	check.call(rig.modifier_callback_mode_process == Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL and HeroRigBuilder.rest_direction(B.HEAD).y > 0.99
		and absf(HeroRigBuilder.BONE_HEADS[B.HEAD].y + HeroRigBuilder.bone_length(B.HEAD) - HeroAppearanceResource.CROWN_HEIGHT_M) < 0.01,
		"the hero stands 4.5 heads to a 1.75 m crown, and the animator advances the skeleton itself each tick")
	rig.free()


func _check_surfaces(tank: ActorBase, healer: ActorBase, dps: ActorBase) -> void:
	var skinned_ok: bool = true
	for hero: ActorBase in [tank, healer, dps]:
		var visuals: ActorVisuals = hero.visuals
		skinned_ok = skinned_ok and visuals.has_rig() and visuals.skeleton.get_bone_count() == 24 and visuals.surfaces.size() == 5
		for surface: MeshInstance3D in visuals.surfaces:
			var arrays: Array = surface.mesh.surface_get_arrays(0)
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			skinned_ok = skinned_ok and surface.skin != null and bones.size() == vertices.size() * 4 and weights.size() == vertices.size() * 4
			skinned_ok = skinned_ok and surface.get_node_or_null(surface.skeleton) == visuals.skeleton and surface.material_override == visuals.body_material
	check.call(skinned_ok, "every hero is the 24-bone rig wearing five continuous skinned surfaces (bones and weights on every vertex), one Skin, one material")
	var regions: Array[String] = []
	for surface: MeshInstance3D in dps.visuals.surfaces:
		regions.append(surface.mesh.surface_get_name(0))
	check.call(_same(regions, ["mesh_head_heritage", "mesh_torso_coat", "mesh_pauldrons_tabard", "mesh_limbs_boots", "mesh_belt_cloak"]),
		"the five regions: head and heritage, torso and coat, pauldrons and tabard, limbs and boots, belt and cloak")
	var woodsman: HeroAppearanceResource = ArsenalCatalog.current.hero_appearance(&"iron_woodsman")
	var meshes: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(woodsman, ArsenalCatalog.RANGER_LEATHER)
	var head: Array = meshes[0].surface_get_arrays(0)
	var colors: PackedColorArray = head[Mesh.ARRAY_COLOR]
	var head_bones: PackedInt32Array = head[Mesh.ARRAY_BONES]
	var head_weights: PackedFloat32Array = head[Mesh.ARRAY_WEIGHTS]
	var beard: int = 0
	var on_jaw: int = 0
	var lowest: float = INF
	var head_vertices: PackedVector3Array = head[Mesh.ARRAY_VERTEX]
	for index: int in colors.size():
		if absf(colors[index].b - HeroMeshAtelier.MAT_BEARD) < 0.02:
			beard += 1
			lowest = minf(lowest, head_vertices[index].y)
			for slot: int in 4:
				if head_bones[index * 4 + slot] == B.JAW_BEARD and head_weights[index * 4 + slot] > 0.5:
					on_jaw += 1
	var hood_peak: float = meshes[0].get_aabb().end.y
	check.call(beard > 200 and on_jaw > beard / 2 and lowest < 1.33 and absf(hood_peak - HeroAppearanceResource.HOOD_PEAK_M) < 0.02,
		"the Iron-Woodsman's multi-lobed beard (%d vertices) hangs on Jaw_Beard to %.2f m under a hood peaking at %.2f m" % [beard, lowest, hood_peak])
	var torso_counts: Array[int] = []
	var hems: Array[float] = []
	for coat: StringName in [ArsenalCatalog.BRAMBLE_JERKIN, ArsenalCatalog.HEARTH_LINEN, ArsenalCatalog.RANGER_LEATHER, ArsenalCatalog.IRONWOOD_PLATE]:
		var coat_meshes: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(woodsman, coat)
		torso_counts.append(coat_meshes[1].surface_get_array_len(0))
		hems.append(coat_meshes[4].get_aabb().position.y)
	var distinct: bool = true
	for index: int in torso_counts.size():
		for other: int in range(index + 1, torso_counts.size()):
			distinct = distinct and torso_counts[index] != torso_counts[other]
	check.call(distinct and hems[1] < hems[2] and hems[2] < hems[0],
		"the four coats are four silhouettes (%s torso vertices): the Hearth-Linen's swallowtail hangs lowest, the Bramble-Spun Jerkin's travel cape shortest" % str(torso_counts))


func _check_arsenal_sculpts() -> void:
	var counts_ok: bool = true
	var markers_ok: bool = true
	var summary: PackedStringArray = PackedStringArray()
	for weapon_type: int in [Weapon.LIGHT_SWORD, Weapon.HEAVY_AXE, Weapon.STAFF, Weapon.BOW]:
		var counts: Array[int] = []
		for tier: int in range(1, 5):
			var mesh: ArrayMesh = HeroMeshAtelier.build_tiered_weapon_mesh(weapon_type, tier)
			counts.append(mesh.surface_get_array_len(0))
			var root: Node3D = HeroMeshAtelier.build_tiered_weapon(weapon_type, tier)
			markers_ok = markers_ok and root.get_node_or_null(^"TrailBase") != null and root.get_node_or_null(^"TrailTip") != null
			markers_ok = markers_ok and (root.get_node_or_null(^"SignStoneCore") != null) == (tier == 4)
			markers_ok = markers_ok and (root.get_node_or_null(^"HaftGripMarker") != null) == HeroMeshAtelier.is_two_handed(weapon_type)
			markers_ok = markers_ok and (root.get_node_or_null(^"BowString/BowStringMid") != null) == (weapon_type == Weapon.BOW)
			var blade: MeshInstance3D = root.get_node(^"Blade") as MeshInstance3D
			var material: ShaderMaterial = blade.material_override as ShaderMaterial
			markers_ok = markers_ok and material != null and material.shader == HeroMeshAtelier.SHADER
			markers_ok = markers_ok and is_equal_approx(float(material.get_shader_parameter(&"equipment_metallic")), ArsenalCatalog.TIER_METALLIC[tier - 1])
			root.free()
		for index: int in counts.size():
			for other: int in range(index + 1, counts.size()):
				counts_ok = counts_ok and counts[index] != counts[other]
		summary.append(str(counts))
	check.call(counts_ok, "all four weapons are sculpted anew at each of the four tiers (vertices by tier: %s)" % ", ".join(summary))
	check.call(markers_ok,
		"every sculpted weapon carries its trail markers and the tier's metal in the hero shader; two-handers a HaftGripMarker, the bow its BowStringMid, and every Dover-Slap relic a SignStoneCore")


func _check_shader_and_library() -> void:
	var names: Array[String] = []
	for uniform: Dictionary in HeroMeshAtelier.SHADER.get_shader_uniform_list():
		names.append(String(uniform["name"]))
	var missing: Array[String] = []
	for wanted: String in SHADER_UNIFORMS:
		if not names.has(wanted):
			missing.append(wanted)
	var code: String = HeroMeshAtelier.SHADER.code
	check.call(missing.is_empty() and code.contains("global uniform vec4 ground_turf") and code.contains("fwidth") and code.contains("bayer4")
		and code.contains("strand_speckle") and code.contains("smoothstep(0.15, 1.45, rest_y)"),
		"storybook_hero_atelier.gdshader parses with its %d uniforms: the Three-Value palette and vertical gradient, the vertex-colour decoder, the speckled beard, an anti-aliased cel ramp with the turf's bounce, the Fellowship rim, Sign veins, Dread-Chill and The Lantern's Promise, a camera dither%s"
		% [names.size(), "" if missing.is_empty() else " (missing %s)" % ", ".join(missing)])
	var library: AnimationLibrary = HeroCombatAnimator.library()
	var absent: Array[String] = []
	var framed: bool = true
	for clip: String in CLIPS:
		if not library.has_animation(StringName(clip)):
			absent.append(clip)
			continue
		var animation: Animation = library.get_animation(StringName(clip))
		framed = framed and is_equal_approx(animation.step, 1.0 / 60.0) and animation.get_track_count() > 0
	var typed: Dictionary[int, bool] = {}
	for clip: String in ["axe_heavy_earth_splitter", "dodge_roll_evade"]:
		var animation: Animation = library.get_animation(StringName(clip))
		for track: int in animation.get_track_count():
			typed[animation.track_get_type(track)] = true
	var frames: Array[int] = []
	for clip: StringName in [&"axe_light_1", &"axe_heavy_earth_splitter", &"dodge_roll_evade", &"hearth_rite_tuck", &"truce_sign_parley",
			&"winded_3rd_light_recovery", &"locomotion_run_cycle"]:
		frames.append(int(HeroCombatAnimator.clip_info(clip).get("frames", 0)))
	check.call(absent.is_empty() and framed and typed.has(Animation.TYPE_ROTATION_3D) and typed.has(Animation.TYPE_POSITION_3D) and typed.has(Animation.TYPE_SCALE_3D)
		and _same(frames, [51, 56, 24, 120, 48, 33, 28]) and _same(HeroCombatAnimator.FOOT_PLANT_FRAMES, [4, 18]),
		"the hero's AnimationLibrary holds all %d clips at 60 Hz in rotation, position and scale tracks: axe lights 51 f, the Earth-Splitter 56, the roll 24, the Hearth-Rite Tuck 120, the Truce-Sign 48, the winded recovery 33, a 28 f run planting on frames 4 and 18%s"
		% [CLIPS.size(), "" if absent.is_empty() else " (missing %s)" % ", ".join(absent)])
	# The springs are exact: one 1/30 s step lands where two 1/60 s steps do.
	var once: Vector2 = StorybookKinematicsModifier3D.spring_step(Vector2(0.3, -1.0), -0.2, 14.0, 0.72, 1.0 / 30.0)
	var twice: Vector2 = StorybookKinematicsModifier3D.spring_step(StorybookKinematicsModifier3D.spring_step(Vector2(0.3, -1.0), -0.2, 14.0, 0.72, 1.0 / 60.0),
		-0.2, 14.0, 0.72, 1.0 / 60.0)
	var critical: Vector2 = StorybookKinematicsModifier3D.spring_step(Vector2(0.3, 0.0), 0.0, 22.0, 1.0, 1.0)
	check.call(once.distance_to(twice) < 0.00001 and absf(critical.x) < 0.001,
		"the cloak and beard springs are frame-rate invariant: one 1/30 s step lands exactly where two 1/60 s steps do (%.6f apart)" % once.distance_to(twice))


## The DPS turned Iron-Woodsman with a Broad-Axe, its animations played through the real action pipeline.
func _check_iron_woodsman(dps: ActorBase, boss: ActorBase) -> void:
	var original: ClassLoadoutResource = dps.loadout
	var standing: Transform3D = dps.global_transform
	var kit: EquipmentLoadoutResource = dps.loadout.kit.copy()
	kit.armor_id = ArsenalCatalog.RANGER_LEATHER
	kit.weapon_id = ArsenalCatalog.COPPICE_BROADAXE
	dps.re_equip(ClassLoadouts.compose(ClassLoadouts.DIRECTIONAL_FLOW_DPS, kit, Callings.Secondary.STOUT_HEART))
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 26.0)))
	dps.input.inject_move(Vector2.ZERO)
	await _frames(6)
	var visuals: ActorVisuals = dps.visuals
	var animator: HeroCombatAnimator = visuals.animator
	var kinematics: StorybookKinematicsModifier3D = visuals.kinematics
	var weapon: Node3D = visuals.weapon()
	check.call(dps.loadout.display_name == "Iron-Woodsman" and visuals.features.get("beard") == &"woodsman_full_speckled"
		and visuals.features.get("left_pauldron") == &"iron_wood_bark_pauldron" and weapon != null and weapon.get_parent().get_parent() == visuals.socket(HeroRigBuilder.MAIN_HAND_SOCKET)
		and visuals.body_material.get_shader_parameter(&"beard_primary_color") == Color(0.290, 0.196, 0.133) and kinematics.steps > 0,
		"the Iron-Woodsman's rig: the speckled beard and bark pauldron, a Hedgerow Iron Broad-Axe in the MainHandSocket, the kinematics stepping (%d)" % kinematics.steps)
	# Light 1, frame-locked: the wind-up ends on frame 18, the active frames on 27.
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.LIGHT)
	var windup_frame: float = -1.0
	var active_frame: float = -1.0
	var hand_high: float = -INF
	var hand_low: float = INF
	var tip_from: Vector3 = Vector3.ZERO
	var tip_to: Vector3 = Vector3.ZERO
	var clip_seen: StringName = &""
	for step: int in 90:
		await tree.physics_frame
		var action: CombatActionResource = dps.action_queue.current_action
		if action == null:
			if windup_frame >= 0.0:
				break
			continue
		clip_seen = animator.clip
		var hand: float = dps.to_local(visuals.socket(HeroRigBuilder.MAIN_HAND_SOCKET).global_position).y
		if dps.action_queue.phase == Phase.WINDUP:
			hand_high = maxf(hand_high, hand)
			tip_from = visuals.trail_points()[1] if visuals.trail_points().size() == 2 else tip_from
		if dps.action_queue.phase == Phase.ACTIVE and windup_frame < 0.0:
			windup_frame = animator.clip_frame
		if dps.action_queue.phase == Phase.RECOVERY and active_frame < 0.0:
			active_frame = animator.clip_frame
			hand_low = hand
			tip_to = visuals.trail_points()[1] if visuals.trail_points().size() == 2 else tip_to
	check.call(clip_seen == &"axe_light_1" and absf(windup_frame - 18.0) <= 3.0 and absf(active_frame - 27.0) <= 3.0 and hand_high > 1.45
		and hand_low < hand_high - 0.4 and tip_from.distance_to(tip_to) > 0.5,
		"axe_light_1 is frame-locked to the Light: wind-up into frame %.0f (18), active into %.0f (27); the axe coils %.2f m high and hews down %.2f m, its blade sweeping %.2f m"
		% [windup_frame, active_frame, hand_high, hand_high - hand_low, tip_from.distance_to(tip_to)])
	await _until_idle(dps)
	# The Earth-Splitter: up and over, the hips squashed on impact.
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.HEAVY)
	var squashed: float = 1.0
	var heavy_clip: StringName = &""
	var hoist: float = -INF
	for step: int in 120:
		await tree.physics_frame
		if dps.action_queue.current_action == null and heavy_clip != &"":
			break
		if dps.action_queue.current_action != null:
			heavy_clip = animator.clip
			squashed = minf(squashed, animator.hips_scale.y)
			if dps.action_queue.phase == Phase.WINDUP:
				hoist = maxf(hoist, dps.to_local(visuals.socket(HeroRigBuilder.MAIN_HAND_SOCKET).global_position).y)
	check.call(heavy_clip == &"axe_heavy_earth_splitter" and squashed < 0.9 and hoist > 1.6,
		"the Earth-Splitter hoists the axe overhead (%.2f m) and slams it down, the hips squashing to %.2f" % [hoist, squashed])
	await _until_idle(dps)
	await _frames(4)
	check.call(not visuals.is_weapon_stowed() and animator.grip_weight > 0.9 and kinematics.grip_error >= 0.0 and kinematics.grip_error < 0.04,
		"in a fighting stance the off hand rides the Broad-Axe's haft (two-bone arm IK to the HaftGripMarker, %.3f m off)" % kinematics.grip_error)
	check.call(kinematics.foot_errors[0] < 0.02 and kinematics.foot_errors[1] < 0.02,
		"both boots stay planted on the flagstones (foot IK %.3f / %.3f m)" % [kinematics.foot_errors[0], kinematics.foot_errors[1]])
	# The run: feet plant on frames 4 and 18, the body leans in, the cloak streams back clear of the body.
	var idle_flare: float = kinematics.cloak_pitch[0]
	var planted: int = animator.feet_planted
	dps.input.inject_move(Vector2(0.0, 1.0))
	var lean: float = 0.0
	var flare: float = 0.0
	var clearance: float = INF
	var running: bool = false
	for step: int in 50:
		await tree.physics_frame
		lean = minf(lean, kinematics.lean)
		flare = minf(flare, kinematics.cloak_pitch[0])
		clearance = minf(clearance, kinematics.cloak_clearance)
		running = running or animator.clip == &"locomotion_run_cycle"
	dps.input.inject_move(Vector2.ZERO)
	check.call(running and animator.feet_planted >= planted + 2 and lean < -0.08 and flare < idle_flare - 0.1
		and clearance >= StorybookKinematicsModifier3D.BODY_CAPSULE_RADIUS - 0.02,
		"running, the Iron-Woodsman's feet plant on the run's frames (%d), the body leans %.2f rad into it and the cloak streams back %.2f rad, never inside the 0.26 m body capsule (%.2f m)"
		% [animator.feet_planted - planted, lean, flare - idle_flare, clearance])
	await _frames(20)
	# A dodge roll: a tucked somersault through the 0.32 s of untouchability.
	dps.stats.stamina = dps.stats.stats.max_stamina
	dps.input.inject_command(Cmd.DODGE)
	var rolled: bool = false
	var tucked: float = 0.0
	var roll_frames: float = -1.0
	for step: int in 50:
		await tree.physics_frame
		if animator.clip == &"dodge_roll_evade":
			rolled = true
			roll_frames = float(HeroCombatAnimator.clip_info(&"dodge_roll_evade")["frames"])
			tucked = minf(tucked, animator.hips_offset.y)
	check.call(rolled and roll_frames == 24.0 and tucked < -0.35 and is_equal_approx(ArsenalCatalog.current.dodge_template().active_time, 0.32),
		"a dodge plays dodge_roll_evade (24 f, 0.40 s): a tucked forward somersault %.2f m down through 0.32 s of untouchability" % tucked)
	await _until_idle(dps)
	# A hit-stop: a 45 Hz tremor in the chest and hand, the hips squashed and sprung back.
	dps.apply_hit_stop(0.1)
	var trembled: bool = false
	var squash: float = 1.0
	for step: int in 5:
		await tree.physics_frame
		trembled = trembled or absf(kinematics.tremor) > 0.005
		squash = minf(squash, kinematics.squash)
	await _frames(40)
	check.call(trembled and squash <= StorybookKinematicsModifier3D.HEAVY_SQUASH + 0.01 and absf(kinematics.squash - 1.0) < 0.03,
		"a 100 ms hit-stop trembles the chest and weapon hand at 45 Hz and squashes the hips to %.2f (volume kept), then springs back" % squash)
	# The parry and the parley one-shots.
	visuals.play_perfect_guard_parry()
	await _frames(2)
	var parried: bool = animator.one_shot_clip() == &"perfect_guard_parry"
	await _frames(20)
	visuals.play_truce_sign_parley()
	var bowed: float = 0.0
	for step: int in 52:
		await tree.physics_frame
		bowed = minf(bowed, visuals.skeleton.get_bone_pose_rotation(B.SPINE).get_euler().x)
	check.call(parried and animator.one_shot_clip() == &"" and bowed < -0.35,
		"a Perfect Guard snaps out perfect_guard_parry, and the Truce-Sign Parley bows %.0f degrees over the heart, then the hero stands easy" % rad_to_deg(-bowed))
	# The Hearth-Rite Tuck: down on one knee for 120 frames, the weapon glowing at 1.35x after.
	dps.place_at(Transform3D(Basis.IDENTITY, boss.global_position + Vector3(0.0, 0.0, 26.0)))
	SignFlowComponent.enabled = true
	await _frames(2)
	dps.input.inject_hold(InputComponent.ACTION_TRIGGER_R, true)
	var knelt: float = 0.0
	var tuck_seen: bool = false
	var locked: bool = true
	for frame: int in SignFlowComponent.HEARTH_RITE_HOLD_FRAMES:
		await tree.physics_frame
		if animator.clip == &"hearth_rite_tuck":
			tuck_seen = true
			knelt = minf(knelt, animator.hips_offset.y)
			locked = locked and absf(animator.clip_frame - dps.input.hearth_rite_progress() * 120.0) < 0.01
	dps.input.inject_hold(InputComponent.ACTION_TRIGGER_R, false)
	await _frames(100)
	check.call(tuck_seen and locked and knelt < -0.35 and is_equal_approx(visuals.weapon_scale(), SignFlowComponent.TRAIL_COAT_SCALE)
		and animator.played.get(&"overhead_pocket_blessing", 0) > 0,
		"holding R plays hearth_rite_tuck locked to the hold's 120 frames, down on one knee (%.2f m), and leaves the Broad-Axe glowing at %.2fx after the Overhead Pocket Blessing"
		% [knelt, visuals.weapon_scale()])
	if dps.sign_flow != null:
		dps.sign_flow._end_tuck()
	SignFlowComponent.enabled = false
	dps.re_equip(original)
	dps.place_at(standing)
	await _frames(3)


# --- Phase 19B: material fidelity, the face, the armour, the run ----------------------

## The Phase 19 counts (the Iron-Woodsman in the Hedgerow Wool-Mantle) the polish must grow past.
const PHASE_19_VERTICES: Array[int] = [1339, 1556, 750, 2271, 732]


func _check_material_fidelity() -> void:
	var code: String = HeroMeshAtelier.SHADER.code
	var wanted: Array[String] = [
		"sin((uv.x + uv.y) * 110.0) * sin((uv.x - uv.y) * 110.0)", "uniform float weave_strength = 0.28;",
		"pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 2.2) * fuzz_strength", "uniform float fuzz_strength = 0.22;",
		"value_noise(vec2(UV.x * 84.0, UV.y * 6.0))", "uniform float grain_strength = 0.24;", "rough = 0.68;",
		"rough = mix(0.78, 0.28, burnish);", "mat.z = 0.65 * burnish;", "fract(UV.y / 0.015)",
		"uniform float facet_cells = 32.0;", "uniform float facet_strength = 0.16;", "voronoi_tilt(vec3(UV * facet_cells", "smoothstep(0.86, 0.92, reflect_dot)",
		"soot_color", "malar_mix = 0.32", "smoothstep(-0.18, 0.20, ndl) * (1.0 - smoothstep(0.0, 0.35, ndl))", "smoothstep(0.95, 0.985, reflect_dot) * 1.6",
	]
	var missing: Array[String] = []
	for line: String in wanted:
		if not code.contains(line):
			missing.append(line)
	var names: Array[String] = []
	for uniform: Dictionary in HeroMeshAtelier.SHADER.get_shader_uniform_list():
		names.append(String(uniform["name"]))
	for uniform_name: String in ["weave_strength", "fuzz_strength", "grain_strength", "facet_cells", "facet_strength", "soot_color", "leather_color", "bark_color",
			"malar_color", "cool_undertone_color", "scatter_color", "sclera_color", "iris_color"]:
		if not names.has(uniform_name):
			missing.append(uniform_name)
	check.call(missing.is_empty(),
		"the hero shader parses with Phase 19B's micro-surfaces: a twill weave (0.28) and fuzz rim (0.22) on cloth, 14:1 timber grain (0.24, rough 0.68), leather matte in its creases (0.78) and burnished on its edges (0.28, specular 0.65) with saddle stitches every 15 mm, 32-a-metre hammer facets (0.16) with a sun glint and forge-soot, the face's malar flush, a sub-dermal scatter band and the eyes' catchlight%s"
		% ("" if missing.is_empty() else " (missing %s)" % ", ".join(missing)))
	var cloth: bool = HeroMeshAtelier.MAT_COAT < 0.3 and HeroMeshAtelier.MAT_BREECHES < 0.3 and HeroMeshAtelier.MAT_TABARD < 0.3 and HeroMeshAtelier.MAT_TUNIC < 0.3 \
		and HeroMeshAtelier.MAT_TRIM < 0.3 and HeroMeshAtelier.MAT_LINEN < 0.3 and HeroMeshAtelier.MAT_ROPE < 0.3
	var timber: bool = HeroMeshAtelier.MAT_TIMBER >= 0.3 and HeroMeshAtelier.MAT_BARK < 0.42
	var leather: bool = HeroMeshAtelier.MAT_LEATHER >= 0.42 and HeroMeshAtelier.MAT_BOOT < 0.5
	var metal: bool = HeroMeshAtelier.MAT_IRON >= 0.5 and HeroMeshAtelier.MAT_STEEL < 0.7
	var skin: bool = HeroMeshAtelier.MAT_SKIN >= 0.7 and HeroMeshAtelier.MAT_FACE >= 0.7 and HeroMeshAtelier.MAT_SCLERA > HeroMeshAtelier.MAT_BEARD
	check.call(cloth and timber and leather and metal and skin,
		"every material id sits in its band: wool and linen below 0.3, timber below 0.42, leather below 0.5, metal below 0.7, then skin, the face and the eyes")


func _check_facial_sculpt() -> void:
	var woodsman: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(ArsenalCatalog.current.hero_appearance(&"iron_woodsman"), ArsenalCatalog.RANGER_LEATHER)
	var arrays: Array = woodsman[0].surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var counted: Dictionary[float, int] = {}
	var nose_tip: float = 0.0
	var brow_front: float = 0.0
	var socket_front: float = -1.0
	var wings: Array[int] = [0, 0]
	var lobes: Array[int] = [0, 0, 0]
	var widest_face: float = 0.0
	var flushed: int = 0
	var warm_brow: int = 0
	for index: int in vertices.size():
		var p: Vector3 = vertices[index]
		var material: float = colors[index].b
		for id: float in [HeroMeshAtelier.MAT_FACE, HeroMeshAtelier.MAT_SCLERA, HeroMeshAtelier.MAT_IRIS, HeroMeshAtelier.MAT_EYE, HeroMeshAtelier.MAT_HAIR, HeroMeshAtelier.MAT_BEARD]:
			if absf(material - id) < 0.006:
				counted[id] = counted.get(id, 0) + 1
		if absf(material - HeroMeshAtelier.MAT_FACE) < 0.006:
			widest_face = maxf(widest_face, absf(p.x))
			flushed += 1 if uvs[index].x > 0.5 else 0
			warm_brow += 1 if uvs[index].y > 0.5 else 0
			if absf(p.x) < 0.03 and p.y < 1.6:
				nose_tip = minf(nose_tip, p.z)
			if p.y > 1.622 and p.y < 1.636 and absf(p.x) > 0.03 and absf(p.x) < 0.08:
				brow_front = minf(brow_front, p.z)
			if p.y > 1.59 and p.y < 1.605 and absf(p.x) > 0.03 and absf(p.x) < 0.08:
				socket_front = minf(socket_front, p.z) if socket_front > -0.5 else p.z
		if absf(material - HeroMeshAtelier.MAT_BEARD) < 0.006:
			if absf(p.x) > 0.09 and p.y > 1.53 and p.y < 1.57:
				wings[0 if p.x < 0.0 else 1] += 1
			if p.y < 1.4:
				lobes[0 if p.x < -0.04 else (2 if p.x > 0.04 else 1)] += 1
	check.call(vertices.size() > PHASE_19_VERTICES[0] and counted.get(HeroMeshAtelier.MAT_SCLERA, 0) > 0 and counted.get(HeroMeshAtelier.MAT_IRIS, 0) > 0
		and counted.get(HeroMeshAtelier.MAT_EYE, 0) > 0 and counted.get(HeroMeshAtelier.MAT_HAIR, 0) > 0,
		"the head is re-sculpted (%d vertices, up from %d) with layered eyes: ivory sclera, a hazel-amber iris, a dark pupil, lash rims and brows"
		% [vertices.size(), PHASE_19_VERTICES[0]])
	check.call(nose_tip <= -0.17 and socket_front > -0.5 and socket_front - brow_front >= 0.015,
		"the face has true planes: a brow ridge standing %.0f mm proud of the recessed eye sockets, and a three-plane nose to a tip %.3f m forward"
		% [(socket_front - brow_front) * 1000.0, -nose_tip])
	check.call(wings[0] > 10 and wings[1] > 10 and lobes[0] > 10 and lobes[1] > 10 and lobes[2] > 10,
		"the two-wing mustache sweeps out to either side, proud of a three-lobed woodsman beard (%s wing, %s lobe vertices)" % [str(wings), str(lobes)])
	var warden: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(ArsenalCatalog.current.hero_appearance(&"bridge_warden"), ArsenalCatalog.IRONWOOD_PLATE)
	var warden_arrays: Array = warden[0].surface_get_arrays(0)
	var warden_vertices: PackedVector3Array = warden_arrays[Mesh.ARRAY_VERTEX]
	var warden_colors: PackedColorArray = warden_arrays[Mesh.ARRAY_COLOR]
	var ears: Array[int] = [0, 0]
	for index: int in warden_vertices.size():
		if absf(warden_colors[index].b - HeroMeshAtelier.MAT_FACE) < 0.006 and absf(warden_vertices[index].x) > 0.15:
			ears[0 if warden_vertices[index].x < 0.0 else 1] += 1
	check.call(ears[0] > 20 and ears[1] > 20 and widest_face < 0.15 and flushed > 20 and warm_brow > 20,
		"cupped ears show at x = +-0.155 m when the head is uncovered (a kettle-cap) and stay under the Wayfarer hood; the face carries its malar flush and warm forehead zones")


func _check_tectonic_armor() -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var woodsman: HeroAppearanceResource = catalog.hero_appearance(&"iron_woodsman")
	var meshes: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(woodsman, ArsenalCatalog.RANGER_LEATHER)
	var grew: bool = true
	var weighted: bool = true
	var counts: Array[int] = []
	for index: int in meshes.size():
		var arrays: Array = meshes[index].surface_get_arrays(0)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var count: int = meshes[index].surface_get_array_len(0)
		counts.append(count)
		grew = grew and count > PHASE_19_VERTICES[index]
		for vertex: int in count:
			var total: float = 0.0
			for slot: int in 4:
				total += weights[vertex * 4 + slot]
				weighted = weighted and bones[vertex * 4 + slot] >= 0 and bones[vertex * 4 + slot] < HeroRigBuilder.BONE_COUNT
			weighted = weighted and absf(total - 1.0) < 0.01
	check.call(grew and weighted, "the armour is rebuilt in stepped layers (%s vertices by region, each past Phase 19's %s), every vertex weighted to the 24 bones"
		% [str(counts), str(PHASE_19_VERTICES)])
	var torso: Array = meshes[1].surface_get_arrays(0)
	var vertices: PackedVector3Array = torso[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = torso[Mesh.ARRAY_COLOR]
	var tunic_front: float = 0.0
	var plate_front: float = 0.0
	var lips: int = 0
	var found: Dictionary[float, int] = {}
	for index: int in vertices.size():
		var p: Vector3 = vertices[index]
		var material: float = colors[index].b
		for id: float in [HeroMeshAtelier.MAT_LEATHER, HeroMeshAtelier.MAT_BRASS, HeroMeshAtelier.MAT_IRON, HeroMeshAtelier.MAT_COAT, HeroMeshAtelier.MAT_LINEN]:
			if absf(material - id) < 0.006:
				found[id] = found.get(id, 0) + 1
		lips += 1 if absf(colors[index].r - HeroMeshAtelier.UNDER_LIP_AO) < 0.01 else 0
		if p.y > 1.17 and p.y < 1.23 and absf(p.x) < 0.05:
			if absf(material - HeroMeshAtelier.MAT_TUNIC) < 0.006:
				tunic_front = minf(tunic_front, p.z)
			elif absf(material - HeroMeshAtelier.MAT_LEATHER) < 0.006:
				plate_front = minf(plate_front, p.z)
	check.call(tunic_front - plate_front >= 0.015 and lips > 100 and found.get(HeroMeshAtelier.MAT_LEATHER, 0) > 0 and found.get(HeroMeshAtelier.MAT_BRASS, 0) > 0
		and found.get(HeroMeshAtelier.MAT_IRON, 0) > 0 and found.get(HeroMeshAtelier.MAT_LINEN, 0) > 0,
		"the Wool-Mantle's brigandine stands %.0f mm off the tunic in leather lames with iron studs, brass corner rivets and roller-buckled harnesses, over a rolled linen collar, every layer's lip in shadow"
		% ((tunic_front - plate_front) * 1000.0))
	var coat_parts: Dictionary[StringName, Array] = {
		ArsenalCatalog.IRONWOOD_PLATE: [HeroMeshAtelier.MAT_STEEL, HeroMeshAtelier.MAT_RING_MAIL], ArsenalCatalog.BRAMBLE_JERKIN: [HeroMeshAtelier.MAT_TUNIC, HeroMeshAtelier.MAT_LEATHER],
		ArsenalCatalog.HEARTH_LINEN: [HeroMeshAtelier.MAT_LINEN, HeroMeshAtelier.MAT_BRASS, HeroMeshAtelier.MAT_TRIM],
	}
	var coats_ok: bool = true
	for coat: StringName in coat_parts:
		var coat_colors: PackedColorArray = HeroMeshAtelier.build_hero_surfaces(woodsman, coat)[1].surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		for id: float in coat_parts[coat]:
			var has: bool = false
			for color: Color in coat_colors:
				if absf(color.b - id) < 0.006:
					has = true
					break
			coats_ok = coats_ok and has
	check.call(coats_ok, "each coat has its own chest: a beveled steel breastplate over ring-mail, a quilted jack with leather side-laces, a pleated linen surcoat with a brass carillon-clasp")
	var limbs: Array = meshes[3].surface_get_arrays(0)
	var limb_vertices: PackedVector3Array = limbs[Mesh.ARRAY_VERTEX]
	var limb_colors: PackedColorArray = limbs[Mesh.ARRAY_COLOR]
	var hobnails: int = 0
	var knuckles: Array[int] = [0, 0]
	var boot_tops: int = 0
	for index: int in limb_vertices.size():
		var p: Vector3 = limb_vertices[index]
		var material: float = limb_colors[index].b
		if absf(material - HeroMeshAtelier.MAT_IRON) < 0.006 and p.y < 0.03:
			hobnails += 1
		if absf(material - HeroMeshAtelier.MAT_IRON) < 0.006 and p.y > 0.7 and p.y < 0.8:
			knuckles[0 if p.x < 0.0 else 1] += 1
		if absf(material - HeroMeshAtelier.MAT_BOOT) < 0.006 and p.y > 0.34 and p.y < 0.425 and Vector2(absf(p.x) - 0.115, p.z).length() > 0.095:
			boot_tops += 1
	var pauldrons: Array = meshes[2].surface_get_arrays(0)
	var pauldron_vertices: PackedVector3Array = pauldrons[Mesh.ARRAY_VERTEX]
	var pauldron_colors: PackedColorArray = pauldrons[Mesh.ARRAY_COLOR]
	var third_lame: int = 0
	var haute_piece: int = 0
	var cop_studs: int = 0
	for index: int in pauldron_vertices.size():
		var p: Vector3 = pauldron_vertices[index]
		var material: float = pauldron_colors[index].b
		third_lame += 1 if absf(material - HeroMeshAtelier.MAT_BARK) < 0.006 and p.x < -0.3 else 0
		haute_piece += 1 if absf(material - HeroMeshAtelier.MAT_IRON) < 0.006 and p.x < 0.0 and p.y > 1.48 else 0
		cop_studs += 1 if absf(material - HeroMeshAtelier.MAT_BRASS) < 0.006 and p.x > 0.15 else 0
	check.call(hobnails > 50 and knuckles[0] > 20 and knuckles[1] > 20 and boot_tops > 40 and third_lame > 10 and haute_piece > 10 and cop_studs > 10,
		"three laminated Iron-Wood plates and an upturned haute-piece on the left shoulder, a brass-studded two-lame leather cop on the right, articulated knuckle plates, folded-down boot tops and iron hobnails round the soles")


func _check_jaunty_run() -> void:
	var info: Dictionary = HeroCombatAnimator.clip_info(&"locomotion_run_cycle")
	var poses: Dictionary[int, Dictionary] = {}
	for frame: int in [2, 4, 7, 11, 18, 21, 25]:
		poses[frame] = HeroCombatAnimator.sample_pose(&"locomotion_run_cycle", float(frame))
	var hips_ok: bool = absf((poses[4]["hips"] as Vector3).y + 0.045) < 0.004 and absf((poses[18]["hips"] as Vector3).y + 0.045) < 0.004 \
		and absf((poses[11]["hips"] as Vector3).y - 0.055) < 0.004 and absf((poses[25]["hips"] as Vector3).y - 0.055) < 0.004 \
		and absf((poses[7]["hips"] as Vector3).x + 0.035) < 0.004 and absf((poses[21]["hips"] as Vector3).x - 0.035) < 0.004
	var roll_l: float = _rotation(poses[7], B.HIPS).get_euler().z
	var roll_r: float = _rotation(poses[21], B.HIPS).get_euler().z
	var yaw_l: float = _rotation(poses[4], B.HIPS).get_euler().y
	var chest_yaw: float = _rotation(poses[4], B.CHEST).get_euler().y
	var chest_roll: float = _rotation(poses[7], B.CHEST).get_euler().z
	check.call(hips_ok and absf(roll_l + 0.113) < 0.01 and absf(roll_r - 0.113) < 0.01 and absf(yaw_l + 0.18) < 0.01
		and chest_yaw > 0.15 and chest_roll > 0.05 and not info.get("grip", false),
		"the run squashes the hips 45 mm at each plant (frames 4, 18) and lofts them 55 mm (11, 25), shifting 35 mm over the planted boot with a 6.5-degree pelvic roll and 0.18 rad yaw, the chest counter-twisting (%.2f rad) and rolling its shoulders"
		% chest_yaw)
	var port: Array[Transform3D] = _pose_globals(poses[11])
	var chest: Basis = port[B.CHEST].basis.orthonormalized()
	var haft: Vector3 = (chest.inverse() * port[B.HAND_R].basis.z.normalized()).normalized()
	var tilt: float = rad_to_deg(acos(clampf(haft.y, -1.0, 1.0)))
	var back_swing: float = _pose_globals(poses[4])[B.UPPER_ARM_L].basis.y.normalized().z
	var fore_swing: float = _pose_globals(poses[18])[B.UPPER_ARM_L].basis.y.normalized().z
	check.call(tilt > 20.0 and tilt < 45.0 and haft.x < 0.0 and back_swing > 0.2 and fore_swing < -0.2,
		"the weapon rides one-handed in a diagonal low port across the hip (%.0f degrees off upright) while the off arm swings back and forth to counter-balance" % tilt)
	var heel: float = _pose_globals(poses[2])[B.FOOT_L].basis.y.normalized().y
	var toe_off: float = _pose_globals(poses[4])[B.FOOT_R].basis.y.normalized().y
	var stance_x: float = _pose_globals(poses[7])[B.FOOT_L].origin.x
	var knee: float = -_pose_globals(poses[11])[B.THIGH_R].basis.y.normalized().z
	check.call(heel > 0.0 and toe_off < -0.6 and stance_x < -0.14 and knee > 0.6,
		"heel-strike tips the leading boot up, toe-off snaps the trailing ankle down, the planted boot runs %.0f mm wide of the middle, and the swing knee whips up" % (-stance_x * 1000.0))


static func _rotation(pose: Dictionary, bone: int) -> Quaternion:
	var rotations: Array[Quaternion] = pose["rotations"]
	return rotations[bone]


## A sampled pose's bone transforms in the skeleton's space.
static func _pose_globals(pose: Dictionary) -> Array[Transform3D]:
	var positions: Array[Vector3] = []
	for rest: Transform3D in HeroRigBuilder.local_rests():
		positions.append(rest.origin)
	positions[B.HIPS] += pose["hips"] as Vector3
	var rotations: Array[Quaternion] = pose["rotations"]
	return StorybookKinematicsModifier3D._globals(rotations, positions)


# --- Oakshire Vale: companions only when asked ---------------------------------------

func run_vale(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	var level: LevelBase = tree.current_scene as LevelBase
	if level == null or not level.wants_companions():
		check.call(false, "the companion opt-in check runs in Oakshire Vale")
		return
	var network: NetworkManager = NetworkManager.current
	# Down to the keyboard alone, so there are roles for companions to fill.
	for seat: PartyMember in network.ordered_members():
		if not seat.companion and seat.device_id != InputComponent.KEYBOARD_DEVICE and seat.peer_id == network.local_peer_id():
			network.drop_local_player(seat.device_id)
	await _frames(4)
	var parleyed: int = 0
	for actor: ActorBase in level.actors.values():
		if actor.visuals != null and actor.visuals.animator != null:
			parleyed += int(actor.visuals.animator.played.get(&"truce_sign_parley", 0))
	check.call(parleyed > 0, "waving the Truce-Sign at a curious hob bowed the hero who waved it (truce_sign_parley, %d)" % parleyed)
	level.set_companion_backfill_enabled(false)
	await _frames(4)
	var without: int = network.companion_seats().size()
	level.set_companion_backfill_enabled(true)
	await _frames(4)
	var people: Array[StringName] = []
	for seat: PartyMember in network.ordered_members():
		if not seat.companion:
			people.append(seat.class_id)
	var wanted: int = CompanionAIComponent.backfill_classes(people).size()
	var with: int = network.companion_seats().size()
	level.set_companion_backfill_enabled(false)
	await _frames(4)
	check.call(without == 0 and with == wanted and network.companion_seats().is_empty(),
		"in Oakshire Vale companions stay home by default (%d) and come when a test turns backfill on (%d of %d), then leave again" % [without, with, wanted])


# --- Helpers -----------------------------------------------------------------------

## Whether two arrays hold the same values in order (typed or not).
static func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for index: int in a.size():
		if a[index] != b[index]:
			return false
	return true


func _frames(count: int) -> void:
	for frame: int in count:
		await tree.physics_frame


func _until_idle(actor: ActorBase) -> void:
	for frame: int in 240:
		if actor.action_queue.current_action == null and actor.state_machine.current_name() != &"attack" and actor.state_machine.current_name() != &"dodge":
			return
		await tree.physics_frame
