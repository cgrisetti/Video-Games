import * as THREE from 'three';
import { paintShader } from './painterly.js';

// Painted foliage: leaves and grass that look brushed on, instead of smooth balls and cones.
//
// Leaf cards. A treetop in a Ghibli background isn't a smooth ball: it's hundreds of little clumps
// of leaves, each catching the light on its own. So over each lump of leaves we scatter "cards":
// small flat pictures of a clump of leaves that always turn to face the camera (billboards), sway
// in the breeze, and are lit as if they were part of one big round crown. The lump underneath
// stays, a little darker, so the gaps between clumps look like shade deep in the tree.
//
// Grass. Tufts of grass blades, thousands of them drawn in one go, darker at the root and sunlit
// at the tip, bending in gusts of wind that roll across the meadow.
//
// The leaf pictures are painted onto canvases in code, so there are no image files.

// Tweak these to change the foliage.
const CARDS_PER_AREA = 11; // Leaf clumps per square unit of a treetop's surface.
const CARD_SIZE = 0.3; // How big a leaf clump is (half its width).
const WIND_SWAY = 0.035; // How far leaf clumps sway in the breeze.
const GRASS_WIND = 0.09; // How far the tips of the grass blades bend in the wind.

// --- The leaf pictures ---

// Paint a picture on a square canvas with `draw(ctx, size, random)` and make it a texture.
function paintTexture(size, draw, seed = 1) {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  let s = seed;
  const random = () => ((s = (s * 16807) % 2147483647) - 1) / 2147483646;
  draw(ctx, size, random);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  return texture;
}

// One leaf: a pointed oval with a lighter vein down the middle. Grey, so it takes the tree's color.
function drawLeaf(ctx, x, y, angle, length, width, shade) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(angle);
  ctx.beginPath();
  ctx.moveTo(0, 0);
  ctx.quadraticCurveTo(width, length * 0.35, 0, length);
  ctx.quadraticCurveTo(-width, length * 0.35, 0, 0);
  const grey = Math.round(255 * shade);
  ctx.fillStyle = `rgb(${grey},${grey},${grey})`;
  ctx.fill();
  ctx.strokeStyle = `rgba(60,60,60,0.35)`;
  ctx.lineWidth = 1.5;
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(0, length * 0.1);
  ctx.lineTo(0, length * 0.8);
  ctx.strokeStyle = `rgba(255,255,255,0.35)`;
  ctx.lineWidth = 1.2;
  ctx.stroke();
  ctx.restore();
}

// A clump of broad leaves (maples, poplars, round trees, oaks): leaves fanning out from the middle,
// lighter at the top where the sun reaches them.
export const broadLeafTexture = paintTexture(128, (ctx, size, random) => {
  const c = size / 2;
  for (let i = 0; i < 26; i++) {
    const angle = random() * Math.PI * 2;
    const out = Math.sqrt(random()) * size * 0.3;
    const x = c + Math.cos(angle) * out;
    const y = c + Math.sin(angle) * out;
    const length = size * (0.16 + random() * 0.1);
    const shade = 0.62 + 0.38 * (1 - y / size) * 0.8 + random() * 0.12;
    drawLeaf(ctx, x, y, angle - Math.PI / 2 + (random() - 0.5) * 0.9, length, length * 0.42, Math.min(shade, 1));
  }
}, 3);

// A spray of pine boughs: drooping sprigs, each a stem with short needles brushed along both
// sides, layered so the top ones catch the light.
export const needleTexture = paintTexture(128, (ctx, size, random) => {
  ctx.lineCap = 'round';
  for (let i = 0; i < 11; i++) {
    const side = i % 2 === 0 ? 1 : -1;
    const x0 = size * (0.5 + (random() - 0.5) * 0.25);
    const y0 = size * (0.22 + 0.5 * (i / 11));
    const length = size * (0.26 + random() * 0.12);
    const droop = 0.25 + random() * 0.3;
    const grey = Math.round(255 * Math.min(1, 0.55 + 0.45 * (1 - y0 / size) + random() * 0.1));
    ctx.strokeStyle = `rgb(${grey},${grey},${grey})`;
    for (let k = 0; k <= 14; k++) {
      const t = k / 14;
      const x = x0 + side * length * t;
      const y = y0 + length * droop * t * t;
      const needle = 7 * (1 - t * 0.6);
      ctx.lineWidth = 2.4;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + side * needle * 0.6, y - needle * 0.7);
      ctx.moveTo(x, y);
      ctx.lineTo(x + side * needle * 0.6, y + needle * 0.8);
      ctx.stroke();
    }
  }
}, 7);

// Little round leaves packed close, for the hedges and shrubs.
export const hedgeLeafTexture = paintTexture(128, (ctx, size, random) => {
  const c = size / 2;
  for (let i = 0; i < 40; i++) {
    const angle = random() * Math.PI * 2;
    const out = Math.sqrt(random()) * size * 0.34;
    const x = c + Math.cos(angle) * out;
    const y = c + Math.sin(angle) * out;
    const length = size * (0.1 + random() * 0.06);
    drawLeaf(ctx, x, y, random() * Math.PI * 2, length, length * 0.6, Math.min(0.65 + 0.35 * (1 - y / size) + random() * 0.1, 1));
  }
}, 11);

// A single leaf, for leaves falling through the air.
export const singleLeafTexture = paintTexture(64, (ctx, size) => {
  drawLeaf(ctx, size / 2, size * 0.08, 0, size * 0.84, size * 0.36, 1);
}, 5);

// --- Leaf cards ---

// Leaf cards: a MeshStandardMaterial (so it's painted and lit like everything else) whose cards
// turn to face the camera and sway in the wind. A class, so copies of it (trees that fade when
// they're in the way) keep the billboard shader too.
export class LeafCardMaterial extends THREE.MeshStandardMaterial {
  constructor(parameters) {
    super({ roughness: 0.9, alphaTest: 0.5, ...parameters });
    this.userData.paint = 'leaves';
  }

  onBeforeCompile(shader) {
    paintShader.call(this, shader);
    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', `#include <common>\nattribute vec2 cardCorner;\nattribute float cardSpin;\nattribute float cardSize;`)
      .replace(
        '#include <project_vertex>',
        `vec4 mvPosition = vec4(transformed, 1.0);
        float cardScale = length(modelMatrix[0].xyz);
        #ifdef USE_INSTANCING
          mvPosition = instanceMatrix * mvPosition;
          cardScale *= length(instanceMatrix[0].xyz);
        #endif
        vec4 cardWorld = modelMatrix * mvPosition;
        // Sway: each clump bobs on its own, and gusts roll through the whole wood.
        float gust = sin(uPaintTime * 0.9 + cardWorld.x * 0.15 + cardWorld.z * 0.1);
        cardWorld.x += (sin(uPaintTime * 1.7 + cardSpin * 5.0 + cardWorld.y) + gust) * ${WIND_SWAY} * cardScale;
        cardWorld.z += cos(uPaintTime * 1.3 + cardSpin * 3.0 + cardWorld.x) * ${WIND_SWAY} * 0.6 * cardScale;
        mvPosition = viewMatrix * cardWorld;
        float a = cardSpin + sin(uPaintTime * 2.1 + cardSpin * 9.0) * 0.1;
        vec2 corner = mat2(cos(a), sin(a), -sin(a), cos(a)) * cardCorner;
        mvPosition.xy += corner * cardSize * cardScale;
        gl_Position = projectionMatrix * mvPosition;`,
      );
  }

  customProgramCacheKey() {
    return 'leaf-cards';
  }
}

// Scatter leaf cards over the outside of a shape (a lump of leaves, or a pine's cone), as many as
// fit its surface. They all face the camera, but they're lit as if they faced out of the shape.
export function leafCards(geometry, { density = CARDS_PER_AREA, size = CARD_SIZE, seed = 1, skipUnderside = true } = {}) {
  const source = geometry.index ? geometry.toNonIndexed() : geometry;
  const positions = source.attributes.position;
  let s = seed * 9973 + 1;
  const random = () => ((s = (s * 16807) % 2147483647) - 1) / 2147483646;

  // Each triangle's area, so bigger ones get more cards.
  const a = new THREE.Vector3();
  const b = new THREE.Vector3();
  const c = new THREE.Vector3();
  const triangles = [];
  let total = 0;
  for (let i = 0; i < positions.count; i += 3) {
    a.fromBufferAttribute(positions, i);
    b.fromBufferAttribute(positions, i + 1);
    c.fromBufferAttribute(positions, i + 2);
    const normal = new THREE.Triangle(a, b, c).getNormal(new THREE.Vector3());
    if (skipUnderside && normal.y < -0.55) continue;
    const area = new THREE.Triangle(a, b, c).getArea();
    total += area;
    triangles.push({ i, area, total, normal });
  }
  const count = Math.max(4, Math.round(total * density));

  const position = [];
  const normal = [];
  const uv = [];
  const corner = [];
  const spin = [];
  const cardSize = [];
  const index = [];
  const point = new THREE.Vector3();
  const lean = new THREE.Vector3();
  for (let k = 0; k < count; k++) {
    const pick = random() * total;
    const triangle = triangles.find((t) => t.total >= pick) ?? triangles[triangles.length - 1];
    a.fromBufferAttribute(positions, triangle.i);
    b.fromBufferAttribute(positions, triangle.i + 1);
    c.fromBufferAttribute(positions, triangle.i + 2);
    let u = random();
    let v = random();
    if (u + v > 1) [u, v] = [1 - u, 1 - v];
    point.copy(a).addScaledVector(b.clone().sub(a), u).addScaledVector(c.clone().sub(a), v);
    const n = triangle.normal;
    const sz = size * (0.75 + 0.5 * random());
    point.addScaledVector(n, sz * 0.25); // Sitting out a little from the surface.
    lean.copy(n).add(new THREE.Vector3(0, 0.35, 0)).normalize(); // Lit a little more from above.
    const turn = random() * Math.PI * 2;
    const base = k * 4;
    for (const [cx, cy] of [[-1, -1], [1, -1], [1, 1], [-1, 1]]) {
      position.push(point.x, point.y, point.z);
      normal.push(lean.x, lean.y, lean.z);
      uv.push((cx + 1) / 2, (cy + 1) / 2);
      corner.push(cx, cy);
      spin.push(turn);
      cardSize.push(sz);
    }
    index.push(base, base + 1, base + 2, base, base + 2, base + 3);
  }

  const cards = new THREE.BufferGeometry();
  cards.setAttribute('position', new THREE.Float32BufferAttribute(position, 3));
  cards.setAttribute('normal', new THREE.Float32BufferAttribute(normal, 3));
  cards.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  cards.setAttribute('cardCorner', new THREE.Float32BufferAttribute(corner, 2));
  cards.setAttribute('cardSpin', new THREE.Float32BufferAttribute(spin, 1));
  cards.setAttribute('cardSize', new THREE.Float32BufferAttribute(cardSize, 1));
  cards.setIndex(index);
  cards.computeBoundingSphere();
  cards.boundingSphere.radius += size * 1.5; // The cards reach out past their middles.
  cards.computeBoundingBox();
  cards.boundingBox.expandByScalar(size * 1.5);
  return cards;
}

// --- Grass ---

// One tuft: a handful of tapering blades leaning out from the middle, each in three bends.
function makeTuftGeometry(random) {
  const position = [];
  const tip = [];
  const index = [];
  const blades = 7;
  for (let b = 0; b < blades; b++) {
    const angle = (b / blades) * Math.PI * 2 + random() * 0.6;
    const out = 0.04 + random() * 0.06;
    const height = 0.2 + random() * 0.2;
    const width = 0.022 + random() * 0.012;
    const lean = 0.08 + random() * 0.12;
    const dx = Math.cos(angle);
    const dz = Math.sin(angle);
    const face = angle + Math.PI / 2 + (random() - 0.5);
    const fx = Math.cos(face);
    const fz = Math.sin(face);
    const start = position.length / 3;
    const levels = 3;
    for (let l = 0; l < levels; l++) {
      const t = l / levels;
      const bend = lean * t * t;
      const cx = dx * (out + bend);
      const cz = dz * (out + bend);
      const w = width * (1 - t * 0.75);
      position.push(cx - fx * w, height * t, cz - fz * w, cx + fx * w, height * t, cz + fz * w);
      tip.push(t, t);
    }
    position.push(dx * (out + lean), height, dz * (out + lean));
    tip.push(1);
    for (let l = 0; l < levels - 1; l++) {
      const i = start + l * 2;
      index.push(i, i + 1, i + 3, i, i + 3, i + 2);
    }
    const last = start + (levels - 1) * 2;
    index.push(last, last + 1, last + 2);
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(position, 3));
  // Every blade faces straight up as far as the light is concerned, so the grass is lit just like
  // the ground it grows from and blends into it, instead of flickering dark and light.
  geometry.setAttribute('normal', new THREE.Float32BufferAttribute(position.map((_, i) => (i % 3 === 1 ? 1 : 0)), 3));
  geometry.setAttribute('bladeTip', new THREE.Float32BufferAttribute(tip, 1));
  geometry.setIndex(index);
  return geometry;
}

// Grass blades: painted, darker at the root and sunlit at the tip, bending in the wind.
class GrassMaterial extends THREE.MeshStandardMaterial {
  constructor() {
    super({ color: 0xffffff, roughness: 1, side: THREE.DoubleSide });
    this.userData.paint = 'grass';
  }

  onBeforeCompile(shader) {
    paintShader.call(this, shader);
    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', `#include <common>\nattribute float bladeTip;\nvarying float vBladeTip;`)
      .replace(
        '#include <begin_vertex>',
        `vec3 transformed = vec3(position);
        vBladeTip = bladeTip;
        {
          vec3 root = (modelMatrix * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
          #ifdef USE_INSTANCING
            root = (modelMatrix * instanceMatrix * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
          #endif
          float bend = bladeTip * bladeTip;
          // Gusts roll across the meadow in waves; each tuft also flutters on its own.
          float gust = sin(uPaintTime * 1.4 - root.x * 0.25 - root.z * 0.18) * 0.5 + 0.5;
          float flutter = sin(uPaintTime * 4.3 + root.x * 3.1 + root.z * 2.7);
          transformed.x += (gust * 1.0 + flutter * 0.3) * ${GRASS_WIND} * bend;
          transformed.z += (gust * 0.5 + cos(uPaintTime * 3.7 + root.z * 2.3) * 0.3) * ${GRASS_WIND} * bend;
          transformed.y -= gust * ${GRASS_WIND} * 0.4 * bend;
        }`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace('#include <common>', `#include <common>\nvarying float vBladeTip;`)
      // Both sides of a blade face up to the light, so the back of a blade isn't dark.
      .replace('#include <normal_fragment_begin>', `#include <normal_fragment_begin>\nnormal = normalize(vNormal);`)
      .replace(
        '#include <color_fragment>',
        `#include <color_fragment>
        diffuseColor.rgb *= mix(0.78, 1.1, vBladeTip);
        diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb * vec3(1.1, 1.06, 0.8), smoothstep(0.6, 1.0, vBladeTip) * 0.25);`,
      );
  }

  customProgramCacheKey() {
    return 'grass';
  }
}

const grassMaterial = new GrassMaterial();

// A meadow of grass: `count` tufts, placed by `spot(random)`, which returns [x, z] for a tuft or
// null to skip that one. `color(x, z, random)` gives each tuft its color, and `height(x, z)` (if
// given) the height of the ground. All drawn at once, so thousands of tufts stay fast.
export function makeGrass({ count, spot, color, height = () => 0, seed = 1, scale = [0.8, 1.4] }) {
  let s = seed * 7919 + 3;
  const random = () => ((s = (s * 16807) % 2147483647) - 1) / 2147483646;
  const geometry = makeTuftGeometry(random);
  const tufts = [];
  for (let i = 0; i < count; i++) {
    const at = spot(random);
    if (at) tufts.push(at);
  }
  const mesh = new THREE.InstancedMesh(geometry, grassMaterial, tufts.length);
  const matrix = new THREE.Matrix4();
  const turn = new THREE.Quaternion();
  const size = new THREE.Vector3();
  const position = new THREE.Vector3();
  tufts.forEach(([x, z], i) => {
    turn.setFromAxisAngle(THREE.Object3D.DEFAULT_UP, random() * Math.PI * 2);
    const grow = scale[0] + (scale[1] - scale[0]) * random();
    size.set(grow, grow * (0.8 + 0.4 * random()), grow);
    mesh.setMatrixAt(i, matrix.compose(position.set(x, height(x, z), z), turn, size));
    mesh.setColorAt(i, color(x, z, random));
  });
  mesh.receiveShadow = true;
  return mesh;
}
