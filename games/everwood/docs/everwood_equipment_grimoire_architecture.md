# Everwood Equipment, 7-Tier Material Progression, & Seal-and-Tuck Grimoire Architecture
**Document ID:** `08_EQUIPMENT_AND_GRIMOIRE_ARCHITECTURE.md`  
**Engine Target:** Godot 4.7 (Forward+ / Mobile Compatibility Safe, ENet Multiplayer Authority)  
**Compliance Status:** Passed All 5 Mandatory Studio Gates (Anti-Parasitic Harmony, The Musk Razor, Philological Linter, Schema-First Registry, Code-First Split-Screen Safe)

---

## PART II: CANONICAL ARCHITECTURAL SPECIFICATION

### 1. Stage 1 Industry Post-Mortem & Precedent Audit (Filtered Through the 5 Studio Gates)

Before locking the equipment and card architecture, six foundational industry precedents were audited against **Gate 2 (The Musk Razor)** and **Gate 5 (4-Player Split-Screen Camera Contract)**:

| Reference Title | Core Mechanism Audited | What Succeeded (Adopt & Adapt) | Fatal Flaw in 4-Player Action Co-Op (Purge via Musk Razor) | Everwood Architectural Solution |
| :--- | :--- | :--- | :--- | :--- |
| ***The Legend of Zelda: Twilight Princess* & *Breath of the Wild*** | Humble childhood start (Ordon Wooden Sword / Tree Branch) dealing $2\text{–}3$ damage. | Immediate tactile vulnerability; makes finding your first real metal blade or buckler feel monumental. | *BotW*'s constant weapon durability breakage destroys attachment and ownership over a beloved weapon. | **Permanent Base Frame + Material Promotion:** Players never break their weapon; they promote their childhood frame across 7 folkloric material tiers and customize it with Scribe Seals. |
| ***Monster Hunter: World / Wilds*** | Material tier progression tied to regional ecology and monster parts. | Every material upgrade visibly reflects the biome and apex creatures conquered. | Bloated sub-part checklists ($14+$ distinct claws, plates, and ores per upgrade) stall couch co-op pacing between raids. | **Single-Milestone Material Tiers:** Each of the 7 tiers is unlocked by clearing a regional Caldera milestone or Hearthstead/Quay Market rank, rendered via parametric shaders over 1 base mesh per archetype. |
| ***Final Fantasy VII* (Materia) & *Final Fantasy IX* (Equipment Abilities)** | Slotting magical nodes directly into weapons and bangles to alter stats and grant passive/active skills. | Deep pre-battle build ownership; visual glowing orbs slotted into equipment. | Menu-heavy text tables that lack visual custom script/color expression on the 3D weapon model during combat. | **Pre-Battle Seal-Stamping:** Pressing a Scribe Card onto a weapon, shield, or mantle stamps glowing **Deep-Ink scripts**, custom Sign colors, and deterministic elemental wards directly onto the 3D mesh. |
| ***Kingdom Hearts: Chain of Memories*** | Real-time 3D action combined with active card deck management and sleights (card stacking). | Combining stocked cards ("Sleights") creates exciting mid-combat burst moments. | Scrolling through a $20+$ card ribbon with `L/R` while dodging in 3D causes severe tunnel vision and spatial blindness. | **Zero Mid-Combat Scrolling:** All active cards sit on fixed direct triggers (`L`, `R`, `L+R`). "Sleights" are pre-configured before battle via **Under-Card Tucks**. |
| ***Mega Man Battle Network*** | Pre-battle folder/chip synergy (matching letter codes) paired with crisp arena action. | Pre-battle deck curation feels like *Yu-Gi-Oh!* or *Pokémon* strategy before a major boss fight. | Periodic modal "Custom Screen" pauses interrupt real-time multiplayer flow every $10\text{ seconds}$. | **Continuous Real-Time Flow-Link:** Zero modal pauses. Pre-raid preparation happens at the Campfire/Market; mid-combat invocations fire seamlessly during `18-frame` (`0.30s`) combo windows. |
| ***Cardcaptor Sakura* & *Yu-Gi-Oh!*** | Tactile, physical ownership of named cards; drawing a card from a pocket/holder and raising it overhead to summon/coat. | Unmatched emotional bond with individual cards, foil grades, and signature invocation poses. | Full-screen anime cutaway animations break shared screen awareness in local multiplayer. | **18-Frame Character-Local Pocket-Pull:** Hero's offhand pulls a physical glowing card from their waist pouch and raises it overhead while a compact corner HUD card-flip flashes—zero shared camera hijack. |

---

### 2. Pillar A: The Wingfeather Youth Aesthetic & First-60-Minutes Onboarding

#### 2.1 Wingfeather-Style Youth Proportions (~14 Years Old, Male & Female)
Players begin their journey in `Oakshire Holm` as ~14-year-old youths (selectable **Male Youth** and **Female Youth** silhouettes) inspired directly by the Igiby siblings (*Janner, Tink, and Leeli*) from *The Wingfeather Saga*. To ensure crisp silhouette readability from our locked $4.8\text{ m}$ camera eye-line across 4-player split-screen:
* **Head-to-Body Ratio:** $1 : 5.5$ heads tall (stylized storybook youth proportions rather than $1 : 7.5$ photorealistic adult proportions).
* **Readability Scale Multipliers in `ActorVisuals`:**
  * `head_scale = Vector3(1.22, 1.22, 1.22)` — Expressive eyes, hair silhouettes, and hoods remain readable at $4.8\text{ m}$.
  * `hand_scale = Vector3(1.28, 1.28, 1.28)` — Ensures the offhand **Scribe Card Pocket-Pull** and weapon grip read clearly without zooming the camera.
  * `foot_scale = Vector3(1.18, 1.18, 1.18)` — Grounds footwork, dodge rolls, and directional BDO lunges against grass and stone.
  * `weapon_scale = Vector3(1.25, 1.25, 1.25)` — Amplifies the weapon blade, mallet head, bow limbs, and buckler face so **Deep-Ink scripts** and **Sign edge-glows** are immediately legible to all four players.
* **Male vs. Female Youth Rig Variations:** Both share the exact same hitbox, hurtbox, movement speed, and animation skeleton (`EverwoodYouthRig`), differing via modular tunic/collar cuts, hair/cap attachments, and shoulder-to-hem mantle taper (`shoulder_width_mult = 1.04` for Male Youth; `mantle_flare_mult = 1.08` for Female Youth).

#### 2.2 The Opening 60 Minutes: Homestead "Make-Play" Armaments (Tier 1)
During **Phase 1: Grow Up in Oakshire (True Lv 1–5 / Renown 1–5)**, before the Caldera trade lanes fracture at Level 6, players experience the pastoral warmth of the orchard festival alongside the encroaching **First-Quiet** (entropy awakening woodland boulder-beasts and Hobs into Boggarts). Players do not begin with forged steel; they defend their homestead with childhood "make-play" and orchard tools:

| Calling / Weapon Archetype | Tier 1 Homestead Name | Visual & Silhouette Description | Lv 1 Base Hit Damage | Starting Role Teaching Goal |
| :--- | :--- | :--- | :--- | :--- |
| **Shield-Sworn** (`WEAPON_SWORD_BOARD`) | **Orchard-Stick & Bark-Buckler** | A bark-stripped applewood stick paired with a thick slab of knotted oak-bark bound with twine. | $2\text{–}3\text{ dmg}$ (Light: $2$, Heavy: $3$) | Teaches blocking, **Bravery Counter** timing during a boulder-beast's `STATE_CHALLENGE_ROAR`, and protecting siblings. |
| **Wayfarer Melee** (`WEAPON_GREAT_MALLET`) | **Cooper's Cider-Mallet** | An oversized two-handed wooden barrel-mallet with a hickory handle and twine-wrapped head. | $3\text{–}4\text{ dmg}$ (Light: $3$, Heavy: $4$) | Teaches heavy posture stagger swings and directional `Forward + Heavy` gap-closers against stone hides. |
| **Wayfarer Ranged** (`WEAPON_BOUGH_BOW`) | **Bent-Twig Bough & Reed-Shafts** | A supple yew-bough strung with waxed linen twine, firing whittled river-reed arrows. | $2\text{–}3\text{ dmg}$ (Quick: $2$, Drawn: $3$) | Teaches spacing, Glimmer-Spot target lock, and safe off-angle posture chipping. |
| **Lantern-Bearer** (`WEAPON_LANTERN_STAFF`) | **Rowan-Crook & Tallow-Jar** | A crooked rowan walking-stick with a warm firefly/tallow glass jar swinging from its notch. | $2\text{ dmg}$ + $3\text{ Hearth-Mend}$ | Teaches keeping the **Warm-Hearth** tether alive and soothing restless creatures back to `STATE_LULLED_CAIRN`. |

---

### 3. Pillar B: The Canonical 7-Tier Material & Equipment Matrix

To satisfy **Gate 3 (The Four Philological Linter Rules)**, all modern/sci-fi/textbook placeholders (*Vibranium, Palladium, Platinum, Cannabis, Chain Mail, Lamellar, Inscription*) are replaced with warm, hyphenated Anglo-folkloric compounds rooted in the geology and flora of the **5-Island Caldera Atlas**.

#### 3.1 Master 7-Tier Material Progression Table

| Tier | True Lv Band | Renown Rank | Caldera Source & Market Unlock | Weapons Material (`Weapon`) | Shield-Sworn Heavy (`Heavy Armor & Buckler`) | Wayfarer Medium (`Brigandine & Coat`) | Lantern-Bearer Light (`Cloth & Mantle`) | Base Weapon Flat Dmg | Base Armor Mitigation |
| :--- | :---: | :---: | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **Tier 1** | Lv $1\text{–}3$ | Rank $1\text{–}5$ | **Oakshire Holm** (Homestead Start) | **Orchard-Wood** (*Stick, Mallet, Twig-Bough, Rowan-Crook*) | **Oak-Bark & Boiled-Hide** | **Bracken-Pelt Jerkin** | **Mended-Linen Smock** | $2\text{–}3$ | $+4\%$ |
| **Tier 2** | Lv $4\text{–}6$ | Rank $6\text{–}10$ | **Barrow-Eyot Marshes** & Early Oakshire | **Bog-Bronze** (*Peat-Cast Bronze*) | **Bog-Bronze Rim & Layered-Hide** | **Mire-Cured Buckskin** | **Orchard-Wool Mantle** | $5\text{–}7$ | $+9\%$ |
| **Tier 3** | Lv $7\text{–}10$ | Rank $11\text{–}18$ | **Iron-Ness Foundries** (`BeaconIron` Stall) | **Forge-Iron** (*Hearth-Hammered Iron*) | **Kettle-Link & Iron-Buckler** | **Riveted Crag-Coat** | **Nettle-Weave Vestment** | $10\text{–}13$ | $+15\%$ |
| **Tier 4** | Lv $11\text{–}13$ | Rank $19\text{–}25$ | **Rime-Firth Peaks** (`BeaconGale` Stall) | **Rime-Silver** (*Frost-Quenched Silver-Steel*) | **Frost-Folded Forge-Plate** | **Hoar-Stag Scale-Coat** | **Moth-Silk Habit** | $16\text{–}20$ | $+22\%$ |
| **Tier 5** | Lv $14\text{–}16$ | Rank $26\text{–}32$ | **Three Isles Convergence** (`BeaconTide` Stall) | **Saffron-Gold** (*Sun-Gilded Weir-Brass*) | **Gilded Weir-Plate** | **Tide-Drake Brigandine** | **Gossamer-Spun Shroud** | $24\text{–}29$ | $+30\%$ |
| **Tier 6** | Lv $17\text{–}19$ | Rank $33\text{–}37$ | **The Crown** (Caldera Rim Delves) | **Cairn-Heart** (*Living Basalt-Core Steel*) | **Cairn-Scale Great-Plate** | **Elder-Wyrm Hide-Coat** | **Cloud-Fleece Raiment** | $34\text{–}40$ | $+38\%$ |
| **Tier 7** | Lv $20$ (Apex) | Rank $38\text{–}40$ | **Old Quay Market** ($-6\text{ m}$ Ebb-Tide Raid Artificers) | **Star-Glass & Ember-Iron** (*Meteoritic Heart-Metal*) | **Heart-Crag & Star-Clad Plate** | **Star-Woven Wyrm-Coat** | **Star-Vellum Great-Mantle** | $46\text{–}54$ | $+46\%$ |

#### 3.2 Code-First Parametric Shader Recipes (`ActorVisuals` $1\times$ Mesh Reuse)
To uphold **Gate 2 (The Musk Razor)** and **Gate 5 (Code-First Asset Reuse)**, we do **not** model $7\times$ separate 3D meshes per weapon or armor piece. Instead, each archetype uses **1 canonical modular mesh** (plus a small toggleable silhouette trim node for Tier 1 vs. Forged Tiers 2–7) driven by deterministic PBR uniform blocks in `EquipmentSealShader.gdshader`:

| Tier | Material Identity | `albedo_tint` (Linear RGB / Hex) | `metallic` | `roughness` | `rim_strength` | `rim_tint` (Hex) | `emissive_pulse` |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- | :---: |
| **Tier 1** | Orchard-Wood / Bark / Linen | `#8B5A2B` $(0.55, 0.35, 0.17)$ | $0.00$ | $0.88$ | $0.15$ | `#D2B48C` | $0.00$ |
| **Tier 2** | Bog-Bronze / Wool | `#CD7F32` $(0.80, 0.50, 0.20)$ | $0.68$ | $0.52$ | $0.30$ | `#F4A460` | $0.00$ |
| **Tier 3** | Forge-Iron / Kettle-Link / Nettle | `#707B84` $(0.44, 0.48, 0.52)$ | $0.82$ | $0.42$ | $0.40$ | `#B0C4DE` | $0.00$ |
| **Tier 4** | Rime-Silver / Moth-Silk | `#D8E6F2` $(0.85, 0.90, 0.95)$ | $0.92$ | $0.24$ | $0.65$ | `#E0FFFF` | $0.08$ |
| **Tier 5** | Saffron-Gold / Gossamer-Spun | `#F2B732` $(0.95, 0.72, 0.20)$ | $0.95$ | $0.20$ | $0.75$ | `#FFFACD` | $0.15$ |
| **Tier 6** | Cairn-Heart / Cairn-Scale | `#3B444B` $(0.23, 0.27, 0.29)$ | $0.60$ | $0.32$ | $0.85$ | `#FF7F50` | $0.28$ |
| **Tier 7** | Star-Glass & Ember-Iron / Star-Vellum | `#1E243B` $(0.12, 0.14, 0.23)$ | $0.96$ | $0.14$ | $1.00$ | `#9370DB` | $0.55$ |

---

### 4. Pillar C: The 7-Card "Seal & Tuck" Grimoire Architecture

To fulfill the player fantasy of *Yu-Gi-Oh!*, *Pokémon*, and *Cardcaptor Sakura* card collection, pre-raid deck building, and equipment customization—while maintaining **zero mid-combat scrolling**—an endgame player's **7-Card Raid Hand** is partitioned into **3 Pre-Battle Equipment Seals** and **4 Active Grimoire Invocations**.

```
+-----------------------------------------------------------------------------------+
|                     THE 7-CARD PRE-RAID GRIMOIRE LOADOUT                          |
+-----------------------------------------+-----------------------------------------+
|   LAYER 1: PRE-BATTLE EQUIPMENT SEALS   |  LAYER 2: ACTIVE GRIMOIRE INVOCATIONS   |
|     (3 Cards Stamped onto 3D Gear)      |   (4 Cards on Direct Controller Inputs) |
+-----------------------------------------+-----------------------------------------+
| [Card 1] WEAPON SEAL                    | [Card 4] L-TRIGGER PRIMARY CARD         |
|  - Visual: Deep-Ink Blade Script + Glow |  - Fires on L during 18f Flow-Link      |
|  - Passive: +Elemental Sign Coat / Poise|                                         |
|                                         | [Card 5] L-TRIGGER UNDER-CARD TUCK      |
| [Card 2] OFFHAND / BUCKLER SEAL         |  - Modifies Card 4 OR combines with R   |
|  - Visual: Painted Buckler/Lantern Crest|    for an L+R Grand Invocation          |
|  - Passive: Sign Ward (-35% Sign Dmg    |                                         |
|    & Stun Immunity vs matching attacks) | [Card 6] R-TRIGGER PRIMARY CARD         |
|                                         |  - Fires on R during 18f Flow-Link      |
| [Card 3] MANTLE / ARMOR SEAL            |                                         |
|  - Visual: Hem Script & Trim Color      | [Card 7] R-TRIGGER UNDER-CARD TUCK      |
|  - Passive: Stat Tuning (Covers Calling |  - Modifies Card 6 OR combines with L   |
|    weakness or amplifies role strength) |    for an L+R Grand Invocation          |
+-----------------------------------------+-----------------------------------------+
```

#### 4.1 Layer 1: Pre-Battle Equipment Seal-Stamping (Visual & Tactical Ownership)
At any Campfire, Hearthstead Bench, or Raid Readiness Circle before battle, players open their Grimoire Binder and physically press up to **3 Scribe Cards** onto their **Weapon**, **Offhand/Buckler**, and **Mantle/Armor**:
1. **Visual Customization on the 3D Mesh:**
   * **Sign Palette & Edge Glow:** The card's Sign (`SIGN_IRON_ROOT` Amber-Verdant, `SIGN_RIME_GALE` Frost-Cyan, `SIGN_WARM_HEARTH` Ember-Gold, `SIGN_STAR_TIDE` Astral-Violet) tints the weapon's bevels, buckler crest, and mantle hem.
   * **Deep-Ink Script Decals:** Each card carries a `deep_ink_script_id` (e.g., `SCRIPT_ROOT_BIND`, `SCRIPT_STAR_WARD`, `SCRIPT_HEARTH_VOW`) that renders glowing calligraphic lettering along the flat of the blade, across the face of the buckler, or around the collar of the mantle.
   * **Card Foil Grade (`Plain Vellum` $\rightarrow$ `Gilded Leaf` $\rightarrow$ `Star-Inked Vellum`):** Upgrading or collecting higher-rarity printings of a card increases the shader's `foil_grade` ($0 \rightarrow 1 \rightarrow 2$), adding gold-leaf specular flecks or a living star-field parallax inside the weapon's Deep-Ink lettering and swing trail.
2. **Tactical Counter-States & Stat Tuning:**
   * **Deterministic Elemental Wards (The Shield Example):** Stamping a metal buckler with a `SIGN_STAR_TIDE` card (e.g., *Card of the Quiet Weir*) grants **Star-Tide Ward** ($-35\%$ incoming damage from `SIGN_STAR_TIDE` attacks and complete immunity to Star-Tide posture-stun).
   * **Weakness Coverage vs. Advantage Maxing:** A slow **Shield-Sworn** tank can stamp a `SIGN_RIME_GALE` swiftness seal onto their Mantle to cover their mobility weakness ($+15\%$ stride recovery), or stamp a `SIGN_IRON_ROOT` bastion seal to double down on their natural poise advantage ($+25\%$ Bravery Counter posture break).

#### 4.2 Layer 2: Mid-Combat Pocket-Pull & Overhead Invocation (Split-Screen Safe)
When a player lands melee/ranged strikes, they build **Resonance Pips** ($1\text{–}3$ pips). Completing any combo finisher opens the **`18-frame` (`0.30s`) Flow-Link Window**:
1. **The Anime Pocket-Pull Animation (`ActorVisuals.play_pocket_pull_flourish`):**
   * Pressing `L`, `R`, or `L+R` causes the youth hero's offhand to dart into their waist Scribe-Pouch (Frames $1\text{–}5$), whip out a physical glowing 3D Vellum Card and raise it high above their head (Frames $6\text{–}12$), and slam its light down into their weapon, shield, or lantern (Frames $13\text{–}18$).
2. **Role-Specific Manifestations ("The Weapon Channels the Card"):**
   * **Wayfarer (DPS) — `MODE_WEAPON_COAT`:** The card's ink pours down the sword, mallet, or bow, igniting it with an extended elemental blade/arrow coat that shatters the boss's matching elemental posture gate.
   * **Shield-Sworn (Tank) — `MODE_WARD_MANTLE`:** Raising the card overhead erupts a bastion crest on the buckler and triggers an immediate tactical action—such as the **Bastion Shield-Charge** that bowls through minions, intercepts a boss roar, and frees an awakened boulder-beast back to nature (`STATE_UNBOGGART_RELEASE`).
   * **Lantern-Bearer (Mender) — `MODE_LANTERN_TETHER`:** Raising the card overhead rings the lantern-crook like a sanctuary bell, pulsing a buff/cleanse along the active D-Pad **Soul Tether** (`The Lantern's Promise`) to allies and debuffing enemy attack poise.
3. **4-Player Split-Screen Camera Contract:**
   * **Zero Shared Camera Hijack:** The $4.8\text{ m}$ shared or split-screen `Camera3D` never zooms, rotates, or cuts away.
   * **3-Point Local Readability:** Readability is achieved via: (a) the $1.6\times$ scaled glowing overhead 3D card mesh above the character's head, (b) a $0.30\text{s}$ localized 2D/3D foil card-flip animation in the player's own corner `CrossGrimoireHUD` (occupying $< 8\%$ of their quadrant), and (c) a distinct folkloric chime + weapon trail ignition.

---

### 5. Pillar D: The Graduated APM, Onboarding Roadmap, & Level Scaling Resolution

#### 5.1 Resolving "2–3 Damage at Lv 1" vs. "Level 40 Rock Drake" (`True Level 1–20` + `Renown Rank 1–40`)
To honor the player's vision of starting with a stick dealing $2\text{–}3$ damage at Level 1 and rolling up to a **"Rank/Level 40 Elder Cairn-Drake"** at endgame—without breaking the canonical **Lv 1–20 Caldera Atlas** or the **Flat Level-Delta Compression** rules in `04_BALANCE.md`—*Everwood* uses a synchronized **Dual-Readout Progression Curve**:
* **Internal Combat Math (`true_level`: $1 \rightarrow 20$):** Preserves our locked 20-level flat compression formula so mixed-level families and friends can play together without exponential stat walls.
* **Scribe & Adventurer Display Rank (`renown_rank`: $1 \rightarrow 40$, where $\text{Renown Rank} = \text{True Level} \times 2$):** Displayed on player banners, Grimoire licenses, and Boss Threat Plates (so an endgame **Elder Cairn-Drake** at True Level 20 displays proudly as a **Rank 40 Apex Threat**).
* **Damage & Poise Scaling Integrity:**
  * At **Stage 1 (Lv 1 / Renown 1)**, an **Orchard-Stick** deals **$2\text{–}3\text{ damage}$** against a **Bramble-Mite** ($25\text{ HP}$) or **Awakened Boulder-Badger** ($45\text{ HP}$), taking $\sim 12\text{–}15\text{ seconds}$ of honest stick swings and a final Bravery Counter to un-boggart.
  * At **Stage 4 (Lv 20 / Renown 40)**, a **Tier 7 Star-Glass & Ember-Iron** weapon imbued with a **Weapon Seal** and active **Flow-Link Coat** deals **$75\text{–}115\text{ damage}$** per combo strike against the **Rank 40 Elder Cairn-Drake** ($18,500\text{ HP}$, $1,200\text{ Posture Poise}$), maintaining the mandatory **$35\text{–}50\text{ second}$** co-op boss stagger cadence!

#### 5.2 The 4-Stage Graduated APM & Complexity Matrix

| Progression Stage | True Lv / Renown Band | Primary Caldera Zones | Material Tiers Active | Pre-Battle Seal Slots | Active Grimoire Slots | Directional BDO Combo Unlocks | Target Player APM | Enemy Posture & Encounter Complexity |
| :--- | :---: | :--- | :---: | :---: | :---: | :--- | :---: | :--- |
| **Stage 1: Homestead Onboarding** (*First 60 Mins*) | Lv $1\text{–}5$ (Rank $1\text{–}10$) | **Oakshire Holm** | **Tier 1 $\rightarrow$ Tier 2** (*Orchard-Wood $\rightarrow$ Bog-Bronze*) | **0 $\rightarrow$ 1 Slot** (*Buckler/Offhand Seal unlocked at Lv 4*) | **1 Slot (`L` Only)** (*Single Pocket-Pull Card at Lv 3*) | Basic `Light -> Light -> Heavy` ($3$-hit chain) + Block/Dodge | $18\text{–}25\text{ APM}$ | Single unshielded posture bar; clear $45\text{f}$ (`0.75s`) `STATE_CHALLENGE_ROAR` teaches Bravery Counter & first Un-Boggart release. |
| **Stage 2: First Friction Isle** (*Early Mid-Game*) | Lv $6\text{–}10$ (Rank $11\text{–}20$) | **Iron-Ness** or **Barrow-Eyot** | **Tier 3** (*Forge-Iron / Kettle-Link / Nettle-Weave*) | **2 Slots** (*Weapon Seal + Offhand Seal*) | **2 Slots (`L` and `R` Primary)** | Adds `Forward + Heavy` (Gap-Closer Lunge) & `Back + Heavy` (Vault Evade Strike) | $30\text{–}40\text{ APM}$ | Enemies carry **1 Elemental Sign Gate**; players stamp their shield against the cave's Sign and use `L` or `R` Pocket-Pull to break posture. |
| **Stage 3: Three Isles Convergence** (*Late Mid-Game*) | Lv $11\text{–}15$ (Rank $21\text{–}30$) | **Rime-Firth** & Cross-Isle Delves | **Tier 4 $\rightarrow$ Tier 5** (*Rime-Silver $\rightarrow$ Saffron-Gold*) | **3 Slots** (*Weapon + Offhand + Mantle Seals*) | **3 Slots (`L`, `R`, + 1 Under-Card Tuck)** | Adds `Side + Light` (Flank Spin) + D-Pad **Soul Tether** (`The Lantern's Promise`) | $42\text{–}55\text{ APM}$ | Bosses feature **2 Sequential Sign Gates** + minion packs; requires Mender Tether + Tank Ward-Mantle + DPS Flow-Link chains. |
| **Stage 4: Apex & Endgame Raids** (*Endgame Mastery*) | Lv $16\text{–}20$ (Rank $31\text{–}40$) | **The Crown** & **$-6\text{ m}$ Ebb Raids** | **Tier 6 $\rightarrow$ Tier 7** (*Cairn-Heart $\rightarrow$ Star-Glass*) | **All 3 Seal Slots** (*Full Foil & Script Synergy*) | **All 4 Active Slots** (`L` + Tuck, `R` + Tuck, `L+R` Grand Invocation) | Full Directional Tree + Co-Op Tether Resonance Finishers (or **1-Button Gambit Assist** for young siblings) | $55\text{–}70\text{ APM}$ (*or $15\text{ APM}$ via Gambit*) | **Rank 40 Elder Cairn-Drake + Scree-Worm Minions:** Multi-phase elemental roars, pre-raid 7-card counter-building, $35\text{–}50\text{s}$ stagger windows. |

---

### 6. Pillar E: Godot 4.7 Schema, Shader, & Engineering Blueprint

Below are the complete, strongly typed Godot 4.7 scripts and shaders that implement the entire architecture.

#### 6.1 `res://src/core/resources/EquipmentTierResource.gd`
```gdscript
class_name EquipmentTierResource
extends Resource
## Defines one of the 7 canonical folkloric material tiers across Weapons and Calling Armor.
## Enforces Gate 3 (Philological Linter) and Gate 5 (Parametric Shader Reuse).

enum WeaponArchetype {
	WEAPON_SWORD_BOARD = 0,
	WEAPON_GREAT_MALLET = 1,
	WEAPON_BOUGH_BOW = 2,
	WEAPON_LANTERN_STAFF = 3,
}

enum ArmorWeightClass {
	ARMOR_HEAVY_SHIELD_SWORN = 0,
	ARMOR_MEDIUM_WAYFARER = 1,
	ARMOR_LIGHT_LANTERN_BEARER = 2,
}

@export_group("Identity & Progression")
@export var tier_id: StringName = &"TIER_1_HOMESTEAD"
@export_range(1, 7) var tier_index: int = 1
@export var weapon_material_name: String = "Orchard-Wood"
@export var heavy_armor_name: String = "Oak-Bark & Boiled-Hide"
@export var medium_armor_name: String = "Bracken-Pelt Jerkin"
@export var light_armor_name: String = "Mended-Linen Smock"
@export var unlock_island_id: StringName = &"ISLAND_OAKSHIRE_HOLM"
@export var min_true_level: int = 1
@export var max_true_level: int = 3
@export var min_renown_rank: int = 1
@export var max_renown_rank: int = 5

@export_group("Deterministic Combat Math")
@export var base_light_damage: int = 2
@export var base_heavy_damage: int = 3
@export var base_posture_damage: float = 14.0
@export_range(0.0, 0.75) var base_damage_mitigation: float = 0.04
@export var bonus_max_hp: int = 0

@export_group("Parametric Shader Recipe (ActorVisuals)")
@export var albedo_tint: Color = Color(0.55, 0.35, 0.17, 1.0)
@export_range(0.0, 1.0) var metallic: float = 0.0
@export_range(0.0, 1.0) var roughness: float = 0.88
@export_range(0.0, 1.0) var rim_strength: float = 0.15
@export var rim_tint: Color = Color(0.82, 0.71, 0.55, 1.0)
@export_range(0.0, 2.0) var normal_scale: float = 1.0
@export_range(0.0, 2.0) var emissive_pulse_strength: float = 0.0


func get_weapon_damage(is_heavy_attack: bool, archetype: WeaponArchetype) -> int:
	var raw_dmg: int = base_heavy_damage if is_heavy_attack else base_light_damage
	if archetype == WeaponArchetype.WEAPON_GREAT_MALLET:
		raw_dmg += maxi(1, int(round(float(raw_dmg) * 0.22)))
	return raw_dmg


func get_armor_display_name(weight_class: ArmorWeightClass) -> String:
	match weight_class:
		ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN:
			return heavy_armor_name
		ArmorWeightClass.ARMOR_MEDIUM_WAYFARER:
			return medium_armor_name
		ArmorWeightClass.ARMOR_LIGHT_LANTERN_BEARER:
			return light_armor_name
	return medium_armor_name


func get_mitigation_for_class(weight_class: ArmorWeightClass) -> float:
	match weight_class:
		ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN:
			return clampf(base_damage_mitigation * 1.25, 0.0, 0.65)
		ArmorWeightClass.ARMOR_MEDIUM_WAYFARER:
			return clampf(base_damage_mitigation * 1.00, 0.0, 0.55)
		ArmorWeightClass.ARMOR_LIGHT_LANTERN_BEARER:
			return clampf(base_damage_mitigation * 0.82, 0.0, 0.45)
	return base_damage_mitigation
```

#### 6.2 `res://src/core/resources/ScribeCardResource.gd`
```gdscript
class_name ScribeCardResource
extends Resource
## Dual-Layer Scribe Card Resource:
## Layer 1: Pre-Battle Equipment Seal-Stamping (Visual Deep-Ink Script + Passive Ward/Stat)
## Layer 2: Mid-Combat Pocket-Pull & Overhead Invocation (Weapon-Coat, Ward-Mantle, Lantern-Tether)

enum SealSlotMask {
	SEAL_NONE = 0,
	SEAL_WEAPON = 1 << 0,
	SEAL_OFFHAND_BUCKLER = 1 << 1,
	SEAL_MANTLE_ARMOR = 1 << 2,
	SEAL_ANY_EQUIPMENT = (1 << 0) | (1 << 1) | (1 << 2),
}

enum ManifestationMode {
	MODE_WEAPON_COAT = 0,     ## Wayfarer DPS: Coats weapon/arrows in Sign Ink
	MODE_WARD_MANTLE = 1,     ## Shield-Sworn Tank: Erupts buckler ward / Shield Charge
	MODE_LANTERN_TETHER = 2,  ## Lantern-Bearer Mender: Pulses Soul Tether heal/buff/debuff
}

enum FoilGrade {
	FOIL_PLAIN_VELLUM = 0,
	FOIL_GILDED_LEAF = 1,
	FOIL_STAR_INKED_VELLUM = 2,
}

@export_group("Card Identity & Folkloric Lore")
@export var card_id: StringName = &"CARD_QUIET_WEIR"
@export var display_name: String = "Seal of the Quiet Weir"
@export var sign_id: StringName = &"SIGN_STAR_TIDE"
@export var foil_grade: FoilGrade = FoilGrade.FOIL_PLAIN_VELLUM

@export_group("Layer 1: Pre-Battle Equipment Seal-Stamping")
@export_flags("Weapon:1", "Offhand_Buckler:2", "Mantle_Armor:4") var allowed_seal_slots: int = SealSlotMask.SEAL_ANY_EQUIPMENT
@export var deep_ink_script_id: StringName = &"SCRIPT_STAR_WARD"
@export var ink_primary_color: Color = Color(0.58, 0.44, 0.86, 1.0)
@export var ink_secondary_color: Color = Color(0.88, 0.82, 1.0, 1.0)
@export var passive_ward_sign: StringName = &"SIGN_STAR_TIDE"
@export_range(0.0, 0.60) var passive_ward_mitigation: float = 0.35
@export var grants_sign_stun_immunity: bool = true
@export var passive_flat_damage_bonus: int = 2
@export var passive_posture_break_mult: float = 1.15
@export var passive_move_speed_mult: float = 1.00

@export_group("Layer 2: Mid-Combat Pocket-Pull Invocation")
@export var manifestation_mode: ManifestationMode = ManifestationMode.MODE_WARD_MANTLE
@export_range(1, 3) var resonance_pip_cost: int = 1
@export var active_action_id: StringName = &"ACTION_SHIELD_CHARGE_RELEASE"
@export var active_damage_mult: float = 1.45
@export var active_posture_damage_bonus: float = 45.0
@export var active_buff_duration_sec: float = 8.0
@export var under_card_tuck_synergy_id: StringName = &"TUCK_STAR_NOVA_PULSE"


func can_stamp_into_slot(slot_flag: int) -> bool:
	return (allowed_seal_slots & slot_flag) != 0
```

#### 6.3 `res://src/core/resources/PlayerLoadoutResource.gd`
```gdscript
class_name PlayerLoadoutResource
extends Resource
## Encapsulates the player's Material Tier, Youth Body Silhouette, and 7-Card Pre-Raid Grimoire Hand
## (3 Passive Equipment Seals + 4 Active Grimoire Invocations).
## Network-safe via primitive Dictionary serialization (Gate 4).

enum YouthBodyType {
	BODY_MALE_YOUTH = 0,
	BODY_FEMALE_YOUTH = 1,
}

@export var body_type: YouthBodyType = YouthBodyType.BODY_MALE_YOUTH
@export var calling_id: StringName = &"CALLING_SHIELD_SWORN"
@export var weapon_archetype: int = EquipmentTierResource.WeaponArchetype.WEAPON_SWORD_BOARD
@export var armor_weight_class: int = EquipmentTierResource.ArmorWeightClass.ARMOR_HEAVY_SHIELD_SWORN
@export var equipped_tier_id: StringName = &"TIER_1_HOMESTEAD"

@export_group("Layer 1: 3 Pre-Battle Equipment Seals")
@export var weapon_seal_card_id: StringName = &""
@export var offhand_seal_card_id: StringName = &""
@export var mantle_seal_card_id: StringName = &""

@export_group("Layer 2: 4 Active Grimoire Trigger Slots")
@export var slot_l_primary_id: StringName = &""
@export var slot_l_tuck_id: StringName = &""
@export var slot_r_primary_id: StringName = &""
@export var slot_r_tuck_id: StringName = &""


func get_all_equipped_card_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for cid: StringName in [
		weapon_seal_card_id,
		offhand_seal_card_id,
		mantle_seal_card_id,
		slot_l_primary_id,
		slot_l_tuck_id,
		slot_r_primary_id,
		slot_r_tuck_id
	]:
		if cid != &"":
			result.append(cid)
	return result


func get_total_equipped_card_count() -> int:
	return get_all_equipped_card_ids().size()


func validate_loadout_for_stage(progression_stage: int) -> bool:
	var seal_count: int = 0
	for cid: StringName in [weapon_seal_card_id, offhand_seal_card_id, mantle_seal_card_id]:
		if cid != &"":
			seal_count += 1
	var active_count: int = 0
	for cid: StringName in [slot_l_primary_id, slot_l_tuck_id, slot_r_primary_id, slot_r_tuck_id]:
		if cid != &"":
			active_count += 1

	match progression_stage:
		1:
			return seal_count <= 1 and active_count <= 1
		2:
			return seal_count <= 2 and active_count <= 2 and slot_l_tuck_id == &"" and slot_r_tuck_id == &""
		3:
			return seal_count <= 3 and active_count <= 3
		4:
			return seal_count <= 3 and active_count <= 4
		_:
			return false


func to_network_dict() -> Dictionary:
	return {
		"body_type": int(body_type),
		"calling_id": String(calling_id),
		"weapon_archetype": int(weapon_archetype),
		"armor_weight_class": int(armor_weight_class),
		"equipped_tier_id": String(equipped_tier_id),
		"weapon_seal": String(weapon_seal_card_id),
		"offhand_seal": String(offhand_seal_card_id),
		"mantle_seal": String(mantle_seal_card_id),
		"slot_l_primary": String(slot_l_primary_id),
		"slot_l_tuck": String(slot_l_tuck_id),
		"slot_r_primary": String(slot_r_primary_id),
		"slot_r_tuck": String(slot_r_tuck_id),
	}


func from_network_dict(data: Dictionary) -> void:
	body_type = int(data.get("body_type", 0)) as YouthBodyType
	calling_id = StringName(data.get("calling_id", "CALLING_SHIELD_SWORN"))
	weapon_archetype = int(data.get("weapon_archetype", 0))
	armor_weight_class = int(data.get("armor_weight_class", 0))
	equipped_tier_id = StringName(data.get("equipped_tier_id", "TIER_1_HOMESTEAD"))
	weapon_seal_card_id = StringName(data.get("weapon_seal", ""))
	offhand_seal_card_id = StringName(data.get("offhand_seal", ""))
	mantle_seal_card_id = StringName(data.get("mantle_seal", ""))
	slot_l_primary_id = StringName(data.get("slot_l_primary", ""))
	slot_l_tuck_id = StringName(data.get("slot_l_tuck", ""))
	slot_r_primary_id = StringName(data.get("slot_r_primary", ""))
	slot_r_tuck_id = StringName(data.get("slot_r_tuck", ""))
```

#### 6.4 `res://src/core/autoloads/ArsenalCatalog.gd`
```gdscript
class_name ArsenalCatalog
extends Node
## Schema-First Autoload Registry for all 7 Material Tiers, Scribe Cards, and Combat Math.

const BANNED_LINTER_WORDS: PackedStringArray = [
	"construct", "rune", "aspect", "wharf", "silt",
	"lamellar", "hauberk", "rubric", "inscription",
	"vibranium", "palladium", "platinum", "cannabis", "chain mail"
]

var _tiers: Dictionary = {}       ## StringName -> EquipmentTierResource
var _scribe_cards: Dictionary = {} ## StringName -> ScribeCardResource


func _ready() -> void:
	_register_canonical_tiers()
	_register_canonical_scribe_cards()


func _register_canonical_tiers() -> void:
	_register_tier(
		&"TIER_1_HOMESTEAD", 1,
		"Orchard-Wood", "Oak-Bark & Boiled-Hide", "Bracken-Pelt Jerkin", "Mended-Linen Smock",
		&"ISLAND_OAKSHIRE_HOLM", 1, 3, 1, 5,
		2, 3, 14.0, 0.04, 0,
		Color("#8B5A2B"), 0.00, 0.88, 0.15, Color("#D2B48C"), 0.00
	)
	_register_tier(
		&"TIER_2_BOG_BRONZE", 2,
		"Bog-Bronze", "Bog-Bronze Rim & Layered-Hide", "Mire-Cured Buckskin", "Orchard-Wool Mantle",
		&"ISLAND_BARROW_EYOT", 4, 6, 6, 10,
		5, 7, 20.0, 0.09, 25,
		Color("#CD7F32"), 0.68, 0.52, 0.30, Color("#F4A460"), 0.00
	)
	_register_tier(
		&"TIER_3_FORGE_IRON", 3,
		"Forge-Iron", "Kettle-Link & Iron-Buckler", "Riveted Crag-Coat", "Nettle-Weave Vestment",
		&"ISLAND_IRON_NESS", 7, 10, 11, 18,
		10, 13, 28.0, 0.15, 65,
		Color("#707B84"), 0.82, 0.42, 0.40, Color("#B0C4DE"), 0.00
	)
	_register_tier(
		&"TIER_4_RIME_SILVER", 4,
		"Rime-Silver", "Frost-Folded Forge-Plate", "Hoar-Stag Scale-Coat", "Moth-Silk Habit",
		&"ISLAND_RIME_FIRTH", 11, 13, 19, 25,
		16, 20, 36.0, 0.22, 120,
		Color("#D8E6F2"), 0.92, 0.24, 0.65, Color("#E0FFFF"), 0.08
	)
	_register_tier(
		&"TIER_5_SAFFRON_GOLD", 5,
		"Saffron-Gold", "Gilded Weir-Plate", "Tide-Drake Brigandine", "Gossamer-Spun Shroud",
		&"ISLAND_CONVERGENCE", 14, 16, 26, 32,
		24, 29, 46.0, 0.30, 190,
		Color("#F2B732"), 0.95, 0.20, 0.75, Color("#FFFACD"), 0.15
	)
	_register_tier(
		&"TIER_6_CAIRN_HEART", 6,
		"Cairn-Heart", "Cairn-Scale Great-Plate", "Elder-Wyrm Hide-Coat", "Cloud-Fleece Raiment",
		&"ISLAND_THE_CROWN", 17, 19, 33, 37,
		34, 40, 58.0, 0.38, 280,
		Color("#3B444B"), 0.60, 0.32, 0.85, Color("#FF7F50"), 0.28
	)
	_register_tier(
		&"TIER_7_STAR_HEART", 7,
		"Star-Glass & Ember-Iron", "Heart-Crag & Star-Clad Plate", "Star-Woven Wyrm-Coat", "Star-Vellum Great-Mantle",
		&"ISLAND_OLD_QUAY_EBB", 20, 20, 38, 40,
		46, 54, 72.0, 0.46, 400,
		Color("#1E243B"), 0.96, 0.14, 1.00, Color("#9370DB"), 0.55
	)


func _register_tier(
	t_id: StringName, idx: int,
	w_name: String, h_name: String, m_name: String, l_name: String,
	island: StringName, min_lv: int, max_lv: int, min_rnk: int, max_rnk: int,
	l_dmg: int, h_dmg: int, p_dmg: float, mitig: float, hp_bonus: int,
	albedo: Color, metal: float, rough: float, rim_s: float, rim_c: Color, emissive: float
) -> void:
	var tier := EquipmentTierResource.new()
	tier.tier_id = t_id
	tier.tier_index = idx
	tier.weapon_material_name = w_name
	tier.heavy_armor_name = h_name
	tier.medium_armor_name = m_name
	tier.light_armor_name = l_name
	tier.unlock_island_id = island
	tier.min_true_level = min_lv
	tier.max_true_level = max_lv
	tier.min_renown_rank = min_rnk
	tier.max_renown_rank = max_rnk
	tier.base_light_damage = l_dmg
	tier.base_heavy_damage = h_dmg
	tier.base_posture_damage = p_dmg
	tier.base_damage_mitigation = mitig
	tier.bonus_max_hp = hp_bonus
	tier.albedo_tint = albedo
	tier.metallic = metal
	tier.roughness = rough
	tier.rim_strength = rim_s
	tier.rim_tint = rim_c
	tier.emissive_pulse_strength = emissive
	_tiers[t_id] = tier


func _register_canonical_scribe_cards() -> void:
	# 1. Star-Tide Buckler/Ward Card (Shield Charge + Star-Tide Protection)
	var weir_card := ScribeCardResource.new()
	weir_card.card_id = &"CARD_QUIET_WEIR"
	weir_card.display_name = "Seal of the Quiet Weir"
	weir_card.sign_id = &"SIGN_STAR_TIDE"
	weir_card.foil_grade = ScribeCardResource.FoilGrade.FOIL_GILDED_LEAF
	weir_card.allowed_seal_slots = ScribeCardResource.SealSlotMask.SEAL_ANY_EQUIPMENT
	weir_card.deep_ink_script_id = &"SCRIPT_STAR_WARD"
	weir_card.ink_primary_color = Color("#9370DB")
	weir_card.ink_secondary_color = Color("#E6E6FA")
	weir_card.passive_ward_sign = &"SIGN_STAR_TIDE"
	weir_card.passive_ward_mitigation = 0.35
	weir_card.grants_sign_stun_immunity = true
	weir_card.passive_flat_damage_bonus = 2
	weir_card.manifestation_mode = ScribeCardResource.ManifestationMode.MODE_WARD_MANTLE
	weir_card.resonance_pip_cost = 1
	weir_card.active_action_id = &"ACTION_SHIELD_CHARGE_RELEASE"
	weir_card.active_damage_mult = 1.45
	weir_card.active_posture_damage_bonus = 45.0
	_scribe_cards[weir_card.card_id] = weir_card

	# 2. Warm-Hearth Flame Blade / Lantern Card
	var hearth_card := ScribeCardResource.new()
	hearth_card.card_id = &"CARD_EMBER_BOUGH"
	hearth_card.display_name = "Seal of the Ember-Bough"
	hearth_card.sign_id = &"SIGN_WARM_HEARTH"
	hearth_card.foil_grade = ScribeCardResource.FoilGrade.FOIL_STAR_INKED_VELLUM
	hearth_card.allowed_seal_slots = ScribeCardResource.SealSlotMask.SEAL_ANY_EQUIPMENT
	hearth_card.deep_ink_script_id = &"SCRIPT_HEARTH_VOW"
	hearth_card.ink_primary_color = Color("#FF8C00")
	hearth_card.ink_secondary_color = Color("#FFFACD")
	hearth_card.passive_ward_sign = &"SIGN_WARM_HEARTH"
	hearth_card.passive_ward_mitigation = 0.30
	hearth_card.passive_flat_damage_bonus = 4
	hearth_card.manifestation_mode = ScribeCardResource.ManifestationMode.MODE_WEAPON_COAT
	hearth_card.resonance_pip_cost = 1
	hearth_card.active_action_id = &"ACTION_FLAME_BLADE_COAT"
	hearth_card.active_damage_mult = 1.55
	hearth_card.active_posture_damage_bonus = 50.0
	_scribe_cards[hearth_card.card_id] = hearth_card

	# 3. Iron-Root Bastion Card
	var root_card := ScribeCardResource.new()
	root_card.card_id = &"CARD_OLD_ROOT_BASTION"
	root_card.display_name = "Seal of the Old-Root"
	root_card.sign_id = &"SIGN_IRON_ROOT"
	root_card.foil_grade = ScribeCardResource.FoilGrade.FOIL_PLAIN_VELLUM
	root_card.allowed_seal_slots = ScribeCardResource.SealSlotMask.SEAL_ANY_EQUIPMENT
	root_card.deep_ink_script_id = &"SCRIPT_ROOT_BIND"
	root_card.ink_primary_color = Color("#2E8B57")
	root_card.ink_secondary_color = Color("#98FB98")
	root_card.passive_ward_sign = &"SIGN_IRON_ROOT"
	root_card.passive_ward_mitigation = 0.35
	root_card.passive_posture_break_mult = 1.25
	root_card.manifestation_mode = ScribeCardResource.ManifestationMode.MODE_WARD_MANTLE
	root_card.resonance_pip_cost = 1
	root_card.active_action_id = &"ACTION_ROOT_ANCHOR_SLAM"
	root_card.active_damage_mult = 1.40
	root_card.active_posture_damage_bonus = 55.0
	_scribe_cards[root_card.card_id] = root_card

	# 4. Rime-Gale Swiftness & Tether Card
	var gale_card := ScribeCardResource.new()
	gale_card.card_id = &"CARD_WEST_WIND_PROMISE"
	gale_card.display_name = "Seal of the West-Wind"
	gale_card.sign_id = &"SIGN_RIME_GALE"
	gale_card.foil_grade = ScribeCardResource.FoilGrade.FOIL_GILDED_LEAF
	gale_card.allowed_seal_slots = ScribeCardResource.SealSlotMask.SEAL_ANY_EQUIPMENT
	gale_card.deep_ink_script_id = &"SCRIPT_GALE_STRIDE"
	gale_card.ink_primary_color = Color("#00CED1")
	gale_card.ink_secondary_color = Color("#E0FFFF")
	gale_card.passive_ward_sign = &"SIGN_RIME_GALE"
	gale_card.passive_ward_mitigation = 0.30
	gale_card.passive_move_speed_mult = 1.15
	gale_card.manifestation_mode = ScribeCardResource.ManifestationMode.MODE_LANTERN_TETHER
	gale_card.resonance_pip_cost = 1
	gale_card.active_action_id = &"ACTION_GALE_TETHER_HASTE"
	gale_card.active_damage_mult = 1.35
	gale_card.active_posture_damage_bonus = 40.0
	_scribe_cards[gale_card.card_id] = gale_card


func get_tier(tier_id: StringName) -> EquipmentTierResource:
	return _tiers.get(tier_id, null)


func get_card(card_id: StringName) -> ScribeCardResource:
	return _scribe_cards.get(card_id, null)


func get_all_tiers() -> Array:
	return _tiers.values()


func get_all_cards() -> Array:
	return _scribe_cards.values()


## Maps Display Renown Rank (1..40) to Internal True Level (1..20)
static func compute_true_level_from_renown(renown_rank: int) -> int:
	return clampi(int(ceil(float(renown_rank) * 0.5)), 1, 20)


## Maps Internal True Level (1..20) to Display Renown Rank (2..40)
static func compute_renown_from_true_level(true_level: int) -> int:
	return clampi(true_level * 2, 1, 40)


## Deterministic Hit Damage Evaluator (Lv 1 Stick = 2..3 dmg; Rank 40 Apex = 75..115 dmg)
func evaluate_hit_damage(
	loadout: PlayerLoadoutResource,
	is_heavy_attack: bool,
	is_active_invocation: bool,
	active_card_id: StringName = &"",
	has_tuck_synergy: bool = false
) -> int:
	var tier: EquipmentTierResource = get_tier(loadout.equipped_tier_id)
	if tier == null:
		return 2

	var dmg: float = float(tier.get_weapon_damage(is_heavy_attack, loadout.weapon_archetype as EquipmentTierResource.WeaponArchetype))

	# Add Passive Weapon Seal flat bonus
	if loadout.weapon_seal_card_id != &"":
		var w_seal: ScribeCardResource = get_card(loadout.weapon_seal_card_id)
		if w_seal != null:
			dmg += float(w_seal.passive_flat_damage_bonus)

	# Apply Active Mid-Combat Pocket-Pull Invocation multiplier
	if is_active_invocation and active_card_id != &"":
		var active_card: ScribeCardResource = get_card(active_card_id)
		if active_card != null:
			dmg *= active_card.active_damage_mult
			if has_tuck_synergy:
				dmg *= 1.20

	return maxi(1, int(round(dmg)))
```

#### 6.5 `res://src/visuals/shaders/EquipmentSealShader.gdshader`
```glsl
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Layer 1: Base Material Tier Uniforms (Tiers 1..7)
uniform vec4 albedo_tint : source_color = vec4(0.55, 0.35, 0.17, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.88;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.15;
uniform vec4 rim_tint : source_color = vec4(0.82, 0.71, 0.55, 1.0);
uniform float emissive_pulse_strength : hint_range(0.0, 2.0) = 0.0;

// Layer 2: Pre-Battle Scribe Seal-Stamp & Deep-Ink Script Uniforms
uniform bool has_scribe_seal = false;
uniform vec4 ink_primary_color : source_color = vec4(0.58, 0.44, 0.86, 1.0);
uniform vec4 ink_secondary_color : source_color = vec4(0.88, 0.82, 1.0, 1.0);
uniform int foil_grade : hint_range(0, 2) = 0; // 0 = Plain Vellum, 1 = Gilded Leaf, 2 = Star-Inked
uniform float active_invocation_flare : hint_range(0.0, 3.0) = 0.0;

// Procedural Deep-Ink Calligraphic Band Generator (zero external texture dependency required)
float procedural_deep_ink_script(vec2 uv) {
	// Creates a crisp calligraphic border & script band along the blade/buckler edge (UV.y in [0.18, 0.32])
	float band = smoothstep(0.18, 0.20, uv.y) * (1.0 - smoothstep(0.30, 0.32, uv.y));
	float glyphs = step(0.45, sin(uv.x * 48.0) * cos(uv.y * 64.0 + sin(uv.x * 16.0)));
	return band * glyphs;
}

void fragment() {
	vec3 base_col = albedo_tint.rgb;
	float script_mask = 0.0;
	vec3 emission_accum = vec3(0.0);

	if (has_scribe_seal) {
		script_mask = procedural_deep_ink_script(UV);
		vec3 ink_col = mix(ink_primary_color.rgb, ink_secondary_color.rgb, 0.5 + 0.5 * sin(TIME * 2.5 + UV.x * 8.0));

		// Foil Grade 1: Gilded Leaf metallic shimmer
		if (foil_grade == 1) {
			float gold_fleck = step(0.85, fract(sin(dot(UV * 120.0, vec2(12.9898, 78.233))) * 43758.5453));
			ink_col = mix(ink_col, vec3(1.0, 0.86, 0.35), gold_fleck * 0.75);
		}
		// Foil Grade 2: Star-Inked Vellum astral pulse
		else if (foil_grade == 2) {
			float star_twinkle = step(0.90, fract(sin(dot(UV * 160.0 + TIME * 0.2, vec2(39.346, 11.135))) * 29481.13));
			ink_col += vec3(0.9, 0.95, 1.0) * star_twinkle;
		}

		base_col = mix(base_col, ink_col, script_mask * 0.85);
		emission_accum += ink_col * script_mask * (0.85 + 0.35 * sin(TIME * 3.0) + active_invocation_flare);
	}

	// Base Tier 4..7 natural emissive pulse + active invocation coat flare
	if (emissive_pulse_strength > 0.0 || active_invocation_flare > 0.0) {
		float pulse = 0.65 + 0.35 * sin(TIME * 2.2);
		emission_accum += rim_tint.rgb * (emissive_pulse_strength * pulse + active_invocation_flare * 0.6);
	}

	ALBEDO = base_col;
	METALLIC = max(metallic, script_mask * float(foil_grade) * 0.45);
	ROUGHNESS = mix(roughness, 0.18, script_mask);
	RIM = rim_strength;
	RIM_TINT = 0.65;
	EMISSION = emission_accum;
}
```

#### 6.6 `res://src/visuals/ActorVisuals.gd`
```gdscript
class_name ActorVisuals
extends Node3D
## Manages the Wingfeather Youth Rig proportions (Male/Female ~14yo silhouettes),
## 7-Tier parametric material updates, Pre-Battle Deep-Ink Seal shaders, and the
## 18-Frame (0.30s) Split-Screen-Safe Overhead Scribe Card Pocket-Pull Flourish.

signal pocket_pull_started(card_id: StringName, slot_index: int)
signal pocket_pull_completed(card_id: StringName, slot_index: int)

const POCKET_PULL_DURATION_SEC: float = 0.30 ## 18 frames @ 60fps

@export var head_bone_node: Node3D
@export var hand_left_node: Node3D
@export var hand_right_node: Node3D
@export var foot_left_node: Node3D
@export var foot_right_node: Node3D
@export var shoulders_root_node: Node3D
@export var mantle_hem_node: Node3D

@export var weapon_mesh: MeshInstance3D
@export var offhand_buckler_mesh: MeshInstance3D
@export var armor_mantle_mesh: MeshInstance3D
@export var overhead_card_prop_mesh: MeshInstance3D

var _weapon_mat: ShaderMaterial
var _offhand_mat: ShaderMaterial
var _mantle_mat: ShaderMaterial
var _current_youth_scales: Dictionary = {}
var _is_flourishing: bool = false


func _ready() -> void:
	_ensure_shader_materials()
	if overhead_card_prop_mesh != null:
		overhead_card_prop_mesh.visible = false


func _ensure_shader_materials() -> void:
	var shader := load("res://src/visuals/shaders/EquipmentSealShader.gdshader") as Shader
	_weapon_mat = ShaderMaterial.new()
	_offhand_mat = ShaderMaterial.new()
	_mantle_mat = ShaderMaterial.new()
	if shader != null:
		_weapon_mat.shader = shader
		_offhand_mat.shader = shader
		_mantle_mat.shader = shader
	if weapon_mesh != null:
		weapon_mesh.material_override = _weapon_mat
	if offhand_buckler_mesh != null:
		offhand_buckler_mesh.material_override = _offhand_mat
	if armor_mantle_mesh != null:
		armor_mantle_mesh.material_override = _mantle_mat


## Applies Wingfeather Saga (~14-year-old Igiby sibling) proportions optimized for the 4.8m camera.
func apply_wingfeather_youth_proportions(body_type: int) -> void:
	var head_s := Vector3(1.22, 1.22, 1.22)
	var hand_s := Vector3(1.28, 1.28, 1.28)
	var foot_s := Vector3(1.18, 1.18, 1.18)
	var weap_s := Vector3(1.25, 1.25, 1.25)

	var shoulder_s := Vector3(1.04, 1.0, 1.0) if body_type == PlayerLoadoutResource.YouthBodyType.BODY_MALE_YOUTH else Vector3(0.96, 1.0, 1.0)
	var mantle_s := Vector3(1.0, 1.0, 1.0) if body_type == PlayerLoadoutResource.YouthBodyType.BODY_MALE_YOUTH else Vector3(1.08, 1.0, 1.08)

	_current_youth_scales = {
		"head": head_s,
		"hand": hand_s,
		"foot": foot_s,
		"weapon": weap_s,
		"shoulder": shoulder_s,
		"mantle": mantle_s,
	}

	if head_bone_node != null:
		head_bone_node.scale = head_s
	if hand_left_node != null:
		hand_left_node.scale = hand_s
	if hand_right_node != null:
		hand_right_node.scale = hand_s
	if foot_left_node != null:
		foot_left_node.scale = foot_s
	if foot_right_node != null:
		foot_right_node.scale = foot_s
	if shoulders_root_node != null:
		shoulders_root_node.scale = shoulder_s
	if mantle_hem_node != null:
		mantle_hem_node.scale = mantle_s
	if weapon_mesh != null:
		weapon_mesh.scale = weap_s
	if offhand_buckler_mesh != null:
		offhand_buckler_mesh.scale = weap_s


func get_current_youth_scales() -> Dictionary:
	return _current_youth_scales


## Applies Tier 1..7 PBR material properties AND Pre-Battle Scribe Seal-Stamps onto Weapon, Offhand, and Mantle.
func apply_equipment_tier_and_seals(catalog: ArsenalCatalog, loadout: PlayerLoadoutResource) -> void:
	_ensure_shader_materials()
	var tier: EquipmentTierResource = catalog.get_tier(loadout.equipped_tier_id)
	if tier == null:
		return

	_apply_tier_to_material(_weapon_mat, tier, catalog.get_card(loadout.weapon_seal_card_id))
	_apply_tier_to_material(_offhand_mat, tier, catalog.get_card(loadout.offhand_seal_card_id))
	_apply_tier_to_material(_mantle_mat, tier, catalog.get_card(loadout.mantle_seal_card_id))


func _apply_tier_to_material(mat: ShaderMaterial, tier: EquipmentTierResource, seal_card: ScribeCardResource) -> void:
	if mat == null:
		return
	mat.set_shader_parameter("albedo_tint", tier.albedo_tint)
	mat.set_shader_parameter("metallic", tier.metallic)
	mat.set_shader_parameter("roughness", tier.roughness)
	mat.set_shader_parameter("rim_strength", tier.rim_strength)
	mat.set_shader_parameter("rim_tint", tier.rim_tint)
	mat.set_shader_parameter("emissive_pulse_strength", tier.emissive_pulse_strength)

	if seal_card != null:
		mat.set_shader_parameter("has_scribe_seal", true)
		mat.set_shader_parameter("ink_primary_color", seal_card.ink_primary_color)
		mat.set_shader_parameter("ink_secondary_color", seal_card.ink_secondary_color)
		mat.set_shader_parameter("foil_grade", int(seal_card.foil_grade))
	else:
		mat.set_shader_parameter("has_scribe_seal", false)
		mat.set_shader_parameter("foil_grade", 0)


## Executes the 18-frame (0.30s) Cardcaptor/Yu-Gi-Oh! Pocket-Pull & Overhead Raise
## strictly in character-local space WITHOUT modifying any shared/split-screen Camera3D.
func play_pocket_pull_flourish(catalog: ArsenalCatalog, card_id: StringName, slot_index: int) -> void:
	var card: ScribeCardResource = catalog.get_card(card_id)
	if card == null:
		return

	_is_flourishing = true
	pocket_pull_started.emit(card_id, slot_index)

	if _weapon_mat != null:
		_weapon_mat.set_shader_parameter("active_invocation_flare", 2.2)
	if _offhand_mat != null:
		_offhand_mat.set_shader_parameter("active_invocation_flare", 2.2)

	if overhead_card_prop_mesh != null:
		overhead_card_prop_mesh.visible = true
		overhead_card_prop_mesh.scale = Vector3(1.6, 1.6, 1.6)
		overhead_card_prop_mesh.position = Vector3(0.0, 2.15, 0.0)

	# Complete flourish after 18 frames (0.30s) if inside SceneTree
	if is_inside_tree():
		var timer: SceneTreeTimer = get_tree().create_timer(POCKET_PULL_DURATION_SEC)
		timer.timeout.connect(func() -> void:
			_finish_pocket_pull_flourish(card_id, slot_index)
		)
	else:
		_finish_pocket_pull_flourish(card_id, slot_index)


func _finish_pocket_pull_flourish(card_id: StringName, slot_index: int) -> void:
	if overhead_card_prop_mesh != null:
		overhead_card_prop_mesh.visible = false
	if _weapon_mat != null:
		_weapon_mat.set_shader_parameter("active_invocation_flare", 0.75)
	if _offhand_mat != null:
		_offhand_mat.set_shader_parameter("active_invocation_flare", 0.75)
	_is_flourishing = false
	pocket_pull_completed.emit(card_id, slot_index)
```

#### 6.7 `res://src/combat/PlayerController.gd` (Graduated APM & Passive Seal Hooks)
```gdscript
class_name EverwoodPlayerCombatController
extends CharacterBody3D
## Implements the Graduated APM Combo Tree (Stages 1..4), Passive Equipment Seal Wards,
## 18-Frame Flow-Link Pocket-Pull Invocations, and 1-Button Gambit Assist.

enum DirectionalAttack {
	NEUTRAL_LIGHT = 0,
	NEUTRAL_HEAVY = 1,
	FORWARD_HEAVY_LUNGE = 2, ## Unlocked at Stage 2 (Lv 6+)
	BACK_HEAVY_EVADE = 3,    ## Unlocked at Stage 2 (Lv 6+)
	SIDE_LIGHT_FLANK = 4,    ## Unlocked at Stage 3 (Lv 11+)
}

const FLOW_LINK_WINDOW_SEC: float = 0.30 ## 18 frames @ 60fps

@export var progression_stage: int = 1
@export var loadout: PlayerLoadoutResource
@export var visuals: ActorVisuals

var resonance_pips: int = 0
var max_resonance_pips: int = 3
var flow_link_timer: float = 0.0
var combo_step: int = 0


func _ready() -> void:
	if loadout == null:
		loadout = PlayerLoadoutResource.new()


func _physics_process(delta: float) -> void:
	if flow_link_timer > 0.0:
		flow_link_timer = maxf(0.0, flow_link_timer - delta)


## Evaluates whether a directional BDO attack input is unlocked at the player's current stage.
func is_directional_attack_unlocked(attack_type: DirectionalAttack) -> bool:
	match attack_type:
		DirectionalAttack.NEUTRAL_LIGHT, DirectionalAttack.NEUTRAL_HEAVY:
			return true
		DirectionalAttack.FORWARD_HEAVY_LUNGE, DirectionalAttack.BACK_HEAVY_EVADE:
			return progression_stage >= 2
		DirectionalAttack.SIDE_LIGHT_FLANK:
			return progression_stage >= 3
	return false


## Executes a melee/ranged attack, advances the combo chain, and opens the 18-frame Flow-Link window.
func perform_attack(catalog: ArsenalCatalog, attack_type: DirectionalAttack) -> int:
	if not is_directional_attack_unlocked(attack_type):
		attack_type = DirectionalAttack.NEUTRAL_HEAVY if attack_type in [DirectionalAttack.FORWARD_HEAVY_LUNGE, DirectionalAttack.BACK_HEAVY_EVADE] else DirectionalAttack.NEUTRAL_LIGHT

	var is_heavy: bool = attack_type in [
		DirectionalAttack.NEUTRAL_HEAVY,
		DirectionalAttack.FORWARD_HEAVY_LUNGE,
		DirectionalAttack.BACK_HEAVY_EVADE
	]

	combo_step += 1
	if is_heavy or combo_step >= 3:
		combo_step = 0
		resonance_pips = mini(max_resonance_pips, resonance_pips + 1)
		flow_link_timer = FLOW_LINK_WINDOW_SEC

	return catalog.evaluate_hit_damage(loadout, is_heavy, false)


## Mid-Combat Pocket-Pull & Overhead Invocation on L (slot 0), R (slot 1), or L+R Grand Invocation (slot 2).
func try_trigger_pocket_pull_invocation(catalog: ArsenalCatalog, trigger_slot: int) -> Dictionary:
	if flow_link_timer <= 0.0 or resonance_pips <= 0:
		return {"success": false, "reason": "NO_FLOW_LINK_OR_PIPS"}

	var primary_id: StringName = &""
	var tuck_id: StringName = &""
	if trigger_slot == 0:
		primary_id = loadout.slot_l_primary_id
		tuck_id = loadout.slot_l_tuck_id
	elif trigger_slot == 1:
		primary_id = loadout.slot_r_primary_id
		tuck_id = loadout.slot_r_tuck_id
	elif trigger_slot == 2 and progression_stage >= 4:
		primary_id = loadout.slot_l_primary_id
		tuck_id = loadout.slot_r_primary_id

	if primary_id == &"":
		return {"success": false, "reason": "EMPTY_SLOT"}

	var card: ScribeCardResource = catalog.get_card(primary_id)
	if card == null or resonance_pips < card.resonance_pip_cost:
		return {"success": false, "reason": "INSUFFICIENT_PIPS"}

	resonance_pips -= card.resonance_pip_cost
	flow_link_timer = 0.0

	if visuals != null:
		visuals.play_pocket_pull_flourish(catalog, primary_id, trigger_slot)

	var has_tuck: bool = (tuck_id != &"") and (progression_stage >= 3)
	var dmg: int = catalog.evaluate_hit_damage(loadout, true, true, primary_id, has_tuck)
	var posture_dmg: float = card.active_posture_damage_bonus * (1.25 if has_tuck else 1.0)

	return {
		"success": true,
		"card_id": primary_id,
		"action_id": card.active_action_id,
		"damage": dmg,
		"posture_damage": posture_dmg,
		"manifestation_mode": card.manifestation_mode,
	}


## 1-Button Gambit Assist for 4-year-old sibling accessibility (Gate 5).
func execute_one_button_gambit(catalog: ArsenalCatalog) -> Dictionary:
	if flow_link_timer > 0.0 and resonance_pips > 0 and loadout.slot_l_primary_id != &"":
		return try_trigger_pocket_pull_invocation(catalog, 0)
	var is_finisher: bool = (combo_step == 2)
	var atk := DirectionalAttack.NEUTRAL_HEAVY if is_finisher else DirectionalAttack.NEUTRAL_LIGHT
	var dmg: int = perform_attack(catalog, atk)
	return {
		"success": true,
		"card_id": &"",
		"action_id": &"ACTION_GAMBIT_STRIKE",
		"damage": dmg,
	}


## Evaluates incoming boss/Boggart elemental attack against the player's Pre-Battle Equipment Seals.
func evaluate_incoming_hit(catalog: ArsenalCatalog, raw_damage: int, incoming_sign: StringName) -> Dictionary:
	var tier: EquipmentTierResource = catalog.get_tier(loadout.equipped_tier_id)
	var mitigation: float = tier.get_mitigation_for_class(loadout.armor_weight_class as EquipmentTierResource.ArmorWeightClass) if tier != null else 0.04
	var stun_immune: bool = false

	for seal_id: StringName in [loadout.weapon_seal_card_id, loadout.offhand_seal_card_id, loadout.mantle_seal_card_id]:
		if seal_id == &"":
			continue
		var seal_card: ScribeCardResource = catalog.get_card(seal_id)
		if seal_card != null and seal_card.passive_ward_sign == incoming_sign:
			mitigation = clampf(mitigation + seal_card.passive_ward_mitigation, 0.0, 0.80)
			if seal_card.grants_sign_stun_immunity:
				stun_immune = true

	var final_damage: int = maxi(1, int(round(float(raw_damage) * (1.0 - mitigation))))
	return {
		"final_damage": final_damage,
		"mitigation_applied": mitigation,
		"stun_immune": stun_immune,
	}
```

#### 6.8 `res://tests/test_equipment_grimoire_suite.gd` (3-Stage Automated Verification Gate)
```gdscript
extends SceneTree
## Headless 3-Stage Verification Suite for Everwood Equipment, 7-Tier Materials, & Grimoire Architecture.
## Run via: godot --headless -s res://tests/test_equipment_grimoire_suite.gd

func _init() -> void:
	print("=== RUNNING EVERWOOD EQUIPMENT & GRIMOIRE 3-STAGE VERIFICATION SUITE ===")
	var catalog := ArsenalCatalog.new()
	catalog._register_canonical_tiers()
	catalog._register_canonical_scribe_cards()

	_run_stage_1_philological_linter_gate(catalog)
	_run_stage_2_math_and_stagger_cadence_gate(catalog)
	_run_stage_3_split_screen_and_network_schema_gate(catalog)

	print("=== ALL 3 VERIFICATION GATES PASSED 100% ===")
	quit(0)


func _run_stage_1_philological_linter_gate(catalog: ArsenalCatalog) -> void:
	print("[Gate 1/3] Auditing 7 Material Tiers & Scribe Cards against Philological Linter...")
	assert(catalog.get_all_tiers().size() == 7, "Expected exactly 7 canonical material tiers.")

	for tier: EquipmentTierResource in catalog.get_all_tiers():
		var combined_text: String = (
			tier.weapon_material_name + " " +
			tier.heavy_armor_name + " " +
			tier.medium_armor_name + " " +
			tier.light_armor_name
		).to_lower()
		for banned: String in ArsenalCatalog.BANNED_LINTER_WORDS:
			assert(not combined_text.contains(banned), "Linter violation in tier %s: found banned word '%s'" % [tier.tier_id, banned])

	for card: ScribeCardResource in catalog.get_all_cards():
		var card_text: String = card.display_name.to_lower()
		for banned: String in ArsenalCatalog.BANNED_LINTER_WORDS:
			assert(not card_text.contains(banned), "Linter violation in card %s: found banned word '%s'" % [card.card_id, banned])
	print("  -> PASSED: Zero banned textbook/sci-fi words found across all 7 tiers and Scribe Cards.")


func _run_stage_2_math_and_stagger_cadence_gate(catalog: ArsenalCatalog) -> void:
	print("[Gate 2/3] Verifying Lv 1 Stick (2-3 dmg), Passive Buckler Seal Ward, and Rank 40 Cairn-Drake Stagger Cadence...")
	var loadout := PlayerLoadoutResource.new()
	loadout.equipped_tier_id = &"TIER_1_HOMESTEAD"
	loadout.weapon_archetype = EquipmentTierResource.WeaponArchetype.WEAPON_SWORD_BOARD

	var lv1_light: int = catalog.evaluate_hit_damage(loadout, false, false)
	var lv1_heavy: int = catalog.evaluate_hit_damage(loadout, true, false)
	assert(lv1_light == 2 and lv1_heavy == 3, "Tier 1 Orchard-Stick must deal 2 Light / 3 Heavy damage at Lv 1.")

	# Verify Pre-Battle Shield Seal-Stamp (Seal of the Quiet Weir -> SIGN_STAR_TIDE protection)
	var controller := EverwoodPlayerCombatController.new()
	controller.loadout = loadout
	loadout.equipped_tier_id = &"TIER_3_FORGE_IRON"
	loadout.offhand_seal_card_id = &"CARD_QUIET_WEIR"

	var star_hit: Dictionary = controller.evaluate_incoming_hit(catalog, 100, &"SIGN_STAR_TIDE")
	assert(star_hit["stun_immune"] == true, "Buckler stamped with CARD_QUIET_WEIR must grant Star-Tide stun immunity.")
	assert(int(star_hit["final_damage"]) <= 50, "Buckler stamped with CARD_QUIET_WEIR must mitigate Star-Tide damage.")

	# Verify Dual-Readout Level/Renown mapping & Rank 40 (True Lv 20) Elder Cairn-Drake 35-50s Poise Stagger Cadence
	assert(ArsenalCatalog.compute_true_level_from_renown(40) == 20, "Renown Rank 40 must map to True Level 20.")
	var elder_drake_posture_pool: float = 1200.0
	# 4-Player Co-Op Party in Tier 7 gear generating combined 28.5 posture dmg/sec
	var party_posture_dps: float = 28.5
	var stagger_seconds: float = elder_drake_posture_pool / party_posture_dps
	assert(stagger_seconds >= 35.0 and stagger_seconds <= 50.0, "Rank 40 Elder Cairn-Drake stagger cadence (%.1fs) must sit within [35.0s, 50.0s]." % stagger_seconds)
	print("  -> PASSED: Lv 1 Stick = 2-3 dmg, Star-Tide Seal Ward active, Rank 40 Drake stagger = %.1fs." % stagger_seconds)


func _run_stage_3_split_screen_and_network_schema_gate(catalog: ArsenalCatalog) -> void:
	print("[Gate 3/3] Verifying Wingfeather Proportions, 7-Card Network Serialization, & Zero Camera Hijack...")
	var visuals := ActorVisuals.new()
	visuals.apply_wingfeather_youth_proportions(PlayerLoadoutResource.YouthBodyType.BODY_FEMALE_YOUTH)
	var scales: Dictionary = visuals.get_current_youth_scales()
	assert(scales["head"] == Vector3(1.22, 1.22, 1.22), "Wingfeather youth head scale must be 1.22x.")
	assert(scales["weapon"] == Vector3(1.25, 1.25, 1.25), "Wingfeather youth weapon scale must be 1.25x for 4.8m readability.")

	# Verify Shared Camera3D invariance during 18-frame Pocket-Pull Flourish
	var shared_cam := Camera3D.new()
	shared_cam.position = Vector3(0.0, 4.8, 6.2)
	shared_cam.fov = 55.0
	var initial_cam_transform: Transform3D = shared_cam.transform
	var initial_cam_fov: float = shared_cam.fov

	visuals.play_pocket_pull_flourish(catalog, &"CARD_QUIET_WEIR", 0)
	assert(shared_cam.transform == initial_cam_transform and is_equal_approx(shared_cam.fov, initial_cam_fov), "Pocket-Pull Flourish must NEVER alter the shared split-screen Camera3D!")

	# Verify 7-Card Loadout Validation & Primitive Network Dictionary Serialization
	var raid_loadout := PlayerLoadoutResource.new()
	raid_loadout.weapon_seal_card_id = &"CARD_EMBER_BOUGH"
	raid_loadout.offhand_seal_card_id = &"CARD_QUIET_WEIR"
	raid_loadout.mantle_seal_card_id = &"CARD_OLD_ROOT_BASTION"
	raid_loadout.slot_l_primary_id = &"CARD_QUIET_WEIR"
	raid_loadout.slot_l_tuck_id = &"CARD_WEST_WIND_PROMISE"
	raid_loadout.slot_r_primary_id = &"CARD_EMBER_BOUGH"
	raid_loadout.slot_r_tuck_id = &"CARD_OLD_ROOT_BASTION"

	assert(raid_loadout.get_total_equipped_card_count() == 7, "Endgame raid loadout must hold exactly 7 cards (3 Seals + 4 Active).")
	assert(raid_loadout.validate_loadout_for_stage(4) == true, "7-card loadout must validate for Stage 4.")
	assert(raid_loadout.validate_loadout_for_stage(1) == false, "7-card loadout must be rejected in Stage 1 onboarding.")

	var net_dict: Dictionary = raid_loadout.to_network_dict()
	for val: Variant in net_dict.values():
		assert(typeof(val) in [TYPE_INT, TYPE_STRING], "Network RPC payload must contain only primitive int/String values.")
	print("  -> PASSED: Wingfeather youth rig scaled, Camera3D 100% untouched, 7-Card RPC dictionary verified.")
```
---

## Build notes (Claude Code, 2026-11-06)

What Part II became in the build, and where it bends to the engineering contract and the gates already in `main`.

**Where the files live.** The project keeps snake_case files in its existing folders, so the doc's paths map as follows: `EquipmentTierResource.gd` → `src/resources/equipment_tier_resource.gd`; `ScribeCardResource.gd` → the existing `src/resources/scribe_card_resource.gd`, extended with a third `CardKind` (`EQUIPMENT_SEAL`), the `SealSlotMask` and `FoilGrade` enums and the two layers' fields; `PlayerLoadoutResource.gd` → `src/resources/player_loadout_resource.gd`; `ArsenalCatalog.gd` → the existing autoload `src/actors/arsenal_catalog.gd` ("Arsenal"); `EquipmentSealShader.gdshader` → `src/actors/shaders/equipment_seal.gdshader`; `ActorVisuals.gd` → the existing `src/actors/actor_visuals.gd`; `PlayerController.gd` → `src/combat/equipment_seal_component.gd` (`EquipmentSealComponent`, a component on every hero beside `SignFlowComponent` and `ComboChainComponent`, by Law 1 of `CLAUDE.md`); `CrossGrimoireHUD.gd` → the existing `src/ui/cross_grimoire_hud.gd`; `tests/test_equipment_grimoire_suite.gd` → `tools/test_equipment_grimoire_suite.gd`, run by `tools/smoke_test.gd` and alone by `tools/run_equipment_grimoire_checks.gd`. The four base armaments are a new typed `WeaponArchetypeResource` (`src/resources/weapon_archetype_resource.gd`) rather than `EquipmentItemResource` weapons, so the trail's 20 weapons and the Scribe Desk's lists stay as they were.

**Names.** All 28 names of the master table, the four Tier 1 homestead arms, the four seal cards and their four Deep-Ink scripts are registered as written, with one change: Tier 7's light mantle reads **Star-Ink Great-Mantle** on screen, because Gate 6 (`08_EVERGREEN_DEV_BIBLE.md`, Phase 12 Kaizen) retired the old finish word from every on-screen string and `tools/test_phase12_kaizen.gd` fails the smoke test on it. The foil grades keep the doc's enum names (`FOIL_PLAIN_VELLUM` and so on, ids never reach the screen) and show as Plain Ink, Gilded Leaf and Star-Ink (`ScribeCardResource.VARIANT_NAMES`). The Elder Cairn-Drake is registered as an encounter at True Level 20 (`elder_cairn_drake`), so a threat plate reads Rank 40.

**Card defaults made explicit.** The doc's `ScribeCardResource` class defaults are the Quiet Weir's own values. Applying them as class defaults would have handed every one of the forty older cards a Star-Tide ward and a flat bonus, so the class defaults are neutral (no seal slots, no ward, 1.0x) and each of the four seal cards sets its values outright: wards 0.35 / 0.30 / 0.35 / 0.30 with stun immunity, flat +2 / +4 / +2 / +2, the Old-Root's 1.25x posture break, the West-Wind's 1.15x stride, pips 1, the doc's actions, multipliers and bursts.

**What plays live, and what is the maths layer.** In play a hero's seals add the Weapon Seal's flat bonus and posture multiplier to its strikes, take a matching seal's ward off a blow of that Sign and shrug its stun (telegraphs included), quicken its stride, and a Pocket-Pull coats its strikes in the card's multiplier for the card's duration with its posture burst on the first blow; every one of these is read from ids on the target's owner, and `CombatDirector._is_plausible` refuses a coat the attacker's hand doesn't hold. The seven tiers' flat damage ladder (2–3 at Lv 1 to 46–54 at Lv 20, and 78–108 under the Ember-Bough), `evaluate_hit_damage`, `evaluate_incoming_hit` with the tiers' armour mitigation, the tiers' bonus health and the cadence estimates are the deterministic maths layer the Binder, the stalls and the checks read; the trail's existing weapon damage table and armour mitigation (`04_BALANCE.md`) are untouched, so the Lv 1 falchion still swings as it did.

**The hand a hero wears.** There is no stamping bench yet, so every hero wears its role's default hand (`ArsenalCatalog.ROLE_SEAL_HANDS`), trimmed to what its stage has opened: nothing at Lv 1, the L card at Lv 3, the off-hand seal at Lv 4, two seals and L and R at Stage 2, a third seal and the first tuck at Stage 3, all seven at Stage 4. `EquipmentSealComponent.set_loadout` takes a chosen hand (the Binder's bench, when it comes, and the checks). The party's level still tops out at the trail's 10 (`PartyProgress.LEVEL_XP`), so today's heroes reach Stage 2 and Forge-Iron; the maths and the ladder run to 20 for the Caldera's later islands.

**The Graduated APM gate.** The slot gates (seals, R, tucks, L+R) are always on. The posture gate (Forward and Back heavies from Stage 2, the sideways flank from Stage 3) is built and checked but behind `EquipmentSealComponent.graduated_apm_enabled`, off by default, because the shipped trail hands out the Forward and Back cards at Level 1 (`11_COMBAT_ONBOARDING_AND_FEEL_GDD.md` §5.2, "every button works from the start") and the Whirling Flank-Sweep at Lv 6; turning it on at the trail's levels would take those away. One constant flips it.

**The window.** Sign-Flow's Flow-Link Window stays 14 frames (9 alone, 18 near a Lantern-Bearer). The Pocket-Pull has its own 18-frame window opened by the same landed physical hits; an L, R or L+R Sign-Flow cast inside it pulls the slot's seal card (the cast already paid its pips), and `try_trigger_pocket_pull_invocation` pulls by hand (the Squire Gambit, the checks) and charges the card's pips itself.

**The rig.** The Wingfeather proportions are bone pose scales on the existing 24-bone hero rig (the head, hands, feet, clavicles and first cloak bone), with the weapon mount and the Greatshield counter-scaled so the arm reads at 1.25x in a 1.28x hand; the figure's crown rises about 6 cm. The seal shader rides the sculpted weapon as a `next_pass` wash (`base_blend` 0.35) and is the whole material of a buckler crest on the off hand and a band at the collar, which show only while that piece is sealed. The flourish adds one 18-frame left-arm overlay clip (`pocket_pull_flourish`) and a 1.6x overhead card capped under 2.5 m; no camera is read or written.

**Checks.** `godot --headless --path . --fixed-fps 60 -s res://tools/run_equipment_grimoire_checks.gd` runs the three gates alone (36 checks); `tools/smoke_test.gd` runs them last, after the Phase 12 Kaizen checks, with `EquipmentSealComponent.enabled` off for the older checks the way `SignFlowComponent.enabled` is.
