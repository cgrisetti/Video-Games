# Everwood

A cooperative raid action-RPG for a family party, built in [Godot 4.7](https://docs.godotengine.org/en/stable/) (GDScript, Jolt physics). Up to 4 players share one screen in split-screen, and up to 5 play together over the network. It's a separate project from Lanternwood: no Vite, no three.js, no launcher page.

Read the design stack first: [CLAUDE.md](CLAUDE.md) (engineering rules), then [docs/01_VISION.md](docs/01_VISION.md), [docs/02_COMBAT_GDD.md](docs/02_COMBAT_GDD.md), [docs/03_GODOT_TDD.md](docs/03_GODOT_TDD.md), [docs/04_BALANCE.md](docs/04_BALANCE.md) and [docs/05_ARSENAL_AND_CARDS_GDD.md](docs/05_ARSENAL_AND_CARDS_GDD.md) (weapons, armor and Scribe Cards, with the build blueprint) and [docs/06_WORLD_AND_CALLINGS.md](docs/06_WORLD_AND_CALLINGS.md) (Bramblebridge, the Four Signs, card finishes and the Callings).

## What's playable

**The Ring of the Cairnsman**: a greybox arena with pillars for cover and the first raid boss, **The Cairnsman of Doverslap**, a sentinel of stacked river stones, heather and brass bell-rope.

**The Weapon Channels the Card.** Light and heavy come from your weapon; Forward + heavy, Back + heavy, R and L + R cast the four **Scribe Cards** in your Grimoire, delivered through that weapon: a sword or axe swings them with a ribbon trail, a bow or staff fires them as rune projectiles. Holding L is always Guard, and a guard raised just before a hit (200 ms, 260 ms in heavy plate) is a Perfect Guard. Armor sets how much damage you shrug off, your stamina, how far you roll and that window.

- **Shield Tank** (Sword & Buckler, Ironwood Plate): holds the boss with threat. Shield Charge, Shadow Sanctuary (a shield cone for everyone behind you), Taunt and Bulwark Quake.
- **Soul-Tether Healer** (Scribe Staff, Hearth-Linen): the D-Pad tethers you to a party member. Sunlit Lance (a Warm-Hearth primer bolt), Green Sanctuary, Homing Heal down the tether, and Lifeline Pull.
- **Flow DPS** (Wind-Ash Hunter Bow, Ranger Leather): the primer specialist. Rising Drive, Frost Crescent and Gale Rush stamp the Signs of Iron-Root, Rime-Gale and Star-Tide; Tempest Flow is the ultimate.
- **The Four Scribe Signs:** a primer card stamps its Sign on the boss and a teammate's heavy detonates it: Iron-Root into **Shatterpoint** (poise), Rime-Gale into **Glacial Rupture** (damage), Warm-Hearth into **Dawnburst** (party heal) or Star-Tide into **Astral Chorus** (party stamina and pips). Different roles or different Signs make it a x1.5 cross-harmony, and both players earn pips.
- **Card looks:** every invocation blooms its Sign's geometric seal under you and flips a vellum card over your shoulder. Cards come in three finishes: **Plain Vellum**; **Gilded Leaf**, which adds gold rings and a gold trail; and **Star-Inked Vellum**, which raises a starfield dome and leaves glowing footprints.
- **The boss** chases whoever has the most threat, telegraphs a slow Crushing Swipe, and casts raid mechanics: **Crimson Bloom** (red circles under everyone: get out) and **Golden Communion** (a gold circle on one player: stack in to share the damage; half the standing party is enough, so two players can clear it). Heavy hits and Perfect Guards break its poise for a 5-second knockdown.
- **Victory:** beat it and time slows for 2 seconds, everyone's screen says VICTORY!, the Grimoire levels up, and a reward chest drops in. Walk up to it for the party's **Dojo Shards** and a collectible card (Rare and Legendary boss cards, Gilded Leaf and Star-Inked Vellum copies); the gold portal then takes everyone home.

Three assist modes, one per player: **Master** (manual, +15% flow speed), **Adventurer** (bigger input buffer, camera follows the boss, combos chain for you) and **Squire Gambit** (one button picks the move, from range with a bow or staff; you auto-roll out of red circles, and your guard goes up by itself when the boss swings at you).

**Fewer than 3 people?** In the Dojo, AI companions (marked "bot") fill whichever of Tank, Healer and DPS nobody is playing. They fight by a KOTOR-style Gambit list (dodge first, then help, then hit) and step aside when someone joins.

## Bramblebridge and hot-join

The game starts in **Bramblebridge**, a stepped-gable canal village with a watermill and the footbridge it's named for (in the files it's still `hub_town`). Walk into the Raid Portal together (everyone standing on it) for a 3-second countdown into the Ring of the Cairnsman (`dungeon_dojo`); the gold exit portal there brings you back. The host moves the whole party and the ENet session stays up (`InstanceManager`).

The **Armory & Scribe Desk** stands up the lane past the fountain. Press light there to change your armor, weapon, the four lead cards and the four under-card links on your own screen (up / down picks, left / right changes, dodge closes); you change in place. The **Grimoire** starts at Lv 1 and gains a level with each win: more memory for Rare cards and one more under-card link (an under-card changes the card above it: Sign Infusion, a 20% Potency Surge or Hearth Echo). Each class's last kit is saved for its next seat.

The **Shard Vendor's** stall stands across the lane from the fountain. Walk up and press light (J / X / □) to open its menu on your own screen: move up and down, light buys, dodge closes. Upgrades raise the whole party's Max Health or Stamina Regen by 10% a level (5 levels, costing 4, 8, 12, 16 and 20 shards). The shards, upgrades, card binder, kits and victories are shared by the party and saved in `user://everwood_progress.cfg` (on a Mac, `~/Library/Application Support/Godot/app_userdata/Everwood/`); delete that file to start fresh. Online, the host's save is the one that counts.

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
| Guard (hold) / Signature card | Q / E | L2 / R2 (or L1 / R1) |
| Ultimate card (both triggers) | R, or Q + E together | L2 + R2 together |
| Soul Tether (healer) | 1 2 3 4 | D-Pad |
| Camera (Master mode) | ← / → | Right stick |
| Change class / mode | Tab / M | Select / R3 |
| Shard Vendor (at the stall) | J, then W / S, J buys, Space closes | X / □, then stick or D-Pad, X / □ buys, A / ✕ closes |
| Scribe Desk (at the desk) | J, then W / S pick, A / D change, Space closes | X / □, then stick or D-Pad, A / ✕ closes |
| Join | Enter | Start |
| Host / join / leave | F5 / F6 / F7 | |

### Playing over the network

One machine presses **F5** to host on port 7777. The others press **F6** to join (it joins `127.0.0.1` unless you start it with `-- --join=192.168.x.x`). Each machine's controllers keep their split-screen seats; the whole party is capped at 5. Players are addressed as `{peer}_{device}`, e.g. `1_0` is the host's keyboard.

Command-line options go after `--`: `--players=N`, `--mode=master|adventurer|squire`, `--host`, `--join=ADDRESS`, `--demo` (players fight on their own), `--weapon=ITEM_ID` and `--armor=ITEM_ID` (this screen's players start with them, e.g. `hunter_bow`, `ironwood_plate`), `--save=PATH` (play from another save file; tests use one so they never touch yours), `--screenshot=PATH`, `--screenshot-delay=S`, `--quit-after=S` (prints a report: boss health, cards, shots and detonations this peer saw, and each player's weapon).

## Layout

```text
project.godot
CLAUDE.md, docs/              design stack and engineering contract
src/autoloads/                NetworkManager (ENet + party roster and kits), CombatDirector (hit-stop, Sign seals,
                              projectiles, routing), InstanceManager (Bramblebridge / raid changes), AudioCues,
                              PartyProgress (shards, upgrades, card binder, kits, Grimoire level)
src/resources/                CombatActionResource (frame data), CharacterStatsResource, ClassLoadoutResource (the
                              compiled loadout), PlayerClassResource, EquipmentItemResource, ScribeCardResource,
                              EquipmentLoadoutResource (a kit of ids), ScribeSignResource, PropPartResource,
                              CombatEvent, PartyMember
src/components/               Input (3 assist modes, menus), ActionQueue (4-phase pipeline + buffer), Stats,
                              Threat, Hitbox, Hurtbox, NetworkSync, SoulTether, CompanionAI (Gambit bots),
                              state_machine/ (Idle, Locomotion, Attack, Guard, Dodge, Stagger, Downed)
src/actors/                   ActorBase, BossDummy, ClassLoadouts, ArsenalCatalog (autoload "Arsenal": every item and
                              card by id), LoadoutComposer (class + kit -> loadout), RuneProjectile, WeaponTrail,
                              ScribeInvocationFX, GlowFootprint, FxPool, PropBuilder, RaidTelegraphDecal,
                              SanctuaryZone, HomingHeal, CueBurst, RaidPortal, RewardChest, Interactable,
                              ShardVendor, ScribeDesk; scribe_seal and astral_dome shaders
src/levels/                   hub_town / dungeon_dojo (.tscn generated, .gd hand-written), LevelBase
src/ui/                       SplitScreenViewportGrid, PlayerCamera, PlayerHUD, HubUpgradeMenu, ScribeDeskMenu
tools/                        build_levels.gd, build_input_map.gd, smoke_test.gd
```

- Actors build their own components in code. Don't hand-edit the level `.tscn` files: change `tools/build_levels.gd` and run it again. Controls live in project.godot's Input Map, written by `tools/build_input_map.gd`.
- Every tunable number is a named constant at the top of its script. Armor, weapons and Scribe Cards are data in `src/actors/arsenal_catalog.gd` (a new card or weapon is one entry there, or a `.tres` card in `res://data/cards/`); classes and their starter kits are in `src/actors/class_loadouts.gd`.
- Networked combat follows one rule: the machine that owns the target applies the effect. `CombatDirector.deliver()` applies it locally or sends it to the owner, who checks it's plausible first.
- Scripts reach the autoloads through each class's `current` (`NetworkManager.current`, `PartyProgress.current`, ...), never by their autoload names (`Network`, `Progress`, ...), so `--check-only` can compile them.

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

The smoke test seats a Tank, Healer and DPS, drives them with scripted input and checks 212 things: the Arsenal (catalog, armor weights, the four weapons, under-card mutations, JSON kits, the Grimoire's rules, card drops, the Four Signs and finishes); Bramblebridge, the Input Map, hot-join, party caps, the split-screen grid and portals; flow-cancels and their windows, hit-stop, all four Sign detonations and their rewards, bow and staff shots, the effect pool, armor in play, strikes crossing the network as ids, Hearth Echo, card invocations and their variants, poise, taunt, Perfect Guard, heals, Lifeline, Shadow Sanctuary, both telegraphs and soak scaling; the Squire auto-evade, auto-guard and ranged picks; companions; the victory, chest, card and Grimoire level; the Shard Vendor and the Scribe Desk; and no orphaned nodes after Bramblebridge, the Ring and back (it uses its own save, never yours). Untyped variables, parameters and return values are build errors (`project.godot` sets that), so the check-only loop enforces the static-typing rule.

To see a frame without playing: `godot --path . -- --players=3 --demo --screenshot=/tmp/dojo.png --screenshot-delay=8`.
