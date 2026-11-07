## Ring 3 of the draw distance (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §6.1): a
## 360-degree painter's horizon from 0.9 to 2.3 km round the party, three
## ridgelines deep, hazing toward the sky's horizon colour with distance, with
## the Six-Zone Stewardship Atlas on it: (north) the cataract mist of
## Sunken-Crown-Falls and the Doverslap Mill-Castle; (west) the granite tors
## of Barrow-Crag-Crossing; (east) the golden hills and windmills of
## Barley-Bridge-Meadow; (south) the white chalk cliffs and sea-stacks of
## Gull-Wick-Haven. One mesh, one draw call, unlit and outside the fog (it
## paints its own haze); it never loads a far zone. The WorldAtmosphereDirector
## keeps it centred on the party and tints its haze. North is -Z, as on the trail.
class_name HorizonVistaRing
extends Node3D

const SEGMENTS: int = 192
## The three ridgelines' distances (m) and how much of the sky's haze each takes.
const LAYER_RADII: Array[float] = [900.0, 1500.0, 2250.0]
const LAYER_HAZE: Array[float] = [0.32, 0.52, 0.72]
## How far below the party the ring's foot sits (so its foot is always under the horizon).
const DROP: float = 60.0
const NEAR_GREEN: Color = Color(0.3, 0.44, 0.3)
const MID_BLUE: Color = Color(0.36, 0.46, 0.5)
const FAR_BLUE: Color = Color(0.5, 0.58, 0.66)
const GOLDEN: Color = Color(0.74, 0.64, 0.34)
const CHALK: Color = Color(0.93, 0.91, 0.85)
const GRANITE: Color = Color(0.46, 0.48, 0.53)
const MIST: Color = Color(0.95, 0.97, 1.0)
const CASTLE: Color = Color(0.4, 0.38, 0.42)
const SHADER_CODE: String = """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, shadows_disabled;
uniform vec4 haze_color : source_color = vec4(0.96, 0.89, 0.77, 1.0);
void fragment() {
	ALBEDO = mix(COLOR.rgb, haze_color.rgb, COLOR.a);
}
"""

var _material: ShaderMaterial


func _ready() -> void:
	var shader: Shader = Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	var shape: MeshInstance3D = MeshInstance3D.new()
	shape.name = "Ridgelines"
	shape.mesh = build_mesh()
	shape.material_override = _material
	shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shape.extra_cull_margin = 4000.0
	shape.ignore_occlusion_culling = true
	add_child(shape)


## Centres the ring on the party (its foot below their feet).
func follow(party: Vector3) -> void:
	global_position = Vector3(party.x, party.y - DROP, party.z)


func set_tint(horizon: Color, _fog: Color) -> void:
	if _material != null:
		_material.set_shader_parameter(&"haze_color", horizon)


## The landmarks' bearings, clockwise from north (tests read these).
static func landmark_bearings() -> Dictionary[StringName, float]:
	return {&"sunken_crown_falls": 0.0, &"barley_bridge_meadow": 90.0, &"gull_wick_haven": 180.0, &"barrow_crag_crossing": 270.0}


static func build_mesh() -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var normals: PackedVector3Array = PackedVector3Array()
	for layer: int in LAYER_RADII.size():
		var radius: float = LAYER_RADII[layer]
		for index: int in SEGMENTS:
			var a: float = TAU * float(index) / SEGMENTS
			var b: float = TAU * float(index + 1) / SEGMENTS
			var top_a: float = _ridge(a, layer)
			var top_b: float = _ridge(b, layer)
			var color_a: Color = _color(a, layer)
			var color_b: Color = _color(b, layer)
			_quad(vertices, colors, normals, _at(a, radius, -DROP), _at(b, radius, -DROP), _at(b, radius, top_b), _at(a, radius, top_a),
				color_a.darkened(0.12), color_b.darkened(0.12), color_b, color_a, LAYER_HAZE[layer])
	_landmarks(vertices, colors, normals)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## A ridgeline's height (above the ring's foot) at bearing `a`.
static func _ridge(a: float, layer: int) -> float:
	var degrees: float = rad_to_deg(a)
	var base: float = DROP + [26.0, 70.0, 150.0][layer]
	var rolling: float = sin(a * 5.0 + layer * 1.7) * 14.0 + sin(a * 13.0 + layer) * 6.0 + sin(a * 29.0 + layer * 2.3) * 2.5
	var height: float = base + rolling * (1.0 + layer * 0.8)
	# East: Barley-Bridge-Meadow's soft golden hills (low and rounded).
	height -= _near(degrees, 90.0, 40.0) * (14.0 + layer * 20.0)
	# West: Barrow-Crag-Crossing's granite tors (jagged, on the middle ridge).
	if layer == 1:
		var tors: float = _near(degrees, 270.0, 28.0)
		height += tors * (60.0 + absf(sin(a * 41.0)) * 70.0)
	# South: Gull-Wick-Haven's chalk cliffs (a flat top falling sheer to the sea).
	if layer == 1:
		var cliff: float = _near(degrees, 180.0, 22.0)
		height = lerpf(height, DROP + 92.0, smoothstep(0.0, 0.25, cliff))
	# North: the Great Cataract's notch in the far range, and the high peaks round it.
	if layer == 2:
		height += _near(degrees, 0.0, 30.0) * 140.0 - _near(degrees, 0.0, 4.0) * 120.0
	return height


static func _color(a: float, layer: int) -> Color:
	var degrees: float = rad_to_deg(a)
	var color: Color = [NEAR_GREEN, MID_BLUE, FAR_BLUE][layer]
	color = color.lerp(GOLDEN, _near(degrees, 90.0, 45.0) * (0.85 if layer == 0 else 0.5))
	color = color.lerp(GRANITE, _near(degrees, 270.0, 32.0) * 0.8)
	if layer == 1:
		color = color.lerp(CHALK, smoothstep(0.0, 0.3, _near(degrees, 180.0, 22.0)))
	return color


## 1 at `center` degrees, falling to 0 `width` degrees away.
static func _near(degrees: float, center: float, width: float) -> float:
	var gap: float = absf(wrapf(degrees - center, -180.0, 180.0))
	return clampf(1.0 - gap / width, 0.0, 1.0)


static func _at(a: float, radius: float, height: float) -> Vector3:
	return Vector3(sin(a) * radius, height, -cos(a) * radius)


## A quad p0-p1 (its foot) to p2-p3 (its top); `top_haze` (when not negative) hazes its top differently, so a plume melts into the sky.
static func _quad(vertices: PackedVector3Array, colors: PackedColorArray, normals: PackedVector3Array,
		p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c0: Color, c1: Color, c2: Color, c3: Color, haze: float, top_haze: float = -1.0) -> void:
	var facing: Vector3 = -Vector3(p0.x + p1.x, 0.0, p0.z + p1.z).normalized()
	var high: float = haze if top_haze < 0.0 else top_haze
	for entry: Array in [[p0, c0, haze], [p1, c1, haze], [p2, c2, high], [p0, c0, haze], [p2, c2, high], [p3, c3, high]]:
		vertices.append(entry[0])
		var color: Color = entry[1]
		colors.append(Color(color.r, color.g, color.b, entry[2]))
		normals.append(facing)


## The atlas's landmarks standing on the ridgelines.
static func _landmarks(vertices: PackedVector3Array, colors: PackedColorArray, normals: PackedVector3Array) -> void:
	# North: Sunken-Crown-Falls' cataract mist billowing out of the notch and melting into the sky.
	var far: float = LAYER_RADII[2] - 20.0
	for column: int in 7:
		var spread: float = (float(column) - 3.0) * 1.1
		var a: float = deg_to_rad(spread - 0.9)
		var b: float = deg_to_rad(spread + 0.9)
		var top: float = DROP + 330.0 - absf(spread) * 45.0 + sin(column * 1.7) * 25.0
		var narrow: float = deg_to_rad(spread * 0.6)
		_quad(vertices, colors, normals, _at(a, far, DROP + 60.0), _at(b, far, DROP + 60.0), _at(narrow + 0.012, far, top), _at(narrow - 0.012, far, top),
			MIST, MIST, MIST, MIST, 0.3, 0.92)
	# North-west of it, the Doverslap Mill-Castle: a keep and two towers on the middle ridge.
	var mid: float = LAYER_RADII[1] - 15.0
	for tower: Array in [[-14.0, -12.5, 150.0], [-12.0, -9.0, 120.0], [-8.5, -7.0, 160.0]]:
		var a: float = deg_to_rad(tower[0])
		var b: float = deg_to_rad(tower[1])
		var top: float = DROP + float(tower[2])
		_quad(vertices, colors, normals, _at(a, mid, DROP), _at(b, mid, DROP), _at(b, mid, top), _at(a, mid, top), CASTLE, CASTLE, CASTLE, CASTLE, 0.5)
		var peak: Vector3 = _at((a + b) * 0.5, mid, top + 26.0)
		for corner: Array in [[_at(a, mid, top), _at(b, mid, top), peak]]:
			for point: Vector3 in corner:
				vertices.append(point)
				colors.append(Color(CASTLE.darkened(0.2), 0.5))
				normals.append(-Vector3(point.x, 0.0, point.z).normalized())
	# South: sea-stacks off the chalk cliffs.
	for stack: Array in [[192.0, 1.6, 70.0], [197.0, 1.0, 54.0], [166.0, 1.3, 62.0]]:
		var a: float = deg_to_rad(stack[0])
		var b: float = deg_to_rad(float(stack[0]) + float(stack[1]))
		var top: float = DROP + float(stack[2])
		var r: float = LAYER_RADII[1] - 120.0
		_quad(vertices, colors, normals, _at(a, r, DROP), _at(b, r, DROP), _at(b, r, top), _at(a, r, top), CHALK, CHALK, CHALK, CHALK, 0.42)
	# East: windmills on the golden hills, their four sails turned to the wind.
	var near: float = LAYER_RADII[0] - 10.0
	for mill: float in [78.0, 94.0, 108.0]:
		var a: float = deg_to_rad(mill)
		var base_height: float = _ridge(a, 0)
		var foot: Vector3 = _at(a, near, base_height - 4.0)
		var side: Vector3 = Vector3(cos(a), 0.0, sin(a))
		var top: Vector3 = foot + Vector3(0.0, 34.0, 0.0)
		var tower_color: Color = Color(0.86, 0.82, 0.74)
		_quad(vertices, colors, normals, foot - side * 5.0, foot + side * 5.0, top + side * 2.5, top - side * 2.5,
			tower_color, tower_color, tower_color, tower_color, 0.3)
		for blade: int in 4:
			var angle: float = PI * 0.25 + blade * PI * 0.5
			var reach: Vector3 = side * cos(angle) * 22.0 + Vector3(0.0, sin(angle) * 22.0, 0.0)
			var width: Vector3 = side * -sin(angle) * 3.0 + Vector3(0.0, cos(angle) * 3.0, 0.0)
			var sail: Color = Color(0.8, 0.74, 0.62)
			_quad(vertices, colors, normals, top - width, top + width, top + reach + width, top + reach - width, sail, sail, sail, sail, 0.3)
