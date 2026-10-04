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

// The golden raspberry: the same berry in shining gold, a little bigger, with rays of sunshine
// fanning out behind it and a warm glow lighting up the ground around it.
// Its rays are kept in golden.userData.rays so the game can turn them slowly.
const goldMaterial = new THREE.MeshStandardMaterial({ color: 0xffc93c, emissive: 0x7a5200, metalness: 0.55, roughness: 0.3 });
const goldCapMaterial = new THREE.MeshStandardMaterial({ color: 0xb8c94a, emissive: 0x2a3300, roughness: 0.5, flatShading: true });

export function makeGoldenRaspberry() {
  const golden = new THREE.Group();
  const berry = new THREE.Group();
  berry.add(new THREE.Mesh(berryGeometry, goldMaterial), new THREE.Mesh(capGeometry, goldCapMaterial));
  berry.scale.setScalar(1.35);
  for (const part of berry.children) part.castShadow = true;

  // The rays are a picture that always faces the camera, so they look the same from every side.
  const rays = new THREE.Sprite(
    new THREE.SpriteMaterial({ map: makeSunburst(), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
  );
  rays.scale.set(3.4, 3.4, 1);
  const glow = new THREE.PointLight(0xffd36b, 3, 5, 2);
  golden.add(rays, berry, glow);
  golden.userData.rays = rays;
  return golden;
}

// Rays of sunshine painted on a small canvas: a soft glow with long and short rays around it.
function makeSunburst() {
  const size = 256;
  const middle = size / 2;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');

  const glow = ctx.createRadialGradient(middle, middle, 0, middle, middle, middle);
  glow.addColorStop(0, 'rgba(255, 250, 215, 0.95)');
  glow.addColorStop(0.25, 'rgba(255, 222, 120, 0.5)');
  glow.addColorStop(1, 'rgba(255, 200, 80, 0)');
  ctx.fillStyle = glow;
  ctx.fillRect(0, 0, size, size);

  for (let i = 0; i < 24; i++) {
    const long = i % 2 === 0;
    const length = long ? middle * 0.97 : middle * 0.55;
    const width = long ? 0.07 : 0.05; // Half the ray's width, as an angle.
    const angle = (i / 24) * Math.PI * 2;
    const fade = ctx.createRadialGradient(middle, middle, 0, middle, middle, length);
    fade.addColorStop(0, 'rgba(255, 244, 180, 0.9)');
    fade.addColorStop(1, 'rgba(255, 205, 90, 0)');
    ctx.fillStyle = fade;
    ctx.beginPath();
    ctx.moveTo(middle, middle);
    ctx.lineTo(middle + Math.cos(angle - width) * length, middle + Math.sin(angle - width) * length);
    ctx.lineTo(middle + Math.cos(angle + width) * length, middle + Math.sin(angle + width) * length);
    ctx.closePath();
    ctx.fill();
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
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
