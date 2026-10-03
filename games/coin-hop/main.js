import * as THREE from 'three';

// Tweak these to change how the game feels.
const COIN_COUNT = 10;
const ARENA_SIZE = 40;
const MOVE_SPEED = 8;
const JUMP_SPEED = 9;
const GRAVITY = 25;
const PLAYER_HALF_HEIGHT = 0.5;

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

function restart() {
  player.position.set(0, PLAYER_HALF_HEIGHT, 0);
  player.rotation.set(0, 0, 0);
  camera.position.copy(player.position).add(cameraOffset);
  verticalSpeed = 0;
  collected = 0;
  elapsed = 0;
  finished = false;
  messageEl.hidden = true;
  placeCoins();
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

// --- Game loop ---

const move = new THREE.Vector3();

function update(dt) {
  // Walk on the ground plane.
  move.set(0, 0, 0);
  if (isDown('KeyW', 'ArrowUp')) move.z -= 1;
  if (isDown('KeyS', 'ArrowDown')) move.z += 1;
  if (isDown('KeyA', 'ArrowLeft')) move.x -= 1;
  if (isDown('KeyD', 'ArrowRight')) move.x += 1;
  if (move.lengthSq() > 0) {
    move.normalize().multiplyScalar(MOVE_SPEED * dt);
    player.position.add(move);
    player.rotation.y = Math.atan2(move.x, move.z);
  }
  const limit = ARENA_SIZE / 2 - 0.5;
  player.position.x = THREE.MathUtils.clamp(player.position.x, -limit, limit);
  player.position.z = THREE.MathUtils.clamp(player.position.z, -limit, limit);

  // Jump and fall.
  const onGround = player.position.y <= PLAYER_HALF_HEIGHT;
  if (onGround && isDown('Space')) verticalSpeed = JUMP_SPEED;
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
    if (coin.position.distanceTo(player.position) < 1.1) {
      scene.remove(coin);
      coins.splice(i, 1);
      collected++;
      if (collected === COIN_COUNT) win();
    }
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
