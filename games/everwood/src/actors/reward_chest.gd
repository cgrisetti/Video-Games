## The reward chest the Dojo Warden leaves behind. It drops into the arena,
## and the first person (not an AI companion) to walk up to it opens it: the
## lid swings up, a burst of gold, and the party's Dojo Shards are paid out
## (DungeonDojo).
## Every peer shows the chest; the host decides when it opens.
class_name RewardChest
extends Node3D

signal opened(opener_id: StringName, shards: int)

## Walking this close opens it.
const OPEN_RADIUS: float = 2.0
## It can't be opened until it has landed and sat for a moment (game seconds),
## so a player standing where it lands still sees it arrive.
const ARM_TIME: float = 1.2
const BODY_SIZE: Vector3 = Vector3(1.4, 0.8, 0.9)
const LID_SIZE: Vector3 = Vector3(1.46, 0.3, 0.96)
const WOOD_COLOR: Color = Color(0.45, 0.28, 0.15)
const TRIM_COLOR: Color = Color(1.0, 0.8, 0.3)
const DROP_HEIGHT: float = 4.0
const DROP_TIME: float = 0.5
const LID_OPEN_ANGLE: float = -1.9
const LID_OPEN_TIME: float = 0.4
const CRYSTAL_HEIGHT: float = 1.6
const CRYSTAL_SPIN: float = 1.5
const CRYSTAL_BOB: float = 2.2
const LIGHT_ENERGY: float = 2.0
const LIGHT_RANGE: float = 6.0

var shards: int = 0
var is_open: bool = false

var _age: float = 0.0
var _model: Node3D
var _lid: Node3D
var _crystal: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	var wood: StandardMaterial3D = _material(WOOD_COLOR, 0.0)
	var trim: StandardMaterial3D = _material(TRIM_COLOR, 1.2)
	_model.add_child(_box("Body", BODY_SIZE, Vector3(0.0, BODY_SIZE.y * 0.5, 0.0), wood))
	_model.add_child(_box("Band", Vector3(BODY_SIZE.x + 0.04, 0.12, BODY_SIZE.z + 0.04), Vector3(0.0, BODY_SIZE.y * 0.55, 0.0), trim))
	# The lid hinges on the back edge, so it swings up and away from the party.
	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = Vector3(0.0, BODY_SIZE.y, BODY_SIZE.z * 0.5)
	_model.add_child(_lid)
	_lid.add_child(_box("Top", LID_SIZE, Vector3(0.0, LID_SIZE.y * 0.5, -LID_SIZE.z * 0.5), wood))
	_lid.add_child(_box("Clasp", Vector3(0.24, 0.24, 0.06), Vector3(0.0, 0.0, -LID_SIZE.z - 0.02), trim))
	# A Dojo Shard floats above it: a gem made from a box turned on its corner.
	_crystal = MeshInstance3D.new()
	_crystal.name = "Shard"
	var gem: BoxMesh = BoxMesh.new()
	gem.size = Vector3(0.36, 0.36, 0.36)
	gem.material = _material(Color(0.55, 0.85, 1.0), 2.5)
	_crystal.mesh = gem
	_crystal.rotation = Vector3(PI * 0.25, 0.0, PI * 0.25)
	_crystal.position = Vector3(0.0, CRYSTAL_HEIGHT, 0.0)
	_model.add_child(_crystal)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = TRIM_COLOR
	glow.light_energy = LIGHT_ENERGY
	glow.omni_range = LIGHT_RANGE
	glow.position = Vector3(0.0, 1.2, 0.0)
	_model.add_child(glow)
	_label = Label3D.new()
	_label.name = "Label"
	_label.text = "Reward Chest\nwalk up to open"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 44
	_label.outline_size = 10
	_label.pixel_size = 0.01
	_label.modulate = TRIM_COLOR.lightened(0.3)
	_label.position = Vector3(0.0, CRYSTAL_HEIGHT + 0.8, 0.0)
	add_child(_label)
	# Drop in from above with a bounce.
	_model.position = Vector3(0.0, DROP_HEIGHT, 0.0)
	var drop: Tween = create_tween()
	drop.tween_property(_model, "position:y", 0.0, DROP_TIME).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	_age += delta
	_crystal.rotate_y(CRYSTAL_SPIN * delta)
	_crystal.position.y = CRYSTAL_HEIGHT + sin(_age * CRYSTAL_BOB) * 0.15
	if is_open or _age < ARM_TIME or not NetworkManager.current.is_host() or not InstanceManager.current.is_live():
		return
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.is_companion:
			continue
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		if flat.length() <= OPEN_RADIUS:
			_open(String(member.player_id), shards)
			for peer_id: int in InstanceManager.current.live_remote_peers():
				_open.rpc_id(peer_id, String(member.player_id), shards)
			return


## Runs on every peer: the lid opens and the shards pop out.
@rpc("authority", "call_local", "reliable")
func _open(opener_id: String, amount: int) -> void:
	if is_open:
		return
	is_open = true
	shards = amount
	var swing: Tween = create_tween()
	swing.tween_property(_lid, "rotation:x", LID_OPEN_ANGLE, LID_OPEN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_label.text = "+%d Dojo Shards" % amount
	var burst: CueBurst = CueBurst.new()
	burst.configure(TRIM_COLOR)
	add_child(burst)
	AudioCues.play(&"chest")
	opened.emit(StringName(opener_id), amount)


func _box(box_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var box: MeshInstance3D = MeshInstance3D.new()
	box.name = box_name
	box.mesh = mesh
	box.position = where
	return box


func _material(color: Color, glow: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material
