## One directional combo form (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §8, the
## Phase 12 Kaizen pass): a short run of postures that ends in a finisher, the
## Black Desert Online way, played with the six postures every hero already has
## (no new button). Light -> Light -> Heavy is the Apprentice's Three-Beat;
## swap the last Heavy for Forward+Heavy and it's the Sundering Gap-Leap, a
## leaping stun that cracks a foe's martial lock; Back+Heavy instead is the
## Wayfarer's Vault-Strike, a back-vault with evasion frames; and so on.
##
## Tokens name the postures as ComboChainComponent hears them: LIGHT, HEAVY,
## FORWARD_HEAVY, BACK_HEAVY, SIDE_HEAVY (Heavy with the stick pushed sideways),
## R_SKILL and LR_ULT. A dodge, a guard or a stagger starts the run over.
##
## Combos are data, registered by id in ArsenalCatalog (Gate 4): a new form is
## one register call, and nothing that plays combos changes.
class_name ComboChainResource
extends Resource

## The posture tokens a combo can name.
const LIGHT: StringName = &"LIGHT"
const HEAVY: StringName = &"HEAVY"
const FORWARD_HEAVY: StringName = &"FORWARD_HEAVY"
const BACK_HEAVY: StringName = &"BACK_HEAVY"
const SIDE_HEAVY: StringName = &"SIDE_HEAVY"
const R_SKILL: StringName = &"R_SKILL"
const LR_ULT: StringName = &"LR_ULT"
const TOKENS: Array[StringName] = [LIGHT, HEAVY, FORWARD_HEAVY, BACK_HEAVY, SIDE_HEAVY, R_SKILL, LR_ULT]
## How each token reads on the HUD, the Binder and the shop.
const TOKEN_GLYPHS: Dictionary[StringName, String] = {
	LIGHT: "Light", HEAVY: "Heavy", FORWARD_HEAVY: "↑+Heavy", BACK_HEAVY: "↓+Heavy", SIDE_HEAVY: "←/→+Heavy",
	R_SKILL: "R", LR_ULT: "L+R",
}
## Finisher defaults: half again the damage and 15 more poise.
const DEFAULT_DAMAGE_MULT: float = 1.5
const DEFAULT_POISE: float = 15.0
const DEFAULT_STEP_M: float = 1.2

@export var combo_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## The postures in order; the last one is the finisher.
@export var input_sequence: Array[StringName] = []
## The party's trail level that teaches it (PartyProgress.trail_level).
@export var required_level: int = 1
## The weapon tier it needs (EquipmentItemResource.EquipmentTier, 1-4).
@export var required_equipment_tier: int = 1

@export_group("Finisher")
@export var finisher_damage_mult: float = DEFAULT_DAMAGE_MULT
@export var finisher_poise_damage: float = DEFAULT_POISE
## Metres the finisher carries the hero along its facing (negative: a back-vault).
## For a flank orbit it's the length of the sideways step round the foe.
@export var step_displacement_m: float = DEFAULT_STEP_M
## A landed finisher stuns the foe this long.
@export var stun_duration_sec: float = 0.0
## Untouchable for this long as the finisher starts.
@export var evasion_iframes_ms: int = 0
## Cracks a foe's MARTIAL_COMBO_KEY lock (a Bravery Counter).
@export var breaks_martial_lock: bool = false
## The finisher steps sideways round the foe instead of straight on, to its flank.
@export var triggers_flank_orbit: bool = false
## A Sign detonation riding the finisher reaches this much further (the Grand Sign-Flow's +25%).
@export var detonation_radius_mult: float = 1.0


func step_count() -> int:
	return input_sequence.size()


func final_token() -> StringName:
	return input_sequence.back() if not input_sequence.is_empty() else &""


## Whether the party has learned it: its trail level, and a weapon of its tier.
func is_unlocked(trail_level: int, weapon_tier: int = 4) -> bool:
	return trail_level >= required_level and weapon_tier >= required_equipment_tier


## Whether the run of postures `buffer` ends with this whole combo.
func completes(buffer: Array[StringName]) -> bool:
	var count: int = input_sequence.size()
	if count == 0 or buffer.size() < count:
		return false
	return buffer.slice(buffer.size() - count) == input_sequence


## How many of this combo's steps the end of `buffer` has already played (0 when none), short of finishing it.
func steps_played(buffer: Array[StringName]) -> int:
	for played: int in range(mini(buffer.size(), input_sequence.size() - 1), 0, -1):
		if buffer.slice(buffer.size() - played) == input_sequence.slice(0, played):
			return played
	return 0


## "Light → Light → ↑+Heavy", for the Binder's Combo Forms and the shop.
func glyphs() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for token: StringName in input_sequence:
		parts.append(TOKEN_GLYPHS.get(token, String(token)))
	return " → ".join(parts)


## The token a posture command plays (`sideways` turns a plain Heavy into SIDE_HEAVY); &"" for none (a roll, a guard).
static func token_for(command: int, sideways: bool) -> StringName:
	match command:
		CombatActionResource.Command.LIGHT:
			return LIGHT
		CombatActionResource.Command.HEAVY:
			return SIDE_HEAVY if sideways else HEAVY
		CombatActionResource.Command.FORWARD_HEAVY:
			return FORWARD_HEAVY
		CombatActionResource.Command.BACK_HEAVY:
			return BACK_HEAVY
		CombatActionResource.Command.TRIGGER_R_SKILL, CombatActionResource.Command.TRIGGER_R_HOLD:
			return R_SKILL
		CombatActionResource.Command.TRIGGER_BOTH_ULT:
			return LR_ULT
	return &""
