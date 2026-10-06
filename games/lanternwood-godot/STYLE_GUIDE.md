# Lanternwood style guide

How the new Lanternwood should look, sound and feel. Use this when adding anything: a new area, a
creature, a sign, a menu. The colours and numbers here are the ones in the code, so the code is
the final word if they ever drift apart.

## The idea in one line

**A living storybook at golden hour.** Walking through Lanternwood should feel like stepping into
an illustrated autumn picture book (Over the Garden Wall's Pottsfield, the hedgerows of Brambly
Hedge, Kiki's Delivery Service's warm towns) but lit like a real place: the sun is low, the air is
hazy, leaves glow when the light comes through them, and paper lanterns pool warm light on the path.

We have moved on from both earlier looks:

- **Not low-poly.** No flat-coloured boxes and balls standing in for things. Shapes are rounded,
  lumpy and a little uneven, the way things grow.
- **Not a painted filter.** The three.js version painted over the picture with a brush effect.
  Here the richness comes from the world itself: real light, real shadow, haze, texture on every
  surface, and thousands of leaves and grass blades.

## Light

Light does most of the work. Get it right and simple shapes look lovely.

| | Setting | Where |
|---|---|---|
| Time of day | Late afternoon, sun about 22° up | `Sun` in `scenes/glen.tscn` |
| Sun direction | From the north-west, *behind* the path as you walk it, so leaves and grass glow and shadows stretch toward you | `Sun` rotation |
| Sun colour | Warm peach `#FFD6A3`, energy 1.7 | `Sun` |
| Sky | Dusty blue overhead `#5278AD` fading to apricot at the horizon `#EDC28F` | `ProceduralSkyMaterial` |
| Haze | Warm volumetric fog that catches the sun (anisotropy 0.55), plus distance haze so far trees fade to the sky colour | `Environment` |
| Lanterns | Candle orange `#FFB052`, real lights with a gentle flicker, range 6 m | `Props.lantern()` |
| Shadows | Soft-edged, never pure black; ambient light from the sky fills them with blue-green | `Environment` ambient |
| Tone | AgX tonemapping, glow on bright things (lanterns, fireflies, sunlit edges), saturation +12% | `Environment` |

Rules of thumb:

- Every area has **one warm key light** (the sun, or lanterns at night) and cool, soft fill.
- Light should come **from behind or the side** of what the camera looks at, never flat from the front.
- Glowing things (lanterns, fireflies, windows) are the brightest thing in view. Nothing else glows.

## Palette

Greens lean yellow and olive, never minty or neon. Autumn colour is an accent: about a quarter
of the broadleaf trees, a scatter of pumpkins, falling leaves.

| Role | Colours |
|---|---|
| Leaves, sunlit / shade | Oak `#9CB54A` / `#26401A`, birch `#C3CF5A` / `#4B6224`, pine `#5F8A52` / `#14271C`, hedge `#7FA043` / `#1A3014` |
| Autumn accents | Amber `#E6A43A`, rust `#D0602A`, gold `#ECC84A` |
| Grass | Root `#29471A`, tip `#8CAD42`, dry tips `#C7B861` |
| Earth path | `#A3855C` to `#6B5238`, with pale pebbles |
| Stone | Warm grey `#A59C8C`, moss `#5F7A2C` |
| Wood | Bark `#5E4A3A`, posts `#3E2C20`, signs `#B08A5A`, white-washed pickets `#D8CDB4` |
| Pumpkins | `#E07A22` to `#F2A33A` |
| Gnome | Hat `#C8261C`, tunic `#2F68B0`, beard `#F5F2EA`, skin `#F1C6A2`, trousers `#D6C196`, boots `#3A2A22` |
| Fox | Fur `#D9702A`, cream `#F6EAD6`, socks `#3A2618` |

The leaf and bark colours live in `Foliage.GREENS` and `Foliage.BARK` (`scripts/world/foliage.gd`).

## Shapes and surfaces

- **Nothing perfectly straight or perfectly round.** Trunks lean and wobble and flare at the
  roots (`Art.tube_mesh`), rocks and bushes are noise-pushed spheres (`Art.blob_mesh`), path edges wander.
- **Leaves are masses, not balls.** Crowns, bushes and hedges are many small leaf cards spread
  through a rounded volume (`Art.add_leaf_cards`). Their lighting is bent so the whole crown shades
  like one soft shape, with a lit side, a shadow side and glowing edges when back-lit.
- **Every surface has texture.** Bark has grooves and moss on top, stone has speckles and moss
  on the sky-facing side, the ground has patches, dry spots and pebbles. Use the shaders in
  `shaders/` rather than plain colours for anything bigger than a hand.
- Small, made things (signs, gates, lanterns) can be simpler shapes, but still use the wood and
  stone materials so they belong.

## The world, in layers

Build each area up in the same order, so it always feels full:

1. **Ground**: meadow with worn paths, shade at the foot of walls and hedges.
2. **Grass**: thick tufts everywhere you walk, thinning onto paths, swaying and parting round the gnome.
3. **Undergrowth**: ferns, toadstools, wildflower drifts and pumpkins where things meet (hedge feet, gate sides).
4. **Structure**: hedges, walls, gates, posts: the shape of the area.
5. **Trees**: groves of one kind with a few neighbours of another, sunny glades left open, bigger trees deeper in.
6. **Distance**: rolling hills fading into the haze, so there's never a hard edge to the world.
7. **Air**: fireflies, motes and falling leaves near the player.

## Movement

Everything alive moves a little, all the time, and nothing moves fast unless it's the player.

- Wind: leaves sway and flutter, grass leans in slow gusts (shared `wind_at()` in `shaders/noise.gdshaderinc`).
- Lanterns flicker by a few percent, each in its own rhythm.
- Characters squash on landing, stretch on take-off, lean into a run, and their soft bits (hat tip, tail) trail behind.

## Characters

- Chunky storybook proportions: big head and hat, short legs, readable from behind at camera distance.
- Rounded, soft shapes with a gentle **rim light** so they stand out from the greenery.
- One strong colour each (the gnome's red hat, the fox's orange) that nothing else in the scene competes with.

## Camera

- Behind and above the gnome, about 9 m back, looking a little over its head so the treetops and sky show.
- 55° field of view, with a faint blur far away.
- The player can turn and tilt it (Q/E, T/G, right stick); movement is always relative to the camera.

## Menus and on-screen text

The storybook look carries over from the three.js version, now in `ui/theme.tres`:

- **Cream paper cards** `#FBF4DF` with a brown ink frame `#8B6A43`, rounded corners and a soft drop shadow.
- **Brown ink text** `#4A3826`; softer notes in `#7A6448`; group headings in moss `#6E9150`.
- **The chosen row** glows golden (`#F4C44C` at 38%) with a darker gold edge on the left.
- **Fonts:** Palatino for reading, Luminari for titles (both come with macOS; other systems fall back to Georgia or any serif).
- **Key caps** for buttons: a little cream key with a brown border, showing the keyboard key or
  the PlayStation button, whichever the player used last.
- Words are plain, warm and short: "This way isn't open yet. Come back soon!", not "Locked".

## Sound

- The forest theme loops under everything (or its 8-bit version); it drops and goes muffled while paused.
- Effects are soft and natural: a whoosh for the stick, a gentle blip for menus.

## Graphics settings

Lanternwood should look like itself on every setting; Low is simpler, not different.

| | Low | Medium | High |
|---|---|---|---|
| Grass tufts | 14,000 | 40,000 | 80,000 |
| Trees | 60% | 85% | all |
| Haze (volumetric fog) | off | on | on |
| Ambient occlusion / bounce light | off / off | on / off | on / on |
| Anti-aliasing | off | 2× | 4× |

Numbers are in `Glen.DETAIL` and `Glen.apply_graphics()`.

## Adding something new: a checklist

- [ ] Does it use the palette above, or a colour that sits with it?
- [ ] Is its surface textured (bark, rock, leaves, ground shaders) rather than a flat colour?
- [ ] Is it a little uneven and organic?
- [ ] Does it move, if it's alive (sway, bob, flicker)?
- [ ] Is it lit from behind or the side in its usual view?
- [ ] Does it look right on Low graphics too?
