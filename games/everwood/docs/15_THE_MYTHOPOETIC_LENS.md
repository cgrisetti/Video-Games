# 15_THE_MYTHOPOETIC_LENS.md — The First-Quiet, The Four Linter Laws & Multi-Zone Ecology

**Status:** Canonical Post-Phase 10 World & Antagonist Spine Specification  
**Paired Systems:** `01_VISION.md`, `02_COMBAT_GDD.md`, `06_WORLD_AND_CALLINGS.md`, `08_EVERGREEN_DEV_BIBLE.md`, `13_STARTING_ZONE_ENCOUNTER_DESIGN.md`, `14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md` (The Lantern's Promise)  
**Track Isolation:** Governs World Lore, Antagonist Taxonomy, Philological Linter Rules, `EnemyAIController` Hob-to-Boggart States, `ActorVisuals` Procedural Silhouettes, and `CrossGrimoireHUD` Rhyme Diagnostics. Zero collision with Phase 11 Landblock Streaming (`10_WORLD_ARCHITECTURE.md`).

---

## 1. THE TRIUMVIRATE LENS: SYNTHESIZING LE GUIN, COOPER, MIYAZAKI & WILLIAMS

Everwood rejects the two bankrupt tropes of commercial fantasy: **biological determinism** (where an entire species such as Orcs or reptilian lizard-brutes is coded as intrinsically evil) and **disembodied sky-laser malice** (where a faceless dark lord projects corruption from a distant tower). Instead, our world is authored through **The Triumvirate Lens**—combining Ursula K. Le Guin, Susan Cooper, and Hayao Miyazaki, with Tad Williams governing folkloric biology.

### 1.1 Ursula K. Le Guin: Making vs. Un-Making & Domestic Stewardship
- **The Language of the Making:** In Le Guin's *Earthsea*, speaking a thing's true name defines its boundary and holds it in cosmic balance. Beneath the named world dwell the *Nameless Ones* (*The Tombs of Atuan*)—ancient, blind geological pressures that existed "before light, and would be after".
- **Heroic Stewardship:** Following *Tehanu* and *Tales from Earthsea*, heroism is not grand military conquest; it is the quiet, resilient daily work of **domestic stewardship**—planting heirloom orchards, mending dry-stone walls, lighting the evening lantern, and keeping the homestead warm against primordial entropy.

### 1.2 Susan Cooper: Nursery Rhymes as Tactical Survival Guides
- **Folklore as Historical Record:** Drawing from *The Dark Is Rising* and *Silver on the Tree*, the skipping rhymes, weather proverbs, and seasonal rituals that adults dismiss as fairy tales are literal, coded diagnostic guides left behind by earlier stewards.
- **The Sleepers & The Seals:** The hills and valleys hold ancient *Sleepers* kept in slumber by tangible elemental *Seals* and *Signs*. When a child sings a village rhyme on the green, they are reciting the exact combat counter-play required when a local Seal cracks.

### 1.3 Hayao Miyazaki: Animism, Broken Etiquette & Turning Boggart
- **A Crowded Moral Ecology:** Nature is a living social space populated by *genius loci*—spirits of river, soot, stone, and hedgerow. Monsters are never grotesque biological punching bags; they possess uncanny storybook majesty governed by folkloric etiquette.
- **The Hob-to-Boggart Spectrum:** Rooted in Derbyshire, Lancashire, and Cornish tradition, a domestic **Hob**, **Brownie**, or **Bucca-Gwidden** (White Bucca) remains a gentle helper as long as the household maintains stewardship and hearth-etiquette. When etiquette is broken or a `Maker-Seal` cracks, that same spirit **"turns boggart"**—swelling into a wild **Boggart**, **Bucca-Dhu** (Black Bucca), or **Spriggan** obsessed with un-making human handiwork.

### 1.4 Tad Williams: Environmental Mimesis (*The Crack-Born*)
- **The *Tinukeda'ya* Principle:** Adapting Tad Williams's *Tinukeda'ya* ("Ocean Children" / Changelings in *Memory, Sorrow, and Thorn*), who physically grow to resemble the terrain they inhabit (*Niskies*, *Kilpa*, *Dwarrow*, *Bukken*, *Hunën*), Everwood has zero separate biological "monster races".
- **Geological Texture:** When pre-creative essence seeps through a fissure in the earth, it takes on the exact physical material of that boundary: salt-shingle and sea-swallow feathers in coastal caves (**Scrays**), greywacke granite and heather on highland tors (**Cairn-Drakes**), and rusted plough-iron in tilled meadows (**Furrow Iron-Men**).

### 1.5 The Musk Razor: One Unified Systemic Origin (`The First-Quiet`)
- **What We Cut:** All bandit syndicates, necromancer cults, dark elf cabals, orc clans, lizard armies, and *World of Warcraft* murloc/kobold/trogg analogs are permanently excised.
- **What Remains:** Every antagonist in Everwood originates from **The First-Quiet** (called **The Deep-Hush**, **The Old-Sleep**, or **The Un-Making** by villagers). Before settlers built bridges, ploughed furrows, and rang chime-bells, the world was un-named and fast asleep. Whenever stewardship falters or a boundary seal wears thin, the original un-shaped essence of the earth rises through geological cracks—sea caves, mountain crags, bog-holes, and plough-furrows—to smooth noisy human cultivation back into silent, trackless slumber.

---

## 2. PHILOLOGICAL LINTER LAWS & CANONICAL LEXICON

In a world anchored by the *Language of the Making*, clear, joyful naming is what keeps the homestead awake. Every identifier, UI string, item, settlement, and creature name must pass all four studio Linter Rules:

1. **Rule 1 — The 8-Year-Old Read-Aloud Rule:** Every word must roll off a child's tongue effortlessly on the first read with a smile, using alliteration, rhyme, or tactile rhythm. Unpronounceable, apostrophe-heavy fantasy nouns are strictly forbidden.
2. **Rule 2 — The Map-Sense Compound Rule:** Every settlement and landmark must pair a warm cultural or sensory syllable with one of seven geographical nouns (`-bridge`, `-green`, `-hollow`, `-falls`, `-haven`, `-wick`, `-crossing`) so players instantly know where it sits in the watershed without a minimap.
3. **Rule 3 — Hyphens & Cadence Keep Heritage Alive:** Preserve playful, rhythmic folkloric compounds (`Tizzi-Wed-Green`, `Gull-Wick-Haven`, `Old-Hob-of-the-Hill`, `Barrow-By-Night`) rather than flattening them into sterile corporate portmanteaus (*Tizwell*, *Barrowknight*).
4. **Rule 4 — Ban Grimy/Textbook Words:** Purge clinical, bureaucratic, or gritty medieval terminology (*Wharf, Silt, Polder, Lamellar, Hauberk, Rubric, Aspect, Construct, Rune, Faction, Trash Mob, Aggro, Loot Drop*) and replace them with storybook words (**Green, Bridge, Meadow, Mantle, Coat, Sign, Ink, Seal, Iron-Man, Kin, Weald-Wight, Cairn-Trove**).

### 2.1 Canonical Linter Conversion Matrix
| Category | Banned Textbook / Grimy Term | Canonical Everwood Storybook Term | GDScript / Engine Identifier |
|:--- |:--- |:--- |:--- |
| **Antagonist Origin** | Primordial Entropy Faction | **The First-Quiet** / **The Deep-Hush** | `SpiritOrigin.FIRST_QUIET` |
| **Primary Antagonist** | Dark Lord / Necromancer | **Old-Hob-of-the-Hill** (*The Flitting-Man*) | `ActorType.OLD_HOB` |
| **Field Automaton** | Enchanted Iron Construct | **Furrow Iron-Man** (*Plough-Giant*) | `ActorType.FURROW_IRON_MAN` |
| **Coastal Spirit** | Murloc / Reptilian Raider | **Sea-Cave Scray** / **Gale-Bucca** | `ActorType.SEA_SCRAY` |
| **Highland Guardian** | Wyvern / Rock Elemental | **Cairn-Drake** / **Tor-Sleeper** | `ActorType.CAIRN_DRAKE` |
| **Lowland Spirit** | Trash Mob / Imp | **Weald-Wight** / **Hedgerow-Hob** | `ActorType.WEALD_WIGHT` |
| **Magic Writing** | Magic Runes / Arcane Rubric | **Maker-Signs** / **Deep-Ink** / **Old-Seals** | `is_maker_seal_upright: bool` |
| **Armor & Attire** | Lamellar / Hauberk / Cuirass | **Ring-Coat** / **Wool-Mantle** / **Kettle-Cap** | `EquipSlot.MANTLE`, `EquipSlot.COAT` |
| **Coastal Settlement** | Silt-Wharf / Salt-Polder | **Gull-Wick-Haven** / **Tizzi-Wick** | `ZONE_GULL_WICK_HAVEN` |
| **Farmland Settlement**| Lowland Polder / Till-Rubric | **Tizzi-Wed-Green** / **Barley-Bridge-Meadow**| `ZONE_BARLEY_BRIDGE_MEADOW` |
| **Highland Settlement**| Scree-Outpost / Crag-Aspect | **Barrow-Crag-Crossing** / **Barrow-Hollow** | `ZONE_BARROW_CRAG_CROSSING` |
| **Wetland Settlement** | Mire-Wharf / Silt-Fen | **Rush-Light-Hollow** / **Moss-Falls** | `ZONE_RUSH_LIGHT_HOLLOW` |

---

## 3. THE PRIMARY ANTAGONIST: THE DEEP-HUSH & OLD-HOB-OF-THE-HILL

To avoid both a disembodied sky-villain and a generic armored warlord, Everwood pairs a sympathetic planetary force with an intimate, wandering folkloric figure.

### 3.1 The Systemic Force: The Deep-Hush
Before the first word of the *Making* was spoken, the world rested in **The Deep-Hush**—a seamless, dreamless stillness where sea, stone, and sky had no names and no walls. To the Deep-Hush, human sub-creation (hammering iron, ploughing straight furrows, ringing bronze chime-bells, and naming hollows) feels like a bright lantern shining into the eyes of an exhausted sleeper. **The Deep-Hush does not hate humanity; it pities humanity's exhausting busyness and wishes to tuck the noisy world back into bed**.

### 3.2 The Embodied Vessel: Old-Hob-of-the-Hill (*The Un-Namer* / *The Flitting-Man*)
- **Folkloric Origin:** Synthesizes Lancashire's **Owd Hob** (master of boggarts), the British **Cunning Folk** tradition, Susan Cooper's *Walker on the Track*, and Le Guin's *Cob*.
- **Backstory:** In the early days of settlement, Old-Hob was the very first domestic *Hob* befriended by humans—the spirit of the first hearth who taught settlers how to stack dry-stone walls, smelt bog-iron, and sing the sea-caves quiet. As generations grew louder, busier, and forgetful of thank-offerings, Old-Hob experienced "turning boggart" on a mythic scale. Heartbroken by humanity's noise and short memory, he concluded that *Making* had failed and that land and folk alike would be happier returned to the *First-Quiet*.
- **Visual Silhouette (`4.8m` Camera Readability):** A tall, stooped hedgerow-tinker wearing a patchwork mantle of dried moss, white gull-feathers, and rusted kettle-links, carrying a crooked staff of un-peeled blackthorn and an empty, unlit iron lantern.
- **World Behavior & Encounter Loop:**
  - Walks the sunken lanes ("the track") between zones during twilight and fog ("the chime hours").
  - Speaks politely in riddles and nursery rhymes at stiles and crossroads, urging families to lay down their tools, forget their names, and *"flit"* (pack their carts and leave the homestead to the brambles).
  - With a quiet tap of his blackthorn staff, he scratches out the `Maker-Ink` on boundary stones—waking **Cairn-Drakes**, calling **Scrays** from the caves, and turning buried **Iron-Men** backward.
  - **Non-Lethal Climax (`Sunken-Crown-Falls`):** Players never decapitate or slaughter Old-Hob; they unite the Six Elemental Seals via cooperative Four-Sign Detonations and `Soul Tether` harmony to speak his true hearth-name, *un-boggarting* him back into the Guardian of the Threshold.

---

## 4. THE THREE FLAGSHIP ANTAGONIST PILLARS (LORE TO GODOT 4.7 COMBAT MATH)

Each flagship antagonist family emerges from a specific geological fissure, targets a specific pillar of village stewardship, and resolves through **un-boggarting / re-sealing** rather than gory corpses.

### 4.1 Pillar 1: The Sea-Cave Scrays (`Gull-Wick-Haven` & `Tizzi-Wick`)
- **Etymology & Folklore:** Fuses the archaic British dialect **scray** (the common tern or sea-swallow, *Sterna hirundo*, famed for hovering like a white butterfly before plunging like a spear into the surf) with the Cornish **Bucca-dhu** (dark sea-cave spirit of coastal *fogous* and gales) and Tad Williams's ocean-born *Kilpa* and *Niskies*.
- **Visual Silhouette (`ActorVisuals` — `ActorType.SEA_SCRAY`):** Zero frog-man or lizard traits. Walks upright on land like a hunched lantern-snuffer wrapped in a boatman's mantle of wet blue slate, barnacles, and overlapping shingle-feathers. Features round phosphorescent yellow saucer-eyes and a split-flint bill. When lunging or casting a gale-wave, its mantle snaps open into wide, fork-tailed sea-swallow wings (`3.2m` wingspan).
- **Ecological Behavior:** Sleeps in booming blow-holes and flooded sea caves. Agitated by cliff-top cottage lamps, harbour bell-buoys, and stone breakwaters. **Shingle-Scrays** skitter onto piers to peck mortar from stone bridges, untie skiffs, and snuff torches with wet salt-spray, while towering **Gale-Buccas** summon sea-fret and rogue waves to wash out coastal gardens.
- **Godot 4.7 Combat & Frame Math:**
  - **Dread-Chill Mist:** Scray squalls project `in_dread_chill = true`. Straying solo (`>8.0m` from party) narrows the player's Flow-Link recovery window from `14 frames` (`0.233s`) to **`9 frames`** (`0.150s`) and reduces Posture regen to **`0.65x`**.
  - **The Lantern's Promise Counter:** Holding within `<=5.5m` of a Lantern-Bearer (`Bell-Keeper`, `Wind-Mender`, `Lantern-Scribe`) or inside `Shadow Sanctuary` burns away the sea-scum fog, expanding Flow-Link windows to **`18 frames`** (`0.300s`), boosting Posture regen to **`1.25x`**, and illuminating the `Glimmer-Spot` beneath the Scray's open wing-mantle.
  - **Un-Boggarted Resolution (`STATE_UNBOGGART_RELEASE`):** Breaking a Scray's posture dissolves its slate-and-foam mantle in a burst of Sea-Azure sparks, releasing a harmless white sea-swallow (*Sterna hirundo*) that wheels into the sky with a bell-like cry while leaving `Chimes` and `Salt-Glass` on the shingle.

### 4.2 Pillar 2: The Cairn-Drakes (`Barrow-Crag-Crossing` & `Barrow-Hollow`)
- **Etymology & Folklore:** Draws from British megalithic folklore of petrified giants, Cornish **Spriggans** guarding dolmens and barrows, Andrew Lang's ancient "stone beasts", and Le Guin's primordial Earthsea dragons who share the bones of the earth.
- **Visual Silhouette (`ActorVisuals` — `ActorType.CAIRN_DRAKE`):** Not a winged gold-hoarding lizard; it *is* the mossy boulder-ridge waking up. A heavy, six-legged drake of segmented greywacke stone, tangled gorse-roots, and silver lichen, crowned along its spine with a 3-tier stacked dry-stone **Cairn Capstone** (`Stone-Seal`). Eyes glow like slow peat-embers in granite sockets. Accompanied by badger-sized **Scree-Worms** and plateau-sized **Tor-Sleepers**.
- **Ecological Behavior:** Driven by **topographical smoothing**—disturbed by straight dry-stone sheep-walls, mile-markers, quarry-picks, and bronze sheep-bells. Butts its granite brow against walls and bridges until they collapse into scree, and exhales cold *Barrow-Rime* to put shepherds to sleep while overgrowing roads with heather.
- **Godot 4.7 Combat & Frame Math:**
  - **Slumber & 45-Frame Challenge-Roar:** Rests disguised as terrain in `STATE_SLUMBER`. Approaching triggers a deterministic **`45-frame` (`0.75s`) `STATE_CHALLENGE_ROAR`**.
  - **The Hearth-Rite Bravery Counter:** Answering the `45-frame` roar with a prepared **Hearth-Rite Tuck** (`SIGN_IRON_ROOT` *Shatterpoint* `60.0` poise damage) + Wayfarer **Bravery Counter** (`45.0` posture damage) inflicts **`105.0` Instant Posture Damage**, restores **`+25.0` Party Stamina**, and illuminates the spine's **Cairn Capstone** (`glimmer_spot_active = true`) in Twilight-Violet for `6.0s`.
  - **Un-Boggarted Resolution (`STATE_LULLED_CAIRN`):** Breaking posture and re-stacking the `Stone-Seal` capstone transitions the drake into a permanent `StaticBody3D` moss-covered boulder cairn—creating climbable vantage terrain and a permanent wind-break where the family can channel a new `Hearth-Rite Tuck` safe from high-crag `Dread-Chill`.

### 4.3 Pillar 3: The Furrow Iron-Men (`Barley-Bridge-Meadow` & `Tizzi-Wed-Bridge`)
- **Etymology & Folklore:** Translates "enchanted iron constructs with runes" via Linter Rule 4 into **The Furrow Iron-Men** (plus clanking **Chain-Hounds** inspired by the *Boggart of Longar Hede* and **Scythe-Stalkers**), drawing from Ted Hughes's 1968 fairy tale *The Iron Man*, Cooper's elemental *Sign of Iron*, and Miyazaki's garden automatons.
- **Backstory:** Forged ages ago by the first smiths to help clear briars and plough heavy clay, stamped on the chest with warm `Maker-Seals` in `Deep-Ink`. Over centuries of peace, they rusted and sank beneath the meadows. Down in the wet soil, **The First-Quiet** corroded and inverted their `Maker-Seals` upside-down into *Signs of Un-Tilling*.
- **Visual Silhouette (`ActorVisuals` — `ActorType.FURROW_IRON_MAN`):** A walking antique farmyard: a riveted iron cauldron torso housing an internal firebox grate, curved scythe-blade and plough-share shoulders, an inverted church-bell kettle-helm with two glowing coal-slit eyes, wrought-iron fence legs, and a high-contrast chest **Maker-Seal** decal.
- **Ecological Behavior:** Not malicious; their state machine is literally running backward. They march in mechanical straight lines pulling up fence-posts, un-ploughing neat furrows into rough clods, eating iron barn-hinges to patch their rust, and planting iron-thorn brambles across wheat fields.
- **Godot 4.7 Combat & Frame Math:**
  - **Riveted Armor Mitigation:** Un-tucked standard weapon slashes suffer a **`50%` damage penalty** (`0.50x`) and deflect with a dull kettle-clank.
  - **"Feed Him a Coal" (`SIGN_WARM_HEARTH` Synergy):** Casting or detonating `SIGN_WARM_HEARTH` (Saffron-Gold) or striking with an active **Hearth-Rite Tuck** ignites the cauldron belly's firebox grate, melting bog-rust and opening the chest plate to expose the inverted `Maker-Seal` (`glimmer_spot_active = true`).
  - **"Turn the Seal Right-Way" (18-Frame Flow-Link Re-Stamp):** Striking the exposed chest `Glimmer-Spot` with a directional attack or `SIGN_IRON_ROOT` during an `18-frame` Flow-Link physically rotates the procedural `Deep-Ink` seal mesh **`180°` upright** (`is_maker_seal_upright = true`).
  - **Un-Boggarted Resolution (`STATE_STEWARD_HELPER`):** Once its posture breaks with the seal upright, the Iron-Man bows its kettle-helm with a cheerful steam-whistle, drops a cache of `Chimes`, and enters `STATE_STEWARD_HELPER` for **`600.0s` (`10 minutes`)**—marching alongside the party to crush bramble barricades, lift fallen bridge timbers, and plough furrows before sinking peacefully back into the turf.

---

## 5. HOLISTIC SIX-ZONE WORLD ATLAS & NURSERY RHYME DIAGNOSTICS

Every zone obeys the **Map-Sense Compound Rule** and pairs its regional **Cooper Sign** with a spoken village nursery rhyme that functions as a live combat diagnostic on the bottom ribbon of `CrossGrimoireHUD`.

| Zone Name (Map-Sense Compound) | Governing Sign & Scribe Harmony | The Crack in the World | Awakened Antagonist Kin | Regional Nursery Rhyme (`CrossGrimoireHUD` Diagnostic Couplet) | Un-Boggarting & Stewardship Payoff |
|:--- |:--- |:--- |:--- |:--- |:--- |
| **1. `Tizzi-Wed-Green`** | **Sign of Wood** (`SIGN_WARM_HEARTH` + `SIGN_IRON_ROOT`) | Hollow oak roots, loose cellar flagstones, dry-stone stiles. | **Boggart-Kin**, **Nut-Nans**, & **Hedgerow-Hobs**. | *"Lift the flagstone, sweep the floor, / Leave the cream beside the door; / Name the Boggart, lose the plough, / Tizzi-Wed is flitting now!"* | **1-Button Gambit Assist Parley:** Within `6.0m` (`180-frame` window), casting the matching Truce-Sign soothes Hobs into dancing helpers (`+25 Chimes`, `+1.0 Pip`, `+15.0 Max Poise`). |
| **2. `Gull-Wick-Haven`** | **Sign of Water** (`SIGN_RIME_GALE` + `SIGN_STAR_TIDE`) | Flooded Cornish *fogous*, sea-caves, booming tide-wells. | **Sea-Cave Scrays**, **Shingle-Scrays**, & **Gale-Buccas**. | *"When the Scray comes out of the cave, / Hide the lantern, bar the wave; / Ring the bell on Gull-Wick-Green, / Or the bridge will never be seen!"* | **Singing the Tide Down:** `The Lantern's Promise` (`<=5.5m`) clears `Dread-Chill` (`18f` Flow-Link); breaking posture releases white sea-swallows (`Sterna hirundo`). |
| **3. `Barley-Bridge-Meadow`** | **Sign of Iron** (`SIGN_WARM_HEARTH` $\rightarrow$ `SIGN_IRON_ROOT`) | Deep plough-furrows, bog-iron pits, rusted ditch-drains. | **Furrow Iron-Men**, **Chain-Hounds**, & **Scythe-Stalkers**. | *"Deep in the furrow the Iron-Man sleeps, / Under the barley the rust-kettle creeps; / Turn the Seal right-way and feed him a coal, / Or he'll eat up the bridge and the miller's whole toll!"* | **Re-Stamping the Seal:** `SIGN_WARM_HEARTH` ("feed him a coal") exposes the chest seal; an `18f` Flow-Link `SIGN_IRON_ROOT` strike flips it `180°` into `STATE_STEWARD_HELPER`. |
| **4. `Rush-Light-Hollow`** | **Sign of Fire** (`SIGN_WARM_HEARTH` + `Shadow Sanctuary`) | Bottomless peat-hags, marsh gas-vents, drowned trunks. | **Wisp-Boggles**, **Lob-Clouds**, & **Greetin-Bairns**. | *"Follow the lantern that dances on peat, / Down in the Hollow where bog-waters meet; / Light the true candle of tallow and twine, / Or Lob-in-the-Raincloud will drink up the Sign!"* | **Keeping the Path-Lights:** `Soul Tether` anchors players against bog-pulls; *Dawnburst* (`30.0 HP` Hearth-Rite heal) condenses *Lob-Clouds* into warm tallow path-lanterns. |
| **5. `Barrow-Crag-Crossing`** | **Sign of Stone** (`SIGN_IRON_ROOT` + `SIGN_STAR_TIDE`) | Prehistoric barrows, split granite tors, old tin-shafts. | **Cairn-Drakes**, **Scree-Worms**, **Tor-Sleepers**, & **Crag-Spriggans**. | *"Count the stones upon the hill, / Nine stand up and one lies still; / If the tenth begins to crawl, / Stack the cairn and mend the wall!"* | **Waking & Lulling the Hill:** Answering the `45f` `STATE_CHALLENGE_ROAR` deals `105.0` posture damage; breaking posture lulls the drake into a climbable `STATE_LULLED_CAIRN` wind-break. |
| **6. `Sunken-Crown-Falls`** | **Sign of Bronze** (All Four Scribe Signs Converged) | **The First-Crevice** at the Great Cataract. | **Old-Hob-of-the-Hill**, **The Un-Named**, & **Deep-Hush Hunën**. | *"Six Signs joined upon the track, / Turn the Long Un-Making back; / Speak the name that warms the stone, / None shall go into the dark alone."* | **The Great Re-Naming:** Full-party Four-Sign Detonation along the `Soul Tether` restores Old-Hob's true hearth-name, transforming him from the Flitting-Man into Threshold Guardian. |

---

## 6. SYSTEMIC GAMEPLAY INTEGRATION (ZERO-MENU STEWARDSHIP)

To honor `01_VISION.md` and `08_EVERGREEN_DEV_BIBLE.md`, the Mythopoetic Lens introduces zero pause-menu bestiaries, zero quest-log text walls, and zero extra controller buttons.

### 6.1 The Hob-to-Boggart Equilibrium (`EnemyAIController`)
Every spirit actor stores an `equilibrium_state` enum (`HOB_BENIGN` vs. `BOGGART_AWOKEN`):
- **`HOB_BENIGN` (`STATE_CURIOUS`):** When a region's `Maker-Seals` are intact, spirits appear in their small, whimsical forms (*Hedgerow-Hobs*, *Bucca-Gwidden*, *Scree-Piskies*). Entering the `6.0m` Parley Threshold opens a `180-frame` (`3.0s`) window where pressing **1-Button Gambit Assist** waves the matching Scribe Sign, triggering a joyful dance and awarding `+25 Chimes`, `+1.0 Resonance Pip`, and `+15.0` temporary Max Poise.
- **`BOGGART_AWOKEN` (`STATE_SLUMBER` $\rightarrow$ `STATE_CHALLENGE_ROAR` / `STATE_HOSTILE`):** Where Old-Hob-of-the-Hill has scratched out a boundary seal—or inside deep delves—spirits manifest as **Scrays**, **Cairn-Drakes**, and **Furrow Iron-Men**.
- **Zero-Gore Un-Boggarting:** Reaching `0.0` HP or full Posture Break never spawns a bloody corpse. It routes deterministically to `STATE_UNBOGGART_RELEASE` (sea-swallow flight), `STATE_LULLED_CAIRN` (climbable wind-break boulder), or `STATE_STEWARD_HELPER` (`10-minute` allied plough-helper).

### 6.2 Chime-Post Rhyme Ribbons in `CrossGrimoireHUD`
When the party passes a threshold stile or channels a `120-frame` **Hearth-Rite Tuck** outside a delve, a single couplet of the regional nursery rhyme unfurls cleanly along the bottom ribbon of `CrossGrimoireHUD`:
- Key action words in the verse dynamically tint with their matching Scribe Sign color:
  - *"feed him a coal"* $\rightarrow$ Tinted **Saffron-Gold** (`SIGN_WARM_HEARTH`).
  - *"Turn the Seal right-way"* / *"Stack the cairn"* $\rightarrow$ Tinted **Amber/Ochre** (`SIGN_IRON_ROOT`).
  - *"bar the wave"* $\rightarrow$ Tinted **Sea-Azure** (`SIGN_RIME_GALE`).
  - *"Ring the bell"* / *"warm the stone"* $\rightarrow$ Tinted **Twilight-Violet** (`SIGN_STAR_TIDE`).
- A parent reading the couplet aloud on the couch naturally coaches a 4-year-old co-op player on which Sign card to tuck before crossing the threshold.

### 6.3 3x3 Calling Matrix Hooks Against The First-Quiet
- **The Shield-Sworn (`Bridge-Warden`, `Weald-Captain`, `Hearth-Guard`):** Can anchor their stance against a **Gale-Bucca**'s rogue wave or a **Cairn-Drake**'s boulder-charge, preventing `Soul Tether` knockback and projecting the `0.80x` stamina-cost **Bravery Aura** while holding a Hearth-Rite Tuck.
- **The Wayfarers (`Iron-Woodsman`, `Hedge-Runner`, `Sign-Seeker`):** Execute the `45-frame` **Bravery Counter** against waking **Cairn-Drakes** and **Furrow Iron-Men**, and can vault directly onto a `Cairn-Drake`'s mossy flank to strike its spine `Stone-Seal`.
- **The Lantern-Bearers (`Bell-Keeper`, `Wind-Mender`, `Lantern-Scribe`):** Passively project **The Lantern's Promise** (`5.5m` radius) to burn away **Scray** `Dread-Chill` sea-fret, illuminate **Glimmer-Spots**, and ring harmonic chime-chords that "sing the tide down" in `Gull-Wick-Haven`.
---

## 7. Build Notes (Pass 1: the docs and the back end)

What the game does today, where it differs from §1–6, and what Pass 2 does next. Pass 1 changed no landblock geometry, terrain or quest layout; it renamed what players read and added the spectrum's state hooks.

**In the code now**
- **The Hob-to-Boggart Spectrum** (`src/combat/hob_spectrum_component.gd`, on every foe: the woodland kin, Oakshire's spirits and the Cairnsman). `EquilibriumState` (`HOB_BENIGN`, `BOGGART_AWOKEN`), `SpiritState` (`STATE_CURIOUS`, `STATE_SOOTHED`, `STATE_SLUMBER`, `STATE_CHALLENGE_ROAR`, `STATE_HOSTILE` and the three resolutions), `UnboggartResolution` (`STATE_UNBOGGART_RELEASE`, `STATE_LULLED_CAIRN`, `STATE_STEWARD_HELPER`), `ReleaseForm` and `is_maker_seal_upright`. Each variant's place on the spectrum is data on `MobVariantResource`.
- **Parley** (§6.1). A curious hob's `ParleyPoint` gives any hero within `6.0m` a `180-frame` window; `Light` (the Squire Gambit's one button) waves the Truce-Sign. The hob dances (`STATE_SOOTHED`), the host adds `25` Chimes, the hero gets `1.0` pip, and a soothed hob stays out of its pack's fights. Striking a curious hob turns it boggart.
- **Un-Boggarting** (§6.1, `src/combat/unboggart_fx.gd`). Padfoot Boggarts fly off as white sea-swallows; Bramble-Hobs (both kinds) and Weald-Wights as hedge-wrens; Wisp-Boggles rise as warm path-lights; Crag-Spriggans and the Crag-Back Cairn-Drake curl into mossy cairns (`30s`); the Cairnsman's cairn stays for good. Bodies still sink away as before, so nothing is left lying.
- **The Maker-Seal** (§4.3). Oakshire's three Furrow Iron-Men wear an upside-down seal (`▼` on the chest). A strike carrying `SIGN_WARM_HEARTH` (a card, a primer or a Hearth-Rite or Sign-Flow coat) opens it for `6.0s`; a strike carrying `SIGN_IRON_ROOT` while it's open turns it `180°` upright (`▲`). Beaten upright, the Iron-Man bows and stands as a friendly steward for `600s`; beaten upside-down, he sinks back into the furrow to sleep.
- **The Challenge-Roar** (§4.2). The Crag-Back Cairn-Drake bellows a `45-frame` roar when it wakes and holds its first blow through it.
- **The atlas and the ribbon** (§5, §6.2). `MythopoeticAtlas` registers the six zones (`StewardshipZoneResource`) and each built place's zone; each level names its arrival place. Crossing into a new zone, or finishing a Hearth-Rite Tuck, unfurls a couplet on `CrossGrimoireHUD`'s Chime-Post ribbon with its coaching words tinted by Sign, and a Saffron-Gold ember border rims the cell while the Tuck is held.
- **The Hearth-Rite Tuck** is `120 frames` (`80` on a Star-Inked Vellum leaf), up from Phase 12's `90` (and `60`), as §6.2 and the Pass 1 brief say.
- **The Linter in code.** `tools/test_mythopoetic_lens.gd` (run by the smoke test) checks every name, blurb, quest and rhyme the game shows against Rule 4 and the cut tropes, and every settlement, zone, delve and Place-Card against Rules 2 and 3.

**Rename ledger** (display names only; every id that saves, scenes or RPCs carry is unchanged)

| Was | Is now | Kept id or file |
|---|---|---|
| Bramblebridge / Bramblebridge Green | Bramble-Bridge / Bramble-Bridge Green | `hub_town`, `--instance=bramblebridge`, `bramblebridge_green` |
| Oakshire Commons / the Kindled Bivouac | Honey-Wick / the Kindle-Fire | — |
| The Bramble-Reach (the seamless world) | Tizzi-Wed-Green | `everwood_world` |
| The Ariundle Moss-Oaks | Moss-Oak Hollow | `loc_ariundle_moss_oaks` |
| The Sunken Holloway | Rush-Light-Hollow | — |
| The Doverslap Gorge Bridge / the gorge | Doverslap Bridge / Doverslap Falls | `loc_doverslap_gorge`, `DoverslapLayout` |
| Sinaya Gatehouse | the Doverslap Gatehouse | `doverslap_gatehouse` |
| The Doverslap Expedition / The Cairnsman of Doverslap | The Doverslap Falls Expedition / The Cairnsman of Doverslap Falls | `dungeon_dojo`, `cairnsman` |
| Bramble Camp / Holloway Camp | Bramble Hush-Crack / Rush-Light Hush-Crack | `MinionCamp`, `camp_bramble` |
| Bramble-Scuttler / Bog-Imp | Bramble-Hob / Wisp-Boggle | `WoodlandMinion`, `scuttler`, `bog_imp` |
| Rune-Plates | Maker-Seal Plates | `RunePlate`, `CoopGate.Method.RUNE_PLATES` |
| Hearth-Linen / Ranger Leather / Ironwood Plate | Hearth-Linen Coat / Hedgerow Wool-Mantle / Iron-Wood Ring-Coat | `hearth_linen`, `ranger_leather`, `ironwood_plate` |
| rune bolts / rune arrows | Sign-bolts / Sign-arrows | `RuneProjectile` |
| Barrow-Crag Star-Tor (Place-Card) | Barrow-Crag-Crossing | `loc_barrow_crag_tor` |
| Old Hob of the Barrow | Old-Hob-of-the-Hill | `old_hob` |
| Oakshire Village · Wayfarer's Glade · The Orchard Reach · The East Quarry · The Bramble Weald · The Barrow Hills | Oakshire-Wick · Wayfarer-Green · Pippin-Green · Quarry-Wick · Bramble-Hollow · Nine-Stones-Crossing | `OakshireValeLayout.Petal` |
| The Smuggler's Root-Cellar · The Gloom-Vein Iron Mine · Hollow-King's Barrow · The Tangled Root-Sanctum | Flagstone-Hollow · Iron-Kettle-Hollow · Star-Barrow-Hollow · Tangle-Root-Hollow | `d3_root_cellar`, `d1_gloom_vein_mine`, `d2_hollow_kings_barrow`, `r1_root_sanctum` |
| Meadow Vermin · Weald Predators · Soot-Paw Outlaws · Blight-Thorn Briarlings · Tarnished Chime-Wights | Curious Weald-Wights · Padfoot Boggarts · Furrow Iron-Men · Bramble-Hobs · Crag-Spriggans | every variant id (`cider_thief_bristleboar`…) |
| The Crag-Back Behemoth | The Crag-Back Cairn-Drake | `crag_back_behemoth` |
| Card finishes `SHINY_FOIL` / `ASTRAL_PRISM` | `CardVariant.GILDED_LEAF` / `STAR_INKED_VELLUM` (Gilded Leaf, Star-Inked Vellum) | save keys `shiny_foil`, `astral_prism` |
| HUD "Aggro: on YOU" | "Eyes on: YOU" | — |

**Deliberate differences from §1–6**
- **Rule 2's noun may sit inside the compound.** The atlas's own *Barley-Bridge-Meadow* ends in *-Meadow*, so the linter asks for one of the seven nouns as any hyphenated part of a name. Rule 2 covers settlements, zones, delves and Place-Cards; a boss arena (the Ring of the Cairnsman), a terrain ring (the Settled Meadow), natural features (the Scribe's Tor, the High Road) and buildings (the Chime-Shrine, the Bridge-Warden's span) keep plain names.
- **Oakshire Vale keeps its name.** It's the game's subtitle and its instance id, so it's read as the vale at the heart of Tizzi-Wed-Green; everything inside it obeys Rules 2 and 3. Every delve is a *-Hollow*, so its name says "go down into it".
- **Oakshire's families are Lens kin in the old bodies.** The brief listed Bramble-Hobs, Wisp-Boggles, Sea-Cave Scrays, Furrow Iron-Men and Cairn-Drakes as the vale's awakened kin. The vale's built creatures were renamed to fit the bodies they already wear (a wolf body is a Padfoot, a humanoid an Iron-Man, a stone-guard a Crag-Spriggan, the patrolling mini-boss a Cairn-Drake); Wisp-Boggles live on the Bramble-Bridge trail, and Sea-Cave Scrays wait for Gull-Wick-Haven.
- **Parley pays Chimes and a pip, not "+15 Max Poise".** Heroes have no poise bar of their own (only foes break), so there is nothing for +15 Max Poise to raise; giving heroes a breakable poise bar would make the gift a weakness. A Creative Director call: a different third reward, or a hero poise bar.
- **The Truce-Sign is the light button near a curious hob**, the same button the Squire Gambit uses for everything, so it needs no new button (08 Gate 2). The hob's window only opens on a fresh approach.
- **The Iron-Man's seal turns on any Iron-Root strike while it's open,** not only inside an `18-frame` Flow-Link, and its `50%` un-tucked mitigation isn't built: Oakshire's Iron-Men keep their Phase 11 mitigation (20–30%).
- **A steward stands still.** He bows and stays friendly for `600s`, but doesn't yet crush brambles, lift timbers or plough.
- **Cairns are scenery, not terrain.** A lulled cairn has no collider yet, so it isn't climbable vantage or a wind-break.
- **`EnemyAIController`, `ActorType` and `SpiritOrigin`** aren't separate classes: the spectrum lives on `HobSpectrumComponent` (composition), bodies are `MobVariantResource.Body`, and every foe's origin is the First-Quiet.
- **Code names keep their old spelling until Pass 2.** Scripts and classes that scenes reference by path (`minion_camp.gd`/`MinionCamp`, `woodland_minion.gd`/`WoodlandMinion`, `rune_plate.gd`/`RunePlate`, `rune_projectile.gd`/`RuneProjectile`), node names inside baked scenes, and the variant, item, card and instance ids stay as they are, so no save, scene or RPC breaks.

**Pass 2 (not built yet)**
- The flagship kin as walking bodies: Sea-Cave Scrays and the Dread-Chill sea-fret, true Cairn-Drakes with the Bravery Counter on their capstone, Furrow Iron-Men with cauldron bodies and a turning seal mesh, and Old-Hob-of-the-Hill walking the sunken lanes at twilight.
- Rebuilt landblocks and quest layouts for the six zones, with Chime-Post engravings, threshold stiles and the Great Re-Naming at Sunken-Crown-Falls.
- Climbable cairns, stewards who help, the Iron-Men's 50% un-tucked penalty and the Tuck's per-Sign empowerments (04 Balance, last table).
- Renaming the old script, class and node names once the scenes that reference them are rebuilt.
