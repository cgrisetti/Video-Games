# 33 · A sense of place: what Everwood takes from four open worlds

> **Asked for (2026-11-09):** take nine recommendations drawn from *Red Dead Redemption 2*, *Ghost of Tsushima*, *Horizon* and *The Witcher 3* (beauty, wonder and a sense of place), analyse each one thoroughly, analyse Everwood's own zone, island, quest and lore guidance, and apply directly the ones that fit and harmonise, keeping to the Musk Razor.
> **Scope:** `games/everwood`, the Caldera Isles. Built on top of [docs/32](32_EMBERSHORE_THE_WORKED_LAND.md) (branch `everwood/sense-of-place`, cut from `everwood/embershore-lived-in`). Embershore's ground, roads and landmarks don't move.
> **In one line:** Everwood already had most of what makes those worlds feel like places. What it lacked was the Friction Isles each looking like *themselves*, distance that sits in its sky, and the Beacons showing from home. Those three are built; the rest are kept, cut or written down as rules for the next isles.

## 1. The verdicts at a glance

| # | Recommendation | Verdict | In the build |
| :-- | :-- | :-- | :-- |
| 1 | One landmark always in view | **Kept, plus 10%** | The World-Tree was already law. Added: a lit Beacon burns on its isle's far silhouette, seen from every quay (docs/14 §6.4, never built until now). |
| 2 | Guidance in the world, not the HUD | **Kept; the guiding wind cut** | The quest tracker, the firefly trail and the fingerposts already do it. A quest-seeking wind would break the Breach's geography and the Frozen Wind's meaning. |
| 3 | A signature colour field per isle | **Built** | Iron-Ness rust bracken, Barrow-Eyot heather and sea-lavender, Rime-Firth cotton-grass, each from its rock and leaning to its Sign, seen first from across The Sound. |
| 4 | Light as the main character | **Built; the day cycle cut** | Each Friction Isle wears its own light (sun, sky, fog), The Crown's shores take on the isle each faces, and the far isles fade into the sky behind them. |
| 5 | Weather you can see coming | **Cut, with 10% back** | No weather system. Each isle's air is its weather (fen mist, sea-fret, forge haze), and the First-Quiet is the front you see coming. |
| 6 | Composed views | **Kept; a rule for the next isles** | The Doverslap reveal and the Chime-Post rhymes already do it. A second reveal at North Quay would repeat Doverslap's view. |
| 7 | Places that look lived in | **Kept** | docs/32 built it. |
| 8 | A world that reacts | **Kept** | The hush, the bloom, the swallows and the shy stock already do it. Birdsong needs recorded sound (a call, §8). |
| 9 | Restraint | **Kept; a rule for the next isles** | No minimap or quest arrows in the Caldera; half the valley left open. |

## 2. The guidance each one answers to

- **The Musk Razor** ([docs/01 §3](01_VISION.md), [docs/08 Gate 2](08_EVERGREEN_DEV_BIBLE.md)): cut so deep you have to add 10% back. No new button, menu or system where an existing one does the job. In world terms ([docs/14 §1.2](14_EVERWOOD_WORLD_MAP_BIBLE.md)): no extra seams, tunnels, towns or ferries; few flags; reuse.
- **The other gates:** Gate 1, every addition feeds two pillars (here the Four Signs and the Callings, and the Chimes economy through the trade lanes). Gates 3 and 6, no new names a child can't say. Gate 4, data as typed resources in a catalog. Gate 5, code-first, with 3.2 m sightlines.
- **The Caldera's nine laws** ([docs/14 §2.2](14_EVERWOOD_WORLD_MAP_BIBLE.md), [docs/20 Part I](20_CALDERA_ATLAS_AND_CROWN_BIBLE.md)), above all Law 1 (one Breach, the north-west gales), Law 2 (The Crown seen from every quay), Law 3 (biomes from rock and exposure, not latitude), Law 6 (sheltered inner shores, wild outer shores) and Law 7 (one Beacon, one flag, three effects).
- **The Lens** ([docs/15](15_THE_MYTHOPOETIC_LENS.md)): one origin, the First-Quiet, whose mark is colour, warmth and wind drained out of the world. Every zone has a rhyme, sung at its chime-posts.
- **The palette contract** ([docs/17 §2.3](17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md)): ground stays mid-value (35-65% luminance), never neon, so a four-year-old reads every telegraph ring on a split screen.
- **The generator is the truth** ([docs/27 §1](27_EMBERSHORE_MASTER_V2.md), [docs/32 §1](32_EMBERSHORE_THE_WORKED_LAND.md)): Embershore's ground, roads, rivers, landmarks and chime-posts are where its scripts put them.
- **The budget** ([docs/27 §8](27_EMBERSHORE_MASTER_V2.md)): four players in split-screen; the Moss-Oaks run at 49 FPS. Colour, light and placement are free; geometry and new systems are not. That is also how Ghost of Tsushima did it.

## 3. The nine, one by one

### 3.1 One landmark always in view

**The four games.** Horizon's Tallnecks, Tsushima's Mount Jogaku, the Grizzlies over RDR2's plains and Novigrad's skyline: one tall thing that tells you where you are, and that the story changes.

**What Everwood has.** This is already law. Law 2 puts The Crown and the World-Tree in sight from every quay "from minute one". Docs/23 makes the tree the Caldera's one global focal point, in sight from every step of the Ring Path. Each isle has a landmark silhouette that reads from North Quay (Windmill, Forge Stacks, Bell-Tower, Snow Peak). The story changes the tree: each trial blooms a bough, and the far silhouette shares the live tree's material, so a bloom shows from every quay the moment it happens. The first sight is staged: the Doverslap reveal at Level 4, and the opening film now hands over facing away from the tree (docs/31), so that sight is earned.

**What was missing.** Docs/14 §6.4 asks for each Friction Isle's Beacon flame on its far silhouette, lit when its flag is. It was never built: lighting a Beacon changed the sea's currents and Hearthstead's stalls, but nothing showed on the isle itself when you looked back at it.

**Verdict: kept, plus 10%.** A lit Beacon now burns on its isle's far silhouette (`FarBeacon`). There's a pale tower where the Beacon stands, a fire in the Beacon's own colour on top, and a column of smoke leaning with the Breach's wind. By day a beacon reads by its smoke. From any quay the party sees which isles they've brought back, and the next one stays dark. It adds no flag: it's the visible face of Law 7's flag. It feeds Gate 1 twice: the fire is the isle's Sign colour, and a lit fire means its trade lane (the Chimes economy) is open. It costs one glow and fourteen puffs per lit isle.

**Cut:** bending roads to frame the tree. Embershore's roads are the generator's (docs/27 §2).

### 3.2 Guidance in the world, not the HUD

**The four games.** Tsushima's Guiding Wind (swipe the pad and the grass bends toward your goal), Horizon's painted handholds, the Witcher's signposts.

**What Everwood has.**
- No minimap and no quest arrows in the Caldera (docs/20 Part III, Phase 5).
- The quest tracker says what to do next and where, with an arrow that turns with the camera (docs/29 §7).
- Pinning a place on the Atlas sends a firefly trail ahead of the hero (docs/18 §7.3).
- Fingerposts stand where a track leaves a road, naming its steading (docs/32 §3).
- There's no climbing system to paint for: heroes walk up to 50° ground, and docs/18 §3.2 already makes walkable and blocked ground read differently.

**Verdict: kept; the guiding wind cut.** Three reasons:
1. The Caldera's wind is weather with a cause. Law 1's Breach sends the gales from the north-west, the world wind blows from there, and the smoke leans with it. A wind that turns toward quests would break that.
2. Stillness is the First-Quiet's tell. Inside a hush the grass lies flat and still (the Frozen Wind, docs/18 §5). If wind also meant "go this way", no wind would stop meaning danger.
3. It would be a third guide on top of the tracker and the fireflies. Under the razor, that one goes.

Nothing was added.

### 3.3 A colour field per isle

**The four games.** Tsushima gives each region one mass of colour (red maples, white pampas, yellow ginkgo) that you read from a mile away before a name shows. Toussaint looks nothing like Velen; Horizon's biomes change colour as they change climate.

**What Everwood has.** Embershore has one already: ripe barley, the dry golden north under its rain shadow, and the orchards, all in Warm-Hearth gold (docs/27 §2, docs/32 §4). The Crown has its gold tree and its violet-stained grottos. The three Friction Isles were all green, under borrowed Vale skies (docs/20 Part III §2.9). From North Quay they read as three green humps.

**Verdict: built.** Each Friction Isle grows one colour field. The plants come from its rock and exposure (Law 3), and the colour leans to its Sign (Gate 1: the Four Signs, and the Calling whose home it is):

| Isle | Rock and exposure (Law 3) | Sign and Calling | The field | The meadow underfoot | The wildflowers |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **Iron-Ness** (W) | hydrothermal ironstone, over-delved mines | Iron-Root amber · Shield-Sworn | rust bracken over an olive ironstone heath, rustier the higher it climbs | tall, bronze to the tip | gorse-gold buttercups half the drifts, a few ember poppies |
| **Barrow-Eyot** (E) | a sunken stretch of the rim gone to tidal fen | Star-Tide violet · Lantern-Bearers | heather and sea-lavender on the barrows, tawny reed-beds by the water, fen green between | tall reeds below 2.2 m, short heather above | sea-lavender blue (cornflowers) two drifts in three |
| **Rime-Firth** (N) | the high basalt rim facing the Breach, snow and sea-fog | Rime-Gale azure · Wayfarers | pale cotton-grass over a grey-green moor, snow on the peak | cropped short by the gales, pale to the tip | cotton-white daisies and cow parsley |

The field is in the plants, so it shows in two ways. **From afar** the far silhouettes (`far_color`) paint each isle as its plants en masse: rust, heather or cotton. **Underfoot** the ground stays turf, with a lean toward the field (bronze-olive, sage, pale moor), and the meadow's tips and wildflower drifts carry the colour.

The first build painted the field into the ground itself. The ground shader reads a painted colour as a material (green is turf, warm is loam or sand, grey is rock), so rust and mauve ground rendered as flat, near-neon bare earth: see the pictures in `docs/images/sense_of_place/`. A check now holds the ground underfoot to turf.

Every colour stays mid-value and never neon (docs/17 §2.3). It costs nothing: it's all colours and shares, with no new meshes.

### 3.4 Light as the main character

**The four games.** RDR2's long sunsets and god-rays, Tsushima's golden hour, and in all four, distance that goes blue and pale in layers.

**What Everwood has.**
- One fixed sun, south-south-east and 48° up, and no day cycle.
- Embershore's light arc (docs/27 §7): each stage of its corridor wears a biome's sky and fog.
- The Friction Isles borrowed the Vale's Quarry-Wick, Nine-Stones-Crossing and Gull-Wick-Haven skies.
- The far silhouettes faded with distance toward one fixed grey-blue, whatever sky stood behind them. Under Embershore's cream horizon they looked pasted on.

**Verdict: built; the day cycle cut.**
- **Each Friction Isle wears its own light**, from its rock and its Sign, as a new biome in `WorldVisualCatalog` (Gate 4):
  - **Iron-Ness:** a warm amber haze, from forge smoke and steam vents (sun warm, horizon amber, fog 0.0024).
  - **Barrow-Eyot:** a soft lilac light through fen mist (horizon lilac, fog lavender-grey 0.0042, the mistiest).
  - **Rime-Firth:** a crisp, cold azure morning (the bluest sky, the coldest sun at 1.28, sea-fret 0.0034).

  Their names are the isles' own, so no new names are added.
- **The Crown's shores take on the isle each faces.** Docs/20 Part II's rule 4 already says each shore "takes on the rock and current of its facing outer island". Now it takes that isle's air too: the Iron Shore wears Iron-Ness's haze, the Gale Cliffs Rime-Firth's morning, the Tide Grottos Barrow-Eyot's mist. The level reads it from the atlas, so the two can't drift apart.
- **The far isles fade into the sky behind them.** The silhouettes now fade toward the sky's own horizon colour, a quarter of the way toward its blue, and the Atmosphere updates that every frame. Distance reads as layers of air, and each isle's own light carries out to the isles it sees.

**Cut:**
- **A day and night cycle.** It would be a system, and night would cost readability: a four-year-old on a quarter of the screen, telegraph rings at dusk, every shader's lighting. Docs/32 also sets the year: it's always the week of the Great Autumn Feast.
- **A sun angle per isle.** Docs/32 placed every steading facing the SSE sun.

Lowering the sun for every isle is a call for the Creative Director (§8).

### 3.5 Weather you can see coming

**The four games.** RDR2's storms rolling over the plains, the Witcher's wind-bent trees before a squall.

**What Everwood has.** No weather system. There are cloud shadows drifting over the land (docs/18 §4.4) and a weathering state the Atmosphere can already put a biome in (docs/17 §2.2). The Deep-Hush is a standing haze curtain on Embershore's south-east edge (docs/27 §2), the Star-Tide's violet bleeds into the eastern sea, and a Breach Gale blasts the Gale Cliffs' trial.

**Verdict: cut, with 10% back.** Rain, storms and wet surfaces in four viewports are a large system for a small family's living room. The game already has its front you see coming: the First-Quiet. The grey on the sea, the Deep-Hush curtain, the colour draining out ahead of a crack. The 10% back is that each isle's air is now its weather, in its own biome: Barrow-Eyot's fen mist (fog 0.0042), Rime-Firth's sea-fret (0.0034), Iron-Ness's forge haze (0.0024), against Embershore's clear lee-shore air (0.0008).

### 3.6 Composed views

**The four games.** Tsushima's haiku spots and hot springs: you sit, and the camera finds a composed view. Vista points in Horizon and the Witcher.

**What Everwood has.**
- **The Doverslap reveal** (docs/27 §5): the first time a hero crosses the gorge bridge, their own camera eases up and back over The Sound to the World-Tree, Rime-Firth and Barrow-Eyot. It plays once per hero and never mid-fight, in each viewport separately.
- **North Quay's five-silhouette sightline fan** is kept clear (docs/14 §3.3).
- **The Chime-Post rhymes are Everwood's haiku** (docs/15 §6.2): ringing a post unfurls its zone's couplet on the ribbon, tinted by Sign.

**Verdict: kept; a rule for the next isles.**
- **No second reveal.** One at North Quay would show the same Sound a level after Doverslap, so the razor cuts it.
- **Embershore's chime-posts don't move.** They stand where the generator put them.

What the lesson asks for (put the rest stop where the view is) belongs in the next isles' briefs: §5 rule 4.

### 3.7 Places that look lived in

**Verdict: kept.** Docs/32 built this, more fully than the recommendation asked:
- 15 steadings sited where people would choose to live, and 322 fields.
- Hedges and walls with a gateway into every field.
- Smoking hearths and a lantern by each door.
- A steward walking each yard's round.
- Ricks, stooks, washing and hives.
- Fallow-Hollow, a flitted farm left to the Iron-Men.
- Fingerposts where the tracks leave the roads.

Its open gaps are the stock's sounds and lit windows; there are lit windows only if there's ever a dusk.

### 3.8 A world that reacts

**Verdict: kept.** The Lens is this recommendation.
- **The hush:** near an open crack the colour drains 85% to slate (the film and the world share one function for it, docs/31), the wind freezes, grass lies pressed flat, hush-motes rise and the lanterns dim.
- **The calming:** calming a crack sweeps a gold-and-emerald bloom out over the ground and raises a lulled cairn with its lantern.
- **The kin:** they leave as sea-swallows, never corpses (docs/15 §6.1).
- **The stock:** it gives way before a hero (docs/32 §8).

**The gap:** birdsong falling silent in the hush. There's no birdsong to silence; it needs recorded or synthesised sound (§8).

### 3.9 Restraint

**Verdict: kept; a rule for the next isles.**
- **The HUD:** the Caldera's has no minimap and no quest arrows.
- **The land:** docs/32 farms about 53 of Embershore's 130 hectares and leaves the commons, the downs and the crags open.
- **The Crown:** it has no town. The razor cut Concord Harbor (docs/14 §1.2).
- **The roads:** they stay safe (docs/23 rule 5).

§5 keeps it that way on the next isles.

## 4. What changed in the build

| File | What |
| :-- | :-- |
| `src/world/world_visual_catalog.gd` | Three new biomes, `IRON_NESS`, `BARROW_EYOT` and `RIME_FIRTH`: each isle's sun, sky, fog and ground palette. |
| `src/world/caldera/caldera_atlas.gd` | The three Friction Isles wear their own biome. Their music is still borrowed. |
| `src/world/caldera/islands/friction_isles_builder.gd` | The colour fields (`IRON_*`, `BARROW_*`, `RIME_*` at the top), each isle's meadow (`_meadow_style`) and wildflower shares, `beacon_spot()`, and the Beacon's tower on the far silhouette. |
| `src/world/caldera/island_builder.gd` | Three hooks: `meadow_flower_shares()` (the meadow reads it), `far_color()` (the far silhouette reads it) and `beacon_spot()`. |
| `src/world/caldera/far_beacon.gd` (new) | `FarBeacon`: the fire and smoke on a far silhouette, shown while its Beacon's flag is set. |
| `src/world/caldera/archipelago_streamer.gd` | `set_far_haze()` and `far_haze`; a `FarBeacon` on each Friction Isle's silhouette. |
| `src/levels/level_base.gd`, `src/levels/caldera_archipelago_world.gd` | `tint_far_scenery()` (the haze, `FAR_HAZE_COOL` 0.25); The Crown's shores read their facing isle's biome from the atlas. |
| `src/world/world_atmosphere_director.gd` | Hands the eased sky to `tint_far_scenery()` every frame. |

Performance: the colours, light and haze cost nothing. A lit far Beacon is one glow sphere and 14 particles per isle, at most three on screen.

## 5. Rules for the next isles

Iron-Ness, Barrow-Eyot and Rime-Firth will get master briefs as Embershore did (docs/27, docs/32). These rules carry this doc into them.

1. **Home in sight.** Each isle's quay, steading and Beacon face The Sound (Law 6), with the World-Tree in sight from its quay. Its landmark is what other isles see of it.
2. **One colour field**, from its rock and leaning to its Sign: the table in §3.3. Ground stays mid-value.
3. **One light per isle**, in its biome. No day cycle and no weather system: the isle's air is its weather.
4. **Find the view first, then put the chime-post (or spring) on it.** Use a low frame under 3.2 m (a wall end, a trunk, a stile), a path leading in, and the World-Tree or the isle's landmark beyond.
5. **Leave open ground.** Farm half the land at most. Keep camps off the roads (docs/23 rule 5), and leave the spaces between places quiet.
6. **Guidance stays where it is:** the tracker, the firefly trail, and a fingerpost at each fork. The wind is weather.
7. **Lived-in by docs/32's recipe:** steadings sited where people would choose to live, smoke, stock that gives way, a flitted farm where the grey has walked.
8. **The grey is the only enemy look:** drained colour, a frozen wind and the bloom when it's calmed. No second look for the enemy.

## 6. The six gates

| Gate | Result |
| :-- | :-- |
| 1 Anti-Parasitic Harmony | Pass. Each colour field and light leans to its isle's Sign and Calling. A lit far Beacon is its Sign's fire and its open trade lane. |
| 2 Musk Razor | Pass. No new button, menu, flag or system. The wind guide, weather, day cycle and second reveal are cut; the 10% back is each isle's air and its far Beacon. |
| 3 Philological Linter | Pass. No new names. The biomes take their isles' names, which docs/20 Part III §2.4 already keeps (checked against Rule 4 only). |
| 4 Schema-First Registry | Pass. The looks are `ZoneBiomeResource`s in `WorldVisualCatalog`, the isles point at them in `CalderaAtlas`, and the far Beacon reads its flag through the atlas. |
| 5 Code-First & Multi-Age Safe | Pass. All in code. Ground stays mid-value so telegraph rings read; nothing tall is added near play (the far tower stands on the silhouette). |
| 6 70-20-10 Linter | Pass. No new words on screen. |

## 7. Checks

`tools/test_sense_of_place.gd` runs inside `tools/test_caldera_isles.gd`, so it runs in the smoke test and in `tools/run_caldera_checks.gd` (119 Caldera checks, all passing, 2026-11-09). It has eight checks:

1. Each Friction Isle wears its own light, under its own Sign. Iron-Ness's horizon is the warmest, Rime-Firth's sky the bluest and its sun the coldest, and Barrow-Eyot's fog the thickest.
2. Underfoot, each isle's ground stays turf to the ground shader (85% of samples or more).
3. Each colour field reads from across The Sound. The far silhouettes' ground is sampled every 24 m: Iron-Ness's is the warmest, Barrow-Eyot's the most violet and Rime-Firth's the palest. Every sample below the snow is mid-value and never neon.
4. Each meadow leans its wildflowers to its field. Barrow-Eyot's own meadow, grown as the streamer grows it, has sea-lavender blue as its commonest flower.
5. From Embershore the far isles fade into its sky, not a fixed grey.
6. From The Crown they fade into The Crown's sky. This runs after the Beacons are lit.
7. From Embershore with every flag clear, no far Beacon burns. From The Crown after all three are lit, each burns over its tower, unstretched by the silhouette's lift.

Also changed:
- `tools/test_crown_zones.gd`: each shore wears its facing isle's light.
- `tools/test_world_visuals.gd`: the catalog has twenty biomes.
- `tools/test_mythopoetic_lens.gd`: the isles' old-tongue names answer to Rule 4 only, per docs/20 Part III §2.4.

## 8. Calls for the Creative Director

1. **The three fields and their light** (still open). The hues are constants at the top of `friction_isles_builder.gd`, and each isle's light is one `_biome` line in `world_visual_catalog.gd`. Say if any isle should lean further or less.
2. **Lower the sun for autumn light.** Built (2026-11-09): see §10.
3. **Birdsong and the stock's sounds.** Built (2026-11-09), generated from the audio architecture: see §10.
4. **A view of home.** Built (2026-11-09): the Mill-Downs reveal, see §10.

## 9. Gaps

- **Pictures:** `tools/sense_of_place_views.gd` (windowed) writes `docs/images/sense_of_place/`. They show the Sound from North Quay, cold and lit, each Friction Isle close from the quay, and each isle underfoot.
- **A grey band along the horizon** shows behind the far isles in every picture, and in docs/27's pictures too. It was there before this change; not chased here.
- **The full smoke test was not re-run.** Only the Caldera checks and check-only on every changed script ran after the last change.
- **The Friction Isles are still sketches** (docs/20 Part III): an arrival, a steading, a Beacon, camps and a landmark each. Their colour fields lie over the ground they have; their master briefs come next.
- **Their music is still borrowed.**
- **No README update yet** for the new tool and doc.

## 10. The Creative Director's calls, built (2026-11-09)

> **Asked for:** "Yes, lower the Sun for autumn. Use our audio architecture, the living pastoral storybook atelier reference, and the design goal to generate the animal sounds. Generate a 2nd camera reveal on Mill-Downs."

### 10.1 The autumn sun

The Caldera's sun stands 36° up (it was 48°, a midday sun): an autumn afternoon, in keeping with docs/32's week of the Great Autumn Feast. Its bearing hasn't moved: it still stands south-south-east, so docs/32's steadings still face it. Shadows lie longer and the land rakes warmer; the windmill on Mill-Downs throws its sails across the road. It's one pair of constants, `CalderaArchipelagoWorld.SUN_HIGH_DEGREES` and `SUN_BEARING_DEGREES`. The pictures in `docs/images/sense_of_place/` were all taken under it.

### 10.2 The farm's and the hedges' voices

**How they're made.** `PastoralVoices` follows docs/16's Tier 2, which makes the chamber ensemble in code: no voice is a bare oscillator, and each is an excitation through resonators.
- **Ewe and lamb:** a throat's harmonics through a mouth's formant resonators, opening from a closed "m" to an open "eh". The bleat's quaver is about 7.5 Hz (a lamb's 9 Hz) in pitch and loudness.
- **Cow:** a low throat through a mouth that opens from "m" through "oo" to "aa" and closes again, the pitch lifting then sinking, with breath.
- **Hen:** short "buk"s, and in every other take a rising "ba-GAWK".
- **Goose:** a nasal, slightly rough honk, in pairs ("ha-honk").
- **Blackbird:** a fluting phrase, a flue gliding between notes, with the score's own 25 ms grace-note flicks (docs/16 §2, the Shore axis).
- **Wren:** a run of falling chirps and a trill.

**The Living Storybook Atelier** (docs/16 §2) sets their manner: the voices are the score's neighbours, not a field recording.
- Each voice's resting pitch is a note of the Chime-Shrine's G pentatonic (G A B D E), and the birds sing from it, so a bleat or a blackbird under the score never clashes. That's the same idea as the Four Signs' stingers, which are pitched to the zone's tonic (docs/16 §5).
- They are soft and rounded, with gentle attacks and a warm low-pass at 4.2 kHz.
- Each take is seeded by its voice and number, so a flock always sounds the same.

There are three takes of each of the seven voices. Rendering all 21 takes on a worker thread takes about 0.3 s, when the first beast or bird would sing.

**Where they play.** All on the Ambience3D bus, through 3D players set as `AudioDirector.attach_ambience` sets its emitters:
- **The stock** (`GrazingStock`). While a flock is awake (a hero within its sight), one beast calls every so often: a ewe every 7-16 s, a cow every 14-30 s, a hen every 3-8 s, a goose every 9-20 s. A lamb calls with a lamb's voice and a calf a third higher. A beast a hero startles calls at once. A goose doesn't give way: it holds its ground and honks at a hero who comes within 5 m.
- **The birds** (`Birdsong`, one in the Caldera level). Every 2.5-7 s a blackbird or a wren sings from a perch on dry land 14 to 38 m from Player 1. The high moor and the ironstone heath have fewer: Rime-Firth's gap is 2.2 times as long, Iron-Ness's 1.8.
- **The First-Quiet silences them** (docs/17 §2.2). By an open Hush-Crack no bird sings, so a kin camp goes quiet as you near it (`WorldAtmosphereDirector.hush_at`). When the crack is calmed, its Reclamation Bloom sets four birds singing round it, one after another (the director's new `bloomed` signal).

Split-screen hears the world from Player 1's view, as all of Everwood's 3D sound does (only the first view has an audio listener), so the birds sing round Player 1.

**Checked by spectrogram.** `tools/test_sense_of_place.gd` holds them to numbers (§10.4). The voices were also drawn as spectrograms: the ewe's harmonics waver with the quaver, the cow's mouth opens and closes, and the birds' notes glide and trill.

### 10.3 The Mill-Downs reveal

The Doverslap reveal became `VistaReveal`, a reveal with its own id, reach, length and banner. Embershore now has two, each a different subject:
- **Doverslap** (Level 4): the promise, north over The Sound.
- **Mill-Downs** (Level 5): home. Where the Downs road passes the windmill, the first time each hero comes by, their camera eases up and back for 5 s. It looks south-west over the worked valley they have walked (walled fields, haycocks, the Moss-Oaks under the Elder Oak, Bramblebridge beyond) with the windmill as the frame on the left. The banner reads "EMBERSHORE: Home: every field and steading you walked through, the Moss-Oaks under the Elder Oak, Bramblebridge beyond".

Like Doverslap's, it plays once per hero per save (`reveals_seen`, id `mill_downs`), never mid-fight, and in each viewport on its own. It looks at a point 900 m out on the Elder Oak's bearing, because the camera looks 8% of the way to its point. So its look runs out over the valley, as Doverslap's runs out over The Sound. Picture: `docs/images/sense_of_place/mill_downs_reveal.jpg`.

This keeps §3.6's razor: one reveal per subject, and no two showing the same view.

### 10.4 Checks

`tools/test_sense_of_place.gd` gained five checks (13 in all):
- **The sun:** it stands 36° up, still south-south-east.
- **The voices:** all 21 takes sound, never clip, rest on the G pentatonic and render the same every time, and the ewe's bleat quavers at about 7.5 a second.
- **The calls:** a ewe a hero walks up to gives way and bleats, and a goose honks at them.
- **The birds:** they sing round the party, fall silent by an open Hush-Crack, and burst into song when it's calmed.
- **The Mill-Downs reveal:** it stands by the windmill, looks toward the Elder Oak, and plays once per hero.

`tools/test_embershore.gd` reads the Doverslap reveal as a `VistaReveal`.

### 10.5 Gaps

- **Nobody has listened to the voices yet.** They're checked by numbers and spectrograms; the first windowed playtest is the real test.
- **Recorded takes could stand in later.** `AudioDirector` prefers a baked recording for a station's loop (`ambience_<kind>.ogg`); the voices don't look for one yet.
