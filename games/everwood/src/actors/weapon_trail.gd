## The ribbon a melee weapon draws through a rune-wreathed strike: a Scribe
## Card swung through a sword or an axe (05 GDD §4.3). While the strike is
## live it sweeps the weapon through an arc and samples its base and tip each
## frame, drawing the last few samples as a fading strip in the card's aspect
## colour (gold for a Shiny Foil copy). It reads the actor's synced current
## action, so every peer draws it.
class_name WeaponTrail
extends MeshInstance3D

const SAMPLE_LIFETIME: float = 0.2
const MAX_SAMPLES: int = 24
## The swing sweeps the weapon this far (radians), right to left, in SWING_TIME.
const SWING_ARC: float = 2.0
const SWING_TIME: float = 0.18
const TRAIL_ALPHA: float = 0.85
const SHINY_COLOR: Color = Color(1.0, 0.84, 0.3)

var actor: ActorBase
## The weapon's current sweep angle; the actor turns its weapon prop to match.
var swing_angle: float = 0.0

var _bases: Array[Vector3] = []
var _tips: Array[Vector3] = []
var _ages: Array[float] = []
var _mesh: ImmediateMesh
var _material: StandardMaterial3D
var _swing_time: float = -1.0
var _colour: Color = Color.WHITE


func setup(owner_actor: ActorBase) -> void:
	actor = owner_actor
	name = "WeaponTrail"


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_mesh = ImmediateMesh.new()
	mesh = _mesh
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.vertex_color_use_as_albedo = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func is_swinging() -> bool:
	return _swing_time >= 0.0


func _process(delta: float) -> void:
	var weapon: EquipmentItemResource = actor.loadout.weapon
	var action: CombatActionResource = actor.current_action()
	var live: bool = weapon != null and action != null and action.trail and actor.current_phase() == ActionQueueComponent.Phase.ACTIVE
	if not live:
		_swing_time = -1.0
		swing_angle = 0.0
	else:
		if _swing_time < 0.0:
			_swing_time = 0.0
			_colour = _colour_for(action)
		_swing_time += delta
		swing_angle = lerpf(SWING_ARC * 0.5, -SWING_ARC * 0.5, clampf(_swing_time / SWING_TIME, 0.0, 1.0))
	var had_samples: bool = not _ages.is_empty()
	for index: int in range(_ages.size() - 1, -1, -1):
		_ages[index] += delta
		if _ages[index] > SAMPLE_LIFETIME:
			_bases.remove_at(index)
			_tips.remove_at(index)
			_ages.remove_at(index)
	if live:
		var turn: Basis = Basis(Vector3.UP, swing_angle)
		var frame: Transform3D = actor.global_transform
		_bases.append(frame * (turn * weapon.trail_base))
		_tips.append(frame * (turn * weapon.trail_tip))
		_ages.append(0.0)
		while _ages.size() > MAX_SAMPLES:
			_bases.remove_at(0)
			_tips.remove_at(0)
			_ages.remove_at(0)
	if had_samples or not _ages.is_empty():
		_rebuild()


func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _ages.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for index: int in _ages.size():
		var shade: Color = Color(_colour, _colour.a * (1.0 - _ages[index] / SAMPLE_LIFETIME))
		_mesh.surface_set_color(shade)
		_mesh.surface_add_vertex(_bases[index])
		_mesh.surface_set_color(shade)
		_mesh.surface_add_vertex(_tips[index])
	_mesh.surface_end()


func _colour_for(action: CombatActionResource) -> Color:
	var colour: Color = ArsenalCatalog.current.aspect_seal(action.aspect).color
	var kit: EquipmentLoadoutResource = actor.loadout.kit
	if action.grimoire_slot >= 0 and kit != null and kit.lead_variant(action.grimoire_slot) == ScribeCardResource.CardVariant.SHINY_FOIL:
		colour = SHINY_COLOR
	return Color(colour, TRAIL_ALPHA)
