## One kind of creature in a starting zone (13_STARTING_ZONE_ENCOUNTER_DESIGN.md §2):
## its family, numbers, how it fights, where it stands on the Hob-to-Boggart
## Spectrum and how it's un-boggarted (15_THE_MYTHOPOETIC_LENS.md §6.1), and how
## it's drawn. Pure data; the Bestiary registers them and WildMob plays them.
class_name MobVariantResource
extends Resource

## The six starting-zone families: five kin of the First-Quiet, and the wildlife
## (sheep, foxes and the roaming Crag-Back Cairn-Drake).
enum Family { CURIOUS_WEALD_WIGHTS, PADFOOT_BOGGARTS, FURROW_IRON_MEN, BRAMBLE_HOBS, CRAG_SPRIGGANS, WILDLIFE, CROWN_TRIAL_KIN, CROWN_SHORE_KIN }
## How it's ranked: a common mob, a rare, an elite, or the roaming mini-boss.
enum Rank { COMMON, RARE, ELITE, BOSS }
## Which code-built body it wears (WildMob).
enum Body { BOAR, SCUTTLER, WOLF, TOAD, HUMANOID, VINE, SHAMBLER, HULK, WIGHT, BEHEMOTH }

@export var variant_id: StringName = &""
@export var display_name: String = ""
@export var family: Family = Family.CURIOUS_WEALD_WIGHTS
@export var rank: Rank = Rank.COMMON
@export var level: int = 1

@export_group("Numbers")
@export var health: float = 80.0
@export var poise: float = 15.0
## Share of damage its hide, shield, bark or barrier soaks (a knockdown cracks it open).
@export var mitigation: float = 0.0
## Damage taken while knocked down (armour bark that's cracked takes a lot more).
@export var knockdown_damage_taken: float = 1.25
@export var move_speed: float = 3.8
@export var turn_speed: float = 6.0

@export_group("Its blow")
@export var damage: float = 8.0
@export var poise_damage: float = 6.0
@export var windup: float = 1.2
@export var active: float = 0.12
@export var recovery: float = 0.6
@export var cooldown: float = 1.6
@export var reach: float = 1.4
@export var hit_radius: float = 1.0
## A dash or pounce along its facing through the wind-up (a linear telegraph).
@export var lunge: float = 0.0
## Ranged: it looses a projectile (drawn like this weapon's shots) out to this range.
@export var ranged: bool = false
@export var projectile_look: StringName = &""
@export var projectile_range: float = 16.0
## The Sign its blow carries (ScribeSignResource.Sign): its limb glows that colour
## through the wind-up, and a Ward-Mantle of the same Sign soaks it (14 GDD §8).
@export var blow_sign: int = ScribeSignResource.Sign.NONE

@export_group("Posture")
## Its Miyamoto tier and lock (a BossEncounterResource id); &"" for roadside kin's default.
@export var encounter_id: StringName = &""

@export_group("Temper")
## Turns on a player this close (0: a curious hob, it only fights back once wronged).
@export var aggro_radius: float = 0.0
## Roams its spawner's patrol path when it isn't fighting (the Crag-Back Cairn-Drake).
@export var patrols: bool = false
## Rooted to its spot (a lasher vine).
@export var rooted: bool = false
## A heavy bell-stomp heard as it walks.
@export var stomps: bool = false

@export_group("Spirit")
## Where it stands on the Hob-to-Boggart Spectrum when it appears.
@export var equilibrium: HobSpectrumComponent.EquilibriumState = HobSpectrumComponent.EquilibriumState.BOGGART_AWOKEN
## How it's un-boggarted when beaten.
@export var resolution: HobSpectrumComponent.UnboggartResolution = HobSpectrumComponent.UnboggartResolution.STATE_UNBOGGART_RELEASE
## What a released spirit becomes.
@export var release_form: HobSpectrumComponent.ReleaseForm = HobSpectrumComponent.ReleaseForm.HEDGE_WREN
## Bellows a 45-frame Challenge-Roar before its first blow (a Cairn-Drake).
@export var roars: bool = false
## Wears a chest Maker-Seal that starts upside-down (a Furrow Iron-Man).
@export var has_maker_seal: bool = false

@export_group("Look")
@export var body: Body = Body.BOAR
@export var radius: float = 0.55
@export var height: float = 0.9
@export var main_color: Color = Color(0.5, 0.4, 0.3)
@export var accent_color: Color = Color(0.3, 0.25, 0.2)
@export var eye_color: Color = Color(1.0, 0.5, 0.2)
