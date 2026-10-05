import * as THREE from 'three';

// Lanternwood's lanterns: a round paper lantern hanging from a little wooden post, glowing warm
// like the strings of lanterns in Tivoli Gardens at dusk. They stand at the ends of the bridges and
// peek out of the glades in the woods, flickering gently, as if each one marks somewhere to explore.

export const LANTERN_HEIGHT = 1.75; // How tall the post is.

const ARM = 0.4; // How far the lantern hangs out from the post.
const postMaterial = new THREE.MeshStandardMaterial({ color: 0x5b4030, roughness: 0.9 });
const capMaterial = new THREE.MeshStandardMaterial({ color: 0x3a2a1e, roughness: 0.7 });
const paperMaterial = new THREE.MeshStandardMaterial({ color: 0xffc46b, emissive: 0xff9437, emissiveIntensity: 1.15, roughness: 0.6 });
const postGeometry = new THREE.CylinderGeometry(0.045, 0.065, LANTERN_HEIGHT, 7).translate(0, LANTERN_HEIGHT / 2, 0);
const armGeometry = new THREE.CylinderGeometry(0.03, 0.03, ARM + 0.05, 6).rotateZ(Math.PI / 2).translate(ARM / 2, LANTERN_HEIGHT - 0.06, 0);
const cordGeometry = new THREE.CylinderGeometry(0.008, 0.008, 0.12, 4).translate(ARM, LANTERN_HEIGHT - 0.14, 0);
const paperGeometry = new THREE.SphereGeometry(0.17, 14, 10).scale(1, 1.2, 1);
const capGeometry = new THREE.CylinderGeometry(0.07, 0.09, 0.05, 10);
const glowTexture = makeGlow();
const glows = []; // Every lantern's glow, so they can all flicker.

// A lantern on its post, standing at 0, 0, 0 with the lantern hanging out along +x.
export function makeLantern() {
  const lantern = new THREE.Group();
  const post = new THREE.Mesh(postGeometry, postMaterial);
  const arm = new THREE.Mesh(armGeometry, postMaterial);
  const cord = new THREE.Mesh(cordGeometry, capMaterial);
  const lamp = makeHangingLantern();
  lamp.position.set(ARM, LANTERN_HEIGHT - 0.2, 0);
  post.castShadow = true;
  arm.castShadow = true;
  lantern.add(post, arm, cord, lamp);
  return lantern;
}

// Just the paper lantern, to hang from something (an arch, a branch). It hangs down from 0, 0, 0.
export function makeHangingLantern() {
  const lamp = new THREE.Group();
  const paper = new THREE.Mesh(paperGeometry, paperMaterial);
  const top = new THREE.Mesh(capGeometry, capMaterial);
  const bottom = new THREE.Mesh(capGeometry, capMaterial);
  paper.position.y = -0.22;
  top.position.y = -0.01;
  bottom.position.y = -0.43;
  bottom.rotation.x = Math.PI; // Wider at the paper, both ends.
  paper.castShadow = true;

  // A soft halo of light around the paper, always facing the camera.
  const glow = new THREE.Sprite(
    new THREE.SpriteMaterial({ map: glowTexture, color: 0xffb35c, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
  );
  glow.position.copy(paper.position);
  glow.scale.setScalar(1.3);
  glow.userData.phase = Math.random() * 100;
  glows.push(glow);

  lamp.add(paper, top, bottom, glow);
  return lamp;
}

// Make every lantern's glow flicker a little, like a candle. `time` is in seconds.
export function flickerLanterns(time) {
  for (const glow of glows) {
    const phase = glow.userData.phase;
    const flicker = 0.85 + 0.1 * Math.sin(time * 7.3 + phase) + 0.05 * Math.sin(time * 13.7 + phase * 2);
    glow.material.opacity = flicker;
    glow.scale.setScalar(1.3 * (0.94 + 0.06 * flicker));
  }
}

// A warm round glow, painted on a small canvas.
function makeGlow() {
  const size = 128;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  const glow = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  glow.addColorStop(0, 'rgba(255, 236, 190, 0.85)');
  glow.addColorStop(0.3, 'rgba(255, 190, 110, 0.35)');
  glow.addColorStop(1, 'rgba(255, 160, 80, 0)');
  ctx.fillStyle = glow;
  ctx.fillRect(0, 0, size, size);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}
