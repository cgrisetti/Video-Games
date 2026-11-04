## The Wayfarer's map of a level (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §7.1):
## drawn in code onto a parchment ImageTexture (no SubViewports, no cameras):
##   parchment  #EFE6D2, a little hill-shaded
##   contours   every 2 m of height, #C9B898
##   roads      #9E7B56 (the flagged Bale-Ways, the footpaths and trails, the cobbled squares)
##   water      #4A9BB8 (rivers, canals, the gorge's falls)
##   buildings  #6E473B footprints (every house, mill, pavilion, shrine and desk)
## 512 pixels along its long side in a window, 256 headless.
##
## A seamless world (Bramble-Bridge's trail, Oakshire Vale) reads its ground
## from its WorldLayout and its buildings from the footprints its level builder
## listed (cartography.json beside its landblocks), plus any kit standing in the
## tree; a walled instance (the hub, the expedition) reads its ground by casting
## rays down at its colliders, its water from its water surfaces and its paths
## from the level (LevelBase.map_paths()). The ground is gathered on the main
## thread; the pixels are painted on a worker thread (request_level_map) or at
## once (bake_level_map). Each instance's map is baked once and kept.
##
## The live things (heroes, Hush-Cracks, shrines, pins) are drawn over it by
## the WayfarerMinimapWidget and the CartographyAtlasPanel.
class_name CartographyBaker
extends RefCounted

const PARCHMENT: Color = Color("#EFE6D2")
const CONTOUR: Color = Color("#C9B898")
const ROAD: Color = Color("#9E7B56")
const WATER: Color = Color("#4A9BB8")
const FOOTPRINT: Color = Color("#6E473B")
## A contour line every this many metres of height.
const CONTOUR_STEP_M: float = 2.0
## Pixels along the map's long side.
const MAP_SIZE: int = 512
const MAP_SIZE_HEADLESS: int = 256
## A walled instance's ground is read on a grid this many rays along its long side, then smoothed up.
const RAY_GRID: int = 128
## The hill-shade's strength (a share of the parchment's value).
const HILL_SHADE: float = 0.07
## Where on the texture the world rectangle it shows is kept (Rect2, x and z).
const META_RECT: StringName = &"world_rect"
## The group the map's glyphs join (Chime-Shrines and Water-Shrines, Scribe Desks and the Scribery, portals).
const GLYPH_GROUP: StringName = &"map_glyphs"
## The footprint and crack list a level builder writes beside a world's landblocks.
const CARTOGRAPHY_FILE: String = "cartography.json"
## Kit categories drawn as building footprints, and as road (bridges).
const BUILDING_CATEGORIES: Array[StringName] = [&"ARCHITECTURE", &"STATION"]
const ROAD_CATEGORIES: Array[StringName] = [&"BRIDGE"]

enum Glyph { SHRINE, DESK, PORTAL }

static var _cache: Dictionary[StringName, ImageTexture] = {}
static var _waiting: Dictionary[StringName, Array] = {}
static var _tasks: Dictionary[StringName, int] = {}
static var _rects: Dictionary[StringName, Rect2] = {}
## Painted images waiting for the main thread (poll()), guarded by _lock.
static var _results: Dictionary[StringName, Image] = {}
static var _lock: Mutex = Mutex.new()


## The map's size along its long side here (512 in a window, 256 headless).
static func map_size() -> int:
	return MAP_SIZE_HEADLESS if DisplayServer.get_name() == "headless" else MAP_SIZE


## The level's map, baked now if it isn't yet (then kept for its instance).
static func bake_level_map(level: LevelBase) -> ImageTexture:
	var key: StringName = _key(level)
	if _cache.has(key):
		return _cache[key]
	var source: MapSource = MapSource.gather(level)
	var made: ImageTexture = _texture(source.paint(map_size()), source.rect)
	_cache[key] = made
	return made


## The level's map, painted on a worker thread: `done` gets the ImageTexture on
## the main thread, from poll() (which the minimap and the Atlas call every frame).
static func request_level_map(level: LevelBase, done: Callable) -> void:
	var key: StringName = _key(level)
	if _cache.has(key):
		done.call(_cache[key])
		return
	if _waiting.has(key):
		_waiting[key].append(done)
		return
	_waiting[key] = [done]
	var source: MapSource = MapSource.gather(level)
	var size: int = map_size()
	_rects[key] = source.rect
	_tasks[key] = WorkerThreadPool.add_task(func() -> void:
		var image: Image = source.paint(size)
		CartographyBaker._lock.lock()
		CartographyBaker._results[key] = image
		CartographyBaker._lock.unlock())


## Hands every map painted since the last call to whoever asked for it (main thread).
static func poll() -> void:
	for key: StringName in _tasks.keys():
		if WorkerThreadPool.is_task_completed(_tasks[key]):
			_collect(key, true)


## Waits for every map still being painted and keeps it (a level leaving, or the game quitting).
static func finish_pending() -> void:
	for key: StringName in _tasks.keys():
		_collect(key, false)
	_waiting.clear()


static func _collect(key: StringName, answer: bool) -> void:
	WorkerThreadPool.wait_for_task_completion(_tasks[key])
	_tasks.erase(key)
	_lock.lock()
	var image: Image = _results.get(key, null)
	_results.erase(key)
	_lock.unlock()
	if image != null:
		_finish(key, image, _rects.get(key, Rect2()), answer)
	_rects.erase(key)


## The kept map of the level, or null while it's still being painted.
static func cached_map(level: LevelBase) -> ImageTexture:
	return _cache.get(_key(level), null)


## Forgets every baked map (the tests, and a rebuilt level).
static func clear_cache() -> void:
	_cache.clear()


## The world rectangle a map shows (x, z).
static func world_rect(texture: Texture2D) -> Rect2:
	return texture.get_meta(META_RECT, Rect2()) if texture != null else Rect2()


## Where a world spot (x, z) falls on a map, 0 to 1 across and down.
static func world_to_uv(texture: Texture2D, at: Vector2) -> Vector2:
	var rect: Rect2 = world_rect(texture)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(0.5, 0.5)
	return (at - rect.position) / rect.size


## What a map glyph stands for: a shrine, a desk or a portal.
static func glyph_of(node: Node) -> int:
	if node is ScribeDesk or node is ScriberyStation:
		return Glyph.DESK
	if node is RaidPortal or node is PortalApron:
		return Glyph.PORTAL
	return Glyph.SHRINE


## Every glyph in the tree now: [{"at": Vector2, "glyph": Glyph}].
static func glyphs(tree: SceneTree) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for node: Node in tree.get_nodes_in_group(GLYPH_GROUP):
		var spot: Node3D = node as Node3D
		if spot != null and spot.is_inside_tree():
			found.append({"at": Vector2(spot.global_position.x, spot.global_position.z), "glyph": glyph_of(node)})
	return found


## Every Hush-Crack of the level, open or calmed, live or listed by its builder:
## [{"id": StringName, "at": Vector2, "calmed": bool}].
static func cracks(level: LevelBase) -> Array[Dictionary]:
	var listed: Dictionary[StringName, Dictionary] = {}
	var path: String = _cartography_path(level)
	var data: Dictionary = _read_json(path) if path != "" else {}
	var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
	var world_state: WorldStateDB = level.get(&"world_state") as WorldStateDB if &"world_state" in level else null
	for entry: Variant in data.get("cracks", []):
		var crack: Dictionary = entry as Dictionary
		var id: StringName = StringName(String(crack.get("id", "")))
		var calmed: bool = false
		if director != null and director.has_crack_state(id):
			calmed = director.crack_state(id) != ZoneSuccessionVisualResource.SuccessionState.ZONE_HUSHED
		elif world_state != null and String(crack.get("persist", "")) != "":
			var chunk: Array = crack.get("chunk", [0, 0])
			calmed = bool(world_state.get_entity_state(Vector2i(int(chunk[0]), int(chunk[1])), StringName(String(crack["persist"]))).get("cleared", false))
		listed[id] = {"id": id, "at": Vector2(float(crack.get("x", 0.0)), float(crack.get("z", 0.0))), "calmed": calmed}
	if director != null:
		for live: HushCrackLandmark in director.cracks():
			if is_instance_valid(live) and live.is_inside_tree():
				listed[live.crack_id] = {"id": live.crack_id, "at": Vector2(live.global_position.x, live.global_position.z),
					"calmed": not live.is_hushed()}
	var list: Array[Dictionary] = []
	list.assign(listed.values())
	return list


static func _finish(key: StringName, image: Image, rect: Rect2, answer: bool) -> void:
	var made: ImageTexture = _texture(image, rect)
	_cache[key] = made
	if answer:
		for done: Callable in _waiting.get(key, []):
			var target: Object = done.get_object()
			if done.is_valid() and (target == null or is_instance_valid(target)):
				done.call(made)
	_waiting.erase(key)


static func _texture(image: Image, rect: Rect2) -> ImageTexture:
	var made: ImageTexture = ImageTexture.create_from_image(image)
	made.set_meta(META_RECT, rect)
	return made


static func _key(level: LevelBase) -> StringName:
	var layout: StringName = WorldGridConfig.layout.layout_id() if _is_streamed(level) else &"walled"
	return StringName("%s:%s" % [level.instance_id(), layout])


static func _is_streamed(level: LevelBase) -> bool:
	return level is EverwoodWorld or level is OakshireVale


static func _cartography_path(level: LevelBase) -> String:
	return WorldGridConfig.layout.cartography_path() if _is_streamed(level) else ""


static func _read_json(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


## The building footprints (x, z, width, depth, yaw) and road pieces of every kit under `root`.
static func kit_footprints(root: Node) -> Array[PackedFloat32Array]:
	var found: Array[PackedFloat32Array] = []
	if root == null:
		return found
	for node: Node in root.find_children("*", "WorldKitInstance", true, false):
		var placed: WorldKitInstance = node as WorldKitInstance
		var print_of: PackedFloat32Array = footprint_of(placed, placed.global_transform if placed.is_inside_tree() else Transform3D(Basis.IDENTITY, placed.position))
		if not print_of.is_empty():
			found.append(print_of)
	return found


## One kit's footprint: x, z, width, depth, yaw and 0 (a building) or 1 (a road), or empty for other kits.
static func footprint_of(placed: WorldKitInstance, where: Transform3D) -> PackedFloat32Array:
	var kit: WorldPropKitResource = WorldVisualCatalog.kit(placed.kit_id)
	if kit == null or not (kit.category in BUILDING_CATEGORIES or kit.category in ROAD_CATEGORIES):
		return PackedFloat32Array()
	var size: Vector3 = placed.size if placed.size != Vector3.ZERO else kit.bounding_size
	var scale: Vector3 = where.basis.get_scale()
	var x_axis: Vector3 = where.basis.x
	var yaw: float = atan2(-x_axis.z, x_axis.x)
	return PackedFloat32Array([where.origin.x, where.origin.z, size.x * scale.x, size.z * scale.z, yaw,
		1.0 if kit.category in ROAD_CATEGORIES else 0.0])


## What a level's map is drawn from, gathered on the main thread; paint() is pure.
class MapSource:
	extends RefCounted

	var rect: Rect2 = Rect2(0.0, 0.0, 64.0, 64.0)
	## A seamless world's layout (thread-safe), or null for a walled instance.
	var layout: WorldLayout
	## A walled instance's heights on a grid across `rect` (grid_size.x by grid_size.y), NAN where nothing was hit.
	var heights: PackedFloat32Array = PackedFloat32Array()
	var grid_size: Vector2i = Vector2i.ZERO
	## Water rectangles (x, z, width, depth) and paths ({"points": PackedVector2Array, "half_width": float}).
	var water: Array[Rect2] = []
	var paths: Array[Dictionary] = []
	var footprints: Array[PackedFloat32Array] = []

	static func gather(level: LevelBase) -> MapSource:
		var source: MapSource = MapSource.new()
		source.footprints = CartographyBaker.kit_footprints(level)
		if CartographyBaker._is_streamed(level):
			source.layout = WorldGridConfig.layout
			source.rect = source.layout.map_rect()
			var listed: Dictionary = CartographyBaker._read_json(source.layout.cartography_path())
			for entry: Variant in listed.get("footprints", []):
				var values: Array = entry as Array
				if values.size() >= 6:
					source.footprints.append(PackedFloat32Array(values))
			return source
		source.rect = level.map_rect()
		source.paths = level.map_paths()
		source._read_walled(level)
		return source

	## Rays straight down at the colliders on a coarse grid, and the water surfaces' extents.
	func _read_walled(level: LevelBase) -> void:
		var long_side: float = maxf(rect.size.x, rect.size.y)
		grid_size = Vector2i(maxi(2, roundi(RAY_GRID * rect.size.x / long_side)), maxi(2, roundi(RAY_GRID * rect.size.y / long_side)))
		heights.resize(grid_size.x * grid_size.y)
		var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state if level.is_inside_tree() else null
		for gz: int in grid_size.y:
			for gx: int in grid_size.x:
				var x: float = rect.position.x + (gx + 0.5) * rect.size.x / grid_size.x
				var z: float = rect.position.y + (gz + 0.5) * rect.size.y / grid_size.y
				var y: float = NAN
				if space != null:
					var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(x, 80.0, z), Vector3(x, -80.0, z), ActorBase.LAYER_WORLD)
					var hit: Dictionary = space.intersect_ray(query)
					if not hit.is_empty():
						y = (hit["position"] as Vector3).y
				heights[gz * grid_size.x + gx] = y
		for node: Node in level.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.mesh == null or mesh.mesh.get_surface_count() == 0 or not mesh.is_visible_in_tree():
				continue
			var material: ShaderMaterial = (mesh.material_override if mesh.material_override != null else mesh.mesh.surface_get_material(0)) as ShaderMaterial
			if material == null or material.shader != WorldVisualCatalog.WATER_SHADER:
				continue
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			water.append(Rect2(box.position.x, box.position.z, box.size.x, box.size.z))

	func _height(x: float, z: float) -> float:
		if layout != null:
			return layout.sample_height(x, z)
		var gx: float = clampf((x - rect.position.x) / rect.size.x * grid_size.x - 0.5, 0.0, grid_size.x - 1.001)
		var gz: float = clampf((z - rect.position.y) / rect.size.y * grid_size.y - 0.5, 0.0, grid_size.y - 1.001)
		var x0: int = int(gx)
		var z0: int = int(gz)
		var corners: Array[float] = [heights[z0 * grid_size.x + x0], heights[z0 * grid_size.x + x0 + 1],
			heights[(z0 + 1) * grid_size.x + x0], heights[(z0 + 1) * grid_size.x + x0 + 1]]
		var known: float = 0.0
		for value: float in corners:
			if not is_nan(value):
				known = value
		for index: int in corners.size():
			if is_nan(corners[index]):
				corners[index] = known
		var fx: float = gx - x0
		var fz: float = gz - z0
		return lerpf(lerpf(corners[0], corners[1], fx), lerpf(corners[2], corners[3], fx), fz)

	func _feature(x: float, z: float, h: float) -> int:
		if layout != null:
			return layout.map_feature(x, z, h)
		var at: Vector2 = Vector2(x, z)
		for pool: Rect2 in water:
			if pool.has_point(at):
				return WorldLayout.MapFeature.WATER
		for path: Dictionary in paths:
			var points: PackedVector2Array = path["points"]
			var half: float = float(path.get("half_width", 2.0))
			for index: int in points.size() - 1:
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at, points[index], points[index + 1])) < half:
					return WorldLayout.MapFeature.ROAD
		return WorldLayout.MapFeature.GROUND

	## The parchment, `long_side` pixels along its long side (pure: safe on a worker thread).
	func paint(long_side: int) -> Image:
		var aspect: float = rect.size.x / maxf(rect.size.y, 0.001)
		var width: int = long_side if aspect >= 1.0 else maxi(8, roundi(long_side * aspect))
		var height: int = long_side if aspect <= 1.0 else maxi(8, roundi(long_side / aspect))
		var step: Vector2 = Vector2(rect.size.x / width, rect.size.y / height)
		var rows: Array[PackedFloat32Array] = []
		var features: PackedByteArray = PackedByteArray()
		features.resize(width * height)
		for py: int in height:
			var row: PackedFloat32Array = PackedFloat32Array()
			row.resize(width)
			var z: float = rect.position.y + (py + 0.5) * step.y
			for px: int in width:
				var x: float = rect.position.x + (px + 0.5) * step.x
				var h: float = _height(x, z)
				row[px] = h
				features[py * width + px] = _feature(x, z, h)
			rows.append(row)
		var bytes: PackedByteArray = PackedByteArray()
		bytes.resize(width * height * 4)
		for py: int in height:
			for px: int in width:
				var h: float = rows[py][px]
				var right: float = rows[py][mini(px + 1, width - 1)]
				var below: float = rows[mini(py + 1, height - 1)][px]
				var color: Color = PARCHMENT
				# A soft hill-shade, lit from the north-west.
				var slope: float = ((right - h) / step.x + (below - h) / step.y) * 0.5
				color = color.darkened(clampf(slope * 0.6, -1.0, 1.0) * HILL_SHADE) if slope > 0.0 else color.lightened(clampf(-slope * 0.6, 0.0, 1.0) * HILL_SHADE * 0.5)
				match features[py * width + px]:
					WorldLayout.MapFeature.WATER:
						color = WATER
					WorldLayout.MapFeature.ROAD:
						color = ROAD
				if features[py * width + px] != WorldLayout.MapFeature.WATER:
					var band: int = floori(h / CONTOUR_STEP_M)
					if band != floori(right / CONTOUR_STEP_M) or band != floori(below / CONTOUR_STEP_M):
						color = color.lerp(CONTOUR, 0.85) if features[py * width + px] == WorldLayout.MapFeature.GROUND else color.darkened(0.12)
				var at: int = (py * width + px) * 4
				bytes[at] = int(color.r8)
				bytes[at + 1] = int(color.g8)
				bytes[at + 2] = int(color.b8)
				bytes[at + 3] = 255
		for footprint: PackedFloat32Array in footprints:
			_stamp(bytes, width, height, step, footprint)
		var image: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, bytes)
		image.generate_mipmaps()
		return image

	## Fills one footprint (x, z, width, depth, yaw, road) into the pixels, at least a pixel across.
	func _stamp(bytes: PackedByteArray, width: int, height: int, step: Vector2, footprint: PackedFloat32Array) -> void:
		var center: Vector2 = Vector2(footprint[0], footprint[1])
		var half: Vector2 = Vector2(maxf(footprint[2] * 0.5, step.x * 0.6), maxf(footprint[3] * 0.5, step.y * 0.6))
		var yaw: float = footprint[4]
		var tint: Color = ROAD if footprint[5] > 0.5 else FOOTPRINT
		var reach: float = half.length()
		var low: Vector2i = Vector2i(floori((center.x - reach - rect.position.x) / step.x), floori((center.y - reach - rect.position.y) / step.y))
		var high: Vector2i = Vector2i(ceili((center.x + reach - rect.position.x) / step.x), ceili((center.y + reach - rect.position.y) / step.y))
		var c: float = cos(yaw)
		var s: float = sin(yaw)
		for py: int in range(maxi(low.y, 0), mini(high.y, height)):
			for px: int in range(maxi(low.x, 0), mini(high.x, width)):
				var dx: float = rect.position.x + (px + 0.5) * step.x - center.x
				var dz: float = rect.position.y + (py + 0.5) * step.y - center.y
				var lx: float = dx * c - dz * s
				var lz: float = dx * s + dz * c
				if absf(lx) <= half.x and absf(lz) <= half.y:
					var at: int = (py * width + px) * 4
					bytes[at] = int(tint.r8)
					bytes[at + 1] = int(tint.g8)
					bytes[at + 2] = int(tint.b8)
