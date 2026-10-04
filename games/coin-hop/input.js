// Everything the player can press: the keyboard, and a game controller such as a PlayStation 5
// controller. Once a frame, readInput() boils it all down to which way to move (and how hard),
// whether jump is held, and whether "play again" was just pressed. The rest of the game only
// asks this file, so it doesn't care where the input came from.

const STICK_DEAD_ZONE = 0.15; // Ignore small stick movements; sticks rarely rest exactly in the middle.

// Button numbers on a controller with the browser's "standard" layout (PlayStation and Xbox
// controllers both use it). On a PlayStation controller, button 0 is ✕.
const CROSS = 0;
const OPTIONS = 9;
const DPAD_UP = 12;
const DPAD_DOWN = 13;
const DPAD_LEFT = 14;
const DPAD_RIGHT = 15;

const keys = new Set();
let restartKeyPressed = false;
let optionsWasDown = false;

window.addEventListener('keydown', (event) => {
  if (event.target instanceof HTMLInputElement) return; // Typing a name for the Top 10 shouldn't move the gnome.
  if (event.code === 'Space' || event.code.startsWith('Arrow')) event.preventDefault();
  keys.add(event.code);
  if (event.code === 'KeyR' && !event.repeat) restartKeyPressed = true;
});
window.addEventListener('keyup', (event) => keys.delete(event.code));
window.addEventListener('blur', () => keys.clear());

const input = {
  moveX: 0, // -1 (left) to 1 (right)
  moveZ: 0, // -1 (forward, up the screen) to 1 (back, toward the camera)
  jump: false, // Held down this frame.
  restart: false, // Pressed this frame (not just held).
};

export function readInput() {
  const pad = controller();
  const key = (...codes) => codes.some((code) => keys.has(code));
  const button = (index) => pad?.buttons[index]?.pressed ?? false;

  // WASD, arrow keys and the D-pad: eight directions, always at full speed.
  let x = 0;
  let z = 0;
  if (key('KeyW', 'ArrowUp') || button(DPAD_UP)) z -= 1;
  if (key('KeyS', 'ArrowDown') || button(DPAD_DOWN)) z += 1;
  if (key('KeyA', 'ArrowLeft') || button(DPAD_LEFT)) x -= 1;
  if (key('KeyD', 'ArrowRight') || button(DPAD_RIGHT)) x += 1;
  if (x !== 0 || z !== 0) {
    const length = Math.hypot(x, z);
    x /= length;
    z /= length;
  } else if (pad) {
    // The left stick: any direction, and push it further to go faster.
    const stickX = pad.axes[0] ?? 0;
    const stickZ = pad.axes[1] ?? 0;
    const push = Math.hypot(stickX, stickZ);
    if (push > STICK_DEAD_ZONE) {
      const strength = Math.min((push - STICK_DEAD_ZONE) / (1 - STICK_DEAD_ZONE), 1);
      x = (stickX / push) * strength;
      z = (stickZ / push) * strength;
    }
  }

  const optionsDown = button(OPTIONS);
  input.moveX = x;
  input.moveZ = z;
  input.jump = key('Space') || button(CROSS);
  input.restart = restartKeyPressed || (optionsDown && !optionsWasDown);
  restartKeyPressed = false;
  optionsWasDown = optionsDown;
  return input;
}

// The first plugged-in controller, if any. Browsers only report a controller after one of its
// buttons has been pressed while the page is open, so press any button once to wake it up.
function controller() {
  for (const pad of navigator.getGamepads?.() ?? []) {
    if (pad?.connected) return pad;
  }
  return null;
}

export function isControllerConnected() {
  return controller() !== null;
}
