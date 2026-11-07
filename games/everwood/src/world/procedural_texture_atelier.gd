## The Procedural Texture Atelier (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md
## §3.1): eight seamless craft textures, each an albedo, a normal and a
## roughness map, generated in code from fixed seeds so the repository carries
## no image files and every run looks the same.
##   COBBLED_FLAGSTONE  bevelled limestone and sandstone setts, warm mortar, moss flecks
##   STEPPED_BRICK      running-bond kiln bricks (#B85D43) in recessed lime mortar
##   LIME_PLASTER       hand-troweled cottage lime-wash (#F4EFE6), gently weathered
##   HEWN_TIMBER        oak planks (#6E4B2E) with grain, adze marks and pegs
##   SCALLOP_SHINGLE    overlapping fish-scale slate, clay and moss roof tiles
##   MEADOW_TURF        painterly grass strokes and clover (#5B8C4A)
##   HOLLOW_LOAM        peat, fallen oak leaves and root striations (#594636)
##   CRAG_GRANITE       stratified highland stone (#7A8086), lichen and heather in its cracks
## render_set() is pure (safe on a worker thread). The WorldAtmosphereDirector
## renders all eight at start, 256 px a side (64 px in headless runs), stacks
## them into three Texture2DArrays and hands them to every world shader as the
## global parameters atelier_albedo, atelier_normal and atelier_roughness.
## A curated texture wins: res://assets/textures/world/<id>_albedo.png (and
## _normal.png, _roughness.png) replaces the generated map of that name. The
## hand-painted set (tools/paint_atelier_textures.py, docs/24 §3) covers all
## eight: then the arrays are CURATED_SIZE a side and nothing is generated.
class_name ProceduralTextureAtelier
extends RefCounted

enum Set { COBBLED_FLAGSTONE, STEPPED_BRICK, LIME_PLASTER, HEWN_TIMBER, SCALLOP_SHINGLE, MEADOW_TURF, HOLLOW_LOAM, CRAG_GRANITE }

const SET_IDS: Array[StringName] = [&"tex_cobbled_flagstone", &"tex_stepped_brick", &"tex_lime_plaster", &"tex_hewn_timber",
	&"tex_scallop_shingle", &"tex_meadow_turf", &"tex_hollow_loam", &"tex_crag_granite"]
const SIZE: int = 256
const HEADLESS_SIZE: int = 64
## The arrays' side when every set has its curated albedo.
const CURATED_SIZE: int = 1024
const OVERRIDE_FOLDER: String = "res://assets/textures/world/"
## Metres of the world one tile covers (a craft material's triplanar scale is 1 / this).
const TILE_METRES: Array[float] = [3.0, 2.0, 3.0, 2.0, 2.4, 4.0, 4.0, 5.0]
## How strongly each set's relief shows in its normal map.
const RELIEF: Array[float] = [5.0, 4.0, 1.4, 3.0, 4.5, 1.8, 2.2, 4.0]
const MAPS: Array[String] = ["albedo", "normal", "roughness"]

const FLAGSTONE: Color = Color("#C8BFA8")
const SANDSTONE: Color = Color("#BFA483")
const MORTAR: Color = Color("#8C8274")
const MOSS: Color = Color("#4A733E")
const BRICK: Color = Color("#B85D43")
const BRICK_OCHRE: Color = Color("#B9824F")
const LIME_MORTAR: Color = Color("#D9D2C2")
const PLASTER: Color = Color("#F4EFE6")
const PLASTER_WARM: Color = Color("#E8DCC6")
const TIMBER: Color = Color("#6E4B2E")
const TIMBER_DARK: Color = Color("#4E3420")
const SLATE: Color = Color("#6F7E8C")
const CLAY_TILE: Color = Color("#A65E44")
const TURF: Color = Color("#5B8C4A")
const TURF_LIGHT: Color = Color("#7FA65A")
const CLOVER: Color = Color("#6E9E52")
const LOAM: Color = Color("#594636")
const LEAF: Color = Color("#9C6A33")
const GRANITE: Color = Color("#7A8086")
const GRANITE_DARK: Color = Color("#5F6469")
const LICHEN: Color = Color("#A3A65E")
const HEATHER: Color = Color("#7B587D")


static func size_for_this_run() -> int:
	if DisplayServer.get_name() == "headless":
		return HEADLESS_SIZE
	return CURATED_SIZE if all_curated() else SIZE


## Whether a set has all three of its curated maps.
static func has_curated(which: int) -> bool:
	for map: String in MAPS:
		if not ResourceLoader.exists("%s%s_%s.png" % [OVERRIDE_FOLDER, SET_IDS[which], map]):
			return false
	return true


## Whether every set is curated (the hand-painted set is in place).
static func all_curated() -> bool:
	for which: int in SET_IDS.size():
		if not has_curated(which):
			return false
	return true


## A set's maps for a run: nothing to generate when its curated maps will replace them (blank stand-ins).
static func render_or_blank(which: int, size: int) -> Array[Image]:
	if has_curated(which) and size > HEADLESS_SIZE:
		var blank: Array[Image] = []
		for map: int in MAPS.size():
			blank.append(Image.create_empty(size, size, true, Image.FORMAT_RGBA8))
		return blank
	return render_set(which, size)


## One set's three maps, [albedo, normal, roughness], each RGBA8 with mipmaps. Pure: safe on a worker thread.
static func render_set(which: int, size: int) -> Array[Image]:
	var count: int = size * size
	var albedo: PackedColorArray = PackedColorArray()
	albedo.resize(count)
	var height: PackedFloat32Array = PackedFloat32Array()
	height.resize(count)
	var rough: PackedFloat32Array = PackedFloat32Array()
	rough.resize(count)
	# Broad noise about four cycles a tile, fine noise about sixteen, whatever the size.
	var noise: PackedFloat32Array = _seamless_noise(size, 1000 + which * 17, 4.0 / size)
	var fine: PackedFloat32Array = _seamless_noise(size, 2000 + which * 31, 16.0 / size)
	match which:
		Set.COBBLED_FLAGSTONE:
			_flagstone(size, noise, fine, albedo, height, rough)
		Set.STEPPED_BRICK:
			_brick(size, noise, fine, albedo, height, rough)
		Set.LIME_PLASTER:
			_plaster(size, noise, fine, albedo, height, rough)
		Set.HEWN_TIMBER:
			_timber(size, noise, fine, albedo, height, rough)
		Set.SCALLOP_SHINGLE:
			_shingle(size, noise, fine, albedo, height, rough)
		Set.MEADOW_TURF:
			_turf(size, noise, fine, albedo, height, rough)
		Set.HOLLOW_LOAM:
			_loam(size, noise, fine, albedo, height, rough)
		_:
			_granite(size, noise, fine, albedo, height, rough)
	var maps: Array[Image] = [_color_image(size, albedo), _normal_image(size, height, RELIEF[which]), _gray_image(size, rough)]
	return maps


## A set's three maps as textures: a curated file where there is one, else generated (tests and tools).
static func texture_set(which: int, size: int = -1) -> Dictionary:
	var side: int = size if size > 0 else size_for_this_run()
	var images: Array[Image] = images_with_overrides(which, side, render_set(which, side))
	var textures: Dictionary = {}
	for map: int in MAPS.size():
		textures[MAPS[map]] = ImageTexture.create_from_image(images[map])
	return textures


## Swaps in any curated map for a set, resized to match (main thread: it loads files).
static func images_with_overrides(which: int, size: int, generated: Array[Image]) -> Array[Image]:
	var images: Array[Image] = []
	images.assign(generated)
	for map: int in MAPS.size():
		var path: String = "%s%s_%s.png" % [OVERRIDE_FOLDER, SET_IDS[which], MAPS[map]]
		if not ResourceLoader.exists(path):
			continue
		var curated: Texture2D = load(path) as Texture2D
		if curated == null:
			continue
		var image: Image = curated.get_image()
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		image.clear_mipmaps()
		image.resize(size, size, Image.INTERPOLATE_BILINEAR)
		image.generate_mipmaps()
		images[map] = image
	return images


## Stacks every set's map of one kind into a Texture2DArray (main thread).
static func make_array(images: Array[Image]) -> Texture2DArray:
	var array: Texture2DArray = Texture2DArray.new()
	array.create_from_images(images)
	return array


# --- The eight crafts ------------------------------------------------------------------

## Voronoi setts on a wrapped grid: each stone bevelled into warm mortar, moss in the joints.
static func _flagstone(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	var cells: int = 5
	var points: PackedVector2Array = _cell_points(cells, 11)
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var cell: Vector3 = _voronoi(float(x) / size * cells, float(y) / size * cells, cells, points)
			var edge: float = cell.y - cell.x
			var bevel: float = smoothstep(0.03, 0.2, edge)
			var stone: Color = FLAGSTONE.lerp(SANDSTONE, _hash01(int(cell.z) * 7 + 3)).darkened(_hash01(int(cell.z) * 13 + 1) * 0.12)
			stone = stone.lightened((noise[i] - 0.5) * 0.12)
			var joint: Color = MORTAR.lerp(MOSS, smoothstep(0.55, 0.75, noise[i]) * 0.8)
			albedo[i] = joint.lerp(stone, bevel)
			height[i] = bevel * (0.75 + fine[i] * 0.25)
			rough[i] = lerpf(0.95, 0.72, bevel)


## Running bond: eight courses a tile, four bricks a course, each its own kiln shade.
static func _brick(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	var courses: int = 8
	var per_course: int = 4
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var v: float = float(y) / size * courses
			var course: int = int(v)
			var u: float = fposmod(float(x) / size * per_course + (0.5 if course % 2 == 1 else 0.0), float(per_course))
			var brick: int = int(u)
			var edge: float = minf(minf(v - course, 1.0 - (v - course)) * 4.0, minf(u - brick, 1.0 - (u - brick)) * 8.0)
			var face: float = smoothstep(0.12, 0.32, edge)
			var shade: float = _hash01(course * 31 + brick * 7 + 5)
			var kiln: Color = BRICK.lerp(BRICK_OCHRE, shade * 0.6).darkened(_hash01(course * 17 + brick * 3) * 0.15)
			kiln = kiln.lightened((fine[i] - 0.5) * 0.14)
			albedo[i] = LIME_MORTAR.darkened(noise[i] * 0.15).lerp(kiln, face)
			height[i] = face * (0.8 + fine[i] * 0.2)
			rough[i] = lerpf(0.97, 0.82, face)


## Lime-wash troweled in broad, overlapping strokes, warmer where it has weathered.
static func _plaster(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var stroke: float = sin((float(x) + noise[i] * size * 0.4) / size * TAU * 3.0 + float(y) / size * TAU) * 0.5 + 0.5
			albedo[i] = PLASTER.lerp(PLASTER_WARM, smoothstep(0.45, 0.85, noise[i]) * 0.8).darkened(stroke * 0.04 + (1.0 - fine[i]) * 0.03)
			height[i] = stroke * 0.3 + fine[i] * 0.2
			rough[i] = 0.9


## Four planks a tile: grain that wanders, adze scoops along the length, a peg at each end.
static func _timber(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	var planks: int = 4
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var u: float = float(x) / size * planks
			var plank: int = int(u)
			var across: float = u - plank
			var seam: float = smoothstep(0.0, 0.06, across) * smoothstep(1.0, 0.94, across)
			var grain: float = sin((across * 9.0 + noise[i] * 3.0 + _hash01(plank * 5) * 4.0) * TAU) * 0.5 + 0.5
			var adze: float = sin(float(y) / size * TAU * 6.0 + plank * 1.7) * 0.5 + 0.5
			var wood: Color = TIMBER.lerp(TIMBER_DARK, grain * 0.45).lightened(_hash01(plank * 11 + 2) * 0.12)
			var peg_d: float = Vector2(across - 0.5, fposmod(float(y) / size + plank * 0.25, 1.0) - 0.08).length()
			var peg: float = 1.0 - smoothstep(0.06, 0.09, peg_d)
			albedo[i] = wood.darkened(adze * 0.08 + peg * 0.35).lerp(TIMBER_DARK.darkened(0.3), 1.0 - seam)
			height[i] = seam * (0.7 + grain * 0.15 + adze * 0.15) - peg * 0.2
			rough[i] = lerpf(0.95, 0.78, seam)


## Fish-scale shingles: six rows a tile, each row half a scale over, round at the bottom.
static func _shingle(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	var rows: int = 6
	var per_row: int = 6
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var v: float = float(y) / size * rows
			var row: int = int(v)
			var u: float = fposmod(float(x) / size * per_row + (0.5 if row % 2 == 1 else 0.0), float(per_row))
			var scale: int = int(u)
			var local: Vector2 = Vector2(u - scale - 0.5, v - row)
			# The scale's round lower edge: inside a half-ellipse hanging from the row above.
			var shape: float = (local.x * local.x) / 0.25 + (local.y * local.y) / 1.0
			var inside: float = smoothstep(1.0, 0.86, shape)
			var tone: float = _hash01(row * 19 + scale * 7 + 1)
			var tile: Color = SLATE.lerp(CLAY_TILE, 1.0 if tone > 0.82 else 0.0).lerp(MOSS, smoothstep(0.6, 0.8, noise[i]) * 0.55)
			tile = tile.lightened((tone - 0.5) * 0.16).darkened(local.y * 0.18)
			albedo[i] = tile.darkened(0.45).lerp(tile, inside)
			height[i] = inside * (0.4 + local.y * 0.6) + fine[i] * 0.05
			rough[i] = lerpf(0.9, 0.7, inside)


## Painterly grass: short strokes leaning one way, clover patches, a few bare flecks.
static func _turf(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var j: int = ((y + 3) % size) * size + (x + 1) % size
			var blade: float = clampf(fine[i] * 1.4 - fine[j] * 0.5, 0.0, 1.0)
			var clover: float = smoothstep(0.62, 0.72, noise[i])
			var green: Color = TURF.lerp(TURF_LIGHT, blade * 0.55).lerp(CLOVER, clover * 0.7)
			albedo[i] = green.darkened((1.0 - blade) * 0.12)
			height[i] = blade * 0.6 + clover * 0.3
			rough[i] = 0.92


## Peat with fallen oak leaves and root lines.
static func _loam(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	var cells: int = 9
	var points: PackedVector2Array = _cell_points(cells, 23)
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var cell: Vector3 = _voronoi(float(x) / size * cells, float(y) / size * cells, cells, points)
			var leaf: float = smoothstep(0.32, 0.18, cell.x) * (1.0 if _hash01(int(cell.z) * 3 + 9) > 0.45 else 0.0)
			var root: float = smoothstep(0.92, 0.98, sin((float(x) / size * 3.0 + noise[i] * 1.6) * TAU) * 0.5 + 0.5)
			var earth: Color = LOAM.lightened((fine[i] - 0.5) * 0.18)
			earth = earth.lerp(LEAF.lerp(LEAF.darkened(0.3), _hash01(int(cell.z))), leaf * 0.85).lerp(TIMBER_DARK, root * 0.6)
			albedo[i] = earth
			height[i] = fine[i] * 0.4 + leaf * 0.4 + root * 0.5
			rough[i] = lerpf(0.88, 0.7, leaf)


## Stratified granite: bands that warp, speckle, lichen on the faces and heather in the cracks.
static func _granite(size: int, noise: PackedFloat32Array, fine: PackedFloat32Array, albedo: PackedColorArray,
		height: PackedFloat32Array, rough: PackedFloat32Array) -> void:
	for y: int in size:
		for x: int in size:
			var i: int = y * size + x
			var band: float = sin((float(y) / size * 5.0 + noise[i] * 1.2) * TAU) * 0.5 + 0.5
			var crack: float = smoothstep(0.96, 0.995, band)
			var rock: Color = GRANITE.lerp(GRANITE_DARK, band * 0.4).lightened((fine[i] - 0.5) * 0.2)
			rock = rock.lerp(LICHEN, smoothstep(0.7, 0.82, noise[i]) * 0.5).lerp(HEATHER, crack * 0.8)
			albedo[i] = rock
			height[i] = (1.0 - crack) * (0.6 + fine[i] * 0.4) - band * 0.15
			rough[i] = lerpf(0.75, 0.9, crack)


# --- Helpers ---------------------------------------------------------------------------

## Tileable value noise from FastNoiseLite's seamless image, 0..1 per pixel.
static func _seamless_noise(size: int, seed_value: int, frequency: float) -> PackedFloat32Array:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 3
	var image: Image = noise.get_seamless_image(size, size, false, false, 0.1, true)
	image.convert(Image.FORMAT_L8)
	var data: PackedByteArray = image.get_data()
	var values: PackedFloat32Array = PackedFloat32Array()
	values.resize(size * size)
	for index: int in values.size():
		values[index] = data[index] / 255.0
	return values


## One jittered feature point per grid cell (cells x cells), in cell units.
static func _cell_points(cells: int, salt: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in cells * cells:
		points.append(Vector2(0.15 + _hash01(index * 2 + salt) * 0.7, 0.15 + _hash01(index * 2 + 1 + salt) * 0.7))
	return points


## Wrapped Voronoi at (u, v) in cell units: x the nearest distance, y the second, z the nearest cell's index.
static func _voronoi(u: float, v: float, cells: int, points: PackedVector2Array) -> Vector3:
	var cu: int = int(u)
	var cv: int = int(v)
	var first: float = 9.0
	var second: float = 9.0
	var nearest: int = 0
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var gx: int = cu + dx
			var gy: int = cv + dy
			var index: int = posmod(gy, cells) * cells + posmod(gx, cells)
			var point: Vector2 = Vector2(gx, gy) + points[index]
			var d: float = Vector2(u - point.x, v - point.y).length()
			if d < first:
				second = first
				first = d
				nearest = index
			elif d < second:
				second = d
	return Vector3(first, second, nearest)


static func _hash01(value: int) -> float:
	var h: int = (value * 374761393 + 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 10007) / 10006.0


static func _color_image(size: int, pixels: PackedColorArray) -> Image:
	var data: PackedByteArray = PackedByteArray()
	data.resize(size * size * 4)
	for index: int in pixels.size():
		var c: Color = pixels[index]
		data[index * 4] = clampi(int(c.r * 255.0), 0, 255)
		data[index * 4 + 1] = clampi(int(c.g * 255.0), 0, 255)
		data[index * 4 + 2] = clampi(int(c.b * 255.0), 0, 255)
		data[index * 4 + 3] = 255
	var image: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, data)
	image.generate_mipmaps()
	return image


static func _gray_image(size: int, values: PackedFloat32Array) -> Image:
	var data: PackedByteArray = PackedByteArray()
	data.resize(size * size * 4)
	for index: int in values.size():
		var v: int = clampi(int(values[index] * 255.0), 0, 255)
		data[index * 4] = v
		data[index * 4 + 1] = v
		data[index * 4 + 2] = v
		data[index * 4 + 3] = 255
	var image: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, data)
	image.generate_mipmaps()
	return image


## A tangent-space normal map from a wrapped height field (x right, y down the image, z out).
static func _normal_image(size: int, height: PackedFloat32Array, relief: float) -> Image:
	var data: PackedByteArray = PackedByteArray()
	data.resize(size * size * 4)
	var scale: float = relief * size / 256.0
	for y: int in size:
		for x: int in size:
			var left: float = height[y * size + posmod(x - 1, size)]
			var right: float = height[y * size + (x + 1) % size]
			var up: float = height[posmod(y - 1, size) * size + x]
			var down: float = height[((y + 1) % size) * size + x]
			var n: Vector3 = Vector3((left - right) * scale, (up - down) * scale, 1.0).normalized()
			var index: int = (y * size + x) * 4
			data[index] = clampi(int((n.x * 0.5 + 0.5) * 255.0), 0, 255)
			data[index + 1] = clampi(int((n.y * 0.5 + 0.5) * 255.0), 0, 255)
			data[index + 2] = clampi(int((n.z * 0.5 + 0.5) * 255.0), 0, 255)
			data[index + 3] = 255
	var image: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, data)
	image.generate_mipmaps()
	return image
