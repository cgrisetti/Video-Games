## Every acoustic profile by id (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §1.1, 08 Gate 4):
## zones, the Four Signs' stingers, the nine Callings' voices and boss suites,
## as typed resources. The built-ins are registered in code; any
## ZoneMusicProfileResource, SignHarmonicProfileResource,
## CallingAudioProfileResource or BossAudioProfileResource saved as a .tres in
## res://data/audio/ is registered by its type, and replaces a built-in of the
## same id. AudioDirector and the levels only ever name profiles by id.
##
## The Bramble-Bridge trail (one regional tonic of G at 108 BPM, 16 §3), with the
## bars of each baked arrangement (tools/build_audio_stems.py composes them):
##   honey_wick              the Kindle-Fire at Honey-Wick, Chunk (0, 1)  G Ionian, 6/8 sway, 16 bars
##   bramble_bridge_square   Bramble-Bridge, Chunk (0, 0)                  G Lydian 3/4 flying waltz, 24 bars
##   moss_oak_hollow         Moss-Oak Hollow, Chunk (0, -1), sinking into Rush-Light-Hollow's
##                           E harmonic-minor invention on the sunken lane  E Dorian 3/4 waltz, 16 bars
##   dover_slap_falls        Doverslap Bridge and the falls, Chunk (0, -2) A Dorian 4/4 march, 16 bars
##   ring_of_the_cairnsman   the causeway and the Ring, Chunk (0, -3)      D Dorian 3/4, 16 bars
##   cairnsmans_vigil        the Cairnsman's suite                         D Dorian / Lydian 6/8 gallop at 132, 16 bars
## and oakshire_vale, the legacy Oakshire Vale's F Lydian waltz (104 BPM, 16 bars). The Caldera
## Isles' two Audio Mosaics (16 §7), twelve four-bar phrase cells each in six moods:
##   millers_holm            Miller's Oak, the mill-isle where every launch begins  F Lydian / D Dorian 6/8 at 104
##   crown_island            The Crown                                            G Lydian / E Dorian 3/4 at 110
## (The audio doc's suite names map on: kindled_bivouac is honey_wick, bramblebridge_square
## bramble_bridge_square, ariundle_holloway moss_oak_hollow, doverslap_gorge dover_slap_falls,
## cairnsman_sanctum ring_of_the_cairnsman and boss_cairnsman_vigil cairnsmans_vigil.)
class_name AudioCatalog
extends RefCounted

const DATA_FOLDER: String = "res://data/audio/"

const IONIAN: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const LYDIAN: Array[int] = [0, 2, 4, 6, 7, 9, 11]
const DORIAN: Array[int] = [0, 2, 3, 5, 7, 9, 10]
const AEOLIAN: Array[int] = [0, 2, 3, 5, 7, 8, 10]
const MIXOLYDIAN: Array[int] = [0, 2, 4, 5, 7, 9, 10]
const HARMONIC_MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 11]

static var _zones: Dictionary[StringName, ZoneMusicProfileResource] = {}
static var _signs: Dictionary[StringName, SignHarmonicProfileResource] = {}
static var _callings: Dictionary[StringName, CallingAudioProfileResource] = {}
static var _bosses: Dictionary[StringName, BossAudioProfileResource] = {}


static func zone(id: StringName) -> ZoneMusicProfileResource:
	_ensure()
	return _zones.get(id, null)


static func zones() -> Array[ZoneMusicProfileResource]:
	_ensure()
	var list: Array[ZoneMusicProfileResource] = []
	list.assign(_zones.values())
	return list


## A Sign's stinger by its ScribeSignResource.Sign value.
static func sign_profile(scribe_sign: int) -> SignHarmonicProfileResource:
	_ensure()
	var keys: Array = ScribeSignResource.Sign.keys()
	if scribe_sign < 0 or scribe_sign >= keys.size():
		return null
	return _signs.get(StringName(keys[scribe_sign]), null)


static func signs() -> Array[SignHarmonicProfileResource]:
	_ensure()
	var list: Array[SignHarmonicProfileResource] = []
	list.assign(_signs.values())
	return list


static func calling(id: StringName) -> CallingAudioProfileResource:
	_ensure()
	return _callings.get(id, null)


static func callings() -> Array[CallingAudioProfileResource]:
	_ensure()
	var list: Array[CallingAudioProfileResource] = []
	list.assign(_callings.values())
	return list


static func boss(id: StringName) -> BossAudioProfileResource:
	_ensure()
	return _bosses.get(id, null)


static func bosses() -> Array[BossAudioProfileResource]:
	_ensure()
	var list: Array[BossAudioProfileResource] = []
	list.assign(_bosses.values())
	return list


## Registers any audio profile by its type (a .tres from DATA_FOLDER, or code).
static func register(profile: Resource) -> void:
	if profile is ZoneMusicProfileResource:
		_zones[(profile as ZoneMusicProfileResource).profile_id] = profile
	elif profile is SignHarmonicProfileResource:
		_signs[(profile as SignHarmonicProfileResource).sign_id] = profile
	elif profile is CallingAudioProfileResource:
		_callings[(profile as CallingAudioProfileResource).calling_id] = profile
	elif profile is BossAudioProfileResource:
		_bosses[(profile as BossAudioProfileResource).boss_id] = profile


static func _ensure() -> void:
	if not _zones.is_empty():
		return
	_build_zones()
	_build_signs()
	_build_callings()
	_build_bosses()
	_load_folder()


static func _load_folder() -> void:
	var folder: DirAccess = DirAccess.open(DATA_FOLDER)
	if folder == null:
		return
	for file: String in folder.get_files():
		var path: String = DATA_FOLDER + file.trim_suffix(".remap")
		if path.ends_with(".tres") or path.ends_with(".res"):
			register(load(path))


# --- Zones (16 §4) -----------------------------------------------------------

static func _build_zones() -> void:
	var commons: ZoneMusicProfileResource = _zone(&"honey_wick", "The Kindle-Fire at Honey-Wick", 67, &"G_IONIAN", 108.0, 3, true,
		[0, 2, 4, 6, 7, 9, 11], HARMONIC_MINOR, [0, 3, 4, 0], &"WHISTLE")
	commons.melody_skips_degrees = PackedInt32Array([3])
	commons.lead_scale = PackedInt32Array(IONIAN)
	commons.silence_interval_range_sec = Vector2(15.0, 25.0)
	commons.arrangement_bars = 16
	var square: ZoneMusicProfileResource = _zone(&"bramble_bridge_square", "Bramble-Bridge Waltz", 67, &"G_LYDIAN", 108.0, 3, false,
		LYDIAN, HARMONIC_MINOR, [0, 1, 6, 0], &"ACCORDION")
	square.silence_interval_range_sec = Vector2(12.0, 20.0)
	square.sanctuary_cadence_on_arrival = true
	square.arrangement_bars = 24
	var hollow: ZoneMusicProfileResource = _zone(&"moss_oak_hollow", "Moss-Oak Hollow into Rush-Light-Hollow", 64, &"E_DORIAN", 108.0, 3, false,
		DORIAN, HARMONIC_MINOR, [0, 3, 6, 0], &"REED")
	hollow.enable_z_depth_discord_blend = true
	hollow.discord_blend_z_start = -54.0
	hollow.discord_blend_z_full = -74.0
	hollow.silence_interval_range_sec = Vector2(20.0, 35.0)
	hollow.arrangement_bars = 16
	var falls: ZoneMusicProfileResource = _zone(&"dover_slap_falls", "Doverslap Falls March", 69, &"A_DORIAN", 108.0, 4, false,
		DORIAN, AEOLIAN, [0, 6, 3, 0], &"VIOLIN")
	falls.silence_interval_range_sec = Vector2(15.0, 30.0)
	falls.arrangement_bars = 16
	var ring: ZoneMusicProfileResource = _zone(&"ring_of_the_cairnsman", "The Ring of the Cairnsman", 62, &"D_DORIAN", 108.0, 3, false,
		DORIAN, HARMONIC_MINOR, [0, 6, 0, 3], &"WHISTLE")
	# Wind-swept solitude: a low whistle and a harp harmonic over the gorge wind.
	ring.explore_stem_volumes_db = PackedFloat32Array([-14.0, -3.0, -80.0, -80.0])
	ring.arrangement_bars = 16
	var vigil: ZoneMusicProfileResource = _zone(&"cairnsmans_vigil", "The Cairnsman's Vigil", 62, &"D_DORIAN", 132.0, 3, true,
		LYDIAN, HARMONIC_MINOR, [0, 6, 3, 4], &"ACCORDION")
	# The boss deck: Stem 1 is the D Lydian flourish, held back for the Poise-Stagger window.
	vigil.explore_stem_volumes_db = PackedFloat32Array([0.0, -80.0, -6.0, 0.0])
	vigil.music_cycle_sec = INF
	vigil.arrangement_bars = 16
	var vale: ZoneMusicProfileResource = _zone(&"oakshire_vale", "Oakshire Vale Pastoral", 65, &"F_LYDIAN", 104.0, 3, false,
		LYDIAN, HARMONIC_MINOR, [0, 1, 4, 0], &"VIOLIN")
	vale.silence_interval_range_sec = Vector2(15.0, 30.0)
	vale.arrangement_bars = 16
	for made: ZoneMusicProfileResource in [commons, square, hollow, falls, ring, vigil, vale]:
		register(made)
	_build_crown_zones()
	_build_mosaics()


## The Crown's five suites (docs/23 §7): one key signature (D major's notes), five modes, and
## The World-Tree's hymn in each, so the crossfade at a spring never clashes.
static func _build_crown_zones() -> void:
	var made: Array[ZoneMusicProfileResource] = [
		_zone(&"crown_south_bay", "The Lantern-Bearers' Landing", 62, &"D_IONIAN", 96.0, 3, false, IONIAN, HARMONIC_MINOR, [0, 3, 5, 4], &"ACCORDION"),
		_zone(&"crown_iron_shore", "Old King's Anvil", 69, &"A_MIXOLYDIAN", 92.0, 4, false, MIXOLYDIAN, DORIAN, [0, 6, 3, 4], &"OBOE"),
		_zone(&"crown_gale_cliffs", "Breach Wind", 64, &"E_DORIAN", 104.0, 3, true, DORIAN, AEOLIAN, [0, 6, 5, 0], &"WHISTLE"),
		_zone(&"crown_tide_grottos", "The Weeping Sluices", 59, &"B_AEOLIAN", 84.0, 3, false, AEOLIAN, HARMONIC_MINOR, [0, 5, 3, 4], &"OBOE"),
		_zone(&"crown_millers_oak", "World-Tree", 67, &"G_LYDIAN", 88.0, 3, false, LYDIAN, HARMONIC_MINOR, [0, 1, 6, 4], &"VIOLIN")]
	for profile: ZoneMusicProfileResource in made:
		profile.arrangement_bars = 16
		profile.silence_interval_range_sec = Vector2(18.0, 32.0)
		register(profile)



# --- The Audio Mosaics (16 §7) -----------------------------------------------
#
# Twelve four-bar cells a zone, two in each mood, in suite order: Peace, Wonder, Interest,
# Curiosity, Anxiousness, Mellow. Each mood's two cells carry the lead on different Hisaishi
# Quartet voicings, and the suite order never puts one voicing twice in a row.
# tools/build_audio_stems.py composes the same cells (same ids, chords and voices); the
# checks fail if the two drift apart.

const MOOD_PEACE: int = ZoneMusicProfileResource.MoodState.PEACE
const MOOD_WONDER: int = ZoneMusicProfileResource.MoodState.WONDER
const MOOD_INTEREST: int = ZoneMusicProfileResource.MoodState.INTEREST
const MOOD_CURIOSITY: int = ZoneMusicProfileResource.MoodState.CURIOSITY
const MOOD_ANXIOUS: int = ZoneMusicProfileResource.MoodState.ANXIOUSNESS
const MOOD_MELLOW: int = ZoneMusicProfileResource.MoodState.MELLOW
const VAR_A: int = ZoneMusicProfileResource.LeadVoice.OCEAN_VIEW
const VAR_B: int = ZoneMusicProfileResource.LeadVoice.SKY_SOAR
const VAR_C: int = ZoneMusicProfileResource.LeadVoice.WOODWIND_DIALOGUE
const VAR_D: int = ZoneMusicProfileResource.LeadVoice.PASTORAL_HEARTH
## Where an unchosen cell goes next: Curiosity and Anxiousness both ease into Mellow.
const MOSAIC_FALLBACKS: Dictionary[int, int] = {7: 10, 9: 10}


static func _build_mosaics() -> void:
	# The Crown: Hisaishi's Town With An Ocean View by the sea. G Lydian and Ionian at 110 in 3/4,
	# a crisp mandolin, pizzicato walking bass, button accordion and a soaring seaside violin,
	# turning to misty E Dorian and E harmonic-minor bassoon along the cliffs and grottos.
	var crown: ZoneMusicProfileResource = _zone(&"crown_island", "The Crown's Sea-Wind Mosaic", 67, &"G_LYDIAN", 110.0, 3, false,
		LYDIAN, HARMONIC_MINOR, [0, 1, 3, 0], &"ACCORDION")
	_mosaic(crown, [
		[&"peace_a", MOOD_PEACE, VAR_B, "Fiddle/Harp", &"F", &"G_PENTATONIC", ["Gadd9", "C/G", "Em7/G", "D/G"]],
		[&"peace_b", MOOD_PEACE, VAR_D, "Recorder/Harp", &"F", &"G_PENTATONIC", ["Gadd9", "Em7/G", "C/G", "Gadd9"]],
		[&"wonder_a", MOOD_WONDER, VAR_A, "Accordion/Pizz", &"B", &"G_LYDIAN", ["G", "A7", "Cmaj7", "G"]],
		[&"wonder_b", MOOD_WONDER, VAR_B, "Violin/Harp", &"B", &"G_LYDIAN", ["Gmaj7", "A9", "Cmaj7#11", "Gadd9"]],
		[&"interest_a", MOOD_INTEREST, VAR_C, "Oboe/Bassoon", &"A", &"G_IONIAN", ["G", "E7", "Am7", "D7"]],
		[&"interest_b", MOOD_INTEREST, VAR_A, "Accordion/Pizz", &"A", &"G_IONIAN", ["G", "E7/G#", "Am7", "D7"]],
		[&"curiosity_a", MOOD_CURIOSITY, VAR_C, "Oboe/Bassoon", &"C", &"E_DORIAN", ["Em", "A", "Em7", "Bm"]],
		[&"curiosity_b", MOOD_CURIOSITY, VAR_D, "Whistle/Harp", &"C", &"E_DORIAN", ["Em", "A/E", "Em7", "Bm7"]],
		[&"anxious_a", MOOD_ANXIOUS, VAR_A, "Accordion/Bassoon", &"E", &"E_HARMONIC_MINOR", ["Em", "C", "D#dim7", "B7b9"]],
		[&"anxious_b", MOOD_ANXIOUS, VAR_C, "Oboe/Bassoon", &"E", &"E_HARMONIC_MINOR", ["Em", "C", "D#dim7", "B7b9"]],
		[&"mellow_a", MOOD_MELLOW, VAR_B, "Cello/Violin", &"D", &"G_MIXOLYDIAN", ["Em", "Bm", "C", "G/B"]],
		[&"mellow_b", MOOD_MELLOW, VAR_D, "Low Whistle/English Horn", &"D", &"G_MIXOLYDIAN", ["Em7", "Bm7", "Cmaj7", "G/B"]],
	])
	# Arriving by skiff at South Bay with the World-Tree ahead: it opens in Wonder.
	crown.opening_cell = 2
	register(crown)
	# Miller's Oak, the mill-isle (the brief's Miller's Holm): Howard Shore's Concerning Hobbits
	# and Hisaishi's Mother's Broom. F Lydian and D Dorian at 104 in 6/8, a guitar and hammered
	# dulcimer turning like the waterwheel, a warm low whistle, cello, and oboe-and-bassoon
	# inventions. Every launch begins in its orchards, so it opens in Peace.
	var holm: ZoneMusicProfileResource = _zone(&"millers_holm", "Miller's Oak's Mill-Wheel Mosaic", 65, &"F_LYDIAN", 104.0, 3, true,
		LYDIAN, HARMONIC_MINOR, [0, 1, 3, 0], &"WHISTLE")
	_mosaic(holm, [
		[&"peace_a", MOOD_PEACE, VAR_B, "Fiddle/Harp", &"F", &"F_PENTATONIC", ["Fadd9", "Bb/F", "Dm7/F", "C/F"]],
		[&"peace_b", MOOD_PEACE, VAR_D, "Recorder/Harp", &"F", &"F_PENTATONIC", ["Fadd9", "Dm7/F", "Bb/F", "Fadd9"]],
		[&"wonder_a", MOOD_WONDER, VAR_A, "Accordion/Pizz", &"B", &"F_LYDIAN", ["F", "G7", "Bbmaj7", "F"]],
		[&"wonder_b", MOOD_WONDER, VAR_B, "Violin/Harp", &"B", &"F_LYDIAN", ["Fmaj7", "G9", "Bbmaj7#11", "Fadd9"]],
		[&"interest_a", MOOD_INTEREST, VAR_C, "Oboe/Bassoon", &"A", &"F_IONIAN", ["F", "D7", "Gm7", "C7"]],
		[&"interest_b", MOOD_INTEREST, VAR_A, "Accordion/Pizz", &"A", &"F_IONIAN", ["F", "D7/F#", "Gm7", "C7"]],
		[&"curiosity_a", MOOD_CURIOSITY, VAR_C, "Oboe/Bassoon", &"C", &"D_DORIAN", ["Dm", "G", "Dm7", "Am"]],
		[&"curiosity_b", MOOD_CURIOSITY, VAR_D, "Whistle/Harp", &"C", &"D_DORIAN", ["Dm", "G/D", "Dm7", "Am7"]],
		[&"anxious_a", MOOD_ANXIOUS, VAR_A, "Accordion/Bassoon", &"E", &"D_HARMONIC_MINOR", ["Dm", "Bb", "C#dim7", "A7b9"]],
		[&"anxious_b", MOOD_ANXIOUS, VAR_C, "Oboe/Bassoon", &"E", &"D_HARMONIC_MINOR", ["Dm", "Bb", "C#dim7", "A7b9"]],
		[&"mellow_a", MOOD_MELLOW, VAR_B, "Cello/Violin", &"D", &"F_MIXOLYDIAN", ["Dm", "Am", "Bb", "F/A"]],
		[&"mellow_b", MOOD_MELLOW, VAR_D, "Low Whistle/English Horn", &"D", &"F_MIXOLYDIAN", ["Dm7", "Am7", "Bbmaj7", "F/A"]],
	])
	holm.opening_cell = 0
	register(holm)


## Fills a zone's mosaic from [id, mood, voice, voice label, chord cell, mode, chords] rows;
## each mood's first row is its FIRST half.
static func _mosaic(zone: ZoneMusicProfileResource, rows: Array[Array]) -> void:
	var seen: Dictionary[int, bool] = {}
	for index: int in rows.size():
		var row: Array = rows[index]
		var made: MosaicCellResource = MosaicCellResource.new()
		made.cell_id = row[0]
		made.mood = int(row[1]) as ZoneMusicProfileResource.MoodState
		made.half = MosaicCellResource.Half.SECOND if seen.has(made.mood) else MosaicCellResource.Half.FIRST
		seen[made.mood] = true
		made.lead_voice = int(row[2]) as ZoneMusicProfileResource.LeadVoice
		made.voice_label = row[3]
		made.chord_cell = row[4]
		made.mode_label = row[5]
		made.chords = PackedStringArray(row[6])
		made.bars = 4
		made.fallback_next = MOSAIC_FALLBACKS.get(index, (index + 1) % rows.size())
		zone.mosaic_cells.append(made)
	zone.phrase_bars = 4
	zone.arrangement_bars = zone.phrase_bars * rows.size()
	# The Emergent Silence breath (Brower): 12-25 s of fading harp after about 80 s of music.
	zone.silence_interval_range_sec = Vector2(12.0, 25.0)
	zone.music_cycle_sec = 80.0


static func _zone(id: StringName, title: String, root: int, mode: StringName, tempo: float, beats: int, compound: bool,
		lead: Array[int], discord: Array[int], chords: Array[int], timbre: StringName) -> ZoneMusicProfileResource:
	var made: ZoneMusicProfileResource = ZoneMusicProfileResource.new()
	made.profile_id = id
	made.display_title = title
	made.root_pitch_midi = root
	made.modal_signature = mode
	made.bpm = tempo
	made.beats_per_bar = beats
	made.compound_meter = compound
	made.lead_scale = PackedInt32Array(lead)
	made.discord_scale = PackedInt32Array(discord)
	made.progression = PackedInt32Array(chords)
	made.lead_timbre = timbre
	return made


# --- The Four Signs (16 §4.1) ------------------------------------------------

static func _build_signs() -> void:
	# Shatterpoint: root and open fifth on bassoon, cello and an anvil-chime.
	_sign(&"SIGN_IRON_ROOT", &"BASSOON_CELLO_ANVIL_CHIME", [0, 7, 12], 0.035, -1)
	# Glacial Rupture: a crystalline Lydian burst on dulcimer and glass-chime.
	_sign(&"SIGN_RIME_GALE", &"DULCIMER_GLASS_CHIME", [0, 4, 6, 7, 12], 0.035, 0)
	# Dawnburst: a warm major ninth on accordion and harp.
	_sign(&"SIGN_WARM_HEARTH", &"ACCORDION_HARP_SWELL", [0, 4, 7, 11, 14], 0.05, 0)
	# Astral Chorus: a rising Dorian major-IV cadence on mandolin, oboe and tubular chime.
	_sign(&"SIGN_STAR_TIDE", &"MANDOLIN_OBOE_TUBULAR_CHIME", [0, 5, 9, 12], 0.06, 0)


static func _sign(id: StringName, timbre: StringName, intervals: Array[int], step: float, octave: int) -> void:
	var made: SignHarmonicProfileResource = SignHarmonicProfileResource.new()
	made.sign_id = id
	made.instrument_timbre = timbre
	made.chord_semitone_intervals = PackedInt32Array(intervals)
	made.arpeggio_step_sec = step
	made.octave_shift = octave
	register(made)


# --- The 3x3 Callings (16 §3.2) ----------------------------------------------

static func _build_callings() -> void:
	# The Shield-Sworn: low bronze bell and cello pizzicato, 80-350 Hz.
	_calling(&"bridge_warden", "Bridge-Warden", &"SHIELD_SWORN", &"BRONZE_BELL_CELLO_PIZZ", 5, [0, 7, 12], Vector2(80.0, 350.0), -1)
	_calling(&"weald_captain", "Weald-Captain", &"SHIELD_SWORN", &"BRONZE_BELL_CELLO_PIZZ", 5, [0, 7, 14], Vector2(80.0, 350.0), -1)
	_calling(&"hearth_guard", "Hearth-Guard", &"SHIELD_SWORN", &"BRONZE_BELL_CELLO_PIZZ", 5, [0, 4, 7], Vector2(80.0, 350.0), -1)
	# The Wayfarers: mandolin double-stops, guitar strum and whistle, 350-2,000 Hz.
	_calling(&"iron_woodsman", "Iron-Woodsman", &"WAYFARERS", &"MANDOLIN_GUITAR_WHISTLE", 6, [0, 5, 7], Vector2(350.0, 2000.0), 0)
	_calling(&"hedge_runner", "Hedge-Runner", &"WAYFARERS", &"MANDOLIN_GUITAR_WHISTLE", 6, [0, 2, 4, 7], Vector2(350.0, 2000.0), 0)
	_calling(&"sign_seeker", "Sign-Seeker", &"WAYFARERS", &"MANDOLIN_GUITAR_WHISTLE", 6, [0, 4, 6, 7], Vector2(350.0, 2000.0), 0)
	# The Lantern-Bearers: carillon Chimes, oboe swell and harp glissando, 1.5-5 kHz.
	_calling(&"bell_keeper", "Bell-Keeper", &"LANTERN_BEARERS", &"CARILLON_OBOE_HARP", 7, [0, 7, 12, 16], Vector2(1500.0, 5000.0), 1)
	_calling(&"wind_mender", "Wind-Mender", &"LANTERN_BEARERS", &"CARILLON_OBOE_HARP", 7, [0, 4, 9, 12], Vector2(1500.0, 5000.0), 1)
	_calling(&"lantern_scribe", "Lantern-Scribe", &"LANTERN_BEARERS", &"CARILLON_OBOE_HARP", 7, [0, 4, 7, 11], Vector2(1500.0, 5000.0), 1)


static func _calling(id: StringName, label: String, family: StringName, instrument: StringName, stem: int, motif: Array[int],
		band: Vector2, octave: int) -> void:
	var made: CallingAudioProfileResource = CallingAudioProfileResource.new()
	made.calling_id = id
	made.display_name = label
	made.trinity_family = family
	made.lead_instrument = instrument
	made.character_select_stem_index = stem
	made.posture_motif_intervals = PackedInt32Array(motif)
	made.frequency_band_hz = band
	made.octave_shift = octave
	register(made)


# --- Bosses (16 §4.5, §5.3) --------------------------------------------------

static func _build_bosses() -> void:
	var cairnsman: BossAudioProfileResource = BossAudioProfileResource.new()
	cairnsman.boss_id = ArsenalCatalog.CAIRNSMAN
	cairnsman.display_title = "The Cairnsman's Vigil"
	cairnsman.suite_profile_id = &"cairnsmans_vigil"
	cairnsman.stagger_stinger_path = ProceduralChamberSynth.SAMPLES_FOLDER + "stinger_poise_stagger_lydian.ogg"
	register(cairnsman)
