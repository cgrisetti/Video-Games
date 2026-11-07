## The storybook sky (docs/13_PLAYTEST_KAIZEN_UPDATE_PROMPT.md §2.6; storybook_sky.gdshader):
## LevelBase puts it in place of a level's procedural sky as the level starts,
## keeping that sky's four colours, and WorldAtmosphereDirector then eases the
## colours by biome as before (set_colors takes either kind of sky).
class_name StorybookSky
extends RefCounted

const SHADER: Shader = preload("res://src/actors/storybook_sky.gdshader")
## Its light probe is small and refreshed in real time (the clouds drift): the
## probe pass draws only the gradient and ridges, so it stays cheap.
const RADIANCE_SIZE: Sky.RadianceSize = Sky.RADIANCE_SIZE_64
const COLOR_NAMES: Array[StringName] = [&"sky_top_color", &"sky_horizon_color", &"ground_horizon_color", &"ground_bottom_color"]


## A storybook sky material, its colours taken from `from` (a ProceduralSkyMaterial) when given.
static func make_material(from: Material = null) -> ShaderMaterial:
	var made: ShaderMaterial = ShaderMaterial.new()
	made.shader = SHADER
	var procedural: ProceduralSkyMaterial = from as ProceduralSkyMaterial
	if procedural != null:
		set_colors(made, procedural.sky_top_color, procedural.sky_horizon_color, procedural.ground_horizon_color, procedural.ground_bottom_color)
	return made


## Puts the storybook sky into an environment in place of its procedural sky. Returns whether it changed anything.
static func install(environment: Environment) -> bool:
	if environment == null or environment.sky == null:
		return false
	var current: Material = environment.sky.sky_material
	if current is ShaderMaterial and (current as ShaderMaterial).shader == SHADER:
		return false
	if not current is ProceduralSkyMaterial:
		return false
	environment.sky.sky_material = make_material(current)
	environment.sky.radiance_size = RADIANCE_SIZE
	environment.sky.process_mode = Sky.PROCESS_MODE_REALTIME
	return true


## Whether an environment wears the storybook sky.
static func is_installed(environment: Environment) -> bool:
	return environment != null and environment.sky != null and environment.sky.sky_material is ShaderMaterial \
		and (environment.sky.sky_material as ShaderMaterial).shader == SHADER


## Sets a sky's four colours, whichever kind of sky material it is.
static func set_colors(material: Material, top: Color, horizon: Color, ground_horizon: Color, ground_bottom: Color) -> void:
	var procedural: ProceduralSkyMaterial = material as ProceduralSkyMaterial
	if procedural != null:
		procedural.sky_top_color = top
		procedural.sky_horizon_color = horizon
		procedural.ground_horizon_color = ground_horizon
		procedural.ground_bottom_color = ground_bottom
		return
	var shaded: ShaderMaterial = material as ShaderMaterial
	if shaded != null:
		var values: Array[Color] = [top, horizon, ground_horizon, ground_bottom]
		for index: int in COLOR_NAMES.size():
			shaded.set_shader_parameter(COLOR_NAMES[index], values[index])
