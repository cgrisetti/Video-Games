# Video Games

A playground for building small 3D browser games together by prompting Claude. The people prompting are having fun and learning, not shipping a product: favor quick, visible progress and plain-language explanations over architecture.

## Stack

- [Three.js](https://threejs.org/docs/) for 3D, plain JavaScript (ES modules, no TypeScript, no framework).
- [Vite](https://vite.dev/) dev server. `npm install` once, then `npm run dev` and open http://localhost:5173.
- No build or deploy step yet. If someone wants to share a game online, ask before adding one.

## Layout

- `index.html` is the launcher page that links to every game.
- `games/<game-name>/` holds one game: an `index.html` (page, HUD, styles) and a `main.js` (the game). Split `main.js` into more files only once it gets hard to follow.
- `games/lanternwood/` is the first game, Lanternwood: a woodland arcade. The gnome walks a lantern-lit path (the Glenn, `woods.js`) and goes through gates into mini-games: Berry Rush (`berry-rush.js`), the Bramble Maze (`maze.js`) and Gnome Crossing (`gnome-crossing.js`, with its endless trail in `trail.js` and its animals in `critters.js`). `main.js` runs whichever area you're in. It's a good reference for the patterns below.
- To add a mini-game to Lanternwood, make it an area like `berry-rush.js`, add it to `areas` in `main.js`, give it an opening in `woods.js` (the `GAMES` and `OPENINGS` lists) and a Top 10 board in `scoreboard.js`. Things only one area shows get `data-area="<area>"` in `index.html`.

## Making a new game

1. Create `games/<kebab-case-name>/index.html` and `main.js`, following `games/lanternwood/`.
2. Add a card for it to the list in the root `index.html`.
3. Get something playable on screen first, then add features one at a time.

## Conventions

- Keep every game playable after each change. After editing, open the game in the preview, check the console for errors, and actually try the controls.
- Build visuals from Three.js primitives (boxes, spheres, cylinders) and colors unless asked for models, textures or sounds. If assets are wanted, put them in the game's folder and use only freely licensed ones.
- Put tunable numbers (speeds, counts, sizes) as named constants at the top of `main.js` so they are easy to find and tweak.
- Use frame-rate independent movement: scale by the `dt` passed to `update`.
- Show controls on screen in the HUD.
- After a change, briefly say what changed and what to try in the game. Avoid jargon or explain it.
- Commit when a feature works, with a short message describing what you can now do in the game.
