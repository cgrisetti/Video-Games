## The Crown, the Heart-Crag (docs/20 Part II; docs/atlas_sources/
## 04_master_crown_heart_crag.pdf), redesigned as four shore zones round Miller's
## Oak (docs/23_THE_CROWN_ZONE_REDESIGN.md). Zone 5, Lv 13-14 (Act III on the Bible's 14-level spine; it was Lv 15-20), no new seams, no
## town. A resurgent volcanic dome about 900 m across in its 1,024 m grid:
##
##   South Bay (121° to 247°, Lv 13): the summit stream's gully, the one gentle
##     beach and the Landing; the Lantern-Bearers' Waypost (+10 m) and its
##     lantern-mast; the One Cliff Stair beside the stream's fall. No kin: the
##     hub and its road are safe.
##   Iron Shore (247° to 328°, Lv 13): ironstone shelves stepping down to the
##     sea, steam vents, Old King's Town and its Kiln, the Trial of the Anvil.
##   Gale Cliffs (328° to 15°, Lv 13): the high, bare north face open to The
##     Breach, the Breach Point headland and its Sanctum Arch, the Trial of the
##     Gale.
##   Tide Grottos (15° to 121°, Lv 13): a low, eroded shelf of reeds and
##     willows with sea stacks offshore, the Weeping Arch, the sap sluices, the Trial of the Tide deep
##     in the grottos, and the Sea-Door's cove.
##   The World-Tree (inside the +32 m cliff band, Lv 14): the dome's meadow and
##     the +65 m Summit Glade, the oak and the Harmonic Bell.
##   The Sap Galleries (under the island, Lv 14 and the endgame): the Sea-Door down to the Heart.
##
## Bearings run clockwise from north (-Z) round the island's middle. Where two
## shores meet is a warm spring on the Ring Path (SW, NW, SE) or the Sanctum
## Gate (NE): the Schelling points a split party regroups at.
class_name CrownHeartCragBuilder
extends IslandBuilder

enum Zone { SOUTH_BAY, IRON_SHORE, GALE_CLIFFS, TIDE_GROTTOS, MILLERS_OAK, SAP_GALLERIES }

## What each zone is called on screen, its level band and the music it plays (AudioCatalog profile ids).
const ZONE_NAMES: Array[String] = ["South Bay", "Iron Shore", "Gale Cliffs", "Tide Grottos", "World-Tree", "The Sap Galleries"]
const ZONE_LEVELS: Array[String] = ["Lv 13", "Lv 13", "Lv 13", "Lv 13", "Lv 14", "Lv 14"]
const ZONE_MUSIC: Array[StringName] = [&"crown_south_bay", &"crown_iron_shore", &"crown_gale_cliffs", &"crown_tide_grottos",
	&"crown_millers_oak", &"crown_tide_grottos"]
## Where the shores meet (bearings from the island's middle): the South-East Spring,
## the South-West Spring, the North-West Spring and the Sanctum Gate.
const EDGE_SE: float = 121.0
const EDGE_SW: float = 247.0
const EDGE_NW: float = 328.0
const EDGE_NE: float = 15.0
## The ground blends between shores over this many degrees either side of an edge.
const EDGE_SOFT: float = 12.0
## A shore's music holds this many degrees past its edge (and this far past the cliff band), so it never flaps at a spring.
const EDGE_HOLD: float = 6.0
const BAND_HOLD: float = 8.0

const DOME_CENTER: Vector2 = Vector2(-30.0, -36.0)
const WORLD_TREE_AT: Vector3 = Vector3(-30.0, 65.0, -36.0)
const SUMMIT_HEIGHT: float = 65.0
const GLADE_RADIUS: float = 60.0
## The cliff band: its mean radius from the dome's centre (it wanders ±14 m where the old crust broke), and half its sheer width.
const BAND_RADIUS: float = 250.0
const BAND_HALF_WIDTH: float = 3.0
const BAND_TOP: float = 32.0
const BAND_FOOT: float = 18.0
const COAST_RADIUS: float = 446.0
const BAY_RADIUS: float = 362.0
## The last stretch of every shore, from the terrace's edge down to the sea.
const SHORE_RUN: float = 34.0
## The Breach Point: the north headland jutting out toward The Breach.
const HEADLAND_BEARING: float = 4.0
const HEADLAND_REACH: float = 34.0
const HEADLAND_WIDTH: float = 7.0
## Sea stacks off the Tide Grottos: x, z, radius, height.
const SEA_STACKS: Array[Vector4] = [Vector4(392.0, -286.0, 11.0, 14.0), Vector4(470.0, -102.0, 10.0, 11.0), Vector4(410.0, 252.0, 12.0, 16.0),
	Vector4(452.0, 170.0, 9.0, 9.0)]

## The Ring Path's radius from the island's middle at each bearing (smoothed between these knots).
const RING_KNOTS: Array[Vector2] = [Vector2(0.0, 381.0), Vector2(15.0, 378.0), Vector2(40.0, 380.0), Vector2(65.0, 386.0), Vector2(90.0, 381.0),
	Vector2(105.0, 377.0), Vector2(121.0, 364.0), Vector2(140.0, 350.0), Vector2(160.0, 341.0), Vector2(180.0, 336.0), Vector2(200.0, 338.0),
	Vector2(222.0, 350.0), Vector2(247.0, 372.0), Vector2(268.0, 386.0), Vector2(290.0, 388.0), Vector2(310.0, 384.0), Vector2(328.0, 380.0),
	Vector2(345.0, 382.0)]

const LANDING_AT: Vector2 = Vector2(0.0, 350.0)
const WAYPOST_AT: Vector3 = Vector3(-58.0, 10.0, 300.0)
## The three warm springs, on the Ring Path where the shores meet (SW, NW, SE).
const SPRINGS: Array[Vector2] = [Vector2(-342.4, 145.4), Vector2(-201.4, -322.3), Vector2(312.0, 187.5)]
const SPRING_NAMES: Array[String] = ["The South-West Spring", "The North-West Spring", "The South-East Spring"]
const SANCTUM_GATE_AT: Vector2 = Vector2(97.8, -365.1)
## The trials' arenas, each between the Ring Path and the cliff band with the band at its back (a short spur in from the road).
const IRON_SHORE_AT: Vector3 = Vector3(-332.8, 16.0, -25.4)
const GALE_CLIFFS_AT: Vector3 = Vector3(-71.0, 20.0, -327.6)
const TIDE_GROTTOS_AT: Vector3 = Vector3(256.9, 14.0, -10.9)
const ARENA_RADIUS: float = 24.0
## Each zone's landmark, tall enough to read from both neighbouring springs.
const KILN_AT: Vector2 = Vector2(-298.8, -108.8)
const SANCTUM_ARCH_AT: Vector2 = Vector2(31.8, -454.9)
const WEEPING_ARCH_AT: Vector2 = Vector2(424.2, -137.8)
const KILN_HEIGHT: float = 24.0
const MAST_HEIGHT: float = 20.0
## The One Cliff Stair, cut through the band beside the summit stream's fall.
const STAIR_FOOT: Vector3 = Vector3(-30.0, 18.0, 232.0)
const STAIR_TOP: Vector3 = Vector3(-30.0, 32.5, 186.0)
const STAIR_HALF_WIDTH: float = 3.5
const FALL_AT: Vector2 = Vector2(-14.0, 210.0)
## The summit stream, from the foot of its fall down the gully to the bay.
const STREAM: Array[Vector2] = [Vector2(-14.0, 214.0), Vector2(-2.0, 244.0), Vector2(12.0, 282.0), Vector2(22.0, 318.0), Vector2(28.0, 346.0),
	Vector2(30.0, 366.0)]
const STREAM_DEPTH: float = 1.6
const STREAM_HALF_WIDTH: float = 6.0
const BELL_AT: Vector3 = Vector3(5.0, 65.0, -26.0)
const SEA_DOOR_AT: Vector3 = Vector3(436.0, -4.5, 64.0)
## The galleries' first hall (inland of the cove) and the Heart's chamber under the oak.
const GALLERY_ENTRANCE: Vector3 = Vector3(404.0, -10.5, 62.0)
const HEART_AT: Vector3 = Vector3(-30.0, -15.0, -36.0)
const GALLERY_ROUTE: Array[Vector3] = [Vector3(404.0, -10.5, 62.0), Vector3(300.0, -11.5, 40.0), Vector3(150.0, -13.0, 4.0), Vector3(-16.0, -15.0, -36.0)]
const GALLERY_WIDTH: float = 6.0
const GALLERY_HEIGHT: float = 5.0
const PIER_ROOT: Vector3 = Vector3(0.0, 1.6, 364.0)
## The wind off The Breach (north-west) across the Gale Cliffs.
const BREACH_WIND: Vector3 = Vector3(0.62, 0.0, 0.78)

## The Crown's kin outside the trials (docs/23 §5): [zone, bearing, radius from the middle, variants, kind].
## Kinds: "camp" regrows in 60-120 s; "guard" is a landmark's elite pair (4-6 min); "rare" walks a shore track (12-18 min).
## Every camp sits off the Ring Path and the spurs by more than its kin's waking reach, and none near a spring or the Waypost.
const KIN: Array[Array] = [
	[Zone.IRON_SHORE, 256.0, 418.0, [&"clinker_iron_man", &"clinker_iron_man", &"cinder_scuttler", &"cinder_scuttler"], "camp"],
	[Zone.IRON_SHORE, 258.0, 330.0, [&"clinker_iron_man", &"clinker_iron_man", &"clinker_iron_man"], "camp"],
	[Zone.IRON_SHORE, 312.0, 425.0, [&"cinder_scuttler", &"cinder_scuttler", &"cinder_scuttler"], "camp"],
	[Zone.IRON_SHORE, 293.0, 322.0, [&"forge_clad_sentinel", &"forge_clad_sentinel"], "guard"],
	[Zone.IRON_SHORE, 0.0, 0.0, [&"old_bellows"], "rare"],
	[Zone.GALE_CLIFFS, 336.0, 424.0, [&"gust_padfoot", &"gust_padfoot", &"gust_padfoot"], "camp"],
	[Zone.GALE_CLIFFS, 352.0, 426.0, [&"scree_hob", &"scree_hob", &"scree_hob"], "camp"],
	[Zone.GALE_CLIFFS, 10.0, 332.0, [&"gust_padfoot", &"gust_padfoot", &"scree_hob"], "camp"],
	[Zone.GALE_CLIFFS, 5.0, 448.0, [&"rime_wing_harrier", &"rime_wing_harrier", &"rime_wing_harrier"], "guard"],
	[Zone.GALE_CLIFFS, 0.0, 0.0, [&"grey_squall"], "rare"],
	[Zone.TIDE_GROTTOS, 34.0, 412.0, [&"sap_sodden_bucca", &"sap_sodden_bucca", &"sap_sodden_bucca"], "camp"],
	[Zone.TIDE_GROTTOS, 58.0, 300.0, [&"blight_lasher", &"blight_lasher", &"sap_sodden_bucca"], "camp"],
	[Zone.TIDE_GROTTOS, 116.0, 300.0, [&"blight_lasher", &"blight_lasher"], "camp"],
	[Zone.TIDE_GROTTOS, 70.0, 420.0, [&"tarnished_scribe_wight", &"tarnished_scribe_wight"], "guard"],
	[Zone.TIDE_GROTTOS, 0.0, 0.0, [&"mother_sluice"], "rare"],
]
## Each rare's shore track (bearings at a radius), walked round and back.
const RARE_TRACKS: Dictionary[int, Vector3] = {Zone.IRON_SHORE: Vector3(264.0, 304.0, 420.0), Zone.GALE_CLIFFS: Vector3(332.0, 362.0, 434.0),
	Zone.TIDE_GROTTOS: Vector3(40.0, 84.0, 412.0)}
const CAMP_RESPAWN: Vector2 = Vector2(60.0, 120.0)
const GUARD_RESPAWN: Vector2 = Vector2(240.0, 360.0)
const RARE_RESPAWN: Vector2 = Vector2(720.0, 1080.0)

## The Ring Path's radius at each whole bearing (built once from RING_KNOTS).
var _ring: PackedFloat32Array = PackedFloat32Array()


func _define() -> void:
	_build_ring()
	# South Bay: the landing, the gully road up to the stair, and the waypost on the gully's west slope.
	add_pad(LANDING_AT, 18.0, 1.4, 10.0)
	# The gully road keeps to the ground's own grade up the gully (docs/26), steepening only into the stair's foot.
	var gully_low: float = clampf(_terrace_height(-10.0, 292.0) + 0.3, 3.0, 9.0)
	var gully_high: float = clampf(_terrace_height(-22.0, 256.0) + 0.3, gully_low + 2.0, 15.0)
	add_ramp(Vector3(0.0, 1.6, 342.0), Vector3(-10.0, gully_low, 292.0), 3.5, 8.0)
	add_ramp(Vector3(-10.0, gully_low, 292.0), Vector3(-22.0, gully_high, 256.0), 3.5, 8.0)
	add_ramp(Vector3(-22.0, gully_high, 256.0), Vector3(STAIR_FOOT.x, STAIR_FOOT.y, STAIR_FOOT.z + 4.0), 3.5, 6.0)
	add_pad(Vector2(WAYPOST_AT.x, WAYPOST_AT.z), 11.0, WAYPOST_AT.y, 24.0)
	# The One Cliff Stair cut through the band, and the bell's ground in the glade.
	add_ramp(STAIR_FOOT, STAIR_TOP, STAIR_HALF_WIDTH, 1.5)
	add_pad(Vector2(BELL_AT.x, BELL_AT.z), 9.0, BELL_AT.y, 6.0)
	# The springs (each a level stone basin on the Ring Path) and the three trials' arenas.
	for spring: Vector2 in SPRINGS:
		add_pad(spring, 6.5, clampf(_terrace_height(spring.x, spring.y), 2.0, 14.0), 8.0)
	# Each arena's edge eases over 18 m, so the spur up onto it is a road, not a bank (docs/26).
	add_pad(Vector2(IRON_SHORE_AT.x, IRON_SHORE_AT.z), ARENA_RADIUS, IRON_SHORE_AT.y, 18.0)
	add_pad(Vector2(GALE_CLIFFS_AT.x, GALE_CLIFFS_AT.z), ARENA_RADIUS, GALE_CLIFFS_AT.y, 18.0)
	add_pad(Vector2(TIDE_GROTTOS_AT.x, TIDE_GROTTOS_AT.z), ARENA_RADIUS, TIDE_GROTTOS_AT.y, 18.0)
	# The landmarks' footings.
	add_pad(KILN_AT, 9.0, maxf(12.0, _base_height(KILN_AT.x, KILN_AT.y)), 8.0)
	add_pad(SANCTUM_ARCH_AT, 10.0, maxf(20.0, _base_height(SANCTUM_ARCH_AT.x, SANCTUM_ARCH_AT.y)), 8.0)
	# The Sea-Door's cove, cut into the east shore, and the stair down to it from the Ring Path.
	add_pad(Vector2(SEA_DOOR_AT.x + 2.0, SEA_DOOR_AT.z), 12.0, SEA_DOOR_AT.y, 5.0)
	add_ramp(Vector3(384.0, 2.0, 34.0), Vector3(414.0, 1.2, 44.0), 3.0, 3.0)
	add_ramp(Vector3(414.0, 1.2, 44.0), Vector3(428.0, -4.5, 58.0), 3.0, 3.0)
	# The roads: the Ring Path, the gully road, the waypost's spur, the summit walk, the trials' spurs and the Sea-Door's stair.
	var widths: Array[float] = [2.0, 2.2, 1.6, 1.8, 1.8, 1.8, 1.8, 1.8]
	var all_roads: Array[PackedVector2Array] = roads()
	for index: int in all_roads.size():
		# The Ring Path is already drawn as a smooth loop through the springs: it's only rounded, never re-routed.
		add_path(all_roads[index], widths[mini(index, widths.size() - 1)], index != 0)
	# The shore tracks: faint loops out to each shore's landmark and its rare's walk.
	for zone: int in RARE_TRACKS:
		add_path(shore_track(zone), 1.1)
	# The zones (their names lie on the map; walking a shore names it) and the places inside them.
	for zone: int in [Zone.SOUTH_BAY, Zone.IRON_SHORE, Zone.GALE_CLIFFS, Zone.TIDE_GROTTOS, Zone.MILLERS_OAK]:
		add_place(ZONE_NAMES[zone], zone_label_at(zone), 0.0)
	add_place("South Bay Landing", Vector3(LANDING_AT.x, 1.4, LANDING_AT.y), 40.0)
	add_place("The Lantern-Bearers' Waypost", WAYPOST_AT, 30.0)
	for index: int in 3:
		add_place(SPRING_NAMES[index], Vector3(SPRINGS[index].x, 0.0, SPRINGS[index].y), 22.0)
	add_place("The Sanctum Gate", Vector3(SANCTUM_GATE_AT.x, 0.0, SANCTUM_GATE_AT.y), 22.0)
	add_place("The Trial of the Anvil", IRON_SHORE_AT, ARENA_RADIUS + 6.0)
	add_place("The Trial of the Gale", GALE_CLIFFS_AT, ARENA_RADIUS + 6.0)
	add_place("The Trial of the Tide", TIDE_GROTTOS_AT, ARENA_RADIUS + 6.0)
	add_place("Old King's Town", Vector3(KILN_AT.x, 0.0, KILN_AT.y), 46.0)
	add_place("The Breach Point", Vector3(SANCTUM_ARCH_AT.x, 0.0, SANCTUM_ARCH_AT.y), 40.0)
	add_place("The Weeping Arch", Vector3(WEEPING_ARCH_AT.x, 0.0, WEEPING_ARCH_AT.y), 36.0)
	add_place("The One Cliff Stair", Vector3(STAIR_FOOT.x, 25.0, (STAIR_FOOT.z + STAIR_TOP.z) * 0.5), 30.0)
	add_place("The Summit Glade", WORLD_TREE_AT, 80.0)
	add_place("The Sea-Door", SEA_DOOR_AT, 30.0)
	add_place("The Sap Galleries", Vector3(180.0, -12.0, 12.0), 0.0)
	add_arrival(CalderaAtlas.ARRIVE_SOUTH_BAY, Vector2(0.0, 352.0), Vector2(0.0, -1.0))
	add_arrival(CalderaAtlas.ARRIVE_SUMMIT, Vector2(BELL_AT.x - 12.0, BELL_AT.z + 30.0), Vector2(0.0, -1.0))


# --- Zones ------------------------------------------------------------------------------

## A spot's bearing from the island's middle, in degrees clockwise from north.
static func bearing_of(x: float, z: float) -> float:
	return fposmod(rad_to_deg(atan2(x, -z)), 360.0)


## A spot at a bearing and distance from the island's middle (or from `center`).
static func _polar(bearing: float, radius: float, center: Vector2 = Vector2.ZERO) -> Vector2:
	var angle: float = deg_to_rad(bearing)
	return center + Vector2(sin(angle) * radius, -cos(angle) * radius)


## The shore a bearing faces (South Bay, Iron Shore, Gale Cliffs or Tide Grottos).
static func shore_of_bearing(bearing: float) -> Zone:
	var b: float = fposmod(bearing, 360.0)
	if b >= EDGE_SE and b < EDGE_SW:
		return Zone.SOUTH_BAY
	if b >= EDGE_SW and b < EDGE_NW:
		return Zone.IRON_SHORE
	if b >= EDGE_NW or b < EDGE_NE:
		return Zone.GALE_CLIFFS
	return Zone.TIDE_GROTTOS


## The zone a spot is in: under the ground is the Sap Galleries, inside the cliff band the World-Tree, else its shore.
func zone_at(at: Vector3) -> Zone:
	if at.y < height_at(at.x, at.z) - 2.5:
		return Zone.SAP_GALLERIES
	if inside_band(at.x, at.z):
		return Zone.MILLERS_OAK
	return shore_of_bearing(bearing_of(at.x, at.z))


## Whether a spot is up on the dome, inside the cliff band.
func inside_band(x: float, z: float) -> bool:
	var from: Vector2 = Vector2(x, z) - DOME_CENTER
	return from.length() < band_radius_toward(from.normalized())


## The music a spot plays. `holding` is the music playing now: within EDGE_HOLD
## degrees of a shore's edge (or BAND_HOLD metres of the band) the neighbour's
## music keeps playing, so a party standing at a spring hears one tune.
func music_at(at: Vector3, holding: StringName = &"") -> StringName:
	var zone: Zone = zone_at(at)
	var music: StringName = ZONE_MUSIC[zone]
	if holding == &"" or holding == music or zone == Zone.SAP_GALLERIES:
		return music
	var from: Vector2 = Vector2(at.x, at.z) - DOME_CENTER
	if absf(from.length() - band_radius_toward(from.normalized())) < BAND_HOLD:
		var shore: StringName = ZONE_MUSIC[shore_of_bearing(bearing_of(at.x, at.z))]
		if holding == shore or holding == ZONE_MUSIC[Zone.MILLERS_OAK]:
			return holding
	if zone == Zone.MILLERS_OAK:
		return music
	var bearing: float = bearing_of(at.x, at.z)
	for edge: float in [EDGE_SE, EDGE_SW, EDGE_NW, EDGE_NE]:
		if absf(angle_difference(deg_to_rad(bearing), deg_to_rad(edge))) < deg_to_rad(EDGE_HOLD):
			var either: Array[StringName] = [ZONE_MUSIC[shore_of_bearing(edge - EDGE_HOLD - 1.0)], ZONE_MUSIC[shore_of_bearing(edge + EDGE_HOLD + 1.0)]]
			if holding in either:
				return holding
	return music


## The named place a spot is in: a site (a spring, a trial, a landmark) when it's inside one, else its zone.
func place_name_at(at: Vector3) -> String:
	var best: String = ""
	var best_share: float = 1.0
	for place: Dictionary in places:
		var radius: float = float(place["radius"])
		if radius <= 0.0:
			continue
		var spot: Vector3 = place["at"]
		var share: float = Vector2(at.x - spot.x, at.z - spot.z).length() / radius
		if share < best_share:
			best_share = share
			best = String(place["name"])
	return best if best != "" else ZONE_NAMES[zone_at(at)]


## Where a zone's name sits on the map: the middle of its shore, or high on the dome.
func zone_label_at(zone: Zone) -> Vector3:
	match zone:
		Zone.SOUTH_BAY:
			return Vector3(80.0, 6.0, 300.0)
		Zone.IRON_SHORE:
			return Vector3(_polar(288.0, 372.0).x, 12.0, _polar(288.0, 372.0).y)
		Zone.GALE_CLIFFS:
			return Vector3(_polar(352.0, 406.0).x, 16.0, _polar(352.0, 406.0).y)
		Zone.TIDE_GROTTOS:
			return Vector3(_polar(68.0, 340.0).x, 6.0, _polar(68.0, 340.0).y)
	return Vector3(DOME_CENTER.x, 48.0, DOME_CENTER.y + 130.0)


## The zones for a map render and the tests: their edges and labels.
func zone_report() -> Dictionary:
	var edges: Array = []
	for edge: float in [EDGE_SE, EDGE_SW, EDGE_NW, EDGE_NE]:
		edges.append({"bearing": edge, "from": 300.0, "to": 470.0})
	var labels: Array = []
	for zone: int in [Zone.SOUTH_BAY, Zone.IRON_SHORE, Zone.GALE_CLIFFS, Zone.TIDE_GROTTOS, Zone.MILLERS_OAK]:
		var at: Vector3 = zone_label_at(zone)
		labels.append({"name": ZONE_NAMES[zone], "x": at.x, "z": at.z})
	return {"edges": edges, "labels": labels}


# --- The Ring Path and the roads --------------------------------------------------------

func _build_ring() -> void:
	var raw: PackedFloat32Array = PackedFloat32Array()
	raw.resize(360)
	for degree: int in 360:
		var b: float = float(degree)
		var after: int = 0
		while after < RING_KNOTS.size() and RING_KNOTS[after].x <= b:
			after += 1
		var lo: Vector2 = RING_KNOTS[(after - 1 + RING_KNOTS.size()) % RING_KNOTS.size()]
		var hi: Vector2 = RING_KNOTS[after % RING_KNOTS.size()]
		var span: float = fposmod(hi.x - lo.x, 360.0)
		var t: float = fposmod(b - lo.x, 360.0) / maxf(span, 0.001)
		raw[degree] = lerpf(lo.y, hi.y, smoothstep(0.0, 1.0, t))
	# Two light smoothing passes; the knots at the springs stay within a metre.
	for _pass: int in 2:
		var smooth: PackedFloat32Array = raw.duplicate()
		for degree: int in 360:
			var sum: float = 0.0
			for offset: int in range(-3, 4):
				sum += raw[(degree + offset + 360) % 360]
			smooth[degree] = sum / 7.0
		raw = smooth
	_ring = raw


## The Ring Path's radius from the island's middle at a bearing.
func ring_radius(bearing: float) -> float:
	var b: float = fposmod(bearing, 360.0)
	var lo: int = int(floor(b)) % 360
	return lerpf(_ring[lo], _ring[(lo + 1) % 360], b - floor(b))


func ring_point(bearing: float) -> Vector2:
	return _polar(bearing, ring_radius(bearing))


## The Ring Path as a closed polyline of `count` legs.
func ring_points(count: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in count + 1:
		points.append(ring_point(360.0 * float(index) / float(count)))
	# The springs and the gate lie exactly on it.
	return points


## Every road a traveller keeps to (kin camps stand back from all of them): the
## Ring Path, the gully road up to the stair's top, the waypost's spur, the
## summit walk, the three trials' spurs and the stair down to the Sea-Door.
func roads() -> Array[PackedVector2Array]:
	var list: Array[PackedVector2Array] = [ring_points(72),
		PackedVector2Array([Vector2(0.0, 346.0), Vector2(-10.0, 292.0), Vector2(-22.0, 256.0), Vector2(STAIR_FOOT.x, STAIR_FOOT.z), Vector2(STAIR_TOP.x, STAIR_TOP.z)]),
		PackedVector2Array([Vector2(WAYPOST_AT.x + 8.0, WAYPOST_AT.z), Vector2(-9.3, 296.0)]),
		summit_walk()]
	for arena: Vector3 in [IRON_SHORE_AT, GALE_CLIFFS_AT, TIDE_GROTTOS_AT]:
		list.append(trial_spur(arena))
	list.append(PackedVector2Array([ring_point(94.5), Vector2(384.0, 34.0), Vector2(414.0, 44.0), Vector2(428.0, 58.0)]))
	return list


## A trial's spur: in from the Ring Path at its bearing to its arena's edge.
func trial_spur(arena: Vector3) -> PackedVector2Array:
	var bearing: float = bearing_of(arena.x, arena.z)
	var from: Vector2 = ring_point(bearing)
	var to: Vector2 = Vector2(arena.x, arena.z)
	var edge: Vector2 = to + (from - to).normalized() * (ARENA_RADIUS - 4.0)
	if arena == TIDE_GROTTOS_AT:
		# The Tide's spur winds in under the grotto arches.
		return PackedVector2Array([from, Vector2(350.0, 16.0), Vector2(318.0, 2.0), Vector2(290.0, -6.0), edge])
	return PackedVector2Array([from, edge])


## The summit walk: from the stair's top up the dome to the bell, the World-Tree ahead the whole way.
func summit_walk() -> PackedVector2Array:
	return PackedVector2Array([Vector2(STAIR_TOP.x, STAIR_TOP.z), Vector2(-14.0, 140.0), Vector2(-40.0, 88.0), Vector2(-22.0, 40.0),
		Vector2(BELL_AT.x - 6.0, BELL_AT.z + 14.0)])


## A shore's track: out from the Ring Path to the coast-side landmark and round its rare's walk.
func shore_track(zone: int) -> PackedVector2Array:
	var track: Vector3 = RARE_TRACKS[zone]
	var points: PackedVector2Array = PackedVector2Array([ring_point(track.x - 6.0)])
	var steps: int = 6
	for index: int in steps + 1:
		points.append(_polar(lerpf(track.x, track.y, float(index) / float(steps)), track.z))
	points.append(ring_point(track.y + 6.0))
	return points


## A rare's patrol round its shore track (world points, at the ground).
func rare_patrol(zone: int) -> PackedVector3Array:
	var track: Vector3 = RARE_TRACKS[zone]
	var points: PackedVector3Array = PackedVector3Array()
	for index: int in 5:
		var spot: Vector2 = _polar(lerpf(track.x, track.y, float(index) / 4.0), track.z)
		points.append(ground(spot.x, spot.y))
	return points


# --- The dome's ground ------------------------------------------------------------------

func _base_height(x: float, z: float) -> float:
	var r0: float = Vector2(x, z).length()
	var coast: float = _coast_radius(x, z, r0)
	if r0 > coast:
		return _sea_stacks(x, z, sea_floor(r0 / coast))
	var from: Vector2 = Vector2(x - DOME_CENTER.x, z - DOME_CENTER.y)
	var rd: float = from.length()
	var dir: Vector2 = from / maxf(rd, 1.0)
	var band: float = band_radius_toward(dir)
	if rd < band - BAND_HALF_WIDTH:
		# The World-Tree's dome: a meadow rising gently to the glade, with low swells.
		var t: float = smoothstep(band - BAND_HALF_WIDTH, GLADE_RADIUS, rd)
		return BAND_TOP + (SUMMIT_HEIGHT - BAND_TOP) * t + 5.0 * t * (1.0 - t) * detail(x * 0.25, z * 0.25)
	var foot: float = _band_foot(x, z)
	if rd < band + BAND_HALF_WIDTH:
		return lerpf(BAND_TOP, foot, smoothstep(band - BAND_HALF_WIDTH, band + BAND_HALF_WIDTH, rd))
	return _terrace(x, z, r0, rd, dir, band, coast, foot)


## The terrace's height at a spot (the springs sit on it).
func _terrace_height(x: float, z: float) -> float:
	var r0: float = Vector2(x, z).length()
	var from: Vector2 = Vector2(x - DOME_CENTER.x, z - DOME_CENTER.y)
	var rd: float = from.length()
	var dir: Vector2 = from / maxf(rd, 1.0)
	return _terrace(x, z, r0, rd, dir, band_radius_toward(dir), _coast_radius(x, z, r0), _band_foot(x, z))


## Each shore from its own rock and exposure: South Bay slopes gently to its
## beach and is cut by the summit stream; Iron Shore steps down in ironstone
## shelves; the Gale Cliffs stay high and end in sheer sea-cliffs; the Tide
## Grottos wear down to a low shelf at the waterline.
func _terrace(x: float, z: float, r0: float, rd: float, dir: Vector2, band: float, coast: float, foot: float) -> float:
	# The coast measured from the dome's centre along this spot's ray (the dome sits north-west of the middle).
	var coast_d: float = coast - dir.dot(DOME_CENTER)
	var t: float = clampf((rd - band - BAND_HALF_WIDTH) / maxf(1.0, coast_d - SHORE_RUN - band - BAND_HALF_WIDTH), 0.0, 1.0)
	var w: Vector4 = shore_weights(x, z)
	var south: float = lerpf(foot, 4.5, smoothstep(0.0, 0.8, t))
	var west: float = _shelves(lerpf(foot, 9.0, t))
	var north: float = lerpf(foot + 1.0, 11.0, pow(t, 0.7)) + 1.5 * maxf(0.0, noise(x * 0.9, z * 0.9))
	var east: float = lerpf(foot, 2.2, smoothstep(0.0, 0.85, t))
	var h: float = w.x * south + w.y * west + w.z * north + w.w * east + 1.2 * noise(x * 1.4, z * 1.4)
	h = _carve_stream(x, z, h)
	var inland: float = clampf((coast - r0) / SHORE_RUN, 0.0, 1.0)
	# The north and west fall to the sea as cliffs; the east and the bay slope down to the water.
	var cliffs: float = w.z + w.y * 0.9
	var drop: float = lerpf(smoothstep(0.0, 1.0, inland), smoothstep(0.0, 0.22, inland), cliffs)
	return lerpf(-1.5, h, drop)


## Iron Shore's ironstone shelves: 3 m treads with walkable risers.
static func _shelves(h: float) -> float:
	var step: float = 3.0
	var level: float = floor(h / step)
	return step * level + step * smoothstep(0.62, 1.0, h / step - level)


## The summit stream's bed down the gully.
func _carve_stream(x: float, z: float, h: float) -> float:
	if z < STREAM[0].y - 8.0 or x < -30.0 or x > 50.0:
		return h
	var best: float = INF
	for index: int in STREAM.size() - 1:
		var a: Vector2 = STREAM[index]
		var b: Vector2 = STREAM[index + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((Vector2(x, z) - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, Vector2(x, z).distance_to(a + ab * t))
	if best >= STREAM_HALF_WIDTH:
		return h
	var cut: float = STREAM_DEPTH * (1.0 - (best * best) / (STREAM_HALF_WIDTH * STREAM_HALF_WIDTH))
	return h - cut


## The sea stacks off the Tide Grottos.
static func _sea_stacks(x: float, z: float, h: float) -> float:
	for stack: Vector4 in SEA_STACKS:
		var d: float = Vector2(x - stack.x, z - stack.y).length()
		if d < stack.z:
			h = maxf(h, lerpf(stack.w + 1.5 * cos(d * 0.9), h, smoothstep(stack.z * 0.78, stack.z, d)))
	return h


func _coast_radius(x: float, z: float, r0: float) -> float:
	var nx: float = x / maxf(r0, 1.0)
	var nz: float = z / maxf(r0, 1.0)
	var coast: float = COAST_RADIUS + 14.0 * noise(nx * 220.0, nz * 220.0)
	# The Breach Point juts north toward The Breach.
	var off: float = rad_to_deg(angle_difference(deg_to_rad(bearing_of(x, z)), deg_to_rad(HEADLAND_BEARING)))
	coast += HEADLAND_REACH * exp(-(off * off) / (HEADLAND_WIDTH * HEADLAND_WIDTH))
	var south: float = maxf(0.0, nz)
	return lerpf(coast, BAY_RADIUS, smoothstep(0.86, 0.985, south))


## The cliff band's radius from the dome's centre toward `dir` (unit, x-z): it wanders where the old crust broke.
func band_radius_toward(dir: Vector2) -> float:
	var angle: float = atan2(dir.x, -dir.y)
	return BAND_RADIUS + 9.0 * sin(angle * 3.0 + 0.7) + 5.0 * sin(angle * 5.0 + 2.1) + 2.0 * noise(dir.x * 160.0 + 40.0, dir.y * 160.0)


func _band_foot(x: float, z: float) -> float:
	return BAND_FOOT + 2.0 * shore_weights(x, z).z


## How much a spot belongs to each shore: South Bay, Iron Shore, Gale Cliffs, Tide Grottos (they sum to one; soft at the edges).
func shore_weights(x: float, z: float) -> Vector4:
	var b: float = bearing_of(x, z)
	var weights: Vector4 = Vector4(_arc(b, EDGE_SE, EDGE_SW), _arc(b, EDGE_SW, EDGE_NW), _arc(b, EDGE_NW, EDGE_NE + 360.0), _arc(b, EDGE_NE, EDGE_SE))
	var total: float = weights.x + weights.y + weights.z + weights.w
	return weights / maxf(total, 0.0001)


## A bearing's soft membership of the arc from `from` to `to` (degrees, `to` > `from`).
static func _arc(bearing: float, from: float, to: float) -> float:
	var rel: float = fposmod(bearing - from + EDGE_SOFT, 360.0) - EDGE_SOFT
	var span: float = to - from
	return smoothstep(-EDGE_SOFT, EDGE_SOFT, rel) * (1.0 - smoothstep(span - EDGE_SOFT, span + EDGE_SOFT, rel))


func _ground_color(x: float, z: float, height: float, up: float) -> Color:
	var w: Vector4 = shore_weights(x, z)
	var patch: float = detail(x * 0.6, z * 0.6)
	# Each shore takes on the rock of the isle it faces: ironstone west, wind-scoured basalt north, sap-stained east.
	var rock: Color = CalderaKit.BASALT.lightened(0.2) * w.x + CalderaKit.IRONSTONE * w.y + CalderaKit.BASALT.lightened(0.32) * w.z \
		+ Color(0.34, 0.28, 0.4) * w.w
	rock.a = 1.0
	var turf: Color = Color(0.46, 0.6, 0.32) * w.x + Color(0.5, 0.48, 0.3) * w.y + Color(0.56, 0.6, 0.48) * w.z + Color(0.42, 0.52, 0.42) * w.w
	turf.a = 1.0
	if height > BAND_TOP - 0.5 and inside_band(x, z):
		turf = Color(0.5, 0.65, 0.32).lerp(Color(0.66, 0.66, 0.34), smoothstep(BAND_TOP, SUMMIT_HEIGHT, height))
	elif w.y > 0.3:
		# Iron Shore's shelves: rust and cinder on the treads.
		turf = turf.lerp(CalderaKit.IRONSTONE.lightened(0.15), 0.18 * w.y * (0.5 + 0.5 * patch))
	elif w.w > 0.3 and height < 3.0:
		# The Tide Grottos' wet shelf, and violet sap-stain near the sluices.
		turf = turf.lerp(Color(0.3, 0.3, 0.36), 0.5 * w.w)
	return shore_or(height, up, turf.lerp(turf.darkened(0.12), patch * 0.5 + 0.5), rock)


func _scatter_species(x: float, z: float, height: float, up: float, roll: float) -> int:
	if height < 1.2:
		return Species.ROCK if height > -0.6 and roll < 0.08 else -1
	if up < 0.62:
		return Species.BASALT_SPIRE if roll < 0.05 else -1
	if height > BAND_TOP + 4.0 and inside_band(x, z):
		# The World-Tree's dome: oaks thinning toward the glade, ferns in the grass.
		var rd: float = Vector2(x - DOME_CENTER.x, z - DOME_CENTER.y).length()
		if rd < GLADE_RADIUS + 10.0:
			return Species.FERN_TUFT if roll < 0.05 else -1
		return Species.OAK_TREE if roll < 0.045 * smoothstep(GLADE_RADIUS, 160.0, rd) + 0.01 else (Species.FERN_TUFT if roll < 0.14 else -1)
	var w: Vector4 = shore_weights(x, z)
	match _strongest(w):
		0:
			# South Bay: ash and oak along the gully, ferns by the stream.
			return Species.ASH_TREE if roll < 0.05 else (Species.OAK_TREE if roll < 0.07 else (Species.FERN_TUFT if roll < 0.16 else -1))
		1:
			# Iron Shore: boulders on the shelves, a few hardy pines.
			return Species.BOULDER if roll < 0.07 else (Species.PINE_TREE if roll < 0.1 else (Species.ROCK if roll < 0.15 else -1))
		2:
			# The Gale Cliffs: wind-scoured, stones and tufts, no trees.
			return Species.ROCK if roll < 0.08 else (Species.FERN_TUFT if roll < 0.13 else -1)
	# The Tide Grottos: weeping willows by the sluices, reeds along the shelf.
	if height < 3.5:
		return Species.REED_CLUMP if roll < 0.2 else (Species.ROCK if roll < 0.26 else -1)
	return Species.WILLOW_TREE if roll < 0.035 else (Species.REED_CLUMP if roll < 0.1 else (Species.FERN_TUFT if roll < 0.15 else -1))


static func _strongest(w: Vector4) -> int:
	var best: int = 0
	for index: int in 4:
		if w[index] > w[best]:
			best = index
	return best


# --- Structures ------------------------------------------------------------------------

func build_structures(root: Node3D) -> void:
	_build_landing(root)
	_build_waypost(root)
	_build_stream(root)
	_build_ring_path(root)
	_build_iron_shore(root)
	_build_gale_cliffs(root)
	_build_tide_grottos(root)
	_build_cliff_band(root)
	_build_summit(root)
	_build_sea_door_and_galleries(root)
	_build_kin(root)


func landmark_silhouette(into: LandblockTerrain.MeshMerge) -> void:
	# The trunk; the crown's lobes are the live boughs' own materials (WorldTree.make_far_crown).
	CalderaKit.add_post(into, WORLD_TREE_AT, 3.2, 6.5, 40.0, Color(0.42, 0.34, 0.26), 10)
	# The Old King's Kiln, standing over Iron Shore.
	CalderaKit.add_post(into, ground(KILN_AT.x, KILN_AT.y), 2.0, 3.2, KILN_HEIGHT, CalderaKit.IRONSTONE.darkened(0.2), 8)


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
	CalderaKit.sign_label(root, "LandingSign", "South Bay Landing\nThe Crown · Lv 13-14 · take any shore, in any order", ground(-6.0, 344.0) + Vector3(0.0, 2.6, 0.0))
	# The crossroads at the head of the beach: the Ring Path runs east and west, the gully road climbs north.
	CalderaKit.sign_label(root, "CrossroadsSign", "← Iron Shore · the Ring Path · Tide Grottos →\n↑ the Waypost and the One Cliff Stair",
		ground(-8.0, 330.0) + Vector3(0.0, 2.4, 0.0))


func _build_waypost(root: Node3D) -> void:
	var at: Vector3 = ground(WAYPOST_AT.x, WAYPOST_AT.z)
	var hut: LandblockTerrain.MeshMerge = CalderaKit.merge()
	# The Warden's house, merged into the waypost (the razor): a stone shelter with a lean-to.
	CalderaKit.add_hut(hut, at + Vector3(-4.0, 0.0, -2.0), Vector3(6.0, 3.2, 4.6), 0.4, CalderaKit.STONE, CalderaKit.DARK_STONE)
	CalderaKit.add_box(hut, at + Vector3(4.0, 0.45, -1.0), Vector3(1.4, 0.9, 0.8), CalderaKit.DARK_STONE)
	CalderaKit.add_box(hut, at + Vector3(4.0, 1.0, -1.0), Vector3(1.0, 0.25, 0.5), CalderaKit.DARK_STONE.darkened(0.3))
	# The lantern-mast: South Bay's landmark, seen all along the southern Ring Path.
	var mast: Vector3 = at + Vector3(2.5, 0.0, 2.5)
	CalderaKit.add_box(hut, mast + Vector3(0.0, 0.6, 0.0), Vector3(2.4, 1.2, 2.4), CalderaKit.STONE.darkened(0.1))
	CalderaKit.add_post(hut, mast + Vector3(0.0, 1.2, 0.0), 0.3, 0.45, MAST_HEIGHT - 1.2, CalderaKit.DARK_TIMBER, 8)
	CalderaKit.add_beam(hut, mast + Vector3(-1.8, MAST_HEIGHT - 2.0, 0.0), mast + Vector3(1.8, MAST_HEIGHT - 2.0, 0.0), 0.2, CalderaKit.DARK_TIMBER)
	CalderaKit.add_box(hut, mast + Vector3(0.0, MAST_HEIGHT, 0.0), Vector3(1.8, 0.2, 1.8), CalderaKit.BRASS.darkened(0.3))
	for corner: Vector2 in [Vector2(-0.75, -0.75), Vector2(0.75, -0.75), Vector2(-0.75, 0.75), Vector2(0.75, 0.75)]:
		CalderaKit.add_box(hut, mast + Vector3(corner.x, MAST_HEIGHT + 0.85, corner.y), Vector3(0.12, 1.5, 0.12), CalderaKit.BRASS.darkened(0.3))
	CalderaKit.add_cone(hut, mast + Vector3(0.0, MAST_HEIGHT + 1.6, 0.0), 1.3, 1.1, CalderaKit.DARK_STONE, 4)
	# Two small lanterns hang from the yard, for the Lantern-Bearers.
	for side: float in [-1.6, 1.6]:
		CalderaKit.add_box(hut, mast + Vector3(side, MAST_HEIGHT - 2.6, 0.0), Vector3(0.36, 0.5, 0.36), CalderaKit.BRASS.darkened(0.2))
	root.add_child(CalderaKit.mesh_node("LandmarkWaypostMast", hut))
	CalderaKit.solid_box(root, "WaypostWalls", at + Vector3(-4.0, 1.6, -2.0), Vector3(6.0, 3.2, 4.6), 0.4)
	CalderaKit.solid_box(root, "MastFooting", mast + Vector3(0.0, 0.6, 0.0), Vector3(2.4, 1.2, 2.4))
	CalderaKit.solid_cylinder(root, "MastFoot", mast, 0.45, MAST_HEIGHT)
	CalderaKit.glow_sphere(root, "SaffronLantern", mast + Vector3(0.0, MAST_HEIGHT + 0.85, 0.0), 0.62, CalderaKit.SAFFRON, 3.6)
	for side: float in [-1.6, 1.6]:
		CalderaKit.glow_sphere(root, "YardLantern%d" % int(side + 2.0), mast + Vector3(side, MAST_HEIGHT - 2.6, 0.0), 0.16, CalderaKit.SAFFRON, 2.8)
	CalderaKit.light(root, "LanternLight", mast + Vector3(0.0, MAST_HEIGHT + 0.4, 0.0), CalderaKit.SAFFRON, 2.6, 30.0)
	var anchor: WarmSpring = WarmSpring.new()
	anchor.name = "RespawnAnchor"
	anchor.spring_name = "The Lantern-Bearers' Waypost"
	anchor.show_pool = false
	anchor.heals = false
	anchor.position = at + Vector3(0.0, 0.0, 4.0)
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
	quartermaster.position = at + Vector3(3.6, 0.0, -2.4)
	root.add_child(quartermaster)
	var warden: TownsfolkNPC = TownsfolkNPC.new()
	warden.name = "Warden"
	warden.role = TownsfolkNPC.Role.QUEST_GIVER
	warden.npc_name = "Wenna Lampwright"
	warden.title = "Warden of the Waypost"
	warden.hub = "The Lantern-Bearers' Waypost"
	warden.quests = PackedStringArray(["Take any shore first: the Anvil west, the Gale north, the Tide east",
		"Split up if you like: a scout waits at each spring, and each spring will stand you back up",
		"When three boughs bloom on the World-Tree, climb the One Cliff Stair and pull the bell together"])
	warden.body_color = Color(0.34, 0.3, 0.42)
	warden.accent_color = CalderaKit.HEARTH_SAFFRON
	warden.npc_seed = 52
	warden.position = at + Vector3(-1.2, 0.0, 3.0)
	root.add_child(warden)
	CalderaKit.sign_label(root, "WaypostSign", "The Lantern-Bearers' Waypost\nrespawn · anvil · quartermaster · the Warden", at + Vector3(0.0, 4.4, 4.2))


## The summit stream: its fall down the cliff band beside the stair, and its run down the gully to the bay.
func _build_stream(root: Node3D) -> void:
	var water: Color = Color(0.62, 0.82, 0.92)
	var run: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in STREAM.size() - 1:
		var a: Vector2 = STREAM[index]
		var b: Vector2 = STREAM[index + 1]
		var pieces: int = int(a.distance_to(b) / 3.0) + 1
		for piece: int in pieces:
			var p0: Vector2 = a.lerp(b, float(piece) / float(pieces))
			var p1: Vector2 = a.lerp(b, float(piece + 1) / float(pieces))
			var a3: Vector3 = ground(p0.x, p0.y) + Vector3(0.0, 0.14, 0.0)
			var b3: Vector3 = ground(p1.x, p1.y) + Vector3(0.0, 0.14, 0.0)
			if a3.y < 0.25 and b3.y < 0.25:
				continue
			# A flat sheet of water lying in the stream's bed, tilted down the slope.
			var flat: Vector2 = p1 - p0
			var tilt: Basis = Basis(Vector3.UP, atan2(flat.x, flat.y)) * Basis(Vector3.RIGHT, atan2(a3.y - b3.y, flat.length()))
			run.add_arrays(_box_arrays(Vector3(3.0, 0.05, flat.length() + 0.4)), Transform3D(tilt, (a3 + b3) * 0.5), Color.WHITE)
	var stream: MeshInstance3D = MeshInstance3D.new()
	stream.name = "SummitStream"
	stream.mesh = run.commit()
	stream.material_override = CalderaKit.glow(water, 0.22)
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(stream)
	# The fall: a ribbon of water down the band's face (from its lip to its foot), its pool and its spray.
	var from: Vector2 = FALL_AT - DOME_CENTER
	var dir: Vector2 = from.normalized()
	var band: float = band_radius_toward(dir)
	var lip: Vector2 = DOME_CENTER + dir * (band - BAND_HALF_WIDTH - 0.6)
	var foot: Vector2 = DOME_CENTER + dir * (band + BAND_HALF_WIDTH + 0.4)
	var fall: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var side: Vector3 = Vector3(dir.y, 0.0, -dir.x)
	for offset: float in [-0.8, 0.8]:
		CalderaKit.add_beam(fall, Vector3(lip.x, BAND_TOP + 0.3, lip.y) + side * offset, Vector3(foot.x, BAND_FOOT - 0.2, foot.y) + side * offset, 1.4, Color.WHITE)
	var ribbon: MeshInstance3D = CalderaKit.mesh_node("LandmarkStreamFall", fall, Vector3.ZERO, false)
	ribbon.material_override = CalderaKit.glow(water.lightened(0.2), 0.9)
	root.add_child(ribbon)
	CalderaKit.plume(root, "FallSpray", ground(FALL_AT.x, FALL_AT.y + 4.0) + Vector3(0.0, 0.4, 0.0), Color(0.92, 0.96, 1.0, 0.5), 3.0, 1.6, 16)


func _build_ring_path(root: Node3D) -> void:
	for index: int in 3:
		var spring: WarmSpring = WarmSpring.new()
		spring.name = "WarmSpring%d" % (index + 1)
		spring.spring_name = SPRING_NAMES[index]
		spring.position = ground(SPRINGS[index].x, SPRINGS[index].y)
		root.add_child(spring)
	# The scouts: one Lantern-Bearer at each spring, on the side of the shore they know.
	var scouts: Array[Array] = [
		[0, "Pell Kilnworth", "Scout of Iron Shore", Color(0.5, 0.32, 0.22), CalderaKit.IRON_AMBER, PackedStringArray([
			"The Anvil-Warden shrugs off small blows: break its poise first, then strike together",
			"The Clinker Iron-Men on the shelves teach the same lesson, if you'd like to practise",
			"Old Bellows walks the vents by the sea; leave it be, or bring friends"])],
		[1, "Sorrel Windhame", "Scout of the Gale Cliffs", Color(0.42, 0.5, 0.6), CalderaKit.GALE_AZURE, PackedStringArray([
			"The Breach Gale gathers before it blows: get behind a wall, or dodge through it",
			"The Gust-Padfoots dash in straight lines: step aside, then answer",
			"The Grey Squall runs the cliff-top; the harriers nest at the Sanctum Arch"])],
		[2, "Ione Saltmarsh", "Scout of the Tide Grottos", Color(0.36, 0.3, 0.46), CalderaKit.TIDE_VIOLET, PackedStringArray([
			"The blight-mist eats your stamina: cleanse the three Sap-Siphons with Star-Tide or Warm-Hearth",
			"Stand in a Sanctuary while you work, and mind the wights' bolts from the arches",
			"Mother Sluice wallows on the shelf by the sea; the Sea-Door waits under the water until the Ebb"])],
	]
	for scout: Array in scouts:
		var spring_at: Vector2 = SPRINGS[int(scout[0])]
		var shore: Vector2 = spring_at.normalized().orthogonal() * (4.0 if int(scout[0]) == 0 else -4.0)
		var npc: TownsfolkNPC = TownsfolkNPC.new()
		npc.name = "Scout%d" % (int(scout[0]) + 1)
		npc.role = TownsfolkNPC.Role.QUEST_GIVER
		npc.npc_name = String(scout[1])
		npc.title = String(scout[2])
		npc.hub = SPRING_NAMES[int(scout[0])]
		npc.quests = scout[5]
		npc.body_color = scout[3]
		npc.accent_color = scout[4]
		npc.npc_seed = 60 + int(scout[0])
		var spot: Vector2 = spring_at + shore + spring_at.normalized() * 5.0
		npc.position = ground(spot.x, spot.y)
		root.add_child(npc)
	# Lantern-poles along the Ring Path and up the gully road, the dome's waymarks.
	for index: int in 30:
		var bearing: float = 360.0 * (float(index) + 0.25) / 30.0
		var spot: Vector2 = _polar(bearing, ring_radius(bearing) + 4.0)
		root.add_child(WorldKitInstance.make("RingLantern%d" % index, WorldVisualCatalog.KIT_WIND_LANTERN_POST, ground(spot.x, spot.y), deg_to_rad(bearing)))
	for spot: Vector2 in [Vector2(-0.4, 324.0), Vector2(-8.7, 284.0), Vector2(-20.4, 250.0)]:
		root.add_child(WorldKitInstance.make("GullyLantern%d" % int(spot.y), WorldVisualCatalog.KIT_WIND_LANTERN_POST, ground(spot.x, spot.y), 0.0))
	# Where the shores meet with no spring, the Sanctum Gate: the Old Sanctum's ruined gateway across the Ring Path.
	var gate: Vector3 = ground(SANCTUM_GATE_AT.x, SANCTUM_GATE_AT.y)
	var along: Vector2 = ring_point(EDGE_NE + 2.0) - ring_point(EDGE_NE - 2.0)
	var masonry: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_arch(masonry, gate, 6.0, 7.0, atan2(along.x, along.y), CalderaKit.PALE_STONE.darkened(0.1))
	for side: float in [-1.0, 1.0]:
		var wall: Vector2 = Vector2(SANCTUM_GATE_AT.x, SANCTUM_GATE_AT.y) + along.normalized().orthogonal() * side * 9.0
		CalderaKit.add_ruin_wall(masonry, ground(wall.x, wall.y), 7.0, 2.6, atan2(along.x, along.y) + PI * 0.5, CalderaKit.PALE_STONE.darkened(0.15), 140 + int(side))
	root.add_child(CalderaKit.mesh_node("LandmarkSanctumGate", masonry))
	for side: float in [-1.0, 1.0]:
		var pier: Vector2 = Vector2(SANCTUM_GATE_AT.x, SANCTUM_GATE_AT.y) + along.normalized().orthogonal() * side * 3.6
		CalderaKit.solid_box(root, "GatePier%d" % int(side + 1.0), ground(pier.x, pier.y) + Vector3(0.0, 2.0, 0.0), Vector3(1.2, 4.0, 1.6), atan2(along.x, along.y))
	CalderaKit.sign_label(root, "GateSign", "The Sanctum Gate\n← Gale Cliffs · Tide Grottos →", gate + Vector3(0.0, 8.4, 0.0))
	for index: int in 3:
		var spring_at: Vector2 = SPRINGS[index]
		var lines: Array[String] = ["Iron Shore ↑ · South Bay ↓", "Gale Cliffs ↑ · Iron Shore ↓", "Tide Grottos ↑ · South Bay ↓"]
		CalderaKit.sign_label(root, "SpringSign%d" % (index + 1), "%s\n%s" % [SPRING_NAMES[index], lines[index]], ground(spring_at.x, spring_at.y) + Vector3(0.0, 3.2, 0.0))


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
	# Old King's Town: the old kingdom's shore town, its street walls on the shelves round the Kiln.
	var ruins: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var walls: Array[Vector4] = [Vector4(-318.0, -150.0, 14.0, 0.2), Vector4(-276.0, -138.0, 12.0, 1.4), Vector4(-262.0, -96.0, 10.0, 0.9),
		Vector4(-330.0, -112.0, 16.0, 1.6), Vector4(-286.0, -72.0, 9.0, 0.3), Vector4(-346.0, -84.0, 8.0, 0.0), Vector4(-300.0, 34.0, 12.0, 1.2),
		Vector4(-352.0, 46.0, 10.0, 0.4)]
	for index: int in walls.size():
		var wall: Vector4 = walls[index]
		CalderaKit.add_ruin_wall(ruins, ground(wall.x, wall.y), wall.z, 2.6, wall.w, CalderaKit.IRONSTONE.lerp(CalderaKit.STONE, 0.45), 70 + index)
		CalderaKit.solid_box(root, "RuinWall%d" % index, ground(wall.x, wall.y) + Vector3(0.0, 0.9, 0.0), Vector3(0.9, 1.8, wall.z), wall.w, ActorBase.LAYER_LOW_SCENERY)
	root.add_child(CalderaKit.mesh_node("OldKingsTown", ruins))
	# The Old King's Kiln: Iron Shore's landmark, a tall ironstone chimney still breathing the dome's heat.
	var kiln: Vector3 = ground(KILN_AT.x, KILN_AT.y)
	var stack: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_box(stack, kiln + Vector3(0.0, 2.5, 0.0), Vector3(9.0, 5.0, 9.0), CalderaKit.IRONSTONE.darkened(0.15))
	CalderaKit.add_post(stack, kiln + Vector3(0.0, 5.0, 0.0), 2.0, 3.0, KILN_HEIGHT - 5.0, CalderaKit.IRONSTONE.lerp(CalderaKit.DARK_STONE, 0.35), 10)
	CalderaKit.add_post(stack, kiln + Vector3(0.0, KILN_HEIGHT, 0.0), 2.6, 2.4, 1.6, CalderaKit.DARK_STONE, 10)
	CalderaKit.add_arch(stack, kiln + Vector3(0.0, 0.0, 4.6), 2.4, 3.4, 0.0, CalderaKit.DARK_STONE)
	root.add_child(CalderaKit.mesh_node("LandmarkOldKingsKiln", stack))
	CalderaKit.solid_box(root, "KilnBody", kiln + Vector3(0.0, 2.5, 0.0), Vector3(9.0, 5.0, 9.0))
	CalderaKit.solid_cylinder(root, "KilnStack", kiln + Vector3(0.0, 5.0, 0.0), 2.6, KILN_HEIGHT - 5.0)
	CalderaKit.plume(root, "KilnSteam", kiln + Vector3(0.0, KILN_HEIGHT + 1.6, 0.0), Color(0.95, 0.94, 0.92, 0.55), 12.0, 2.6, 26)
	CalderaKit.glow_sphere(root, "KilnMouth", kiln + Vector3(0.0, 1.2, 4.8), 0.9, Color(1.0, 0.5, 0.18), 2.0)
	# The steam vents by the sea: the same hot rock as Iron-Ness.
	for index: int in 5:
		var vent2: Vector2 = _polar(266.0 + index * 9.0, 412.0 + 6.0 * float(index % 2))
		var vent: Vector3 = ground(vent2.x, vent2.y)
		CalderaKit.plume(root, "SteamVent%d" % index, vent + Vector3(0.0, 0.3, 0.0), Color(0.95, 0.94, 0.92, 0.6), 3.6, 0.8, 22)
		CalderaKit.glow_sphere(root, "VentGlow%d" % index, vent + Vector3(0.0, 0.05, 0.0), 0.7, Color(1.0, 0.5, 0.2), 1.4)
	CalderaKit.sign_label(root, "IronShoreSign", "Old King's Town\nIron Shore · Lv 13", kiln + Vector3(0.0, 7.0, 7.0))


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
	var spots: Array[Vector2] = [Vector2(-14.0, -10.0), Vector2(6.0, -14.0), Vector2(-6.0, 6.0), Vector2(14.0, 4.0), Vector2(0.0, 16.0)]
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
	# The Sanctum Arch on the Breach Point: the Gale Cliffs' landmark, framing The Breach.
	var point: Vector3 = ground(SANCTUM_ARCH_AT.x, SANCTUM_ARCH_AT.y)
	var breach: Vector3 = Vector3(-BREACH_WIND.x, 0.0, -BREACH_WIND.z)
	var arch: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_arch(arch, point, 7.0, 16.0, atan2(breach.x, breach.z), CalderaKit.PALE_STONE.darkened(0.08))
	for index: int in 3:
		var stub: Vector3 = point + Vector3(-9.0 + 9.0 * index, 0.0, 6.0 + 2.0 * float(index % 2))
		CalderaKit.add_ruin_wall(arch, ground(stub.x, stub.z), 5.0, 2.4, atan2(breach.x, breach.z) + PI * 0.5, CalderaKit.PALE_STONE.darkened(0.2), 150 + index)
	root.add_child(CalderaKit.mesh_node("LandmarkSanctumArch", arch))
	for side: float in [-1.0, 1.0]:
		var across: Vector3 = Vector3(cos(atan2(breach.x, breach.z)), 0.0, -sin(atan2(breach.x, breach.z)))
		CalderaKit.solid_box(root, "ArchPier%d" % int(side + 1.0), point + across * side * 4.1 + Vector3(0.0, 6.25, 0.0), Vector3(1.2, 12.5, 1.6),
			atan2(breach.x, breach.z))
	for index: int in 3:
		CalderaKit.plume(root, "SeaSpray%d" % index, ground(-60.0 + index * 46.0, -432.0) + Vector3(0.0, 1.0, 0.0), Color(0.92, 0.96, 1.0, 0.5), 2.6, 2.0, 14)
	CalderaKit.sign_label(root, "GaleCliffsSign", "The Breach Point\nGale Cliffs · open to The Breach · Lv 13", point + Vector3(0.0, 3.0, 12.0))


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
	# The old kingdom's sluice channels, still weeping violet sap down to the sea (either side of the Sea-Door's cove, never across it).
	var channels: LandblockTerrain.MeshMerge = CalderaKit.merge()
	# The first runs to the Weeping Arch (the sap is why it weeps); the others to the shore beside the cove.
	var ends: Array[Vector2] = [WEEPING_ARCH_AT - WEEPING_ARCH_AT.normalized() * 6.0, Vector2(440.0, -38.0), Vector2(440.0, 20.0)]
	var starts: Array[Vector2] = [Vector2(at.x + 16.0, at.z - 12.0), Vector2(at.x + 20.0, at.z - 4.0), Vector2(at.x + 18.0, at.z + 12.0)]
	for index: int in 3:
		var start: Vector2 = starts[index]
		var finish: Vector2 = ends[index]
		# Stop where the shore meets the water.
		for step: int in 40:
			var probe: Vector2 = start.lerp(ends[index], float(step + 1) / 40.0)
			if height_at(probe.x, probe.y) < 0.6:
				break
			finish = probe
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
	# Grotto arches over the winding spur, and bioluminescent glints along the waterline.
	var spur: PackedVector2Array = trial_spur(TIDE_GROTTOS_AT)
	for index: int in range(1, 4):
		var here: Vector2 = spur[index]
		var dir: Vector2 = (spur[index + 1] - spur[index - 1]).normalized()
		CalderaKit.add_arch(channels, ground(here.x, here.y), 5.0, 6.0, atan2(dir.x, dir.y), CalderaKit.BASALT.lightened(0.15))
	root.add_child(CalderaKit.mesh_node("SluicesAndGrottos", channels))
	for index: int in 12:
		var glint2: Vector2 = _polar(40.0 + float(index) * 6.5, 428.0 + 6.0 * float(index % 3))
		CalderaKit.glow_sphere(root, "Glint%d" % index, ground(glint2.x, glint2.y) + Vector3(0.0, 0.15, 0.0), 0.22, Color(0.5, 0.9, 1.0), 2.4)
	# The Weeping Arch: the Tide Grottos' landmark, a sea arch stained violet where the sap runs out to sea.
	var weep: Vector3 = ground(WEEPING_ARCH_AT.x, WEEPING_ARCH_AT.y)
	var out: Vector2 = WEEPING_ARCH_AT.normalized()
	var sea_arch: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var arch_yaw: float = atan2(out.orthogonal().x, out.orthogonal().y)
	var arch_foot: Vector3 = Vector3(weep.x, -1.0, weep.z) + Vector3(out.x, 0.0, out.y) * 8.0
	CalderaKit.add_arch(sea_arch, arch_foot, 12.0, 20.0, arch_yaw, CalderaKit.BASALT.lightened(0.1))
	# Violet sap-stain down its landward pier, where the sluice spills over.
	var stained: Vector3 = arch_foot - Vector3(out.x, 0.0, out.y) * 6.6
	CalderaKit.add_box(sea_arch, stained + Vector3(0.0, 7.0, 0.0) + Vector3(out.x, 0.0, out.y) * 0.62, Vector3(0.9, 14.0, 0.1), CalderaKit.SAP_VIOLET.darkened(0.3),
		atan2(out.x, out.y))
	root.add_child(CalderaKit.mesh_node("LandmarkWeepingArch", sea_arch))
	for side: float in [-1.0, 1.0]:
		var pier: Vector3 = arch_foot + Vector3(out.x, 0.0, out.y) * side * 6.6
		CalderaKit.solid_box(root, "WeepingPier%d" % int(side + 1.0), pier + Vector3(0.0, 7.0, 0.0), Vector3(1.2, 14.0, 1.6), arch_yaw)
	CalderaKit.sign_label(root, "TideGrottosSign", "The Weeping Arch\nTide Grottos · where the old kingdom drained the sap · Lv 13", weep + Vector3(0.0, 3.0, 0.0))


func _build_cliff_band(root: Node3D) -> void:
	# Basalt columns along the band's foot all round: the wall reads as stone, honest and sheer.
	var columns: MultiMesh = MultiMesh.new()
	columns.transform_format = MultiMesh.TRANSFORM_3D
	columns.mesh = CalderaKit.species_mesh(Species.BASALT_SPIRE)
	var spots: Array[Transform3D] = []
	var count: int = 340
	for index: int in count:
		var angle: float = TAU * float(index) / float(count)
		var dir: Vector2 = Vector2(sin(angle), -cos(angle))
		var rd: float = band_radius_toward(dir) + BAND_HALF_WIDTH + 1.2
		var x: float = DOME_CENTER.x + dir.x * rd
		var z: float = DOME_CENTER.y + dir.y * rd
		if Vector2(x - STAIR_FOOT.x, z - (STAIR_FOOT.z + STAIR_TOP.z) * 0.5).length() < 12.0 or Vector2(x - FALL_AT.x, z - FALL_AT.y).length() < 4.0:
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
	# The One Cliff Stair: dressed steps up the cut, two lantern pillars at its foot, and the Resonance Barrier where it enters the band.
	var steps: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var run: float = STAIR_FOOT.distance_to(STAIR_TOP)
	var treads: int = int(run / 1.4)
	for index: int in treads:
		var t: float = float(index) / float(treads)
		var at: Vector3 = STAIR_FOOT.lerp(STAIR_TOP, t)
		CalderaKit.add_box(steps, Vector3(at.x, height_at(at.x, at.z) + 0.02, at.z), Vector3(STAIR_HALF_WIDTH * 2.0 - 0.4, 0.22, 0.9), CalderaKit.PALE_STONE.darkened(0.06 * float(index % 2)))
	for side: float in [-1.0, 1.0]:
		var pillar: Vector3 = ground(STAIR_FOOT.x + side * (STAIR_HALF_WIDTH + 1.4), STAIR_FOOT.z + 3.0)
		CalderaKit.add_post(steps, pillar, 0.5, 0.7, 4.2, CalderaKit.PALE_STONE, 6)
		CalderaKit.glow_sphere(root, "StairLantern%d" % int(side + 1.0), pillar + Vector3(0.0, 4.6, 0.0), 0.38, CalderaKit.SAFFRON, 2.6)
	root.add_child(CalderaKit.mesh_node("OneCliffStair", steps))
	var barrier: ResonanceBarrier = ResonanceBarrier.new()
	barrier.name = "ResonanceBarrier"
	barrier.width = STAIR_HALF_WIDTH * 2.0 + 6.0
	var gate_z: float = STAIR_FOOT.z - 20.0
	barrier.position = ground(STAIR_FOOT.x, gate_z)
	root.add_child(barrier)
	CalderaKit.sign_label(root, "StairSign", "The One Cliff Stair\nthe only way up the +32 m cliff band, to the World-Tree", ground(STAIR_FOOT.x + 9.0, STAIR_FOOT.z + 6.0) + Vector3(0.0, 2.6, 0.0))


func _build_summit(root: Node3D) -> void:
	var tree: WorldTree = WorldTree.new()
	tree.name = "WorldTree"
	tree.position = ground(WORLD_TREE_AT.x, WORLD_TREE_AT.z) - Vector3(0.0, 0.3, 0.0)
	root.add_child(tree)
	var bell: HarmonicBell = HarmonicBell.new()
	bell.name = "HarmonicBell"
	bell.position = ground(BELL_AT.x, BELL_AT.z)
	root.add_child(bell)
	# The old kingdom's sap-taps, still driven into the World-Tree's root-flare (the ruins tell why the blight came).
	var taps: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in 3:
		var angle: float = TAU * float(index) / 3.0 + 0.9
		var foot: Vector3 = ground(WORLD_TREE_AT.x + cos(angle) * 7.4, WORLD_TREE_AT.z + sin(angle) * 7.4)
		var into: Vector3 = Vector3(WORLD_TREE_AT.x, foot.y + 1.6, WORLD_TREE_AT.z)
		CalderaKit.add_beam(taps, foot + Vector3(0.0, 1.2, 0.0), foot.lerp(into, 0.35) + Vector3(0.0, 0.4, 0.0), 0.3, CalderaKit.IRONSTONE.darkened(0.3))
		CalderaKit.add_box(taps, foot + Vector3(0.0, 0.05, 0.0), Vector3(1.6, 0.1, 1.6), CalderaKit.SAP_VIOLET.darkened(0.45))
	root.add_child(CalderaKit.mesh_node("SapTaps", taps))
	CalderaKit.sign_label(root, "GladeSign", "The Summit Glade · +65 m\nThe World-Tree", ground(WORLD_TREE_AT.x + 16.0, WORLD_TREE_AT.z + 66.0) + Vector3(0.0, 3.0, 0.0))


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
	CalderaKit.sign_label(galleries, "HeartSign", "The Heart of Everwood\nthe True Raid (Lv 14) waits here: its raid is the next milestone", HEART_AT + Vector3(-8.0, 4.4, 0.0))
	var outward: PartyThreshold = PartyThreshold.new()
	outward.name = "GalleryExit"
	outward.radius = 3.0
	outward.position = GALLERY_ENTRANCE + Vector3(2.0, 0.05, 0.0)
	outward.destination = SEA_DOOR_AT + Vector3(4.0, 0.2, 0.0)
	outward.destination_yaw = -PI * 0.5
	outward.ring_color = CalderaKit.HEARTH_SAFFRON
	galleries.add_child(outward)
	CalderaKit.sign_label(galleries, "GallerySign", "The Sap Galleries\nback out through the Sea-Door", GALLERY_ENTRANCE + Vector3(2.0, 3.0, 0.0))


## The Crown's kin outside the trials: each shore's camps, its landmark's guards and its rare (docs/23 §5).
func _build_kin(root: Node3D) -> void:
	var counts: Dictionary[int, int] = {}
	for entry: Array in KIN:
		var zone: int = int(entry[0])
		var kind: String = String(entry[4])
		counts[zone] = counts.get(zone, 0) + 1
		var spawner: MobSpawner = MobSpawner.new()
		spawner.name = "%sKin%d" % [ZONE_NAMES[zone].replace(" ", ""), counts[zone]]
		spawner.territory = ZONE_NAMES[zone]
		var pack: Array[StringName] = []
		pack.assign(entry[3])
		spawner.variant_ids = pack
		match kind:
			"guard":
				spawner.leash = 18.0
				spawner.respawn_time = GUARD_RESPAWN
			"rare":
				spawner.leash = 26.0
				spawner.respawn_time = RARE_RESPAWN
				spawner.patrol = rare_patrol(zone)
			_:
				spawner.leash = 20.0
				spawner.respawn_time = CAMP_RESPAWN
		var spot: Vector2 = _polar(float(entry[1]), float(entry[2])) if kind != "rare" else _polar(RARE_TRACKS[zone].x, RARE_TRACKS[zone].z)
		spawner.position = ground(spot.x, spot.y)
		spawner.has_hush_crack = kind == "camp" and counts[zone] == 1
		spawner.set_meta(&"crown_kin", kind)
		spawner.add_to_group(&"caldera_streamed_spawners")
		root.add_child(spawner)


static func _box_arrays(size: Vector3) -> Array:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return box.get_mesh_arrays()
