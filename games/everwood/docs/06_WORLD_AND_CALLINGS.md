# 06_WORLD_AND_CALLINGS.md — World Etymology, The Four Signs, & The 3x3 Calling Matrix

## 1. World Setting & Starting Geography
- **Starting Hub Village:** **Bramblebridge** (A warm, stepped-gable canal and watermill village inspired by Bruges, Visby, and *Fable*'s Oakvale, bordering the **Ariundle Moss-Oaks**).
- **First Expedition Path:** From **Bramblebridge Green** -> through the **Ariundle Moss-Oaks** -> down the root-arched **Sunken Holloway** -> across the **Doverslap Gorge Bridge** (with a *Peleș/Corvin* carved-timber gatehouse and paper-mill waterwheel) -> to the boss sanctum.
- **First Raid Boss (`BossDummy`):** **The Cairnsman of Doverslap** (An ancient sentinel of stacked river-boulders, heather, and weathered bridge-timbers bound with brass bell-ropes).
- **Other Key Archipelago Regions:** **The Wadden-Green** & **Millwater Reach** (Dutch dyke-meadows), **Luka-Bay** (Dalmatian karst coves), **Tizzi-Wed** & **The Saffron Cliffs** (Southern cliff-granaries and pigment presses), **Sinaya Mill-Castle** & **Corvin Bridge-Keep** (The Two Great Scriberies).

---

## 2. The Four Scribe Signs & Manuscript Finishes
All references to "Aspect" are replaced in UI and lore by **Sign**:
1. **`SIGN_IRON_ROOT` (Sign of Iron-Root — Amber/Ochre):** Poise & stagger lever. Detonation: **Shatterpoint** (`+45.0` poise damage).
2. **`SIGN_RIME_GALE` (Sign of Rime-Gale — Sea-Azure):** Elemental burst lever. Detonation: **Glacial Rupture** (`+45.0` burst damage).
3. **`SIGN_WARM_HEARTH` (Sign of Warm-Hearth — Saffron-Gold):** Mending & shelter lever. Detonation: **Dawnburst** (`20.0` HP party heal within `10m`).
4. **`SIGN_STAR_TIDE` (Sign of Star-Tide — Twilight-Violet):** Tempo & resource lever. Detonation: **Astral Chorus** (`+25.0` stamina & `+0.5` pips to party within `10m`).

**Card Finishes (`CardVariant` Display Names):**
- `STANDARD` -> **Plain Vellum**
- `SHINY_FOIL` -> **Gilded Leaf**
- `ASTRAL_PRISM` -> **Star-Inked Vellum**

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

## 4. Build Notes (Phases 8 to 11)

What the game uses today, and what is still design only.

**In the code now**
- **The Four Signs.** `ScribeSignResource.Sign` holds `SIGN_IRON_ROOT`, `SIGN_RIME_GALE`, `SIGN_WARM_HEARTH` and `SIGN_STAR_TIDE`; every card, seal, detonation and effect uses them. The detonations are Shatterpoint, Glacial Rupture, Dawnburst and Astral Chorus, with the numbers in §2.
- **Card finishes** read as Plain Vellum, Gilded Leaf and Star-Inked Vellum. Save files keep the old variant keys (`shiny_foil`, `astral_prism`), so existing binders still load.
- **Bramblebridge** is the hub's name, with a greybox pass toward §1: stepped gables, a canal with a bridge, and a turning watermill wheel. Its files and network id stay `hub_town`.
- **The Cairnsman of Doverslap** is the first raid boss (`BossDummy`), fought in **The Ring of the Cairnsman** (the Phase 7 & 8 brief's name for the boss sanctum). Its files and network id stay `dungeon_dojo`.

**Built in Phases 9 and 10** (see 07_EXPEDITION_HUD_AND_ART_GDD.md §5)
- The 3x3 Callings, with the names in §3 and the Secondary modifiers above.
- The expedition trail: the Ariundle Moss-Oaks, the Sunken Holloway, the Doverslap Gorge Bridge with its gatehouse and paper-mill wheel, and the Ring of the Cairnsman. Bramblebridge Green is the hub's spawn green.

**Built in Phase 11** (see 10_WORLD_ARCHITECTURE.md §6)
- **The Bramble-Reach**, the first seamless region: Bramblebridge and the expedition joined as 128 m Landblocks. Walk out of the village's open Forest Gate, under the Moss-Oak Great Arch, all the way to the Ring of the Cairnsman. The game now starts there; the Raid Portal still leads to the instanced expedition.
- The Sinaya Mill-Castle and the Wadden-Green appear only as far silhouettes on the crags round the corridor.

**Design only, not built yet**
- The other regions (the Wadden-Green, Millwater Reach, Luka-Bay, Tizzi-Wed, the Saffron Cliffs, Sinaya Mill-Castle and Corvin Bridge-Keep) as places to walk.

**Naming decisions**
- **The Callings are named as in §3** (Creative Director, 2026-11-01). The Phase 7 & 8 brief used other names (Bastion-Ward, Iron-Gable, Cairn-Breaker, Edgerunner, Carillon Guard, Gale-Warden, High-Scribe); those are retired. Use the §3 names in code and copy.
- **The currency is Chimes** (07 GDD §1.2): octagonal brass wayfarer coins. "Dojo Shards" is retired.
