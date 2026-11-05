# 14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md — Sign-Flow Combat, Location + Action Card Dioramas, & The Isomorphic Grimoire UX

## 1. Executive Summary & The Five-Gate Audit
This specification unifies **Sign-Flow Combat** (*"Coat, Break, Turn!"*), threat-tiered **Nursery Rhyme & Glimmer-Spot Scaling (Levels 1–60)**, the **Action Card + Location Card** diorama loadout system, **0-Pip Out-of-Combat Hearth-Rite Tuck**, and the overhauled **Bramble-Bridge Grimoire Shop (*The Reed-Light Scribery*)** under a single isomorphic UI geometry.

| Gate ID | Compliance Verification |
|---|---|
| **GATE 1: Anti-Parasitic Harmony** | Location Cards, Action Cards, and the 0-Pip Hearth-Rite Tuck feed directly into Stamina/Poise, the Four Scribe Signs, the 3x3 Calling Matrix, and the **Chimes** economy. |
| **GATE 2: The Musk Razor** | Zero mid-combat deck scrolling, zero separate buff-card swap menus, and zero extra buttons. Out-of-combat prep and in-combat execution share the exact same `L`, `R`, and `L+R` postures. |
| **GATE 3: Philological Linter** | Replaces technical terms ("Front/Under-Card", "Unified Escalation System", "Buff Slot") with storybook folk terms: **Sign-Flow**, **Action-Leaf**, **Place-Card (Location Card)**, **Hearth-Rite Tuck**, **Weapon-Coat**, **Ward-Mantle**, **Bravery Counter**, and **Seal-Turn**. |
| **GATE 4: Schema-First Registry** | All Action Cards, Location Cards, and Boss Escalation curves live as typed `Resource` files registered in `ArsenalCatalog`. |
| **GATE 5: Code-First & Multi-Age Safe** | Uses one reusable procedural UI layout (`CrossGrimoireDiamondWidget`) across HUD, Loadout Binder, and Town Shop; keeps all 3D visual effects <= 3.2m height for the 4.8m split-screen camera. |

---

## 2. Sign-Flow Combat ("Coat, Break, Turn!") & The BDO / Phantom Dust Blend

**Sign-Flow Combat** synthesizes *Black Desert Online*’s directional Flow-Link cancels, *Phantom Dust*’s color-coded Arsenal counters, and *Batman: Arkham*’s escalating counter windows into a 3-step loop:

1. **STEP 1 — SIGN-COAT (Channeling the Card):**
   - Landing physical directional attacks (`Light`, `Heavy`, `Forward+Heavy`, `Back+Heavy`) generates **Resonance Pips** ($1\diamond$ / $3\diamond$) and opens a **Flow-Link Window** (`14 frames` base; `9 frames` in solo `Dread-Chill`; `18 frames` within `5.5m` of a Lantern-Bearer's **The Lantern's Promise**).
   - Pressing `R Skill` ($1\diamond$), `L Guard` ($1\diamond$ Counter-Brace), or `L+R Ult` ($3\diamond$) inside the Flow-Link Window channels the equipped card through the hero's physical weapon:
     - **DPS (`The Wayfarers`):** Applies a **Weapon-Coat**, scaling the blade, axe, or bow wave to `2.0x` silhouette in the Sign's ink color for `8.0s`.
     - **Tank (`The Shield-Sworn`):** Applies a **Ward-Mantle**, wrapping the shield and shoulders in a protective Sign crest and projecting a `4.0m` `BLUE_BEHIND_TANK` safe cone.
     - **Magic (`The Lantern-Bearers`):** Applies a **Lantern-Tether**, pulsing the Sign along the `5.5m` `D-Pad` **Soul Tether** or `10.0m` `Shadow Sanctuary`.

2. **STEP 2 — GLIMMER-BREAK (The Elemental Bravery Counter):**
   - Striking an enemy's active **`Glimmer-Spot`** opening with its countering Scribe Sign triggers a **Bravery Counter**:
     $$\text{Bravery Counter Posture Damage} = \left(60.0 + 45.0\right) \times M_{\text{impact}}(L)$$
   - Simultaneously triggers the Sign's canonical detonation:
     - `SIGN_IRON_ROOT` (Amber/Ochre) -> **Shatterpoint** (`+45.0` Poise Damage)
     - `SIGN_RIME_GALE` (Sea-Azure) -> **Glacial Rupture** (`+45.0` Burst Damage)
     - `SIGN_WARM_HEARTH` (Saffron-Gold) -> **Dawnburst** (`20.0 HP` Party Heal within `10m`)
     - `SIGN_STAR_TIDE` (Twilight-Violet) -> **Astral Chorus** (`+25.0` Stamina & `+0.5` Pips within `10m`)

3. **STEP 3 — SEAL-TURN (Stewardship Resolution):**
   - Once the `Glimmer-Spot` is cracked open, landing a follow-up strike during an `18-frame` Flow-Link Window spins the monster's inverted **`Maker-Seal`** $180^\circ$ upright, transitioning the foe into **`STATE_UNBOGGART_RELEASE`** (dissolving **Sea-Cave Scrays** into white sea-swallows, lulling **Cairn-Drakes** into climbable `<= 3.2m` boulder cairns, or converting **Furrow Iron-Men** into `10-minute` allied field stewards).

---

## 3. Threat-Tiered Lore Pacing & Dynamic Window Scaling (Levels 1–60)

Nursery rhyme coaching and `Glimmer-Spot` opening durations scale dynamically by **Enemy Threat Tier**, **Encounter Level ($L$)**, and **Pattern Familiarity ($N_{\text{seen}}$ in `SaveManager`)**:

| Threat Tier & Level | Lore & HUD Hint Density | Vulnerability Complexity | Base Window ($T_{\text{base}}$) | Floor Window ($T_{\text{floor}}$) | Impact Multiplier ($M_{\text{impact}}$) |
|---|---|---|---|---|---|
| **Tier 1: Roadside Pebbles & Minor Kin** *(Lv 1–4 `Scree-Worm`)* | Zero text; stone glints Amber on hit | **Always-Open Passive:** Any `SIGN_IRON_ROOT` strike cracks poise at any time | Always Open ($\infty$) | Always Open ($\infty$) | `1.25x` Posture |
| **Tier 2: Trail Wardens** *(Lv 5–9 `Shingle-Scray`)* | 4-word engraving on nearby `Chime-Post` | **1-Step Timed Opening:** Single Sign counter during dive/brace | `210 frames` (`3.5s`) | `150 frames` (`2.5s`) | `1.50x` Posture |
| **Tier 3A: Early Milestone Boss** *(Lv 5 `Cairnsman`, Lv 10 `Gale-Bucca`)* | 3-Echo trail buildup + HUD rhyme couplet on sightings 1–2 | **1-Step Boss Opening:** Cast `SIGN_STAR_TIDE` or `SIGN_IRON_ROOT` during wing-spread / roar | `180 frames` (`3.0s`) | `120 frames` (`2.0s`) | `2.00x` Posture + Ground Stun |
| **Tier 3B: Mid-Game Zone Boss** *(Lv 15 `Furrow Iron-Man`, Lv 25 `Cairn-Drake`)* | Full village nursery rhyme + Chime-Post relief | **2-Step Prime & Turn:** Melt rust (`SIGN_WARM_HEARTH`) -> Flow-Link `Maker-Seal` flip (`SIGN_IRON_ROOT`) | `120 frames` (`2.0s`) | `75 frames` (`1.25s`) | `3.00x` Posture + Armor Strip |
| **Tier 3C: Master Raid Boss** *(Lv 50–60 `Tor-Sleeper`, `Old-Hob`)* | Multi-zone mythic cycle; zero HUD text after sighting 3 | **3-Step Trinity Chain:** Tank Ward-Mantle -> Mender Tether Prime -> DPS Sign Detonation | `75 frames` (`1.25s`) | `45 frames` (`0.75s`) | `5.00x` Exponential Shatter |

### Deterministic Scaling Formulas (60 FPS)
$$T_{\text{frames}}(L, N_{\text{seen}}) = \max\left(T_{\text{floor}}(L), \; T_{\text{base}}(L) - 12 \cdot \min(N_{\text{seen}}, 5)\right)$$
$$M_{\text{impact}}(L) = 1.25 + 3.75 \cdot \left(\frac{L}{60}\right)^{1.6}$$
- **Squire Assist Guarantee (4-Year-Old Safe):** For players on the `SQUIRE` assist tier (`1-Button KOTOR Gambit Assist`), pressing the assist button within a `90-frame` (`1.5s`) pre-buffer halo automatically queues and fires their countering Sign on Frame 1 of any boss opening.

---

## 4. The Diorama Card Architecture: Action Cards (Verbs) + Location Cards (Places)

Instead of abstract "Front" and "Under" cards, every active Grimoire socket (`L Guard`, `R Skill`, `L+R Ult`) holds a **Two-Card Diorama Pair**:

### 4.1 Action Cards (`CARD_KIND_ACTION` — The Hero Verb)
- Defines **what the hero does** when the posture button is pressed (`Weapon-Coat`, `Ward-Mantle`, or `Lantern-Tether`) and the base **Scribe Sign** (`SIGN_IRON_ROOT`, `SIGN_RIME_GALE`, `SIGN_WARM_HEARTH`, `SIGN_STAR_TIDE`).
- Visualized as an arched foreground portrait of the weapon or lantern glowing with ink.

### 4.2 Location Cards (`CARD_KIND_LOCATION` — The Place Backdrop)
- Collected by discovering landmark **Chime-Posts**, completing dungeon zones, or charting maps at the Bramble-Bridge Grimoire Shop.
- Defines **where the power draws its strength from**, framing the Action Card visually like a panoramic stage backdrop and augmenting its behavior:

| Location Card ID & Name | Native Sign | Source Landmark | Augmentation on Paired Action Card | Home-Ground Bonus (If Action Card Shares Sign) |
|---|---|---|---|---|
| `loc_ariundle_moss_oaks`<br>**Moss-Oak-Hollow** | `SIGN_IRON_ROOT` *(Amber)* | Moss-Oak-Hollow Trail Chime-Post | Adds `Root-Bind`: Weapon-Coat strikes slow enemy movement by `20%` and sprout mossy oak bark on the blade. | `+25%` Coat duration (`10.0s` total) & `+15.0` bonus Poise damage. |
| `loc_doverslap_gorge`<br>**Dover-Slap-Bridge** | `SIGN_RIME_GALE` *(Sea-Azure)* | Dover-Slap Gatehouse | Adds `Gorge-Draft`: Extends weapon hitbox reach by `+0.8m` with a sweeping river-mist arc. | `+25%` Coat duration & `+15.0` bonus burst damage on *Glacial Rupture*. |
| `loc_bramblebridge_mill`<br>**Bramble-Bridge Hearth-Mill** | `SIGN_WARM_HEARTH` *(Saffron-Gold)* | Bramble-Bridge Green | Adds `Mill-Warmth`: Casting pulses a `4.0m` warm ember ring that heals allies for `6.0 HP` and melts `Furrow Iron-Man` rust. | `+25%` Coat duration & `+10.0 HP` bonus to *Dawnburst* party heal. |
| `loc_barrow_crag_tor`<br>**Barrow-Crag-Crossing** | `SIGN_STAR_TIDE` *(Twilight-Violet)* | Ring of the Cairnsman | Adds `Star-Spark`: Refunds `8.0` Stamina on every Flow-Link cancel and wraps the weapon in violet starlight. | `+25%` Coat duration & `+0.25` extra Resonance Pips on *Astral Chorus*. |

---

## 5. Dual-State Execution: 0-Pip Out-of-Combat "Hearth-Rite Tuck" vs. In-Combat "Sign-Flow"

Every slotted **Action + Location Card** pair operates in two automatic states without ever swapping cards:

| Execution State | Trigger Condition & Input | Resource Cost | Mechanical & Visual Effect |
|---|---|---|---|
| **State 1: Hearth-Rite Tuck** *(Out of Combat)* | Party is out of combat (`in_combat == false`). Hold `R Skill` or `L+R Ult` for `120 frames` (`2.0s`; set by [15_THE_MYTHOPOETIC_LENS.md](15_THE_MYTHOPOETIC_LENS.md) §6.2, up from `90`). | **0 Pips** *(Free Pre-Fight Cast)* | 1. Hero raises their weapon as the **Location Card** vignette chimes softly.<br>2. Grants **Trail-Coat Blessing** (lasts until entering combat + `15.0s`, or until discharged): weapon visually glows at `1.35x` scale with the Location's particles while walking.<br>3. Pre-charges `+1.0` Resonance Pip ($1\diamond$) so the player never starts a fight resource-starved.<br>4. **Opening Strike Discharge:** Your very first strike or Bravery Counter in the next fight automatically unleashes a full-power Sign prime + Location effect. |
| **State 2: Active Sign-Flow** *(In Combat)* | Party is in combat (`in_combat == true`). Tap `L`, `R`, or `L+R` during any `Flow-Link Window`. | **`1.0 Pip` (`L`/`R`)** or **`3.0 Pips` (`L+R`)** | Instant (`0-frame` cast delay) recovery-canceling **Weapon-Coat**, **Ward-Mantle**, or **Lantern-Tether** at `2.0x` weapon scale with `110ms` Sakurai hit-stop and a `2.5m` ground Sign emblem. |

---

## 6. Isomorphic UX Architecture: HUD <-> Loadout Binder <-> Bramble-Bridge Grimoire Shop

To guarantee that a 4-year-old and 8-year-old instantly understand card assignment, **all three interfaces reuse the exact same `CrossGrimoireDiamondWidget` geometry**:

```text
                  ┌───────────────────────────┐
                  │      TOP DIAMOND (L+R)    │
                  │  [Location Frame Backdrop]│
                  │   [3-Pip Ult Action Card] │
                  └─────────────┬─────────────┘
                                │
┌───────────────────────────┐   │   ┌───────────────────────────┐
│     LEFT DIAMOND (L)      │   │   │     RIGHT DIAMOND (R)     │
│  [Location Frame Backdrop]├───┼───┤  [Location Frame Backdrop]│
│  [1-Pip Ward/Role Card]   │   │   │  [1-Pip Coat Action Card] │
└───────────────────────────┘   │   └───────────────────────────┘
                                │
                  ┌─────────────┴─────────────┐
                  │   BOTTOM DIAMOND (Basic)  │
                  │  [Equipped Physical Arm]  │
                  │ (Sword / Axe / Bow /Staff)│
                  └───────────────────────────┘
```

---

## 7. Build Notes (Phase 12)

What the game does today, where it differs from the spec above, and what's still to come. This file arrived as `12_...`; 12 is Oakshire Vale, so it's 14 here. It ended at the §6 diagram, so anything after that didn't reach the build.

**In the code now**
- **Schema.** `ScribeCardResource` has `CardKind` (`ACTION_LEAF`, `LOCATION_PLACE`), `ManifestationMode` (`WEAPON_COAT`, `WARD_MANTLE`, `LANTERN_TETHER`), `DioramaSocket` (L, R, L+R) and the brief's exports (`card_kind`, `manifestation_mode`, `coat_duration_sec`, the four `location_bonus_*`/`location_stamina_refund`, `location_landmark_id`, `home_ground_duration_mult`, `chime_cost`). The old lead/under enum is now `LinkRole`. Save keys are unchanged (`standard`, `shiny_foil`, `astral_prism` read as Plain Vellum, Gilded Leaf, Star-Inked Vellum), and kits saved before Phase 12 load with empty dioramas.
- **Dioramas.** A kit pairs each socket's Action-Leaf with a Place-Card. R's and L+R's leaves are the Signature and Ultimate cards; L has a leaf of its own. Every lead card is an Action-Leaf: the tank's cards are Ward-Mantles, the healer's Lantern-Tethers, the rest Weapon-Coats, and six new Common R leaves (Oak-Knot Tether, Rime-Mantle Bash, Mist-Lantern Mend, Ember-Coat Cut, Hearth-Mantle Brace, Star-Thread Mend) give every Sign all three. The four Place-Cards carry the brief's Signs and numbers. `ArsenalCatalog.compute_diorama_synergy()` returns the pair's Sign, mode, `is_home_ground_harmony` and its bonuses.
- **Encounters.** `BossEncounterResource` holds the threat tier, level, counter Signs, windows and rhyme, with `get_scaled_glimmer_frames()` and `get_impact_multiplier()` as specified. `ArsenalCatalog` registers Roadside Kin and the Scree-Worm (Tier 1), the Shingle-Scray (Tier 2), and the Cairnsman (Lv 5), Gale-Bucca (10), Furrow Iron-Man (15), Cairn-Drake (25), Tor-Sleeper (50) and Old-Hob-of-the-Hill (60).
- **The Hearth-Rite Tuck** (`src/combat/sign_flow_component.gd`, on every hero). Out of combat (no engaged foe within 18 m), holding R or L+R for 120 frames (80 on a Star-Inked Vellum leaf; 90 and 60 before the Mythopoetic Lens) costs no pip, tops the hero up to 1 pip, and holds the weapon at 1.35x in the Place-Card's tint, with a shoulder crest for a Ward-Mantle or three motes for a Lantern-Tether. The first strike that lands in the next fight carries the Sign, stamps its seal and adds the Place-Card's poise. The blessing fades 15 s into a fight if no strike lands.
- **Sign-Flow in combat.** Landing a Light, Heavy or directional Heavy opens a Flow-Link Window: 14 frames, 18 within 5.5 m of a Lantern-Bearer, 9 for a party of one (Dread-Chill). R (1 pip) or L+R (3 pips) pressed in it skips the wind-up; L tapped in it is a 1-pip Counter-Brace from the L leaf. The cast flares the weapon to 2.0x for 600 ms, freezes foes in the 2.5 m ring for 110 ms, stamps the ring, and coats the hero for the leaf's time (x1.25 on Home-Ground). While coated, every strike carries the Sign and the Place-Card's poise, reaches its extra distance, and a Flow-Link cancel refunds its stamina. Casting also mends friends within 4 m by the Place-Card's heal. A Ward-Mantle raises a 4 m shelter cone for 3 s; a Lantern-Tether mends the tethered ally for 6.
- **Glimmer-Spots** (`src/combat/glimmer_spot_component.gd`, on every foe with an encounter). The expedition's woodland kin and Oakshire's spirits up to Level 4 are Tier 1: an Iron-Root strike does 1.25x poise and glints amber, with no text. The Cairnsman opens his spot as he roars into each raid cast (Iron-Root or Star-Tide cracks it). A counter Sign on an open spot is a Bravery Counter: (60 + 45) x M(L) poise plus the Sign's detonation, then the spot shuts. `PartyProgress` saves each boss's sightings (`[glimmer] seen`), which tighten the window, and the HUD rhyme shows on sightings 1 and 2 only. A Squire's press up to 90 frames before the roar is buffered and fires their R on its first frame.
- **One widget everywhere.** `CrossGrimoireDiamondWidget` draws the four diamonds: Place-Card frame with its landscape, Action-Leaf portrait with its mode icon and finish trim, and a gold star for Home-Ground Harmony. The HUD shows it at 1.0x beside the R wing, with the Hearth-Rite hold filling, the coat timer, the Flow-Link flash and a gold beat when a Glimmer-Spot is yours to crack. `GrimoireBinderPanel` (a tap of Tab / View, out of combat) and `ScriberyShopPanel` show the same widget at 2.2x.
- **The Reed-Light Scribery** (`src/actors/scribery_station.gd`) stands on the square's west side in both Bramblebridges. It's a crow-stepped timber pavilion 2.92 m tall, with a turning Vellum Press-Wheel and four Deep-Ink Vat Lanterns, one OmniLight3D per Sign colour. Its counter sells the six Common leaves and the four Place-Cards (25 Chimes each) and gilds owned cards: Gilded Leaf 50, Star-Inked Vellum 120. A new leaf fills an empty R, a new Place-Card frames the chosen diamond if it's empty, and a gilded copy replaces the one worn. Highlighting a card shows its coat on your own puppet.

**Deliberate differences from the spec**
- **No `SaveManager` or `CombatController`.** `PartyProgress` is the save, and the Sign-Flow state lives on `SignFlowComponent` (composition), not on `ActorBase`.
- **`ui_binder` is a tap of Tab / View,** the button whose hold changes Fellowship, so no new button (Gate 2).
- **The Scribery is an `Interactable`** like the desk and the shrine (walk up, press light), not an `Area3D`. It opens its panel through `PlayerHUD.for_actor()`, so no level script changed.
- **Out of combat, R and L+R fire when you let go** rather than when you press: that's how a tap is told from the 90-frame hold. In combat they fire on the press as before.
- **Impact follows the formula, not §3's table.** M(L) gives 1.33x at the Cairnsman's Lv 5 and 1.46x at Lv 10, where the table says 2.00x. Tier 1 uses the table's flat 1.25x, as the brief asks.
- **A Place-Card's bonus always applies;** Home-Ground Harmony adds the 25% longer coat. §4.2's per-place Home-Ground extras (+15 Glacial Rupture damage, +0.25 Astral Chorus pips) and Root-Bind's 20% slow aren't built.
- **One charted Place-Card frames every diamond,** and dioramas take no Grimoire Memory. L's leaf needs its own copy, like any card.
- **The HUD keeps its slot grid;** the diamonds sit beside it. Replacing the grid with the diamonds would move Forward and Back off the cross: a Creative Director call.
- **The Scribery sells only Common leaves.** Uncommon finds and boss cards stay earned. The Gilding Press adds a finer copy and keeps the old one.

**Still to come**
- Seal-Turn on a boss (step 3). The Mythopoetic Lens's Pass 1 built the Maker-Seal and `STATE_UNBOGGART_RELEASE` for Oakshire's Furrow Iron-Men and every foe (15 GDD §7); a Tier 3B Iron-Man boss is still to come.
- Live Tier 2 foes, and the bosses past the Cairnsman (their encounters are data only).
- The 3-Echo trail build-up and Chime-Post engravings.
- Place-Cards charted at landmark Chime-Posts.
- The hero raising their weapon during the rite.

---

## 8. Build Notes (the Phase 12 Kaizen pass: combos, Miyamoto tiers, role asymmetry)

A second Phase 12 brief arrived with its spec named `12_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md`. That file was cut off after the first sentence of its §1, so it isn't kept here; the brief is the spec for this pass, and this section says what it built. It went in as five increments (the data, combos and card choreography, the Trinity loops, the Miyamoto tiers and gates, the Grimoire surfaces), each checked with `--check-only` before the next.

**In the code now**
- **Five combo forms** (`ComboChainResource`, registered by id in `ArsenalCatalog`; `get_unlocked_combos_for_level()`). `ComboChainComponent` on every hero hears each posture as a token. Heavy with the stick pushed sideways is `SIDE_HEAVY`, so there's no new button. A roll, a guard, a stagger or a second's rest starts the run over. The finisher keeps its own posture, so one form can flow into the next.

  | Form | Lv | Postures | Finisher |
  |---|---|---|---|
  | Apprentice's Three-Beat | 1 | Light, Light, Heavy | steps 1.2 m; 1.5x damage, +15 poise |
  | Sundering Gap-Leap | 2 | Light, Light, ↑+Heavy | leaps 2.8 m; 1.5x, +15, a 1.2 s stun; cracks a martial lock |
  | Wayfarer's Vault-Strike | 4 | Light, Light, ↓+Heavy | vaults 2.6 m back with 200 ms of evasion frames; 1.5x, +15 |
  | Whirling Flank-Sweep | 6 | Heavy, ←/→+Heavy | orbits 2.2 m round the foe to its flank; 1.5x, +20 |
  | Grand Sign-Flow | 8 | ↑+Heavy, R, L+R | a Sign detonation riding it reaches 25% further |

  A landed finisher names its form in the strike (`CombatEvent.combo_id`), and the foe's owner adds the numbers. The HUD's weapon diamond lights a pip per step (o - o - >).
- **The Overhead Pocket Blessing** is the Hearth-Rite's look. The weapon is put away, the right hand draws a glowing vellum card (0.18 x 0.26 m, with a rim of the Sign's colour) from the coat pocket and raises it overhead (its top edge reaches 2.2 m, under the 2.5 m limit), and a column of the Sign's ink pours down round the hero. Then the card goes back and the weapon is drawn again at 1.35x. The rite also grants a **Ward Blessing**: the first foe that strikes in the next fight does 15% less, until 15 s into it.
- **The Offhand Pocket-Draw** plays on every Sign-Flow cast: the off hand flicks the card out and sweeps it along the weapon as it ignites at 2.0x. That player's camera dolly-pulses 0.35 m toward the hero's shoulder and back over 120 ms, beside the 110 ms freeze.
- **DPS: the One-and-Done Seal-Breaker.** L+R while a Weapon-Coat of a Sign burns spends the coat and 3 pips. Its strikes land the leaf's 3.2x, ride the Sign's detonation (Shatterpoint +45 poise, Glacial Rupture +45 burst, Dawnburst 20 heal, Astral Chorus +25 stamina and ½ pip), and crack whatever the foe shows: a lock, an open Glimmer-Spot, the Aegis Mantle or the Maker-Seal.
- **Tank: the Ward-Mantle.** A blow of the mantle's own Sign takes 80% less. So does any Sign's blow Perfect-Guarded under a mantle. Either way the tank shrugs off the stun and the shove, throws 60 poise back at the attacker and raises the 4 m shelter cone. Every Ward-Mantle and Support leaf grants stun immunity while its coat lasts. To make this readable, foes' blows now carry Signs, and the striking limb glows in that colour through the wind-up. The Cairnsman's Crushing Swipe is Iron-Root (amber fists), so the starter tank's Taunt wards it. In Oakshire, padfoots and the Barrow-Rime spriggan are Rime-Gale, Iron-Men, lashers, the bog-hulk and the Crag-Back are Iron-Root, and the spore-puff and the Moss-Shield and Barrow-Bell spriggans are Star-Tide. The curious hobs and the expedition's kin stay plain.
- **Support: the Aegis Ward and the Ink-Share.** Binding the Soul Tether, or laying a Green Sanctuary (allies within 10 m), wards an ally: their next stun or shove is shrugged off. The tethered ally also gets The Lantern's Promise (18 frames) at any distance. A Support's leaf shares its ink: when its R or L+R starts in a fight, everyone on the tether or within 10 m strikes in its Sign for 8 s with their physical blows. The Sign pulses down the beam and rings the ground. So a party with a Warm-Hearth Homing Heal melts a Furrow Iron-Man's rust and opens his Maker-Seal with plain Lights.
- **The Miyamoto tiers** replace the old threat tiers (`BossEncounterResource.MiyamotoTier`). `PostureEscalationComponent` on every foe with an encounter plays Tiers 1 and 2. At the threshold the foe leaps 3 m back over 220 ms (a rooted lasher stays put), an armour plate falls, and a lock ring lights on its chest. The key cracks it with a Bravery Counter: (60 + 45) x M(L) poise and a 2.5 s stun. A plain blow on a locked foe lands at half damage with a dull clank, so nobody is ever stuck. A Squire's one button finishes the Gap-Leap when a martial lock is up.

  | Tier | Foes | Lock |
  |---|---|---|
  | 0 Punching Bag | the expedition's kin, Oakshire's hobs and padfoots up to Lv 2 | none: Iron-Root cracks them for 1.25x poise, no text |
  | 1 Single Evade | Frost-Fang Padfoot (Lv 3), Bramble-Hobs (Lv 4-5) | martial (white-gold) at 75% |
  | 1 Single Evade | Furrow Iron-Men (Lv 3-4) | Warm-Hearth ink (their rust) at 75% |
  | 1 Single Evade | Crag-Spriggans (Lv 5) | Iron-Root ink (their shields) at 75% |
  | 2 Multi-Lock | the Crag-Back Cairn-Drake (Lv 6); the Shingle-Scray (data) | martial at 75%, Warm-Hearth at 50%, Iron-Root at 25% |
  | 3 Four-Gate Boss | the Cairnsman (Lv 5); the later bosses (data) | the four gates |

- **The four gates** (`BossGateComponent`, on the Cairnsman). Gate 1, the Measure: his roar opens Iron-Root or Star-Tide. Gate 2, the Summons, at 75%: he leaps 3 m back behind a glassy Aegis Mantle (a tenth of the damage) and three Bramble-Hobs answer. He can't fall past 50% while the mantle stands. Un-boggarting them shatters it and opens a Star-Tide Glimmer-Spot. Gate 3, the Tempest, at 50%: his Gale-Beam phase, and his weakness shifts to Warm-Hearth. Gate 4, the Seal-Turn, at 25%: a 45-frame Challenge-Roar and his upside-down Maker-Seal shows for the scaled window (168 frames on the second sighting). An Iron-Root strike or a One-and-Done turns it right-way up: `STATE_UNBOGGART_RELEASE`, the fight won there and then, and he's lulled into his cairn. Missed, the seal hides until his next roar. The HUD rhyme carries a badge for each Sign that cracks him now.
- **Gilding adds potency:** a Gilded Leaf card does 10% more damage, poise and healing (a Place-Card lends 10% more), and Star-Inked Vellum 20% more, with the quicker rite it already had. The Gilding Press shows the gain.
- **One widget, three places.** `CrossGrimoireDiamondWidget.set_presentation_mode()` is the one call. The weapon diamond shows its tier (I to IV) and the combo pips. The Binder grows the diamonds from 1.0x to 2.2x over 220 ms and lists the Combo Forms the party knows under the Place-Cards. Picking a card at the Scribery plays the pocket-draw on your puppet at the press.
- **Checks.** `test_phase_12_miyamoto_posture_trinity_and_grimoire_ux()` in the smoke test plays all of it in the Ring: the combos on the controller, both card animations, the One-and-Done, the Ward-Mantle against the swipe, the Aegis Ward and Ink-Share against a practice Iron-Man, a Frost-Fang and a Crag-Back, a practice Cairnsman through all four gates, the window maths, potency, and the widget in the Scribery and Binder. The Lens linter now reads the combo, tier, gate and lock names, and bans "tincture" and "catalyst" too. 528 checks pass.

**Deliberate differences from the brief**
- **The Hearth-Rite hold stays 120 frames** (80 on Star-Inked Vellum), as the Mythopoetic Lens set it (15 §6.2). The brief asks for 60 (0.65 s on Star-Inked). That's a Creative Director call.
- **The brief's file names** were mapped onto the code as it is. `ArsenalCatalog` lives in `src/actors/`. There's no `SaveManager` (`PartyProgress` is the save) and no `EnemyMob` or `EnemyAIController` (`WildMob`, `WoodlandMinion` and `BossDummy`). The combo state lives on `ComboChainComponent`, not `ActorBase`, the way Sign-Flow lives on `SignFlowComponent`. Small hooks went outside the brief's folders: the stick's sideways read and the posture step (`src/components`), the tether's pulse, the bestiary's encounters and blow Signs, potency in `LoadoutComposer`, and the clank in `AudioCues`.
- **`role_delivery` is the manifestation under its role's name**, the same stored value, so a card can't disagree with itself. Every Lantern-Tether leaf is a Support's Ink-Share leaf.
- **The tiers were renumbered.** The old Tier 1 (always open) is Tier 0, and §3's table still uses the old numbers. Oakshire's kin from Lv 3 now lock; before, they were roadside kin up to Lv 4.
- **The Ink-Share fires whenever a Support's R or L+R card starts in a fight**, not only from the Flow-Link Window, and it inks physical blows (Light, Heavy, ↑/↓+Heavy), not cards.
- **The Lantern's Promise reaches a tethered ally at any distance**, so a party with a Lantern-Bearer always has one ally on the 18-frame window. Worth watching on the couch.
- **"Shadow Sanctuary (10 m)" for the Support** is read as the Lantern-Bearer's Green Sanctuary; Shadow Sanctuary is the Tank's cone.
- **The Ward Blessing turns toward the first foe that strikes**, rather than toward an element, since foes don't have one element.
- **Tier 2's "multi-lock"** is a lock at each gate threshold, each with its own key (`gate_weakness_signs`).
- **Gate 2's henchmen** are Bramble-Hobs for the Cairnsman. The resource's default `mob_scree_worm` is registered, but it wears the Bramble-Hob's body until Scree-Worms have one. Henchmen pay trail XP but no Chimes.
- **The Seal-Turn ends the fight at once.** Without it, the boss is beaten the plain way at 0. The Cairnsman is lulled into his cairn either way.
- **The HUD's diamonds stay beside the slot grid at 172 px**; the brief says 140 px, bottom-centred. That's the same open call as in §7.
- **Screenshots:** `--screenshot=PATH` takes one frame of a normal launch, so a windowed probe (kept out of the repo) staged each moment instead and saved split-screen and close-up frames.

**Still to come**
- Bodies for Scree-Worm henchmen, and the bosses past the Cairnsman (their four gates are data only).
- The items still open from §7: the 3-Echo trail build-up, Chime-Post engravings, Place-Cards charted at landmark Chime-Posts, and live Tier 2 foes beyond the Crag-Back.

## 9. Build Notes (the Phase 12 Combat Kaizen Refinement: jump, sprint, debug switch, diamond HUD, Binder tabs, Gate 6)

The third Phase 12 brief (2026-11-04) asked for six increments, K1 to K6. This section says what each built and where the build differs on purpose. `tools/test_phase12_kaizen.gd` checks all of it (27 checks, run by the smoke test after the Caldera Isles').

**In the code now**
- **K1: jump, roll and sprint.** Jump is ✕ / A (Space), roll is ○ / B (L), sprint is L3 / LS (Left Shift), all through `tools/build_input_map.gd`. `JumpState` launches at 6.5 m/s (about 1 m high); the rig stretches up to 12% on the way up and squashes 16% for 0.18 s on landing (`HeroCombatAnimator`). Sprint is 1.5x the run, drains 12 stamina a second (no regen while sprinting), stops at 0 and waits for a fresh press. The run's lean reaches 1.5x further at a sprint (`StorybookKinematicsModifier3D.lean_reach`). In menus, jump backs out like roll.
- **K2: the debug hero switch.** F2, or holding Share (Create / View) and tapping D-Pad → or ←, steps `PlaytestSwitcher` through Bridge-Warden, Hedge-Runner and Bell-Keeper at Levels 3, 7 and 12: Fellowship, Calling, the trail kit for that level (weapon tier included) and the Grimoire level (1, 2 or 4), with a toast ("Debug Switch: Bridge-Warden Lv 7") and a banner. The session becomes a playtest: `PartyProgress.save()` and the Caldera's flags write nothing afterwards. The chord spends the Share press, so it never also opens the Binder or changes Fellowship.
- **K3: the minimal cross.** `CrossSlot` and its slot grid are deleted. `CrossGrimoireHUD` is the diamond widget at 1.3x plus two arcs (health left, stamina right), the pip gems on top, a small Chimes coin, the floating verb and the downed / staggered line, and the Lantern-Bearer's tether compass. The widget took over the slot grid's live marks: a press or buffered press flashes its diamond, a socket without its pips is dimmed, L glows while guarding, R rings gold (with a star) for a detonation, and each socket wears the hero's own key (Q / E / R; L2 / R2 / L2+R2). The combo pips (o - o - >) were already on the weapon diamond.
- **K4: the Binder's tabs.** `GrimoireBinderPanel.Tab` is GEAR, CARDS, COMBOS, ATLAS, labelled "1. Gear & Weapon", "2. Quick Magic-Ink Cards", "3. Combo Moves" and "Atlas Map", stepped with L / R in any menu (`InputComponent.MENU_TAB_PREV` / `MENU_TAB_NEXT`). It opens on the cards. A tooltip box under the title gives the tab's purpose and the highlighted row's meaning (a card's description, a combo's buttons and finisher, a gear row), and rows and tabs carry the same text as mouse tooltips. Gear & Weapon shows the live hero in a 300 x 380 window: a camera circling 3.2 m out at chest height in the shared world, a brighter copy of the sky with a quarter of the fog, a far-depth blur, and a warm key and cool rim light whose cull mask reaches only render layer 13, which the hero's meshes wear while the tab shows.
- **K5: the 70-20-10 Playground Linter (08 Gate 6).** On screen: *Plain Ink, Gilded Leaf, Star-Ink* (finishes); *Ink Blade, Ink Shield, Lantern-Tether* (how a card shows itself, and its cast's shout); *PARRY & STRIKE!* (the Bravery Counter); *INK READY* (the Hearth-Rite Tuck's shout); *Ink Cards: What You Do*, *the Ink Card Collection*, *Make Ink Cards*; *the Four Ink-Signs*. A source scan fails the smoke test if a retired word comes back in a string that can reach the screen.

**Where the build differs on purpose**
- **Button numbers.** The brief's `joy_button_8` (L3) and `joy_button_10` (Share) are not Godot's numbers. Godot numbers L3 as 7 and Share / Create / View as 4 (`JOY_BUTTON_LEFT_STICK`, `JOY_BUTTON_BACK`); the bindings use the named constants, so the buttons are the ones the brief means.
- **Keyboard roll moved from Space to L**, so Space can jump (and J / K / L sit under one hand). Space still closes menus.
- **Hold C / L3 for Calling is C only now**; L3 is sprint. A pad changes Calling at the Scribe Desk.
- **Share is a chord, not a cycle on its own.** A plain tap of Share still opens the Binder and its hold still changes Fellowship, so cycling needs Share held with a D-Pad tap. F2 is the keyboard's single press.
- **Level 12 is past the trail's top (Level 10).** The switcher's Level 12 wears Level 10's gear; the toast still says Lv 12 and the banner says why.
- **The cross keeps its arcs, pips and verb.** The brief asked for the diamonds alone; health, stamina and pips have no other home, so they stay as shapes with no numbers. The floating verb and "Downed" line are feedback, not labels.
- **Gear & Weapon shows gear; it doesn't change it.** The Scribe Desk stays the one place to change weapon and armour (Gate 2); light on a gear row says so.
- **The preview lights the live hero, not a copy.** A copy would need a second rig; the cost is that the key and rim light also touch that hero in other players' split-screen views while the tab is open.
- **Glimmer-Spot, Sign-Coat Grimoire Combat and the Four-Sign Ink-Wheel** weren't on screen anywhere, so there was nothing to rename; the README says *Glowing Spot*. Ids, class names, node names and save keys keep their old spellings, so old saves and network messages still read (the old finish names still read back too).

**Still to come**
- A pad shortcut for Calling if the Scribe Desk proves too far away.
- Jump has no gameplay use yet beyond getting over low things: no ledges, jump attacks or air dodges.
