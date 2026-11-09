## The Recovery burst (docs/28 §3.5; Tolkien's Recovery, seeing a familiar thing
## clearly again): when a foe is calmed, a watercolour ring races out over the
## grey grass, leaving it green with a wet, ragged edge, and buttercups and
## daisies pop up as the edge passes. A short effect, built from flat discs.
class_name RecoveryBurst
extends Node3D

const GROW_TIME: float = 0.5
const LINGER_TIME: float = 1.0
const FLOWERS: int = 10
const WASH: Color = Color(0.46, 0.78, 0.34, 0.55)
const EDGE: Color = Color(0.32, 0.62, 0.22, 0.8)
const PETALS: Array[Color] = [Color(1.0, 0.86, 0.3), Color(0.98, 0.97, 0.92), Color(0.96, 0.62, 0.74)]

var radius: float = 6.0
var _age: float = 0.0
var _wash: MeshInstance3D
var _edge: MeshInstance3D
var _wash_material: StandardMaterial3D
var _edge_material: StandardMaterial3D
var _flowers: Array[MeshInstance3D] = []


## Blooms a burst on the ground at `at` under `holder`.
static func bloom(holder: Node, at: Vector3, burst_radius: float) -> RecoveryBurst:
	var burst: RecoveryBurst = RecoveryBurst.new()
	burst.name = "RecoveryBurst"
	burst.radius = burst_radius
	holder.add_child(burst)
	burst.global_position = at + Vector3(0.0, 0.06, 0.0)
	return burst


func _ready() -> void:
	_wash_material = _material(WASH)
	_edge_material = _material(EDGE)
	_wash = _disc("Wash", 1.0, 0.02, _wash_material)
	_edge = MeshInstance3D.new()
	_edge.name = "Edge"
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.92
	ring.outer_radius = 1.0
	ring.rings = 24
	ring.ring_segments = 6
	_edge.mesh = ring
	_edge.material_override = _edge_material
	_edge.scale = Vector3(1.0, 0.04, 1.0)
	_edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_edge)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(global_position)
	for index: int in FLOWERS:
		var angle: float = rng.randf() * TAU
		var out: float = rng.randf_range(0.3, 0.95) * radius
		var flower: MeshInstance3D = _disc("Flower%d" % index, 0.09, 0.03, _material(PETALS[index % PETALS.size()]))
		flower.position = Vector3(cos(angle) * out, 0.05, sin(angle) * out)
		flower.visible = false
		_flowers.append(flower)
	_apply(0.0)


func _process(delta: float) -> void:
	_age += delta
	_apply(_age)
	if _age >= GROW_TIME + LINGER_TIME:
		queue_free()


func _apply(age: float) -> void:
	var grown: float = clampf(age / GROW_TIME, 0.0, 1.0)
	var reach: float = maxf(0.05, radius * (1.0 - pow(1.0 - grown, 3.0)))
	_wash.scale = Vector3(reach, 1.0, reach)
	_edge.scale = Vector3(reach, 0.04, reach)
	var fade: float = 1.0 - clampf((age - GROW_TIME) / LINGER_TIME, 0.0, 1.0)
	_wash_material.albedo_color.a = WASH.a * fade
	_edge_material.albedo_color.a = EDGE.a * fade
	for flower: MeshInstance3D in _flowers:
		flower.visible = Vector2(flower.position.x, flower.position.z).length() <= reach and fade > 0.05


func _disc(node_name: String, disc_radius: float, height: float, material: Material) -> MeshInstance3D:
	var made: MeshInstance3D = MeshInstance3D.new()
	made.name = node_name
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = disc_radius
	mesh.bottom_radius = disc_radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.rings = 1
	made.mesh = mesh
	made.material_override = material
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(made)
	return made


static func _material(color: Color) -> StandardMaterial3D:
	var made: StandardMaterial3D = StandardMaterial3D.new()
	made.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	made.albedo_color = color
	made.no_depth_test = false
	return made
