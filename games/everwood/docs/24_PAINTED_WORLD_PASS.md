# 24_PAINTED_WORLD_PASS.md — From Plastic to Painted

Creative Director brief (2026-11-07): the game looked shiny, flat and plastic,
with no lived-in texture; the goal is a whimsical Miyazaki and Grimm Brothers
world at the polish of a top indie release. The assessment found five causes;
this pass answers all four of its options (A shaders and lighting, B a texture
set, C set dressing, D models).

## 1. What was wrong

| Cause | Where |
|---|---|
| No authored art: eight code-generated textures at 256 px, used only as a faint tint | `ProceduralTextureAtelier`, the shaders' value clamps |
| Flat, even light: one ambient colour for every shadow, a weak sun, bloom over everything | `CalderaArchipelagoWorld._make_environment`, `WorldAtmosphereDirector.SUN_SCALE` |
| A glowing rim on every surface (the "CG plastic" halo) | the cel, triplanar and foliage shaders' `EMISSION` |
| Sky reflections on skin and cloth, and a white glow along every cloth edge | `storybook_hero_atelier.gdshader` (no `SPECULAR = 0`, full fuzz) |
| Clean, simple shapes: lollipop trees, capsule townsfolk, bare lawns, empty yards | `CalderaKit`, `TownsfolkNPC`, the island scatter |

## 2. A: painted light and matte surfaces

- **The painter's hand** (`src/actors/storybook_brush.gdshaderinc`): a world-space
  stroke field (40 cm strokes on the diagonal with a finer scumble). Every
  surface's shade edge wanders along it (`v_brush`), so the terminator looks laid
  on in gouache, not drawn by a computer.
- **Three painted tones** (`storybook_cel_light.gdshaderinc`, the hero's own
  `light()`): sun, a half-light at 50–55%, and the cool shade, instead of two
  crisp bands.
- **The rim is a backlight now**: a thin warm line on the silhouette only where
  the sun is behind the object. The hero keeps a faint Fellowship line for
  split-screen readability (Gate 5), 18% of its rim strength.
- **Matte heroes**: no sky reflection except on metal (`SPECULAR = 0`,
  roughness at least 0.85); cloth fuzz at 35%.
- **Weathering** (`sb_weather`): every flat-coloured prop and building now has
  sun-faded and grimy blotches, fine flecks, darker handled edges where the
  surface turns, and (scenery) moss on its upward faces. `StorybookMaterial`
  gives scenery wear 0.9 and moss 0.22, figures and creatures wear 0.45.
- **Light**: the sky fills the shadows (`AMBIENT_SOURCE_SKY`, 70% sky, energy
  0.52), the sun at full strength (`SUN_SCALE` 1.02, Oakshire 1.2, warmer), bloom
  at 0.22 with no bloom wash, exposure 0.92, stronger contact shade (SSAO
  radius 1.4, intensity 2.2, power 1.5, 18% in sunlight), a 1.07 contrast grade,
  and a bluer sky that comes further down to the horizon (`sky_curve` 0.27),
  Oakshire's haze thinned to 0.0008.

## 3. B: the hand-painted texture set

`tools/paint_atelier_textures.py` (Python 3 and Pillow, fixed seeds) paints all
eight craft textures at 1024 px with tiling brush strokes, and their normal
and roughness maps at 512 px, into `assets/textures/world/` (7.4 MB):

| Set | Painted as |
|---|---|
| Meadow turf | washes of yellow- and blue-green, 16,000 grass strokes with sunlit tips, clover, daisies and buttercups |
| Hollow loam | peat washes, 700 oak leaves in amber and rust with their veins, twigs, pebbles |
| Cobbled flagstone | worn setts, each its own stone colour, a sunlit shoulder, cracks, moss in the joints |
| Crag granite | stratified strokes, dark fissures, lichen rosettes, heather |
| Hewn timber | oak planks with wandering grain, knots, adze marks, pegs and dark gaps |
| Stepped brick | running bond, each brick fired differently, chipped corners, soot and moss |
| Lime plaster | troweled lime-wash, damp stains, hairline cracks, fallen patches showing stone |
| Scallop shingle | overlapping rounded slates, moss clumps and lichen |

`ProceduralTextureAtelier` loads them at 1024 px (`CURATED_SIZE`) when all eight
are present and skips generating its own (`render_or_blank`); headless runs
still use the 64 px generated set. The triplanar shader shows 75% of a texture's
own colour (was 40%).

## 4. C: the meadow and the lived-in village

- **The meadow** (`IslandBuilder._meadow`, built on the worker threads with the
  near landblock): about 7,000 grass tufts and 1,900 wildflowers per 128 m
  landblock, in natural clumps and drifts, in 32 m cells that are only drawn
  within 66 m of a camera and fade out per pixel by 48 m. Tufts are a fuller
  14-blade clump rooted in the ground's own colour (`CalderaKit.meadow_grass_mesh`);
  the flowers are ox-eye daisies, buttercups, poppies, cornflowers and cow
  parsley (`CalderaKit.meadow_flower_mesh`), their heads drawn 1.7x so they read
  from the 4.8 m camera. Islands can thin it (`_meadow_lushness`).
- **Richer ground**: Oakshire's painted grass is greener and deeper, and the
  terrain shader holds the ground between 33% and 58% on screen (was 68%), still
  light enough for telegraph rings.
- **Lived-in clutter** (`CalderaKit.lived_in_clutter`): five pieces round each of
  Hearthstead Market's eight cottages (coopered barrels with iron hoops, slatted
  crates, split-log woodpiles, hessian sacks, flower tubs, stump benches), and
  an apple-harvest pile beside the Level 1 start.

## 5. D: sculpted townsfolk and fuller trees

- **Townsfolk** (`StorybookFigure`, used by `TownsfolkNPC`): every capsule
  person is now a sculpted figure on the heroes' own skeleton, in a Calling's
  look dyed with their colours: guards in kettle-caps and ring-coats with a
  spear and a greatshield, merchants and quest-givers in linen, villagers in
  any look or, one in three, a village child (the Level 1 youth's sculpt). They
  stand in the easy idle and stroll in the country walk, animating at 30 Hz
  within 45 m of a camera.
- **Trees**: broadleaf and orchard crowns break into leaf clusters at the end
  of each bough (`CalderaKit._bough_clusters`), with gaps of light between them,
  instead of one round ball on a bare pole.

## 6. Build notes and deliberate differences

1. **Textures are painted by a script, not downloaded.** No third-party pack
   was fetched (no licence questions, no download). The painter is the source;
   re-run it to change a texture. A curated file can still replace any map.
2. **No new 3D model files.** Option D's "hand-made models" are built in code
   on the existing sculpt pipeline; the `.glb` drop-in hooks remain for real
   artist models later, and are the next step up.
3. **Grass costs triangles.** About 7,000 tufts a landblock, drawn only near a
   camera. If a four-way split-screen drops frames, `IslandBuilder.MEADOW_CLUMPS`
   and `CalderaKit.MEADOW_CELL_RANGE` are the knobs.
4. **Only Miller's Oak's village got clutter.** The Crown and the friction isles
   get the meadow, weathering and lighting, but no yard clutter yet.
5. **The hero's split-screen rim is kept**, thinner, for Gate 5 readability.
