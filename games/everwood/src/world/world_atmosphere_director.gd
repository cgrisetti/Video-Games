## The world's light and air (autoload "Atmosphere";
## 17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §3, §6.2):
##
## - At start it renders the Procedural Texture Atelier's eight craft sets on
##   worker threads (256 px, 64 px headless), stacks them into three
##   Texture2DArrays and hands them to every world shader as the global
##   parameters atelier_albedo / _normal / _roughness, then sets atelier_ready.
## - Every 0.4 s it finds the biome most local players stand in
##   (LevelBase.visual_biome_at) and eases the level's sky, sun and fog toward
##   it (Filmic, a procedural sky, a soft-shadowed sun, light SSAO and glow).
## - Every frame it tells the world shaders where the local heroes stand (the
##   camera sightline fade and the grass brush), which Hush-Cracks are open
##   near the party (hush_crack_0..3) and where Reclamation Blooms are
##   sweeping out (bloom_0..3), and blows the world wind.
## - Ecological Succession (§2.2): set_succession_state(id, state) puts a
##   Hush-Crack (by its camp's id) or a whole biome into ZONE_HUSHED,
##   ZONE_RECLAIMED or ZONE_WEATHERING_EVENT. Hushed cracks grey the turf round
##   them and dim the Wind-Lanterns there; a reclaimed one blooms gold and
##   emerald and becomes a Lulled Cairn; a weathering biome thickens its fog,
##   strengthens its wind and flares its lanterns.
## - It keeps the HorizonVistaRing (Ring 3, out to 2.5 km) round the party,
##   and drifts pollen, hush-motes or fret round the party in the biome's colour.
## - Phase 18 (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md §3-5):
##   every frame it hands the shaders the Lantern's Promise halos (5.5 m round
##   every Lantern-Bearer and every hero holding a Hearth-Rite Tuck, up to
##   four, nearest the local players first), which push the First-Quiet's blight
##   back; it eases the biome's ground palette (turf, road, trodden verge) for
##   the frayed road edges and its cloud shadows (22% of the sun in drifting 35 m
##   patches), sets the blight's ashen slate-indigo, hoar-rime and Frozen Wind
##   from ZONE_HUSHED's look, and lights the fog with warm sun-scatter and
##   aerial perspective over a low height fog.
## Levels say which biome is where; nothing here names a place.
class_name WorldAtmosphereDirector
extends Node

signal biome_changed(biome_id: StringName)
signal succession_changed(id: StringName, state: int)
signal atelier_finished

const Succession = ZoneSuccessionVisualResource.SuccessionState

## Seconds between biome evaluations (as the score's heartbeat).
const HEARTBEAT: float = 0.4
## The time constant of the sky, sun and fog easing toward a new biome (they settle in about three).
const BLEND_TAU: float = 1.0
## A biome's sun energy is scaled by this (1.15, the meadow's, is the old 0.95 sun).
## The sun at full strength over the sky-lit shade (docs/24 §2; it was 0.82, which flattened every form).
const SUN_SCALE: float = 1.02
const SUN_SHADOW_BLUR: float = 1.4
## Ambient occlusion and the grade (docs/24 §2): deep creases, a touch of punch.
const SSAO_RADIUS: float = 1.4
const SSAO_INTENSITY: float = 2.2
const SSAO_POWER: float = 1.5
const SSAO_LIGHT_AFFECT: float = 0.18
const GRADE_CONTRAST: float = 1.07
const MAX_CRACKS: int = 4
const MAX_BLOOMS: int = 4
## How far a Reclamation Bloom's wave runs from a sealed crack.
const BLOOM_REACH_M: float = 26.0
## Open cracks further than this from every local player aren't sent to the shaders.
const CRACK_SEARCH_M: float = 240.0
## Every PlayerCamera's far plane (§6.1 Ring 3).
const CAMERA_FAR: float = 3000.0
const BASE_WIND: Vector4 = Vector4(0.8, 0.0, 0.6, 0.35)
const WEATHER_WIND: float = 2.4
const WEATHER_FOG: float = 3.0
const HUSHED_SATURATION: float = 0.78
const MOTE_COUNT: int = 64
const MOTE_BOX: Vector3 = Vector3(28.0, 5.0, 28.0)
const LANTERN_GROUP: StringName = &"wind_lanterns"
## Sunlit pollen and dandelion drift (§6.2).
const POLLEN_COLOR: Color = Color(1.0, 0.88, 0.5)
const GLOBAL_HEROES: Array[StringName] = [&"hero_pos_0", &"hero_pos_1", &"hero_pos_2", &"hero_pos_3"]
const GLOBAL_CRACKS: Array[StringName] = [&"hush_crack_0", &"hush_crack_1", &"hush_crack_2", &"hush_crack_3"]
const GLOBAL_BLOOMS: Array[StringName] = [&"bloom_0", &"bloom_1", &"bloom_2", &"bloom_3"]
const GLOBAL_HALOS: Array[StringName] = [&"lantern_halo_0", &"lantern_halo_1", &"lantern_halo_2", &"lantern_halo_3"]
const MAX_HALOS: int = 4
## Sun-scattering air (18 §4.4).
const FOG_AERIAL_PERSPECTIVE: float = 0.65
const FOG_SUN_SCATTER: float = 0.38
const FOG_HEIGHT: float = 2.5
const FOG_HEIGHT_DENSITY: float = 0.12
## The clouds drift this way (m/s).
const CLOUD_DRIFT: Vector2 = Vector2(1.4, 0.9)
## A Caldera seam's sea-fog at its thickest (seam_mist 1): dense, pale and close.
const SEAM_MIST_DENSITY: float = 0.045
const SEAM_MIST_COLOR: Color = Color(0.84, 0.86, 0.85)
const NO_HERO: Vector4 = Vector4(0.0, -1000.0, 0.0, 0.0)

## The live autoload node (see NetworkManager.current for why).
static var current: WorldAtmosphereDirector

## The biome the sky, sun and fog are easing toward.
var biome_id: StringName = &""
var atelier_is_ready: bool = false
## The atelier's tile size this run, and how long it took from start to the arrays.
var atelier_size: int = 0
var atelier_msec: int = 0
## Albedo, normal and roughness (eight layers each, ProceduralTextureAtelier.Set order).
var atelier_arrays: Array[Texture2DArray] = []
var horizon: HorizonVistaRing
## What was last sent to the shaders (tests read these; the renderer may be a dummy).
var hero_globals: Array[Vector4] = [NO_HERO, NO_HERO, NO_HERO, NO_HERO]
var crack_globals: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
var bloom_globals: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
## The Lantern's Promise halos handed to the shaders (xyz where, w the radius; 0 when none).
var halo_globals: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
## The ground palette, cloud shadows and blight looks handed to the shaders (what was set, since globals can't be read back).
var look_globals: Dictionary[StringName, Vector4] = {}
var wind: Vector4 = BASE_WIND
## A Caldera seam's sea-fog (0 clear, 1 thick), set by its SeamTransitionController.
var seam_mist: float = 0.0

var _states: Dictionary[StringName, int] = {}
var _cracks: Array[HushCrackLandmark] = []
## Live blooms: xyz the sealed crack, w the clock when it was sealed.
var _blooms: Array[Vector4] = []
var _clock: float = 0.0
var _heartbeat_left: float = 0.0
var _level: LevelBase
var _environment: Environment
var _sun: DirectionalLight3D
var _snap_look: bool = true
var _sun_color: Color = Color(1.0, 0.95, 0.86)
var _sun_energy: float = 0.95
var _sky_top: Color = WorldVisualCatalog.SKY_TOP
var _sky_horizon: Color = WorldVisualCatalog.SKY_HORIZON
var _fog_color: Color = Color(0.9, 0.9, 0.8)
var _fog_density: float = 0.0014
var _saturation: float = 1.0
var _mote_color: Color = Color(1.0, 0.88, 0.5, 0.8)
var _motes: GPUParticles3D
var _mote_material: StandardMaterial3D
var _jobs: Array[AtelierJob] = []
var _atelier_started_usec: int = 0


class AtelierJob:
	var which: int = 0
	var size: int = 64
	var images: Array[Image] = []
	var task_id: int = -1

	func run() -> void:
		images = ProceduralTextureAtelier.render_or_blank(which, size)


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	for job: AtelierJob in _jobs:
		WorkerThreadPool.wait_for_task_completion(job.task_id)
	_jobs.clear()
	if current == self:
		current = null


func _ready() -> void:
	process_priority = 10
	_start_atelier()
	horizon = HorizonVistaRing.new()
	horizon.name = "HorizonVistaRing"
	horizon.visible = false
	add_child(horizon)
	_build_motes()


func _process(delta: float) -> void:
	_clock += delta
	if not atelier_is_ready and not _jobs.is_empty():
		_poll_atelier(false)
	WorldKitInstance.build_waiting()
	var level: LevelBase = get_tree().current_scene as LevelBase
	if level != _level:
		_attach(level)
	if _level == null:
		return
	_heartbeat_left -= delta
	if _heartbeat_left <= 0.0:
		_heartbeat_left = HEARTBEAT
		_evaluate()
	_publish_heroes()
	_publish_cracks()
	_publish_blooms()
	_publish_halos()
	_ease_look(delta)


# --- The atelier ----------------------------------------------------------------------

func _start_atelier() -> void:
	atelier_size = ProceduralTextureAtelier.size_for_this_run()
	_atelier_started_usec = Time.get_ticks_usec()
	for which: int in ProceduralTextureAtelier.SET_IDS.size():
		var job: AtelierJob = AtelierJob.new()
		job.which = which
		job.size = atelier_size
		job.task_id = WorkerThreadPool.add_task(job.run, true, "Atelier %s" % ProceduralTextureAtelier.SET_IDS[which])
		_jobs.append(job)


## Waits for the atelier's textures (tests, and loading screens).
func wait_for_atelier() -> void:
	_poll_atelier(true)


func _poll_atelier(block: bool) -> void:
	if _jobs.is_empty():
		return
	for job: AtelierJob in _jobs:
		if block:
			WorkerThreadPool.wait_for_task_completion(job.task_id)
		elif not WorkerThreadPool.is_task_completed(job.task_id):
			return
	var maps: Array[Array] = [[], [], []]
	for job: AtelierJob in _jobs:
		if not block:
			WorkerThreadPool.wait_for_task_completion(job.task_id)
		var images: Array[Image] = ProceduralTextureAtelier.images_with_overrides(job.which, job.size, job.images)
		for map: int in 3:
			maps[map].append(images[map])
	_jobs.clear()
	atelier_arrays.clear()
	var names: Array[StringName] = [&"atelier_albedo", &"atelier_normal", &"atelier_roughness"]
	for map: int in 3:
		var layers: Array[Image] = []
		layers.assign(maps[map])
		var array: Texture2DArray = ProceduralTextureAtelier.make_array(layers)
		atelier_arrays.append(array)
		RenderingServer.global_shader_parameter_set(names[map], array)
	RenderingServer.global_shader_parameter_set(&"atelier_ready", 1.0)
	atelier_is_ready = true
	atelier_msec = int((Time.get_ticks_usec() - _atelier_started_usec) / 1000)
	atelier_finished.emit()


# --- The level's sky, sun and fog ----------------------------------------------------

func _attach(level: LevelBase) -> void:
	_level = level
	_environment = null
	_sun = null
	horizon.visible = level != null and level.wants_horizon_ring()
	_motes.emitting = level != null
	_snap_look = true
	biome_id = &""
	_cracks = _cracks.filter(func(crack: HushCrackLandmark) -> bool: return is_instance_valid(crack))
	_blooms.clear()
	if level == null:
		return
	var holder: WorldEnvironment = level.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if holder != null and holder.environment != null:
		_environment = holder.environment
		_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		# Contact shade in every crease and under every eave (docs/24 §2), a little of it in the sunlight too.
		_environment.ssao_enabled = true
		_environment.ssao_radius = SSAO_RADIUS
		_environment.ssao_intensity = SSAO_INTENSITY
		_environment.ssao_power = SSAO_POWER
		_environment.ssao_detail = 0.7
		_environment.ssao_light_affect = SSAO_LIGHT_AFFECT
		_environment.glow_enabled = true
		_environment.fog_enabled = true
		_environment.fog_sky_affect = 0.1
		# Warm sun-scatter and aerial perspective, so far hills glow amber instead of washing grey (18 §4.4).
		_environment.fog_aerial_perspective = FOG_AERIAL_PERSPECTIVE
		_environment.fog_sun_scatter = FOG_SUN_SCATTER
		_environment.fog_height = FOG_HEIGHT
		_environment.fog_height_density = FOG_HEIGHT_DENSITY
		_environment.adjustment_enabled = true
		_environment.adjustment_contrast = GRADE_CONTRAST
	_sun = level.find_child("Sun", true, false) as DirectionalLight3D
	if _sun != null:
		_sun.shadow_blur = SUN_SHADOW_BLUR
	_heartbeat_left = 0.0


func _evaluate() -> void:
	var locals: Array[ActorBase] = _local_players()
	var counts: Dictionary[StringName, int] = {}
	var first: StringName = &""
	for player: ActorBase in locals:
		var id: StringName = _level.visual_biome_at(player.global_position)
		if WorldVisualCatalog.biome(id) == null:
			continue
		if first == &"":
			first = id
		counts[id] = counts.get(id, 0) + 1
	var chosen: StringName = first
	for id: StringName in counts:
		if counts[id] > counts.get(chosen, 0):
			chosen = id
	if chosen == &"":
		chosen = WorldVisualCatalog.biome_for_place(_level.home_place())
	if chosen != &"" and chosen != biome_id:
		biome_id = chosen
		biome_changed.emit(biome_id)
	_warm_lanterns()


## The look being eased toward: the biome's, under its succession state.
func _ease_look(delta: float) -> void:
	var look: ZoneBiomeResource = WorldVisualCatalog.biome(biome_id)
	if look == null:
		return
	var state: int = succession_state(biome_id)
	var weather: float = WorldVisualCatalog.succession(Succession.ZONE_WEATHERING_EVENT).weathering_frost_or_fog_intensity \
		if state == Succession.ZONE_WEATHERING_EVENT else 0.0
	var mote: Color = POLLEN_COLOR
	if state == Succession.ZONE_HUSHED or _party_in_hush():
		mote = WorldVisualCatalog.succession(Succession.ZONE_HUSHED).mote_color
	elif weather > 0.0:
		mote = WorldVisualCatalog.succession(Succession.ZONE_WEATHERING_EVENT).mote_color
	var t: float = 1.0 if _snap_look else 1.0 - exp(-delta / BLEND_TAU)
	_snap_look = false
	_sun_color = _sun_color.lerp(look.sun_color, t)
	_sun_energy = lerpf(_sun_energy, look.sun_energy * SUN_SCALE * (1.0 - 0.25 * weather), t)
	_sky_top = _sky_top.lerp(look.sky_top_color, t)
	_sky_horizon = _sky_horizon.lerp(look.sky_horizon_color.lerp(look.fog_light_color, weather * 0.5), t)
	_fog_color = _fog_color.lerp(look.fog_light_color, t)
	_fog_density = lerpf(_fog_density, look.fog_density * (1.0 + (WEATHER_FOG - 1.0) * weather), t)
	_saturation = lerpf(_saturation, HUSHED_SATURATION if state == Succession.ZONE_HUSHED else 1.0, t)
	_mote_color = _mote_color.lerp(Color(mote, 0.8), t)
	# The ground palette and cloud shadows of the biome, and the blight's look (18 §3.1, §4.4, §5).
	_set_look_global(&"ground_turf", _linear4(look.turf_albedo, 1.0))
	_set_look_global(&"ground_road", _linear4(look.road_albedo, 1.0))
	_set_look_global(&"ground_verge", _linear4(look.verge_loam_albedo, 0.18))
	_set_look_global(&"cloud_shadow_params", Vector4(look.cloud_shadow_strength * (1.0 - 0.5 * weather), look.cloud_shadow_scale,
		CLOUD_DRIFT.x, CLOUD_DRIFT.y))
	var hushed: ZoneSuccessionVisualResource = WorldVisualCatalog.succession(Succession.ZONE_HUSHED)
	_set_look_global(&"blight_ashen", _linear4(hushed.blight_ashen_albedo, hushed.blight_desaturation))
	_set_look_global(&"blight_rime", _linear4(hushed.blight_rime_vein_color, ZoneBiomeResource.HUSH_RIME_RING_M))
	_set_look_global(&"blight_wind", Vector4(hushed.frozen_wind_multiplier, hushed.pressed_grass_height, 0.0, 0.0))
	var gust: float = 1.6 if biome_id == WorldVisualCatalog.DOVER_SLAP_FALLS else 1.0
	wind = Vector4(BASE_WIND.x, 0.0, BASE_WIND.z, BASE_WIND.w * gust * lerpf(1.0, WEATHER_WIND, weather))
	RenderingServer.global_shader_parameter_set(&"world_wind", wind)
	if _sun != null:
		_sun.light_color = _sun_color
		_sun.light_energy = _sun_energy
	if _environment != null:
		_environment.fog_light_color = _fog_color.lerp(SEAM_MIST_COLOR, seam_mist)
		_environment.fog_density = lerpf(_fog_density * _level.fog_density_scale(), SEAM_MIST_DENSITY, seam_mist)
		_environment.fog_height = _level.fog_height()
		_environment.adjustment_saturation = _saturation
	# The level's sky: Godot's procedural one, or the storybook sky that LevelBase puts in its place (13_PLAYTEST §2.6).
	var sky_material: Material = _environment.sky.sky_material if _environment != null and _environment.sky != null else null
	if sky_material != null:
		var below: Color = _level.sky_ground_color()
		StorybookSky.set_colors(sky_material, _sky_top, _sky_horizon,
			_sky_horizon.lerp(below if below.a > 0.0 else look.turf_albedo, 0.45 if below.a <= 0.0 else 0.7),
			below if below.a > 0.0 else look.turf_albedo.darkened(0.35))
	horizon.set_tint(_sky_horizon, _fog_color)
	_level.tint_far_scenery(_sky_horizon, _sky_top)
	_mote_material.albedo_color = _mote_color
	_mote_material.emission = Color(_mote_color.r, _mote_color.g, _mote_color.b)


## The level's look right now (tests): sun colour and energy, sky top and horizon, fog colour and density, saturation.
func look_snapshot() -> Dictionary:
	return {"biome": biome_id, "sun_color": _sun_color, "sun_energy": _sun_energy, "sky_top": _sky_top,
		"sky_horizon": _sky_horizon, "fog_color": _fog_color, "fog_density": _fog_density, "saturation": _saturation,
		"wind": wind, "mote_color": _mote_color}


## Settles the sky, sun and fog on the current biome at once (tests, and arriving through a portal).
func settle() -> void:
	if _level == null:
		return
	_evaluate()
	_snap_look = true
	_ease_look(0.0)


# --- Heroes, cracks and blooms --------------------------------------------------------

func _publish_heroes() -> void:
	var locals: Array[ActorBase] = _local_players()
	var centroid: Vector3 = Vector3.ZERO
	for slot: int in 4:
		var value: Vector4 = NO_HERO
		if slot < locals.size():
			var at: Vector3 = locals[slot].global_position
			value = Vector4(at.x, at.y, at.z, 1.0)
			centroid += at
		if value != hero_globals[slot]:
			hero_globals[slot] = value
			RenderingServer.global_shader_parameter_set(GLOBAL_HEROES[slot], value)
	if not locals.is_empty():
		centroid /= float(locals.size())
		horizon.follow(centroid)
		_motes.global_position = centroid + Vector3(0.0, 1.5, 0.0)


func register_crack(crack: HushCrackLandmark) -> void:
	if not _cracks.has(crack):
		_cracks.append(crack)
	_states[crack.crack_id] = crack.state


func unregister_crack(crack: HushCrackLandmark) -> void:
	_cracks.erase(crack)


## The Hush-Cracks streamed in now (the Wayfarer's map draws them).
func cracks() -> Array[HushCrackLandmark]:
	var live: Array[HushCrackLandmark] = []
	for crack: HushCrackLandmark in _cracks:
		if is_instance_valid(crack):
			live.append(crack)
	return live


## Whether a crack's succession state is known this session (it streamed in, or changed), and what it is.
func has_crack_state(id: StringName) -> bool:
	return _states.has(id)


func crack_state(id: StringName) -> int:
	return int(_states.get(id, ZoneSuccessionVisualResource.SuccessionState.ZONE_HUSHED))


## The open (or closing) cracks nearest the local players, up to four.
func _publish_cracks() -> void:
	var locals: Array[ActorBase] = _local_players()
	var open: Array[HushCrackLandmark] = []
	var distances: Dictionary[HushCrackLandmark, float] = {}
	for crack: HushCrackLandmark in _cracks:
		if not is_instance_valid(crack) or not crack.is_inside_tree() or crack.hush_radius <= 0.01:
			continue
		var nearest: float = INF
		for player: ActorBase in locals:
			nearest = minf(nearest, player.global_position.distance_to(crack.global_position))
		if nearest <= CRACK_SEARCH_M or locals.is_empty():
			open.append(crack)
			distances[crack] = nearest
	open.sort_custom(func(a: HushCrackLandmark, b: HushCrackLandmark) -> bool: return distances[a] < distances[b])
	for slot: int in MAX_CRACKS:
		var value: Vector4 = Vector4.ZERO
		if slot < open.size():
			var at: Vector3 = open[slot].global_position
			value = Vector4(at.x, at.y, at.z, open[slot].hush_radius)
		if value != crack_globals[slot]:
			crack_globals[slot] = value
			RenderingServer.global_shader_parameter_set(GLOBAL_CRACKS[slot], value)


## The Lantern's Promise (18 §5 layer 4): a warm 5.5 m halo round every
## Lantern-Bearer (any healer in the party) and every hero holding a Hearth-Rite
## Tuck, up to four, those nearest a local player first.
func _publish_halos() -> void:
	var locals: Array[ActorBase] = _local_players()
	var bearers: Array[ActorBase] = []
	var nearest: Dictionary[ActorBase, float] = {}
	var party: Array[ActorBase] = CombatDirector.current.party_actors() if CombatDirector.current != null else []
	for member: ActorBase in party:
		if not is_instance_valid(member) or not member.is_inside_tree() or member.stats == null or member.stats.is_downed:
			continue
		var tucked: bool = member.sign_flow != null and member.sign_flow.has_hearth_rite_tuck
		if member.role() != ClassLoadoutResource.Role.HEALER and not tucked:
			continue
		var gap: float = INF
		for player: ActorBase in locals:
			gap = minf(gap, player.global_position.distance_to(member.global_position))
		bearers.append(member)
		nearest[member] = gap
	bearers.sort_custom(func(a: ActorBase, b: ActorBase) -> bool: return nearest[a] < nearest[b])
	for slot: int in MAX_HALOS:
		var value: Vector4 = Vector4.ZERO
		if slot < bearers.size():
			var at: Vector3 = bearers[slot].global_position
			value = Vector4(at.x, at.y, at.z, ZoneBiomeResource.LANTERN_HALO_RADIUS_M)
		if value != halo_globals[slot]:
			halo_globals[slot] = value
			RenderingServer.global_shader_parameter_set(GLOBAL_HALOS[slot], value)


## The halos lit now (tests).
func halos_lit() -> int:
	var lit: int = 0
	for value: Vector4 in halo_globals:
		if value.w > 0.0:
			lit += 1
	return lit


## Sets a look global (and remembers it: globals can't be read back outside the editor).
func _set_look_global(global_name: StringName, value: Vector4) -> void:
	if look_globals.get(global_name, Vector4(-1.0, -1.0, -1.0, -1.0)) == value:
		return
	look_globals[global_name] = value
	RenderingServer.global_shader_parameter_set(global_name, value)


static func _linear4(color: Color, w: float) -> Vector4:
	var linear: Color = color.srgb_to_linear()
	return Vector4(linear.r, linear.g, linear.b, w)


## Starts a Reclamation Bloom sweeping out from `at` (a sealed crack, a lulled boss).
func bloom_at(at: Vector3) -> void:
	if _blooms.size() >= MAX_BLOOMS:
		_blooms.remove_at(0)
	_blooms.append(Vector4(at.x, at.y, at.z, _clock))


func _publish_blooms() -> void:
	var duration: float = WorldVisualCatalog.succession(Succession.ZONE_RECLAIMED).reclamation_bloom_duration_sec
	_blooms = _blooms.filter(func(bloom: Vector4) -> bool: return _clock - bloom.w <= duration)
	for slot: int in MAX_BLOOMS:
		var value: Vector4 = Vector4.ZERO
		if slot < _blooms.size():
			var bloom: Vector4 = _blooms[slot]
			var progress: float = clampf((_clock - bloom.w) / duration, 0.0, 1.0)
			value = Vector4(bloom.x, bloom.y, bloom.z, maxf(0.05, ease(progress, 0.6) * BLOOM_REACH_M))
		if value != bloom_globals[slot]:
			bloom_globals[slot] = value
			RenderingServer.global_shader_parameter_set(GLOBAL_BLOOMS[slot], value)


func blooms_running() -> int:
	return _blooms.size()


## Dims Wind-Lanterns inside an open crack's hush and flares them in a weathering biome.
func _warm_lanterns() -> void:
	var flare: bool = succession_state(biome_id) == Succession.ZONE_WEATHERING_EVENT
	for node: Node in get_tree().get_nodes_in_group(LANTERN_GROUP):
		var lantern: Node3D = node as Node3D
		if lantern == null or not lantern.is_inside_tree() or not lantern.has_method(&"set_warmth"):
			continue
		var warmth: float = WorldVisualCatalog.succession(Succession.ZONE_WEATHERING_EVENT).lantern_warmth_multiplier if flare else 1.0
		for crack: HushCrackLandmark in _cracks:
			if is_instance_valid(crack) and crack.state == Succession.ZONE_HUSHED \
					and lantern.global_position.distance_to(crack.global_position) <= crack.hush_radius:
				warmth = WorldVisualCatalog.succession(Succession.ZONE_HUSHED).lantern_warmth_multiplier
		lantern.call(&"set_warmth", warmth)


func _party_in_hush() -> bool:
	for player: ActorBase in _local_players():
		for crack: HushCrackLandmark in _cracks:
			if is_instance_valid(crack) and crack.state == Succession.ZONE_HUSHED \
					and player.global_position.distance_to(crack.global_position) <= crack.hush_radius:
				return true
	return false


# --- Ecological Succession ------------------------------------------------------------

## Puts a Hush-Crack (its camp's WorldStateDB id) or a biome into a succession state.
func set_succession_state(zone_or_camp_id: StringName, state: int) -> void:
	for crack: HushCrackLandmark in _cracks:
		if is_instance_valid(crack) and crack.crack_id == zone_or_camp_id:
			crack.set_state(state, true)
			return
	note_state(zone_or_camp_id, state)


## Records a state (HushCrackLandmark calls this when its camp changes).
func note_state(id: StringName, state: int) -> void:
	if _states.get(id, -1) == state:
		return
	_states[id] = state
	succession_changed.emit(id, state)


## A crack's or biome's state: ZONE_RECLAIMED when nothing has said otherwise.
func succession_state(id: StringName) -> int:
	return _states.get(id, Succession.ZONE_RECLAIMED)


func crack(id: StringName) -> HushCrackLandmark:
	for found: HushCrackLandmark in _cracks:
		if is_instance_valid(found) and found.crack_id == id:
			return found
	return null


# --- Motes ---------------------------------------------------------------------------

## Pollen (or hush-motes, or fret) drifting up round the party.
func _build_motes() -> void:
	_motes = GPUParticles3D.new()
	_motes.name = "AtmosphereMotes"
	_motes.amount = MOTE_COUNT
	_motes.lifetime = 7.0
	_motes.preprocess = 4.0
	_motes.local_coords = false
	_motes.visibility_aabb = AABB(-MOTE_BOX, MOTE_BOX * 2.0)
	_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = MOTE_BOX * 0.5
	process.gravity = Vector3(0.0, 0.05, 0.0)
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.25
	process.direction = Vector3(0.3, 1.0, 0.2)
	process.spread = 60.0
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.6
	process.turbulence_noise_scale = 3.0
	process.scale_min = 0.6
	process.scale_max = 1.2
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.2, Color.WHITE)
	fade.add_point(0.8, Color.WHITE)
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	_motes.process_material = process
	var mote: SphereMesh = SphereMesh.new()
	mote.radius = 0.03
	mote.height = 0.06
	mote.radial_segments = 6
	mote.rings = 3
	_mote_material = StandardMaterial3D.new()
	_mote_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mote_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mote_material.vertex_color_use_as_albedo = true
	_mote_material.albedo_color = _mote_color
	_mote_material.emission_enabled = true
	_mote_material.emission = Color(_mote_color.r, _mote_color.g, _mote_color.b)
	_mote_material.emission_energy_multiplier = 1.4
	mote.material = _mote_material
	_motes.draw_pass_1 = mote
	_motes.emitting = false
	add_child(_motes)


func _local_players() -> Array[ActorBase]:
	var locals: Array[ActorBase] = []
	if CombatDirector.current == null:
		return locals
	for member: ActorBase in CombatDirector.current.party_actors():
		if is_instance_valid(member) and member.is_inside_tree() and member.is_local_player() and not member.is_companion:
			locals.append(member)
	return locals
