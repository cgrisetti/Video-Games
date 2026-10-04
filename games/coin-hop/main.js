import * as THREE from 'three';
import { createGnome } from './gnome.js';
import { makeGround, makeWater, updateCreek, bridges, groundHeightAt, isInWater, isNearBridge, creekDistance, CREEK_HALF_WIDTH } from './creek.js';
import { makeTree, makeRock, makeLog, makeHedges, makeOuterWoods, TREE_HEIGHT, TRUNK_DIAMETER } from './scenery.js';
import { showScoreboard, hideScoreboard } from './scoreboard.js';
import { createBackdrop, SKY_COLOR, HAZE_COLOR } from './backdrop.js';
import { makeRaspberry } from './raspberry.js';

// Tweak these to change how the game feels.
const BERRY_COUNT = 10;
const ARENA_SIZE = 40;
const HEDGE_THICKNESS = 1.2; // The hedges around the edge take up this much of the field.
const START_Z = 4; // The gnome starts a little south of the middle, on dry land.
const MOVE_SPEED = 8;
const CREEK_SLOWDOWN = 0.6; // In the creek, the gnome and the worms move at 60% speed.
const JUMP_SPEED = 9;
const GRAVITY = 25;
const TURN_SPEED = 12; // How quickly the gnome turns to face the way it's running.
const GNOME_RADIUS = 0.3; // How close the gnome can get to trees and rocks.
const GNOME_MIDDLE = 0.45; // Height of the middle of the gnome, where raspberries and worms touch it.
const CAMERA_LOOK_ABOVE = 2; // Aim the camera this far above the gnome, so the painted sky shows.

// Trees block you completely. Rocks and logs are low enough to jump over, or to stand on.
const TREE_COUNT = 14;
// A few trees in the field are other kinds; the rest are pines. Biggest first, since they're hardest to fit.
const TREE_MIX = ['oak', 'oak', 'maple', 'maple', 'poplar', 'poplar'];
const TREE_SIZES = [1, 1.3]; // Smallest and biggest tree, compared with the basic tree.
const TREE_FADE = 0.3; // How solid a tree stays when it's between the camera and the gnome (0 is invisible).
const ROCK_COUNT = 12;
const ROCK_WIDTHS = [0.55, 0.75];
const ROCK_HEIGHTS = [0.55, 0.7];
const LOG_COUNT = 4;
// Logs are as thick as the tree trunks, longer than the widest rock and shorter than the tallest tree.
const LOG_THICKNESSES = [TRUNK_DIAMETER * TREE_SIZES[0], TRUNK_DIAMETER * TREE_SIZES[1]];
const LOG_LENGTHS = [2 * ROCK_WIDTHS[1] + 0.3, TREE_HEIGHT * TREE_SIZES[1] - 0.3];
const OBSTACLE_GAP = 1.2; // Space always left between them, so the gnome can squeeze through.
const START_CLEARING = 4; // No trees, rocks or logs this close to where the gnome starts.

// The inch worms that chase you.
const WORM_COUNT = 3; // Each one starts in a different quadrant of the field.
const WORM_MAX_SPEED = MOVE_SPEED * 0.9; // Its fastest moment. It averages much less, since it stops to bunch up.
const WORM_LENGTH = 3;
const WORM_BUNCHED_LENGTH = WORM_LENGTH * 0.35; // How close the tail gets to the head when the body arches.
const WORM_RADIUS = 0.25;
const WORM_SEGMENTS = 15;
const WORM_MAX_TURN = Math.PI / 3; // It turns at most 60 degrees per inch, unless it's steering around something.
const WORM_SAFE_DISTANCE = 10; // Worms never start closer than this to the gnome.
const WORM_CATCH_DISTANCE = 0.75;
const WORM_COLORS = [0xff3b30, 0xff9500, 0xffdd00, 0x34c759, 0x1e90ff, 0x5856d6, 0xaf52de]; // Red to violet.

const PLAY_HALF = ARENA_SIZE / 2 - HEDGE_THICKNESS; // From the middle of the field to the inside of the hedges.

const scoreEl = document.getElementById('score');
const timerEl = document.getElementById('timer');

// --- Renderer, scene and camera ---

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(SKY_COLOR);
scene.fog = new THREE.Fog(HAZE_COLOR, 35, 110); // Faraway trees fade toward the color of the painted hills.

const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 200);
const cameraOffset = new THREE.Vector3(0, 6, 10);
const cameraGoal = new THREE.Vector3();
const cameraTarget = new THREE.Vector3();

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// --- Lights ---

scene.add(new THREE.HemisphereLight(0xffffff, 0x446644, 1.2));

const sun = new THREE.DirectionalLight(0xffffff, 2);
sun.position.set(10, 20, 10);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.camera.left = -ARENA_SIZE / 2 - 4;
sun.shadow.camera.right = ARENA_SIZE / 2 + 4;
sun.shadow.camera.top = ARENA_SIZE / 2 + 4;
sun.shadow.camera.bottom = -ARENA_SIZE / 2 - 4;
scene.add(sun);

// --- World ---

scene.add(makeGround(), makeWater(), makeHedges(ARENA_SIZE, HEDGE_THICKNESS), makeOuterWoods(ARENA_SIZE), createBackdrop());
for (const bridge of bridges) scene.add(bridge.model);

const gnome = createGnome();
const player = gnome.model;
scene.add(player);

// --- Trees, rocks and logs ---

// Everything the gnome and the worms have to get around. Each one has a spot on the ground,
// a radius you bump into, and a height. Trees are taller than any jump, so their height is
// Infinity, and they also have a `room`: how far their leaves spread, which other things keep clear of.
// The bridge railings are obstacles too, and they stay put from round to round.
const obstacles = [];
const railings = bridges.flatMap((bridge) => bridge.bumpers);
const trees = Array.from({ length: TREE_COUNT }, (_, i) => makeTree(TREE_MIX[i] ?? 'pine'));
const rocks = Array.from({ length: ROCK_COUNT }, makeRock);
const logs = Array.from({ length: LOG_COUNT }, makeLog);
scene.add(...trees, ...rocks, ...logs);

// Scatter the trees, rocks and logs to new spots, with new sizes, for a new round.
// Logs go first, since long things are the hardest to fit.
function placeObstacles() {
  obstacles.length = 0;
  obstacles.push(...railings);
  for (const log of logs) log.visible = placeLog(log);
  for (const tree of trees) {
    const size = THREE.MathUtils.randFloat(...TREE_SIZES);
    const { blockRadius, canopyRadius } = tree.userData;
    tree.scale.setScalar(size);
    tree.rotation.y = Math.random() * Math.PI * 2;
    tree.visible = findOpenSpot(tree, blockRadius * size, Infinity, canopyRadius * size);
  }
  for (const rock of rocks) {
    const width = THREE.MathUtils.randFloat(...ROCK_WIDTHS);
    const height = THREE.MathUtils.randFloat(...ROCK_HEIGHTS);
    rock.scale.set(width, height, width);
    rock.rotation.y = Math.random() * Math.PI * 2;
    rock.visible = findOpenSpot(rock, 0.9 * width, 0.93 * height);
  }
}

// Is x, z a good place for something `radius` wide? On dry land inside the hedges,
// clear of the start, the bridges and every other obstacle.
function isOpenSpot(x, z, radius) {
  const half = PLAY_HALF - 1.5;
  if (Math.abs(x) > half || Math.abs(z) > half) return false;
  if (Math.hypot(x, z - START_Z) < START_CLEARING + radius) return false;
  if (creekDistance(x, z) < CREEK_HALF_WIDTH + radius + 0.5 || isNearBridge(x, z, radius + 1)) return false;
  return !isNearObstacle(x, z, radius + OBSTACLE_GAP);
}

// Move a tree or rock to an open spot and add it to the obstacles. Gives up if the field is too full.
// `room` is how much space it needs around it, if that's more than the radius you bump into.
function findOpenSpot(object, radius, height, room = radius) {
  const half = PLAY_HALF - 1.5;
  for (let attempt = 0; attempt < 100; attempt++) {
    const x = THREE.MathUtils.randFloat(-half, half);
    const z = THREE.MathUtils.randFloat(-half, half);
    if (!isOpenSpot(x, z, room)) continue;
    object.position.set(x, 0, z);
    obstacles.push({ position: object.position, radius, height, room });
    return true;
  }
  return false;
}

// Lay a log down somewhere open, at a random angle. It's added to the obstacles as a row of
// small circles along its length, so it blocks you all the way along (unless you jump).
function placeLog(log) {
  const length = THREE.MathUtils.randFloat(...LOG_LENGTHS);
  const thickness = THREE.MathUtils.randFloat(...LOG_THICKNESSES);
  const radius = thickness / 2;
  const reach = length / 2 - radius; // From the middle of the log to the middle of its last circle.
  const count = Math.ceil((2 * reach) / 0.15);
  const half = PLAY_HALF - 1.5;
  for (let attempt = 0; attempt < 100; attempt++) {
    const x = THREE.MathUtils.randFloat(-half, half);
    const z = THREE.MathUtils.randFloat(-half, half);
    const angle = Math.random() * Math.PI;
    const circles = [];
    for (let i = 0; i <= count; i++) {
      const along = -reach + (i / count) * 2 * reach;
      circles.push(new THREE.Vector3(x + Math.cos(angle) * along, 0, z - Math.sin(angle) * along));
    }
    if (!circles.every((spot) => isOpenSpot(spot.x, spot.z, radius))) continue;
    log.scale.set(length, thickness, thickness);
    log.position.set(x, 0, z);
    log.rotation.y = angle;
    for (const position of circles) obstacles.push({ position, radius, height: thickness });
    return true;
  }
  return false;
}

// Trees standing between the camera and the gnome fade out, so you never lose sight of it.
function fadeTreesInTheWay(dt) {
  const lineX = playerMiddle.x - camera.position.x;
  const lineZ = playerMiddle.z - camera.position.z;
  const lineLengthSquared = lineX * lineX + lineZ * lineZ;
  for (const tree of trees) {
    // How far along the line from the camera to the gnome the tree is (0 at the camera, 1 at
    // the gnome), how far off to the side, and how high the line passes there.
    const along = ((tree.position.x - camera.position.x) * lineX + (tree.position.z - camera.position.z) * lineZ) / lineLengthSquared;
    const sideways = Math.hypot(camera.position.x + lineX * along - tree.position.x, camera.position.z + lineZ * along - tree.position.z);
    const lineHeight = camera.position.y + (playerMiddle.y - camera.position.y) * along;
    const size = tree.scale.x;
    const { canopyRadius, height, materials } = tree.userData;
    const betweenUs = along > 0 && along < 1 && sideways < canopyRadius * size + 0.5 && lineHeight < height * size;
    const overhead = Math.hypot(playerMiddle.x - tree.position.x, playerMiddle.z - tree.position.z) < canopyRadius * size; // The gnome is under its leaves.
    const inTheWay = betweenUs || overhead;
    const opacity = THREE.MathUtils.damp(materials[0].opacity, inTheWay ? TREE_FADE : 1, 8, dt);
    for (const material of materials) material.opacity = opacity;
  }
}

// Is the spot x, z closer than `gap` to the edge of any obstacle (or the edge of a tree's leaves)?
function isNearObstacle(x, z, gap) {
  return obstacles.some((obstacle) => Math.hypot(obstacle.position.x - x, obstacle.position.z - z) < (obstacle.room ?? obstacle.radius) + gap);
}

// Push the gnome back out of trees, rocks and railings, unless it's up on top of them.
function bumpIntoObstacles() {
  for (const obstacle of obstacles) {
    if (player.position.y >= obstacle.height - 0.05) continue;
    const dx = player.position.x - obstacle.position.x;
    const dz = player.position.z - obstacle.position.z;
    const distance = Math.hypot(dx, dz);
    const closest = obstacle.radius + GNOME_RADIUS;
    if (distance > 0 && distance < closest) {
      player.position.x = obstacle.position.x + (dx / distance) * closest;
      player.position.z = obstacle.position.z + (dz / distance) * closest;
    }
  }
}

// How high the ground is under the gnome: grass, creek bed, a bridge, or the top of a rock it's standing on.
function floorUnderGnome() {
  let floor = groundHeightAt(player.position.x, player.position.z);
  for (const obstacle of obstacles) {
    const distance = Math.hypot(player.position.x - obstacle.position.x, player.position.z - obstacle.position.z);
    const onTop = distance < obstacle.radius * 0.7 && player.position.y >= obstacle.height - 0.05;
    if (onTop) floor = Math.max(floor, obstacle.height);
  }
  return floor;
}

// --- Raspberries ---

const berries = [];

function placeBerries() {
  for (const berry of berries) scene.remove(berry);
  berries.length = 0;

  const half = PLAY_HALF - 1.5;
  for (let i = 0; i < BERRY_COUNT; i++) {
    const berry = makeRaspberry();
    let x, z;
    do {
      x = THREE.MathUtils.randFloat(-half, half);
      z = THREE.MathUtils.randFloat(-half, half);
    } while (Math.hypot(x, z - START_Z) < 3 || isNearObstacle(x, z, 1) || isNearBridge(x, z, 1)); // Keep them clear of the start, trees, rocks and bridges.
    berry.userData.floatHeight = groundHeightAt(x, z) + 0.9; // Some float over the creek, so you'll have to wade.
    berry.userData.bobOffset = Math.random() * Math.PI * 2;
    berry.position.set(x, berry.userData.floatHeight, z);
    scene.add(berry);
    berries.push(berry);
  }
}

// --- Inch worms ---

const wormGeometry = new THREE.SphereGeometry(WORM_RADIUS, 16, 12);
const wormMaterials = WORM_COLORS.map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.5 }));
const eyeGeometry = new THREE.SphereGeometry(0.07, 12, 8);
const eyeMaterial = new THREE.MeshStandardMaterial({ color: 0x000000, roughness: 0.2 });

// A worm is a chain of rainbow balls. The last ball is the head, which carries the eyes.
// It moves one end at a time: the tail scoots up to the head, arching the body,
// then the head reaches forward until the body is flat again.
function makeWorm() {
  const segments = [];
  for (let i = 0; i < WORM_SEGMENTS; i++) {
    const stripe = (WORM_SEGMENTS - 1 - i) % WORM_COLORS.length; // Count from the head, so the head is red.
    const segment = new THREE.Mesh(wormGeometry, wormMaterials[stripe]);
    segment.castShadow = true;
    scene.add(segment);
    segments.push(segment);
  }
  const headBall = segments[WORM_SEGMENTS - 1];
  headBall.scale.setScalar(1.25);
  for (const side of [-1, 1]) {
    const eye = new THREE.Mesh(eyeGeometry, eyeMaterial);
    eye.position.set(side * 0.1, 0.1, 0.2); // The front of the head is +z.
    headBall.add(eye);
  }
  return {
    segments,
    headBall,
    tail: new THREE.Vector3(), // Where each end touches the ground.
    head: new THREE.Vector3(),
    stretching: false, // true while the head reaches forward, false while the tail catches up.
    from: new THREE.Vector3(), // The moving end slides from here...
    to: new THREE.Vector3(), // ...to here during this step.
    stepTime: 0,
    stepDuration: 1,
    dodgeSide: 1, // Which way it last turned to get around a tree or rock.
  };
}

const worms = Array.from({ length: WORM_COUNT }, makeWorm);

// Give each worm its own quadrant of the field, at a random spot there, lying flat and facing the middle.
function placeWorms() {
  let quadrants = [];
  for (const worm of worms) {
    if (quadrants.length === 0) quadrants = [[1, 1], [1, -1], [-1, 1], [-1, -1]]; // Refill if there are more than four worms.
    const [signX, signZ] = quadrants.splice(Math.floor(Math.random() * quadrants.length), 1)[0];
    const far = PLAY_HALF - 4;
    for (let attempt = 0; attempt < 100; attempt++) {
      worm.head.set(signX * THREE.MathUtils.randFloat(1, far), 0, signZ * THREE.MathUtils.randFloat(1, far));
      worm.tail.copy(worm.head).setLength(worm.head.length() + WORM_LENGTH);
      const safe = Math.hypot(worm.head.x, worm.head.z - START_Z) >= WORM_SAFE_DISTANCE;
      if (safe && isClearForWorm(worm.tail, worm.head)) break;
    }
    worm.stretching = true; // So its first step pulls the tail up.
    startWormStep(worm);
    shapeWorm(worm);
  }
}

function startWormStep(worm) {
  worm.stretching = !worm.stretching;
  const facing = Math.atan2(worm.head.x - worm.tail.x, worm.head.z - worm.tail.z);
  if (worm.stretching) {
    worm.from.copy(worm.head);
    chooseReach(worm, facing);
  } else {
    // Pull the tail up behind the head.
    worm.from.copy(worm.tail);
    worm.to.set(Math.sin(facing), 0, Math.cos(facing)).multiplyScalar(-WORM_BUNCHED_LENGTH).add(worm.head);
    keepInArena(worm.to, WORM_RADIUS);
  }

  // Each step speeds up then slows down, and its fastest moment is pi/2 times its average speed.
  // Timing the step like this makes that fastest moment exactly its top speed, which is lower in the creek.
  const wading = isInWater(worm.from.x, worm.from.z) || isInWater(worm.to.x, worm.to.z);
  const topSpeed = WORM_MAX_SPEED * (wading ? CREEK_SLOWDOWN : 1);
  worm.stepDuration = Math.max(((Math.PI / 2) * worm.from.distanceTo(worm.to)) / topSpeed, 0.05);
  worm.stepTime = 0;
}

// Pick where the head reaches to: toward the gnome, turning only a little each step.
// If a tree or rock is in the way, try turning further left and right until the way is clear,
// starting with the side it dodged to last time so it doesn't wiggle back and forth.
function chooseReach(worm, facing) {
  const toGnome = Math.atan2(player.position.x - worm.tail.x, player.position.z - worm.tail.z);
  const wanted = facing + THREE.MathUtils.clamp(shortestTurn(toGnome - facing), -WORM_MAX_TURN, WORM_MAX_TURN);
  for (let i = 0; i < 18; i++) {
    const side = i % 2 === 1 ? worm.dodgeSide : -worm.dodgeSide;
    reachToward(worm, wanted + Math.ceil(i / 2) * 0.35 * side);
    if (isClearForWorm(worm.tail, worm.to) && isClearForWorm(worm.head, worm.to)) {
      if (i > 0) worm.dodgeSide = side;
      return;
    }
  }
  reachToward(worm, wanted); // Boxed in on every side, so just go for it.
}

function reachToward(worm, heading) {
  worm.to.set(Math.sin(heading), 0, Math.cos(heading)).multiplyScalar(WORM_LENGTH).add(worm.tail);
  keepInArena(worm.to, WORM_RADIUS);
}

// Can a worm's body lie along the line from `from` to `to` without touching an obstacle?
const wormLine = new THREE.Line3();
const closestPoint = new THREE.Vector3();

function isClearForWorm(from, to) {
  wormLine.set(from, to);
  return obstacles.every((obstacle) => {
    wormLine.closestPointToPoint(obstacle.position, true, closestPoint);
    return closestPoint.distanceTo(obstacle.position) > obstacle.radius + WORM_RADIUS + 0.1;
  });
}

function updateWorm(worm, dt) {
  worm.stepTime += dt;
  const progress = Math.min(worm.stepTime / worm.stepDuration, 1);
  const eased = (1 - Math.cos(Math.PI * progress)) / 2; // Starts slow, speeds up, slows down.
  const movingEnd = worm.stretching ? worm.head : worm.tail;
  movingEnd.lerpVectors(worm.from, worm.to, eased);
  if (progress === 1) startWormStep(worm);
  shapeWorm(worm);
}

// Bend a worm's body into an arch between its two ends, following the ground (down into the
// creek, or up over a bridge). The closer the ends, the taller the arch.
const archPoints = Array.from({ length: 11 }, () => new THREE.Vector3());
const archCurve = new THREE.CatmullRomCurve3(archPoints);

function shapeWorm(worm) {
  const gap = worm.tail.distanceTo(worm.head);
  const archHeight = Math.sqrt(Math.max(WORM_LENGTH ** 2 - gap ** 2, 0)) / 2;
  archPoints.forEach((point, i) => {
    const along = i / (archPoints.length - 1);
    point.lerpVectors(worm.tail, worm.head, along);
    point.y = groundHeightAt(point.x, point.z) + WORM_RADIUS + archHeight * Math.sin(Math.PI * along);
  });
  archCurve.updateArcLengths(); // The points moved, so measure the curve again.
  const spots = archCurve.getSpacedPoints(WORM_SEGMENTS - 1); // Evenly spaced, so the stripes stay even.
  worm.segments.forEach((segment, i) => segment.position.copy(spots[i]));

  worm.headBall.position.y += WORM_RADIUS * 0.25; // The head is bigger, so lift it to sit on the ground.
  worm.headBall.rotation.y = Math.atan2(worm.head.x - worm.tail.x, worm.head.z - worm.tail.z);
}

// --- Helpers ---

// Keep a spot inside the hedges, at least `radius` away from them.
function keepInArena(position, radius) {
  const limit = PLAY_HALF - radius;
  position.x = THREE.MathUtils.clamp(position.x, -limit, limit);
  position.z = THREE.MathUtils.clamp(position.z, -limit, limit);
}

// The smallest turn from one direction to another, between -180 and 180 degrees (in radians).
function shortestTurn(angle) {
  return Math.atan2(Math.sin(angle), Math.cos(angle));
}

// --- Input ---

const keys = new Set();

window.addEventListener('keydown', (event) => {
  if (event.target instanceof HTMLInputElement) return; // Typing a name for the Top 10 shouldn't move the gnome.
  if (event.code === 'Space' || event.code.startsWith('Arrow')) event.preventDefault();
  keys.add(event.code);
  if (event.code === 'KeyR') restart();
});
window.addEventListener('keyup', (event) => keys.delete(event.code));
window.addEventListener('blur', () => keys.clear());

function isDown(...codes) {
  return codes.some((code) => keys.has(code));
}

// --- Game state ---

let verticalSpeed = 0;
let grounded = true;
let wading = false; // Standing (or jumping from) in the creek.
let collected = 0;
let elapsed = 0;
let worldTime = 0;
let finished = false;
let caughtByWorm = false;

function restart() {
  player.position.set(0, 0, START_Z);
  player.rotation.set(0, 0, 0);
  camera.position.copy(player.position).add(cameraOffset);
  verticalSpeed = 0;
  grounded = true;
  wading = false;
  collected = 0;
  elapsed = 0;
  finished = false;
  caughtByWorm = false;
  hideScoreboard();
  placeObstacles();
  placeBerries();
  placeWorms();
  updateHud();
}

function updateHud() {
  scoreEl.textContent = `Raspberries: ${collected} / ${BERRY_COUNT}`;
  timerEl.textContent = `Time: ${elapsed.toFixed(1)}s`;
}

// Either way a round ends, the Top 10 board comes up.
function win() {
  finished = true;
  showScoreboard(elapsed);
}

function caught() {
  if (caughtByWorm) return; // Two worms can reach the gnome in the same moment.
  finished = true;
  caughtByWorm = true;
  showScoreboard(null);
}

// --- Game loop ---

const move = new THREE.Vector3();
const playerMiddle = new THREE.Vector3();

function update(dt) {
  worldTime += dt;
  updateCreek(dt);

  // Run around on the ground. Wading through the creek is slower.
  move.set(0, 0, 0);
  if (isDown('KeyW', 'ArrowUp')) move.z -= 1;
  if (isDown('KeyS', 'ArrowDown')) move.z += 1;
  if (isDown('KeyA', 'ArrowLeft')) move.x -= 1;
  if (isDown('KeyD', 'ArrowRight')) move.x += 1;
  const running = move.lengthSq() > 0 && !caughtByWorm;
  if (running) {
    move.normalize().multiplyScalar(MOVE_SPEED * (wading ? CREEK_SLOWDOWN : 1) * dt);
    player.position.add(move);
    // Turn smoothly to face the way the gnome is running.
    const turn = shortestTurn(Math.atan2(move.x, move.z) - player.rotation.y);
    player.rotation.y += turn * (1 - Math.exp(-TURN_SPEED * dt));
  }
  bumpIntoObstacles();
  keepInArena(player.position, GNOME_RADIUS);

  // Jump and fall. The ground might be grass, the creek bed, a bridge or the top of a rock.
  const floor = floorUnderGnome();
  // Walking down a slope, stay on the ground instead of floating off it for a moment.
  if (grounded && verticalSpeed <= 0 && player.position.y - floor < 0.35) player.position.y = floor;
  if (player.position.y <= floor && isDown('Space') && !caughtByWorm) verticalSpeed = JUMP_SPEED;
  verticalSpeed -= GRAVITY * dt;
  player.position.y += verticalSpeed * dt;
  const landed = player.position.y < floor && verticalSpeed < -3;
  if (player.position.y < floor) {
    player.position.y = floor;
    verticalSpeed = 0;
  }
  grounded = player.position.y <= floor;
  if (grounded) wading = isInWater(player.position.x, player.position.z);
  gnome.animate(dt, { running, inAir: !grounded, verticalSpeed, landed });
  playerMiddle.copy(player.position);
  playerMiddle.y += GNOME_MIDDLE;

  // Bob and spin the raspberries, and pick any the gnome touches.
  for (let i = berries.length - 1; i >= 0; i--) {
    const berry = berries[i];
    berry.rotation.y += 1.5 * dt;
    berry.position.y = berry.userData.floatHeight + Math.sin(worldTime * 2.5 + berry.userData.bobOffset) * 0.08;
    if (!finished && berry.position.distanceTo(playerMiddle) < 1) {
      scene.remove(berry);
      berries.splice(i, 1);
      collected++;
      if (collected === BERRY_COUNT) win();
    }
  }

  // The inch worms crawl after the gnome until the round is over.
  if (!finished) {
    for (const worm of worms) {
      updateWorm(worm, dt);
      if (worm.headBall.position.distanceTo(playerMiddle) < WORM_CATCH_DISTANCE) caught();
    }
  }

  if (!finished) elapsed += dt;
  updateHud();

  // Smoothly follow the gnome from behind and above, looking a little over its head.
  cameraGoal.copy(playerMiddle).add(cameraOffset);
  camera.position.lerp(cameraGoal, 1 - Math.exp(-5 * dt));
  cameraTarget.copy(playerMiddle);
  cameraTarget.y += CAMERA_LOOK_ABOVE;
  camera.lookAt(cameraTarget);
  fadeTreesInTheWay(dt);
}

let lastTime = null;

renderer.setAnimationLoop((time) => {
  // Cap the step so a paused tab doesn't make everything jump forward.
  const dt = lastTime === null ? 0 : Math.min((time - lastTime) / 1000, 0.05);
  lastTime = time;
  update(dt);
  renderer.render(scene, camera);
});

restart();
