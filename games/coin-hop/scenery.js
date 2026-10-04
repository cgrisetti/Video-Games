import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { creekDistance, CREEK_HALF_WIDTH } from './creek.js';

// Trees, rocks, logs, the hedges around the field, and the woods outside it.

// --- Kinds of tree ---

// The size of a basic pine, before it's scaled up. The game sizes logs from these.
export const TREE_HEIGHT = 3.2;
export const TREE_RADIUS = 0.75; // Its widest point: the bottom cone of leaves.
export const TRUNK_DIAMETER = 0.32;

const trunkMaterial = new THREE.MeshStandardMaterial({ color: 0x7a5230, roughness: 0.9 });
const oakBarkMaterial = new THREE.MeshStandardMaterial({ color: 0x5e4c3c, roughness: 0.95 });

function leaves(color) {
  return new THREE.MeshStandardMaterial({ color, roughness: 0.8, flatShading: true });
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
      [new THREE.ConeGeometry(TREE_RADIUS, 1.4, 8).translate(0, 1.3, 0), leaves(0x2f7d3b)],
      [new THREE.ConeGeometry(0.58, 1.2, 8).translate(0, 2.0, 0), leaves(0x2f7d3b)],
      [new THREE.ConeGeometry(0.4, 1.0, 8).translate(0, TREE_HEIGHT - 0.5, 0), leaves(0x2f7d3b)],
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
        [mergeGeometries(moss), leaves(0xa3b18f)],
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

// Every so often the plain hedge gives way to a flowering shrub. Each kind has its own leaf color
// and flowers, and each bush picks one flower color.
const SHRUBS = [
  // Hydrangea: big round mophead flowers in blue, lavender or pink.
  { chance: 0.06, leaves: 0x4f9a45, colors: [0x86aee8, 0xb39ae3, 0xf2a9cc], flowers: 5, flowerSize: 0.16 },
  // Rhododendron: dark glossy leaves with clusters of pink, magenta or purple flowers.
  { chance: 0.06, leaves: 0x2f6a36, colors: [0xd8489c, 0xe86fae, 0xa25ac4], flowers: 6, flowerSize: 0.12 },
  // Vitex (a butterfly bush): grey-green leaves and upright purple flower spikes.
  { chance: 0.05, leaves: 0x6f9a62, colors: [0x9a7fd8, 0x8a6cc9], flowers: 7, spikes: true },
];
const HEDGE_LEAVES = 0x3f8c3c;

// Two staggered rows of little round bushes along all four edges, with flowering shrubs mixed in.
// Where the creek flows out of the field, the hedge stops and a fallen log lies across the water.
export function makeHedges(arenaSize, thickness) {
  const half = arenaSize / 2;
  const line = half - thickness / 2; // From the middle of the field to the middle of the hedge.
  const edges = [
    { spot: (t, row) => [t, -line + row], alongX: true }, // north
    { spot: (t, row) => [t, line + row], alongX: true }, // south
    { spot: (t, row) => [-line + row, t], alongX: false }, // west
    { spot: (t, row) => [line + row, t], alongX: false }, // east
  ];
  const group = new THREE.Group();
  const bushes = [];
  const blooms = [];
  const spikes = [];

  for (const edge of edges) {
    const steps = Math.round(arenaSize / 0.55);
    let gapStart = null;
    let gapEnd = null;
    for (let i = 0; i <= steps; i++) {
      const t = -half + (i / steps) * arenaSize;
      const [x, z] = edge.spot(t, 0);
      if (creekDistance(x, z) < CREEK_HALF_WIDTH + 0.3) {
        if (gapStart === null) gapStart = t;
        gapEnd = t;
        continue;
      }
      for (const row of [-thickness / 4, thickness / 4]) {
        const [bx, bz] = edge.spot(t + (row > 0 ? 0.27 : 0), row);
        bushes.push(makeBush(bx, bz, blooms, spikes));
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

  group.add(instancedPlants(hedgeGeometry, bushes), instancedPlants(bloomGeometry, blooms), instancedPlants(spikeGeometry, spikes));
  return group;
}

// One bush in the hedge: usually plain, sometimes a flowering shrub. Flowers are added to the
// blooms or spikes lists. Every plant is { position, turn, size, color }.
function makeBush(x, z, blooms, spikes) {
  let roll = Math.random();
  const shrub = SHRUBS.find((kind) => (roll -= kind.chance) < 0);
  const grow = shrub ? 1.15 : 1; // Flowering shrubs grow a little bigger than the hedge.
  const size = new THREE.Vector3(
    THREE.MathUtils.randFloat(0.95, 1.25) * grow,
    THREE.MathUtils.randFloat(0.75, 1) * grow,
    THREE.MathUtils.randFloat(0.95, 1.25) * grow,
  );
  const center = new THREE.Vector3(x, 0.28, z);
  const shade = THREE.MathUtils.randFloat(0.82, 1.08);
  const bush = { position: center, turn: Math.random() * Math.PI * 2, size, color: new THREE.Color(shrub ? shrub.leaves : HEDGE_LEAVES).multiplyScalar(shade) };
  if (!shrub) return bush;

  // Flowers sit around the top half of the bush, poking out of the leaves.
  const flowerColor = shrub.colors[Math.floor(Math.random() * shrub.colors.length)];
  for (let i = 0; i < shrub.flowers; i++) {
    const around = Math.random() * Math.PI * 2;
    const up = THREE.MathUtils.randFloat(0.35, 1.3); // From low on the side to nearly the top.
    const out = new THREE.Vector3(Math.cos(up) * Math.cos(around), Math.sin(up), Math.cos(up) * Math.sin(around));
    const position = out.clone().multiply(size).multiplyScalar(0.42 * 0.92).add(center);
    const color = new THREE.Color(flowerColor).multiplyScalar(THREE.MathUtils.randFloat(0.9, 1.1));
    if (shrub.spikes) {
      // Spikes point mostly up, leaning outward a little.
      const lean = new THREE.Vector3(out.x * 0.5, 1, out.z * 0.5).normalize();
      spikes.push({ position, lean, size: new THREE.Vector3().setScalar(THREE.MathUtils.randFloat(0.8, 1.2)), color });
    } else {
      blooms.push({ position, turn: Math.random() * Math.PI, size: new THREE.Vector3().setScalar(shrub.flowerSize * THREE.MathUtils.randFloat(0.8, 1.2)), color });
    }
  }
  return bush;
}

// Draw one shape for every plant in the list, each with its own spot, turn or lean, size and color.
function instancedPlants(geometry, plants) {
  const mesh = new THREE.InstancedMesh(geometry, plantMaterial, plants.length);
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

// How often each kind of tree turns up in the woods.
const WOODS_MIX = [
  ['pine', 0.45],
  ['round', 0.25],
  ['maple', 0.12],
  ['poplar', 0.12],
  ['oak', 0.06],
];

function pickKind() {
  let roll = Math.random();
  return WOODS_MIX.find(([, chance]) => (roll -= chance) < 0)?.[0] ?? 'pine';
}

// Lots of trees beyond the hedges on the west, north and east sides: mostly green, with some
// autumn maples and poplars and a few big live oaks. They're "instanced": each tree part is drawn
// for every tree of that kind in one go, which keeps hundreds of trees fast.
export function makeOuterWoods(arenaSize) {
  const edge = arenaSize / 2 + 0.8;
  const reach = 39; // The painted hills start at 40.
  const trees = [];
  for (let attempt = 0; attempt < 8000 && trees.length < 320; attempt++) {
    const x = THREE.MathUtils.randFloat(-reach, reach);
    const z = THREE.MathUtils.randFloat(-reach, edge);
    const kind = pickKind();
    const size = THREE.MathUtils.randFloat(0.9, 1.6);
    const spread = TREES[kind].canopyRadius * size;
    const outsideField = Math.abs(x) > edge + spread * 0.4 || z < -(edge + spread * 0.4); // Leaves may hang a little over the hedge.
    if (!outsideField || Math.hypot(x, z) + spread > reach || creekDistance(x, z) < CREEK_HALF_WIDTH + 0.8) continue;
    if (trees.some((tree) => Math.hypot(tree.x - x, tree.z - z) < Math.max(1.6, (tree.spread + spread) * 0.6))) continue;
    trees.push({ x, z, kind, size, spread, turn: Math.random() * Math.PI * 2, shade: THREE.MathUtils.randFloat(0.8, 1.1) });
  }

  const woods = new THREE.Group();
  for (const kind of Object.keys(TREES)) {
    const ofKind = trees.filter((tree) => tree.kind === kind);
    for (const [geometry, material] of TREES[kind].parts) woods.add(instancedTrees(geometry, material, ofKind));
  }
  return woods;
}

// One tree part, drawn once for every tree in the list, each with its own spot, size, turn and shade.
function instancedTrees(geometry, material, trees) {
  const mesh = new THREE.InstancedMesh(geometry, material, trees.length);
  const matrix = new THREE.Matrix4();
  const position = new THREE.Vector3();
  const turn = new THREE.Quaternion();
  const size = new THREE.Vector3();
  const shade = new THREE.Color();
  trees.forEach((tree, i) => {
    turn.setFromAxisAngle(THREE.Object3D.DEFAULT_UP, tree.turn);
    mesh.setMatrixAt(i, matrix.compose(position.set(tree.x, 0, tree.z), turn, size.setScalar(tree.size)));
    mesh.setColorAt(i, shade.setScalar(tree.shade));
  });
  mesh.castShadow = true;
  return mesh;
}
