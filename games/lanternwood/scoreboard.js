// The Top 10 boards, one for each game, shown at the end of each round: the fastest times to
// pick every raspberry in Berry Rush and to find the way out of the Bramble Maze, and the
// farthest anyone has hopped in Gnome Crossing.
// They're saved in this browser, so they're still there the next time you play on this computer.
// Only one is ever on screen, so they share the storybook page in index.html.

import { loadSaved, save } from './saved.js';

const BOARD_SIZE = 10;
const NAME_LENGTH = 10;

const page = document.getElementById('scoreboard');
const emblemEl = document.getElementById('scoreboard-emblem');
const titleEl = document.getElementById('scoreboard-title');
const resultEl = document.getElementById('result');
const listEl = document.getElementById('scores');
const resetButton = document.getElementById('reset-scores');

let showing = null; // The board on the page right now, if any.

// One game's board. `saveAs` and `field` are where and how it's saved; `lowerIsBetter` is true
// for times (fastest first) and false for distances (farthest first); `emblem` is the little
// picture above the title (an id from index.html); `words` is what it says.
function createBoard({ saveAs, field, title, emblem = 'sprig', lowerIsBetter, format, words }) {
  return { saveAs, field, title, emblem, lowerIsBetter, format, words, scores: load(saveAs, field), pending: null, justSaved: null };
}

export const boards = {
  'berry-rush': createBoard({
    saveAs: 'top-10',
    field: 'time',
    title: 'Top 10 Raspberry Pickers',
    emblem: 'sprig',
    lowerIsBetter: true,
    format: formatTime,
    words: {
      noScore: 'The inch worm got you! Pick every raspberry to earn a place in the book.',
      newBest: (score) => `A new fastest time: ${score}! Write your name in the book.`,
      topTen: (score) => `${score} is a Top 10 time! Write your name in the book.`,
      notTopTen: (score) => `You picked them all in ${score}. Not quite a Top 10 time!`,
      saved: (name) => `Well picked, ${name}!`,
      best: (score, name) => `Best time: ${score}, by ${name}`,
      noBest: 'No best time yet. Be the first!',
    },
  }),
  'bramble-maze': createBoard({
    saveAs: 'maze-top-10',
    field: 'time',
    title: 'Top 10 Maze Escapers',
    emblem: 'key-sprig',
    lowerIsBetter: true,
    format: formatTime,
    words: {
      noScore: 'Find the way out to earn a place in the book.',
      newBest: (score) => `A new fastest time: ${score}! Write your name in the book.`,
      topTen: (score) => `${score} is a Top 10 time! Write your name in the book.`,
      notTopTen: (score) => `You found the way out in ${score}. Not quite a Top 10 time!`,
      saved: (name) => `Well found, ${name}!`,
      best: (score, name) => `Best time: ${score}, by ${name}`,
      noBest: 'No best time yet. Be the first!',
    },
  }),
  'gnome-crossing': createBoard({
    saveAs: 'gnome-crossing-top-10',
    field: 'hops',
    title: 'Top 10 Trailblazers',
    lowerIsBetter: false,
    format: (hops) => `${hops} hop${hops === 1 ? '' : 's'}`,
    words: {
      noScore: 'Hop forward to earn a place in the book.',
      newBest: (score) => `${score}: the farthest yet! Write your name in the book.`,
      topTen: (score) => `${score} is a Top 10 trip! Write your name in the book.`,
      notTopTen: (score) => `You made it ${score}. Not quite a Top 10 trip!`,
      saved: (name) => `Well hopped, ${name}!`,
      best: (score, name) => `Farthest: ${score}, by ${name}`,
      noBest: 'Nobody has crossed yet. Be the first!',
    },
  }),
};

// Show a board at the end of a round. `score` is the time or distance, or null if the round
// ended without one (an inch worm got you first). `story` is said first: how the round ended.
export function showScoreboard(board, score, story = '') {
  hideScoreboard();
  showing = board;
  board.pending = null;
  board.justSaved = null;
  const { scores, words, format } = board;
  let message;
  if (score === null || score <= 0) {
    message = words.noScore;
  } else if (scores.length < BOARD_SIZE || isBetter(board, score, scores[scores.length - 1].score)) {
    board.pending = { name: '', score };
    message = scores.length === 0 || isBetter(board, score, scores[0].score) ? words.newBest(format(score)) : words.topTen(format(score));
  } else {
    message = words.notTopTen(format(score));
  }
  titleEl.textContent = board.title;
  emblemEl.setAttribute('href', `#${board.emblem}`);
  resultEl.textContent = story ? `${story} ${message}` : message;
  render(board);
  page.hidden = false;
  listEl.querySelector('input')?.focus();
}

// Hide the board when a new round starts. A score still waiting for its name is saved
// with whatever has been typed so far.
export function hideScoreboard() {
  if (showing) savePending(showing);
  showing = null;
  page.hidden = true;
}

// The best score on a board ({ name, score }), or null if there isn't one yet.
export function bestScore(board) {
  return board.scores[0] ?? null;
}

// A line about the best score, for the game's card in the woods.
export function bestLine(board) {
  const best = bestScore(board);
  return best ? board.words.best(board.format(best.score), best.name) : board.words.noBest;
}

function isBetter(board, a, b) {
  return board.lowerIsBetter ? a < b : a > b;
}

function savePending(board) {
  if (!board.pending) return;
  const entry = { name: board.pending.name.trim().slice(0, NAME_LENGTH) || 'Gnome', score: board.pending.score };
  board.scores.splice(rankFor(board, entry.score), 0, entry);
  board.scores = board.scores.slice(0, BOARD_SIZE);
  saveScores(board);
  board.pending = null;
  board.justSaved = entry;
  resultEl.textContent = board.words.saved(entry.name);
  render(board);
}

// Where a score would go on the board: after every score that's as good or better.
function rankFor(board, score) {
  const worse = board.scores.findIndex((entry) => isBetter(board, score, entry.score));
  return worse === -1 ? board.scores.length : worse;
}

// Draw all ten rows: saved scores, the new one waiting for a name, and empty spots.
function render(board) {
  const rows = [...board.scores];
  if (board.pending) rows.splice(rankFor(board, board.pending.score), 0, board.pending);
  listEl.replaceChildren();
  for (let i = 0; i < BOARD_SIZE; i++) {
    const entry = rows[i];
    const row = document.createElement('li');
    row.append(cell('rank', i + 1));
    if (!entry) {
      row.classList.add('empty');
      row.append(cell('name', '· · ·'), cell('time', '–'));
    } else if (entry === board.pending) {
      row.classList.add('yours');
      row.append(nameField(board), saveButton(board), cell('time', board.format(entry.score)));
    } else {
      if (entry === board.justSaved) row.classList.add('yours');
      row.append(cell('name', entry.name), cell('time', board.format(entry.score)));
    }
    listEl.append(row);
  }
}

function cell(className, text) {
  const span = document.createElement('span');
  span.className = className;
  span.textContent = text;
  return span;
}

function nameField(board) {
  const input = document.createElement('input');
  input.type = 'text';
  input.maxLength = NAME_LENGTH;
  input.placeholder = 'Your name';
  input.setAttribute('aria-label', 'Your name, up to 10 letters');
  input.value = board.pending.name;
  input.addEventListener('input', () => (board.pending.name = input.value));
  input.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') savePending(board);
  });
  return input;
}

function saveButton(board) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'save';
  button.textContent = 'Save';
  button.addEventListener('click', () => savePending(board));
  return button;
}

// The reset link asks once more before it wipes the board on the page, in case of a stray click.
let resetTimer = null;
resetButton.addEventListener('click', () => {
  if (resetTimer === null) {
    resetButton.textContent = 'Really? Click again to reset';
    resetTimer = setTimeout(endResetQuestion, 3000);
    return;
  }
  endResetQuestion();
  if (!showing) return;
  showing.scores = [];
  showing.justSaved = null;
  saveScores(showing);
  render(showing);
});

function endResetQuestion() {
  clearTimeout(resetTimer);
  resetTimer = null;
  resetButton.textContent = 'Reset leaderboard';
  resetButton.blur();
}

// A time as "37.4s", or "1:23.4" once it's a minute or more.
export function formatTime(time) {
  if (time < 60) return `${time.toFixed(1)}s`;
  const tenths = Math.round(time * 10);
  const minutes = Math.floor(tenths / 600);
  return `${minutes}:${((tenths - minutes * 600) / 10).toFixed(1).padStart(4, '0')}`;
}

// Saved as [{ name, time }] for Berry Rush and the maze (as they always have been) and [{ name, hops }] for Gnome Crossing.
function load(saveAs, field) {
  const saved = loadSaved(saveAs);
  if (!Array.isArray(saved)) return [];
  return saved
    .filter((entry) => typeof entry?.name === 'string' && Number.isFinite(entry?.[field]))
    .map((entry) => ({ name: entry.name, score: entry[field] }))
    .slice(0, BOARD_SIZE);
}

function saveScores(board) {
  save(
    board.saveAs,
    board.scores.map((entry) => ({ name: entry.name, [board.field]: entry.score })),
  );
}
