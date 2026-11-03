## The ground's small life, per landblock (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4.3):
## three MultiMeshInstance3D batches on the clutter ring, one draw call each,
## no colliders, nothing ticking on the CPU:
##   mm_grass_clumps       painter-style grass blades swaying in the wind and
##                         leaning from heroes within 1.2 m (the biome's count)
##   mm_wildflowers_ferns  the biome's blooms: daisies and buttercups in the
##                         Greens, bracken ferns and luminous rush-reeds in the
##                         Hollows, heather on the Crags
##   mm_pebbles_fungi      mossy river cobbles, shelf mushrooms and fallen twigs
## Every piece shrinks away between 176 and 220 m from the camera.
## bake() is pure (a worker thread packs the buffers from the chunk's own seed,
## so a chunk always grows back the same); make_nodes() builds the batches on
## the main thread. The layout says where things may grow (`accept`).
class_name ChunkClutterBaker
extends RefCounted

const BATCH_NAMES: Array[String] = ["mm_grass_clumps", "mm_wildflowers_ferns", "mm_pebbles_fungi"]
const GRASS: int = 0
const FLOWERS: int = 1
const PEBBLES: int = 2
## The clutter fades out by this distance from the camera (§6.1 Ring 1).
const FADE_DISTANCE: float = 220.0
## Attempts per wanted instance (the layout turns some spots down).
const TRIES_PER_PIECE: float = 1.6
const HOLLOW_BIOMES: Array[StringName] = [&"rush_light_hollow", &"bramble_hollow", &"moss_oak_hollow"]
const CRAG_BIOMES: Array[StringName] = [&"barrow_crag_crossing", &"quarry_wick", &"nine_stones_crossing", &"dover_slap_falls",
	&"ring_of_the_cairnsman", &"sunken_crown_falls", &"gull_wick_haven"]
const GRASS_JITTER: float = 0.12


## The three batches for a chunk of `biome_id`: {"biome", GRASS: {"count", "buffer"}, FLOWERS: ..., PEBBLES: ...}.
## `accept` is (x: float, z: float) -> float: the ground's height there, or NAN where nothing grows.
static func bake(chunk: Vector2i, biome_id: StringName, accept: Callable) -> Dictionary:
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
	var wanted: Array[int] = [look.grass_clump_count, look.wildflower_count, look.pebble_fungi_count]
	var grass: Color = look.grass_color
	for batch: int in BATCH_NAMES.size():
		var transforms: Array[Transform3D] = []
		var colors: PackedColorArray = PackedColorArray()
		var tries: int = int(wanted[batch] * TRIES_PER_PIECE)
		for attempt: int in tries:
			if transforms.size() >= wanted[batch]:
				break
			var x: float = origin.x + rng.randf() * size
			var z: float = origin.z + rng.randf() * size
			var y: float = accept.call(x, z)
			var yaw: float = rng.randf() * TAU
			var scale: float = rng.randf_range(0.75, 1.3)
			if is_nan(y):
				continue
			transforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), Vector3(x, y - 0.02, z) - Vector3(center.x, 0.0, center.z)))
			var shade: float = rng.randf_range(-GRASS_JITTER, GRASS_JITTER)
			var tint: Color = grass if batch == GRASS else Color.WHITE
			colors.append(tint.lightened(shade) if shade > 0.0 else tint.darkened(-shade))
		baked[batch] = LandblockClutter._pack({"transforms": transforms, "colors": colors})
	baked["center"] = Vector3(center.x, 0.0, center.z)
	return baked


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
		instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instances.visibility_range_end = FADE_DISTANCE + WorldGridConfig.CHUNK_SIZE * 0.5
		made.append(instances)
	return made


static func instance_count(baked: Dictionary) -> int:
	var count: int = 0
	for batch: int in BATCH_NAMES.size():
		count += int(baked.get(batch, {}).get("count", 0))
	return count


## The shared mesh for a batch (wildflowers by the biome's kind and colours).
static func mesh_for(batch: int, biome_id: StringName) -> ArrayMesh:
	match batch:
		GRASS:
			return WorldAssetCatalog.shared_mesh("mm_grass", _grass_clump)
		FLOWERS:
			var look: ZoneBiomeResource = WorldVisualCatalog.biome(biome_id)
			var palette: PackedColorArray = look.flower_colors if look != null else PackedColorArray([Color.WHITE])
			var kind: StringName = &"hollow" if HOLLOW_BIOMES.has(biome_id) else (&"crag" if CRAG_BIOMES.has(biome_id) else &"green")
			return WorldAssetCatalog.shared_mesh("mm_flowers:%s:%s" % [kind, var_to_str(palette)], func(parts: WorldAssetCatalog.Parts) -> void:
				_flower_clump(parts, kind, palette))
	return WorldAssetCatalog.shared_mesh("mm_pebbles", _pebble_clump)


## Nine blades of grass leaning out from a tuft, darker at the root.
static func _grass_clump(parts: WorldAssetCatalog.Parts) -> void:
	var blades: Material = WorldVisualCatalog.foliage(Color.WHITE, 0.55, 0.9, 1.0, false, FADE_DISTANCE)
	for index: int in 9:
		var angle: float = TAU * float(index) / 9.0 + float(index % 3) * 0.4
		var lean: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * (0.08 + 0.05 * float(index % 2))
		var height: float = 0.32 + 0.1 * float((index * 5) % 3)
		parts.blade(Vector3(cos(angle), 0.0, sin(angle)) * 0.06, lean + Vector3(0.0, height, 0.0), 0.05, Color(0.5, 0.5, 0.5), Color.WHITE, blades)


## A biome's blooms: green-meadow daisies and buttercups, hollow ferns and rush-reeds, crag heather.
static func _flower_clump(parts: WorldAssetCatalog.Parts, kind: StringName, palette: PackedColorArray) -> void:
	var leaves: Material = WorldVisualCatalog.foliage(Color.WHITE, 0.6, 0.6, 1.0, false, FADE_DISTANCE)
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
				var bloom: Color = palette[index % 2].lerp(stem, 0.3)
				parts.foliage_sphere(at, 0.06, stem.darkened(0.25), bloom, leaves, Vector3(1.0, 1.6, 1.0))
		_:
			for index: int in 4:
				var at: Vector3 = Vector3(cos(index * 1.7) * 0.18, 0.0, sin(index * 1.7) * 0.18)
				var height: float = 0.22 + 0.06 * float(index % 3)
				parts.blade(at, at + Vector3(0.0, height, 0.0), 0.02, stem.darkened(0.2), stem, leaves)
				var bloom: Color = palette[index % palette.size()]
				parts.foliage_sphere(at + Vector3(0.0, height + 0.02, 0.0), 0.055, bloom, bloom, leaves, Vector3(1.0, 0.45, 1.0))
			parts.foliage_sphere(Vector3(0.0, 0.03, 0.0), 0.16, stem.darkened(0.3), stem, leaves, Vector3(1.0, 0.35, 1.0))


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
