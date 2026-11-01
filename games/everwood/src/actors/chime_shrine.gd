## The Chime-Shrine on Bramblebridge's village square (07_EXPEDITION_HUD_AND_ART_GDD.md
## §1.1): a stone plinth under a little shingled roof, a bronze bell, and a
## brass Chime turning in the air above an offering bowl. Walk up and press
## light to open the upgrade menu (HubUpgradeMenu) on your own screen and spend
## the party's Chimes. The shrine builds itself in code; players stand on its
## front side, local -Z.
class_name ChimeShrine
extends Interactable

signal menu_requested(actor: ActorBase)

const PLINTH_SIZE: Vector3 = Vector3(2.6, 0.9, 1.3)
const PLINTH_Z: float = 0.35
const POST_HEIGHT: float = 3.0
const ROOF_SIZE: Vector3 = Vector3(3.4, 1.1, 2.4)
const STONE_COLOR: Color = Color(0.62, 0.6, 0.56)
const WOOD_COLOR: Color = Color(0.45, 0.3, 0.18)
const SHINGLE_COLOR: Color = Color(0.36, 0.42, 0.34)
const BELL_COLOR: Color = Color(0.7, 0.5, 0.25)
const BOWL_COLOR: Color = Color(0.5, 0.38, 0.26)
const GLOW_COLOR: Color = Color(1.0, 0.82, 0.45)
const COIN_SIZE: float = 0.5
const COIN_HEIGHT: float = 1.75
const COIN_SPIN: float = 1.4
const COIN_BOB: float = 2.0
const BELL_SWAY: float = 0.12

var _coin: MeshInstance3D
var _bell: Node3D
var _sign: Label3D
var _age: float = 0.0


func _ready() -> void:
	var plinth: StaticBody3D = StaticBody3D.new()
	plinth.name = "Plinth"
	plinth.position = Vector3(0.0, PLINTH_SIZE.y * 0.5, PLINTH_Z)
	plinth.collision_layer = ActorBase.LAYER_WORLD
	plinth.collision_mask = 0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = PLINTH_SIZE
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	plinth.add_child(collision)
	plinth.add_child(_box("Mesh", PLINTH_SIZE, Vector3.ZERO, _material(STONE_COLOR, 0.0)))
	plinth.add_child(_box("Cap", PLINTH_SIZE + Vector3(0.16, -0.75, 0.16), Vector3(0.0, PLINTH_SIZE.y * 0.5, 0.0), _material(STONE_COLOR.darkened(0.15), 0.0)))
	add_child(plinth)
	var post_x: float = ROOF_SIZE.x * 0.5 - 0.25
	var posts: int = 0
	for side: float in [-1.0, 1.0]:
		posts += 1
		add_child(_cylinder("Post%d" % posts, 0.09, POST_HEIGHT, Vector3(side * post_x, POST_HEIGHT * 0.5, PLINTH_Z + 0.4), _material(WOOD_COLOR, 0.0)))
	add_child(_box("Beam", Vector3(ROOF_SIZE.x - 0.2, 0.16, 0.16), Vector3(0.0, POST_HEIGHT - 0.1, PLINTH_Z + 0.4), _material(WOOD_COLOR, 0.0)))
	# A little gabled roof of mossy shingles.
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = ROOF_SIZE
	roof_mesh.material = _material(SHINGLE_COLOR, 0.0)
	var roof: MeshInstance3D = MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = roof_mesh
	roof.position = Vector3(0.0, POST_HEIGHT + ROOF_SIZE.y * 0.5, PLINTH_Z + 0.4)
	add_child(roof)
	# The bronze bell hangs from the beam and sways.
	_bell = Node3D.new()
	_bell.name = "Bell"
	_bell.position = Vector3(post_x - 0.55, POST_HEIGHT - 0.2, PLINTH_Z + 0.4)
	add_child(_bell)
	var bell: MeshInstance3D = _cylinder("Cup", 0.26, 0.42, Vector3(0.0, -0.3, 0.0), _material(BELL_COLOR, 0.15))
	(bell.mesh as CylinderMesh).top_radius = 0.1
	_bell.add_child(bell)
	_bell.add_child(_cylinder("Clapper", 0.04, 0.2, Vector3(0.0, -0.55, 0.0), _material(BELL_COLOR.darkened(0.4), 0.0)))
	# An offering bowl, and above it a brass Chime turning in its own glow.
	var bowl: MeshInstance3D = _cylinder("Bowl", 0.42, 0.18, Vector3(0.0, PLINTH_SIZE.y + 0.09, PLINTH_Z), _material(BOWL_COLOR, 0.0))
	(bowl.mesh as CylinderMesh).bottom_radius = 0.26
	add_child(bowl)
	_coin = ChimeCoin.make(COIN_SIZE)
	_coin.position = Vector3(0.0, COIN_HEIGHT, PLINTH_Z)
	add_child(_coin)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = GLOW_COLOR
	glow.light_energy = 1.2
	glow.omni_range = 4.0
	glow.position = Vector3(0.0, COIN_HEIGHT, PLINTH_Z - 0.6)
	add_child(glow)
	_sign = Label3D.new()
	_sign.name = "Sign"
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 48
	_sign.outline_size = 10
	_sign.pixel_size = 0.01
	_sign.modulate = GLOW_COLOR.lightened(0.3)
	_sign.position = Vector3(0.0, POST_HEIGHT + ROOF_SIZE.y + 0.7, PLINTH_Z)
	add_child(_sign)
	_refresh_sign()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_age += delta
	_coin.rotate_y(COIN_SPIN * delta)
	_coin.position.y = COIN_HEIGHT + sin(_age * COIN_BOB) * 0.08
	_bell.rotation.z = sin(_age * 1.3) * BELL_SWAY
	_refresh_sign()


func prompt_for(actor: ActorBase) -> String:
	return "%s: Chime-Shrine (%d Chimes to spend)" % [actor.input.label(InputComponent.ACTION_LIGHT), PartyProgress.current.chimes]


func interact(actor: ActorBase) -> void:
	menu_requested.emit(actor)


func _refresh_sign() -> void:
	_sign.text = "Chime-Shrine\n%d Chimes" % PartyProgress.current.chimes


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


## The storybook cel look, or a glowing material when `glow` is above zero.
func _material(color: Color, glow: float) -> Material:
	return StorybookMaterial.glowing(color, glow) if glow > 0.0 else StorybookMaterial.make(color)
