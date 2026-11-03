# 01_VISION.md — Everwood (Oakshire Raids): Executive Vision & Design Principles

## 1. Executive Summary & Mission Statement
*"Why do we climb mountains, trek through woods, explore caves, and dive for treasures in the sea? Because what is around the next corner is magic."*

**Everwood (Oakshire Raids)** is an authoritative, Godot 4.7-powered cooperative action-RPG engineered from the ground up for a 5-player family party—uniting up to 4-player local split-screen with LAN/online multiplayer across instanced hub towns and raid delves. It keeps the promise of Miyazaki, Susan Cooper and Ursula K. Le Guin: the world is crowded with spirits, the old rhymes are true, and heroism is the daily work of keeping a homestead warm.

Its one struggle is between **Domestic Stewardship (*The Making*)**—families who build bridges, plough straight furrows, ring chime-bells and name the hollows—and **The First-Quiet (*The Un-Making*)**, the un-named slumber of the earth that rises through cracks in the ground to smooth that noisy handiwork back into silent sleep. There are no evil races and no far-off dark lord: every foe is a spirit of the First-Quiet that has turned boggart, and every victory un-boggarts it rather than slaying it (see [15_THE_MYTHOPOETIC_LENS.md](15_THE_MYTHOPOETIC_LENS.md)).

Our mission is to fuse the tactile directional combo flow of *Black Desert Online* and the stamina-driven, hitbox-committed weight of *Dark Souls* with the interdependent Tank-Healer-DPS raid mechanics of *World of Warcraft* and the accessible action-queue/tactical assist systems of *Knights of the Old Republic*, so veterans and young children alike can master readable boss encounters, execute interlocking cross-Fellowship synergies, and share the triumph of progression together on the couch and across the network.

---

## 2. Core Design Pillars (The Four-Genre Synthesis)
1. **Black Desert Online (Tactile Flow):** Replaces sprawling 30-button hotbars with intuitive directional motion inputs (`Forward + Heavy`, `Back + Heavy`) and recovery-canceling combo chains that reward muscle memory.
2. **Dark Souls (Kinetic Weight & Commitment):** Attacks have undeniable physical impact. Stamina governs every dodge and swing; wind-up commitments and active weapon hitboxes make positioning and boss timing matter.
3. **World of Warcraft (The Holy Trinity & Raid Mechanics):** True cooperative interdependence where Tanks manage active threat and shielding, Healers manage strategic spatial tethers, and DPS execute coordinated cross-class synergy combos.
4. **Knights of the Old Republic (Accessible Tactical Assist):** Bridges the age gap (from adults down to a 4-year-old child) via a 2-slot input buffer and an optional 1-button KOTOR Gambit Assist system that automates combo routing and auto-evades boss red zones.

---

## 3. The Musk Razor: Ruthless Subtractions & 10% Replacements
To prevent combat from becoming a floaty, messy spreadsheet, we enforce Elon Musk’s First Principles engineering rule: **"Cut so deep that you are forced to add 10% back in."**

| What We Ruthlessly Cut | Why It Fails Family Co-Op | The Harmonized 10% Added Back In |
|---|---|---|
| **30-Slot Hotbars & GCDs (WoW)** | Forces players to stare at bottom screens instead of the action; impossible on a split-screen gamepad. | **Posture-Driven 6-Skill Loadout:** 3 basic inputs + 3 Posture Modifier triggers (`L`, `R`, `Both`). |
| **At-Will Animation Canceling (BDO)** | Destroys *Souls* weight and turns combat into mindless button-mashing. | **The Flow-Link Window:** 100% locked wind-up/active frames, but final recovery can be canceled into valid combo continuations. |
| **Tab-Targeting & Free-Aim Healing (MMO)** | Frustrating when family members are sprinting and dodging across a chaotic raid arena. | **Dual-Channel Smart Targeting:** Magnetic soft-cones for offense; 4-way D-Pad Soul Tethers for instant support. |
| **RNG Dice-Roll Misses & Pauses (KOTOR)** | Breaks physical immersion when a blade physically connects but rolls a "Miss". | **Deterministic Hitboxes + KOTOR Input Buffer:** If a hitbox overlaps a hurtbox, damage is absolute; inputs are buffered mid-swing. |
| **Orc/Goblin/Lizard Factions, MMO Mob Spam & Disembodied Dark Lords** | Codes whole peoples as born evil, turns the woods into a grinder of nameless bodies, and gives children a villain they can never meet or understand. | **The Mythopoetic Antagonist Razor:** one origin (*The First-Quiet*) and one wandering face (*Old-Hob-of-the-Hill*); **The Hob-to-Boggart Spectrum** (curious hobs you can greet as well as boggarts that fight), **Truce-Sign Parleys** (1-Button Gambit Assist within `6.0m`), and **Un-Boggarting Resolutions** (released as a sea-swallow, lulled into a cairn, or bowed into a steward—never a corpse). |
