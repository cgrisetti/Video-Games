## The look of a Chime (07_EXPEDITION_HUD_AND_ART_GDD.md §1.2): an octagonal
## brass wayfarer coin with a square hole through the middle, the party's
## currency. Builds the coin mesh once and shares it, with a warm brass material.
class_name ChimeCoin
extends RefCounted

const RADIUS: float = 0.5
const THICKNESS: float = 0.1
## Half the width of the square hole, as a share of the radius.
const HOLE_SHARE: float = 0.28
const BRASS_COLOR: Color = Color(0.93, 0.72, 0.32)
const BRASS_GLOW: float = 0.35

static var _mesh: ArrayMesh
static var _material: StandardMaterial3D


## A unit coin (radius 0.5) standing in the XY plane, its faces along ±Z. Scale it to size.
static func mesh() -> ArrayMesh:
	if _mesh == null:
		_mesh = _build_mesh()
	return _mesh


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = BRASS_COLOR
		_material.metallic = 0.85
		_material.roughness = 0.3
		_material.emission_enabled = true
		_material.emission = BRASS_COLOR
		_material.emission_energy_multiplier = BRASS_GLOW
		# The faces are wound by hand; draw both sides so none can vanish.
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _material


## A coin node ready to place: `size` is its width in metres.
static func make(size: float) -> MeshInstance3D:
	var coin: MeshInstance3D = MeshInstance3D.new()
	coin.name = "Chime"
	coin.mesh = mesh()
	coin.material_override = material()
	coin.scale = Vector3.ONE * (size / (RADIUS * 2.0))
	coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return coin


## An octagon ring around a square hole on both faces, the outer rim and the hole's walls.
static func _build_mesh() -> ArrayMesh:
	var outer: PackedVector2Array = PackedVector2Array()
	for index: int in 8:
		var angle: float = PI / 8.0 + TAU * float(index) / 8.0
		outer.append(Vector2(cos(angle), sin(angle)) * RADIUS)
	var hole: float = RADIUS * HOLE_SHARE
	var inner: PackedVector2Array = PackedVector2Array([Vector2(hole, hole), Vector2(-hole, hole), Vector2(-hole, -hole), Vector2(hole, -hole)])
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = THICKNESS * 0.5
	for face: float in [half, -half]:
		# Each hole corner k sits between octagon points 2k and 2k+1.
		for k: int in 4:
			var corner: Vector2 = inner[k]
			var next_corner: Vector2 = inner[(k + 1) % 4]
			_triangle(tool, corner, outer[2 * k], outer[2 * k + 1], face)
			_triangle(tool, corner, outer[2 * k + 1], outer[(2 * k + 2) % 8], face)
			_triangle(tool, corner, outer[(2 * k + 2) % 8], next_corner, face)
	for index: int in 8:
		_wall(tool, outer[index], outer[(index + 1) % 8], half)
	for index: int in 4:
		_wall(tool, inner[(index + 1) % 4], inner[index], half)
	tool.generate_normals()
	return tool.commit()


static func _triangle(tool: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, z: float) -> void:
	for point: Vector2 in [a, b, c]:
		tool.add_vertex(Vector3(point.x, point.y, z))


static func _wall(tool: SurfaceTool, a: Vector2, b: Vector2, half: float) -> void:
	var a_front: Vector3 = Vector3(a.x, a.y, half)
	var b_front: Vector3 = Vector3(b.x, b.y, half)
	var a_back: Vector3 = Vector3(a.x, a.y, -half)
	var b_back: Vector3 = Vector3(b.x, b.y, -half)
	for point: Vector3 in [a_front, a_back, b_back, a_front, b_back, b_front]:
		tool.add_vertex(point)
