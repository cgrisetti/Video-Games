import * as THREE from 'three';
import { PHI, goldenFraction, fibonacciLong } from './golden.js';

// The painted backdrop: a soft blue sky with big puffy clouds over layers of rolling wooded
// hills, in a hand-painted storybook style. It's painted once onto a canvas with ordinary 2D
// drawing, then wrapped around the inside of a big open cylinder that surrounds the world.

export const SKY_COLOR = '#74b6e8'; // The top of the sky. The scene background uses it too, so they meet without a seam.
export const HAZE_COLOR = '#c2dbe0'; // The pale blue-green of faraway hills. The fog uses it too.

const RADIUS = 40;
const BOTTOM = -1; // The backdrop covers world heights from BOTTOM to TOP.
const TOP = 13;
const WIDTH = 4096; // Canvas size in pixels. The painting repeats three times around the circle.
const HEIGHT = 680;
const REPEATS = 3;

export function createBackdrop() {
  const canvas = document.createElement('canvas');
  canvas.width = WIDTH;
  canvas.height = HEIGHT;
  const ctx = canvas.getContext('2d');

  paintSky(ctx);
  // Hills from farthest to nearest: each layer is greener and darker, and its trees are
  // φ (the golden ratio) times bigger than the layer behind.
  paintHills(ctx, { height: 7.4, roll: 1.1, light: '#b4d2c6', dark: '#9fc2b6', trees: '#93b8ab', treeSize: 9 });
  paintHills(ctx, { height: 5.7, roll: 0.9, light: '#8fbd83', dark: '#73a56c', trees: '#5f955a', treeSize: 9 * PHI });
  paintHills(ctx, { height: 3.9, roll: 0.7, light: '#64a05b', dark: '#4a8547', trees: '#3e7a3f', treeSize: 9 * PHI * PHI });

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.wrapS = THREE.RepeatWrapping;
  texture.repeat.x = REPEATS;
  texture.anisotropy = 8;

  const backdrop = new THREE.Mesh(
    new THREE.CylinderGeometry(RADIUS, RADIUS, TOP - BOTTOM, 128, 1, true),
    new THREE.MeshBasicMaterial({ map: texture, side: THREE.BackSide, fog: false }),
  );
  backdrop.position.y = (TOP + BOTTOM) / 2;
  return backdrop;
}

// The canvas row (pixels down from the top) for a height in the world.
function row(height) {
  return ((TOP - height) / (TOP - BOTTOM)) * HEIGHT;
}

// Paint something at x, and again one canvas-width over if it pokes past an edge,
// so the painting joins up seamlessly where its two ends meet.
function wrapped(x, reach, paint) {
  paint(x);
  if (x - reach < 0) paint(x + WIDTH);
  if (x + reach > WIDTH) paint(x - WIDTH);
}

// A soft round dab of paint: one color in the middle, shading to another at the edge.
function blob(ctx, x, y, radius, middle, edge) {
  const paint = ctx.createRadialGradient(x - radius * 0.3, y - radius * 0.3, radius * 0.1, x, y, radius);
  paint.addColorStop(0, middle);
  paint.addColorStop(1, edge);
  ctx.fillStyle = paint;
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fill();
}

// Blue sky, deep at the top and pale near the hills, with big puffy clouds.
function paintSky(ctx) {
  const sky = ctx.createLinearGradient(0, 0, 0, row(2));
  sky.addColorStop(0, SKY_COLOR);
  sky.addColorStop(0.55, '#a9d3f1');
  sky.addColorStop(1, '#dcedf2');
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  for (let i = 0; i < 9; i++) {
    const x = (i + Math.random() * 0.6) * (WIDTH / 9);
    const base = row(THREE.MathUtils.randFloat(8.6, 10.2));
    const width = THREE.MathUtils.randFloat(160, 380);
    const puffs = cloudPuffs(width);
    wrapped(x, width, (cx) => paintCloud(ctx, cx, base, puffs));
  }
}

// A cloud is a row of round puffs, biggest in the middle.
function cloudPuffs(width) {
  const count = Math.round(width / 28);
  const puffs = [];
  for (let i = 0; i < count; i++) {
    const t = i / (count - 1); // 0 at the left end, 1 at the right.
    const bulge = Math.sin(Math.PI * t);
    const radius = width * (0.09 + 0.13 * bulge) * THREE.MathUtils.randFloat(0.8, 1.15);
    puffs.push({ dx: (t - 0.5) * width, dy: -radius * (0.4 + 0.5 * bulge) - Math.random() * 10, radius });
  }
  return puffs;
}

// Shadowed blue-grey undersides first, a little lower, then bright white tops over them.
function paintCloud(ctx, x, base, puffs) {
  for (const p of puffs) {
    blob(ctx, x + p.dx, base + p.dy + p.radius * 0.25, p.radius, 'rgba(178, 194, 222, 0.9)', 'rgba(178, 194, 222, 0)');
  }
  for (const p of puffs) {
    blob(ctx, x + p.dx + p.radius * 0.1, base + p.dy - p.radius * 0.1, p.radius * 0.92, 'rgba(255, 255, 255, 0.98)', 'rgba(236, 242, 250, 0.85)');
  }
}

// One layer of rolling hills, with a fringe of trees along the top and more scattered down the slopes.
function paintHills(ctx, layer) {
  // A few gentle waves, each fitting a whole number of times across the canvas so the ends join up.
  const waves = [3, 7, 13].map((count, i) => ({ count, size: layer.roll / (i + 1), shift: Math.random() * Math.PI * 2 }));
  const crest = (x) =>
    row(layer.height + waves.reduce((sum, w) => sum + w.size * Math.sin((x / WIDTH) * w.count * Math.PI * 2 + w.shift), 0));

  // The hill itself, shaded from light along the top to darker below.
  const hill = new Path2D();
  hill.moveTo(0, HEIGHT);
  for (let x = 0; x <= WIDTH; x += 8) hill.lineTo(x, crest(x));
  hill.lineTo(WIDTH, HEIGHT);
  hill.closePath();
  const shading = ctx.createLinearGradient(0, row(layer.height + layer.roll * 1.8), 0, HEIGHT);
  shading.addColorStop(0, layer.light);
  shading.addColorStop(1, layer.dark);
  ctx.fillStyle = shading;
  ctx.fill(hill);

  // Soft dabs of lighter and darker paint inside the hill, like brush strokes.
  ctx.save();
  ctx.clip(hill);
  for (let i = 0; i < 260; i++) {
    const x = Math.random() * WIDTH;
    const y = crest(x) + Math.random() * (HEIGHT - crest(x));
    const across = 20 + Math.random() * 50;
    const tall = 6 + Math.random() * 12;
    ctx.fillStyle = Math.random() < 0.5 ? 'rgba(255, 255, 230, 0.07)' : 'rgba(20, 60, 30, 0.07)';
    wrapped(x, across, (dx) => {
      ctx.beginPath();
      ctx.ellipse(dx, y, across, tall, 0, 0, Math.PI * 2);
      ctx.fill();
    });
  }
  ctx.restore();

  // Trees: a dense fringe along the top of the hill, spaced in the Fibonacci rhythm of long and
  // short gaps (in the golden ratio), with sizes from the golden sequence so neighbors differ.
  for (let k = 0, x = 0; x < WIDTH; k++) {
    const size = layer.treeSize * (0.75 + 0.5 * goldenFraction(k));
    const round = fibonacciLong(k + 3);
    wrapped(x, size, (tx) => paintTree(ctx, tx, crest(x) + size * 0.35, size, layer.trees, round));
    x += layer.treeSize * (fibonacciLong(k) ? 0.95 : 0.95 / PHI);
  }
  // A few more down the slope, spread evenly along the hill by the golden sequence.
  for (let i = 0; i < WIDTH / (layer.treeSize * 3); i++) {
    const x = goldenFraction(i) * WIDTH;
    const size = layer.treeSize * (0.6 + 0.5 * goldenFraction(i + 7));
    const y = crest(x) + size * (1 + 3 * (((i * 3) % 8) / 8));
    const round = fibonacciLong(i);
    wrapped(x, size, (tx) => paintTree(ctx, tx, y, size, layer.trees, round));
  }
}

// A little painted tree, either round and puffy or a pointy pine, with sunlight on its right side.
function paintTree(ctx, x, y, size, color, round) {
  ctx.fillStyle = color;
  if (round) {
    for (const [dx, dy, r] of [[0, -0.55, 0.5], [-0.32, -0.3, 0.38], [0.32, -0.3, 0.38]]) {
      ctx.beginPath();
      ctx.arc(x + dx * size, y + dy * size, r * size, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.fillStyle = 'rgba(255, 255, 220, 0.18)';
    ctx.beginPath();
    ctx.arc(x + 0.15 * size, y - 0.68 * size, 0.28 * size, 0, Math.PI * 2);
    ctx.fill();
  } else {
    ctx.beginPath();
    ctx.moveTo(x, y - size * 1.5);
    ctx.lineTo(x + size * 0.42, y);
    ctx.lineTo(x - size * 0.42, y);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = 'rgba(255, 255, 220, 0.14)';
    ctx.beginPath();
    ctx.moveTo(x, y - size * 1.5);
    ctx.lineTo(x + size * 0.42, y);
    ctx.lineTo(x + size * 0.08, y);
    ctx.closePath();
    ctx.fill();
  }
}
