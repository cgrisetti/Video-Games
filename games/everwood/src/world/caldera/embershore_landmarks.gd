## Embershore's landmarks and settlements (docs/27 §7): the two bridges, the
## Doverslap gatehouse and its reveal, Hearthstead's market, Scribe table and
## quay stair, Bramblebridge's watermill, wright's yard and cold smithy, the
## Elder Oak over the Root-Sanctum, Mill-Downs' windmill and the Downs Gate,
## the four chime-posts, the First-Quiet's sleepers, the coves' signs and the
## grain strips. Built once per visit by EmbershoreBuilder.build_structures.
class_name EmbershoreLandmarks
extends RefCounted

## The Doverslap Gorge Bridge: a level stone deck on three arches, 51 m over the gorge (deck 25.88 m).
const DOVERSLAP_WIDTH: float = 6.0
const DOVERSLAP_DECK: float = 0.8
## Bramblebridge's bridge: a single arch over the Bramble, its stone deck sloping down the valley to the lane.
const BRAMBLE_WIDTH: float = 4.4
const BRAMBLE_DECK: float = 0.6
## The quay stair: two flights hung on the bluff's face from Hearthstead down to North Quay's pier.
const STAIR_WIDTH: float = 2.4
const GRAIN: Color = Color(0.8, 0.68, 0.32)
const STUBBLE: Color = Color(0.56, 0.47, 0.26)
const SLEEPER_STONE: Color = Color(0.46, 0.5, 0.44)


static func build(root: Node3D, builder: EmbershoreBuilder) -> void:
	_build_bramblebridge(root, builder)
	_build_moss_oaks(root, builder)
	_build_doverslap(root, builder)
	_build_hearthstead(root, builder)
	_build_quay_stair(root, builder)
	_build_mill_downs(root, builder)
	_build_coast(root, builder)
	_build_sleepers(root, builder)
	_build_grain(root, builder)


# --- Bramblebridge -------------------------------------------------------------------------

static func _build_bramblebridge(root: Node3D, builder: EmbershoreBuilder) -> void:
	# The stone bridge: from the lane's first point over the Bramble to the Downs road's last, one arch over the water.
	var lane: PackedVector3Array = builder.road_points("lane")
	var downs: PackedVector3Array = builder.road_points("downs")
	if lane.size() > 0 and downs.size() > 0:
		var a: Vector3 = lane[0]
		var b: Vector3 = downs[downs.size() - 1]
		_stone_bridge(root, builder, "Bramblebridge", a, b, BRAMBLE_WIDTH, BRAMBLE_DECK, 1, "bramble")
		CalderaKit.sign_label(root, "BridgeSign", "Bramblebridge\nthe stone bridge over the Bramble", (a + b) * 0.5 + Vector3(3.5, 2.8, 0.0))
	# The watermill on the race: a stepped-gable mill house and its undershot wheel in the leat.
	var mill: Vector3 = builder.landmark(&"bramblebridge_watermill")
	var race: PackedVector2Array = builder.points_of("mill_race")
	if mill != Vector3.ZERO and race.size() >= 2:
		var foot: Vector3 = builder.ground(mill.x, mill.z)
		# The race's nearest point to the mill, and the leat's direction there.
		var best: int = 0
		for index: int in race.size() - 1:
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2(mill.x, mill.z), race[index], race[index + 1])
			if closest.distance_to(Vector2(mill.x, mill.z)) < Geometry2D.get_closest_point_to_segment(Vector2(mill.x, mill.z), race[best], race[best + 1]).distance_to(Vector2(mill.x, mill.z)):
				best = index
		var on_race: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2(mill.x, mill.z), race[best], race[best + 1])
		var along: Vector2 = (race[best + 1] - race[best]).normalized()
		var toward_race: Vector2 = (on_race - Vector2(mill.x, mill.z)).normalized()
		var house: WorldKitInstance = WorldKitInstance.make("Watermill", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, foot, atan2(toward_race.x, toward_race.y),
			{&"size": Vector3(7.0, 6.0, 6.0), &"tint": Color(0.5, 0.42, 0.34), &"seed_value": 41})
		root.add_child(house)
		CalderaKit.solid_box(root, "WatermillBody", foot + Vector3(0.0, 3.0, 0.0), Vector3(7.0, 6.0, 6.0), atan2(toward_race.x, toward_race.y))
		var wheel_foot: Vector3 = builder.ground(on_race.x, on_race.y)
		var wheel: WatermillWheel = WatermillWheel.new()
		wheel.name = "MillWheel"
		wheel.position = Vector3(on_race.x, wheel_foot.y + WatermillWheel.RADIUS - 0.25, on_race.y)
		# Its axle lies across the leat: tilt the wheel on its side, then turn it to the race's line.
		var axle: Vector2 = Vector2(-along.y, along.x)
		wheel.rotation = Vector3(PI * 0.5, atan2(axle.x, axle.y), 0.0)
		root.add_child(wheel)
		var watch: WheelWatch = WheelWatch.new()
		watch.name = "WheelWatch"
		watch.wheel = wheel
		watch.mill_at = foot
		root.add_child(watch)
		AudioDirector.attach_ambience(wheel, &"water_trickle", Vector3.ZERO, -3.0)
		CalderaKit.sign_label(root, "MillSign", "The Watermill\nits wheel turns while the weir runs free", foot + Vector3(0.0, 7.2, 0.0))
	# The wright's yard: sawn timber and the makings of carts.
	var yard: Vector3 = builder.landmark(&"wrights_yard")
	if yard != Vector3.ZERO:
		var foot: Vector3 = builder.ground(yard.x, yard.z)
		var timber: LandblockTerrain.MeshMerge = CalderaKit.merge()
		for index: int in 3:
			for layer: int in 3 - index:
				CalderaKit.add_box(timber, foot + Vector3(-3.0 + index * 1.0, 0.25 + layer * 0.5, -2.0 + index * 2.6), Vector3(0.4, 0.4, 5.0 - index * 0.8), CalderaKit.TIMBER.lightened(0.08 * float(layer)), 0.3)
		CalderaKit.add_box(timber, foot + Vector3(3.2, 0.5, 0.0), Vector3(1.6, 1.0, 2.6), CalderaKit.DARK_TIMBER, 0.0)
		for side: float in [-1.0, 1.0]:
			CalderaKit.add_post(timber, foot + Vector3(3.2 + side * 1.6, 0.0, 1.4), 0.9, 0.9, 0.14, CalderaKit.DARK_TIMBER, 10)
		root.add_child(CalderaKit.mesh_node("WrightsYard", timber))
		CalderaKit.solid_box(root, "WrightsBench", foot + Vector3(3.2, 0.5, 0.0), Vector3(1.6, 1.0, 2.6), 0.0, ActorBase.LAYER_LOW_SCENERY)
		CalderaKit.lived_in_clutter(root, "WrightsClutter", foot, 77, 6, 2.0, 5.5, builder.ground)
		CalderaKit.sign_label(root, "WrightSign", "The Wright's Yard\ncarts and wheels, when there's timber", foot + Vector3(0.0, 2.6, 0.0))
	# The cold smithy: its hearth out since the Hush.
	var smithy: Vector3 = builder.landmark(&"cold_smithy")
	if smithy != Vector3.ZERO:
		var foot: Vector3 = builder.ground(smithy.x, smithy.z)
		var yaw: float = atan2(EmbershoreBuilder.BRAMBLEBRIDGE_AT.x - smithy.x, EmbershoreBuilder.BRAMBLEBRIDGE_AT.y - smithy.z)
		root.add_child(WorldKitInstance.make("ColdSmithy", WorldVisualCatalog.KIT_HOUSE_STEPPED_GABLE, foot, yaw,
			{&"size": Vector3(5.5, 4.2, 5.0), &"tint": Color(0.36, 0.34, 0.33), &"seed_value": 43}))
		CalderaKit.solid_box(root, "SmithyBody", foot + Vector3(0.0, 2.1, 0.0), Vector3(5.5, 4.2, 5.0), yaw)
		var forge: LandblockTerrain.MeshMerge = CalderaKit.merge()
		var front: Vector3 = foot + Vector3(sin(yaw), 0.0, cos(yaw)) * 4.2
		CalderaKit.add_box(forge, front + Vector3(0.0, 0.45, 0.0), Vector3(1.4, 0.9, 1.0), CalderaKit.DARK_STONE, yaw)
		CalderaKit.add_box(forge, front + Vector3(cos(yaw), 0.0, -sin(yaw)) * 1.6 + Vector3(0.0, 0.5, 0.0), Vector3(0.9, 0.45, 0.4), CalderaKit.BASALT, yaw)
		root.add_child(CalderaKit.mesh_node("ColdForge", forge))
		CalderaKit.solid_box(root, "ColdForgeBody", front + Vector3(0.0, 0.45, 0.0), Vector3(1.4, 0.9, 1.0), yaw, ActorBase.LAYER_LOW_SCENERY)
		CalderaKit.sign_label(root, "SmithySign", "The Cold Smithy\nno fire since the trade lanes went quiet", foot + Vector3(0.0, 5.4, 0.0))


# --- The Moss-Oaks and the Elder Oak ----------------------------------------------------------

static func _build_moss_oaks(root: Node3D, builder: EmbershoreBuilder) -> void:
	_chime_post(root, builder, "MossOaksChimePost", &"moss_oaks_chimepost", "Moss-Oak Hollow")
	var oak: Vector3 = builder.landmark(&"elder_oak")
	if oak != Vector3.ZERO:
		var foot: Vector3 = builder.ground(oak.x, oak.z)
		var elder: WorldKitInstance = WorldKitInstance.make("ElderOak", WorldVisualCatalog.KIT_TREE_MOSS_OAK, foot, 0.4, {&"height": 30.0, &"seed_value": 7, &"fade": false})
		root.add_child(elder)
		CalderaKit.solid_cylinder(root, "ElderOakTrunk", foot, 2.4, 9.0)
		CalderaKit.sign_label(root, "ElderOakSign", "The Elder Oak\nits roots hold the Root-Sanctum, and choke the weir", foot + Vector3(0.0, 5.0, 4.0))
	var sanctum: Vector3 = builder.landmark(&"root_sanctum_entrance")
	if sanctum != Vector3.ZERO and oak != Vector3.ZERO:
		var foot: Vector3 = builder.ground(sanctum.x, sanctum.z)
		var toward_oak: Vector2 = Vector2(oak.x - sanctum.x, oak.z - sanctum.z).normalized()
		var yaw: float = atan2(-toward_oak.y, toward_oak.x)
		var arch: LandblockTerrain.MeshMerge = CalderaKit.merge()
		CalderaKit.add_arch(arch, foot - Vector3(toward_oak.x, 0.0, toward_oak.y) * 2.5, 4.2, 5.2, yaw, Color(0.5, 0.46, 0.4))
		# The oak's roots over the arch, reaching down from the tree.
		for index: int in 6:
			var spread: float = -1.0 + 0.4 * float(index)
			var top: Vector3 = foot + Vector3(toward_oak.x, 0.0, toward_oak.y) * 6.0 + Vector3(-toward_oak.y, 0.0, toward_oak.x) * spread * 2.0 + Vector3(0.0, 5.5, 0.0)
			var tip: Vector3 = foot - Vector3(toward_oak.x, 0.0, toward_oak.y) * 2.0 + Vector3(-toward_oak.y, 0.0, toward_oak.x) * spread * 3.2 + Vector3(0.0, 2.6 + 0.8 * float(index % 2), 0.0)
			CalderaKit.add_beam(arch, top, tip, 0.45 - 0.04 * float(index % 3), CalderaKit.DARK_TIMBER.lightened(0.05 * float(index % 2)))
		root.add_child(CalderaKit.mesh_node("SanctumArch", arch))


# --- Doverslap -----------------------------------------------------------------------------------

static func _build_doverslap(root: Node3D, builder: EmbershoreBuilder) -> void:
	var south: Vector3 = builder.landmark(&"doverslap_bridge_south")
	var north: Vector3 = builder.landmark(&"doverslap_bridge_north")
	if south != Vector3.ZERO and north != Vector3.ZERO:
		_stone_bridge(root, builder, "DoverslapBridge", south, north, DOVERSLAP_WIDTH, DOVERSLAP_DECK, 3, "dover")
		CalderaKit.sign_label(root, "DoverslapSign", "Doverslap Gorge Bridge\nthree arches over the Dover; the Sound opens to the north", south + Vector3(4.2, 3.0, -4.0))
		var reveal: DoverslapReveal = DoverslapReveal.new()
		reveal.name = "DoverslapReveal"
		var middle: Vector3 = (south + north) * 0.5
		reveal.position = middle
		var crown: Vector3 = CalderaAtlas.offset_between(builder.isle.isle_id, CalderaAtlas.ISLE_THE_CROWN)
		reveal.look_at_point = crown + Vector3(0.0, 60.0, 0.0)
		root.add_child(reveal)
	var gatehouse: Vector3 = builder.landmark(&"doverslap_gatehouse")
	var gate_road: PackedVector3Array = builder.road_points("gate")
	if gatehouse != Vector3.ZERO and gate_road.size() >= 2:
		var foot: Vector3 = builder.ground(gatehouse.x, gatehouse.z)
		var last: Vector3 = gate_road[gate_road.size() - 1]
		var before: Vector3 = gate_road[gate_road.size() - 2]
		var along: Vector2 = Vector2(last.x - before.x, last.z - before.z).normalized()
		var across: Vector2 = Vector2(-along.y, along.x)
		var yaw: float = atan2(-across.y, across.x)
		var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
		# The arch over the road, and a squat tower either side with a timber hoarding on top.
		CalderaKit.add_arch(stone, foot, 5.0, 6.0, yaw, CalderaKit.STONE.darkened(0.12))
		for side: float in [-1.0, 1.0]:
			var tower: Vector3 = foot + Vector3(across.x, 0.0, across.y) * side * 5.2
			var tower_foot: Vector3 = builder.ground(tower.x, tower.z)
			CalderaKit.add_box(stone, tower_foot + Vector3(0.0, 4.0, 0.0), Vector3(4.2, 8.0, 4.2), CalderaKit.STONE.darkened(0.08), atan2(along.x, along.y))
			CalderaKit.add_box(stone, tower_foot + Vector3(0.0, 8.6, 0.0), Vector3(4.8, 1.2, 4.8), CalderaKit.DARK_TIMBER, atan2(along.x, along.y))
			for corner: int in 4:
				var angle: float = atan2(along.x, along.y) + PI * 0.25 + PI * 0.5 * float(corner)
				CalderaKit.add_box(stone, tower_foot + Vector3(sin(angle) * 2.6, 9.6, cos(angle) * 2.6), Vector3(0.7, 0.8, 0.7), CalderaKit.DARK_STONE, atan2(along.x, along.y))
			CalderaKit.solid_box(root, "GatehouseTower%s" % ("W" if side < 0.0 else "E"), tower_foot + Vector3(0.0, 4.0, 0.0), Vector3(4.2, 8.0, 4.2), atan2(along.x, along.y))
		root.add_child(CalderaKit.mesh_node("Gatehouse", stone))
		CalderaKit.light(root, "GatehouseLamp", foot + Vector3(0.0, 5.2, 0.0), CalderaKit.SAFFRON, 1.4, 10.0)
		AudioDirector.attach_ambience(root, &"hearth_fire", foot + Vector3(across.x, 0.0, across.y) * 5.2 + Vector3(0.0, 2.0, 0.0), -8.0)
		CalderaKit.sign_label(root, "GatehouseSign", "The Doverslap Gatehouse\nthe Coast Road begins; Hearthstead lies west", foot + Vector3(0.0, 7.6, 0.0))
	_chime_post(root, builder, "DoverslapChimePost", &"doverslap_chimepost", "Doverslap Bridge")


# --- Hearthstead ----------------------------------------------------------------------------------

static func _build_hearthstead(root: Node3D, builder: EmbershoreBuilder) -> void:
	var market: Vector3 = builder.landmark(&"hearthstead_market")
	if market != Vector3.ZERO:
		var at: Vector3 = builder.ground(market.x, market.z)
		for index: int in 2:
			root.add_child(WorldKitInstance.make("Pavilion%d" % index, WorldVisualCatalog.KIT_MARKET_PAVILION,
				builder.ground(at.x - 11.0 + index * 22.0, at.z + 9.0), 0.0))
		var folk: Array[Dictionary] = [
			{"name": "Wren Applewhite", "title": "Chime-Alchemist", "wares": TownsfolkNPC.Wares.BANKER, "note": "the Chime-Vault's upgrades", "at": Vector2(-7.0, 7.0)},
			{"name": "Harrow Coalbrook", "title": "Blacksmith", "wares": TownsfolkNPC.Wares.WEAPONS, "note": "axes, falchions, bows and staves", "at": Vector2(7.0, 7.0)},
			{"name": "Mother Hollin", "title": "Innkeeper", "wares": TownsfolkNPC.Wares.APOTHECARY, "note": "a hot meal: mended", "at": Vector2(-13.0, -5.0)},
			{"name": "Ostler Fennick", "title": "Calling Tutor", "wares": TownsfolkNPC.Wares.CALLING_TUTOR, "note": "the Secondary Callings", "at": Vector2(13.0, -5.0)},
		]
		for index: int in folk.size():
			var person: Dictionary = folk[index]
			var npc: TownsfolkNPC = TownsfolkNPC.new()
			npc.name = String(person["title"]).replace(" ", "").replace("-", "")
			npc.role = TownsfolkNPC.Role.VENDOR
			npc.npc_name = person["name"]
			npc.title = person["title"]
			npc.hub = "Hearthstead"
			npc.wares = person["wares"]
			npc.wares_note = person["note"]
			npc.body_color = [Color(0.52, 0.42, 0.66), Color(0.42, 0.36, 0.3), Color(0.66, 0.42, 0.32), Color(0.36, 0.5, 0.42)][index]
			npc.accent_color = CalderaKit.SAFFRON
			npc.npc_seed = 11 + index
			var spot: Vector2 = person["at"]
			npc.position = builder.ground(at.x + spot.x, at.z + spot.y)
			root.add_child(npc)
		AudioDirector.attach_ambience(root, &"hearth_fire", at + Vector3(-11.0, 1.2, 9.0), -6.0)
	# The Scribe table on its terrace above the square, facing it.
	var table: Vector3 = builder.landmark(&"hearthstead_scribe_table")
	if table != Vector3.ZERO and market != Vector3.ZERO:
		var foot: Vector3 = builder.ground(table.x, table.z)
		var scribery: ScriberyStation = ScriberyStation.new()
		scribery.name = "ScribeTable"
		scribery.position = foot
		var toward: Vector2 = Vector2(market.x - table.x, market.z - table.z).normalized()
		scribery.rotation.y = atan2(-toward.x, -toward.y)
		root.add_child(scribery)
	_chime_post(root, builder, "HearthsteadChimePost", &"hearthstead_chimepost", "Oakshire-Wick")


## The timber stair down Hearthstead's bluff to North Quay: two flights hung on the face, a landing at the pier's root.
static func _build_quay_stair(root: Node3D, builder: EmbershoreBuilder) -> void:
	var pier: Vector3 = EmbershoreBuilder.PIER_ROOT
	var deck: float = EmbershoreBuilder.PIER_DECK
	var top: Vector3 = builder.ground(pier.x - 15.5, pier.z + 3.7)
	var turn_high: Vector3 = Vector3(pier.x + 12.5, (top.y + deck) * 0.5 + 0.4, pier.z + 2.7)
	var turn_low: Vector3 = Vector3(pier.x + 12.5, (top.y + deck) * 0.5 - 0.4, pier.z + 1.7)
	var bottom: Vector3 = Vector3(pier.x - 15.5, deck, pier.z + 0.6)
	var timber: LandblockTerrain.MeshMerge = CalderaKit.merge()
	var flights: Array[Array] = [[top, turn_high], [turn_low, bottom]]
	for index: int in flights.size():
		var a: Vector3 = flights[index][0]
		var b: Vector3 = flights[index][1]
		CalderaKit.add_slab(timber, a, b, STAIR_WIDTH, 0.4, CalderaKit.TIMBER)
		CalderaKit.solid_slab(root, "QuayStairFlight%d" % (index + 1), a, b, STAIR_WIDTH, 0.4)
		# Treads, handrails and posts down to the rock.
		var steps: int = int(a.distance_to(b) / 1.2)
		for step: int in steps:
			var at: Vector3 = a.lerp(b, (float(step) + 0.5) / float(steps))
			CalderaKit.add_box(timber, at + Vector3(0.0, 0.08, 0.0), Vector3(STAIR_WIDTH, 0.12, 0.5), CalderaKit.DARK_TIMBER)
		for post: int in range(0, 5):
			var at: Vector3 = a.lerp(b, float(post) / 4.0)
			for side: float in [-1.0, 1.0]:
				var rail_foot: Vector3 = at + Vector3(0.0, 0.0, side * STAIR_WIDTH * 0.5)
				CalderaKit.add_post(timber, rail_foot, 0.07, 0.09, 1.0, CalderaKit.DARK_TIMBER, 5)
				var rock: float = builder.height_at(rail_foot.x, rail_foot.z)
				if rail_foot.y - rock > 0.6 and rail_foot.y - rock < 18.0:
					CalderaKit.add_post(timber, Vector3(rail_foot.x, rock - 0.4, rail_foot.z), 0.14, 0.18, rail_foot.y - rock + 0.4, CalderaKit.DARK_TIMBER, 6)
		for side: float in [-1.0, 1.0]:
			CalderaKit.add_beam(timber, a + Vector3(0.0, 1.0, side * STAIR_WIDTH * 0.5), b + Vector3(0.0, 1.0, side * STAIR_WIDTH * 0.5), 0.1, CalderaKit.TIMBER)
	# The turn's landing and the landing along the pier's root.
	var landing: Vector3 = Vector3(pier.x + 13.6, turn_high.y - 0.2, pier.z + 2.2)
	CalderaKit.add_box(timber, landing, Vector3(3.2, 0.4, 3.2), CalderaKit.TIMBER)
	CalderaKit.solid_box(root, "QuayStairTurn", landing, Vector3(3.2, 0.4, 3.2), 0.0, ActorBase.LAYER_LOW_SCENERY)
	var quay: Vector3 = Vector3(pier.x - 8.0, deck - 0.2, pier.z + 0.3)
	CalderaKit.add_box(timber, quay, Vector3(18.0, 0.4, 3.0), CalderaKit.TIMBER)
	CalderaKit.solid_box(root, "QuayLanding", quay, Vector3(18.0, 0.4, 3.0), 0.0, ActorBase.LAYER_LOW_SCENERY)
	root.add_child(CalderaKit.mesh_node("QuayStair", timber))
	CalderaKit.sign_label(root, "QuayStairSign", "The Quay Stair\ndown the bluff to North Quay", top + Vector3(0.0, 2.4, 0.0))


# --- Mill-Downs -----------------------------------------------------------------------------------

static func _build_mill_downs(root: Node3D, builder: EmbershoreBuilder) -> void:
	var mill: Vector3 = builder.landmark(&"mill_downs_windmill")
	if mill != Vector3.ZERO:
		var foot: Vector3 = builder.ground(mill.x, mill.z)
		var windmill: WorldKitInstance = WorldKitInstance.make("Windmill", WorldVisualCatalog.KIT_WINDMILL, foot, 0.6, {&"spin_speed": 0.5})
		windmill.scale = Vector3.ONE * 2.4
		root.add_child(windmill)
		CalderaKit.solid_cylinder(root, "WindmillBody", foot, 5.2, 18.0)
		CalderaKit.sign_label(root, "WindmillSign", "The Mill-Downs Windmill\nseen from every isle of the Sound", foot + Vector3(0.0, 4.0, 7.0))
	var gate_at: Vector3 = builder.landmark(&"downs_gate")
	var downs: PackedVector3Array = builder.road_points("downs")
	if gate_at != Vector3.ZERO and downs.size() >= 2:
		var foot: Vector3 = builder.ground(gate_at.x, gate_at.z)
		# The road's line through the gate: the Downs road runs from Hearthstead (its start) south to Bramblebridge.
		var nearest: int = 1
		for index: int in downs.size():
			if Vector2(downs[index].x, downs[index].z).distance_to(Vector2(gate_at.x, gate_at.z)) < Vector2(downs[nearest].x, downs[nearest].z).distance_to(Vector2(gate_at.x, gate_at.z)):
				nearest = index
		var before: Vector3 = downs[maxi(nearest - 1, 0)]
		var after: Vector3 = downs[mini(nearest + 1, downs.size() - 1)]
		var toward_hearthstead: Vector2 = Vector2(before.x - after.x, before.z - after.z).normalized()
		var gate: OneWayGate = OneWayGate.new()
		gate.name = "DownsGate"
		gate.flag = CalderaWorldState.DOWNS_GATE_OPEN
		gate.width = 6.0
		gate.closed_line = "The Downs Gate\nbarred from Mill-Downs: it opens from the Hearthstead side"
		gate.open_line = "The Downs Gate\nopen: the Downs road runs on to Bramblebridge"
		gate.position = foot
		gate.rotation.y = atan2(toward_hearthstead.x, toward_hearthstead.y)
		root.add_child(gate)


# --- The Coast Road, the sleepers and the fields ------------------------------------------------

static func _build_coast(root: Node3D, builder: EmbershoreBuilder) -> void:
	var coves: Dictionary[StringName, String] = {&"seal_cove": "Seal Cove\nshingle and the seals' rocks", &"sunward_cove": "Sunward Cove\npale sand facing the morning",
		&"eel_junction": "The Eel Junction\nEel Spit lies east, Hearthstead west"}
	for key: StringName in coves:
		var at: Vector3 = builder.landmark(key)
		if at == Vector3.ZERO:
			continue
		var foot: Vector3 = builder.ground(at.x, at.z)
		CalderaKit.sign_label(root, "%sSign" % String(key).to_pascal_case(), coves[key], foot + Vector3(0.0, 2.4, 0.0))
		if key != &"eel_junction":
			var rocks: LandblockTerrain.MeshMerge = CalderaKit.merge()
			for index: int in 5:
				var angle: float = 0.9 * float(index)
				var rock_at: Vector3 = builder.ground(at.x + cos(angle) * (9.0 + 3.0 * float(index % 2)), at.z + sin(angle) * 7.0)
				CalderaKit.add_sphere(rocks, rock_at + Vector3(0.0, 0.2, 0.0), 1.1 + 0.3 * float(index % 3), CalderaKit.DARK_STONE.lightened(0.06 * float(index % 2)), 0.6, 7)
			root.add_child(CalderaKit.mesh_node("%sRocks" % String(key).to_pascal_case(), rocks))


## The First-Quiet's six sleepers: great mossy figures curled asleep on the south-east crags, scenery only.
static func _build_sleepers(root: Node3D, builder: EmbershoreBuilder) -> void:
	var spots: PackedVector2Array = builder.points_of("first_quiet_sleepers")
	for index: int in spots.size():
		var foot: Vector3 = builder.ground(spots[index].x, spots[index].y)
		var sleeper: MeshInstance3D = MeshInstance3D.new()
		sleeper.name = "Sleeper%d" % (index + 1)
		sleeper.mesh = ShapeKit.make_sculpted_megalith(Vector3(5.0, 2.8, 8.5), 300 + index)
		sleeper.material_override = StorybookMaterial.make(SLEEPER_STONE.darkened(0.05 * float(index % 3)))
		sleeper.position = foot + Vector3(0.0, 1.0, 0.0)
		sleeper.rotation = Vector3(0.0, 0.7 * float(index), 0.0)
		root.add_child(sleeper)
		CalderaKit.solid_box(root, "SleeperBody%d" % (index + 1), foot + Vector3(0.0, 1.3, 0.0), Vector3(4.6, 2.6, 8.0), 0.7 * float(index))
	if spots.size() > 0:
		var middle: Vector3 = builder.ground(spots[0].x, spots[0].y)
		CalderaKit.sign_label(root, "SleepersSign", "The First-Quiet\nsix sleepers, not to be woken", middle + Vector3(0.0, 4.2, 0.0))


## The grain strips: each generator row a ripe strip of corn, no collision.
static func _build_grain(root: Node3D, builder: EmbershoreBuilder) -> void:
	var rows: Array = builder.features.get("grain_field_rows", [])
	if rows.is_empty():
		return
	var corn: LandblockTerrain.MeshMerge = CalderaKit.merge()
	for index: int in rows.size():
		var row: Array = rows[index]
		var a: Vector2 = EmbershoreBuilder.to_local(Vector2(float(row[0][0]), float(row[0][1])))
		var b: Vector2 = EmbershoreBuilder.to_local(Vector2(float(row[1][0]), float(row[1][1])))
		var ga: Vector3 = builder.ground(a.x, a.y)
		var gb: Vector3 = builder.ground(b.x, b.y)
		if ga.y < 1.0 or gb.y < 1.0:
			continue
		CalderaKit.add_slab(corn, ga + Vector3(0.0, 0.95, 0.0), gb + Vector3(0.0, 0.95, 0.0), 0.8, 0.9, GRAIN.lightened(0.04 * float(index % 3)))
		CalderaKit.add_slab(corn, ga + Vector3(0.0, 0.12, 0.0), gb + Vector3(0.0, 0.12, 0.0), 1.1, 0.12, STUBBLE)
	root.add_child(CalderaKit.mesh_node("GrainStrips", corn))


# --- Shared pieces ------------------------------------------------------------------------------------

## A stone bridge from `a` to `b` (its deck's top through both): the deck and parapets, `arches` arches with
## piers between them down to the ground, and no pier in the river.
static func _stone_bridge(root: Node3D, builder: EmbershoreBuilder, node_name: String, a: Vector3, b: Vector3, width: float, deck: float,
		arches: int, river_name: String) -> void:
	var stone: LandblockTerrain.MeshMerge = CalderaKit.merge()
	CalderaKit.add_slab(stone, a, b, width, deck, CalderaKit.STONE)
	CalderaKit.solid_slab(root, "%sDeck" % node_name, a, b, width, deck)
	var length: float = a.distance_to(b)
	var forward: Vector3 = (b - a) / length
	var across: Vector3 = Vector3(forward.z, 0.0, -forward.x).normalized()
	for side: float in [-1.0, 1.0]:
		var edge: Vector3 = across * side * (width * 0.5 - 0.2)
		CalderaKit.add_slab(stone, a + edge + Vector3(0.0, 1.0, 0.0), b + edge + Vector3(0.0, 1.0, 0.0), 0.4, 1.0, CalderaKit.STONE.darkened(0.06))
		CalderaKit.solid_slab(root, "%sParapet%s" % [node_name, "L" if side < 0.0 else "R"], a + edge + Vector3(0.0, 1.0, 0.0), b + edge + Vector3(0.0, 1.0, 0.0), 0.4, 1.0, ActorBase.LAYER_WORLD)
	var yaw: float = atan2(across.x, -across.z)
	# Where the river crosses under: the arch (or the middle arch) goes there.
	var river: Array[PackedFloat32Array] = builder.river_points(river_name)
	var crossing: float = 0.5
	var best: float = INF
	for point: PackedFloat32Array in river:
		var at: Vector3 = Vector3(point[0], 0.0, point[1])
		var t: float = clampf((at - Vector3(a.x, 0.0, a.z)).dot(Vector3(forward.x, 0.0, forward.z).normalized()) / length, 0.05, 0.95)
		var on_line: Vector3 = Vector3(a.x, 0.0, a.z) + Vector3(forward.x, 0.0, forward.z).normalized() * t * length
		var gap: float = on_line.distance_to(at)
		if gap < best:
			best = gap
			crossing = t
	var arch_width: float = minf(10.0, length / float(arches) * 0.7)
	for index: int in arches:
		var t: float = crossing + (float(index) - float(arches - 1) * 0.5) * (arch_width + 2.4) / length
		var on_deck: Vector3 = a.lerp(b, clampf(t, 0.05, 0.95))
		var foot_y: float = builder.height_at(on_deck.x, on_deck.z)
		var foot: Vector3 = Vector3(on_deck.x, minf(foot_y, on_deck.y - deck - 1.0), on_deck.z)
		var height: float = on_deck.y - deck - foot.y - 0.3
		if height > arch_width * 0.5 + 0.5:
			CalderaKit.add_arch(stone, foot, arch_width, height, yaw, CalderaKit.STONE.darkened(0.1))
	# Piers under the approaches, every 9 m, where the deck stands clear of the ground.
	var piers: int = int(length / 9.0)
	for index: int in range(1, piers):
		var t: float = float(index) / float(piers)
		if absf(t - crossing) < (arch_width * float(arches) * 0.5 + 2.0) / length:
			continue
		var on_deck: Vector3 = a.lerp(b, t)
		var ground_y: float = builder.height_at(on_deck.x, on_deck.z)
		var drop: float = on_deck.y - deck - ground_y
		if drop > 0.6:
			CalderaKit.add_box(stone, Vector3(on_deck.x, ground_y - 0.3 + (drop + 0.3) * 0.5, on_deck.z), Vector3(width - 0.6, drop + 0.3, 1.6), CalderaKit.STONE.darkened(0.1), yaw)
	root.add_child(CalderaKit.mesh_node(node_name, stone))


static func _chime_post(root: Node3D, builder: EmbershoreBuilder, node_name: String, key: StringName, place: String) -> void:
	var at: Vector3 = builder.landmark(key)
	if at == Vector3.ZERO:
		return
	var post: ChimePost = ChimePost.new()
	post.name = node_name
	post.place = place
	post.checkpoint = true
	post.position = builder.ground(at.x, at.z)
	root.add_child(post)


## Watches the mill-wheel (docs/27 §9): it stops when a party of Lv 5 or more comes back to the mill (the Elder
## Oak's roots have choked the weir) and turns again once the Root-Sanctum is cleared. The host decides; everyone
## sees the flag.
class WheelWatch:
	extends Node

	const STOP_LEVEL: int = 5
	## A party member this near the mill, at the level, stops the wheel.
	const REACH: float = 60.0

	var wheel: WatermillWheel
	var mill_at: Vector3 = Vector3.ZERO

	func _ready() -> void:
		if CalderaWorldState.current != null:
			CalderaWorldState.current.flag_changed.connect(_on_flag_changed)
		_refresh()

	func _exit_tree() -> void:
		if CalderaWorldState.current != null and CalderaWorldState.current.flag_changed.is_connected(_on_flag_changed):
			CalderaWorldState.current.flag_changed.disconnect(_on_flag_changed)

	func _physics_process(_delta: float) -> void:
		var state: CalderaWorldState = CalderaWorldState.current
		if state == null or state.wheel_stopped or state.root_sanctum_cleared:
			return
		if EnemyNameplate.party_level() < STOP_LEVEL or CombatDirector.current == null:
			return
		for member: ActorBase in CombatDirector.current.party_actors():
			if member.global_position.distance_to(mill_at) <= REACH:
				state.set_flag(CalderaWorldState.WHEEL_STOPPED, true)
				return

	func _on_flag_changed(_flag: StringName, _value: bool) -> void:
		_refresh()

	func _refresh() -> void:
		var state: CalderaWorldState = CalderaWorldState.current
		if wheel != null and state != null:
			wheel.turning = not state.wheel_stopped or state.root_sanctum_cleared
