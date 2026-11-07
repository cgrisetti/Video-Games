# 27 · Embershore, Zone 1, in the engine (Master v2)

> **Asked for (2026-11-07):** build Embershore, the starting isle, from the Creative Director's *Everwood — Embershore* Master v2 (council second pass and master map) in the engine, feature by feature, with the generator as the one source of truth.
> **Scope:** `games/everwood` only. The starting isle (`isle_embershore`, once Oakshire Holm, then Miller's Oak) and whatever it touches: the grid resource, the atlas, the streamer, the map, the sea, the water shader, the world state, the camera, the Binder. The other four isles are unchanged but for their seam ends.
> **Numbered 27:** the brief asked for `docs/15_EMBERSHORE_MASTER_V2.md`; 15 is the Mythopoetic Lens, so this is 27.

## 1. One source of truth

`tools/worldgen/embershore_gen.py` is the brief's Appendix A, saved verbatim. Run from `games/everwood`:

```bash
tools/worldgen/.venv/bin/python tools/worldgen/embershore_gen.py world/embershore/gen 7
```

It needs Python 3.12 with numpy 2.5.3, scipy 1.18.1, scikit-image 0.26.0 and Pillow 12.3.0 (`uv venv --python 3.12 tools/worldgen/.venv`, then `uv pip install` those). With seed 7 its output matches Appendix B to the centimetre (drift 0.00 m). It writes `world/embershore/gen/`:

| File | What |
| :-- | :-- |
| `terrain.jpg`, `vectors.json` | the master map and its vectors, for people |
| `engine/embershore_height_f32.raw` | 2049 x 1025 little-endian float32 heights at 1 m, row 0 north |
| `engine/embershore_height_u16.png` | the same as 16-bit grey (Y = v / 65535 · 120 − 20) |
| `engine/mask_*.png` | land, moss_oaks, road, river, cliff, beach, rain_shadow_dry at 1 m (2048 x 1024) |
| `engine/embershore_features.json` | every landmark, path, river, bridge, tree, house, field, sea stack, sleeper, causeway, skiff lane and trigger, in metres |

A `.gdignore` keeps Godot from importing the folder; `EmbershoreBuilder` reads the files with `FileAccess`.

**Frames.** The generator's origin is the north-west corner (X east, Z south, Y up, sea at 0). Every Caldera isle is centred on its origin, so the island's frame is `local = generator − (1024, 512)` (`EmbershoreBuilder.to_local`). Embershore sits at `sound_position (0, 1850)`, 1,850 m south of The Crown, so its 2:1 grid clears the outer isles'.

## 2. The island

- **Grid:** 2,048 x 1,024 m, 16 x 8 landblocks of 128 m. `IslandGridResource.chunks_z` makes a grid rectangular (0 keeps it square); `grid_size()`, `half_size()`, `chunk_min_z()`, `chunk_max_z()`, `contains_point()` take either. The layout, the map baker, the map panel and the streamer loop per axis.
- **Ground:** `EmbershoreBuilder._base_height` reads the heightmap bilinearly; past its edge the sea floor is −14 m. Three levels of detail (`lod_quads()` = 128, 64, 32 quads a landblock): 1 m in the 3 x 3 window round the party, 2 m in a ring two landblocks round it, 4 m far stand-ins over the whole island. `collision_resident()`: every landblock's `HeightMapShape3D` is built the moment the island is live, straight from the 1 m data (`collision_heights_for`), and stays; trunks and stones add their solids as the window reaches them.
- **Coast:** the heightmap's own (`has_organic_coast()` false, no `_coast_shape`). The five sea stacks are in the heightmap (34 to 44 m).
- **Paint:** `_ground_color` from the masks: ash-loam under dry golden turf in the northern rain shadow and lush green south, moss and leaf litter under the Moss-Oaks, silt and pebbles in the river beds, ochre-and-grey banded tuff on the cliffs, pale sand in the northern coves, shingle at Bramblemouth and on the Eel Spit. The ground shader draws the roads per pixel over it (docs/26).
- **Paths:** the seven generator roads (`lane`, `hollow`, `gate`, `coast`, `downs`, `strait`, `eel`) are laid as drawn (`add_path(points, half_width, false)`: rounded only, never re-routed, their beds already in the heightmap). Cobbled within 70 m of Bramblebridge's and 95 m of Hearthstead's middles (`road_surface_at`), packed earth everywhere else.
- **The sea** (`caldera_sea.gdshader`): reads the ground under it; pales to the shore colour over the beaches (3.5 m), breaks lines of surf that fade 2.6 m out, laps with foam against sand, rock, the pier and the stacks; keeps the three currents, the Star-Tide bleed and the seam mist. The Ebb drops it to −6 m (`ebb_unlocked`, the brief's `world.ebb`); the Old Quay platform at −4.5 m is bared and walkable (its collider is resident).
- **The Deep-Hush** (`EmbershoreWater._build_seal`): a standing haze curtain along the generator's `boundary_seal` line on the south-east edge, humming a low drone. No wall: `EmbershoreBuilder.beyond_seal()` marks the far side within 160 m, and `CalderaArchipelagoWorld._tide` turns a party there back the way deep water does ("The Deep-Hush turns you back").
- **Deep water:** `DEEP_WATER` is 0.9 m (was 1.3): feet that deep for 1.2 s and the tide carries the hero back to their last dry footing.

## 3. The water

- **Rivers** (`EmbershoreWater.river_ribbon`): the Bramble (326 points) and the Dover (349) as triangle strips along the generator's centrelines, the surface 0.6 m over the bed, each ribbon 0.8 m wider than the river so its edge hides under the bank, UV.x across and UV.y along in metres. The stream shader's new `along_uv` mode runs its ripples down the ribbon at `flow.y` m/s (0.7), so the water follows every bend. Both run downhill all the way (`is_monotonic`; the Bramble 9.48 → −0.28 m, the Dover 18.45 → −0.63 m) and stop where the surface is under 0.15 m (the sea's). A trickle every 90 m.
- **Springs:** stone-rimmed pools at the Bramble Spring (−88.75, 9.45, 177.49) and the Dover Spring (88.75, 18.22, 146.77), trickling.
- **The weir:** a dark-stone sill across the Bramble at (−453.41, 6.13, 212.28), abutments on the banks, white water over its downstream lip; the Root-Sanctum's way out is the arrival beside it.
- **The mill race:** a kerbed stone leat along the generator's `mill_race` line to the watermill, its water lying on the ground as laid (see Assumptions).

## 4. The land

- **The Ariundle Moss-Oaks:** the generator's 1,308 sessile oaks stand where it put them (`_scatter` override, bucketed by landblock; canopy radius / 2.9 as the oak stand-in's scale), with ferns, mossy boulders and stones beneath, hazel (ash stand-ins) and rowan at the wood's edge.
- **The Elder Oak** at (−189.44, 15.16, 167.25): a 30 m moss-oak kit over a solid trunk; its roots arch over the Root-Sanctum's door at (−146.77, 13.85, 233.81) (`RaidPortal` into the Root-Sanctum instance).
- **The Heirloom Orchards:** 94 apple trees from the generator. **Grain:** 120 ripe strips (`grain_field_rows`), no collision.
- **Edges:** gorse and heather above 28 m (new species `GORSE_BUSH`, `HEATHER_CLUMP`; `ROWAN_TREE` too), willows and reeds by the rivers, stones on the cliffs. The meadow thins to half in the rain shadow and to 30% under the oaks.

## 5. Settlements and landmarks

| Place | What stands there |
| :-- | :-- |
| **Bramblebridge** (Lv 1–2) | 12 cottages (the first the inn), the start chime-post on the green (the party spawns facing the bridge), the single-arch stone bridge from the lane's first point over the Bramble to the Downs road's end (a 45 m sloping deck, parapets, the arch over the water, piers under the approaches), the watermill (stepped-gable mill house, undershot `WatermillWheel` in the leat), the wright's yard (timber stacks, bench), the cold smithy (no fire) |
| **The Ariundle Moss-Oaks** (Lv 2–3) | the Moss-Oaks chime-post, the Elder Oak, the Root-Sanctum's arch and portal, the two springs, the weir |
| **The Sunken Holloway** (Lv 3–4) | the sunk lane as the generator carved it, over the rim shoulder (37.74 m) |
| **Doverslap Gorge** (Lv 4) | the three-arch bridge (51 m, deck 25.88 m, the gorge floor 9.08 m), the gatehouse (an arch over the road, two squat towers with timber hoardings, a lamp and a hearth), the Doverslap chime-post, the reveal |
| **The Coast Road** (Lv 4–5) | Seal Cove and Sunward Cove (signs, rocks), the Eel Junction |
| **Hearthstead** (Lv 5) | 12 cottages, the market (two pavilions, four vendors, the three lane stalls that open with the Beacons), the Scribe table (a `ScriberyStation` on the terrace), the chime-post, the quay stair (two timber flights hung on the 20 m bluff down to the pier) |
| **North Quay** | the timber pier (8 m wide, 30 m out, deck 1.6 m) and its head with the Salt Road and Crown Landing skiff bells and moored skiffs; the party arrives on the deck; the Old Quay (−4.5 m) beside it |
| **Mill-Downs** (Lv 5) | the windmill (and its silhouette from every other isle), the Downs Gate |
| **The First-Quiet** | six sleepers on the south-east crags (curled megaliths), the Deep-Hush beyond |
| **Causeways** | the West Strait (from the west tip, 1.86 m) and the Eel Spit (shingle, 4.77 m), gated by `root_sanctum_cleared` |

**The Doverslap reveal** (`DoverslapReveal`, `PlayerCamera.reveal`): the first time each hero steps within 6 m of the bridge's middle, their own camera eases up and back for 4 s (the field of view widening 14°) to look over the Sound at The Crown's World-Tree, Rime-Firth west of it and Barrow-Eyot east, then eases home; a banner names them. Once per hero (by class) per save (`PartyProgress.reveals_seen`, `[caldera] reveals`), never mid-fight, each split-screen viewport its own.

**Chime-posts** (four: Bramblebridge, the Moss-Oaks, Doverslap, Hearthstead) are checkpoints (`ChimePost.checkpoint`: ringing one makes it where that hero gets back up) and card-loadout stations: in the Caldera, the Grimoire Binder opens anywhere to read, but `_equip` and `press_seal` are refused more than 14 m from a checkpoint post ("Cards and gear change at a chime-post: ring one first").

## 6. Progression and flags

| Flag | Set when | Effect |
| :-- | :-- | :-- |
| `wheel_stopped` (new, bit 8) | a party of Lv 5 or more comes within 60 m of the mill | the mill-wheel stops; banner "THE MILL-WHEEL STOPS" |
| `root_sanctum_cleared` (bit 0) | the Root-Sanctum (the Dojo instance) is cleared | the wheel turns again; the West Strait, Eel Spit and Salt Road open; the trade lanes go dark |
| `downs_gate_open` (new, bit 9) | a party member stands within 6 m of the Downs Gate on its Hearthstead side | the gate swings open and stays open (`OneWayGate`) |
| `ebb_unlocked` (bit 7; the brief's `world.ebb`) | the Harmonic Bell | the sea falls to −6 m: the Old Quay is bared |

The world state keeps docs/20's eight booleans first, in their save bits, then these two. `ISLE_OAKSHIRE_HOLM`, `ARRIVE_ORCHARDS` and `--boot-zone=oakshire` remain as aliases of `ISLE_EMBERSHORE`, `ARRIVE_START` and `embershore`, so old code and saves still find the isle.

**Encounters** (docs/13 §2 by stage, `EmbershoreBuilder.ENCOUNTERS`, 15 packs 18 m off the paths, grown as their landblock streams in): Curious Weald-Wights in the orchards (Lv 1–2, with Old Tusk), Padfoot Boggarts in the Moss-Oaks and by the Bramble (Lv 2–3, a Frost-Fang), Furrow Iron-Men in three-spirit pulls on the Holloway and the rim (Lv 3–4, the Plough-Giant), Bramble-Hobs on the Coast Road with a Bog-Hulk at Seal Cove (Lv 4–5), Crag-Spriggans on Mill-Downs with the Barrow-Bell (Lv 5), and a briar guard at the Root-Sanctum (Lv 6).

## 7. Atmosphere

- **Light arc:** each stage wears a biome's sky and fog (`CalderaArchipelagoWorld.EMBERSHORE_BIOMES`): Oakshire-Wick for Bramblebridge and the orchards, Moss-Oak Hollow under the oaks, Rush-Light Hollow in the Sunken Holloway, Dover-Slap Falls on the rim, the gorge, the south cliffs and the First-Quiet crags, Gull-Wick Haven on the Coast Road and its coves; Hearthstead, Mill-Downs and the quay keep the isle's own.
- **Weather:** the rain shadow is painted in (dry golden north, lush south); there is no dynamic weather system in the engine, so none was added.
- **Sound:** `millers_holm`, the mill-wheel mosaic (now "Embershore's Mill-Wheel Mosaic"), plays over the isle; trickles along the rivers, at the springs, the weir and the wheel; hearth fire at Hearthstead's market and the gatehouse; the Deep-Hush's drone.
- **Impostors:** from the other isles, Embershore stands on the horizon with the windmill's silhouette on Mill-Downs; the far stand-ins are 4 m, the mid ring 2 m.

## 8. Checks

`tools/test_embershore.gd` runs inside `tools/test_caldera_isles.gd` (so in the smoke test and `tools/run_caldera_checks.gd`), eleven checks: the grid and data (16 x 8, three LODs, 128 resident colliders, the heightmap and masks, 29 landmarks, the trees standing); every landmark's table height is the ground's within 0.25 m; the corridor is 2,658 m from Bramblebridge to Hearthstead and crosses the Dover only on the Doverslap bridge; both rivers run downhill 0.6 m deep with their springs, weir and race; the settlements and landmarks stand; deep water and the Deep-Hush turn the party back; the wheel and the Downs Gate follow their flags; the reveal plays once per hero and never mid-fight; cards change only at chime-posts; and nothing invisible blocks the way (every solid shape has a mesh about it).

Screenshots of the seven stages, the orthographic plate beside `terrain.jpg`, and the four-player performance table come from a windowed run of `tools/embershore_screenshots.gd` (it writes `docs/images/embershore/`): `01_bramblebridge` to `07_mill_downs`, and `00_ortho.jpg`, the island from straight above, which lines up with `world/embershore/gen/terrain.jpg` (coast, gorge, stacks, forest, grain strips, the two causeway lines).

**Four-player split-screen, 1920 x 1080, Apple M5 (2026-11-07, `docs/images/embershore/perf.md`):**

| Stage | FPS | process ms | physics ms | draw calls | primitives | near / mid / far landblocks |
| :-- | --: | --: | --: | --: | --: | :-- |
| Bramblebridge | 58 | 15.5 | 2.8 | 7,957 | 7.6 M | 12 / 19 / 128 |
| the Moss-Oaks | 38 | 23.6 | 2.8 | 2,882 | 22.3 M | 14 / 23 / 128 |
| the Sunken Holloway | 65 | 15.5 | 2.1 | 1,714 | 4.3 M | 9 / 21 / 128 |
| Doverslap bridge | 74 | 13.7 | 1.9 | 1,458 | 4.0 M | 11 / 20 / 128 |
| the Coast Road | 55 | 17.1 | 2.0 | 7,978 | 6.5 M | 12 / 17 / 128 |
| Hearthstead | 67 | 15.1 | 1.7 | 5,372 | 6.4 M | 12 / 23 / 128 |
| Mill-Downs | 65 | 15.5 | 2.5 | 3,000 | 5.3 M | 14 / 30 / 128 |

The Moss-Oaks are the heavy stage: four cameras inside 1,308 sculpted oaks draw 22 M triangles a frame (the atelier oak within `CalderaKit.ATELIER_RANGE` of any camera). A density-aware stand-in range for the oaks is the next step if 60 is wanted there with four players.

## 9. Assumptions (where the brief was silent)

1. **Numbering:** this doc is 27, not 15.
2. **Causeway decks** are level shore to shore at Embershore's head heights (West Strait 1.86 m, Eel Spit 4.77 m); Iron-Ness's and Barrow-Eyot's arrival pads rise to meet them.
3. **North Quay** lies at the foot of Hearthstead's 20 m bluff (the heightmap drops from 14.8 m at z −230 to the −4.5 m platform at z −245). The party arrives on the pier head's deck; the quay stair is how you walk down.
4. **The mill race** isn't graded by the generator (its ground runs 5.6 → 11.7 → 7.4 m from weir to mill), so the leat is drawn along the line on the ground as laid.
5. **River mouths** end where the surface is under 0.15 m; at the Ebb their last metres show bed.
6. **The reveal's "per player"** is per hero class in the save (player ids change between sessions).
7. **The wheel's "Lv 5"** is the party's trail level, read when a party member comes within 60 m of the mill (a global check flipped it at boot for an endgame test party).
8. **The Downs Gate** opens on approach from the Hearthstead side at any level (Lv 5 is the stage's level, not a lock).
9. **The Deep-Hush** hums with the `gate_drone` ambience (the kinds available: hearth_fire, water_trickle, carillon, gate_drone, gate_counter).
10. **Hazel** has no species of its own; ash stand-ins mark the wood's edge with rowan.
11. **Encounter spots** are fractions along each road, 18 m to one side, never in a river.
12. **Cottages and packs** were built in the water phase (3) rather than 5 and 6 so the map and badge checks stayed green at every commit.
13. **Sea stacks** are terrain (the heightmap raises them 34 to 44 m); no separate meshes.

## 10. Conflicts (the brief wins; noted)

- **docs/08's ruling "Miller's Oak = starting isle"** against the brief's "Embershore": the isle is Embershore; the old ids stay as aliases.
- **docs/20's Musk Razor "eight booleans, nothing else"** against the brief's `wheel_stopped` and `downs_gate_open`: ten booleans now, the eight first.
- **docs/20's and docs/14's 12 x 12 grids for every isle** against the brief's 2:1 island: Embershore is 16 x 8; the Atlas notes in both ask whether all isles should follow.

## 11. Gaps

- The Root-Sanctum is still the Dojo instance (its own dungeon isn't in this brief).
- The Crag-Back Cairn-Drake has no road to walk on Embershore (docs/13's High Road is the Vale's); not placed.
- Legacy mentions of Miller's Oak in docs 23 to 26 are left as history.
