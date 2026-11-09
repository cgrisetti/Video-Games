## Embershore's acceptance checks (docs/27_EMBERSHORE_MASTER_V2.md §12), run on the
## live isle by tools/test_caldera_isles.gd (so by the smoke test and
## tools/run_caldera_checks.gd) right after the roads are checked:
##   1  the grid and the generator's data: 16 x 8 landblocks, three levels of
##      detail, every collider resident, the heightmap, seven masks, 28 landmarks
##      and the generator's trees standing
##   2  every landmark's height is the ground's (±0.25 m)
##   3  the corridor is 2.6 to 2.8 km from Bramblebridge to Hearthstead and
##      crosses the Dover only at the Doverslap Gorge Bridge
##   4  both rivers run downhill all the way, 0.6 m deep, and are built with their
##      springs, the weir and the race
##   5  the settlements and landmarks stand: cottages, stalls, chime-posts,
##      bridges, gatehouse, windmill, gate, sleepers, pier, stair, quay, portal
##   6  no walls: deep water and the Deep-Hush turn the party back by the tide
##   7  the mill-wheel stops and turns again with the flags; the Downs Gate
##      opens only from the Hearthstead side
##   8  the Doverslap reveal plays once per hero, never mid-fight
##   9  cards and gear change only within a chime-post's reach
##  10  nothing invisible blocks the way: every collider has a mesh about it
extends RefCounted

const POI_SLACK: float = 0.25
const CORRIDOR_MIN: float = 2600.0
const CORRIDOR_MAX: float = 2800.0

var check: Callable
var level: CalderaArchipelagoWorld
var tree: SceneTree
var builder: EmbershoreBuilder


func run(live_level: CalderaArchipelagoWorld, checker: Callable, scene_tree: SceneTree) -> void:
	check = checker
	level = live_level
	tree = scene_tree
	builder = CalderaAtlas.builder_for(CalderaAtlas.ISLE_EMBERSHORE) as EmbershoreBuilder
	if builder == null or not builder.loaded or level.streamer.active_isle != CalderaAtlas.ISLE_EMBERSHORE:
		check.call(false, "Embershore is live with its generator's data (run tools/worldgen/embershore_gen.py world/embershore/gen 7)")
		return
	_check_grid_and_data()
	_check_poi_heights()
	_check_corridor()
	_check_rivers()
	_check_structures()
	await _check_no_walls()
	await _check_wheel_and_gate()
	await _check_reveal()
	await _check_loadout_gate()
	_check_no_invisible_walls()
	# Back to the start, the window built, for the streaming checks that follow.
	level.place_party_at(CalderaAtlas.ARRIVE_START)
	level.streamer.load_now([level.tether_centroid()])
	await _frames(2)


# --- 1: the grid and the data ---------------------------------------------------------------

func _check_grid_and_data() -> void:
	var isle: IslandGridResource = builder.isle
	var counts: Dictionary = level.streamer.counts()
	var oaks: int = 0
	var apples: int = 0
	for record: ArchipelagoStreamer.LoadedChunk in level.streamer.chunks.values():
		oaks += (record.scatter.get(IslandBuilder.Species.OAK_TREE, []) as Array).size()
		apples += (record.scatter.get(IslandBuilder.Species.ORCHARD_TREE, []) as Array).size()
	# The generator's smaller trees along the wood's edge are its birch, rowan and holly (docs/32 §6): still where it put them.
	var wood_mix: int = builder.settlement.list("wood_mix").size()
	var masks_ok: bool = true
	for mask_name: StringName in EmbershoreBuilder.MASK_NAMES:
		masks_ok = masks_ok and (builder.masks.get(mask_name, PackedByteArray()) as PackedByteArray).size() == EmbershoreBuilder.MASK_COLUMNS * EmbershoreBuilder.MASK_ROWS
	check.call(isle.chunks_x() == 16 and isle.chunks_z_count() == 8 and isle.grid_size() == Vector2(2048.0, 1024.0)
		and builder.lod_quads() == PackedInt32Array([128, 64, 32]) and builder.collision_resident() and int(counts["bodies"]) == 128
		and builder.heights.size() == EmbershoreBuilder.HEIGHT_COLUMNS * EmbershoreBuilder.HEIGHT_ROWS and masks_ok and builder.poi.size() == 28
		and oaks + wood_mix >= 1250 and oaks >= 1150 and wood_mix <= 130 and apples >= 90,
		"Embershore: 16 x 8 landblocks (2,048 x 1,024 m) at 1, 2 and 4 m, all %d colliders resident, the 2049 x 1025 heightmap and 7 masks read, %d landmarks, %d Moss-Oaks (and %d birch, rowan and holly at the wood's edge, docs/32) and %d orchard trees standing where the generator put them"
		% [int(counts["bodies"]), builder.poi.size(), oaks, wood_mix, apples])


# --- 2: the landmarks' heights ---------------------------------------------------------------

func _check_poi_heights() -> void:
	var worst: float = 0.0
	var worst_name: StringName = &""
	for key: StringName in builder.poi:
		var at: Vector3 = builder.poi[key]
		var gap: float = absf(builder.height_at(at.x, at.z) - at.y)
		if gap > worst:
			worst = gap
			worst_name = key
	check.call(worst <= POI_SLACK, "every landmark's table height is the ground's within %.2f m (the furthest off: %s by %.2f m)" % [POI_SLACK, worst_name, worst])


# --- 3: the corridor ---------------------------------------------------------------------------

func _check_corridor() -> void:
	var length: float = 0.0
	var dover: Array[PackedFloat32Array] = builder.river_points("dover")
	var crossings: int = 0
	for road_name: String in ["lane", "hollow", "gate", "coast", "downs", "strait", "eel"]:
		var points: PackedVector3Array = builder.road_points(road_name)
		for index: int in points.size() - 1:
			if road_name in ["lane", "hollow", "gate", "coast"]:
				length += Vector2(points[index].x, points[index].z).distance_to(Vector2(points[index + 1].x, points[index + 1].z))
			crossings += _crossings(Vector2(points[index].x, points[index].z), Vector2(points[index + 1].x, points[index + 1].z), dover)
	# The bridge closes the gap between the Holloway's end and the gate road's start, over the Dover.
	var south: Vector3 = builder.landmark(&"doverslap_bridge_south")
	var north: Vector3 = builder.landmark(&"doverslap_bridge_north")
	length += Vector2(south.x, south.z).distance_to(Vector2(north.x, north.z))
	var bridge_crossings: int = _crossings(Vector2(south.x, south.z), Vector2(north.x, north.z), dover)
	check.call(length >= CORRIDOR_MIN and length <= CORRIDOR_MAX and crossings == 0 and bridge_crossings == 1 and is_equal_approx(south.y, 25.88),
		"the corridor runs %.0f m from Bramblebridge to Hearthstead (lane, Holloway, bridge, gate, Coast Road) and crosses the Dover only on the Doverslap Gorge Bridge (deck %.2f m)" % [length, south.y])


static func _crossings(a: Vector2, b: Vector2, river: Array[PackedFloat32Array]) -> int:
	var count: int = 0
	for index: int in river.size() - 1:
		var c: Vector2 = Vector2(river[index][0], river[index][1])
		var d: Vector2 = Vector2(river[index + 1][0], river[index + 1][1])
		if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
			count += 1
	return count


# --- 4: the rivers ---------------------------------------------------------------------------------

func _check_rivers() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var mouths: PackedStringArray = PackedStringArray()
	for river_name: String in ["bramble", "dover"]:
		var points: Array[PackedFloat32Array] = builder.river_points(river_name)
		if not EmbershoreWater.is_monotonic(points):
			problems.append("the %s rises on its way" % river_name)
		for point: PackedFloat32Array in points:
			if absf(point[3] - point[2] - 0.6) > 0.01:
				problems.append("the %s isn't 0.6 m deep" % river_name)
				break
		var mouth: PackedFloat32Array = points[points.size() - 1]
		if mouth[3] > 0.0:
			problems.append("the %s doesn't reach the sea" % river_name)
		mouths.append("%s %.2f -> %.2f m over %d points" % [river_name, points[0][3], mouth[3], points.size()])
		var ribbon: MeshInstance3D = _structure("River_%s" % river_name) as MeshInstance3D
		if ribbon == null or ribbon.mesh == null or ribbon.mesh.get_surface_count() == 0 or ribbon.mesh.surface_get_array_len(0) < points.size():
			problems.append("the %s has no ribbon of water" % river_name)
	for node_name: String in ["BrambleSpring", "DoverSpring", "BrambleWeir", "MillRace", "WeirSpill"]:
		if _structure(node_name) == null:
			problems.append("no %s" % node_name)
	check.call(problems.is_empty(), "the Bramble and the Dover run downhill all the way (%s), 0.6 m over their beds, as ribbons of water with their springs, the weir and the mill race%s"
		% [", ".join(mouths), "" if problems.is_empty() else ": " + "; ".join(problems)])


# --- 5: settlements and landmarks -----------------------------------------------------------------

func _check_structures() -> void:
	var problems: PackedStringArray = PackedStringArray()
	var houses: int = 0
	var posts: int = 0
	var spawners: int = 0
	var sleepers: int = 0
	for node: Node in level.streamer.structures.find_children("*", "", true, false):
		# The two villages' twelve houses each (docs/32 §7: stepped-gable houses and valley cottages, each on the generator's spot).
		if node.is_in_group(EmbershoreSteadings.HOMES) and (String(node.name).begins_with("Bramblebridge") or String(node.name).begins_with("Hearthstead")):
			houses += 1
		var post: ChimePost = node as ChimePost
		if post != null and post.checkpoint:
			posts += 1
		if node is MobSpawner and node.is_in_group(&"caldera_streamed_spawners"):
			spawners += 1
		if String(node.name).begins_with("Sleeper") and node is MeshInstance3D:
			sleepers += 1
	if houses < 24:
		problems.append("%d cottages" % houses)
	if posts != 4:
		problems.append("%d checkpoint chime-posts" % posts)
	if spawners < 15:
		problems.append("%d packs" % spawners)
	if sleepers != 6:
		problems.append("%d sleepers" % sleepers)
	for node_name: String in ["IronStall", "LanternStall", "ProvisionsStall", "BramblebridgeDeck", "DoverslapBridgeDeck", "Gatehouse", "DoverslapReveal", "Windmill",
			"DownsGate", "NorthQuayPier", "QuayStair", "SaltRoadBell", "CrownLandingBell", "OldQuayMarket", "SanctumDoor", "ElderOak", "SanctumArch",
			"Watermill", "MillWheel", "WrightsYard", "ColdSmithy", "ScribeTable", "Pavilion0", "DeepHush", "GrainStrips", "StartChimePost"]:
		if _structure(node_name) == null:
			problems.append("no %s" % node_name)
	var stacks: PackedVector2Array = builder.points_of("sea_stacks")
	var tall: int = 0
	for stack: Vector2 in stacks:
		if builder.height_at(stack.x, stack.y) > 30.0:
			tall += 1
	if tall != 5:
		problems.append("%d sea stacks stand over 30 m" % tall)
	var market: OldQuayMarket = _structure("OldQuayMarket") as OldQuayMarket
	if market != null and not is_equal_approx(market.position.y, -4.5):
		problems.append("the Old Quay isn't at -4.5 m")
	check.call(problems.is_empty(),
		"Embershore stands: %d cottages, Hearthstead's three stalls, Scribe table, market and quay stair, %d checkpoint chime-posts, both bridges, the gatehouse and its reveal, the windmill and the Downs Gate, the watermill, wright's yard and cold smithy, the Elder Oak over the Root-Sanctum, the pier and its bells, the Old Quay at -4.5 m, five sea stacks, six sleepers, the Deep-Hush and %d packs%s"
		% [houses, posts, spawners, "" if problems.is_empty() else ": " + "; ".join(problems)])


# --- 6: no walls -------------------------------------------------------------------------------------

func _check_no_walls() -> void:
	var p1: ActorBase = _p1()
	var before: int = level.tide_returns
	# Into the Sound off North Quay: 1.5 m under, for longer than the tide allows.
	var pier: Vector3 = EmbershoreBuilder.PIER_ROOT
	var sea_spot: Vector3 = Vector3(pier.x + 40.0, CalderaWorldState.current.sea_level_y - 1.5, pier.z - 40.0)
	p1.place_at(Transform3D(Basis.IDENTITY, sea_spot))
	await _seconds(CalderaArchipelagoWorld.DEEP_WATER_TIME + 0.6)
	var tide_took: bool = level.tide_returns == before + 1 and p1.global_position.y > CalderaWorldState.current.sea_level_y - 0.5
	# Past the Deep-Hush: the seal's far side, not the sea's depth, turns them back.
	var seal_in: bool = builder.beyond_seal(1012.0, 300.0) and not builder.beyond_seal(900.0, 300.0) and not builder.beyond_seal(-500.0, 200.0)
	p1.place_at(Transform3D(Basis.IDENTITY, Vector3(1012.0, 1.0, 300.0)))
	await _seconds(CalderaArchipelagoWorld.DEEP_WATER_TIME + 0.6)
	var hush_took: bool = level.tide_returns == before + 2 and not builder.beyond_seal(p1.global_position.x, p1.global_position.z)
	check.call(is_equal_approx(CalderaArchipelagoWorld.DEEP_WATER, 0.9) and tide_took and seal_in and hush_took,
		"no walls: water deeper than %.1f m carries the party back after %.1f s (P1 back at %.1f m), and so does the Deep-Hush's far side (tide returns %d -> %d)"
		% [CalderaArchipelagoWorld.DEEP_WATER, CalderaArchipelagoWorld.DEEP_WATER_TIME, p1.global_position.y, before, level.tide_returns])


# --- 7: the wheel and the gate ---------------------------------------------------------------------

func _check_wheel_and_gate() -> void:
	var state: CalderaWorldState = CalderaWorldState.current
	var wheel: WatermillWheel = _structure("MillWheel") as WatermillWheel
	var turning_first: bool = wheel != null and wheel.turning
	state.set_flag(CalderaWorldState.WHEEL_STOPPED, true)
	await _frames(2)
	var stopped: bool = wheel != null and not wheel.turning
	state.set_flag(CalderaWorldState.ROOT_SANCTUM_CLEARED, true)
	await _frames(2)
	var turning_again: bool = wheel != null and wheel.turning
	state.reset_for_testing()
	await _frames(2)
	check.call(turning_first and stopped and turning_again,
		"the mill-wheel turns, stops when the wheel_stopped flag is set (Lv 5 at the mill) and turns again once the Root-Sanctum is cleared")
	var gate: OneWayGate = _structure("DownsGate") as OneWayGate
	if gate == null:
		check.call(false, "the Downs Gate stands on the Downs road")
		return
	var barred_first: bool = gate.blocks()
	var open_dir: Vector3 = (gate.global_transform.basis * gate.open_side).normalized()
	_place_party(gate.global_position - open_dir * 4.0)
	await _frames(4)
	var still_barred: bool = gate.blocks() and not state.downs_gate_open
	_place_party(gate.global_position + open_dir * 4.0)
	await _frames(4)
	var opened: bool = not gate.blocks() and state.downs_gate_open
	state.reset_for_testing()
	await _frames(2)
	check.call(barred_first and still_barred and opened,
		"the Downs Gate is barred from Mill-Downs, stays barred to a party on that side, and swings open (downs_gate_open) when they come up to it from Hearthstead")


# --- 8: the reveal -----------------------------------------------------------------------------------

func _check_reveal() -> void:
	var reveal: VistaReveal = _structure("DoverslapReveal") as VistaReveal
	var party: Array[ActorBase] = _party()
	if reveal == null or party.size() < 2:
		check.call(false, "the Doverslap reveal stands on the bridge, and a party of two or more walks it")
		return
	PartyProgress.current.reveals_seen.clear()
	var p1: ActorBase = party[0]
	var p2: ActorBase = party[1]
	var camera: PlayerCamera = level.grid.camera_for(p1.player_id)
	var shown_before: int = reveal.shown
	# Everyone off the bridge first, then P1 onto its middle (on the deck, over the gorge).
	_place_party(reveal.global_position + Vector3(0.0, 0.0, 60.0))
	await _frames(2)
	p1.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(0.0, 0.4, 0.0)))
	await _frames(3)
	var who: StringName = p1.loadout.class_id
	var played: bool = reveal.shown == shown_before + 1 and camera != null and camera.is_revealing() and PartyProgress.current.has_seen_reveal(VistaReveal.DOVERSLAP, who)
	# Away and back: not again.
	p1.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(0.0, 0.4, 20.0)))
	await _frames(2)
	p1.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(0.0, 0.4, 0.0)))
	await _frames(3)
	var once: bool = reveal.shown == shown_before + 1
	# P2 mid-fight: a Padfoot woken on the deck beside them holds the reveal back; once it's gone, it plays.
	var spawner: MobSpawner = MobSpawner.new()
	spawner.name = "RevealFoe"
	spawner.territory = "Doverslap Gorge"
	spawner.variant_ids = [&"grey_pelt_prowler"]
	spawner.leash = 30.0
	level.add_child(spawner)
	spawner.global_position = reveal.global_position + Vector3(0.0, 0.0, 60.0)
	spawner.spawn_mobs()
	await _frames(2)
	var foe: WildMob = spawner.mobs[0] if not spawner.mobs.is_empty() else null
	if foe != null:
		foe.spawn_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(3.0, 0.4, 2.0)))
	p2.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(1.5, 0.4, 0.0)))
	await _frames(8)
	var fighting: bool = foe != null and foe.is_engaged() and p2.sign_flow.is_in_combat
	var held: bool = fighting and reveal.shown == shown_before + 1
	spawner.queue_free()
	await _frames(8)
	var second: bool = not p2.sign_flow.is_in_combat and reveal.shown == shown_before + 2
	PartyProgress.current.reveals_seen.clear()
	check.call(played and once and held and second,
		"the Doverslap reveal pulls P1's camera back for %.0f s to look over the Sound once (saved per hero), not again on a second crossing, never mid-fight (P2 held while a Padfoot woke beside them: %s), and P2 gets their own once it's gone"
		% [reveal.seconds, fighting])


# --- 9: cards at chime-posts ------------------------------------------------------------------------

func _check_loadout_gate() -> void:
	var p1: ActorBase = _p1()
	var post: ChimePost = _structure("DoverslapChimePost") as ChimePost
	if post == null:
		check.call(false, "the Doverslap chime-post stands by the gatehouse")
		return
	_place_party(post.global_position + Vector3(40.0, 0.0, 0.0))
	await _frames(2)
	var away: bool = ChimePost.near(p1) == null
	_place_party(post.global_position + Vector3(3.0, 0.0, 2.0))
	await _frames(2)
	var near: bool = ChimePost.near(p1) == post
	check.call(away and near and post.checkpoint and is_equal_approx(ChimePost.LOADOUT_REACH, 14.0),
		"cards and gear change only within %.0f m of a checkpoint chime-post: none 40 m off, the Doverslap post beside it" % ChimePost.LOADOUT_REACH)


# --- 10: nothing invisible --------------------------------------------------------------------------

func _check_no_invisible_walls() -> void:
	var structures: Node3D = level.streamer.structures
	for node: Node in structures.find_children("*", "WorldKitInstance", true, false):
		(node as WorldKitInstance).build()
	var meshes: Array[AABB] = []
	for node: Node in structures.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh != null and mesh.visible:
			meshes.append(mesh.global_transform * mesh.mesh.get_aabb())
	var bodies: int = 0
	var bare: PackedStringArray = PackedStringArray()
	for node: Node in structures.find_children("*", "StaticBody3D", true, false):
		var body: StaticBody3D = node as StaticBody3D
		if body.collision_layer == 0:
			continue
		for shape_node: Node in body.get_children():
			var shape: CollisionShape3D = shape_node as CollisionShape3D
			if shape == null or shape.shape == null:
				continue
			var local: AABB
			if shape.shape is BoxShape3D:
				local = AABB(-(shape.shape as BoxShape3D).size * 0.5, (shape.shape as BoxShape3D).size)
			elif shape.shape is CylinderShape3D:
				var cylinder: CylinderShape3D = shape.shape as CylinderShape3D
				local = AABB(Vector3(-cylinder.radius, -cylinder.height * 0.5, -cylinder.radius), Vector3(cylinder.radius * 2.0, cylinder.height, cylinder.radius * 2.0))
			else:
				continue
			bodies += 1
			var world: AABB = (shape.global_transform * local).grow(1.0)
			var seen: bool = false
			for box: AABB in meshes:
				if box.intersects(world):
					seen = true
					break
			if not seen and bare.size() < 4:
				bare.append("%s/%s" % [body.get_parent().name, body.name])
	check.call(bare.is_empty() and bodies > 40, "nothing invisible blocks the way: all %d solid shapes on Embershore have a mesh about them%s"
		% [bodies, "" if bare.is_empty() else " (bare: %s)" % ", ".join(bare)])


# --- Helpers -----------------------------------------------------------------------------------------

func _structure(node_name: String) -> Node:
	return level.streamer.structures.find_child(node_name, true, false)


func _party() -> Array[ActorBase]:
	var members: Array[ActorBase] = []
	for actor: ActorBase in level.party_in_order():
		if actor.is_multiplayer_authority() and actor.is_local_player() and not actor.is_companion:
			members.append(actor)
	return members


func _p1() -> ActorBase:
	var party: Array[ActorBase] = _party()
	return party[0] if not party.is_empty() else null


func _place_party(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in _party():
		var spot: Vector3 = at + Vector3((float(seat % 4) - 1.5) * 1.6, 0.0, 0.0)
		level.streamer.ensure_ground_at(spot)
		spot.y = level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, spot))
		seat += 1


func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds * 60.0)))
