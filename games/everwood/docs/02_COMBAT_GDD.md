# 02_COMBAT_GDD.md — Combat Systems & Mechanics Design Document

## 1. Unified Resource Economy
- **Stamina (0 to 100):** Governs movement, rolling, blocking, and heavy attacks. Regenerates at 22/sec out of combat/idle.
- **Resonance Pips (0 to 3):** Landed combos fill resonance pips, which are spent to cast signature role abilities, group heals, or taunts.
- **Poise (0 to 100):** Hidden enemy gauge. Heavy attacks and perfect blocks deplete boss poise, triggering a 5.0-second knockdown state.

---

## 2. The Four-Phase Attack Pipeline
Every action (`CombatActionResource`) flows through four strict frame-data phases:
1. **Phase A (Wind-Up / Startup):** Stamina deducted instantly. Character rotates up to $45^\circ$ toward camera/target. **Cannot dodge-cancel.**
2. **Phase B (Active Hitbox & Hit-Stop):** Weapon collision enabled. On overlap, freezes attacker and target for **60ms** (hit-stop impact) and triggers validation RPC.
3. **Phase C (KOTOR Input Buffer):** Captures next button press up to 400ms–550ms before animation finishes, displaying a visual queue icon.
4. **Phase D (BDO Flow-Cancel Window):** Recovery tail. If a valid directional follow-up was buffered, recovery is skipped entirely, cross-fading into the next attack with a **+15% speed bonus**.

---

## 3. The Fellowship Trinity & The Four Scribe Signs
Every hero swears to one of three Fellowships (their Raid Trinity seat) and carries cards of the **Four Scribe Signs** ([06_WORLD_AND_CALLINGS.md](06_WORLD_AND_CALLINGS.md) §2–3):
- **The Shield-Sworn (Tank — `Bridge-Warden`, `Weald-Captain`, `Hearth-Guard`):** Holds `L` for Active Guard. A **Perfect Guard** within the armor's window (200 ms, 260 ms in an Iron-Wood Ring-Coat) costs 0 stamina, deals 50 poise damage to the attacker and generates heavy threat. `BACK_HEAVY` raises a physical `Shadow Sanctuary` shield cone that shelters teammates behind them.
- **The Lantern-Bearers (Mender — `Bell-Keeper`, `Wind-Mender`, `Lantern-Scribe`):** Bind four party members to **Soul Tethers** on `D-Pad Up/Right/Down/Left`. `TRIGGER_R_SKILL` sends a homing mend down the tether without breaking camera lock on the boss; `BACK_HEAVY` lays a `Green Sanctuary` ring; `TRIGGER_BOTH_ULT` is the **Lifeline Pull** that yanks a child out of danger. Standing within `5.5m` of one is **The Lantern's Promise** (§5).
- **The Wayfarers (DPS — `Iron-Woodsman`, `Hedge-Runner`, `Sign-Seeker`):** Chain directional BDO combos (`Forward+Heavy`, `Back+Heavy`) and stamp **Sign seals** that a teammate's Heavy or detonating card bursts for a cross-Fellowship bonus (`x1.5` and `+0.75` pips when the two players differ in Fellowship or Sign).

**The Four Scribe Signs** replace the old three primers. Each stamps a seal for `8.0s`; its detonation is:

| Sign (`ScribeSignResource.Sign`) | Colour | Detonation | Effect (x1.5 Cross-Harmony) |
|---|---|---|---|
| `SIGN_IRON_ROOT` | Amber/Ochre | ***Shatterpoint*** | `+45.0` (`67.5`) poise damage and a stagger shove |
| `SIGN_RIME_GALE` | Sea-Azure | ***Glacial Rupture*** | `+45.0` (`67.5`) burst damage round the target |
| `SIGN_WARM_HEARTH` | Saffron-Gold | ***Dawnburst*** | Mends every party member within `10.0m` for `20.0` (`30.0`) |
| `SIGN_STAR_TIDE` | Twilight-Violet | ***Astral Chorus*** | `+25.0` stamina and `+0.5` pips to the party within `10.0m` |

---

## 4. Family Accessibility Matrix (Assist Modes)
- **Master Mode (Full Manual):** Full BDO directional chords, manual i-frame dodge timing, and manual D-Pad targeting (+15% flow speed reward).
- **Adventurer Mode (Assisted):** 550ms input buffer, automatic soft-lock camera tracking, and basic auto-combo chaining.
- **Squire Gambit Mode (Youngest Children):** 1-button smart combo cycling based on dynamic distance/party health priorities, plus an **Auto-Evade Safety Net** that automatically dodges away from hostile red telegraphs at 85% fill ratio if stamina permits.

---

## 5. Stewardship Combat Loops: The Hearth-Rite, The Lantern's Promise & Un-Boggarting
Every foe is a spirit of **The First-Quiet** ([15_THE_MYTHOPOETIC_LENS.md](15_THE_MYTHOPOETIC_LENS.md)), so a fight is a piece of homestead work: get ready by the fire, stay together in the lantern-light, answer the spirit's challenge, and set it right rather than slay it.
- **The Hearth-Rite Tuck (out of combat, `120 frames`):** with no awake foe within `18m`, hold `R` or `L+R` for `120 frames` (`2.0s`; `80` on a Star-Inked Vellum leaf). It costs `0` pips, tops the hero up to `1.0` pip, holds the weapon at `1.35x` in the Place-Card's tint, and empowers the next fight's opening strike with the Sign, its seal and the Place-Card's poise. The Cross-Grimoire HUD wears a Saffron-Gold ember border while the Tuck is held, and the zone's nursery rhyme unfurls on the Chime-Post ribbon.
- **Flow-Link scaling (in combat):** landing a Light, Heavy or directional Heavy opens the Flow-Link Window, in which `R`, `L` or `L+R` casts with no wind-up:

| Window | Frames | When |
|---|---|---|
| **Dread-Chill** | `9 frames` (`0.150s`) | A hero fighting alone, out on their own (a party of one; the Scrays' sea-fret strays a hero `>8.0m` from the party) |
| **Baseline** | `14 frames` (`0.233s`) | Everyone else |
| **The Lantern's Promise** | `18 frames` (`0.300s`) | Within `5.5m` of a Lantern-Bearer (`Bell-Keeper`, `Wind-Mender`, `Lantern-Scribe`) |

- **The Bravery Counter (`45 frames`):** a waking Guardian (the Cairnsman, a Cairn-Drake, a Furrow Iron-Man) bellows a `45-frame` **Challenge-Roar** and opens its **Glimmer-Spot**. A counter Sign landed there is a Bravery Counter: (`60.0` Hearth-Rite *Shatterpoint* + `45.0` Wayfarer counter) x `M(L)` = `105.0` posture at Lv 1 (see [14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md](14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md) §3), plus the Sign's detonation.
- **Squire Gambit Assist & the Truce-Sign:** a `STATE_CURIOUS` Weald-Wight (a hob nobody has wronged) opens a `180-frame` parley window to any hero within `6.0m`. The one Gambit button (`Light`) waves the Truce-Sign: the hob dances, the party's pouch gets `+25` Chimes and the hero `+1.0` pip. Striking a curious hob instead breaks the etiquette and it turns boggart. A Squire's press up to `90 frames` before a boss's Glimmer-Spot opens is buffered and fires their counter on its first frame.
- **Un-Boggarting:** a beaten spirit never leaves a corpse. It is released (`STATE_UNBOGGART_RELEASE`: a white sea-swallow, a hedge-wren or a warm path-light), lulled into a mossy cairn (`STATE_LULLED_CAIRN`), or—a Furrow Iron-Man whose chest `Maker-Seal` was turned right-way up—bowed into a steward for `600s` (`STATE_STEWARD_HELPER`).
