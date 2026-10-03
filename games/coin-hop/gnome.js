import * as THREE from 'three';

// The player: a little gnome in the style of David the Gnome, built from simple shapes.
// Tall red pointy hat, big white beard, blue tunic with a belt, beige trousers and dark boots.

const COLORS = {
  hat: 0xd7261e,
  skin: 0xf3c9a5,
  nose: 0xeaa083,
  eyes: 0x1a1a1a,
  beard: 0xf7f5ee,
  tunic: 0x2d6cb5,
  belt: 0x5b3a1f,
  buckle: 0xe9c443,
  trousers: 0xd9c49b,
  boots: 0x3a2a22,
};

// Tweak these to change how the gnome runs and jumps.
const RUN_CYCLE_SPEED = 14; // How fast the legs swing while running.
const LEG_SWING = 0.9; // How far the legs swing, in radians (1 radian is about 57 degrees).
const ARM_SWING = 0.8;
const RUN_BOUNCE = 0.08; // How high the gnome bobs with each step.

const materials = {};

// One shape in one of the gnome's colors, placed at x, y, z inside its parent.
function part(geometry, color, x, y, z) {
  if (!materials[color]) materials[color] = new THREE.MeshStandardMaterial({ color: COLORS[color], roughness: 0.8 });
  const mesh = new THREE.Mesh(geometry, materials[color]);
  mesh.position.set(x, y, z);
  mesh.castShadow = true;
  return mesh;
}

// An invisible pivot the gnome bends at, like a hip or a shoulder.
function joint(parent, x, y, z) {
  const pivot = new THREE.Group();
  pivot.position.set(x, y, z);
  parent.add(pivot);
  return pivot;
}

export function createGnome() {
  const model = new THREE.Group(); // Its origin is between the feet. The game moves and turns this.
  const rig = joint(model, 0, 0, 0); // Bounces, squashes and stretches inside the model.

  // Legs: beige trousers and dark boots, swinging from the hips.
  const legs = [-1, 1].map((side) => {
    const hip = joint(rig, side * 0.09, 0.33, 0);
    hip.add(part(new THREE.CylinderGeometry(0.07, 0.07, 0.24, 10), 'trousers', 0, -0.12, 0));
    const boot = part(new THREE.SphereGeometry(0.09, 12, 8), 'boots', 0, -0.265, 0.04);
    boot.scale.set(1, 0.75, 1.45);
    hip.add(boot);
    return hip;
  });

  // Body: a blue tunic that flares at the bottom, with a brown belt and a gold buckle.
  const body = joint(rig, 0, 0.33, 0);
  body.add(part(new THREE.CylinderGeometry(0.17, 0.25, 0.36, 14), 'tunic', 0, 0.16, 0));
  body.add(part(new THREE.CylinderGeometry(0.228, 0.228, 0.05, 14), 'belt', 0, 0.1, 0));
  body.add(part(new THREE.BoxGeometry(0.08, 0.06, 0.03), 'buckle', 0, 0.1, 0.228));

  // Arms: blue sleeves and little hands, swinging from the shoulders.
  const arms = [-1, 1].map((side) => {
    const shoulder = joint(body, side * 0.19, 0.3, 0);
    shoulder.add(part(new THREE.CylinderGeometry(0.055, 0.06, 0.22, 10), 'tunic', 0, -0.11, 0));
    shoulder.add(part(new THREE.SphereGeometry(0.055, 10, 8), 'skin', 0, -0.24, 0));
    return shoulder;
  });

  // Head: a round face, a big nose, little black eyes, a fluffy white beard and a tall red hat.
  body.add(part(new THREE.SphereGeometry(0.17, 16, 12), 'skin', 0, 0.5, 0));
  body.add(part(new THREE.SphereGeometry(0.055, 12, 8), 'nose', 0, 0.48, 0.17));
  for (const side of [-1, 1]) {
    body.add(part(new THREE.SphereGeometry(0.022, 8, 6), 'eyes', side * 0.065, 0.54, 0.15));
  }
  const beard = part(new THREE.SphereGeometry(1, 16, 12), 'beard', 0, 0.29, 0.13);
  beard.scale.set(0.16, 0.19, 0.12);
  body.add(beard);
  const hat = joint(body, 0, 0.56, 0);
  hat.add(part(new THREE.ConeGeometry(0.2, 0.62, 16), 'hat', 0, 0.31, 0));

  let time = 0;
  let runPhase = 0; // Where the legs are in their swing.
  let runAmount = 0; // Blends from 0 (standing) to 1 (running).
  let airAmount = 0; // Blends from 0 (on the ground) to 1 (in the air).
  let squash = 0; // A quick squash when landing, fading back to 0.

  // Call once a frame. running: moving along the ground. inAir: jumping or falling.
  // verticalSpeed: how fast it's going up or down. landed: it just hit the ground.
  function animate(dt, { running, inAir, verticalSpeed, landed }) {
    time += dt;
    const blend = 1 - Math.exp(-15 * dt); // How quickly it eases from one pose to the next.
    runAmount += ((running && !inAir ? 1 : 0) - runAmount) * blend;
    airAmount += ((inAir ? 1 : 0) - airAmount) * blend;
    if (running) runPhase += RUN_CYCLE_SPEED * dt;
    if (landed) squash = 1;
    squash *= Math.exp(-10 * dt);

    // Running: arms and legs swing opposite ways, the body leans forward and the hat flops back.
    // In the air: one knee up and both arms thrown up high.
    const swing = Math.sin(runPhase);
    legs[0].rotation.x = swing * LEG_SWING * runAmount - 0.9 * airAmount;
    legs[1].rotation.x = -swing * LEG_SWING * runAmount + 0.4 * airAmount;
    arms[0].rotation.x = -swing * ARM_SWING * runAmount - 2.6 * airAmount;
    arms[1].rotation.x = swing * ARM_SWING * runAmount - 2.6 * airAmount;
    arms[0].rotation.z = -0.15 - 0.5 * airAmount;
    arms[1].rotation.z = 0.15 + 0.5 * airAmount;
    body.rotation.x = 0.2 * runAmount;
    hat.rotation.x = (-0.3 + Math.sin(runPhase * 2) * 0.08) * runAmount + Math.sin(time * 2) * 0.03;

    // Bob up with each step, breathe while standing, stretch tall in the air, squash flat on landing.
    const stretch = Math.min(Math.abs(verticalSpeed) * 0.012, 0.1) * airAmount;
    const breathe = Math.sin(time * 3) * 0.015 * (1 - runAmount) * (1 - airAmount);
    rig.position.y = Math.abs(swing) * RUN_BOUNCE * runAmount;
    rig.scale.y = 1 + stretch + breathe - 0.25 * squash;
    rig.scale.x = rig.scale.z = 1 - stretch / 2 + 0.15 * squash;
  }

  return { model, animate };
}
