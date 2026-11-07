# 22_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md — The Ink-Well, the Seven-Card Hand, Per-Hero Levels and the Atelier Menus

Sources, in order of authority:
1. **Creative Director rulings, 2026-11-06** (pasted into the session that built
   this phase): the Ink-Well, finishes, unlock levels, the linter renames, the
   Pommel-Knot, one card per slot, and the rename of Oakshire Holm to Miller's Oak.
2. **The Everwood Menu Wireframes canvas** (claude.ai artifact
   `Xaf8pLmrXYP95zSQe6hy2P`): nine boards (HUD, Options, Binder tabs 1 to 3,
   the Seal Press, the Scribe Desk and Forge, the pre-raid loadout) with the
   rulings applied.
3. **The Google Doc *Everwood Equipment & Grimoire Architecture***
   (id `1YjX1R2My3dTVc0IgZoR5e3I5VOup84hdUUPXl9aeP0s`): the 7 tiers and their
   numbers, the Contextual Slot Rule for Seals, Steward Threat, the 7-card hand,
   Tucks, the four stages.
4. **The Google Doc *17_WORLD_VISUAL_AND_AESTHETIC_ARCHITECTURE*** (id
   `1f9u-4PQUZUQbYhGzsfbvzf7csiagURy94SU5SJIRfjY`): the living storybook atelier
   palette and the draw-distance rings the Options menu now names.

It builds on two branches that were never merged: the Seal-and-Tuck Grimoire
(`claude/everwood-equipment-grimoire-0f1c06`) and the stamping bench
(`claude/unruffled-murdock-55037a`). Both are merged first, then evolved; nothing
they built is thrown away without a reason written below.

## 1. The rulings, as rules the code enforces

| # | Rule | Where it lives |
|---|---|---|
| R1 | **Ink-Well.** Cards spend Ink-Drops, never cooldowns and never Grimoire Memory. A basic L or R card costs 1, a mid-tier card or any card with its Tuck 2, the L+R Grand card 3. The well holds 4 / 6 / 8 / 10 drops at Stages 1 to 4, plus 1 / 1 / 2 / 2 for Wise Hand. Swings never fill it. | `InkWellRules` (static), `StatsComponent` ink, `SignFlowComponent` costs |
| R2 | **Refills.** Calming a foe +1 (a Rare +2), a Great-Boggart (elite or boss) +3; a boss stagger, a cracked gate or a PARRY & STRIKE! on a boss roar +2 to every hero within reach; a Hearth-Brazier fills the well; a Star-Tide Astral Chorus or a tether gifts +1. | `CombatDirector` hooks, `HearthCampfire` |
| R3 | **Finishes.** Each card copy carries Ink-Binding Marks. Calming foes while it is worn adds Marks; feeding a spare copy adds 100. At 100 it is *Ready to Press* (Gilded Leaf, +15%); at 250 (Star-Ink, +30% and the presser's Maker-Seal). Pressing happens at the Scribery's Gilding Press or with a Wise Hand Scribe Kit at a Hearth-Brazier. Calming an Elite or Boss drops its card as Gilded Leaf 10% of the time; Star-Ink never drops. Three rubbings draft a missing Plain Ink card at the Scribe Desk. Any finish trades at a Hearth-Brazier or the Scribe Desk. | `PartyProgress` collection, `ScribeCardResource` finishes |
| R4 | **Slots unlock by Character Level:** weapon Seal 3, R card 4, offhand Seal and L card 6, mantle Seal and the Tuck 11, L+R 17. The socket is drawn from Lv 1 (dashed, padlocked) so the Cross never changes shape. The host checks every hand. | `PlayerLoadoutResource.SLOT_OPEN_LEVELS` |
| R5 | **Seven slots, seven different cards.** 3 Seals + L + R + L+R + 1 Tuck, at most one equipped copy of a title. Pressing a card that is already worn elsewhere moves it. | `PlayerLoadoutResource.duplicate_titles()`, the host's check |
| R6 | **Pommel-Knot.** Two-handed mauls and greataxes seal their pommel; it guards like a buckler. Every weapon has three Seals. | `EquipmentTierResource.offhand_name()` |
| R7 | **Words** (Gates 3 and 6): Defender / Striker / Mender (never Tank or DPS on screen), Armor Guard (not mitigation), Breath Recovery (not stamina regen), Marks (not AP), the Gold-Ring Flash (no frame counts on screen), Great-Boggart (not Elite), Heart-Crag Bulwark (not Aegis), Deep-Tide Roar (not Abyssal), "hills and woods" (not landblocks). | `tools/test_phase12_kaizen.gd` RETIRED_WORDS |
| R8 | **Place renames:** the Dover-Slap stem becomes **Doverslap** everywhere (Doverslap Bridge, Doverslap Falls, the Doverslap Gatehouse, the Doverslap Relic tier); Moss-Oak-Hollow becomes **Moss-Oak Hollow**; Oakshire Holm becomes **Miller's Oak**. Ids, file names, node names and save keys keep their old spellings, as every rename before this one did. | display strings and docs |

### 1.1 Amendments to the bible (Creative Director, 2026-11-06)

R8 breaks two of Gate 3's Linter Rules as written: "Doverslap" flattens a
hyphenated compound (Rule 3), "Moss-Oak Hollow" drops a hyphen, and "Miller's
Oak" has no Map-Sense noun (Rule 2) and carries an apostrophe. The Creative
Director chose them, so the bible records them as named exceptions and the
Lens linter carries the same list (`CD_NAME_EXCEPTIONS`). Every other name still
answers to the four rules.

## 2. What the merged code already does, and what changes

| System | Merged state (Seal-and-Tuck + bench) | After this phase |
|---|---|---|
| **Level** | One party trail level, 1 to 10 (`PartyProgress.trail_level`), read as True Level; Renown Rank = Level × 2. | **Character Level per hero**, 1 to 20, kept per Fellowship like the hand. The party's old XP seeds every Fellowship once (nobody loses a level). **Steward Threat** = Character Level + the weapon's material rank (+0 to +20) replaces Renown on screen. |
| **Tiers** | Seven tiers from the local doc (Rime-Silver at 4, Cairn-Heart at 6). | The Google Doc's ladder: Orchard-Wood, Bog-Bronze, Forge-Iron, **Barrow-Steel**, Rime-Silver, Saffron-Gold, **Star-Glass & Heart-Crag**; bands 1–4, 5–7, 8–10, 11–13, 14–16, 17–19, 20; Light 2.4 to 36.0; ranks +0 to +20; Armor Guard per weight. The tier is no longer forced by level: it is **promoted** at the Forge once the level allows it. |
| **Hand** | 3 Seals + L, L tuck, R, R tuck; L+R is the two primaries together; opens by stage (Lv 3, 4, 6, 11, 16). | 3 Seals + **L, R, L+R** (each its own card) + **one Tuck** under any of them; opens at Lv 3, 4, 6, 11, 17; seven different cards. |
| **Active cards** | The diorama leaves (Binder tab 2) fire on L, R, L+R; the hand's L and R primaries ride the same press as a Pocket-Pull coat. | **One card per socket.** The hand's L, R and L+R *are* the socket leaves; the Pocket-Pull plays the leaf. The Forward and Back Heavy cards stay in the kit as the Fellowship's own stance moves (Combo Moves tab), no longer slotted by the player. |
| **Fuel** | Resonance pips, 3 max, earned per hit; R 1, L+R 3; Grimoire Memory caps rarity. | **Ink-Well** (R1, R2). Memory leaves the screen and the rules. |
| **Finishes** | Bought at the Gilding Press (50 / 120 Chimes, +10% / +20%). | Ink-Binding Marks, Ready to Press, then the press (R3). Gilding still costs nothing extra in Chimes [CD: confirm a Chime fee]. |
| **Menus** | Options (4 tabs), Binder (1 Gear, 2 Cards, 3 Combos, Atlas, 4 Seals & Pocket Cards), Scribe Desk rows, Scribery tabs, the Cross HUD with pips. | The wireframes: the Cross with ink beads and cost dots; Binder 1 Gear & Weapon (Threat formula, Seals and their Marks), Binder 2 the card bench (Place-Card, card, Tuck), Binder 3 Combo Moves by stage; the **Seal Press** (from tab 1 at a rest point; it replaces tab 4); the Scribe Desk & Forge; Options' new rows; the pre-raid loadout at the Quay Brazier. All drawn by one **Atelier** theme. |

## 3. The Atelier look (menus)

From the world doc's palette and the wireframes: dark timber ground `#120D09`,
page `#1E1711` / `#2A2018`, gilt edge `#D9B36B`, chosen-row gold `#F2D27A` on
`#3A2C1E`, lime-wash text `#F2ECE1`, muted `#C9BBA5`, dim `#A0917C`. The four
Signs keep their world-doc colours: Iron-Root `#D9822B`, Rime-Gale `#38A3D1`,
Warm-Hearth `#F2B749`, Star-Tide `#8C52D9` (text tints `#E9A257`, `#6CC3E8`,
`#F2C66A`, `#C4A3F5`). Ink-Drops are lavender beads `#B993F2`. One class,
`AtelierTheme` (`src/ui/atelier_theme.gd`), builds every page, tab, row, chip
and tooltip box so the Options menu, the Binder, the Seal Press, the Desk and
the raid board read as one book.

## 4. Increments (each check-only clean, then the smoke test)

| Step | What | Status |
|---|---|---|
| M0 | Merge the two Seal-and-Tuck branches onto main (after the Level 1 youth); fix the boot flag the youth retired. | done |
| M1 | R8 renames in strings and docs; the bible's amendment; the Lens linter's exceptions. (R7's words join the Gate 6 linter in M7, when the menus that print them change.) | done |
| M2 | Character Level per hero (1 to 20) and Steward Threat. | done |
| M3 | The Google Doc's 7-tier ladder; promotion at the Forge; the Pommel-Knot. | done |
| M4 | The seven-card hand: L, R, L+R and one Tuck; level unlocks; one card per slot; the hand's actives become the socket leaves. | |
| M5 | The Ink-Well: costs, well sizes, refills; pips and Memory retired. | |
| M6 | Finishes by Ink-Binding Marks and the press. | |
| M7 | The Atelier menus: the Cross, Binder 1 to 3, the Seal Press, the Desk & Forge, Options rows, the pre-raid loadout. | |
| M8 | Build notes, README, doc 03 and the doc index. | |

Status is kept in this table as each step lands, so a fresh session can pick
up from the first empty row. The work lives on the branch
`everwood/grimoire-overhaul` (worktree `.claude/worktrees/grimoire-overhaul`).

## 5. Build notes (as each increment lands)

**M2, per-hero levels.** `PartyProgress.hero_xp` keeps each Fellowship's XP; every
seated hero (never a companion) earns what the party earns. `character_level(class_id)`
reads 1 to 20; `trail_level()` stays the party's 1 to 10 and still paces the trail's
milestones and the foes' badges, so nothing on the Bramble-Bridge trail moved. The
hand's slots and the host's hand check read the hero's own level. A save from before
this phase seeds all three Fellowships with the party's XP. `steward_threat()` is
Character Level plus the weapon tier's rank. Levels 11 to 20 cost 1,300 to 5,800 XP
[tuning TBD: 04_BALANCE has no Stage 3 or 4 pacing yet].

**M3, the ladder.** The seven tiers now carry the Google Doc's names, bands, Light
and Heavy (as decimals, rounded per blow), ranks, Armor Guard by weight (an explicit
table, not a scale of one number), four arms and four offhands each (the maul seals a
Pommel-Knot: R6) and the recipe table. The Seal-and-Tuck branch's tier ids for 4 to 7
read back as the tier now at their place (`LEGACY_TIER_IDS`). `PartyProgress.promoted_tiers`
keeps each Fellowship's weapon tier and armour tier; `request_promotion` promotes one
step at the Forge when the hero's level opens it (host-checked). A live hero wears
its promoted tiers, capped by its level; the catalog's planning hands (a "Level 20
hero") still read the level's tier. Deliberate differences: no Chime cost yet
(`PROMOTE_CHIME_COST` is all 0, the docs give none); the "after the Rime-Firth
milestone" gate isn't wired (the level gate is); the trail's four weapon tiers
(Apprentice Timber to the Doverslap Relic) still set the combat numbers of the
Bramble-Bridge trail weapons, and folding them onto the ladder is the next step
after this phase.
