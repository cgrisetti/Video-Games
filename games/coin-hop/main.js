import * as THREE from 'three';
import { createGnome } from './gnome.js';

// Tweak these to change how the game feels.
const COIN_COUNT = 10;
const ARENA_SIZE = 40;
const MOVE_SPEED = 8;
const JUMP_SPEED = 9;
const GRAVITY = 25;
const TURN_SPEED = 12; // How quickly the gnome turns to face the way it's running.
const GNOME_RADIUS = 0.3; // How close the gnome can get to trees and rocks.
const GNOME_MIDDLE = 0.45; // Height of the middle of the gnome, where coins and worms touch it.

// Trees block you completely. Rocks are low enough to jump over, or to stand on.
const TREE_COUNT = 14;
const ROCK_COUNT = 12;
const OBSTACLE_GAP = 1.2; // Space always left between them, so the gnome can squeeze through.
const START_CLEARING = 4; // No trees or rocks this close to where the gnome starts.

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

const scoreEl = document.getElementById('score');
const timerEl = document.getElementById('timer');
const messageEl = document.getElementById('message');

// --- Renderer, scene and camera ---

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x87ceeb);
scene.fog = new THREE.Fog(0x87ceeb, 30, 80);

const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 200);
const cameraOffset = new THREE.Vector3(0, 6, 10);
const cameraGoal = new THREE.Vector3();

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
sun.shadow.camera.left = -ARENA_SIZE / 2;
sun.shadow.camera.right = ARENA_SIZE / 2;
sun.shadow.camera.top = ARENA_SIZE / 2;
sun.shadow.camera.bottom = -ARENA_SIZE / 2;
scene.add(sun);

// --- World ---

const ground = new THREE.Mesh(
  new THREE.PlaneGeometry(ARENA_SIZE, ARENA_SIZE),
  new THREE.MeshStandardMaterial({ color: 0x55aa55 }),
);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);

const gnome = createGnome();
const player = gnome.model;
scene.add(player);

// --- Trees and rocks ---

// Everything the gnome and the worms have to get around. Each one has a spot on the ground,
// a radius, and a height. Trees are taller than any jump, so their height is Infinity.
const obstacles = [];

// A tree is a trunk and three cones of leaves, each narrower than the one below,
// so you can see past the tops.
const trunkGeometry = new THREE.CylinderGeometry(0.12, 0.16, 0.8, 8).translate(0, 0.4, 0);
const trunkMaterial = new THREE.MeshStandardMaterial({ color: 0x7a5230, roughness: 0.9 });
const leafGeometries = [
  new THREE.ConeGeometry(0.75, 1.4, 8).translate(0, 1.3, 0),
  new THREE.ConeGeometry(0.58, 1.2, 8).translate(0, 2.0, 0),
  new THREE.ConeGeometry(0.4, 1.0, 8).translate(0, 2.7, 0),
];
const leafMaterial = new THREE.MeshStandardMaterial({ color: 0x2f7d3b, roughness: 0.8, flatShading: true });

function makeTree() {
  const tree = new THREE.Group();
  tree.add(new THREE.Mesh(trunkGeometry, trunkMaterial));
  for (const geometry of leafGeometries) tree.add(new THREE.Mesh(geometry, leafMaterial));
  for (const part of tree.children) part.castShadow = true;
  scene.add(tree);
  return tree;
}

// A rock is a chunky, squashed ball, half sunk into the ground.
const rockGeometry = new THREE.DodecahedronGeometry(1);
const rockMaterial = new THREE.MeshStandardMaterial({ color: 0x9a968c, roughness: 0.95, flatShading: true });

function makeRock() {
  const rock = new THREE.Mesh(rockGeometry, rockMaterial);
  rock.castShadow = true;
  scene.add(rock);
  return rock;
}

const trees = Array.from({ length: TREE_COUNT }, makeTree);
const rocks = Array.from({ length: ROCK_COUNT }, makeRock);

// Scatter the trees and rocks to new spots, with new sizes, for a new round.
function placeObstacles() {
  obstacles.length = 0;
  for (const tree of trees) {
    const size = THREE.MathUtils.randFloat(1, 1.3);
    tree.scale.setScalar(size);
    tree.rotation.y = Math.random() * Math.PI * 2;
    tree.visible = findOpenSpot(tree, 0.6 * size, Infinity);
  }
  for (const rock of rocks) {
    const width = THREE.MathUtils.randFloat(0.55, 0.75);
    const height = THREE.MathUtils.randFloat(0.55, 0.7);
    rock.scale.set(width, height, width);
    rock.rotation.y = Math.random() * Math.PI * 2;
    rock.visible = findOpenSpot(rock, 0.9 * width, 0.93 * height);
  }
}

// Move a tree or rock to an open spot and add it to the obstacles. Gives up if the field is too full.
function findOpenSpot(object, radius, height) {
  const half = ARENA_SIZE / 2 - 2;
  for (let attempt = 0; attempt < 100; attempt++) {
    const x = THREE.MathUtils.randFloat(-half, half);
    const z = THREE.MathUtils.randFloat(-half, half);
    if (Math.hypot(x, z) < START_CLEARING + radius || isNearObstacle(x, z, radius + OBSTACLE_GAP)) continue;
    object.position.set(x, 0, z);
    obstacles.push({ position: object.position, radius, height });
    return true;
  }
  return false;
}

// Is the spot x, z closer than `gap` to the edge of any tree or rock?
function isNearObstacle(x, z, gap) {
  return obstacles.some((obstacle) => Math.hypot(obstacle.position.x - x, obstacle.position.z - z) < obstacle.radius + gap);
}

// Push the gnome back out of trees, and out of rocks unless it's up on top of them.
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

// How high the ground is under the gnome: the top of a rock it's standing on, or 0.
function floorUnderGnome() {
  let floor = 0;
  for (const obstacle of obstacles) {
    const distance = Math.hypot(player.position.x - obstacle.position.x, player.position.z - obstacle.position.z);
    const onTop = distance < obstacle.radius * 0.7 && player.position.y >= obstacle.height - 0.05;
    if (onTop) floor = Math.max(floor, obstacle.height);
  }
  return floor;
}

// --- Coins ---

const coinGeometry = new THREE.CylinderGeometry(0.5, 0.5, 0.15, 24);
coinGeometry.rotateX(Math.PI / 2); // Stand the coin on its edge so spinning shows its face.
const coinMaterial = new THREE.MeshStandardMaterial({ color: 0xffcc00, emissive: 0x442200, metalness: 0.3, roughness: 0.4 });
const coins = [];

function placeCoins() {
  for (const coin of coins) scene.remove(coin);
  coins.length = 0;

  const half = ARENA_SIZE / 2 - 2;
  for (let i = 0; i < COIN_COUNT; i++) {
    const coin = new THREE.Mesh(coinGeometry, coinMaterial);
    let x, z;
    do {
      x = THREE.MathUtils.randFloat(-half, half);
      z = THREE.MathUtils.randFloat(-half, half);
    } while (Math.hypot(x, z) < 3 || isNearObstacle(x, z, 1)); // Keep coins away from the start and clear of trees and rocks.
    coin.position.set(x, 1, z);
    coin.castShadow = true;
    scene.add(coin);
    coins.push(coin);
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

// Give each worm its own quadrant of the field, at a random spot there, lying flat and facing the gnome.
function placeWorms() {
  let quadrants = [];
  for (const worm of worms) {
    if (quadrants.length === 0) quadrants = [[1, 1], [1, -1], [-1, 1], [-1, -1]]; // Refill if there are more than four worms.
    const [signX, signZ] = quadrants.splice(Math.floor(Math.random() * quadrants.length), 1)[0];
    const far = ARENA_SIZE / 2 - 4;
    for (let attempt = 0; attempt < 100; attempt++) {
      worm.head.set(signX * THREE.MathUtils.randFloat(1, far), 0, signZ * THREE.MathUtils.randFloat(1, far));
      worm.tail.copy(worm.head).setLength(worm.head.length() + WORM_LENGTH);
      if (worm.head.length() >= WORM_SAFE_DISTANCE && isClearForWorm(worm.tail, worm.head)) break;
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
  // Timing the step like this makes that fastest moment exactly WORM_MAX_SPEED.
  worm.stepDuration = Math.max(((Math.PI / 2) * worm.from.distanceTo(worm.to)) / WORM_MAX_SPEED, 0.05);
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

// Can a worm's body lie along the line from `from` to `to` without touching a tree or rock?
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

// Bend a worm's body into an arch between its two ends. The closer the ends, the taller the arch.
const archPoints = Array.from({ length: 11 }, () => new THREE.Vector3());
const archCurve = new THREE.CatmullRomCurve3(archPoints);

function shapeWorm(worm) {
  const gap = worm.tail.distanceTo(worm.head);
  const archHeight = Math.sqrt(Math.max(WORM_LENGTH ** 2 - gap ** 2, 0)) / 2;
  archPoints.forEach((point, i) => {
    const along = i / (archPoints.length - 1);
    point.lerpVectors(worm.tail, worm.head, along);
    point.y = WORM_RADIUS + archHeight * Math.sin(Math.PI * along);
  });
  archCurve.updateArcLengths(); // The points moved, so measure the curve again.
  const spots = archCurve.getSpacedPoints(WORM_SEGMENTS - 1); // Evenly spaced, so the stripes stay even.
  worm.segments.forEach((segment, i) => segment.position.copy(spots[i]));

  worm.headBall.position.y += WORM_RADIUS * 0.25; // The head is bigger, so lift it to sit on the ground.
  worm.headBall.rotation.y = Math.atan2(worm.head.x - worm.tail.x, worm.head.z - worm.tail.z);
}

// --- Helpers ---

// Keep a spot inside the field, at least `radius` from the edge.
function keepInArena(position, radius) {
  const limit = ARENA_SIZE / 2 - radius;
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
let collected = 0;
let elapsed = 0;
let finished = false;
let caughtByWorm = false;

function restart() {
  player.position.set(0, 0, 0);
  player.rotation.set(0, 0, 0);
  camera.position.copy(player.position).add(cameraOffset);
  verticalSpeed = 0;
  collected = 0;
  elapsed = 0;
  finished = false;
  caughtByWorm = false;
  messageEl.hidden = true;
  placeObstacles();
  placeCoins();
  placeWorms();
  updateHud();
}

function updateHud() {
  scoreEl.textContent = `Coins: ${collected} / ${COIN_COUNT}`;
  timerEl.textContent = `Time: ${elapsed.toFixed(1)}s`;
}

function win() {
  finished = true;
  messageEl.textContent = `You got them all in ${elapsed.toFixed(1)}s! Press R to play again.`;
  messageEl.hidden = false;
}

function caught() {
  finished = true;
  caughtByWorm = true;
  messageEl.textContent = 'The inch worm got you! Press R to try again.';
  messageEl.hidden = false;
}

// --- Game loop ---

const move = new THREE.Vector3();
const playerMiddle = new THREE.Vector3();

function update(dt) {
  // Run around on the ground.
  move.set(0, 0, 0);
  if (isDown('KeyW', 'ArrowUp')) move.z -= 1;
  if (isDown('KeyS', 'ArrowDown')) move.z += 1;
  if (isDown('KeyA', 'ArrowLeft')) move.x -= 1;
  if (isDown('KeyD', 'ArrowRight')) move.x += 1;
  const running = move.lengthSq() > 0 && !caughtByWorm;
  if (running) {
    move.normalize().multiplyScalar(MOVE_SPEED * dt);
    player.position.add(move);
    // Turn smoothly to face the way the gnome is running.
    const turn = shortestTurn(Math.atan2(move.x, move.z) - player.rotation.y);
    player.rotation.y += turn * (1 - Math.exp(-TURN_SPEED * dt));
  }
  bumpIntoObstacles();
  keepInArena(player.position, GNOME_RADIUS);

  // Jump and fall. On top of a rock, the rock is the ground.
  const floor = floorUnderGnome();
  if (player.position.y <= floor && isDown('Space') && !caughtByWorm) verticalSpeed = JUMP_SPEED;
  verticalSpeed -= GRAVITY * dt;
  player.position.y += verticalSpeed * dt;
  const landed = player.position.y < floor && verticalSpeed < -3;
  if (player.position.y < floor) {
    player.position.y = floor;
    verticalSpeed = 0;
  }
  gnome.animate(dt, { running, inAir: player.position.y > floor, verticalSpeed, landed });
  playerMiddle.copy(player.position);
  playerMiddle.y += GNOME_MIDDLE;

  // Spin coins and pick up any the gnome touches.
  for (let i = coins.length - 1; i >= 0; i--) {
    const coin = coins[i];
    coin.rotation.y += 3 * dt;
    if (!finished && coin.position.distanceTo(playerMiddle) < 1.1) {
      scene.remove(coin);
      coins.splice(i, 1);
      collected++;
      if (collected === COIN_COUNT) win();
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

  // Smoothly follow the gnome from behind and above.
  cameraGoal.copy(playerMiddle).add(cameraOffset);
  camera.position.lerp(cameraGoal, 1 - Math.exp(-5 * dt));
  camera.lookAt(playerMiddle);
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
