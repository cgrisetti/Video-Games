## A hero's storybook puppet (07_EXPEDITION_HUD_AND_ART_GDD.md §4.1), built in code
## from simple shapes in the storybook cel look, so every Fellowship reads at a
## glance from the split-screen camera:
##   the Shield-Sworn   a crested warden helm, broad pauldrons in plate, a heavy
##                      cape and a banded oak-and-brass Greatshield
##   the Wayfarers      a feathered ranger hood, a travel cloak that streams out
##                      as they run, and a quiver (with a bow) or a Scribe Satchel
##   the Lantern-Bearers a pointed scribe hat, a mantle and a swinging brass
##                      Tether-Lantern that really glows
## Armor shows by weight (a sash, a leather jerkin, or plate), trimmed in the
## Calling's colour; the weapon in the right hand comes from its item (PropBuilder).
##
## Drop a model at res://assets/models/<class_id>.glb (say, a CC0 KayKit or
## Quaternius character named shield_tank.glb) and it's used instead of the
## procedural body.
class_name ActorVisuals
extends Node3D

const MODEL_FOLDER: String = "res://assets/models/"
const SKIN_COLOR: Color = Color(0.96, 0.8, 0.66)
const TROUSER_COLOR: Color = Color(0.3, 0.26, 0.24)
const LEATHER_COLOR: Color = Color(0.45, 0.3, 0.18)
const METAL_COLOR: Color = Color(0.66, 0.68, 0.72)
const BRASS_COLOR: Color = Color(0.88, 0.68, 0.3)
const OAK_COLOR: Color = Color(0.46, 0.31, 0.18)
const EYE_COLOR: Color = Color(0.12, 0.1, 0.1)
const LANTERN_GLOW: Color = Color(1.0, 0.78, 0.4)
## Cape length per Fellowship: a heavy oilskin, a travel cloak, a short mantle.
const CAPE_LENGTHS: Array[float] = [1.0, 0.9, 0.6]
## The cape lifts back this far (radians) at full running speed...
const CAPE_SWING: float = 0.95
## ...hangs with this tilt at rest, and follows this quickly.
const CAPE_REST: float = 0.1
const CAPE_SHARPNESS: float = 8.0
const LANTERN_SWAY: float = 0.25

var actor: ActorBase
## Every cel material on the puppet, lit together by a hit flash.
var materials: Array[Material] = []
## A dropped-in .glb model in use instead of the procedural body, if there is one.
var model: Node3D

var _cape_pivot: Node3D
var _lantern: Node3D
var _age: float = 0.0


static func model_path(id: StringName) -> String:
	return MODEL_FOLDER + String(id) + ".glb"


## Whether a model was dropped in for this class, item or creature id.
static func has_model(id: StringName) -> bool:
	return id != &"" and ResourceLoader.exists(model_path(id))


## The dropped-in model for `id`, ready to add, or null.
static func load_model(id: StringName) -> Node3D:
	if not has_model(id):
		return null
	var scene: PackedScene = load(model_path(id)) as PackedScene
	return scene.instantiate() as Node3D if scene != null else null


func setup(for_actor: ActorBase) -> void:
	actor = for_actor
	name = "Puppet"


func _ready() -> void:
	rebuild()


## Builds the puppet for the actor's current loadout (again after a Scribe Desk swap or a new Calling).
func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	materials.clear()
	_cape_pivot = null
	_lantern = null
	model = load_model(actor.loadout.class_id)
	if model != null:
		add_child(model)
		return
	var loadout: ClassLoadoutResource = actor.loadout
	var row: int = Callings.fellowship_row(loadout.class_id)
	# Trim in the Secondary Calling's colour (its SecondaryCallingResource).
	var calling: SecondaryCallingResource = Callings.secondary(Callings.resolve(loadout.class_id, loadout.calling))
	var trim: Color = calling.trim_color if calling != null else Color.WHITE
	var body: Color = loadout.body_color
	var weight: EquipmentItemResource.ArmorWeight = loadout.armor.armor_weight if loadout.armor != null else EquipmentItemResource.ArmorWeight.MEDIUM
	_build_body(body)
	_build_armor(weight, body, trim)
	_build_head(row, body, trim)
	_build_cape(row, body, trim)
	_build_off_hand(row, loadout, trim)


## Lights the whole puppet (a hit flash or flow glow); black turns it off.
func set_glow(color: Color) -> void:
	for material: Material in materials:
		StorybookMaterial.set_glow(material, color)


## The cape streams back with speed; the lantern swings.
func update_motion(delta: float, velocity: Vector3, move_speed: float) -> void:
	_age += delta
	if _cape_pivot != null:
		var run: float = clampf(Vector2(velocity.x, velocity.z).length() / maxf(0.1, move_speed), 0.0, 1.0)
		var wanted: float = CAPE_REST + CAPE_SWING * run + sin(_age * 3.0) * 0.04
		_cape_pivot.rotation.x = lerpf(_cape_pivot.rotation.x, wanted, 1.0 - exp(-CAPE_SHARPNESS * delta))
	if _lantern != null:
		_lantern.rotation.z = sin(_age * 2.4) * LANTERN_SWAY * 0.4
		_lantern.rotation.x = sin(_age * 1.7) * LANTERN_SWAY * 0.3


# --- Parts ------------------------------------------------------------------

func _build_body(body: Color) -> void:
	var trousers: Material = _cel(TROUSER_COLOR, body)
	for side: float in [-1.0, 1.0]:
		add_child(_capsule("Leg", 0.11, 0.8, Vector3(side * 0.14, 0.4, 0.0), trousers))
		add_child(_box("Boot", Vector3(0.16, 0.12, 0.26), Vector3(side * 0.14, 0.06, -0.04), _cel(LEATHER_COLOR.darkened(0.3), body)))
	var tunic: Material = _cel(body, body)
	add_child(_cylinder("Tunic", 0.31, 0.37, 0.72, Vector3(0.0, 1.06, 0.0), tunic))
	add_child(_cylinder("Skirt", 0.39, 0.35, 0.26, Vector3(0.0, 0.68, 0.0), _cel(body.darkened(0.2), body)))
	add_child(_cylinder("Belt", 0.38, 0.38, 0.08, Vector3(0.0, 0.82, 0.0), _cel(LEATHER_COLOR, body)))
	add_child(_box("Buckle", Vector3(0.1, 0.08, 0.04), Vector3(0.0, 0.82, -0.38), _cel(BRASS_COLOR, body)))
	# Arms: the right reaches forward to the weapon's grip, the left hangs to the off hand.
	var sleeve: Material = _cel(body.darkened(0.08), body)
	var right: Node3D = _pivot("RightArm", Vector3(0.39, 1.36, 0.0), Vector3(-0.95, 0.0, 0.12))
	right.add_child(_capsule("Sleeve", 0.08, 0.6, Vector3(0.0, -0.28, 0.0), sleeve))
	right.add_child(_sphere("Hand", 0.07, Vector3(0.0, -0.6, 0.0), _cel(SKIN_COLOR, body)))
	var left: Node3D = _pivot("LeftArm", Vector3(-0.39, 1.36, 0.0), Vector3(-0.35, 0.0, -0.15))
	left.add_child(_capsule("Sleeve", 0.08, 0.6, Vector3(0.0, -0.28, 0.0), sleeve))
	left.add_child(_sphere("Hand", 0.07, Vector3(0.0, -0.6, 0.0), _cel(SKIN_COLOR, body)))


func _build_armor(weight: EquipmentItemResource.ArmorWeight, body: Color, trim: Color) -> void:
	match weight:
		EquipmentItemResource.ArmorWeight.LIGHT:
			var sash: MeshInstance3D = _box("Sash", Vector3(0.09, 0.82, 0.05), Vector3(0.0, 1.08, -0.33), _cel(trim, body))
			sash.rotation = Vector3(0.0, 0.0, 0.62)
			add_child(sash)
		EquipmentItemResource.ArmorWeight.MEDIUM:
			add_child(_cylinder("Jerkin", 0.34, 0.39, 0.5, Vector3(0.0, 1.12, 0.0), _cel(LEATHER_COLOR, body)))
			add_child(_cylinder("JerkinTrim", 0.35, 0.35, 0.05, Vector3(0.0, 1.36, 0.0), _cel(trim, body)))
		EquipmentItemResource.ArmorWeight.HEAVY:
			var metal: Material = _cel(METAL_COLOR, body)
			add_child(_box("Breastplate", Vector3(0.6, 0.52, 0.14), Vector3(0.0, 1.12, -0.29), metal))
			for side: float in [-1.0, 1.0]:
				var pauldron: MeshInstance3D = _sphere("Pauldron", 0.22, Vector3(side * 0.42, 1.4, 0.0), metal)
				pauldron.scale = Vector3(1.15, 0.7, 1.2)
				add_child(pauldron)
				add_child(_torus("PauldronTrim", 0.2, 0.24, Vector3(side * 0.42, 1.36, 0.0), _cel(trim, body)))


func _build_head(row: int, body: Color, trim: Color) -> void:
	add_child(_sphere("Head", 0.21, Vector3(0.0, 1.62, 0.0), _cel(SKIN_COLOR, body)))
	# Two dark eyes show which way the hero faces.
	var eyes: StandardMaterial3D = StandardMaterial3D.new()
	eyes.albedo_color = EYE_COLOR
	for side: float in [-1.0, 1.0]:
		add_child(_sphere("Eye", 0.035, Vector3(side * 0.075, 1.65, -0.19), eyes))
	match row:
		0:
			var metal: Material = _cel(METAL_COLOR, body)
			add_child(_cylinder("Helm", 0.23, 0.23, 0.16, Vector3(0.0, 1.71, 0.0), metal))
			var dome: MeshInstance3D = _sphere("Dome", 0.23, Vector3(0.0, 1.78, 0.0), metal)
			dome.scale = Vector3(1.0, 0.72, 1.0)
			add_child(dome)
			add_child(_box("Crest", Vector3(0.06, 0.18, 0.4), Vector3(0.0, 1.98, 0.02), _cel(trim, body)))
		1:
			var hood: MeshInstance3D = _sphere("Hood", 0.26, Vector3(0.0, 1.68, 0.04), _cel(body.darkened(0.25), body))
			hood.scale = Vector3(1.0, 1.08, 1.05)
			add_child(hood)
			add_child(_cone("HoodTip", 0.12, 0.3, Vector3(0.0, 1.82, 0.24), Vector3(-1.0, 0.0, 0.0), _cel(body.darkened(0.25), body)))
			var feather: MeshInstance3D = _box("Feather", Vector3(0.03, 0.34, 0.07), Vector3(0.21, 1.86, 0.05), _cel(trim, body))
			feather.rotation = Vector3(0.0, 0.0, -0.45)
			add_child(feather)
		_:
			var hat: Material = _cel(body.darkened(0.3), body)
			add_child(_cylinder("Brim", 0.34, 0.34, 0.03, Vector3(0.0, 1.78, 0.0), hat))
			add_child(_cone("Hat", 0.2, 0.5, Vector3(0.0, 2.04, 0.04), Vector3(-0.18, 0.0, 0.0), hat))
			add_child(_cylinder("HatBand", 0.205, 0.205, 0.05, Vector3(0.0, 1.82, 0.0), _cel(trim, body)))


func _build_cape(row: int, body: Color, trim: Color) -> void:
	var length: float = CAPE_LENGTHS[row]
	_cape_pivot = _pivot("Cape", Vector3(0.0, 1.44, 0.27), Vector3(CAPE_REST, 0.0, 0.0))
	_cape_pivot.add_child(_box("Cloth", Vector3(0.62, length, 0.04), Vector3(0.0, -length * 0.5, 0.0), _cel(body.darkened(0.35), body)))
	_cape_pivot.add_child(_box("Hem", Vector3(0.62, 0.06, 0.05), Vector3(0.0, -length + 0.03, 0.0), _cel(trim, body)))


func _build_off_hand(row: int, loadout: ClassLoadoutResource, trim: Color) -> void:
	var body: Color = loadout.body_color
	match row:
		0:
			# The banded oak-and-brass Greatshield on the left arm.
			var shield: Node3D = _pivot("Greatshield", Vector3(-0.5, 1.0, -0.12), Vector3(0.0, 0.22, 0.0))
			shield.add_child(_box("Board", Vector3(0.08, 0.95, 0.7), Vector3.ZERO, _cel(OAK_COLOR, body)))
			for y: float in [-0.28, 0.28]:
				shield.add_child(_box("Band", Vector3(0.1, 0.07, 0.72), Vector3(0.0, y, 0.0), _cel(BRASS_COLOR, body)))
			shield.add_child(_sphere("Boss", 0.09, Vector3(-0.05, 0.0, 0.0), _cel(BRASS_COLOR, body)))
			shield.add_child(_box("Emblem", Vector3(0.1, 0.22, 0.22), Vector3(-0.02, 0.0, 0.0), _cel(trim, body)))
		2:
			# The brass Tether-Lantern swinging from the left hand, really glowing.
			_lantern = _pivot("TetherLantern", Vector3(-0.47, 0.82, -0.18), Vector3.ZERO)
			_lantern.add_child(_cylinder("Cord", 0.012, 0.012, 0.22, Vector3(0.0, -0.11, 0.0), _cel(LEATHER_COLOR, body)))
			_lantern.add_child(_cylinder("Cage", 0.09, 0.11, 0.22, Vector3(0.0, -0.33, 0.0), _cel(BRASS_COLOR, body)))
			var flame: MeshInstance3D = _sphere("Flame", 0.065, Vector3(0.0, -0.33, 0.0), StorybookMaterial.glowing(LANTERN_GLOW, 3.0))
			flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_lantern.add_child(flame)
			_lantern.add_child(_cone("Cap", 0.11, 0.1, Vector3(0.0, -0.18, 0.0), Vector3.ZERO, _cel(BRASS_COLOR, body)))
			var light: OmniLight3D = OmniLight3D.new()
			light.name = "Light"
			light.light_color = LANTERN_GLOW
			light.light_energy = 0.8
			light.omni_range = 3.0
			light.position = Vector3(0.0, -0.33, 0.0)
			_lantern.add_child(light)
		_:
			if loadout.is_ranged():
				# A quiver on the back, arrows fletched in the Calling's colour.
				var quiver: Node3D = _pivot("Quiver", Vector3(0.16, 1.18, 0.3), Vector3(0.0, 0.0, -0.35))
				quiver.add_child(_cylinder("Case", 0.09, 0.08, 0.6, Vector3.ZERO, _cel(LEATHER_COLOR, body)))
				for index: int in 3:
					quiver.add_child(_box("Fletch", Vector3(0.03, 0.12, 0.05), Vector3((float(index) - 1.0) * 0.04, 0.36, 0.0), _cel(trim, body)))
			else:
				var satchel: Node3D = _pivot("ScribeSatchel", Vector3(0.36, 0.86, 0.06), Vector3.ZERO)
				satchel.add_child(_box("Bag", Vector3(0.12, 0.24, 0.28), Vector3.ZERO, _cel(LEATHER_COLOR, body)))
				satchel.add_child(_box("Flap", Vector3(0.13, 0.08, 0.29), Vector3(0.0, 0.1, 0.0), _cel(trim, body)))


# --- Shape helpers ----------------------------------------------------------

## A cel material rimmed in the hero's colour, remembered for hit flashes.
func _cel(color: Color, rim: Color) -> Material:
	var material: ShaderMaterial = StorybookMaterial.actor(color, rim)
	materials.append(material)
	return material


func _pivot(pivot_name: String, where: Vector3, rotation_radians: Vector3) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = pivot_name
	pivot.position = where
	pivot.rotation = rotation_radians
	add_child(pivot)
	return pivot


func _mesh(part_name: String, mesh: PrimitiveMesh, where: Vector3, material: Material) -> MeshInstance3D:
	mesh.material = material
	var node: MeshInstance3D = MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	node.position = where
	return node


func _box(part_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _mesh(part_name, mesh, where, material)


func _sphere(part_name: String, radius: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _mesh(part_name, mesh, where, material)


func _capsule(part_name: String, radius: float, height: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	return _mesh(part_name, mesh, where, material)


func _cylinder(part_name: String, top: float, bottom: float, height: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 16
	return _mesh(part_name, mesh, where, material)


func _cone(part_name: String, radius: float, height: float, where: Vector3, tilt: Vector3, material: Material) -> MeshInstance3D:
	var cone: MeshInstance3D = _cylinder(part_name, 0.0, radius, height, where, material)
	cone.rotation = tilt
	return cone


func _torus(part_name: String, inner: float, outer: float, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 16
	mesh.ring_segments = 8
	return _mesh(part_name, mesh, where, material)
