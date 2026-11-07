# 06_WORLD_AND_CALLINGS.md — World Etymology, The Four Signs, & The 3x3 Calling Matrix

## 1. World Setting & Starting Geography
Everwood is one land of hollows, greens and falls, kept awake by the stewards who name it and pressed on from below by **The First-Quiet** ([15_THE_MYTHOPOETIC_LENS.md](15_THE_MYTHOPOETIC_LENS.md)). Every settlement and zone is a hyphenated Map-Sense compound: a warm syllable joined to `-bridge`, `-green`, `-hollow`, `-falls`, `-haven`, `-wick` or `-crossing`, so a child can tell where a place sits in the watershed from its name alone.

### 1.1 The Six-Zone Stewardship Atlas
| # | Zone | Cooper Sign | Landscape & Settlements | Kin of the First-Quiet |
|---|---|---|---|---|
| 1 | **`Tizzi-Wed-Green`** | *Sign of Wood* | Lowland greens and orchards; the hub village **Bramble-Bridge**, the hamlet **Honey-Wick**, and **Oakshire Vale** at its heart. | *Boggart-Kin* & *Hedgerow-Hobs* |
| 2 | **`Gull-Wick-Haven`** | *Sign of Water* | Chalk cliffs, Cornish *fogous* and booming sea-caves. | *Sea-Cave Scrays* & *Gale-Buccas* |
| 3 | **`Barley-Bridge-Meadow`** | *Sign of Iron* | Ploughed fields, water-mills and bog-iron pits. | *Furrow Iron-Men* & *Chain-Hounds* |
| 4 | **`Rush-Light-Hollow`** | *Sign of Fire* | Peat bogs, willow-pools and drowned trunks. | *Wisp-Boggles* & *Lob-Clouds* |
| 5 | **`Barrow-Crag-Crossing`** | *Sign of Stone* | Granite tors, standing stones and old barrows. | *Cairn-Drakes*, *Scree-Worms* & *Tor-Sleepers* |
| 6 | **`Sunken-Crown-Falls`** | *Sign of Bronze* | The First-Crevice at the Great Cataract. | *Old-Hob-of-the-Hill* & *The Deep-Hush* |

### 1.2 The First Expedition: The Bramble-Bridge Trail
- **Starting Hub Village:** **Bramble-Bridge** in Tizzi-Wed-Green (a warm, stepped-gable canal and watermill village inspired by Bruges, Visby and *Fable*'s Oakvale), south of **Moss-Oak Hollow**. The lane north from **Honey-Wick**'s Kindle-Fire comes in at its south gate.
- **First Expedition Path:** From **Bramble-Bridge Green** -> through **Moss-Oak Hollow** -> down the root-arched sunken lane into the edge of **Rush-Light-Hollow** -> across **Doverslap Bridge** (with a carved-timber gatehouse and paper-mill waterwheel over the roaring **Doverslap Falls**) -> to the Ring of the Cairnsman.
- **Kin on the trail:** *Bramble-Hobs* (thorny bramble balls on twig legs) and *Wisp-Boggles* (moss-grey sprites with lantern eyes) slumber round two **Hush-Cracks**, where the First-Quiet seeps up through the roots.
- **First Raid Boss (`BossDummy`):** **The Cairnsman of Doverslap Falls**, an ancient river-cairn of stacked boulders, heather and weathered bridge-timbers bound with brass bell-ropes. He turned boggart when the bridge was built across his falls; beaten, he is lulled back into a mossy cairn, never slain.
- **Oakshire Vale** ([12_WORLD_OAKSHIRE_VALE_GDD.md](12_WORLD_OAKSHIRE_VALE_GDD.md)): the starting vale, with **Oakshire-Wick** at its centre and five petals (**Wayfarer-Green**, **Pippin-Green**, **Quarry-Wick**, **Bramble-Hollow**, **Nine-Stones-Crossing**), each a threshold toward one of the zones above.

---

## 2. The Four Scribe Signs & Manuscript Finishes
Every card, seal and detonation belongs to one of the **Four Scribe Signs**:
1. **`SIGN_IRON_ROOT` (Sign of Iron-Root — Amber/Ochre):** Poise & stagger lever. Detonation: **Shatterpoint** (`+45.0` poise damage).
2. **`SIGN_RIME_GALE` (Sign of Rime-Gale — Sea-Azure):** Burst & frost lever. Detonation: **Glacial Rupture** (`+45.0` burst damage).
3. **`SIGN_WARM_HEARTH` (Sign of Warm-Hearth — Saffron-Gold):** Mending & shelter lever. Detonation: **Dawnburst** (`20.0` HP party heal within `10m`).
4. **`SIGN_STAR_TIDE` (Sign of Star-Tide — Twilight-Violet):** Tempo & resource lever. Detonation: **Astral Chorus** (`+25.0` stamina & `+0.5` pips to party within `10m`).

**Card Finishes (`CardVariant`):**
- `STANDARD` -> **Plain Vellum**
- `GILDED_LEAF` -> **Gilded Leaf**
- `STAR_INKED_VELLUM` -> **Star-Inked Vellum**

---

## 3. The 3x3 Matrix of Callings (`PrimaryRole` x `SecondaryRole`)
Every hero chooses a **Primary Fellowship** (locking in their Raid Trinity Seat: Tank, DPS, or Mender) and a **Secondary Calling** (applying a clean composable modifier):

| Primary \ Secondary | `+ TANK` (Stout Heart) | `+ DPS` (Swift Foot) | `+ MAGIC` (Wise Hand) |
|---|---|---|---|
| **TANK** *(The Shield-Sworn)* | **Bridge-Warden** *(Keeper of the Stone-Span)* | **Weald-Captain** *(Vanguard of the Green Company)* | **Hearth-Guard** *(Watcher of the Kindled Stone)* |
| **DPS** *(The Wayfarers)* | **Iron-Woodsman** *(Hewn-Hand of the High Pines)* | **Hedge-Runner** *(Outrider of the Bramble-Ways)* | **Sign-Seeker** *(Journeyman of the Four Signs)* |
| **MAGIC** *(The Lantern-Bearers)* | **Bell-Keeper** *(Ringer of the Sanctuary Chime)* | **Wind-Mender** *(Weather-Worker of the Sound)* | **Lantern-Scribe** *(Bearer of the Reed-Light)* |

### Composable Secondary Modifiers (Applied on top of Primary Base Stats)
- **`+ TANK` Secondary:** `+20.0` Max HP, `-2.0/s` Stamina Regen, `+25%` Poise Damage, `+30ms` Perfect Guard window, unlocks `HEAVY` Armor & `Sign of Iron-Root` affinity.
- **`+ DPS` Secondary:** `+0.0` Max HP, `+3.0/s` Stamina Regen, `+15%` Weapon & Card Strike Damage, unlocks `BOW` / `HEAVY_AXE` & `Sign of Rime-Gale` affinity.
- **`+ MAGIC` Secondary:** `-5.0` Max HP, `+2.0/s` Stamina Regen, `+20%` Resonance Pip Gain & Heal/Shield Potency, `+1` Grimoire Memory Capacity, unlocks `STAFF` & `Sign of Warm-Hearth` / `Sign of Star-Tide` affinity.
---

## 4. Build Notes (Phases 8 to 12 and the Mythopoetic Lens)

What the game uses today, and what is still design only.

**In the code now**
- **The Four Signs.** `ScribeSignResource.Sign` holds `SIGN_IRON_ROOT`, `SIGN_RIME_GALE`, `SIGN_WARM_HEARTH` and `SIGN_STAR_TIDE`; every card, seal, detonation and effect uses them. The detonations are Shatterpoint, Glacial Rupture, Dawnburst and Astral Chorus, with the numbers in §2.
- **Card finishes** read as Plain Vellum, Gilded Leaf and Star-Inked Vellum (`CardVariant.STANDARD`, `GILDED_LEAF`, `STAR_INKED_VELLUM`). Save files keep the original save keys (`standard`, `shiny_foil`, `astral_prism`), so existing binders still load.
- **Bramble-Bridge** is the hub's name, with a greybox pass toward §1.2: stepped gables, a canal with a bridge, and a turning watermill wheel. Its files and network id stay `hub_town`, and `--instance=bramblebridge` still names the seamless world.
- **The Cairnsman of Doverslap Falls** is the first raid boss (`BossDummy`), fought in **The Ring of the Cairnsman**. Its files and network id stay `dungeon_dojo`. Beaten, he's lulled into a mossy cairn that stays (`HobSpectrumComponent`, `STATE_LULLED_CAIRN`).
- **The atlas** is data: `MythopoeticAtlas` registers the six zones of §1.1 (`StewardshipZoneResource`) with their Signs, kin and rhymes, and names the zone each built place belongs to.

**Built in Phases 9 and 10** (see 07_EXPEDITION_HUD_AND_ART_GDD.md §5)
- The 3x3 Callings, with the names in §3 and the Secondary modifiers above.
- The expedition trail: Moss-Oak Hollow, Rush-Light-Hollow, Doverslap Bridge with its gatehouse and paper-mill wheel, and the Ring of the Cairnsman. Bramble-Bridge Green is the hub's spawn green.

**Built in Phase 11** (see 10_WORLD_ARCHITECTURE.md §6)
- **The Bramble-Bridge trail through Tizzi-Wed-Green**, the first seamless region: Honey-Wick, Bramble-Bridge and the expedition joined as 128 m Landblocks. Walk out of the village's open Forest Gate, under the Moss-Oak Great Arch, all the way to the Ring of the Cairnsman. Start it with `-- --instance=bramblebridge` (the game itself starts in Oakshire Vale); the Raid Portal still leads to the instanced expedition.
- A far mill-castle and a windmill stand as silhouettes on the crags round the corridor.

**Design only, not built yet**
- Gull-Wick-Haven, Barley-Bridge-Meadow, the rest of Rush-Light-Hollow, Barrow-Crag-Crossing and Sunken-Crown-Falls as places to walk. Oakshire Vale's petals already point toward them (12 GDD §6).

**Naming decisions**
- **The Callings are named as in §3** (Creative Director, 2026-11-01). Use the §3 names in code and copy; the Phase 7 & 8 brief's set is retired.
- **The currency is Chimes** (07 GDD §1.2): octagonal brass wayfarer coins.
- **Places, creatures and gear follow the Mythopoetic Lens** (15 GDD §2 and §7): Bramble-Bridge, Moss-Oak Hollow, Rush-Light-Hollow, Doverslap Bridge and Doverslap Falls on the trail; the six zones of §1.1 replace the old archipelago list. Ids already in saves, scenes and RPCs keep their old spelling.
