## Who sees the opening film, and when (docs/31). One per level (node "Prologue", so its RPCs
## meet on every peer). The host decides everything; offline counts as the host.
##
## A character is a Fellowship's hero in a tale (the game keys per-hero levels, tiers, kits
## and seal hands by Fellowship too). PartyProgress keeps which heroes have seen the film
## ([heroes] prologue_seen); a tale from before the film has no ledger, so all have seen it.
##
##   The film      plays on arrival at the Lv 1 spawn when the host's own first seat is a new
##                 hero: once, full screen, before split-screen starts, every local seat held
##                 still. A remote seat whose hero is new and joins while it plays is told to
##                 play it too, in step (an RPC with the host's start timestamp).
##   The recap     a new hero who drops in after that (a local seat or an online peer) sees
##                 the six plates in their own view only; nobody else is interrupted.
##   Seen          set when the film or recap finishes or is skipped, never on a quit mid-film
##                 (it then plays again on the next load of that character). A hero who has
##                 seen it this session carries it over to a new Fellowship.
##   Skip          only the host: seat 1 here, the host peer online, holding the pause / menu
##                 button (no new input) for skip_hold_s with a fill ring; anyone else pressing
##                 it sees "Host can skip". The host's skip reaches the clients by RPC. A recap
##                 is skipped by its own player the same way.
##   The ribbon    the film's Chime-Post rhyme stays on each watcher's HUD until they reach the
##                 OrchardGate or for its seconds of play.
## Each audio cue is posted to AudioDirector.post_cinematic_cue at its time; nothing plays.
class_name PrologueDirector
extends Node

signal film_started(start_at: float)
signal film_finished(skipped: bool)
signal recap_started(player_id: StringName)
signal recap_finished(player_id: StringName, skipped: bool)
signal cue_posted(cue_id: StringName)

const NODE_NAME: String = "Prologue"
## How long "Host can skip" shows when someone else presses pause.
const NON_HOST_HINT_S: float = 2.5
## The ribbon comes down when its player is this close (level distance) to the gate it points to.
const GATE_REACHED_M: float = 4.0
## A client asked to play a recap before its seat's view exists waits up to this many frames.
const RECAP_RETRY_FRAMES: int = 30

## Tests: false keeps the film and recaps from starting by themselves (a check starts them).
static var enabled: bool = true

var film_resource: CinematicFilmResource
var level: LevelBase
## Whether this arrival is where the film hands over (the Lv 1 spawn on Embershore).
var film_allowed: bool = false
## Where the Chime-Post ribbon points (the OrchardGate marker); Vector3.INF when this isle has none.
var gate_at: Vector3 = Vector3.INF
## The level's "finish streaming now" (returns how many jobs were still waiting).
var settle: Callable = Callable()
var film: PrologueFilm
## The seats watching the full film: player id -> their Fellowship.
var film_seats: Dictionary[StringName, StringName] = {}
## The recaps playing on this machine, by player id.
var recaps: Dictionary[StringName, PrologueRecap] = {}
## Seats whose hero has seen the film this session (watched it, recapped it, or had already).
var seen_this_session: Dictionary[StringName, bool] = {}
## Host: the recaps sent to other peers and not yet reported done.
var remote_recaps: Dictionary[StringName, bool] = {}
## The skip hold on the film, in seconds, and each recap's.
var skip_hold: float = 0.0
var recap_holds: Dictionary[StringName, float] = {}
## Ribbons up and pointing at the gate: player id -> seconds left.
var ribbons: Dictionary[StringName, float] = {}

var _decided: bool = false
var _start_unix_msec: int = 0
var _peers_told: Dictionary[int, bool] = {}
var _was_pressed: Dictionary[StringName, bool] = {}


## `allow_film`: this arrival is the film's spawn. `settle_zone` finishes the level's streaming now.
func setup(for_level: LevelBase, allow_film: bool, settle_zone: Callable = Callable()) -> void:
	level = for_level
	film_allowed = allow_film
	settle = settle_zone


func _ready() -> void:
	name = NODE_NAME
	film_resource = CinematicCatalog.film(CinematicCatalog.PROLOGUE)
	if film_resource != null and film_allowed:
		# The marker the spawn faces, by the timeline's name for it ("OrchardGate" -> POI_OrchardGate).
		var gate_id: StringName = StringName("POI_%s" % film_resource.spawn_face_toward)
		if ActOnePlaces.has_place(gate_id):
			gate_at = ActOnePlaces.centre(gate_id)
	var network: NetworkManager = NetworkManager.current
	network.player_registered.connect(_on_player_registered, CONNECT_DEFERRED)
	network.player_updated.connect(_on_player_updated, CONNECT_DEFERRED)
	network.player_unregistered.connect(_on_player_unregistered)
	# After the level's _ready, once the session's first seats are in (still before the first frame is drawn).
	_decide_at_entry.call_deferred()


func _exit_tree() -> void:
	var network: NetworkManager = NetworkManager.current
	if network != null:
		for connection: Array in [[network.player_registered, _on_player_registered], [network.player_updated, _on_player_updated],
				[network.player_unregistered, _on_player_unregistered]]:
			var sig: Signal = connection[0]
			var handler: Callable = connection[1]
			if sig.is_connected(handler):
				sig.disconnect(handler)
	if is_instance_valid(level):
		level.cinematic_playing = false


func _process(delta: float) -> void:
	_poll_film_skip(delta)
	_poll_recap_skips(delta)
	_watch_ribbons(delta)


# --- State --------------------------------------------------------------------------------

func is_film_playing() -> bool:
	return film != null and is_instance_valid(film) and not film.ended


## Whether this peer decides (the host, or a party playing offline).
func deciding() -> bool:
	return NetworkManager.current.is_host()


## This peer's first seat: the local person with the lowest party slot ("seat 1" here).
func lead_seat() -> PartyMember:
	var me: int = NetworkManager.current.local_peer_id()
	for seat: PartyMember in NetworkManager.current.ordered_members():
		if seat.peer_id == me and not seat.companion:
			return seat
	return null


func _actor(player_id: StringName) -> ActorBase:
	var actor: ActorBase = level.actors.get(player_id) as ActorBase if is_instance_valid(level) else null
	return actor if is_instance_valid(actor) else null


func _is_local(seat: PartyMember) -> bool:
	return seat != null and seat.peer_id == NetworkManager.current.local_peer_id() and not seat.companion


# --- Deciding ---------------------------------------------------------------------------------

func _decide_at_entry() -> void:
	_decided = true
	if not enabled or film_resource == null or not deciding():
		return
	var lead: PartyMember = lead_seat()
	if film_allowed and lead != null and not PartyProgress.current.has_seen_prologue(lead.class_id):
		start_film(0.0)
	for seat: PartyMember in NetworkManager.current.ordered_members():
		consider(seat)


## Host: what a seat sees now: the film (it's playing), a recap (a new hero, the film over), or nothing.
func consider(seat: PartyMember) -> void:
	if seat == null or seat.companion or not deciding() or film_resource == null:
		return
	var seen: bool = PartyProgress.current.has_seen_prologue(seat.class_id)
	if is_film_playing():
		if _is_local(seat):
			_join_film(seat)
		elif not seen:
			_join_film(seat)
			_tell_peer_film(seat.peer_id)
		return
	if seen:
		seen_this_session[seat.player_id] = true
		return
	if seen_this_session.has(seat.player_id) or recaps.has(seat.player_id) or remote_recaps.has(seat.player_id):
		return
	start_recap(seat)


func _on_player_registered(seat: PartyMember) -> void:
	if not _decided or not enabled:
		return
	if deciding():
		consider(seat)
	elif is_film_playing() and _is_local(seat):
		# A client's own seat joining while the host's film plays here watches it too.
		_join_film(seat)


func _on_player_updated(seat: PartyMember) -> void:
	# A hero who has seen it this session carries it over to a new Fellowship.
	if deciding() and seen_this_session.has(seat.player_id) and not PartyProgress.current.has_seen_prologue(seat.class_id):
		var classes: Array[StringName] = [seat.class_id]
		PartyProgress.current.mark_prologue_seen(classes)


func _on_player_unregistered(player_id: StringName) -> void:
	film_seats.erase(player_id)
	ribbons.erase(player_id)
	remote_recaps.erase(player_id)
	recap_holds.erase(player_id)
	if recaps.has(player_id):
		var recap: PrologueRecap = recaps[player_id]
		recaps.erase(player_id)
		if is_instance_valid(recap):
			recap.queue_free()
	if is_film_playing() and is_instance_valid(film.lead) and film.lead.player_id == player_id:
		# The player the film hands over to has gone: the rest of the couch gets their screens back.
		film.skip_to_end()


# --- The film ---------------------------------------------------------------------------------

## Plays the film from `start_at` seconds (a client joining the host's film part-way starts later).
func start_film(start_at: float) -> void:
	if is_film_playing() or film_resource == null:
		return
	var lead: PartyMember = lead_seat()
	var lead_actor: ActorBase = _actor(lead.player_id) if lead != null else null
	if lead_actor == null:
		return
	film = PrologueFilm.new()
	film.setup(film_resource, lead_actor, level.grid, not deciding(), start_at, settle)
	film.cue_fired.connect(_on_cue_fired)
	film.ribbon_due.connect(_on_ribbon_due)
	film.finished.connect(_on_film_finished)
	level.cinematic_playing = true
	skip_hold = 0.0
	_peers_told.clear()
	_start_unix_msec = int(Time.get_unix_time_from_system() * 1000.0) - int(start_at * 1000.0)
	for seat: PartyMember in NetworkManager.current.ordered_members():
		if _is_local(seat):
			_join_film(seat)
	add_child(film)
	film_started.emit(start_at)


func _join_film(seat: PartyMember) -> void:
	film_seats[seat.player_id] = seat.class_id
	var actor: ActorBase = _actor(seat.player_id)
	if actor != null and actor.input != null:
		actor.input.cinematic_hold = true


## Host: tells a peer the film is on, with when it started on the host's clock and when this was sent.
func _tell_peer_film(peer_id: int) -> void:
	if not NetworkManager.current.is_online() or _peers_told.has(peer_id) or not NetworkManager.current.has_peer(peer_id):
		return
	_peers_told[peer_id] = true
	_rpc_film_start.rpc_id(peer_id, _start_unix_msec, int(Time.get_unix_time_from_system() * 1000.0))


## Client: the host's film is on. It started at `start_unix_msec` (the host's clock), and this was
## sent at `sent_unix_msec` (the same clock), so it's that far in, plus half the round trip.
@rpc("authority", "call_remote", "reliable")
func _rpc_film_start(start_unix_msec: int, sent_unix_msec: int) -> void:
	take_film_start_from(multiplayer.get_remote_sender_id(), start_unix_msec, sent_unix_msec)


## Whether a client takes the host's word (a film's start or skip) from `sender_id`: only from
## peer 1, the host; and the host takes it from nobody.
static func accepts_host_word(sender_id: int, is_host: bool) -> bool:
	return not is_host and sender_id == 1


## The start as a client takes it: only from the host. Returns whether it started.
func take_film_start_from(sender_id: int, start_unix_msec: int, sent_unix_msec: int) -> bool:
	if not accepts_host_word(sender_id, deciding()):
		return false
	start_film(maxf(0.0, float(sent_unix_msec - start_unix_msec) / 1000.0 + _host_latency_s()))
	return is_film_playing()


func _host_latency_s() -> float:
	var enet: ENetMultiplayerPeer = multiplayer.multiplayer_peer as ENetMultiplayerPeer
	var host: ENetPacketPeer = enet.get_peer(1) if enet != null else null
	return host.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME) / 2000.0 if host != null else 0.0


## Host: skips the film here and on every peer playing it.
func skip_film() -> void:
	if not deciding() or not is_film_playing():
		return
	if NetworkManager.current.is_online():
		for peer_id: int in _peers_told:
			if NetworkManager.current.has_peer(peer_id):
				_rpc_film_skip.rpc_id(peer_id)
	film.skip_to_end()


@rpc("authority", "call_remote", "reliable")
func _rpc_film_skip() -> void:
	take_skip_from(multiplayer.get_remote_sender_id())


## A skip as a client takes it: only from the host. Returns whether it skipped.
func take_skip_from(sender_id: int) -> bool:
	if not accepts_host_word(sender_id, deciding()) or not is_film_playing():
		return false
	film.skip_to_end()
	return true


## Seat 1 here holding pause skips (when this peer is the host); anyone else pressing it is told who can.
func _poll_film_skip(delta: float) -> void:
	if not is_film_playing():
		skip_hold = 0.0
		return
	var lead: ActorBase = film.lead if is_instance_valid(film.lead) else null
	for player_id: StringName in film_seats:
		var actor: ActorBase = _actor(player_id)
		if actor == null or actor.input == null:
			continue
		var down: bool = actor.input.is_held(InputComponent.ACTION_OPTIONS)
		var pressed: bool = down and not _was_pressed.get(player_id, false)
		_was_pressed[player_id] = down
		if pressed and not (deciding() and actor == lead):
			film.flash_hint(film_resource.skip_non_host_hint, NON_HOST_HINT_S)
	if not deciding() or lead == null or lead.input == null:
		return
	skip_hold = skip_hold + delta if lead.input.is_held(InputComponent.ACTION_OPTIONS) else 0.0
	film.set_skip_progress(skip_hold / maxf(film_resource.skip_hold_s, 0.001))
	if skip_hold >= film_resource.skip_hold_s:
		skip_film()


func _on_cue_fired(cue: CinematicCueResource) -> void:
	if AudioDirector.current != null:
		AudioDirector.current.post_cinematic_cue(film_resource.film_id, cue.cue_id, cue.at_s)
	cue_posted.emit(cue.cue_id)


func _on_film_finished(skipped: bool) -> void:
	var classes: Array[StringName] = []
	for player_id: StringName in film_seats:
		var seat: PartyMember = NetworkManager.current.member(player_id)
		classes.append(seat.class_id if seat != null else film_seats[player_id])
		seen_this_session[player_id] = true
		_release(player_id)
	if deciding():
		PartyProgress.current.mark_prologue_seen(classes)
	film_seats.clear()
	_was_pressed.clear()
	skip_hold = 0.0
	if is_instance_valid(level):
		level.cinematic_playing = false
	film = null
	film_finished.emit(skipped)


func _release(player_id: StringName) -> void:
	var actor: ActorBase = _actor(player_id)
	if actor != null and actor.input != null:
		actor.input.cinematic_hold = false
	var hud: PlayerHUD = level.huds.get(player_id) as PlayerHUD if is_instance_valid(level) else null
	if is_instance_valid(hud):
		hud.film_released()


# --- The Chime-Post ribbon -----------------------------------------------------------------------

func _on_ribbon_due(heading: String, text: String, seconds: float) -> void:
	for player_id: StringName in film_seats:
		var hud: PlayerHUD = level.huds.get(player_id) as PlayerHUD
		if is_instance_valid(hud) and hud.cross_grimoire != null:
			hud.cross_grimoire.show_ribbon_line(heading, text, seconds)
			ribbons[player_id] = seconds


## Each ribbon comes down when its player reaches the gate (or its time runs out).
func _watch_ribbons(delta: float) -> void:
	for player_id: StringName in ribbons.keys():
		var left: float = ribbons[player_id] - delta
		var actor: ActorBase = _actor(player_id)
		if left <= 0.0 or actor == null:
			ribbons.erase(player_id)
			continue
		ribbons[player_id] = left
		if gate_at == Vector3.INF or (actor.input != null and actor.input.cinematic_hold):
			continue
		if Vector2(actor.global_position.x - gate_at.x, actor.global_position.z - gate_at.z).length() <= GATE_REACHED_M:
			var hud: PlayerHUD = level.huds.get(player_id) as PlayerHUD
			if is_instance_valid(hud) and hud.cross_grimoire != null:
				hud.cross_grimoire.hide_ribbon()
			ribbons.erase(player_id)


# --- The recap -------------------------------------------------------------------------------

## Host: a new hero dropped in late sees the recap in their own view (on their own machine).
func start_recap(seat: PartyMember) -> void:
	if seat == null or not deciding():
		return
	if _is_local(seat):
		play_recap(seat.player_id)
	elif NetworkManager.current.is_online() and NetworkManager.current.has_peer(seat.peer_id):
		remote_recaps[seat.player_id] = true
		_rpc_play_recap.rpc_id(seat.peer_id, String(seat.player_id))


## Plays the recap in a local seat's view, holding only that player. Returns whether it started.
func play_recap(player_id: StringName) -> bool:
	if recaps.has(player_id) or film_resource == null:
		return false
	var actor: ActorBase = _actor(player_id)
	var overlay: Control = level.grid.overlay_for(player_id) if is_instance_valid(level) else null
	if actor == null or actor.input == null or overlay == null:
		return false
	var recap: PrologueRecap = PrologueRecap.new()
	recap.setup(film_resource, actor)
	recap.finished.connect(_on_recap_finished.bind(player_id))
	overlay.add_child(recap)
	recaps[player_id] = recap
	recap_holds[player_id] = 0.0
	actor.input.cinematic_hold = true
	recap_started.emit(player_id)
	return true


@rpc("authority", "call_remote", "reliable")
func _rpc_play_recap(player_id: String) -> void:
	if not accepts_host_word(multiplayer.get_remote_sender_id(), deciding()):
		return
	_play_recap_soon(StringName(player_id), RECAP_RETRY_FRAMES)


## A client's seat may still be on its way when the host's word arrives: try again a few frames on.
func _play_recap_soon(player_id: StringName, tries: int) -> void:
	if play_recap(player_id) or tries <= 0 or not is_inside_tree():
		return
	await get_tree().process_frame
	_play_recap_soon(player_id, tries - 1)


func _poll_recap_skips(delta: float) -> void:
	for player_id: StringName in recaps.keys():
		var recap: PrologueRecap = recaps[player_id]
		var actor: ActorBase = _actor(player_id)
		if not is_instance_valid(recap) or actor == null or actor.input == null:
			continue
		var hold: float = recap_holds.get(player_id, 0.0) + delta if actor.input.is_held(InputComponent.ACTION_OPTIONS) else 0.0
		recap_holds[player_id] = hold
		recap.set_skip_progress(hold / maxf(film_resource.skip_hold_s, 0.001))
		if hold >= film_resource.skip_hold_s:
			recap.skip()


func _on_recap_finished(skipped: bool, player_id: StringName) -> void:
	recaps.erase(player_id)
	recap_holds.erase(player_id)
	seen_this_session[player_id] = true
	_release(player_id)
	var seat: PartyMember = NetworkManager.current.member(player_id)
	if deciding():
		if seat != null:
			var classes: Array[StringName] = [seat.class_id]
			PartyProgress.current.mark_prologue_seen(classes)
	elif NetworkManager.current.is_online():
		_rpc_recap_done.rpc_id(1, String(player_id))
	recap_finished.emit(player_id, skipped)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_recap_done(player_id: String) -> void:
	take_recap_done_from(multiplayer.get_remote_sender_id(), StringName(player_id))


## Host: a peer says its seat's recap is over. Only that seat's own peer can say so.
func take_recap_done_from(sender_id: int, player_id: StringName) -> bool:
	var seat: PartyMember = NetworkManager.current.member(player_id)
	if not deciding() or seat == null or seat.peer_id != sender_id:
		return false
	remote_recaps.erase(player_id)
	seen_this_session[player_id] = true
	var classes: Array[StringName] = [seat.class_id]
	PartyProgress.current.mark_prologue_seen(classes)
	return true
