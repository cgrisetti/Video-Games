## Hub Town: the safe greybox plaza where the party gathers. Walk into the Raid
## Portal together to enter the Dungeon Dojo, and spend the Dojo Shards from its
## chest at the Shard Vendor. Seating, hot-join and the split-screen grid come
## from LevelBase.
class_name HubTown
extends LevelBase

## Demo bots (--demo) gather on the portal, spread out this far.
const DEMO_SPREAD: float = 1.1

@onready var raid_portal: RaidPortal = $RaidPortal
@onready var shard_vendor: ShardVendor = $ShardVendor


func instance_id() -> StringName:
	return InstanceManager.HUB_TOWN


func level_title() -> String:
	return "Hub Town"


func level_hint() -> String:
	return "Walk into the Raid Portal together to fight the Dojo Warden · %d Dojo Shards to spend at the Shard Vendor" % PartyProgress.current.shards


func _setup_level() -> void:
	shard_vendor.menu_requested.connect(_on_vendor_menu_requested)


## Light at the stall opens the upgrade menu on that player's own screen.
func _on_vendor_menu_requested(actor: ActorBase) -> void:
	var hud: PlayerHUD = huds.get(actor.player_id) as PlayerHUD
	if hud != null:
		hud.open_upgrade_menu()


func _demo_post_for(actor: ActorBase) -> Vector3:
	var angle: float = float(actor.party_slot) * TAU / NetworkManager.MAX_PARTY_SIZE
	return raid_portal.global_position + Vector3(cos(angle), 0.0, sin(angle)) * DEMO_SPREAD
