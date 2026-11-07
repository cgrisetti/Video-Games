## Miller's Oak (docs/20 Part I; docs/atlas_sources/02_master_atlas_caldera_isles.pdf):
## the south isle, Zone 1, Lv 1-6, the hub every trade lane runs through. The
## lee shore of the old caldera, on volcanic ash-loam, the richest farm soil in
## The Sound:
##
##   - the Lee-Shore Orchards and the Windmill (south-east, Lv 1-2), where the
##     party starts, with curious Bristle-Hobs among the trees
##   - Hearthstead Market (centre-east): the green, the Chime-Alchemist, the
##     Blacksmith, the Inn and the Calling Tutor, and the three lane stalls
##     (Iron, Lantern, Provisions) shuttered until their Beacons are lit
##   - the Root-Sanctum (south-west interior, Lv 6): the petrified Elder-Oak
##     whose way in leads to the Cairnsman's expedition; clearing it sets
##     root_sanctum_cleared and the three lanes go dark
##   - North Quay, facing The Sound: the Salt Road and Crown Landing
##     Chime-Bells, and an open 180-degree sightline over the water to The
##     Crown's World-Tree, the Forge Stacks, the Snow Peak and the Bell-Tower
##   - the Old Quay Market (north-west shore, -4 m), under the Long Flood until
##     the Ebb bares it for the endgame's Chime and gear merchants
##   - the West Strait's causeway (north-west tip) and Eel Spit (north-east tip)
class_name OakshireHolmBuilder
extends IslandBuilder

const CENTER: Vector2 = Vector2(0.0, 20.0)
const SEMI_AXES: Vector2 = Vector2(640.0, 360.0)
const MARKET_AT: Vector2 = Vector2(140.0, 10.0)
const MARKET_RADIUS: float = 34.0
const WINDMILL_AT: Vector2 = Vector2(380.0, 110.0)
const ORCHARDS_AT: Vector2 = Vector2(390.0, 200.0)
const ORCHARDS_RADIUS: float = 170.0
const ROOT_SANCTUM_AT: Vector2 = Vector2(-330.0, 110.0)
const NORTH_QUAY_AT: Vector2 = Vector2(40.0, -318.0)
const PIER_ROOT: Vector3 = Vector3(40.0, 1.6, -332.0)
const PIER_HEAD_Z: float = -414.0
const OLD_QUAY_AT: Vector3 = Vector3(-290.0, -4.0, -322.0)
## The orchard lane's foot, 10 m up from where it starts, and which way it climbs toward the market.
const ORCHARD_LANE_FOOT: Vector2 = Vector2(354.0, 222.0)
const ORCHARD_LANE_UP: Vector2 = Vector2(-0.6, -0.8)
## The arrival point: Player 1's seat (the first of a row of four, 3.6 m left of
## the row's middle) stands on the lane at ORCHARD_LANE_FOOT.
const ORCHARD_ARRIVAL: Vector2 = Vector2(356.88, 219.84)


func _define() -> void:
	var market_h: float = _base_height(MARKET_AT.x, MARKET_AT.y)
	add_pad(MARKET_AT, MARKET_RADIUS, market_h, 14.0)
	add_pad(WINDMILL_AT, 12.0, _base_height(WINDMILL_AT.x, WINDMILL_AT.y) + 2.0, 12.0)
	add_pad(ROOT_SANCTUM_AT, 22.0, _base_height(ROOT_SANCTUM_AT.x, ROOT_SANCTUM_AT.y), 10.0)
	add_pad(NORTH_QUAY_AT, 26.0, 3.0, 10.0)
	add_ramp(Vector3(40.0, 3.0, -330.0), Vector3(40.0, 1.6, -340.0), 3.0, 2.0)
	# The Old Quay Market's shelf, and the old stair down to it.
	add_pad(Vector2(OLD_QUAY_AT.x, OLD_QUAY_AT.z), 22.0, OLD_QUAY_AT.y, 5.0)
	add_ramp(Vector3(-290.0, 2.6, -286.0), Vector3(-290.0, -4.0, -302.0), 2.6, 2.0)
	# The causeway aprons at the north-west and north-east tips.
	for seam_id: StringName in [CalderaAtlas.SEAM_WEST_STRAIT, CalderaAtlas.SEAM_EEL_SPIT]:
		var anchor: Vector3 = CalderaAtlas.seam(seam_id).anchor(CalderaAtlas.ISLE_OAKSHIRE_HOLM)
		add_pad(Vector2(anchor.x, anchor.z + 12.0), 10.0, anchor.y, 8.0)
	# Roads: orchards to the market to the quay, and out to the sanctum and both aprons.
	var west: Vector3 = CalderaAtlas.seam(CalderaAtlas.SEAM_WEST_STRAIT).anchor(CalderaAtlas.ISLE_OAKSHIRE_HOLM)
	var east: Vector3 = CalderaAtlas.seam(CalderaAtlas.SEAM_EEL_SPIT).anchor(CalderaAtlas.ISLE_OAKSHIRE_HOLM)
	add_path(PackedVector2Array([Vector2(360.0, 230.0), Vector2(300.0, 150.0), Vector2(220.0, 60.0), MARKET_AT]), 2.2)
	add_path(PackedVector2Array([MARKET_AT, Vector2(110.0, -120.0), Vector2(60.0, -240.0), Vector2(40.0, -330.0)]), 2.4)
	add_path(PackedVector2Array([MARKET_AT, Vector2(-40.0, 40.0), Vector2(-200.0, 90.0), Vector2(-320.0, 128.0)]), 2.0)
	add_path(PackedVector2Array([Vector2(-40.0, 40.0), Vector2(-260.0, -40.0), Vector2(-480.0, -70.0), Vector2(west.x, west.z + 12.0)]), 1.8)
	add_path(PackedVector2Array([Vector2(220.0, 60.0), WINDMILL_AT, Vector2(480.0, -20.0), Vector2(east.x, east.z + 12.0)]), 1.8)
	add_path(PackedVector2Array([Vector2(-140.0, -150.0), Vector2(-260.0, -270.0), Vector2(-290.0, -286.0)]), 1.6)
	add_path(PackedVector2Array([Vector2(-40.0, 40.0), Vector2(-140.0, -150.0)]), 1.6)
	add_place("The Lee-Shore Orchards", Vector3(ORCHARDS_AT.x, 0.0, ORCHARDS_AT.y), ORCHARDS_RADIUS)
	add_place("The Windmill", Vector3(WINDMILL_AT.x, 0.0, WINDMILL_AT.y), 40.0)
	add_place("Hearthstead Market", Vector3(MARKET_AT.x, 0.0, MARKET_AT.y), 90.0)
	add_place("The Root-Sanctum", Vector3(ROOT_SANCTUM_AT.x, 0.0, ROOT_SANCTUM_AT.y), 70.0)
	add_place("North Quay", Vector3(NORTH_QUAY_AT.x, 3.0, NORTH_QUAY_AT.y - 30.0), 80.0)
	add_place("The Old Quay Market", OLD_QUAY_AT, 50.0)
	add_place("The West Strait", west, 60.0)
	add_place("Eel Spit", east, 60.0)
	# The Level 1 start (21_WINGFEATHER_YOUTH_HERO.md §4): the foot of the orchard
	# lane among the Lee-Shore Orchards, the youth facing up it toward the
	# Windmill and Hearthstead Market.
	add_arrival(CalderaAtlas.ARRIVE_ORCHARDS, ORCHARD_ARRIVAL, ORCHARD_LANE_UP)
	add_arrival(CalderaAtlas.ARRIVE_NORTH_QUAY, Vector2(40.0, -324.0))
	add_arrival(CalderaAtlas.ARRIVE_ROOT_SANCTUM, Vector2(-330.0, 146.0))


func _coast_shape() -> Dictionary:
	return {"center": CENTER, "semi": SEMI_AXES}


func _base_height(x: float, z: float) -> float:
	var q: float = ellipse_q(x, z, CENTER, SEMI_AXES, 0.05)
	if q > 1.0:
		return sea_floor(q)
	var north: float = clampf(-(z - CENTER.y) / SEMI_AXES.y, 0.0, 1.0)
	var inland: float = 1.0 - q
	var rolling: float = 3.6 * noise(x * 1.2, z * 1.2) + 1.2 * detail(x * 0.4, z * 0.4)
	var interior: float = 3.0 + 9.0 * smoothstep(0.0, 0.55, inland) + rolling * smoothstep(0.0, 0.25, inland)
	# The lee (south) shore runs out in a long beach; the north shore stands up in low cliffs over The Sound.
	var beach: float = smoothstep(0.0, 0.1, inland)
	var cliff: float = smoothstep(0.0, 0.025, inland)
	return lerpf(-1.5, interior, lerpf(beach, cliff, smoothstep(0.3, 0.7, north)))


func _ground_color(x: float, z: float, height: float, up: float) -> Color:
	# Rich meadow greens (docs/24 §4), deep in the hollows and sunnier on the rises, never straw.
	var loam: Color = Color(0.32, 0.5, 0.22).lerp(Color(0.44, 0.58, 0.26), 0.5 + 0.5 * detail(x * 0.5, z * 0.5))
	var orchard: float = 1.0 - smoothstep(ORCHARDS_RADIUS * 0.8, ORCHARDS_RADIUS, Vector2(x - ORCHARDS_AT.x, z - ORCHARDS_AT.y).length())
	loam = loam.lerp(Color(0.38, 0.52, 0.22), orchard * 0.5)
	return shore_or(height, up, loam, Color(0.46, 0.42, 0.38))


func _scatter_species(x: float, z: float, height: float, up: float, roll: float) -> int:
	if height < 1.3:
		return Species.REED_CLUMP if height > -0.4 and z > 100.0 and roll < 0.05 else -1
	if up < 0.7:
		return Species.ROCK if roll < 0.2 else -1
	if Vector2(x - MARKET_AT.x, z - MARKET_AT.y).length() < MARKET_RADIUS + 16.0 or Vector2(x - NORTH_QUAY_AT.x, z - NORTH_QUAY_AT.y).length() < 60.0:
		return -1
	if Vector2(x - ROOT_SANCTUM_AT.x, z - ROOT_SANCTUM_AT.y).length() < 30.0 or Vector2(x - WINDMILL_AT.x, z - WINDMILL_AT.y).length() < 20.0:
		return -1
	# Weeping willows and ferns on the low ground by the shore and along the river inlets.
	if height < 3.4 and up > 0.85:
		return Species.WILLOW_TREE if roll < 0.035 else (Species.FERN_TUFT if roll < 0.07 else -1)
	if Vector2(x - ORCHARDS_AT.x, z - ORCHARDS_AT.y).length() < ORCHARDS_RADIUS:
		return Species.ORCHARD_TREE if roll < 0.32 else (Species.FERN_TUFT if roll < 0.36 else -1)
	if roll < 0.035:
		return Species.OAK_TREE
	if roll < 0.06:
		return Species.ASH_TREE
	if roll < 0.11:
		return Species.FERN_TUFT
	return Species.ROCK if roll < 0.12 else -1


func landmark_silhouette(into: LandblockTerrain.MeshMerge) -> void:
	CalderaKit.add_windmill_silhouette(into, ground(WINDMILL_AT.x, WINDMILL_AT.y))


# --- Structures ------------------------------------------------------------------------

func build_structures(root: Node3D) -> void:
	_build_orchards_and_windmill(root)
	_build_market(root)
	_build_root_sanctum(root)
	_build_north_quay(root)
	_build_old_quay_market(root)
	for seam_id: StringName in [CalderaAtlas.SEAM_WEST_STRAIT, CalderaAtlas.SEAM_EEL_SPIT]:
		CalderaCauseway.build(root, CalderaAtlas.seam(seam_id), isle.isle_id)
	_build_lantern_poles(root)


func _build_orchards_and_windmill(root: Node3D) -> void:
	var mill: WorldKitInstance = WorldKitInstance.make("Windmill", WorldVisualCatalog.KIT_WINDMILL, ground(WINDMILL_AT.x, WINDMILL_AT.y), 0.6,
		{"spin_speed": 0.5})
	mill.scale = Vector3.ONE * 2.4
	root.add_child(mill)
	CalderaKit.solid_cylinder(root, "WindmillBody", ground(WINDMILL_AT.x, WINDMILL_AT.y), 5.2, 18.0)
	CalderaKit.sign_label(root, "OrchardSign", "The Lee-Shore Orchards\nMiller's Oak · Lv 1-2", ground(320.0, 214.0) + Vector3(0.0, 2.6, 0.0))
	# The orchard's own homestead pile beside the Level 1 start: apple crates, barrels and sacks from the harvest.
	CalderaKit.lived_in_clutter(root, "OrchardHarvest", ground(ORCHARD_LANE_FOOT.x + 6.5, ORCHARD_LANE_FOOT.y - 2.5), 410, 6, 0.4, 3.0, ground, true)
	for index: int in 3:
		var at: Vector2 = [Vector2(330.0, 250.0), Vector2(470.0, 170.0), Vector2(260.0, 130.0)][index]
		var hobs: MobSpawner = MobSpawner.new()
		hobs.name = "OrchardHobs%d" % (index + 1)
		hobs.territory = "The Lee-Shore Orchards"
		var pack: Array[StringName] = [&"cider_thief_bristleboar", &"cider_thief_bristleboar"]
		if index == 2:
			pack = [&"thorn_tail_scuttler", &"cider_thief_bristleboar"]
		hobs.variant_ids = pack
		hobs.leash = 20.0
		hobs.position = ground(at.x, at.y)
		hobs.add_to_group(&"caldera_streamed_spawners")
		root.add_child(hobs)


func _build_market(root: Node3D) -> void:
	var at: Vector3 = ground(MARKET_AT.x, MARKET_AT.y)
	CalderaKit.sign_label(root, "MarketSign", "Hearthstead Market\nevery lane runs through here", at + Vector3(0.0, 3.4, 12.0))
	# Houses round the green, the Inn the biggest.
	for index: int in 8:
		var angle: float = TAU * float(index) / 8.0 + 0.2
		var spot: Vector3 = ground(at.x + cos(angle) * (MARKET_RADIUS + 6.0), at.z + sin(angle) * (MARKET_RADIUS + 6.0))
		var house: WorldKitInstance = WorldKitInstance.make("House%d" % index, WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, spot, -angle + PI * 0.5,
			{"seed_value": 20 + index})
		if index == 0:
			house.name = "Inn"
			house.scale = Vector3.ONE * 1.35
		root.add_child(house)
		CalderaKit.solid_box(root, "HouseBody%d" % index, spot + Vector3(0.0, 2.5, 0.0), Vector3(6.0, 5.0, 6.0), -angle + PI * 0.5)
		# What a family leaves about a cottage (docs/24 §5): barrels, crates, a woodpile, sacks, a flower tub.
		CalderaKit.lived_in_clutter(root, "HouseClutter%d" % index, spot, 300 + index, 5, 4.6, 6.4, ground)
	for index: int in 2:
		root.add_child(WorldKitInstance.make("Pavilion%d" % index, WorldVisualCatalog.KIT_MARKET_PAVILION,
			ground(at.x - 12.0 + index * 24.0, at.z + 10.0), 0.0))
	var folk: Array[Dictionary] = [
		{"name": "Wren Applewhite", "title": "Chime-Alchemist", "wares": TownsfolkNPC.Wares.BANKER, "note": "the Chime-Vault's upgrades", "at": Vector2(-8.0, 8.0)},
		{"name": "Harrow Coalbrook", "title": "Blacksmith", "wares": TownsfolkNPC.Wares.WEAPONS, "note": "axes, falchions, bows and staves", "at": Vector2(8.0, 8.0)},
		{"name": "Mother Hollin", "title": "Innkeeper", "wares": TownsfolkNPC.Wares.APOTHECARY, "note": "a hot meal: mended", "at": Vector2(-16.0, -6.0)},
		{"name": "Ostler Fennick", "title": "Calling Tutor", "wares": TownsfolkNPC.Wares.CALLING_TUTOR, "note": "the Secondary Callings", "at": Vector2(16.0, -6.0)},
	]
	for index: int in folk.size():
		var person: Dictionary = folk[index]
		var npc: TownsfolkNPC = TownsfolkNPC.new()
		npc.name = String(person["title"]).replace(" ", "").replace("-", "")
		npc.role = TownsfolkNPC.Role.VENDOR
		npc.npc_name = person["name"]
		npc.title = person["title"]
		npc.hub = "Hearthstead Market"
		npc.wares = person["wares"]
		npc.wares_note = person["note"]
		npc.body_color = [Color(0.52, 0.42, 0.66), Color(0.42, 0.36, 0.3), Color(0.66, 0.42, 0.32), Color(0.36, 0.5, 0.42)][index]
		npc.accent_color = CalderaKit.SAFFRON
		npc.npc_seed = 11 + index
		var spot: Vector2 = person["at"]
		npc.position = ground(at.x + spot.x, at.z + spot.y)
		root.add_child(npc)
	# The three lane stalls along the green's north side: shuttered until their Beacons burn.
	var stalls: Array[Dictionary] = [
		{"flag": CalderaWorldState.BEACON_IRON, "name": "The Iron Stall", "vendor": "Bryn Ironside", "title": "Iron-Ness smith",
			"wares": TownsfolkNPC.Wares.ARMOR, "note": "iron from Iron-Ness: Ring-Coats and Kettle-Caps", "accent": CalderaKit.IRON_AMBER},
		{"flag": CalderaWorldState.BEACON_TIDE, "name": "The Lantern Stall", "vendor": "Ellis Wickmoor", "title": "Lantern Staithe chandler",
			"wares": TownsfolkNPC.Wares.APOTHECARY, "note": "lamp-oil from Barrow-Eyot: lanterns lit, wounds mended", "accent": CalderaKit.TIDE_VIOLET},
		{"flag": CalderaWorldState.BEACON_GALE, "name": "The Provisions Stall", "vendor": "Saoirse Galebrook", "title": "Gale-Hall factor",
			"wares": TownsfolkNPC.Wares.BANKER, "note": "fuel and provisions from Rime-Firth: the Chime-Vault", "accent": CalderaKit.GALE_AZURE},
	]
	for index: int in stalls.size():
		var spec: Dictionary = stalls[index]
		var stall: TradeStall = TradeStall.new()
		stall.name = ["IronStall", "LanternStall", "ProvisionsStall"][index]
		stall.lane_flag = spec["flag"]
		stall.stall_name = spec["name"]
		stall.vendor_name = spec["vendor"]
		stall.vendor_title = spec["title"]
		stall.wares = spec["wares"]
		stall.wares_note = spec["note"]
		stall.accent = spec["accent"]
		stall.position = ground(at.x - 14.0 + index * 14.0, at.z - 22.0)
		stall.rotation.y = PI
		root.add_child(stall)


func _build_root_sanctum(root: Node3D) -> void:
	var at: Vector3 = ground(ROOT_SANCTUM_AT.x, ROOT_SANCTUM_AT.y)
	var trunk: MeshInstance3D = MeshInstance3D.new()
	trunk.name = "PetrifiedElderOak"
	trunk.mesh = ShapeKit.make_gnarled_trunk_mesh(22.0, 6.0, 2.2, 6, 77)
	trunk.material_override = StorybookMaterial.make(Color(0.6, 0.6, 0.58))
	trunk.position = at + Vector3(0.0, 0.0, -10.0)
	root.add_child(trunk)
	CalderaKit.solid_cylinder(root, "ElderOakBody", at + Vector3(0.0, 0.0, -10.0), 5.6, 12.0)
	var entrance: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_arch(entrance, at + Vector3(0.0, 0.0, -3.5), 4.0, 5.0, 0.0, Color(0.56, 0.56, 0.54))
	root.add_child(CalderaKit.mesh_node("SanctumArch", entrance))
	var portal: RaidPortal = RaidPortal.new()
	portal.name = "RootSanctumPortal"
	portal.target_instance = InstanceManager.DUNGEON_DOJO
	portal.title = "The Root-Sanctum (Lv 6): the Cairnsman's expedition"
	portal.portal_color = Color(0.62, 0.86, 0.5)
	portal.position = at + Vector3(0.0, 0.0, 2.0)
	root.add_child(portal)
	CalderaKit.sign_label(root, "SanctumSign", "The Root-Sanctum · Lv 6\nclear it, and the trade lanes go dark", at + Vector3(0.0, 6.4, 0.0))
	for index: int in 2:
		var camp: MobSpawner = MobSpawner.new()
		camp.name = "SanctumKin%d" % (index + 1)
		camp.territory = "The Root-Sanctum"
		var pack: Array[StringName] = [&"soot_paw_cutthroat", &"quarry_sling_shotter"]
		if index == 1:
			pack = [&"grey_pelt_prowler", &"river_snapper_toad"]
		camp.variant_ids = pack
		camp.leash = 22.0
		camp.position = ground([-200.0, -430.0][index], [160.0, 50.0][index])
		camp.add_to_group(&"caldera_streamed_spawners")
		root.add_child(camp)


func _build_north_quay(root: Node3D) -> void:
	var dock: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_pier(dock, PIER_ROOT, Vector3(PIER_ROOT.x, PIER_ROOT.y, PIER_HEAD_Z), 6.0, PIER_ROOT.y)
	# The pier head: a crosspiece with a berth at each end.
	CalderaKit.add_box(dock, Vector3(PIER_ROOT.x, PIER_ROOT.y - 0.2, PIER_HEAD_Z - 4.0), Vector3(36.0, 0.4, 10.0), CalderaKit.TIMBER)
	for x: float in [-17.0, -6.0, 6.0, 17.0]:
		CalderaKit.add_post(dock, Vector3(PIER_ROOT.x + x, -10.0, PIER_HEAD_Z - 8.6), 0.24, 0.28, 12.4, CalderaKit.DARK_TIMBER, 6)
	root.add_child(CalderaKit.mesh_node("NorthQuayPier", dock))
	var length: float = PIER_ROOT.z - PIER_HEAD_Z
	CalderaKit.solid_box(root, "PierDeck", Vector3(PIER_ROOT.x, PIER_ROOT.y - 0.2, (PIER_ROOT.z + PIER_HEAD_Z) * 0.5), Vector3(6.0, 0.4, length), 0.0, ActorBase.LAYER_LOW_SCENERY)
	CalderaKit.solid_box(root, "PierHead", Vector3(PIER_ROOT.x, PIER_ROOT.y - 0.2, PIER_HEAD_Z - 4.0), Vector3(36.0, 0.4, 10.0), 0.0, ActorBase.LAYER_LOW_SCENERY)
	for seam_id: StringName in [CalderaAtlas.SEAM_SALT_ROAD, CalderaAtlas.SEAM_CROWN_LANDING]:
		var seam: LoadSeamResource = CalderaAtlas.seam(seam_id)
		var berth: Vector3 = seam.anchor(isle.isle_id)
		var bell: SkiffBell = SkiffBell.new()
		bell.name = "SaltRoadBell" if seam_id == CalderaAtlas.SEAM_SALT_ROAD else "CrownLandingBell"
		bell.seam_id = seam_id
		bell.position = Vector3(berth.x, PIER_ROOT.y, PIER_HEAD_Z - 2.0)
		bell.rotation.y = PI
		root.add_child(bell)
		var skiff: LandblockTerrain.MeshMerge = CalderaKit.merge()
		CalderaKit.add_skiff(skiff)
		var moored: MeshInstance3D = CalderaKit.mesh_node("Skiff_%s" % String(seam_id).trim_prefix("seam_"), skiff)
		moored.position = berth + Vector3(0.0, -1.5, 0.0)
		root.add_child(moored)
	CalderaKit.sign_label(root, "QuaySign", "North Quay\nThe Sound: The Crown dead ahead", ground(NORTH_QUAY_AT.x - 10.0, NORTH_QUAY_AT.y) + Vector3(0.0, 2.8, 0.0))


func _build_old_quay_market(root: Node3D) -> void:
	var market: OldQuayMarket = OldQuayMarket.new()
	market.name = "OldQuayMarket"
	market.position = OLD_QUAY_AT
	root.add_child(market)


func _build_lantern_poles(root: Node3D) -> void:
	var stops: Array[Vector2] = [Vector2(300.0, 150.0), Vector2(220.0, 60.0), Vector2(110.0, -120.0), Vector2(60.0, -240.0), Vector2(-40.0, 40.0),
		Vector2(-200.0, 90.0), Vector2(-260.0, -40.0), Vector2(-480.0, -70.0), Vector2(480.0, -20.0), Vector2(-140.0, -150.0)]
	for index: int in stops.size():
		var spot: Vector3 = ground(stops[index].x + 3.5, stops[index].y)
		root.add_child(WorldKitInstance.make("LanternPole%d" % index, WorldVisualCatalog.KIT_WIND_LANTERN_POST, spot, float(index)))
