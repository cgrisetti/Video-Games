## A dungeon or raid portal apron recessed into Oakshire Vale's rim crags
## (12_WORLD_OAKSHIRE_VALE_GDD.md §5): a stone arch at the back of the apron,
## its plaque, and a Scribe Sign boundary barrier, a curtain of glyph-light in
## the Sign's colour that blocks the way in until the party's trail level opens
## it. The instances themselves are offloaded: they aren't built yet, so an
## open portal says so. Built in code; the host and every peer read the same
## party level, so the barrier lifts everywhere at once.
class_name PortalApron
extends Interactable

const ARCH_WIDTH: float = 6.0
const ARCH_HEIGHT: float = 7.0
const PILLAR: Vector3 = Vector3(1.4, 7.0, 1.6)
const STONE: Color = Color(0.58, 0.56, 0.52)
const CHECK_EVERY: float = 0.5
const OPEN_FADE: float = 1.2

## "[D1]"
@export var code: String = ""
@export var title: String = ""
## "Lvl 4–5 5-Player Story Dungeon"
@export var blurb: String = ""
@export var required_level: int = 1
@export var scribe_sign: int = ScribeSignResource.Sign.SIGN_IRON_ROOT
@export var dungeon_id: StringName = &""

var is_open: bool = false

var _barrier: MeshInstance3D
var _barrier_body: StaticBody3D
var _barrier_material: StandardMaterial3D
var _swirl: MeshInstance3D
var _check_left: float = 0.0
var _fade_left: float = 0.0


func _ready() -> void:
	# A glyph on the Wayfarer's map (CartographyBaker.GLYPH_GROUP, 18 GDD §7.2).
	add_to_group(&"map_glyphs")
	reach = 5.0
	_build()
	_refresh(true)


func prompt_for(_actor: ActorBase) -> String:
	if not is_open:
		return "%s %s · sealed by the %s until Level %d" % [code, title, _seal().seal_name, required_level]
	return "%s %s · %s · light: step through" % [code, title, blurb]


func interact(actor: ActorBase) -> void:
	if not is_open:
		CombatDirector.current.announce(global_position + Vector3.UP * 4.0, "Sealed until Level %d" % required_level, _seal().color, &"refuse")
		return
	CombatDirector.current.announce(actor.global_position + Vector3.UP * 2.6, "%s: this delve is still being scribed" % title, _seal().color, &"refuse")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = CHECK_EVERY
		_refresh(false)
	if _fade_left > 0.0:
		_fade_left = maxf(0.0, _fade_left - delta)
		_barrier_material.albedo_color.a = 0.55 * (_fade_left / OPEN_FADE)
		_barrier.visible = _fade_left > 0.0
	if _swirl.visible:
		_swirl.rotate_object_local(Vector3.FORWARD, delta * 0.8)


## Lifts (or raises) the barrier to match the party's trail level.
func _refresh(at_once: bool) -> void:
	var open_now: bool = PartyProgress.current != null and PartyProgress.current.trail_level() >= required_level
	if open_now == is_open and not at_once:
		return
	is_open = open_now
	(_barrier_body.get_child(0) as CollisionShape3D).disabled = is_open
	_swirl.visible = is_open
	if is_open and not at_once:
		_fade_left = OPEN_FADE
		AudioCues.play(&"gate")
	else:
		_barrier.visible = not is_open
		_barrier_material.albedo_color.a = 0.55


func _seal() -> ScribeSignResource:
	return ArsenalCatalog.current.sign_seal(scribe_sign)


func _build() -> void:
	var stone: Material = StorybookMaterial.make(STONE, StorybookMaterial.SCENERY_RIM)
	var glow: Color = _seal().color
	for side: float in [-1.0, 1.0]:
		add_child(ShapeKit.box("Pillar", PILLAR, Vector3(side * (ARCH_WIDTH * 0.5 + PILLAR.x * 0.5), PILLAR.y * 0.5, 0.0), stone))
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "PillarBody"
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = PILLAR
		shape.shape = box
		shape.position = Vector3(side * (ARCH_WIDTH * 0.5 + PILLAR.x * 0.5), PILLAR.y * 0.5, 0.0)
		body.add_child(shape)
		add_child(body)
	add_child(ShapeKit.box("Lintel", Vector3(ARCH_WIDTH + PILLAR.x * 2.0 + 0.6, 1.2, PILLAR.z + 0.2), Vector3(0.0, ARCH_HEIGHT + 0.6, 0.0), stone))
	add_child(ShapeKit.box("Keystone", Vector3(1.2, 1.4, PILLAR.z + 0.4), Vector3(0.0, ARCH_HEIGHT + 0.9, 0.0), StorybookMaterial.make(glow.darkened(0.2))))
	# The portal itself behind the barrier, swirling once it's open.
	_swirl = MeshInstance3D.new()
	_swirl.name = "Portal"
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = ARCH_WIDTH * 0.46
	disc.bottom_radius = ARCH_WIDTH * 0.46
	disc.height = 0.1
	disc.radial_segments = 24
	disc.material = StorybookMaterial.glowing(glow, 1.6)
	_swirl.mesh = disc
	_swirl.rotation.x = PI * 0.5
	_swirl.position = Vector3(0.0, ARCH_HEIGHT * 0.48, 0.4)
	add_child(_swirl)
	# The Scribe Sign boundary barrier across the arch.
	_barrier_material = StandardMaterial3D.new()
	_barrier_material.albedo_color = Color(glow, 0.55)
	_barrier_material.emission_enabled = true
	_barrier_material.emission = glow
	_barrier_material.emission_energy_multiplier = 1.4
	_barrier_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_barrier_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_barrier = MeshInstance3D.new()
	_barrier.name = "Barrier"
	var curtain: BoxMesh = BoxMesh.new()
	curtain.size = Vector3(ARCH_WIDTH, ARCH_HEIGHT, 0.12)
	curtain.material = _barrier_material
	_barrier.mesh = curtain
	_barrier.position = Vector3(0.0, ARCH_HEIGHT * 0.5, -0.6)
	_barrier.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_barrier)
	for index: int in 5:
		var glyph: Label3D = Label3D.new()
		glyph.name = "Glyph%d" % index
		glyph.text = ["◆", "✦", "◇", "✧", "◆"][index]
		glyph.font_size = 72
		glyph.modulate = glow.lightened(0.5)
		glyph.position = Vector3((index - 2) * 1.1, ARCH_HEIGHT * 0.5 + sin(index * 1.9) * 1.4, -0.68)
		glyph.rotation.y = PI
		_barrier.add_child(glyph)
	_barrier_body = StaticBody3D.new()
	_barrier_body.name = "BarrierBody"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var wall: BoxShape3D = BoxShape3D.new()
	wall.size = Vector3(ARCH_WIDTH, ARCH_HEIGHT, 0.6)
	shape.shape = wall
	shape.position = Vector3(0.0, ARCH_HEIGHT * 0.5, -0.6)
	_barrier_body.add_child(shape)
	add_child(_barrier_body)
	var plaque: Label3D = Label3D.new()
	plaque.name = "Plaque"
	plaque.text = "%s %s\n%s\nOpens at Level %d" % [code, title, blurb, required_level]
	plaque.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plaque.font_size = 40
	plaque.outline_size = 10
	plaque.pixel_size = 0.008
	plaque.modulate = glow.lightened(0.45)
	plaque.position = Vector3(0.0, ARCH_HEIGHT + 2.6, 0.0)
	add_child(plaque)
