import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { makeRipples, WATER_LEVEL } from './creek.js';
import { makeRock, makeLog, makeToadstool, makeBlueberryBush, createTreePool } from './scenery.js';
import { makeLantern } from './lantern.js';
import { makeSignBoard } from './gates.js';
import { makeRaspberry } from './raspberry.js';
import { makeDeer, makeBoar, makeHedgehog } from './critters.js';
import { playBell } from './sounds.js';

// Gnome Crossing's trail: an endless strip of rows heading north, each one hop deep, made just
// ahead of the gnome and cleared away behind it, like the lanes in Frogger and Crossy Road.
// Each row is one of these:
//   - a meadow: safe grass, with toadstools, rocks, bushes and stumps in the way, a raspberry
//     now and then, and trees, lanterns and flowers along its edges;
//   - a creek: water too deep to wade, with logs drifting along it, or lily pads to hop across;
//   - an animal trail: worn dirt, with deer, wild boars or hedgehog families running along it;
//   - a deer run: a trail where a whole herd thunders through now and then, after a bell rings.
// Rows come in stretches (a creek three lanes wide, say) with meadows between. The further you
// go, the wider the stretches, the faster things move and the less room there is between them.
// Rows are numbered from the start (row 0) going north; row n sits at z = -n * TILE.

// Tweak these to change the trail.
export const TILE = 1.5; // One hop, forward, back or sideways.
export const COLUMNS = 6; // Tiles either side of the middle you can hop to (13 across in all).
export const BACK_ROW = -2; // The furthest back you can hop. The hedge, with the way out, is just behind it.
export const ROWS_AHEAD = 40; // Rows made ready ahead of the gnome...
const ROWS_BEHIND = 9; // ...and kept behind it.
const START_ROWS = 4; // Safe meadow at the start, before the first creek or trail.
const REST_EVERY = 25; // Every 25th row is a meadow with a lantern and a sign saying how far you've come.
const HARDEST_AT = 220; // How far along it stops getting harder.
const LOOP = 72; // Logs and animals go round a loop this long: out one side, back in the other, out of sight.

// Meadows. Pairs like [1, 4] are [at the start, at the hardest].
const BLOCKERS = [1, 4]; // Things in the way across a meadow row.
const BLOCKER_KINDS = { toadstool: 4, rock: 3, bush: 3, stump: 2 }; // How often each kind turns up.
const BERRY_CHANCE = 0.33; // How often a meadow row has a raspberry on it.
const VERGE_TREES = 3; // Trees along each edge of a meadow row.
const TREE_KINDS = { pine: 13, round: 8, maple: 5, poplar: 5, oak: 3 }; // The same mix as the woods round the hallway.
const LANTERN_EVERY = 6; // A lantern on the left edge of the trail this often (on meadow rows).
const FLOWERS = 5; // Little flowers dotted over each meadow row.

// Creeks.
const CREEK_LANES = [[1, 2], [2, 4]]; // How many lanes wide a creek is: [fewest, most] at the start, and at the hardest.
const LOG_SPEED = [1.3, 2.8]; // How fast the logs drift.
const LOG_TILES = [[2, 4], [2, 3]]; // How long logs are, in tiles.
const LOG_GAPS = [[1, 2.5], [1.6, 4]]; // The open water between logs, in tiles.
const LOG_THICKNESS = 0.62;
const PAD_LANE_CHANCE = 0.28; // How often a creek lane has lily pads instead of logs.
const PAD_SHARE = [0.45, 0.3]; // How many of a lily pad lane's tiles have a pad.
const PAD_BERRY_CHANCE = 0.3;

// Animal trails.
const TRAIL_LANES = [[1, 2], [2, 4]];
const ANIMALS = {
  // speed: how fast they run, at the start and at the hardest. gap: room between them, at the start.
  // chance: how often a trail lane has them, at the start and at the hardest.
  hedgehogs: { speed: [1.1, 1.9], gap: 7, chance: [5, 2] },
  boar: { speed: [2.4, 4.4], gap: 7, chance: [3, 4] },
  deer: { speed: [4, 7.2], gap: 10, chance: [2, 5] },
};
const GAP_SHRINK = 0.65; // At the hardest, the room between animals shrinks to 65%.
const HERD = { size: [4, 6], speed: 15, spacing: 2.3, wait: [3, 7], warn: 1.6, from: 30, chance: 0.2 };

// The ground.
const ROW_WIDTH = 84;
const GROUND_DEPTH = 1.2;
const BED_LEVEL = -0.65;
const GRASS = [0x5cae58, 0x53a250]; // Two shades, row by row, so the rows are easy to count.
const DIRT = [0xb39a6c, 0xa98f62];
const BANK = 0x8c7f6d;
const BED = 0x6d6457;
const FLOW_SPEED = 0.5; // How fast the ripples drift.

const difficulty = (index) => THREE.MathUtils.clamp(index / HARDEST_AT, 0, 1);
const ease = ([start, hardest], d) => THREE.MathUtils.lerp(start, hardest, d);
const between = (low, high) => low + (high - low) * Math.random();
const whole = (low, high) => Math.floor(between(low, high + 1)); // A whole number from low to high.
const pick = (list) => list[Math.floor(Math.random() * list.length)];
const weighted = (chances) => {
  const total = Object.values(chances).reduce((sum, chance) => sum + chance, 0);
  let roll = Math.random() * total;
  for (const [kind, chance] of Object.entries(chances)) if ((roll -= chance) < 0) return kind;
  return Object.keys(chances)[0];
};
const wrap = (x) => THREE.MathUtils.euclideanModulo(x + LOOP / 2, LOOP) - LOOP / 2;
const columns = Array.from({ length: COLUMNS * 2 + 1 }, (_, i) => i - COLUMNS);

// --- Shapes and colors, shared by every row ---

// A slab of ground one row deep, its top at height 0: one color on top, bank-brown down the sides.
// (Its faces are put in two groups, top and the rest, so it draws in two goes instead of six.)
function slab(width, height, depth) {
  const box = new THREE.BoxGeometry(width, height, depth).translate(0, -height / 2, 0);
  const index = box.index.array;
  const top = Array.from(index.slice(12, 18)); // The box's third face (+y) is its top.
  const rest = [...index.slice(0, 12), ...index.slice(18)];
  box.setIndex([...top, ...rest]);
  box.clearGroups();
  box.addGroup(0, 6, 0);
  box.addGroup(6, rest.length, 1);
  return box;
}

const groundGeometry = slab(ROW_WIDTH, GROUND_DEPTH, TILE);
const bedGeometry = new THREE.BoxGeometry(ROW_WIDTH, 0.3, TILE).translate(0, BED_LEVEL - 0.15, 0);
const waterGeometry = new THREE.PlaneGeometry(ROW_WIDTH, TILE).rotateX(-Math.PI / 2);
const ground = (color) => new THREE.MeshStandardMaterial({ color, roughness: 1 });
const bankMaterial = ground(BANK);
const grassMaterials = GRASS.map((color) => [ground(color), bankMaterial]);
const dirtMaterials = DIRT.map((color) => [ground(color), bankMaterial]);
const bedMaterial = ground(BED);
// Water flowing west (-1) and east (1), each with its own ripples drifting the right way.
const flows = { [-1]: makeFlow(), 1: makeFlow() };

function makeFlow() {
  const map = makeRipples({ repeat: [ROW_WIDTH / 4, TILE / 4], rotation: 0 });
  return new THREE.MeshStandardMaterial({ map, roughness: 0.2, metalness: 0.1, transparent: true, opacity: 0.88 });
}

// A lily pad: a flat round leaf with a notch, and now and then a water lily on it.
const padGeometry = new THREE.CylinderGeometry(0.58, 0.58, 0.05, 22, 1, false, 0.35, Math.PI * 2 - 0.7);
const padMaterial = new THREE.MeshStandardMaterial({ color: 0x4f9a3e, roughness: 0.7 });
const lilyGeometry = (() => {
  const petals = [];
  for (let i = 0; i < 7; i++) {
    const petal = new THREE.SphereGeometry(1, 8, 6).scale(0.06, 0.04, 0.16).translate(0, 0.07, 0.12);
    petal.rotateX(-0.5).rotateY((i / 7) * Math.PI * 2);
    petals.push(petal);
  }
  return mergeGeometries(petals);
})();
const lilyMaterial = new THREE.MeshStandardMaterial({ color: 0xfbe3ee, roughness: 0.6 });
const lilyMiddle = new THREE.SphereGeometry(0.05, 8, 6).translate(0, 0.09, 0);
const lilyMiddleMaterial = new THREE.MeshStandardMaterial({ color: 0xffcf3a, roughness: 0.5 });

// Little flowers and tufts of grass: one shape for a whole row, colored at its points.
const FLOWER_COLORS = [0xfffaf0, 0xfff1a8, 0xc9b6ef, 0xf6b8d0];
const flowerMaterial = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.8 });

function paint(geometry, color) {
  const c = new THREE.Color(color);
  const colors = new Float32Array(geometry.attributes.position.count * 3);
  for (let i = 0; i < colors.length; i += 3) c.toArray(colors, i);
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  return geometry;
}

function flower(x, z, color) {
  const petals = paint(new THREE.CylinderGeometry(0.09, 0.09, 0.02, 7).translate(x, 0.08, z), color);
  const middle = paint(new THREE.CylinderGeometry(0.035, 0.035, 0.03, 6).translate(x, 0.09, z), 0xf2b631);
  const stem = paint(new THREE.CylinderGeometry(0.008, 0.008, 0.08, 4).translate(x, 0.04, z), 0x3f7f3a);
  return [petals, middle, stem];
}

function tuft(x, z) {
  return [-0.5, 0, 0.5].map((lean) => paint(new THREE.ConeGeometry(0.03, 0.26, 4).rotateZ(lean).translate(x + lean * 0.06, 0.12, z), 0x4c9a44));
}

// --- Signs and lanterns along the trail ---

// Painted boards are made once and copied, so passing a hundred rows doesn't paint a hundred boards.
const boards = new Map();
function board(text, size) {
  if (!boards.has(text)) boards.set(text, makeSignBoard(text, size));
  return boards.get(text).clone();
}

const postMaterial = new THREE.MeshStandardMaterial({ color: 0x5b4030, roughness: 0.9 });
const brassMaterial = new THREE.MeshStandardMaterial({ color: 0xd8a944, metalness: 0.6, roughness: 0.35 });
const pennantMaterial = new THREE.MeshStandardMaterial({ color: 0xffc93c, emissive: 0x6a4600, roughness: 0.5, side: THREE.DoubleSide });

// A lantern with a sign under it saying how many hops from the start this is.
function makeMarker(hops) {
  const marker = makeLantern();
  const sign = board(String(hops), { width: 0.62, height: 0.4 });
  sign.position.set(0, 1.05, 0.08);
  marker.add(sign);
  return marker;
}

// Your best so far: a post with a golden pennant and a "Best" sign.
function makeBestFlag() {
  const flag = new THREE.Group();
  const post = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.06, 2, 7).translate(0, 1, 0), postMaterial);
  const pennant = new THREE.Mesh(new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(0, 2, 0), new THREE.Vector3(0.75, 1.82, 0), new THREE.Vector3(0, 1.62, 0)]), pennantMaterial);
  pennant.geometry.computeVertexNormals();
  const sign = board('Best', { width: 0.8, height: 0.36 });
  sign.position.set(0, 1.08, 0.07);
  for (const part of [post, pennant]) part.castShadow = true;
  flag.add(post, pennant, sign);
  flag.userData.pennant = pennant;
  return flag;
}

// The deer run's warning bell: a post with a crossbar, a little brass bell, and a sign.
function makeBellPost() {
  const post = new THREE.Group();
  post.add(new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.065, 2, 7).translate(0, 1, 0), postMaterial));
  post.add(new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.5, 6).rotateZ(Math.PI / 2).translate(0.22, 1.9, 0), postMaterial));
  const bell = new THREE.Group();
  bell.position.set(0.4, 1.88, 0);
  const cup = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.15, 0.2, 12, 1, true).translate(0, -0.13, 0), brassMaterial);
  cup.material.side = THREE.DoubleSide;
  bell.add(cup, new THREE.Mesh(new THREE.SphereGeometry(0.04, 8, 6).translate(0, -0.25, 0), brassMaterial));
  post.add(bell);
  const sign = board('Deer Run', { width: 1.1, height: 0.36 });
  sign.position.set(0, 1.25, 0.07);
  post.add(sign);
  post.traverse((part) => (part.castShadow = part.isMesh));
  post.userData.bell = bell;
  return post;
}

// --- The trail ---

export function createTrail(scene) {
  const rows = new Map(); // Row number → row.
  const trees = createTreePool(['pine', 'round', 'maple', 'poplar', 'oak', 'stump'], 140);
  scene.add(trees.group);
  const critters = { deer: [], boar: [], hedgehog: [] }; // Animals not out on a trail just now, ready to reuse.
  const lanterns = []; // Lanterns not standing anywhere just now. (Every lantern ever made flickers, so they're reused.)
  const markers = new Map(); // Row number → its marker, made once and kept for the next trip.
  const bestFlag = makeBestFlag();
  let bestRow = 0;
  let plan = null; // The stretch of rows being laid out: { kind, left, dir, herd }.
  let nearRow = 0; // The row the gnome is nearest, for the deer run bells.
  let time = 0;

  // --- Making rows ---

  function makeRow(index) {
    const row = {
      index,
      kind: 'meadow',
      group: new THREE.Group(),
      blocked: new Set(), // Columns with something in the way.
      berry: null, // { col, mesh }
      trees: [], // Tickets from the tree pool.
      lanterns: [],
      speed: 0, // How fast logs or animals move along it (and which way: + is east).
      floaters: [], // Logs and lily pads: { kind, x, half, slots, top, mesh, col }
      animals: [], // { critter, kind, x, half }
      herd: null,
      pads: false,
      extras: [], // Shapes made just for this row, to throw away with it.
    };
    row.group.position.z = -index * TILE;
    const before = rows.get(index - 1);
    const lane = nextLane(index, before);
    row.kind = lane.kind;
    if (lane.kind === 'meadow') buildMeadow(row, before);
    else if (lane.kind === 'creek') buildCreek(row, before, lane);
    else buildTrail(row, lane);
    if (index === bestRow && bestRow > 0) placeBestFlag(row);
    scene.add(row.group);
    rows.set(index, row);
    return row;
  }

  // What the next row is. Rows come in stretches; after a creek or a trail there's usually a
  // meadow to catch your breath, less often the further you go.
  function nextLane(index, before) {
    if (index < START_ROWS || index % REST_EVERY === 0) {
      plan = null;
      return { kind: 'meadow' };
    }
    const d = difficulty(index);
    if (!plan || plan.left === 0) {
      const after = before?.kind ?? 'meadow';
      let kind;
      if (after !== 'meadow' && Math.random() < ease([0.8, 0.45], d)) kind = 'meadow';
      else if (after === 'creek') kind = 'trail';
      else if (after === 'trail') kind = 'creek';
      else kind = Math.random() < 0.5 ? 'creek' : 'trail';
      const lanes = kind === 'creek' ? CREEK_LANES : TRAIL_LANES;
      const herd = kind === 'trail' && index >= HERD.from && Math.random() < HERD.chance;
      const length = kind === 'meadow' ? whole(1, d < 0.5 ? 3 : 2) : herd ? 1 : whole(Math.round(ease([lanes[0][0], lanes[1][0]], d)), Math.round(ease([lanes[0][1], lanes[1][1]], d)));
      plan = { kind, left: length, dir: Math.random() < 0.5 ? -1 : 1, herd };
    }
    plan.left--;
    plan.dir = -plan.dir; // Creek lanes take turns flowing each way.
    return { kind: plan.kind, dir: plan.kind === 'creek' ? plan.dir : Math.random() < 0.5 ? -1 : 1, herd: plan.herd };
  }

  function addGround(row, materials) {
    const slabMesh = new THREE.Mesh(groundGeometry, materials);
    slabMesh.receiveShadow = true;
    row.group.add(slabMesh);
  }

  // --- Meadows ---

  function buildMeadow(row, before) {
    const { index } = row;
    const z = -index * TILE;
    addGround(row, grassMaterials[((index % 2) + 2) % 2]);
    if (index <= BACK_ROW - 1) {
      // The hedge row and the way back to the woods behind it: nothing gets through.
      for (const col of columns) row.blocked.add(col);
    } else {
      placeBlockers(row, before);
    }

    // A raspberry now and then (and always one just ahead at the start, to show the way).
    const free = columns.filter((col) => !row.blocked.has(col));
    if (index === 2) addBerry(row, 0, 0.9);
    else if (index >= START_ROWS && free.length && Math.random() < BERRY_CHANCE) addBerry(row, pick(free), 0.9);

    // Trees along both edges, out past where you can hop (the right edge is the fox's path, so
    // its trees stand a little further out).
    for (const side of [-1, 1]) {
      const spots = [8, 9, 10, 11, 12, 13, 14, 15].sort(() => Math.random() - 0.5).slice(0, VERGE_TREES);
      for (const col of spots) {
        const x = side * (col + (side > 0 ? 0.6 : 0)) * TILE + between(-0.4, 0.4);
        const tint = new THREE.Color().setScalar(between(0.88, 1.05));
        row.trees.push(trees.plant(weighted(TREE_KINDS), x, z + between(-0.45, 0.45), between(0.85, 1.35) * (1 + (col - 8) * 0.05), between(0, 6.3), tint));
      }
    }

    // Lanterns light the left edge of the trail, and every 25th row has a marker saying how far you've come.
    const edge = -(COLUMNS + 1.3) * TILE;
    if (index > 0 && index % REST_EVERY === 0) {
      if (!markers.has(index)) markers.set(index, makeMarker(index));
      const marker = markers.get(index);
      marker.position.set(edge, 0, 0);
      row.group.add(marker);
    } else if (index > 0 && index % LANTERN_EVERY === 0) {
      const lantern = lanterns.pop() ?? makeLantern();
      lantern.position.set(edge, 0, 0);
      row.group.add(lantern);
      row.lanterns.push(lantern);
    }

    // Flowers and tufts of grass, anywhere but under the things in the way.
    const bits = [];
    for (let i = 0; i < FLOWERS; i++) {
      const x = between(-COLUMNS - 3, COLUMNS + 3) * TILE;
      if (row.blocked.has(Math.round(x / TILE))) continue;
      bits.push(...flower(x, between(-0.6, 0.6), pick(FLOWER_COLORS)));
    }
    for (const side of [-1, 1]) bits.push(...tuft(side * (COLUMNS + 0.62) * TILE, between(-0.4, 0.4)));
    const flowers = new THREE.Mesh(mergeGeometries(bits), flowerMaterial);
    for (const bit of bits) bit.dispose();
    row.group.add(flowers);
    row.extras.push(flowers.geometry);
  }

  // Toadstools, rocks, bushes and stumps in the way. Never two side by side, never on the start
  // tile, never on a tile you'd need to reach a lily pad, and always with plenty of ways through.
  function placeBlockers(row, before) {
    const { index } = row;
    const d = difficulty(index);
    const z = -index * TILE;
    const atStart = index < START_ROWS;
    const count = atStart ? (index <= 0 ? 0 : 1) : whole(BLOCKERS[0], Math.round(ease(BLOCKERS, d)));
    const keepClear = new Set(before?.pads ? before.floaters.map((pad) => pad.col) : []);
    for (let attempt = 0; attempt < 10; attempt++) {
      row.blocked.clear();
      for (let tries = 0; row.blocked.size < count && tries < 40; tries++) {
        const col = pick(columns);
        if (atStart && Math.abs(col) < 3) continue;
        if (keepClear.has(col) || row.blocked.has(col - 1) || row.blocked.has(col + 1)) continue;
        row.blocked.add(col);
      }
      // At least three columns open in this row and the meadow before it, so there's always a way on.
      if (before?.kind !== 'meadow' || columns.filter((col) => !row.blocked.has(col) && !before.blocked.has(col)).length >= 3) break;
    }
    for (const col of row.blocked) {
      const kind = weighted(BLOCKER_KINDS);
      const x = col * TILE;
      if (kind === 'stump') {
        row.trees.push(trees.plant('stump', x, z, between(1.4, 1.7), between(0, 6.3)));
        continue;
      }
      let thing;
      if (kind === 'toadstool') thing = makeToadstool(Math.random() < 0.6);
      else if (kind === 'bush') {
        thing = makeBlueberryBush();
        thing.scale.setScalar(between(1, 1.15));
      } else {
        thing = makeRock();
        const width = between(0.52, 0.66);
        thing.scale.set(width, between(0.45, 0.6), width * between(0.85, 1));
      }
      thing.position.x = x;
      thing.rotation.y = between(0, Math.PI * 2);
      row.group.add(thing);
    }
  }

  function addBerry(row, col, height) {
    const mesh = makeRaspberry();
    mesh.position.set(col * TILE, height, 0);
    mesh.userData.height = height;
    mesh.userData.bob = Math.random() * Math.PI * 2;
    row.group.add(mesh);
    row.berry = { col, mesh };
  }

  function placeBestFlag(row) {
    bestFlag.position.set(-(COLUMNS + 2.3) * TILE, row.kind === 'creek' ? BED_LEVEL : 0, 0.2);
    row.group.add(bestFlag);
  }

  // --- Creeks ---

  function buildCreek(row, before, lane) {
    const d = difficulty(row.index);
    const bed = new THREE.Mesh(bedGeometry, bedMaterial);
    bed.receiveShadow = true;
    const water = new THREE.Mesh(waterGeometry, flows[lane.dir]);
    water.position.y = WATER_LEVEL;
    water.receiveShadow = true;
    water.renderOrder = -1;
    row.group.add(bed, water);
    const lilyPads = before?.kind === 'creek' ? !before.pads && Math.random() < PAD_LANE_CHANCE : Math.random() < PAD_LANE_CHANCE;
    if (lilyPads) {
      // Lily pads stay put. Put them where you could hop onto them from the row before.
      row.pads = true;
      const reachable = columns.filter((col) => !before?.blocked.has(col));
      const pads = reachable.filter(() => Math.random() < ease(PAD_SHARE, d));
      while (pads.length < 3) pads.push(pick(reachable.filter((col) => !pads.includes(col))));
      for (const col of pads) {
        const pad = new THREE.Mesh(padGeometry, padMaterial);
        pad.rotation.y = between(0, Math.PI * 2);
        pad.receiveShadow = true;
        pad.position.set(col * TILE, WATER_LEVEL + 0.02, 0);
        if (Math.random() < 0.3) {
          const lily = new THREE.Mesh(lilyGeometry, lilyMaterial);
          const middle = new THREE.Mesh(lilyMiddle, lilyMiddleMaterial);
          lily.position.set(0.25, 0, -0.15);
          middle.position.copy(lily.position);
          pad.add(lily, middle);
        }
        row.group.add(pad);
        row.floaters.push({ kind: 'pad', x: col * TILE, half: 0.6, slots: 1, top: WATER_LEVEL + 0.05, mesh: pad, col, bob: Math.random() * 6, dip: 0 });
      }
      if (Math.random() < PAD_BERRY_CHANCE) addBerry(row, pick(pads), WATER_LEVEL + 0.9);
      return;
    }
    // Logs, end to end with water between, drifting round the loop.
    row.speed = lane.dir * ease(LOG_SPEED, d) * between(0.85, 1.15);
    const [shortest, longest] = d < 0.5 ? LOG_TILES[0] : LOG_TILES[1];
    const gaps = [ease([LOG_GAPS[0][0], LOG_GAPS[1][0]], d), ease([LOG_GAPS[0][1], LOG_GAPS[1][1]], d)];
    let x = -LOOP / 2 + between(0, 2);
    for (;;) {
      const slots = whole(shortest, longest);
      const length = slots * TILE - 0.12;
      if (x + length > LOOP / 2 - gaps[0] * TILE) break;
      const log = makeLog();
      log.scale.set(length, LOG_THICKNESS, LOG_THICKNESS);
      log.position.set(x + length / 2, WATER_LEVEL - LOG_THICKNESS * 0.4, 0);
      row.group.add(log);
      row.floaters.push({ kind: 'log', x: x + length / 2, half: length / 2, slots, top: WATER_LEVEL + LOG_THICKNESS * 0.6, mesh: log, bob: Math.random() * 6 });
      x += length + between(...gaps) * TILE;
    }
  }

  // --- Animal trails ---

  function buildTrail(row, lane) {
    const d = difficulty(row.index);
    addGround(row, dirtMaterials[((row.index % 2) + 2) % 2]);
    row.dir = lane.dir;
    if (lane.herd) {
      buildDeerRun(row);
      return;
    }
    const kind = weighted(Object.fromEntries(Object.entries(ANIMALS).map(([name, animal]) => [name, ease(animal.chance, d)])));
    const animal = ANIMALS[kind];
    row.speed = lane.dir * ease(animal.speed, d) * between(0.9, 1.1);
    let x = -LOOP / 2 + between(0, animal.gap);
    while (x < LOOP / 2 - 3) {
      if (kind === 'hedgehogs') {
        // A mother hedgehog leading her babies in a line.
        const babies = whole(2, 4);
        addAnimal(row, 'hedgehog', x, 0.4, 1);
        for (let i = 1; i <= babies; i++) addAnimal(row, 'hedgehog', x - lane.dir * (0.25 + 0.6 * i), 0.4, 0.6);
        x += babies * 0.6;
      } else {
        addAnimal(row, kind, x, kind === 'deer' ? 1 : 0.85, 1);
      }
      x += animal.gap * between(0.9, 1.7) * THREE.MathUtils.lerp(1, GAP_SHRINK, d);
    }
  }

  function getCritter(kind) {
    return critters[kind].pop() ?? (kind === 'deer' ? makeDeer({ antlers: Math.random() < 0.6 }) : kind === 'boar' ? makeBoar() : makeHedgehog());
  }

  function addAnimal(row, kind, x, half, size) {
    const critter = getCritter(kind);
    critter.model.scale.setScalar(size);
    critter.model.rotation.y = (row.dir * Math.PI) / 2; // Facing the way it runs.
    critter.model.position.set(wrap(x), 0, 0);
    critter.model.visible = true;
    row.group.add(critter.model);
    row.animals.push({ critter, kind, x: wrap(x), half: half * size });
  }

  // A deer run: quiet, until the bell rings and a whole herd comes bounding through.
  function buildDeerRun(row) {
    const post = makeBellPost();
    post.position.set(-(COLUMNS + 1.3) * TILE, 0, 0.3);
    row.group.add(post);
    const herd = { deer: [], state: 'wait', timer: between(1.5, HERD.wait[1]), lead: 0, post };
    for (let i = 0, count = whole(...HERD.size); i < count; i++) {
      const critter = getCritter('deer');
      critter.model.rotation.y = (row.dir * Math.PI) / 2;
      critter.model.scale.setScalar(between(0.95, 1.08));
      critter.model.visible = false;
      row.group.add(critter.model);
      herd.deer.push(critter);
    }
    row.herd = herd;
    row.speed = row.dir * HERD.speed;
  }

  // --- Clearing rows away ---

  function clearRow(row) {
    scene.remove(row.group);
    for (const ticket of row.trees) trees.uproot(ticket);
    for (const lantern of row.lanterns) {
      row.group.remove(lantern);
      lanterns.push(lantern);
    }
    // (A deer run's animals are its herd, put away just below.)
    for (const { critter, kind } of row.herd ? [] : row.animals) {
      row.group.remove(critter.model);
      critters[kind].push(critter);
    }
    for (const critter of row.herd?.deer ?? []) {
      row.group.remove(critter.model);
      critters.deer.push(critter);
    }
    for (const geometry of row.extras) geometry.dispose();
    rows.delete(row.index);
  }

  // --- Every frame ---

  function updateRow(row, dt) {
    if (row.berry) {
      const { mesh } = row.berry;
      mesh.rotation.y += 1.5 * dt;
      mesh.position.y = mesh.userData.height + Math.sin(time * 2.5 + mesh.userData.bob) * 0.08;
    }
    for (const floater of row.floaters) {
      // Logs drift; everything bobs gently; a lily pad dips when you land on it.
      if (floater.kind === 'log') floater.x = wrap(floater.x + row.speed * dt);
      floater.dip = Math.max((floater.dip ?? 0) - dt * 3, 0);
      floater.mesh.position.x = floater.x;
      const bob = Math.sin(time * 1.8 + floater.bob) * 0.025 - floater.dip * 0.08;
      floater.lift = bob; // So whoever's standing on it bobs too.
      floater.mesh.position.y = (floater.kind === 'log' ? WATER_LEVEL - LOG_THICKNESS * 0.4 : WATER_LEVEL + 0.02) + bob;
    }
    if (row.herd) {
      updateDeerRun(row, dt);
      return;
    }
    for (const animal of row.animals) {
      animal.x = wrap(animal.x + row.speed * dt);
      animal.critter.model.position.x = animal.x;
      animal.critter.animate(dt, Math.abs(row.speed));
    }
  }

  function updateDeerRun(row, dt) {
    const herd = row.herd;
    const bell = herd.post.userData.bell;
    herd.timer -= dt;
    if (herd.state === 'wait' && herd.timer <= 0) {
      herd.state = 'warn';
      herd.timer = HERD.warn;
      if (Math.abs(row.index - nearRow) < 9) playBell();
    } else if (herd.state === 'warn') {
      bell.rotation.z = Math.sin(time * 22) * 0.45 * Math.min(herd.timer, 1);
      if (herd.timer <= 0) {
        herd.state = 'run';
        herd.lead = -row.dir * (LOOP / 2);
        bell.rotation.z = 0;
        for (const critter of herd.deer) critter.model.visible = true;
      }
    } else if (herd.state === 'run') {
      herd.lead += row.speed * dt;
      row.animals = herd.deer.map((critter, i) => ({ critter, kind: 'deer', x: herd.lead - row.dir * i * HERD.spacing, half: 1 }));
      for (const animal of row.animals) {
        animal.critter.model.position.x = animal.x;
        animal.critter.animate(dt, HERD.speed);
      }
      const last = row.animals[row.animals.length - 1];
      if (last.x * row.dir > LOOP / 2) {
        herd.state = 'wait';
        herd.timer = between(...HERD.wait);
        row.animals = [];
        for (const critter of herd.deer) critter.model.visible = false;
      }
    }
  }

  // Make rows ready from a little behind `focus` (the gnome's farthest row) to well ahead of it,
  // and clear away the ones left far behind. Move everything along.
  function update(dt, focus, gnomeRow) {
    if (rows.size === 0) return;
    time += dt;
    nearRow = gnomeRow;
    for (const [index, row] of rows) if (index < focus - ROWS_BEHIND) clearRow(row);
    const last = Math.max(...rows.keys());
    for (let index = last + 1; index <= focus + ROWS_AHEAD; index++) makeRow(index);
    for (const row of rows.values()) updateRow(row, dt);
    for (const dir of [-1, 1]) flows[dir].map.offset.x -= dir * (FLOW_SPEED / 4) * dt;
    if (bestFlag.parent) bestFlag.userData.pennant.rotation.y = Math.sin(time * 2.2) * 0.25;
  }

  // A new trail from scratch, for a new round. `best` is the farthest anyone has hopped, for the flag.
  function reset(best = 0) {
    for (const row of [...rows.values()]) clearRow(row);
    bestFlag.removeFromParent();
    bestRow = best;
    plan = null;
    for (let index = BACK_ROW - ROWS_BEHIND + 1; index <= ROWS_AHEAD; index++) makeRow(index);
  }

  // --- Questions the game asks ---

  const row = (index) => rows.get(index);

  // Is there something in the way on this tile (or is it off the trail)?
  function isBlocked(index, col) {
    return Math.abs(col) > COLUMNS || index < BACK_ROW || (rows.get(index)?.blocked.has(col) ?? true);
  }

  // The log or lily pad that will be under `x` in this row after `ahead` seconds, and where it
  // will be then, or null if there'll only be water. `margin` is how near its end still counts.
  function floaterAt(index, x, ahead = 0, margin = 0.35) {
    const lane = rows.get(index);
    if (!lane) return null;
    let found = null;
    for (const floater of lane.floaters) {
      const at = floater.kind === 'log' ? wrap(floater.x + lane.speed * ahead) : floater.x;
      const off = Math.abs(at - x) - floater.half;
      if (off < margin && (!found || off < found.off)) found = { floater, at, off };
    }
    return found;
  }

  // Where to land on a log (or lily pad) at `at`: on whichever of its tile-sized spots is nearest `x`.
  function landingSpot(floater, at, x) {
    const end = ((floater.slots - 1) / 2) * TILE;
    return at + THREE.MathUtils.clamp(Math.round((x - at + end) / TILE) * TILE - end, -end, end);
  }

  // The animal (if any) touching a gnome at x in this row: anything within `radius` of it.
  function animalAt(index, x, radius) {
    const lane = rows.get(index);
    return lane?.animals.find((animal) => animal.critter.model.visible && Math.abs(animal.x - x) < animal.half + radius) ?? null;
  }

  // Pick the raspberry on this tile, if there is one: it's handed over, ready to pop.
  function takeBerry(index, col) {
    const lane = rows.get(index);
    if (!lane?.berry || lane.berry.col !== col) return null;
    const { mesh } = lane.berry;
    lane.berry = null;
    return mesh;
  }

  // A good spot for the golden raspberry somewhere between two rows: an open meadow tile.
  function goldenSpot(from, to) {
    const spots = [];
    for (let index = from; index <= to; index++) {
      const lane = rows.get(index);
      if (lane?.kind !== 'meadow' || index < START_ROWS) continue;
      for (const col of columns) if (!lane.blocked.has(col) && lane.berry?.col !== col && Math.abs(col) < COLUMNS) spots.push({ index, col });
    }
    return spots.length ? pick(spots) : null;
  }

  // The first and last rows of the creek this row is part of (for the fox, leaping across).
  function creekAround(index) {
    if (rows.get(index)?.kind !== 'creek') return null;
    let first = index;
    let last = index;
    while (rows.get(first - 1)?.kind === 'creek') first--;
    while (rows.get(last + 1)?.kind === 'creek') last++;
    return [first, last];
  }

  return { reset, update, row, isBlocked, floaterAt, landingSpot, animalAt, takeBerry, goldenSpot, creekAround };
}
