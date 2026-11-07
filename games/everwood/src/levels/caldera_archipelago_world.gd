## The Caldera Isles (docs/20_CALDERA_ATLAS_AND_CROWN_BIBLE.md): the game's
## world and its main scene. Five island grids in a drowned caldera, one live
## at a time (ArchipelagoStreamer), joined by four seams (SeamTransitionController),
## with eight world-state booleans (CalderaWorldState) deciding what's open.
##
## The scene is one node with this script; everything else (environment, sun,
## the party's roots, the split-screen grid and banner) is built here in code.
##
## Where the party starts:
##   --boot-zone=embershore (the default; "oakshire" still works): Bramblebridge's
##       green on Embershore, the chime-post where the party spawns (docs/27)
##   --boot-zone=north_quay: North Quay, facing The Sound
##   --boot-zone=crown: The Crown's South Bay Landing (a playtest: its landing
##       counts as open and nothing changed there is saved)
##   coming home from the Root-Sanctum's expedition: the Root-Sanctum's door
## In play, F9 jumps the party between Embershore and The Crown (a playtest
## warp, unsaved), and the Crown Landing's Chime-Bell at North Quay glides there
## once its lane is open.
##
## No minimap and no quest arrows (the Musk Razor): the World-Tree, the four
## horizon silhouettes, the lantern-poles and the cliff band's shape do the
## guiding. World changes (a Beacon lit, a bough bloomed, the Ebb) show as one
## banner on every screen.
class_name CalderaArchipelagoWorld
extends LevelBase

const TITLE: String = "The Caldera Isles"
const BOOT_ZONE_ARG: String = "--boot-zone="
const ZONE_EMBERSHORE: StringName = &"embershore"
## The starting zone's old name, the same place.
const ZONE_OAKSHIRE: StringName = &"oakshire"
const ZONE_NORTH_QUAY: StringName = &"north_quay"
const ZONE_CROWN: StringName = &"crown"
const CHANGE_KEYS: String = "Space / ✕: jump · Shift / L3: sprint · hold Tab / View: Fellowship · hold C: Calling · hold M / R3: assist mode\ntap M / R3: the Atlas · PgUp / PgDn or right stick: tilt the camera · F2 / Share + D-Pad →: debug hero · F4: telemetry · F9: playtest warp"
## Far enough to see every island's landmark from North Quay and The Crown.
const CAMERA_FAR: float = 4600.0
## The biomes' fog is for valleys; over open water it's thinned so the far isles show.
const FOG_SCALE: float = 0.28
## Underground (the Sap Galleries) the low fog is put far below.
const FOG_OUT_OF_REACH: float = -200.0
## Below the horizon the sky is the sea's colour.
const SEA_SKY_GROUND: Color = Color(0.36, 0.52, 0.56)
## Feet this far under the water for this long, and the tide carries you back to the last dry ground
## (docs/27 §2: rivers wade at 0.4 to 0.8 m; deeper water is a wall).
const DEEP_WATER: float = 0.9
const DEEP_WATER_TIME: float = 1.2
const REGION_COLOR: Color = Color(0.86, 0.94, 0.7)
const QUEST_COLOR: Color = Color(1.0, 0.82, 0.25)
const REGION_BANNER_TIME: float = 3.0
const QUEST_BANNER_TIME: float = 6.0
const WORLD_BANNER_TIME: float = 6.5
## Below this a hero has fallen out of the Caldera (under the Sap Galleries and the Sound's floor).
const FALL_OUT_HEIGHT: float = -40.0
## A falling hero with no ground streamed in under them gets it at once.
const CATCH_FALL_SPEED: float = -4.0
## The Audio Mosaics' places (music_mood_context): where folk live, and the wild ones.
const SETTLED_PLACES: Array[String] = ["Bramblebridge", "The Heirloom Orchards", "Hearthstead", "North Quay", "The Old Quay", "Mill-Downs",
	"The Doverslap Gatehouse", "South Bay Landing", "The Lantern-Bearers' Waypost", "Old King's Town"]
const WILD_PLACES: Array[String] = ["The Root-Sanctum", "The West Strait", "Eel Spit", "The South Cliffs", "The First-Quiet Crags", "Doverslap Gorge",
	"Bramblemouth", "The Breach Point", "The Weeping Arch", "The Trial of the Anvil", "The Trial of the Gale", "The Trial of the Tide", "The Sea-Door",
	"The Sap Galleries"]
## Embershore's light arc (docs/27 §10): each stage of the corridor wears a biome's sky and fog.
const EMBERSHORE_BIOMES: Dictionary[String, StringName] = {"Bramblebridge": WorldVisualCatalog.OAKSHIRE_WICK, "The Heirloom Orchards": WorldVisualCatalog.OAKSHIRE_WICK,
	"Bramblemouth": WorldVisualCatalog.OAKSHIRE_WICK, "The Ariundle Moss-Oaks": WorldVisualCatalog.MOSS_OAK_HOLLOW, "The Elder Oak": WorldVisualCatalog.MOSS_OAK_HOLLOW,
	"The Root-Sanctum": WorldVisualCatalog.MOSS_OAK_HOLLOW, "The Bramble Spring": WorldVisualCatalog.MOSS_OAK_HOLLOW, "The Dover Spring": WorldVisualCatalog.MOSS_OAK_HOLLOW,
	"The Sunken Holloway": WorldVisualCatalog.RUSH_LIGHT_HOLLOW, "The Rim Shoulder": WorldVisualCatalog.DOVER_SLAP_FALLS,
	"Doverslap Gorge Bridge": WorldVisualCatalog.DOVER_SLAP_FALLS, "Doverslap Gorge": WorldVisualCatalog.DOVER_SLAP_FALLS,
	"The Doverslap Gatehouse": WorldVisualCatalog.DOVER_SLAP_FALLS, "The Coast Road": WorldVisualCatalog.GULL_WICK_HAVEN, "Seal Cove": WorldVisualCatalog.GULL_WICK_HAVEN,
	"Sunward Cove": WorldVisualCatalog.GULL_WICK_HAVEN, "The Eel Junction": WorldVisualCatalog.GULL_WICK_HAVEN, "Eel Spit": WorldVisualCatalog.GULL_WICK_HAVEN,
	"The South Cliffs": WorldVisualCatalog.DOVER_SLAP_FALLS, "The First-Quiet Crags": WorldVisualCatalog.DOVER_SLAP_FALLS}
## The Crown's outer shores (docs/23) lean this wild anywhere on them.
const CROWN_WILD_SHORES: Array[int] = [CrownHeartCragBuilder.Zone.IRON_SHORE, CrownHeartCragBuilder.Zone.GALE_CLIFFS,
	CrownHeartCragBuilder.Zone.TIDE_GROTTOS]
const CROWN_SHORE_WILD: float = 0.6
## An island's outer edge leans wild from this share of its half-width to this one.
const EDGE_FROM: float = 0.55
const EDGE_TO: float = 0.85
## High ground lifts Wonder from this far above the sea, fully this much higher.
const HEIGHT_FROM: float = 8.0
const HEIGHT_SPAN: float = 30.0
## This far under the island's ground is a holloway (the Sap Galleries).
const UNDERGROUND_DEPTH: float = 2.5

## The --boot-zone this run asked for (read once per launch).
static var boot_zone: StringName = ZONE_EMBERSHORE
static var _boot_zone_read: bool = false

var streamer: ArchipelagoStreamer
var seams: SeamTransitionController
var ebb_cinematic: EbbCinematic
## The last world banner shown (tests).
var last_world_banner: String = ""
var tide_returns: int = 0

var _badge: WorldTelemetryBadge
var _regions: Dictionary[StringName, String] = {}
var _isles_named: Dictionary[StringName, StringName] = {}
var _deep: Dictionary[StringName, float] = {}
var _safe: Dictionary[StringName, Vector3] = {}


func _init() -> void:
	name = "CalderaIsles"
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	environment.environment = _make_environment()
	add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-48.0), deg_to_rad(35.0), 0.0)), Vector3.ZERO)
	sun.light_color = Color(1.0, 0.9, 0.74)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	for root_name: String in ["SpawnPoints", "Actors", "Telegraphs", "Effects"]:
		var holder: Node3D = Node3D.new()
		holder.name = root_name
		add_child(holder)
		if root_name == "SpawnPoints":
			for index: int in 4:
				var marker: Marker3D = Marker3D.new()
				marker.name = "Spawn%d" % (index + 1)
				holder.add_child(marker)
	var screens: CanvasLayer = CanvasLayer.new()
	screens.name = "Screens"
	add_child(screens)
	var view_grid: SplitScreenViewportGrid = SplitScreenViewportGrid.new()
	view_grid.name = "Grid"
	view_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screens.add_child(view_grid)
	var line: Label = Label.new()
	line.name = "Banner"
	line.modulate = Color(1.0, 1.0, 1.0, 0.85)
	line.anchor_left = 0.5
	line.anchor_right = 0.5
	line.offset_top = 6.0
	line.grow_horizontal = Control.GROW_DIRECTION_BOTH
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override(&"font_size", 15)
	line.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0))
	line.add_theme_constant_override(&"outline_size", 6)
	screens.add_child(line)


static func _make_environment() -> Environment:
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.36, 0.56, 0.84)
	sky_material.sky_horizon_color = Color(0.82, 0.86, 0.86)
	sky_material.ground_bottom_color = Color(0.2, 0.32, 0.36)
	sky_material.ground_horizon_color = Color(0.62, 0.7, 0.72)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	var made: Environment = Environment.new()
	made.background_mode = Environment.BG_SKY
	made.sky = sky
	# The shadows are filled by the sky itself (docs/24 §2): cool from above, warmer near the
	# ground, never one flat grey. Bloom is a touch, not a haze over everything.
	made.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	made.ambient_light_color = Color(0.62, 0.64, 0.7)
	made.ambient_light_sky_contribution = 0.7
	made.ambient_light_energy = 0.52
	made.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	made.tonemap_exposure = 0.92
	made.glow_enabled = true
	made.glow_intensity = 0.22
	made.glow_bloom = 0.0
	made.fog_enabled = true
	made.fog_light_color = Color(0.86, 0.88, 0.86)
	made.fog_density = 0.0012
	made.fog_sky_affect = 0.1
	return made


# --- LevelBase ---------------------------------------------------------------------

func instance_id() -> StringName:
	return InstanceManager.CALDERA_ISLES


func level_title() -> String:
	return TITLE


func level_hint() -> String:
	if streamer == null or streamer.builder == null:
		return TITLE
	var isle: IslandGridResource = streamer.builder.isle
	return "%s · %s · trail Level %d · steer by the World-Tree and the far isles · talk to anyone under a gold !\n%s" % [
		isle.display_name, isle.level_band(), PartyProgress.current.trail_level(), CHANGE_KEYS]


func home_place() -> String:
	return "Embershore"


## Each island plays its score; on The Crown each shore and the World-Tree play
## their own suite (docs/23 §7), holding the one playing now for a few degrees
## past an edge so a party at a spring hears one tune. An island whose score is an
## Audio Mosaic (16 §7) plays it everywhere on it: Miller's Oak's millers_holm and,
## since Clay chose it over the shore suites, The Crown's crown_island.
func music_profile_at(position: Vector3) -> StringName:
	if streamer == null or streamer.builder == null:
		return &"millers_holm"
	var isle: IslandGridResource = streamer.builder.isle
	var score: ZoneMusicProfileResource = AudioCatalog.zone(isle.music_profile)
	var crown: CrownHeartCragBuilder = streamer.builder as CrownHeartCragBuilder
	if crown != null and (score == null or not score.is_mosaic()):
		var playing: StringName = AudioDirector.current.zone_profile_id if AudioDirector.current != null else &""
		return crown.music_at(position, playing)
	return isle.music_profile


## The mosaics' moods by place (16 GDD §7.1): the towns, markets, quays and orchards lean to Peace,
## Mellow and Wonder; the strait shores, the Root-Sanctum, The Crown's outer shores, arches, trials
## and galleries, and any island's outer edge, lean to Curiosity, Interest and Anxiousness; high
## ground lifts Wonder; under the ground is a holloway.
func music_mood_context(position: Vector3, context: MusicMoodEngine.Context) -> void:
	if streamer == null or streamer.builder == null:
		return
	var builder: IslandBuilder = streamer.builder
	var place: String = builder.place_name_at(position)
	context.settled = 1.0 if SETTLED_PLACES.has(place) else 0.0
	var half: Vector2 = builder.isle.half_size()
	var reach: float = Vector2(position.x / maxf(half.x, 1.0), position.z / maxf(half.y, 1.0)).length()
	context.wild = 1.0 if WILD_PLACES.has(place) else smoothstep(EDGE_FROM, EDGE_TO, reach)
	# The Crown's three outer shores lean wild everywhere on them (docs/23).
	var crown: CrownHeartCragBuilder = builder as CrownHeartCragBuilder
	if crown != null and CROWN_WILD_SHORES.has(crown.zone_at(position)):
		context.wild = maxf(context.wild, CROWN_SHORE_WILD)
	var ground: float = streamer.height_at(position.x, position.z)
	context.underground = 1.0 if position.y < ground - UNDERGROUND_DEPTH else 0.0
	context.height = clampf((position.y - CalderaWorldState.current.sea_level_y - HEIGHT_FROM) / HEIGHT_SPAN, 0.0, 1.0)


## Each island wears its biome's sky and fog; The Crown's shores take on the isles they face.
func visual_biome_at(position: Vector3) -> StringName:
	if streamer == null or streamer.builder == null:
		return WorldVisualCatalog.OAKSHIRE_WICK
	var crown: CrownHeartCragBuilder = streamer.builder as CrownHeartCragBuilder
	if crown != null:
		match crown.zone_at(position):
			CrownHeartCragBuilder.Zone.IRON_SHORE:
				return WorldVisualCatalog.QUARRY_WICK
			CrownHeartCragBuilder.Zone.GALE_CLIFFS:
				return WorldVisualCatalog.GULL_WICK_HAVEN
			CrownHeartCragBuilder.Zone.TIDE_GROTTOS, CrownHeartCragBuilder.Zone.SAP_GALLERIES:
				return WorldVisualCatalog.NINE_STONES_CROSSING
	if streamer.builder is EmbershoreBuilder:
		return EMBERSHORE_BIOMES.get(streamer.builder.place_name_at(position), streamer.builder.isle.visual_biome)
	return streamer.builder.isle.visual_biome


func wants_companions() -> bool:
	return true


func wants_horizon_ring() -> bool:
	return false


func wants_minimap() -> bool:
	return false


func fog_density_scale() -> float:
	return FOG_SCALE


func sky_ground_color() -> Color:
	return SEA_SKY_GROUND


## The low fog lies on the sea, wherever the sea stands (it falls with the Ebb), and lifts away underground.
func fog_height() -> float:
	if streamer == null or streamer.builder == null:
		return WorldAtmosphereDirector.FOG_HEIGHT
	var middle: Vector3 = tether_centroid()
	if middle.y < streamer.height_at(middle.x, middle.z) - 2.5:
		return FOG_OUT_OF_REACH
	return CalderaWorldState.current.sea_level_y + WorldAtmosphereDirector.FOG_HEIGHT


func map_rect() -> Rect2:
	return WorldGridConfig.layout.map_rect() if streamer != null and streamer.builder != null else super.map_rect()


func _setup_level() -> void:
	_read_boot_zone()
	# The Sap Galleries run down to -15 m under the island; only far below them has a hero fallen out.
	ActorBase.fall_respawn_height = FALL_OUT_HEIGHT
	streamer = ArchipelagoStreamer.new()
	streamer.name = "Archipelago"
	add_child(streamer)
	streamer.collision_changed.connect(_on_collision_changed)
	streamer.island_activated.connect(_on_island_activated)
	seams = SeamTransitionController.new()
	seams.name = "Seams"
	seams.level = self
	add_child(seams)
	var state: CalderaWorldState = CalderaWorldState.current
	state.flag_changed.connect(_on_world_flag_changed)
	state.ebb_started.connect(_on_ebb_started)
	get_tree().node_added.connect(_on_node_added)
	var start: Array[StringName] = _start_point()
	var builder: IslandBuilder = CalderaAtlas.builder_for(start[0])
	var focus: Array[Vector3] = [builder.arrival_spot(start[1])]
	streamer.activate_island(start[0], focus)
	_place_spawn_points(start[1])
	# F4: the telemetry badge, here the live score (16 GDD §7.4).
	_badge = WorldTelemetryBadge.new()
	get_node(^"Screens").add_child(_badge)
	if OS.get_cmdline_user_args().has("--telemetry"):
		set_telemetry_visible(true)


func _exit_tree() -> void:
	super._exit_tree()
	ActorBase.fall_respawn_height = ActorBase.FALL_RESPAWN_HEIGHT
	if get_tree() != null and get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	var state: CalderaWorldState = CalderaWorldState.current
	if state != null:
		if state.flag_changed.is_connected(_on_world_flag_changed):
			state.flag_changed.disconnect(_on_world_flag_changed)
		if state.ebb_started.is_connected(_on_ebb_started):
			state.ebb_started.disconnect(_on_ebb_started)


func _on_player_registered(seat: PartyMember) -> void:
	super._on_player_registered(seat)
	var view: PlayerCamera = grid.camera_for(seat.player_id)
	if view != null:
		view.set_horizon(CAMERA_FAR)


func _report_extra() -> String:
	if streamer == null:
		return ""
	var counts: Dictionary = streamer.counts()
	return " · Caldera: %s, %d/%d hills and woods near, %d crossings, sea %.1f m · " % [streamer.active_isle, int(counts["near"]), int(counts["chunks"]),
		seams.crossings, CalderaWorldState.current.sea_level_y]


# --- Where the party starts -------------------------------------------------------------

static func _read_boot_zone() -> void:
	if _boot_zone_read:
		return
	var zone: StringName = ZONE_EMBERSHORE
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(BOOT_ZONE_ARG):
			var asked: StringName = StringName(arg.trim_prefix(BOOT_ZONE_ARG).strip_edges().to_lower())
			if asked == ZONE_OAKSHIRE:
				asked = ZONE_EMBERSHORE
			if asked in [ZONE_EMBERSHORE, ZONE_NORTH_QUAY, ZONE_CROWN]:
				zone = asked
			else:
				push_warning("CalderaArchipelagoWorld: no boot zone is called '%s' (embershore, north_quay, crown)" % asked)
	use_boot_zone(zone)


## Where the next load of the Caldera starts (--boot-zone; tests). The Crown is a playtest: its landing opens, nothing is saved.
static func use_boot_zone(zone: StringName) -> void:
	_boot_zone_read = true
	boot_zone = ZONE_EMBERSHORE if zone == ZONE_OAKSHIRE else zone
	var crown: bool = zone == ZONE_CROWN
	CalderaWorldState.current.playtest = crown
	CalderaWorldState.current.playtest_crown_landing = crown


## [isle id, arrival id] this load starts at.
func _start_point() -> Array[StringName]:
	if InstanceManager.current.previous_instance == InstanceManager.DUNGEON_DOJO:
		return [CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_ROOT_SANCTUM]
	match boot_zone:
		ZONE_CROWN:
			return [CalderaAtlas.ISLE_THE_CROWN, CalderaAtlas.ARRIVE_SOUTH_BAY]
		ZONE_NORTH_QUAY:
			return [CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_NORTH_QUAY]
	return [CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_START]


func _place_spawn_points(arrival: StringName) -> void:
	var markers: Array[Node] = spawn_points.get_children()
	for index: int in markers.size():
		(markers[index] as Node3D).global_transform = Transform3D(streamer.builder.arrival_basis(arrival), streamer.builder.arrival_spot(arrival, index))


# --- The party ------------------------------------------------------------------------------

## The Soul Tether centroid: the middle of every hero who's up (the streamer's window follows it).
func tether_centroid() -> Vector3:
	var sum: Vector3 = Vector3.ZERO
	var count: int = 0
	for actor: ActorBase in actors.values():
		if is_instance_valid(actor) and not actor.stats.is_downed:
			sum += actor.global_position
			count += 1
	if count == 0:
		var markers: Array[Node] = spawn_points.get_children()
		return (markers[0] as Node3D).global_position if not markers.is_empty() else Vector3.ZERO
	return sum / float(count)


func party_in_order() -> Array[ActorBase]:
	var list: Array[ActorBase] = []
	for actor: ActorBase in actors.values():
		if is_instance_valid(actor):
			list.append(actor)
	list.sort_custom(func(a: ActorBase, b: ActorBase) -> bool: return a.party_slot < b.party_slot)
	return list


## Whether this peer decides world changes (the host, or a party playing offline).
func may_decide() -> bool:
	return not NetworkManager.current.is_online() or NetworkManager.current.is_host()


## Puts this peer's heroes (and companions) at an arrival on the live island, ground loaded first.
func place_party_at(arrival: StringName) -> void:
	var builder: IslandBuilder = streamer.builder
	var seat: int = 0
	var points: Array[Vector3] = [builder.arrival_spot(arrival, 0)]
	var placed: Array[ActorBase] = []
	for actor: ActorBase in party_in_order():
		if actor.is_multiplayer_authority():
			points.append(builder.arrival_spot(arrival, seat))
			placed.append(actor)
			seat += 1
	streamer.load_now(points)
	for index: int in placed.size():
		var where: Transform3D = Transform3D(builder.arrival_basis(arrival), points[index + 1])
		placed[index].spawn_at(where)
		_safe[placed[index].player_id] = where.origin
	_place_spawn_points(arrival)


## Makes `to_isle` live and moves this peer's party into its frame by `shift`
## (a seam's remap), loading the ground under them first. `spawn_arrival`, when
## set, becomes where they get back up.
func swap_island(to_isle: StringName, shift: Vector3, spawn_arrival: StringName) -> void:
	var moved: Array[ActorBase] = []
	var points: Array[Vector3] = [tether_centroid() + shift]
	for actor: ActorBase in party_in_order():
		if actor.is_multiplayer_authority():
			moved.append(actor)
			points.append(actor.global_position + shift)
	var targets: Array[Vector3] = points.slice(1)
	streamer.activate_island(to_isle, points)
	for index: int in moved.size():
		var actor: ActorBase = moved[index]
		actor.place_at(Transform3D(actor.global_transform.basis, targets[index]))
		_safe[actor.player_id] = targets[index]
		if spawn_arrival != &"" and streamer.builder.arrivals.has(spawn_arrival):
			actor.spawn_transform = Transform3D(Basis.IDENTITY, streamer.builder.arrival_spot(spawn_arrival, actor.party_slot))
		else:
			actor.spawn_transform = Transform3D(Basis.IDENTITY, targets[index] + Vector3(0.0, 0.2, 0.0))
	_place_spawn_points(spawn_arrival if spawn_arrival != &"" and streamer.builder.arrivals.has(spawn_arrival) else streamer.builder.arrivals.keys()[0])


## Jumps the whole party to an island's arrival (F9, the tests; every peer when online).
func travel_to(isle_id: StringName, arrival: StringName) -> void:
	if NetworkManager.current.is_online() and NetworkManager.current.is_host():
		_rpc_travel.rpc(isle_id, arrival)
	else:
		_rpc_travel(isle_id, arrival)


@rpc("authority", "call_local", "reliable")
func _rpc_travel(isle_id: StringName, arrival: StringName) -> void:
	var builder: IslandBuilder = CalderaAtlas.builder_for(isle_id)
	if builder == null:
		return
	var focus: Array[Vector3] = [builder.arrival_spot(arrival)]
	streamer.activate_island(isle_id, focus)
	if arrival != &"":
		place_party_at(arrival)


## The host starts a walkable seam's swap on every peer.
func request_seam_swap(seam_id: StringName, from_isle: StringName) -> void:
	if NetworkManager.current.is_online():
		_rpc_seam_swap.rpc(seam_id, from_isle)
	else:
		_rpc_seam_swap(seam_id, from_isle)


@rpc("authority", "call_local", "reliable")
func _rpc_seam_swap(seam_id: StringName, from_isle: StringName) -> void:
	var seam: LoadSeamResource = CalderaAtlas.seam(seam_id)
	if seam != null and streamer.active_isle == from_isle:
		seams.swap_walkable(seam, from_isle)


## A rung Chime-Bell: the host starts the glide on every peer (a client asks the host).
func request_skiff(seam_id: StringName) -> void:
	var seam: LoadSeamResource = CalderaAtlas.seam(seam_id)
	if seam == null or not seam.touches(streamer.active_isle) or seams.is_gliding():
		return
	if not CalderaWorldState.current.lane_open(seam.gate_flag):
		return
	if not may_decide():
		_ask_skiff.rpc_id(1, seam_id)
	elif NetworkManager.current.is_online():
		_rpc_skiff.rpc(seam_id, streamer.active_isle)
	else:
		_rpc_skiff(seam_id, streamer.active_isle)


@rpc("any_peer", "call_remote", "reliable")
func _ask_skiff(seam_id: StringName) -> void:
	if multiplayer.is_server():
		request_skiff(seam_id)


@rpc("authority", "call_local", "reliable")
func _rpc_skiff(seam_id: StringName, from_isle: StringName) -> void:
	var seam: LoadSeamResource = CalderaAtlas.seam(seam_id)
	if seam != null and streamer.active_isle == from_isle:
		seams.start_skiff(seam, from_isle)


@rpc("authority", "call_local", "reliable")
func _rpc_threshold(path: NodePath) -> void:
	var threshold: PartyThreshold = get_node_or_null(path) as PartyThreshold
	if threshold == null:
		return
	var seat: int = 0
	var across: Vector3 = Basis(Vector3.UP, threshold.destination_yaw) * Vector3.RIGHT
	for actor: ActorBase in party_in_order():
		if not actor.is_multiplayer_authority():
			continue
		var spot: Vector3 = threshold.destination + across * (float(seat % 4) - 1.5) * 1.6
		streamer.ensure_ground_at(spot)
		actor.place_at(Transform3D(Basis(Vector3.UP, threshold.destination_yaw), spot))
		_safe[actor.player_id] = spot
		seat += 1
	AudioCues.play(&"portal")


# --- Every frame --------------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	if _key_pressed(KEY_F9) and may_decide():
		playtest_warp()
	if _key_pressed(KEY_F4):
		set_telemetry_visible(not is_telemetry_visible())


## F4's badge: the live score's line (its zone, mode, tempo, mood and voicing, stage, stems and voices).
func set_telemetry_visible(shown: bool) -> void:
	if _badge != null:
		_badge.visible = shown
		_badge.refresh()


func is_telemetry_visible() -> bool:
	return _badge != null and _badge.visible


func telemetry_badge() -> WorldTelemetryBadge:
	return _badge


## F9: between Bramblebridge's green on Embershore and The Crown's landing (a playtest: unsaved).
func playtest_warp() -> void:
	var state: CalderaWorldState = CalderaWorldState.current
	state.playtest = true
	state.playtest_crown_landing = true
	if streamer.active_isle == CalderaAtlas.ISLE_THE_CROWN:
		travel_to(CalderaAtlas.ISLE_EMBERSHORE, CalderaAtlas.ARRIVE_START)
	else:
		travel_to(CalderaAtlas.ISLE_THE_CROWN, CalderaAtlas.ARRIVE_SOUTH_BAY)


func _physics_process(delta: float) -> void:
	if streamer == null or streamer.builder == null:
		return
	var points: Array[Vector3] = [tether_centroid()]
	for actor: ActorBase in actors.values():
		if is_instance_valid(actor) and not actor.stats.is_downed:
			points.append(actor.global_position)
	streamer.focus_points = points
	if seams.is_gliding():
		return
	for actor: ActorBase in actors.values():
		if not is_instance_valid(actor) or not actor.is_multiplayer_authority():
			continue
		_catch_fall(actor)
		_tide(actor, delta)
		if actor.is_local_player():
			_name_region(actor)


func _catch_fall(actor: ActorBase) -> void:
	if actor.is_on_floor() or actor.velocity.y > CATCH_FALL_SPEED or streamer.has_ground_at(actor.global_position):
		return
	streamer.ensure_ground_at(actor.global_position)


## Out of your depth in The Sound, the tide carries you back to the last dry ground.
func _tide(actor: ActorBase, delta: float) -> void:
	var sea: float = CalderaWorldState.current.sea_level_y
	var at: Vector3 = actor.global_position
	var ground_y: float = streamer.height_at(at.x, at.z)
	if at.y < ground_y - 2.5:
		_deep[actor.player_id] = 0.0
		return # Underground: the Sap Galleries.
	var hushed: bool = streamer.builder.beyond_seal(at.x, at.z)
	if actor.is_on_floor() and at.y > sea - 0.3 and not hushed:
		_safe[actor.player_id] = at
	if at.y >= sea - DEEP_WATER and not hushed:
		_deep[actor.player_id] = 0.0
		return
	var held: float = _deep.get(actor.player_id, 0.0) + delta
	_deep[actor.player_id] = held
	if held < DEEP_WATER_TIME:
		return
	_deep[actor.player_id] = 0.0
	tide_returns += 1
	var back: Vector3 = _safe.get(actor.player_id, actor.spawn_transform.origin)
	streamer.ensure_ground_at(back)
	actor.place_at(Transform3D(actor.global_transform.basis, back + Vector3(0.0, 0.3, 0.0)))
	CombatDirector.current.announce(back + Vector3.UP * 2.2, "The Deep-Hush turns you back" if hushed else "The tide carries you back", Color(0.7, 0.9, 1.0), &"wade")


func _name_region(actor: ActorBase) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	var isle: IslandGridResource = streamer.builder.isle
	if _isles_named.get(actor.player_id, &"") != isle.isle_id:
		var first: bool = not _isles_named.has(actor.player_id)
		_isles_named[actor.player_id] = isle.isle_id
		if hud != null and not first:
			hud.show_banner(isle.display_name.to_upper(), _isle_line(isle), isle.accent_color, REGION_BANNER_TIME)
	var region: String = streamer.builder.place_name_at(actor.global_position)
	if _regions.get(actor.player_id, "") == region:
		return
	var first_region: bool = not _regions.has(actor.player_id)
	_regions[actor.player_id] = region
	if hud != null:
		hud.enter_place(region, not first_region)


static func _isle_line(isle: IslandGridResource) -> String:
	var parts: PackedStringArray = PackedStringArray([isle.level_band()])
	if isle.scribe_sign != ScribeSignResource.Sign.NONE:
		var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(isle.scribe_sign) if ArsenalCatalog.current != null else null
		parts.append(seal.seal_name if seal != null else isle.compass)
	if isle.calling_title != "":
		parts.append(isle.calling_title)
	parts.append("%s: %s" % [isle.steading, isle.landmark])
	return " · ".join(parts)


## The region a spot is in on the live island.
func region_at(at: Vector3) -> String:
	return streamer.builder.place_name_at(at) if streamer != null and streamer.builder != null else ""


# --- Streamed things --------------------------------------------------------------------

func _on_collision_changed(chunk: Vector2i, loaded: bool) -> void:
	if streamer.structures == null:
		return
	for node: Node in get_tree().get_nodes_in_group(&"caldera_streamed"):
		var arena: CrownTrialArena = node as CrownTrialArena
		if arena == null or not streamer.structures.is_ancestor_of(arena) or IslandGridResource.chunk_of(arena.global_position) != chunk:
			continue
		if loaded:
			arena.stream_in()
		else:
			arena.stream_out()
	for node: Node in get_tree().get_nodes_in_group(&"caldera_streamed_spawners"):
		var spawner: MobSpawner = node as MobSpawner
		if spawner == null or not streamer.structures.is_ancestor_of(spawner) or IslandGridResource.chunk_of(spawner.global_position) != chunk:
			continue
		if loaded and spawner.mobs.is_empty():
			if spawner.has_meta(&"beacon_guards") and CalderaWorldState.current.get_flag(streamer.builder.isle.beacon_flag):
				continue
			spawner.spawn_mobs()
		elif not loaded:
			spawner.despawn_mobs()


func _on_island_activated(_isle_id: StringName) -> void:
	# Things already in the window when the island arrived grow now.
	for record: ArchipelagoStreamer.LoadedChunk in streamer.chunks.values():
		if record.body != null:
			_on_collision_changed(record.chunk, true)
	if WorldAtmosphereDirector.current != null:
		WorldAtmosphereDirector.current.settle()


func _on_node_added(node: Node) -> void:
	if not is_ancestor_of(node):
		return
	if node is TownsfolkNPC:
		var npc: TownsfolkNPC = node as TownsfolkNPC
		if not npc.quests_offered.is_connected(_on_quests_offered):
			npc.quests_offered.connect(_on_quests_offered)
			npc.wares_requested.connect(_on_wares_requested)
	elif node is SkiffBell:
		var bell: SkiffBell = node as SkiffBell
		if not bell.rung.is_connected(_on_bell_rung):
			bell.rung.connect(_on_bell_rung)
	elif node is PartyThreshold:
		var threshold: PartyThreshold = node as PartyThreshold
		if not threshold.crossed.is_connected(_on_threshold_crossed):
			threshold.crossed.connect(_on_threshold_crossed)
	elif node is HarmonicBell:
		var harmonic: HarmonicBell = node as HarmonicBell
		if not harmonic.rope_pulled.is_connected(_on_rope_pulled):
			harmonic.rope_pulled.connect(_on_rope_pulled)


func _on_bell_rung(_actor: ActorBase, bell: SkiffBell) -> void:
	request_skiff(bell.seam_id)


func _on_threshold_crossed(threshold: PartyThreshold) -> void:
	if NetworkManager.current.is_online():
		_rpc_threshold.rpc(get_path_to(threshold))
	else:
		_rpc_threshold(get_path_to(threshold))


func _on_rope_pulled(_actor: ActorBase, pulled: int, needed: int) -> void:
	if pulled < needed:
		for hud: PlayerHUD in huds.values():
			hud.show_banner("THE HARMONIC BELL", "%d of %d ropes pulled: everyone, together, within %.1f s" % [pulled, needed, HarmonicBell.SYNC_WINDOW],
				CalderaKit.HEARTH_SAFFRON, 2.0)


func _on_quests_offered(actor: ActorBase, npc: TownsfolkNPC) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	if hud != null:
		hud.show_banner("%s of %s" % [npc.npc_name, npc.hub], "Quests: " + "  ·  ".join(npc.quests), QUEST_COLOR, QUEST_BANNER_TIME)


func _on_wares_requested(actor: ActorBase, npc: TownsfolkNPC) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	match npc.wares:
		TownsfolkNPC.Wares.WEAPONS:
			if hud != null:
				hud.open_scribe_desk(ScribeDeskMenu.ROW_WEAPON)
		TownsfolkNPC.Wares.ARMOR:
			if hud != null:
				hud.open_scribe_desk(ScribeDeskMenu.ROW_ARMOR)
		TownsfolkNPC.Wares.CALLING_TUTOR:
			if hud != null:
				hud.open_scribe_desk(ScribeDeskMenu.ROW_CALLING)
		TownsfolkNPC.Wares.BANKER:
			if hud != null:
				hud.open_upgrade_menu()
		TownsfolkNPC.Wares.APOTHECARY:
			CombatDirector.current.apply_heal(actor, actor, actor.stats.stats.max_health)
			CombatDirector.current.reward(actor, 0.0, actor.stats.stats.max_stamina)
			CombatDirector.current.announce(actor.global_position + Vector3.UP * 2.6, "%s: mended" % npc.npc_name, Color(0.5, 1.0, 0.6), &"heal")


# --- World-state banners (the diegetic toast) -------------------------------------------

func _on_world_flag_changed(flag: StringName, value: bool) -> void:
	if not value:
		return
	var state: CalderaWorldState = CalderaWorldState.current
	var title: String = ""
	var line: String = ""
	var color: Color = CalderaKit.HEARTH_SAFFRON
	match flag:
		CalderaWorldState.ROOT_SANCTUM_CLEARED:
			title = "THE TRADE LANES GO DARK"
			line = "Iron, lamp-oil and fuel stop coming: the West Strait, Eel Spit and the Salt Road are open"
		CalderaWorldState.BEACON_IRON, CalderaWorldState.BEACON_TIDE, CalderaWorldState.BEACON_GALE:
			for isle: IslandGridResource in CalderaAtlas.isles():
				if isle.beacon_flag == flag:
					title = "%s'S BEACON BURNS" % isle.display_name.to_upper()
					line = "Its stall opens at Hearthstead Market · the %s calms round The Crown · the Sign is earned" % isle.current_name
					color = isle.accent_color
			if state.can_land_on_crown() and state.beacon_iron and state.beacon_tide and state.beacon_gale:
				line += "\nAll three Beacons burn: the Crown Landing's bell rings at North Quay"
		CalderaWorldState.TRIAL_ANVIL_COMPLETE, CalderaWorldState.TRIAL_GALE_COMPLETE, CalderaWorldState.TRIAL_TIDE_COMPLETE:
			var names: Dictionary[StringName, Array] = {
				CalderaWorldState.TRIAL_ANVIL_COMPLETE: ["THE TRIAL OF THE ANVIL IS DONE", "The World-Tree's western bough blooms Amber", CalderaKit.IRON_AMBER],
				CalderaWorldState.TRIAL_GALE_COMPLETE: ["THE TRIAL OF THE GALE IS DONE", "The World-Tree's northern bough blooms Sea-Azure", CalderaKit.GALE_AZURE],
				CalderaWorldState.TRIAL_TIDE_COMPLETE: ["THE TRIAL OF THE TIDE IS DONE", "The World-Tree's eastern bough blooms Twilight-Violet", CalderaKit.TIDE_VIOLET]}
			title = names[flag][0]
			line = names[flag][1]
			color = names[flag][2]
			if state.cliff_stair_open():
				line += "\nAll three Signs answer: the One Cliff Stair is open"
		CalderaWorldState.EBB_UNLOCKED:
			title = "THE LONG FLOOD ENDS"
			line = "The sea falls six metres: the Old Quay, the three raid gates and the Sea-Door are bared"
		CalderaWorldState.WHEEL_STOPPED:
			title = "THE MILL-WHEEL STOPS"
			line = "The Elder Oak's roots have choked the Bramble's weir: the Root-Sanctum waits beneath it"
			color = Color(0.62, 0.86, 0.5)
		CalderaWorldState.DOWNS_GATE_OPEN:
			title = "THE DOWNS GATE IS OPEN"
			line = "The Downs road runs from Hearthstead over Mill-Downs to Bramblebridge"
	if title == "":
		return
	last_world_banner = title
	for hud: PlayerHUD in huds.values():
		hud.show_banner(title, line, color, WORLD_BANNER_TIME)


func _on_ebb_started() -> void:
	if ebb_cinematic != null and is_instance_valid(ebb_cinematic):
		return
	ebb_cinematic = EbbCinematic.new()
	ebb_cinematic.name = "EbbCinematic"
	ebb_cinematic.setup(get_world_3d(), CalderaAtlas.offset_between(streamer.active_isle, CalderaAtlas.ISLE_THE_CROWN),
		CalderaAtlas.offset_between(streamer.active_isle, CalderaAtlas.ISLE_OAKSHIRE_HOLM))
	add_child(ebb_cinematic)
