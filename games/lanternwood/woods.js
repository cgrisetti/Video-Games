import * as THREE from 'three';
import { createGnome } from './gnome.js';
import { createFox } from './fox.js';
import { createWalker, shortestTurn, MOVE_SPEED } from './walker.js';
import { makeRock, makeHedgeWalls, growWoods } from './scenery.js';
import { createBackdrop, SKY_COLOR, HAZE_COLOR } from './backdrop.js';
import { makeLantern, flickerLanterns } from './lantern.js';
import { makeGardenGate, makeHedgeArch, makeArbor, makeTrailhead, makeGardenDoor, OPENING } from './gates.js';
import { showBanner, hideBanner } from './banner.js';
import { showToast } from './menu.js';
import { isUsingController } from './input.js';
import { formatTime } from './scoreboard.js';
import { playSwing } from './sounds.js';

// The woods of Lanternwood: the Glenn, a long lantern-lit path between hedges, with games behind
// the gates, archways and openings along its sides, and the old garden door to the Bramble Maze at
// the far end. It works like the hub world of a
// console adventure: walk up to an opening and a prompt appears; press F (□ on a controller) to
// see what's there, and press it again to go in. Openings whose games aren't built yet are shut,
// with a "Coming soon" sign, to show there's more to find.

// Tweak these to change the Glenn.
const HALL_WIDTH = 18;
const HALL_LENGTH = 72; // It runs north and south, so the camera looks down its length.
const HEDGE_THICKNESS = 1.2;
const START_Z = 30; // The gnome starts near the south end and walks north.
const PATH_SWAY = 1.6; // How far the forest path winds from side to side...
const PATH_BEND = 28; // ...and how far along it one whole wind takes.
const PATH_HALF_WIDTH = 1.25;
const LANTERN_SPACING = 9; // A lantern beside the path this often, on alternate sides.
const ROCK_COUNT = 7;
const INTERACT_RANGE = 2.3; // How close to an opening the gnome has to be to go in.
const BACKDROP_RADIUS = 48; // The painted hills sit further out than in Berry Rush, round this longer area.

// The games, as the openings describe them.
const GAMES = {
  'berry-rush': {
    title: 'Berry Rush',
    blurb: 'Pick all 9 raspberries, then follow the fox to the golden one. Watch out for the inch worms!',
  },
  'bramble-maze': {
    title: 'Bramble Maze',
    blurb: "Find your way out of a tall hedge maze, a new one every time. Lanterns light up where you've been.",
  },
};

// The openings along the Glenn: which kind, which side (-1 west, 1 east, 0 the far north end, where
// the path leads), how far along, and which game is behind it (none yet, for some).
const OPENINGS = [
  { kind: 'gate', side: -1, z: 22, game: 'berry-rush' },
  { kind: 'arch', side: 1, z: 11 },
  { kind: 'arbor', side: -1, z: -1 },
  { kind: 'trail', side: 1, z: -13 },
  { kind: 'arch', side: -1, z: -24 },
  { kind: 'door', side: 0, z: -HALL_LENGTH / 2, game: 'bramble-maze' },
];
const BUILDERS = { gate: makeGardenGate, arch: makeHedgeArch, arbor: makeArbor, trail: makeTrailhead, door: makeGardenDoor };

const FOX_FOLLOW_SPEED = MOVE_SPEED * 1.15;
const FOX_SIDE_GAP = 1.9;
const FOX_RADIUS = 0.55;

const HALF_X = HALL_WIDTH / 2;
const HALF_Z = HALL_LENGTH / 2;
const INNER_X = HALF_X - HEDGE_THICKNESS; // From the middle to the inside of the hedges.
const INNER_Z = HALF_Z - HEDGE_THICKNESS;

const promptEl = document.getElementById('prompt');
const promptKey = document.getElementById('prompt-key');
const promptText = document.getElementById('prompt-text');
const card = document.getElementById('portal-card');
const cardTitle = document.getElementById('portal-title');
const cardBlurb = document.getElementById('portal-blurb');
const cardBest = document.getElementById('portal-best');
const cardPlayKey = document.getElementById('portal-play-key');
const cardCloseKey = document.getElementById('portal-close-key');

// --- Scene, camera and light ---

const scene = new THREE.Scene();
scene.background = new THREE.Color(SKY_COLOR);
scene.fog = new THREE.Fog(HAZE_COLOR, 35, 110);
const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 200);

scene.add(new THREE.HemisphereLight(0xffffff, 0x446644, 1.2));
const sun = new THREE.DirectionalLight(0xffffff, 2);
sun.position.set(10, 20, 10);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
Object.assign(sun.shadow.camera, { left: -HALF_X - 6, right: HALF_X + 6, top: HALF_Z + 6, bottom: -HALF_Z - 6, far: 80 });
scene.add(sun);

// The same painted hills as Berry Rush, turned a quarter of the way round, so you see a different part.
const backdrop = createBackdrop({ radius: BACKDROP_RADIUS });
backdrop.rotation.y = Math.PI / 2;
scene.add(backdrop);

// --- The forest path ---

// The middle of the winding path at a point along the Glenn.
function pathX(z) {
  return PATH_SWAY * Math.sin((z / PATH_BEND) * Math.PI * 2);
}

// Each opening's spot in the hedge, the way it faces, and the spot in front of it where you stand to go in.
const openings = OPENINGS.map((opening) => {
  const x = opening.side * (HALF_X - HEDGE_THICKNESS / 2);
  const z = opening.side === 0 ? -HALF_Z + HEDGE_THICKNESS / 2 : opening.z;
  const inward = opening.side === 0 ? [0, 1] : [-opening.side, 0]; // Toward the path.
  return {
    ...opening,
    x,
    z,
    facing: Math.atan2(inward[0], inward[1]),
    spot: new THREE.Vector3(x + inward[0] * 1.4, 0, z + inward[1] * 1.4),
    // A side path from the forest path, through the opening and off into the trees beyond.
    branchFrom: new THREE.Vector2(opening.side === 0 ? 0 : pathX(z), opening.side === 0 ? z + 4 : z),
    branchTo: new THREE.Vector2(x - inward[0] * 7, z - inward[1] * 7),
  };
});

// How far a spot is from the nearest path (the forest path, or a side path to an opening).
const segment = new THREE.Line3();
const closest = new THREE.Vector3();
function pathDistance(x, z) {
  let distance = Math.abs(x - pathX(z)) - PATH_HALF_WIDTH;
  if (z > HALF_Z + 2 || z < -HALF_Z) distance = Infinity; // The forest path stops at the ends.
  for (const { branchFrom, branchTo } of openings) {
    segment.start.set(branchFrom.x, 0, branchFrom.y);
    segment.end.set(branchTo.x, 0, branchTo.y);
    segment.closestPointToPoint(closest.set(x, 0, z), true, closest);
    distance = Math.min(distance, Math.hypot(closest.x - x, closest.z - z) - PATH_HALF_WIDTH * 0.6);
  }
  return distance;
}

// The ground: grass with soft light and dark patches, and the paths worn into it.
function makeGround() {
  const size = BACKDROP_RADIUS * 2 + 6;
  const geometry = new THREE.PlaneGeometry(size, size, 220, 220).rotateX(-Math.PI / 2);
  const positions = geometry.attributes.position;
  const colors = new Float32Array(positions.count * 3);
  const grass = new THREE.Color(0x55aa55);
  const dirt = new THREE.Color(0xb39a6c);
  const color = new THREE.Color();
  for (let i = 0; i < positions.count; i++) {
    const x = positions.getX(i);
    const z = positions.getZ(i);
    const patch = Math.sin(x * 0.31) * Math.sin(z * 0.27) + 0.6 * Math.sin(x * 0.11 - z * 0.15);
    color.copy(grass).offsetHSL(0, 0, patch * 0.03);
    const worn = 1 - THREE.MathUtils.smoothstep(pathDistance(x, z), -0.25, 0.3);
    color.lerp(dirt.clone().offsetHSL(0, 0, patch * 0.02), worn * 0.9);
    color.toArray(colors, i * 3);
  }
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geometry.computeVertexNormals();
  const ground = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1 }));
  ground.receiveShadow = true;
  return ground;
}
scene.add(makeGround());

// --- Hedges, openings, woods and lanterns ---

const gap = (along) => [along - OPENING / 2 - 0.6, along + OPENING / 2 + 0.6];
const sideGaps = (side) => openings.filter((o) => o.side === side).map((o) => gap(HALF_Z - o.z));
const line = (half) => half - HEDGE_THICKNESS / 2;
scene.add(
  makeHedgeWalls(
    [
      { from: [-line(HALF_X), HALF_Z], to: [-line(HALF_X), -HALF_Z], gaps: sideGaps(-1) }, // west
      { from: [line(HALF_X), HALF_Z], to: [line(HALF_X), -HALF_Z], gaps: sideGaps(1) }, // east
      { from: [-HALF_X, -line(HALF_Z)], to: [HALF_X, -line(HALF_Z)], gaps: [gap(HALF_X)] }, // north
      { from: [-HALF_X, line(HALF_Z)], to: [HALF_X, line(HALF_Z)] }, // south
    ],
    HEDGE_THICKNESS,
  ),
);

for (const opening of openings) {
  const model = BUILDERS[opening.kind](opening.game ? GAMES[opening.game].title : 'Coming soon');
  model.position.set(opening.x, 0, opening.z);
  model.rotation.y = opening.facing;
  model.scale.setScalar(opening.size ?? 1);
  scene.add(model);
}

// The woods all round, kept off the side paths (so they lead away into the trees) and away from
// the camera behind the south end.
scene.add(
  growWoods({
    backFromHedge: (x, z) => Math.max(Math.abs(x) - HALF_X - 0.8, Math.abs(z) - HALF_Z - 0.8),
    reach: BACKDROP_RADIUS - 2,
    keepClear: (x, z) => z > HALF_Z - 1 || pathDistance(x, z) < 1.2,
    seed: 23,
  }),
);

// Things to bump into: lanterns along the path, and rocks you can jump onto.
const obstacles = [];
for (let z = HALF_Z - 6, side = 1; z > -HALF_Z + 4; z -= LANTERN_SPACING, side = -side) {
  if (openings.some((o) => o.side !== 0 && Math.abs(o.z - z) < 3.5)) continue; // Not in front of an opening.
  const lantern = makeLantern();
  const x = pathX(z) + side * (PATH_HALF_WIDTH + 0.7);
  lantern.position.set(x, 0, z);
  lantern.rotation.y = side > 0 ? Math.PI : 0; // Hanging out over the path.
  scene.add(lantern);
  obstacles.push({ position: lantern.position, radius: 0.12, height: Infinity });
}
for (let i = 0; i < ROCK_COUNT; i++) {
  // Along the hedges, spread down the Glenn, never in front of an opening.
  const z = HALF_Z - 4 - ((i + 0.5) / ROCK_COUNT) * (HALL_LENGTH - 10);
  const side = i % 2 === 0 ? 1 : -1;
  if (openings.some((o) => o.side === side && Math.abs(o.z - z) < 3)) continue;
  const rock = makeRock();
  const width = 0.55 + 0.25 * ((i * 0.618) % 1);
  const height = 0.5 + 0.2 * ((i * 0.382) % 1);
  rock.scale.set(width, height, width);
  rock.position.set(side * (INNER_X - 1.1 - ((i * 0.618) % 1) * 1.2), 0, z);
  rock.rotation.y = i * 2.4;
  scene.add(rock);
  obstacles.push({ position: rock.position, radius: 0.9 * width, height: 0.93 * height });
}

// --- The gnome and the fox ---

const gnome = createGnome();
const player = gnome.model;
scene.add(player);
const walker = createWalker({ gnome, camera, floorAt: floorUnderGnome, pushOut: bumpIntoObstacles, keepIn: keepInGlenn });

const fox = createFox();
scene.add(fox.model);
let foxSide = -1;

function floorUnderGnome() {
  let floor = 0;
  for (const obstacle of obstacles) {
    const distance = Math.hypot(player.position.x - obstacle.position.x, player.position.z - obstacle.position.z);
    if (distance < obstacle.radius * 0.7 && player.position.y >= obstacle.height - 0.05) floor = Math.max(floor, obstacle.height);
  }
  return floor;
}

function bumpIntoObstacles(position) {
  for (const obstacle of obstacles) pushOutOf(position, obstacle, 0.3, player.position.y);
}

function pushOutOf(position, obstacle, radius, y) {
  if (y >= obstacle.height - 0.05) return;
  const dx = position.x - obstacle.position.x;
  const dz = position.z - obstacle.position.z;
  const distance = Math.hypot(dx, dz);
  const closestAllowed = obstacle.radius + radius;
  if (distance > 0 && distance < closestAllowed) {
    position.x = obstacle.position.x + (dx / distance) * closestAllowed;
    position.z = obstacle.position.z + (dz / distance) * closestAllowed;
  }
}

function keepInGlenn(position, radius) {
  position.x = THREE.MathUtils.clamp(position.x, -INNER_X + radius, INNER_X - radius);
  position.z = THREE.MathUtils.clamp(position.z, -INNER_Z + radius, INNER_Z - radius);
}

// The fox trots along beside the gnome, swapping sides if it would end up in the hedge.
function updateFox(dt) {
  const spot = fox.model.position;
  if (Math.abs(spot.x - player.position.x) > 0.8) foxSide = Math.sign(spot.x - player.position.x);
  if (Math.abs(player.position.x + foxSide * FOX_SIDE_GAP) > INNER_X - FOX_RADIUS) foxSide = -foxSide;
  const goalX = player.position.x + foxSide * FOX_SIDE_GAP;
  const goalZ = player.position.z + 0.6;
  const distance = Math.hypot(goalX - spot.x, goalZ - spot.z);
  let speed = 0;
  let facing = Math.atan2(player.position.x - spot.x, player.position.z - spot.z); // Look at its friend.
  if (distance > 0.3) {
    speed = Math.min(FOX_FOLLOW_SPEED, distance * 2.5); // Trot faster the further behind it is.
    facing = Math.atan2(goalX - spot.x, goalZ - spot.z);
    const step = Math.min(speed * dt, distance);
    spot.x += ((goalX - spot.x) / distance) * step;
    spot.z += ((goalZ - spot.z) / distance) * step;
  }
  for (const obstacle of obstacles) pushOutOf(spot, obstacle, FOX_RADIUS, 0);
  keepInGlenn(spot, FOX_RADIUS);
  fox.model.rotation.y += shortestTurn(facing - fox.model.rotation.y) * (1 - Math.exp(-8 * dt));
  fox.animate(dt, { speed, sniffing: false });
}

// --- Going into the openings ---

let near = null; // The opening the gnome is standing at, if any.
let offering = null; // The opening whose game card is showing, waiting for a second press.
let controllerButtons = false; // Whether the prompt shows the controller's buttons (or the keyboard's).
let worldTime = 0;

// The opening the gnome is close enough to, if any.
function openingAt() {
  let best = null;
  let bestDistance = INTERACT_RANGE;
  for (const opening of openings) {
    const distance = Math.hypot(player.position.x - opening.spot.x, player.position.z - opening.spot.z);
    if (distance < bestDistance) {
      best = opening;
      bestDistance = distance;
    }
  }
  return best;
}

// The prompt at the bottom of the screen: which button to press, and what's there.
function showPrompt() {
  promptEl.hidden = !near || offering !== null;
  if (!near) return;
  controllerButtons = isUsingController();
  promptKey.textContent = controllerButtons ? '□' : 'F';
  promptText.textContent = near.game ? GAMES[near.game].title : 'Coming soon';
}

// The game's card: its name, what to do, the best time so far, and "press again to play".
function openCard(opening) {
  offering = opening;
  const game = GAMES[opening.game];
  const best = woods.bestTimeOf?.(opening.game);
  cardTitle.textContent = game.title;
  cardBlurb.textContent = game.blurb;
  cardBest.textContent = best ? `Best time: ${formatTime(best.time)}, by ${best.name}` : 'No best time yet. Be the first!';
  cardPlayKey.textContent = isUsingController() ? '□' : 'F';
  cardCloseKey.textContent = isUsingController() ? '○' : 'Esc';
  card.hidden = false;
  showPrompt();
}

function closeCard() {
  offering = null;
  card.hidden = true;
  showPrompt();
}

function play(opening) {
  closeCard();
  promptEl.hidden = true;
  woods.onPlay?.(opening.game);
}

card.addEventListener('click', (event) => {
  const button = event.target.closest('button');
  if (button?.dataset.portal === 'play' && offering) play(offering);
  if (button?.dataset.portal === 'close') closeCard();
  button?.blur();
});

// --- Every frame ---

function update(dt, controls) {
  worldTime += dt;
  flickerLanterns(worldTime);
  walker.update(dt, controls);
  updateFox(dt);

  // Walking up to an opening shows its prompt; walking away puts away its card too.
  const here = openingAt();
  if (here !== near) {
    near = here;
    if (offering && offering !== near) closeCard();
    showPrompt();
  } else if (near && isUsingController() !== controllerButtons) {
    showPrompt(); // Switched between keyboard and controller: show the right button.
  }
  if (controls.back && offering) closeCard();
  // F (or □): at an opening, the first press shows what's there and the second goes in.
  // Anywhere else, the gnome swings its stick, just for fun.
  if (controls.swing) {
    if (offering) play(offering);
    else if (near?.game) openCard(near);
    else if (near) showToast("This way isn't open yet. Come back soon!");
    else if (gnome.swingStick()) playSwing();
  }
  walker.followCamera(dt);
}

// The woods as an area of Lanternwood (see main.js).
export const woods = {
  name: 'The Glenn',
  scene,
  camera,
  update,
  onPlay: null, // Set by main.js: what to do when the player goes into a game...
  bestTimeOf: null, // ...and how to find a game's best time ({ name, time }), for its card.
  // Arrive at the south end, or (coming back from a game) in front of that game's opening.
  enter({ from = null, quiet = false } = {}) {
    const back = openings.find((opening) => opening.game === from);
    if (back) walker.place(back.spot.x, back.spot.z, back.facing);
    else walker.place(pathX(START_Z), START_Z, Math.PI);
    fox.model.position.set(player.position.x - FOX_SIDE_GAP, 0, player.position.z + 0.6);
    keepInGlenn(fox.model.position, FOX_RADIUS);
    near = null;
    closeCard();
    if (!quiet) showBanner('The Glenn', 'Lanternwood');
  },
  leave() {
    closeCard();
    promptEl.hidden = true;
    hideBanner();
  },
  canPause: () => true,
  // Esc (or ○) puts away the game card before it would open the pause menu.
  dismiss() {
    if (!offering) return false;
    closeCard();
    return true;
  },
};
