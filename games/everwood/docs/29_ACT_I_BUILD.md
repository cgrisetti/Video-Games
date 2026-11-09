# 29 · Act I, The Fading Margin: the build (Q01 to Q05)

> **Asked for (2026-11-09):** the engineering brief "Engineering Act I Quests, Locations, Enemies & NPCs (`Z1_EMB` Embershore)", pasted with the updated *Everwood Narrative & Design Bible* (Google Doc `1QyJqg9plie4SDhuepEH3ZLWFSIwZAXAACCtlwtEVJog`: Embershore as `Z1_EMB`, Lee-Shore Orchards as the Level 1 spawn, a 14-level spine). The script it builds is [docs/28](28_ACT_I_THE_FADING_MARGIN_SCRIPT_PACKAGE.md).
> **The Creative Director's three calls (2026-11-09):** (1) the Bible's **14-level curve**, (2) Act I **fitted to today's Embershore** (no terrain change), (3) the **Lens names** on screen for the brief's three foes that fail Gate 3.
> **Branch:** `everwood/act-one-quests`. GDScript only (the brief's "C# / GDScript hybrid" isn't this project: docs/03 and `CLAUDE.md` are strictly typed GDScript).

---

## 1. What you can do now

Start a New Game. You wake on the lane at **Lee-Shore Orchards**' south gate, over the stone bridge from Bramblebridge. The quest tracker on the right of your screen says what to do next.

1. **Q01, Lee-Shore Awakening.** Speak to Master Alf-Wright at the orchard gate (light, line by line). He gives you the Calming Seal. Wear down the Un-Inked Bramble-Hounds on the orchard's grey edge until one wavers, then walk up and press light to **calm** it: a watercolour ring blooms, your Ink-Well fills, the count goes up. Burn one to nothing instead and it only **scatters** (2 Chimes, no count). Calm six, walk home to Bramblebridge green: **THE GREEN IS LIT**, Level 2.
2. **Q02, The Blighted Cider-Boughs.** Nokes and Tenar-Moss argue at the orchard gate. Four groves' Grey-Bark Weevils go for the oldest tree in each; calm every weevil while the tree stands (a tree gnawed grey starts its grove again). Then pour 3 Ink-Drops per hero into each Root-Shrine: *Ael-Voran*, the grove blooms, 3 Living Cider-Resin. Bring the resin to Alf-Wright's bench in the wright's yard: Make Ink Cards opens, and the Breaching Seal. Level 3.
3. **Q03, The Silent Mill & The Furrow Iron-Man.** The mill-wheel stops. Calm the five Ash-Grigs in Hob's granary. Miller Hob stands grey and speaks flat. On the stone bridge, the Furrow Iron-Man: a **Stag Hunt**. Burn him down and he scatters for 25 Chimes, and the Rusted Iron-Man rises there 10 minutes later. Or wear down his posture until he **kneels**; the Lantern-Bearer presses light at his seal for the **Amber Chime** (HOLD BLADES!: his health locks, his dots glow amber); then everyone presses light at his seal for **Deep-Ink** (2 drops each) before the beats run out. His seal turns upright, he wakes, the bridge is mended, +10% speed for 15 minutes, and he gives you the Warmth-Ember. Press light at Hob's hearth (Hearth-Warmth, 2 drops): the colour floods back and he remembers his daughter. Level 4: the R card opens beside the weapon Seal.
4. **Q04, Six Shall Turn It Back.** Ring the tide-bell on North Quay's pier: the sea falls 6 m in 20 s and stays out 4 minutes. Hold the Old Quay against three waves of Barnacle Scuttlers and Tide-Wights (their cold breath slows you). Read the plaque, ring the sea-lock bells **deep, then warm, then bright**, on time (wrong or late, the chain clangs back). The vault opens: the Bronze Carillon Tongue. The Tidal Horologium appears near the quays. Level 5.
5. **Q05, The Root-Sanctum & The Star in the Cake.** Gather in the ring at the Elder Oak's roots and the party goes down together into the **Root-Sanctum**: the Sap-Gallery, the Two Valves (both calmed within 3 s), the Taproot Hall's Root-Lurkers, then the **Blighted Taproot Stag**. Its health stops at a tenth while a chain holds. Each kneel, a heavy on the glowing chain breaks it (one two-handed Breaching heavy, three one-handed). After two chains the **Forging Fog** padlocks cards; the Hearth-Brazier's **Hearth-Ward** clears it. After four, every hero pours 3 drops for the **Naming**: ELDERHART. Out by the weir, the wheel turns, the causeways open. Take a slice of the Great Cake on the green: the **Fay-Star Seal**. Level 6 at 3,800 XP.

---

## 2. The three calls, and what they changed

### 2.1 The Bible's 14-level curve

| | Before | Now |
| :-- | :-- | :-- |
| `PartyProgress.LEVEL_XP` | 20 levels, Lv 6 at 560 XP, Lv 20 at 5,800 | 14 levels: 0, 400, 900, 1,600, 2,500, **3,800 (Lv 6)**, 5,400, 7,400, 9,800, 12,600, 16,000, 20,000, 24,800, 27,650 (Lv 14) |
| XP cap | `LEVEL_XP.back()` | `XP_CEILING` 30,500 (Q14 caps the spine; Level 14 stays) |
| `MAX_CHARACTER_LEVEL` | 20 | 14 |
| Slots (`GrimoireRules`, R4) | weapon Seal 3, R 4, offhand Seal + L 6, mantle Seal + Tuck 11, L+R 17 | weapon Seal 3, R 4, offhand Seal + L 6, **mantle Seal + Tuck 10, L+R 13** |
| Stages (`PlayerLoadoutResource`) | 1-5, 6-10, 11-16, 17-20 | 1-5, 6-9, 10-12, 13-14 |
| Gear tiers' levels | 1-4, 5-7, 8-10, 11-13, 14-16, 17-19, 20 | 1-3, 4-5, 6-7, 8-9, 10-11, 12-13, 14 |
| Renown / Threat bands | 1-7 ... 38-40 (two a level, 1-40) | 1-6 ... 27-28 (two a level, 1-28) |
| The Crown | Lv 15-20, its kin 15-18, the World-Tree 18-19, the galleries 20 | Lv 13-14 (Act III), its kin 13-14, the World-Tree and galleries 14 |
| Old saves | | Read once on the old curve and moved onto the spine at the level they had reached (`PartyProgress.xp_on_spine`, capped at 14); the save then carries `[trail] curve="bible14"`. The family's tale keeps its heroes' levels. |

**How quests pay.** A quest's ledger XP is its whole budget. Calms during it pay their own 35 XP as before. Handing it in tops the party up to the quest's cumulative XP (`QuestManager.hand_in_xp`), or pays a quarter of its XP if the party is already past it. So finishing Q01 is Level 2 and finishing Q05 is Level 6 with exactly 3,800 XP, however many foes were calmed. (The question offered "calm XP about 7 times larger"; with quests carrying the curve that would have run the party far ahead of the story, so calm XP stays at 35. See §10.)

### 2.2 Act I fitted to today's Embershore

The brief's places are ids; each is pinned to real ground (`ActOnePlaces`, Embershore's local frame). The Bible's heights are kept as metadata beside the real ones.

| Brief id | Where on Embershore | Real ground | Bible |
| :-- | :-- | :-- | :-- |
| `POI_LeeShoreOrchards` | the orchard north of Bramblebridge's stone bridge (was "The Heirloom Orchards"); the spawn is its south gate on the lane (-584, 182) | 6 to 18.5 m | Lv 1 spawn |
| `POI_HearthsteadMarket` | **Bramblebridge green** (Embershore's Hearthstead is the Lv 5 town, 900 m east); the Atelier bench is the wright's yard next door | 15 to 18 m | |
| `POI_AppleOrchards` (+4 tiers) | the same orchard's four groves: Root (-770, 148), Leaf (-505, 178), Flower (-604, 73), Seed (-705, 5) | 5.7 to 18.5 m | +15 / +25 / +35 / +45 m |
| `POI_OldWatermill` | Bramblebridge's watermill (-512, 259) | 12 m | |
| `POI_NorthQuayBridge` | Bramblebridge's **stone bridge** (-589, 213), 90 m from the mill | 6.5 m | |
| `POI_NorthQuay` | North Quay's pier (37.6, 1.6, -247) | the deck at 1.6 m | +0 m |
| `POI_OldQuay_EbbShelf` | the Old Quay platform (x 17 to 61, z -263 to -242) | -4.5 m | -6 m shelf |
| `POI_Dungeon_RootSanctum` | carved under the **Elder Oak** (the Bible's "Great Oak of Hearthstead"), door at (-147, 234) | floor -12 m | |

### 2.3 The Lens names

`ash_gremlin` reads **Ash-Grig**, `tide_wraith` **Tide-Wight**, `sap_elemental` **Sap-Boggart**. The brief's ids stay in code so the Bible still lines up.

---

## 3. Pillar 1: the quest state machine and ledger

| Piece | File | What it does |
| :-- | :-- | :-- |
| `QuestStepResource` | `src/quests/quest_step_resource.gd` | One step: REACH_PLACE, TALK_TO, CALM, EVENT, BOSS_OUTCOME, NPC_RESTORED or ITEM, a target id, a count, its on-screen words, its place, and what it grants when done. |
| `QuestDefinition` | `src/quests/quest_definition.gd` | A quest: id, title, zone `Z1_EMB`, levels, ledger XP and cumulative XP, its literary counsel, steps, unlocks. |
| `ActOneQuests` | `src/quests/act_one_quests.gd` | Q01 to Q05 as data (21 steps), the cast, boss, event, item and unlock ids, and the Bible's whole Master Quest Ledger (Q01 to Q14) as numbers, so the curve can be checked against it. |
| `QuestManager` | `src/quests/quest_manager.gd` (autoload **`Quests`**) | Plays the ledger: one quest at a time, step by step, from `report(kind, target)`. The host decides; a client's report goes to the host by RPC. Pays the hand-in XP, grants unlocks, starts the next quest, keeps world marks and the Stag Hunt log. |

**Server-authoritative sync.** The ledger lives in `PartyProgress` (`quest_log`, `unlocks`, `items`, `stag_hunts`), so it is saved in the party's save (`[quests]`), shared with every peer in the host's progress snapshot, and never written in a playtest. A client's `QuestManager` reads the host's copy.

**The steps, as built:**

| Quest | Steps |
| :-- | :-- |
| Q01 | wake in Lee-Shore Orchards · speak to Alf-Wright (grants StarterWeapon, Card_CalmingSeal, CardFuelReservoir) · calm 6 `bramble_hound` · reach Bramblebridge green (grants AudioStem_SoloBassoon) |
| Q02 | speak to Tenar-Moss at the gate · 4 `grove_cleared` · 4 `shrine_lit` (each gives 3 Item_LivingCiderResin) · speak to Alf-Wright at his bench (grants System_ScribeCrafting, Card_BreachingSeal) |
| Q03 | calm 5 `ash_gremlin` · speak to Miller Hob · reach the stone bridge · Boss_FurrowIronMan calmed (the Stag) · Hob restored · *unlocks DualActiveSealSlot, Card_HearthWarmth* |
| Q04 | `tide_ebb` · `ebb_waves_held` · `bell_chain_rung` · carry Relic_BronzeCarillonTongue · *unlocks HUD_TidalHorologium* |
| Q05 | `sanctum_entered` · 3 `chamber_cleared` · Boss_BlightedTaprootStag calmed · `feast_complete` · *unlocks Card_FayStarSeal, Causeways_Open* |

---

## 4. Pillar 2: places, elevation and the tide

- **`ActOnePlaces`** (`src/quests/act_one_places.gd`): the POI registry above, each with its centre, reach, real ground band and the Bible's elevation; `contains(place, spot)` and `places_at(spot)`.
- **`ActOneDirector`** (`src/quests/act_one_director.gd`), built into Embershore by `EmbershoreBuilder.build_structures`: checks where the heroes stand four times a second and reports the places; builds and gates everything below from the shared ledger on every peer.
- **The timed Ebb-Tide** (the brief's `GlobalTidalClock`) is in `CalderaWorldState`: `start_ebb_window()` falls the sea 0 to -6 m over 20 s, holds it 240 s, floods it back over 30 s (`Tide` HIGH / EBBING / EBB / FLOODING, `tide_changed`, `tide_dial_text()`). It is never saved, and the Harmonic Bell's permanent ebb (`ebb_unlocked`, Lv 14 now) still wins. Peers joining mid-window are told where it stands.
- **The stone bridge** shows rubble on its parapets until the Iron-Man is calmed (it stays passable: the orchards and Q01 are across it). The Rusted Iron-Man blocks it after a scatter until he is calmed.
- **The Root-Sanctum** (`src/quests/root_sanctum.gd`) is carved under the Elder Oak like The Crown's Sap Galleries, not a separate instance: three rooms at -12 m (ground above is 7.8 m or more), a `PartyThreshold` ring at the door the whole party steps into together, and one in the hall that takes them out by the weir. The old Cairnsman expedition no longer hangs on the door; it stays reachable with `--instance=expedition`.

---

## 5. Pillar 3: foes, the calming hook and the bosses

**The Act I kin** (`Bestiary`, family `EMBERSHORE_ACT_ONE`, twelve): Un-Inked Bramble-Hound, Grey-Bark Weevil (and its Great-Boggart), Ash-Grig, Barnacle Scuttler, Tide-Wight, Sap-Boggart (and its Great-Boggart), Root-Lurker, the Furrow Iron-Man, the Rusted Iron-Man, the Blighted Taproot Stag. New `MobVariantResource` fields: `calm_rule`, `scatter_chimes`, `targets_trees` (weevils walk to and gnaw the grove's tree, `OrchardTree`), `stamina_slow` (a Tide-Wight's blow slows the hero and drains 20 stamina).

**The calming hook** (`CalmingComponent`, `src/quests/calming_component.gd`) on every Act I kin:

- It **wavers** under a quarter of its health or while its posture is broken.
- A hero within reach then sees **light: CALM** and presses light: `calm_entity()` plays the Recovery burst (`RecoveryBurst`) on every peer, reports the calm to the quests, and downs the foe; `CombatDirector` pays the calm as it always has (Ink-Drops +1 / +2 / +3 to the wells nearby, XP, Ink-Binding Marks).
- Burnt to nothing instead, `CombatDirector._on_enemy_down` sees no calm and only **scatters** it (`on_scattered`: its `scatter_chimes`, no drops, no XP); its spawner grows it again.
- Why light, not the brief's "Seal card hit" or docs/28's "hold R": R's hold is the Sign-Flow's Hearth-Rite and only waits out of combat. Light near a wavering foe is a button every hero has, and the `Interactable` path already makes light "use" instead of swing.
- "Scaled by PlayerLevel and ClassMultiplier": the drops stay docs/25 R2's +1 / +2 / +3 (the CD's ruling); the well's depth already grows with the stage.

**The Stag Hunt** (`StagHuntEncounter`, `src/quests/stag_hunt_encounter.gd`) on the Furrow Iron-Man:

| | The Rabbit (defect) | The Stag (cooperate) |
| :-- | :-- | :-- |
| How | health to 0 | posture to 0: he kneels (8 s); the Lantern-Bearer (a seated Lantern-Bearer, else a companion Mender who rings by itself, else the hero with most drops) presses light at his seal: the **Amber Chime** locks his health (`StatsComponent.health_locked`), his dots glow amber; every hero within 9 m presses light for **Deep-Ink** (2 drops) inside the Metronome Pendulum's 5 beats (+2 for a Squire seat) |
| Pays | his `scatter_chimes` 25 | 15 Chimes |
| Then | logged −40 hazard, **−15** net; the **Rusted Iron-Man** (+40% damage, double posture) rises in 600 s | his seal turns upright, he bows as a steward; logged +120 World Buff, **+135** net; the bridge mended, heroes +10% stride for 900 s (`ActorBase.world_boon_speed`), the Warmth-Ember |
| Missed | | he stands with half his posture back; strokes already poured stay |

Health and posture scale with the heroes present when he's first engaged (40% for one hero up to all of it for five). Every outcome goes into `PartyProgress.stag_hunts`.

**The Taproot Stag** (`TaprootStagEncounter`, `src/quests/taproot_stag_encounter.gd`): health floor 10% while a chain holds (`StatsComponent.health_floor`); each kneel the next chain glows; a heavy (HEAVY, FORWARD_HEAVY, BACK_HEAVY) on it adds 6 with a two-handed weapon (the Mallet or the Staff) and the Breaching Seal, 2 one-handed with it, 1 without; it breaks at 6. Phase 1 root-spikes (red circle) and the Chain-Rattle Charge (gold soak); Phase 2 **Forging Fog** (`CardFog`: one or two of a hero's L / R / L+R sockets padlocked 15 s, 5 s for a Squire; a fogged socket won't play and reads padlocked on the HUD); the **Hearth-Brazier**'s Hearth-Ward (2 drops) clears everyone within 4 m and keeps them clear 6 s; Phase 3 Root-Lurkers; then the **Naming** (3 drops from every hero within 12 m, 5 beats), ELDERHART, calmed. Missed, it stands with 60% posture and the next break brings the Naming back.

---

## 6. Pillar 4: the townsfolk

`EverwoodNPC` (`src/quests/everwood_npc.gd`) is a `TownsfolkNPC` who speaks: light opens the talk box on that hero's screen (§7), which stays up until goodbye; hearing the last line reports TALK_TO. The gold "!" shows only while the step under way wants them. **Forged / Restored**: a Forged townsperson's colours are 85% grey with a grey mist at their feet, they speak flat, and a vendor's wares stay shut; `restore()` brings the colour back with a Recovery burst on every peer. The director stands each where the story needs them:

| Who | Where | Says (docs/28, by the step under way) |
| :-- | :-- | :-- |
| `NPC_AlfWright` | the orchard gate in Q01 and Q02, the wright's yard from Q02's bench, the green for the Feast | the Calming Seal, the bench and the Breaching Seal, the Iron-Man, the plaque, "It's borrowed, mind." |
| `NPC_ReeveNokes` | the orchard gate; the green at the Feast | the argument; "sensible management" |
| `NPC_DameTenarMoss` | the orchard gate | root, leaf, flower, seed; *Ael-Voran* |
| `NPC_MillerHob` | the mill door | Forged until Q03's hearth; then Wren |

---

## 7. On screen

The quest screens (`src/ui/quest/`) are built in the living storybook atelier look of the Binder (`AtelierTheme`, `BinderKit`: warm timber pages, a gilt edge, lime-wash ink) and sit over play with the world still in view. Every one scales to its player's split-screen cell. The words for an 8-year-old live in one place, `QuestKit`: each quest's story, who asked for it, what it gives in plain words ("Your R diamond", "The Calming Seal card"), and where the step is from the hero's point of view.

- **The talk box** (`TalkBox`): light on a townsperson opens it along the bottom of the view. Their portrait (a bust in their own colours, greyed while Forged, blinking, mouth moving as they talk) sits in a gilt medallion with their name on a plate; a green chip says when they're part of the quest under way. The words write themselves out (light finishes them at once) and **stay up**: nothing fades on a timer. Beside them: **Tell me more** (the next line; on the last one, **Say that again**, which starts over with whatever they have to say now), **What do I do?** (the step in one sentence, where it is, and the firefly trail lit toward it) and **Goodbye** (dodge too). A dot per line shows how far through you are. A two-hander shows the right face, name and title ("TENAR-MOSS: ..." beside Nokes reads Dame Tenar-Moss, Herbalist). The diamonds at the bottom step aside while the talk box or the quest book is open. The talk ends by itself if a fight starts or the hero is pulled more than 6 m away, and it never opens mid-fight.
- **The quest tracker** (`QuestTracker`, right of the view, under where a minimap would sit): QUEST 1 OF 5, the quest's name, the step with a painted mark for what it asks (a speech bubble to talk, a heart to calm, a flag to go, a crown for a big foe, a flame to help, a satchel to carry, a star for the rest), a pip per thing to do ("● ● ○ 2 of 3"), and **where**: an arrow that turns with the camera and "The Orchard Gate · 42 m · to your right", "close by", "You're here!" (green) or "On Embershore: sail home". A finished step flashes "Done!" in green with sparkles before the next one comes in. It watches the ledger, so it cheers on every peer. It stays up beside a talk and hides under the other menus. It's the one compass in the Caldera, which otherwise navigates by landmarks (no minimap).
- **The quest book** (`QuestBook`): **B**, or on a pad hold Share / View and tap D-Pad ↓, out of combat. One page down the left of the view: Act I's five quests with their seals (a green tick done, a gold star under way, "?" and "A quest to come" for the rest), and the chosen quest's story, who asked, its steps (done ones ticked, the one under way lit with its count and where it is, the rest "More to discover..."), and what it gives (+XP, the level, every new thing). **Show me the way** lights the firefly trail to the step and closes the book so the hero can follow ("FOLLOW THE FIREFLIES").
- **QUEST COMPLETE!** (`QuestCompleteCard`): a gilt card springs down over the top of the view, a red wax seal stamps a gold star on it, sparkles burst, and it says what the quest gave and what's next ("Next: The Blighted Cider-Boughs. Hear out Reeve Nokes and Dame Tenar-Moss at the orchard gate."). It never takes the controls and fades after 6.5 s. A banner already up waits under it, apart from a level's (the card says the level), and banners that arrive while it's up (the next quest's) follow it one after another.
- **The Tidal Horologium** under the tracker, within 300 m of North Quay once Q04 is under way or done: "EBB-TIDE · the flood in 3:12".
- Banners for every quest start, unlock and Stag Hunt beat (HE KNEELS!, HOLD BLADES!, THE IRON-MAN WAKES, FORGING FOG, THE NAMING).
- Words follow Gate 6: Ink-Drops, calm, scatter. Never "kill", "pips" or "Scrap" on screen.

---

## 8. The checks

`tools/test_quest_ui.gd` runs first inside it (8 checks): the tracker's quest, step and where; the talk box opening on Alf-Wright, its words still up 9 s later, light finishing the writing, What do I do? lighting the trail, the last line counting for the quest with the tracker's "Done!", and Goodbye; a two-hander's speaker; the quest book's seals, story, steps, gifts, a surprise for the next quest, Show me the way and B; and QUEST COMPLETE! with what's next, the next banner waiting for it, and "You're here!". Then it resets the ledger for the quest checks.

`tools/test_act_one.gd` runs inside the Caldera checks (so in the smoke test and `tools/run_caldera_checks.gd`) right after Embershore's: 22 checks over the ledger and curve, the places, the kin, the world built, then the whole Level 1 to 6 loop on the live isle with a Level 1 party (each quest's real pieces: the calm and the scatter, a felled grove, a shrine waiting for every hero's drops, both Stag Hunt paths and a missed kneel, the tide window, bells out of order and late, a valve calmed alone, the Stag's floor, chains, fog and ward, the Naming, out by the weir, the cake), ending at Level 6 with exactly 3,800 XP, then saving round-trips and an old-curve save keeping its levels. The 14-level curve also updated four older checks (the curve itself, the gear bands, Renown, stages and slots).

---

## 9. The brief, mapped

| The brief says | The build |
| :-- | :-- |
| `Z1_OAK` / Oakshire Holm | `Z1_EMB` / Embershore everywhere new; `ISLE_OAKSHIRE_HOLM` stays an alias of `ISLE_EMBERSHORE` (saves and tools use it) |
| C# / GDScript hybrid | GDScript only |
| Custom Resources | `QuestDefinition`, `QuestStepResource` (built in code, as the project builds its catalogs) |
| `BlightedEnemyStats` | `MobVariantResource` with the Act I fields; `BlightedCreatureEntity` is `WildMob` + `CalmingComponent` |
| `CalmEntity()` / `KillEntity()` | `CalmingComponent.calm_entity()` / `on_scattered()` (nothing is slain: Gate 3) |
| Card Fuel pips | Ink-Drops (docs/25 R1, R2) |
| Scrap | Chimes |
| `StagHuntEncounterController` | `StagHuntEncounter` |
| `SubTarget_RustedChain` hitboxes | four chain strengths on `TaprootStagEncounter`, struck by heavies on the kneeling Stag |
| `Debuff_ForgingFog` | `CardFog` |
| `Card_HearthWard` | the Hearth-Brazier's Hearth-Ward (see §10) |
| `GlobalTidalClock` | `CalderaWorldState`'s timed window |
| `HUD_TidalHorologium` | the HUD's tide line |
| `EverwoodNPC` ForgedState / RestoredState | `EverwoodNPC.NpcState.FORGED` / `RESTORED` |
| Dual Active/Seal Card Slot (Lv 4) | the R socket at Lv 4 beside the Lv 3 weapon Seal (docs/28 §5.8) |

---

## 10. Not built yet, and calls for Clay

**Built as a first pass (works, checked, but thin):**
- No cutscenes: the intro, Nokes cracking the seal and the Feast are banners, not staged scenes.
- The Flicker-Wick bassoon is a banner and a bell: the `flicker_wick` mosaic cell (docs/28 §3.6) isn't composed.
- Telegraphs: the Iron-Man fights with his plain blow; the Taproot Stag has root-spikes and the soak, not the Antler Sweep, the Fog Breath cone, the fog banks or the shrinking ring.
- Packs and clutches don't grow with more heroes yet (every peer must grow the same pack); the bosses do scale.
- The Rusted Iron-Man's 10-minute timer and the World Buff aren't saved: quitting resets them.
- The Iron-Man's steward walks for docs/15's 600 s, not the buff's 900 s.
- No quest log screen: the tracker and the map only.

**Calls, each with the default the build uses:**
1. **Calm XP.** Stays 35 (the hand-in tops each quest up to the curve). Q02's 18 weevils pay more than Q02's budget, so the hand-in there is a quarter. *Default: keep 35; tune in 04_BALANCE.*
2. **Light to calm**, not "hold R" (docs/28) or a Seal-card hit (the brief). *Default: light.*
3. **Hearth-Ward** is the Hearth-Brazier's (anyone, 2 drops), not yet the Lantern-Bearer's R card. *Default: the brazier, until the card exists.*
4. **The Breaching Seal, Hearth-Warmth and the Fay-Star Seal** are party unlocks, not card resources in the Binder yet; the Breaching Seal counts for every hero once Q02 grants it. *Default: unlocks now, cards in a Binder pass.*
5. **Finish level gates and resin feeding Marks** (docs/28 §9 calls 13 and 14) aren't built. *Default: leave R3 as it is.*
6. **The stone bridge stays passable** while damaged (Q01's orchard is across it). *Default: rubble only.*
7. **Mob XP outside quests and the legacy trail.** The old Bramble-Bridge expedition now reaches only about Level 2 on the new curve. *Default: leave it; it's deprecated.*
8. **The Crown at Lv 13-14** moved its labels and kin levels; its trials' numbers weren't re-tuned. *Default: re-tune with Act III.*
9. **Steward Threat** is still level plus weapon rank (1 to 40); at Lv 14 it tops out at 34 while Renown tops out at 28. *Default: leave both.*
10. **Old-curve saves** move to the same level on the spine (an old Lv 6 is Lv 6 at 3,800 XP). *Default: keep the level, not the XP number.*

docs/28 §9's calls 1 (Embershore), 2 (Q01 ends on the green), 3 (four groves), 7 (the curve) and 15 (Gate 3 names) are settled by the three calls above; 4 (Bramblebridge's bridge), 5 (the wheel at Q03), 6 (a timed ebb), 9 (Ink-Drops), 10 (Chimes), 12 (the pair) are built on their defaults.
