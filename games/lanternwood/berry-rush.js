import * as THREE from 'three';
import { createGnome } from './gnome.js';
import { createFox } from './fox.js';
import { createWalker, shortestTurn, MOVE_SPEED, GNOME_RADIUS } from './walker.js';
import { setDanger } from './music.js';
import { showBanner, setBannerSubtitle, hideBanner } from './banner.js';
import { makeGardenGate, OPENING } from './gates.js';
import { createEffects } from './effects.js';
import { playSwing, playBonk, playPop, playChomp } from './sounds.js';
import { flickerLanterns } from './lantern.js';
import { makeGround, makeWater, updateCreek, bridges, groundHeightAt, isInWater, isNearBridge, creekDistance, CREEK_HALF_WIDTH } from './creek.js';
import { makeTree, makeRock, makeLog, makeHedges, makeOuterWoods, TREE_HEIGHT, TRUNK_DIAMETER } from './scenery.js';
import { boards, showScoreboard, hideScoreboard } from './scoreboard.js';
import { createBackdrop, SKY_COLOR, HAZE_COLOR } from './backdrop.js';
import { makeRaspberry, makeGoldenRaspberry } from './raspberry.js';

// Berry Rush: Lanternwood's first game. A field of raspberries ringed by hedges and woods, with a
// creek, three hungry rainbow inch worms, and a golden raspberry to finish. You come in through
// the garden gate at the south end of the field. (How the gnome moves is in walker.js.)

// Tweak these to change how the game feels.
const BERRY_COUNT = 9; // Pick these, then find the golden raspberry to finish.
const ARENA_SIZE = 40;
const HEDGE_THICKNESS = 1.2; // The hedges around the edge take up this much of the field.
const START_Z = 4; // The gnome starts a little south of the middle, on dry land.
const CREEK_SLOWDOWN = 0.6; // In the creek, the gnome and the worms move at 60% speed.
const READY_TIME = 1.6; // Seconds of "Ready..." before a round starts, when you come in through the gate.
const RESULTS_DELAY = 1.3; // Seconds to enjoy the golden raspberry popping before the Top 10 board comes up.

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
const STUN_TIME = 5; // Seconds a worm lies dazed after a bonk on the head with the stick.
const STUN_SPEEDUP = 1.05; // Each bonk makes that worm 5% faster...
const WORM_TOP_SPEED = MOVE_SPEED * 0.99; // ...up to 99% of the gnome's top speed.
const STICK_REACH = 0.44; // How close the stick has to come to a worm's head to bonk it.
const DANGER_FAR = 9; // The danger music starts creeping in when a worm is this close...
const DANGER_NEAR = 3; // ...and is at full strength this close.

// The fox, the gnome's friend.
const FOX_FOLLOW_SPEED = MOVE_SPEED * 1.15; // A little faster than the gnome, so it can keep up.
const FOX_LEAD_SPEED = MOVE_SPEED * 0.05; // How slowly it walks the gnome to the golden raspberry.
const FOX_SIDE_GAP = 1.9; // It walks beside the gnome, never between it and the camera.
const FOX_RADIUS = 0.55;
const FOX_POINT_TIME = 1.5; // Seconds it stands pointing before it starts walking.

const PLAY_HALF = ARENA_SIZE / 2 - HEDGE_THICKNESS; // From the middle of the field to the inside of the hedges.

const scoreEl = document.getElementById('score');
const timerEl = document.getElementById('timer');
const berryPill = document.getElementById('berry-pill');
const hintEl = document.getElementById('hud-hint');

// --- Scene and camera ---

const scene = new THREE.Scene();
scene.background = new THREE.Color(SKY_COLOR);
scene.fog = new THREE.Fog(HAZE_COLOR, 35, 110); // Faraway trees fade toward the color of the painted hills.

const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 200);

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

// The garden gate stands in a gap in the middle of the south hedge, its sign facing out toward the
// woods: it's the way you came in. (To leave, pick "Return to Woods" in the pause menu.)
const gateGap = { edge: 'south', from: -OPENING / 2 - 0.6, to: OPENING / 2 + 0.6 };
const gate = makeGardenGate('Berry Rush');
gate.position.set(0, 0, ARENA_SIZE / 2 - HEDGE_THICKNESS / 2);
scene.add(gate);

scene.add(makeGround(), makeWater(), makeHedges(ARENA_SIZE, HEDGE_THICKNESS, [gateGap]), makeOuterWoods(ARENA_SIZE), createBackdrop());
for (const bridge of bridges) scene.add(bridge.model);

const gnome = createGnome();
const player = gnome.model;
scene.add(player);
const walker = createWalker({
  gnome,
  camera,
  floorAt: floorUnderGnome,
  pushOut: bumpIntoObstacles,
  keepIn: keepInArena,
  speedAt: (x, z) => (isInWater(x, z) ? CREEK_SLOWDOWN : 1),
});
const playerMiddle = walker.middle; // Where raspberries and worms touch the gnome.

const effects = createEffects(scene, camera); // Berries popping, and their numbers floating up.

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
  for (const tree of trees) {
    const size = tree.scale.x;
    const { canopyRadius, height, materials } = tree.userData;
    const overhead = Math.hypot(playerMiddle.x - tree.position.x, playerMiddle.z - tree.position.z) < canopyRadius * size; // The gnome is under its leaves.
    const inTheWay = overhead || blocksView(tree.position.x, tree.position.z, canopyRadius * size, height * size);
    const opacity = THREE.MathUtils.damp(materials[0].opacity, inTheWay ? TREE_FADE : 1, 8, dt);
    for (const material of materials) material.opacity = opacity;
  }
}

// Is something standing at x, z (this wide and this tall) between the camera and the gnome?
function blocksView(x, z, radius, height) {
  const lineX = playerMiddle.x - camera.position.x;
  const lineZ = playerMiddle.z - camera.position.z;
  // How far along the line from the camera to the gnome it is (0 at the camera, 1 at the gnome),
  // how far off to the side, and how high the line passes there.
  const along = ((x - camera.position.x) * lineX + (z - camera.position.z) * lineZ) / (lineX * lineX + lineZ * lineZ);
  const sideways = Math.hypot(camera.position.x + lineX * along - x, camera.position.z + lineZ * along - z);
  const lineHeight = camera.position.y + (playerMiddle.y - camera.position.y) * along;
  return along > 0 && along < 1 && sideways < radius + 0.5 && lineHeight < height;
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

// The golden raspberry appears once all the others are picked, in one of the three quadrants of
// the field the gnome isn't in. Picking it finishes the round.
const goldenBerry = makeGoldenRaspberry();
goldenBerry.visible = false;
scene.add(goldenBerry);
let goldenOut = false;

function spawnGoldenBerry() {
  const gnomeQuadrant = [Math.sign(player.position.x) || 1, Math.sign(player.position.z) || 1];
  const others = [[1, 1], [1, -1], [-1, 1], [-1, -1]].filter(([sx, sz]) => sx !== gnomeQuadrant[0] || sz !== gnomeQuadrant[1]);
  const [signX, signZ] = others[Math.floor(Math.random() * others.length)];
  const half = PLAY_HALF - 1.5;
  let x, z;
  for (let attempt = 0; attempt < 200; attempt++) {
    x = signX * THREE.MathUtils.randFloat(1.5, half);
    z = signZ * THREE.MathUtils.randFloat(1.5, half);
    const onDryOpenGround = creekDistance(x, z) > CREEK_HALF_WIDTH + 0.5 && !isNearBridge(x, z, 1) && !isNearObstacle(x, z, 1.2);
    if (onDryOpenGround) break;
  }
  goldenBerry.userData.floatHeight = groundHeightAt(x, z) + 1;
  goldenBerry.position.set(x, goldenBerry.userData.floatHeight, z);
  goldenBerry.visible = true;
  goldenOut = true;
  // The fox catches the scent.
  foxPlan.mode = 'point';
  foxPlan.timer = 0;
}

// --- The fox ---

// The fox trots along beside the gnome. When the golden raspberry appears, it drops into a
// sniffing stance and points its nose straight at it, then walks slowly toward it to show the way.
const fox = createFox();
scene.add(fox.model);
const foxPlan = { mode: 'follow', side: -1, timer: 0 }; // mode: 'follow', 'point' or 'lead'.
let foxOpacity = 1;

function resetFox() {
  foxPlan.mode = 'follow';
  foxPlan.side = -1;
  fox.model.position.set(player.position.x - FOX_SIDE_GAP, 0, player.position.z + 0.6);
  fox.model.rotation.set(0, 0, 0);
}

function updateFox(dt) {
  const spot = fox.model.position;
  let goalX, goalZ, speed = 0, pitch = 0;
  let facing = fox.model.rotation.y;

  if (foxPlan.mode === 'follow') {
    // Stay beside the gnome, on whichever side the fox is already on, so it never blocks the view.
    const besideX = spot.x - player.position.x;
    if (Math.abs(besideX) > 0.8) foxPlan.side = Math.sign(besideX);
    goalX = player.position.x + foxPlan.side * FOX_SIDE_GAP;
    goalZ = player.position.z + 0.6;
    const distance = Math.hypot(goalX - spot.x, goalZ - spot.z);
    if (distance > 0.3) {
      speed = Math.min(FOX_FOLLOW_SPEED, distance * 2.5); // Trot faster the further behind it is.
      facing = Math.atan2(goalX - spot.x, goalZ - spot.z);
    } else {
      facing = Math.atan2(player.position.x - spot.x, player.position.z - spot.z); // Look at its friend.
    }
  } else {
    // Point the nose straight at the golden raspberry, then lead the way to it, slowly.
    goalX = goldenBerry.position.x;
    goalZ = goldenBerry.position.z;
    const distance = Math.hypot(goalX - spot.x, goalZ - spot.z);
    facing = Math.atan2(goalX - spot.x, goalZ - spot.z);
    pitch = Math.atan2(spot.y + 1.0 - goldenBerry.position.y, distance); // Tip the nose down (or up) to it.
    foxPlan.timer += dt;
    if (foxPlan.mode === 'point' && foxPlan.timer > FOX_POINT_TIME) foxPlan.mode = 'lead';
    if (foxPlan.mode === 'lead' && distance > 1.8) speed = FOX_LEAD_SPEED;
  }

  if (speed > 0) {
    const distance = Math.hypot(goalX - spot.x, goalZ - spot.z);
    const stepLength = Math.min(speed * dt, distance);
    spot.x += ((goalX - spot.x) / distance) * stepLength;
    spot.z += ((goalZ - spot.z) / distance) * stepLength;
  }
  // Trees are in its way too; rocks, logs and the creek it just steps over or wades through.
  for (const obstacle of obstacles) {
    if (obstacle.height !== Infinity) continue;
    const dx = spot.x - obstacle.position.x;
    const dz = spot.z - obstacle.position.z;
    const distance = Math.hypot(dx, dz);
    const closest = obstacle.radius + FOX_RADIUS;
    if (distance > 0 && distance < closest) {
      spot.x = obstacle.position.x + (dx / distance) * closest;
      spot.z = obstacle.position.z + (dz / distance) * closest;
    }
  }
  keepInArena(spot, FOX_RADIUS);
  spot.y = groundHeightAt(spot.x, spot.z);
  fox.model.rotation.y += shortestTurn(facing - fox.model.rotation.y) * (1 - Math.exp(-8 * dt));
  fox.animate(dt, { speed, sniffing: foxPlan.mode !== 'follow', pitch });

  // If it wanders between the camera and the gnome (catching up from behind), it fades like a tree.
  foxOpacity = THREE.MathUtils.damp(foxOpacity, blocksView(spot.x, spot.z, 0.6, spot.y + 1.8) ? TREE_FADE : 1, 8, dt);
  fox.setOpacity(foxOpacity);
}

// --- Inch worms ---

const wormGeometry = new THREE.SphereGeometry(WORM_RADIUS, 16, 12);
const wormMaterials = WORM_COLORS.map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.5 }));
const eyeGeometry = new THREE.SphereGeometry(0.07, 12, 8);
const eyeMaterial = new THREE.MeshStandardMaterial({ color: 0x000000, roughness: 0.2 });
const crossGeometry = new THREE.BoxGeometry(0.15, 0.035, 0.03); // One stroke of an X for a dazed eye.
const ROLL_SPEED = (Math.PI / 2) / 0.25; // A bonked worm takes a quarter of a second to roll onto its side.

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
  const eyes = [];
  const dazedEyes = [];
  for (const side of [-1, 1]) {
    const eye = new THREE.Mesh(eyeGeometry, eyeMaterial);
    eye.position.set(side * 0.1, 0.1, 0.2); // The front of the head is +z.
    headBall.add(eye);
    eyes.push(eye);
    // When it's bonked, each eye turns into a little X.
    const cross = new THREE.Group();
    for (const tilt of [Math.PI / 4, -Math.PI / 4]) {
      const stroke = new THREE.Mesh(crossGeometry, eyeMaterial);
      stroke.rotation.z = tilt;
      cross.add(stroke);
    }
    cross.position.set(side * 0.1, 0.1, 0.235);
    cross.visible = false;
    headBall.add(cross);
    dazedEyes.push(cross);
  }
  return {
    segments,
    headBall,
    eyes,
    dazedEyes,
    tail: new THREE.Vector3(), // Where each end touches the ground.
    head: new THREE.Vector3(),
    stretching: false, // true while the head reaches forward, false while the tail catches up.
    from: new THREE.Vector3(), // The moving end slides from here...
    to: new THREE.Vector3(), // ...to here during this step.
    stepTime: 0,
    stepDuration: 1,
    dodgeSide: 1, // Which way it last turned to get around a tree or rock.
    topSpeed: WORM_MAX_SPEED, // Goes up a little every time it's bonked.
    stunTime: 0, // Seconds left lying dazed.
    roll: 0, // How far it has rolled onto its side: 0 upright, up to 90 degrees (in radians).
    rollSide: 1, // Which way it rolls: away from the gnome.
  };
}

// A worm is dazed while it's stunned, and while it rolls back up afterwards.
function isDazed(worm) {
  return worm.stunTime > 0 || worm.roll > 0;
}

// Bonk! The worm rolls over away from the gnome, its eyes turn to X's, and when it gets
// back up it's a little faster than before.
function stunWorm(worm) {
  worm.stunTime = STUN_TIME;
  const acrossX = worm.head.z - worm.tail.z;
  const acrossZ = -(worm.head.x - worm.tail.x);
  const gnomeSide = (player.position.x - worm.head.x) * acrossX + (player.position.z - worm.head.z) * acrossZ;
  worm.rollSide = gnomeSide > 0 ? -1 : 1;
  worm.topSpeed = Math.min(worm.topSpeed * STUN_SPEEDUP, WORM_TOP_SPEED);
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
    worm.topSpeed = WORM_MAX_SPEED;
    worm.stunTime = 0;
    worm.roll = 0;
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
  const topSpeed = worm.topSpeed * (wading ? CREEK_SLOWDOWN : 1);
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
  // A bonked worm rolls onto its side and lies there with X eyes, then rolls back up.
  worm.stunTime = Math.max(worm.stunTime - dt, 0);
  const rollTo = worm.stunTime > 0 ? Math.PI / 2 : 0;
  worm.roll = rollTo > worm.roll ? Math.min(worm.roll + ROLL_SPEED * dt, rollTo) : Math.max(worm.roll - ROLL_SPEED * dt, rollTo);
  const dazed = isDazed(worm);
  for (const eye of worm.eyes) eye.visible = !dazed;
  for (const cross of worm.dazedEyes) cross.visible = dazed;

  if (!dazed) {
    worm.stepTime += dt;
    const progress = Math.min(worm.stepTime / worm.stepDuration, 1);
    const eased = (1 - Math.cos(Math.PI * progress)) / 2; // Starts slow, speeds up, slows down.
    const movingEnd = worm.stretching ? worm.head : worm.tail;
    movingEnd.lerpVectors(worm.from, worm.to, eased);
    if (progress === 1) startWormStep(worm);
  }
  shapeWorm(worm);
}

// Bend a worm's body into an arch between its two ends, following the ground (down into the
// creek, or up over a bridge). The closer the ends, the taller the arch. When it's rolled onto
// its side, the arch tips over sideways to lie flat on the ground.
const archPoints = Array.from({ length: 11 }, () => new THREE.Vector3());
const archCurve = new THREE.CatmullRomCurve3(archPoints);

function shapeWorm(worm) {
  const gap = worm.tail.distanceTo(worm.head);
  const archHeight = Math.sqrt(Math.max(WORM_LENGTH ** 2 - gap ** 2, 0)) / 2;
  const facing = Math.atan2(worm.head.x - worm.tail.x, worm.head.z - worm.tail.z);
  const sidewaysX = Math.cos(facing) * worm.rollSide; // Flat on the ground, square to the body.
  const sidewaysZ = -Math.sin(facing) * worm.rollSide;
  archPoints.forEach((point, i) => {
    const along = i / (archPoints.length - 1);
    const bump = archHeight * Math.sin(Math.PI * along);
    point.lerpVectors(worm.tail, worm.head, along);
    point.x += sidewaysX * bump * Math.sin(worm.roll);
    point.z += sidewaysZ * bump * Math.sin(worm.roll);
    point.y = groundHeightAt(point.x, point.z) + WORM_RADIUS + bump * Math.cos(worm.roll);
  });
  archCurve.updateArcLengths(); // The points moved, so measure the curve again.
  const spots = archCurve.getSpacedPoints(WORM_SEGMENTS - 1); // Evenly spaced, so the stripes stay even.
  worm.segments.forEach((segment, i) => segment.position.copy(spots[i]));

  worm.headBall.position.y += WORM_RADIUS * 0.25; // The head is bigger, so lift it to sit on the ground.
  worm.headBall.rotation.set(0, facing, -worm.rollSide * worm.roll); // Roll the head over too, eyes and all.
}

// --- Helpers ---

// Keep a spot inside the hedges, at least `radius` away from them.
function keepInArena(position, radius) {
  const limit = PLAY_HALF - radius;
  position.x = THREE.MathUtils.clamp(position.x, -limit, limit);
  position.z = THREE.MathUtils.clamp(position.z, -limit, limit);
}

// --- Game state ---

let collected = 0;
let elapsed = 0;
let worldTime = 0;
let finished = false;
let caughtByWorm = false;
let resultsIn = 0; // Seconds until the Top 10 board comes up, after picking the golden raspberry.
let readyIn = 0; // Seconds of "Ready..." left before the round starts.

function restart() {
  effects.clear();
  hideBanner();
  readyIn = 0;
  walker.place(0, START_Z, 0);
  collected = 0;
  elapsed = 0;
  finished = false;
  caughtByWorm = false;
  resultsIn = 0;
  goldenOut = false;
  goldenBerry.visible = false;
  hideScoreboard();
  placeObstacles();
  placeBerries();
  placeWorms();
  resetFox();
  updateHud();
}

// The raspberries picked (the golden one is number 10) and the clock.
function updateHud() {
  scoreEl.textContent = `${collected} / ${BERRY_COUNT + 1}`;
  berryPill.classList.toggle('golden', collected >= BERRY_COUNT);
  hintEl.hidden = !goldenOut;
  timerEl.textContent = `${elapsed.toFixed(1)}s`;
}

// Pick a raspberry: count it, pop it, and give the counter a little bump.
function pickBerry(berry, golden, onGone) {
  collected++;
  playPop(collected, golden);
  effects.popBerry(berry, { number: collected, golden, floor: groundHeightAt(berry.position.x, berry.position.z), onGone });
  berryPill.classList.remove('bump');
  void berryPill.offsetWidth; // Start the bump animation over, even if the last one is still going.
  berryPill.classList.add('bump');
}

// Either way a round ends, the Top 10 board comes up: straight away if a worm caught you,
// or after a moment to enjoy the golden raspberry popping if you picked it.
function win() {
  finished = true;
  resultsIn = RESULTS_DELAY;
}

function caught(worm) {
  if (caughtByWorm) return; // Two worms can reach the gnome in the same moment.
  finished = true;
  caughtByWorm = true;
  playChomp(screenSide(worm.headBall.position));
  showScoreboard(boards['berry-rush'], null);
}

// How far left (-1) or right (1) of the middle of the screen something is, so its sound comes from that side.
const onScreen = new THREE.Vector3();
function screenSide(position) {
  return onScreen.copy(position).project(camera).x;
}

// --- Game loop ---

const standStill = { moveX: 0, moveZ: 0, jump: false, swing: false, restart: false, pause: false };

// `controls` is the keyboard or controller: which way to go, how hard, and whether to jump, swing or play again.
function update(dt, controls) {
  worldTime += dt;
  updateCreek(dt);
  flickerLanterns(worldTime);

  // "Ready..." then "Go!": until then, the gnome waits at the start and nothing moves.
  const ready = readyIn <= 0;
  if (!ready) {
    readyIn -= dt;
    controls = standStill;
    if (readyIn <= 0) setBannerSubtitle('Go!', 0.8);
  }

  if (controls.restart || (finished && controls.pause)) restart();
  if (controls.swing && !caughtByWorm && gnome.swingStick()) playSwing();

  // Run, jump and fall. The ground might be grass, the creek bed (slow going), a bridge or the top of a rock.
  walker.update(dt, controls, !caughtByWorm);

  // Bob and spin the raspberries, and pick any the gnome touches.
  for (let i = berries.length - 1; i >= 0; i--) {
    const berry = berries[i];
    berry.rotation.y += 1.5 * dt;
    berry.position.y = berry.userData.floatHeight + Math.sin(worldTime * 2.5 + berry.userData.bobOffset) * 0.08;
    if (!finished && berry.position.distanceTo(playerMiddle) < 1) {
      berries.splice(i, 1);
      pickBerry(berry, false, () => scene.remove(berry));
      if (collected === BERRY_COUNT) spawnGoldenBerry();
    }
  }

  // The golden raspberry bobs, spins and shines. Picking it finishes the round.
  if (goldenOut) {
    goldenBerry.rotation.y += 1.2 * dt;
    goldenBerry.position.y = goldenBerry.userData.floatHeight + Math.sin(worldTime * 2) * 0.12;
    goldenBerry.userData.rays.material.rotation += 0.4 * dt;
    goldenBerry.userData.rays.scale.setScalar(3.4 + Math.sin(worldTime * 3) * 0.25);
    if (!finished && goldenBerry.position.distanceTo(playerMiddle) < 1.3) {
      goldenOut = false;
      pickBerry(goldenBerry, true, () => (goldenBerry.visible = false));
      win();
    }
  }
  effects.update(dt);
  if (resultsIn > 0) {
    resultsIn -= dt;
    if (resultsIn <= 0) showScoreboard(boards['berry-rush'], elapsed);
  }

  // A swing of the stick that catches an inch worm on the head stuns it.
  if (!finished && gnome.isStriking()) {
    const stick = gnome.whereIsStick();
    for (const worm of worms) {
      if (isDazed(worm)) continue;
      const headRadius = WORM_RADIUS * 1.25;
      if (stick.some((point) => point.distanceTo(worm.headBall.position) < headRadius + STICK_REACH)) {
        stunWorm(worm);
        playBonk(screenSide(worm.headBall.position));
      }
    }
  }

  // The inch worms crawl after the gnome until the round is over. Dazed worms can't catch anyone.
  if (!finished && ready) {
    for (const worm of worms) {
      updateWorm(worm, dt);
      if (!isDazed(worm) && worm.headBall.position.distanceTo(playerMiddle) < WORM_CATCH_DISTANCE) caught(worm);
    }
  }
  updateFox(dt);

  // Music: the danger layer swells as the nearest wide-awake inch worm creeps closer.
  let nearestWorm = Infinity;
  for (const worm of worms) {
    if (!isDazed(worm)) nearestWorm = Math.min(nearestWorm, worm.headBall.position.distanceTo(playerMiddle));
  }
  setDanger(finished ? 0 : 1 - THREE.MathUtils.smoothstep(nearestWorm, DANGER_NEAR, DANGER_FAR));

  if (!finished && ready) elapsed += dt;
  updateHud();

  walker.followCamera(dt);
  fadeTreesInTheWay(dt);
}

restart();

// Berry Rush as an area of Lanternwood (see main.js).
export const berryRush = {
  name: 'Berry Rush',
  scene,
  camera,
  update,
  restart,
  // Coming in through the gate: a fresh round, with "Ready..." and "Go!".
  enter() {
    restart();
    readyIn = READY_TIME;
    showBanner('Berry Rush', 'Ready…', 0);
  },
  // Going back to the woods: put the Top 10 away and let the danger music fade.
  leave() {
    hideScoreboard();
    hideBanner();
    setDanger(0);
  },
  // Pausing by itself (when you switch windows) only makes sense mid-round.
  canPause: () => !finished,
  // A round has started and isn't over, so leaving would lose it.
  roundInProgress: () => !finished && elapsed > 0,
};
