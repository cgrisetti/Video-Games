## Builds the look of equipment and projectiles: the item's model when it has
## one (or a .glb dropped at res://assets/models/<item_id>.glb), otherwise its
## parts in the storybook cel look. Small props cast no shadows.
class_name PropBuilder
extends RefCounted

const CYLINDER_SEGMENTS: int = 12
## Weapons and gear catch a little more rim light than scenery, so they read in a hand.
const PROP_RIM: float = 0.35


static func build(parts: Array[PropPartResource], model: PackedScene, node_name: String, item_id: StringName = &"") -> Node3D:
	if model != null:
		var art: Node3D = model.instantiate() as Node3D
		if art != null:
			art.name = node_name
			return art
	var dropped: Node3D = ActorVisuals.load_model(item_id)
	if dropped != null:
		dropped.name = node_name
		return dropped
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
	if part.glow > 0.0:
		mesh.material = StorybookMaterial.glowing(part.color, part.glow)
	else:
		var material: ShaderMaterial = StorybookMaterial.make(part.color, PROP_RIM)
		if part.metal > 0.0:
			material.set_shader_parameter(&"metal", part.metal)
			material.set_shader_parameter(&"sheen_roughness", part.sheen_roughness)
		mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = part.offset
	instance.rotation_degrees = part.rotation_degrees
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
