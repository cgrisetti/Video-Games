import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { makeHangingLantern } from './lantern.js';

// The ways into Lanternwood's games: openings in the hedges, each dressed differently so you can
// tell them apart from down the path. Each one is built standing at 0, 0, 0, with its opening
// running along x (OPENING wide) and its front, with the sign, facing +z.
//   - A garden gate: stone pillars, a rose-covered wooden arch with a lantern, and two picket gates.
//     It's the way into Berry Rush (and stands in Berry Rush's hedge too, as the way out).
//   - A hedge archway: the way into Gnome Crossing (and its way out, at the start of the trail).
//   - A rose arbor and a forest trailhead: the ways to games still to come.
// An opening with a game behind it has the game's name over it and a lantern lit; the others have
// a "Coming soon" sign on a post beside them.

export const OPENING = 2.4; // How wide the gap in the hedge is.

const stone = new THREE.MeshStandardMaterial({ color: 0xcfc4ae, roughness: 0.95, flatShading: true });
const wood = new THREE.MeshStandardMaterial({ color: 0x8b6a43, roughness: 0.85 });
const darkWood = new THREE.MeshStandardMaterial({ color: 0x5b4030, roughness: 0.9 });
const picket = new THREE.MeshStandardMaterial({ color: 0xeee3c8, roughness: 0.8 });
const leaves = new THREE.MeshStandardMaterial({ color: 0x4f8f45, roughness: 0.8, flatShading: true });
const hedgeLeaves = new THREE.MeshStandardMaterial({ color: 0x3f8c3c, roughness: 0.8, flatShading: true });
const roses = new THREE.MeshStandardMaterial({ color: 0xe0577c, roughness: 0.6 });
const rope = new THREE.MeshStandardMaterial({ color: 0xc9b083, roughness: 1 });

// --- The pieces ---

function mesh(geometry, material, x = 0, y = 0, z = 0) {
  const part = new THREE.Mesh(geometry, material);
  part.position.set(x, y, z);
  part.castShadow = true;
  return part;
}

// A curve over the opening: up from one side, over the top and down the other.
function archCurve(halfWidth, bottom, rise) {
  const points = [];
  for (let i = 0; i <= 16; i++) {
    const t = i / 16;
    points.push(new THREE.Vector3(-halfWidth + 2 * halfWidth * t, bottom + rise * Math.sin(Math.PI * t), 0));
  }
  return new THREE.CatmullRomCurve3(points);
}

// Leaves (and maybe flowers) scattered along a curve, like a vine growing over it.
function vine(curve, count, size, flowers) {
  const leafBlobs = [];
  const bloomBalls = [];
  for (let i = 0; i < count; i++) {
    const spot = curve.getPoint((i + 0.5) / count);
    const wobble = Math.sin(i * 2.4);
    leafBlobs.push(new THREE.IcosahedronGeometry(size * (0.8 + 0.3 * wobble), 0).translate(spot.x, spot.y + 0.05 * wobble, 0.1 * wobble));
    if (flowers && i % 2 === 0) bloomBalls.push(new THREE.SphereGeometry(size * 0.35, 8, 6).translate(spot.x + 0.1, spot.y + size * 0.4, size * 0.6));
  }
  const group = new THREE.Group();
  group.add(mesh(mergeGeometries(leafBlobs), leaves));
  if (bloomBalls.length) group.add(mesh(mergeGeometries(bloomBalls), roses));
  return group;
}

// A pair of little picket gates across the opening. Each has a row of pickets with pointed tops,
// dipping toward the middle, and two rails. They're shut, or (`open`) swung back on their hinges
// to let you through.
function picketGates(width, height, open = false) {
  const pieces = [];
  const half = width / 2;
  for (const side of [-1, 1]) {
    const gate = [];
    const count = 6;
    for (let i = 0; i < count; i++) {
      const x = side * (0.06 + ((i + 0.5) / count) * (half - 0.08));
      const tall = height * (0.8 + 0.2 * (Math.abs(x) / half)); // Lower toward the middle.
      gate.push(new THREE.BoxGeometry(0.09, tall, 0.04).translate(x, tall / 2, 0));
      gate.push(new THREE.ConeGeometry(0.065, 0.12, 4).rotateY(Math.PI / 4).translate(x, tall + 0.06, 0));
    }
    for (const y of [height * 0.25, height * 0.62]) {
      gate.push(new THREE.BoxGeometry(half - 0.06, 0.07, 0.05).translate(side * (half / 2 + 0.02), y, -0.04));
    }
    // Swing open: turn each gate on its hinge at the side of the opening, away from the front.
    if (open) for (const piece of gate) piece.translate(-side * half, 0, 0).rotateY(-side * 1.3).translate(side * half, 0, 0);
    pieces.push(...gate);
  }
  return mesh(mergeGeometries(pieces), picket);
}

// A board with the opening's name painted on it, on the front only (its back is plain wood).
export function makeSignBoard(text, { width = 1.7, height = 0.46, berry = false } = {}) {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = Math.round((512 * height) / width);
  const ctx = canvas.getContext('2d');
  // Warm wood with a few darker grain lines, and a painted border.
  ctx.fillStyle = '#a07a4c';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.strokeStyle = 'rgba(70, 45, 20, 0.25)';
  ctx.lineWidth = 2;
  for (let y = 10; y < canvas.height; y += 13) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.bezierCurveTo(170, y + 4, 340, y - 4, 512, y + 2);
    ctx.stroke();
  }
  ctx.strokeStyle = '#f6ecd2';
  ctx.lineWidth = 6;
  ctx.strokeRect(10, 10, canvas.width - 20, canvas.height - 20);
  // The name, in cream paint with a brown shadow, and a raspberry beside it for Berry Rush.
  // Long names are painted smaller, so they fit inside the border.
  const textX = berry ? canvas.width / 2 + 24 : canvas.width / 2;
  const room = canvas.width - (berry ? 120 : 64);
  let size = Math.round(canvas.height * 0.5);
  const font = () => `bold ${size}px Luminari, Palatino, 'Palatino Linotype', Georgia, serif`;
  ctx.font = font();
  while (ctx.measureText(text).width > room && size > 12) {
    size -= 2;
    ctx.font = font();
  }
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = '#4a2e18';
  ctx.fillText(text, textX + 3, canvas.height / 2 + 4);
  ctx.fillStyle = '#fff6e0';
  ctx.fillText(text, textX, canvas.height / 2 + 1);
  if (berry) {
    const left = textX - ctx.measureText(text).width / 2 - 34;
    paintBerry(ctx, left, canvas.height / 2 + 2, canvas.height * 0.13);
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  const front = new THREE.MeshStandardMaterial({ map: texture, roughness: 0.8 });
  const board = new THREE.Mesh(new THREE.BoxGeometry(width, height, 0.07), [wood, wood, wood, wood, front, wood]);
  board.castShadow = true;
  return board;
}

function paintBerry(ctx, x, y, r) {
  ctx.fillStyle = '#c8325f';
  for (const [dx, dy] of [[-1, -1], [1, -1], [-1.6, 0.5], [0, 0.5], [1.6, 0.5], [-0.8, 2], [0.8, 2], [0, 3.3]]) {
    ctx.beginPath();
    ctx.arc(x + dx * r * 0.95, y + dy * r * 0.9, r, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.fillStyle = '#4e9a3a';
  ctx.beginPath();
  ctx.moveTo(x, y - r * 1.6);
  ctx.lineTo(x - r * 1.8, y - r * 2.6);
  ctx.lineTo(x - r * 0.5, y - r * 2.7);
  ctx.lineTo(x, y - r * 3.8);
  ctx.lineTo(x + r * 0.5, y - r * 2.7);
  ctx.lineTo(x + r * 1.8, y - r * 2.6);
  ctx.closePath();
  ctx.fill();
}

// A finger-post, like the ones where footpaths meet: a board with a name on it, its end cut to a
// point, on a tall post. The name faces +z, and it points along x, toward `point` (1 or -1).
export function makeFingerpost(text, point = 1) {
  const post = new THREE.Group();
  post.add(mesh(new THREE.CylinderGeometry(0.06, 0.075, 1.75, 7).translate(0, 0.875, 0), darkWood));
  const width = 1.5;
  const height = 0.42;
  const board = makeSignBoard(text, { width, height });
  board.position.set(point * (width / 2 + 0.04), 1.42, 0.07);
  post.add(board);
  // The point: a wedge of wood on the end of the board.
  const reach = height / Math.sqrt(3); // So the wedge is exactly as tall as the board.
  const tip = mesh(new THREE.CylinderGeometry(reach, reach, 0.07, 3).rotateX(Math.PI / 2).rotateZ((point * Math.PI) / 2), wood);
  tip.position.set(point * (width + 0.04 + reach / 2), 1.42, 0.07);
  post.add(tip);
  return post;
}

// A sign on its own little post, beside an opening.
function signpost(text) {
  const post = new THREE.Group();
  post.add(mesh(new THREE.CylinderGeometry(0.06, 0.07, 1.3, 7).translate(0, 0.65, 0), darkWood));
  const board = makeSignBoard(text, { width: 1.25, height: 0.4 });
  board.position.set(0, 1.12, 0.07);
  board.rotation.z = -0.04; // Hung just a little crooked.
  post.add(board);
  return post;
}

// A painted "Gnome Crossing" sign, like the deer crossing signs beside country roads: a mustard
// diamond with a little gnome striding across it, on a post, with the name on a board beneath.
export function makeCrossingSign() {
  const sign = new THREE.Group();
  sign.add(mesh(new THREE.CylinderGeometry(0.06, 0.07, 2.1, 7).translate(0, 1.05, 0), darkWood));

  const size = 256;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#4a2e18';
  ctx.fillRect(0, 0, size, size);
  ctx.fillStyle = '#e8b33a';
  ctx.fillRect(14, 14, size - 28, size - 28);
  // The board is turned 45° to stand on a corner, so paint the gnome turned back the other way.
  ctx.translate(size / 2, size / 2);
  ctx.rotate(-Math.PI / 4);
  ctx.fillStyle = '#4a2e18';
  ctx.strokeStyle = '#4a2e18';
  ctx.lineCap = 'round';
  const path = (points) => {
    ctx.beginPath();
    points.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)));
    ctx.fill();
  };
  path([[-18, -38], [-2, -92], [16, -36]]); // The pointy hat, flopping back.
  ctx.beginPath();
  ctx.arc(0, -30, 15, 0, Math.PI * 2); // Head.
  ctx.fill();
  path([[-12, -24], [14, -24], [2, 4]]); // Beard.
  path([[-16, -14], [16, -14], [24, 26], [-24, 26]]); // Tunic.
  ctx.lineWidth = 11;
  for (const [hipX, footX, footY] of [[-9, -30, 62], [9, 30, 60]]) {
    // Legs mid-stride, with boots.
    ctx.beginPath();
    ctx.moveTo(hipX, 22);
    ctx.lineTo(footX, footY);
    ctx.stroke();
    ctx.beginPath();
    ctx.ellipse(footX + 6, footY + 2, 10, 6, 0, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.lineWidth = 8;
  ctx.beginPath(); // An arm swinging forward, and the walking stick.
  ctx.moveTo(10, -8);
  ctx.lineTo(30, 10);
  ctx.stroke();
  ctx.lineWidth = 5;
  ctx.beginPath();
  ctx.moveTo(38, -26);
  ctx.lineTo(26, 62);
  ctx.stroke();

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  const front = new THREE.MeshStandardMaterial({ map: texture, roughness: 0.8 });
  const diamond = new THREE.Mesh(new THREE.BoxGeometry(0.8, 0.8, 0.06), [wood, wood, wood, wood, front, wood]);
  diamond.castShadow = true;
  diamond.rotation.z = Math.PI / 4;
  diamond.position.set(0, 1.78, 0.08);
  sign.add(diamond);
  const board = makeSignBoard('Gnome Crossing', { width: 1.3, height: 0.32 });
  board.position.set(0, 1.0, 0.08);
  sign.add(board);
  return sign;
}

// --- The openings ---

// The garden gate into Berry Rush, with its name over the arch. In the woods its gates stand `open`.
export function makeGardenGate(name = 'Berry Rush', { open = false } = {}) {
  const gate = new THREE.Group();
  const pillarX = OPENING / 2 + 0.28;
  for (const side of [-1, 1]) {
    const x = side * pillarX;
    gate.add(mesh(new THREE.BoxGeometry(0.5, 1.5, 0.5), stone, x, 0.75, 0));
    gate.add(mesh(new THREE.BoxGeometry(0.62, 0.12, 0.62), stone, x, 1.56, 0));
    gate.add(mesh(new THREE.SphereGeometry(0.16, 10, 8), stone, x, 1.76, 0));
  }
  // A wooden arch springing from the pillars, with climbing roses.
  const curve = archCurve(pillarX, 1.62, 1.05);
  gate.add(mesh(new THREE.TubeGeometry(curve, 32, 0.07, 6), wood));
  gate.add(vine(curve, 18, 0.16, true));
  // The name on a board across the top, and a lantern hanging under it.
  const board = makeSignBoard(name, { berry: true });
  board.position.set(0, 2.3, 0.12);
  gate.add(board);
  const lamp = makeHangingLantern();
  lamp.position.set(0, 2.05, 0);
  gate.add(lamp);
  gate.add(picketGates(OPENING, 1.05, open));
  return gate;
}

// An archway grown from the hedge itself, with a little gate shut across it. With a game behind
// it (`open`), its name hangs across the front of the arch with a lantern glowing underneath, and
// its gates stand open (unless `gatesOpen` says otherwise).
export function makeHedgeArch(sign = 'Coming soon', { open = false, gatesOpen = open } = {}) {
  const arch = new THREE.Group();
  const blobs = [];
  const curve = archCurve(OPENING / 2 + 0.35, 0, 2.6);
  for (let i = 0; i <= 22; i++) {
    const spot = curve.getPoint(i / 22);
    blobs.push(new THREE.IcosahedronGeometry(0.42 + 0.06 * Math.sin(i * 1.7), 1).translate(spot.x, spot.y + 0.2, 0));
  }
  arch.add(mesh(mergeGeometries(blobs), hedgeLeaves));
  arch.add(picketGates(OPENING * 0.9, 0.9, gatesOpen));
  if (open) {
    const board = makeSignBoard(sign);
    board.position.set(0, 2.62, 0.46);
    arch.add(board);
    const lamp = makeHangingLantern();
    lamp.position.set(0, 2.35, 0);
    arch.add(lamp);
  } else {
    const post = signpost(sign);
    post.position.set(OPENING / 2 + 0.9, 0, 0.9);
    arch.add(post);
  }
  return arch;
}

// A wooden arbor of posts and crossbeams, covered in roses: the entrance to a garden.
export function makeArbor(sign = 'Coming soon') {
  const arbor = new THREE.Group();
  const halfX = OPENING / 2 + 0.1;
  for (const x of [-halfX, halfX]) {
    for (const z of [-0.45, 0.45]) arbor.add(mesh(new THREE.BoxGeometry(0.12, 2.3, 0.12), picket, x, 1.15, z));
  }
  for (let i = 0; i < 6; i++) {
    const z = -0.6 + (i / 5) * 1.2;
    arbor.add(mesh(new THREE.BoxGeometry(OPENING + 0.9, 0.08, 0.08), picket, 0, 2.34, z));
  }
  for (const z of [-0.45, 0.45]) arbor.add(mesh(new THREE.BoxGeometry(0.08, 0.12, 0.1), picket, 0, 2.28, z));
  // Roses climbing up both sides and across the top.
  for (const x of [-halfX, halfX]) {
    arbor.add(vine(new THREE.CatmullRomCurve3([new THREE.Vector3(x, 0.2, 0.5), new THREE.Vector3(x + 0.05, 1.2, 0.48), new THREE.Vector3(x, 2.3, 0.4)]), 8, 0.15, true));
  }
  arbor.add(vine(new THREE.CatmullRomCurve3([new THREE.Vector3(-halfX, 2.42, 0), new THREE.Vector3(0, 2.5, 0.1), new THREE.Vector3(halfX, 2.42, 0)]), 10, 0.17, true));
  arbor.add(picketGates(OPENING * 0.9, 0.85));
  const post = signpost(sign);
  post.position.set(-(OPENING / 2 + 0.9), 0, 0.9);
  arbor.add(post);
  return arbor;
}

// An old garden door, like the hidden one in The Secret Garden: a round-topped wooden door in an
// ivy-covered stone wall, with a lantern beside it and the name above. `open` swings the door open.
export const DOORWAY = 1.5; // How wide the doorway is.
export const DOOR_WALL = OPENING + 1.2; // How wide the whole wall is.
const doorWood = new THREE.MeshStandardMaterial({ color: 0x6b4a2c, roughness: 0.85 });
const iron = new THREE.MeshStandardMaterial({ color: 0x3b3631, roughness: 0.5, metalness: 0.4 });
const ivy = new THREE.MeshStandardMaterial({ color: 0x35693a, roughness: 0.8, flatShading: true });

export function makeGardenDoor(name, { open = false } = {}) {
  const door = new THREE.Group();
  const half = DOOR_WALL / 2;
  const top = 3.5;
  const archY = 2.0; // Where the doorway's round top begins.
  const radius = DOORWAY / 2;

  // The wall: one stone slab with the round-topped doorway cut out of the bottom.
  const outline = new THREE.Shape();
  outline.moveTo(-half, 0);
  outline.lineTo(-radius, 0);
  outline.lineTo(-radius, archY);
  outline.absarc(0, archY, radius, Math.PI, 0, true);
  outline.lineTo(radius, 0);
  outline.lineTo(half, 0);
  outline.lineTo(half, top);
  outline.lineTo(-half, top);
  outline.closePath();
  const wall = new THREE.ExtrudeGeometry(outline, { depth: 0.6, bevelEnabled: false, curveSegments: 16 }).translate(0, 0, -0.3);
  door.add(mesh(wall, stone));
  // A few stones standing out from the wall, and coping stones along the top.
  for (const [x, y, w, h] of [[-1.3, 0.5, 0.5, 0.3], [1.25, 1.2, 0.45, 0.28], [-1.15, 2.4, 0.55, 0.3], [1.35, 2.9, 0.4, 0.26], [-1.45, 1.6, 0.35, 0.25]]) {
    door.add(mesh(new THREE.BoxGeometry(w, h, 0.1), stone, x, y, 0.32));
  }
  door.add(mesh(new THREE.BoxGeometry(DOOR_WALL + 0.2, 0.16, 0.8), stone, 0, top + 0.08, 0));

  // The door: planks with a round top, iron hinges and a ring to pull, hung from its left side.
  const leaf = new THREE.Group();
  const planks = [];
  for (let i = 0; i < 5; i++) {
    const x = -radius + (i + 0.5) * (DOORWAY / 5);
    const tall = archY + Math.sqrt(Math.max(radius * radius - x * x, 0)) - 0.02;
    planks.push(new THREE.BoxGeometry(DOORWAY / 5 - 0.02, tall, 0.1).translate(x + radius, tall / 2, 0));
  }
  leaf.add(mesh(mergeGeometries(planks), doorWood));
  for (const y of [0.5, 1.7]) leaf.add(mesh(new THREE.BoxGeometry(0.8, 0.08, 0.04), iron, 0.4, y, 0.07));
  const ring = mesh(new THREE.TorusGeometry(0.09, 0.018, 6, 12), iron, DOORWAY - 0.3, 1.1, 0.09);
  leaf.add(ring);
  leaf.position.set(-radius, 0, 0.05);
  leaf.rotation.y = open ? -1.9 : 0; // Swung wide open, toward whoever is coming.
  door.add(leaf);

  // Ivy climbing up both sides and spilling over the top.
  for (const side of [-1, 1]) {
    const climb = new THREE.CatmullRomCurve3([
      new THREE.Vector3(side * (half - 0.25), 0.2, 0.35),
      new THREE.Vector3(side * (half - 0.45), 1.6, 0.36),
      new THREE.Vector3(side * (half - 0.2), top, 0.3),
      new THREE.Vector3(side * 0.6, top + 0.15, 0.2),
    ]);
    door.add(vineOf(climb, 16, 0.2, ivy));
  }

  // A lantern beside the door, and the name above it.
  const lamp = makeHangingLantern();
  lamp.position.set(radius + 0.45, archY + 0.75, 0.45);
  door.add(mesh(new THREE.BoxGeometry(0.06, 0.06, 0.5), iron, radius + 0.45, archY + 0.78, 0.25));
  door.add(lamp);
  const board = makeSignBoard(name, { width: 1.9 });
  board.position.set(0, archY + radius + 0.42, 0.36);
  door.add(board);
  return door;
}

// Leaves along a curve in a chosen material (like vine(), without flowers).
function vineOf(curve, count, size, material) {
  const blobs = [];
  for (let i = 0; i < count; i++) {
    const spot = curve.getPoint((i + 0.5) / count);
    const wobble = Math.sin(i * 2.4);
    blobs.push(new THREE.IcosahedronGeometry(size * (0.8 + 0.3 * wobble), 0).translate(spot.x + 0.08 * wobble, spot.y, spot.z));
  }
  return mesh(mergeGeometries(blobs), material);
}

// Where a forest path leads off into the trees: two posts with a rope sagging between them.
export function makeTrailhead(sign = 'Coming soon') {
  const trail = new THREE.Group();
  const halfX = OPENING / 2;
  for (const x of [-halfX, halfX]) trail.add(mesh(new THREE.CylinderGeometry(0.09, 0.11, 1, 7), darkWood, x, 0.5, 0));
  const sag = new THREE.CatmullRomCurve3([
    new THREE.Vector3(-halfX, 0.85, 0),
    new THREE.Vector3(0, 0.62, 0),
    new THREE.Vector3(halfX, 0.85, 0),
  ]);
  trail.add(mesh(new THREE.TubeGeometry(sag, 16, 0.025, 5), rope));
  const post = signpost(sign);
  post.position.set(halfX + 0.8, 0, 0.7);
  trail.add(post);
  return trail;
}
