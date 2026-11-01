## Simple named shapes for everything built in code: hero puppets, props,
## interactables and scenery (08 Stage 5, the Rule of Three: these were copied
## into a dozen scripts). Each returns a MeshInstance3D at a position with its
## material on the mesh, ready to add as a child.
class_name ShapeKit
extends RefCounted

const SEGMENTS: int = 16


static func box(part_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return node(part_name, mesh, where, material)


## A cylinder, or a cone or tapered post when `top` and `bottom` differ.
static func cylinder(part_name: String, top: float, bottom: float, height: float, where: Vector3, material: Material,
		segments: int = SEGMENTS) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	return node(part_name, mesh, where, material)


## A cone pointing up (+Y).
static func cone(part_name: String, radius: float, height: float, where: Vector3, material: Material) -> MeshInstance3D:
	return cylinder(part_name, 0.0, radius, height, where, material)


static func sphere(part_name: String, radius: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = SEGMENTS
	mesh.rings = SEGMENTS / 2
	return node(part_name, mesh, where, material)


static func capsule(part_name: String, radius: float, height: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	return node(part_name, mesh, where, material)


static func torus(part_name: String, inner: float, outer: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = SEGMENTS
	mesh.ring_segments = 8
	return node(part_name, mesh, where, material)


## Any primitive mesh as a named, placed node with `material` on the mesh.
static func node(part_name: String, mesh: PrimitiveMesh, where: Vector3, material: Material) -> MeshInstance3D:
	mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = where
	return instance


## Turns a shape (radians) and hands it back, for one-line placing.
static func tilted(shape: MeshInstance3D, rotation_radians: Vector3) -> MeshInstance3D:
	shape.rotation = rotation_radians
	return shape


## Stretches a shape (a squashed sphere, an oval) and hands it back.
static func stretched(shape: MeshInstance3D, scale: Vector3) -> MeshInstance3D:
	shape.scale = scale
	return shape


## Small parts skip casting shadows.
static func no_shadow(shape: MeshInstance3D) -> MeshInstance3D:
	shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return shape
