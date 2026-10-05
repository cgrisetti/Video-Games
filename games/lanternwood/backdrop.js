import * as THREE from 'three';
import { PHI, GOLDEN_ANGLE } from './golden.js';
import { seededRandom } from './scenery.js';

// The painted backdrop: a soft blue sky with big puffy clouds over layers of rolling wooded
// hills and faraway blue mountains, in a hand-painted storybook style. It's painted once onto a
// canvas with ordinary 2D drawing, then wrapped around the inside of a big open cylinder that
// surrounds the world.
//
// It follows the same rules as the 3D woods, the way a background painter would:
//   - Trees grow in groves of odd numbers (1, 3, 5, 7), big, medium and small, with bare grassy
//     stretches between them, instead of an even fringe of trees along every hilltop.
//   - Each grove is mostly one kind, so autumn colors come in drifts.
//   - Each layer of hills is a row of rounded humps of different sizes, a few big ones among
//     smaller ones, so the skyline rolls instead of repeating.
//   - Faraway things are paler, bluer and softer (the air between gets in the way), and a little
//     mist lies in the valleys between layers, so each layer stands clear of the one behind.
//   - Clouds gather in groups, a big one with a smaller one or two nearby, with open sky between.

export const SKY_COLOR = '#74b6e8'; // The top of the sky. The scene background uses it too, so they meet without a seam.
export const HAZE_COLOR = '#c2dbe0'; // The pale blue-green of faraway hills. The fog uses it too.

const RADIUS = 40; // Berry Rush's size. Bigger areas ask for a bigger one.
const BOTTOM = -1; // The backdrop covers world heights from BOTTOM to TOP.
const TOP = 15;
const WIDTH = 6144; // Canvas size in pixels. The painting goes round the circle twice.
const HEIGHT = 777; // Tall enough for the clouds to billow without their tops being cut off.
const REPEATS = 2;
const SEED = 11; // Change it for a different (but just as carefully arranged) painting.

// The layers, from farthest to nearest. Each one is lower, greener and less hazy than the one
// behind, and its trees are φ (the golden ratio) times bigger. Hill counts are Fibonacci numbers.
const LAYERS = [
  { mountains: true, height: 7.4, rise: 3.6, hills: 8, light: '#bccde0', dark: '#aec2d6' },
  { height: 6.1, rise: 2.6, hills: 8, light: '#b3d1c4', dark: '#a0c3b4', treeSize: 12, haze: 0.6 },
  { height: 4.6, rise: 2.3, hills: 13, light: '#98c387', dark: '#7aa96f', treeSize: 12 * PHI, haze: 0.32 },
  { height: 3.1, rise: 1.7, hills: 21, light: '#6ea85f', dark: '#4f8a4a', treeSize: 12 * PHI * PHI, haze: 0.08 },
];
// The kinds of tree in the groves, in the same Fibonacci mix as the woods around the field.
const KINDS = { pine: 13, round: 8, maple: 5, poplar: 5, oak: 3 };
const TREE_COLORS = { pine: '#2f6f3c', round: '#4f8f40', maple: '#a8503a', poplar: '#c99a3e', oak: '#476b37' };
// Small groves come in odd numbers; faraway woods read as one mass, in Fibonacci numbers of trees.
const GROVE_SIZES = [3, 5, 7, 13, 21, 34];
const GLADE_CHANCE = 0.3; // How often a spot for a grove is left as open grass.

// The painted backdrop, as a cylinder `radius` across around the world. It's painted only once,
// and every area that asks for one shares the same painting.
let painting = null;

export function createBackdrop({ radius = RADIUS } = {}) {
  painting ??= paint();
  const backdrop = new THREE.Mesh(
    new THREE.CylinderGeometry(radius, radius, TOP - BOTTOM, 128, 1, true),
    new THREE.MeshBasicMaterial({ map: painting, side: THREE.BackSide, fog: false }),
  );
  backdrop.position.y = (TOP + BOTTOM) / 2;
  return backdrop;
}

function paint() {
  const canvas = document.createElement('canvas');
  canvas.width = WIDTH;
  canvas.height = HEIGHT;
  const ctx = canvas.getContext('2d');
  const random = seededRandom(SEED);

  paintSky(ctx, random);
  LAYERS.forEach((layer, i) => {
    const crest = makeCrest(layer, random);
    paintHills(ctx, layer, crest, random);
    if (!layer.mountains) paintGroves(ctx, layer, crest, random);
    const next = LAYERS[i + 1];
    if (next) paintMist(ctx, next);
  });

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.wrapS = THREE.RepeatWrapping;
  texture.repeat.x = REPEATS;
  texture.anisotropy = 8;
  return texture;
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

// The distance from a to b across the canvas, the short way round (it wraps).
function across(a, b) {
  const d = Math.abs(a - b) % WIDTH;
  return Math.min(d, WIDTH - d);
}

// Mix two colors: amount 0 is all `from`, 1 is all `to`.
function mix(from, to, amount) {
  return `#${new THREE.Color(from).lerp(new THREE.Color(to), amount).getHexString()}`;
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

// --- Sky and clouds ---

function paintSky(ctx, random) {
  const sky = ctx.createLinearGradient(0, 0, 0, row(3));
  sky.addColorStop(0, SKY_COLOR);
  sky.addColorStop(0.5, '#a9d3f1');
  sky.addColorStop(0.85, '#d8ecf3');
  sky.addColorStop(1, '#eef3ea'); // A warm glow low in the sky.
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  // Long thin wisps low down, behind the mountains.
  for (let i = 0; i < 7; i++) {
    const x = random() * WIDTH;
    const y = row(8.2 + random() * 1.6);
    const length = 300 + random() * 500;
    wrapped(x, length, (cx) => {
      ctx.fillStyle = 'rgba(255, 255, 255, 0.35)';
      ctx.beginPath();
      ctx.ellipse(cx, y, length / 2, 5 + random() * 5, 0, 0, Math.PI * 2);
      ctx.fill();
    });
  }

  // Groups of clouds: a big billowing one, sometimes with a smaller one drifting nearby.
  const groups = spread(random, 5, WIDTH / 6.5);
  for (const x of groups) {
    const members = 1 + Math.floor(random() * 2);
    let width = 320 + random() * 200;
    let offset = 0;
    let base = row(9.6 + random() * 1.4);
    for (let k = 0; k < members; k++) {
      const puffs = cloudPuffs(width, k === 0 ? 1.25 : 0.9, random);
      const cx = x + offset;
      wrapped(cx, width, (wx) => paintCloud(ctx, wx, base, puffs));
      // The next one is smaller (by the golden ratio), off to one side and a little higher or lower.
      offset += (random() < 0.5 ? -1 : 1) * width * (0.85 + random() * 0.5);
      width /= PHI;
      base += (random() - 0.5) * 70;
    }
  }
}

// Random spots along the canvas, each at least `gap` from the others: spread out, never in a row.
function spread(random, count, gap) {
  const spots = [];
  for (let attempt = 0; attempt < 500 && spots.length < count; attempt++) {
    const x = random() * WIDTH;
    if (spots.every((other) => across(other, x) > gap)) spots.push(x);
  }
  return spots;
}

// A cloud is a mound of round puffs, biggest in the middle, on a flat bottom. `billow` makes it taller.
function cloudPuffs(width, billow, random) {
  const count = Math.max(4, Math.round(width / 26));
  const puffs = [];
  for (let i = 0; i < count; i++) {
    const t = i / (count - 1); // 0 at the left end, 1 at the right.
    const bulge = Math.sin(Math.PI * t) ** 0.8;
    const radius = width * (0.08 + 0.13 * bulge) * (0.8 + random() * 0.35);
    puffs.push({ dx: (t - 0.5) * width, dy: -radius * (0.35 + 0.6 * bulge * billow) - random() * 10, radius });
  }
  // A few more on top, for the tallest middle part.
  for (let i = 0; i < 3 * billow; i++) {
    const radius = width * (0.1 + random() * 0.06);
    puffs.push({ dx: (random() - 0.5) * width * 0.4, dy: -width * 0.22 * billow - random() * 20, radius });
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

// --- Hills and mountains ---

// The top edge of a layer: a row of rounded humps (or pointed peaks, for mountains) of different
// widths and heights. Where two overlap, the taller one shows, like hills one behind another.
function makeCrest(layer, random) {
  const humps = [];
  const spacing = WIDTH / layer.hills;
  for (let i = 0; i < layer.hills; i++) {
    const big = random() < 0.3; // A few big hills among the smaller ones.
    humps.push({
      x: (i + random() * 0.8) * spacing,
      width: spacing * (big ? 0.75 : 0.4 + random() * 0.25), // Half its width, really.
      rise: layer.rise * (big ? 0.85 + random() * 0.3 : 0.35 + random() * 0.4),
    });
  }
  const ripple = random() * Math.PI * 2;
  const swell = random() * Math.PI * 2;
  const heights = new Float32Array(WIDTH + 1);
  for (let x = 0; x <= WIDTH; x++) {
    let height = 0;
    for (const hump of humps) {
      const u = across(x, hump.x) / hump.width;
      if (u >= 1) continue;
      const shape = layer.mountains ? (1 - u) ** 1.25 * (1 + 0.3 * u) : Math.sqrt(1 - u * u); // Peaks, or domes.
      height = Math.max(height, hump.rise * shape);
    }
    // A long slow swell underneath, so there are no flat stretches between hills,
    // and a gentle wobble along the top, so no edge is perfectly smooth.
    const under = layer.rise * 0.18 * (1 + Math.sin((x / WIDTH) * Math.PI * 2 * 3 + swell));
    heights[x] = layer.height + Math.max(height, under) + 0.06 * Math.sin((x / WIDTH) * Math.PI * 2 * 89 + ripple);
  }
  return (x) => heights[Math.round(((x % WIDTH) + WIDTH) % WIDTH)];
}

function paintHills(ctx, layer, crest, random) {
  const hill = new Path2D();
  hill.moveTo(0, HEIGHT);
  for (let x = 0; x <= WIDTH; x += 4) hill.lineTo(x, row(crest(x)));
  hill.lineTo(WIDTH, HEIGHT);
  hill.closePath();
  const shading = ctx.createLinearGradient(0, row(layer.height + layer.rise), 0, row(layer.height - 3));
  shading.addColorStop(0, layer.light);
  shading.addColorStop(1, layer.dark);
  ctx.fillStyle = shading;
  ctx.fill(hill);

  ctx.save();
  ctx.clip(hill);
  // Sunlight along the tops, like a painter's rim light.
  const top = new Path2D();
  for (let x = -8; x <= WIDTH + 8; x += 4) top.lineTo(x, row(crest(x)) + 4);
  ctx.lineWidth = 10;
  ctx.strokeStyle = 'rgba(255, 252, 225, 0.16)';
  ctx.stroke(top);
  // Long soft strokes following the slope, like the brush marks of meadows and fields.
  for (let i = 0; i < WIDTH / 60; i++) {
    const x = random() * WIDTH;
    const y = row(crest(x)) + 12 + random() * 70;
    const length = 60 + random() * 160;
    ctx.fillStyle = random() < 0.5 ? 'rgba(255, 255, 230, 0.06)' : 'rgba(20, 60, 30, 0.06)';
    wrapped(x, length, (dx) => {
      ctx.beginPath();
      ctx.ellipse(dx, y, length, 4 + random() * 5, (row(crest(x + 40)) - row(crest(x - 40))) / 80, 0, Math.PI * 2);
      ctx.fill();
    });
  }
  ctx.restore();
}

// A soft band of mist in the valleys, just where the next layer of hills will stand in front.
function paintMist(ctx, next) {
  const top = row(next.height + next.rise * 0.9);
  const bottom = row(next.height - 0.4);
  const mist = ctx.createLinearGradient(0, top, 0, bottom);
  mist.addColorStop(0, 'rgba(226, 238, 240, 0)');
  mist.addColorStop(1, 'rgba(226, 238, 240, 0.55)');
  ctx.fillStyle = mist;
  ctx.fillRect(0, top, WIDTH, bottom - top);
}

// --- Trees ---

// Groves along the hills: some on the hilltops, breaking the skyline, some down the slopes.
function paintGroves(ctx, layer, crest, random) {
  const kinds = Object.entries(KINDS).flatMap(([kind, count]) => Array(count).fill(kind));
  const groveGap = layer.treeSize * 5;
  const trees = [];
  for (const x of spread(random, Math.round(WIDTH / groveGap), groveGap)) {
    if (random() < GLADE_CHANCE) continue; // Leave it as open grass.
    const kind = kinds[Math.floor(random() * kinds.length)];
    const count = kind === 'oak' ? 1 : GROVE_SIZES[Math.floor(random() * GROVE_SIZES.length)];
    const down = random() < 0.45 ? 0 : random() * layer.rise * 1.3; // On the top, or this far down the slope (in world units).
    const biggest = layer.treeSize * (0.95 + random() * 0.35);
    const startAngle = random() * Math.PI * 2;
    for (let k = 0; k < count; k++) {
      // Biggest first, then each one a golden angle round and a little further out, and smaller.
      const angle = startAngle + k * GOLDEN_ANGLE;
      const out = biggest * 0.5 * Math.sqrt(k) * (0.8 + random() * 0.4);
      const tx = x + Math.cos(angle) * out;
      const ty = row(crest(tx) - down) + Math.sin(angle) * out * 0.3 + biggest * 0.3;
      const neighbor = k > 0 && random() < 0.2; // One in five is a different kind, at the edge.
      trees.push({
        x: tx,
        y: ty,
        size: biggest * (1 - 0.3 * Math.sqrt(k / count)) * (0.92 + random() * 0.16),
        kind: neighbor ? (random() < 0.5 ? 'pine' : 'round') : kind,
        shade: 0.9 + random() * 0.2,
      });
    }
  }
  // Paint from the back (higher up the canvas) to the front, so nearer trees overlap farther ones.
  trees.sort((a, b) => a.y - b.y);
  for (const tree of trees) wrapped(tree.x, tree.size * 2, (tx) => paintTree(ctx, tx, tree.y, tree, layer));
}

// A little painted tree in three tones: shadow on the left, its own color, and sunlight on the right.
// It's mixed with the haze color by how far away its layer is.
function paintTree(ctx, x, y, tree, layer) {
  const { size, kind } = tree;
  const base = mix(new THREE.Color(TREE_COLORS[kind]).multiplyScalar(tree.shade).getStyle(), HAZE_COLOR, layer.haze);
  const shadow = mix(base, '#1d3b2a', 0.35 * (1 - layer.haze));
  const light = mix(base, '#fff6d0', 0.28);
  const trunk = mix('#5b4030', HAZE_COLOR, layer.haze);

  if (size > 14 && kind !== 'pine') {
    ctx.fillStyle = trunk;
    ctx.fillRect(x - size * 0.05, y - size * 0.6, size * 0.1, size * 0.6);
  }
  if (kind === 'pine') {
    ctx.fillStyle = shadow;
    triangle(ctx, x, y - size * 1.55, size * 0.44, y);
    ctx.fillStyle = base;
    triangle(ctx, x + size * 0.05, y - size * 1.5, size * 0.36, y - size * 0.05);
    ctx.fillStyle = light;
    ctx.beginPath();
    ctx.moveTo(x + size * 0.05, y - size * 1.5);
    ctx.lineTo(x + size * 0.41, y - size * 0.05);
    ctx.lineTo(x + size * 0.15, y - size * 0.05);
    ctx.closePath();
    ctx.fill();
  } else if (kind === 'poplar') {
    puffs(ctx, x, y, size, [[0, -0.95, 0.32, 0.7], [0, -1.5, 0.24, 0.5]], shadow, base, light);
  } else if (kind === 'oak') {
    puffs(ctx, x, y, size, [[-0.5, -0.75, 0.42, 0.26], [0.5, -0.75, 0.42, 0.26], [0, -0.9, 0.55, 0.3]], shadow, base, light);
  } else {
    puffs(ctx, x, y, size, [[0, -0.75, 0.48, 0.48], [-0.32, -0.5, 0.36, 0.36], [0.32, -0.52, 0.36, 0.36]], shadow, base, light);
  }
}

function triangle(ctx, x, topY, halfWidth, bottomY) {
  ctx.beginPath();
  ctx.moveTo(x, topY);
  ctx.lineTo(x + halfWidth, bottomY);
  ctx.lineTo(x - halfWidth, bottomY);
  ctx.closePath();
  ctx.fill();
}

// A leafy crown made of soft ovals [dx, dy, width, height] (in tree sizes): shadow, then color, then light.
function puffs(ctx, x, y, size, ovals, shadow, base, light) {
  const paint = (color, shiftX, shiftY, shrink) => {
    ctx.fillStyle = color;
    for (const [dx, dy, rx, ry] of ovals) {
      ctx.beginPath();
      ctx.ellipse(x + (dx + shiftX) * size, y + (dy + shiftY) * size, rx * size * shrink, ry * size * shrink, 0, 0, Math.PI * 2);
      ctx.fill();
    }
  };
  paint(shadow, 0, 0, 1);
  paint(base, 0.06, -0.05, 0.86);
  ctx.globalAlpha = 0.55;
  paint(light, 0.16, -0.14, 0.42);
  ctx.globalAlpha = 1;
}
