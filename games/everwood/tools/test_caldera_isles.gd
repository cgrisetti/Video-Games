## The Caldera Isles' checks (docs/20_CALDERA_ATLAS_AND_CROWN_BIBLE.md), run
## last by tools/smoke_test.gd (and alone by tools/run_caldera_checks.gd):
##   0  the atlas and the state: five grids (Embershore's 16 x 8, three 12 x 12 and The Crown's 8 x 8),
##      four seams in two skins, ten booleans (docs/20's eight and Embershore's two), the two derived properties,
##      and the Lens's Rule 4 over every name the Caldera shows
##   1  the boot: the main scene is the Caldera Isles; it boots at Bramblebridge's
##      green on Embershore (and with --boot-zone=crown at The Crown's South Bay
##      Landing), with no legacy landblock streamer, map or horizon ring in it,
##      no minimap, and the playtest warp
##   2  streaming and the seams: the 3 x 3 window round the tether centroid,
##      every island's far stand-ins and four horizon silhouettes; walking the
##      West Strait and Eel Spit through their fog and back, gliding the Salt
##      Road both ways, the Crown Landing refused while the currents run wild;
##      no orphaned nodes after every island has loaded and unloaded
##   3  the Beacons: Iron-Ness's guarded by its kin until they're calmed, then
##      kindled by light; each Beacon stocks its Hearthstead stall, calms its
##      current round The Crown and earns its Sign; all three open the Crown
##      Landing, and its bell glides the party to South Bay
##   4  The Crown's seven areas at their heights: the landing (0-8 m), the
##      waypost (+10), the Ring Path's three springs (8-18), the three trials'
##      arenas, the sheer +32 m cliff band, the One Cliff Stair, the +65 m
##      Summit Glade with the World-Tree and the Harmonic Bell, the Sea-Door at
##      -4.5 m and the Heart's chamber at -15 m; a spring is a checkpoint
##   5  the trials: each arena's foes grow when it streams in (the Colossus's
##      poise 180 and its carapace), the Breach Gale shoves the unsheltered
##      and spares a wall's lee, the blight drains stamina until the three
##      Sap-Siphons are cleansed; each trial done blooms its bough; all three
##      open the stair's Resonance Barrier
##   6  the Harmonic Bell: one hero pulling isn't enough, nor a pull too late;
##      everyone within 2.5 s rings it; the Ebb cinematic plays while the sea
##      falls from 0 to -6 m over ten seconds, baring the Sea-Door (whose
##      threshold leads into the Sap Galleries), the Old Quay Market and its
##      merchants, and Raid Gates A, B and C
extends RefCounted

const CALDERA_SCENE: String = "res://scenes/worlds/caldera_isles.tscn"
## Pads (high indices, clear of real ones) that seat extra heroes when fewer than three are here: the bell needs a party.
const EXTRA_PADS: Array[int] = [9, 10, 11]
const PARTY_SIZE: int = 3
const LENS: GDScript = preload("res://tools/test_mythopoetic_lens.gd")
## The Crown's zone design (docs/23), checked while The Crown is live.
const CROWN_ZONES: GDScript = preload("res://tools/test_crown_zones.gd")
## The roads laid over the land (docs/26), on all five isles.
const LAID_ROADS: GDScript = preload("res://tools/test_laid_roads.gd")
## Embershore's acceptance checks (docs/27 §12).
const EMBERSHORE: GDScript = preload("res://tools/test_embershore.gd")
const ACT_ONE: GDScript = preload("res://tools/test_act_one.gd")
## The kin overhaul (docs/30): the foes of Levels 1 to 5 as sculpted, animated figures.
const KIN_ATELIER: GDScript = preload("res://tools/test_kin_atelier.gd")

var tree: SceneTree
var check: Callable
var level: CalderaArchipelagoWorld
var state: CalderaWorldState


func run(scene_tree: SceneTree, checker: Callable) -> void:
	tree = scene_tree
	check = checker
	state = CalderaWorldState.current
	state.reset_for_testing()
	_check_atlas_and_state()
	await _check_boot()
	LAID_ROADS.new().run(level, check)
	await EMBERSHORE.new().run(level, check, tree)
	await ACT_ONE.new().run(level, check, tree)
	await KIN_ATELIER.new().run(level, check, tree)
	await _check_streaming_and_seams()
	await _check_beacons()
	_check_crown_areas()
	await CROWN_ZONES.new().run(level, check)
	await _check_trials_and_stair()
	await _check_bell_and_ebb()
	state.reset_for_testing()


# --- Helpers --------------------------------------------------------------------------

func _frames(count: int) -> void:
	for index: int in count:
		await tree.physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds * 60.0)))


func _load(zone: StringName) -> void:
	CalderaArchipelagoWorld.use_boot_zone(zone)
	InstanceManager.current.previous_instance = &""
	tree.change_scene_to_file(CALDERA_SCENE)
	await _frames(8)
	level = tree.current_scene as CalderaArchipelagoWorld


func _party() -> Array[ActorBase]:
	var list: Array[ActorBase] = []
	for actor: ActorBase in level.party_in_order():
		if actor.is_local_player() and not actor.is_companion:
			list.append(actor)
	return list


func _p1() -> ActorBase:
	var party: Array[ActorBase] = _party()
	return party[0] if not party.is_empty() else null


## Puts every local hero at a spot (spread a little), ground loaded first.
func _place_party(at: Vector3) -> void:
	var seat: int = 0
	for actor: ActorBase in level.party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		var spot: Vector3 = at + Vector3((float(seat % 4) - 1.5) * 1.6, 0.0, 0.0)
		level.streamer.ensure_ground_at(spot)
		spot.y = level.streamer.height_at(spot.x, spot.z) + 0.2
		actor.place_at(Transform3D(Basis.IDENTITY, spot))
		seat += 1


## Puts every local hero on a corridor at s (in the live island's frame), on the deck.
func _place_on_corridor(seam: LoadSeamResource, s: float) -> void:
	var at: Vector3 = seam.point_at(level.streamer.active_isle, s)
	var seat: int = 0
	for actor: ActorBase in level.party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		var across: Vector3 = Vector3(seam.direction_3d().z, 0.0, -seam.direction_3d().x)
		actor.place_at(Transform3D(Basis.IDENTITY, at + across * (float(seat % 3) - 1.0) * 1.4 + Vector3(0.0, 0.3, 0.0)))
		seat += 1


## Seats extra heroes on spare pads until three people are here (the Harmonic Bell is a party's bell).
func _ensure_party() -> void:
	for pad: int in EXTRA_PADS:
		if _party().size() >= PARTY_SIZE or NetworkManager.current.local_player_count() >= NetworkManager.MAX_LOCAL_PLAYERS:
			break
		if not NetworkManager.current.is_device_seated(pad):
			NetworkManager.current.request_local_player(pad, NetworkManager.ANY_CLASS, InputComponent.AssistMode.ADVENTURER)
			await _frames(4)


func _down_all(spawner: MobSpawner) -> void:
	for mob: WildMob in spawner.mobs:
		if is_instance_valid(mob) and not mob.stats.is_downed:
			mob.stats.take_damage(mob.stats.health + 100000.0)


func _structure(node_name: String) -> Node:
	return level.streamer.structures.find_child(node_name, true, false)


# --- 0: the atlas and the state -----------------------------------------------------

func _check_atlas_and_state() -> void:
	var sizes: Array[String] = []
	var grids_ok: bool = CalderaAtlas.isles().size() == 5
	for isle: IslandGridResource in CalderaAtlas.isles():
		sizes.append("%s %dx%d (%d x %d m)" % [isle.display_name, isle.chunks_x(), isle.chunks_z_count(), int(isle.grid_size().x), int(isle.grid_size().y)])
		match isle.isle_id:
			CalderaAtlas.ISLE_THE_CROWN:
				grids_ok = grids_ok and isle.chunks_x() == 8 and isle.chunks_z_count() == 8 and isle.grid_size() == Vector2(1024.0, 1024.0)
			CalderaAtlas.ISLE_EMBERSHORE:
				# docs/27: a 2:1 island, 2,048 x 1,024 m.
				grids_ok = grids_ok and isle.chunks_x() == 16 and isle.chunks_z_count() == 8 and isle.grid_size() == Vector2(2048.0, 1024.0)
			_:
				grids_ok = grids_ok and isle.chunks_x() == 12 and isle.chunks_z_count() == 12 and isle.grid_size() == Vector2(1536.0, 1536.0)
	check.call(grids_ok, "five island grids, 128 m landblocks: %s" % ", ".join(sizes))
	var skins: Array[int] = []
	var gates: Array[StringName] = []
	for seam: LoadSeamResource in CalderaAtlas.seams():
		skins.append(seam.skin)
		gates.append(seam.gate_flag)
	var walk: int = LoadSeamResource.SeamSkin.WALKABLE_CAUSEWAY
	var skiff: int = LoadSeamResource.SeamSkin.LANTERN_SKIFF
	check.call(CalderaAtlas.seams().size() == 4 and skins == [walk, walk, skiff, skiff]
		and gates == [CalderaWorldState.ROOT_SANCTUM_CLEARED, CalderaWorldState.ROOT_SANCTUM_CLEARED, CalderaWorldState.ROOT_SANCTUM_CLEARED, CalderaWorldState.CROWN_LANDING]
		and CalderaAtlas.seam(CalderaAtlas.SEAM_EEL_SPIT).shingle,
		"four seams, one scene in two skins: the West Strait and Eel Spit walk (Eel Spit as shingle), the Salt Road and Crown Landing are skiff lanes; three open with the Root-Sanctum, the Crown Landing with the Beacons")
	var west: LoadSeamResource = CalderaAtlas.seam(CalderaAtlas.SEAM_WEST_STRAIT)
	var mid_a: Vector3 = west.midpoint(west.isle_a)
	var mapped: Vector3 = mid_a + west.remap_offset(west.isle_a)
	check.call(mapped.distance_to(west.midpoint(west.isle_b)) < 0.01 and is_equal_approx(west.corridor_s(west.isle_b, west.point_at(west.isle_b, 90.0)), 90.0),
		"a seam's swap is a translation: the corridor's middle in Embershore's frame lands on its middle in Iron-Ness's, and s carries across")
	check.call(CalderaWorldState.FLAGS.size() == 10 and state.bits() == 0 and not state.can_land_on_crown() and not state.cliff_stair_open()
		and state.sea_level_y == CalderaWorldState.SEA_LEVEL_FLOOD,
		"eight world-state booleans, all false at first: the Crown landing shut, the stair sealed, the sea at the Long Flood's 0 m")
	state.beacon_iron = true
	state.beacon_tide = true
	var two: bool = state.can_land_on_crown()
	state.beacon_gale = true
	var three: bool = state.can_land_on_crown()
	state.trial_anvil_complete = true
	state.trial_gale_complete = true
	var trials_two: bool = state.cliff_stair_open()
	state.trial_tide_complete = true
	var trials_three: bool = state.cliff_stair_open()
	state.reset_for_testing()
	check.call(not two and three and not trials_two and trials_three and state.sign_granted(ScribeSignResource.Sign.SIGN_WARM_HEARTH)
		and not state.sign_granted(ScribeSignResource.Sign.SIGN_IRON_ROOT),
		"can_land_on_crown() needs all three Beacons and cliff_stair_open() all three trials (derived, never stored); Warm-Hearth is Oakshire's own Sign")
	var banned: RegEx = RegEx.create_from_string(LENS.BANNED_PATTERN)
	var shown: Array[String] = CalderaAtlas.shown_names()
	for id: StringName in [Bestiary.FORGE_CLAD_SENTINEL, Bestiary.ANVIL_WARDEN_COLOSSUS, Bestiary.RIME_WING_HARRIER, Bestiary.STORM_CALLER_VAELEN,
			Bestiary.TARNISHED_SCRIBE_WIGHT, Bestiary.SIPHON_PRELATE]:
		shown.append(Bestiary.variant(id).display_name)
	var offenders: Array[String] = []
	for text: String in shown:
		var found: RegExMatch = banned.search(text)
		if found != null:
			offenders.append("%s (%s)" % [text, found.get_string()])
	check.call(offenders.is_empty() and shown.size() > 60,
		"the Lens's Rule 4 over all %d Caldera names and the Crown's Trial-Kin: no rune, construct or the like%s"
		% [shown.size(), "" if offenders.is_empty() else " (found: %s)" % "; ".join(offenders)])


# --- 1: the boot ------------------------------------------------------------------------

func _check_boot() -> void:
	check.call(InstanceManager.scene_path(TitleScreen.GAME_INSTANCE) == CALDERA_SCENE, "the title screen's tales start in the Caldera Isles")
	await _load(CalderaArchipelagoWorld.ZONE_EMBERSHORE)
	if level == null:
		check.call(false, "the Caldera Isles load")
		return
	await _ensure_party()
	var p1: ActorBase = _p1()
	var green: Vector3 = level.streamer.builder.arrivals[CalderaAtlas.ARRIVE_START]
	await _frames(20)
	var legacy: Array[String] = []
	for node: Node in level.find_children("*", "", true, false):
		if node is WorldGridManager or node is OakshireVale or node is EverwoodWorld or node is HubTown or node is HorizonVistaRing:
			legacy.append(String(node.name))
	var hud: PlayerHUD = level.huds.get(p1.player_id) as PlayerHUD
	check.call(level.instance_id() == InstanceManager.CALDERA_ISLES and level.streamer.active_isle == CalderaAtlas.ISLE_EMBERSHORE
		and p1 != null and p1.global_position.distance_to(green) < 8.0 and p1.is_on_floor() and legacy.is_empty()
		and not WorldAtmosphereDirector.current.horizon.visible and hud != null and not hud.minimap.visible,
		"--boot-zone=embershore boots the Caldera at Lee-Shore Orchards' gate over the bridge from Bramblebridge on Embershore, standing (P1 %.1f m from the arrival), no legacy streamer, map or horizon ring%s, no minimap"
		% [p1.global_position.distance_to(green) if p1 != null else -1.0, "" if legacy.is_empty() else " (found: %s)" % ", ".join(legacy)])
	check.call(level.region_at(p1.global_position) == "Bramblebridge" and level.streamer.impostor_for(CalderaAtlas.ISLE_THE_CROWN) != null
		and state.bits() == 0 and not state.playtest,
		"Bramblebridge names itself, The Crown stands on the horizon, and a plain boot is no playtest")
	await _load(CalderaArchipelagoWorld.ZONE_CROWN)
	p1 = _p1()
	var bay: Vector3 = level.streamer.builder.arrivals[CalderaAtlas.ARRIVE_SOUTH_BAY]
	await _frames(20)
	check.call(level.streamer.active_isle == CalderaAtlas.ISLE_THE_CROWN and p1.global_position.distance_to(bay) < 8.0 and p1.is_on_floor()
		and state.can_land_on_crown() and state.playtest and state.bits() == 0,
		"--boot-zone=crown boots at The Crown's South Bay Landing (a playtest: the landing counts as open, nothing saved)")
	level.playtest_warp()
	await _frames(10)
	var on_oakshire: bool = level.streamer.active_isle == CalderaAtlas.ISLE_EMBERSHORE and _p1().global_position.distance_to(level.streamer.builder.arrivals[CalderaAtlas.ARRIVE_START]) < 8.0
	level.playtest_warp()
	await _frames(10)
	check.call(on_oakshire and level.streamer.active_isle == CalderaAtlas.ISLE_THE_CROWN, "F9's playtest warp jumps the party Crown -> Embershore -> Crown")
	state.reset_for_testing()
	await _load(CalderaArchipelagoWorld.ZONE_EMBERSHORE)


# --- 2: streaming and the seams ------------------------------------------------------------

func _check_streaming_and_seams() -> void:
	var counts: Dictionary = level.streamer.counts()
	var p1: ActorBase = _p1()
	var window_ok: bool = int(counts["far"]) == 128 and int(counts["near"]) >= 9 and int(counts["near"]) <= 15 and int(counts["impostors"]) == 4
	# Walk the window: move the party a landblock east and watch it follow.
	var before: Vector2i = IslandGridResource.chunk_of(level.tether_centroid())
	_place_party(p1.global_position + Vector3(140.0, 0.0, 0.0))
	await _frames(40)
	level.streamer.load_now([level.tether_centroid()])
	var after: Vector2i = IslandGridResource.chunk_of(level.tether_centroid())
	var record: ArchipelagoStreamer.LoadedChunk = level.streamer.chunks.get(after + Vector2i(1, 0), null)
	check.call(window_ok and after != before and record != null and record.body != null and level.streamer.has_ground_at(level.tether_centroid()),
		"Embershore streams 128 far stand-ins (16 x 8), a %d-landblock window round the tether centroid and 4 horizon silhouettes; the window follows the party"
		% int(counts["near"]))
	var orphans_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	# The West Strait is dark until the Root-Sanctum is cleared.
	var gate: LaneGate = _structure("Causeway_west_strait").find_child("LaneGate", false, false) as LaneGate
	var dark: bool = gate != null and gate.blocks()
	state.clear_root_sanctum()
	await _frames(2)
	check.call(dark and not gate.blocks() and level.last_world_banner == "THE TRADE LANES GO DARK",
		"the West Strait's gate is barred while the lane is dark; clearing the Root-Sanctum opens it with a world banner")
	var west: LoadSeamResource = CalderaAtlas.seam(CalderaAtlas.SEAM_WEST_STRAIT)
	_place_on_corridor(west, 30.0)
	await _frames(10)
	var thin: float = level.seams.mist
	_place_on_corridor(west, 60.0)
	await _frames(10)
	var thick: float = level.seams.mist
	var still_home: bool = level.streamer.active_isle == CalderaAtlas.ISLE_EMBERSHORE
	_place_on_corridor(west, 74.0)
	await _frames(12)
	var crossed: bool = level.streamer.active_isle == CalderaAtlas.ISLE_IRON_NESS
	var s_after: float = west.corridor_s(CalderaAtlas.ISLE_IRON_NESS, _p1().global_position)
	check.call(thin > 0.05 and thin < 0.6 and thick > 0.9 and still_home and crossed and absf(s_after - 74.0) < 3.0
		and WorldAtmosphereDirector.current.seam_mist > 0.5 and level.streamer.mist() > 0.5,
		"walking the West Strait: sea-fog rolls in (%.2f at 30 m, %.2f at 60 m), and past the middle Iron-Ness streams in round the party, who walk on at the same spot (s %.1f)"
		% [thin, thick, s_after])
	_place_on_corridor(west, 118.0)
	await _frames(20)
	var counts_iron: Dictionary = level.streamer.counts()
	check.call(level.seams.mist < 0.1 and int(counts_iron["far"]) == 144 and _p1().is_on_floor() and level.region_at(_p1().global_position) != "",
		"ashore on Iron-Ness the fog has cleared (%.2f) and its 144 landblocks stand in" % level.seams.mist)
	_place_on_corridor(west, 56.0)
	await _frames(12)
	check.call(level.streamer.active_isle == CalderaAtlas.ISLE_EMBERSHORE, "walking back past the middle brings Embershore back")
	var eel: LoadSeamResource = CalderaAtlas.seam(CalderaAtlas.SEAM_EEL_SPIT)
	_place_on_corridor(eel, 74.0)
	await _frames(12)
	var barrow: bool = level.streamer.active_isle == CalderaAtlas.ISLE_BARROW_EYOT
	_place_on_corridor(eel, 54.0)
	await _frames(12)
	check.call(barrow and level.streamer.active_isle == CalderaAtlas.ISLE_EMBERSHORE, "Eel Spit's shingle walks to Barrow-Eyot and back")
	# The Salt Road: ring the bell at North Quay and glide.
	level.place_party_at(CalderaAtlas.ARRIVE_NORTH_QUAY)
	await _frames(4)
	var crown_bell: SkiffBell = _structure("CrownLandingBell") as SkiffBell
	var salt_bell: SkiffBell = _structure("SaltRoadBell") as SkiffBell
	crown_bell.interact(_p1())
	await _frames(30)
	var refused: bool = not level.seams.is_gliding() and level.streamer.active_isle == CalderaAtlas.ISLE_EMBERSHORE
	check.call(refused and not crown_bell.is_open() and crown_bell.prompt_for(_p1()) == CalderaAtlas.CROWN_SHUT_LINE,
		"the Crown Landing's bell is refused while the currents run wild: \"%s\"" % crown_bell.prompt_for(_p1()))
	salt_bell.interact(_p1())
	await _frames(2)
	var gliding: bool = level.seams.is_gliding()
	await _seconds(2.0)
	var on_deck: float = _p1().global_position.y - state.sea_level_y
	await _seconds(4.6)
	var rime: Vector3 = level.streamer.builder.arrivals.get(CalderaAtlas.ARRIVE_QUAY, Vector3.ZERO)
	await _frames(10)
	check.call(gliding and on_deck > 0.2 and on_deck < 2.5 and level.streamer.active_isle == CalderaAtlas.ISLE_RIME_FIRTH and not level.seams.is_gliding()
		and _p1().global_position.distance_to(rime) < 8.0 and _p1().is_on_floor(),
		"the Salt Road's bell seats the party on a Lantern-Skiff (%.1f m over the sea) for a six-second glide to Rime-Firth's inner quay" % on_deck)
	var home_bell: SkiffBell = _structure("SaltRoadBell") as SkiffBell
	home_bell.interact(_p1())
	await _seconds(6.6)
	await _frames(10)
	check.call(level.streamer.active_isle == CalderaAtlas.ISLE_EMBERSHORE and _p1().global_position.distance_to(level.streamer.builder.arrivals[CalderaAtlas.ARRIVE_NORTH_QUAY]) < 8.0,
		"and its bell glides them home to North Quay")
	for isle_id: StringName in [CalderaAtlas.ISLE_THE_CROWN, CalderaAtlas.ISLE_BARROW_EYOT, CalderaAtlas.ISLE_IRON_NESS, CalderaAtlas.ISLE_RIME_FIRTH, CalderaAtlas.ISLE_EMBERSHORE]:
		level.travel_to(isle_id, CalderaAtlas.builder_for(isle_id).arrivals.keys()[0])
		await _frames(4)
	await _frames(10)
	var orphans_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var final_counts: Dictionary = level.streamer.counts()
	check.call(orphans_after <= orphans_before and int(final_counts["terrain_nodes"]) == 128 and int(final_counts["pending"]) == 0
		and level.streamer.structures.get_parent() == level.streamer and level.streamer.get_child_count() == 4,
		"after every island has loaded and unloaded: no orphaned nodes (%d, was %d), 128 landblock roots (Embershore's), no jobs left, one island's structures" % [orphans_after, orphans_before])


# --- 3: the Beacons ----------------------------------------------------------------------

func _check_beacons() -> void:
	level.travel_to(CalderaAtlas.ISLE_IRON_NESS, CalderaAtlas.ARRIVE_BEACON)
	await _frames(10)
	var beacon: IslandBeacon = _structure("Beacon") as IslandBeacon
	var guards: MobSpawner = beacon.guards if beacon != null else null
	var guarded: bool = guards != null and guards.mobs.size() == 2 and not beacon.guards_calmed()
	var refusal: String = beacon.prompt_for(_p1()) if beacon != null else ""
	beacon.interact(_p1())
	var still_cold: bool = not state.beacon_iron
	_down_all(guards)
	await _frames(4)
	beacon.interact(_p1())
	await _frames(2)
	check.call(guarded and refusal.begins_with("Calm the Beacon's guardians") and still_cold and state.beacon_iron
		and level.last_world_banner == "IRON-NESS'S BEACON BURNS" and state.sign_granted(ScribeSignResource.Sign.SIGN_IRON_ROOT),
		"Iron-Ness's Beacon: its guardians stand (\"%s\"); calmed, light kindles it, earns the Sign of Iron-Root and shows a world banner" % refusal)
	var wild: Dictionary = level.streamer.current_wildness()
	check.call(is_equal_approx(float(wild["iron"]), 0.0) and is_equal_approx(float(wild["tide"]), 1.0) and is_equal_approx(float(wild["gale"]), 1.0),
		"the Iron Current round The Crown calms; the Tide and Gale Currents still run wild")
	state.light_beacon(CalderaAtlas.ISLE_BARROW_EYOT)
	var not_yet: bool = not state.can_land_on_crown()
	state.light_beacon(CalderaAtlas.ISLE_RIME_FIRTH)
	level.travel_to(CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_NORTH_QUAY)
	await _frames(6)
	var stocked: Array[String] = []
	for stall_name: String in ["IronStall", "LanternStall", "ProvisionsStall"]:
		var stall: TradeStall = _structure(stall_name) as TradeStall
		if stall != null and stall.is_stocked() and stall.vendor != null:
			stocked.append(stall.stall_name)
	wild = level.streamer.current_wildness()
	check.call(stocked.size() == 3 and float(wild["iron"]) + float(wild["tide"]) + float(wild["gale"]) == 0.0 and not_yet and state.can_land_on_crown(),
		"three Beacons: Hearthstead Market's %s are stocked with vendors, all three currents are calm, and the Crown Landing opens" % ", ".join(stocked))
	var bell: SkiffBell = _structure("CrownLandingBell") as SkiffBell
	bell.interact(_p1())
	await _seconds(6.6)
	await _frames(10)
	check.call(level.streamer.active_isle == CalderaAtlas.ISLE_THE_CROWN and _p1().global_position.distance_to(level.streamer.builder.arrivals[CalderaAtlas.ARRIVE_SOUTH_BAY]) < 8.0,
		"the Crown Landing's bell glides the party to The Crown's South Bay Landing")


# --- 4: The Crown's seven areas ----------------------------------------------------------------

func _check_crown_areas() -> void:
	var crown: CrownHeartCragBuilder = level.streamer.builder as CrownHeartCragBuilder
	if crown == null:
		check.call(false, "The Crown is the live island for its areas' checks")
		return
	var landing: float = crown.height_at(0.0, 350.0)
	var waypost: float = crown.height_at(CrownHeartCragBuilder.WAYPOST_AT.x, CrownHeartCragBuilder.WAYPOST_AT.z)
	var springs: Array[float] = []
	for spring: Vector2 in CrownHeartCragBuilder.SPRINGS:
		springs.append(crown.height_at(spring.x, spring.y))
	var springs_ok: bool = true
	for h: float in springs:
		# On the Ring Path, which the PDF holds to 0-14 m (docs/23 lowered them from the old 8-18 m).
		springs_ok = springs_ok and h >= 1.0 and h <= 14.5
	check.call(landing >= 0.0 and landing <= 8.0 and absf(waypost - 10.0) < 0.6 and springs_ok and _structure("WarmSpring3") is WarmSpring
		and _structure("Quartermaster") is TownsfolkNPC and _structure("RespawnAnchor") is WarmSpring,
		"area 1-2: South Bay Landing at %.1f m, the Lantern-Bearers' Waypost at %.1f m (respawn, anvil, one quartermaster, no town), the three springs at %s m on the Ring Path"
		% [landing, waypost, "%.1f, %.1f, %.1f" % [springs[0], springs[1], springs[2]]])
	var iron: float = crown.height_at(CrownHeartCragBuilder.IRON_SHORE_AT.x, CrownHeartCragBuilder.IRON_SHORE_AT.z)
	var gale: float = crown.height_at(CrownHeartCragBuilder.GALE_CLIFFS_AT.x, CrownHeartCragBuilder.GALE_CLIFFS_AT.z)
	var tide: float = crown.height_at(CrownHeartCragBuilder.TIDE_GROTTOS_AT.x, CrownHeartCragBuilder.TIDE_GROTTOS_AT.z)
	check.call(iron >= 12.0 and iron <= 24.0 and gale >= 16.0 and gale <= 28.0 and tide >= 6.0 and tide <= 18.0
		and _structure("TrialOfTheAnvil") is CrownTrialArena and _structure("TrialOfTheGale") is CrownTrialArena and _structure("TrialOfTheTide") is CrownTrialArena,
		"areas 3-5: Iron Shore's arena at %.1f m (12-24), Gale Cliffs' at %.1f m (16-28), Tide Grottos' at %.1f m (6-18)" % [iron, gale, tide])
	# The band: sheer everywhere round the dome except at the One Stair.
	var steepest_low: float = INF
	var tops: Array[float] = []
	for index: int in 24:
		var angle: float = TAU * (float(index) + 0.5) / 24.0
		var dir: Vector2 = Vector2(sin(angle), -cos(angle))
		var band: float = crown.band_radius_toward(dir)
		var inner: Vector2 = CrownHeartCragBuilder.DOME_CENTER + dir * (band - 12.0)
		var outer: Vector2 = CrownHeartCragBuilder.DOME_CENTER + dir * (band + 12.0)
		var best_rise: float = 0.0
		for step: int in 24:
			var a: Vector2 = inner.lerp(outer, float(step) / 24.0)
			var b: Vector2 = inner.lerp(outer, float(step + 1) / 24.0)
			best_rise = maxf(best_rise, absf(crown.height_at(a.x, a.y) - crown.height_at(b.x, b.y)) / a.distance_to(b))
		steepest_low = minf(steepest_low, best_rise)
		tops.append(crown.height_at(inner.x, inner.y))
	var band_top_ok: bool = tops.all(func(h: float) -> bool: return h >= 31.5)
	var stair_foot: float = crown.height_at(CrownHeartCragBuilder.STAIR_FOOT.x, CrownHeartCragBuilder.STAIR_FOOT.z)
	var stair_top: float = crown.height_at(CrownHeartCragBuilder.STAIR_TOP.x, CrownHeartCragBuilder.STAIR_TOP.z)
	var stair_grade: float = rad_to_deg(atan((stair_top - stair_foot) / CrownHeartCragBuilder.STAIR_FOOT.distance_to(CrownHeartCragBuilder.STAIR_TOP)))
	var barrier: ResonanceBarrier = _structure("ResonanceBarrier") as ResonanceBarrier
	var floor_max: float = rad_to_deg(_p1().floor_max_angle)
	check.call(rad_to_deg(atan(steepest_low)) > floor_max + 5.0 and band_top_ok and absf(stair_foot - 18.0) < 1.0 and absf(stair_top - 32.5) < 1.0
		and stair_grade < floor_max - 10.0 and barrier != null and barrier.blocks(),
		"area 6: the +32 m cliff band is sheer all round (at least %.0f° on every bearing, past the %.0f° a hero can climb), and the One Cliff Stair climbs it from %.1f to %.1f m at %.0f°, sealed by its Resonance Barrier"
		% [rad_to_deg(atan(steepest_low)), floor_max, stair_foot, stair_top, stair_grade])
	var glade: float = crown.height_at(CrownHeartCragBuilder.WORLD_TREE_AT.x, CrownHeartCragBuilder.WORLD_TREE_AT.z)
	var world_tree: WorldTree = _structure("WorldTree") as WorldTree
	var bell: HarmonicBell = _structure("HarmonicBell") as HarmonicBell
	check.call(absf(glade - 65.0) < 0.8 and world_tree != null and absf(world_tree.global_position.y - 65.0) < 1.0 and bell != null
		and bell.global_position.distance_to(CrownHeartCragBuilder.BELL_AT) < 1.0,
		"area 6: the Summit Glade at %.1f m, the World-Tree on it and the Harmonic Bell beside it at (+5, +65, -26)" % glade)
	var door: SeaGate = _structure("SeaDoor") as SeaGate
	var cove: float = crown.height_at(CrownHeartCragBuilder.SEA_DOOR_AT.x, CrownHeartCragBuilder.SEA_DOOR_AT.z)
	var chamber: Node3D = _structure("HeartChamber") as Node3D
	check.call(door != null and absf(door.global_position.y + 4.5) < 0.01 and absf(cove + 4.5) < 0.3 and door.is_submerged() and not door.is_bared()
		and chamber != null and _structure("TrueRaidPortal") != null and _structure("SapGalleries") != null,
		"area 7: the Sea-Door at -4.5 m on the east shore (its cove at %.1f m), under the Long Flood; the Sap Galleries lead to the Heart's chamber at -15 m" % cove)


# --- 5: the three trials and the stair ------------------------------------------------------

func _check_trials_and_stair() -> void:
	var tree_node: WorldTree = _structure("WorldTree") as WorldTree
	# The Anvil.
	var anvil: CrownTrialArena = _structure("TrialOfTheAnvil") as CrownTrialArena
	_place_party(anvil.global_position + Vector3(0.0, 0.0, 18.0))
	level.streamer.load_now([anvil.global_position])
	await _frames(6)
	var colossus: WildMob = null
	for mob: WildMob in anvil.spawner.mobs:
		if is_instance_valid(mob) and mob.variant.variant_id == Bestiary.ANVIL_WARDEN_COLOSSUS:
			colossus = mob
	check.call(anvil.spawned and anvil.spawner.mobs.size() == 3 and colossus != null and colossus.variant.rank == MobVariantResource.Rank.BOSS
		and is_equal_approx(colossus.variant.poise, 180.0) and colossus.variant.mitigation > 0.85,
		"the Trial of the Anvil grows as it streams in: two Forge-Clad Sentinels and the Anvil-Warden Colossus (poise 180, nine tenths of every blow glancing off till it breaks)")
	_down_all(anvil.spawner)
	await _frames(4)
	tree_node.settle()
	var anvil_done: bool = state.trial_anvil_complete and is_equal_approx(tree_node.bloom_of(CalderaWorldState.TRIAL_ANVIL), 1.0)
	var amber: float = float(WorldTree.bough_material(CalderaWorldState.TRIAL_ANVIL).get_shader_parameter(&"bloom"))
	var barrier: ResonanceBarrier = _structure("ResonanceBarrier") as ResonanceBarrier
	check.call(anvil_done and is_equal_approx(amber, 1.0) and level.last_world_banner == "THE TRIAL OF THE ANVIL IS DONE" and barrier.seals_lit() == 1 and barrier.blocks(),
		"its foes beaten, the trial is done: the western bough blooms Amber (one shared shader parameter, so North Quay's silhouette blooms too) and the first seal lights")
	# The Gale.
	var gale_arena: CrownTrialArena = _structure("TrialOfTheGale") as CrownTrialArena
	_place_party(gale_arena.global_position + Vector3(0.0, 0.0, 10.0))
	level.streamer.load_now([gale_arena.global_position])
	await _frames(6)
	var gale: BreachGale = gale_arena.gale
	var wall: Node3D = gale.walls[2]
	var p1: ActorBase = _p1()
	var open_spot: Vector3 = gale_arena.global_position + Vector3(0.0, 0.0, -24.0)
	var lee_spot: Vector3 = wall.global_position + gale.wind * 2.0
	check.call(gale.active and gale.in_lee(lee_spot) and not gale.in_lee(open_spot) and gale_arena.spawner.mobs.size() == 4,
		"the Trial of the Gale: three Rime-Wing Harriers and Storm-Caller Vaelen, and the Breach Gale blowing (an Old Sanctum wall's lee is shelter)")
	p1.place_at(Transform3D(Basis.IDENTITY, Vector3(open_spot.x, level.streamer.height_at(open_spot.x, open_spot.z) + 0.2, open_spot.z)))
	var others: Array[ActorBase] = _party().slice(1)
	for other: ActorBase in others:
		other.place_at(Transform3D(Basis.IDENTITY, Vector3(lee_spot.x, level.streamer.height_at(lee_spot.x, lee_spot.z) + 0.2, lee_spot.z)))
	await _frames(3)
	var start: Vector3 = p1.global_position
	var sheltered_start: Vector3 = others[0].global_position if not others.is_empty() else Vector3.ZERO
	gale.blast()
	await _frames(40)
	var shoved: float = Vector2(p1.global_position.x - start.x, p1.global_position.z - start.z).length()
	var stayed: float = Vector2(others[0].global_position.x - sheltered_start.x, others[0].global_position.z - sheltered_start.z).length() if not others.is_empty() else 0.0
	check.call(shoved > 4.0 and stayed < 1.0, "a Breach Gale shoves a hero in the open %.1f m downwind and spares one in a wall's lee (%.1f m)" % [shoved, stayed])
	_down_all(gale_arena.spawner)
	await _frames(4)
	# The Tide.
	var tide_arena: CrownTrialArena = _structure("TrialOfTheTide") as CrownTrialArena
	_place_party(tide_arena.global_position + Vector3(4.0, 0.0, 6.0))
	level.streamer.load_now([tide_arena.global_position])
	await _frames(6)
	p1 = _p1()
	p1.stats.stamina = p1.stats.stats.max_stamina
	await _seconds(1.0)
	var drained: float = p1.stats.stats.max_stamina - p1.stats.stamina
	var blight: bool = tide_arena.blight_active()
	var near_totem: Vector3 = tide_arena.totems[0].global_position + Vector3(2.0, 0.0, 0.0)
	p1.place_at(Transform3D(Basis.IDENTITY, Vector3(near_totem.x, level.streamer.height_at(near_totem.x, near_totem.z) + 0.2, near_totem.z)))
	CombatDirector.current.synergy_detonated.emit(p1, ScribeSignResource.Sign.SIGN_STAR_TIDE, false, "")
	var by_detonation: bool = tide_arena.totems[0].cleansed and not tide_arena.totems[1].cleansed
	for totem: SapSiphonTotem in tide_arena.totems:
		totem.cleanse()
	var cleared: bool = not tide_arena.blight_active()
	p1.stats.stamina = p1.stats.stats.max_stamina * 0.5
	await _seconds(1.0)
	check.call(blight and drained > 3.0 and cleared and p1.stats.stamina > p1.stats.stats.max_stamina * 0.5 and tide_arena.spawner.mobs.size() == 4,
		"the Trial of the Tide: blight-mist drains %.1f stamina a second until the three Sap-Siphon Totems are cleansed (a Star-Tide detonation by one: %s)"
		% [drained, by_detonation])
	check.call(by_detonation, "a Star-Tide detonation within reach cleanses a Sap-Siphon Totem")
	_down_all(tide_arena.spawner)
	await _frames(4)
	tree_node.settle()
	var blooms: Array[float] = []
	for trial: StringName in CalderaWorldState.TRIALS:
		blooms.append(tree_node.bloom_of(trial))
	check.call(state.cliff_stair_open() and blooms == [1.0, 1.0, 1.0] and not barrier.blocks() and barrier.seals_lit() == 3
		and level.last_world_banner == "THE TRIAL OF THE TIDE IS DONE",
		"all three trials done: three boughs bloom (Amber, Sea-Azure, Twilight-Violet) and the One Cliff Stair's barrier falls")


# --- 6: the Harmonic Bell and the Ebb ------------------------------------------------------------

func _check_bell_and_ebb() -> void:
	var bell: HarmonicBell = _structure("HarmonicBell") as HarmonicBell
	_place_party(bell.global_position + Vector3(0.0, 0.0, HarmonicBell.ROPE_ARC_RADIUS))
	await _frames(4)
	var party: Array[ActorBase] = _party()
	var needed: int = bell.ringers_needed()
	bell.pull(party[0])
	var alone: bool = not state.ebb_unlocked and bell.pulled_count() == 1
	await _seconds(HarmonicBell.SYNC_WINDOW + 0.2)
	for index: int in range(1, party.size()):
		bell.pull(party[index])
	var too_late: bool = not state.ebb_unlocked or party.size() == 1
	await _seconds(HarmonicBell.SYNC_WINDOW + 0.2)
	check.call(needed == party.size() and alone and too_late and needed >= 2,
		"the Harmonic Bell needs every hero (%d): one pull alone, or the rest pulling after the 2.5 s window, rings nothing" % needed)
	for actor: ActorBase in party:
		bell.pull(actor)
	await _frames(2)
	var cinematic: EbbCinematic = level.ebb_cinematic
	check.call(state.ebb_unlocked and bell.has_rung and state.ebb_in_progress() and cinematic != null and is_instance_valid(cinematic)
		and state.sea_level_y > -0.5,
		"all pulling together rings it: ebb_unlocked, and the 10-second Ebb cinematic starts as the sea begins to fall")
	await _seconds(5.0)
	var mid: float = state.sea_level_y
	var mid_shot: int = cinematic.shot_index if is_instance_valid(cinematic) else -1
	await _seconds(5.4)
	check.call(mid < -1.0 and mid > -5.0 and mid_shot >= 1 and is_equal_approx(state.sea_level_y, CalderaWorldState.SEA_LEVEL_EBB)
		and is_equal_approx(level.streamer.sea.position.y, -6.0) and not is_instance_valid(cinematic) and level.last_world_banner == "THE LONG FLOOD ENDS",
		"the sea falls from 0 to -6 m over the ten seconds (%.1f m half-way, cutting across the archipelago), then the cinematic ends" % mid)
	var door: SeaGate = _structure("SeaDoor") as SeaGate
	var threshold: PartyThreshold = _structure("SeaDoorThreshold") as PartyThreshold
	_place_party(threshold.global_position)
	await _frames(70)
	var below: bool = true
	for actor: ActorBase in _party():
		below = below and actor.global_position.y < -9.0 and actor.global_position.x < CrownHeartCragBuilder.GALLERY_ENTRANCE.x
	check.call(door.is_bared() and threshold.enabled and below,
		"the Sea-Door is bared at the Ebb, and the party gathered at it go down into the Sap Galleries (P1 at %.1f m)" % _p1().global_position.y)
	level.travel_to(CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_NORTH_QUAY)
	await _frames(4)
	var market: OldQuayMarket = _structure("OldQuayMarket") as OldQuayMarket
	check.call(market != null and market.is_bared() and market.merchants.size() == 2 and is_equal_approx(level.streamer.sea.position.y, -6.0),
		"on Embershore the Ebb has bared the Old Quay at -4.5 m, its Chime and gear merchants open again")
	var gates: Array[String] = []
	for isle_id: StringName in [CalderaAtlas.ISLE_IRON_NESS, CalderaAtlas.ISLE_RIME_FIRTH, CalderaAtlas.ISLE_BARROW_EYOT]:
		level.travel_to(isle_id, CalderaAtlas.ARRIVE_BEACON)
		await _frames(3)
		var gate: SeaGate = _structure("RaidGate") as SeaGate
		if gate != null and gate.is_bared() and absf(gate.global_position.y + 4.5) < 0.01:
			gates.append(gate.title)
	check.call(gates.size() == 3, "and the three raid gates stand bared on the outer shores: %s" % "; ".join(gates))
