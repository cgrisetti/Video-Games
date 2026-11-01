## One greybox piece of a prop (a blade, a buckler, a bowstring, an arrow
## head), placed in its owner's space with -Z forward. Equipment and
## projectiles are drawn from lists of these until they get real models.
class_name PropPartResource
extends Resource

enum Shape { BOX, CYLINDER, SPHERE }

@export var shape: Shape = Shape.BOX
## BOX: the size. CYLINDER: x = bottom radius, y = height, z = top radius. SPHERE: x = radius.
@export var size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var offset: Vector3 = Vector3.ZERO
@export var rotation_degrees: Vector3 = Vector3.ZERO
@export var color: Color = Color.WHITE
## Emission strength; 0 is a plain, unlit-looking material.
@export var glow: float = 0.0


static func make(part_shape: Shape, part_size: Vector3, part_offset: Vector3, part_color: Color,
		part_rotation: Vector3 = Vector3.ZERO, part_glow: float = 0.0) -> PropPartResource:
	var part: PropPartResource = PropPartResource.new()
	part.shape = part_shape
	part.size = part_size
	part.offset = part_offset
	part.color = part_color
	part.rotation_degrees = part_rotation
	part.glow = part_glow
	return part
