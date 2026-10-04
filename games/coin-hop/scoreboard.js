// The Top 10 board: the fastest times to pick every raspberry, shown at the end of each round.
// It's saved in this browser, so it's still there the next time you play on this computer.

const STORAGE_KEY = 'coin-hop-top-10';
const BOARD_SIZE = 10;
const NAME_LENGTH = 10;

const board = document.getElementById('scoreboard');
const resultEl = document.getElementById('result');
const listEl = document.getElementById('scores');
const resetButton = document.getElementById('reset-scores');

let scores = loadScores(); // Fastest first: [{ name, time }, ...]
let pending = null; // A new Top 10 time waiting for its name: { name, time }.
let justSaved = null; // The entry saved this round, so it can be highlighted.

// Show the board at the end of a round. `time` is how long the gnome took to pick every
// raspberry, or null if an inch worm caught it first.
export function showScoreboard(time) {
  pending = null;
  justSaved = null;
  if (time === null) {
    resultEl.textContent = 'The inch worm got you! Pick every raspberry to earn a place in the book.';
  } else if (scores.length < BOARD_SIZE || time < scores[scores.length - 1].time) {
    pending = { name: '', time };
    resultEl.textContent =
      scores.length === 0 || time < scores[0].time
        ? `A new fastest time: ${format(time)}! Write your name in the book.`
        : `${format(time)} is a Top 10 time! Write your name in the book.`;
  } else {
    resultEl.textContent = `You picked them all in ${format(time)}. Not quite a Top 10 time!`;
  }
  render();
  board.hidden = false;
  listEl.querySelector('input')?.focus();
}

// Hide the board when a new round starts. A time still waiting for its name is saved
// with whatever has been typed so far.
export function hideScoreboard() {
  savePending();
  board.hidden = true;
}

function savePending() {
  if (!pending) return;
  const entry = { name: pending.name.trim().slice(0, NAME_LENGTH) || 'Gnome', time: pending.time };
  scores.splice(rankFor(entry.time), 0, entry);
  scores = scores.slice(0, BOARD_SIZE);
  saveScores();
  pending = null;
  justSaved = entry;
  resultEl.textContent = `Well picked, ${entry.name}!`;
  render();
}

// Where a time would go on the board: after every time that's as fast or faster.
function rankFor(time) {
  const slower = scores.findIndex((entry) => entry.time > time);
  return slower === -1 ? scores.length : slower;
}

// Draw all ten rows: saved times, the new time waiting for a name, and empty spots.
function render() {
  const rows = [...scores];
  if (pending) rows.splice(rankFor(pending.time), 0, pending);
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
      row.append(nameField(), saveButton(), cell('time', format(entry.time)));
    } else {
      if (entry === justSaved) row.classList.add('yours');
      row.append(cell('name', entry.name), cell('time', format(entry.time)));
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
  input.value = pending.name;
  input.addEventListener('input', () => (pending.name = input.value));
  input.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') savePending();
  });
  return input;
}

function saveButton() {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'save';
  button.textContent = 'Save';
  button.addEventListener('click', savePending);
  return button;
}

// The reset link asks once more before it wipes the board, in case of a stray click.
let resetTimer = null;
resetButton.addEventListener('click', () => {
  if (resetTimer === null) {
    resetButton.textContent = 'Really? Click again to reset';
    resetTimer = setTimeout(endResetQuestion, 3000);
    return;
  }
  endResetQuestion();
  scores = [];
  justSaved = null;
  saveScores();
  render();
});

function endResetQuestion() {
  clearTimeout(resetTimer);
  resetTimer = null;
  resetButton.textContent = 'Reset leaderboard';
  resetButton.blur();
}

function format(time) {
  return `${time.toFixed(1)}s`;
}

function loadScores() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (!Array.isArray(saved)) return [];
    return saved.filter((entry) => typeof entry?.name === 'string' && Number.isFinite(entry?.time)).slice(0, BOARD_SIZE);
  } catch {
    return [];
  }
}

function saveScores() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(scores));
  } catch {
    // Some private browsing modes block saving. The board still works until the page is closed.
  }
}
