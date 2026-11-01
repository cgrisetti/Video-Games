## Bramblebridge (06_WORLD_AND_CALLINGS.md §1), the hub village: a stepped-gable
## canal and watermill village where the party gathers (its files and network
## id keep the old name, Hub Town). Walk into the Raid Portal together to face
## the Cairnsman in his Ring, spend the Chimes from his
## chest at the Chime-Shrine, and change armor, weapon and Scribe Cards at the
## Armory & Scribe Desk. Seating, hot-join and the split-screen grid come from
## LevelBase.
class_name HubTown
extends LevelBase

## Demo bots (--demo) gather on the portal, spread out this far.
const DEMO_SPREAD: float = 1.1

@onready var raid_portal: RaidPortal = $RaidPortal
@onready var chime_shrine: ChimeShrine = $ChimeShrine
@onready var scribe_desk: ScribeDesk = $ScribeDesk


func instance_id() -> StringName:
	return InstanceManager.HUB_TOWN


func level_title() -> String:
	return "Bramblebridge"


func level_hint() -> String:
	return "Raid Portal: face the Cairnsman · Chime-Shrine: %d Chimes · Scribe Desk: armor, weapons and cards" % PartyProgress.current.chimes


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
