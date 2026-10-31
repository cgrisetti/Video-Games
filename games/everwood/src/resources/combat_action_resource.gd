## One skill's frame data: how long each phase lasts, what it costs, what it does
## when it lands, and which skills it can flow into (02_COMBAT_GDD.md §2).
class_name CombatActionResource
extends Resource

## The inputs a player can give. The posture-driven 6-skill loadout (Musk Razor):
## three basics (light, heavy, dodge) and three triggers (L, R, both).
## FORWARD_HEAVY and BACK_HEAVY are BDO chords: stick toward or away from the
## target while pressing heavy. TRIGGER_R_HOLD is the R trigger held down.
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
	STRIKE,           ## Weapon hitbox: damage, poise, primers, detonations.
	DODGE,            ## Roll with invulnerable frames.
	TAUNT,            ## Locks the boss onto you.
	SHADOW_SANCTUARY, ## Tank: a shield cone that protects allies behind you.
	HOMING_HEAL,      ## Healer: a heal that flies to your Soul Tether.
	GREEN_SANCTUARY,  ## Healer: a healing ring on the ground.
	LIFELINE_PULL,    ## Healer: yanks your Soul Tether to your side.
}

## Cross-class primers a DPS applies and a teammate detonates.
enum Synergy { NONE, STAGGER, FROST, RADIANT }

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
@export var primer: Synergy = Synergy.NONE
@export var detonates: bool = false

@export_group("Support effects")
## Heal amount (homing heal) or heal per second (sanctuary ring).
@export var heal_amount: float = 0.0
## Zone radius or cone length, in metres.
@export var effect_radius: float = 0.0
## Zone lifetime, taunt lock or pull time, in seconds.
@export var effect_duration: float = 0.0

@export_group("Flow")
## Action ids this one can flow-cancel into, each matched by its own `command`.
## Ids, not resources, so combo loops don't become reference cycles (and the
## loadout can be saved as a .tres). The class loadout resolves them.
@export var flow_links: Array[StringName] = []


func total_time() -> float:
	return windup_time + active_time + recovery_time


func is_heavy_family() -> bool:
	return command == Command.HEAVY or command == Command.FORWARD_HEAVY or command == Command.BACK_HEAVY
