## The Chime-Shrine on Bramble-Bridge's village square (07_EXPEDITION_HUD_AND_ART_GDD.md
## §1.1; the pagoda of 17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4.2): a
## stone altar on an octagonal plinth under a carved cedar bell-frame and two
## tiers of mossy shingles, five graduated bronze carillon chimes (G, A, B, D,
## E) that swing and gleam Saffron-Gold whenever the party banks or spends
## Chimes, and a brass Chime turning in the air above an offering bowl. Walk up
## and press light to open the upgrade menu (HubUpgradeMenu) on your own screen
## and spend the party's Chimes. The shrine builds itself in code; players
## stand on its front side, local -Z.
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
## The shrine's pentatonic carillon harmonics, kept soft under the square (16 GDD §4.2).
const CARILLON_DB: float = -8.0
const COIN_SPIN: float = 1.4
const COIN_BOB: float = 2.0
const BELL_SWAY: float = 0.12
## The five carillon chimes' lengths, longest (G) to shortest (E), and how far apart they hang.
const CHIME_LENGTHS: Array[float] = [0.9, 0.8, 0.7, 0.6, 0.52]
const CHIME_SPACING: float = 0.42
const CHIME_SWING: float = 0.45
const CHIME_DAMPING: float = 1.6
const GLEAM_TIME: float = 1.6

## How many times the chimes have rung for banked or spent Chimes.
var rings: int = 0

var _coin: MeshInstance3D
var _bell: Node3D
var _chimes: Array[Node3D] = []
var _bronze: ShaderMaterial
var _swing: float = 0.0
var _gleam: float = 0.0
var _last_chimes: int = -1
var _sign: Label3D
var _age: float = 0.0


func _ready() -> void:
	# A glyph on the Wayfarer's map (CartographyBaker.GLYPH_GROUP, 18 GDD §7.2).
	add_to_group(&"map_glyphs")
	AudioDirector.attach_ambience(self, &"carillon", Vector3(0.0, COIN_HEIGHT, PLINTH_Z), CARILLON_DB)
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
	plinth.add_child(ShapeKit.box("Mesh", PLINTH_SIZE, Vector3.ZERO, WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE, STONE_COLOR, false, 0.3)))
	plinth.add_child(ShapeKit.box("Cap", PLINTH_SIZE + Vector3(0.16, -0.75, 0.16), Vector3(0.0, PLINTH_SIZE.y * 0.5, 0.0),
		WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.COBBLED_FLAGSTONE, WorldVisualCatalog.FLAGSTONE)))
	add_child(plinth)
	# The pagoda: its octagonal plinth, cedar bell-frame and shingled eaves.
	var pagoda: Node3D = WorldAssetCatalog.build(WorldVisualCatalog.KIT_CHIME_SHRINE_PAGODA, {"size": Vector3(ROOF_SIZE.x, POST_HEIGHT + 0.4, ROOF_SIZE.z)})
	pagoda.position = Vector3(0.0, 0.0, PLINTH_Z - 0.4)
	add_child(pagoda)
	# The five graduated chimes hang from the frame's beam and swing.
	_bell = Node3D.new()
	_bell.name = "Chimes"
	_bell.position = Vector3(0.0, POST_HEIGHT + 0.25, PLINTH_Z)
	add_child(_bell)
	_bronze = (WorldVisualCatalog.craft(-1, WorldAssetCatalog.BRONZE) as ShaderMaterial).duplicate() as ShaderMaterial
	for index: int in CHIME_LENGTHS.size():
		var chime: Node3D = Node3D.new()
		chime.name = "Chime%d" % (index + 1)
		chime.position = Vector3((float(index) - 2.0) * CHIME_SPACING, 0.0, 0.0)
		var tube: MeshInstance3D = MeshInstance3D.new()
		tube.name = "Tube"
		tube.mesh = WorldAssetCatalog.chime_mesh(CHIME_LENGTHS[index])
		tube.material_override = _bronze
		tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chime.add_child(tube)
		_bell.add_child(chime)
		_chimes.append(chime)
	# An offering bowl, and above it a brass Chime turning in its own glow.
	var bowl: MeshInstance3D = ShapeKit.cylinder("Bowl", 0.42, 0.42, 0.18, Vector3(0.0, PLINTH_SIZE.y + 0.09, PLINTH_Z), _material(BOWL_COLOR, 0.0))
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
	_sign.position = Vector3(0.0, POST_HEIGHT + ROOF_SIZE.y + 1.6, PLINTH_Z)
	add_child(_sign)
	_refresh_sign()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_age += delta
	_coin.rotate_y(COIN_SPIN * delta)
	_coin.position.y = COIN_HEIGHT + sin(_age * COIN_BOB) * 0.08
	_ring_on_change()
	_swing = move_toward(_swing, 0.0, CHIME_DAMPING * delta * maxf(_swing, 0.08))
	_gleam = maxf(0.0, _gleam - delta)
	for index: int in _chimes.size():
		var phase: float = _age * (1.1 + index * 0.17) + index * 0.9
		_chimes[index].rotation.z = sin(phase) * BELL_SWAY * 0.35 + sin(_age * 7.0 + index) * _swing
		_chimes[index].rotation.x = cos(phase * 0.8) * BELL_SWAY * 0.2
	var gleam: float = _gleam / GLEAM_TIME
	_bronze.set_shader_parameter(&"glow", Color(WorldVisualCatalog.WARM_HEARTH.r, WorldVisualCatalog.WARM_HEARTH.g, WorldVisualCatalog.WARM_HEARTH.b) * gleam * 1.8)
	_refresh_sign()


## Banking or spending Chimes swings the carillon and makes it gleam Saffron-Gold.
func _ring_on_change() -> void:
	var chimes: int = PartyProgress.current.chimes
	if _last_chimes >= 0 and chimes != _last_chimes:
		rings += 1
		_swing = CHIME_SWING
		_gleam = GLEAM_TIME
	_last_chimes = chimes


func prompt_for(actor: ActorBase) -> String:
	return "%s: Chime-Shrine (%d Chimes to spend)" % [actor.input.label(InputComponent.ACTION_LIGHT), PartyProgress.current.chimes]


func interact(actor: ActorBase) -> void:
	menu_requested.emit(actor)


func _refresh_sign() -> void:
	_sign.text = "Chime-Shrine\n%d Chimes" % PartyProgress.current.chimes


## The storybook cel look, or a glowing material when `glow` is above zero.
func _material(color: Color, glow: float) -> Material:
	return StorybookMaterial.glowing(color, glow) if glow > 0.0 else StorybookMaterial.make(color)
