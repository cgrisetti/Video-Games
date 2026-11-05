## The code-first chamber ensemble: Tier 2 of 16_ADAPTIVE_AUDIO_ARCHITECTURE.md (§1.1, §4.2).
## It plays a zone when its baked acoustic stems are missing (tools/build_audio_stems.py bakes
## them), and it builds the short phrases the score makes at run time (a Calling's motif over the
## zone's tonic). No voice is a bare oscillator: every note is an excitation driving a resonator.
##   PLUCK, HARP, MANDOLIN,   Karplus-Strong waveguides: a pink-filtered pick burst circulating a
##   DULCIMER, PIZZ           fractional delay line through a one-pole bridge filter. MANDOLIN and
##                            DULCIMER ring two courses a hair apart; PIZZ adds a 180 Hz body thump.
##   REED (bassoon), OBOE     a double reed's 12 harmonics (1/k^1.15) through the bore's three formant
##                            resonators (bassoon 440, 1150, 2500 Hz; oboe 750, 1400, 2900 Hz), a
##                            45 ms breath attack, breath noise and 5.5 Hz vibrato after 180 ms
##   ACCORDION                three musette reeds (0, +14 and -12 cents) in a bellows swell, low-passed at 2.8 kHz
##   VIOLIN                   a Helmholtz bowed string through the body's bridge resonances (290, 520
##                            and 2400 Hz; a cello's 180 Hz below G3), bow noise and vibrato
##   WHISTLE                  a flue: breath noise ringing a resonator at the pipe's pitch over its few harmonics
##   BELL                     struck modal resonators on a carillon's partials
##   DRUM                     a bodhran: a felt beater striking a membrane's modes, and a skin slap
## The reed, bowed and flue resonators are applied to their harmonic series in the frequency
## domain (each harmonic weighted by the resonator bank's response at its frequency), which is exact
## for a held tone and costs one table read a sample. A zone's stems come from its baked score
## (assets/audio/music/<id>/score.json) when there is one, so the fallback plays the same tune as
## the acoustic stems; otherwise from the profile's progression as a buoyant waltz, sway or march.
## Phrases play the baked acoustic samples (assets/audio/samples/sample_*.wav), re-pitched, when
## they are there. Every render is seeded by the profile id, so a zone always sounds the same, and
## works from a plain snapshot of the profile, so AudioDirector can render on a worker thread.
class_name ProceduralChamberSynth
extends RefCounted

enum Timbre { PLUCK, HARP, DULCIMER, REED, WHISTLE, ACCORDION, VIOLIN, BELL, DRUM, OBOE, PIZZ, MANDOLIN }

const MIX_RATE: int = 22050
## Stems and stingers are scaled so their loudest sample sits here.
const PEAK: float = 0.6
const TABLE_SIZE: int = 512
const TIMBRE_NAMES: Dictionary[StringName, Timbre] = {&"PLUCK": Timbre.PLUCK, &"HARP": Timbre.HARP, &"DULCIMER": Timbre.DULCIMER,
	&"REED": Timbre.REED, &"WHISTLE": Timbre.WHISTLE, &"ACCORDION": Timbre.ACCORDION, &"VIOLIN": Timbre.VIOLIN, &"BELL": Timbre.BELL,
	&"DRUM": Timbre.DRUM, &"OBOE": Timbre.OBOE, &"PIZZ": Timbre.PIZZ, &"MANDOLIN": Timbre.MANDOLIN}
## The station ambience loops by kind, and their lengths in seconds.
const AMBIENCE_LENGTHS: Dictionary[StringName, float] = {&"hearth_fire": 4.0, &"water_trickle": 4.0, &"carillon": 8.0,
	&"gate_drone": 8.0, &"gate_counter": 8.0}
const SCORE_FILE: String = "res://assets/audio/music/%s/score.json"
const SAMPLES_FOLDER: String = "res://assets/audio/samples/"
## The baked acoustic sample behind each voice, and the MIDI note it was recorded at (0: unpitched).
const SAMPLE_VOICES: Dictionary[Timbre, Array] = {Timbre.PLUCK: ["sample_guitar_pluck_g3.wav", 55],
	Timbre.HARP: ["sample_harp_pluck_g4.wav", 67], Timbre.DULCIMER: ["sample_dulcimer_g4.wav", 67],
	Timbre.REED: ["sample_bassoon_legato_d3.wav", 50], Timbre.WHISTLE: ["sample_whistle_g5.wav", 79],
	Timbre.ACCORDION: ["sample_accordion_g4.wav", 67], Timbre.VIOLIN: ["sample_violin_swell_g4.wav", 67],
	Timbre.BELL: ["sample_carillon_chime_g5.wav", 79], Timbre.DRUM: ["sample_bodhran_hit.wav", 0],
	Timbre.OBOE: ["sample_oboe_legato_g4.wav", 67], Timbre.PIZZ: ["sample_pizz_cello_g2.wav", 43],
	Timbre.MANDOLIN: ["sample_mandolin_pluck_g4.wav", 67]}
## Karplus-Strong strings: [ring (T60, s) at A3, bridge damping d, pick brightness, courses, release (s)].
const STRINGS: Dictionary[Timbre, Array] = {Timbre.PLUCK: [2.4, 0.35, 0.5, 1, 0.3], Timbre.HARP: [3.4, 0.35, 0.42, 1, 0.9],
	Timbre.MANDOLIN: [1.3, 0.2, 0.75, 2, 0.15], Timbre.DULCIMER: [2.8, 0.12, 0.85, 2, 0.5], Timbre.PIZZ: [0.5, 0.55, 0.35, 1, 0.12]}
## Formant resonators: (centre Hz, Q).
const BASSOON_FORMANTS: Array[Vector2] = [Vector2(440.0, 4.5), Vector2(1150.0, 5.0), Vector2(2500.0, 4.0)]
const OBOE_FORMANTS: Array[Vector2] = [Vector2(750.0, 5.0), Vector2(1400.0, 5.5), Vector2(2900.0, 4.5)]
const VIOLIN_BODY: Array[Vector2] = [Vector2(290.0, 3.0), Vector2(520.0, 3.5), Vector2(2400.0, 2.5)]
const CELLO_BODY: Array[Vector2] = [Vector2(180.0, 3.0), Vector2(400.0, 3.0), Vector2(1800.0, 2.5)]
const MUSETTE_CENTS: Array[float] = [0.0, 14.0, -12.0]
const REED_PARTIALS: Array[float] = [1.0, 0.65, 0.45, 0.25, 0.15, 0.08]
const FLUE_PARTIALS: Array[float] = [1.0, 0.18, 0.08, 0.03]
## Where the bow meets the string (a share of its length): every 1/β-th harmonic goes missing.
const BOW_POSITION: float = 0.13
const VIBRATO_HZ: float = 5.5
## A carillon bell's modes: (ratio to the strike note, weight, T60 s): hum, prime, minor third, fifth, nominal, upper partials.
const BELL_MODES: Array[Vector3] = [Vector3(0.5, 0.5, 4.0), Vector3(1.0, 0.8, 2.6), Vector3(1.2, 0.55, 2.0), Vector3(1.5, 0.3, 1.6),
	Vector3(2.0, 0.7, 1.4), Vector3(2.52, 0.22, 0.9), Vector3(2.67, 0.18, 0.8), Vector3(3.36, 0.1, 0.5)]
## A frame drum's membrane modes: (ratio, weight, T60 s).
const DRUM_MODES: Array[Vector3] = [Vector3(1.0, 1.0, 0.34), Vector3(1.59, 0.5, 0.2), Vector3(2.14, 0.38, 0.15), Vector3(2.3, 0.28, 0.12),
	Vector3(2.65, 0.18, 0.1), Vector3(2.92, 0.14, 0.08)]
## The bodhran's voices by GM drum key: the low and high "boom", the tips, the rim, the kick.
const DRUM_PITCH: Dictionary[int, float] = {35: 55.0, 41: 72.0, 43: 88.0, 45: 112.0, 47: 132.0, 37: 240.0}
const TAMBOURINE_KEY: int = 54
const TAMBOURINE_MODES: Array[Vector3] = [Vector3(1.0, 0.4, 0.18), Vector3(1.31, 0.3, 0.15), Vector3(1.62, 0.25, 0.12)]
## A cello's body thump under a pizzicato, and a campfire pop's little resonance.
const PIZZ_BODY: Array[Vector3] = [Vector3(1.0, 1.0, 0.12)]
const POP_MODE: Array[Vector3] = [Vector3(1.0, 1.0, 0.05)]
const ONE_REED: Array[float] = [1.0]
const NO_RESONATORS: Array[Vector2] = []

## Decoded acoustic samples by voice (main thread only: phrases are built there).
static var _samples: Dictionary[Timbre, PackedFloat32Array] = {}
static var _sample_rates: Dictionary[Timbre, float] = {}


static func midi_hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## A zone's baked arrangement, if tools/build_audio_stems.py wrote one: {"stems": [[start_beat,
## beats, midi, velocity, voice], ...] x4, ...}. Empty when there is none.
static func load_score(profile_id: StringName) -> Dictionary:
	var path: String = SCORE_FILE % profile_id
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


## What render_stems() needs from a profile, as plain values (safe to hand to a worker thread).
static func snapshot(profile: ZoneMusicProfileResource) -> Dictionary:
	return {"id": String(profile.profile_id), "root": profile.root_pitch_midi, "bpm": profile.bpm, "beats": profile.beats_per_bar,
		"compound": profile.compound_meter, "lead": profile.lead_scale.duplicate(), "discord": profile.discord_scale.duplicate(),
		"progression": profile.progression.duplicate(), "skips": profile.melody_skips_degrees.duplicate(), "bars": profile.loop_bars(),
		"lead_timbre": TIMBRE_NAMES.get(profile.lead_timbre, Timbre.ACCORDION), "score": load_score(profile.profile_id)}


## The four stems of a zone as 16-bit PCM, one loop each, all the same length.
static func render_stems(snap: Dictionary) -> Array[PackedByteArray]:
	var stems: Array[PackedByteArray] = []
	for layer: int in ZoneMusicProfileResource.STEM_COUNT:
		stems.append(_to_pcm(_render_stem(snap, layer)))
	return stems


## A looping 16-bit stream from PCM bytes.
static func loop_stream(pcm: PackedByteArray) -> AudioStreamWAV:
	var wav: AudioStreamWAV = _stream(pcm)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = pcm.size() / 2
	return wav


## A one-shot phrase: each event is [start_sec, midi, length_sec, Timbre, gain]. A voice with a
## baked acoustic sample plays it, re-pitched (unless `use_samples` is false); the rest are modelled.
static func render_phrase(events: Array[Array], use_samples: bool = true) -> AudioStreamWAV:
	var total: float = 0.0
	for event: Array in events:
		total = maxf(total, float(event[0]) + float(event[2]) + 0.9)
	var mix: Mix = Mix.new(int(total * MIX_RATE) + 1, false, 7)
	for event: Array in events:
		var timbre: Timbre = int(event[3]) as Timbre
		var sample: PackedFloat32Array = acoustic_sample(timbre) if use_samples else PackedFloat32Array()
		if sample.is_empty():
			mix.note(float(event[0]), float(event[2]), float(event[1]), timbre, float(event[4]))
		else:
			mix.sampled(float(event[0]), float(event[1]), float(event[2]), sample, int(SAMPLE_VOICES[timbre][1]), _sample_rates[timbre],
				float(event[4]))
	return _stream(_to_pcm(mix.buf))


## An arpeggiated chord: `notes` in MIDI, one every `step` seconds, each ringing `ring` seconds.
static func render_chord(notes: PackedInt32Array, step: float, ring: float, timbre: Timbre, gain: float, use_samples: bool = true) -> AudioStreamWAV:
	var events: Array[Array] = []
	for index: int in notes.size():
		events.append([step * index, notes[index], ring, timbre, gain])
	return render_phrase(events, use_samples)


## A voice's baked acoustic sample as mono floats (empty if it isn't there, or isn't plain PCM).
static func acoustic_sample(timbre: Timbre) -> PackedFloat32Array:
	if _samples.has(timbre):
		return _samples[timbre]
	var decoded: PackedFloat32Array = PackedFloat32Array()
	var path: String = SAMPLES_FOLDER + String(SAMPLE_VOICES[timbre][0]) if SAMPLE_VOICES.has(timbre) else ""
	var wav: AudioStreamWAV = load(path) as AudioStreamWAV if path != "" and ResourceLoader.exists(path) else null
	if wav != null and wav.format == AudioStreamWAV.FORMAT_16_BITS:
		var channels: int = 2 if wav.stereo else 1
		var frames: int = wav.data.size() / (2 * channels)
		decoded.resize(frames)
		for frame: int in frames:
			var value: float = 0.0
			for channel: int in channels:
				value += wav.data.decode_s16((frame * channels + channel) * 2) / 32768.0
			decoded[frame] = value / channels
		_sample_rates[timbre] = float(wav.mix_rate)
	_samples[timbre] = decoded
	return decoded


## A station's ambience loop (AMBIENCE_LENGTHS): the campfire's crackle and a water-shrine's
## trickle are noise and resonators; the Chime-Shrine's carillon and the Co-Op Gate's two plate
## harmonies are played by the chamber voices (AudioDirector prefers their baked recordings).
static func render_ambience(kind: StringName) -> AudioStreamWAV:
	var length: float = AMBIENCE_LENGTHS.get(kind, 4.0)
	var mix: Mix = Mix.new(int(length * MIX_RATE), true, hash(kind))
	var rng: RandomNumberGenerator = mix.rng
	match kind:
		&"hearth_fire":
			mix.noise_bed(0.08, 0.3)
			for pop: int in 26:
				mix.pop(rng.randf() * length, rng.randf_range(300.0, 1100.0), rng.randf_range(0.15, 0.6))
		&"water_trickle":
			mix.noise_bed(0.35, 0.45)
			for bubble: int in 18:
				mix.bubble(rng.randf() * length, rng.randf_range(500.0, 1400.0), rng.randf_range(0.2, 0.5))
		&"carillon":
			# The Chime-Shrine's pentatonic bronze: G A B D E.
			var pentatonic: Array[int] = [79, 81, 83, 86, 88, 91]
			for strike: int in 7:
				mix.note(strike * length / 7.0 + rng.randf() * 0.3, 2.4, pentatonic[rng.randi() % pentatonic.size()], Timbre.BELL, 0.5)
		&"gate_drone":
			# Plate one: an accordion open fifth, A2 and E3, breathing in overlapping bellows swells, and a bowed cello A2.
			for at: float in [0.0, length * 0.5]:
				mix.note(at, length * 0.5 + 0.4, 45.0, Timbre.ACCORDION, 0.45)
				mix.note(at, length * 0.5 + 0.4, 52.0, Timbre.ACCORDION, 0.35)
				mix.note(at + length * 0.25, length * 0.5 + 0.4, 45.0, Timbre.VIOLIN, 0.3)
		&"gate_counter":
			# Plate two: an oboe and mandolin harmony, C#4 F#4 B4 over the drone.
			var line: Array[int] = [61, 66, 71, 66]
			var step: float = length / line.size()
			for index: int in line.size():
				mix.note(index * step, step * 1.05, line[index], Timbre.OBOE, 0.45)
				for pluck: int in 4:
					mix.note(index * step + pluck * step / 4.0, 0.3, line[index] + 12, Timbre.MANDOLIN, 0.25 - pluck * 0.03)
	return loop_stream(_to_pcm(mix.buf))


# --- The stems (16 §3) ---------------------------------------------------------------

static func _render_stem(snap: Dictionary, layer: int) -> PackedFloat32Array:
	var beat: float = 60.0 / maxf(float(snap["bpm"]), 1.0)
	var bars: int = maxi(1, int(snap["bars"]))
	var mix: Mix = Mix.new(int(roundf(bar_beats(snap) * bars * beat * MIX_RATE)), true, hash(String(snap["id"]) + str(layer)))
	var score: Dictionary = snap["score"]
	var stems: Array = score.get("stems", [])
	if stems.size() == ZoneMusicProfileResource.STEM_COUNT:
		for item: Variant in stems[layer]:
			var note: Array = item as Array
			var velocity: float = float(note[3]) / 127.0
			mix.note(float(note[0]) * beat, float(note[1]) * beat, float(note[2]), TIMBRE_NAMES.get(StringName(str(note[4])), Timbre.HARP),
				pow(velocity, 1.6) * 0.9)
	else:
		_compose(mix, snap, layer, beat)
	return mix.buf


static func bar_beats(snap: Dictionary) -> int:
	return maxi(1, int(snap["beats"]))


## The profile's progression as chamber patterns (16 §2.1): an oom-pah-pah waltz, a rolling 6/8
## sway or a march under a sunny tune that breathes every four bars, a staccato bassoon answering
## in the breaths and a harp glissando every eight; a quirky reed invention for the Holloway stem;
## bodhran, dulcimer, mandolin and bassoon for the skirmish.
static func _compose(mix: Mix, snap: Dictionary, layer: int, beat: float) -> void:
	var beats: int = bar_beats(snap)
	var compound: bool = bool(snap["compound"])
	var root: int = int(snap["root"])
	var scale: PackedInt32Array = snap["lead"]
	var progression: PackedInt32Array = snap["progression"]
	var skips: PackedInt32Array = snap["skips"]
	var lead: Timbre = int(snap["lead_timbre"]) as Timbre
	var rng: RandomNumberGenerator = mix.rng
	var eighth: float = beat * 0.5
	var bar: float = beat * beats
	var pitch: float = float(root + 12)
	for b: int in int(snap["bars"]):
		var at: float = b * bar
		var degree: int = progression[b % maxi(1, progression.size())] if not progression.is_empty() else 0
		var bass: float = _degree(root - 24, scale, degree)
		var tones: Array[float] = [_degree(root, scale, degree), _degree(root, scale, degree + 2), _degree(root, scale, degree + 4),
			_degree(root, scale, degree + 7)]
		match layer:
			ZoneMusicProfileResource.StemLayer.FOLK_BASE:
				if compound:
					var roll: Array[float] = [bass + 12.0, tones[2] - 12.0, tones[1], tones[0] + 2.0, tones[0], tones[2] - 12.0]
					for step: int in 6:
						mix.note(at + step * eighth, eighth * 1.8, roll[step], Timbre.PLUCK, 0.55 if step % 3 == 0 else 0.4)
					mix.note(at, eighth, bass, Timbre.PIZZ, 0.8)
					mix.note(at + 3.0 * eighth, eighth, bass + 7.0, Timbre.PIZZ, 0.6)
				elif beats == 4:
					mix.note(at, beat * 0.45, bass, Timbre.PIZZ, 0.85)
					mix.note(at + 2.0 * beat, beat * 0.45, bass + 7.0, Timbre.PIZZ, 0.7)
					for step: int in 8:
						mix.note(at + step * eighth, eighth, tones[0] - 12.0 + (7.0 if step % 2 == 1 else 0.0), Timbre.DULCIMER, 0.4)
					for chop: int in [1, 3]:
						for tone: int in 3:
							mix.note(at + chop * beat + tone * 0.012, beat * 0.3, tones[tone], Timbre.MANDOLIN, 0.3)
				else:
					# Oom: a crisp pizzicato root with a staccato bassoon. Pah-pah: mandolin and guitar chords.
					mix.note(at, beat * 0.45, bass, Timbre.PIZZ, 0.9)
					mix.note(at, beat * 0.4, bass + 12.0, Timbre.REED, 0.3)
					for pah: int in [1, 2]:
						for tone: int in 3:
							mix.note(at + pah * beat + tone * 0.012, beat * 0.3, tones[tone + 1] if tone < 2 else tones[0] + 12.0, Timbre.MANDOLIN,
								0.32 if pah == 1 else 0.26)
							mix.note(at + pah * beat, beat * 0.4, tones[tone] - 12.0, Timbre.PLUCK, 0.22)
				if b % 4 == 3:
					for step: int in 8:
						mix.note(at + beat + step * beat * 0.25, beat, tones[step % 3] + 12.0 * floorf(step / 3.0), Timbre.HARP, 0.3)
			ZoneMusicProfileResource.StemLayer.PASTORAL_LEAD:
				if b % 4 == 3:
					# The breath: a held chord tone, then the bassoon answers with staccato leaps.
					pitch = _nearest(tones, pitch)
					mix.note(at, (beats - 1) * beat * 0.95, pitch, lead, 0.55)
					for leap: int in 2:
						mix.note(at + (beats - 1) * beat + leap * eighth, eighth * 0.45, bass + 12.0 + (7.0 if leap == 1 else 0.0), Timbre.REED, 0.5)
					if b % 8 == 7:
						for step: int in 14:
							mix.note(at + (beats - 1) * beat + step * beat / 14.0, beat * 2.0, _degree(root - 12, scale, step), Timbre.HARP, 0.22)
					continue
				var cells: Array = [[1.5, 0.5, 1.0], [2.0, 1.0], [1.0, 1.0, 1.0]] if beats == 3 else [[1.5, 0.5, 1.0, 1.0], [2.0, 1.0, 1.0], [1.0, 1.0, 2.0]]
				if compound:
					cells = [[1.0, 0.5, 1.0, 0.5], [1.5, 0.5, 0.5, 0.5], [0.5, 0.5, 0.5, 1.5]]
				var cell: Array = cells[rng.randi() % cells.size()]
				var offset: float = 0.0
				for index: int in cell.size():
					if index == 0:
						pitch = _nearest(tones, pitch + rng.randf_range(-3.0, 5.0))
					else:
						var step_degree: int = _degree_of(root, scale, pitch) + (1 if rng.randf() < 0.55 else -1)
						while skips.has(posmod(step_degree, scale.size())):
							step_degree += 1
						pitch = _degree(root, scale, step_degree)
					pitch = clampf(pitch, float(root), float(root + 21))
					if index == 0 and lead == Timbre.WHISTLE:
						mix.note(at - beat * 0.125, beat * 0.11, pitch + 2.0, lead, 0.35)
					mix.note(at + offset * beat, float(cell[index]) * beat * 0.95, pitch, lead, 0.55)
					offset += float(cell[index])
			ZoneMusicProfileResource.StemLayer.HOLLOWAY_DISCORD:
				# A quirky two-part invention: the motif (with its chromatic lower neighbour) passes
				# between oboe and bassoon every bar, over a soft accordion bellows swell.
				var voice: Timbre = Timbre.OBOE if b % 2 == 0 else Timbre.REED
				var base: float = tones[0] if b % 2 == 0 else tones[0] - 12.0
				var motif: Array[float] = [base, base - 1.0, base, base + tones[1] - tones[0], base + tones[2] - tones[0],
					base + tones[1] - tones[0], base]
				var rhythm: Array[float] = [0.5, 0.25, 0.25, 0.5, 0.5, 0.5, 0.5]
				var offset: float = 0.0
				for index: int in motif.size():
					if offset >= beats:
						break
					mix.note(at + offset * beat, rhythm[index] * beat * 0.8, motif[index], voice, 0.45)
					offset += rhythm[index]
				for tone: int in 3:
					mix.note(at, bar * 0.85, tones[tone] - 12.0, Timbre.ACCORDION, 0.14)
			ZoneMusicProfileResource.StemLayer.SKIRMISH_DRIVE:
				var group: int = 3 if compound else 2
				for step: int in beats * 2:
					var accent: bool = step % group == 0
					mix.note(at + step * eighth, 0.2, 41.0 if step == 0 else (43.0 if accent else 45.0), Timbre.DRUM, 0.9 if accent else 0.45)
				var shape: Array[int] = [0, 1, 2, 3, 2, 1]
				for step: int in beats * 4:
					mix.note(at + step * eighth * 0.5, eighth, tones[shape[step % shape.size()]] - 12.0, Timbre.DULCIMER, 0.3)
				mix.note(at, eighth * 0.45, bass + 12.0, Timbre.REED, 0.55)


## The MIDI note of a scale degree (degrees past 6 climb an octave).
static func _degree(base: int, scale: PackedInt32Array, degree: int) -> float:
	var size: int = maxi(1, scale.size())
	return float(base + scale[posmod(degree, size)] + 12 * floori(float(degree) / size))


## The scale degree nearest a pitch (the inverse of _degree).
static func _degree_of(base: int, scale: PackedInt32Array, pitch: float) -> int:
	var best: int = 0
	for degree: int in range(-14, 22):
		if absf(_degree(base, scale, degree) - pitch) < absf(_degree(base, scale, best) - pitch):
			best = degree
	return best


## The chord tone (in any octave) nearest a pitch.
static func _nearest(tones: Array[float], pitch: float) -> float:
	var best: float = tones[0]
	for tone: float in tones:
		for octave: int in range(-2, 3):
			var candidate: float = tone + 12.0 * octave
			if absf(candidate - pitch) < absf(best - pitch):
				best = candidate
	return best


# --- The mix and its voices ------------------------------------------------------------

## A buffer the voices add into (wrapping round the end when it loops, so loops are seamless),
## with its own random numbers and harmonic tables.
class Mix:
	var buf: PackedFloat32Array = PackedFloat32Array()
	var size: int = 0
	var wrap: bool = false
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var _tables: Dictionary[String, PackedFloat32Array] = {}

	func _init(frames: int, looping: bool, seed_value: int) -> void:
		size = maxi(1, frames)
		buf.resize(size)
		wrap = looping
		rng.seed = seed_value

	## One note of a voice, `start` and `length` in seconds.
	func note(start: float, length: float, midi: float, timbre: Timbre, gain: float) -> void:
		var first: int = int(roundf(start * ProceduralChamberSynth.MIX_RATE))
		if wrap:
			first = posmod(first, size)
		elif first >= size:
			return
		first = maxi(first, 0)
		var hz: float = ProceduralChamberSynth.midi_hz(midi)
		match timbre:
			Timbre.PLUCK, Timbre.HARP, Timbre.MANDOLIN, Timbre.DULCIMER, Timbre.PIZZ:
				_string(first, length, hz, timbre, gain)
			Timbre.REED:
				_tone(first, length, hz, gain, _reed_table(hz, ProceduralChamberSynth.BASSOON_FORMANTS), ProceduralChamberSynth.ONE_REED, 0.045, 0.06, 0.0035, 0.18, 0.05)
			Timbre.OBOE:
				_tone(first, length, hz, gain, _reed_table(hz, ProceduralChamberSynth.OBOE_FORMANTS), ProceduralChamberSynth.ONE_REED, 0.04, 0.06, 0.0035, 0.18, 0.04)
			Timbre.ACCORDION:
				var reeds: Array[float] = []
				for cents: float in ProceduralChamberSynth.MUSETTE_CENTS:
					reeds.append(pow(2.0, cents / 1200.0))
				_tone(first, length, hz, gain * 0.6, _table("accordion:%.2f" % hz, hz, ProceduralChamberSynth.REED_PARTIALS, ProceduralChamberSynth.NO_RESONATORS, 2800.0), reeds,
					0.06, 0.08, 0.0, 0.0, 0.01)
			Timbre.VIOLIN:
				var body: Array[Vector2] = ProceduralChamberSynth.CELLO_BODY if hz < 196.0 else ProceduralChamberSynth.VIOLIN_BODY
				var weights: Array[float] = []
				for k: int in range(1, 21):
					weights.append(absf(sin(PI * k * ProceduralChamberSynth.BOW_POSITION)) / k)
				_tone(first, length, hz, gain, _table("bow:%.2f" % hz, hz, weights, body, 0.0), ProceduralChamberSynth.ONE_REED, 0.09, 0.1, 0.005, 0.2, 0.03)
			Timbre.WHISTLE:
				_tone(first, length, hz, gain, _table("flue:%.2f" % hz, hz, ProceduralChamberSynth.FLUE_PARTIALS, ProceduralChamberSynth.NO_RESONATORS, 0.0), ProceduralChamberSynth.ONE_REED,
					0.03, 0.05, 0.0025, 0.25, 0.0)
				_breath(first, length, hz, gain * 0.35)
			Timbre.BELL:
				_modes(first, maxf(length, 1.2), hz, ProceduralChamberSynth.BELL_MODES, gain * 0.6, 1.0)
			Timbre.DRUM:
				_drum(first, int(roundf(midi)), gain)

	## A baked acoustic sample re-pitched from `base` to `midi` (`base` 0: as recorded).
	func sampled(start: float, midi: float, length: float, sample: PackedFloat32Array, base: int, rate: float, gain: float) -> void:
		var first: int = int(roundf(start * ProceduralChamberSynth.MIX_RATE))
		if first >= size:
			return
		var step: float = (pow(2.0, (midi - base) / 12.0) if base > 0 else 1.0) * rate / ProceduralChamberSynth.MIX_RATE
		var count: int = mini(int((sample.size() - 2) / step), int((length + 0.6) * ProceduralChamberSynth.MIX_RATE))
		count = mini(count, size - first)
		var fade: int = mini(int(0.03 * ProceduralChamberSynth.MIX_RATE), count / 2)
		var at: float = 0.0
		for index: int in count:
			var whole: int = int(at)
			var value: float = lerpf(sample[whole], sample[whole + 1], at - whole)
			var envelope: float = 1.0 if index < count - fade else float(count - index) / fade
			buf[first + index] += value * gain * envelope
			at += step

	# Karplus-Strong: a pink-filtered pick burst circulating a delay line of one period through the
	# bridge's two-tap loss filter y = g((1 - d) y[n-L] + d y[n-L-1]) and a first-order all-pass
	# that tunes the fractional part of the period.
	func _string(first: int, length: float, hz: float, timbre: Timbre, gain: float) -> void:
		var spec: Array = ProceduralChamberSynth.STRINGS[timbre]
		var ring: float = float(spec[0]) * sqrt(clampf(220.0 / hz, 0.3, 3.0))
		var damping: float = float(spec[1])
		var bright: float = float(spec[2])
		var courses: int = int(spec[3])
		var release: float = float(spec[4])
		var rate: float = float(ProceduralChamberSynth.MIX_RATE)
		var total: int = int((maxf(length, 0.05) + release) * rate)
		if not wrap:
			total = mini(total, size - first)
		total = mini(total, size)
		var held: int = int(maxf(length, 0.05) * rate)
		for course: int in courses:
			var tuned: float = hz * (1.0 + 0.0012 * course)
			var period: float = rate / tuned
			var whole: int = maxi(2, int(period - damping - 0.1))
			var fraction: float = clampf(period - damping - whole, 0.05, 1.5)
			var allpass: float = (1.0 - fraction) / (1.0 + fraction)
			var loss: float = pow(10.0, -3.0 / (ring * tuned))
			var line: PackedFloat32Array = PackedFloat32Array()
			line.resize(whole)
			var smooth: float = 0.0
			var mean: float = 0.0
			for index: int in whole:
				smooth += (rng.randf_range(-1.0, 1.0) - smooth) * bright
				line[index] = smooth
				mean += smooth
			mean /= whole
			for index: int in whole:
				line[index] -= mean
			var last: float = 0.0
			var ap_in: float = 0.0
			var ap_out: float = 0.0
			var cursor: int = 0
			var at: int = first
			var level: float = gain / courses
			for index: int in total:
				var value: float = line[cursor]
				var damped: float = loss * ((1.0 - damping) * value + damping * last)
				last = value
				var tuned_out: float = allpass * damped + ap_in - allpass * ap_out
				ap_in = damped
				ap_out = tuned_out
				line[cursor] = tuned_out
				cursor += 1
				if cursor == whole:
					cursor = 0
				var envelope: float = 1.0 if index < held else 1.0 - float(index - held) / maxf(1.0, total - held)
				buf[at] += value * level * envelope
				at += 1
				if at == size:
					at = 0
		if timbre == Timbre.PIZZ:
			# The cello body's thump under the pluck.
			_modes(first, 0.2, 180.0, ProceduralChamberSynth.PIZZ_BODY, gain * 0.35, 1.0)

	# A held tone: `table` (one period of the voice's harmonics, already shaped by its resonators)
	# read at each reed's rate, with an attack, a release, delayed vibrato and breath noise.
	func _tone(first: int, length: float, hz: float, gain: float, table: PackedFloat32Array, reeds: Array[float], attack: float,
			release: float, vibrato: float, vibrato_delay: float, breath: float) -> void:
		var rate: float = float(ProceduralChamberSynth.MIX_RATE)
		var count: int = int((maxf(length, 0.04) + release) * rate)
		if not wrap:
			count = mini(count, size - first)
		count = mini(count, size)
		var attack_n: float = maxf(1.0, attack * rate)
		var release_n: float = maxf(1.0, release * rate)
		var delay_n: float = vibrato_delay * rate
		var lfo_cos: float = cos(TAU * ProceduralChamberSynth.VIBRATO_HZ / rate)
		var lfo_sin: float = sin(TAU * ProceduralChamberSynth.VIBRATO_HZ / rate)
		var lfo_x: float = 1.0
		var lfo_y: float = 0.0
		var phases: Array[float] = []
		for reed: float in reeds:
			phases.append(rng.randf())
		var noise: float = 0.0
		var at: int = first
		var size_f: float = float(ProceduralChamberSynth.TABLE_SIZE)
		var level: float = gain / reeds.size()
		for index: int in count:
			var envelope: float = minf(1.0, index / attack_n)
			envelope *= envelope * (3.0 - 2.0 * envelope)
			if index > count - release_n:
				envelope *= maxf(0.0, (count - index) / release_n)
			var next_x: float = lfo_cos * lfo_x - lfo_sin * lfo_y
			lfo_y = lfo_sin * lfo_x + lfo_cos * lfo_y
			lfo_x = next_x
			var depth: float = vibrato * clampf((index - delay_n) / (0.15 * rate), 0.0, 1.0)
			var wobble: float = 1.0 + depth * lfo_y
			var value: float = 0.0
			for reed: int in reeds.size():
				var phase: float = phases[reed] + hz * reeds[reed] * wobble / rate
				phase -= floorf(phase)
				phases[reed] = phase
				var spot: float = phase * size_f
				var whole: int = int(spot)
				value += lerpf(table[whole], table[(whole + 1) % ProceduralChamberSynth.TABLE_SIZE], spot - whole)
			if breath > 0.0:
				noise += (rng.randf_range(-1.0, 1.0) - noise) * 0.35
				value += noise * breath * (1.0 + 2.0 * maxf(0.0, 1.0 - index / attack_n))
			buf[at] += value * level * envelope
			at += 1
			if at == size:
				at = 0

	# The flue's breath: noise ringing a narrow resonator at the pipe's pitch (with a chiff at the start).
	func _breath(first: int, length: float, hz: float, gain: float) -> void:
		var rate: float = float(ProceduralChamberSynth.MIX_RATE)
		var count: int = int((maxf(length, 0.04) + 0.05) * rate)
		if not wrap:
			count = mini(count, size - first)
		count = mini(count, size)
		var radius: float = exp(-PI * (hz / 30.0) / rate)
		var feed: float = 2.0 * radius * cos(TAU * hz / rate)
		var back: float = radius * radius
		var one: float = 0.0
		var two: float = 0.0
		var at: int = first
		for index: int in count:
			var envelope: float = minf(1.0, index / (0.03 * rate)) * minf(1.0, (count - index) / (0.05 * rate))
			var chiff: float = 2.5 * maxf(0.0, 1.0 - index / (0.025 * rate))
			var excite: float = rng.randf_range(-1.0, 1.0) * (1.0 - radius)
			var ringing: float = feed * one - back * two + excite
			two = one
			one = ringing
			buf[at] += (ringing * 4.0 + excite * chiff * 0.5) * gain * envelope
			at += 1
			if at == size:
				at = 0

	# Struck modal resonators (a bell, a drum's membrane): each mode a two-pole resonator rung by one impulse.
	func _modes(first: int, length: float, hz: float, modes: Array[Vector3], gain: float, decay_scale: float) -> void:
		var rate: float = float(ProceduralChamberSynth.MIX_RATE)
		for mode: Vector3 in modes:
			var freq: float = hz * mode.x
			if freq >= rate * 0.45 or freq <= 20.0:
				continue
			var t60: float = mode.z * decay_scale
			var count: int = int(minf(t60, length + 0.3 * t60) * rate)
			if not wrap:
				count = mini(count, size - first)
			count = mini(count, size)
			var radius: float = pow(10.0, -3.0 / (t60 * rate))
			var omega: float = TAU * freq / rate
			var feed: float = 2.0 * radius * cos(omega)
			var back: float = radius * radius
			var one: float = mode.y * gain * sin(omega)
			var two: float = 0.0
			var fade_from: int = int(count * 0.8)
			var at: int = first
			for index: int in count:
				var value: float = one
				var envelope: float = 1.0 if index < fade_from else float(count - index) / maxf(1.0, count - fade_from)
				buf[at] += value * envelope
				var next: float = feed * one - back * two
				two = one
				one = next
				at += 1
				if at == size:
					at = 0

	# A bodhran stroke: the beater rings the membrane's modes at the key's pitch, over a short skin
	# slap. The tambourine's key is a bright jingle instead.
	func _drum(first: int, key: int, gain: float) -> void:
		var rate: float = float(ProceduralChamberSynth.MIX_RATE)
		if key == ProceduralChamberSynth.TAMBOURINE_KEY:
			_modes(first, 0.2, 5200.0, ProceduralChamberSynth.TAMBOURINE_MODES, gain * 0.3, 1.0)
			_slap(first, 0.08, 0.9, gain * 0.25)
			return
		var hz: float = ProceduralChamberSynth.DRUM_PITCH.get(key, 100.0)
		_modes(first, 0.4, hz, ProceduralChamberSynth.DRUM_MODES, gain * 0.9, 1.0 if key != 37 else 0.4)
		_slap(first, 0.014, 0.25 if key != 37 else 0.6, gain * 0.5)

	func _slap(first: int, length: float, bright: float, gain: float) -> void:
		var count: int = int(length * ProceduralChamberSynth.MIX_RATE)
		if not wrap:
			count = mini(count, size - first)
		count = mini(count, size)
		var smooth: float = 0.0
		var at: int = first
		for index: int in count:
			smooth += (rng.randf_range(-1.0, 1.0) - smooth) * bright
			buf[at] += smooth * gain * (1.0 - float(index) / count)
			at += 1
			if at == size:
				at = 0

	# A campfire pop: a short noise burst ringing a small resonance.
	func pop(start: float, hz: float, gain: float) -> void:
		var first: int = posmod(int(start * ProceduralChamberSynth.MIX_RATE), size)
		_slap(first, 0.012, 0.6, gain)
		_modes(first, 0.06, hz, ProceduralChamberSynth.POP_MODE, gain * 0.5, 1.0)

	# A water bubble: a resonance whose pitch rises as it closes (Minnaert), struck once.
	func bubble(start: float, hz: float, gain: float) -> void:
		var rate: float = float(ProceduralChamberSynth.MIX_RATE)
		var count: int = int(0.06 * rate)
		var radius: float = pow(10.0, -3.0 / (0.05 * rate))
		var one: float = gain * 0.05
		var two: float = 0.0
		var at: int = posmod(int(start * rate), size)
		for index: int in count:
			var freq: float = hz * (1.0 + 0.6 * index / count)
			var next: float = 2.0 * radius * cos(TAU * freq / rate) * one - radius * radius * two
			two = one
			one = next
			buf[at] += one
			at += 1
			if at == size:
				at = 0

	# Softened noise with a slow swell: fire hiss, or running water.
	func noise_bed(brightness: float, gain: float) -> void:
		var smooth: float = 0.0
		var hush: float = 0.0
		for index: int in size:
			smooth += (rng.randf_range(-1.0, 1.0) - smooth) * brightness
			hush += (smooth - hush) * 0.02
			var swell: float = 0.7 + 0.3 * sin(TAU * 2.0 * index / size)
			buf[index] += (smooth - hush) * swell * gain

	# A reed's harmonics (1/k^1.15) shaped by the bore's formant resonators.
	func _reed_table(hz: float, formants: Array[Vector2]) -> PackedFloat32Array:
		var weights: Array[float] = []
		for k: int in range(1, 13):
			weights.append(1.0 / pow(k, 1.15))
		return _table("reed:%.1f:%.2f" % [formants[0].x, hz], hz, weights, formants, 0.0)

	## One period (TABLE_SIZE samples) of a harmonic series: harmonic k weighted by `weights[k - 1]`,
	## by the parallel resonators' response at k * hz (plus a little direct path), and by a one-pole
	## low-pass at `lowpass_hz` (0: none). Harmonics past 0.45 of the mix rate are left out.
	func _table(key: String, hz: float, weights: Array[float], resonators: Array[Vector2], lowpass_hz: float) -> PackedFloat32Array:
		if _tables.has(key):
			return _tables[key]
		var amplitudes: Array[float] = []
		var phases: Array[float] = []
		for k: int in range(1, weights.size() + 1):
			var freq: float = hz * k
			if freq > ProceduralChamberSynth.MIX_RATE * 0.45:
				break
			var real: float = 1.0 if resonators.is_empty() else 0.3
			var imag: float = 0.0
			for resonator: Vector2 in resonators:
				var detune: float = resonator.y * (freq / resonator.x - resonator.x / freq)
				var denominator: float = 1.0 + detune * detune
				real += 1.0 / denominator
				imag -= detune / denominator
			var amplitude: float = weights[k - 1] * sqrt(real * real + imag * imag)
			if lowpass_hz > 0.0:
				amplitude /= sqrt(1.0 + pow(freq / lowpass_hz, 2.0))
			amplitudes.append(amplitude)
			phases.append(atan2(imag, real))
		var table: PackedFloat32Array = PackedFloat32Array()
		table.resize(ProceduralChamberSynth.TABLE_SIZE)
		var peak: float = 0.0001
		for index: int in ProceduralChamberSynth.TABLE_SIZE:
			var t: float = TAU * index / ProceduralChamberSynth.TABLE_SIZE
			var value: float = 0.0
			for k: int in amplitudes.size():
				value += amplitudes[k] * sin((k + 1) * t + phases[k])
			table[index] = value
			peak = maxf(peak, absf(value))
		for index: int in ProceduralChamberSynth.TABLE_SIZE:
			table[index] /= peak
		_tables[key] = table
		return table


# --- PCM ------------------------------------------------------------------------------

static func _to_pcm(buf: PackedFloat32Array) -> PackedByteArray:
	var peak: float = 0.0001
	for value: float in buf:
		peak = maxf(peak, absf(value))
	var scale: float = PEAK / peak
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(buf.size() * 2)
	for index: int in buf.size():
		pcm.encode_s16(index * 2, int(clampf(buf[index] * scale, -1.0, 1.0) * 32767.0))
	return pcm


static func _stream(pcm: PackedByteArray) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = pcm
	return wav
