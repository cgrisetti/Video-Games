# 07_EXPEDITION_HUD_AND_ART_GDD.md — Bramblebridge, The 3x3 Callings, Cross-Grimoire HUD, Doverslap Expedition, & Storybook Art Direction

## 1. Pillar 1: Immediate Fixes — Bramblebridge Navigation, "Chimes" Currency, & The $3 \times 3$ Callings

### 1.1 Walkable Bramblebridge Village Layout (`src/levels/hub_town.gd` & `tools/build_levels.gd`)
Because *Everwood* has no jump button (`Space` / gamepad `✕` is dedicated to the stamina-based Dodge Roll), every bridge, threshold, and stair in **Bramblebridge** must be seamlessly walkable via ground movement:
- **Smooth Arched Bridge Colliders:** The stone canal bridge in Bramblebridge uses low-angle ramp colliders ($\le 25^\circ$) with `ActorBase.floor_snap_length = 0.35` and `ActorBase.floor_max_angle = deg_to_rad(50.0)` so players never snag on collider lips.
- **Logical Village Flow:**
  1. **South Bank (Spawn Green):** Players arrive on the cobbled canal green facing the arched stone bridge of Bramblebridge.
  2. **North Bank (The Village Square):** Walking over the bridge leads directly to the **Armory & Scribe Desk** (where players swap Weapons, Armor Weight, Scribe Cards, and their $3 \times 3$ Calling) and the **Chime-Shrine** (where players spend **Chimes** for permanent stat upgrades), surrounded by stepped-gable brick houses, a puffing bakery oven, and drying pigment bundles.
  3. **Northern Forest Gate (The Expedition Portal):** The **Raid Portal** sits at the northern timber gate leading out into the **Ariundle Moss-Oaks**, preventing accidental portal triggers while exploring town.

### 1.2 Official Currency: **Chimes** (Replacing "Dojo Shards")
- **Lore & Audio-Visual Identity:** All UI labels, chest pickups, upgrade prompts, and docs replace "Dojo Shards" with **Chimes** (octagonal brass wayfarer coins stamped with a central square hole and strung on a belt-cord).
- **In-Game Feedback:** When dropped by minion packs, chests, or **The Cairnsman of Doverslap**, **Chimes** scatter as gleaming brass octagons and play a crisp, musical two-note brass bell chime as they magnetize into the party's satchels.

### 1.3 The $3 \times 3$ Matrix of Callings (`ClassLoadoutComposer`)
Every hero selects a **Primary Fellowship** (locking in their Raid Trinity Seat: Tank, DPS, or Mender) and a **Secondary Calling** (applying a composable stat, off-hand, and equipment modifier):

| Primary Fellowship (Row) | **`+ TANK` (Stout Heart)** | **`+ DPS` (Swift Foot)** | **`+ MAGIC` (Wise Hand)** |
|---|---|---|---|
| **The Shield-Sworn** *(Tank Primary: $160$ HP, $\times 3.0$ Threat, `Shadow Sanctuary`)* | **1. Bastion-Ward** *(Keeper of the Stone-Span)* | **2. Weald-Captain** *(Vanguard of the Green Company)* | **3. Iron-Gable** *(Watcher of the Kindled Stone)* |
| **The Wayfarers** *(DPS Primary: $100$ HP, $\times 1.0$ Threat, $+15\%$ Master Flow)* | **4. Cairn-Breaker** *(Hewn-Hand of the High Pines)* | **5. Edgerunner** *(Outrider of the Bramble-Ways)* | **6. Sign-Seeker** *(Journeyman of the Four Signs)* |
| **The Lantern-Bearers** *(Magic Primary: $110$ HP, $\times 0.8$ Threat, 4-Way `Soul Tether`)* | **7. Carillon Guard** *(Ringer of the Sanctuary Chime)* | **8. Gale-Warden** *(Weather-Worker of the Sound)* | **9. High-Scribe** *(Bearer of the Reed-Light)* |

#### Composable Secondary Modifiers (Applied to Primary Base Stats)
| Secondary Calling | Health Delta | Stamina Regen Delta | Combat Potency Modifier | Unlocked Gear & Sign Affinity |
|---|---|---|---|---|
| **`+ TANK` (Stout Heart)** | $+20.0\text{ HP}$ | $-2.0\text{ / s}$ | $+25\%$ Poise Damage & $+30\text{ ms}$ Perfect Guard window | Unlocks `HEAVY` Armor & `Sign of Iron-Root` bonus |
| **`+ DPS` (Swift Foot)** | $+0.0\text{ HP}$ | $+3.0\text{ / s}$ | $+15\%$ Weapon & Card Strike Damage | Unlocks `BOW` / `HEAVY_AXE` & `Sign of Rime-Gale` bonus |
| **`+ MAGIC` (Wise Hand)** | $-5.0\text{ HP}$ | $+2.0\text{ / s}$ | $+20\%$ Resonance Pip Gain & Heal/Shield Potency | Unlocks `STAFF`, $+1$ Grimoire Memory, & `Warm-Hearth` / `Star-Tide` bonus |

---

## 2. Pillar 2: Game-Design Overhaul — The Kid-Friendly Bottom-Centered HUD (`src/ui/player_hud.gd`)

### 2.1 Visual Reference & Core Layout
Using the attached **Cross-Hair / Cross-Grimoire HUD reference artifact**, remove the horizontal string of control help text at the bottom of the screen and replace it with a spatial, bottom-centered **Cross-Grimoire HUD** inside each player's viewport:

```text
               [ ♥ 160/160  ██████████ ]   [ ⚡ 100/100 ██████████ ]
                 Bastion-Ward · (◆)(◆)(◇) Pips · 🪙 45 Chimes

                                 ┌──────────────┐
                                 │  ▲ W+K / ↑△  │
                                 │ [IRON-ROOT]  │
                                 │  Gap-Closer  │
                  ┌──────────────┼──────────────┼──────────────┐
                  │  L2 / Q      │  ⚔️ + 🛡️      │  R2 / E (1◆) │
                  │ [ 🛡️ GUARD ] │Weapon Posture│ [WARM-HEARTH]│
                  │  Perfect 0.2s│  J:Lt  K:Hvy │  Role Skill  │
                  └──────────────┼──────────────┼──────────────┘
                                 │  ▼ S+K / ↓△  │
                                 │ [RIME-GALE]  │
                                 │  Back-Skill  │
                                 └──────────────┘
                                        +
                              [ ★ L2+R2 / R (3◆) ]
                              [   ULTIMATE CARD   ]
```

### 2.2 Zero-Reading Visual Affordances for Kids (Ages 4 to 12+)
1. **Posture Mirrors Physical Hands:**
   - **Center Hub:** Displays the equipped Weapon icon (`Light Sword`, `Heavy Axe`, `Staff`, `Bow`) + Off-Hand icon (`Greatshield`, `Tether-Lantern`, `Scribe Satchel`) for basic `Light` (`J` / `□`) and `Heavy` (`K` / `△`) swings.
   - **North Slot (`W+K` / `↑+△`):** `FORWARD_HEAVY` Lead Card + tucked Under-Card corner badge.
   - **South Slot (`S+K` / `↓+△`):** `BACK_HEAVY` Lead Card + tucked Under-Card corner badge.
   - **West Wing (`Q` / `L2`):** Protected **Guard / Perfect Guard** shield crest.
   - **East Wing (`E` / `R2`):** `TRIGGER_R_SKILL` Signature Role Card ($1\diamond$ Pip badge).
   - **Lower Crown (`R` / `L2+R2`):** `TRIGGER_BOTH_ULT` Ultimate Card ($2\text{–}3\diamond$ Pip badge).
2. **Sign Color Coding & Under-Card Corner Tuck:**
   - Each card frame is tinted by its **Sign**: Amber-Ochre (`Sign of Iron-Root`), Sea-Azure (`Sign of Rime-Gale`), Saffron-Gold (`Sign of Warm-Hearth`), or Twilight-Violet (`Sign of Star-Tide`).
   - If an **Under-Card** is slotted beneath a Lead Card, a diagonal ribbon in the bottom-right corner displays the Under-Card's Sign color.
3. **"Pop, Glow, & Pulse" State Feedback:**
   - **Pip Readiness:** Cards requiring Resonance Pips ($1\diamond$ or $3\diamond$) sit dimmed ($60\%$ opacity) and lowered by $6\text{ px}$ until the player has enough Pips; the instant enough Pips are earned, the card **slides up $6\text{ px}$ and illuminates with a golden border**.
   - **Input & Buffer Pulse:** Pressing a button or queueing a move in `ActionQueueComponent` scales the corresponding HUD slot to $1.15\times$ and flashes a crisp white highlight for $150\text{ ms}$.
   - **Healer Tether Compass:** For **The Lantern-Bearers**, a compact 4-way D-Pad compass sits beside the left wing, highlighting which party member holds the golden `Soul Tether`.

---

## 3. Pillar 3: Phase 3 (Repo Phase 9) — The Three-Zone Expedition Map

Evolve `tools/build_levels.gd` and `src/levels/dungeon_dojo.gd` from a single circular room into a continuous 3-Zone outdoor-to-sanctum raid journey (**The Doverslap Expedition**):

### Zone 1: The Ariundle Moss-Oaks & Sunken Holloway (The Whispering Approach)
- **Environment:** Players step out of the Bramblebridge portal onto a mossy oak trail that descends six feet between earthen banks into a root-arched **Sunken Holloway**. Hanging clay **Wind-Lanterns** sway, chime softly, and shed golden motes when players brush past or cast skills nearby.
- **Gameplay & Encounters:**
  - **2 Woodland Minion Camps:** Each camp spawns $3\text{–}4$ aggressive woodland creatures (*Bramble-Scuttlers* and *Holloway Imps*, built on `ActorBase` with $65\text{ HP}$ and $30\text{ Poise}$) so the family can practice multi-target weapon cleaves, ranged Bow/Staff kiting, AoE Taunts, and 4-Sign detonations before reaching the boss.
  - **Wayfarer's Water-Shrine:** A mossy spring basin under a tiny shingled roof midway down the trail; walking through its mist restores $100\%$ HP and Stamina to the party.
  - **Hidden Side Alcove:** A forked deer-run behind dry-stone walls holding a **Wayfarer's Chest** that bursts open for $+15\text{ Chimes}$ and an Uncommon Scribe Card.

### Zone 2: Doverslap Gorge Bridge & Sinaya Gatehouse (The Co-Op Threshold)
- **Environment:** The holloway emerges above a roaring waterfall chasm (*the Doverslap*) spanned by a soaring timber-and-stone trestle bridge inspired by *Corvin Castle* and *Peleș Castle*, complete with carved Carpathian timber turrets and a giant spinning wooden waterwheel pounding linen into Scribe vellum.
- **The Asymmetric Co-Op Threshold Puzzle:**
  - The timber gatehouse portcullis blocking Zone 3 is sealed, and a periodic **Gorge Gale-Jet** sweeps down the center of the bridge.
  - **Two Ways to Solve (Supports Solo + 2-to-5 Player Parties):**
    1. **Rune-Plate Synchronization:** Standing on the twin glowing Scribe Rune-Plates on either side of the bridge for $2.0\text{ s}$ lowers the portcullis (dynamically scaled to $\min(2, \text{active\_party\_size})$ plates, with Companion AI automatically taking the second plate if playing solo).
    2. **Shield-Sworn Heroics:** A Tank can raise `Shadow Sanctuary` (`Back + Heavy`) to physically block the **Gorge Gale-Jet**, creating a wind-sheltered corridor behind their shield so a sibling can walk up and ring the **Bronze Bridge-Bell Winch** to open the gate immediately.

### Zone 3: The Ring of the Cairnsman (The Warden's Sanctum)
- **Environment:** Beyond the timber gatehouse lies a sunlit, moss-ringed ancient stone causeway overlooking the waterfall spray.
- **Boss Encounter — The Cairnsman of Doverslap:**
  - **Phase 1 ($100\% \rightarrow 50\%\text{ HP}$):** Chases highest threat, executes `Crushing Swipe` ($0.85\text{ s}$ wind-up), and alternates `Crimson Bloom` (red dodge circles) with `Golden Communion` (gold stack circle scaled to $\max(1, \lfloor \text{party\_size} / 2 \rfloor)$).
  - **New Phase 2 Mechanic ($\le 50\%\text{ HP}$): `Doverslap Gale-Beam` (`BLUE_BEHIND_TANK`):**
    - The Cairnsman plants its boulder-fist and projects a `RaidTelegraphDecal` of type `BLUE_BEHIND_TANK` ($3.2\text{ s}$ cast) aimed at the highest-threat player, with a clear blue shield-pillar icon indicating **"Stand Behind the Tank!"**
    - When the cast finishes, a roaring torrent of waterfall mist and stone sweeps the lane: any player standing inside the Tank's `Shadow Sanctuary` cone takes $0\text{ damage}$ and earns $+0.5\text{ Pips}$, while exposed players in the beam take $40\text{ damage}$ and knockback.

---

## 4. Pillar 4: Phase 4 (Repo Phase 10) — Storybook Art Direction & Articulated Silhouettes

### 4.1 Code-First Articulated Multi-Mesh Puppets + `.glb` Asset Hook (`src/actors/actor_visuals.gd`)
To maintain $100\%$ compliance with `CLAUDE.md` (zero fragile hand-edited `.tscn` sub-resources) while supporting optional external 3D models:
1. **Procedural Storybook Multi-Mesh Rig (Default):**
   - Replace single capsules with articulated multi-mesh puppets constructed cleanly in GDScript (`Head`, `Headgear`, `TorsoTunic`, `Pauldrons`, `CapeMesh`, `MainHandMount`, `OffHandMount`):
     - **The Shield-Sworn:** Broad pauldrons, warden helmet/crest, heavy oilskin cape, and a banded oak-and-brass **Greatshield** on the left arm.
     - **The Wayfarers:** Feathered ranger hood/cap, fluttering forest travel cloak that pitches dynamically with movement velocity, and a side **Quiver / Scribe Satchel**.
     - **The Lantern-Bearers:** Pointed scribe hat or carillon hood, warm saffron-trimmed robe, and a swinging **Brass Tether-Lantern** emitting a warm `OmniLight3D` glow.
   - **The Cairnsman of Doverslap Rig:** Assembled from stacked, mossy river-boulder meshes, ancient bridge-timber crossbeams on its shoulders, heather tufts, a glowing amber core, and braided brass bell-ropes that swing during `Crushing Swipe`.
2. **Automatic `.glb` Override Hook:**
   - Before building procedural primitives, `ActorVisuals` checks `ResourceLoader.exists("res://assets/models/<actor_or_item_id>.glb")`. If a CC0 KayKit or Quaternius `.glb` file is dropped into `assets/models/`, it instantiates and binds automatically.

### 4.2 Wind Waker / Tunic Cel-Rim Shader & Sunlit Palette
- Create a shared `ShaderMaterial` (`src/actors/storybook_cel_shader.gdshader` or inline `Shader`) featuring:
  - **2-Band Toon Ramp:** Crisp sunlit highlights and warm, never-muddy shadows.
  - **Fresnel Silhouette Rim-Light:** High-contrast rim glow tinted by team/role color so all 4 split-screen viewports remain effortlessly readable from the $4.8\text{ m}$ camera eye-line.

---

## 5. Build Notes (Phases 9 and 10)

What the game does today, where it differs from the spec above, and what's still to come.

**In the code now**
- **Walkable Bramblebridge** (§1.1). The canal runs east to west across the village under a low stone arch: two 13° ramps and a flat crown, one convex collider flush with the ground at both ends, with parapets. Actors snap to floors within 0.35 m and climb up to 50° (`ActorBase`). The spawn green is south, the village square north (the Armory & Scribe Desk, the Chime-Shrine, a bakery with a smoking chimney, pigment racks), and the Raid Portal stands at the northern forest gate. Knee-high walls, rails and banks are on a `LowScenery` physics layer the cameras ignore.
- **Chimes** (§1.2). The currency, everywhere: the Chime-Shrine (`chime_shrine.gd`) replaces the Shard Vendor, chests and cleared camps burst into octagonal brass coins (`ChimeCoin`, `ChimeBurst`) that fly to the party with a two-note bell. Saves keep their old `shards` pouch as Chimes.
- **The 3x3 Callings** (§1.3). The three Secondaries and the nine Callings are typed data registered in the ArsenalCatalog (`SecondaryCallingResource`, `CallingResource`; 08 Gate 4): numbers, gear unlocks, trim colour, names and subtitles. `callings.gd` reads them and holds the gear rules; `ClassLoadouts.player_class(class_id, secondary)` applies them and `LoadoutComposer` scales every action. Each seat's Calling travels in the roster and is saved per Fellowship, by id (`stout_heart`, `swift_foot`, `wise_hand`; older saves with a number still load). Change it at the Scribe Desk's Fellowship and Calling rows, or hold C / L3 (Tab / View still changes Fellowship).
- **The Cross-Grimoire HUD** (§2). `CrossGrimoireHUD` and `CrossSlot`, bottom-centre in each split-screen cell, scaled to the cell. Sign-tinted frames, under-card corner ribbons, pip readiness (60% opacity and 6 px low until affordable, then a gold border and glow), a 1.15x white pulse for 150 ms on press or buffer, health, stamina, pip gems, Calling title, Chimes, and the Lantern-Bearer's tether compass. The line of control help is gone.
- **The Doverslap Expedition** (§3, repo Phase 9). `dungeon_dojo.gd` and `build_levels.gd`. Zone 1: the Moss-Oaks clearing, the Bramble Camp (3 Scuttlers), the alcove's Wayfarer's Chest, the ramp into the Sunken Holloway, root arches with Wind-Lanterns (`wind_lantern.gd`), the Water-Shrine (`water_shrine.gd`) and the Holloway Camp (3 Bog-Imps and a Scuttler); minions are `WoodlandMinion` on the enemy side, camps are `MinionCamp`. Zone 2: the trestle bridge with Rune-Plate bays, the waterfall, the paper-mill wheel, the Sinaya Gatehouse and its `CoopGate` (`RunePlate`, `BellWinch`, `GorgeGaleJet`). Zone 3: the causeway and the Ring. Checkpoints per zone; companions fight minions, take a plate, and catch up. The Cairnsman's Phase 2 adds the Doverslap Gale-Beam (`RaidTelegraphDecal` kind `BLUE_BEHIND_TANK`). While it's up, each player's HUD says what to do under the boss frame: "RAISE SHADOW SANCTUARY!" for the tank it's aimed at, "STAND BEHIND THE TANK!" for everyone else. In Squire Gambit, that tank turns and raises the shield by itself once the beam is a quarter full, and anyone else left in the lane outside a shield rolls clear at 85% (08 Gate 5).
- **Storybook art** (§4, repo Phase 10). `ActorVisuals` builds each hero's puppet by Fellowship, armor weight and Calling: the tunic keeps the seat's colour and a tabard front and back shows the Secondary's (bronze, green, violet), with a speed-driven cape and a working Tether-Lantern light; the weapons' parts were redrawn; the Cairnsman has boulder fists that swing with the swipe, swaying bell-ropes and an amber core that heats up in the wind-up; minions have their own bodies. `storybook_cel.gdshader` (two light bands, a Fresnel rim, a glow for hit flashes) is on actors, items and scenery, under a warm sun with Filmic tone mapping and a light haze. `ResourceLoader.exists("res://assets/models/<id>.glb")` swaps in a dropped model for a hero, weapon, armor, minion or the boss. Every code-made shape comes from one `ShapeKit` (08 Stage 5, the Rule of Three: ten scripts had their own copy).

**Deliberate differences from this spec**
- **Calling names.** The Creative Director chose the 06 §3 names on 2026-11-01 (Bridge-Warden, Weald-Captain, Hearth-Guard; Iron-Woodsman, Hedge-Runner, Sign-Seeker; Bell-Keeper, Wind-Mender, Lantern-Scribe), and kept them when the 08-alignment brief listed the §1.3 names again, so the game uses those; the subtitles are the same. All nine are registered in `ArsenalCatalog._build_callings()`.
- **Bog-Imps.** §3's Holloway Imps are Bog-Imps (id `bog_imp`), the Creative Director's pick; their camp is still the Holloway Camp, after the place.
- **`ClassLoadoutComposer`** is `ClassLoadouts` (Fellowship and starter kit) with `Callings` (the Secondary) and `LoadoutComposer` (kit to actions).
- **Gear rules.** Anyone may use the Falchion and light or medium armor; a Fellowship always has its own column's gear, so a Secondary's "unlock" matters for the cross Callings.
- **The Ultimate crown** sits in the cross's bottom-right corner (the brief allows a side crown) with the Roll chip bottom-left, so the cross stays three rows tall in four-way split-screen. The Fellowship, Calling and mode holds are shown in Bramblebridge's banner.
- **The Gorge Gale-Jet** shoves (5 m) but does no damage, and the Bell-Winch can only be rung from inside a Shadow Sanctuary cone; the tank holding the cone counts as sheltered for the Gale-Beam too.
- **The Gale-Beam's 40 damage** is before armor, like every telegraph's.
- **The Wayfarer's Chest's Uncommon card** comes from four new expedition-only Uncommon cards: Holloway Lunge, Root-Snare Step, Lantern Mote and Gorge Gale.
- **The weapons** now carry §4.1's names (Falchion, Broad-Axe, Rowan Way-Staff, Yew Longbow); their ids are unchanged, so kits and saves still load.
- **The puppets** are posed shapes with a swinging cape and lantern, not an animation rig.

**Against the 08 Dev Bible** (audited 2026-11-01)
- **Gate 2 (no new buttons).** Hold C / L3 to change Calling, added in Phase 9, is a new hold on an existing stick click. It's kept because it only works in Bramblebridge, but it brushes the gate; the Scribe Desk's Calling row does the same job.
- **Gate 4 (schema first).** Callings are now catalog data (above). Two of 08's expansion contracts, `BossEncounterResource` and `ZoneBiomeResource`, aren't built: there's one boss and one expedition, so by the Rule of Three they wait for the second and third.
- **Gate 5 (an assisted 4-year-old survives).** The Gale-Beam was the gap; Squire Gambit now shelters and dodges it (above), checked in the smoke test.
- **The four telegraph presets.** 08 names RED_AVOID, GOLD_STACK, GREEN_HEAL and BLUE_BEHIND_TANK. The game has three, named `CRIMSON_DODGE_OUT`, `GOLD_PARTY_SOAK` and `BLUE_BEHIND_TANK`; a green heal-zone preset isn't built yet.
- **Readability.** Words on screen no longer pile up: banners drop under the boss frame while it shows, and the Raid Portal ("Raid: The Doverslap Expedition") and the gate's "To the Ariundle Moss-Oaks" sign sit apart.

**Built since, in Phase 11** (10_WORLD_ARCHITECTURE.md §6)
- A latecomer joining mid-expedition now gets everything: `WorldStateDB` sends the cleared camps, the opened Wayfarer's Chest, the Water-Shrine's rest and the open gate in one snapshot.
- Companions, minions and demo bots follow a navigation mesh round walls, banks and ledges (one for the Dojo, one per chunk in the seamless world). Companions still skip ahead if they're stranded far behind.
- The whole expedition can also be walked from Bramblebridge in the seamless world, with no loading screen.

**Not built yet**
- No models ship in `assets/models/`; the hook is ready for CC0 packs.

