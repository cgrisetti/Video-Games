# 28 · Act I, The Fading Margin: production design and script (Q01 to Q05)

> **Asked for (2026-11-08):** the complete Act I production design and narrative script package for Quests Q01 to Q05, plus a 12-card Act I compendium, from the Creative Director's pasted brief and the Google Doc *Everwood Narrative & Design Bible* (id `1QyJqg9plie4SDhuepEH3ZLWFSIwZAXAACCtlwtEVJog`, §4 Act I).
> **Scope:** writing only. No code, scene or save changed. Everything here is fitted to the game as it stands on `main` (369525a): the starting isle is **Embershore** (docs/27), cards spend **Ink-Drops** (docs/25), and every foe is a spirit of the First-Quiet that is calmed, never slain (docs/08 Gate 3, docs/15).
> **Numbered 28:** 27 is the newest doc.
> **Built (2026-11-09):** [docs/29](29_ACT_I_BUILD.md) builds this script on Embershore (`Z1_EMB`), after the Creative Director chose the Bible's 14-level curve (Level 2 at 400 XP to Level 6 at 3,800, cap 14), Act I fitted to today's Embershore with the Level 1 spawn moved into Lee-Shore Orchards, and the Lens names Ash-Grig, Tide-Wight and Sap-Boggart. Three things play differently from this script: a calm, a Deep-Ink or Naming pour, a shrine pour and a bell are **light** pressed near the foe or spot, not a held R (R's hold only waits out of combat); Hearth-Ward is the Hearth-Brazier's; and the Taproot Hall's Root-Lurkers are the third chamber, with the Stag after it (the brief's three chambers come before the boss). §9's calls 1, 2, 3, 7 and 15 are settled; docs/29 §10 lists what's left.

---

## 1. Read first: how the brief fits the game

The brief and the Bible were written against an older map and older card rules. Each line below says what this package does about it. The open choices are gathered in §9 with a default for each.

| The brief says | The game has | This package |
| :-- | :-- | :-- |
| Zone `Z1_OAK`, **Oakshire Holm** | **Embershore** (once Oakshire Holm, then Miller's Oak). Ids keep `oakshire_holm`, `ISLE_OAKSHIRE_HOLM`, `--boot-zone=oakshire`. | Plays on Embershore. Every quest has a *Staging* line with real spots in the isle's local frame (docs/27 §1). |
| **Card Fuel pips**, "scaled by class and level" | The **Ink-Well**: cards spend **Ink-Drops**. 4 drops at Stage 1 (5 with Wise Hand). Swings never fill it. Calming a foe +1, a Rare +2, a Great-Boggart +3, a boss stagger +2 to every hero in reach, a Hearth-Brazier fills it (docs/25 R1, R2). | Ink-Drops throughout. The brief's rule (fill by calming, not by slaughter) is already the game's rule. |
| **Cooldown** on each card | None. Cards cost drops, never cooldowns (R1). | The compendium's Cooldown column says "none" or names a limit a card's own rule sets. |
| **Scrap** (25 / 15) | **Chimes** is the one currency (Gate 1: no new currencies). | 25 Chimes / 15 Chimes. |
| **Woodcut, Gilded, Foil, Capstone Star-Seal** finishes | **Plain Ink, Gilded Leaf, Star-Ink**, earned with Ink-Binding Marks and pressed (R3). | Woodcut = Plain Ink, Gilded = Gilded Leaf, Foil = Star-Ink. The Capstone Star-Seal is new and belongs to the Fay-Star alone (§8). |
| **Dual Active/Seal Card Slot** at Lv 4 | Sockets open by Character Level: weapon Seal 3, R card 4, offhand Seal and L card 6, mantle Seal and Tuck 11, L+R 17 (R4). | Lv 4 is the first level a hero carries a Seal *and* an Active. Q03 unlocks that pair (spec in §5.7). |
| A **Calming Seal** played at Lv 1 | No socket is open before Lv 3. | The Calming Seal needs no socket: it plays on the Hearth-Rite hold of R (§3.4). |
| Burn a guardian to **0 HP** | Nothing is slain (Gate 3). | 0 HP **scatters** a spirit: it breaks into grey ash, sinks into its crack and comes back. Calming sets it right. |
| **The Un-Inking**, Blank-Stone | The **First-Quiet** (the Deep-Hush). Old-Hob-of-the-Hill scratches out the Maker-Ink on boundary stones (docs/15 §3.2). | One thing, two names. Villagers say "the grey" or "the Un-Inking". Blank-Stone is a stone whose Maker-Ink has been scratched out. |
| **5-player** encounters | 1 to 4 heroes on one screen, up to 5 over the network, companions to fill. | Every "5-player" finisher means *every hero in reach*, companions included. Numbers scale by heroes present. |
| **Lantern-Bearer** chime | The Lantern-Bearers are a Fellowship (Bell-Keeper, Wind-Mender, Lantern-Scribe), the Menders. | The party's Lantern-Bearer holds the Amber Chime. With none seated, it passes to one hero (§5.4). |
| XP: 400 / 900 / 1,600 / 2,500 / 3,800 | `PartyProgress.LEVEL_XP`: 70 / 105 / 230 / 320 / 560 for Levels 2 to 6. | Lists the brief's numbers. The curve is a call (§9). |
| A recurring **-6 m Ebb-Tide** at Lv 4 to 5 | One permanent ebb: the whole party pulls the Harmonic Bell on The Crown at Lv 18 to 19 (docs/20). | Q04 runs a *timed* ebb window that floods back. The permanent ebb stays the Bell's (§9). |

**On screen, words follow Gate 6:** Ink-Drops, Ink-Well, Seal, chime-post, Make Ink Cards, Defender / Striker / Mender. The brief's system names stay in design text only. Barks show in each player's own cell on the ribbon, never as labels over heads (a Label3D over a head lands on the boss frame in a chase camera).

---

## 2. Act I at a glance

| Quest | Levels, XP (brief) | Where on Embershore (local m) | Foes | Teaches | Unlocks, world change |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **Q01** Lee-Shore Awakening & Through the Veil of Mooreeffoc | 1→2, +400 / 400 | The Heirloom Orchards' grey edge → Bramblebridge green (start chime-post, −594, 17, 258) | Un-Inked Bramble-Hounds | Wear down, then calm. Ink-Drops. | Starter weapon card, Calming Seal, the Ink-Well. The green's lanterns relight. Flicker-Wick cue. |
| **Q02** Root, Leaf, Flower, and Seed: The Blighted Cider-Boughs | 2→3, +500 / 900 | The orchard's four groves (§4.1) | Grey-Bark Weevils, Blight-Mites | Wide sweeps that spare the trunks. Spending drops at a shrine. | *Ael-Voran* at four Root-Shrines. Living Cider-Resin. Make Ink Cards and finishes at Alf-Wright's bench. |
| **Q03** The Silent Mill & The Furrow Iron-Man | 3→4, +700 / 1,600 | The watermill (−512, 12, 259) and Bramblebridge's stone bridge (−589, 6.5, 213) | Ash-Gremlins, the Furrow Iron-Man | The Stag Hunt: hold blades, finish together. | Bridge mended. Miller Hob cured. The Seal-and-Active pair (Lv 4). The wheel stops. |
| **Q04** Six Shall Turn It Back at the Old Quay | 4→5, +900 / 2,500 | North Quay pier (38, −0.6, −237) → the Old Quay platform (x 17 to 61, z −263 to −242, y −4.5) | Barnacle Scuttlers, Tide-Wraiths | Fighting on a clock. Three bells on the beat. | The Bronze Carillon Tongue. The Tidal Horologium. |
| **Q05** The Root-Sanctum & The Star in the Cake | 5→6, +1,300 / 3,800 | The Elder Oak's roots (door −147, 14, 234) → out by the weir (−453, 6, 212) → the green | Blighted Sap-Elementals, Root-Lurkers, the Blighted Taproot Stag | Chains in stagger windows, cleansing fog, one Naming together. | `root_sanctum_cleared`: the wheel turns, the West Strait and Eel Spit open. The Fay-Star Seal. Lv 6. |

Between Q03 and Q04 the party walks Embershore's corridor (the Moss-Oaks, the Sunken Holloway, Doverslap, the Coast Road) to Hearthstead. Its camps fill the levels the quests don't (docs/27 §6).

### 2.1 The cast

| Who | Plays as | Voice |
| :-- | :-- | :-- |
| **Master Alf-Wright** | Master of the wright's yard (−638, 18, 259) and its Atelier bench. Arms the party. Bakes the Great Cake. | Quiet, dry, kind. Short sentences. Sees more than he says. Never explains the magic away. |
| **Reeve Nokes** | The parish Reeve. Bunting, lists, a chain of office he polishes on his sleeve. | Pompous and loud. Takes credit. Calls Faery "nursery stuff". He is the joke. The magic never is. |
| **Dame Tenar-Moss** | Herbalist. Knows every tree by four names. | Plain, patient, a little stern. Asks before she tells. |
| **Miller Hob** | The miller. Forged by a Blank-Stone, then cured. | Before: flat, no names, no questions. After: warm, wet-eyed, laughing at himself. |
| **Wren** (offstage) | Hob's daughter. Took the lantern-ferry to The Crown at the first grey. *Invented for this script.* | Seen only in a painted cup marked W. |

**Bark rules.** Combat barks are 12 words or fewer. A bark never repeats within 30 s. Tutorial barks play once per save, then rarely.

---

## 3. Q01 · Lee-Shore Awakening & Through the Veil of Mooreeffoc

*Lv 1→2 · +400 XP / 400 · Counsel: Tolkien, Recovery (seeing a familiar thing clearly again).*

### 3.1 Staging

- **Start:** the party wakes under the apple trees on the orchard's east edge, between the Leaf grove (−550, 17, 119) and the green. The start chime-post on the green (−594, 17, 258) stays the checkpoint.
- **The grey perimeter:** four Bramble-Hound packs on the orchard's outer rows, one per side, each at a grey hedge gap. Each gap has a small Hush-Crack the pack sleeps by.
- **Finish:** Bramblebridge green. The brief's "Hearthstead Market" is Embershore's Lv 5 town, 2.6 km away, so the green stands in for it here (§9).

### 3.2 Intro cutscene (about 48 s, any player holds Start to skip)

| # | Time | Picture | Line |
| :-- | :-- | :-- | :-- |
| 1 | 0 to 6 s | High over the Bramble at dawn. The camera drifts down over the orchard. The middle rows are watercolour gold and green. The outer rows are grey at their edges, like a page rubbed with a thumb. Music: the mosaic thinned to its cello drone (§3.6). | (none) |
| 2 | 6 to 14 s | The heroes wake in the grass (the youth's idle). An apple drops beside them and lands grey and dull. | (none) |
| 3 | 14 to 22 s | Master Alf-Wright leans on the orchard gate, a wood-shaving in his hair, a card box under his arm. | **ALF-WRIGHT:** Awake at last. Good. The orchard isn't. |
| 4 | 22 to 30 s | He holds up the grey apple. Through the gate lantern's glass, the inn's painted sign across the green reads back to front. | **ALF-WRIGHT:** Look at it. Properly. The old sign-painters had a word for this. *Mooreeffoc.* "Coffee-room", read backwards through the glass. A thing you've seen a hundred times, suddenly strange. Strange is where seeing starts. |
| 5 | 30 to 38 s | The camera follows his look to the grey hedge. Something with thorns for fur shifts behind it. | **ALF-WRIGHT:** Something is rubbing the ink out of the world. Old folk call it the Deep-Hush. I call it the grey. The hedge-hounds have it worst. They aren't wicked. They're blank. And frightened. |
| 6 | 38 to 44 s | He deals each hero two cards. They fly into each player's Cross with the card sparkle: the Fellowship's weapon card and the Calming Seal. | **ALF-WRIGHT:** A weapon to shake the fright loose. A Seal to write them back in. Wear them down, then calm them. Never the other way round. |
| 7 | 44 to 48 s | A Bramble-Hound pushes through the hedge, thorns rattling, eyes as blank as paper. Title card. | (title) **Q01 · Through the Veil of Mooreeffoc** |

### 3.3 Combat tutorial barks (Master Alf-Wright)

| When | Line |
| :-- | :-- |
| First hound in reach | There. Strike it till it staggers. Watch for the wobble. |
| A hound's posture breaks (first time) | Now! Hold R. Gently, like a hand on a dog. |
| First calm | See? The colour comes back where it belongs. |
| First Ink-Drop lands | That bead's an Ink-Drop. Your well holds four. Seals drink them. |
| Well full | Your well's full. Keep it. The shrines will want it. |
| A hound scattered by plain hits (first time) | Scattered, not calmed. It'll be back, and crosser. |
| Two heroes calm at once | Two at once! The orchard felt that. |
| Hero under 40% health | Step back. Guard with L. No shame in a buckler. |
| Perfect Guard (first time) | Ha! Like a gate swinging shut. |
| A hero is downed | Up you get. Nobody's lost on my watch. |
| 20 s with no fighting while packs remain | The grey doesn't wait. Neither do hounds. |
| Third pack calmed | One more gap in the hedge. Then the green. |
| Last pack calmed | That's the edge holding. Come on, to the green. |

### 3.4 Un-Inked Bramble-Hounds: tuning

Numbers are set by hits, not raw health, because the Character Level 1 to 20 ladder (docs/25) is still settling. They live as named constants on the hound's resource.

| Constant | Value | Why |
| :-- | :-- | :-- |
| `PACK_SIZE` | 3, +1 per hero past the first, at most 6 | Every hero has a hound. |
| `PACKS` | 4 | One per side of the orchard. |
| Health | lasts about 9 Light hits from a Lv 1 hero | Longer than posture, so calming is always possible. |
| Posture | breaks after about 4 Light hits or 2 Heavies, or 1 Perfect Guard plus 2 Lights | Rewards Heavies and guarding (docs/04: posture comes from coordination). |
| `WAVER_SECONDS` | 2.0, held to 3.0 while a hero holds the calm | The calm window (the woodland kin's knockdown). |
| `CALM_HOLD_SECONDS` | 0.75 (Squire seat 0.4) | Short enough for a six-year-old. |
| Bite | the Bramble-Hob nip (7 at docs/04's scale), 0.6 s wind-up, 3 m lunge | Readable. One bite never downs a Lv 1 hero. |
| Calm reward | +1 Ink-Drop to the calmer, XP, Ink-Binding Marks on worn cards | docs/25 R2, R3. |
| Scatter reward (health to 0) | 2 Chimes, no drop. The hound re-forms at its crack 90 s later, its bite +25%. | Scattering is quicker and worse. The lesson Q03 builds on. |

**The calm, as a player does it.** A wavering hound shows a soft gold ring and the prompt **HOLD R: CALM**. Holding R is the Hearth-Rite hold the controls already have. At Lv 1 the R socket is padlocked, but the hold still plays the Calming Seal: it is Alf-Wright's gift, not a socketed card. It costs 0 drops and pays 1.

### 3.5 The Recovery burst (watercolour)

Every calm plays this. It reuses the un-boggarting effect and the blight radius from docs/18.

| Time | What you see | What you hear |
| :-- | :-- | :-- |
| 0 s | The hound freezes mid-stagger. Its grey coat cracks like dried paint. | The mosaic ducks 3 dB. |
| 0 to 0.3 s | A drop of Warm-Hearth gold falls from the Seal's glyph onto its brow. | A soft harp pluck on the next eighth note, in F. |
| 0.3 to 0.8 s | A watercolour bloom races out in a 6 m ring. The grass under it turns from grey to green with a wet, ragged edge and a paper-grain bleed. Daisies and buttercups pop up as the edge passes. | A rising harp glissando. |
| 0.8 to 1.5 s | The hound shakes like a wet dog. Its brambles flower pink (dog-rose). It wags once and trots into the hedge. | One brass chime. |
| 1.5 s | A lavender Ink-Drop bead (`#B993F2`) flies to the calmer's Cross. | A bead click. |

Each calm restores a twelfth of the grey perimeter. With all four packs calmed, the orchard edge is full colour and stays so in the save.

### 3.6 Audio: the Tier 1 Flicker-Wick cue (solo bassoon)

- **Before:** while Q01 is open, the orchards lean the mosaic (`millers_holm`, F Lydian, 6/8 at 104) to Peace and Mellow, with the lead stem (stem 1) at −80 dB. You hear the waterwheel ground and the cello drone only. This is the Bible's "Tier 0: Gutter-Ash" colour.
- **Trigger:** the last pack is calmed, *and* a hero comes within 20 m of the start chime-post.
- **The moment:** the green's twelve cottage lanterns relight one by one, a quarter-second apart, on the beat. The director queues a new cell, `flicker_wick`, with `playback.switch_to_clip` at the next bar line (exact, per docs/16's lesson). Stem 1 rises from −80 to 0 dB across the cell's first bar. A solo bassoon plays a four-bar tune over the waterwheel (6.92 s). Banner: **THE GREEN IS LIT**.
- **After:** the walk resumes in Peace. From then on `flicker_wick` sits in the Peace pool within 60 m of the green at twice the weight, for the rest of the save.
- **To make:** compose the cell in `tools/build_audio_stems.py` (Peace mood, voicing "E Solo Bassoon", Holm chords `Fadd9 Bb/F Dm7/F C/F`), then bake its stems and listening copy as for the other cells.

### 3.7 Done when

All four packs are calmed and a hero reaches the green. **Rewards:** +400 XP, Level 2. The orchard edge stays coloured. Alf-Wright's bench in the wright's yard opens (it holds the Tier 1 wood kit).

---

## 4. Q02 · Root, Leaf, Flower, and Seed: The Blighted Cider-Boughs

*Lv 2→3 · +500 XP / 900 · Counsel: Le Guin. Know a thing whole before you use it.*

### 4.1 Staging

Embershore's orchard rises only 5.7 to 18.5 m and has no terraces, so the brief's four tiers become four groves (§9). Each has a Root-Shrine: a mossy stone with four cup-marks at the foot of its oldest tree.

| Grove | Trees | Height | Centre (local) | Its idea |
| :-- | :-- | :-- | :-- | :-- |
| **Root** | 23 | 5.7 to 10.7 m | (−770, 7, 148), the low west rows | Weevils come up from the soil. |
| **Leaf** | 24 | 10.9 to 16.1 m | (−550, 17, 119), by the green and the mill race | Mites fall from the canopy. |
| **Flower** | 23 | 16.1 to 17.0 m | (−614, 17, 66), the north rows with the bee-skeps | Both kinds at once. |
| **Seed** | 24 | 17.1 to 18.5 m | the orchard's top edge, north of Flower | A Great-Boggart weevil. |

### 4.2 The argument at the orchard gate

*Nokes arrives with two workmen carrying axes and a cart of bunting. Dame Tenar-Moss is already at the gate, a basket on her arm.*

> **NOKES:** Stand aside, Dame. Parish business. These trees are coming down.
> **TENAR-MOSS:** These trees are older than your parish, Reeve.
> **NOKES:** And greyer than my grandmother. The Feast needs firewood. Grey wood burns. I've done the sums.
> **TENAR-MOSS:** Grey isn't dead. Grey is forgetting.
> **NOKES:** Forgetting! Trees don't forget. Trees don't *remember*. Trees stand about being trees.
> **TENAR-MOSS:** *(to the party)* Do you know what a tree is?
> **NOKES:** Firewood that hasn't been told yet.
> **TENAR-MOSS:** A root to hold the hill. A leaf to drink the light. A flower for the bees. A seed for the tree after this one. Know all four, and you know it. Know one, and you only know what it's good for.
> **NOKES:** I know what it's good for. A bonfire. With bunting.
> **TENAR-MOSS:** Weevils have got into the bark, and mites into the leaves. The grey came with them. Clear them out and the trees will wake.
> **NOKES:** And if they don't?
> **TENAR-MOSS:** Then you can have your bonfire.
> **NOKES:** Ha! Witnesses! *(to the workmen)* You heard her.
> **TENAR-MOSS:** *(to the party)* Mind the trunks. A sweep that bites the bark does the weevils' work for them.
> **NOKES:** One day, Dame. If I see a single weevil at my Feast, the whole orchard goes on the fire.
> **TENAR-MOSS:** Your Feast?
> **NOKES:** *(polishing his chain)* Whose name is on the bunting?

### 4.3 Encounter script: the four groves

**Teaching tool:** the Cooper's Split-Rail Mallet's Heavy sweeps wide twice (the brief's AoE Cleave weapon card, §8). One-hand heroes sweep with the Stick's third Light. Either way the rule is the same:

- **Spare the trunks.** A sweep that strikes a trunk leaves a grey scar. Each grove yields 3 Living Cider-Resin, 1 less for every 3 scars (never below 1). Scars heal after the grove's shrine is lit.

| Grove | Pulls | Pressure | New idea | Bark |
| :-- | :-- | :-- | :-- | :-- |
| **Root** | 3 clutches of Grey-Bark Weevils (4 each, +2 per hero past the first). They surface in a ring of turned soil 0.8 s before they pop up. | Low | A wide sweep hits a whole clutch. | **TENAR-MOSS:** Low and wide. They come up from the roots. |
| **Leaf** | Blight-Mite clouds drop from the canopy every 6 s on a RED_AVOID circle (1.0 s tell), plus one weevil clutch. | Low to medium | Step out of a falling cloud, then sweep what lands. | **TENAR-MOSS:** Look up! Then step aside. |
| **Flower** | Two weevil clutches and two mite drops at once, among the bee-skeps. | Medium | Pick your sweep: a skep sits between you and the clutch. (Skeps are scenery and take no harm.) | **TENAR-MOSS:** Bees are friends. Mind your swing. |
| **Seed** | One Great-Boggart Grey-Bark Weevil the size of a cider barrel, with two small clutches. It has a posture bar and a Braced Front Guard. | Medium | Flank it. Calming it pays +3 drops (R2). | **TENAR-MOSS:** Go round it. Its back is soft bark. |

Calm every foe you can. Each grove has enough to fill every hero's well (4 drops) before its shrine.

### 4.4 The Root-Shrines and *Ael-Voran*

*Ael-Voran* (say AY-el VOR-an) is an Old Speech word. Tenar-Moss: "It isn't an order. It's a reminder. It means *be what you were.*"

| Rule | Value |
| :-- | :-- |
| Drops a shrine needs | 3 per hero in reach (solo 3, five heroes 15) |
| How you pour | Hold R at the shrine (the Hearth-Rite hold, 2 s). Your drops fly to the cup-marks as lavender beads. Several heroes pour together. |
| If short | The cup-marks keep what was poured. Calm more and come back. |
| When full | The word *Ael-Voran* writes itself up the trunk in gold calligraphy, one letter per beat. A Recovery burst fills the grove (18 m). Apples redden. A bead of resin swells on the bark: the grove's Living Cider-Resin. |
| Seed grove only | One last weevil clutch rises while you pour. Pouring under pressure. |

**Shrine barks (Tenar-Moss):** first shrine "Give it what you carry. It gives it back." · a hero pours alone "Others can pour too. It's quicker shared." · last letter written "There. Root, leaf, flower, seed."

### 4.5 Make Ink Cards and finishes: the tutorial (Alf-Wright's bench)

*The wright's yard. Timber stacks, a bench, pots of ink. The party arrives with Living Cider-Resin.*

> **ALF-WRIGHT:** Resin. Good. Do you know what's in it?
> **ALF-WRIGHT:** Years. The good ones. A tree keeps its best summers in its sap.
> **ALF-WRIGHT:** Show me your cards. *(the bench opens on the hero's Calming Seal)* See those marks along the edge? Ink-Binding Marks. Every hound you calmed with it wrote one.
> **ALF-WRIGHT:** Brush a little resin in. *(prompt: Light to brush. The Marks bar climbs to 100)*
> **ALF-WRIGHT:** That's a card that's ready. Press it.
> *(prompt: Light to press. The card goes under the press with a thump and comes out edged in gold leaf. Banner: GILDED LEAF)*
> **ALF-WRIGHT:** Gilded Leaf. Same card, more of it. It'll calm quicker and shine while it does.
> **ALF-WRIGHT:** Now something new. *(he slides a blank card across)* Your weapon wants a Seal. Here's one I keep for chains and rusted things.
> *(prompt: Light to make it. The Breaching Seal draws itself in ink. It flies into the weapon Seal socket, which opens at Lv 3)*
> **ALF-WRIGHT:** It hits hardest on a two-handed swing. On a short blade, it takes three.
> **ALF-WRIGHT:** Cards change at a chime-post or at this bench. Not in the middle of a scrap.
> **ALF-WRIGHT:** And the Dame was right. You can't make a good card out of a thing you don't understand.

**What it sets up:** the tutorial costs 4 resin for one 100-Mark feed (1 resin = 25 Marks), so a party that spared the trunks has resin left to feed other cards. This is a new feed beside docs/25's "a spare copy adds 100". Making a card here is the Scribe Desk's draft. The bench is a second `ScriberyStation` (§10).

### 4.6 Done when

All four shrines are lit. **Rewards:** +500 XP, Level 3, Living Cider-Resin (3 to 12), a Gilded Leaf Calming Seal, the Breaching Seal in the weapon socket. Nokes, at the gate: "Hmph. Well. They *are* rather red." His workmen put the axes back on the cart.

---

## 5. Q03 · The Silent Mill & The Furrow Iron-Man

*Lv 3→4 · +700 XP / 1,600 · Counsel: Hobb (Forging: a person emptied of feeling) and the Stag Hunt.*

### 5.1 Staging

- **The mill:** Bramblebridge's watermill (−512, 12, 259) on the mill race. Its granary is the loft.
- **The bridge:** Bramblebridge's single-arch stone bridge (−589, 6.5, 213), about 90 m from the mill. The brief's "North Quay Bridge" doesn't exist on Embershore. This is the nearest bridge to the mill (the other choice is the Doverslap bridge, §9). The Iron-Man is knocking the parapet stones into the Bramble.
- **The wheel:** `wheel_stopped` is set as Q03 starts, not at Lv 5 (§9). It stays stopped after Hob is cured, because the weir that feeds the race is choked by the Elder Oak's roots (docs/27's own note). Q05 frees it.

### 5.2 Miller Hob, before the cure (Forged)

*Hob stands at a millstone that isn't turning, moving an empty scoop from sack to hopper and back. He doesn't look up. A Blank-Stone boulder sits by the door, grey and smooth as an egg.*

> **HOB:** Grain goes in. Flour comes out. Grain goes in.
> **HOB:** The wheel stopped. I will wait for it.
> **HOB:** You are standing on my sacks.
> **HOB:** Something is in the loft. It eats four sacks a day. That is a loss.
> **ALF-WRIGHT:** *(at the door)* Do you live here alone, Hob?
> **HOB:** I keep a tidy mill.
> **HOB:** There is a cup on the shelf with a W on it. I don't know whose. I should throw it out. I don't.
> *(after the loft is cleared)*
> **HOB:** The loft is clear. "Thank you" is the word, I think. Thank you.
> **HOB:** The thing on the bridge is breaking it. The bridge is how flour leaves. That is also a loss.

**Direction:** no exclamation marks, no names, no questions back. His face has no cheek flush (`cheek_flush` 0) and his blink is slow. Never played for laughs.

### 5.3 Ash-Gremlins in the granary

Two short waves in the loft (5 Ash-Gremlins, then 4, +1 per hero each). They grab a grain sack and run for the loft door: a gremlin that reaches it escapes with the sack. They have low posture. Calm them all to fill your wells before the bridge.

**Bark (Alf-Wright, arriving at the mill door):** "Fill your wells on these. You'll want every drop on that bridge."

### 5.4 The Furrow Iron-Man: a Stag Hunt

The Iron-Man is a Furrow Iron-Man from docs/15: a plough-iron spirit with an upside-down Maker-Seal (▼) on its chest. It isn't wicked. Its seal was turned when the grey reached the furrows.

**Two paths, shown once on every screen as the party first sees him (plain words, no maths):**

| | **Scatter him** (the "Rabbit") | **Calm him** (the "Stag") |
| :-- | :-- | :-- |
| Card text | 25 Chimes now. He comes back angry in 10 minutes. | 15 Chimes. The bridge is mended. He walks with you. +10% speed for 15 minutes. |
| How | Burn his health to 0. | Fill his posture meter, hold blades, finish together. |
| Time (5 heroes) | about 35 s | about 48 s (40 s to break, 8 s to finish) |
| Then | He falls apart into rusted plough-iron and sinks into the furrow at the bridge foot. 10 minutes later the **Rusted Iron-Man** rises there: +40% damage, his posture meter fills at half speed, and he blocks the bridge until calmed. No Warmth-Ember, so Q03 can't finish. | His seal turns upright (▲). He bows, sets the parapet stones back and stays as a friendly steward for 15 minutes (900 s; the Lens's steward time is 600 s). He opens his chest-grate and gives the Warmth-Ember. |
| Party value (design only) | 25 Scrap, −40 hazard = **−15** | 15 Scrap, +120 World Buff = **+135** |

Health and posture scale by heroes present, so both times hold within a few seconds from 1 to 5 heroes. His posture meter drains 15 a second after 3 s untouched (docs/04's boss poise), so a slow trickle of Lights never breaks it. Heavies, Perfect Guards and Sign strikes do. Docs/15's Maker-Seal rule still works: a Warm-Hearth strike opens his seal for 6 s, and an Iron-Root strike in that time adds a big posture chunk.

**Fight timeline (5 heroes):**

| Time | He does | The party should |
| :-- | :-- | :-- |
| 0 to 15 s | **Furrow Sweep:** a plough-blade swipe, RED_AVOID 120° arc, 5 m, 1.2 s tell. **Clod Toss** at the farthest hero: RED_AVOID circle, 3 m. | Defender in front. Others flank. |
| 15 to 30 s | Adds **Stamp:** GOLD_STACK on the Defender. Stack to share the blow. | Stack, then punish with Heavies. |
| 30 to 40 s | **Seal Flare:** the ▼ glows for 6 s. | Warm-Hearth, then Iron-Root: a posture chunk. |
| about 40 s | Posture 100%: **he kneels** for an 8 s window. | The chime, then the finisher (below). |
| 40 to 48 s | Kneeling, still. | Hold R together. |

**The break, step by step:**

1. Posture reaches 100%. Banner on every cell: **HE KNEELS!** A golden **Metronome Pendulum** appears over him and swings once a beat (the mosaic's dotted quarter, 0.58 s).
2. The Lantern-Bearer's cell shows **R: HOLD BLADES!** Pressing R plays the **Amber Chime**: 0 drops, once per kneel. A brass carillon rings on every player's audio. His health bar turns amber.
3. While the bar is amber, hits do no health damage. They throw sparks and a soft clank. No accidental scatter.
4. Every cell shows **HOLD R: DEEP-INK** and the pendulum's five beats (about 3 s, inside the 8 s kneel; Squire seat +2 beats). Each hero holds R to pour 2 drops. The kneel just paid every hero in reach +2 drops (R2), so everyone can afford it.
5. Each finished hold draws one gold stroke across his seal. When every hero in reach has poured, the seal turns upright (▲) with a deep bell note and a full Recovery burst. Calmed.
6. **Missed:** if the beats run out before everyone pours, he stands up, his posture at 50%. The strokes already drawn stay drawn. Break him again.

**No Lantern-Bearer seated?** The chime goes to the hero with the most drops at the kneel. Their cell says **YOU HOLD THE CHIME**. A companion Mender rings it on the kneel by itself. Either way one hero gives the signal and everyone else answers.

### 5.5 Callouts and screen prompts

| Moment | Bark (who) | On screen |
| :-- | :-- | :-- |
| Party first sees him | **ALF-WRIGHT:** That's no foe. That's the old furrow-tender. Someone's turned his seal. | The two-paths card (§5.4) |
| Fight starts | **ALF-WRIGHT:** Wear him down. Don't knock him down. | Lantern-Bearer's cell: **YOU HOLD THE CHIME** |
| Posture 50% | **ALF-WRIGHT:** He's wobbling! Heavies now! | Posture meter pulses |
| Posture 90% | **ALF-WRIGHT:** Nearly! Ready your hands. | |
| Health under 25%, no kneel yet | **ALF-WRIGHT:** Careful! You'll scatter him, not save him. | Health bar edge flickers grey |
| Kneel | **LANTERN-BEARER:** Hold your blades! *(on the chime)* | **HE KNEELS!**, the pendulum, **R: HOLD BLADES!** |
| A hero hits during amber | **ALF-WRIGHT:** Blades down. He's listening. | Sparks, no damage |
| Finisher | **ALF-WRIGHT:** All together. Now. | **HOLD R: DEEP-INK**, five beats |
| Seal turns upright | **IRON-MAN:** *(a slow clank, then)* MEND. MEND THE BRIDGE. | Banner **THE IRON-MAN WAKES** |
| Window missed | **ALF-WRIGHT:** He's up. Once more. You were close. | |
| Scattered | **ALF-WRIGHT:** Scattered. He'll rise again, rusty and cross. Ten minutes, I'd say. | A 10:00 count on the bridge's chime ribbon |
| Calmed | **ALF-WRIGHT:** There he is. Good morning, old fellow. | |

### 5.6 The Warmth-Ember and Hob's hearth

1. The calmed Iron-Man opens his chest-grate and holds out a coal, the **Warmth-Ember**. One hero takes it. It glows in their hand at walking speed. Any hero can pass it with a tether press.
2. At the mill, the ember goes into Hob's cold hearth. Every hero within 5 m holds R to play **Hearth-Warmth** (2 drops each). The Bible's "infuse your own Hearth-Warmth": you give some of what you carry.
3. Short scene (about 15 s): the ember catches. Colour floods the mill room from the hearth outwards. Hob's cheeks flush (`cheek_flush` back to his normal). He looks up for the first time.

### 5.7 Miller Hob, after the cure

> **HOB:** *(a long breath)* ...Wren.
> **HOB:** Her name's Wren. My girl.
> **HOB:** She took the lantern-ferry to The Crown, the week the grey came. Said she'd find out what was rubbing the colour off the world.
> **HOB:** And I let her go, and then I... stopped missing her. Like she was a sack I'd already ground.
> **HOB:** *(he picks up the cup marked W)* She painted this when she was six. I nearly threw it out. I nearly threw *her* out.
> **HOB:** *(laughing and crying)* Oh, it hurts. It's good. I'd rather hurt than be tidy.
> **HOB:** Thank you. And I mean it this time. I can feel myself meaning it.
> *(the hook for Q04)*
> **HOB:** The quay bell went quiet when she left. Its bronze tongue went down with the old sea-lock, into the vault under North Quay. I watched it go and felt nothing.
> **HOB:** I feel it now. Bring it home?

**Direction:** let the silences sit. Hob's grief is not fixed by the cure. The cure is that he can carry it again.

### 5.8 Unlock: the Seal-and-Active pair (the brief's Dual Active/Seal Slot)

| | Spec |
| :-- | :-- |
| **What opens** | The **R socket** (docs/25 R4, Lv 4). With the weapon Seal opened at Lv 3 (Q02's Breaching Seal sits there), a hero now carries a Seal and an Active together for the first time. |
| **When** | On reaching Level 4, which Q03's XP gives at the end of Hob's scene. |
| **What fills it** | Ember-Wick Cut, every hero's first card (docs/25 §7), is offered into R. A Lantern-Bearer is offered Hearth-Ward instead (it is needed in Q05). |
| **Screen** | Banner **YOUR R DIAMOND IS OPEN**. The diamond guide opens at the step about R. The card flies into the diamond with the sparkle and the chime: "Ember-Wick Cut is in your R diamond!" |
| **Rule reminder** | Cards change only within 14 m of a chime-post. The green's post is about 80 m from the mill. Alf-Wright: "Ring the post on the green, then set your cards." |
| **What R does now** | Tap R plays the card (1 drop for a basic card, R1). Hold R still plays the Hearth-Rite: calms, shrine pours, finishers. |
| **The pair's bonus** | Nothing extra. The pair is the lesson: a Seal shapes every swing, an Active is a choice you spend drops on. |

If "Dual" was meant as one socket that takes either kind, that is a new rule against R5. See §9.

### 5.9 Done when

The Iron-Man is calmed and Hob is cured. **Rewards:** +700 XP, Level 4, 15 Chimes, the bridge mended, 15 minutes of the World Buff (+10% movement and gathering, the Iron-Man walking the lane). The wheel stays still.

---

## 6. Q04 · Six Shall Turn It Back at the Old Quay

*Lv 4→5 · +900 XP / 2,500 · Counsel: Cooper. Verse as a map, a tide as a clock.*

### 6.1 Staging

- **Start:** North Quay's timber pier (root at 38, −0.6, −237), down the quay stair from Hearthstead's 20 m bluff. Hob's message reaches the party at the Hearthstead chime-post (106, 20, −212).
- **The ebb shelf:** the Old Quay platform (x 17 to 61, z −263 to −242, y −4.5), under water until the sea falls.
- **The three sea-locks** stand along the platform's seaward edge, 15 m apart: **Deep** at the west end (x 24), wrapped in black weed; **Warm** in the middle (x 39), under the quay's old lanterns; **Bright** at the east end (x 54), on a rock the gulls sit on.
- **The vault door** is in the bluff face at the platform's back, under the quay stair. The bronze plaque is set in it.

**The tide.** Hob gives the party his tide-reckoner. Ringing the pier's tide-bell starts an **Ebb-Tide window**: the sea falls from 0 to −6 m over 20 s (banner **THE TIDE IS GOING OUT**, no letterbox), stays out for 4 minutes, then floods back over 30 s. This is a timed window, not docs/20's permanent ebb (§9).

### 6.2 The plaque

Six lines in raised bronze letters, green at the edges. It is original to Everwood and tells the order and place of each bell:

> *Grey on the quay and the bells all drowned:*
> *five hands and the sea's own hand make six.*
> *Deep bell first, where the weed grows round;*
> *warm bell next, by the lantern-wicks;*
> *bright bell last, where the gulls fly free,*
> *and the bronze will sing the grey to sea.*

"Five hands and the sea's own hand make six": the five heroes and the tide. A smaller party still counts. With fewer than five heroes, Alf-Wright says on the ribbon: "Five's an old way of saying *everyone*."

**Read-aloud.** The first hero to come within 4 m of the plaque gets the verse on the ribbon, one line per beat, with each bell word tinted (deep in Iron-Root ochre, warm in Warm-Hearth gold, bright in Star-Tide violet).

### 6.3 Wave pacing inside the 4-minute window

Wave sizes are for 5 heroes. Smaller parties get 2 Scuttlers and 1 Tide-Wraith fewer per missing hero, never fewer than 2 foes a wave.

| Time | Wave | Where | Notes |
| :-- | :-- | :-- | :-- |
| 0:00 to 0:20 | The sea falls. | The quay stair | Walk down. The ribbon reads the verse. |
| 0:20 to 1:00 | **Wave 1:** 10 Barnacle Scuttlers in two drops. | The **Deep** lock, crusted shut | Scuttlers scuttle sideways and guard their front (Braced Front Guard): flank them. Calming the last one cracks the crust off the lock. |
| 1:00 to 1:40 | **Wave 2:** 6 Scuttlers, 2 Tide-Wraiths. | The **Warm** lock | Tide-Wraiths are sea-fret given shape. **Cold Breath:** BLUE_BEHIND_TANK cone, 8 m: stand behind the Defender. **Undertow:** pulls one hero 4 m toward the water. A tether press anchors them. |
| 1:40 to 2:20 | **Wave 3:** 3 Tide-Wraiths lead, 6 Scuttlers flank. | The **Bright** lock | The Lantern's Promise (a Lantern-Bearer's 5.5 m light) thins Wraith fog and speeds their posture. |
| 2:20 to 3:30 | **The chain** (§6.4), while an **ambush** of 2 Scuttlers and 1 Wraith comes every 20 s. | All three locks | Defender and Striker guard the ringers. Calming ambushers pays the drops for the bells. |
| 3:30 | **THE TIDE IS TURNING.** The water creeps up the shelf, to −5 m by 4:00. | | Alf-Wright: "Tide's turning! Ring them now or wait for the next one." |
| 4:00 | **Flood.** | | If the vault is shut, every hero is floated back to the quay stair (the deep-water rule). Cleared locks stay cleared. The next window opens 2 minutes later. Nobody redoes Waves 1 to 3. |

### 6.4 The three Resonance Bells

| Rule | Value |
| :-- | :-- |
| The card | **Resonance Bell**, a quest card. While a hero stands in a lock's ring (2.5 m), their R plays it instead of their R card (prompt **R: RING**). 1 drop a strike. |
| Order | Deep, then Warm, then Bright, as the verse says. |
| Chain window | Each strike must land within 2 bars (2.31 s at 104 in 6/8) of the one before. 4 bars (4.6 s) with 1 or 2 heroes. Squire seat +2 bars. |
| On the beat | Each strike sounds on the nearest beat, so the three bells ring in key: F, then A, then C. Together they make an F major chord. |
| Wrong order or late | The bell clangs flat. The chain resets. Only the drop is lost. |
| Who rings | 3 or more heroes: one per lock. 2 heroes: one rings Deep, then sprints to Bright (30 m away, so the 4-bar window must be checked against the youth's sprint speed in a playtest). Solo: the 4-bar window, and a struck bell hums on for it. Companions take free locks. |
| Success | The chord rings out across the bay. The three lock-wheels turn. The vault door grinds open. Every hero in reach gets +2 drops. |

**Barks:** first wrong order (Alf-Wright) "Read the plaque again. Deep, warm, bright." · first good strike "That's one. Keep the time." · chord rings "Hear that? That's the island's own voice."

### 6.5 The vault, the Bronze Carillon Tongue and the Tidal Horologium

- **Inside:** a small, dripping room. The Bronze Carillon Tongue hangs from a rusted hook, green with age, taller than a child. Behind it, painted on the wall, is a bell in a great tree, the Harmonic Bell. Alf-Wright, later: "Its brother hangs in the World-Tree. One day you'll ring that too."
- **Carrying it:** two heroes lift it together (one with a solo hero: it rides on a tether). The tide is coming back, so the walk up the stair is the only fight left: one ambush.
- **Home:** it is hung in the Hearthstead chime-post's bell. When it first rings, the whole isle hears it (the carillon ambience at full, every cell). Banner **THE QUAY BELL RINGS**.
- **The Tidal Horologium:** a small brass tide dial in the corner of each player's cell. One hand swings between FLOOD and EBB, and a ring of ticks counts the minutes to the next window. It shows on Embershore within 300 m of the quays and on the Atlas. It is a clock, not a quest arrow (docs/20 Phase 5 keeps quest arrows out).

### 6.6 Done when

The tongue hangs in the Hearthstead bell. **Rewards:** +900 XP, Level 5, the Tidal Horologium. Hob, at the mill, when he hears it: "There. That's the sound she grew up with."

---

## 7. Q05 · The Root-Sanctum & The Star in the Cake (Act I capstone dungeon)

*Lv 5→6 · +1,300 XP / 3,800 · Counsel: Tolkien (a gift that is lent, not owned) and Le Guin (a true name).*

### 7.1 Staging

- **The door:** among the Elder Oak's roots (door −147, 14, 234; the oak at −189, 15, 167), 450 m east of the green. The Elder Oak is Embershore's largest tree and stands in for the brief's "Great Oak of Hearthstead".
- **The way out:** the arrival beside the weir (−453, 6, 212). The weir is choked by the Elder Oak's roots.
- **The instance:** the Root-Sanctum door already leads into the Cairnsman's expedition (the old Dojo instance, docs/27 §11). This script is its new content, in the three-zone shape docs/08 asks for: introduction, twist, climax.

### 7.2 Opening scene: Nokes cracks the seal (about 30 s)

*Evening light at the Elder Oak. Nokes, a tap, a mallet and a bucket labelled FEAST SYRUP. His workmen look worried.*

> **NOKES:** Every great oak has sap. Every great feast has syrup. Simple sums.
> **WORKMAN:** That's the old seal-stone, Reeve. Dame says don't touch it.
> **NOKES:** The Dame says a great many things. *(he drives the tap into the root-stone; it cracks with a sound like a bell breaking)*
> *(grey mist pours out of the crack and over his boots. The bucket goes grey. Down the slope, the weir's water slows to a trickle)*
> **NOKES:** ...That's the Dame's department.
> **ALF-WRIGHT:** *(arriving, quietly)* No, Reeve. It's ours now. *(to the party)* Down you go. Take everything you've learned.

### 7.3 The three chambers: pacing

Target: about 4 + 3 minutes of chambers, then a 3 to 4 minute boss. The party should reach the boss with full wells.

**Chamber 1 · The Sap-Gallery (introduction).** A long root tunnel lit by amber sap glowing in the walls.

| Pull | Foes (5 heroes) | Idea | Breather after |
| :-- | :-- | :-- | :-- |
| 1 | 4 Root-Lurkers | Lurkers wait inside the walls. A root-knot twitches and a RED_AVOID circle shows 0.8 s before one bursts out. | 15 s |
| 2 | 2 Blighted Sap-Elementals | Slow blobs of grey sap that leave sticky pools: 30% slow while you stand in one. Pull them out of their pools. | 15 s |
| 3 | 3 Lurkers, 1 Sap-Elemental | Both at once. | 20 s, a Hearth-Brazier refills every well |
| 4 | 1 Great-Boggart Sap-Elemental, 2 Lurkers | A posture bar. Calming it pays +3. | Into Chamber 2 |

**Chamber 2 · The Two Valves (the twist).** The sap-river is dammed by two grey valve-knots, 20 m apart. Each holds a sleeping Sap-Elemental Great-Boggart. Both must be calmed **within 3 s of each other**, while Lurkers press from the walls. That needs 2 heroes (docs/08's `min(2, party_size)`). Solo: 8 s, and a companion helps. Miss the timing and the first one re-greys. On success the sap-river runs again and carries the party down a root-slide into Chamber 3.

**Bark (Alf-Wright, over the ribbon):** "Two hands, two valves, one breath."

**Chamber 3 · The Taproot Hall (climax).** A round hall 36 m across. The taproot rises through the middle like a pillar. The Stag stands chained to it.

### 7.4 Boss: the Blighted Taproot Stag

A great stag, as tall as a cottage, its hide gone grey, moss and roots in its antlers. Four rusted chains bind it to the taproot: two to its front legs, one to its antlers, one round its chest. Nokes's workmen hammered them in years ago "to stop it wandering".

**Rules for the whole fight:**

- Only the four telegraph presets: RED_AVOID, GOLD_STACK, GREEN_HEAL, BLUE_BEHIND_TANK (docs/08).
- Its posture breaks every 35 to 45 s (docs/08's pre-check). Four breaks, then the finisher.
- **No scatter here.** Its health can't fall below 10% while a chain holds: the chains hold it up. Q03 taught the choice. Here the only way through is the calm.
- Each break pays every hero in reach +2 drops (R2).
- An assisted youngest player can survive it: the Squire seat auto-guards the Antler Sweep, takes half of any GOLD_STACK share, and is Fogged for 5 s, not 15.

**The chains.** At each break, the Stag kneels for 8 s and one chain glows white-hot where its rust is thinnest. A two-handed Heavy carrying the **Breaching Seal** shatters a glowing chain in one blow. A one-hand Heavy with the Seal takes three. A Heavy without it takes six. Chain order: left leg, right leg, antlers, chest.

**Phase 1 · Bound (chains 1 and 2)**

| Move | Telegraph | Tell | Answer |
| :-- | :-- | :-- | :-- |
| Antler Sweep | RED_AVOID, 120° arc, 6 m in front | 1.2 s: the head lowers, the antlers grey over | Move behind or to the side. |
| Root-Spike Lines | RED_AVOID, three lines out from the taproot | 1.5 s | Step between the lines. The spikes stand 3 s, under 3.2 m tall. |
| Chain-Rattle Charge | GOLD_STACK on the farthest hero | 2.0 s: it strains against its chains | Stack with them to share the blow. The Defender's guard halves it. |

Break 1: left leg chain. Break 2: right leg chain. **Bark (Alf-Wright):** "There! It's glowing. Hit the chain, not the stag!"

**Phase 2 · Forging Fog (chain 3)**

Adds two things:

- **Fog Breath:** BLUE_BEHIND_TANK, a 10 m cone, 1.5 s tell. Stand behind the Defender.
- **Fog banks:** every 20 s, two 5 m banks drift in from the walls and cross the hall over 8 s.

A hero caught in the breath or a bank is **Fogged**: one random card in their Cross greys over with a padlock for 15 s. It can't be played.

**Hearth-Ward** (the Lantern-Bearer's R card, 2 drops): a GREEN_HEAL circle, 4 m, for 4 s. Every hero inside is cleared of fog and can't be Fogged for 6 s. Friends inside also mend 1.5% a second. **Bark (Lantern-Bearer, on cast):** "Into the light! Shake it off."

With no Lantern-Bearer seated, a Hearth-Brazier stands at the hall's south side. Touching it clears your fog (once per 20 s).

Break 3: the antler chain. **Bark (Alf-Wright):** "Fog forgets. A hearth remembers. Stay close to your Mender."

**Phase 3 · The Taproot (chain 4)**

- The Stag plants its hooves. The dry ink-spring at the taproot's foot cracks, and a ring of grey sap closes in: RED_AVOID outer ring, the safe floor shrinking from 36 m to 24 m across for 10 s, then back.
- Two Root-Lurkers, +1 per hero, burst from the walls. Calm them: the Naming Seal costs 3 drops, and the break only pays 2.
- Every move from Phases 1 and 2 still comes, 20% less often.

Break 4: the chest chain shatters. The Stag sinks down. **The Naming:**

1. The Metronome Pendulum appears over the taproot. Every cell: **HOLD R: NAMING SEAL**, five beats (about 3 s; Squire seat +2 beats).
2. Each hero holds R and pours 3 drops. As each hold finishes, one gold letter-group writes itself on the taproot.
3. When every hero in reach has poured, the name stands whole: **ELDERHART**. Each cell shows it, and one low chord sounds under it.
4. **Missed:** the chest chain re-forges, the Stag's posture goes to 60%, and one more break (about 20 s) brings the Naming back. No wipe.

**Bark (Alf-Wright, as the pendulum appears):** "Read it off the root. Say it like you'd wake a friend."

**The calm:** Elderhart rises, unchained. The grey blows off its hide in a watercolour burst that fills the hall, gold and green and the brown of good bark. It looks at each hero in turn. It strikes the dry ink-spring with its forehoof. Golden sap surges up the taproot. Cut away.

### 7.5 Out by the weir

The sap pushes out through the Elder Oak's roots. The roots let go of the weir. The party steps out at the weir's arrival as the water bursts over the sill and runs down the mill race.

- `root_sanctum_cleared` is set: **THE MILL-WHEEL TURNS** (the wheel at the mill starts), the West Strait and Eel Spit causeways open, the trade lanes go dark (docs/27 §6).
- **HOB** *(running out of the mill)*: "She's turning! Listen to her! Listen!"

### 7.6 The Great Autumn Feast

*Night on Bramblebridge green. Trestle tables, bunting, every lantern lit. The mill-wheel turns beyond the bridge. The Elder Oak glows faintly gold across the river. The calmed Iron-Man stands at the green's edge, holding a lantern on a pole. Music: the Flicker-Wick cell, then Wonder.*

> **NOKES:** *(standing on a bench, chain gleaming)* Friends! Parishioners! What a year. Grey trees. Grey hounds. Grey... everything. And who kept the Feast on? Sensible management.
> **TENAR-MOSS:** *(to the party, under her breath)* He means himself.
> **NOKES:** Some will tell you it was magic. Faery! Old Speech! Ha! Faery is for nurseries. Ribbons and wishes and sugar-mice. This Feast was saved by a firm hand and a good list.
> **ALF-WRIGHT:** *(setting down the Great Cake)* Some things look small when you're far away from them, Reeve.
> **NOKES:** Some things look small because they *are* small. Now. The Cake! My design.
> *(the Cake: four tiers, iced, and on top a portrait of Nokes in yellow icing)*
> **NOKES:** A trinket in every slice for luck. Tin. I chose them myself.
> *(Alf-Wright cuts. Each hero's slice goes to them. A beat. Each hero bites something hard.)*
> *(close on one hero's hand: a little tin star. It warms. It unfolds into a card that shines like a star in water. On every screen: A NEW CARD! The Fay-Star Seal.)*
> **NOKES:** *(squinting)* Tin. Lovely bit of tin.
> **HOB:** *(quietly, holding Wren's cup)* That's not tin.
> **ALF-WRIGHT:** *(beside the party, low, so only they hear)* It's borrowed, mind. Stars always are. Carry it well. One day you'll know who needs it next.
> **TENAR-MOSS:** *(raising a cup)* To roots, leaves, flowers and seeds.
> **HOB:** And to Wren. Wherever she's got to.
> **NOKES:** And to sensible management!
> *(everyone drinks anyway. The camera rises over the green, the turning wheel, the gold oak, and out across the dark Sound to The Crown's World-Tree, faintly lit. Fade.)*

**Direction:** Nokes gets laughs. The star never does. Alf-Wright's line is the quietest in Act I.

### 7.7 Done when

The Feast ends. **Rewards:** +1,300 XP, Level 6, the Fay-Star Seal (one per hero). Level 6 opens the offhand Seal and the L card (R4). The Fay-Star goes in the offhand Seal.

---

## 8. Act I card and finish compendium (12 cards)

**Kinds:** a *Weapon* card is the weapon in hand, shown as a card (Binder tab 1). A *Seal* sits in a Seal socket (weapon, offhand) or plays on the Hearth-Rite hold. An *Active* plays on a tap of R (R1 prices). **Stagger** is in docs/04's posture points. **Cooldown:** none for any card (R1); a card's own limit is named where it has one.

| # | Card | Kind, button | Ink-Drops | Cooldown | Stagger | Finish ladder (opens) | Found | Flavour text |
| --: | :-- | :-- | --: | :-- | :-- | :-- | :-- | :-- |
| 1 | **Orchard-Wood Stick & Bark-Buckler** | Weapon, 1H + buckler. Light, Heavy, L guard. | 0 | none | Light 4, Heavy thrust 15 | Plain Ink (1) → Gilded Leaf (3) → Star-Ink (5) | Q01, Alf-Wright | "A stick for the hedge, a buckler for the bramble, and manners for the rest." — Master Alf-Wright |
| 2 | **Cooper's Split-Rail Mallet** | Weapon, 2H, Oak-Knot Pommel. The Heavy sweeps wide twice (the AoE Cleave). | 0 | none | Light 6, Heavy two sweeps 35 | Plain Ink (1) → Gilded Leaf (3) → Star-Ink (5) | Q01, Alf-Wright | "Swing it wide. Mind the trunks." — Dame Tenar-Moss |
| 3 | **Calming Seal** | Seal. Hold R on a wavering foe. Needs no socket. | 0 (pays +1) | none | none: calms | Plain Ink (1) → Gilded Leaf (3) → Star-Ink (5). Each finish shortens the hold 15% / 30%. | Q01, Alf-Wright | "It was never grey. You were only tired of looking." — Master Alf-Wright |
| 4 | ***Ael-Voran*** | Seal, shrine-cast. Hold R at a Root-Shrine. | 3 per hero at the shrine | none | none | Plain Ink only (a word, not a card you wear) | Q02, Tenar-Moss | "Root, leaf, flower, seed. Learn all four and the tree will tell you its name." — Dame Tenar-Moss |
| 5 | **Breaching Seal** | Seal, weapon socket (Lv 3). | 0 | none | Heavies ×1.5 against a kneeling foe. Cracks a glowing chain: 1 two-hand Heavy, 3 one-hand. | Plain Ink (3) → Gilded Leaf (3) → Star-Ink (5) | Q02, made at Alf-Wright's bench | "Iron that binds a living thing is only iron. Hit it." — Master Alf-Wright |
| 6 | **Amber Chime** ("Hold Blades!") | Active, Lantern-Bearer. R during a kneel. | 0 | once per kneel | none: freezes the posture drain, turns health amber | Look only: the chime's colour | Q03 | "One bell, one voice, and every blade waits." — saying of the Lantern-Bearers |
| 7 | **Deep-Ink Finisher** | Seal, party finisher. Hold R in the pendulum's beats. | 2 each | once per kneel | none: completes the calm | Look only: the stroke's colour | Q03 | "We don't break what's lost its way. We write it back in." — Master Alf-Wright |
| 8 | **Hearth-Warmth** | Active, at a hearth. Hold R with the Warmth-Ember lit. | 2 each | none | none | Plain Ink only | Q03, Hob's hearth | "It hurts to remember her. I'd rather hurt." — Miller Hob |
| 9 | **Resonance Bell** | Active, quest card. R in a sea-lock's ring. | 1 a strike | none | none | Plain Ink only | Q04, the Old Quay | "Deep bell first, where the weed grows round." — the Old Quay plaque |
| 10 | **Hearth-Ward** | Active, R socket (Lv 4). GREEN_HEAL circle, 4 m, 4 s. | 2 | none | none: clears fog, 6 s proof, mends 1.5%/s | Plain Ink (4) → Gilded Leaf (4, +15% radius) → Star-Ink (5, +30% radius) | Q03 for a Lantern-Bearer, else the Hearthstead Scribery | "Fog forgets. A hearth remembers." — Dame Tenar-Moss |
| 11 | **Naming Seal** | Seal, party finisher. Hold R in the pendulum's beats. | 3 each | once per break | none: completes the calm | Look only: the letters' colour | Q05, the Taproot Hall | "Say it softly, all together. A name is not a weapon." — Dame Tenar-Moss |
| 12 | **Fay-Star Seal** | Seal, offhand socket (Lv 6). Capstone Star-Seal. | 0 | none | none | **Capstone Star-Seal** only: never pressed, never dropped, never traded | Q05, the Great Cake | "It's borrowed, mind. Stars always are." — Master Alf-Wright |

**The Fay-Star Seal does:** when you calm a foe, the friend nearest you also gets +1 Ink-Drop (once every 4 s). It is the only Act I card that helps someone else by being worn. In Act IV it is given back (the Bible's Q15). Every hero has their own, so siblings never share one star.

**Finishes, with the level gates this package proposes:**

| The brief's tier | In the game | How you get it (R3) | Opens at (proposed) | Adds |
| :-- | :-- | :-- | :-- | :-- |
| Woodcut | Plain Ink | Every card starts here. | Lv 1 | the card |
| Gilded | Gilded Leaf | 100 Marks, Ready to Press, press at a bench | Lv 3 (Q02) | +15% |
| Foil | Star-Ink | 250 Marks | Lv 5 (Q04) | +30% and the presser's Maker-Seal |
| Capstone Star-Seal | new | The Fay-Star only | Lv 6 (Q05) | its own rule above |

R3 has no level gate today. Party cards (the chime and both finishers) change only their look, so a finish never makes the cooperative signal cost or do more.

**Still in every binder:** Ember-Wick Cut and the rest of docs/25 §7's Ink Card Deck are unchanged. This table is the Act I quest set beside them.

---

## 9. Calls for Clay

Each has the default this package uses.

**The map**

1. **The isle.** The script plays on Embershore, not the Bible's Oakshire Holm map. *Default: Embershore.*
2. **Q01's finish.** Bramblebridge green stands in for "Hearthstead Market" (Hearthstead is the Lv 5 town). *Default: the green.*
3. **Q02's tiers.** The orchard rises only 5.7 to 18.5 m, so four groves, not four terraces 15 to 45 m up. The other way is to terrace the orchard in `embershore_gen.py`. *Default: four groves.*
4. **Q03's bridge.** Bramblebridge's stone bridge, about 90 m from the mill, or the Doverslap bridge, where Embershore's Iron-Men live (Lv 4). *Default: Bramblebridge.*
5. **The wheel.** `wheel_stopped` set as Q03 starts (Lv 3), not at Lv 5 near the mill. *Default: at Q03.*
6. **The ebb.** Q04 uses a timed 4-minute ebb that floods back. Docs/20 makes the one permanent ebb the Harmonic Bell's at Lv 18 to 19. Also: should ebb windows keep coming round after Q04 (the Horologium suggests yes)? *Default: timed in Q04, recurring after it, permanent only at the Bell.*

**The numbers**

7. **XP.** The brief's 400 / 900 / 1,600 / 2,500 / 3,800 against `LEVEL_XP`'s 70 / 105 / 230 / 320 / 560. Either re-cut the curve to the brief, or scale quest XP to the curve. Both need a 04_BALANCE pass. *Default: none chosen; the brief's numbers are listed.*
8. **Stag Hunt timers.** The World Buff and the calmed Iron-Man last 15 minutes (the Bible), not the Lens's 600 s. *Default: 15 minutes.*

**The rules**

9. **Pips and cooldowns.** Card Fuel pips are Ink-Drops. No card has a cooldown (R1). *Default: as R1.*
10. **Scrap.** Paid in Chimes (Gate 1). *Default: Chimes.*
11. **The Lv 1 Calming Seal** plays on the Hearth-Rite hold with no socket open. *Default: no socket.*
12. **"Dual Active/Seal Slot."** This package reads it as the Seal-and-Active pair at Lv 4 (the weapon Seal from Lv 3, the R card at 4). A single socket that takes either kind would be a new rule against R5. *Default: the pair.*
13. **Finish level gates.** Gilded Leaf from Lv 3, Star-Ink from Lv 5. R3 has none. *Default: add the gates for Act I.*
14. **Resin feeds Marks** (1 resin = 25 Marks), a new feed beside "a spare copy adds 100". *Default: add it.*

**The names**

15. **Gate 3.** Three of the brief's foes fail the Linter: *Ash-Gremlins* (goblin kin), *Tide-Wraiths* (the undead) and *Sap-Elementals* (a textbook word). Suggested: Ash-Grigs, Tide-Wights (Weald-Wight is already approved), Sap-Boggarts. *Default: the brief's names, pending your call.*
16. **The grey.** The Un-Inking is treated as the First-Quiet's work: Old-Hob scratching out the Maker-Ink. *Default: one antagonist.*
17. **Invented for this script:** Hob's daughter Wren and her ferry to The Crown, the Stag's name Elderhart, the four grove fights, Nokes's icing portrait, the Iron-Man's "MEND". *Default: keep; change freely.*
18. **Book echoes.** Nokes, Alf, Tenar, the star in the cake and Q04's title echo published books by Tolkien, Le Guin and Cooper. Every line and the plaque verse here are original; none is quoted. Fine for the family's own game. Rename before any public release. *Default: keep for the family build.*

---

## 10. What a build of this would reuse

Nothing above is built. These pieces already exist and fit:

| Need | Already in the game |
| :-- | :-- |
| Calms, Ink-Drops, refills | `GrimoireRules.well_depth`, `GrimoireRules.ink_cost`, `CombatDirector.refill_ink`, `StatsComponent.add_ink` |
| The Hearth-Rite hold (calm, pour, finishers) | `InputComponent.hearth_rite_held`, `hearth_rite_progress()` |
| The Iron-Man's seal | docs/15's Maker-Seal on Furrow Iron-Men (`HobSpectrumComponent`) |
| Boss phases, breaks, gates | `BossEncounterResource`, `BossGateComponent`, `PostureEscalationComponent`, `BracedGuardComponent` |
| Telegraphs | `RaidTelegraphDecal` (RED_AVOID, GOLD_STACK, GREEN_HEAL, BLUE_BEHIND_TANK) |
| Card unlocks on screen | `CardReveal` ("A NEW CARD!"), `CardSparkle`, `DiamondGuide` |
| Benches | `ScriberyStation` (a second one in the wright's yard), the Gilding Press, Ink-Binding Marks |
| Chime-post rule | `ChimePost.LOADOUT_REACH` (14 m) |
| World flags | `CalderaWorldState`: `wheel_stopped`, `root_sanctum_cleared`, `ebb_unlocked` |
| The sea falling | `CalderaWorldState`'s sea level and `EbbCinematic` (Q04 needs a timed version) |
| Music cue | `AudioDirector` mosaic decks, `MusicMoodEngine`, `playback.switch_to_clip`, `tools/build_audio_stems.py` |
| Faces warming | `HeroAppearanceResource.cheek_flush` on townsfolk (`StorybookFigure`) |

**Not in the game yet:** a quest log or quest state, NPC dialogue boxes, the Metronome Pendulum, the amber health bar, the Tidal Horologium, a timed ebb, the Root-Sanctum's own chambers, and the Stag.
