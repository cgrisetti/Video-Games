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
  stick: 0x8b5a2b,
  leaf: 0x5fa046,
};

// Tweak these to change how the gnome runs, jumps and swings its stick.
const RUN_CYCLE_SPEED = 14; // How fast the legs swing while running.
const LEG_SWING = 0.9; // How far the legs swing, in radians (1 radian is about 57 degrees).
const ARM_SWING = 0.8;
const RUN_BOUNCE = 0.08; // How high the gnome bobs with each step.
const SWING_TIME = 0.5; // Seconds for one whole stick swing.
const STRIKE = [0.32, 0.75]; // The part of the swing (0 = start, 1 = end) when the stick can hit something.

// The stick swing, as key poses the gnome passes through. Each one is
// [when (0-1), right arm forward(-)/back(+), right arm out(-)/across(+), stick angle in the hand, body twist, joy].
// It winds up over the right shoulder, chops down to the front-right, sweeps low across the
// front to the left (where worm heads are), then settles back.
const SWING_POSES = [
  [0, 0, -0.15, 1.25, 0, 0],
  [0.22, -2.3, -0.55, 1.7, -0.7, 0.5],
  [0.4, -0.7, -0.1, 2.45, -0.45, 0.9],
  [0.6, -0.6, 0.3, 2.5, 0.8, 1],
  [1, 0, -0.15, 1.25, 0, 0],
];

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

  // A crooked stick in the right hand, with a twig and a leaf sprouting from it. (Facing us, the
  // gnome's right hand is on our left: arms[0].) It's built pointing up from the hand; the grip
  // joint turns it to point forward. Three invisible marks along it are what hits the worms.
  const grip = joint(arms[0], 0, -0.24, 0);
  grip.add(part(new THREE.CylinderGeometry(0.032, 0.042, 0.45, 8), 'stick', 0, 0.125, 0));
  const bend = part(new THREE.CylinderGeometry(0.025, 0.032, 0.27, 8), 'stick', -0.033, 0.48, 0);
  bend.rotation.z = 0.25;
  grip.add(bend);
  const twig = part(new THREE.CylinderGeometry(0.008, 0.012, 0.12, 6), 'stick', 0.04, 0.29, 0);
  twig.rotation.z = -0.8;
  grip.add(twig);
  const leaf = part(new THREE.SphereGeometry(1, 8, 6), 'leaf', 0.088, 0.335, 0);
  leaf.scale.set(0.045, 0.07, 0.014);
  leaf.rotation.z = -0.5;
  grip.add(leaf);
  const stickMarks = [[0, 0.25], [-0.025, 0.45], [-0.065, 0.61]].map(([x, y]) => joint(grip, x, y, 0)); // Middle, near the end, tip.

  // Sparkles that trail from the tip of the stick during a swing.
  const sparkleGeometry = new THREE.OctahedronGeometry(0.06);
  const sparkleColors = [0xffe27a, 0xffffff, 0xffb3d9];
  const sparkles = Array.from({ length: 24 }, (_, i) => {
    const mesh = new THREE.Mesh(sparkleGeometry, new THREE.MeshBasicMaterial({ color: sparkleColors[i % 3], transparent: true }));
    mesh.visible = false;
    return { mesh, life: 0 };
  });
  let nextSparkle = 0;

  let time = 0;
  let runPhase = 0; // Where the legs are in their swing.
  let runAmount = 0; // Blends from 0 (standing) to 1 (running).
  let airAmount = 0; // Blends from 0 (on the ground) to 1 (in the air).
  let squash = 0; // A quick squash when landing, fading back to 0.
  let swingTime = -1; // Seconds into the current stick swing, or -1 when not swinging.

  // Call once a frame. running: moving along the ground. pace: how fast, from 0 to 1 (full speed).
  // inAir: jumping or falling. verticalSpeed: how fast it's going up or down. landed: it just hit the ground.
  function animate(dt, { running, pace = 1, inAir, verticalSpeed, landed }) {
    time += dt;
    const blend = 1 - Math.exp(-15 * dt); // How quickly it eases from one pose to the next.
    const stride = 0.4 + 0.6 * pace; // Walking slowly takes shorter, slower steps.
    runAmount += ((running && !inAir ? stride : 0) - runAmount) * blend;
    airAmount += ((inAir ? 1 : 0) - airAmount) * blend;
    if (running) runPhase += RUN_CYCLE_SPEED * stride * dt;
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
    body.rotation.y = 0;
    hat.rotation.x = (-0.3 + Math.sin(runPhase * 2) * 0.08) * runAmount + Math.sin(time * 2) * 0.03;
    hat.rotation.z = 0;
    grip.rotation.x = 1.25 + 1.0 * airAmount; // Carried pointing forward; held up high when jumping.

    // Bob up with each step, breathe while standing, stretch tall in the air, squash flat on landing.
    const stretch = Math.min(Math.abs(verticalSpeed) * 0.012, 0.1) * airAmount;
    const breathe = Math.sin(time * 3) * 0.015 * (1 - runAmount) * (1 - airAmount);
    rig.position.y = Math.abs(swing) * RUN_BOUNCE * runAmount;

    if (swingTime >= 0) animateSwing(dt);
    updateSparkles(dt);

    rig.scale.y = 1 + stretch + breathe - 0.25 * squash;
    rig.scale.x = rig.scale.z = 1 - stretch / 2 + 0.15 * squash;
  }

  // The stick swing: blend from the running pose into the swing's key poses and back again,
  // with a happy little hop, the other arm flung out, a wobbly hat and sparkles off the tip.
  function animateSwing(dt) {
    swingTime += dt;
    const progress = Math.min(swingTime / SWING_TIME, 1);
    const pose = swingPose(progress);
    const blend = Math.min(1, progress / 0.12, (1 - progress) / 0.2); // Ease in and out of the swing.
    const joy = pose[5] * blend;
    arms[0].rotation.x = THREE.MathUtils.lerp(arms[0].rotation.x, pose[1], blend);
    arms[0].rotation.z = THREE.MathUtils.lerp(arms[0].rotation.z, pose[2], blend);
    grip.rotation.x = THREE.MathUtils.lerp(grip.rotation.x, pose[3], blend);
    body.rotation.y = pose[4] * blend;
    arms[1].rotation.x -= 0.7 * joy;
    arms[1].rotation.z += 0.9 * joy;
    hat.rotation.z = Math.sin(progress * Math.PI * 2) * 0.35 * blend;
    rig.position.y += 0.12 * Math.sin(Math.PI * THREE.MathUtils.clamp((progress - 0.15) / 0.6, 0, 1));
    if (progress > STRIKE[0] && progress < STRIKE[1] + 0.05) sparkle();
    if (progress >= 0.75 && progress - dt / SWING_TIME < 0.75) squash = 0.5; // Land from the hop.
    if (progress === 1) swingTime = -1;
  }

  // Where the swing is at `progress`: between two key poses, eased so it speeds up and slows down.
  function swingPose(progress) {
    const next = SWING_POSES.findIndex((pose) => pose[0] >= progress);
    if (next <= 0) return SWING_POSES[0];
    const from = SWING_POSES[next - 1];
    const to = SWING_POSES[next];
    const t = THREE.MathUtils.smoothstep((progress - from[0]) / (to[0] - from[0]), 0, 1);
    return from.map((value, i) => THREE.MathUtils.lerp(value, to[i], t));
  }

  // Pop a sparkle out at the tip of the stick. Sparkles live in the world, not on the gnome,
  // so they hang in the air behind the swing.
  function sparkle() {
    const world = model.parent;
    if (!world) return;
    const spark = sparkles[nextSparkle++ % sparkles.length];
    if (!spark.mesh.parent) world.add(spark.mesh);
    model.updateMatrixWorld(true);
    stickMarks[2].getWorldPosition(spark.mesh.position);
    spark.life = 1;
    spark.mesh.visible = true;
  }

  function updateSparkles(dt) {
    for (const spark of sparkles) {
      if (spark.life <= 0) continue;
      spark.life -= dt / 0.4;
      spark.mesh.position.y += 0.5 * dt;
      spark.mesh.rotation.y += 8 * dt;
      spark.mesh.scale.setScalar(Math.max(spark.life, 0.01));
      spark.mesh.material.opacity = Math.max(spark.life, 0);
      spark.mesh.visible = spark.life > 0;
    }
  }

  // Start a stick swing, unless one is already going.
  function swingStick() {
    if (swingTime < 0) swingTime = 0;
  }

  // Is the stick in the part of the swing that can hit something?
  function isStriking() {
    const progress = swingTime / SWING_TIME;
    return swingTime >= 0 && progress >= STRIKE[0] && progress <= STRIKE[1];
  }

  // Where the stick is in the world right now: its middle, near its end and its tip.
  const stickPoints = stickMarks.map(() => new THREE.Vector3());
  function whereIsStick() {
    model.updateMatrixWorld(true);
    stickMarks.forEach((mark, i) => mark.getWorldPosition(stickPoints[i]));
    return stickPoints;
  }

  return { model, animate, swingStick, isStriking, whereIsStick };
}
