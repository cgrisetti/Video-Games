# Plan: menu ✕ button, new gnome and fox, a fox with a mind of its own, faster frames

Written 2026-10-31 on the `claude/godot-glen` branch. Status of each step is at the bottom, so a
fresh session can pick up where this one stopped.

## 1. ✕ doesn't select anything in the menus

**Cause (confirmed).** Godot's built-in "select" action for menus, `ui_accept`, only listens for
Enter, keypad Enter and Space. No controller button is mapped to it. ✕ (controller button 0) is
mapped only to `jump`, so in the menus it does nothing. △ (button 3) is on Godot's separate
`ui_select` action, which buttons don't use.

**Fix.** Add controller button 0 (✕) to `ui_accept` in `project.godot`, and ○ (button 1) to
`ui_cancel` so both "back" paths agree. Check that pressing ✕ on Play or Resume doesn't also make
the gnome jump as the game un-pauses.

**Test.** Extend `tools/smoke_test.gd`: with a simulated ✕ press, open Settings from the pause
menu, change a setting row, and go Back. Then resume and check the gnome didn't jump.

## 2. A new gnome and fox

### What the original prompts asked for (Oct 3–4, the three.js sessions)

- **Gnome:** "a small animated Nisse Gnome consistent with the style of David the Gnome", "a cute
  running and jumping style", "a stick in his right hand" with "a joyous and whimsical attack
  swinging stick animation", then the stick made 2× bigger.
- **Fox:** "an oversized red fox with a whimsical and kind face that follows" the gnome, like
  David's fox companion. It lowers into a sniffing stance and points its nose at the golden
  raspberry (a Berry Rush job, which isn't in Godot yet).

### What the Godot port lost

| | three.js version | Godot today |
|---|---|---|
| Gnome swing | Happy hop, other arm flung out, wobbly hat, sparkles off the stick tip | Arm swing only |
| Gnome idle | Breathes while standing | Stands frozen |
| Gnome from behind (the camera's usual view) | Readable hat and beard | A grey dome under a small hat |
| Stick | 2× size, per the prompt | Original small size |
| Fox size | Oversized: body 0.92 m up, legs 0.86 m | Smaller than the gnome's head height |
| Fox face | Cream cheeks, almond eyes with a sparkle, white jaw, dark-tipped ears with cream insides | A sphere with a cone snout and dot eyes |
| Fox legs | Two-tone with paws | Stiff cylinders, wrong gait pairing |

### The new gnome

- **Structure:** a proper skeleton of pivots: hips, spine, chest, neck and head. Each arm has a
  shoulder, elbow and mitten hand; each leg a hip, knee and boot. Knees and elbows bend, so the
  run looks like running.
- **Look:** chunky David-the-Gnome proportions. Tall felt hat (about half his height) with a
  floppy tip, a big round Nisse nose, bushy brows, rosy cheeks, and a full beard that wraps round
  the sides so it reads from behind. Little ears, a tuft of white hair at the back, belt and
  buckle, a tunic with a hem, rolled trousers and boots.
- **Texture:** felt, wool and leather made in code (soft noise bumps plus a gentle rim light),
  like the bark and stone shaders. The stick uses the bark shader, at the 2× size from the prompt.
- **Animation:**
  - Idle: breathes, blinks, glances about, and after a while leans on his stick or strokes his beard.
  - Run: knees and elbows pump; the head counters the bob; he leans into turns.
  - Jump: crouches first, stretches on take-off, tucks in the air, squashes on landing with a
    puff of dust. Small dust puffs at his feet while running.
  - Hat tip and beard: springy follow-through, so they swing and settle.
  - Swing: the three.js "joyous" version brought back: a hop, the free arm flung out, and
    sparkles trailing from the stick tip.
- **New action:** Wave (△ on a controller, R on the keyboard). He tips his hat and waves; the fox
  notices and comes bounding over, wagging.

### The new fox

- **Structure:** oversized (shoulder about at the gnome's chest). Spine and neck pivots, four
  two-jointed legs with paws, ears that perk, swivel and flatten, and a tail made of a springy
  chain of segments.
- **Look:** a smooth body with a cream belly and fluffy chest ruff, cheek fluffs, a rounded snout
  with a white jaw and black nose, big soft almond eyes with a sparkle (the kind face), tall
  dark-tipped ears with cream insides, dark socks and paws, and a bushy tail with a white tip.
  Fur texture plus a rim light.
- **Animation:**
  - Gaits by speed: walk, trot (diagonal leg pairs), and a bounding gallop.
  - Rest: sit (back legs fold), lie down with the tail curled round, breathing.
  - Small life: ear twitches, the head follows the gnome, tail wags, the sniff-the-ground pose.
  - Play bow, and the classic fox pounce: a high arc, nose-dive into the grass.

## 3. A fox that makes its own choices

Instead of always walking a fixed 1.9 m to one side, the fox picks what to do every few seconds
from a short list, weighted by what the gnome is up to:

| Choice | When it's likely |
|---|---|
| Follow loosely | Gnome is moving. The fox aims for a spot beside and a little ahead of where the gnome will be in a second, and that spot drifts. |
| Explore | Gnome is dawdling. The fox goes and sniffs something nearby: a pumpkin, a lantern post, flowers, mushrooms, a rock. |
| Sniff the ground | Anywhere; it stops, nose down, and the tail swishes. |
| Pounce | Now and then at a firefly or in long grass. |
| Sit and watch | Gnome stands still. It sits facing the gnome, ears swivelling. |
| Lie down | Gnome has been still a long while. |
| Play | Gnome jumps or swings the stick nearby: a play bow or a little zoom in a circle. |
| Greet | Gnome waves: bound over, wag, sit. |

Path rules that keep it natural:

- **A loose leash:** happy anywhere 1.5–7 m from the gnome. Past 7 m it heads back; past 12 m it
  gallops; past 30 m (after a gate) it simply appears beside the gnome.
- **Turns like an animal:** speed and turning rate are limited, so it curves round instead of
  spinning in place, and it speeds up and slows down smoothly.
- **Wanders a little:** the spot it aims for drifts with slow noise, and it stops and starts.
- **Stays out of the way:** never between the camera and the gnome, never stuck in a hedge
  (stays inside the Glenn), steps round rocks and lantern posts.
- **Same steps, any frame rate:** all movement is scaled by the frame time.

## 4. Faster frames, same look

Measured with the new `tools/benchmark.gd` on this Mac (Apple M5, Forward+). The GPU is the
bottleneck; the CPU needs only about 2–3 ms a frame.

| Before | High | Medium | Low |
|---|---|---|---|
| 1600×900 window, standing at the start | 20 fps | 25 fps | 53 fps |
| Full screen (3420×2146) | 8 fps | 13 fps | 19 fps |

What each effect costs on High in the window, from a 50 ms frame:
grass 21 ms, 4× anti-aliasing 12 ms (2× saves 6 ms), sun shadows 12 ms (of which leaf shadows
about 3, the shadow map size about 2 and soft edges about 2). Ambient occlusion, bounce light,
haze and glow are each under 1 ms.

Fixes in order of payoff. All of these are standard practice for a GPU-bound game:

1. **Draw the 3D at a capped resolution and upscale it** (MetalFX on Macs, FSR elsewhere), with
   the menus and text still sharp. The scale is worked out from the window, so a small window is
   unchanged and full screen on a Retina display draws about 2 million pixels instead of 7
   million. Measured: full screen High 8 → 16 fps, with a nearly identical picture.
2. **Grass level of detail:** full tufts near the gnome, simpler tufts further out, faded out
   where the haze hides it anyway, and a cheaper wind sway calculation. Grass is the single
   biggest cost.
3. **2× anti-aliasing on High instead of 4×**, keeping the edge smoothing pass. Measured −6 ms.
4. **Shadow tuning:** distant leaves stop casting shadows, the shadow map is sized to the
   graphics setting, and the soft shadow edges are kept, measured again.
5. **Lanterns fade their light out with distance** (and their shadows sooner).
6. Also: make Forward+ the project's renderer, so the full look shows without a command-line
   flag. And fix the bug where changing Graphics left the old grass behind, which doubled it.

Target: High at 40+ fps in a window and 30+ full screen, with before and after screenshots that
look the same.

## Order and checks

1. ✕ fix → smoke test → commit.
2. Gnome → screenshots from the game camera → smoke test → commit.
3. Fox look and animations → screenshots → commit.
4. Fox behaviour → a long simulated walk checking it stays inside the Glenn, keeps up, and spends
   time on each choice → commit.
5. Speed → benchmark every graphics setting, windowed and full screen → screenshots → commit.
6. Final full smoke test and benchmark; update README, STYLE_GUIDE and the How to play page.

## Status

- [x] Analysis and measurements
- [x] 1. ✕ button: `ui_accept` and `ui_cancel` now include ✕ and ○; the smoke test drives the menus by controller.
- [x] 2. Gnome: rebuilt, with idle, run, jump, swing, wave and fidgets; stick in his right hand.
- [x] 2. Fox look and animations: oversized, two-bone legs, walk/trot/gallop, sit, lie, sniff, bow, pounce, pant.
- [x] 3. Fox behaviour: `scripts/fox_brain.gd`; `tools/fox_walk.gd` checks its rules (8 of 8 runs passed).
- [x] 4. Speed (fps, standing at the start; before → after):

| | Window 1600×900 | Full screen 3420×2146 |
|---|---|---|
| High | 20 → 34 | 8 → 27 |
| Medium | 25 → 45 | 13 → 35 |
| Low | 53 → 60 | 19 → 50 |

  High missed the 40 / 30 targets by a few frames. What's left costs the look itself (shadows,
  grass, edge smoothing), so it stopped there.
- [x] Final checks and docs

Also fixed along the way: tube shapes (hat, tunic, tree trunks) were built inside out; changing
Graphics left the old grass behind; Forward+ is now the project's renderer.

Known: the first time something new comes into view (the far grass, a fox pose), Godot builds its
shader and there can be one short hitch. Godot keeps them, so it's smoother the next time.
