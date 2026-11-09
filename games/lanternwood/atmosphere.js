import * as THREE from 'three';
import { singleLeafTexture } from './foliage.js';

// The air of Lanternwood: autumn leaves drifting down, tumbling as they fall, and specks of pollen
// and dust floating in the sunlight, glowing gold. They drift round wherever the camera is looking,
// in whichever area you're in, the way a film keeps a little life moving in every shot.

// Tweak these to change the air.
const LEAF_COUNT = 140;
const MOTE_COUNT = 220;
const SPREAD = 22; // How far round the camera they drift (across).
const DEPTH = 26; // How far in front of the camera they reach.
const LEAF_FALL = 0.55; // How fast leaves fall.
const LEAF_COLORS = [0xd9542c, 0xe8892f, 0xf0b53a, 0xc23f2a, 0xb8732e, 0xe6c35a];

export function createAtmosphere() {
  const group = new THREE.Group();

  // Leaves: one shape drawn for every leaf at once, each with its own spot, spin and color.
  const leafMaterial = new THREE.MeshStandardMaterial({ map: singleLeafTexture, alphaTest: 0.5, side: THREE.DoubleSide, roughness: 0.9 });
  leafMaterial.userData.paint = 'plain';
  const leafGeometry = new THREE.PlaneGeometry(0.16, 0.2);
  const leaves = new THREE.InstancedMesh(leafGeometry, leafMaterial, LEAF_COUNT);
  leaves.frustumCulled = false;
  const leafState = [];
  const color = new THREE.Color();
  for (let i = 0; i < LEAF_COUNT; i++) {
    leafState.push({
      position: new THREE.Vector3(),
      spin: new THREE.Vector3(Math.random() * 3, Math.random() * 3, Math.random() * 3),
      phase: Math.random() * Math.PI * 2,
      flutter: 0.8 + Math.random() * 1.2,
      placed: false,
    });
    leaves.setColorAt(i, color.set(LEAF_COLORS[i % LEAF_COLORS.length]));
  }
  group.add(leaves);

  // Motes: tiny glowing specks, added to the light rather than drawn over it.
  const moteGeometry = new THREE.BufferGeometry();
  const motePositions = new Float32Array(MOTE_COUNT * 3);
  moteGeometry.setAttribute('position', new THREE.BufferAttribute(motePositions, 3));
  const motes = new THREE.Points(
    moteGeometry,
    new THREE.PointsMaterial({ map: makeMoteTexture(), color: 0xffd98a, size: 0.09, transparent: true, opacity: 0.8, depthWrite: false, blending: THREE.AdditiveBlending, fog: false }),
  );
  motes.frustumCulled = false;
  const moteState = Array.from({ length: MOTE_COUNT }, () => ({ position: new THREE.Vector3(), phase: Math.random() * 100, placed: false }));
  group.add(motes);

  const center = new THREE.Vector3();
  const forward = new THREE.Vector3();
  const matrix = new THREE.Matrix4();
  const rotation = new THREE.Quaternion();
  const euler = new THREE.Euler();
  const one = new THREE.Vector3(1, 1, 1);
  let time = 0;

  // A fresh spot somewhere in the box of air in front of the camera; `top` puts it up high, to fall from.
  function scatter(position, top) {
    position.set(
      center.x + (Math.random() - 0.5) * SPREAD,
      top ? 5 + Math.random() * 2 : 0.2 + Math.random() * 6,
      center.z + (Math.random() - 0.5) * SPREAD,
    );
  }

  // Keep things inside the box round the camera: anything that drifts out comes back on the far side.
  function wrap(position) {
    const half = SPREAD / 2;
    if (position.x < center.x - half) position.x += SPREAD;
    if (position.x > center.x + half) position.x -= SPREAD;
    if (position.z < center.z - half) position.z += SPREAD;
    if (position.z > center.z + half) position.z -= SPREAD;
  }

  function update(scene, camera, dt) {
    if (group.parent !== scene) scene.add(group);
    time += dt;
    camera.getWorldDirection(forward);
    forward.y = 0;
    forward.normalize();
    center.copy(camera.position).addScaledVector(forward, DEPTH * 0.45);

    for (let i = 0; i < LEAF_COUNT; i++) {
      const leaf = leafState[i];
      if (!leaf.placed) {
        scatter(leaf.position, false);
        leaf.placed = true;
      }
      // Falling leaves don't drop straight: they swing side to side like a pendulum as they go.
      const swing = Math.sin(time * leaf.flutter + leaf.phase);
      leaf.position.y -= LEAF_FALL * (0.7 + 0.3 * Math.abs(swing)) * dt;
      leaf.position.x += (swing * 0.6 + 0.25) * dt;
      leaf.position.z += Math.cos(time * leaf.flutter * 0.7 + leaf.phase) * 0.35 * dt;
      if (leaf.position.y < 0.02) scatter(leaf.position, true);
      wrap(leaf.position);
      euler.set(leaf.spin.x * time + swing, leaf.spin.y * time, leaf.spin.z * time * 0.5 + swing * 0.8);
      leaves.setMatrixAt(i, matrix.compose(leaf.position, rotation.setFromEuler(euler), one));
    }
    leaves.instanceMatrix.needsUpdate = true;

    for (let i = 0; i < MOTE_COUNT; i++) {
      const mote = moteState[i];
      if (!mote.placed) {
        scatter(mote.position, false);
        mote.position.y = 0.3 + Math.random() * 3.5;
        mote.placed = true;
      }
      mote.position.x += Math.sin(time * 0.3 + mote.phase) * 0.12 * dt;
      mote.position.y += Math.sin(time * 0.5 + mote.phase * 1.3) * 0.08 * dt;
      mote.position.z += Math.cos(time * 0.27 + mote.phase) * 0.12 * dt;
      wrap(mote.position);
      mote.position.toArray(motePositions, i * 3);
    }
    moteGeometry.attributes.position.needsUpdate = true;
  }

  return { update };
}

// A soft round speck of light.
function makeMoteTexture() {
  const size = 32;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  const gradient = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  gradient.addColorStop(0, 'rgba(255,255,255,1)');
  gradient.addColorStop(0.3, 'rgba(255,240,200,0.6)');
  gradient.addColorStop(1, 'rgba(255,220,150,0)');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, size, size);
  return new THREE.CanvasTexture(canvas);
}
