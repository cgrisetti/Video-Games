import { ignoreHeldJump, isUsingController, controlSettings, setControlSetting } from './input.js';
import { musicSettings, setMusicVolume, setMusicMuted, setMusicStyle, setMusicPaused } from './music.js';
import { soundSettings, setSoundVolume, playPop } from './sounds.js';
import { graphicsSettings, setPainted } from './painterly.js';

// The menu: a start screen when the page opens, and the pause menu during play, with pages for
// Settings and How to play. What's in it depends on where you are: in a game like Berry Rush you
// can restart the round or return to the woods; in the woods you can quit to the game list.
// It works the way console game menus do:
//   - Esc or P (keyboard), Options (controller) or the pause button opens and closes it.
//   - Up and down choose a row, left and right change a setting, Enter or ✕ picks, Esc or ○ goes back.
//   - The mouse works too: point at a row to choose it, click to pick it.
//   - The game pauses by itself if you switch to another window or your controller comes unplugged.
// While it's open the world stands still, and the music goes quiet and muffled.

const TOAST_SECONDS = 1.6;
const VOLUME_STEP = 0.05;
const STYLES = [
  ['forest', 'Forest'],
  ['8bit', '8-bit'],
];

const menu = document.getElementById('menu');
const title = document.getElementById('menu-title');
const notice = document.getElementById('menu-notice');
const prompts = document.getElementById('menu-prompts');
const pages = [...menu.querySelectorAll('.menu-page')];
const resumeButton = menu.querySelector('[data-action="resume"]');
const musicToggle = document.getElementById('music-toggle');
const volumeSlider = document.getElementById('music-volume');
const volumeValue = document.getElementById('music-volume-value');
const styleChoice = document.getElementById('music-style');
const paintedToggle = document.getElementById('painted-toggle');
const invertX = document.getElementById('invert-x');
const invertY = document.getElementById('invert-y');
const soundSlider = document.getElementById('sound-volume');
const soundValue = document.getElementById('sound-volume-value');
const pauseButton = document.getElementById('pause-button');
const pauseKey = document.getElementById('pause-key');
const toast = document.getElementById('toast');

let isOpen = false;
let starting = true; // The start screen, before the first round: "Play" instead of "Resume".
let page = 'main';
let actions = {};
let toastTimer = null;
let shownController = false; // Whether the button hints show the controller's buttons.
let chosen = null; // The button or slider on the chosen row.

// The game tells the menu what its buttons do:
//   restart(), returnToWoods(), roundInProgress() (leaving would lose a round), canPause() (pausing
//   by itself makes sense now), busy() (between areas: no menu), dismiss() (put away whatever the
//   area has open, like a game card; true if there was something), started() (the first Play).
export function initMenu(gameActions) {
  actions = gameActions;
  showSettings();
  openMenu({ start: true });
}

export function isPaused() {
  return isOpen;
}

export function openMenu({ start = false, message = '' } = {}) {
  starting = start;
  isOpen = true;
  menu.hidden = false;
  pauseButton.hidden = true;
  title.textContent = start ? 'Lanternwood' : 'Paused';
  title.classList.toggle('brand', start);
  resumeButton.textContent = start ? 'Play' : 'Resume';
  // (toggleAttribute, not .hidden, so it works on the pictures too: they're SVG, not HTML.)
  for (const element of menu.querySelectorAll('[data-start-only]')) element.toggleAttribute('hidden', !start);
  for (const element of menu.querySelectorAll('[data-pause-only]')) element.toggleAttribute('hidden', start);
  showNotice(message);
  setMusicPaused(true);
  showPage('main');
}

export function closeMenu() {
  const wasStarting = starting;
  isOpen = false;
  starting = false;
  menu.hidden = true;
  pauseButton.hidden = false;
  document.activeElement?.blur(); // Hand the keyboard back to the game.
  ignoreHeldJump();
  setMusicPaused(false);
  if (wasStarting) actions.started?.();
}

function showPage(name) {
  const from = page;
  page = name;
  for (const element of pages) element.hidden = element.dataset.page !== name;
  showPrompts();
  // Coming back to the main page, land on the row that led away from it.
  const back = name === 'main' ? menu.querySelector(`[data-open="${from}"]`) : null;
  choose(back ?? rows()[0]);
}

// Choose a row: give it the keyboard focus, and the golden glow. (The glow is set here rather than
// left to the browser's focus styling, which disappears whenever the window isn't the one in front.)
function choose(control) {
  if (!control) return;
  chosen = control;
  if (document.activeElement !== control) control.focus({ preventScroll: true });
  const row = control.closest('.setting') ?? control;
  for (const old of menu.querySelectorAll('.chosen')) if (old !== row) old.classList.remove('chosen');
  row.classList.add('chosen');
}

function goBack() {
  if (page !== 'main') showPage('main');
  else closeMenu();
}

function showNotice(message) {
  notice.textContent = message;
  notice.hidden = !message;
}

// The rows you can move between on this page: buttons and sliders.
function rows() {
  const current = pages.find((element) => element.dataset.page === page);
  return [...current.querySelectorAll('button, input')].filter((element) => element.offsetParent !== null);
}

// Move up or down a row, wrapping round from the bottom to the top.
function moveFocus(step) {
  const list = rows();
  const at = list.indexOf(chosen);
  choose(list[at === -1 ? 0 : (at + step + list.length) % list.length]);
}

// Left or right on a setting changes it.
function adjust(step) {
  const row = chosen;
  if (row === volumeSlider) {
    setMusicVolume(musicSettings.volume + step * VOLUME_STEP);
  } else if (row === soundSlider) {
    setSoundVolume(soundSettings.volume + step * VOLUME_STEP);
    playPop(1); // A sample, so you can hear how loud the effects are now.
  } else if (row === musicToggle) {
    setMusicMuted(!musicSettings.muted);
  } else if (row === paintedToggle) {
    setPainted(!graphicsSettings.painted);
  } else if (row === invertX || row === invertY) {
    const name = row === invertX ? 'invertX' : 'invertY';
    setControlSetting(name, !controlSettings[name]);
  } else if (row === styleChoice) {
    const at = STYLES.findIndex(([style]) => style === musicSettings.style);
    setMusicStyle(STYLES[(at + step + STYLES.length) % STYLES.length][0]);
  } else {
    return false;
  }
  showSettings();
  return true;
}

function showSettings() {
  musicToggle.querySelector('.value').textContent = musicSettings.muted ? 'Off' : 'On';
  musicToggle.setAttribute('aria-checked', String(!musicSettings.muted));
  volumeSlider.value = Math.round(musicSettings.volume * 100);
  volumeValue.textContent = `${volumeSlider.value}%`;
  soundSlider.value = Math.round(soundSettings.volume * 100);
  soundValue.textContent = `${soundSlider.value}%`;
  styleChoice.querySelector('.value').textContent = STYLES.find(([style]) => style === musicSettings.style)?.[1] ?? 'Forest';
  for (const [button, on] of [[paintedToggle, graphicsSettings.painted], [invertX, controlSettings.invertX], [invertY, controlSettings.invertY]]) {
    button.querySelector('.value').textContent = on ? 'On' : 'Off';
    button.setAttribute('aria-checked', String(on));
  }
}

// The button hints along the bottom of the menu, and on the pause button, for whichever you're using.
function showPrompts() {
  const close = starting ? 'Play' : 'Resume';
  prompts.innerHTML = shownController
    ? `<span><kbd>✕</kbd> Select</span><span><kbd>○</kbd> Back</span><span><kbd>Options</kbd> ${close}</span>`
    : `<span><kbd>↑</kbd><kbd>↓</kbd> Choose</span><span><kbd>Enter</kbd> Select</span><span><kbd>Esc</kbd> Back</span>`;
  pauseKey.textContent = shownController ? 'Options' : 'Esc';
}

// Switch the button hints between the keyboard's and the controller's, whichever was used last.
// The game calls this every frame; it only redraws when something changed.
export function updateButtonHints() {
  if (isUsingController() === shownController) return;
  shownController = isUsingController();
  showPrompts();
}

export function showToast(text) {
  toast.textContent = text;
  toast.classList.add('showing');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('showing'), TOAST_SECONDS * 1000);
}

// The game calls this every frame while the menu is open, with the controller's buttons.
export function menuInput(controls) {
  if (controls.menuY) moveFocus(controls.menuY);
  if (controls.menuX) adjust(controls.menuX);
  if (controls.confirm) {
    if (!rows().includes(chosen)) choose(rows()[0]);
    else if (chosen.type !== 'range') chosen.click();
  }
  if (controls.back) goBack();
  if (controls.pause) closeMenu();
}

// --- Clicks, keys and pointing ---

menu.addEventListener('click', (event) => {
  const button = event.target.closest('button');
  if (!button) {
    // A click anywhere along a setting's row changes it, not just on its value.
    const row = event.target.closest('div.setting');
    if (row) row.querySelector('button').click();
    return;
  }
  if (button.dataset.open) showPage(button.dataset.open);
  const action = button.dataset.action;
  if (action === 'resume') closeMenu();
  if (action === 'back') goBack();
  if (action === 'restart') {
    actions.restart();
    closeMenu();
  }
  // Leaving a game mid-round asks first, since the round would be lost.
  if (action === 'return' && actions.roundInProgress()) showPage('leave');
  else if (action === 'return' || action === 'leave') {
    closeMenu();
    actions.returnToWoods();
  }
  if (action === 'quit') location.href = '../../';
  if ([musicToggle, styleChoice, paintedToggle, invertX, invertY].includes(button)) {
    choose(button); // (A tap doesn't point at the row first, the way a mouse does.)
    adjust(1);
  }
});

volumeSlider.addEventListener('input', () => {
  setMusicVolume(volumeSlider.value / 100);
  showSettings();
});
soundSlider.addEventListener('input', () => {
  setSoundVolume(soundSlider.value / 100);
  showSettings();
});
soundSlider.addEventListener('change', () => playPop(1));

// Pointing at a row chooses it, so the mouse and the keyboard never disagree about which one is chosen.
menu.addEventListener('pointermove', (event) => {
  const row = event.target.closest('.menu-list > button, .setting');
  const target = row?.matches('.setting') ? row.querySelector('button, input') : row;
  if (target && chosen !== target && !(event.buttons && chosen?.type === 'range')) choose(target);
});

pauseButton.addEventListener('click', () => openMenu());
// Tabbing through the menu chooses rows too.
menu.addEventListener('focusin', (event) => {
  if (event.target !== chosen && event.target.matches('button, input')) choose(event.target);
});

window.addEventListener('keydown', (event) => {
  const typing = event.target instanceof HTMLInputElement && event.target.type === 'text';
  if (typing || event.repeat) return;
  if (event.code === 'KeyM') {
    setMusicMuted(!musicSettings.muted);
    showSettings();
    showToast(musicSettings.muted ? 'Music off' : 'Music on');
    return;
  }
  if (event.code === 'Escape' || event.code === 'KeyP') {
    event.preventDefault();
    if (isOpen) goBack();
    else if (!actions.busy() && !actions.dismiss()) openMenu();
    return;
  }
  if (!isOpen) return;
  if (event.code === 'ArrowUp' || event.code === 'ArrowDown') {
    event.preventDefault();
    moveFocus(event.code === 'ArrowUp' ? -1 : 1);
  } else if (event.code === 'ArrowLeft' || event.code === 'ArrowRight') {
    event.preventDefault();
    adjust(event.code === 'ArrowLeft' ? -1 : 1);
  }
});

// Pause by yourself when the player looks away: another window, another tab, or an unplugged controller.
function autoPause(message = '') {
  if (!isOpen && !actions.busy() && actions.canPause()) openMenu({ message });
  else if (isOpen && message) showNotice(message);
}
window.addEventListener('blur', () => autoPause());
document.addEventListener('visibilitychange', () => document.hidden && autoPause());
window.addEventListener('gamepaddisconnected', () => {
  autoPause('Your controller came unplugged. Plug it back in, or carry on with the keyboard.');
});
window.addEventListener('gamepadconnected', () => {
  showToast('Controller connected');
  if (isOpen) showNotice('');
});
