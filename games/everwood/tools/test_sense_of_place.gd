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
##   6  the Caldera's sun is an autumn afternoon's, still south-south-east
##   7  the farm's and the hedges' voices: every take sounds, rests on the G pentatonic, never clips, and the
##      ewe's bleat quavers
##   8  a startled ewe bleats and a goose honks at a hero who comes near
##   9  the birds sing round the party, fall silent in the hush, and burst into song at a bloom
##  10  the Mill-Downs reveal: by the windmill, looking back over the valley, once per hero
extends RefCounted

const Succession = ZoneSuccessionVisualResource.SuccessionState
## The ewe's bleat quavers at about this rate (PastoralVoices.EWE_QUAVER).
const BLEAT_QUAVER_HZ: float = 7.5

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
	_check_autumn_sun()
	_check_voices()
	await _check_stock_calls()
	await _check_birdsong()
	await _check_mill_downs_reveal()
	# Back to the start, the window built, for the checks that follow.
	level.place_party_at(CalderaAtlas.ARRIVE_START)
	level.streamer.load_now([level.tether_centroid()])
	await _frames(2)


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


# --- 6: the autumn sun -------------------------------------------------------------------------------------

func _check_autumn_sun() -> void:
	var sun: DirectionalLight3D = level.find_child("Sun", true, false) as DirectionalLight3D
	var shine: Vector3 = -sun.global_transform.basis.z if sun != null else Vector3.ZERO
	var high: float = rad_to_deg(asin(clampf(-shine.y, -1.0, 1.0)))
	# Where the light comes from: east and south (+X, +Z), as it always has (docs/32 sited the steadings by it).
	var from: Vector2 = Vector2(-shine.x, -shine.z)
	check.call(sun != null and absf(high - CalderaArchipelagoWorld.SUN_HIGH_DEGREES) < 0.5 and from.x > 0.0 and from.y > 0.0 and from.y > from.x,
		"the Caldera's sun is an autumn afternoon's, %.0f degrees up (it was 48, a midday sun), still south-south-east" % high)


# --- 7: the voices ---------------------------------------------------------------------------------------------

func _check_voices() -> void:
	PastoralVoices.wait_until_ready()
	var wrong: Array[String] = []
	for voice: int in PastoralVoices.Voice.size():
		var voice_name: String = String(PastoralVoices.Voice.keys()[voice]).to_lower()
		for take: int in PastoralVoices.TAKES:
			var sound: AudioStreamWAV = PastoralVoices.stream(voice as PastoralVoices.Voice, take)
			if sound == null:
				wrong.append("%s %d missing" % [voice_name, take])
				continue
			var samples: PackedFloat32Array = _decode(sound)
			var seconds: float = samples.size() / float(PastoralVoices.MIX_RATE)
			var top: float = 0.0
			var power: float = 0.0
			for value: float in samples:
				top = maxf(top, absf(value))
				power += value * value
			var rms: float = sqrt(power / maxf(samples.size(), 1.0))
			var midi: int = PastoralVoices.resting_midi(voice as PastoralVoices.Voice, take)
			if seconds < 0.4 or seconds > 2.6 or top > PastoralVoices.PEAK + 0.01 or top < PastoralVoices.PEAK - 0.05 or rms < 0.03 \
					or not PastoralVoices.PENTATONIC_CLASSES.has(posmod(midi, 12)):
				wrong.append("%s %d (%.2f s, peak %.2f, rms %.3f, midi %d)" % [voice_name, take, seconds, top, rms, midi])
	var same: bool = PastoralVoices.render_samples(PastoralVoices.Voice.CATTLE, 1) == PastoralVoices.render_samples(PastoralVoices.Voice.CATTLE, 1)
	var quavers: float = _bleat_quaver(PastoralVoices.render_samples(PastoralVoices.Voice.SHEEP, 0))
	check.call(wrong.is_empty() and same and absf(quavers - BLEAT_QUAVER_HZ) < 1.5,
		"the farm's and the hedges' voices (ewe, lamb, cow, hen, goose, blackbird, wren), %d takes each: each sounds, never clips, rests on the Chime-Shrine's G pentatonic so it never clashes with the score, renders the same every time, and the ewe's bleat quavers (%.1f a second)%s"
		% [PastoralVoices.TAKES, quavers, "" if wrong.is_empty() else " (wrong: %s)" % ", ".join(wrong)])


static func _decode(sound: AudioStreamWAV) -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(sound.data.size() / 2)
	for index: int in samples.size():
		samples[index] = sound.data.decode_s16(index * 2) / 32768.0
	return samples


## How often a bleat's loudness swells in its held middle (peaks a second of its 10 ms envelope).
static func _bleat_quaver(samples: PackedFloat32Array) -> float:
	var frame: int = PastoralVoices.MIX_RATE / 100
	var envelope: PackedFloat32Array = PackedFloat32Array()
	for at: int in range(0, samples.size() - frame, frame):
		var power: float = 0.0
		for index: int in frame:
			power += samples[at + index] * samples[at + index]
		envelope.append(sqrt(power / frame))
	var loud: float = 0.0
	for value: float in envelope:
		loud = maxf(loud, value)
	var first: int = -1
	var last: int = -1
	for index: int in envelope.size():
		if envelope[index] > loud * 0.3:
			last = index
			if first < 0:
				first = index
	var from: int = first + int((last - first) * 0.15)
	var to: int = first + int((last - first) * 0.85)
	var peaks: int = 0
	for index: int in range(maxi(from, 2), mini(to, envelope.size() - 2)):
		if envelope[index] >= envelope[index - 1] and envelope[index] > envelope[index + 1] and envelope[index] >= envelope[index - 2] \
				and envelope[index] > envelope[index + 2]:
			peaks += 1
	return peaks / maxf((to - from) * 0.01, 0.01)


# --- 8: the flocks' calls --------------------------------------------------------------------------------------

func _check_stock_calls() -> void:
	var p1: ActorBase = level.birdsong.listener() if level.birdsong != null else null
	var sheep: GrazingStock = _flock(GrazingStock.Kind.SHEEP)
	var geese: GrazingStock = _flock(GrazingStock.Kind.GEESE)
	if p1 == null or sheep == null or geese == null:
		check.call(false, "a hero, a flock of sheep and a gaggle of geese stand on Embershore")
		return
	# A hero comes by (the flock wakes and takes up its round), then walks right up to a ewe: she gives way, and bleats.
	await _wake(sheep, p1)
	# Past the flock's cooldown from any call while it woke, so the next startle is heard.
	await _frames(int(ceil(GrazingStock.STARTLE_COOLDOWN * 60.0)) + 6)
	var before: int = sheep.calls
	# She walks her round and gives way, so the hero keeps stepping up to where she stands now.
	for step: int in 10:
		p1.place_at(Transform3D(Basis.IDENTITY, sheep.where(0) + Vector3(0.6, 0.4, 0.0)))
		await _frames(6)
		if sheep.calls > before:
			break
	var bleated: bool = sheep.calls > before and sheep.last_voice in [PastoralVoices.Voice.SHEEP, PastoralVoices.Voice.LAMB]
	# A goose holds its ground and honks.
	await _wake(geese, p1)
	var honks: int = geese.calls
	for step: int in 10:
		p1.place_at(Transform3D(Basis.IDENTITY, geese.where(0) + Vector3(2.5, 0.4, 0.0)))
		await _frames(6)
		if geese.calls > honks:
			break
	var honked: bool = geese.calls > honks and geese.last_voice == PastoralVoices.Voice.GEESE
	check.call(bleated and honked,
		"the stock have voices: a ewe a hero walks up to gives way and bleats, and a goose holds its ground and honks at them (bleat %s, %d to %d calls; honk %s, %d to %d)"
		% [bleated, before, sheep.calls, honked, honks, geese.calls])


## Stands the hero a little off a flock until it's awake and walking its round.
func _wake(flock: GrazingStock, hero: ActorBase) -> void:
	hero.place_at(Transform3D(Basis.IDENTITY, flock.global_position + Vector3(GrazingStock.AWAKE_RANGE[flock.kind] * 0.5 + flock.reach, 0.4, 0.0)))
	await _frames(90)


func _flock(kind: GrazingStock.Kind) -> GrazingStock:
	for node: Node in level.streamer.structures.find_children("*", "GrazingStock", true, false):
		var flock: GrazingStock = node as GrazingStock
		if flock != null and flock.kind == kind and flock.count > 0:
			return flock
	return null


# --- 9: the birds ------------------------------------------------------------------------------------------------

func _check_birdsong() -> void:
	var birds: Birdsong = level.birdsong
	var p1: ActorBase = birds.listener() if birds != null else null
	if p1 == null:
		check.call(false, "the birds sing round Player 1")
		return
	level.place_party_at(CalderaAtlas.ARRIVE_START)
	level.streamer.load_now([level.tether_centroid()])
	await _frames(2)
	var here: Vector3 = p1.global_position
	var sang: bool = false
	for attempt: int in 6:
		sang = sang or birds.try_sing(here) == &"sang"
	# A Hush-Crack opens 30 m off: by it no bird sings.
	var spot: Vector3 = here + Vector3(30.0, 0.0, 0.0)
	spot.y = level.streamer.height_at(spot.x, spot.z)
	var crack: HushCrackLandmark = HushCrackLandmark.new()
	crack.crack_id = &"sense_of_place_check"
	level.add_child(crack)
	crack.global_position = spot
	await _frames(2)
	var hushed_before: int = birds.hushed
	var silent: bool = birds.try_sing(spot) == &"hushed" and birds.hushed == hushed_before + 1
	# Calmed: the bloom sweeps out and the birds round it take up their song.
	var sung_before: int = birds.sung
	var bursts_before: int = birds.bursts
	crack.set_state(Succession.ZONE_RECLAIMED, true)
	if WorldAtmosphereDirector.current.blooms_running() == 0:
		WorldAtmosphereDirector.current.bloom_at(spot)
	await _frames(180)
	var burst: bool = birds.bursts > bursts_before and birds.sung >= sung_before + Birdsong.BURST_SONGS
	var again: bool = birds.try_sing(spot) != &"hushed"
	crack.queue_free()
	await _frames(1)
	check.call(sang and silent and burst and again,
		"the birds sing round the party; by an open Hush-Crack they fall silent, and when it's calmed and its bloom sweeps out they burst into song there (%d songs; sang %s, silent %s, burst %s, again %s)"
		% [birds.sung - sung_before, sang, silent, burst, again])


# --- 10: the Mill-Downs reveal -------------------------------------------------------------------------------------

func _check_mill_downs_reveal() -> void:
	var reveal: VistaReveal = level.streamer.structures.find_child("MillDownsReveal", true, false) as VistaReveal
	var windmill: Node3D = level.streamer.structures.find_child("Windmill", true, false) as Node3D
	var builder: EmbershoreBuilder = level.streamer.builder as EmbershoreBuilder
	var p1: ActorBase = level.birdsong.listener() if level.birdsong != null else null
	if reveal == null or windmill == null or builder == null or p1 == null:
		check.call(false, "the Mill-Downs reveal stands by the windmill")
		return
	var oak: Vector3 = builder.landmark(&"elder_oak")
	var toward_oak: Vector3 = Vector3(oak.x - reveal.global_position.x, 0.0, oak.z - reveal.global_position.z).normalized()
	var toward_look: Vector3 = Vector3(reveal.look_at_point.x - reveal.global_position.x, 0.0, reveal.look_at_point.z - reveal.global_position.z).normalized()
	var placed: bool = reveal.global_position.distance_to(windmill.global_position) < 45.0 and toward_oak.dot(toward_look) > 0.99 \
		and reveal.reveal_id == VistaReveal.MILL_DOWNS and reveal.reveal_id != VistaReveal.DOVERSLAP
	PartyProgress.current.reveals_seen.clear()
	var camera: PlayerCamera = level.grid.camera_for(p1.player_id)
	var shown_before: int = reveal.shown
	level.streamer.load_now([reveal.global_position])
	p1.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(0.0, 0.4, 0.0)))
	await _frames(3)
	var who: StringName = p1.loadout.class_id
	var played: bool = reveal.shown == shown_before + 1 and camera != null and camera.is_revealing() \
		and PartyProgress.current.has_seen_reveal(VistaReveal.MILL_DOWNS, who)
	p1.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(0.0, 0.4, 30.0)))
	await _frames(2)
	p1.place_at(Transform3D(Basis.IDENTITY, reveal.global_position + Vector3(0.0, 0.4, 0.0)))
	await _frames(3)
	var once: bool = reveal.shown == shown_before + 1
	check.call(placed and played and once,
		"the Mill-Downs reveal: where the Downs road passes the windmill, a hero's camera looks back over the worked valley toward the Elder Oak, once per hero")


func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame
