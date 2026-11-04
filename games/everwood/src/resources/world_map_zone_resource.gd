## One named place on the Wayfarer's map (18_NEXT_GEN_PASTORAL_RENDERING_WAYFINDING_AND_CAMERA_GDD.md
## §7, §8.1): a sub-zone of a world (Oakshire-Wick and its five petals, or the
## Bramble-Bridge trail's six stops), its Cooper Sign, where it lies and how far
## it reaches, where its hand-lettered callout sits on the Vellum Atlas, and which
## places it leads to. The minimap's place ribbon names the zone a hero stands in.
##
## Pure data; WorldVisualCatalog registers one per place, per instance (a world
## and its classic twin can each have a Bramble-Bridge), and the cartography
## reads them. Names are hyphenated Map-Sense compounds (15 §5, Linter Rules 2-3).
class_name WorldMapZoneResource
extends Resource

@export var zone_id: StringName = &"oakshire_wick"
@export var display_name: String = "Oakshire-Wick"
@export var cooper_sign_title: String = "Sign of Wood"
## ScribeSignResource.Sign: tints the zone's crest on the Atlas.
@export var primary_scribe_sign: int = 2
@export var world_center_xz: Vector2 = Vector2.ZERO
@export var world_radius_m: float = 140.0
## Where its callout banner sits on the Atlas, in metres from its centre (north is -Z).
@export var landmark_label_offset: Vector2 = Vector2(0.0, -18.0)
@export var connects_to_zone_ids: PackedStringArray = PackedStringArray()
## The instance it's in (InstanceManager ids: oakshire_vale, everwood_world, hub_town, dungeon_dojo).
@export var instance_id: StringName = &"oakshire_vale"


## Whether a spot (world x, z) lies inside the zone's reach.
func contains_xz(at: Vector2) -> bool:
	return at.distance_to(world_center_xz) <= world_radius_m


## How far a spot lies inside the zone, as a share of its reach (0 at its centre, 1 at its edge).
func reach_share(at: Vector2) -> float:
	return at.distance_to(world_center_xz) / maxf(world_radius_m, 0.001)
