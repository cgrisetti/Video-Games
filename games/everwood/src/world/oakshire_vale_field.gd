## Oakshire Vale's ground, baked (tools/build_oakshire_vale.gd): the field's
## height and colour every 2 m over the whole zone, `side` samples to a side
## (heights as floats, colours as 3 bytes each). OakshireValeLayout reads it so
## streaming never works out the landforms sample by sample.
class_name OakshireValeField
extends Resource

@export var side: int = 0
@export var heights: PackedFloat32Array = PackedFloat32Array()
@export var colors: PackedByteArray = PackedByteArray()
