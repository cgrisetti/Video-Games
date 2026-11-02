## The Instance Manager (autoload): which instance (the seamless world, Hub
## Town or a raid) the party is in, and moving everyone between them without
## dropping ENet. It remembers which Bramblebridge the party last stood in
## (the world's or the classic hub's), so a raid's exit portal takes them home.
##
## The host decides. It tells every peer to load the new instance; each peer
## fades out, swaps its scene (the autoloads, and with them the ENet peer and
## the party roster, stay put), seats the party again, and reports back. The
## host keeps a list of peers that have finished loading and shares it, so
## nobody sends actor updates to a peer whose scene isn't there yet. A peer
## that joins later is sent to whatever instance the host is in.
class_name InstanceManager
extends Node

signal instance_changing(instance_id: StringName)
signal instance_live(instance_id: StringName)

const HUB_TOWN: StringName = &"hub_town"
const DUNGEON_DOJO: StringName = &"dungeon_dojo"
## The seamless Landblock world (10_WORLD_ARCHITECTURE.md): Bramblebridge and the
## expedition in one streamed world, the game's start.
const EVERWOOD_WORLD: StringName = &"everwood_world"
const FADE_TIME: float = 0.35
const FADE_LAYER: int = 100

## The live autoload node (see NetworkManager.current for why).
static var current: InstanceManager

var instance_id: StringName = &""
## Where "home" is: the last Bramblebridge loaded (hub_town or everwood_world).
var home_instance: StringName = EVERWOOD_WORLD
## Peers known to have the current instance loaded (the host shares this list).
var live_peers: PackedInt32Array = PackedInt32Array()

var _changing: bool = false
var _loaded: Dictionary[int, bool] = {}
var _announced_live: StringName = &""

var _fade: ColorRect


static func scene_path(id: StringName) -> String:
	match id:
		HUB_TOWN:
			return "res://src/levels/hub_town.tscn"
		DUNGEON_DOJO:
			return "res://src/levels/dungeon_dojo.tscn"
		EVERWOOD_WORLD:
			return "res://src/levels/everwood_world.tscn"
	return ""


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "Fade"
	layer.layer = FADE_LAYER
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


# --- State ----------------------------------------------------------------

func is_changing() -> bool:
	return _changing


## True when this peer's instance is loaded and in step with the host.
func is_live() -> bool:
	if _changing:
		return false
	if NetworkManager.current.is_host():
		return true
	return live_peers.has(NetworkManager.current.local_peer_id())


func is_peer_live(peer_id: int) -> bool:
	if peer_id == NetworkManager.current.local_peer_id():
		return is_live()
	if not NetworkManager.current.is_online():
		return true
	return live_peers.has(peer_id)


## Other peers that can receive actor updates right now (none once offline,
## even if the last host's list is still around).
func live_remote_peers() -> PackedInt32Array:
	var peers: PackedInt32Array = PackedInt32Array()
	if not is_live() or not NetworkManager.current.is_online():
		return peers
	var me: int = NetworkManager.current.local_peer_id()
	for peer_id: int in live_peers:
		if peer_id != me:
			peers.append(peer_id)
	return peers


# --- Changing instance ----------------------------------------------------

## Moves the whole party to another instance. Host only; others ignore it.
func change_instance(id: StringName) -> void:
	if not NetworkManager.current.is_host() or _changing or scene_path(id) == "":
		return
	if NetworkManager.current.is_online():
		_begin_change.rpc(id)
	else:
		_begin_change(id)


@rpc("authority", "call_local", "reliable")
func _begin_change(id: StringName) -> void:
	_changing = true
	instance_id = id
	_announced_live = &""
	live_peers = PackedInt32Array()
	_loaded.clear()
	instance_changing.emit(id)
	print("[Instance] Moving the party to %s" % id)
	AudioCues.play(&"portal")
	var fade_out: Tween = create_tween()
	fade_out.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await fade_out.finished
	if instance_id != id:
		return # A newer change arrived while fading.
	get_tree().change_scene_to_file(scene_path(id))


## Every level calls this from _ready once it has seated the party.
func level_ready(id: StringName) -> void:
	instance_id = id
	_changing = false
	if id == HUB_TOWN or id == EVERWOOD_WORLD:
		home_instance = id
	var fade_in: Tween = create_tween()
	fade_in.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	if NetworkManager.current.is_host():
		_mark_loaded(NetworkManager.current.local_peer_id())
	elif NetworkManager.current.is_online():
		_report_loaded.rpc_id(1, id)


@rpc("any_peer", "call_remote", "reliable")
func _report_loaded(id: StringName) -> void:
	if multiplayer.is_server() and id == instance_id:
		_mark_loaded(multiplayer.get_remote_sender_id())


func _mark_loaded(peer_id: int) -> void:
	_loaded[peer_id] = true
	_publish_live_peers()


func _publish_live_peers() -> void:
	var peers: PackedInt32Array = PackedInt32Array()
	for peer_id: int in _loaded.keys():
		peers.append(peer_id)
	peers.sort()
	print("[Instance] %s loaded on peers %s" % [instance_id, peers])
	_apply_live_peers(instance_id, peers)
	if NetworkManager.current.is_online():
		_receive_live_peers.rpc(instance_id, peers)


@rpc("authority", "call_remote", "reliable")
func _receive_live_peers(id: StringName, peers: PackedInt32Array) -> void:
	if id == instance_id:
		_apply_live_peers(id, peers)


func _apply_live_peers(id: StringName, peers: PackedInt32Array) -> void:
	live_peers = peers
	if is_live() and _announced_live != id:
		_announced_live = id
		print("[Instance] %s is live here" % id)
		instance_live.emit(id)


func _on_peer_connected(peer_id: int) -> void:
	# A newcomer goes wherever the party is.
	if multiplayer.is_server() and instance_id != &"" and not _changing:
		_begin_change.rpc_id(peer_id, instance_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server() and _loaded.erase(peer_id):
		_publish_live_peers()
