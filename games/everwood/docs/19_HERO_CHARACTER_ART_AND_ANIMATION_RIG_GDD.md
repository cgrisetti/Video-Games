# 19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md — The Living Wooden Marionette: Next-Gen 24-Bone Hero Rig, Modular Equipment Architecture, Procedural Kinematics, & Storybook Cel-Shader Pipeline

> **SYSTEM DIRECTIVE FOR GEMINI & CLAUDE CODE:** This document is the authoritative character technical art, skeletal rigging, procedural kinematics, and modular equipment specification for *Everwood (Oakshire Raids)* in Godot 4.7.2-stable. Following our Phase 17–18 World, Shader, Camera, and Cartography overhaul (`17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md` and `18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md`), this specification establishes the foundational hero character architecture—beginning with our flagship archetype, the **Iron-Woodsman** (`Wayfarer` Primary + `Stout Heart` `+Tank` Secondary, `Tizzi-Wed-Green` Heritage)—and scales polymorphically across all $3 \times 3$ Callings, 4 Coats, and $4 \times 4$ Weapon Tiers. Every mesh generator, skeleton builder, kinematic solver, and shader committed to the repository MUST adhere to the Five Mandatory Gates, the Three-Value Harmony, and the headless CI verification checks defined below.

---

## 1. Stage 1: Ideation, Industry Post-Mortem, The Musk Razor, & The Three-Value Harmony

### 1.1 Industry Post-Mortem: Expressive Storybook Heroes at a $4.8\text{ m}$ Co-Op Eye-Line
To elevate *Everwood*'s heroes from static, disconnected primitive capsules into tactile, living storybook figures that look handmade and punch far above Godot 4.7's weight class, we synthesize lessons from four industry benchmarks:

1. **The Legend of Zelda: The Wind Waker & Breath of the Wild (*Nintendo EPD*) — Heroic Proportions & Three-Value Readability:**
   * *What Succeeded:* Nintendo recognized that realistic $8\text{-head}$ human proportions turn into unreadable toothpicks from an elevated third-person camera. By shifting to a **heroic $5.0\text{ to }5.5\text{-head}$ scale** with slightly oversized hands, boots, head, and weapon silhouettes, every posture change and sword swing reads from across the room.
   * *The Trap to Avoid:* High-frequency surface noise across the middle of the torso blurs when four players fight side-by-side on a split-screen television.
   * *Everwood Application:* Lock our hero rig to a **5.5-Head "Tactile Artisan" Proportion ($1.80\text{ m}$ tall)** and enforce a strict bottom-to-top **Three-Value Luminance Hierarchy** (§1.3) that draws the player's eye directly to the hero's head, hands, and weapon arc.
2. **Guilty Gear Strive (*Arc System Works*) & Spider-Man: Into the Spider-Verse — Hybrid Stepped-to-Fluid Motion & Custom Normals:**
   * *What Succeeded:* Purely linear 60 FPS procedural tweening often feels "floaty" or robotic because every frame has equal visual weight. *Arc System Works* holds key anticipation poses (Phase A wind-up) on crisp, extreme silhouettes before snapping through the active swing (Phase B) at full speed accompanied by a curved 3D smear mesh.
   * *Everwood Application:* Drive our procedural animation synthesizer (`HeroRigAnimator`) with **Non-Linear Anticipation Hold Curves** during `CombatActionResource` Phase A wind-ups, explosive $60\text{ Hz}$ release curves with a **3D Tapered Ribbon Smear** during Phase B active frames, and elastic spring-damped recovery during Phase C/D **Flow-Link** windows.
3. **Monster Hunter & Dark Souls (*Capcom / FromSoftware*) — Kinetic Weight Through Center-of-Mass & Two-Handed Haft Mechanics:**
   * *What Succeeded:* Heavy weapons feel heavy not because they move slowly, but because the **weapon leads the body's center of mass**. When swinging a heavy axe, the hips drop, the spine coils $60^\circ$ into the backswing, the leading hand slides up the timber haft for leverage, and the boots plant wide.
   * *Everwood Application:* Drive `Pelvis` vertical dip, `Spine_Lower`/`Spine_Upper` axial torsion, and dynamic `Hand_L` off-hand sliding grips directly from weapon weight and action phase.
4. **Tunic & Death's Door — Seamless Joint Skinning & Tactile Figurine Shading:**
   * *What Succeeded:* Characters look like cohesive, hand-carved wooden or clay figurines because limbs bend seamlessly without intersecting cylinder gaps, and materials separate matte wool, oiled leather, and brushed metal via anisotropic highlights.
   * *Everwood Application:* Replace disconnected child `MeshInstance3D` primitives with a **Unified Skinned `ArrayMesh` + Modular Socket Pipeline** (`HeroMeshBuilder`) bound to a deterministic **24-Bone `Skeleton3D`**, shaded by `hero_storybook_cel.gdshader`.

---

### 1.2 Applying the Musk Razor to Godot 4.7.2 Character & Animation Architecture
> *"Cut so deep that you are forced to add $10\%$ back in."* — `01_VISION.md`

| Bloated Industry Trap (What We Cut) | Why It Fails in a Code-First 5-Player Co-Op ARPG | The Harmonized $10\%$ Added Back In (*Everwood* Architecture) |
|---|---|---|
| **75-Bone Mocap Skeletons & Finger Micro-Rigs** | Wastes CPU skinning budget across 5 players + 15 foes in 4-way split-screen; fingers are $2\text{ px}$ wide at a $4.8\text{ m}$ camera height. | **The Deterministic 24-Bone Storybook `Skeleton3D` (`HeroSkeletonBuilder`):** Exact anatomical joints for spine torsion, clavicle shrug, 2-bone limb IK, mittens/gauntlet grip, and a 2-bone Verlet cloak chain. |
| **Sprawling 40-Node `AnimationTree` State Graphs** | Creates state-desync bugs where visual animations drift out of sync with `AttackState` and `ActionQueueComponent`'s authoritative frame timers. | **Phase-Locked Procedural Pose Synthesizer (`HeroRigAnimator`):** Reads `ActorBase`'s exact authoritative state (`Idle`, `Move`, `Attack` Phase A/B/C/D, `Guard`, `Dodge`, `Hearth-Rite Tuck`, `Truce-Sign`) and evaluates deterministic mathematical pose curves with zero frame drift. |
| **Heavy GPU `SoftBody3D` Cloth Simulations** | Jitters violently on character teleports/dodges, clips through shields, and spikes frame times in split-screen. | **Analytic Second-Order Verlet Spring-Bone Solver (`SpringBoneChain`):** Solves cape, apron, and lantern-pendulum physics in $< 0.03\text{ ms}$ with an analytical torso-sphere repulsion constraint so capes never clip through the body. |
| **Separate Un-Skinned Primitive Boxes per Limb** | Leaves ugly gaps and intersecting dark seams at shoulders, elbows, hips, and knees during deep combat stances. | **Continuous Skinned Tube/Loft `ArrayMesh` Generator (`HeroMeshBuilder`) + `.glb` Retarget Hook:** Generates seamless vertex-weighted torso and limb tubes in code while supporting drop-in `.glb` humanoids via `SkeletonProfileHumanoid`. |

---

### 1.3 The Three-Value Luminance & Color Harmony Contract
In Phases 17 and 18, all world ground surfaces (`storybook_terrain_splat.gdshader`) were calibrated to mid-value earthy tones ($35\%\text{–}65\%$ luminance: `#5B8C4A` meadow turf, `#C8BFA8` Bale-Way flagstones, `#48505E` hushed slate). To guarantee that every hero pops off the terrain instantly across 4 split-screen viewports, every character model and equipment coat must obey a strict **Vertical Value Gradient & 55 / 30 / 15 Ratio**:

```text
       ▲  VALUE 3: FOCAL CROWN & SIGN SPARK (82%–100% Luminance | 15% Area)
       │  • Head, Face, Beard/Hair, Hood/Kettle-Cap Crest, Pauldron Rims, Weapon Edge & Sign-Stone
       │  • Draws the eye immediately to the top 30% of the silhouette & the active weapon swing arc!
       ├──────────────────────────────────────────────────────────────────────────────────────────
       │  VALUE 2: CRAFT & CALLING SILHOUETTE (50%–68% Luminance | 30% Area)
       │  • Fellowship Tunic (Wayfarer Emerald / Shield-Sworn Cobalt / Lantern-Bearer Saffron)
       │  • Secondary Calling Tabard & Trim (+Tank Bronze / +DPS Bramble-Green / +Magic Violet)
       ├──────────────────────────────────────────────────────────────────────────────────────────
       ▼  VALUE 1: THE GROUNDED ANCHOR (18%–30% Luminance | 55% Area)
          • Cuffed Turn-Boots, Heavy Trousers, Split-Leather Hewing Apron, Under-Mantle Shadow
          • High-contrast dark anchor against bright #C8BFA8 flagstones and #5B8C4A sunlit grass!
```

| Value Tier & Screen Share | Target Luminance ($Y$) | *Iron-Woodsman* (`Tizzi-Wed-Green`) Canonical Palette | Visual & Gameplay Role in 4-Player Split-Screen |
|---|---|---|---|
| **Value 1: The Grounded Anchor**<br>*($55\%$ of Surface Area — Lower Body & Core Mantle)* | $18\% \text{ to } 30\%$ | **Heartwood Bark Leather** (`#2B2017`)<br>**Charcoal Bog-Iron** (`#2D3238`)<br>**Deep Pine-Shadow Wool** (`#243622`) | Prevents the character's boots and legs from washing out against sunlit limestone roads (`#C8BFA8`) or bright grass (`#5B8C4A`). |
| **Value 2: The Craft & Calling Silhouette**<br>*($30\%$ of Surface Area — Mid Torso, Arms, & Tabard)* | $50\% \text{ to } 68\%$ | **Wayfarer Forest Tunic** (`#3B7A47`)<br>**Stout-Heart Bronze Tabard** (`#B87A3D`)<br>**Adze-Hewn Ash & Oiled Hide** (`#8C6239`) | Communicates the hero's **Primary Fellowship** (Row) and **Secondary Calling** (Column) in the $3 \times 3$ Matrix at a single glance. |
| **Value 3: The Focal Crown & Sign Spark**<br>*($15\%$ of Surface Area — Head, Shoulders, Hands, Weapon)* | $82\% \text{ to } 100\%$<br>*(+ $1.5\times$ Emission)* | **Sunlit Warm Skin & Silver-Speckled Beard** (`#F0C8A8` / `#8E8A84`)<br>**Gilded Brass Kettle-Brim & Rivets** (`#E5C158`)<br>**Active Scribe Sign Inlay** (`#D9822B` Amber / `#38A3D1` Azure / `#F2B749` Saffron / `#8C52D9` Violet) | Locks player tracking onto the hero's head direction, off-hand posture (`Greatshield` / `Lantern` / `Quiver`), and weapon tip during fast BDO **Flow-Link** combos. |

---

### 1.4 Mandatory Five-Gate Verification (`08_EVERGREEN_DEV_BIBLE.md`)

| Gate ID & Pedigree | Mandatory Rule (`08_EVERGREEN_DEV_BIBLE.md`) | Verification Audit for Phase 19 Hero Rig & Animation Architecture | Gate Verdict |
|---|---|---|---|
| **GATE 1**<br>*Anti-Parasitic Harmony* | Must directly feed into at least two core pillars: Stamina/Poise, Four Signs, $3 \times 3$ Callings, or Chimes/Vellum. | Harmonizes with all four pillars: (1) **Stamina/Poise** is telegraphed visually via heavy weapon center-of-mass coil, winded 3rd-Light breath heave, and Perfect Guard parry sparks; (2) **The Four Signs** drive weapon Sign-stone emission, Hearth-Rite Tuck kneeling invocations, and vellum card flips; (3) **The $3 \times 3$ Callings** govern asymmetric pauldron/apron/tabard silhouettes and stowed off-hand props; (4) **Chimes & Progression** drive the 4-Tier weapon geometry evolution. | **PASS** |
| **GATE 2**<br>*The Musk Razor* | Strip secondary menus and extra keybinds; execute through the 6-Posture Controller Contract. | Zero new buttons or animation-wheel menus. Every animation—including the kneeling **Hearth-Rite Tuck** (hold `R` or `L+R` out of combat) and the Miyazaki **Truce-Sign Bow** (`Light` within $6.0\text{ m}$ of a curious hob)—fires automatically through the existing 6-Posture Controller Contract. | **PASS** |
| **GATE 3**<br>*Philological Linter & Single-Origin Antagonist Rule* | Pass the 4 Linter Rules (8-Year-Old Read-Aloud, Map-Sense compounds, hyphenated cadence, zero banned grimy/textbook words). | Uses strictly canonical terminology: `Iron-Woodsman`, `Bridge-Warden`, `Weald-Captain`, `Hearth-Guard`, `Hedge-Runner`, `Sign-Seeker`, `Bell-Keeper`, `Wind-Mender`, `Lantern-Scribe`; coats are `Bramble-Spun Jerkin`, `Hearth-Linen Coat`, `Hedgerow Wool-Mantle`, and `Iron-Wood Ring-Coat` (zero *Hauberk*, *Cuirass*, or *Lamellar*!); headgear is `Kettle-Cap` / `Coppice-Hood`. | **PASS** |
| **GATE 4**<br>*Schema-First Registry* | Content added as typed `Resource` data registered in central catalogs; polymorphic resolution. | All calling silhouettes, coat meshes, 4-tier weapon geometries, dye swatches, and animation profiles live in typed `HeroVisualProfileResource`, `CoatVisualSpecResource`, and `WeaponVisualSpecResource` schemas registered in `HeroVisualCatalog` (`src/actors/hero_visual_catalog.gd`). | **PASS** |
| **GATE 5**<br>*Code-First & Multi-Age Safe* | Deterministic GDScript build; headless CI safe; multi-age readable at $4.8\text{ m}$ camera height. | $100\%$ built in pure GDScript (`HeroSkeletonBuilder`, `HeroMeshBuilder`, `HeroRigAnimator`); passes `--headless --check-only` and `tools/smoke_test.gd`; oversized $5.5\text{-head}$ proportions and Value 3 focal accents allow a 4-year-old Squire to read hero facing and wind-up timing effortlessly. | **PASS** |

---

## 2. Character Architecture & Model Engineering: The Iron-Woodsman

### 2.1 Heroic Storybook Proportions (The $5.5\text{-Head}$ "Tactile Artisan" Standard)
To harmonize with our Studio Ghibli / *Wind Waker* / *Tunic* world architecture from a $4.8\text{ m}$ raid camera eye-line, all playable heroes share a standardized $1.80\text{ m}$ tall, $5.5\text{-head}$ proportion grid:

| Anatomical Segment | Vertical Span ($y$ in meters) | Width / Radius Specification | Artistic & Readability Rationale |
|---|---|---|---|
| **Crown, Head & Hood (`Head`)** | $y \in [1.46\text{ m}, 1.80\text{ m}]$<br>*(Height: $0.34\text{ m}$)* | Width: $0.28\text{ m}$<br>Depth: $0.30\text{ m}$ | Enlarged $5.5\text{-head}$ cranium with a sculpted brow-ridge, warm recessed eye-planes, distinct nose bridge, full/braided woodsman beard, and layered hood/kettle-brim so facial direction reads from $15\text{ m}$ away. |
| **Shoulders, Chest & Mantle (`Spine_Upper`)** | $y \in [1.10\text{ m}, 1.46\text{ m}]$<br>*(Height: $0.36\text{ m}$)* | Shoulder Span: $0.56\text{ m}$<br>Chest Depth: $0.32\text{ m}$ | Broad, heroic trapezoidal chest taper ($0.56\text{ m}$ at shoulders narrowing to $0.34\text{ m}$ at waist) giving the *Iron-Woodsman* an unmistakable, grounded silhouette. |
| **Waist, Belt & Hewing Apron (`Spine_Lower` / `Pelvis`)** | $y \in [0.82\text{ m}, 1.10\text{ m}]$<br>*(Height: $0.28\text{ m}$)* | Waist Width: $0.34\text{ m}$<br>Hip Apron: $0.44\text{ m}$ | Framed by a chunky $0.10\text{ m}$ tall brass-buckled timber-belt carrying physical 3D craft tools (iron splitting-wedges, vellum case, coiled rope, or tether-lantern). |
| **Arms, Bracers & Gauntlets (`UpperArm` $\rightarrow$ `Hand`)** | Shoulder $1.38\text{ m}$ $\rightarrow$ Knuckle $0.76\text{ m}$ | Upper Arm $r = 0.075\text{ m}$<br>Forearm Bracer $r = 0.095\text{ m}$<br>Mitten Hand $0.14\text{ m}$ | Popeye / *Wind Waker*-inspired **flared forearm taper**: forearms and leather bracers are $25\%$ thicker than upper arms, terminating in chunky sculpted gauntlet-mittens with an articulated thumb so weapon grips look powerful. |
| **Legs, Breeches & Turn-Boots (`Thigh` $\rightarrow$ `Toe`)** | Hip $0.88\text{ m}$ $\rightarrow$ Sole $0.00\text{ m}$ | Thigh $r = 0.11\text{ m}$<br>Cuffed Boot $0.16 \times 0.28\text{ m}$ | Sturdy, slightly tapered wool breeches tucked into thick folded-cuff leather woodsman boots with a solid heel and upturned storybook toe box. |

### 2.2 Signature Archetype Design: The Iron-Woodsman (`Wayfarer` + `Stout Heart` `+Tank`)
As the vanguard of the **Wayfarers** (*"Hewn-Hand of the High Pines"*, `Tizzi-Wed-Green` Heritage), the **Iron-Woodsman** bridges agile woodland DPS with sturdy front-line poise breaking (`+20.0 HP`, `+25% Poise Damage`, `+30ms Perfect Guard`, unlocks `HEAVY` Armor & `Sign of Iron-Root` affinity):
1. **Headgear & Face (`Value 3` Focal Crown):**
   * Wears a deep forest-green **Dagged Wool Coppice-Hood** crowned with a tilted **Brass-Brimmed Iron Kettle-Cap** (`#5A626A` forged iron dome with a gleaming `#E5C158` brass rim and an embossed `SIGN_IRON_ROOT` oak-knot badge on the brow).
   * Beneath the brim sits a warm, weathered face with expressive dark-amber eyes and a sculpted **Briar-Thatch Beard** (rich chestnut-brown `#4A3222` speckled with silver-grey `#B8B4AE` badger-streaks along the mustache and chin corners) that moves with the head bone.
2. **Asymmetric Shoulder & Torso Silhouette (`Value 2` Craft Layer):**
   * **Left Shoulder (The Bracing Ward):** Wears a heavy **Banded Ash-and-Iron Logging Pauldron**—two overlapping curved plates of adze-hewn heartwood rimmed in dark bog-iron with three large brass dome-rivets—visually communicating his `+Tank` Secondary Calling and `L Guard` poise stability.
   * **Right Shoulder (The Hewing Arm):** Wears a flexible quilted-leather shoulder gusset over his **Wayfarer Emerald Tunic** (`#3B7A47`) and **Stout-Heart Bronze Tabard** (`#B87A3D`), keeping his weapon-swinging arm completely unencumbered.
   * **Back Cloak:** A warm, hip-length **Oilskin & Hedgerow-Wool Mantle** (`#2E4229` outer, `#8C6239` russet lining) with a notched swallowtail hem driven by the 2-bone Verlet spring chain.
3. **The Timber-Steward's Belt & Split-Leather Apron (`Value 1` Grounded Anchor):**
   * Over dark charcoal-bark breeches (`#2B2017`), he wears a heavy **Split-Leather Hewing Apron** (divided down the center so each leg kicks freely during lunges and rolls).
   * Cinched at the waist by a wide harness belt featuring:
     * **Right Hip:** Two hanging **Bog-Iron Splitting Wedges** and a whetstone horn.
     * **Left Hip:** A coiled **Hemp Felling-Rope** and a brass-bound **Scribe Vellum Folio Case** whose clasp glows with the active Place-Card's Scribe Sign color.
     * **Upper Back (`BackStowSocket`):** A compact **Round Oak-and-Iron Buckler-Targe** strapped across his upper back (marking his `+Tank` Stout Heart heritage even when two-handing the `Broad-Axe`!).

### 2.3 Continuous Skinned `ArrayMesh` Engineering (`HeroMeshBuilder`)
To eliminate the "stack of disconnected primitives" look seen in early prototypes, `src/actors/hero_mesh_builder.gd` constructs the character using **Continuous Multi-Ring Skinned Lofting**:
* **Zero Joint Gaps on Bend:** Torso (`Pelvis` $\rightarrow$ `Spine_Lower` $\rightarrow$ `Spine_Upper` $\rightarrow$ `Neck`), Arms (`Clavicle` $\rightarrow$ `UpperArm` $\rightarrow$ `Forearm` $\rightarrow$ `Hand`), Legs (`Thigh` $\rightarrow$ `Calf` $\rightarrow$ `Foot` $\rightarrow$ `Toe`), and Cape (`Spine_Upper` $\rightarrow$ `Cape_Upper` $\rightarrow$ `Cape_Lower`) are lofted as continuous cross-sectional vertex rings with smooth $2\text{-to-}4\text{-bone}$ blend weights (`ARRAY_BONES` and `ARRAY_WEIGHTS`) across every joint ring.
* **Custom Outward Proxy Normals for Cel Shading:** During mesh generation, `HeroMeshBuilder` blends each vertex's geometric normal $35\%$ toward a smooth cylindrical/spherical proxy normal centered on the limb's bone axis. This prevents harsh polygon-facet Mach bands under `hero_storybook_cel.gdshader`'s 2-band toon ramp, making low-poly procedural geometry shade like a smooth, high-poly Studio Ghibli model!
* **Automatic `.glb` Humanoid Override & Retargeting Hook:** Before generating procedural skinned surfaces, `HeroMeshBuilder` checks `ResourceLoader.exists("res://assets/models/heroes/%s.glb" % calling_id)` (and `res://assets/models/heroes/hero_base.glb`). If an external `.glb` model is present, it binds it directly to the 24-bone hierarchy and applies `hero_storybook_cel.gdshader` materials automatically.

---

## 3. The 24-Bone Modular Animation Rig & Storybook Kinematics

### 3.1 The Canonical 24-Bone Hierarchy (`src/actors/hero_skeleton_builder.gd`)
Built deterministically in code via `HeroSkeletonBuilder.build_hero_skeleton() -> Skeleton3D`, every hero shares this exact 24-bone layout:

| Bone Index | Bone Name | Parent Bone | Rest Position (Local / Model $Y\text{-Up}$, Meters) | Kinematic & Attachment Responsibility |
|---|---|---|---|---|
| `0` | `Root` | `-1` | $(0.00, 0.00, 0.00)$ | Ground-plane projection, velocity turn-banking, squash-and-stretch scalar. |
| `1` | `Pelvis` | `0: Root` | $(0.00, 0.88, 0.00)$ | Center-of-mass vertical dip, stride hip-sway, slope IK height offset, `HipSatchelSocket`. |
| `2` | `Spine_Lower` | `1: Pelvis` | $(0.00, 0.14, 0.00)$ | Abdominal pitch crunch (wind-up coil, dodge tuck, bow lean). |
| `3` | `Spine_Upper` | `2: Spine_Lower` | $(0.00, 0.22, 0.00)$ | Thoracic axial counter-twist, breathing heave, `BackStowSocket`. |
| `4` | `Neck` | `3: Spine_Upper` | $(0.00, 0.22, 0.00)$ | Head pitch/yaw cushion. |
| `5` | `Head` | `4: Neck` | $(0.00, 0.08, 0.00)$ | Look-at target tracking, camera pitch tracking, `HeadgearSocket`. |
| `6` | `Clavicle_L` | `3: Spine_Upper` | $(-0.08, 0.16, 0.00)$ | Left shoulder shrug & forward reach protraction (shield brace / bow draw). |
| `7` | `UpperArm_L` | `6: Clavicle_L` | $(-0.16, 0.00, 0.00)$ | Left shoulder ball-joint rotation +Left Pauldron mount. |
| `8` | `Forearm_L` | `7: UpperArm_L` | $(-0.24, 0.00, 0.00)$ | Left elbow hinge + forearm pronation/supination twist. |
| `9` | `Hand_L` | `8: Forearm_L` | $(-0.22, 0.00, 0.00)$ | `OffHandSocket` (Greatshield, Tether-Lantern, Yew Longbow riser, or 2H Axe pommel grip). |
| `10` | `Clavicle_R` | `3: Spine_Upper` | $(+0.08, 0.16, 0.00)$ | Right shoulder shrug & backswing retraction. |
| `11` | `UpperArm_R` | `10: Clavicle_R` | $(+0.16, 0.00, 0.00)$ | Right shoulder ball-joint rotation + Right Pauldron mount. |
| `12` | `Forearm_R` | `11: UpperArm_R` | $(+0.24, 0.00, 0.00)$ | Right elbow hinge + wrist cleave alignment. |
| `13` | `Hand_R` | `12: Forearm_R` | $(+0.22, 0.00, 0.00)$ | `MainHandSocket` (Falchion, Broad-Axe, Rowan Way-Staff, or Bowstring draw fingers). |
| `14` | `Thigh_L` | `1: Pelvis` | $(-0.12, -0.04, 0.00)$ | Left hip stride, lunge step, & kneeling Hearth-Rite plant. |
| `15` | `Calf_L` | `14: Thigh_L` | $(0.00, -0.38, 0.00)$ | Left knee hinge (analytic 2-bone IK mid-joint). |
| `16` | `Foot_L` | `15: Calf_L` | $(0.00, -0.38, 0.00)$ | Left ankle pitch/roll (ground-normal aligned). |
| `17` | `Toe_L` | `16: Foot_L` | $(0.00, -0.08, +0.14)$ | Left toe push-off bend during sprint and dodge roll. |
| `18` | `Thigh_R` | `1: Pelvis` | $(+0.12, -0.04, 0.00)$ | Right hip stride, back-step brace, & kneeling Hearth-Rite knee-drop. |
| `19` | `Calf_R` | `18: Thigh_R` | $(0.00, -0.38, 0.00)$ | Right knee hinge (analytic 2-bone IK mid-joint). |
| `20` | `Foot_R` | `19: Calf_R` | $(0.00, -0.38, 0.00)$ | Right ankle pitch/roll (ground-normal aligned). |
| `21` | `Toe_R` | `20: Foot_R` | $(0.00, -0.08, +0.14)$ | Right toe push-off bend. |
| `22` | `Cape_Upper` | `3: Spine_Upper` | $(0.00, 0.14, -0.14)$ | Upper mantle/cloak Verlet spring node. |
| `23` | `Cape_Lower` | `22: Cape_Upper` | $(0.00, -0.42, -0.04)$ | Lower swallowtail cloak hem Verlet spring node. |

---

### 3.2 Four Emotive Storybook Kinematic Solvers (`src/actors/hero_rig_animator.gd`)
To make characters feel alive, weighty, and responsive to the terrain and wind created in Phases 17–18, `HeroRigAnimator` runs four lightweight ($< 0.08\text{ ms}$ total per actor) kinematic solvers every frame via `Skeleton3D.set_bone_pose_position()` and `set_bone_pose_rotation()`:

1. **Analytic Two-Bone Foot IK & Slope Pelvis Ground-Adaptation:**
   * Given a thigh length $L_1 = 0.38\text{ m}$ and calf length $L_2 = 0.38\text{ m}$, for any stance or stride foot target $\mathbf{p}_{\text{foot}}$ at local terrain height $h(\mathbf{p}_{xz})$ and surface normal $\mathbf{n}_{\text{ground}}$, the knee angle $\theta_{\text{knee}}$ is solved analytically via the Law of Cosines:
     $$\cos(\pi - \theta_{\text{knee}}) = \text{clamp}\left(\frac{d^2 - L_1^2 - L_2^2}{2 L_1 L_2}, \; -0.98, \; 0.98\right), \quad d = \|\mathbf{p}_{\text{ankle}} - \mathbf{p}_{\text{hip}}\|$$
   * When climbing the $13^\circ\text{–}25^\circ$ ramps of `Bramble-Bridge`, `Quarry-Wick`, or `Dover-Slap-Bridge`, `Pelvis` automatically drops by $\Delta y_{\text{pelvis}} = -0.5 \cdot |h_L - h_R|$ so the downhill leg stays fully extended while the uphill knee bends naturally onto the higher stepping stone!
2. **Two-Handed Weapon Haft IK & Dynamic Hand-Slide (`Hand_L` $\leftrightarrow$ `MainHandSocket`):**
   * When wielding a two-handed weapon (`Broad-Axe` or `Rowan Way-Staff`), `Hand_L` is not left dangling at the side. `HeroRigAnimator` computes the world position of a **Sliding Haft Grip Point** $\mathbf{g}(s)$ along the weapon's shaft vector ($s \in [0.15, 0.75]$ from pommel to head) and solves analytical 2-bone arm IK for `UpperArm_L` and `Forearm_L`:
     * *During Idle / Walk & Wind-Up (Phase A):* $s = 0.68$ (`Hand_L` slides high up beneath the bearded axe blade for leverage, holding the heavy head across the chest/shoulder).
     * *During Active Cleave / Slam (Phase B):* $s$ snaps down to $0.18$ (`Hand_L` slides down to meet `Hand_R` at the pommel like a wood-splitter driving a maul through oak!).
3. **Second-Order Damped Spring-Bone Solver (Cloak, Apron, & Lantern Pendulum):**
   * `Cape_Upper`, `Cape_Lower`, the `Split-Leather Apron`, and any equipped `Tether-Lantern` updates via a critically damped second-order differential spring driven by actor world acceleration $\mathbf{a}_{\text{actor}}$ and the local wind-wave vector $\mathbf{w}(\mathbf{x}_{xz}, t)$ from `WorldAtmosphereDirector`:
     $$\ddot{\theta} = -\omega_0^2 (\theta - \theta_{\text{rest}}) - 2 \zeta \omega_0 \dot{\theta} + k_{\text{vel}} \cdot v_{\text{local\_z}} + k_{\text{wind}} \cdot w_{\text{gust}}$$
     clamped to $\theta_{\text{cape\_pitch}} \ge 8^\circ$ away from the back so the cloak never penetrates the torso or legs.
4. **Anticipation Coil, Squash-and-Stretch, & 3D Curved Blade-Smear (`WeaponSmearMesh`):**
   * **Phase A Anticipation Coil:** Instead of linear interpolation from $0.0 \rightarrow 1.0$, Phase A wind-up evaluates an **Overshoot Anticipation Curve**:
     $$u_{\text{coil}}(t_A) = 1.0 - (1.0 - t_A)^3 + 0.12 \cdot \sin(\pi t_A)$$
     which pulls the hero rapidly into their extreme coiled silhouette during the first $45\%$ of wind-up and holds that readable silhouette taut for the human eye before unleashing Phase B!
   * **Phase B Active Strike & Hit-Stop Vibrato:** During the $60\text{ ms}\text{–}180\text{ ms}$ hit-stop freeze (`04_BALANCE.md`), the weapon bone applies a high-frequency $\pm 0.018\text{ m}$ kinetic impact tremor so heavy hits feel bone-shakingly solid.

---

### 3.3 Complete Combat, Weapon, & Stewardship Animation Catalog
Every action in *Everwood* maps to a deterministic pose profile inside `HeroRigAnimator` synchronized $1:1$ with `CombatActionResource` and `SignFlowComponent`:

| Animation State / Action | Canonical Timing (`02` & `04`) | Skeletal Choreography & Storybook Silhouette Read | Secondary Motion & VFX Sync |
|---|---|---|---|
| **1. Pastoral Idle & Winded Breath** | Continuous ($0.52\text{ Hz}$ breath cycle; $1.6\text{ Hz}$ after winded 3rd Light) | Relaxed $18^\circ$ contrapposto hip shift; `Broad-Axe` rests heavy across the right shoulder with `Hand_L` hooked on the belt; after a winded 3rd Light (`550ms`), chest heaves deeper and shoulders dip. | Cloak sways gently with world wind-waves; beard & hood tassel bob softly. |
| **2. Walk, Sprint, & Turn-Bank Gait** | Stride frequency scales with speed ($6.0\text{ m/s}$ base) | Double-bounce *Wind Waker* pastoral run: `Pelvis` bobs $\pm 0.045\text{ m}$ at $2\times$ stride frequency; `Spine_Upper` counter-rotates $\pm 22^\circ$ against `Pelvis`; body banks up to $14^\circ$ into turns. | Alternating boot-step dust puffs on turf/cobbles; cloak trails at $35^\circ\text{–}55^\circ$. |
| **3. Broad-Axe Light Chain (2 Cleaves)** | $0.85\text{ s}$ per swing ($16\text{ stam}$, $14 / 17\text{ dmg}$) | **Cleave 1:** Right-to-left diagonal timber-felling hew (`Spine` twists $+55^\circ \rightarrow -60^\circ$, $1.2\text{ m}$ step). **Cleave 2:** Low-to-high reverse undercut (`Pelvis` drops $-0.16\text{ m}$, axe hooks upward). | Wide Amber/Iron-Root or Steel 3D ribbon trail (`weapon_trail.gd`). |
| **4. Broad-Axe Heavy (*Earth-Splitter*) & Flourishes** | Heavy: $28\text{ dmg}, 35\text{ poise}$<br>`R`: *Coppice-Splitter Slam*<br>`L+R`: *Heartwood Sundering* | **Phase A:** Hero leaps/rises onto toes ($+0.12\text{ m}$), hoisting the axe high overhead with both hands while torso arches back $28^\circ$. **Phase B:** `Hand_L` slides down to the pommel as the entire body jackknifes forward, slamming the blade into the earth ($0.90\times$ pelvis squash on impact!). | Always detonates active Scribe Seals; `100ms` heavy hit-stop tremor. |
| **5. Falchion Light (3 Cuts), Heavy (*Advancing Thrust*), & Flourishes** | $0.55\text{ s}$ cuts ($8/9/12\text{ dmg}$)<br>Heavy: $2.0\text{ m}$ lunge<br>`L+R`: *Bramble-Whirl Flurry* | Crisp fencing flow: (1) High diagonal slash, (2) Quick backhand Horizontal sweep, (3) Spinning flourish cut; Heavy plants back foot and lunges $2.0\text{ m}$ in a low fencer's foil extension with off-hand shield/arm counter-balanced behind. | Crisp silver-or-Sign ribbon arc. |
| **6. Yew Longbow (*Snap-Shot*, *Piercing Draw*, & *Vaulting Bough-Shot*)** | Light: $0.56\text{ s}$ ($-0.6\text{ m}$ hop)<br>Heavy: $1.10\text{ s}$ planted draw | **Canted Storybook Archer Stance:** Torso turns $70^\circ$ side-on; `Arm_L` extends the Yew Longbow canted at $22^\circ$ so the hero's face remains visible to the camera; `Hand_R` pulls the bowstring to the cheek (`BowString` vertex flexes back $0.42\text{ m}$!) before releasing with a crisp finger-snap recoil and $-0.6\text{ m}$ back-hop. | Bow limbs bend elastically during Phase A draw and snap straight on Phase B release. |
| **7. Rowan Way-Staff (2 Sweeps + Bolt, *Resonant Pulse*, & *Reed-Sweep Gust*)** | 2 sweeps + $12\text{ m}$ bolt<br>Heavy: AoE pulse ($+25\%$ Sanctuary) | Fluid two-handed figure-eight quarterstaff weaves followed by a planted one-handed lantern-staff extension; on Heavy (*Resonant Pulse*) or *Lantern-Keeper's Chime* (`L+R`), the hero raises the staff vertically and strikes the butt-cap into the flagstones, ringing its top chime. | Swinging brass lantern-head flares $2.0\times$ light energy on pulse. |
| **8. Active Guard, Perfect Guard Parry, & `Shadow Sanctuary`** | `L` Hold (`200–260ms` Perfect Guard window)<br>`Back+Heavy`: Shield Cone | **Guard:** Drops `Pelvis` $-0.12\text{ m}$, brings `OffHandSocket` (Greatshield, Buckler, or braced weapon haft) across chest at $45^\circ$. **Perfect Guard:** Snaps shoulder forward in a kinetic deflection bash (`0` stam, `50` poise to boss!). **Shadow Sanctuary:** Plants shield edge into the turf with both hands bracing behind it. | Golden-azure parry shockwave ring on Perfect Guard. |
| **9. Dodge Roll (Stamina Evasion)** | $0.32\text{ s}$ i-frames ($3.8\text{–}5.2\text{ m}$ by coat weight) | Full tucked forward somersault (`Pelvis` pitches $360^\circ$ around local X-axis while `Spine_Lower` and knees tuck tight to chest), emerging into a low 1-knee slide recovery before rising. | Cloak wraps smoothly around the roll arc; boot-scuff particles on landing. |
| **10. The Hearth-Rite Tuck (Out-of-Combat Stewardship Rite)** | Hold `R` or `L+R` for $120\text{ frames}$ ($2.0\text{ s}$; $80\text{ f}$ on Star-Inked Vellum) | Hero drops onto right knee (`Thigh_R` vertical, `Thigh_L` planted at $90^\circ$ forward), lays their weapon across their left knee, holds an illuminated vellum **Scribe Card** in `Hand_L`, and sweeps it along the weapon blade (`t = 0.0 -> 1.0`). On completion (`120f`), hero stands tall and hoists the weapon overhead as it expands to $1.35\times$ scale in the Place-Card's Sign glow! | Synchronizes with `CrossGrimoireHUD`'s Saffron-Gold ember border and Chime-Post rhyme ribbon. |
| **11. The Truce-Sign Parley Bow (`STATE_CURIOUS` Hob Greeting)** | Press `Light` within $6.0\text{ m}$ of a curious hob ($180\text{-frame}$ window) | Hero lowers weapon peacefully to their side, places `Hand_R` over their heart/hat-brim in a warm Miyazaki bow ($35^\circ$ `Spine_Lower` nod), and raises a glowing Sign-leaf overhead with `Hand_L` as the curious hob dances (`+25` Chimes, `+1.0` Pip). | Warm chime twinkle and floating heart/clover motes. |

---

## 4. Technical Art & Material Pipeline for Heroes (`hero_storybook_cel.gdshader`)

To ensure heroes look like master-crafted, hand-painted figurines that belong inside our Phase 18 world (`storybook_world_triplanar.gdshader` and `storybook_terrain_splat.gdshader`), we introduce `src/actors/shaders/hero_storybook_cel.gdshader`:

### 4.1 Five-Layer Shader Architecture
1. **3-Band Painterly Toon Ramp with Warm Subsurface Terminator:**
   * Computes `NdotL = dot(NORMAL, LIGHT)`. Rather than a harsh binary step from light to grey shadow, `hero_storybook_cel.gdshader` evaluates three artistic zones:
     * **Sunlit Key ($N\cdot L > 0.18$):** Full sunlit albedo + directional sun warmth.
     * **Subsurface Scatter Terminator ($N\cdot L \in [-0.04, +0.18]$):** A narrow, warm coral-amber subsurface band (`subsurface_tint = vec3(0.92, 0.48, 0.32)`, strength `0.22` on skin, wool, and wood) that makes characters look warm-blooded and tactile.
     * **Hemispheric Bounce Shadow ($N\cdot L < -0.04$):** Tints shadows with warm sky-and-turf bounce (`shadow_tint = vec3(0.32, 0.38, 0.52)`) so shadow sides remain rich and colorful.
2. **Material-ID Micro-Detail & Anisotropic Metal/Timber Specular:**
   * A single `material_surface_type` uniform (or vertex color alpha channel: `0.0 = Matte Wool/Linen`, `0.33 = Oiled Leather/Skin`, `0.66 = Hewn Timber`, `1.0 = Forged Iron/Steel/Brass`) selects procedural micro-normal grain from `ProceduralTextureAtelier` and tunes the specular lobe:
     * *Matte Wool (`#2E4229`):* Soft, broad cloth sheen (`roughness = 0.88`).
     * *Forged Iron & Brass (`#5A626A` / `#E5C158`):* Sharp, stepped comic-book anisotropic highlight (`smoothstep(0.86, 0.92, spec_dot)`) that flashes cleanly when an axe or falchion sweeps through the air.
3. **Role-Coded Fresnel Silhouette Rim + First-Quiet Blight Boost:**
   * Computes a crisp view-space grazing rim:
     $$R_{\text{fresnel}} = \text{smoothstep}\left(0.62, 0.88, \; 1.0 - \max(0.0, \text{dot}(\text{VIEW}, \text{NORMAL}))\right) \cdot \max(0.25, N\cdot L + 0.5)$$
   * Tinted by the hero's Primary Fellowship / Calling (`role_rim_color`) and automatically boosted by $+35\%$ luminance when standing inside a dark `ZONE_HUSHED` blight radius so the hero never gets lost in the slate mist.
4. **Hearth-Rite & Scribe Sign Vein Emission (`sign_glow_intensity`):**
   * When `SignFlowComponent` holds a **Hearth-Rite Tuck** (`1.35x` weapon empowerment) or invokes a Scribe Card, `sign_glow_intensity` ($0.0 \rightarrow 1.0$) illuminates carved Sign-stone inlays and weapon fuller grooves in the active Sign's canonical color (`SIGN_IRON_ROOT` `#D9822B`, `SIGN_RIME_GALE` `#38A3D1`, `SIGN_WARM_HEARTH` `#F2B749`, `SIGN_STAR_TIDE` `#8C52D9`).
5. **World Cloud-Shadow & Lantern's Promise Integration:**
   * Evaluates the same world-space drifting cloud-shadow function as `storybook_terrain_splat.gdshader` so clouds passing overhead dim the hero and the ground beneath them in unison.

---

## 5. Modular Equipment, 4-Tier Weapon Evolution, & Aesthetic Variation System

### 5.1 Schema-First Visual Composition (`HeroVisualCatalog`)
In strict compliance with **Gate 4 (`08_EVERGREEN_DEV_BIBLE.md`)**, `ActorVisuals` never branches on hardcoded weapon or coat strings. Instead, equipping any combination of Calling, Coat, Weapon Tier, or Family Dye Swatch queries `HeroVisualCatalog` (`src/actors/hero_visual_catalog.gd`) and updates the 24-bone rig in $O(1)$ time:

```text
  EquipmentLoadoutResource (coat_id, weapon_id, card_finishes) + CallingResource + HeroAppearanceResource
                                                 │
                                                 ▼
                         HeroVisualCatalog.resolve_hero_visual_spec(...)
     ┌───────────────────────────┬───────────────────────────────┬───────────────────────────┐
     ▼                           ▼                               ▼                           ▼
1. Skinned Body & Coat     2. Calling Headgear &         3. MainHandSocket           4. OffHandSocket &
   (`HeroMeshBuilder`)        Asymmetric Pauldrons          4-Tier Sculpted Weapon      BackStowSocket Props
   • Bramble-Spun Jerkin      • Iron-Woodsman Kettle-Cap    • Tier 1 Apprentice Timber  • Greatshield / Targe
   • Hearth-Linen Coat        • Left Ash-Iron Pauldron      • Tier 2 Hedgerow Iron      • Brass Tether-Lantern
   • Hedgerow Wool-Mantle     • Hewing Apron & Wedges       • Tier 3 Bramble Steel      • Quiver & Scribe Folio
   • Iron-Wood Ring-Coat      • 9 Calling Variants          • Tier 4 Dover-Slap Relic   • Dynamic Bowstring
```

### 5.2 The Four Armor Coats (`CoatVisualSpecResource`)
Switching armor at the **Armory & Scribe Desk** visibly transforms the hero's torso silhouette, collar/mantle, forearm bracers, and lower skirt while preserving their Calling's distinctive headgear and tabard colors:

| Coat ID & Weight (`05_ARSENAL_AND_CARDS_GDD.md`) | Silhouette & Geometry Modifier (`HeroMeshBuilder`) | Surface Material & Three-Value Breakdown |
|---|---|---|
| **`bramble_spun_jerkin`**<br>*Bramble-Spun Jerkin (Lv 1 Starter Medium — $15\%$ Mit, $4.8\text{ m}$ Roll)* | Fitted quilted hedgerow tunic, stitched rawhide forearm wraps, light split hem, short travel cape. | Value 1: Dark bark boots/breeches (`#2B2017`)<br>Value 2: Quilted olive-hemp tunic (`#556B45`)<br>Value 3: Brass collar clasp & Calling crest. |
| **`hearth_linen_coat`**<br>*Hearth-Linen Coat (`LIGHT` — $10\%$ Mit, $27.5/\text{s}$ Stam, $5.2\text{ m}$ Roll)* | Flowing pleated cream-and-saffron linen surcoat with wide bell-cuff sleeves, woven Sign-embroidered sash, and long fluttering swallowtail scarf. | Value 1: Indigo-slate trousers & soft turn-boots (`#283040`)<br>Value 2: Warm bleached hearth-linen & Fellowship trim (`#D8CEBE`)<br>Value 3: Gilded sash-bells & glowing Sign hem. |
| **`hedgerow_wool_mantle`**<br>*Hedgerow Wool-Mantle (`MEDIUM` — $20\%$ Mit, $22.0/\text{s}$ Stam, $4.6\text{ m}$ Roll)* | **The Iron-Woodsman Signature Coat:** Heavy dagged wool chaperon shoulder-mantle, buckled leather brigandine chest-cinch, split-leather hewing apron, and thick cuffed woodsman boots. | Value 1: Deep heartwood leather apron & boots (`#2B2017`)<br>Value 2: Forest moss-wool mantle & Calling tabard (`#3B7A47` / `#B87A3D`)<br>Value 3: Brass buckle plates & shoulder rivets (`#E5C158`). |
| **`iron_wood_ring_coat`**<br>*Iron-Wood Ring-Coat (`HEAVY` — $35\%$ Mit, $260\text{ ms}$ Perfect Guard)* | Layered ash-wood and forged bog-iron ring-mail coat reaching mid-thigh, double-layered articulated steel pauldrons, flanged iron vambraces, and plated shin-greaves. | Value 1: Charcoal bog-iron ring-skirt & greaves (`#2A2F35`)<br>Value 2: Brushed steel chest-bands & heavy oak-scale coat (`#6E7680`)<br>Value 3: Polished brass pauldrons & warden crest (`#E8C664`). |

---

### 5.3 Four-Tier Weapon Geometry Evolution (`WeaponVisualSpecResource` — 16 Distinct Meshes)
In accordance with `11_COMBAT_ONBOARDING_AND_FEEL_GDD.md` and `04_BALANCE.md`, every weapon (`Falchion`, `Broad-Axe`, `Rowan Way-Staff`, `Yew Longbow`) climbs four material tiers across the Trail of the Four Signs. Rather than merely tinting the same mesh, `HeroMeshBuilder.build_weapon_mesh(weapon_type, tier, active_sign)` evolves the **3D geometry and craftsmanship** at every tier:

| Weapon Tier (`04_BALANCE.md`) | Unlock Level & Stat Multiplier | Geometric & Material Evolution Across All 4 Weapons |
|---|---|---|
| **Tier 1: Apprentice Timber**<br>*(Turned Hazel & Hemp Cord)* | **Level 1** ($1.0\times$ base)<br>Hazel `#A67B5B`, Metal `0.0` | **Crafted Practice & Homestead Tools:** Lathed hazel-wood blades and axe-heads with chamfered wooden edges, criss-cross hemp cord bindings around the crossguard/haft neck, and a sprouting green oak-leaf twig tied to the pommel. |
| **Tier 2: Hedgerow Iron**<br>*(Hand-Forged Bog-Iron & Ash)* | **Level 2** ($1.2\times$ base)<br>Dark Iron `#5A626A`, Metal `0.55` | **Working Village Ironware:** Hand-hammered dark bog-iron blades and bearded axe-heads with a bright honed cutting bevel, sturdy ash-wood hafts, squared iron crossguards, and dome-headed brass rivets (`#C49540`). |
| **Tier 3: Bramble-Bridge Steel**<br>*(Milled Steel & Bell-Brass)* | **Level 5** ($1.45\times$ base)<br>Milled Steel `#C4CED4`, Metal `0.80` | **Master Guild Arms:** Gleaming fuller-grooved steel blades, double-bitted/reinforced broad-axe wings, cast-brass **Sanctuary Bell-Guards** and pommel rings, and diamond-wrapped ox-hide grips. |
| **Tier 4: Dover-Slap Relic**<br>*(Gilded Bronze & Living Sign-Stone)* | **Level 10** ($1.75\times$ base)<br>Gilded Bronze `#E5C158`, Metal `0.90` | **Mythopoetic Steward Relics:** Ornate Carpathian scroll-forged bronze and Damascus steel frames with an **Open Cage Crossguard / Axe-Eye** housing a **Levitating, Rotating Faceted Sign-Stone Core** (`1.8x` emission) that dynamically shifts color and rune-sparks to match the hero's active Scribe Sign or Hearth-Rite Tuck! |

---

### 5.4 The $3 \times 3$ Calling Visual Matrix & Family Co-Op Customization (`HeroAppearanceResource`)
While the **Iron-Woodsman** (`Wayfarer` + `+Tank`) is our primary showcase model for this pass, the 24-bone rig and modular socket system automatically outfit all 9 Callings with unmistakable silhouette markers:
* **Primary Fellowship Silhouette Markers:**
  * *The Shield-Sworn (`Bridge-Warden`, `Weald-Captain`, `Hearth-Guard`):* Crest-plumed warden Kettle-Helm, broad symmetrical pauldrons, and a full **Banded Oak-and-Brass Greatshield** on `OffHandSocket`.
  * *The Wayfarers (`Iron-Woodsman`, `Hedge-Runner`, `Sign-Seeker`):* Dagged wool Coppice-Hood (with Kettle-Brim on `Iron-Woodsman`, double pheasant-feather plume on `Hedge-Runner`, and brass astrolabe-monocle/scroll-visor on `Sign-Seeker`), asymmetric hewing/archer pauldrons, and hip **Scribe Vellum Folio + Quiver**.
  * *The Lantern-Bearers (`Bell-Keeper`, `Wind-Mender`, `Lantern-Scribe`):* Pointed Scribe-Brim or Carillon Hood, saffron-bordered stole, and a swinging **Brass Tether-Lantern** on `OffHandSocket` emitting a warm `OmniLight3D` glow.
* **Family Co-Op Aesthetic Variation (`HeroAppearanceResource`):**
  So four siblings or parents playing the same Calling on the couch can always tell their heroes apart, `ActorVisuals` supports 5 curated **Heritage Dye Swatches** (*Tizzi-Wed Emerald*, *Honey-Wick Saffron*, *Gull-Wick Sea-Azure*, *Barrow-Crag Heather*, *Pippin-Green Russet*) and 4 **Beard / Hair Styles** (`BRIAR_BEARD`, `TWIN_BRAIDS`, `CROPPED_CURLS`, `CLEAN_SHAVEN`)—all mathematically clamped to preserve the **55 / 30 / 15 Three-Value Luminance Hierarchy**.

---

## 6. Schema-First GDScript Specifications & Headless CI Verification Gates

### 6.1 Schema-First Resource Definitions (`src/resources/`)

#### A. `HeroVisualProfileResource` (`src/resources/hero_visual_profile_resource.gd`)
```gdscript
class_name HeroVisualProfileResource
extends Resource

## Canonical 5.5-Head Storybook Proportions & Three-Value Luminance Constants
const HERO_TOTAL_HEIGHT_M: float = 1.80
const HERO_SHOULDER_SPAN_M: float = 0.56
const HERO_BONE_COUNT: int = 24
const VALUE_1_MAX_LUMINANCE: float = 0.30 ## Grounded Anchor (Boots, Trousers, Apron)
const VALUE_2_MIN_LUMINANCE: float = 0.45 ## Craft & Calling Silhouette (Tunic, Tabard)
const VALUE_3_MIN_LUMINANCE: float = 0.80 ## Focal Crown & Sign Spark (Head, Trim, Blade)

@export var calling_id: StringName = &"Iron-Woodsman"
@export var primary_fellowship: StringName = &"WAYFARER"
@export var secondary_modifier: StringName = &"stout_heart"
@export var heritage_id: StringName = &"tizzi_wed_green"

## Three-Value Canonical Palette
@export var value_1_anchor_color: Color = Color(0.169, 0.125, 0.090)   ## #2B2017 Heartwood Bark
@export var value_2_tunic_color: Color = Color(0.231, 0.478, 0.278)    ## #3B7A47 Wayfarer Emerald
@export var value_2_tabard_color: Color = Color(0.722, 0.478, 0.239)   ## #B87A3D Stout-Heart Bronze
@export var value_3_crown_trim_color: Color = Color(0.898, 0.757, 0.345) ## #E5C158 Gilded Brass
@export var role_fresnel_rim_color: Color = Color(0.35, 0.88, 0.52)

## Archetype Silhouette Flags
@export var headgear_style: StringName = &"COPPICE_HOOD_KETTLE_BRIM"
@export var left_pauldron_style: StringName = &"ASH_IRON_LOGGING_GUARD"
@export var right_pauldron_style: StringName = &"LEATHER_GUSSET"
@export var has_split_hewing_apron: bool = true
@export var belt_tool_kit: StringName = &"WEDGES_ROPE_VELLUM_FOLIO"
@export var back_stow_prop: StringName = &"OAK_IRON_BUCKLER_TARGE"
@export var default_beard_hair_style: StringName = &"BRIAR_BEARD_SILVER_SPECKLED"
@export var glb_override_path: String = "res://assets/models/heroes/iron_woodsman.glb"
```

#### B. `WeaponVisualSpecResource` (`src/resources/weapon_visual_spec_resource.gd`)
```gdscript
class_name WeaponVisualSpecResource
extends Resource

@export var weapon_id: StringName = &"heavy_axe_t1"
@export var base_weapon_type: int = 1 ## EquipmentItemResource.WeaponType.HEAVY_AXE
@export var tier_level: int = 1       ## 1 = Timber, 2 = Iron, 3 = Steel, 4 = Relic
@export var is_two_handed: bool = true
@export var blade_albedo: Color = Color(0.651, 0.482, 0.357) ## #A67B5B
@export var haft_albedo: Color = Color(0.431, 0.294, 0.180)  ## #6E4B2E
@export var guard_albedo: Color = Color(0.769, 0.584, 0.251) ## #C49540
@export var metallic: float = 0.0
@export var roughness: float = 0.78
@export var has_floating_sign_stone: bool = false
@export var shaft_grip_range_m: Vector2 = Vector2(0.18, 0.68)
```

---

### 6.2 Automated Headless CI & Visual Verification Gates (`tools/smoke_test.gd`)
Every update to `ActorVisuals`, `HeroSkeletonBuilder`, `HeroMeshBuilder`, `HeroRigAnimator`, and `hero_storybook_cel.gdshader` must pass five automated verification checks before commit:
1. **Static Parse & Type Verification (`--check-only`):**
   ```bash
   godot --headless --path . --check-only -s src/resources/hero_visual_profile_resource.gd
   godot --headless --path . --check-only -s src/resources/weapon_visual_spec_resource.gd
   godot --headless --path . --check-only -s src/actors/hero_visual_catalog.gd
   godot --headless --path . --check-only -s src/actors/hero_skeleton_builder.gd
   godot --headless --path . --check-only -s src/actors/hero_mesh_builder.gd
   godot --headless --path . --check-only -s src/actors/hero_rig_animator.gd
   godot --headless --path . --check-only -s src/actors/actor_visuals.gd
   ```
2. **24-Bone `Skeleton3D` & Skinned Mesh Integrity Gate (`tools/smoke_test.gd`):**
   * Assert that every playable hero (`ActorBase` with `is_player == true` or companion) instantiates a valid `Skeleton3D` with `get_bone_count() == 24` and exact canonical bone names (`Root`, `Pelvis`, `Spine_Lower`, `Spine_Upper`, `Neck`, `Head`, `Clavicle_L`..`Cape_Lower`).
   * Assert that the body mesh is a valid skinned `ArrayMesh` bound to the `Skeleton3D` (`get_skin() != null` or valid bone weights) with zero disconnected capsule gaps.
3. **Three-Value Luminance Harmony & Iron-Woodsman Silhouette Gate:**
   * Query `HeroVisualCatalog.get_profile(&"Iron-Woodsman")` and assert that `value_1_anchor_color.get_luminance() <= 0.30`, `value_2_tunic_color.get_luminance()` sits between `0.32` and `0.70`, and `value_3_crown_trim_color.get_luminance() >= 0.72`.
   * Assert that equipping the `Iron-Woodsman` mounts the `COPPICE_HOOD_KETTLE_BRIM`, asymmetric `ASH_IRON_LOGGING_GUARD` left pauldron, split-leather hewing apron, splitting-wedges belt kit, and back-stowed buckler-targe.
4. **4-Tier Weapon Evolution & 4-Coat Swapping Gate:**
   * Programmatically cycle a hero through all 4 Coats (`Bramble-Spun Jerkin`, `Hearth-Linen Coat`, `Hedgerow Wool-Mantle`, `Iron-Wood Ring-Coat`) and all 4 Weapons across Tiers 1 to 4 (`Apprentice Timber` $\rightarrow$ `Hedgerow Iron` $\rightarrow$ `Bramble-Bridge Steel` $\rightarrow$ `Dover-Slap Relic`). Assert that each tier produces a distinct `ArrayMesh` vertex/surface signature and that Tier 4 weapons spawn the glowing `SignStoneCore` node.
5. **Procedural Kinematics & Action Pose Gate:**
   * Step `HeroRigAnimator` through `Idle`, `Move`, `Attack` (`Broad-Axe` Phase A wind-up coil $\rightarrow$ Phase B cleave with two-handed `Hand_L` pommel slide), `Yew Longbow` canted draw, `Guard` / `Perfect Guard`, `Dodge Roll`, `Hearth-Rite Tuck` (kneeling pose + $1.35\times$ weapon empowerment), and `Truce-Sign Parley Bow`. Assert that bone transforms update deterministically at $60\text{ Hz}$ with zero NaN quaternions and zero frame-budget regressions.
---

## 7. Build Notes (Phase 19)

What's built, by stage, and where it differs from the text above on purpose. The Phase 19 brief and this document disagreed in places (bone names, proportions, file and class names); where they did, the brief's build directive was followed, because its stages and checks name its own, and this document's version is listed below.

### 7.1 What's built

1. **The solo Iron-Woodsman boot.** A default launch seats Player 1 alone, as the **Iron-Woodsman** ("Hewn-Hand of the High Pines": the Wayfarers with a Stout Heart, 120 health at Level 1, +25% poise, a 230 ms Perfect Guard) in the Hedgerow Wool-Mantle with the best Broad-Axe the trail has opened (the Split-Ash Broad-Axe at Level 1, the Dover-Slap Cleaver-Axe at 10), keeping the Wayfarers' saved cards. No AI companions join anywhere (`LevelBase.auto_backfill_companions` is off) unless the game starts with `-- --with-companions` or a test calls `set_companion_backfill_enabled(true)`. One player fills the screen (a 1x1 grid). A solo party needs one Maker-Seal Plate at the Gorge gate (min(2, party)) and meets a 1,400-health Cairnsman (900 + 500 x 1); both rules were already in place. `-- --kit=saved` boots in the saved kit instead. Constants: `ClassLoadouts.SOLO_BOOT_*`; kit: `PartyProgress.iron_woodsman_kit()`.
2. **Schema-first looks.** `HeroAppearanceResource` (the 60-30-10 bands and every colour and style of a look) and `WeaponVisualTierResource` (a tier's id, opening level, multiplier, blade, trim, grip, metallic, roughness and Sign-stone glow). The `ArsenalCatalog` registers the four tiers (Apprentice Timber, Hedgerow Iron, Bramble-Bridge Steel, Dover-Slap Relic, from its tier tables, which now hold the brief's trims and roughness), one look per Calling (nine) and four heritage dyes (Tizzi-Wed Pine, Gull-Wick Slate, Barley-Bridge Russet, Barrow-Crag Heather). `hero_appearance_for_seat()` dyes a seat's look by party slot, so siblings in the same Calling read apart.
3. **The 24-bone rig.** `HeroRigBuilder.build_hero_skeleton()`: Root, Hips, Spine, Chest, Neck, Head, Jaw_Beard, both arms (Clavicle, UpperArm, Forearm, Hand), both legs (Thigh, Shin, Foot) and Cloak_01..03, parent before child, 4.5 heads to a 1.75 m crown; one `Skin` from `create_skin_from_rest_transforms()`; the read-only `MainHandSocket`, `OffHandSocket`, `BackStowSocket` and `HipSatchelSocket`.
4. **The hero shader.** `src/actors/shaders/storybook_hero_atelier.gdshader`: the vertex-colour decoder (five bands of materials, sub-ids for coat, boots, breeches, tabard, tunic, trim, timber, linen, rope, iron, ring-mail, brass, steel, skin, beard, eyes and hair), twill, the vertical gradient `mix(0.68, 1.12, smoothstep(0.15, 1.45, y))` times crevice AO, worn chamfers, the beard's cellular strand speckle (28% #B8C0C8 through #4A3222), a cel ramp anti-aliased by its own derivative whose shade takes the biome's turf bounce (`ground_turf`), the Fellowship rim (#F2B749, #52C478, #58B8F2), Maker-Seal veins in the active Sign (0 to 2.4), Dread-Chill hoar-rime on the lowest 0.45 m and The Lantern's Promise's Saffron-Gold rim (both driven by the Flow-Link window's frames), a MatCap band on metal, and a 4x4 Bayer dither inside 1.1 m of the camera.
5. **The atelier.** `HeroMeshAtelier` lofts five skinned regions (head and heritage, torso and coat, pauldrons and tabard, limbs and boots, belt and cloak), with the four headgear styles, four beards (the Iron-Woodsman's three-lobed woodsman beard on Jaw_Beard), five shoulder styles, nine belt trinkets and four coats as four silhouettes (the Jerkin's quilting and rawhide wraps; the Linen Coat's sash, bell cuffs and long swallowtail; the Wool-Mantle's dagged capelet and brass-studded brigandine over a split hewing apron; the Ring-Coat's ring-mail, gorget, bands and greaves), plus the Greatshield, Tether-Lantern, quiver, buckler-targe and an articulated Scribe Vellum Satchel. `build_tiered_weapon()` sculpts the Falchion, Broad-Axe, Rowan Way-Staff and Yew Longbow anew at each tier (hemp knots and a leaf twig; iron with a honed bevel and brass rivets; a fullered blade, double wings, a bell-guard; scroll-forged gilded bronze round a turning Sign-stone core), with `HaftGripMarker`, trail and bowstring markers. Models at `assets/models/heroes/<calling_id>.glb` and `assets/models/<item_id>.glb` win.
6. **Kinematics.** `StorybookKinematicsModifier3D`: exact damped springs (cloak 14 rad/s at 0.72, beard 22) held outside a 0.26 m body capsule, a 0.24 rad lean and 0.26 rad bank, the 3.2 Hz winded heave under 25% stamina or a winded third Light, two-bone foot-plant IK with the hips dropping half the feet's difference, the off hand on a two-hander's haft (sliding from high on the haft down to the right hand as a blow lands) and the bow hand drawn to the jaw, a look-at (25% chest, 65% head, within 55 and 28 degrees) toward a curious hob or an open Glimmer-Spot inside 8 m, and through a hit-stop a 45 Hz tremor with a (1/sqrt(s), s, 1/sqrt(s)) squash (0.86 heavy, 0.93 light).
7. **The animator.** `HeroCombatAnimator` keys 45 clips (`HeroClipBook`, baked by `HeroPoseBaker`) at 60 Hz into one `AnimationLibrary`: idles (the weapon goes on the back after 4 s out of a fight), the 28-frame run planting on frames 4 and 18, the winded recovery, every weapon's lights, heavy and both un-inked flourishes, five card postures (four through the weapon, one at the caster), guard, the Perfect Guard bash, Shadow Sanctuary's brace, the 24-frame roll, the 120-frame Hearth-Rite Tuck (80 on Star-Inked Vellum, by the hold's own clock), the Truce-Sign Parley, the Bravery Counter, stagger and the downed slump, and the two card choreographies as one-arm overlays. `ActorBase` and `ActorVisuals` feed it every action phase, hit-stop, Flow-Link speed, kit swap, tier upgrade and Sign look; the parley, the Perfect Guard and the Bravery Counter start their one-shots.
8. **Verification.** Check-only on every changed script and `tools/test_hero_rig.gd` (the boot first, the rig in the expedition, the companion opt-in last in Oakshire Vale), with Phase 19's names in the Mythopoetic Lens's linter. No scene needed a rebake: heroes are built at runtime and no level scene holds one.

### 7.2 Deliberate differences

- **The bones are the brief's.** Hips, Spine, Chest, Shin, a Jaw_Beard bone and a three-bone cloak, rather than this document's Pelvis, Spine_Lower, Spine_Upper, Calf, two toe bones and a two-bone cape (§3.1). Both are 24 bones; the brief's gives the beard and cloak their springs.
- **4.5 heads to a 1.75 m crown** (a raised hood peaks at 1.85 m), the brief's, rather than §2.1's 5.5 heads at 1.80 m.
- **The 60-30-10 bands are the brief's** (Value 1 0.16-0.38, Value 2 0.45-0.74, Value 3 from 0.78 with 1.8x emission), not §1.3's 55/30/15. The brief's Buff Gambeson (#D6C7B2) measures 0.79, a touch above Value 2; it's kept as given, since it only shows at collars and cuffs.
- **Names follow the brief.** `HeroRigBuilder`, `HeroMeshAtelier`, `HeroCombatAnimator` (with `HeroClipBook` and `HeroPoseBaker`), `StorybookKinematicsModifier3D` and `storybook_hero_atelier.gdshader`, rather than §2-§4's `HeroSkeletonBuilder`, `HeroMeshBuilder`, `HeroRigAnimator` and `hero_storybook_cel.gdshader`; the looks are `HeroAppearanceResource` and `WeaponVisualTierResource` registered in the `ArsenalCatalog`, rather than §6.1's `HeroVisualProfileResource`, `WeaponVisualSpecResource`, `CoatVisualSpecResource` and a separate `HeroVisualCatalog`. Coats are sculpted from the armor's item id.
- **The Iron-Woodsman wears the raised Wayfarer hood** (the brief) rather than §2.2's hood under a kettle-cap brim; the kettle-cap is the Shield-Sworn's. His beard's speckle is #B8C0C8 (the brief), not #B8B4AE.
- **Calling trims are now the brief's hexes** everywhere (Stout Heart #C49540, Swift Foot #3B8C52, Wise Hand #7E52B8), so tabards, HUD trim and the Scribe Desk agree.
- **The Iron-Woodsman is sworn from Level 1 on the boot seat.** Elsewhere the Secondary Callings still open at Level 10; only the session's first seat takes the Stout Heart early. Each boot starts in the Wool-Mantle and Broad-Axe (the brief's playtest default) with the saved cards, so a Scribe Desk change lasts for that session; `--kit=saved` boots in the saved kit. The Network Manager stays class-agnostic: the level's pickers choose.
- **Companions are opt-in everywhere,** so a solo hero meets the expedition alone; the gate's one plate and the boss's 1,400 health make that playable. `--with-companions` brings them back.
- **The Lantern-Bearers' Tether-Lantern hangs at the hip,** so the Rowan Way-Staff can be held in both hands.
- **The AnimationPlayer holds the library but doesn't play it.** The animator samples the tracks itself each tick, so a clip lands on the action's exact frame, with cross-fades and one-shots; no AnimationTree (§1.2's cut).
- **Clips keep the brief's frame counts but stretch by phase.** The Earth-Splitter's 56 frames play over the heavy's own 81 (0.55 + 0.15 + 0.65 s); the roll's 24 frames cover its wind-up and active frames, its last five its recovery.
- **The kneeling Tuck shows on the holder's own screen.** The hold isn't sent over the network; every peer sees the Overhead Pocket Blessing that follows.
- **The modifier implements Godot 4.7's `_process_modification_with_delta()`**, which is what the engine calls; `_process_modification()` is kept, guarded, for older builds. Both open with the `is_inside_tree()` guard.
- **Not built:** the cloud shadows on heroes (§4.5) and retargeting a dropped-in `.glb` onto the 24 bones (a dropped-in hero is shown as it comes).
