# 16_ADAPTIVE_AUDIO_ARCHITECTURE.md — Chamber Pastoral Whimsicalism & Living Storybook Atelier Audio Engine

> **SYSTEM DIRECTIVE FOR GEMINI & CLAUDE CODE:** This document is the authoritative musicological, acoustic-synthesis, and runtime audio specification for *Everwood*. It governs how zone scores, multi-focus split-screen ambience, Hush-Crack skirmishes, boss encounters, the Four Scribe Signs, the $3 \times 3$ Calling Trinity, and all $36$ interactive cues in `AudioCues` are composed, rendered, and mixed in Godot 4.7.
>
> **THE LIVING STORYBOOK ATELIER MANDATE (ZERO SPEAK-&-SPELL SYNTHS):** Raw mathematical oscillator synthesis (`Wave.SQUARE`, `Wave.SAW`, and un-articulated `Wave.SINE` arpeggios at $22050\text{ Hz}$) is **strictly banned** across both `ProceduralChamberSynth` and `AudioCues`. Every musical stem and gameplay cue must be rendered at $44100\text{ Hz}$ through either our **Build-Time Symphonic Chamber SoundFont Pipeline (`tools/build_audio_stems.py` + `FluidSynth` + `.sf2` + `ffmpeg`)** or our **Acoustic Waveguide, Double-Reed Formant, & Musette Physical Modeling Engine** with warm wooden chamber reverb.

---

## 1. Codebase Post-Mortem: Why the Current Audio Sounds Like a 1970s Speak & Spell

A forensic audit of `src/core/audio_cues.gd`, `src/resources/zone_music_profile_resource.gd`, and `src/core/procedural_chamber_synth.gd` reveals four exact engineering causes behind the synthetic, somber "1970s Speak & Spell" sound:

1. **Raw `Wave.SQUARE` and `Wave.SAW` Oscillators at $22050\text{ Hz}$ in `AudioCues`:**
   * `AudioCues` (`audio_cues.gd`) currently runs at `MIX_RATE = 22050` with only four primitive waveforms (`enum Wave { SINE, SQUARE, SAW, NOISE }`).
   * Iconic moments like `seal_iron_root`, `victory`, `camp_cleared`, `equip`, and `chime` are rendered as raw `Wave.SQUARE` (`tanh(3.0 * sin(TAU * phase))`) step-arpeggios, while `telegraph`, `soak_fail`, `refuse`, `gate`, and `beam` use un-anti-aliased `Wave.SAW` (`2.0 * fposmod(phase, 1.0) - 1.0`). At $22050\text{ Hz}$, raw saw and square waves fold harmonics back across the Nyquist limit ($11025\text{ Hz}$), producing the exact nasal, electronic buzz of a 1978 Texas Instruments *Speak & Spell*.
2. **Missing Multi-Voice Chamber Accompaniment & Counterpoint in `ProceduralChamberSynth`:**
   * While `ZoneMusicProfileResource` defines `lead_scale`, `discord_scale`, `progression`, and `lead_timbre` (`&"WHISTLE"`, `&"ACCORDION"`, `&"VIOLIN"`, `&"REED"`), the code-built stem generator plays mechanical, block-chord patterns on `progression = [0, 1, 6, 0]` without **Joe Hisaishi's buoyant "oom-pah-pah" waltz engine**, without **staccato Bassoon counter-melodies**, without **Celtic Harp Lydian glissandi**, and without **Solo Violin/Oboe soaring octave lifts**.
3. **Unpopulated `.tres` / `.ogg` SoundFont Stems on Disk:**
   * `ZoneMusicProfileResource.synchronized_stream_path` expects `res://assets/audio/music/<profile_id>.tres`. Because no build script had baked those `.ogg` stems from a real Orchestral/Chamber SoundFont (`.sf2`), the engine permanently falls back to low-rate procedural oscillators.
4. **Dry Mono Buffers Without Wooden Atelier Acoustics:**
   * Both `AudioCues` (`stream.stereo = false`) and the procedural stem builder output bone-dry mono waveforms with zero early reflections, zero stereo instrument staging, and zero wooden body resonance.

---

## 2. Aesthetic & Musicological Pillars: Chamber Pastoral Whimsicalism

To transform *Everwood* into a **Living Storybook Atelier**, every zone score and interactive cue synthesizes five touchstone ensembles into a unified European/Archipelago chamber-folk palette:

| Aesthetic Axis | Primary Touchstones | Modal & Rhythmic Mechanics | Conversational Chamber Palette |
|---|---|---|---|
| **1. The Hisaishi Flight & Bustle Axis** | Joe Hisaishi (*Town With An Ocean View*, *Mother's Broom*, *Totoro*) | **Lydian Mode** ($\sharp\hat{4}$ skyward lift); buoyant $3/4$ waltz & $6/8$ pastoral lilt; crisp Beat-1 pizzicato bass + Beat-2/3 off-beat strums; playful bassoon leaps. | **Acoustic Bassoon**, **French Musette Accordion**, **Pizzicato Strings**, **Solo Legato Violin**, **Celtic Harp** glissandi. |
| **2. The Shore Hearth & Commons Axis** | Howard Shore (*Concerning Hobbits*), Cécile Corbel | **Ionian / Pentatonic** with Lydian inflections; rolling $6/8$ fingerpicked sixths; $32\text{nd}$-note whistle grace-note flicks; omitting natural $\hat{4}$ in opening phrases. | **Wooden Low Whistle / Recorder**, **Nylon & Steel Acoustic Guitar**, **Celtic Harp**, **Warm Cello**, **Staccato Bassoon**. |
| **3. The Call & Arcadian Expedition Axis** | Evan Call (*Frieren: Beyond Journey's End*), The Arcadian Wild | **Dorian / Lydian Mixture**; deliberate $1\text{–}2\text{ beat}$ breathing rests between phrases; interlocking 3-voice plucked string counterpoint. | **Mandolin**, **Acoustic Guitar**, **Oboe**, **English Horn**, **Hammered Dulcimer (Cimbalom)**, **Solo Viola/Violin**. |
| **4. The Storybook Holloway Wonder Axis** | The Blasting Company (*Over the Garden Wall — Into the Unknown*), J.S. Bach *Two-Part Inventions* | **Harmonic Minor** ($\sharp\hat{7}$) & **Diminished $7\text{th}$ Counterpoint**; playful, tiptoeing rubato dialogue—mysterious and whimsical, never sluggish or electronic. | **Reedy Bassoon & Plaintive Oboe** trading contrapuntal lines, **Accordion** bellows fifths, **Pizzicato Cello** tiptoes. |
| **5. The Kinetic Folk Skirmish Axis** | Evan Call (*Zoltraak*), Carpathian & Celtic Chamber Folk | **Dorian / Harmonic Minor** fast $6/8$ or $3/4$ gallop; syncopated double-stops; **Lydian Harp/Carillon Poise-Stagger Window** every $35\text{–}45\text{ s}$. | **Hammered Dulcimer**, **Bodhrán & Frame Drum**, rapid **Fiddle & Mandolin** ostinati, **Bassoon & Cello** stabs. |

---

## 3. Dual-Tier Symphonic Chamber Engineering Architecture

To guarantee studio-grade acoustic warmth while obeying **Gate 5 (Code-First & Headless CI Safe)** of `08_EVERGREEN_DEV_BIBLE.md`, *Everwood* implements a **Dual-Tier Symphonic Chamber Pipeline**:

### 3.1 Tier 1: Build-Time SoundFont & Physical-Model Stem Baker (`tools/build_audio_stems.py`)
* A deterministic Python build tool (`tools/build_audio_stems.py`) that generates the 4 phase-locked `.ogg` stems (`stem_0_folk_base.ogg`, `stem_1_pastoral_lead.ogg`, `stem_2_holloway_discord.ogg`, `stem_3_skirmish_drive.ogg`) and the Godot `AudioStreamSynchronized` `.tres` wrapper (`res://assets/audio/music/<profile_id>.tres`) for every zone in `AudioCatalog`.
* **Rendering Engine:**
  1. If `fluidsynth` and a General MIDI / Symphonic `.sf2` SoundFont (`FluidR3_GM.sf2`, `GeneralUser_GS.sf2`, or `MuseScore_General.sf2`) are present, it renders humanized multi-channel MIDI scores (with CC11 Expression swells, CC1 Vibrato, CC91 Warm Hall Reverb, and human micro-timing) through `fluidsynth` and normalizes them via `ffmpeg` two-pass `loudnorm` ($I = -18\text{ LUFS}$, $TP = -1.5\text{ dBTP}$).
  2. If no external `.sf2` is installed on the developer's machine, `tools/build_audio_stems.py` synthesizes the stems directly in $44.1\text{ kHz}$ 32-bit float using NumPy/Python **Karplus-Strong Waveguides, 3-Formant Conical Bore Woodwind Models (Bassoon/Oboe), Triple-Reed Musette Accordion Models, and Helmholtz Bowed Strings** convolved with a warm Wooden Chamber Impulse Response, encoding seamless looping `.ogg` files via `ffmpeg`.

### 3.2 Tier 2: Runtime Symphonic Chamber Synthesizer (`ProceduralChamberSynth` v3)
When `ProceduralChamberSynth` (`src/core/procedural_chamber_synth.gd`) builds streams at runtime, it operates at **`MIX_RATE = 44100` in True Stereo (`stereo = true`)** with an integrated **Early-Reflection Wooden Atelier Diffuser** and seven distinct physical-modeling chamber instruments:

1. **`TIMBRE_BASSOON` (Double-Reed Conical Bore Model):**
   * Band-limited reed excitation ($12$ harmonics weighted by $k^{-1.1}$ with asymmetric reed-clipping) shaped by a $35\text{ ms}$ breath-chiff attack, $5.2\text{ Hz}$ delayed vibrato, and a **3-Band Biquad Formant Filter** tuned to acoustic bassoon vocal tracts:
     $$F_1 = 440\text{ Hz}\ (Q = 4.5), \quad F_2 = 1150\text{ Hz}\ (Q = 5.0), \quad F_3 = 2500\text{ Hz}\ (Q = 4.0)$$
   * Articulates with a bouncy $55\%$ staccato gate on waltz counter-melodies and walking basslines so it chuckles and dances like Joe Hisaishi's bassoon in *Kiki's Delivery Service*.
2. **`TIMBRE_OBOE` & `TIMBRE_ENGLISH_HORN` (Singing Pastoral Double-Reed):**
   * Formant peaks at $F_1 = 750\text{ Hz}$, $F_2 = 1400\text{ Hz}$, $F_3 = 2900\text{ Hz}$ with an expressive $65\text{ ms}$ legato swell and warm $5.6\text{ Hz}$ vibrato.
3. **`TIMBRE_ACCORDION` (French Musette *Voix Céleste* Triple-Reed):**
   * Three detuned free-reed oscillators at $f_0$, $f_0 \cdot 2^{+13/1200}$, and $f_0 \cdot 2^{-11/1200}$ with reed harmonic weights $[1.0, 0.68, 0.48, 0.28, 0.16, 0.09]$, soft bellows attack ($60\text{ ms}$), and warm $2900\text{ Hz}$ wooden-casing low-pass filtering.
4. **`TIMBRE_VIOLIN` & `TIMBRE_CELLO` (Helmholtz Bowed & Wooden-Body Pizzicato):**
   * *Legato Bowed:* Dual-saw phase-modulated bow slip routed through spruce soundboard body resonances ($285\text{ Hz}$, $520\text{ Hz}$, $2350\text{ Hz}$) with a singing $85\text{ ms}$ bow swell and $5.8\text{ Hz}$ vibrato.
   * *Pizzicato:* Karplus-Strong plucked gut waveguide ($g = 0.968$, damping $d = 0.52$) + resonant $175\text{ Hz}$ wooden body thump for the Hisaishi "oom-pah-pah" waltz foundation.
5. **`TIMBRE_HARP`, `TIMBRE_GUITAR`, `TIMBRE_MANDOLIN`, & `TIMBRE_DULCIMER` (Karplus-Strong Plucked String Waveguides):**
   * Circular delay line of length $L = f_s / f_0$ excited by a warm pink-noise plectrum burst and filtered through a one-pole bridge-damping loop filter:
     $$y[n] = g \cdot \left((1 - d) \cdot y[n - L] + d \cdot y[n - L - 1]\right)$$
   * Harp ($g = 0.995, d = 0.28$), Nylon/Steel Guitar ($g = 0.992, d = 0.36$), Mandolin ($g = 0.989, d = 0.22$ with double-course $18\text{ ms}$ double-pluck on tremolos), Hammered Dulcimer ($g = 0.994, d = 0.15$ with metallic-wood hammer strike).
6. **`TIMBRE_WHISTLE` (Wooden Low Whistle / Recorder):**
   * Pure fundamental + $2\text{nd}/3\text{rd}$ tube overtones $[1.0, 0.28, 0.12]$ + $22\text{ ms}$ breath chiff transient + automatic **$32\text{nd}$-note diatonic grace-note flicks** before primary downbeats.
7. **`TIMBRE_CARILLON` (Archipelago Bronze & Crystal Chimes):**
   * Modal bell resonator with inharmonic partials $[1.0, 2.0, 2.416, 2.992, 4.18]$ and individual partial decay rates.

---

## 4. Symphonic Chamber Orchestration of the 4 Phase-Locked Stems

Every `ZoneMusicProfileResource` drives four synchronized stems (`StemLayer.FOLK_BASE = 0`, `PASTORAL_LEAD = 1`, `HOLLOWAY_DISCORD = 2`, `SKIRMISH_DRIVE = 3`) with multi-voice orchestration:

### 4.1 Stem 0 (`FOLK_BASE`) — The Buoyant Rhythmic & Arpeggio Atelier
* **In $3/4$ Waltz Zones (`bramble_bridge_square`, `rush_light_hollow`):**
  * **Beat 1:** Warm **Pizzicato Cello** root + **Staccato Bassoon** root/fifth pedal ($140\text{ ms}$ gate, panned $+0.20$).
  * **Beats 2 & 3:** Snappy **Acoustic Guitar, Mandolin, and Pizzicato Viola** upper-structure chords (adding the $9\text{th}$ and Lydian $\sharp 11\text{th}$, panned $-0.25$ and $+0.15$).
  * **Continuous Weave:** **Celtic Harp** plays rolling $8\text{th}$/$16\text{th}$-note Cécile Corbel arpeggios across two octaves, executing a shimmering upward **Lydian Harp Glissando** on the final beat of every 4-bar phrase.
* **In $6/8$ Compound Pastoral Zones (`kindled_bivouac`, `tizzi_wed_green`):**
  * Rolling fingerpicked **Acoustic Guitar** sixths ($\text{1}-\text{5}-\text{3}-\text{2}-\text{1}-\text{5}$), **Celtic Harp** counter-arpeggios, and gentle **Pizzicato Cello & Bassoon** dotted-quarter pulses on beats $1$ and $4$.
* **In $4/4$ Expedition March Zones (`dover_slap_falls` / `doverslap_gorge`):**
  * Crisp **Hammered Dulcimer** & **Mandolin** $8\text{th}$-note fifth ostinati over **Pizzicato Cello** walking bass.

### 4.2 Stem 1 (`PASTORAL_LEAD`) — The Conversational Chamber Quartet
Instead of a single solo line, `PASTORAL_LEAD` orchestrates a three-way conversation between the zone's lead instrument, the **Acoustic Bassoon**, and the **Solo Legato Violin / Oboe**:
* **Voice A (Primary Lead — `lead_timbre`):** Plays an expressive, lyrical melody in `lead_scale` (G Lydian / G Ionian / A Dorian) featuring dotted rhythms, $32\text{nd}$-note grace ornaments, and Evan Call breathing rests on bar $4$ and bar $8$.
* **Voice B (The Quirky Staccato Bassoon Counter-Melody):** Throughout the entire loop, the **Bassoon** answers Voice A with playful, staccato eighth-note leaps (walking in $3\text{rds}$, $5\text{ths}$, and octaves in the $\text{D}_3\text{–}\text{A}_4$ tenor register) and fills every melodic rest with a jaunty 3-note turnaround!
* **Voice C (Soaring Legato Violin & Oboe Harmony):** On the second half of each phrase (bars $3\text{–}4$ and $7\text{–}8$), a **Solo Legato Violin** and **Oboe** swell in sweet parallel $3\text{rds}$ and $6\text{ths}$ an octave above, delivering the unmistakable *Mother's Broom* / *Town With An Ocean View* airborne lift.

### 4.3 Stem 2 (`HOLLOWAY_DISCORD`) — Storybook Woodwind Counterpoint
* Activated by Z-depth in `rush_light_hollow` (`enable_z_depth_discord_blend = true`) or within $35.0\text{ m}$ of an open Hush-Crack (`PROXIMITY_OUTER_RADIUS_M = 35.0`).
* Orchestrated as a **J.S. Bach / Blasting Company Two-Part Invention**: a **Reedy Bassoon** (left-center) and **Plaintive Oboe / English Horn** (right-center) trade syncopated, tiptoeing contrapuntal lines in `discord_scale` (Harmonic Minor / Diminished $7\text{th}$ intervals), accompanied by a soft **Musette Accordion** open-fifth bellows breath and delicate **Pizzicato Strings**.

### 4.4 Stem 3 (`SKIRMISH_DRIVE`) — Kinetic Chamber Folk Drive
* Activated on `CombatDirector` aggro within $0.4\text{ s}$ (`SKIRMISH_ATTACK_SEC`).
* Orchestrated with rapid $16\text{th}$-note **Hammered Dulcimer (Cimbalom)** and **Mandolin** interlocking ostinati, soaring **Carpathian Folk Fiddle** double-stops, rhythmic **Staccato Bassoon & Cello** accents, and a warm **Bodhrán** frame-drum pulse.

---

## 5. Acoustic Atelier Overhaul of `AudioCues` (`src/core/audio_cues.gd`)

All $36$ cues in `AudioCues.CUES` keep their exact `StringName` identifiers and `play()` / `play_at()` signatures, but their synthesis is upgraded to **`MIX_RATE = 44100` Stereo Acoustic Atelier Models** (`enum Instrument { HARP, BASSOON, OBOE, ACCORDION, VIOLIN, CELLO_PIZZ, MANDOLIN, WHISTLE, CARILLON, GLASS_CHIME, WOOD_DRUM, FOLEY_BRUSH }`):

| Cue Category | Cue `StringName` IDs | New Acoustic Atelier Voicing (Zero Square/Saw Waves) |
|---|---|---|
| **The Four Scribe Signs** *(Quantized to Active Zone Tonic)* | `&"seal_iron_root"`<br>`&"seal_rime_gale"`<br>`&"seal_warm_hearth"`<br>`&"seal_star_tide"` | • **Iron-Root:** Low **Bassoon + Cello Bartók Pizzicato + Bronze Anvil-Bell** $\text{I}^5$ open-fifth strike.<br>• **Rime-Gale:** **Hammered Dulcimer + Wooden Whistle + Crystal Chime** upward Lydian $\sharp\hat{4}$ arpeggio.<br>• **Warm-Hearth:** Warm **Musette Accordion $\text{I}^{\text{maj9}}$ Swell + Celtic Harp** glissando.<br>• **Star-Tide:** **Mandolin Tremolo + Oboe + Tubular Carillon** rising Dorian $\text{IV}$ cadence. |
| **Combat & Flow-Link** | `&"hit"`, `&"shot"`, `&"flow"`, `&"perfect_guard"`, `&"knockdown"`, `&"clank"` | • **Hit / Knockdown:** Warm **Bodhrán** skin-thud + **Cello Pizzicato** body impact.<br>• **Flow:** Crisp **Wooden Whistle** grace-flick + **Celtic Harp** harmonic ($\text{E}_5 \rightarrow \text{A}_5$).<br>• **Perfect Guard:** Resonant **Bronze Shield-Bell** + **Violin** fifth harmonic. |
| **Raid Telegraphs & Soaks** | `&"telegraph"`, `&"soak_ok"`, `&"soak_fail"`, `&"beam"` | • **Telegraph:** Dramatic **Bassoon + Oboe** staccato double-reed warning call (replaces harsh `Wave.SAW`).<br>• **Soak OK:** Warm **Accordion + Harp + Carillon** major-sixth resolution.<br>• **Soak Fail:** Low **Bassoon + Cello** minor-second sigh.<br>• **Beam:** Rising **Accordion Bellows + Bowed Cello** tremolo + wind rush. |
| **Storybook World & Progression** | `&"victory"`, `&"camp_cleared"`, `&"chime"`, `&"card_chime"`, `&"card_chime_foil"`, `&"card_chime_astral"`, `&"reward"`, `&"chest"`, `&"purchase"`, `&"refuse"`, `&"equip"`, `&"menu_move"`, `&"join"`, `&"heal"`, `&"portal_charge"`, `&"portal"`, `&"lantern"`, `&"shrine"`, `&"gale"`, `&"bell"`, `&"gate"`, `&"wade"` | • **Victory & Camp Cleared:** Joyful **Musette Accordion, Solo Violin, Bassoon, & Celtic Harp** Lydian chamber fanfare (replaces square-wave arpeggio!).<br>• **Chime / Card Chimes / Shrine / Lantern / Bell:** Authentic inharmonic **Bronze Carillon & Crystal Glass-Bell** modal resonators paired with **Celtic Harp** plucks.<br>• **Refuse:** Playful **Solo Bassoon** two-note descending "uh-uh" ($\text{D}_3 \rightarrow \text{G}\sharp_2$) instead of a buzzsaw wave.<br>• **Menu Move / Equip:** Tactile **Vellum Page / Wooden Scribe Press** click + soft **Harp** harmonic. |

---

## 6. Five-Gate Compliance Summary

* **Gate 1 (Anti-Parasitic Harmony):** Connects Stamina/Poise (Boss Poise-Stagger Lydian Harp/Accordion window), Four Signs (pitch-quantized chamber stingers), $3 \times 3$ Callings (Calling instrument motifs), and Chimes (carillon modal resonators). **PASS.**
* **Gate 2 (The Musk Razor):** Zero extra buttons or menus; $100\%$ automatic via `WorldGridManager`, `WorldStateDB`, and `CombatDirector`. **PASS.**
* **Gate 3 (Philological & Whimsy Linter):** Pure European/Archipelago chamber-folk palette; zero 1970s Speak & Spell oscillators. **PASS.**
* **Gate 4 (Schema-First Registry):** Driven by `ZoneMusicProfileResource` and `AudioCatalog`. **PASS.**
* **Gate 5 (Code-First & Multi-Age Safe):** Deterministic code-built synthesis + `tools/build_audio_stems.py` SoundFont stem baker; $100\%$ headless CI safe. **PASS.**
---

## 6. Build Notes (Phase 16.1, 2026-11-05)

**What's built.**
* **Tier 1:** `tools/build_audio_stems.py` (Python standard library only) composes seven suites as humanized MIDI (±8 ms timing, accented downbeats, 45% staccato for bassoon and pizzicato, 102% legato with CC11 phrase swells and delayed CC1 vibrato for the leads). It renders them through FluidSynth 2.6 and GeneralUser GS v2.0.3, then masters each stem. A stem is cut from the middle of a three-loop render, with a 2,048-sample crossfade at the seam so it loops without a click. It is set to -19 LUFS (the lead to -17) under -1.5 dBTP and encoded as Vorbis q6 with `oggenc`. One bake makes 28 stems, 58 one-shots and loops, a `score.json` per zone and listening copies. It checks every file: it decodes, it isn't silent or clipped, and its spectrum is wide like an ensemble, not narrow like a bare tone. Godot then imports the files, and `tools/build_audio_resources.gd` writes the seven `<profile_id>_sync.tres`. `assets/audio/README.md` explains the files and credits the SoundFont.
* **Tier 2:** `ProceduralChamberSynth` is rewritten as §4.2 asks. Karplus-Strong strings have a fractional delay, a pink pick burst and the two-tap bridge loss. Bassoon and oboe are 12 reed harmonics through their three formant resonators, with a 45 ms breath attack and 5.5 Hz vibrato after 180 ms. The accordion is three musette reeds at 0, +14 and -12 cents under a 2.8 kHz low-pass. The violin is a Helmholtz bowed string through 290, 520 and 2,400 Hz body resonances (180 Hz for a cello). The whistle is a flue resonator over breath. Bells and the bodhrán are struck modal resonators. No voice is a bare oscillator. When the stems are missing it plays each zone's `score.json`, so the fallback is the same tune. A profile with no score gets an oom-pah-pah waltz, a 6/8 sway or a march. Runtime phrases (a Calling's motif) play the baked acoustic samples, re-pitched.
* **AudioDirector:** loads `<profile_id>_sync.tres`, else the four `.ogg` stems, else the fallback. Stem 0 and Stem 1 rest at 0 dB in exploration. The Music bus is low-pass, warm EQ, chamber-hall reverb (0.38, 0.68, 0.85, wet 0.18), then the keyed compressor. SignTelegraphs gets its own hall (0.42, 0.65, wet 0.22). The Four Signs, the Sanctuary Cadence, the Restoration Exhale, the skirmish accent, the gate's A Lydian fanfare, the portal's chord and the Cairnsman's flourish are acoustic stingers. An oasis drops the Holloway discord 12 dB under a harp glissando in the zone's key. Coming home through a portal plays the Sanctuary Cadence. AudioCues plays 30 musical cues as acoustic recordings.
* **Checks:** `tools/test_adaptive_audio.gd` checks the buses' new effects, each zone's acoustic stems and `_sync.tres`, the fallback playing Moss-Oak-Hollow's score, Stems 0 and 1 at 0 dB in Chunks (0, 1) and (0, 0), the oasis, the acoustic ambience loops, and the Sign chords re-pitched to the vale's tonic with their 4.5 dB duck. The smoke test checks the stagger window's discord drop and its acoustic flourish, and that the musical cues are acoustic.

**Deliberate differences from the text above.**
1. **Profile ids.** The suites keep the ids the levels, the biome catalog and the Lens linter already use: `kindled_bivouac` is `honey_wick`, `bramblebridge_square` is `bramble_bridge_square`, `ariundle_holloway` is `moss_oak_hollow`, `doverslap_gorge` is `dover_slap_falls`, `cairnsman_sanctum` is `ring_of_the_cairnsman` and `boss_cairnsman_vigil` is `cairnsmans_vigil`.
2. **Seven suites, not five.** `oakshire_vale` (Oakshire Holm, where every launch starts) and the Ring's prelude are baked too.
3. **Tempo arithmetic.** At 108 quarter-note BPM, 16 bars of 6/8 last 26.67 s, not the 32.0 s in §3.1. Honey-Wick moves from 96 to 108 BPM and Moss-Oak-Hollow from 6/8 to 3/4, as §3 asks. Each profile records its arrangement's bars (`arrangement_bars`), and every tier loops that many.
4. **One chord chart per suite.** All four stems follow the same chord in each bar, so any mix of layers agrees. The Hollow's harmonic-minor invention uses chords both modes share (Em9, Cmaj7, Am7, Am6, B7(b9)). Its diminished colour is the B7(b9) without its root. Cmaj7(#5) is left out because its G# clashes with the Dorian layers.
5. **The Cairnsman's suite** sits on a D pedal, with open fifths in Stem 0 and the percussion, so both the D Lydian Stem 1 and the harmonic-minor Stem 2 fit over it. In the stagger window Stem 2 also drops 18 dB (`stagger_discord_duck_db`), so the Lydian lift doesn't fight the minor line.
6. **The warm EQ.** Godot's EQ6 has no 250 Hz band. The +1.5 dB goes on its 320 Hz band, which covers 250 Hz.
7. **The Sign duck** is -4.5 dB held for 300 ms, with the existing 30 ms attack and 250 ms release.
8. **Formants in the frequency domain.** The reed, bowed and flue resonators weight each harmonic by the resonator bank's response. That is exact for a held tone and cheap enough for GDScript.
9. **Re-pitched stingers.** The Sign chords, cadences, skirmish accent and oasis glissando are baked over G and re-pitched by playback rate, at most 6 semitones (up to 19% faster or slower). The gate's fanfare, the portal's chord and the Cairnsman's flourish are baked in their own keys.
10. **Instruments.** The mandolin is GS bank 16:25, the musette accordion 8:21 (Italian Accordion), the tin whistle 24:75 and the carillon 9:14. The Celtic harp is the Orchestral Harp (46). The bodhrán is the GS Room kit's toms, rim and tambourine.
11. **The gate's plates** are the Maker-Seal Plates ("rune" is retired by Gate 3). Plate 2's harmony uses this doc's C#4, F#4 and B4 (the old code had E4, F#4 and B4).
12. **Noise stays code-built.** The campfire's crackle and the water-shrine's trickle are noise and resonators, and AudioCues' hits, shots, gale, beam, clank and wade stay synthesized.
13. **`test_world_grid.gd`** lives in `deprecated/legacy_maps/bramble_bridge_corridor/` and runs inside the smoke test, not by itself.
14. **Size.** About 18 MB of stems and 14 MB of samples are committed. The SoundFont is not.
