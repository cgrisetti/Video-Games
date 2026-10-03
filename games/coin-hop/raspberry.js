import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// A raspberry to collect: a rounded cone of little juicy bumps, with a green leafy cap on top.

const berryMaterial = new THREE.MeshStandardMaterial({ color: 0xd8285c, emissive: 0x420016, roughness: 0.4 });
const capMaterial = new THREE.MeshStandardMaterial({ color: 0x4e9a3a, roughness: 0.7, flatShading: true });
const berryGeometry = makeBerryGeometry();
const capGeometry = makeCapGeometry();

export function makeRaspberry() {
  const berry = new THREE.Group();
  const body = new THREE.Mesh(berryGeometry, berryMaterial);
  const cap = new THREE.Mesh(capGeometry, capMaterial);
  body.castShadow = true;
  cap.castShadow = true;
  berry.add(body, cap);
  return berry;
}

// Rings of little balls, widest near the top and narrowing to a rounded tip, around a core
// that fills the gaps. They're merged into one shape so each raspberry is quick to draw.
function makeBerryGeometry() {
  const bump = 0.1;
  const pieces = [new THREE.SphereGeometry(0.27, 16, 12).scale(1, 1.1, 1).translate(0, -0.07, 0)];
  const rings = 7;
  for (let ring = 0; ring <= rings; ring++) {
    const t = ring / rings; // 0 at the top, 1 at the tip.
    const y = 0.22 - t * 0.6;
    const radius = 0.34 * Math.sin(Math.PI * (0.25 + 0.7 * t));
    const count = Math.max(1, Math.round((2 * Math.PI * radius) / (bump * 1.7)));
    for (let i = 0; i < count; i++) {
      const angle = ((i + (ring % 2) * 0.5) / count) * Math.PI * 2; // Every other ring is shifted half a step.
      pieces.push(new THREE.SphereGeometry(bump, 8, 6).translate(Math.cos(angle) * radius, y, Math.sin(angle) * radius));
    }
  }
  return mergeGeometries(pieces);
}

// Five flat little leaves spreading out from the top, and a short stem.
function makeCapGeometry() {
  const pieces = [new THREE.CylinderGeometry(0.025, 0.035, 0.16, 6).translate(0, 0.38, 0)];
  for (let i = 0; i < 5; i++) {
    const leaf = new THREE.ConeGeometry(0.08, 0.28, 4);
    leaf.scale(0.4, 1, 1); // Flatten it into a leaf.
    leaf.rotateZ(-Math.PI / 2 - 0.35); // Lay it down, pointing outward and a little downward.
    leaf.translate(0.13, 0.3, 0);
    leaf.rotateY((i / 5) * Math.PI * 2);
    pieces.push(leaf);
  }
  return mergeGeometries(pieces);
}
