## One of the four load seams between Caldera island grids (docs/20 Part I §3):
## a 128 m corridor whose first half lies in island A's grid and whose second
## half lies in island B's. Skin A is a walkable causeway or shingle spit the
## party crosses in sea-fog; Skin B is a Lantern-Skiff bell lane glided in six
## seconds. Both ends use one frame direction, so crossing is a translation:
## a point in A's frame maps to B's by adding remap_offset(A).
##
## Corridor coordinate s runs 0 at A's shore to length_m at B's shore; the
## swap happens at s = length_m / 2, inside the thickest fog.
class_name LoadSeamResource
extends Resource

enum SeamSkin { WALKABLE_CAUSEWAY, LANTERN_SKIFF }

@export var seam_id: StringName = &""
@export var display_name: String = ""
@export var skin: SeamSkin = SeamSkin.WALKABLE_CAUSEWAY
## Eel Spit's look: low shingle instead of a dressed stone causeway.
@export var shingle: bool = false
## Oakshire Holm's side.
@export var isle_a: StringName = &""
@export var isle_b: StringName = &""
## The shore end (or the pier head a skiff leaves) in each island's own frame.
@export var anchor_a: Vector3 = Vector3.ZERO
@export var anchor_b: Vector3 = Vector3.ZERO
## Travel direction from A to B, in x-z (unit).
@export var direction: Vector2 = Vector2(0.0, -1.0)
@export var length_m: float = 128.0
## The CalderaWorldState flag that opens it (&"crown_landing" means can_land_on_crown()).
@export var gate_flag: StringName = &""
## The line a closed lane shows.
@export var closed_line: String = ""


func touches(isle: StringName) -> bool:
	return isle == isle_a or isle == isle_b


func other(isle: StringName) -> StringName:
	return isle_b if isle == isle_a else isle_a


func direction_3d() -> Vector3:
	return Vector3(direction.x, 0.0, direction.y).normalized()


## The shore end on `isle`.
func anchor(isle: StringName) -> Vector3:
	return anchor_a if isle == isle_a else anchor_b


## Out to sea from `isle`'s shore along the corridor.
func out_direction(isle: StringName) -> Vector3:
	return direction_3d() if isle == isle_a else -direction_3d()


## Where the corridor's middle (the swap) lies in `isle`'s frame.
func midpoint(isle: StringName) -> Vector3:
	return anchor(isle) + out_direction(isle) * length_m * 0.5


## The corridor point s (0 at A's shore) in `isle`'s frame.
func point_at(isle: StringName, s: float) -> Vector3:
	if isle == isle_a:
		return anchor_a + direction_3d() * s
	return anchor_b - direction_3d() * (length_m - s)


## How far along the corridor (0 at A's shore) a point in `isle`'s frame is.
func corridor_s(isle: StringName, at: Vector3) -> float:
	if isle == isle_a:
		return (at - anchor_a).dot(direction_3d())
	return length_m + (at - anchor_b).dot(direction_3d())


## How far a point in `isle`'s frame lies to the side of the corridor's line.
func corridor_offset(isle: StringName, at: Vector3) -> float:
	var flat: Vector3 = at - anchor(isle)
	flat.y = 0.0
	var along: Vector3 = direction_3d() * flat.dot(direction_3d())
	return (flat - along).length()


## Add this to a point in `from_isle`'s frame to get the same point in the other island's.
func remap_offset(from_isle: StringName) -> Vector3:
	var shift: Vector3 = midpoint(other(from_isle)) - midpoint(from_isle)
	shift.y = 0.0
	return shift
