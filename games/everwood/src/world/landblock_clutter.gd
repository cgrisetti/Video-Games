## Layer 2 of a Landblock (10_WORLD_ARCHITECTURE.md §3): static clutter and
## foliage, drawn with one MultiMeshInstance3D per kind (no node per rock or
## bush) in the storybook palette: mossy river boulders, heather tufts, reed
## clumps, stepping stones down the trails, the low dry-stone walls that line
## them, and the oak canopy crowding the crags.
##
## Where everything goes is worked out from the chunk's own seed, so a chunk
## always grows back the same. Nothing is strewn inside a zone's footprint
## (the village, the clearing, the holloway, the gorge, the Ring): those are
## dressed by their landblock. The trail walls' colliders live with the
## terrain (Layer 3); these are their looks.
class_name LandblockClutter
extends RefCounted

enum Kind { BOULDER, HEATHER, REED, STEPPING_STONE, WALL, TRUNK, CANOPY, GUIDE_POST }

const KIND_NAMES: Array[String] = ["Boulders", "Heather", "Reeds", "SteppingStones", "TrailWalls", "OakTrunks", "OakCanopy", "GuidePosts"]
## How many of each a chunk tries to place: on the corridor, and on the crags.
const CORRIDOR_TRIES: Array[int] = [90, 320, 80, 0, 0, 60, 60, 0]
const CRAG_TRIES: Array[int] = [50, 200, 0, 0, 0, 160, 160, 0]
## Stepping stones every this many metres down a trail, and how far they stray from its middle.
const STONE_SPACING: float = 2.6
## The slope contract (18 GDD §3.2): low guide-posts (kit_guide_post, 0.55 m) line
## both sides of every trail where it climbs, this far apart and this far past its
## painted edge; a climb is any stretch rising more than CLIMB_GRADE.
const GUIDE_POST_SPACING: float = 4.0
const GUIDE_POST_OFFSET: float = 0.55
const CLIMB_GRADE: float = 0.01
## Crag-Crest Cornices (kit_cliff_cornice) along both crests of the corridor's impassable ridges, this far apart.
const CORNICE_SPACING: float = 5.6
const STONE_JITTER: float = 0.5
const WALL_HEIGHT: float = 0.9
const WALL_THICKNESS: float = 0.6
const BASE_COLORS: Array[Color] = [Color(0.5, 0.52, 0.46), Color(0.58, 0.38, 0.58), Color(0.56, 0.6, 0.36), Color(0.6, 0.58, 0.54),
	Color(0.56, 0.55, 0.5), Color(0.36, 0.26, 0.18), Color(0.3, 0.46, 0.26), Color(1.0, 1.0, 1.0)]
## Each colour strays this much, brighter or darker, per instance.
const COLOR_JITTER: float = 0.12


## Every instance, by kind: {"count", "buffer"} with the MultiMesh buffer packed
## here (transform rows and colour per instance), so the main thread only hands
## it over (pure, worker-thread safe).
static func build_clutter_data(chunk: Vector2i) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed(chunk)
	var placed: Dictionary = {}
	for kind: int in Kind.size():
		var transforms: Array[Transform3D] = []
		placed[kind] = {"transforms": transforms, "colors": PackedColorArray()}
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var size: float = WorldGridConfig.CHUNK_SIZE
	var tries: Array[int] = CORRIDOR_TRIES if chunk.x == 0 else CRAG_TRIES
	for kind: int in [Kind.BOULDER, Kind.HEATHER, Kind.REED, Kind.TRUNK]:
		for attempt: int in tries[kind]:
			var x: float = origin.x + rng.randf() * size
			var z: float = origin.z + rng.randf() * size
			var spot: Dictionary = _spot(x, z)
			if not _fits(kind, spot):
				continue
			var y: float = LandblockTerrain.sample_height(x, z)
			match kind:
				Kind.BOULDER:
					var scale: float = rng.randf_range(0.5, 1.6)
					_add(placed, kind, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * 1.2, scale * 0.8, scale)), Vector3(x, y + scale * 0.2, z)), rng)
				Kind.HEATHER:
					var scale: float = rng.randf_range(0.6, 1.3)
					_add(placed, kind, Transform3D(Basis.IDENTITY.scaled(Vector3(scale, scale * 0.6, scale)), Vector3(x, y + 0.08, z)), rng)
				Kind.REED:
					for blade: int in 5:
						var lean: Basis = Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(), rng.randf_range(0.05, 0.3))
						_add(placed, kind, Transform3D(lean, Vector3(x + rng.randf_range(-0.4, 0.4), y + 0.55, z + rng.randf_range(-0.4, 0.4))), rng)
				Kind.TRUNK:
					var height: float = rng.randf_range(5.0, 8.0)
					_add(placed, kind, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, height / 6.0, 1.0)), Vector3(x, y + height * 0.5 - 0.3, z)), rng)
					var crown: float = rng.randf_range(2.6, 4.2)
					_add(placed, Kind.CANOPY, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(crown * 1.15, crown * 0.8, crown)),
						Vector3(x, y + height + crown * 0.35, z)), rng)
	_add_trail_dressing(chunk, placed, rng)
	var packed: Dictionary = {}
	for kind: int in Kind.size():
		packed[kind] = _pack(placed[kind])
	# The ground's small life (17 GDD §4.3), in the biome of the zone this row belongs to.
	var middle: Vector3 = origin + Vector3(size * 0.5, 0.0, size * 0.5)
	packed["baked"] = ChunkClutterBaker.bake(chunk, WorldVisualCatalog.biome_for_music(LandblockManifest.music_profile_at(middle)), _grows_at,
		LandblockTerrain.corridor_surface_color, road_edge, LandblockTerrain.sample_height, crest_pieces(chunk))
	return packed


## Where a Crag-Crest Cornice sits along the corridor's ridges in a chunk (18 GDD §3.2):
## on each side's crest (the ridge ramp's top), jutting toward the corridor, clear of
## the zones and the gorge.
static func crest_pieces(chunk: Vector2i) -> Array[Transform3D]:
	var pieces: Array[Transform3D] = []
	if chunk.x != 0:
		return pieces
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed(chunk) ^ 0xC0C0
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var z: float = origin.z + CORNICE_SPACING * 0.5
	while z < origin.z + WorldGridConfig.CHUNK_SIZE:
		for side: float in [-1.0, 1.0]:
			if LandblockManifest.band_half_width(z, side < 0.0) <= 0.0:
				continue
			var edge: float = LandblockTerrain._floor_edge(LandblockManifest.CORRIDOR_X + side, z)
			var x: float = LandblockManifest.CORRIDOR_X + side * (edge + LandblockTerrain.RIDGE_RAMP)
			if LandblockManifest.in_footprint(x, z) or LandblockManifest.carve_bottom(x, z) < INF:
				continue
			var lean: Basis = Basis(Vector3.UP, side * PI * 0.5 + rng.randf_range(-0.08, 0.08)).scaled(Vector3(rng.randf_range(0.95, 1.15), rng.randf_range(0.85, 1.2), 1.0))
			pieces.append(Transform3D(lean, Vector3(x, LandblockTerrain.corridor_height(x, z) - 0.05, z)))
		z += CORNICE_SPACING
	return pieces


## The dirt trail's painted edge, metres from its middle (LandblockTerrain.corridor_surface_color blends it 1.6 to 2.8 m out).
const TRAIL_PAINT_EDGE: float = 2.2


## How far past the nearest trail's or lane's painted edge a spot lies (18 GDD §3.1:
## where curb-stones and verges grow; negative on it), or INF inside a zone or a carving.
static func road_edge(x: float, z: float) -> float:
	if LandblockManifest.in_footprint(x, z) or LandblockManifest.carve_bottom(x, z) < INF:
		return INF
	var best: float = INF
	if LandblockManifest.trail_at(z) != Vector3.ZERO:
		best = absf(x - LandblockManifest.CORRIDOR_X) - TRAIL_PAINT_EDGE
	return minf(best, LandblockManifest.lane_gap(x, z) - LandblockManifest.LANE_HALF_WIDTH)


## Where grass, flowers and pebbles may grow: anywhere a heather tuft could (not in a zone, a carving or on a trail).
static func _grows_at(x: float, z: float) -> float:
	if not _fits(Kind.HEATHER, _spot(x, z)):
		return NAN
	return LandblockTerrain.sample_height(x, z)


static func chunk_seed(chunk: Vector2i) -> int:
	return absi((chunk.x + 1000) * 73856093 ^ (chunk.y + 1000) * 19349663) % 2147483647


## The node holding one MultiMeshInstance3D per kind that has instances.
static func make_clutter_node(chunk: Vector2i, data: Dictionary) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Clutter_%s" % WorldGridConfig.chunk_key(chunk)
	for kind: int in Kind.size():
		var entry: Dictionary = data[kind]
		var count: int = entry["count"]
		if count == 0:
			continue
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = _mesh_for(kind)
		multimesh.instance_count = count
		multimesh.buffer = entry["buffer"]
		var instances: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instances.name = KIND_NAMES[kind]
		instances.multimesh = multimesh
		var look: Material = _material_for(kind)
		if look != null:
			instances.material_override = look
		if kind == Kind.HEATHER or kind == Kind.REED or kind == Kind.STEPPING_STONE:
			instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(instances)
	for batch: MultiMeshInstance3D in ChunkClutterBaker.make_nodes(data.get("baked", {})):
		root.add_child(batch)
	return root


## A kind's world material (17 GDD §3): crafted stone, or foliage that sways (null: the mesh's own).
static func _material_for(kind: int) -> Material:
	match kind:
		Kind.BOULDER:
			return WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.CRAG_GRANITE, WorldVisualCatalog.GRANITE, false, 0.6)
		Kind.STEPPING_STONE:
			return WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE, WorldVisualCatalog.FLAGSTONE, false, 0.3)
		Kind.WALL:
			return WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.CRAG_GRANITE, Color(0.68, 0.64, 0.57), false, 0.5)
	return null


## How many instances of each kind the data holds, the baked ground life too (tests and telemetry).
static func instance_count(data: Dictionary) -> int:
	var count: int = 0
	for kind: int in Kind.size():
		count += int(data[kind]["count"])
	return count + ChunkClutterBaker.instance_count(data.get("baked", {}))


## A kind's instances as a MultiMesh buffer: 12 floats of transform (basis
## rows with the origin last) and 4 of colour each.
static func _pack(entry: Dictionary) -> Dictionary:
	var transforms: Array[Transform3D] = entry["transforms"]
	var colors: PackedColorArray = entry["colors"]
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(transforms.size() * 16)
	for index: int in transforms.size():
		var where: Transform3D = transforms[index]
		var color: Color = colors[index]
		var values: Array[float] = [where.basis.x.x, where.basis.y.x, where.basis.z.x, where.origin.x,
			where.basis.x.y, where.basis.y.y, where.basis.z.y, where.origin.y,
			where.basis.x.z, where.basis.y.z, where.basis.z.z, where.origin.z, color.r, color.g, color.b, color.a]
		for offset: int in 16:
			buffer[index * 16 + offset] = values[offset]
	return {"count": transforms.size(), "buffer": buffer}


# --- Where things may go ------------------------------------------------------

## What the ground is like at (x, z): past the floor's edge (metres; negative
## inside), whether it's in a zone or on a trail's middle.
static func _spot(x: float, z: float) -> Dictionary:
	var dx: float = x - LandblockManifest.CORRIDOR_X
	var edge: float = LandblockManifest.band_half_width(z, dx < 0.0)
	var trail: Vector3 = LandblockManifest.trail_at(z)
	return {"past": absf(dx) - edge, "zone": LandblockManifest.in_footprint(x, z),
		"on_trail": (trail != Vector3.ZERO and absf(dx) < trail.z + LandblockTerrain.TRAIL_WALL_OFFSET + 1.0)
			or LandblockManifest.lane_gap(x, z) < LandblockManifest.LANE_HALF_WIDTH + 2.0,
		"carved": LandblockManifest.carve_bottom(x, z) < INF}


static func _fits(kind: int, spot: Dictionary) -> bool:
	if spot["zone"] or spot["carved"] or spot["on_trail"]:
		return false
	var past: float = spot["past"]
	match kind:
		Kind.BOULDER:
			return past < LandblockTerrain.RIDGE_RAMP * 0.7
		Kind.HEATHER:
			return true
		Kind.REED:
			# Reed beds in the wet foot of the crags.
			return past > -4.0 and past < 3.0
		Kind.TRUNK:
			# The oak canopy crowds the slopes and crests, never the floor.
			return past > LandblockTerrain.RIDGE_RAMP * 0.35
	return false


## Stepping stones down each trail's middle and dry-stone walls along both sides.
static func _add_trail_dressing(chunk: Vector2i, placed: Dictionary, rng: RandomNumberGenerator) -> void:
	if chunk.x != 0:
		return
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var chunk_south: float = origin.z + WorldGridConfig.CHUNK_SIZE
	for trail: Vector3 in LandblockManifest.TRAILS:
		var z: float = minf(trail.x, chunk_south) - STONE_SPACING * 0.5
		while z > maxf(trail.y, origin.z):
			var x: float = LandblockManifest.CORRIDOR_X + rng.randf_range(-STONE_JITTER, STONE_JITTER)
			var stone_z: float = z + rng.randf_range(-STONE_JITTER, STONE_JITTER) * 0.5
			var y: float = LandblockTerrain.sample_height(x, stone_z)
			var scale: float = rng.randf_range(0.8, 1.15)
			_add(placed, Kind.STEPPING_STONE, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale, 1.0, scale * 0.85)), Vector3(x, y + 0.04, stone_z)), rng)
			z -= STONE_SPACING
	# Guide-posts both sides of each trail where it climbs (Doverslap's approaches).
	for trail: Vector3 in LandblockManifest.TRAILS:
		var z: float = minf(trail.x, chunk_south) - GUIDE_POST_SPACING * 0.5
		while z > maxf(trail.y, origin.z):
			var grade: float = absf(LandblockManifest.base_height(z - 2.0) - LandblockManifest.base_height(z + 2.0)) / 4.0
			if grade > CLIMB_GRADE:
				for side: float in [-1.0, 1.0]:
					var x: float = LandblockManifest.CORRIDOR_X + side * (TRAIL_PAINT_EDGE + GUIDE_POST_OFFSET)
					_add(placed, Kind.GUIDE_POST, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(x, LandblockTerrain.sample_height(x, z) - 0.04, z)), rng)
			z -= GUIDE_POST_SPACING
	for piece: Transform3D in LandblockTerrain.trail_wall_pieces(chunk):
		var on_ground: Vector3 = piece.origin
		on_ground.y = LandblockManifest.base_height(on_ground.z) + WALL_HEIGHT * 0.5 - 0.1
		_add(placed, Kind.WALL, Transform3D(Basis.IDENTITY, on_ground), rng)


static func _add(placed: Dictionary, kind: int, where: Transform3D, rng: RandomNumberGenerator) -> void:
	var entry: Dictionary = placed[kind]
	(entry["transforms"] as Array[Transform3D]).append(where)
	var shade: float = rng.randf_range(-COLOR_JITTER, COLOR_JITTER)
	var color: Color = BASE_COLORS[kind].lightened(shade) if shade > 0.0 else BASE_COLORS[kind].darkened(-shade)
	var colors: PackedColorArray = entry["colors"]
	colors.append(color)
	entry["colors"] = colors


static func _mesh_for(kind: int) -> Mesh:
	match kind:
		Kind.GUIDE_POST:
			return WorldAssetCatalog.shared_mesh("mm_guide_post", func(parts: WorldAssetCatalog.Parts) -> void:
				WorldAssetCatalog._guide_post(parts, {}))
		Kind.HEATHER:
			return WorldAssetCatalog.clutter_mound_mesh(0.3)
		Kind.REED:
			return WorldAssetCatalog.clutter_reed_mesh()
		Kind.TRUNK:
			return WorldAssetCatalog.clutter_trunk_mesh()
		Kind.CANOPY:
			return WorldAssetCatalog.clutter_crown_mesh()
		Kind.BOULDER:
			var boulder: SphereMesh = SphereMesh.new()
			boulder.radius = 0.6
			boulder.height = 1.0
			boulder.radial_segments = 8
			boulder.rings = 5
			return boulder
		Kind.HEATHER:
			var tuft: SphereMesh = SphereMesh.new()
			tuft.radius = 0.32
			tuft.height = 0.5
			tuft.radial_segments = 6
			tuft.rings = 3
			return tuft
		Kind.REED:
			var reed: CylinderMesh = CylinderMesh.new()
			reed.top_radius = 0.01
			reed.bottom_radius = 0.035
			reed.height = 1.1
			reed.radial_segments = 4
			reed.rings = 1
			return reed
		Kind.STEPPING_STONE:
			var stone: CylinderMesh = CylinderMesh.new()
			stone.top_radius = 0.42
			stone.bottom_radius = 0.48
			stone.height = 0.12
			stone.radial_segments = 8
			stone.rings = 1
			return stone
		Kind.WALL:
			var wall: BoxMesh = BoxMesh.new()
			wall.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, LandblockTerrain.TRAIL_WALL_PIECE)
			return wall
		Kind.TRUNK:
			var trunk: CylinderMesh = CylinderMesh.new()
			trunk.top_radius = 0.3
			trunk.bottom_radius = 0.45
			trunk.height = 6.0
			trunk.radial_segments = 6
			trunk.rings = 1
			return trunk
	var canopy: SphereMesh = SphereMesh.new()
	canopy.radius = 1.0
	canopy.height = 1.6
	canopy.radial_segments = 8
	canopy.rings = 5
	return canopy
