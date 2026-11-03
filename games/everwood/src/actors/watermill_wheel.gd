## Bramble-Bridge's watermill wheel (06_WORLD_AND_CALLINGS.md §1): a timber
## wheel with paddles, turning slowly in the canal. It builds itself in code
## and spins around its local Y axis; the level builder stands it on its side.
class_name WatermillWheel
extends Node3D

const RADIUS: float = 1.5
const THICKNESS: float = 0.45
const PADDLES: int = 10
const PADDLE_SIZE: Vector3 = Vector3(0.5, 0.55, 0.12)
const AXLE_RADIUS: float = 0.12
const AXLE_LENGTH: float = 1.4
const RIM_TUBE: float = 0.08
const WOOD_COLOR: Color = Color(0.4, 0.27, 0.16)
const IRON_COLOR: Color = Color(0.3, 0.3, 0.32)
## Radians per second.
const SPIN_SPEED: float = 0.55


func _ready() -> void:
	var wood: Material = _material(WOOD_COLOR)
	for side: float in [-1.0, 1.0]:
		var rim: TorusMesh = TorusMesh.new()
		rim.inner_radius = RADIUS - RIM_TUBE
		rim.outer_radius = RADIUS
		rim.material = wood
		var rim_node: MeshInstance3D = _mesh("Rim", rim)
		rim_node.position = Vector3(0.0, side * THICKNESS * 0.5, 0.0)
		add_child(rim_node)
	var axle: CylinderMesh = CylinderMesh.new()
	axle.top_radius = AXLE_RADIUS
	axle.bottom_radius = AXLE_RADIUS
	axle.height = AXLE_LENGTH
	axle.material = _material(IRON_COLOR)
	add_child(_mesh("Axle", axle))
	for index: int in PADDLES:
		var angle: float = TAU * float(index) / PADDLES
		var paddle: BoxMesh = BoxMesh.new()
		paddle.size = PADDLE_SIZE
		paddle.material = wood
		var paddle_node: MeshInstance3D = _mesh("Paddle%d" % index, paddle)
		# Paddles stand out from the rim like the spokes of a wheel.
		paddle_node.position = Vector3(cos(angle), 0.0, sin(angle)) * (RADIUS - PADDLE_SIZE.x * 0.3)
		paddle_node.rotation = Vector3(0.0, -angle, 0.0)
		add_child(paddle_node)
		var spoke: BoxMesh = BoxMesh.new()
		spoke.size = Vector3(RADIUS, 0.08, 0.08)
		spoke.material = wood
		var spoke_node: MeshInstance3D = _mesh("Spoke%d" % index, spoke)
		spoke_node.position = Vector3(cos(angle), 0.0, sin(angle)) * RADIUS * 0.5
		spoke_node.rotation = Vector3(0.0, -angle, 0.0)
		add_child(spoke_node)


func _process(delta: float) -> void:
	rotate_object_local(Vector3.UP, SPIN_SPEED * delta)


func _mesh(node_name: String, mesh: Mesh) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	return node


func _material(color: Color) -> Material:
	return StorybookMaterial.make(color)
