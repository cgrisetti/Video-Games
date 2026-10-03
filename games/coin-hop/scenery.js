import * as THREE from 'three';
import { creekDistance, CREEK_HALF_WIDTH } from './creek.js';

// Trees, rocks, the hedges around the field, and the woods outside it.

// --- Trees and rocks inside the field ---

// A pine tree: a trunk and three cones of leaves, each narrower than the one below,
// so you can see past the tops.
const trunkGeometry = new THREE.CylinderGeometry(0.12, 0.16, 0.8, 8).translate(0, 0.4, 0);
const trunkMaterial = new THREE.MeshStandardMaterial({ color: 0x7a5230, roughness: 0.9 });
const leafGeometries = [
  new THREE.ConeGeometry(0.75, 1.4, 8).translate(0, 1.3, 0),
  new THREE.ConeGeometry(0.58, 1.2, 8).translate(0, 2.0, 0),
  new THREE.ConeGeometry(0.4, 1.0, 8).translate(0, 2.7, 0),
];
const leafMaterial = new THREE.MeshStandardMaterial({ color: 0x2f7d3b, roughness: 0.8, flatShading: true });

export function makeTree() {
  const tree = new THREE.Group();
  tree.add(new THREE.Mesh(trunkGeometry, trunkMaterial));
  for (const geometry of leafGeometries) tree.add(new THREE.Mesh(geometry, leafMaterial));
  for (const part of tree.children) part.castShadow = true;
  return tree;
}

// A rock: a chunky, squashed ball, half sunk into the ground.
const rockGeometry = new THREE.DodecahedronGeometry(1);
const rockMaterial = new THREE.MeshStandardMaterial({ color: 0x9a968c, roughness: 0.95, flatShading: true });

export function makeRock() {
  const rock = new THREE.Mesh(rockGeometry, rockMaterial);
  rock.castShadow = true;
  return rock;
}

// --- Hedges around the field ---

const hedgeGeometry = new THREE.IcosahedronGeometry(0.42, 1);
const hedgeMaterial = new THREE.MeshStandardMaterial({ color: 0x3f8c3c, roughness: 0.85, flatShading: true });
const barkMaterial = new THREE.MeshStandardMaterial({ color: 0x6b4a2c, roughness: 0.95 });
const cutWoodMaterial = new THREE.MeshStandardMaterial({ color: 0xc9a26b, roughness: 0.9 });

// Two staggered rows of little round bushes along all four edges. Where the creek flows out of
// the field, the hedge stops and a fallen log lies across the water instead.
export function makeHedges(arenaSize, thickness) {
  const half = arenaSize / 2;
  const line = half - thickness / 2; // From the middle of the field to the middle of the hedge.
  const edges = [
    { spot: (t, row) => [t, -line + row], alongX: true }, // north
    { spot: (t, row) => [t, line + row], alongX: true }, // south
    { spot: (t, row) => [-line + row, t], alongX: false }, // west
    { spot: (t, row) => [line + row, t], alongX: false }, // east
  ];
  const clumps = [];
  const group = new THREE.Group();

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
        const [cx, cz] = edge.spot(t + (row > 0 ? 0.27 : 0), row);
        clumps.push({ x: cx, z: cz });
      }
    }

    if (gapStart !== null) {
      const length = gapEnd - gapStart + 1.4;
      const log = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.29, length, 12), [barkMaterial, cutWoodMaterial, cutWoodMaterial]);
      const [x, z] = edge.spot((gapStart + gapEnd) / 2, 0);
      log.position.set(x, 0.12, z);
      if (edge.alongX) log.rotation.z = Math.PI / 2;
      else log.rotation.x = Math.PI / 2;
      log.castShadow = true;
      group.add(log);
    }
  }

  const hedges = new THREE.InstancedMesh(hedgeGeometry, hedgeMaterial, clumps.length);
  const matrix = new THREE.Matrix4();
  const position = new THREE.Vector3();
  const turn = new THREE.Quaternion();
  const size = new THREE.Vector3();
  const shade = new THREE.Color();
  clumps.forEach((clump, i) => {
    turn.setFromAxisAngle(THREE.Object3D.DEFAULT_UP, Math.random() * Math.PI * 2);
    size.set(THREE.MathUtils.randFloat(0.95, 1.25), THREE.MathUtils.randFloat(0.75, 1), THREE.MathUtils.randFloat(0.95, 1.25));
    hedges.setMatrixAt(i, matrix.compose(position.set(clump.x, 0.28, clump.z), turn, size));
    hedges.setColorAt(i, shade.setScalar(THREE.MathUtils.randFloat(0.82, 1.08)));
  });
  hedges.castShadow = true;
  hedges.receiveShadow = true;
  group.add(hedges);
  return group;
}

// --- The woods outside the field ---

// Round leafy trees for the woods, to mix in with the pines.
const crownGeometries = [
  new THREE.IcosahedronGeometry(0.85, 1).translate(0, 1.55, 0),
  new THREE.IcosahedronGeometry(0.6, 1).translate(0.35, 2.25, 0.1),
];
const crownMaterial = new THREE.MeshStandardMaterial({ color: 0x5a9e45, roughness: 0.85, flatShading: true });

// Lots of pines and round leafy trees beyond the hedges on the west, north and east sides.
// They're "instanced": each kind of tree part is drawn for every tree in one go, which keeps it fast.
export function makeOuterWoods(arenaSize) {
  const edge = arenaSize / 2 + 0.8;
  const reach = 37; // How far out the woods go (the painted hills start at 40).
  const trees = [];
  for (let attempt = 0; attempt < 8000 && trees.length < 320; attempt++) {
    const x = THREE.MathUtils.randFloat(-reach, reach);
    const z = THREE.MathUtils.randFloat(-reach, edge);
    const outsideField = Math.abs(x) > edge || z < -edge;
    if (!outsideField || Math.hypot(x, z) > reach || creekDistance(x, z) < CREEK_HALF_WIDTH + 0.8) continue;
    if (trees.some((tree) => Math.hypot(tree.x - x, tree.z - z) < 1.7)) continue;
    trees.push({
      x,
      z,
      size: THREE.MathUtils.randFloat(0.9, 1.6),
      turn: Math.random() * Math.PI * 2,
      shade: THREE.MathUtils.randFloat(0.8, 1.1),
      round: Math.random() < 0.4,
    });
  }
  const pines = trees.filter((tree) => !tree.round);
  const roundTrees = trees.filter((tree) => tree.round);

  const woods = new THREE.Group();
  woods.add(instanced(trunkGeometry, trunkMaterial, trees));
  for (const geometry of leafGeometries) woods.add(instanced(geometry, leafMaterial, pines));
  for (const geometry of crownGeometries) woods.add(instanced(geometry, crownMaterial, roundTrees));
  return woods;
}

// One tree part, drawn once for every tree in the list, each with its own spot, size, turn and shade.
function instanced(geometry, material, trees) {
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
