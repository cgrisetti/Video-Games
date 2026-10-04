// Coin Hop's background music, made from scratch: no recordings, every sound is computed here.
//
// Run it with:  npm run music
//
// It writes three seamless loops into games/coin-hop/audio/, each as a WAV and an OGG:
//   forest-theme       The main track: ocarina melody, warm pad, harp arpeggios, triangle bass,
//                      a quiet shaker and wind chimes, with light reverb and a ping-pong echo.
//   forest-theme-8bit  The same tune for an old game console's sound chip: two pulse waves,
//                      a triangle bass and noise drums.
//   forest-danger      A darker layer to fade in when an inch worm is near: pulsing low bass and
//                      tremolo strings. Same key, tempo and length, so it lines up exactly.
// plus music.json, which tells the game how long one loop is.
//
// The tune is original. Change the settings, chords or melody below, then run it again.

import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createOggEncoder } from 'wasm-media-encoders';

const OUTPUT_DIR = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'games', 'coin-hop', 'audio');

// --- Settings ---

const RATE = 44100; // Samples per second.
const BPM = 88;
const BEATS_PER_BAR = 3; // 3/4 time: a gentle waltz sway.
const BARS = 32;
const TAIL_SECONDS = 8; // Extra time rendered past the end so echoes ring out; it's folded back onto the start.
const PEAK_DB = -1; // The loudest moment of each file, in decibels below full scale.
const OGG_QUALITY = 4; // Ogg Vorbis quality, 0 (small) to 10 (best). 4 is about 128 kbps.
const SEED = 2026; // Change it for different wind chimes and tiny timing wobbles.

const BEAT = 60 / BPM;
const BAR = BEAT * BEATS_PER_BAR;
const LOOP_SAMPLES = Math.round(BAR * BARS * RATE);
const TOTAL_SAMPLES = LOOP_SAMPLES + Math.round(TAIL_SECONDS * RATE);

// When something happens, in seconds. Bars count from 1, beats from 0.
const at = (bar, beat = 0) => ((bar - 1) * BEATS_PER_BAR + beat) * BEAT;

// --- The tune ---

// One chord per bar. A (bars 1-16) wanders out and comes home; B (bars 17-32) drifts lower and
// more mysterious, then the final A chord leads back to D at the top of the loop.
// "E/D" and "E" use G#, the magical-sounding note borrowed from the Lydian mode.
const CHORDS = [
  'Dmaj7', 'Dmaj7', 'E/D', 'E/D', 'Bm7', 'Bm7', 'Gmaj7', 'Asus4',
  'Dmaj7', 'F#m7', 'Gmaj7', 'E', 'Bm7', 'Gmaj7', 'Em7', 'A',
  'Gmaj7', 'Gmaj7', 'F#m7', 'Bm7', 'Em7', 'E', 'Gmaj7', 'Asus4',
  'Bm7', 'Gmaj7', 'D/F#', 'E', 'Gmaj7', 'Em7', 'Asus4', 'A',
];

// How each chord is played: a bass note, the pad's notes and the notes the harp picks from.
const SHAPES = {
  Dmaj7: { bass: 'D2', pad: ['F#3', 'A3', 'C#4', 'E4'], arp: ['D4', 'A4', 'C#5', 'E5'] },
  'E/D': { bass: 'D2', pad: ['E3', 'G#3', 'B3', 'D4'], arp: ['E4', 'G#4', 'B4', 'D5'] },
  Bm7: { bass: 'B1', pad: ['D3', 'F#3', 'A3', 'C#4'], arp: ['B3', 'F#4', 'A4', 'D5'] },
  Gmaj7: { bass: 'G1', pad: ['D3', 'F#3', 'B3', 'E4'], arp: ['G4', 'B4', 'D5', 'F#5'] },
  Asus4: { bass: 'A1', pad: ['D3', 'E3', 'A3', 'E4'], arp: ['A4', 'D5', 'E5', 'A5'] },
  A: { bass: 'A1', pad: ['C#3', 'E3', 'A3', 'E4'], arp: ['A4', 'C#5', 'E5', 'A5'] },
  'F#m7': { bass: 'F#2', pad: ['E3', 'A3', 'C#4', 'F#4'], arp: ['F#4', 'A4', 'C#5', 'E5'] },
  E: { bass: 'E2', pad: ['E3', 'G#3', 'B3', 'E4'], arp: ['E4', 'G#4', 'B4', 'E5'] },
  Em7: { bass: 'E2', pad: ['D3', 'G3', 'B3', 'E4'], arp: ['E4', 'G4', 'B4', 'D5'] },
  'D/F#': { bass: 'F#2', pad: ['D3', 'F#3', 'A3', 'D4'], arp: ['F#4', 'A4', 'D5', 'F#5'] },
};

// The ocarina melody: [bar, beat, note, length in beats]. Lots of rests, so it never tires.
const MELODY = [
  // A: a gentle question...
  [1, 1, 'A4', 1], [1, 2, 'D5', 1],
  [2, 0, 'F#5', 2], [2, 2, 'E5', 1],
  [3, 0, 'E5', 1.5], [3, 1.5, 'F#5', 0.5], [3, 2, 'G#5', 1],
  [4, 0, 'E5', 3],
  // ...and its answer.
  [6, 1, 'D5', 1], [6, 2, 'C#5', 1],
  [7, 0, 'B4', 1.5], [7, 1.5, 'A4', 0.5], [7, 2, 'F#4', 1],
  [8, 0, 'A4', 3],
  [9, 1, 'A4', 1], [9, 2, 'D5', 1],
  [10, 0, 'F#5', 1.5], [10, 1.5, 'E5', 0.5], [10, 2, 'C#5', 1],
  [11, 0, 'D5', 1], [11, 1, 'B4', 2],
  [12, 0, 'G#4', 1], [12, 1, 'B4', 1], [12, 2, 'E5', 1],
  [13, 0, 'F#5', 2], [13, 2, 'E5', 1],
  [14, 0, 'D5', 3],
  [16, 1, 'E5', 1], [16, 2, 'C#5', 1],
  // B: lower, curious, a little mysterious.
  [17, 0, 'B4', 2], [17, 2, 'D5', 1],
  [18, 0, 'F#5', 3],
  [19, 0, 'E5', 1], [19, 1, 'C#5', 2],
  [21, 0, 'G4', 1], [21, 1, 'B4', 1], [21, 2, 'D5', 1],
  [22, 0, 'B4', 1], [22, 1, 'G#4', 2],
  [23, 0, 'A4', 1], [23, 1, 'B4', 1], [23, 2, 'F#5', 1],
  [24, 0, 'E5', 3],
  [26, 1, 'D5', 1], [26, 2, 'E5', 1],
  [27, 0, 'F#5', 1.5], [27, 1.5, 'A5', 0.5], [27, 2, 'F#5', 1],
  [28, 0, 'G#5', 2], [28, 2, 'E5', 1],
  [29, 0, 'D5', 3],
  [30, 1, 'B4', 1], [30, 2, 'A4', 1],
  [31, 0, 'A4', 2.5],
];

// How busy the harp is in each bar: 0 rests, 1 a few notes, 2 a flowing line, 3 every eighth note.
const HARP = [
  1, 1, 1, 1, 1, 0, 1, 1, 2, 2, 2, 1, 2, 2, 2, 1,
  2, 2, 3, 2, 2, 2, 3, 2, 3, 3, 2, 2, 2, 2, 1, 0,
];
// Which eighth notes of the bar the harp plays, and which of the chord's harp notes: [eighth, note].
const HARP_PATTERNS = [
  [],
  [[0, 0], [2, 2], [4, 1]],
  [[0, 0], [1, 1], [2, 2], [3, 3], [4, 2]],
  [[0, 0], [1, 1], [2, 2], [3, 3], [4, 2], [5, 1]],
];

const CHIME_NOTES = ['A5', 'B5', 'D6', 'E6', 'F#6', 'G#6', 'A6'];

// --- Helpers ---

const NOTE_STEPS = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

// The pitch of a note like 'F#4', in Hz. `shift` moves it up or down in semitones.
function frequency(note, shift = 0) {
  const [, letter, sharp, octave] = note.match(/^([A-G])(#?)(\d)$/);
  const midi = 12 * (Number(octave) + 1) + NOTE_STEPS[letter] + (sharp ? 1 : 0) + shift;
  return 440 * 2 ** ((midi - 69) / 12);
}

// A random number generator that gives the same numbers every run, so the music comes out the same.
function seededRandom(seed) {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = Math.imul(state ^ (state >>> 15), state | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const random = seededRandom(SEED);

// A smooth 0-to-1 fade along a sine curve.
function ease(x) {
  const clamped = Math.min(Math.max(x, 0), 1);
  return Math.sin((Math.PI / 2) * clamped) ** 2;
}

// How loud a note is `t` seconds in: fades in over `attack`, holds until `length`, fades out over `release`.
function envelope(t, length, attack, release) {
  if (t < attack) return ease(t / attack);
  if (t < length) return 1;
  return 1 - ease((t - length) / release);
}

// One cycle of a waveform, built by adding harmonics, so instruments can read it quickly.
const TABLE_SIZE = 2048;
function wavetable(harmonics) {
  const table = new Float32Array(TABLE_SIZE + 1);
  harmonics.forEach((amount, h) => {
    for (let i = 0; i < TABLE_SIZE; i++) table[i] += amount * Math.sin((2 * Math.PI * (h + 1) * i) / TABLE_SIZE);
  });
  const peak = table.reduce((most, value) => Math.max(most, Math.abs(value)), 0);
  for (let i = 0; i < TABLE_SIZE; i++) table[i] /= peak;
  table[TABLE_SIZE] = table[0];
  return table;
}

function readTable(table, phase) {
  const position = phase * TABLE_SIZE;
  const i = position | 0;
  return table[i] + (table[i + 1] - table[i]) * (position - i);
}

function seconds(length) {
  return new Float32Array(Math.ceil(length * RATE));
}

// --- Instruments (each returns one mono sound) ---

// Ocarina: a pure, flute-like tone with a little breath noise, and vibrato that creeps in late.
const OCARINA = wavetable([1, 0.1, 0.04, 0.015]);
function ocarina(note, beats) {
  const pitch = frequency(note);
  const length = beats * BEAT * 0.95;
  const release = 0.35;
  const sound = seconds(length + release);
  let phase = 0;
  let breathLow = 0;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    const vibrato = 0.011 * ease((t - 0.3) / 0.6) * Math.sin(2 * Math.PI * 5.2 * t);
    phase += (pitch * (1 + vibrato)) / RATE;
    phase -= Math.floor(phase);
    const noise = random() * 2 - 1;
    breathLow += 0.2 * (noise - breathLow);
    const breath = (noise - breathLow) * (0.035 + 0.12 * Math.exp(-t / 0.07)); // Breathier at the start.
    sound[i] = envelope(t, length, 0.07, release) * (readTable(OCARINA, phase) + breath);
  }
  return sound;
}

// Pad: a soft, warm tone that swells in slowly and shimmers gently.
const PAD = wavetable([1, 0.45, 0.25, 0.14, 0.08, 0.045, 0.025, 0.012]);
function padVoice(note, length, detuneCents) {
  const pitch = frequency(note) * 2 ** (detuneCents / 1200);
  const release = 1.8;
  const sound = seconds(length + release);
  let phase = random();
  const shimmer = random() * Math.PI * 2;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    phase += pitch / RATE;
    phase -= Math.floor(phase);
    sound[i] = envelope(t, length, 1.1, release) * (1 + 0.07 * Math.sin(2 * Math.PI * 0.27 * t + shimmer)) * readTable(PAD, phase);
  }
  return sound;
}

// Harp / kalimba: a plucked string, made with the Karplus-Strong method. A burst of soft noise
// circles round a delay line exactly one string-vibration long, and averaging each trip round
// mellows it the way a real string's ring fades.
function pluck(note, length = 2.6) {
  const pitch = frequency(note);
  const sound = seconds(length);
  const delay = RATE / pitch - 0.5; // The averaging step adds half a sample of delay.
  const start = Math.ceil(delay) + 1;
  let soft = 0;
  let mean = 0;
  for (let i = 0; i < start; i++) {
    soft += 0.5 * (random() * 2 - 1 - soft);
    sound[i] = soft;
    mean += soft / start;
  }
  for (let i = 0; i < start; i++) sound[i] -= mean;
  for (let i = start; i < sound.length; i++) {
    const back = i - delay;
    const j = Math.floor(back);
    const fraction = back - j;
    const now = sound[j] + (sound[j + 1] - sound[j]) * fraction;
    const before = sound[j - 1] + (sound[j] - sound[j - 1]) * fraction;
    sound[i] = 0.996 * 0.5 * (now + before);
  }
  fadeOutEnd(sound, 0.05);
  return sound;
}

// Bass: a round triangle wave.
function bass(note, beats, shift = 0) {
  const pitch = frequency(note, shift);
  const length = beats * BEAT * 0.92;
  const release = 0.25;
  const sound = seconds(length + release);
  let phase = 0;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    phase += pitch / RATE;
    phase -= Math.floor(phase);
    const triangle = 4 * Math.abs(phase - 0.5) - 1;
    sound[i] = envelope(t, length, 0.02, release) * (0.75 + 0.25 * Math.exp(-t / 0.25)) * triangle;
  }
  return sound;
}

// Shaker: a tiny hiss of filtered noise.
function shake() {
  const sound = seconds(0.09);
  let low = 0;
  let band = 0;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    const noise = random() * 2 - 1;
    low += 0.5 * (noise - low);
    band += 0.6 * (noise - low - band);
    sound[i] = band * (1 - Math.exp(-t / 0.003)) * Math.exp(-t / 0.028);
  }
  return sound;
}

// Wind chime: a little metal bar ringing. Its overtones aren't evenly spaced, which makes it shimmer.
const CHIME_PARTIALS = [[1, 1, 2.4], [2.76, 0.45, 1.3], [5.4, 0.22, 0.7], [8.93, 0.1, 0.35]]; // [pitch ratio, loudness, seconds to fade]
function chime(note) {
  const pitch = frequency(note);
  const sound = seconds(3.2);
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    let value = 0;
    for (const [ratio, amount, fade] of CHIME_PARTIALS) value += amount * Math.exp((-2.3 * t) / fade) * Math.sin(2 * Math.PI * pitch * ratio * t);
    sound[i] = value * Math.min(1, t / 0.002);
  }
  fadeOutEnd(sound, 0.1);
  return sound;
}

// Strings for the danger layer: three slightly out-of-tune bright waves (like a section of players),
// softened, with fast tremolo: the bow shivering back and forth four times a beat.
const SAW = wavetable(Array.from({ length: 24 }, (_, i) => 1 / (i + 1)));
function tremoloStrings(note, length) {
  const pitch = frequency(note);
  const release = 0.6;
  const sound = seconds(length + release);
  const phases = [random(), random(), random()];
  const detunes = [-7, 0, 6].map((cents) => 2 ** (cents / 1200));
  const tremoloRate = 4 / BEAT;
  let soft = 0;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    let value = 0;
    for (let v = 0; v < 3; v++) {
      phases[v] += (pitch * detunes[v]) / RATE;
      phases[v] -= Math.floor(phases[v]);
      value += readTable(SAW, phases[v]) / 3;
    }
    soft += 0.2 * (value - soft);
    const tremolo = 0.35 + 0.65 * (0.5 + 0.5 * Math.cos(2 * Math.PI * tremoloRate * t)) ** 2;
    sound[i] = envelope(t, length, 0.25, release) * tremolo * soft;
  }
  return sound;
}

// Danger bass: a dark buzzy note that pulses on every eighth note, its tone opening up on each pulse.
function pulsingBass(note, length) {
  const pitch = frequency(note);
  const eighth = BEAT / 2;
  const sound = seconds(length + 0.08);
  let phase = 0;
  let dark = 0;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    phase += pitch / RATE;
    phase -= Math.floor(phase);
    const pulse = Math.exp(-(t % eighth) / 0.09);
    dark += (0.02 + 0.08 * pulse) * (readTable(SAW, phase) - dark);
    sound[i] = envelope(t, length, 0.01, 0.08) * (0.25 + 0.75 * pulse) * dark;
  }
  return sound;
}

// --- 8-bit instruments ---

// Square-ish pulse waves like an old console's. `duty` is how much of each cycle is "on".
// Volume moves in 16 steps, as it did on the real chips.
function chipNote(note, beats, duty, { decay = 0.4, hold = 0.55, vibrato = true } = {}) {
  const pitch = frequency(note);
  const length = beats * BEAT * 0.92;
  const sound = seconds(length + 0.06);
  let phase = 0;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    const wobble = vibrato ? 0.008 * (t > 0.3 ? 1 : 0) * Math.sin(2 * Math.PI * 6 * t) : 0;
    phase += (pitch * (1 + wobble)) / RATE;
    phase -= Math.floor(phase);
    const level = t < length ? hold + (1 - hold) * Math.exp(-t / decay) : (hold + (1 - hold) * Math.exp(-length / decay)) * (1 - (t - length) / 0.06);
    const stepped = Math.round(Math.max(level, 0) * 15) / 15;
    sound[i] = stepped * ((phase < duty ? 1 : 0) - duty) * 1.6;
  }
  return sound;
}

// The chip's triangle channel: a triangle built from 32 little steps, always at full volume.
function chipTriangle(note, beats, shift = 0) {
  const pitch = frequency(note, shift);
  const length = beats * BEAT * 0.92;
  const sound = seconds(length);
  let phase = 0;
  for (let i = 0; i < sound.length; i++) {
    const t = i / RATE;
    phase += pitch / RATE;
    phase -= Math.floor(phase);
    const step = Math.floor(phase * 32);
    const level = step < 16 ? step : 31 - step;
    sound[i] = (level / 7.5 - 1) * Math.min(1, t / 0.005, (length - t) / 0.005); // Tiny fades so it doesn't click.
  }
  return sound;
}

// The chip's noise channel: random clicks held for `hold` samples (longer holds sound lower).
function chipNoise(length, hold, fade) {
  const sound = seconds(length);
  let value = 0;
  for (let i = 0; i < sound.length; i++) {
    if (i % hold === 0) value = random() < 0.5 ? -1 : 1;
    const level = Math.round(Math.exp(-(i / RATE) / fade) * 15) / 15;
    sound[i] = value * level;
  }
  return sound;
}

function fadeOutEnd(sound, length) {
  const count = Math.min(sound.length, Math.round(length * RATE));
  for (let i = 0; i < count; i++) sound[sound.length - 1 - i] *= i / count;
}

// --- Mixing ---

function emptyMix() {
  return { left: new Float32Array(TOTAL_SAMPLES), right: new Float32Array(TOTAL_SAMPLES) };
}

// A track has a dry mix, plus mixes that are sent to the reverb and the echo.
class Track {
  constructor() {
    this.dry = emptyMix();
    this.reverb = emptyMix();
    this.echo = emptyMix();
  }

  // Play a sound at `time` seconds. pan: -1 left to 1 right. reverb / echo: how much is sent to them.
  play(sound, time, { volume = 1, pan = 0, reverb = 0, echo = 0 } = {}) {
    place(this.dry, sound, time, volume, pan);
    if (reverb) place(this.reverb, sound, time, volume * reverb, pan);
    if (echo) place(this.echo, sound, time, volume * echo, pan);
  }
}

function place(mix, sound, time, volume, pan) {
  const start = Math.round(time * RATE);
  const angle = ((pan + 1) * Math.PI) / 4; // Equal-power panning.
  const left = Math.cos(angle) * Math.SQRT2 * volume;
  const right = Math.sin(angle) * Math.SQRT2 * volume;
  const end = Math.min(sound.length, TOTAL_SAMPLES - start);
  for (let i = Math.max(0, -start); i < end; i++) {
    mix.left[start + i] += sound[i] * left;
    mix.right[start + i] += sound[i] * right;
  }
}

// Reverb, after the well-known "Freeverb": eight echoing delay lines blurred by four more,
// a slightly different set for each ear so it sounds wide.
function reverb(input, { room = 0.86, damping = 0.4 } = {}) {
  const combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];
  const allpasses = [556, 441, 341, 225];
  const out = emptyMix();
  const feedback = 0.7 + 0.28 * room;
  for (const [channel, spread] of [['left', 0], ['right', 23]]) {
    const output = out[channel];
    for (const size of combs) {
      const buffer = new Float32Array(size + spread);
      let index = 0;
      let filtered = 0;
      for (let i = 0; i < TOTAL_SAMPLES; i++) {
        const delayed = buffer[index];
        filtered = delayed * (1 - damping) + filtered * damping;
        buffer[index] = (input.left[i] + input.right[i]) * 0.0075 + filtered * feedback;
        output[i] += delayed;
        if (++index === buffer.length) index = 0;
      }
    }
    for (const size of allpasses) {
      const buffer = new Float32Array(size + spread);
      let index = 0;
      for (let i = 0; i < TOTAL_SAMPLES; i++) {
        const delayed = buffer[index];
        const value = output[i];
        output[i] = delayed - value;
        buffer[index] = value + delayed * 0.5;
        if (++index === buffer.length) index = 0;
      }
    }
  }
  return out;
}

// Ping-pong echo: each echo bounces to the other side, a little darker and quieter each time.
function pingPong(input, delaySeconds, feedback) {
  const length = Math.round(delaySeconds * RATE);
  const leftLine = new Float32Array(length);
  const rightLine = new Float32Array(length);
  const out = emptyMix();
  let index = 0;
  let darkLeft = 0;
  let darkRight = 0;
  for (let i = 0; i < TOTAL_SAMPLES; i++) {
    const fromLeft = leftLine[index];
    const fromRight = rightLine[index];
    darkLeft += 0.35 * (fromLeft - darkLeft);
    darkRight += 0.35 * (fromRight - darkRight);
    out.left[i] = fromLeft;
    out.right[i] = fromRight;
    leftLine[index] = (input.left[i] + input.right[i]) * 0.5 + darkRight * feedback;
    rightLine[index] = darkLeft * feedback;
    if (++index === length) index = 0;
  }
  return out;
}

function rms(mix) {
  let sum = 0;
  for (let i = 0; i < TOTAL_SAMPLES; i++) sum += mix.left[i] ** 2 + mix.right[i] ** 2;
  return Math.sqrt(sum / (2 * TOTAL_SAMPLES)) || 1;
}

function addInto(target, source, gain) {
  for (let i = 0; i < TOTAL_SAMPLES; i++) {
    target.left[i] += source.left[i] * gain;
    target.right[i] += source.right[i] * gain;
  }
}

// Add the effects at a set level under the dry sound (measured, so changing the reverb's
// inner workings doesn't change how much of it you hear), then make the seamless loop.
function mixdown(track, { reverbLevel = 0, echoLevel = 0, smooth = 0 } = {}) {
  const out = track.dry;
  const dryLevel = rms(out);
  if (reverbLevel) {
    const wet = reverb(track.reverb);
    addInto(out, wet, (reverbLevel * dryLevel) / rms(wet));
  }
  if (echoLevel) {
    const echoes = pingPong(track.echo, BEAT, 0.38);
    addInto(out, echoes, (echoLevel * dryLevel) / rms(echoes));
  }
  if (smooth) {
    // A gentle low-pass, to take the harsh edge off chip sounds.
    for (const channel of [out.left, out.right]) {
      let value = 0;
      for (let i = 0; i < TOTAL_SAMPLES; i++) channel[i] = value += smooth * (channel[i] - value);
    }
  }
  return makeLoop(out);
}

// Turn a mix into a seamless loop: remove any slow drift away from zero, fold the ringing tail
// back onto the start (where it would be ringing on from the loop before), then set the peak level.
function makeLoop(mix) {
  for (const channel of [mix.left, mix.right]) {
    let lastIn = 0;
    let lastOut = 0;
    for (let i = 0; i < TOTAL_SAMPLES; i++) {
      lastOut = channel[i] - lastIn + 0.9995 * lastOut;
      lastIn = channel[i];
      channel[i] = lastOut;
    }
  }
  const left = mix.left.slice(0, LOOP_SAMPLES);
  const right = mix.right.slice(0, LOOP_SAMPLES);
  for (let i = LOOP_SAMPLES; i < TOTAL_SAMPLES; i++) {
    left[i - LOOP_SAMPLES] += mix.left[i];
    right[i - LOOP_SAMPLES] += mix.right[i];
  }
  let peak = 0;
  for (let i = 0; i < LOOP_SAMPLES; i++) peak = Math.max(peak, Math.abs(left[i]), Math.abs(right[i]));
  const gain = 10 ** (PEAK_DB / 20) / peak;
  for (let i = 0; i < LOOP_SAMPLES; i++) {
    left[i] *= gain;
    right[i] *= gain;
  }
  return { left, right };
}

// --- The three tracks ---

// Runs of bars that share a chord, so a held chord keeps sounding instead of swelling in again.
function chordRuns() {
  const runs = [];
  for (let bar = 1; bar <= BARS; bar++) {
    const last = runs[runs.length - 1];
    if (last && last.chord === CHORDS[bar - 1]) last.bars++;
    else runs.push({ chord: CHORDS[bar - 1], bar, bars: 1 });
  }
  return runs;
}

function forestTheme() {
  const track = new Track();

  // Pad: each chord held for as long as it lasts, two slightly out-of-tune copies spread wide.
  for (const { chord, bar, bars } of chordRuns()) {
    for (const note of SHAPES[chord].pad) {
      for (const [cents, pan] of [[-5, -0.55], [5, 0.55]]) {
        track.play(padVoice(note, bars * BAR, cents), at(bar), { volume: 0.05, pan, reverb: 0.5 });
      }
    }
  }

  // Bass: a long low note in part A; in part B it adds a lift on the third beat.
  for (let bar = 1; bar <= BARS; bar++) {
    const root = SHAPES[CHORDS[bar - 1]].bass;
    if (bar <= 16) {
      track.play(bass(root, 2.8), at(bar), { volume: 0.24, reverb: 0.05 });
    } else {
      track.play(bass(root, 2), at(bar), { volume: 0.24, reverb: 0.05 });
      track.play(bass(root, 1, 7), at(bar, 2), { volume: 0.18, reverb: 0.05 });
    }
  }

  // Harp: plucked arpeggios, nudged a hair off the beat and varied in strength, like a person playing.
  for (let bar = 1; bar <= BARS; bar++) {
    const notes = SHAPES[CHORDS[bar - 1]].arp;
    for (const [eighth, which] of HARP_PATTERNS[HARP[bar - 1]]) {
      const time = at(bar, eighth / 2) + (random() - 0.5) * 0.012;
      track.play(pluck(notes[which]), time, { volume: 0.2 * (0.8 + 0.4 * random()), pan: 0.15 + 0.3 * (random() - 0.5), reverb: 0.35, echo: 0.25 });
    }
  }

  // Melody: the ocarina.
  for (const [bar, beat, note, beats] of MELODY) {
    track.play(ocarina(note, beats), at(bar, beat), { volume: 0.3, pan: -0.08, reverb: 0.35, echo: 0.3 });
  }

  // Shaker: very quiet eighth notes through the middle, resting around the loop point.
  const accents = [0.9, 0.35, 0.6, 0.35, 0.75, 0.4];
  for (let bar = 5; bar <= 31; bar++) {
    for (let eighth = 0; eighth < 6; eighth++) {
      track.play(shake(), at(bar, eighth / 2) + (random() - 0.5) * 0.008, { volume: 0.05 * accents[eighth], pan: 0.35, reverb: 0.15 });
    }
  }

  // Wind chimes: every so often, a little cascade of high twinkles.
  for (let bar = 2; bar <= BARS; bar += 4) {
    if (random() > 0.75) continue;
    let time = at(bar, random() * 2);
    const count = 3 + Math.floor(random() * 3);
    for (let i = 0; i < count; i++) {
      const note = CHIME_NOTES[Math.floor(random() * CHIME_NOTES.length)];
      track.play(chime(note), time, { volume: 0.05 + 0.03 * random(), pan: random() * 1.2 - 0.6, reverb: 0.6, echo: 0.2 });
      time += 0.11 + random() * 0.13;
    }
  }

  return mixdown(track, { reverbLevel: 0.4, echoLevel: 0.22 });
}

function chiptuneTheme() {
  const track = new Track();
  for (const [bar, beat, note, beats] of MELODY) {
    track.play(chipNote(note, beats, 0.125), at(bar, beat), { volume: 0.28, pan: -0.1 });
  }
  // With no pad on the chip, the second pulse channel keeps the harp line busier to carry the chords.
  for (let bar = 1; bar <= BARS; bar++) {
    const notes = SHAPES[CHORDS[bar - 1]].arp;
    for (const [eighth, which] of HARP_PATTERNS[Math.min(HARP[bar - 1] + 1, 3)]) {
      track.play(chipNote(notes[which], 0.45, 0.25, { decay: 0.12, hold: 0.2, vibrato: false }), at(bar, eighth / 2), { volume: 0.16, pan: 0.1 });
    }
  }
  for (let bar = 1; bar <= BARS; bar++) {
    const root = SHAPES[CHORDS[bar - 1]].bass;
    if (bar <= 16) {
      track.play(chipTriangle(root, 2.8, 12), at(bar), { volume: 0.35 });
    } else {
      track.play(chipTriangle(root, 2, 12), at(bar), { volume: 0.35 });
      track.play(chipTriangle(root, 1, 19), at(bar, 2), { volume: 0.3 });
    }
  }
  // Noise drums: a soft thump on each bar and a ticking hi-hat on the eighth notes.
  const accents = [1, 0.4, 0.7, 0.4, 0.85, 0.45];
  for (let bar = 5; bar <= 31; bar++) {
    track.play(chipNoise(0.12, 24, 0.05), at(bar), { volume: 0.18 });
    for (let eighth = 0; eighth < 6; eighth++) {
      track.play(chipNoise(0.05, 2, 0.02), at(bar, eighth / 2), { volume: 0.07 * accents[eighth] });
    }
  }
  return mixdown(track, { smooth: 0.85 });
}

function dangerLayer() {
  const track = new Track();
  // Tremolo strings on each chord, low down, with a dark G# (the tritone above D) under the D chords.
  for (const { chord, bar, bars } of chordRuns()) {
    const notes = [...SHAPES[chord].pad];
    if (chord.startsWith('D')) notes.push('G#2');
    notes.forEach((note, i) => {
      track.play(tremoloStrings(note, bars * BAR), at(bar), { volume: 0.06, pan: i % 2 ? 0.4 : -0.4, reverb: 0.3 });
    });
  }
  // The pulsing bass, following the same bass notes as the main track.
  for (let bar = 1; bar <= BARS; bar++) {
    track.play(pulsingBass(SHAPES[CHORDS[bar - 1]].bass, BAR), at(bar), { volume: 0.35, reverb: 0.05 });
  }
  return mixdown(track, { reverbLevel: 0.3 });
}

// --- Writing the files ---

function wavFile({ left, right }) {
  const frames = left.length;
  const file = Buffer.alloc(44 + frames * 4);
  file.write('RIFF', 0);
  file.writeUInt32LE(36 + frames * 4, 4);
  file.write('WAVEfmt ', 8);
  file.writeUInt32LE(16, 16);
  file.writeUInt16LE(1, 20); // Plain PCM.
  file.writeUInt16LE(2, 22); // Stereo.
  file.writeUInt32LE(RATE, 24);
  file.writeUInt32LE(RATE * 4, 28);
  file.writeUInt16LE(4, 32);
  file.writeUInt16LE(16, 34); // 16-bit.
  file.write('data', 36);
  file.writeUInt32LE(frames * 4, 40);
  for (let i = 0; i < frames; i++) {
    // A whisper of random noise ("dither") hides the roughness of rounding to 16 bits.
    for (const [channel, offset] of [[left, 0], [right, 2]]) {
      const value = Math.round(channel[i] * 32767 + (random() - random()));
      file.writeInt16LE(Math.max(-32768, Math.min(32767, value)), 44 + i * 4 + offset);
    }
  }
  return file;
}

async function oggFile({ left, right }) {
  const encoder = await createOggEncoder();
  encoder.configure({ channels: 2, sampleRate: RATE, vbrQuality: OGG_QUALITY });
  const parts = [];
  const chunk = 1 << 16;
  for (let i = 0; i < left.length; i += chunk) {
    parts.push(Buffer.from(encoder.encode([left.subarray(i, i + chunk), right.subarray(i, i + chunk)]))); // Copy: the encoder reuses its buffer.
  }
  parts.push(Buffer.from(encoder.finalize()));
  return Buffer.concat(parts);
}

// Loudness the way broadcasters measure it (LUFS, from the ITU BS.1770 standard): weight the
// sound the way ears hear it, then average the loudness over the parts that aren't near-silent.
function loudness({ left, right }) {
  const weighted = [left, right].map((channel) => {
    let out = biquad(channel, highShelf(1681.97, 3.9998, 0.7072));
    out = biquad(out, highPass(38.135, 0.5003));
    return out;
  });
  const block = Math.round(0.4 * RATE);
  const step = Math.round(0.1 * RATE);
  const blocks = [];
  for (let start = 0; start + block <= left.length; start += step) {
    let sum = 0;
    for (const channel of weighted) for (let i = start; i < start + block; i++) sum += channel[i] ** 2;
    blocks.push(sum / block);
  }
  const level = (power) => -0.691 + 10 * Math.log10(power);
  const audible = blocks.filter((power) => level(power) > -70);
  const average = (list) => list.reduce((a, b) => a + b, 0) / list.length;
  const relativeGate = level(average(audible)) - 10;
  return level(average(audible.filter((power) => level(power) > relativeGate)));
}

function highShelf(frequencyHz, gainDb, q) {
  const a = 10 ** (gainDb / 40);
  const w = (2 * Math.PI * frequencyHz) / RATE;
  const alpha = Math.sin(w) / (2 * q);
  const cos = Math.cos(w);
  const root = 2 * Math.sqrt(a) * alpha;
  return {
    b: [a * (a + 1 + (a - 1) * cos + root), -2 * a * (a - 1 + (a + 1) * cos), a * (a + 1 + (a - 1) * cos - root)],
    a: [a + 1 - (a - 1) * cos + root, 2 * (a - 1 - (a + 1) * cos), a + 1 - (a - 1) * cos - root],
  };
}

function highPass(frequencyHz, q) {
  const w = (2 * Math.PI * frequencyHz) / RATE;
  const alpha = Math.sin(w) / (2 * q);
  const cos = Math.cos(w);
  return { b: [(1 + cos) / 2, -(1 + cos), (1 + cos) / 2], a: [1 + alpha, -2 * cos, 1 - alpha] };
}

function biquad(input, { b, a }) {
  const out = new Float32Array(input.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < input.length; i++) {
    const y = (b[0] * input[i] + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2) / a[0];
    x2 = x1;
    x1 = input[i];
    y2 = y1;
    y1 = out[i] = y;
  }
  return out;
}

mkdirSync(OUTPUT_DIR, { recursive: true });
const loopSeconds = LOOP_SAMPLES / RATE;
const loudnessOf = {}; // The game uses these to play every track at the same, moderate loudness.
console.log(`Making ${BARS} bars of ${BEATS_PER_BAR}/4 at ${BPM} BPM: a ${loopSeconds.toFixed(2)} second loop.`);
for (const [name, make] of [['forest-theme', forestTheme], ['forest-theme-8bit', chiptuneTheme], ['forest-danger', dangerLayer]]) {
  const started = Date.now();
  const music = make();
  const wav = wavFile(music);
  const ogg = await oggFile(music);
  writeFileSync(join(OUTPUT_DIR, `${name}.wav`), wav);
  writeFileSync(join(OUTPUT_DIR, `${name}.ogg`), ogg);
  loudnessOf[name] = Math.round(loudness(music) * 10) / 10;
  console.log(
    `  ${name}: loudness ${loudnessOf[name]} LUFS, peak ${PEAK_DB} dBFS, ` +
      `WAV ${(wav.length / 1e6).toFixed(1)} MB, OGG ${(ogg.length / 1e6).toFixed(2)} MB (${((Date.now() - started) / 1000).toFixed(1)}s)`,
  );
}
writeFileSync(
  join(OUTPUT_DIR, 'music.json'),
  `${JSON.stringify({ bpm: BPM, beatsPerBar: BEATS_PER_BAR, bars: BARS, sampleRate: RATE, loopSeconds, loudness: loudnessOf }, null, 2)}\n`,
);
console.log(`Wrote them to ${OUTPUT_DIR}`);
