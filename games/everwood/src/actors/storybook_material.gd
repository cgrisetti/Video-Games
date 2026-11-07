## Makes storybook cel materials (storybook_cel.gdshader, 07 GDD §4.2) and
## lights them up. Every non-glowing surface of actors and scenery uses one;
## glowing bits (eyes, lanterns, windows) stay StandardMaterial3D with emission.
class_name StorybookMaterial
extends RefCounted

const SHADER: Shader = preload("res://src/actors/storybook_cel.gdshader")
const DOUBLE_SIDED_SHADER: Shader = preload("res://src/actors/storybook_cel_double.gdshader")
const VERTEX_COLOR_SHADER: Shader = preload("res://src/actors/storybook_cel_vertex.gdshader")
## Scenery gets a faint warm rim; heroes and foes a stronger one in their colour.
const SCENERY_RIM: float = 0.18
const ACTOR_RIM: float = 0.7
const WARM_RIM: Color = Color(1.0, 0.92, 0.78)
## How weathered a cel colour is (docs/24 §2): scenery and props, then creatures and figures.
const SCENERY_WEAR: float = 0.9
const ACTOR_WEAR: float = 0.45
## Moss on scenery's upward faces.
const SCENERY_MOSS: float = 0.22


## A cel material in `color`, with a rim of `rim_color` at `rim_strength`.
static func make(color: Color, rim_strength: float = SCENERY_RIM, rim_color: Color = WARM_RIM, double_sided: bool = false) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = DOUBLE_SIDED_SHADER if double_sided else SHADER
	material.set_shader_parameter(&"albedo", color)
	material.set_shader_parameter(&"rim_color", rim_color)
	material.set_shader_parameter(&"rim_strength", rim_strength)
	# Lived in (docs/24 §2): scenery weathers and gathers a little moss on its tops; heroes and foes stay cleaner.
	var scenery: bool = rim_strength <= SCENERY_RIM + 0.001
	material.set_shader_parameter(&"wear", SCENERY_WEAR if scenery else ACTOR_WEAR)
	material.set_shader_parameter(&"moss_amount", SCENERY_MOSS if scenery else 0.0)
	return material


## The same look, drawn from both sides (for surfaces built face by face, like ramps).
static func double_sided(material: Material) -> Material:
	var cel: ShaderMaterial = material as ShaderMaterial
	if cel != null:
		var copy: ShaderMaterial = cel.duplicate() as ShaderMaterial
		copy.shader = DOUBLE_SIDED_SHADER
		return copy
	var standard: BaseMaterial3D = material.duplicate() as BaseMaterial3D
	if standard != null:
		standard.cull_mode = BaseMaterial3D.CULL_DISABLED
		return standard
	return material


## The look tinted by each vertex's colour (Landblock terrain, HLOD proxies, clutter).
static func vertex_colored() -> ShaderMaterial:
	var material: ShaderMaterial = make(Color.WHITE)
	material.shader = VERTEX_COLOR_SHADER
	return material


## A hero's or foe's material: its colour, rimmed in its role's colour so it pops in split-screen.
static func actor(color: Color, rim_color: Color) -> ShaderMaterial:
	return make(color, ACTOR_RIM, rim_color.lightened(0.35))


## Lights a material up (a hit flash, a flow glow, a wind-up tell); black turns it off.
static func set_glow(material: Material, color: Color) -> void:
	var cel: ShaderMaterial = material as ShaderMaterial
	if cel != null:
		cel.set_shader_parameter(&"glow", color)
		return
	var standard: StandardMaterial3D = material as StandardMaterial3D
	if standard != null:
		standard.emission_enabled = true
		standard.emission = color


## A glowing part: unaffected by the cel bands, it shines in `color`.
static func glowing(color: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
