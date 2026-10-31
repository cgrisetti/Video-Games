# Lanternwood (Godot 4)

The next version of Lanternwood, rebuilt in the [Godot](https://godotengine.org) game engine with
a richer look: real sunlight and soft shadows, warm haze, lantern light, swaying grass and leafy
trees. The three.js version in `games/lanternwood/` still works and is untouched.

So far this has **the Glenn** (the lantern-lit path between the hedges, with its gates and
openings), the gnome and the fox, the start and pause menus with Settings and How to play,
the music, and **Berry Rush** behind its gate. Gnome Crossing and the Bramble Maze come next;
for now their gates tell you they're on the way.

## Running it on a Mac

1. Install Godot 4.5 or newer (one time; it runs on 4.7). In Terminal:

   ```bash
   brew install --cask godot
   ```

   Or download it from <https://godotengine.org/download/macos/> and drag it to Applications.

2. Open Godot, click **Import**, and choose `games/lanternwood-godot/project.godot` in this folder.
   The first time, it takes a minute to prepare the music and shaders.
3. Press **F5** (or the ▶ button at the top right) to play.

To play without opening the editor:

```bash
cd games/lanternwood-godot
godot --path .
```

## Controls

| | Keyboard | Controller |
|---|---|---|
| Move | W A S D or arrows | Left stick or D-pad |
| Jump | Space | ✕ |
| Swing stick | F | □ |
| Wave to the fox (in the Glenn) | R | △ |
| Start the round over (in a game) | R | Pause, then Restart round |
| Go through a gate | F, then F | □, then □ |
| Turn the camera | Q, E | Right stick |
| Look up or down | T, G | Right stick |
| Pause | Esc or P | Options |
| Music on/off | M | In Settings |
| Save a picture | F12 | |

## Berry Rush

Through the Berry Rush gate (F, then F) is a raspberry glade inside a hedge, with a creek and
two bridges. "Ready…", then "Go!": pick all 9 raspberries, then follow the fox to the golden one,
as fast as you can. Three rainbow inch worms want to catch you. Swing your stick at a worm's head
to stun it (it gets back up a little faster). The creek slows everyone down. The fastest times
go in the Top 10.

Everything the three.js Berry Rush does is here, on a new field. On top of that:

- **Fair fields:** one berry in each ninth of the field, one over the creek, none by a worm.
- **A berry compass:** badges at the edge of the screen point to the nearest berries you can't see.
- **Medals:** gold, silver and bronze times for each field, the clock in the colour you're on
  pace for, and how you're doing against gold pace after each berry.
- **A finale that flows:** the fox lopes ahead to the golden raspberry at your pace, under a
  shaft of sunlight you can see across the field.
- **Worms you can read:** a "!" when one notices you, stars when it's bonked, crosser brows
  with every bonk.
- **Tension that builds:** the worms start asleep and wake one by one (at Go!, after your 3rd
  berry, after your 6th).
- **Impact:** a blink of a freeze and a little shake on a bonk; slow motion when you're caught.
  Turn shaking off in Settings.
- **Today's Glade:** one field all day, the same for everyone, with its own Top 10 that starts
  fresh each day. Choose it from the pause menu or the Top 10.

## Where things are

| | |
|---|---|
| `scenes/glen.tscn` | The Glenn: open it in the editor to see it. The openings, sun, sky, gnome and fox are placed here; drag an opening along the hedge to move it. |
| `scripts/glen.gd` | The Glenn's layout numbers (size, path, lanterns), and what happens at the openings. |
| `scripts/world/` | Builders for everything in the scenery: trees and hedges (`foliage.gd`), gates (`gates.gd`), lanterns, rocks and pumpkins (`props.gd`), the ground and grass (`meadow.gd`), fireflies and leaves (`atmosphere.gd`), and shared pieces (`art.gd`). |
| `shaders/` | How leaves, grass, bark, stone and the ground are drawn. |
| `scripts/gnome.gd`, `scripts/fox.gd` | The gnome and fox: their looks, their skeletons, and every move. |
| `scripts/fox_shape.gd`, `models/fox_*.res` | The fox's seamless skin: its shape, and the mesh baked from it by `tools/make_fox.gd`. |
| `scripts/fox_brain.gd` | What the fox decides to do: follow, explore, sniff, sit, lie down, pounce, play, greet, and point and lead the way in a game. |
| `scenes/berry_rush.tscn`, `scripts/berry_rush/` | Berry Rush: the game (`berry_rush.gd`, tunable numbers at the top), the field (`field.gd`), the creek (`creek.gd`), raspberries, inch worms, the berry compass and the pop effects. |
| `shaders/cloth.gdshader` | Felt, knitted wool, hair and leather for the characters. |
| `scripts/ui/` | The menu, the on-screen prompts and the Top 10 (`scoreboard.gd`). `ui/theme.tres` is their look. |
| `scripts/autoload/` | Settings (saved between visits), the Top 10 boards (`scores.gd`), music and sounds, and which buttons to show. |
| `STYLE_GUIDE.md` | How the new Lanternwood should look. Read it before adding things. |

## Checking it works

```bash
godot --headless --path . --script res://tools/smoke_test.gd
```

walks the gnome, jumps, waves, visits the gates and works the menus with the keyboard and a
controller, and prints PASS or FAIL for each.

```bash
godot --headless --fixed-fps 60 --path . --script res://tools/fox_walk.gd
```

takes the fox on a long walk (the gnome walks, stops, waves, jumps and swings) and checks it
kept to its rules: it stayed near, stayed inside the Glenn, came when waved to, and kept out of
the camera's way. It also prints what the fox chose to do.

```bash
godot --headless --fixed-fps 60 --path . --script res://tools/berry_rush_test.gd
```

plays Berry Rush: goes in through the gate, checks the field's rules, wades, picks every berry,
follows the fox to the golden raspberry, writes a name in the Top 10, wakes, bonks and gets
caught by worms, tries Today's Glade and comes back out. Its scores go in a test file, not
your real Top 10.

These need a real window:

```bash
godot --path . --script res://tools/benchmark.gd -- --graphics=high
```

measures frames a second standing at the start, walking up the Glenn and turning to the woods.
Add `--area=berry-rush` to measure Berry Rush, `--fullscreen` to measure full screen, or
`--off=grass,msaa` to see what an effect costs.

```bash
godot --path . --script res://tools/character_shots.gd -- --who=gnome --out=gnome.png
```

saves a sheet of close-up photos of the gnome (or `--who=fox`) from each side and mid-move.

```bash
godot --path . --script res://tools/berry_rush_shots.gd -- --out=berry-rush.png
```

saves photos of Berry Rush: the start, the field from above, a bridge, a worm, the golden
raspberry and the Top 10.

After changing the fox's shape in `scripts/fox_shape.gd`, bake its skin again (about a minute):

```bash
godot --headless --path . --script res://tools/make_fox.gd
```
