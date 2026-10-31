# Plan: a seamless fox, Berry Rush in Godot, and a better Berry Rush

Written 2026-10-31 on `claude/godot-glen`. The status of each step is at the bottom, so a fresh
session can pick up where this one stopped. (The previous plan, for the ✕ button, the new gnome
and fox, and the speed-ups, is in `PLAN.md`.)

## 1. A seamless fox

**What's wrong.** The fox is about 40 separate shapes (blobs for the body, belly, chest, rump and
haunches, cylinders for the legs, cones for the ears) pushed into each other. Where they meet
you can see the seams, and the joints show gaps when the legs bend.

**The new fox is one continuous skin over a Godot skeleton:**

- **Shape:** the fox is described as about 30 rounded pieces (capsules and ellipsoids) that
  melt into each other (a "smooth union" of signed distance fields). A small tool turns that into
  one closed, smooth surface (surface nets, then a relax pass) and saves it as a mesh file:
  `models/fox_body.res`. It's built once, not every time the game starts.
- **Skeleton:** a `Skeleton3D` with the same joints the animation already drives (body, neck,
  head, jaw, ears, five tail pieces, three joints per leg). Each point of the skin is weighted
  to the joints near it, so the skin bends smoothly at shoulders, hips, knees and tail, with no
  gaps.
- **Colour:** painted into the mesh (orange coat, cream chest, belly and cheeks, dark stockings
  and ear tips, white tail tip), blending softly from one to the next like real fur markings. A
  new fur shader adds fine fur texture and a soft rim.
- **Kept:** every animation, gait and behaviour. Only the eyes, nose and tongue stay separate
  pieces, set into the face.

## 2. Berry Rush, rebuilt for Godot

Everything the three.js game does, with a new look:

| | The game, unchanged |
|---|---|
| Getting there | The Berry Rush gate in the Glenn (F, then F), a fade, and you arrive at the garden gate at the south end of the field. |
| Start | "Berry Rush" with "Ready…" for 1.6 s (nothing moves), then "Go!". |
| The field | 40 × 40 m inside a hedge (1.2 m thick), the gate in the middle of the south side. |
| Creek | Winds north-east to south-west; you and the worms wade at 60% speed; two arched bridges, with lanterns; some berries float over the water. |
| Obstacles, new every round | 14 trees (2 oaks, 2 maples, 2 poplars, the rest pines) that block you; 12 rocks and 4 logs you can jump over or stand on. Sizes and gaps follow the same rules. Trees between you and the camera fade. |
| Raspberries | 9, bobbing and spinning; touch one to pick it. Squash, pop, juice and leaves, a ring, its number floating up, and a chime that climbs with each berry. |
| The golden raspberry | After the 9th, in a quarter of the field you're not in, on dry open ground, with sun rays and a glow. Picking it wins. |
| The fox | Follows; when the golden raspberry appears it drops into a sniffing point for 1.5 s, then leads the way. Hint: "Follow the fox to the golden raspberry!" |
| Inch worms | 3, one per quarter, at least 10 m away, inching (tail bunches up, head reaches out) at up to 90% of your speed, slower in the creek, turning at most 60° per inch, steering round trees and rocks. Touch = caught. |
| Stick | A swing that catches a worm's head stuns it for 5 s: it rolls onto its side away from you with ✕ eyes, then gets up 5% faster (up to 99% of your speed). |
| Music | The danger layer swells as the nearest awake worm comes from 9 m to 3 m away. |
| Clock and HUD | Berries "n / 10" (turns gold at 9), the clock (37.4s, 1:23.4), the hint. |
| Top 10 | Fastest times. The same messages for each outcome; type a name (up to 10 letters, "Gnome" if blank); "Reset leaderboard" with a second click to confirm. Saved between visits. The gate's card in the Glenn shows the best time. |
| Controls | R restarts the round (in Berry Rush; R still waves in the Glenn). Pause menu: Resume, Restart round, Settings, How to play, Return to the Glenn (asks first mid-round). Options or ✕ on the Top 10 plays again. |
| Sounds | Swing, bonk, pop, golden run, chomp, all panned to where they happen. |

**New look**, following the style guide. A sunken raspberry glade at golden hour:
- **Edges:** flowering hedgerows lined with raspberry canes, and woods and far hills in the haze.
- **The creek:** a real water shader (moving ripples, see-through shallows, foam at the banks).
- **Bridges:** stone-and-timber.
- **Obstacles:** mossy logs and boulders, and trees from the same `Foliage` set as the Glenn.
- **Characters:** new smooth rainbow worms (one continuous body, not a string of balls), and
  raspberries made of glossy drupelets.

**Built as a Godot area.** `main.gd` swaps between the Glenn and Berry Rush with a fade.
Berry Rush is its own scene (`scenes/berry_rush.tscn`), with its own gnome and fox. It uses real
physics: the ground's height map for the creek banks, solid trees, and rocks and logs you can
land on.

## 3. Making Berry Rush better

### How the game plays now (from the code)

The loop: Ready → Go → plan a route through 9 random berries while 3 worms close in → bonk
worms to buy time (each bonk makes that worm faster) → golden raspberry → time → Top 10 →
instant retry. Rounds are 40–90 s.

**Strengths:**
- Short, fast to retry, and one clear goal.
- Random layouts.
- A real risk/reward choice in the bonk.
- The creek as a shortcut that costs speed.

**Problems:**

| | Problem | Why it matters |
|---|---|---|
| a | Finding the last berries. The field is 37 m across with up to 14 trees; a berry behind a tree or across the creek is often off screen. | Time lost to searching isn't skill, and it isn't fun. |
| b | No goal but the Top 10, and no idea mid-run how you're doing. | First runs have nothing to aim at; repeat runs can't show progress. |
| c | The fox leads to the golden raspberry at 5% of your speed (0.4 m/s). | The finale tells you to follow something you have to wait for. |
| d | You mostly hear a worm closing in, through the music. A bonk's +5% is invisible. | Players should be able to read threats and the cost of their choices. |
| e | All three worms chase from second 0. | Constant pressure, with no build-up and release. |
| f | Berries are scattered uniformly at random: sometimes clumped, sometimes one far outlier, sometimes next to a worm. | Times measure luck as much as skill, so the Top 10 is less fair. |
| g | The bonk and the catch happen without impact. | The big moments don't land. |
| h | Every layout is new, so you can never compare the same field with anyone. | No reason to come back tomorrow. |

### What the research says, briefly

- **Flow:** keep players between boredom and anxiety. Demand should also rise and fall over time:
  the tension-and-release curve ([Baumann et al. 2016](https://www.uni-trier.de/fileadmin/fb1/prof/PSY/PGA/unterlagen/BaumannL%C3%BCrigEngeser_Flow_MOEM_2016.pdf);
  [The flow applied to game design](https://www.gamedeveloper.com/design/the-flow-applied-to-game-design)).
- **Fairness:** players should be able to read threats through telegraphing, and unavoidable
  hits feel unfair ([Finding flow in hard games](https://www.gamedeveloper.com/design/oops-i-did-it-again-finding-flow-in-hard-games);
  [Appropriate difficulty in small games](https://abagames.github.io/joys-of-small-game-development-en/difficulty)).
- **Game feel:** a brief hit-stop, small shake and particles make hits land. Use restraint, and
  offer a way to turn shake off ([game feel and juice](https://www.wayline.io/learn/game-feel)).
- **Replayable, score-chasing loops** keep players through goals beyond the core loop, and by
  keeping decisions meaningful ([Casual game loops](https://gdevelop.io/blog/casual-game-loops);
  [Designing progression players stick with](https://cursa.app/en/article/game-development-core-loops-designing-progression-systems-players-actually-stick-with)).

### Upgrades, ranked by how much better the game gets for the work

1. **Fair layouts from a seed:**
   - Berries are spread across the field (one or two in each part, never in a clump, never next
     to a worm's start).
   - At least one berry is over the creek, as a risk choice.
   - Every berry can be reached.
   - Fixes f, and is the base for 8.
2. **The berry compass:** small berry-shaped pointers at the edge of the screen show the way to
   berries you can't see, gently, so you still plan your own route. Fixes a.
3. **A golden finale that flows:**
   - The fox points, then lopes ahead at your pace, waiting for you if you fall behind.
   - A shaft of sunlight rises over the golden raspberry, visible above the trees.
   - Fixes c.
4. **Goals and pace:**
   - Bronze, silver and gold times for each field, shown at the start and on the Top 10.
   - Your best splits are remembered, and each berry shows how you're doing against them
     ("−1.4s" in green, "+0.8s" in red).
   - Fixes b.
5. **Worms you can read:**
   - A worm that locks on to you pops a "!" and widens its eyes.
   - A bonked worm sees stars, and gets visibly crosser (brighter, faster stripes) with each bonk.
   - Fixes d.
6. **Tension that builds:** one worm wakes at Go, the second after your 3rd berry, the third
   after your 6th. Then the golden raspberry is the release. Fixes e.
7. **Impact:**
   - A 60 ms hit-stop and a small shake on a bonk.
   - When you're caught, a slow-motion zoom on the worm.
   - A Settings switch: Screen shake on/off.
   - Fixes g.
8. **Today's Glade:** the same field for everyone each day (a daily seed), with its own Top 10,
   next to the usual random field. Fixes h.

Upgrades 1, 6 and 8 change how the game plays. So the port in step 2 keeps 1:1 parity, and the
upgrades come after it, as their own commits.

## Order and checks

1. Fox: build the mesh tool → photos from every side and in every pose → fox walk test → commit.
2. Berry Rush: the area switch → field and scenery → berries and golden raspberry → worms → fox
   point and lead → HUD → Top 10 → menu and sounds. A new `tools/berry_rush_test.gd` plays a
   round headless (picks every berry, wins, saves a name; gets caught; bonks a worm; restarts;
   returns to the Glenn). Benchmark the field. Commit.
3. Each upgrade in turn, with checks added to the Berry Rush test, then commit.
4. Final: all tests, benchmark, docs (README, STYLE_GUIDE), push.

## Status

- [x] Analysis, research and plan
- [x] 1. Seamless fox
- [x] 2. Berry Rush port: `tools/berry_rush_test.gd` plays a round headless (31 checks, 8 of 8 runs)
- [x] 3. Upgrades 1–8, each its own commit, each with checks in `tools/berry_rush_test.gd`
  (now 59 checks)
- [x] Final checks and docs (README, STYLE_GUIDE)
- [ ] Push (asks first: it updates PR #3 and the Desktop launcher)
