# **17\_WORLD\_VISUAL\_AND\_AESTHETIC\_ARCHITECTURE.md — The Living Storybook Atelier: World, Zone, Architectural, & Environmental Overhaul**

**SYSTEM DIRECTIVE FOR GEMINI & CLAUDE CODE:** This document is the authoritative visual, environmental, and world-architecture specification for *Everwood (Oakshire Raids)* in Godot 4.7.2. It governs how terrain, architectural kits, textures, shaders, foliage, water, lighting, draw distance (HLOD & Vista Rings), and **Ecological Succession** states are constructed and streamed across **Oakshire Vale** and **The Bramble-Bridge Trail**. Every world asset, shader, and level baker committed to the repository MUST adhere to the Five Mandatory Gates, $4.8m$ split-screen camera sightlines, jump-free walkability rules, and headless CI verification gates defined below. *(Note: Player and monster character rigs, equipment meshes, and combat spell VFX are isolated to their dedicated subsequent upgrade track.)*

## **1\. Stage 1: Ideation, Industry Post-Mortem, Architectural Options, & Gate Audit**

### **1.1 Industry Post-Mortem: Tactile Storybook Worlds at $60Hz$**

Following Stage 1 of the **Evergreen Development Loop** (08\_EVERGREEN\_DEV\_BIBLE.md), upgrading *Everwood* from its Phase 10–12 procedural greybox primitives into a lush, cohesive, final-vision world requires analyzing how benchmark RPGs and adventure games achieve timeless environmental beauty without sacrificing gameplay readability or frame budgets:

> 1. **The Legend of Zelda: The Wind Waker & Breath of the Wild (*Nintendo EPD*) — The Triangle Rule & Cel-Shaded Horizon Clarity:**  
   * *What Succeeded:* Nintendo paired a crisp 2-band sunlit cel ramp on foreground props with soft, painter-ly triplanar terrain gradients and organized world geometry around **"The Triangle Rule"**—triangular hills, gables, and arches that naturally frame distant landmarks and invite curiosity around every corner.  
   * *The Trap to Avoid:* Applying harsh black ink outlines or flat un-textured vertex fills to large terrain meshes turns hills into sterile plastic blocks and creates shimmering moiré noise at a distance.  
   * *Everwood Application:* Reserve crisp Fresnel rims and cel bands for architectural timber, stonework, and interactive props (storybook\_world\_triplanar.gdshader) while giving terrain a warm, multi-layered painter's splatmap (storybook\_terrain\_splat.gdshader) with procedural cobble, turf, loam, and heather micro-relief.  
> 2. **Tunic & The Legend of Zelda: Link's Awakening (Switch) — Elevated Camera Readability & Tactile Bevels:**  
   * *What Succeeded:* From an elevated camera eye-line, high-frequency photo-realistic textures turn into muddy visual noise—especially when divided across 4 local split-screen viewports. *Tunic* and *Link's Awakening* solved this by exaggerating architectural proportions: thick chamfered flagstones, chunky timber beams ($0.25–0.40m$ wide), oversized roof tiles, and automatic camera-proximity dither-fading whenever a tall tree canopy or archway crosses between the lens and a player.  
   * *Everwood Application:* Enforce chunky, readable architectural silhouettes across ShapeKit and WorldAssetCatalog, and build a deterministic **Camera Sightline Dither-Fade** directly into world and foliage shaders for any geometry exceeding our $3.2m$ combat sightline cap below the $4.8m$ camera eye-line.  
> 3. **Studio Ghibli (*Kiki's Delivery Service*, *My Neighbor Totoro*, *Princess Mononoke*) & Fable (*Oakvale*) — Domestic Craftsmanship & Mundane Magic:**  
   * *What Succeeded:* Miyazaki and *Fable* make worlds feel lived-in by celebrating **Domestic Stewardship (*The Making*)**: stepped brick gables, spinning wooden waterwheels, mossy dry-stone sheep walls, puffing bakery chimneys, bee-hives humming at the woodline, and way-side shrines.  
   * *The Trap to Avoid:* Traditional MMO "corruption zones" (purple sky-lasers, neon slime, jagged bone spikes) destroy pastoral warmth and violate our **Triumvirate Lens** (Le Guin, Cooper, Miyazaki).  
   * *Everwood Application:* Ground every building and trail in northern and central European folk craftsmanship (Bruges/Visby stepped gables, British holloways, Carpathian carved-timber bridges), and express **The First-Quiet (*The Un-Making*)** as localized **Atmospheric Creep**—muted slate saturation, hairline stone cracks, un-ploughed furrows, and snuffed lanterns that visibly bloom back into sunlit life via **Ecological Succession** when the family seals a **Hush-Crack**.  
> 4. **Valheim & Enshrouded — Modular Tectonic Kits & GPU MultiMesh Clutter:**  
   * *What Succeeded:* Rather than sculpting monolithic, non-reusable city meshes, assembling buildings from a cohesive library of tectonic structural parts (stone plinths, timber wall frames, corbels, gable roofs, dormers) paired with GPU-instanced MultiMeshInstance3D grass and foliage delivers rich visual density within tiny memory and streaming footprints.  
   * *Everwood Application:* Upgrade ShapeKit into a tectonic architectural and landscape factory that composes multi-part buildings, bridges, and trees in code—while checking res://assets/models/world/\<kit\_id\>.glb first so curated 3D models drop in seamlessly without touching level logic.

### **1.2 Evaluation of Three Architectural Options**

| Architectural Option | Technical Summary | Pros | Cons / Gate Failures | Verdict |
| :---- | :---- | :---- | :---- | :---- |
| **Option 1: Pure External .glb Kitbashing Pipeline** | Replace procedural builders in build\_levels.gd and build\_oakshire\_vale.gd with hardcoded references to external .glb scene files. | High polygon detail if bespoke 3D art is already authored. | **Fails Gate 5:** Breaks deterministic code-first builds when .glb files are absent; mismatches collider ramp angles ($\leq 2{5}^{\circ }$) and $3.2m$ sightlines. | **REJECTED** |
| **Option 2: Upgraded Primitive CSG \+ Flat Vertex Colors** | Keep un-textured box/cylinder primitives in ShapeKit and simply add more primitive subdivisions with flat colors. | Zero texture memory overhead; fast to script. | **Fails Aesthetic Mandate:** Still reads as flat programmer art; lacks mortar lines, timber grain, roof tiles, water foam, and foliage depth. | **REJECTED** |
| **Option 3: The "Living Storybook Atelier" Hybrid Architecture** *(Tectonic Procedural Kits \+ Triplanar Craft Shaders \+ GPU MultiMesh Foliage \+ Ecological Succession Shaders \+ .glb Overrides)* | Upgrade ShapeKit & ZoneBiomeResource with multi-part tectonic meshes, code-generated tileable normal/albedo craft textures (ProceduralTextureAtelier), triplanar world shaders, GPU MultiMeshInstance3D foliage, 4-ring HLOD vistas, and WorldStateDB-driven Succession blooms—with automatic .glb and texture override hooks. | Delivers an immediate, dramatic visual evolution out-of-the-box in pure GDScript while remaining \$100\\%\$ ready for curated .glb and .png overrides; keeps $2ms$ streaming budget and $60Hz$ 4-player split-screen intact. | Requires a clean shader and texture-baking autoload/utility pass (src/world/world\_visual\_catalog.gd). | **SELECTED (RECOMMENDED)** |

### **1.3 Mandatory Five-Gate Verification (08\_EVERGREEN\_DEV\_BIBLE.md)**

| Gate ID & Pedigree | Mandatory Rule (08\_EVERGREEN\_DEV\_BIBLE.md) | Verification Audit for World, Zone, & Aesthetic Upgrade | Gate Verdict |
| :---- | :---- | :---- | :---- |
| **GATE 1** *Anti-Parasitic Harmony* | Must directly feed into at least two core pillars: Stamina/Poise, Four Signs, $3\times 3$ Callings, or Chimes/Vellum. | Harmonizes with all four pillars: (1) **The Four Signs** via color-coded **Chime-Post** nursery rhyme ribbons and reactive **Maker-Seal** architecture (SIGN\_IRON\_ROOT ochre stone, SIGN\_WARM\_HEARTH saffron lanterns, SIGN\_RIME\_GALE sea-azure water-shrines, SIGN\_STAR\_TIDE twilight-violet standing stones); (2) **Stamina/Poise & Flow-Link** via visible $5.5m$ **Lantern's Promise** ground warmth and $18m$ **Hearth-Rite Tuck** safe clearings; (3) **The $3\times 3$ Callings** via Shadow Sanctuary wind-sheltered bridge lanes; (4) **Chimes & Stewardship** via visible **Ecological Succession** when Hush-Cracks seal. | **PASS** |
| **GATE 2** *The Musk Razor* | Strip secondary menus and extra keybinds; execute through the 6-Posture Controller Contract and existing world hooks. | Zero new buttons or UI clutter. Environmental storytelling, **Chime-Post** diagnostics, **Water-Shrine** oases, and **Ecological Succession** transitions trigger automatically from player proximity, **Hearth-Rite Tucks**, **Truce-Sign** parleys (Light), and WorldStateDB deltas. | **PASS** |
| **GATE 3** *Philological Linter & Single-Origin Antagonist Rule* | Pass the 4 Linter Rules (8-Year-Old Read-Aloud, Map-Sense compounds, hyphenated cadence, zero grimy/textbook words) & Single-Origin Antagonist Rule. | Every settlement and zone uses canonical hyphenated Map-Sense compounds (Oakshire-Wick, Wayfarer-Green, Pippin-Green, Quarry-Wick, Bramble-Hollow, Nine-Stones-Crossing, Honey-Wick, Bramble-Bridge, Moss-Oak-Hollow, Rush-Light-Hollow, Dover-Slap-Bridge, Dover-Slap-Falls, Tizzi-Wed-Green, Gull-Wick-Haven, Barley-Bridge-Meadow, Barrow-Crag-Crossing, Sunken-Crown-Falls). Environmental decay is purely **The First-Quiet** rising through **Hush-Cracks**—zero skulls, gore, or grimdark blight. | **PASS** |
| **GATE 4** *Schema-First Registry* | Content added as typed Resource data registered in central catalogs; polymorphic resolution. | All biome palettes, terrain splat rules, architectural prop kits, foliage densities, HLOD silhouettes, and succession states live in typed ZoneBiomeResource, WorldPropKitResource, and ZoneSuccessionVisualResource schemas registered in WorldVisualCatalog. | **PASS** |
| **GATE 5** *Code-First & Multi-Age Safe* | Build deterministically in GDScript; $4.8m$ camera / $3.2m$ obstacle sightlines; support Master, Adventurer, and Squire tiers. | \$100\\%\$ deterministic GDScript generation in tools/build\_oakshire\_vale.gd, tools/build\_levels.gd, and ShapeKit; automatic shader dither-fade on canopies $>3.2m$; all bridges/ramps $\leq 2{5}^{\circ }$ with flush colliders; high-contrast ground values so RaidTelegraphDecal rings remain \$100\\%\$ legible for a 4-year-old Squire. | **PASS** |

## **2\. Aesthetic Direction & Material Language: *The Making* vs. *The First-Quiet***

### **2.1 Visual Philosophy: *The Making* (Domestic Stewardship)**

In *Everwood*, every human structure is a physical act of **Domestic Stewardship (*The Making*)** holding back the trackless slumber of the earth. Architecture and landscape design must never look like generic high-fantasy marble palaces or gritty medieval squalor; they must radiate tactile, hand-fitted rural craftsmanship:

* **Stepped-Gable Brick & Half-Timber Craft (*Bramble-Bridge*, *Oakshire-Wick*, *Honey-Wick*):** Inspired by Bruges, Visby, and *Kiki's Delivery Service*, buildings rest on chamfered fieldstone plinths ($0.6m$ high) that keep dampness off warm lime-washed plaster (\#F4EFE6) and kiln-fired terracotta brick (\#B85D43), framed by heavy adze-hewn oak posts, diagonal braces, and pegged corbels (\#5C4028).  
* **Scalloped Shingle & Steep Gable Roofs:** Roofs pitch at $3{8}^{\circ }–4{5}^{\circ }$ with stepped masonry gables, overlapping courses of weathered slate-blue, moss-green, or warm clay shingles, dormer windows, and brick chimneys puffing gentle curls of apple-wood smoke.  
* **Hierarchy of Ways (*Bale-Ways to Sunken Holloways*):** In compliance with 08\_EVERGREEN\_DEV\_BIBLE.md Pillar 4, roads physically tell the story of trade and travel:  
  1. **Flagged Bale-Ways:** $5.0–6.0m$ wide main arteries paved with warm limestone and sandstone flagstones bordered by curb stones and knee-high dry-stone walls ($\leq 0.9m$ high on the LowScenery physics layer so cameras never snag).  
  2. **Sunken Holloways (*Moss-Oak-Hollow* & *Rush-Light-Hollow*):** Ancient lanes worn $1.5–2.0m$ deep into the earth between mossy banks, overhung by gnarled oak roots and lit by swaying clay-and-brass **Wind-Lanterns**.  
  3. **Sheep-Stile Deer-Runs:** Narrow $2.5m$ trodden dirt-and-clover footpaths crossing stone walls via low wooden sheep-stiles ($\leq 2{0}^{\circ }$ ramp colliders) leading to hidden **Wayfarer's Chests** and **Water-Shrines**.

### **2.2 Visual Philosophy: *The First-Quiet* & Ecological Succession**

Grounded in our **Triumvirate Lens** (Le Guin, Cooper, Miyazaki) and Everwood Narrative Progression & Ecological Succession Plan, **The First-Quiet (*The Un-Making*)** never manifests as neon purple ooze, skulls, or military fortifications. Instead, every zone chunk supports three persistent visual states driven by WorldStateDB:

| Succession State (ZoneSuccessionState) | Environmental Palette & Shader State | Architectural & Prop State | Ambient & Particle World Effects |
| :---- | :---- | :---- | :---- |
| **1\. ZONE\_HUSHED** *(Initial Exposure / Active Hush-Crack Radius)* | Within an active **Hush-Crack**'s $18.0m$ influence radius, storybook\_terrain\_splat.gdshader desaturates turf by \$45\\%\$ toward cool slate-grey (\#6E7880), rimmed by pale hoar-rime and creeping ground mist. | Boundary stones show hairline fissures seeping pale mist; nearby **Wind-Lanterns** sit snuffed or dim; plough-furrows look slumped and untended; **Maker-Seals** sit inverted. | Birdsong and bee particles pause inside the hush radius; slow, low-drifting grey-blue hush-motes rise from the earth crack. |
| **2\. ZONE\_RECLAIMED** *(Succession Payoff — Hush-Crack Sealed / Boss Lulled)* | A $2.5s$ radial **Reclamation Bloom** sweeps outward from the sealed crack, restoring full sunlit Lydian/Ionian saturation, warm emerald-and-ochre turf, and wildflower clusters. | The **Hush-Crack** seals into a mossy **Lulled Cairn** (STATE\_LULLED\_CAIRN) ringed by daisies and heather; **Wind-Lanterns** ignite in Saffron-Gold (\#F2B749); waterwheels turn briskly; **Maker-Seals** glow upright. | Golden pollen motes, fluttering hedge-wrens/sea-swallows, and warm hearth-sparks drift through the restored clearing. |
| **3\. ZONE\_WEATHERING\_EVENT** *(Seasonal Macro-Stewardship Overlay)* | Preserves the reclaimed architectural legacy while overlaying a directional microclimate shader pass (*Barrow-Rime* frost dust, *Bog-Rust* amber damp, or *Deep-Hush* rolling fog banks). | Village beacons and **Chime-Posts** flare with high-visibility Sign-tints so the party can form a 5.5m **Lantern's Promise** relay from post to post. | Directional wind-streaks, driving snow/sea-fret particles, and swaying tree canopies scaled by the event intensity scalar. |

### **2.3 Master Palette & Readability Contrast Contract**

To guarantee that a 4-year-old Squire on a 4-way split-screen television can instantly read **The Four Scribe Signs** and RaidTelegraphDecal rings (CRIMSON\_DODGE\_OUT, GOLD\_PARTY\_SOAK, BLUE\_BEHIND\_TANK, GREEN\_HEAL), world ground surfaces are strictly forbidden from using high-saturation neon reds, pure cyan-blues, or blinding yellows. Ground values are anchored in mid-value earthy tones (\$35\\%\\text{–}65\\%\$ luminance):

| Palette Category | Primary Surface / Element | Canonical Hex & RGB | Shader Roughness / Specular | Visual & Gameplay Role |
| :---- | :---- | :---- | :---- | :---- |
| **Tizzi-Wed-Green Turf** | Sunlit meadow grass & clover | \#5B8C4A (91, 140, 74\) | Roughness 0.88, Spec 0.10 | Warm, restful primary ground canvas for Oakshire Vale and Bramble-Bridge. |
| **Orchard & Autumn Moss** | Dappled bank moss & fern | \#436B3C (67, 107, 60\) | Roughness 0.92, Spec 0.08 | Shaded holloway banks and Moss-Oak-Hollow canopy floor. |
| **Bale-Way Flagstone** | Warm hewn limestone cobbles | \#C8BFA8 (200, 191, 168\) | Roughness 0.75, Spec 0.20 | High-readability footpath & combat arena floor; contrasts cleanly with all telegraph decals. |
| **Sunken-Hollow Loam** | Damp peat, earth & root-soil | \#594636 (89, 70, 54\) | Roughness 0.85, Spec 0.15 | Rush-Light-Hollow and sunken trail beds. |
| **Dover-Slap Granite** | Highland crag & river boulder | \#7A8086 (122, 128, 134\) | Roughness 0.70, Spec 0.25 | Dover-Slap-Bridge piers, Quarry-Wick, and Ring of the Cairnsman. |
| **Stewardship Timber** | Adze-hewn oak & cedar | \#6E4B2E (110, 75, 46\) | Roughness 0.80, Spec 0.12 | Half-timber framing, bridges, waterwheels, Scribe Desk, and cedar bee-hives. |
| **Lime-Wash & Brick** | Village gable plaster & brick | \#F2ECE1 / \#B55A3F | Roughness 0.85, Spec 0.10 | Stepped-gable walls, bakery ovens, and gatehouse turrets. |
| **Sign of Iron-Root** | Amber-Ochre Seal & Accent | \#D9822B (217, 130, 43\) | Emission 1.4x | Poise / *Shatterpoint* architectural inlays & Chime-Post ribbons. |
| **Sign of Rime-Gale** | Sea-Azure Seal & Accent | \#38A3D1 (56, 163, 209\) | Emission 1.4x | Burst / *Glacial Rupture* water-shrine & coastal inlays. |
| **Sign of Warm-Hearth** | Saffron-Gold Seal & Accent | \#F2B749 (242, 183, 73\) | Emission 1.8x | Mending / *Dawnburst* Wind-Lanterns, campfires, & Hearth-Rite borders. |
| **Sign of Star-Tide** | Twilight-Violet Seal & Accent | \#8C52D9 (140, 82, 217\) | Emission 1.5x | Stamina / *Astral Chorus* standing stone spirals & portal rings. |

## **3\. Shader, Texture, & Material Pipeline (Godot 4.7.2 Code-First)**

To eliminate flat, un-textured surfaces while respecting CLAUDE.md and **Gate 5** (zero fragile hand-edited .tscn sub-resources; \$100\\%\$ deterministic headless boot), *Everwood* introduces a two-pronged material architecture: **ProceduralTextureAtelier** (which bakes tileable craft albedo, normal, and roughness maps in code at startup or build time while checking res://assets/textures/world/\<id\>.png for external overrides) paired with four specialized Godot 4.7.2 shaders.

### **3.1 ProceduralTextureAtelier (src/world/procedural\_texture\_atelier.gd)**

On boot (or during tools/build\_\*.gd landblock baking), ProceduralTextureAtelier deterministically generates and caches eight core $256\times 256$ seamless ImageTexture sets (Albedo \+ Normal \+ Roughness/AO) in $<60ms$ on worker threads (falling back to $64\times 64$ in \--headless CI for instant test execution):

> 1. **tex\_cobbled\_flagstone:** Voronoi-beveled Ashlar and river-cobble stones with warm mortar grooves and subtle moss flecks.  
> 2. **tex\_stepped\_brick:** Running-bond Flemish kiln bricks with varied terracotta/ochre hues and recessed lime mortar.  
> 3. **tex\_lime\_plaster:** Hand-troweled stucco with subtle warm cottage weathering.  
> 4. **tex\_hewn\_timber:** Directional wood-grain fibers, adze tool marks, and pegged joinery seams.  
> 5. **tex\_scallop\_shingle:** Overlapping fish-scale clay and slate roof tiles with drop-shadow normal depth.  
> 6. **tex\_meadow\_turf:** Painterly grass-blade strokes and clover patches that break up flat terrain spans.  
> 7. **tex\_hollow\_loam:** Rich woodland peat, fallen oak leaves, and exposed root-bark striations.  
> 8. **tex\_crag\_granite:** Stratified highland stone with lichen and heather crevices.

*External Texture Override Hook:* Just as ActorVisuals checks res://assets/models/\<id\>.glb, ProceduralTextureAtelier.get\_texture\_set(id) checks ResourceLoader.exists("res://assets/textures/world/%s\_albedo.png" % id) first, automatically binding curated textures whenever dropped into the folder.

### **3.2 storybook\_world\_triplanar.gdshader (Architectural & Prop Shader)**

Upgrades storybook\_cel.gdshader for all buildings, bridges, walls, shrines, and rocks:

* **World-Space Triplanar Projection:** Computes seamless UV coordinates from world/object-space position and normal vectors so procedural boxes, cylinders, and bevels display crisp brick courses, stone mortar, and timber grain without UV stretching.  
* **2-Band Sunlit Toon Ramp \+ Warm Bounce Shadow:** Preserves our signature *Wind Waker* / *Tunic* cel ramp while tinting shadow bands with warm sky/ground hemisphere bounce (never muddy grey-black).  
* **Top-Face Moss & Weathering Blend:** Automatically blends mossy green (\#4A733E) or highland heather (\#7B587D) onto upward-facing normals ($normal.y>0.65$) modulated by world-space noise, making bridges, boulders, and ruins look rooted in the land.  
* **Camera Sightline Dither-Fade ($4.8m$ Eye-Line Protection):** In strict compliance with **Gate 5**, when a building roof, archway, or tree trunk with enable\_sightline\_fade \= true sits above $y=3.2m$ and enters the cylinder between the active viewport camera and its target hero, a $4\times 4$ Bayer screen-space dither smoothly fades ALPHA down to 0.18 so players are never blinded in combat.

### **3.3 storybook\_terrain\_splat.gdshader (Continuous Landscape & Succession Shader)**

Replaces flat vertex-colored terrain meshes in LandblockTerrain (tools/build\_oakshire\_vale.gd and tools/build\_levels.gd):

* **4-Channel Height, Slope, & Vertex-Weight Splatting:** Blends tex\_meadow\_turf (flat greens), tex\_cobbled\_flagstone (painted along road/square weights), tex\_hollow\_loam (sunken holloway trenches and forest floors), and tex\_crag\_granite ( automatically appearing on cliff slopes $>3{2}^{\circ }$ and high elevations).  
* **Real-Time Hush-Crack Atmospheric Creep & Reclamation Bloom:** Accepts up to 4 active Hush-Crack world positions and radii per chunk (uniform vec4 hush\_cracks\[4\], where .xyz is world position and .w is current hush radius $0.0–18.0m$). Inside the radius, the shader smoothly desaturates turf into cool slate-grey (ZONE\_HUSHED) and draws a subtle cracked-earth rim; when the family un-boggarts the camp or boss, WorldStateDB shrinks .w to 0.0 while pulsing a golden-green **Reclamation Bloom** wave (ZONE\_RECLAIMED) across the meadow.

### **3.4 storybook\_foliage\_wind.gdshader & storybook\_water\_stream.gdshader**

* **Ghibli Foliage & Grass Shader (storybook\_foliage\_wind.gdshader):**  
  * Transfers spherical canopy normals across clustered leaf-cards/puffs so tree crowns (Moss-Oak, Weeping Willow, Apple Orchard, Highland Pine) shade as lush, volumetric storybook clouds rather than intersecting flat polygons.  
  * Applies phase-offset sinusoidal vertex wind sway (scaled by GorgeGaleJet or ZONE\_WEATHERING\_EVENT wind vectors) plus a **Hero Brush Displacement** uniform that bends grass and low shrubs away within $1.2m$ of moving players.  
* **Stylized Stream, Canal, & Waterfall Shader (storybook\_water\_stream.gdshader):**  
  * Renders clear, inviting water for the **Bramble-Bridge Canal**, **Wayfarer's Water-Shrine**, **Rush-Light-Hollow** willow pools, and **Dover-Slap-Falls**.  
  * Features depth-based color absorption (shallow sunlit aqua \#52B8B2 $\rightarrow$ deep indigo-teal \#1F5E6B), scrolling cellular surface ripples, directional white-water foam streaks along bridge piers and waterfall crests, and crisp shoreline intersection foam.

## **4\. Tectonic Architectural & Environmental Kit Upgrade (ShapeKit & WorldAssetCatalog)**

Rather than assembling buildings from single boxes and cylinders, ShapeKit (src/actors/shape\_kit.gd) and the new WorldAssetCatalog (src/world/world\_asset\_catalog.gd) construct modular, multi-mesh architectural prefabs in code—checking res://assets/models/world/\<kit\_id\>.glb first for every asset ID.

### **4.1 Village & Homestead Architecture Kits**

> 1. **kit\_house\_stepped\_gable (Bruges/Visby Artisan House):**  
   * **Tectonic Parts:** Chamfered fieldstone foundation plinth ($0.6m$); timber-framed first story with warm lime-wash plaster and diagonal oak braces; corbeled jetty overhang ($0.25m$); stepped brick gable facades (5 to 7 masonry steps capped with limestone coping stones); $4{2}^{\circ }$ scalloped shingle roof with a pitched dormer window; leaded Mullion window boxes with flower-troughs and warm interior OmniLight3D evening glow (\#FFBA66); and a brick chimney with a rising smoke particle emitter.  
   * **Variants:** Configurable via parameters for **The Smoking Bakery** (adds a domed brick bread-oven alcove with glowing coals and baker's peel rack), **The Reed-Light Scribery** (adds hanging vellum banners in the 4 Sign colors and drying pigment bundles), and **The Oakshire Homestead Hall** (wider L-plan timber hall with a wrap-around porch).  
> 2. **kit\_watermill\_wheel (Bramble-Bridge & Dover-Slap Vellum Mill):**  
   * **Tectonic Parts:** Dual timber axle-piers, 12-spoke oak wheel ($4.4m$ diameter) with 24 angled wooden bucket-paddles, iron rim-bands, a timber mill-race flume directing foamy water over the top, and a synchronized splash particle ring \+ Ambience3D emitter (area\_mask \= 1).  
> 3. **kit\_bridge\_stone\_arch & kit\_bridge\_carpathian\_trestle:**  
   * **Bramble-Bridge Stone Canal Arch:** Smooth $\leq 1{3}^{\circ }$ approach ramps and a flat crown backed by a single snag-free convex collider flush with the ground, dressed visually with radiating limestone arch voussoirs, a carved central **Maker-Seal Keystone**, low $0.75m$ stone parapets (LowScenery layer), and corner **Wind-Lantern** posts.  
   * **Dover-Slap Timber-and-Stone Trestle (Dover-Slap-Bridge):** Soaring granite chasm piers supporting heavy criss-cross Carpathian timber trusses, cantilevered **Maker-Seal Plate** bays on either side, and the twin-turreted **Dover-Slap Gatehouse** with an iron-shod oak portcullis, carved shingled spires, and the **Bronze Bridge-Bell Winch**.

### **4.2 Stewardship Stations & Miyazaki Mundane Magic Props**

> 1. **kit\_scribe\_desk\_pavilion (The Armory & Scribe Desk):**  
   * Open-sided timber pavilion ($\leq 3.0m$ eaves with sightline dither-fade) housing a heavy oak **Scribe Press** with a wooden screw-spindle, open illuminated Grimoire folios, four glowing glass inkwells (SIGN\_IRON\_ROOT, SIGN\_RIME\_GALE, SIGN\_WARM\_HEARTH, SIGN\_STAR\_TIDE), and a weapon rack displaying the four tiered martial silhouettes.  
> 2. **kit\_chime\_shrine\_pagoda (The Chime-Shrine):**  
   * Octagonal stone plinth supporting a carved cedar bell-frame hung with **five graduated bronze carillon chimes** (tuned to the pentatonic $G–A–B–D–E$ resonances of 16\_ADAPTIVE\_AUDIO\_ARCHITECTURE.md) that physically swing and gleam with Saffron-Gold light whenever the party banks or spends **Chimes**.  
> 3. **kit\_chime\_post\_diagnostic (The Nursery Rhyme Chime-Post):**  
   * Placed at every zone threshold, bridge approach, and Hush-Crack trailhead: a $2.6m$ carved oak way-post with a curved cross-arm, a swaying bronze chime-lantern, and four painted wooden **Scribe Sign** vanes. Walking within $6.0m$ rings a soft chime and unfurls the zone's diagnostic nursery rhyme couplet on CrossGrimoireHUD's Chime-Post ribbon.  
> 4. **kit\_water\_shrine\_oasis (Wayfarer's Water-Shrine):**  
   * Moss-draped stone basin beneath a tiny hipped cedar-shingle roof ($\leq 2.4m$ tall), fed by a carved stone spout pouring clear, sparkling water (storybook\_water\_stream.gdshader) surrounded by glowing blue-green ferns and floating water-striders. Reflects its WorldStateDB cooldown visually (dropping water flow and mist glow while resting for $40s$).  
> 5. **kit\_hush\_crack\_and\_cairn (Dynamic Hush-Crack $\rightarrow$ Reclaimed Cairn):**  
   * **While ZONE\_HUSHED (Un-Sealed):** A $3.5m$ jagged root-and-earth fissure in the turf emitting slow slate-grey mist plumes and muted desaturation.  
   * **When Sealed (ZONE\_RECLAIMED):** Smoothly transitions into a peaceful, moss-and-heather-crowned **Stewardship Cairn** (STATE\_LULLED\_CAIRN) ringed by golden wildflowers and a warm miniature path-light, physically preserving the family's victory in the world.

### **4.3 Botanical & Geological Kit (MultiMeshInstance3D Clutter & Hero Trees)**

* **Hero Trees (kit\_tree\_moss\_oak, kit\_tree\_orchard\_apple, kit\_tree\_weeping\_willow, kit\_tree\_highland\_pine):**  
  * Built with gnarled, buttressed root flares, tapered trunks with branch forks, and 5 to 9 volumetric leaf-cloud clusters using storybook\_foliage\_wind.gdshader.  
  * **Strict Sightline Contract:** Every tree trunk within $12m$ of a walkable lane branches above $3.2m$ so the lower $3.2m$ is an unobstructed sightline corridor, and the upper canopy automatically dither-fades when between the $4.8m$ camera and a player.  
* **GPU MultiMeshInstance3D Ground Clutter (Per-Chunk Baker):**  
  * Each $128m\times 128m$ Landblock bakes 3 lightweight MultiMeshInstance3D batches on its Clutter ring (Ring 1, loaded within $2$ chunks):  
    1. mm\_grass\_clumps: $600–1,200$ painter-style grass blades and clover tufts per chunk (zero physics collision, wind-swayed).  
    2. mm\_wildflowers\_ferns: $150–300$ biome-specific blooms (daisies and buttercups in Greens; bracken ferns and luminous rush-reeds in Hollows; purple heather in Crags).  
    3. mm\_pebbles\_fungi: $80–150$ mossy river cobbles, shelf mushrooms, and fallen twigs along trail edges.

## **5\. Zone-by-Zone Overhaul Specification**

### **5.1 Starting World: Oakshire Vale (scenes/worlds/oakshire\_vale.tscn — $12\times 12$ Landblocks)**

tools/build\_oakshire\_vale.gd is upgraded so the $1.5km\times 1.5km$ seamless vale transforms from a uniform green field into a richly differentiated six-subzone watershed anchored by **Oakshire-Wick** at its center and five radiating threshold petals pointing toward the **Six-Zone Stewardship Atlas**:

| Sub-Zone / Petal | Grid & Directional Sector | Biome & Material Signature | Signature Landmarks & Stewardship Architecture |
| :---- | :---- | :---- | :---- |
| **1\. Oakshire-Wick** *(Central Homestead Hub)* | Center Chunks *Sign of Wood* (Tizzi-Wed-Green) | Sunlit emerald turf (\#5B8C4A), flagged limestone courtyard, warm half-timber & brick. | **The Oakshire Homestead Hall**, the central **Kindle-Fire** ring, **Armory & Scribe Desk**, **Chime-Shrine**, **7 custom cedar bee-hives** in a south-facing convex arc along the east woodline with humming bee particles, two heirloom pumpkin patches (Musquée de Provence ribbed terracotta-orange gourds) inside knee-high dry-stone walls, and a turning brook waterwheel. |
| **2\. Wayfarer-Green** *(Southern Threshold Petal)* | South Sector Leads toward Bramble-Bridge & Gull-Wick-Haven | Breezy coastal-meadow grass, chalk-limestone Bale-Way flagstones, white-blossom apple trees. | **The Wayfarer's Arch**, a flagged **Bale-Way** lined with swaying **Wind-Lanterns**, a hillside windmill with turning canvas sails, sheep-stiles, and a **Chime-Post** looking toward the southern chalk downs. |
| **3\. Pippin-Green** *(Eastern Threshold Petal)* | East Sector Threshold to Barley-Bridge-Meadow (*Sign of Iron*) | Golden-green pasture blended with parallel ploughed furrow strips and warm ochre soil. | Terraced **Apple & Pear Orchards**, a timber **Cider & Barley Mill** beside a stone-bridged stream, dry-stone enclosures, and resting **Furrow Iron-Men** standing amid the furrows waiting to have their **Maker-Seals** turned upright. |
| **4\. Quarry-Wick** *(Western Threshold Petal)* | West Sector Threshold to Barrow-Crag-Crossing (*Sign of Stone*) | Stepped limestone and grey granite ledges, rusty-ochre gravel paths, hardy pines. | Hewn stone quarry terraces ($\leq 2{2}^{\circ }$ walkable ramps), timber A-frame pulley cranes, stacked ashlar blocks carved with SIGN\_IRON\_ROOT marks, and mossy boulder cairns. |
| **5\. Bramble-Hollow** *(North-West Threshold Petal)* | North-West Sector Threshold to Rush-Light-Hollow (*Sign of Fire*) | Sunken peat-loam holloway (\#594636), dappled willow-pools, mossy root banks. | Root-arched sunken lane, weeping willows trailing over reflective pools (storybook\_water\_stream.gdshader), hanging clay **Wind-Lanterns**, a **Wayfarer's Water-Shrine**, and slumbering *Wisp-Boggle* Hush-Cracks. |
| **6\. Nine-Stones-Crossing** *(Northern Threshold Petal)* | North Sector Threshold to Sunken-Crown-Falls (*Sign of Bronze*) | Elevated heather-and-granite ridge, twilight-violet wildflower tufts, mist-swept stone. | A circle of **Nine Weathered Standing Stones** inlaid with SIGN\_STAR\_TIDE spirals, an ancient flagged causeway, a bronze **Threshold Bell-Frame**, and a panoramic vista overlooking the northern cataract. |

### **5.2 Seamless Corridor & Expedition: The Bramble-Bridge Trail (everwood\_world.gd, hub\_town.gd, dungeon\_dojo.gd)**

tools/build\_levels.gd upgrades both the seamless 5-chunk corridor (everwood\_world.gd) and the instanced hub/expedition (hub\_town.gd, dungeon\_dojo.gd) so every zone along the trail shares the new tectonic kits, shaders, and **Ecological Succession** hooks:

> 1. **Chunk $(0,1)$ — Honey-Wick & The Kindle-Fire:**  
   * Upgrades the bivouac clearing with a detailed river-stone hearth ring, iron tripod kettle with rising steam, quilted travel packs, an ancient bivouac oak with a swaying **Wind-Lantern**, the **7 south-facing cedar bee-hives** with golden bee particle loops, two ribbed heirloom pumpkin patches framed by mortared dry-stone walls (LowScenery), and a warm stepped-gable cottage leading north to the canal.  
> 2. **Chunk $(0,0)$ — Bramble-Bridge (South Bank Green & North Village Square):**  
   * **South Bank & Canal:** Paved with bevel-edged limestone cobbles leading to the **Bramble-Bridge Stone Arch** ($\leq 1{3}^{\circ }$ flush collider) spanning a lively, foam-streaked canal (storybook\_water\_stream.gdshader) with stone quay walls, moored wooden skiffs, and the turning $4.4m$ **Watermill Wheel**.  
   * **North Village Square:** Framed by 5 multi-part kit\_house\_stepped\_gable buildings (Bruges/Visby brick and half-timber), cobblestone flower planters, the **Smoking Bakery** with glowing brick oven, the **Armory & Scribe Desk Pavilion**, the 5-bell **Chime-Shrine Pagoda**, drying pigment racks in the Four Sign hues, and the carved timber **Northern Forest Gate** with a diagnostic **Chime-Post**.  
> 3. **Chunk $(0,-1)$ & Dojo Zone 1 — Moss-Oak-Hollow into Rush-Light-Hollow:**  
   * **The Moss-Oak Great Arch:** Massive buttressed oak trunks arching $6.0m$ overhead (with automatic camera dither-fade above $3.2m$) casting dappled canopy light-shafts onto the trail.  
   * **The Bramble Hush-Crack & Deer-Run Alcove:** Visualizes the first **Hush-Crack** with localized ZONE\_HUSHED slate desaturation that blooms into wildflowers (ZONE\_RECLAIMED) when the 3 *Bramble-Hobs* are un-boggarted into hedge-wrens. The forked deer-run behind dry-stone walls leads over a sheep-stile to a brass-bound **Wayfarer's Chest**.  
   * **The Sunken-Hollow Descent (Rush-Light-Hollow Edge):** As the lane descends between $1.8m$ mossy earthen banks and gnarled root-ribs (z \= \-54 to \-74 on the grid), swaying clay **Wind-Lanterns** and the **Wayfarer's Water-Shrine** create warm Saffron-Gold and Sea-Azure light oases against the harmonic-minor twilight mist before the second Hush-Crack.  
> 4. **Chunk $(0,-2)$ & Dojo Zone 2 — Dover-Slap-Bridge & Dover-Slap Gatehouse:**  
   * **The Roaring Cataract (Dover-Slap-Falls):** Multi-tiered granite cliff face down which a wide white-water curtain plunges (storybook\_water\_stream.gdshader), kicking up volumetric mist plumes and rainbow spray.  
   * **The Trestle & Vellum Mill:** Heavy Carpathian timber-and-stone trestle bridge flanked by the giant spinning paper-mill waterwheel pounding linen into Scribe vellum.  
   * **Co-Op Threshold Visuals:** The twin **Maker-Seal Plates** feature recessed brass-and-stone geometric inlays that fill with glowing amber/azure light as players stand on them (CoopGate), while the **Gorge Gale-Jet** renders crisp, translucent wind-ribbons down the center lane that visibly part around a Shield-Sworn Tank's Shadow Sanctuary cone on the way to the **Bronze Bridge-Bell Winch**.  
> 5. **Chunk $(0,-3)$ & Dojo Zone 3 — The Ring of the Cairnsman:**  
   * Climbing to $+18m$ elevation, the stone causeway opens into a circular sanctum paved with weathered concentric flagstones (kept \$100\\%\$ clear of clutter $>0.15m$ and mid-value \#8A8E91 so CRIMSON\_DODGE\_OUT, GOLD\_PARTY\_SOAK, and the Phase 2 BLUE\_BEHIND\_TANK **Dover-Slap Gale-Beam** telegraphs pop with maximum contrast).  
   * Ringed by 12 monolithic mossy standing stones carved with spiral **Maker-Seals**, wind-bent highland pines, heather banks, and an unobstructed cliffside vista overlooking the waterfall gorge below.

## **6\. Draw Distance, 4-Ring HLOD & Vista Architecture, Lighting, & World Effects**

### **6.1 Extending Draw Distance Without Frame Stalls: The 4-Ring Streaming & Vista Contract**

To make *Everwood* feel like a vast, interconnected world from any hill or bridge while strictly honoring WorldGridManager's $2.0ms$ **per-frame attachment budget** (04\_BALANCE.md), draw distance is structured across four concentric rings:

| Streaming Ring | Distance from Local FocusPoints | Geometry & Shader Payload | Performance & Readability Guarantee |
| :---- | :---- | :---- | :---- |
| **Ring 0: Active Gameplay** *($\leq 1$ Chunk / $0–128m$)* | Load $\leq 1$, Unload $>2$ | Full tectonic kits, colliders, interactive stations, HobSpectrumComponent AI ($60Hz$ $\leq 35m$, $10Hz$ $\leq 90m$), and 3D Ambience3D emitters. | \$100\\%\$ deterministic physics and combat hitboxes. |
| **Ring 1: Botanical & Prop Clutter** *($\leq 2$ Chunks / $128–256m$)* | Load $\leq 2$, Unload $>3$ | Hero trees and GPU MultiMeshInstance3D batches (mm\_grass\_clumps, mm\_wildflowers\_ferns, mm\_pebbles\_fungi) with distance scale-down fade at $220m$. | Single draw call per MultiMeshInstance3D batch per chunk; zero CPU tick cost. |
| **Ring 2: Merged Chunk HLOD** *($\leq 3–4$ Chunks / $256–512m$)* | Load $\leq 3$, Unload $>4$ | Single baked ArrayMesh per chunk (\<chunk\>\_hlod.res) combining decimated terrain, merged stepped-gable rooflines, and simplified tree-crown silhouettes. | Keeps distant villages and woods visible across all of Oakshire Vale in $1$ draw call per distant chunk. |
| **Ring 3: The Panoramic Atlas Horizon Skirt** *($512m\rightarrow 2,500m$)* | Persistent lightweight horizon ring (HorizonVistaRing) | A 360-degree painter's horizon mesh (camera.far \= 3000.0) featuring the silhouette landmarks of the **Six-Zone Stewardship Atlas**: (North) the towering cataract mist of **Sunken-Crown-Falls** & the **Dover-Slap Mill-Castle**; (West) the granite tors of **Barrow-Crag-Crossing**; (East) the golden rolling hills & windmills of **Barley-Bridge-Meadow**; (South) the white chalk cliffs & sea-stacks of **Gull-Wick-Haven**. | Gives players an inspiring sense of scale and direction without ever loading distant zone instances into memory. |

### **6.2 Dynamic Atmosphere, Sky, & World Particle Effects (WorldAtmosphereDirector)**

> 1. **Sunlit Filmic Environment & Modal Fog Shifts (src/world/world\_atmosphere\_director.gd):**  
   * Configures WorldEnvironment with TONE\_MAPPER\_FILMIC, a procedural ProceduralSkyMaterial (warm cerulean zenith \#3B78B8, sunlit golden-cream horizon \#F5E2C4), directional sun light (shadow\_blur \= 1.4), and subtle screen-space ambient occlusion / glow that makes **Four-Sign** seals and **Wind-Lanterns** sing.  
   * Smoothly interpolates fog\_light\_color, fog\_density, and ambient sky contribution as the party crosses zone thresholds—shifting from breezy golden-green meadow air in Bramble-Bridge and Oakshire-Wick (G\_LYDIAN) to cool emerald-slate canopy mist in Rush-Light-Hollow (E\_HARMONIC\_MINOR) and crisp highland spray on Dover-Slap-Bridge (A\_DORIAN).  
> 2. **Ambient Mundane-Magic Particle Layers:**  
   * **Meadow Pollen & Dandelion Drift:** Gentle upward-floating sunlit motes across Oakshire Vale, Honey-Wick, and Bramble-Bridge.  
   * **Canopy Dappled Light-Shafts:** Translucent additive sunbeam planes angled parallel to the directional sun under the Moss-Oak Great Arch and orchard groves.  
   * **Waterfall Plume & Creek Mist:** Continuous billowing mist emitters at the base of Dover-Slap-Falls and the Bramble-Bridge watermill wheel.  
   * **Un-Boggarting & Reclamation Persistence:** Sealing a Hush-Crack replaces its dark hush-mote emitter with a permanent warm path-light and orbiting fireflies/butterflies synced via WorldStateDB.

## **7\. Schema-First GDScript Specifications & Headless CI Verification Gates**

### **7.1 Schema-First Resource Specifications (src/resources/)**

#### **A. ZoneBiomeResource (src/resources/zone\_biome\_resource.gd)**

Fulfilling the expansion contract reserved in 08\_EVERGREEN\_DEV\_BIBLE.md §3 Pillar 4:

GDScript  
class\_name ZoneBiomeResource  
extends Resource

\#\# Canonical Sightline & Streaming Constants (Gate 5\)  
const CAMERA\_EYELINE\_HEIGHT\_M: float \= 4.8  
const MAX\_OBSTACLE\_SIGHTLINE\_M: float \= 3.2  
const MAX\_WALKABLE\_RAMP\_DEG: float \= 25.0  
const DEFAULT\_HUSH\_RADIUS\_M: float \= 18.0

@export var biome\_id: StringName \= &"tizzi\_wed\_green"  
@export var display\_name: String \= "Tizzi-Wed-Green"  
@export var cooper\_sign\_title: String \= "Sign of Wood"  
@export var primary\_scribe\_sign: int \= 0 \#\# ScribeSignResource.Sign

\#\# Terrain Splat Colors (Mid-value calibrated for Telegraph Decal contrast)  
@export var turf\_albedo: Color \= Color(0.357, 0.549, 0.290)      \#\# \#5B8C4A  
@export var road\_albedo: Color \= Color(0.784, 0.749, 0.659)      \#\# \#C8BFA8  
@export var hollow\_albedo: Color \= Color(0.349, 0.275, 0.212)    \#\# \#594636  
@export var crag\_albedo: Color \= Color(0.478, 0.502, 0.525)      \#\# \#7A8086  
@export var hush\_desaturate\_tint: Color \= Color(0.431, 0.471, 0.502) \#\# \#6E7880

\#\# Lighting & Atmosphere Envelope  
@export var sun\_color: Color \= Color(1.0, 0.95, 0.86)  
@export var sun\_energy: float \= 1.15  
@export var sky\_top\_color: Color \= Color(0.231, 0.471, 0.722)  
@export var sky\_horizon\_color: Color \= Color(0.961, 0.886, 0.769)  
@export var fog\_light\_color: Color \= Color(0.85, 0.89, 0.82)  
@export var fog\_density: float \= 0.0018

\#\# MultiMesh Clutter Densities (Per 128m x 128m Landblock)  
@export var grass\_clump\_count: int \= 800  
@export var wildflower\_count: int \= 200  
@export var pebble\_fungi\_count: int \= 100  
@export var tree\_kit\_ids: PackedStringArray \= PackedStringArray(\["kit\_tree\_moss\_oak", "kit\_tree\_orchard\_apple"\])

#### **B. WorldPropKitResource (src/resources/world\_prop\_kit\_resource.gd)**

GDScript  
class\_name WorldPropKitResource  
extends Resource

@export var kit\_id: StringName \= &"kit\_house\_stepped\_gable"  
@export var category: StringName \= &"ARCHITECTURE"  
@export var bounding\_size: Vector3 \= Vector3(8.0, 7.5, 6.0)  
@export var is\_low\_scenery: bool \= false \#\# True for \<= 0.9m walls/rails on LowScenery layer  
@export var enable\_sightline\_fade: bool \= true \#\# Dither-fades geometry \> 3.2m when blocking camera  
@export var glb\_override\_path: String \= "res://assets/models/world/kit\_house\_stepped\_gable.glb"

### **7.2 Automated Headless CI & Visual Verification Gates (tools/smoke\_test.gd)**

Every world, shader, and landblock update must pass four automated verification checks before commit:

> 1. **Static Parse & Type Verification (--check-only):**  
>    Bash  
>    godot \--headless \--path . \--check-only \-s src/world/procedural\_texture\_atelier.gd  
>    godot \--headless \--path . \--check-only \-s src/world/world\_asset\_catalog.gd  
>    godot \--headless \--path . \--check-only \-s src/world/world\_atmosphere\_director.gd  
>    godot \--headless \--path . \--check-only \-s tools/build\_oakshire\_vale.gd  
>    godot \--headless \--path . \--check-only \-s tools/build\_levels.gd

> 2. **Landblock Re-Bake & Streaming Budget Gate (tools/test\_world\_grid.gd & tools/test\_oakshire\_vale.gd):**  
   * Re-bake data/landblocks/ via tools/build\_levels.gd and tools/build\_oakshire\_vale.gd.  
   * Assert that streaming attachment across 4 split-screen FocusPoints remains strictly within the $2.0ms$ frame budget and that every distant chunk resolves a valid merged \*\_hlod.res mesh plus the Ring 3 HorizonVistaRing (camera.far \>= 2500.0).  
> 3. **Sightline, Walkability, & Ecological Succession Assertions (tools/smoke\_test.gd):**  
   * Assert that all knee-high dry-stone walls, bridge parapets, and garden borders sit on the camera-ignored LowScenery physics layer, all bridge/trail ramps stay $\leq 2{5}^{\circ }$ with zero collider snags, and all tall canopy/arch materials above $3.2m$ bind enable\_sightline\_fade \= true.  
   * Simulate sealing a MinionCamp (**Hush-Crack**) and assert that WorldStateDB transitions the camp's visual state from ZONE\_HUSHED (hush radius $>0.0m$) to ZONE\_RECLAIMED (hush radius $0.0m$, spawning the mossy **Lulled Cairn** and lighting nearby **Wind-Lanterns**).  
> 4. **Philological Linter & Screenshot Audit (tools/test\_mythopoetic\_lens.gd & \--screenshot):**  
   * Run tools/test\_mythopoetic\_lens.gd across all registered ZoneBiomeResource and WorldPropKitResource display strings to verify \$100\\%\$ compliance with the Four Linter Rules.  
   * Capture \--screenshot verification frames at **Oakshire-Wick**, **Bramble-Bridge Square**, **Moss-Oak-Hollow / Rush-Light-Hollow**, **Dover-Slap-Bridge**, and **The Ring of the Cairnsman** for Stage 4 Multimodal Split-Screen Squint Audit.

## 8. Build Notes (Phase 17)

What the game does today, where it differs from §1–7, and what's still to come.

**In the code now**
- **Schemas** (`src/resources/`): `ZoneBiomeResource` (§7.1 A, with the sightline constants, plus each biome's wildflower and grass colours), `WorldPropKitResource` (§7.1 B) and `ZoneSuccessionVisualResource` (the three states of §2.2).
- **`WorldVisualCatalog`** (`src/world/world_visual_catalog.gd`) registers them by id:
  - 17 biomes: the six atlas zones, Oakshire Vale's village and five petals, and the trail's Honey-Wick, Bramble-Bridge, Moss-Oak-Hollow, Dover-Slap-Falls and the Ring of the Cairnsman. Each has the §2.3 ground palette, its sun, sky and fog, and its clutter counts.
  - 21 kits: the 13 of §4, plus the knee-high dry-stone wall, bee-hive, pumpkin patch, standing stone, Wind-Lantern post, windmill, pulley-crane and ashlar stack.
  - Which biome each place wears (`biome_for_place()`, `biome_for_music()`).
  - The shared world materials, one per look so scenes stay small and draw calls batch: `craft()`, `painted()`, `glowing()`, `double_sided()`, `terrain()`, `foliage()` and `water()`. `craft_for_color()` reads a colour's hue and value to pick its craft (limestone, brick, lime-wash, timber, granite, loam or turf).
  - A `.tres` in `res://data/world_visuals/` (a biome, kit or `succession_hushed` / `_reclaimed` / `_weathering`) replaces the built-in of that id.
- **`ProceduralTextureAtelier`** (§3.1) paints the eight craft sets (albedo, normal, roughness) in code from fixed seeds: 256 px, 64 px headless. A PNG at `res://assets/textures/world/<id>_<map>.png` replaces its map.
- **The shaders** (`src/world/shaders/`) share `storybook_world_common.gdshaderinc`: the atelier arrays, the heroes, the open Hush-Cracks and the Reclamation Blooms as global shader parameters (`project.godot` `[shader_globals]`).
  - `storybook_world_triplanar` (and its two-sided twin, for ramps and decks): triplanar craft over the palette colour (the texture keeps the colour's value; 40% of its own hue shows), moss on faces looking up, the cel bands, and the Bayer sightline fade above 3.2 m.
  - `storybook_terrain_splat` (Mode B): turf, flagstone, loam and granite by the painted colour and the slope (granite past about 32°), the value held in the mid-tones, and the hush and the bloom. The Terrain3D shader does the same over its colour maps.
  - `storybook_foliage_wind`: canopy normals, wind sway, the hero brush (1.2 m), the sightline fade and a fade-out with distance.
  - `storybook_water_stream`: #52B8B2 to #1F5E6B by depth, ripples along the flow, crest and shoreline foam, and a waterfall mode.
- **`WorldAtmosphereDirector`** (autoload `Atmosphere`):
  - renders the atelier on worker threads at start and binds three `Texture2DArray`s; surfaces show their plain colours until then (about 0.5 s);
  - every 0.4 s finds the biome most local players stand in (`LevelBase.visual_biome_at()`) and eases the sky, sun and fog to it (Filmic, a procedural sky, a 1.4-blur sun, light SSAO and glow);
  - every frame publishes the heroes, the four nearest open cracks and any blooms, and the wind;
  - keeps the `HorizonVistaRing` and the pollen motes round the party, and builds queued kits.
- **Ecological Succession.** `set_succession_state(zone_or_camp_id, state)`.
  - Every `MinionCamp` and chosen Oakshire `MobSpawner` carries a `HushCrackLandmark`. While open, its 18 m greys the turf, foliage and stone toward slate and dims the Wind-Lanterns in it.
  - Clearing the camp sweeps a 2.5 s golden-emerald bloom, the hush shrinks to nothing, and the fissure sinks as a heather-crowned Lulled Cairn rises with golden flowers, a path-light and fireflies.
  - A cleared camp (WorldStateDB) streams back in as a cairn. An Oakshire spawner's crack seals while its whole pack is beaten and quietly reopens when one regrows.
  - A biome can be hushed (it loses colour) or under a weathering event (thicker fog, stronger wind, flaring lanterns).
- **Kits** (`WorldAssetCatalog`) merge each kit's static parts into one mesh, one surface per material, cached by its options.
  - Scenes store a `WorldKitInstance` (the kit's id and options), not the mesh. A kit already cached appears at once; a new one waits in a queue built 1.5 ms a frame.
  - A curated `res://assets/models/world/<kit_id>[_<variant>].glb` replaces the code-built kit.
  - The stations build theirs: the Chime-Shrine's pagoda and five chimes that swing and gleam Saffron-Gold when Chimes are banked or spent; the Water-Shrine's oasis, whose pour thins while it rests; the Scribe Desk's pavilion; the 4.4 m watermill wheel with its splashes. The new `ChimePost` rings within 6 m and unfurls its place's couplet on that player's ribbon.
- **Clutter.** `ChunkClutterBaker` grows each landblock's `mm_grass_clumps`, `mm_wildflowers_ferns` (daisies and buttercups on the greens, ferns and rush-reeds in the hollows, heather on the crags) and `mm_pebbles_fungi` from its biome, off the roads, footprints and the Ring's floor, shrinking away by 220 m. The old clutter's trees are trunks with roots under leaf-cloud crowns, its stones crafted, and the river and falls run in the water shader.
- **Draw distance.** Player cameras see 3 km. Rings 0 to 2 are the grid's (gameplay within a chunk, clutter within two, HLOD within three to four). The `HorizonVistaRing` is Ring 3: three ridgelines from 0.9 to 2.3 km with the atlas's landmarks, unlit and hazing toward the sky. HLOD bakes use each kit's low-poly stand-in (house blocks with gable rooflines, simple crowns).
- **Oakshire Vale** (`tools/build_oakshire_vale.gd`, §5.1):
  - Oakshire-Wick's ten stepped-gable houses round the Oakshire Homestead Hall, with the Kindle-Fire ring, the desk pavilion, the Chime-Shrine pagoda, seven cedar hives along the east woodline and two walled pumpkin patches.
  - A Chime-Post at the village and at every camp.
  - Wayfarer-Green: a windmill with turning sails and sheep-stiles, and chalk Bale-Ways.
  - Pippin-Green: the cider mill, a walled orchard of fruit trees and plough-furrow strips.
  - Quarry-Wick: pulley-cranes, carved ashlar stacks, cairns and rusty gravel roads.
  - Bramble-Hollow: willow pools, hanging Wind-Lanterns and a Water-Shrine.
  - Nine-Stones-Crossing: nine standing stones with Star-Tide spirals, the Threshold Bell-Frame, a flagged causeway and heather on the ridge.
  - Hush-Cracks under Bramble-Hollow's briars, the outlaws' camp and the barrow wights.
- **The trail** (`tools/build_levels.gd`, §5.2): every surface crafted; kit houses with the bakery and the scribery; the canal, skiffs and the arch's voussoirs, keystone and lantern posts; the mill race; flower planters; Chime-Posts at the Forest Gate, both Hush-Crack trailheads, Dover-Slap-Bridge and the commons; the Great Arch fading with light-shafts; the trestle's piers and trusses; shingled turret spires; and the Ring's #8A8E91 flagstones, twelve standing stones, corner pines and heather. Colliders and positions are unchanged.
- **Checks.** `tools/test_world_visuals.gd` (run by the smoke test) checks the catalog, the atelier, the shaders, the crafted ground and clutter, low walls on LowScenery, ramps at 25° or less, sightline fades above 3.2 m, the 3 km cameras, the horizon ring, the HLODs, a crack sealed into a cairn (bloom, WorldStateDB, lanterns), weathering, the kit queue, the Ring's clear floor, and in Oakshire Vale each part's biome and look, every landmark, the cracks and the furrows. The Lens linter now reads every biome, kit and succession name.

**Deliberate differences from the spec**
- **Atlas zones follow the game, not §5.1's table.** The table ties Pippin-Green to Barley-Bridge-Meadow, Quarry-Wick to Barrow-Crag-Crossing and Nine-Stones-Crossing to Sunken-Crown-Falls. The game's atlas (15 §5, Pass 1) ties Pippin-Green to Tizzi-Wed-Green, Quarry-Wick to Barley-Bridge-Meadow (its Iron-Men couplet) and Nine-Stones-Crossing to Barrow-Crag-Crossing. Each petal wears §5.1's look under its in-game Sign: a Creative Director call.
- **No Furrow Iron-Men statues in Pippin-Green.** They are creatures, out of this phase's scope.
- **Terrain3D can't take separate splat weights**: its colour maps carry one colour. Both terrain modes read the craft from the painted colour and the slope, so they splat the same.
- **Colours are authored in sRGB and converted in the shaders.** Mode B ground, HLODs and clutter now match Terrain3D's (already converted) colours, which makes them a little deeper than before.
- **The atelier takes about 0.5 s on worker threads at 256 px, not 60 ms.** Nothing waits on it.
- **Kits build at runtime** from `WorldKitInstance` nodes, so the level files hold ids, not meshes (`landblock_0_1.tscn` went from 180 KB to 60 KB).
- **The streaming budget is the grid's 2 ms queue plus the kit queue's 1.5 ms slice.** No single step is promised under 2 ms; the checks assert the slicing.
- **No `--screenshot` flag.** Windowed probes captured Oakshire-Wick, Bramble-Bridge square, Moss-Oak-Hollow (hushed, blooming, reclaimed), Dover-Slap-Bridge, the Ring and the horizon for the squint audit.

**Still to come**
- Curated kit models and textures dropped into `assets/`, and per-zone weathering events wired to the calendar.
- The Gale-Jet's wind ribbons parting round a Shadow Sanctuary, and the Maker-Seal Plates' brass inlays (combat and actor visuals).
- Volumetric light-shafts, rainbow spray and butterflies.
