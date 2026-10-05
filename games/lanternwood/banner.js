// The area title card: the name of the place you've just walked into, shown for a moment the way
// adventure games announce a new area. Berry Rush also uses it for "Ready..." and "Go!".

const card = document.getElementById('area-card');
const titleEl = document.getElementById('area-title');
const subtitleEl = document.getElementById('area-subtitle');
let hideTimer = null;

// Show the card. It fades away by itself after `seconds` (or stays, if `seconds` is 0).
export function showBanner(title, subtitle = '', seconds = 2.4) {
  titleEl.textContent = title;
  setBannerSubtitle(subtitle, seconds);
  card.classList.add('showing');
}

export function setBannerSubtitle(subtitle, seconds = 0) {
  subtitleEl.textContent = subtitle;
  subtitleEl.classList.remove('pop');
  void subtitleEl.offsetWidth; // Start its little pop-in over.
  subtitleEl.classList.add('pop');
  clearTimeout(hideTimer);
  if (seconds > 0) hideTimer = setTimeout(hideBanner, seconds * 1000);
}

export function hideBanner() {
  clearTimeout(hideTimer);
  card.classList.remove('showing');
}
