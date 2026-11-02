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