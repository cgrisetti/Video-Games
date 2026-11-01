## One of the Four Scribe Signs (06_WORLD_AND_CALLINGS.md §2; mechanics in
## 05_ARSENAL_AND_CARDS_GDD.md §3.2): the seal a primer card stamps on an
## enemy, and what a teammate's detonation of that seal does.
##
## A detonation is pure data: CombatDirector applies every non-zero field the
## same way for any Sign (bonus poise, bonus damage with its burst radius, a
## party heal, party stamina and pips), so a new Sign needs no new code.
class_name ScribeSignResource
extends Resource

enum Sign { NONE, SIGN_IRON_ROOT, SIGN_RIME_GALE, SIGN_WARM_HEARTH, SIGN_STAR_TIDE }
## The geometric figure drawn in the Sign's floor seal.
enum Glyph { RING, GEAR, STAR, SUN, MOON }

@export var scribe_sign: Sign = Sign.NONE
## The Sign's short name: "Iron-Root".
@export var display_name: String = ""
## How the seal reads on screen: "Sign of Iron-Root".
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
