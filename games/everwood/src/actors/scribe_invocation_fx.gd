## The choreography of a Scribe Card invocation (05 GDD §3.3), shown on every
## peer when a card's wind-up begins:
##   STANDARD      the aspect's geometric seal blooms under the caster's boots for
##                 0.6 s, and a vellum card flips and dissolves above their shoulder
##   SHINY_FOIL    + two counter-rotating gold rings and a brighter, higher chime
##                 (the weapon's ribbon trail turns gold: WeaponTrail)
##   ASTRAL_PRISM  + a starfield dome through the wind-up and luminous footprints
##                 for 2.5 s
## A card fired through a bow or staff also charges through a standing rune ring
## in front of the caster. Presentation only: nothing here changes the fight.
## Pooled: when the last flourish ends, finish() hands it back to the FxPool.
class_name ScribeInvocationFX
extends PooledFx

const SEAL_SHADER: Shader = preload("res://src/actors/scribe_seal.gdshader")
const DOME_SHADER: Shader = preload("res://src/actors/astral_dome.gdshader")
const SEAL_SIZE: float = 3.0
const SEAL_TIME: float = 0.6
const FLOOR_OFFSET: float = 0.05
## The vellum card floats above the caster's right shoulder (actor space).
const CARD_OFFSET: Vector3 = Vector3(0.55, 2.05, 0.15)
const CARD_SIZE: Vector3 = Vector3(0.3, 0.42, 0.012)
const CARD_RISE: float = 0.35
## The flip takes this share of the seal's life; the card dissolves in the rest.
const CARD_FLIP_SHARE: float = 0.45
const CARD_DISSOLVE_GROWTH: float = 0.4
const VELLUM_COLOR: Color = Color(0.96, 0.91, 0.78)
const EMBLEM_SIZE: float = 0.24
const EMBLEM_INTENSITY: float = 1.8
## Shiny Foil: gold rings just above the seal, turning opposite ways.
const FOIL_RING_RADII: Array[float] = [1.15, 1.42]
const FOIL_RING_THICKNESS: float = 0.04
const FOIL_RING_SPIN: float = 5.0
const FOIL_COLOR: Color = Color(1.0, 0.82, 0.3)
const FOIL_GLOW: float = 3.0
## A Shiny Foil card's vellum glows gold at its edges this brightly.
const FOIL_EDGE_GLOW: float = 0.6
## Astral Prism: the dome grows through the wind-up, then fades.
const DOME_RADIUS: float = 2.4
const DOME_START_SCALE: float = 0.3
const DOME_FADE_TIME: float = 0.35
const FOOTPRINT_TIME: float = 2.5
const FOOTPRINT_STRIDE: float = 0.55
const FOOTPRINT_SIDE_STEP: float = 0.14
## Card shots charge through a standing rune ring this far in front of the caster.
const MUZZLE_RING_OFFSET: Vector3 = Vector3(0.0, 1.2, -0.95)
const MUZZLE_RING_RADIUS: float = 0.45
const MUZZLE_RING_START_SCALE: float = 0.4
const MUZZLE_RING_LINGER: float = 0.25
## The chime for each variant, and the Shiny Foil's harmonic pitch boost.
const VARIANT_SOUNDS: Array[StringName] = [&"card_chime", &"card_chime_foil", &"card_chime_astral"]
const FOIL_PITCH: float = 1.25

var caster: ActorBase
var variant: ScribeCardResource.CardVariant = ScribeCardResource.CardVariant.STANDARD

var _age: float = 0.0
var _life: float = SEAL_TIME
var _windup: float = 0.0
var _colour: Color = Color.WHITE
var _ranged: bool = false
var _seal: MeshInstance3D
var _seal_material: ShaderMaterial
var _card: Node3D
var _card_material: StandardMaterial3D
var _emblem_material: ShaderMaterial
var _rings: Array[MeshInstance3D] = []
var _ring_material: StandardMaterial3D
var _dome: MeshInstance3D
var _dome_material: ShaderMaterial
var _muzzle_ring: MeshInstance3D
var _muzzle_material: StandardMaterial3D
var _last_step: Vector3 = Vector3.ZERO
var _step_side: float = 1.0


static func make() -> ScribeInvocationFX:
	var fx: ScribeInvocationFX = ScribeInvocationFX.new()
	fx.name = "ScribeInvocationFX"
	fx._build()
	return fx


func _build() -> void:
	_seal_material = ShaderMaterial.new()
	_seal_material.shader = SEAL_SHADER
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(SEAL_SIZE, SEAL_SIZE)
	plane.material = _seal_material
	_seal = _mesh_node("Seal", plane)
	add_child(_seal)

	_card = Node3D.new()
	_card.name = "Card"
	add_child(_card)
	_card_material = StandardMaterial3D.new()
	_card_material.albedo_color = VELLUM_COLOR
	_card_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_card_material.emission_enabled = true
	_card_material.emission = Color.BLACK
	var vellum: BoxMesh = BoxMesh.new()
	vellum.size = CARD_SIZE
	vellum.material = _card_material
	_card.add_child(_mesh_node("Vellum", vellum))
	_emblem_material = ShaderMaterial.new()
	_emblem_material.shader = SEAL_SHADER
	_emblem_material.set_shader_parameter(&"hold", 1.0)
	var emblem_quad: QuadMesh = QuadMesh.new()
	emblem_quad.size = Vector2(EMBLEM_SIZE, EMBLEM_SIZE)
	emblem_quad.material = _emblem_material
	var emblem: MeshInstance3D = _mesh_node("Emblem", emblem_quad)
	emblem.position = Vector3(0.0, 0.0, CARD_SIZE.z)
	_card.add_child(emblem)

	_ring_material = _glow_material(FOIL_COLOR, FOIL_GLOW)
	for radius: float in FOIL_RING_RADII:
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = radius - FOIL_RING_THICKNESS
		torus.outer_radius = radius
		torus.rings = 48
		torus.material = _ring_material
		var ring: MeshInstance3D = _mesh_node("FoilRing", torus)
		ring.position = Vector3(0.0, FLOOR_OFFSET + 0.04, 0.0)
		add_child(ring)
		_rings.append(ring)

	_dome_material = ShaderMaterial.new()
	_dome_material.shader = DOME_SHADER
	var dome_mesh: SphereMesh = SphereMesh.new()
	dome_mesh.radius = DOME_RADIUS
	dome_mesh.height = DOME_RADIUS
	dome_mesh.is_hemisphere = true
	dome_mesh.material = _dome_material
	_dome = _mesh_node("StarDome", dome_mesh)
	add_child(_dome)

	_muzzle_material = _glow_material(Color.WHITE, FOIL_GLOW)
	var muzzle_torus: TorusMesh = TorusMesh.new()
	muzzle_torus.inner_radius = MUZZLE_RING_RADIUS - FOIL_RING_THICKNESS
	muzzle_torus.outer_radius = MUZZLE_RING_RADIUS
	muzzle_torus.material = _muzzle_material
	_muzzle_ring = _mesh_node("MuzzleRing", muzzle_torus)
	add_child(_muzzle_ring)


## Starts the show for a card `on` an actor: its aspect's seal, its copy's
## variant, and how long its wind-up lasts (the dome and muzzle ring follow it).
func play(on: ActorBase, seal: AspectSealResource, card_variant: ScribeCardResource.CardVariant, windup: float, ranged: bool) -> void:
	caster = on
	variant = card_variant
	_windup = maxf(0.05, windup)
	_ranged = ranged
	_age = 0.0
	_colour = seal.color
	_life = SEAL_TIME
	if variant == ScribeCardResource.CardVariant.ASTRAL_PRISM:
		_life = maxf(SEAL_TIME, FOOTPRINT_TIME)
	if _ranged:
		_life = maxf(_life, _windup + MUZZLE_RING_LINGER)
	_seal_material.set_shader_parameter(&"tint", _colour)
	_seal_material.set_shader_parameter(&"glyph", seal.glyph)
	_emblem_material.set_shader_parameter(&"tint", _colour)
	_emblem_material.set_shader_parameter(&"glyph", seal.glyph)
	_card_material.emission = FOIL_COLOR * FOIL_EDGE_GLOW if variant == ScribeCardResource.CardVariant.SHINY_FOIL else Color.BLACK
	_muzzle_material.albedo_color = _colour
	_muzzle_material.emission = _colour
	_dome_material.set_shader_parameter(&"tint", _colour.lerp(Color(0.75, 0.6, 1.0), 0.5))
	for ring: MeshInstance3D in _rings:
		ring.visible = variant == ScribeCardResource.CardVariant.SHINY_FOIL
	_dome.visible = variant == ScribeCardResource.CardVariant.ASTRAL_PRISM
	_muzzle_ring.visible = _ranged
	_last_step = caster.global_position
	_follow_caster()
	_update(0.0)
	AudioCues.play(VARIANT_SOUNDS[variant], FOIL_PITCH if variant == ScribeCardResource.CardVariant.SHINY_FOIL else 1.0)


func is_showing_foil() -> bool:
	return in_use and variant == ScribeCardResource.CardVariant.SHINY_FOIL and _rings[0].visible


func is_showing_dome() -> bool:
	return in_use and _dome.visible


func is_showing_muzzle_ring() -> bool:
	return in_use and _muzzle_ring.visible


func _process(delta: float) -> void:
	if not is_instance_valid(caster):
		finish()
		return
	_age += delta
	_follow_caster()
	_update(delta)
	if variant == ScribeCardResource.CardVariant.ASTRAL_PRISM and _age < FOOTPRINT_TIME:
		_leave_footprints()
	if _age >= _life:
		finish()


func _follow_caster() -> void:
	var feet: Vector3 = caster.global_position
	global_position = Vector3(feet.x, feet.y + FLOOR_OFFSET, feet.z)


func _update(delta: float) -> void:
	var seal_t: float = clampf(_age / SEAL_TIME, 0.0, 1.0)
	_seal.visible = _age < SEAL_TIME
	_seal_material.set_shader_parameter(&"progress", seal_t)
	# The vellum card: rises, flips once, then dissolves.
	_card.visible = _age < SEAL_TIME
	var frame: Transform3D = caster.global_transform
	_card.global_position = frame * (CARD_OFFSET + Vector3.UP * CARD_RISE * seal_t)
	var flip_t: float = clampf(seal_t / CARD_FLIP_SHARE, 0.0, 1.0)
	_card.global_rotation = Vector3(0.0, caster.rotation.y + TAU * ease(flip_t, -2.0), 0.0)
	var dissolve_t: float = clampf((seal_t - CARD_FLIP_SHARE) / (1.0 - CARD_FLIP_SHARE), 0.0, 1.0)
	_card.scale = Vector3.ONE * (1.0 + dissolve_t * CARD_DISSOLVE_GROWTH)
	_card_material.albedo_color.a = 1.0 - dissolve_t
	_emblem_material.set_shader_parameter(&"intensity", EMBLEM_INTENSITY * (1.0 - dissolve_t))
	# Shiny Foil rings turn opposite ways and fade with the seal.
	for index: int in _rings.size():
		_rings[index].rotate_y(FOIL_RING_SPIN * delta * (1.0 if index % 2 == 0 else -1.0))
	_ring_material.albedo_color.a = 1.0 - seal_t
	# Astral Prism dome: grows through the wind-up, then fades.
	if _dome.visible:
		var grow: float = clampf(_age / _windup, 0.0, 1.0)
		var fade: float = 1.0 - clampf((_age - _windup) / DOME_FADE_TIME, 0.0, 1.0)
		_dome.scale = Vector3.ONE * lerpf(DOME_START_SCALE, 1.0, grow)
		_dome_material.set_shader_parameter(&"strength", fade)
		_dome.visible = fade > 0.0 or _age < _windup
	# A card shot's rune ring stands in front of the caster until the shot has gone through.
	if _ranged:
		_muzzle_ring.global_transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5).rotated(Vector3.UP, caster.rotation.y), frame * MUZZLE_RING_OFFSET)
		_muzzle_ring.scale = Vector3.ONE * lerpf(MUZZLE_RING_START_SCALE, 1.0, clampf(_age / _windup, 0.0, 1.0))
		_muzzle_material.albedo_color.a = 1.0 - clampf((_age - _windup) / MUZZLE_RING_LINGER, 0.0, 1.0)
		_muzzle_ring.visible = _age < _windup + MUZZLE_RING_LINGER


## Astral Prism: a glowing print every stride the caster takes, left and right in turn.
func _leave_footprints() -> void:
	var feet: Vector3 = caster.global_position
	if feet.distance_to(_last_step) < FOOTPRINT_STRIDE or pool == null:
		return
	_last_step = feet
	_step_side = -_step_side
	var side: Vector3 = caster.global_transform.basis.x * FOOTPRINT_SIDE_STEP * _step_side
	var footprint: GlowFootprint = pool.take(&"footprint", GlowFootprint.make) as GlowFootprint
	footprint.place(feet + side, caster.rotation.y, _colour)


func _mesh_node(node_name: String, mesh: Mesh) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _glow_material(colour: Color, glow: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = glow
	return material
