# 21_WINGFEATHER_YOUTH_HERO.md — The Level 1 Youth: Model, Animation and Start

Source: the Google Doc *Everwood Equipment & Grimoire Architecture*
(id 1YjX1R2My3dTVc0IgZoR5e3I5VOup84hdUUPXl9aeP0s), section 2, "Pillar A &
Pillar B: The Wingfeather Youth Aesthetic & Canonical 7-Tier Material
Progression Matrix", plus its §5.3 ActorVisuals blueprint and §4 Stage 1 row.
Creative Director decisions (2026-11-06): the youth walks empty-handed and
draws the Tier 1 tool only in a fight; the youth starts in the Wayfarer seat,
Unsworn.

## 1. What the doc asks of the player character (extracted)

| # | Direction | Source line |
|---|---|---|
| 1 | Players begin on **Miller's Oak (Character Levels 1–5)** as selectable male or female **14-year-old youths**. | §2 ¶1 |
| 2 | Proportion and spirit of *The Wingfeather Saga*'s Igiby children (Janner, Tink, Leeli): earnest, hand-crafted. | §2 ¶1 |
| 3 | **"Truth of Materials"** (Garrett Taylor): CG puppet rigs with hand-painted storybook textures that carry weight and real peril. No rubbery, inflated cartoon distortion; tactile, hand-worked surfaces (split grain, rawhide stitching, axe-hewn facets). | §2 ¶1 |
| 4 | A **5.5-head-tall heroic storybook proportion**, readable from the locked **4.8 m camera** in 4-way split-screen. | §2 ¶2 |
| 5 | Head and silhouette at **1.18x cranial proportion**, with **clear brow-ridge planes**. | §2 ¶2 |
| 6 | **Distinct hair or hood silhouettes**: wind-tousled bangs, homespun scarves, woven reed-caps, reading at 30–45° camera pitch. | §2 ¶2 |
| 7 | **Hands and feet at 1.22x**: sturdy boots ground the footwork; the off-hand card pull stays unmistakable. | §2 ¶2 |
| 8 | No forged steel in the first hour: Tier 1 homestead "make-play" tools only (Orchard-Wood). Level 1 Light hits for 2.0–3.0. | §2 ¶3 |
| 9 | Tier 1 Wayfarer coat is the **Bracken-Pelt Jerkin**; Tier 1 shader recipe: albedo #7A5438, metallic 0.00, roughness 0.88, coarse grain 1.40x (hand-split timber, homespun cloth). | §2 table |
| 10 | Male and female youths share every attachment through standard sockets (Hand_R, Hand_L, Spine_Upper); the torso adapts by one taper. | §2 "Code-First" |
| 11 | `apply_wingfeather_youth_proportions()` scales Head 1.18 and Hands/Feet 1.22 through `set_bone_pose_scale`. | §5.3 |
| 12 | Stage 1 (Lv 1–5): basic swings only (3-hit Light, held Heavy, Guard/Dodge), 0 cards at Lv 1. | §4 table |

Blended, as asked, with the reference sheets (tousled brown mop, open linen
shirt with rolled sleeves, braces, patched russet breeches with cuffs,
turned-down boots, a knotted neckerchief) and the Cooper / Le Guin / Tolkien
register: the goatherd boy of Gont in his homespun and his cloak, Will Stanton
in the snowy lanes, a hobbit's waistcoat-and-braces practicality. Earnest,
not cute; a country youth who has done real chores.

## 2. The youth's design

**Silhouette (front to back, head to foot)**

- A big, wind-tousled chestnut mop: a cap of hair with a dozen chunky locks,
  bangs swept to the youth's left, a cowlick at the crown, locks over the ears
  (direction 6: reads at 30–45° pitch).
- A young, open face: softer brow ridge than the adults but still planed
  (direction 5), bigger eyes, a small upturned nose, a rounder jaw, no beard.
- A Wayfarer-green homespun neckerchief, knotted at the throat (the Fellowship
  tie, and the doc's "homespun scarf").
- A loose cream linen shirt, laced at the open collar, sleeves rolled above
  the elbow in fat cuffs; bare forearms.
- Saddle-leather braces over the shirt, crossing at the back, buttoned to the
  breeches; a plain belt with a small tin-buckled pouch.
- A short hooded half-cape of heather-blue wool (the Earthsea cloak of the
  reference), the hood down and folded round the shoulders, the cape to the
  small of the back on the three cloak springs, so it lifts when the youth runs.
- Russet-madder knee-breeches with a sage patch on the left knee, cuffed
  below the knee; striped wool stockings (cream and Wayfarer green).
- Big turned-down soft-leather boots with a rolled cuff and a round toe
  (direction 7, 1.22x).
- Bare hands at 1.22x: palm, four-finger block and a thumb (no gauntlets).

**Proportion.** The youth uses the same 24-bone skeleton as every hero, scaled
to 0.9 (a 14-year-old about 1.6 m tall). The head is sculpted at 1.18x
round the neck joint and the hands and feet at 1.22x round their joints, in
the mesh rather than by bone scale, so the shared animation library, the
foot-plant IK and the sockets keep working untouched (direction 11's intent,
built the way this rig can carry it). Measured: a 1.64 m crown, 5.2 heads.

**Material.** Tier 1 "Truth of Materials": the same hero shader, everything
matte (no metal on the youth but a tin buckle), coarse homespun weave, the
cape's dagged hem left raw.

**Palette (Three-Value Harmony).**

| Value | Part | Colour |
|---|---|---|
| 1 (60%) | heather-blue wool cape | #3B4A66 |
| 1 | russet-madder breeches | #7A3A2E |
| 1 | soft boot leather | #4A3324 |
| 2 (30%) | linen shirt | #DCCFB6 |
| 2 | saddle leather braces and belt | #A06A4A |
| 2 | Wayfarer neckerchief and stocking stripes | #3B7A47 |
| 3 (10%) | face, the Wayfarer rim | skin #E8B996, rim #52C478 |

## 3. Animation (new and evolved)

All clips are authored for the shared skeleton in `HeroClipBook` and baked
into the same procedural library:

| Clip | Frames | What it shows |
|---|---|---|
| `idle_youth_calm` | 240 loop | weight on the right hip, right thumb hooked in a brace, left arm easy; breathes, looks off left, glances back over the right shoulder, shifts weight |
| `locomotion_youth_walk` | 40 loop | an easy country walk, 1.5 m a cycle: heel-toe roll, arms swinging loose, a small bounce |
| `locomotion_youth_run` | 26 loop | an eager run, 2.6 m a cycle: forward lean, bent arms pumping, knees high, a bouncy loft (the cape springs lift) |
| `youth_draw_tool` | 18 | the hand reaches back and brings the Tier 1 tool forward (played when a fight starts) |

The animator picks walk below 3.2 m/s and run above it while the youth is
calm and empty-handed; once fighting, the existing Tier 1 weapon clips play,
so Level 1 combat is unchanged. The youth starts calm (empty hands at spawn).

## 4. Level 1 start

- Seat: Player 1 boots as a **Wayfarer, Unsworn**, wearing the honest Level 1
  trail kit (`ArsenalCatalog.trail_kit_for_role`: Tier 1 Willow-Coppice
  Longbow, Bramble-Spun Jerkin, Rising Drive on Forward+Heavy, Frost Crescent
  on Back+Heavy, R and L+R un-inked), base stats 100 HP, 6.6 m/s.
  The forced Iron-Woodsman Calling and Broad-Axe boot is retired.
- Look: any player hero whose Calling is Unsworn (the trail before Level 10)
  is a youth; swearing a Calling at Level 10 brings the adult hero. Companions
  are always sworn, so they stay adult.
- Place: Miller's Oak, the Lee-Shore Orchards (the doc's Tier 1 source,
  "Cider-Mill & Orchard-Green Homestead"), at the foot of the orchard lane,
  facing up the lane toward the Windmill and Hearthstead Market.
- A fresh Level 1 run: `-- --save=user://fresh_youth.cfg` (the family save
  keeps its own trail level and is never written by tests).

## 5. Build steps

1. `HeroYouthAtelier` sculpts the youth's five skinned surfaces (same region
   names) with `HeroMeshAtelier`'s loft tools; `Sculpt` gains a vertex warp so
   the head and extremities scale round their joints.
2. `HeroAppearanceResource` gains `body_build` (`adult` / `youth_wingfeather`)
   and hair and cape fields; `ArsenalCatalog` registers the Wayfarer youth
   look; `ActorVisuals` builds the youth (skeleton at 0.9, no weapon while calm,
   quiver only while the bow is out, satchel moved in).
3. `HeroClipBook` gains the four youth clips; `HeroCombatAnimator` picks them.
4. The boot seat becomes the Unsworn Wayfarer on the trail kit; the arrival
   moves to the lane's foot and the party faces up the lane.
5. Checks: `tools/test_youth_hero.gd` (proportions, palette bands, empty hands,
   clips, the boot seat, the start spot), joined to the smoke test; the older
   boot checks updated.

## 6. Build notes and deliberate differences

**What was built**

- `src/actors/hero_youth_atelier.gd` (`HeroYouthAtelier`): the youth's five
  skinned surfaces, sculpted with `HeroMeshAtelier`'s loft tools.
  `HeroMeshAtelier.Sculpt` gained `warp`, a per-vertex callable applied as each
  vertex is written (after its weights, face zones and rest height are taken),
  which scales the head 1.18x round the neck joint, the eyes another 1.14x, the
  hands 1.22x round the wrists and the boots 1.22x round the soles.
- `HeroAppearanceResource`: `body_build` (`adult` / `youth_wingfeather`),
  `patch_color`, the youth constants, `is_youth()`; the sculpt key includes the
  build. `ArsenalCatalog` registers a youth per Fellowship
  (`youth_appearance_for_seat`, `youth_appearances`); seats after the first
  dye the cape with the heritage dyes.
- `ActorVisuals`: `is_youth_seat()` (an Unsworn player, never a companion;
  `ActorVisuals.youth_heroes` turns the rule off), the skeleton drawn at 0.9,
  the trim slot set to the patch colour, the satchel moved in, the tool and its
  quiver or shield hidden while calm (`_tuck_away`, `is_empty_handed()`) and
  popped into hand over 0.16 s with the draw overlay, and the foot probe's
  ground heights divided by the skeleton's scale.
- `HeroCombatAnimator.youth`: starts calm, calm for a bow too, walk below
  3.2 m/s and run above (one shared cycle, so the stride's phase carries
  across), the calm youth's jump on the run's frames, the draw overlays on
  the correct arm. `HeroClipBook._youth`: the idle, the walk and run sampled
  from smooth gait curves, the two draws.
- The boot: `LevelBase.solo_youth_boot` (was `solo_iron_woodsman_boot`) seats
  Player 1 as the Wayfarers like any seat. The forced Stout Heart Calling,
  `PartyProgress.iron_woodsman_kit()`, `ClassLoadouts.SOLO_BOOT_CALLING /
  _ARMOR / _WEAPON_TYPE` and `--kit=saved` are gone.
- The start: `IslandBuilder.add_arrival` takes a facing (`arrival_yaws`,
  `arrival_basis`); seats spread across the facing; Miller's Oak's orchard
  arrival stands Player 1 at (354, 222) on the lane, facing up it
  (`OakshireHolmBuilder.ORCHARD_LANE_FOOT / _UP / ORCHARD_ARRIVAL`).
  `CalderaArchipelagoWorld` uses the facing for the spawn markers and
  `place_party_at`, so the camera starts looking up the lane.
- Checks: `tools/test_youth_hero.gd`, run by `test_hero_rig.gd`'s `run_boot`
  on the boot seat at Level 1. The smoke test now switches to the Level 10
  classic kits after the boot checks rather than before them.

**Deliberate differences from the doc**

1. *Proportions by sculpt, not bone scale.* §5.3 scales the Head, Hand and
   Foot bones with `set_bone_pose_scale`. On this rig that would scale every
   socket on those bones (the weapon in hand) and fight the animator, which
   writes every bone's pose each tick. The youth is sculpted at those scales
   round the same joints instead, and the whole skeleton is drawn at 0.9.
2b. *5.2 heads, not 5.5.* The doc's 1.18x head and its 5.5 heads can't both
   hold here: this rig's grown heroes are about 6.2 heads, so a 1.18x head
   gives about 4.7. The youth keeps the 1.18x head (the storybook read the
   reference sheets show), scales it from mid-face, and has a shorter, rounder
   jaw, which lands at 5.2 heads to a 1.64 m crown (checked: 4.95 to 5.6).
2. *One youth, not male and female.* The doc says "selectable male or female".
   This build has the one youth (the reference sheets' boy); a second build
   with a different hair silhouette and a torso taper is the natural next step,
   and `body_build` leaves room for it.
3. *Empty hands, then the Tier 1 tool.* Creative Director call: the youth walks
   empty-handed and draws the trail's Tier 1 weapon in a fight. The doc's
   Orchard-Wood Stick, Cooper's Mallet and Rowan Walking-Stick are not in the
   game yet (the Equipment & Grimoire branch adds the tier data, not these
   models), so the Wayfarer youth draws the existing Tier 1 Willow-Coppice
   Longbow. Damage stays on `04_BALANCE.md`'s numbers, not the doc's 2.4.
4. *Youth until sworn.* The doc puts youths on Miller's Oak (Levels 1–5) and
   says nothing of when they grow up. Here every player stays a youth while
   Unsworn and becomes the grown Calling hero when sworn at Level 10.
5. *The start spot.* The doc names "Cider-Mill & Orchard-Green Homestead
   Chests" as the Tier 1 source. The isle has no cider-mill or homestead
   chests yet, so the start is the orchard lane's foot, the nearest real place.
