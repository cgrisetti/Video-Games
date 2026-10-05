import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { GOLDEN_ANGLE } from './golden.js';

// The animals of Gnome Crossing, built from simple shapes like the fox: deer that bound across
// the animal trails, wild boars that trot, hedgehog families that waddle in a line, and the owl
// who comes for gnomes still out after dark. Each one faces +z. The deer, boar and hedgehog stand
// with their feet on the ground at 0, 0, 0; the owl's middle is at 0, 0, 0, since it flies.
// Each has an animate(dt, ...) that moves its legs (or wings).

// Shapes are shared between animals, so a whole herd is quick to make.
const sphere = new THREE.SphereGeometry(1, 16, 12);
const shapes = new Map();
const materials = new Map();

function material(color) {
  if (!materials.has(color)) materials.set(color, new THREE.MeshStandardMaterial({ color, roughness: 0.85 }));
  return materials.get(color);
}

function shape(key, make) {
  if (!shapes.has(key)) shapes.set(key, make());
  return shapes.get(key);
}

function joint(parent, x, y, z) {
  const pivot = new THREE.Group();
  pivot.position.set(x, y, z);
  parent.add(pivot);
  return pivot;
}

function add(parent, geometry, color, x, y, z) {
  const mesh = new THREE.Mesh(geometry, material(color));
  mesh.position.set(x, y, z);
  mesh.castShadow = true;
  parent.add(mesh);
  return mesh;
}

// A stretched ball: a sphere scaled to sx, sy, sz.
function ball(parent, color, sx, sy, sz, x, y, z) {
  const mesh = add(parent, sphere, color, x, y, z);
  mesh.scale.set(sx, sy, sz);
  return mesh;
}

// A leg bone: a tapering stick hanging down `length` from its top at x, y, z.
function limb(parent, color, top, bottom, length, x, y, z) {
  const geometry = shape(`limb ${top} ${bottom} ${length}`, () => new THREE.CylinderGeometry(top, bottom, length, 9).translate(0, -length / 2, 0));
  return add(parent, geometry, color, x, y, z);
}

// A stick growing up `length` from x, y, z (necks, antlers).
function stalk(parent, color, radius, length, x, y, z) {
  const geometry = shape(`stalk ${radius} ${length}`, () => new THREE.CylinderGeometry(radius * 0.7, radius, length, 7).translate(0, length / 2, 0));
  return add(parent, geometry, color, x, y, z);
}

function cone(parent, color, radius, height, x, y, z) {
  const geometry = shape(`cone ${radius} ${height}`, () => new THREE.ConeGeometry(radius, height, 8));
  return add(parent, geometry, color, x, y, z);
}

// Merge all the parts that move together into one shape per color, so a whole herd is quick to
// draw. `movers` are the joints animate() turns; every other part is fixed to the nearest mover above it.
function bake(model, movers) {
  const owners = [model, ...movers];
  model.updateMatrixWorld(true);
  for (const owner of owners) {
    const byColor = new Map();
    const toOwner = owner.matrixWorld.clone().invert();
    const collect = (node) => {
      for (const child of [...node.children]) {
        if (owners.includes(child)) continue; // That mover takes care of its own parts.
        if (child.isMesh) {
          const geometry = child.geometry.clone().applyMatrix4(new THREE.Matrix4().multiplyMatrices(toOwner, child.matrixWorld));
          if (!byColor.has(child.material)) byColor.set(child.material, []);
          byColor.get(child.material).push(geometry);
          child.removeFromParent();
        } else {
          collect(child);
        }
      }
    };
    collect(owner);
    for (const [material, geometries] of byColor) {
      const mesh = new THREE.Mesh(mergeGeometries(geometries), material);
      mesh.castShadow = true;
      owner.add(mesh);
      for (const geometry of geometries) geometry.dispose();
    }
  }
}

// --- The deer ---

// A red deer stag (or a hind, without antlers): long legs, a white rump, big ears, and branching
// antlers. It runs in great bounds, front legs reaching forward and back legs stretched behind.
const DEER = { coat: 0xa8673a, belly: 0xf1e2c8, rump: 0xfaf3e6, dark: 0x3b2618, antler: 0xd9c49b };

export function makeDeer({ antlers = true } = {}) {
  const model = new THREE.Group();
  const rig = joint(model, 0, 0, 0); // Rises and falls with each bound.
  const body = joint(rig, 0, 1.2, 0);
  ball(body, DEER.coat, 0.3, 0.33, 0.72, 0, 0, 0);
  ball(body, DEER.belly, 0.24, 0.18, 0.55, 0, -0.16, 0.04);
  ball(body, DEER.rump, 0.2, 0.22, 0.1, 0, 0.04, -0.66);
  ball(body, DEER.coat, 0.06, 0.1, 0.05, 0, 0.2, -0.73); // A little tail.

  const legs = [[-0.15, 0.48], [0.15, 0.48], [-0.15, -0.48], [0.15, -0.48]].map(([x, z]) => {
    const hip = joint(body, x, -0.1, z);
    limb(hip, DEER.coat, 0.075, 0.05, 0.55, 0, 0, 0);
    limb(hip, DEER.coat, 0.042, 0.035, 0.5, 0, -0.55, 0);
    ball(hip, DEER.dark, 0.045, 0.04, 0.06, 0, -1.07, 0.02);
    return hip;
  });

  // A long neck reaching up and forward, and a head held level on top of it.
  const neck = joint(body, 0, 0.12, 0.52);
  neck.rotation.x = 0.55;
  ball(neck, DEER.coat, 0.12, 0.34, 0.12, 0, 0.26, 0);
  const head = joint(neck, 0, 0.56, 0);
  head.rotation.x = -0.55;
  ball(head, DEER.coat, 0.15, 0.15, 0.19, 0, 0, 0.04);
  ball(head, DEER.coat, 0.09, 0.085, 0.15, 0, -0.04, 0.2);
  ball(head, DEER.dark, 0.045, 0.04, 0.035, 0, -0.03, 0.34);
  for (const side of [-1, 1]) {
    ball(head, DEER.dark, 0.03, 0.035, 0.02, side * 0.11, 0.04, 0.13);
    const ear = joint(head, side * 0.12, 0.1, -0.03);
    ear.rotation.z = -side * 0.95;
    ball(ear, DEER.coat, 0.05, 0.13, 0.03, 0, 0.11, 0);
    ball(ear, DEER.belly, 0.03, 0.09, 0.015, 0, 0.11, 0.02);
    if (!antlers) continue;
    // Each antler: a beam sweeping up and out, with two tines pointing forward and a fork at the top.
    const beam = joint(head, side * 0.07, 0.12, -0.03);
    beam.rotation.set(-0.25, 0, -side * 0.4);
    stalk(beam, DEER.antler, 0.025, 0.46, 0, 0, 0);
    for (const [y, lean, length] of [[0.12, 1.1, 0.16], [0.28, 0.9, 0.15], [0.46, 0.35, 0.12]]) {
      const tine = joint(beam, 0, y, 0);
      tine.rotation.x = lean;
      stalk(tine, DEER.antler, 0.016, length, 0, 0, 0);
    }
  }

  let phase = Math.random() * Math.PI * 2;
  function animate(dt, speed) {
    phase += dt * (2.5 + speed * 0.75);
    const stride = Math.min(speed / 4, 1);
    const s = Math.sin(phase);
    legs[0].rotation.x = legs[1].rotation.x = -s * 0.75 * stride;
    legs[2].rotation.x = legs[3].rotation.x = s * 0.75 * stride;
    rig.position.y = Math.max(s, 0) * 0.3 * stride;
    body.rotation.x = -Math.cos(phase) * 0.1 * stride;
    head.rotation.x = -0.55 + Math.cos(phase) * 0.08 * stride;
  }

  bake(model, [rig, body, head, ...legs]);
  return { model, animate };
}

// --- The wild boar ---

// A stout dark boar: a big humped body with a bristly ridge down its back, short legs, a pink
// snout and two little curved tusks. It trots along with its legs in diagonal pairs, like the fox.
const BOAR = { coat: 0x5a4033, dark: 0x2e211a, snout: 0xc89a8a, tusk: 0xf4ecdc };

export function makeBoar() {
  const model = new THREE.Group();
  const rig = joint(model, 0, 0, 0);
  const body = joint(rig, 0, 0.62, 0);
  ball(body, BOAR.coat, 0.36, 0.37, 0.62, 0, 0, -0.04);
  ball(body, BOAR.coat, 0.34, 0.37, 0.32, 0, 0.07, 0.3); // The hump at the shoulders.
  for (let i = 0; i < 9; i++) {
    const z = -0.42 + i * 0.11;
    const bristle = cone(body, BOAR.dark, 0.05, 0.2, 0, 0.36 + 0.08 * Math.sin((i / 8) * Math.PI), z);
    bristle.rotation.x = -0.5; // Swept back.
  }
  const legs = [[-0.17, 0.38], [0.17, 0.38], [-0.17, -0.38], [0.17, -0.38]].map(([x, z]) => {
    const hip = joint(body, x, -0.2, z);
    limb(hip, BOAR.coat, 0.08, 0.06, 0.34, 0, 0, 0);
    ball(hip, BOAR.dark, 0.06, 0.05, 0.07, 0, -0.38, 0.02);
    return hip;
  });
  const head = joint(body, 0, 0.0, 0.6);
  ball(head, BOAR.coat, 0.24, 0.24, 0.3, 0, 0, 0.06);
  ball(head, BOAR.coat, 0.15, 0.14, 0.18, 0, -0.06, 0.28);
  ball(head, BOAR.snout, 0.1, 0.09, 0.05, 0, -0.07, 0.45);
  for (const side of [-1, 1]) {
    ball(head, BOAR.dark, 0.02, 0.025, 0.01, side * 0.04, -0.07, 0.49); // Nostrils.
    ball(head, BOAR.dark, 0.032, 0.035, 0.02, side * 0.13, 0.08, 0.26); // Eyes.
    const tusk = cone(head, BOAR.tusk, 0.03, 0.14, side * 0.1, -0.1, 0.36);
    tusk.rotation.set(-0.3, 0, side * 0.5);
    const ear = cone(head, BOAR.coat, 0.07, 0.18, side * 0.15, 0.22, 0.02);
    ear.rotation.z = -side * 0.5;
  }
  const tail = joint(body, 0, 0.12, -0.64);
  limb(tail, BOAR.dark, 0.015, 0.012, 0.22, 0, 0, 0);

  let phase = Math.random() * Math.PI * 2;
  function animate(dt, speed) {
    phase += dt * (4 + speed * 1.6);
    const step = Math.sin(phase) * 0.6 * Math.min(speed / 2, 1);
    legs[0].rotation.x = legs[3].rotation.x = step;
    legs[1].rotation.x = legs[2].rotation.x = -step;
    rig.position.y = Math.abs(Math.sin(phase)) * 0.04;
    tail.rotation.x = 0.4 + Math.sin(phase * 2) * 0.4;
  }

  bake(model, [rig, body, head, tail, ...legs]);
  return { model, animate };
}

// --- The hedgehog ---

// A hedgehog: a round brown back covered in spines, a pointed cream face with a black button nose,
// and little feet underneath. It waddles from side to side. The babies are the same, smaller.
const HEDGEHOG = { spines: 0x6b5644, tips: 0xd8c8a8, face: 0xd9b48a, dark: 0x1e1612 };

// The spines: little cones standing out from the back, spread a golden angle apart, merged into one shape.
const spineGeometry = (() => {
  const spines = [];
  const up = THREE.Object3D.DEFAULT_UP;
  for (let i = 0; i < 70; i++) {
    const height = 0.05 + 0.9 * (i / 70); // From the top of the back down toward the ground.
    const round = i * GOLDEN_ANGLE;
    const normal = new THREE.Vector3(Math.cos(round) * Math.sin(Math.acos(1 - height)), 1 - height, Math.sin(round) * Math.sin(Math.acos(1 - height)));
    if (normal.z > 0.55 || normal.y < 0.05) continue; // Not over the face, and not underneath.
    normal.z -= 0.35; // Swept back.
    normal.normalize();
    const spine = new THREE.ConeGeometry(0.03, 0.15, 4);
    spine.translate(0, 0.075, 0);
    spine.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(up, normal));
    spine.translate(normal.x * 0.27, 0.18 + normal.y * 0.2, normal.z * 0.3);
    spines.push(spine);
  }
  return mergeGeometries(spines);
})();

export function makeHedgehog() {
  const model = new THREE.Group();
  const rig = joint(model, 0, 0, 0);
  ball(rig, HEDGEHOG.spines, 0.28, 0.21, 0.32, 0, 0.18, -0.02);
  add(rig, spineGeometry, HEDGEHOG.tips, 0, 0, 0);
  const snout = cone(rig, HEDGEHOG.face, 0.13, 0.28, 0, 0.14, 0.34);
  snout.rotation.x = Math.PI / 2;
  ball(rig, HEDGEHOG.face, 0.17, 0.14, 0.12, 0, 0.15, 0.22);
  ball(rig, HEDGEHOG.dark, 0.04, 0.035, 0.035, 0, 0.14, 0.48);
  for (const side of [-1, 1]) {
    ball(rig, HEDGEHOG.dark, 0.025, 0.028, 0.02, side * 0.08, 0.21, 0.3);
    ball(rig, HEDGEHOG.face, 0.035, 0.035, 0.02, side * 0.12, 0.28, 0.2);
  }
  for (const [x, z] of [[-0.13, 0.12], [0.13, 0.12], [-0.13, -0.14], [0.13, -0.14]]) ball(rig, HEDGEHOG.dark, 0.05, 0.035, 0.06, x, 0.03, z);

  let phase = Math.random() * Math.PI * 2;
  function animate(dt, speed) {
    phase += dt * (8 + speed * 6);
    const s = Math.sin(phase);
    rig.rotation.z = s * 0.08; // A little side-to-side waddle.
    rig.position.y = Math.abs(s) * 0.025;
  }

  bake(model, [rig]);
  return { model, animate };
}

// --- The owl ---

// A big tawny owl with a round pale face, great golden eyes, ear tufts and broad soft wings.
// When night catches a gnome still out on the trail, it swoops down and flies it home to bed.
const OWL = { feathers: 0x8a6342, light: 0xe9d6b4, disc: 0xdcc39a, dark: 0x4a3423, eye: 0xffb72e, pupil: 0x141414, beak: 0x5a4632, talon: 0xe0b04a };

export function makeOwl() {
  const model = new THREE.Group();
  const body = joint(model, 0, 0, 0);
  ball(body, OWL.feathers, 0.5, 0.62, 0.45, 0, 0, 0);
  ball(body, OWL.light, 0.36, 0.46, 0.22, 0, -0.08, 0.3);
  for (let i = 0; i < 7; i++) {
    const round = i * GOLDEN_ANGLE;
    ball(body, OWL.dark, 0.035, 0.02, 0.02, Math.cos(round) * 0.18, -0.15 + Math.sin(round) * 0.25, 0.5); // Speckles.
  }

  const head = joint(body, 0, 0.62, 0.04);
  ball(head, OWL.feathers, 0.42, 0.36, 0.38, 0, 0, 0);
  for (const side of [-1, 1]) {
    ball(head, OWL.disc, 0.2, 0.22, 0.07, side * 0.15, -0.01, 0.31);
    ball(head, OWL.eye, 0.1, 0.1, 0.05, side * 0.15, 0.02, 0.36);
    ball(head, OWL.pupil, 0.056, 0.056, 0.03, side * 0.15, 0.02, 0.4);
    ball(head, 0xffffff, 0.018, 0.018, 0.01, side * 0.13, 0.05, 0.43); // A sparkle in each eye.
    const tuft = cone(head, OWL.feathers, 0.08, 0.24, side * 0.25, 0.32, 0);
    tuft.rotation.z = -side * 0.45;
  }
  const beak = cone(head, OWL.beak, 0.05, 0.14, 0, -0.1, 0.39);
  beak.rotation.x = Math.PI;

  // Wings: broad and soft, with darker tips, beating from the shoulders.
  const wings = [-1, 1].map((side) => {
    const shoulder = joint(body, side * 0.4, 0.22, -0.04);
    ball(shoulder, OWL.feathers, 0.7, 0.11, 0.38, side * 0.62, -0.06, 0);
    ball(shoulder, OWL.dark, 0.3, 0.08, 0.3, side * 1.2, -0.08, -0.05);
    return shoulder;
  });

  // Feet with golden talons, where the gnome is held.
  for (const side of [-1, 1]) {
    ball(body, OWL.talon, 0.07, 0.05, 0.08, side * 0.15, -0.62, 0.1);
    for (const spread of [-0.4, 0, 0.4]) {
      const claw = cone(body, OWL.dark, 0.02, 0.1, side * 0.15 + Math.sin(spread) * 0.07, -0.66, 0.1 + Math.cos(spread) * 0.07);
      claw.rotation.x = Math.PI * 0.75;
    }
  }
  const talons = joint(body, 0, -0.7, 0.1); // Hang things from here.

  let phase = 0;
  // flapping: beating its wings (or, if false, gliding with them held out).
  function animate(dt, { flapping = true } = {}) {
    if (flapping) phase += dt * 10;
    const beat = flapping ? Math.sin(phase) * 0.85 : 0.12;
    wings[0].rotation.z = -beat;
    wings[1].rotation.z = beat;
    body.position.y = flapping ? -Math.sin(phase) * 0.06 : 0;
    head.rotation.z = Math.sin(phase * 0.3) * 0.12;
  }

  return { model, animate, talons };
}
