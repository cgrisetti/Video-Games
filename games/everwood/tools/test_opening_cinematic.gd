## The opening film's checks (docs/31), on scratch tales (never the family's saves):
##   - the timeline: six shots end to end from 0.0 to 30.0 s, every caption inside its shot,
##     every cue inside its shot and no cue id twice, the captions word for word and time for
##     time as the .srt has them, every plate there, every effect and curve one the film draws
##   - the save: a new tale's heroes haven't seen it, an older tale (no ledger) and no save at
##     all count as seen, and the seen flag is written and read back
##   - an existing character arrives with no film; a new character's arrival plays it from the
##     first frame, holds the party still, posts every cue in order, captions on time, streams
##     the zone in under the page, lands the dive on the rig's spawn pose within 1 cm and 0.1
##     degrees, hands over to the rig's camera, unfurls the ribbon and gives control back at 30 s
##   - skip: another seat's 1.5 s hold is ignored ("Host can skip"); the host's 1.5 s hold
##     reaches the same end state as the film's own end, saves both heroes as having seen it
##     and gives control back at once; a non-host's word over the network is refused
##   - a new hero dropping in late sees the recap in their own view only, while the others
##     play on; their own hold skips it, or it ends after its six pages, and they're saved as seen
extends RefCounted

const CALDERA_SCENE: String = "res://scenes/worlds/caldera_isles.tscn"
const SCRATCH_TALE: String = "user://smoke_prologue_tale.cfg"
const SCRATCH_OLD_TALE: String = "user://smoke_prologue_old_tale.cfg"
const SCRATCH_MISSING: String = "user://smoke_prologue_no_such_tale.cfg"
## Frames to wait for the Caldera to load and seat the party.
const LOAD_FRAMES: int = 8
## The first pad id tried for the extra seats (high, so a real pad can't collide).
const FIRST_FAKE_PAD: int = 11

var tree: SceneTree
var check: Callable
var film: CinematicFilmResource
## The film's end state when it plays out, to hold the skip's end state to.
var _natural_end: Dictionary = {}


func run(scene_tree: SceneTree, checker: Callable, restore_save: String) -> void:
	tree = scene_tree
	check = checker
	film = CinematicCatalog.film(CinematicCatalog.PROLOGUE)
	check.call(film != null, "the opening film is registered in the CinematicCatalog, built from its timeline JSON")
	if film == null:
		return
	var kits_before: bool = PartyProgress.current.endgame_kits_for_testing
	var dropped: Array[int] = _keep_only_player_one()
	_check_timeline()
	_check_save_flag()
	await _check_existing_character()
	await _check_new_character()
	await _check_skip()
	await _check_recap()
	_check_network_words()
	# Back as the smoke test left it: its own save, its kits, its seats.
	for pad: int in _fake_pads_seated():
		NetworkManager.current.drop_local_player(pad)
	PartyProgress.current.use_save_file(restore_save)
	PartyProgress.current.endgame_kits_for_testing = kits_before
	for device: int in dropped:
		NetworkManager.current.request_local_player(device, NetworkManager.ANY_CLASS, InputComponent.AssistMode.ADVENTURER)
	await _frames(4)
	for path: String in [SCRATCH_TALE, SCRATCH_OLD_TALE, SCRATCH_MISSING]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _frames(count: int) -> void:
	for i: int in count:
		await tree.process_frame


# --- The timeline ----------------------------------------------------------------------------

func _check_timeline() -> void:
	var shots: Array[CinematicShotResource] = film.shots
	var contiguous: bool = shots.size() == 6
	for index: int in shots.size():
		contiguous = contiguous and shots[index].index == index + 1 and shots[index].end_s > shots[index].start_s
		if index > 0:
			contiguous = contiguous and is_equal_approx(shots[index].start_s, shots[index - 1].end_s)
	check.call(contiguous and is_equal_approx(shots[0].start_s, 0.0) and is_equal_approx(shots[-1].end_s, 30.0)
		and is_equal_approx(film.duration_s, 30.0) and is_equal_approx(film.control_unlock_s, 30.0),
		"the timeline: six shots, numbered in order and end to end, from 0.0 to 30.0 s; control comes back at 30.0 s")
	var captions_inside: bool = true
	var cues_inside: bool = true
	var ids: Dictionary[StringName, bool] = {}
	var unique: bool = true
	for shot: CinematicShotResource in shots:
		captions_inside = captions_inside and not shot.captions.is_empty()
		for caption: CinematicCaptionResource in shot.captions:
			captions_inside = captions_inside and caption.start_s >= shot.start_s and caption.end_s <= shot.end_s and caption.end_s > caption.start_s
		for cue: CinematicCueResource in shot.cues:
			cues_inside = cues_inside and cue.at_s >= shot.start_s and cue.at_s <= shot.end_s
			unique = unique and not ids.has(cue.cue_id) and cue.cue_id != &""
			ids[cue.cue_id] = true
	check.call(captions_inside, "every shot has a caption, and every caption starts and ends inside its shot")
	check.call(unique and ids.size() == film.all_cues().size() and ids.size() >= 20 and cues_inside,
		"every audio cue id is used once (%d) and falls inside its shot" % ids.size())
	var srt: Array[CinematicCaptionResource] = CinematicCatalog.read_srt(CinematicCatalog.PROLOGUE_CAPTIONS)
	var timed: Array[CinematicCaptionResource] = film.all_captions()
	var same: bool = srt.size() == timed.size() and not srt.is_empty()
	for index: int in mini(srt.size(), timed.size()):
		same = same and srt[index].text == timed[index].text and absf(srt[index].start_s - timed[index].start_s) < 0.001 \
			and absf(srt[index].end_s - timed[index].end_s) < 0.001
	check.call(same, "the captions match the .srt word for word and to the millisecond (%d captions)" % srt.size())
	var plates: bool = true
	for shot: CinematicShotResource in shots:
		var texture: Texture2D = load(shot.any_plate()) as Texture2D if ResourceLoader.exists(shot.any_plate()) else null
		plates = plates and texture != null and texture.get_width() == film.resolution_ref.x and texture.get_height() == film.resolution_ref.y
		plates = plates and (shot.is_live() == (shot.plate_path == "")) and (shot.is_live() or shot.camera_kind == CinematicShotResource.CAMERA_PAN_ZOOM)
	var live: CinematicShotResource = film.live_shot()
	check.call(plates and live != null and live == shots[-1] and live.camera_kind == CinematicShotResource.CAMERA_DIVE_TO_RIG
		and film.recap_shots().size() == 6,
		"shots 1 to 5 draw their own 1920 x 1080 plates, shot 6 is live 3D with its plate a reference only, and the recap finds all six")
	var known: bool = true
	for shot: CinematicShotResource in shots:
		known = known and CinematicFilmResource.EASES.has(shot.camera_ease)
		for effect: CinematicEffectResource in shot.effects:
			known = known and CinematicEffectResource.KINDS.has(effect.kind) and CinematicFilmResource.EASES.has(effect.ease_curve)
		if not shot.is_live():
			known = known and [CinematicShotResource.CROSSFADE, CinematicShotResource.PAGE_TURN, CinematicShotResource.PAGE_DISSOLVE_TO_3D].has(shot.transition_kind)
	check.call(known and live.dive_start_s >= live.start_s and live.dive_end_s <= live.end_s and live.dive_start_offset.y > 0.0
		and film.skip_hold_s > 0.0 and film.effect(CinematicEffectResource.CHIME_POST_RIBBON).persist_play_s > 0.0,
		"every effect, curve and hand-over the timeline names is one the film draws; the dive and its offset, the skip hold and the ribbon's time are read from it")


# --- The save ----------------------------------------------------------------------------------

func _check_save_flag() -> void:
	var progress: PartyProgress = PartyProgress.current
	var lead_class: StringName = _lead_class()
	progress.begin_new_tale(SCRATCH_TALE, "Wren")
	var written: ConfigFile = ConfigFile.new()
	written.load(SCRATCH_TALE)
	check.call(progress.prologue_ledger and not progress.has_seen_prologue(lead_class) and written.has_section_key("heroes", "prologue_seen")
		and (written.get_value("heroes", "prologue_seen", {"x": 1}) as Dictionary).is_empty(),
		"a new character: the tale keeps the film's ledger ([heroes] prologue_seen), empty, so its heroes haven't seen it")
	written.erase_section_key("heroes", "prologue_seen")
	written.save(SCRATCH_OLD_TALE)
	progress.use_save_file(SCRATCH_OLD_TALE)
	var old_seen: bool = progress.has_seen_prologue(lead_class) and not progress.prologue_ledger
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_MISSING))
	progress.use_save_file(SCRATCH_MISSING)
	check.call(old_seen and progress.has_seen_prologue(lead_class) and not FileAccess.file_exists(SCRATCH_MISSING),
		"a tale saved before the film (no prologue_seen) and no save at all count as seen (and nothing is written)")
	progress.use_save_file(SCRATCH_TALE)
	var classes: Array[StringName] = [lead_class]
	progress.mark_prologue_seen(classes)
	progress.use_save_file(SCRATCH_TALE)
	check.call(progress.prologue_ledger and progress.has_seen_prologue(lead_class),
		"seeing it saves the hero's prologue_seen flag, read back on the next load")


# --- An existing character, then a new one -------------------------------------------------------

func _check_existing_character() -> void:
	PartyProgress.current.use_save_file(SCRATCH_OLD_TALE)
	var level: CalderaArchipelagoWorld = await _load_caldera()
	var p1: ActorBase = _p1(level)
	check.call(level != null and level.prologue != null and not level.prologue.is_film_playing() and p1 != null
		and not p1.input.cinematic_hold and _films_in(level) == 0 and level.grid.spotlight == &"" and not level.cinematic_playing,
		"an existing character arrives at the Lv 1 spawn with no film: nothing held, nothing spotlit")


func _check_new_character() -> void:
	PartyProgress.current.begin_new_tale(SCRATCH_TALE, "Wren")
	var heard_before: int = AudioDirector.current.cinematic_cues_heard.size()
	var level: CalderaArchipelagoWorld = await _load_caldera(1)
	var director: PrologueDirector = level.prologue if level != null else null
	var playing: bool = director != null and director.is_film_playing()
	check.call(playing and director.film.page_shown() and director.film.elapsed < 0.1,
		"a new character's arrival plays the film from its first frame, a storybook page over the world (%.3f s in)" % (director.film.elapsed if playing else -1.0))
	if not playing:
		return
	await _frames(LOAD_FRAMES)
	var p1: ActorBase = _p1(level)
	var rig: PlayerCamera = level.grid.camera_for(p1.player_id)
	var at: Vector3 = p1.global_position
	p1.input.inject_move(Vector2(0.0, 1.0))
	await _frames(20)
	check.call(p1.input.cinematic_hold and p1.global_position.distance_to(at) < 0.05 and level.grid.spotlight == p1.player_id
		and level.grid.shown_view_count() == 1 and level.cinematic_playing and not rig.current,
		"the party is held still under it (a walk goes nowhere), the lead's view alone and full screen, the dive camera current in it")
	p1.input.release_script()
	# The rig's spawn pose: where it comes to rest over the hero standing at the spawn.
	var spawn_pose: Transform3D = await _settled_pose(rig)
	var shown: FilmMoment = _moment(director.film, 2.0)
	check.call(shown.caption == film.all_captions()[0].text and shown.page,
		"at 2 s the first caption shows on the page: \"%s\"" % shown.caption)
	shown = _moment(director.film, 16.0)
	check.call(shown.caption == film.caption_at(16.0).text and shown.page and director.film.cues_fired.size() == _cues_up_to(16.0),
		"at 16 s the fourth caption shows and every cue up to then is posted, in order")
	director.film.seek(24.4)
	var streamer: ArchipelagoStreamer = level.streamer
	check.call(director.film.settled and int(streamer.counts()["pending"]) == 0 and streamer.has_ground_at(p1.global_position) and director.film.page_shown(),
		"the zone streams in under the page: before it dissolves, nothing is still loading and the spawn's ground is there (%d jobs waited)" % director.film.pending_at_settle)
	shown = _moment(director.film, 25.6)
	var dive: Camera3D = director.film.dive_camera
	check.call(not director.film.page_shown() and dive != null and dive.current and dive.global_position.distance_to(rig.global_position) > 5.0,
		"at 25.6 s the page has dissolved into the live world and the dive camera is still high above the rig")
	shown = _moment(director.film, 28.2)
	check.call(director.film.title_shown() and director.film.title_inked() >= 1.0 and shown.caption == "",
		"at 28.2 s the title card has inked on (EVERWOOD / The Caldera Isles)")
	var film_node: PrologueFilm = director.film
	film_node.seek(29.0)
	var error: Vector2 = film_node.handoff_error()
	var live: CinematicShotResource = film.live_shot()
	var from_spawn: float = film_node.handoff_dive.origin.distance_to(spawn_pose.origin)
	var spawn_turn: float = rad_to_deg((film_node.handoff_dive.basis.get_rotation_quaternion().inverse() * spawn_pose.basis.get_rotation_quaternion()).normalized().get_angle())
	check.call(film_node.is_handed_off and error.x <= live.handoff_position_m and error.y <= live.handoff_angle_deg
		and from_spawn <= live.handoff_position_m and spawn_turn <= live.handoff_angle_deg and film_node.handoff_fov_gap < 0.01,
		"the dive's last frame is the rig's spawn pose: %.4f m and %.4f degrees from the rig, %.4f m and %.4f degrees from its pose at spawn, same lens" % [
			error.x, error.y, from_spawn, spawn_turn])
	var hud: PlayerHUD = level.huds.get(p1.player_id) as PlayerHUD
	var ribbon: String = film.effect(CinematicEffectResource.CHIME_POST_RIBBON).text
	await _frames(1)
	check.call(rig.current and film_node.dive_camera == null and not is_instance_valid(dive) and hud.cross_grimoire.ribbon_text() == ribbon
		and p1.input.cinematic_hold and director.is_film_playing(),
		"at 29 s the rig's own camera is current (the dive camera gone), the Chime-Post ribbon unfurls, and control is still held")
	film_node.seek(30.0)
	await _frames(2)
	_natural_end = _end_state(level)
	var heard: PackedStringArray = AudioDirector.current.cinematic_cues_heard.slice(heard_before)
	var in_order: bool = heard.size() == film.all_cues().size()
	for index: int in mini(heard.size(), film.all_cues().size()):
		in_order = in_order and heard[index] == "%s:%s" % [film.film_id, film.all_cues()[index].cue_id]
	check.call(in_order, "every audio cue reached the score's hook in time order (%d), and the score plays nothing for them" % heard.size())
	check.call(not _natural_end["playing"] and not _natural_end["held"] and _natural_end["spotlight"] == "" and not _natural_end["cinematic"]
		and _natural_end["rig_current"] and _natural_end["ribbon"] == ribbon and _natural_end["seen"] and _natural_end["saved"],
		"at 30 s control comes back: nothing held or spotlit, the rig current, the ribbon up and prologue_seen saved")
	at = p1.global_position
	p1.input.inject_move(Vector2(0.0, 1.0))
	await _frames(30)
	p1.input.release_script()
	check.call(p1.global_position.distance_to(at) > 0.3, "after the film the hero walks again")


# --- Skip --------------------------------------------------------------------------------------

func _check_skip() -> void:
	PartyProgress.current.begin_new_tale(SCRATCH_TALE, "Wren")
	var pad: int = _free_pad()
	NetworkManager.current.request_local_player(pad, NetworkManager.ANY_CLASS, InputComponent.AssistMode.ADVENTURER)
	var level: CalderaArchipelagoWorld = await _load_caldera()
	var director: PrologueDirector = level.prologue if level != null else null
	var p1: ActorBase = _p1(level)
	var p2: ActorBase = level.actors.get(PartyMember.make_player_id(NetworkManager.current.local_peer_id(), pad)) as ActorBase if level != null else null
	if director == null or not director.is_film_playing() or p2 == null:
		check.call(false, "a couch of two new characters gets the film (it didn't start, or the second seat is missing)")
		return
	check.call(director.film_seats.size() == 2 and p2.input.cinematic_hold and level.grid.shown_view_count() == 1,
		"two new characters on the couch: one film, full screen, before split-screen starts (both seats held)")
	var film_node: PrologueFilm = director.film
	film_node.seek(6.0)
	p2.input.inject_hold(InputComponent.ACTION_OPTIONS, true)
	await _frames(roundi(film.skip_hold_s * 60.0 * 1.4))
	check.call(director.is_film_playing() and director.skip_hold == 0.0 and film_node.skip_line() == film.skip_non_host_hint
		and p2.input.cinematic_hold and NetworkManager.current.is_device_seated(pad),
		"another seat's %.1f s hold of pause is ignored: the film plays on, \"%s\" shows, and the seat doesn't leave" % [film.skip_hold_s, film_node.skip_line()])
	p2.input.inject_hold(InputComponent.ACTION_OPTIONS, false)
	await _frames(2)
	p1.input.inject_hold(InputComponent.ACTION_OPTIONS, true)
	var frames: int = 0
	var ring_seen: float = 0.0
	while director.is_film_playing() and frames < 240:
		await tree.process_frame
		frames += 1
		if is_instance_valid(film_node):
			ring_seen = maxf(ring_seen, film_node.skip_progress)
	var held_for: float = float(frames) / 60.0
	check.call(not director.is_film_playing() and film_node == null or not is_instance_valid(film_node) or film_node.was_skipped,
		"the host (seat 1) skips by holding pause")
	check.call(absf(held_for - film.skip_hold_s) <= 0.1 and ring_seen >= 0.9,
		"the skip takes a %.1f s hold (%.2f s here), the ring filling as it's held" % [film.skip_hold_s, held_for])
	p1.input.inject_hold(InputComponent.ACTION_OPTIONS, false)
	await _frames(3)
	var end: Dictionary = _end_state(level)
	var same: bool = true
	for key: String in _natural_end:
		same = same and end.get(key) == _natural_end[key]
	check.call(same, "a skip lands on the same end state as the film's own end (%s)" % str(end))
	var p2_class: StringName = NetworkManager.current.member(p2.player_id).class_id
	var file: ConfigFile = ConfigFile.new()
	file.load(SCRATCH_TALE)
	var saved: Dictionary = file.get_value("heroes", "prologue_seen", {}) as Dictionary
	check.call(bool(saved.get(String(_lead_class()), false)) and bool(saved.get(String(p2_class), false)),
		"the skip saves prologue_seen for both heroes who watched (%s)" % str(saved))
	var hud: PlayerHUD = level.huds.get(p1.player_id) as PlayerHUD
	check.call(hud.options_menu() == null and not p1.input.cinematic_hold and not p2.input.cinematic_hold,
		"control comes back at once, and letting go of the skip's hold doesn't open the Options menu")
	var at: Vector3 = p1.global_position
	p1.input.inject_move(Vector2(0.0, 1.0))
	await _frames(30)
	p1.input.release_script()
	p2.input.release_script()
	check.call(p1.global_position.distance_to(at) > 0.3, "after the skip the hero walks at once")


# --- The recap -----------------------------------------------------------------------------------

func _check_recap() -> void:
	var level: CalderaArchipelagoWorld = tree.current_scene as CalderaArchipelagoWorld
	var director: PrologueDirector = level.prologue if level != null else null
	if director == null:
		check.call(false, "a level to drop a late hero into")
		return
	# A Fellowship nobody here has played in this tale: the next seat's (the least used).
	var progress: PartyProgress = PartyProgress.current
	var next_class: StringName = level.least_used_class(NetworkManager.current.roster)
	progress.prologue_seen.erase(next_class)
	progress.save()
	var pad: int = _free_pad()
	var late_id: StringName = PartyMember.make_player_id(NetworkManager.current.local_peer_id(), pad)
	NetworkManager.current.request_local_player(pad, NetworkManager.ANY_CLASS, InputComponent.AssistMode.ADVENTURER)
	await _frames(3)
	var recap: PrologueRecap = director.recaps.get(late_id, null) as PrologueRecap
	var late: ActorBase = level.actors.get(late_id) as ActorBase
	var p1: ActorBase = _p1(level)
	var own_view: bool = recap != null and recap.get_parent() == level.grid.overlay_for(late_id)
	check.call(own_view and late != null and late.input.cinematic_hold and not p1.input.cinematic_hold and not director.is_film_playing()
		and level.grid.spotlight == &"" and recap.pages.size() == 6,
		"a new hero dropping in late gets the six-page recap in their own view only; the others play on, the screen still split")
	if recap == null:
		return
	var at: Vector3 = p1.global_position
	p1.input.inject_move(Vector2(0.0, 1.0))
	await _frames(20)
	p1.input.release_script()
	check.call(p1.global_position.distance_to(at) > 0.2, "nobody else is interrupted: Player 1 walks while the recap plays")
	recap.seek(film.recap_seconds_per_plate * 1.5)
	check.call(recap.page_index() == 1 and recap.caption_text() == film.shots[1].captions[0].text,
		"each page takes %.1f s with its shot's caption (page 2: \"%s\")" % [film.recap_seconds_per_plate, recap.caption_text()])
	late.input.inject_hold(InputComponent.ACTION_OPTIONS, true)
	var frames: int = 0
	while is_instance_valid(recap) and not recap.ended and frames < 240:
		await tree.process_frame
		frames += 1
	late.input.inject_hold(InputComponent.ACTION_OPTIONS, false)
	await _frames(2)
	var late_class: StringName = NetworkManager.current.member(late_id).class_id
	check.call(not director.recaps.has(late_id) and not late.input.cinematic_hold and absf(float(frames) / 60.0 - film.skip_hold_s) <= 0.1
		and progress.has_seen_prologue(late_class) and NetworkManager.current.is_device_seated(pad),
		"that player skips their own recap with a %.1f s hold (%.2f s): let go, still seated, and saved as seen" % [film.skip_hold_s, float(frames) / 60.0])
	# Once more to the end, unskipped.
	NetworkManager.current.drop_local_player(pad)
	await _frames(3)
	progress.prologue_seen.erase(late_class)
	director.seen_this_session.erase(late_id)
	NetworkManager.current.request_local_player(pad, NetworkManager.ANY_CLASS, InputComponent.AssistMode.ADVENTURER)
	await _frames(3)
	recap = director.recaps.get(late_id, null) as PrologueRecap
	var had_recap: bool = recap != null
	if had_recap:
		recap.seek(recap.length())
		await _frames(2)
	var again: ActorBase = level.actors.get(late_id) as ActorBase
	check.call(had_recap and not director.recaps.has(late_id) and again != null and not again.input.cinematic_hold
		and progress.has_seen_prologue(NetworkManager.current.member(late_id).class_id),
		"a recap left to run ends after its last page and saves its hero as seen")
	NetworkManager.current.drop_local_player(pad)
	await _frames(2)


# --- Over the network ------------------------------------------------------------------------------

func _check_network_words() -> void:
	var level: CalderaArchipelagoWorld = tree.current_scene as CalderaArchipelagoWorld
	var director: PrologueDirector = level.prologue if level != null else null
	if director == null:
		return
	var late_id: StringName = PartyMember.make_player_id(NetworkManager.current.local_peer_id(), InputComponent.KEYBOARD_DEVICE)
	check.call(not director.take_skip_from(2) and not director.take_skip_from(1) and not director.take_film_start_from(3, 0, 0)
		and not director.take_recap_done_from(7, late_id),
		"over the network only the host's word counts: a skip or film start from anyone else is refused, and a peer can't finish another's recap")
	check.call(PrologueDirector.accepts_host_word(1, false) and not PrologueDirector.accepts_host_word(2, false) and not PrologueDirector.accepts_host_word(1, true),
		"a client takes the film's start and skip from the host (peer 1) alone, and the host takes neither from anyone")


# --- Helpers -------------------------------------------------------------------------------------------

class FilmMoment:
	var caption: String = ""
	var page: bool = false


func _moment(film_node: PrologueFilm, at_s: float) -> FilmMoment:
	film_node.seek(at_s)
	var shown: FilmMoment = FilmMoment.new()
	shown.caption = film_node.caption_text()
	shown.page = film_node.page_shown()
	return shown


## The camera's pose once it has come to rest (two frames in a row within a millimetre), up to two seconds.
func _settled_pose(camera: Camera3D) -> Transform3D:
	var last: Transform3D = camera.global_transform
	for frame: int in 120:
		await tree.process_frame
		var now: Transform3D = camera.global_transform
		if now.origin.distance_to(last.origin) < 0.001 and now.basis.is_equal_approx(last.basis):
			return now
		last = now
	return last


func _cues_up_to(at_s: float) -> int:
	var count: int = 0
	for cue: CinematicCueResource in film.all_cues():
		if cue.at_s <= at_s:
			count += 1
	return count


## What the end of the film leaves behind (a skip must leave the same).
func _end_state(level: CalderaArchipelagoWorld) -> Dictionary:
	var p1: ActorBase = _p1(level)
	var rig: PlayerCamera = level.grid.camera_for(p1.player_id)
	var viewport: SubViewport = level.grid.viewport_for(p1.player_id)
	var hud: PlayerHUD = level.huds.get(p1.player_id) as PlayerHUD
	var held: bool = false
	for actor: ActorBase in level.actors.values():
		if is_instance_valid(actor) and actor.input != null:
			held = held or actor.input.cinematic_hold
	var file: ConfigFile = ConfigFile.new()
	file.load(SCRATCH_TALE)
	return {
		"playing": level.prologue.is_film_playing(),
		"film_nodes": _films_in(level),
		"held": held,
		"spotlight": String(level.grid.spotlight),
		"cinematic": level.cinematic_playing,
		"rig_current": rig != null and rig.current,
		"dive_camera": viewport != null and viewport.find_child("PrologueDiveCamera", false, false) != null,
		"ribbon": hud.cross_grimoire.ribbon_text() if hud != null else "",
		"seen": PartyProgress.current.has_seen_prologue(_lead_class()),
		"saved": bool((file.get_value("heroes", "prologue_seen", {}) as Dictionary).get(String(_lead_class()), false)),
		"overlay": level.grid.overlay_for(p1.player_id).visible,
	}


func _films_in(level: Node) -> int:
	return level.find_children("*", "PrologueFilm", true, false).size() if level != null else 0


func _load_caldera(extra_frames: int = LOAD_FRAMES) -> CalderaArchipelagoWorld:
	InstanceManager.current.previous_instance = &""
	CalderaArchipelagoWorld.use_boot_zone(CalderaArchipelagoWorld.ZONE_EMBERSHORE)
	tree.change_scene_to_file(CALDERA_SCENE)
	await _frames(maxi(1, extra_frames) + 1)
	return tree.current_scene as CalderaArchipelagoWorld


func _p1(level: LevelBase) -> ActorBase:
	if level == null:
		return null
	return level.actors.get(PartyMember.make_player_id(NetworkManager.current.local_peer_id(), InputComponent.KEYBOARD_DEVICE)) as ActorBase


func _lead_class() -> StringName:
	var seat: PartyMember = NetworkManager.current.member(PartyMember.make_player_id(NetworkManager.current.local_peer_id(), InputComponent.KEYBOARD_DEVICE))
	return seat.class_id if seat != null else ClassLoadouts.SOLO_BOOT_CLASS


## Drops every local seat but Player 1's (the keyboard), seating that one if it isn't; returns the dropped devices.
func _keep_only_player_one() -> Array[int]:
	var dropped: Array[int] = []
	var me: int = NetworkManager.current.local_peer_id()
	for seat: PartyMember in NetworkManager.current.ordered_members():
		if seat.peer_id == me and not seat.companion and seat.device_id != InputComponent.KEYBOARD_DEVICE:
			dropped.append(seat.device_id)
			NetworkManager.current.drop_local_player(seat.device_id)
	if not NetworkManager.current.is_device_seated(InputComponent.KEYBOARD_DEVICE):
		NetworkManager.current.request_local_player(InputComponent.KEYBOARD_DEVICE, ClassLoadouts.SOLO_BOOT_CLASS, InputComponent.AssistMode.ADVENTURER)
	return dropped


func _free_pad() -> int:
	var pad: int = FIRST_FAKE_PAD
	while NetworkManager.current.is_device_seated(pad):
		pad += 1
	return pad


func _fake_pads_seated() -> Array[int]:
	var pads: Array[int] = []
	for pad: int in range(FIRST_FAKE_PAD, FIRST_FAKE_PAD + 8):
		if NetworkManager.current.is_device_seated(pad):
			pads.append(pad)
	return pads
