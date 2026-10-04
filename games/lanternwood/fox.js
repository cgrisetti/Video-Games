import * as THREE from 'three';

// The gnome's friend: a big, kind red fox, like David the Gnome's fox Swift. Built from simple
// shapes, facing +z with its paws on the ground. The game moves and turns `model`; animate()
// does the trotting, tail swishing and the low sniffing stance.

const COLORS = {
  fur: 0xd9662b,
  cream: 0xf6efe4,
  dark: 0x3a2418,
  nose: 0x1d1410,
  eye: 0x24170f,
  sparkle: 0xffffff,
};

const TROT_RATE = 1.6; // Steps per unit of speed (plus a steady base pace).
const LEG_SWING = 0.55;

const materials = {};

function part(geometry, color, x, y, z) {
  // See-through-able, so the fox can fade when it's between the camera and the gnome.
  if (!materials[color]) materials[color] = new THREE.MeshStandardMaterial({ color: COLORS[color], roughness: 0.85, transparent: true });
  const mesh = new THREE.Mesh(geometry, materials[color]);
  mesh.position.set(x, y, z);
  mesh.castShadow = true;
  return mesh;
}

function joint(parent, x, y, z) {
  const pivot = new THREE.Group();
  pivot.position.set(x, y, z);
  parent.add(pivot);
  return pivot;
}

// A stretched ball: a sphere scaled to sx, sy, sz.
function ball(color, sx, sy, sz, x, y, z) {
  const mesh = part(new THREE.SphereGeometry(1, 18, 12), color, x, y, z);
  mesh.scale.set(sx, sy, sz);
  return mesh;
}

export function createFox() {
  const model = new THREE.Group();
  const rig = joint(model, 0, 0, 0); // Bobs while trotting.

  // The body pivots at the hips, so tipping it forward lowers the chest into a sniffing stance.
  const body = joint(rig, 0, 0.92, -0.55);
  body.add(ball('fur', 0.4, 0.38, 0.9, 0, 0, 0.6));
  body.add(ball('cream', 0.3, 0.3, 0.42, 0, -0.1, 1.15)); // Fluffy white chest.

  // Four legs: orange up top, dark "stockings" below, little dark paws.
  const legs = [[-0.2, 1.12], [0.2, 1.12], [-0.2, 0.08], [0.2, 0.08]].map(([x, z]) => {
    const hip = joint(body, x, -0.05, z);
    hip.add(part(new THREE.CylinderGeometry(0.085, 0.075, 0.48, 10), 'fur', 0, -0.24, 0));
    hip.add(part(new THREE.CylinderGeometry(0.065, 0.06, 0.38, 10), 'dark', 0, -0.67, 0));
    hip.add(ball('dark', 0.08, 0.05, 0.11, 0, -0.86, 0.04));
    return hip;
  });
  const [frontLeft, frontRight, backLeft, backRight] = legs;

  // The head: a round orange crown, fluffy cream cheeks, a pointed snout with a white jaw,
  // a little black nose, soft dark eyes with a sparkle in each, and tall dark-tipped ears.
  const neck = joint(body, 0, 0.22, 1.32);
  const head = joint(neck, 0, 0.08, 0.08);
  head.add(ball('fur', 0.27, 0.24, 0.28, 0, 0.1, 0));
  for (const side of [-1, 1]) head.add(ball('cream', 0.15, 0.13, 0.15, side * 0.14, 0, 0.08));
  const snout = part(new THREE.ConeGeometry(0.13, 0.36, 14).rotateX(Math.PI / 2), 'fur', 0, 0.04, 0.33);
  const jaw = part(new THREE.ConeGeometry(0.1, 0.3, 14).rotateX(Math.PI / 2), 'cream', 0, -0.03, 0.3);
  head.add(snout, jaw, ball('nose', 0.05, 0.045, 0.045, 0, 0.05, 0.52));
  for (const side of [-1, 1]) {
    const eye = ball('eye', 0.052, 0.042, 0.03, side * 0.12, 0.17, 0.235);
    eye.rotation.z = side * 0.2; // A gentle almond tilt.
    head.add(eye, ball('sparkle', 0.014, 0.014, 0.01, side * 0.105, 0.19, 0.262));
    const ear = joint(head, side * 0.15, 0.3, -0.02);
    ear.rotation.z = -side * 0.25; // Tilted a little outward.
    ear.add(part(new THREE.ConeGeometry(0.11, 0.3, 10), 'fur', 0, 0.15, 0));
    const inner = part(new THREE.ConeGeometry(0.06, 0.2, 8), 'cream', 0, 0.12, 0.05);
    inner.scale.z = 0.4;
    ear.add(inner, part(new THREE.ConeGeometry(0.045, 0.1, 8), 'dark', 0, 0.27, 0));
  }

  // A big fluffy tail with a white tip.
  const tail = joint(body, 0, 0.08, -0.32);
  for (const [z, y, r] of [[-0.12, -0.02, 0.15], [-0.38, 0.05, 0.21], [-0.66, 0.12, 0.23], [-0.93, 0.17, 0.19]]) {
    tail.add(ball('fur', r, r, r * 1.15, 0, y, z));
  }
  tail.add(ball('cream', 0.14, 0.14, 0.16, 0, 0.2, -1.13));

  let time = 0;
  let trotPhase = 0;
  let trotAmount = 0; // 0 standing, 1 trotting.
  let sniffAmount = 0; // 0 standing tall, 1 low in the sniffing stance.

  // Call once a frame. speed: how fast it's moving. sniffing: in the low pointing stance.
  // pitch: how far to tip the nose down (in radians) to point straight at something.
  function animate(dt, { speed, sniffing, pitch = 0 }) {
    time += dt;
    const blend = 1 - Math.exp(-8 * dt);
    trotAmount += (Math.min(speed / 2.5, 1) - trotAmount) * blend;
    sniffAmount += ((sniffing ? 1 : 0) - sniffAmount) * blend;
    trotPhase += (4 + speed * TROT_RATE) * dt * (trotAmount > 0.02 ? 1 : 0);

    // Trot: legs move in diagonal pairs, the body bobs and the tail swishes.
    const step = Math.sin(trotPhase) * LEG_SWING * trotAmount;
    const dip = 0.2 * sniffAmount; // How far the chest tips down when sniffing.
    body.rotation.x = dip;
    for (const leg of legs) leg.rotation.x = -dip; // Keep the legs straight up and down.
    frontLeft.rotation.x += step;
    backRight.rotation.x += step;
    frontRight.rotation.x -= step;
    backLeft.rotation.x -= step;
    for (const leg of [frontLeft, frontRight]) leg.scale.y = 1 - 0.25 * sniffAmount; // Front legs bend to lower the chest.
    rig.position.y = Math.abs(Math.sin(trotPhase)) * 0.05 * trotAmount;

    // The head stays level (or tips to point) even when the chest dips, twitching as it sniffs.
    // Standing about, it tilts its head now and then, kind and curious.
    head.rotation.x = (-dip + pitch) * sniffAmount + Math.sin(time * 24) * 0.03 * sniffAmount;
    head.rotation.z = Math.sin(time * 0.8) * 0.08 * (1 - sniffAmount) * (1 - trotAmount);

    // Tail: a lazy swish, quicker when trotting, held up straight like a pointer when sniffing.
    tail.rotation.y = Math.sin(time * (2 + 3 * trotAmount)) * 0.35 * (1 - 0.7 * sniffAmount);
    tail.rotation.x = 0.1 + 0.35 * sniffAmount;
  }

  // How solid the fox looks: 1 is solid, lower is see-through.
  function setOpacity(opacity) {
    for (const material of Object.values(materials)) material.opacity = opacity;
  }

  return { model, animate, setOpacity };
}
