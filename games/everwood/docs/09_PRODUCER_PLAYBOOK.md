# 09_PRODUCER_PLAYBOOK.md — Your Visual Studio Dashboard & Accelerator Guide

This is your quick-reference field manual for driving *Everwood* with **Gemini (Principal Game Designer)** and **Claude Code (Principal Lead Engineer)**.

---

## 1. Visual Map of Your 5-Stage Studio Pipeline

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ STAGE 1: IDEATION & MUSK RAZOR (You + Gemini)                               │
│  • Pitch an idea (New Island, Calling tweak, Boss, Card Folio, Profession)  │
│  • Gemini runs Deep Research + Philology Linter + 2-System Harmony Check    │
│  • Output: 1 GDD Markdown Artifact + 1 "ultrathink" Claude Code Prompt      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ STAGE 2 & 3: SCHEMA-FIRST BUILD & BOT VERIFICATION (Claude Code)            │
│  • Run `/effort xhigh` in Claude Code and paste the Master Prompt           │
│  • Claude builds Resources -> Catalogs -> Procedural 3D Scenes & Shaders    │
│  • Claude runs `--check-only`, `smoke_test.gd`, and renders `--screenshot`  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ STAGE 4: 15-MINUTE FAMILY PLAYTEST & MULTIMODAL LOOPBACK (You + Kids)       │
│  • Boot `godot --path games/everwood` and test for 15 minutes on the couch  │
│  • Upload Claude's screenshots + your quick notes back into Gemini          │
│  • Gemini outputs a 5-minute surgical polish prompt for constants/UI        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ STAGE 5: AMORTIZED TECH-DEBT GATE (Claude Code)                             │
│  • Every 3rd similar feature, Claude extracts shared components             │
│  • Clean atomic commits pushed to `main` -> Ready for next feature!         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Quick-Lookup: Which Gemini Accelerator Should I Use Today?

| What You Want to Do | What to Give Gemini | What Gemini Will Do for You |
|---|---|---|
| **Brainstorm a New Area, Island, or System** | 2–3 sentences describing the vibe, real-world places, or gameplay fantasy. | Run **Deep Research** + the **Philological Linter** to invent joyful, map-logical proper nouns and cut any bloat via Gate 1 & Gate 2. |
| **Turn a Sketch or Reference Image into 3D/UI** | Upload a photo of a paper sketch, a castle/forest photo, or a UI mockup. | Run **Multimodal Vision** to convert the image into exact Godot meter dimensions ($4.8\text{ m}$ camera safe), RGB palettes, and `Control` / `MeshInstance3D` trees. |
| **Add New Weapons, Armor, or Scribe Cards** | Describe the combat feel or combo fantasy you want to pull off with the kids. | Run **Combinatorial Math Modeling** against `docs/04_BALANCE.md` so new cards harmonize with the **Four Signs** (`Iron-Root`, `Rime-Gale`, `Warm-Hearth`, `Star-Tide`) without breaking balance. |
| **Fix Something That Felt Off in Playtesting** | Upload a screenshot from the game + 3 bullet points of what confused you or the kids. | Run a **Split-Screen Squint & Feel Audit** and hand you a surgical Claude prompt that fixes the exact collider, UI anchor, or timing constant. |

---

## 3. Copy-Paste Prompt Starters for Any Situation

Whenever you start a new turn with me, copy-paste whichever template fits your goal:

### A. Starting Any New Feature or Content Pillar
```text
Follow `docs/08_EVERGREEN_DEV_BIBLE.md`. I want to design [describe new feature, island, dungeon, card set, or profession].
1. Run Stage 1 (Deep Research, Counter-Arguments, Gate 1 Harmony Check, Gate 2 Musk Razor, and Gate 3 Philological Linter).
2. Present 3 harmonized options with linted proper nouns before we generate the GDD and Claude prompt.
```

### B. Turning an Image, Sketch, or UI Mockup into Code
```text
[Attach Sketch, Photo, or UI Mockup]
Follow `docs/08_EVERGREEN_DEV_BIBLE.md`. Translate this visual reference into a code-first Godot 4.7 specification for `tools/build_levels.gd` / `ActorVisuals` / `PlayerHUD`. Keep all obstacles <= 3.2m for our 4.8m split-screen camera, extract the sunlit cel-shader RGB palette, and generate the GDD + Claude prompt.
```

### C. Post-Build Playtest & Screenshot Triage
```text
[Attach Screenshots + Paste Playtest Notes]
Follow Stage 4 of `docs/08_EVERGREEN_DEV_BIBLE.md`. Run a 4-Player Split-Screen Readability and Game-Feel Audit on these playtest notes and screenshots, then generate a surgical Stage 4/5 polish prompt for Claude Code.
```

---

## 4. The 15-Minute Family Couch Playtest Scorecard

Whenever Claude finishes a build and you boot `godot --path games/everwood`, run through these 5 quick checks:

1. **The Walkability Check (2 mins):** Can you walk from spawn across every bridge, threshold, and trail without snagging on a single collider lip?
2. **The 4-Year-Old Glance Check (3 mins):** Looking only at the bottom-centered **Cross-Grimoire HUD** and the 3D characters, is it immediately obvious which button does what and when a Pip skill ($1\diamond$ / $3\diamond$) is ready to fire?
3. **The "Weapon Channels the Card" Check (3 mins):** Do melee weapons (`Light Sword`, `Heavy Axe`) and ranged weapons (`Bow`, `Staff`) feel distinct, grounded, and punchy when Flow-Canceling into a Scribe Card?
4. **The Co-Op Synergy Check (4 mins):** Did the family naturally trigger at least two **Four-Sign Detonations** (*Shatterpoint*, *Glacial Rupture*, *Dawnburst*, *Astral Chorus*) or use `Shadow Sanctuary` / `Soul Tether` together?
5. **The Mundane Magic Smile Check (3 mins):** Did at least one detail in the world (chiming wind-lanterns, brass **Chimes** scattering, waterwheels turning, or a character's title/cape) make someone smile?