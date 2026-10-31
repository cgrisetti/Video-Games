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

## 3. The Kinetic Trinity
- **The Kinetic Tank:** Uses `TRIGGER_L_SKILL` for Active Guard. A **Perfect Guard** executed within 200ms of an incoming strike costs 0 stamina, deals 50 poise damage to the attacker, and generates massive threat. `BACK_HEAVY` spawns a physical `Shadow Sanctuary` shield cone protecting teammates behind them.
- **The Kinetic Healer:** Uses `D-Pad Up/Right/Down/Left` to bind 4 party members to **Soul Tethers**. `TRIGGER_R_SKILL` fires homing heals to the tethered target without breaking camera lock on the boss. Holding the trigger drops an AoE `Green Sanctuary` ring. `TRIGGER_BOTH_ULT` performs a **Lifeline Pull**, yanking a child out of danger.
- **The Kinetic DPS:** Executes directional BDO combos (`Forward+Heavy`, `Back+Heavy`) and applies **Synergy Primers** (`STAGGER`, `FROST`, `RADIANT`) that teammates detonate for massive cross-class bonus effects.

---

## 4. Family Accessibility Matrix (Assist Modes)
- **Master Mode (Full Manual):** Full BDO directional chords, manual i-frame dodge timing, and manual D-Pad targeting (+15% flow speed reward).
- **Adventurer Mode (Assisted):** 550ms input buffer, automatic soft-lock camera tracking, and basic auto-combo chaining.
- **Squire Gambit Mode (Youngest Children):** 1-button smart combo cycling based on dynamic distance/party health priorities, plus an **Auto-Evade Safety Net** that automatically dodges away from hostile red telegraphs at 85% fill ratio if stamina permits.