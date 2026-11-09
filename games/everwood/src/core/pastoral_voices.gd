## The farm's and the hedges' voices (docs/33 §10, the Creative Director's call of 2026-11-09): sheep and lambs,
## cattle, hens, geese, and two songbirds, made in code as 16_ADAPTIVE_AUDIO_ARCHITECTURE.md's Tier 2 makes the
## chamber ensemble. No voice is a bare oscillator: each is an excitation through resonators.
##   SHEEP, LAMB   a throat's harmonics (1/k^1.2) through a mouth's formant resonators, opening from a closed "m"
##                 to an open "eh" (the bleat's "mbeh"), with the quaver that makes it a bleat: about 7.5 Hz
##                 (a lamb's 9 Hz) in pitch and loudness
##   CATTLE        a low throat through a mouth that opens from "m" through "oo" to "aa" and closes again, the
##                 pitch lifting then sinking, with breath
##   HENS          short voiced "buk"s, and now and then a rising "ba-GAWK" to end the phrase
##   GEESE         a nasal, slightly rough honk, alone or in a pair ("ha-honk")
##   SONGBIRD      a fluting phrase like a blackbird's: a flue (the pipe's tone over breath ringing a resonator)
##                 gliding between notes, with the score's own grace-note flicks (16 §2, the Shore axis)
##   WREN          a quick run of falling chirps and a trill, high
## The Living Storybook Atelier (16 §2): the voices are the score's neighbours, not a field recording. Each one's
## resting pitch is a note of the Chime-Shrine's G pentatonic (G A B D E), and the birds sing from it, so a bleat or
## a blackbird under the score never clashes. They're soft and rounded (gentle attacks, a warm low-pass), and each
## take is seeded by its voice and number, so a flock always sounds the same.
## Rendering takes a moment in GDScript, so warm() renders every take on a worker thread when the first beast
## or bird would sing; until then stream() returns null and nothing sings.
class_name PastoralVoices
extends RefCounted

enum Voice { SHEEP, LAMB, CATTLE, HENS, GEESE, SONGBIRD, WREN }

const MIX_RATE: int = 22050
## Each take is scaled so its loudest sample sits here (ProceduralChamberSynth.PEAK).
const PEAK: float = 0.6
## Takes per voice, so a flock doesn't repeat itself.
const TAKES: int = 3
const TABLE_SIZE: int = 1024
## The Chime-Shrine's G pentatonic, as pitch classes (G A B D E).
const PENTATONIC_CLASSES: Array[int] = [7, 9, 11, 2, 4]
## Each voice's resting pitch by take (MIDI), all on the G pentatonic: ewes D4, E4, B3; lambs B4, D5, A4; cattle A2,
## G2, B2; hens G4, A4, B4; geese D4, E4, G4. The birds sing from these.
const RESTING: Array = [[62, 64, 59], [71, 74, 69], [45, 43, 47], [67, 69, 71], [62, 64, 67], [91, 93, 95], [100, 103, 105]]
## The birds' notes: G pentatonic from G6 to B7.
const BIRD_NOTES: Array[int] = [91, 93, 95, 98, 100, 103, 105, 107]
## Mouths (formant resonators, (centre Hz, Q)): closed "m", an ewe's open "eh", a cow's "oo" and "aa", a hen's "uk"
## and "aw", a goose's nasal "onk".
const M_CLOSED: Array[Vector2] = [Vector2(280.0, 3.0), Vector2(1000.0, 3.0), Vector2(2400.0, 3.0)]
const BLEAT_OPEN: Array[Vector2] = [Vector2(700.0, 4.0), Vector2(1750.0, 5.0), Vector2(2700.0, 4.0)]
const MOO_CLOSED: Array[Vector2] = [Vector2(300.0, 3.0), Vector2(800.0, 4.0), Vector2(2200.0, 3.0)]
const MOO_OPEN: Array[Vector2] = [Vector2(650.0, 3.5), Vector2(1100.0, 4.0), Vector2(2500.0, 3.0)]
const CLUCK: Array[Vector2] = [Vector2(650.0, 4.0), Vector2(1600.0, 5.0), Vector2(2600.0, 4.0)]
const GAWK: Array[Vector2] = [Vector2(820.0, 4.0), Vector2(1300.0, 5.0), Vector2(2800.0, 4.0)]
const HONK: Array[Vector2] = [Vector2(520.0, 4.0), Vector2(1150.0, 6.0), Vector2(2700.0, 5.0)]
## The throat's harmonics stop by here (and the warm low-pass at the end rounds what's left).
const VOICED_TOP_HZ: float = 5000.0
const WARM_HZ: float = 4200.0
## The bleat's quaver: (hz, pitch depth, loudness depth) for an ewe and a lamb.
const EWE_QUAVER: Vector3 = Vector3(7.5, 0.035, 0.4)
const LAMB_QUAVER: Vector3 = Vector3(9.0, 0.04, 0.45)

static var _cache: Dictionary[int, AudioStreamWAV] = {}
static var _lock: Mutex = Mutex.new()
static var _task: int = -1
static var _done: bool = false
static var _waited: bool = false


## A voice's take, ready to play, or null while warm() is still rendering (it starts warm() if it hasn't begun).
static func stream(voice: Voice, take: int) -> AudioStreamWAV:
	warm()
	_lock.lock()
	var found: AudioStreamWAV = _cache.get(_key(voice, take), null)
	_lock.unlock()
	return found


## Renders every take on a worker thread, once.
static func warm() -> void:
	if _task >= 0:
		return
	_task = WorkerThreadPool.add_task(_render_all, false, "Pastoral voices")


static func is_ready() -> bool:
	_lock.lock()
	var done: bool = _done
	_lock.unlock()
	return done


## Waits for warm() to finish (the checks). A task is waited on once.
static func wait_until_ready() -> void:
	warm()
	if not _waited:
		_waited = true
		WorkerThreadPool.wait_for_task_completion(_task)


static func resting_midi(voice: Voice, take: int) -> int:
	var row: Array = RESTING[voice]
	return int(row[posmod(take, row.size())])


static func _key(voice: Voice, take: int) -> int:
	return int(voice) * 16 + posmod(take, TAKES)


static func _render_all() -> void:
	for voice: int in Voice.size():
		for take: int in TAKES:
			var made: AudioStreamWAV = render(voice as Voice, take)
			_lock.lock()
			_cache[_key(voice as Voice, take)] = made
			_lock.unlock()
	_lock.lock()
	_done = true
	_lock.unlock()


## One take of a voice, rendered from scratch (pure and deterministic: the same voice and take always sound the same).
static func render(voice: Voice, take: int) -> AudioStreamWAV:
	return to_stream(render_samples(voice, take))


static func render_samples(voice: Voice, take: int) -> PackedFloat32Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("pastoral_%d_%d" % [voice, take])
	var hz: float = midi_hz(resting_midi(voice, take))
	var buf: PackedFloat32Array = PackedFloat32Array()
	match voice:
		Voice.SHEEP, Voice.LAMB:
			var lamb: bool = voice == Voice.LAMB
			var length: float = rng.randf_range(0.5, 0.68) if lamb else rng.randf_range(0.7, 0.98)
			buf.resize(int((length + 0.25) * MIX_RATE))
			var mouth: Array[Vector2] = _scaled(BLEAT_OPEN, 1.15) if lamb else BLEAT_OPEN
			_voiced(buf, 0.02, length, hz, M_CLOSED, mouth, PackedVector2Array([Vector2(0.0, 0.92), Vector2(0.12, 1.02), Vector2(0.7, 1.0), Vector2(1.0, 0.9)]),
				PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.1, 1.0), Vector2(0.85, 0.9), Vector2(1.0, 0.4)]), LAMB_QUAVER if lamb else EWE_QUAVER,
				0.03, 0.0, 0.04, 0.18, 1.0, rng)
		Voice.CATTLE:
			var length: float = rng.randf_range(1.5, 2.1)
			buf.resize(int((length + 0.4) * MIX_RATE))
			_voiced(buf, 0.05, length, hz, MOO_CLOSED, MOO_OPEN, PackedVector2Array([Vector2(0.0, 0.9), Vector2(0.25, 1.05), Vector2(0.7, 1.0), Vector2(1.0, 0.82)]),
				PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.15, 0.25), Vector2(0.5, 1.0), Vector2(0.85, 0.7), Vector2(1.0, 0.0)]), Vector3(4.5, 0.01, 0.08),
				0.06, 0.0, 0.18, 0.35, 1.0, rng)
		Voice.HENS:
			buf.resize(int(2.4 * MIX_RATE))
			var at: float = 0.03
			var buks: int = rng.randi_range(3, 5)
			for buk: int in buks:
				_voiced(buf, at, rng.randf_range(0.06, 0.09), hz * rng.randf_range(0.97, 1.05), CLUCK, CLUCK, PackedVector2Array([Vector2(0.0, 1.0), Vector2(1.0, 0.9)]),
					PackedVector2Array([Vector2(0.0, 1.0), Vector2(1.0, 1.0)]), Vector3.ZERO, 0.04, 0.0, 0.005, 0.04, 0.8, rng)
				at += rng.randf_range(0.16, 0.34)
			# Every other take ends its phrase in a rising "ba-GAWK".
			if take % 2 == 1:
				_voiced(buf, at, 0.07, hz * 1.1, CLUCK, CLUCK, PackedVector2Array([Vector2(0.0, 1.0), Vector2(1.0, 1.0)]),
					PackedVector2Array([Vector2(0.0, 1.0), Vector2(1.0, 1.0)]), Vector3.ZERO, 0.04, 0.0, 0.005, 0.03, 0.8, rng)
				_voiced(buf, at + 0.1, 0.28, hz * 1.2, CLUCK, GAWK, PackedVector2Array([Vector2(0.0, 1.0), Vector2(0.6, 1.35), Vector2(1.0, 1.25)]),
					PackedVector2Array([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.8)]), Vector3.ZERO, 0.05, 0.0, 0.01, 0.08, 1.0, rng)
		Voice.GEESE:
			buf.resize(int(1.2 * MIX_RATE))
			var at: float = 0.02
			for honk: int in take + 1:
				# A short "ha" before each "honk", lower and quick.
				_voiced(buf, at, 0.1, hz * 0.9, HONK, HONK, PackedVector2Array([Vector2(0.0, 0.92), Vector2(1.0, 1.0)]),
					PackedVector2Array([Vector2(0.0, 0.7), Vector2(1.0, 1.0)]), Vector3(22.0, 0.0, 0.2), 0.05, 0.03, 0.01, 0.03, 0.6, rng)
				_voiced(buf, at + 0.13, 0.22, hz, HONK, HONK, PackedVector2Array([Vector2(0.0, 0.9), Vector2(0.3, 1.05), Vector2(1.0, 0.95)]),
					PackedVector2Array([Vector2(0.0, 1.0), Vector2(1.0, 1.0)]), Vector3(22.0, 0.0, 0.25), 0.05, 0.03, 0.01, 0.06, 1.0, rng)
				at += 0.42
		Voice.SONGBIRD:
			buf.resize(int(2.2 * MIX_RATE))
			var at: float = 0.04
			var note: int = BIRD_NOTES.find(resting_midi(voice, take))
			for step: int in rng.randi_range(4, 7):
				var next: int = clampi(note + [-2, -1, 1, 2][rng.randi() % 4], 0, 4)
				var length: float = rng.randf_range(0.09, 0.22)
				# Now and then the score's grace-note flick: a 25 ms lift into the note.
				if rng.randf() < 0.35:
					_flue(buf, at, 0.025, midi_hz(BIRD_NOTES[note] + 2), midi_hz(BIRD_NOTES[note]), 0.0, 0.0, 0.5, rng)
					at += 0.03
				_flue(buf, at, length, midi_hz(BIRD_NOTES[note]), midi_hz(BIRD_NOTES[next]), 0.0, 0.0, 0.9, rng)
				at += length + rng.randf_range(0.03, 0.08)
				note = next
			# A little twitter to close.
			for chirp: int in 3:
				_flue(buf, at, 0.035, midi_hz(BIRD_NOTES[note] + 5), midi_hz(BIRD_NOTES[note]), 0.0, 0.0, 0.45, rng)
				at += 0.05
		Voice.WREN:
			buf.resize(int(1.6 * MIX_RATE))
			var at: float = 0.03
			var top: int = BIRD_NOTES.find(resting_midi(voice, take))
			for chirp: int in rng.randi_range(6, 9):
				var from: int = BIRD_NOTES[clampi(top + (chirp % 2), 0, BIRD_NOTES.size() - 1)]
				_flue(buf, at, rng.randf_range(0.04, 0.06), midi_hz(from), midi_hz(from - rng.randi_range(3, 6)), 0.0, 0.0, 0.7, rng)
				at += 0.075
			_flue(buf, at + 0.04, rng.randf_range(0.4, 0.55), midi_hz(BIRD_NOTES[maxi(top - 1, 0)]), midi_hz(BIRD_NOTES[maxi(top - 1, 0)]), 22.0, 0.06, 0.6, rng)
	_warm(buf)
	_normalize(buf)
	return buf


static func midi_hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


# --- The resonators -----------------------------------------------------------------------------------

## A voiced call: the throat's harmonics through a mouth that moves from `closed` to `open` by `openness`
## (time share, 0 to 1), the pitch following `pitch` (time share, ratio to `hz`), with a quaver
## (hz, pitch depth, loudness depth), breath, roughness (a goose's per-cycle wobble), and an attack and release.
static func _voiced(buf: PackedFloat32Array, start: float, length: float, hz: float, closed: Array[Vector2], open: Array[Vector2],
		pitch: PackedVector2Array, openness: PackedVector2Array, quaver: Vector3, breath: float, rough: float, attack: float, release: float,
		gain: float, rng: RandomNumberGenerator) -> void:
	var shut: PackedFloat32Array = _table(hz, closed)
	var wide: PackedFloat32Array = _table(hz, open)
	var first: int = int(start * MIX_RATE)
	var count: int = mini(int(length * MIX_RATE), buf.size() - first)
	var phase: float = 0.0
	var wobble: float = 1.0
	var hiss: float = 0.0
	var rate: float = float(MIX_RATE)
	for index: int in count:
		var t: float = index / rate
		var share: float = float(index) / float(maxi(count, 1))
		var swing: float = sin(TAU * quaver.x * t)
		var ratio: float = _curve(pitch, share) * (1.0 + quaver.y * swing) * wobble
		var before: float = phase
		phase = fposmod(phase + hz * ratio / rate, 1.0)
		if rough > 0.0 and phase < before:
			wobble = 1.0 + rng.randf_range(-rough, rough)
		var slot: int = int(phase * TABLE_SIZE)
		var mouth: float = _curve(openness, share)
		var tone: float = lerpf(shut[slot], wide[slot], mouth) * (1.0 - quaver.z * (0.5 + 0.5 * swing))
		hiss += (rng.randf_range(-1.0, 1.0) - hiss) * 0.35
		var envelope: float = minf(1.0, t / maxf(attack, 0.001)) * minf(1.0, (length - t) / maxf(release, 0.001))
		buf[first + index] += (tone + hiss * breath * (0.4 + mouth)) * maxf(envelope, 0.0) * gain


## One cycle of the throat's harmonics at `hz`, each weighted by the mouth's resonators at its frequency
## (exact for a held tone, 16 §6 note 8), scaled to a peak of 1.
static func _table(hz: float, formants: Array[Vector2]) -> PackedFloat32Array:
	var table: PackedFloat32Array = PackedFloat32Array()
	table.resize(TABLE_SIZE)
	var harmonics: int = maxi(1, int(VOICED_TOP_HZ / maxf(hz, 20.0)))
	var weights: PackedFloat32Array = PackedFloat32Array()
	for k: int in range(1, harmonics + 1):
		var f: float = hz * k
		var response: float = 0.04
		for formant: Vector2 in formants:
			var detune: float = f / formant.x - formant.x / f
			response += 1.0 / sqrt(1.0 + formant.y * formant.y * detune * detune)
		weights.append(pow(float(k), -1.2) * response)
	var top: float = 0.0
	for index: int in TABLE_SIZE:
		var x: float = TAU * float(index) / TABLE_SIZE
		var value: float = 0.0
		for k: int in weights.size():
			value += weights[k] * sin(x * (k + 1) + 0.6 * k)
		table[index] = value
		top = maxf(top, absf(value))
	for index: int in TABLE_SIZE:
		table[index] /= maxf(top, 0.0001)
	return table


## A flue (a bird's whistle): the pipe's tone, gliding from `from_hz` to `to_hz` (with a trill: hz and depth),
## over breath ringing a resonator that follows the pitch, in a soft swell.
static func _flue(buf: PackedFloat32Array, start: float, length: float, from_hz: float, to_hz: float, trill_hz: float, trill: float,
		gain: float, rng: RandomNumberGenerator) -> void:
	var first: int = int(start * MIX_RATE)
	var count: int = mini(int(length * MIX_RATE), buf.size() - first)
	var rate: float = float(MIX_RATE)
	var phase: float = 0.0
	var one: float = 0.0
	var two: float = 0.0
	for index: int in count:
		var t: float = index / rate
		var share: float = float(index) / float(maxi(count, 1))
		var f: float = lerpf(from_hz, to_hz, smoothstep(0.0, 1.0, share)) * (1.0 + trill * sin(TAU * trill_hz * t))
		phase = fposmod(phase + f / rate, 1.0)
		var pipe: float = sin(TAU * phase) + 0.12 * sin(2.0 * TAU * phase)
		# The breath through a resonator at the pipe's pitch (r 0.995: a narrow, ringing band).
		var radius: float = 0.995
		var ring: float = 2.0 * radius * cos(TAU * f / rate) * one - radius * radius * two + rng.randf_range(-1.0, 1.0) * 0.01
		two = one
		one = ring
		var swell: float = pow(sin(PI * share), 0.6)
		buf[first + index] += (pipe * 0.85 + ring * 0.6) * swell * gain


## Piecewise-linear: the value at `share` along points (share, value).
static func _curve(points: PackedVector2Array, share: float) -> float:
	if share <= points[0].x:
		return points[0].y
	for index: int in range(1, points.size()):
		if share <= points[index].x:
			var a: Vector2 = points[index - 1]
			var b: Vector2 = points[index]
			return lerpf(a.y, b.y, (share - a.x) / maxf(b.x - a.x, 0.0001))
	return points[points.size() - 1].y


static func _scaled(formants: Array[Vector2], by: float) -> Array[Vector2]:
	var made: Array[Vector2] = []
	for formant: Vector2 in formants:
		made.append(Vector2(formant.x * by, formant.y))
	return made


## A warm one-pole low-pass, so nothing is shrill.
static func _warm(buf: PackedFloat32Array) -> void:
	var alpha: float = 1.0 - exp(-TAU * WARM_HZ / MIX_RATE)
	var held: float = 0.0
	for index: int in buf.size():
		held += (buf[index] - held) * alpha
		buf[index] = held


static func _normalize(buf: PackedFloat32Array) -> void:
	var top: float = 0.0
	for value: float in buf:
		top = maxf(top, absf(value))
	if top <= 0.0:
		return
	var scale: float = PEAK / top
	for index: int in buf.size():
		buf[index] *= scale


static func to_stream(buf: PackedFloat32Array) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(buf.size() * 2)
	for index: int in buf.size():
		data.encode_s16(index * 2, int(clampf(buf[index], -1.0, 1.0) * 32767.0))
	var made: AudioStreamWAV = AudioStreamWAV.new()
	made.format = AudioStreamWAV.FORMAT_16_BITS
	made.mix_rate = MIX_RATE
	made.stereo = false
	made.data = data
	return made


# --- Playing -----------------------------------------------------------------------------------------------

## A 3D player on the Ambience3D bus, carrying `reach` metres (AudioDirector.attach_ambience's settings).
static func player(node_name: String, reach: float, volume_db: float) -> AudioStreamPlayer3D:
	var made: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	made.name = node_name
	made.bus = AudioDirector.BUS_NAMES[AudioDirector.AMBIENCE_BUS]
	made.unit_size = AudioDirector.UNIT_SIZE
	made.max_db = AudioDirector.MAX_DB
	made.max_distance = reach
	made.attenuation_filter_cutoff_hz = AudioDirector.FAR_FILTER_HZ
	made.attenuation_filter_db = AudioDirector.FAR_FILTER_DB
	made.volume_db = volume_db
	return made


## Whether sound is off (a headless run): voices are still chosen and counted, never played.
static func silent() -> bool:
	return DisplayServer.get_name() == "headless"
