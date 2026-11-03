## The Armory & Scribe Desk in Hub Town: a writing desk with an open Grimoire,
## a card stand of floating Scribe Cards and a seal circle on the floor, under
## an open-sided timber pavilion with the Scribe Press, four glowing inkwells
## and a weapon rack (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §4.2). Walk
## up and press light to open ScribeDeskMenu on your own screen and change
## your armor, weapon, lead cards and under-card links. The desk builds itself
## in code; players stand on its front side, local -Z.
class_name ScribeDesk
extends Interactable

signal menu_requested(actor: ActorBase)

const DESK_SIZE: Vector3 = Vector3(2.4, 0.9, 1.0)
const DESK_Z: float = 0.35
const LEG_SIZE: Vector3 = Vector3(0.1, 0.9, 0.1)
const BOOK_PAGE_SIZE: Vector3 = Vector3(0.42, 0.04, 0.56)
const BOOK_TILT: float = 0.18
const WOOD_COLOR: Color = Color(0.42, 0.27, 0.16)
const PAGE_COLOR: Color = Color(0.96, 0.92, 0.8)
## Three cards float and turn over the stand, in the Iron-Root, Rime-Gale and Star-Tide colours.
const STAND_CARD_COLORS: Array[Color] = [Color(0.93, 0.6, 0.22), Color(0.35, 0.72, 0.95), Color(0.6, 0.45, 0.95)]
const STAND_CARD_SIZE: Vector3 = Vector3(0.28, 0.4, 0.012)
const STAND_HEIGHT: float = 1.55
const STAND_SPIN: float = 0.8
const STAND_BOB: float = 1.7
const CANDLE_COLOR: Color = Color(1.0, 0.75, 0.4)
const RUNE_CIRCLE_RADIUS: float = 2.3
const RUNE_CIRCLE_COLOR: Color = Color(0.72, 0.55, 1.0, 0.35)

var _cards: Array[Node3D] = []
var _sign: Label3D
var _age: float = 0.0


func _ready() -> void:
	var desk: StaticBody3D = StaticBody3D.new()
	desk.name = "Desk"
	desk.position = Vector3(0.0, DESK_SIZE.y * 0.5, DESK_Z)
	desk.collision_layer = ActorBase.LAYER_WORLD
	desk.collision_mask = 0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = DESK_SIZE
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	desk.add_child(collision)
	var wood: Material = WorldVisualCatalog.craft(ProceduralTextureAtelier.Set.HEWN_TIMBER, WOOD_COLOR)
	var top_size: Vector3 = Vector3(DESK_SIZE.x, 0.08, DESK_SIZE.z)
	desk.add_child(ShapeKit.box("Top", top_size, Vector3(0.0, DESK_SIZE.y * 0.5 - 0.04, 0.0), wood))
	var leg_x: float = DESK_SIZE.x * 0.5 - 0.1
	var leg_z: float = DESK_SIZE.z * 0.5 - 0.1
	var legs: int = 0
	for side: float in [-1.0, 1.0]:
		for depth: float in [-1.0, 1.0]:
			legs += 1
			desk.add_child(ShapeKit.box("Leg%d" % legs, LEG_SIZE, Vector3(side * leg_x, -0.04, depth * leg_z), wood))
	add_child(desk)
	# The pavilion over it: posts, shingled roof, the Scribe Press, inkwells and the weapon rack.
	var pavilion: Node3D = WorldAssetCatalog.build(WorldVisualCatalog.KIT_SCRIBE_DESK_PAVILION, {"size": Vector3(4.4, 2.9, 3.0)})
	pavilion.position = Vector3(0.0, 0.0, DESK_Z - 0.35)
	add_child(pavilion)
	# An open Grimoire on the desk.
	var page: Material = _material(PAGE_COLOR, 0.0)
	for side: float in [-1.0, 1.0]:
		var leaf: MeshInstance3D = ShapeKit.box("Page", BOOK_PAGE_SIZE, Vector3(side * BOOK_PAGE_SIZE.x * 0.5, DESK_SIZE.y + 0.02, DESK_Z - 0.1), page)
		leaf.rotation = Vector3(0.0, 0.0, -side * BOOK_TILT)
		leaf.name = "PageLeft" if side < 0.0 else "PageRight"
		add_child(leaf)
	# A candle.
	add_child(ShapeKit.no_shadow(ShapeKit.cylinder("Candle", 0.05, 0.05, 0.22, Vector3(DESK_SIZE.x * 0.38, DESK_SIZE.y + 0.11, DESK_Z + 0.2), _material(PAGE_COLOR, 0.0), 12)))
	var flame: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.cylinder("Flame", 0.025, 0.025, 0.08, Vector3(DESK_SIZE.x * 0.38, DESK_SIZE.y + 0.27, DESK_Z + 0.2), _material(CANDLE_COLOR, 4.0), 12))
	(flame.mesh as CylinderMesh).top_radius = 0.0
	add_child(flame)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "CandleLight"
	light.light_color = CANDLE_COLOR
	light.light_energy = 1.0
	light.omni_range = 3.5
	light.position = Vector3(DESK_SIZE.x * 0.38, DESK_SIZE.y + 0.4, DESK_Z + 0.2)
	add_child(light)
	# Cards floating over the desk, turning slowly.
	for index: int in STAND_CARD_COLORS.size():
		var card: Node3D = Node3D.new()
		card.name = "StandCard%d" % index
		card.position = Vector3((float(index) - 1.0) * 0.45, STAND_HEIGHT, DESK_Z + 0.15)
		var vellum: MeshInstance3D = ShapeKit.box("Vellum", STAND_CARD_SIZE, Vector3.ZERO, _material(PAGE_COLOR, 0.0))
		card.add_child(vellum)
		var mark: MeshInstance3D = ShapeKit.box("Mark", Vector3(0.12, 0.12, 0.02), Vector3.ZERO, _material(STAND_CARD_COLORS[index], 2.5))
		mark.rotation = Vector3(0.0, 0.0, PI * 0.25)
		card.add_child(mark)
		add_child(card)
		_cards.append(card)
	# A faint rune circle where players stand.
	var circle_material: StandardMaterial3D = StorybookMaterial.glowing(RUNE_CIRCLE_COLOR, 1.5)
	circle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var circle: TorusMesh = TorusMesh.new()
	circle.inner_radius = RUNE_CIRCLE_RADIUS - 0.06
	circle.outer_radius = RUNE_CIRCLE_RADIUS
	circle.rings = 64
	circle.material = circle_material
	var circle_node: MeshInstance3D = MeshInstance3D.new()
	circle_node.name = "RuneCircle"
	circle_node.mesh = circle
	circle_node.position = Vector3(0.0, 0.03, -1.2)
	circle_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(circle_node)
	_sign = Label3D.new()
	_sign.name = "Sign"
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 46
	_sign.outline_size = 10
	_sign.pixel_size = 0.01
	_sign.modulate = Color(0.85, 0.75, 1.0)
	_sign.position = Vector3(0.0, 4.6, DESK_Z)
	add_child(_sign)
	_refresh_sign()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_age += delta
	for index: int in _cards.size():
		_cards[index].rotate_y(STAND_SPIN * delta * (1.0 if index % 2 == 0 else -1.0))
		_cards[index].position.y = STAND_HEIGHT + sin(_age * STAND_BOB + index) * 0.06
	_refresh_sign()


func prompt_for(actor: ActorBase) -> String:
	return "%s: Armory & Scribe Desk (Grimoire Lv %d)" % [actor.input.label(InputComponent.ACTION_LIGHT), PartyProgress.current.grimoire_level()]


func interact(actor: ActorBase) -> void:
	menu_requested.emit(actor)


func _refresh_sign() -> void:
	_sign.text = "Armory & Scribe Desk\nGrimoire Lv %d" % PartyProgress.current.grimoire_level()


## The storybook cel look, or a glowing material when `glow` is above zero.
func _material(color: Color, glow: float) -> Material:
	return StorybookMaterial.glowing(color, glow) if glow > 0.0 else StorybookMaterial.make(color)
