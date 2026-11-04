## A collectible Scribe Rune-Card (05_ARSENAL_AND_CARDS_GDD.md §3).
##
## A LEAD card sits in one of the Grimoire's four posture slots and carries a
## template action: its frame data, costs and effect, as if swung in melee with
## no under-card. LoadoutComposer channels it through the equipped weapon and
## lets the UNDER card linked beneath it change it with one verb.
##
## Sign-Flow's dioramas (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §4): every lead card
## is an ACTION_LEAF, the verb a posture does, and manifests as a Weapon-Coat,
## a Ward-Mantle or a Lantern-Tether. A LOCATION_PLACE card (a Place-Card) frames
## an Action-Leaf in one of the three diamond sockets (L, R, L+R) like a stage
## backdrop and lends it its landmark's strength; a Place-Card of the leaf's own
## Sign is Home-Ground Harmony and makes the coat last 25% longer.
##
## Role asymmetry (14 GDD §8, the Phase 12 Kaizen pass): the manifestation is
## also the role's delivery (role_delivery reads the same value). A DPS
## Weapon-Coat can be spent by L+R on a 3.2x One-and-Done Seal-Breaker; a Tank
## Ward-Mantle soaks 80% of a blow of its own Sign, shrugs off the stun and
## throws 60 poise back; a Support's leaf shares its ink, so for 8 s every
## teammate on the Soul Tether or within 10 m strikes in its Sign. A finer
## finish adds potency: Gilded Leaf +10%, Star-Inked Vellum +20%.
##
## Cards are data: adding one is a register_card() call in ArsenalCatalog (or a
## .tres file), and nothing that plays cards changes.
class_name ScribeCardResource
extends Resource

## Whether a card leads a Grimoire slot or links beneath one (05 GDD §3.1).
enum LinkRole { LEAD, UNDER }
## What the card is in a diorama: the hero's verb, or the place behind it.
enum CardKind { ACTION_LEAF = 0, LOCATION_PLACE = 1 }
## How an Action-Leaf shows its Sign: on the weapon, on the shield and shoulders, or down the Soul Tether.
enum ManifestationMode { WEAPON_COAT = 0, WARD_MANTLE = 1, LANTERN_TETHER = 2 }
## The same three as each role delivers them (DPS, Tank, Support): one value, two names.
enum RoleDelivery { DPS_WEAPON_COAT = 0, TANK_WARD_MANTLE = 1, SUPPORT_INK_SHARE = 2 }
## The diamond sockets that hold a diorama pair: L Guard, R Skill and L+R Ult.
enum DioramaSocket { GUARD, SKILL, ULT }
## The four posture slots, in Grimoire order.
enum GrimoireSlot { FORWARD, BACK, SIGNATURE, ULTIMATE }
enum CardRarity { BASIC, COMMON, UNCOMMON, RARE, LEGENDARY }
## A copy's finish (06_WORLD_AND_CALLINGS.md §2): Plain Vellum, Gilded Leaf or
## Star-Inked Vellum. A finer finish adds potency (FINISH_POTENCY: +10%, +20%)
## and a Star-Inked leaf's Hearth-Rite is quicker.
enum CardVariant { STANDARD, GILDED_LEAF, STAR_INKED_VELLUM }
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
const MODE_NAMES: Array[String] = ["Weapon-Coat", "Ward-Mantle", "Lantern-Tether"]
const SOCKET_NAMES: Array[String] = ["L Guard", "R Skill", "L+R Ult"]
## The Grimoire slot whose lead card is each socket's Action-Leaf (L has a leaf of its own, -1).
const SOCKET_GRIMOIRE_SLOTS: Array[int] = [-1, GrimoireSlot.SIGNATURE, GrimoireSlot.ULTIMATE]
## Pips a Sign-Flow cast from each socket costs in combat (L's Counter-Brace, R, L+R).
const SOCKET_PIP_COSTS: Array[float] = [1.0, 1.0, 3.0]
## The Gilding Press's price to raise a copy to each finish: Gilded Leaf 50, Star-Inked Vellum 120 Chimes.
const GILDING_COSTS: Array[int] = [0, 50, 120]
## What each finish adds to a card's potency (damage, poise, heals, a Place-Card's bonuses): +10% and +20%.
const FINISH_POTENCY: Array[float] = [1.0, 1.1, 1.2]
const ROLE_DELIVERY_NAMES: Array[String] = ["Weapon-Coat", "Ward-Mantle", "Ink-Share"]

@export var card_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: LinkRole = LinkRole.LEAD
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

@export_group("Sign-Flow diorama")
@export var card_kind: CardKind = CardKind.ACTION_LEAF
@export var manifestation_mode: ManifestationMode = ManifestationMode.WEAPON_COAT
## How long a Sign-Flow coat of this leaf lasts.
@export var coat_duration_sec: float = 8.0
## Place-Cards: the landmark (a Chime-Post) the card is charted from.
@export var location_landmark_id: StringName = &""
## Place-Cards: what they lend the leaf they frame.
@export var location_bonus_reach_m: float = 0.0
@export var location_bonus_poise: float = 0.0
@export var location_bonus_heal: float = 0.0
@export var location_stamina_refund: float = 0.0
## A Place-Card behind a leaf of its own Sign makes the coat last this much longer.
@export var home_ground_duration_mult: float = 1.25
## What the Reed-Light Scribery asks to inscribe or chart a copy.
@export var chime_cost: int = 25

@export_group("Role asymmetry")
## How long a Sign-Flow coat lasts is coat_duration_sec; these say what each role's coat does.
## Support: casting it shares its Sign with the party (Ink-Share) for INK_SHARE_TIME.
@export var shares_ink_to_party: bool = false
## Tank and Support: a coat of it shrugs off stuns and knockback.
@export var grants_stun_immunity: bool = false
## Tank: a Ward-Mantle takes this share off a blow of its own Sign.
@export var ward_damage_mitigation_pct: float = 0.80
## Tank: and throws this much poise back at the attacker.
@export var ward_reflected_poise: float = 60.0
## DPS: L+R spends a live Weapon-Coat on a finisher this many times the weapon's damage.
@export var one_and_done_finisher_mult: float = 3.2

## The role that delivers this leaf (the manifestation under its role's name). Not stored: it is manifestation_mode.
var role_delivery: RoleDelivery:
	get:
		return manifestation_mode as int as RoleDelivery
	set(value):
		manifestation_mode = value as int as ManifestationMode


func is_lead() -> bool:
	return kind == LinkRole.LEAD and card_kind == CardKind.ACTION_LEAF


func is_under() -> bool:
	return kind == LinkRole.UNDER and card_kind == CardKind.ACTION_LEAF


## A hero verb that can stand in a diorama socket (every lead card is one).
func is_action_leaf() -> bool:
	return is_lead()


func is_place_card() -> bool:
	return card_kind == CardKind.LOCATION_PLACE


func mode_name() -> String:
	return MODE_NAMES[manifestation_mode]


## A Support leaf whose cast shares its Sign with the party.
func shares_ink() -> bool:
	return is_action_leaf() and (shares_ink_to_party or role_delivery == RoleDelivery.SUPPORT_INK_SHARE)


## How much a copy of this finish adds to what the card does (1.0, 1.1 or 1.2).
static func finish_potency(variant: int) -> float:
	return FINISH_POTENCY[clampi(variant, 0, FINISH_POTENCY.size() - 1)]


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
	return variant_for_key(text.get_slice(COPY_KEY_SEPARATOR, 1))


## A finish by its save key ("shiny_foil") or its name ("Gilded Leaf"): old
## binders spell finishes by key, so both read back (Plain Vellum otherwise).
static func variant_for_key(key: String) -> CardVariant:
	var index: int = VARIANT_KEYS.find(key)
	if index < 0:
		index = VARIANT_NAMES.find(key)
	return CardVariant.STANDARD if index < 0 else index as CardVariant
