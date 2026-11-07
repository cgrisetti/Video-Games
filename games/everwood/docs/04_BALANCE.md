# 04_BALANCE.md — Balance (Phases 5 to 12 and the Mythopoetic Lens)

Every name below is in the words of [15_THE_MYTHOPOETIC_LENS.md](15_THE_MYTHOPOETIC_LENS.md): the Four Scribe Signs, the Cairnsman of Doverslap Falls, card finishes, Chimes, and foes as kin of the First-Quiet. Renames never moved a number. The Callings, the Doverslap Falls Expedition and the Phase 2 Gale-Beam start at "The 3x3 Callings"; the Hob-to-Boggart Spectrum's numbers are in the last table.

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

## Boss: The Cairnsman of Doverslap Falls

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
| Hearth-Linen Coat (Light) | 10% | 27.5 / s | 5.2 m | 200 ms | Healer |
| Hedgerow Wool-Mantle (Medium) | 20% | 22.0 / s | 4.6 m | 200 ms | DPS |
| Iron-Wood Ring-Coat (Heavy) | 35% | 18.0 / s | 3.8 m | 260 ms | Tank |

Mitigation comes off every hit before guards (telegraphs too). So a guarded swipe now costs the tank about 2 health (24 × 0.65 × 0.15), and a full soak costs 27 in a Hearth-Linen Coat or 19.5 in an Iron-Wood Ring-Coat. Fights are a little gentler than in Phase 6; the upgrade and level curves assume that. A roll also slides on after its push, so the distance travelled is longer than the table (the smoke test compares linen against plate rather than exact metres).

## Weapons (05 GDD §2.2)

| Weapon | Light chain | Heavy (always detonates) | Cards travel as | Notes |
|---|---|---|---|---|
| Falchion | 3 cuts, 0.55 s, 10 stamina, 8/9/12 damage | Advancing Thrust: 18 damage, 15 poise, 2 m lunge | Melee swing with a ribbon trail | Tank starter |
| Broad-Axe | 2 wide cleaves, 0.85 s, 16 stamina, 14/17 damage | Earth-Splitter: 28 damage, 35 poise | Melee swing with a ribbon trail | Slow and heavy |
| Rowan Way-Staff | 2 sweeps (7) then a 12 m arcane bolt (10) | Resonant Pulse: 16 damage AoE around you | 12 m Sign-bolts | Sanctuaries +25% radius; healer starter |
| Yew Longbow | 14 m snap-shots, 10 stamina, stepping back 0.6 m | Piercing Draw: 24 damage, 20 poise, 18 m, pierces | 18 m Sign-arrows | DPS starter |

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

## Victory and Chimes

| Number | Value | Where | Why |
|---|---|---|---|
| Slow motion | ×0.2 for 2 real seconds | `dungeon_dojo.gd` | Long enough to see the boss fall, short enough not to drag |
| Chest | 10 + 2 Chimes per person (16 for three) | `dungeon_dojo.gd` | Bigger parties beat a tougher boss; companions don't add Chimes |
| Chest arming | Opens 1.2 s after it lands | `reward_chest.gd` | Everyone sees it drop before anyone can open it |
| Trip home | 5 s after the chest opens | `dungeon_dojo.gd` | Time to read the banner |

## Chime-Shrine upgrades

Each level adds 10% of the class's own number for the whole party, up to 5 levels. Level n costs 4 × n Chimes, so one upgrade line costs 60 in all and both cost 120: about 3 full expeditions for a party of three (a run pays about 40, see below). Fully upgraded, a Bridge-Warden has 270 health (from 180), and every stamina regen grows by half (22 to 33 a second in medium armor, before the Calling's own change). Health upgrades also make the boss's fixed damage relatively smaller, so the fight gets gentler as the family progresses.

## Companions

| Number | Value | Where | Why |
|---|---|---|---|
| Backfill | Up to 3 in the party, missing roles in Tank, Healer, DPS order, in their starter kits | `companion_ai_component.gd` | A tank protects children best, then a healer |
| Range | A bot with a bow or staff stands at 60% of its shot's reach; reach always comes from its loadout | `companion_ai_component.gd` | Plays any kit without per-weapon code |
| Pause between presses | 0.25 s (rolls and Lifeline skip it) | `companion_ai_component.gd` | Quick, but not faster than a person |
| Tank guard | Raised 0.12 s before the swipe lands | `companion_ai_component.gd` | Inside the 200 ms window: the bot tank lands Perfect Guards |
| DPS roll | 0.35 s before the swipe lands | `companion_ai_component.gd` | Clears the reach with time to spare |
| Healer | Heals anyone under 75%; Lifeline when a friend stands in red that's half full | `companion_ai_component.gd` | Keeps a child up without overhealing |
| Stamina reserve | Attacks keep 30 back; the tank keeps 30 too (25 guards, +5) | `companion_ai_component.gd` | Always enough for a roll or a guard (a Stout Heart's slower stamina had a tank swinging itself too tired to guard) |
| Awakened kin | Fight any woken Bramble-Hob or Wisp-Boggle within 20 m | `companion_ai_component.gd` | Bots help close Hush-Cracks, but don't wander off after far ones |
| Catch-up | More than 22 m behind the leader, with no foe nearby: appear 3 m behind them | `companion_ai_component.gd` | A long trail (and walls) would otherwise strand a bot |
| Gale-Beam | The tank faces the boss and raises Shadow Sanctuary; others go into its cone (45% of its length), or step out of the lane | `companion_ai_component.gd` | Shows children what to do |

In a headless run, one player plus two companions beat the Cairnsman (2,400 health) in about 70 seconds.

## The 3x3 Callings (07 GDD §1.3)

A Calling is the Fellowship's base numbers plus one Secondary modifier. The modifiers are `SecondaryCallingResource` data registered in `ArsenalCatalog._build_callings()` (`arsenal_catalog.gd`); `callings.gd` applies them. Each Fellowship starts in its own column, so out of the box the Shield-Sworn is a Bridge-Warden (180 health), the Wayfarer a Hedge-Runner and the Lantern-Bearer a Lantern-Scribe (105 health).

| Secondary | Health | Stamina regen | Potency | Gear it unlocks |
|---|---|---|---|---|
| Stout Heart (+Tank) | +20 | −2 / s | +25% poise damage, +30 ms Perfect Guard | Heavy armor |
| Swift Foot (+DPS) | +0 | +3 / s | +15% damage on every strike (weapon and card) | Bow and axe |
| Wise Hand (+Magic) | −5 | +2 / s | +20% pips from every source, +20% healing, +1 Grimoire Memory | Staff |

Everyone may use the Falchion and light or medium armor, and a Fellowship always has its own column's gear (the Shield-Sworn wear the Iron-Wood Ring-Coat, Wayfarers carry bows and axes, Lantern-Bearers bear staves). Stamina regen never drops below 6 a second, whatever the armor and Calling. A save naming gear the Calling can't use falls back to the starter piece.

Why these numbers: every Secondary costs something or gives in two directions, so no column is simply best. The double-down Callings (Bridge-Warden, Hedge-Runner, Lantern-Scribe) get the purest version of their seat, and the cross Callings trade a little of it for new gear (a Weald-Captain tank with a Broad-Axe, a Sign-Seeker archer who earns pips faster).

## The Doverslap Falls Expedition (07 GDD §3)

| Number | Value | Where | Why |
|---|---|---|---|
| Woodland kin | 65 health, 30 poise (2 s knockdown), Bramble-Hob nip 7, Wisp-Boggle claw 10 | `class_loadouts.gd` | A cleave, a volley or one detonation un-boggarts a few; they teach multi-target play, not hurt |
| Kin speed | Bramble-Hob 4.6 m/s, Wisp-Boggle 3.6 m/s; a strike every 1.5 s | `class_loadouts.gd`, `woodland_minion.gd` | Slower than a player (6+), so you can always walk away |
| Hush-Crack wake / settle | A player within 9 m, or one of its kin hurt; settles when nobody is within 18 m | `minion_camp.gd` | Sleeping kin don't jump you from across the clearing |
| Hush-Crack reward | 3 Chimes per sealed Hush-Crack (2 of them) | `dungeon_dojo.gd` | Small, but it makes the trail worth fighting |
| Wayfarer's Chest | 15 Chimes and one Uncommon card (own dice, never shifts the boss's drop) | `dungeon_dojo.gd` | A reward for exploring the alcove |
| Water-Shrine | Full health and stamina for the whole party, then rests 40 s | `water_shrine.gd` | One clean reset before the gorge; not a heal-bot |
| Maker-Seal Plates | min(2, standing party) plates held together for 2 s | `coop_gate.gd` | Needs teamwork without ever soft-locking a lone player |
| Gale-Jet | Quiet 3.5 s, gathers 1.4 s (the lane pales), blows 0.6 s: a 5 m shove down the lane, no damage | `gorge_gale_jet.gd` | A readable rhythm that pushes children around without hurting them |
| Bell-Winch | Only rings from inside a Shadow Sanctuary cone (the tank holding it counts) | `coop_gate.gd` | The tank's shield is the key; teaches "stand behind the tank" before the boss asks for it |
| Checkpoints | Zone 2 from z < 15, Zone 3 past the gate | `dungeon_dojo.gd` | A wipe never sends you back through the Hush-Cracks |

In a headless run, one player with two companions seals both Hush-Cracks and reaches the falls in about 40 seconds, and a demo player and a companion open the gate on the plates in under 20.

## Phase 2: the Doverslap Gale-Beam (07 GDD §3, Zone 3)

| Number | Value | Where | Why |
|---|---|---|---|
| Phase 2 | At 50% health or less; the first beam 1.5 s later | `boss_dummy.gd` | A clear "the fight changed" moment |
| Rotation | Beam, then Crimson or Golden by turns, then beam again (every other cast) | `boss_dummy.gd` | The floor mechanics stay, the beam joins them |
| Gale-Beam | 3.2 s cast; a 22 × 4.5 m lane from the boss through its top-threat player; it tracks them until 70% cast, then locks | `boss_dummy.gd`, `raid_telegraph_decal.gd` | Long enough for the tank to turn and raise the shield and for everyone to get behind it |
| Sheltered | In any Shadow Sanctuary cone (or holding one): no damage, +½ pip | `boss_dummy.gd` | Rewards doing it right, like a Perfect Guard |
| Exposed | 40 damage (before armor: 36 in a Hearth-Linen Coat, 26 in an Iron-Wood Ring-Coat) and a 4 m knockback, never past 16 m from the boss | `boss_dummy.gd` | Hurts but never kills a full-health player on its own |
| Squire shelter | A Squire tank the beam is aimed at turns to the boss and raises Shadow Sanctuary once the beam is 25% full (if it has the stamina); anyone else in the lane outside a shield rolls sideways at 85% | `input_component.gd` (`AUTO_SHELTER_FILL`, `AUTO_EVADE_FILL`) | 08 Gate 5: an assisted child survives every mechanic |

## The seamless world (10_WORLD_ARCHITECTURE.md)

| Number | Value | Where | Why |
|---|---|---|---|
| Landblock | 128 m square; the corridor is chunks (0, 0) to (0, -3) | `world_grid_config.gd` | A whole zone fits in one, and one attaches inside the frame budget |
| Streaming | Gameplay within 1 chunk of any player (unloads past 2), clutter within 2 (past 3), terrain and HLOD within 3 (past 4) | `world_grid_config.gd` | Everything a player can reach in a few seconds is loaded; nobody on a seam makes chunks thrash |
| Frame budget | 2 ms of attaching a frame | `world_grid_config.gd` | Sprinting across seams in four-way split-screen never stutters |
| Trails | 0 to 3 m rise from the holloway to the gorge, 3 to 6 m from the gorge to the Ring, 10 to 12 m wide | `landblock_manifest.gd` | Gentler than the 13° bridge ramps; wide enough for the party and a fight |
| Checkpoints | Inside the Moss-Oaks' south gap, the gorge's south cliff, the causeway | `landblock_manifest.gd` | Nobody walks back from the village after a wipe |
| Companions | Join once anyone walks out of the Forest Gate, leave when everyone's back in the village | `everwood_world.gd` | The village stays the family's own space |
| AI tick | Enemies think every tick within 35 m of a player, 10 times a second to 90 m, rest beyond; always full rate in a fight | `chunk_nav_builder.gd` | Far Hush-Cracks cost nothing until someone comes near |
| Recall | 5 s after the Cairnsman's chest opens, everyone is back on the green and the expedition resets (the village's state stays) | `everwood_world.gd` | One run, then home, as in the instanced expedition |

## The Trail of the Four Signs (11 GDD §5)

| Tier | Opens at | Damage and poise | Blade | Metal |
|---|---|---|---|---|
| 1 Apprentice Timber | Level 1 | 1.0x | hazel `#A67B5B`, hemp cord | 0 |
| 2 Hedgerow Iron | Level 2 | 1.2x | dark iron `#5A626A`, brass rivets | 0.55 |
| 3 Bramble-Bridge Steel | Level 5 | 1.45x | milled steel `#C4CED4`, brass bell-guard | 0.80 |
| 4 Doverslap Relic | Level 10 | 1.75x | gilded bronze `#E5C158`, glowing Sign-stone | 0.90 |

Each tier multiplies its classic weapon's numbers above (the classics are Tier 3 looks with 1.0x numbers, open from Level 5). The Bramble-Spun Jerkin, everyone's Level 1 armor, is medium: 15% mitigation, 24 stamina a second, 4.8 m rolls, 220 ms Perfect Guard.

**XP:** a mob 35, the Gorge gate 80, a boss 200. Levels at 0, 70, 105, 230, 320, 560, 700, 800, 850 and 1050 XP: one expedition (525 XP) reaches Level 5 at the Gatehouse, the second reaches Level 10 at the Cairnsman.

**Un-Inked Martial Flourishes** (R 1 pip, L+R 3 pips, no card): damage as a multiple of the weapon's Heavy and flat poise (times the tier):

| Weapon | R | L+R |
|---|---|---|
| Falchion | Timber-Cross Slash: 1.6x, 15 poise, 1.8 m lunge | Bramble-Whirl Flurry: 2.8x, 30 poise, 3.2 m around you |
| Broad-Axe | Coppice-Splitter Slam: 1.8x, 28 poise, 2.2 m ring | Heartwood Sundering: 3.15x, 56 poise, 3.5 m around you |
| Way-Staff | Reed-Sweep Gust: 1.4x, 10 poise, 3 m arc, mends the most hurt ally in 8 m for 10 | Lantern-Keeper's Chime: 2.45x, 20 poise, 4 m, mends 25 |
| Longbow | Vaulting Bough-Shot: 1.7x, 20 poise, piercing, steps back 1.5 m | Hail of the Hedgerow: 2.98x, 40 poise, a wide piercing shot |

A Tier 1 Falchion's Timber-Cross Slash hits for 29, Gale Rush for 22: a flourish is a strong first R, and a card adds a Sign rather than raw damage.

**The kinetic loop:** steps of 0.6 m (Light), 1.2 m (Heavy) and 2.8 m (Forward+Heavy) for melee swings without a lunge of their own; Back+Heavy hops back at least 2.4 m. The third Light in a row is winded for 550 ms; the Flow-Link window is the first 220 ms of a Light's recovery, and a pulse refunds 8 stamina and 0.15 pip. Hit-stop: 50 ms Light, 100 ms Heavy or flourish, 140 ms inked card, 180 ms detonation.

**Braced Front Guard:** 3 frontal hits in 4 s; 5 s braced; front hits 30% damage and half poise (a Shield-Sworn's Iron-Root strike, or a +Tank's, 2x poise); a Flank Breach 1.35x and +20 poise; a 2.5 m shield-shove at 1.8 s, 8 damage and 3 m back.

## Open questions for playtest

- Should taunt cost 1 pip, or should the tank's Perfect Guard pip already be enough?
- Is a companion tank that always lands Perfect Guards too strong next to a child playing tank? (Raise `PERFECT_GUARD_LEAD` past 0.2 s to make it guard early and take chip damage.)
- Is about 40 Chimes a run the right pace? Maxing both upgrades takes about 3 runs; with the Hush-Cracks and the Wayfarer's Chest that may now be too fast.
- With armor mitigation on every hit, is the Cairnsman now too gentle? Its damage could rise 15–20% to make up for it.
- Does a Rare card at Lv 2 (memory 7 of 8, no room for a link) feel like a real choice, or should Lv 2 hold 9?
- Does the Gale-Beam's 3.2 s give a child at tank, in Adventurer or Master mode, enough time to turn and raise Shadow Sanctuary? (Squire Gambit now does it for them.)
- Is the Gale-Jet's push fun for younger players, or should it slow (not shove) them?
- Do two Hush-Cracks feel like enough fighting before the boss, or should Rush-Light-Hollow hold a third?
- Do woodland kin bracing after three frontal hits slow the trail down too much for a party of small children? `BRACED_GUARD_HIT_THRESHOLD` could rise for them only.
- Is Level 5 at the Gatehouse right, or should the Tier 3 weapon and the L+R card come before the second Hush-Crack?
- Is the winded third Light felt as "weave in a heavy" or just as lag? 550 ms may want to be 450.
- In the seamless world, is the walk from the village to the Ring (about 350 m) a pleasant journey or a chore? The trails could be shorter, or a checkpoint could let the party skip back to the gorge.
- In Oakshire Vale, do the Curious Weald-Wights (parley or fight) give small children a gentle first meeting, or do the Padfoot Boggarts' 10 m waking radius catch them on the roads?
- Is a 120-frame Hearth-Rite Tuck (2 s, up from 1.5 s) too long for a four-year-old to hold?
- With no navigation mesh in Oakshire yet, do creatures and companions snag on trees and boulders too often when they walk straight at you?

## The Lantern's Promise & the First-Quiet Bestiary (15 GDD §4, §6)

| What | Number | Where | Why |
|---|---|---|---|
| Hearth-Rite Tuck | Hold R or L+R `120 frames` (`80` on a Star-Inked Vellum leaf) out of combat; `0` pips | `sign_flow_component.gd` | A free, calm pre-fight beat |
| Tuck empowerments | `60.0` poise (*Shatterpoint*) / `60.0` burst (*Glacial Rupture*) / `30.0` heal (*Dawnburst*) / `+40.0` stamina and `+1.0` pip (*Astral Chorus*) on the opening strike, by the leaf's Sign | 15 GDD §4 (spec) | One strong opening, never a stockpile |
| Flow-Link Window | `9f` Dread-Chill (alone) / `14f` baseline / `18f` The Lantern's Promise (within `5.5m` of a Lantern-Bearer) | `sign_flow_component.gd` | Staying together is easier than going alone |
| Cairn-Drake Challenge-Roar | `45 frames` (`0.75s`), no blow during it | `hob_spectrum_component.gd`, `wild_mob.gd` | A readable cue before a big foe's first swing |
| Bravery Counter | `(60.0 + 45.0) × M(L)` = `105.0` posture at Lv 1 (`1.33x` at the Cairnsman's Lv 5) | `glimmer_spot_component.gd` | Rewards answering the roar, not mashing |
| Truce-Sign parley | Within `6.0m`, a `180-frame` window; `+25` Chimes, `+1.0` pip | `hob_spectrum_component.gd` | Greeting a curious hob is worth as much as a fight |
| Furrow Iron-Man | `50%` mitigation on un-tucked weapon strikes (spec); Maker-Seal opens on a Warm-Hearth strike for `6.0s`, turns `180°` on an Iron-Root strike | 15 GDD §4.3; `hob_spectrum_component.gd` | Two Signs, two players, one puzzle |
| Steward helper | `600.0s` (`10 minutes`) bowed and friendly | `hob_spectrum_component.gd` | Long enough to feel like a friend |
| Lulled cairn (mobs) | Stays `30.0s`; a boss's stays for good | `hob_spectrum_component.gd` | A mob's spawner grows a fresh spirit later |

Today's Oakshire Iron-Men keep their Phase 11 mitigation (20–30%); the 50% un-tucked penalty and the per-Sign Tuck empowerments are Pass 2 tuning (15 GDD §7).
