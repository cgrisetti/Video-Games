# Everwood

A cooperative raid action-RPG for a family party, built in [Godot 4.7](https://docs.godotengine.org/en/stable/) (GDScript, Jolt physics). Up to 4 players share one screen in split-screen, and up to 5 play together over the network. It's a separate project from Lanternwood: no Vite, no three.js, no launcher page.

Read the design stack first: [CLAUDE.md](CLAUDE.md) (engineering rules), then [docs/01_VISION.md](docs/01_VISION.md), [docs/02_COMBAT_GDD.md](docs/02_COMBAT_GDD.md), [docs/03_GODOT_TDD.md](docs/03_GODOT_TDD.md), [docs/04_BALANCE.md](docs/04_BALANCE.md), [docs/05_ARSENAL_AND_CARDS_GDD.md](docs/05_ARSENAL_AND_CARDS_GDD.md) (weapons, armor and Scribe Cards, with the build blueprint), [docs/06_WORLD_AND_CALLINGS.md](docs/06_WORLD_AND_CALLINGS.md) (Bramble-Bridge, the Four Signs, card finishes and the Callings) [docs/07_EXPEDITION_HUD_AND_ART_GDD.md](docs/07_EXPEDITION_HUD_AND_ART_GDD.md) (walkable Bramble-Bridge, Chimes, the 3x3 Callings, the Cross-Grimoire HUD, the Dover-Slap-Falls Expedition and storybook art, with build notes) and [docs/10_WORLD_ARCHITECTURE.md](docs/10_WORLD_ARCHITECTURE.md) (the seamless Landblock world, with build notes) and [docs/11_COMBAT_ONBOARDING_AND_FEEL_GDD.md](docs/11_COMBAT_ONBOARDING_AND_FEEL_GDD.md) (the kinetic loop, Martial Imbuement and Levels 1 to 10, with build notes) and [docs/14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md](docs/14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md) (Sign-Flow, the Action-Leaf and Place-Card dioramas, Glimmer-Spots and the Reed-Light Scribery, with build notes) and [docs/15_THE_MYTHOPOETIC_LENS.md](docs/15_THE_MYTHOPOETIC_LENS.md) (the First-Quiet, the four Linter Rules, the six-zone atlas and the Hob-to-Boggart Spectrum, with the Pass 1 rename ledger) and [docs/16_ADAPTIVE_AUDIO_ARCHITECTURE.md](docs/16_ADAPTIVE_AUDIO_ARCHITECTURE.md) (the chamber-folk adaptive score, with build notes) and [docs/17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md](docs/17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md) (the Living Storybook Atelier: textures, world shaders, kits, biomes, draw distance and Ecological Succession, with build notes).

## What's playable

**Oakshire Vale**, the starting zone, where every launch begins: a streamed world 1.5 km square, 12 x 12 Landblocks. You arrive at Wayfarer-Green and follow the lantern-lit road north over the Bridge-Warden's span to Oakshire-Wick on its saddle, among 68 townsfolk (quest givers under a gold !, smiths who open the Armory, apothecaries who mend you). Five petal valleys ring the village, each with a camp, its own creatures (Curious Weald-Wights, Padfoot Boggarts, Furrow Iron-Men, Bramble-Hobs, Crag-Spriggans) and, in four of them, a portal apron in the rim crags sealed by a Scribe Sign until the party's level opens it. The river is a 0.4 m ford you splash through, and the Crag-Back Cairn-Drake walks the High Road. The dungeons behind the portals and a quest log aren't built yet (12 §6).

**Bramble-Bridge's seamless world** (start it with `-- --instance=bramblebridge`). The party wakes round a campfire at **the Kindle-Fire**, on the woodland trailhead south of Bramble-Bridge. Stand by the fire to warm up to full, then follow the walled lane east and north through **Honey-Wick** (a stepped-gable homestead, bee-hives and heirloom pumpkin patches), in at Bramble-Bridge's south gate and over the canal bridge. Once anyone reaches the village square, that's where the party gets back up and where a raid brings it home. The whole expedition lies north of the village with no loading screen: walk out of the open Forest Gate, under the Moss-Oak Great Arch, through the Moss-Oaks and down Rush-Light-Hollow, up a trail to Dover-Slap-Bridge and the Dover-Slap Gatehouse, and up the causeway to the Ring of the Cairnsman. The world is made of 128 m Landblocks that stream in round every player (all four split-screen views and everyone on the network), with far-off ones shown as simple silhouettes. Cleared camps, opened chests, the shrine's rest and the open gate stay that way as you come and go. AI companions join once anyone leaves the village, and after the Cairnsman a gold portal brings everyone home for a fresh run. The Raid Portal in the village still warps the party into the expedition as its own instance. Press **F4** to see the world's streaming in a corner badge.

**The Dover-Slap-Falls Expedition**, the raid, in three zones end to end. **Zone 1**: Moss-Oak-Hollow and Rush-Light-Hollow, with two Hush-Cracks of slumbering woodland kin (Bramble-Hobs and Wisp-Boggles, who fly off as hedge-wrens and rise as path-lights when beaten), clay Wind-Lanterns that chime as you pass, the Wayfarer's Water-Shrine (walk through its mist and the whole party is restored), and the Wayfarer's Chest hidden in a side alcove (Chimes and an Uncommon card). **Zone 2**: Dover-Slap-Bridge and the Dover-Slap Gatehouse, whose portcullis opens for two players standing on both Maker-Seal Plates for 2 seconds (a companion takes the second plate in solo play), or for a teammate ringing the Bronze Bridge-Bell while sheltered from the Gorge Gale-Jet by a Shield-Sworn's Shadow Sanctuary. **Zone 3**: the Ring of the Cairnsman and its boss, **The Cairnsman of Dover-Slap-Falls**, a sentinel of stacked mossy river-boulders with boulder fists, bridge timbers, brass bell-ropes and a glowing amber core. Reaching a zone moves everyone's respawn to its checkpoint.

**The Trail of the Four Signs.** A new party starts at Level 1 with lathe-turned timber (the Turned-Hazel Falchion, Reed-Light Way-Staff or Willow-Coppice Longbow) and the Bramble-Spun Jerkin. Every button works from the start: with no card in R or L+R, the weapon itself swings an **Un-Inked Martial Flourish** (the Falchion's Timber-Cross Slash, say, for 1 pip). Mobs, the Gorge gate and bosses pay XP; each new level flies a Saffron-Gold Wayfarer Pennant over every hero, and milestones drop straight into empty slots: Hedgerow Iron at Level 2, a first Plain Vellum R card at 3, Bramble-Bridge Steel and an L+R card at 5, an Under-Card beneath R at 7, and a Dover-Slap relic and the Secondary Callings at 10. One expedition takes the party to about Level 5, a second to 10. Old saves start at Level 5 or 10 by their Cairnsman wins.

**Move while you fight.** Every swing steps you forward (Back + heavy hops you back), and three Lights in place leave you winded on the third. Weave Forward + heavy, Back + heavy, R, L + R, a guard or a roll into the first moment of a Light's recovery for a **Flow-Link Pulse** (stamina back, a sliver of pip, a white-gold ring). Hit an enemy three times from the front and it raises a **Braced Front Guard**: the front takes 30% damage and a red shield-shove follows, so the tank cracks it with Iron-Root or holds it while someone lands a Forward + heavy, Back + heavy or R on its back for a **Flank Breach**. R and L + R swell your weapon to twice its size in your card's colour; a seal turns a Sign Ring under the enemy with a badge over its head, and your R slot rings gold ("R: DETONATE SIGN!") when a teammate's seal is yours to set off.

**Sign-Flow: "Coat, Break, Turn!"** Each of the L, R and L+R diamonds holds a diorama: an **Action-Leaf** (what you do: a Weapon-Coat, a Ward-Mantle or a Lantern-Tether) framed by a **Place-Card** (where you stand: Moss-Oak-Hollow, Dover-Slap-Bridge, the Bramble-Bridge Hearth-Mill or Barrow-Crag-Crossing). A Place-Card lends its strength (+15 poise, +0.8 m reach, a mending ember ring, stamina back on every Flow-Link), and one of the leaf's own Sign is **Home-Ground Harmony**: a gold star and a 25% longer coat. Out of combat, hold R or L+R for 1.5 s for the free **Hearth-Rite**: a pip in hand, the weapon glowing at 1.35x, and an opening strike that carries the Sign into the next fight. In combat, land a hit, then tap R, L+R or L in the short **Flow-Link Window** (longer near a Lantern-Bearer): the move goes off at once, the weapon flares to 2x, a 2.5 m Sign ring stamps the ground, and you're coated in the Sign for 8 s (10 on Home-Ground). Strike a boss's golden **Glimmer-Spot** with a Sign that counters it for a **Bravery Counter**: a huge poise hit and the Sign's detonation. The Cairnsman opens his as he roars into each raid cast (Iron-Root or Star-Tide cracks him); his window and HUD rhyme shrink as the family learns him. Minor kin crack under any Iron-Root strike. A Squire who presses just before the roar has the counter fire for them.

**Spirits, not monsters (the Mythopoetic Lens).** Every foe is a spirit of the First-Quiet, the earth's old sleep rising through cracks in the land (docs/15). Oakshire's Bristle-Hobs and Hedgerow-Hobs are curious, not hostile: walk within 6 m and, for 3 seconds, light (J / X / □, the Squire's one button) waves the Truce-Sign, the hob dances, and the party gets 25 Chimes and you a pip. Strike one instead and it turns boggart. Nothing leaves a body: a beaten padfoot flies off as a white sea-swallow, Bramble-Hobs as hedge-wrens, Wisp-Boggles rise as path-lights, Crag-Spriggans and the Cairnsman curl into mossy cairns, and a Furrow Iron-Man whose upside-down chest seal you open with a Warm-Hearth strike ("feed him a coal") and turn with an Iron-Root strike bows as a friendly steward for 10 minutes. The Crag-Back Cairn-Drake bellows a Challenge-Roar before its first swing. Walk into a new zone, or finish a Hearth-Rite Tuck there, and a couplet of its nursery rhyme unfurls above your cross, the coaching words tinted by Sign; a Saffron-Gold border glows round your screen while the Tuck is held.

**The adaptive score.** Every place has its own chamber-folk music, built in code until real recordings arrive: Honey-Wick's campfire sway, Bramble-Bridge's waltz (with a little "coming home" cadence as you cross into the square), Moss-Oak-Hollow darkening into bassoon-and-oboe hush as you go down Rush-Light-Hollow's sunken lane, Dover-Slap-Falls' march, the wind-swept Ring, and Oakshire Vale's pastoral. Four layers play in lock-step and the game turns them up and down: the hush whispers as you near sleeping kin, drums and dulcimer join when a fight starts, the Cairnsman has his own suite (when he's knocked down, a bright harp flourish tells everyone to pile in), and after a fight the music exhales and rests before the tune comes back. Every Sign detonation rings its own chord in the zone's key while the music dips under it, hits and arrows sound where they land, and the campfire, the water-shrines, the Chime-Shrine and the gate's plates have sounds of their own.

**A storybook world.** Every wall, roof, path and rock is painted in hand-made crafts (limestone flagstones, kiln brick, lime-wash, hewn timber, scalloped shingles, turf, loam and granite), all drawn in code. Bramble-Bridge, Honey-Wick and Oakshire-Wick are stepped-gable houses with half-timbering, jetties, dormers, window boxes and smoking chimneys, round a bakery with a glowing oven, a scribery hung with Sign-coloured vellum and the Oakshire Homestead Hall. Grass, wildflowers, ferns and pebbles grow in every landblock (daisies on the greens, rush-reeds in the hollows, heather on the crags) and sway as you brush past; trees, roofs and arches fade out of the way when they'd hide your hero. Water runs aqua to teal with foam, the canal's wheel splashes, the sky and fog change as you walk from meadow to hollow to highland, and a painted horizon of the atlas's far lands (the cataract mist north, granite tors west, windmills east, chalk cliffs south) rings the view out to 3 km. Each place has its landmarks: Wayfarer-Green's windmill, Pippin-Green's cider mill and furrows, Quarry-Wick's cranes, Bramble-Hollow's willow pools and Nine-Stones-Crossing's ring of standing stones. Chime-Posts at the thresholds ring as you pass and sing that place's rhyme. Round every open Hush-Crack the land greys and the lanterns dim; clear its camp and a golden bloom sweeps out and the crack becomes a mossy cairn ringed with flowers, for good.

**Fellowships and Callings.** Every hero is one of three Fellowships, their raid seat, with one of three Secondary Callings on top; together they name one of nine Callings (06 §3):

| | Stout Heart (+Tank) | Swift Foot (+DPS) | Wise Hand (+Magic) |
|---|---|---|---|
| **The Shield-Sworn** (Tank) | Bridge-Warden | Weald-Captain | Hearth-Guard |
| **The Wayfarers** (DPS) | Iron-Woodsman | Hedge-Runner | Sign-Seeker |
| **The Lantern-Bearers** (Mender) | Bell-Keeper | Wind-Mender | Lantern-Scribe |

A Stout Heart adds 20 health, a wider Perfect Guard and harder poise hits, and unlocks the Iron-Wood Ring-Coat; a Swift Foot adds stamina regen and 15% strike damage, and unlocks the bow and the axe; a Wise Hand earns pips and heals 20% better, holds one more Grimoire Memory, and unlocks the staff. The Secondary Callings open at Level 10 (until then a hero is Unsworn, with their Fellowship's own gear); then each Fellowship starts in its own column.

**The Weapon Channels the Card.** Light and heavy come from your weapon; Forward + heavy, Back + heavy, R and L + R cast the four **Scribe Sign-Cards** in your Grimoire, delivered through that weapon: the Falchion or Broad-Axe swings them with a ribbon trail, the Yew Longbow or Rowan Way-Staff fires them as Sign-bolts and Sign-arrows. Holding L is always Guard, and a guard raised just before a hit is a Perfect Guard (200 ms, 260 ms in heavy plate, +30 ms with a Stout Heart). Armor sets how much damage you shrug off, your stamina, how far you roll and that window.

- **The Shield-Sworn** (Falchion, Iron-Wood Ring-Coat, a banded Greatshield): holds the boss with threat. Shield Charge, Shadow Sanctuary (a shield cone for everyone behind you), Taunt and Bulwark Quake.
- **The Lantern-Bearers** (Rowan Way-Staff, Hearth-Linen Coat, a glowing Tether-Lantern): the D-Pad tethers you to a party member. Sunlit Lance (a Warm-Hearth primer bolt), Green Sanctuary, Homing Heal down the tether, and Lifeline Pull.
- **The Wayfarers** (Yew Longbow, Hedgerow Wool-Mantle, a quiver): the primer specialists. Rising Drive, Frost Crescent and Gale Rush stamp the Signs of Iron-Root, Rime-Gale and Star-Tide; Tempest Flow is the ultimate.
- **The Four Scribe Signs:** a primer card stamps its Sign on an enemy and a teammate's heavy detonates it: Iron-Root into **Shatterpoint** (poise), Rime-Gale into **Glacial Rupture** (damage that splashes nearby foes), Warm-Hearth into **Dawnburst** (party heal) or Star-Tide into **Astral Chorus** (party stamina and pips). Different roles or different Signs make it a x1.5 cross-harmony, and both players earn pips.
- **Card looks:** every invocation blooms its Sign's geometric seal under you and flips a vellum card over your shoulder. Cards come in three finishes: **Plain Vellum**; **Gilded Leaf**, which adds gold rings and a gold trail; and **Star-Inked Vellum**, which raises a starfield dome and leaves glowing footprints.
- **The boss** chases whoever has the most threat, telegraphs a slow Crushing Swipe (its fists rear back and its core glows hotter), and casts raid mechanics: **Crimson Bloom** (red circles under everyone: get out) and **Golden Communion** (a gold circle on one player: stack in to share the damage; half the standing party is enough). At half health it enters **Phase 2** and weaves in the **Dover-Slap Gale-Beam**: a 3.2 s blue lane aimed at its tank with a "stand behind the tank" shield pillar. Anyone in the tank's Shadow Sanctuary cone takes nothing and earns half a pip; anyone else in the lane takes 40 and is thrown back. Heavy hits and Perfect Guards break its poise for a 5-second knockdown.
- **Victory:** beat it and time slows for 2 seconds, everyone's screen says VICTORY!, the Grimoire levels up, and a reward chest drops in. Walk up to it and brass **Chimes** fly into the party's satchels with a collectible card (Rare and Legendary boss cards, Gilded Leaf and Star-Inked Vellum copies); the gold portal then takes everyone home. Sealed Hush-Cracks pay a few Chimes too.

**The Cross-Grimoire HUD.** Each player's moves sit in a cross at the bottom of their own screen, readable by shape and colour: the Forward card above the weapon, the Back card below, Guard on the left wing, the Signature card on the right, the Ultimate as a crown, and Roll in the corner. Card frames are tinted by their Sign with a corner ribbon for a linked under-card; a card you can't afford yet sits dimmed and lowered, and slides up with a gold border the moment you have the pips; any slot pops and flashes when you press or buffer it. Health, stamina, three pip gems, your Calling and the party's Chimes sit round the top, and a Lantern-Bearer gets a little D-Pad compass of Soul Tethers.

Three assist modes, one per player: **Master** (manual, +15% flow speed), **Adventurer** (bigger input buffer, camera follows the fight, combos chain for you) and **Squire Gambit** (one button picks the move, from range with a bow or staff; you auto-roll out of red circles, your guard goes up by itself when the boss swings at you, and in the Gale-Beam a Squire tank raises Shadow Sanctuary by itself while everyone else rolls out of the lane).

**Fewer than 3 people?** On the expedition, AI companions (marked "bot") fill whichever of Tank, Healer and DPS nobody is playing. They fight by a KOTOR-style Gambit list (dodge first, then help, then hit), seal Hush-Cracks with you, take a Maker-Seal Plate, get behind the tank's shield for the Gale-Beam (a companion tank raises it), catch up if left behind, and step aside when someone joins.

**Storybook art.** Heroes are code-built puppets that read by Fellowship: the Shield-Sworn's crested helm and Greatshield, the Wayfarer's feathered hood and streaming cloak, the Lantern-Bearer's pointed scribe hat. Everything wears a two-band cel shader with a rim light, in a warm, sunlit day. Drop a `.glb` model into `assets/models/` to replace any hero, weapon, woodland kin or the boss ([assets/models/README.md](assets/models/README.md)).

## Bramble-Bridge and hot-join

The game starts in Oakshire Vale. `-- --instance=bramblebridge` starts the seamless world (`everwood_world`) instead, at the Kindle-Fire just south of **Bramble-Bridge**, and `-- --instance=hub` the classic walled hub (in the files it's still `hub_town`, where the Forest Gate is shut). You come in at the south gate onto the spawn green and walk over the low stone arch the village is named for (no jump needed: Space is the roll) to the village square, with the canal and its watermill turning between them. On the square stand the **Armory & Scribe Desk** and the **Chime-Shrine**, and by its northern Forest Gate the **Raid Portal**: walk into it together (everyone standing on it) for a 3-second countdown into the instanced Dover-Slap-Falls Expedition (`dungeon_dojo`); the gold exit portal there brings you back to whichever Bramble-Bridge you came from. In the seamless world you can instead walk straight out of the gate. The host moves the whole party and the ENet session stays up (`InstanceManager`).

At the **Scribe Desk**, press light to change your Fellowship, your Calling, your armor, weapon, the four lead cards and the four under-card links on your own screen (up / down picks, left / right changes, dodge closes); you change in place, and a new Fellowship reopens the desk for your new self. Gear your Calling can't use says which Calling unlocks it. The **Grimoire** starts at Lv 1 and gains a level with each win: more memory for Rare cards and one more under-card link (an under-card changes the card above it: Sign Infusion, a 20% Potency Surge or Hearth Echo). Each Fellowship's last kit and Calling are saved for its next seat.

At the **Reed-Light Scribery** (the stepped-gable pavilion on the square's west side, its four ink vats glowing in the Sign colours), press light to open its counter: inscribe Action-Leaves and chart Place-Cards for 25 Chimes each, or gild a card at the press (Gilded Leaf 50, Star-Inked Vellum 120). A tap of **Tab / View** anywhere out of combat opens the **Grimoire Binder**: your diamonds big in the middle, Action-Leaves on the left page, Place-Cards on the right, and the Collection Folio of every card found and still to find.

At the **Chime-Shrine**, press light (J / X / □) to open its menu on your own screen: move up and down, light buys, dodge closes. Upgrades raise the whole party's Max Health or Stamina Regen by 10% a level (5 levels, costing 4, 8, 12, 16 and 20 Chimes). The Chimes, upgrades, card binder, kits, Callings and victories are shared by the party and saved in `user://everwood_progress.cfg` (on a Mac, `~/Library/Application Support/Godot/app_userdata/Everwood/`); delete that file to start fresh. Saves from before Chimes keep their old pouch as Chimes. Online, the host's save is the one that counts.

The keyboard and mouse is Player 1. Plugging in a pad joins the next player and splits the screen; unplugging drops them. Tap Enter / Start to join by hand, hold it 1.5 s to leave. Hold Tab / View for 0.6 s to change Fellowship, C / L3 to change Calling, M / R3 to change assist mode. Click to steer the camera with the mouse, Esc to let go. Balance numbers and the reasoning behind them: [docs/04_BALANCE.md](docs/04_BALANCE.md).

## Run it

Open `project.godot` in Godot 4.7 and press F5, or from this folder:

```bash
godot --path .
```

Either way you arrive in Oakshire Vale at Wayfarer-Green. To start in Bramble-Bridge's seamless world or the classic hub instead:

```bash
godot --path . -- --instance=bramblebridge
```

```bash
godot --path . -- --instance=hub
```

Terrain3D is optional and not in git (`addons/` is ignored). Without it the world draws its own ground meshes and plays the same. To draw the ground with Terrain3D on your machine, run this once from this folder, then `godot --headless --path . --import`:

```bash
tools/fetch_terrain3d.sh
```

The keyboard player joins as soon as it starts. Each pad joins with **Start**. Fellowships fill out the trinity automatically; switch with Tab / Select. The Cross-Grimoire HUD shows each move's keys on your own screen.

| | Keyboard | Pad |
|---|---|---|
| Move | WASD | Left stick |
| Light / heavy | J / K (W or S + K: forward / back heavy) | □ / △ (stick + △: directional) |
| Dodge | Space | ✕ or ○ |
| Guard (hold) / Signature card | Q / E | L2 / R2 (or L1 / R1) |
| Ultimate card (both triggers) | R, or Q + E together | L2 + R2 together |
| Hearth-Rite Tuck (out of combat) | hold E, or R / Q + E, 2 s | hold R2, or L2 + R2, 2 s |
| Wave the Truce-Sign (at a curious hob) | J | X / □ |
| Grimoire Binder (out of combat) | tap Tab | tap View / Select |
| Soul Tether (healer) | 1 2 3 4 | D-Pad |
| Camera (Master mode) | ← / → | Right stick |
| Change Fellowship / Calling / mode (hold) | Tab / C / M | Select / L3 / R3 |
| Chime-Shrine (at the shrine) | J, then W / S, J buys, Space closes | X / □, then stick or D-Pad, X / □ buys, A / ✕ closes |
| Scribe Desk (at the desk) | J, then W / S pick, A / D change, Space closes | X / □, then stick or D-Pad, A / ✕ closes |
| Reed-Light Scribery (at the counter) | J, then A / D tabs, W / S pick, J buys, Space closes | X / □, then stick or D-Pad, X / □ buys, A / ✕ closes |
| Bridge-Bell (sheltered, at the winch) | J | X / □ |
| Join | Enter | Start |
| Host / join / leave | F5 / F6 / F7 | |
| Landblock telemetry badge | F4 | |

### Playing over the network

One machine presses **F5** to host on port 7777. The others press **F6** to join (it joins `127.0.0.1` unless you start it with `-- --join=192.168.x.x`). Each machine's controllers keep their split-screen seats; the whole party is capped at 5. Players are addressed as `{peer}_{device}`, e.g. `1_0` is the host's keyboard.

Command-line options go after `--`: `--players=N`, `--mode=master|adventurer|squire`, `--host`, `--join=ADDRESS`, `--demo` (players fight on their own), `--weapon=ITEM_ID` and `--armor=ITEM_ID` (this screen's players start with them, e.g. `hunter_bow`, `ironwood_plate`), `--save=PATH` (play from another save file; tests use one so they never touch yours), `--instance=bramblebridge` (Bramble-Bridge's seamless world, from the Kindle-Fire), `--instance=hub` (the classic hub) or `--instance=expedition` (the instanced expedition); without it every launch starts in Oakshire Vale at Wayfarer-Green (the ids `everwood_world`, `hub_town`, `dungeon_dojo` and `oakshire_vale` work too, and a name it doesn't know is ignored), `--telemetry` (show the F4 badge from the start), `--zone=2` or `--zone=3` (start the expedition at that zone's checkpoint; 3 opens the gate), `--boss-health=0.4` (the Cairnsman's health share when his fight starts, to try Phase 2), `--screenshot=PATH`, `--screenshot-delay=S`, `--quit-after=S` (prints a report: boss health, zone, woodland kin standing, the gate, cards, shots and detonations this peer saw, and each player's weapon).

## Layout

```text
project.godot
CLAUDE.md, docs/              design stack and engineering contract
assets/models/                drop-in .glb models (optional, CC0 only); assets/models/world/<kit_id>.glb replaces a world
                              kit, assets/textures/world/<set>_<map>.png an atelier texture
data/landblocks/              the seamless world's Landblocks (landblock_X_Z.tscn) and HLOD proxies (hlod_X_Z.res),
                              generated by tools/build_levels.gd; oakshire_vale/ holds Oakshire's, with its baked
                              ground (field.res) and horizon (horizon.res), generated by tools/build_oakshire_vale.gd
scenes/worlds/                oakshire_vale.tscn (generated)
src/autoloads/                NetworkManager (ENet + party roster, Callings and kits), CombatDirector (hit-stop, Sign
                              seals, projectiles, shelter, routing), InstanceManager (Bramble-Bridge / expedition
                              changes), AudioCues, PartyProgress (Chimes, upgrades, card binder, kits, Callings, Grimoire)
src/resources/                CombatActionResource (frame data), CharacterStatsResource, ClassLoadoutResource (the
                              compiled loadout), PlayerClassResource (a class as one of its Callings),
                              EquipmentItemResource, ScribeCardResource, EquipmentLoadoutResource (a kit of ids, with
                              its dioramas), ScribeSignResource, BossEncounterResource (threat tier, Glimmer-Spot
                              window, impact), MobVariantResource, StewardshipZoneResource (a zone of the
                              Mythopoetic Atlas), ZoneMusicProfileResource, SignHarmonicProfileResource,
                              CallingAudioProfileResource, BossAudioProfileResource, ZoneBiomeResource,
                              WorldPropKitResource, ZoneSuccessionVisualResource, PropPartResource, CombatEvent, PartyMember
src/core/                     AudioDirector (autoload "Score": the buses, the two music decks, the combat stages, the
                              32-voice 3D pool, stingers), AudioCatalog (every zone, Sign, Calling and boss sound
                              profile by id), ProceduralChamberSynth (the code-built stems, stingers and ambience)
src/combat/                   SignFlowComponent (the Hearth-Rite Tuck, Flow-Link casts and coats, on heroes),
                              GlimmerSpotComponent (Glimmer-Spots and Bravery Counters, on foes),
                              HobSpectrumComponent (the Hob-to-Boggart Spectrum: parley, turning boggart, the
                              Maker-Seal, the Challenge-Roar, un-boggarting; on every foe), UnboggartFx
src/components/               Input (3 assist modes, menus), ActionQueue (4-phase pipeline + buffer), Stats,
                              Threat, Hitbox, Hurtbox, NetworkSync, SoulTether, CompanionAI (Gambit bots),
                              state_machine/ (Idle, Locomotion, Attack, Guard, Dodge, Stagger, Downed)
src/actors/                   ActorBase, ActorVisuals (hero puppets, the .glb hook), StorybookMaterial and the
                              storybook_cel shaders, BossDummy (the Cairnsman), WoodlandMinion, MinionCamp,
                              ClassLoadouts, Callings (the 3x3 matrix), ArsenalCatalog (autoload "Arsenal": every
                              item and card by id), LoadoutComposer (class + Calling + kit -> loadout), RuneProjectile,
                              WeaponTrail, ScribeInvocationFX, GlowFootprint, FxPool, PropBuilder, RaidTelegraphDecal,
                              SanctuaryZone, HomingHeal, CueBurst, RaidPortal, RewardChest, ChimeCoin, ChimeBurst,
                              Interactable, ChimeShrine, ScribeDesk, ScriberyStation (the Reed-Light Scribery), WaterShrine, HearthCampfire, WindLantern, CoopGate, RunePlate,
                              BellWinch, GorgeGaleJet, WatermillWheel; scribe_seal and astral_dome shaders; Oakshire's
                              Bestiary, WildMob, MobSpawner, AmbientFlock, TownsfolkNPC and PortalApron;
                              MythopoeticAtlas (the six zones, their rhymes, and each place's zone); ChimePost,
                              HushCrackLandmark (a camp's Hush-Crack and Lulled Cairn)
src/levels/                   everwood_world / hub_town / dungeon_dojo (.tscn generated, .gd hand-written), LevelBase,
                              oakshire_vale.gd
src/world/                    the Landblock world: WorldGridConfig, WorldLayout (DoverslapLayout, OakshireValeLayout,
                              OakshireValeField), LandblockManifest, WorldGridManager (streaming),
                              WorldStateDB + WorldStateBinding, LandblockTerrain, LandblockClutter, ChunkNavBuilder,
                              NavSteering; the storybook world: WorldVisualCatalog (biomes, kits, succession, shared
                              materials), WorldAtmosphereDirector (autoload "Atmosphere": the atelier, sky, sun and
                              fog, the shaders' heroes, cracks and blooms), ProceduralTextureAtelier, WorldAssetCatalog
                              (the kits) and WorldKitInstance, ChunkClutterBaker, HorizonVistaRing; shaders/ (the
                              triplanar, terrain splat, foliage wind and water stream shaders)
src/ui/                       SplitScreenViewportGrid, PlayerCamera, PlayerHUD, CrossGrimoireHUD, CrossSlot,
                              CrossGrimoireDiamondWidget (the diamonds: HUD 1.0x, Binder and Scribery 2.2x),
                              GrimoireBinderPanel, ScriberyShopPanel, HubUpgradeMenu, ScribeDeskMenu, WorldTelemetryBadge
tools/                        build_levels.gd, build_oakshire_vale.gd, build_input_map.gd, smoke_test.gd,
                              test_world_grid.gd, test_oakshire_vale.gd, test_mythopoetic_lens.gd, test_adaptive_audio.gd,
                              test_world_visuals.gd,
                              fetch_terrain3d.sh (optional Terrain3D)
```

- Actors build their own components in code. Don't hand-edit the level `.tscn` files or the Landblocks: change `tools/build_levels.gd` (or `tools/build_oakshire_vale.gd` for Oakshire) and run it again. Controls live in project.godot's Input Map, written by `tools/build_input_map.gd`.
- Every tunable number is a named constant at the top of its script. Armor, weapons and Scribe Cards are data in `src/actors/arsenal_catalog.gd` (a new card or weapon is one entry there, or a `.tres` card in `res://data/cards/`); classes and their starter kits are in `src/actors/class_loadouts.gd`, and the nine Callings (names, numbers, gear, trim colour) are registered in `arsenal_catalog.gd` too, read by `src/actors/callings.gd`. Code-built shapes come from `src/actors/shape_kit.gd`.
- Networked combat follows one rule: the machine that owns the target applies the effect. `CombatDirector.deliver()` applies it locally or sends it to the owner, who checks it's plausible first. The host runs the boss, the woodland kin and Oakshire's spirits (and decides parleys and Maker-Seal turns), the gate and the shrine, and tells everyone what happened.
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

The smoke test seats a Tank, Healer and DPS, drives them with scripted input and checks 491 things: the Arsenal (catalog, armor weights, the four weapons, under-card mutations, JSON kits, the Grimoire's rules, card drops, the Four Signs and finishes); the 3x3 Callings (the registry, names, numbers, gear unlocks, the roster, saving by id); Bramble-Bridge (walking over the arch, the layout), the Input Map, hot-join, party caps, the split-screen grid and portals; the Dover-Slap-Falls Expedition (the ramp into Rush-Light-Hollow, Wind-Lanterns, waking and sealing a Hush-Crack and its kin flying off as hedge-wrens, the Water-Shrine, the Wayfarer's Chest, checkpoints, the Gale-Jet, the gate opened by plates, by shelter and the bell, and by a companion on the second plate); the Cross-Grimoire HUD (slots, keys, Sign colours, pip readiness, pulses); the storybook puppets (Calling tabards, capes behind, arms forward) and cel shader; flow-cancels and their windows, hit-stop, all four Sign detonations and their rewards, bow and staff shots, the effect pool, armor in play, strikes crossing the network as ids, Hearth Echo, card invocations and their variants, poise, taunt, Perfect Guard, heals, Lifeline, Shadow Sanctuary, the telegraphs, soak scaling and the Phase 2 Gale-Beam; the Squire auto-evade, auto-guard, ranged picks and Gale-Beam shelter; the Gale-Beam's HUD callout; companions, including the Gale-Beam; the victory, the Cairnsman lulled into a cairn that stays, chest, Chimes, card and Grimoire level; the Chime-Shrine (and old saves' shards) and the Scribe Desk with its Fellowship and Calling rows and hold C; the Phase 11 combat track (the four weapon tiers and their materials, a Level 1 party in timber with un-inked flourishes, the stepping Lights, the winded third Light and the Flow-Link Pulse, the Braced Front Guard, its shove and the Flank Breach, milestones auto-slotting at Levels 2 to 10 with pennants and the Calling unlock, a card's 2x swell, Sign Ring, badge, the R detonation prompt and a 180 ms detonation); Phase 12's Sign-Flow (every Sign's three manifestations and the four Place-Cards, old finish keys, Home-Ground Harmony's 10 s coat and +15 poise, the Glimmer-Spot formulas, the 120-frame Hearth-Rite Tuck that costs no pip and its 1.35x glow and opening strike, a no-wind-up R in the Flow-Link Window with its 2x flare, 110 ms freeze, ring and Ward-Mantle cone, the L Counter-Brace, the Gorge's reach, the 14/18/9-frame windows, Tier 1 kin at 1.25x, the Gale-Bucca's 180-to-120-frame window and rhyme, Bravery Counters up to Old-Hob-of-the-Hill's 525 poise, the Cairnsman's roar, the Squire's buffered counter, charting and gilding at the Scribery with both diamonds refreshing, and the Binder); the Reed-Light Scribery on the square (2.92 m, its prompt and counter, the Tab tap); and no orphaned nodes after Bramble-Bridge, the expedition and back (it uses its own save, never yours). Then `tools/test_world_grid.gd` wakes the party at the Kindle-Fire (round the campfire, facing the lane, warmed to full by the fire), runs one player down the walled lane through Honey-Wick and over the canal bridge (never slowed, ringing the oak's Wind-Lantern, making the square the checkpoint), and walks the party up the seamless world: the grid maths and split-screen union, each chunk's layers and HLOD swaps from (0, 0) to (0, -3), hysteresis on a seam, the 2 ms attach queue, no orphaned nodes after chunks stream out and back, a sealed Hush-Crack, opened chest, resting shrine and open gate surviving an unload and reload, a latecomer's snapshot, and a navigation path across the z = 0 seam. Last, `tools/test_oakshire_vale.gd` checks Oakshire Vale: its size and rings, terrace cliffs too steep to climb and roads gentle enough to walk, its trees, boulders, lanterns and Sign-stones, its 68 townsfolk, four sealed portal aprons and 40 spawners, then walks the party from Wayfarer-Green into the village, through the ford and up to Flagstone-Hollow's barrier. Last of all, `tools/test_mythopoetic_lens.gd` checks the Mythopoetic Lens: the four Linter Rules over every name, blurb, quest and rhyme the game shows, the six-zone atlas, then spirits grown beside the village (a curious hob's 180-frame parley window, the Truce-Sign's 25 Chimes and pip, a soothed hob staying out of fights, a struck hob turning boggart, a padfoot's sea-swallow, an Iron-Man fed a coal and turned right-way up bowing as a steward while one left upside-down sinks to sleep, a spriggan's cairn, the Cairn-Drake's 45-frame Challenge-Roar) and the Chime-Post ribbon and Hearth-Rite border. The adaptive score is checked along the way by `tools/test_adaptive_audio.gd`: the five buses and their effects, every zone's four code-built stems, each place's score up the trail (the Sanctuary Cadence, the sunken lane's depth blend under the Hush-Crack's pre-warm, the water-shrine's oasis, the majority rule), the stations' 3D ambience, the 32-voice pool's cap, cooldown and culling, the four stages on a padfoot, and the Sign chords and their duck; the expedition adds the Cairnsman's Poise-Stagger window, the plate harmony and the gate's fanfare. The storybook world is checked by `tools/test_world_visuals.gd`: the biome, kit and succession catalog, the atelier's texture arrays, the world shaders and their global parameters, the crafted ground and clutter, knee-high walls on LowScenery, ramps at 25° or less, roofs and crowns fading above 3.2 m, 3 km cameras and the horizon ring, low-poly HLODs, a Hush-Crack sealed into a cairn (its bloom, WorldStateDB and the lanterns), a weathering zone, the kit build queue and the Ring's clear floor; then in Oakshire Vale each part's biome and look, every landmark, the Hush-Cracks and Pippin-Green's furrows. Untyped variables, parameters and return values are build errors (`project.godot` sets that), so the check-only loop enforces the static-typing rule.

To see a frame without playing: `godot --path . -- --players=3 --instance=dungeon_dojo --zone=3 --boss-health=0.45 --demo --save=user://shot.cfg --screenshot=/tmp/ring.png --screenshot-delay=9`. For the seamless world with its badge: `godot --path . -- --players=2 --instance=bramblebridge --demo --telemetry --save=user://shot.cfg --screenshot=/tmp/world.png --screenshot-delay=25`.
