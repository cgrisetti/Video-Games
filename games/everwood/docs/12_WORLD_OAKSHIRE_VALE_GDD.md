# EVERWOOD (OAKSHIRE RAIDS) — GDD: OAKSHIRE VALE STARTING ZONE
**Authoritative Specification | Godot 4.7 Engine | Post-Phase 10 Baseline**

## 1. Zone Scope & Dimension Architecture
* **Total Grid Footprint:** $1,536\text{m} \times 1,536\text{m}$ ($12 \times 12$ landblock chunks of $128\text{m} \times 128\text{m}$).
* **Playable Floor Area:** $1,280\text{m} \times 1,280\text{m}$ ($2.36\text{ km}^2$ / $0.91\text{ sq mi}$ / $25.4\text{M sq ft}$), surrounded by a $128\text{m}$ perimeter cliff and forest skirt.
* **Traversal Time:** End-to-end traversal takes approximately $3\text{ minutes } 30\text{ seconds}$ at standard player run speed ($6.0\text{ m/s}$).
* **Camera Budget:** Fully optimized for 4-player local split-screen rendering from a canonical $4.8\text{m}$ camera eye-line with a maximum active draw distance clip plane of $192\text{m}$ ($1.5$ chunks).

## 2. Topographical & Concentric Ecological Rings
* **Tier 0 — The River & Mill Basin ($0.0\text{m}$ to $+4.0\text{m}$ elevation):** Shallow wadeable ford ($0.4\text{m}$ water depth triggering wet footstep SFX without movement reduction), bridged by the stone span of the **Bridge-Warden**.
* **Tier 1 — The Settled Meadow & High Road ($+4.0\text{m}$ to $+14.0\text{m}$ elevation):** Undulating pastureland ($5^\circ$ to $12^\circ$ slopes) maintaining unobstructed $4.8\text{m}$ camera sightlines during 5-player melee combat combos.
* **Tier 2 — The Bramble Weald & Quarry Terraces ($+14.0\text{m}$ to $+32.0\text{m}$ elevation):** Stepped plateau shelves connected by wide natural stone ramps ($4.5\text{m}$ minimum width to prevent camera snagging).
* **Tier 3 — The Rim-Crags & Portal Aprons ($+32.0\text{m}$ to $+65.0\text{m}$ elevation):** Impassable vertical granite escarpments housing the four recessed dungeon and raid portal aprons.

## 3. Artifact & Prop Density Budgets (Per $128\text{m}$ Chunk)
* **Canopy Trees:** $18 \text{–} 28$ (Forest) / $3 \text{–} 6$ (Meadow); minimum $4.5\text{m}$ inter-trunk spacing; foliage canopy starts above $5.5\text{m}$ or fades via proximity shader.
* **Hero Landmark Trees:** 18 total across the zone ($12\text{m} \text{–} 18\text{m}$ trunk girth) marking sub-zone transitions and mini-boss arenas.
* **Boulders & Outcrops:** $4 \text{–} 8$ per chunk ($2.5\text{m} \text{–} 8.0\text{m}$ granite slabs providing hard collision and Line-of-Sight [LoS] cover for ranged enemy volleys).
* **Sign & Wayfinding Props:** Roadside Saffron/Amber Lantern-Poles and Scribe Runestones placed every $75\text{m}$ of roadway to guide players without minimap UI clutter.

## 4. Pinwheel Hub-and-Petal Basin Shape & Streaming Grid
* **Central Anchor:** **Oakshire Village** sits on a raised central saddle ($+12\text{m}$ elevation) backed by the Scribe's Tor ridge, occluding $50\%$ of distant horizon views.
* **Five Petal Valleys:** Radiating S-curve roads bend $35^\circ \text{–} 50^\circ$ around rock spurs within $110\text{m}$, ensuring the engine never renders beyond $220\text{m}$.
* **Active Chunk Window:** A $3 \times 3$ active chunk streaming matrix ($384\text{m} \times 384\text{m}$) centered on the party's **Soul Tether** keeps $9 \text{–} 16$ chunks in high detail (LOD0/LOD1) while background hills render as a static horizon mesh ($< 4,000$ triangles).

## 5. Friendly NPC & Offloaded Instance Roster
* **Quest Givers (18 Total):** Grouped into 3-quest hub bundles across Wayfarer's Glade, Oakshire Village, and 4 outlying petal camps.
* **Service Vendors (14 Total):** Weapon/Armor merchants (`Falchion`, `Broad-Axe`, `Rowan Way-Staff`, `Yew Longbow`), apothecaries, Chime-Vault bankers, and Calling Respec tutors.
* **Ambient Guards & Townsfolk (36 Total):** $16$ *Bridge-Warden*/*Hearth-Guard* sentries and $20$ ambient villagers running deterministic idle loops.
* **Offloaded Dungeon & Raid Portals (4 Total):**
  1. *The Smuggler's Root-Cellar* (`[D3]` - Lvl 3 Solo/Co-op Delve via orchard trapdoor).
  2. *The Gloom-Vein Iron Mine* (`[D1]` - Lvl 4–5 5-Player Story Dungeon in East Quarry).
  3. *Hollow-King's Barrow* (`[D2]` - Lvl 5–6 Undead Crypt behind Barrow Hills).
  4. *The Tangled Root-Sanctum* (`[R1]` - Lvl 6 Capstone 5-Player Family Raid at NE petrified oak).