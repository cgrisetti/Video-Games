# 04_BALANCE.md — Phase 5 Balance Pass

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
| Golden Communion | 3.2 m circle, 4.0 s cast, 90 split among those inside (2 needed), 30 to everyone on a fail | `boss_dummy.gd` | A 3-player soak costs 30 each |

## Players

| Number | Value | Where |
|---|---|---|
| Health | Tank 160 · Healer 110 · DPS 100 | `class_loadouts.gd` |
| Stamina | 100, regenerates 22/s (from the GDD) after 0.8 s idle | `character_stats_resource.gd` |
| Dodge | 20 stamina, 4.6 m, 0.32 s invulnerable | `class_loadouts.gd` |
| Perfect Guard | Within 200 ms; no stamina, 50 poise to the boss, 250 threat, +½ pip | `stats_component.gd`, `combat_director.gd` |
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

## Open questions for playtest

- Is 0.85 s enough warning on the swipe for a child to guard, or should Squire Gambit also auto-guard?
- Does the soak's 2-player minimum suit a 2-player couch? (A party of 2 needs both inside.)
- Should taunt cost 1 pip, or should the tank's Perfect Guard pip already be enough?
