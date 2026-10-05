import { audioContext as context } from './music.js';
import { loadSaved, save } from './saved.js';

// Sound effects, made on the spot from simple tones and bursts of noise (no sound files):
//   - the stick: a woody whoosh as it swings, and a "tok" with a soft thud and a springy boing
//     when it bonks an inch worm on the head;
//   - a raspberry: a juicy pop and a little chime that climbs higher with every berry you pick,
//     on the notes of the music's key (D major), with a sparkling run for the golden one;
//   - an inch worm catching the gnome: chomp, chomp, gulp.
// And for Gnome Crossing:
//   - a hop: a soft little "hup" and a brush of grass;
//   - falling in the creek: a plop, a gush of water and a few drips;
//   - being bowled over by a deer, boar or hedgehog: a thump, a tumble and a dizzy "whee";
//   - the owl: two soft hoots and a few beats of its wings;
//   - the golden glow saving you: the golden raspberry's run, quickly, with a shimmer;
//   - a little bell on a post, ringing before a herd of deer comes running down a trail.
// They all pass through a little "forest" echo so they sit in the same place as the music.

const LEVEL = 0.6; // How loud the effects are at full volume, to sit nicely with the music.
const ROOM_SECONDS = 1.1; // How long the forest echo rings on.
const ROOM_LEVEL = 0.16; // How much of the echo you hear.

// The chime for each berry: up the D major pentatonic scale (D E F# A B), one note per berry.
const BERRY_NOTES = [587.33, 659.25, 739.99, 880, 987.77, 1174.66, 1318.51, 1479.98, 1760];
// The golden raspberry's run: D, F#, G# (the music's magic Lydian note), A and high D.
const GOLDEN_RUN = [1174.66, 1479.98, 1661.22, 1760, 2349.32];

export const soundSettings = { volume: 0.8, ...loadSaved('sounds') }; // { volume: 0-1 }

const output = context.createGain();
const bus = context.createGain(); // Every sound goes in here...
const room = context.createConvolver(); // ...and splits between straight out and the echo.
const roomLevel = context.createGain();
output.gain.value = soundSettings.volume * LEVEL;
roomLevel.gain.value = ROOM_LEVEL;
room.buffer = makeRoom();
bus.connect(output);
bus.connect(room);
room.connect(roomLevel);
roomLevel.connect(output);
output.connect(context.destination);
const noise = makeNoise();

// --- The sounds ---

// The stick swishing through the air: a rush of air that rises and falls in pitch.
export function playSwing() {
  if (!ready()) return;
  hiss({ type: 'bandpass', q: 1.4, sweep: [600, 2400, 800], attack: 0.12, decay: 0.2, gain: 0.7, pan: 0.15 });
}

// The stick bonking an inch worm on the head. `pan` is -1 (left of the screen) to 1 (right).
export function playBonk(pan = 0) {
  if (!ready()) return;
  tone({ from: 900, to: 600, glide: 0.03, decay: 0.06, gain: 0.35, pan }); // Tok! The wood.
  hiss({ type: 'bandpass', q: 3, sweep: [2200], decay: 0.035, gain: 0.4, pan });
  tone({ from: 180, to: 80, glide: 0.12, decay: 0.14, gain: 0.55, pan }); // The thud of a soft head.
  tone({ from: 330, to: 250, glide: 0.35, attack: 0.01, decay: 0.4, gain: 0.16, at: 0.03, wobble: [22, 30], pan }); // Boing.
}

// A raspberry popping: a quick "plop" that jumps up in pitch, a little squish of juice, and a
// chime. `number` is which berry this is (1 to 10); the tenth is the golden one.
export function playPop(number, golden = false) {
  if (!ready()) return;
  tone({ from: 300, to: 950, glide: 0.035, attack: 0.003, decay: 0.07, gain: golden ? 0.7 : 0.6 });
  hiss({ type: 'bandpass', q: 0.8, sweep: [1300, 700], decay: 0.06, gain: 0.18, at: 0.01 });
  if (golden) {
    GOLDEN_RUN.forEach((note, i) => chime(note, i * 0.07, 0.22));
    hiss({ type: 'highpass', q: 0.7, sweep: [5000], attack: 0.05, decay: 0.6, gain: 0.08, at: 0.05 }); // Sparkle.
  } else {
    chime(BERRY_NOTES[Math.min(number, BERRY_NOTES.length) - 1], 0.02, 0.2);
  }
}

// An inch worm catching the gnome: two hungry chomps, then a gulp.
export function playChomp(pan = 0) {
  if (!ready()) return;
  for (const at of [0, 0.24]) {
    hiss({ type: 'highpass', q: 0.7, sweep: [3000], decay: 0.012, gain: 0.25, at, pan }); // Teeth.
    hiss({ type: 'bandpass', q: 2, sweep: [900, 600], attack: 0.004, decay: 0.09, gain: 0.5, at, pan }); // Crunch.
    tone({ from: 160, to: 70, glide: 0.1, decay: 0.11, gain: 0.55, at, pan }); // The jaws closing.
  }
  tone({ from: 520, to: 150, glide: 0.2, attack: 0.02, decay: 0.24, gain: 0.4, at: 0.55, pan }); // Gulp.
  tone({ from: 260, to: 75, glide: 0.2, attack: 0.02, decay: 0.24, gain: 0.3, at: 0.55, pan });
}

// A hop: soft enough to hear over and over without minding.
export function playHop() {
  if (!ready()) return;
  tone({ from: 240, to: 420, glide: 0.05, attack: 0.004, decay: 0.07, gain: 0.12 });
  hiss({ type: 'bandpass', q: 1.2, sweep: [2600, 1800], decay: 0.04, gain: 0.05 });
}

// Falling in the creek: a deep plop, a gush of water settling, and a few drips.
export function playSplash(pan = 0) {
  if (!ready()) return;
  tone({ from: 520, to: 110, glide: 0.16, attack: 0.004, decay: 0.2, gain: 0.45, pan });
  hiss({ type: 'lowpass', q: 0.8, sweep: [2600, 1400, 350], attack: 0.01, decay: 0.55, gain: 0.55, pan });
  hiss({ type: 'highpass', q: 0.7, sweep: [4000], attack: 0.005, decay: 0.12, gain: 0.12, at: 0.02, pan });
  for (const [at, note] of [[0.28, 1480], [0.4, 1975], [0.55, 1318]]) {
    tone({ from: note, to: note * 1.4, glide: 0.03, attack: 0.002, decay: 0.05, gain: 0.09, at, pan });
  }
}

// Bowled over: a soft thump, a tumble through the grass, and a dizzy little "whee" that slides down.
export function playTumble(pan = 0) {
  if (!ready()) return;
  tone({ from: 170, to: 60, glide: 0.12, decay: 0.16, gain: 0.6, pan });
  hiss({ type: 'bandpass', q: 1.5, sweep: [900, 500], attack: 0.004, decay: 0.12, gain: 0.35, pan });
  hiss({ type: 'bandpass', q: 1, sweep: [1800, 700], attack: 0.02, decay: 0.3, gain: 0.18, at: 0.1, pan });
  tone({ from: 1100, to: 380, glide: 0.45, attack: 0.02, decay: 0.45, gain: 0.14, at: 0.16, wobble: [9, 40], pan });
}

// The owl: a few beats of its big soft wings, then "hoo... hoooo". Without `wings`, just the
// hoots, as a warning from somewhere out in the dark.
export function playHoot(pan = 0, { wings = true } = {}) {
  if (!ready()) return;
  const start = wings ? 0.6 : 0;
  if (wings) {
    for (const at of [0, 0.22, 0.44]) hiss({ type: 'bandpass', q: 0.9, sweep: [380, 900, 420], attack: 0.06, decay: 0.12, gain: 0.3, at, pan });
  }
  const gain = wings ? 1 : 0.6; // Further off when it's only a warning.
  tone({ from: 410, to: 380, glide: 0.25, attack: 0.05, decay: 0.3, gain: 0.32 * gain, at: start, wobble: [5, 6], pan });
  tone({ from: 400, to: 330, glide: 0.6, attack: 0.07, decay: 0.65, gain: 0.34 * gain, at: start + 0.4, wobble: [5, 6], pan });
}

// The golden glow saving the gnome: the golden raspberry's run, quick, twice, with a shimmer.
export function playGoldenSave() {
  if (!ready()) return;
  GOLDEN_RUN.forEach((note, i) => chime(note, i * 0.045, 0.18));
  GOLDEN_RUN.forEach((note, i) => chime(note * 2, 0.25 + i * 0.045, 0.1));
  hiss({ type: 'highpass', q: 0.7, sweep: [6000], attack: 0.08, decay: 0.7, gain: 0.1 });
}

// A little brass bell on a post: ding, ding. Bells ring with an odd, clangy overtone (2.76 times the note).
export function playBell(pan = 0) {
  if (!ready()) return;
  for (const at of [0, 0.28]) {
    tone({ from: 1568, decay: 0.5, gain: 0.16, at, attack: 0.002, pan });
    tone({ from: 1568 * 2.76, decay: 0.25, gain: 0.05, at, attack: 0.002, pan });
  }
}

// 0 (silent) to 1 (full).
export function setSoundVolume(volume) {
  soundSettings.volume = Math.min(Math.max(volume, 0), 1);
  output.gain.setTargetAtTime(soundSettings.volume * LEVEL, context.currentTime, 0.03);
  save('sounds', soundSettings);
}

// --- Building blocks ---

// Sounds only play once the browser allows sound (after a click or key press), and not at all
// when the volume is down, so none pile up and all come out at once later.
function ready() {
  return context.state === 'running' && soundSettings.volume > 0;
}

// A pure tone that slides from one pitch to another, and fades away. `wobble` is [speed, depth]
// in Hz, for a springy vibrato.
function tone({ from, to = from, glide = 0.05, attack = 0.002, decay, gain, at = 0, pan = 0, wobble = null }) {
  const start = context.currentTime + at;
  const oscillator = context.createOscillator();
  oscillator.frequency.setValueAtTime(from, start);
  oscillator.frequency.exponentialRampToValueAtTime(to, start + glide);
  if (wobble) {
    const lfo = context.createOscillator();
    const depth = context.createGain();
    lfo.frequency.value = wobble[0];
    depth.gain.value = wobble[1];
    lfo.connect(depth).connect(oscillator.frequency);
    lfo.start(start);
    lfo.stop(start + attack + decay + 0.05);
  }
  play(oscillator, start, attack, decay, gain, pan);
}

// A burst of noise through a filter whose pitch moves through the `sweep` values, evenly spaced in time.
function hiss({ type, q, sweep, attack = 0.002, decay, gain, at = 0, pan = 0 }) {
  const start = context.currentTime + at;
  const source = context.createBufferSource();
  source.buffer = noise;
  const filter = context.createBiquadFilter();
  filter.type = type;
  filter.Q.value = q;
  filter.frequency.setValueAtTime(sweep[0], start);
  sweep.slice(1).forEach((frequency, i) => {
    filter.frequency.exponentialRampToValueAtTime(frequency, start + ((attack + decay) * (i + 1)) / (sweep.length - 1));
  });
  source.connect(filter);
  play(filter, start, attack, decay, gain, pan, source);
}

// A soft bell: the note and a quieter one an octave up, ringing down.
function chime(frequency, at, gain) {
  tone({ from: frequency, decay: 0.6, gain, at, attack: 0.004 });
  tone({ from: frequency * 2, decay: 0.3, gain: gain * 0.25, at, attack: 0.004 });
}

// Shape a sound's volume (a quick rise, then a fade) and send it out, panned left or right.
function play(node, start, attack, decay, gain, pan, source = node) {
  const envelope = context.createGain();
  envelope.gain.setValueAtTime(0.0001, start);
  envelope.gain.linearRampToValueAtTime(gain, start + attack);
  envelope.gain.exponentialRampToValueAtTime(0.0001, start + attack + decay);
  const panner = context.createStereoPanner();
  panner.pan.value = Math.max(-0.8, Math.min(0.8, pan));
  node.connect(envelope).connect(panner).connect(bus);
  // Noise starts somewhere different in the hiss each time, so no two bursts sound the same.
  if (source.buffer) source.start(start, Math.random());
  else source.start(start);
  source.stop(start + attack + decay + 0.05);
}

// Two seconds of hiss to cut noise bursts from.
function makeNoise() {
  const buffer = context.createBuffer(1, context.sampleRate * 2, context.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
  return buffer;
}

// The forest echo: a short, soft, fading wash of noise, a little different on each side.
function makeRoom() {
  const length = Math.round(context.sampleRate * ROOM_SECONDS);
  const buffer = context.createBuffer(2, length, context.sampleRate);
  for (let channel = 0; channel < 2; channel++) {
    const data = buffer.getChannelData(channel);
    for (let i = 0; i < length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / length) ** 3;
  }
  return buffer;
}
