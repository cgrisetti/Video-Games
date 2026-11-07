## The Crown's zone design (docs/23_THE_CROWN_ZONE_REDESIGN.md), checked while
## The Crown is the live island. Run by tools/test_caldera_isles.gd after its
## area checks (so by the smoke test and tools/run_caldera_checks.gd too):
##   1  four shore zones round Miller's Oak, split at the three springs and the
##      Sanctum Gate; the dome is Miller's Oak, the tunnels the Sap Galleries
##   2  the roads: the Ring Path runs through every spring and the gate, stays
##      0-15 m up, never crosses an arena; each trial is off the road on a short
##      spur with the cliff band at its back
##   3  the game theory: west and east are an even choice from the Landing, and
##      every trial is a short walk from a spring (a focal point to regroup at)
##   4  the landmarks: each shore's is tall and seen from both its springs, and
##      Miller's Oak is in sight from every step of the Ring Path
##   5  the kin: camps, guards and a rare on every shore, none in South Bay or on
##      the dome; every camp stands back from every road by more than its kin's
##      waking reach, and away from springs, the Waypost and the trials; each
##      shore's kin teach its trial's lesson
##   6  the townsfolk: five, no town; two at the Waypost and a scout at each spring
##   7  the music: a suite per zone, one key signature (D major's notes) in five
##      modes, holding at an edge; the skies follow the zones
##   8  live: Old Bellows grows on Iron Shore's track and walks it
extends RefCounted

## The Ring Path's height (the PDF's 0-14 m, with a metre of give for the springs' basins).
const RING_LOW: float = 0.0
const RING_HIGH: float = 15.0
## The longest walk (metres) from a trial back to a spring.
const TRIAL_TO_SPRING: float = 400.0
## How far a camp stands back from a road beyond its kin's waking reach.
const ROAD_MARGIN: float = 6.0
const SPRING_CLEAR: float = 60.0
const LANDING_CLEAR: float = 90.0
const Zone = CrownHeartCragBuilder.Zone

var check: Callable
var tree: SceneTree
var level: CalderaArchipelagoWorld
var crown: CrownHeartCragBuilder


func run(live_level: CalderaArchipelagoWorld, checker: Callable) -> void:
	check = checker
	level = live_level
	tree = live_level.get_tree()
	crown = level.streamer.builder as CrownHeartCragBuilder if level.streamer != null else null
	if crown == null:
		check.call(false, "The Crown's zone design: The Crown is the live island")
		return
	_check_zones()
	_check_roads()
	_check_balance()
	_check_landmarks()
	_check_kin()
	_check_townsfolk()
	_check_music_and_skies()
	await _check_rare_walks()


# --- Helpers ---------------------------------------------------------------------------

static func _distance_to_line(at: Vector2, line: PackedVector2Array) -> float:
	var best: float = INF
	for index: int in line.size() - 1:
		var a: Vector2 = line[index]
		var ab: Vector2 = line[index + 1] - a
		var t: float = clampf((at - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		best = minf(best, at.distance_to(a + ab * t))
	return best


## The Ring Path's length between two bearings, the short way round.
func _ring_walk(from: float, to: float) -> float:
	var span: float = rad_to_deg(absf(angle_difference(deg_to_rad(from), deg_to_rad(to))))
	var steps: int = maxi(1, int(span))
	var direction: float = signf(rad_to_deg(angle_difference(deg_to_rad(from), deg_to_rad(to))))
	var total: float = 0.0
	for index: int in steps:
		var a: float = from + direction * span * float(index) / float(steps)
		var b: float = from + direction * span * float(index + 1) / float(steps)
		total += crown.ring_point(a).distance_to(crown.ring_point(b))
	return total


static func _length(line: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in line.size() - 1:
		total += line[index].distance_to(line[index + 1])
	return total


## Whether an eye at `from` sees `to` over the ground (the last few metres, where the thing stands, don't count).
func _sees(from: Vector3, to: Vector3) -> bool:
	var flat: float = Vector2(to.x - from.x, to.z - from.z).length()
	var steps: int = int(flat / 3.0)
	for index: int in range(1, steps):
		var t: float = float(index) / float(steps)
		if flat * (1.0 - t) < 10.0:
			break
		var at: Vector3 = from.lerp(to, t)
		if crown.height_at(at.x, at.z) > at.y - 0.3:
			return false
	return true


func _eye(spot: Vector2) -> Vector3:
	return crown.ground(spot.x, spot.y) + Vector3(0.0, 1.7, 0.0)


func _structure(node_name: String) -> Node:
	return level.streamer.structures.find_child(node_name, true, false)


func _arenas() -> Array[Vector3]:
	return [CrownHeartCragBuilder.IRON_SHORE_AT, CrownHeartCragBuilder.GALE_CLIFFS_AT, CrownHeartCragBuilder.TIDE_GROTTOS_AT]


# --- 1: the zones --------------------------------------------------------------------------

func _check_zones() -> void:
	var wanted: Dictionary[int, Vector3] = {}
	for zone: int in [Zone.SOUTH_BAY, Zone.IRON_SHORE, Zone.GALE_CLIFFS, Zone.TIDE_GROTTOS, Zone.MILLERS_OAK]:
		var at: Vector3 = crown.zone_label_at(zone)
		wanted[zone] = Vector3(at.x, crown.height_at(at.x, at.z) + 0.5, at.z)
	var ok: bool = true
	for zone: int in wanted:
		ok = ok and crown.zone_at(wanted[zone]) == zone
	var gallery: Vector3 = CrownHeartCragBuilder.GALLERY_ROUTE[1]
	ok = ok and crown.zone_at(gallery + Vector3(0.0, 1.0, 0.0)) == Zone.SAP_GALLERIES
	# The edges fall at the springs: a few degrees either side of each is the two shores it joins.
	var edges: Array[Array] = [[CrownHeartCragBuilder.EDGE_SW, Zone.SOUTH_BAY, Zone.IRON_SHORE], [CrownHeartCragBuilder.EDGE_NW, Zone.IRON_SHORE, Zone.GALE_CLIFFS],
		[CrownHeartCragBuilder.EDGE_NE, Zone.GALE_CLIFFS, Zone.TIDE_GROTTOS], [CrownHeartCragBuilder.EDGE_SE, Zone.TIDE_GROTTOS, Zone.SOUTH_BAY]]
	for edge: Array in edges:
		var bearing: float = float(edge[0])
		var before: int = CrownHeartCragBuilder.shore_of_bearing(bearing - 3.0)
		var after: int = CrownHeartCragBuilder.shore_of_bearing(bearing + 3.0)
		ok = ok and before == int(edge[1]) and after == int(edge[2])
	var springs_at_edges: bool = true
	var spring_edges: Array[float] = [CrownHeartCragBuilder.EDGE_SW, CrownHeartCragBuilder.EDGE_NW, CrownHeartCragBuilder.EDGE_SE]
	for index: int in 3:
		var spring: Vector2 = CrownHeartCragBuilder.SPRINGS[index]
		springs_at_edges = springs_at_edges and absf(CrownHeartCragBuilder.bearing_of(spring.x, spring.y) - spring_edges[index]) < 1.0
	var gate: Vector2 = CrownHeartCragBuilder.SANCTUM_GATE_AT
	springs_at_edges = springs_at_edges and absf(CrownHeartCragBuilder.bearing_of(gate.x, gate.y) - CrownHeartCragBuilder.EDGE_NE) < 1.0
	check.call(ok and springs_at_edges,
		"The Crown's zones: South Bay, Iron Shore, Gale Cliffs and Tide Grottos round Miller's Oak's dome (and the Sap Galleries underneath), each pair of shores meeting at a spring or the Sanctum Gate")


# --- 2: the roads ----------------------------------------------------------------------------

func _check_roads() -> void:
	var ring: PackedVector2Array = crown.ring_points(360)
	var through: float = 0.0
	for spring: Vector2 in CrownHeartCragBuilder.SPRINGS:
		through = maxf(through, _distance_to_line(spring, ring))
	through = maxf(through, _distance_to_line(CrownHeartCragBuilder.SANCTUM_GATE_AT, ring))
	var low: float = INF
	var high: float = -INF
	for spot: Vector2 in ring:
		var h: float = crown.height_at(spot.x, spot.y)
		low = minf(low, h)
		high = maxf(high, h)
	var clear: float = INF
	var spurs_reach: bool = true
	var backed: float = 0.0
	for arena: Vector3 in _arenas():
		var centre: Vector2 = Vector2(arena.x, arena.z)
		clear = minf(clear, _distance_to_line(centre, ring) - CrownHeartCragBuilder.ARENA_RADIUS)
		var spur: PackedVector2Array = crown.trial_spur(arena)
		spurs_reach = spurs_reach and spur[spur.size() - 1].distance_to(centre) < CrownHeartCragBuilder.ARENA_RADIUS \
			and _distance_to_line(spur[0], ring) < 2.0 and _length(spur) < 140.0
		var from: Vector2 = centre - CrownHeartCragBuilder.DOME_CENTER
		backed = maxf(backed, from.length() - crown.band_radius_toward(from.normalized()) - CrownHeartCragBuilder.ARENA_RADIUS)
	var length: float = _length(ring)
	check.call(through < 3.0 and low >= RING_LOW and high <= RING_HIGH and clear > 6.0 and spurs_reach and backed < 25.0,
		"the Ring Path (%.0f m round, about %d minutes' walk) runs through all three springs and the Sanctum Gate (within %.1f m) at %.1f to %.1f m up; it passes every trial by at least %.0f m, and each trial sits off it on a short spur with the cliff band at its back (within %.0f m)"
		% [length, int(round(length / 5.0 / 60.0)), through, low, high, clear, backed])


# --- 3: the game theory ----------------------------------------------------------------------

func _check_balance() -> void:
	var landing: float = 180.0
	var west: Vector3 = CrownHeartCragBuilder.IRON_SHORE_AT
	var east: Vector3 = CrownHeartCragBuilder.TIDE_GROTTOS_AT
	var to_west: float = _ring_walk(landing, CrownHeartCragBuilder.bearing_of(west.x, west.z)) + _length(crown.trial_spur(west))
	var to_east: float = _ring_walk(landing, CrownHeartCragBuilder.bearing_of(east.x, east.z)) + _length(crown.trial_spur(east))
	var even: float = maxf(to_west, to_east) / minf(to_west, to_east)
	var spring_bearings: Array[float] = [CrownHeartCragBuilder.EDGE_SW, CrownHeartCragBuilder.EDGE_NW, CrownHeartCragBuilder.EDGE_SE]
	var worst: float = 0.0
	var walks: PackedStringArray = PackedStringArray()
	for arena: Vector3 in _arenas():
		var bearing: float = CrownHeartCragBuilder.bearing_of(arena.x, arena.z)
		var nearest: float = INF
		for spring: float in spring_bearings:
			nearest = minf(nearest, _ring_walk(spring, bearing))
		nearest += _length(crown.trial_spur(arena))
		worst = maxf(worst, nearest)
		walks.append("%.0f m" % nearest)
	check.call(even < 1.15 and worst < TRIAL_TO_SPRING,
		"the game theory: from the Landing the west and east trials are an even choice (%.0f m and %.0f m, %.0f%% apart, so no order dominates), and every trial is a short walk from a spring to regroup at (%s)"
		% [to_west, to_east, (even - 1.0) * 100.0, ", ".join(walks)])


# --- 4: the landmarks ------------------------------------------------------------------------

func _check_landmarks() -> void:
	var kiln: Vector3 = crown.ground(CrownHeartCragBuilder.KILN_AT.x, CrownHeartCragBuilder.KILN_AT.y) + Vector3(0.0, CrownHeartCragBuilder.KILN_HEIGHT, 0.0)
	var arch: Vector3 = crown.ground(CrownHeartCragBuilder.SANCTUM_ARCH_AT.x, CrownHeartCragBuilder.SANCTUM_ARCH_AT.y) + Vector3(0.0, 15.0, 0.0)
	var weep: Vector3 = Vector3(CrownHeartCragBuilder.WEEPING_ARCH_AT.x, 18.0, CrownHeartCragBuilder.WEEPING_ARCH_AT.y)
	var mast: Vector3 = CrownHeartCragBuilder.WAYPOST_AT + Vector3(2.5, CrownHeartCragBuilder.MAST_HEIGHT, 2.5)
	var springs: Array[Vector2] = CrownHeartCragBuilder.SPRINGS
	var gate: Vector2 = CrownHeartCragBuilder.SANCTUM_GATE_AT
	var sights: Array[Array] = [["the Old King's Kiln", kiln, [springs[0], springs[1]]], ["the Sanctum Arch", arch, [springs[1], gate]],
		["the Weeping Arch", weep, [gate, springs[2]]], ["the Waypost's lantern-mast", mast, [springs[2], springs[0]]]]
	var seen: PackedStringArray = PackedStringArray()
	var blind: PackedStringArray = PackedStringArray()
	for sight: Array in sights:
		var all: bool = true
		for from: Vector2 in sight[2]:
			all = all and _sees(_eye(from), sight[1])
		if all:
			seen.append(String(sight[0]))
		else:
			blind.append(String(sight[0]))
	var built: bool = _structure("LandmarkOldKingsKiln") != null and _structure("LandmarkSanctumArch") != null and _structure("LandmarkWeepingArch") != null \
		and _structure("LandmarkWaypostMast") != null and _structure("WorldTree") != null
	# Miller's Oak's upper crown (50 m above the glade) from every step of the Ring Path, the trials and the Landing.
	var oak: Vector3 = CrownHeartCragBuilder.WORLD_TREE_AT + Vector3(0.0, 50.0, 0.0)
	var spots: Array[Vector2] = []
	for index: int in 72:
		spots.append(crown.ring_point(5.0 * float(index)))
	for arena: Vector3 in _arenas():
		spots.append(Vector2(arena.x, arena.z))
	spots.append(CrownHeartCragBuilder.LANDING_AT)
	var hidden: int = 0
	for spot: Vector2 in spots:
		if not _sees(_eye(spot), oak):
			hidden += 1
	check.call(built and blind.is_empty() and hidden == 0,
		"the landmarks: each shore's is seen from both its springs (%s%s), and Miller's Oak from every step of the Ring Path, each trial and the Landing (%d of %d spots)"
		% [", ".join(seen), "" if blind.is_empty() else "; hidden: " + ", ".join(blind), spots.size() - hidden, spots.size()])


# --- 5: the kin --------------------------------------------------------------------------------

func _check_kin() -> void:
	var roads: Array[PackedVector2Array] = crown.roads()
	var per_zone: Dictionary[int, int] = {}
	var rares: Dictionary[int, int] = {}
	var problems: PackedStringArray = PackedStringArray()
	var kin_count: int = 0
	var shore_spawners: int = 0
	var spawners: Array[Node] = level.streamer.structures.find_children("*", "MobSpawner", true, false)
	for node: Node in spawners:
		var spawner: MobSpawner = node as MobSpawner
		if not spawner.has_meta(&"crown_kin"):
			continue
		var kind: String = String(spawner.get_meta(&"crown_kin"))
		shore_spawners += 1
		var at: Vector2 = Vector2(spawner.global_position.x, spawner.global_position.z)
		var zone: int = crown.zone_at(spawner.global_position + Vector3(0.0, 0.5, 0.0))
		per_zone[zone] = per_zone.get(zone, 0) + 1
		kin_count += spawner.variant_ids.size()
		var reach: float = 0.0
		for id: StringName in spawner.variant_ids:
			var variant: MobVariantResource = Bestiary.variant(id)
			reach = maxf(reach, variant.aggro_radius)
			if kind == "rare" and (variant.rank != MobVariantResource.Rank.RARE or not variant.patrols):
				problems.append("%s isn't a patrolling rare" % id)
		if kind == "rare":
			rares[zone] = rares.get(zone, 0) + 1
			var closest: float = INF
			for point: Vector3 in spawner.patrol:
				closest = minf(closest, _distance_to_line(Vector2(point.x, point.z), roads[0]))
			if spawner.patrol.size() < 3 or closest < reach + ROAD_MARGIN or spawner.respawn_time.x < 600.0:
				problems.append("%s walks within %.0f m of the Ring Path" % [spawner.name, closest])
			continue
		for road: PackedVector2Array in roads:
			var near: float = _distance_to_line(at, road)
			if near < reach + ROAD_MARGIN:
				problems.append("%s is %.0f m from a road (wakes at %.0f m)" % [spawner.name, near, reach])
				break
		for spring: Vector2 in CrownHeartCragBuilder.SPRINGS:
			if at.distance_to(spring) < SPRING_CLEAR:
				problems.append("%s is %.0f m from a spring" % [spawner.name, at.distance_to(spring)])
		var waypost: Vector2 = Vector2(CrownHeartCragBuilder.WAYPOST_AT.x, CrownHeartCragBuilder.WAYPOST_AT.z)
		if at.distance_to(waypost) < LANDING_CLEAR or at.distance_to(CrownHeartCragBuilder.LANDING_AT) < LANDING_CLEAR:
			problems.append("%s is near the Waypost or the Landing" % spawner.name)
		for arena: Vector3 in _arenas():
			var gap: float = at.distance_to(Vector2(arena.x, arena.z))
			if gap < CrownHeartCragBuilder.ARENA_RADIUS + 8.0 + reach + 10.0:
				problems.append("%s is %.0f m from a trial" % [spawner.name, gap])
	var shores_ok: bool = true
	for zone: int in [Zone.IRON_SHORE, Zone.GALE_CLIFFS, Zone.TIDE_GROTTOS]:
		shores_ok = shores_ok and per_zone.get(zone, 0) >= 4 and rares.get(zone, 0) == 1
	var quiet: bool = not per_zone.has(Zone.SOUTH_BAY) and not per_zone.has(Zone.MILLERS_OAK)
	# Each shore's kin teach its trial's lesson in small.
	var clinker: MobVariantResource = Bestiary.variant(Bestiary.CLINKER_IRON_MAN)
	var gust: MobVariantResource = Bestiary.variant(Bestiary.GUST_PADFOOT)
	var lasher: MobVariantResource = Bestiary.variant(Bestiary.BLIGHT_LASHER)
	var lessons: bool = clinker.mitigation >= 0.5 and clinker.knockdown_damage_taken > 2.0 and gust.lunge >= 6.0 and lasher.rooted \
		and clinker.health < Bestiary.variant(Bestiary.FORGE_CLAD_SENTINEL).health
	check.call(shores_ok and quiet and lessons and problems.is_empty(),
		"the kin: %d spawners (%d kin) on the three shores (Iron Shore %d, Gale Cliffs %d, Tide Grottos %d, a named rare walking each shore's track), none in South Bay or on the dome; every camp stands back from every road by more than its kin's waking reach, %d m from the springs and %d m from the Waypost and the Landing, clear of the trials; the Clinker Iron-Men glance blows until their poise breaks, the Gust-Padfoots dash 7 m, the Blight-Lashers are rooted%s"
		% [shore_spawners, kin_count, per_zone.get(Zone.IRON_SHORE, 0), per_zone.get(Zone.GALE_CLIFFS, 0), per_zone.get(Zone.TIDE_GROTTOS, 0),
		int(SPRING_CLEAR), int(LANDING_CLEAR), "" if problems.is_empty() else ": " + "; ".join(problems)])


# --- 6: the townsfolk --------------------------------------------------------------------------

func _check_townsfolk() -> void:
	var folk: Array[Node] = level.streamer.structures.find_children("*", "TownsfolkNPC", true, false)
	var waypost: Vector3 = crown.ground(CrownHeartCragBuilder.WAYPOST_AT.x, CrownHeartCragBuilder.WAYPOST_AT.z)
	var at_waypost: int = 0
	var scouts: int = 0
	for node: Node in folk:
		var npc: TownsfolkNPC = node as TownsfolkNPC
		if npc.global_position.distance_to(waypost) < 12.0:
			at_waypost += 1
			continue
		for spring: Vector2 in CrownHeartCragBuilder.SPRINGS:
			if Vector2(npc.global_position.x, npc.global_position.z).distance_to(spring) < 12.0 and npc.role == TownsfolkNPC.Role.QUEST_GIVER \
					and npc.quests.size() == 3:
				scouts += 1
	var warden: TownsfolkNPC = _structure("Warden") as TownsfolkNPC
	check.call(folk.size() == 5 and at_waypost == 2 and scouts == 3 and warden != null and warden.quests.size() == 3,
		"the townsfolk: %d, and no town (the Quartermaster and the Warden at the Waypost, %d scouts at the springs, each with three lines of advice for their shore)"
		% [folk.size(), scouts])


# --- 7: the music and the skies ------------------------------------------------------------------

func _check_music_and_skies() -> void:
	var ok: bool = true
	for zone: int in [Zone.SOUTH_BAY, Zone.IRON_SHORE, Zone.GALE_CLIFFS, Zone.TIDE_GROTTOS, Zone.MILLERS_OAK]:
		var at: Vector3 = crown.zone_label_at(zone)
		at.y = crown.height_at(at.x, at.z) + 0.5
		ok = ok and crown.music_at(at) == CrownHeartCragBuilder.ZONE_MUSIC[zone] and AudioCatalog.zone(CrownHeartCragBuilder.ZONE_MUSIC[zone]) != null
	var gallery: Vector3 = CrownHeartCragBuilder.GALLERY_ROUTE[1] + Vector3(0.0, 1.0, 0.0)
	ok = ok and crown.music_at(gallery) == &"crown_tide_grottos"
	# At the South-West Spring the music already playing holds; ten degrees on, the shore's own takes over.
	var spring: Vector2 = CrownHeartCragBuilder.SPRINGS[0]
	var at_spring: Vector3 = crown.ground(spring.x, spring.y) + Vector3(0.0, 0.5, 0.0)
	var past: Vector2 = crown.ring_point(CrownHeartCragBuilder.EDGE_SW + 10.0)
	var holds: bool = crown.music_at(at_spring, &"crown_south_bay") == &"crown_south_bay" and crown.music_at(at_spring, &"crown_iron_shore") == &"crown_iron_shore" \
		and crown.music_at(crown.ground(past.x, past.y) + Vector3(0.0, 0.5, 0.0), &"crown_south_bay") == &"crown_iron_shore"
	# One key signature: every Crown suite's mode, on its root, uses only D major's notes.
	var d_major: Array[int] = [2, 4, 6, 7, 9, 11, 1]
	var modes: PackedStringArray = PackedStringArray()
	var unity: bool = true
	for music: StringName in [&"crown_south_bay", &"crown_iron_shore", &"crown_gale_cliffs", &"crown_tide_grottos", &"crown_millers_oak"]:
		var profile: ZoneMusicProfileResource = AudioCatalog.zone(music)
		if profile == null:
			unity = false
			continue
		modes.append(String(profile.modal_signature).replace("_", " "))
		for step: int in profile.lead_scale:
			unity = unity and (profile.root_pitch_midi + step) % 12 in d_major
	# The level plays them, and the skies follow the zones.
	var level_ok: bool = level.music_profile_at(crown.zone_label_at(Zone.IRON_SHORE) + Vector3(0.0, 20.0, 0.0)) in [&"crown_iron_shore"]
	var skies: bool = level.visual_biome_at(crown.zone_label_at(Zone.GALE_CLIFFS) + Vector3(0.0, 20.0, 0.0)) == WorldVisualCatalog.GULL_WICK_HAVEN \
		and level.visual_biome_at(crown.zone_label_at(Zone.IRON_SHORE) + Vector3(0.0, 20.0, 0.0)) == WorldVisualCatalog.QUARRY_WICK
	check.call(ok and holds and unity and level_ok and skies,
		"the music: a suite for each zone (%s), every one in D major's notes so a crossfade never clashes, the Tide's under the ground too; at a spring the tune playing holds, ten degrees on the shore's own takes over; the skies follow the shores"
		% ", ".join(modes))


# --- 8: a rare walks its track -------------------------------------------------------------------

func _check_rare_walks() -> void:
	var rare: MobSpawner = null
	for node: Node in level.streamer.structures.find_children("*", "MobSpawner", true, false):
		var spawner: MobSpawner = node as MobSpawner
		if spawner.has_meta(&"crown_kin") and String(spawner.get_meta(&"crown_kin")) == "rare" and spawner.territory == "Iron Shore":
			rare = spawner
	if rare == null:
		check.call(false, "Old Bellows walks Iron Shore's track")
		return
	# The party waits on the Ring Path, beyond its waking reach, while it streams in.
	var watch: Vector2 = crown.ring_point(284.0)
	for actor: ActorBase in level.party_in_order():
		if actor.is_multiplayer_authority():
			var spot: Vector3 = Vector3(watch.x, crown.height_at(watch.x, watch.y) + 0.3, watch.y)
			level.streamer.ensure_ground_at(spot)
			actor.place_at(Transform3D(Basis.IDENTITY, spot))
	level.streamer.load_now([rare.global_position, Vector3(watch.x, 0.0, watch.y)])
	for index: int in 10:
		await tree.physics_frame
	if rare.mobs.is_empty():
		rare.spawn_mobs()
		for index: int in 4:
			await tree.physics_frame
	var bellows: WildMob = rare.mobs[0] if not rare.mobs.is_empty() else null
	var start: Vector3 = bellows.global_position if is_instance_valid(bellows) else Vector3.ZERO
	for index: int in 300:
		await tree.physics_frame
	var walked: float = bellows.global_position.distance_to(start) if is_instance_valid(bellows) else 0.0
	check.call(is_instance_valid(bellows) and bellows.variant.variant_id == Bestiary.OLD_BELLOWS and walked > 2.0 and not bellows.stats.is_downed,
		"Old Bellows (Rare) grows on Iron Shore's vents track and walks it (%.1f m in 5 s) while the party watches from the Ring Path" % walked)
