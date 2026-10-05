import * as THREE from 'three';
import { createGnome } from './gnome.js';
import { createFox } from './fox.js';
import { createWalker, shortestTurn } from './walker.js';
import { growWoods } from './scenery.js';
import { createBackdrop, SKY_COLOR, HAZE_COLOR } from './backdrop.js';
import { makeLantern, setLanternLit, flickerLanterns } from './lantern.js';
import { makeGardenDoor, DOORWAY, DOOR_WALL } from './gates.js';
import { LANDMARKS, animateLandmark } from './landmarks.js';
import { showBanner, setBannerSubtitle, hideBanner } from './banner.js';
import { createBoard, formatTime } from './scoreboard.js';
import { playSwing, playLanternLit, playEscape } from './sounds.js';

// The Bramble Maze: Lanternwood's second game. You start by the old tree in the middle of a tall
// garden maze and have to find the one way out. Every round is a new maze, made up on the spot,
// with long hallways, twisty turns, dead ends and the odd loop. To help you find your way, the way
// a well-planned town does (with districts, landmarks and paths you can recognize):
//   - Each corner of the maze is its own garden, with its own flowers and path color.
//   - Every dead end has something you'll remember: a sundial, a wishing well, a scarecrow...
//   - Lanterns at the crossings light up once you've been there, so you can see where you've been.
//   - The giant old tree marks the middle, and the bell tower stands to the north, above the hedges.
// The hedges are taller than the camera, so you can't see over them.

// Tweak these to change the maze.
const CELLS = 15; // The maze is this many stretches of path across, each way.
const CELL = 3.2; // How wide each stretch of path is, wall to wall.
const HEDGE_HEIGHT = 3.4; // Taller than the camera, so you can't see over.
const HEDGE_THICKNESS = 0.9;
// The shortest way out is this many stretches long: about 24 to 34 seconds of walking. With the
// wrong turns everyone takes, that makes escaping take one to three minutes. (Tested by sending a
// pretend player, who explores one new passage at a time, through 100 mazes: 40s when lucky, 72s
// usually, 124s when unlucky, at full speed without ever stopping to look around.)
const PATH_TO_EXIT = [60, 85];
const STRAIGHT_CHANCE = 0.4; // How often a passage carries straight on, making long hallways.
const LOOP_CHANCE = 0.1; // How many dead ends get opened into loops, so it isn't all dead ends.
const LANDMARK_GAP = 4; // Landmarks stand at least this many stretches apart.
const READY_TIME = 1.6; // Seconds of "Ready..." before the clock starts.
const RESULTS_DELAY = 1.8; // Seconds to enjoy getting out before the Top 10 board comes up.
const CAMERA_DISTANCE = 4.6;
const CAMERA_HEIGHT = 2.5; // Below the tops of the hedges.
const CAMERA_TURN_SPEED = 2.4; // Turning the camera with Q and E (or the right stick), in radians a second.
const CAMERA_FOLLOW = 1.8; // How quickly the camera swings round behind the gnome as it walks.
const ESCAPE_DISTANCE = 1.3; // How far out through the door counts as escaped.

// The four gardens, one in each corner: north-east, north-west, south-west and south-east.
const DISTRICTS = [
  { name: 'Rose Walk', leaves: 0x3f7f3c, flowers: [0xe0577c, 0xc8325f, 0xf2a9cc], shape: 'bloom', ground: 0xcbb489 },
  { name: 'Lavender Lane', leaves: 0x587f55, flowers: [0x9a7fd8, 0x8a6cc9, 0xb39ae3], shape: 'spike', ground: 0xc9c2b2 },
  { name: 'Marigold Row', leaves: 0x4a8236, flowers: [0xf3c341, 0xe8962e, 0xf6dd6a], shape: 'bloom', ground: 0x98b06a },
  { name: 'Bluebell Dell', leaves: 0x2f6c40, flowers: [0x6f8fe0, 0x8fb4ea, 0xb7c9f2], shape: 'bell', ground: 0x7cae60 },
];
const PLAZA_GROUND = 0xd8d0bf; // The paved clearing round the old tree.

const HALF = (CELLS * CELL) / 2; // From the middle to the outside of the maze.
const MIDDLE = (CELLS - 1) / 2; // The middle cell.
const DIRECTIONS = [
  { bit: 1, di: 0, dj: -1 }, // north
  { bit: 2, di: 1, dj: 0 }, // east
  { bit: 4, di: 0, dj: 1 }, // south
  { bit: 8, di: -1, dj: 0 }, // west
];
const opposite = (bit) => (bit << 2) % 15; // North (1) and south (4), east (2) and west (8).

const timerEl = document.getElementById('timer');
const districtEl = document.getElementById('district');
const districtPill = document.getElementById('district-pill');

// The Top 10 for the maze: the fastest ways out.
const board = createBoard({
  saveAs: 'maze-top-10',
  title: 'Top 10 Maze Escapers',
  emblem: 'key-sprig',
  done: 'You found the way out in',
  thanks: 'Well found',
});

// --- Scene, camera and light ---

const scene = new THREE.Scene();
scene.background = new THREE.Color(SKY_COLOR);
scene.fog = new THREE.Fog(HAZE_COLOR, 25, 90);
const camera = new THREE.PerspectiveCamera(65, window.innerWidth / window.innerHeight, 0.1, 200);

// Warm, low, late-afternoon sun, so the hedges cast long shadows across the paths.
scene.add(new THREE.HemisphereLight(0xfff4e0, 0x4a6a40, 1.15));
const sun = new THREE.DirectionalLight(0xffe2b8, 2.2);
sun.position.set(-14, 18, 10);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
Object.assign(sun.shadow.camera, { left: -HALF - 4, right: HALF + 4, top: HALF + 4, bottom: -HALF - 4, far: 80 });
scene.add(sun);

const backdrop = createBackdrop({ radius: HALF * Math.SQRT2 + 10 });
backdrop.rotation.y = Math.PI; // Another part of the painting again.
scene.add(backdrop);

// --- Where things are ---

const cellCenter = (index) => (index - MIDDLE) * CELL;
const inPlaza = (i, j) => Math.abs(i - MIDDLE) <= 1 && Math.abs(j - MIDDLE) <= 1;
function districtAt(x, z) {
  if (Math.hypot(x, z) < CELL * 1.6) return null; // The clearing in the middle.
  return x >= 0 ? (z < 0 ? 0 : 3) : z < 0 ? 1 : 2;
}

// --- The ground, and the big things that don't change from round to round ---

// The ground: each garden's path its own color, a paved clearing in the middle, grass outside.
function makeGround() {
  const size = HALF * 2 + 40;
  const geometry = new THREE.PlaneGeometry(size, size, 180, 180).rotateX(-Math.PI / 2);
  const positions = geometry.attributes.position;
  const colors = new Float32Array(positions.count * 3);
  const grass = new THREE.Color(0x55aa55);
  const color = new THREE.Color();
  for (let i = 0; i < positions.count; i++) {
    const x = positions.getX(i);
    const z = positions.getZ(i);
    const patch = Math.sin(x * 0.31) * Math.sin(z * 0.27) + 0.6 * Math.sin(x * 0.11 - z * 0.15);
    const inside = Math.max(Math.abs(x), Math.abs(z)) < HALF;
    const district = districtAt(x, z);
    color.set(!inside ? grass : district === null ? PLAZA_GROUND : DISTRICTS[district].ground);
    color.offsetHSL(0, 0, patch * 0.03);
    color.toArray(colors, i * 3);
  }
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geometry.computeVertexNormals();
  const ground = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1 }));
  ground.receiveShadow = true;
  return ground;
}
scene.add(makeGround());

// The giant old tree in the middle, taller than everything, with a rope swing.
const SWING_X = 2.6;
function makeOldTree() {
  const bark = new THREE.MeshStandardMaterial({ color: 0x5e4c3c, roughness: 0.95 });
  const leaves = [0x3f7f3c, 0x4b8f45, 0x5a9e4c].map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.8, flatShading: true }));
  const tree = new THREE.Group();
  const add = (geometry, material, x, y, z) => {
    const part = new THREE.Mesh(geometry, material);
    part.position.set(x, y, z);
    part.castShadow = true;
    tree.add(part);
    return part;
  };
  add(new THREE.CylinderGeometry(0.55, 0.95, 7, 10), bark, 0, 3.5, 0);
  for (let i = 0; i < 5; i++) {
    const root = add(new THREE.ConeGeometry(0.3, 1.4, 6), bark, Math.cos(i * 1.3) * 0.8, 0.3, Math.sin(i * 1.3) * 0.8);
    root.rotation.set(Math.sin(i * 1.3) * 1.1, 0, -Math.cos(i * 1.3) * 1.1);
  }
  const canopy = [[0, 8.4, 0, 3.4], [2.4, 7.4, 0.6, 2.4], [-2.2, 7.6, -0.8, 2.5], [0.6, 7.2, 2.3, 2.2], [-0.8, 7.3, -2.4, 2.2], [0.3, 10.2, 0.2, 2.2]];
  canopy.forEach(([x, y, z, r], i) => add(new THREE.IcosahedronGeometry(r, 1).scale(1, 0.8, 1), leaves[i % 3], x, y, z));
  // A branch reaching east, with a rope swing hanging from it.
  const branch = add(new THREE.CylinderGeometry(0.12, 0.22, 3, 7), bark, 1.4, 5.6, 0);
  branch.rotation.z = -1.25;
  const rope = new THREE.MeshStandardMaterial({ color: 0xc9b083, roughness: 1 });
  for (const z of [-0.35, 0.35]) add(new THREE.CylinderGeometry(0.02, 0.02, 4.4), rope, SWING_X, 3.6, z);
  add(new THREE.BoxGeometry(0.3, 0.07, 0.9), new THREE.MeshStandardMaterial({ color: 0x8b6a43 }), SWING_X, 1.4, 0);
  return tree;
}
scene.add(makeOldTree());

// An old stone bell tower beyond the north side of the maze: look for it above the hedges.
function makeBellTower() {
  const tower = new THREE.Group();
  const stone = new THREE.MeshStandardMaterial({ color: 0xbdb3a0, roughness: 0.95, flatShading: true });
  const add = (geometry, material, y) => {
    const part = new THREE.Mesh(geometry, material);
    part.position.y = y;
    part.castShadow = true;
    tower.add(part);
  };
  add(new THREE.BoxGeometry(3.4, 11, 3.4), stone, 5.5);
  add(new THREE.BoxGeometry(3.8, 0.4, 3.8), stone, 11.2);
  add(new THREE.BoxGeometry(3.2, 3, 3.2), stone, 12.9);
  add(new THREE.BoxGeometry(3.3, 1.8, 2.2), new THREE.MeshStandardMaterial({ color: 0x3b3128 }), 12.8);
  add(new THREE.BoxGeometry(2.2, 1.8, 3.3), new THREE.MeshStandardMaterial({ color: 0x3b3128 }), 12.8);
  add(new THREE.SphereGeometry(0.6, 12, 8, 0, Math.PI * 2, 0, Math.PI / 1.6), new THREE.MeshStandardMaterial({ color: 0xc9a24a, metalness: 0.6, roughness: 0.4 }), 12.6);
  add(new THREE.ConeGeometry(2.8, 3.6, 4).rotateY(Math.PI / 4), new THREE.MeshStandardMaterial({ color: 0x9b4a32, roughness: 0.8, flatShading: true }), 16.2);
  // A lit window, halfway up, facing the maze.
  const lit = new THREE.Mesh(new THREE.PlaneGeometry(0.6, 1), new THREE.MeshStandardMaterial({ color: 0xffd27a, emissive: 0xffa040, emissiveIntensity: 0.9 }));
  lit.position.set(0, 7, 1.71);
  tower.add(lit);
  tower.position.set(0, 0, -HALF - 9);
  return tower;
}
scene.add(makeBellTower());

// Woods outside the maze, beyond a ring of lawn, to see when you get out.
scene.add(
  growWoods({
    backFromHedge: (x, z) => Math.max(Math.abs(x), Math.abs(z)) - HALF - 5,
    reach: HALF * Math.SQRT2 + 8,
    keepClear: (x, z) => Math.hypot(x, z + HALF + 9) < 5, // Round the bell tower.
    seed: 31,
  }),
);

// The way out: an old garden door, standing open, with the fox waiting just outside.
const exitDoor = makeGardenDoor('Way Out', { open: true });
scene.add(exitDoor);
const fox = createFox();
scene.add(fox.model);

// The landmarks, built once and moved to new dead ends for each maze.
const landmarks = LANDMARKS.map((landmark) => ({ ...landmark, model: landmark.build() }));
for (const { model } of landmarks) scene.add(model);
const lanterns = []; // Junction lanterns, made as needed and reused.

// --- The gnome ---

const gnome = createGnome();
const player = gnome.model;
scene.add(player);
const walker = createWalker({
  gnome,
  camera,
  floorAt: floorUnderGnome,
  pushOut: (position) => pushOutOfEverything(position, 0.3, player.position.y),
  keepIn: (position) => {
    position.x = THREE.MathUtils.clamp(position.x, -HALF - 4, HALF + 4);
    position.z = THREE.MathUtils.clamp(position.z, -HALF - 4, HALF + 4);
  },
});

// --- Making a maze ---

let maze = null; // { open, exit, walls (boxes to bump into), lanternSpots }
let hedges = null; // The hedges' meshes, remade for each maze.
const obstacles = []; // Round things to bump into: the old tree, landmarks, lantern posts.

// Carve a maze through the grid of cells, starting from the middle. `open[i][j]` holds which
// sides of each cell are open (north 1, east 2, south 4, west 8). It's a "depth-first" maze: a
// path wanders off as far as it can, then backs up to the last fork and tries another way, which
// gives long winding passages with dead ends off them.
function carveMaze() {
  const open = Array.from({ length: CELLS }, () => new Array(CELLS).fill(0));
  const visited = Array.from({ length: CELLS }, () => new Array(CELLS).fill(false));
  const inside = (i, j) => i >= 0 && j >= 0 && i < CELLS && j < CELLS;
  const join = (i, j, direction) => {
    open[i][j] |= direction.bit;
    open[i + direction.di][j + direction.dj] |= opposite(direction.bit);
  };
  const stack = [{ i: MIDDLE, j: MIDDLE, last: null }];
  visited[MIDDLE][MIDDLE] = true;
  while (stack.length) {
    const { i, j, last } = stack[stack.length - 1];
    const choices = DIRECTIONS.filter((d) => inside(i + d.di, j + d.dj) && !visited[i + d.di][j + d.dj]);
    if (choices.length === 0) {
      stack.pop();
      continue;
    }
    // Sometimes carry straight on, for long hallways; otherwise turn any way.
    const direction = choices.includes(last) && Math.random() < STRAIGHT_CHANCE ? last : choices[Math.floor(Math.random() * choices.length)];
    join(i, j, direction);
    visited[i + direction.di][j + direction.dj] = true;
    stack.push({ i: i + direction.di, j: j + direction.dj, last: direction });
  }
  // A passage always leads south out of the clearing, so the first view is down a path into the maze.
  join(MIDDLE, MIDDLE + 1, DIRECTIONS[2]);
  // Open up the clearing round the old tree, and knock through a few dead ends to make loops.
  for (let i = 0; i < CELLS; i++) {
    for (let j = 0; j < CELLS; j++) {
      for (const direction of DIRECTIONS) {
        const ni = i + direction.di;
        const nj = j + direction.dj;
        if (!inside(ni, nj)) continue;
        if (inPlaza(i, j) && inPlaza(ni, nj)) join(i, j, direction);
      }
      if (!inPlaza(i, j) && openings(open[i][j]) === 1 && Math.random() < LOOP_CHANCE) {
        const walls = DIRECTIONS.filter((d) => !(open[i][j] & d.bit) && inside(i + d.di, j + d.dj) && !inPlaza(i + d.di, j + d.dj));
        if (walls.length) join(i, j, walls[Math.floor(Math.random() * walls.length)]);
      }
    }
  }
  return open;
}

function openings(sides) {
  return DIRECTIONS.filter((d) => sides & d.bit).length;
}

// How many steps every cell is from the middle, along the paths.
function stepsFromMiddle(open) {
  const steps = Array.from({ length: CELLS }, () => new Array(CELLS).fill(Infinity));
  steps[MIDDLE][MIDDLE] = 0;
  const queue = [[MIDDLE, MIDDLE]];
  while (queue.length) {
    const [i, j] = queue.shift();
    for (const d of DIRECTIONS) {
      if (!(open[i][j] & d.bit)) continue;
      const ni = i + d.di;
      const nj = j + d.dj;
      if (steps[ni][nj] > steps[i][j] + 1) {
        steps[ni][nj] = steps[i][j] + 1;
        queue.push([ni, nj]);
      }
    }
  }
  return steps;
}

// Make a maze whose way out is the right distance away: a cell on the outside edge whose
// shortest path from the middle is within PATH_TO_EXIT. Try again if this maze hasn't one.
function makeMaze() {
  for (let attempt = 0; ; attempt++) {
    const open = carveMaze();
    const steps = stepsFromMiddle(open);
    const edgeCells = [];
    for (let k = 0; k < CELLS; k++) {
      edgeCells.push({ i: k, j: 0, side: DIRECTIONS[0] }, { i: CELLS - 1, j: k, side: DIRECTIONS[1] });
      edgeCells.push({ i: k, j: CELLS - 1, side: DIRECTIONS[2] }, { i: 0, j: k, side: DIRECTIONS[3] });
    }
    const [shortest, longest] = PATH_TO_EXIT;
    let fits = edgeCells.filter(({ i, j }) => steps[i][j] >= shortest && steps[i][j] <= longest);
    if (fits.length === 0 && attempt < 30) continue;
    // (After many tries, settle for the edge cell closest to the right distance.)
    if (fits.length === 0) fits = [edgeCells.sort((a, b) => Math.abs(steps[a.i][a.j] - shortest) - Math.abs(steps[b.i][b.j] - shortest))[0]];
    const exit = fits[Math.floor(Math.random() * fits.length)];
    open[exit.i][exit.j] |= exit.side.bit;
    return { open, steps, exit };
  }
}

// --- Building it ---

// The hedge walls, as boxes (for bumping into) and as leafy shapes (to draw). Walls along the
// same line join up into one long hedge, except where one garden meets the next.
function buildWalls(open) {
  const runs = [];
  // Walls running east-west: on the north side of each row of cells, plus the south edge.
  for (let j = 0; j <= CELLS; j++) {
    let run = null;
    for (let i = 0; i <= CELLS; i++) {
      const z = (j - CELLS / 2) * CELL;
      const x = (i + 0.5 - CELLS / 2) * CELL;
      const closed = i < CELLS && (j === CELLS ? !(open[i][CELLS - 1] & 4) : !(open[i][j] & 1));
      const district = districtAt(x, z - Math.sign(z || 1) * 0.1);
      if (closed && run && run.district === district) run.to = x + CELL / 2;
      else {
        if (run) runs.push(run);
        run = closed ? { alongX: true, line: z, from: x - CELL / 2, to: x + CELL / 2, district } : null;
      }
    }
  }
  // Walls running north-south: on the west side of each column of cells, plus the east edge.
  for (let i = 0; i <= CELLS; i++) {
    let run = null;
    for (let j = 0; j <= CELLS; j++) {
      const x = (i - CELLS / 2) * CELL;
      const z = (j + 0.5 - CELLS / 2) * CELL;
      const closed = j < CELLS && (i === CELLS ? !(open[CELLS - 1][j] & 2) : !(open[i][j] & 8));
      const district = districtAt(x - Math.sign(x || 1) * 0.1, z);
      if (closed && run && run.district === district) run.to = z + CELL / 2;
      else {
        if (run) runs.push(run);
        run = closed ? { alongX: false, line: x, from: z - CELL / 2, to: z + CELL / 2, district } : null;
      }
    }
  }
  // As boxes on the ground: the hedge reaches half its thickness past each end, to fill the corners.
  const half = HEDGE_THICKNESS / 2;
  return runs.map((run) => {
    const box = run.alongX
      ? { minX: run.from - half, maxX: run.to + half, minZ: run.line - half, maxZ: run.line + half }
      : { minX: run.line - half, maxX: run.line + half, minZ: run.from - half, maxZ: run.to + half };
    return { ...run, ...box };
  });
}

// Draw the hedges: a solid core, lumpy leaves along the top and both faces, and each garden's flowers.
const unitBox = new THREE.BoxGeometry(1, 1, 1);
const leafBlob = new THREE.IcosahedronGeometry(1, 1);
const bloom = new THREE.IcosahedronGeometry(1, 0);
const spike = new THREE.ConeGeometry(0.06, 0.4, 5);
const bell = new THREE.ConeGeometry(0.1, 0.16, 6).rotateX(Math.PI);
const hedgeMaterial = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.85, flatShading: true });

function buildHedges(walls) {
  const cores = [];
  const blobs = [];
  const flowers = { bloom: [], spike: [], bell: [] };
  const color = new THREE.Color();
  for (const wall of walls) {
    const district = wall.district === null ? DISTRICTS[0] : DISTRICTS[wall.district];
    const length = wall.to - wall.from + HEDGE_THICKNESS;
    const middle = (wall.from + wall.to) / 2;
    const at = (along, across, y) => (wall.alongX ? new THREE.Vector3(along, y, wall.line + across) : new THREE.Vector3(wall.line + across, y, along));
    cores.push({
      position: at(middle, 0, HEDGE_HEIGHT / 2 - 0.15),
      size: wall.alongX ? new THREE.Vector3(length, HEDGE_HEIGHT - 0.3, HEDGE_THICKNESS - 0.1) : new THREE.Vector3(HEDGE_THICKNESS - 0.1, HEDGE_HEIGHT - 0.3, length),
      color: color.set(district.leaves).multiplyScalar(0.8).clone(),
    });
    const steps = Math.max(2, Math.round(length / 0.7));
    for (let s = 0; s <= steps; s++) {
      const along = wall.from - HEDGE_THICKNESS / 2 + (s / steps) * length;
      const shade = () => color.set(district.leaves).multiplyScalar(0.85 + 0.3 * Math.random()).clone();
      blobs.push({ position: at(along, 0, HEDGE_HEIGHT - 0.1 - Math.random() * 0.15), size: 0.5 + Math.random() * 0.2, color: shade() });
      for (const face of [-1, 1]) {
        const y = 0.5 + Math.random() * (HEDGE_HEIGHT - 1);
        blobs.push({ position: at(along, face * (HEDGE_THICKNESS / 2 - 0.22), y), size: 0.3 + Math.random() * 0.12, color: shade() });
        if (Math.random() < 0.45) {
          const flowerY = 0.4 + Math.random() * (HEDGE_HEIGHT - 0.9);
          const flowerColor = color.set(district.flowers[Math.floor(Math.random() * district.flowers.length)]).clone();
          flowers[district.shape].push({ position: at(along + (Math.random() - 0.5) * 0.4, face * (HEDGE_THICKNESS / 2 + 0.12), flowerY), size: 1, color: flowerColor });
        }
      }
    }
  }
  const group = new THREE.Group();
  group.add(
    instanced(unitBox, cores, (item) => item.size, false),
    instanced(leafBlob, blobs, (item) => new THREE.Vector3().setScalar(item.size)),
    instanced(bloom, flowers.bloom, () => new THREE.Vector3().setScalar(0.11)),
    instanced(spike, flowers.spike, () => new THREE.Vector3(1, 1, 1)),
    instanced(bell, flowers.bell, () => new THREE.Vector3(1, 1, 1)),
  );
  return group;
}

// One shape drawn for every item, each with its own spot, size and color. Unless `turned` is false
// (for the straight hedge cores), each is also turned a golden angle from the last, so no two lumps match.
function instanced(geometry, items, sizeOf, turned = true) {
  const mesh = new THREE.InstancedMesh(geometry, hedgeMaterial, Math.max(items.length, 1));
  mesh.count = items.length;
  const matrix = new THREE.Matrix4();
  const turn = new THREE.Quaternion();
  items.forEach((item, i) => {
    turn.setFromAxisAngle(THREE.Object3D.DEFAULT_UP, turned ? i * 2.39996 : 0);
    mesh.setMatrixAt(i, matrix.compose(item.position, turn, sizeOf(item)));
    mesh.setColorAt(i, item.color);
  });
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  return mesh;
}

// Put the landmarks in dead ends, spread out across the maze, each facing back up its passage.
function placeLandmarks(open) {
  const deadEnds = [];
  for (let i = 0; i < CELLS; i++) {
    for (let j = 0; j < CELLS; j++) {
      if (!inPlaza(i, j) && openings(open[i][j]) === 1 && !(i === maze.exit.i && j === maze.exit.j)) deadEnds.push({ i, j });
    }
  }
  const chosen = [];
  shuffle(deadEnds);
  for (const spot of deadEnds) {
    if (chosen.length === landmarks.length) break;
    if (chosen.every((other) => Math.abs(other.i - spot.i) + Math.abs(other.j - spot.j) >= LANDMARK_GAP)) chosen.push(spot);
  }
  shuffle(landmarks);
  landmarks.forEach((landmark, k) => {
    const spot = chosen[k];
    landmark.model.visible = Boolean(spot);
    if (!spot) return;
    const way = DIRECTIONS.find((d) => open[spot.i][spot.j] & d.bit); // The way back out.
    const x = cellCenter(spot.i) - way.di * 0.35;
    const z = cellCenter(spot.j) - way.dj * 0.35;
    landmark.model.position.set(x, 0, z);
    landmark.model.rotation.y = Math.atan2(way.di, way.dj);
    obstacles.push({ position: landmark.model.position, radius: landmark.radius, height: landmark.height });
  });
}

// A lantern at every crossing (three or more ways on), unlit until you get there.
function placeLanterns(open) {
  let used = 0;
  for (let i = 0; i < CELLS; i++) {
    for (let j = 0; j < CELLS; j++) {
      if (inPlaza(i, j) || openings(open[i][j]) < 3) continue;
      if (!lanterns[used]) {
        const lantern = makeLantern({ lit: false });
        scene.add(lantern);
        lanterns.push(lantern);
      }
      const lantern = lanterns[used++];
      // In the corner of the crossing with hedge on both sides, hanging in toward the middle.
      const corner = [[1, -1], [1, 1], [-1, 1], [-1, -1]].find(([sx, sz]) => {
        const sideX = sx > 0 ? 2 : 8;
        const sideZ = sz > 0 ? 4 : 1;
        return !(open[i][j] & sideX) || !(open[i][j] & sideZ);
      }) ?? [1, -1];
      const reach = CELL / 2 - HEDGE_THICKNESS / 2 - 0.22;
      lantern.position.set(cellCenter(i) + corner[0] * reach, 0, cellCenter(j) + corner[1] * reach);
      lantern.rotation.y = Math.atan2(corner[1], -corner[0]);
      lantern.userData.cell = { i, j };
      lantern.userData.lit = false;
      setLanternLit(lantern.userData.lamp, false);
      lantern.visible = true;
      obstacles.push({ position: lantern.position, radius: 0.12, height: Infinity });
    }
  }
  for (let k = used; k < lanterns.length; k++) lanterns[k].visible = false;
}

// The open door in the gap where the way out is, facing in, and the fox waiting outside it.
let exitOut = new THREE.Vector3(); // Which way is out, through the door.
function placeExit() {
  const { i, j, side } = maze.exit;
  const x = cellCenter(i) + side.di * (CELL / 2);
  const z = cellCenter(j) + side.dj * (CELL / 2);
  exitOut = new THREE.Vector3(side.di, 0, side.dj);
  exitDoor.position.set(x, 0, z);
  exitDoor.rotation.y = Math.atan2(-side.di, -side.dj); // Its front faces back into the maze.
  // The stone wall on either side of the doorway is solid.
  const half = HEDGE_THICKNESS / 2;
  for (const end of [-1, 1]) {
    const middle = end * (DOORWAY / 2 + DOOR_WALL / 2) / 2;
    const reach = (DOOR_WALL - DOORWAY) / 4;
    maze.walls.push(
      side.di === 0
        ? { minX: x + middle - reach, maxX: x + middle + reach, minZ: z - half, maxZ: z + half }
        : { minX: x - half, maxX: x + half, minZ: z + middle - reach, maxZ: z + middle + reach },
    );
  }
  fox.model.position.set(x + side.di * 2.6 + side.dj * 1.7, 0, z + side.dj * 2.6 - side.di * 1.7); // Out of the doorway.
  fox.model.rotation.y = Math.atan2(-side.di, -side.dj);
}

function shuffle(list) {
  for (let i = list.length - 1; i > 0; i--) {
    const k = Math.floor(Math.random() * (i + 1));
    [list[i], list[k]] = [list[k], list[i]];
  }
  return list;
}

// A whole new maze: carve it, grow its hedges, and set out the landmarks, lanterns and way out.
function newMaze() {
  maze = makeMaze();
  maze.walls = buildWalls(maze.open);
  if (hedges) {
    scene.remove(hedges);
    for (const mesh of hedges.children) mesh.dispose();
  }
  hedges = buildHedges(maze.walls);
  scene.add(hedges);
  obstacles.length = 0;
  obstacles.push({ position: new THREE.Vector3(0, 0, 0), radius: 0.95, height: Infinity }); // The old tree...
  obstacles.push({ position: new THREE.Vector3(SWING_X, 0, 0), radius: 0.5, height: Infinity }); // ...and its swing.
  placeExit();
  placeLandmarks(maze.open);
  placeLanterns(maze.open);
}

// --- Bumping into things ---

function pushOutOfEverything(position, radius, y) {
  for (const wall of maze.walls) {
    const closestX = THREE.MathUtils.clamp(position.x, wall.minX, wall.maxX);
    const closestZ = THREE.MathUtils.clamp(position.z, wall.minZ, wall.maxZ);
    const dx = position.x - closestX;
    const dz = position.z - closestZ;
    const distance = Math.hypot(dx, dz);
    if (distance >= radius) continue;
    if (distance > 0) {
      position.x = closestX + (dx / distance) * radius;
      position.z = closestZ + (dz / distance) * radius;
    } else {
      // Right inside the hedge: step out the shortest way.
      const outs = [position.x - wall.minX + radius, wall.maxX - position.x + radius, position.z - wall.minZ + radius, wall.maxZ - position.z + radius];
      const shortest = Math.min(...outs);
      if (shortest === outs[0]) position.x = wall.minX - radius;
      else if (shortest === outs[1]) position.x = wall.maxX + radius;
      else if (shortest === outs[2]) position.z = wall.minZ - radius;
      else position.z = wall.maxZ + radius;
    }
  }
  for (const obstacle of obstacles) {
    if (y >= obstacle.height - 0.05) continue;
    const dx = position.x - obstacle.position.x;
    const dz = position.z - obstacle.position.z;
    const distance = Math.hypot(dx, dz);
    const closest = obstacle.radius + radius;
    if (distance > 0 && distance < closest) {
      position.x = obstacle.position.x + (dx / distance) * closest;
      position.z = obstacle.position.z + (dz / distance) * closest;
    }
  }
}

// The gnome can hop up onto the low landmarks (a toadstool, the tea bench...).
function floorUnderGnome() {
  let floor = 0;
  for (const obstacle of obstacles) {
    const distance = Math.hypot(player.position.x - obstacle.position.x, player.position.z - obstacle.position.z);
    if (distance < obstacle.radius * 0.7 && player.position.y >= obstacle.height - 0.05) floor = Math.max(floor, obstacle.height);
  }
  return floor;
}

// Is a point inside (or within `margin` of) a hedge, or the old tree's trunk? The camera uses this to stay out of them.
function inHedge(point, margin) {
  if (point.y > HEDGE_HEIGHT + 0.3) return false;
  if (Math.hypot(point.x, point.z) < 0.95 + margin) return true;
  return maze.walls.some((w) => point.x > w.minX - margin && point.x < w.maxX + margin && point.z > w.minZ - margin && point.z < w.maxZ + margin);
}

// --- The camera: low behind the gnome, turning with it ---

let cameraYaw = 0; // The way the camera looks: 0 is south, Math.PI is north.
const head = new THREE.Vector3();
const probe = new THREE.Vector3();
const cameraGoal = new THREE.Vector3();
const lookTarget = new THREE.Vector3();
let cameraReach = CAMERA_DISTANCE;
const steering = { moveX: 0, moveZ: 0, jump: false };

// Turn "forward" on the stick into "the way the camera is looking".
function steer(controls) {
  const back = cameraYaw + Math.PI; // The direction from the gnome to the camera.
  const c = Math.cos(back);
  const s = Math.sin(back);
  steering.moveX = controls.moveX * c + controls.moveZ * s;
  steering.moveZ = -controls.moveX * s + controls.moveZ * c;
  steering.jump = controls.jump;
  return steering;
}

function updateCamera(dt, controls, moving) {
  cameraYaw += controls.lookX * CAMERA_TURN_SPEED * dt;
  // As the gnome walks, the camera swings round behind it (unless it's walking toward the camera).
  if (moving && !controls.lookX) {
    const turn = shortestTurn(player.rotation.y - cameraYaw);
    if (Math.abs(turn) < 2.4) cameraYaw += turn * (1 - Math.exp(-CAMERA_FOLLOW * dt));
  }
  // Back out from the gnome's head until just before a hedge gets in the way.
  head.set(player.position.x, player.position.y + 1.1, player.position.z);
  const backX = -Math.sin(cameraYaw);
  const backZ = -Math.cos(cameraYaw);
  let reach = CAMERA_DISTANCE;
  for (let d = 0.5; d <= CAMERA_DISTANCE; d += 0.12) {
    probe.set(head.x + backX * d, CAMERA_HEIGHT, head.z + backZ * d);
    if (inHedge(probe, 0.3)) {
      reach = Math.max(d - 0.3, 0.6);
      break;
    }
  }
  // Pull in quickly (so a hedge never blocks the view), ease back out slowly.
  cameraReach = THREE.MathUtils.damp(cameraReach, reach, reach < cameraReach ? 25 : 3, dt);
  // Squeezed in close, it rises to look down over the gnome's hat (but never above the hedges).
  const squeeze = 1 - cameraReach / CAMERA_DISTANCE;
  cameraGoal.set(head.x + backX * cameraReach, player.position.y + CAMERA_HEIGHT + squeeze * 0.5, head.z + backZ * cameraReach);
  camera.position.lerp(cameraGoal, 1 - Math.exp(-12 * dt));
  // Look a little ahead of the gnome and up, so the sky (and the tree and the tower) show above the hedges.
  lookTarget.set(head.x - backX * 2, head.y + 0.5, head.z - backZ * 2);
  camera.lookAt(lookTarget);
}

function snapCamera() {
  cameraReach = CAMERA_DISTANCE;
  camera.position.set(player.position.x + Math.sin(cameraYaw) * -CAMERA_DISTANCE, CAMERA_HEIGHT, player.position.z - Math.cos(cameraYaw) * CAMERA_DISTANCE);
  updateCamera(1, { lookX: 0 }, false);
}

// --- The round ---

let elapsed = 0;
let worldTime = 0;
let finished = false;
let readyIn = 0;
let resultsIn = 0;
let district = null;
const standStill = { moveX: 0, moveZ: 0, jump: false, swing: false, restart: false, pause: false, lookX: 0 };

function restart() {
  board.hide();
  hideBanner();
  newMaze();
  // Start in the clearing by the old tree in the middle, looking south down a path into the maze.
  cameraYaw = 0;
  walker.place(0, CELL * 1.3, 0);
  snapCamera();
  elapsed = 0;
  finished = false;
  readyIn = 0;
  resultsIn = 0;
  district = undefined;
  updateHud();
}

function updateHud() {
  timerEl.textContent = formatTime(elapsed);
  const here = districtAt(player.position.x, player.position.z);
  if (here !== district) {
    district = here;
    districtEl.textContent = here === null ? 'The Old Tree' : DISTRICTS[here].name;
    // The little flower on the pill turns that garden's color.
    districtPill.style.color = here === null ? '#8fbf6a' : `#${new THREE.Color(DISTRICTS[here].flowers[0]).getHexString()}`;
  }
}

function update(dt, controls) {
  worldTime += dt;
  flickerLanterns(worldTime);
  for (const { model } of landmarks) animateLandmark(model, worldTime);
  fox.animate(dt, { speed: 0, sniffing: false });

  const ready = readyIn <= 0;
  if (!ready) {
    readyIn -= dt;
    controls = standStill;
    if (readyIn <= 0) setBannerSubtitle('Go!', 0.8);
  }
  if (controls.restart || (finished && controls.pause)) restart();
  if (controls.swing && gnome.swingStick()) playSwing();

  const moving = Math.hypot(controls.moveX, controls.moveZ) > 0.1;
  walker.update(dt, steer(controls), !finished);
  updateCamera(dt, controls, moving && !finished);

  // Light the lantern at each crossing the first time the gnome gets there.
  for (const lantern of lanterns) {
    if (!lantern.visible || lantern.userData.lit) continue;
    const { i, j } = lantern.userData.cell;
    if (Math.abs(player.position.x - cellCenter(i)) < CELL / 2 && Math.abs(player.position.z - cellCenter(j)) < CELL / 2) {
      lantern.userData.lit = true;
      setLanternLit(lantern.userData.lamp, true);
      playLanternLit();
    }
  }

  // Out through the door: the round is won.
  if (!finished && ready) {
    const out = (player.position.x - exitDoor.position.x) * exitOut.x + (player.position.z - exitDoor.position.z) * exitOut.z;
    if (out > ESCAPE_DISTANCE) {
      finished = true;
      resultsIn = RESULTS_DELAY;
      playEscape();
      showBanner('You found the way out!', formatTime(elapsed), RESULTS_DELAY);
    }
  }
  if (resultsIn > 0) {
    resultsIn -= dt;
    if (resultsIn <= 0) board.show(elapsed);
  }
  if (!finished && ready) elapsed += dt;
  updateHud();
}

restart();

// The Bramble Maze as an area of Lanternwood (see main.js).
export const brambleMaze = {
  name: 'Bramble Maze',
  scene,
  camera,
  update,
  restart,
  // Coming in through the garden door: a fresh maze, with "Ready..." and "Go!".
  enter() {
    restart();
    readyIn = READY_TIME;
    showBanner('Bramble Maze', 'Ready…', 0);
  },
  leave() {
    board.hide();
    hideBanner();
  },
  canPause: () => !finished,
  roundInProgress: () => !finished && elapsed > 0,
  best: () => board.best(),
};
