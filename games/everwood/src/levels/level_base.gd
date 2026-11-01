## What every playable instance shares (Hub Town, the Dungeon Dojo).
##
## It seats the party: one actor per Network Manager roster entry, and local
## ones get a controller, a split-screen view and a HUD. The keyboard and mouse
## is Player 1; every pad that's plugged in joins as the next player, splitting
## the screen 1 to 4, and leaves when it's unplugged. Enter / Start joins a
## controller by hand; holding it for a moment leaves.
##
## Each seat wears an equipment kit (ids, carried by the roster). This level
## picks a new seat's kit (the class's last saved one), checks kit changes from
## the Scribe Desk against the Grimoire's rules, composes each seat's loadout
## from its kit, and re-equips an actor in place when its kit changes.
##
## In raids, AI companions fill any Holy Trinity role nobody is playing while
## fewer than 3 people are in the party (CompanionAIComponent). The host seats
## them, and they step aside as people join.
##
## Keys: F5 host · F6 join · F7 leave · click to steer the camera with the mouse, Esc to let go.
## Command line (after --): --players=N --mode=master|adventurer|squire --instance=ID
##   --host --join=ADDRESS --demo --screenshot=PATH --screenshot-delay=S --quit-after=S
##   --weapon=ITEM_ID --armor=ITEM_ID (this screen's players start with them)
##   --save=PATH (another save file; read by PartyProgress)
class_name LevelBase
extends Node3D

const DEFAULT_ASSIST_MODE: InputComponent.AssistMode = InputComponent.AssistMode.ADVENTURER
const SCREENSHOT_DELAY: float = 3.0
## Extra rows behind the four spawn pads for a fifth (network) player.
const SPAWN_ROW_SPACING: float = 2.0
## Holding Enter / Start this long leaves the party.
const LEAVE_HOLD_TIME: float = 1.5
const NOTICE_TIME: float = 4.0
const DEMO_ATTACK_EVERY: float = 0.55

@onready var actors_root: Node3D = $Actors
@onready var telegraphs_root: Node3D = $Telegraphs
@onready var effects_root: Node3D = $Effects
@onready var spawn_points: Node3D = $SpawnPoints
@onready var grid: SplitScreenViewportGrid = $Screens/Grid
@onready var banner: Label = $Screens/Banner

var actors: Dictionary[StringName, ActorBase] = {}
var huds: Dictionary[StringName, PlayerHUD] = {}

var _join_hold: Dictionary[int, float] = {}
var _keys_held: Dictionary[int, bool] = {}
var _notice: String = ""
var _notice_time_left: float = 0.0
var _telegraphs_seen: int = 0
# What this peer saw, for the --quit-after report (network checks compare peers).
var _cards_seen: int = 0
var _shots_seen: int = 0
var _detonations_seen: int = 0
var _demo_clock: float = 0.0
var _companion_refresh_queued: bool = false

# The command line is read once per run; these survive instance changes.
static var session_clock: float = 0.0
static var _session_started: bool = false
static var _assist_mode: InputComponent.AssistMode = DEFAULT_ASSIST_MODE
static var _join_address: String = NetworkManager.DEFAULT_ADDRESS
static var _demo: bool = false
static var _screenshot_path: String = ""
static var _screenshot_delay: float = SCREENSHOT_DELAY
static var _screenshot_taken: bool = false
static var _quit_after: float = 0.0
static var _start_weapon: StringName = &""
static var _start_armor: StringName = &""
## Devices that already got the --weapon / --armor kit this run.
static var _start_kit_given: Dictionary[int, bool] = {}


# --- What each level fills in ---------------------------------------------

## This level's InstanceManager id.
func instance_id() -> StringName:
	return &""


func level_title() -> String:
	return ""


## A banner line telling players what to do here.
func level_hint() -> String:
	return ""


## Whether AI companions fill missing roles here (raids yes, Hub Town no).
func wants_companions() -> bool:
	return false


## Builds level-specific actors (the boss) before the party is seated.
func _setup_level() -> void:
	pass


## Where a --demo bot walks to, and whether it fights once there.
func _demo_post_for(actor: ActorBase) -> Vector3:
	return actor.global_position


func _demo_attacks() -> bool:
	return false


## Extra words for the --quit-after report.
func _report_extra() -> String:
	return ""


# --- Lifecycle ------------------------------------------------------------

func _ready() -> void:
	CombatDirector.current.reset()
	CombatDirector.current.effects_root = effects_root
	var pool: FxPool = FxPool.new()
	pool.name = "FxPool"
	effects_root.add_child(pool)
	CombatDirector.current.fx_pool = pool
	CombatDirector.current.telegraph_cast.connect(_on_telegraph_cast)
	CombatDirector.current.card_invoked.connect(_on_card_invoked)
	CombatDirector.current.projectile_fired.connect(_on_projectile_fired)
	CombatDirector.current.synergy_detonated.connect(_on_synergy_detonated)
	NetworkManager.current.class_picker = least_used_class
	NetworkManager.current.kit_picker = pick_kit
	NetworkManager.current.kit_validator = check_kit
	grid.set_world(get_world_3d())
	_setup_level()
	NetworkManager.current.player_registered.connect(_on_player_registered)
	NetworkManager.current.player_updated.connect(_on_player_updated)
	NetworkManager.current.player_unregistered.connect(_on_player_unregistered)
	NetworkManager.current.registration_refused.connect(_on_registration_refused)
	NetworkManager.current.status_changed.connect(_on_status_changed)
	NetworkManager.current.kit_refused.connect(_on_kit_refused)
	PartyProgress.current.progress_changed.connect(_on_progress_changed)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	# Companions from the last instance leave (or new ones join) before anyone is seated.
	_refresh_companions()
	for existing: PartyMember in NetworkManager.current.ordered_members():
		_on_player_registered(existing)
	InstanceManager.current.level_ready(instance_id())
	if not _session_started:
		_session_started = true
		_start_session()
	_refresh_banner()


func _exit_tree() -> void:
	var director: CombatDirector = CombatDirector.current
	if director != null:
		for connection: Array in [[director.telegraph_cast, _on_telegraph_cast], [director.card_invoked, _on_card_invoked],
				[director.projectile_fired, _on_projectile_fired], [director.synergy_detonated, _on_synergy_detonated]]:
			var director_signal: Signal = connection[0]
			var handler: Callable = connection[1]
			if director_signal.is_connected(handler):
				director_signal.disconnect(handler)
	if director != null and director.fx_pool != null and director.fx_pool.get_parent() == effects_root:
		director.fx_pool = null
	var network: NetworkManager = NetworkManager.current
	if network != null:
		for connection: Array in [
				[network.player_registered, _on_player_registered], [network.player_updated, _on_player_updated],
				[network.player_unregistered, _on_player_unregistered], [network.registration_refused, _on_registration_refused],
				[network.status_changed, _on_status_changed], [network.kit_refused, _on_kit_refused]]:
			var sig: Signal = connection[0]
			var callable: Callable = connection[1]
			if sig.is_connected(callable):
				sig.disconnect(callable)
	var progress: PartyProgress = PartyProgress.current
	if progress != null and progress.progress_changed.is_connected(_on_progress_changed):
		progress.progress_changed.disconnect(_on_progress_changed)
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)


func _process(delta: float) -> void:
	session_clock += delta
	_notice_time_left = maxf(0.0, _notice_time_left - delta)
	_poll_join_and_leave(delta)
	_poll_network_keys()
	if _demo:
		_drive_demo_bots(delta)
	_refresh_banner()
	if _screenshot_path != "" and not _screenshot_taken and session_clock >= _screenshot_delay and InstanceManager.current.is_live():
		_screenshot_taken = true
		_take_screenshot()
	if _quit_after > 0.0 and session_clock >= _quit_after:
		_print_report()
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	# Player 1 steers the camera with the mouse once it's captured.
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE \
			and NetworkManager.current.is_device_seated(InputComponent.KEYBOARD_DEVICE):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# --- Seating players ------------------------------------------------------

## Asks the Network Manager for a party seat; the actor appears when it's granted.
func seat_local_player(device_id: int, class_id: StringName, mode: InputComponent.AssistMode) -> void:
	NetworkManager.current.request_local_player(device_id, class_id, mode)


## The class the people in the party play least, so new players balance the
## trinity (a companion's role counts as open: the newcomer takes it over).
func least_used_class(roster: Dictionary[StringName, PartyMember]) -> StringName:
	var counts: Dictionary[StringName, int] = {}
	for class_id: StringName in ClassLoadouts.PLAYER_CLASSES:
		counts[class_id] = 0
	for seat: PartyMember in roster.values():
		if counts.has(seat.class_id) and not seat.companion:
			counts[seat.class_id] += 1
	var best: StringName = ClassLoadouts.PLAYER_CLASSES[0]
	for class_id: StringName in ClassLoadouts.PLAYER_CLASSES:
		if counts[class_id] < counts[best]:
			best = class_id
	return best


# --- Kits -----------------------------------------------------------------

## The kit a new seat wears: the class's last saved kit while it's still
## allowed, otherwise its starter kit. Companions always wear the starter kit.
func pick_kit(class_id: StringName, companion: bool) -> Dictionary:
	var starter: Dictionary = ClassLoadouts.starter_kit(class_id).to_dict()
	if companion:
		return starter
	var saved: Dictionary = PartyProgress.current.kit_for(class_id)
	if not saved.is_empty() and check_kit_for_class(class_id, saved) == "":
		return saved
	return starter


## Host: why a seat may not wear `kit` ("" when it may).
func check_kit(seat: PartyMember, kit: Dictionary) -> String:
	return check_kit_for_class(seat.class_id, kit)


func check_kit_for_class(class_id: StringName, kit: Dictionary) -> String:
	var progress: PartyProgress = PartyProgress.current
	return LoadoutComposer.kit_problem(ClassLoadouts.player_class(class_id), EquipmentLoadoutResource.from_dict(kit),
		progress.grimoire_level(), progress.collection)


## The loadout a seat's class and kit compose into.
func _compose_for(seat: PartyMember) -> ClassLoadoutResource:
	var kit: EquipmentLoadoutResource = null if seat.kit.is_empty() else EquipmentLoadoutResource.from_dict(seat.kit)
	return ClassLoadouts.compose(seat.class_id, kit)


## --weapon / --armor: this screen's players swap them into their kit once.
func _give_start_kit(device_id: int) -> void:
	var seat: PartyMember = _local_seat(device_id)
	if seat == null or _start_kit_given.has(device_id):
		return
	_start_kit_given[device_id] = true
	var kit: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(seat.kit)
	if _start_weapon != &"":
		kit.weapon_id = _start_weapon
	if _start_armor != &"":
		kit.armor_id = _start_armor
	NetworkManager.current.update_local_kit(device_id, kit.to_dict())


func _on_player_registered(seat: PartyMember) -> void:
	if actors.has(seat.player_id):
		return
	var actor: ActorBase = ActorBase.new()
	actor.name = String(seat.player_id)
	actor.loadout = _compose_for(seat)
	actor.player_id = seat.player_id
	actor.peer_id = seat.peer_id
	actor.device_id = seat.device_id
	actor.party_slot = seat.slot
	var is_local: bool = seat.peer_id == NetworkManager.current.local_peer_id()
	actor.is_companion = seat.companion
	if seat.companion:
		if is_local:
			actor.attach_companion()
	elif is_local:
		actor.attach_input(seat.device_id, seat.assist_mode)
	actor.set_multiplayer_authority(seat.peer_id)
	actors_root.add_child(actor)
	actor.spawn_at(_spawn_transform(seat.slot))
	actors[seat.player_id] = actor
	_queue_companion_refresh()
	if is_local and not seat.companion and (_start_weapon != &"" or _start_armor != &"") and not _start_kit_given.has(seat.device_id):
		_give_start_kit.call_deferred(seat.device_id)
	if is_local and not seat.companion:
		# Deferred: the request fires inside the actor's own physics step, and a
		# class change replaces that actor.
		actor.input.class_cycle_requested.connect(_on_class_cycle.bind(seat.device_id), CONNECT_DEFERRED)
		actor.input.mode_cycle_requested.connect(_on_mode_cycle.bind(seat.device_id))
		var overlay: Control = grid.add_player_view(actor)
		if overlay != null:
			var hud: PlayerHUD = PlayerHUD.new()
			hud.setup(actor)
			overlay.add_child(hud)
			huds[seat.player_id] = hud


func _on_player_updated(seat: PartyMember) -> void:
	_queue_companion_refresh()
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
		_show_notice("%s is now a %s" % [replacement.display_name().get_slice(" ", 0), replacement.loadout.display_name])
		return
	# A new kit (the Scribe Desk): re-equip in place, so the view, HUD and menu stay.
	var composed: ClassLoadoutResource = _compose_for(seat)
	if not composed.kit.same_as(actor.loadout.kit):
		actor.re_equip(composed)
		if NetworkManager.current.is_host() and not seat.companion:
			PartyProgress.current.save_kit(seat.class_id, seat.kit)
	actor.party_slot = seat.slot
	actor.refresh_name_label()
	if actor.input != null and actor.input.assist_mode != seat.assist_mode:
		actor.input.assist_mode = seat.assist_mode as InputComponent.AssistMode
		actor.apply_assist_mode()
		_show_notice("%s: %s mode" % [actor.display_name(), actor.input.mode_name()])


func _on_player_unregistered(player_id: StringName) -> void:
	_remove_actor(player_id)
	_queue_companion_refresh()


func _queue_companion_refresh() -> void:
	if _companion_refresh_queued or not NetworkManager.current.is_host():
		return
	_companion_refresh_queued = true
	_refresh_companions.call_deferred()


## Host only: AI companions take the trinity roles nobody is playing (in raids).
func _refresh_companions() -> void:
	_companion_refresh_queued = false
	if not is_inside_tree() or not NetworkManager.current.is_host():
		return
	var people: Array[StringName] = []
	for seat: PartyMember in NetworkManager.current.ordered_members():
		if not seat.companion:
			people.append(seat.class_id)
	var wanted: Array[StringName] = []
	if wants_companions():
		wanted = CompanionAIComponent.backfill_classes(people)
	NetworkManager.current.set_companions(wanted)


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
	var seat: PartyMember = _local_seat(device_id)
	if seat != null:
		NetworkManager.current.update_local_player(device_id, ClassLoadouts.next_class(seat.class_id), seat.assist_mode)


func _on_mode_cycle(device_id: int) -> void:
	var seat: PartyMember = _local_seat(device_id)
	if seat != null:
		NetworkManager.current.update_local_player(device_id, seat.class_id, (seat.assist_mode + 1) % InputComponent.MODE_NAMES.size())


func _local_seat(device_id: int) -> PartyMember:
	return NetworkManager.current.member(PartyMember.make_player_id(NetworkManager.current.local_peer_id(), device_id))


func _on_registration_refused(_device_id: int, reason: String) -> void:
	_show_notice(reason)


func _on_status_changed(text: String) -> void:
	_show_notice(text)


func _on_kit_refused(_device_id: int, reason: String) -> void:
	_show_notice(reason)


## An upgrade was bought (here or on the host): everyone's stats grow at once.
func _on_progress_changed() -> void:
	for actor: ActorBase in actors.values():
		actor.refresh_upgrades()


func _on_telegraph_cast(_decal: RaidTelegraphDecal) -> void:
	_telegraphs_seen += 1


func _on_card_invoked(_caster: ActorBase, _action: CombatActionResource, _variant: int) -> void:
	_cards_seen += 1


func _on_projectile_fired(_attacker: ActorBase, _action: CombatActionResource) -> void:
	_shots_seen += 1


func _on_synergy_detonated(_target: ActorBase, _primer: int, _cross: bool, _label: String) -> void:
	_detonations_seen += 1


## Hot-join: plugging in a pad seats it as the next player; unplugging drops it.
func _on_joy_connection_changed(pad: int, connected: bool) -> void:
	var device_id: int = pad + 1
	if connected:
		if not NetworkManager.current.is_device_seated(device_id):
			_show_notice("%s connected" % (Input.get_joy_name(pad) if Input.get_joy_name(pad) != "" else "Pad %d" % device_id))
			AudioCues.play(&"join")
			seat_local_player(device_id, NetworkManager.ANY_CLASS, _assist_mode)
	else:
		NetworkManager.current.drop_local_player(device_id)


func _spawn_transform(slot: int) -> Transform3D:
	var markers: Array[Node] = spawn_points.get_children()
	if markers.is_empty():
		return Transform3D.IDENTITY
	var marker: Node3D = markers[slot % markers.size()] as Node3D
	@warning_ignore("integer_division")
	var row: int = slot / markers.size()
	return marker.global_transform.translated(Vector3(0.0, 0.0, SPAWN_ROW_SPACING * row))


# --- Input outside the fight ----------------------------------------------

## Enter / Start joins an unseated controller; holding it leaves the party.
func _poll_join_and_leave(delta: float) -> void:
	_check_join(InputComponent.KEYBOARD_DEVICE, delta)
	for pad: int in Input.get_connected_joypads():
		_check_join(pad + 1, delta)


func _check_join(device_id: int, delta: float) -> void:
	var held: bool = InputComponent.action_strength(InputComponent.ACTION_JOIN, device_id) >= InputComponent.PRESS_THRESHOLD
	var hold: float = _join_hold.get(device_id, -1.0)
	if not held:
		_join_hold[device_id] = -1.0
		return
	if hold < 0.0:
		_join_hold[device_id] = 0.0
		if not NetworkManager.current.is_device_seated(device_id):
			AudioCues.play(&"join")
			seat_local_player(device_id, NetworkManager.ANY_CLASS, _assist_mode)
			_join_hold[device_id] = LEAVE_HOLD_TIME * 2.0 # This press joined; it can't also leave.
		return
	var after: float = hold + delta
	_join_hold[device_id] = after
	if hold < LEAVE_HOLD_TIME and after >= LEAVE_HOLD_TIME:
		NetworkManager.current.drop_local_player(device_id)
		_show_notice("%s left the party" % ("Keyboard player" if device_id == InputComponent.KEYBOARD_DEVICE else "Pad %d" % device_id))


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
	_notice_time_left = NOTICE_TIME


func _refresh_banner() -> void:
	var local_count: int = NetworkManager.current.local_player_count()
	var lines: PackedStringArray = PackedStringArray()
	if local_count == 0:
		lines.append("EVERWOOD · %s" % level_title())
		lines.append("Press Enter, or plug in a pad (or press Start), to join")
	elif local_count < NetworkManager.MAX_LOCAL_PLAYERS and NetworkManager.current.party_size() < NetworkManager.MAX_PARTY_SIZE:
		lines.append("Plug in a pad or press Start / Enter to join (%d/%d on this screen) · hold it to leave" % [
			local_count, NetworkManager.MAX_LOCAL_PLAYERS])
	if level_hint() != "":
		lines.append(level_hint())
	var bots: int = NetworkManager.current.companion_seats().size()
	lines.append("%s · Party %d/%d%s · F5 host · F6 join %s · F7 leave" % [
		NetworkManager.current.status, NetworkManager.current.human_count(), NetworkManager.MAX_PARTY_SIZE,
		" + %d bot%s" % [bots, "" if bots == 1 else "s"] if bots > 0 else "", _join_address])
	if _notice_time_left > 0.0:
		lines.append(_notice)
	banner.text = "\n".join(lines)


# --- Command line, demo bots, screenshots ---------------------------------

## Runs once per launch: network flags, who's playing, and where to start.
func _start_session() -> void:
	var players: int = -1
	var host: bool = false
	var join: bool = false
	var start_instance: StringName = &""
	for arg: String in OS.get_cmdline_user_args():
		var value: String = arg.get_slice("=", 1) if arg.contains("=") else ""
		if arg.begins_with("--players="):
			players = clampi(value.to_int(), 0, NetworkManager.MAX_LOCAL_PLAYERS)
		elif arg.begins_with("--mode="):
			_assist_mode = _mode_from_name(value)
		elif arg.begins_with("--instance="):
			start_instance = StringName(value)
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
		elif arg.begins_with("--weapon="):
			_start_weapon = StringName(value)
		elif arg.begins_with("--armor="):
			_start_armor = StringName(value)
	if host:
		NetworkManager.current.host_game()
	elif join:
		NetworkManager.current.join_game(_join_address)
	if players >= 0:
		for device_id: int in players:
			seat_local_player(device_id, NetworkManager.ANY_CLASS, _assist_mode)
	else:
		# Keyboard and mouse first (Player 1), then every pad already plugged in.
		seat_local_player(InputComponent.KEYBOARD_DEVICE, NetworkManager.ANY_CLASS, _assist_mode)
		for pad: int in Input.get_connected_joypads():
			seat_local_player(pad + 1, NetworkManager.ANY_CLASS, _assist_mode)
	if start_instance != &"" and start_instance != instance_id():
		InstanceManager.current.change_instance(start_instance)


func _mode_from_name(text: String) -> InputComponent.AssistMode:
	match text.to_lower():
		"master":
			return InputComponent.AssistMode.MASTER
		"squire", "squire_gambit":
			return InputComponent.AssistMode.SQUIRE_GAMBIT
	return InputComponent.AssistMode.ADVENTURER


## --demo: every local player plays on its own (walks to its post, maybe fights).
func _drive_demo_bots(delta: float) -> void:
	_demo_clock += delta
	var beat: bool = fmod(_demo_clock, DEMO_ATTACK_EVERY) < delta
	for actor: ActorBase in actors.values():
		if actor.input == null:
			continue
		var to_post: Vector3 = _demo_post_for(actor) - actor.global_position
		to_post.y = 0.0
		var stick: Vector2 = Vector2.ZERO
		if to_post.length() > 0.5:
			var yaw: float = actor.camera_yaw
			var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
			var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
			stick = Vector2(to_post.dot(right), to_post.dot(forward)).normalized()
		actor.input.inject_move(stick)
		if beat and _demo_attacks() and to_post.length() < 1.5:
			var options: Array[int] = [CombatActionResource.Command.LIGHT, CombatActionResource.Command.LIGHT, CombatActionResource.Command.HEAVY]
			if actor.role() == ClassLoadoutResource.Role.DPS:
				options.append(CombatActionResource.Command.FORWARD_HEAVY)
				options.append(CombatActionResource.Command.BACK_HEAVY)
			if actor.role() == ClassLoadoutResource.Role.HEALER:
				options.append(CombatActionResource.Command.TRIGGER_R_SKILL)
			actor.input.inject_command(options[randi() % options.size()])


## One line for headless runs: what this peer saw.
func _print_report() -> void:
	var players: PackedStringArray = PackedStringArray()
	for actor: ActorBase in actors.values():
		var tag: String = " (local)" if actor.is_local_player() else ""
		if actor.companion != null:
			tag = " (bot: %s)" % actor.companion.gambit_name()
		var weapon: String = String(actor.loadout.weapon.item_id) if actor.loadout.weapon != null else "-"
		players.append("%s %s/%s %d/%d hp%s" % [actor.player_id, actor.loadout.class_id, weapon, roundi(actor.stats.health),
			roundi(actor.stats.stats.max_health), tag])
	print("[Level] Report: peer %d in %s, %s%d telegraphs, %d cards, %d shots, %d detonations seen, players: %s" % [
		NetworkManager.current.local_peer_id(), instance_id(), _report_extra(), _telegraphs_seen, _cards_seen, _shots_seen,
		_detonations_seen, ", ".join(players)])


func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var error: Error = image.save_png(_screenshot_path)
	print("[Level] Screenshot %s: %s" % [_screenshot_path, error_string(error)])
	get_tree().quit()
