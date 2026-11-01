## One skill's frame data: how long each phase lasts, what it costs, what it does
## when it lands, and which skills it can flow into (02_COMBAT_GDD.md §2).
## Weapons and Scribe Cards hold these as templates; LoadoutComposer copies
## them into each actor's compiled loadout, channelled through the weapon
## (05_ARSENAL_AND_CARDS_GDD.md §4).
class_name CombatActionResource
extends Resource

## The inputs a player can give. The posture-driven 6-skill loadout (Musk Razor):
## three basics (light, heavy, dodge) and three triggers (L, R, both).
## FORWARD_HEAVY and BACK_HEAVY are BDO chords: stick toward or away from the
## target while pressing heavy. TRIGGER_R_HOLD is the R trigger held down.
## Player kits bind the four Grimoire cards to FORWARD_HEAVY, BACK_HEAVY,
## TRIGGER_R_SKILL and TRIGGER_BOTH_ULT; L is always Guard, so
## TRIGGER_L_SKILL and TRIGGER_R_HOLD are free for future kits.
enum Command {
	NONE,
	LIGHT,
	HEAVY,
	FORWARD_HEAVY,
	BACK_HEAVY,
	DODGE,
	TRIGGER_L_SKILL,
	TRIGGER_R_SKILL,
	TRIGGER_R_HOLD,
	TRIGGER_BOTH_ULT,
}

## What happens when the action reaches Phase B (active).
enum Effect {
	STRIKE,           ## A hit (melee hitbox or projectile): damage, poise, primers, detonations.
	DODGE,            ## Roll with invulnerable frames.
	TAUNT,            ## Locks the boss onto you.
	SHADOW_SANCTUARY, ## Tank: a shield cone that protects allies behind you.
	HOMING_HEAL,      ## Healer: a heal that flies to your Soul Tether.
	GREEN_SANCTUARY,  ## Healer: a healing ring on the ground.
	LIFELINE_PULL,    ## Healer: yanks your Soul Tether to your side.
}

## How a STRIKE reaches its target: a hitbox in front of (or around) the
## actor, or a projectile flying from it.
enum Delivery { MELEE, PROJECTILE }

@export var action_id: StringName = &""
@export var display_name: String = ""
@export var command: Command = Command.LIGHT
@export var effect: Effect = Effect.STRIKE

@export_group("Frame data")
## Phase A: stamina is paid, the actor turns up to 45 degrees toward the target, no cancels.
@export var windup_time: float = 0.2
## Phase B: the hitbox is live; a landed hit freezes both actors (hit-stop).
@export var active_time: float = 0.12
## Phase D: the recovery tail a buffered follow-up can skip.
@export var recovery_time: float = 0.4
## Multiplies the Combat Director's base hit-stop for this action.
@export var hit_stop_scale: float = 1.0
## Metres travelled forward across wind-up and active (negative steps back).
@export var lunge_distance: float = 0.0

@export_group("Cost")
@export var stamina_cost: float = 10.0
@export var resonance_cost: int = 0

@export_group("On hit")
@export var damage: float = 10.0
@export var poise_damage: float = 0.0
@export var threat_multiplier: float = 1.0
## Fraction of a resonance pip earned per landed hit.
@export var resonance_gain: float = 0.1
## How far in front of the actor the hitbox centre sits (0 = around the actor).
@export var reach: float = 1.6
@export var hit_radius: float = 1.2
## Stamps this Sign's seal on the target (a teammate's heavy detonates it).
@export var primer: ScribeSignResource.Sign = ScribeSignResource.Sign.NONE
@export var detonates: bool = false
## The action's own Sign: a detonation by a different Sign than the seal's
## is a cross-harmony (x1.5). Also colours its rune effects.
@export var scribe_sign: ScribeSignResource.Sign = ScribeSignResource.Sign.NONE
@export var delivery: Delivery = Delivery.MELEE

@export_group("Projectile")
@export var projectile_range: float = 0.0
@export var projectile_speed: float = 30.0
@export var projectile_radius: float = 0.35
## Flies on through the first target instead of stopping.
@export var pierces: bool = false
## The weapon whose projectile parts draw the shot (also its pool kind).
@export var projectile_look: StringName = &""
## A melee rune-wreathed strike draws its weapon's ribbon trail.
@export var trail: bool = false

@export_group("Support effects")
## Heal amount (homing heal) or heal per second (sanctuary ring).
@export var heal_amount: float = 0.0
## Zone radius or cone length, in metres.
@export var effect_radius: float = 0.0
## Zone lifetime, taunt lock or pull time, in seconds.
@export var effect_duration: float = 0.0

@export_group("Hearth Echo (an under-card verb)")
## A landed heal bounces this share of itself to the next most hurt ally nearby.
@export var echo_heal_ratio: float = 0.0
## A landed strike gives the attacker this much stamina back.
@export var echo_stamina_on_hit: float = 0.0
## Allies inside this action's sanctuary zone regain this much stamina a second.
@export var zone_stamina_per_second: float = 0.0

@export_group("Scribe Card")
## The lead card this action was composed from (&"" for weapon swings).
@export var card_id: StringName = &""
## Which Grimoire slot it came from (-1 for weapon swings and the dodge).
@export var grimoire_slot: int = -1

@export_group("Flow")
## Action ids this one can flow-cancel into, each matched by its own `command`.
## Ids, not resources, so combo loops don't become reference cycles (and the
## loadout can be saved as a .tres). The class loadout resolves them.
@export var flow_links: Array[StringName] = []


func total_time() -> float:
	return windup_time + active_time + recovery_time


func is_card() -> bool:
	return card_id != &""


func is_projectile() -> bool:
	return effect == Effect.STRIKE and delivery == Delivery.PROJECTILE


## How far away this action can touch a target: a projectile's range, or a
## swing's reach plus its radius and any forward lunge.
func reach_distance() -> float:
	if is_projectile():
		return projectile_range
	return reach + hit_radius + maxf(0.0, lunge_distance)


func is_heavy_family() -> bool:
	return command == Command.HEAVY or command == Command.FORWARD_HEAVY or command == Command.BACK_HEAVY
