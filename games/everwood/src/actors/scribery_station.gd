## The Reed-Light Scribery (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §6), Bramble-Bridge's
## Grimoire shop on the village square: an open timber pavilion under a
## stepped-gable roof, a brass-and-oak Vellum Press-Wheel turning beside the
## counter, and four Deep-Ink Vat Lanterns along the back, each glowing in one
## Sign's colour (Iron-Root amber, Rime-Gale sea-azure, Warm-Hearth saffron,
## Star-Tide violet). Walk up and press light to open ScriberyShopPanel on your
## own screen: inscribe Action-Leaves, chart Place-Cards, and gild them.
##
## It builds itself in code and stays under 3.0 m, inside the 3.2 m sightline
## cap for the 4.8 m split-screen camera (Gate 5); its posts, counter and vats
## sit on the LowScenery layer, so cameras look past them. Players stand on
## its front side, local -Z.
class_name ScriberyStation
extends Interactable

const DECK_SIZE: Vector3 = Vector3(4.6, 0.06, 3.6)
const POST_SIZE: Vector3 = Vector3(0.18, 2.0, 0.18)
const EAVE_HEIGHT: float = 2.0
const RIDGE_HEIGHT: float = 2.5
## The crow-stepped gables rise above the roof to here, the tallest thing (the cap is 3.0 m).
const GABLE_TOP: float = 2.92
const COPING_SIZE: Vector2 = Vector2(0.06, 0.2)
const ROOF_OVERHANG: float = 0.25
const ROOF_THICKNESS: float = 0.08
const GABLE_STEPS: int = 4
const GABLE_THICKNESS: float = 0.12
const COUNTER_SIZE: Vector3 = Vector3(2.8, 0.95, 0.55)
const COUNTER_Z: float = -1.05
## The Vellum Press-Wheel: a brass rim and oak spokes on a stand, turning on its axle.
const WHEEL_CENTER: Vector3 = Vector3(1.55, 1.25, -0.1)
const WHEEL_RADIUS: float = 0.55
const WHEEL_SPOKES: int = 6
const WHEEL_SPIN: float = 0.9
## The four vats along the back, in Sign order, and their hanging lanterns.
const VAT_XS: Array[float] = [-1.65, -0.55, 0.55, 1.65]
const VAT_Z: float = 1.25
const VAT_RADIUS: float = 0.3
const VAT_HEIGHT: float = 0.62
const LANTERN_HEIGHT: float = 1.7
const LANTERN_SIZE: float = 0.2
const LANTERN_ENERGY: float = 0.9
const LANTERN_RANGE: float = 3.2
const SIGN_ORDER: Array[int] = [ScribeSignResource.Sign.SIGN_IRON_ROOT, ScribeSignResource.Sign.SIGN_RIME_GALE,
	ScribeSignResource.Sign.SIGN_WARM_HEARTH, ScribeSignResource.Sign.SIGN_STAR_TIDE]
const OAK_COLOR: Color = Color(0.42, 0.28, 0.17)
const TIMBER_COLOR: Color = Color(0.5, 0.35, 0.22)
const COPING_COLOR: Color = Color(0.36, 0.24, 0.15)
const PLASTER_COLOR: Color = Color(0.9, 0.84, 0.72)
const ROOF_COLOR: Color = Color(0.36, 0.42, 0.55)
const BRASS_COLOR: Color = Color(0.86, 0.66, 0.3)
const VELLUM_COLOR: Color = Color(0.96, 0.92, 0.8)
const SIGN_TEXT_COLOR: Color = Color(0.75, 0.88, 1.0)
const SIGN_HEIGHT: float = 2.55
## A faint ring of reed-light where players stand.
const STAND_RING_RADIUS: float = 1.6
const STAND_RING_Z: float = -2.4
const STAND_RING_COLOR: Color = Color(0.55, 0.8, 1.0, 0.35)

var _wheel: Node3D


func _ready() -> void:
	reach = 3.4
	var oak: Material = StorybookMaterial.make(OAK_COLOR)
	var timber: Material = StorybookMaterial.make(TIMBER_COLOR)
	add_child(ShapeKit.box("Deck", DECK_SIZE, Vector3(0.0, DECK_SIZE.y * 0.5, 0.0), timber))
	var frame: StaticBody3D = _low_body("Frame")
	var half: Vector2 = Vector2(DECK_SIZE.x * 0.5 - POST_SIZE.x * 0.5, DECK_SIZE.z * 0.5 - POST_SIZE.z * 0.5)
	var posts: int = 0
	for side: float in [-1.0, 1.0]:
		for depth: float in [-1.0, 1.0]:
			posts += 1
			_solid(frame, "Post%d" % posts, POST_SIZE, Vector3(side * half.x, POST_SIZE.y * 0.5, depth * half.y), oak)
	_build_roof()
	_build_counter(frame)
	_build_press_wheel(oak)
	_build_vats(frame, oak)
	_build_stand_ring()
	var sign_label: Label3D = Label3D.new()
	sign_label.name = "Sign"
	sign_label.text = "The Reed-Light Scribery\nAction-Leaves · Place-Cards · Gilding"
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.font_size = 40
	sign_label.outline_size = 10
	sign_label.pixel_size = 0.01
	sign_label.modulate = SIGN_TEXT_COLOR
	sign_label.position = Vector3(0.0, SIGN_HEIGHT, -DECK_SIZE.z * 0.5 - 0.3)
	add_child(sign_label)


func _process(delta: float) -> void:
	if is_instance_valid(_wheel):
		_wheel.rotate_object_local(Vector3.FORWARD, WHEEL_SPIN * delta)


func prompt_for(actor: ActorBase) -> String:
	return "%s: The Reed-Light Scribery (Action-Leaves, Place-Cards, the Gilding Press)" % actor.input.label(InputComponent.ACTION_LIGHT)


## Opens the counter on the player's own screen.
func interact(actor: ActorBase) -> void:
	var hud: PlayerHUD = PlayerHUD.for_actor(get_tree(), actor)
	if hud != null:
		hud.open_scribery_shop()


## The highest point of everything drawn here, in metres above its feet (the sightline check).
func tallest_point() -> float:
	var top: float = 0.0
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var shape: MeshInstance3D = node as MeshInstance3D
		if shape.mesh != null:
			top = maxf(top, (shape.global_transform * shape.mesh.get_aabb()).end.y - global_position.y)
	return top


## Two slate-blue slopes meeting at the ridge, which runs front to back, and a
## crow-stepped gable at the front and the back standing well above them, each
## step capped in dark timber.
func _build_roof() -> void:
	var slate: Material = StorybookMaterial.make(ROOF_COLOR)
	var plaster: Material = StorybookMaterial.make(PLASTER_COLOR)
	var run: float = DECK_SIZE.x * 0.5 + ROOF_OVERHANG
	var rise: float = RIDGE_HEIGHT - ROOF_THICKNESS - EAVE_HEIGHT
	var slope: float = atan2(rise, run)
	var length: float = sqrt(run * run + rise * rise)
	for side: float in [-1.0, 1.0]:
		var slab: MeshInstance3D = ShapeKit.box("Roof%s" % ("Left" if side < 0.0 else "Right"), Vector3(length, ROOF_THICKNESS, DECK_SIZE.z + ROOF_OVERHANG * 2.0),
			Vector3(side * run * 0.5, EAVE_HEIGHT + rise * 0.5, 0.0), slate)
		slab.rotation = Vector3(0.0, 0.0, -side * slope)
		add_child(slab)
	var coping: Material = StorybookMaterial.make(COPING_COLOR)
	var step_height: float = (GABLE_TOP - COPING_SIZE.x - EAVE_HEIGHT) / GABLE_STEPS
	for depth: float in [-1.0, 1.0]:
		var face: String = "Front" if depth < 0.0 else "Back"
		var z: float = depth * (DECK_SIZE.z * 0.5 - GABLE_THICKNESS * 0.5)
		for step: int in GABLE_STEPS:
			var width: float = DECK_SIZE.x * (1.0 - float(step) / GABLE_STEPS)
			var top: float = EAVE_HEIGHT + step_height * (step + 1)
			add_child(ShapeKit.box("Gable%s%d" % [face, step], Vector3(width, step_height, GABLE_THICKNESS),
				Vector3(0.0, top - step_height * 0.5, z), plaster))
			add_child(ShapeKit.box("Coping%s%d" % [face, step], Vector3(width + 0.08, COPING_SIZE.x, COPING_SIZE.y),
				Vector3(0.0, top + COPING_SIZE.x * 0.5, z), coping))


## The counter at the front, with ink pots and a fresh sheet of vellum.
func _build_counter(frame: StaticBody3D) -> void:
	var oak: Material = StorybookMaterial.make(OAK_COLOR.lightened(0.1))
	_solid(frame, "Counter", COUNTER_SIZE, Vector3(0.0, COUNTER_SIZE.y * 0.5, COUNTER_Z), oak)
	add_child(ShapeKit.box("Vellum", Vector3(0.5, 0.01, 0.36), Vector3(-0.3, COUNTER_SIZE.y + 0.01, COUNTER_Z), StorybookMaterial.make(VELLUM_COLOR)))
	for index: int in SIGN_ORDER.size():
		var ink: Color = _sign_color(SIGN_ORDER[index])
		add_child(ShapeKit.cylinder("InkPot%d" % index, 0.05, 0.06, 0.1, Vector3(0.35 + index * 0.16, COUNTER_SIZE.y + 0.05, COUNTER_Z - 0.08),
			StorybookMaterial.glowing(ink, 1.2), 10))


## The Vellum Press-Wheel on its stand: brass rim, oak spokes, a brass hub. It turns.
func _build_press_wheel(oak: Material) -> void:
	var brass: Material = StorybookMaterial.make(BRASS_COLOR)
	for side: float in [-1.0, 1.0]:
		add_child(ShapeKit.box("WheelStand%s" % ("Left" if side < 0.0 else "Right"), Vector3(0.08, WHEEL_CENTER.y, 0.08),
			WHEEL_CENTER + Vector3(0.0, -WHEEL_CENTER.y * 0.5, side * 0.16), oak))
	_wheel = Node3D.new()
	_wheel.name = "VellumPressWheel"
	_wheel.position = WHEEL_CENTER
	add_child(_wheel)
	var rim: MeshInstance3D = ShapeKit.torus("Rim", WHEEL_RADIUS - 0.06, WHEEL_RADIUS, Vector3.ZERO, brass)
	rim.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_wheel.add_child(rim)
	_wheel.add_child(ShapeKit.tilted(ShapeKit.cylinder("Hub", 0.09, 0.09, 0.2, Vector3.ZERO, brass, 12), Vector3(PI * 0.5, 0.0, 0.0)))
	for spoke: int in WHEEL_SPOKES:
		var angle: float = TAU * spoke / WHEEL_SPOKES
		var arm: MeshInstance3D = ShapeKit.box("Spoke%d" % spoke, Vector3(WHEEL_RADIUS * 0.95, 0.06, 0.05),
			Vector3(cos(angle), sin(angle), 0.0) * WHEEL_RADIUS * 0.47, oak)
		arm.rotation = Vector3(0.0, 0.0, angle)
		_wheel.add_child(arm)


## Four oak vats of deep ink along the back, each under a hanging brass lantern in its Sign's colour.
func _build_vats(frame: StaticBody3D, oak: Material) -> void:
	var brass: Material = StorybookMaterial.make(BRASS_COLOR)
	add_child(ShapeKit.box("LanternBeam", Vector3(DECK_SIZE.x - 1.0, 0.1, 0.1), Vector3(0.0, LANTERN_HEIGHT + 0.32, VAT_Z), oak))
	for index: int in SIGN_ORDER.size():
		var ink: Color = _sign_color(SIGN_ORDER[index])
		var spot: Vector3 = Vector3(VAT_XS[index], 0.0, VAT_Z)
		var vat: MeshInstance3D = ShapeKit.cylinder("Vat%d" % index, VAT_RADIUS, VAT_RADIUS * 0.88, VAT_HEIGHT, spot + Vector3(0.0, VAT_HEIGHT * 0.5, 0.0), oak, 16)
		frame.add_child(vat)
		var shape: CylinderShape3D = CylinderShape3D.new()
		shape.radius = VAT_RADIUS
		shape.height = VAT_HEIGHT
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "VatShape%d" % index
		collision.shape = shape
		collision.position = vat.position
		frame.add_child(collision)
		add_child(ShapeKit.no_shadow(ShapeKit.cylinder("Ink%d" % index, VAT_RADIUS * 0.86, VAT_RADIUS * 0.86, 0.03,
			spot + Vector3(0.0, VAT_HEIGHT + 0.005, 0.0), StorybookMaterial.glowing(ink, 2.2), 16)))
		var lantern: Node3D = Node3D.new()
		lantern.name = "VatLantern%d" % index
		lantern.position = spot + Vector3(0.0, LANTERN_HEIGHT, 0.0)
		add_child(lantern)
		lantern.add_child(ShapeKit.box("Cord", Vector3(0.015, 0.3, 0.015), Vector3(0.0, 0.17, 0.0), oak))
		lantern.add_child(ShapeKit.box("Cage", Vector3.ONE * LANTERN_SIZE, Vector3.ZERO, brass))
		lantern.add_child(ShapeKit.no_shadow(ShapeKit.sphere("Flame", LANTERN_SIZE * 0.42, Vector3.ZERO, StorybookMaterial.glowing(ink, 3.5))))
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "Light"
		light.light_color = ink
		light.light_energy = LANTERN_ENERGY
		light.omni_range = LANTERN_RANGE
		light.shadow_enabled = false
		lantern.add_child(light)


func _build_stand_ring() -> void:
	var material: StandardMaterial3D = StorybookMaterial.glowing(STAND_RING_COLOR, 1.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.torus("StandRing", STAND_RING_RADIUS - 0.05, STAND_RING_RADIUS,
		Vector3(0.0, 0.03, STAND_RING_Z), material))
	ring.scale = Vector3(1.0, 0.2, 1.0)
	add_child(ring)


## A body on the LowScenery layer: walkers bump into it, cameras see past it.
func _low_body(body_name: String) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = body_name
	body.collision_layer = ActorBase.LAYER_LOW_SCENERY
	body.collision_mask = 0
	add_child(body)
	return body


## A box drawn and collided at once, under `body`.
func _solid(body: StaticBody3D, part_name: String, part_size: Vector3, where: Vector3, material: Material) -> void:
	body.add_child(ShapeKit.box(part_name, part_size, where, material))
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = part_size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "%sShape" % part_name
	collision.shape = shape
	collision.position = where
	body.add_child(collision)


static func _sign_color(scribe_sign: int) -> Color:
	return ArsenalCatalog.current.sign_seal(scribe_sign).color
