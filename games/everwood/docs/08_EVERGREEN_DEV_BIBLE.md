# 08_EVERGREEN_DEV_BIBLE.md — The Binding Design, Lore, & Engineering Protocol

> **SYSTEM DIRECTIVE FOR GEMINI & CLAUDE CODE:** This document is the authoritative production contract for *Everwood*. Every time a new feature, island, heritage, card folio, dungeon, profession, or game mode is proposed, it MUST pass through all five stages and all five mandatory gates defined below before code is committed.

---

## 1. The Five Mandatory Design Gates (Enforced on Every Request)

Whenever a new feature or content expansion is requested, Gemini must automatically evaluate the concept against these five non-negotiable gates:

| Gate ID | Name & Studio Pedigree | Mandatory Rule | Hard Rejection Trigger (Auto-Cut) |
|---|---|---|---|
| **GATE 1** | **Anti-Parasitic Harmony**<br>*(Mark Rosewater — WotC)* | Every new mechanic must directly feed into at least **two** existing core pillars: (1) Stamina/Poise, (2) The Four Signs, (3) The $3 \times 3$ Calling Trinity, or (4) The **Chimes** & Scribe Vellum economy. | Mechanics that introduce isolated currencies, standalone mini-games, or bespoke status effects that do not interact with the Four Signs. |
| **GATE 2** | **The Musk Razor**<br>*(Cut Deep, Add $10\%$ Back)* | Strip away all secondary menus, cooldown bloat, and extra keybinds. All combat and world interactions must execute through the existing **6-Posture Controller Contract** (`Light`, `Heavy`, `Forward+Heavy`, `Back+Heavy`, `L Guard`, `R Skill`, `L+R Ult`, `D-Pad Tether`). | Any feature requiring a new controller button, a mid-combat scrolling menu, random mid-fight card draws, or weightless hack-and-slash juggling. |
| **GATE 3** | **Philological & Whimsy Linter**<br>*(Tolkien, Miyazaki, Lionhead)* | All proper nouns must derive from our 4 Archipelago cultures (Dutch/Flemish, Dalmatian/Croatian, Amazigh/Moroccan, Carpathian) evolved into warm, bouncy Anglo-folk compounds. | Clinical/corporate words, harsh guttural clusters, grimdark clichés, or names that fail the **8-Year-Old First-Read Smile Rule**. |
| **GATE 4** | **Schema-First Registry**<br>*(Chris Wilson — GGG)* | New content is added as typed `Resource` data registered in central catalogs (`ArsenalCatalog`, `InstanceManager`). Actors and `CombatDirector` resolve behavior polymorphically. | Adding hardcoded `match` branches inside `ActorBase` or `CombatDirector` for specific item IDs, card IDs, or boss names. |
| **GATE 5** | **Code-First & Multi-Age Safe**<br>*(Yoshi-P & CLAUDE.md)* | All scenes build deterministically in GDScript (`tools/build_levels.gd`), maintain $4.8\text{ m}$ camera / $3.2\text{ m}$ max obstacle sightlines, and support all 3 player assist tiers (Master, Adventurer, Squire/Apprentice). | Hand-editing `.tscn` sub-resources, placing tall visual blockers in combat lanes, or designing boss mechanics that an assisted 4-year-old cannot survive. |

---

## 2. The 5-Stage Evergreen Development Loop

Every feature, from ideation to `main` branch commit, follows this strict five-stage pipeline:

### Stage 1: Ideation, Research Counter-Argument, & Musk Razor (Gemini + Producer)
1. **Industry Post-Mortem Audit:** Gemini researches how comparable RPG/MMO systems succeeded or failed, presenting counter-arguments against potential design traps.
2. **Harmonization & Linter Pass:** Gemini applies Gates 1–3, aligning mechanics with the Four Signs (`Sign of Iron-Root`, `Sign of Rime-Gale`, `Sign of Warm-Hearth`, `Sign of Star-Tide`) and linting all proper nouns.
3. **Mathematical Pre-Check:** Gemini verifies numbers against `docs/04_BALANCE.md` (ensuring boss poise staggers occur every $35\text{–}45\text{ s}$ and TTK stays within target raid windows).
4. **Deliverable:** A self-contained `docs/0X_[FEATURE]_GDD.md` artifact + a staged `ultrathink` Claude Code prompt.

### Stage 2: Schema-First Registry & Component Architecture (Claude Code — Plan Mode)
1. **Resource Definition First:** Define or extend strongly typed `Resource` classes in `src/resources/` with named tuning constants at the top of the script.
2. **Catalog Registration:** Register new definitions by `StringName` ID in `ArsenalCatalog` (or the relevant domain catalog) so ENet RPCs and save files only serialize lightweight `StringName` keys.

### Stage 3: Code-First Kishōtenketsu Implementation & Bot Verification (Claude Code — Build)
1. **Procedural Scene Generation:** Update `tools/build_levels.gd` and `ActorVisuals` to construct 3D geometry, shaders, and encounters in code (checking `res://assets/models/<id>.glb` for optional 3D model overrides).
2. **Kishōtenketsu Pacing (For Zones/Dungeons):**
   - **Zone 1 (Introduction):** Safe outdoor trail & minion camps introducing the new mechanic at low stakes.
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
1. **The Rule of Three:** Whenever a third instance of a pattern is created (e.g., 3rd boss, 3rd island, 3rd crafting station), extract shared behavior into a reusable component before starting the next feature.
2. **Memory & Leak Audit:** Confirm zero orphan nodes, zero circular `Resource` references, and clean ENet 2-process synchronization before pushing atomic commits to `main`.

---

## 3. Architectural Contracts for the Six Expansion Pillars

| Expansion Pillar | Required Resource Schema | Central Registry / Autoload | Mandatory Harmony & Gameplay Rule |
|---|---|---|---|
| **1. Character Heritages**<br>*(Wadden-Green, Luka-Bay, Tizzi-Wed, Hazel-Weald)* | `HeritageResource`<br>(`src/resources/heritage_resource.gd`) | `ArsenalCatalog` | Grants distinctive folk attire silhouettes in `ActorVisuals`, a folk epithet, and 1 world utility knack. **Never** locks out any of the 9 Callings or 4 Weapon Types. |
| **2. New Islands**<br>*(Archipelago Expansion)* | `IslandManifestResource`<br>(`src/resources/island_manifest_resource.gd`) | `InstanceManager` | Reached via lugger-boat dock transitions in isolated `World3D` instances. Reuses the universal Hub Scribe Desk, Chime-Shrine, and **Chimes** economy. |
| **3. Equipment & Card Folios**<br>*(12-Card Scribe Sets)* | `EquipmentItemResource` & `ScribeCardResource` | `ArsenalCatalog` | Every new card uses the 4 Signs, Plain/Gilded-Leaf/Star-Inked finishes, and composable Under-Card verbs. Weapon delivery always obeys *"The Weapon Channels the Card."* |
| **4. Open-World Trails**<br>*(Bale-Ways to Holloways)* | `ZoneBiomeResource`<br>(`src/resources/zone_biome_resource.gd`) | `tools/build_levels.gd` | Visually reflects trade volume (flagged Bale-Ways $\rightarrow$ sunken Holloways $\rightarrow$ sheep-stile deer-runs). Includes Miyazaki mundane magic props (Water-Shrines, Wind-Lanterns). |
| **5. New Raid Dungeons**<br>*(3-Zone Expeditions)* | `BossEncounterResource`<br>(`src/resources/boss_encounter_resource.gd`) | `CombatDirector` & `build_levels.gd` | Strictly follows the 3-Zone Kishōtenketsu template and uses only the 4 standardized `RaidTelegraphDecal` presets so kids never have to re-learn telegraph colors. |
| **6. Folksy Professions**<br>*(Mill, Press, Bell, Bakery)* | `ProfessionRecipeResource`<br>(`src/resources/profession_recipe_resource.gd`) | `ArsenalCatalog` & Hub Stations | Gather materials kineticly along Zone 1 trails into a **shared family pouch** (zero inventory grid management) to press Gilded-Leaf cards or bake pre-raid hearth buffs in town. |

---

## 4. The Master Roadmap (Phases 11–15)

- **Phase 11 — Persistent Family Profiles & Save System (`SaveManager`):** Local JSON/SQLite persistence saving each family member's Calling, Level, **Chimes**, unlocked Equipment, and collected Scribe Card Grimoire across sessions.
- **Phase 12 — Family Couch Playtest & Telemetry Balance Pass:** Real-world tuning of `docs/04_BALANCE.md` constants, camera framing, and assist tier responsiveness based on family playtests in Bramblebridge and Doverslap.
- **Phase 13 — Scribe Press Crafting & Family Card Trading:** Interactive Scribe Press in Bramblebridge to press duplicate Plain Vellum cards into **Gilded Leaf** variants, craft Under-Cards, and trade cards between siblings.
- **Phase 14 — The Archipelago Map-Table & Second 3-Zone Expedition:** Interactive boat-dock / map-table in Bramblebridge unlocking a second 3-zone expedition (*The Kamahi Goblin-Wood* or *The Saffron Cliffs of Tizzi-Wed*) with a new boss and 12-Card Scribe Folio.
- **Phase 15 — Curated CC0 `.glb` Models & Acoustic Soundscape:** Populate `res://assets/models/` with curated low-poly `.glb` meshes via `ActorVisuals` override hooks and upgrade synthesized cues to layered acoustic woodland and carillon audio.