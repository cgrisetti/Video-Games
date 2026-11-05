## Oakshire Vale's checks (12_WORLD_OAKSHIRE_VALE_GDD.md, 13_STARTING_ZONE_ENCOUNTER_DESIGN.md),
## run by tools/smoke_test.gd after the seamless world's:
##   1  the layout: 12 x 12 chunks of 128 m, 100 walked and 44 skirt, the four
##      rings' heights, terrace cliffs steeper than 50° and gentle road ramps
##   2  the dressing: 2,800+ canopy trees (18–28 a forest chunk, 4.5 m apart,
##      canopies above 5.5 m), 18 hero trees, 650+ boulders (no more than 8 a
##      chunk) and a lantern pole and runestone every 75 m of road
##   3  the landblocks: 68 townsfolk (18 quest givers, 14 vendors, 16 guards,
##      20 villagers), the four portal aprons with their Signs and levels, and
##      the six families' spawners with 18–25 m leashes and 45–90 s respawns
##   4  in play: the party arrives at Wayfarer-Green, the village's chunks
##      ([5, 5], [5, 6], [6, 5]) stream in with their folk, creatures stand on
##      the ground, the ford is 0.4 m deep and splashes, a quest giver shows
##      their quest, a weapon vendor opens the Armory, walking into the village
##      makes it your respawn, and a portal's barrier blocks the way until the
##      party's level opens it
extends RefCounted

const FULL: int = WorldGridManager.ChunkState.FULL_GAMEPLAY
const VILLAGE_CHUNKS: Array[Vector2i] = [Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 5)]

var tree: SceneTree
var check: Callable
var vale: OakshireValeLayout
var level: OakshireVale
var grid: WorldGridManager


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	vale = OakshireValeLayout.new()
	_check_layout()
	_check_dressing()
	_check_landblocks()
	InstanceManager.current.change_instance(InstanceManager.OAKSHIRE_VALE)
	for frame: int in 900:
		await tree.process_frame
		if tree.current_scene is OakshireVale and InstanceManager.current.is_live():
			break
	level = tree.current_scene as OakshireVale
	check.call(level != null and WorldGridConfig.layout.layout_id() == OakshireValeLayout.LAYOUT_ID,
		"Oakshire Vale loads as its own instance (scenes/worlds/oakshire_vale.tscn) on the vale's layout")
	if level == null:
		return
	grid = level.grid_manager
	await _check_in_play()


# --- 1: the layout -------------------------------------------------------------------

func _check_layout() -> void:
	var walked: int = 0
	var skirt: int = 0
	for z: int in OakshireValeLayout.CHUNKS:
		for x: int in OakshireValeLayout.CHUNKS:
			if vale.has_collision(Vector2i(x, z)):
				walked += 1
			else:
				skirt += 1
	check.call(vale.bounds_min() == Vector2i.ZERO and vale.bounds_max() == Vector2i(11, 11) and is_equal_approx(OakshireValeLayout.SIZE, 12.0 * WorldGridConfig.CHUNK_SIZE)
		and walked == 100 and skirt == 44 and vale.has_baked_field(),
		"Oakshire Vale is 12 x 12 Landblocks (1,536 m): 100 playable inner chunks inside 44 skirt chunks, its ground baked every 2 m")
	var meadow: Vector2 = _ring_range(220.0)
	var terraces: Vector2 = _ring_range(470.0)
	var crags: Vector2 = _ring_range(630.0)
	var river_top: float = 0.0
	var x: float = 300.0
	while x < 1300.0:
		var middle: Vector2 = OakshireValeLayout.river_at(x)
		for across: float in [0.0, 8.0, 18.0]:
			river_top = maxf(river_top, vale.sample_height(x, middle.x + across))
		x += 25.0
	check.call(river_top <= 4.0 and is_equal_approx(vale.water_depth(770.0, OakshireValeLayout.river_at(770.0).x), OakshireValeLayout.RIVER_WATER)
		and meadow.x >= 3.5 and meadow.y <= 14.5 and terraces.x >= 13.5 and terraces.y <= 32.0 and crags.x >= 32.0 and crags.y <= 66.0
		and is_equal_approx(vale.sample_height(OakshireValeLayout.CENTER.x, OakshireValeLayout.CENTER.y), OakshireValeLayout.VILLAGE_HEIGHT),
		"the rings: the river basin %.1f m at most (a 0.4 m ford), the meadow %.1f–%.1f m, the terraces %.1f–%.1f m, the rim crags %.1f–%.1f m, the village saddle +12 m" % [
			river_top, meadow.x, meadow.y, terraces.x, terraces.y, crags.x, crags.y])
	# The terrace risers are cliffs; the roads ramp gently through them.
	var steepest: float = 0.0
	for bearing_degrees: float in [10.0, 150.0, 210.0, 300.0]:
		var theta: float = deg_to_rad(bearing_degrees)
		var stretch: float = OakshireValeLayout.superellipse_factor(theta)
		var d: float = OakshireValeLayout.MEADOW_OUTER + 4.0
		var previous: float = _height_at_d(theta, d)
		while d < OakshireValeLayout.CLIFF_FOOT - 4.0:
			d += 0.5
			var here: float = _height_at_d(theta, d)
			var at: Vector2 = OakshireValeLayout.CENTER + Vector2(sin(theta), -cos(theta)) * d / stretch
			if not vale.is_kept_clear(at.x, at.y, 4.0):
				steepest = maxf(steepest, rad_to_deg(atan2(absf(here - previous), 0.5 / stretch)))
			previous = here
	var road_steepest: float = 0.0
	for petal: int in vale.petal_count():
		var r: float = OakshireValeLayout.ROAD_START + 6.0
		var last: Vector3 = vale.road_point(petal, r)
		while r < vale.road_end(petal) - 8.0:
			r += 2.0
			var here: Vector3 = vale.road_point(petal, r)
			if OakshireValeLayout.river_distance(here.x, here.z) > OakshireValeLayout.RIVER_HALF_WIDTH + OakshireValeLayout.RIVER_BANK + 1.0:
				road_steepest = maxf(road_steepest, rad_to_deg(atan2(absf(here.y - last.y), Vector2(here.x - last.x, here.z - last.z).length())))
			last = here
	check.call(steepest > 50.0 and road_steepest < 13.0 and OakshireValeLayout.ROAD_HALF_WIDTH * 2.0 >= 4.5,
		"the Tier 2 shelves rise in cliffs of %d° (too steep to climb); the 7 m roads ramp through them at %d° at most" % [roundi(steepest), roundi(road_steepest)])


func _height_at_d(theta: float, d: float) -> float:
	var at: Vector2 = OakshireValeLayout.CENTER + Vector2(sin(theta), -cos(theta)) * d / OakshireValeLayout.superellipse_factor(theta)
	return vale.sample_height(at.x, at.y)


## The lowest and highest ground round one ring, off the roads and away from the river and clearings.
func _ring_range(d: float) -> Vector2:
	var low: float = INF
	var high: float = -INF
	for step: int in 144:
		var theta: float = TAU * step / 144.0
		var at: Vector2 = OakshireValeLayout.CENTER + Vector2(sin(theta), -cos(theta)) * d / OakshireValeLayout.superellipse_factor(theta)
		if vale.is_kept_clear(at.x, at.y, 10.0) or OakshireValeLayout.river_distance(at.x, at.y) < OakshireValeLayout.BANK_REACH:
			continue
		var height: float = vale.sample_height(at.x, at.y)
		low = minf(low, height)
		high = maxf(high, height)
	return Vector2(low, high)


# --- 2: the dressing ------------------------------------------------------------------

func _check_dressing() -> void:
	var trees: int = 0
	var boulders: int = 0
	var lanterns: int = 0
	var runestones: int = 0
	var most_trees: int = 0
	var most_boulders: int = 0
	var low_canopy: int = 0
	for z: int in OakshireValeLayout.CHUNKS:
		for x: int in OakshireValeLayout.CHUNKS:
			var chunk: Vector2i = Vector2i(x, z)
			var props: Dictionary = vale._chunk_props(chunk)
			var chunk_trees: int = props["trees"]
			var chunk_boulders: int = props["boulders"]
			trees += chunk_trees
			boulders += chunk_boulders
			most_trees = maxi(most_trees, chunk_trees)
			most_boulders = maxi(most_boulders, chunk_boulders)
			lanterns += (props[OakshireValeLayout.Prop.LANTERN]["transforms"] as Array).size()
			runestones += (props[OakshireValeLayout.Prop.RUNESTONE]["transforms"] as Array).size()
			for canopy: Transform3D in props[OakshireValeLayout.Prop.CANOPY]["transforms"]:
				var base: float = canopy.origin.y - canopy.basis.y.length() * 0.8
				if base - vale.sample_height(canopy.origin.x, canopy.origin.z) < OakshireValeLayout.CANOPY_BASE - 0.4:
					low_canopy += 1
	var spaced: bool = true
	var forest: Dictionary = vale._chunk_props(Vector2i(9, 3))
	var trunks: Array = forest[OakshireValeLayout.Prop.TRUNK]["transforms"]
	for a: int in trunks.size():
		for b: int in range(a + 1, trunks.size()):
			var pa: Vector3 = (trunks[a] as Transform3D).origin
			var pb: Vector3 = (trunks[b] as Transform3D).origin
			spaced = spaced and Vector2(pa.x - pb.x, pa.z - pb.z).length() >= OakshireValeLayout.TREE_SPACING - 0.01
	check.call(trees >= 2800 and most_trees <= OakshireValeLayout.FOREST_TREES.y and trunks.size() >= OakshireValeLayout.FOREST_TREES.x - 2 and spaced and low_canopy == 0,
		"%d canopy trees (no chunk over 28, a forest chunk %d, trunks 4.5 m apart, every canopy above 5.5 m)" % [trees, trunks.size()])
	check.call(vale.hero_trees().size() == 18 and boulders >= 650 and most_boulders <= OakshireValeLayout.BOULDERS_PER_CHUNK.y,
		"18 hero landmark trees and %d granite boulders (no chunk over 8), all hard cover" % boulders)
	var road_length: float = 0.0
	for petal: int in vale.petal_count():
		var r: float = OakshireValeLayout.ROAD_START + 4.0
		var last: Vector3 = vale.road_point(petal, r)
		while r < vale.road_end(petal) - 6.0:
			r += 2.0
			var here: Vector3 = vale.road_point(petal, r)
			road_length += Vector2(here.x - last.x, here.z - last.z).length()
			last = here
	var ring_last: Vector3 = vale.ring_road_point(0.0)
	for step: int in range(1, 721):
		var here: Vector3 = vale.ring_road_point(TAU * step / 720.0)
		road_length += Vector2(here.x - ring_last.x, here.z - ring_last.z).length()
		ring_last = here
	var expected: int = floori(road_length / OakshireValeLayout.WAYMARK_SPACING)
	check.call(lanterns >= expected - 6 and lanterns <= expected + 6 and runestones >= expected - 6,
		"%d lantern poles and %d Scribe Sign-stones along %d m of road (one of each every 75 m)" % [lanterns, runestones, roundi(road_length)])


# --- 3: the landblocks -----------------------------------------------------------------

func _check_landblocks() -> void:
	var roles: Dictionary[int, int] = {}
	var aprons: Array[PortalApron] = []
	var spawners: Array[MobSpawner] = []
	var flocks: Array[AmbientFlock] = []
	var scenes: Array[Node] = []
	for file: String in DirAccess.get_files_at(OakshireValeLayout.LANDBLOCK_FOLDER):
		if not file.begins_with("landblock_") or not file.ends_with(".tscn"):
			continue
		var landblock: Node = (load(OakshireValeLayout.LANDBLOCK_FOLDER + file) as PackedScene).instantiate()
		scenes.append(landblock)
		for node: Node in landblock.find_children("*", "", true, false):
			if node is TownsfolkNPC:
				var role: int = (node as TownsfolkNPC).role
				roles[role] = roles.get(role, 0) + 1
			elif node is PortalApron:
				aprons.append(node as PortalApron)
			elif node is MobSpawner:
				spawners.append(node as MobSpawner)
			elif node is AmbientFlock:
				flocks.append(node as AmbientFlock)
	var givers: int = roles.get(TownsfolkNPC.Role.QUEST_GIVER, 0)
	var vendors: int = roles.get(TownsfolkNPC.Role.VENDOR, 0)
	var guards: int = roles.get(TownsfolkNPC.Role.GUARD, 0)
	var villagers: int = roles.get(TownsfolkNPC.Role.VILLAGER, 0)
	check.call(givers == 18 and vendors == 14 and guards == 16 and villagers == 20,
		"68 friendly folk: %d quest givers, %d vendors, %d Bridge-Warden and Hearth-Guard sentries, %d villagers" % [givers, vendors, guards, villagers])
	var codes: Dictionary[String, int] = {}
	var signs: Dictionary[int, bool] = {}
	for apron: PortalApron in aprons:
		codes[apron.code] = apron.required_level
		signs[apron.scribe_sign] = true
	check.call(aprons.size() == 4 and codes.get("[D1]", 0) == 4 and codes.get("[D2]", 0) == 5 and codes.get("[D3]", 0) == 3 and codes.get("[R1]", 0) == 6 and signs.size() == 4,
		"four portal aprons in the rim crags: [D3] Lvl 3, [D1] Lvl 4, [D2] Lvl 5 and [R1] Lvl 6, each sealed by a different Scribe Sign")
	var families: Dictionary[int, bool] = {}
	var leashes_ok: bool = true
	var behemoth_patrol: int = 0
	for spawner: MobSpawner in spawners:
		leashes_ok = leashes_ok and spawner.leash >= 18.0 and spawner.leash <= 25.0 and spawner.respawn_time == Vector2(45.0, 90.0)
		for id: StringName in spawner.variant_ids:
			var chosen: MobVariantResource = Bestiary.variant(id)
			if chosen != null:
				families[chosen.family] = true
			if id == &"crag_back_behemoth":
				behemoth_patrol = spawner.patrol.size()
	var sheep: bool = false
	var foxes: bool = false
	for flock: AmbientFlock in flocks:
		sheep = sheep or flock.kind == AmbientFlock.Kind.SHEEP
		foxes = foxes or flock.kind == AmbientFlock.Kind.FOX
	check.call(families.size() == 6 and leashes_ok and behemoth_patrol >= 24 and sheep and foxes and Bestiary.all().size() == Bestiary.STARTING_ZONE_COUNT + 6,
		"%d spawners for all six families (18–25 m leashes, 45–90 s respawns), sheep and foxes, and the Crag-Back Cairn-Drake walking a %d-stop round of the High Road" % [
			spawners.size(), behemoth_patrol])
	for landblock: Node in scenes:
		landblock.free()


# --- 4: in play --------------------------------------------------------------------------

func _check_in_play() -> void:
	var glade: Vector3 = vale.camp_center(OakshireValeLayout.Petal.GLADE)
	await _settle([WorldGridConfig.world_to_chunk(glade)])
	var p1: ActorBase = _people()[0]
	check.call(level.region_at(p1.global_position) == "Wayfarer-Green" and p1.is_on_floor() and p1.global_position.distance_to(glade) < 30.0,
		"the party arrives at Wayfarer-Green, standing on the ground")
	await _move_party(Vector3(768.0, 0.0, 790.0))
	await _settle(VILLAGE_CHUNKS)
	# The village's own folk: 14 vendors, its 3 quest givers, 8 Hearth-Guards and 12 villagers.
	var village_folk: int = 0
	var roles: Dictionary[int, int] = {}
	for npc: TownsfolkNPC in level.townsfolk:
		if is_instance_valid(npc) and npc.global_position.distance_to(Vector3(768.0, 12.0, 768.0)) < 80.0:
			village_folk += 1
			roles[npc.role] = roles.get(npc.role, 0) + 1
	var ready: bool = true
	for chunk: Vector2i in VILLAGE_CHUNKS:
		ready = ready and grid.get_chunk_state(chunk) == FULL
	var all_folk: bool = roles.get(TownsfolkNPC.Role.VENDOR, 0) == 14 and roles.get(TownsfolkNPC.Role.QUEST_GIVER, 0) == 3 \
		and roles.get(TownsfolkNPC.Role.GUARD, 0) == 8 and roles.get(TownsfolkNPC.Role.VILLAGER, 0) == 12
	check.call(ready and all_folk and p1.is_on_floor(), "walking into Oakshire-Wick streams in chunks [5, 5], [5, 6] and [6, 5] with all %d of its folk" % village_folk)
	var standing: int = 0
	var mobs: int = 0
	for spawner: MobSpawner in level.spawners:
		for mob: WildMob in spawner.mobs:
			if is_instance_valid(mob) and not mob.stats.is_downed:
				mobs += 1
				if absf(mob.global_position.y - vale.sample_height(mob.global_position.x, mob.global_position.z)) < 0.6:
					standing += 1
	check.call(mobs > 0 and standing == mobs, "the nearby spawners' %d creatures stand on the ground" % mobs)
	for frame: int in 5:
		await tree.physics_frame
	check.call(p1.spawn_transform.origin.distance_to(Vector3(768.0, 12.0, 778.0)) < 8.0, "walking into the village makes it where you get back up")
	await _check_folk(p1)
	await _check_ford(p1)
	await _check_barrier(p1)


func _check_folk(p1: ActorBase) -> void:
	var hud: PlayerHUD = level.huds.get(p1.player_id) as PlayerHUD
	var giver: TownsfolkNPC = null
	var smith: TownsfolkNPC = null
	for npc: TownsfolkNPC in level.townsfolk:
		if not is_instance_valid(npc):
			continue
		if giver == null and npc.role == TownsfolkNPC.Role.QUEST_GIVER and npc.hub == "Oakshire-Wick":
			giver = npc
		if smith == null and npc.role == TownsfolkNPC.Role.VENDOR and npc.wares == TownsfolkNPC.Wares.WEAPONS:
			smith = npc
	if giver == null or smith == null or hud == null:
		check.call(false, "a quest giver and a weapon smith are in the village")
		return
	p1.place_at(Transform3D(Basis.IDENTITY, giver.global_position + Vector3(0.0, 0.2, 1.5)))
	for frame: int in 3:
		await tree.physics_frame
	var pointed: bool = p1.interactable == giver and hud.prompt_text().contains(giver.npc_name)
	giver.interact(p1)
	check.call(pointed and hud.banner_title().contains(giver.npc_name), "standing by %s shows their prompt, and light shows their quest" % giver.npc_name)
	hud.hide_banner()
	smith.interact(p1)
	var desk: ScribeDeskMenu = hud.scribe_desk_menu()
	check.call(desk != null and desk.selected == ScribeDeskMenu.ROW_WEAPON, "%s, %s, opens the Armory at the weapon row" % [smith.npc_name, smith.title])
	if desk != null:
		desk.close()
	await tree.process_frame


## Wading the ford: 0.4 m of water, wet footsteps, and no slowing down.
func _check_ford(p1: ActorBase) -> void:
	var x: float = 640.0
	var middle: float = OakshireValeLayout.river_at(x).x
	var start: Vector3 = Vector3(x, vale.sample_height(x, middle - 14.0) + 0.2, middle - 14.0)
	p1.place_at(Transform3D(Basis.IDENTITY, start))
	grid.prime([start])
	var splashes: Array[int] = [0]
	var hook: Callable = func(cue: StringName) -> void:
		if cue == &"wade":
			splashes[0] += 1
	AudioCues.current.cue_played.connect(hook)
	var depth: float = 0.0
	var fastest: float = 0.0
	for frame: int in 150:
		p1.stats.grant_invulnerability(0.5)
		p1.camera_yaw = PI
		p1.input.inject_move(Vector2(0.0, 1.0))
		await tree.physics_frame
		depth = maxf(depth, vale.water_depth(p1.global_position.x, p1.global_position.z))
		if vale.water_depth(p1.global_position.x, p1.global_position.z) > 0.2:
			fastest = maxf(fastest, Vector2(p1.velocity.x, p1.velocity.z).length())
	p1.input.inject_move(Vector2.ZERO)
	AudioCues.current.cue_played.disconnect(hook)
	check.call(is_equal_approx(depth, OakshireValeLayout.RIVER_WATER) and splashes[0] >= 2 and fastest >= p1.loadout.stats.move_speed * 0.9,
		"wading the river's ford: 0.4 m deep, %d wet footsteps, and full running speed through it" % splashes[0])


## Flagstone-Hollow opens at Level 3: below it the Sign's barrier blocks the arch, above it the way is open.
func _check_barrier(p1: ActorBase) -> void:
	var frame_at: Transform3D = vale.apron_portal(OakshireValeLayout.Petal.ORCHARD)
	var front: Vector3 = frame_at.origin - frame_at.basis.z * 7.0 + Vector3(0.0, 0.3, 0.0)
	p1.place_at(Transform3D(Basis.IDENTITY, front))
	grid.prime([front])
	var progress: PartyProgress = PartyProgress.current
	var xp_before: int = progress.xp
	progress.xp = 0
	var apron: PortalApron = null
	for frame: int in 60:
		await tree.physics_frame
		for found: PortalApron in level.aprons:
			if is_instance_valid(found) and found.code == "[D3]":
				apron = found
	if apron == null:
		check.call(false, "the [D3] apron streams in")
		progress.xp = xp_before
		return
	# From the portal itself (the cliff's rock starts right behind it) out through the barrier.
	var through: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(frame_at.origin + Vector3.UP * 2.5,
		frame_at.origin - frame_at.basis.z * 3.0 + Vector3.UP * 2.5)
	var space: PhysicsDirectSpaceState3D = p1.get_world_3d().direct_space_state
	var blocked: bool = not apron.is_open and not space.intersect_ray(through).is_empty()
	var sealed_prompt: bool = apron.prompt_for(p1).contains("Level 3")
	progress.xp = PartyProgress.LEVEL_XP[2]
	for frame: int in 60:
		await tree.physics_frame
	var open: bool = is_instance_valid(apron) and apron.is_open and space.intersect_ray(through).is_empty()
	progress.xp = xp_before
	check.call(blocked and sealed_prompt and open,
		"below Level 3 the Sign of Warm-Hearth's barrier seals Flagstone-Hollow; at Level 3 it lifts")


# --- Helpers ----------------------------------------------------------------------------

func _people() -> Array[ActorBase]:
	var people: Array[ActorBase] = []
	for actor: ActorBase in CombatDirector.current.party_actors():
		if not actor.is_companion:
			people.append(actor)
	return people


## Everyone to a spot, then its ground loaded at once (players first: the stream follows them).
func _move_party(spot: Vector3) -> void:
	var index: int = 0
	var points: Array[Vector3] = []
	for actor: ActorBase in level.actors.values():
		var at: Vector3 = spot + Vector3((index - 1) * 1.6, 0.0, 0.0)
		at.y = vale.sample_height(at.x, at.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, at))
		points.append(at)
		index += 1
	grid.prime(points)
	await tree.physics_frame


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
