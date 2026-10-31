# 01_VISION.md — Oakshire Raids: Executive Vision & Design Principles

## 1. Executive Summary & Mission Statement
**Oakshire Raids** is an authoritative, Godot 4.7-powered cooperative action-RPG engineered from the ground up for a 5-player family party—seamlessly uniting up to 4-player local split-screen with LAN/online multiplayer across instanced hub towns and raid dungeons. 

Our mission is to fuse the tactile directional combo flow of *Black Desert Online* and the stamina-driven, hitbox-committed weight of *Dark Souls* with the interdependent Tank-Healer-DPS raid mechanics of *World of Warcraft* and the accessible action-queue/tactical assist systems of *Knights of the Old Republic*, empowering veterans and young children alike to master readable boss encounters, execute interlocking cross-class synergies, and share the triumph of progression together on the couch and across the network.

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