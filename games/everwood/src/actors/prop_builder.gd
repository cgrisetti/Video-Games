## Builds the look of equipment and projectiles: the item's model when it has
## one, otherwise its greybox parts. Small props cast no shadows.
class_name PropBuilder
extends RefCounted

const CYLINDER_SEGMENTS: int = 12
const PROP_ROUGHNESS: float = 0.6


static func build(parts: Array[PropPartResource], model: PackedScene, node_name: String) -> Node3D:
	if model != null:
		var art: Node3D = model.instantiate() as Node3D
		if art != null:
			art.name = node_name
			return art
	var root: Node3D = Node3D.new()
	root.name = node_name
	for index: int in parts.size():
		var piece: MeshInstance3D = build_part(parts[index])
		piece.name = "Part%d" % index
		root.add_child(piece)
	return root


static func build_part(part: PropPartResource) -> MeshInstance3D:
	var mesh: PrimitiveMesh
	match part.shape:
		PropPartResource.Shape.CYLINDER:
			var cylinder: CylinderMesh = CylinderMesh.new()
			cylinder.bottom_radius = part.size.x
			cylinder.height = part.size.y
			cylinder.top_radius = part.size.z
			cylinder.radial_segments = CYLINDER_SEGMENTS
			mesh = cylinder
		PropPartResource.Shape.SPHERE:
			var sphere: SphereMesh = SphereMesh.new()
			sphere.radius = part.size.x
			sphere.height = part.size.x * 2.0
			mesh = sphere
		_:
			var box: BoxMesh = BoxMesh.new()
			box.size = part.size
			mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = part.color
	material.roughness = PROP_ROUGHNESS
	if part.glow > 0.0:
		material.emission_enabled = true
		material.emission = part.color
		material.emission_energy_multiplier = part.glow
	mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = part.offset
	instance.rotation_degrees = part.rotation_degrees
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
