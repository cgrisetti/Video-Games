## The three friction isles (docs/20 Part I; the Master Atlas): Iron-Ness
## (west, Lv 6-10), Barrow-Eyot (east, Lv 8-12) and Rime-Firth (north, Lv
## 10-14). Biomes come from rock and exposure, not latitude: Iron-Ness is
## hydrothermal ironstone and over-delved mines; Barrow-Eyot is a sunken
## stretch of the caldera rim gone to tidal fen; Rime-Firth is the high basalt
## rim facing The Breach, snowed from altitude and sea-fog.
##
## Le Guin's rule on every one: the sheltered inner shore (facing The Sound
## and The Crown) holds the arrival (causeway or skiff quay), the steading
## (Forge-Gorge, Lantern Staithe, Gale-Hall) and the island's Beacon with its
## guardians; the wild outer shore (facing the Open Sea) holds the landmark
## (Forge Stacks, Bell-Tower, Snow Peak), the island's kin camps and the
## sealed raid gate at -4.5 m that the Ebb bares (A, C, B).
class_name FrictionIslesBuilder
extends IslandBuilder

## Each isle's shape: semi-axes, and (local, x-z) its steading, Beacon, landmark and raid gate
## (keyed by CalderaAtlas isle id, spelled out: a constant can't read another class's constant across a class cycle).
const SHAPES: Dictionary[StringName, Dictionary] = {
	&"isle_iron_ness": {"semi": Vector2(430.0, 640.0), "steading": Vector2(170.0, -80.0), "beacon": Vector2(338.0, -170.0),
		"landmark": Vector2(-230.0, -190.0), "gate": Vector2(-404.0, 120.0), "gate_yaw": -PI * 0.5,
		"camps": [[Vector2(-250.0, -40.0), [&"foreman_iron_gavel", &"soot_paw_cutthroat", &"quarry_sling_shotter"]],
			[Vector2(-170.0, 300.0), [&"soot_paw_cutthroat", &"soot_paw_cutthroat"]], [Vector2(40.0, -470.0), [&"quarry_sling_shotter", &"quarry_sling_shotter"]]],
		"guards": [&"soot_paw_cutthroat", &"quarry_sling_shotter"],
		"steading_line": "Forge-Gorge\nthe smiths' steading, cold forges and empty bellows", "gate_name": "Raid Gate A: the Under-Forge Abyss",
		"gate_line": "the over-delved mine's sea-cave, bared by the Ebb: its raid is still to be built"},
	&"isle_barrow_eyot": {"semi": Vector2(480.0, 560.0), "steading": Vector2(-250.0, 230.0), "beacon": Vector2(-420.0, -90.0),
		"landmark": Vector2(40.0, -20.0), "gate": Vector2(452.0, 150.0), "gate_yaw": PI * 0.5,
		"camps": [[Vector2(250.0, -200.0), [&"river_snapper_toad", &"river_snapper_toad", &"grey_pelt_prowler"]],
			[Vector2(160.0, 300.0), [&"spore_puff_shambler", &"bramble_lasher_vine"]], [Vector2(320.0, 60.0), [&"bog_hulk_tangler"]]],
		"guards": [&"river_snapper_toad", &"grey_pelt_prowler"],
		"steading_line": "Lantern Staithe\nthe lamp-makers' landing stage, its oil-jars dry", "gate_name": "Raid Gate C: the Sunken Cathedral",
		"gate_line": "the bell-tower's sea door, bared by the Ebb: its raid is still to be built"},
	&"isle_rime_firth": {"semi": Vector2(660.0, 430.0), "steading": Vector2(-220.0, 250.0), "beacon": Vector2(-70.0, 352.0),
		"landmark": Vector2(60.0, -150.0), "gate": Vector2(0.0, -414.0), "gate_yaw": PI,
		"camps": [[Vector2(-320.0, -90.0), [&"alpha_frost_fang", &"grey_pelt_prowler", &"grey_pelt_prowler"]],
			[Vector2(320.0, -140.0), [&"hollow_scribe_acolyte", &"risen_shield_sworn_husk"]], [Vector2(160.0, -300.0), [&"barrow_warden_knell"]]],
		"guards": [&"grey_pelt_prowler", &"alpha_frost_fang"],
		"steading_line": "Gale-Hall\nthe Wayfarers' long hall, its hearth low on fuel", "gate_name": "Raid Gate B: the Frost-Peak Aerie",
		"gate_line": "the whalers' stair up the sea-cliff, bared by the Ebb: its raid is still to be built"},
}
## Rime-Firth's Snow Peak: where it stands, how high, how broad.
const PEAK_HEIGHT: float = 210.0
const PEAK_RADIUS: float = 170.0
## Rime-Firth's inner quay (the Salt Road's skiff docks at its head).
const RIME_PIER_ROOT: Vector3 = Vector3(60.0, 1.6, 412.0)
const RIME_PIER_HEAD_Z: float = 462.0

var shape: Dictionary = {}
var inner: Vector2 = Vector2.ZERO
## The steading's level ground: the land's own height round it (docs/26; it once sat in a pit up to 34 m deep).
var _steading_y: float = 0.0


func _define() -> void:
	shape = SHAPES[isle.isle_id]
	inner = (-isle.sound_position).normalized()
	var steading: Vector2 = shape["steading"]
	var beacon: Vector2 = shape["beacon"]
	var gate: Vector2 = shape["gate"]
	_steading_y = _ground_round(steading, 30.0)
	add_pad(steading, 30.0, _steading_height(), 24.0)
	add_pad(beacon, 9.0, maxf(4.0, _base_height(beacon.x, beacon.y)), 8.0)
	# The raid gate's cove, cut into the outer shore at -4.5 m, with a stair down from the cliff-top.
	add_pad(gate + _outward(gate) * 8.0, 11.0, -4.5, 5.0)
	var stair_top: Vector2 = gate - _outward(gate) * 26.0 + _outward(gate).orthogonal() * 10.0
	add_ramp(Vector3(stair_top.x, _base_height(stair_top.x, stair_top.y), stair_top.y), Vector3(gate.x + _outward(gate).x * 6.0, -4.5, gate.y + _outward(gate).y * 6.0), 2.6, 2.5)
	var arrival: Vector2
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			var anchor: Vector3 = CalderaAtlas.seam(CalderaAtlas.SEAM_WEST_STRAIT).anchor(isle.isle_id)
			add_pad(Vector2(anchor.x, anchor.z - 12.0), 10.0, anchor.y, 8.0)
			# The road up from the West Strait finds its own way now (docs/26): no straight trench to the steading.
			arrival = Vector2(anchor.x, anchor.z - 16.0)
			add_path(PackedVector2Array([arrival, Vector2(steading.x + 10.0, steading.y + 30.0), steading, beacon]), 2.0)
		CalderaAtlas.ISLE_BARROW_EYOT:
			var anchor: Vector3 = CalderaAtlas.seam(CalderaAtlas.SEAM_EEL_SPIT).anchor(isle.isle_id)
			add_pad(Vector2(anchor.x, anchor.z - 12.0), 10.0, anchor.y, 8.0)
			arrival = Vector2(anchor.x, anchor.z - 16.0)
			add_path(PackedVector2Array([arrival, steading, Vector2(-330.0, 60.0), beacon]), 2.0)
			add_path(PackedVector2Array([steading, Vector2(-80.0, 80.0), Vector2(shape["landmark"].x - 40.0, shape["landmark"].y + 20.0)]), 1.8)
		CalderaAtlas.ISLE_RIME_FIRTH:
			add_pad(Vector2(RIME_PIER_ROOT.x, RIME_PIER_ROOT.z - 12.0), 16.0, 3.0, 10.0)
			add_ramp(Vector3(RIME_PIER_ROOT.x, 3.0, RIME_PIER_ROOT.z - 4.0), Vector3(RIME_PIER_ROOT.x, 1.6, RIME_PIER_ROOT.z + 4.0), 3.0, 2.0)
			arrival = Vector2(RIME_PIER_ROOT.x, RIME_PIER_ROOT.z - 14.0)
			add_path(PackedVector2Array([arrival, beacon, steading]), 2.0)
			add_arrival(CalderaAtlas.ARRIVE_QUAY, arrival)
	add_arrival(&"arrival", arrival)
	add_arrival(CalderaAtlas.ARRIVE_BEACON, beacon - _outward(beacon) * 14.0)
	add_path(PackedVector2Array([steading, steading.lerp(Vector2.ZERO, 0.5), _landmark_lookout()]), 1.6)
	add_place(String(shape["steading_line"]).get_slice("\n", 0), Vector3(steading.x, 0.0, steading.y), 80.0)
	add_place("%s's Beacon" % isle.display_name, Vector3(beacon.x, 0.0, beacon.y), 40.0)
	add_place(isle.landmark if isle.isle_id != CalderaAtlas.ISLE_BARROW_EYOT else "The Bell-Tower", Vector3(shape["landmark"].x, 0.0, shape["landmark"].y), 90.0)
	add_place(String(shape["gate_name"]), Vector3(gate.x, -4.5, gate.y), 45.0)


## Where the path to the landmark ends: at the Forge Stacks themselves, on the Bell-Tower lagoon's
## outer shore, at the Snow Peak's foot (docs/26: the paths once ran into the lagoon and up the peak).
func _landmark_lookout() -> Vector2:
	var landmark: Vector2 = shape["landmark"]
	var home: Vector2 = shape["steading"]
	match isle.isle_id:
		CalderaAtlas.ISLE_BARROW_EYOT:
			return landmark + (home - landmark).normalized() * 84.0
		CalderaAtlas.ISLE_RIME_FIRTH:
			return landmark + (home - landmark).normalized() * 210.0
	return landmark


func _steading_height() -> float:
	return _steading_y


## The land's mean height at a spot and on a ring `radius` round it (never below 2.2 m, a fen steading's floor).
func _ground_round(at: Vector2, radius: float) -> float:
	var total: float = _base_height(at.x, at.y)
	for step: int in 8:
		var angle: float = TAU * float(step) / 8.0
		total += _base_height(at.x + cos(angle) * radius, at.y + sin(angle) * radius)
	return maxf(2.2, total / 9.0)


## Out to the open sea from a spot, as a unit x-z direction.
func _outward(at: Vector2) -> Vector2:
	var semi: Vector2 = shape["semi"]
	return Vector2(at.x / (semi.x * semi.x), at.y / (semi.y * semi.y)).normalized()


func _coast_shape() -> Dictionary:
	return {"center": Vector2.ZERO, "semi": SHAPES[isle.isle_id]["semi"]}


## Rime-Firth's high basalt shore takes steep-sided firths where the others take low river inlets.
func _inlet_max_rise() -> float:
	return 70.0 if isle.isle_id == CalderaAtlas.ISLE_RIME_FIRTH else super()


func _base_height(x: float, z: float) -> float:
	var semi: Vector2 = SHAPES[isle.isle_id]["semi"]
	var q: float = ellipse_q(x, z, Vector2.ZERO, semi, 0.07)
	if q > 1.0:
		return sea_floor(q)
	var inland: float = 1.0 - q
	var facing: Vector2 = Vector2(x, z).normalized()
	var outer: float = clampf(-facing.dot((-isle.sound_position).normalized()), 0.0, 1.0)
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			var ridges: float = 9.0 * absf(noise(x * 1.1, z * 1.1)) + 3.0 * detail(x * 0.5, z * 0.5)
			var interior: float = 5.0 + 24.0 * smoothstep(0.0, 0.45, inland) + ridges * smoothstep(0.05, 0.3, inland)
			var beach: float = smoothstep(0.0, 0.08, inland)
			var cliff: float = smoothstep(0.0, 0.02, inland)
			return lerpf(-1.5, interior, lerpf(beach, cliff, smoothstep(0.2, 0.6, outer)))
		CalderaAtlas.ISLE_BARROW_EYOT:
			var fen: float = 1.0 + 3.2 * smoothstep(0.0, 0.3, inland) + 1.6 * noise(x * 1.3, z * 1.3)
			var pools: float = detail(x * 0.35, z * 0.35)
			if pools < -0.32 and inland > 0.12:
				fen -= 3.6 * smoothstep(-0.32, -0.5, pools)
			# The lagoon round the Bell-Tower's mound.
			var landmark: Vector2 = SHAPES[isle.isle_id]["landmark"]
			var ring: float = Vector2(x - landmark.x, z - landmark.y).length()
			if ring < 80.0:
				fen = lerpf(fen, -1.8, smoothstep(30.0, 42.0, ring) * (1.0 - smoothstep(64.0, 80.0, ring)))
				fen = lerpf(fen, 4.0, 1.0 - smoothstep(22.0, 32.0, ring))
			return lerpf(-1.5, fen, smoothstep(0.0, 0.12, inland))
	# Rime-Firth: the high rim, and the Snow Peak.
	var rim: float = 10.0 + 30.0 * smoothstep(0.0, 0.32, inland) + 9.0 * absf(noise(x * 0.9, z * 0.9))
	var peak_at: Vector2 = SHAPES[isle.isle_id]["landmark"]
	var d: float = Vector2(x - peak_at.x, z - peak_at.y).length()
	rim += PEAK_HEIGHT * exp(-(d * d) / (PEAK_RADIUS * PEAK_RADIUS)) * (1.0 + 0.08 * noise(x * 3.0, z * 3.0))
	var beach: float = smoothstep(0.0, 0.1, inland)
	var cliff: float = smoothstep(0.0, 0.03, inland)
	return lerpf(-1.5, rim, lerpf(beach, cliff, smoothstep(0.15, 0.5, outer)))


func _ground_color(x: float, z: float, height: float, up: float) -> Color:
	var patch: float = 0.5 + 0.5 * detail(x * 0.7, z * 0.7)
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			return shore_or(height, up, Color(0.42, 0.52, 0.3).lerp(Color(0.48, 0.54, 0.32), patch), CalderaKit.IRONSTONE)
		CalderaAtlas.ISLE_BARROW_EYOT:
			var fen: Color = Color(0.38, 0.5, 0.3).lerp(Color(0.44, 0.52, 0.34), patch)
			if height < 0.4 and height > -2.5:
				return Color(0.3, 0.34, 0.26)
			return shore_or(height, up, fen, Color(0.42, 0.4, 0.36))
	var heath: Color = Color(0.42, 0.52, 0.36).lerp(Color(0.5, 0.44, 0.5), patch * 0.3)
	var snow: float = smoothstep(62.0, 90.0, height + 8.0 * detail(x * 2.0, z * 2.0))
	return shore_or(height, up, heath, CalderaKit.BASALT.lightened(0.15)).lerp(CalderaKit.SNOW, snow)


func _scatter_species(x: float, z: float, height: float, up: float, roll: float) -> int:
	var steading: Vector2 = shape["steading"]
	if Vector2(x - steading.x, z - steading.y).length() < 42.0:
		return -1
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			if height < 1.2:
				return -1
			if up < 0.7:
				return Species.BOULDER if roll < 0.12 else -1
			return Species.PINE_TREE if roll < 0.08 else (Species.BOULDER if roll < 0.13 else (Species.ROCK if roll < 0.2 else -1))
		CalderaAtlas.ISLE_BARROW_EYOT:
			if height < -0.6:
				return -1
			if height < 1.6:
				return Species.REED_CLUMP if roll < 0.4 else -1
			if roll < 0.025:
				return Species.WILLOW_TREE
			return Species.OAK_TREE if roll < 0.045 else (Species.REED_CLUMP if roll < 0.18 else (Species.FERN_TUFT if roll < 0.24 else -1))
	if height < 1.2:
		return -1
	if up < 0.66:
		return Species.BASALT_SPIRE if roll < 0.06 else -1
	if height > 95.0:
		return -1
	return (Species.SNOW_PINE if height > 45.0 else Species.PINE_TREE) if roll < 0.07 else (Species.ROCK if roll < 0.13 else -1)


func landmark_silhouette(into: LandblockTerrain.MeshMerge) -> void:
	var at: Vector2 = SHAPES[isle.isle_id]["landmark"]
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			CalderaKit.add_forge_stacks(into, ground(at.x, at.y))
		CalderaAtlas.ISLE_BARROW_EYOT:
			CalderaKit.add_bell_tower(into, ground(at.x, at.y))


# --- Structures ------------------------------------------------------------------------

func build_structures(root: Node3D) -> void:
	_build_steading(root)
	_build_beacon(root)
	_build_landmark(root)
	_build_raid_gate(root)
	_build_camps(root)
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			CalderaCauseway.build(root, CalderaAtlas.seam(CalderaAtlas.SEAM_WEST_STRAIT), isle.isle_id)
		CalderaAtlas.ISLE_BARROW_EYOT:
			CalderaCauseway.build(root, CalderaAtlas.seam(CalderaAtlas.SEAM_EEL_SPIT), isle.isle_id)
		CalderaAtlas.ISLE_RIME_FIRTH:
			_build_rime_quay(root)


func _build_steading(root: Node3D) -> void:
	var steading: Vector2 = shape["steading"]
	var at: Vector3 = ground(steading.x, steading.y)
	var kit: StringName = WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE
	for index: int in 5:
		var angle: float = TAU * float(index) / 5.0 + 0.5
		var spot: Vector3 = ground(at.x + cos(angle) * 22.0, at.z + sin(angle) * 22.0)
		root.add_child(WorldKitInstance.make("SteadingHouse%d" % index, kit, spot, -angle + PI * 0.5, {"seed_value": 40 + index}))
		CalderaKit.solid_box(root, "SteadingHouseBody%d" % index, spot + Vector3(0.0, 2.5, 0.0), Vector3(6.0, 5.0, 6.0), -angle + PI * 0.5)
	var hall: LandblockTerrain.MeshMerge = CalderaKit.merge()
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			CalderaKit.add_hut(hall, at + Vector3(0.0, 0.0, -6.0), Vector3(12.0, 4.0, 8.0), 0.0, CalderaKit.IRONSTONE.lerp(CalderaKit.STONE, 0.4), CalderaKit.DARK_STONE)
			CalderaKit.add_post(hall, at + Vector3(4.0, 4.0, -8.0), 0.8, 1.0, 8.0, CalderaKit.IRONSTONE.darkened(0.2), 8)
			CalderaKit.add_box(hall, at + Vector3(-3.0, 0.5, 2.0), Vector3(1.6, 1.0, 0.8), CalderaKit.DARK_STONE)
			CalderaKit.plume(root, "ForgeSmoke", at + Vector3(4.0, 12.5, -8.0), Color(0.4, 0.38, 0.36, 0.5), 2.0, 0.6, 12)
		CalderaAtlas.ISLE_BARROW_EYOT:
			CalderaKit.add_pier(hall, at + Vector3(-20.0, 0.0, 14.0), at + Vector3(-62.0, 0.0, 34.0), 4.0, at.y + 0.4)
			CalderaKit.add_hut(hall, at + Vector3(0.0, 0.0, -6.0), Vector3(8.0, 3.4, 6.0), 0.3, Color(0.7, 0.66, 0.56), CalderaKit.THATCH)
			for index: int in 6:
				CalderaKit.add_post(hall, at + Vector3(-14.0 + index * 6.0, 0.0, 12.0), 0.08, 0.1, 3.0, CalderaKit.DARK_TIMBER, 5)
				CalderaKit.add_box(hall, at + Vector3(-14.0 + index * 6.0, 3.1, 12.0), Vector3(0.5, 0.6, 0.5), CalderaKit.SAFFRON.darkened(0.4))
		_:
			CalderaKit.add_hut(hall, at + Vector3(0.0, 0.0, -6.0), Vector3(24.0, 4.2, 9.0), 0.0, CalderaKit.TIMBER.lightened(0.1), CalderaKit.DARK_STONE)
			for index: int in 4:
				CalderaKit.add_ruin_wall(hall, at + Vector3(-18.0 + index * 12.0, 0.0, -18.0), 8.0, 2.4, PI * 0.5, CalderaKit.STONE, 120 + index)
	root.add_child(CalderaKit.mesh_node("SteadingHall", hall))
	CalderaKit.solid_box(root, "SteadingHallBody", at + Vector3(0.0, 2.0, -6.0), Vector3(10.0, 4.0, 6.0))
	var elder: TownsfolkNPC = TownsfolkNPC.new()
	elder.name = "SteadingElder"
	elder.role = TownsfolkNPC.Role.QUEST_GIVER
	var line: String = String(shape["steading_line"])
	elder.npc_name = {CalderaAtlas.ISLE_IRON_NESS: "Garrow Flintmantle", CalderaAtlas.ISLE_BARROW_EYOT: "Ysolde Reedlamp",
		CalderaAtlas.ISLE_RIME_FIRTH: "Hakon Frostbridge"}[isle.isle_id]
	elder.title = "Elder of %s" % line.get_slice("\n", 0)
	elder.hub = line.get_slice("\n", 0)
	elder.quests = PackedStringArray(["Calm the Beacon's guardians on the inner shore", "Kindle %s's Beacon" % isle.display_name,
		"Look on the %s from the outer shore" % isle.landmark])
	elder.body_color = isle.accent_color.darkened(0.3)
	elder.accent_color = CalderaKit.SAFFRON
	elder.npc_seed = hash(isle.isle_id) % 89
	elder.position = at + Vector3(0.0, 0.0, 6.0)
	root.add_child(elder)
	CalderaKit.sign_label(root, "SteadingSign", "%s\n%s · %s" % [line, isle.display_name, isle.level_band()], at + Vector3(0.0, 4.0, 10.0))


func _build_beacon(root: Node3D) -> void:
	var spot: Vector2 = shape["beacon"]
	var at: Vector3 = ground(spot.x, spot.y)
	var guards: MobSpawner = MobSpawner.new()
	guards.name = "BeaconGuards"
	guards.territory = "%s's Beacon" % isle.display_name
	var pack: Array[StringName] = []
	pack.assign(shape["guards"])
	guards.variant_ids = pack
	guards.leash = 18.0
	guards.respawn_time = Vector2(1.0e9, 1.0e9)
	guards.position = ground(spot.x - _outward(spot).x * 12.0, spot.y - _outward(spot).y * 12.0)
	guards.add_to_group(&"caldera_streamed_spawners")
	guards.set_meta(&"beacon_guards", true)
	root.add_child(guards)
	var beacon: IslandBeacon = IslandBeacon.new()
	beacon.name = "Beacon"
	beacon.isle_id = isle.isle_id
	beacon.guards = guards
	beacon.position = at
	beacon.rotation.y = atan2(-_outward(spot).x, -_outward(spot).y)
	root.add_child(beacon)


func _build_landmark(root: Node3D) -> void:
	var at: Vector2 = shape["landmark"]
	var merged: LandblockTerrain.MeshMerge = CalderaKit.merge()
	match isle.isle_id:
		CalderaAtlas.ISLE_IRON_NESS:
			CalderaKit.add_forge_stacks(merged, ground(at.x, at.y))
			for index: int in 3:
				CalderaKit.plume(root, "StackSmoke%d" % index, ground(at.x, at.y) + Vector3(-12.0 + 12.0 * index, 66.0 + 8.0 * float(index % 2), -2.0),
					Color(0.36, 0.34, 0.34, 0.55), 4.0, 1.6, 16)
			CalderaKit.solid_box(root, "ForgeHall", ground(at.x, at.y) + Vector3(0.0, 6.0, 0.0), Vector3(34.0, 12.0, 16.0))
			CalderaKit.sign_label(root, "LandmarkSign", "The Forge Stacks\nIron-Ness's over-delved mines", ground(at.x, at.y + 14.0) + Vector3(0.0, 3.0, 0.0))
		CalderaAtlas.ISLE_BARROW_EYOT:
			CalderaKit.add_bell_tower(merged, ground(at.x, at.y))
			CalderaKit.solid_box(root, "BellTowerBody", ground(at.x, at.y) + Vector3(0.0, 16.0, 0.0), Vector3(9.0, 32.0, 9.0))
			CalderaKit.sign_label(root, "LandmarkSign", "The Bell-Tower\nits sea door sank with the fen", ground(at.x, at.y + 10.0) + Vector3(0.0, 2.6, 0.0))
		CalderaAtlas.ISLE_RIME_FIRTH:
			CalderaKit.sign_label(root, "LandmarkSign", "The Snow Peak\nthe high rim facing The Breach", ground(at.x + 120.0, at.y + 180.0) + Vector3(0.0, 3.0, 0.0))
	if not merged.is_empty():
		root.add_child(CalderaKit.mesh_node("Landmark", merged))


func _build_raid_gate(root: Node3D) -> void:
	var at: Vector2 = shape["gate"]
	var gate: SeaGate = SeaGate.new()
	gate.name = "RaidGate"
	gate.title = String(shape["gate_name"])
	gate.beyond = String(shape["gate_line"])
	gate.facing_yaw = float(shape["gate_yaw"])
	gate.position = Vector3(at.x, -4.5, at.y)
	root.add_child(gate)


func _build_camps(root: Node3D) -> void:
	var camps: Array = shape["camps"]
	for index: int in camps.size():
		var camp: Array = camps[index]
		var spot: Vector2 = camp[0]
		var spawner: MobSpawner = MobSpawner.new()
		spawner.name = "OuterShoreKin%d" % (index + 1)
		spawner.territory = "%s's outer shore" % isle.display_name
		var pack: Array[StringName] = []
		pack.assign(camp[1])
		spawner.variant_ids = pack
		spawner.leash = 22.0
		spawner.position = ground(spot.x, spot.y)
		spawner.has_hush_crack = index == 0
		spawner.add_to_group(&"caldera_streamed_spawners")
		root.add_child(spawner)


func _build_rime_quay(root: Node3D) -> void:
	var dock: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_pier(dock, RIME_PIER_ROOT, Vector3(RIME_PIER_ROOT.x, RIME_PIER_ROOT.y, RIME_PIER_HEAD_Z), 6.0, RIME_PIER_ROOT.y)
	root.add_child(CalderaKit.mesh_node("InnerQuay", dock))
	var length: float = RIME_PIER_HEAD_Z - RIME_PIER_ROOT.z
	CalderaKit.solid_box(root, "QuayDeck", Vector3(RIME_PIER_ROOT.x, RIME_PIER_ROOT.y - 0.2, RIME_PIER_ROOT.z + length * 0.5), Vector3(6.0, 0.4, length),
		0.0, ActorBase.LAYER_LOW_SCENERY)
	var bell: SkiffBell = SkiffBell.new()
	bell.name = "SaltRoadBell"
	bell.seam_id = CalderaAtlas.SEAM_SALT_ROAD
	bell.position = Vector3(RIME_PIER_ROOT.x - 1.8, RIME_PIER_ROOT.y, RIME_PIER_HEAD_Z - 2.0)
	root.add_child(bell)
	var skiff: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_skiff(skiff)
	var moored: MeshInstance3D = CalderaKit.mesh_node("MooredSkiff", skiff)
	moored.position = CalderaAtlas.seam(CalderaAtlas.SEAM_SALT_ROAD).anchor(isle.isle_id) + Vector3(0.0, -1.5, 0.0)
	moored.rotation.y = PI
	root.add_child(moored)
	CalderaKit.sign_label(root, "QuaySign", "Rime-Firth's inner quay\nthe Salt Road home to North Quay", ground(RIME_PIER_ROOT.x - 8.0, RIME_PIER_ROOT.z - 10.0) + Vector3(0.0, 2.6, 0.0))
