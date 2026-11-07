# 22_TITLE_SCREEN_AND_TALES.md — The Title Screen, New Game and Continue

Creative Director brief (2026-11-06): a design-accurate splash and starting
screen with a new "Everwood" title and branding; a New Game option that asks
for the character's name, starts a fresh Level 1 character and builds a new
save file; a Continue option that asks you to pick a previous save.

## 1. What the player sees

1. The game opens on the title (`scenes/title/title_screen.tscn`, the main scene).
2. **New Game** opens a parchment page, "A New Tale": *A youth of Oakshire
   Holm wakes among the orchards. What is your hero called?* Type a name (or
   pick **Suggest a Name**), then **Begin the Tale**. The game writes a new
   save file and walks into the Caldera Isles at the orchard lane, a Level 1
   youth wearing that name on their nameplate ("P1 · Wren").
3. **Continue** opens "Choose a Tale": every save on this machine, newest
   played first, each with its hero's name, level, Chimes and when it was last
   played ("Level 4 · 45 Chimes · played 2 hours ago"). The family's save from
   before the title screen is there too, as "The Family Tale". Pick one to play it.
   Continue is greyed out until there's a tale to continue.
4. **Quit** leaves the game.

Mouse, keyboard and pad all work: ↑/↓ choose, Enter or A selects, Escape or B
goes back. A pad player who can't type can take a suggested name.

## 2. Branding and the picture

There was no title-screen spec in the design stack, so the screen is built
from the game's own established look:

- **The wordmark** (`EverwoodWordmark`, drawn in code like the rest of the UI):
  a kicker, "A TALE OF THE CALDERA ISLES", between two Saffron-Gold rules;
  **EVERWOOD** in a letterpress serif, Saffron-Gold (#E8B64A) with a pale
  gold top edge on a deep-ink outline (#3A2818) and a warm shadow; an
  oak-sprig flourish (a rule curling at both ends, oak leaves and an acorn);
  and the line from the vision (doc 01), *The old rhymes are true.*
- **The type** is the system's serif (Iowan Old Style, Palatino, Hoefler Text,
  Baskerville, Georgia...), so the game ships no font files.
- **The menu** uses the Options menu's language: parchment text with an ink
  outline, the Saffron-Gold diamond on the chosen line, the key hints along
  the bottom. Pages are parchment (#EFE6D2) cards with ink borders and ink
  buttons ringed in gold when chosen.
- **The picture** (`TitleDiorama`) is live 3D in the Living Storybook Atelier
  look: Miller's Oak's orchard knoll at golden hour above The Sound, the
  Level 1 youth on its crest in the easy idle with the cape stirring in a sea
  breeze, the atelier apple trees and ferns, thistledown drifting in the low
  sun, and across the water The Crown and its World-Tree in the haze. The
  camera breathes slowly. The music is the orchard hamlet's acoustic suite.

## 3. Tales and save files

- `SaveSlots` (`src/core/save_slots.gd`): each New Game writes its own file in
  `user://saves/` (`<name>_<time>.cfg`); `list()` reads every tale's summary
  without writing anything; names are tidied to letters, spaces, hyphens and
  apostrophes, 16 at most.
- `PartyProgress` keeps `hero_name`, `created_unix` and `last_played_unix` in a
  new `[hero]` section of the same save file. `begin_new_tale(path, hero)`
  starts a fresh Level 1 party there and writes it at once. Older saves read
  back with no name.
- `ActorBase.display_name()`: the first hero on the host's screen wears the
  tale's name.

## 4. Build notes and deliberate differences

1. **Command-line launches skip the title.** Any game option after `--`
   (`--save=`, `--instance=`, `--players=`, `--screenshot=` ...) goes straight
   to the Caldera Isles as before, so tools, tests and `--save=` playtests are
   unchanged. `godot --path .` (or `godot --path . --`) shows the title.
2. **The family save stays where it was.** It isn't moved into the tales
   folder; Continue lists it in place, and playing it saves to it as before.
3. **One name per tale, not per player.** The name belongs to the save and is
   shown on Player 1's nameplate on the host's screen; other seats keep their
   Fellowship names.
4. **No Options entry on the title.** The in-game Options menu (Esc) still
   holds audio, video and controls.
5. **No delete.** Removing a tale is left out on purpose (a child could lose a
   save); the files are in the user data folder's `saves/` if one needs to go.
6. Checks: `tools/test_title_screen.gd`, run last by the smoke test in a scratch
   tales folder. The main-scene checks in the smoke test and
   `tools/test_caldera_isles.gd` now expect the title, whose tales start in the
   Caldera Isles.
