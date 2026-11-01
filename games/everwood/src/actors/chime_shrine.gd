## The Shard Vendor's stall in Hub Town: a counter under a striped awning, a
## shopkeeper and a floating Dojo Shard. Walk up and press light to open the
## upgrade menu (HubUpgradeMenu) on your own screen. The stall builds itself in
## code; players stand on its front side, local -Z.
class_name ShardVendor
extends Interactable

signal menu_requested(actor: ActorBase)

const COUNTER_SIZE: Vector3 = Vector3(3.0, 1.0, 0.9)
const COUNTER_Z: float = 0.3
const POST_HEIGHT: float = 2.8
const AWNING_SIZE: Vector3 = Vector3(3.6, 0.12, 2.2)
const AWNING_STRIPES: int = 6
const AWNING_TILT: float = 0.18
const WOOD_COLOR: Color = Color(0.5, 0.34, 0.2)
const AWNING_COLORS: Array[Color] = [Color(0.55, 0.5, 1.0), Color(0.95, 0.93, 0.88)]
const KEEPER_COLOR: Color = Color(0.6, 0.45, 0.85)
const SHARD_COLOR: Color = Color(0.55, 0.85, 1.0)
const SHARD_HEIGHT: float = 1.55
const SHARD_SPIN: float = 1.2
const SHARD_BOB: float = 2.0

var _shard: MeshInstance3D
var _sign: Label3D
var _age: float = 0.0


func _ready() -> void:
	var counter: StaticBody3D = StaticBody3D.new()
	counter.name = "Counter"
	counter.position = Vector3(0.0, COUNTER_SIZE.y * 0.5, COUNTER_Z)
	counter.collision_layer = ActorBase.LAYER_WORLD
	counter.collision_mask = 0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = COUNTER_SIZE
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	counter.add_child(collision)
	counter.add_child(_box("Mesh", COUNTER_SIZE, Vector3.ZERO, _material(WOOD_COLOR, 0.0)))
	counter.add_child(_box("Top", COUNTER_SIZE + Vector3(0.12, -0.9, 0.12), Vector3(0.0, COUNTER_SIZE.y * 0.5, 0.0), _material(WOOD_COLOR.darkened(0.35), 0.0)))
	add_child(counter)
	var post_x: float = AWNING_SIZE.x * 0.5 - 0.15
	var posts: int = 0
	for side: float in [-1.0, 1.0]:
		for depth: float in [COUNTER_Z - 0.55, COUNTER_Z + 1.1]:
			posts += 1
			add_child(_cylinder("Post%d" % posts, 0.07, POST_HEIGHT, Vector3(side * post_x, POST_HEIGHT * 0.5, depth), _material(WOOD_COLOR, 0.0)))
	var awning: Node3D = Node3D.new()
	awning.name = "Awning"
	awning.position = Vector3(0.0, POST_HEIGHT, COUNTER_Z + 0.27)
	awning.rotation = Vector3(-AWNING_TILT, 0.0, 0.0)
	add_child(awning)
	var stripe_width: float = AWNING_SIZE.x / AWNING_STRIPES
	for index: int in AWNING_STRIPES:
		var x: float = -AWNING_SIZE.x * 0.5 + stripe_width * (index + 0.5)
		awning.add_child(_box("Stripe%d" % index, Vector3(stripe_width, AWNING_SIZE.y, AWNING_SIZE.z), Vector3(x, 0.0, 0.0),
			_material(AWNING_COLORS[index % AWNING_COLORS.size()], 0.0)))
	# The shopkeeper stands behind the counter in a pointed hat.
	add_child(_cylinder("Keeper", 0.35, 1.6, Vector3(0.0, 0.8, COUNTER_Z + 0.85), _material(KEEPER_COLOR, 0.0)))
	var hat: MeshInstance3D = _cylinder("Hat", 0.4, 0.7, Vector3(0.0, 1.95, COUNTER_Z + 0.85), _material(KEEPER_COLOR.darkened(0.4), 0.0))
	(hat.mesh as CylinderMesh).top_radius = 0.0
	add_child(hat)
	_shard = _box("Shard", Vector3(0.3, 0.3, 0.3), Vector3(0.0, SHARD_HEIGHT, COUNTER_Z), _material(SHARD_COLOR, 2.5))
	_shard.rotation = Vector3(PI * 0.25, 0.0, PI * 0.25)
	add_child(_shard)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = SHARD_COLOR
	glow.light_energy = 1.2
	glow.omni_range = 4.0
	glow.position = Vector3(0.0, SHARD_HEIGHT, COUNTER_Z - 0.6)
	add_child(glow)
	_sign = Label3D.new()
	_sign.name = "Sign"
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 48
	_sign.outline_size = 10
	_sign.pixel_size = 0.01
	_sign.modulate = SHARD_COLOR.lightened(0.4)
	_sign.position = Vector3(0.0, POST_HEIGHT + 0.9, COUNTER_Z)
	add_child(_sign)
	_refresh_sign()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_age += delta
	_shard.rotate_y(SHARD_SPIN * delta)
	_shard.position.y = SHARD_HEIGHT + sin(_age * SHARD_BOB) * 0.08
	_refresh_sign()


func prompt_for(actor: ActorBase) -> String:
	return "%s: Shard Vendor (%d Dojo Shards to spend)" % [actor.input.label(InputComponent.ACTION_LIGHT), PartyProgress.current.shards]


func interact(actor: ActorBase) -> void:
	menu_requested.emit(actor)


func _refresh_sign() -> void:
	_sign.text = "Shard Vendor\n%d Dojo Shards" % PartyProgress.current.shards


func _box(box_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var box: MeshInstance3D = MeshInstance3D.new()
	box.name = box_name
	box.mesh = mesh
	box.position = where
	return box


func _cylinder(cylinder_name: String, radius: float, height: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.material = material
	var cylinder: MeshInstance3D = MeshInstance3D.new()
	cylinder.name = cylinder_name
	cylinder.mesh = mesh
	cylinder.position = where
	return cylinder


func _material(color: Color, glow: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material
