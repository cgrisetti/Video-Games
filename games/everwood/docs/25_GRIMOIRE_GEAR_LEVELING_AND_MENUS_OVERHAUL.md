# 25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md — The Ink-Well, the Seven-Card Hand, Per-Hero Levels and the Atelier Menus

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
| M4 | The seven-card hand: L, R, L+R and one Tuck; level unlocks; one card per slot; the hand's actives become the socket leaves. | done |
| M5 | The Ink-Well: costs, well sizes, refills; pips and Memory retired. | done |
| M6 | Finishes by Ink-Binding Marks and the press. | done |
| M7 | The Atelier menus: the Cross, Binder 1 to 3, the Seal Press, the Desk & Forge, Options rows, the pre-raid loadout. | done, but for the pre-raid loadout board and a tab 2 redraw (§5, M7) |
| M8 | Build notes, README, doc 03 and the doc index. | done |

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

**M4, the seven-card hand.** `GrimoireRules` (`src/resources/grimoire_rules.gd`) holds
the unlock levels, the costs and the well depths in one place. The hand's L, R and
L+R are the kit's socket leaves (`LoadoutComposer.socket_cards`); the four pocket
slots in `PlayerLoadoutResource` stay as fields so old saves read, but nothing opens
them (`slot_opens_text` says "is in the Cross now"). `LoadoutComposer.gated` clears what
the hero's level hasn't opened and keeps one Tuck from Lv 11. Every seal card carries
`slot_passives`, what it does on the weapon, the offhand and the mantle (the Contextual
Slot Rule), read through `ScribeCardResource.slot_passive`. Deliberate differences:
the Tuck goes under R or L+R only (the L card has no under-slot in the kit); the
Forward and Back Heavy cards stay in the kit as the Fellowship's stance moves.

**M5, the Ink-Well.** `CharacterStatsResource.ink_well` turns a hero onto drops:
hits fill nothing, `StatsComponent.add_ink` and `CombatDirector.refill_ink` pour
them back (a calm foe 1 or 2, a Great-Boggart 3, a boss's beat 2, a gift 1, a
Hearth-Brazier fills it), and `GrimoireRules.ink_cost` prices each socket.
Differences: Homing Heal costs 1 drop; the Astral Chorus gift still pays 0.5 pips
in the classic full kits.

**M6, finishes.** Worn cards earn Ink-Binding Marks near each calm foe
(`PartyProgress.award_ink_marks`); a copy with enough Marks is Ready to Press and
the Scribery presses it to the next finish for no Chimes [CD: confirm a Chime fee],
keeping its Marks and the presser's Maker-Seal. Calm foes leave rubbings; three
draft a Plain Ink copy of a missing card. Drop odds are the Google Doc's
(`VARIANT_ODDS`).

**M7, the Atelier menus.** `AtelierTheme` (`src/ui/atelier_theme.gd`) draws the
Options menu, the Binder and the Scribe Desk. The Cross HUD shows the Ink-Well's
beads, ink-dot costs, padlocked sockets with their level, the Tuck peeking under its
card, the Seal gems and the material tier I to VII. Options adds World detail
(camera reach as a share of each place's horizon), Grass & flowers (for ground
baked from then on), Craft textures (the mipmap bias), Damage numbers, Rhyme ribbon
size, the INK READY border, and each player's help for every seat on the screen.
Binder tab 1 shows Steward Threat as a sum, what the kit adds up to and each Seal's
Marks; light there opens the Seal Press at a rest point. Tab 4 is the **Seal Press**:
three Seal rows with their slot text and Marks, changed only at a Hearth-Brazier or
the Scribe Desk (anywhere in the classic full kits the older checks use). The Scribe
Desk drops its card and link rows for Promote weapon & offhand, Promote armour and
Draft a card. A chosen Seal hand now follows the Forge's promotions too. R7's words
joined the Gate 6 linter; the screen reads Great-Boggart, Bulwark, Armor Guard,
Breath Recovery, +Defender and +Striker (the ids and rank keys keep the old words).
Not built: the trade row (the family shares one binder, so it has nothing to do),
the pre-raid loadout board at the Quay Brazier, and a full card-bench redraw of
Binder tab 2 (its fit lines already carry the Tuck and one-card-one-place rules).

**M7b, the Binder rebuilt to the wireframes (2026-11-07).** The first pass kept the
old Binder layout and added text; Clay asked for the wireframes' layouts. The Binder
is now one 1600 x 900 sheet (the wireframes' own coordinates) scaled to the player's
cell: header, tabs, a two-part tooltip box (what's highlighted · what it does, when,
whether it fits) and the controls along the foot. Each page is its own class in
`src/ui/binder/`: `BinderGearPage` (hero and Threat sum, kit totals, Seal wards; the
live preview with Seal callouts; weapon, offhand and mantle rows with their Seal,
finish, maker and Marks), `BinderCardBench` (the Cross; the seven-slot hand and
Ink-Well; Place-Card, Ink card and Tuck layers; the collection with Cards / Tucks /
Place-Cards filters and a fit chip on every row) and `BinderSealPressPage` (the three
Seal tiles; the cards you can press with where each is now; the card slot by slot,
what you lose and gain, the Ink-Binding ladder; preview and Press). `BinderKit`
builds every box from `AtelierTheme`. Navigation follows the wireframes: on the
bench ← → diamond, ↑ ↓ layer, light opens the collection, light slots, dodge backs
out; in the Seal Press ← → piece, ↑ ↓ card, light presses, dodge returns to tab 1.
The Tuck slides under R or L+R (`slot_tuck`), never L. Not built from the wireframes:
the coat-dye swatches (no dye choice exists yet), turning the preview with the right
stick (it still turns on its own), and the Seal Press as a page reached only from tab 1
(it keeps its tab, look-only away from a rest point).


## 7. The Ink Card Deck (2026-11-07)

Workshopped on the "Everwood Ink Card Deck" page, then built for an eight-year-old
to understand at a glance. One attack and one defense card for each Sign:

| Sign | Attack: R, Ink Blade | Defense: L, Ink Shield |
|---|---|---|
| Iron-Root | **Cairn-Cleave** (Common): every third coated hit rings a big foe for SHATTERPOINT | **Hedge-Root Brace** (Common): the counter-brace roots the foe you just hit, 1.5 s |
| Rime-Gale | **Squall-Lash** (Uncommon): coated hits frost-slow 20% for 2 s; every fourth bursts in GLACIAL RUPTURE | **Hoarfrost Mantle** (Common): no slow takes hold; the counter-brace's 4 m frost ring slows foes 40% for 3 s |
| Warm-Hearth | **Ember-Wick Cut** (Common, the starting card): an Ember-Burn stacks +18% stagger a hit, up to 3; the cut rings for DAWNBURST | **Kindle-Hearth Ward** (Uncommon): friends within 3 m behind you mend 1.5% a second; the counter-brace sets off DAWNBURST |
| Star-Tide | **Tide-Turn Thrust** (Uncommon): 6 Breath back a coated hit; the thrust rings for ASTRAL CHORUS | **Moon-Weir Guard** (Common): a Perfect Guard under the shield pours 1 Ink-Drop (once in 4 s); the counter-brace gives friends behind you 15 Breath |

Every shield soaks 70% of its own Sign's blows from bosses, shrugs stuns and shoves,
and lasts the coat's 8 s. **Where they come from:** Ember-Wick Cut is in every binder
from the start; the Commons are inscribed at the Scribery (25 Chimes); none are in the
boss chest (its seeded drops stay as they were); a calmed foe may leave a deck card of its isle's Sign the party hasn't found
(`PartyProgress.roll_deck_find`: 20% from a calm foe, 60% a rare, always a Great-Boggart),
and "A NEW CARD!" (`CardReveal`) springs up on every player's screen.

**Build.** `ScribeCardResource` gained `twist`, `art_motif`, `kid_text`, `flavor_text`,
`flavor_by` and `found_text`. `CardTwists` (`src/combat/card_twists.gd`) holds every
twist's rule and number; `SignFlowComponent` calls it on a coated hit, on the
counter-brace, each frame a shield is up and on a Perfect Guard. Slows ride the strike
(`CombatEvent.slow_fraction`, `slow_seconds`; `CombatDirector.slow_foe`) so the foe's
owner applies them; `ActorBase.apply_slow` / `slow_factor` scale `steer_horizontal`.
`LevelBase.home_sign()` names the isle's Sign (the Caldera reads it from the atlas).

**The card bench for a young player.** `InkCardFace` paints each card in code: its
Sign's colours, name, ink dots, the eight deck pictures (cairn, hedge, squall,
mantle, ember, hearth, thrust, weir; any other card gets its Sign's glyph over a blade
or a shield), what it does in a child's words and its diamond; Gilded Leaf copies
shimmer and Star-Ink copies twinkle. Your cards are a grid of these pictures; the
highlighted one stands big in the spotlight with "Light: put it in your R diamond!" or
why not yet; slotting one flies the card into its diamond with a burst of sparkles
(`CardSparkle`), a chime and "Squall-Lash is in your R diamond!". `DiamondGuide` is the
picture guide (a diamond taken apart, six numbered steps); it opens itself the first
time the cards tab shows in a session and from the bench's "How does a diamond work?".
Checked by `tools/test_ink_deck.gd`.

**Corrections to the workshop page.** The L counter-brace is "land a hit, then tap L
in the gold flash" (not "after a blocked hit"), so Hedge-Root Brace roots the foe you
just hit; a shield already shrugged shoves, so that line is no longer "new". The
page's open questions ("To decide") were built as drafted; changing one is a number in
`CardTwists` or a line in `ArsenalCatalog._build_ink_deck`.
