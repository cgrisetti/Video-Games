## The Crown, the Heart-Crag (docs/20 Part II; docs/atlas_sources/
## 04_master_crown_heart_crag.pdf): Zone 5, Lv 15-20, seven areas, no new
## seams, no town. A resurgent volcanic dome about 850 m across in its 1,024 m
## grid, in the middle of The Sound:
##
##   1 South Bay Landing (0, +350; 0 to +8 m), the summit stream's gully, the
##     one gentle beach, and the Lantern-Bearers' Waypost up its west slope
##     (-60, +280; +10 m): shelter, Saffron lantern, respawn, anvil, one vendor
##   2 The Ring Path round the cliff band's foot (+8 to +18 m) and its three
##     warm-spring checkpoints: SW (-240, +140), NW (-120, -310), SE (+230, +150)
##   3 Iron Shore W (-280, 0; +12 to +24 m): steam vents, Old King's Town, the
##     Trial of the Anvil
##   4 Gale Cliffs N (0, -320; +16 to +28 m): Old Sanctum walls facing The
##     Breach, the Trial of the Gale
##   5 Tide Grottos E (+260, +40; +6 to +18 m): violet sap channels, the Trial
##     of the Tide and its Sap-Siphon Totems
##   6 The +32 m cliff band, sheer all round (no invisible walls), cut by the
##     One Cliff Stair (-10, +150) behind its Resonance Barrier; above it the
##     dome climbs to the +65 m Summit Glade (0, -20), the World-Tree and the
##     Harmonic Bell (+35, -10)
##   7 The Sea-Door (+380, +40; -4.5 m) under the east shore's sea until the
##     Ebb, and the Sap Galleries running west under the cliff band to the
##     Heart's chamber beneath the tree (0, -20; -15 m)
class_name CrownHeartCragBuilder
extends IslandBuilder

const DOME_CENTER: Vector2 = Vector2(0.0, -20.0)
const WORLD_TREE_AT: Vector3 = Vector3(0.0, 65.0, -20.0)
const SUMMIT_HEIGHT: float = 65.0
const GLADE_RADIUS: float = 58.0
## The cliff band: its middle radius from the dome's centre, and half its (sheer) width.
const BAND_RADIUS: float = 172.0
const BAND_HALF_WIDTH: float = 3.0
const BAND_TOP: float = 32.0
const BAND_FOOT: float = 18.0
const COAST_RADIUS: float = 412.0
const BAY_RADIUS: float = 360.0
## The last stretch of every shore, from the terrace's edge down to the sea.
const SHORE_RUN: float = 34.0

const LANDING_AT: Vector2 = Vector2(0.0, 350.0)
const WAYPOST_AT: Vector3 = Vector3(-60.0, 10.0, 280.0)
const SPRINGS: Array[Vector2] = [Vector2(-240.0, 140.0), Vector2(-120.0, -310.0), Vector2(230.0, 150.0)]
const SPRING_NAMES: Array[String] = ["The South-West Spring", "The North-West Spring", "The South-East Spring"]
const IRON_SHORE_AT: Vector3 = Vector3(-280.0, 16.0, 0.0)
const GALE_CLIFFS_AT: Vector3 = Vector3(0.0, 20.0, -320.0)
const TIDE_GROTTOS_AT: Vector3 = Vector3(260.0, 10.0, 40.0)
const ARENA_RADIUS: float = 26.0
const STAIR_FOOT: Vector3 = Vector3(-10.0, 18.0, 172.0)
const STAIR_TOP: Vector3 = Vector3(-10.0, 32.5, 128.0)
const STAIR_HALF_WIDTH: float = 3.5
const BELL_AT: Vector3 = Vector3(35.0, 65.0, -10.0)
const SEA_DOOR_AT: Vector3 = Vector3(380.0, -4.5, 40.0)
## The galleries' first hall (under the cove floor) and the Heart's chamber under the tree.
const GALLERY_ENTRANCE: Vector3 = Vector3(352.0, -10.5, 40.0)
const HEART_AT: Vector3 = Vector3(0.0, -15.0, -20.0)
const GALLERY_ROUTE: Array[Vector3] = [Vector3(352.0, -10.5, 40.0), Vector3(250.0, -11.5, 28.0), Vector3(130.0, -13.0, 4.0), Vector3(14.0, -15.0, -20.0)]
const GALLERY_WIDTH: float = 6.0
const GALLERY_HEIGHT: float = 5.0
const PIER_ROOT: Vector3 = Vector3(0.0, 1.6, 364.0)
## The wind off The Breach (north-west) across the Gale Cliffs.
const BREACH_WIND: Vector3 = Vector3(0.62, 0.0, 0.78)


func _define() -> void:
	# 1: the landing, its gully up to the stair, and the waypost on its west slope.
	# The gully is cut a little into the bay's slope (the summit stream's bed), never built up over it.
	add_pad(LANDING_AT, 18.0, 1.4, 10.0)
	add_ramp(Vector3(0.0, 1.6, 340.0), Vector3(-6.0, 10.0, 248.0), 6.0, 10.0)
	add_ramp(Vector3(-6.0, 10.0, 248.0), Vector3(-10.0, 17.5, 182.0), 5.5, 9.0)
	add_pad(Vector2(WAYPOST_AT.x, WAYPOST_AT.z), 11.0, WAYPOST_AT.y, 12.0)
	# 6: the One Cliff Stair cut through the band, and the bell's ground in the glade.
	add_ramp(STAIR_FOOT, STAIR_TOP, STAIR_HALF_WIDTH, 1.5)
	add_pad(Vector2(BELL_AT.x, BELL_AT.z), 9.0, BELL_AT.y, 6.0)
	# 2-5: the springs and the three trials' arenas.
	for spring: Vector2 in SPRINGS:
		add_pad(spring, 6.5, _terrace_height(spring.x, spring.y), 6.0)
	add_pad(Vector2(IRON_SHORE_AT.x, IRON_SHORE_AT.z), ARENA_RADIUS, IRON_SHORE_AT.y, 10.0)
	add_pad(Vector2(GALE_CLIFFS_AT.x, GALE_CLIFFS_AT.z), ARENA_RADIUS, GALE_CLIFFS_AT.y, 10.0)
	add_pad(Vector2(TIDE_GROTTOS_AT.x, TIDE_GROTTOS_AT.z), ARENA_RADIUS, TIDE_GROTTOS_AT.y, 10.0)
	# 7: the Sea-Door's cove, cut into the east shore, and the path down to it from the north.
	add_pad(Vector2(SEA_DOOR_AT.x + 2.0, SEA_DOOR_AT.z), 12.0, SEA_DOOR_AT.y, 5.0)
	add_ramp(Vector3(330.0, 9.0, -40.0), Vector3(372.0, 2.0, -2.0), 3.0, 3.0)
	add_ramp(Vector3(372.0, 2.0, -2.0), Vector3(384.0, -4.5, 26.0), 3.0, 3.0)
	# The Ring Path, round the band's foot, and the spurs to the landing and the door.
	var ring: PackedVector2Array = PackedVector2Array()
	for index: int in 49:
		var angle: float = TAU * float(index) / 48.0
		var radius: float = 292.0 + 14.0 * sin(angle * 3.0 + 0.6)
		ring.append(Vector2(sin(angle) * radius, -cos(angle) * radius))
	add_path(ring, 2.0)
	add_path(PackedVector2Array([Vector2(0.0, 346.0), Vector2(-6.0, 248.0), Vector2(-10.0, 186.0), Vector2(-10.0, 130.0)]), 2.2)
	add_path(PackedVector2Array([Vector2(-50.0, 284.0), Vector2(-8.0, 262.0)]), 1.6)
	add_path(PackedVector2Array([Vector2(300.0, -44.0), Vector2(330.0, -40.0), Vector2(372.0, -2.0), Vector2(384.0, 26.0)]), 1.8)
	add_path(PackedVector2Array([Vector2(-10.0, 128.0), Vector2(0.0, 60.0), Vector2(BELL_AT.x, BELL_AT.z + 8.0)]), 1.8)
	# Named places (walking into one names it).
	add_place("South Bay Landing", Vector3(0.0, 1.4, 350.0), 70.0)
	add_place("The Lantern-Bearers' Waypost", WAYPOST_AT, 28.0)
	for index: int in 3:
		add_place(SPRING_NAMES[index], Vector3(SPRINGS[index].x, 0.0, SPRINGS[index].y), 22.0)
	add_place("Iron Shore", IRON_SHORE_AT, 90.0)
	add_place("Gale Cliffs", GALE_CLIFFS_AT, 95.0)
	add_place("Tide Grottos", TIDE_GROTTOS_AT, 90.0)
	add_place("The One Cliff Stair", Vector3(-10.0, 25.0, 150.0), 32.0)
	add_place("The Summit Glade", WORLD_TREE_AT, 150.0)
	add_place("The Sea-Door", SEA_DOOR_AT, 34.0)
	add_place("The Sap Galleries", Vector3(180.0, -12.0, 12.0), 200.0)
	for index: int in 8:
		var angle: float = TAU * (float(index) + 0.5) / 8.0
		add_place("The Ring Path", Vector3(sin(angle) * 300.0, 12.0, -cos(angle) * 300.0), 120.0)
	add_arrival(CalderaAtlas.ARRIVE_SOUTH_BAY, Vector2(0.0, 352.0))
	add_arrival(CalderaAtlas.ARRIVE_SUMMIT, Vector2(18.0, 8.0))


# --- The dome's ground ------------------------------------------------------------

func _base_height(x: float, z: float) -> float:
	var r0: float = Vector2(x, z).length()
	var coast: float = _coast_radius(x, z, r0)
	if r0 > coast:
		return sea_floor(r0 / coast)
	var rd: float = Vector2(x - DOME_CENTER.x, z - DOME_CENTER.y).length()
	var band: float = _band_radius(x, z, rd)
	if rd < band - BAND_HALF_WIDTH:
		var t: float = smoothstep(band - BAND_HALF_WIDTH, GLADE_RADIUS, rd)
		return BAND_TOP + (SUMMIT_HEIGHT - BAND_TOP) * t + 6.0 * t * (1.0 - t) * detail(x * 0.25, z * 0.25)
	var foot: float = _band_foot(x, z, r0)
	if rd < band + BAND_HALF_WIDTH:
		return lerpf(BAND_TOP, foot, smoothstep(band - BAND_HALF_WIDTH, band + BAND_HALF_WIDTH, rd))
	return _terrace(x, z, r0, rd, band, coast, foot)


## The terrace's height at a spot (the springs sit on it).
func _terrace_height(x: float, z: float) -> float:
	var r0: float = Vector2(x, z).length()
	var rd: float = Vector2(x - DOME_CENTER.x, z - DOME_CENTER.y).length()
	return _terrace(x, z, r0, rd, _band_radius(x, z, rd), _coast_radius(x, z, r0), _band_foot(x, z, r0))


func _terrace(x: float, z: float, r0: float, rd: float, band: float, coast: float, foot: float) -> float:
	var t: float = clampf((rd - band - BAND_HALF_WIDTH) / maxf(1.0, coast - SHORE_RUN - band - BAND_HALF_WIDTH), 0.0, 1.0)
	var weights: Vector4 = _compass(x, z, r0)
	var shore_top: float = 16.0 * weights.x + 7.0 * weights.y + 8.0 * weights.z + 12.0 * weights.w
	var h: float = lerpf(foot, shore_top, smoothstep(0.0, 1.0, t)) + 1.6 * noise(x * 1.4, z * 1.4)
	var inland: float = clampf((coast - r0) / SHORE_RUN, 0.0, 1.0)
	# North and west fall to the sea as cliffs; east and the south bay slope down (the bay's beach runs 0 to 8 m).
	var cliffs: float = weights.x + weights.w * 0.8
	var drop: float = lerpf(smoothstep(0.0, 1.0, inland), smoothstep(0.0, 0.28, inland), cliffs)
	return lerpf(-1.5, h, drop)


func _coast_radius(x: float, z: float, r0: float) -> float:
	var nx: float = x / maxf(r0, 1.0)
	var nz: float = z / maxf(r0, 1.0)
	var coast: float = COAST_RADIUS + 16.0 * noise(nx * 220.0, nz * 220.0)
	var south: float = maxf(0.0, nz)
	return lerpf(coast, BAY_RADIUS, smoothstep(0.86, 0.985, south))


func _band_radius(x: float, z: float, rd: float) -> float:
	var nx: float = (x - DOME_CENTER.x) / maxf(rd, 1.0)
	var nz: float = (z - DOME_CENTER.y) / maxf(rd, 1.0)
	return BAND_RADIUS + 6.0 * noise(nx * 160.0 + 40.0, nz * 160.0)


func _band_foot(x: float, z: float, r0: float) -> float:
	return BAND_FOOT + 2.0 * _compass(x, z, r0).x


## How much a spot faces each way from the dome: north, east, south, west (their squares sum to one).
func _compass(x: float, z: float, r0: float) -> Vector4:
	var nx: float = x / maxf(r0, 1.0)
	var nz: float = z / maxf(r0, 1.0)
	return Vector4(maxf(0.0, -nz) * maxf(0.0, -nz), maxf(0.0, nx) * maxf(0.0, nx), maxf(0.0, nz) * maxf(0.0, nz), maxf(0.0, -nx) * maxf(0.0, -nx))


func _ground_color(x: float, z: float, height: float, up: float) -> Color:
	var r0: float = Vector2(x, z).length()
	var weights: Vector4 = _compass(x, z, r0)
	# Each shore takes on the rock of the isle it faces: ironstone west, wind-scoured basalt north, sap-stained east.
	var rock: Color = CalderaKit.BASALT.lightened(0.18)
	rock = rock.lerp(CalderaKit.IRONSTONE, weights.w * 0.85)
	rock = rock.lerp(Color(0.36, 0.3, 0.42), weights.y * 0.6)
	var turf: Color = Color(0.44, 0.58, 0.32).lerp(Color(0.56, 0.58, 0.4), weights.x * 0.6)
	turf = turf.lerp(Color(0.5, 0.42, 0.3), weights.w * 0.4)
	turf = turf.lerp(Color(0.42, 0.44, 0.4), weights.y * 0.45)
	if height > BAND_TOP - 0.5:
		turf = Color(0.5, 0.64, 0.32).lerp(Color(0.62, 0.66, 0.34), smoothstep(BAND_TOP, SUMMIT_HEIGHT, height))
	var patch: float = detail(x * 0.6, z * 0.6)
	return shore_or(height, up, turf.lerp(turf.darkened(0.12), patch * 0.5 + 0.5), rock)


func _scatter_species(x: float, z: float, height: float, up: float, roll: float) -> int:
	if height < 1.2:
		return Species.ROCK if height > -0.6 and roll < 0.08 else -1
	if up < 0.62:
		return Species.BASALT_SPIRE if roll < 0.05 else -1
	if height > BAND_TOP + 4.0:
		# The dome: scattered oaks round the glade, ferns in the grass.
		var rd: float = Vector2(x - DOME_CENTER.x, z - DOME_CENTER.y).length()
		if rd < GLADE_RADIUS + 6.0:
			return Species.FERN_TUFT if roll < 0.06 else -1
		return Species.OAK_TREE if roll < 0.05 else (Species.FERN_TUFT if roll < 0.14 else -1)
	var r0: float = Vector2(x, z).length()
	var weights: Vector4 = _compass(x, z, r0)
	if roll < 0.05 * weights.w + 0.02:
		return Species.BOULDER
	if roll < 0.08 + 0.05 * weights.z:
		return Species.ASH_TREE if weights.x < 0.5 else Species.ROCK
	if roll < 0.14:
		return Species.FERN_TUFT
	return -1


# --- Structures ------------------------------------------------------------------------

func build_structures(root: Node3D) -> void:
	_build_landing(root)
	_build_waypost(root)
	_build_ring_path(root)
	_build_iron_shore(root)
	_build_gale_cliffs(root)
	_build_tide_grottos(root)
	_build_cliff_band(root)
	_build_summit(root)
	_build_sea_door_and_galleries(root)


func landmark_silhouette(into: LandblockTerrain.MeshMerge) -> void:
	# The trunk; the crown's lobes are the live boughs' own materials (WorldTree.make_far_crown).
	CalderaKit.add_post(into, WORLD_TREE_AT, 3.2, 6.5, 40.0, Color(0.42, 0.34, 0.26), 10)


func _build_landing(root: Node3D) -> void:
	var seam: LoadSeamResource = CalderaAtlas.seam(CalderaAtlas.SEAM_CROWN_LANDING)
	var head: Vector3 = seam.anchor(isle.isle_id)
	var dock: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_pier(dock, PIER_ROOT, head, 5.0, head.y)
	root.add_child(CalderaKit.mesh_node("LandingPier", dock))
	var middle: Vector3 = (PIER_ROOT + head) * 0.5
	CalderaKit.solid_box(root, "LandingDeck", Vector3(middle.x, head.y - 0.2, middle.z), Vector3(5.0, 0.4, head.z - PIER_ROOT.z), 0.0, ActorBase.LAYER_LOW_SCENERY)
	var bell: SkiffBell = SkiffBell.new()
	bell.name = "CrownLandingBell"
	bell.seam_id = seam.seam_id
	bell.position = head + Vector3(-1.6, 0.0, -2.0)
	root.add_child(bell)
	var skiff: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_skiff(skiff)
	var moored: MeshInstance3D = CalderaKit.mesh_node("MooredSkiff", skiff)
	moored.position = head + Vector3(4.6, -1.5, -2.0)
	moored.rotation.y = PI
	root.add_child(moored)
	CalderaKit.sign_label(root, "LandingSign", "South Bay Landing\nThe Crown · Lv 15-20", ground(-6.0, 344.0) + Vector3(0.0, 2.6, 0.0))


func _build_waypost(root: Node3D) -> void:
	var at: Vector3 = ground(WAYPOST_AT.x, WAYPOST_AT.z)
	var hut: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_hut(hut, at + Vector3(-4.0, 0.0, -2.0), Vector3(5.0, 3.0, 4.0), 0.4, CalderaKit.STONE, CalderaKit.DARK_STONE)
	CalderaKit.add_post(hut, at + Vector3(2.5, 0.0, 1.5), 0.12, 0.16, 3.4, CalderaKit.DARK_TIMBER, 6)
	CalderaKit.add_box(hut, at + Vector3(4.0, 0.45, -1.0), Vector3(1.4, 0.9, 0.8), CalderaKit.DARK_STONE)
	CalderaKit.add_box(hut, at + Vector3(4.0, 1.0, -1.0), Vector3(1.0, 0.25, 0.5), CalderaKit.DARK_STONE.darkened(0.3))
	root.add_child(CalderaKit.mesh_node("Waypost", hut))
	CalderaKit.solid_box(root, "WaypostWalls", at + Vector3(-4.0, 1.5, -2.0), Vector3(5.0, 3.0, 4.0), 0.4)
	CalderaKit.glow_sphere(root, "SaffronLantern", at + Vector3(2.5, 3.5, 1.5), 0.32, CalderaKit.SAFFRON, 3.0)
	CalderaKit.light(root, "LanternLight", at + Vector3(2.5, 3.6, 1.5), CalderaKit.SAFFRON, 2.0, 16.0)
	var anchor: WarmSpring = WarmSpring.new()
	anchor.name = "RespawnAnchor"
	anchor.spring_name = "The Lantern-Bearers' Waypost"
	anchor.show_pool = false
	anchor.heals = false
	anchor.position = at + Vector3(0.0, 0.0, 3.0)
	root.add_child(anchor)
	var quartermaster: TownsfolkNPC = TownsfolkNPC.new()
	quartermaster.name = "Quartermaster"
	quartermaster.role = TownsfolkNPC.Role.VENDOR
	quartermaster.npc_name = "Tamsin Brightwick"
	quartermaster.title = "Waypost Quartermaster"
	quartermaster.hub = "The Lantern-Bearers' Waypost"
	quartermaster.wares = TownsfolkNPC.Wares.WEAPONS
	quartermaster.wares_note = "repairs at the anvil, arms and Ring-Coats"
	quartermaster.body_color = Color(0.5, 0.36, 0.22)
	quartermaster.accent_color = CalderaKit.SAFFRON
	quartermaster.npc_seed = 51
	quartermaster.position = at + Vector3(3.0, 0.0, -2.6)
	root.add_child(quartermaster)
	CalderaKit.sign_label(root, "WaypostSign", "The Lantern-Bearers' Waypost\nrespawn · anvil · quartermaster", at + Vector3(0.0, 4.2, 3.0))


func _build_ring_path(root: Node3D) -> void:
	for index: int in 3:
		var spring: WarmSpring = WarmSpring.new()
		spring.name = "WarmSpring%d" % (index + 1)
		spring.spring_name = SPRING_NAMES[index]
		spring.position = ground(SPRINGS[index].x, SPRINGS[index].y)
		root.add_child(spring)
	# Lantern-poles along the Ring Path (and up the gully), the dome's waymarks.
	for index: int in 24:
		var angle: float = TAU * (float(index) + 0.25) / 24.0
		var radius: float = 292.0 + 14.0 * sin(angle * 3.0 + 0.6) + 4.0
		var spot: Vector3 = ground(sin(angle) * radius, -cos(angle) * radius)
		root.add_child(WorldKitInstance.make("RingLantern%d" % index, WorldVisualCatalog.KIT_WIND_LANTERN_POST, spot, angle))
	for z: float in [320.0, 280.0, 240.0, 200.0]:
		var x: float = lerpf(0.0, -10.0, (340.0 - z) / 160.0) + 3.5
		root.add_child(WorldKitInstance.make("GullyLantern%d" % int(z), WorldVisualCatalog.KIT_WIND_LANTERN_POST, ground(x, z), 0.0))


func _build_iron_shore(root: Node3D) -> void:
	var at: Vector3 = ground(IRON_SHORE_AT.x, IRON_SHORE_AT.z)
	var arena: CrownTrialArena = CrownTrialArena.new()
	arena.name = "TrialOfTheAnvil"
	arena.trial_id = CalderaWorldState.TRIAL_ANVIL
	arena.title = "The Trial of the Anvil"
	arena.pillar = "posture and Shatterpoint: break the Colossus's poise, then strike"
	arena.arena_radius = ARENA_RADIUS
	arena.variant_ids = [Bestiary.FORGE_CLAD_SENTINEL, Bestiary.FORGE_CLAD_SENTINEL, Bestiary.ANVIL_WARDEN_COLOSSUS]
	arena.accent = CalderaKit.IRON_AMBER
	arena.position = at
	root.add_child(arena)
	# Old King's Town: the sunken foundations of the old kingdom's shore town.
	var ruins: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var walls: Array[Vector4] = [Vector4(-318.0, -50.0, 14.0, 0.2), Vector4(-300.0, 44.0, 12.0, 1.4), Vector4(-246.0, -46.0, 10.0, 0.9),
		Vector4(-330.0, 12.0, 16.0, 1.6), Vector4(-250.0, 48.0, 9.0, 0.3), Vector4(-338.0, -24.0, 8.0, 0.0)]
	for index: int in walls.size():
		var wall: Vector4 = walls[index]
		CalderaKit.add_ruin_wall(ruins, ground(wall.x, wall.y), wall.z, 2.6, wall.w, CalderaKit.IRONSTONE.lerp(CalderaKit.STONE, 0.45), 70 + index)
		CalderaKit.solid_box(root, "RuinWall%d" % index, ground(wall.x, wall.y) + Vector3(0.0, 0.9, 0.0), Vector3(0.9, 1.8, wall.z), wall.w, ActorBase.LAYER_LOW_SCENERY)
	root.add_child(CalderaKit.mesh_node("OldKingsTown", ruins))
	# The steam vents: the same hot rock as Iron-Ness.
	for index: int in 4:
		var vent: Vector3 = ground([-338.0, -306.0, -248.0, -262.0][index], [26.0, -58.0, 54.0, -30.0][index])
		CalderaKit.plume(root, "SteamVent%d" % index, vent + Vector3(0.0, 0.3, 0.0), Color(0.95, 0.94, 0.92, 0.6), 3.4, 0.8, 22)
		CalderaKit.glow_sphere(root, "VentGlow%d" % index, vent + Vector3(0.0, 0.05, 0.0), 0.7, Color(1.0, 0.5, 0.2), 1.4)
	CalderaKit.sign_label(root, "IronShoreSign", "Iron Shore\nOld King's Town · Lv 15-18", ground(-236.0, 4.0) + Vector3(0.0, 3.0, 0.0))


func _build_gale_cliffs(root: Node3D) -> void:
	var at: Vector3 = ground(GALE_CLIFFS_AT.x, GALE_CLIFFS_AT.z)
	var arena: CrownTrialArena = CrownTrialArena.new()
	arena.name = "TrialOfTheGale"
	arena.trial_id = CalderaWorldState.TRIAL_GALE
	arena.title = "The Trial of the Gale"
	arena.pillar = "mobility and wind-shear: shelter in the walls' lee, dash through the gusts"
	arena.arena_radius = ARENA_RADIUS
	arena.variant_ids = [Bestiary.RIME_WING_HARRIER, Bestiary.RIME_WING_HARRIER, Bestiary.RIME_WING_HARRIER, Bestiary.STORM_CALLER_VAELEN]
	arena.accent = CalderaKit.GALE_AZURE
	arena.position = at
	root.add_child(arena)
	var gale: BreachGale = BreachGale.new()
	gale.name = "BreachGale"
	gale.wind = BREACH_WIND
	gale.radius = ARENA_RADIUS + 4.0
	arena.add_child(gale)
	arena.gale = gale
	# The Old Sanctum walls: megalithic wind-breaks across the wind (never above the 3.2 m sightline).
	var wind_yaw: float = atan2(BREACH_WIND.x, BREACH_WIND.z)
	var spots: Array[Vector2] = [Vector2(-14.0, -10.0), Vector2(6.0, -14.0), Vector2(-6.0, 6.0), Vector2(14.0, 4.0), Vector2(0.0, 18.0)]
	var masonry: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in spots.size():
		var spot: Vector3 = ground(at.x + spots[index].x, at.z + spots[index].y)
		var wall: Node3D = Node3D.new()
		wall.name = "OldSanctumWall%d" % index
		wall.position = spot
		wall.rotation.y = wind_yaw
		wall.set_meta(&"half_length", 3.0)
		root.add_child(wall)
		gale.walls.append(wall)
		CalderaKit.add_ruin_wall(masonry, spot, 6.0, 2.9, wind_yaw + PI * 0.5, CalderaKit.PALE_STONE.darkened(0.15), 90 + index)
		CalderaKit.solid_box(root, "SanctumWallBody%d" % index, spot + Vector3(0.0, 1.3, 0.0), Vector3(6.0, 2.6, 1.0), wind_yaw)
	root.add_child(CalderaKit.mesh_node("OldSanctumWalls", masonry))
	for index: int in 3:
		CalderaKit.plume(root, "SeaSpray%d" % index, ground(-30.0 + index * 30.0, -372.0) + Vector3(0.0, 1.0, 0.0), Color(0.92, 0.96, 1.0, 0.5), 2.6, 2.0, 14)
	CalderaKit.sign_label(root, "GaleCliffsSign", "Gale Cliffs\nopen to The Breach · Lv 15-18", ground(0.0, -282.0) + Vector3(0.0, 3.0, 0.0))


func _build_tide_grottos(root: Node3D) -> void:
	var at: Vector3 = ground(TIDE_GROTTOS_AT.x, TIDE_GROTTOS_AT.z)
	var arena: CrownTrialArena = CrownTrialArena.new()
	arena.name = "TrialOfTheTide"
	arena.trial_id = CalderaWorldState.TRIAL_TIDE
	arena.title = "The Trial of the Tide"
	arena.pillar = "darkness and cleansing: cleanse the three Sap-Siphons with Star-Tide or Warm-Hearth"
	arena.arena_radius = ARENA_RADIUS
	arena.variant_ids = [Bestiary.TARNISHED_SCRIBE_WIGHT, Bestiary.TARNISHED_SCRIBE_WIGHT, Bestiary.TARNISHED_SCRIBE_WIGHT, Bestiary.SIPHON_PRELATE]
	arena.accent = CalderaKit.TIDE_VIOLET
	arena.position = at
	root.add_child(arena)
	for index: int in 3:
		var angle: float = TAU * float(index) / 3.0 + 0.4
		var totem: SapSiphonTotem = SapSiphonTotem.new()
		totem.name = "SapSiphonTotem%d" % (index + 1)
		totem.position = ground(at.x + cos(angle) * 15.0, at.z + sin(angle) * 15.0)
		root.add_child(totem)
		arena.totems.append(totem)
	# The old kingdom's sluice channels, still weeping violet sap down to the sea.
	var channels: LandblockTerrain.MeshMerge = CalderaKit.merge()
	# They run to the shore either side of the Sea-Door's cove, never across it.
	var lanes: Array[float] = [-34.0, -22.0, 34.0]
	for index: int in 3:
		var start: Vector2 = Vector2(at.x + 10.0, at.z + lanes[index] * 0.6)
		var finish: Vector2 = Vector2(392.0, at.z + lanes[index])
		var a: Vector3 = ground(start.x, start.y) + Vector3(0.0, 0.2, 0.0)
		var b: Vector3 = ground(finish.x, finish.y) + Vector3(0.0, 0.2, 0.0)
		CalderaKit.add_beam(channels, a, b, 1.2, CalderaKit.DARK_STONE)
		var sap: MeshInstance3D = MeshInstance3D.new()
		sap.name = "SapRun%d" % index
		var strip: LandblockTerrain.MeshMerge = CalderaKit.merge()
		CalderaKit.add_beam(strip, a + Vector3(0.0, 0.62, 0.0), b + Vector3(0.0, 0.62, 0.0), 0.5, Color.WHITE)
		sap.mesh = strip.commit()
		sap.material_override = CalderaKit.glow(CalderaKit.SAP_VIOLET, 1.6)
		sap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sap)
	# Grotto arches over the shore, and bioluminescent glints in the rock pools.
	for index: int in 3:
		var spot: Vector3 = ground(318.0 + index * 14.0, -20.0 + index * 48.0)
		CalderaKit.add_arch(channels, spot, 5.0, 6.0, PI * 0.5, CalderaKit.BASALT.lightened(0.15))
	root.add_child(CalderaKit.mesh_node("SluicesAndGrottos", channels))
	for index: int in 10:
		var glint: Vector3 = ground(330.0 + float(index % 5) * 12.0, -10.0 + float(index) * 9.0)
		CalderaKit.glow_sphere(root, "Glint%d" % index, glint + Vector3(0.0, 0.15, 0.0), 0.22, Color(0.5, 0.9, 1.0), 2.4)
	CalderaKit.sign_label(root, "TideGrottosSign", "Tide Grottos\nwhere the old kingdom drained the sap · Lv 15-18", ground(222.0, 40.0) + Vector3(0.0, 3.0, 0.0))


func _build_cliff_band(root: Node3D) -> void:
	# Basalt columns along the band's foot all round: the wall reads as stone, honest and sheer.
	var columns: MultiMesh = MultiMesh.new()
	columns.transform_format = MultiMesh.TRANSFORM_3D
	columns.mesh = CalderaKit.species_mesh(Species.BASALT_SPIRE)
	var spots: Array[Transform3D] = []
	var count: int = 260
	for index: int in count:
		var angle: float = TAU * float(index) / float(count)
		var nx: float = sin(angle)
		var nz: float = -cos(angle)
		var rd: float = BAND_RADIUS + 6.0 * noise(nx * 160.0 + 40.0, nz * 160.0) + BAND_HALF_WIDTH + 1.2
		var x: float = DOME_CENTER.x + nx * rd
		var z: float = DOME_CENTER.y + nz * rd
		if Vector2(x - STAIR_FOOT.x, z - 150.0).length() < 12.0:
			continue
		var tall: float = 2.2 + 1.4 * absf(detail(x * 2.0, z * 2.0))
		spots.append(Transform3D(Basis(Vector3.UP, angle * 7.0).scaled(Vector3(1.3, tall, 1.3)), Vector3(x, height_at(x, z) - 1.0, z)))
	columns.instance_count = spots.size()
	for index: int in spots.size():
		columns.set_instance_transform(index, spots[index])
	var band: MultiMeshInstance3D = MultiMeshInstance3D.new()
	band.name = "CliffBandColumns"
	band.multimesh = columns
	band.material_override = CalderaKit.vertex_material()
	root.add_child(band)
	# The One Cliff Stair: dressed steps up the cut, and the Resonance Barrier where it enters the band.
	var steps: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var run: float = STAIR_FOOT.distance_to(STAIR_TOP)
	var treads: int = int(run / 1.4)
	for index: int in treads:
		var t: float = float(index) / float(treads)
		var at: Vector3 = STAIR_FOOT.lerp(STAIR_TOP, t)
		CalderaKit.add_box(steps, Vector3(at.x, height_at(at.x, at.z) + 0.02, at.z), Vector3(STAIR_HALF_WIDTH * 2.0 - 0.4, 0.22, 0.9), CalderaKit.PALE_STONE.darkened(0.06 * float(index % 2)))
	root.add_child(CalderaKit.mesh_node("OneCliffStair", steps))
	var barrier: ResonanceBarrier = ResonanceBarrier.new()
	barrier.name = "ResonanceBarrier"
	barrier.width = STAIR_HALF_WIDTH * 2.0 + 6.0
	var gate_z: float = 154.0
	barrier.position = ground(STAIR_FOOT.x, gate_z)
	root.add_child(barrier)
	CalderaKit.sign_label(root, "StairSign", "The One Cliff Stair\nthe only way up the +32 m cliff band", ground(STAIR_FOOT.x + 9.0, 178.0) + Vector3(0.0, 2.6, 0.0))


func _build_summit(root: Node3D) -> void:
	var tree: WorldTree = WorldTree.new()
	tree.name = "WorldTree"
	tree.position = ground(WORLD_TREE_AT.x, WORLD_TREE_AT.z) - Vector3(0.0, 0.3, 0.0)
	root.add_child(tree)
	var bell: HarmonicBell = HarmonicBell.new()
	bell.name = "HarmonicBell"
	bell.position = ground(BELL_AT.x, BELL_AT.z)
	root.add_child(bell)
	CalderaKit.sign_label(root, "GladeSign", "The Summit Glade · +65 m\nThe World-Tree", ground(-14.0, 30.0) + Vector3(0.0, 3.0, 0.0))


func _build_sea_door_and_galleries(root: Node3D) -> void:
	var door: SeaGate = SeaGate.new()
	door.name = "SeaDoor"
	door.title = "The Sea-Door"
	door.beyond = "bared by the Ebb: gather here to go down into the Sap Galleries"
	door.facing_yaw = PI * 0.5
	door.position = Vector3(SEA_DOOR_AT.x - 10.0, SEA_DOOR_AT.y, SEA_DOOR_AT.z)
	root.add_child(door)
	var inward: PartyThreshold = PartyThreshold.new()
	inward.name = "SeaDoorThreshold"
	inward.radius = 4.5
	inward.position = SEA_DOOR_AT + Vector3(-4.0, 0.05, 0.0)
	inward.destination = GALLERY_ENTRANCE + Vector3(-6.0, 0.2, 0.0)
	inward.destination_yaw = PI * 0.5
	inward.ring_color = CalderaKit.SAP_VIOLET
	inward.enabled = false
	root.add_child(inward)
	door.threshold = inward
	# The Sap Galleries: a descending tunnel under the cliff band to the Heart's chamber.
	var galleries: Node3D = Node3D.new()
	galleries.name = "SapGalleries"
	root.add_child(galleries)
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var sap: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in GALLERY_ROUTE.size() - 1:
		var a: Vector3 = GALLERY_ROUTE[index]
		var b: Vector3 = GALLERY_ROUTE[index + 1]
		var flat: Vector3 = Vector3(b.x - a.x, 0.0, b.z - a.z)
		var yaw: float = atan2(flat.x, flat.z)
		var length: float = flat.length()
		var pieces: int = int(length / 6.0) + 1
		for piece: int in pieces:
			var t0: float = float(piece) / float(pieces)
			var t1: float = float(piece + 1) / float(pieces)
			var p0: Vector3 = a.lerp(b, t0)
			var p1: Vector3 = a.lerp(b, t1)
			var middle: Vector3 = (p0 + p1) * 0.5
			var span: float = length / float(pieces) + 0.4
			var tilt: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, atan2(p0.y - p1.y, length / float(pieces)))
			stone.add_arrays(_box_arrays(Vector3(GALLERY_WIDTH + 2.0, 0.6, span)), Transform3D(tilt, middle - Vector3(0.0, 0.3, 0.0)), CalderaKit.DARK_STONE)
			stone.add_arrays(_box_arrays(Vector3(GALLERY_WIDTH + 2.0, 0.6, span)), Transform3D(tilt, middle + Vector3(0.0, GALLERY_HEIGHT + 0.3, 0.0)), CalderaKit.BASALT)
			for side: float in [-1.0, 1.0]:
				var wall: Vector3 = middle + (Basis(Vector3.UP, yaw) * Vector3(side * (GALLERY_WIDTH * 0.5 + 0.5), GALLERY_HEIGHT * 0.5, 0.0))
				stone.add_arrays(_box_arrays(Vector3(1.0, GALLERY_HEIGHT + 0.6, span)), Transform3D(tilt, wall), CalderaKit.BASALT.lightened(0.08))
			sap.add_arrays(_box_arrays(Vector3(0.6, 0.06, span)), Transform3D(tilt, middle + Vector3(0.0, 0.04, 0.0)), Color.WHITE)
			var body: StaticBody3D = StaticBody3D.new()
			body.name = "GalleryPiece%d_%d" % [index, piece]
			body.collision_layer = ActorBase.LAYER_WORLD
			body.collision_mask = 0
			body.transform = Transform3D(tilt, middle)
			for part: Array in [[Vector3(GALLERY_WIDTH + 2.0, 0.6, span), Vector3(0.0, -0.3, 0.0)], [Vector3(GALLERY_WIDTH + 2.0, 0.6, span), Vector3(0.0, GALLERY_HEIGHT + 0.3, 0.0)],
					[Vector3(1.0, GALLERY_HEIGHT, span), Vector3(-(GALLERY_WIDTH * 0.5 + 0.5), GALLERY_HEIGHT * 0.5, 0.0)],
					[Vector3(1.0, GALLERY_HEIGHT, span), Vector3(GALLERY_WIDTH * 0.5 + 0.5, GALLERY_HEIGHT * 0.5, 0.0)]]:
				var shape: CollisionShape3D = CollisionShape3D.new()
				var box: BoxShape3D = BoxShape3D.new()
				box.size = part[0]
				shape.shape = box
				shape.position = part[1]
				body.add_child(shape)
			galleries.add_child(body)
			if piece % 6 == 0:
				CalderaKit.light(galleries, "SapLight%d_%d" % [index, piece], middle + Vector3(0.0, 3.0, 0.0), CalderaKit.SAP_VIOLET, 1.6, 14.0)
	var walls: MeshInstance3D = CalderaKit.mesh_node("GalleryStone", stone)
	galleries.add_child(walls)
	var sap_run: MeshInstance3D = MeshInstance3D.new()
	sap_run.name = "SapChannel"
	sap_run.mesh = sap.commit()
	sap_run.material_override = CalderaKit.glow(CalderaKit.SAP_VIOLET, 1.8)
	galleries.add_child(sap_run)
	# The Heart's chamber under the World-Tree: its roots, and the True Raid's portal.
	var chamber: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_post(chamber, HEART_AT - Vector3(0.0, 0.6, 0.0), 15.0, 15.0, 0.6, CalderaKit.DARK_STONE, 24)
	CalderaKit.add_post(chamber, HEART_AT + Vector3(0.0, 9.0, 0.0), 15.0, 15.0, 0.8, CalderaKit.BASALT, 24)
	for index: int in 10:
		var angle: float = TAU * float(index) / 10.0
		var root_foot: Vector3 = HEART_AT + Vector3(cos(angle) * 13.0, 0.0, sin(angle) * 13.0)
		CalderaKit.add_beam(chamber, root_foot, HEART_AT + Vector3(cos(angle) * 4.0, 9.0, sin(angle) * 4.0), 1.0, Color(0.44, 0.34, 0.26))
	# Its round wall, open only where the gallery comes in from the east.
	for index: int in 24:
		var angle: float = TAU * (float(index) + 0.5) / 24.0
		if minf(angle, TAU - angle) < 0.35:
			continue
		var wall_at: Vector3 = HEART_AT + Vector3(cos(angle) * 15.6, 4.2, sin(angle) * 15.6)
		CalderaKit.add_box(chamber, wall_at, Vector3(1.2, 9.6, 4.3), CalderaKit.BASALT.lightened(0.06 * float(index % 2)), -angle)
		CalderaKit.solid_box(galleries, "ChamberWall%d" % index, wall_at, Vector3(1.2, 9.6, 4.3), -angle)
	galleries.add_child(CalderaKit.mesh_node("HeartChamber", chamber))
	var floor_body: StaticBody3D = CalderaKit.solid_cylinder(galleries, "ChamberFloor", HEART_AT - Vector3(0.0, 0.6, 0.0), 15.0, 0.6)
	floor_body.name = "ChamberFloor"
	CalderaKit.glow_sphere(galleries, "HeartGlow", HEART_AT + Vector3(0.0, 4.5, 0.0), 1.6, CalderaKit.SAP_VIOLET.lerp(CalderaKit.HEARTH_SAFFRON, 0.3), 2.8)
	CalderaKit.light(galleries, "HeartLight", HEART_AT + Vector3(0.0, 4.0, 0.0), CalderaKit.SAP_VIOLET, 3.0, 24.0)
	# The True Raid's portal ring (its raid is the next milestone, so it doesn't open yet).
	var portal: Node3D = Node3D.new()
	portal.name = "TrueRaidPortal"
	portal.position = HEART_AT + Vector3(-8.0, 0.02, 0.0)
	portal.add_to_group(&"map_glyphs")
	galleries.add_child(portal)
	var ring: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.tilted(ShapeKit.torus("Ring", 1.5, 1.9, Vector3(0.0, 2.1, 0.0),
		CalderaKit.glow(CalderaKit.TIDE_VIOLET, 2.4)), Vector3(0.0, 0.0, PI * 0.5)))
	portal.add_child(ring)
	portal.add_child(ShapeKit.no_shadow(ShapeKit.cylinder("Platform", 2.6, 2.6, 0.06, Vector3(0.0, 0.03, 0.0), CalderaKit.glow(CalderaKit.TIDE_VIOLET.darkened(0.5), 0.8))))
	CalderaKit.sign_label(galleries, "HeartSign", "The Heart of Everwood\nthe True Raid (Lv 20) waits here: its raid is the next milestone", HEART_AT + Vector3(-8.0, 4.4, 0.0))
	var outward: PartyThreshold = PartyThreshold.new()
	outward.name = "GalleryExit"
	outward.radius = 3.0
	outward.position = GALLERY_ENTRANCE + Vector3(2.0, 0.05, 0.0)
	outward.destination = SEA_DOOR_AT + Vector3(4.0, 0.2, 0.0)
	outward.destination_yaw = -PI * 0.5
	outward.ring_color = CalderaKit.HEARTH_SAFFRON
	galleries.add_child(outward)
	CalderaKit.sign_label(galleries, "GallerySign", "The Sap Galleries\nback out through the Sea-Door", GALLERY_ENTRANCE + Vector3(2.0, 3.0, 0.0))


static func _box_arrays(size: Vector3) -> Array:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return box.get_mesh_arrays()
