# Lanternwood (Godot 4)

The next version of Lanternwood, rebuilt in the [Godot](https://godotengine.org) game engine with
a richer look: real sunlight and soft shadows, warm haze, lantern light, swaying grass and leafy
trees. The three.js version in `games/lanternwood/` still works and is untouched.

So far this has **the Glenn** (the lantern-lit path between the hedges, with its gates and
openings), the gnome and the fox, the start and pause menus with Settings and How to play,
and the music. The mini-games behind the gates (Berry Rush, Gnome Crossing, the Bramble Maze)
come next; for now their gates tell you they're on the way.

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
| Wave to the fox | R | △ |
| Go through a gate | F, then F | □, then □ |
| Turn the camera | Q, E | Right stick |
| Look up or down | T, G | Right stick |
| Pause | Esc or P | Options |
| Music on/off | M | In Settings |
| Save a picture | F12 | |

## Where things are

| | |
|---|---|
| `scenes/glen.tscn` | The Glenn: open it in the editor to see it. The openings, sun, sky, gnome and fox are placed here; drag an opening along the hedge to move it. |
| `scripts/glen.gd` | The Glenn's layout numbers (size, path, lanterns), and what happens at the openings. |
| `scripts/world/` | Builders for everything in the scenery: trees and hedges (`foliage.gd`), gates (`gates.gd`), lanterns, rocks and pumpkins (`props.gd`), the ground and grass (`meadow.gd`), fireflies and leaves (`atmosphere.gd`), and shared pieces (`art.gd`). |
| `shaders/` | How leaves, grass, bark, stone and the ground are drawn. |
| `scripts/gnome.gd`, `scripts/fox.gd` | The gnome and fox: their looks, their skeletons of pivots, and every move. |
| `scripts/fox_brain.gd` | What the fox decides to do: follow, explore, sniff, sit, lie down, pounce, play, greet. |
| `shaders/cloth.gdshader` | Felt, knitted wool, hair and leather for the characters. |
| `scripts/ui/` | The menu and the on-screen prompts. `ui/theme.tres` is their look. |
| `scripts/autoload/` | Settings (saved between visits), music and sounds, and which buttons to show. |
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

These two need a real window:

```bash
godot --path . --script res://tools/benchmark.gd -- --graphics=high
```

measures frames a second standing at the start, walking up the Glenn and turning to the woods.
Add `--fullscreen` to measure full screen, or `--off=grass,msaa` to see what an effect costs.

```bash
godot --path . --script res://tools/character_shots.gd -- --who=gnome --out=gnome.png
```

saves a sheet of close-up photos of the gnome (or `--who=fox`) from each side and mid-move.
