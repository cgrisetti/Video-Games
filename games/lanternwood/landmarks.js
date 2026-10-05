import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// Landmarks for the Bramble Maze: one-of-a-kind things to find in its dead ends and crossings,
// so you can say "I've been past the wishing well" and know where you are. Each one is built
// standing at 0, 0, 0 with its front facing +z, and has a `radius` you bump into and a `height`
// (low ones you can hop over). They're storybook garden things: a sundial, a birdbath with a
// robin, a toadstool ring, a tea bench for mice, a beehive, a little house in a stump...

const stone = new THREE.MeshStandardMaterial({ color: 0xc2baa8, roughness: 0.95, flatShading: true });
const darkStone = new THREE.MeshStandardMaterial({ color: 0x9a9384, roughness: 0.95, flatShading: true });
const wood = new THREE.MeshStandardMaterial({ color: 0x8b6a43, roughness: 0.85 });
const darkWood = new THREE.MeshStandardMaterial({ color: 0x5b4030, roughness: 0.9 });
const brass = new THREE.MeshStandardMaterial({ color: 0xc9a24a, roughness: 0.4, metalness: 0.6 });
const water = new THREE.MeshStandardMaterial({ color: 0x5aa6d8, roughness: 0.2 });
const leaf = new THREE.MeshStandardMaterial({ color: 0x4f8f45, roughness: 0.8, flatShading: true });
const topiary = new THREE.MeshStandardMaterial({ color: 0x5a8f52, roughness: 0.85, flatShading: true });
const paleLeaf = new THREE.MeshStandardMaterial({ color: 0xa9c79a, roughness: 0.85, flatShading: true });
const white = new THREE.MeshStandardMaterial({ color: 0xf6f0e2, roughness: 0.7 });
const red = new THREE.MeshStandardMaterial({ color: 0xc8302a, roughness: 0.6 });
const orange = new THREE.MeshStandardMaterial({ color: 0xe5852d, roughness: 0.7, flatShading: true });
const straw = new THREE.MeshStandardMaterial({ color: 0xd9b45a, roughness: 0.9, flatShading: true });
const terracotta = new THREE.MeshStandardMaterial({ color: 0xc0673f, roughness: 0.85 });
const china = new THREE.MeshStandardMaterial({ color: 0x8fb4dd, roughness: 0.35 });
const black = new THREE.MeshStandardMaterial({ color: 0x1d1a17, roughness: 0.4 });
const burlap = new THREE.MeshStandardMaterial({ color: 0xbfa27a, roughness: 1, flatShading: true });
const coat = new THREE.MeshStandardMaterial({ color: 0x4d6a8f, roughness: 0.9 });

function part(geometry, material, x = 0, y = 0, z = 0) {
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(x, y, z);
  mesh.castShadow = true;
  return mesh;
}

function group(...parts) {
  const g = new THREE.Group();
  g.add(...parts);
  return g;
}

// A stone sundial on a pedestal, with a brass pointer.
function sundial() {
  return group(
    part(new THREE.CylinderGeometry(0.22, 0.3, 0.85, 8), stone, 0, 0.42, 0),
    part(new THREE.CylinderGeometry(0.45, 0.42, 0.08, 16), stone, 0, 0.89, 0),
    part(new THREE.CylinderGeometry(0.36, 0.36, 0.02, 16), brass, 0, 0.94, 0),
    part(new THREE.BoxGeometry(0.03, 0.22, 0.3).rotateX(-0.5), brass, 0, 1.03, 0.02),
  );
}

// A birdbath with a robin perched on the rim.
function birdbath() {
  const robin = group(
    part(new THREE.SphereGeometry(0.09, 10, 8).scale(1, 0.9, 1.3), darkWood),
    part(new THREE.SphereGeometry(0.06, 10, 8), red, 0, -0.01, 0.07),
    part(new THREE.SphereGeometry(0.06, 10, 8), darkWood, 0, 0.08, 0.08),
    part(new THREE.ConeGeometry(0.018, 0.06, 5).rotateX(Math.PI / 2), brass, 0, 0.08, 0.15),
  );
  robin.position.set(0.42, 1.0, 0.1);
  robin.rotation.y = 1.2;
  return group(
    part(new THREE.CylinderGeometry(0.12, 0.28, 0.8, 8), stone, 0, 0.4, 0),
    part(new THREE.CylinderGeometry(0.52, 0.22, 0.2, 16), stone, 0, 0.88, 0),
    part(new THREE.CylinderGeometry(0.44, 0.44, 0.02, 16), water, 0, 0.97, 0),
    robin,
  );
}

// A wishing well: a ring of stones, a little shingled roof, and a bucket on a rope.
function well() {
  const w = group(
    part(new THREE.CylinderGeometry(0.62, 0.66, 0.7, 12, 1, true), stone, 0, 0.35, 0),
    part(new THREE.TorusGeometry(0.62, 0.08, 6, 14).rotateX(Math.PI / 2), darkStone, 0, 0.7, 0),
    part(new THREE.CylinderGeometry(0.58, 0.58, 0.02, 14), water, 0, 0.45, 0),
    part(new THREE.ConeGeometry(0.85, 0.55, 4).rotateY(Math.PI / 4), red, 0, 1.95, 0),
    part(new THREE.CylinderGeometry(0.02, 0.02, 0.6), black, 0, 1.4, 0),
    part(new THREE.CylinderGeometry(0.12, 0.09, 0.16, 10), wood, 0, 1.05, 0),
  );
  for (const x of [-0.62, 0.62]) w.add(part(new THREE.BoxGeometry(0.1, 1.5, 0.1), darkWood, x, 1.2, 0));
  w.add(part(new THREE.CylinderGeometry(0.04, 0.04, 1.3).rotateZ(Math.PI / 2), darkWood, 0, 1.7, 0));
  return w;
}

// A fairy ring of toadstools, red with white spots: just right for a gnome.
function toadstools() {
  const ring = new THREE.Group();
  for (let i = 0; i < 5; i++) {
    const angle = (i / 5) * Math.PI * 2;
    const size = 0.7 + 0.35 * Math.sin(i * 2.1) ** 2;
    const shroom = group(
      part(new THREE.CylinderGeometry(0.06, 0.08, 0.32, 8), white, 0, 0.16, 0),
      part(new THREE.SphereGeometry(0.2, 12, 8, 0, Math.PI * 2, 0, Math.PI / 2).scale(1, 0.7, 1), red, 0, 0.3, 0),
    );
    for (let s = 0; s < 4; s++) {
      const a = s * 1.7;
      shroom.add(part(new THREE.SphereGeometry(0.035, 6, 4), white, Math.cos(a) * 0.12, 0.4, Math.sin(a) * 0.12));
    }
    shroom.position.set(Math.cos(angle) * 0.5, 0, Math.sin(angle) * 0.5);
    shroom.scale.setScalar(size);
    ring.add(shroom);
  }
  return ring;
}

// A pumpkin patch: three ribbed pumpkins with stalks, and broad leaves.
function pumpkins() {
  const patch = new THREE.Group();
  for (const [x, z, size] of [[-0.35, 0.1, 1], [0.35, -0.1, 0.75], [0.1, 0.45, 0.6]]) {
    const ribs = [];
    for (let i = 0; i < 6; i++) ribs.push(new THREE.SphereGeometry(0.16, 8, 6).scale(1, 1.2, 1).translate(Math.cos(i) * 0.12, 0, Math.sin(i) * 0.12));
    const pumpkin = group(part(mergeGeometries(ribs), orange, 0, 0.18, 0), part(new THREE.CylinderGeometry(0.025, 0.035, 0.12, 5), darkWood, 0, 0.38, 0));
    pumpkin.position.set(x, 0, z);
    pumpkin.scale.setScalar(size * 1.3);
    patch.add(pumpkin);
  }
  for (let i = 0; i < 5; i++) patch.add(part(new THREE.CircleGeometry(0.18, 6).rotateX(-Math.PI / 2 + 0.3), leaf, Math.cos(i * 1.3) * 0.6, 0.05, Math.sin(i * 1.3) * 0.5));
  return patch;
}

// A wooden bench set for tea, the way the mice of the hedgerow would have it: teapot and two cups.
function teaBench() {
  const bench = group(
    part(new THREE.BoxGeometry(1.3, 0.07, 0.42), wood, 0, 0.45, 0),
    part(new THREE.BoxGeometry(1.3, 0.35, 0.05), wood, 0, 0.72, -0.2),
  );
  for (const x of [-0.55, 0.55]) for (const z of [-0.15, 0.15]) bench.add(part(new THREE.BoxGeometry(0.07, 0.45, 0.07), darkWood, x, 0.22, z));
  const teapot = group(
    part(new THREE.SphereGeometry(0.11, 12, 8).scale(1, 0.85, 1), china),
    part(new THREE.ConeGeometry(0.025, 0.12, 6).rotateZ(-1.0), china, 0.12, 0.02, 0),
    part(new THREE.TorusGeometry(0.06, 0.012, 5, 10), china, -0.11, 0.01, 0),
    part(new THREE.SphereGeometry(0.025, 6, 4), china, 0, 0.1, 0),
  );
  teapot.position.set(-0.2, 0.58, 0.02);
  bench.add(teapot);
  for (const x of [0.15, 0.4]) bench.add(part(new THREE.CylinderGeometry(0.045, 0.035, 0.06, 10), white, x, 0.52, 0.05));
  return bench;
}

// A straw beehive (a skep) on a little stand, with a few bees about.
function beehive() {
  const rings = [];
  for (let i = 0; i < 6; i++) {
    const r = 0.38 * Math.cos((i / 6) * (Math.PI / 2));
    rings.push(new THREE.TorusGeometry(r + 0.02, 0.07, 6, 16).rotateX(Math.PI / 2).translate(0, 0.08 + i * 0.1, 0));
  }
  const hive = group(
    part(new THREE.BoxGeometry(0.9, 0.08, 0.9), darkWood, 0, 0.6, 0),
    part(mergeGeometries(rings), straw, 0, 0.64, 0),
    part(new THREE.SphereGeometry(0.07, 8, 6), straw, 0, 1.3, 0),
    part(new THREE.CircleGeometry(0.06, 10), black, 0, 0.74, 0.39),
  );
  for (const x of [-0.35, 0.35]) for (const z of [-0.35, 0.35]) hive.add(part(new THREE.BoxGeometry(0.07, 0.6, 0.07), darkWood, x, 0.3, z));
  for (let i = 0; i < 4; i++) {
    const bee = part(new THREE.SphereGeometry(0.035, 6, 4).scale(1.4, 1, 1), straw, Math.cos(i * 2) * 0.5, 1.0 + 0.15 * i, Math.sin(i * 2) * 0.5);
    bee.userData.buzz = i;
    hive.add(bee);
  }
  return hive;
}

// A stone mouse on a plinth, holding up a lantern: a brave little mouse, keeping watch.
function mouseStatue() {
  const mouse = group(
    part(new THREE.SphereGeometry(0.28, 10, 8).scale(0.9, 1.15, 0.9), stone, 0, 0.3, 0),
    part(new THREE.SphereGeometry(0.17, 10, 8).scale(1, 1, 1.25), stone, 0, 0.68, 0.06),
    part(new THREE.ConeGeometry(0.06, 0.14, 6).rotateX(Math.PI / 2), stone, 0, 0.66, 0.29),
  );
  for (const side of [-1, 1]) mouse.add(part(new THREE.CylinderGeometry(0.12, 0.12, 0.03, 12).rotateX(Math.PI / 2), stone, side * 0.13, 0.84, 0));
  mouse.add(part(new THREE.TorusGeometry(0.22, 0.025, 5, 12, Math.PI * 1.2), stone, -0.05, 0.12, -0.25));
  mouse.add(part(new THREE.CylinderGeometry(0.03, 0.03, 0.36), stone, 0.22, 0.6, 0.08));
  mouse.add(part(new THREE.SphereGeometry(0.07, 8, 6), brass, 0.22, 0.82, 0.08));
  mouse.position.y = 0.55;
  return group(part(new THREE.BoxGeometry(0.75, 0.55, 0.75), darkStone, 0, 0.27, 0), mouse);
}

// A big round topiary forest spirit with pointed ears and a pale tummy, grown in the hedge.
function topiarySpirit() {
  const spirit = group(
    part(new THREE.IcosahedronGeometry(0.85, 2).scale(1, 1.08, 0.95), topiary, 0, 0.9, 0),
    part(new THREE.IcosahedronGeometry(0.62, 1).scale(1, 1.05, 0.5), paleLeaf, 0, 0.78, 0.5),
  );
  for (const side of [-1, 1]) {
    spirit.add(part(new THREE.ConeGeometry(0.14, 0.5, 6).rotateZ(-side * 0.2), topiary, side * 0.35, 1.95, 0));
    spirit.add(part(new THREE.SphereGeometry(0.08, 10, 8), white, side * 0.24, 1.25, 0.76));
    spirit.add(part(new THREE.SphereGeometry(0.045, 8, 6), black, side * 0.24, 1.25, 0.83));
  }
  return spirit;
}

// A wheelbarrow, left with three pots of flowers in it.
function wheelbarrow() {
  const barrow = group(
    part(new THREE.CylinderGeometry(0.5, 0.36, 0.3, 4, 1).rotateY(Math.PI / 4).scale(1.4, 1, 0.9), wood, 0, 0.45, 0),
    part(new THREE.TorusGeometry(0.17, 0.05, 6, 14).rotateY(Math.PI / 2), black, 0, 0.18, 0.62),
  );
  for (const x of [-0.22, 0.22]) {
    barrow.add(part(new THREE.BoxGeometry(0.05, 0.05, 1.3), darkWood, x, 0.36, -0.15));
    barrow.add(part(new THREE.BoxGeometry(0.05, 0.3, 0.05), darkWood, x, 0.15, -0.45));
  }
  const colors = [0xe0577c, 0xf3d150, 0x9a7fd8];
  colors.forEach((color, i) => {
    const x = -0.25 + i * 0.25;
    barrow.add(part(new THREE.CylinderGeometry(0.11, 0.08, 0.18, 10), terracotta, x, 0.68, (i - 1) * 0.08));
    barrow.add(part(new THREE.IcosahedronGeometry(0.12, 0), leaf, x, 0.82, (i - 1) * 0.08));
    barrow.add(part(new THREE.SphereGeometry(0.05, 6, 4), new THREE.MeshStandardMaterial({ color }), x + 0.04, 0.9, (i - 1) * 0.08 + 0.04));
  });
  return barrow;
}

// A scarecrow: a sack for a head, a tall pointed hat, a patched coat and straw sticking out.
function scarecrow() {
  const crow = group(
    part(new THREE.CylinderGeometry(0.05, 0.06, 2.0), darkWood, 0, 1.0, 0),
    part(new THREE.CylinderGeometry(0.04, 0.04, 1.3).rotateZ(Math.PI / 2), darkWood, 0, 1.5, 0),
    part(new THREE.BoxGeometry(0.55, 0.65, 0.28), coat, 0, 1.35, 0),
    part(new THREE.SphereGeometry(0.2, 10, 8), burlap, 0, 1.9, 0),
    part(new THREE.ConeGeometry(0.2, 0.55, 8), black, 0, 2.3, 0),
    part(new THREE.CylinderGeometry(0.3, 0.3, 0.03, 12), black, 0, 2.06, 0),
  );
  for (const side of [-1, 1]) crow.add(part(new THREE.ConeGeometry(0.06, 0.2, 5).rotateZ(side * 1.9), straw, side * 0.7, 1.48, 0));
  return crow;
}

// A tree stump with a little round door and a window: someone small lives here.
function stumpHouse() {
  const stump = group(
    part(new THREE.CylinderGeometry(0.55, 0.7, 1.15, 10), darkWood, 0, 0.57, 0),
    part(new THREE.CylinderGeometry(0.5, 0.5, 0.04, 10), wood, 0, 1.16, 0),
    part(new THREE.CylinderGeometry(0.2, 0.2, 0.05, 14).rotateX(Math.PI / 2), red, 0, 0.3, 0.64),
    part(new THREE.SphereGeometry(0.025, 6, 4), brass, 0.12, 0.3, 0.67),
    part(new THREE.CylinderGeometry(0.09, 0.09, 0.04, 12).rotateX(Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0xffd27a, emissive: 0xffa040, emissiveIntensity: 0.6 }), 0.28, 0.75, 0.52),
    part(new THREE.CylinderGeometry(0.06, 0.06, 0.35, 8), terracotta, -0.25, 1.32, -0.1),
  );
  stump.children[4].rotation.y = 0.45; // Turn the window to sit flat on the bark.
  return stump;
}

// The landmarks, each with how wide and tall it is (for bumping and hopping over).
export const LANDMARKS = [
  { name: 'sundial', build: sundial, radius: 0.45, height: 0.95 },
  { name: 'birdbath', build: birdbath, radius: 0.5, height: 1.0 },
  { name: 'wishing well', build: well, radius: 0.75, height: Infinity },
  { name: 'toadstool ring', build: toadstools, radius: 0.75, height: 0.45 },
  { name: 'pumpkin patch', build: pumpkins, radius: 0.7, height: 0.55 },
  { name: 'tea bench', build: teaBench, radius: 0.7, height: 0.9 },
  { name: 'beehive', build: beehive, radius: 0.5, height: Infinity },
  { name: 'mouse statue', build: mouseStatue, radius: 0.5, height: Infinity },
  { name: 'topiary spirit', build: topiarySpirit, radius: 0.9, height: Infinity },
  { name: 'wheelbarrow', build: wheelbarrow, radius: 0.6, height: 0.95 },
  { name: 'scarecrow', build: scarecrow, radius: 0.3, height: Infinity },
  { name: 'stump house', build: stumpHouse, radius: 0.7, height: 1.18 },
];

// Make the bees buzz round the hive (and anything else that likes to move). Call once a frame.
export function animateLandmark(model, time) {
  for (const child of model.children) {
    if (child.userData.buzz === undefined) continue;
    const i = child.userData.buzz;
    child.position.x = Math.cos(time * (1.3 + i * 0.2) + i * 2) * 0.55;
    child.position.z = Math.sin(time * (1.1 + i * 0.3) + i * 2) * 0.5;
    child.position.y = 1.0 + 0.15 * i + 0.08 * Math.sin(time * 6 + i);
  }
}
