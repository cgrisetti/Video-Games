# 03_GODOT_TDD.md — Technical Design Document (Godot 4.7.2-stable)

## 1. Directory & Repository Topology
The tree as it stands after Phase 18 (pastoral rendering, the living blight, the camera's pitch and the Wayfarer's map). File names and ids that saves, RPCs and scenes carry keep their old spelling (`hub_town`, `dungeon_dojo`, `rune_plate.gd`, `minion_camp.gd`); what players read is in the Lens's words.
```text
games/everwood/
├── CLAUDE.md                           # The engineering contract
├── project.godot                       # Main scene: scenes/worlds/oakshire_vale.tscn
├── docs/                               # 01–22: vision, GDDs, this TDD, balance, the Mythopoetic Lens, audio, world visuals, wayfinding, heroes, the Caldera, levels and menus
├── scenes/worlds/oakshire_vale.tscn    # Oakshire Vale, the starting world
├── data/landblocks/                    # Baked 128 m Landblocks + HLOD proxies + cartography.json (tools/build_*.gd)
├── tools/
│   ├── build_levels.gd                 # Builds hub_town, dungeon_dojo and the Bramble-Bridge trail's Landblocks
│   ├── build_oakshire_vale.gd          # Bakes Oakshire Vale's field, horizon and Landblocks
│   ├── build_input_map.gd              # Writes the Input Map
│   ├── smoke_test.gd                   # Headless functional checks (runs the five below last)
│   ├── test_world_grid.gd · test_oakshire_vale.gd · test_mythopoetic_lens.gd · test_adaptive_audio.gd
│   ├── test_world_visuals.gd           # The storybook world: catalog, atelier, shaders, sightlines, succession
│   ├── test_pastoral_cartography.gd    # Phase 18: camera pitch, labels, sculpted kits, clutter, the map and Atlas
│   └── fetch_terrain3d.sh              # Optional Terrain3D addon
└── src/
    ├── autoloads/
    │   ├── network_manager.gd          # ENet host/client + composite player_id registry
    │   ├── instance_manager.gd         # SubViewport World3D switcher (Oakshire Vale, Bramble-Bridge, the expedition)
    │   ├── combat_director.gd          # Strikes, hit-stop, seals and Four-Sign detonations, telegraphs
    │   ├── party_progress.gd           # The family save: Chimes, cards, kits, trail level, sightings
    │   ├── settings_manager.gd         # Autoload "Settings": the Options menu's settings, saved as JSON (doc 13)
    │   ├── save_manager.gd             # JSON files written safely (a temp file, then renamed)
    │   └── audio_cues.gd               # Synthesized cues (positional ones through AudioDirector's pool)
    ├── core/
    │   ├── audio_director.gd           # Autoload "Score": buses, Deck A/B, combat stages, 32-voice 3D pool, stingers
    │   ├── audio_catalog.gd            # Zone, Sign, Calling and boss sound profiles by id
    │   └── procedural_chamber_synth.gd # Code-built stems, stingers and station ambience
    ├── resources/                      # Typed data: actions, stats, kits, cards, Signs, encounters, combo forms,
    │   │                               # Callings, MobVariantResource, StewardshipZoneResource,
    │   │                               # Zone/Sign/Calling/Boss audio profiles, ZoneBiomeResource,
    │   │                               # WorldPropKitResource, ZoneSuccessionVisualResource, WorldMapZoneResource,
    │   │                               # HeroAppearanceResource (a Calling's look), WeaponVisualTierResource (a tier's look)
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
    │   ├── sign_flow_component.gd      # Heroes: the Hearth-Rite Tuck, in-combat Sign-Flow, and each
    │   │                               # role's coat (One-and-Done, Ward-Mantle, Aegis Ward, Ink-Share)
    │   ├── combo_chain_component.gd    # Heroes: the directional combo forms and their finishers
    │   ├── glimmer_spot_component.gd   # Foes with an encounter: Glimmer-Spots and Bravery Counters
    │   ├── posture_escalation_component.gd # Foes of Miyamoto Tier 1 and 2: the armour-drop and its locks
    │   ├── boss_gate_component.gd      # Four-gate bosses: the Measure, Summons, Tempest and Seal-Turn
    │   ├── hob_spectrum_component.gd   # Foes: the Hob-to-Boggart Spectrum and Un-Boggarting
    │   └── unboggart_fx.gd             # The released bird or path-light, and the lulled cairn
    ├── actors/
    │   ├── actor_base.gd               # Root CharacterBody3D wiring components via signals
    │   ├── actor_visuals.gd            # A hero: the rig, its surfaces, kit and weapon, posed each tick (+ .glb hooks)
    │   ├── hero_rig_builder.gd         # The canonical 24-bone Skeleton3D, its Skin and four read-only sockets
    │   ├── hero_mesh_atelier.gd        # Catmull-Rom superellipse lofts: five skinned regions, props, 16 weapon sculpts
    │   ├── hero_combat_animator.gd     # The procedural AnimationLibrary, sampled frame-locked to the action's clock
    │   ├── hero_clip_book.gd · hero_pose_baker.gd # The 45 clips' key poses, and aim-authored poses into bone rotations
    │   ├── storybook_kinematics_modifier_3d.gd # Springs, lean, foot-plant and grip IK, look-at, hit-stop tremor
    │   ├── shaders/storybook_hero_atelier.gdshader # The heroes' Three-Value Harmony shader
    │   ├── arsenal_catalog.gd          # Autoload: Signs, armor, weapons, Scribe Sign-Cards, Callings, encounters
    │   ├── bestiary.gd                 # Oakshire Vale's six families of First-Quiet kin
    │   ├── mythopoetic_atlas.gd        # The Six-Zone Stewardship Atlas and each place's zone
    │   ├── boss_dummy.gd · woodland_minion.gd · wild_mob.gd · mob_spawner.gd
    │   ├── chime_post.gd · hush_crack_landmark.gd # A threshold's rhyme-post; a camp's Hush-Crack and Lulled Cairn
    │   ├── shape_kit.gd                # Primitives, and the sculpted generators (trunks, crowns, tufts, megaliths, cornices, skirts)
    │   ├── wayfarer_trail_guide_fx.gd  # The firefly trail to a pinned place
    │   └── …                           # Shrines, gates, portals, chests, townsfolk, FX
    ├── world/                          # Landblock streaming: WorldGridManager, layouts, WorldStateDB, nav
    │   ├── world_visual_catalog.gd     # Biomes, kits, succession looks, shared world materials
    │   ├── world_atmosphere_director.gd # Autoload "Atmosphere": atelier, sky/sun/fog, shader globals, succession
    │   ├── procedural_texture_atelier.gd · world_asset_catalog.gd · world_kit_instance.gd
    │   ├── chunk_clutter_baker.gd · horizon_vista_ring.gd
    │   └── shaders/                    # Triplanar, terrain splat, foliage wind, water stream, hush ring (+ shared include)
    ├── levels/                         # LevelBase, HubTown, DungeonDojo, EverwoodWorld, OakshireVale
    └── ui/
        ├── player_hud.gd               # Each player's cell: banners, boss frame, prompts
        ├── cross_grimoire_hud.gd       # The bottom-centre cross, the Chime-Post ribbon, the Hearth-Rite border
        ├── cross_grimoire_diamond_widget.gd · grimoire_binder_panel.gd · scribery_shop_panel.gd
        ├── player_camera.gd            # Each player's camera: yaw, pitch (-12 to +52 degrees), boom, ground clamp
        ├── world_label_style.gd        # How every Label3D reads, and the station layer
        ├── cartography_baker.gd        # The parchment map of a level, painted in code
        ├── wayfarer_minimap_widget.gd · world_map_panel.gd # The minimap, and the Zone and World Maps
        ├── options_menu.gd             # Options: Audio, Video, Controls (key and pad drawings), Gameplay
        ├── dev_admin_panel.gd          # The Developer Tools (F1): test tools only, apart from the player's menus
        ├── enemy_nameplate.gd          # An enemy's level and danger badge
        └── split_screen_viewport_grid.gd # Dynamic 1-to-4 player SubViewport container
```

## 2. Architecture Notes

### 2.1 Composition
Every actor is an `ActorBase` (`CharacterBody3D`) that builds its own child components in `_build_components()`: stats, the action queue, the state machine, hit/hurtboxes and network sync for everyone; input, Sign-Flow and the combo forms (`ComboChainComponent`) for heroes; threat, the Braced Front Guard, a Glimmer-Spot and the Miyamoto armour-drop (`PostureEscalationComponent`, with an encounter), the four gates (`BossGateComponent`, raid bosses) and the **Hob-to-Boggart Spectrum** for foes. Behaviour that differs by kind of actor comes from small virtuals (`glimmer_encounter_id()`, `is_beaten()`, `configure_spirit()`) and from data, never from `match` branches on ids (08 Gate 4).

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

### 2.3 Sign-Flow's Phase 12 Kaizen pass ([14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md](14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md) §8)
- **A strike carries its attacker's state by id.** A combo finisher sets `CombatEvent.combo_id`, a One-and-Done `one_and_done` and `finisher_card_id`, a Support's Ink-Share `coat_sign` and `ink_share_from`. The foe's owner looks the numbers up in `ArsenalCatalog` (`_apply_flourishes`) and checks the claim (the form is known at the party's level and ends in the strike's posture; the leaf is in the hero's diorama; the lent Sign is in the Support's).
- **One judging order on the foe's owner** (`ActorBase.receive_strike`): the Braced Front Guard, then the boss's gates (a Seal-Turn settles the strike), its Glimmer-Spot, then a Tier 1 or 2 lock; on a hero, the Ward Blessing and a Ward-Mantle soften it before the guard maths. A stun lands after the hit (`CombatEvent.stun_seconds`), and a Ward-Mantle or Aegis Ward shrugs it off in `ActorBase.stagger()`.
- **Support blessings** (Aegis Ward, Ink-Share) go to each hero's owner by RPC (`CombatDirector.share_ink`, `grant_aegis_ward`); a peer only accepts one from the Support's own peer, for a Sign the Support carries.
- **The gates and locks** run on the foe's owner and tell the other peers by RPC: the lock and its plate, the Aegis Mantle, the summoned henchmen (a `MinionCamp` with `summoned` set), the roar and the seal.

### 2.4 The Mythopoetic Atlas and the Chime-Post ribbon
`MythopoeticAtlas` registers six `StewardshipZoneResource`s (name, Cooper Sign, harmony Signs, crack, kin, a four-line rhyme and the phrases each Sign tints) and maps every built place to its zone. Each level names its arrival place (`LevelBase.home_place()`); crossing a threshold calls `PlayerHUD.enter_place()`, and a new zone unfurls a couplet on `CrossGrimoireHUD`'s ribbon. `SignFlowComponent.hearth_rite_prepared` sings it again, and `CrossGrimoireHUD` draws the Saffron-Gold ember border while the Tuck is held.

### 2.5 The adaptive score ([16_ADAPTIVE_AUDIO_ARCHITECTURE.md](16_ADAPTIVE_AUDIO_ARCHITECTURE.md) §8)
`AudioDirector` (autoload `Score`) builds the five buses in code and plays two decks, each one zone's four phase-locked stems in an `AudioStreamSynchronized`, driven only by `set_sync_stream_volume()`. Every 0.4 s it resolves one party state from the local players: the zone most of them stand in (`LevelBase.music_profile_at()`), the depth blend, and the threat round them (Exploration, Pre-Warm, Skirmish, Boss, Exhale). Profiles are data in `AudioCatalog`; until curated stems exist, `ProceduralChamberSynth` renders each zone's stems on worker threads. Positional sounds share a 32-voice `AudioStreamPlayer3D` pool made once at start (45 m cull, 50 ms per kind, `area_mask = 1`).

### 2.6 The storybook world ([17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md](17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md) §8)
- **Data.** `WorldVisualCatalog` registers the biomes, kits and succession looks, and hands out one shared material per look (`craft()`, `foliage()`, `water()` and the rest). Levels say which biome a spot wears (`LevelBase.visual_biome_at()`); nothing in the director names a place.
- **Global shader parameters** (`project.godot` `[shader_globals]`) carry what every world surface needs: the atelier's three `Texture2DArray`s, the heroes, the four nearest open Hush-Cracks, the blooms and the wind. `WorldAtmosphereDirector` (autoload `Atmosphere`) sets them, renders the atelier on worker threads, and eases the level's sky, sun and fog to the biome most local players stand in.
- **Kits are code, placed by id.** `WorldAssetCatalog` merges a kit's static parts into one mesh, one surface per material, cached by options. Scenes hold `WorldKitInstance` nodes; a new kit builds in a 1.5 ms-a-frame queue so streaming never stalls. A `.glb` at `res://assets/models/world/<kit_id>.glb` replaces it, and HLOD bakes use each kit's low-poly stand-in.
- **Colour space.** Palette colours, vertex colours and MultiMesh instance colours are authored in sRGB; the shaders convert them, so Mode B ground, HLODs and clutter match Terrain3D's.
- **Succession.** `HushCrackLandmark` registers with the director; `set_succession_state()` takes a camp's id or a biome's. A camp's cleared state stays in `WorldStateDB`, so it streams back as a cairn.

### 2.7 The pastoral pass and the Wayfarer's map ([18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md](18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md) §9)
- **Ground.** `storybook_ground()` in the shared include blends a road into turf by height and noise (`frayed_road`), lays a trodden-loam verge with 18% AO, and snaps slopes to scree and roots (walkable banks) or strata with a dark toe (cliffs). The Mode B splat and the Terrain3D shader both call it. Builders camber the roads (+4 cm flagged, -5 cm footpaths).
- **Sculpted meshes.** `ShapeKit`'s generators return `ArrayMesh`es with vertex shading; `Parts.add_mesh()` merges them into kits keeping it, and `WorldVisualCatalog.shaded()` turns that shading on in the triplanar shader. Crowns use `canopy()` (the three-band leaf ramp and backlight in `storybook_cel_light`'s `STORYBOOK_FOLIAGE_LIGHT` branch); grass uses `grass_blades()`.
- **Clutter.** `ChunkClutterBaker.bake()` takes the layout's ground colour (grass roots), its road-edge distance (curbs and verges) and its crest pieces (cornices), all pure, so it still runs on worker threads. Six batches, each with `FADE_SELF`.
- **The blight.** The director's globals carry each open crack (22 m), the blight's palette and Frozen Wind, the Lantern's Promise halos (5.5 m) and the cloud-shadow parameters; every world shader reads them through `apply_succession()`, `blight_at()` and `cloud_shadow()`.
- **The camera.** `PlayerCamera` reads `InputComponent.camera_pitch_input` and `take_mouse_pitch()`, interpolates its pivot and boom by pitch, clamps itself above the ground by a ray, and drops `WorldLabelStyle.STATION_LABEL_LAYER` from its cull mask while its player's menu is open. `LevelBase.set_camera_pitch_degrees()` / `get_camera_pitch_degrees()` address cameras by seat (P-number).
- **Labels.** `WorldLabelStyle.watch()` styles every `Label3D` as it enters the tree (deferred, after its maker has set it up), so no script needs to know the style.
- **The map.** `CartographyBaker` gathers a level's ground on the main thread (a layout's functions, or rays at a walled instance's colliders) and paints on a worker thread; `poll()` hands the texture over on the main thread, and `finish_pending()` waits for any paint before a level leaves. Builders write `cartography.json` (footprints, cracks) beside a world's landblocks. Shrines, desks and portals join the `map_glyphs` group.

### 2.8 The hero rig ([19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md](19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md) §7)
- **Skeleton.** `HeroRigBuilder.build_hero_skeleton()` adds 24 bones parent-first, sets each rest so its +Y runs along the bone (its X the model's +X where it can be), makes one `Skin` with `create_skin_from_rest_transforms()` and hangs four `BoneAttachment3D` sockets with `override_pose` off. Its modifier mode is manual: `ActorVisuals.update_rig()` poses the bones and then calls `Skeleton3D.advance()`, so the modifier runs on that tick's pose. Godot restores the un-modified pose after each update, so `get_bone_pose_*` reads the animator's pose and attachments follow the final one.
- **Surfaces.** `HeroMeshAtelier` lofts closed superellipse rings along Catmull-Rom spines through a `SurfaceTool` (bones and weights per ring, blended between rings; normals by finite differences leaning 35% to a radial proxy; triangles wound to face their normals). Vertex colours carry AO (0.25 under each armour layer's lip), worn edges, a material id (cloth below 0.3, timber below 0.42, leather below 0.5, metal below 0.7, then skin, face and eyes) and Sign veins; UV2.x the height at rest. On the face (`MAT_FACE`, the loft's `face_zones` option) the UVs carry the portrait zones instead: the malar flush, the forehead's warmth and, in UV2.y, the jaw's cool. Coats are built in stepped shells round Layer 0's torso (`_torso_shell()`, `_skirt()`). Surfaces are cached by `HeroAppearanceResource.sculpt_key()` and coat, weapons by type and tier.
- **Animation.** `HeroClipBook` writes key poses by aim (arms in the chest's frame, legs in the ground's or the hips'), `HeroPoseBaker` turns them into local rotations, and `HeroCombatAnimator` keys them into rotation, position and scale tracks of one shared `AnimationLibrary` on an `AnimationPlayer`. The player stays inactive: the animator samples the tracks itself each physics tick, at the frame the action's phase says (wind-up, active and recovery stretched onto the action's own timing), cross-fades, and layers one-shots (parley, parry, Bravery Counter) and one-arm overlays (the card choreography).
- **Kinematics.** `StorybookKinematicsModifier3D` (a GDScript `SkeletonModifier3D`, never `SpringBoneSimulator3D`) reads the pose, adds lean, bank, the winded heave, look-at and the hit-stop tremor, drops the hips on slopes, plants the feet and puts the off hand on a two-hander's `HaftGripMarker` (or the bow hand at the jaw) by two-bone IK, swings the cloak and beard on exact damped springs held outside a body capsule, squashes the hips through a hit-stop, and writes it back. `ActorVisuals` feeds it the velocity, stamina, ground heights (two rays a tick), the grip and the look target.
- **The solo boot.** `LevelBase.solo_youth_boot` seats the first person as the Wayfarers, Unsworn on the trail kit like any seat; an Unsworn player hero is drawn as the Level 1 youth (`ActorVisuals.is_youth_seat()`, `HeroYouthAtelier`; docs/21). `LevelBase.auto_backfill_companions` gates companion backfill (`--with-companions`, `set_companion_backfill_enabled()`). The Network Manager still knows nothing about classes.

### 2.9 Levels, the Forge, the hand and the Atelier menus ([22_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md](22_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md) §5)
- **Levels.** `PartyProgress.hero_xp` keeps each Fellowship's XP; `character_level(class_id)` (1 to 20) drives the hand, the Ink-Well and the Forge, while `trail_level()` (1 to 10) still paces the Bramble-Bridge trail. `steward_threat()` is Character Level plus the worn material's rank.
- **The Forge.** `PartyProgress.promoted_tiers` holds each Fellowship's weapon and armour tier; `request_promotion` is host-checked. `ArsenalCatalog.default_seal_loadout(..., use_promotions = true)` builds the live hero's hand on those tiers (capped by level), and a chosen hand keeps its cards but takes the promoted tiers too.
- **The hand.** `GrimoireRules` is the one table of unlock levels (Seals at 3, 6, 11; R at 4, L at 6, the Tuck at 11, L+R at 17), Ink-Drop costs and well depths. `GrimoireRules.all_open()` (the classic full kits, `PartyProgress.endgame_kits_for_testing`) keeps the older checks on the old rules. Seal cards carry `slot_passives` per piece (the Contextual Slot Rule).
- **The Ink-Well.** `CharacterStatsResource.ink_well`, `StatsComponent.add_ink` and `CombatDirector.refill_ink` (calm foes by rank, a boss's beats, gifts, a Hearth-Brazier) with `CombatEvent.ink_refill` on the wire.
- **Finishes.** `PartyProgress.ink_marks`, `ready_to_press`, `maker_seals` and `rubbings`; the Scribery presses, the Scribe Desk drafts.
- **Menus.** `AtelierTheme` styles the Options menu, the Binder, the Scribe Desk and the Scribery. `SettingsManager` adds `world_detail` (cameras in the `player_cameras` group scale their horizon, `PlayerCamera.set_horizon`), `grass_density` (`ChunkClutterBaker.grass_count`), `craft_textures` (the views' mipmap bias), `damage_numbers`, `rhyme_ribbon_size` and `ink_ready_border`. The Seal Press opens near nodes in the `hearth_braziers` and `scribe_desks` groups.

### 2.10 Verification
`godot --headless --check-only -s <script>` on every changed script, a headless boot, and `tools/smoke_test.gd` (see the README). `tools/test_mythopoetic_lens.gd` lints every name the game shows against the four Linter Rules, the world's biome and kit names included. `tools/test_world_visuals.gd` checks the storybook world, and `tools/test_hero_rig.gd` the solo boot and the hero rig.
