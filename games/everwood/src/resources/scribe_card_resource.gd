## A collectible Scribe Rune-Card (05_ARSENAL_AND_CARDS_GDD.md §3).
##
## A LEAD card sits in one of the Grimoire's four posture slots and carries a
## template action: its frame data, costs and effect, as if swung in melee with
## no under-card. LoadoutComposer channels it through the equipped weapon and
## lets the UNDER card linked beneath it change it with one verb.
##
## Cards are data: adding one is a register_card() call in ArsenalCatalog (or a
## .tres file), and nothing that plays cards changes.
class_name ScribeCardResource
extends Resource

enum CardKind { LEAD, UNDER }
## The four posture slots, in Grimoire order.
enum GrimoireSlot { FORWARD, BACK, SIGNATURE, ULTIMATE }
enum CardRarity { BASIC, COMMON, UNCOMMON, RARE, LEGENDARY }
## A copy's finish (06_WORLD_AND_CALLINGS.md §2): Plain Vellum, Gilded Leaf or
## Star-Inked Vellum. Presentation only: the mechanics never read it.
enum CardVariant { STANDARD, SHINY_FOIL, ASTRAL_PRISM }
## THROUGH_WEAPON cards take the weapon's delivery (a swing or a projectile);
## AT_CASTER cards happen around the caster whatever is in their hands.
enum Delivery { THROUGH_WEAPON, AT_CASTER }
## What an under-card does to the lead card above it.
enum UnderVerb { NONE, SIGN_INFUSION, POTENCY_SURGE, HEARTH_ECHO }

## The posture command each Grimoire slot answers to.
const SLOT_COMMANDS: Array[int] = [
	CombatActionResource.Command.FORWARD_HEAVY, CombatActionResource.Command.BACK_HEAVY,
	CombatActionResource.Command.TRIGGER_R_SKILL, CombatActionResource.Command.TRIGGER_BOTH_ULT,
]
const SLOT_NAMES: Array[String] = ["Forward", "Back", "Signature", "Ultimate"]
const RARITY_NAMES: Array[String] = ["Basic", "Common", "Uncommon", "Rare", "Legendary"]
## The finishes' display names (06 GDD §2).
const VARIANT_NAMES: Array[String] = ["Plain Vellum", "Gilded Leaf", "Star-Inked Vellum"]
## How variants are spelled in copy keys and save files (kept from Phase 7, so old binders load).
const VARIANT_KEYS: Array[String] = ["standard", "shiny_foil", "astral_prism"]
## Grimoire Memory each rarity takes up.
const MEMORY_COST: Array[int] = [1, 2, 3, 4, 5]
const COPY_KEY_SEPARATOR: String = ":"

@export var card_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: CardKind = CardKind.LEAD
@export var scribe_sign: ScribeSignResource.Sign = ScribeSignResource.Sign.NONE
@export var rarity: CardRarity = CardRarity.BASIC
## Always in the party's binder (the starter kit); other cards must be collected.
@export var starter: bool = false
## Weight in the boss chest's card drop (0 never drops).
@export var drop_weight: float = 0.0

@export_group("Lead card")
@export var slot: GrimoireSlot = GrimoireSlot.FORWARD
@export var delivery: Delivery = Delivery.THROUGH_WEAPON
## The action before the weapon and under-card shape it.
@export var template: CombatActionResource
## Only a class with Soul Tethers can use it (heals and pulls go down the tether).
@export var needs_soul_tether: bool = false

@export_group("Under card")
@export var verb: UnderVerb = UnderVerb.NONE


func is_lead() -> bool:
	return kind == CardKind.LEAD


func is_under() -> bool:
	return kind == CardKind.UNDER


func memory_cost() -> int:
	return MEMORY_COST[rarity]


## Landing it stamps its Sign's seal on the enemy.
func primes() -> bool:
	return template != null and template.primer != ScribeSignResource.Sign.NONE


func rarity_name() -> String:
	return RARITY_NAMES[rarity]


## A copy in the collection: "rising_drive" for a standard copy, "rising_drive:shiny_foil" otherwise.
static func copy_key(id: StringName, variant: CardVariant) -> StringName:
	if variant == CardVariant.STANDARD:
		return id
	return StringName("%s%s%s" % [id, COPY_KEY_SEPARATOR, VARIANT_KEYS[variant]])


static func copy_card_id(key: StringName) -> StringName:
	return StringName(String(key).get_slice(COPY_KEY_SEPARATOR, 0))


static func copy_variant(key: StringName) -> CardVariant:
	var text: String = String(key)
	if not text.contains(COPY_KEY_SEPARATOR):
		return CardVariant.STANDARD
	var index: int = VARIANT_KEYS.find(text.get_slice(COPY_KEY_SEPARATOR, 1))
	return CardVariant.STANDARD if index < 0 else index as CardVariant
