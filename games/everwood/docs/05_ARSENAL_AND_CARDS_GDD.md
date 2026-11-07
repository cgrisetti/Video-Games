# 05_ARSENAL_AND_CARDS_GDD.md — Grounded Arsenal & Scribe Sign-Cards

## 1. Core Design Philosophy & Aesthetic Guardrails
- **World & Combat Tone:** Lived-in, tactile craftsmanship (*Kiki's Delivery Service*, *Log Horizon*) fused with committed physical weight (*Elden Ring*) and geometric Sign-card invocations (*Cardcaptor Sakura*, *FFXIV*, *Kingdom Hearts*). Every card is a Scribe's Sign inked in Maker-Ink on vellum: a piece of the *Making* that holds the First-Quiet back ([15_THE_MYTHOPOETIC_LENS.md](15_THE_MYTHOPOETIC_LENS.md)).
- **Strict Anti-Goals:** NEVER a weightless hack-and-slash (*God of War*, *Dynasty Warriors*, *No More Heroes*). No air-juggling, no 10-hit mash strings, no mid-combat card-deck scrolling, and no random hand draws.
- **The Golden Harmony Rule ("The Weapon Channels the Card"):** Basic `Light` and `Heavy` attacks come from the equipped **weapon**. Special postures (`Forward+Heavy`, `Back+Heavy`, `R Trigger`, `Both Triggers`) invoke the equipped **Scribe Sign-Cards**, channelled through that weapon (a melee cleave for the Falchion and Broad-Axe; a Sign-bolt or Sign-arrow for the Way-Staff and Longbow). `L Trigger` (hold) is always **Guard / Perfect Guard**.

---

## 2. Grounded Equipment System (`EquipmentLoadoutResource`)

### 2.1 The Three Coats (`ArmorWeight`)
A coat sets survivability, footwork, stamina recovery and which Fellowship wears it best:

| Coat (`ArmorWeight`) | Damage Mitigation | Stamina Regen | Dodge Roll Distance | Perfect Guard Window | Worn By |
|---|---|---|---|---|---|
| **Hearth-Linen Coat** (`LIGHT`) | `10%` | `27.5 / s` | `5.2 m` | `200 ms` | Lantern-Bearers and archers |
| **Hedgerow Wool-Mantle** (`MEDIUM`) | `20%` | `22.0 / s` | `4.6 m` | `200 ms` | Wayfarers and all-rounders |
| **Iron-Wood Ring-Coat** (`HEAVY`) | `35%` | `18.0 / s` | `3.8 m` | `260 ms` | The Shield-Sworn |

The trail's first coat, the **Bramble-Spun Jerkin** (medium: `15%`, `24.0 / s`, `4.8 m`, `220 ms`), is what everyone wears at Level 1 ([11_COMBAT_ONBOARDING_AND_FEEL_GDD.md](11_COMBAT_ONBOARDING_AND_FEEL_GDD.md) §5).

### 2.2 The Four Weapons (`WeaponType`)
A weapon defines the hero's `Light` chain, `Heavy` finisher, and whether Sign-Cards land as melee strikes or fly as projectiles:
- **Falchion** (`LIGHT_SWORD`): a crisp 3-cut chain (`0.55s` per cut, `10.0` stamina) and an advancing thrust Heavy (`18.0` damage, `15.0` poise). Delivery: `MELEE`.
- **Broad-Axe** (`HEAVY_AXE`): a deliberate 2-cleave chain (`0.85s` per swing, `16.0` stamina) and the Earth-Splitter Heavy (`28.0` damage, `35.0` poise). Delivery: `MELEE`.
- **Rowan Way-Staff** (`STAFF`): two staff sweeps and a `12.0m` Sign-bolt (`10.0` stamina), and a grounded Resonant Pulse Heavy (`16.0` damage, `+25%` Sanctuary radius). Delivery: `RANGED_BOLT`.
- **Yew Longbow** (`BOW`): a `14.0m` stepping snap-shot (`10.0` stamina) and an `18.0m` planted Piercing Draw Heavy (`24.0` damage, `20.0` poise). Delivery: `RANGED_ARROW`.

Each weapon climbs four tiers on the Trail of the Four Signs (Apprentice Timber, Hedgerow Iron, Bramble-Bridge Steel, Doverslap Relic; 11 GDD §5.1).

---

## 3. Collectible Scribe Sign-Cards (`ScribeCardResource`)

### 3.1 Grimoire Structure: 4 Lead Cards + 4 Under-Card Links
Every hero's Grimoire binds straight to the 4 invocation postures (zero menu scrolling):
1. **Slot 1 (`FORWARD_HEAVY`):** Gap-Closer / Offensive Primer Card
2. **Slot 2 (`BACK_HEAVY`):** Tactical Retreat / Sanctuary / Counter Primer Card
3. **Slot 3 (`TRIGGER_R_SKILL`):** Signature Fellowship Card (`1 Pip` — Taunt, Homing Heal or Gale Rush)
4. **Slot 4 (`TRIGGER_BOTH_ULT`):** Ultimate Finisher Card (`2–3 Pips` — Bulwark Quake, Lifeline Pull or Tempest Flow)

**Level Progression & Under-Card Stacking:**
- At **Level 1**, all 4 Lead slots hold `BASIC` starter cards, so every button works at once.
- Levelling up raises **Grimoire Memory** (room for rarer cards) and opens the **4 Under-Card Link Slots** (one per Lead Card).
- **How Under-Cards work:** an Under-Card slid beneath a Lead Card changes it with one clear verb:
  - *Sign Infusion:* the Lead Card's hits stamp the Under-Card's Sign.
  - *Potency Surge:* `+20%` damage, healing and poise.
  - *Hearth Echo:* heals and shields grant `+8.0/s` stamina regen or bounce to a second ally at `50%`.

Phase 12 pairs each socket's card with a **Place-Card** in a diorama ([14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md](14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md) §4).

### 3.2 The Four Scribe Signs: The Harmonic Combo Matrix
Every Sign-Card is inked in one of **The Four Scribe Signs**. Landing a card with a primer stamps its **Sign seal** on the foe for `8.0s`. When a teammate hits that foe with a Heavy or a detonating card, the seal bursts (`x1.5` potency and `+0.75` pips if the two heroes differ in Fellowship or Sign):

| Sign (`ScribeSignResource.Sign`) | Seal Colour & Mark | Detonation | Base Effect (x1.5 Cross-Harmony) |
|---|---|---|---|
| `SIGN_IRON_ROOT` | Amber/Ochre root-knot | ***Shatterpoint*** | `+45.0` (`67.5`) poise damage and a stagger shove |
| `SIGN_RIME_GALE` | Sea-Azure frost-star | ***Glacial Rupture*** | `+45.0` (`67.5`) burst damage round the foe |
| `SIGN_WARM_HEARTH` | Saffron-Gold sun-crest | ***Dawnburst*** | Mends every party member within `10.0m` for `20.0` (`30.0`) |
| `SIGN_STAR_TIDE` | Twilight-Violet moon-ring | ***Astral Chorus*** | `+25.0` stamina and `+0.5` pips to the party within `10.0m` |

### 3.3 Rarities, Finding Cards, & Vellum Finishes
- **Rarities (`CardRarity`):**
  - `BASIC` and `COMMON`: the starter kit, and sold at the Reed-Light Scribery for **Chimes**.
  - `UNCOMMON`: found in Wayfarer's Chests on the trail.
  - `RARE` and `LEGENDARY`: given by un-boggarted raid bosses.
- **Vellum Finishes (`CardVariant` — presentation only):**
  - **Plain Vellum** (`STANDARD`): a `0.6s` single Sign ring in the Sign's colour under the boots and a vellum card flipping above the shoulder.
  - **Gilded Leaf** (`GILDED_LEAF`): two counter-turning gold Sign rings, a shimmering gold weapon trail and a brighter chime.
  - **Star-Inked Vellum** (`STAR_INKED_VELLUM`): a starfield dome through the wind-up and glowing footprints for `2.5s`.

Save files keep each finish's original save key (listed in [06_WORLD_AND_CALLINGS.md](06_WORLD_AND_CALLINGS.md) §4), so every family binder still loads.

---

## 4. Phase 7 Build Blueprint (engineering)

How the rules above live in the code. The goal: a 50th card or a 5th weapon is a new data entry, never a new `match` branch in `ActorBase` or `CombatDirector`.

### 4.1 Data flow
```
PlayerClassResource (Fellowship, base stats, Soul Tether, starter kit)    ClassLoadouts
EquipmentLoadoutResource "kit" (coat id, weapon id, 4 lead + 4 under card ids, finishes)
        │  ids only: this is what the roster, saves and RPCs carry
        ▼
LoadoutComposer.compose(class, kit) ── looks every id up in ArsenalCatalog
        │  coat   → stats (mitigation, stamina regen, roll distance, Perfect Guard window)
        │  weapon → Light chain + Heavy (Heavy always detonates)
        │  lead card → the posture's CombatActionResource, channelled through the weapon
        │  under-card → one verb changes that action (infusion / surge / echo)
        ▼
ClassLoadoutResource (compiled: openers, combo actions, dodge, labels)  ← what ActorBase runs
```
Every peer compiles the same kit into the same actions with the same ids, so the network only ever names things by id.

### 4.2 Registry
- `ArsenalCatalog` (autoload `Arsenal`, `src/actors/arsenal_catalog.gd`) owns every `ScribeSignResource`, `EquipmentItemResource` and `ScribeCardResource`, indexed by `StringName` id. Each registers through one `register_*` call, so loading `.tres` definitions later is a loop over a folder.
- Cards are data: a template `CombatActionResource` plus slot, Sign, rarity, delivery and whether it primes. Weapons are data: Light chain, Heavy, delivery, card range, projectile and prop parts.
- Sign detonations are data (`ScribeSignResource`: bonus poise, bonus damage and burst radius, party heal, party stamina and pips). `CombatDirector` applies whatever is non-zero, so there is no per-Sign code.

### 4.3 The Weapon Channels the Card
- A lead card marked `THROUGH_WEAPON` keeps its numbers but takes the weapon's delivery: `MELEE` weapons swing it with a ribbon trail; `RANGED_BOLT` and `RANGED_ARROW` weapons fire it as a Sign-wreathed projectile out to the weapon's card range. Forward lunges are dropped for ranged delivery (you plant and cast); backward steps stay.
- Cards marked `AT_CASTER` (sanctuaries, taunt, heals, pulls, the ultimate bursts) happen at the caster whatever the weapon.
- `L` (hold) is Guard for every Fellowship, and every hero can Perfect Guard inside their coat's window.

### 4.4 Network and saves
- The roster carries each seat's kit as ids. A strike between peers carries the action id; the target's owner looks the numbers up in its own compiled copy of the attacker's loadout (so a peer can't claim more damage than the action does). Telegraph strikes and Perfect Guard counters, which have no action, still carry numbers.
- Projectiles: the attacker's peer flies the real one and reports hits; other peers fly a look-alike copy that can't hit anything. Card invocations and projectiles cross the network as the actor's path plus an action id.
- Detonations: the host (which owns every foe) resolves a seal and broadcasts it, so every peer shows and signals it.
- Grimoire changes from the Scribe Desk go to the host, which checks them against the rules (owned copy, open link, memory) before the roster carries the new kit; a refusal comes back with the reason.
- `PartyProgress` saves the card collection (a copy key is the card id plus its finish's save key), each Fellowship's last kit, and the victory count that sets the Grimoire level. `--save=PATH` points a run at another file, so tests and demos never touch the family's save.

### 4.5 Effects
- Projectiles and Scribe invocation effects come from an `FxPool` under the level's `Effects` node: finished ones go back to the pool, and the whole pool is freed with the level, so nothing outlives an instance.
- Finish choreography (Plain Vellum, Gilded Leaf, Star-Inked Vellum) is presentation data in `ScribeInvocationFX`; the mechanics never read the finish.

### 4.6 Deliberate differences from §1–3 (for the Creative Director)
- **Homing Heal costs no pip.** §3.1 lists the Signature slot at 1 pip, but the Lantern-Bearer's Homing Heal is their everyday tool and heals earn only ~0.18 pip each, so a pip cost would stop healing. It costs 12 stamina, as in Phase 5; Taunt and Gale Rush cost 1 pip.
- **R-hold is retired.** The four card slots replace it; Green Sanctuary moves to the Lantern-Bearer's Back+Heavy slot.
- **Potency Surge** multiplies damage, healing and poise by 1.20 (the Phase 7 brief), rather than adding a flat +20 poise.
- **Hearth Echo on an attack card** returns 8 stamina to the caster on a hit (§3.1 defines it only for heals and shields).
- **The Way-Staff's +25% Soul Tether radius:** tethers have no range today, so the bonus applies to sanctuary radius only.
- **Perfect Guard threat** scales with the defender's threat modifier, so a Wayfarer who Perfect Guards doesn't pull a foe off the tank.
