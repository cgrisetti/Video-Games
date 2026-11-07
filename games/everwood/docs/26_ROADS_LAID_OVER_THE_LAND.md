# 26 · Roads laid over the land, small cobbles, cleaner ground

> **Asked for (2026-11-07):** the ground looked muddy, the cobbles were too big and all alike, the Zone Map's roads were straight lines, and in the world the roads were jagged diagonals. Roads should wander through the terrain by the best way.
> **Scope:** all five Caldera isles (Miller's Oak, Iron-Ness, Barrow-Eyot, Rime-Firth, The Crown), their ground shader and their map. Legacy levels are unchanged.

| | Before | After |
| :-- | :-- | :-- |
| Road shape | A few hand-placed points joined by straight lines | Each leg routed over the ground, then rounded into curves |
| Road edge | Painted into the ground's vertex colours on a 2 m grid, so it zigzagged along the triangles | Drawn per pixel from the laid road: a smooth curve |
| Cobbles | One painted texture, about seven stones every 3 m, flattened to one tone | Small irregular setts (about 0.2 m) laid along the road, each its own size and tint, the edge ones missing into the turf |
| Narrow paths | The same cobbles | Packed earth, ruts and pebbles |
| Ground | A yellow loam verge along every road, the turf tile showing as a grid from above, cobble texture and orange leaf-litter on beaches and banks | A faint trodden verge, the turf blended at two scales, sand on beaches, quiet gravel on banks |

## 1. How a road is laid

`IslandBuilder.add_path(points, half_width, route := true)` now asks for a road; `_lay_roads()` lays them all once the island is defined:

1. **Route each leg.** Each leg between two control points is searched on a 5 m grid (`AStarGrid2D`) over a corridor round it. A cell costs 1, plus a climbing cost for grades over 10%, plus a little slow noise so open ground isn't crossed in a ruler line. Deep water and grades over 55% are closed; shallow water costs 40 (a ford only where there's no other way). Cells near a road already laid cost 55%, so roads share trunks instead of running side by side.
2. **Straighten, round, relax.** The route is straightened to within 3 m (Ramer–Douglas–Peucker), rounded three times (Chaikin), resampled every 3 m and relaxed 48 times, so no bend is a hairpin. Wherever smoothing cut a corner into water, the points ease back onto the route.
3. **Re-lay after the coast.** The organic coast keeps clear of the roads, so it is shaped after them. Any road that its bays or fen pools then put underwater is laid again over the final ground.

Legs under 24 m, legs that run along a ramp (a built grade) and roads asked for with `route = false` are only rounded. The Crown's Ring Path is one: it is already a smooth loop through the springs. So are the first 50 m of the orchard lane, which keeps the Level 1 start facing straight up it.

The laid roads are `laid_roads` (points 3 m apart, drawn by the shader) and `_paths` (6 m segments, read by the scatter, the meadow, the map and `on_path`). `nearest_road()` and `roadside()` find a spot beside a road; Miller's Oak's lantern poles use them.

## 2. How a road is drawn

`IslandBuilder.road_textures()` packs the laid roads for the ground shader: the segments (two float texels each), a 16 m grid over the island, and each cell's list of nearby segments. `ArchipelagoStreamer` puts the live isle's set on the shared terrain material and clears it on leaving, so legacy levels draw their vertex-painted roads as before.

`storybook_terrain_splat.gdshader` finds, for every pixel, the nearest road segment and the distance along and across it:

- **Cobbled roads** (half width over 1.7 m) are setts in road space: rounded crowns, dark joints of earth with the odd tuft, and a tint per stone from granite greys, warm sandstones, a pale limestone and a mossy one. Near the edge, setts go missing at random, so the road ends in whole stones with turf between. When a sett gets under a few pixels, it fades to the road's average.
- **Footpaths** (half width 1.7 m or less) are packed earth with two worn ruts and pebbles. On the narrowest, grass creeps into the middle.
- **The verge**, under a metre past the edge, is the turf slightly darker and cooler, never yellow.

The road keeps its own range of tones; the ground's value clamp is applied before it.

## 3. The ground

- **Vertices no longer paint roads.** In the Caldera (`STORYBOOK_DRAWN_ROADS`), what the vertex colours used to call "road" is a beach or a sandy bank. It now draws as sand, eased softly into the turf, with no flagstones and no frayed verge.
- **The turf** is sampled at two scales, the second turned, and blended by a slow noise. Its 4 m tile no longer reads as a grid from above.
- **The loam's orange leaf-litter** is cut to a trace on banks and scree. That was the muddy band along every inlet.

## 4. Fixes the routing turned up

- **Steadings in pits.** Iron-Ness's steading sat 22 m below the land round it, and Rime-Firth's 34 m. Each now sits at its land's own height. The two straight ramp trenches on Iron-Ness (causeway to steading, inner shore to steading) are gone; the routed road climbs instead.
- **Landmark paths.** Barrow-Eyot's ended in the Bell-Tower's lagoon; it now stops on its outer shore. Rime-Firth's climbed the Snow Peak's 224 m summit; it now stops at the peak's foot.
- **The Crown.** The trial arenas' edges ease over 18 m (they were 10 m banks where the spurs met them). The gully road follows the gully's own grade. The Waypost's spur meets the gully road at its centre. The Sea-Door stair starts at the Ring Path's real height.

## 5. Checks and cost

`tools/test_laid_roads.gd` runs inside `tools/test_caldera_isles.gd` (3 checks):

- Routed roads wander from their straight lines (up to 73 m), bend at most 30° between 3 m steps, climb at most a walkable 85% grade, stay out of the sea away from quays and causeways, and still reach their ends.
- Every isle has road data, the live isle's is on the terrain material, and the vertices don't paint roads.
- The map and the scatter read the laid roads, not the old straight lines.

The Crown's zone checks now measure camp clearances against the laid roads.

Laying the roads adds about 150 ms to building Miller's Oak, 40–80 ms to each of the others, and nothing per frame on the CPU. The shader loops over at most 48 nearby segments per pixel, usually a handful.

## 6. Calls for the Creative Director

1. **Rime-Firth's roads stay steep in places** (up to 77%, under 40°). Its rim is ridged, and routing round every crease would add long switchbacks. Walkable, but not gentle.
2. **The vertex-painted market squares and the legacy maps** keep their old look. Only Caldera roads are drawn per pixel.
3. **The routes are generated, not hand-drawn.** If a road should pass a particular spot (a bridge, a viewpoint), add that spot as a control point and it will be routed through.
