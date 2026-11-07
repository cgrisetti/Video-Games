## The ground's small life, per landblock (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4.3,
## 18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §3.1, §4.2): five
## MultiMeshInstance3D batches on the clutter ring, one draw call each (two for
## the verges), no colliders, nothing ticking on the CPU:
##   mm_grass_clumps       lush tufts of 7 to 9 arched blades (2,500 to 3,600 a
##                         landblock in a window, 600 headless), their roots the
##                         ground's own colour, bending in the rolling wind-waves
##                         and parting round heroes within 1.2 m
##   mm_wildflowers_ferns  the biome's blooms in grounded clusters (white daisies
##                         and golden buttercups with fern fronds and a mossy
##                         stone in the Greens, ferns and rush-reeds in the
##                         Hollows, heather on the Crags), tucked along verges too
##   mm_pebbles_fungi      mossy river cobbles, shelf mushrooms and fallen twigs
##   mm_road_curbs         intermittent half-buried mossy limestone curb-stones
##                         along a road's edge (the splat's w = 0.45 contour)
##   mm_verge_clumps       dense fern, plantain and white-clover clumps
##                         overhanging that edge, so a road's silhouette is as
##                         organic as its blend
##   mm_cliff_cornices     Crag-Crest Cornices (kit_cliff_cornice) along the
##                         crests of impassable cliffs, where the layout says (18 §3.2)
## Grass, blooms and verges shrink away by 95 m from the camera (GRASS_FADE_M),
## pebbles and curbs by 220 m; each batch also fades itself out (FADE_SELF).
## bake() is pure (a worker thread packs the buffers from the chunk's own seed,
## so a chunk always grows back the same); make_nodes() builds the batches on
## the main thread. The layout says where things may grow (`accept`), what
## colour the ground is (`paint`) and how far a spot is from a road's edge (`edge`).
class_name ChunkClutterBaker
extends RefCounted

const BATCH_NAMES: Array[String] = ["mm_grass_clumps", "mm_wildflowers_ferns", "mm_pebbles_fungi", "mm_road_curbs", "mm_verge_clumps",
	"mm_cliff_cornices"]
const GRASS: int = 0
const FLOWERS: int = 1
const PEBBLES: int = 2
const CURBS: int = 3
const VERGES: int = 4
const CORNICES: int = 5
## Cornices read from far off (a child tells a cliff from 60 m away), so they fade late.
const CORNICE_FADE_M: float = 320.0
## Pebbles and curbs fade out by this distance from the camera (§6.1 Ring 1).
const FADE_DISTANCE: float = 220.0
## Grass, blooms and verges shrink away by this distance (18 GDD §4.2: a zero-pop 95 m fade).
const GRASS_FADE_M: float = 95.0
## A batch spans its whole landblock, and Godot measures a visibility range to
## its middle, so each batch's own range reaches past the fade by half its diagonal.
const CHUNK_HALF_DIAGONAL: float = WorldGridConfig.CHUNK_SIZE * 0.7072
const SELF_FADE_MARGIN: float = 12.0
## Grass tufts a landblock (18 GDD §4.2): the biome's count, held between these in a window...
const GRASS_WINDOWED_MIN: int = 2500
const GRASS_WINDOWED_MAX: int = 3600
const GRASS_DENSITY: float = 3.2
## ...and this many headless (the smoke tests and dedicated hosts).
const GRASS_HEADLESS: int = 600
## Attempts per wanted instance (the layout turns some spots down).
const TRIES_PER_PIECE: float = 1.6
const HOLLOW_BIOMES: Array[StringName] = [&"rush_light_hollow", &"bramble_hollow", &"moss_oak_hollow"]
const CRAG_BIOMES: Array[StringName] = [&"barrow_crag_crossing", &"quarry_wick", &"nine_stones_crossing", &"dover_slap_falls",
	&"ring_of_the_cairnsman", &"sunken_crown_falls", &"gull_wick_haven"]
const GRASS_JITTER: float = 0.12
## Blooms grow in clusters of this many round a centre, within this reach.
const CLUSTER_SIZE: Vector2i = Vector2i(3, 7)
const CLUSTER_REACH: float = 1.3
## Road verges (18 GDD §3.1): sampled on this grid across the landblock...
const VERGE_GRID_STEP: float = 2.5
## ...a curb-stone this far outside the edge (half-buried this deep), at this share of the edge's samples...
const CURB_OFFSET: float = 0.22
const CURB_SINK: float = 0.12
const CURB_SHARE: float = 0.5
## ...verge clumps this many a sample, out to this far past the edge, and this share of the blooms along verges.
const VERGE_PER_SAMPLE: int = 3
const VERGE_REACH: float = 1.5
const VERGE_FLOWER_SHARE: float = 0.25
## No more than these a landblock.
const CURB_MAX: int = 420
const VERGE_MAX: int = 1400
## Bloom colours never read as neon magenta (18 GDD §4.2): hues between these, this saturated, become daisy white.
const MAGENTA_HUES: Vector2 = Vector2(285.0, 340.0)
const MAGENTA_SATURATION: float = 0.45
const DAISY_WHITE: Color = Color("#F4F1E6")
const BUTTERCUP_GOLD: Color = Color("#F2C230")


## The grass tufts a landblock of `look` grows: the biome's count held to 2,500-3,600 in a window, 600 headless.
static func grass_count(look: ZoneBiomeResource) -> int:
	if DisplayServer.get_name() == "headless":
		return GRASS_HEADLESS
	# Grass & flowers (the Options menu) thins it for ground baked from now on.
	return clampi(int(look.grass_clump_count * GRASS_DENSITY * SettingsManager.grass_scale()), GRASS_WINDOWED_MIN, GRASS_WINDOWED_MAX)


## The batches for a chunk of `biome_id`: {"biome", GRASS: {"count", "buffer"}, FLOWERS: ..., ..., VERGES: ...}.
## `accept` is (x: float, z: float) -> float: the ground's height there, or NAN where nothing grows.
## `paint` (optional) is (x, z, height) -> Color: the ground's painted colour (grass roots take it).
## `edge` (optional) is (x, z) -> float: metres past the nearest road's edge (negative on it, INF where no verge grows),
## and `height` (x, z) -> float the ground's height for the verges.
static func bake(chunk: Vector2i, biome_id: StringName, accept: Callable, paint: Callable = Callable(), edge: Callable = Callable(),
		height: Callable = Callable(), crests: Array[Transform3D] = []) -> Dictionary:
	var look: ZoneBiomeResource = WorldVisualCatalog.biome(biome_id)
	var baked: Dictionary = {"biome": biome_id}
	if look == null:
		for batch: int in BATCH_NAMES.size():
			baked[batch] = {"count": 0, "buffer": PackedFloat32Array()}
		return baked
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = LandblockClutter.chunk_seed(chunk) ^ 0x17C1
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var size: float = WorldGridConfig.CHUNK_SIZE
	var center: Vector3 = origin + Vector3(size * 0.5, 0.0, size * 0.5)
	var middle: Vector3 = Vector3(center.x, 0.0, center.z)
	var grass: Color = look.grass_color
	var spots: Array[Vector4] = _verge_spots(origin, size, edge, rng) if edge.is_valid() and height.is_valid() else []
	# Grass: tufts scattered over the chunk, each rooted in the ground's own colour.
	var placed: Dictionary = {"transforms": [] as Array[Transform3D], "colors": PackedColorArray()}
	var wanted: int = grass_count(look)
	for attempt: int in int(wanted * TRIES_PER_PIECE):
		if (placed["transforms"] as Array[Transform3D]).size() >= wanted:
			break
		var x: float = origin.x + rng.randf() * size
		var z: float = origin.z + rng.randf() * size
		var y: float = accept.call(x, z)
		var yaw: float = rng.randf() * TAU
		var scale: float = rng.randf_range(0.75, 1.3)
		if is_nan(y):
			continue
		var root: Color = grass
		if paint.is_valid():
			root = (paint.call(x, z, y) as Color).lerp(grass, 0.25)
		_place(placed, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), Vector3(x, y - 0.02, z) - middle), _jitter(root, rng))
	baked[GRASS] = LandblockClutter._pack(placed)
	# Blooms: grounded clusters round a centre, a share of them along the road verges.
	placed = {"transforms": [] as Array[Transform3D], "colors": PackedColorArray()}
	wanted = look.wildflower_count
	var along_verge: int = int(wanted * VERGE_FLOWER_SHARE) if not spots.is_empty() else 0
	var tries: int = int(wanted * TRIES_PER_PIECE)
	while tries > 0 and (placed["transforms"] as Array[Transform3D]).size() < wanted:
		tries -= 1
		var hub: Vector2 = Vector2(origin.x + rng.randf() * size, origin.z + rng.randf() * size)
		var on_verge: bool = (placed["transforms"] as Array[Transform3D]).size() < along_verge
		if on_verge:
			var spot: Vector4 = spots[rng.randi() % spots.size()]
			var out: float = rng.randf_range(VERGE_REACH * 0.6, VERGE_REACH * 1.4)
			hub = Vector2(spot.x + spot.z * out, spot.y + spot.w * out)
		for member: int in rng.randi_range(CLUSTER_SIZE.x, CLUSTER_SIZE.y):
			var angle: float = rng.randf() * TAU
			var reach: float = sqrt(rng.randf()) * CLUSTER_REACH
			var x: float = hub.x + cos(angle) * reach
			var z: float = hub.y + sin(angle) * reach
			var y: float = accept.call(x, z) if not on_verge else height.call(x, z)
			if on_verge:
				var past: float = edge.call(x, z)
				if past == INF or past < VERGE_REACH * 0.4:
					continue
			if is_nan(y):
				continue
			var scale: float = rng.randf_range(0.75, 1.25)
			_place(placed, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale), Vector3(x, y - 0.02, z) - middle),
				_jitter(Color.WHITE, rng))
	baked[FLOWERS] = LandblockClutter._pack(placed)
	# Pebbles: as before, scattered.
	placed = {"transforms": [] as Array[Transform3D], "colors": PackedColorArray()}
	wanted = look.pebble_fungi_count
	for attempt: int in int(wanted * TRIES_PER_PIECE):
		if (placed["transforms"] as Array[Transform3D]).size() >= wanted:
			break
		var x: float = origin.x + rng.randf() * size
		var z: float = origin.z + rng.randf() * size
		var y: float = accept.call(x, z)
		var yaw: float = rng.randf() * TAU
		var scale: float = rng.randf_range(0.75, 1.3)
		if is_nan(y):
			continue
		_place(placed, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), Vector3(x, y - 0.02, z) - middle), _jitter(Color.WHITE, rng))
	baked[PEBBLES] = LandblockClutter._pack(placed)
	# Curb-stones and verge clumps along every road edge in the chunk.
	var curbs: Dictionary = {"transforms": [] as Array[Transform3D], "colors": PackedColorArray()}
	var verges: Dictionary = {"transforms": [] as Array[Transform3D], "colors": PackedColorArray()}
	for spot: Vector4 in spots:
		var outward: Vector3 = Vector3(spot.z, 0.0, spot.w)
		var along: Vector3 = Vector3(-spot.w, 0.0, spot.z)
		if rng.randf() < CURB_SHARE and (curbs["transforms"] as Array[Transform3D]).size() < CURB_MAX:
			var at: Vector3 = Vector3(spot.x, 0.0, spot.y) + outward * CURB_OFFSET + along * rng.randf_range(-0.6, 0.6)
			var y: float = height.call(at.x, at.z) if (edge.call(at.x, at.z) as float) != INF else NAN
			if is_nan(y):
				continue
			var lean: Basis = Basis(along, rng.randf_range(-0.12, 0.12)) * Basis(Vector3.UP, atan2(-along.z, along.x) + rng.randf_range(-0.25, 0.25))
			var scale: Vector3 = Vector3(rng.randf_range(0.8, 1.35), rng.randf_range(0.8, 1.2), rng.randf_range(0.85, 1.15))
			_place(curbs, Transform3D(lean.scaled(scale), Vector3(at.x, y - CURB_SINK, at.z) - middle), _jitter(Color.WHITE, rng))
		for clump: int in VERGE_PER_SAMPLE:
			if (verges["transforms"] as Array[Transform3D]).size() >= VERGE_MAX:
				break
			# Densest just past the edge, thinning outward, some hanging a little over it.
			var out: float = lerpf(-0.15, VERGE_REACH, pow(rng.randf(), 1.6))
			var at: Vector3 = Vector3(spot.x, 0.0, spot.y) + outward * out + along * rng.randf_range(-1.2, 1.2)
			var y: float = height.call(at.x, at.z) if (edge.call(at.x, at.z) as float) != INF else NAN
			if is_nan(y):
				continue
			var scale: float = rng.randf_range(0.7, 1.3)
			var tilt: Basis = Basis(along, -0.18 * (1.0 - clampf(out / VERGE_REACH, 0.0, 1.0)))
			_place(verges, Transform3D((tilt * Basis(Vector3.UP, rng.randf() * TAU)).scaled(Vector3.ONE * scale), Vector3(at.x, y - 0.02, at.z) - middle),
				_jitter(Color.WHITE, rng))
	baked[CURBS] = LandblockClutter._pack(curbs)
	baked[VERGES] = LandblockClutter._pack(verges)
	var lips: Dictionary = {"transforms": [] as Array[Transform3D], "colors": PackedColorArray()}
	for piece: Transform3D in crests:
		_place(lips, Transform3D(piece.basis, piece.origin - middle), _jitter(Color.WHITE, rng))
	baked[CORNICES] = LandblockClutter._pack(lips)
	baked["center"] = middle
	return baked


## Points on the road edges crossing a chunk, each with its outward direction:
## (x, z, outward x, outward z). A coarse pass first skips chunks with no road.
static func _verge_spots(origin: Vector3, size: float, edge: Callable, rng: RandomNumberGenerator) -> Array[Vector4]:
	var spots: Array[Vector4] = []
	var near: bool = false
	var coarse: float = 16.0
	for gx: int in int(size / coarse) + 1:
		for gz: int in int(size / coarse) + 1:
			var e: float = edge.call(origin.x + gx * coarse, origin.z + gz * coarse)
			if e < coarse * 0.75:
				near = true
				break
		if near:
			break
	if not near:
		return spots
	var cells: int = int(size / VERGE_GRID_STEP)
	for gx: int in cells:
		for gz: int in cells:
			var x: float = origin.x + (gx + 0.5) * VERGE_GRID_STEP + rng.randf_range(-0.6, 0.6)
			var z: float = origin.z + (gz + 0.5) * VERGE_GRID_STEP + rng.randf_range(-0.6, 0.6)
			var e: float = edge.call(x, z)
			if e == INF or e < -VERGE_GRID_STEP * 0.5 or e > VERGE_GRID_STEP * 0.5:
				continue
			var slope: Vector2 = Vector2((edge.call(x + 0.3, z) as float) - e, (edge.call(x, z + 0.3) as float) - e) / 0.3
			if not slope.is_finite() or slope.length() < 0.3:
				continue
			var outward: Vector2 = slope.normalized()
			var foot: Vector2 = Vector2(x, z) - outward * e
			if foot.x < origin.x or foot.x >= origin.x + size or foot.y < origin.z or foot.y >= origin.z + size:
				continue
			spots.append(Vector4(foot.x, foot.y, outward.x, outward.y))
	return spots


static func _place(placed: Dictionary, where: Transform3D, color: Color) -> void:
	(placed["transforms"] as Array[Transform3D]).append(where)
	var colors: PackedColorArray = placed["colors"]
	colors.append(color)
	placed["colors"] = colors


static func _jitter(tint: Color, rng: RandomNumberGenerator) -> Color:
	var shade: float = rng.randf_range(-GRASS_JITTER, GRASS_JITTER)
	return tint.lightened(shade) if shade > 0.0 else tint.darkened(-shade)


## The batches as MultiMeshInstance3D nodes (main thread), placed at the chunk's middle.
static func make_nodes(baked: Dictionary) -> Array[MultiMeshInstance3D]:
	var made: Array[MultiMeshInstance3D] = []
	if baked.is_empty():
		return made
	var biome_id: StringName = baked.get("biome", &"")
	for batch: int in BATCH_NAMES.size():
		var entry: Dictionary = baked.get(batch, {})
		var count: int = entry.get("count", 0)
		if count == 0:
			continue
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = mesh_for(batch, biome_id)
		multimesh.instance_count = count
		multimesh.buffer = entry["buffer"]
		var instances: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instances.name = BATCH_NAMES[batch]
		instances.multimesh = multimesh
		instances.position = baked.get("center", Vector3.ZERO)
		instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if batch == CORNICES else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instances.visibility_range_end = fade_distance(batch) + CHUNK_HALF_DIAGONAL
		instances.visibility_range_end_margin = SELF_FADE_MARGIN
		instances.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		made.append(instances)
	return made


## How far from the camera a batch's pieces have shrunk away.
static func fade_distance(batch: int) -> float:
	if batch == CORNICES:
		return CORNICE_FADE_M
	return FADE_DISTANCE if batch in [PEBBLES, CURBS] else GRASS_FADE_M


static func instance_count(baked: Dictionary) -> int:
	var count: int = 0
	for batch: int in BATCH_NAMES.size():
		count += int(baked.get(batch, {}).get("count", 0))
	return count


## The shared mesh for a batch (grass and wildflowers by the biome's kind and colours).
static func mesh_for(batch: int, biome_id: StringName) -> ArrayMesh:
	var look: ZoneBiomeResource = WorldVisualCatalog.biome(biome_id)
	match batch:
		GRASS:
			var tip: Color = WorldVisualCatalog.GRASS_TIP.lerp(look.grass_color if look != null else WorldVisualCatalog.GRASS_TIP, 0.25)
			return WorldAssetCatalog.shared_mesh("mm_grass:%s" % tip.to_html(), func(parts: WorldAssetCatalog.Parts) -> void:
				_grass_clump(parts, tip))
		FLOWERS:
			var palette: PackedColorArray = grounded_palette(look.flower_colors if look != null else PackedColorArray([Color.WHITE]))
			var kind: StringName = &"hollow" if HOLLOW_BIOMES.has(biome_id) else (&"crag" if CRAG_BIOMES.has(biome_id) else &"green")
			return WorldAssetCatalog.shared_mesh("mm_flowers:%s:%s" % [kind, var_to_str(palette)], func(parts: WorldAssetCatalog.Parts) -> void:
				_flower_clump(parts, kind, palette))
		CURBS:
			return WorldAssetCatalog.shared_mesh("mm_curbs", _curb_stone)
		VERGES:
			return WorldAssetCatalog.shared_mesh("mm_verges", _verge_clump)
		CORNICES:
			return WorldAssetCatalog.shared_mesh("mm_cornice", func(parts: WorldAssetCatalog.Parts) -> void:
				WorldAssetCatalog._cornice(parts, {"size": Vector3(6.0, 1.0, 1.8), "seed": 3}))
	return WorldAssetCatalog.shared_mesh("mm_pebbles", _pebble_clump)


## A biome's bloom colours with any neon magenta turned to daisy white (18 GDD §4.2).
static func grounded_palette(palette: PackedColorArray) -> PackedColorArray:
	var kept: PackedColorArray = PackedColorArray()
	for bloom: Color in palette:
		var hue: float = bloom.h * 360.0
		kept.append(DAISY_WHITE if hue > MAGENTA_HUES.x and hue < MAGENTA_HUES.y and bloom.s > MAGENTA_SATURATION else bloom)
	if kept.is_empty():
		kept.append(DAISY_WHITE)
	return kept


## A lush tuft (ShapeKit.make_lush_grass_tuft_mesh): 8 arched blades, roots the instance's ground colour, tips `tip`.
static func _grass_clump(parts: WorldAssetCatalog.Parts, tip: Color) -> void:
	parts.add_mesh(ShapeKit.make_lush_grass_tuft_mesh(8, 11), Transform3D.IDENTITY, [WorldVisualCatalog.grass_blades(tip, GRASS_FADE_M)])


## A biome's blooms, grounded (18 GDD §4.2): in the Greens white daisies and golden
## buttercups over a leafy rosette with two fern fronds and a mossy stone; ferns
## and rush-reeds in the Hollows; heather on the Crags.
static func _flower_clump(parts: WorldAssetCatalog.Parts, kind: StringName, palette: PackedColorArray) -> void:
	var leaves: Material = WorldVisualCatalog.foliage(Color.WHITE, 0.6, 0.6, 1.0, false, GRASS_FADE_M)
	var stem: Color = Color(0.3, 0.48, 0.24)
	match kind:
		&"hollow":
			for index: int in 6:
				var angle: float = TAU * float(index) / 6.0
				var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
				parts.blade(out * 0.05, out * 0.42 + Vector3(0.0, 0.34, 0.0), 0.12, stem.darkened(0.25), stem.lightened(0.15), leaves)
			for index: int in 3:
				var at: Vector3 = Vector3(cos(index * 2.1) * 0.22, 0.0, sin(index * 2.1) * 0.22)
				parts.blade(at, at + Vector3(0.02, 0.85, 0.0), 0.02, stem, stem.lightened(0.2), leaves)
				parts.foliage_sphere(at + Vector3(0.02, 0.88, 0.0), 0.04, palette[0], palette[0], leaves, Vector3(1.0, 2.0, 1.0))
		&"crag":
			for index: int in 8:
				var at: Vector3 = Vector3(cos(index * 1.3) * (0.08 + 0.02 * index), 0.05, sin(index * 1.3) * (0.08 + 0.02 * index))
				var bloom: Color = palette[index % palette.size()].lerp(stem, 0.3)
				parts.foliage_sphere(at, 0.06, stem.darkened(0.25), bloom, leaves, Vector3(1.0, 1.6, 1.0))
			parts.sphere(0.09, Vector3(0.2, 0.02, -0.12), _mossy_stone(), Vector3(1.3, 0.6, 1.0), 6)
		_:
			# The leafy rosette the blooms rise from.
			parts.foliage_sphere(Vector3(0.0, 0.03, 0.0), 0.17, stem.darkened(0.3), stem, leaves, Vector3(1.0, 0.3, 1.0))
			for index: int in 6:
				var angle: float = index * 1.7
				var at: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * (0.1 + 0.035 * index)
				var height: float = 0.2 + 0.05 * float(index % 3)
				parts.blade(at, at + Vector3(0.0, height, 0.0), 0.02, stem.darkened(0.2), stem, leaves)
				var head: Vector3 = at + Vector3(0.0, height + 0.02, 0.0)
				if index % 2 == 0:
					# A daisy: a flat white ray round a golden eye.
					parts.foliage_sphere(head, 0.055, DAISY_WHITE, DAISY_WHITE, leaves, Vector3(1.0, 0.3, 1.0))
					parts.foliage_sphere(head + Vector3(0.0, 0.012, 0.0), 0.02, BUTTERCUP_GOLD, BUTTERCUP_GOLD, leaves)
				elif index % 3 == 1:
					# A buttercup: a glossy golden cup.
					parts.foliage_sphere(head, 0.04, BUTTERCUP_GOLD.darkened(0.15), BUTTERCUP_GOLD, leaves, Vector3(1.0, 0.7, 1.0))
				else:
					var bloom: Color = palette[index % palette.size()]
					parts.foliage_sphere(head, 0.045, bloom, bloom, leaves, Vector3(1.0, 0.5, 1.0))
			for side: float in [-1.0, 1.0]:
				var out: Vector3 = Vector3(side * 0.7, 0.0, 0.7).normalized()
				parts.blade(out * 0.08, out * 0.4 + Vector3(0.0, 0.26, 0.0), 0.1, stem.darkened(0.3), stem.lightened(0.1), leaves)
			parts.sphere(0.08, Vector3(-0.22, 0.02, 0.1), _mossy_stone(), Vector3(1.3, 0.6, 1.0), 6)


static func _mossy_stone() -> Material:
	return WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.CRAG_GRANITE, Color(0.62, 0.62, 0.6), false, 0.7)


## A half-buried mossy limestone curb-stone (18 GDD §3.1): a cleaved block about
## 0.7 m long, its foot sunk by the baker; mossy on top, darker at its foot.
static func _curb_stone(parts: WorldAssetCatalog.Parts) -> void:
	var limestone: Material = WorldVisualCatalog.shaded(WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE,
		Color(0.78, 0.74, 0.64), false, 0.65))
	parts.add_mesh(ShapeKit.make_sculpted_megalith(Vector3(0.72, 0.34, 0.4), 77), Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO), [limestone])


## An overhanging verge clump (18 GDD §3.1): arched fern fronds, a rosette of
## broad plantain leaves with a seed spike, and white clover over its trefoils.
static func _verge_clump(parts: WorldAssetCatalog.Parts) -> void:
	var leaves: Material = WorldVisualCatalog.foliage(Color.WHITE, 0.55, 0.7, 1.0, false, GRASS_FADE_M)
	var fern: Color = Color(0.3, 0.5, 0.24)
	var plantain: Color = Color(0.34, 0.47, 0.26)
	var clover: Color = Color(0.36, 0.56, 0.3)
	for index: int in 5:
		var angle: float = TAU * float(index) / 5.0 + 0.3
		var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		parts.blade(out * 0.06, out * 0.5 + Vector3(0.0, 0.3, 0.0), 0.13, fern.darkened(0.3), fern.lightened(0.15), leaves)
	for index: int in 4:
		var angle: float = TAU * float(index) / 4.0 + 0.8
		var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		parts.blade(out * 0.03 + Vector3(0.15, 0.0, 0.1), out * 0.24 + Vector3(0.15, 0.06, 0.1), 0.1, plantain.darkened(0.25), plantain, leaves)
	parts.blade(Vector3(0.15, 0.0, 0.1), Vector3(0.16, 0.34, 0.1), 0.02, plantain.darkened(0.2), Color(0.55, 0.5, 0.36), leaves)
	for index: int in 4:
		var at: Vector3 = Vector3(-0.15 + 0.07 * (index % 2), 0.05, -0.12 + 0.08 * (index / 2))
		for leaf: int in 3:
			var angle: float = TAU * float(leaf) / 3.0
			parts.foliage_sphere(at + Vector3(cos(angle), 0.0, sin(angle)) * 0.025, 0.026, clover.darkened(0.2), clover, leaves, Vector3(1.0, 0.35, 1.0))
		if index % 2 == 0:
			parts.blade(at, at + Vector3(0.0, 0.12, 0.0), 0.012, clover.darkened(0.2), clover, leaves)
			parts.foliage_sphere(at + Vector3(0.0, 0.13, 0.0), 0.028, DAISY_WHITE.darkened(0.05), DAISY_WHITE, leaves)


## Mossy river cobbles, a shelf mushroom and a fallen twig.
static func _pebble_clump(parts: WorldAssetCatalog.Parts) -> void:
	var cobble: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.CRAG_GRANITE, Color(0.62, 0.62, 0.6), false, 0.6)
	var cap: Material = WorldVisualCatalog.painted(Color(0.86, 0.72, 0.52))
	var twig: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, Color(0.4, 0.3, 0.2))
	parts.sphere(0.16, Vector3(0.0, 0.04, 0.0), cobble, Vector3(1.2, 0.55, 1.0), 6)
	parts.sphere(0.1, Vector3(0.22, 0.03, 0.08), cobble, Vector3(1.0, 0.6, 1.2), 6)
	parts.sphere(0.07, Vector3(-0.16, 0.02, 0.14), cobble, Vector3(1.0, 0.7, 1.0), 6)
	parts.cylinder(0.12, 0.13, 0.04, Vector3(-0.12, 0.1, -0.12), cap, 8)
	parts.cylinder(0.02, 0.025, 0.08, Vector3(-0.12, 0.05, -0.12), cap, 5)
	parts.beam(Vector3(0.05, 0.02, -0.3), Vector3(0.38, 0.03, 0.05), 0.025, twig)
