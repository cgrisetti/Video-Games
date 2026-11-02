## The seamless world's checks (10_WORLD_ARCHITECTURE.md), run by
## tools/smoke_test.gd once the classic tests are done: it moves the seated
## party into the Landblock world and walks it up the corridor.
##   1  the grid's coordinate maths and the split-screen union
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
extends RefCounted

const TOWN_SQUARE: Vector3 = Vector3(64.0, 0.0, 20.0)
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
	await _settle([Vector2i(0, 0), Vector2i(0, -1)])
	_check_world_start()
	await _check_navigation_across_seam()
	await _check_layers_up_the_corridor()
	await _check_world_state_persistence()


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


# --- The world as it starts ---------------------------------------------------

func _check_world_start() -> void:
	check.call(grid.get_chunk_state(Vector2i(0, 0)) == FULL and grid.get_chunk_state(Vector2i(0, -1)) == FULL
		and grid.get_chunk_state(Vector2i(0, -2)) == WorldGridManager.ChunkState.VISUAL_CLUTTER and grid.get_chunk_state(Vector2i(0, -3)) == WorldGridManager.ChunkState.HORIZON_HLOD,
		"from Bramblebridge's green: the village and the Moss-Oaks fully in, the gorge as clutter, the Ring as horizon")
	check.call(not grid.is_hlod_visible(Vector2i(0, -1)) and grid.is_hlod_visible(Vector2i(0, -2)) and grid.is_hlod_visible(Vector2i(0, -3)),
		"the Sinaya Gatehouse's and the standing stones' HLOD proxies stand on the horizon; the loaded Moss-Oaks' is hidden")
	var town: Node3D = grid.gameplay_root(Vector2i(0, 0))
	check.call(town != null and town.find_child("ForestGate", true, false) != null and town.find_child("GateBlocker", true, false) == null
		and world.raid_portal != null and world.raid_portal.target_instance == InstanceManager.DUNGEON_DOJO and world.chime_shrine != null and world.scribe_desk != null,
		"the Forest Gate stands open, and the Raid Portal (to the instanced expedition), Chime-Shrine and Scribe Desk are all there")
	var first: ActorBase = _people()[0]
	check.call(WorldGridConfig.world_to_chunk(first.global_position) == Vector2i(0, 0) and first.is_on_floor(), "the party stands on the village green in Chunk (0, 0)")
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
	check.call(latecomer.delta_count() == 1 and latecomer.has_entity_state(Vector2i(0, 0), &"town_banner"), "a fresh run forgets the expedition but keeps the village's state")
	latecomer.free()


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
