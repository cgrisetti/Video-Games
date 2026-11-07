# **EVERWOOD WORLD MAP GAME BIBLE (V1 MASTER ATLAS & THE CROWN)**

> **Build status (2026-11-04, tracked in the Phase 12 Kaizen pass):** kept for the record as written. The Caldera Isles in the game follow [20_CALDERA_ATLAS_AND_CROWN_BIBLE.md](20_CALDERA_ATLAS_AND_CROWN_BIBLE.md) (the brief's own atlas, built in Phases 1 to 5; its Part III lists what's built and where it differs). Where this document disagrees, doc 20 and the engineering contract win: the game is GDScript 2.0 with strict static typing, not C# / .NET 8; the island and seam layout, level bands, raids and The Crown are doc 20's; and Phase 11's landblock streaming ([10_WORLD_ARCHITECTURE.md](10_WORLD_ARCHITECTURE.md)) is unchanged. Doc 20's build notes already record that this document was not followed.

**Document ID:** 14\_EVERWOOD\_WORLD\_MAP\_BIBLE **Status:** Canonical Architecture Lock (Supersedes 07\_WORLD\_OAKSHIRE\_VALE\_GDD.md and all prior zone layouts) **Target Engine:** Godot 4.7 (C\# / .NET 8, Forward+ Renderer, Jolt Physics) **Core Formula:** *Spine (Hobb) \+ Geology (Tolkien) \+ Sightlines & Shores (Le Guin) \\rightarrow Filtered by the Musk Razor*

## **1\. EXECUTIVE SUMMARY & DEPRECATION / EVOLUTION LEDGER**

This document establishes the final, unified spatial architecture for **Everwood: The Caldera Isles**. All previous landlocked valley layouts, redundant transit tunnels, and multi-town hub concepts are officially **deprecated**. However, **100% of our underlying Godot 4.7 C\# systems, chunk-streaming architecture, procedural terrain splat pipelines, and 3D modular asset kits are preserved and evolved** to build this streamlined world.

### **1.1 Why the Council Ruling Works**

Every feature in the Caldera Isles had to earn its place **twice**: once as rigorous **game design / game theory**, and once as **geological and economic truth** (a world that would naturally exist this way). Finally, the **Musk Razor** stripped out every redundant seam, tunnel, and town until only the essential, high-impact loops remained—and added back the crucial 10\\% (*The Old Quay Market* and *Horizon Silhouette Impostors*) that make the world feel alive.  
                         `[ N: RIME-FIRTH ]`  
                        `(Lv 10-14 | Rime-Gale)`  
                       `Raid B: Frost-Peak Aerie`  
                                 `^`  
     `\ The Breach                |               Open Sea`  
      `\ (Cold Current)           | (Salt Road Skiff - Seam 3)`  
       `v                         |`  
`[ W: IRON-NESS ]          [ C: THE CROWN ]          [ E: BARROW-EYOT ]`  
`(Lv 6-10 | Iron-Root)     (Lv 15-20 | All 4)        (Lv 8-12 | Star-Tide)`  
`Raid A: Under-Forge        The Heart-Crag           Raid C: Sunken Cathedral`  
       `^                         ^                         ^`  
       `| (West Strait - Seam 1)  | (Crown Landing - Seam 4)| (Eel Spit - Seam 2)`  
       `+--------------------+    |    +--------------------+`  
                            `|    |    |`  
                         `[ S: MILLER'S OAK ]`  
                        `(Lv 1-6 | Warm Hearth)`  
                     `Hearthstead Hub & North Quay`  
                     `(+ Old Quay Market at -6m Ebb)`

### **1.2 Deprecation & Asset Evolution Matrix**

| Legacy Concept / File (Deprecated) | Status | Evolved Replacement in Master Atlas V1 | Asset & Code Reuse Strategy |
| :---- | :---- | :---- | :---- |
| **Landlocked Oakshire Vale** (Wayfarer's Rest, Bramble-Wood, Whispering Fen) | **Deprecated Layout** | **Miller's Oak (Zone 1, South Isle)**: A coastal volcanic ash-loam crescent framing the southern rim of the Sound. | Reuse OakshireTerrainGenerator.cs height/splat math, reshaped into a south-sloping lee-shore island with northern harbor cliffs and a submerged Old Quay shelf. |
| **Wayfarer's Rest Village** | **Renamed & Refocused** | **Hearthstead Market & North Quay**: Hearthstead sits in the sheltered central-east orchard basin; North Quay sits on the northern caldera shore. | Reuse all Timber-Frame Village Kits, Tavern/Smithy props, and NPC schedules; bind the 3 empty market stalls to the 3 Friction Isle Beacon booleans. |
| **Bramble-Hollow / Deep-Root Burrows** | **Consolidated** | **Root-Sanctum (SW Miller's Oak)**: The single Zone 1 Capstone Grove/Barrow (Lv 5-6). | Reuse Elder Stone Kit, corrupted root meshes, and the Lv 6 boss encounter to trigger the breaking of the trade lanes. |
| **Root-Ways (3 Underground Fast-Travel Tunnels)** | **Deleted (Musk Razor)** | **3 Spokes from North Quay**: Walkable *West Strait*, walkable *Eel Spit*, and the *Salt Road* Skiff Bell. | Saves 3 entire tunnel map files and 6 load seams. |
| **4 Viaducts & 4 Tethers to the Center** | **Deleted (Musk Razor)** | **1 Crown Landing (South Bay of The Crown)**: Unlocked only when all 3 Friction Isle Beacons are lit. | Cuts 7 transition triggers down to 1 canonical skiff seam (Seam 4). |
| **Perimeter Inter-Island Ferries** (*Ore Ferry*, *Cod Run*, *4-Bell Chime Ring*) | **Deleted (Musk Razor)** | **Hub-and-Spoke Return Loop**: All lanes route through Miller's Oak. No direct Iron-to-Barrow lane. | Forces the party to return home between islands, sell loot, and witness Hearthstead Market physically upgrade. |
| **3 Interior Gate Dungeons on The Crown** | **Deleted (Musk Razor)** | **3 Open-Air Shore Trials** (*Trial of the Anvil*, *Trial of the Gale*, *Trial of the Tide*). | Saves 3 instanced dungeon scenes; reuses existing island environmental hazards on the Crown's outer shores. |
| **Concord Harbor (2nd Town on The Crown)** | **Deleted (Musk Razor)** | **Lantern-Bearers' Waypost**: A single campfire, anvil, and quartermaster at the Crown's South Bay Landing. | Preserves the sacred mystery of the final island and prevents splitting town traffic away from Miller's Oak. |
| **11–12 Streaming Load Seams** | **Deleted (Musk Razor)** | **Exactly 4 Load Seams** driven by **1 Seam Scene with 2 Visual Skins** (*Causeway Walk* & *Lantern-Skiff*). | Reuses ZoneStreamer.cs and OriginShifter.cs with deterministic memory unloading between the 5 island grids. |

## **2\. MACRO-ARCHIPELAGO ARCHITECTURE: THE CALDERA ISLES**

### **2.1 Geological & Ecological Truth (The Santorini Model)**

The entire archipelago is a single **collapsed volcanic caldera** approximately 4.5\\text{ km} in diameter, flooded by the ocean through a single massive structural rupture in the north-west (**The Breach**). Because islands only a few kilometers apart share the same macro-latitude, Everwood derives its **four distinct biomes strictly from rock chemistry, altitude, and exposure to the Breach**:

> 1. **The North-West Breach & Rime-Firth (North Isle, Lv 10–14):** The sea broke the caldera rim in the north-west. Freezing pelagic currents and gale-force sea-fog pour through the Breach and slam directly into **Rime-Firth's** high basalt cliffs (+120\\text{m} elevation). High altitude plus freezing breach-fog creates perpetual snow, rime-ice, and wind-scoured crags.  
> 2. **Iron-Ness (West Isle, Lv 6–10):** Situated along the active western magma fracture, hydrothermal plumes pushed ironstone and sulfur-rich ore up through the rock. Its rust-red crags and geothermal vents fuel the great blast-forges of *Forge-Gorge*.  
> 3. **Barrow-Eyot (East Isle, Lv 8–12):** Here, the eastern caldera rim subsided below the high-water table, turning the ancient burial lowlands into a drowned, mist-shrouded tidal fen of peat channels, willow-marshes, and half-sunken stone towers (*sunken rim / tidal fen*).  
> 4. **Miller's Oak (South Isle, Lv 1–6):** Sheltered in the calm southern lee of the caldera, protected from the NW Breach gales by Iron-Ness and The Crown, Miller's Oak sits atop deep, weathered **volcanic ash-loam**—the most fertile orchard and grain soil in the world.  
> 5. **The Crown / The Heart-Crag (Center Isle, Lv 15–20):** As calderas do in nature, magma pressure beneath the flooded basin pushed up a **resurgent dome** in the exact center of the Sound. Internal geothermal heat feeds warm freshwater springs at its \+65\\text{m} summit glade, explaining why the colossal **World-Tree** thrives there and nowhere else.

### **2.2 The 9 Non-Negotiable Macro Laws**

Every system and quest in Everwood must obey these nine structural rules established by the Council:

> 1. **A Drowned Caldera with One Breach (Tolkien):** A broken ring of islands reads visually as one cohesive world and frames the endgame in its center. The NW Breach explains the cold current, the gales, and why sea levels fluctuate.  
> 2. **The Crown as a Dome in the Middle, Seen from Every Quay (Le Guin):** The endgame is a visible promise from Minute 1\. Every harbor in the Sound looks directly at the resurgent dome and the World-Tree.  
> 3. **Biomes from Rock and Exposure, Not Latitude (Tolkien \+ Hobb):** Four distinct biomes emerge naturally from one geological rule-set (hydrothermal ironstone, high breach-facing basalt, subsided tidal fen, sheltered volcanic ash-loam).  
> 4. **Trade Lanes that Break at Level 6 (Hobb):** Gives a 9-year-old player an immediate, concrete motivation to leave home (*"The smith has no iron; the lamps have no oil"*). Oakshire grows all the food, while the three Friction Isles produce the iron, lantern-oil, and highland timber—neither side can survive alone.  
> 5. **Oakshire is the Hub Every Lane Runs Through (Hobb):** Every route radiates from and returns to Miller's Oak. There is no perimeter ferry between Iron-Ness and Barrow-Eyot (rival guilds and nothing to trade). The party returns home after every expedition, sells loot, and sees Hearthstead change.  
> 6. **Sheltered Inner Shores, Wild Outer Shores (Le Guin):** One universal level-design law governs every peripheral island: **Quays, Beacons, and Steadings face the calm inner Sound**; **Elites, Cliffs, and Sealed Raid Gates (A, B, C) face the violent Open Sea**. Players never need a compass to know whether they are walking toward safety or danger.  
> 7. **One Beacon per Friction Isle — One Flag, Three Effects (All Three):** Lighting an island's Beacon sets **one boolean flag** that simultaneously:  
   * Reopens that island's trade lane (spawning a permanent, functional vendor stall in **Hearthstead Market** that the whole co-op party uses with zero free-riding).  
   * Calms that island's treacherous vortex current (*Iron Current*, *Tide Current*, or *Gale Current*) swirling around **The Crown**.  
   * Grants the party that island's **Calling Sign** (*Iron-Root*, *Star-Tide*, or *Rime-Gale*).  
> 8. **Three Beacons Open the Crown Landing:** Once all three outer beacons blaze, the three maelstrom currents around the central dome subside, opening the skiff lane from **North Quay** directly to the **Crown Landing**.  
> 9. **The Ebb Ends the Long Flood — It Does Not Drain the Sea (Tolkien \+ Hobb):** For a generation (25\\text{ years}), the blighted **Star-Tide** (caused by the old kingdom draining the World-Tree's sap into the eastern sea) has artificially held the Sound's water level **\+6\\text{m} above normal**. Village grandparents still remember walking the **Old Quay Market** before the waters rose. Ringing the **Harmonic Bell** atop The Crown ends the Long Flood, dropping the global sea level by \-6\\text{m} back to its true historical waterline.

### **2.3 Master Island & Progression Matrix**

| Grid ID | Island Name | Compass | Level Band | Calling & Sign | Horizon Landmark (Visible from North Quay) | Beacon Unlocks (Hearthstead Stall) | Bared at the \-6\\text{m} Ebb-Tide |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **Grid 1** | **Miller's Oak** | South (S) | \\text{Lv } 1\\text{--}6 | **Warm Hearth** *(Hearth-Wardens)* | **The Great Windmill** (SE Orchard Ridge) | *Starting Larder & Bakery* (Active at \\text{Lv } 1\) | **Old Quay Market** (North Shore Endgame Bazaar) |
| **Grid 2** | **Iron-Ness** | West (W) | \\text{Lv } 6\\text{--}10 | **Iron-Root** *(Shield-Sworn)* | **The Twin Forge Stacks** (Forge-Gorge) | **Heavy Smithy & Armor Stall** (*Iron Current* calmed) | **Raid A: Under-Forge Abyss** (Over-delved mine sea-cave) |
| **Grid 3** | **Barrow-Eyot** | East (E) | \\text{Lv } 8\\text{--}12 | **Star-Tide** *(Lantern-Bearers)* | **The Sunken Bell-Tower** (Cathedral Fen) | **Lantern-Oil & Alchemy Stall** (*Tide Current* calmed) | **Raid C: Sunken Cathedral** (Sea-door of the bell-tower) |
| **Grid 4** | **Rime-Firth** | North (N) | \\text{Lv } 10\\text{--}14 | **Rime-Gale** *(Wayfarers)* | **The White Horn Snow Peak** (+120\\text{m} Rim) | **Highland Fletcher & Pelts Stall** (*Gale Current* calmed) | **Raid B: Frost-Peak Aerie** (The Whalers' Stair sea-cliff) |
| **Grid 5** | **The Crown** *(The Heart-Crag)* | Center (C) | \\text{Lv } 15\\text{--}20 | **All Four Signs** *(Convergence)* | **The World-Tree** (+65\\text{m} Dome \+ 3 Blooming Boughs) | *Harmonic Bell Unlocked* (Triggers \-6\\text{m} Ebb) | **True Raid: The Heart** (East Shore Sea-Door \\rightarrow Sap Galleries) |

### **2.4 The Co-Op Game-Theory Loop & "Scaling Floor" Math**

> * **Phase 1 — Grow Up in Oakshire (\\text{Lv } 1\\text{--}6):** Players awaken on the Lee Shore of Miller's Oak, learn the core combat loop and the first Sign (*Warm Hearth*), rally at Hearthstead Market, and clear the **Root-Sanctum** (Lv 6). Upon emerging, the **Star-Tide surge** severs all three trade lanes; the beacons on the horizon go dark, and Hearthstead's smith, chandler, and fletcher run out of raw materials.  
> * **Phase 2 — The Friction Isles in Any Order (\\text{Lv } 6\\text{--}14):** Players can walk across the **West Strait** causeway to *Iron-Ness* (Lv 6-10), walk the **Eel Spit** shingle bar to *Barrow-Eyot* (Lv 8-12), or ring the **Salt Road** skiff bell at North Quay to sail to *Rime-Firth* (Lv 10-14).  
  * **Nudged, Never Forced:** Material needs naturally suggest the order \\text{Iron-Ness} \\rightarrow \\text{Barrow-Eyot} \\rightarrow \\text{Rime-Firth}.  
  * **The Scaling Floor Rule:** To allow genuine free-choice without one-shotting bold parties who sail north early, each island enforces a **Scaling Floor** with **Flat Level-Delta Compression**: \\text{EffectiveEnemyLevel} \= \\max\\left(\\text{ZoneMinLevel}, \\min(\\text{ZoneMaxLevel}, \\text{PartyAvgLevel})\\right) Crucially, combat damage formulas **never** multiply enemy damage based on level delta—higher-level enemies in Rime-Firth simply possess their base \\text{Lv } 10 health and poise pools, meaning a skilled \\text{Lv } 6 co-op party using coordinated **Four-Sign Detonations** and **Shatterpoint breaks** can triumph if they dare.  
> * **Phase 3 — The Crown & The Harmonic Bell (\\text{Lv } 15\\text{--}20):** With all 3 Beacons lit, the party sails from North Quay to the **Crown Landing**, conquers the three open-air shore trials in any order (watching a massive bough of the World-Tree blossom in that Sign's color after each trial), ascends the single **Cliff Stair**, and pulls the **Harmonic Bell** together.  
> * **Phase 4 — The \-6\\text{m} Ebb-Tide Boomerang (\\text{Lv } 20 Raids):** A 10-second cross-archipelago camera sequence shows the sea dropping 6\\text{ meters} across all five islands. **Old Quay Market** emerges on Oakshire's north shore, **Sealed Raids A, B, and C** are bared on the outer coasts of the three Friction Isles, and the **Sea-Door** on the eastern shore of The Crown opens into the bleeding **Sap Galleries** for the 7-Man **True Raid: The Heart**.

## **3\. ZONE 1 DEEP-DIVE: MILLER'S OAK (STARTING ZONE & PERMANENT HUB)**

**Grid Footprint:** 12 \\times 12 Chunks (128\\text{m} \\times 128\\text{m} per chunk \= 1,536\\text{m} \\times 1,536\\text{m} total world area) **Local Coordinate Space:** X \\in \[-768\\text{m}, \+768\\text{m}\], Z \\in \[-768\\text{m}, \+768\\text{m}\] (where \-Z is North toward the Sound and \+Z is South toward the Open Sea) **Level Band:** \\text{Lv } 1\\text{--}6 (Onboarding) \+ \\text{Lv } 6\\text{--}20 (Central Hub & \-6\\text{m} Ebb-Tide Endgame Bazaar) **Native Calling Sign:** **Warm Hearth** (Fire / Vitality / Restoration)

### **3.1 Topographical & Ecological Profile**

Miller's Oak is a crescent-shaped southern rim segment of the volcanic caldera.

> * **The Inner (Northern) Shore (Z \\in \[-768\\text{m}, \-384\\text{m}\]):** Faces the calm waters of **The Sound**. Features sheltered stone harbors (**North Quay**), gentle shingle shelving where the drowned **Old Quay Market** rests just beneath the \+0\\text{m} Star-Tide waterline, and two natural land-pinch spits hooking northwest (**West Strait**) and northeast (**Eel Spit**).  
> * **The Central Ash-Loam Basin (Z \\in \[-384\\text{m}, \+256\\text{m}\]):** A warm, fertile bowl of dark volcanic soil irrigated by run-off streams from the southern rim. Home to **Hearthstead Market** in the central-east meadow and ancient oak-and-apple orchards across the eastern terrace.  
> * **The Southern Lee Shore & Windmill Ridge (Z \\in \[+256\\text{m}, \+768\\text{m}\]):** Gentle, sun-drenched terraced hills rising to \+45\\text{m} along the southeastern ridge (crowned by the **Great Windmill**) before dropping to protective basalt sea-bluffs along the southern Open Sea margin.  
> * **The South-Western Root-Ridge (X \\in \[-640\\text{m}, \-128\\text{m}\], Z \\in \[+128\\text{m}, \+512\\text{m}\]):** An uplifted, tangled spur of ancient caldera rock choked with petrified elder-roots leading into the **Root-Sanctum**.

### **3.2 Miller's Oak 12 \\times 12 Chunk Map & Coordinate Directory**

      `W (-768m)                                                   E (+768m)`  
`N     +-------------------------------------------------------------------+`  
`(-768)| [0,0] WEST STRAIT  | [2,0] The Sound      | [9,0] EEL SPIT        |`  
      `| Causeway Apron     | Sightline Corridor   | Shingle Apron         |`  
      `| (Seam 1 -> Iron)   |                      | (Seam 2 -> Barrow)    |`  
      `|--------------------+----------------------+-----------------------|`  
      `| [1,2] NW Bluff     | [4,2] OLD QUAY MKT   | [6,2] NORTH QUAY      |`  
      `| Watch-Post         | (Bared at -6m Ebb)   | (Skiff Bells: Seam 3&4|`  
      `|                    |                      |  + 5-Silhouette Vista)|`  
      `|--------------------+----------------------+-----------------------|`  
      `| [2,5] Whispering   | [6,6] HEARTHSTEAD MARKET (Central Hub)       |`  
      `| Copse (Lv 3-4)     | - Warm Hearth Commons & Great Hearth-Fire    |`  
      `|                    | - 3 Trade Stalls (Iron, Lantern, Timber)     |`  
      `|--------------------+----------------------+-----------------------|`  
      `| [2,8] ROOT-SANCTUM | [5,8] Mill-Stream    | [8,8] Ash-Loam        |`  
      `| (Lv 5-6 Capstone)  | Crossing (Lv 2-3)    | Orchards (Lv 1-2)     |`  
      `|--------------------+----------------------+-----------------------|`  
`S     | [1,10] SW Sea-Bluff| [5,10] Homestead     | [9,10] THE WINDMILL   |`  
`(+768)|                    | Meadows (Lv 1 Spawn) | Landmark (+45m Ridge) |`  
      `+-------------------------------------------------------------------+`

### **3.3 Detailed Sub-Zone & POI Specifications**

#### **1\. Lee Shore Ash-Loam Orchards & The Great Windmill (Lv 1–2)**

> * **Grid Chunks:** Chunks \[7..10, 7..10\] \| **World Coords:** (+320\\text{m}, \+384\\text{m}) to (+512\\text{m}, \+512\\text{m})  
> * **Elevation:** \+12\\text{m} (Orchard Terraces) rising to \+45\\text{m} (Windmill Crest).  
> * **Design Function:** The gentle, zero-stress onboarding cradle where families spawn (Homestead Meadows at (+128\\text{m}, \+448\\text{m})), learn camera/movement controls, basic attacks, and the **Warm Hearth** Sign amidst golden apple trees, stone dry-walls, and honey-bee apiaries.  
> * **The Landmark Silhouette:** **The Great Windmill** sits at (+448\\text{m}, \+480\\text{m}, \+45\\text{m}). Its four canvas sails rotate continuously via a lightweight vertex/transform script and remain visible across the Sound from North Quay and The Crown.  
> * **Enemies:** *Bramble-Mites* (Lv 1 swarm fodder) and *Cinder-Badgers* (Lv 2 basic telegraph tutorial).

#### **2\. Hearthstead Market (Lv 1–20 Permanent Social & Economic Hub)**

> * **Grid Chunks:** Chunks \[5..7, 5..6\] \| **World Coords:** (+64\\text{m}, \-64\\text{m}) to (+192\\text{m}, \+64\\text{m})  
> * **Elevation:** \+18\\text{m} (Level compacted cobblestone & timber plaza).  
> * **Design Function:** The beating heart of the Hobb economic spine. Surrounded by warm cottage roofs, the **Great Hearth-Fire** (party rest/buff brazier), and the **Four-Slot Trade Plaza**.  
> * **Dynamic World-State Stalls (No Free-Riders Co-Op Economy):**  
  1. **The Hearth-Larder (Always Open):** Sells basic rations, healing poultices, and starter \\text{Lv } 1\\text{--}5 gear.  
  2. **The Iron-Ness Smithy Stall (Tied to BeaconIron):** At \\text{Lv } 1\\text{--}6, the anvil sits cold and shuttered (*"No pig-iron from Forge-Gorge since the West Strait flooded"*). Once the party lights the Iron-Ness Beacon, the stall opens with a blazing forge, unlocking party-wide armor tempering, poise-break runes, and \\text{Lv } 6\\text{--}15 heavy weapons.  
  3. **The Barrow-Eyot Chandler Stall (Tied to BeaconTide):** Initially draped in tarpaulins (*"No bog-tallow or star-glass from Lantern Staithe"*). Lighting the Barrow-Eyot Beacon populates the stall with glowing blue-glass lanterns, corruption-cleansing oils, and flask upgrades.  
  4. **The Rime-Firth Outfitter Stall (Tied to BeaconGale):** Initially bare timber frames (*"The Salt Road skiff hasn't returned from Gale-Hall"*). Lighting the Rime-Firth Beacon stocks high-tier yew bows, grapple-hook cordage, wind-cloaks, and stamina elixirs.

#### **3\. North Quay & The 5-Silhouette Vista (Lv 1–20 Transit Hub)**

> * **Grid Chunks:** Chunk \[6, 2\] \| **World Coords:** (+32\\text{m}, \-480\\text{m}), Elevation \+2.5\\text{m} above Long Flood sea level.  
> * **Design Function:** Oakshire's active high-water harbor facing directly north across **The Sound**.  
> * **The Two Skiff Bells:**  
  * **East Pier — The Salt Road Skiff Bell (Seam 3):** Summons the Lantern-Skiff across the eastern Sound to **Rime-Firth** (Lv 10-14). Locked behind the \\text{Lv } 6 *Root-Sanctum* completion flag.  
  * **Center Pier — The Crown Landing Bell (Seam 4):** Faces straight north toward the South Bay of **The Crown**. Visually chained by three heavy elemental seals (Iron, Tide, Gale) that shatter one by one as BeaconIron, BeaconTide, and BeaconGale are set to true.  
> * **The Mandatory 180-Degree Sightline Fan:** Standing at the end of North Quay at (+32\\text{m}, \-500\\text{m}) and panning the camera from West to East gives an unobstructed view of all five archipelago silhouettes:  
  1. **West-Northwest (305^\\circ):** The smoking **Twin Forge Stacks** and Beacon cliff of *Iron-Ness* (1.6\\text{ km} away).  
  2. **North (0^\\circ):** The **Resurgent Dome of The Crown** and the **World-Tree** (1.4\\text{ km} away), with its three upper boughs blooming in gold/red, cyan, and silver as the Crown Trials are completed.  
  3. **North-Northeast (15^\\circ):** Rising \+120\\text{m} above the eastern shoulder of The Crown, the snow-capped **White Horn Peak** and Beacon of *Rime-Firth* (2.8\\text{ km} away).  
  4. **East-Northeast (60^\\circ):** The leaning **Sunken Bell-Tower** and Beacon of *Barrow-Eyot* (1.7\\text{ km} away).  
  5. **South-Southeast (150^\\circ, looking back over the shoulder):** **The Great Windmill** turning atop Oakshire's orchard ridge.

#### **4\. Old Quay Market (-6m Ebb-Tide Reveal Area)**

> * **Grid Chunks:** Chunks \[4..5, 2\] \| **World Coords:** (-160\\text{m}, \-512\\text{m}), Elevation \-3.5\\text{m} (Submerged during Phases 1–3; \+2.5\\text{m} dry stone plaza after the Ebb).  
> * **Design Function:** The Musk Razor's critical 10\\% addition. During \\text{Lv } 1\\text{--}19, players standing on North Quay can look down through the clear shallow water to see ancient drowned market arches, barnacle-crusted guild statues, and sunken flagstones 3.5\\text{ meters} below the surface.  
> * **Endgame Payoff:** When the **Harmonic Bell** is rung on The Crown and EbbTriggered \== true, the global water plane drops by \-6.0\\text{m}. The **Old Quay Market** is bared to the sun. Moss-covered stone stairs descend from North Quay into this reclaimed ancient plaza, where Master Raid Artificers set up camp to exchange Raid A, B, and C trophies for \\text{Lv } 20 Legendary sets.

#### **5\. The Root-Sanctum (Lv 5–6 Zone 1 Capstone Grove)**

> * **Grid Chunks:** Chunks \[1..3, 7..9\] \| **World Coords:** (-448\\text{m}, \+256\\text{m}), Elevation \+28\\text{m} descending into an open-air sunken caldera fissure at \+8\\text{m}.  
> * **Design Function:** Built without an interior load seam (open-air sunken stone amphitheater beneath massive petrified roots). Here, the party confronts the **Blighted Sap-Warden** (Lv 6 Boss) choking Oakshire's wellspring.  
> * **World-State Trigger:** Defeating the Sap-Warden cleanses Oakshire's local spring, awards the full **Warm Hearth** Sign mastery, and triggers the mid-game inciting event: a violent **Star-Tide pulse** washes down from The Crown's eastern wound, extinguishing the three distant Beacons on Iron-Ness, Barrow-Eyot, and Rime-Firth, while unlocking the soft-gates at **West Strait**, **Eel Spit**, and the **Salt Road Bell**.

#### **6\. West Strait Causeway Apron (Seam 1 \\rightarrow Iron-Ness) & Eel Spit Shingle Apron (Seam 2 \\rightarrow Barrow-Eyot)**

> * **West Strait Apron:** Chunk \[0, 0\] at (-700\\text{m}, \-700\\text{m}), Elevation \+1.5\\text{m}. A battered basalt causeway stretching northwest across the narrowest 200\\text{m} strait to *Iron-Ness*.  
  * *Lv 1–5 Soft Gate:* Blocked by a **Shield-Sworn Quarantine Barricade** until the Root-Sanctum (Lv 6\) is cleared.  
> * **Eel Spit Apron:** Chunk \[11, 0\] at (+700\\text{m}, \-700\\text{m}), Elevation \+0.8\\text{m}. A curving black-shingle sandbar and tidal timber boardwalk stretching northeast to *Barrow-Eyot*.  
  * *Lv 1–5 Soft Gate:* Washed over by churning knee-deep Star-Tide surf that pushes \\text{Lv } 1\\text{--}5 players back onto the beach until the Root-Sanctum is cleared at \\text{Lv } 6\.

## **4\. ZONES 2, 3, & 4: THE THREE FRICTION ISLES (LV 6–14)**

Each Friction Isle occupies a standardized 12 \\times 12 chunk grid (1,536\\text{m} \\times 1,536\\text{m}) and strictly obeys Le Guin's **Inner Shore / Outer Shore Law**:

> * **The Inner Shore (Facing The Sound):** Sheltered water, arrival causeway/quay, the friendly Steading, and the coastal **Beacon Tower** overlooking the Sound.  
> * **The Interior Spine:** The primary resource-gathering, questing, and dungeon-delving terrain teaching that island's core mechanical pillar.  
> * **The Outer Shore (Facing The Open Sea):** Jagged, storm-lashed cliffs where the **Sealed Raid Gate (A, B, or C)** lies submerged 4\\text{ to }5\\text{ meters} beneath the foaming Star-Tide surf until the \-6\\text{m} Ebb-Tide bares its threshold at \\text{Lv } 20\.

### **4.1 Zone 2: Iron-Ness (West Isle, Lv 6–10)**

> * **Calling & Sign:** **Iron-Root** (*Shield-Sworn* — Tanking, Posture Damage, & Shatterpoint Breaks).  
> * **Geological Profile:** Hydrothermal ironstone cliffs, steaming sulfur fissures, rust-red scree slopes, and terraced slag-works along the western caldera rim.  
> * **Core Gameplay Pillar Taught:** **Posture & Shatterpoint Mastery.** Enemies wear heavy slag-iron plating that deflects standard attacks until broken by coordinated Heavy/Stagger strikes and *Iron-Root* tremors.  
> * **Key Locations:**  
  1. **West Strait Landing (SE Inner Shore):** Walkable arrival apron from Miller's Oak (Seam 1).  
  2. **Forge-Gorge (Central Canyon & Steading):** Built inside a natural basalt chasm where geothermal vents heat the great blast-furnaces. Topped by the **Twin Forge Stacks** landmark.  
  3. **Iron-Point Beacon (East Inner Shore Cliff):** Overlooks the rusty **Iron Current** swirling on the western flank of The Crown. Lighting it sets BeaconIron \= true (reopens Hearthstead Smithy Stall, calms the western current, awards the *Iron-Root* Sign).  
  4. **Raid Gate A — The Under-Forge Abyss (SW Outer Sea-Cliffs):** An over-delved deep-iron mine whose lower haulage shaft breached the Open Sea. Flooded during \\text{Lv } 6\\text{--}19; when the sea drops \-6\\text{m} at the Ebb, a massive iron blast-door is exposed on the dry basalt shelf below the surf.

### **4.2 Zone 3: Barrow-Eyot (East Isle, Lv 8–12)**

> * **Calling & Sign:** **Star-Tide** (*Lantern-Bearers* — Healing, Light-Radius Management, & Blight Cleansing).  
> * **Geological Profile:** A sunken stretch of the eastern caldera rim where the land subsided into a brackish tidal fen of weeping willows, peat hags, bioluminescent reed-beds, and half-drowned elder barrows.  
> * **Core Gameplay Pillar Taught:** **Darkness & Cleansing Mastery.** Thick Star-Tide miasma blankets the low fen channels, stacking *Drowned Gloom* unless players maintain overlapping Lantern radii, ignite brazier chains, and time their *Star-Tide* cleanse bursts.  
> * **Key Locations:**  
  1. **Eel Spit Landing (SW Inner Shore):** Walkable shingle arrival apron from Miller's Oak (Seam 2).  
  2. **Lantern Staithe (South-Central Stilt Steading):** A timber boardwalk village suspended on tarred pilings above the fen channels, lit by strings of amber and star-glass lamps.  
  3. **The Sunken Bell-Tower (Central Fen Landmark):** The upper half of a colossal drowned abbey rising out of the central lagoon, visible from North Quay.  
  4. **Eyot Headland Beacon (West Inner Shore):** Overlooks the dark purple **Tide Current** off the eastern shore of The Crown. Lighting it sets BeaconTide \= true (reopens Hearthstead Chandler Stall, calms the eastern current, awards the *Star-Tide* Sign).  
  5. **Raid Gate C — The Sunken Cathedral (East Outer Coast):** The grand nave sea-doors at the base of the Bell-Tower's eastern sea-wall. Submerged under 5\\text{ meters} of black surf until the \-6\\text{m} Ebb drains the cathedral courtyard.

### **4.3 Zone 4: Rime-Firth (North Isle, Lv 10–14)**

> * **Calling & Sign:** **Rime-Gale** (*Wayfarers* — High-Agility Mobility, Updraft Gliding/Grappling, & Wind-Shear Positioning).  
> * **Geological Profile:** High columnar basalt cliffs (+120\\text{m}) directly facing the **North-West Breach**. Cold ocean currents and freezing sea-fog slam into the cliff face, burying the upper highland plateau in snowdrifts and rime-ice spires.  
> * **Core Gameplay Pillar Taught:** **Mobility & Wind-Shear Mastery.** Periodic gale-gusts sweep across the crags; players learn to read wind-shear telegraph ribbons, anchor behind basalt windbreaks, ride thermal/gale updrafts, and strike aerial/crag predators.  
> * **Key Locations:**  
  1. **Firth Haven Quay (South Inner Shore):** Sheltered rocky cove where the **Salt Road Skiff** (Seam 3\) docks in the lee of the mountain.  
  2. **Gale-Hall (West-Central Highland Steading):** A great Viking-inspired stone-and-pine longhouse built into a sheltered mountain saddle below the **White Horn Snow Peak** landmark.  
  3. **Breach-Watch Beacon (South-Central Rim Promontory):** Commands a sweeping view of both the NW Breach and the howling **Gale Current** north of The Crown. Lighting it sets BeaconGale \= true (reopens Hearthstead Outfitter Stall, calms the northern current, awards the *Rime-Gale* Sign).  
  4. **Raid Gate B — Frost-Peak Aerie / The Whalers' Stair (North Outer Sea-Cliff):** A centuries-old stone stair carved into the sheer northern sea-stacks by giant-whalers. Its lower landing is pounded by freezing breakers until the \-6\\text{m} Ebb exposes the base of the Whalers' Stair.

## **5\. ZONE 5 DEEP-DIVE: THE CROWN / THE HEART-CRAG (LV 15–20 APEX)**

**Council Verdict:** *Le Guin's open-air structure \+ Tolkien's vertical climax (up to the summit to ring the bell, down to the roots to break the blight) \+ Hobb's sap-works environmental storytelling — with zero new load seams and zero town clutter.*  
**Grid Footprint:** 800\\text{m} \\times 800\\text{m} Resurgent Volcanic Dome centered inside Grid 5 (1,536\\text{m} \\times 1,536\\text{m} Sound water envelope). **Elevation Profile:** \+0\\text{m} (Shoreline Apron) \\rightarrow \+15\\text{m} (Ring Path) \\rightarrow \+32\\text{m} (Sheer Crust-Fracture Cliff Band) \\rightarrow \+65\\text{m} (Summit Glade & World-Tree). **Level Band:** \\text{Lv } 15\\text{--}20 (7 Areas, 0 New Seams, 0 Pre-Raid Interior Dungeons).

### **5.1 Spatial Map of The Crown (The Heart-Crag)**

                    `N: GALE CLIFFS (Area 4 | Lv 15-18)`  
                `[North Face: Cold Breach Wind & Bare Basalt]`  
                  `( O ) TRIAL OF THE GALE (Mobility/Wind)`  
                   `(o) Spring     Old Sanctum Walls`  
                 `.-----------------------------------.`  
               `/         +32m CLIFF BAND WALL          \`  
             `/        .-------------------------.        \`  
    `W: IRON SHORE    /      WORLD-TREE (+65m)    \    E: TIDE GROTTOS`  
  `(Area 3 | Lv 15-18)|     (3 Blooming Boughs)   |  (Area 5 | Lv 15-18)`  
  `[Hot Vents/Steam]  |             |             |  [Old Sap-Works Coast]`  
  `( O ) TRIAL OF     |      [HARMONIC BELL]      |  ( O ) TRIAL OF`  
     `THE ANVIL       |   (All 5 Players Pull)    |     THE TIDE (Cleansing)`  
  `(Posture/Shatter)  |             :..(Sap       |        :..[A] SEA-DOOR`  
  `Old King's Town    \             :  Galleries) /   (o)   (Bared at -6m Ebb`  
   `(o) Spring         \       [=] CLIFF STAIR   /   Spring  -> True Raid:`  
             `\         '-------(Opens at 3/3)--'         /    The Heart)`  
               `\    Area 2: RING PATH (+15m Apron)     /`  
                 `'-----------------------------------'`  
                      `/_\ Lantern-Bearers' Waypost`  
                       `|  Area 1: SOUTH BAY LANDING`  
                       `v  (Seam 4 -> North Quay, Oakshire)`

### **5.2 The 10 Non-Negotiable Laws of The Crown**

> 1. **One Landing in the South Bay:** The summit stream cut a single gentle gully through the southern slope of the dome. All skiffs from North Quay land here (Seam 4).  
> 2. **The World-Tree in Sight from Every Step:** Rising from the \+65\\text{m} summit to over \+180\\text{m} in canopy height, the World-Tree is visible from every shore on the island so a 9-year-old player never gets disoriented.  
> 3. **Three Sign Shores Where the Currents Land, in Any Order:** Each of the three calmed currents deposits its island's geological and elemental character onto the matching flank of the Crown:  
   * **West Flank (Iron Shore):** Shares Iron-Ness's hydrothermal hot rock and steam vents.  
   * **North Face (Gale Cliffs):** Faces the open NW Breach, taking the full brunt of the freezing wind against bare basalt cliffs.  
   * **East Shore (Tide Grottos):** Where the ancient kingdom carved stone sluices to drain the World-Tree's golden sap into the sea—creating the festering wound that birthed the Star-Tide.  
> 4. **Each Trial is a Mastery Remix, Not a New System (\\text{Lv } 15\\text{--}18):** Capstone design tests what players learned across \\text{Lv } 6\\text{--}14 rather than inventing tutorial gimmicks at \\text{Lv } 15\. Furthermore, online/co-op parties can stay together or split up to tackle the three open-air trials in any of the 6 valid permutations.  
> 5. **The \+32\\text{m} Cliff Band is the Wall; One Stair Climbs It:** Where the resurgent dome's crust cracked during uplift, a sheer \+32\\text{m} basalt cliff rings the entire upper plateau. There are no invisible walls—only honest rock and a single ancient **Cliff Stair** on the southern face sealed by three elemental counterweights until all three Shore Trials are cleared.  
> 6. **Warm Springs are Checkpoints:** The dome's geothermal heat feeds three steaming mineral springs along the **Ring Path** (one near each shore trial). Resting at a spring binds party respawn and refills flasks with zero new UI or building bloat.  
> 7. **The Tree Answers Each Trial (Visible from Home):** Completing a Shore Trial sets its boolean (TrialAnvil, TrialGale, TrialTide) and triggers a shader state on one of the World-Tree's three colossal boughs—blossoming in **Ember-Gold** (West), **Rime-Silver** (North), or **Star-Cyan** (East). Because the horizon impostor in Oakshire reads these exact 3 booleans, a player standing on North Quay can look across the Sound and see which trials have been conquered.  
> 8. **The Harmonic Bell is Rung Together (Game-Theory Climax):** Hanging beneath the boughs of the World-Tree at the \+65\\text{m} **Summit Glade**, the great bronze **Harmonic Bell** has braided bell-ropes for every active party member. All present players must interact and pull within a 2.5\\text{s} harmonic window—a pure coordination climax that no solo carry can rush and no teammate is left out of.  
> 9. **Up to Ring, Down to Break:** Ringing the bell triggers the **10-Second Cross-Island Ebb Cinematic**, dropping the sea by \-6\\text{m} across all 5 islands. On The Crown itself, this bares the **Sea-Door** at the base of the eastern Tide Grottos—allowing the party to descend beneath the dome through the bleeding **Sap Galleries** into **The Heart (True Raid)**.  
> 10. **No Town on The Crown:** Only the **Lantern-Bearers' Waypost** (a campfire, repair anvil, and single supply chest) sits above the South Bay Landing. No NPC town dilutes the silence, awe, or Miller's Oak's role as the true home hub.

### **5.3 The 7 Canonical Areas of The Crown**

| Area \# | Area Name | Elevation | Level | Core Mechanics, Ruins, & World Logic |
| :---- | :---- | :---- | :---- | :---- |
| **Area 1** | **South Bay Landing & Waypost** | \+0\\text{m}\\text{ to }+10\\text{m} | \\text{Lv } 15 | Gentle shingle beach at the mouth of the summit stream gully. Contains the Skiff Dock (Seam 4\) and the *Lantern-Bearers' Waypost* (respawn, repair anvil, 1 quartermaster). |
| **Area 2** | **The Ring Path** | \+12\\text{m}\\text{ to }+20\\text{m} | \\text{Lv } 15 | A stone-flagged perimeter trail looping around the lower apron of the dome below the \+32\\text{m} cliff wall. Links all three shores and hosts the **3 Warm Spring Checkpoints**. |
| **Area 3** | **Iron Shore (West Flank)** | \+10\\text{m}\\text{ to }+28\\text{m} | \\text{Lv } 15\\text{--}18 | Hydrothermal vents, boiling geysers, and the half-melted ruins of *Old King's Town*. Hosts the open-air **Trial of the Anvil** (multi-wave posture/Shatterpoint gauntlet against Elder Automaton Wardens). Sets TrialAnvil \= true \\rightarrow West Bough blooms. |
| **Area 4** | **Gale Cliffs (North Face)** | \+18\\text{m}\\text{ to }+30\\text{m} | \\text{Lv } 15\\text{--}18 | Wind-scoured basalt ledges facing the NW Breach, dressed with the weathered *Old Sanctum Walls*. Hosts the open-air **Trial of the Gale** (high-velocity wind-shear platforms, updraft grapples, and storm-drake interceptors). Sets TrialGale \= true \\rightarrow North Bough blooms. |
| **Area 5** | **Tide Grottos (East Shore)** | \+4\\text{m}\\text{ to }+22\\text{m} | \\text{Lv } 15\\text{--}18 | Carved basalt aqueducts and broken bronze pipes where the old kingdom drained the World-Tree's sap into the sea. Hosts the open-air **Trial of the Tide** (creeping Star-Tide eclipse requiring coordinated Lantern relays and cleansing detonations). Sets TrialTide \= true \\rightarrow East Bough blooms. |
| **Area 6** | **Cliff Stair & Summit Glade** | \+32\\text{m}\\text{ to }+65\\text{m} | \\text{Lv } 18\\text{--}19 | When TrialAnvil && TrialGale && TrialTide are true, the counterweight gate at the base of the \+32\\text{m} cliff band opens. Players ascend the ancient **Cliff Stair** to the \+65\\text{m} warm-spring **Summit Glade**, stand beneath the **World-Tree**, and pull the **Harmonic Bell** together. |
| **Area 7** | **The Sea-Door \\rightarrow The Heart (True Raid)** | \-4.5\\text{m} (Entrance) \\rightarrow \-40\\text{m} (Core) | \\text{Lv } 20 | Bared on the outer East Shore below the Tide Grottos when EbbTriggered \== true (-6\\text{m} sea level). Players enter the ancient **Sap Galleries**—where golden sap and dark Star-Tide still bleed into the sea—and descend beneath the roots of the World-Tree for the 7-Man **True Raid**. |

## **6\. GODOT 4.7 TECHNICAL IMPLEMENTATION & DATA CONTRACTS**

### **6.1 The 7-Boolean World State Contract (WorldStateData.cs)**

By adhering to the Musk Razor, the entire progression of the 5-island archipelago—including market stalls, ocean currents, horizon shaders, skiff locks, the Cliff Stair, and the global sea level—is governed by **7 deterministic booleans** (4 Macro Flags \+ 3 Crown Trial Flags):  
`namespace Everwood.World;`

`public struct CalderaWorldState`  
`{`  
    `// --- 4 MACRO WORLD FLAGS (Master Atlas V1) ---`  
    `public bool RootSanctumCleared; // Unlocks West Strait, Eel Spit, & Salt Road Bell at Lv 6`  
    `public bool BeaconIron;         // 1. Opens Smithy Stall, 2. Calms Iron Current, 3. Grants Iron-Root Sign`  
    `public bool BeaconTide;         // 1. Opens Chandler Stall, 2. Calms Tide Current, 3. Grants Star-Tide Sign`  
    `public bool BeaconGale;         // 1. Opens Outfitter Stall, 2. Calms Gale Current, 3. Grants Rime-Gale Sign`  
    `public bool EbbTriggered;       // Drops Global Sea Level by -6.0m; bares Old Quay + Raids A, B, C, & Sea-Door`

    `// --- 3 CROWN TRIAL FLAGS (Crown Master V1) ---`  
    `public bool TrialAnvil;         // Blooms West Bough (Ember-Gold)`  
    `public bool TrialGale;          // Blooms North Bough (Rime-Silver)`  
    `public bool TrialTide;          // Blooms East Bough (Star-Cyan)`

    `public readonly bool IsCrownLandingUnlocked => BeaconIron && BeaconTide && BeaconGale;`  
    `public readonly bool IsCliffStairUnlocked   => TrialAnvil && TrialGale && TrialTide;`  
    `public readonly float TargetSeaLevelOffset  => EbbTriggered ? -6.0f : 0.0f;`  
`}`

### **6.2 The 4 Load Seams & "1 Seam Scene, 2 Skins" Architecture**

To guarantee zero out-of-memory spikes on a 16\\text{ GB} shared-VRAM machine running 4-player split-screen \+ 3 remote network peers, only **one 12 \\times 12 island grid** is loaded in active physics/high-detail memory at a time, while distant islands render via ultra-low-poly **Horizon Silhouette Impostors**. All transitions between the 5 islands use **a single C\# transition scene (ArchipelagoSeamTransition.tscn)** configured with **two visual skins**:

| Seam ID | Route | Skin Mode | Trigger Type | Condition to Traverse |
| :---- | :---- | :---- | :---- | :---- |
| **Seam 1** | **Miller's Oak \\leftrightarrow Iron-Ness** (*West Strait*) | Skin A: Causeway Walk (Basalt bridge & rolling sea-mist) | Walk-in Party Volume at Chunk \[0,0\] | RootSanctumCleared \== true |
| **Seam 2** | **Miller's Oak \\leftrightarrow Barrow-Eyot** (*Eel Spit*) | Skin A: Causeway Walk (Shingle spit & lantern-posts) | Walk-in Party Volume at Chunk \[11,0\] | RootSanctumCleared \== true |
| **Seam 3** | **North Quay \\leftrightarrow Rime-Firth** (*Salt Road*) | Skin B: Lantern-Skiff (6s boat glide across the Sound) | Interactive Skiff Bell on East Pier | RootSanctumCleared \== true |
| **Seam 4** | **North Quay \\leftrightarrow The Crown** (*Crown Landing*) | Skin B: Lantern-Skiff (6s boat glide to South Bay) | Interactive Skiff Bell on Center Pier | IsCrownLandingUnlocked \== true |

### **6.3 Global Ebb-Tide Water Plane & Reveal Controller (EbbTideManager.cs)**

Every island scene shares a synchronized OceanWaterPlane node and an EbbRevealGroup node container:

> * **Long Flood State (EbbTriggered \== false):**  
  * OceanWaterPlane.GlobalPosition.Y \= 0.0f  
  * All geometry between Y \= \-6.0\\text{m} and Y \= 0.0\\text{m} (**Old Quay Market** in Oakshire, **Raid Gate A** in Iron-Ness, **Raid Gate B** in Rime-Firth, **Raid Gate C** in Barrow-Eyot, and the **Sea-Door** on The Crown) is underwater. A submerged buoyancy/surf-pushback volume prevents players from walking down below Y \= \-1.2\\text{m}.  
> * **The Ebb-Tide State (EbbTriggered \== true):**  
  * Ringing the **Harmonic Bell** triggers a 10-second multi-camera cutscene (EbbTideSequence.cs) that smoothly interpolates OceanWaterPlane.GlobalPosition.Y from 0.0f to \-6.0f using a wet-sand shoreline foam shader transition.  
  * The submerged pushback volumes disable, dry navmesh links activate over the \-6\\text{m} shelf, and the **Old Quay Market** stalls and **Raid Portals A, B, C, and True Raid** become immediately accessible on maps the players already know by heart.

### **6.4 Horizon Silhouette Impostor System (HorizonVistaController.cs)**

Mounted persistently in the skybox/horizon ring of every island, 5 low-draw-call (\< 1,500 triangles each) distant island proxy meshes sit at their true world-space bearings across the 4.5\\text{ km} caldera:

> 1. **Oakshire Impostor:** Lee-shore hills \+ animated **Windmill sails**.  
> 2. **Iron-Ness Impostor:** Red ironstone cliffs \+ particle plume from the **Twin Forge Stacks** \+ **Iron Beacon flame** (enabled when BeaconIron \== true).  
> 3. **Barrow-Eyot Impostor:** Low misty fen \+ **Sunken Bell-Tower** silhouette \+ **Tide Beacon flame** (enabled when BeaconTide \== true).  
> 4. **Rime-Firth Impostor:** High basalt wall \+ **White Horn Snow Peak** \+ **Gale Beacon flame** (enabled when BeaconGale \== true).  
> 5. **The Crown Impostor:** Central resurgent dome \+ **World-Tree** with 3 independent canopy shader parameters (\_BoughWestBloom, \_BoughNorthBloom, \_BoughEastBloom) driven directly by TrialAnvil, TrialGale, and TrialTide, plus 3 animated water-current rings around its base that calm as each Beacon is lit.