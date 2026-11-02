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
## same field is handed to one Terrain3D node instead (see make_terrain3d).
##
## It also gives each corridor chunk its HLOD proxy, one merged mesh baked from
## its landblock by tools/build_levels.gd (the village rooftops and mill, the
## Moss-Oak Great Arch and canopy, the Sinaya Gatehouse and waterwheel, the
## Cairnsman's standing stones), occluders along the ridges, and the far
## landmarks on the crags (the Sinaya Mill-Castle, the Wadden-Green's mill).
##
## Data is built by pure static functions, safe on a worker thread; nodes are
## made on the main thread from that data.
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

## The ground's height at world (x, z): continuous everywhere.
static func sample_height(world_x: float, world_z: float) -> float:
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


## The ground's colour at world (x, z): moss and meadow on the floor, a dirt
## line down the trails, heather and rock on the crags, a river in the chasm.
static func sample_surface_color(world_x: float, world_z: float) -> Color:
	return _surface_color(world_x, world_z, sample_height(world_x, world_z))


static func _surface_color(world_x: float, world_z: float, height: float) -> Color:
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

## The chunk's mesh arrays (and the collider's height map when `with_collision`), all in world space.
static func build_chunk_data(chunk: Vector2i, with_collision: bool) -> Dictionary:
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
			colors[index] = _surface_color(x, z, heights[at])
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
		var collision: PackedFloat32Array = PackedFloat32Array()
		collision.resize(COLLISION_SIDE * COLLISION_SIDE)
		for row: int in COLLISION_SIDE:
			for column: int in COLLISION_SIDE:
				# Every other sample is already a mesh vertex.
				var height: float = heights[(row / 2 + 1) * apron + column / 2 + 1] if row % 2 == 0 and column % 2 == 0 \
					else sample_height(origin.x + column, origin.z + row)
				collision[row * COLLISION_SIDE + column] = height
		data["collision_heights"] = collision
	return data


## Navigation source triangles for a corridor chunk: the floor and the crag
## foot only, spilling past the chunk's edges so baked tiles meet at the seams.
static func build_nav_faces(chunk: Vector2i) -> PackedVector3Array:
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


## The chunk's ground collider (the same triangles) and the trail walls in it,
## on the low-scenery layer: bodies stand on it, cameras look through it.
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
	var piece_index: int = 0
	for piece: Transform3D in trail_wall_pieces(chunk):
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(0.6, TRAIL_WALL_HEIGHT, TRAIL_WALL_PIECE)
		var wall: CollisionShape3D = CollisionShape3D.new()
		wall.name = "TrailWall%d" % piece_index
		wall.shape = box
		wall.transform = piece
		body.add_child(wall)
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


## Mode A: one Terrain3D node fed with our height field over Region (0, 0), so
## the world looks and plays the same with the GDExtension installed. It's
## driven by name (the class only exists with the addon), and returns null if
## the addon's API doesn't answer as expected. Untested without the addon.
static func make_terrain3d(spacing: float) -> Node3D:
	if not terrain3d_available():
		return null
	var terrain: Node3D = ClassDB.instantiate(TERRAIN3D_CLASS) as Node3D
	if terrain == null:
		return null
	terrain.name = "Terrain3D"
	if &"vertex_spacing" in terrain:
		terrain.set(&"vertex_spacing", spacing)
	var low: Vector3 = WorldGridConfig.chunk_to_world_origin(WorldGridConfig.BOUNDS_MIN)
	var size: int = int((WorldGridConfig.BOUNDS_MAX.x - WorldGridConfig.BOUNDS_MIN.x + 1) * WorldGridConfig.CHUNK_SIZE / spacing)
	var depth: int = int((WorldGridConfig.BOUNDS_MAX.y - WorldGridConfig.BOUNDS_MIN.y + 1) * WorldGridConfig.CHUNK_SIZE / spacing)
	var height_map: Image = Image.create_empty(size, depth, false, Image.FORMAT_RF)
	for row: int in depth:
		for column: int in size:
			height_map.set_pixel(column, row, Color(sample_height(low.x + column * spacing, low.z + row * spacing), 0.0, 0.0))
	var data: Object = terrain.get(&"data") as Object if &"data" in terrain else null
	if data == null or not data.has_method(&"import_images"):
		terrain.free()
		return null
	data.call(&"import_images", [height_map, null, null], low, 0.0, 1.0)
	return terrain


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
