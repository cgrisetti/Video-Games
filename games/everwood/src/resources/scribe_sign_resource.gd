## One of the four Magical Aspects a Scribe Card belongs to
## (05_ARSENAL_AND_CARDS_GDD.md §3.2): the seal a primer stamps on an enemy,
## and what a teammate's detonation of that seal does.
##
## A detonation is pure data: CombatDirector applies every non-zero field the
## same way for any aspect (bonus poise, bonus damage with its burst radius,
## a party heal, party stamina and pips), so a new aspect needs no new code.
class_name AspectSealResource
extends Resource

enum CardAspect { NONE, KINETIC, ELEMENTAL, DIVINE, CELESTIAL }
## The geometric figure drawn in the aspect's floor seal.
enum Glyph { RING, GEAR, STAR, SUN, MOON }

@export var aspect: CardAspect = CardAspect.NONE
@export var display_name: String = ""
## The seal's look: "Amber Gear", "Violet Moon-Ring".
@export var seal_name: String = ""
## What a teammate's heavy turns the seal into: "SHATTERPOINT".
@export var detonation_name: String = ""
@export var color: Color = Color.WHITE
@export var glyph: Glyph = Glyph.RING
## The cue played when the seal detonates.
@export var sound: StringName = &""

@export_group("Detonation (base values; x1.5 on a cross-harmony)")
@export var bonus_poise: float = 0.0
@export var bonus_damage: float = 0.0
## Bonus damage also bursts onto other enemies this close to the target.
@export var burst_radius: float = 0.0
## Extra hit-stop on the detonating hit (the "stagger impulse").
@export var bonus_hit_stop: float = 0.0
@export var party_heal: float = 0.0
@export var party_stamina: float = 0.0
@export var party_pips: float = 0.0
## Party effects reach members this close to the target.
@export var party_radius: float = 10.0


func has_party_effect() -> bool:
	return party_heal > 0.0 or party_stamina > 0.0 or party_pips > 0.0
