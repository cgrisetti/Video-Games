# Everwood

A cooperative raid action-RPG for a family party, built in [Godot 4.7](https://docs.godotengine.org/en/stable/) (GDScript, Jolt physics). Up to 4 players share one screen in split-screen, and up to 5 play together over the network. It's a separate project from Lanternwood: no Vite, no three.js, no launcher page.

Read the design stack first: [CLAUDE.md](CLAUDE.md) (engineering rules), then [docs/01_VISION.md](docs/01_VISION.md), [docs/02_COMBAT_GDD.md](docs/02_COMBAT_GDD.md), [docs/03_GODOT_TDD.md](docs/03_GODOT_TDD.md), [docs/04_BALANCE.md](docs/04_BALANCE.md), [docs/05_ARSENAL_AND_CARDS_GDD.md](docs/05_ARSENAL_AND_CARDS_GDD.md) (weapons, armor and Scribe Cards, with the build blueprint), [docs/06_WORLD_AND_CALLINGS.md](docs/06_WORLD_AND_CALLINGS.md) (Bramblebridge, the Four Signs, card finishes and the Callings) and [docs/07_EXPEDITION_HUD_AND_ART_GDD.md](docs/07_EXPEDITION_HUD_AND_ART_GDD.md) (walkable Bramblebridge, Chimes, the 3x3 Callings, the Cross-Grimoire HUD, the Doverslap Expedition and storybook art, with build notes).

## What's playable

**The Doverslap Expedition**, the raid, in three zones end to end. **Zone 1**: the Ariundle Moss-Oaks and the Sunken Holloway, with two camps of woodland minions (Bramble-Scuttlers and Bog-Imps), clay Wind-Lanterns that chime as you pass, the Wayfarer's Water-Shrine (walk through its mist and the whole party is restored), and the Wayfarer's Chest hidden in a side alcove (Chimes and an Uncommon card). **Zone 2**: the Doverslap Gorge Bridge and the Sinaya Gatehouse, whose portcullis opens for two players standing on both Rune-Plates for 2 seconds (a companion takes the second plate in solo play), or for a teammate ringing the Bronze Bridge-Bell while sheltered from the Gorge Gale-Jet by a Shield-Sworn's Shadow Sanctuary. **Zone 3**: the Ring of the Cairnsman and its boss, **The Cairnsman of Doverslap**, a sentinel of stacked mossy river-boulders with boulder fists, bridge timbers, brass bell-ropes and a glowing amber core. Reaching a zone moves everyone's respawn to its checkpoint.

**Fellowships and Callings.** Every hero is one of three Fellowships, their raid seat, with one of three Secondary Callings on top; together they name one of nine Callings (06 §3):

| | Stout Heart (+Tank) | Swift Foot (+DPS) | Wise Hand (+Magic) |
|---|---|---|---|
| **The Shield-Sworn** (Tank) | Bridge-Warden | Weald-Captain | Hearth-Guard |
| **The Wayfarers** (DPS) | Iron-Woodsman | Hedge-Runner | Sign-Seeker |
| **The Lantern-Bearers** (Mender) | Bell-Keeper | Wind-Mender | Lantern-Scribe |

A Stout Heart adds 20 health, a wider Perfect Guard and harder poise hits, and unlocks heavy plate; a Swift Foot adds stamina regen and 15% strike damage, and unlocks the bow and the axe; a Wise Hand earns pips and heals 20% better, holds one more Grimoire Memory, and unlocks the staff. Each Fellowship starts in its own column.

**The Weapon Channels the Card.** Light and heavy come from your weapon; Forward + heavy, Back + heavy, R and L + R cast the four **Scribe Cards** in your Grimoire, delivered through that weapon: the Falchion or Broad-Axe swings them with a ribbon trail, the Yew Longbow or Rowan Way-Staff fires them as rune projectiles. Holding L is always Guard, and a guard raised just before a hit is a Perfect Guard (200 ms, 260 ms in heavy plate, +30 ms with a Stout Heart). Armor sets how much damage you shrug off, your stamina, how far you roll and that window.

- **The Shield-Sworn** (Falchion, Ironwood Plate, a banded Greatshield): holds the boss with threat. Shield Charge, Shadow Sanctuary (a shield cone for everyone behind you), Taunt and Bulwark Quake.
- **The Lantern-Bearers** (Rowan Way-Staff, Hearth-Linen, a glowing Tether-Lantern): the D-Pad tethers you to a party member. Sunlit Lance (a Warm-Hearth primer bolt), Green Sanctuary, Homing Heal down the tether, and Lifeline Pull.
- **The Wayfarers** (Yew Longbow, Ranger Leather, a quiver): the primer specialists. Rising Drive, Frost Crescent and Gale Rush stamp the Signs of Iron-Root, Rime-Gale and Star-Tide; Tempest Flow is the ultimate.
- **The Four Scribe Signs:** a primer card stamps its Sign on an enemy and a teammate's heavy detonates it: Iron-Root into **Shatterpoint** (poise), Rime-Gale into **Glacial Rupture** (damage that splashes nearby minions), Warm-Hearth into **Dawnburst** (party heal) or Star-Tide into **Astral Chorus** (party stamina and pips). Different roles or different Signs make it a x1.5 cross-harmony, and both players earn pips.
- **Card looks:** every invocation blooms its Sign's geometric seal under you and flips a vellum card over your shoulder. Cards come in three finishes: **Plain Vellum**; **Gilded Leaf**, which adds gold rings and a gold trail; and **Star-Inked Vellum**, which raises a starfield dome and leaves glowing footprints.
- **The boss** chases whoever has the most threat, telegraphs a slow Crushing Swipe (its fists rear back and its core glows hotter), and casts raid mechanics: **Crimson Bloom** (red circles under everyone: get out) and **Golden Communion** (a gold circle on one player: stack in to share the damage; half the standing party is enough). At half health it enters **Phase 2** and weaves in the **Doverslap Gale-Beam**: a 3.2 s blue lane aimed at its tank with a "stand behind the tank" shield pillar. Anyone in the tank's Shadow Sanctuary cone takes nothing and earns half a pip; anyone else in the lane takes 40 and is thrown back. Heavy hits and Perfect Guards break its poise for a 5-second knockdown.
- **Victory:** beat it and time slows for 2 seconds, everyone's screen says VICTORY!, the Grimoire levels up, and a reward chest drops in. Walk up to it and brass **Chimes** fly into the party's satchels with a collectible card (Rare and Legendary boss cards, Gilded Leaf and Star-Inked Vellum copies); the gold portal then takes everyone home. Cleared minion camps pay a few Chimes too.

**The Cross-Grimoire HUD.** Each player's moves sit in a cross at the bottom of their own screen, readable by shape and colour: the Forward card above the weapon, the Back card below, Guard on the left wing, the Signature card on the right, the Ultimate as a crown, and Roll in the corner. Card frames are tinted by their Sign with a corner ribbon for a linked under-card; a card you can't afford yet sits dimmed and lowered, and slides up with a gold border the moment you have the pips; any slot pops and flashes when you press or buffer it. Health, stamina, three pip gems, your Calling and the party's Chimes sit round the top, and a Lantern-Bearer gets a little D-Pad compass of Soul Tethers.

Three assist modes, one per player: **Master** (manual, +15% flow speed), **Adventurer** (bigger input buffer, camera follows the fight, combos chain for you) and **Squire Gambit** (one button picks the move, from range with a bow or staff; you auto-roll out of red circles, and your guard goes up by itself when the boss swings at you).

**Fewer than 3 people?** On the expedition, AI companions (marked "bot") fill whichever of Tank, Healer and DPS nobody is playing. They fight by a KOTOR-style Gambit list (dodge first, then help, then hit), clear minion camps with you, take a Rune-Plate, get behind the tank's shield for the Gale-Beam (a companion tank raises it), catch up if left behind, and step aside when someone joins.

**Storybook art.** Heroes are code-built puppets that read by Fellowship: the Shield-Sworn's crested helm and Greatshield, the Wayfarer's feathered hood and streaming cloak, the Lantern-Bearer's pointed scribe hat. Everything wears a two-band cel shader with a rim light, in a warm, sunlit day. Drop a `.glb` model into `assets/models/` to replace any hero, weapon, minion or the boss ([assets/models/README.md](assets/models/README.md)).

## Bramblebridge and hot-join

The game starts in **Bramblebridge** (in the files it's still `hub_town`). You arrive on the spawn green in the south and walk over the low stone arch the village is named for (no jump needed: Space is the roll) to the village square, with the canal and its watermill turning between them. On the square stand the **Armory & Scribe Desk** and the **Chime-Shrine**, and at its northern forest gate the **Raid Portal**: walk into it together (everyone standing on it) for a 3-second countdown into the Doverslap Expedition (`dungeon_dojo`); the gold exit portal there brings you back. The host moves the whole party and the ENet session stays up (`InstanceManager`).

At the **Scribe Desk**, press light to change your Fellowship, your Calling, your armor, weapon, the four lead cards and the four under-card links on your own screen (up / down picks, left / right changes, dodge closes); you change in place, and a new Fellowship reopens the desk for your new self. Gear your Calling can't use says which Calling unlocks it. The **Grimoire** starts at Lv 1 and gains a level with each win: more memory for Rare cards and one more under-card link (an under-card changes the card above it: Sign Infusion, a 20% Potency Surge or Hearth Echo). Each Fellowship's last kit and Calling are saved for its next seat.

At the **Chime-Shrine**, press light (J / X / □) to open its menu on your own screen: move up and down, light buys, dodge closes. Upgrades raise the whole party's Max Health or Stamina Regen by 10% a level (5 levels, costing 4, 8, 12, 16 and 20 Chimes). The Chimes, upgrades, card binder, kits, Callings and victories are shared by the party and saved in `user://everwood_progress.cfg` (on a Mac, `~/Library/Application Support/Godot/app_userdata/Everwood/`); delete that file to start fresh. Saves from before the rename keep their Dojo Shards as Chimes. Online, the host's save is the one that counts.

The keyboard and mouse is Player 1. Plugging in a pad joins the next player and splits the screen; unplugging drops them. Tap Enter / Start to join by hand, hold it 1.5 s to leave. Hold Tab / View for 0.6 s to change Fellowship, C / L3 to change Calling, M / R3 to change assist mode. Click to steer the camera with the mouse, Esc to let go. Balance numbers and the reasoning behind them: [docs/04_BALANCE.md](docs/04_BALANCE.md).

## Run it

Open `project.godot` in Godot 4.7 and press F5, or from this folder:

```bash
godot --path .
```

The keyboard player joins as soon as it starts. Each pad joins with **Start**. Fellowships fill out the trinity automatically; switch with Tab / Select. The Cross-Grimoire HUD shows each move's keys on your own screen.

| | Keyboard | Pad |
|---|---|---|
| Move | WASD | Left stick |
| Light / heavy | J / K (W or S + K: forward / back heavy) | □ / △ (stick + △: directional) |
| Dodge | Space | ✕ or ○ |
| Guard (hold) / Signature card | Q / E | L2 / R2 (or L1 / R1) |
| Ultimate card (both triggers) | R, or Q + E together | L2 + R2 together |
| Soul Tether (healer) | 1 2 3 4 | D-Pad |
| Camera (Master mode) | ← / → | Right stick |
| Change Fellowship / Calling / mode (hold) | Tab / C / M | Select / L3 / R3 |
| Chime-Shrine (at the shrine) | J, then W / S, J buys, Space closes | X / □, then stick or D-Pad, X / □ buys, A / ✕ closes |
| Scribe Desk (at the desk) | J, then W / S pick, A / D change, Space closes | X / □, then stick or D-Pad, A / ✕ closes |
| Bridge-Bell (sheltered, at the winch) | J | X / □ |
| Join | Enter | Start |
| Host / join / leave | F5 / F6 / F7 | |

### Playing over the network

One machine presses **F5** to host on port 7777. The others press **F6** to join (it joins `127.0.0.1` unless you start it with `-- --join=192.168.x.x`). Each machine's controllers keep their split-screen seats; the whole party is capped at 5. Players are addressed as `{peer}_{device}`, e.g. `1_0` is the host's keyboard.

Command-line options go after `--`: `--players=N`, `--mode=master|adventurer|squire`, `--host`, `--join=ADDRESS`, `--demo` (players fight on their own), `--weapon=ITEM_ID` and `--armor=ITEM_ID` (this screen's players start with them, e.g. `hunter_bow`, `ironwood_plate`), `--save=PATH` (play from another save file; tests use one so they never touch yours), `--instance=dungeon_dojo` (start on the expedition), `--zone=2` or `--zone=3` (start the expedition at that zone's checkpoint; 3 opens the gate), `--boss-health=0.4` (the Cairnsman's health share when his fight starts, to try Phase 2), `--screenshot=PATH`, `--screenshot-delay=S`, `--quit-after=S` (prints a report: boss health, zone, minions standing, the gate, cards, shots and detonations this peer saw, and each player's weapon).

## Layout

```text
project.godot
CLAUDE.md, docs/              design stack and engineering contract
assets/models/                drop-in .glb models (optional, CC0 only)
src/autoloads/                NetworkManager (ENet + party roster, Callings and kits), CombatDirector (hit-stop, Sign
                              seals, projectiles, shelter, routing), InstanceManager (Bramblebridge / expedition
                              changes), AudioCues, PartyProgress (Chimes, upgrades, card binder, kits, Callings, Grimoire)
src/resources/                CombatActionResource (frame data), CharacterStatsResource, ClassLoadoutResource (the
                              compiled loadout), PlayerClassResource (a class as one of its Callings),
                              EquipmentItemResource, ScribeCardResource, EquipmentLoadoutResource (a kit of ids),
                              ScribeSignResource, PropPartResource, CombatEvent, PartyMember
src/components/               Input (3 assist modes, menus), ActionQueue (4-phase pipeline + buffer), Stats,
                              Threat, Hitbox, Hurtbox, NetworkSync, SoulTether, CompanionAI (Gambit bots),
                              state_machine/ (Idle, Locomotion, Attack, Guard, Dodge, Stagger, Downed)
src/actors/                   ActorBase, ActorVisuals (hero puppets, the .glb hook), StorybookMaterial and the
                              storybook_cel shaders, BossDummy (the Cairnsman), WoodlandMinion, MinionCamp,
                              ClassLoadouts, Callings (the 3x3 matrix), ArsenalCatalog (autoload "Arsenal": every
                              item and card by id), LoadoutComposer (class + Calling + kit -> loadout), RuneProjectile,
                              WeaponTrail, ScribeInvocationFX, GlowFootprint, FxPool, PropBuilder, RaidTelegraphDecal,
                              SanctuaryZone, HomingHeal, CueBurst, RaidPortal, RewardChest, ChimeCoin, ChimeBurst,
                              Interactable, ChimeShrine, ScribeDesk, WaterShrine, WindLantern, CoopGate, RunePlate,
                              BellWinch, GorgeGaleJet, WatermillWheel; scribe_seal and astral_dome shaders
src/levels/                   hub_town / dungeon_dojo (.tscn generated, .gd hand-written), LevelBase
src/ui/                       SplitScreenViewportGrid, PlayerCamera, PlayerHUD, CrossGrimoireHUD, CrossSlot,
                              HubUpgradeMenu, ScribeDeskMenu
tools/                        build_levels.gd, build_input_map.gd, smoke_test.gd
```

- Actors build their own components in code. Don't hand-edit the level `.tscn` files: change `tools/build_levels.gd` and run it again. Controls live in project.godot's Input Map, written by `tools/build_input_map.gd`.
- Every tunable number is a named constant at the top of its script. Armor, weapons and Scribe Cards are data in `src/actors/arsenal_catalog.gd` (a new card or weapon is one entry there, or a `.tres` card in `res://data/cards/`); classes and their starter kits are in `src/actors/class_loadouts.gd`, and the nine Callings (names, numbers, gear) in `src/actors/callings.gd`.
- Networked combat follows one rule: the machine that owns the target applies the effect. `CombatDirector.deliver()` applies it locally or sends it to the owner, who checks it's plausible first. The host runs the boss, the minions, the gate and the shrine, and tells everyone what happened.
- Knee-high walls, rails and banks sit on their own physics layer (`LowScenery`): bodies bump into them, but cameras see past them.
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

The smoke test seats a Tank, Healer and DPS, drives them with scripted input and checks 292 things: the Arsenal (catalog, armor weights, the four weapons, under-card mutations, JSON kits, the Grimoire's rules, card drops, the Four Signs and finishes); the 3x3 Callings (names, numbers, gear unlocks, the roster); Bramblebridge (walking over the arch, the layout), the Input Map, hot-join, party caps, the split-screen grid and portals; the Doverslap Expedition (the ramp into the holloway, Wind-Lanterns, waking and clearing a camp, the Water-Shrine, the Wayfarer's Chest, checkpoints, the Gale-Jet, the gate opened by plates, by shelter and the bell, and by a companion on the second plate); the Cross-Grimoire HUD (slots, keys, Sign colours, pip readiness, pulses); the storybook puppets and cel shader; flow-cancels and their windows, hit-stop, all four Sign detonations and their rewards, bow and staff shots, the effect pool, armor in play, strikes crossing the network as ids, Hearth Echo, card invocations and their variants, poise, taunt, Perfect Guard, heals, Lifeline, Shadow Sanctuary, the telegraphs, soak scaling and the Phase 2 Gale-Beam; the Squire auto-evade, auto-guard and ranged picks; companions, including the Gale-Beam; the victory, chest, Chimes, card and Grimoire level; the Chime-Shrine (and old saves' shards) and the Scribe Desk with its Fellowship and Calling rows and hold C; and no orphaned nodes after Bramblebridge, the expedition and back (it uses its own save, never yours). Untyped variables, parameters and return values are build errors (`project.godot` sets that), so the check-only loop enforces the static-typing rule.

To see a frame without playing: `godot --path . -- --players=3 --instance=dungeon_dojo --zone=3 --boss-health=0.45 --demo --save=user://shot.cfg --screenshot=/tmp/ring.png --screenshot-delay=9`.
