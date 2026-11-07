## An actor's base numbers: health, the stamina / resonance / poise economy,
## threat and guarding (02_COMBAT_GDD.md §1). A player's armor fills in its
## mitigation, stamina regen, roll distance and Perfect Guard window
## (05_ARSENAL_AND_CARDS_GDD.md §2.1).
class_name CharacterStatsResource
extends Resource

@export var max_health: float = 100.0
## Share of every hit's damage that armor absorbs before guards apply.
@export var damage_mitigation: float = 0.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
## Regenerates out of combat / while idle.
@export var stamina_regen_per_sec: float = 22.0
## Seconds after spending stamina before it starts coming back.
@export var stamina_regen_delay: float = 0.8

@export_group("Resonance")
@export var max_resonance_pips: int = 3
## The Ink-Well (25 GDD R1, R2): the pips are Ink-Drops that swings never fill; only
## refills do (calming foes, beating a boss's stagger or gate, a Hearth-Brazier, a gift).
## The composer sets it, and the well's depth in max_resonance_pips, for a hero in play.
@export var ink_well: bool = false
## Every pip earned is multiplied by this (a Wise Hand earns 20% more).
@export var resonance_gain_multiplier: float = 1.0

@export_group("Poise")
## Hidden gauge; 0 means no poise (players). Bosses use 100.
@export var max_poise: float = 0.0
@export var poise_knockdown_time: float = 5.0
## Poise comes back this fast once nothing has hit it for poise_regen_delay seconds,
## so breaking it takes a focused burst rather than a slow trickle of hits.
@export var poise_regen_per_sec: float = 0.0
@export var poise_regen_delay: float = 3.0
## Damage taken is multiplied by this while knocked down (the party's burn window).
@export var knockdown_damage_taken: float = 1.0

@export_group("Threat")
## Multiplies the threat this actor's hits generate (tanks are high).
@export var threat_modifier: float = 1.0

@export_group("Guard")
## Share of a guarded hit's damage that is blocked.
@export var guard_damage_reduction: float = 0.5
## Stamina lost per point of damage blocked.
@export var guard_stamina_per_damage: float = 0.6
## Guarding within the Perfect Guard window of a hit costs nothing and staggers the attacker.
@export var can_perfect_guard: bool = false
## Seconds before a hit that a raised guard still counts as perfect (armor sets it).
@export var perfect_guard_window: float = 0.2

@export_group("Movement")
@export var move_speed: float = 6.0
@export var guard_move_speed: float = 2.5
## How far a dodge roll carries you (armor sets it).
@export var roll_distance: float = 4.6
## Radians per second the actor turns while walking.
@export var turn_speed: float = 12.0
