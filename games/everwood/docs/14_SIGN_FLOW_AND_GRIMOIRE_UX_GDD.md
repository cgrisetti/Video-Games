# 14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md — Sign-Flow Combat, Location + Action Card Dioramas, & The Isomorphic Grimoire UX

## 1. Executive Summary & The Five-Gate Audit
This specification unifies **Sign-Flow Combat** (*"Coat, Break, Turn!"*), threat-tiered **Nursery Rhyme & Glimmer-Spot Scaling (Levels 1–60)**, the **Action Card + Location Card** diorama loadout system, **0-Pip Out-of-Combat Hearth-Rite Prep**, and the overhauled **Bramblebridge Grimoire Shop (*The Reed-Light Scribery*)** under a single isomorphic UI geometry.

| Gate ID | Compliance Verification |
|---|---|
| **GATE 1: Anti-Parasitic Harmony** | Location Cards, Action Cards, and 0-Pip Hearth-Rite Prep feed directly into Stamina/Poise, the Four Scribe Signs, the 3x3 Calling Matrix, and the **Chimes** economy. |
| **GATE 2: The Musk Razor** | Zero mid-combat deck scrolling, zero separate buff-card swap menus, and zero extra buttons. Out-of-combat prep and in-combat execution share the exact same `L`, `R`, and `L+R` postures. |
| **GATE 3: Philological Linter** | Replaces technical terms ("Front/Under-Card", "Unified Escalation System", "Buff Slot") with storybook folk terms: **Sign-Flow**, **Action-Leaf**, **Place-Card (Location Card)**, **Hearth-Rite Prep**, **Weapon-Coat**, **Ward-Mantle**, **Bravery Counter**, and **Seal-Turn**. |
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
- Collected by discovering landmark **Chime-Posts**, completing dungeon zones, or charting maps at the Bramblebridge Grimoire Shop.
- Defines **where the power draws its strength from**, framing the Action Card visually like a panoramic stage backdrop and augmenting its behavior:

| Location Card ID & Name | Native Sign | Source Landmark | Augmentation on Paired Action Card | Home-Ground Bonus (If Action Card Shares Sign) |
|---|---|---|---|---|
| `loc_ariundle_moss_oaks`<br>**Ariundle Moss-Oaks** | `SIGN_IRON_ROOT` *(Amber)* | Ariundle Trail Chime-Post | Adds `Root-Bind`: Weapon-Coat strikes slow enemy movement by `20%` and sprout mossy oak bark on the blade. | `+25%` Coat duration (`10.0s` total) & `+15.0` bonus Poise damage. |
| `loc_doverslap_gorge`<br>**Doverslap Gorge Bridge** | `SIGN_RIME_GALE` *(Sea-Azure)* | Doverslap Gatehouse | Adds `Gorge-Draft`: Extends weapon hitbox reach by `+0.8m` with a sweeping river-mist arc. | `+25%` Coat duration & `+15.0` bonus burst damage on *Glacial Rupture*. |
| `loc_bramblebridge_mill`<br>**Bramblebridge Hearth-Mill** | `SIGN_WARM_HEARTH` *(Saffron-Gold)* | Bramblebridge Green | Adds `Mill-Warmth`: Casting pulses a `4.0m` warm ember ring that heals allies for `6.0 HP` and melts `Furrow Iron-Man` rust. | `+25%` Coat duration & `+10.0 HP` bonus to *Dawnburst* party heal. |
| `loc_barrow_crag_tor`<br>**Barrow-Crag Star-Tor** | `SIGN_STAR_TIDE` *(Twilight-Violet)* | Ring of the Cairnsman | Adds `Star-Spark`: Refunds `8.0` Stamina on every Flow-Link cancel and wraps the weapon in violet starlight. | `+25%` Coat duration & `+0.25` extra Resonance Pips on *Astral Chorus*. |

---

## 5. Dual-State Execution: 0-Pip Out-of-Combat "Hearth-Rite Prep" vs. In-Combat "Sign-Flow"

Every slotted **Action + Location Card** pair operates in two automatic states without ever swapping cards:

| Execution State | Trigger Condition & Input | Resource Cost | Mechanical & Visual Effect |
|---|---|---|---|
| **State 1: Hearth-Rite Trail-Prep** *(Out of Combat)* | Party is out of combat (`in_combat == false`). Hold `R Skill` or `L+R Ult` for `90 frames` (`1.5s`). | **0 Pips** *(Free Pre-Fight Cast)* | 1. Hero raises their weapon as the **Location Card** vignette chimes softly.<br>2. Grants **Trail-Coat Blessing** (lasts until entering combat + `15.0s`, or until discharged): weapon visually glows at `1.35x` scale with the Location's particles while walking.<br>3. Pre-charges `+1.0` Resonance Pip ($1\diamond$) so the player never starts a fight resource-starved.<br>4. **Opening Strike Discharge:** Your very first strike or Bravery Counter in the next fight automatically unleashes a full-power Sign prime + Location effect. |
| **State 2: Active Sign-Flow** *(In Combat)* | Party is in combat (`in_combat == true`). Tap `L`, `R`, or `L+R` during any `Flow-Link Window`. | **`1.0 Pip` (`L`/`R`)** or **`3.0 Pips` (`L+R`)** | Instant (`0-frame` cast delay) recovery-canceling **Weapon-Coat**, **Ward-Mantle**, or **Lantern-Tether** at `2.0x` weapon scale with `110ms` Sakurai hit-stop and a `2.5m` ground Sign emblem. |

---

## 6. Isomorphic UX Architecture: HUD <-> Loadout Binder <-> Bramblebridge Grimoire Shop

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
- **Encounters.** `BossEncounterResource` holds the threat tier, level, counter Signs, windows and rhyme, with `get_scaled_glimmer_frames()` and `get_impact_multiplier()` as specified. `ArsenalCatalog` registers Roadside Kin and the Scree-Worm (Tier 1), the Shingle-Scray (Tier 2), and the Cairnsman (Lv 5), Gale-Bucca (10), Furrow Iron-Man (15), Cairn-Drake (25), Tor-Sleeper (50) and Old Hob (60).
- **Hearth-Rite Prep** (`src/combat/sign_flow_component.gd`, on every hero). Out of combat (no engaged foe within 18 m), holding R or L+R for 90 frames (60 on a Star-Inked Vellum leaf) costs no pip, tops the hero up to 1 pip, and holds the weapon at 1.35x in the Place-Card's tint, with a shoulder crest for a Ward-Mantle or three motes for a Lantern-Tether. The first strike that lands in the next fight carries the Sign, stamps its seal and adds the Place-Card's poise. The blessing fades 15 s into a fight if no strike lands.
- **Sign-Flow in combat.** Landing a Light, Heavy or directional Heavy opens a Flow-Link Window: 14 frames, 18 within 5.5 m of a Lantern-Bearer, 9 for a party of one (Dread-Chill). R (1 pip) or L+R (3 pips) pressed in it skips the wind-up; L tapped in it is a 1-pip Counter-Brace from the L leaf. The cast flares the weapon to 2.0x for 600 ms, freezes foes in the 2.5 m ring for 110 ms, stamps the ring, and coats the hero for the leaf's time (x1.25 on Home-Ground). While coated, every strike carries the Sign and the Place-Card's poise, reaches its extra distance, and a Flow-Link cancel refunds its stamina. Casting also mends friends within 4 m by the Place-Card's heal. A Ward-Mantle raises a 4 m shelter cone for 3 s; a Lantern-Tether mends the tethered ally for 6.
- **Glimmer-Spots** (`src/combat/glimmer_spot_component.gd`, on every foe with an encounter). The expedition's minions and Oakshire's creatures up to Level 4 are Tier 1: an Iron-Root strike does 1.25x poise and glints amber, with no text. The Cairnsman opens his spot as he roars into each raid cast (Iron-Root or Star-Tide cracks it). A counter Sign on an open spot is a Bravery Counter: (60 + 45) x M(L) poise plus the Sign's detonation, then the spot shuts. `PartyProgress` saves each boss's sightings (`[glimmer] seen`), which tighten the window, and the HUD rhyme shows on sightings 1 and 2 only. A Squire's press up to 90 frames before the roar is buffered and fires their R on its first frame.
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
- Seal-Turn (step 3) and `STATE_UNBOGGART_RELEASE`.
- Live Tier 2 foes, and the bosses past the Cairnsman (their encounters are data only).
- The 3-Echo trail build-up and Chime-Post engravings.
- Place-Cards charted at landmark Chime-Posts.
- The hero raising their weapon during the rite.
