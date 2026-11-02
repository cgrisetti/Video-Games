# 10_WORLD_ARCHITECTURE.md — The Everwood Landblock & Seamless World-Grid Architecture (Phase 11)

## 1. Executive Summary & Architectural Mission
As *Everwood* completes Phases 9 and 10 (**Walkable Bramblebridge**, **The 3x3 Matrix of Callings**, **Cross-Grimoire HUD**, **The Doverslap Expedition**, and **Storybook Cel-Shaded Puppets**), Phase 11 transitions our world representation from monolithic single-script scenes (`hub_town.gd` and `dungeon_dojo.gd`) to a **WoW (`.adt`) / Lord of the Rings Online ("Landblock") Deterministic World-Grid Architecture**.

### Core Engineering Goals
1. **Seamless Overworld-to-Expedition Continuity:** Unite **Bramblebridge**, **The Ariundle Moss-Oaks**, **The Sunken Holloway**, **Doverslap Gorge Bridge**, and **The Ring of the Cairnsman** (and future regions like **The Wadden-Green** and **Luka-Bay**) into a continuous, bounded 2D grid of `128m × 128m` Landblocks (`Vector2i(x, z)`).
2. **Multi-Focus Split-Screen & Co-Op Union Streaming:** Unlike single-player open worlds that stream a single circle around one camera, *Everwood* supports up to **4 local split-screen players + 5-player LAN/online co-op**. Our `WorldGridManager` calculates the **Spatial Union of Active Party Radii** so every couch viewport and network peer renders a rock-solid, stutter-free surrounding world.
3. **100% Code-First & Headless CI Safe (`CLAUDE.md` Compliant):**
   - Zero fragile hand-edited `.tscn` megafiles.
   - **Dual-Mode Terrain Backend:** Native support for the **Terrain3D GDExtension** when present in `addons/terrain_3d/`, paired with an automatic **Code-First Heightmap & Clipmap Mesh Generator (`LandblockTerrainBuilder`)** so `godot --headless --check-only` and `tools/smoke_test.gd` always pass out-of-the-box without requiring external binary compilation.
4. **Musk Razor Applied to Open Worlds:**
   - **What We Cut:** Monolithic level reloads between town and wilderness, per-node `MeshInstance3D` trees for thousands of grass blades/rocks, single giant `NavigationRegion3D` bakes, and storing persistent state inside transient visual nodes.
   - **The 10% Added Back In:** A **4-Layer Landblock Anatomy**, a **2ms Frame-Budgeted Instantiation Queue**, a **Decoupled `WorldStateDB` Delta Dictionary** (that also solves the Phase 9 latecomer sync gap for `Wayfarer's Chest` and `Water-Shrine`), and **Per-Chunk `NavigationServer3D` Edge Stitching** (solving the Phase 9 companion AI pathfinding gap).

---

## 2. Deterministic Spatial Grid Specification (`WorldGridConfig`)

All world coordinates map deterministically to two hierarchical grid levels in $O(1)$ time:

- **Region (Zone / Archipelago Sector):** $1024\text{ m} \times 1024\text{ m}$ ($8 \times 8 = 64$ Landblocks per Region). Matches `Terrain3D` standard region dimensions.
- **Landblock (Chunk / Cell):** $128\text{ m} \times 128\text{ m}$. Large enough to frame a complete combat encounter or village quarter (under our $4.8\text{ m}$ camera eye-line and $\le 3.2\text{ m}$ obstacle height rule), yet compact enough to instantiate in $< 1.5\text{ ms}$.

### Coordinate Conversion Math
$$\text{ChunkCoord}(x, z) = \left( \left\lfloor \frac{\text{WorldPos}.x}{128.0} \right\rfloor, \left\lfloor \frac{\text{WorldPos}.z}{128.0} \right\rfloor \right)$$

$$\text{RegionCoord}(x, z) = \left( \left\lfloor \frac{\text{ChunkCoord}.x}{8} \right\rfloor, \left\lfloor \frac{\text{ChunkCoord}.y}{8} \right\rfloor \right)$$

### Canonical Proof-of-Capability (PoC) Landblock Map: *The Bramble-to-Doverslap Corridor*
To prove the stack while maintaining 100% backward compatibility with `hub_town` and `dungeon_dojo` network IDs, our initial seamless region (**Region `(0, 0)` — The Bramble-Reach**) spans a deterministic $2 \times 4$ Landblock corridor surrounded by bounded topographical ridge-lines:

| Landblock `Vector2i` | World Bounds ($X, Z$) | Lore & Gameplay Contents |
|---|---|---|
| **`Chunk (0, 0)`** | $X \in [0, 128), Z \in [0, 128)$ | **Bramblebridge South & Village Square:** South Bank Spawn Green, low-angle ($13^\circ$) arched canal bridge, Armory & Scribe Desk, Chime-Shrine, smoking bakery, watermill wheel, and Northern Timber Gate. |
| **`Chunk (0, -1)`** | $X \in [0, 128), Z \in [-128, 0)$ | **Ariundle Moss-Oaks & Sunken Holloway:** Northern forest threshold, Bramble Minion Camp (3 *Bramble-Scuttlers*), Hidden Side Alcove with **Wayfarer's Chest** ($+15\text{ Chimes}$ + Uncommon Card), swaying **Wind-Lanterns**, **Wayfarer's Water-Shrine**, and Holloway Minion Camp (3 *Holloway Imps* + 1 *Scuttler*). |
| **`Chunk (0, -2)`** | $X \in [0, 128), Z \in [-256, -128)$ | **Doverslap Gorge Bridge & Sinaya Gatehouse:** Roaring waterfall chasm, Carpathian timber-and-stone trestle bridge, paper-mill waterwheel, **CoopGate** portcullis, twin **Rune-Plates**, **Gorge Gale-Jet**, and **Bronze Bridge-Bell Winch**. |
| **`Chunk (0, -3)`** | $X \in [0, 128), Z \in [-384, -256)$ | **The Ring of the Cairnsman:** Sunlit moss-ringed stone causeway overlooking the gorge spray, housing **The Cairnsman of Doverslap** (Phase 1 & Phase 2 `BLUE_BEHIND_TANK` **Doverslap Gale-Beam**). |
| **`Border Ring`** (`X=-1`, `X=1`, `Z=1`, `Z=-4`) | Perimeter around Corridor | **Bounded LOTRO Topography & HLOD Silhouettes:** Impassable mossy crags, dense Ariundle oak canopy walls, `OccluderInstance3D` volumes, and distant silhouettes of **Sinaya Mill-Castle** and **The Wadden-Green**. |

---

## 3. The 4-Layer Landblock Anatomy

Every `128m × 128m` Landblock is decoupled into **four distinct runtime layers** with independent load/unload hysteresis radii around the party's occupied chunks:

| Layer | Load / Unload Radius | Engine Implementation | Purpose in *Everwood* |
|---|---|---|---|
| **Layer 1: Terrain & Horizon (HLOD)** | Load $\le 3$ chunks ($384\text{ m}$)<br>Unload $> 4$ chunks | **Dual-Mode:** `Terrain3D` GDExtension *or* Code-First `ArrayMesh` + `HeightMapShape3D` + single-draw-call `HLODProxy` mesh | Seamless ground elevation, vertex-painted moss/cobble/heather transitions, and distant landmark silhouettes (waterwheels, gatehouse towers, mountain ridges) visible from across the valley. |
| **Layer 2: Static Clutter & Foliage** | Load $\le 2$ chunks ($256\text{ m}$)<br>Unload $> 3$ chunks | `MultiMeshInstance3D` / `RenderingServer` direct RIDs (`LowScenery` camera-ignored collider layer where needed) | Mossy boulders, heather tufts, reed beds, stepping stones, and timber fence posts. **Zero per-object `Node3D` SceneTree overhead.** Shared `storybook_cel.gdshader`. |
| **Layer 3: Interactive & Gameplay** | Load $\le 1$ chunk ($3 \times 3$ grid)<br>Unload $> 2$ chunks | Frame-budgeted node attachment via `WorldGridManager` ($\le 2.0\text{ ms/frame}$) | `MinionCamp`, `WayfarerChest`, `WaterShrine`, `WindLantern`, `CoopGate` (`RunePlate`, `BellWinch`, `GorgeGaleJet`), `ChimeShrine`, Scribe Desk, and `BossDummy`. |
| **Layer 4: Chunked Navigation & AI** | Load $\le 1$ chunk ($3 \times 3$ grid)<br>Active Tick $= 0\text{–}1$ chunk | Per-chunk `NavigationRegion3D` / `NavigationServer3D` RIDs with `edge_connection_margin = 0.5m` | Enables Companion AI and `WoodlandMinion` packs to pathfind smoothly around obstacles and across `128m` chunk seams, with distance-scaled AI tick rates. |

---

## 4. Deep-Dive System Specifications

### 4.1 Multi-Focus Split-Screen & Co-Op Union Streaming (`src/world/world_grid_manager.gd`)
In a 4-player couch + LAN party, Player 1 might be browsing the **Scribe Desk** in `Chunk (0, 0)` while Player 2 and Player 3 walk ahead into the **Ariundle Moss-Oaks** in `Chunk (0, -1)`.
1. **Focus Set Calculation:** Every `0.2s` (5 Hz streaming heartbeat), `WorldGridManager` gathers the `global_position` of all active human players (`FocusPoints`).
2. **Union of Chebyshev Radii:**
   - For any candidate chunk $C$:
     $$d(C) = \min_{p \in \text{FocusPoints}} \max(|C.x - \text{chunk}(p).x|, |C.y - \text{chunk}(p).y|)$$
   - **Hysteresis Ring (Prevents Boundary Thrashing):**
     - `d(C) <= 1`: Upgrade to **FULL_GAMEPLAY** (Layers 1 + 2 + 3 + 4 active).
     - `d(C) == 2`: Hold at **VISUAL_CLUTTER** (Layers 1 + 2 active; Layer 3 & 4 stays loaded if already loaded, or loads Layer 1+2 if approaching).
     - `d(C) == 3`: Hold at **HORIZON_HLOD** (Layer 1 + `HLODProxy` visible; Layers 2, 3, 4 unloaded).
     - `d(C) >= 4`: Unload completely (`UNLOADED`).
3. **2ms Frame-Budgeted Instantiation Queue:**
   - Instead of calling `add_child()` on an entire chunk's interactive props in a single frame, `WorldGridManager` pushes Layer 3 spawn tasks into `_instantiation_queue`.
   - Inside `_process()`, it pops and attaches nodes until `Time.get_ticks_usec() - frame_start_usec >= 2000` ($2.0\text{ ms}$ budget), guaranteeing 60+ FPS even when sprinting across chunk borders in 4-way split-screen.

### 4.2 Decoupled Persistence & Latecomer Sync (`src/world/world_state_db.gd`)
When a chunk unloads (or when a 5th family member joins mid-expedition over LAN), world mutations must never be lost.
- **`WorldStateDB` Structure:** Keyed by `Vector2i` chunk coordinate $\rightarrow$ `StringName` entity ID $\rightarrow$ `Dictionary` state delta:
  ```gdscript
  # Example runtime state in WorldStateDB
  var chunk_deltas: Dictionary = {
      Vector2i(0, -1): {
          &"camp_bramble_01": { "cleared": true },
          &"chest_alcove_01": { "opened": true, "opener_peer": 1 },
          &"shrine_holloway_01": { "cooldown_until": 184.5 }
      },
      Vector2i(0, -2): {
          &"gate_sinaya_01": { "opened": true, "method": &"bell_winch" }
      }
  }
  ```
- **Lifecycle Contract:**
  1. When an interactive entity (`MinionCamp`, `WayfarerChest`, `WaterShrine`, `CoopGate`) mutates state, it calls `WorldStateDB.set_entity_state(chunk_coord, entity_id, state_dict)`.
  2. When `WorldGridManager` streams `Chunk (0, -1)` back into the SceneTree, each stateful entity queries `WorldStateDB.get_entity_state(chunk_coord, entity_id)` inside `apply_persisted_state()` before its first visible frame—so cleared minion camps stay cleared and opened chests stay open.
  3. **Fixes Phase 9 Latecomer Note:** `WorldStateDB.export_snapshot()` serializes the full delta dictionary in a single compact RPC payload when a latecomer joins mid-expedition, immediately syncing `WayfarerChest`, `WaterShrine`, `MinionCamp`, and `CoopGate` states!

### 4.3 Seamless Chunked Navigation & AI Tick Scaling (`src/world/chunk_nav_builder.gd`)
Fixes the Phase 9 build note (*"Companions steer in straight lines and skip ahead when stranded; there's no navigation mesh"*):
- **Per-Chunk Baked/Procedural NavMesh:** Each `128m × 128m` Landblock generates a lightweight `NavigationRegion3D` with a `NavigationMesh` matching its walkable terrain surface and carved obstacle footprints (bridges, ramps, gatehouse piers, shrine basins).
- **Automatic Seam Stitching:** On startup, `WorldGridManager` configures `NavigationServer3D.map_set_edge_connection_margin(world_nav_map, 0.5)` and `map_set_cell_size(world_nav_map, 0.25)`. When `Chunk (0, 0)` and `Chunk (0, -1)` are both active, `NavigationServer3D` stitches their border edges together automatically so Companion AI and `WoodlandMinion` actors pathfind smoothly across chunk seams and over the $13^\circ$ canal bridge.
- **Distance-Based AI Tick Scaler:**
  - Distance $\le 35\text{ m}$ to nearest player: **Full Tick ($60\text{ Hz}$)** — full hitbox/posture evaluation.
  - Distance $35\text{–}90\text{ m}$: **Reduced Tick ($10\text{ Hz}$)** — coarse patrol/idle evaluation.
  - Distance $> 90\text{ m}$: **Dormant ($0\text{ Hz}$)** — physics process disabled until a player approaches.

### 4.4 Dual-Mode Terrain & Bounded LOTRO Horizon (`src/world/landblock_terrain.gd`)
- **Mode A (Native C++ GDExtension Hook):** Checks `ClassDB.class_exists(&"Terrain3D")`. If you install the `Terrain3D` plugin into `addons/terrain_3d/`, `LandblockTerrain` automatically binds regions to `Terrain3DData` and feeds our deterministic elevation function into `Terrain3D`.
- **Mode B (Code-First Heightmap & Clipmap Mesh — Default & Headless Safe):** Generates an optimized vertex-colored `ArrayMesh` (with `storybook_cel.gdshader` support) + exact `HeightMapShape3D` / ramped convex bridge colliders per `128m × 128m` chunk using a continuous analytical elevation field $h(x, z)$. Because $h(x, z)$ is continuous across chunk boundaries ($x = 128k, z = 128m$), normal vectors and vertex heights match with **zero seam gaps**.
- **Bounded Topographical Framing & Occlusion:** Each outer border chunk places an `ArrayOccluder3D` inside an `OccluderInstance3D` along the ridge-line and holloway walls, plus a single merged `HLODProxy` mesh (e.g., the Sinaya Gatehouse silhouette and spinning waterwheel visible from Bramblebridge North Gate) that automatically hides the moment the real `Chunk (0, -2)` finishes streaming in.

---

## 5. Verification, Compatibility, & Telemetry HUD
- **Zero-Regression Backward Compatibility:** `hub_town.gd` and `dungeon_dojo.gd` remain valid entry points for existing tests and network session IDs, while a new **Seamless World Mode (`everwood_world.gd`)**—and upgraded chunk-backed delegators inside the existing level scripts—allows walking directly from **Bramblebridge Spawn Green (`Chunk 0,0`)** through the **Northern Forest Gate** into **The Ariundle Moss-Oaks (`Chunk 0,-1`)**, across **Doverslap Gorge Bridge (`Chunk 0,-2`)**, and into **The Ring of the Cairnsman (`Chunk 0,-3`)** with **zero loading screens**.
- **F4 Landblock Telemetry Overlay (Developer / Verification Toggle):** Pressing `F4` toggles a compact top-right corner diagnostic badge displaying current `Chunk (X, Z)`, Active Loaded Chunks, HLOD Proxy Count, Frame-Budget Queue Depth, and `WorldStateDB` Delta Count.
---

## 6. Build Notes (Phase 11)

What the game does today, where it differs from the spec above, and what's still to come.

**In the code now**
- **The Seamless World Mode** is its own instance, `everwood_world` (`src/levels/everwood_world.gd`, scene generated by `tools/build_levels.gd`), and the game now starts there. Bramblebridge sits in Chunk (0, 0) with its Forest Gate open: walk out of it, under the new Moss-Oak Great Arch, into the Ariundle Moss-Oaks (0, -1), down the Sunken Holloway, up a trail to the Doverslap Gorge Bridge and the Sinaya Gatehouse (0, -2), and up the causeway to the Ring of the Cairnsman (0, -3), with no loading screen. The Raid Portal still warps the party into the instanced `dungeon_dojo`, whose exit portal brings them home to whichever Bramblebridge they came from. `hub_town` and `dungeon_dojo` keep their coordinates, scenes and network ids, so every Phase 1–10 test still runs against them.
- **`src/world/`**: `WorldGridConfig` (the grid maths, radii and the 2 ms budget), `LandblockManifest` (what each chunk holds and the shape of the land), `WorldStateDB` and `WorldStateBinding`, `LandblockTerrain` (Layer 1), `LandblockClutter` (Layer 2), `ChunkNavBuilder` and `NavSteering` (Layer 4), and `WorldGridManager` (the streaming controller). `src/ui/world_telemetry_badge.gd` is the F4 badge.
- **The Kindled Bivouac and Oakshire Commons** are Chunk (0, 1), south of Bramblebridge, and the party now wakes there: round a Warm-Hearth campfire (`HearthCampfire`: a mossy river-stone ring, a tripod kettle, travel packs and a flickering saffron-gold light) in the chunk's south-west, facing the lane. Standing by the fire warms the whole party to full health and stamina, then it burns low for 40 s, as the Water-Shrine does; its rest is in WorldStateDB. A Wind-Lantern hangs from the bivouac oak's limb over the lane. The lane (`LandblockManifest.LANE`, flat, cobbles with no colliders) runs east, then north through the commons (a stepped-gable timber homestead, seven cedar bee-hives in a south-facing arc along the east woodline, two heirloom pumpkin patches), between knee-high dry-stone walls on the LowScenery layer, and in at a new south gate in Bramblebridge's wall. When anyone crosses the canal bridge into the square, the square becomes the party's checkpoint: downed players get back up there, between the Scribe Desk and the Chime-Shrine, and a raid or the Cairnsman's gold portal brings the party home there. That lasts for the rest of the run of the game (`EverwoodWorld.town_square_reached`, also in WorldStateDB for latecomers); a fresh start wakes at the campfire again. The commons and the village both keep their state when the expedition resets.
- **Layouts.** The streamer asks a `WorldLayout` (`src/world/world_layout.gd`) for everything that differs between worlds: its bounds, heights and colours, which chunks have collision and navigation, each chunk's landblock and HLOD files, its clutter, occluders and horizon. `DoverslapLayout` is this corridor (through `LandblockManifest`); `OakshireValeLayout` is Oakshire Vale's 12 x 12 vale (`12_WORLD_OAKSHIRE_VALE_GDD.md` §6). `WorldGridManager.layout_id` picks one when the level loads, and `WorldGridConfig.layout` holds it.
- **Landblocks as files.** Each corridor chunk's gameplay layer is a scene in `data/landblocks/` (`landblock_0_-1.tscn` and so on), built by the same builder functions as the classic levels and moved to its world origin, like a WoW `.adt`. They stream in through `ResourceLoader`'s threaded loading, are instantiated on a worker thread, and are attached piece by piece through the 2 ms queue (in a headless run the worst frame spent about 1.1 ms attaching, the worst single step 0.7 ms). Each one's HLOD proxy is baked from it (`hlod_*.res`, its big shapes merged into one vertex-coloured mesh).
- **Terrain (Mode B)** samples one continuous height and colour field on a 2 m grid, with normals from the same field, so chunk edges match exactly. Its collider is a 1 m height map. The floor is flat 4 cm under each zone's own floor; past it the land rises at once into crags too steep to climb, and the trails between zones are lined with low dry-stone walls that have colliders. The trails climb 3 m to the gorge and 3 m more to the Ring.
- **Streaming.** Five times a second the union of every human player's chunk decides each chunk's layers, with the load and unload radii above. From the green: 9 chunks fully in, 12 with clutter, 2 HLOD proxies on the horizon (the gatehouse and the standing stones). The village's gameplay streams out once everyone is 3 chunks away, and its rooftops come back as an HLOD.
- **WorldStateDB** holds cleared camps, the opened Wayfarer's Chest, the Water-Shrine's rest (on the store's own clock), the open gate, and the fallen Cairnsman with his chest. The host sends every change to every peer, and a peer that loads in late asks for the whole snapshot, which closes the Phase 9 latecomer gap in the classic Dojo too. After the Cairnsman's chest is opened, a gold portal brings everyone home to the green and the expedition's state is cleared for a fresh run, keeping the village's.
- **Navigation.** Every loaded corridor chunk bakes its own navigation mesh on a worker thread, from its landblock's colliders and the terrain floor. The bakes are clipped to the chunk and grown by a 1 m border, so neighbouring tiles meet exactly on the seam and the map joins them. The classic Dojo bakes one mesh for its whole expedition. Companions, minions and `--demo` bots follow paths past a few metres and walk straight when close. Far-off enemies think less often: every tick within 35 m of a player, 10 times a second to 90 m, dormant beyond. Enemies in a fight always think at full rate.
- **Terrain3D (Mode A)** is live now that the addon is installed (Terrain3D 1.1.0 in `addons/terrain_3d/`). The world finds it and draws the ground with one Terrain3D node: each landblock is one 128 m region at 1 m, its height and colour maps built on a worker thread from the same field and the region made from them on the main thread (Terrain3D crashes if a region is made on a worker), then added or removed as its chunk's Layer 1 streams. It wears `src/world/landblock_terrain3d.gdshader`, Terrain3D's minimal shader reading our colour map and lit by the shared storybook bands (`storybook_cel_light.gdshaderinc`), so it looks like Mode B. Its clipmap LODs centre on Player 1, its own collision and background are off, and it holds one plain texture slot (a tiny white albedo and a flat normal the shader never samples). Without that slot Terrain3D counts itself untextured and switches its checkerboard on at every region refresh, rebuilding its shader each time; on the first load that freed a still-compiling shader about 50 times (render-thread errors and leaked shaders in a windowed run) and recompiled the shader on every chunk change. The colliders stay our height maps in both modes, so the world plays the same with or without the addon. `--terrain=builtin` (or `WorldGridManager.force_builtin_terrain`) draws the built-in meshes instead.
- **The F4 badge** sits top-right under the banner: `Landblock (0, 0) · Active: 9 · Clutter: 12 · HLOD: 2 · Queue: 0 · Deltas: 0`. `--telemetry` shows it from the start.
- **Checks.** `tools/test_world_grid.gd` runs after the classic smoke checks (with Terrain3D installed it also follows the regions in and out, then reloads the world on the built-in meshes): the grid maths, the layers and HLOD swaps up the corridor, hysteresis on a seam, the queue and orphan nodes, `WorldStateDB` persistence through an unload and reload plus a latecomer snapshot, and a navigation path across the z = 0 seam.

**Deliberate differences from this spec**
- **Bramblebridge's place in Chunk (0, 0).** Its classic layout moves to (64, 0, 32), so the Northern Forest Gate stands at z = 2 inside Chunk (0, 0) and the trail out of it crosses the seam at z = 0. No content straddles a seam except terrain trails, so navigation tiles join cleanly.
- **The HLOD landmarks** are each chunk's own big shapes rather than new models: the village's rooftops and mill, the Moss-Oak Great Arch and canopy, the gatehouse towers and waterwheel, and the standing stones. The crags carry two far silhouettes of their own: the Sinaya Mill-Castle east of the gorge, and a windmill on the Wadden-Green downs.
- **Holloway Imps** are the Bog-Imps (the Creative Director's name).
- **Test 4 parks the party in Chunk (0, 2)**, outside the bounded world, with their physics paused there, then primes the chunks again before moving them back, as a teleport does.
- **Navigation map updates are synchronous** (`navigation/world/map_use_async_iterations` and `region_use_async_iterations` are off). Asynchronous updates never took in new meshes under headless `--fixed-fps` runs, and the world is small.
- **The game's main scene is now the seamless world.** Start the classic hub with `-- --instance=hub_town`.
- **The bivouac is Chunk (0, 1), not (0, -1).** The brief that added it numbered the chunks with north positive. Here north is -Z, so the chunk south of Bramblebridge is (0, 1), and the expedition keeps (0, -1) to (0, -3). The new start is a small hamlet called Oakshire Commons; the 1.5 km Oakshire Vale (`12_WORLD_OAKSHIRE_VALE_GDD.md`) is still its own instance.
- **Terrain3D is not in git.** `addons/` and the addon's `demo/` are gitignored, so a fresh clone draws the ground in Mode B and plays the same. `tools/fetch_terrain3d.sh` installs Terrain3D 1.1.0 for local use, and the world finds it with `ClassDB.class_exists`.

- **Terrain3D's region refresh** takes about 12 ms each time regions change, since Terrain3D re-uploads every region's maps at once. The grid batches every add and remove into one refresh per streaming change. In Mode B every attach step stays under 2 ms.
- **One clipmap** follows Player 1. Other split-screen views see its coarser rings near them, which is fine on our gentle trails.

**Not built yet**
- Loaded landblock scenes and HLOD meshes stay cached for the session (four of each). Nothing is evicted yet.
- The other regions (the Wadden-Green, Luka-Bay and the rest) are design only; Oakshire Vale is the second world built on the streamer. The crag chunks have terrain, clutter and occluders but no gameplay.
