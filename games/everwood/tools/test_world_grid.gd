## The seamless world's checks (10_WORLD_ARCHITECTURE.md), run by
## tools/smoke_test.gd once the classic tests are done: it moves the seated
## party into the Landblock world and walks it up the corridor.
##   1  the grid's coordinate maths and the split-screen union
##   0  the start: the party wakes round the Kindled Bivouac's campfire in
##      Chunk (0, 1) facing the lane, the fire warms everyone to full, and one
##      player walks the walled lane through Oakshire Commons, in at
##      Bramblebridge's south gate and over the canal bridge, which makes the
##      square the party's checkpoint
##   2  the four layers and their hysteresis as the party goes from Chunk
##      (0, 0) to (0, -3), and the HLOD proxies swapping out and back in
##   3  the 2 ms attach queue spreading work over frames and draining, and no
##      orphaned nodes after chunks stream out and back
##   4  WorldStateDB: a cleared camp, an opened Wayfarer's Chest, a resting
##      Water-Shrine and an open Sinaya Gatehouse survive their chunks
##      unloading (the party parked in Chunk (0, 2)) and streaming back in,
##      and a latecomer's snapshot carries all of it
##   5  a navigation path from Bramblebridge's square across the seam at
##      z = 0 into the Moss-Oaks, through the Forest Gate
## With Terrain3D installed the world draws its ground with it (Mode A): the
## checks also follow its regions in and out, then reload the world on the
## built-in meshes (Mode B) to see that still works.
extends RefCounted

const TOWN_SQUARE: Vector3 = Vector3(64.0, 0.0, 20.0)
## The walk from the campfire to the square: along the lane, through the south gate, over the bridge (world x, z).
const LANE_WALK: Array[Vector2] = [Vector2(40.0, 178.0), Vector2(48.0, 178.0), Vector2(56.5, 174.5), Vector2(62.0, 167.0), Vector2(64.0, 156.0),
	Vector2(64.0, 62.0), Vector2(64.0, 40.0), Vector2(64.0, 20.0)]
## Simulated seconds the walk may take (about 200 m at a run).
const WALK_FRAMES: int = 3600
const MOSS_OAKS: Vector3 = Vector3(64.0, 0.0, -30.0)
const GORGE: Vector3 = Vector3(64.0, 3.0, -140.0)
const RING: Vector3 = Vector3(64.0, 6.0, -280.0)
const PARKED: Vector3 = Vector3(64.0, 30.0, 320.0)
const NAV_WAIT_MSEC: int = 20000
const FULL: int = WorldGridManager.ChunkState.FULL_GAMEPLAY

var tree: SceneTree
var check: Callable
var world: EverwoodWorld
var grid: WorldGridManager


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	_check_grid_math()
	InstanceManager.current.change_instance(InstanceManager.EVERWOOD_WORLD)
	for frame: int in 600:
		await tree.process_frame
		if tree.current_scene is EverwoodWorld and InstanceManager.current.is_live():
			break
	world = tree.current_scene as EverwoodWorld
	check.call(world != null and InstanceManager.current.instance_id == InstanceManager.EVERWOOD_WORLD, "the seamless world loads as its own instance (everwood_world)")
	if world == null:
		return
	grid = world.grid_manager
	await _settle([Vector2i(0, 1), Vector2i(0, 0)])
	_check_bivouac_start()
	await _check_campfire_warmth()
	await _check_lane_walk()
	_move_party(TOWN_SQUARE)
	await _settle([Vector2i(0, 0), Vector2i(0, -1)])
	_check_world_start()
	await _check_navigation_across_seam()
	await _check_layers_up_the_corridor()
	await _check_world_state_persistence()
	await _check_builtin_terrain()


# --- 1: the maths --------------------------------------------------------------

func _check_grid_math() -> void:
	check.call(WorldGridConfig.world_to_chunk(Vector3.ZERO) == Vector2i(0, 0) and WorldGridConfig.world_to_chunk(Vector3(127.9, 5.0, 127.9)) == Vector2i(0, 0)
		and WorldGridConfig.world_to_chunk(Vector3(128.0, 0.0, 0.0)) == Vector2i(1, 0) and WorldGridConfig.world_to_chunk(Vector3(-0.1, 0.0, -0.1)) == Vector2i(-1, -1)
		and WorldGridConfig.world_to_chunk(Vector3(64.0, 0.0, -300.0)) == Vector2i(0, -3),
		"world_to_chunk floors into 128 m Landblocks (Chunk (0, 0) is X and Z in [0, 128))")
	check.call(WorldGridConfig.chunk_to_world_origin(Vector2i(0, -1)) == Vector3(0.0, 0.0, -128.0) and WorldGridConfig.chunk_to_world_center(Vector2i(0, -1)) == Vector3(64.0, 0.0, -64.0)
		and WorldGridConfig.world_to_region(Vector3(1000.0, 0.0, -10.0)) == Vector2i(0, -1) and WorldGridConfig.world_to_region(Vector3(1024.0, 0.0, 0.0)) == Vector2i(1, 0),
		"chunk origins and centres, and 1024 m Regions of 8 x 8")
	var split: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, -2)]
	var union: int = 0
	for chunk: Vector2i in WorldGridConfig.all_chunks():
		union += 1 if WorldGridConfig.min_chebyshev_to_focuses(chunk, split) <= WorldGridConfig.LOAD_GAMEPLAY_RADIUS else 0
	check.call(WorldGridConfig.chebyshev_distance(Vector2i(0, 0), Vector2i(2, -1)) == 2 and WorldGridConfig.min_chebyshev_to_focuses(Vector2i(0, -3), split) == 1
		and union == 15 and WorldGridConfig.all_chunks().size() == 18,
		"split-screen players in the village and on the gorge share one union: 15 of the 18 bounded chunks within 1 of either")


# --- 0: waking at the Kindled Bivouac --------------------------------------------

func _check_bivouac_start() -> void:
	var fire: Vector3 = LandblockManifest.CAMPFIRE_POSITION
	var lane_start: Vector3 = Vector3(LandblockManifest.LANE[1].x, 0.0, LandblockManifest.LANE[1].y)
	var round_fire: bool = true
	for person: ActorBase in _people():
		var gap: float = Vector2(person.global_position.x - fire.x, person.global_position.z - fire.z).length()
		var toward_lane: Vector3 = (lane_start - person.global_position) * Vector3(1.0, 0.0, 1.0)
		round_fire = round_fire and gap > HearthCampfire.WARM_RADIUS and gap < 6.0 and person.is_on_floor() and person.facing_vector().dot(toward_lane.normalized()) > 0.6
	check.call(not EverwoodWorld.town_square_reached and round_fire and WorldGridConfig.world_to_chunk(_people()[0].global_position) == LandblockManifest.COMMONS_CHUNK,
		"the party wakes round the Kindled Bivouac's campfire in Chunk (0, 1), on its feet and facing up the lane")
	check.call(grid.get_chunk_state(Vector2i(0, 1)) == FULL and grid.get_chunk_state(Vector2i(0, 0)) == FULL
		and grid.get_chunk_state(Vector2i(0, -1)) == WorldGridManager.ChunkState.VISUAL_CLUTTER and grid.get_chunk_state(Vector2i(0, -2)) == WorldGridManager.ChunkState.HORIZON_HLOD,
		"from the campfire: the commons and Bramblebridge fully in, the Moss-Oaks as clutter, the gorge as horizon")
	var commons: Node3D = grid.gameplay_root(LandblockManifest.COMMONS_CHUNK)
	var town: Node3D = grid.gameplay_root(Vector2i(0, 0))
	var hives: int = 0
	var patches: int = 0
	var low_walls: bool = true
	var walls: int = 0
	if commons != null:
		hives = commons.find_children("Hive?", "Node3D", true, false).size()
		patches = commons.find_children("PumpkinPatch*", "Node3D", true, false).size()
	for root: Node3D in [commons, town]:
		if root == null:
			continue
		for node: Node in root.find_children("LaneWall*", "StaticBody3D", true, false):
			var wall: StaticBody3D = node as StaticBody3D
			walls += 1
			var box: BoxShape3D = (wall.get_node("Collision") as CollisionShape3D).shape as BoxShape3D
			low_walls = low_walls and wall.collision_layer == ActorBase.LAYER_LOW_SCENERY and wall.global_position.y + box.size.y * 0.5 < 0.75
	var lantern: WindLantern = commons.find_child("WindLantern", true, false) as WindLantern if commons != null else null
	check.call(world.campfire != null and world.campfire.persist_id == LandblockManifest.CAMPFIRE and commons.find_child("Homestead", true, false) != null
		and hives == 7 and patches == 2 and lantern != null, "Oakshire Commons is there: the campfire, the stepped-gable homestead, 7 bee-hives, 2 pumpkin patches and a Wind-Lantern on the oak's limb")
	check.call(walls > 40 and low_walls and town != null and town.find_child("SouthGateBeam", true, false) != null and town.find_child("WallSouth", true, false) == null,
		"%d pieces of knee-high dry-stone wall line the lane (LowScenery, so cameras see past them), into Bramblebridge's new south gate" % walls)
	var steepest: float = 0.0
	for index: int in LandblockManifest.LANE.size() - 1:
		var from: Vector2 = LandblockManifest.LANE[index]
		var to: Vector2 = LandblockManifest.LANE[index + 1]
		var steps: int = ceili(from.distance_to(to))
		for step: int in steps:
			var a: Vector2 = from.lerp(to, float(step) / steps)
			var b: Vector2 = from.lerp(to, float(step + 1) / steps)
			var rise: float = absf(LandblockTerrain.sample_height(b.x, b.y) - LandblockTerrain.sample_height(a.x, a.y))
			steepest = maxf(steepest, rad_to_deg(atan2(rise, a.distance_to(b))))
	check.call(steepest <= 15.0, "the lane's grade is %.1f° at most (15° allowed)" % steepest)
	var badge: String = WorldTelemetryBadge.text_for(grid.get_streaming_metrics())
	check.call(badge.begins_with("Landblock (0, 1) · Active: 6 · Clutter: 9 · HLOD: 2"), "the F4 badge at the campfire: %s" % badge)


## Standing by the fire warms the whole party to full, then it burns low (the Water-Shrine's rule).
func _check_campfire_warmth() -> void:
	var fire: HearthCampfire = world.campfire
	if fire == null:
		check.call(false, "the campfire streamed in")
		return
	var people: Array[ActorBase] = _people()
	var start: Transform3D = people[0].global_transform
	for person: ActorBase in people:
		person.stats.take_damage(30.0)
		person.stats.stamina = 10.0
	await tree.physics_frame
	var hurt: bool = people[0].stats.health < people[0].stats.stats.max_health and not fire.is_resting()
	people[0].place_at(Transform3D(start.basis, fire.global_position + Vector3(2.2, 0.3, 0.0)))
	for frame: int in 30:
		await tree.physics_frame
		if fire.is_resting():
			break
	for frame: int in 3:
		await tree.physics_frame
	var full: bool = true
	for person: ActorBase in people:
		full = full and is_equal_approx(person.stats.health, person.stats.stats.max_health) and is_equal_approx(person.stats.stamina, person.stats.stats.max_stamina)
	check.call(hurt and fire.is_resting() and full, "standing by the campfire warms the whole party to full health and stamina, then it burns low for %d s" % roundi(HearthCampfire.REST_TIME))
	people[0].place_at(start)
	await tree.physics_frame


## One player runs the lane from the campfire into the square: never held up
## (no lips or snags), brushing the Wind-Lantern, and the square becomes the checkpoint.
func _check_lane_walk() -> void:
	var walker: ActorBase = _people()[0]
	var lantern: WindLantern = grid.gameplay_root(LandblockManifest.COMMONS_CHUNK).find_child("WindLantern", true, false) as WindLantern
	var chimes_before: int = lantern.chimes if lantern != null else 0
	var target: int = 0
	var slowest: float = INF
	var frames: int = 0
	while target < LANE_WALK.size() and frames < WALK_FRAMES:
		var flat: Vector2 = Vector2(walker.global_position.x, walker.global_position.z)
		var to: Vector2 = LANE_WALK[target] - flat
		if to.length() < 1.2:
			target += 1
			continue
		walker.stats.grant_invulnerability(0.5)
		walker.camera_yaw = atan2(-to.x, -to.y)
		walker.input.inject_move(Vector2(0.0, 1.0))
		await tree.physics_frame
		frames += 1
		# Once up to speed, a run along a straight stretch should never slow.
		if frames > 30 and to.length() > 4.0:
			slowest = minf(slowest, Vector2(walker.velocity.x, walker.velocity.z).length())
	walker.input.inject_move(Vector2.ZERO)
	await tree.physics_frame
	var arrived: bool = target >= LANE_WALK.size()
	check.call(arrived and slowest >= walker.loadout.stats.move_speed * 0.8,
		"one player runs the lane from the campfire through the commons, in at the south gate and over the canal bridge into the square in %.0f s (never below %.1f m/s)" % [
			frames / 60.0, slowest])
	check.call(lantern != null and lantern.chimes > chimes_before, "passing under the oak's limb rings its Wind-Lantern")
	var spot: Vector3 = walker.spawn_transform.origin
	check.call(EverwoodWorld.town_square_reached and world.world_state.has_entity_state(Vector2i(0, 0), LandblockManifest.TOWN_CHECKPOINT)
		and spot.distance_to(LandblockManifest.TOWN_SQUARE_SPAWN) < 6.0 and spot.distance_to(world.scribe_desk.global_position) < 10.0
		and spot.distance_to(world.chime_shrine.global_position) < 10.0,
		"crossing into the square makes it the party's checkpoint, between the Scribe Desk and the Chime-Shrine")


# --- The world as it starts ---------------------------------------------------

func _check_world_start() -> void:
	check.call(grid.get_chunk_state(Vector2i(0, 0)) == FULL and grid.get_chunk_state(Vector2i(0, -1)) == FULL
		and grid.get_chunk_state(Vector2i(0, -2)) == WorldGridManager.ChunkState.VISUAL_CLUTTER and grid.get_chunk_state(Vector2i(0, -3)) == WorldGridManager.ChunkState.HORIZON_HLOD,
		"from Bramblebridge's square: the village and the Moss-Oaks fully in, the gorge as clutter, the Ring as horizon")
	check.call(not grid.is_hlod_visible(Vector2i(0, -1)) and grid.is_hlod_visible(Vector2i(0, -2)) and grid.is_hlod_visible(Vector2i(0, -3)),
		"the Sinaya Gatehouse's and the standing stones' HLOD proxies stand on the horizon; the loaded Moss-Oaks' is hidden")
	var town: Node3D = grid.gameplay_root(Vector2i(0, 0))
	check.call(town != null and town.find_child("ForestGate", true, false) != null and town.find_child("GateBlocker", true, false) == null
		and world.raid_portal != null and world.raid_portal.target_instance == InstanceManager.DUNGEON_DOJO and world.chime_shrine != null and world.scribe_desk != null,
		"the Forest Gate stands open, and the Raid Portal (to the instanced expedition), Chime-Shrine and Scribe Desk are all there")
	if LandblockTerrain.terrain3d_available():
		var terrain: Node3D = grid.terrain3d_node()
		var mismatched: Array[Vector2i] = []
		for chunk: Vector2i in WorldGridConfig.all_chunks():
			if terrain == null or LandblockTerrain.has_terrain3d_region(terrain, chunk) != (grid.get_chunk_state(chunk) != WorldGridManager.ChunkState.UNLOADED):
				mismatched.append(chunk)
		check.call(grid.use_terrain3d and terrain != null and mismatched.is_empty() and int(terrain.get(&"region_size")) == LandblockTerrain.TERRAIN3D_REGION_SIZE
			and int(terrain.get(&"collision_mode")) == LandblockTerrain.TERRAIN3D_COLLISION_DISABLED,
			"Terrain3D draws the ground (Mode A): one 128 m region for each streamed chunk, its own collision off%s" % (
				"" if mismatched.is_empty() else " (regions out of step: %s, region size %s, collision %s)" % [mismatched, terrain.get(&"region_size"), terrain.get(&"collision_mode")]))
	var first: ActorBase = _people()[0]
	check.call(WorldGridConfig.world_to_chunk(first.global_position) == Vector2i(0, 0) and first.is_on_floor(), "the party stands in the village square in Chunk (0, 0)")
	grid.set_telemetry_visible(true)
	var badge: String = WorldTelemetryBadge.text_for(grid.get_streaming_metrics())
	check.call(grid.is_telemetry_visible() and badge.begins_with("Landblock (0, 0) · Active: 9 · Clutter: 12 · HLOD: 2") and badge.contains("· Queue: ") and badge.contains("· Deltas: "),
		"the F4 badge reads the stream: %s" % badge)


# --- 5: navigation over the seam ------------------------------------------------

func _check_navigation_across_seam() -> void:
	var started: int = Time.get_ticks_msec()
	while not (grid.is_navigation_ready(Vector2i(0, 0)) and grid.is_navigation_ready(Vector2i(0, -1))) and Time.get_ticks_msec() - started < NAV_WAIT_MSEC:
		await tree.physics_frame
	# The navigation map takes the new meshes on its own (asynchronous) update.
	var path: PackedVector3Array = PackedVector3Array()
	started = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < NAV_WAIT_MSEC:
		await tree.physics_frame
		path = ChunkNavBuilder.path_between(world.get_world_3d().navigation_map, TOWN_SQUARE, MOSS_OAKS)
		if not path.is_empty() and path[path.size() - 1].distance_to(MOSS_OAKS) < 2.0:
			break
	var crosses: bool = false
	var through_gate: bool = false
	var joined: bool = path.size() >= 2
	# The Forest Gate's opening is 6 m wide at z = 2.
	for index: int in range(1, path.size()):
		var from: Vector3 = path[index - 1]
		var to: Vector3 = path[index]
		crosses = crosses or (from.z > 0.0) != (to.z > 0.0)
		if (from.z > 2.0) != (to.z > 2.0):
			var at_gate: float = lerpf(from.x, to.x, (2.0 - from.z) / (to.z - from.z))
			through_gate = through_gate or absf(at_gate - LandblockManifest.CORRIDOR_X) < 3.0
		joined = joined and from.distance_to(to) < 60.0
	check.call(grid.is_navigation_ready(Vector2i(0, 0)) and grid.is_navigation_ready(Vector2i(0, -1)), "both chunks' navigation meshes are baked (off the main thread)")
	check.call(joined and crosses and through_gate and path[0].distance_to(TOWN_SQUARE) < 2.0 and path[path.size() - 1].distance_to(MOSS_OAKS) < 2.0,
		"a navigation path runs from the village square through the Forest Gate across the z = 0 seam into the Moss-Oaks (%d points)" % path.size())


# --- 2 and 3: up the corridor ----------------------------------------------------

func _check_layers_up_the_corridor() -> void:
	var orphans_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_move_party(MOSS_OAKS)
	# Frames where the queue attached something (it works in frame-sized slices as jobs finish).
	var busy_frames: int = 0
	for frame: int in 900:
		await tree.process_frame
		busy_frames += 1 if grid.last_frame_usec > 50 else 0
		if frame > 14 and grid.is_idle() and grid.get_chunk_state(Vector2i(0, -2)) == FULL:
			break
	check.call(grid.get_chunk_state(Vector2i(0, -2)) == FULL and not grid.is_hlod_visible(Vector2i(0, -2))
		and grid.get_chunk_state(Vector2i(0, -3)) == WorldGridManager.ChunkState.VISUAL_CLUTTER and grid.is_hlod_visible(Vector2i(0, -3)),
		"into the Moss-Oaks: the gorge streams fully in (its HLOD proxy hides), the Ring comes in as clutter")
	check.call(busy_frames >= 2 and grid.queue_depth() == 0, "the attach queue spread the gorge over %d frames (at most %d µs of attaching a frame, %d µs for one step) and drained" % [
		busy_frames, grid.peak_frame_usec, grid.peak_step_usec])
	_move_party(GORGE)
	await _settle([Vector2i(0, -3)])
	check.call(grid.get_chunk_state(Vector2i(0, 0)) == FULL and grid.get_chunk_state(Vector2i(0, -3)) == FULL and not grid.is_hlod_visible(Vector2i(0, -3)),
		"on the gorge: the Ring streams in, and the village, two chunks back, stays loaded (unload only past 2)")
	_move_party(RING)
	await _settle([])
	check.call(grid.get_chunk_state(Vector2i(0, 0)) == WorldGridManager.ChunkState.VISUAL_CLUTTER and grid.is_hlod_visible(Vector2i(0, 0))
		and grid.gameplay_root(Vector2i(0, 0)) == null and grid.get_chunk_state(Vector2i(0, -1)) == FULL and world.boss != null,
		"in the Ring: the village's gameplay streams out and its HLOD proxy shows again; the Moss-Oaks, two back, stays; the Cairnsman is there")
	# A player dancing on the seam between the gorge and the Ring never makes chunks thrash.
	_move_party(Vector3(64.0, 6.0, -254.0))
	await _settle([])
	var changes: Array[int] = [0]
	var count_change: Callable = func(_chunk: Vector2i, _state: int) -> void: changes[0] += 1
	grid.chunk_state_changed.connect(count_change)
	for flip: int in 6:
		_move_party(Vector3(64.0, 6.0, -255.0 if flip % 2 == 0 else -257.0))
		for frame: int in 14:
			await tree.process_frame
	grid.chunk_state_changed.disconnect(count_change)
	check.call(changes[0] == 0, "six crossings of the seam at z = -256 change no chunk's layers (hysteresis)")
	_move_party(MOSS_OAKS)
	await _settle([Vector2i(0, 0)])
	for frame: int in 6:
		await tree.process_frame
	var orphans_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	check.call(orphans_after <= orphans_before, "chunks streamed out and back leave no orphaned nodes (%d before, %d after)" % [orphans_before, orphans_after])


# --- 4: remembered state ----------------------------------------------------------

func _check_world_state_persistence() -> void:
	var db: WorldStateDB = world.world_state
	var camp: MinionCamp = _camp(LandblockManifest.CAMP_BRAMBLE)
	var chest: RewardChest = world.wayfarer_chest
	var shrine: WaterShrine = world.water_shrine
	var gate: CoopGate = world.coop_gate
	check.call(camp != null and chest != null and shrine != null and gate != null and camp.minions.size() == 3, "the Bramble Camp, the Wayfarer's Chest, the Water-Shrine and the Sinaya Gatehouse are streamed in")
	if camp == null or chest == null or shrine == null or gate == null:
		return
	var ids: Array[int] = [camp.get_instance_id(), chest.get_instance_id(), shrine.get_instance_id(), gate.get_instance_id()]
	for minion: WoodlandMinion in camp.minions:
		minion.stats.take_damage(minion.stats.health + 100.0)
	# One person opens the chest, another (or the same one, after) walks into the shrine's mist.
	var people: Array[ActorBase] = _people()
	people[0].place_at(Transform3D(Basis.IDENTITY, chest.global_position + Vector3(0.0, 0.3, 1.2)))
	if people.size() > 1:
		people[1].place_at(Transform3D(Basis.IDENTITY, shrine.global_position + Vector3(1.2, 0.3, 0.0)))
	gate.open(CoopGate.Method.BELL_WINCH)
	for frame: int in 120:
		await tree.physics_frame
		if chest.is_open and people.size() == 1:
			people[0].place_at(Transform3D(Basis.IDENTITY, shrine.global_position + Vector3(1.2, 0.3, 0.0)))
		if camp.is_cleared and chest.is_open and shrine.is_resting():
			break
	check.call(camp.is_cleared and chest.is_open and shrine.is_resting() and gate.is_open, "the camp is cleared, the chest opened, the shrine blessed and the gate raised")
	var oaks: Vector2i = Vector2i(0, -1)
	check.call(bool(db.get_entity_state(oaks, LandblockManifest.CAMP_BRAMBLE).get("cleared", false)) and bool(db.get_entity_state(oaks, LandblockManifest.WAYFARER_CHEST).get("opened", false))
		and db.has_entity_state(oaks, LandblockManifest.WATER_SHRINE) and bool(db.get_entity_state(Vector2i(0, -2), LandblockManifest.SINAYA_GATE).get("opened", false)),
		"WorldStateDB holds all four, filed by Landblock (%d deltas)" % db.delta_count())
	# Park everyone in Chunk (0, 2), far enough for both chunks' gameplay to stream out.
	_move_party(PARKED)
	for actor: ActorBase in world.actors.values():
		actor.set_physics_process(false)
	await _settle([])
	check.call(grid.gameplay_root(oaks) == null and grid.gameplay_root(Vector2i(0, -2)) == null and world.camps.is_empty() and world.coop_gate == null
		and world.wayfarer_chest == null, "with the party parked in Chunk (0, 2), the Moss-Oaks' and the gorge's gameplay is gone")
	if grid.use_terrain3d:
		check.call(not LandblockTerrain.has_terrain3d_region(grid.terrain3d_node(), Vector2i(0, -3)) and LandblockTerrain.has_terrain3d_region(grid.terrain3d_node(), Vector2i(0, 1)),
			"the Ring's Terrain3D region left with its chunk; the meadow's, near the party, is there")
	# Back again: a teleport primes the chunks first, as a recall does.
	grid.prime([MOSS_OAKS, GORGE])
	for actor: ActorBase in world.actors.values():
		actor.set_physics_process(true)
	_move_party(MOSS_OAKS)
	await _settle([oaks, Vector2i(0, -2)])
	camp = _camp(LandblockManifest.CAMP_BRAMBLE)
	chest = world.wayfarer_chest
	shrine = world.water_shrine
	gate = world.coop_gate
	var fresh: bool = camp != null and chest != null and shrine != null and gate != null and not ids.has(camp.get_instance_id()) and not ids.has(chest.get_instance_id()) \
		and not ids.has(shrine.get_instance_id()) and not ids.has(gate.get_instance_id())
	check.call(fresh and camp.is_cleared and camp.minions.is_empty() and chest.is_open and shrine.is_resting() and gate.is_open,
		"streamed back in from scratch: the camp is still cleared and empty, the chest open, the shrine resting and the gate raised")
	# A latecomer gets it all in one snapshot (plain keys: it survives JSON too).
	var snapshot: Dictionary = db.export_snapshot()
	var latecomer: WorldStateDB = WorldStateDB.new()
	var applied: Array[int] = [0]
	latecomer.entity_state_changed.connect(func(_chunk: Vector2i, _id: StringName, _state: Dictionary) -> void: applied[0] += 1)
	latecomer.import_snapshot(JSON.parse_string(JSON.stringify(snapshot)) as Dictionary)
	check.call(latecomer.delta_count() == db.delta_count() and applied[0] == db.delta_count() and is_equal_approx(latecomer.world_time, db.world_time)
		and bool(latecomer.get_entity_state(oaks, LandblockManifest.WAYFARER_CHEST).get("opened", false))
		and bool(latecomer.get_entity_state(Vector2i(0, -2), LandblockManifest.SINAYA_GATE).get("opened", false)),
		"a latecomer's snapshot (export, JSON, import) carries every delta and the shared clock, and tells each bound entity")
	latecomer.set_entity_state(Vector2i(0, 0), &"town_banner", {"raised": true})
	latecomer.clear_expedition_transient_state()
	check.call(latecomer.delta_count() == 3 and latecomer.has_entity_state(Vector2i(0, 0), &"town_banner")
		and latecomer.has_entity_state(Vector2i(0, 0), LandblockManifest.TOWN_CHECKPOINT) and latecomer.has_entity_state(LandblockManifest.COMMONS_CHUNK, LandblockManifest.CAMPFIRE)
		and not latecomer.has_entity_state(oaks, LandblockManifest.WAYFARER_CHEST),
		"a fresh run forgets the expedition but keeps the village's and the commons' state (the square checkpoint, the campfire's rest)")
	latecomer.free()


# --- Mode B -------------------------------------------------------------------

## The world on its built-in meshes, as on a machine without Terrain3D.
func _check_builtin_terrain() -> void:
	WorldGridManager.force_builtin_terrain = true
	InstanceManager.current.change_instance(InstanceManager.EVERWOOD_WORLD)
	for frame: int in 600:
		await tree.process_frame
		if tree.current_scene is EverwoodWorld and tree.current_scene != world and InstanceManager.current.is_live():
			break
	world = tree.current_scene as EverwoodWorld
	grid = world.grid_manager
	await _settle([Vector2i(0, 0)])
	var village: Node3D = grid.chunk_node(Vector2i(0, 0))
	check.call(not grid.use_terrain3d and grid.terrain3d_node() == null and village != null and village.find_child("Terrain_0_0", true, false) is MeshInstance3D
		and _people()[0].is_on_floor() and _people()[0].global_position.distance_to(LandblockManifest.TOWN_SQUARE_SPAWN) < 6.0,
		"without Terrain3D (or with --terrain=builtin) each chunk draws its own ground mesh, and the party, back in the world, starts in the square it reached")
	WorldGridManager.force_builtin_terrain = false


# --- Helpers ----------------------------------------------------------------

## The people seated here (not companions), in seat order.
func _people() -> Array[ActorBase]:
	var people: Array[ActorBase] = []
	for actor: ActorBase in CombatDirector.current.party_actors():
		if not actor.is_companion:
			people.append(actor)
	return people


func _camp(id: StringName) -> MinionCamp:
	for camp: MinionCamp in world.camps:
		if is_instance_valid(camp) and camp.persist_id == id:
			return camp
	return null


func _move_party(spot: Vector3) -> void:
	var index: int = 0
	for actor: ActorBase in world.actors.values():
		actor.place_at(Transform3D(Basis.IDENTITY, spot + Vector3((index - 1) * 1.6, 0.2, 0.0)))
		index += 1


## Waits until the stream is quiet (and `full` chunks are fully in), at least two heartbeats.
func _settle(full: Array[Vector2i]) -> void:
	for frame: int in 1200:
		await tree.process_frame
		if frame < 26 or not grid.is_idle():
			continue
		var ready: bool = true
		for chunk: Vector2i in full:
			ready = ready and grid.get_chunk_state(chunk) == FULL
		if ready:
			return
