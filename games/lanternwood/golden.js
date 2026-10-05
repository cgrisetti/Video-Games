// The golden ratio and the Fibonacci sequence, used to arrange the woods, hedges and painted
// hills in patterns that feel natural instead of random: the way seeds pack into a sunflower.

export const PHI = (1 + Math.sqrt(5)) / 2; // The golden ratio, about 1.618.
export const GOLDEN_ANGLE = Math.PI * (3 - Math.sqrt(5)); // About 137.5°: the turn from one sunflower seed to the next.

// The "golden sequence": the part after the decimal point of n × φ. As n counts up, these values
// spread evenly between 0 and 1, never repeating and never clumping together.
export function goldenFraction(n) {
  const value = n * PHI;
  return value - Math.floor(value);
}

// The Fibonacci word: a pattern of longs (true) and shorts (false) like L S L L S L S L L S...
// It never repeats exactly, and there are φ times as many longs as shorts.
export function fibonacciLong(k) {
  return Math.floor((k + 2) / PHI) - Math.floor((k + 1) / PHI) === 1;
}
