## The Caldera's sense of place (docs/33_SENSE_OF_PLACE.md), checked on the live archipelago. Run by
## tools/test_caldera_isles.gd (so by the smoke test and tools/run_caldera_checks.gd): `run` right after
## Embershore's worked land (Embershore live, every flag clear), `run_lit` right after the three Beacons are lit
## and the party has glided to The Crown:
##   1  each Friction Isle wears its own light, from its rock, its exposure and its Sign
##   2  each isle's colour field reads from across The Sound: Iron-Ness the warmest, Barrow-Eyot the most
##      violet, Rime-Firth the palest, every colour mid-value and never neon; underfoot the ground stays turf
##   3  each isle's meadow leans its wildflowers to its field
##   4  the far isles fade into the sky they stand against, in each isle's own light
##   5  a cold Beacon shows nothing on the far isles; a lit one burns on its isle's far silhouette
extends RefCounted

const FRICTION_ISLES: Array[StringName] = [CalderaAtlas.ISLE_IRON_NESS, CalderaAtlas.ISLE_BARROW_EYOT, CalderaAtlas.ISLE_RIME_FIRTH]
const OWN_LOOKS: Array[StringName] = [WorldVisualCatalog.IRON_NESS, WorldVisualCatalog.BARROW_EYOT, WorldVisualCatalog.RIME_FIRTH]
## The far silhouettes are sampled this far apart (ArchipelagoStreamer.IMPOSTOR_STEP).
const SAMPLE_STEP: float = 24.0
## Ground above this is land (the shore's sand and shingle lie below); snow lies above SNOW_LINE.
const LAND_FROM: float = 3.0
const SNOW_LINE: float = 55.0
## How far apart two isles' field measures must be to count as different (a mean over hundreds of samples).
const FIELD_MARGIN: float = 0.04

var check: Callable
var level: CalderaArchipelagoWorld
var tree: SceneTree


func run(live_level: CalderaArchipelagoWorld, checker: Callable, scene_tree: SceneTree) -> void:
	check = checker
	level = live_level
	tree = scene_tree
	_check_own_light()
	_check_colour_fields()
	_check_meadows()
	await _check_far_haze("Embershore")
	_check_far_beacons(false)


func run_lit(live_level: CalderaArchipelagoWorld, checker: Callable, scene_tree: SceneTree) -> void:
	check = checker
	level = live_level
	tree = scene_tree
	await _check_far_haze("The Crown")
	_check_far_beacons(true)


# --- 1: each isle's own light -------------------------------------------------------------------

func _check_own_light() -> void:
	var wrong: Array[String] = []
	var horizons: Array[Color] = []
	var fogs: Array[Color] = []
	var suns: Array[Color] = []
	for index: int in FRICTION_ISLES.size():
		var isle: IslandGridResource = CalderaAtlas.isle(FRICTION_ISLES[index])
		var look: ZoneBiomeResource = WorldVisualCatalog.biome(isle.visual_biome)
		if isle.visual_biome != OWN_LOOKS[index] or look == null or look.primary_scribe_sign != isle.scribe_sign or look.display_name != isle.display_name:
			wrong.append(isle.display_name)
			continue
		horizons.append(look.sky_horizon_color)
		fogs.append(look.fog_light_color)
		suns.append(look.sun_color)
	var distinct: bool = horizons.size() == 3
	for a: int in horizons.size():
		for b: int in range(a + 1, horizons.size()):
			distinct = distinct and not horizons[a].is_equal_approx(horizons[b]) and not fogs[a].is_equal_approx(fogs[b]) \
				and not suns[a].is_equal_approx(suns[b])
	var iron: ZoneBiomeResource = WorldVisualCatalog.biome(WorldVisualCatalog.IRON_NESS)
	var rime: ZoneBiomeResource = WorldVisualCatalog.biome(WorldVisualCatalog.RIME_FIRTH)
	var tide: ZoneBiomeResource = WorldVisualCatalog.biome(WorldVisualCatalog.BARROW_EYOT)
	# Iron-Ness's haze is the warmest, Rime-Firth's sky the bluest and its sun the coldest, Barrow-Eyot's fog the mistiest.
	var leaning: bool = iron != null and rime != null and tide != null \
		and iron.sky_horizon_color.r - iron.sky_horizon_color.b > tide.sky_horizon_color.r - tide.sky_horizon_color.b \
		and rime.sky_top_color.b - rime.sky_top_color.r > iron.sky_top_color.b - iron.sky_top_color.r \
		and rime.sun_color.b > iron.sun_color.b and tide.fog_density > iron.fog_density and tide.fog_density > rime.fog_density
	check.call(wrong.is_empty() and distinct and leaning,
		"each Friction Isle wears its own light, no longer a borrowed Vale petal's: Iron-Ness a warm amber haze, Barrow-Eyot a lilac fen mist, Rime-Firth a cold azure morning, each under its own Sign%s"
		% ("" if wrong.is_empty() else " (not: %s)" % ", ".join(wrong)))


# --- 2: the colour fields --------------------------------------------------------------------------

func _check_colour_fields() -> void:
	var means: Dictionary[StringName, Color] = {}
	var muddy: Array[String] = []
	var bare: Array[String] = []
	for isle_id: StringName in FRICTION_ISLES:
		var builder: IslandBuilder = CalderaAtlas.builder_for(isle_id)
		var half: Vector2 = builder.isle.half_size()
		var total: Color = Color(0.0, 0.0, 0.0, 0.0)
		var count: int = 0
		var turf: int = 0
		var z: float = -half.y
		while z <= half.y:
			var x: float = -half.x
			while x <= half.x:
				var h: float = builder.height_at(x, z)
				if h > LAND_FROM:
					# The colour the far silhouette is painted (ArchipelagoStreamer.ImpostorJob), and the ground's underfoot.
					var far: Color = builder.far_color(x, z, h, 1.0)
					var near: Color = builder.surface_color(x, z, h, 1.0)
					total += far
					count += 1
					if h < SNOW_LINE:
						for color: Color in [far, near]:
							if color.get_luminance() < 0.2 or color.get_luminance() > 0.8 or color.s > 0.7:
								muddy.append("%s %s" % [builder.isle.display_name, color.to_html(false)])
						turf += 1 if _reads_as_turf(near) else 0
					else:
						turf += 1
				x += SAMPLE_STEP
			z += SAMPLE_STEP
		means[isle_id] = total / float(maxi(count, 1))
		if float(turf) < 0.85 * float(count):
			bare.append("%s %d of %d" % [builder.isle.display_name, turf, count])
	var iron: Color = means[CalderaAtlas.ISLE_IRON_NESS]
	var tide: Color = means[CalderaAtlas.ISLE_BARROW_EYOT]
	var rime: Color = means[CalderaAtlas.ISLE_RIME_FIRTH]
	var warmest: bool = _warmth(iron) > maxf(_warmth(tide), _warmth(rime)) + FIELD_MARGIN
	var violetest: bool = _violet(tide) > maxf(_violet(iron), _violet(rime)) + FIELD_MARGIN
	var palest: bool = rime.get_luminance() > maxf(iron.get_luminance(), tide.get_luminance()) + FIELD_MARGIN
	check.call(warmest and violetest and palest and muddy.size() <= 3,
		"each isle's colour field reads from across The Sound (its far silhouette): Iron-Ness's rust bracken the warmest (%.2f), Barrow-Eyot's heather the most violet (%.2f), Rime-Firth's cotton-grass the palest (%.2f); every colour mid-value and never neon%s"
		% [_warmth(iron), _violet(tide), rime.get_luminance(), "" if muddy.size() <= 3 else " (%d off: %s)" % [muddy.size(), ", ".join(muddy.slice(0, 6))]])
	check.call(bare.is_empty(),
		"underfoot the field is in the plants: each isle's ground stays turf to the ground shader (green on top), so it keeps the turf's texture and never paints a whole isle as bare earth%s"
		% ("" if bare.is_empty() else " (not: %s)" % ", ".join(bare)))


## Whether the ground shader reads a painted colour as turf (storybook_world_common's terrain_class_weights):
## green on top, not warm enough for loam or sand, not grey enough for rock.
static func _reads_as_turf(painted: Color) -> bool:
	var top: float = maxf(painted.r, maxf(painted.g, painted.b))
	var saturation: float = (top - minf(painted.r, minf(painted.g, painted.b))) / maxf(top, 0.001)
	var green: float = smoothstep(0.0, 0.06, painted.g - maxf(painted.r, painted.b))
	var warm: float = smoothstep(0.02, 0.08, painted.r - painted.g) * (1.0 - green)
	var grey: float = (1.0 - smoothstep(0.08, 0.16, saturation)) * (1.0 - green)
	return warm < 0.5 and grey < 0.5


## Red over blue: rust and amber are warm.
static func _warmth(color: Color) -> float:
	return color.r - color.b


## Red and blue together over green: heather and lavender.
static func _violet(color: Color) -> float:
	return (color.r + color.b) * 0.5 - color.g


# --- 3: the meadows ----------------------------------------------------------------------------------

func _check_meadows() -> void:
	var leaning: bool = true
	for isle_id: StringName in FRICTION_ISLES:
		var shares: Array[float] = CalderaAtlas.builder_for(isle_id).meadow_flower_shares()
		var sum: float = 0.0
		for share: float in shares:
			sum += share
		leaning = leaning and shares.size() == IslandBuilder.MEADOW_FLOWER_SHARES.size() and is_equal_approx(sum, 1.0)
	var iron: Array[float] = CalderaAtlas.builder_for(CalderaAtlas.ISLE_IRON_NESS).meadow_flower_shares()
	var rime: Array[float] = CalderaAtlas.builder_for(CalderaAtlas.ISLE_RIME_FIRTH).meadow_flower_shares()
	leaning = leaning and iron.max() == iron[CalderaKit.Flower.BUTTERCUP] and rime[CalderaKit.Flower.DAISY] + rime[CalderaKit.Flower.COW_PARSLEY] >= 0.7
	# Barrow-Eyot's own meadow, grown as the streamer grows it: sea-lavender blue the commonest flower.
	var tide: IslandBuilder = CalderaAtlas.builder_for(CalderaAtlas.ISLE_BARROW_EYOT)
	var counts: Array[int] = []
	counts.resize(IslandBuilder.MEADOW_FLOWER_SHARES.size())
	counts.fill(0)
	for chunk: Vector2i in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1)]:
		var data: Dictionary = tide.build_chunk_data(chunk, 32, false, false, true)
		for cell: Variant in data.get("meadow", []):
			var flowers: Array = (cell as Dictionary)["flowers"]
			for kind: int in flowers.size():
				counts[kind] += (flowers[kind] as Array).size()
	var grown: int = 0
	for each: int in counts:
		grown += each
	var blue: bool = grown > 100 and counts.max() == counts[CalderaKit.Flower.CORNFLOWER]
	check.call(leaning and blue,
		"each isle's meadow leans its wildflowers to its field: gorse-gold buttercups on Iron-Ness, cotton-white daisies and cow parsley on Rime-Firth, and sea-lavender blue on Barrow-Eyot (%d of %d flowers grown there)"
		% [counts[CalderaKit.Flower.CORNFLOWER], grown])


# --- 4: the far haze -----------------------------------------------------------------------------------

func _check_far_haze(where: String) -> void:
	var director: WorldAtmosphereDirector = WorldAtmosphereDirector.current
	if director == null:
		check.call(false, "the Atmosphere is running")
		return
	director.settle()
	await tree.process_frame
	var look: Dictionary = director.look_snapshot()
	var want: Color = (look["sky_horizon"] as Color).lerp(look["sky_top"] as Color, CalderaArchipelagoWorld.FAR_HAZE_COOL)
	var given: Variant = level.streamer.impostor_material.get_shader_parameter(&"horizon_color")
	var on_material: bool = given is Color and (given as Color).is_equal_approx(want)
	check.call(level.streamer.far_haze.is_equal_approx(want) and on_material and not want.is_equal_approx(Color(0.72, 0.78, 0.84)),
		"from %s the far isles fade into the sky behind them (its horizon, a quarter toward its blue: %s), not one fixed grey"
		% [where, want.to_html(false)])


# --- 5: the far Beacons ----------------------------------------------------------------------------------

func _check_far_beacons(lit: bool) -> void:
	var right: Array[String] = []
	var wrong: Array[String] = []
	for isle_id: StringName in FRICTION_ISLES:
		if isle_id == level.streamer.active_isle:
			continue
		var silhouette: MeshInstance3D = level.streamer.impostor_for(isle_id)
		var far: FarBeacon = silhouette.get_node_or_null("FarBeacon") as FarBeacon if silhouette != null else null
		var builder: IslandBuilder = CalderaAtlas.builder_for(isle_id)
		var isle_name: String = builder.isle.display_name
		if far == null:
			wrong.append("%s has none" % isle_name)
			continue
		# The fire stands over the Beacon's tower on the lifted silhouette, unstretched itself.
		var spot: Vector3 = builder.beacon_spot()
		var ground_y: float = silhouette.global_position.y + spot.y * ArchipelagoStreamer.IMPOSTOR_LIFT
		var over: float = far.fire.global_position.y - ground_y
		var placed: bool = Vector2(far.global_position.x - silhouette.global_position.x - spot.x, far.global_position.z - silhouette.global_position.z - spot.z).length() < 0.5 \
			and over > FarBeacon.FIRE_ABOVE_GROUND and absf(far.global_transform.basis.get_scale().y - 1.0) < 0.01
		if far.is_visible_in_tree() == lit and far.smoke.emitting == lit and placed:
			right.append(isle_name)
		else:
			wrong.append(isle_name)
	var wanted: int = FRICTION_ISLES.size() - (1 if FRICTION_ISLES.has(level.streamer.active_isle) else 0)
	if lit:
		check.call(right.size() == wanted and wrong.is_empty(),
			"seen from %s, each lit Beacon burns on its isle's far silhouette, fire and smoke over its tower: %s%s"
			% [level.streamer.builder.isle.display_name, ", ".join(right), "" if wrong.is_empty() else " (wrong: %s)" % ", ".join(wrong)])
	else:
		check.call(right.size() == wanted and wrong.is_empty(),
			"seen from %s, a cold Beacon shows no fire on the far isles: %s wait dark%s"
			% [level.streamer.builder.isle.display_name, ", ".join(right), "" if wrong.is_empty() else " (wrong: %s)" % ", ".join(wrong)])
