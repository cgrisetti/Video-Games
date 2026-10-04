// Background music. The forest theme loops quietly under everything, and a darker "danger" layer,
// made to line up with it exactly, fades in as an inch worm gets close. There's an 8-bit version
// of the theme too. The music files are made by tools/audio/make-music.mjs (npm run music).

const TARGET_LOUDNESS = -18; // How loud the music plays at full volume (LUFS), so it sits under the action.
const DANGER_LOUDEST = 0.9; // The danger layer at its strongest, compared with the theme.
const THEME_DIP = 0.3; // How much the theme steps back while the danger layer is in.
const FADE_SECONDS = 0.6; // How quickly the danger layer swells and fades.
const STORAGE_KEY = 'coin-hop-music';

const volumeSlider = document.getElementById('music-volume');
const muteButton = document.getElementById('music-mute');
const styleButton = document.getElementById('music-style');

const format = new Audio().canPlayType('audio/ogg; codecs="vorbis"') ? 'ogg' : 'wav';
const context = new AudioContext();
const master = context.createGain(); // The volume setting.
const themeGain = context.createGain();
const dangerGain = context.createGain();
master.connect(context.destination);
themeGain.connect(master);
dangerGain.connect(master);
dangerGain.gain.value = 0;

const settings = loadSettings(); // { volume: 0-1, muted, style: 'forest' or '8bit' }
let tracks = {}; // Decoded music, and how much to turn each one down to reach TARGET_LOUDNESS.
let loopSeconds = 0;
let startedAt = null; // When the loops started playing, on the audio clock.
let themeSource = null;
let themeLevel = 1;
let dangerLevel = 1;
let lastDanger = 0;

showSettings();
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
  themeSource = playLoop(tracks[settings.style], themeGain, startedAt, 0);
  themeLevel = tracks[settings.style].level;
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

// Switch between the forest theme and the 8-bit version, picking up at the same spot in the tune.
function setStyle(style) {
  settings.style = style;
  saveSettings();
  showSettings();
  if (startedAt === null || !tracks[style]) return;
  const offset = (((context.currentTime - startedAt) % loopSeconds) + loopSeconds) % loopSeconds;
  themeSource.stop();
  themeSource = playLoop(tracks[style], themeGain, context.currentTime, offset);
  themeLevel = tracks[style].level;
  themeGain.gain.setTargetAtTime((1 - THEME_DIP * lastDanger) * themeLevel, context.currentTime, 0.05);
}

function applyVolume() {
  master.gain.setTargetAtTime(settings.muted ? 0 : settings.volume, context.currentTime, 0.05);
}

// --- The little music panel: on/off, volume and style ---

function showSettings() {
  volumeSlider.value = Math.round(settings.volume * 100);
  muteButton.textContent = settings.muted ? '🔇' : '♪';
  muteButton.setAttribute('aria-pressed', String(!settings.muted));
  styleButton.textContent = settings.style === '8bit' ? '8-bit' : 'Forest';
}

volumeSlider.addEventListener('input', () => {
  settings.volume = volumeSlider.value / 100;
  settings.muted = false;
  applyVolume();
  showSettings();
  saveSettings();
});
// Hand the keyboard straight back to the game, so the arrow keys move the gnome, not the slider.
volumeSlider.addEventListener('change', () => volumeSlider.blur());
volumeSlider.addEventListener('pointerup', () => volumeSlider.blur());

muteButton.addEventListener('click', () => {
  toggleMute();
  muteButton.blur();
});
styleButton.addEventListener('click', () => {
  setStyle(settings.style === '8bit' ? 'forest' : '8bit');
  styleButton.blur();
});
window.addEventListener('keydown', (event) => {
  if (event.code === 'KeyM' && !event.repeat && !(event.target instanceof HTMLInputElement && event.target.type === 'text')) toggleMute();
});

function toggleMute() {
  settings.muted = !settings.muted;
  applyVolume();
  showSettings();
  saveSettings();
}

function loadSettings() {
  const defaults = { volume: 0.7, muted: false, style: 'forest' };
  try {
    return { ...defaults, ...JSON.parse(localStorage.getItem(STORAGE_KEY)) };
  } catch {
    return defaults;
  }
}

function saveSettings() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
  } catch {
    // Some private browsing modes block saving. The settings still work until the page closes.
  }
}
