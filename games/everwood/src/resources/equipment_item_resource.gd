## One piece of equipment in the ArsenalCatalog: a suit of armor or a weapon
## (05_ARSENAL_AND_CARDS_GDD.md §2). Pure data. Armor numbers become an
## actor's stats; a weapon's actions become its Light chain and Heavy, and its
## delivery vector decides how Attack Cards reach a target ("The Weapon
## Channels the Card"). Items are drawn from greybox parts until `model` holds
## real art.
class_name EquipmentItemResource
extends Resource

enum ItemSlot { ARMOR, WEAPON }
enum ArmorWeight { LIGHT, MEDIUM, HEAVY }
enum WeaponType { LIGHT_SWORD, HEAVY_AXE, STAFF, BOW }
## How a weapon carries its strikes and Attack Cards to the target.
enum DeliveryVector { MELEE, RANGED_BOLT, RANGED_ARROW }

@export var item_id: StringName = &""
@export var display_name: String = ""
@export var item_slot: ItemSlot = ItemSlot.WEAPON
@export_multiline var description: String = ""

@export_group("Armor")
@export var armor_weight: ArmorWeight = ArmorWeight.MEDIUM
## Share of every hit's damage the armor absorbs.
@export var mitigation: float = 0.0
@export var stamina_regen_per_sec: float = 22.0
@export var roll_distance: float = 4.6
## A guard raised this long before a hit lands is a Perfect Guard (seconds).
@export var perfect_guard_window: float = 0.2

@export_group("Weapon")
@export var weapon_type: WeaponType = WeaponType.LIGHT_SWORD
@export var delivery: DeliveryVector = DeliveryVector.MELEE
## The Light chain in order (each swing flows into the next) and the Heavy finisher.
@export var light_chain: Array[CombatActionResource] = []
@export var heavy: CombatActionResource
## Ranged weapons: how far an Attack Card fired through the weapon flies.
@export var card_range: float = 0.0
@export var projectile_speed: float = 30.0
@export var projectile_radius: float = 0.35
## Ranged weapons: what their shots look like (the head points along -Z).
@export var projectile_parts: Array[PropPartResource] = []
## Sanctuary zones cast with this weapon in hand are this much bigger.
@export var support_radius_multiplier: float = 1.0
## The ribbon a melee weapon draws through a rune-wreathed strike.
@export var trail_color: Color = Color(1.0, 1.0, 1.0, 0.8)
## Where along the weapon (actor space) the ribbon runs from and to.
@export var trail_base: Vector3 = Vector3(0.45, 1.0, -0.3)
@export var trail_tip: Vector3 = Vector3(0.45, 1.0, -1.3)

@export_group("Look")
## Real art for later. While it's empty the item is drawn from `prop_parts`.
@export var model: PackedScene
@export var prop_parts: Array[PropPartResource] = []


func is_armor() -> bool:
	return item_slot == ItemSlot.ARMOR


func is_weapon() -> bool:
	return item_slot == ItemSlot.WEAPON


func is_ranged() -> bool:
	return is_weapon() and delivery != DeliveryVector.MELEE
