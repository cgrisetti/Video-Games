# **18\_NEXT\_GEN\_PASTORAL\_RENDERING\_WAYFINDING\_AND\_CAMERA\_GDD.md — Pushing Godot 4.7 Beyond Its Weight Class: Visual Polish, Living Blight, Path Blending, Y-Axis Camera, & Cartography**

**SYSTEM DIRECTIVE FOR GEMINI & CLAUDE CODE:** This document is the authoritative Stage 4 Multimodal Audit and Stage 1–3 Engineering Specification following visual inspection of the Phase 17 build screenshots. It diagnoses why the current world still reads as flat programmer art and prescribes concrete, industry-pushing rendering, shader, procedural-modeling, camera, and cartography architectures in Godot 4.7.2 to make *Everwood (Oakshire Raids)* look handmade, deeply atmospheric, and technically extraordinary—while preserving \$100\\%\$ compliance with our Five Mandatory Gates. *(Character, NPC, and monster model rigs remain isolated to the subsequent Character & Creature Upgrade Track.)*

## **1\. Stage 4 Multimodal Forensic Audit of Current Build Screenshots**

A forensic inspection of the five build screenshots reveals seven specific visual and technical bottlenecks preventing the world from achieving our Studio Ghibli / *Wind Waker* / *Tunic* / *Fable* target aesthetic:

| Screenshot Evidence | Visual & Technical Defect Diagnosed | Root Cause in Current GDScript / Shader Code | Mandatory Architectural Fix in This Upgrade |
| :---- | :---- | :---- | :---- |
| **Image 1 & 3** *(Honey-Wick & Oakshire Trail)* | **1\. Razor-Sharp "Ribbon" Path Edges:** Roads cut across the grass with hard, jagged polygon seams and zero height or foliage transition. | storybook\_terrain\_splat.gdshader uses a linear vertex-weight mix() across coarse terrain vertices with no heightmap modulation, curbing, or grass overhang. | **Height-Modulated Splat Lerp \+ Stone Curbing \+ Overhanging Verge Clutter** (§3.1). |
| **Image 1 & 3** *(Foreground & Horizon Trees)* | **2\. "Coat-Rack" & "Lollipop" Trees:** The tree behind P1 in Image 1 is a brown cylinder with four horizontal $9{0}^{\circ }$ peg sticks and detached green spheres; horizon trees in Image 3 are identical green balls on toothpicks. | ShapeKit builds trees from un-tapered cylinders at $9{0}^{\circ }$ angles and simple spheres without canopy normal transfer or subsurface backlight. | **Recursive Tapered Spline Trunks \+ Flared Roots \+ Subsurface Rim-Lit Leaf Clouds** (§4.1). |
| **Image 2 & 3** *(Oakshire-Wick & Meadows)* | **3\. "Green Pool-Table Felt" & Toothpick Grass:** The ground is a dead-flat, monochrome lime-green plane with tiny, sparse V-shaped ticks and random magenta blobs. | Terrain lacks micro-undulation and cloud-shadow projection; grass count/scale is too sparse and does not sample terrain color at its base. | **Terrain Base-Matched Wind-Wave Grass Carpet \+ Rolling Cloud Shadows \+ Contact AO Skirts** (§3.3, §4.2). |
| **Image 2 & 4** *(Market Stalls & Cairnsman Ring)* | **4\. Toy-Block Stalls & Box Monoliths:** Market stalls look like flat primary-colored plastic tables; standing stones in the boss arena are literal rectangular BoxMesh blocks with a green stripe painted at the bottom. | ShapeKit uses raw boxes for megaliths and market stalls instead of sculpted polyhedra and timber joinery. | **Voronoi-Cleaved Tapered Megaliths (make\_sculpted\_megalith) & Draped Linen Artisan Pavilions** (§4.3). |
| **Image 1–4** *(Camera Framing)* | **5\. Rigid Floor-Staring Camera & Unclear Slope Traversability:** The camera is locked at a steep downward angle with zero Y-axis pitch control, and players cannot tell what slopes are walkable vs. impassable walls. | Camera rig only rotates yaw (X-axis) with fixed pitch; terrain shader lacks slope-angle visual affordances. | **Full Y-Axis Camera Pitch ($-{8}^{\circ }$ to $+5{2}^{\circ }$) \+ Slope Traversability Shader & Stepping-Stone Terraces** (§3.2, §6). |
| **Image 3 & 4** *(World Atmosphere & Hush-Cracks)* | **6\. Washed-Out Fog & Invisible Boggart Blight:** Fog washes the horizon into flat grey-white, and **Hush-Cracks** (*The First-Quiet*) look no different from ordinary turf. | Missing sun-scattering aerial perspective, god-rays, and dramatic geometry/shader transformation inside Hush-Crack radii. | **Visceral "First-Quiet" Blight Zones (Ashen Hoar-Rime, Frozen Wind, Slate Shards, Weeping Roots) \+ Volumetric Sunbeams** (§5). |
| **Image 2 & 5** *(Split-Screen & Nameplates)* | **7\. Giant "ibe De" Label3D Bug & Overlapping Bot Tags:** In Image 5, 3D station text blows up to fill the entire left viewports ("ibe De", "Desk"); in Image 2, bot nameplates collide into unreadable soup (P2 LanWayfBear(bot)ot)). | Station Label3D nodes use un-clamped screen scaling or lack distance/menu culling; actor nameplates share identical vertical offsets. | **Distance-Clamped Diegetic Signboards \+ De-Collided Nameplate Stacking \+ Wayfarer's Compass Minimap & Atlas** (§6.3, §7). |

## **2\. Mandatory Five-Gate Verification (08\_EVERGREEN\_DEV\_BIBLE.md)**

| Gate ID & Pedigree | Mandatory Rule (08\_EVERGREEN\_DEV\_BIBLE.md) | Verification Audit for Phase 18 Visual, Camera, & Cartography Overhaul | Gate Verdict |
| :---- | :---- | :---- | :---- |
| **GATE 1** *Anti-Parasitic Harmony* | Must directly feed into at least two core pillars: Stamina/Poise, Four Signs, $3\times 3$ Callings, or Chimes/Vellum. | Feeds into all four pillars: (1) **The Four Signs** drive the **Parchment Atlas** & **Chime-Post** region crests (SIGN\_IRON\_ROOT, SIGN\_RIME\_GALE, SIGN\_WARM\_HEARTH, SIGN\_STAR\_TIDE); (2) **Stamina/Poise & Flow-Link** interact directly with **First-Quiet Blight Zones** (visualizing the $9-frame$ Dread-Chill vs. $18-frame$ **Lantern's Promise** golden aura radius); (3) **Chimes & Stewardship** drive live **Minimap Reclamation Blots** turning from slate-ash to emerald-gold as Hush-Cracks are sealed. | **PASS** |
| **GATE 2** *The Musk Razor* | Strip secondary menus and extra combat keybinds; execute through existing controller contracts. | Zero new combat buttons. Camera Y-axis pitch uses standard Right Stick Y / Mouse Y; the **Corner Compass-Rose Minimap** is passive and zero-clutter; the **Folding Vellum Atlas** lives inside the existing Grimoire Binder (Tab / View) plus an out-of-combat M shortcut. | **PASS** |
| **GATE 3** *Philological Linter & Single-Origin Antagonist Rule* | Pass the 4 Linter Rules & Single-Origin Antagonist Rule. | All map labels use canonical hyphenated Map-Sense compounds (Oakshire-Wick, Wayfarer-Green, Pippin-Green, Quarry-Wick, Bramble-Hollow, Nine-Stones-Crossing, Honey-Wick, Bramble-Bridge, Moss-Oak-Hollow, Rush-Light-Hollow, Dover-Slap-Bridge, Dover-Slap-Falls). Boggart blight expresses **The First-Quiet (*The Un-Making*)**—ashen stillness, hoar-rime, and slate fissures—never skulls or gore. | **PASS** |
| **GATE 4** *Schema-First Registry* | Content added as typed Resource data registered in central catalogs. | Adds WorldMapZoneResource and upgrades ZoneBiomeResource and ZoneSuccessionVisualResource inside WorldVisualCatalog with zero hardcoded match branches in ActorBase. | **PASS** |
| **GATE 5** *Code-First & Multi-Age Safe* | Deterministic GDScript build; $4.8m$ camera / $3.2m$ sightline safe; multi-age readable. | \$100\\%\$ code-built in ShapeKit, WorldVisualCatalog, PlayerCameraRig, and WayfarerMapHUD; camera pitch clamps above ground via SpringArm3D raycast and preserves upper-canopy dither-fade; minimap renders from a pre-baked topographic texture (0 extra runtime SubViewport draw calls in 4-player split-screen\!). | **PASS** |

## **3\. Path Edge Blending & Visual Traversability Contract (Walkable vs. Unwalkable)**

### **3.1 Killing the "Razor-Sharp Ribbon": Height-Modulated Splat Blending & Verge Curbing**

In Images 1 and 3, paths look like pasted brown ribbons because standard vertex-weight blending (mix(turf\_col, road\_col, weight)) interpolates linearly across large triangle edges. We replace this with a three-layer AAA terrain transition in storybook\_terrain\_splat.gdshader and tools/build\_\*.gd:  
> **Heightmap-Modulated World-Noise Splat Equation:** Instead of a linear lerp, storybook\_terrain\_splat.gdshader computes the stone-to-grass transition using the cobblestone height map ${h}_{stone}(u)$ and a 2-octave world-space Worley/Perlin edge-fray noise ${n}_{fray}({x}_{xz})$:

> $${w}_{road\_final}=smoothstep\left({0.42,0.58,{w}_{vertex}+\left({{h}_{stone}(u)-0.5}\right)\cdot 0.45+{n}_{fray}({x}_{xz})\cdot 0.28}\right)$$

> 1.   
>    *Visual Result:* At the edge of every road and courtyard, individual rounded flagstones and cobbles organically poke *out* into the grass while tufts of clover and turf creep *between* the outer stones—completely erasing straight polygon lines.  
> 2. **WornLoam Verge Ring & Micro-Depression:** Along the outer transition band (${w}_{vertex}\in [0.18,0.52]$), the shader blends a warm **Trodden Loam & Clover Verge** (\#4E5D38) with \$18\\%\$ ambient occlusion darkening, while the terrain mesh builder slightly depresses the center of footpaths by $-0.05m$ and crowns flagstone Bale-Ways by $+0.04m$ so paths have genuine physical camber in directional sunlight.  
> 3. **Intermittent Curb Stones & Overhanging Verge Foliage:**ChunkClutterBaker places intermittent, half-buried mossy limestone **Edge Curb-Stones** and dense clumps of overhanging fern, plantain, and white clover right along the ${w}_{vertex}\approx 0.45$ contour so the 3D silhouette of the road edge is just as organic as the shader blend.

### **3.2 Visual Traversability: Knowing Immediately What Can Be Walked/Climbed vs. Blocked**

Because *Everwood* has no jump button (Space / ✕ is Dodge Roll, and ActorBase walks smoothly up slopes $\leq 2{5}^{\circ }$ and snaps up to $5{0}^{\circ }$ max), players must never guess whether a hill, quarry terrace, or river bank is climbable:

| Terrain / Architectural Slope Class | Physical Angle & Collider Rule | Mandatory Visual & Shader Affordance ("Read-at-a-Glance" Contract) |
| :---- | :---- | :---- |
| **1\. Gentle Walkable Ramps & Trails** *(${0}^{\circ }to2{5}^{\circ }$)* | Walkable at \$100\\%\$ speed; floor\_snap\_length \= 0.35. | **Stewardship Stepping-Stones & Timber Sleepers:** Every climbable slope or hill path (Quarry-Wick terraces, Rush-Light-Hollow ramps, Dover-Slap approaches) is visually dressed with half-set timber railway-style log sleepers or flat limestone stepping-stones bordered by low wooden guide-posts (\<= 0.6m, LowScenery layer) and warm ochre-tan footpath splatting. |
| **2\. Steep Scree & Bank Transitions** *($2{6}^{\circ }to4{5}^{\circ }$)* | Traversable margin; slows movement if steeper than $4{5}^{\circ }$. | **Exposed Loam & Root-Ribbing:** storybook\_terrain\_splat.gdshader automatically blends in exposed brown earth, pebble scree, and gnarled root-ribs (NORMAL.y between 0.70 and 0.89), signaling a steep embankment. |
| **3\. Impassable Cliffs, Ledges, & Walls** *($>4{8}^{\circ }$ or Blocked Perimeter)* | Non-climbable (\> floor\_max\_angle or backed by StaticBody3D wall collider). | **Stratified Escarpment & Overhanging Moss-Lip:** Wherever NORMAL.y \< 0.68, the shader snaps via a crisp smoothstep to **Horizontal Sedimentary Crag Strata** (tex\_crag\_granite with dark horizontal fissure bands), a dark $0.8m$ basal contact-shadow toe at the cliff foot, and a protruding **3D Overhanging Turf/Rock Lip** (ShapeKit.make\_cliff\_cornice()) along the top crest. A child can tell from $60m$ away that an overhanging rock cornice cannot be walked up. |

## **4\. "How Did They Make Godot Do That\!?" — Next-Gen Storybook Asset & Shader Engineering**

### **4.1 Killing the "Coat-Rack Trees": Tapered Spline Trunks & Subsurface Ghibli Canopies**

In Image 1, the tree is an un-tapered cylinder with four $9{0}^{\circ }$ horizontal sticks. We overhaul ShapeKit's tree generators (kit\_tree\_moss\_oak, kit\_tree\_orchard\_apple, kit\_tree\_weeping\_willow, kit\_tree\_highland\_pine) using two techniques inspired by *The Witness* and Studio Ghibli:

> 1. **Continuous Tapered & Twisted Trunk \+ Root-Buttress Mesh (ShapeKit.make\_gnarled\_trunk\_mesh()):**  
   * Instead of separate cylinders, generate a single continuous ArrayMesh lofted along a 3D Bezier/Catmull-Rom spine from $y=-0.2m$ to $y=5.5m$.

At the base ($y\in [0.0,1.1m]$), modulate the trunk radius by a 5-lobed cosine wave:

$$r(y,\theta )={r}_{0}(y)\cdot \left({1.0+0.48\cdot (1.0-clamp(y/1.1,0.0,1.0){)}^{2}\cdot \max\limits_{}(0.0,\cos (5\theta +\phi ))}\right)$$

*   
  This produces **five organic, flared oak root-buttresses** gripping the earth with zero extra draw calls\!  
  * Primary boughs fork upward at natural botanical angles ($3{2}^{\circ }–4{8}^{\circ }$ upward pitch, never $9{0}^{\circ }$ coat-rack pegs\!) and taper smoothly into the leaf crown above our $3.2m$ combat sightline.  
> 2. **Subsurface-Lit Volumetric Leaf-Cloud Crown (storybook\_foliage\_wind.gdshader v2):**  
   * Each tree crown is composed of 11 to 18 overlapping, asymmetrically scaled **icosahedral leaf-cloud lobes** (with displaced ruffled silhouettes) arranged in a tiered dome, plus hanging willow/moss fronds.  
   * **Spherical Proxy Normals \+ BACKLIGHT Subsurface Scattering:** Vertex normals are overridden to point radially outward from the canopy center ($N=normalize({v}_{pos}-{c}_{crown})$), and Godot 4.7's BACKLIGHT shader output is driven by sun direction (vec3(0.45, 0.62, 0.18) warm golden-chartreuse transmission) alongside a 3-band painter's cel ramp (Sunlit Top Leaf \#78B84A $\rightarrow$ Mid Leaf \#488236 $\rightarrow$ Deep Canopy Shadow \#234B28 with sky-blue bounce).

### **4.2 Killing the "Green Pool-Table Felt": Terrain-Color-Matched Wind-Wave Grass Carpet**

In Images 1–3, tiny dark-green V-ticks stand out harshly against a flat lime-green floor. We implement the *Zelda: Breath of the Wild* / *Ghost of Tsushima* seamless meadow technique:

> 1. **Base-to-Tip Terrain Albedo Inheritance:** In storybook\_foliage\_wind.gdshader, grass blades do not use a single flat green color. The bottom \$40\\%\$ of every grass tuft samples the exact procedural terrain splat equation (turf\_albedo \+ cloud shadow \+ hush desaturation) at its world $XZ$ coordinate, blending upward into a sunlit golden-green tip (\#84BD52)\! Because the bottom of the grass matches the ground underneath it \$100\\%\$, the boundary between the 3D grass mesh and the terrain mesh completely disappears—making a 4,000-instance MultiMeshInstance3D look like a 500,000-blade continuous meadow carpet\!  
> 2. **World-Space Scrolling Wind-Wave & Gust Highlights:** storybook\_foliage\_wind.gdshader samples a scrolling dual-octave world-space wind wave (sin(world\_pos.x \* 0.18 \+ world\_pos.z \* 0.12 \- TIME \* 2.4)). When a wind crest passes over grass or tree canopies, the blades bend by up to $2{8}^{\circ }$ AND briefly catch a \$+14\\%\$ warm specular sheen—creating visible, sweeping waves of golden wind rolling across Oakshire Vale.  
> 3. **Hardware Distance Fade & Zero-Pop Clutter:** Set visibility\_range\_end \= 95.0 and visibility\_range\_fade\_mode \= GeometryInstance3D.VISIBILITY\_RANGE\_FADE\_SELF on chunk clutter MultiMeshInstance3D nodes, and replace the random bright-magenta blobs seen in Image 1 with grounded clusters of white meadow daisies, golden buttercups, fern fronds, and mossy river stones tucked naturally beside trees, walls, and path verges.

### **4.3 Killing the "Box Monoliths & Toy Stalls": Sculpted Megaliths, Timber Pavilions, & Contact AO Skirts**

> 1. **Voronoi-Cleaved Sculpted Megaliths (ShapeKit.make\_sculpted\_megalith()):**  
   * In Image 4, the standing stones around the Cairnsman are literal rectangular boxes. Replace them with a procedural rock/menhir sculptor that takes a subdivided prism/icosahedron, tapers its top by $0.55\times$, applies 6 deterministic Voronoi cleavage-plane cuts (dot(v, plane\_normal)), bevels the edges, and carves a glowing spiral **Maker-Seal** into the front face—with a mossy heather base mound (ShapeKit.make\_ground\_skirt()) wrapping the bottom.  
> 2. **Artisan Timber & Draped-Linen Market Pavilions (kit\_market\_pavilion):**  
   * In Image 2, the market stalls in Oakshire-Wick are boxy primary-colored tables. Upgrade them into medieval storybook craft pavilions: chamfered timber posts with diagonal knee-braces, scalloped canvas/linen awnings with sagging catenary cloth curves in warm heritage dyes (Saffron-Ochre, Madder-Terracotta, Woad-Azure, Sage-Green—never neon primaries), wooden counter barrels, hanging herb bundles, woven baskets, and a **Cobblestone Plaza Apron** underneath the entire market ring so stalls sit on a bustling village square instead of raw grass.  
> 3. **Universal Ground Contact AO & Moss Skirts (ShapeKit.make\_ground\_contact\_skirt()):**  
   * Every building (kit\_house\_stepped\_gable), wall (LowScenery), shrine, and market stall automatically generates a slightly flared $0.45m$ basal foundation collar with vertex-baked ambient occlusion and small perimeter bush/fern clusters so structures look deeply rooted into the earth.

### **4.4 Rolling Cloud Shadows, Sun-Scattering Height Fog, & Canopy God-Rays (WorldAtmosphereDirector)**

To make players ask *"How did they make Godot do that\!?"*:

> 1. **World-Space Rolling Cloud Shadows:** Both storybook\_terrain\_splat.gdshader and storybook\_world\_triplanar.gdshader evaluate a shared, slowly drifting world-space cloud-cover function $C({x}_{xz}+{v}_{wind}\cdot t)$ that softly attenuates direct sunlight by \$22\\%\$ in broad $35m$ organic patches moving across the valley. Watching giant dappled cloud shadows drift over the hills and rooftops of Oakshire Vale and Bramble-Bridge instantly gives the world cinematic scale and life.  
> 2. **Warm Sun-Scattering Aerial Perspective & Height Fog:** Replace the flat grey-white fog in Images 3 and 4 with Godot 4.7's fog\_aerial\_perspective \= 0.65, fog\_sun\_scatter \= 0.38, and height-layered fog (fog\_height \= 2.5, fog\_height\_density \= 0.12) tinted warm golden-amber toward the sun and cool cerulean-violet in the distant mountain shadows.

## **5\. Making *The First-Quiet* Visceral: Living Boggart Blight vs. Sunlit Stewardship**

In the current build, areas where Boggart-Kin and **Hush-Cracks** slumber look almost identical to safe meadows. To fulfill our **Triumvirate Lens** (Le Guin, Cooper, Miyazaki), stepping near an un-sealed **Hush-Crack** must feel like walking into an eerie, hushed pocket where **The First-Quiet (*The Un-Making*)** is actively drinking the color, wind, and warmth out of the world:

| Blight Layer | Visual & Technical Execution Inside ZONE\_HUSHED (22.0 m22.0\\text{ m}22.0 m Radius) | Visual Transformation Upon ZONE\_RECLAIMED (When Un-Boggarted) |
| :---- | :---- | :---- |
| **1\. Ground & Foliage Color Drain** | storybook\_terrain\_splat.gdshader and storybook\_foliage\_wind.gdshader drain \$85\\%\$ of warm saturation inside hush\_cracks\[i\].w ($22.0m$), shifting turf and leaves into **Ashen Slate-Indigo** (\#48505E) rimmed by pale crystalline **Hoar-Rime** frost veins. | A $2.5s$ radial golden-emerald **Reclamation Wave** sweeps across the ground and trees, restoring lush sunlit green and bursting $40+$ wildflowers into bloom around the cairn. |
| **2\. "The Frozen Wind" (Stillness of the Quiet)** | Inside the blight radius, the grass and tree wind-wave shader multiplies wind\_strength by 0.05 and bends grass blades *downward and outward* as if pressed flat by heavy, silent air. | The wind-wave immediately rushes back through the meadow in a celebratory ripple of swaying grass and dancing leaves. |
| **3\. 3D Fissure Geometry & Weeping Hush-Roots** | kit\_hush\_crack\_and\_cairn spawns **7 to 11 jagged, leaning Slate-Shard Monoliths** and twisted, pale-grey **Weeping Root-Tendrils** erupting from a dark sunken earth trench (-0.35m visual pit) that pulses with cold slate-violet rings and rising reverse-gravity ash motes. | The jagged slate shards and pale root-tendrils sink and dissolve into a peaceful, rounded **Stewardship Cairn** (STATE\_LULLED\_CAIRN) covered in plush green moss, purple heather, and a warm Saffron-Gold **Way-Lantern**. |
| **4\. The Lantern's Promise Safe-Halo ($5.5m$)** | When a **Lantern-Bearer** (Bell-Keeper, Wind-Mender, Lantern-Scribe) or a hero holding a **Hearth-Rite Tuck** walks into a blighted zone, their 5.5m **Lantern's Promise** radius dynamically pushes back the shader desaturation around their boots in real time—creating a literal moving pool of warm Saffron-Gold colour inside the grey hush\! | Reinforces the $18-frame$ Flow-Link window (02\_COMBAT\_GDD.md §5) visually so even a 4-year-old child instinctively stays inside the warm golden light of the Lantern-Bearer\! |

## **6\. Full Y-Axis Camera Pitch Control & Diegetic Text De-Cluttering**

### **6.1 Player-Controlled Y-Axis Camera Pitch (src/levels/level\_base.gd & SplitScreenViewportGrid)**

Right now, players are forced to stare down at the ground at a fixed angle. We upgrade the per-player camera rig in LevelBase / ActorBase with smooth, responsive **Y-Axis Pitch Control** alongside X-Axis Yaw:

> 1. **Multi-Device Pitch Input Mapping (build\_input\_map.gd & InputComponent):**  
   * **Gamepad:** Right Stick Vertical (JOY\_AXIS\_RIGHT\_Y, deadzone 0.15, sensitivity 1.8 rad/s, with an optional invert-Y toggle).  
   * **Mouse \+ Keyboard:** Moving Mouse Y (InputEventMouseMotion.relative.y \* 0.0035) while holding Right-Click (or when mouse-look mode is toggled via V), PLUS dedicated keyboard pitch keys (PageUp / PageDown or \[ / \]) so keyboard-only split-screen players also have full pitch control.  
> 2. **Pitch Envelope & Dynamic Boom Interpolation (Preserving the $4.8m$ Contract):**  
   * **Pitch Range:** Clamped smoothly between ${\theta }_{pitch}\in [-1{2}^{\circ }(LookUpatSky/Vista),+5{2}^{\circ }(TacticalHighRaidOverview)]$, defaulting on spawn to a balanced $+2{2}^{\circ }$ **Pastoral Horizon Angle** (down from the steep $\sim 3{8}^{\circ }$ floor-stare in Images 1–3 so the horizon, buildings, and sky are naturally visible\!).  
   * **Dynamic Pivot & Boom Curve:**  
     * At the default $+2{2}^{\circ }$ to $+5{2}^{\circ }$ overhead angles, the camera maintains our canonical raid eye-line (up to $4.8m$ height, $6.8m$ boom distance) so all 4 RaidTelegraphDecal rings are crystal clear.  
     * As the player pulls the camera down toward $-1{2}^{\circ }$ to look *up* at **Dover-Slap-Falls**, the **Moss-Oak Great Arch**, or distant mountain tors, the camera pivot interpolates down to over-the-shoulder height ($1.65m$) with a $3.6m$ boom distance and a **Terrain Floor Collision Clamp** (max(camera\_y, terrain\_height\_at\_cam \+ 0.45)) so the camera never clips beneath the ground.

### **6.2 Fixing the Giant "ibe De" Label3D Bug & Overlapping Bot Nameplates (Images 2 & 5\)**

> 1. **Eliminating the Split-Screen Label3D Explosion (Image 5):**  
   * In Image 5 (Top-Left and Bottom-Left viewports), the 3D station labels for "The Reed-Light Scribery" and "Scribe Desk" scale up to fill the entire viewport when a camera passes near them or opens the UI.  
   * **Mandatory Fix:** Audit every Label3D in src/ and tools/ (scribery, scribe\_desk, chime\_shrine, water\_shrine, raid\_portal, coop\_gate, banners). Set fixed\_size \= false, pixel\_size \= 0.0042, font\_size \= 32, outline\_size \= 8, visibility\_range\_begin \= 1.8, visibility\_range\_fade\_mode \= GeometryInstance3D.VISIBILITY\_RANGE\_FADE\_SELF, visibility\_range\_end \= 24.0, and automatically hide world Label3D prompts for any player viewport currently displaying an open modal panel (GrimoireBinderPanel, ScriberyShopPanel).  
> 2. **De-Colliding Player & Companion Nameplates (Image 2):**  
   * In Image 2, P2 and P3 bot labels render at the exact same height and overlap into "P2 LanWayfBear(bot)ot)".  
   * **Mandatory Fix:** Compact companion tags to clean, short badges ("P2 · Bell-Keeper" instead of verbose (bot) strings), stagger vertical Label3D Y-offsets slightly by seat index (y \= 2.25 \+ (seat\_idx % 3\) \* 0.22 when within $3.0m$ of another actor), and fade companion nameplates to \$35\\%\$ opacity when out of combat and within $4.0m$ of the leader.

## **7\. Wayfinding Architecture: The Wayfarer's Compass-Rose Minimap & Folding Vellum Atlas**

To solve requirement \#1 (*"Generate the plan for a map and minimap feature so I know where I actually am. Keep my architectural requirements intact"*), we introduce a zero-allocation, storybook-authentic cartography system that costs $0.0ms$ **of extra 3D scene rendering** across 4 split-screen viewports:

Plaintext  
  ╭─── TOP-RIGHT OF EACH PLAYER VIEWPORT ───╮      ╭────────── FOLDING VELLUM ATLAS (Tab / M) ──────────╮  
  │            ▲ N · Nine-Stones            │      │   OAKSHIRE VALE · TIZZI-WED-GREEN (SIGN OF WOOD)   │  
  │         ╭───────────────────╮           │      │  ┌──────────────────────────────────────────────┐  │  
  │         │   ░░  \[Nine\]      │           │      │  │          \[✦ Nine-Stones-Crossing\]            │  │  
  │         │  \[Bramble\]   \[Pip\]│           │      │  │   \[Bramble-Hollow\]         \[Pippin-Green\]    │  │  
  │      W ◄│     (P2) ❖ (P1➤)  │► E        │      │  │       (● Hush-Crack)         (❖ Restored)    │  │  
  │         │  \[Quarry\]  ═══    │           │      │  │             ★ OAKSHIRE-WICK (P1,P2,P3)       │  │  
  │         │       \[Wayfarer\]  │           │      │  │   \[Quarry-Wick\]                              │  │  
  │         ╰───────────────────╯           │      │  │            \[Wayfarer-Green ──► Trail\]        │  │  
  │         Oakshire-Wick · (0, 0\)          │      │  └──────────────────────────────────────────────┘  │  
  │         Hush-Cracks: 2/6 Calmed         │      │  \[Click/Press A on any Landmark to Set Way-Light\]  │  
  ╰─────────────────────────────────────────╯      ╰────────────────────────────────────────────────────╯

### **7.1 Zero-Overhead Pre-Baked Topographic Parchment Map (src/ui/cartography\_baker.gd)**

* **Why We Reject SubViewport Overhead Cameras (Gate 5 Efficiency):** Adding 4 overhead Camera3D \+ SubViewport instances for a 4-player split-screen minimap would multiply vertex/draw calls by $2\times$ and break our $60Hz$ frame budget.  
* **The Deterministic Cartography Baker Solution:** On level load (OakshireVale, EverwoodWorld, HubTown, DungeonDojo), CartographyBaker samples the level's mathematical heightfield, road splines, water masks, and building/shrine registries once to bake a crisp $512\times 512$ **Hand-Inked Parchment Topographic Texture** (ImageTexture):  
  * Parchment vellum background (\#EFE6D2) with subtle elevation contour rings every $2.0m$ of height (\#C9B898).  
  * Flagged Bale-Ways & bridges drawn in warm sepia-ochre (\#9E7B56) with dashed trail lines.  
  * Streams, canals, willow pools, and waterfalls drawn in Sea-Azure watercolor ink (\#4A9BB8).  
  * Stepped-gable buildings, watermills, and standing stones stamped as crisp architectural plan footprints (\#6E473B).

### **7.2 The Corner Compass-Rose Minimap (src/ui/wayfarer\_minimap\_widget.gd)**

Mounted in the **top-right corner** of each player's PlayerHUD cell ($124\times 124px$ in 1–2 player mode, scaling automatically to $92\times 92px$ in 3–4 player split-screen so it never crowds the viewport):

> 1. **Scrolling UV Window \+ Brass Astrolabe Frame:** Uses a custom Control \_draw() / shader pass that scrolls and rotates a $160m\times 160m$ local window of the pre-baked parchment texture around the player's live world $(X,Z)$ position, framed by an octagonal brass **Chime-Ring** with Cardinal (N, E, S, W) and Camera-Cone indicators.  
> 2. **Live Ecological Succession & Party Telemetry:**  
   * **Player & Party Pips:** Renders the local hero at the center with a directional facing arrow and all teammates/companions (P1–P5) as color-coded Fellowship gems (clamped to the brass rim as directional arrows if a sibling wanders $>80m$ away—so you always know which way to run to regroup\!).  
   * **Hush-Crack vs. Reclaimed Cairn Icons:** Un-sealed **Hush-Cracks** pulse as dark **Slate-Ink Blots** (ZONE\_HUSHED); the instant a camp is un-boggarted, the blot transforms into a glowing **Saffron-Gold Cairn Star** (ZONE\_RECLAIMED).  
   * **Place-Name & Chunk Banner:** Directly beneath the compass ring, a clean 1-line ribbon displays the player's exact current sub-zone (e.g., "Oakshire-Wick · (0, 0)" or "Dover-Slap-Bridge · Zone 2") and active Hush-Crack stewardship count.

### **7.3 The Folding Vellum Atlas & Golden Firefly Way-Light (src/ui/cartography\_atlas\_panel.gd)**

> 1. **Musk Razor Access (Zero Combat Clutter):**  
   * Pressing M (keyboard) or switching to the new **"Atlas Map"** tab inside the existing **Grimoire Binder (Tab / View)** unfolds the full-zone **Vellum Stewardship Atlas**.  
   * Displays the entire active world (Oakshire Vale's central hub \+ 5 threshold petals, or the entire 5-chunk Bramble-Bridge to Ring of the Cairnsman expedition corridor) with hand-lettered callouts for every Map-Sense sub-zone, its Cooper Sign, **Chime-Posts**, **Water-Shrines**, **Scribe Desk**, and **Raid Portals**.  
> 2. **Diegetic Firefly Way-Light Trail (Miyazaki Wayfinding):**  
   * Selecting any landmark or zone petal on the Atlas (or cycling landmarks with D-Pad Left/Right while the Atlas is open) pins a **Wayfarer's Beacon**.  
   * Rather than painting an ugly neon GPS arrow on the HUD, pinning a beacon spawns a gentle, floating ribbon of **Saffron-Gold Firefly Motes** (WayfarerTrailGuideFX) that drifts $0.8m$ above the nearest road spline toward the destination—guiding young children and adults alike through the world with pure storybook magic\!

## **8\. Schema-First GDScript Specifications & Headless CI Verification Gates**

### **8.1 WorldMapZoneResource (src/resources/world\_map\_zone\_resource.gd)**

GDScript  
class\_name WorldMapZoneResource  
extends Resource

@export var zone\_id: StringName \= &"oakshire\_wick"  
@export var display\_name: String \= "Oakshire-Wick"  
@export var cooper\_sign\_title: String \= "Sign of Wood"  
@export var primary\_scribe\_sign: int \= 2 \#\# SIGN\_WARM\_HEARTH  
@export var world\_center\_xz: Vector2 \= Vector2(0.0, 0.0)  
@export var world\_radius\_m: float \= 140.0  
@export var landmark\_label\_offset: Vector2 \= Vector2(0.0, \-18.0)  
@export var connects\_to\_zone\_ids: PackedStringArray \= PackedStringArray(\[  
	"wayfarer\_green", "pippin\_green", "quarry\_wick", "bramble\_hollow", "nine\_stones\_crossing"  
\])

### **8.2 Camera Pitch \&Traversability Tuning Constants (PlayerCameraRig / LevelBase)**

GDScript  
const CAM\_DEFAULT\_PITCH\_DEG: float \= 22.0   \#\# Restores horizon & sky visibility (was \~38 deg)  
const CAM\_MIN\_PITCH\_DEG: float \= \-12.0      \#\# Look up at waterfalls, arches, and vistas  
const CAM\_MAX\_PITCH\_DEG: float \= 52.0       \#\# High tactical raid overview  
const CAM\_PITCH\_SPEED\_RAD: float \= 1.85  
const CAM\_DEFAULT\_HEIGHT\_M: float \= 4.8     \#\# Canonical raid eye-line at \+22..+52 deg  
const CAM\_LOW\_PIVOT\_HEIGHT\_M: float \= 1.65  \#\# Shoulder pivot when pitching \< \+10 deg to look up

### **8.3 Automated Headless CI & Visual Verification Gates (tools/smoke\_test.gd)**

> 1. **Static Parse & Type Verification (--check-only):**  
   * Verify cartography\_baker.gd, wayfarer\_minimap\_widget.gd, cartography\_atlas\_panel.gd, world\_visual\_catalog.gd, shape\_kit.gd, and all updated level/camera scripts pass godot \--headless \--path . \--check-only \-s \<script\> with zero warnings or errors.  
> 2. **Cartography & Minimap Smoke Assertions:**  
   * Assert that CartographyBaker.bake\_level\_map(level) produces a valid $512\times 512$ ImageTexture with non-uniform road, water, and contour pixels in $<25ms$ and spawns zero extra SubViewport nodes.  
   * Assert that every PlayerHUD mounts a visible WayfarerMinimapWidget and that toggling CartographyAtlasPanel displays all canonical Map-Sense zone landmarks and spawns the WayfarerTrailGuideFX firefly guide when a landmark is pinned.  
> 3. **Camera Y-Axis Pitch & Label3D Regression Gate:**  
   * Simulate feeding negative and positive pitch deltas into the camera rig; assert that camera pitch interpolates smoothly across $[-1{2}^{\circ },+5{2}^{\circ }]$, clamps properly, and never clips below terrain\_height \+ 0.4m.  
   * Assert that \$100\\%\$ of Label3D nodes in hub\_town, dungeon\_dojo, everwood\_world, and oakshire\_vale have fixed\_size \== false, visibility\_range\_end \<= 30.0, and automatically hide when GrimoireBinderPanel or ScriberyShopPanel is open.  
> 4. **Path Blending, Sculpted Megaliths, & First-Quiet Blight Assertions:**  
   * Assert that storybook\_terrain\_splat.gdshader compiles and binds height-modulated edge blending, slope cliff strata (NORMAL.y \< 0.68), cloud shadows, and the $22.0m$ hush\_cracks blight radius (with Lantern's Promise $5.5m$ safe-halo pushback).  
   * Assert that standing stones use ShapeKit.make\_sculpted\_megalith() (ArrayMesh vertex count $>24$, zero raw BoxMesh monoliths) and trees use tapered multi-segment spline trunks (make\_gnarled\_trunk\_mesh()).

## 9. Build Notes (Phase 18)

What's built, by stage, and where it differs from the text above on purpose.

### 9.1 What's built

1. **Map zones.** `WorldMapZoneResource` (§8.1). `WorldVisualCatalog` registers Oakshire-Wick and its five petals, the Bramble-Bridge trail's six stops, and the hub's and the expedition's places (`map_zone()`, `map_zones(instance)`, `map_zone_at()`). The blight's reach is 22 m (`ZoneBiomeResource.DEFAULT_HUSH_RADIUS_M`), its palette in `ZoneSuccessionVisualResource`.
2. **Path blending and the slope contract.** `storybook_ground()` (the shared include) blends roads by height and noise, `smoothstep(0.42, 0.58, w + (h_stone - 0.5) * 0.45 + n_fray * 0.28)`, with the #4E5D38 trodden verge (w 0.18 to 0.52, 18% AO); walkable banks (n.y 0.70 to 0.89) get scree, loam and root ribs; cliffs (n.y below 0.68) get strata and a 0.8 m dark toe. Oakshire's flagged Bale-Ways are crowned +4 cm and its footpaths and the corridor's trail and lane troughed -5 cm. `ChunkClutterBaker` lays half-buried curb-stones and fern, plantain and clover verges along every road edge, and Crag-Crest Cornices along the cliff ring's crest and the corridor's ridges. Log sleepers and guide-posts dress Rush-Light-Hollow's ramps, the Quarry-Wick road's two terrace climbs and Nine-Stones' causeway; stepping-stones and guide-posts line the corridor's climbing trails.
3. **Assets.** `ShapeKit` generates gnarled trunks (five root-buttresses, boughs at 32 to 48 degrees above 3.2 m), leaf-cloud crowns (11 to 18 lobes, outward normals), lush grass tufts (7 to 9 blades), Voronoi-cleaved megaliths (top tapered to 0.55x), slate shards, cornices and contact skirts. The four tree kits, the standing stones (the Ring's pillars and outer stones, Nine-Stones), the cracks and cairns use them; houses, the Scribe-Desk pavilion, the pagoda, the water-shrine and the dry-stone walls stand on skirts. The foliage shader bends grass up to 28 degrees in the rolling wind-wave with a 14% gust sheen, roots it in the ground's colour (instance colour, bottom 40%) and ripens it to #84BD52; crowns wear the three-band leaf ramp and the BACKLIGHT vec3(0.45, 0.62, 0.18). Grass grows 2,500 to 3,600 tufts a landblock in a window, 600 headless, shrinking away by 95 m. Blooms grow in grounded clusters (daisies, buttercups, ferns, a mossy stone), never neon magenta. `kit_market_pavilion` replaces Oakshire-Wick's fourteen stalls, on a cobbled plaza apron out to 31.5 m.
4. **The blight.** An open crack is a dark trench, 7 to 11 slate shards at 15 to 32 degrees, six weeping root-tendrils, a breathing slate-violet ring (`hush_ring_pulse.gdshader`) and ash falling upward; for 22 m the colour drains 85% to #48505E under a 2.5 m hoar-rime rim, the wind freezes (x0.05) and grass lies pressed to 55%. Sealing it sinks the shards 2.1 m as the cairn rises with its Saffron-Gold Way-Lantern and 42 wildflowers over the 2.5 s bloom. The director lights a 5.5 m Lantern's Promise halo round every Lantern-Bearer and Hearth-Rite holder (four slots), rolls 22% cloud shadows about 35 m across over the terrain, Terrain3D and triplanar shaders, and sets the fog (aerial perspective 0.65, sun scatter 0.38, height 2.5 m, density 0.12).
5. **Camera and labels.** `cam_pitch_up` / `cam_pitch_down` (right stick Y, deadzone 0.15, 1.85 rad/s; PageUp / [ and PageDown / ]), mouse Y x0.0035 while the right button is held or mouse-look is on (`cam_mouse_look`, V). `PlayerCamera` holds -12 to +52 degrees, starts at +22 with its eye at 4.8 m on a 6.8 m boom, drops to a 1.65 m pivot on a 3.6 m boom below +18, and stays 0.45 m above the ground. `LevelBase.set_camera_pitch_degrees(seat_id, deg)` / `get_camera_pitch_degrees(seat_id)`. `WorldLabelStyle` styles every Label3D (fixed_size off, 0.0042 m a pixel, 32 px, outline 8, 1.8 to 24 m, FADE_SELF); world signs sit on visual layer 12, which a camera drops while its player has a modal open. Nameplates read "P2 · Bell-Keeper", stagger 0.22 m by seat when heroes crowd within 3 m, and companions' fade to 35% within 4 m of the leader out of combat.
6. **Cartography.** `CartographyBaker.bake_level_map(level)` paints a 512 px (256 headless) parchment map in code: 2 m contours, roads, water and building footprints, no SubViewports. `WayfarerMinimapWidget` sits top-right of each HUD (124 px for one or two players, 92 px for three or four), a 160 m window in an octagonal brass Chime-Ring with N/E/S/W and the camera's wedge, P1 to P5 gems (held to the rim past 80 m), crack blots and cairn stars, shrine, desk and portal glyphs, and its ribbon ("Oakshire-Wick · (Chunk 6, 6)", "Hush-Cracks: 3/10 Calmed"). `CartographyAtlasPanel` (a tap of M / R3, or the Binder's Atlas Map tab) shows the whole map with banner callouts, the party, every crack and the glyphs; a pin starts `WayfarerTrailGuideFX`, a firefly ribbon 0.8 m over the ground.
7. **Verification.** Check-only on every script, the rebakes (the Input Map, `build_levels.gd`, `build_oakshire_vale.gd`), and `tools/test_pastoral_cartography.gd` in all four instances (565 smoke checks in all).

### 9.2 Deliberate differences

- **The right mouse button is still Heavy.** Holding it pitches the camera with the mouse, as §6.1 says, but its press still swings a Heavy (combat bindings are out of this phase's scope). Mouse-look (V, or the old click-to-capture) pitches without attacking.
- **M's tap opens the Atlas, its hold still changes assist mode**, the way Tab's tap opens the Binder and its hold changes Fellowship.
- **Pinning on a pad is light (X), not A.** A is the game's menu "back" everywhere else; Enter and a click pin too.
- **Text is smaller.** 32 px at 0.0042 m a pixel is 13 cm tall, against the old plates' 24 cm, as specified; it reads at the 1.8 to 24 m it now shows at.
- **The clutter's 95 m fade is per plant.** Godot measures a visibility range to a batch's middle and a batch spans its 128 m landblock, so the shader shrinks each tuft away by 95 m and the batch's own range (FADE_SELF) reaches 95 m plus half the landblock's diagonal.
- **Bramble-Bridge had no stalls,** so it gained a market row of three pavilions on the spawn green's east side; Oakshire's vendors keep their clothing colours.
- **The terraces' risers are cliffs; the road is the climb.** Quarry-Wick's sleepers and guide-posts sit where its road crosses the two risers. The corridor's guide-posts are clutter (no colliders): its dry-stone trail walls are the physical border. The Holloway's guide-posts are LowScenery colliders.
- **Cornices are a clutter batch** (`mm_cliff_cornices`) placed by each layout's `crest_pieces()`, not one node per piece.
- **The map's buildings and cracks come from the builders.** `cartography.json` beside each world's landblocks lists them, since most landblocks aren't loaded; walled instances read their colliders by rays. A crack's state is the director's (this session) or `WorldStateDB`'s (a cleared camp), otherwise open.
- **The leaf ramp keeps each kit's greens:** it applies the three bands as each band's shift from #78B84A, so apple, willow and pine crowns don't all turn one green.
- **Pitch speed is 1.85 rad/s** (the brief), not §6.1's 1.8. Invert-Y exists (`InputComponent.invert_pitch`) with no menu toggle yet.
- **The expedition's map zones** were placed on its geometry: the Moss-Oaks at z 52 (40 m), the gorge at z -5, the Ring round the boss at z -52.
- **The hub's ribbon shows local chunk numbers.** The walled instances aren't streamed, so their "chunk" is just where the hero stands on the 128 m grid.
