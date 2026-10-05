import * as THREE from 'three';
import { createGnome } from './gnome.js';
import { createFox } from './fox.js';
import { shortestTurn } from './walker.js';
import { setDanger } from './music.js';
import { showBanner, setBannerSubtitle, hideBanner } from './banner.js';
import { makeHedgeArch, makeCrossingSign, OPENING } from './gates.js';
import { makeHedgeWalls } from './scenery.js';
import { createEffects } from './effects.js';
import { playSwing, playPop, playHop, playSplash, playTumble, playHoot, playGoldenSave } from './sounds.js';
import { flickerLanterns } from './lantern.js';
import { WATER_LEVEL } from './creek.js';
import { boards, showScoreboard, hideScoreboard, bestScore } from './scoreboard.js';
import { createBackdrop, SKY_COLOR, HAZE_COLOR } from './backdrop.js';
import { makeGoldenRaspberry } from './raspberry.js';
import { makeOwl } from './critters.js';
import { showToast } from './menu.js';
import { createTrail, TILE, COLUMNS, BACK_ROW } from './trail.js';

// Gnome Crossing: Lanternwood's second game, through the hedge archway in the Forest Hallway.
// It's Lanternwood's take on Frogger and Crossy Road: hop up an endless trail one tile at a time,
// across creeks (ride the logs, step on the lily pads; the water's too deep to wade) and animal
// trails (dodge the deer, boars and hedgehog families). Night is falling behind you: dawdle, and
// it catches up, and the owl flies you home to bed. Raspberries along the way add up, and every
// 8th brings out a golden one. Your fox friend runs ahead to point it out, and its golden glow
// saves you from one splash or bump. How far you get goes in the Top 10. (The trail is in trail.js.)

// Tweak these to change how the game feels.
const HOP_TIME = 0.15; // Seconds for one hop.
const HOP_HEIGHT = 0.45;
const TURN_SPEED = 30; // How quickly the gnome turns to face the way it hops.
const READY_TIME = 1.6; // Seconds of "Ready..." before a round starts, when you come in through the arch.
const RESULTS_DELAY = 1.4; // Seconds to see what happened before the Top 10 board comes up.
const HIT_RADIUS = 0.3; // How close an animal has to come to bowl the gnome over.
const SWEPT_AWAY = (COLUMNS + 1.5) * TILE; // Riding a log this far out to the side, the creek carries you off.
const GOLDEN_EVERY = 8; // Every 8th raspberry brings out a golden one, somewhere up ahead...
const GOLDEN_AHEAD = [6, 12]; // ...this many rows ahead of you.
const SAFE_TIME = 1.5; // After the golden glow saves you, nothing can hurt you for this long.

// Night falling behind you. All in rows.
const NIGHT_START = 3.5; // How far behind you it starts.
const NIGHT_LAG = 6; // It's never further behind your farthest hop than this.
const NIGHT_SPEED = [0.33, 0.7]; // Rows a second it creeps forward: at the start, and from row 220 on.
const NIGHT_HARDEST = 220;
const DANGER_FAR = 4; // The danger music creeps in when night is this close behind you...
const DANGER_NEAR = 1; // ...and is at full strength this close.
const HOOT_AT = 1.8; // The owl hoots from the dark when night is this close: a warning.
const HINT_AT = 2.6; // "Keep hopping!" shows when night is this close.
const DUSK = 0.3; // How much the daylight fades as night gets close (0.3 is 30% dimmer).

// The camera: behind and above, looking a little way up the trail, always straight north.
const CAMERA_BACK = 9.5;
const CAMERA_HEIGHT = 8;
const CAMERA_LOOK = new THREE.Vector3(0, -6, -13.5); // Which way it looks.
const CAMERA_FOLLOW_SIDE = 0.5; // How far it slides sideways with the gnome (1 would keep it in the middle).

// The fox trots up the right-hand edge of the trail.
const FOX_X = (COLUMNS + 1) * TILE;
const FOX_SPEED = 11;

const rowZ = (index) => -index * TILE;

const hopsEl = document.getElementById('hops');
const hopsPill = document.getElementById('hops-pill');
const berriesEl = document.getElementById('crossing-berries');
const berryPill = document.getElementById('crossing-berry-pill');
const goldenPill = document.getElementById('golden-pill');
const hintEl = document.getElementById('crossing-hint');
const nightfall = document.getElementById('nightfall');

// --- Scene, camera and lights ---

const scene = new THREE.Scene();
scene.background = new THREE.Color(SKY_COLOR);
scene.fog = new THREE.Fog(HAZE_COLOR, 30, 85); // The far end of the trail fades into the painted hills.
const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 200);

const skyLight = new THREE.HemisphereLight(0xffffff, 0x446644, 1.2);
scene.add(skyLight);
const sun = new THREE.DirectionalLight(0xffffff, 2);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
Object.assign(sun.shadow.camera, { left: -24, right: 24, top: 24, bottom: -24, far: 80 });
scene.add(sun, sun.target); // The sun follows the gnome up the trail, so the shadows always fall nearby.

const backdrop = createBackdrop({ radius: 70 }); // The painted hills travel with you, always far off.
scene.add(backdrop);

// --- The way in ---

// The hedge across the start of the trail, with the archway you came in by, its name facing out
// toward the woods (the same way Berry Rush's gate faces). Pick "Return to Woods" in the menu to go back.
const hedgeZ = rowZ(BACK_ROW - 1);
const hedgeReach = 30;
scene.add(makeHedgeWalls([{ from: [-hedgeReach, hedgeZ], to: [hedgeReach, hedgeZ], gaps: [[hedgeReach - OPENING / 2 - 0.6, hedgeReach + OPENING / 2 + 0.6]] }], 1.2));
const arch = makeHedgeArch('Gnome Crossing', { open: true });
arch.position.z = hedgeZ;
scene.add(arch);
// And a sign by the trail, like the ones by country roads.
const crossingSign = makeCrossingSign();
crossingSign.position.set(-(COLUMNS + 0.9) * TILE, 0, rowZ(1));
crossingSign.rotation.y = 0.35;
scene.add(crossingSign);

// --- Everyone ---

const trail = createTrail(scene);
const effects = createEffects(scene, camera); // Raspberries popping, splashes, dust and golden sparkles.

const gnome = createGnome();
const player = gnome.model;
scene.add(player);
const glow = new THREE.PointLight(0xffd36b, 0, 3.5, 2); // The golden glow, lighting the ground round the gnome.
glow.position.y = 0.7;
player.add(glow);

const fox = createFox();
scene.add(fox.model);
const owl = makeOwl();
owl.model.visible = false;
scene.add(owl.model);
const goldenBerry = makeGoldenRaspberry();
goldenBerry.visible = false;
scene.add(goldenBerry);

// --- Game state ---

// Where the gnome is: its row, how far across (x), its column when it's on a tile (null on a
// log), how high it is, and the log it's riding, if any: { floater, offset from the log's middle }.
const hero = { row: 0, x: 0, col: 0, y: 0, ride: null, facing: Math.PI };
let hop = null; // The hop under way: { from, to, fromRow, toRow, time, landing }.
let queued = null; // A hop pressed while still in the air, to do on landing.
let nudge = 0; // Seconds left of a little bump against something in the way...
let nudgeDir = [0, 0]; // ...and which way.
let landedNow = false;
let farthest = 0; // The score: the farthest row reached.
let berries = 0;
let hasGlow = false; // Picked a golden raspberry, and not used its glow yet.
let safeFor = 0;
let golden = null; // The golden raspberry, while it's out: { index, col }.
let goldenWanted = false; // Due a golden raspberry, but there wasn't room for it yet.
let lastSafe = { row: 0, col: 0 }; // The last meadow tile the gnome stood on, where the golden glow puts it back.
let night = -NIGHT_START; // How far up the trail night has come. Rows below this are dark.
let lead = 0; // The row night follows behind: your farthest, or where the golden glow put you back.
let hooted = false;
let state = 'playing'; // 'playing', or 'over' once something's happened.
let fate = null; // What happened: { kind: 'splash', 'swept', 'tumble' or 'owl', time, story, ... }
let readyIn = 0;
let resultsIn = 0;
let worldTime = 0;
let foxPointing = false;

function restart() {
  effects.clear();
  hideBanner();
  hideScoreboard();
  trail.reset(bestScore(boards['gnome-crossing'])?.score ?? 0);
  Object.assign(hero, { row: 0, x: 0, col: 0, y: 0, ride: null, facing: Math.PI });
  hop = null;
  queued = null;
  nudge = 0;
  farthest = 0;
  berries = 0;
  hasGlow = false;
  safeFor = 0;
  golden = null;
  goldenWanted = false;
  goldenBerry.visible = false;
  lastSafe = { row: 0, col: 0 };
  night = -NIGHT_START;
  lead = 0;
  hooted = false;
  state = 'playing';
  fate = null;
  readyIn = 0;
  resultsIn = 0;
  foxPointing = false;
  player.visible = true;
  player.position.set(0, 0, 0);
  player.rotation.set(0, Math.PI, 0);
  player.scale.setScalar(1);
  owl.model.visible = false;
  fox.model.position.set(FOX_X, 0, 0.8);
  fox.model.rotation.set(0, Math.PI, 0);
  moveCamera(0);
  updateHud();
}

// --- Hopping ---

// The row the gnome counts as being in: during a hop, the one it's left until halfway, then the one it's going to.
function currentRow() {
  if (!hop) return hero.row;
  return hop.time / HOP_TIME < 0.5 ? hop.fromRow : hop.toRow;
}

// Start a hop one tile in direction [x, z] (-z is forward), or bump against whatever's in the way.
function startHop([dx, dz]) {
  hero.facing = Math.atan2(dx, dz);
  const toRow = hero.row - dz;
  const sideways = dx !== 0;
  const lane = trail.row(toRow);
  if (toRow < BACK_ROW || !lane) return bump(dx, dz);
  // A log keeps drifting under you while you hop along it.
  const drift = hero.ride && sideways ? trail.row(hero.row).speed * HOP_TIME : 0;
  let toX;
  let landing;
  if (lane.kind === 'creek' && !lane.pads) {
    // Onto a log: the logs move during the hop, so look where they'll be on landing.
    const aim = hero.x + drift + dx * TILE;
    const found = trail.floaterAt(toRow, aim, HOP_TIME);
    toX = found ? trail.landingSpot(found.floater, found.at, aim) : aim;
    landing = found ? { kind: 'log', floater: found.floater } : { kind: 'water' };
  } else {
    // Onto a tile: grass, the trail or a lily pad. Coming off a log, onto the nearest tile.
    const col = (hero.ride ? Math.round((hero.x + drift) / TILE) : hero.col) + dx;
    if (trail.isBlocked(toRow, col)) return bump(dx, dz);
    toX = col * TILE;
    if (lane.pads) {
      const pad = lane.floaters.find((floater) => floater.col === col);
      landing = pad ? { kind: 'pad', floater: pad, col } : { kind: 'water', col };
    } else {
      landing = { kind: 'ground', col };
    }
  }
  const toY = landing.floater ? landing.floater.top : landing.kind === 'water' ? WATER_LEVEL : 0;
  hop = {
    from: new THREE.Vector3(hero.x, hero.y, rowZ(hero.row)),
    to: new THREE.Vector3(toX, toY, rowZ(toRow)),
    fromRow: hero.row,
    toRow,
    time: 0,
    landing,
  };
  hero.ride = null;
  playHop();
}

// Something's in the way (or it's the edge of the trail): turn to face it and give it a little nudge.
function bump(dx, dz) {
  nudge = 0.14;
  nudgeDir = [dx, dz];
}

function moveHero(dt) {
  if (hop) {
    hop.time += dt;
    const t = Math.min(hop.time / HOP_TIME, 1);
    hero.x = THREE.MathUtils.lerp(hop.from.x, hop.to.x, t);
    hero.y = THREE.MathUtils.lerp(hop.from.y, hop.to.y, t) + Math.sin(Math.PI * t) * HOP_HEIGHT;
    player.position.set(hero.x, hero.y, THREE.MathUtils.lerp(hop.from.z, hop.to.z, t));
    if (t === 1) land();
    return;
  }
  if (hero.ride) {
    hero.x = hero.ride.floater.x + hero.ride.offset;
    hero.y = hero.ride.floater.top + (hero.ride.floater.lift ?? 0);
  }
  player.position.set(hero.x, hero.y, rowZ(hero.row));
}

function land() {
  const { landing, toRow, to } = hop;
  hop = null;
  hero.row = toRow;
  hero.x = to.x;
  hero.y = to.y;
  landedNow = true;
  if (toRow > farthest) {
    farthest = toRow;
    bumpPill(hopsPill);
  }
  lead = Math.max(lead, toRow);
  if (landing.kind === 'water') {
    fall('splash');
    return;
  }
  if (landing.kind === 'log') {
    hero.ride = { floater: landing.floater, offset: hero.x - landing.floater.x };
    hero.col = null;
  } else {
    hero.col = landing.col;
    if (landing.kind === 'pad') landing.floater.dip = 1;
    if (trail.row(toRow).kind === 'meadow') lastSafe = { row: toRow, col: landing.col };
    const berry = trail.takeBerry(toRow, hero.col);
    if (berry) pickBerry(berry);
    if (golden && golden.index === toRow && golden.col === hero.col) pickGolden();
  }
  if (goldenWanted) spawnGolden();
  if (queued) {
    const next = queued;
    queued = null;
    startHop(next);
  }
}

// --- Raspberries and the golden glow ---

function pickBerry(berry) {
  berries++;
  scene.attach(berry); // Out of its row and into the world, so it can pop where it is.
  playPop(((berries - 1) % 9) + 1); // The chime climbs the scale, berry by berry, and starts again.
  effects.popBerry(berry, { number: berries, floor: hero.y, onGone: () => scene.remove(berry) });
  bumpPill(berryPill);
  if (berries % GOLDEN_EVERY === 0 && !hasGlow && !golden) spawnGolden();
}

// The golden raspberry appears a little way up the trail, and the fox runs ahead to point at it.
function spawnGolden() {
  const spot = trail.goldenSpot(hero.row + GOLDEN_AHEAD[0], hero.row + GOLDEN_AHEAD[1]);
  goldenWanted = !spot;
  if (!spot) return;
  golden = spot;
  goldenBerry.position.set(spot.col * TILE, 1, rowZ(spot.index));
  goldenBerry.scale.setScalar(1);
  goldenBerry.visible = true;
  foxPointing = true;
}

function pickGolden() {
  golden = null;
  hasGlow = true;
  berries++;
  foxPointing = false;
  playPop(10, true);
  effects.popBerry(goldenBerry, { number: berries, golden: true, floor: hero.y, onGone: () => (goldenBerry.visible = false) });
  bumpPill(berryPill);
  showToast('A golden glow! It will save you from one splash or bump.');
}

function updateGolden(dt) {
  if (!golden) return;
  goldenBerry.rotation.y += 1.2 * dt;
  goldenBerry.position.y = 1 + Math.sin(worldTime * 2) * 0.12;
  goldenBerry.userData.rays.material.rotation += 0.4 * dt;
  goldenBerry.userData.rays.scale.setScalar(3.4 + Math.sin(worldTime * 3) * 0.25);
  // Hopped right past it: it's gone (and night will soon cover that row anyway).
  if (hero.row > golden.index + 1) {
    golden = null;
    goldenBerry.visible = false;
    foxPointing = false;
  }
}

// Saved by the golden glow: a burst of golden sparkles, and back to the last meadow tile you
// stood on, with a moment when nothing can hurt you. Night is pushed back a little, too.
function goldenSave() {
  hasGlow = false;
  playGoldenSave();
  effects.goldenBurst(player.position.clone().setY(player.position.y + 0.6), Math.max(hero.y, WATER_LEVEL));
  Object.assign(hero, { row: lastSafe.row, col: lastSafe.col, x: lastSafe.col * TILE, y: 0, ride: null });
  hop = null;
  queued = null;
  night = Math.min(night, lastSafe.row - 2.5);
  lead = lastSafe.row;
  safeFor = SAFE_TIME;
  player.position.set(hero.x, 0, rowZ(hero.row));
  effects.goldenBurst(player.position.clone().setY(0.6), 0);
  showToast('The golden glow saved you!');
}

// --- How a round ends ---

const STORIES = {
  splash: 'Splash! Into the creek you went.',
  swept: 'The creek carried you away!',
  deer: 'A deer bowled you over!',
  boar: 'A wild boar knocked you flying!',
  hedgehog: 'You tripped over a hedgehog family!',
  owl: 'Past your bedtime! The owl flew you home.',
};

function fall(kind, animal = null) {
  if (kind !== 'owl' && hasGlow) {
    goldenSave();
    return;
  }
  const lane = trail.row(currentRow());
  state = 'over';
  hop = null;
  queued = null;
  const side = screenSide(player.position);
  fate = { kind, time: 0, story: STORIES[animal?.kind ?? kind], cameraAt: camera.position.clone() };
  resultsIn = RESULTS_DELAY;
  if (kind === 'splash' || kind === 'swept') {
    hero.ride = null;
    effects.splash(player.position, WATER_LEVEL);
    playSplash(side);
  } else if (kind === 'tumble') {
    // Knocked flying the way the animal was running, spinning, to land flat on the ground.
    const dir = Math.sign(lane?.speed || 1);
    fate.velocity = new THREE.Vector3(dir * 3.5, 5.5, 0.8);
    fate.dir = dir;
    effects.dust(player.position.clone().setY(0.3));
    playTumble(side);
  } else {
    // The owl swoops down out of the night sky behind you, takes you gently in its talons,
    // turns round and flies you home.
    const at = player.position.clone();
    fate.path = [new THREE.Vector3(at.x - 2, 11, at.z + 12), new THREE.Vector3(at.x, 6, at.z - 1), new THREE.Vector3(at.x, at.y + 1.55, at.z)];
    fate.away = new THREE.Vector3(at.x + 2.5, 12, at.z + 15);
    owl.model.visible = true;
    owl.model.position.copy(fate.path[0]);
    owl.model.rotation.set(0, Math.PI, 0);
    playHoot(side);
    resultsIn = 2.9;
  }
}

const curve = new THREE.QuadraticBezierCurve3();
const talons = new THREE.Vector3();

function updateFate(dt) {
  fate.time += dt;
  if (fate.kind === 'splash' || fate.kind === 'swept') {
    // Down into the water it goes.
    player.position.y = Math.max(player.position.y - dt * 3, WATER_LEVEL - 1.4);
    if (fate.time > 0.45) player.visible = false;
  } else if (fate.kind === 'tumble') {
    fate.velocity.y -= 25 * dt;
    player.position.addScaledVector(fate.velocity, dt);
    if (player.position.y <= 0) {
      player.position.y = 0;
      fate.velocity.set(0, 0, 0);
      player.rotation.z = fate.dir * (Math.PI / 2); // Flat on its side, seeing stars.
    } else {
      player.rotation.z += fate.dir * 11 * dt;
    }
  } else {
    const SWOOP = 0.8;
    const TURN = 0.4;
    const t = fate.time;
    if (t < SWOOP) {
      curve.v0.copy(fate.path[0]);
      curve.v1.copy(fate.path[1]);
      curve.v2.copy(fate.path[2]);
      curve.getPoint(THREE.MathUtils.smootherstep(t / SWOOP, 0, 1), owl.model.position);
    } else if (t < SWOOP + TURN) {
      owl.model.rotation.y = Math.PI * (1 - THREE.MathUtils.smoothstep((t - SWOOP) / TURN, 0, 1)); // Turns to face home.
    } else {
      const away = Math.min((t - SWOOP - TURN) / 1.6, 1);
      owl.model.position.lerpVectors(fate.path[2], fate.away, away * away);
    }
    owl.animate(dt, { flapping: true });
    if (t >= SWOOP) {
      owl.talons.getWorldPosition(talons);
      player.position.set(talons.x, talons.y - 1.12, talons.z); // Held by the shoulders, hat and all.
    }
  }
  if (resultsIn > 0) {
    resultsIn -= dt;
    if (resultsIn <= 0) showScoreboard(boards['gnome-crossing'], farthest, fate.story);
  }
}

// How far left (-1) or right (1) of the middle of the screen something is, so its sound comes from that side.
const onScreen = new THREE.Vector3();
function screenSide(position) {
  return onScreen.copy(position).project(camera).x;
}

// --- Dangers ---

function checkDangers() {
  if (hero.ride && Math.abs(hero.x) > SWEPT_AWAY) return fall('swept');
  const row = currentRow();
  if (safeFor <= 0) {
    const animal = trail.animalAt(row, hero.x, HIT_RADIUS);
    if (animal) return fall('tumble', animal);
  }
  if (night >= row) fall('owl');
}

// Night creeps up the trail behind you, a little faster the further you've come, and never
// lags too far behind your farthest hop (or, after the golden glow saves you, where it put you). As it gets close the bottom of the screen darkens, the
// music turns uneasy, and the owl hoots a warning from the dark.
function updateNight(dt) {
  const speed = THREE.MathUtils.lerp(...NIGHT_SPEED, Math.min(farthest / NIGHT_HARDEST, 1));
  night = Math.max(night + speed * dt, lead - NIGHT_LAG);
  const closeness = currentRow() - night;
  if (closeness < HOOT_AT && !hooted) {
    hooted = true;
    playHoot(0, { wings: false });
  } else if (closeness > HOOT_AT + 1) {
    hooted = false;
  }
}

// Draw the dark: shade the screen from the bottom up to where night has reached on the ground.
const front = new THREE.Vector3();
function showNight(dt) {
  front.set(camera.position.x, 0, rowZ(night));
  let top = window.innerHeight;
  if (front.z < camera.position.z - 1) top = ((1 - front.project(camera).y) / 2) * window.innerHeight;
  nightfall.style.top = `${Math.max(Math.min(top - 45, window.innerHeight), -60)}px`;
  const closeness = currentRow() - night;
  const danger = 1 - THREE.MathUtils.smoothstep(closeness, DANGER_NEAR, DANGER_FAR);
  setDanger(state === 'playing' ? danger : 0);
  // The daylight fades a little as night draws near, and comes back as you get away.
  const dusk = state === 'playing' ? danger : 0;
  sun.intensity = THREE.MathUtils.damp(sun.intensity, 2 * (1 - DUSK * dusk), 3, dt);
  skyLight.intensity = THREE.MathUtils.damp(skyLight.intensity, 1.2 * (1 - DUSK * 0.8 * dusk), 3, dt);
  return closeness;
}

// --- The fox ---

// The fox trots up the right-hand edge beside you, bounding across the creeks. When a golden
// raspberry is out, it runs ahead to that row and points at it, nose down, tail straight out.
function updateFox(dt) {
  const spot = fox.model.position;
  let goalZ = foxPointing && golden ? rowZ(golden.index) : player.position.z + 0.8;
  // Waiting for you, it waits on the bank, not in mid-air over a creek.
  const goalCreek = !foxPointing && trail.creekAround(Math.round(-goalZ / TILE));
  if (goalCreek) goalZ = rowZ(Math.abs(-goalZ / TILE - goalCreek[0]) < Math.abs(-goalZ / TILE - goalCreek[1]) ? goalCreek[0] - 1 : goalCreek[1] + 1);
  const distance = goalZ - spot.z;
  let speed = 0;
  let facing = fox.model.rotation.y;
  let pitch = 0;
  const pointing = foxPointing && golden && Math.abs(distance) < 0.3;
  if (Math.abs(distance) > 0.15) {
    speed = Math.min(FOX_SPEED, Math.abs(distance) * 3);
    spot.z += Math.sign(distance) * Math.min(speed * dt, Math.abs(distance));
    facing = distance < 0 ? Math.PI : 0;
  } else if (pointing) {
    facing = Math.atan2(goldenBerry.position.x - spot.x, goldenBerry.position.z - spot.z);
    pitch = Math.atan2(spot.y + 1 - goldenBerry.position.y, Math.abs(goldenBerry.position.x - spot.x));
  } else {
    facing = Math.atan2(player.position.x - spot.x, player.position.z - spot.z); // Looking at its friend.
  }
  spot.x = FOX_X;
  // Leaping across a creek in one great bound.
  const creek = trail.creekAround(Math.round(-spot.z / TILE));
  if (creek) {
    const across = (-spot.z / TILE - (creek[0] - 0.5)) / (creek[1] - creek[0] + 1);
    spot.y = Math.sin(Math.PI * THREE.MathUtils.clamp(across, 0, 1)) * (0.5 + 0.4 * (creek[1] - creek[0] + 1));
  } else {
    spot.y = 0;
  }
  fox.model.rotation.y += shortestTurn(facing - fox.model.rotation.y) * (1 - Math.exp(-8 * dt));
  fox.animate(dt, { speed, sniffing: pointing, pitch });
}

// --- Camera and HUD ---

const lookAt = new THREE.Vector3();
function moveCamera(dt) {
  const goalX = (fate ? fate.cameraAt.x : player.position.x * CAMERA_FOLLOW_SIDE);
  const goalZ = fate ? fate.cameraAt.z : player.position.z + CAMERA_BACK;
  if (dt === 0) camera.position.set(goalX, CAMERA_HEIGHT, goalZ);
  camera.position.x = THREE.MathUtils.damp(camera.position.x, goalX, 4, dt);
  camera.position.z = THREE.MathUtils.damp(camera.position.z, goalZ, 6, dt);
  camera.position.y = CAMERA_HEIGHT;
  camera.lookAt(lookAt.copy(camera.position).add(CAMERA_LOOK));
  camera.updateMatrixWorld();
  // The sun and its shadows, and the painted hills, come along too.
  const middleZ = camera.position.z - CAMERA_BACK - 8;
  sun.position.set(camera.position.x + 10, 20, middleZ + 10);
  sun.target.position.set(camera.position.x, 0, middleZ);
  backdrop.position.x = camera.position.x;
  backdrop.position.z = camera.position.z - CAMERA_BACK;
}

function bumpPill(pill) {
  pill.classList.remove('bump');
  void pill.offsetWidth; // Start the bump animation over, even if the last one is still going.
  pill.classList.add('bump');
}

function updateHud(closeness = Infinity) {
  hopsEl.textContent = farthest;
  berriesEl.textContent = berries;
  goldenPill.hidden = !hasGlow;
  let hint = '';
  if (state === 'playing' && readyIn <= 0 && closeness < HINT_AT) hint = 'Night is falling. Keep hopping!';
  else if (state === 'playing' && golden) hint = 'Follow the fox to the golden raspberry!';
  hintEl.hidden = !hint;
  if (hint && hintEl.textContent !== hint) hintEl.textContent = hint;
}

// --- Every frame ---

const standStill = { hop: null, swing: false, restart: false, pause: false };

function update(dt, controls) {
  worldTime += dt;
  flickerLanterns(worldTime);
  landedNow = false;

  // "Ready..." then "Go!": until then the gnome waits at the start, and night waits too.
  const ready = readyIn <= 0;
  if (!ready) {
    readyIn -= dt;
    controls = standStill;
    if (readyIn <= 0) setBannerSubtitle('Go!', 0.8);
  }
  if (controls.restart || (state === 'over' && controls.pause)) restart();
  if (controls.swing && state === 'playing' && gnome.swingStick()) playSwing(); // Just for fun.
  if (state === 'playing' && controls.hop) {
    if (hop) queued = controls.hop;
    else startHop(controls.hop);
  }

  trail.update(dt, farthest, currentRow());
  if (state === 'playing') {
    moveHero(dt);
    safeFor = Math.max(safeFor - dt, 0);
    if (state === 'playing') checkDangers();
    if (state === 'playing' && ready) updateNight(dt);
  } else {
    updateFate(dt);
  }
  updateGolden(dt);
  updateFox(dt);
  effects.update(dt);

  // The gnome: turned to face its hop, legs going while it hops, a squash on landing, a little
  // nudge against anything in the way, and blinking while the golden glow keeps it safe.
  player.rotation.y += shortestTurn(hero.facing - player.rotation.y) * (1 - Math.exp(-TURN_SPEED * dt));
  if (nudge > 0) {
    nudge = Math.max(nudge - dt, 0);
    const push = Math.sin((Math.PI * nudge) / 0.14) * 0.14;
    player.position.x += nudgeDir[0] * push;
    player.position.z += nudgeDir[1] * push;
  }
  const carried = fate?.kind === 'owl' && fate.time >= 0.8;
  const flying = fate?.kind === 'tumble' && player.position.y > 0;
  gnome.animate(dt, { running: Boolean(hop), pace: 1, inAir: carried || flying, verticalSpeed: 0, landed: landedNow });
  if (state === 'playing') player.visible = safeFor <= 0 || Math.floor(safeFor * 12) % 2 === 0;
  glow.intensity = hasGlow ? 2.2 + Math.sin(worldTime * 4) * 0.5 : 0;

  moveCamera(dt);
  const closeness = showNight(dt);
  updateHud(closeness);
}

restart();

// Gnome Crossing as an area of Lanternwood (see main.js).
export const gnomeCrossing = {
  name: 'Gnome Crossing',
  scene,
  camera,
  update,
  restart,
  // Coming in through the archway: a fresh trail, with "Ready..." and "Go!".
  enter() {
    restart();
    readyIn = READY_TIME;
    showBanner('Gnome Crossing', 'Ready…', 0);
  },
  // Going back to the woods: put the Top 10 away, and let the danger music fade.
  leave() {
    hideScoreboard();
    hideBanner();
    setDanger(0);
  },
  // Pausing by itself (when you switch windows) only makes sense mid-round.
  canPause: () => state === 'playing',
  // A round has started and isn't over, so leaving would lose it.
  roundInProgress: () => state === 'playing' && farthest > 0,
};
