## The code-first chamber ensemble (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §1.1, §1.4):
## until curated stems are dropped in, every zone's four phase-locked stems,
## every stinger and every station's ambience are synthesized here into 16-bit
## PCM, so the score plays (and the headless checks run) with no audio files.
##   PLUCK, HARP, DULCIMER   Karplus-Strong strings (guitar, mandolin, Celtic harp, cimbalom)
##   REED                    bassoon and oboe: a narrow pulse, softened, with vibrato
##   WHISTLE                 low whistle and recorder: a breathy sine
##   ACCORDION               two reeds a few cents apart
##   VIOLIN                  a bowed saw with a slow attack and vibrato
##   BELL                    bronze carillon partials (1, 2, 2.76, 5.4)
##   DRUM                    bodhran: a falling thump and a skin slap
## Stems are rendered from a plain snapshot of the profile, so AudioDirector can
## render them on a worker thread. Every render is seeded by the profile id, so
## the same zone always sounds the same.
class_name ProceduralChamberSynth
extends RefCounted

enum Timbre { PLUCK, HARP, DULCIMER, REED, WHISTLE, ACCORDION, VIOLIN, BELL, DRUM }

const MIX_RATE: int = 16000
## Stems and stingers are scaled so their loudest sample sits here.
const PEAK: float = 0.6
const TIMBRE_NAMES: Dictionary[StringName, Timbre] = {&"PLUCK": Timbre.PLUCK, &"HARP": Timbre.HARP, &"DULCIMER": Timbre.DULCIMER,
	&"REED": Timbre.REED, &"WHISTLE": Timbre.WHISTLE, &"ACCORDION": Timbre.ACCORDION, &"VIOLIN": Timbre.VIOLIN, &"BELL": Timbre.BELL,
	&"DRUM": Timbre.DRUM}
## The station ambience loops by kind, and their lengths in seconds.
const AMBIENCE_LENGTHS: Dictionary[StringName, float] = {&"hearth_fire": 4.0, &"water_trickle": 4.0, &"carillon": 8.0,
	&"gate_drone": 4.0, &"gate_counter": 4.0}


static func midi_hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## What render_stems() needs from a profile, as plain values (safe to hand to a worker thread).
static func snapshot(profile: ZoneMusicProfileResource) -> Dictionary:
	return {"id": String(profile.profile_id), "root": profile.root_pitch_midi, "bpm": profile.bpm, "beats": profile.beats_per_bar,
		"compound": profile.compound_meter, "lead": profile.lead_scale.duplicate(), "discord": profile.discord_scale.duplicate(),
		"progression": profile.progression.duplicate(), "skips": profile.melody_skips_degrees.duplicate(),
		"lead_timbre": TIMBRE_NAMES.get(profile.lead_timbre, Timbre.ACCORDION)}


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


## A one-shot phrase: each event is [start_sec, midi, length_sec, Timbre, gain].
static func render_phrase(events: Array[Array]) -> AudioStreamWAV:
	var total: float = 0.0
	for event: Array in events:
		total = maxf(total, float(event[0]) + float(event[2]) + 0.05)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(total * MIX_RATE) + 1)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for event: Array in events:
		_add_note(buf, float(event[0]), float(event[2]), float(event[1]), int(event[3]), float(event[4]), rng, false)
	return _stream(_to_pcm(buf))


## An arpeggiated chord: `notes` in MIDI, one every `step` seconds, each ringing `ring` seconds.
static func render_chord(notes: PackedInt32Array, step: float, ring: float, timbre: Timbre, gain: float) -> AudioStreamWAV:
	var events: Array[Array] = []
	for index: int in notes.size():
		events.append([step * index, notes[index], ring, timbre, gain])
	return render_phrase(events)


## A station's ambience loop (AMBIENCE_LENGTHS): the campfire, a water-shrine, the
## Chime-Shrine's carillon, and the Co-Op Gate's two Maker-Seal Plate harmonies.
static func render_ambience(kind: StringName) -> AudioStreamWAV:
	var length: float = AMBIENCE_LENGTHS.get(kind, 4.0)
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(length * MIX_RATE))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		&"hearth_fire":
			_noise_bed(buf, rng, 0.08, 0.06)
			for pop: int in 26:
				var at: float = rng.randf() * length
				_add_note(buf, at, 0.05, 0.0, Timbre.DRUM, rng.randf_range(0.05, 0.25), rng, true)
		&"water_trickle":
			_noise_bed(buf, rng, 0.3, 0.12)
			for bloop: int in 14:
				_add_note(buf, rng.randf() * length, 0.12, rng.randf_range(84.0, 91.0), Timbre.WHISTLE, 0.12, rng, true)
		&"carillon":
			# The Chime-Shrine's pentatonic bronze harmonics: G A B D E.
			var pentatonic: Array[int] = [79, 81, 83, 86, 88, 91]
			for strike: int in 7:
				_add_note(buf, strike * length / 7.0 + rng.randf() * 0.3, 2.4, pentatonic[rng.randi() % pentatonic.size()], Timbre.BELL, 0.35, rng, true)
		&"gate_drone":
			# Plate one: an accordion and cello open fifth, A2 and E3, held.
			_drone(buf, 45, 0.5)
			_drone(buf, 52, 0.4)
		&"gate_counter":
			# Plate two: an oboe and mandolin A Dorian counter-harmony, E4 F#4 B4.
			var line: Array[int] = [64, 66, 71, 66]
			for index: int in line.size():
				_add_note(buf, index * length / line.size(), length / line.size() * 1.1, line[index], Timbre.REED, 0.4, rng, true)
				_add_note(buf, index * length / line.size(), 0.6, line[index] + 12, Timbre.PLUCK, 0.25, rng, true)
	var wav: AudioStreamWAV = loop_stream(_to_pcm(buf))
	return wav


# --- The stems (16 §5.1) ---------------------------------------------------------

static func _render_stem(snap: Dictionary, layer: int) -> PackedFloat32Array:
	var beat: float = 60.0 / maxf(float(snap["bpm"]), 1.0)
	var beats: int = int(snap["beats"])
	var progression: PackedInt32Array = snap["progression"]
	var bars: int = maxi(1, progression.size())
	var bar: float = beat * beats
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(bar * bars * MIX_RATE))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(String(snap["id"]) + str(layer))
	var root: int = int(snap["root"])
	var lead: PackedInt32Array = snap["lead"]
	var discord: PackedInt32Array = snap["discord"]
	var compound: bool = bool(snap["compound"])
	var eighth: float = beat * 0.5
	match layer:
		ZoneMusicProfileResource.StemLayer.FOLK_BASE:
			# Plucked guitar and harp: a bass root on each main beat and the chord rippling in eighths.
			for b: int in bars:
				var start: float = b * bar
				var chord: int = progression[b]
				var bass: float = _degree(root - 24, lead, chord)
				var pulses: Array = [0.0, beat * 1.5] if compound else ([0.0, beat * 2.0] if beats == 4 else [0.0])
				for pulse: float in pulses:
					_add_note(buf, start + pulse, beat * 1.4, bass, Timbre.PLUCK, 0.8, rng, true)
				var shape: Array = [0, 1, 2, 1, 2, 1] if compound else ([0, 2, 1, 2, 0, 2, 1, 2] if beats == 4 else [-1, -1, 1, 2, 1, 2])
				for step: int in shape.size():
					var tone: int = int(shape[step])
					if tone < 0:
						continue
					_add_note(buf, start + step * eighth, eighth * 2.5, _degree(root - 12, lead, chord + tone * 2), Timbre.HARP, 0.4, rng, true)
		ZoneMusicProfileResource.StemLayer.PASTORAL_LEAD:
			# The sunny tune: a seeded walk on the lead scale, phrases of two bars with a breath after each.
			var skips: PackedInt32Array = snap["skips"]
			var timbre: int = int(snap["lead_timbre"])
			var at: float = 0.0
			var degree: int = 4
			var lengths: Array[float] = [1.0, 0.5, 1.5, 2.0, 1.0]
			while at < bar * bars - beat * 0.5:
				var phrase_end: float = (floorf(at / (bar * 2.0)) + 1.0) * bar * 2.0
				if at > phrase_end - beat * 1.0:
					at = phrase_end
					continue
				var length: float = beat * lengths[rng.randi() % lengths.size()]
				length = minf(length, phrase_end - beat * 0.5 - at)
				degree = clampi(degree + rng.randi_range(-2, 2), 0, 9)
				while skips.has(posmod(degree, 7)):
					degree += 1
				if length > 0.05:
					_add_note(buf, at, length * 0.95, _degree(root, lead, degree), timbre, 0.55, rng, true)
				at += maxf(length, beat * 0.5)
		ZoneMusicProfileResource.StemLayer.HOLLOWAY_DISCORD:
			# An accordion bellows drone in a diminished fifth, under bassoon and oboe trading minor seconds.
			_add_note(buf, 0.0, bar * bars, root - 24, Timbre.ACCORDION, 0.22, rng, true)
			_add_note(buf, 0.0, bar * bars, root - 18, Timbre.ACCORDION, 0.16, rng, true)
			var walk: Array[int] = [0, 6, 0, 5, 4, 6, 2, 0]
			for index: int in bars * beats:
				var pitch: float = _degree(root - 12, discord, walk[index % walk.size()])
				_add_note(buf, index * beat, beat * 0.9, pitch, Timbre.REED, 0.45, rng, true)
				if index % 2 == 1:
					_add_note(buf, index * beat + eighth, beat * 0.8, pitch + 13.0, Timbre.REED, 0.3, rng, true)
		ZoneMusicProfileResource.StemLayer.SKIRMISH_DRIVE:
			# Bodhran on every eighth, accented on the beat groups, under a hammered-dulcimer ostinato.
			var per_bar: int = beats * 2
			for b: int in bars:
				var chord: int = progression[b]
				var tones: Array[float] = [_degree(root - 12, discord, chord), _degree(root - 12, discord, chord + 4), _degree(root, discord, chord),
					_degree(root - 12, discord, chord + 4)]
				for step: int in per_bar:
					var accent: bool = step % (3 if compound else 2) == 0
					_add_note(buf, b * bar + step * eighth, 0.18, 0.0, Timbre.DRUM, 0.9 if accent else 0.45, rng, true)
				for step: int in per_bar * 2:
					_add_note(buf, b * bar + step * eighth * 0.5, eighth, tones[step % tones.size()], Timbre.DULCIMER, 0.3, rng, true)
	return buf


## The MIDI note of a scale degree (degrees past 6 climb an octave).
static func _degree(base: int, scale: PackedInt32Array, degree: int) -> float:
	var size: int = maxi(1, scale.size())
	return float(base + scale[posmod(degree, size)] + 12 * floori(float(degree) / size))


# --- Voices ---------------------------------------------------------------------

## Adds one note into `buf` (wrapping round the end when `wrap`, so loops are seamless).
static func _add_note(buf: PackedFloat32Array, start: float, length: float, midi: float, timbre: int, gain: float,
		rng: RandomNumberGenerator, wrap: bool) -> void:
	var size: int = buf.size()
	if size == 0:
		return
	var first: int = int(start * MIX_RATE)
	var count: int = int(length * MIX_RATE)
	if not wrap:
		count = mini(count, size - first)
	if count <= 0:
		return
	var hz: float = midi_hz(midi)
	match timbre:
		Timbre.PLUCK, Timbre.HARP, Timbre.DULCIMER:
			var period: int = maxi(2, int(MIX_RATE / hz))
			var line: PackedFloat32Array = PackedFloat32Array()
			line.resize(period)
			for index: int in period:
				line[index] = rng.randf_range(-1.0, 1.0)
			var damping: float = 0.4985 if timbre == Timbre.PLUCK else (0.4995 if timbre == Timbre.HARP else 0.4975)
			var cursor: int = 0
			for index: int in count:
				var next: int = cursor + 1 if cursor + 1 < period else 0
				var value: float = line[cursor]
				line[cursor] = (value + line[next]) * damping
				cursor = next
				var at: int = first + index
				if at >= size:
					at %= size
				buf[at] += value * gain
		Timbre.DRUM:
			var phase: float = 0.0
			for index: int in count:
				var t: float = float(index) / MIX_RATE
				var pitch: float = 60.0 + 70.0 * exp(-t * 30.0)
				phase += TAU * pitch / MIX_RATE
				var value: float = sin(phase) * exp(-t * 18.0) + rng.randf_range(-1.0, 1.0) * 0.35 * exp(-t * 60.0)
				var at: int = (first + index) % size
				buf[at] += value * gain
		Timbre.BELL:
			var partials: Array[float] = [1.0, 2.0, 2.76, 5.4]
			var weights: Array[float] = [0.6, 0.3, 0.25, 0.12]
			var decays: Array[float] = [1.6, 2.4, 3.2, 5.0]
			for partial: int in partials.size():
				if hz * partials[partial] >= MIX_RATE * 0.45:
					continue
				var step: float = TAU * hz * partials[partial] / MIX_RATE
				var phase: float = 0.0
				var amp: float = weights[partial] * gain
				var fall: float = exp(-decays[partial] / MIX_RATE)
				for index: int in count:
					var at: int = first + index
					if at >= size:
						at %= size
					buf[at] += sin(phase) * amp
					phase += step
					amp *= fall
		_:
			_add_sustained(buf, first, count, hz, timbre, gain, rng)


## Reeds, whistle, accordion and violin: shaped waves with an attack, a release and vibrato.
static func _add_sustained(buf: PackedFloat32Array, first: int, count: int, hz: float, timbre: int, gain: float,
		rng: RandomNumberGenerator) -> void:
	var size: int = buf.size()
	var attack: float = {Timbre.REED: 0.04, Timbre.WHISTLE: 0.07, Timbre.ACCORDION: 0.06, Timbre.VIOLIN: 0.15}.get(timbre, 0.05)
	var vibrato_depth: float = {Timbre.REED: 0.003, Timbre.WHISTLE: 0.004, Timbre.ACCORDION: 0.0, Timbre.VIOLIN: 0.006}.get(timbre, 0.0)
	var attack_n: int = maxi(1, int(attack * MIX_RATE))
	var release_n: int = mini(int(0.08 * MIX_RATE), count / 2)
	var phase: float = rng.randf()
	var phase_two: float = rng.randf()
	var smooth: float = 0.0
	var cutoff: float = 0.25 if timbre == Timbre.REED else 0.18
	for index: int in count:
		var envelope: float = minf(1.0, float(index) / attack_n)
		if index > count - release_n:
			envelope *= float(count - index) / maxf(1.0, release_n)
		var wobble: float = 1.0 + vibrato_depth * sin(TAU * 5.2 * index / MIX_RATE)
		phase = fmod(phase + hz * wobble / MIX_RATE, 1.0)
		var raw: float = 0.0
		match timbre:
			Timbre.REED:
				raw = 1.0 if phase < 0.3 else -0.43
			Timbre.WHISTLE:
				raw = sin(TAU * phase) + 0.15 * sin(TAU * phase * 2.0) + rng.randf_range(-0.04, 0.04)
			Timbre.ACCORDION:
				phase_two = fmod(phase_two + hz * 1.0046 / MIX_RATE, 1.0)
				raw = (phase * 2.0 - 1.0) + (phase_two * 2.0 - 1.0)
			_:
				raw = phase * 2.0 - 1.0
		smooth += (raw - smooth) * cutoff
		var at: int = first + index
		if at >= size:
			at %= size
		buf[at] += smooth * envelope * gain


## A steady, seamless loop note: its pitch rounded so whole cycles fill the loop.
static func _drone(buf: PackedFloat32Array, midi: int, gain: float) -> void:
	var size: int = buf.size()
	var length: float = float(size) / MIX_RATE
	var cycles: float = roundf(midi_hz(midi) * length)
	for index: int in size:
		var phase: float = fmod(cycles * index / size, 1.0)
		var partner: float = fmod(cycles * 2.0 * index / size, 1.0)
		buf[index] += ((phase * 2.0 - 1.0) * 0.6 + sin(TAU * partner) * 0.3) * gain


## Softened noise with a slow swell: fire hiss, or running water.
static func _noise_bed(buf: PackedFloat32Array, rng: RandomNumberGenerator, brightness: float, gain: float) -> void:
	var size: int = buf.size()
	var smooth: float = 0.0
	for index: int in size:
		smooth += (rng.randf_range(-1.0, 1.0) - smooth) * brightness
		var swell: float = 0.7 + 0.3 * sin(TAU * 2.0 * index / size)
		buf[index] += smooth * swell * gain * 4.0


# --- PCM ------------------------------------------------------------------------

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
