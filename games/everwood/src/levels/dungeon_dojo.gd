## The Dungeon Dojo: a greybox raid arena for the first boss.
##
## The scene (built by tools/build_dojo_scene.gd) holds the floor, pillars,
## spawn points and the split-screen grid. This script seats players: it
## listens to the Network Manager's roster and spawns one actor per party
## member, giving local ones a controller, a split-screen view and a HUD.
##
## Keys: Enter / Start joins a controller · F5 host · F6 join · F7 leave.
## Command line (after --): --players=N --mode=master|adventurer|squire
##   --host --join=ADDRESS --demo --screenshot=PATH --screenshot-delay=S --quit-after=S
class_name DungeonDojo
extends Node3D

const DEFAULT_ASSIST_MODE: InputComponent.AssistMode = InputComponent.AssistMode.ADVENTURER
const SCREENSHOT_DELAY: float = 3.0
## Extra rows behind the four spawn pads for a fifth (network) player.
const SPAWN_ROW_SPACING: float = 2.0
# Demo bots (--demo) stand on a ring in front of the boss and attack on a beat.
const DEMO_RING_RADIUS: float = 3.0
const DEMO_ATTACK_EVERY: float = 0.55

@onready var actors_root: Node3D = $Actors
@onready var telegraphs_root: Node3D = $Telegraphs
@onready var effects_root: Node3D = $Effects
@onready var spawn_points: Node3D = $SpawnPoints
@onready var boss_spawn: Marker3D = $BossSpawn
@onready var grid: SplitScreenViewportGrid = $Screens/Grid
@onready var banner: Label = $Screens/Banner

var boss: BossDummy
var actors: Dictionary[StringName, ActorBase] = {}
var huds: Dictionary[StringName, PlayerHUD] = {}

var _join_held: Dictionary[int, bool] = {}
var _keys_held: Dictionary[int, bool] = {}
var _join_address: String = NetworkManager.DEFAULT_ADDRESS
var _assist_mode: InputComponent.AssistMode = DEFAULT_ASSIST_MODE
var _demo: bool = false
var _demo_clock: float = 0.0
var _screenshot_path: String = ""
var _screenshot_delay: float = SCREENSHOT_DELAY
var _quit_after: float = 0.0
var _clock: float = 0.0
var _screenshot_taken: bool = false
var _notice: String = ""
var _telegraphs_seen: int = 0
var _notice_time_left: float = 0.0


func _ready() -> void:
	CombatDirector.current.reset()
	CombatDirector.current.effects_root = effects_root
	NetworkManager.current.class_picker = least_used_class
	grid.set_world(get_world_3d())
	_spawn_boss()
	NetworkManager.current.player_registered.connect(_on_player_registered)
	NetworkManager.current.player_updated.connect(_on_player_updated)
	NetworkManager.current.player_unregistered.connect(_on_player_unregistered)
	NetworkManager.current.registration_refused.connect(_on_registration_refused)
	NetworkManager.current.status_changed.connect(_on_status_changed)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	CombatDirector.current.telegraph_cast.connect(func(_decal: RaidTelegraphDecal) -> void: _telegraphs_seen += 1)
	for existing: PartyMember in NetworkManager.current.ordered_members():
		_on_player_registered(existing)
	_apply_command_line()
	_refresh_banner()


func _process(delta: float) -> void:
	_clock += delta
	_notice_time_left = maxf(0.0, _notice_time_left - delta)
	_poll_drop_in()
	_poll_network_keys()
	if _demo:
		_drive_demo_bots(delta)
	_refresh_banner()
	if _screenshot_path != "" and not _screenshot_taken and _clock >= _screenshot_delay:
		_screenshot_taken = true
		_take_screenshot()
	if _quit_after > 0.0 and _clock >= _quit_after:
		_print_report()
		get_tree().quit()


# --- Seating players ------------------------------------------------------

## Asks the Network Manager for a party seat; the actor appears when it's granted.
func seat_local_player(device_id: int, class_id: StringName, mode: InputComponent.AssistMode) -> void:
	NetworkManager.current.request_local_player(device_id, class_id, mode)


## The class the party has fewest of, so new players balance the trinity.
func least_used_class(roster: Dictionary[StringName, PartyMember]) -> StringName:
	var counts: Dictionary[StringName, int] = {}
	for class_id: StringName in ClassLoadouts.PLAYER_CLASSES:
		counts[class_id] = 0
	for seat: PartyMember in roster.values():
		if counts.has(seat.class_id):
			counts[seat.class_id] += 1
	var best: StringName = ClassLoadouts.PLAYER_CLASSES[0]
	for class_id: StringName in ClassLoadouts.PLAYER_CLASSES:
		if counts[class_id] < counts[best]:
			best = class_id
	return best


func _on_player_registered(seat: PartyMember) -> void:
	if actors.has(seat.player_id):
		return
	var actor: ActorBase = ActorBase.new()
	actor.name = String(seat.player_id)
	actor.loadout = ClassLoadouts.by_id(seat.class_id)
	actor.player_id = seat.player_id
	actor.peer_id = seat.peer_id
	actor.device_id = seat.device_id
	actor.party_slot = seat.slot
	var is_local: bool = seat.peer_id == NetworkManager.current.local_peer_id()
	if is_local:
		actor.attach_input(seat.device_id, seat.assist_mode)
	actor.set_multiplayer_authority(seat.peer_id)
	actors_root.add_child(actor)
	actor.spawn_at(_spawn_transform(seat.slot))
	actors[seat.player_id] = actor
	if is_local:
		actor.input.class_cycle_requested.connect(_on_class_cycle.bind(seat.device_id))
		actor.input.mode_cycle_requested.connect(_on_mode_cycle.bind(seat.device_id))
		var overlay: Control = grid.add_player_view(actor)
		if overlay != null:
			var hud: PlayerHUD = PlayerHUD.new()
			hud.setup(actor)
			overlay.add_child(hud)
			huds[seat.player_id] = hud


func _on_player_updated(seat: PartyMember) -> void:
	var actor: ActorBase = actors.get(seat.player_id) as ActorBase
	if actor == null:
		_on_player_registered(seat)
		return
	if actor.loadout.class_id != seat.class_id:
		# A new class is a new actor, standing where the old one stood.
		var where: Transform3D = actor.global_transform
		_remove_actor(seat.player_id)
		_on_player_registered(seat)
		var replacement: ActorBase = actors[seat.player_id]
		replacement.place_at(where)
		return
	actor.party_slot = seat.slot
	actor.refresh_name_label()
	if actor.input != null and actor.input.assist_mode != seat.assist_mode:
		actor.input.assist_mode = seat.assist_mode as InputComponent.AssistMode
		actor.apply_assist_mode()
		_show_notice("%s: %s mode" % [actor.display_name(), actor.input.mode_name()])


func _on_player_unregistered(player_id: StringName) -> void:
	_remove_actor(player_id)
	if boss != null and boss.threat != null:
		boss.threat.forget(player_id)


func _remove_actor(player_id: StringName) -> void:
	grid.remove_player_view(player_id)
	huds.erase(player_id)
	if not actors.has(player_id):
		return
	var actor: ActorBase = actors[player_id]
	actors.erase(player_id)
	# Out of the tree now, so a replacement can take the same node name (RPC paths).
	actors_root.remove_child(actor)
	actor.queue_free()


func _on_class_cycle(device_id: int) -> void:
	var seat: PartyMember = NetworkManager.current.member(PartyMember.make_player_id(NetworkManager.current.local_peer_id(), device_id))
	if seat != null:
		NetworkManager.current.update_local_player(device_id, ClassLoadouts.next_class(seat.class_id), seat.assist_mode)


func _on_mode_cycle(device_id: int) -> void:
	var seat: PartyMember = NetworkManager.current.member(PartyMember.make_player_id(NetworkManager.current.local_peer_id(), device_id))
	if seat != null:
		NetworkManager.current.update_local_player(device_id, seat.class_id, (seat.assist_mode + 1) % InputComponent.MODE_NAMES.size())


func _on_registration_refused(_device_id: int, reason: String) -> void:
	_show_notice(reason)


func _on_status_changed(text: String) -> void:
	_show_notice(text)


func _on_joy_connection_changed(pad: int, connected: bool) -> void:
	if not connected:
		NetworkManager.current.drop_local_player(pad + 1)


func _spawn_transform(slot: int) -> Transform3D:
	var markers: Array[Node] = spawn_points.get_children()
	if markers.is_empty():
		return Transform3D.IDENTITY
	var marker: Node3D = markers[slot % markers.size()] as Node3D
	@warning_ignore("integer_division")
	var row: int = slot / markers.size()
	return marker.global_transform.translated(Vector3(0.0, 0.0, SPAWN_ROW_SPACING * row))


func _spawn_boss() -> void:
	boss = BossDummy.new()
	boss.name = "Boss"
	boss.player_id = &"boss"
	boss.loadout = ClassLoadouts.raid_boss_dummy()
	boss.telegraphs_root = telegraphs_root
	boss.set_multiplayer_authority(1)
	actors_root.add_child(boss)
	boss.spawn_at(boss_spawn.global_transform)


# --- Input outside the fight ----------------------------------------------

## Enter (keyboard) or Start (pad) seats that controller in the party.
func _poll_drop_in() -> void:
	_check_join(InputComponent.KEYBOARD_DEVICE, Input.is_physical_key_pressed(KEY_ENTER))
	for pad: int in Input.get_connected_joypads():
		_check_join(pad + 1, Input.is_joy_button_pressed(pad, JOY_BUTTON_START))


func _check_join(device_id: int, held: bool) -> void:
	var was_held: bool = _join_held.get(device_id, false)
	_join_held[device_id] = held
	if held and not was_held and not NetworkManager.current.is_device_seated(device_id):
		seat_local_player(device_id, NetworkManager.ANY_CLASS, _assist_mode)


func _poll_network_keys() -> void:
	if _key_pressed(KEY_F5):
		NetworkManager.current.host_game()
	if _key_pressed(KEY_F6):
		NetworkManager.current.join_game(_join_address)
	if _key_pressed(KEY_F7):
		NetworkManager.current.leave_game()


func _key_pressed(key: Key) -> bool:
	var held: bool = Input.is_physical_key_pressed(key)
	var was_held: bool = _keys_held.get(key, false)
	_keys_held[key] = held
	return held and not was_held


func _show_notice(text: String) -> void:
	_notice = text
	_notice_time_left = 4.0


func _refresh_banner() -> void:
	var local_count: int = NetworkManager.current.local_player_count()
	var lines: PackedStringArray = PackedStringArray()
	if local_count == 0:
		lines.append("EVERWOOD · Dungeon Dojo")
		lines.append("Press Enter (keyboard) or Start (pad) to join")
	elif local_count < NetworkManager.MAX_LOCAL_PLAYERS and NetworkManager.current.party_size() < NetworkManager.MAX_PARTY_SIZE:
		lines.append("Start / Enter: join (%d/%d on this screen)" % [local_count, NetworkManager.MAX_LOCAL_PLAYERS])
	lines.append("%s · Party %d/%d · F5 host · F6 join %s · F7 leave" % [
		NetworkManager.current.status, NetworkManager.current.party_size(), NetworkManager.MAX_PARTY_SIZE, _join_address])
	if _notice_time_left > 0.0:
		lines.append(_notice)
	banner.text = "\n".join(lines)


# --- Command line, demo bots, screenshots ---------------------------------

func _apply_command_line() -> void:
	var players: int = 1
	var host: bool = false
	var join: bool = false
	for arg: String in OS.get_cmdline_user_args():
		var value: String = arg.get_slice("=", 1) if arg.contains("=") else ""
		if arg.begins_with("--players="):
			players = clampi(value.to_int(), 0, NetworkManager.MAX_LOCAL_PLAYERS)
		elif arg.begins_with("--mode="):
			_assist_mode = _mode_from_name(value)
		elif arg == "--host":
			host = true
		elif arg.begins_with("--join"):
			join = true
			if value != "":
				_join_address = value
		elif arg == "--demo":
			_demo = true
		elif arg.begins_with("--screenshot="):
			_screenshot_path = value
		elif arg.begins_with("--screenshot-delay="):
			_screenshot_delay = value.to_float()
		elif arg.begins_with("--quit-after="):
			_quit_after = value.to_float()
	if host:
		NetworkManager.current.host_game()
	elif join:
		NetworkManager.current.join_game(_join_address)
	for device_id: int in players:
		seat_local_player(device_id, NetworkManager.ANY_CLASS, _assist_mode)


func _mode_from_name(text: String) -> InputComponent.AssistMode:
	match text.to_lower():
		"master":
			return InputComponent.AssistMode.MASTER
		"squire", "squire_gambit":
			return InputComponent.AssistMode.SQUIRE_GAMBIT
	return InputComponent.AssistMode.ADVENTURER


## --demo: every local player walks to the boss and fights on its own.
func _drive_demo_bots(delta: float) -> void:
	_demo_clock += delta
	var beat: bool = fmod(_demo_clock, DEMO_ATTACK_EVERY) < delta
	for actor: ActorBase in actors.values():
		if actor.input == null or boss == null:
			continue
		var angle: float = (float(actor.party_slot) - 1.5) * 0.7
		var post: Vector3 = boss.global_position + Vector3(sin(angle), 0.0, cos(angle)) * DEMO_RING_RADIUS
		var to_post: Vector3 = post - actor.global_position
		to_post.y = 0.0
		var stick: Vector2 = Vector2.ZERO
		if to_post.length() > 0.5:
			var yaw: float = actor.camera_yaw
			var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
			var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
			stick = Vector2(to_post.dot(right), to_post.dot(forward)).normalized()
		actor.input.inject_move(stick)
		if beat and to_post.length() < 1.5:
			var options: Array[int] = [CombatActionResource.Command.LIGHT, CombatActionResource.Command.LIGHT, CombatActionResource.Command.HEAVY]
			if actor.role() == ClassLoadoutResource.Role.DPS:
				options.append(CombatActionResource.Command.FORWARD_HEAVY)
			if actor.role() == ClassLoadoutResource.Role.HEALER:
				options.append(CombatActionResource.Command.TRIGGER_R_SKILL)
			actor.input.inject_command(options[randi() % options.size()])


## One line for headless runs: what this peer saw of the fight.
func _print_report() -> void:
	var players: PackedStringArray = PackedStringArray()
	for actor: ActorBase in actors.values():
		players.append("%s %s %d/%d hp%s" % [actor.player_id, actor.loadout.class_id, roundi(actor.stats.health),
			roundi(actor.stats.stats.max_health), " (local)" if actor.is_local_player() else ""])
	print("[Dojo] Report: peer %d, boss %d/%d hp, %d telegraphs seen, players: %s" % [
		NetworkManager.current.local_peer_id(), roundi(boss.stats.health), roundi(boss.stats.stats.max_health),
		_telegraphs_seen, ", ".join(players)])


func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var error: Error = image.save_png(_screenshot_path)
	print("[Dojo] Screenshot %s: %s" % [_screenshot_path, error_string(error)])
	get_tree().quit()
