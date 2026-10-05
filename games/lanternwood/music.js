// Background music. The forest theme loops quietly under everything, and a darker "danger" layer,
// made to line up with it exactly, fades in as an inch worm gets close. There's an 8-bit version
// of the theme too. The music files are made by tools/audio/make-music.mjs (npm run music).
// The Settings menu (menu.js) changes the volume, turns it on or off, and picks the version.

import { loadSaved, save } from './saved.js';

const TARGET_LOUDNESS = -18; // How loud the music plays at full volume (LUFS), so it sits under the action.
const DANGER_LOUDEST = 0.9; // The danger layer at its strongest, compared with the theme.
const THEME_DIP = 0.3; // How much the theme steps back while the danger layer is in.
const FADE_SECONDS = 0.6; // How quickly the danger layer swells and fades.
const PAUSED_LEVEL = 0.6; // While the game is paused, the music is a little quieter...
const PAUSED_MUFFLE = 700; // ...and muffled, as if through a door (the highest pitch let through, in Hz).

const format = new Audio().canPlayType('audio/ogg; codecs="vorbis"') ? 'ogg' : 'wav';
const context = new AudioContext();
export { context as audioContext }; // The sound effects (sounds.js) play through it too.
const master = context.createGain(); // The volume setting.
const muffle = context.createBiquadFilter();
const themeGain = context.createGain();
const dangerGain = context.createGain();
muffle.type = 'lowpass';
muffle.frequency.value = 20000;
themeGain.connect(master);
dangerGain.connect(master);
master.connect(muffle);
muffle.connect(context.destination);
dangerGain.gain.value = 0;

// What the player picked: { volume: 0-1, muted, style: 'forest' or '8bit' }. Change it through the functions below.
export const musicSettings = loadSettings();
let tracks = {}; // Decoded music, and how much to turn each one down to reach TARGET_LOUDNESS.
let loopSeconds = 0;
let startedAt = null; // When the loops started playing, on the audio clock.
let themeSource = null;
let themeLevel = 1;
let dangerLevel = 1;
let lastDanger = 0;
let paused = false;

applyVolume();
loadMusic();

// Browsers only let a page make sound after you click or press a key on it.
for (const event of ['pointerdown', 'keydown']) {
  window.addEventListener(event, () => context.resume().then(startIfReady));
}

async function loadMusic() {
  try {
    const info = await fetch('audio/music.json').then((response) => response.json());
    loopSeconds = info.loopSeconds;
    const load = async (name) => {
      const data = await fetch(`audio/${name}.${format}`).then((response) => response.arrayBuffer());
      return { buffer: await context.decodeAudioData(data), level: 10 ** ((TARGET_LOUDNESS - info.loudness[name]) / 20) };
    };
    const [forest, chiptune, danger] = await Promise.allSettled(['forest-theme', 'forest-theme-8bit', 'forest-danger'].map(load));
    // If one version of the theme won't load, fall back to the other.
    tracks = {
      forest: forest.value ?? chiptune.value,
      '8bit': chiptune.value ?? forest.value,
      danger: danger.value,
    };
    startIfReady();
  } catch (error) {
    console.warn('The music could not be loaded.', error);
  }
}

// Start both loops together, once the music has loaded and the browser allows sound.
function startIfReady() {
  if (startedAt !== null || context.state !== 'running' || !tracks.forest) return;
  startedAt = context.currentTime + 0.05;
  themeSource = playLoop(tracks[musicSettings.style], themeGain, startedAt, 0);
  themeLevel = tracks[musicSettings.style].level;
  themeGain.gain.value = themeLevel;
  if (tracks.danger) {
    playLoop(tracks.danger, dangerGain, startedAt, 0);
    dangerLevel = tracks.danger.level;
  }
}

function playLoop({ buffer }, destination, when, offset) {
  const source = context.createBufferSource();
  source.buffer = buffer;
  source.loop = true;
  source.loopEnd = Math.min(loopSeconds, buffer.duration);
  source.connect(destination);
  source.start(when, offset);
  return source;
}

// Fade the danger layer in (1) or out (0). The game calls this every frame.
export function setDanger(amount) {
  // Skip tiny changes, so the fade isn't re-planned every frame (but always settle fully in or out).
  const settles = (amount === 0 || amount === 1) && amount !== lastDanger;
  if (Math.abs(amount - lastDanger) < 0.02 && !settles) return;
  lastDanger = amount;
  const now = context.currentTime;
  dangerGain.gain.setTargetAtTime(amount * DANGER_LOUDEST * dangerLevel, now, FADE_SECONDS / 3);
  themeGain.gain.setTargetAtTime((1 - THEME_DIP * amount) * themeLevel, now, FADE_SECONDS / 3);
}

// Switch between the forest theme ('forest') and the 8-bit version ('8bit'), picking up at the same spot in the tune.
export function setMusicStyle(style) {
  musicSettings.style = style;
  saveSettings();
  if (startedAt === null || !tracks[style]) return;
  const offset = (((context.currentTime - startedAt) % loopSeconds) + loopSeconds) % loopSeconds;
  themeSource.stop();
  themeSource = playLoop(tracks[style], themeGain, context.currentTime, offset);
  themeLevel = tracks[style].level;
  themeGain.gain.setTargetAtTime((1 - THEME_DIP * lastDanger) * themeLevel, context.currentTime, 0.05);
}

// 0 (silent) to 1 (full). Moving the volume also turns the music back on.
export function setMusicVolume(volume) {
  musicSettings.volume = Math.min(Math.max(volume, 0), 1);
  musicSettings.muted = false;
  applyVolume();
  saveSettings();
}

export function setMusicMuted(muted) {
  musicSettings.muted = muted;
  applyVolume();
  saveSettings();
}

// Muffle the music while the game is paused, and open it back up when play starts again.
export function setMusicPaused(isPaused) {
  paused = isPaused;
  muffle.frequency.setTargetAtTime(paused ? PAUSED_MUFFLE : 20000, context.currentTime, 0.12);
  applyVolume();
}

function applyVolume() {
  const volume = musicSettings.muted ? 0 : musicSettings.volume * (paused ? PAUSED_LEVEL : 1);
  master.gain.setTargetAtTime(volume, context.currentTime, 0.05);
}

function loadSettings() {
  return { volume: 0.7, muted: false, style: 'forest', ...loadSaved('music') };
}

function saveSettings() {
  save('music', musicSettings);
}
