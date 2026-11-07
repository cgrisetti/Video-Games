# 08_EVERGREEN_DEV_BIBLE.md — The Binding Design, Lore, & Engineering Protocol

> **SYSTEM DIRECTIVE FOR GEMINI & CLAUDE CODE:** This document is the authoritative production contract for *Everwood*. Every time a new feature, zone, heritage, card folio, dungeon, profession, or game mode is proposed, it MUST pass through all five stages and all six mandatory gates defined below before code is committed.

---

## 1. The Six Mandatory Design Gates (Enforced on Every Request)

Whenever a new feature or content expansion is requested, Gemini must automatically evaluate the concept against these six non-negotiable gates:

| Gate ID | Name & Studio Pedigree | Mandatory Rule | Hard Rejection Trigger (Auto-Cut) |
|---|---|---|---|
| **GATE 1** | **Anti-Parasitic Harmony**<br>*(Mark Rosewater — WotC)* | Every new mechanic must directly feed into at least **two** existing core pillars: (1) Stamina/Poise, (2) The Four Signs, (3) The $3 \times 3$ Calling Trinity, or (4) The **Chimes** & Scribe Vellum economy. | Mechanics that introduce isolated currencies, standalone mini-games, or bespoke status effects that do not interact with the Four Signs. |
| **GATE 2** | **The Musk Razor**<br>*(Cut Deep, Add $10\%$ Back)* | Strip away all secondary menus, cooldown bloat, and extra keybinds. All combat and world interactions must execute through the existing **6-Posture Controller Contract** (`Light`, `Heavy`, `Forward+Heavy`, `Back+Heavy`, `L Guard`, `R Skill`, `L+R Ult`, `D-Pad Tether`). | Any feature requiring a new controller button, a mid-combat scrolling menu, random mid-fight card draws, or weightless hack-and-slash juggling. |
| **GATE 3** | **Philological Linter & The Single-Origin Antagonist Rule**<br>*(Tolkien, Le Guin, Cooper, Miyazaki — [15_THE_MYTHOPOETIC_LENS.md](15_THE_MYTHOPOETIC_LENS.md))* | Every proper noun passes **The Four Linter Rules**: **(1) 8-Year-Old Read-Aloud** — it rolls off a child's tongue on the first read, with a smile; **(2) Map-Sense Compound** — every settlement and zone pairs a warm syllable with one of seven geographical nouns: `-bridge`, `-green`, `-hollow`, `-falls`, `-haven`, `-wick`, `-crossing`; **(3) Hyphens & Cadence** — keep bouncy compounds hyphenated (`Tizzi-Wed-Green`, `Bramble-Bridge`, `Rush-Light-Hollow`, `Old-Hob-of-the-Hill`, `Hedge-Runner`), never flattened, except the Creative Director's named exceptions below; **(4) Ban Grimy/Textbook Words** — no *Wharf, Silt, Polder, Lamellar, Hauberk, Cuirass, Rubric, Aspect, Construct, Rune, Vermin, Trash Mob, Dojo Shards*; use *Green, Bridge, Meadow, Mantle, Coat, Ring-Coat, Kettle-Cap, Sign, Ink, Deep-Ink, Seal, Maker-Seal, Iron-Man, Weald-Wight, Hedgerow-Hob, Boggart-Kin, Chimes*. **The Single-Origin Antagonist Rule:** every foe is a spirit of **The First-Quiet** (the Deep-Hush) rising through a crack in the land, stirred by **Old-Hob-of-the-Hill**; it sits on the Hob-to-Boggart Spectrum and is un-boggarted, never slain. | Clinical or corporate words, harsh guttural clusters, grimdark clichés, a name that fails the read-aloud smile, a place name with no Map-Sense noun, or any foe from a second origin: orc, goblin or lizard races, bandit or cultist factions, the undead, mob spam, or a disembodied dark lord. |
| **GATE 4** | **Schema-First Registry**<br>*(Chris Wilson — GGG)* | New content is added as typed `Resource` data registered in central catalogs (`ArsenalCatalog`, `InstanceManager`). Actors and `CombatDirector` resolve behavior polymorphically. | Adding hardcoded `match` branches inside `ActorBase` or `CombatDirector` for specific item IDs, card IDs, or boss names. |
| **GATE 5** | **Code-First & Multi-Age Safe**<br>*(Yoshi-P & CLAUDE.md)* | All scenes build deterministically in GDScript (`tools/build_levels.gd`), maintain $4.8\text{ m}$ camera / $3.2\text{ m}$ max obstacle sightlines, and support all 3 player assist tiers (Master, Adventurer, Squire/Apprentice). | Hand-editing `.tscn` sub-resources, placing tall visual blockers in combat lanes, or designing boss mechanics that an assisted 4-year-old cannot survive. |
| **GATE 6** | **The 70-20-10 Linguistic Linter**<br>*(Clay Grisetti — Oakshire Farms Studio)* | Every feature name, proper noun, and combat mechanic must satisfy the 70-20-10 linguistic ratio:<br>• **70% — The 8-Year-Old Joy Test:** Grounded, visceral English words that evoke immediate emotional or physical understanding.<br>• **20% — Gamer Shorthand:** Established industry-standard video game lexicons that cross-pollinate from co-op RPGs.<br>• **10% — Everwood Originality:** Custom, invented heritage terminology anchored in world-building lore and family motifs (*Þegn-Wedd*, vellum, ink, cairns, hearths), used sparingly.<br>*(Living Room Test: If you would feel slightly silly saying it out loud to a friend while sitting on the couch eating pizza, it fails the linter. Strip it down until it sounds like something from an 89-minute classic family adventure movie.)* | Over-crafted pseudo-archaic folklore pastiche, clinical Greco-Latin textbook terms, or unpronounceable high-fantasy jargon that breaks playground clarity. |

> **Gate 3's named exceptions (Creative Director, 2026-11-06):** **Doverslap** (Doverslap Bridge, Doverslap Falls, the Doverslap Gatehouse; once Dover-Slap), **Moss-Oak Hollow** (once Moss-Oak-Hollow) and **Miller's Oak** (the starting isle, once Oakshire Holm) are kept as the Creative Director named them, though they flatten a hyphen, drop one, or carry no Map-Sense noun. `tools/test_mythopoetic_lens.gd` lists them in `CD_NAME_EXCEPTIONS`; every other name still answers to all four rules. Ids, node names and save keys keep the old spellings (`dover_slap_falls`, `moss_oak_hollow`, `oakshire_holm`).
>
> **Gate 6 in the build (Phase 12 Kaizen, 2026-11-04):** the on-screen words it retired are gone from `src/`, and `tools/test_phase12_kaizen.gd` fails the smoke test if one comes back in a string that can reach the screen: *Vellum, Folio, Weapon-Coat, Ward-Mantle, Bravery Counter, Hearth-Rite Tuck, Four-Sign, Sign-Coat, Ink-Wheel, Glimmer-Spot, Action-Leaves*. Players now read *Plain Ink, Gilded Leaf, Star-Ink* (finishes), *Ink Blade, Ink Shield* (how a card shows itself), *PARRY & STRIKE!* (the old Bravery Counter), *INK READY* (the old Hearth-Rite Tuck), *the Ink Card Collection*, *Make Ink Cards* and *the Four Ink-Signs*. Ids, class names, node names and save keys keep their old spellings, so saves and network messages are unchanged.

---

## 2. The 5-Stage Evergreen Development Loop

Every feature, from ideation to `main` branch commit, follows this strict five-stage pipeline:

### Stage 1: Ideation, Research Counter-Argument, & Musk Razor (Gemini + Producer)
1. **Industry Post-Mortem Audit:** Gemini researches how comparable RPG/MMO systems succeeded or failed, presenting counter-arguments against potential design traps.
2. **Harmonization & Linter Pass:** Gemini applies Gates 1–3 and Gate 6, aligning mechanics with the Four Signs (`Sign of Iron-Root`, `Sign of Rime-Gale`, `Sign of Warm-Hearth`, `Sign of Star-Tide`) and linting all proper nouns.
3. **Mathematical Pre-Check:** Gemini verifies numbers against `docs/04_BALANCE.md` (ensuring boss poise staggers occur every $35\text{–}45\text{ s}$ and TTK stays within target raid windows).
4. **Deliverable:** A self-contained `docs/0X_[FEATURE]_GDD.md` artifact + a staged `ultrathink` Claude Code prompt.

### Stage 2: Schema-First Registry & Component Architecture (Claude Code — Plan Mode)
1. **Resource Definition First:** Define or extend strongly typed `Resource` classes in `src/resources/` with named tuning constants at the top of the script.
2. **Catalog Registration:** Register new definitions by `StringName` ID in `ArsenalCatalog` (or the relevant domain catalog) so ENet RPCs and save files only serialize lightweight `StringName` keys.

### Stage 3: Code-First Kishōtenketsu Implementation & Bot Verification (Claude Code — Build)
1. **Procedural Scene Generation:** Update `tools/build_levels.gd` and `ActorVisuals` to build 3D geometry, shaders, and encounters in code (checking `res://assets/models/<id>.glb` for optional 3D model overrides).
2. **Kishōtenketsu Pacing (For Zones/Dungeons):**
   - **Zone 1 (Introduction):** Safe outdoor trail & Hush-Cracks of slumbering kin introducing the new mechanic at low stakes.
   - **Zone 2 (Development/Twist):** Co-op threshold puzzle testing the mechanic asymmetrically (scaling to $\min(2, \text{party\_size})$).
   - **Zone 3 (Climax):** Boss sanctum combining the mechanic with `ThreatComponent`, Poise, and the 4 `RaidTelegraphDecal` presets (`RED_AVOID`, `GOLD_STACK`, `GREEN_HEAL`, `BLUE_BEHIND_TANK`).
3. **Automated Bot & Static Verification:**
   - Run `godot --headless --path . --check-only -s <script>` across $100\%$ of `.gd` files.
   - Add headless assertions to `tools/smoke_test.gd` and run `--fixed-fps 60`.
   - Render `--screenshot` frames for visual inspection.

### Stage 4: The 15-Minute Family Couch Playtest & Loopback (Producer + Family)
1. **Live Feel Check:** Playtest the build on controllers/keyboards across age tiers.
2. **Multimodal Loopback:** Upload Claude's verification screenshots and playtest notes back into Gemini for a **Split-Screen Squint & Game-Feel Audit**, generating a surgical constant-tuning prompt if needed.

### Stage 5: Amortized Technical Debt & Rule-of-Three Refactor (Claude Code — Gate)
1. **The Rule of Three:** Whenever a third instance of a pattern is created (e.g., 3rd boss, 3rd zone, 3rd crafting station), extract shared behavior into a reusable component before starting the next feature.
2. **Memory & Leak Audit:** Confirm zero orphan nodes, zero circular `Resource` references, and clean ENet 2-process synchronization before pushing atomic commits to `main`.

---

## 3. Architectural Contracts for the Six Expansion Pillars

| Expansion Pillar | Required Resource Schema | Central Registry / Autoload | Mandatory Harmony & Gameplay Rule |
|---|---|---|---|
| **1. Character Heritages**<br>*(Tizzi-Wed-Green, Gull-Wick-Haven, Barley-Bridge-Meadow, Barrow-Crag-Crossing)* | `HeritageResource`<br>(`src/resources/heritage_resource.gd`) | `ArsenalCatalog` | Grants distinctive folk attire silhouettes in `ActorVisuals`, a folk epithet, and 1 world utility knack. **Never** locks out any of the 9 Callings or 4 Weapon Types. |
| **2. New Zones**<br>*(The Six-Zone Atlas)* | `ZoneManifestResource`<br>(`src/resources/zone_manifest_resource.gd`) | `InstanceManager` | Reached along the sunken lanes (or by lugger-boat to Gull-Wick-Haven) in isolated `World3D` instances; each wakes its own kin of the First-Quiet with its own nursery rhyme. Reuses the universal Hub Scribe Desk, Chime-Shrine, and **Chimes** economy. |
| **3. Equipment & Card Folios**<br>*(12-Card Scribe Sets)* | `EquipmentItemResource` & `ScribeCardResource` | `ArsenalCatalog` | Every new card uses the 4 Signs, Plain/Gilded-Leaf/Star-Inked finishes, and composable Under-Card verbs. Weapon delivery always obeys *"The Weapon Channels the Card."* |
| **4. Open-World Trails**<br>*(Bale-Ways to Sunken Lanes)* | `ZoneBiomeResource`<br>(`src/resources/zone_biome_resource.gd`) | `tools/build_levels.gd` | Visually reflects trade volume (flagged Bale-Ways $\rightarrow$ sunken lanes $\rightarrow$ sheep-stile deer-runs). Includes Miyazaki mundane magic props (Water-Shrines, Wind-Lanterns). |
| **5. New Raid Dungeons**<br>*(3-Zone Expeditions)* | `BossEncounterResource`<br>(`src/resources/boss_encounter_resource.gd`) | `CombatDirector` & `build_levels.gd` | Strictly follows the 3-Zone Kishōtenketsu template and uses only the 4 standardized `RaidTelegraphDecal` presets so kids never have to re-learn telegraph colors. |
| **6. Folksy Professions**<br>*(Mill, Press, Bell, Bakery)* | `ProfessionRecipeResource`<br>(`src/resources/profession_recipe_resource.gd`) | `ArsenalCatalog` & Hub Stations | Gather materials kineticly along Zone 1 trails into a **shared family pouch** (zero inventory grid management) to press Gilded-Leaf cards or bake pre-raid hearth buffs in town. |

---

## 4. The Master Roadmap (Phases 11–15)

- **Phase 11 — Persistent Family Profiles & Save System (`SaveManager`):** Local JSON/SQLite persistence saving each family member's Calling, Level, **Chimes**, unlocked Equipment, and collected Scribe Card Grimoire across sessions.
- **Phase 12 — Family Couch Playtest & Telemetry Balance Pass:** Real-world tuning of `docs/04_BALANCE.md` constants, camera framing, and assist tier responsiveness based on family playtests in Bramble-Bridge and Doverslap Falls.
- **Phase 13 — Scribe Press Crafting & Family Card Trading:** Interactive Scribe Press in Bramble-Bridge to press duplicate Plain Vellum cards into **Gilded Leaf** variants, craft Under-Cards, and trade cards between siblings.
- **Phase 14 — The Atlas Map-Table & Second 3-Zone Expedition:** An interactive map-table in Bramble-Bridge unlocking a second 3-zone expedition into one of the Lens's flagship zones—**`Gull-Wick-Haven`** (*Sea-Cave Scrays*), **`Barley-Bridge-Meadow`** (*Furrow Iron-Men*) or **`Barrow-Crag-Crossing`** (*Cairn-Drakes*)—with a new boss to un-boggart and a 12-Card Scribe Folio.
- **Phase 15 — Curated CC0 `.glb` Models & Acoustic Soundscape:** Populate `res://assets/models/` with curated low-poly `.glb` meshes via `ActorVisuals` override hooks and upgrade synthesized cues to layered acoustic woodland and carillon audio.