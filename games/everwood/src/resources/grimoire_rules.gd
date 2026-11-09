## The seven-card hand's rules in one place (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md
## §1, the Creative Director's rulings of 2026-11-06), read by the composer, the
## seal component, the HUD, the Binder, the Seal Press and the host's checks:
##
##   R4  every slot opens at a Character Level: the weapon Seal at 3, the R card
##       at 4, the offhand Seal and the L card at 6, the mantle Seal and the
##       Tuck at 10, the L+R Grand card at 13. The socket is drawn from Lv 1.
##       (On the Bible's 14-level spine, 2026-11-09: the last two moved from 11
##       and 17 to the starts of Stages 3 and 4. Lv 4 is Act I's "Dual
##       Active/Seal Slot": the first level a hero carries a Seal and an Active.)
##   R5  seven slots, seven different cards.
##   R1  the Ink-Well (InkWell rules, below): what a card costs and how deep the
##       well is at each stage.
##
## While the older checks stand the party in the classic full kits
## (PartyProgress.endgame_kits_for_testing), every slot is open, so they keep
## measuring what they always measured.
class_name GrimoireRules
extends RefCounted

## The three card sockets on the Cross (ScribeCardResource.DioramaSocket order).
const SOCKET_L: int = 0
const SOCKET_R: int = 1
const SOCKET_LR: int = 2
## The level each socket's card opens at, in socket order (L, R, L+R).
const SOCKET_OPEN_LEVELS: Array[int] = [6, 4, 13]
## The level each Seal opens at: weapon, offhand, mantle.
const SEAL_OPEN_LEVELS: Array[int] = [3, 6, 10]
## The one Tuck opens here.
const TUCK_OPEN_LEVEL: int = 10
const SOCKET_NAMES: Array[String] = ["L", "R", "L+R"]
const SEAL_NAMES: Array[String] = ["weapon", "offhand", "mantle"]

## Ink-Drops (R1): a basic L or R card costs 1, a mid-tier card (Uncommon and
## up) or any card with its Tuck 2, the L+R Grand card 3.
const COST_BASIC: int = 1
const COST_MID_TIER: int = 2
const COST_GRAND: int = 3
## The well's depth by stage (index 1 to 4), and Wise Hand's extra drops.
const WELL_BY_STAGE: Array[int] = [0, 4, 6, 8, 10]
const WISE_HAND_BONUS_BY_STAGE: Array[int] = [0, 1, 1, 2, 2]
## Refills (R2).
const REFILL_CALM: int = 1
const REFILL_CALM_RARE: int = 2
const REFILL_GREAT_BOGGART: int = 3
const REFILL_BOSS_BEAT: int = 2
const REFILL_GIFT: int = 1


## Every slot open: the older checks' classic full kits (and a missing PartyProgress, in tools).
static func all_open() -> bool:
	return PartyProgress.current == null or PartyProgress.current.endgame_kits_for_testing


static func socket_open(socket: int, level: int) -> bool:
	return all_open() or socket_open_at(socket, level)


## The rule alone, whatever kits the checks stand in: whether `level` has opened the socket.
static func socket_open_at(socket: int, level: int) -> bool:
	return socket >= 0 and socket < SOCKET_OPEN_LEVELS.size() and level >= SOCKET_OPEN_LEVELS[socket]


static func seal_open(seal_index: int, level: int) -> bool:
	return all_open() or (seal_index >= 0 and seal_index < SEAL_OPEN_LEVELS.size() and level >= SEAL_OPEN_LEVELS[seal_index])


static func tuck_open(level: int) -> bool:
	return all_open() or level >= TUCK_OPEN_LEVEL


## "R opens at Lv 4", for the Binder and the host's refusals.
static func socket_opens_text(socket: int) -> String:
	return "%s opens at Lv %d" % [SOCKET_NAMES[socket], SOCKET_OPEN_LEVELS[socket]]


static func seal_opens_text(seal_index: int) -> String:
	return "The %s Seal opens at Lv %d" % [SEAL_NAMES[seal_index], SEAL_OPEN_LEVELS[seal_index]]


## How many of the seven slots a level has opened (the Binder's "6 of 7").
static func slots_open(level: int) -> int:
	var count: int = 0
	for opens: int in SOCKET_OPEN_LEVELS + SEAL_OPEN_LEVELS:
		count += 1 if level >= opens else 0
	return count + (1 if level >= TUCK_OPEN_LEVEL else 0)


## What a socket's card costs in Ink-Drops (R1).
static func ink_cost(socket: int, card: ScribeCardResource, tucked: bool) -> int:
	if socket == SOCKET_LR:
		return COST_GRAND
	var mid_tier: bool = card != null and card.rarity >= ScribeCardResource.CardRarity.UNCOMMON
	return COST_MID_TIER if mid_tier or tucked else COST_BASIC


## The Ink-Well's depth at a stage, with Wise Hand's extra drops.
static func well_depth(stage: int, wise_hand: bool) -> int:
	var at: int = clampi(stage, 1, WELL_BY_STAGE.size() - 1)
	return WELL_BY_STAGE[at] + (WISE_HAND_BONUS_BY_STAGE[at] if wise_hand else 0)


## The first title worn twice among a hand's cards (R5), or &"" when all differ.
static func duplicate_title(card_ids: Array[StringName]) -> StringName:
	var seen: Array[StringName] = []
	for card_id: StringName in card_ids:
		if card_id == &"":
			continue
		if seen.has(card_id):
			return card_id
		seen.append(card_id)
	return &""
