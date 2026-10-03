import * as THREE from 'three';

// Tweak these to change how the game feels.
const COIN_COUNT = 10;
const ARENA_SIZE = 40;
const MOVE_SPEED = 8;
const JUMP_SPEED = 9;
const GRAVITY = 25;
const PLAYER_HALF_HEIGHT = 0.5;

// The inch worm that chases you.
const WORM_MAX_SPEED = MOVE_SPEED * 0.75; // Its fastest moment. It averages much less, since it stops to bunch up.
const WORM_LENGTH = 3;
const WORM_BUNCHED_LENGTH = WORM_LENGTH * 0.35; // How close the tail gets to the head when the body arches.
const WORM_RADIUS = 0.25;
const WORM_SEGMENTS = 15;
const WORM_MAX_TURN = Math.PI / 3; // It can turn at most 60 degrees per inch.
const WORM_START_DISTANCE = 15;
const WORM_CATCH_DISTANCE = 0.9;
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

const player = new THREE.Mesh(
  new THREE.BoxGeometry(1, PLAYER_HALF_HEIGHT * 2, 1),
  new THREE.MeshStandardMaterial({ color: 0xff6633 }),
);
player.castShadow = true;
scene.add(player);

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
    } while (Math.hypot(x, z) < 3); // Keep coins away from the starting spot.
    coin.position.set(x, 1, z);
    coin.castShadow = true;
    scene.add(coin);
    coins.push(coin);
  }
}

// --- Inch worm ---

// A chain of rainbow balls. The last ball is the head, which carries the eyes.
const wormGeometry = new THREE.SphereGeometry(WORM_RADIUS, 16, 12);
const wormMaterials = WORM_COLORS.map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.5 }));
const wormSegments = [];
for (let i = 0; i < WORM_SEGMENTS; i++) {
  const stripe = (WORM_SEGMENTS - 1 - i) % WORM_COLORS.length; // Count from the head, so the head is red.
  const segment = new THREE.Mesh(wormGeometry, wormMaterials[stripe]);
  segment.castShadow = true;
  scene.add(segment);
  wormSegments.push(segment);
}

const wormHead = wormSegments[WORM_SEGMENTS - 1];
wormHead.scale.setScalar(1.25);
const eyeGeometry = new THREE.SphereGeometry(0.07, 12, 8);
const eyeMaterial = new THREE.MeshStandardMaterial({ color: 0x000000, roughness: 0.2 });
for (const side of [-1, 1]) {
  const eye = new THREE.Mesh(eyeGeometry, eyeMaterial);
  eye.position.set(side * 0.1, 0.1, 0.2); // The front of the head is +z.
  wormHead.add(eye);
}

// An inch worm moves one end at a time: the tail scoots up to the head, arching the body,
// then the head reaches forward until the body is flat again.
const worm = {
  tail: new THREE.Vector3(), // Where each end touches the ground.
  head: new THREE.Vector3(),
  stretching: false, // true while the head reaches forward, false while the tail catches up.
  from: new THREE.Vector3(), // The moving end slides from here...
  to: new THREE.Vector3(), // ...to here during this step.
  stepTime: 0,
  stepDuration: 1,
};

function resetWorm() {
  // Start a way off, ahead and a little to the left, stretched out flat and facing the player.
  const away = new THREE.Vector3(-0.4, 0, -1).normalize();
  worm.head.copy(away).multiplyScalar(WORM_START_DISTANCE);
  worm.tail.copy(away).multiplyScalar(WORM_START_DISTANCE + WORM_LENGTH);
  worm.stretching = true; // So the first step pulls the tail up.
  startWormStep();
  shapeWorm();
}

function startWormStep() {
  worm.stretching = !worm.stretching;
  const facing = Math.atan2(worm.head.x - worm.tail.x, worm.head.z - worm.tail.z);
  if (worm.stretching) {
    // Turn toward the player, but only a little each step, then reach out to full length.
    const toPlayer = Math.atan2(player.position.x - worm.tail.x, player.position.z - worm.tail.z);
    const turn = Math.atan2(Math.sin(toPlayer - facing), Math.cos(toPlayer - facing)); // The shortest way round.
    const heading = facing + THREE.MathUtils.clamp(turn, -WORM_MAX_TURN, WORM_MAX_TURN);
    worm.from.copy(worm.head);
    worm.to.set(Math.sin(heading), 0, Math.cos(heading)).multiplyScalar(WORM_LENGTH).add(worm.tail);
  } else {
    // Pull the tail up behind the head.
    worm.from.copy(worm.tail);
    worm.to.set(Math.sin(facing), 0, Math.cos(facing)).multiplyScalar(-WORM_BUNCHED_LENGTH).add(worm.head);
  }
  const edge = ARENA_SIZE / 2 - WORM_RADIUS;
  worm.to.x = THREE.MathUtils.clamp(worm.to.x, -edge, edge);
  worm.to.z = THREE.MathUtils.clamp(worm.to.z, -edge, edge);

  // Each step speeds up then slows down, and its fastest moment is pi/2 times its average speed.
  // Timing the step like this makes that fastest moment exactly WORM_MAX_SPEED.
  worm.stepDuration = Math.max(((Math.PI / 2) * worm.from.distanceTo(worm.to)) / WORM_MAX_SPEED, 0.05);
  worm.stepTime = 0;
}

function updateWorm(dt) {
  worm.stepTime += dt;
  const progress = Math.min(worm.stepTime / worm.stepDuration, 1);
  const eased = (1 - Math.cos(Math.PI * progress)) / 2; // Starts slow, speeds up, slows down.
  const movingEnd = worm.stretching ? worm.head : worm.tail;
  movingEnd.lerpVectors(worm.from, worm.to, eased);
  if (progress === 1) startWormStep();
  shapeWorm();
}

// Bend the body into an arch between its two ends. The closer the ends, the taller the arch.
const archPoints = Array.from({ length: 11 }, () => new THREE.Vector3());
const archCurve = new THREE.CatmullRomCurve3(archPoints);

function shapeWorm() {
  const gap = worm.tail.distanceTo(worm.head);
  const archHeight = Math.sqrt(Math.max(WORM_LENGTH ** 2 - gap ** 2, 0)) / 2;
  archPoints.forEach((point, i) => {
    const along = i / (archPoints.length - 1);
    point.lerpVectors(worm.tail, worm.head, along);
    point.y = WORM_RADIUS + archHeight * Math.sin(Math.PI * along);
  });
  archCurve.updateArcLengths(); // The points moved, so measure the curve again.
  const spots = archCurve.getSpacedPoints(WORM_SEGMENTS - 1); // Evenly spaced, so the stripes stay even.
  wormSegments.forEach((segment, i) => segment.position.copy(spots[i]));

  wormHead.position.y += WORM_RADIUS * 0.25; // The head is bigger, so lift it to sit on the ground.
  wormHead.rotation.y = Math.atan2(worm.head.x - worm.tail.x, worm.head.z - worm.tail.z);
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
  player.position.set(0, PLAYER_HALF_HEIGHT, 0);
  player.rotation.set(0, 0, 0);
  camera.position.copy(player.position).add(cameraOffset);
  verticalSpeed = 0;
  collected = 0;
  elapsed = 0;
  finished = false;
  caughtByWorm = false;
  messageEl.hidden = true;
  placeCoins();
  resetWorm();
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

function update(dt) {
  // Walk on the ground plane.
  move.set(0, 0, 0);
  if (isDown('KeyW', 'ArrowUp')) move.z -= 1;
  if (isDown('KeyS', 'ArrowDown')) move.z += 1;
  if (isDown('KeyA', 'ArrowLeft')) move.x -= 1;
  if (isDown('KeyD', 'ArrowRight')) move.x += 1;
  if (move.lengthSq() > 0 && !caughtByWorm) {
    move.normalize().multiplyScalar(MOVE_SPEED * dt);
    player.position.add(move);
    player.rotation.y = Math.atan2(move.x, move.z);
  }
  const limit = ARENA_SIZE / 2 - 0.5;
  player.position.x = THREE.MathUtils.clamp(player.position.x, -limit, limit);
  player.position.z = THREE.MathUtils.clamp(player.position.z, -limit, limit);

  // Jump and fall.
  const onGround = player.position.y <= PLAYER_HALF_HEIGHT;
  if (onGround && isDown('Space') && !caughtByWorm) verticalSpeed = JUMP_SPEED;
  verticalSpeed -= GRAVITY * dt;
  player.position.y += verticalSpeed * dt;
  if (player.position.y < PLAYER_HALF_HEIGHT) {
    player.position.y = PLAYER_HALF_HEIGHT;
    verticalSpeed = 0;
  }

  // Spin coins and pick up any the player touches.
  for (let i = coins.length - 1; i >= 0; i--) {
    const coin = coins[i];
    coin.rotation.y += 3 * dt;
    if (!finished && coin.position.distanceTo(player.position) < 1.1) {
      scene.remove(coin);
      coins.splice(i, 1);
      collected++;
      if (collected === COIN_COUNT) win();
    }
  }

  // The inch worm crawls after the player until the round is over.
  if (!finished) {
    updateWorm(dt);
    if (wormHead.position.distanceTo(player.position) < WORM_CATCH_DISTANCE) caught();
  }

  if (!finished) elapsed += dt;
  updateHud();

  // Smoothly follow the player from behind and above.
  cameraGoal.copy(player.position).add(cameraOffset);
  camera.position.lerp(cameraGoal, 1 - Math.exp(-5 * dt));
  camera.lookAt(player.position);
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
