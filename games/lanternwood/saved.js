// Things saved in this browser between visits: the Top 10, and the music and sound settings.
// The game used to be called Coin Hop, so anything saved under its old name is moved over
// to the new one the first time it's loaded.

const PREFIX = 'lanternwood-';
const OLD_PREFIX = 'coin-hop-';

// What was saved under `name`, or null if nothing was (or this browser won't let pages save).
export function loadSaved(name) {
  try {
    const old = localStorage.getItem(OLD_PREFIX + name);
    if (old !== null && localStorage.getItem(PREFIX + name) === null) {
      localStorage.setItem(PREFIX + name, old);
      // Only clear the old copy once the new one is safely saved.
      if (localStorage.getItem(PREFIX + name) === old) localStorage.removeItem(OLD_PREFIX + name);
    }
    return JSON.parse(localStorage.getItem(PREFIX + name));
  } catch {
    return null;
  }
}

export function save(name, value) {
  try {
    localStorage.setItem(PREFIX + name, JSON.stringify(value));
  } catch {
    // Some private browsing modes block saving. Everything still works until the page closes.
  }
}
