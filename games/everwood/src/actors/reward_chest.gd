## A chest of Chimes and a collectible Scribe Card: the reward chest the
## Cairnsman leaves behind (it drops in with a bounce), or the Wayfarer's
## Chest waiting in the Moss-Oaks' side alcove. The first person (not an AI
## companion) to walk up to it opens it: the lid swings up, brass Chimes burst
## out and fly to the party, and the level pays out the Chimes and the card.
## Every peer shows the chest; the host decides when it opens. An opened chest
## is remembered (WorldStateDB): it comes back open, with nothing more inside.
class_name RewardChest
extends Node3D

signal opened(opener_id: StringName, chimes: int, card_key: StringName)

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
const COIN_SIZE: float = 0.55
const COIN_HEIGHT: float = 1.6
const COIN_SPIN: float = 1.5
const COIN_BOB: float = 2.2
const LIGHT_ENERGY: float = 2.0
const LIGHT_RANGE: float = 6.0

var chimes: int = 0
## The card copy inside (the host rolled it when the boss fell, or rolls it on opening).
var card_key: StringName = &""
## What the floating label calls it.
var title: String = "Reward Chest"
## Drops in from above with a bounce (the boss's chest); false sits there already.
var drop_in: bool = true
## Host: rolls the card copy the moment the chest opens, if `card_key` is still empty.
var card_roller: Callable
var is_open: bool = false
var persistence: WorldStateBinding

var _age: float = 0.0
var _model: Node3D
var _lid: Node3D
var _coin: MeshInstance3D
var _label: Label3D
var _drop: Tween
var _pending_state: Dictionary = {}


func _ready() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	var wood: Material = _material(WOOD_COLOR, 0.0)
	var trim: Material = _material(TRIM_COLOR, 1.2)
	_model.add_child(ShapeKit.box("Body", BODY_SIZE, Vector3(0.0, BODY_SIZE.y * 0.5, 0.0), wood))
	_model.add_child(ShapeKit.box("Band", Vector3(BODY_SIZE.x + 0.04, 0.12, BODY_SIZE.z + 0.04), Vector3(0.0, BODY_SIZE.y * 0.55, 0.0), trim))
	# The lid hinges on the back edge, so it swings up and away from the party.
	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = Vector3(0.0, BODY_SIZE.y, BODY_SIZE.z * 0.5)
	_model.add_child(_lid)
	_lid.add_child(ShapeKit.box("Top", LID_SIZE, Vector3(0.0, LID_SIZE.y * 0.5, -LID_SIZE.z * 0.5), wood))
	_lid.add_child(ShapeKit.box("Clasp", Vector3(0.24, 0.24, 0.06), Vector3(0.0, 0.0, -LID_SIZE.z - 0.02), trim))
	# A brass Chime turns above it.
	_coin = ChimeCoin.make(COIN_SIZE)
	_coin.position = Vector3(0.0, COIN_HEIGHT, 0.0)
	_model.add_child(_coin)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = TRIM_COLOR
	glow.light_energy = LIGHT_ENERGY
	glow.omni_range = LIGHT_RANGE
	glow.position = Vector3(0.0, 1.2, 0.0)
	_model.add_child(glow)
	_label = Label3D.new()
	_label.name = "Label"
	_label.text = "%s\nwalk up to open" % title
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 44
	_label.outline_size = 10
	_label.pixel_size = 0.01
	_label.modulate = TRIM_COLOR.lightened(0.3)
	_label.position = Vector3(0.0, COIN_HEIGHT + 0.8, 0.0)
	add_child(_label)
	if drop_in:
		# Drop in from above with a bounce.
		_model.position = Vector3(0.0, DROP_HEIGHT, 0.0)
		_drop = create_tween()
		_drop.tween_property(_model, "position:y", 0.0, DROP_TIME).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if not _pending_state.is_empty():
		apply_persisted_state(_pending_state)


func _physics_process(delta: float) -> void:
	_age += delta
	_coin.rotate_y(COIN_SPIN * delta)
	_coin.position.y = COIN_HEIGHT + sin(_age * COIN_BOB) * 0.15
	if is_open or _age < ARM_TIME or not NetworkManager.current.is_host() or not InstanceManager.current.is_live():
		return
	for member: ActorBase in CombatDirector.current.alive_party():
		if member.is_companion:
			continue
		var flat: Vector2 = Vector2(member.global_position.x - global_position.x, member.global_position.z - global_position.z)
		if flat.length() <= OPEN_RADIUS:
			if card_key == &"" and card_roller.is_valid():
				card_key = StringName(str(card_roller.call()))
			_open(String(member.player_id), chimes, String(card_key))
			for peer_id: int in InstanceManager.current.live_remote_peers():
				_open.rpc_id(peer_id, String(member.player_id), chimes, String(card_key))
			return


## Runs on every peer: the lid opens and the Chimes fly out to the party.
@rpc("authority", "call_local", "reliable")
func _open(opener_id: String, amount: int, card: String) -> void:
	if is_open:
		return
	is_open = true
	chimes = amount
	card_key = StringName(card)
	var swing: Tween = create_tween()
	swing.tween_property(_lid, "rotation:x", LID_OPEN_ANGLE, LID_OPEN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_label.text = "+%d Chimes\n%s" % [amount, ArsenalCatalog.current.copy_name(card_key)]
	_coin.visible = false
	var burst: CueBurst = CueBurst.new()
	burst.configure(TRIM_COLOR)
	add_child(burst)
	var coins: ChimeBurst = ChimeBurst.new()
	var catchers: Array[Node3D] = []
	for member: ActorBase in CombatDirector.current.alive_party():
		catchers.append(member)
	coins.configure(amount, catchers)
	add_child(coins)
	coins.position = Vector3(0.0, BODY_SIZE.y, 0.0)
	AudioCues.play(&"chest")
	if persistence != null:
		persistence.save({"opened": true, "opener": opener_id, "chimes": amount, "card": card})
	opened.emit(StringName(opener_id), amount, card_key)


## WorldStateDB hands over its line to the store, and the state on record applies at once.
func bind_persistence(binding: WorldStateBinding) -> void:
	persistence = binding
	apply_persisted_state(binding.current_state())


## A chest on record as opened shows open (lid up, its Chimes and card named)
## without paying out, bursting or chiming again.
func apply_persisted_state(state: Dictionary) -> void:
	if not bool(state.get("opened", false)) or is_open:
		return
	if not is_node_ready():
		_pending_state = state
		return
	is_open = true
	chimes = int(state.get("chimes", chimes))
	card_key = StringName(str(state.get("card", String(card_key))))
	if _drop != null:
		_drop.kill()
	_model.position = Vector3.ZERO
	_lid.rotation.x = LID_OPEN_ANGLE
	_coin.visible = false
	_label.text = "+%d Chimes\n%s" % [chimes, ArsenalCatalog.current.copy_name(card_key)] if card_key != &"" else "Opened"


## The storybook cel look, or a glowing material when `glow` is above zero.
func _material(color: Color, glow: float) -> Material:
	return StorybookMaterial.glowing(color, glow) if glow > 0.0 else StorybookMaterial.make(color)
