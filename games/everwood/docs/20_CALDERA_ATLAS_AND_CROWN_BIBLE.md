# 20 — THE CALDERA ISLES & THE CROWN (AUTHORITATIVE WORLD BIBLE)

> **Visual Reference PDFs (located in `docs/atlas_sources/`):**
> - `01_council_ruling_caldera.pdf` & `02_master_atlas_caldera_isles.pdf` (Macro World)
> - `03_design_and_game_theory_loop_musk_razor.pdf` (the Crown's council ruling) & `04_master_crown_heart_crag.pdf` (Zone 5 / Master Crown)

---

## PART I: THE CALDERA ISLES (MASTER ATLAS V1)
**Architecture Budget:** `5 Grids` · `4 Load Seams` · `4 World Flags` · `1 Ebb Flag` · `1 Seam Scene (2 Skins)` · `0 Extra Map Files`

### 1. Geological & Economic Spine (Tolkien + Hobb + Le Guin Synthesis)
1. **Drowned Caldera with One Breach (NW):** A collapsed volcano flooded by the sea from the north-west (**The Breach**), explaining the cold current, NW gales, and sea-level shift.
2. **The Crown in the Center:** A resurgent volcanic dome with warm springs in the middle of **The Sound**, visible from every quay from minute one.
3. **Biomes from Rock & Exposure (Not Latitude):**
   - **Miller's Oak (South, Lv 1–6):** Sheltered lee shore on volcanic ash-loam orchards (`SIGN_WARM_HEARTH`).
   - **Iron-Ness (West, Lv 6–10):** Hydrothermal ironstone cliffs & over-delved mines (`SIGN_IRON_ROOT` · *Shield-Sworn*).
   - **Barrow-Eyot (East, Lv 8–12):** Sunken stretch of caldera rim gone to tidal fen (`SIGN_STAR_TIDE` · *Lantern-Bearers*).
   - **Rime-Firth (North, Lv 10–14):** High basalt rim facing The Breach; snow from altitude and sea-fog (`SIGN_RIME_GALE` · *Wayfarers*).
4. **Hub-and-Spoke Economy:** At Lv 6 (after clearing **Root-Sanctum**), all three trade lanes go dark. Oakshire grows food but lacks iron, lamp-oil, and fuel; every lane runs through **Hearthstead Market** (no outer-island ring lanes).
5. **Inner Shore vs. Outer Shore Rule:** Towns, steadings (**Forge-Gorge**, **Lantern Staithe**, **Gale-Hall**), quests, Beacons, and quays face the sheltered **Sound**; elites and sealed Raid Gates face the wild **Open Sea**.

### 2. Island Progression, Landmarks & Ebb Reveals
| Island | Level Band | Sign & Calling | Steading / Hub | Landmark Silhouette (from North Quay) | Bared at the Ebb (`-6.0m`) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Miller's Oak (S)** | Lv 1–6 | `SIGN_WARM_HEARTH` (Hub) | Hearthstead Market & North Quay | **Windmill** | **Old Quay Market** (North shore) |
| **Iron-Ness (W)** | Lv 6–10 | `SIGN_IRON_ROOT` (Shield-Sworn) | Forge-Gorge | **Forge Stacks** | **Raid A: Under-Forge Abyss** (sea-cave) |
| **Barrow-Eyot (E)** | Lv 8–12 | `SIGN_STAR_TIDE` (Lantern-Bearers) | Lantern Staithe | **Bell-Tower** | **Raid C: Sunken Cathedral** (sea door) |
| **Rime-Firth (N)** | Lv 10–14 | `SIGN_RIME_GALE` (Wayfarers) | Gale-Hall | **Snow Peak** | **Raid B: Frost-Peak Aerie** (whalers' stair) |
| **The Crown (C)** | Lv 15–20 | All Four Signs | South Bay Waypost | **World-Tree** | **Sea-Door -> The Heart** (True Raid) |

### 3. The 4 Seams & 4 World-State Flags
- **Seam 1 (`West Strait`):** Walkable causeway (NW Oakshire <-> SE Iron-Ness).
- **Seam 2 (`Eel Spit`):** Walkable shingle spit (NE Oakshire <-> SW Barrow-Eyot).
- **Seam 3 (`Salt Road`):** Lantern-Skiff bell lane (North Quay, Oakshire <-> Rime-Firth Quay).
- **Seam 4 (`Crown Landing`):** Lantern-Skiff bell lane (North Quay, Oakshire <-> South Bay, The Crown — opens when all 3 Beacons are lit).
- **1 Beacon = 3 Effects (`beacon_iron`, `beacon_tide`, `beacon_gale`):** Lighting an island's Beacon (1) reopens its trade lane and stocks its stall at Hearthstead Market, (2) calms its current (**Iron**, **Tide**, or **Gale Current**) around The Crown, and (3) grants its Scribe Sign.

---

## PART II: THE CROWN — THE HEART-CRAG (MASTER CROWN V1)
> **Redesigned in [docs/23](23_THE_CROWN_ZONE_REDESIGN.md):** four shore zones round **the World-Tree**, trials off the Ring Path, springs on it, a landmark, scout, kin and suite per shore. Part III below describes the first build.
**Architecture Budget:** `Zone 5 (Lv 15–20)` · `7 Areas` · `0 New Seams` · `0 Interior Gate Dungeons` · `+3 Trial Booleans`

### 1. Non-Negotiable Spatial & Game-Theory Rules
1. **One Landing (South Bay):** The gully cut by the summit stream—the only gentle landing on the dome. Houses the **Lantern-Bearers' Waypost** (respawn, repair, 1 vendor—**no town on the Crown**).
2. **The World-Tree in Sight from Every Step:** Tallest landmark for `5 km` at the `+65m` Summit Glade, fed by warm volcanic springs.
3. **The `+32m` Cliff Band & The One Stair:** The dome's cracked crust forms an honest `+32m` perimeter cliff wall; only **The One Cliff Stair** (South) climbs it, opening after all 3 trials.
4. **Three Open-Air Sign Shores (Any Order):** Each shore takes on the rock and current of its facing outer island and tests mastery of existing combat pillars (remix, not new systems).
5. **The Harmonic Bell & The `-6.0m` Ebb:** Hanging in the World-Tree at `+65m`. Every player must pull together (pure co-op coordination). Triggers the **10-second Ebb Cinematic**, ending the generation-long "Long Flood" by dropping the sea `6.0m` across all 5 islands.
6. **The Wound (Sap Galleries):** The old kingdom tapped the World-Tree's sap and drained it into the eastern sea (creating the blighted Star-Tide). The `-6.0m` Ebb bares the eastern **Sea-Door**, leading down through the underground **Sap Galleries** to **The Heart (True Raid, Lv 20)**.

### 2. The 7 Areas of The Crown
| # | Area | Level | Mechanics & Environment | Boolean / Payoff |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Landing & Waypost (S)** | Lv 15 | Arrive at South Bay gully, respawn, repair, 1 vendor | Entry anchor |
| **2** | **Ring Path** | Lv 15 | Perimeter trail below `+32m` cliff band; **3 Warm Spring Checkpoints** (SW, NW, SE) | Respawn checkpoints |
| **3** | **Iron Shore (W)** | Lv 15–18 | **Trial of the Anvil:** Posture & *Shatterpoint* (`SIGN_IRON_ROOT`); steam vents & **Old King's Town** ruins | `trial_anvil_complete` (Amber bough blooms) |
| **4** | **Gale Cliffs (N)** | Lv 15–18 | **Trial of the Gale:** Mobility & wind-shear (`SIGN_RIME_GALE`); **Old Sanctum Walls** facing The Breach | `trial_gale_complete` (Azure bough blooms) |
| **5** | **Tide Grottos (E)** | Lv 15–18 | **Trial of the Tide:** Darkness & cleansing (`SIGN_STAR_TIDE`); sap-drain channels | `trial_tide_complete` (Violet bough blooms) |
| **6** | **Cliff Stair -> Summit** | Lv 18–19 | Opens after 3 trials; climbs `+32m` wall to `+65m` Summit Glade; **all players pull Harmonic Bell** | `ebb_unlocked = true` (`-6.0m` sea drop) |
| **7** | **Sea-Door -> The Heart** | Lv 20 | Bared at the Ebb on outer East shore; **True Raid** through underground **Sap Galleries** | Final Raid Capstone |
---

## PART III: BUILD NOTES (2026-11-04)

What the game does today, from the Caldera brief (Phases 1 to 5), and where the build differs on purpose.

### 1. What's built

**Phase 1, the legacy maps.** The game boots into the Caldera Isles (`scenes/worlds/caldera_isles.tscn`, one node; `CalderaArchipelagoWorld` builds the rest in code). Oakshire Vale, the Bramble-Bridge landblock corridor and the classic hub moved to `deprecated/legacy_maps/` with their builders, data and tests. They still load with `-- --instance=oakshire_vale`, `bramblebridge` or `hub`, and the smoke test still runs their checks. Boot zones: `-- --boot-zone=oakshire` (the default, the Lee-Shore Orchards), `north_quay`, or `crown` (South Bay Landing, a playtest). In play, **F9** warps the party between the orchards and The Crown. North Quay's Crown Landing bell glides there once its lane is open.

**Phase 2, the state and the streaming.**
- `CalderaWorldState` (autoload `Caldera`) holds the eight booleans and the sea level. `can_land_on_crown()` and `cliff_stair_open()` are derived. The host decides every change and sends it to the other peers. The flags ride in the party's save (`[caldera] flags`, bits in `FLAGS` order). Playtest warps set `playtest`, and nothing changed while playtesting is saved.
- `CalderaAtlas` registers the five `IslandGridResource`s (12 x 12 landblocks of 128 m; The Crown 8 x 8) and the four `LoadSeamResource`s.
- `ArchipelagoStreamer` keeps one island live at the origin. Every landblock shows an 8 m stand-in with its trees and stones. A 3 x 3 window round the Soul Tether centroid, plus the landblock under every hero, gets the 2 m ground and its collider. The other four islands stand on the horizon as impostor silhouettes with their landmarks. One sea plane sits at `sea_level_y` and carries the three currents round The Crown, which calm as their Beacons are lit. Ground data is built on worker threads.
- `SeamTransitionController` is the one seam scene with two skins. Skin A (West Strait causeway, Eel Spit shingle spit): fog rolls in along the 128 m corridor, and at its middle the islands swap and the party walks on in the new island's frame. Skin B (Salt Road, Crown Landing): a rung Chime-Bell seats the party on a Lantern-Skiff for a six-second glide, swapping islands half-way.

**Phase 3, The Crown, the Heart-Crag (`CrownHeartCragBuilder`).** All seven areas at the brief's coordinates and heights:
1. South Bay Landing (1.4 m) with its pier and bell. The Lantern-Bearers' Waypost (+10 m): a shelter, a Saffron lantern, a respawn anchor, an anvil and one quartermaster.
2. The Ring Path, lantern-poled, and three warm springs (SW 12.6 m, NW 16.4 m, SE 11.0 m). Each is a respawn checkpoint and sends a +20 HP Warm-Hearth pulse to the party nearby.
3. Iron Shore: Old King's Town ruins, steam vents, and the Trial of the Anvil (two Forge-Clad Sentinels and the Anvil-Warden Colossus: poise 180, 88% of every blow glances off until its poise breaks, then 7.5x).
4. Gale Cliffs: Old Sanctum walls and the Trial of the Gale (three Rime-Wing Harriers and Storm-Caller Vaelen). A Breach Gale gathers for 1.6 s and blasts the arena about every 8 s, shoving anyone not in a wall's lee, not in a Shadow Sanctuary and not mid-dodge.
5. Tide Grottos: sap sluices and grotto arches, and the Trial of the Tide (three Tarnished Scribe-Wights and the Siphon-Prelate). Blight-mist drains 9 stamina a second outside a sanctuary until the three Sap-Siphon Totems are cleansed by a Star-Tide or Warm-Hearth detonation or card.
6. The +32 m cliff band, sheer all round (at least 71°, where heroes can climb 50°), cut only by the One Cliff Stair (18 to 32.5 m at 17°) behind its 3-Sign Resonance Barrier. Above it the dome climbs to the +65 m Summit Glade, the World-Tree and the Harmonic Bell. Each trial done blooms one bough (one shader parameter, shared by the far silhouette every other island shows) and lights one barrier seal.
7. The Sea-Door at -4.5 m in a cove on the east shore. At the Ebb, the party gathered at it goes down into the Sap Galleries, a tunnel under the cliff band to the Heart's chamber at -15 m and the True Raid's portal.

**Phase 4, the other four islands.** `OakshireHolmBuilder`: the orchards and the Windmill, Hearthstead Market (the Chime-Alchemist, the Blacksmith, the Innkeeper, the Calling Tutor, and the Iron, Lantern and Provisions stalls, shuttered until their Beacons burn), the Root-Sanctum, North Quay with both bells, the Old Quay Market on its -4 m shelf, and both causeway aprons. `FrictionIslesBuilder`: Iron-Ness, Barrow-Eyot and Rime-Firth, each with its arrival, steading and elder, and its Beacon and guardians on the sheltered inner shore. Its landmark (Forge Stacks, Bell-Tower, Snow Peak), kin camps and sealed raid gate at -4.5 m are on the wild outer shore.

**Phase 5, the HUD.** No minimap and no quest arrows in the Caldera (the Atlas on M still opens). One world banner on every screen when the lanes go dark, a Beacon is lit, a trial is done or the Long Flood ends. The Harmonic Bell needs every human hero to pull within 2.5 s. It plays the 10-second Ebb cinematic (four shots across the archipelago, letterboxed) while the sea falls from 0 to -6 m.

**Checks.** `tools/test_caldera_isles.gd` (43 checks, run last by the smoke test, or alone by `tools/run_caldera_checks.gd`) covers the brief's six smoke gates.

### 2. Deliberate differences (calls for the Creative Director)

1. **Paths and names follow the engineering contract.** The brief's `res://scripts/world/CalderaWorldState.gd` style became `src/world/caldera/caldera_world_state.gd`, keeping the brief's class names.
2. **The legacy maps are quarantined, not deleted.** The landblock streamer they share (`WorldGridManager`, `LandblockTerrain`...) stays in `src/world`; the Caldera doesn't use it. Their smoke checks still run, because the classic combat checks live in the hub and the expedition.
3. **The Root-Sanctum is the existing expedition.** Its door is a Raid Portal into the Doverslap Falls Expedition. Lulling the Cairnsman there (entered from the Caldera) sets `root_sanctum_cleared`. No new Lv 6 boss was built.
4. **The Atlas's old-tongue names are kept** (Holm, Ness, Eyot, Firth, Staithe, Quay), following the Council's "old-tongue names that describe the land". The Lens's Rule 2 lists only seven Map-Sense nouns, so these names are checked against Rule 4 (no banned words) and kept out of the Rule 2 and 3 list.
5. **Foe names linted.** "Forge-Clad Husk Sentinels" became "Forge-Clad Sentinels" (husk reads as undead, as the Lens pass did for the Moss-Shield Spriggan). The stair's "runes" became Sign-seals. Storm-Caller Vaelen is a Breach-wind spirit in a Wayfarer's shape, not a specter. "Siphon-Prelate" is kept as written.
6. **Level bands are labels.** The trail still ends at Level 10. The Crown's kin are tuned for a Level 10 party, and nothing is gated by level.
7. **"Grants the Sign"** is recorded as `CalderaWorldState.sign_granted()`. All four Signs were already playable from Level 1, so nothing new unlocks.
8. **The Sound is smaller than the atlas's scale bar.** Islands sit 1.2 to 3.1 km apart in the atlas's directions, and Caldera cameras see 4.6 km, so every landmark is in view from North Quay. The far silhouettes stand 1.6x taller than life so a 60 m landmark still reads at 2-3 km. The biomes' fog is thinned to 0.28x over the open sea, and the low height-fog lies on the sea wherever it stands (it falls with the Ebb, and lifts away in the galleries).
9. **The islands borrow existing looks and scores.** Oakshire-Wick, Quarry-Wick, Nine-Stones-Crossing, Gull-Wick-Haven and Sunken-Crown-Falls; no new biomes or music yet.
10. **The Sap Galleries are entered through a gathered threshold** (like a portal, without a load). A height-field ground can't hold a tunnel mouth.
11. **Raid Gates A, B, C and the Heart's True Raid are built, sealed and bared, but their raids aren't** (each says so). They're the next milestones.
12. **Deep water:** out of your depth for 1.2 s, the tide carries you back to the last dry ground. There's no swimming.
13. **Not built:** Iron Shore's warm updrafts (the vents are visual only). The North Quay bells don't show three breaking chains.
14. **Screenshots:** headless Godot doesn't render, so the visual gate used a windowed probe.
15. **Online:** world changes, seam swaps, skiffs, thresholds and the bell are host-decided with RPCs, but no ENet run has tested them yet.
16. **`docs/14_EVERWOOD_WORLD_MAP_BIBLE.md`** (untracked, written for C#) gives Miller's Oak a larger crescent with different coordinates. It has an open-air Root-Sanctum boss, seven booleans and a different stall list. The build follows the brief and the PDFs; that doc is untouched.
