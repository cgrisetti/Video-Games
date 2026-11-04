## One zone's look (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §7.1 A; 08 §3
## Pillar 4): its ground palette (mid-values, so telegraph rings always read),
## its sun, sky and fog, and how thickly its chunks grow grass, flowers and
## pebbles. Pure data; WorldVisualCatalog registers them and the
## WorldAtmosphereDirector eases from one to the next as the party walks.
class_name ZoneBiomeResource
extends Resource

## Canonical Sightline & Streaming Constants (Gate 5)
const CAMERA_EYELINE_HEIGHT_M: float = 4.8
const MAX_OBSTACLE_SIGHTLINE_M: float = 3.2
const MAX_WALKABLE_RAMP_DEG: float = 25.0
## How far an open Hush-Crack's blight reaches (18 §5: 22 m), and its rim of hoar-rime.
const DEFAULT_HUSH_RADIUS_M: float = 22.0
const HUSH_RIME_RING_M: float = 2.5
## A Lantern-Bearer's (or a Hearth-Rite holder's) warm halo pushes the blight back this far (18 §5 layer 4).
const LANTERN_HALO_RADIUS_M: float = 5.5

@export var biome_id: StringName = &"tizzi_wed_green"
@export var display_name: String = "Tizzi-Wed-Green"
@export var cooper_sign_title: String = "Sign of Wood"
@export var primary_scribe_sign: int = 0 ## ScribeSignResource.Sign

## Terrain Splat Colors (Mid-value calibrated for Telegraph Decal contrast)
@export var turf_albedo: Color = Color(0.357, 0.549, 0.290)      ## #5B8C4A
@export var road_albedo: Color = Color(0.784, 0.749, 0.659)      ## #C8BFA8
@export var hollow_albedo: Color = Color(0.349, 0.275, 0.212)    ## #594636
@export var crag_albedo: Color = Color(0.478, 0.502, 0.525)      ## #7A8086
@export var hush_desaturate_tint: Color = Color(0.431, 0.471, 0.502) ## #6E7880
## The trodden loam-and-clover verge along a road's edge (18 §3.1).
@export var verge_loam_albedo: Color = Color(0.306, 0.365, 0.220)  ## #4E5D38
## Rolling cloud shadows (18 §4.4): how much of the sun a cloud takes, and how big the patches are (cycles per metre).
@export var cloud_shadow_strength: float = 0.22
@export var cloud_shadow_scale: float = 0.028

## Lighting & Atmosphere Envelope
@export var sun_color: Color = Color(1.0, 0.95, 0.86)
@export var sun_energy: float = 1.15
@export var sky_top_color: Color = Color(0.231, 0.471, 0.722)
@export var sky_horizon_color: Color = Color(0.961, 0.886, 0.769)
@export var fog_light_color: Color = Color(0.85, 0.89, 0.82)
@export var fog_density: float = 0.0018

## MultiMesh Clutter Densities (Per 128m x 128m Landblock)
@export var grass_clump_count: int = 800
@export var wildflower_count: int = 200
@export var pebble_fungi_count: int = 100
@export var tree_kit_ids: PackedStringArray = PackedStringArray(["kit_tree_moss_oak", "kit_tree_orchard_apple"])
## The wildflowers' colours (daisies and buttercups on a green, heather on a crag, rush-reeds in a hollow).
@export var flower_colors: PackedColorArray = PackedColorArray([Color(0.96, 0.95, 0.88), Color(0.98, 0.84, 0.3), Color(0.86, 0.62, 0.78)])
## Grass tufts' colour, before each tuft's own shade.
@export var grass_color: Color = Color(0.42, 0.6, 0.32)
