import * as THREE from 'three';

// The creek: a blue stream that winds diagonally across the field from the north-east to the
// south-west, with sloped brownish-grey banks and two arched wooden bridges over it.
// This file also builds the ground, since the creek is carved into it.

// Tweak these to change the creek.
const CREEK_OFFSET = -5.5; // How far the creek's middle line sits north-west of the center of the field.
const WIGGLE = 2.5; // How far it bends from side to side.
const WIGGLE_LENGTH = 26; // How far along the creek one full bend takes.
const BED_HALF_WIDTH = 1.1; // Half the width of the flat creek bed.
const BANK_WIDTH = 1.5; // How wide each sloping bank is.
const DEPTH = 0.6; // How far the creek bed sits below the grass.
const FLOW_SPEED = 0.06; // How fast the ripples drift downstream.
export const WATER_LEVEL = -0.28;
export const CREEK_HALF_WIDTH = BED_HALF_WIDTH + BANK_WIDTH; // From the middle of the creek to the top of a bank.

// Bridges sit this far along the creek, measured from the middle of the field (negative is north).
const BRIDGE_SPOTS = [-9, 13];
const BRIDGE_LENGTH = CREEK_HALF_WIDTH * 2 + 1.6;
const BRIDGE_WIDTH = 1.9;
const BRIDGE_RISE = 0.8; // How high the middle of a bridge arches above the grass.
const RAIL_HEIGHT = 0.55;

const TERRAIN_SIZE = 90; // The ground reaches past the hedges, out to the painted hills.
const TERRAIN_SEGMENTS = 270;
const GRASS = new THREE.Color(0x55aa55);
const BANK = new THREE.Color(0x8c7f6d);
const BED = new THREE.Color(0x6d6457);

const bendRate = (2 * Math.PI) / WIGGLE_LENGTH;

// --- Where the creek is ---

// The creek follows the field's north-east to south-west diagonal. `along` measures distance
// down that diagonal (growing toward the south-west), and this gives how far sideways the
// creek's middle sits there (growing toward the south-east).
function middleAt(along) {
  return CREEK_OFFSET + WIGGLE * Math.sin(bendRate * along);
}

// How far a spot is from the middle of the creek.
export function creekDistance(x, z) {
  const along = (z - x) / Math.SQRT2;
  const across = (x + z) / Math.SQRT2;
  const lean = WIGGLE * bendRate * Math.cos(bendRate * along); // How much the creek bends away from the diagonal here.
  return Math.abs(across - middleAt(along)) / Math.sqrt(1 + lean * lean);
}

// Height of the grass or creek bed at a spot, not counting bridges.
function terrainHeight(x, z) {
  const distance = creekDistance(x, z);
  if (distance >= CREEK_HALF_WIDTH) return 0;
  const upTheBank = THREE.MathUtils.smoothstep(distance, BED_HALF_WIDTH, CREEK_HALF_WIDTH); // 0 on the bed, 1 at the top.
  return -DEPTH * (1 - upTheBank);
}

// Height of whatever you'd stand on at a spot: the grass, the creek bed or a bridge.
export function groundHeightAt(x, z) {
  let height = terrainHeight(x, z);
  for (const bridge of bridges) {
    const { along, sideways } = bridge.toLocal(x, z);
    if (Math.abs(along) < BRIDGE_LENGTH / 2 && Math.abs(sideways) < BRIDGE_WIDTH / 2) {
      height = Math.max(height, deckHeight(along));
    }
  }
  return height;
}

export function isInWater(x, z) {
  return groundHeightAt(x, z) < WATER_LEVEL;
}

// Is a spot on a bridge, or within `margin` of one?
export function isNearBridge(x, z, margin) {
  return bridges.some((bridge) => {
    const { along, sideways } = bridge.toLocal(x, z);
    return Math.abs(along) < BRIDGE_LENGTH / 2 + margin && Math.abs(sideways) < BRIDGE_WIDTH / 2 + margin;
  });
}

// --- Ground and water ---

export function makeGround() {
  const geometry = new THREE.PlaneGeometry(TERRAIN_SIZE, TERRAIN_SIZE, TERRAIN_SEGMENTS, TERRAIN_SEGMENTS);
  geometry.rotateX(-Math.PI / 2); // Lay it flat: x and z run along the ground, y is up.
  const positions = geometry.attributes.position;
  const colors = new Float32Array(positions.count * 3);
  const color = new THREE.Color();
  for (let i = 0; i < positions.count; i++) {
    const x = positions.getX(i);
    const z = positions.getZ(i);
    positions.setY(i, terrainHeight(x, z));

    // Grass with soft light and dark patches, like brush strokes, turning to muddy banks near the water.
    const patch = Math.sin(x * 0.31) * Math.sin(z * 0.27) + 0.6 * Math.sin(x * 0.11 - z * 0.15);
    color.copy(GRASS).offsetHSL(0, 0, patch * 0.03);
    const distance = creekDistance(x, z);
    color.lerp(BANK, 1 - THREE.MathUtils.smoothstep(distance, CREEK_HALF_WIDTH - 0.3, CREEK_HALF_WIDTH + 0.25));
    color.lerp(BED, 1 - THREE.MathUtils.smoothstep(distance, BED_HALF_WIDTH, BED_HALF_WIDTH + 0.9));
    color.toArray(colors, i * 3);
  }
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geometry.computeVertexNormals();

  const ground = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1 }));
  ground.receiveShadow = true;
  return ground;
}

// Ripples: pale streaks on blue, painted once on a small tile that repeats across the water.
function makeRipples() {
  const size = 256;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#3d8fd6';
  ctx.fillRect(0, 0, size, size);
  ctx.lineCap = 'round';
  for (let i = 0; i < 30; i++) {
    const x = Math.random() * size;
    const y = Math.random() * size;
    const length = 18 + Math.random() * 46;
    const sway = (Math.random() - 0.5) * 10;
    ctx.lineWidth = 1.5 + Math.random() * 2.5;
    ctx.strokeStyle = `rgba(200, 235, 255, ${0.35 + Math.random() * 0.35})`;
    // Draw each streak nine times, shifted by the tile size, so the tile joins up with no seams.
    for (const dx of [-size, 0, size]) {
      for (const dy of [-size, 0, size]) {
        ctx.beginPath();
        ctx.moveTo(x + dx, y + dy);
        ctx.quadraticCurveTo(x + dx + length / 2, y + dy + sway, x + dx + length, y + dy);
        ctx.stroke();
      }
    }
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
  texture.repeat.set(TERRAIN_SIZE / 5, TERRAIN_SIZE / 5);
  texture.rotation = Math.PI / 4; // Line the streaks up with the creek.
  return texture;
}

const ripples = makeRipples();

export function makeWater() {
  // One big sheet of water just below the grass. The ground hides it everywhere except down in the creek.
  const water = new THREE.Mesh(
    new THREE.PlaneGeometry(TERRAIN_SIZE, TERRAIN_SIZE),
    new THREE.MeshStandardMaterial({ map: ripples, roughness: 0.2, metalness: 0.1, transparent: true, opacity: 0.88 }),
  );
  water.rotation.x = -Math.PI / 2;
  water.position.y = WATER_LEVEL;
  water.receiveShadow = true;
  return water;
}

// Call once a frame to make the water flow.
export function updateCreek(dt) {
  ripples.offset.x -= FLOW_SPEED * dt;
}

// --- Bridges ---

// The height of a bridge's deck, `along` units from its middle: an arch that meets the grass at both ends.
function deckHeight(along) {
  return BRIDGE_RISE * Math.cos((Math.PI * along) / BRIDGE_LENGTH);
}

function deckSlope(along) {
  return -BRIDGE_RISE * (Math.PI / BRIDGE_LENGTH) * Math.sin((Math.PI * along) / BRIDGE_LENGTH);
}

const plankMaterials = [0xa47448, 0x96683f].map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.85 }));
const postMaterial = new THREE.MeshStandardMaterial({ color: 0x6e4a2b, roughness: 0.9 });

// An arched wooden footbridge straight across the creek, `spot` units along it.
function makeBridge(spot) {
  // Find the middle of the creek there, and which way the water flows.
  const middle = middleAt(spot);
  const center = new THREE.Vector3((middle - spot) / Math.SQRT2, 0, (middle + spot) / Math.SQRT2);
  const lean = WIGGLE * bendRate * Math.cos(bendRate * spot);
  const flow = new THREE.Vector3(lean - 1, 0, lean + 1).normalize();
  const span = new THREE.Vector3(flow.z, 0, -flow.x); // Straight across the creek.

  // Build the bridge with its length along z, then turn it to span the creek.
  const model = new THREE.Group();
  model.position.copy(center);
  model.rotation.y = Math.atan2(span.x, span.z);

  // Planks: a row of boards following the arch.
  const plankCount = 14;
  const plankDepth = BRIDGE_LENGTH / plankCount;
  const plankGeometry = new THREE.BoxGeometry(BRIDGE_WIDTH, 0.08, plankDepth - 0.04);
  for (let i = 0; i < plankCount; i++) {
    const along = -BRIDGE_LENGTH / 2 + (i + 0.5) * plankDepth;
    const plank = new THREE.Mesh(plankGeometry, plankMaterials[i % 2]);
    plank.position.set(0, deckHeight(along) - 0.04, along);
    plank.rotation.x = -Math.atan(deckSlope(along));
    plank.castShadow = true;
    plank.receiveShadow = true;
    model.add(plank);
  }

  // Railings: posts along both sides with a curved handrail on top, and stout legs down into the creek.
  const postGeometry = new THREE.CylinderGeometry(0.06, 0.07, 1, 8);
  for (const side of [-1, 1]) {
    const x = side * (BRIDGE_WIDTH / 2 - 0.06);
    const railPoints = [];
    for (let i = 0; i <= 6; i++) {
      const along = -BRIDGE_LENGTH / 2 + 0.15 + (i / 6) * (BRIDGE_LENGTH - 0.3);
      const bottom = deckHeight(along) - 0.1;
      const top = deckHeight(along) + RAIL_HEIGHT;
      const post = new THREE.Mesh(postGeometry, postMaterial);
      post.scale.y = top - bottom;
      post.position.set(x, (top + bottom) / 2, along);
      post.castShadow = true;
      model.add(post);
    }
    for (let i = 0; i <= 16; i++) {
      const along = -BRIDGE_LENGTH / 2 + 0.15 + (i / 16) * (BRIDGE_LENGTH - 0.3);
      railPoints.push(new THREE.Vector3(x, deckHeight(along) + RAIL_HEIGHT, along));
    }
    const rail = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(railPoints), 32, 0.05, 6), postMaterial);
    rail.castShadow = true;
    model.add(rail);

    for (const end of [-1, 1]) {
      const along = end * (BED_HALF_WIDTH + 0.5);
      const top = deckHeight(along) - 0.08;
      const leg = new THREE.Mesh(postGeometry, postMaterial);
      leg.scale.set(1.5, top + DEPTH, 1.5);
      leg.position.set(side * (BRIDGE_WIDTH / 2 - 0.2), (top - DEPTH) / 2, along);
      model.add(leg);
    }
  }

  // Invisible bumpers along both railings, so you can't walk off the sides (but you can jump over).
  const bumpers = [];
  const bumperCount = Math.round(BRIDGE_LENGTH / 0.5);
  for (const side of [-1, 1]) {
    for (let i = 0; i <= bumperCount; i++) {
      const along = -BRIDGE_LENGTH / 2 + (i / bumperCount) * BRIDGE_LENGTH;
      const position = center.clone().addScaledVector(span, along).addScaledVector(flow, side * (BRIDGE_WIDTH / 2 - 0.06));
      bumpers.push({ position, radius: 0.1, height: deckHeight(along) + RAIL_HEIGHT });
    }
  }

  // Turn a spot in the world into distances along the bridge and sideways from its middle line.
  function toLocal(x, z) {
    const dx = x - center.x;
    const dz = z - center.z;
    return { along: dx * span.x + dz * span.z, sideways: dx * flow.x + dz * flow.z };
  }

  return { model, bumpers, toLocal };
}

export const bridges = BRIDGE_SPOTS.map(makeBridge);
