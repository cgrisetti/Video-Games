# 05_ARSENAL_AND_CARDS_GDD.md — Grounded Arsenal & Scribe Rune-Cards

## 1. Core Design Philosophy & Aesthetic Guardrails
- **World & Combat Tone:** Lived-in, tactile craftsmanship (*Kiki's Delivery Service*, *Log Horizon*) fused with committed physical weight (*Elden Ring*) and geometric rune-card invocations (*Cardcaptor Sakura*, *FFXIV*, *Kingdom Hearts*).
- **Strict Anti-Goals:** NEVER a weightless hack-and-slash (*God of War*, *Dynasty Warriors*, *No More Heroes*). No air-juggling, no 10-hit mash strings, no mid-combat card-deck scrolling, and no random hand draws.
- **The Golden Harmony Rule ("The Weapon Channels the Card"):** Basic `Light` and `Heavy` attacks are determined by your equipped **Weapon Archetype**. Special postures (`Forward+Heavy`, `Back+Heavy`, `R Trigger`, `Both Triggers`) invoke your equipped **Scribe Rune-Cards**, channeled physically through your weapon (melee cleave for `Sword`/`Axe`; rune-projected arrow/bolt for `Bow`/`Staff`). `L Trigger` (Hold) is permanently protected as **Guard / Perfect Guard**.

---

## 2. Grounded Equipment System (`EquipmentLoadoutResource`)

### 2.1 Armor Weight Classes (`ArmorWeight` Enum)
Armor governs survivability, footwork weight, stamina recovery, and Grimoire affinity:
| Armor Class | Damage Mitigation | Stamina Regen | Dodge Roll Distance | Perfect Guard Window | Role Affinity |
|---|---|---|---|---|---|
| `LIGHT` (Hearth-Linen) | `10%` | `27.5 / s` | `5.2 m` | `200 ms` | Healer / Ranged / Mystic |
| `MEDIUM` (Ranger Leather) | `20%` | `22.0 / s` | `4.6 m` | `200 ms` | Agile DPS / Hybrid |
| `HEAVY` (Ironwood Plate) | `35%` | `18.0 / s` | `3.8 m` | `260 ms` | Shield or Vanguard Tank |

### 2.2 The Four Weapon Archetypes (`WeaponType` Enum)
Equipping a weapon defines the actor's `Light` chain, `Heavy` finisher, and whether Attack Cards are delivered as melee strikes or ranged projectiles:
- `LIGHT_SWORD` (Sword & Buckler): Crisp 3-hit slash chain (`0.55s` per swing, `10.0` stamina), advancing thrust heavy (`18.0` damage, `15.0` poise). Delivery: `MELEE`.
- `HEAVY_AXE` (Two-Handed Greataxe): Deliberate 2-hit wide cleave (`0.85s` per swing, `16.0` stamina), earth-splitter heavy (`28.0` damage, `35.0` poise). Delivery: `MELEE`.
- `STAFF` (Hearthwood Scribe Staff): 2-hit staff sweep + `12.0m` arcane bolt (`10.0` stamina), grounded resonant pulse heavy (`16.0` damage, `+25%` Soul Tether & Sanctuary radius). Delivery: `RANGED_BOLT`.
- `BOW` (Wind-Ash Hunter Bow): `14.0m` stepping snap-shot (`10.0` stamina), `18.0m` planted piercing draw heavy (`24.0` damage, `20.0` poise). Delivery: `RANGED_ARROW`.

---

## 3. Collectible Scribe Rune-Card System (`ScribeCardResource`)

### 3.1 Grimoire Structure: 4 Lead Cards + 4 Under-Card Links
Every player's Grimoire binds directly to the 4 combat invocation postures (zero menu scrolling):
1. **Slot 1 (`FORWARD_HEAVY`):** Gap-Closer / Offensive Primer Card
2. **Slot 2 (`BACK_HEAVY`):** Tactical Retreat / Sanctuary / Counter Primer Card
3. **Slot 3 (`TRIGGER_R_SKILL`):** Signature Role Card (`1 Pip` — Taunt, Homing Tether Heal, or Gale Rush)
4. **Slot 4 (`TRIGGER_BOTH_ULT`):** Ultimate Finisher Card (`2–3 Pips` — Bulwark Quake, Lifeline Pull, or Tempest Flow)

**Level Progression & Under-Card Stacking:**
- At **Level 1**, all 4 Lead Card slots are active and populated with `BASIC` starter cards so every controller button works immediately.
- Leveling up (`Lv 1 -> Lv 5`) increases **Grimoire Memory Capacity** (allowing high-rarity cards) and unlocks the **4 Under-Card Link Slots** (1 slot per Lead Card).
- **How Under-Cards Work:** Sliding an Under-Card beneath a Lead Card modifies the Lead Card with a single clear verb:
  - *Aspect Infusion:* Imbues the Lead Card with the Under-Card's `CardAspect` primer.
  - *Potency / Poise Surge:* Adds `+20%` damage/healing or `+20.0` poise break.
  - *Hearth Echo:* Causes heals/shields to grant `+8.0/s` Stamina regen or bounce to a second nearby ally at `50%` value.

### 3.2 The Unified Four-Aspect Harmonic Combo Matrix
Every Scribe Card belongs to one of four **Magical Aspects**. Landing a Card with a Primer tag stamps that **Aspect Seal** onto the enemy for `8.0s`. When a teammate hits that enemy with a Heavy attack or Detonator Card, it triggers the Aspect's detonation (`x1.5` potency and `+0.75` Pips if the two players used different Roles or different Aspects):

| Aspect | Seal Color & Icon | Detonation Name | Base Effect (x1.5 Cross-Harmony) |
|---|---|---|---|
| `KINETIC` | Amber Gear | **Shatterpoint** | `+45.0` (`67.5`) Poise damage & stagger impulse |
| `ELEMENTAL` | Azure Frost-Star | **Elemental Rupture** | `+45.0` (`67.5`) Burst AoE damage |
| `DIVINE` | Gold Sun-Crest | **Dawnburst** | Heals all party members within `10.0m` for `20.0` (`30.0`) HP |
| `CELESTIAL` | Violet Moon-Ring | **Astral Chorus** | Restores `+25.0` Stamina and `+0.5` Pips to all party members within `10.0m` |

### 3.3 Card Rarities, Acquisition, & Visual Variants
- **Rarities (`CardRarity`):**
  - `BASIC` & `COMMON`: Starter kit & purchasable at Hub Town Scribe Shop for Dojo Shards.
  - `UNCOMMON`: Found in dungeon exploration chests or scribed from Common cards + Shards.
  - `RARE` & `LEGENDARY`: Dropped by Raid Bosses or crafted from Boss Essences.
- **Visual Variants (`CardVariant` — Drives 3D Shader Choreography):**
  - `STANDARD`: `0.6s` single-ring Aspect-colored geometric rune decal under boots + floating vellum card flip above shoulder.
  - `SHINY_FOIL` (Gilded Variant): Double counter-rotating gold rune rings, shimmering gold weapon trail, and harmonic chime pitch boost.
  - `ASTRAL_PRISM` (Prismatic Variant): Expanding starfield dome during Phase A wind-up and luminous footprints for `2.5s`.
---

## 4. Phase 7 Build Blueprint (engineering)

How the rules above live in the code. The goal: a 50th card or a 5th weapon is a new data entry, never a new `match` branch in `ActorBase` or `CombatDirector`.

### 4.1 Data flow
```
PlayerClassResource (role, base stats, Soul Tether, starter kit)     ClassLoadouts
EquipmentLoadoutResource "kit" (armor id, weapon id, 4 lead + 4 under card ids, lead variants)
        │  ids only: this is what the roster, saves and RPCs carry
        ▼
LoadoutComposer.compose(class, kit) ── looks every id up in ArsenalCatalog
        │  armor  → stats (mitigation, stamina regen, roll distance, Perfect Guard window)
        │  weapon → Light chain + Heavy (Heavy always detonates)
        │  lead card → the posture's CombatActionResource, channelled through the weapon
        │  under-card → one verb mutates that action (infusion / surge / echo)
        ▼
ClassLoadoutResource (compiled: openers, combo actions, dodge, labels)  ← what ActorBase runs
```
Every peer compiles the same kit into the same actions with the same ids, so the network only ever names things by id.

### 4.2 Registry
- `ArsenalCatalog` (autoload `Arsenal`, `src/actors/arsenal_catalog.gd`) owns every `AspectSealResource`, `EquipmentItemResource` and `ScribeCardResource`, indexed by `StringName` id. Cards and items register through one `register_*` call each, so loading `.tres` definitions later is a loop over a folder.
- Cards are data: a template `CombatActionResource` plus slot, aspect, rarity, delivery and whether it primes. Weapons are data: Light chain, Heavy, delivery vector, card range, projectile and prop parts.
- Aspect detonations are data (`AspectSealResource`: bonus poise, bonus damage and burst radius, party heal, party stamina and pips). `CombatDirector` applies whatever is non-zero, so there is no per-aspect code.

### 4.3 The Weapon Channels the Card
- A lead card marked `THROUGH_WEAPON` keeps its numbers but takes the weapon's delivery: `MELEE` weapons swing it with a ribbon trail; `RANGED_BOLT` and `RANGED_ARROW` weapons fire it as a rune-wreathed projectile out to the weapon's card range. Forward lunges are dropped for ranged delivery (you plant and cast); backward steps stay.
- Cards marked `AT_CASTER` (sanctuaries, taunt, heals, pulls, the ultimate bursts) happen at the caster whatever the weapon.
- `L` (hold) is Guard for every class, and every class can Perfect Guard inside its armor's window.

### 4.4 Network and saves
- The roster carries each seat's kit as ids. A strike between peers carries the action id; the target's owner looks the numbers up in its own compiled copy of the attacker's loadout (so a peer can't claim more damage than the action does). Telegraph strikes and Perfect Guard counters, which have no action, still carry numbers.
- Projectiles: the attacker's peer flies the real one and reports hits; other peers fly a look-alike copy that can't hit anything. Card invocations and projectiles cross the network as the actor's path plus an action id.
- `PartyProgress` saves the card collection (copy keys like `rising_drive:shiny_foil`), each class's last kit, and the victory count that sets the Grimoire level.

### 4.5 Effects
- Projectiles and Scribe invocation effects come from an `FxPool` that lives under the level's `Effects` node: finished ones go back to the pool, and the whole pool is freed with the level, so nothing outlives an instance.
- Variant choreography (`STANDARD`, `SHINY_FOIL`, `ASTRAL_PRISM`) is presentation data in `ScribeInvocationFX`; the mechanics never read the variant.

### 4.6 Deliberate differences from §1–3 (for the Creative Director)
- **Homing Heal costs no pip.** §3.1 lists the Signature slot at 1 pip, but the healer's Homing Heal is their everyday tool and heals earn only ~0.18 pip each, so a pip cost would stop healing. It costs 12 stamina, as in Phase 5; Taunt and Gale Rush cost 1 pip.
- **R-hold is retired.** The four card slots replace it; Green Sanctuary moves to the healer's Back+Heavy slot.
- **Under-Card Potency Surge** multiplies damage, healing and poise by 1.20 (the Phase 7 brief), rather than adding a flat +20 poise.
- **Hearth Echo on an attack card** returns 8 stamina to the caster on a hit (§3.1 defines it only for heals and shields).
- **Staff's +25% Soul Tether radius:** tethers have no range today, so the bonus applies to sanctuary radius only.
- **Perfect Guard threat** scales with the defender's threat modifier, so a DPS who Perfect Guards doesn't rip aggro from the tank.
