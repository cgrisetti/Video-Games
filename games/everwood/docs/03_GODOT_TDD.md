# 03_GODOT_TDD.md — Technical Design Document (Godot 4.7.2-stable)

## 1. Directory & Repository Topology
The tree as it stands after Phase 17 (the Living Storybook Atelier). File names and ids that saves, RPCs and scenes carry keep their old spelling (`hub_town`, `dungeon_dojo`, `rune_plate.gd`, `minion_camp.gd`); what players read is in the Lens's words.
```text
games/everwood/
├── CLAUDE.md                           # The engineering contract
├── project.godot                       # Main scene: scenes/worlds/oakshire_vale.tscn
├── docs/                               # 01–17: vision, GDDs, this TDD, balance, the Mythopoetic Lens, audio, world visuals
├── scenes/worlds/oakshire_vale.tscn    # Oakshire Vale, the starting world
├── data/landblocks/                    # Baked 128 m Landblocks + HLOD proxies (tools/build_*.gd)
├── tools/
│   ├── build_levels.gd                 # Builds hub_town, dungeon_dojo and the Bramble-Bridge trail's Landblocks
│   ├── build_oakshire_vale.gd          # Bakes Oakshire Vale's field, horizon and Landblocks
│   ├── build_input_map.gd              # Writes the Input Map
│   ├── smoke_test.gd                   # Headless functional checks (runs the five below last)
│   ├── test_world_grid.gd · test_oakshire_vale.gd · test_mythopoetic_lens.gd · test_adaptive_audio.gd
│   ├── test_world_visuals.gd           # The storybook world: catalog, atelier, shaders, sightlines, succession
│   └── fetch_terrain3d.sh              # Optional Terrain3D addon
└── src/
    ├── autoloads/
    │   ├── network_manager.gd          # ENet host/client + composite player_id registry
    │   ├── instance_manager.gd         # SubViewport World3D switcher (Oakshire Vale, Bramble-Bridge, the expedition)
    │   ├── combat_director.gd          # Strikes, hit-stop, seals and Four-Sign detonations, telegraphs
    │   ├── party_progress.gd           # The family save: Chimes, cards, kits, trail level, sightings
    │   └── audio_cues.gd               # Synthesized cues (positional ones through AudioDirector's pool)
    ├── core/
    │   ├── audio_director.gd           # Autoload "Score": buses, Deck A/B, combat stages, 32-voice 3D pool, stingers
    │   ├── audio_catalog.gd            # Zone, Sign, Calling and boss sound profiles by id
    │   └── procedural_chamber_synth.gd # Code-built stems, stingers and station ambience
    ├── resources/                      # Typed data: actions, stats, kits, cards, Signs, encounters,
    │   │                               # Callings, MobVariantResource, StewardshipZoneResource,
    │   │                               # Zone/Sign/Calling/Boss audio profiles, ZoneBiomeResource,
    │   │                               # WorldPropKitResource, ZoneSuccessionVisualResource
    │   └── …
    ├── components/
    │   ├── input_component.gd          # Master, Adventurer and Squire Gambit assist tiers
    │   ├── action_queue_component.gd   # 2-slot KOTOR buffer and the Flow-Link evaluator
    │   ├── stats_component.gd          # Authoritative health, stamina, pips, poise, mitigation
    │   ├── threat_component.gd         # Each foe's threat table and taunt lock
    │   ├── hitbox_component.gd · hurtbox_component.gd
    │   ├── braced_guard_component.gd   # Foes' Braced Front Guard
    │   ├── soul_tether_component.gd · companion_ai_component.gd · network_sync_component.gd
    │   └── state_machine/              # Idle, Locomotion, Attack, Guard, Dodge, Stagger, Downed
    ├── combat/
    │   ├── sign_flow_component.gd      # Heroes: the Hearth-Rite Tuck and in-combat Sign-Flow
    │   ├── glimmer_spot_component.gd   # Foes with an encounter: Glimmer-Spots and Bravery Counters
    │   ├── hob_spectrum_component.gd   # Foes: the Hob-to-Boggart Spectrum and Un-Boggarting
    │   └── unboggart_fx.gd             # The released bird or path-light, and the lulled cairn
    ├── actors/
    │   ├── actor_base.gd               # Root CharacterBody3D wiring components via signals
    │   ├── actor_visuals.gd            # Code-built storybook puppets (+ assets/models/<id>.glb hook)
    │   ├── arsenal_catalog.gd          # Autoload: Signs, armor, weapons, Scribe Sign-Cards, Callings, encounters
    │   ├── bestiary.gd                 # Oakshire Vale's six families of First-Quiet kin
    │   ├── mythopoetic_atlas.gd        # The Six-Zone Stewardship Atlas and each place's zone
    │   ├── boss_dummy.gd · woodland_minion.gd · wild_mob.gd · mob_spawner.gd
    │   ├── chime_post.gd · hush_crack_landmark.gd # A threshold's rhyme-post; a camp's Hush-Crack and Lulled Cairn
    │   └── …                           # Shrines, gates, portals, chests, townsfolk, FX
    ├── world/                          # Landblock streaming: WorldGridManager, layouts, WorldStateDB, nav
    │   ├── world_visual_catalog.gd     # Biomes, kits, succession looks, shared world materials
    │   ├── world_atmosphere_director.gd # Autoload "Atmosphere": atelier, sky/sun/fog, shader globals, succession
    │   ├── procedural_texture_atelier.gd · world_asset_catalog.gd · world_kit_instance.gd
    │   ├── chunk_clutter_baker.gd · horizon_vista_ring.gd
    │   └── shaders/                    # Triplanar, terrain splat, foliage wind, water stream (+ shared include)
    ├── levels/                         # LevelBase, HubTown, DungeonDojo, EverwoodWorld, OakshireVale
    └── ui/
        ├── player_hud.gd               # Each player's cell: banners, boss frame, prompts
        ├── cross_grimoire_hud.gd       # The bottom-centre cross, the Chime-Post ribbon, the Hearth-Rite border
        ├── cross_grimoire_diamond_widget.gd · grimoire_binder_panel.gd · scribery_shop_panel.gd
        └── split_screen_viewport_grid.gd # Dynamic 1-to-4 player SubViewport container
```

## 2. Architecture Notes

### 2.1 Composition
Every actor is an `ActorBase` (`CharacterBody3D`) that builds its own child components in `_build_components()`: stats, the action queue, the state machine, hit/hurtboxes and network sync for everyone; input and Sign-Flow for heroes; threat, the Braced Front Guard, a Glimmer-Spot (with an encounter) and the **Hob-to-Boggart Spectrum** for foes. Behaviour that differs by kind of actor comes from small virtuals (`glimmer_encounter_id()`, `is_beaten()`, `configure_spirit()`) and from data, never from `match` branches on ids (08 Gate 4).

### 2.2 The Hob-to-Boggart Spectrum (`HobSpectrumComponent`, 15 GDD §6.1)
Every foe carries one. Its states are plain enums, so saves and RPCs never need them:

| Identifier | Values | Meaning |
|---|---|---|
| `EquilibriumState` | `HOB_BENIGN`, `BOGGART_AWOKEN` | Where the spirit stands. A benign hob becomes `BOGGART_AWOKEN` the moment it's struck. |
| `SpiritState` | `STATE_CURIOUS`, `STATE_SOOTHED`, `STATE_SLUMBER`, `STATE_CHALLENGE_ROAR`, `STATE_HOSTILE`, `STATE_UNBOGGART_RELEASE`, `STATE_LULLED_CAIRN`, `STATE_STEWARD_HELPER` | What it's doing now. |
| `UnboggartResolution` | `STATE_UNBOGGART_RELEASE`, `STATE_LULLED_CAIRN`, `STATE_STEWARD_HELPER` | How it's un-boggarted when beaten. |
| `ReleaseForm` | `SEA_SWALLOW`, `HEDGE_WREN`, `PATH_LIGHT`, `SINK_TO_SLEEP` | What a released spirit becomes. |
| `is_maker_seal_upright: bool` / `is_maker_seal_exposed: bool` | — | A Furrow Iron-Man's chest seal: upside-down until a Warm-Hearth strike opens it and an Iron-Root strike turns it. |

- **Data first.** `MobVariantResource` carries `equilibrium`, `resolution`, `release_form`, `roars` and `has_maker_seal`; the `Bestiary` fills them per family. The woodland kin and the Cairnsman set theirs in `configure_spirit()`.
- **Parley without a new button.** A curious hob adds a `ParleyPoint` (an `Interactable`, 6 m reach). A hero within reach gets a 180-frame window in which `Light`—the Squire Gambit's one button—waves the Truce-Sign.
- **Authority.** The host decides parleys and seal turns and tells the other peers by RPC. Every peer resolves a beaten spirit from its synced health, so each draws the same sea-swallow or cairn.

### 2.3 The Mythopoetic Atlas and the Chime-Post ribbon
`MythopoeticAtlas` registers six `StewardshipZoneResource`s (name, Cooper Sign, harmony Signs, crack, kin, a four-line rhyme and the phrases each Sign tints) and maps every built place to its zone. Each level names its arrival place (`LevelBase.home_place()`); crossing a threshold calls `PlayerHUD.enter_place()`, and a new zone unfurls a couplet on `CrossGrimoireHUD`'s ribbon. `SignFlowComponent.hearth_rite_prepared` sings it again, and `CrossGrimoireHUD` draws the Saffron-Gold ember border while the Tuck is held.

### 2.4 The adaptive score ([16_ADAPTIVE_AUDIO_ARCHITECTURE.md](16_ADAPTIVE_AUDIO_ARCHITECTURE.md) §8)
`AudioDirector` (autoload `Score`) builds the five buses in code and plays two decks, each one zone's four phase-locked stems in an `AudioStreamSynchronized`, driven only by `set_sync_stream_volume()`. Every 0.4 s it resolves one party state from the local players: the zone most of them stand in (`LevelBase.music_profile_at()`), the depth blend, and the threat round them (Exploration, Pre-Warm, Skirmish, Boss, Exhale). Profiles are data in `AudioCatalog`; until curated stems exist, `ProceduralChamberSynth` renders each zone's stems on worker threads. Positional sounds share a 32-voice `AudioStreamPlayer3D` pool made once at start (45 m cull, 50 ms per kind, `area_mask = 1`).

### 2.5 The storybook world ([17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md](17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md) §8)
- **Data.** `WorldVisualCatalog` registers the biomes, kits and succession looks, and hands out one shared material per look (`craft()`, `foliage()`, `water()` and the rest). Levels say which biome a spot wears (`LevelBase.visual_biome_at()`); nothing in the director names a place.
- **Global shader parameters** (`project.godot` `[shader_globals]`) carry what every world surface needs: the atelier's three `Texture2DArray`s, the heroes, the four nearest open Hush-Cracks, the blooms and the wind. `WorldAtmosphereDirector` (autoload `Atmosphere`) sets them, renders the atelier on worker threads, and eases the level's sky, sun and fog to the biome most local players stand in.
- **Kits are code, placed by id.** `WorldAssetCatalog` merges a kit's static parts into one mesh, one surface per material, cached by options. Scenes hold `WorldKitInstance` nodes; a new kit builds in a 1.5 ms-a-frame queue so streaming never stalls. A `.glb` at `res://assets/models/world/<kit_id>.glb` replaces it, and HLOD bakes use each kit's low-poly stand-in.
- **Colour space.** Palette colours, vertex colours and MultiMesh instance colours are authored in sRGB; the shaders convert them, so Mode B ground, HLODs and clutter match Terrain3D's.
- **Succession.** `HushCrackLandmark` registers with the director; `set_succession_state()` takes a camp's id or a biome's. A camp's cleared state stays in `WorldStateDB`, so it streams back as a cairn.

### 2.6 Verification
`godot --headless --check-only -s <script>` on every changed script, a headless boot, and `tools/smoke_test.gd` (see the README). `tools/test_mythopoetic_lens.gd` lints every name the game shows against the four Linter Rules, the world's biome and kit names included. `tools/test_world_visuals.gd` checks the storybook world.
