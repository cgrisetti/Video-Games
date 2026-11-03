# EVERWOOD (OAKSHIRE RAIDS) — GDD: OAKSHIRE VALE STARTING ZONE
**Authoritative Specification | Godot 4.7 Engine | Post-Phase 10 Baseline**

## 1. Zone Scope & Dimension Architecture
* **Total Grid Footprint:** $1,536\text{m} \times 1,536\text{m}$ ($12 \times 12$ landblock chunks of $128\text{m} \times 128\text{m}$).
* **Playable Floor Area:** $1,280\text{m} \times 1,280\text{m}$ ($2.36\text{ km}^2$ / $0.91\text{ sq mi}$ / $25.4\text{M sq ft}$), surrounded by a $128\text{m}$ perimeter cliff and forest skirt.
* **Traversal Time:** End-to-end traversal takes approximately $3\text{ minutes } 30\text{ seconds}$ at standard player run speed ($6.0\text{ m/s}$).
* **Camera Budget:** Fully optimized for 4-player local split-screen rendering from a canonical $4.8\text{m}$ camera eye-line with a maximum active draw distance clip plane of $192\text{m}$ ($1.5$ chunks).

## 2. Topographical & Concentric Ecological Rings
* **Tier 0 — The River & Mill Basin ($0.0\text{m}$ to $+4.0\text{m}$ elevation):** Shallow wadeable ford ($0.4\text{m}$ water depth triggering wet footstep SFX without movement reduction), bridged by the stone span of the **Bridge-Warden**.
* **Tier 1 — The Settled Meadow & High Road ($+4.0\text{m}$ to $+14.0\text{m}$ elevation):** Undulating pastureland ($5^\circ$ to $12^\circ$ slopes) maintaining unobstructed $4.8\text{m}$ camera sightlines during 5-player melee combat combos.
* **Tier 2 — Bramble-Hollow & Quarry Terraces ($+14.0\text{m}$ to $+32.0\text{m}$ elevation):** Stepped plateau shelves connected by wide natural stone ramps ($4.5\text{m}$ minimum width to prevent camera snagging).
* **Tier 3 — The Rim-Crags & Portal Aprons ($+32.0\text{m}$ to $+65.0\text{m}$ elevation):** Impassable vertical granite escarpments housing the four recessed dungeon and raid portal aprons.

## 3. Artifact & Prop Density Budgets (Per $128\text{m}$ Chunk)
* **Canopy Trees:** $18 \text{–} 28$ (Forest) / $3 \text{–} 6$ (Meadow); minimum $4.5\text{m}$ inter-trunk spacing; foliage canopy starts above $5.5\text{m}$ or fades via proximity shader.
* **Hero Landmark Trees:** 18 total across the zone ($12\text{m} \text{–} 18\text{m}$ trunk girth) marking sub-zone transitions and mini-boss arenas.
* **Boulders & Outcrops:** $4 \text{–} 8$ per chunk ($2.5\text{m} \text{–} 8.0\text{m}$ granite slabs providing hard collision and Line-of-Sight [LoS] cover for ranged enemy volleys).
* **Sign & Wayfinding Props:** Roadside Saffron/Amber Lantern-Poles and Scribe Sign-Stones placed every $75\text{m}$ of roadway to guide players without minimap UI clutter.

## 4. Pinwheel Hub-and-Petal Basin Shape & Streaming Grid
* **Central Anchor:** **Oakshire-Wick** sits on a raised central saddle ($+12\text{m}$ elevation) backed by the Scribe's Tor ridge, occluding $50\%$ of distant horizon views.
* **Five Petal Valleys:** Radiating S-curve roads bend $35^\circ \text{–} 50^\circ$ around rock spurs within $110\text{m}$, ensuring the engine never renders beyond $220\text{m}$.
* **Active Chunk Window:** A $3 \times 3$ active chunk streaming matrix ($384\text{m} \times 384\text{m}$) centered on the party's **Soul Tether** keeps $9 \text{–} 16$ chunks in high detail (LOD0/LOD1) while background hills render as a static horizon mesh ($< 4,000$ triangles).

## 5. Friendly NPC & Offloaded Instance Roster
* **Quest Givers (18 Total):** Grouped into 3-quest hub bundles across Wayfarer-Green, Oakshire-Wick, and 4 outlying petal camps.
* **Service Vendors (14 Total):** Weapon and coat merchants (`Falchion`, `Broad-Axe`, `Rowan Way-Staff`, `Yew Longbow`; Hearth-Linen Coats, Hedgerow Wool-Mantles and Iron-Wood Ring-Coats), apothecaries, Chime-Vault bankers, and Calling Respec tutors.
* **Ambient Guards & Townsfolk (36 Total):** $16$ *Bridge-Warden*/*Hearth-Guard* sentries and $20$ ambient villagers running deterministic idle loops.
* **Offloaded Delve & Raid Portals (4 Total):** every delve is a *-Hollow*, so its name says "go down into it":
  1. *Flagstone-Hollow* (`[D3]` - Lvl 3 Solo/Co-op Delve through a trapdoor under Pippin-Green's orchard, where the Boggart-Kin keep the cellar).
  2. *Iron-Kettle-Hollow* (`[D1]` - Lvl 4–5 5-Player Story Delve in the old bog-iron pits under Quarry-Wick, where the Furrow Iron-Men sleep).
  3. *Star-Barrow-Hollow* (`[D2]` - Lvl 5–6 Spriggan Barrow behind the standing stones of Nine-Stones-Crossing).
  4. *Tangle-Root-Hollow* (`[R1]` - Lvl 6 Capstone 5-Player Family Raid under Bramble-Hollow's petrified oak).

### 5.1 Map-Sense Landmarks (15 GDD §2, Rules 2 & 3)
| Place | Kind | Zone Whose Rhyme It Sings |
|---|---|---|
| **Oakshire-Wick** | The village on the central saddle | Tizzi-Wed-Green |
| **Wayfarer-Green** (south) | Arrival camp, where every road begins | Tizzi-Wed-Green |
| **Pippin-Green** (orchard petal) | Cider rows and Flagstone-Hollow | Tizzi-Wed-Green |
| **Quarry-Wick** (east petal) | Quarry terraces and Iron-Kettle-Hollow | Barley-Bridge-Meadow |
| **Bramble-Hollow** (weald petal) | Thickets, bog-pools and the petrified oak | Rush-Light-Hollow |
| **Nine-Stones-Crossing** (barrow petal) | Standing stones and Star-Barrow-Hollow | Barrow-Crag-Crossing |

Natural features and buildings keep plain names (the Scribe's Tor ridge, the High Road, the Settled Meadow ring, the Bridge-Warden's span, the watermill).

### 5.2 Wildlife & Spirits on the Hob-to-Boggart Spectrum
* **Ordinary animals:** Golden-Fleece sheep and red foxes wander the meadow; they can't be fought.
* **Curious Weald-Wights / Hedgerow-Hobs (`HOB_BENIGN`, `STATE_CURIOUS`):** Bristle-Hobs and Thorn-Tail Hedgerow-Hobs nose round Pippin-Green and the Settled Meadow. Walking within `6.0m` greets a hero with a `180-frame` Truce-Sign parley window: the 1-button Gambit Assist waves the Sign, the hob dances, and the party earns `+25` Chimes and a pip. Strike one and it turns boggart.
* **Awakened First-Quiet Kin (`BOGGART_AWOKEN`), stirred by Old-Hob-of-the-Hill:** Padfoot Boggarts on the meadow and by the river, Furrow Iron-Men on Quarry-Wick's terraces, Bramble-Hobs and Bog-Hulk Boggarts in Bramble-Hollow, Crag-Spriggans guarding the delve gates of Nine-Stones-Crossing, and the Crag-Back Cairn-Drake walking the High Road. They wake within their radius and fight; beaten, they are un-boggarted, never slain. (Wisp-Boggles, Sea-Cave Scrays and the true Cairn-Drakes of the flagship zones wait beyond the vale's rim; 06 §1.1.)

## 6. Build Notes (Oakshire Vale world build)

What the game does today, where it differs from the spec above (and from `13_STARTING_ZONE_ENCOUNTER_DESIGN.md`), and what's still to come.

**In the code now**
- **Its own instance.** Oakshire Vale is the `oakshire_vale` instance (`scenes/worlds/oakshire_vale.tscn`, `src/levels/oakshire_vale.gd`). Since 2026-11-03 it's the game's main scene: every launch arrives here unless `--instance=` names somewhere else (`bramblebridge` for the seamless world, `hub` for the classic hub). The party arrives at Wayfarer-Green in the south petal and walks north over the Bridge-Warden's span into the village.
- **One streaming system, two worlds.** The Landblock streamer of `10_WORLD_ARCHITECTURE.md` now asks a `WorldLayout` for the world's shape: `DoverslapLayout` is the Bramble-Bridge-to-Dover-Slap corridor, `OakshireValeLayout` is the vale. `WorldGridManager.layout_id` picks one. Oakshire uses Terrain3D, 12 x 12 chunks with the corner at (0, 0) and the village at (768, 768). Chunks 1 to 10 each way (100) are walked; the 44 round them are the skirt, with no collision.
- **The rings,** measured from the village as a rounded square: the river basin (bed 0 m, water 0.4 m, floodplain to about 2 m), the Settled Meadow (4 to 14 m), the Tier 2 terraces (three shelves up to 31 m, risers of 57°, too steep to climb), and the rim crags (58 to 62 m, then a 70 m skirt). The village sits on a +12 m saddle with the Scribe's Tor (24 m) behind it to the north.
- **Roads.** Five S-curve petal roads (7 m wide) run out from the village to each petal's camp and portal apron, and the High Road rings the meadow at about 285 m. The roads are the only ramps through the terrace cliffs, at 11.4° at most. A lantern pole and a Scribe Sign-stone stand every 75 m (68 and 67 along 5,154 m).
- **The river** runs west to east south of the village, 13 m wide and 0.4 m deep everywhere, from a waterfall in the west crags to a cave in the east. The Wayfarer-Green road crosses on the Bridge-Warden's span; the Barrow road and the High Road (twice) ford it. Its banks ease to about 9° near each ford, and a road or a camp keeps its own grade beside the river. Wading splashes (the `wade` cue) and never slows you. The watermill stands on its north bank.
- **Props,** placed once per chunk from a fixed seed and drawn as MultiMeshes: 2,918 canopy trees (18 to 28 in a forest chunk, 3 to 6 in a meadow chunk, trunks 4.5 m apart, canopies above 5.5 m), 18 hero trees (trunks 4.4 to 5.8 m across, 26 to 30 m tall, one of them the petrified oak), 877 granite boulders (4 to 8 a chunk, 2.5 to 8 m), plus reeds, flowers and brambles. Trees and boulders have hard collision, and ranged shots stop on them.
- **The horizon** is one baked mesh of 3,200 triangles (the rim, the hero trees, the river ribbon, the waterfall and the cave). The ground is baked every 2 m into `data/landblocks/oakshire_vale/field.res`.
- **68 friendly folk** (`TownsfolkNPC`): 18 quest givers (three each at Wayfarer-Green, the village and the four petal camps), 14 vendors (four weapon smiths, three armourers, three apothecaries, two Chime-Vault keepers, two Calling tutors), 16 sentries (Hearth-Guards in the village, Bridge-Wardens at the span and the camps) and 20 villagers on deterministic idle loops. The village holds 37 of them. A quest giver with a gold ! shows their three quests; a smith or armourer opens the Armory & Scribe Desk at the weapon or armor row, a tutor at the Calling row, a Chime-Vault keeper the Chime-Shrine's upgrades, and an apothecary mends you.
- **Four portal aprons** (`PortalApron`) in the rim crags, each a flat floor at 28 m running into the cliff with a stone arch and a Scribe Sign barrier: [D3] Flagstone-Hollow (Level 3, Warm-Hearth, Pippin-Green, with a trapdoor), [D1] Iron-Kettle-Hollow (Level 4, Iron-Root, Quarry-Wick), [D2] Star-Barrow-Hollow (Level 5, Star-Tide, Nine-Stones-Crossing) and [R1] Tangle-Root-Hollow (Level 6, Rime-Gale, Bramble-Hollow's petrified oak). The barrier lifts when the party's trail level reaches it.
- **The six families** (`Bestiary`, `WildMob`, `MobSpawner`; 13 GDD §2): 40 spawners, 16 fighting variants with the doc's health and poise, 18 to 25 m leashes, 45 to 90 s regrowth and 10 to 14 m pack spacing. Curious Weald-Wights parley or, once struck, fight back; Padfoot Boggarts wake at 10 m and dash; Furrow Iron-Men come in pulls of one heavy, one melee and one ranged, each with an upside-down Maker-Seal; Bramble-Lasher Hobs are rooted; Crag-Spriggans guard the aprons. The Crag-Back Cairn-Drake (2,500 HP, 150 poise) walks the High Road with a bell-stomp and wakes with a 45-frame Challenge-Roar. Every spirit pays trail XP when it's un-boggarted.
- **The Hob-to-Boggart Spectrum** (`HobSpectrumComponent`, 15 GDD §7) is on every one: the parley, turning boggart, the three un-boggartings (a sea-swallow or hedge-wren flying off, a mossy cairn, a bowing steward) and the Maker-Seal. Walking into a petal also unfurls its zone's nursery rhyme on the Chime-Post ribbon (§5.1).
- **Getting about.** Walking into a petal names it on your screen, with what lives there. Walking into the village or a camp makes it where you get back up. If a respawn or a jump lands where the ground hasn't streamed in yet, it loads at once rather than letting you fall.
- **Rebuilding.** `tools/build_oakshire_vale.gd` bakes the field and horizon, writes the scene and the 44 landblocks that hold buildings and folk, and their HLOD proxies. `tools/test_oakshire_vale.gd` (run by the smoke test) checks the layout, the dressing, the landblocks and a walk through the vale.
- **Measured.** Four players split-screen at 1600 x 900 on an Apple M5, spread over the village, the Wayfarer-Green road, Bramble-Hollow and Quarry-Wick and walking for 20 s: 110 fps on average (9.1 ms a frame), 82 fps at the 1% low, and 8 frames of 2,206 over 16.7 ms (chunk streaming, 25 ms at worst).

**Deliberate differences from the spec**
- **GDScript only.** The brief named a C# and GDScript hybrid; the engineering contract (`CLAUDE.md`) is strict GDScript.
- **The 192 m budget** is read as fog and streaming, not a hard clip: props stream in within two chunks and fog thickens past them, but the camera sees 3 km like every level (Phase 17), so the rim, the horizon mesh and the HorizonVistaRing beyond still show.
- **The active window** is the streamer's own rings round every player (gameplay within one chunk, props within two, HLOD within three), not a fixed 3 x 3 on the Soul Tether. With four players spread out, more chunks are live.
- **Ramps.** The terraces' only ways up are the 7 m roads, rather than separate stone ramps.
- **The sheep and foxes** are ambient critters (`AmbientFlock`) that wander and can't be fought.
- **Dungeons are offloaded.** An open portal says its delve is still being scribed; the instances aren't built.
- **No quest log yet.** Quest givers show their quests; nothing tracks them.
- **No navigation mesh in Oakshire.** Baking full Oakshire chunks starved the worker threads, so creatures and companions walk straight at their target.

**Still to come**
- Travel between Bramble-Bridge and Oakshire Vale.
- The quest log, and the four dungeon instances behind the aprons.
- Navigation along the road bands, so creatures path round cliffs and boulders.

## 7. Build Notes (Phase 17: the storybook vale)

`17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md` §5.1 and §8 in the vale:
- **Each part wears its biome** (`OakshireVale.visual_biome_at()` from `OakshireValeLayout.region_name_at()`): Oakshire-Wick in the village and the Settled Meadow, then Wayfarer-Green, Pippin-Green, Quarry-Wick, Bramble-Hollow and Nine-Stones-Crossing. The sky, sun and fog ease to it as the party walks, and each landblock grows its biome's clutter.
- **Oakshire-Wick:** ten stepped-gable kit houses (House0 is the Oakshire Homestead Hall, with its wing and porch), the Kindle-Fire ring (river stones, a tripod kettle and travel packs), the Armory & Scribe Desk pavilion and the Chime-Shrine pagoda as landmarks, seven cedar hives along the east woodline, two pumpkin patches inside knee-high walls open toward the green, and a Chime-Post on the road south. The mill is a stepped-gable mill house with its race.
- **The petals:** Wayfarer-Green's windmill with turning sails and two sheep-stiles; Pippin-Green's cider mill, barrels, walled orchard of fruit trees and plough-furrow strips in the field; Quarry-Wick's two pulley-cranes, three ashlar stacks with Iron-Root marks, cairns and rusty gravel roads; Bramble-Hollow's three willow pools, hanging Wind-Lanterns and a Water-Shrine; Nine-Stones-Crossing's nine standing stones with Star-Tide spirals, the Threshold Bell-Frame, a flagged causeway and heather. Every camp has a Chime-Post singing its petal's rhyme. Wayfarer-Green's roads are chalk.
- **Hush-Cracks** sit under Bramble-Hollow's five briar packs, the outlaws' camp and the four barrow-wight packs (10 in all): sealed while the whole pack is beaten, quietly open again when one regrows.
- **The river and the falls** run in the storybook water shader; the meadow's trees are trunks with roots under leaf-cloud crowns, the boulders and Sign-stones crafted granite.
- **Not done:** the Furrow Iron-Men standing in Pippin-Green's furrows (creatures, a later pass), and §5.1's petal-to-zone pairing, which differs from the game's atlas (see doc 17 §8).

