// Everything the player can press: the keyboard, and a game controller such as a PlayStation 5
// controller. Once a frame, readInput() boils it all down to which way to move (and how hard),
// whether jump is held, and which buttons were just pressed: swing the stick, restart, pause, and
// the buttons for getting around the menu. The rest of the game only asks this file, so it doesn't
// care where the input came from. (The menu also listens to the keyboard itself, for Esc, Enter and the arrows.)

const STICK_DEAD_ZONE = 0.15; // Ignore small stick movements; sticks rarely rest exactly in the middle.
const MENU_STICK_PUSH = 0.5; // How far to push the stick to move through a menu.
const MENU_REPEAT_DELAY = 0.4; // Hold a direction in a menu: it moves once, then again after this many seconds...
const MENU_REPEAT_EVERY = 0.12; // ...and then this often.

// Button numbers on a controller with the browser's "standard" layout (PlayStation and Xbox
// controllers both use it). On a PlayStation controller, button 0 is ✕ and button 1 is ○.
const CROSS = 0;
const CIRCLE = 1;
const SQUARE = 2;
const OPTIONS = 9;
const DPAD_UP = 12;
const DPAD_DOWN = 13;
const DPAD_LEFT = 14;
const DPAD_RIGHT = 15;

const keys = new Set();
let restartKeyPressed = false;
let swingKeyPressed = false;
const wasDown = []; // Which controller buttons were down last frame, to spot new presses.
let lastPad = null; // Which controller that was.
let jumpHeldOver = false; // After leaving the menu with ✕, ignore that press until it's let go.
let menuStep = { x: 0, y: 0, next: 0 }; // The direction held in a menu, and when it repeats.
let controllerLast = false; // Was the controller (not the keyboard or mouse) used last? For showing the right button names.

window.addEventListener('pointerdown', () => (controllerLast = false));
window.addEventListener('keydown', (event) => {
  controllerLast = false;
  // Typing a name for the Top 10, or using a menu button or slider, shouldn't move the gnome.
  if (event.target instanceof Element && event.target.closest('input, button, select, textarea')) return;
  if (event.code === 'Space' || event.code.startsWith('Arrow')) event.preventDefault();
  keys.add(event.code);
  if (event.code === 'KeyR' && !event.repeat) restartKeyPressed = true;
  if (event.code === 'KeyF' && !event.repeat) swingKeyPressed = true;
});
window.addEventListener('keyup', (event) => keys.delete(event.code));
window.addEventListener('blur', () => keys.clear());

const input = {
  moveX: 0, // -1 (left) to 1 (right)
  moveZ: 0, // -1 (forward, up the screen) to 1 (back, toward the camera)
  jump: false, // Held down this frame.
  swing: false, // Swing the stick: pressed this frame (not just held).
  restart: false, // Pressed this frame (not just held).
  pause: false, // Options pressed this frame. (Esc and P are handled by the menu.)
  confirm: false, // ✕ pressed this frame, to pick something in a menu.
  back: false, // ○ pressed this frame, to go back in a menu.
  menuX: 0, // A step left (-1) or right (1) in a menu this frame, from the D-pad or left stick.
  menuY: 0, // A step up (-1) or down (1).
  lookX: 0, // Turn the camera: -1 (left) to 1 (right), from Q and E or the right stick.
};

export function readInput() {
  const pad = controller();
  const key = (...codes) => codes.some((code) => keys.has(code));
  const button = (index) => pad?.buttons[index]?.pressed ?? false;
  // The first time a controller shows up, whatever it reports as held doesn't count as a new press.
  const padName = pad ? `${pad.index} ${pad.id}` : null;
  if (padName !== lastPad) {
    lastPad = padName;
    for (let i = 0; i < (pad?.buttons.length ?? 0); i++) wasDown[i] = button(i);
  }
  const pressed = (index) => button(index) && !wasDown[index];
  if (!pad) controllerLast = false;
  else if (pad.buttons.some((b) => b.pressed) || Math.hypot(pad.axes[0] ?? 0, pad.axes[1] ?? 0) > 0.5) controllerLast = true;

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

  const jumpDown = key('Space') || button(CROSS);
  if (!jumpDown) jumpHeldOver = false;
  input.moveX = x;
  input.moveZ = z;
  const stickLook = pad?.axes[2] ?? 0;
  input.lookX = (key('KeyE') ? 1 : 0) - (key('KeyQ') ? 1 : 0) || (Math.abs(stickLook) > STICK_DEAD_ZONE ? stickLook : 0);
  input.jump = jumpDown && !jumpHeldOver;
  input.swing = swingKeyPressed || pressed(SQUARE);
  input.restart = restartKeyPressed;
  input.pause = pressed(OPTIONS);
  input.confirm = pressed(CROSS);
  input.back = pressed(CIRCLE);
  readMenuSteps(pad, button);
  restartKeyPressed = false;
  swingKeyPressed = false;
  for (let i = 0; i < (pad?.buttons.length ?? 0); i++) wasDown[i] = button(i);
  return input;
}

// Menu steps from the controller: one step when a direction is first pushed, then repeating while it's held.
function readMenuSteps(pad, button) {
  let x = (button(DPAD_RIGHT) ? 1 : 0) - (button(DPAD_LEFT) ? 1 : 0);
  let y = (button(DPAD_DOWN) ? 1 : 0) - (button(DPAD_UP) ? 1 : 0);
  if (x === 0 && y === 0 && pad) {
    const stickX = pad.axes[0] ?? 0;
    const stickY = pad.axes[1] ?? 0;
    if (Math.max(Math.abs(stickX), Math.abs(stickY)) > MENU_STICK_PUSH) {
      if (Math.abs(stickX) > Math.abs(stickY)) x = Math.sign(stickX);
      else y = Math.sign(stickY);
    }
  }
  if (y !== 0) x = 0; // One direction at a time.
  const now = performance.now() / 1000;
  const same = x === menuStep.x && y === menuStep.y;
  let step = false;
  if (!same) {
    step = x !== 0 || y !== 0;
    menuStep = { x, y, next: now + MENU_REPEAT_DELAY };
  } else if ((x !== 0 || y !== 0) && now >= menuStep.next) {
    step = true;
    menuStep.next = now + MENU_REPEAT_EVERY;
  }
  input.menuX = step ? x : 0;
  input.menuY = step ? y : 0;
}

// Call when play starts again after a menu, so the ✕ (or Space) that closed it doesn't also jump.
export function ignoreHeldJump() {
  jumpHeldOver = true;
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

// Was the controller used more recently than the keyboard or mouse? Prompts show its buttons if so.
export function isUsingController() {
  return controllerLast;
}
