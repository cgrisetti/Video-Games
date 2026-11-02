## Layer 1 of a Landblock (10_WORLD_ARCHITECTURE.md §4.4): the ground and the
## horizon.
##
## Mode B (the default, and what headless runs use): a continuous height field
## h(x, z) and surface colour over the whole bounded world. Each 128 m chunk
## samples it on a 2 m grid into a vertex-coloured mesh in the storybook cel
## look, with normals taken from the same field, so neighbouring chunks share
## their edge vertices and normals exactly: no seams. Its collider is a height
## map of the same field at 1 m (cheap to attach, exact on the flat floor). The corridor's floor is flat (4 cm under each zone's own floor,
## and no steeper than the 13° bridge ramps on the trails); beyond it the land
## rises at once into crags too steep to climb, and low dry-stone walls (with
## colliders) line the trails.
##
## Mode A: with the Terrain3D GDExtension installed in addons/terrain_3d/, the
## ground is drawn by one Terrain3D node instead, its clipmap LODs round Player
## 1. Each landblock is one Terrain3D region (128 vertices at 1 m), built from
## the same field (heights and the colour map) on a worker thread and added
## or removed as the chunk's Layer 1 streams. It wears a storybook shader
## (landblock_terrain3d.gdshader). The colliders stay this script's height maps
## in both modes, so the world plays identically with or without the addon.
##
## It also gives each corridor chunk its HLOD proxy, one merged mesh baked from
## its landblock by tools/build_levels.gd (the village rooftops and mill, the
## Moss-Oak Great Arch and canopy, the Sinaya Gatehouse and waterwheel, the
## Cairnsman's standing stones), occluders along the ridges, and the far
## landmarks on the crags (the Sinaya Mill-Castle, the Wadden-Green's mill).
##
## Data is built by pure static functions, safe on a worker thread; nodes are
## made on the main thread from that data.
##
## The field itself belongs to the world being streamed (WorldGridConfig.layout):
## sample_height and the colours ask it. The corridor's own field, nav faces,
## trail walls, occluders and landmarks below are the Doverslap world's
## (DoverslapLayout hands them over).
class_name LandblockTerrain
extends RefCounted

## Metres between terrain vertices (64 quads to a chunk side).
const STEP: float = 2.0
const QUADS: int = 64
## The collider's height map: a sample every metre, 129 to a side.
const COLLISION_SIDE: int = 129
## The terrain sits this far under each zone's own floor so the floor always shows.
const FLAT_SINK: float = 0.04
## The crags: how high they climb, over how many metres past the floor's edge.
const RIDGE_HEIGHT: float = 16.0
const RIDGE_RAMP: float = 18.0
const CRAG_NOISE: float = 5.0
## The floor's edge wanders outward by up to this much (never into a zone).
const EDGE_WOBBLE: float = 2.5
## Navigation source geometry covers the floor and this much of the crag foot, and spills this far past the chunk.
const NAV_BAND_MARGIN: float = 3.0
const NAV_CHUNK_MARGIN: float = 4.0
## The low dry-stone walls along the trails: their collider height, and pieces this long so they follow the slope.
const TRAIL_WALL_HEIGHT: float = 1.8
const TRAIL_WALL_PIECE: float = 8.0
const TRAIL_WALL_OFFSET: float = 0.6
const TERRAIN3D_CLASS: StringName = &"Terrain3D"
const TERRAIN3D_REGION_CLASS: StringName = &"Terrain3DRegion"
const TERRAIN3D_TEXTURE_CLASS: StringName = &"Terrain3DTextureAsset"
const TERRAIN3D_SHADER: Shader = preload("res://src/world/landblock_terrain3d.gdshader")
## Terrain3D's numbers this uses: one region per landblock, no collision of its own, no colour compression.
const TERRAIN3D_REGION_SIZE: int = 128
const TERRAIN3D_COLLISION_DISABLED: int = 0
const TERRAIN3D_COMPRESS_NONE: int = 5
const TERRAIN3D_MAP_HEIGHT: int = 0
const TERRAIN3D_MAP_COLOR: int = 2
const TERRAIN3D_MAP_MAX: int = 3
## Nothing is drawn outside the streamed regions (as in Mode B), rather than Terrain3D's flat background.
const TERRAIN3D_BACKGROUND_NONE: int = 0

const MOSS_COLOR: Color = Color(0.36, 0.5, 0.26)
const MEADOW_COLOR: Color = Color(0.44, 0.56, 0.3)
const TRAIL_COLOR: Color = Color(0.52, 0.43, 0.3)
const HEATHER_COLOR: Color = Color(0.52, 0.37, 0.5)
const ROCK_COLOR: Color = Color(0.5, 0.48, 0.44)
const CRAG_GRASS_COLOR: Color = Color(0.4, 0.5, 0.3)
const EARTH_COLOR: Color = Color(0.36, 0.28, 0.2)
const RIVER_COLOR: Color = Color(0.24, 0.42, 0.5)
const CASTLE_COLOR: Color = Color(0.62, 0.6, 0.56)
const ROOF_COLOR: Color = Color(0.55, 0.3, 0.26)

## The crags' and colours' noise (seed 1107, smooth simplex, 3 octaves of fBm at
## 0.035): the same everywhere, so the world grows back identically. A file, not
## a static variable, so nothing lingers at exit.
const NOISE: FastNoiseLite = preload("res://src/world/landblock_noise.tres")


# --- The field ------------------------------------------------------------

## The current world's ground height at world (x, z): continuous everywhere.
static func sample_height(world_x: float, world_z: float) -> float:
	return WorldGridConfig.layout.sample_height(world_x, world_z)


## The Doverslap corridor's ground height at world (x, z).
static func corridor_height(world_x: float, world_z: float) -> float:
	var height: float = LandblockManifest.base_height(world_z) - FLAT_SINK
	var dx: float = world_x - LandblockManifest.CORRIDOR_X
	var past: float = absf(dx) - _floor_edge(world_x, world_z)
	if past > 0.0:
		var t: float = clampf(past / RIDGE_RAMP, 0.0, 1.0)
		# Steep from the first metre (no foothold), easing toward the crest.
		var rise: float = 1.0 - (1.0 - t) * (1.0 - t)
		var crag: float = (NOISE.get_noise_2d(world_x * 1.7, world_z * 1.7) * 0.5 + 0.5) * CRAG_NOISE
		height += RIDGE_HEIGHT * rise + crag * t
	return minf(height, LandblockManifest.carve_bottom(world_x, world_z))


## The current world's ground colour at world (x, z).
static func sample_surface_color(world_x: float, world_z: float) -> Color:
	return WorldGridConfig.layout.surface_color(world_x, world_z, sample_height(world_x, world_z))


## The corridor's colour at (x, z): moss and meadow on the floor, a dirt line
## down the trails, heather and rock on the crags, a river in the chasm.
static func corridor_surface_color(world_x: float, world_z: float, height: float) -> Color:
	var base: float = LandblockManifest.base_height(world_z)
	var patch: float = NOISE.get_noise_2d(world_x * 0.6 + 300.0, world_z * 0.6) * 0.5 + 0.5
	if height < base - 4.0:
		return RIVER_COLOR.lerp(ROCK_COLOR, clampf((height - LandblockManifest.carve_bottom(world_x, world_z)) / 6.0, 0.0, 1.0))
	if height < base - 1.0:
		return EARTH_COLOR
	var dx: float = world_x - LandblockManifest.CORRIDOR_X
	var past: float = absf(dx) - _floor_edge(world_x, world_z)
	if past <= 0.0:
		var ground: Color = MOSS_COLOR.lerp(MEADOW_COLOR, patch)
		var trail: Vector3 = LandblockManifest.trail_at(world_z)
		if trail != Vector3.ZERO:
			ground = ground.lerp(TRAIL_COLOR, 1.0 - smoothstep(1.6, 2.8, absf(dx)))
		return ground
	var t: float = clampf(past / RIDGE_RAMP, 0.0, 1.0)
	var slope_color: Color = MOSS_COLOR.lerp(ROCK_COLOR, smoothstep(0.1, 0.55, t))
	var top: Color = HEATHER_COLOR.lerp(CRAG_GRASS_COLOR, patch)
	return slope_color.lerp(top, smoothstep(0.55, 1.0, t))


## Where the flat floor stops on (x, z)'s side: the band, nudged outward by noise.
static func _floor_edge(world_x: float, world_z: float) -> float:
	var west: bool = world_x < LandblockManifest.CORRIDOR_X
	var edge: float = LandblockManifest.band_half_width(world_z, west)
	if edge <= 0.0:
		return 0.0
	return edge + (NOISE.get_noise_2d(world_z * 0.4, 50.0 if west else -50.0) * 0.5 + 0.5) * EDGE_WOBBLE


# --- Chunk data (pure, worker-thread safe) ----------------------------------

## The chunk's data, all in world space: the mesh arrays (unless Terrain3D
## draws the ground), the collider's height map when `with_collision`, and with
## `terrain3d` its Terrain3D region.
static func build_chunk_data(chunk: Vector2i, with_collision: bool, terrain3d: bool = false) -> Dictionary:
	if terrain3d:
		var metre_heights: PackedFloat32Array = collision_heights(chunk, PackedFloat32Array())
		var regional: Dictionary = {"terrain3d_maps": make_terrain3d_maps(chunk, metre_heights)}
		if with_collision:
			regional["collision_heights"] = metre_heights
		return regional
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var side: int = QUADS + 1
	# Heights with a one-sample apron, so edge normals match the neighbour's exactly.
	var apron: int = side + 2
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(apron * apron)
	for row: int in apron:
		for column: int in apron:
			heights[row * apron + column] = sample_height(origin.x + (column - 1) * STEP, origin.z + (row - 1) * STEP)
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	vertices.resize(side * side)
	normals.resize(side * side)
	colors.resize(side * side)
	for row: int in side:
		for column: int in side:
			var at: int = (row + 1) * apron + column + 1
			var x: float = origin.x + column * STEP
			var z: float = origin.z + row * STEP
			var index: int = row * side + column
			vertices[index] = Vector3(x, heights[at], z)
			var slope_x: float = (heights[at + 1] - heights[at - 1]) / (2.0 * STEP)
			var slope_z: float = (heights[at + apron] - heights[at - apron]) / (2.0 * STEP)
			normals[index] = Vector3(-slope_x, 1.0, -slope_z).normalized()
			colors[index] = WorldGridConfig.layout.surface_color(x, z, heights[at])
	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize(QUADS * QUADS * 6)
	var cursor: int = 0
	for row: int in QUADS:
		for column: int in QUADS:
			var a: int = row * side + column
			# Clockwise seen from above (Godot's front face).
			for corner: int in [a, a + 1, a + side, a + 1, a + side + 1, a + side]:
				indices[cursor] = corner
				cursor += 1
	var data: Dictionary = {"vertices": vertices, "normals": normals, "colors": colors, "indices": indices}
	if with_collision:
		data["collision_heights"] = collision_heights(chunk, heights)
	return data


## The field every metre over the chunk, 129 to a side (its last row and column
## are the next chunk's first). `mesh_heights` (the 2 m grid with its apron) saves
## re-sampling every other point when it's there.
static func collision_heights(chunk: Vector2i, mesh_heights: PackedFloat32Array) -> PackedFloat32Array:
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var apron: int = QUADS + 3
	var collision: PackedFloat32Array = PackedFloat32Array()
	collision.resize(COLLISION_SIDE * COLLISION_SIDE)
	for row: int in COLLISION_SIDE:
		for column: int in COLLISION_SIDE:
			@warning_ignore("integer_division")
			var height: float = mesh_heights[(row / 2 + 1) * apron + column / 2 + 1] if not mesh_heights.is_empty() and row % 2 == 0 and column % 2 == 0 \
				else sample_height(origin.x + column, origin.z + row)
			collision[row * COLLISION_SIDE + column] = height
	return collision


## Navigation source triangles for a corridor chunk: the floor and the crag
## foot only, spilling past the chunk's edges so baked tiles meet at the seams.
static func corridor_nav_faces(chunk: Vector2i) -> PackedVector3Array:
	var faces: PackedVector3Array = PackedVector3Array()
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var start_x: float = origin.x - NAV_CHUNK_MARGIN
	var start_z: float = origin.z - NAV_CHUNK_MARGIN
	var cells: int = int((WorldGridConfig.CHUNK_SIZE + NAV_CHUNK_MARGIN * 2.0) / STEP)
	for row: int in cells:
		var z0: float = start_z + row * STEP
		var z1: float = z0 + STEP
		for column: int in cells:
			var x0: float = start_x + column * STEP
			var x1: float = x0 + STEP
			var middle_x: float = (x0 + x1) * 0.5
			var middle_z: float = (z0 + z1) * 0.5
			var reach: float = LandblockManifest.band_half_width(middle_z, middle_x < LandblockManifest.CORRIDOR_X) + NAV_BAND_MARGIN
			if absf(middle_x - LandblockManifest.CORRIDOR_X) > reach:
				continue
			var a: Vector3 = Vector3(x0, sample_height(x0, z0), z0)
			var b: Vector3 = Vector3(x1, sample_height(x1, z0), z0)
			var c: Vector3 = Vector3(x0, sample_height(x0, z1), z1)
			var d: Vector3 = Vector3(x1, sample_height(x1, z1), z1)
			faces.append_array(PackedVector3Array([a, b, c, b, d, c]))
	return faces


# --- Nodes (main thread) ------------------------------------------------------

static func material() -> Material:
	return StorybookMaterial.vertex_colored()


## The chunk's ground mesh, from build_chunk_data.
static func make_terrain_node(chunk: Vector2i, data: Dictionary) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = data["normals"]
	arrays[Mesh.ARRAY_COLOR] = data["colors"]
	arrays[Mesh.ARRAY_INDEX] = data["indices"]
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material())
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "Terrain_%s" % WorldGridConfig.chunk_key(chunk)
	ground.mesh = mesh
	return ground


## The chunk's ground collider (the same field as a height map) and its solid
## props (WorldLayout.solid_pieces, in data["solids"]): the ground and low
## pieces on the low-scenery layer (bodies stand on them, cameras look
## through them), tall ones (boulders, trunks) on the world layer, where they
## block cameras and shots too.
static func make_collision_node(chunk: Vector2i, data: Dictionary) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = ActorBase.LAYER_LOW_SCENERY
	body.collision_mask = 0
	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = COLLISION_SIDE
	shape.map_depth = COLLISION_SIDE
	shape.map_data = data["collision_heights"]
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	# A height map is centred on its node.
	collision.position = WorldGridConfig.chunk_to_world_center(chunk)
	body.add_child(collision)
	var solids: StaticBody3D = null
	var piece_index: int = 0
	for piece: Dictionary in data.get("solids", []) as Array:
		var shape_node: CollisionShape3D = CollisionShape3D.new()
		if piece.has("box"):
			var box: BoxShape3D = BoxShape3D.new()
			box.size = piece["box"]
			shape_node.shape = box
		else:
			var size: Vector2 = piece["cylinder"]
			var cylinder: CylinderShape3D = CylinderShape3D.new()
			cylinder.radius = size.x
			cylinder.height = size.y
			shape_node.shape = cylinder
		shape_node.transform = piece["transform"]
		if bool(piece.get("low", false)):
			shape_node.name = "TrailWall%d" % piece_index
			body.add_child(shape_node)
		else:
			if solids == null:
				solids = StaticBody3D.new()
				solids.name = "Solids"
				solids.collision_layer = ActorBase.LAYER_WORLD
				solids.collision_mask = 0
				body.add_child(solids)
			shape_node.name = "Solid%d" % piece_index
			solids.add_child(shape_node)
		piece_index += 1
	return body


## Where each piece of trail wall stands in the chunk (a box TRAIL_WALL_PIECE long, centred, on the ground).
static func trail_wall_pieces(chunk: Vector2i) -> Array[Transform3D]:
	var pieces: Array[Transform3D] = []
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var chunk_south: float = origin.z + WorldGridConfig.CHUNK_SIZE
	if chunk.x != 0:
		return pieces
	for trail: Vector3 in LandblockManifest.TRAILS:
		var south: float = minf(trail.x, chunk_south)
		var north: float = maxf(trail.y, origin.z)
		var z: float = south - TRAIL_WALL_PIECE * 0.5
		while z > north - TRAIL_WALL_PIECE * 0.5 + 0.01:
			for side: float in [-1.0, 1.0]:
				var x: float = LandblockManifest.CORRIDOR_X + side * (trail.z + TRAIL_WALL_OFFSET)
				pieces.append(Transform3D(Basis.IDENTITY, Vector3(x, LandblockManifest.base_height(z) + TRAIL_WALL_HEIGHT * 0.5 - 0.2, z)))
			z -= TRAIL_WALL_PIECE
	return pieces


## The chunk's HLOD proxy node, from its baked mesh (LandblockManifest.hlod_path,
## streamed in by the WorldGridManager); null without one.
static func make_hlod_proxy(mesh: ArrayMesh) -> MeshInstance3D:
	if mesh == null:
		return null
	var proxy: MeshInstance3D = MeshInstance3D.new()
	proxy.name = "HLODProxy"
	proxy.mesh = mesh
	proxy.material_override = material()
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return proxy


## Occluders along the ridges either side of the corridor (one wall of a
## crag chunk), so the far side of a crag isn't drawn.
static func make_occluders(chunk: Vector2i) -> OccluderInstance3D:
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var size: float = WorldGridConfig.CHUNK_SIZE
	var base: float = LandblockManifest.base_height(origin.z + size * 0.5)
	var top: float = base + RIDGE_HEIGHT * 0.75
	var quads: Array[PackedVector3Array] = []
	if chunk.x == 0:
		var widest: float = 0.0
		for step: int in 9:
			var z: float = origin.z + size * step / 8.0
			widest = maxf(widest, maxf(LandblockManifest.band_half_width(z, true), LandblockManifest.band_half_width(z, false)))
		for side: float in [-1.0, 1.0]:
			var x: float = LandblockManifest.CORRIDOR_X + side * minf(widest + RIDGE_RAMP, size * 0.5 - 1.0)
			quads.append(PackedVector3Array([Vector3(x, base, origin.z), Vector3(x, base, origin.z + size), Vector3(x, top, origin.z + size), Vector3(x, top, origin.z)]))
	else:
		var x: float = origin.x if chunk.x > 0 else origin.x + size
		quads.append(PackedVector3Array([Vector3(x, base, origin.z), Vector3(x, base, origin.z + size), Vector3(x, top, origin.z + size), Vector3(x, top, origin.z)]))
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for quad: PackedVector3Array in quads:
		var first: int = vertices.size()
		vertices.append_array(quad)
		indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var shape: ArrayOccluder3D = ArrayOccluder3D.new()
	shape.set_arrays(vertices, indices)
	var occluder: OccluderInstance3D = OccluderInstance3D.new()
	occluder.name = "Occluders"
	occluder.occluder = shape
	return occluder


## A far landmark on a crag chunk, or null: the Sinaya Mill-Castle east of the
## gorge, and the Wadden-Green's windmill on the downs south-west of the village.
static func make_horizon_landmark(chunk: Vector2i) -> MeshInstance3D:
	var merge: MeshMerge = MeshMerge.new()
	var center: Vector3 = WorldGridConfig.chunk_to_world_center(chunk)
	if chunk == Vector2i(1, -2):
		var at: Vector3 = Vector3(center.x - 20.0, sample_height(center.x - 20.0, center.z), center.z + 10.0)
		merge.add_box(at + Vector3(0.0, 6.0, 0.0), Vector3(22.0, 12.0, 14.0), CASTLE_COLOR)
		for corner: Vector2 in [Vector2(-11.0, -7.0), Vector2(11.0, -7.0), Vector2(-11.0, 7.0), Vector2(11.0, 7.0)]:
			var tower: Vector3 = at + Vector3(corner.x, 0.0, corner.y)
			merge.add_cylinder(tower + Vector3(0.0, 9.0, 0.0), 3.0, 3.0, 18.0, CASTLE_COLOR, 10)
			merge.add_cylinder(tower + Vector3(0.0, 20.5, 0.0), 0.0, 3.6, 5.0, ROOF_COLOR, 10)
		merge.add_cylinder(at + Vector3(-13.5, 4.0, 0.0), 6.0, 6.0, 1.4, Color(0.4, 0.28, 0.17), 16, true)
	elif chunk == Vector2i(-1, 1):
		var at: Vector3 = Vector3(center.x + 10.0, sample_height(center.x + 10.0, center.z - 30.0), center.z - 30.0)
		merge.add_cylinder(at + Vector3(0.0, 6.0, 0.0), 2.2, 3.4, 12.0, Color(0.85, 0.82, 0.76), 10)
		merge.add_cylinder(at + Vector3(0.0, 13.2, 0.0), 0.0, 3.0, 3.0, ROOF_COLOR, 10)
		for blade: int in 4:
			var angle: float = TAU * blade / 4.0 + 0.4
			merge.add_box(at + Vector3(cos(angle) * 4.0, 11.0 + sin(angle) * 4.0, -3.0), Vector3(1.2, 1.2, 0.2) + Vector3(absf(cos(angle)) * 6.0, absf(sin(angle)) * 6.0, 0.0),
				Color(0.9, 0.88, 0.82))
	else:
		return null
	var landmark: MeshInstance3D = MeshInstance3D.new()
	landmark.name = "HorizonLandmark"
	landmark.mesh = merge.commit()
	landmark.material_override = material()
	return landmark


# --- Mode A: Terrain3D --------------------------------------------------------

static func terrain3d_available() -> bool:
	return ClassDB.class_exists(TERRAIN3D_CLASS)


## Mode A: an empty Terrain3D node, ready for landblock regions (call
## configure_terrain3d once it's in the tree). Its clipmap follows `target`
## until a player is set; it makes no collision of its own. Driven by name: the
## class only exists with the addon.
static func make_terrain3d(target: Node3D) -> Node3D:
	if not terrain3d_available():
		return null
	var terrain: Node3D = ClassDB.instantiate(TERRAIN3D_CLASS) as Node3D
	terrain.name = "Terrain3D"
	terrain.set(&"clipmap_target", target)
	terrain.set(&"free_editor_textures", false)
	return terrain


## One plain texture slot (a tiny white albedo and a flat normal), so Terrain3D
## never counts itself untextured. With none it turns its checkerboard view on
## at every region refresh, which rebuilds its shader, and a shader rebuilt
## before the last one finished compiling is freed off the render thread (an
## error and a leaked shader per variant, about 50 on the first load). Our own
## images, because the placeholders Terrain3D makes for an empty slot leak at
## exit. The storybook shader never samples them: it draws the colour map.
static func _give_terrain3d_a_texture_slot(terrain: Node3D) -> void:
	var assets: Resource = terrain.get(&"assets") as Resource
	if assets == null or int(assets.call(&"get_texture_count")) > 0:
		return
	var slot: Resource = ClassDB.instantiate(TERRAIN3D_TEXTURE_CLASS) as Resource
	slot.set(&"name", "Storybook colour map")
	var albedo: Image = Image.create_empty(16, 16, true, Image.FORMAT_RGBA8)
	albedo.fill(Color(1.0, 1.0, 1.0, 0.0))
	albedo.generate_mipmaps()
	var normal: Image = Image.create_empty(16, 16, true, Image.FORMAT_RGBA8)
	normal.fill(Color(0.5, 0.5, 1.0, 1.0))
	normal.generate_mipmaps()
	slot.set(&"albedo_texture", ImageTexture.create_from_image(albedo))
	slot.set(&"normal_texture", ImageTexture.create_from_image(normal))
	assets.call(&"set_texture_asset", 0, slot)


## Settings that only take once the node is in the tree (Terrain3D resets them
## as it starts): one region per landblock at 1 m, no collision of its own, no
## colour compression, a texture slot, and the storybook shader.
static func configure_terrain3d(terrain: Node3D) -> void:
	terrain.set(&"collision_mode", TERRAIN3D_COLLISION_DISABLED)
	terrain.set(&"color_compress_mode", TERRAIN3D_COMPRESS_NONE)
	terrain.set(&"vertex_spacing", float(WorldGridConfig.CHUNK_SIZE) / TERRAIN3D_REGION_SIZE)
	terrain.set(&"region_size", TERRAIN3D_REGION_SIZE)
	_give_terrain3d_a_texture_slot(terrain)
	# The node's debug views pass down to its material, and its checkerboard is on by default.
	terrain.set(&"show_checkered", false)
	var look: Resource = terrain.get(&"material") as Resource
	if look != null:
		look.set(&"world_background", TERRAIN3D_BACKGROUND_NONE)
		look.set(&"show_checkered", false)
		look.set(&"shader_override", TERRAIN3D_SHADER)
		look.set(&"shader_override_enabled", true)


## A safety net: Terrain3D turns its checkerboard on whenever it finds no
## textures (the slot above prevents that); the storybook shader draws the
## colour map instead, so keep it off.
static func keep_terrain3d_untextured_view_off(terrain: Node3D) -> void:
	if bool(terrain.get(&"show_checkered")):
		terrain.set(&"show_checkered", false)
	var look: Resource = terrain.get(&"material") as Resource
	if look != null and bool(look.get(&"show_checkered")):
		look.set(&"show_checkered", false)


## A landblock's Terrain3D maps from its metre heights (129 to a side): the
## height map and the colour map (pure; worker-thread safe).
static func make_terrain3d_maps(chunk: Vector2i, metre_heights: PackedFloat32Array) -> Array[Image]:
	var origin: Vector3 = WorldGridConfig.chunk_to_world_origin(chunk)
	var height_map: Image = Image.create_empty(TERRAIN3D_REGION_SIZE, TERRAIN3D_REGION_SIZE, false, Image.FORMAT_RF)
	var color_map: Image = Image.create_empty(TERRAIN3D_REGION_SIZE, TERRAIN3D_REGION_SIZE, false, Image.FORMAT_RGBA8)
	for row: int in TERRAIN3D_REGION_SIZE:
		for column: int in TERRAIN3D_REGION_SIZE:
			var height: float = metre_heights[row * COLLISION_SIDE + column]
			height_map.set_pixel(column, row, Color(height, 0.0, 0.0))
			color_map.set_pixel(column, row, WorldGridConfig.layout.surface_color(origin.x + column, origin.z + row, height))
	var maps: Array[Image] = [height_map, color_map]
	return maps


## Main thread: the Terrain3D region for a landblock from its maps. Terrain3D's
## objects are made here, not on a worker: making many at once on workers races
## inside the extension (a crash once a whole vale streams in).
static func make_terrain3d_region(chunk: Vector2i, maps: Array[Image]) -> Resource:
	if not ClassDB.class_exists(TERRAIN3D_REGION_CLASS) or maps.size() < 2:
		return null
	var height_map: Image = maps[0]
	var color_map: Image = maps[1]
	var region: Resource = ClassDB.instantiate(TERRAIN3D_REGION_CLASS) as Resource
	region.set(&"region_size", TERRAIN3D_REGION_SIZE)
	region.set(&"vertex_spacing", float(WorldGridConfig.CHUNK_SIZE) / TERRAIN3D_REGION_SIZE)
	region.set(&"location", chunk)
	region.call(&"set_map", TERRAIN3D_MAP_HEIGHT, height_map)
	region.call(&"set_map", TERRAIN3D_MAP_COLOR, color_map)
	region.call(&"calc_height_range")
	return region


## Main thread: the landblock's region joins the terrain. It shows after the
## next refresh_terrain3d (Terrain3D rebuilds every region's textures at once,
## so the grid batches region changes into one refresh).
static func bind_terrain3d_region(terrain: Node3D, region: Resource) -> void:
	var data: Object = terrain.get(&"data") as Object
	if data != null and region != null:
		data.call(&"add_region", region, false)


static func unbind_terrain3d_region(terrain: Node3D, chunk: Vector2i) -> void:
	var data: Object = terrain.get(&"data") as Object
	if data != null and bool(data.call(&"has_region", chunk)):
		data.call(&"remove_regionl", chunk, false)


## Uploads every region's maps after regions were added or removed (about 12 ms with a dozen regions).
static func refresh_terrain3d(terrain: Node3D) -> void:
	var data: Object = terrain.get(&"data") as Object
	if data != null:
		data.call(&"update_maps", TERRAIN3D_MAP_MAX, true, false)


static func has_terrain3d_region(terrain: Node3D, chunk: Vector2i) -> bool:
	var data: Object = terrain.get(&"data") as Object
	return data != null and bool(data.call(&"has_region", chunk))


# --- A merged mesh for HLOD and landmarks -------------------------------------

## Collects simple shapes into one vertex-coloured mesh (one draw call).
class MeshMerge:
	extends RefCounted

	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()

	func add_box(center: Vector3, size: Vector3, color: Color) -> void:
		var box: BoxMesh = BoxMesh.new()
		box.size = size
		add_arrays(box.get_mesh_arrays(), Transform3D(Basis.IDENTITY, center), color)

	func add_cylinder(center: Vector3, top: float, bottom: float, height: float, color: Color, segments: int, sideways: bool = false) -> void:
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = top
		cylinder.bottom_radius = bottom
		cylinder.height = height
		cylinder.radial_segments = segments
		cylinder.rings = 1
		var basis: Basis = Basis(Vector3.FORWARD, PI * 0.5) if sideways else Basis.IDENTITY
		add_arrays(cylinder.get_mesh_arrays(), Transform3D(basis, center), color)

	## Appends a primitive's arrays (indexed or not), moved by `where`, in one colour.
	func add_arrays(arrays: Array, where: Transform3D, color: Color) -> void:
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var directions: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var turn: Basis = where.basis.inverse().transposed()
		if order.is_empty():
			for index: int in points.size():
				vertices.append(where * points[index])
				normals.append((turn * directions[index]).normalized())
				colors.append(color)
			return
		for index: int in order:
			vertices.append(where * points[index])
			normals.append((turn * directions[index]).normalized())
			colors.append(color)

	func is_empty() -> bool:
		return vertices.is_empty()

	func commit() -> ArrayMesh:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		var mesh: ArrayMesh = ArrayMesh.new()
		if not vertices.is_empty():
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh
