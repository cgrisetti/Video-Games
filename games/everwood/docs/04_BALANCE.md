# 04_BALANCE.md — Balance (Phases 5 and 6)

First-pass numbers, set by arithmetic rather than playtesting. Tune them after the family plays. Every number is a named constant; the "Where" column says which file.

## Targets

| Goal | Target |
|---|---|
| Fight length | About 1.5 minutes for a party of 3, scaling so solo and 5-player fights stay in the 1 to 2 minute range |
| Ultimate (3 pips) | About every 30 s for an active DPS |
| Taunt (1 pip) | About every 10 s for a tank |
| A correct soak | Hurts (about 30% of a DPS), never close to downing anyone |
| Poise break | Comes from coordination (a synergy, heavies, a Perfect Guard), not from a slow trickle of light hits |

## The math behind the boss's health

- Sustained damage per second, counting stamina pauses: Flow DPS about 12 to 16, Shield Tank about 8 to 10, Healer about 5. A 3-player party deals about 25 once you allow for moving and dodging.
- 2,400 HP ÷ 25 ≈ 96 s. Health scales with the party when the fight starts: **900 + 500 per player** (1,400 solo, 2,400 for three, 3,400 for five).

## Boss: Dojo Warden

| Number | Value | Where | Why |
|---|---|---|---|
| Health | 900 + 500 per player | `boss_dummy.gd` | Fight length above |
| Poise | 120, regenerates 15/s after 3 s untouched | `class_loadouts.gd` | A break needs a burst: Rising Drive (12) + a cross-class Shatterpoint slam (30 + 67.5) ≈ 110 |
| Knockdown | 5 s, takes ×1.25 damage | `class_loadouts.gd` | 5 s comes from the GDD; ×1.25 makes the break worth chasing |
| Crushing Swipe | 24 damage, 0.85 s wind-up, every 2.8 s | `class_loadouts.gd`, `boss_dummy.gd` | A guarded hit costs the tank about 4 health and 12 stamina; an unguarded one costs a DPS a quarter of their health |
| First cast / interval | 8 s after the pull, then every 10 s | `boss_dummy.gd` | Time to settle in before the first mechanic |
| Crimson Bloom | 3.5 m circles, 3.0 s cast, 35 damage | `boss_dummy.gd` | 3 s gives kids time to react; a 4.6 m roll clears a circle from its centre |
| Golden Communion | 3.2 m circle, 4.0 s cast. Needs max(1, standing ÷ 2) inside. Deals 30 per standing player (up to 90), split among those inside; 30 to everyone on a fail | `boss_dummy.gd` | A full stack always costs about 30 each. A 2-player couch can clear it with one player (60 to them), never the full 90 |

## Players

| Number | Value | Where |
|---|---|---|
| Health | Tank 160 · Healer 110 · DPS 100 | `class_loadouts.gd` |
| Stamina | 100, regenerates 22/s (from the GDD) after 0.8 s idle | `character_stats_resource.gd` |
| Dodge | 20 stamina, 4.6 m, 0.32 s invulnerable | `class_loadouts.gd` |
| Perfect Guard | Within 200 ms; no stamina, 50 poise to the boss, 250 threat, +½ pip | `stats_component.gd`, `combat_director.gd` |
| Squire auto-guard | Guard goes up when the swipe threatens you and you have 25+ stamina, held until the swing ends (not timed for a Perfect Guard). The DPS rolls instead | `input_component.gd` |
| Threat | Tank ×3, Healer ×0.8; heals add 0.5 per HP; Taunt locks for 6 s | `class_loadouts.gd`, `combat_director.gd` |

## Resonance economy

| Source | Pips |
|---|---|
| Light hit | 0.06 to 0.08 |
| Heavy or primer hit | 0.10 to 0.12 |
| A hit after a flow-cancel | ×1.5 |
| Healing | 0.008 per HP restored (one 22-HP homing heal ≈ 0.18) |
| Perfect Guard | +0.5 |
| Synergy detonation | +0.5 to **both** partners, ×1.5 across roles (+¾) |

Costs: Taunt, Green Sanctuary and Gale Rush cost 1 pip, Lifeline Pull costs 2, ultimates cost 3. At about 1.5 hits per second and half of them flowed, a DPS fills 3 pips in roughly 30 s. Each synergy takes several seconds off that, so teamwork speeds up everyone's ultimates.

## Cross-Class Synergy

| Primer (DPS) | Detonated by | Bonus (×1.5 across roles) |
|---|---|---|
| Stagger (Forward + Heavy) | Tank slam or charge, Healer burst | +45 poise: **Shatterpoint** |
| Frost (Back + Heavy) | Same | +45 damage: **Glacial Rupture** |
| Radiant (L) | Same | Heals the party within 10 m by 20: **Dawnburst** |

A primer lasts 8 s, and the player who applied it can't detonate it. Each detonation plays its own sound, shows a burst of light on both partners, and briefly lights up their pip display.

## Flow-cancel window

| Mode | Buffer window (Phase C) | Flow bonus |
|---|---|---|
| Master | Last 400 ms of the action | +15% speed on the next action |
| Adventurer / Squire | Last 550 ms | None (auto-chaining instead) |

The window never opens during wind-up, and the buffer holds two presses. With a short chain like Flow Cut (0.58 s), the 400 ms window covers most of the swing. With a long one like Cleave (1.01 s), Master players have to time the press (`smoke_test.gd` checks both edges).

## Victory and Dojo Shards

| Number | Value | Where | Why |
|---|---|---|---|
| Slow motion | ×0.2 for 2 real seconds | `dungeon_dojo.gd` | Long enough to see the boss fall, short enough not to drag |
| Chest | 10 + 2 shards per person (16 for three) | `dungeon_dojo.gd` | Bigger parties beat a tougher boss; companions don't add shards |
| Chest arming | Opens 1.2 s after it lands | `reward_chest.gd` | Everyone sees it drop before anyone can open it |
| Trip home | 5 s after the chest opens | `dungeon_dojo.gd` | Time to read the banner |

## Shard Vendor upgrades

Each level adds 10% of the class's own number for the whole party, up to 5 levels. Level n costs 4 × n shards, so one upgrade line costs 60 in all and both cost 120: about 8 wins for a party of three. Fully upgraded, the Shield Tank has 240 health (from 160) and stamina comes back at 33 a second (from 22). Health upgrades also make the boss's fixed damage relatively smaller, so the fight gets gentler as the family progresses.

## Companions

| Number | Value | Where | Why |
|---|---|---|---|
| Backfill | Up to 3 in the party, missing roles in Tank, Healer, DPS order | `companion_ai_component.gd` | A tank protects children best, then a healer |
| Pause between presses | 0.25 s (rolls and Lifeline skip it) | `companion_ai_component.gd` | Quick, but not faster than a person |
| Tank guard | Raised 0.12 s before the swipe lands | `companion_ai_component.gd` | Inside the 200 ms window: the bot tank lands Perfect Guards |
| DPS roll | 0.35 s before the swipe lands | `companion_ai_component.gd` | Clears the reach with time to spare |
| Healer | Heals anyone under 75%; Lifeline when a friend stands in red that's half full | `companion_ai_component.gd` | Keeps a child up without overhealing |
| Stamina reserve | Attacks keep 30 back (the tank excepted) | `companion_ai_component.gd` | Always enough for a roll or a guard |

In a headless run, one player plus two companions beat the Warden (2,400 health) in about 70 seconds.

## Open questions for playtest

- Should taunt cost 1 pip, or should the tank's Perfect Guard pip already be enough?
- Is a companion tank that always lands Perfect Guards too strong next to a child playing tank? (Raise `PERFECT_GUARD_LEAD` past 0.2 s to make it guard early and take chip damage.)
- Is 16 shards a win the right pace? Maxing both upgrades takes about 8 wins; a family that plays once a week might want it faster.
