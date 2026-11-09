# 31 · The Opening Film ("Prologue")

> Copied from the opening-cinematic handoff (`handoff/everwood_opening_cinematic/docs/OPENING_CINEMATIC_SPEC.md`, 2026-11-09), with the build notes added as §12. The timeline JSON, captions, plates and fonts now live in `assets/cinematics/prologue/` and `assets/fonts/`.


**Status:** Ready to implement · **Length:** 30.0 s · **Plays:** once per new character
**Values live in:** `data/opening_cinematic_timeline.json` (times, captions, camera moves, effects, audio cues). This doc explains intent and rules; if a number here and in the JSON disagree, the JSON wins.

---

## 1. What "done" means

After 30 seconds, a 9-year-old on the couch can answer, without touching the controller:

1. **Where am I?** Embershore, the warm south island of a ring of five. The big tree in the middle is where the story is going.
2. **What's wrong?** A grey tide is washing the color, and the names, out of everything. It has just reached our orchards.
3. **What do I do first?** Walk to the orchard gate. The man with the lantern, the narrator, is waiting.

The film ends *as* gameplay: its last frame is the player's own camera at the Lv 1 spawn, with no cut, no load screen, and no camera pop.

## 2. Canon used

- **The Caldera Isles.** A collapsed fire-mountain left a ring of five islands around a calm water called **the Sound**, broken by one gap in the north-west, **The Breach**. Islands: **Embershore** (south, start/hub), **Iron-Ness** (west), **Barrow-Eyot** (east), **Rime-Firth** (north), **The Crown** (centre).
- **The World-Tree** grows on The Crown's +65 m summit. Its golden sap is the color in every living thing.
- **The old kings' wound.** The old kingdom cut stone sluices down the Crown's east shore (the Tide Grottos) and drained the sap into the sea. The wound still bleeds: **the Star-Tide**.
- **The Long Flood and the Un-Inking.** For 25 years the Star-Tide has held the sea 6 m high, drowning the **Old Quay Market**. Wherever its grey touches, color and names fade to **Blank-Stone**. Folk call it **the Un-Inking**.
- **Where you wake.** Sheltered Embershore still glows. It is the week of the Great Autumn Feast; the grey has reached the orchards. The player wakes in **Homestead Meadows** on the Lee Shore; **Master Alf-Wright** waits at the orchard gate.

**Naming:** the island is **Embershore** in all player-facing text. Code may still use older IDs (e.g. `oakshire_*`, `OakshireVale`); keep IDs, change display strings only.

**Philological linter:** all narration is written to pass the 8-Year-Old Read-Aloud Rule and contains none of the banned words. Do not reword it.

## 3. Shot list

| # | Time | Beat | Narration (Alf-Wright) | Picture & camera |
|---|---|---|---|---|
| 1 | 0:00–0:05 | The Ring | "Long ago, a ring of islands rose from fire and sea." | Parchment map of the ring; slow push-in. |
| 2 | 0:05–0:10 | The World-Tree | "At its heart grows the World-Tree. Its golden sap colors all things." | The Crown pops up like a storybook fold; gold sap veins run to every island; crane up. |
| 3 | 0:10–0:14 | The Old Kings' Wound | "But the old kings bled that sap into the sea." | Crowned figures carve sluices; gold pours into the sea and turns violet; pan right and down. |
| 4 | 0:14–0:20 | The Un-Inking | "Now a grey tide rises. All it touches forgets its color… and its name." | Sea rises over the Old Quay arches; grey sweeps right-to-left; a Bramble-Hound goes grey mid-step; title "The Un-Inking" runs. Silence on "name." |
| 5 | 0:20–0:25 | Embershore | "Only Embershore still glows. And tonight, the grey has reached its orchards." | Golden-hour Embershore: windmill turning, Hearthstead in Feast bunting; tilt down to mist spilling over the orchard wall. |
| 6 | 0:25–0:30 | Wake Up, Steward | "Wake up, steward." | Page dissolves into the live 3D scene; camera dives into Homestead Meadows and settles into the play camera behind the player. Alf-Wright waves his lantern at the orchard gate. "EVERWOOD / The Caldera Isles" inks on at 0:27; control at 0:30. |

Shots 1–5 are a **2D storybook layer** (plates + pan/zoom + overlay effects + captions) drawn over the 3D world while it streams in. Shot 6 is **live 3D**.

## 4. Trigger & persistence

- Plays **right after New Character creation is confirmed**, before the first gameplay frame, then spawns the character at the prologue spawn.
- **Never** plays when loading an existing character.
- Per-character save field **`prologue_seen: bool`** (default `false`). Set `true` when the film finishes **or** is skipped. Existing saves without the field are treated as `true` (they are not new characters).
- If the game quits mid-film, `prologue_seen` stays `false` and the film plays again on next load of that character.

## 5. Co-op & online

- **Same-couch, same moment:** if several seats create new characters before entering the world together, play the film **once, full screen**, before split-screen starts.
- **Late drop-in with a new character** (local seat or online peer joining a running session): that player's viewport alone shows the **recap**: the six plates as a page-flip, 1.5 s each, with captions, skippable by that player. Everyone else keeps playing. Then that player spawns normally and `prologue_seen = true`.
- **Online (peer-hosted):** the host is authoritative. Host sends a start RPC with a start timestamp; clients play locally in sync. Skip is a host RPC. Clients that are not new characters are unaffected.

## 6. Skip

- **Only the host can skip:** seat 1 locally, the host peer online.
- Input: **hold the existing pause/menu action for 1.5 s**, with a fill ring. **No new input actions** (Gate 2, Musk Razor).
- Non-host players see a small "Host can skip" hint.
- Skip jumps straight to the shot-6 end state (rig camera current at the spawn pose, title card gone, Chime-Post ribbon showing), sets `prologue_seen`, and unlocks control immediately.

## 7. Handoff & spawn

- **Spawn:** Homestead Meadows on Embershore's Lee Shore. World Map Bible §3.2 places it at local **(+128 m, +448 m)** (-Z = north toward the Sound, +X = east). The orchard terraces and the Great Windmill are to the east; Hearthstead to the north.
- **Facing:** toward the **OrchardGate** marker (proposed local **(+300 m, +430 m)**, the west edge of the orchard terraces; verify). Framing goal: the gate and Alf-Wright in the right third, the World-Tree on the horizon left of centre.
- **Camera:** the shot-6 Camera3D starts at the timeline's offset above and behind the rig's spawn pose and eases (out-cubic, 25.0 → 29.0 s) to **exactly** the PlayerCameraRig spawn pose (doc 18: default pitch 22°, height 4.8 m, boom 6.8 m). Then the rig's camera becomes current. Tolerance: 1 cm and 0.1°. Read the pose from the rig at runtime; do not hardcode it.
- **If world content is missing:** if the current build has no Embershore layout, no spawn marker, no `OrchardGate` or no Alf-Wright NPC, add clearly named placeholder markers or nodes at the coordinates above with TODOs. Do not build terrain, the NPC or quest Q01.

## 8. Streaming & performance

- Stream the starting zone during shots 1–5 so the dive in shot 6 needs no load screen.
- The storybook layer is a CanvasLayer over the world; it must hold 60 fps on the target machine with the zone streaming underneath.
- The film plays full screen, never inside a split-screen cell (except the late-joiner recap).

## 9. Assets (all placeholders)

- `art/storyboards/shot01…06*.png`: 1920×1080 plates. Shots 1–5 are the on-screen art for now; shot 6 is a composition reference only (the scene is rendered live). The matching `.svg` sources are included.
- `art/fonts/`: IM FELL English (Roman, Italic, SC) and Alegreya Sans (Regular, Bold), SIL OFL (licences included).
- **Audio:** none yet. Fire an event for every `cues[].id` at its `t_s` so the Adaptive Audio system can attach stems later.
- Narration is captions-only until VO is recorded. Captions are always on for this film.

## 10. Acceptance criteria

1. New character → film plays once; existing character → no film. Covered by a headless test.
2. Skip (host, 1.5 s hold) sets `prologue_seen`, lands at the same end state, and unlocks control. Non-host skip input is ignored. Covered by a test.
3. Timeline integrity test: 6 shots, contiguous, 0.0 → 30.0 s; every caption inside its shot; cue ids unique; caption text matches `data/opening_cinematic.en.srt`.
4. Handoff test: the shot-6 camera's final transform equals the rig's spawn pose within tolerance.
5. Late drop-in recap shows only on the joining player's viewport; other players are not interrupted.
6. Manual 1080p run: all six shots in order, captions on time, no load screen, no camera pop at 0:29–0:30.
7. The project parses and builds with zero new errors or warnings; existing smoke tests still pass.
8. A Five-Gate audit (08_EVERGREEN_DEV_BIBLE.md), one line per gate, is included in the change notes.

## 11. Known open items (not blockers)

- The World Map Bible still says "Oakshire Holm"; the Narrative Bible's "Embershore" is now canon.
- "What the grey is" merges the two bibles: the sap is the world's ink, its wound bleeds the Star-Tide, and the Star-Tide's touch is the Un-Inking.
- Beacon fires are left out of the film because the World Map Bible contradicts itself about their state at Lv 1.
- Final VO, score and SFX are to come; the cue ids are the contract.

---

## 12. Build notes (2026-11-09, branch `feat/opening-cinematic`)

### 12.1 Where it lives

| Piece | File |
|---|---|
| The timeline, captions and plates (copied from the handoff, unchanged) | `assets/cinematics/prologue/data/opening_cinematic_timeline.json`, `…/data/opening_cinematic.en.srt`, `…/art/storyboards/shot01…06*.png` |
| Fonts (IM FELL English Roman, Italic, SC; Alegreya Sans Regular, Bold; OFL texts) | `assets/fonts/` |
| Typed data (Gate 4) | `src/resources/cinematic_film_resource.gd`, `cinematic_shot_resource.gd`, `cinematic_effect_resource.gd`, `cinematic_caption_resource.gd`, `cinematic_cue_resource.gd` |
| The registry: every film by id, built from its JSON at first use; reads the .srt; the fonts by the timeline's names | `src/core/cinematic_catalog.gd` (`CinematicCatalog.PROLOGUE`) |
| Who sees it, when; holds; skip; recaps; RPCs; the seen flag | `src/cinematics/prologue_director.gd` (node `Prologue` under the Caldera level) |
| The film itself: shots 1–5 as pages, the dive, title card, captions, skip ring | `src/cinematics/prologue_film.gd`, `prologue_kit.gd`, `skip_ring.gd`, `storybook_plate.gdshader` |
| The late-joiner's recap | `src/cinematics/prologue_recap.gd` |
| The grey drain, now shared by the world's blight and shot 4 | `src/world/shaders/hush_drain.gdshaderinc` (included by `storybook_world_common.gdshaderinc`) |
| Checks | `tools/test_opening_cinematic.gd` (in the smoke test, before the title screen's), `tools/run_opening_cinematic_checks.gd` (alone) |

Small hooks in existing code: `InputComponent.cinematic_hold` and `is_held()` (a film holds a player; no new input action), `PlayerCamera.held_by_film()` and `look_point()` (no soft-lock swing while held), `SplitScreenViewportGrid.set_spotlight()` (one view full screen until split-screen starts), `CrossGrimoireHUD.show_ribbon_line()` / `hide_ribbon()` (the existing Chime-Post ribbon, silent), `PlayerHUD.film_released()` (quest banners that arrive during the film wait for it), `LevelBase.cinematic_playing` (F5 / F6 / F7 and F9 wait; a held seat's Start hold never leaves the party), `AudioDirector.post_cinematic_cue()` and its `cinematic_cue` signal, `PartyProgress.prologue_seen` / `has_seen_prologue()` / `mark_prologue_seen()`, `CalderaArchipelagoWorld.prologue` and `settle_streaming()`.

### 12.2 How it plays

- **Trigger.** `TitleScreen.begin_new_tale()` → `PartyProgress.begin_new_tale()` writes the new tale with an empty `[heroes] prologue_seen`. On arrival at the Lv 1 spawn (`ARRIVE_START` on Embershore), `PrologueDirector` checks the host's first seat; if that hero hasn't seen the film, it starts before the first frame is drawn (the level's own `_ready`, deferred), under the instance fade.
- **A character** is a Fellowship's hero inside a tale, the way the game already keys per-hero levels, tiers, kits and seal hands. `prologue_seen` is a per-hero flag (`{class_id: true}`). A tale saved before the film has no key, so every hero counts as having seen it; so does a launch with no save. It's set when the film or a recap finishes or is skipped, never on a quit, so a quit mid-film plays it again next time.
- **Shots 1–5** are two full-screen pages on a CanvasLayer (layer 50) drawn by `storybook_plate.gdshader`: the timeline's pan and zoom (held so the plate always covers the screen), its effects and its hand-overs. Hand-overs are centred on the shot boundary (a 0.4 s crossfade runs 4.8–5.2 s), which keeps every caption clear of them.
- **Shot 4's grey** drains through `hush_drain()`, the very function the world's blight uses, with the timeline's `#6E7880` (the world's own hush tint) at the world's 85% share.
- **Shot 6.** The page dissolves (24.5–25.5 s) into the lead player's own split-screen view, spotlit full screen. A Camera3D in that view starts at the timeline's offset (0, 30, 18) in the rig's level heading frame (x right, y world-up, z back) and eases (out-cubic, 25–29 s) to the `PlayerCamera`'s live pose, read every frame; it looks at the rig's own look point, its turn settling onto the rig's as it lands, with the rig's lens copied. At 29.0 s the rig's camera becomes current; the measured gap is 0.0 m and 0.0°. The title card inks on letter by letter at 27.0 s and fades 29.2–29.8 s. The ribbon goes up at 29.0 s on every watcher's HUD and stays until they're within 4 m of the OrchardGate or for 20 s of play (the "20" is read from the timeline's `persist_until`). Control comes back at 30.0 s, when split-screen starts.
- **Streaming.** The Caldera already loads the spawn's near window before the first frame; the mid and far jobs finish under the pages. Half a second before the dissolve, anything still on its way is finished under the still page (`settle_streaming()`); the film's clock moves at most 0.1 s a frame, so a hitch slows it rather than skipping a beat.
- **Audio.** Every cue id reaches `AudioDirector.post_cinematic_cue()` at its time and its `cinematic_cue` signal. Nothing plays. A skip posts no later cues; a hook that needs the end-state ambience on a skip listens for `PrologueDirector.film_finished`.
- **Skip.** Only the host: seat 1 here (the lowest-slot local seat), the host peer online. Holding `player_options` (Esc / Start) for 1.5 s fills the ring and jumps to the same end state as the film's own end (checked key by key), saves every watcher's flag, and gives control back at once; the skip's own press never opens the Options menu. Anyone else pressing pause sees "Host can skip". Start is also the pad's join/leave button, so a held seat's Start hold never leaves the party.
- **Couch co-op.** Everyone seated at arrival watches one film, full screen; every local seat is held. A pad joining during the film watches too.
- **Late drop-in.** A new hero who joins after the film (a local pad, or an online peer's seat) gets the recap in their own split-screen cell: the six plates, 1.5 s each, each panned the way its shot pans, with its shot's caption and a page turn between. Only that player is held; they skip it with their own 1.5 s hold.
- **Online.** The host decides everything. A remote seat whose hero is new and joins while the film plays is sent `_rpc_film_start(start_unix_msec, sent_unix_msec)` (both on the host's clock) and starts that far in, plus half the round trip. The skip is `_rpc_film_skip()`. Both are `@rpc("authority")`, and the client also checks the sender is peer 1. A remote late joiner gets `_rpc_play_recap(player_id)`; its peer reports back with `_rpc_recap_done`, which the host only accepts from that seat's own peer. While the film plays here, F5 / F6 / F7 wait.

### 12.3 Calls for the Creative Director

1. **The spawn and its framing (decided).** §7's Homestead Meadows (+128, +448) and gate (+300, +430) are in the World Map Bible's frame, which predates Embershore v2 (docs/27). Today's build already has all three things the spec asks for: the Lv 1 spawn at the orchard's south gate (`ActOnePlaces.SPAWN_AT` (-584, 182)), `POI_OrchardGate` (-586, 192), and Master Alf-Wright at the gate for Q01 (`ActOneDirector`, (-579, 188)). So no placeholders were added and the spawn stays where Act I put it. It used to face into the orchard, which left the gate and Alf behind the camera. On 2026-11-09 you chose to turn it to the gate. `EmbershoreBuilder.START_FACING` (and `ActOnePlaces.SPAWN_FACING`) is now (0.766, 0.643), south-east, picked from 1080p renders at 190–250°. In the hero's camera at the hand-off, Alf stands 0.67 of the way across (the right third's edge) and the gate spot, the foot of the stone bridge with no model of its own, sits at the right side. The grey-edged hounds of Q01 are ahead, and the World-Tree is behind, as expected: no heading here puts the gate, Alf and the World-Tree in one frame. Moving Alf a few metres west for the film would put him fully in the right third.
2. **Alf-Wright's lantern wave** isn't built: his NPC has no wave clip, and the NPC is out of scope here.
3. **The dive's start frame.** "rig_local (x right, y up, z back)" is read as the rig's level heading (y is world-up), so the dive starts 30 m up and 18 m behind. Read in the pitched camera's own axes, it would start about 35 m up and only 5 m back.

### 12.4 Placeholders and TODOs added

- `PrologueKit` holds four numbers measured on the placeholder plates, which the timeline doesn't give: the sea's surface on shot 4 (`SEA_LINE_FRAC`), the windmill's sail reach and tower and the label kept still on shot 5 (`SAIL_*`). Each has a `TODO(docs/31)` to re-measure when the final plates land. It also sets how far the open-ended effects reach (`TINT_REACH`, `MIST_REACH`, `GLOW_PEAK`).
- No world placeholders: the spawn, the OrchardGate and Alf-Wright already exist.

### 12.5 Not done, and why

- Alf-Wright's wave (§12.3 item 2). The framing goal holds only in part (§12.3 item 1).
- The 60 fps target on the target machine isn't measured here (headless checks can't). The pages are two textured quads; the 3D under them costs what normal play costs, and only the lead's view renders while it's spotlit.
- The .srt is read with `FileAccess`. It isn't a Godot resource, so an exported build would need `*.srt` in the export filter (there's no export preset yet).
- The handoff folder itself stays untracked; a `.gdignore` in it keeps Godot from importing it twice.

### 12.6 The six gates

| Gate | Verdict |
|---|---|
| 1 Anti-Parasitic Harmony | Pass: no mechanic, currency or status. The film teaches the Un-Inking with the game's own grey and hands over to the Chime-Post rhyme and Q01's calm. |
| 2 Musk Razor | Pass: no new input action. Skip is the existing `player_options` held 1.5 s; no menus. |
| 3 Philological Linter | Pass: narration, title and ribbon come verbatim from the JSON (pre-linted, §2). New on-screen words are only "Hold Esc to skip"; "Host can skip" comes from the JSON. No new proper nouns. |
| 4 Schema-First Registry | Pass: the film is typed Resources in `CinematicCatalog`, built from the JSON. No `match` on content ids in `ActorBase` or `CombatDirector`; the film's renderer switches on effect kinds, its own vocabulary. |
| 5 Code-First & Multi-Age Safe | Pass: built in GDScript at run time with no `.tscn` edits, and it hands over to the 4.8 m / 22° rig. Held heroes can't move, guard or open menus, and the assist tiers are untouched. |
| 6 70-20-10 Linguistic Linter | Pass: the only new words are plain ("Hold Esc to skip"). |

### 12.7 Run it by hand at 1080p

From `games/everwood`, once after pulling (new classes, plates and fonts): `godot --headless --path . --import`.

- **One player:** `godot --path . --resolution 1920x1080`, then New Game, a name, Begin. Watch all six shots in order with captions on time, no load screen, and no camera pop at 0:29–0:30. Walk to Alf-Wright at the orchard gate, ahead and to your right: the ribbon comes down. New Game again, then hold Esc for 1.5 s to see the skip.
- **Two-seat couch:** plug in a pad before choosing New Game. One full-screen film plays, and the screen splits at 0:30. Holding Start on the pad shows "Host can skip" and does nothing else; holding Esc on the keyboard skips.
- **Late drop-in:** after the film, press Start on another pad. Its Fellowship hasn't seen the film in this tale, so it gets the recap in its own cell while you keep playing. Hold its Start for 1.5 s to skip.
- Each New Game writes a tale to `user://saves/` (on a Mac, `~/Library/Application Support/Godot/app_userdata/Everwood/saves/`).
