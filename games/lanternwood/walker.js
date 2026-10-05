import * as THREE from 'three';

// How the gnome gets around, the same everywhere in Lanternwood: running and turning, jumping and
// landing, bumping into things, and the camera following along behind. Each area (Berry Rush, the
// woods) tells it about its own ground and obstacles.

// Tweak these to change how the gnome moves, everywhere.
export const MOVE_SPEED = 8;
export const GNOME_RADIUS = 0.3; // How close the gnome can get to trees and rocks.
export const GNOME_MIDDLE = 0.45; // Height of the middle of the gnome, where things touch it.
const JUMP_SPEED = 9;
const GRAVITY = 25;
const TURN_SPEED = 12; // How quickly the gnome turns to face the way it's running.
const CAMERA_OFFSET = new THREE.Vector3(0, 6, 10); // Behind and above the gnome.
const CAMERA_LOOK_ABOVE = 2; // Aim the camera this far above the gnome, so the painted sky shows.

// `floorAt()`: how high the ground is under the gnome right now (it can stand on rocks, bridges...).
// `pushOut(position)`: move it back out of anything solid. `keepIn(position, radius)`: keep it inside the area.
// `speedAt(x, z)`: 1 for full speed, less where the going is slow (like the creek).
export function createWalker({ gnome, camera, floorAt, pushOut, keepIn, speedAt = () => 1 }) {
  const player = gnome.model;
  const middle = new THREE.Vector3(); // The middle of the gnome, where raspberries and worms touch it.
  const move = new THREE.Vector3();
  const lookAt = new THREE.Vector3();
  let verticalSpeed = 0;
  let grounded = true;
  let pace = 1; // The speed the ground allows where the gnome last stood.

  // Put the gnome at x, z with the camera right behind. `facing` is the way it looks, as an angle
  // like Math.atan2(x, z): 0 is toward the camera (south), Math.PI is away (north), Math.PI / 2 is east.
  function place(x, z, facing = 0) {
    player.position.set(x, 0, z);
    player.position.y = floorAt();
    player.rotation.set(0, facing, 0);
    verticalSpeed = 0;
    grounded = true;
    pace = speedAt(x, z);
    middle.copy(player.position).y += GNOME_MIDDLE;
    camera.position.copy(middle).add(CAMERA_OFFSET);
    camera.lookAt(lookAt.copy(middle).setY(middle.y + CAMERA_LOOK_ABOVE));
  }

  // Run, jump and fall for one frame. With `canMove` false the gnome stands still (but still lands).
  function update(dt, controls, canMove = true) {
    // Pushing the stick part way walks slower; slow ground (like the creek) is slower too.
    move.set(controls.moveX, 0, controls.moveZ);
    const push = move.length(); // 0 standing still, 1 full speed.
    const running = push > 0 && canMove;
    if (running) {
      move.multiplyScalar(MOVE_SPEED * pace * dt);
      player.position.add(move);
      // Turn smoothly to face the way the gnome is running.
      const turn = shortestTurn(Math.atan2(move.x, move.z) - player.rotation.y);
      player.rotation.y += turn * (1 - Math.exp(-TURN_SPEED * dt));
    }
    pushOut(player.position);
    keepIn(player.position, GNOME_RADIUS);

    // Jump and fall. Walking down a slope, stay on the ground instead of floating off it for a moment.
    const floor = floorAt();
    if (grounded && verticalSpeed <= 0 && player.position.y - floor < 0.35) player.position.y = floor;
    if (player.position.y <= floor && controls.jump && canMove) verticalSpeed = JUMP_SPEED;
    verticalSpeed -= GRAVITY * dt;
    player.position.y += verticalSpeed * dt;
    const landed = player.position.y < floor && verticalSpeed < -3;
    if (player.position.y < floor) {
      player.position.y = floor;
      verticalSpeed = 0;
    }
    grounded = player.position.y <= floor;
    if (grounded) pace = speedAt(player.position.x, player.position.z);
    gnome.animate(dt, { running, pace: push, inAir: !grounded, verticalSpeed, landed });
    middle.copy(player.position).y += GNOME_MIDDLE;
  }

  // Smoothly follow the gnome from behind and above, looking a little over its head.
  function followCamera(dt) {
    lookAt.copy(middle).add(CAMERA_OFFSET);
    camera.position.lerp(lookAt, 1 - Math.exp(-5 * dt));
    camera.lookAt(lookAt.copy(middle).setY(middle.y + CAMERA_LOOK_ABOVE));
  }

  return { player, middle, place, update, followCamera };
}

// The smallest turn from one direction to another, between -180 and 180 degrees (in radians).
export function shortestTurn(angle) {
  return Math.atan2(Math.sin(angle), Math.cos(angle));
}
