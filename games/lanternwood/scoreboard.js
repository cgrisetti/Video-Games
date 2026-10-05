// The Top 10 boards: each game keeps its own list of fastest times, shown at the end of each
// round. They're saved in this browser, so they're still there the next time you play on this
// computer. All the boards share one storybook page on screen.

import { loadSaved, save } from './saved.js';

const BOARD_SIZE = 10;
const NAME_LENGTH = 10;

const page = document.getElementById('scoreboard');
const emblemEl = document.getElementById('scoreboard-emblem');
const titleEl = document.getElementById('scoreboard-title');
const resultEl = document.getElementById('result');
const listEl = document.getElementById('scores');
const resetButton = document.getElementById('reset-scores');

let showing = null; // The board on screen right now.

// A game's board. `saveAs` is the name it's saved under; `title` goes at the top; `emblem` is the
// little picture above it (an id from index.html); `done` and `failed` say how the round went;
// `thanks` is said once a name is written in.
export function createBoard({ saveAs, title, emblem = 'sprig', done, failed = '', thanks }) {
  const board = { saveAs, title, emblem, done, failed, thanks, scores: load(saveAs), pending: null, justSaved: null };
  return {
    // Show the board at the end of a round: `time` is how long the round took, or null if it was lost.
    show: (time) => show(board, time),
    hide: () => hide(board),
    // The fastest time on the board ({ name, time }), or null if there isn't one yet.
    best: () => board.scores[0] ?? null,
  };
}

function show(board, time) {
  showing = board;
  board.pending = null;
  board.justSaved = null;
  const { scores } = board;
  if (time === null) {
    resultEl.textContent = board.failed;
  } else if (scores.length < BOARD_SIZE || time < scores[scores.length - 1].time) {
    board.pending = { name: '', time };
    resultEl.textContent =
      scores.length === 0 || time < scores[0].time
        ? `A new fastest time: ${formatTime(time)}! Write your name in the book.`
        : `${formatTime(time)} is a Top 10 time! Write your name in the book.`;
  } else {
    resultEl.textContent = `${board.done} ${formatTime(time)}. Not quite a Top 10 time!`;
  }
  titleEl.textContent = board.title;
  emblemEl.setAttribute('href', `#${board.emblem}`);
  render();
  page.hidden = false;
  listEl.querySelector('input')?.focus();
}

// Hide the board when a new round starts. A time still waiting for its name is saved
// with whatever has been typed so far.
function hide(board) {
  savePending(board);
  if (showing === board) {
    page.hidden = true;
    showing = null;
  }
}

function savePending(board) {
  if (!board.pending) return;
  const entry = { name: board.pending.name.trim().slice(0, NAME_LENGTH) || 'Gnome', time: board.pending.time };
  board.scores.splice(rankFor(board.scores, entry.time), 0, entry);
  board.scores = board.scores.slice(0, BOARD_SIZE);
  save(board.saveAs, board.scores);
  board.pending = null;
  board.justSaved = entry;
  if (showing === board) {
    resultEl.textContent = `${board.thanks}, ${entry.name}!`;
    render();
  }
}

// Where a time would go on the board: after every time that's as fast or faster.
function rankFor(scores, time) {
  const slower = scores.findIndex((entry) => entry.time > time);
  return slower === -1 ? scores.length : slower;
}

// Draw all ten rows of the board on screen: saved times, the new time waiting for a name, and empty spots.
function render() {
  const { scores, pending, justSaved } = showing;
  const rows = [...scores];
  if (pending) rows.splice(rankFor(scores, pending.time), 0, pending);
  listEl.replaceChildren();
  for (let i = 0; i < BOARD_SIZE; i++) {
    const entry = rows[i];
    const row = document.createElement('li');
    row.append(cell('rank', i + 1));
    if (!entry) {
      row.classList.add('empty');
      row.append(cell('name', '· · ·'), cell('time', '–'));
    } else if (entry === pending) {
      row.classList.add('yours');
      row.append(nameField(), saveButton(), cell('time', formatTime(entry.time)));
    } else {
      if (entry === justSaved) row.classList.add('yours');
      row.append(cell('name', entry.name), cell('time', formatTime(entry.time)));
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

function nameField() {
  const input = document.createElement('input');
  input.type = 'text';
  input.maxLength = NAME_LENGTH;
  input.placeholder = 'Your name';
  input.setAttribute('aria-label', 'Your name, up to 10 letters');
  input.value = showing.pending.name;
  input.addEventListener('input', () => (showing.pending.name = input.value));
  input.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') savePending(showing);
  });
  return input;
}

function saveButton() {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'save';
  button.textContent = 'Save';
  button.addEventListener('click', () => savePending(showing));
  return button;
}

// The reset link asks once more before it wipes the board on screen, in case of a stray click.
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
  save(showing.saveAs, showing.scores);
  render();
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

function load(saveAs) {
  const saved = loadSaved(saveAs);
  if (!Array.isArray(saved)) return [];
  return saved.filter((entry) => typeof entry?.name === 'string' && Number.isFinite(entry?.time)).slice(0, BOARD_SIZE);
}
