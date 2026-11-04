# **19B\_HERO\_MATERIAL\_FIDELITY\_FACIAL\_SCULPT\_AND\_GAIT\_POLISH.md — Stage 4 Polish Specification & Claude Code Directive**

### **1\. Stage 4 Technical Art & Animation Diagnosis**

#### **Pillar 1: Physically-Plausible Storybook Micro-Surfaces (storybook\_hero\_atelier.gdshader)**

Right now, the hero's materials read as smooth, uniform cel-shaded surfaces because the micro-normal perturbations and roughness/specular curves in storybook\_hero\_atelier.gdshader are too subtle at the $4.8m$ camera distance. To make materials pop as tactile, touchable craft without adding heavy external texture dependencies or breaking the **60-30-10 Three-Value Harmony** (docs/19\_HERO\_CHARACTER\_ART\_AND\_ANIMATION\_RIG\_GDD.md):

* **Woven Felted Wool & Linen (COLOR.b \< 0.3):**  
  * **Herringbone / Twill Normal Weave:** Generate a high-frequency procedural chevron/twill weave in UV space ($u\cdot 96.0\pm v\cdot 96.0$) that perturbs NORMAL by 0.28 strength so the weave catches directional sunlight along the mantle folds.  
  * **Oren-Nayar / Sheen Fuzz Rim:** Real wool and heavy linen have microscopic surface fibers that scatter light at grazing angles. Add a soft fabric-fuzz rim (pow(1.0 \- NdotV, 2.2) \* 0.22) tinted warm cream/moss along the cloth terminator so the **Hedgerow Wool-Mantle** looks thick, warm, and woven.  
* **Striated Adze-Hewn Timber (0.3 \<= COLOR.b \< 0.42):**  
  * **Anisotropic Wood-Grain & Growth Rings:** Sample elongated 1D/3D Perlin fibers stretched $14:1$ along the weapon haft and pauldron axis (uv.y \* 6.0, uv.x \* 84.0) layered with concentric growth-ring bands and carved adze flat-planes (floor(noise \* 6.0) / 6.0), driving both a \$\\pm 12\\%\$ warm ochre-to-umber value striation and a crisp normal-map groove.  
* **Supple Worn & Burnished Leather (0.42 \<= COLOR.b \< 0.5):**  
  * **Pebbled Grain \+ Crease Cavity \+ Burnished Edge Specular:** Real oiled leather is matte in its recessed creases (roughness \= 0.78) but burnishes to a warm, waxy sheen (roughness \= 0.28, specular \= 0.65) along high-wear edges (boot toes, belt rims, brigandine straps, gauntlet knuckles). Use the vertex curvature mask (COLOR.g) to drive this dual-roughness response and stamp dashed saddle-stitching normal indentations (0.015m spacing) along the borders.  
* **Hand-Hammered Forged Metal (0.5 \<= COLOR.b \< 0.7):**  
  * **Planished Hammer-Facets:** Instead of smooth cylinder normals that look like chrome plastic, quantize the metal surface normal using small Voronoi cells ($35cells/m$) by 0.16 rad so iron and steel catch the sun in crisp, hand-forged hammer facets.  
  * **Split Anisotropic Horizon-Sky Reflection \+ Cavity Patina:** Combine a sharp primary specular lobe (smoothstep(0.86, 0.92, RdotL)) with a secondary sky-horizon MatCap band, while darkening recessed rivet and ring-mail cavities (COLOR.r \< 0.65) with gunmetal forge-soot patina (\#2B3036).

#### **Pillar 2: Killing the "Lara Croft" Run — Jaunty, Athletic Woodsman Stride (HeroCombatAnimator)**

A classic "Tomb Raider" run happens when Hips stay on a flat horizontal rail with zero lateral weight transfer, the knees stay high and narrow toward the centerline, and the elbows pump rigidly straight forward-and-back. To give the **Iron-Woodsman** a grounded, jaunty, tactical woodsman's lope (inspired by *Fable*, *Monster Hunter*, and *Wind Waker*):

1. **Asymmetric Double-Bounce Pelvis Curve (Hips.position.y & .x):**  
   * Replace simple sine-wave vertical bobbing with a two-stage **Contact Squash $\rightarrow$ Push-Off Loft** curve: at foot-plant (f \= 4 and f \= 18), Hips.y drops by \-0.045m over 3 frames to absorb the heavy boot impact, then springs upward to \+0.055m with a 2 frames hang-time peak at mid-stride (f \= 11 and f \= 25), accompanied by a ±0.035m lateral hip shift (Hips.x) over the planted boot and ±6.5° pelvic roll (Hips.rotation.z).  
2. **Tactical Diagonal Low-Port Weapon Carry (Asymmetric Arms):**  
   * Instead of pumping both arms symmetrically like a track sprinter, the right arm (UpperArm\_R, Forearm\_R) carries the **Broad-Axe** or **Falchion** in an athletic **30° diagonal trail-ready port** across the lower hip/ribs, while the left pauldron (Clavicle\_L, UpperArm\_L) leads slightly forward (18° counter-torsion twist between Hips and Chest) like an experienced trailblazer pushing through brush.  
3. **Snappy Heel-Strike & Toe-Whip Footwork:**  
   * Widen the stride stance by \+0.04m per foot (killing the narrow tightrope walk), pitch Foot\_L/Foot\_R up \+24° on heel-strike, and hold the back foot's toe-push for an extra 2 frames before whipping the knee forward.

#### **Pillar 3: Expressive Storybook Human Facial Topology & Living Skin Zones (HeroMeshAtelier)**

To replace the simplified geometric head block with an unmistakable, warm, human face that still fits our handcrafted atelier style:

1. **True Anatomical Facial Planes (mesh\_head\_heritage):**  
   * **Supraorbital Brow Ridge & Eye Sockets:** Sculpt a distinct overhanging brow bone (z \= \+0.145m, y \= 1.56m) that recesses \-0.022m into shadowed orbital sockets before rising into the upper eyelids.  
   * **Bridge-and-Bulb Nose \+ Zygomatic Cheekbones:** Loft a three-plane nasal bridge and warm bulbous tip (z \= \+0.172m, width \= 0.042m) flanked by pronounced zygomatic cheekbone planes that catch a crisp cel highlight beneath the eyes.  
   * **Layered Eyes with Corneal Specular Catchlight:** Construct eyes from a warm ivory sclera shell, a recessed iris disc (deep hazel-amber \#5E4728), a dark pupil core, upper/lower dark eyelash creases, and a dedicated shader **Corneal Catchlight Spark** (smoothstep(0.94, 0.98, dot(view\_reflect, sun\_dir))) so the eyes always gleam with life.  
   * **Articulated Brow-Banderoles & Layered Beard Mustache Locks:** Separate the mustache into two swept handlebar/hearth-locks framing the mouth above the multi-lobed chin beard (\#4A3222 bark-brown with 28% \#B8C0C8 light ash-gray speckles).  
2. **Tri-Zone Facial Chromaticity & Sub-Dermal Skin Shader (COLOR.b \>= 0.7):**  
   * Apply traditional portrait-painter **Facial Color Zones** inside storybook\_hero\_atelier.gdshader:  
     * **Forehead / Upper Brow Zone:** Warm golden-ochre undertone (\+6% yellow-warmth).  
     * **Mid-Face / Nose & Cheek Malar Zone:** Ruddy, wind-kissed carmine-rose flush (\#D97964 blended at 32% across the nose bridge, cheeks, and ears).  
     * **Lower Jaw / Periorbital Zone:** Subtle cool-olive shadow undertone (\#9E8272).  
   * Add a soft **Sub-Dermal Terminator Band** (smoothstep(-0.15, 0.18, NdotL) tinted \#E26D52) so light wraps warmly through the ears, nose tip, and fingers, paired with subtle skin-pore micro-roughness (roughness \= 0.58).

#### **Pillar 4: Explicit Tectonic Armor Part Separation & Layered Silhouette Readability**

To make every piece of the **Hedgerow Wool-Mantle**, **Bramble-Spun Jerkin**, **Hearth-Linen Coat**, and **Iron-Wood Ring-Coat** read as distinct, functional layers of gear rather than one extruded tube:

1. **Physical Step-Depth Offsets (\+0.015m to \+0.032m Layer Steps):**  
   * Never rely on flat color changes on a single smooth surface. Each armor component must step outward in 3D radius with a dark COLOR.r \= 0.25 ambient-occlusion under-lip:  
     * **Layer 0 (Base Under-Tunic & Breeches):** Buff homespun linen collar, cuffs, and slate knee-breeches (r \= 1.00x).  
     * **Layer 1 (Quilted Gambeson / Wool Great-Coat Skirt):** Steps out \+0.016m with raised 0.008m rolled-leather hem piping and a clean front center split revealing the breeches when running.  
     * **Layer 2 (Stitched Brigandine Cuirass / Ring-Mail Hauberk):** Steps out another \+0.018m over the ribcage (y \= 1.06m..1.35m), featuring distinct overlapping leather/iron lames, embossed brass corner rivets, and diagonal leather shoulder-straps with functional brass roller-buckles.  
     * **Layer 3 (Pauldrons, Gorget, & Wood-Splitter's Harness):** Asymmetric left **3-Tier Laminated Iron-Wood & Forged-Iron Pauldron** (with a raised sword-breaker haute-piece lip protecting the neck) and right **Articulated 2-Plate Leather Archer's Cop**, strapped across the chest to the **Left Forearm Buckler-Bracer** and cinched waist belt.

---

### **Build Notes (Phase 19B)**

What's built, and where it differs from the text above on purpose.

#### **What's built**

1. **Micro-surfaces** (`storybook_hero_atelier.gdshader`). The material ids are re-laid in this document's bands: woven cloth below 0.3 (heritage wool, slate breeches, tabard, tunic, trim, linen, hemp rope), timber below 0.42 (hewn timber and a darker Iron-Wood bark), leather below 0.5 (oiled saddle leather, now its own #A06A4A, and dark bog-leather), metal below 0.7, then skin. Cloth carries the twill weave (`sin((u + v) * 110) * sin((u - v) * 110)`, normal 0.28, colour ±6%) and a velvet fuzz rim (`pow(1 - N·V, 2.2) * 0.22`) on its light-facing edge. Timber has fibres stretched 14:1, growth rings and stepped adze facets (±12% ochre to umber, grooves 0.24, roughness 0.68). Leather has a Voronoi pebbled hide, roughness 0.78 in its creases and 0.28 with a 0.65 waxy sheen on worn edges (10% lighter), and saddle-stitch ticks every 15 mm along its seams. Metal has planished hammer facets (32 cells a metre, 0.16), the sun's crisp glint (`smoothstep(0.86, 0.92, R·V)`), the sky band and #2B3036 forge-soot in its cavities.
2. **The face** (`HeroMeshAtelier`). A 24-sided head sculpted in planes: a brow ridge standing about 24 mm proud of orbital sockets recessed 22 mm, zygomatic cheekbones, sunken temples, a narrower jaw; a three-plane nose to a rounded 42 mm tip with its wings; almond eyes of #F4EFE6 sclera, a #5E4728 iris disc, a dark pupil and a dark lash rim; angled brows; cupped ears at ±0.155 m when the head is uncovered; a two-wing handlebar mustache proud of the woodsman beard's jaw mass and three faceted lobes. The face carries its portrait zones in its UVs: a warm golden-ochre forehead (+6%), a 32% #D97964 malar flush over the nose, cheeks and ear tips, and a #9E8272 cool undertone under the eyes and along the jaw. The shader adds the #E26D52 sub-dermal scatter band at the terminator (`smoothstep(-0.18, 0.20, N·L) * (1 - smoothstep(0, 0.35, N·L))`), skin roughness 0.56, and a corneal catchlight (`smoothstep(0.95, 0.985, R·V) * 1.6`) on the iris and pupil.
3. **Tectonic armour.** Every layer steps out over the one beneath with a dark AO under-lip (`COLOR.r` 0.25): Layer 0 a rolled linen collar, quilted linen under-sleeves puffing at the elbow and slate knee-breeches with a buckled garter; Layer 1 the coat's skirt 18 mm off the hips, split up the front over the thighs, with side gores and a raised rolled-leather hem; Layer 2 the coat's chest: the Wool-Mantle's six stitched-leather brigandine lames with iron studs, brass corner rivets and two crossed shoulder harnesses through brass roller-buckles; the Ring-Coat's beveled steel breastplate with a medial ridge over its ring-mail, back plate, high gorget and banded skirt; the Jerkin's diamond-quilted padded jack laced up each side; the Linen Coat's pleated surcoat, short capelet and brass carillon-clasp. The Iron-Woodsman's left pauldron is three laminated Iron-Wood plates in iron rims with an upturned haute-piece and a buckled arming-strap; his right a brass-studded two-lame leather cop. Bracers stand over the forearm with two buckled straps (the left carries the Iron-Wood and brass buckler-bracer); gauntlets have three articulated knuckle plates and a thumb plate; boots have folded-down tops (0.34 to 0.42 m), stacked heels and iron hobnails round the welt. The Iron-Woodsman's sculpt grew from about 6,600 vertices to 11,400.
4. **The jaunty run** (`HeroClipBook._run_cycle`). Each boot plant (frames 4 and 18) squashes the hips 45 mm over a 3-frame cushion and the push-off lofts them 55 mm (11 and 25); the weight shifts 35 mm over the planted boot with a 6.5-degree pelvic roll and 0.18 rad hip yaw; the chest counter-twists 0.22 rad and rolls its shoulders; the head counter-pitches 35% of the chest's bounce and holds its gaze. The weapon rides one-handed in a diagonal low port across the hip (about 30 degrees off upright), bouncing 3 frames behind the pelvis, while the off arm swings to counter-balance. Feet run 35 mm wider a side, heel-strike tips the leading boot up 24 degrees, the trailing ankle snaps 31 degrees down on toe-off and the swing knee whips up 0.78 rad. The beard's spring trails the hips' rise and fall by about two frames.
5. **Verification.** `tools/test_hero_rig.gd` adds the micro-surfaces (the shader's code and uniforms), every id in its band, the head (vertex growth, the eyes, the brow-over-socket step, the nose tip, the mustache wings and three lobes, ears only when uncovered, the face zones), the armour (every region past Phase 19's count and every vertex weighted, the brigandine's step off the tunic, each coat's own chest, the pauldrons, knuckles, boot tops and hobnails) and the run (the hips' squash, loft and shift, the pelvic roll and yaw, the chest's counter-twist, the port's angle, the off arm's swing, heel-strike, toe-off, the wider track and the knee whip).

#### **Deliberate differences**

- **The face's heights fit our head.** Heroes face −Z with their eyes at 1.60 m under a 1.75 m crown, so the brow ridge sits at 1.62 to 1.635 m (not 1.55 to 1.58) and the nose tip at z −0.177 m (the document's +0.175, mirrored); the sockets recess the specified 22 mm.
- **The weave is six times denser than written.** The 110 assumes UVs of 0 to 1 a piece; ours are in metres, so `weave_density` 6 gives centimetre threads. The weave, the pebbled hide and the stitches fade out where they'd fall below a pixel, so nothing shimmers at the 4.8 m eye-line.
- **Linen moved into the cloth band** and leather has its own colour (#A06A4A), separate from the hewn hazel (#9C7250). The brief gives `COLOR.b` 0.6 for both iron rims and brass rivets; iron stays 0.55 and brass 0.62.
- **Two-handers let go of the haft on the run.** The low-port carry is one-handed so the off arm can swing; the off hand takes the haft again in any fighting stance.
- **The run's spine leans less** (5 degrees, not 10), since the kinematic lean adds up to 0.24 rad at full speed.
- **The scatter band shows on faces, ears and necks, not knuckles,** since every hero wears gauntlets.
- **The shader no longer disables specular,** so its own glints (metal, burnished leather, the catchlight) reach the frame; the catchlight also has a view-space spark so eyes gleam from any angle.
