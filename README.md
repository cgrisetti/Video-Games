# Video Games

3D browser games we build by describing them to Claude. Each game lives in `games/`, runs in a web browser, and uses [Three.js](https://threejs.org/) for the 3D graphics. The first game is **Lanternwood**, a woodland arcade: walk a little gnome down a lantern-lit forest path, and go through the gates along it to play games. In **Berry Rush** you pick raspberries with your fox friend while dodging (or bonking) rainbow inch worms; in the **Bramble Maze** you find your way out of a tall garden hedge maze, a new one every time. **Gnome Crossing** is Lanternwood's take on Frogger and Crossy Road: hop up an endless trail across creeks and deer trails, as far as you can, before night catches up. Play them, then change them.

## 1. What you need

- A Mac running macOS 13 (Ventura) or newer, Apple Silicon or Intel.
- A paid Claude plan (Pro or Max). Claude Code isn't on the free plan. Opus 5.5 is the default model on Pro and Max.
- About 30 minutes for the one-time setup.

## 2. One-time setup

### Install the Claude desktop app and sign in

1. Download it from <https://claude.ai/download> and drag **Claude** into **Applications**.
2. Open Claude and sign in with your Claude account (the same one you use on claude.ai).
3. Click the **Code** tab at the top. That's where you'll build the games.

### Install the developer tools

Open **Terminal** (press `Cmd+Space`, type `Terminal`, press Enter) and paste these one at a time.

Install [Homebrew](https://brew.sh), the Mac package installer. It asks for your Mac password and may install Apple's command line tools, which takes a few minutes:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

When it finishes, it prints a **Next steps** section with two or three commands to run. Run them, then close and reopen Terminal.

Install Node.js (runs the game's web server), Git (saves your work history) and the GitHub CLI (downloads this project):

```bash
brew install node git gh
```

Check they worked. Each should print a version number (Node needs to be 22.12 or newer):

```bash
node --version
git --version
gh --version
```

### Get this project onto your Mac

Sign in to GitHub (pick **GitHub.com**, **HTTPS**, and **Login with a web browser**):

```bash
gh auth login
```

Then download the project into a `Projects` folder in your home folder:

```bash
mkdir -p ~/Projects
cd ~/Projects
gh repo clone cgrisetti/Video-Games
```

### Optional: Claude Code in the terminal

Everything below works in the desktop app. If you'd rather use the terminal, install the command-line version too:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Open a new Terminal window, then run `cd ~/Projects/Video-Games` and `claude`. The first run opens your browser to sign in. Type `/model opus` to pick Opus 5.5.

## 3. Start building

1. In the Claude app's **Code** tab, start a new session (`Cmd+N`).
2. Above the prompt box, set:
   - **Environment**: Local
   - **Project folder**: `Projects/Video-Games` in your home folder
   - **Model**: Opus 5.5
   - **Permission mode**: Manual while you're learning (Claude asks before each change). Switch to **Accept edits** once you're comfortable.
3. Send your first prompt:

   > Install the dependencies, start the dev server and open Lanternwood in the preview.

   Claude runs `npm install`, starts the game server and opens the game in the app's Browser pane. Click **Play**, then: **WASD** or the arrow keys to move, **Space** to jump, **F** to swing your stick, **Esc** to pause. Walk up to a gate and press **F**, then **F** again, to go in. In Gnome Crossing, each tap of **WASD** or the arrows is one hop. A PlayStation or Xbox controller works too. The pause menu has the full controls and settings.

4. Then ask for changes and play-test after each one.

To play outside the app, run `npm run dev` in the project folder and open <http://localhost:5173> in your browser.

## 4. Prompt ideas

Changing Lanternwood:

- "Make the next game, behind the rose arbor: a mushroom-hopping race."
- "Make it slowly turn to dusk, with fireflies, and the lanterns glowing brighter as it gets dark."
- "Hide a few acorns around the woods to collect, with a counter in the pause menu."
- "Add a mushroom that makes the gnome jump twice as high for ten seconds."
- "Make the camera orbit with the mouse."
- "In Gnome Crossing, add a lane of bumblebees that zigzag across a meadow of flowers."
- "In Gnome Crossing, let me pick which hat the gnome wears, with a new hat unlocked every 50 hops."

Starting new games:

- "Make a new game: a marble that rolls through a maze by tilting the board with the arrow keys."
- "Make a new game: an endless runner where you dodge blocks on a three-lane road."
- "Make a new game: a spaceship flying through an asteroid field, shooting with Space."
- "Make a new game: a minigolf course with three holes."

Each new game gets its own folder in `games/` and a link on the launcher page.

## 5. Tips for building together

- **Take turns.** One person types the prompt, the other play-tests, then swap.
- **One idea at a time.** Small changes are easier to check and easier to undo.
- **Plan big ideas first.** Switch the permission mode to **Plan** and Claude describes its approach before changing anything.
- **Describe what you see.** "When I jump next to the wall I fall through the floor" helps more than "jumping is broken". You can also drag a screenshot into the prompt box.
- **Save when it works.** Say "commit this" and Claude saves a checkpoint with Git. "Push it" also uploads it to GitHub.
- **Undo.** Say "undo that last change", or "go back to the last commit" to throw away everything since your last save.
- **Ask why.** "Explain how the jumping works" is a good way to learn the code.
- **Watch your usage.** The ring next to the model picker shows how much of your plan's usage you've used.

## The next Lanternwood, in Godot

`games/lanternwood-godot/` is Lanternwood being rebuilt in the [Godot](https://godotengine.org) game engine, with real sunlight, soft shadows, haze, swaying grass and leafy trees. It runs as a Mac app rather than in the browser. Install Godot once with `brew install --cask godot`, then follow [its README](games/lanternwood-godot/README.md). So far it has the Glenn and the menus; the mini-games are on their way.

## Project layout

```
index.html          Launcher page that links to every game
games/lanternwood/  The first game: Lanternwood
  index.html        Page, on-screen HUD, menus and styles
  main.js           Runs the game and moves you between areas
  woods.js          The Glenn: the path with the gates to the games
  berry-rush.js     Berry Rush: pick the raspberries, dodge the inch worms
  maze.js           The Bramble Maze: find the way out of a hedge maze
  gnome-crossing.js Gnome Crossing: hopping, the night and the owl
  trail.js          Gnome Crossing's endless trail of meadows, creeks and animal trails
  critters.js       Gnome Crossing's deer, boars, hedgehogs and owl
games/lanternwood-godot/  The next Lanternwood, in the Godot engine (see its README.md)
CLAUDE.md           Instructions Claude reads about this project
.claude/launch.json Tells the Claude app how to start the preview
```
