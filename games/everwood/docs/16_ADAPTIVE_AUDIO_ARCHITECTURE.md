# 16_ADAPTIVE_AUDIO_ARCHITECTURE.md — Chamber Pastoral Whimsicalism & Code-First Adaptive Audio Engine

> **SYSTEM DIRECTIVE FOR GEMINI & CLAUDE CODE:** This document is the authoritative musicological and audio-engineering specification for *Everwood*. It governs how zone exploration, multi-focus split-screen ambience, Hush-Crack skirmishes, boss encounters, the Four Scribe Signs, and the $3 \times 3$ Calling Trinity are scored and mixed in Godot 4.7. Every audio feature, stem asset, or sound effect committed to the repository MUST adhere to the Schema-First registries, Musk Razor constraints, and headless CI verification gates defined below.

---

## 1. Architectural Philosophy: Extensibility, Efficiency, & The Musk Razor

To sustain an indie-AAA cooperative action-RPG across a seamless $128\text{ m} \times 128\text{ m}$ Landblock grid (`WorldGridManager`) with up to $4$ local split-screen viewports and $5$ LAN/online family members, *Everwood*'s audio architecture is engineered from three foundational principles: **Schema-First Extensibility**, **Zero-Allocation Runtime Efficiency**, and **The Musk Razor**.

### 1.1 Extensibility-First Schema Registry (`AudioCatalog`)
In strict compliance with **Gate 4 (Schema-First Registry)** of `08_EVERGREEN_DEV_BIBLE.md`, `ActorBase`, `CombatDirector`, `WorldGridManager`, and `EverwoodWorld` never hardcode `.ogg` or `.wav` file paths or branch on boss/zone names via `match` blocks:
1. **Polymorphic Resource Resolution:** Every Landblock, Heritage, Calling, Scribe Sign, and Boss defines its acoustic behavior through strongly typed `Resource` schemas (`ZoneMusicProfileResource`, `CallingAudioProfileResource`, `SignHarmonicProfileResource`, `BossAudioProfileResource`) registered by `StringName` ID inside the central `AudioCatalog` (`src/core/audio_catalog.gd`).
2. **Zero-Code Content Scaling:** Adding a new expedition island in Phase 14 (`Gull-Wick-Haven`, `Barley-Bridge-Meadow`, or `Barrow-Crag-Crossing`) or a new 12-Card Scribe Folio requires only registering a new `ZoneMusicProfileResource` entry in `AudioCatalog` and binding its `StringName` ID in `LandblockManifest`.
3. **Dual-Mode Synthesis & Stem Override Hook:** Mirroring how `ActorVisuals` builds procedural multi-mesh puppets in code while checking `res://assets/models/<id>.glb` for curated 3D overrides, `AudioDirector` (`src/core/audio_director.gd`) checks `res://assets/audio/music/<profile_id>.tres` (or `.ogg` stems) first and automatically falls back to a deterministic, code-first `ProceduralChamberSynth` (`AudioStreamGenerator`) whenever an asset is not yet populated or when running in headless CI.

### 1.2 Efficiency-First Runtime Architecture
Audio processing in a 5-player action-RPG with deterministic $60\text{ Hz}$ hitboxes and $10\text{–}15$ active Boggart-Kin must consume $< 0.25\text{ ms}$ of CPU frame time:
1. **$2.5\text{ Hz}$ ($0.4\text{ s}$) World-Grid Heartbeat Alignment:** `AudioDirector` does not poll spatial distances or zone boundaries at $60\text{ Hz}$. Instead, it subscribes directly to `WorldGridManager`'s existing $2.5\text{ Hz}$ ($0.4\text{ s}$) streaming heartbeat to evaluate the **Multi-Focus Split-Screen Union State**, interpolating stem gains smoothly in a lightweight per-frame ring loop.
2. **Pre-Allocated 32-Voice Ring Buffer & Distance Culling:** `AudioDirector` pre-allocates a fixed pool of $32$ `AudioStreamPlayer3D` nodes at startup. Zero `AudioStreamPlayer3D.new()` or `queue_free()` allocations occur during combat. Any 3D sound request beyond $45.0\text{ m}$ from the nearest local player FocusPoint—or inside the $> 90.0\text{ m}$ dormant AI ring—is culled in $O(1)$ time before claiming a voice.
3. **Lightweight Network Serialization:** ENet RPCs and `WorldStateDB` deltas never serialize audio streams; they broadcast compact `StringName` event IDs and quantized 16-bit positional vectors.

### 1.3 Applying the Musk Razor to Godot 4.7 Audio
> *"Cut so deep that you are forced to add $10\%$ back in."* — `01_VISION.md`

An engineering audit of Godot $4.3\text{–}4.7$'s `modules/interactive_music/` reveals critical engine traps when developers over-complicate adaptive audio graphs:
* **What We Cut (The Trap):** Nesting `AudioStreamInteractive` inside `AudioStreamSynchronized` (or vice versa). In Godot $4.7.2\text{-stable}$, GDScript cannot access an inner `AudioStreamPlaybackInteractive` instance to call `switch_to_clip_by_name()` (`godot-proposals#12957`), and `AudioStreamInteractive` transitions from `CLIP_END` to `CLIP_START` can introduce a $50\text{–}80\text{ ms}$ timing drift and audible click (`godot#94538`). We also cut all manual in-game jukebox menus, combat track-switching toggles, and secondary audio keybinds.
* **What We Keep (The $10\%$ Core):** Pure, flat **4-Stem `AudioStreamSynchronized` Decks** paired with a dual-deck (`Deck A` / `Deck B`) crossfader in `AudioDirector`. In Godot $4.7.2\text{-stable}$ (`audio_stream_synchronized.cpp:197` and `:232`), `AudioStreamSynchronized` starts all sub-streams at the exact same sample frame—guaranteeing $100\%$ phase-locked playback—and updates layer gain every $128\text{-frame}$ mix chunk (`MIX_BUFFER_SIZE`). Because layer volumes live on the `AudioStreamSynchronized` resource (`audio_stream_synchronized.h:50`), `AudioDirector` duplicates the resource per deck and drives vertical combat layering entirely through smooth `set_sync_stream_volume(layer_idx, db)` envelopes.

### 1.4 First-Pass Tooling & Library Recommendations (Indie-AAA Pipeline)
To maintain a clean, future-proof repository without proprietary binary lock-in, we enforce the following tooling boundaries:

| Tool / Library Tier | Technology Selection | Architectural Rationale & Pipeline Role |
|---|---|---|
| **Runtime Audio Engine** | **Native Godot 4.7 `AudioServer` + `AudioStreamSynchronized` + `AudioStreamGenerator`**<br>*(Reject FMOD / Wwise / 3rd-party GDExtensions)* | External C++ middleware (FMOD/Wwise) breaks single-binary headless CI determinism (`--headless --check-only`), adds cross-platform GDExtension notarization friction, and hides bus telemetry from GDScript smoke tests. Native Godot 4.7 provides everything we need in pure GDScript. |
| **Offline Stem Prototyping & Rendering (Optional Dev Tool)** | **`FluidSynth` / `SFizz` CLI + Curated CC0 Chamber Folk `.sf2`/`.sfz` SoundFonts**<br>*(Invoked via `tools/render_chamber_stems.py`)* | Allows us to author deterministic MIDI scores for each zone's 4 stems (Guitar/Harp, Accordion/Violin, Bassoon/Oboe Discord, Dulcimer/Bodhrán Skirmish) and batch-render phase-locked `.ogg` stems offline before live studio recordings arrive in Phase 15. |
| **Offline Asset Conditioning & Loudness Gate** | **`ffmpeg` (`loudnorm` EBU R128 + `afade` Zero-Cross Enforcer)**<br>*(Invoked via `tools/condition_audio_assets.sh`)* | Automatically normalizes long `.ogg` stems via two-pass `loudnorm` to $-16.0\text{ LUFS}$ (spread $< 1.5\text{ LU}$), peak-levels short $< 500\text{ ms}$ `.wav` transients to $-1.0\text{ dBTP}$ (avoiding `loudnorm`'s $+6\text{ to }+9\text{ dB}$ transient overshoot), strips leading silence, and verifies zero-sample loop seams. |
| **Headless CI Audio Verification & Fallback** | **`ProceduralChamberSynth` (`src/core/procedural_chamber_synth.gd`) + `tools/audio_linter.gd`** | Generates real-time plucked string (Karplus-Strong), reed woodwind, and bronze carillon waveforms via `AudioStreamGenerator` when `.ogg` files are absent, and asserts bus layout, voice caps, and sidechain ducking inside `tools/smoke_test.gd`. |

---

## 2. Musicological Theory & Aesthetic Synthesis: Chamber Pastoral Whimsicalism

Designing the interactive soundscape for *Everwood* requires translating a specialized chamber-folk aesthetic—**Chamber Pastoral Whimsicalism**—into a functional, non-fatiguing background music architecture for a 5-player cooperative action-RPG. Rather than relying on grand Hollywood brass bravado, grimdark synthesizer drones, or antique American ragtime, Chamber Pastoral Whimsicalism isolates a pure core of European, Celtic, Mediterranean, Amazigh, and Carpathian folk traditions woven into classical chamber arrangements.

### 2.1 The Two Conversational Instrumental Families
The sonic identity of *Everwood* rests on an intimate, conversational dialogue between two distinct acoustic ensembles:
1. **The Acoustic Folk Core:** Anchored by diatonic button accordion, mandolin (*bisernica*), fingerpicked acoustic guitar, nylon oud-guitar, Celtic harp, hammered dulcimer (*cimbalom*), bronze carillon **Chimes**, and light frame-drum/bodhrán pulse.
2. **The Quirky Chamber Woodwind & String Section:** Led by conversational bassoon, oboe, English horn, wooden recorder / low whistle, and expressive legato and pizzicato violin, viola, and cello.

### 2.2 The Three Cinematic Touchstone Axes
To instill simultaneous feelings of restoration, melancholy, whimsy, and depth while transitioning between sunlit pastoral safety and the hushed, mysterious unknown, the score synthesizes three cinematic axes through the contemporary chamber frameworks of **Evan Call** (*Frieren: Beyond Journey's End*, *Violet Evergarden*), **Cécile Corbel** (*Arrietty*), and **The Arcadian Wild**:
* **The Hisaishi Axis (*Town With An Ocean View* & *Mother's Broom*):** Captures breezy, airborne restoration, nostalgic melancholy, and domestic wonder. Jaunty pizzicato strings and accordion pair with soaring legato violin lines and quirky, leaping bassoon counter-melodies. Rolling $\frac{3}{4}$ and $\frac{6}{8}$ pastoral arpeggios evoke gliding through meadows while retaining the structural capacity to pivot into agitated, turbulent minor-key string ostinati when a **Hush-Crack** stirs.
* **The Shore Axis (*Concerning Hobbits*):** Establishes grounded agrarian optimism, communal warmth, and the tactile joy of harvest, bakery, and hearth. Pentatonic, Ionian, and Lydian folk melodies introduced by solo low whistle and fiddle over a light acoustic guitar pulse gradually expand into a warm chamber string section celebrating family fellowship before an expedition.
* **The Blasting Company Axis (*Over the Garden Wall — Into the Unknown*):** Injects sudden, storybook discordance and despondent wonder at the wide, shadowed world. Because Chamber Pastoral Whimsicalism strips away antique American ragtime and Vaudeville brass, *Everwood* translates the emotional DNA of *Into the Unknown* into a purely European chamber idiom: rubato tempo fluctuations, reedy bassoon and oboe voices moving in stark **harmonic minor** ($\sharp\hat{7}$) and **diminished seventh ($\text{vii}^{\circ 7}$) counterpoint**, and bowed cello *sul ponticello* tremolos that evoke the creeping hush of **The First-Quiet**.

### 2.3 Modal Mechanics, Melodic Spacing, & Counterpoint Matrix
So that crossing $128\text{ m} \times 128\text{ m}$ Landblock boundaries never feels like switching radio stations, transitions between airborne whimsy, agrarian warmth, and hushed discordance occur inside a unified harmonic language:
* **Lydian Lift & Evan Call's Melodic Spacing:** Pastoral melodies utilize the **Lydian mode**—raising the fourth scale degree ($\sharp\hat{4}$) for weightless upward lift—alongside **Evan Call's melodic spacing rule**: avoiding heavy reliance on the natural fourth ($\hat{4}$) in primary melodies and leaving deliberate rests between phrases so the acoustic decay of Celtic harp, oboe, and strings has space to breathe (and so combat callouts remain crystal clear).
* **Arcadian Wild Plucked Counterpoint:** Instead of static synthesizer pads that cloud the $250\text{ Hz} \text{–} 2.5\text{ kHz}$ midrange, mandolin, acoustic guitar, and fiddle weave rhythmically interlocking 3-voice contrapuntal lines that generate kinetic forward momentum without heavy rock or orchestral drum kits.
* **Direct Modal Pivot into the Deep-Hush:** When the party steps from a sunlit Bale-Way into a sunken holloway or approaches an active **Hush-Crack**, a sunlit Lydian progression ($\text{I} \rightarrow \text{II} \rightarrow \text{vii} \rightarrow \text{I}$) drops its third and sixth scale degrees ($\flat\hat{3}, \flat\hat{6}$) while raising the leading tone ($\sharp\hat{7}$) into **Harmonic Minor** ($\text{i} \rightarrow \text{iv} \rightarrow \text{vii}^{\circ 7} \rightarrow \text{V}^7(\flat 9)$), replacing bright mandolin bounce with a halting dialogue between low bassoon, plaintive oboe, and an accordion wheezing in diminished fifths ($\text{dim}5$).

| Emotional Pillar | Primary Touchstones | Modal & Harmonic Language | Lead Conversational Instrumentation | Gameplay Context in *Everwood* |
|---|---|---|---|---|
| **Agrarian Restoration & Hearth** | Howard Shore (*Concerning Hobbits*), Cécile Corbel | Ionian / Pentatonic with open-fifth ($\hat{1}\text{–}\hat{5}$) pedal drones; omitting natural $\hat{4}$ for open air | Acoustic guitar, Celtic harp, low whistle/recorder, warm legato cello | Campfires (`HearthCampfire`), homesteads, post-combat recovery |
| **Airborne Whimsy & Bustle** | Joe Hisaishi (*Town With An Ocean View*, *Mother's Broom*) | Lydian mode ($\sharp\hat{4}$ lift) in $\frac{3}{4}$ or $\frac{6}{8}$ waltz/pastoral meter; playful bassoon leaps | Accordion, pizzicato strings, mandolin, solo legato violin, quirky bassoon | Village squares (`Bramble-Bridge`), artisan stations, sunlit Bale-Ways |
| **Wandering Melancholy & Depth** | Evan Call (*Frieren* OST), The Arcadian Wild | Dorian / Aeolian modal mixture; intricate 3-voice plucked string counterpoint | Mandolin, acoustic guitar, oboe, English horn, solo viola/violin | Open-world threshold trails, moss-oak arches, twilight vistas |
| **Hushed Discordance & Wonder** | The Blasting Company (*Into the Unknown*), Hisaishi (*Mother's Broom* climax) | Harmonic minor ($\flat\hat{3}, \flat\hat{6}, \sharp\hat{7}$), diminished $\text{vii}^{\circ 7}$ counterpoint, rubato | Bassoon & oboe in minor $2\text{nds}$/tritones, accordion bellows drone, *sul ponticello* violin | Sunken Holloways, Hush-Cracks, pre-boss causeways, ambush alcoves |
| **Kinetic Folk Skirmish** | Evan Call (*Zoltraak*), The Arcadian Wild | Dorian / Harmonic minor fast $\frac{6}{8}$ or $\frac{4}{4}$ ostinato; syncopated folk accents | Hammered dulcimer, rapid mandolin & fiddle interlocking, bodhrán, staccato bassoon/cello | Overworld Hush-Crack camps (*Hedgerow-Hobs*, *Boggart-Kin*) & co-op gates |

---

## 3. Industry Post-Mortem & Anti-Parasitic Harmony Across the Core Pillars

In accordance with Stage 1 of the **Evergreen Development Loop** (`08_EVERGREEN_DEV_BIBLE.md`), *Everwood*'s audio architecture incorporates the proven lessons—and avoids the documented failure modes—of four foundational MMOs and RPGs.

### 3.1 Four-Game MMO Audio Post-Mortem
1. **World of Warcraft (*Russell Brower, Derek Duke, Glenn Stafford*) — "The Ear Does Not Blink":** Human hearing remains continuously active; if background music stays permanently locked in the foreground, families suffer listener fatigue and mute the television. *Everwood* enforces Brower's **Emergent Silence Buffer** ($15\text{–}35\text{ s}$ of pure environmental ambience between zone music loops) and the *Mists of Pandaria* non-startling login philosophy (zero jarring roars or brass blasts on the title screen).
2. **The Lord of the Rings Online (*Chance Thomas, Stephen DiGregorio*) — Cultural Stem Matrices & The Anti-Angmar Rule:** Chance Thomas proved the power of culturally segregated acoustic instrument matrices, while the community backlash against harsh, synthetic dread loops in *Angmar* ("the Angmar problem") and abrupt battle-track loop resets demonstrated how quickly synthetic dissonance alienates players. *Everwood* enforces the **Anti-Angmar Rule** (even dark zones use live-sounding acoustic bassoon, oboe, accordion, and strings—never harsh synth dread) and keeps all 4 stems phase-locked so skirmishes never reset a zone's exploration melody to bar $1$.
3. **The Elder Scrolls Online (*Brad Derrick, Matt Conway*) — Painted Ambience Grids & Midrange Frequency Carving:** ESO mapped environmental sound palettes directly to 2D terrain coordinates and carved out the $1.5\text{–}4.0\text{ kHz}$ frequency band in background music so spell transients and material footsteps remained crisp. *Everwood* maps acoustic profiles directly onto its $128\text{ m} \times 128\text{ m}$ `LandblockManifest` grid and carves $1.5\text{–}4.0\text{ kHz}$ in the `Music` bus (reinforced by sidechain ducking) so a 4-year-old Squire can hear **Four-Sign Detonations** and `RaidTelegraphDecal` cues without visual clutter.
4. **EverQuest (*Jay Barbeau*) — Bach Two-Part Inventions, The *Kelethin* Sanctuary Lift, & Real-Time Stem Swapping:** Barbeau used J.S. Bach-style two-part counterpoint, engineered real-time race-based stem swapping on the Character Creation screen, and composed the iconic *Kelethin* theme—which wanders through minor keys before executing a surprise modulation into a bright major key at the cadence to evoke "coming home." *Everwood* adopts both Barbeau's **Character Select Stem Swapper** and the **Sanctuary Lift Cadence** ($\text{e minor} \rightarrow \text{C}^{\text{maj}7} \rightarrow \text{D}^6 \rightarrow \text{G}^{\text{maj}9(\sharp 11)}$) whenever the party crosses into `Bramble-Bridge` or returns through a gold portal.

| Game & Audio Leadership | Zone & Ambience Architecture | Combat Music Handling | Role / Heritage / Character Audio | Key Post-Mortem Lesson for *Everwood* |
|---|---|---|---|---|
| **World of Warcraft**<br>*(R. Brower, D. Duke, G. Stafford)* | Plaintive cues emerging from ambience with long silence buffers. | No music change for overworld foes; bespoke suites for dungeons/bosses. | Strong cultural leitmotifs tied to starting zones and hubs. | **"The Ear Does Not Blink":** Enforce ambient silence intervals ($15\text{–}35\text{ s}$) and gentle title themes. |
| **Lord of the Rings Online**<br>*(C. Thomas, S. DiGregorio)* | Modular stem matrices (Clarinet A–H, Bass Flute A–E) per cultural region. | Hard switch to short battle loops (*Orc Hunt*), resetting zone music. | Cultural instrument palettes + player-performed ABC notation. | **The Anti-Angmar Rule & Phase Lock:** Never use harsh synth dread; keep stems phase-locked so exploration never resets to bar $1$. |
| **Elder Scrolls Online**<br>*(B. Derrick, M. Conway)* | 2D top-down painted ambience grids + subtle background suites. | Smooth crossfade into percussive beds; heavy focus on SFX clarity. | Diegetic 3D tavern bards performing regional folk lore. | **Protect Combat Readability:** Carve $1.5\text{–}4.0\text{ kHz}$ in music so telegraphs and weapon impacts cut through. |
| **EverQuest**<br>*(Jay Barbeau)* | 3D spatial musical objects at landmarks + cyclical Bach counterpoint. | Dedicated stinger/loop (*Perilous Circumstances*) on aggro. | Real-time stem swapping by heritage on Character Creation. | **The Sanctuary Lift & Stem Swapping:** Minor-to-Lydian cadences for safe hubs; real-time Heritage/Calling stem swaps. |

### 3.2 Anti-Parasitic Harmony: Heritages, The $3 \times 3$ Calling Trinity, The Four Signs, & The First-Quiet
To pass **Gate 1 (Anti-Parasitic Harmony)** and **Gate 3 (Philological Linter & The Single-Origin Antagonist Rule)** of `08_EVERGREEN_DEV_BIBLE.md`, every core gameplay system in *Everwood* feeds directly into the chamber score across a shared living-room speaker system without creating cacophony:

| *Everwood* Gameplay Pillar | Canonical IDs / Variants (`06` & `08`) | Chamber Pastoral Instrumental Voice | Musical & Harmonic Integration |
|---|---|---|---|
| **Character Heritages**<br>*(Archipelago Cultures)* | `Wadden-Green` (*Gull-Wick-Haven*), `Luka-Bay` (*Barley-Bridge-Meadow*), `Tizzi-Wed` (*Tizzi-Wed-Green*), `Hazel-Weald` (*Barrow-Crag-Crossing*) | Accordion/Carillon (`Wadden-Green`), Mandolin/Guitar (`Luka-Bay`), Oud-Guitar/Reed Flute (`Tizzi-Wed`), Cimbalom/Bassoon (`Hazel-Weald`) | Real-time stem swapping on Character Select (*EverQuest* model) + campfire/Scribe Desk solo flourishes quantized to the active zone's tonic. |
| **The Shield-Sworn**<br>*(Tank Calling Trinity)* | `Bridge-Warden` (+Tank), `Weald-Captain` (+DPS), `Hearth-Guard` (+Magic) | Low bronze bridge-bell, cello Bartók pizzicato, bassoon staccato root-fifth pedal | Reinforces `L Guard` posture, `ThreatComponent` taunts, and poise stability in the warm low-mid register ($80\text{–}350\text{ Hz}$). |
| **The Wayfarers**<br>*(DPS Calling Trinity)* | `Iron-Woodsman` (+Tank), `Hedge-Runner` (+DPS), `Sign-Seeker` (+Magic) | Mandolin double-stop, acoustic guitar percussive strum, recorder/whistle transient | Accents **Flow-Link** recovery windows and weapon delivery (`Falchion`, `Broad-Axe`, `Yew Longbow`). |
| **The Lantern-Bearers**<br>*(Magic Calling Trinity)* | `Bell-Keeper` (+Tank), `Wind-Mender` (+DPS), `Lantern-Scribe` (+Magic) | Brass carillon **Chimes**, breathy oboe/ocarina swell, Celtic harp harmonic glissando | Signals `D-Pad` Soul Tethers, `Rowan Way-Staff` casts, and Mender healing projections. |
| **Sign of Iron-Root**<br>*Shatterpoint* ($+45.0$ Poise Dmg) | `SIGN_IRON_ROOT` (Amber/Ochre) | Low bassoon + cello Bartók pizzicato + brass anvil-chime strike | Root + Open Fifth ($\hat{1}\text{–}\hat{5}\text{–}\hat{8}$) power chord quantized to active zone tonic; ducks `Music` bus by $-6.0\text{ dB}$ for $0.8\text{ s}$. |
| **Sign of Rime-Gale**<br>*Glacial Rupture* ($+45.0$ Burst) | `SIGN_RIME_GALE` (Sea-Azure) | Hammered dulcimer + high glass-chime + piccolo/recorder arpeggio | Lydian $\sharp\hat{4}$ crystalline upward burst ($\hat{1}\text{–}\hat{3}\text{–}\sharp\hat{4}\text{–}\hat{5}\text{–}\hat{8}$) quantized to active zone tonic; ducks `Music` bus by $-6.0\text{ dB}$ for $0.8\text{ s}$. |
| **Sign of Warm-Hearth**<br>*Dawnburst* ($20.0\text{ HP}$ Party Heal) | `SIGN_WARM_HEARTH` (Saffron-Gold) | Warm accordion major $9\text{th}$ swell + Celtic harp upward glissando | Ionian/Lydian Major $9\text{th}$ chord ($\hat{1}\text{–}\hat{3}\text{–}\hat{5}\text{–}\hat{7}\text{–}\hat{9}$) providing instant auditory warmth across split-screen. |
| **Sign of Star-Tide**<br>*Astral Chorus* ($+25.0\text{ Stam}, +0.5\text{ Pips}$) | `SIGN_STAR_TIDE` (Twilight-Violet) | Interlocking mandolin tremolo + oboe + tubular chime | Dorian Major $\text{IV}$ rising cadence ($\hat{1}\text{–}\hat{4}\text{–}\hat{6}\text{–}\hat{8}$) energizing party stamina and Resonance Pip generation. |
| **Spirits of The First-Quiet**<br>*(Hob-to-Boggart Spectrum)* | *Hedgerow-Hobs*, *Weald-Wights*, *Boggart-Kin*, *Iron-Men*, stirred by `Old-Hob-of-the-Hill` | Rattling seed-pods, bassoon/oboe minor $2\text{nds}$, muted brass kettle-cap clinks | Rising from a **Hush-Crack** introduces harmonic minor ($\sharp\hat{7}$) tension; **un-boggarting** a foe resolves its dissonant interval into a peaceful pentatonic sigh and brass **Chimes** scatter. |

---

## 4. Zone-by-Zone Mood, Ambience, & Musical Specifications

In Phase 11+, *Everwood* operates as a seamless world (`everwood_world.gd`) built on a deterministic $128\text{ m} \times 128\text{ m}$ Landblock grid (`WorldGridManager`). To prevent adjacent $128\text{ m}$ chunks from clashing harmonically when players straddle a chunk seam ($Z = -64\text{ m}$) or split up across adjacent chunks in 4-player couch co-op, the entire $8\text{ km} \times 8\text{ km}$ **Region $(0, 0)$ — The Bramble-Reach** is unified under a master regional tonic of $\text{G}$ ($\text{MIDI } 67 = \text{G4}$, and its relative/parallel modal centers: $\text{G Ionian/Lydian}$, $\text{E Dorian/Harmonic Minor}$, and $\text{A/D Dorian}$) anchored at a shared base tempo grid of $108\text{ BPM}$ so cross-chunk transitions remain musically phase-locked.

### 4.1 Chunk $(0, 1)$: The Kindled Bivouac & Oakshire-Green
* **Spatial Coordinates:** $Z \in [+64.0\text{ m}, +192.0\text{ m}]$, Base Elevation $0.0\text{ m}$.
* **Musicological Spec:** Synthesizes **Howard Shore (*Concerning Hobbits*)** and **Cécile Corbel** in $\text{G Ionian}$ with subtle $\text{C Lydian}$ ($\sharp\hat{4}$) inflections, $\frac{6}{8}$ pastoral meter at $96\text{ BPM}$ (dotted-quarter $= 48\text{ BPM}$). Omits the natural $\hat{4}$ in the opening whistle motif for open air.
* **Stem Architecture:**
  * `Stem 0 (FOLK_BASE)`: Fingerpicked acoustic guitar and Celtic harp outlining warm parallel sixths (*Rivervale* counterpoint).
  * `Stem 1 (PASTORAL_LEAD)`: Solo wooden recorder / low whistle trading unhurried phrases with a warm bassoon playing staccato root-fifth ($\hat{1}\text{–}\hat{5}$) bass notes past the heirloom pumpkin patches and seven cedar bee-hives, joined by a solo legato violin near the south gate of `Bramble-Bridge`.
* **Diegetic 3D & `WorldStateDB` Binding:** Crackling birch-wood fire and bubbling tripod kettle at `HearthCampfire` attenuate by $-6.0\text{ dB}$ during its $180.0\text{ s}$ `WorldStateDB` cooldown while a saffron harp harmonic lingers; overhead `WindLantern` brass-and-glass tinkle ($1\text{–}3\text{ m}$ sweet spot); warm honeybee hum along the east woodline hives.
* **Emergent Silence Buffer:** $15.0\text{–}25.0\text{ s}$ between $90.0\text{ s}$ musical cycles, letting morning birdsong, bee hum, and oak wind carry the scene.

### 4.2 Chunk $(0, 0)$: Bramble-Bridge South & Village Square
* **Spatial Coordinates:** $Z \in [-64.0\text{ m}, +64.0\text{ m}]$, Base Elevation $0.0\text{ m}$.
* **Musicological Spec:** Synthesizes **Joe Hisaishi (*Town With An Ocean View* & *Mother's Broom*)** with **Jay Barbeau's *Kelethin* Sanctuary Lift** in $\text{G Lydian}$ ($\text{C}\sharp$ raised fourth), buoyant $\frac{3}{4}$ waltz at $108\text{ BPM}$.
* **The Bramble-Bridge Sanctuary Cadence:** Crossing the $10^{\circ}$ arched canal bridge into the Village Square (persisting `EverwoodWorld.town_square_reached` in `WorldStateDB`) or warping home via a gold portal triggers a 2-bar minor-to-Lydian modulation ($\text{e minor} \rightarrow \text{C}^{\text{maj}7} \rightarrow \text{D}^6 \rightarrow \text{G}^{\text{maj}9(\sharp 11)}$) that signals domestic safety.
* **Stem Architecture:**
  * `Stem 0 (FOLK_BASE)`: Crisp pizzicato cello and viola waltz pulse intertwined with acoustic guitar and mandolin strums.
  * `Stem 1 (PASTORAL_LEAD)`: Expressive diatonic **accordion** and **solo legato violin** trading the sunny primary melody, punctuated by conversational **bassoon and oboe** counter-melodies.
* **Diegetic 3D Stations & Silence Buffer:** Rushing canal water beneath the bridge, rhythmic $\frac{3}{4}$ wooden splash of the watermill wheel, crackling bread-oven at the smoking bakery, wooden clack and Bach harp/bassoon invention at the **Scribe Desk**, and pentatonic bronze carillon harmonics ($\text{G–A–B–D–E}$) at the **Chime-Shrine**. Silence buffer: $12.0\text{–}20.0\text{ s}$.

### 4.3 Chunk $(0, -1)$: Ariundle Moss-Oaks & The Sunken-Hollow
* **Spatial Coordinates:** $Z \in [-192.0\text{ m}, -64.0\text{ m}]$, Base Elevation $0.0\text{ m}$ sinking into the holloway trench.
* **Musicological Spec:** Executes Stage 3's **Kishōtenketsu Introduction & Twist** (`08_EVERGREEN_DEV_BIBLE.md`), synthesizing **The Blasting Company (*Into the Unknown*)**, **Joe Hisaishi (*Mother's Broom* minor development)**, and **The Arcadian Wild** at $108\text{ BPM}$ ($\frac{6}{8}$ meter).
* **Intra-Chunk $Z$-Depth Modal Pivot:**
  * *Moss-Oak Threshold ($Z \in [-104.0\text{ m}, -64.0\text{ m}]$):* Begins in **$\text{E Dorian}$** ($\text{E–F}\sharp\text{–G–A–B–C}\sharp\text{–D}$), driven by `Stem 0`'s weaving Arcadian Wild arpeggios on mandolin and acoustic guitar over a bowed cello pedal drone.
  * *Sunken-Hollow Descent ($Z < -104.0\text{ m}$ to $-154.0\text{ m}$ full blend):* As the party descends into the sunken lane toward the Holloway Hush-Crack camp, `Stem 1 (PASTORAL_LEAD)` crossfades into `Stem 2 (HOLLOWAY_DISCORD)`, pivoting directly into **$\text{E Harmonic Minor}$ and Diminished Seventh Counterpoint** ($\text{E–F}\sharp\text{–G–A–B–C–D}\sharp$, $\text{D}\sharp\text{dim}^7$). Reedy **bassoon** and **oboe** perform a halting two-part invention in minor seconds ($\text{m}2$) and tritones ($\text{dim}5$) over a wheezing **accordion** bellows drone and high *sul ponticello* violin harmonics.
* **Miyazaki Mundane-Magic Oasis:** Standing within $4.0\text{ m}$ of the **Wayfarer's Water-Shrine** or swaying **Wind-Lanterns** temporarily lifts the diminished tension into a shimmering $\text{E Lydian/Dorian}$ Celtic harp oasis. Silence buffer: $20.0\text{–}35.0\text{ s}$.

### 4.4 Chunk $(0, -2)$: Dover-Slap-Falls Bridge & Sinaya Gatehouse
* **Spatial Coordinates:** $Z \in [-320.0\text{ m}, -192.0\text{ m}]$, Elevation climb $+8.0\text{ m}$.
* **Musicological Spec:** Combines **Evan Call (*Frieren* expedition cues)** with **Carpathian Chamber Folk** in $\text{A Dorian}$ / $\text{A Aeolian}$ at $108\text{ BPM}$ ($\frac{4}{4}$ processional march).
* **Acoustic Frequency Separation Over Waterfall Broadband Noise:** Because roaring waterfalls and the **Gorge Gale-Jet** generate dense broadband noise, `Stem 0` relies on crisp **hammered dulcimer (*cimbalom*)** and **mandolin** ostinati that cut cleanly through the spray while `Stem 1`'s **English horn** and **legato violin** soar in wide octaves and sixths across the chasm.
* **Interactive Co-Op Threshold Puzzle Scoring (`CoopGate`):**
  * *Maker-Seal Plate 1 (`RunePlate` 1) Pressed:* Fades in a sustained accordion and cello open-fifth ($\text{A2–E3}$) pedal drone.
  * *Maker-Seal Plate 2 (`RunePlate` 2) Pressed (scales to $\min(2, \text{party\_size})$):* Locks in an oboe and mandolin $\text{A Dorian}$ counter-harmony ($\text{E4–F}\sharp\text{4–B4}$).
  * *Bronze Bridge-Bell Winch Cranked:* Strikes a deep bronze carillon toll in $\text{A}$ that resolves into a triumphant 2-bar **$\text{A Lydian}$** chamber fanfare the instant `WorldStateDB` records `gate_sinaya_01` as `"opened": true`.

### 4.5 Chunk $(0, -3)$: The Ring of the Cairnsman
* **Spatial Coordinates:** $Z \in [-448.0\text{ m}, -320.0\text{ m}]$, Elevation climb $+10.0\text{ m}$ ($+18.0\text{ m}$ total).
* **Pre-Pull Causeway (Hisaishi Wind-Swept Solitude):** $80\%$ of the mix consists of gorge wind whistling through standing stones and distant waterfall spray, accompanied only by a solitary low whistle and plucked harp harmonic in $\text{D Dorian}$.
* **Boss Encounter Suite (*The Cairnsman's Vigil*):** Engaging **The Cairnsman of Dover-Slap-Falls** launches a 2-phase chamber raid piece inspired by **Evan Call's *Zoltraak*** and **The Arcadian Wild** in $\text{D Dorian}$ / $\text{D Harmonic Minor}$ at $132\text{ BPM}$ ($\frac{6}{8}$ folk gallop):
  * *Phase 1 ($100\% \rightarrow 55\%$ HP):* Rapid interlocking mandolin, acoustic guitar, and Carpathian fiddle lines lock into a propulsive groove with bodhrán and hammered dulcimer while bassoon and cello trade rhythmic stabs.
  * *Phase 2 ($< 55\%$ HP & `BLUE_BEHIND_TANK` Dover-Slap Gale-Beam):* Double-time oboe and legato violin counterpoint escalates urgency without ever crossing into oppressive grimdark noise that would frighten a 4-year-old Squire.

### 4.6 The Master Zone & Six-Zone Atlas Musical Matrix

| Zone / Region ID | Grid Coordinates & Elevation | Key & Modal Center | Tempo & Meter | Lead Chamber Pastoral Palette | Cultural & Emotional Signature |
|---|---|---|---|---|---|
| **Chunk $(0, 1)$**<br>*Kindled Bivouac & Oakshire-Green* | $Z \in [+64\text{ m}, +192\text{ m}]$<br>Elevation: $0.0\text{ m}$ | $\text{G Ionian}$ / $\text{C Lydian}$ ($\sharp\hat{4}$) | $96\text{ BPM}$ ($\frac{6}{8}$ sway) | Acoustic guitar, Celtic harp, low whistle, pizzicato bassoon, solo violin | **Shore (*Concerning Hobbits*):** Warm campfire restoration, bee-hives, pumpkin harvest. |
| **Chunk $(0, 0)$**<br>*Bramble-Bridge Square* | $Z \in [-64\text{ m}, +64\text{ m}]$<br>Elevation: $0.0\text{ m}$ | $\text{G Lydian}$ ($\sharp\hat{4}$) | $108\text{ BPM}$ ($\frac{3}{4}$ waltz) | Accordion, mandolin, pizzicato strings, legato violin, quirky bassoon & oboe | **Hisaishi (*Town With An Ocean View*):** Breezy village bustle, canal bridge sanctuary lift. |
| **Chunk $(0, -1)$**<br>*Ariundle & Sunken-Hollow* | $Z \in [-192\text{ m}, -64\text{ m}]$<br>Elevation: $0.0\text{ m}$ | $\text{E Dorian} \rightarrow \text{E Harmonic Minor}$ / $\text{Dim}^7$ | $108\text{ BPM}$ ($\frac{6}{8}$ rubato) | Bassoon & oboe counterpoint, accordion drone, mandolin/guitar weave, *sul ponticello* violin | **Blasting Co. (*Into the Unknown*) + *Mother's Broom*:** Dappled moss-oaks sinking into hushed wonder. |
| **Chunk $(0, -2)$**<br>*Dover-Slap-Falls & Gatehouse* | $Z \in [-320\text{ m}, -192\text{ m}]$<br>Elevation: $+8.0\text{ m}$ | $\text{A Dorian} \rightarrow \text{A Lydian}$ (on Gate Open) | $108\text{ BPM}$ ($\frac{4}{4}$ march) | Hammered dulcimer (*cimbalom*), English horn, mandolin, bronze bridge-bell, legato strings | **Evan Call (*Frieren*) + Carpathian Folk:** Mist-swept trestle verticality, co-op Maker-Seal harmony. |
| **Chunk $(0, -3)$**<br>*Ring of the Cairnsman* | $Z \in [-448\text{ m}, -320\text{ m}]$<br>Elevation: $+18.0\text{ m}$ | $\text{D Dorian}$ / $\text{D Harmonic Minor}$ (Boss) | $132\text{ BPM}$ ($\frac{6}{8}$ gallop) | Rapid fiddle & mandolin counterpoint, bodhrán, hammered dulcimer, bassoon, chamber strings | **Call (*Zoltraak*) + Arcadian Wild:** Wind-swept standing stone prelude $\rightarrow$ 2-phase chamber raid. |
| **Oakshire-Vale**<br>*$1.5\text{ km}$ Seamless Vale* | $12 \times 12$ Landblocks (`OakshireValeLayout`) | $\text{F Lydian} \rightarrow \text{D Dorian}$ / $\text{Harmonic Minor}$ | $104\text{ BPM}$ ($\frac{3}{4}$ & $\frac{6}{8}$) | Full conversational quartet: accordion, mandolin, acoustic guitar, oboe, bassoon, violin | **Hisaishi + Shore Synthesis:** Rolling Bale-Ways, sheep-stile deer-runs, and sunken holloways. |
| **Gull-Wick-Haven**<br>*Wadden-Green Downs (Dutch/Flemish)* | Phase 14 Atlas (`ZoneManifestResource`) | $\text{C Lydian}$ / $\text{A Aeolian}$ | $112\text{ BPM}$ ($\frac{3}{4}$ breezy) | Diatonic button accordion, brass carillon chimes, wooden flute, pizzicato cello | **Hisaishi (*Kiki* Windmill Flight):** Sea-meadow greens, spinning windmills, *Sea-Cave Scrays*. |
| **Barley-Bridge-Meadow**<br>*Luka-Bay Coast (Dalmatian)* | Phase 14 Atlas (`ZoneManifestResource`) | $\text{D Mixolydian}$ / $\text{Lydian}$ | $100\text{ BPM}$ ($\frac{6}{8}$ barcarolle) | Mandolin (*bisernica*), acoustic guitar, oboe, solo cello, accordion | **Hisaishi (*Ocean View*) + Mediterranean Folk:** Sunlit limestone bridges, *Furrow Iron-Men*. |
| **Tizzi-Wed-Green**<br>*Saffron Cliffs (Amazigh)* | Phase 14 Atlas (`ZoneManifestResource`) | $\text{E Phrygian Dominant}$ / $\text{Dorian}$ | $108\text{ BPM}$ ($\frac{6}{8}$ & $\frac{12}{8}$) | Nylon oud-guitar, reed flute, bassoon, bendir frame drum, solo violin | **Celtic-Amazigh Chamber Synthesis:** Warm terracotta greens, saffron wind-lanterns, star-inked mystery. |
| **Barrow-Crag-Crossing**<br>*Hazel-Weald Crags (Carpathian)* | Phase 14 Atlas (`ZoneManifestResource`) | $\text{G Harmonic Minor}$ / $\text{Dorian}$ | $116\text{ BPM}$ ($\frac{4}{4}$ & $\frac{6}{8}$) | Bassoon, oboe, hammered dulcimer (*cimbalom*), folk fiddle, contrabass pizzicato | **Blasting Co. + Carpathian Chamber:** Knotted crag roots, *Cairn-Drakes*, whimsical danger. |

---

## 5. Seamless Zone-to-Combat Blending & Multi-Focus Split-Screen Resolution

### 5.1 Four-Stem Phase-Locked `AudioStreamSynchronized` Anatomy
Each zone's `AudioStreamSynchronized` resource encapsulates four phase-locked `.ogg` stems (or `ProceduralChamberSynth` voices) exported at the exact same tempo and bar count with `loop = true`, `bpm`, and `beat_count` embedded:
* **`Stem 0 (FOLK_BASE)`:** Plucked acoustic guitar, mandolin, Celtic harp, and pizzicato bass/cello rhythmic foundation.
* **`Stem 1 (PASTORAL_LEAD)`:** Accordion, legato violin, low whistle, and sunny oboe/bassoon conversational melody (Lydian/Ionian/Dorian).
* **`Stem 2 (HOLLOWAY_DISCORD)`:** Harmonic minor ($\sharp\hat{7}$) and diminished ($\text{vii}^{\circ 7}$) counterpoint on bassoon, oboe, accordion drone, and *sul ponticello* strings.
* **`Stem 3 (SKIRMISH_DRIVE)`:** Hammered dulcimer, driving bodhrán and frame drums, rapid mandolin/fiddle interlocking ostinati, and staccato cello/bassoon accents.

### 5.2 The Multi-Focus Split-Screen Union Audio Resolver
On every $2.5\text{ Hz}$ ($0.4\text{ s}$) heartbeat from `WorldGridManager`, `AudioDirector` evaluates the `FocusPoints` of all active local viewports alongside `CombatDirector` threat telemetry to resolve a single **Authoritative Party Acoustic State**:
1. **Highest Threat Priority Wins:** If *any* local split-screen player (or any networked teammate within the $\le 35.0\text{ m}$ Full-Tick $60\text{ Hz}$ AI evaluation radius of a local player) enters active combat with a Hush-Crack `MinionCamp` or Boss, the party audio transitions into **Stage B (Active Skirmish Lock)** or **Stage C (Boss Suite)**. This immediately alerts a sibling browsing the Scribe Desk in `Chunk (0, 0)` that their party member just stirred *Hedgerow-Hobs* across the gate seam in `Chunk (0, -1)`.
2. **Majority Focus Chunk Selection:** When no player is in combat, the active zone profile is chosen by the majority chunk among local viewports (tie-broken by the forward-most expedition chunk, i.e., lowest $Z$-coordinate).
3. **Intra-Chunk $Z$-Depth Interpolation:** Within chunks where `enable_z_depth_discord_blend == true` (such as `Chunk (0, -1)`), `AudioDirector` computes the mean $Z$-coordinate $\bar{Z}$ of players inside that chunk and linearly crossfades `Stem 1` and `Stem 2` via:
   $$\alpha_Z = \text{clamp}\left(\frac{\bar{Z} - Z_{\text{start}}}{Z_{\text{full}} - Z_{\text{start}}}, 0.0, 1.0\right)$$

### 5.3 The Four-Stage Combat Blend & Restoration Exhale Envelope

#### Stage A: Proximity & Telegraph Pre-Warming ($35.0\text{ m} \rightarrow 14.0\text{ m}$)
As the party approaches an un-calmed `MinionCamp` (Hush-Crack) and crosses the $35.0\text{ m}$ boundary where enemy AI upgrades from $10\text{ Hz}$ reduced ticks to $60\text{ Hz}$ full hitbox/posture evaluation, `AudioDirector` calculates a continuous proximity scalar based on the distance $d$ to the nearest active foe:
$$S_{\text{prox}}(d) = \text{clamp}\left(\frac{35.0 - d}{35.0 - 14.0}, 0.0, 1.0\right)$$
As $S_{\text{prox}}(d)$ rises from $0.0$ at $35.0\text{ m}$ to $1.0$ at $14.0\text{ m}$, `Stem 2 (HOLLOWAY_DISCORD)` swells from $-80.0\text{ dB}$ to $-6.0\text{ dB}$ along an equal-power curve while `Stem 1 (PASTORAL_LEAD)` attenuates by $-4.0\text{ dB}$. Before a single weapon is swung, the bassoon and oboe whisper to the family that a Hush-Crack is near.

#### Stage B: Active Skirmish Lock ($0.4\text{ s}$ Beat-Quantized Attack)
The instant `CombatDirector` registers active aggro or a deterministic hitbox-hurtbox overlap:
1. The underlying `AudioStreamSynchronized` deck **continues playing at its exact musical bar and beat position without restarting**.
2. Quantized to the next eighth-note subdivision ($\approx 0.27\text{ s}$ at $108\text{ BPM}$), a crisp acoustic percussive stinger (bodhrán rim-hit + hammered dulcimer roll + mandolin slash) fires.
3. `Stem 3 (SKIRMISH_DRIVE)` ramps from $-80.0\text{ dB}$ to $0.0\text{ dB}$ over $0.4\text{ s}$ ($\approx 1$ beat), `Stem 2 (HOLLOWAY_DISCORD)` locks at $-3.0\text{ dB}$, and `Stem 1 (PASTORAL_LEAD)` ducks to $-18.0\text{ dB}$. Rather than cutting to an external battle loop, the existing chamber quartet leans forward into an Evan Call (*Zoltraak*) and Arcadian Wild folk drive.

#### Stage C: Boss Encounter Suite & The $35\text{–}45\text{ s}$ Poise-Stagger Lydian Window
Engaging an expedition boss crossfades from `Deck A` (Zone) to `Deck B` (Boss Suite at $132\text{ BPM}$) over $2$ beats ($0.9\text{ s}$). In strict harmony with `04_BALANCE.md`—which mandates that boss poise staggers occur every $35.0\text{–}45.0\text{ s}$—when the family's `SIGN_IRON_ROOT` (*Shatterpoint* $+45.0$ poise damage) and heavy attacks break the boss's poise bar:
* `AudioDirector` triggers **The Poise-Stagger Lydian Window**: all heavy combat percussion (`Stem 3`) drops by $-14.0\text{ dB}$ for the stagger duration while a shimmering **$\text{D Lydian}$** Celtic harp, accordion, and brass chime flourish swells to $0.0\text{ dB}$. Even a 4-year-old playing on Squire Gambit Assist receives an unmistakable, joyful auditory cue that the boss is staggered and ready for a family burst window before the rhythm slams back in on recovery.

#### Stage D: The Restoration Exhale & Brower Silence Breath
When the final Boggart-Kin in a camp or boss sanctum is **un-boggarted**:
1. **$1.5\text{ s}$ Hysteresis Hold:** `AudioDirector` holds the skirmish state for $1.5\text{ s}$ to prevent fade thrashing if another Hush-Crack pack is pulled immediately.
2. **The Restoration Exhale Stinger:** At the next bar boundary, a solo low whistle, cello, and accordion chord resolves from minor into a sunlit major/Lydian sixth (Jay Barbeau's *Kelethin* relief cadence) accompanied by the gentle scatter of brass **Chimes**.
3. **2-Bar Cosine S-Curve Fade ($3.6\text{ s}$):** `Stem 3 (SKIRMISH_DRIVE)` and `Stem 2 (HOLLOWAY_DISCORD)` fade out to $-80.0\text{ dB}$ over $2$ full musical bars ($3.6\text{ s}$).
4. **The $8.0\text{–}12.0\text{ s}$ Post-Battle Silence Breath:** Immediately following the fade, `Stem 0` and `Stem 1` dip to $-24.0\text{ dB}$ for $10.0\text{ s}$, leaving only quiet fingerpicked guitar and 3D environmental audio (wind in the moss-oaks, trickling `WaterShrine`, crackling `HearthCampfire`) while the family opens the `WayfarerChest` before `Stem 1 (PASTORAL_LEAD)` swells back in from its phase-locked position.

| Transition Stage | Trigger Condition & Spatial Metric | Stem Volume Envelope (`Stem 0` / `1` / `2` / `3`) | Fade Duration & Quantization | Emotional & Gameplay Feel in *Everwood* |
|---|---|---|---|---|
| **0. Pure Exploration** | Nearest active foe $> 35.0\text{ m}$ ($10\text{ Hz}$ or $0\text{ Hz}$ AI tick) | $0\text{ dB} / 0\text{ dB} / -80\text{ dB} / -80\text{ dB}$ (or $Z$-depth blend in Holloway) | Continuous; $15\text{–}35\text{ s}$ silence buffer between loops | Rolling through fields (Hisaishi) or bouncing through hills (Shore). |
| **A. Proximity Pre-Warm** | Nearest active foe $35.0\text{ m} \rightarrow 14.0\text{ m}$ ($60\text{ Hz}$ Full AI Tick) | $0\text{ dB} / -4\text{ dB} / -6\text{ dB} / -80\text{ dB}$ (scales linearly $35\text{ m} \rightarrow 14\text{ m}$) | Continuous distance interpolation ($2.5\text{ Hz}$ update) | Subtle *Into the Unknown* bassoon/oboe harmonic minor tension whispers danger. |
| **B. Active Skirmish Lock** | `CombatDirector` aggro or hitbox-hurtbox overlap | $0\text{ dB} / -18\text{ dB} / -3\text{ dB} / 0\text{ dB}$ + dulcimer/bodhrán accent | $0.4\text{ s}$ ($1$ beat) quantized to next eighth-note subdivision | Chamber players lean in; rapid *Zoltraak* / Arcadian Wild folk drive without track reset. |
| **C. Boss Poise-Stagger** | Boss Poise $\le 0.0$ (every $35\text{–}45\text{ s}$ via `SIGN_IRON_ROOT`) | Percussion ducks $-14\text{ dB}$; Lydian Harp/Accordion/Chime layer at $0\text{ dB}$ | Immediate on stagger frame; exits on boss recovery beat | Joyful, unmistakable auditory window for kids and adults to burst the staggered boss. |
| **D. Restoration Exhale** | All engaged foes un-boggarted $+ 1.5\text{ s}$ hysteresis hold | Minor-to-Lydian cadence $\rightarrow$ `Stem 2` & `3` to $-80\text{ dB}$; $10\text{ s}$ breath at $-24\text{ dB}$ | $2$ bars ($3.6\text{ s}$) cosine S-curve fade $+ 10\text{ s}$ ambient breath | Deep restorative exhale; wind and water-shrines fill the air before melody resumes. |

---

## 6. Menus, Character Creation, Town Micro-Zones, & Instance Transitions

### 6.1 Main Menu & Character Creation: *The Grimoire by the Open Window*
Applying Russell Brower's *Mists of Pandaria* login lesson alongside Jay Barbeau's *EverQuest* Character Creation stem engine, the title and character-select screen plays *The Grimoire by the Open Window*—a $96.0\text{ s}$ cyclical chamber piece in $\text{F Lydian}$ / $\text{D Dorian}$ at $104\text{ BPM}$ ($\frac{3}{4}$ waltz) driven by an 8-stem `AudioStreamSynchronized` deck:
* **Title Idle (`Stem 0` + `Stem 1`):** Solo Celtic harp and acoustic guitar over the soft ambient texture of vellum pages turning at a wooden Scribe Desk and a meadow breeze, joined by a gentle Hisaishi-style accordion and legato violin waltz.
* **Interactive Heritage & Calling Quartet Builder (`Stems 2–7`):** Highlighting one of the 4 **Character Heritages** crossfades its cultural lead stem from $-80.0\text{ dB}$ to $0.0\text{ dB}$ over $0.35\text{ s}$. Selecting one of the **9 Callings** brings in that archetype's chamber voice (warm cello & bronze bell for *Shield-Sworn*, crisp mandolin & fiddle counterpoint for *Wayfarers*, shimmering **Chimes** & oboe for *Lantern-Bearers*) and locks it at $-3.0\text{ dB}$ when the player readies up—allowing the 4 couch players to literally assemble their family chamber ensemble before launching the expedition.

### 6.2 Inside Towns: Spatialized Diegetic Micro-Zones & Godot 4.7.2 3D Calibration
All 3D diegetic emitters (`AudioStreamPlayer3D`) and combat sound effects are calibrated against verified **Godot 4.7.2 audio engine benchmarks**:

| Acoustic Metric / Benchmark | Godot 4.7.2 Measured Parameter | *Everwood* Spatial & Mix Calibration |
|---|---|---|
| **3D Near-Field Sweet Spot ($1.0\text{–}3.0\text{ m}$)** | Flat response at $+3.0\text{ dB}$ (`unit_size = 10.0`, `max_db = +3.0`) | Intimate interaction radius for `HearthCampfire`, Scribe Desk, `WaterShrine`, and `WindLantern` micro-motifs. |
| **3D Mid-Field Roll-Off ($5.0\text{–}20.0\text{ m}$)** | Drops $-6.0\text{ dB}$ (to $-3.0\text{ dB}$) at $10.0\text{ m}$; LPF removes $-9.5\text{ dB}$ at $5.0\text{ kHz}$ by $50.0\text{ m}$ | Prevents `Bramble-Bridge`'s Chime-Shrine, smoking bakery, and watermill from clashing across the $40.0\text{ m}$ village square. |
| **3D Far-Field & AI Culling ($> 45.0\text{ m}$)** | Drops $-20.0\text{ dB}$ (to $-17.0\text{ dB}$) at $50.0\text{ m}$; AI ticks scale at $35.0\text{ m}$ ($60\text{ Hz}$) and $90.0\text{ m}$ ($10\text{ Hz}$) | Distance-cull enemy vocalizations and footsteps beyond $45.0\text{ m}$ in $O(1)$ before claiming a voice from the 32-voice pool. |
| **`Area3D` Reverb Masking** | `area_mask` defaults to `0` in Godot 4.7.2 (causing `Area3D` reverb buses to be ignored) | Force `area_mask = 1` on all `AudioStreamPlayer3D` nodes in `AudioDirector` and `tools/build_levels.gd` so archways and gatehouses apply convolution reverb. |
| **Combat Mix Peak Headroom** | Naive $10$ foes @ $60\text{ Hz}$: $+11.4\text{ dBFS}$ $\rightarrow$ 32-Cap only: $+4.2\text{ dBFS}$ $\rightarrow$ Cap + Cooldown + 4 Takes: $-2.8\text{ dBFS}$ | Enforce a **32-voice pool cap** + **$50.0\text{ ms}$ per-type cooldown** + **4-take `AudioStreamRandomizer`** ($\pm 8\%$ pitch, $\pm 1.5\text{ dB}$ gain) on all combat SFX. |
| **Cross-Grimoire / Scribe Press Focus** | `AudioEffectLowPassFilter` on `Music` & `Ambience3D` buses | Opening the Scribe Press or Cross-Grimoire sweeps cutoff $20.0\text{ kHz} \rightarrow 1.8\text{ kHz}$ over $0.3\text{ s}$ while raising the Bach harp/bassoon invention by $+2.0\text{ dB}$. |

### 6.3 Portal & Lugger-Boat Transitions
Because `AudioDirector` persists as an Autoload singleton across scene changes, instance transitions never cut audio playback:
1. **Raid Portal & Gold Return Portal (*The Wayfarer's Threshold*, $2.5\text{ s}$):** Sweeps a resonant low-pass filter ($20.0\text{ kHz} \rightarrow 900\text{ Hz}$ over $0.5\text{ s}$) across the outgoing deck while playing a suspended $\text{G}^{\text{sus}2(\text{add}9)}$ chord on shimmering brass **Chimes**, Celtic harp, and breathy accordion. The instant the destination scene initializes, the filter opens back to $20.0\text{ kHz}$ and resolves onto the downbeat of the destination theme (triggering the **Bramble-Bridge Sanctuary Cadence** when returning home).
2. **Lugger-Boat Atlas Travel (*Across the Star-Tide*, $4.0\text{ s}$):** Plays a $4.0\text{ s}$ maritime chamber bridge—creaking lugger-boat timber, lapping hull waves, accordion, and a solo oboe playing a Hisaishi *Ocean View* phrase that modulates smoothly from the departure island's key into the destination island's tonic.

---

## 7. Gate Verification & Code-First GDScript Engineering Specification

### 7.1 Mandatory Five-Gate Verification (`08_EVERGREEN_DEV_BIBLE.md`)

| Gate ID & Pedigree | Mandatory Rule (`08_EVERGREEN_DEV_BIBLE.md`) | Verification Audit for *Everwood* Audio Architecture | Gate Verdict |
|---|---|---|---|
| **GATE 1**<br>*Anti-Parasitic Harmony* | Must directly feed into at least two core pillars: Stamina/Poise, Four Signs, $3 \times 3$ Callings, or Chimes/Vellum. | Harmonizes with all four pillars: (1) **Stamina/Poise** via the Boss Poise-Stagger Lydian Harp/Accordion Window every $35\text{–}45\text{ s}$; (2) **The Four Signs** via root-key-quantized chamber stingers and $-6.0\text{ dB}$ sidechain ducking; (3) **The $3 \times 3$ Callings** via character-select stem building and posture motifs; (4) **Chimes** via pentatonic carillon shrine resonances. | **PASS** |
| **GATE 2**<br>*The Musk Razor* | Strip secondary menus, cooldown bloat, and extra keybinds; execute through the 6-Posture Controller Contract. | Zero manual jukebox menus, zero extra controller buttons, zero nested `AudioStreamInteractive` bugs. Music adapts automatically via $2.5\text{ Hz}$ `WorldGridManager` coordinates, `WorldStateDB` deltas, and `CombatDirector` threat. | **PASS** |
| **GATE 3**<br>*Philological Linter & Single-Origin Antagonist Rule* | Pass the 4 Linter Rules (`Bramble-Bridge`, `Dover-Slap-Falls`, `Tizzi-Wed-Green`, `Gull-Wick-Haven`, `Barley-Bridge-Meadow`, `Barrow-Crag-Crossing`) & Single-Origin Antagonist Rule. | All zone names use hyphenated Map-Sense compounds; all foes are spirits of **The First-Quiet** rising from **Hush-Cracks** and are **un-boggarted** (resolving diminished intervals into pentatonic chimes); zero grimdark synth noise. | **PASS** |
| **GATE 4**<br>*Schema-First Registry* | Content added as typed `Resource` data registered in central catalogs; polymorphic resolution. | Zone profiles, stem volumes, and modal keys are encapsulated in `ZoneMusicProfileResource`, `SignHarmonicProfileResource`, and `CallingAudioProfileResource` inside `AudioCatalog` with zero hardcoded `match` branches in `ActorBase`. | **PASS** |
| **GATE 5**<br>*Code-First & Multi-Age Safe* | Build deterministically in GDScript; headless CI safe; support Master, Adventurer, and Squire (4-year-old) tiers. | $100\%$ code-built 5-bus layout and `ProceduralChamberSynth` fallback; headless CI safe on Godot's `Dummy` driver (`--headless --check-only` and `smoke_test.gd`); Poise-Stagger Lydian cues and $-6.0\text{ dB}$ Sign ducking allow a 4-year-old Squire to read boss states by ear. | **PASS** |

### 7.2 Schema-First Resource Specifications (`src/resources/`)

#### A. `ZoneMusicProfileResource` (`src/resources/zone_music_profile_resource.gd`)
```gdscript
class_name ZoneMusicProfileResource
extends Resource

## Canonical tuning constants (Godot 4.7.2 verified)
const DEFAULT_BPM: float = 108.0
const DEFAULT_BEATS_PER_BAR: int = 3
const SILENCE_BUFFER_MIN_SEC: float = 15.0
const SILENCE_BUFFER_MAX_SEC: float = 30.0
const SKIRMISH_ATTACK_SEC: float = 0.4
const RESTORATION_EXHALE_SEC: float = 3.6
const POST_COMBAT_SILENCE_SEC: float = 10.0
const PROXIMITY_OUTER_RADIUS_M: float = 35.0
const PROXIMITY_INNER_RADIUS_M: float = 14.0

## Stem indices inside the phase-locked AudioStreamSynchronized resource
enum StemLayer {
	FOLK_BASE = 0,        ## Guitar, Mandolin, Harp, Pizzicato Bass
	PASTORAL_LEAD = 1,    ## Accordion, Legato Violin, Sunny Woodwinds (Lydian/Ionian)
	HOLLOWAY_DISCORD = 2, ## Bassoon, Oboe, Diminished/Harmonic Minor Counterpoint
	SKIRMISH_DRIVE = 3    ## Hammered Dulcimer, Bodhran, Rapid Folk Ostinato
}

@export var profile_id: StringName = &"bramble_bridge_square"
@export var display_title: String = "Bramble-Bridge Waltz"
@export var root_pitch_midi: int = 67 ## 67 = G4 (Master Regional Tonic for Region 0,0)
@export var modal_signature: StringName = &"G_LYDIAN"
@export var bpm: float = DEFAULT_BPM
@export var beats_per_bar: int = DEFAULT_BEATS_PER_BAR

## Optional path to curated 4-stem AudioStreamSynchronized (.tres wrapping 4 .ogg streams)
## Falls back automatically to ProceduralChamberSynth when empty or in headless CI.
@export_file("*.tres") var synchronized_stream_path: String = ""

## Default exploration stem volumes (in dB) when out of combat
@export var explore_stem_volumes_db: PackedFloat32Array = PackedFloat32Array([
	0.0,   ## Stem 0: FOLK_BASE active
	0.0,   ## Stem 1: PASTORAL_LEAD active
	-80.0, ## Stem 2: HOLLOWAY_DISCORD muted until Z-threshold or 35m Hush-Crack proximity
	-80.0  ## Stem 3: SKIRMISH_DRIVE muted until CombatDirector aggro
])

## Intra-chunk Z-coordinate threshold to blend Stem 1 -> Stem 2 (e.g., Sunken-Hollow)
@export var enable_z_depth_discord_blend: bool = false
@export var discord_blend_z_start: float = -104.0
@export var discord_blend_z_full: float = -154.0

## Silence breath window between exploration loop cycles (Russell Brower rule)
@export var silence_interval_range_sec: Vector2 = Vector2(SILENCE_BUFFER_MIN_SEC, SILENCE_BUFFER_MAX_SEC)
```

#### B. `SignHarmonicProfileResource` (`src/resources/sign_harmonic_profile_resource.gd`)
```gdscript
class_name SignHarmonicProfileResource
extends Resource

const DEFAULT_SIDECHAIN_DUCK_DB: float = -6.0
const DEFAULT_SIDECHAIN_DURATION_SEC: float = 0.8

@export var sign_id: StringName = &"SIGN_IRON_ROOT"
@export var instrument_timbre: StringName = &"BASSOON_CELLO_ANVIL_CHIME"
## Semitone offsets relative to the active ZoneMusicProfileResource.root_pitch_midi
@export var chord_semitone_intervals: PackedInt32Array = PackedInt32Array([0, 7, 12])
@export var arpeggio_step_sec: float = 0.035
@export var sidechain_duck_db: float = DEFAULT_SIDECHAIN_DUCK_DB
@export var sidechain_duration_sec: float = DEFAULT_SIDECHAIN_DURATION_SEC
@export_file("*.wav", "*.ogg") var custom_stinger_path: String = ""
```

#### C. `CallingAudioProfileResource` (`src/resources/calling_audio_profile_resource.gd`)
```gdscript
class_name CallingAudioProfileResource
extends Resource

@export var calling_id: StringName = &"Bridge-Warden"
@export var trinity_family: StringName = &"SHIELD_SWORN"
@export var lead_instrument: StringName = &"BRONZE_BELL_CELLO_PIZZ"
@export var character_select_stem_index: int = 2
@export var posture_motif_intervals: PackedInt32Array = PackedInt32Array([0, 7, 12])
@export var frequency_band_hz: Vector2 = Vector2(80.0, 350.0)
```

### 7.3 Deterministic 5-Bus Hierarchy & Sidechain Architecture (`AudioDirector`)
On `_ready()`, `AudioDirector` constructs a deterministic 5-bus hierarchy under `Master` in pure GDScript (never relying on a hand-edited `default_bus_layout.tres` that could drift in git merges):

| Bus Index & Name | Target Parent | Nominal Volume | Mounted `AudioEffect` Chain (Built in Code) | Primary Routing Responsibility |
|---|---|---|---|---|
| `0: Master` | — | $0.0\text{ dB}$ | `AudioEffectLimiter` (ceiling $= -0.5\text{ dBFS}$, threshold $= -2.0\text{ dB}$) | Final living-room television/headphone safety ceiling. |
| `1: Music` | `Master` | $-4.0\text{ dB}$ | `0`: `AudioEffectLowPassFilter` (cutoff $= 20000\text{ Hz}$, resonance $= 0.5$)<br>`1`: `AudioEffectEQ6` ($-2.5\text{ dB}$ carve at $1.5\text{–}4.0\text{ kHz}$)<br>`2`: `AudioEffectCompressor` (sidechained to `SignTelegraphs`, ratio $= 4.0:1$, threshold $= -18.0\text{ dB}$, attack $= 15\text{ ms}$, release $= 450\text{ ms}$) | Dual `AudioStreamSynchronized` decks (`Deck A` & `Deck B`) + `ProceduralChamberSynth` fallback. |
| `2: Ambience3D` | `Master` | $-6.0\text{ dB}$ | `0`: `AudioEffectLowPassFilter` (cutoff $= 20000\text{ Hz}$) | Spatialized 3D emitters (`HearthCampfire`, canal water, watermill, bee-hives, waterfall, `WaterShrine`) with `area_mask = 1`. |
| `3: SignTelegraphs` | `Master` | $-1.5\text{ dB}$ | — (Acts as the sidechain key source for `Music` bus compressor) | Root-pitch-quantized **Four-Sign Detonation** stingers, **Poise-Stagger Lydian Window** harp/accordion flourishes, and `RaidTelegraphDecal` cues (`RED_AVOID`, `GOLD_STACK`, `GREEN_HEAL`, `BLUE_BEHIND_TANK`). |
| `4: CombatSFX` | `Master` | $-3.0\text{ dB}$ | `0`: `AudioEffectHardLimiter` (ceiling $= -1.5\text{ dBFS}$) | Pre-allocated 32-voice `AudioStreamPlayer3D` ring buffer with $50.0\text{ ms}$ per-type cooldown and 4-take `AudioStreamRandomizer`. |

### 7.4 Headless CI Verification Gates (`tools/smoke_test.gd` & `tools/audio_linter.gd`)
Every update to `AudioDirector`, `AudioCatalog`, or `ZoneMusicProfileResource` must pass three automated headless verification checks before commit:
1. **Static Type & Parse Verification:**
   ```bash
   godot --headless --path . --check-only -s src/core/audio_director.gd
   ```
2. **Bus Topology & Voice-Cap Smoke Assertions (`tools/smoke_test.gd`):**
   * Verify `AudioServer.bus_count >= 5` and confirm exact bus names (`Master`, `Music`, `Ambience3D`, `SignTelegraphs`, `CombatSFX`).
   * Verify `AudioDirector.get_voice_pool_size() == 32` and confirm that firing $64$ simultaneous combat SFX requests at distance $10.0\text{ m}$ caps active voices at $\le 32$, enforces the $50.0\text{ ms}$ per-type cooldown, and culls any request at $d > 45.0\text{ m}$ with zero node allocations.
   * Verify that all `AudioStreamPlayer3D` nodes spawned by `AudioDirector` and `tools/build_levels.gd` have `area_mask == 1`.
3. **Adaptive State Machine & Sidechain Verification:**
   * Simulate moving local viewport FocusPoints across `Chunk (0, 1)` $\rightarrow$ `Chunk (0, 0)` $\rightarrow$ `Chunk (0, -1)` ($Z = -160.0\text{ m}$) $\rightarrow$ `Chunk (0, -2)` $\rightarrow$ `Chunk (0, -3)` and assert that `AudioDirector.get_active_profile_id()` resolves each canonical `ZoneMusicProfileResource`, blends `Stem 2 (HOLLOWAY_DISCORD)` as $Z$ crosses $-104.0\text{ m} \rightarrow -154.0\text{ m}$, transitions to `SKIRMISH_DRIVE` on `CombatDirector` aggro, triggers the **Poise-Stagger Lydian Window** when boss poise reaches $0.0$, and quantizes `SIGN_IRON_ROOT`, `SIGN_RIME_GALE`, `SIGN_WARM_HEARTH`, and `SIGN_STAR_TIDE` chord intervals to `root_pitch_midi`.
---

## 8. Build Notes (Phase 16)

What the game does today, where it differs from §1–7, and what's still to come.

**In the code now**
- **`AudioDirector`** (`src/core/audio_director.gd`, autoload `Score`) builds the five buses in code (§7.3) and plays two decks, each one zone's four stems as an `AudioStreamSynchronized`. A new zone, or a boss suite, loads into the back deck and crossfades (4 s between zones, 2 beats into a boss). A deck at the same tempo starts in step with the one playing. Stem volumes move only through `set_sync_stream_volume()`, and no `AudioStreamInteractive` is used anywhere.
- **The party state, every 0.4 s** (§5.2): the zone most local players stand in (a tie goes to the one furthest up the trail), the depth blend into the Holloway discord, and the threat round the local players and any teammate within 35 m of one. Curious hobs (`HOB_BENIGN`) are no threat.
- **The four stages** (§5.3):
  - **Proximity Pre-Warm:** S rises from 0 at 35 m to 1 at 14 m; the discord swells toward −6 dB on an equal-power curve and the lead dips 4 dB.
  - **Skirmish Lock:** 0 / −18 / −3 / 0 dB over 0.4 s on the same playing stems, with a bodhrán-and-dulcimer accent on the next eighth note.
  - **Boss:** the Cairnsman's Vigil; Phase 2 lifts the discord under 55% health. The Poise-Stagger window raises the D Lydian flourish stem to 0 dB, drops the percussion 14 dB, and plays a harp flourish.
  - **Restoration Exhale:** a 1.5 s hold, a minor-to-Lydian cadence on the next bar, stems 2 and 3 gone over a 3.6 s cosine fade, 10 s of breath at −24 dB, then exploring again.
  - **Silence breath:** out of a fight, every 90 s of music fades to silence for the zone's interval (Brower's rule).
- **`AudioCatalog`** (`src/core/audio_catalog.gd`) holds every profile by id: seven zones, the Four Signs (§3.2's chords), the nine Callings and the Cairnsman's suite. Any profile saved as a `.tres` in `res://data/audio/` is registered by its type and replaces a built-in of the same id.

  | Profile | Where | Key |
  |---|---|---|
  | `honey_wick` | the Kindle-Fire and Honey-Wick, Chunk (0, 1) | G Ionian, 96 BPM, 6/8 |
  | `bramble_bridge_square` | Bramble-Bridge, Chunk (0, 0), and the classic hub | G Lydian waltz, 108 BPM (plays the Sanctuary Cadence on arrival) |
  | `moss_oak_hollow` | Moss-Oak-Hollow, Chunk (0, -1), and the expedition's Zone 1 | E Dorian, darkening to E harmonic minor down Rush-Light-Hollow's sunken lane |
  | `dover_slap_falls` | Dover-Slap-Bridge and the falls, Chunk (0, -2), and Zone 2 | A Dorian march, 108 BPM |
  | `ring_of_the_cairnsman` | the causeway and the Ring, Chunk (0, -3), and Zone 3 | D Dorian, the whistle over the wind |
  | `cairnsmans_vigil` | the Cairnsman's fight | D Dorian / harmonic minor, 132 BPM, D Lydian stagger stem |
  | `oakshire_vale` | Oakshire Vale | F Lydian waltz, 104 BPM |

- **`ProceduralChamberSynth`** (`src/core/procedural_chamber_synth.gd`) is the code-first ensemble: Karplus-Strong guitar, harp and cimbalom, reeds, whistle, accordion, bowed violin, bronze bells and bodhrán.
  - Each zone's four stems are rendered as one progression's looping 16-bit PCM, seeded by the profile id, on worker threads from boot. A zone takes about 0.15 s.
  - It also renders every stinger and the station ambience. A curated stem set at `res://assets/audio/music/<profile_id>.tres` (or a profile's `synchronized_stream_path`) replaces the code-built stems.
- **Levels say where.** `LevelBase.music_profile_at()` returns the profile for a spot: the trail reads `LandblockManifest.ZONE_MUSIC` by chunk row, the expedition by zone, the hub and the vale one each. `LevelBase.music_world_z()` lets the expedition's Zone 1 share the trail's depth blend.
- **Stingers.** Each Four-Sign detonation plays its chord over the zone's tonic on SignTelegraphs, rung out on a chime. It also ducks the Music bus: the compressor keyed by SignTelegraphs, plus a scripted −6 dB for 0.8 s. The other stingers are the Sanctuary Cadence, the exhale cadence, the skirmish accent, the stagger flourish, the Co-Op Gate's A Lydian fanfare, the Wayfarer's Threshold chord (with a 0.5 s low-pass sweep through every portal) and each Calling's posture motif when a hero changes Calling.
- **3D sound.**
  - A pool of 32 `AudioStreamPlayer3D` voices is made once at start, on CombatSFX with `area_mask = 1`, `unit_size` 10, `max_db` +3 and a 5 kHz far filter.
  - Hits and shots now play where they land, through `AudioCues.play_at()`: culled beyond 45 m of every local player, 50 ms apart per kind, through an `AudioStreamRandomizer` (×1.08 pitch, ±1.5 dB).
  - The other cues stay non-positional, on SignTelegraphs (Signs, telegraphs, soaks) or CombatSFX.
- **Station ambience** (`AudioDirector.attach_ambience()`, on Ambience3D with `area_mask = 1`):
  - the Kindle-Fire's crackle, 6 dB lower while it burns low;
  - each water-shrine's trickle, quieter while it rests;
  - the Chime-Shrine's pentatonic carillon;
  - the Co-Op Gate's plate harmonies: the A2–E3 drone with one plate held, the A Dorian counter-line with two, silent once open.
  The water-shrines and wind-lanterns are oases: within 4 m the Holloway discord lifts. Each station's state comes from its own `WorldStateDB` binding, so a resting shrine sounds rested after a reload too.
- **Checks.** `tools/test_adaptive_audio.gd` (run by the smoke test) checks:
  - the buses and their effects, the catalog and the code-built stems;
  - each zone's score walking the trail, the depth blend and the oasis, the majority rule, and the station ambience;
  - in Oakshire Vale: the voice pool, cooldown and culling, the four stages on a padfoot, and the Sign stingers and duck.
  The expedition checks add the Cairnsman's stagger window, the plate harmony and the gate fanfare. The Lens linter now reads every audio title too.

**Deliberate differences from the spec**
- **`src/core` is new.** There was no `audio_director.gd` to refactor, so this is a new build. The existing `AudioCues` autoload still renders the short cues and now routes them onto the new buses.
- **The brief's "Oakshire Vale" chunks are the Bramble-Bridge trail.** Chunks (0, 1) to (0, −3) belong to the seamless world (`everwood_world`); Oakshire Vale is its own 12 × 12 world. Both are scored, along with the classic hub and the instanced expedition.
- **Names follow the Mythopoetic Lens** (15 §7): Honey-Wick and the Kindle-Fire, Moss-Oak-Hollow into Rush-Light-Hollow, the Dover-Slap Gatehouse, Maker-Seal Plates, Tizzi-Wed-Green.
  - Two parts of this doc predate the Lens and contradict doc 15. §3.2's Heritages (Wadden-Green, Luka-Bay, Hazel-Weald) aren't in the game. §4.6's atlas rows give Tizzi-Wed-Green, Gull-Wick-Haven and the others different cultures and places than doc 15's atlas. Neither is built: a Creative Director call.
- **Chunk coordinates.** §4 puts Chunk (0, 0) at z −64 to +64; the grid's Chunk (0, 0) is z 0 to 128. So the depth blend sits on the real sunken lane, z −54 (the ramp's top) to −74. The doc's −104 to −154 would fall on Dover-Slap-Bridge.
- **The 2.5 Hz heartbeat is the director's own.** The world grid's streaming heartbeat is 0.2 s and emits no signal, and the hub and the expedition have no grid. The director evaluates every 0.4 s in every level instead; the cost is the same.
- **Code-built stems are rendered loops.** They are `AudioStreamWAV` buffers inside the `AudioStreamSynchronized`, not live `AudioStreamGenerator` voices. A generator nested in a synchronized stream can't be fed from GDScript: the same trap as §1.3's nested `AudioStreamInteractive`.
- **Tempo** is the quarter-note BPM in every profile; a 6/8 bar is three quarter notes. The doc mixes dotted-quarter and eighth tempos.
- **Master uses `AudioEffectHardLimiter`** (ceiling −0.5 dB) rather than the deprecated `AudioEffectLimiter`.
- **One take per combat sound.** The randomizer spreads pitch and gain over a single code-built take, not four recordings.
- **Time is game time.** The 50 ms cooldown and every stage timer run on game time, so they stay deterministic under `--fixed-fps`. Headless runs keep every state and volume but start no playback.
- **Verification.** `--check-only -s tools/smoke_test.gd` is part of the check loop. `tools/test_world_grid.gd` isn't a standalone script (the smoke test runs it), and headless runs can't take screenshots. The full smoke test is the verification path, and a windowed run is how to listen.

**Still to come**
- The character-select stem builder (§6.1: there is no title or character-select screen yet), Heritages, lugger-boat travel (§6.3), and the Scribe Press / Cross-Grimoire focus low-pass (§6.2).
- The offline tools (`tools/render_chamber_stems.py`, `tools/condition_audio_assets.sh`) and curated `.ogg` stems (Phase 15).
- More emitters: canal water, watermill, bee-hives, bakery, waterfall, and the Scribe Desk's invention.
- Per-petal scores in Oakshire Vale, and Phase 2's double-time counterpoint.
