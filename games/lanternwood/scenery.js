import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { creekDistance, CREEK_HALF_WIDTH } from './creek.js';
import { PHI, GOLDEN_ANGLE, goldenFraction, fibonacciLong } from './golden.js';
import { makeLantern } from './lantern.js';
import { LeafCardMaterial, leafCards, broadLeafTexture, needleTexture, hedgeLeafTexture } from './foliage.js';

// Trees, rocks, logs, the hedges around the field, and the woods outside it.

// --- Kinds of tree ---

// The size of a basic pine, before it's scaled up. The game sizes logs from these.
export const TREE_HEIGHT = 3.2;
export const TREE_RADIUS = 0.75; // Its widest point: the bottom cone of leaves.
export const TRUNK_DIAMETER = 0.32;

const trunkMaterial = new THREE.MeshStandardMaterial({ color: 0x7a5230, roughness: 0.9 });
const oakBarkMaterial = new THREE.MeshStandardMaterial({ color: 0x5e4c3c, roughness: 0.95 });

// Leaves: `kind` is 'broad' or 'needle', for the leaf clumps scattered over them (see addLeafCards).
function leaves(color, kind = 'broad') {
  const material = new THREE.MeshStandardMaterial({ color, roughness: 0.8, flatShading: true });
  material.userData.foliage = kind;
  return material;
}

// A lumpy ball of leaves of radius r at x, y, z. `stretch` makes it taller (above 1) or flatter (below 1).
function blob(r, x, y, z, stretch = 1) {
  return new THREE.IcosahedronGeometry(r, 1).scale(1, stretch, 1).translate(x, y, z);
}

// A branch: a tapering stick from one point to another.
function branch(from, to, bottomRadius, topRadius) {
  const direction = new THREE.Vector3().subVectors(to, from);
  const geometry = new THREE.CylinderGeometry(topRadius, bottomRadius, direction.length(), 6);
  geometry.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(THREE.Object3D.DEFAULT_UP, direction.normalize()));
  return geometry.translate((from.x + to.x) / 2, (from.y + to.y) / 2, (from.z + to.z) / 2);
}

// Each kind of tree is a list of [shape, material] parts with its base on the ground, plus:
//   blockRadius: how close you can get (the trunk, or the low branches of a pine),
//   canopyRadius: how far its leaves spread, and height: how tall it is.
// Pines' leaves come down low, so they block you wide. The others have their leaves up
// above the gnome's hat, so you can run underneath and only the trunk stops you.
const TREES = {
  // A pine: three cones of leaves, each narrower than the one below, so you can see past the tops.
  pine: {
    parts: [
      [new THREE.CylinderGeometry(0.12, TRUNK_DIAMETER / 2, 0.8, 8).translate(0, 0.4, 0), trunkMaterial],
      [new THREE.ConeGeometry(TREE_RADIUS, 1.4, 8).translate(0, 1.3, 0), leaves(0x2f7d3b, 'needle')],
      [new THREE.ConeGeometry(0.58, 1.2, 8).translate(0, 2.0, 0), leaves(0x2f7d3b, 'needle')],
      [new THREE.ConeGeometry(0.4, 1.0, 8).translate(0, TREE_HEIGHT - 0.5, 0), leaves(0x2f7d3b, 'needle')],
    ],
    blockRadius: 0.6,
    canopyRadius: TREE_RADIUS,
    height: TREE_HEIGHT,
  },

  // A round green leafy tree (only out in the woods).
  round: {
    parts: [
      [new THREE.CylinderGeometry(0.12, 0.16, 1.2, 8).translate(0, 0.6, 0), trunkMaterial],
      [blob(0.85, 0, 1.55, 0), leaves(0x5a9e45)],
      [blob(0.6, 0.35, 2.25, 0.1), leaves(0x5a9e45)],
    ],
    blockRadius: 0.3,
    canopyRadius: 1.1,
    height: 2.85,
  },

  // A red maple in autumn: a round crown in three shades of red.
  maple: {
    parts: [
      [new THREE.CylinderGeometry(0.1, 0.17, 1.9, 8).translate(0, 0.95, 0), trunkMaterial],
      [blob(0.85, 0, 2.45, 0), leaves(0xc63a2a)],
      [mergeGeometries([blob(0.6, 0.6, 2.2, 0.35), blob(0.5, -0.15, 3.05, -0.1)]), leaves(0xdb5a2c)],
      [blob(0.6, -0.55, 2.25, -0.3), leaves(0xa82b26)],
    ],
    blockRadius: 0.3,
    canopyRadius: 1.3,
    height: 3.55,
  },

  // A tulip poplar in autumn: tall and straight, with a narrow golden crown.
  poplar: {
    parts: [
      [new THREE.CylinderGeometry(0.09, 0.15, 2.4, 8).translate(0, 1.2, 0), trunkMaterial],
      [blob(0.7, 0, 2.6, 0, 1.35), leaves(0xe8b62e)],
      [blob(0.55, 0.12, 3.45, 0.05, 1.35), leaves(0xf3d150)],
      [blob(0.38, -0.05, 4.1, 0, 1.3), leaves(0xd99a22)],
    ],
    blockRadius: 0.28,
    canopyRadius: 0.8,
    height: 4.6,
  },

  // A sprawling live oak: a short, thick trunk, four great limbs reaching out sideways,
  // a wide flat canopy, and grey-green Spanish moss hanging down.
  oak: (() => {
    const limbs = [];
    const canopy = [[], []];
    const moss = [];
    for (let i = 0; i < 4; i++) {
      const angle = (i / 4) * Math.PI * 2 + 0.4;
      const end = new THREE.Vector3(Math.cos(angle) * 1.45, 1.95, Math.sin(angle) * 1.45);
      limbs.push(branch(new THREE.Vector3(0, 1.0, 0), end, 0.14, 0.07));
      canopy[i % 2].push(blob(0.95, end.x * 1.05, 2.25, end.z * 1.05, 0.5));
    }
    canopy[0].push(blob(1.05, 0, 2.5, 0, 0.55));
    for (let i = 0; i < 9; i++) {
      const angle = (i / 9) * Math.PI * 2;
      const out = 0.9 + (i % 3) * 0.45;
      moss.push(new THREE.ConeGeometry(0.05, 0.5, 4).rotateX(Math.PI).translate(Math.cos(angle) * out, 1.75, Math.sin(angle) * out));
    }
    return {
      parts: [
        [new THREE.CylinderGeometry(0.22, 0.32, 1.15, 8).translate(0, 0.57, 0), oakBarkMaterial],
        [mergeGeometries(limbs), oakBarkMaterial],
        [mergeGeometries(canopy[0]), leaves(0x4a6b37)],
        [mergeGeometries(canopy[1]), leaves(0x5a7d41)],
        [mergeGeometries(moss), new THREE.MeshStandardMaterial({ color: 0xa3b18f, roughness: 0.9 })],
      ],
      blockRadius: 0.4,
      canopyRadius: 2.5,
      height: 3.1,
    };
  })(),
};

// A tree for the field, of one kind ('pine', 'maple', 'poplar' or 'oak'). Each tree gets its own
// copy of its materials, so it can fade on its own when it's between the camera and the gnome.
// Its size facts and materials are kept in tree.userData.
export function makeTree(kind) {
  const { parts, blockRadius, canopyRadius, height } = TREES[kind];
  const tree = new THREE.Group();
  const materials = [];
  for (const [geometry, material] of parts) {
    const own = material.clone();
    own.transparent = true;
    materials.push(own);
    const part = new THREE.Mesh(geometry, own);
    part.castShadow = true;
    tree.add(part);
  }
  tree.userData = { kind, materials, blockRadius, canopyRadius, height };
  return tree;
}

// --- Rocks and logs ---

// A rock: a chunky, squashed ball, half sunk into the ground.
const rockGeometry = new THREE.DodecahedronGeometry(1);
const rockMaterial = new THREE.MeshStandardMaterial({ color: 0x9a968c, roughness: 0.95, flatShading: true });

export function makeRock() {
  const rock = new THREE.Mesh(rockGeometry, rockMaterial);
  rock.castShadow = true;
  return rock;
}

// A fallen log lying on its side: bark all round, pale wood at the cut ends. It's 1 long (along x)
// and 1 thick, resting on the ground, so stretch it with scale.set(length, thickness, thickness).
const logGeometry = new THREE.CylinderGeometry(0.5, 0.5, 1, 12).rotateZ(Math.PI / 2).translate(0, 0.5, 0);
const barkMaterial = new THREE.MeshStandardMaterial({ color: 0x6b4a2c, roughness: 0.95 });
const cutWoodMaterial = new THREE.MeshStandardMaterial({ color: 0xc9a26b, roughness: 0.9 });

export function makeLog() {
  const log = new THREE.Mesh(logGeometry, [barkMaterial, cutWoodMaterial, cutWoodMaterial]);
  log.castShadow = true;
  log.receiveShadow = true;
  return log;
}

// --- Hedges around the field ---

const hedgeGeometry = new THREE.IcosahedronGeometry(0.42, 1);
const bloomGeometry = new THREE.IcosahedronGeometry(1, 1);
const spikeGeometry = new THREE.ConeGeometry(0.05, 0.36, 5).translate(0, 0.18, 0);
// White, so each bush and flower can be tinted its own color.
const plantMaterial = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.8, flatShading: true });
// The bushes are leaf clumps over a darker lump, like the trees.
const hedgeBushMaterial = new THREE.MeshStandardMaterial({ color: 0xb0b0b0, roughness: 0.8 });
const bushCards = leafCards(hedgeGeometry, { size: 0.19, density: 15, seed: 101 });
const bushCardMaterial = new LeafCardMaterial({ color: 0xffffff, map: hedgeLeafTexture });

// Every so often the plain hedge gives way to a flowering shrub. Each kind has its own leaf color
// and flowers, and each bush has one flower color.
const SHRUBS = [
  // Hydrangea: big round mophead flowers in blue, lavender or pink.
  { leaves: 0x4f9a45, colors: [0x86aee8, 0xb39ae3, 0xf2a9cc], flowers: 5, flowerSize: 0.16 },
  // Rhododendron: dark glossy leaves with clusters of pink, magenta or purple flowers.
  { leaves: 0x2f6a36, colors: [0xd8489c, 0xe86fae, 0xa25ac4], flowers: 8, flowerSize: 0.12 },
  // Vitex (a butterfly bush): grey-green leaves and upright purple flower spikes.
  { leaves: 0x6f9a62, colors: [0x9a7fd8, 0x8a6cc9], flowers: 8, spikes: true },
];
const HEDGE_LEAVES = 0x3f8c3c;

// Flowering shrubs come along the hedge in a golden rhythm: after 8 plain bushes, then 5, then
// 8, 8, 5, 8, 5, 8... following the Fibonacci word. Which kind comes next follows the golden
// sequence, so each kind turns up evenly and none of them bunch together.
function makeRhythm() {
  return { bushes: 0, untilFlowers: 3, gaps: 0, shrubs: 0, colorTurns: SHRUBS.map(() => 0) };
}

// Two staggered rows of little round bushes along all four edges, with flowering shrubs mixed in.
// Where the creek flows out of the field, the hedge stops and a fallen log lies across the water.
// `openings` leave gaps for gates: [{ edge: 'south', from, to }], from and to along the edge.
export function makeHedges(arenaSize, thickness, openings = []) {
  const half = arenaSize / 2;
  const line = half - thickness / 2; // From the middle of the field to the middle of the hedge.
  const edges = [
    { name: 'north', spot: (t, row) => [t, -line + row], alongX: true },
    { name: 'south', spot: (t, row) => [t, line + row], alongX: true },
    { name: 'west', spot: (t, row) => [-line + row, t], alongX: false },
    { name: 'east', spot: (t, row) => [line + row, t], alongX: false },
  ];
  const group = new THREE.Group();
  const bushes = [];
  const blooms = [];
  const spikes = [];
  const rhythm = makeRhythm();

  for (const edge of edges) {
    const steps = Math.round(arenaSize / 0.55);
    let gapStart = null;
    let gapEnd = null;
    for (let i = 0; i <= steps; i++) {
      const t = -half + (i / steps) * arenaSize;
      const [x, z] = edge.spot(t, 0);
      if (openings.some((opening) => opening.edge === edge.name && t > opening.from && t < opening.to)) continue;
      if (creekDistance(x, z) < CREEK_HALF_WIDTH + 0.3) {
        if (gapStart === null) gapStart = t;
        gapEnd = t;
        continue;
      }
      for (const row of [-thickness / 4, thickness / 4]) {
        const [bx, bz] = edge.spot(t + (row > 0 ? 0.27 : 0), row);
        bushes.push(makeBush(bx, bz, rhythm, blooms, spikes));
      }
    }

    if (gapStart !== null) {
      const log = makeLog();
      const [x, z] = edge.spot((gapStart + gapEnd) / 2, 0);
      log.scale.set(gapEnd - gapStart + 1.4, 0.55, 0.55);
      log.position.set(x, -0.15, z); // Sagging a little into the dip where the creek runs.
      if (!edge.alongX) log.rotation.y = Math.PI / 2;
      group.add(log);
    }
  }

  group.add(...leafyBushes(bushes), instancedPlants(bloomGeometry, blooms), instancedPlants(spikeGeometry, spikes));
  return group;
}

// Hedges along straight lines, for areas that aren't a square field: each wall runs `from` one
// [x, z] point `to` another, with `gaps` left open: [[start, end], ...] in distances along the wall.
export function makeHedgeWalls(walls, thickness) {
  const bushes = [];
  const blooms = [];
  const spikes = [];
  const rhythm = makeRhythm();
  for (const { from, to, gaps = [] } of walls) {
    const length = Math.hypot(to[0] - from[0], to[1] - from[1]);
    const alongX = (to[0] - from[0]) / length;
    const alongZ = (to[1] - from[1]) / length;
    const steps = Math.round(length / 0.55);
    for (let i = 0; i <= steps; i++) {
      const t = (i / steps) * length;
      if (gaps.some(([start, end]) => t > start && t < end)) continue;
      for (const row of [-thickness / 4, thickness / 4]) {
        const shift = row > 0 ? 0.27 : 0; // The two rows are staggered.
        const x = from[0] + alongX * (t + shift) - alongZ * row;
        const z = from[1] + alongZ * (t + shift) + alongX * row;
        bushes.push(makeBush(x, z, rhythm, blooms, spikes));
      }
    }
  }
  const group = new THREE.Group();
  group.add(...leafyBushes(bushes), instancedPlants(bloomGeometry, blooms), instancedPlants(spikeGeometry, spikes));
  return group;
}

// One bush in the hedge: usually plain, sometimes (when the rhythm says so) a flowering shrub.
// Flowers are added to the blooms or spikes lists. Every plant is { position, turn, size, color }.
// Sizes, turns and shades come from the golden sequence, so neighbors always differ a little.
function makeBush(x, z, rhythm, blooms, spikes) {
  const n = ++rhythm.bushes;
  let shrub = null;
  let flowerColor = null;
  if (rhythm.untilFlowers-- === 0) {
    const kind = Math.floor(goldenFraction(rhythm.shrubs++) * SHRUBS.length);
    shrub = SHRUBS[kind];
    flowerColor = shrub.colors[rhythm.colorTurns[kind]++ % shrub.colors.length];
    rhythm.untilFlowers = fibonacciLong(rhythm.gaps++) ? 8 : 5;
  }
  const grow = shrub ? 1.15 : 1; // Flowering shrubs grow a little bigger than the hedge.
  const size = new THREE.Vector3(
    (0.95 + 0.3 * goldenFraction(n)) * grow,
    (0.75 + 0.25 * goldenFraction(n + 7)) * grow,
    (0.95 + 0.3 * goldenFraction(n + 3)) * grow,
  );
  const center = new THREE.Vector3(x, 0.28, z);
  const turn = n * GOLDEN_ANGLE;
  const shade = 0.82 + 0.26 * goldenFraction(n + 11);
  const bush = { position: center, turn, size, color: new THREE.Color(shrub ? shrub.leaves : HEDGE_LEAVES).multiplyScalar(shade) };
  if (!shrub) return bush;

  // Flowers spiral around the bush like seeds in a sunflower: each one a golden angle round from
  // the last, starting at the top and working down the sides.
  for (let i = 0; i < shrub.flowers; i++) {
    const around = turn + i * GOLDEN_ANGLE;
    const up = 1.3 - 0.95 * ((i + 0.5) / shrub.flowers); // From nearly the top down to low on the side.
    const out = new THREE.Vector3(Math.cos(up) * Math.cos(around), Math.sin(up), Math.cos(up) * Math.sin(around));
    const position = out.clone().multiply(size).multiplyScalar(0.42 * 0.92).add(center);
    const color = new THREE.Color(flowerColor).multiplyScalar(0.9 + 0.2 * goldenFraction(i));
    const bloomSize = 0.85 + 0.3 * goldenFraction(i + 5);
    if (shrub.spikes) {
      // Spikes point mostly up, leaning outward a little.
      const lean = new THREE.Vector3(out.x * 0.5, 1, out.z * 0.5).normalize();
      spikes.push({ position, lean, size: new THREE.Vector3().setScalar(bloomSize), color });
    } else {
      blooms.push({ position, turn: around, size: new THREE.Vector3().setScalar(shrub.flowerSize * bloomSize), color });
    }
  }
  return bush;
}

// Bushes: the darker lump and the leaf clumps over it.
function leafyBushes(bushes) {
  const cards = instancedPlants(bushCards, bushes, bushCardMaterial);
  cards.castShadow = false;
  return [instancedPlants(hedgeGeometry, bushes, hedgeBushMaterial), cards];
}

// Draw one shape for every plant in the list, each with its own spot, turn or lean, size and color.
function instancedPlants(geometry, plants, material = plantMaterial) {
  const mesh = new THREE.InstancedMesh(geometry, material, plants.length);
  const matrix = new THREE.Matrix4();
  const turn = new THREE.Quaternion();
  plants.forEach((plant, i) => {
    if (plant.lean) turn.setFromUnitVectors(THREE.Object3D.DEFAULT_UP, plant.lean);
    else turn.setFromAxisAngle(THREE.Object3D.DEFAULT_UP, plant.turn);
    mesh.setMatrixAt(i, matrix.compose(plant.position, turn, plant.size));
    mesh.setColorAt(i, plant.color);
  });
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  return mesh;
}

// --- The woods outside the field ---

// Real woods (and the painted forests in Ghibli films) aren't spread out evenly, and they don't
// stand in rows. Trees grow in groves: a big old tree with a few younger ones of the same kind
// around it, shrubs and saplings at their feet, and open glades between the groves where you can
// see deeper in. So the woods are built from groves, following a few rules that environment
// artists and garden designers use:
//   - Groves are scattered at random, but never crowded: each keeps clear space around it.
//   - Each grove has an odd number of trees (1, 3, 5 or 7), which looks natural; even numbers look planted.
//   - A grove is mostly one kind of tree, so the autumn colors come in drifts instead of confetti.
//   - Within a grove the trees step down in size from the biggest (big, medium, small), and each
//     sits a golden angle round from the last, like seeds in a sunflower, so no three line up.
//   - The edge of the woods is ragged: some groves come right up to the hedge, others leave a meadow.
//   - Groves further back are taller, but each varies, so the treetops make a rolling skyline.
//   - Further back, trees are a little paler and bluer (as faraway things look), which adds depth.
//   - Shrubs, saplings, stumps and the odd bare dead tree fill in underneath, as in a real wood.
const WOODS_SEED = 7; // Change it for a different (but just as carefully arranged) woods.
const GROVE_GAP = [5, 2.9]; // Space kept around each grove: at the hedge, and at the back (where the woods are thicker).
const GLADE_CHANCE = [0.35, 0.06]; // How often a grove spot is left open as a glade: at the hedge, and at the back.
const GROVE_SIZES = [1, 3, 3, 5, 5, 7, 7]; // Odd numbers of trees. Groves near the hedge use only the smaller ones.
// Which kinds of tree the groves are, in Fibonacci numbers: mostly evergreen, with autumn color.
const GROVE_KINDS = { pine: 13, round: 8, maple: 5, poplar: 5, oak: 3 };
const DEPTH_OF_WOODS = 14; // Groves this far back from the hedge are at their tallest.
const WOODS_LANTERNS = 5; // Lanterns glowing in glades near the hedge, as if each one marks somewhere to explore.
const LANTERN_GAP = 8; // They stand at least this far apart.

// Extra kinds that only grow out in the woods: a bare dead tree and a stump.
TREES.snag = (() => {
  const grey = new THREE.MeshStandardMaterial({ color: 0x8a8178, roughness: 1 });
  const arms = [
    branch(new THREE.Vector3(0, 1.4, 0), new THREE.Vector3(0.55, 2.1, 0.1), 0.06, 0.03),
    branch(new THREE.Vector3(0, 1.9, 0), new THREE.Vector3(-0.45, 2.55, -0.15), 0.05, 0.025),
    branch(new THREE.Vector3(0, 2.3, 0), new THREE.Vector3(0.2, 2.75, 0.35), 0.04, 0.02),
  ];
  return {
    parts: [[mergeGeometries([new THREE.CylinderGeometry(0.06, 0.15, 2.9, 7).translate(0, 1.45, 0), ...arms]), grey]],
    blockRadius: 0.2,
    canopyRadius: 0.5,
    height: 2.9,
  };
})();
TREES.stump = {
  parts: [
    [new THREE.CylinderGeometry(0.2, 0.26, 0.35, 9).translate(0, 0.17, 0), trunkMaterial],
    [new THREE.CylinderGeometry(0.17, 0.17, 0.02, 9).translate(0, 0.36, 0), new THREE.MeshStandardMaterial({ color: 0xc9a26b, roughness: 0.9 })],
  ],
  blockRadius: 0.26,
  canopyRadius: 0.3,
  height: 0.37,
};

// Leaf clumps over every treetop, so the trees look painted leaf by leaf instead of like smooth
// balls and cones (see foliage.js). The lumps underneath turn darker, like the shade deep inside a tree.
(function addLeafCards() {
  let seed = 0;
  for (const tree of Object.values(TREES)) {
    const cards = [];
    for (const [geometry, material] of tree.parts) {
      const kind = material.userData.foliage;
      if (!kind) continue;
      const needles = kind === 'needle';
      cards.push([
        leafCards(geometry, { size: needles ? 0.27 : 0.3, density: needles ? 9 : 11, seed: ++seed }),
        new LeafCardMaterial({ color: material.color.clone().multiplyScalar(1.12), map: needles ? needleTexture : broadLeafTexture }),
      ]);
      material.color.multiplyScalar(0.7);
    }
    tree.parts.push(...cards);
  }
})();

// The same random numbers every time the page loads, so the woods always look the same
// (and can be tuned). Change WOODS_SEED for a different layout. The painted backdrop uses it too.
export function seededRandom(seed) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// The woods around Berry Rush's square field: west, north and east. (The camera looks north,
// so the south is left open behind it.)
export function makeOuterWoods(arenaSize) {
  const edge = arenaSize / 2 + 0.8;
  return growWoods({
    backFromHedge: (x, z) => Math.max(Math.abs(x), -z) - edge,
    reach: 39, // The painted hills start at 40.
    zMax: edge,
    keepClear: (x, z) => z > edge - 1 || creekDistance(x, z) < CREEK_HALF_WIDTH + 0.8,
  });
}

// Woods around any area. `backFromHedge(x, z)` is how far a spot is outside the area's hedge
// (below 0 inside it). Trees grow out to `reach` from the middle, never where `keepClear(x, z)`
// says, and grove spots are picked with z up to `zMax`. The trees are "instanced": each tree part
// is drawn for every tree of that kind in one go, which keeps hundreds of trees fast.
export function growWoods({ backFromHedge, reach, zMax = reach, keepClear = () => false, seed = WOODS_SEED }) {
  const random = seededRandom(seed);
  const between = (low, high) => low + (high - low) * random();
  const pick = (list) => list[Math.floor(random() * list.length)];
  const depthOf = (x, z) => THREE.MathUtils.clamp(backFromHedge(x, z) / DEPTH_OF_WOODS, 0, 1); // 0 at the hedge, 1 deep in.
  const trees = [];
  const shrubs = [];
  const fits = (x, z, spread, closeness) => {
    const outsideArea = backFromHedge(x, z) > spread * 0.4; // Leaves may hang a little over the hedge.
    if (!outsideArea || Math.hypot(x, z) + spread > reach || keepClear(x, z)) return false;
    return !trees.some((tree) => Math.hypot(tree.x - x, tree.z - z) < (tree.spread + spread) * closeness);
  };
  const plant = (kind, x, z, size) => {
    const spread = TREES[kind].canopyRadius * size;
    const depth = depthOf(x, z);
    trees.push({ x, z, kind, size, spread, turn: random() * Math.PI * 2, tint: hazeTint(depth, between(0.88, 1.06)) });
  };

  // 1. Where the groves go: random spots, each keeping its distance from the others.
  const groves = [];
  for (let attempt = 0; attempt < 6000; attempt++) {
    const x = between(-reach, reach);
    const z = between(-reach, zMax);
    if (backFromHedge(x, z) < 0 || Math.hypot(x, z) > reach - 1) continue;
    const gap = THREE.MathUtils.lerp(...GROVE_GAP, depthOf(x, z));
    if (groves.some((grove) => Math.hypot(grove.x - x, grove.z - z) < gap)) continue;
    groves.push({ x, z });
  }

  // 2. Fill each grove, nearest the hedge first, so the front of the woods gets the best spots.
  const glades = [];
  groves.sort((a, b) => backFromHedge(a.x, a.z) - backFromHedge(b.x, b.z));
  const kinds = Object.entries(GROVE_KINDS).flatMap(([kind, count]) => Array(count).fill(kind));
  for (const grove of groves) {
    const depth = depthOf(grove.x, grove.z);
    if (random() < THREE.MathUtils.lerp(...GLADE_CHANCE, depth)) {
      glades.push(grove); // Leave a glade.
      continue;
    }
    const kind = pick(kinds);
    // Live oaks sprawl, so they stand alone. Near the hedge, groves are smaller and the edge more ragged.
    const count = kind === 'oak' ? 1 : pick(depth < 0.25 ? GROVE_SIZES.slice(0, 5) : GROVE_SIZES);
    const biggest = (1 + 0.6 * depth) * between(0.9, 1.15);
    const spacing = TREES[kind].canopyRadius * biggest * between(0.7, 0.9);
    const startAngle = random() * Math.PI * 2;
    for (let k = 0; k < count; k++) {
      // Biggest in the middle, then each one further out and smaller, a golden angle round.
      const angle = startAngle + k * GOLDEN_ANGLE;
      const out = spacing * Math.sqrt(k) * between(0.85, 1.25);
      const x = grove.x + Math.cos(angle) * out;
      const z = grove.z + Math.sin(angle) * out;
      // One tree in five is a neighbor of a different kind, mixed in at the edge of the grove.
      const treeKind = k > 0 && random() < 0.2 ? pick(['pine', 'round']) : kind;
      const size = biggest * (1 - 0.32 * Math.sqrt(k / count)) * between(0.92, 1.08);
      if (fits(x, z, TREES[treeKind].canopyRadius * size, k === 0 ? 0.5 : 0.38)) plant(treeKind, x, z, size);
    }

    // 3. Underneath: shrubs on the side facing the field, a sapling or two, now and then a stump
    // or a bare dead tree. Only near the front, where you can see them.
    if (depth > 0.55) continue;
    const toField = Math.atan2(-grove.z, -grove.x);
    for (let i = 0, shrubCount = 2 + Math.floor(random() * 3); i < shrubCount; i++) {
      const angle = toField + between(-1.3, 1.3);
      const out = spacing * between(1.1, 2);
      addShrub(shrubs, grove.x + Math.cos(angle) * out, grove.z + Math.sin(angle) * out, between(1.3, 2.4), random, depth);
    }
    if (random() < 0.5) {
      const angle = toField + between(-1.6, 1.6);
      const x = grove.x + Math.cos(angle) * spacing * between(1.4, 2.2);
      const z = grove.z + Math.sin(angle) * spacing * between(1.4, 2.2);
      const sapling = pick(['pine', 'round', kind === 'oak' ? 'round' : kind]);
      const size = between(0.45, 0.62);
      if (fits(x, z, TREES[sapling].canopyRadius * size, 0.5)) plant(sapling, x, z, size);
    }
    if (random() < 0.18) {
      const odd = random() < 0.5 ? 'stump' : 'snag';
      const angle = random() * Math.PI * 2;
      const x = grove.x + Math.cos(angle) * spacing * 1.6;
      const z = grove.z + Math.sin(angle) * spacing * 1.6;
      if (fits(x, z, TREES[odd].canopyRadius, 0.6)) plant(odd, x, z, between(0.9, 1.15));
    }
  }

  const woods = new THREE.Group();
  for (const kind of Object.keys(TREES)) {
    const ofKind = trees.filter((tree) => tree.kind === kind);
    if (ofKind.length === 0) continue;
    for (const [geometry, material] of TREES[kind].parts) woods.add(instancedTrees(geometry, material, ofKind));
  }
  woods.add(...leafyBushes(shrubs));

  // 4. Lanterns in the glades nearest the hedge, spread out round the woods, hanging out toward the field.
  const lanterns = [];
  for (const glade of glades) {
    if (lanterns.length === WOODS_LANTERNS || depthOf(glade.x, glade.z) > 0.5) continue;
    if (lanterns.some((other) => Math.hypot(other.x - glade.x, other.z - glade.z) < LANTERN_GAP) || !fits(glade.x, glade.z, 0.6, 1)) continue;
    const lantern = makeLantern();
    lantern.position.set(glade.x, 0, glade.z);
    lantern.rotation.y = Math.atan2(glade.z, -glade.x); // Its arm points toward the middle of the field.
    lantern.scale.setScalar(1.25);
    woods.add(lantern);
    lanterns.push(glade);
  }
  return woods;
}

// A shrub under the trees: a big rounded bush with one or two smaller ones tucked against it,
// each a little smaller than the last (the same "big, medium, small" as the groves).
const SHRUB_GREENS = [0x3f7f3a, 0x4c8c42, 0x5d984b, 0x35703a];

function addShrub(shrubs, x, z, size, random, depth) {
  const color = new THREE.Color(SHRUB_GREENS[Math.floor(random() * SHRUB_GREENS.length)]).multiply(hazeTint(depth, 0.85 + 0.25 * random()));
  let angle = random() * Math.PI * 2;
  for (let i = 0, count = 1 + Math.floor(random() * 3); i < count; i++) {
    const s = size * PHI ** (-i * 0.6);
    const out = i === 0 ? 0 : 0.3 * size;
    const px = x + Math.cos(angle) * out;
    const pz = z + Math.sin(angle) * out;
    const height = new THREE.Vector3(s, s * (0.7 + 0.2 * random()), s);
    shrubs.push({ position: new THREE.Vector3(px, 0.42 * height.y * 0.55, pz), turn: random() * Math.PI * 2, size: height, color });
    angle += GOLDEN_ANGLE;
  }
}

// A tint for something in the woods: darker and richer at the front, paler and a little bluer
// deep in, the way faraway hills and trees look through the air.
function hazeTint(depth, brightness) {
  const haze = depth * 0.55;
  return new THREE.Color(1 - 0.08 * haze, 1 - 0.01 * haze, 1 + 0.12 * haze).multiplyScalar(brightness * (0.92 + 0.14 * haze));
}

// One tree part, drawn once for every tree in the list, each with its own spot, size, turn and tint.
function instancedTrees(geometry, material, trees) {
  const mesh = new THREE.InstancedMesh(geometry, material, trees.length);
  const matrix = new THREE.Matrix4();
  const position = new THREE.Vector3();
  const turn = new THREE.Quaternion();
  const size = new THREE.Vector3();
  trees.forEach((tree, i) => {
    turn.setFromAxisAngle(THREE.Object3D.DEFAULT_UP, tree.turn);
    mesh.setMatrixAt(i, matrix.compose(position.set(tree.x, 0, tree.z), turn, size.setScalar(tree.size)));
    mesh.setColorAt(i, tree.tint);
  });
  mesh.castShadow = true;
  return mesh;
}

// --- Trees that come and go ---

// A pool of trees for an area that keeps changing, like Gnome Crossing's endless trail. Like the
// woods, each tree part is drawn for every tree at once, which keeps hundreds of trees fast.
// plant(kind, x, z, size, turn, tint) puts a tree out and returns a ticket; uproot(ticket) takes
// it away again, freeing its place for another. `kinds` are the kinds it can grow, `perKind` how many of each.
export function createTreePool(kinds, perKind) {
  const group = new THREE.Group();
  const pools = {};
  const hidden = new THREE.Matrix4().makeScale(0, 0, 0);
  const white = new THREE.Color(0xffffff);
  for (const kind of kinds) {
    const meshes = TREES[kind].parts.map(([geometry, material]) => {
      const mesh = new THREE.InstancedMesh(geometry, material, perKind);
      for (let i = 0; i < perKind; i++) {
        mesh.setMatrixAt(i, hidden);
        mesh.setColorAt(i, white);
      }
      mesh.castShadow = true;
      mesh.frustumCulled = false; // Its trees move about, so always draw it rather than guess where they are.
      group.add(mesh);
      return mesh;
    });
    pools[kind] = { meshes, free: Array.from({ length: perKind }, (_, i) => perKind - 1 - i) };
  }
  const matrix = new THREE.Matrix4();
  const position = new THREE.Vector3();
  const turnBy = new THREE.Quaternion();
  const scale = new THREE.Vector3();

  function set(kind, slot, transform, tint) {
    for (const mesh of pools[kind].meshes) {
      mesh.setMatrixAt(slot, transform);
      mesh.instanceMatrix.needsUpdate = true;
      if (tint) {
        mesh.setColorAt(slot, tint);
        mesh.instanceColor.needsUpdate = true;
      }
    }
  }

  function plant(kind, x, z, size = 1, turn = 0, tint = white) {
    const slot = pools[kind].free.pop();
    if (slot === undefined) return null; // All in use: no tree this time.
    turnBy.setFromAxisAngle(THREE.Object3D.DEFAULT_UP, turn);
    set(kind, slot, matrix.compose(position.set(x, 0, z), turnBy, scale.setScalar(size)), tint);
    return { kind, slot };
  }

  function uproot(ticket) {
    if (!ticket) return;
    set(ticket.kind, ticket.slot, hidden);
    pools[ticket.kind].free.push(ticket.slot);
  }

  return { group, plant, uproot, blockRadius: (kind) => TREES[kind].blockRadius };
}

// --- Toadstools and bushes, for Gnome Crossing's meadows ---

// Build something from parts once, then merge its parts into one shape per color, so each copy
// is quick to draw: makes a function that hands out new copies sharing those shapes.
function mergedCopies(build) {
  let parts = null;
  return () => {
    if (!parts) {
      const original = build();
      original.updateMatrixWorld(true);
      const byMaterial = new Map();
      original.traverse((part) => {
        if (!part.isMesh) return;
        if (!byMaterial.has(part.material)) byMaterial.set(part.material, []);
        byMaterial.get(part.material).push(part.geometry.clone().applyMatrix4(part.matrixWorld));
      });
      parts = [...byMaterial].map(([material, geometries]) => [mergeGeometries(geometries), material]);
    }
    const copy = new THREE.Group();
    for (const [geometry, material] of parts) {
      const mesh = new THREE.Mesh(geometry, material);
      mesh.castShadow = true;
      copy.add(mesh);
    }
    return copy;
  };
}

// A toadstool, red with white spots like the gnome's hat, often with a little one beside it.
const stemMaterial = new THREE.MeshStandardMaterial({ color: 0xf1e8d2, roughness: 0.8 });
const toadstoolCapMaterial = new THREE.MeshStandardMaterial({ color: 0xd7261e, roughness: 0.55 });
const gillMaterial = new THREE.MeshStandardMaterial({ color: 0xe8d9b8, roughness: 0.9 });
const spotMaterial = new THREE.MeshStandardMaterial({ color: 0xfffaf0, roughness: 0.6 });
const CAP_RADIUS = 0.42;
const CAP_SQUASH = 0.72;

function buildToadstool(withLittleOne) {
  const stem = new THREE.CylinderGeometry(0.11, 0.15, 0.5, 10).translate(0, 0.25, 0);
  const cap = new THREE.SphereGeometry(CAP_RADIUS, 18, 10, 0, Math.PI * 2, 0, Math.PI / 2).scale(1, CAP_SQUASH, 1).translate(0, 0.46, 0);
  const gills = new THREE.CircleGeometry(CAP_RADIUS * 0.96, 18).rotateX(Math.PI / 2).translate(0, 0.46, 0);
  const spot = new THREE.SphereGeometry(0.065, 8, 6).scale(1, 0.35, 1);
  const group = new THREE.Group();
  const grow = (size, x, z, lean) => {
    const toadstool = new THREE.Group();
    toadstool.add(new THREE.Mesh(stem, stemMaterial), new THREE.Mesh(cap, toadstoolCapMaterial), new THREE.Mesh(gills, gillMaterial));
    // White spots, spread over the cap a golden angle apart, each lying flat on it.
    for (let i = 0; i < 8; i++) {
      const down = 0.25 + 0.9 * ((i * 0.618) % 1); // How far down from the top of the cap.
      const round = i * GOLDEN_ANGLE;
      const normal = new THREE.Vector3(Math.sin(down) * Math.cos(round), Math.cos(down), Math.sin(down) * Math.sin(round));
      const dot = new THREE.Mesh(spot, spotMaterial);
      dot.position.set(normal.x * CAP_RADIUS, 0.46 + normal.y * CAP_RADIUS * CAP_SQUASH, normal.z * CAP_RADIUS);
      dot.quaternion.setFromUnitVectors(THREE.Object3D.DEFAULT_UP, normal);
      toadstool.add(dot);
    }
    toadstool.scale.setScalar(size);
    toadstool.position.set(x, 0, z);
    toadstool.rotation.z = lean;
    group.add(toadstool);
  };
  grow(1, 0, 0, 0);
  if (withLittleOne) grow(0.5, 0.42, 0.22, -0.18);
  return group;
}

const toadstoolPair = mergedCopies(() => buildToadstool(true));
const toadstoolAlone = mergedCopies(() => buildToadstool(false));

export function makeToadstool(withLittleOne = true) {
  return withLittleOne ? toadstoolPair() : toadstoolAlone();
}

// A round leafy bush, three lumps of leaves big, medium and small, dotted with blueberries.
const bushMaterial = new THREE.MeshStandardMaterial({ color: 0x3f8040, roughness: 0.8, flatShading: true });
const blueberryMaterial = new THREE.MeshStandardMaterial({ color: 0x3d4f9e, roughness: 0.35 });

export const makeBlueberryBush = mergedCopies(() => {
  const bush = new THREE.Group();
  const lumpGeometry = new THREE.IcosahedronGeometry(1, 1);
  const berryGeometry = new THREE.SphereGeometry(0.055, 8, 6);
  for (const [r, x, y, z] of [[0.48, 0, 0.4, 0], [0.34, 0.36, 0.3, 0.12], [0.26, -0.3, 0.25, 0.2]]) {
    const lump = new THREE.Mesh(lumpGeometry, bushMaterial);
    lump.scale.set(r, r * 0.85, r);
    lump.position.set(x, y, z);
    bush.add(lump);
  }
  for (let i = 0; i < 9; i++) {
    const round = i * GOLDEN_ANGLE;
    const up = 0.15 + 0.6 * ((i * 0.618) % 1);
    const berry = new THREE.Mesh(berryGeometry, blueberryMaterial);
    berry.position.set(Math.cos(round) * 0.47 * Math.cos(up), 0.4 + Math.sin(up) * 0.4, Math.sin(round) * 0.47 * Math.cos(up));
    bush.add(berry);
  }
  return bush;
});
