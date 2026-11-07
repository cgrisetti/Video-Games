## The Level 1 youth's checks (docs/21_WINGFEATHER_YOUTH_HERO.md), run by
## tools/test_hero_rig.gd's run_boot on the boot seat at trail Level 1:
##   - the boot seat: a Wayfarer, Unsworn, on the honest Level 1 trail kit
##     (Tier 1 Willow-Coppice Longbow, Bramble-Spun Jerkin), 100 health, 6.6 m/s
##   - the look: the youth's sculpt on the shared 24-bone skeleton drawn at
##     0.9, about 5.5 heads to a crown near 1.6 m, the head 1.18x and the hands
##     and boots 1.22x, no beard, the Three-Value palette
##   - empty hands at spawn (the tool and quiver tucked away), the youth's own
##     idle, walk and run picked by speed, feet planting, the tool drawn with
##     the reach-back overlay when a fight starts and tucked away again after
##   - the start: Embershore's Bramblebridge arrival stands Player 1 at the chime-post
##     facing up it toward the Windmill and Hearthstead Market
##   - adults stay adults: a companion, or a sworn hero, is never the youth
extends RefCounted

const Cmd = CombatActionResource.Command

var tree: SceneTree
var check: Callable


func run(scene_tree: SceneTree, checker: Callable, p1: ActorBase) -> void:
	tree = scene_tree
	check = checker
	_check_seat(p1)
	_check_sculpt(p1)
	_check_clips()
	_check_start_spot()
	await _check_motion(p1)


func _frames(count: int) -> void:
	for i: int in count:
		await tree.physics_frame


func _check_seat(p1: ActorBase) -> void:
	var loadout: ClassLoadoutResource = p1.loadout
	var trail: EquipmentLoadoutResource = ArsenalCatalog.current.trail_kit_for_role(ClassLoadoutResource.Role.DPS, 1)
	check.call(PartyProgress.current.trail_level() == 1 and loadout.class_id == ClassLoadouts.DIRECTIONAL_FLOW_DPS and loadout.calling == Callings.UNSWORN,
		"the boot seat is a Wayfarer, Unsworn, at trail Level 1 (%s, %s, Lv %d)" % [loadout.class_id, Callings.id_of(loadout.calling), PartyProgress.current.trail_level()])
	check.call(loadout.weapon != null and loadout.weapon.item_id == trail.weapon_id and loadout.weapon.item_id == ArsenalCatalog.WILLOW_LONGBOW
		and loadout.armor != null and loadout.armor.item_id == ArsenalCatalog.BRAMBLE_JERKIN
		and is_equal_approx(loadout.stats.max_health, 100.0) and is_equal_approx(loadout.stats.move_speed, 6.6),
		"...on the honest Level 1 trail kit: the Tier 1 Willow-Coppice Longbow and the Bramble-Spun Jerkin, 100 health, 6.6 m/s (%s, %s)"
		% [loadout.weapon.item_id if loadout.weapon != null else &"-", loadout.armor.item_id if loadout.armor != null else &"-"])


func _check_sculpt(p1: ActorBase) -> void:
	var visuals: ActorVisuals = p1.visuals
	var look: HeroAppearanceResource = visuals.appearance
	check.call(visuals.is_youth() and visuals.is_youth_seat() and look.appearance_id == &"youth_wayfarer" and visuals.features.get("body_build") == HeroAppearanceResource.BODY_YOUTH
		and visuals.features.get("beard") == &"clean_youth" and visuals.surfaces.size() == HeroMeshAtelier.REGIONS.size(),
		"Player 1 is drawn as the Level 1 youth: the Wayfarer youth's look, no beard, five skinned surfaces (%s)" % look.appearance_id)
	check.call(visuals.skeleton.get_bone_count() == HeroRigBuilder.BONE_COUNT and visuals.skeleton.scale.is_equal_approx(Vector3.ONE * HeroAppearanceResource.YOUTH_SKELETON_SCALE)
		and visuals.animator.youth,
		"...on the shared 24-bone skeleton, drawn at %.2f, with the youth's animator" % visuals.skeleton.scale.y)
	# The head: the chin (the lowest point down the front of the face) to the top of the hair.
	var scale: float = visuals.skeleton.scale.y
	var youth_head: Vector3 = _head_measure(visuals.surfaces[0].mesh as ArrayMesh)
	var heads_tall: float = youth_head.y / (youth_head.y - youth_head.x)
	check.call(youth_head.y * scale > 1.55 and youth_head.y * scale < 1.7 and heads_tall > 4.95 and heads_tall < 5.6,
		"the youth stands %.2f m to the crown of the hair, %.1f heads tall (a storybook youth near the doc's 5.5 heads, about 1.6 m)" % [youth_head.y * scale, heads_tall])
	check.call(is_equal_approx(HeroAppearanceResource.YOUTH_HEAD_SCALE, 1.18) and is_equal_approx(HeroAppearanceResource.YOUTH_EXTREMITY_SCALE, 1.22),
		"the youth's head is sculpted 1.18x and the hands and boots 1.22x (Equipment & Grimoire doc §2)")
	var adult_head: Vector3 = _head_measure(HeroMeshAtelier.build_hero_surfaces(ArsenalCatalog.current.hero_appearance(&"hedge_runner"), &"ranger_leather")[0])
	check.call(youth_head.z > adult_head.z * 1.12,
		"...a broader head than a grown hero's (%.3f m across the face in rig space, against %.3f)" % [youth_head.z * 2.0, adult_head.z * 2.0])
	var bands_ok: bool = true
	for youth: HeroAppearanceResource in ArsenalCatalog.current.youth_appearances():
		for color: Color in [youth.value_1_coat_color, youth.value_1_breeches_color, youth.value_1_boot_color]:
			bands_ok = bands_ok and HeroAppearanceResource.value_band(color) == 1
		bands_ok = bands_ok and HeroAppearanceResource.value_band(youth.value_2_leather_color) == 2 and youth.is_youth()
	check.call(bands_ok and ArsenalCatalog.current.youth_appearances().size() == 3,
		"a youth for each Fellowship, the cape, breeches and boots in Value 1 and the braces' leather in Value 2")
	check.call(visuals.body_material.get_shader_parameter(&"calling_trim_color") == look.patch_color,
		"the trim slot paints the knee patch and the cape's lining (an Unsworn youth wears no tabard)")


## A head surface's chin (x: the lowest face vertex down the front, near the
## middle), its top (y: the highest vertex) and its half-width (z: the widest
## face vertex above the cheeks, in front), in rig space.
static func _head_measure(mesh: ArrayMesh) -> Vector3:
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var chin: float = 9.0
	var top: float = -9.0
	var half: float = 0.0
	for index: int in verts.size():
		var v: Vector3 = verts[index]
		top = maxf(top, v.y)
		if absf(colors[index].b - HeroMeshAtelier.MAT_FACE) > 0.005:
			continue
		if v.z < -0.1 and absf(v.x) < 0.03:
			chin = minf(chin, v.y)
		if v.y > 1.55 and v.z < -0.02 and absf(v.x) < 0.25:
			half = maxf(half, absf(v.x))
	return Vector3(chin, top, half)


func _check_clips() -> void:
	var ok: bool = true
	for entry: Array in [[HeroCombatAnimator.YOUTH_IDLE, 240, true], [HeroCombatAnimator.YOUTH_WALK, HeroCombatAnimator.YOUTH_WALK_FRAMES, true],
			[HeroCombatAnimator.YOUTH_RUN, HeroCombatAnimator.YOUTH_RUN_FRAMES, true], [HeroCombatAnimator.YOUTH_DRAW_LEFT, 18, false],
			[HeroCombatAnimator.YOUTH_DRAW_RIGHT, 18, false]]:
		var info: Dictionary = HeroCombatAnimator.clip_info(entry[0])
		ok = ok and int(info.get("frames", 0)) == int(entry[1]) and bool(info.get("loop", false)) == bool(entry[2])
	check.call(ok, "the youth's clips are baked: a 240-frame idle, a 40-frame walk, a 26-frame run and two 18-frame draws")
	# The walk's left heel leads at frame 0, the right halfway; the run lofts between steps.
	var walk_0: Dictionary = HeroCombatAnimator.sample_pose(HeroCombatAnimator.YOUTH_WALK, 0.0)
	var walk_half: Dictionary = HeroCombatAnimator.sample_pose(HeroCombatAnimator.YOUTH_WALK, 20.0)
	var left_fwd: float = (walk_0["rotations"][HeroRigBuilder.Bone.THIGH_L] as Quaternion).get_euler().x
	var right_fwd: float = (walk_half["rotations"][HeroRigBuilder.Bone.THIGH_R] as Quaternion).get_euler().x
	var run_low: float = (HeroCombatAnimator.sample_pose(HeroCombatAnimator.YOUTH_RUN, 6.5)["hips"] as Vector3).y
	var run_high: float = (HeroCombatAnimator.sample_pose(HeroCombatAnimator.YOUTH_RUN, 13.0)["hips"] as Vector3).y
	check.call(absf(left_fwd - right_fwd) < 0.08 and run_high > run_low + 0.02,
		"the walk strides left then right in step, and the run squashes through stance and lofts between steps (%.3f to %.3f m)" % [run_low, run_high])


func _check_start_spot() -> void:
	var builder: IslandBuilder = CalderaAtlas.builder_for(CalderaAtlas.ISLE_EMBERSHORE)
	var spot: Vector3 = builder.arrival_spot(CalderaAtlas.ARRIVE_START, 0)
	var facing: Vector3 = -builder.arrival_basis(CalderaAtlas.ARRIVE_START).z
	var toward_bridge: Vector2 = EmbershoreBuilder.START_FACING.normalized()
	# The party's row of four spreads 3.6 m either side of the arrival across the green.
	check.call(Vector2(spot.x, spot.z).distance_to(EmbershoreBuilder.START_AT) < 4.0 and Vector2(facing.x, facing.z).dot(toward_bridge) > 0.999,
		"a Level 1 start stands Player 1 on Bramblebridge's green by its chime-post on Embershore at %s, facing the stone bridge (docs/27 §7)"
		% Vector2(spot.x, spot.z))
	var second: Vector3 = builder.arrival_spot(CalderaAtlas.ARRIVE_START, 1)
	check.call(absf((second - spot).normalized().dot(Vector3(facing.x, 0.0, facing.z))) < 0.01,
		"...and the rest of the party lines up beside them, across the green")


func _check_motion(p1: ActorBase) -> void:
	var visuals: ActorVisuals = p1.visuals
	var animator: HeroCombatAnimator = visuals.animator
	await _frames(4)
	check.call(visuals.is_empty_handed() and animator.calm and animator.clip == HeroCombatAnimator.YOUTH_IDLE,
		"the youth spawns empty-handed (the longbow and quiver tucked away), in the easy idle")
	var hidden_kit: bool = true
	for gear: Node in visuals.socket(HeroRigBuilder.BACK_STOW_SOCKET).get_children():
		hidden_kit = hidden_kit and not (gear as Node3D).visible
	check.call(hidden_kit, "...with nothing on the back but the cape")
	p1.input.inject_move(Vector2(0.0, -0.4))
	await _frames(30)
	var walked: StringName = animator.clip
	var planted: int = animator.feet_planted
	p1.input.inject_move(Vector2(0.0, -1.0))
	await _frames(40)
	var ran: StringName = animator.clip
	check.call(walked == HeroCombatAnimator.YOUTH_WALK and ran == HeroCombatAnimator.YOUTH_RUN and animator.feet_planted > planted,
		"a gentle stick walks the youth, a full one runs, the feet planting as they go (%s, %s)" % [walked, ran])
	p1.input.inject_move(Vector2.ZERO)
	await _frames(20)
	p1.input.inject_command(Cmd.LIGHT)
	var drew: bool = false
	var overlay: StringName = &""
	for i: int in 20:
		await tree.physics_frame
		if not visuals.is_empty_handed():
			drew = true
			overlay = animator.overlay_clip() if overlay == &"" else overlay
	check.call(drew and overlay == HeroCombatAnimator.YOUTH_DRAW_LEFT,
		"a Light draws the Tier 1 longbow into the left hand with the reach-back draw (%s)" % overlay)
	await _frames(int((HeroCombatAnimator.CALM_AFTER + 1.0) * 60.0))
	check.call(visuals.is_empty_handed() and animator.clip == HeroCombatAnimator.YOUTH_IDLE,
		"%.0f s after the fight the bow is tucked away again" % HeroCombatAnimator.CALM_AFTER)
	p1.input.release_script()
