## How a place looks in each state of Ecological Succession
## (17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE.md §2.2): hushed by an open
## Hush-Crack, reclaimed once it's sealed, or under a weathering event.
## Pure data; WorldVisualCatalog registers one per state and the
## WorldAtmosphereDirector reads them when a crack or a zone changes state.
class_name ZoneSuccessionVisualResource
extends Resource

enum SuccessionState { ZONE_HUSHED = 0, ZONE_RECLAIMED = 1, ZONE_WEATHERING_EVENT = 2 }

@export var state: SuccessionState = SuccessionState.ZONE_HUSHED
@export var display_name: String = "Hushed"
## How far turf inside a hush radius greys toward the biome's hush tint.
@export var hush_desaturation: float = 0.45
## How long the golden-emerald Reclamation Bloom takes to sweep out.
@export var reclamation_bloom_duration_sec: float = 2.5
## Wind-Lanterns' warmth (1 is a steady glow; under 1 dim or snuffed; over 1 a flare).
@export var lantern_warmth_multiplier: float = 1.0
## Frost dust, bog damp or fog-bank strength for a weathering event (0 for none).
@export var weathering_frost_or_fog_intensity: float = 0.0
## The motes drifting over the place: slate hush-motes, golden pollen, or driving fret.
@export var mote_color: Color = Color(0.62, 0.68, 0.74, 0.7)
