import * as THREE from 'three';

// Little bursts of fun when a raspberry is picked. The berry squashes, then pops into a spray of
// juicy bits and leaves with a soft ring, and its number floats up, wafting side to side like a
// falling leaf in reverse, and fades away: 1, 2, 3... up to 10 for the golden raspberry.
// Gnome Crossing adds a few more: a splash in the creek, a puff of dust when the gnome is bowled
// over, and a burst of golden sparkles when the golden glow saves it.

const SQUASH_TIME = 0.16; // How long a berry squashes and swells before it pops.
const BIT_COUNT = 14; // Juicy bits in a pop (the golden raspberry throws twice as many, and sparkles).
const BIT_LIFE = [0.45, 0.8]; // Seconds each bit flies before it's gone.
const BIT_GRAVITY = 14;
const RING_TIME = 0.35;
const NUMBER_LIFE = 1.6; // Seconds a number floats before it's gone (the golden 10 lingers longer).
const NUMBER_RISE = 1.7; // How far it floats up.
const NUMBER_SIZE = 1.3; // How tall it is, in the world.
const NUMBER_WAFT = 0.14; // How far it sways from side to side.

const bitGeometry = new THREE.SphereGeometry(0.075, 8, 6);
const leafGeometry = new THREE.ConeGeometry(0.07, 0.22, 4).scale(0.4, 1, 1);
const berryBits = [0xd8285c, 0xe8487a, 0xb81e4c].map((color) => new THREE.MeshStandardMaterial({ color, emissive: 0x420016, roughness: 0.4 }));
const goldBits = [0xffc93c, 0xffe07a, 0xf2a922].map(
  (color) => new THREE.MeshStandardMaterial({ color, emissive: 0x7a5200, metalness: 0.5, roughness: 0.3 }),
);
const leafMaterial = new THREE.MeshStandardMaterial({ color: 0x4e9a3a, roughness: 0.7, flatShading: true });
const dropMaterials = [0xd6f0ff, 0x8fcdf5, 0xffffff].map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.2 }));
const ripple = new THREE.RingGeometry(0.82, 1, 40).rotateX(-Math.PI / 2);
const puffGeometry = new THREE.IcosahedronGeometry(0.3, 1);
const ringTextures = { berry: makeRing('255, 214, 228'), golden: makeRing('255, 236, 160') };
const sparkleTexture = makeSparkle();
const numberTextures = new Map();

export function createEffects(scene, camera) {
  const effects = []; // Each one: { update(dt) → false once it's done, finish() }.
  const right = new THREE.Vector3();

  // Pop a picked berry. `number` is how many have been picked, counting this one; `floor` is the
  // height of the ground under it; `onGone` runs once the berry has popped (to remove or hide it).
  function popBerry(berry, { number, golden = false, floor = 0, onGone }) {
    const startScale = berry.scale.clone();
    let time = 0;
    let burst = false;
    effects.push({
      update(dt) {
        time += dt;
        const t = Math.min(time / SQUASH_TIME, 1);
        // First half: squash down and spread out. Then pop! and shrink away to nothing, stretching up.
        const wide = t < 0.5 ? 1 + 0.5 * t : 1.25 * Math.sqrt(2 - 2 * t);
        const tall = t < 0.5 ? 1 - 0.5 * t : wide * 1.15;
        berry.scale.set(startScale.x * wide, startScale.y * tall, startScale.z * wide);
        if (t >= 0.5 && !burst) {
          burst = true;
          spray(berry.position.clone(), golden, floor);
        }
        return t < 1;
      },
      finish() {
        berry.scale.copy(startScale);
        onGone();
      },
    });
    floatNumber(berry.position.clone(), number, golden);
  }

  // A spray of juicy bits (and a few leaves) flying out, a soft ring, and for the golden one, sparkles.
  function spray(center, golden, floor) {
    const palette = golden ? goldBits : berryBits;
    const count = golden ? BIT_COUNT * 2 : BIT_COUNT;
    for (let i = 0; i < count + (golden ? 0 : 3); i++) {
      const leaf = i >= count;
      const bit = new THREE.Mesh(leaf ? leafGeometry : bitGeometry, leaf ? leafMaterial : palette[i % palette.length]);
      const angle = Math.random() * Math.PI * 2;
      const outward = THREE.MathUtils.randFloat(1.8, 3.6) * (golden ? 1.3 : 1);
      const velocity = new THREE.Vector3(Math.cos(angle) * outward, THREE.MathUtils.randFloat(1.5, 4.2), Math.sin(angle) * outward);
      const spin = new THREE.Vector3().randomDirection().multiplyScalar(leaf ? 12 : 0);
      const size = THREE.MathUtils.randFloat(0.7, 1.3);
      const life = THREE.MathUtils.randFloat(...BIT_LIFE) * (leaf ? 1.3 : 1);
      let time = 0;
      bit.position.copy(center);
      bit.scale.setScalar(size);
      scene.add(bit);
      effects.push({
        update(dt) {
          time += dt;
          velocity.y -= BIT_GRAVITY * dt * (leaf ? 0.45 : 1); // Leaves flutter down slower.
          bit.position.addScaledVector(velocity, dt);
          if (bit.position.y < floor + 0.04) {
            // Splat on the ground and stay there while it shrinks away.
            bit.position.y = floor + 0.04;
            velocity.set(0, 0, 0);
          }
          bit.rotation.x += spin.x * dt;
          bit.rotation.y += spin.y * dt;
          bit.rotation.z += spin.z * dt;
          bit.scale.setScalar(size * Math.max(1 - (time / life) ** 2, 0));
          return time < life;
        },
        finish: () => scene.remove(bit),
      });
    }

    const ring = new THREE.Sprite(
      new THREE.SpriteMaterial({ map: golden ? ringTextures.golden : ringTextures.berry, transparent: true, depthWrite: false, fog: false }),
    );
    ring.position.copy(center);
    scene.add(ring);
    let ringTime = 0;
    const ringSize = golden ? 4 : 2;
    effects.push({
      update(dt) {
        ringTime += dt;
        const t = Math.min(ringTime / RING_TIME, 1);
        ring.scale.setScalar(0.3 + ringSize * (1 - (1 - t) ** 2));
        ring.material.opacity = 0.9 * (1 - t);
        return t < 1;
      },
      finish: () => {
        scene.remove(ring);
        ring.material.dispose();
      },
    });

    if (golden) {
      for (let i = 0; i < 14; i++) {
        const sparkle = new THREE.Sprite(
          new THREE.SpriteMaterial({ map: sparkleTexture, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, fog: false }),
        );
        const drift = new THREE.Vector3().randomDirection().multiplyScalar(THREE.MathUtils.randFloat(0.6, 1.6));
        drift.y = Math.abs(drift.y) + 0.4;
        const life = THREE.MathUtils.randFloat(0.9, 1.6);
        const twinkle = Math.random() * Math.PI * 2;
        let time = 0;
        sparkle.position.copy(center);
        scene.add(sparkle);
        effects.push({
          update(dt) {
            time += dt;
            sparkle.position.addScaledVector(drift, dt);
            sparkle.material.rotation += dt * 2;
            sparkle.scale.setScalar(0.45 * (0.6 + 0.4 * Math.sin(time * 14 + twinkle)));
            sparkle.material.opacity = 1 - time / life;
            return time < life;
          },
          finish: () => {
            scene.remove(sparkle);
            sparkle.material.dispose();
          },
        });
      }
    }
  }

  // The berry's number floats up from where it was picked, wafting side to side, and fades away.
  function floatNumber(start, number, golden) {
    const map = numberTexture(number, golden);
    const label = new THREE.Sprite(new THREE.SpriteMaterial({ map, transparent: true, depthTest: false, depthWrite: false, fog: false }));
    label.renderOrder = 10; // Drawn last, so trees never hide it.
    const aspect = map.image.width / map.image.height;
    const size = NUMBER_SIZE * (golden ? 1.5 : 1);
    const life = NUMBER_LIFE * (golden ? 1.5 : 1);
    start.y += 0.55;
    scene.add(label);
    let time = 0;
    effects.push({
      update(dt) {
        time += dt;
        const t = Math.min(time / life, 1);
        // Pop in with a little overshoot, rise quickly then slow down, and fade over the second half.
        const popIn = time < 0.18 ? easeOutBack(time / 0.18) : 1;
        const sway = Math.sin(time * 4.2) * NUMBER_WAFT * (0.5 + t);
        right.setFromMatrixColumn(camera.matrixWorld, 0);
        label.position.copy(start).addScaledVector(right, sway);
        label.position.y += NUMBER_RISE * (1 - (1 - t) ** 3);
        label.scale.set(size * aspect * popIn, size * popIn, 1);
        label.material.rotation = Math.sin(time * 4.2 + 0.7) * 0.12;
        label.material.opacity = t < 0.5 ? 1 : 1 - ((t - 0.5) / 0.5) ** 1.5;
        return t < 1;
      },
      finish: () => {
        scene.remove(label);
        label.material.dispose();
      },
    });
  }

  // A splash where the gnome falls in the creek: drops of water thrown up and falling back,
  // and two rings spreading across the water.
  function splash(center, waterLevel) {
    for (let i = 0; i < 26; i++) {
      const drop = new THREE.Mesh(bitGeometry, dropMaterials[i % dropMaterials.length]);
      const angle = Math.random() * Math.PI * 2;
      const outward = THREE.MathUtils.randFloat(0.6, 2.4);
      const velocity = new THREE.Vector3(Math.cos(angle) * outward, THREE.MathUtils.randFloat(3, 6.5), Math.sin(angle) * outward);
      const size = THREE.MathUtils.randFloat(0.6, 1.4);
      drop.position.set(center.x, waterLevel + 0.05, center.z);
      drop.scale.setScalar(size);
      scene.add(drop);
      effects.push({
        update(dt) {
          velocity.y -= BIT_GRAVITY * dt;
          drop.position.addScaledVector(velocity, dt);
          return drop.position.y > waterLevel;
        },
        finish: () => scene.remove(drop),
      });
    }
    for (const [delay, reach] of [[0, 2.2], [0.18, 1.5]]) {
      const ring = new THREE.Mesh(ripple, new THREE.MeshBasicMaterial({ color: 0xeaf7ff, transparent: true, depthWrite: false }));
      ring.position.set(center.x, waterLevel + 0.02, center.z);
      ring.visible = false;
      scene.add(ring);
      let time = -delay;
      effects.push({
        update(dt) {
          time += dt;
          const t = Math.min(Math.max(time / 0.7, 0), 1);
          ring.visible = time > 0;
          ring.scale.setScalar(0.2 + reach * (1 - (1 - t) ** 2));
          ring.material.opacity = 0.85 * (1 - t);
          return t < 1;
        },
        finish: () => {
          scene.remove(ring);
          ring.material.dispose();
        },
      });
    }
  }

  // A puff of dust where the gnome tumbles over: soft little clouds that swell and fade.
  function dust(center) {
    for (let i = 0; i < 7; i++) {
      const puff = new THREE.Mesh(puffGeometry, new THREE.MeshStandardMaterial({ color: 0xd9c9a3, roughness: 1, transparent: true, depthWrite: false }));
      const angle = (i / 7) * Math.PI * 2 + Math.random() * 0.5;
      const drift = new THREE.Vector3(Math.cos(angle) * 1.1, THREE.MathUtils.randFloat(0.3, 0.9), Math.sin(angle) * 1.1);
      const life = THREE.MathUtils.randFloat(0.5, 0.8);
      let time = 0;
      puff.position.copy(center);
      scene.add(puff);
      effects.push({
        update(dt) {
          time += dt;
          const t = Math.min(time / life, 1);
          puff.position.addScaledVector(drift, dt * (1 - t));
          puff.scale.setScalar(0.6 + 1.4 * Math.sqrt(t));
          puff.material.opacity = 0.75 * (1 - t);
          return t < 1;
        },
        finish: () => {
          scene.remove(puff);
          puff.material.dispose();
        },
      });
    }
  }

  // A burst of golden bits, a ring and sparkles, the same as the golden raspberry's pop.
  function goldenBurst(center, floor = 0) {
    spray(center.clone(), true, floor);
  }

  function update(dt) {
    for (let i = effects.length - 1; i >= 0; i--) {
      if (!effects[i].update(dt)) {
        effects[i].finish();
        effects.splice(i, 1);
      }
    }
  }

  // Stop everything at once (for a new round).
  function clear() {
    for (const effect of effects) effect.finish();
    effects.length = 0;
  }

  return { popBerry, splash, dust, goldenBurst, update, clear };
}

function easeOutBack(x) {
  const c1 = 1.70158;
  return 1 + (c1 + 1) * (x - 1) ** 3 + c1 * (x - 1) ** 2;
}

// A number painted like the storybook's lettering: raspberry red (or gold) with a cream edge,
// a brown ink outline and a soft shadow, and a little green leaf on top like a berry's cap.
function numberTexture(number, golden) {
  const name = `${number}-${golden}`;
  if (numberTextures.has(name)) return numberTextures.get(name);
  const text = String(number);
  const height = 192;
  const width = text.length > 1 ? 288 : 192;
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  const middleX = width / 2;
  const middleY = height / 2 + 12;
  ctx.font = `bold 128px Palatino, 'Palatino Linotype', 'Book Antiqua', Georgia, serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.lineJoin = 'round';

  ctx.shadowColor = 'rgba(50, 25, 10, 0.45)';
  ctx.shadowBlur = 10;
  ctx.shadowOffsetY = 5;
  ctx.lineWidth = 22;
  ctx.strokeStyle = '#5a2e1a';
  ctx.strokeText(text, middleX, middleY);
  ctx.shadowColor = 'transparent';
  ctx.lineWidth = 12;
  ctx.strokeStyle = '#fff6e0';
  ctx.strokeText(text, middleX, middleY);
  const paint = ctx.createLinearGradient(0, middleY - 50, 0, middleY + 50);
  paint.addColorStop(0, golden ? '#fff4b8' : '#ff7aa0');
  paint.addColorStop(1, golden ? '#eea51f' : '#c42858');
  ctx.fillStyle = paint;
  ctx.fillText(text, middleX, middleY);

  // The leafy cap, tucked on the top right of the number.
  const leafX = middleX + ctx.measureText(text).width / 2 - 6;
  const leafY = middleY - 52;
  for (const [tilt, length] of [[-0.6, 20], [0.35, 17]]) {
    ctx.save();
    ctx.translate(leafX, leafY);
    ctx.rotate(tilt);
    ctx.fillStyle = '#4e9a3a';
    ctx.strokeStyle = '#2f5e22';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.ellipse(length * 0.6, 0, length, length * 0.42, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }

  if (golden) {
    // Twinkles around the golden 10.
    for (const [x, y, r] of [[0.1, 0.25, 14], [0.9, 0.78, 12], [0.12, 0.85, 9], [0.86, 0.12, 8]]) drawSparkle(ctx, x * width, y * height, r);
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  numberTextures.set(name, texture);
  return texture;
}

// A soft ring of light, for the moment a berry pops.
function makeRing(rgb) {
  const size = 128;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  const ring = ctx.createRadialGradient(size / 2, size / 2, size * 0.28, size / 2, size / 2, size / 2);
  ring.addColorStop(0, `rgba(${rgb}, 0)`);
  ring.addColorStop(0.55, `rgba(${rgb}, 0.85)`);
  ring.addColorStop(1, `rgba(${rgb}, 0)`);
  ctx.fillStyle = ring;
  ctx.fillRect(0, 0, size, size);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

function makeSparkle() {
  const size = 64;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  drawSparkle(canvas.getContext('2d'), size / 2, size / 2, size / 2);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

// A four-pointed star with a soft glow.
function drawSparkle(ctx, x, y, r) {
  const glow = ctx.createRadialGradient(x, y, 0, x, y, r);
  glow.addColorStop(0, 'rgba(255, 250, 220, 0.9)');
  glow.addColorStop(1, 'rgba(255, 220, 120, 0)');
  ctx.fillStyle = glow;
  ctx.beginPath();
  for (let i = 0; i < 8; i++) {
    const angle = (i / 8) * Math.PI * 2;
    const reach = i % 2 === 0 ? r : r * 0.22;
    ctx.lineTo(x + Math.cos(angle) * reach, y + Math.sin(angle) * reach);
  }
  ctx.closePath();
  ctx.fill();
}
