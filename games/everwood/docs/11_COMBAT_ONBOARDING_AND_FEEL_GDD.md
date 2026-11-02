# 11_COMBAT_ONBOARDING_AND_FEEL_GDD.md — Kinetic Combat Loop, Martial Imbuement, & Level 1–10 Trail Progression

## 1. Executive Summary & Design Mandate
This specification upgrades the core combat loop of **Everwood (Oakshire Raids)** to eliminate stationary "turret clicking," make every weapon swing and Scribe Card unmistakable from our $4.8\text{ m}$ split-screen camera eye-line, and replace "endgame gear at Level 1" with an authentic zero-to-hero progression arc from **Bramblebridge Green** to **The Ring of the Cairnsman**.

In strict compliance with **The Musk Razor (`01_VISION.md` & `08_EVERGREEN_DEV_BIBLE.md`)**:
1. **Zero Progressive HUD Locks:** All 6 postures (`Light`, `Heavy`, `Forward+Heavy`, `Back+Heavy`, `L Guard`, `R Skill`, `L+R Ult`, and `D-Pad Soul Tether`) and all four diamonds of the bottom-centered `CrossGrimoireHUD` are $100\%$ active from Level 1.
2. **Zero Floating Arcade Orbs:** Movement is driven organically by root-motion attack steps, Flow-Link stamina recovery windows, and enemy **Braced Front Guard** states that force Tank threat holding and DPS/Mender flanking.
3. **Martial Imbuement ("The Weapon Channels the Card"):** At Level 1, players wield lathe-turned wooden practice weapons and an un-inked grimoire. Pressing `R Skill` ($1\text{ Pip}$) or `L+R Ult` ($3\text{ Pips}$) with no card equipped executes a raw physical **Un-Inked Martial Flourish**. When the player earns their first **Plain Vellum** Scribe Card at Level 3, slotting it into `R Skill` imbues that exact same muscle-memory input with the card's Scribe Sign (`SIGN_IRON_ROOT`, `SIGN_RIME_GALE`, `SIGN_WARM_HEARTH`, or `SIGN_STAR_TIDE`).

---

## 2. Five-Gate Compliance Audit

| Gate ID | Audit Result | Implementation Contract |
|---|---|---|
| **GATE 1: Anti-Parasitic Harmony** | **PASS** | Un-Inked Martial Flourishes, Flank Breaches, and Equipment Tiers feed directly into Stamina/Poise, Resonance Pips, the Four Scribe Signs, the $3 \times 3$ Calling Matrix, and the **Chimes** economy. |
| **GATE 2: The Musk Razor** | **PASS** | Zero new buttons, zero mid-combat menus, zero floating pickup orbs, and zero locked HUD buttons. Early simplicity comes solely from starting with Tier 1 wooden arms and empty vellum slots. |
| **GATE 3: Philological & Whimsy Linter** | **PASS** | Uses tactile Anglo-folk craft terminology: `Turned-Hazel Falchion`, `Split-Ash Broad-Axe`, `Willow-Coppice Longbow`, `Reed-Light Way-Staff`, `Moss-Oak Buckler`, and `Braced Front Guard`. |
| **GATE 4: Schema-First Registry** | **PASS** | Equipment tiers, weapon visual scale/material presets, and level milestone grants are defined as typed properties on `EquipmentItemResource` and registered in `ArsenalCatalog`. |
| **GATE 5: Code-First & Multi-Age Safe** | **PASS** | `ActorVisuals` procedurally renders wood, hedgerow iron, Bramblebridge steel, and Doverslap relic tiers plus $2.0\times$ Sign weapon-channel silhouettes visible at $4.8\text{ m}$ height. |

---

## 3. The Anti-Turret Kinetic Combat Loop

### 3.1 Root-Motion Step Displacement & Flow-Link Cadence
Standing still while clicking is physically impossible because every posture drives deterministic root-motion velocity along the actor's facing or input vector:

| Posture Input | Stamina Cost | Pip Gain / Cost | Root-Motion Displacement | Wind-Up / Active / Recovery (`ms`) | Flow-Link Cancel Window |
|---|---|---|---|---|---|
| `Light Attack` (Chain 1–2) | $8.0$ | $+0.20\text{ Pip}$ | $+0.6\text{ m}$ forward step | $140 / 120 / 220\text{ ms}$ | Final $140\text{ ms}$ of recovery |
| `Light Attack` (3rd Static Finisher) | $12.0$ | $+0.25\text{ Pip}$ | $+0.8\text{ m}$ forward step | $160 / 140 / 550\text{ ms}$ *(Winded)* | Cancelable in first $220\text{ ms}$ of recovery into Directional Heavy, Guard, or Dodge |
| `Heavy Attack` (Neutral) | $16.0$ | $+0.35\text{ Pip}$ | $+1.2\text{ m}$ forward lunge | $240 / 160 / 300\text{ ms}$ | Final $160\text{ ms}$ of recovery |
| `Forward + Heavy` (*Gap-Closer*) | $18.0$ | $+0.40\text{ Pip}$ | $+2.8\text{ m}$ leaping cleave / shot | $220 / 180 / 260\text{ ms}$ | Final $160\text{ ms}$ of recovery |
| `Back + Heavy` (*Evasive Vault*) | $18.0$ | $+0.40\text{ Pip}$ | $-2.4\text{ m}$ back-hop strike | $160 / 160 / 240\text{ ms}$ | Final $160\text{ ms}$ of recovery |
| `R Skill` (Un-Inked or Card) | $0.0$ | $-1.00\text{ Pip}$ | Weapon-dependent ($+1.5\text{ m}$ or ranged) | $200 / 200 / 240\text{ ms}$ | Chains directly from any Flow-Link window |
| `L+R Ult` (Un-Inked or Card) | $0.0$ | $-3.00\text{ Pips}$ | $+2.0\text{ m}$ heroic surge | $300 / 280 / 320\text{ ms}$ | Chains directly from any Flow-Link window |

- **The Flow-Link Stamina Refund:** If a player cancels the recovery of their 2nd or 3rd `Light Attack` into `Forward + Heavy`, `Back + Heavy`, `R Skill`, or `L Guard` inside the $220\text{ ms}$ Flow-Link window, they receive a **Flow-Link Pulse** (a crisp white-gold ring at the character's waist, refunding $+8.0\text{ Stamina}$ and granting $+0.15\text{ bonus Pip}$).
- **The Static Mash Penalty:** Clicking `Light Attack` 3 times in place without weaving a directional input, guard, or dodge triggers the full $550\text{ ms}$ winded recovery on the 3rd swing, teaching players through feel that directional weaving is faster and stronger than stationary clicking.

### 3.2 Enemy "Braced Front Guard" & Trinity Flanking
To prevent 4–5 players from clumping in front of a mob or boss and mashing:
1. **Braced Front Guard Trigger:** When an enemy or boss absorbs $3$ frontal hits within $4.0\text{ s}$, it raises an amber-glowing **Braced Front Buckler** for $5.0\text{ s}$ (`ActorVisuals` renders an oversized timber-and-brass buckler arc across its front $120^\circ$ cone).
2. **Frontal Mitigation & Counter-Shove:** Attacks hitting the front $120^\circ$ arc while braced deal only $30\%$ HP damage ($70\%$ reduction) and $50\%$ poise damage, accompanied by a dull wooden *clunk* and gray deflected sparks. After $1.8\text{ s}$ in Braced Front Guard, the enemy projects a $2.5\text{ m}$ `RED_AVOID` frontal shield-shove telegraph that knocks back stationary front-mashers.
3. **Two Cooperative Counter-Plays:**
   - **Wayfarer Flanking (`Flank Breach`):** Landing a `Forward + Heavy`, `Back + Heavy`, or `R Skill` against the enemy's unguarded rear/side $240^\circ$ arc triggers a **Flank Breach** ($1.35\times$ HP damage, $+20.0$ bonus poise damage, and instantly shatters Braced Front Guard).
   - **Shield-Sworn Poise Cracking & Sanctuary:** A Tank wielding `SIGN_IRON_ROOT` or `+ TANK` Calling modifiers deals $2.0\times$ poise damage directly against Braced Front Guard, cracking it from the front while holding `ThreatComponent` aggro so teammates have an open back-arc, or holds `L Guard` (`Shadow Sanctuary`) to project the $4.0\text{ m}$ `BLUE_BEHIND_TANK` safe-fan that blocks the enemy's counter-shove for all allies standing behind the Tank.

---

## 4. "Martial Imbuement" & $4.8\text{ m}$ Camera-Safe Power Feedback

### 4.1 Un-Inked Martial Flourishes (Empty Card Slot Behavior)
Because all buttons work at Level 1, pressing `R Skill` ($1\text{ Pip}$) or `L+R Ult` ($3\text{ Pips}$) when no Scribe Card is slotted in that posture executes the equipped weapon type's **Un-Inked Martial Flourish**:

| Weapon Class | Empty `R Skill` ($1\text{ Pip}$) | Empty `L+R Ult` ($3\text{ Pips}$) | Physical Effect & Visual Telegraph |
|---|---|---|---|
| `LIGHT_SWORD` (*Falchion*) | **Timber-Cross Slash** | **Bramble-Whirl Flurry** | Lunges $+1.8\text{ m}$ with a wide ivory-white X-slash ($1.6\times$ weapon damage, $+15.0$ poise). |
| `HEAVY_AXE` (*Broad-Axe*) | **Coppice-Splitter Slam** | **Heartwood Sundering** | Overhead leap slam cracking a $2.2\text{ m}$ dust ring ($1.8\times$ weapon damage, $+28.0$ poise). |
| `BOW` (*Yew Longbow*) | **Vaulting Bough-Shot** | **Hail of the Hedgerow** | Back-steps $-1.5\text{ m}$ while firing a heavy whistling bodkin arrow ($1.7\times$ damage, pierces $2$ targets). |
| `STAFF` (*Rowan Way-Staff*) | **Reed-Sweep Gust** | **Lantern-Keeper's Chime** | Sweeps a $3.0\text{ m}$ warm wind arc that deals $1.4\times$ damage and heals the lowest-HP ally within $8.0\text{ m}$ for $10.0\text{ HP}$. |

### 4.2 Four-Layer Visual Feedback ("What Did My Power Just Do?")
Whenever a player activates `R Skill`, `L+R Ult`, or a **Four-Sign Detonation**, four synchronized visual layers fire so players never have to guess whether their power worked:

1. **Layer 1 — Sakurai Hit-Stop (Frame Freeze):**
   - `Light Attack`: $50\text{ ms}$ local actor freeze on hit.
   - `Heavy` / `Directional Heavy` / `Un-Inked Flourish`: $100\text{ ms}$ freeze on hit.
   - `Inked Scribe Card Strike`: $140\text{ ms}$ freeze on hit.
   - `Four-Sign Detonation` (*Shatterpoint*, *Glacial Rupture*, *Dawnburst*, *Astral Chorus*): $180\text{ ms}$ freeze + crisp $1.5\text{ m}$ shockwave torus.
2. **Layer 2 — $2.0\times$ Weapon-Channel Silhouette Morph (`ActorVisuals`):**
   - During the active frames ($450\text{ ms}$) of any `R Skill` or `L+R Ult`, `ActorVisuals` scales the character's weapon mesh by $2.0\times$ ($2.4\times$ on `L+R Ult`) and overrides its emissive rim with the slotted Sign's color (or warm ivory-gold if un-inked). From the $4.8\text{ m}$ camera, even a 4-year-old immediately sees their wooden sword or bow flare into a giant glowing Amber, Sea-Azure, Saffron-Gold, or Twilight-Violet projection.
3. **Layer 3 — $2.5\text{ m}$ Ground Sign Stamp & Overhead Primer Banner:**
   - Striking an enemy with a Scribe Card stamps a rotating $2.5\text{ m}$ Sign Ring flat on the ground beneath the enemy and spawns a high-contrast 3D floating Sign Badge $2.2\text{ m}$ above the enemy's head showing the active Sign color and a countdown arc ($6.0\text{ s}$ prime duration).
4. **Layer 4 — `CrossGrimoireHUD` Active Pulse & Co-Op Detonation Callout:**
   - Pressing any posture flashes its corresponding diamond on `CrossGrimoireHUD` ($1.35\times$ scale bounce over $180\text{ ms}$) with a floating verb label (`"TIMBER-CROSS!"`, `"IRON-ROOT PRIMED!"`, `"SHATTERPOINT!"`).
   - When any teammate primes a Sign on an enemy within $12.0\text{ m}$, every nearby ally with $1.0+\text{ Pip}$ sees their `R Skill` HUD diamond pulse with a bright golden ring and a prompt banner (`"R: DETONATE SIGN!"`), teaching two-player combos without text walls.

---

## 5. Level 1 to 10 Progression: "The Trail of the Four Signs"

### 5.1 Four-Tier Equipment Progression (`EquipmentItemResource`)
Players no longer spawn at Level 1 with ornate endgame steel. `ArsenalCatalog` registers four distinct visual and statistical equipment tiers across all four weapon classes (`Falchion`, `Broad-Axe`, `Yew Longbow`, `Rowan Way-Staff`) and armor sets:

| Tier | Unlock Level | Material Palette (`ActorVisuals`) | Canonical Weapon Names | Base Damage / Poise Multiplier |
|---|---|---|---|---|
| **Tier 1: Apprentice Timber** | **Level 1** *(Starting Gear)* | Unvarnished hazel/ash wood (`#A67B5B`), hemp cord wrap (`#D9C39A`), zero metallic sheen | `Turned-Hazel Falchion`, `Split-Ash Broad-Axe`, `Willow-Coppice Longbow`, `Reed-Light Way-Staff` | $1.00\times\text{ Base}$ |
| **Tier 2: Hedgerow Iron** | **Level 2–3** *(Ariundle Moss-Oaks)* | Hammered dark iron (`#5A626A`), oak grip (`#7A5230`), brass rivet trim | `Hedgerow Iron Falchion`, `Coppice-Forged Broad-Axe`, `Horn-Tipped Yew Longbow`, `Copper-Shod Way-Staff` | $1.20\times\text{ Base}$ |
| **Tier 3: Bramblebridge Steel** | **Level 5–6** *(Sunken Holloway)* | Bright milled steel (`#C4CED4`), dyed leather wrap, brass bell-guard (`#D4AF37`) | `Bramble-Steel Falchion`, `Mill-Forged Broad-Axe`, `Weald-Ranger Yew Longbow`, `Scribe-Banded Way-Staff` | $1.45\times\text{ Base}$ |
| **Tier 4: Doverslap Relic** | **Level 9–10** *(Ring of the Cairnsman)* | Gilded Carillon bronze & star-etched steel (`#E5C158`), glowing Sign-stone pommel | `Cairnsman's Span-Blade`, `Doverslap Cleaver-Axe`, `Gorge-Wind Greatbow`, `Arch-Scribe's Carillon Staff` | $1.75\times\text{ Base}$ |

### 5.2 Milestone-by-Milestone Onboarding Table (Levels 1–10)
XP is awarded by defeating trail packs ($+35\text{ XP}$ per mob), completing co-op threshold gates ($+80\text{ XP}$), and felling bosses ($+200\text{ XP}$). Level thresholds are tuned so a family party progresses from Level 1 to Level 5 across their first expedition run, and reaches Level 10 across their second run or mastery rematch:

| Level | Trail Milestone Context | What Changes in Player Kit | Co-Op & Combat Lesson Mastered |
|---|---|---|---|
| **Level 1** | **Bramblebridge Green** *(Spawn)* | **Tier 1 Apprentice Timber** weapon + `Bramble-Spun Jerkin`. All 6 postures & `D-Pad Soul Tether` active; `R` and `L+R` fire **Un-Inked Martial Flourishes**. | Moving with attacks, spending $1\diamond$ / $3\diamond$ Pips, and Flow-Canceling the 3rd swing into `Forward+Heavy` or `Back+Heavy`. |
| **Level 2** | **Ariundle Moss-Oaks Trailhead** *(First Mob Pack)* | Drops **Tier 2 Hedgerow Iron** weapon upgrade ($+20\%$ damage, iron mesh swap in `ActorVisuals`). | Breaking enemy **Braced Front Guard** via Tank frontal poise pressure or DPS rear `Flank Breach`. |
| **Level 3** | **Ariundle Moss-Oaks Way-Shrine** | Grants **1st Plain Vellum Scribe Card** (auto-slotted into `R Skill` if empty, aligned with Primary Fellowship: `SIGN_IRON_ROOT` for Shield-Sworn, `SIGN_RIME_GALE` for Wayfarers, `SIGN_WARM_HEARTH` for Lantern-Bearers). | Seeing `R Skill` transform from a plain wooden swing into a $2.0\times$ glowing Sign channel that primes a $2.5\text{ m}$ Sign Ring. |
| **Level 4** | **Holloway Threshold Gate** | Grants **Role Signature Talisman** enhancing `L Guard` (`Shadow Sanctuary` $4.0\text{ m}$ `BLUE_BEHIND_TANK` safe-fan gains $+15\%$ ally damage buff) and `D-Pad Soul Tether` (braided 3D tether ribbon pulses $+4.0\text{ HP}$ every $2.0\text{ s}$). | Standing behind the Tank during red boss cones and keeping a `Soul Tether` linked to the frontliner. |
| **Level 5** | **The Sunken Holloway Mid-Camp** | Grants **Tier 3 Bramblebridge Steel** weapon + **2nd Plain Vellum Scribe Card** (auto-slotted into `L+R Ult`, e.g., `SIGN_STAR_TIDE` or role secondary Sign). | Using $3\diamond$ `L+R Ult` for big AoE waves and chaining `R Skill` $\rightarrow$ teammate `R Skill` for a **Four-Sign Detonation**. |
| **Level 7** | **Doverslap Gorge Bridge Gatehouse** | Unlocks the **Under-Card Tuck** slot beneath `R Skill` and awards the player's first Under-Card modifier (`Widened Arc`, `Twin-Echo`, or `Leeching Ink`). | Learning lenticular deckbuilding: tucking an Under-Card beneath a primary card to alter its geometry or resource return. |
| **Level 10** | **The Ring of the Cairnsman** | Unlocks the **$3 \times 3$ Secondary Calling** (`+ TANK`, `+ DPS`, or `+ MAGIC` modifiers from `06_WORLD_AND_CALLINGS.md`), bestowing canonical Calling title (`Bridge-Warden`, `Hedge-Runner`, `Lantern-Scribe`, etc.) and **Tier 4 Doverslap Relic** weapon. | Full raid mastery: combining $3 \times 3$ Calling passives, Under-Card tucks, and all 4 Scribe Sign Detonations (`Shatterpoint`, `Glacial Rupture`, `Dawnburst`, `Astral Chorus`). |

---

## 6. Diegetic Level-Up & Loadout Onboarding (Zero Full-Screen Pause Bloat)
To preserve couch co-op momentum:
- **3D Milestone Pennant:** When a player levels up or receives a new weapon tier / Scribe Card along the trail, a warm Saffron-Gold **Wayfarer Pennant** unfurls $2.4\text{ m}$ above their character for $3.0\text{ s}$ with a carillon chime cue while an animated card/weapon icon slides directly into their bottom `CrossGrimoireHUD`.
- **Smart Auto-Slot for Empty Slots:** If a player earns their first weapon upgrade (Level 2), first `R Skill` card (Level 3), second `L+R Ult` card (Level 5), or first Under-Card (Level 7) while that slot is still at its starter/empty state, the item auto-equips immediately so a 4-year-old or first-time player experiences the power upgrade on their very next button press without opening a menu.
---

## 7. Build Notes (Phase 11 combat track)

What the game does today, where it differs from the spec above, and what's still to come.

**In the code now**
- **Equipment tiers.** `EquipmentItemResource` has `EquipmentTier` (`TIER_1_TIMBER` = 1 to `TIER_4_RELIC` = 4) and `equipment_tier`, `required_level`, `damage_multiplier`, `blade_albedo`, `trim_albedo`, `metallic_factor`, `roughness_factor`, `uninked_r_skill_name` and `uninked_ult_name`. `ArsenalCatalog` registers the 16 trail weapons under the doc's names (`weapon_hazel_falchion` to `weapon_carillon_waystaff`) and the `armor_bramble_jerkin`. Each tier weapon copies its classic weapon's moves with damage and poise times 1.0, 1.2, 1.45 or 1.75, and is drawn in its tier's palette: hazel and hemp, dark iron with brass rivets, milled steel with a brass bell-guard, gilded bronze with a glowing Sign-stone pommel. Metal parts carry a glint band (`PropPartResource.metal`, read by `storybook_cel_light.gdshaderinc`).
- **The Level 1 kit and milestones.** `get_default_level_one_loadout_for_role()` and `get_milestone_grant_for_level()` hold §5.2's table. `apply_milestone_grant()` is the smart auto-slot of §6: a weapon replaces a lower tier of the type already carried, a card fills R or L+R only while empty, an Under-Card fills the link beneath R only while empty. `trail_kit_for_role()` is the Level 1 kit with every milestone so far applied, which is what a new seat wears.
- **Un-Inked Martial Flourishes.** An empty R or L+R composes into the weapon's flourish (`LoadoutComposer._flourish_action`): 1.6x, 1.8x, 1.4x or 1.7x the weapon's Heavy damage, +15, +28, +10 or +20 poise (times the tier), and the step of §4.1. L+R hits 1.75x harder with twice the poise, all round you after a 2 m surge. The Way-Staff's flourishes mend the most hurt ally within 8 m (10 HP, 25 on L+R). The Scribe Desk can leave R and L+R un-inked.
- **The kinetic loop.** `ActorBase` has the `STEP_*`, `STATIC_MASH_RECOVERY_MS`, `FLOW_LINK_*` constants of §3.1. A hero's melee strike with no lunge of its own steps 0.6 m (Light), 1.2 m (Heavy) or 2.8 m (Forward+Heavy); every Back+Heavy strike hops back at least 2.4 m. `ActionQueueComponent` counts Lights in a row: the third is winded for 550 ms and can only be cancelled in the first 220 ms of its recovery, into Forward+Heavy, Back+Heavy, R, L+R or a roll. Cancelling a 2nd or 3rd Light there, or raising a guard there, is a Flow-Link Pulse: +8 stamina, +0.15 pip and a white-gold ring at the waist. R and L+R now chain from every Light, the Heavy and the movement cards.
- **Braced Front Guard** (`src/components/braced_guard_component.gd`, on every enemy) works as §3.2 says: 3 frontal hits in 4 s, 5 s braced, 30% damage and half poise on the front 120°, a Shield-Sworn's Iron-Root strike or any strike of a +Tank (Stout Heart) Shield-Sworn cracking it at 2x poise, a Flank Breach (Forward+Heavy, Back+Heavy, R or L+R on the other 240°) for 1.35x damage and +20 poise that shatters it, and a 2.5 m red shield-shove 1.8 s in that throws front-mashers back 3 m unless they shelter in the tank's Shadow Sanctuary. A knockdown also shatters it.
- **The four feedback layers.** Hit-stop is 50 ms for a Light, 100 ms for a Heavy, directional Heavy or flourish, 140 ms for an inked card and 180 ms for a detonation (`CombatDirector.HIT_STOP_*`; the composer sets each hero action's scale), and a detonation bursts a 1.5 m shockwave torus. R and L+R swell the weapon to 2x (2.4x) over 450 ms, rimmed in the Sign's colour or warm ivory-gold un-inked (`ActorVisuals.update_channel`, on every peer). A seal puts a turning 2.5 m Sign Ring under the enemy and a badge 2.2 m over its head with a countdown arc (`SignMark`); the host now tells every peer about every seal. The Cross-Grimoire slots pop to 1.35x over 180 ms with a floating verb ("TIMBER-CROSS!", "IRON-ROOT PRIMED!", "GLACIAL RUPTURE!"), and while a teammate's seal waits within 12 m and you have the pip, the R slot rings gold under "R: DETONATE SIGN!". R and L+R strikes detonate a teammate's seal, as heavies always have.
- **Levels 1 to 10.** `PartyProgress` holds the party's trail XP and level, saved and shared like the Chimes. Mobs pay 35, the Gorge gate 80, a boss 200. Thresholds: 0, 70, 105, 230, 320, 560, 700, 800, 850, 1050. One expedition (525 XP) reaches Level 5 at the Gatehouse; the second reaches Level 10 at the Cairnsman. On each new level every hero gets a 3 s Saffron-Gold Wayfarer Pennant and a LEVEL n! banner, and the host auto-slots the milestone into every seat's kit and every saved kit.
- **The Callings open at Level 10.** Below it a hero is Unsworn (`Callings.UNSWORN`): their Fellowship's name, no Secondary numbers, their Fellowship's own gear. Hold C and the desk's Calling row say when they open. At Level 10 each seat takes its saved Calling or its Fellowship's own column (Bridge-Warden, Hedge-Runner, Lantern-Scribe).
- **Old saves** keep their gear: a save from before the trail starts at Level 5 after one Cairnsman win and Level 10 after two.
- **Testing.** `PartyProgress.apply_full_endgame_kit_for_testing()` (the brief's `apply_Full_endgame_kit_for_testing`, in the project's snake_case) puts the party at Level 10 with every class in its classic full kit, so the older smoke checks measure what they always did. The smoke test also turns the Braced Front Guard off for those older checks; `_check_phase_11_combat_onboarding_and_flanking` turns it on and plays the trail from Level 1.

**Deliberate differences from the spec**
- **The classic weapons stay.** The Falchion, Broad-Axe, Rowan Way-Staff and Yew Longbow are Tier 3 Bramblebridge steel, open from Level 5, with the base (1.0x) numbers every tier scales. They are what `apply_full_endgame_kit_for_testing` wears.
- **R cards at Level 3** are the Fellowships' own: Taunt (Iron-Root) for the Shield-Sworn, Homing Heal (Warm-Hearth) for the Lantern-Bearers, and a new Plain Vellum card, **Rime-Lash** (Rime-Gale, 1 pip), for the Wayfarers. Rime-Lash is kept out of chest drops so the drop table is unchanged. L+R cards at Level 5 are the Fellowships' starter ultimates (Bulwark Quake, Lifeline Pull, Tempest Flow).
- **The Level 7 Under-Card** is one the game already has: Iron-Root Link (Potency Surge) for the Shield-Sworn, Star-Tide Link (Sign Infusion) for the Wayfarers, Warm-Hearth Link (Hearth Echo) for the Lantern-Bearers. Under-Card links stay shut below Level 7; from Level 7 the link beneath R is always open, and the Grimoire's victories open the others as before.
- **Forward+Heavy and Back+Heavy** keep their Fellowship cards from Level 1, so seals and detonations can be learned from the first fight; only R and L+R start un-inked.
- **Seals still last 8 s** (§4.2 says 6 s); the badge's arc counts down the real time.
- **Every enemy braces,** minions too, as §3.2 says. A Light from behind isn't a breach, but it does full damage.
- **Each Light keeps its weapon's own frame data** rather than §3.1's single table, so the four weapons still feel different; the steps, the winded third Light and the Flow-Link window are as specified.

**Still to come**
- The Level 4 Role Signature Talisman (a stronger Shadow Sanctuary and a pulsing Soul Tether).
- §6's animated card or weapon icon sliding into the Cross-Grimoire on a milestone.
- The doc's own Under-Cards (Widened Arc, Twin-Echo, Leeching Ink) and Doverslap relic armor.
