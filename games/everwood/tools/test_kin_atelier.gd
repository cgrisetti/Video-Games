## The kin overhaul (docs/30_KIN_DESIGN_LANGUAGE.md): the foes a hero meets on
## Embershore from Level 1 to 5 as sculpted, skinned, painted and animated figures
## on the heroes' own architecture. Run by tools/test_caldera_isles.gd right after
## Act I (so by the smoke test and tools/run_caldera_checks.gd):
##   1  every look sculpts one skinned surface on its own skeleton, standing on its
##      feet at its height, within its vertex budget, identical kin sharing it
##   2  every kin wears a look: Act I's twelve their own and Un-Inked, every pack on
##      Embershore's roads a sculpted one
##   3  every family's clip library: the shared clips, each look's blow with its
##      wind-up before its strike, a steward's bow; poses that really move
##   4  a figure's material (the kin shader, the ink line, the sea-fret's unlined
##      hem), its striking limbs and an Iron-Man's seal plate; the calm's wash and
##      bloom, the scatter's grey, the steward's colour back
##   5  live on Embershore: a hound runs on its gait, its bite plays frame-locked to
##      the wind-up, it kneels when its posture breaks; a scuttler wavers worn down;
##      a calmed hound washes its grey off, shakes, then walks off as it fades; a
##      burnt Tide-Wight greys and crumbles
extends RefCounted

## A look's surface stays under this many vertices (a quay wave puts a dozen in view).
const VERTEX_BUDGET: int = 7000
## Its feet are on the ground (lowest vertex within this share of its height) and its top near its height.
const GROUND_SLACK: float = 0.07
const HEIGHT_SLACK: float = 0.2
const SHARED_CLIPS: Array[StringName] = [&"idle", &"walk", &"run", &"hit", &"stagger", &"kneel", &"waver", &"collapse", &"calmed", &"happy"]

var check: Callable
var level: CalderaArchipelagoWorld
var tree: SceneTree


## The checks that need no level (1 to 4).
func run_offline(checker: Callable) -> void:
	check = checker
	_check_sculpts()
	_check_looks()
	_check_clips()
	_check_figures()


## Every check, the live ones on Embershore after Act I.
func run(live_level: CalderaArchipelagoWorld, checker: Callable, scene_tree: SceneTree) -> void:
	level = live_level
	tree = scene_tree
	run_offline(checker)
	await _check_live()


# --- 1: sculpts ----------------------------------------------------------------------

func _check_sculpts() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var most: int = 0
	for look: StringName in KinLooks.ALL:
		var mesh: ArrayMesh = KinSculptor.mesh(look)
		var rig: KinRig = KinSculptor.rig(look)
		var height: float = float(KinLooks.spec(look)["height"])
		if mesh == null or mesh.get_surface_count() != 1:
			problems.append("%s has no single surface" % look)
			continue
		var arrays: Array = mesh.surface_get_arrays(0)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		most = maxi(most, points.size())
		if points.size() > VERTEX_BUDGET:
			problems.append("%s %d verts" % [look, points.size()])
		if bones.size() != points.size() * 4 or weights.size() != points.size() * 4:
			problems.append("%s not skinned 4 a vertex" % look)
		for bone: int in bones:
			if bone < 0 or bone >= rig.count():
				problems.append("%s weights bone %d of %d" % [look, bone, rig.count()])
				break
		var aabb: AABB = mesh.get_aabb()
		if absf(aabb.position.y) > height * GROUND_SLACK:
			problems.append("%s lowest at %.2f" % [look, aabb.position.y])
		if absf(aabb.end.y - height) > height * HEIGHT_SLACK:
			problems.append("%s top %.2f for %.2f" % [look, aabb.end.y, height])
	var shared: bool = KinSculptor.mesh(KinLooks.HOUND) == KinSculptor.mesh(KinLooks.HOUND) and KinSculptor.mesh(KinLooks.HOUND) != KinSculptor.mesh(KinLooks.PADFOOT)
	check.call(problems.is_empty() and shared,
		"the kin's %d looks each sculpt one skinned surface on their own skeleton (4 weights a vertex, every bone real), standing on their feet at their height, under %d verts (most %d), identical kin sharing one mesh%s"
		% [KinLooks.ALL.size(), VERTEX_BUDGET, most, "" if problems.is_empty() else ": " + "; ".join(problems)])


# --- 2: who wears what ------------------------------------------------------------------

func _check_looks() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var act_one: Dictionary[StringName, StringName] = {
		Bestiary.BRAMBLE_HOUND: KinLooks.HOUND, Bestiary.GREY_BARK_WEEVIL: KinLooks.WEEVIL, Bestiary.GREY_BARK_WEEVIL_GREAT: KinLooks.WEEVIL,
		Bestiary.ASH_GREMLIN: KinLooks.ASH_GRIG, Bestiary.BARNACLE_SCUTTLER: KinLooks.BARNACLE, Bestiary.TIDE_WRAITH: KinLooks.TIDE_WIGHT,
		Bestiary.SAP_ELEMENTAL: KinLooks.SAP_BOGGART, Bestiary.SAP_ELEMENTAL_GREAT: KinLooks.SAP_BOGGART, Bestiary.ROOT_LURKER: KinLooks.ROOT_LURKER,
		Bestiary.FURROW_IRON_MAN_GUARDIAN: KinLooks.IRON_MAN, Bestiary.RUSTED_IRON_MAN: KinLooks.IRON_MAN, Bestiary.TAPROOT_STAG: KinLooks.TAPROOT_STAG,
	}
	for id: StringName in act_one:
		var variant: MobVariantResource = Bestiary.variant(id)
		if KinLooks.look_of(variant) != act_one[id] or not variant.un_inked:
			problems.append("%s wears %s (un-inked %s)" % [id, KinLooks.look_of(variant), variant.un_inked])
	var packs: int = 0
	for spec: Dictionary in EmbershoreBuilder.ENCOUNTERS:
		for id: Variant in spec["pack"]:
			packs += 1
			var variant: MobVariantResource = Bestiary.variant(StringName(id))
			if variant == null or not KinLooks.ALL.has(KinLooks.look_of(variant)):
				problems.append("%s has no look" % id)
			elif variant.un_inked:
				problems.append("%s is un-inked off Act I" % id)
	for variant: MobVariantResource in Bestiary.all():
		if not KinLooks.ALL.has(KinLooks.look_of(variant)):
			problems.append("%s has no look" % variant.variant_id)
	check.call(problems.is_empty(),
		"every kin wears a sculpted look: Act I's twelve their own (hound, weevil, Ash-Grig, scuttler, Tide-Wight, Sap-Boggart, Root-Lurker, Iron-Man, Taproot Stag), all Un-Inked; the %d foes in Embershore's road packs and every other kin a look of their body's%s"
		% [packs, "" if problems.is_empty() else ": " + "; ".join(problems)])


# --- 3: clips -----------------------------------------------------------------------------

func _check_clips() -> void:
	var problems: PackedStringArray = PackedStringArray()
	for look: StringName in KinLooks.ALL:
		var rig: KinRig = KinSculptor.rig(look)
		var wanted: Array[StringName] = SHARED_CLIPS.duplicate()
		var attack: StringName = KinLooks.spec(look)["attack"]
		wanted.append(attack)
		if rig.rig == KinRigBuilder.Rig.BIPED:
			wanted.append(&"bow")
		for clip: StringName in wanted:
			if not KinAnimator.has_clip(look, clip):
				problems.append("%s lacks %s" % [look, clip])
		var info: Dictionary = KinAnimator.clip_info(look, attack)
		if not (0 < int(info.get("windup", 0)) and int(info["windup"]) < int(info["active"]) and int(info["active"]) < int(info["frames"])):
			problems.append("%s's %s frames %s" % [look, attack, info])
		if not KinAnimator.clip_info(look, &"walk").get("loop", false) or KinAnimator.clip_info(look, &"collapse").get("loop", true):
			problems.append("%s loops wrong" % look)
		# Poses that move: the blow's wind-up away from the idle, the gait's two halves apart, the collapse low.
		var idle: Dictionary = KinAnimator.sample_pose(look, &"idle", 0.0)
		var windup: Dictionary = KinAnimator.sample_pose(look, attack, float(info.get("windup", 0)))
		var walk_frames: float = float(KinAnimator.clip_info(look, &"walk")["frames"])
		var stride_a: Dictionary = KinAnimator.sample_pose(look, &"walk", walk_frames * 0.25)
		var stride_b: Dictionary = KinAnimator.sample_pose(look, &"walk", walk_frames * 0.75)
		var fallen: Dictionary = KinAnimator.sample_pose(look, &"collapse", float(KinAnimator.clip_info(look, &"collapse")["frames"]))
		if _largest_turn(idle, windup) < 10.0:
			problems.append("%s's wind-up barely moves" % look)
		if _largest_turn(stride_a, stride_b) < 8.0:
			problems.append("%s's walk barely moves" % look)
		var low: float = (fallen["offset"] as Vector3).y * (fallen["scale"] as Vector3).y if rig.rig == KinRigBuilder.Rig.BLOB else (fallen["offset"] as Vector3).y
		if low >= -0.04 and (fallen["scale"] as Vector3).y >= 0.9:
			problems.append("%s's collapse stays up" % look)
	check.call(problems.is_empty(),
		"each family's clips are baked onto every look at 60 Hz (idle, walk, run, hit, stagger, kneel, waver, collapse, calmed, happy, its own blow, and a steward's bow on two legs): blows wind up before they strike, gaits loop and step, wind-ups and collapses move%s"
		% ("" if problems.is_empty() else ": " + "; ".join(problems)))


func _largest_turn(a: Dictionary, b: Dictionary) -> float:
	var most: float = 0.0
	var turns_a: Array[Quaternion] = a["rotations"]
	var turns_b: Array[Quaternion] = b["rotations"]
	for index: int in turns_a.size():
		most = maxf(most, rad_to_deg(turns_a[index].angle_to(turns_b[index])))
	return most


# --- 4: figures ---------------------------------------------------------------------------

func _check_figures() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var holder: Node3D = Node3D.new()
	var hound: KinFigure = _figure(holder, Bestiary.BRAMBLE_HOUND)
	var lasher: KinFigure = _figure(holder, &"bramble_lasher_vine")
	var guardian: KinFigure = _figure(holder, Bestiary.FURROW_IRON_MAN_GUARDIAN)
	var wight: KinFigure = _figure(holder, Bestiary.TIDE_WRAITH)
	var barnacle: KinFigure = _figure(holder, Bestiary.BARNACLE_SCUTTLER)
	var ink: ShaderMaterial = hound.material.next_pass as ShaderMaterial
	if hound.material.shader != KinSculptor.SHADER or ink == null or ink != HeroMeshAtelier.ink_material():
		problems.append("the hound's material")
	var wight_ink: ShaderMaterial = wight.material.next_pass as ShaderMaterial
	var wight_cut: Variant = wight_ink.get_shader_parameter(&"mist_cut") if wight_ink != null else null
	var shared_cut: Variant = ink.get_shader_parameter(&"mist_cut") if ink != null else null
	if wight_cut == null or float(wight_cut) <= 0.0 or (shared_cut != null and float(shared_cut) > 0.0):
		problems.append("the sea-fret's hem is lined")
	if not is_equal_approx(hound.skeleton.scale.y, Bestiary.variant(Bestiary.BRAMBLE_HOUND).height / float(KinLooks.spec(KinLooks.HOUND)["height"])):
		problems.append("the hound's fit")
	if hound.un_inked != 1.0 or hound.bloom != 0.0 or lasher.un_inked != 0.0 or lasher.bloom != 1.0:
		problems.append("the grey and the roses at the start")
	if guardian.seal == null or barnacle.strike_limbs().size() != 2 or guardian.strike_limbs().size() != 2:
		problems.append("the seal plate or the striking limbs")
	if hound.surface.mesh != KinSculptor.mesh(KinLooks.HOUND) or hound.surface.skin == null:
		problems.append("the hound's skinned surface")
	# The calm washes the grey off and opens the dog-roses; the scatter greys it right through; a steward's colour comes back.
	hound.begin_calm()
	var washed: bool = false
	for step: int in 70:
		hound.update_preview(1.0 / 60.0)
	washed = hound.un_inked < 0.01 and hound.bloom > 0.0 and hound.is_calming()
	for step: int in 60:
		hound.update_preview(1.0 / 60.0)
	barnacle.scatter()
	for step: int in 30:
		barnacle.update_preview(1.0 / 60.0)
	guardian.restore()
	for step: int in 70:
		guardian.update_preview(1.0 / 60.0)
	if not washed or hound.bloom < 1.0 or barnacle.un_inked < 0.99 or barnacle.story != &"scattered" or guardian.un_inked > 0.01:
		problems.append("calm %s/%.2f/%.2f, scatter %.2f, restore %.2f" % [washed, hound.un_inked, hound.bloom, barnacle.un_inked, guardian.un_inked])
	# A flinch layers over the clip.
	hound.flinch()
	hound.update_preview(1.0 / 60.0)
	if int(hound.animator.played.get(&"hit", 0)) != 1:
		problems.append("no flinch")
	holder.free()
	check.call(problems.is_empty(),
		"a kin's figure wears the kin shader with the heroes' ink line (a Tide-Wight's hem unlined as it thins to wisps), fits its variant's height, names its striking limbs and an Iron-Man's seal plate; a calm washes the grey off in %.1f s and opens the dog-roses, a scatter greys it through, a steward's colour comes back, and a blow flinches it%s"
		% [KinFigure.CALM_WASH_TIME, "" if problems.is_empty() else ": " + "; ".join(problems)])


func _figure(holder: Node3D, id: StringName) -> KinFigure:
	var made: KinFigure = KinFigure.new()
	holder.add_child(made)
	made.build(Bestiary.variant(id))
	return made


# --- 5: live --------------------------------------------------------------------------

func _check_live() -> void:
	var builder: EmbershoreBuilder = CalderaAtlas.builder_for(CalderaAtlas.ISLE_EMBERSHORE) as EmbershoreBuilder
	var home: Vector3 = builder.arrival_spot(CalderaAtlas.ARRIVE_START, 0) + Vector3(10.0, 0.0, -6.0)
	level.streamer.ensure_ground_at(home)
	home.y = level.streamer.height_at(home.x, home.z)
	var pack: MobSpawner = MobSpawner.new()
	pack.name = "KinAtelierChecks"
	pack.territory = "Lee-Shore Orchards"
	pack.variant_ids = [Bestiary.BRAMBLE_HOUND, Bestiary.BARNACLE_SCUTTLER, Bestiary.TIDE_WRAITH]
	pack.leash = 22.0
	pack.position = home
	level.add_child(pack)
	pack.spawn_mobs()
	await _frames(3)
	var hound: WildMob = pack.mobs[0]
	var barnacle: WildMob = pack.mobs[1]
	var wight: WildMob = pack.mobs[2]
	var built: bool = true
	for mob: WildMob in pack.mobs:
		built = built and mob.figure != null and mob.figure.get_parent() == mob.visual and mob._body_material == mob.figure.material
	var auras: bool = not barnacle._aura_shells.is_empty() and not wight._aura_shells.is_empty()
	check.call(built and auras,
		"live on Embershore a hound, a Barnacle Scuttler and a Tide-Wight stand as sculpted figures, their bodies' glow on the kin material, the scuttler's claws and the wight's hand carrying their Signs")
	# The hound runs at a hero on its gait.
	_place_party(home + Vector3(0.0, 0.0, 14.0))
	hound.stats.take_damage(1.0)
	var gaits: Dictionary[StringName, bool] = {}
	var frames_seen: Dictionary[float, bool] = {}
	for step: int in 90:
		await _frames(1)
		if hound.remote_speed() > 1.0:
			gaits[hound.kin_clip()] = true
			frames_seen[snappedf(hound.figure.animator.clip_frame, 0.5)] = true
	var ran: bool = (gaits.has(&"run") or gaits.has(&"walk")) and frames_seen.size() > 6
	# Its bite plays frame-locked: the wind-up's frames while the blow winds up, the strike's after.
	var windup_frames: float = float(KinAnimator.clip_info(KinLooks.HOUND, &"attack_bite")["windup"])
	var in_windup: int = 0
	var windup_ok: bool = true
	var struck: bool = false
	for step: int in 300:
		await _frames(1)
		var action: CombatActionResource = hound.current_action()
		if action == null or hound.kin_clip() != &"attack_bite":
			continue
		if hound.current_phase() == ActionQueueComponent.Phase.WINDUP:
			in_windup += 1
			windup_ok = windup_ok and hound.figure.animator.clip_frame <= windup_frames + 0.5
		elif hound.current_phase() == ActionQueueComponent.Phase.ACTIVE:
			struck = struck or hound.figure.animator.clip_frame >= windup_frames - 0.5
		if struck and in_windup > 10:
			break
	check.call(ran and in_windup > 10 and windup_ok and struck,
		"a hurt hound runs at the heroes on its gait (%s, %d frames of the cycle seen), and its bite plays frame-locked: the clip's wind-up frames while the blow winds up (%d ticks), its strike's as it lands"
		% [", ".join(PackedStringArray(gaits.keys())), frames_seen.size(), in_windup])
	# Its posture broken, it kneels.
	var broke: bool = hound.stats.damage_poise(99999.0)
	var knelt: bool = false
	for step: int in 40:
		# (A bite that just landed holds it in its hit-stop for a few frames first.)
		await _frames(1)
		knelt = hound.stats.is_knocked_down() and hound.kin_clip() == &"kneel"
		if knelt:
			break
	var kneel_seen: String = "%s, down %s, broke %s" % [hound.kin_clip(), hound.stats.is_knocked_down(), broke]
	# Worn under a quarter, the scuttler wavers between its blows (a foe with no hero near walks home and mends).
	_place_party(barnacle.global_position + Vector3(0.0, 0.0, 3.0))
	barnacle.stats.take_damage(barnacle.stats.health * 0.8)
	var wavered: bool = false
	for step: int in 300:
		await _frames(1)
		if barnacle.calming.is_wavering() and barnacle.kin_clip() == &"waver":
			wavered = true
			break
	check.call(knelt and wavered,
		"a hound whose posture breaks kneels (%s), and a scuttler worn under a quarter wavers between its blows, trembling, head low (%s)"
		% [kneel_seen, barnacle.kin_clip()])
	# Calmed, the hound's grey washes off; it shakes itself, then walks off into the hedge as it fades.
	_place_party(home + Vector3(0.0, 0.0, 3.0))
	await _frames(2)
	var start: Vector3 = hound.visual.position
	hound.calming.calm_entity(_party()[0].player_id)
	await _frames(60)
	var washing: bool = hound.figure.is_calming() and hound.figure.un_inked < 0.05 and hound.kin_clip() == &"calmed" and hound.visual.visible \
		and is_equal_approx(hound.visual.scale.y, 1.0)
	var walked: bool = false
	for step: int in 240:
		await _frames(1)
		if hound.has_faded():
			break
	walked = hound.has_faded() and hound.visual.position.z < start.z - 0.5 and hound.figure.walking_off
	# Burnt to nothing, the Tide-Wight greys right through and crumbles.
	wight.stats.take_damage(wight.stats.health + 10.0)
	await _frames(30)
	var crumbled: bool = wight.figure.story == &"scattered" and wight.figure.un_inked > 0.99 and wight.kin_clip() == &"collapse"
	check.call(washing and walked and crumbled,
		"a calmed hound's grey washes off as its calm plays (un-inked %.2f, %s) and it stays whole a moment, then walks off as it fades; a Tide-Wight burnt to nothing greys through and crumbles (%s, %.2f)"
		% [hound.figure.un_inked, hound.kin_clip(), wight.kin_clip(), wight.figure.un_inked])
	pack.despawn_mobs()
	pack.queue_free()
	await _frames(2)


func _party() -> Array[ActorBase]:
	return level.party_in_order()


func _place_party(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in level.party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		var spot: Vector3 = at + Vector3((float(seat % 4) - 1.5) * 1.6, 0.0, 0.0)
		level.streamer.ensure_ground_at(spot)
		spot.y = level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, spot))
		seat += 1


func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame
