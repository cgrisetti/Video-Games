# 32 · Embershore, the worked land

> **Asked for (2026-11-09):** an enhancement and "world populating" pass on Embershore only. Make the landscape, the homes and the trees read as a valley people have farmed for a long time, in the manner of Le Guin's farming valleys, Tolkien's Shire and Susan Cooper's Welsh hill farms, using topographical and geographical judgement, and obeying every quest, lore, world-design and island rule already set.
> **Scope:** `games/everwood`, the starting isle (`isle_embershore`) only. The other four isles are untouched. Nothing of the generator's island moves: not a metre of ground, not a road, river, landmark, house or tree.
> **Reference pictures:** a New England farm valley (a dirt road winding past stone-and-timber farmsteads, a stream, sheep in a fenced paddock, wooded hills) and Tolkien's *The Hill: Hobbiton-across-the-Water* (a patchwork of small hedged fields, a lane, a mill, round-headed trees).

| | Before | After |
| :-- | :-- | :-- |
| The land | One green meadow from shore to shore, a wood, three orchard blocks and four patches of grain | 322 small fields round 15 steadings and the two villages: pasture, hay, barley, plough, roots, stubble, fallow, water meadow, with open common and downs between |
| Field edges | None | 10.2 km of hawthorn hedge (the lush west and south), 16 km of dry-stone wall (the dry north, the uplands, the coast), fences, hurdles and green baulks, with a gateway into every field |
| Homes | 24 identical red-roofed cottages, each facing its village's middle | The villages' 24 turned to face their lanes, in five lime washes and three roofs, with thatched and slated valley cottages among them, each with its toft; 15 steadings out in the fields with a house, barn, byre and yard |
| Trees | Moss-oak, apple, a few ash, willow and rowan | 21 kinds: field oak and field ash, beech, elm, chestnut, birch, poplar, thorn, alder, pollard willow, plum, pear, yew, holly and Scots pine besides, each where it would grow and each holding with its own few |
| Life | Smoke from the cottages | 131 sheep, 24 cattle, hens and geese that give way as you walk up; a steward about every yard; ricks, stooks, haycocks, carts, washing, hives |

## 1. Two sources, one on top of the other

`tools/worldgen/embershore_gen.py` (docs/27, the Master v2 brief's Appendix A, verbatim) stays the island's one source of truth. A second script reads what it wrote and lays the *settlement layer* over it:

```bash
tools/worldgen/.venv/bin/python tools/worldgen/embershore_settle.py world/embershore/gen/engine world/embershore/settle 7
```

It needs the same Python environment as the generator. The same seed always writes the same files into `world/embershore/settle/` (a `.gdignore` keeps Godot from importing them):

| File | What |
| :-- | :-- |
| `settlement.json` | steadings, village plots, tracks, fields, boundaries, trees, props and flocks, in the generator's metres |
| `mask_landuse.png` | what each square metre is used for (15 uses), 2048 x 1024 |
| `mask_tilth.png` | the direction each field is worked in |
| `preview.png` | the layer drawn over the hill-shaded island, for people |

`EmbershoreSettlement` reads the files. If they are missing the island builds as it did in docs/27 (the old cottages, no fields), with a warning.

**The ground does not move.** No pad or ramp is pressed into Embershore; `height_at` is still the heightmap's own value and every landblock's collider is still the generator's 1 m data. The check proves it at five spots.

## 2. Where people settled, and why

The script scores every square metre for a yard and takes the best ground within reach of each steading's seed:

- **Gentle:** the worst slope over a 30 m square counts, not one flat metre.
- **Sunward:** the Caldera's sun stands south-south-east, so a slope falling that way is warm.
- **Near a road** (about 70 m off it, not on it) and **near water** but 2.5 m above the river.
- **Sheltered:** a little below the land round it, never on a knoll.
- **Clear:** 14 m from anything Act I or the corridor stands on, 30 m from a cliff and the shore, 26 m from the Moss-Oaks.

Each yard opens to the sun with the house at its back and the barn across the weather, which comes from the south-west (the generator's rain shadow lies north).

| Steading | Kind | Fields parted by | Where |
| :-- | :-- | :-- | :-- |
| **Lark-Wick** | farm | hedge | the west end, over the sea |
| **Barley-Green** | farm | hedge and wall | Strait Lane, west |
| **Thistle-Crossing** | farm | hedge and wall | Strait Lane, toward the north strand |
| **Clover-Hollow** | farm | hedge and wall | the middle basin |
| **Plum-Wick** | croft | hedge | above Lee-Shore Orchards |
| **Otter-Crossing** | croft | hedge | the Bramble's south bank, reached by a ford |
| **Kettle-Wick** | croft | hedge and wall | west of Hearthstead |
| **Withy-Hollow** | the wood-wright's cot | hedge | the Moss-Oaks' north edge (timber stacks, a saw-horse, a charcoal clamp) |
| **Miller's-Green** | the miller's | wall | under the windmill |
| **Ewe-Green** | farm | wall | east of Hearthstead |
| **Sunward-Haven**, **Seal-Haven** | fisher's cots | wall | the two coves (a turf-roofed net shed, racks, a boat keel-up) |
| **Gorse-Wick** | hill farm | wall | above Doverslap (a round sheepfold) |
| **Eel-Wick** | croft | wall | the Eel Junction |
| **Fallow-Hollow** | flitted | tumbled wall | south of the Sunken Holloway |

Names keep the Lens's Map-Sense rule (docs/15 §2): a warm syllable and one of its seven nouns. **Fallow-Hollow** is the Lens's *flit*: its people packed their cart and left. It stands where the Furrow Iron-Men walk the Holloway un-ploughing furrows, so its roof is down, its walls are tumbled, its plough stands where it stopped and its fields are going back to bramble. No hearth, no steward, no stock.

Each steading is a named place 44 m round its yard: the HUD names it as you walk in. It keeps the sky, fog and music of the corridor stage it stands in (`IslandBuilder.stage_name_at`), and every lived-in one counts as settled ground for the mosaics (`is_settled_place`).

## 3. Tracks

Each yard gate is joined to the nearest road by the cheapest walk over the ground (slope squared, the wood, the river and Act I's places all cost), then eased until no turn between 3 m steps is sharper than 13° (a cart's turning circle; the roads' limit is 30°). Five footpaths go where nobody's track does: the Bramble's bank to the river mouth, the orchard walk, the strand way, the downs drove and the cove steps.

20 tracks, 2.5 km. They are laid as drawn (`add_path(points, half_width, false)`), so the ground shader draws them as rutted earth, the map shows them and the scatter keeps off them. Where Otter-Crossing's track wades the Bramble there is a ford of stepping stones. A finger-post with the steading's name stands where each track leaves its road.

## 4. Fields

- **Who works what:** each steading works the ground within its reach (100 to 235 m), the edge roughened by noise, on slopes under 25%, between 2 and 36 m, off the cliffs, the shore, the wood, the roads and the rivers. The downs above 36 m stay open.
- **Parcels:** seeds are sown closer near a home (small closes) and wider further out, and each cell takes its nearest seed, stretched 1.5 times along the contour (a plough turns the furrow along the hill). A field is one piece; stray scraps go back to the waste and grow spinneys.
- **What grows:** by slope, damp and soil. Over 20% is pasture. Beside the river and under 9 m above it is water meadow. Otherwise a weighted draw: the dry north leans to barley and stubble, the lush south to hay, roots and plough, a hill farm to pasture, and no crop is likely beside itself.
- **The generator's own:** Lee-Shore Orchards' three blocks are hedged orchard closes, and the four grain patches are the Mill-Downs' open strips, in barley and stubble with their rows along the generator's 120 lines. Each line is now the green baulk between two strips.

| Use | Fields | Hectares | Ground | Meadow | Rows the shader draws |
| :-- | --: | --: | :-- | :-- | :-- |
| pasture | 81 | 15.2 | grazed green | short, few flowers | old ridge-and-furrow under one in three |
| hay | 35 | 8.4 | pale green | tall, full of flowers | mower's swathes |
| barley | 42 | 8.8 | straw gold | ripe grain 1.75 times a meadow's height, a poppy here and there | drills |
| plough | 24 | 4.3 | loam | none | furrows every 0.62 m |
| roots | 10 | 2.2 | soil | none | green rows every 1.2 m |
| stubble | 27 | 4.8 | pale straw | cut to a hand's height | drills |
| fallow | 30 | 5.2 | weedy grey-green | rank | slumped furrows |
| water meadow | 7 | 0.9 | dark lush green | tall | |
| orchard, garden, yard | 66 | 2.9 | | | garden rows |

**How it is drawn.** `EmbershoreBuilder._ground_color` paints each use over the wild turf, inside the ground's mid-tones (docs/17 §2.3) and on the green or loam side of the shader's sorting so nothing reads as sand. Rows are drawn per pixel: each landblock's mesh carries the field's row direction and strength in UV and its spacing and tone in UV2 (`ground_tilth`), and `storybook_terrain_splat.gdshader` draws dark furrows between pale ridges, or green rows on bare soil, leans the normal off each ridge, and fades to the rows' average where a row is under a pixel. The meadow reads its style per tuft (`_meadow_style`: height, flowers, ripeness); a ripe tuft keeps its own colour to the tip instead of the meadow's green.

A green baulk 2 m wide is left unploughed along every crop's edge.

## 5. Boundaries

The lines between fields are traced from the parcels and laid in runs: a piece 3.2 m long (a hurdle 2.4 m) set end to end along the line and tilted to the slope.

| Kind | Length | Where | Solid |
| :-- | --: | :-- | :-- |
| hawthorn hedge | 10.2 km | the lush west and south; a quarter of its runs in may blossom and dog-rose | no: leaves, which lean from a hero pushing through |
| dry-stone wall | 14.8 km | the dry north, the uplands, the coast, every yard | yes: 0.8 m, on the low-scenery layer |
| tumbled wall | 1.2 km | Fallow-Hollow | no |
| split-rail fence | 0.8 km | some pastures | yes |
| wattle hurdle | 0.3 km | gardens and tofts | yes |
| green baulk | 3.3 km | between two tilled fields | nothing built |
| line of trees | 0.7 km | between two tilled fields | |

- **Never a cage.** Every field beside a road or track has a gate onto it (granite gateposts, a five-barred gate standing open). Every wall has a way through at least every 55 m: a gate, a squeeze stile or a gap. 400 gateways in all.
- **Hop it.** A wall is 0.8 m; a hero's jump is 0.96 m. Walls are on the low-scenery layer, so cameras see over them (docs/17 §2.1).
- **Not near a fight.** No boundary runs within 28 m of a road pack or 26 m of Act I's packs and groves, so a foe on its leash never meets a wall. Docs/28's hounds stand "at a grey hedge gap": the orchard closes are hedged and the hedge is open where each pack stands.
- **None along the water** (stock drink there) or on a cliff's lip.

Runs are scatter species (`HEDGE_RUN`, `HEDGE_BLOOM`, `WALL_RUN`, `WALL_TUMBLE`, `FENCE_RUN`, `HURDLE_RUN`, `FIELD_GATE`, `STILE`), one MultiMesh per kind per landblock while a camera is near it. `IslandBuilder.SOLID_BOX` gives the solid kinds a low box each inside the loaded window. Section 9 says how they are drawn far off.

## 6. Trees

Every tree is placed for a reason (1,595 beside the generator's own), and each holding keeps its own few kinds, so the island's variety is from one valley to the next:

- **Hedgerow standards:** about every 34 m of hedge, three kinds to a holding (oak, ash and thorn at one; elm, thorn and oak at the next; beech, oak and holly at a third); a wind-bent thorn, rowan, ash or birch about every 95 m of wall.
- **Shelterbelts:** two kinds across the south-west of every yard (beech and oak, elm and chestnut; pine with ash or rowan at a stone farm), one of them by the gate.
- **Orchard closes:** one fruit to a steading, plum, pear or apple, behind its house; plums in Bramblebridge's tofts, pears in Hearthstead's.
- **Along the water:** alder and pollard willow on the Bramble, alder and birch on the Dover.
- **Line-trees:** poplars along Strait Lane and the Coast Road into Hearthstead, and along some baulks.
- **The dark wood:** 553 Scots pines (a long ruddy stem under three leaning pads of dark needles, not the highland fir's tiers; 80 triangles, the same shape near and far) in stands on steep ground facing away from the sun, thinning into birch and rowan (the slope south of Bramblebridge, the south-east crags).
- **The upland fringe:** birch and rowan between the fields and the crags.
- **Spinneys and clumps:** mixed broadleaf in the waste corners the fields left; beech clumps on seven knolls.
- **Lone field trees** in the larger pastures; a great chestnut by each village green; yews by four of the First-Quiet's sleepers.
- **The Sunken Holloway** runs under oak, ash and holly on the lips of its banks, with fern on the cut earth.
- **The Moss-Oaks** are an oakwood, not a plantation: 90 of the generator's smaller trees along the wood's edge are birch, rowan and holly, each where the generator put it. The wood's heart stays oak (1,218 of 1,308).

The new kinds are sculpted like docs/24's (a gnarled trunk forking above the sightline, ShapeKit's leaf-cloud crown) with two changes. A second, shallower dome hangs under the first, so an open-grown tree is round all the way down instead of a flat-bottomed umbrella. And a crown is a handful of big lobes, not a score of small ones: a field tree is about 1,800 triangles. No leaf comes under 2.4 m (the check measures it). The Scots pine has no sculpted mesh: like the rowan, it is its far shape at every distance (its stands are a hundred trees to a landblock).

## 7. Homes

**The villages keep docs/17's stepped-gable house.** Bramblebridge's and Hearthstead's 24 stand on the generator's spots, but each now faces its lane (or the green, where no lane passes), in one of five lime washes under clay, slate-blue or moss-green shingles; the first is the inn (the Homestead Hall), one in nine a Smoking Bakery. Eight of the 24 are the valley's own cottages instead. Each has a toft behind it: garden rows inside hurdles, a low wall or a hedge, a fruit tree or two, a woodpile, a bench by the door, hives or a washing line. Each green has a well, benches, a cart, geese and hens.

**A steading out in the fields is plainer** (`SteadingKit`): built low out of what the island gives.

| Building | What |
| :-- | :-- |
| valley cottage, farmhouse | fieldstone or lime wash over it, on a stone footing; thatch at 50° with a block-cut ridge and rounded eaves, or slate at 44° under stone copings; a stone chimney on the gable (two on a farmhouse); small shuttered windows, a plank door in one of the market's four heritage dyes, a rose trained up beside it, the evening lantern on its bracket, a water butt. A farmhouse adds a porch and an outshut under a catslide. |
| barn | boards and battens of oak gone silver over a waist-high stone footing (or all stone), great doors with one leaf standing open on the dark, straw over the sill, a loft door and hoist in the gable, an owl hole |
| byre | open to the yard on oak posts, a manger along the back wall, straw underfoot |
| granary | a boarded box on nine staddle stones under a four-sided tiled roof |
| net shed | tarred boards under a turf roof, a net and floats drying on the wall |
| ruin | the roof fallen in, one gable standing, ivy up the stone |

Round the yard: a well under a thatched hood, round ricks on staddles, a blue cart with red wheels, a trough, a split-log woodpile, cedar hives on a slate bench (docs/17's hives), washing that lifts in the wind, a kennel.

**On a slope.** A building's floor is the ground at its door. Behind, it is dug into the bank; in front, it stands on its footing, which reaches down to the lowest corner. Nothing is flattened.

**Near and far.** Each building is one crafted mesh, shared by shape, to 190 m, and a one-draw stand-in past it. A yard's pieces are merged into one mesh. Dwellings smoke; the lantern by the door glows.

## 8. Life

- **Stock** (`GrazingStock`): Golden-Fleece sheep (docs/13's, with lambs and now and then a dark one), belted cattle with calves, yard hens, geese on the greens. Each beast walks a seeded, clock-driven round and stands a while at each stop with its head down, the same on every peer (as `AmbientFlock` does). It is also shy: it gives way before a hero inside its shy ring (sheep 5 m, cattle 3.4 m, hens 3.2 m; geese stand their ground) and drifts back. A flock is two draws (bodies and heads), seen from across the valley. It stands still until a hero comes within 40 to 80 m of its home (hens 40 m, geese 50 m, sheep 70 m, cattle 80 m), then takes up its round where the clock has it.
- **Stewards:** whoever keeps each lived-in steading walks their day's round, from the door to the well, out to the gate and back by the barn (a `TownsfolkNPC` villager). Nobody to talk to; never in a quest's way.
- **In the fields:** haycocks in rows across the mown hay, stooks across the stubble, leafy tops along the root crop, bean wigwams in the gardens, scarecrows in the corn, a trough by the gate of a grazed pasture, bramble in the fallow.
- **On the hill:** three old sheepfolds going back to stone, two cairns.

## 9. What it costs

The first build of all of the above cost 10 to 17 frames a second with four players (Bramblebridge 54 to 40, Mill-Downs 61 to 45). Four viewports and the sun's shadow splits draw every triangle about twelve times, and miles of hedge, a thousand and a half trees and two hundred beasts add up. What brought it back, each measured:

- **Far shapes are merged.** Past its hand-over, a landblock's worked-land trees are one mesh and its hedges, walls, haycocks and stooks another: two draws a landblock instead of one per kind (`ArchipelagoStreamer._add_scatter`, `WorkedLandKit.MERGED_FAR`). Every node of a landblock measures its distance from the landblock's own box (`custom_aabb`), so its sculpts and its far meshes hand over together. A landblock's runs are sculpted within 96 m of its middle and its trees within 128 m, so no far hedge shows nearer than about 32 m and no far tree nearer than about 64 m. Far runs are not drawn at all past 720 m.
- **Far shapes are a handful of triangles.** A far hedge or wall is a ten-triangle loaf, a far tree a five-sided bole and one faceted head (60 to 90 triangles). The Moss-Oaks' own stand-in keeps its bole and three lobes in fewer facets (234 triangles to 174): thirteen hundred of them are in any view of the wood.
- **Near shapes are lean.** A hedge run is six faceted lumps of leaf (330 triangles), a wall run two courses under its coping (216), a field tree a handful of big lobes (1,800).
- **A sculpted tree throws no shadow of its own.** While a landblock's trees are sculpted, their stand-ins throw the shadows instead (shadow-only, drawn 22% narrower so the sculpted crown stands clear of them in the light): fifty triangles a tree in each shadow split instead of 1,800. Hedges, walls and small field pieces throw none.
- **Each holding keeps a few kinds of tree** (§6), so a landblock draws three or four kinds, not a dozen.
- **Small things give out near.** Crop rows are drawn to 100 m, gates to 170 m, a yard's pieces to 150 m (a toft's to 105 m, without shadows), a steward to 75 m (a figure is 15,000 triangles), a building's crafted mesh to 190 m.
- **Stock sleeps.** A flock moves only while a hero is within 40 to 80 m of its home (by kind), every other physics tick, and all the island's flocks share one look at where the party stands. A sheep is 150 triangles.
- **The furrow shader works only where a row can be seen.** Past that the field is its rows' average colour and no noise is read.
- **A field grows no more grass than the wild did.** The dry north keeps its thin sward under the fields; plough, roots, gardens and yards grow none.

Four players, 1920 x 1080, Apple M5, `tools/embershore_screenshots.gd` (docs/27 §8's tool and stages; "before" is the same build with `world/embershore/settle` moved aside, which is how to see the island without its worked land):

**What a frame draws** (all four views and their shadow passes; these counts don't depend on what else the machine is doing):

| Stage | Triangles before | Triangles after | Draws before | Draws after |
| :-- | --: | --: | --: | --: |
| Bramblebridge | 8.93 M | 9.01 M | 8,480 | 5,898 |
| Moss-Oaks | 7.51 M | 7.76 M | 3,371 | 4,126 |
| Sunken Holloway | 5.17 M | 5.87 M | 1,777 | 2,479 |
| Doverslap bridge | 4.97 M | 5.43 M | 1,714 | 2,425 |
| Coast Road | 8.33 M | 8.39 M | 8,581 | 5,396 |
| Hearthstead | 8.18 M | 8.16 M | 6,119 | 4,993 |
| Mill-Downs | 6.05 M | 6.68 M | 2,993 | 3,696 |

The villages draw less than they did: a home is one crafted mesh with a far stand-in where the old cottage was a dozen parts.

**Frames a second: not settled.** Without the worked land this branch runs at 54, 47, 60, 70, 51, 62 and 61 at the seven stages on a quiet machine (lower than docs/27 §8's table, which was taken before Act I's kin and people stood on the isle). By the time the savings above were in, the Mac was busy with a video call and a browser, and a run swung by ten frames a second with nothing changed. So the pair was run in turn, three times each, at three stages, with the window hidden:

| Stage | Before (three runs) | After (three runs) |
| :-- | :-- | :-- |
| Bramblebridge | 35, 41, 33 | 49, 32, 42 |
| Sunken Holloway | 41, 40, 45 | 32, 45, 40 |
| Mill-Downs | 46, 50, 49 | 48, 44, 36 |

The two overlap at every stage: whatever the worked land costs now is less than a busy machine can show. The last full run before the stock was put to sleep, with the machine already getting busy, read 48, 42, 54, 64, 44, 54 and 50. A seven-stage pair on a quiet machine is still owed. From `games/everwood`, with nothing else running:

```
mv world/embershore/settle /tmp/embershore_settle
godot --path . -s res://tools/embershore_screenshots.gd -- --out=/tmp/embershore_before
mv /tmp/embershore_settle world/embershore/settle
godot --path . -s res://tools/embershore_screenshots.gd
```

The second run also takes docs/27's seven stage pictures and `docs/images/embershore/perf.md` afresh; until then those show the island before its worked land.

## 10. Checks

`tools/test_worked_land.gd` runs inside `tools/test_caldera_isles.gd` right after Embershore's own checks, eight checks:

1. The layer is read (steadings, fields, uses, boundaries, trees) and the generator's ground is untouched: no pad or ramp, the height at five spots the heightmap's own.
2. Nothing of it stands on what Act I and the corridor use: the spawn, the orchard gate, the four groves, every pack, the chime-posts and the market are clear of every run, new tree, field piece and home.
3. The fields are parted by hedge and wall; no wall runs further than 62 m without a way through; in the window a landblock's wall runs are low boxes under a hero's jump and its hedge runs are none.
4. The valley keeps 14 kinds of tree or more; each new one is sculpted (at most 3,200 triangles, no leaf under 2.4 m) with a stand-in.
5. The homes stand on their ground: the villages' 24, the steadings', every lived-in hearth smoking, a steward in each yard, Fallow-Hollow cold and empty.
6. The fields are worked: loam where it is ploughed, with furrows carried in the near ground's UVs; green rows in the roots; grazed turf; ripe grain in the barley.
7. The tracks are laid as roads and join the roads they leave.
8. The stock keeps to the ground and a ewe gives way before a hero.

Changed in Embershore's own checks (`tools/test_embershore.gd`): the wood's count is its oaks and its edge trees together, and the cottages are counted as homes (stepped-gable houses and valley cottages alike). `tools/test_laid_roads.gd` holds the tracks to the roads' rules as it stands.

`tools/embershore_views.gd` (windowed) takes the pictures in `docs/images/embershore_worked_land/`: it stands a hero at each subject, so the near ground, meadow and stock are there, and looks from a free camera. A steading's view follows the steading to wherever the script set it down.

## 11. Assumptions

1. **"Upgrade the landscape" means what stands on the land, not the land.** The heightmap is the Master v2 brief's (docs/27 §1, exact to the centimetre against its Appendix B). Terraces are drawn as contour-following fields and walls, not cut into it.
2. **The villages keep the stepped gable.** Docs/17 §2.1 gives Bramble-Bridge that house; the Le Guin, Tolkien and Cooper vernacular is added beside it and used for everything outside the villages.
3. **No hobbit-holes.** "Earth-integrated" is read as homes dug into their banks behind, low eaves, turf on a net shed, a turfed charcoal clamp.
4. **The weather comes from the south-west.** The generator gives a dry north (its rain shadow) and the Caldera's sun stands south-south-east; shelterbelts stand across the south-west of each yard.
5. **Hedges are leaves and walls are stone.** A hero walks through a hedge and hops a wall. A foe never has to: boundaries keep clear of every pack's leash.
6. **Stock and stewards are scenery.** They have no collision, nothing to say and no part in any quest.
7. **The Moss-Oaks' mix is at the edge only.** Clay chose to keep the wood's look and its 49 FPS (docs/27 §8); 90 small edge trees changed kind and none moved.
8. **Fallow-Hollow is new lore, small and consistent:** a steading whose people flitted, on the Iron-Men's ground. It names nobody.

## 12. Calls for the Creative Director

1. **The steadings' names** are mine, to the Lens's rules. Rename any in `STEADINGS` at the top of `embershore_settle.py` and run it again.
2. **How much of the island is farmed:** about 53 of its 130 hectares are fields. Each steading's `land` (its reach in metres) turns that up or down.
3. **Stone or hedge:** each steading's `style` sets what parts its fields.
4. **The Moss-Oaks' edge mix** (assumption 7): say if the wood should be oak to its last tree again.
5. **People.** The stewards are silent. A line or two each, and a name, would make them neighbours; that is writing, and it is yours or Gemini's.

## 13. Gaps

- **No sound of it yet:** no sheep, cowbell or hen. The Ambience3D kinds are hearth fire, trickle, carillon and the gate's drones; stock would need recorded or synthesised cues.
- **No morning mist** in the valley floors: the biomes' fog is the level's, not the river's.
- **No seasons or weather:** it is always the week of the Great Autumn Feast, with the barley ripe and the hay half in.
- **The other four isles** are as they were. The script and the kit are Embershore's but nothing in the streamer, the species list or the ground shader is.
