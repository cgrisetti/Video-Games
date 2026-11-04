## Bramble-Bridge (06_WORLD_AND_CALLINGS.md §1, 07 GDD §1.1), the hub village
## where the party gathers (its files and network id keep the old name, Hub
## Town). You arrive on the spawn green, walk over the stone arch across the
## canal to the village square, change armor, weapon and Scribe Cards at the
## Armory & Scribe Desk, spend Chimes at the Chime-Shrine, and step into the
## Raid Portal at the northern forest gate together to set out. Seating,
## hot-join and the split-screen grid come from LevelBase.
class_name HubTown
extends LevelBase

## Demo bots (--demo) gather on the portal, spread out this far.
const DEMO_SPREAD: float = 1.1
## The map's reach either side of the square's middle (the walls are 44 m by 60 m).
const MAP_HALF_SIZE: Vector2 = Vector2(26.0, 34.0)
## The holds that change who you are, named for keyboards and pads alike (the HUD's cross shows the fighting moves).
const CHANGE_KEYS: String = "Hold Tab / View: Fellowship · hold C / L3: Calling · hold M / R3: assist mode · tap M / R3: the Atlas · PgUp / PgDn, [ / ] or right stick: tilt the camera · V: mouse-look"

@onready var raid_portal: RaidPortal = $RaidPortal
@onready var chime_shrine: ChimeShrine = $ChimeShrine
@onready var scribe_desk: ScribeDesk = $ScribeDesk


func instance_id() -> StringName:
	return InstanceManager.HUB_TOWN


## The walled village, gate to gate (18 GDD §7.1).
func map_rect() -> Rect2:
	return Rect2(-MAP_HALF_SIZE.x, -MAP_HALF_SIZE.y, MAP_HALF_SIZE.x * 2.0, MAP_HALF_SIZE.y * 2.0)


## The lane from the south wall over Bramble-Bridge to the Forest Gate.
func map_paths() -> Array[Dictionary]:
	var lanes: Array[Dictionary] = [{"points": PackedVector2Array([Vector2(0.0, 30.0), Vector2(0.0, -31.0)]), "half_width": 2.4}]
	return lanes


func level_title() -> String:
	return "Bramble-Bridge"


func home_place() -> String:
	return "Bramble-Bridge"


func music_profile_at(_position: Vector3) -> StringName:
	return LandblockManifest.ZONE_MUSIC[LandblockManifest.Zone.BRAMBLEBRIDGE]


func level_hint() -> String:
	return "Raid Portal: set out for the Cairnsman · Chime-Shrine: %d Chimes · Scribe Desk: armor, weapons, cards and Calling\n%s" % [
		PartyProgress.current.chimes, CHANGE_KEYS]


func _setup_level() -> void:
	chime_shrine.menu_requested.connect(_on_shrine_menu_requested)
	scribe_desk.menu_requested.connect(_on_desk_menu_requested)


## Light at the shrine opens the upgrade menu on that player's own screen.
func _on_shrine_menu_requested(actor: ActorBase) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	if hud != null:
		hud.open_upgrade_menu()


## Light at the desk opens the Armory & Scribe Desk on that player's own screen.
func _on_desk_menu_requested(actor: ActorBase) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	if hud != null:
		hud.open_scribe_desk()


func _demo_post_for(actor: ActorBase) -> Vector3:
	var angle: float = float(actor.party_slot) * TAU / NetworkManager.MAX_PARTY_SIZE
	return raid_portal.global_position + Vector3(cos(angle), 0.0, sin(angle)) * DEMO_SPREAD
