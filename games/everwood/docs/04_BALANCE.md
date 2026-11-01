# 04_BALANCE.md — Balance (Phases 5 to 8)

Phase 8 renamed things (06_WORLD_AND_CALLINGS.md): the Aspects are the Four Scribe Signs, the Dojo Warden is The Cairnsman of Doverslap, and card variants are finishes. The numbers didn't change.

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

## Boss: The Cairnsman of Doverslap

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
| Stamina | 100, regenerating after 0.8 s idle at the armor's rate (below) | `character_stats_resource.gd`, `arsenal_catalog.gd` |
| Dodge | 20 stamina, 0.32 s invulnerable, as far as the armor allows | `arsenal_catalog.gd`, `dodge_state.gd` |
| Perfect Guard | Every class (L is always Guard), within the armor's window; no stamina, 50 poise to the boss, +½ pip, and 250 threat for a tank (others scaled by their threat modifier, so a DPS draws 83) | `stats_component.gd`, `combat_director.gd` |
| Squire auto-guard | Guard goes up when the swipe threatens you and you have 25+ stamina, held until the swing ends (not timed for a Perfect Guard). Every class has a guard now | `input_component.gd` |
| Threat | Tank ×3, Healer ×0.8; heals add 0.5 per HP; Taunt locks for 6 s | `class_loadouts.gd`, `combat_director.gd` |

## Resonance economy

| Source | Pips |
|---|---|
| Light hit | 0.06 to 0.08 |
| Heavy or primer hit | 0.10 to 0.12 |
| A hit after a flow-cancel | ×1.5 |
| Healing | 0.008 per HP restored (one 22-HP homing heal ≈ 0.18) |
| Perfect Guard | +0.5 |
| Seal detonation | +0.5 to **both** partners, ×1.5 on a cross-harmony (+¾) |
| Astral Chorus | +0.5 to everyone within 10 m (×1.5 on a cross-harmony), on top of the partners' reward |

Costs: Taunt, Green Sanctuary and Gale Rush cost 1 pip, Lifeline Pull costs 2, ultimates cost 3. At about 1.5 hits per second and half of them flowed, a DPS fills 3 pips in roughly 30 s. Each detonation takes several seconds off that, so teamwork speeds up everyone's ultimates.

## The Four Scribe Signs (06 GDD §2, 05 GDD §3.2)

A primer card stamps its Sign on the boss for 8 s; a *teammate's* Heavy (every weapon's Heavy detonates) or a detonating card cashes it in. A different role **or** a different Sign than the seal's is a cross-harmony: ×1.5. The numbers live on each `ScribeSignResource` in `arsenal_catalog.gd`; `CombatDirector` applies whatever is set.

| Sign | Colour | Detonation | Base effect (×1.5 cross-harmony) | Starter primers |
|---|---|---|---|---|
| `SIGN_IRON_ROOT` (Iron-Root) | Amber / ochre | **Shatterpoint** | +45 (67.5) poise, +1 hit-stop "stagger impulse" | Rising Drive (DPS) |
| `SIGN_RIME_GALE` (Rime-Gale) | Sea-azure | **Glacial Rupture** | +45 (67.5) damage, bursting 4 m to other enemies | Frost Crescent (DPS) |
| `SIGN_WARM_HEARTH` (Warm-Hearth) | Saffron-gold | **Dawnburst** | Heals the party within 10 m by 20 (30) | Sunlit Lance (Healer) |
| `SIGN_STAR_TIDE` (Star-Tide) | Twilight-violet | **Astral Chorus** | +25 (37.5) stamina and +0.5 (0.75) pips to the party within 10 m | Gale Rush (DPS) |

The player who stamped a seal can't detonate it. Each detonation plays its own sound on every peer, shows a burst of light on both partners, and lights up their pip display.

## Armor weights (05 GDD §2.1)

| Armor | Mitigation | Stamina regen | Roll | Perfect Guard window | Worn by (starter) |
|---|---|---|---|---|---|
| Hearth-Linen (Light) | 10% | 27.5 / s | 5.2 m | 200 ms | Healer |
| Ranger Leather (Medium) | 20% | 22.0 / s | 4.6 m | 200 ms | DPS |
| Ironwood Plate (Heavy) | 35% | 18.0 / s | 3.8 m | 260 ms | Tank |

Mitigation comes off every hit before guards (telegraphs too). So a guarded swipe now costs the tank about 2 health (24 × 0.65 × 0.15), and a full soak costs 27 in linen or 19.5 in plate. Fights are a little gentler than in Phase 6; the upgrade and level curves assume that. A roll also slides on after its push, so the distance travelled is longer than the table (the smoke test compares linen against plate rather than exact metres).

## Weapons (05 GDD §2.2)

| Weapon | Light chain | Heavy (always detonates) | Cards travel as | Notes |
|---|---|---|---|---|
| Sword & Buckler | 3 cuts, 0.55 s, 10 stamina, 8/9/12 damage | Advancing Thrust: 18 damage, 15 poise, 2 m lunge | Melee swing with a ribbon trail | Tank starter |
| Greataxe | 2 wide cleaves, 0.85 s, 16 stamina, 14/17 damage | Earth-Splitter: 28 damage, 35 poise | Melee swing with a ribbon trail | Slow and heavy |
| Hearthwood Scribe Staff | 2 sweeps (7) then a 12 m arcane bolt (10) | Resonant Pulse: 16 damage AoE around you | 12 m rune bolts | Sanctuaries +25% radius; healer starter |
| Wind-Ash Hunter Bow | 14 m snap-shots, 10 stamina, stepping back 0.6 m | Piercing Draw: 24 damage, 20 poise, 18 m, pierces | 18 m rune arrows | DPS starter |

Ranged cards keep their numbers but are planted: forward lunges are dropped (Rising Drive, Gale Rush), backward steps stay (Frost Crescent). Shots lean toward a target within about 37° of where you face. A shot freezes only its target in hit-stop.

## Scribe Cards (05 GDD §3)

| Slot | Tank | Healer | DPS | Boss drops |
|---|---|---|---|---|
| Forward + Heavy | Shield Charge (detonates) | Sunlit Lance (Warm-Hearth primer) | Rising Drive (Iron-Root primer) | Moonfall Cleave (Rare, Star-Tide primer) |
| Back + Heavy | Shadow Sanctuary (60% shield cone) | Green Sanctuary (1 pip, 8 HP/s) | Frost Crescent (Rime-Gale primer) | Aegis of Embers (Rare, wider cone) |
| R (signature) | Taunt (1 pip) | Homing Heal (12 stamina, 22 HP) | Gale Rush (1 pip, Star-Tide primer) | Starlit Volley (Rare, 1 pip, Rime-Gale primer) |
| L + R (ultimate) | Bulwark Quake (3 pips) | Lifeline Pull (2 pips) | Tempest Flow (3 pips) | Dawnbreaker (Legendary, 3 pips, detonates and stamps Warm-Hearth) |

Any class may slot any card except Homing Heal and Lifeline Pull, which need a Soul Tether. Homing Heal costs no pip (see 05 GDD §4.6).

| Under-card (Common) | Verb | Effect |
|---|---|---|
| Iron-Root Link | Potency Surge | ×1.2 damage, healing and poise |
| Rime-Gale Link | Sign Infusion | The card's hits stamp the Sign of Rime-Gale |
| Warm-Hearth Link | Hearth Echo | Heals bounce 50% to the next hurt ally within 8 m; sanctuaries restore 8 stamina/s; hits return 8 stamina |
| Star-Tide Link | Sign Infusion | The card's hits stamp the Sign of Star-Tide |

## Grimoire and card drops

| Number | Value | Where | Why |
|---|---|---|---|
| Grimoire level | 1 + victories, up to 5 | `loadout_composer.gd` | One link and two memory per win: noticeable progress every fight |
| Memory | 4 + 2 per level (6 at Lv 1, 14 at Lv 5) | `loadout_composer.gd` | The starter kit costs 4; a Rare lead plus a link doesn't fit until Lv 3 |
| Memory per card | Basic 1 · Common 2 · Uncommon 3 · Rare 4 · Legendary 5 | `scribe_card_resource.gd` | Rarer cards are stronger, so they crowd the Grimoire |
| Under-card links | Level − 1 (none at Lv 1, all four at Lv 5) | `loadout_composer.gd` | 05 GDD §3.1 |
| Chest card | One per chest: boss cards weigh 3, each starter card 1 | `arsenal_catalog.gd` | About half the drops are boss cards |
| Finish odds | Plain Vellum 60% · Gilded Leaf 30% · Star-Inked Vellum 10% | `arsenal_catalog.gd` | A starter card never drops in Plain Vellum (you already have it), so it comes Gilded |

## Card choreography (presentation only)

| Effect | Value | Where |
|---|---|---|
| Floor seal | 3 m across, blooms in 0.15 s, gone at 0.6 s | `scribe_invocation_fx.gd`, `scribe_seal.gdshader` |
| Vellum card | Flips in the first 45% of the seal's life, then dissolves | `scribe_invocation_fx.gd` |
| Gilded Leaf | Gold rings at 1.15 m and 1.42 m, a 1.25× chime, gold ribbon trail | `scribe_invocation_fx.gd`, `weapon_trail.gd` |
| Star-Inked Vellum | 2.4 m starfield dome through the wind-up; footprints every 0.55 m for 2.5 s, each fading in 1 s | `scribe_invocation_fx.gd`, `glow_footprint.gd` |
| Melee ribbon | A 2-radian sweep in 0.18 s, samples living 0.2 s | `weapon_trail.gd` |

## Flow-cancel window

| Mode | Buffer window (Phase C) | Flow bonus |
|---|---|---|
| Master | Last 400 ms of the action | +15% speed on the next action |
| Adventurer / Squire | Last 550 ms | None (auto-chaining instead) |

The window never opens during wind-up, and the buffer holds two presses. With a short action like a Snap-Shot (0.56 s), the 400 ms window covers most of it. With a long one like the Piercing Draw (1.1 s), Master players have to time the press (`smoke_test.gd` checks both edges, timed from whatever Heavy the DPS holds).

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
| Backfill | Up to 3 in the party, missing roles in Tank, Healer, DPS order, in their starter kits | `companion_ai_component.gd` | A tank protects children best, then a healer |
| Range | A bot with a bow or staff stands at 60% of its shot's reach; reach always comes from its loadout | `companion_ai_component.gd` | Plays any kit without per-weapon code |
| Pause between presses | 0.25 s (rolls and Lifeline skip it) | `companion_ai_component.gd` | Quick, but not faster than a person |
| Tank guard | Raised 0.12 s before the swipe lands | `companion_ai_component.gd` | Inside the 200 ms window: the bot tank lands Perfect Guards |
| DPS roll | 0.35 s before the swipe lands | `companion_ai_component.gd` | Clears the reach with time to spare |
| Healer | Heals anyone under 75%; Lifeline when a friend stands in red that's half full | `companion_ai_component.gd` | Keeps a child up without overhealing |
| Stamina reserve | Attacks keep 30 back (the tank excepted) | `companion_ai_component.gd` | Always enough for a roll or a guard |

In a headless run, one player plus two companions beat the Cairnsman (2,400 health) in about 70 seconds.

## Open questions for playtest

- Should taunt cost 1 pip, or should the tank's Perfect Guard pip already be enough?
- Is a companion tank that always lands Perfect Guards too strong next to a child playing tank? (Raise `PERFECT_GUARD_LEAD` past 0.2 s to make it guard early and take chip damage.)
- Is 16 shards a win the right pace? Maxing both upgrades takes about 8 wins; a family that plays once a week might want it faster.
- With armor mitigation on every hit, is the Cairnsman now too gentle? Its damage could rise 15–20% to make up for it.
- Does a Rare card at Lv 2 (memory 7 of 8, no room for a link) feel like a real choice, or should Lv 2 hold 9?
