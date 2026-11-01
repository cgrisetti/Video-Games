# Everwood

A cooperative raid action-RPG for a family party, built in [Godot 4.7](https://docs.godotengine.org/en/stable/) (GDScript, Jolt physics). Up to 4 players share one screen in split-screen, and up to 5 play together over the network. It's a separate project from Lanternwood: no Vite, no three.js, no launcher page.

Read the design stack first: [CLAUDE.md](CLAUDE.md) (engineering rules), then [docs/01_VISION.md](docs/01_VISION.md), [docs/02_COMBAT_GDD.md](docs/02_COMBAT_GDD.md), [docs/03_GODOT_TDD.md](docs/03_GODOT_TDD.md) and [docs/04_BALANCE.md](docs/04_BALANCE.md).

## What's playable

The **Dungeon Dojo**: a greybox arena with pillars for cover and the first raid boss, the **Dojo Warden**.

- **Shield Tank**: hold the boss with threat. Hold L to guard; a guard raised just before a hit (within 200 ms) is a Perfect Guard that costs nothing and staggers the boss. Back + heavy raises a Shadow Sanctuary cone that shields everyone behind you.
- **Soul-Tether Healer**: the D-Pad tethers you to a party member. R sends a homing heal down the tether, holding R drops a Green Sanctuary ring, and L+R is the Lifeline Pull that yanks your tether to safety.
- **Flow DPS**: long combos where the stick picks the next move. Forward + heavy primes Stagger, back + heavy primes Frost, L primes Radiant. A teammate's heavy hit detonates the primer for a bonus (x1.5 when it's a different class).
- **The boss** chases whoever has the most threat, telegraphs a slow Crushing Swipe, and casts raid mechanics: **Crimson Bloom** (red circles under everyone: get out) and **Golden Communion** (a gold circle on one player: stack in to share the damage). Heavy hits and Perfect Guards break its poise for a 5-second knockdown. Defeated, it rises again.

Three assist modes, one per player: **Master** (manual, +15% flow speed), **Adventurer** (bigger input buffer, camera follows the boss, combos chain for you) and **Squire Gambit** (one button picks the move; you auto-roll out of red circles).

## Hub Town and hot-join (Phase 5)

The game starts in **Hub Town**. Walk into the Raid Portal together (everyone standing on it) for a 3-second countdown into the Dungeon Dojo; the gold exit portal there brings you back. The host moves the whole party and the ENet session stays up (`InstanceManager`).

The keyboard and mouse is Player 1. Plugging in a pad joins the next player and splits the screen; unplugging drops them. Tap Enter / Start to join by hand, hold it 1.5 s to leave. Hold Tab / View for 0.6 s to change class, hold M / RS to change assist mode. Click to steer the camera with the mouse, Esc to let go. Balance numbers and the reasoning behind them: [docs/04_BALANCE.md](docs/04_BALANCE.md).

## Run it

Open `project.godot` in Godot 4.7 and press F5, or from this folder:

```bash
godot --path .
```

The keyboard player joins as soon as it starts. Each pad joins with **Start**. Classes fill out the trinity automatically; switch with Tab / Select.

| | Keyboard | Pad |
|---|---|---|
| Move | WASD | Left stick |
| Light / heavy | J / K (W or S + K: forward / back heavy) | □ / △ (stick + △: directional) |
| Dodge | Space | ✕ or ○ |
| L / R trigger skill | Q / E (hold E: R-hold skill) | L2 / R2 (or L1 / R1) |
| Ultimate (both triggers) | R, or Q + E together | L2 + R2 together |
| Soul Tether (healer) | 1 2 3 4 | D-Pad |
| Camera (Master mode) | ← / → | Right stick |
| Change class / mode | Tab / M | Select / R3 |
| Join | Enter | Start |
| Host / join / leave | F5 / F6 / F7 | |

### Playing over the network

One machine presses **F5** to host on port 7777. The others press **F6** to join (it joins `127.0.0.1` unless you start it with `-- --join=192.168.x.x`). Each machine's controllers keep their split-screen seats; the whole party is capped at 5. Players are addressed as `{peer}_{device}`, e.g. `1_0` is the host's keyboard.

Command-line options go after `--`: `--players=N`, `--mode=master|adventurer|squire`, `--host`, `--join=ADDRESS`, `--demo` (players fight on their own), `--screenshot=PATH`, `--screenshot-delay=S`, `--quit-after=S`.

## Layout

```text
project.godot
CLAUDE.md, docs/              design stack and engineering contract
src/autoloads/                NetworkManager (ENet + party roster), CombatDirector (hit-stop, synergies, routing)
src/resources/                CombatActionResource (frame data), CharacterStatsResource, ClassLoadoutResource,
                              CombatEvent, PartyMember
src/components/               Input (3 assist modes), ActionQueue (4-phase pipeline + buffer), Stats, Threat,
                              Hitbox, Hurtbox, NetworkSync, SoulTether, state_machine/ (Idle, Locomotion,
                              Attack, Guard, Dodge, Stagger, Downed)
src/actors/                   ActorBase, BossDummy, ClassLoadouts, RaidTelegraphDecal, SanctuaryZone, HomingHeal
src/levels/                   dungeon_dojo.tscn (generated) and dungeon_dojo.gd
src/ui/                       SplitScreenViewportGrid, PlayerCamera, PlayerHUD
tools/                        build_dojo_scene.gd, smoke_test.gd
```

- Actors build their own components in code. Don't hand-edit `dungeon_dojo.tscn`: change `tools/build_levels.gd` and run it again. Controls live in project.godot's Input Map, written by `tools/build_input_map.gd`.
- Every tunable number is a named constant at the top of its script. Class skills and their numbers live in `src/actors/class_loadouts.gd`.
- Networked combat follows one rule: the machine that owns the target applies the effect. `CombatDirector.deliver()` applies it locally or sends it to the owner, who checks it's plausible first.
- Scripts reach the autoloads as `NetworkManager.current` and `CombatDirector.current`, never by their autoload names (`Network`, `Combat`), so `--check-only` can compile them.

## Check it

From this folder:

```bash
for f in $(find src tools -name '*.gd'); do godot --headless --path . --check-only -s "res://$f"; done
```

```bash
godot --headless --path . --quit
```

```bash
godot --headless --path . --fixed-fps 60 -s res://tools/smoke_test.gd
```

The smoke test seats a Tank, Healer and DPS, drives them with scripted input and checks 103 things (hub, Input Map, hot-join, portals, all three detonations and their rewards, flow windows, poise): party caps, the split-screen grid, flow-cancels, hit-stop, prime and detonate, taunt, Perfect Guard, heals, Lifeline, Shadow Sanctuary, both telegraphs, the Squire auto-evade and the boss reset. Untyped variables, parameters and return values are build errors (`project.godot` sets that), so the check-only loop enforces the static-typing rule.

To see a frame without playing: `godot --path . -- --players=3 --demo --screenshot=/tmp/dojo.png --screenshot-delay=8`.
