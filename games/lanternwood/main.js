import * as THREE from 'three';
import { readInput } from './input.js';
import { initMenu, isPaused, openMenu, menuInput, updateButtonHints } from './menu.js';
import { showBanner } from './banner.js';
import { woods } from './woods.js';
import { berryRush } from './berry-rush.js';
import { brambleMaze } from './maze.js';
import { gnomeCrossing } from './gnome-crossing.js';
import { createPainter } from './painterly.js';
import { createAtmosphere } from './atmosphere.js';

// Lanternwood: lantern-lit woods (the Glenn) with games behind the gates along its path.
// This file runs the show. It draws whichever area you're in and hands it the controls each
// frame, and it walks you between areas with a fade to dark and back, the way hub-world games
// do. Each area (woods.js, berry-rush.js, maze.js, gnome-crossing.js) has its own scene, camera
// and gnome, and these parts: update(dt, controls), enter(options), leave(), canPause(), and
// optionally restart(), roundInProgress() and dismiss().

const FADE_SECONDS = 0.45; // Matches the fade in index.html.

const areas = { woods, 'berry-rush': berryRush, 'bramble-maze': brambleMaze, 'gnome-crossing': gnomeCrossing };
let area = woods;
let areaName = 'woods';
let switching = false; // Fading between areas: nothing moves, and the menu stays shut.

// The painter (painterly.js) draws the picture and lays the storybook finish over it.
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
document.body.appendChild(renderer.domElement);
const painter = createPainter(renderer);
painter.setSize(window.innerWidth, window.innerHeight);
// Leaves drifting down and motes of light floating in the air, wherever you are.
const atmosphere = createAtmosphere();
const fade = document.getElementById('fade');

window.addEventListener('resize', () => {
  for (const { camera } of Object.values(areas)) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
  }
  renderer.setSize(window.innerWidth, window.innerHeight);
  painter.setSize(window.innerWidth, window.innerHeight);
});

// Fade out, swap to the area called `name`, and fade back in.
function goTo(name, options = {}) {
  if (switching || areas[name] === area) return;
  switching = true;
  fade.classList.add('dark');
  setTimeout(() => {
    area.leave();
    area = areas[name];
    areaName = name;
    showAreaParts(name);
    area.enter(options);
    fade.classList.remove('dark');
    setTimeout(() => (switching = false), FADE_SECONDS * 1000);
  }, FADE_SECONDS * 1000);
}

// Some parts of the page only belong in some areas: the berry counter in Berry Rush, the clock
// in Berry Rush and the maze, "Quit to game list" in the woods. They're marked in index.html with
// data-area="...", listing the areas they belong in ("game" means any game, not the woods), or
// data-not-area="...", listing the areas they're hidden in.
function showAreaParts(name) {
  document.body.dataset.area = name;
  const isIn = (list) => list.split(' ').some((area) => area === name || (area === 'game' && name !== 'woods'));
  for (const part of document.querySelectorAll('[data-area], [data-not-area]')) {
    const off = (part.dataset.area !== undefined && !isIn(part.dataset.area)) || (part.dataset.notArea !== undefined && isIn(part.dataset.notArea));
    part.classList.toggle('off-area', off);
  }
}

// Going through a gate in the woods.
woods.onPlay = (game) => goTo(game);
// While developing, jump straight to an area from the browser console: lanternwood.goTo('bramble-maze').
if (import.meta.env.DEV) window.lanternwood = { goTo };

let lastTime = null;
renderer.setAnimationLoop((time) => {
  // Cap the step so a hidden tab doesn't make everything jump forward.
  const dt = lastTime === null ? 0 : Math.min((time - lastTime) / 1000, 0.05);
  lastTime = time;
  const controls = readInput();
  updateButtonHints();
  // While the menu is open the world stands still, and the controller works the menu instead.
  if (isPaused()) menuInput(controls);
  else if (switching) {
    // Nothing moves while the screen fades.
  } else if (controls.pause && area.canPause()) openMenu();
  else area.update(dt, controls);
  atmosphere.update(area.scene, area.camera, isPaused() ? 0 : dt);
  painter.render(area.scene, area.camera, isPaused() ? 0 : dt);
});

// Start in the woods, behind the title screen. Pressing Play walks you in.
showAreaParts('woods');
woods.enter({ quiet: true });
initMenu({
  restart: () => area.restart?.(),
  returnToWoods: () => goTo('woods', { from: areaName }), // Back out through the gate you went in by.
  roundInProgress: () => area.roundInProgress?.() ?? false,
  canPause: () => area.canPause(),
  busy: () => switching,
  dismiss: () => area.dismiss?.() ?? false,
  started: () => showBanner('The Glenn', 'Lanternwood'),
});
