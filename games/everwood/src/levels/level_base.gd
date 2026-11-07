## What every playable instance shares (Hub Town, the Dungeon Dojo).
##
## It seats the party: one actor per Network Manager roster entry, and local
## ones get a controller, a split-screen view and a HUD. The keyboard and mouse
## is Player 1; every pad that's plugged in joins as the next player, splitting
## the screen 1 to 4, and leaves when it's unplugged. Enter / Start joins a
## controller by hand; holding it for a moment leaves.
##
## Each seat is a class (its Primary Fellowship) with a Secondary Calling and
## wears an equipment kit (ids, carried by the roster). This level picks a new
## seat's Calling and kit (the class's last saved ones), checks kit changes
## from the Scribe Desk against the Calling's gear and the Grimoire's rules,
## composes each seat's loadout, and re-equips an actor in place when its kit
## or Calling changes.
##
## In raids, AI companions can fill any Holy Trinity role nobody is playing
## while fewer than 3 people are in the party (CompanionAIComponent). The host
## seats them, and they step aside as people join. For the solo playtest boot
## (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md, Stage 1) they stay home
## unless asked for: `--with-companions`, or set_companion_backfill_enabled(true).
## Player 1 boots alone, the screen theirs, as the Level 1 youth: a Wayfarer
## (ClassLoadouts.SOLO_BOOT_CLASS), Unsworn until the trail reaches Level 10,
## in the kit the trail has earned (21_WINGFEATHER_YOUTH_HERO.md §4).
##
## Keys: F5 host · F6 join · F7 leave · click to steer the camera with the mouse, Esc to let go.
## Command line (after --): --players=N --mode=master|adventurer|squire
##   --instance=caldera|bramblebridge|hub|oakshire_vale|expedition (or an instance id; without it the game starts in the Caldera Isles)
##   --boot-zone=oakshire|north_quay|crown (where in the Caldera Isles: Miller's Oak's orchards, North Quay, or The Crown's landing)
##   --host --join=ADDRESS --demo --screenshot=PATH --screenshot-delay=S --quit-after=S
##   --with-companions (AI companions fill the missing trinity roles in raids and the wilds)
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
var _debug_banner: String = ""
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
## Each --demo bot finds its way by the navigation map, like a companion.
var _demo_steering: Dictionary[StringName, NavSteering] = {}
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
## Whether AI companions fill missing roles where a level wants them (off for
## the solo playtest boot; --with-companions or set_companion_backfill_enabled turn it on).
static var auto_backfill_companions: bool = false
## Whether Player 1 boots alone as the Wayfarer youth. Tests that seat the
## classic trinity turn it off.
static var solo_youth_boot: bool = true


# --- What each level fills in ---------------------------------------------

## This level's InstanceManager id.
func instance_id() -> StringName:
	return &""


## The world rectangle the Wayfarer's map shows (x, z; 18 GDD §7.1): by default
## the walls' and floors' colliders' reach. Seamless worlds use their layout's.
func map_rect() -> Rect2:
	var reach: Rect2 = Rect2()
	var started: bool = false
	for node: Node in find_children("*", "CollisionShape3D", true, false):
		var shape: CollisionShape3D = node as CollisionShape3D
		var body: CollisionObject3D = shape.get_parent() as CollisionObject3D
		var box: BoxShape3D = shape.shape as BoxShape3D
		if body == null or box == null or not body is StaticBody3D or not shape.is_inside_tree():
			continue
		if (body.collision_layer & ActorBase.LAYER_WORLD) == 0 or box.size.x > 400.0 or box.size.z > 400.0:
			continue
		var at: Vector3 = shape.global_position
		var piece: Rect2 = Rect2(at.x - box.size.x * 0.5, at.z - box.size.z * 0.5, box.size.x, box.size.z)
		reach = piece if not started else reach.merge(piece)
		started = true
	return reach.grow(4.0) if started else Rect2(-32.0, -32.0, 64.0, 64.0)


## The paths the map draws as roads in a walled instance: [{"points": PackedVector2Array (x, z), "half_width": float}].
func map_paths() -> Array[Dictionary]:
	var none: Array[Dictionary] = []
	return none


func level_title() -> String:
	return ""


## A banner line telling players what to do here.
func level_hint() -> String:
	return ""


## Where the party arrives, as a place in the Mythopoetic Atlas (15 GDD §5):
## it sets which zone's rhyme the Chime-Post ribbon sings.
func home_place() -> String:
	return ""


## The ZoneMusicProfileResource id that plays at a spot (16 GDD §5.2; &"" for none).
func music_profile_at(_position: Vector3) -> StringName:
	return &""


## The ZoneBiomeResource id whose sky, sun, fog and ground a spot wears
## (17 GDD §6.2): by default the biome under its score, and past the sunken
## lane's turn, Rush-Light-Hollow's (&"" for none).
func visual_biome_at(position: Vector3) -> StringName:
	var profile: StringName = music_profile_at(position)
	if profile == &"moss_oak_hollow" and music_world_z(position) < WorldVisualCatalog.SUNKEN_LANE_Z:
		return WorldVisualCatalog.RUSH_LIGHT_HOLLOW
	return WorldVisualCatalog.biome_for_music(profile)


## A spot's z on the Bramble-Bridge trail, for a profile's depth blend (the expedition shifts its own).
func music_world_z(position: Vector3) -> float:
	return position.z


## Whether the HorizonVistaRing's far hills stand round this level (the Caldera Isles have the open sea and their own horizon silhouettes).
func wants_horizon_ring() -> bool:
	return true


## Whether the Wayfarer's minimap shows (the Caldera Isles navigate by landmarks: the Musk Razor).
func wants_minimap() -> bool:
	return true


## The sky's colour below the horizon here (alpha 0: the biome's ground). The Caldera's is the sea's,
## so a high camera never sees a green band between the sea's far edge and the horizon.
func sky_ground_color() -> Color:
	return Color(0.0, 0.0, 0.0, 0.0)


## Where the low height-fog lies here (metres; it thickens below this).
func fog_height() -> float:
	return WorldAtmosphereDirector.FOG_HEIGHT


## The biomes' fog density is scaled by this here (the Caldera thins it over open water so the far isles show).
func fog_density_scale() -> float:
	return 1.0


## Whether AI companions fill missing roles here (raids yes, Hub Town no),
## once companion backfill is on (auto_backfill_companions).
func wants_companions() -> bool:
	return false


## Turns AI companion backfill on or off for the session (a test that checks
## companions, or --with-companions), and seats or dismisses them now.
func set_companion_backfill_enabled(enabled: bool) -> void:
	auto_backfill_companions = enabled
	_queue_companion_refresh()


## Whether the command line asks for companions.
static func wants_companions_flag(args: PackedStringArray) -> bool:
	return args.has("--with-companions")


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
	NetworkManager.current.calling_picker = pick_calling
	NetworkManager.current.kit_picker = pick_kit
	NetworkManager.current.kit_validator = check_kit
	NetworkManager.current.calling_validator = check_calling
	NetworkManager.current.seal_hand_picker = pick_seal_hand
	NetworkManager.current.seal_hand_validator = check_seal_hand
	grid.set_world(get_world_3d())
	# The storybook sky, with its clouds and the far ridgelines (13_PLAYTEST §2.6), in place of the procedural one.
	for found: Node in find_children("*", "WorldEnvironment", true, false):
		StorybookSky.install((found as WorldEnvironment).environment)
	_setup_level()
	# Every sign and nameplate reads the same (18 GDD §6.2), built by any script or baked into the scene.
	WorldLabelStyle.watch(get_tree(), self)
	NetworkManager.current.player_registered.connect(_on_player_registered)
	NetworkManager.current.player_updated.connect(_on_player_updated)
	NetworkManager.current.player_unregistered.connect(_on_player_unregistered)
	NetworkManager.current.registration_refused.connect(_on_registration_refused)
	NetworkManager.current.status_changed.connect(_on_status_changed)
	NetworkManager.current.kit_refused.connect(_on_kit_refused)
	PartyProgress.current.progress_changed.connect(_on_progress_changed)
	PartyProgress.current.trail_level_reached.connect(_on_trail_level_reached)
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
	# A Wayfarer's map still being painted finishes before the level goes.
	CartographyBaker.finish_pending()
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
	if progress != null and progress.trail_level_reached.is_connected(_on_trail_level_reached):
		progress.trail_level_reached.disconnect(_on_trail_level_reached)
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
	# Esc gives the mouse back (and, through the Input Map, opens the Options menu).
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# --- The cameras (18 GDD §6) ----------------------------------------------

## Tilts seat `seat_id`'s camera (its P-number, 1 to 5) to `degrees`, held between -12 and +52.
func set_camera_pitch_degrees(seat_id: int, degrees: float) -> void:
	var view: PlayerCamera = camera_for_seat(seat_id)
	if view != null:
		view.set_pitch_degrees(degrees)


## Seat `seat_id`'s camera pitch in degrees (NAN if that seat has no camera here).
func get_camera_pitch_degrees(seat_id: int) -> float:
	var view: PlayerCamera = camera_for_seat(seat_id)
	return view.pitch_degrees if view != null else NAN


## The camera of the local player in seat `seat_id` (its P-number), or null.
func camera_for_seat(seat_id: int) -> PlayerCamera:
	for player_id: StringName in actors:
		var actor: ActorBase = actors[player_id]
		if is_instance_valid(actor) and actor.party_slot + 1 == seat_id:
			var view: PlayerCamera = grid.camera_for(player_id)
			if view != null:
				return view
	return null


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
	# The boot: the first person to sit down is the Wayfarer youth.
	if solo_youth_boot and counts.values().max() == 0:
		return ClassLoadouts.SOLO_BOOT_CLASS
	var best: StringName = ClassLoadouts.PLAYER_CLASSES[0]
	for class_id: StringName in ClassLoadouts.PLAYER_CLASSES:
		if counts[class_id] < counts[best]:
			best = class_id
	return best


# --- Kits -----------------------------------------------------------------

## The Calling a new seat takes, by id: Unsworn until the trail reaches Level
## 10 (11 GDD §5.2); then the class's last saved one, otherwise its own column
## (Bridge-Warden, Hedge-Runner, Lantern-Scribe). Companions take their own column.
func pick_calling(class_id: StringName, companion: bool) -> StringName:
	if not PartyProgress.current.callings_unlocked():
		return Callings.UNSWORN_ID
	if companion:
		return Callings.id_of(Callings.default_secondary(class_id))
	var saved: int = Callings.column_of(PartyProgress.current.calling_for(class_id))
	return Callings.id_of(saved if Callings.is_valid(saved) else Callings.default_secondary(class_id))


## The kit a new seat wears: the class's last saved kit while it's still
## allowed, otherwise the kit the trail has earned it so far (PartyProgress.trail_kit:
## Tier 1 timber and an un-inked R and L+R at Level 1). Companions wear the trail kit.
func pick_kit(class_id: StringName, calling: StringName, companion: bool) -> Dictionary:
	var earned: Dictionary = PartyProgress.current.trail_kit(class_id)
	if companion:
		return earned
	var saved: Dictionary = PartyProgress.current.kit_for(class_id)
	if not saved.is_empty() and check_kit_for_class(class_id, calling, saved) == "":
		return saved
	return earned


## Host: why a seat may not wear `kit` ("" when it may).
func check_kit(seat: PartyMember, kit: Dictionary) -> String:
	return check_kit_for_class(seat.class_id, seat.calling, kit)


func check_kit_for_class(class_id: StringName, calling: StringName, kit: Dictionary) -> String:
	var progress: PartyProgress = PartyProgress.current
	return LoadoutComposer.kit_problem(ClassLoadouts.player_class(class_id, Callings.column_of(calling)), EquipmentLoadoutResource.from_dict(kit),
		progress.grimoire_level(), progress.collection, progress.trail_level())


## The seal hand a new seat carries: the class's last one from the Binder's stamping bench
## while it still fits (PartyProgress.seal_hand_for), otherwise {} and the role's default
## hand by stage. Companions always wear the default.
func pick_seal_hand(class_id: StringName, companion: bool) -> Dictionary:
	if companion:
		return {}
	var saved: Dictionary = PartyProgress.current.seal_hand_for(class_id)
	if saved.is_empty():
		return {}
	var level: int = clampi(PartyProgress.current.trail_level(), 1, ArsenalCatalog.MAX_TRUE_LEVEL)
	var problem: String = _seal_hand_problem(ClassLoadouts.player_class(class_id).role, PlayerLoadoutResource.stage_for_true_level(level), level, saved)
	return saved if problem == "" else {}


## Host: why a seat may not carry a seal hand ("" when it may): only seal cards the party
## owns (or the Fellowship's starting seal for the slot), only in slots its hero's stage has
## opened (ArsenalCatalog.seal_hand_problem). A client can't claim a locked slot this way.
func check_seal_hand(seat: PartyMember, hand: Dictionary) -> String:
	if hand.is_empty():
		return ""
	var level: int = clampi(PartyProgress.current.trail_level(), 1, ArsenalCatalog.MAX_TRUE_LEVEL)
	var stage: int = PlayerLoadoutResource.stage_for_true_level(level)
	var hero: ActorBase = actors.get(seat.player_id) as ActorBase
	if hero != null and hero.seal != null:
		level = hero.seal.true_level
		stage = hero.seal.progression_stage
	return _seal_hand_problem(ClassLoadouts.player_class(seat.class_id).role, stage, level, hand)


func _seal_hand_problem(role: int, stage: int, level: int, hand: Dictionary) -> String:
	return ArsenalCatalog.current.seal_hand_problem(PlayerLoadoutResource.from_dict(hand), role, stage, level, PartyProgress.current.collection)


## Host: why a seat may not take a Calling ("" when it may): they open at Level 10.
func check_calling(_seat: PartyMember, calling: StringName) -> String:
	if calling != Callings.UNSWORN_ID and not PartyProgress.current.callings_unlocked():
		return "The Secondary Callings open at Level %d" % ArsenalCatalog.CALLING_LEVEL
	return ""


## The loadout a seat's class, Calling and kit compose into.
func _compose_for(seat: PartyMember) -> ClassLoadoutResource:
	var kit: EquipmentLoadoutResource = null if seat.kit.is_empty() else EquipmentLoadoutResource.from_dict(seat.kit)
	return ClassLoadouts.compose(seat.class_id, kit, Callings.column_of(seat.calling))


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
		# Deferred too: a playtest switch can change class, which replaces this actor.
		actor.input.playtest_cycle_requested.connect(_on_playtest_cycle.bind(seat.device_id), CONNECT_DEFERRED)
		actor.input.mode_cycle_requested.connect(_on_mode_cycle.bind(seat.device_id))
		actor.input.calling_cycle_requested.connect(_on_calling_cycle.bind(seat.device_id))
		var overlay: Control = grid.add_player_view(actor)
		if overlay != null:
			var hud: PlayerHUD = PlayerHUD.new()
			hud.setup(actor)
			overlay.add_child(hud)
			huds[seat.player_id] = hud
			hud.enter_place.call_deferred(home_place(), false)


func _on_player_updated(seat: PartyMember) -> void:
	_queue_companion_refresh()
	var actor: ActorBase = actors.get(seat.player_id) as ActorBase
	if actor == null:
		_on_player_registered(seat)
		return
	if actor.loadout.class_id != seat.class_id:
		# A new class is a new actor, standing where the old one stood. If its
		# player was at the Scribe Desk, the desk reopens on the new HUD.
		var where: Transform3D = actor.global_transform
		var old_hud: PlayerHUD = huds.get(seat.player_id) as PlayerHUD
		var desk_row: int = old_hud.scribe_desk_menu().selected if old_hud != null and old_hud.scribe_desk_menu() != null else -1
		_remove_actor(seat.player_id)
		_on_player_registered(seat)
		var replacement: ActorBase = actors[seat.player_id]
		replacement.place_at(where)
		var new_hud: PlayerHUD = huds.get(seat.player_id) as PlayerHUD
		if desk_row >= 0 and new_hud != null:
			new_hud.open_scribe_desk(desk_row)
		_show_notice("%s is now a %s: %s" % [replacement.display_name().get_slice(" ", 0), Callings.fellowship_member(seat.class_id),
			replacement.loadout.display_name])
		return
	# A new kit (the Scribe Desk) or Calling: re-equip in place, so the view, HUD and menu stay.
	var composed: ClassLoadoutResource = _compose_for(seat)
	if not composed.kit.same_as(actor.loadout.kit) or composed.calling != actor.loadout.calling:
		var new_calling: bool = composed.calling != actor.loadout.calling
		actor.re_equip(composed)
		actor.refresh_name_label()
		if new_calling:
			_show_notice("%s is now a %s (%s)" % [actor.display_name().get_slice(" ", 0), composed.display_name, Callings.secondary_label(composed.calling)])
		if NetworkManager.current.is_host() and not seat.companion:
			PartyProgress.current.save_kit(seat.class_id, seat.kit)
			PartyProgress.current.save_calling(seat.class_id, seat.calling)
	# A hand from the Binder's stamping bench: every peer's copy wears it at once, and the host keeps it for the Fellowship.
	if actor.seal != null:
		actor.seal.wear_seat_hand(seat.seal_hand)
	if NetworkManager.current.is_host() and not seat.companion and not seat.seal_hand.is_empty():
		PartyProgress.current.save_seal_hand(seat.class_id, seat.seal_hand)
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
	if auto_backfill_companions and wants_companions():
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


## Hold C (or pick at the Scribe Desk): the next Secondary Calling (Stout Heart, Swift Foot, Wise Hand).
func _on_calling_cycle(device_id: int) -> void:
	var seat: PartyMember = _local_seat(device_id)
	if seat != null and not PartyProgress.current.callings_unlocked():
		_show_notice("The Secondary Callings open at Level %d" % ArsenalCatalog.CALLING_LEVEL)
		return
	if seat != null:
		var column: int = Callings.resolve(seat.class_id, Callings.column_of(seat.calling))
		var secondary: StringName = Callings.id_of(Callings.next_secondary(column))
		NetworkManager.current.update_local_calling(device_id, secondary)
		# The new Calling's posture motif over the zone's tonic (16 GDD §3.2).
		for calling: CallingResource in ArsenalCatalog.current.callings():
			if calling.fellowship_class_id == seat.class_id and calling.secondary_id == secondary and AudioDirector.current != null:
				AudioDirector.current.play_calling_motif(calling.calling_id)


## F2, or Share held and the D-Pad tapped: the playtest switcher's next (or previous) class and level (K2).
func _on_playtest_cycle(step: int, device_id: int) -> void:
	var toast: String = PlaytestSwitcher.step_hero(self, device_id, step)
	if toast == "":
		return
	_show_notice(toast + (" · playtest: nothing is saved" if PartyProgress.current.playtest else ""))
	var capped: bool = PartyProgress.current.playtest_level > PartyProgress.LEVEL_XP.size()
	var seat: PartyMember = _local_seat(device_id)
	var hud: PlayerHUD = huds.get(seat.player_id) as PlayerHUD if seat != null else null
	if hud != null:
		var line: String = toast.trim_prefix("Debug Switch: ")
		if capped:
			line += " (the trail tops out at Lv %d: its gear)" % PartyProgress.LEVEL_XP.size()
		hud.show_banner("DEBUG SWITCH", line, PlaytestSwitcher.TOAST_COLOR, PlaytestSwitcher.TOAST_TIME)
	AudioCues.play(&"equip")


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


## The party reached a trail level (11 GDD §6): a Wayfarer Pennant over every
## hero, and on the host the milestone's grant auto-slots into every seat's kit
## (and every class's saved kit), so the power is there on the very next press.
func _on_trail_level_reached(level: int) -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	for actor: ActorBase in actors.values():
		var grant: Dictionary = catalog.get_milestone_grant_for_level(level, actor.role())
		actor.show_milestone_pennant(level, PlayerHUD.grant_text(grant))
	for hud: PlayerHUD in huds.values():
		hud.show_milestone(level, PlayerHUD.grant_text(catalog.get_milestone_grant_for_level(level, hud.actor.role())))
	if not NetworkManager.current.is_host():
		return
	var progress: PartyProgress = PartyProgress.current
	for class_id: StringName in ClassLoadouts.PLAYER_CLASSES:
		var saved: Dictionary = progress.kit_for(class_id)
		if not saved.is_empty():
			var saved_kit: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(saved)
			catalog.apply_milestone_grant(saved_kit, catalog.get_milestone_grant_for_level(level, ClassLoadouts.player_class(class_id).role))
			progress.save_kit(class_id, saved_kit.to_dict())
	for seat: PartyMember in NetworkManager.current.ordered_members():
		var grant: Dictionary = catalog.get_milestone_grant_for_level(level, ClassLoadouts.player_class(seat.class_id).role)
		if grant.is_empty():
			continue
		var kit: EquipmentLoadoutResource = EquipmentLoadoutResource.from_dict(seat.kit) if not seat.kit.is_empty() \
			else EquipmentLoadoutResource.from_dict(progress.trail_kit(seat.class_id))
		catalog.apply_milestone_grant(kit, grant)
		var calling: StringName = seat.calling
		if grant.get("unlocks_secondary_calling", false) and calling == Callings.UNSWORN_ID:
			calling = pick_calling(seat.class_id, seat.companion)
		NetworkManager.current.grant_seat(seat.player_id, kit.to_dict(), calling)
	_open_seal_slots(level)


## Host: a level that opens a slot of the Seal-and-Tuck hand fills it with the Fellowship's
## starting seal in every chosen hand (on the seats and in the saves), as milestones auto-slot
## kits; a hand nobody chose grows by itself (EquipmentSealComponent's default).
func _open_seal_slots(level: int) -> void:
	var catalog: ArsenalCatalog = ArsenalCatalog.current
	var progress: PartyProgress = PartyProgress.current
	for class_id: StringName in ClassLoadouts.PLAYER_CLASSES:
		var saved: Dictionary = progress.seal_hand_for(class_id)
		if saved.is_empty():
			continue
		var hand: PlayerLoadoutResource = PlayerLoadoutResource.from_dict(saved)
		if catalog.apply_seal_milestone(hand, ClassLoadouts.player_class(class_id).role, level):
			progress.save_seal_hand(class_id, hand.to_network_dict())
	for seat: PartyMember in NetworkManager.current.ordered_members():
		if seat.companion or seat.seal_hand.is_empty():
			continue
		var worn: PlayerLoadoutResource = PlayerLoadoutResource.from_dict(seat.seal_hand)
		if catalog.apply_seal_milestone(worn, ClassLoadouts.player_class(seat.class_id).role, level):
			NetworkManager.current.grant_seal_hand(seat.player_id, worn.to_network_dict())


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


## The top of the screen shows nothing in play (13_PLAYTEST §2.1): only the join
## prompt while nobody's seated and a short notice when someone joins or leaves.
## The old lines (the level's hint, the keys, the network status) are kept as
## debug_banner_text() for the Developer Tools panel.
func _refresh_banner() -> void:
	var local_count: int = NetworkManager.current.local_player_count()
	var lines: PackedStringArray = PackedStringArray()
	var shown: PackedStringArray = PackedStringArray()
	if local_count == 0:
		lines.append("EVERWOOD · %s" % level_title())
		lines.append("Press Enter, or plug in a pad (or press Start), to join")
		shown.append_array(lines)
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
		shown.append(_notice)
	_debug_banner = "\n".join(lines)
	banner.text = "\n".join(shown)
	banner.visible = not shown.is_empty()


## What the top banner used to show in play (the level's hint and keys, the network status): the Developer Tools panel's.
func debug_banner_text() -> String:
	return _debug_banner


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
			start_instance = InstanceManager.instance_for_name(value)
			if start_instance == &"":
				push_warning("LevelBase: no instance is called '%s'; starting where the game starts" % value)
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
		elif arg == "--with-companions":
			auto_backfill_companions = true
	if host:
		NetworkManager.current.host_game()
	elif join:
		NetworkManager.current.join_game(_join_address)
	# Player 1 boots as the Wayfarer youth (21 doc §4).
	var first_class: StringName = NetworkManager.ANY_CLASS
	if solo_youth_boot and players != 0:
		first_class = ClassLoadouts.SOLO_BOOT_CLASS
	if players >= 0:
		for device_id: int in players:
			seat_local_player(device_id, first_class if device_id == 0 else NetworkManager.ANY_CLASS, _assist_mode)
	else:
		# Keyboard and mouse first (Player 1), then every pad already plugged in.
		seat_local_player(InputComponent.KEYBOARD_DEVICE, first_class, _assist_mode)
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
		var post: Vector3 = _demo_post_for(actor)
		var to_post: Vector3 = post - actor.global_position
		to_post.y = 0.0
		var stick: Vector2 = Vector2.ZERO
		if to_post.length() > 0.5:
			if not _demo_steering.has(actor.player_id):
				_demo_steering[actor.player_id] = NavSteering.new()
			var heading: Vector3 = _demo_steering[actor.player_id].direction(actor, post, delta)
			var yaw: float = actor.camera_yaw
			var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
			var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
			stick = Vector2(heading.dot(right), heading.dot(forward)).normalized()
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
