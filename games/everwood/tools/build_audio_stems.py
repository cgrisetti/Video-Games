#!/usr/bin/env python3
"""Everwood's acoustic stem and sample baker (docs/16_ADAPTIVE_AUDIO_ARCHITECTURE.md §1.1, Tier 1).

Composes every zone's suite as humanized multi-track MIDI, renders it through FluidSynth and a
General MIDI / GS SoundFont (GeneralUser GS by S. Christian Collins, free to use), and masters
it with ffmpeg and oggenc into:

  assets/audio/music/<profile_id>/stem_0_folk_base.ogg ... stem_3_skirmish_drive.ogg
      the four phase-locked stems of each zone: Vorbis q6, every stem the same length,
      seamless at the loop
  assets/audio/music/<profile_id>/score.json
      the same arrangement as notes; ProceduralChamberSynth plays it if the stems are missing
  assets/audio/music/<profile_id>/<cell_id>/stem_0_folk_base.ogg ... (the Audio Mosaics, docs/16 §7)
      a mosaic zone's twelve four-bar phrase cells, four stems each, not looping: the four bars,
      then TAIL_SEC of ringing that AudioDirector lets sound under the next cell
  assets/audio/samples/
      acoustic one-shots: instrument samples, the Four Signs' chords, the cadences and
      stingers, the stations' loops, and the musical cues AudioCues plays
  tools/audio_previews/  (git-ignored)
      each zone's exploration and full mixes as .m4a, looped twice, to listen to in Finder

then runs Godot to import them and tools/build_audio_resources.gd to write each zone's
AudioStreamSynchronized (assets/audio/music/<profile_id>_sync.tres).

  python3 tools/build_audio_stems.py                       # everything
  python3 tools/build_audio_stems.py --only honey_wick     # one suite (and no one-shots)
  python3 tools/build_audio_stems.py --no-godot            # skip the import

Needs fluidsynth, ffmpeg and oggenc (brew install fluid-synth ffmpeg vorbis-tools). The
SoundFont is fetched into tools/soundfonts/ (git-ignored) the first time. Standard library only.

The suites keep the zone ids, tempos and meters of src/core/audio_catalog.gd; the smoke test
fails if a stem's length stops matching its profile.
"""
from __future__ import annotations

import argparse
import array
import concurrent.futures
import json
import math
import random
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import urllib.request
import zlib
from fractions import Fraction
from pathlib import Path

EVERWOOD = Path(__file__).resolve().parent.parent
SOUNDFONT = EVERWOOD / "tools" / "soundfonts" / "GeneralUser-GS.sf2"
SOUNDFONT_URL = "https://raw.githubusercontent.com/mrbumpy409/GeneralUser-GS/main/GeneralUser-GS.sf2"
MUSIC = EVERWOOD / "assets" / "audio" / "music"
SAMPLES = EVERWOOD / "assets" / "audio" / "samples"
PREVIEWS = EVERWOOD / "tools" / "audio_previews"

RATE = 44100
PPQ = 480
STEM_FILES = ["stem_0_folk_base", "stem_1_pastoral_lead", "stem_2_holloway_discord", "stem_3_skirmish_drive"]
# Each stem's integrated loudness (LUFS): the lead sits 2 LU over the others.
STEM_LUFS = [-19.0, -17.0, -19.0, -19.0]
LOOP_LUFS = -21.0
TRUE_PEAK = -1.5
STINGER_PEAK_DB = -2.0
SAMPLE_PEAK_DB = -3.0
CUE_PEAK_DB = -4.0
# Humanizing: every note lands up to 8 ms early or late.
JITTER_SEC = 0.008
STACCATO = 0.45
LEGATO = 1.02
# The key the Sign chords and cadences are baked in; AudioDirector re-pitches them to the zone's tonic.
BAKED_TONIC = 67
# Samples crossfaded at each loop's seam (fluidsynth's 64-sample blocks land differently each cycle).
SEAM_FADE = 2048
OGG_QUALITY = "6"
# A mosaic's cells by stem: the folk base and lead at q5, the rarely heard discord and drive at q3
# (they sit under the others), which keeps both mosaics near 11 MB.
MOSAIC_OGG_QUALITY = ["5", "5", "3", "3"]
OGG_SERIAL = "1916"
FLUID_SETTINGS = {
    # GeneralUser GS's recommended effects (documentation §3.0.2).
    "synth.reverb.room-size": 0.5, "synth.reverb.damp": 0.3, "synth.reverb.width": 0.8, "synth.reverb.level": 0.7,
    "synth.chorus.depth": 3.6, "synth.chorus.level": 0.55, "synth.chorus.nr": 4, "synth.chorus.speed": 0.36,
    "synth.polyphony": 512, "synth.midi-bank-select": "gs",
}


# --- Instruments ---------------------------------------------------------------------

class Inst:
    """A SoundFont preset and how it is played (docs/16 §2.2)."""

    def __init__(self, bank: int, program: int, voice: str, legato: bool = False, pan: int = 64, reverb: int = 56,
                 chorus: int = 20, vibrato: bool = False, drum: bool = False) -> None:
        self.bank = bank
        self.program = program
        # The ProceduralChamberSynth voice that plays this part when the stems are missing.
        self.voice = voice
        self.legato = legato
        self.pan = pan
        self.reverb = reverb
        self.chorus = chorus
        self.vibrato = vibrato
        self.drum = drum


INSTRUMENTS = {
    "bassoon": Inst(0, 70, "REED", pan=50),
    "bassoon_legato": Inst(0, 70, "REED", legato=True, pan=50, reverb=60),
    "oboe": Inst(0, 68, "OBOE", legato=True, pan=78, reverb=64, vibrato=True),
    "english_horn": Inst(0, 69, "OBOE", legato=True, pan=70, reverb=64, vibrato=True),
    "accordion": Inst(8, 21, "ACCORDION", legato=True, pan=54, reverb=58, chorus=30),
    "violin": Inst(0, 40, "VIOLIN", legato=True, pan=84, reverb=66, vibrato=True),
    "fiddle": Inst(0, 110, "VIOLIN", pan=80, reverb=50),
    "cello": Inst(0, 42, "VIOLIN", legato=True, pan=44, reverb=60, vibrato=True),
    "cello_stab": Inst(0, 42, "VIOLIN", pan=44, reverb=48),
    "tremolo": Inst(0, 44, "VIOLIN", legato=True, pan=46, reverb=64),
    "pizz": Inst(0, 45, "PIZZ", pan=58, reverb=44),
    "harp": Inst(0, 46, "HARP", pan=88, reverb=62, chorus=10),
    "guitar": Inst(0, 24, "PLUCK", pan=38, reverb=46),
    "mandolin": Inst(16, 25, "MANDOLIN", pan=86, reverb=46),
    "recorder": Inst(0, 74, "WHISTLE", legato=True, pan=70, reverb=62),
    "flute": Inst(0, 73, "WHISTLE", legato=True, pan=72, reverb=68),
    "whistle": Inst(24, 75, "WHISTLE", legato=True, pan=72, reverb=60),
    "dulcimer": Inst(0, 15, "DULCIMER", pan=76, reverb=50),
    "tubular": Inst(0, 14, "BELL", pan=60, reverb=70),
    "carillon": Inst(9, 14, "BELL", pan=66, reverb=72),
    "church_bell": Inst(8, 14, "BELL", pan=64, reverb=72),
    "celesta": Inst(0, 8, "BELL", pan=80, reverb=66),
    "glock": Inst(0, 9, "BELL", pan=76, reverb=64),
    # The GS Room kit on channel 10: the bodhran is its toms, its rim and a tambourine.
    "drums": Inst(0, 8, "DRUM", pan=64, reverb=40, drum=True),
}

BOOM, BOOM_HI, TIP, TIP_HI, RIM, TAMB, KICK = 41, 43, 45, 47, 37, 54, 35


# --- Notes and chords ----------------------------------------------------------------

NOTE_RE = re.compile(r"^([A-G])([#b]?)(-?\d)$")
LETTERS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
ACCIDENTALS = {"#": 1, "b": -1, "": 0}


def n(name: str) -> int:
    """A note name as MIDI (C4 = 60)."""
    match = NOTE_RE.match(name)
    if match is None:
        raise ValueError("not a note: %r" % name)
    return LETTERS[match.group(1)] + ACCIDENTALS[match.group(2)] + 12 * (int(match.group(3)) + 1)


def pitch_class(name: str) -> int:
    return (LETTERS[name[0]] + ACCIDENTALS[name[1:]]) % 12


QUALITIES = {
    "": [0, 4, 7], "m": [0, 3, 7], "5": [0, 7], "sus2": [0, 2, 7], "sus4": [0, 5, 7], "add9": [0, 4, 7, 14],
    "6": [0, 4, 7, 9], "m6": [0, 3, 7, 9], "7": [0, 4, 7, 10], "maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10],
    "m9": [0, 3, 7, 10, 14], "maj9": [0, 4, 7, 11, 14], "9": [0, 4, 7, 10, 14], "13": [0, 4, 7, 10, 14, 21],
    "7b9": [0, 4, 7, 10, 13], "mM7": [0, 3, 7, 11], "dim7": [0, 3, 6, 9], "7sus4": [0, 5, 7, 10],
    "6sus4": [0, 5, 7, 9], "9sus4": [0, 5, 7, 10, 14], "maj7#11": [0, 4, 7, 11, 18], "maj9#11": [0, 4, 7, 11, 14, 18],
}
CHORD_RE = re.compile(r"^([A-G][#b]?)([^/]*)(?:/([A-G][#b]?))?$")


class Chord:
    """A chord symbol ("Cmaj7", "D/C", "B7b9") and the voicings the patterns draw from it."""

    def __init__(self, symbol: str) -> None:
        match = CHORD_RE.match(symbol)
        if match is None or match.group(2) not in QUALITIES:
            raise ValueError("not a chord: %r" % symbol)
        self.symbol = symbol
        self.root = pitch_class(match.group(1))
        self.intervals = QUALITIES[match.group(2)]
        self.bass_pc = pitch_class(match.group(3)) if match.group(3) else self.root
        self.pcs = sorted({(self.root + step) % 12 for step in self.intervals})

    def near(self, pc: int, low: int) -> int:
        """The lowest pitch of class `pc` at or above `low`."""
        return low + (pc - low) % 12

    def bass(self, low: int = 40) -> int:
        return self.near(self.bass_pc, low)

    def root_at(self, low: int) -> int:
        return self.near(self.root, low)

    def fifth(self) -> int:
        for step in (7, 6, 8):
            if step in self.intervals:
                return step
        return 7

    def arp(self, low: int, count: int, pcs: list[int] | None = None) -> list[int]:
        """`count` chord tones climbing from `low`."""
        wanted = pcs if pcs is not None else self.pcs
        notes: list[int] = []
        pitch = low
        while len(notes) < count:
            if pitch % 12 in wanted:
                notes.append(pitch)
            pitch += 1
        return notes

    def upper(self, low: int, count: int) -> list[int]:
        """A close upper-structure voicing: the root left to the bass, then the fifth if there's no room."""
        colour = [pc for pc in self.pcs if pc != self.root]
        fifth = (self.root + 7) % 12
        if len(colour) > count and fifth in colour:
            colour.remove(fifth)
        if len(colour) < count:
            colour = list(self.pcs)
        return self.arp(low, count, colour)

    def scale(self, mode: list[int]) -> list[int]:
        """The mode bent to fit this chord: a chord tone outside it pushes out its neighbours a semitone away."""
        pcs = set(mode)
        for pc in self.pcs:
            if pc not in pcs:
                pcs.discard((pc + 1) % 12)
                pcs.discard((pc - 1) % 12)
                pcs.add(pc)
        return sorted(pcs)


def mode(tonic: str, steps: list[int]) -> list[int]:
    root = pitch_class(tonic)
    return sorted({(root + step) % 12 for step in steps})


IONIAN = [0, 2, 4, 5, 7, 9, 11]
LYDIAN = [0, 2, 4, 6, 7, 9, 11]
DORIAN = [0, 2, 3, 5, 7, 9, 10]
MIXOLYDIAN = [0, 2, 4, 5, 7, 9, 10]
AEOLIAN = [0, 2, 3, 5, 7, 8, 10]
HARMONIC_MINOR = [0, 2, 3, 5, 7, 8, 11]


# --- Parts, suites and one-shots ------------------------------------------------------

class Part:
    """One instrument's notes in one stem, in quarter-note beats."""

    def __init__(self, owner: "Piece", inst: str, volume: int, seed: int) -> None:
        self.owner = owner
        self.name = inst
        self.inst = INSTRUMENTS[inst]
        self.volume = volume
        self.rng = random.Random(seed)
        self.notes: list[dict] = []

    def note(self, start: float, beats: float, pitch: int, vel: int, gate: float | None = None, strum: int = 0) -> dict:
        if gate is None:
            gate = LEGATO if self.inst.legato else 0.9
        jitter = self.rng.uniform(-1.0, 1.0) * JITTER_SEC * self.owner.bpm / 60.0 if self.owner.humanize else 0.0
        vel = int(max(1, min(127, vel + (self.rng.randint(-4, 4) if self.owner.humanize else 0))))
        made = {"start": start, "beats": beats, "pitch": pitch, "vel": vel, "gate": gate,
                "jitter": jitter + strum * 0.018 * self.owner.bpm / 60.0}
        self.notes.append(made)
        return made


class Piece:
    """Anything rendered through FluidSynth: a looping suite or a one-shot."""

    humanize = True

    def __init__(self, bpm: float, meter: str) -> None:
        self.bpm = bpm
        self.meter = meter
        self.beats = {"3/4": 3, "6/8": 3, "4/4": 4}[meter]

    def _seed(self, label: str) -> int:
        return zlib.crc32(label.encode())


class Suite(Piece):
    """A zone's four-stem score: one chord per bar shared by every stem, so any mix of layers agrees."""

    def __init__(self, profile_id: str, bpm: float, meter: str, chords: list[str], key: list[int],
                 explore_db: list[float]) -> None:
        super().__init__(bpm, meter)
        self.profile_id = profile_id
        self.chords = [Chord(symbol) for symbol in chords]
        self.bars = len(self.chords)
        self.key = key
        self.explore_db = explore_db
        self.stems: list[list[Part]] = [[], [], [], []]

    def part(self, stem: int, inst: str, volume: int = 100) -> Part:
        made = Part(self, inst, volume, self._seed("%s:%d:%s:%d" % (self.profile_id, stem, inst, len(self.stems[stem]))))
        self.stems[stem].append(made)
        return made

    def each_bar(self, chords: list[Chord] | None = None):
        for index, chord in enumerate(chords or self.chords):
            yield index, index * self.beats, chord

    @property
    def loop_beats(self) -> float:
        return self.bars * self.beats


class Shot(Piece):
    """A one-shot (a stinger, a sample, a cue) or a short station loop. At 60 BPM a beat is a second."""

    humanize = False

    def __init__(self, name: str, kind: str, stereo: bool = True, loop_sec: float = 0.0) -> None:
        super().__init__(60.0, "4/4")
        self.name = name
        self.kind = kind
        self.stereo = stereo
        self.loop_sec = loop_sec
        self.parts: list[Part] = []

    def part(self, inst: str, volume: int = 100) -> Part:
        made = Part(self, inst, volume, self._seed("%s:%s:%d" % (self.name, inst, len(self.parts))))
        self.parts.append(made)
        return made


FRACTION_RE = re.compile(r"^(.+?):(\d*\.?\d+(?:/\d+)?)([.>]*)$")


def line(part: Part, bar: int, text: str, vel: int = 84, gate: float | None = None) -> None:
    """A written line from bar `bar` (1-based). Tokens are NOTE:BEATS ("F#5:1.5"), "r:1" for a rest,
    "+:1" to tie onto the last note, "~A5" for a 32nd-note grace before the next note; a "." after
    the beats plays it staccato and ">" accents it. Bar lines ("|") must each hold one full bar."""
    suite = part.owner
    at = (bar - 1) * suite.beats
    graces: list[int] = []
    last: dict | None = None
    for offset, segment in enumerate(text.split("|")):
        if not segment.strip():
            continue
        segment_start = at
        for token in segment.split():
            if token.startswith("~"):
                graces.append(n(token[1:]))
                continue
            match = FRACTION_RE.match(token)
            if match is None:
                raise ValueError("%s bar %d: can't read %r" % (part.name, bar + offset, token))
            name, beats, flags = match.group(1), float(Fraction(match.group(2))), match.group(3)
            if name == "r":
                last = None
            elif name == "+":
                if last is None:
                    raise ValueError("%s bar %d: a tie with nothing before it" % (part.name, bar + offset))
                last["beats"] += beats
            else:
                downbeat = abs(at - round(at / suite.beats) * suite.beats) < 1e-6
                accent = (6 if downbeat else 0) + (12 if ">" in flags else 0)
                for step, grace in enumerate(reversed(graces)):
                    part.note(at - 0.125 * (step + 1), 0.11, grace, vel - 12, gate=1.0)
                graces = []
                last = part.note(at, beats, n(name), vel + accent, gate=STACCATO if "." in flags else gate)
            at += beats
        if abs((at - segment_start) - suite.beats) > 1e-6:
            raise ValueError("%s bar %d holds %.3f beats, not %d" % (part.name, bar + offset, at - segment_start, suite.beats))


# --- Patterns (docs/16 §2.1, §3) -----------------------------------------------------

def oompah(s: Suite, harp_turns: int = 4, bassoon: bool = True) -> None:
    """The Hisaishi waltz engine: beat 1 a crisp pizzicato root with a staccato bassoon, beats 2 and 3
    snappy mandolin, guitar and pizzicato viola chords, and a harp turn every few bars."""
    bass = s.part(0, "pizz", 104)
    reed = s.part(0, "bassoon", 82) if bassoon else None
    mandolin = s.part(0, "mandolin", 90)
    guitar = s.part(0, "guitar", 94)
    viola = s.part(0, "pizz", 80)
    harp = s.part(0, "harp", 92)
    for index, at, chord in s.each_bar():
        root = chord.bass(40)
        bass.note(at, 1, root, 98, gate=STACCATO)
        if reed is not None:
            reed.note(at, 1, chord.bass(48), 70, gate=0.4)
        if index % 2 == 1:
            bass.note(at + 2, 1, root + chord.fifth() if chord.bass_pc == chord.root else root, 70, gate=STACCATO)
        for beat in (1, 2):
            vel = 76 if beat == 1 else 66
            for strum, pitch in enumerate(chord.upper(66, 3)):
                mandolin.note(at + beat, 1, pitch, vel, gate=0.3, strum=strum)
            for strum, pitch in enumerate(chord.upper(55, 3)):
                guitar.note(at + beat, 1, pitch, vel - 8, gate=0.4, strum=strum)
            for pitch in chord.upper(60, 2):
                viola.note(at + beat, 1, pitch, vel - 12, gate=0.35)
        if harp_turns and (index + 1) % harp_turns == 0:
            for step, pitch in enumerate(chord.arp(62, 8)):
                harp.note(at + 1 + step * 0.25, 0.5, pitch, 64 + step * 3, gate=1.4)


def rolling_sixths(s: Suite) -> None:
    """The 6/8 pastoral sway: fingerpicked guitar rolling root, fifth, tenth, ninth, octave, fifth,
    pizzicato cello on beats 1 and 4, and a harp arpeggio answering every other bar."""
    guitar = s.part(0, "guitar", 100)
    bass = s.part(0, "pizz", 96)
    harp = s.part(0, "harp", 86)
    for index, at, chord in s.each_bar():
        root = chord.root_at(50)
        above = chord.arp(root + 13, 2)
        voicing = [root, root + chord.fifth(), root + 12, above[0], above[1]]
        for step, slot in enumerate([0, 1, 4, 3, 2, 1]):
            guitar.note(at + step * 0.5, 0.5, voicing[slot], 80 if step in (0, 3) else 64, gate=1.8)
        low = chord.bass(40)
        bass.note(at, 0.5, low, 90, gate=0.6)
        bass.note(at + 1.5, 0.5, low + 7 if (low + 7) % 12 in chord.pcs else low, 70, gate=0.6)
        if index % 2 == 1:
            for step, pitch in enumerate(chord.arp(67, 6)):
                harp.note(at + 1.5 + step * 0.25, 0.5, pitch, 60 + step * 3, gate=2.0)


def march(s: Suite) -> None:
    """The Carpathian trek: pizzicato cello on 1 and 3, a hammered dulcimer marching in fifths,
    mandolin chops on the backbeat."""
    bass = s.part(0, "pizz", 104)
    dulcimer = s.part(0, "dulcimer", 86)
    mandolin = s.part(0, "mandolin", 86)
    for index, at, chord in s.each_bar():
        low = chord.bass(40)
        fifth = chord.root_at(40) + chord.fifth()
        bass.note(at, 1, low, 100, gate=STACCATO)
        bass.note(at + 2, 1, fifth if fifth > low else fifth + 12, 86, gate=STACCATO)
        if index % 2 == 1:
            bass.note(at + 3.5, 0.5, fifth - 12 if fifth - 12 >= 38 else fifth, 74, gate=STACCATO)
        root = chord.root_at(57)
        top = root + 14 if 14 in chord.intervals or 2 in chord.intervals else root + 12
        for step, pitch in enumerate([root, root + 7, root + 12, root + 7, root, root + 7, top, root + 7]):
            dulcimer.note(at + step * 0.5, 0.5, pitch, 76 if step % 4 == 0 else 60, gate=0.9)
        for beat in (1, 3):
            for strum, pitch in enumerate(chord.upper(64, 3)):
                mandolin.note(at + beat, 0.5, pitch, 70, gate=0.35, strum=strum)


def weave(s: Suite) -> None:
    """The Arcadian Wild weave: a plucked cello pedal, guitar eighths, mandolin answering on the
    off-sixteenths, and a harp falling through the chord every other bar."""
    bass = s.part(0, "pizz", 96)
    guitar = s.part(0, "guitar", 96)
    mandolin = s.part(0, "mandolin", 78)
    harp = s.part(0, "harp", 84)
    for index, at, chord in s.each_bar():
        low = chord.bass(40)
        bass.note(at, 1, low, 92, gate=0.55)
        if index % 2 == 1:
            bass.note(at + 2, 1, low, 64, gate=0.4)
        tones = chord.arp(52, 5)
        for step, slot in enumerate([0, 2, 1, 3, 2, 4]):
            guitar.note(at + step * 0.5, 0.5, tones[slot], 72 if step == 0 else 58, gate=1.5)
        high = chord.arp(69, 4)
        for step, slot in enumerate([1, 0, 2, 1]):
            mandolin.note(at + 1.25 + step * 0.5, 0.25, high[slot], 56, gate=0.6)
        if index % 2 == 0:
            for step, pitch in enumerate(reversed(chord.arp(71, 3))):
                harp.note(at + step, 1, pitch, 62, gate=2.0)


def sparse_harp(s: Suite) -> None:
    """The Ring's stillness: a harp rising through the chord every other bar over a soft pizzicato
    pedal, and a lone harmonic in between."""
    harp = s.part(0, "harp", 92)
    bass = s.part(0, "pizz", 84)
    for index, at, chord in s.each_bar():
        if index % 2 == 0:
            for step, pitch in enumerate(chord.arp(50, 6)):
                harp.note(at + step * 0.5, 0.5, pitch, 56 + step * 3, gate=4.0)
            bass.note(at, 1, chord.bass(38), 70, gate=0.7)
        else:
            harp.note(at + 1, 1, chord.arp(76, 1)[0], 48, gate=3.0)


def bodhran(drums: Part, at: float, meter: str, index: int, scale: float = 1.0) -> None:
    """A warm frame-drum pattern: deep "boom" toms, lighter tips, a 16th gallop every other bar."""
    if meter == "6/8":
        hits = [(0, BOOM, 104), (0.5, TIP, 54), (1, TIP, 62), (1.5, BOOM_HI, 88), (2, TIP, 54), (2.5, TIP_HI, 66), (1, TAMB, 40)]
        if index % 2:
            hits += [(2.75, TIP, 50)]
    elif meter == "3/4":
        hits = [(0, BOOM, 104), (0.5, TIP, 52), (1, BOOM_HI, 80), (1.5, TIP, 56), (2, BOOM_HI, 80), (2.5, TIP_HI, 62),
                (1, TAMB, 38), (2, TAMB, 38)]
        if index % 2:
            hits += [(2.75, TIP, 48)]
    else:
        hits = [(0, BOOM, 104), (0.5, TIP, 50), (1, TIP_HI, 68), (1.5, TIP, 50), (2, BOOM_HI, 90), (2.5, TIP, 50),
                (3, TIP_HI, 68), (3.5, TIP, 56), (1, TAMB, 40), (3, TAMB, 40)]
        if index % 2:
            hits += [(3.75, TIP, 50), (3.25, RIM, 44)]
    for offset, key, vel in hits:
        drums.note(at + offset, 0.25, key, int(vel * scale), gate=1.0)


def run_notes(chord: Chord, key: list[int], low: int, count: int) -> list[int]:
    """A scale run up and back down from the chord's root, the scale bent to the chord."""
    pcs = chord.scale(key)
    start = chord.root_at(low)
    climb: list[int] = []
    pitch = start
    while len(climb) < (count + 1) // 2 + 1:
        if pitch % 12 in pcs:
            climb.append(pitch)
        pitch += 1
    return (climb + climb[-2::-1])[:count]


def skirmish(s: Suite, fiddle: bool = True) -> None:
    """The Skirmish Drive: bodhran, a hammered-dulcimer 16th ostinato, mandolin chops, staccato
    bassoon stabs and fiddle runs (docs/16 §3)."""
    drums = s.part(3, "drums", 110)
    dulcimer = s.part(3, "dulcimer", 92)
    mandolin = s.part(3, "mandolin", 80)
    reed = s.part(3, "bassoon", 96)
    bow = s.part(3, "fiddle", 84) if fiddle else None
    group = 3 if s.meter == "6/8" else 2
    sixteenths = int(s.beats * 4)
    for index, at, chord in s.each_bar():
        bodhran(drums, at, s.meter, index)
        tones = chord.arp(62, 4)
        shape = [0, 1, 2, 3, 2, 1]
        for step in range(sixteenths):
            dulcimer.note(at + step * 0.25, 0.25, tones[shape[step % len(shape)]], 74 if step % (group * 2) == 0 else 56, gate=0.9)
        for eighth in range(int(s.beats * 2)):
            if eighth % group != 0:
                for strum, pitch in enumerate(chord.upper(67, 2)):
                    mandolin.note(at + eighth * 0.5, 0.5, pitch, 62, gate=0.3, strum=strum)
        reed.note(at, 0.5, chord.bass(40), 100, gate=0.4)
        reed.note(at + (1.5 if s.meter == "6/8" else 2.0), 0.5, chord.root_at(45) + chord.fifth(), 86, gate=0.4)
        if bow is not None and index % 2 == 1:
            # A fiddle run up and back over the bar's last two beats.
            for step, pitch in enumerate(run_notes(chord, s.key, 74, 8)):
                bow.note(at + s.beats - 2 + step * 0.25, 0.25, pitch, 70, gate=0.85)


def invention(s: Suite, high: str = "oboe", low: str = "bassoon", pads: bool = True) -> None:
    """A gentle two-part question and answer for the Holloway discord stem: one voice states a
    quirky motif (with a chromatic lower neighbour) while the other holds a countersubject, and
    they swap every bar, over wheezing accordion swells."""
    upper = s.part(2, high, 86)
    lower = s.part(2, low, 92)
    bellows = s.part(2, "accordion", 66) if pads else None
    if s.meter == "4/4":
        rhythm = [(0, 0.5), (0.5, 0.25), (0.75, 0.25), (1, 1), (2, 0.5), (2.5, 0.5), (3, 1)]
    else:
        rhythm = [(0, 0.5), (0.5, 0.25), (0.75, 0.25), (1, 0.5), (1.5, 0.5), (2, 0.5), (2.5, 0.5)]
    for index, at, chord in s.each_bar():
        pcs = chord.scale(s.key)
        lead, follow = (upper, lower) if index % 2 == 0 else (lower, upper)
        base = 64 if lead is upper else 50
        tones = chord.arp(base, 4)
        steps = [tones[0], tones[0] - 1, tones[0], tones[1], tones[2], 0, 0]
        below = [p for p in range(tones[2] - 1, tones[2] - 4, -1) if p % 12 in pcs]
        steps[5] = below[0] if below else tones[1]
        nxt = [p for p in range(steps[5] - 1, steps[5] - 4, -1) if p % 12 in pcs]
        steps[6] = nxt[0] if nxt else tones[1]
        for (offset, beats), pitch in zip(rhythm, steps):
            lead.note(at + offset, beats, pitch, 76 if offset == 0 else 66, gate=0.8)
        hold = chord.arp(50 if follow is lower else 67, 3)
        follow.note(at, s.beats - 1, hold[1], 60, gate=0.95)
        follow.note(at + s.beats - 1, 1, hold[0], 56, gate=0.9)
        if bellows is not None:
            for pitch in chord.upper(55, 3):
                bellows.note(at, s.beats * 0.85, pitch, 50, gate=1.0)


# --- The seven suites of the vale (docs/16 §3) ---------------------------------------------------

def bramble_bridge_square() -> Suite:
    """Bramble-Bridge, Chunk (0, 0): the Hisaishi flying waltz in G Lydian, 3/4 at 108, 24 bars."""
    s = Suite("bramble_bridge_square", 108.0, "3/4", [
        "Cmaj7", "D/C", "Bm7", "Em9", "Am7", "B7b9", "EmM7", "Em7",
        "Cmaj7", "D/C", "Bm7", "Em9", "A9", "A9", "D13", "D13",
        "Gmaj9#11", "Gmaj9#11", "Cmaj7", "D/C", "Bm7", "Em9", "Am7", "D13"], mode("G", LYDIAN), [0.0, 0.0, -80.0, -80.0])
    oompah(s)
    accordion = s.part(1, "accordion", 100)
    violin = s.part(1, "violin", 100)
    oboe = s.part(1, "oboe", 88)
    bassoon = s.part(1, "bassoon", 96)
    harp = s.part(1, "harp", 96)
    # Bars 1-8: the musette accordion's airborne theme over the bassoon's staccato leaps.
    line(accordion, 1, "G5:1.5 F#5:.5 E5:1 | F#5:2 A5:1 | D5:1.5 E5:.5 F#5:1 | B5:2 r:1 |"
                       "C6:1.5 B5:.5 A5:1 | F#5:1 A5:1 C6:1 | B5:2 G5:1 | E5:2 r:1", vel=90)
    line(bassoon, 1, "r:1 E3:.5 G3:.5 B3:.5 C4:.5 | D4:.5 r:.5 A3:.5 F#3:.5 D3:.5 r:.5 | B2:.5 r:.5 F#3:.5 B3:.5 D4:.5 r:.5 |"
                     "E4:.5 D4:.5 B3:.5 G3:.5 F#3:.5 E3:.5 | A2:.5 r:.5 E3:.5 r:.5 G3:.5 C4:.5 |"
                     "B2:.5 r:.5 D#3:.5 F#3:.5 A3:.5 C4:.5 | B3:.5 r:.5 D#4:.5 r:.5 B3:.5 G3:.5 |"
                     "E3:.5 F#3:.5 G3:.5 A3:.5 B3:.5 D4:.5", vel=84, gate=STACCATO)
    # Bars 9-16: the solo violin takes the theme up, the oboe a third or sixth under it.
    line(violin, 9, "G5:1.5 F#5:.5 E5:1 | F#5:2 A5:1 | D6:1.5 C#6:.5 B5:1 | F#6:2 r:1 |"
                    "E6:1.5 C#6:.5 A5:1 | B5:1 C#6:1 E6:1 | F#6:1.5 E6:.5 D6:1 | B5:2 r:1", vel=86)
    line(oboe, 9, "E5:1.5 D5:.5 C5:1 | D5:2 F#5:1 | F#5:1.5 E5:.5 D5:1 | B5:2 r:1 |"
                  "C#6:1.5 A5:.5 E5:1 | G5:1 A5:1 C#6:1 | D6:1.5 C6:.5 A5:1 | F#5:2 r:1", vel=78)
    line(bassoon, 9, "r:1 C3:.5 G3:.5 E4:.5 G3:.5 | D3:.5 r:.5 F#3:.5 A3:.5 C4:.5 A3:.5 | B2:.5 r:.5 F#3:.5 r:.5 A3:.5 F#3:.5 |"
                     "E3:.5 G3:.5 B3:.5 D4:.5 F#4:.5 r:.5 | E3:.5 B3:.5 G3:.5 F#3:.5 E3:.5 D3:.5 |"
                     "C#3:.5 B2:.5 A2:.5 r:.5 E3:.5 A3:.5 | D3:.5 r:.5 A3:.5 r:.5 C4:.5 B3:.5 |"
                     "A3:.5 F#3:.5 D3:.5 r:.5 r:1", vel=80, gate=STACCATO)
    # Bars 17-24: the whole chamber quartet in a sunlit cadence.
    line(violin, 17, "B5:1.5 A5:.5 B5:1 | C#6:2 B5:1 | E6:1.5 D6:.5 B5:1 | A5:2 F#5:1 |"
                     "D6:1.5 C#6:.5 B5:1 | G5:1 F#5:1 E5:1 | E5:1 A5:1 C6:1 | B5:2 r:1", vel=88)
    line(accordion, 17, "G5:1.5 F#5:.5 G5:1 | A5:2 G5:1 | C6:1.5 B5:.5 G5:1 | F#5:2 D5:1 |"
                        "B5:1.5 A5:.5 F#5:1 | E5:1 D5:1 B4:1 | C5:1 E5:1 A5:1 | F#5:2 r:1", vel=80)
    line(oboe, 17, "D5:3 | F#5:2 E5:1 | E5:3 | D5:1.5 E5:.5 F#5:1 | F#5:3 | G5:2 F#5:1 | E5:3 | F#5:2 r:1", vel=70)
    line(bassoon, 17, "G2:.5 r:.5 D3:.5 G3:.5 B3:.5 D4:.5 | C#4:.5 r:.5 A3:.5 F#3:.5 D3:.5 r:.5 |"
                      "C3:.5 r:.5 G3:.5 r:.5 E3:.5 G3:.5 | D3:.5 r:.5 A3:.5 r:.5 F#3:.5 A3:.5 |"
                      "B2:.5 D3:.5 F#3:.5 A3:.5 B3:.5 r:.5 | E3:.5 r:.5 B3:.5 r:.5 G3:.5 E3:.5 |"
                      "A2:.5 C3:.5 E3:.5 G3:.5 A3:.5 C4:.5 | D4:.5 r:.5 C4:.5 A3:.5 F#3:.5 D3:.5", vel=84, gate=STACCATO)
    # Two-octave Lydian harp glissandi, G4 to F#6, over the A9 and the Gmaj9(#11).
    for bar in (14, 18):
        gliss = [n(name) for name in "G4 A4 B4 C#5 D5 E5 F#5 G5 A5 B5 C#6 D6 E6 F#6".split()]
        for step, pitch in enumerate(gliss):
            harp.note((bar - 1) * 3 + 1 + step * (2.0 / len(gliss)), 0.25, pitch, 60 + step * 3, gate=4.0)
    invention(s)
    skirmish(s)
    return s


def honey_wick() -> Suite:
    """The Kindle-Fire at Honey-Wick, Chunk (0, 1): Howard Shore's pastoral warmth in G Ionian with
    C Lydian lifts, 6/8 at 108, 16 bars."""
    chords = []
    for symbol in ["Gmaj9", "Cmaj7#11", "Em7", "D6sus4", "Gadd9", "Bm7", "Cmaj9", "D13"]:
        chords += [symbol, symbol]
    s = Suite("honey_wick", 108.0, "6/8", chords, mode("G", IONIAN), [0.0, 0.0, -80.0, -80.0])
    rolling_sixths(s)
    whistle = s.part(1, "whistle", 100)
    violin = s.part(1, "violin", 88)
    bassoon = s.part(1, "bassoon", 96)
    # The tin whistle's morning tune, with 32nd-note grace flicks.
    line(whistle, 1, "~A5 B5:1 A5:.5 G5:.5 A5:.5 B5:.5 | D6:1.5 r:1.5 | E6:1 D6:.5 B5:1 A5:.5 | ~E5 F#5:1.5 r:1.5 |"
                     "G5:.5 A5:.5 B5:.5 D6:1 B5:.5 | A5:1 G5:.5 E5:1.5 | G5:1 A5:.5 B5:1 A5:.5 | G5:1.5 r:1.5 |"
                     "~A5 B5:1 A5:.5 G5:.5 A5:.5 B5:.5 | D6:1 E6:.5 D6:1.5 | ~E6 F#6:1 E6:.5 D6:1 B5:.5 | A5:1.5 r:1.5 |"
                     "~F#6 G6:1 F#6:.5 E6:1 D6:.5 | E6:1 D6:.5 B5:1.5 | A5:1 B5:.5 C6:1 B5:.5 | A5:1.5 r:1.5", vel=86)
    # The solo violin joins in sweet sixths and thirds for bars 9-16.
    line(violin, 9, "D5:1 C5:.5 B4:.5 C5:.5 D5:.5 | B5:1 C6:.5 B5:1.5 | A5:1 G5:.5 F#5:1 D5:.5 | F#5:1.5 r:1.5 |"
                    "E6:1 D6:.5 C6:1 B5:.5 | C6:1 B5:.5 G5:1.5 | F#5:1 G5:.5 A5:1 G5:.5 | F#5:1.5 r:1.5", vel=74)
    # The bassoon answers every two bars, walking up G2 A2 B2 D3 E3.
    line(bassoon, 1, "G3:.5 r:2.5 | r:1.5 G2:.5 A2:.5 B2:.5 | D3:.5 E3:1 r:1.5 | r:1.5 C3:.5 G3:.5 E3:.5 |"
                     "E3:.5 r:2.5 | E3:.5 r:1 B2:.5 r:1 | D3:.5 r:1 A2:.5 r:1 | r:1.5 D3:.5 E3:.5 G3:.5 |"
                     "A3:.5 B3:1 r:1.5 | G2:.5 r:1 D3:.5 r:1 | B2:.5 r:1 F#3:.5 r:1 | r:1.5 B2:.5 C#3:.5 D3:.5 |"
                     "E3:.5 r:2.5 | C3:.5 r:1 G2:.5 r:1 | D3:.5 r:1 A2:.5 r:1 | r:1.5 D3:.5 E3:.5 F#3:.5", vel=82, gate=STACCATO)
    # The Holloway stem here is a gentle bassoon-and-oboe question and answer.
    invention(s)
    skirmish(s)
    return s


def moss_oak_hollow() -> Suite:
    """Moss-Oak-Hollow into Rush-Light-Hollow's sunken lane, Chunk (0, -1): E Dorian over a plucked
    weave, with the Into-the-Unknown invention in E harmonic minor waiting in the discord stem.
    3/4 at 108, 16 bars."""
    s = Suite("moss_oak_hollow", 108.0, "3/4", [
        "Em9", "Em9", "Cmaj7", "Cmaj7", "Am7", "Am6", "B7sus4", "B7b9",
        "Em9", "Em9", "A9", "A9", "Cmaj7", "Am6", "B7sus4", "B7b9"], mode("E", DORIAN), [0.0, 0.0, -80.0, -80.0])
    weave(s)
    oboe = s.part(1, "oboe", 96)
    violin = s.part(1, "violin", 98)
    line(oboe, 1, "E5:1.5 F#5:.5 G5:1 | B5:2 A5:.5 G5:.5 | G5:1.5 E5:.5 D5:1 | E5:2 r:1 |"
                  "A4:1 C5:1 E5:1 | F#5:1.5 E5:.5 C5:1 | B4:1 E5:1 F#5:1 | D#5:2 r:1 |"
                  "G4:1.5 A4:.5 B4:1 | G5:2 B5:.5 G5:.5 | A5:2 G5:.5 F#5:.5 | C#5:2 r:1 |"
                  "A5:1.5 G5:.5 E5:1 | E5:1.5 C5:.5 A4:1 | A4:1 B4:1 E5:1 | B4:1 A4:1 r:1", vel=84)
    line(violin, 9, "E5:1.5 F#5:.5 G5:1 | B5:2 D6:.5 B5:.5 | C#6:2 B5:.5 A5:.5 | E5:2 r:1 |"
                    "C6:1.5 B5:.5 G5:1 | A5:1.5 F#5:.5 E5:1 | E5:1 F#5:1 A5:1 | F#5:1 D#5:1 r:1", vel=88)
    # Stem 2: the bassoon-and-oboe two-part invention in E harmonic minor, over wheezing accordion
    # bellows and a tremolo cello, intriguing rather than dark.
    reed = s.part(2, "bassoon", 100)
    lead = s.part(2, "oboe", 90)
    line(reed, 1, "E3:.5 D#3:1/4 E3:1/4 G3:.5 B3:.5 A3:.5 G3:.5 | F#3:.5 E3:.5 r:.5 B2:.5 E3:.5 r:.5 |"
                  "C3:1 B2:.5 A2:.5 G2:1 | E3:.5 G3:.5 B3:.5 C4:.5 r:1 |"
                  "A2:.5 B2:1/4 A2:1/4 C3:.5 E3:.5 D3:.5 C3:.5 | F#3:.5 E3:.5 r:.5 C3:.5 A2:.5 r:.5 |"
                  "B2:.5 r:.5 E3:.5 r:.5 F#3:.5 A3:.5 | B2:1/4 C3:1/4 B2:.5 D#3:.5 F#3:.5 A3:.5 C4:.5 |"
                  "E3:1 r:.5 B2:.5 G2:.5 r:.5 | E3:.5 D#3:1/4 E3:1/4 G3:.5 B3:.5 A3:.5 G3:.5 |"
                  "A2:.5 r:.5 E3:.5 r:.5 G3:.5 E3:.5 | A3:.5 G3:.5 E3:.5 C#3:.5 A2:1 |"
                  "C3:.5 r:.5 G3:.5 r:.5 B3:.5 G3:.5 | A2:.5 C3:.5 E3:.5 F#3:.5 A3:.5 r:.5 |"
                  "B2:.5 r:.5 F#3:.5 r:.5 E3:.5 r:.5 | B2:1/4 C3:1/4 B2:.5 D#3:.5 F#3:.5 A3:.5 C4:.5", vel=86, gate=0.6)
    line(lead, 1, "r:3 | r:3 | E5:.5 D#5:1/4 E5:1/4 G5:.5 B5:.5 A5:.5 G5:.5 | F#5:.5 E5:.5 r:.5 B4:.5 E5:.5 r:.5 |"
                  "C5:2 B4:1 | A4:.5 C5:.5 E5:.5 F#5:.5 A5:1 | B5:1.5 A5:.5 E5:1 | D#5:1 C5:1 B4:1 |"
                  "E5:.5 D#5:1/4 E5:1/4 G5:.5 B5:.5 A5:.5 G5:.5 | F#5:.5 E5:.5 r:.5 B4:.5 E5:.5 r:.5 |"
                  "B4:.5 C#5:.5 E5:1 G5:1 | F#5:2 E5:1 | E5:.5 D#5:1/4 E5:1/4 G5:.5 B5:.5 A5:.5 G5:.5 |"
                  "F#5:.5 E5:.5 r:.5 C5:.5 A4:.5 r:.5 | E5:1.5 F#5:.5 A5:1 | C6:1 B5:.5 A5:.5 F#5:.5 D#5:.5", vel=80, gate=0.85)
    bellows = s.part(2, "accordion", 70)
    tremolo = s.part(2, "tremolo", 62)
    for index, at, chord in s.each_bar():
        if chord.symbol == "B7b9":
            # The wheezing diminished bellows: the B7(b9) without its root.
            voicing = [n("D#4"), n("F#4"), n("A4"), n("C5")]
        else:
            voicing = chord.upper(55, 3)
        for pitch in voicing:
            bellows.note(at, 2.6, pitch, 50, gate=1.0)
        tremolo.note(at, 3, chord.bass(40), 46, gate=1.0)
    skirmish(s)
    return s


def dover_slap_falls() -> Suite:
    """Dover-Slap-Falls and the gorge, Chunk (0, -2): Evan Call's expedition march in A Dorian,
    4/4 at 108, 16 bars (the A Lydian fanfare comes with the gate)."""
    s = Suite("dover_slap_falls", 108.0, "4/4", [
        "Am9", "D/A", "Am9", "D/A", "Cmaj7", "G/B", "Am7", "Esus4",
        "Cmaj7", "D", "Em7", "Am7", "Cmaj7", "G/B", "Dsus4", "D"], mode("A", DORIAN), [0.0, 0.0, -80.0, -80.0])
    march(s)
    horn = s.part(1, "english_horn", 100)
    violin = s.part(1, "violin", 98)
    accordion = s.part(1, "accordion", 84)
    bassoon = s.part(1, "bassoon", 88)
    line(horn, 1, "A4:1.5 B4:.5 C5:1 E5:1 | F#5:2 E5:1 D5:1 | C5:1.5 B4:.5 A4:1 E4:1 | A4:3 r:1 |"
                  "G4:1 C5:1 E5:1.5 D5:.5 | D5:2 B4:1 G4:1 | A4:1 C5:1 E5:1 G5:1 | E5:3 r:1 |"
                  "C5:1.5 D5:.5 E5:1 C5:1 | F#5:2 D5:1 A4:1 | E5:1.5 F#5:.5 G5:2 | E5:3 r:1 |"
                  "G5:2 E5:1 C5:1 | B4:2 G4:1 D4:1 | D5:2 A4:1 C5:1 | D5:3 r:1", vel=88)
    line(violin, 9, "E5:1.5 F#5:.5 G5:1 E5:1 | A5:2 F#5:1 D5:1 | G5:1.5 A5:.5 B5:2 | A5:3 r:1 |"
                    "E6:1.5 D6:.5 C6:1 G5:1 | D6:2 B5:1 G5:1 | A5:1 G5:1 D5:1 E5:1 | F#5:3 r:1", vel=90)
    line(accordion, 1, "E4:4 | F#4:4 | E4:4 | D4:3 r:1 | B3:1 E4:1 G4:1.5 F#4:.5 | F#4:2 D4:1 B3:1 | C4:1 E4:1 G4:1 B4:1 | A4:3 r:1 |"
                       "r:4 | r:4 | r:4 | r:4 | G5:1.5 F#5:.5 E5:1 B4:1 | F#5:2 D5:1 B4:1 | C5:1 B4:1 A4:1 G4:1 | A4:3 r:1", vel=74)
    # The bassoon's counter-rhythm: off-beat leaps through each bar's chord.
    for index, at, chord in s.each_bar():
        tones = chord.arp(45, 4)
        for offset, slot in [(0.5, 0), (1.0, 1), (1.5, 2), (2.5, 1), (3.0, 0), (3.5, 3)]:
            bassoon.note(at + offset, 0.5, tones[slot], 78 if offset == 0.5 else 70, gate=STACCATO)
    invention(s, high="english_horn")
    skirmish(s)
    return s


def ring_of_the_cairnsman() -> Suite:
    """The causeway and the Ring, Chunk (0, -3): wind-swept solitude before the pull. A wooden flute,
    harp harmonics and a low bassoon pedal in D Dorian, 3/4 at 108, 16 bars."""
    s = Suite("ring_of_the_cairnsman", 108.0, "3/4", [
        "Dm9", "Dm9", "G/D", "G/D", "Fmaj7", "C", "Dm9", "Dm9",
        "Am7", "G", "Fmaj7", "Em7", "Dm9", "G/D", "Csus2", "Dm9"], mode("D", DORIAN), [-14.0, -3.0, -80.0, -80.0])
    sparse_harp(s)
    flute = s.part(1, "flute", 100)
    pedal = s.part(1, "bassoon_legato", 84)
    harmonics = s.part(1, "harp", 70)
    line(flute, 1, "A5:2 G5:.5 F5:.5 | E5:2 r:1 | D5:1 G5:1 B5:1 | A5:2 r:1 | C6:1.5 A5:.5 F5:1 | G5:2 E5:1 | F5:1 E5:1 D5:1 | D5:2 r:1 |"
                   "E5:1.5 G5:.5 A5:1 | B5:2 D6:1 | C6:2 A5:1 | G5:2 r:1 | A5:1.5 G5:.5 F5:1 | B5:2 A5:1 | G5:1.5 D5:1.5 | E5:2 r:1", vel=80)
    for index, at, chord in s.each_bar():
        if index % 2 == 0:
            pedal.note(at, 5.6, chord.bass(36), 56, gate=1.0)
            harmonics.note(at + 1.5, 1, chord.arp(81, 1)[0], 44, gate=3.0)
    invention(s, high="english_horn", pads=False)
    skirmish(s, fiddle=False)
    return s


def cairnsmans_vigil() -> Suite:
    """The Cairnsman's raid suite: a Zoltraak chamber gallop on a D pedal, 6/8 at 132, 16 bars.
    Stem 0 and the percussion keep to roots, fifths and ninths, so Stem 1 (the D Lydian triumph,
    up only in the Poise-Stagger window) and Stem 2 (Phase 2's D harmonic-minor counterpoint) can
    each sit on top of them."""
    pedal = ["D5", "D5", "D5", "D5", "D5", "D5", "A5", "A5"] * 2
    s = Suite("cairnsmans_vigil", 132.0, "6/8", pedal, mode("D", DORIAN), [0.0, -80.0, -6.0, 0.0])
    dulcimer = s.part(0, "dulcimer", 96)
    mandolin = s.part(0, "mandolin", 74)
    fiddle = s.part(0, "fiddle", 86)
    stabs = s.part(0, "cello_stab", 100)
    for index, at, chord in s.each_bar():
        root = chord.root_at(62)
        for step, pitch in enumerate([root, root + 7, root + 12, root + 14, root + 12, root + 7]):
            dulcimer.note(at + step * 0.5, 0.5, pitch, 84 if step in (0, 3) else 64, gate=0.85)
        for step in range(12):
            mandolin.note(at + step * 0.25, 0.25, root + (12 if step % 2 == 0 else 7), 58 if step % 3 == 0 else 48, gate=0.8)
        if index % 2 == 1:
            for step, rel in enumerate([12, 14, 19, 21, 24, 21, 19, 14, 12, 9, 7, 9]):
                fiddle.note(at + step * 0.25, 0.25, root + rel, 72, gate=0.85)
        low = chord.bass(38)
        stabs.note(at, 0.5, low, 104, gate=0.35)
        stabs.note(at + 1.5, 0.5, low + 7, 90, gate=0.35)
        if index % 2 == 1:
            stabs.note(at + 2.5, 0.5, low, 84, gate=0.35)
    # Stem 1: the D Lydian triumph (D, then E over D: the Lydian lift), on harp, accordion and carillon.
    lift = [Chord(symbol) for symbol in ["D", "E/D", "D", "E/D", "D", "E/D", "A", "A"] * 2]
    harp = s.part(1, "harp", 100)
    accordion = s.part(1, "accordion", 92)
    bells = s.part(1, "carillon", 86)
    for index, at, chord in s.each_bar(lift):
        for step, pitch in enumerate(chord.arp(62, 12, [(chord.root + i) % 12 for i in (0, 4, 7)])):
            harp.note(at + step * 0.25, 0.25, pitch, 62 + (step % 6) * 4, gate=2.0)
        for pitch in chord.arp(66, 3, [(chord.root + i) % 12 for i in (0, 4, 7)]):
            accordion.note(at, 3, pitch, 80, gate=1.0)
        if index % 2 == 0:
            bells.note(at, 1.5, chord.root_at(74), 84, gate=2.0)
    # Stem 2: Phase 2's double-time oboe, accordion stabs and high violin in D harmonic minor.
    minor = [Chord(symbol) for symbol in ["Dm", "Dm", "Bb/D", "Bb/D", "Gm/D", "Gm/D", "A7", "A7b9"] * 2]
    oboe = s.part(2, "oboe", 98)
    line(oboe, 1, "D5:.5 F5:.5 A5:.5 G5:.5 F5:.5 E5:.5 | F5:1 E5:.5 D5:1 C#5:.5 | D5:.5 F5:.5 Bb5:.5 A5:.5 G5:.5 F5:.5 | G5:1 F5:.5 D5:1.5 |"
                  "Bb5:.5 A5:.5 G5:.5 D5:.5 G5:.5 Bb5:.5 | A5:1 G5:.5 F5:1 E5:.5 | E5:.5 C#5:.5 E5:.5 G5:.5 A5:.5 G5:.5 | Bb5:1 A5:.5 G5:.5 F5:.5 E5:.5 |"
                  "D6:.5 C#6:.5 D6:.5 A5:.5 F5:.5 D5:.5 | F5:1 G5:.5 A5:1.5 | Bb5:.5 A5:.5 Bb5:.5 F5:.5 D5:.5 F5:.5 | G5:1 A5:.5 Bb5:1.5 |"
                  "D6:.5 Bb5:.5 G5:.5 A5:.5 Bb5:.5 D6:.5 | Bb5:1 A5:.5 G5:1.5 | A5:.5 G5:.5 F5:.5 E5:.5 C#5:.5 E5:.5 | G5:1 F5:.5 E5:1 C#5:.5", vel=88, gate=0.8)
    squeeze = s.part(2, "accordion", 78)
    high = s.part(2, "violin", 74)
    for index, at, chord in s.each_bar(minor):
        for offset in (0, 1.5):
            for pitch in chord.upper(57, 3):
                squeeze.note(at + offset, 0.5, pitch, 70, gate=0.6)
        if index >= 8:
            for step, pitch in enumerate(chord.arp(74, 6) + chord.arp(74, 6)[::-1]):
                high.note(at + step * 0.25, 0.25, pitch, 58, gate=0.9)
    # Stem 3: the bodhran gallop under bassoon and cello stabs.
    drums = s.part(3, "drums", 112)
    reed = s.part(3, "bassoon", 100)
    for index, at, chord in s.each_bar():
        bodhran(drums, at, "6/8", index)
        drums.note(at + 2.75, 0.25, TIP, 52, gate=1.0)
        reed.note(at, 0.5, chord.bass(38), 104, gate=0.35)
        reed.note(at + 1.5, 0.5, chord.bass(38) + 7, 92, gate=0.35)
    return s


def oakshire_vale() -> Suite:
    """Oakshire Holm, where every launch begins: a bright F Lydian waltz, 3/4 at 104, 16 bars,
    turning home through an F major cadence."""
    s = Suite("oakshire_vale", 104.0, "3/4", [
        "Fmaj7", "G/F", "Fmaj7", "G/F", "Em7", "Am7", "Dm7", "G7",
        "Fmaj7", "G/F", "Em7", "A7", "Dm9", "Gm7", "C9sus4", "C7"], mode("F", LYDIAN), [0.0, 0.0, -80.0, -80.0])
    oompah(s)
    accordion = s.part(1, "accordion", 100)
    violin = s.part(1, "violin", 100)
    oboe = s.part(1, "oboe", 86)
    bassoon = s.part(1, "bassoon", 96)
    harp = s.part(1, "harp", 94)
    line(accordion, 1, "C5:1 F5:1 A5:1 | B5:2 A5:.5 G5:.5 | A5:.5 G5:.5 F5:1 C5:1 | D5:2 r:1 |"
                       "E5:1 G5:1 B5:1 | C6:2 B5:.5 A5:.5 | A5:1.5 G5:.5 F5:1 | B4:2 r:1", vel=90)
    line(violin, 9, "C5:1 F5:1 A5:1 | B5:2 C6:.5 D6:.5 | E6:1.5 D6:.5 B5:1 | C#6:2 A5:1 |"
                    "D6:1 E6:1 F6:1 | D6:1.5 Bb5:.5 G5:1 | C6:1.5 Bb5:.5 G5:1 | E5:2 r:1", vel=88)
    line(oboe, 9, "A4:1 C5:1 F5:1 | G5:2 A5:.5 B5:.5 | B5:1.5 G5:.5 E5:1 | A5:2 E5:1 |"
                  "A5:1 C6:1 D6:1 | Bb5:1.5 G5:.5 D5:1 | G5:1.5 F5:.5 D5:1 | C5:2 r:1", vel=76)
    line(bassoon, 1, "r:1 F3:.5 A3:.5 C4:.5 E4:.5 | D4:.5 r:.5 B3:.5 G3:.5 D3:.5 r:.5 | F3:.5 r:.5 C3:.5 r:.5 A3:.5 F3:.5 |"
                     "G3:.5 A3:.5 B3:.5 D4:.5 G4:.5 r:.5 | E3:.5 r:.5 B3:.5 r:.5 G3:.5 E3:.5 | A2:.5 C3:.5 E3:.5 G3:.5 A3:.5 r:.5 |"
                     "D3:.5 r:.5 A3:.5 F3:.5 D3:.5 C3:.5 | B2:.5 D3:.5 F3:.5 G3:.5 B3:.5 D4:.5 |"
                     "F3:.5 r:.5 C4:.5 r:1.5 | G3:.5 r:.5 D4:.5 r:.5 B3:.5 r:.5 | E3:.5 r:.5 G3:.5 r:.5 B3:.5 r:.5 |"
                     "A2:.5 r:.5 C#3:.5 E3:.5 G3:.5 r:.5 | D3:.5 F3:.5 A3:.5 C4:.5 E4:.5 r:.5 | G2:.5 r:.5 D3:.5 r:.5 Bb3:.5 G3:.5 |"
                     "C3:.5 r:.5 G3:.5 r:.5 Bb3:.5 F3:.5 | C3:.5 E3:.5 G3:.5 Bb3:.5 C4:.5 E4:.5", vel=84, gate=STACCATO)
    # F Lydian glissandi, F4 to E6, over G/F.
    for bar in (2, 10):
        gliss = [n(name) for name in "F4 G4 A4 B4 C5 D5 E5 F5 G5 A5 B5 C6 D6 E6".split()]
        for step, pitch in enumerate(gliss):
            harp.note((bar - 1) * 3 + 1 + step * (2.0 / len(gliss)), 0.25, pitch, 58 + step * 3, gate=4.0)
    invention(s)
    skirmish(s)
    return s


# --- The Crown's five suites (docs/23 §7) ------------------------------------------------
#
# One island, one key signature, five modes: every suite keeps to the notes of D major (two
# sharps), so a crossfade at a spring never clashes. Each states Miller's Oak's hymn (the fifth
# below, the tonic, then a step up to the third and back: 5 1 2 3 2 1 5) in its own mode and
# colour: D Ionian at the landing, A Mixolydian on Iron Shore, E Dorian on the Gale Cliffs,
# B Aeolian in the Tide Grottos, and G Lydian round the oak itself.

def crown_south_bay() -> Suite:
    """South Bay and the Lantern-Bearers' Waypost: the hymn first heard, warm and wondering. D Ionian,
    3/4 at 96, 16 bars, over a plucked weave."""
    s = Suite("crown_south_bay", 96.0, "3/4", [
        "D", "G/D", "Bm7", "A7sus4", "Gmaj7", "D/F#", "Em7", "A7",
        "D", "G/D", "Bm7", "F#m", "Gmaj7", "Em7", "A7sus4", "D"], mode("D", IONIAN), [0.0, 0.0, -80.0, -80.0])
    weave(s)
    accordion = s.part(1, "accordion", 96)
    violin = s.part(1, "violin", 98)
    bassoon = s.part(1, "bassoon_legato", 80)
    line(accordion, 1, "A4:1 D5:1.5 E5:.5 | F#5:2 E5:.5 D5:.5 | D5:1.5 C#5:.5 B4:1 | A4:2 r:1 |"
                       "B4:1 D5:1.5 E5:.5 | F#5:1.5 G5:.5 A5:1 | G5:1 F#5:1 E5:1 | E5:2 r:1", vel=84)
    line(violin, 9, "A5:1 D6:1.5 E6:.5 | F#6:2 E6:.5 D6:.5 | D6:1.5 C#6:.5 B5:1 | A5:1.5 F#5:.5 A5:1 |"
                    "B5:1 G5:1 B5:1 | E6:1.5 D6:.5 B5:1 | A5:1 G5:1 E5:1 | D5:2 r:1", vel=84)
    line(bassoon, 9, "D3:3 | D3:3 | B2:3 | A2:3 | G2:3 | E2:3 | A2:3 | D3:2 r:1", vel=70)
    invention(s)
    skirmish(s)
    return s


def crown_iron_shore() -> Suite:
    """Iron Shore and Old King's Town: the hymn as a heavy march in A Mixolydian, an anvil ringing every
    other bar. 4/4 at 92, 16 bars."""
    s = Suite("crown_iron_shore", 92.0, "4/4", [
        "A5", "G/A", "A5", "D/A", "A5", "G/A", "Em7", "A7sus4",
        "D", "A/C#", "G", "D/F#", "Em7", "G", "A7sus4", "A5"], mode("A", MIXOLYDIAN), [0.0, 0.0, -80.0, -80.0])
    march(s)
    anvil = s.part(0, "tubular", 64)
    stabs = s.part(0, "cello_stab", 88)
    for index, at, chord in s.each_bar():
        if index % 2 == 0:
            anvil.note(at, 1, n("E6"), 70 if index % 4 == 0 else 58, gate=1.5)
        stabs.note(at, 1, chord.bass(36), 92, gate=0.35)
        stabs.note(at + 2, 1, chord.bass(36), 74, gate=0.35)
    horn = s.part(1, "english_horn", 100)
    cello = s.part(1, "cello", 96)
    line(horn, 1, "E4:1 A4:1.5 B4:.5 C#5:1 | B4:2 A4:1 E4:1 | G4:1.5 A4:.5 B4:1 C#5:1 | D5:3 r:1 |"
                  "E4:1 A4:1.5 B4:.5 C#5:1 | D5:2 C#5:1 B4:1 | G4:1.5 F#4:.5 E4:1 G4:1 | A4:3 r:1", vel=88)
    line(cello, 9, "A2:1 D3:1.5 E3:.5 F#3:1 | E3:2 C#3:1 A2:1 | B2:1 D3:1 G3:1.5 F#3:.5 | F#3:3 r:1 |"
                   "E3:1 G3:1.5 A3:.5 B3:1 | B3:2 A3:1 G3:1 | E3:1.5 F#3:.5 G3:1 B3:1 | A3:3 r:1", vel=92)
    line(horn, 9, "D5:4 | E5:2 C#5:2 | D5:4 | A4:4 | B4:4 | D5:2 B4:2 | D5:2 E5:2 | A4:4", vel=72)
    invention(s, high="english_horn")
    skirmish(s)
    return s


def crown_gale_cliffs() -> Suite:
    """The Gale Cliffs and the Breach Point: the hymn skirled on a tin whistle into the wind, E Dorian,
    6/8 at 104, 16 bars, over a rolling guitar and harp harmonics."""
    s = Suite("crown_gale_cliffs", 104.0, "6/8", [
        "Em9", "Em9", "D/E", "D/E", "Cmaj7", "D", "Em7", "Bm7",
        "Em9", "Em9", "A9", "A9", "Cmaj7", "D", "Bm7", "Em9"], mode("E", DORIAN), [0.0, 0.0, -80.0, -80.0])
    rolling_sixths(s)
    whistle = s.part(1, "whistle", 100)
    flute = s.part(1, "flute", 92)
    harmonics = s.part(1, "harp", 66)
    line(whistle, 1, "B5:1 E6:1.5 F#6:.5 | G6:1.5 F#6:1 E6:.5 | A5:1.5 r:1.5 | F#5:.5 A5:.5 D6:.5 E6:1.5 |"
                     "~F#6 G6:1 F#6:.5 E6:1 D6:.5 | E6:1.5 D6:1 B5:.5 | G5:1 A5:.5 B5:1 D6:.5 | B5:1.5 r:1.5", vel=86)
    line(flute, 9, "B4:1 E5:1.5 F#5:.5 | G5:1.5 F#5:1 E5:.5 | E5:1 F#5:.5 A5:1 G5:.5 | E5:1.5 r:1.5 |"
                   "G5:1 E5:.5 C5:1 E5:.5 | F#5:1 A5:.5 D6:1.5 | D6:1 C#6:.5 B5:1.5 | B5:1.5 r:1.5", vel=82)
    for index, at, chord in s.each_bar():
        if index % 2 == 1:
            harmonics.note(at + 1.5, 1, chord.arp(81, 1)[0], 44, gate=3.0)
    invention(s, high="english_horn", pads=False)
    skirmish(s)
    return s


def crown_tide_grottos() -> Suite:
    """The Tide Grottos and the Sap Galleries: the hymn low on an English horn in B Aeolian, harp and
    celesta glinting like the rock pools over a tremolo cello. 3/4 at 84, 16 bars."""
    s = Suite("crown_tide_grottos", 84.0, "3/4", [
        "Bm9", "Bm9", "Gmaj7", "Gmaj7", "Em9", "F#m", "Gmaj7", "F#7sus4",
        "Bm9", "Bm9", "Dmaj7", "A", "Gmaj7", "Em7", "F#7sus4", "Bm9"], mode("B", AEOLIAN), [0.0, 0.0, -80.0, -80.0])
    sparse_harp(s)
    glints = s.part(0, "celesta", 70)
    deep = s.part(0, "tremolo", 58)
    for index, at, chord in s.each_bar():
        deep.note(at, 3, chord.bass(35), 50, gate=1.0)
        if index % 2 == 0:
            for step, pitch in enumerate(chord.arp(83, 2)):
                glints.note(at + 1 + step * 0.5, 0.5, pitch, 52 - step * 6, gate=2.0)
    horn = s.part(1, "english_horn", 100)
    oboe = s.part(1, "oboe", 88)
    line(horn, 1, "F#4:1 B4:1.5 C#5:.5 | D5:2 C#5:.5 B4:.5 | B4:1.5 A4:.5 G4:1 | F#4:2 r:1 |"
                  "E4:1 G4:1.5 A4:.5 | C#5:2 B4:.5 A4:.5 | B4:1 D5:1 F#5:1 | E5:2 r:1", vel=84)
    line(oboe, 9, "F#5:1 B5:1.5 C#6:.5 | D6:2 C#6:.5 B5:.5 | A5:1.5 F#5:.5 D5:1 | E5:2 C#5:1 |"
                  "D5:1 B4:1 G5:1 | G5:1.5 F#5:.5 E5:1 | E5:1 C#5:1 A4:1 | B4:2 r:1", vel=80)
    invention(s, high="english_horn", pads=False)
    skirmish(s, fiddle=False)
    return s


def crown_millers_oak() -> Suite:
    """Miller's Oak and the Summit Glade: the hymn in full, G Lydian, the oboe and then the solo violin
    over harp, carillon and the accordion's held chords. 3/4 at 88, 16 bars."""
    s = Suite("crown_millers_oak", 88.0, "3/4", [
        "Gmaj7", "A/G", "Gmaj7", "A/G", "Em7", "F#m7", "Bm7", "D",
        "Gmaj9", "A/G", "Bm7", "F#m7", "Em7", "A7sus4", "D/G", "A/G"], mode("G", LYDIAN), [0.0, 0.0, -80.0, -80.0])
    harp = s.part(0, "harp", 92)
    pedal = s.part(0, "bassoon_legato", 70)
    bells = s.part(0, "carillon", 72)
    for index, at, chord in s.each_bar():
        for step, pitch in enumerate(chord.arp(55, 6)):
            harp.note(at + step * 0.5, 0.5, pitch, 54 + step * 3, gate=3.0)
        pedal.note(at, 3, chord.bass(36), 54, gate=1.0)
        if index % 2 == 0:
            bells.note(at, 1.5, chord.root_at(74), 62 if index % 4 == 0 else 52, gate=2.0)
    oboe = s.part(1, "oboe", 96)
    violin = s.part(1, "violin", 100)
    accordion = s.part(1, "accordion", 74)
    line(oboe, 1, "D5:1 G5:1.5 A5:.5 | B5:2 A5:.5 G5:.5 | D5:2 r:1 | C#6:1.5 B5:.5 A5:1 |"
                  "B5:1 G5:1.5 E5:.5 | F#5:2 E5:.5 C#5:.5 | D5:1 F#5:1 B5:1 | A5:2 r:1", vel=84)
    line(violin, 9, "D6:1 G6:1.5 A6:.5 | B6:2 A6:.5 G6:.5 | F#6:1.5 E6:.5 D6:1 | C#6:2 A5:1 |"
                    "B5:1 G5:1.5 E5:.5 | E5:2 F#5:.5 G5:.5 | A5:1.5 G5:.5 F#5:1 | E5:2 r:1", vel=86)
    for index, at, chord in s.each_bar():
        if index >= 8:
            for pitch in chord.upper(57, 3):
                accordion.note(at, 3, pitch, 48, gate=1.0)
    invention(s)
    skirmish(s, fiddle=False)
    return s


SUITES = [oakshire_vale, honey_wick, bramble_bridge_square, moss_oak_hollow, dover_slap_falls, ring_of_the_cairnsman,
          cairnsmans_vigil, crown_south_bay, crown_iron_shore, crown_gale_cliffs, crown_tide_grottos, crown_millers_oak]


# --- The Audio Mosaics (docs/16 §7) ----------------------------------------------------
#
# A mosaic zone has twelve four-bar phrase cells instead of one loop: two in each of six moods,
# each carrying its lead on a different Hisaishi Quartet voicing (A: accordion over pizzicato,
# bassoon counter; B: violin or cello in sixths over guitar and harp; C: oboe and bassoon in
# dialogue over mandolin; D: low whistle or recorder over harp and cello fifths). AudioDirector
# chains them on the bar line and MusicMoodEngine picks the next one, so every cell starts on
# a tonic-family chord and ends on one that leads anywhere (I, IV or V). Each cell is its own
# four stems; its notes ring on past the bar line for TAIL_SEC under the next cell.

TAIL_SEC = 1.5
TAIL_FADE_SEC = 0.6
# Each mood's exploration mix, as MusicMoodEngine.MOOD_STEMS_DB has it (for the listening copy).
MOOD_STEMS_DB = {"wonder": [0.0, 0.0], "interest": [0.0, -1.0], "mellow": [-1.5, -1.0], "peace": [-2.0, -1.5],
                 "curiosity": [-1.0, 0.0], "anxious": [-2.0, -2.5]}


class Mosaic:
    """A zone's twelve cells, in suite order: Peace, Wonder, Interest, Curiosity, Anxiousness, Mellow."""

    def __init__(self, profile_id: str, bpm: float, meter: str) -> None:
        self.profile_id = profile_id
        self.bpm = bpm
        self.meter = meter
        self.cells: list[Suite] = []

    def cell(self, cell_id: str, voice: str, chords: list[str], key: list[int]) -> Suite:
        made = Suite("%s/%s" % (self.profile_id, cell_id), self.bpm, self.meter, chords, key, [0.0, 0.0, -80.0, -80.0])
        made.cell_id = cell_id
        made.mood = cell_id.rsplit("_", 1)[0]
        made.voice = voice
        self.cells.append(made)
        return made


def parallel(source: Part, part: Part, s: Suite, below: bool = True, sizes: tuple[int, ...] = (9, 8), drop: int = 12) -> None:
    """A second voice moving with `source` a sixth (sizes 8, 9) or a third (3, 4) away, in the cell's
    mode bent to each bar's chord, a chord tone when it can be."""
    for note in list(source.notes):
        if note["beats"] < 0.2:
            continue
        bar = min(int(note["start"] // s.beats), len(s.chords) - 1)
        chord = s.chords[bar]
        pcs = chord.scale(s.key)
        options = [note["pitch"] + (-size if below else size) for size in sizes]
        fitting = [pitch for pitch in options if pitch % 12 in pcs]
        tones = [pitch for pitch in fitting if pitch % 12 in chord.pcs]
        pitch = (tones or fitting or options)[0]
        part.note(note["start"], note["beats"], pitch, note["vel"] - drop, gate=note["gate"])


def harp_gliss(part: Part, s: Suite, bar: int, names: str, vel: int = 60) -> None:
    """A harp glissando over beats 2 and 3 of `bar` (1-based)."""
    gliss = [n(name) for name in names.split()]
    for step, pitch in enumerate(gliss):
        part.note((bar - 1) * s.beats + 1 + step * (2.0 / len(gliss)), 0.25, pitch, vel + step * 2, gate=4.0)


def peace_bed(s: Suite) -> None:
    """Shore's hearth: a Celtic harp climbing the chord in eighths over a cello's open-fifth drone,
    with a high harp harmonic every other bar."""
    harp = s.part(0, "harp", 88)
    drone = s.part(0, "cello", 66)
    for index, at, chord in s.each_bar():
        low = chord.bass(41)
        for pitch in (low, low + 7):
            drone.note(at, s.beats, pitch, 52, gate=1.03)
        for step, pitch in enumerate(chord.arp(55, 6)):
            harp.note(at + step * 0.5, 0.5, pitch, 54 + step * 3, gate=3.0)
        if index % 2 == 1:
            harp.note(at + 2, 1, chord.arp(79, 1)[0], 42, gate=3.0)


def soar_bed(s: Suite) -> None:
    """The Sky Soar's ground: fingerpicked guitar rolling root, fifth, octave, tenth; a harp rising
    through the chord on the last two beats; a soft pizzicato root on the downbeat."""
    guitar = s.part(0, "guitar", 92)
    harp = s.part(0, "harp", 84)
    bass = s.part(0, "pizz", 88)
    for index, at, chord in s.each_bar():
        root = chord.root_at(50)
        above = chord.arp(root + 13, 2)
        voicing = [root, root + chord.fifth(), root + 12, above[0], above[1]]
        for step, slot in enumerate([0, 1, 2, 3, 4, 2]):
            guitar.note(at + step * 0.5, 0.5, voicing[slot], 74 if step == 0 else 60, gate=1.8)
        bass.note(at, 1, chord.bass(40), 84, gate=0.6)
        for step, pitch in enumerate(chord.arp(62, 6)):
            harp.note(at + 1 + step * (2.0 / 6), 0.33, pitch, 52 + step * 3, gate=2.4)


def walking(s: Suite, chops: bool = True) -> None:
    """Ocean View's bustle: a pizzicato walking bass in quarters (root, a chord tone, then a step
    into the next bar's bass) under mandolin and guitar chops on beats 2 and 3."""
    bass = s.part(0, "pizz", 100)
    mandolin = s.part(0, "mandolin", 84) if chops else None
    guitar = s.part(0, "guitar", 86) if chops else None
    for index, at, chord in s.each_bar():
        low = chord.bass(40)
        nxt = s.chords[(index + 1) % len(s.chords)].bass(40)
        middle = chord.arp(low + 3, 1)[0]
        approach = nxt - 1 if (nxt - 1) % 12 in chord.scale(s.key) or index == len(s.chords) - 1 else nxt + 2
        approach = approach if approach > low - 6 else approach + 12
        for beat, pitch, vel in [(0, low, 98), (1, middle, 78), (2, approach, 82)]:
            bass.note(at + beat, 1, pitch, vel, gate=0.5)
        if mandolin is not None and guitar is not None:
            for beat in (1, 2):
                for strum, pitch in enumerate(chord.upper(66, 3)):
                    mandolin.note(at + beat, 0.5, pitch, 70 if beat == 1 else 62, gate=0.3, strum=strum)
                for strum, pitch in enumerate(chord.upper(55, 3)):
                    guitar.note(at + beat + 0.5, 0.5, pitch, 56, gate=0.35, strum=strum)


def tiptoe(s: Suite) -> None:
    """Into the Unknown's tiptoe: a pizzicato cello creeping round the root with its lower neighbour,
    a low harp chord on the bar, and a soft mandolin tremolo on the chord's top."""
    bass = s.part(0, "pizz", 92)
    harp = s.part(0, "harp", 70)
    mandolin = s.part(0, "mandolin", 58)
    for index, at, chord in s.each_bar():
        low = chord.bass(40)
        for offset, pitch, vel in [(0, low, 90), (0.5, low - 1, 58), (1, low, 72), (1.5, low + chord.fifth(), 66), (2.5, low - 1, 60)]:
            bass.note(at + offset, 0.5, pitch, vel, gate=0.4)
        for strum, pitch in enumerate(chord.upper(48, 3)):
            harp.note(at, 2, pitch, 50, gate=1.6, strum=strum)
        top = chord.arp(74, 1)[0]
        for step in range(6):
            mandolin.note(at + 1 + step * (1.0 / 3), 0.33, top, 40 + (step % 2) * 6, gate=0.7)


def waterwheel(s: Suite) -> None:
    """The mill-isle's turning wheel (6/8): guitar rolling the chord in eighths, a hammered dulcimer
    striking root and fifth on each dotted quarter, and a pizzicato bass on 1 and 4."""
    guitar = s.part(0, "guitar", 94)
    dulcimer = s.part(0, "dulcimer", 76)
    bass = s.part(0, "pizz", 92)
    for index, at, chord in s.each_bar():
        root = chord.root_at(50)
        above = chord.arp(root + 13, 2)
        voicing = [root, root + chord.fifth(), root + 12, above[0], above[1]]
        for step, slot in enumerate([0, 1, 2, 3, 4, 2]):
            guitar.note(at + step * 0.5, 0.5, voicing[slot], 76 if step in (0, 3) else 58, gate=1.6)
        for beat in (0, 1.5):
            for pitch in (chord.root_at(62), chord.root_at(62) + chord.fifth()):
                dulcimer.note(at + beat, 0.75, pitch, 64 if beat == 0 else 54, gate=1.2)
        low = chord.bass(40)
        bass.note(at, 0.5, low, 90, gate=0.6)
        bass.note(at + 1.5, 0.5, low + 7 if (low + 7) % 12 in chord.pcs else low, 68, gate=0.6)


def jig(s: Suite) -> None:
    """A 6/8 jig's bustle: pizzicato bass on 1 and 4 with a pickup into the next bar, mandolin and
    guitar chopping the off-eighths."""
    bass = s.part(0, "pizz", 98)
    mandolin = s.part(0, "mandolin", 84)
    guitar = s.part(0, "guitar", 84)
    for index, at, chord in s.each_bar():
        low = chord.bass(40)
        nxt = s.chords[(index + 1) % len(s.chords)].bass(40)
        bass.note(at, 0.5, low, 96, gate=0.5)
        bass.note(at + 1.5, 0.5, low + 7 if (low + 7) % 12 in chord.pcs else low + 12, 76, gate=0.5)
        bass.note(at + 2.5, 0.5, nxt - 1 if (nxt - 1) % 12 in chord.scale(s.key) else nxt + 2, 70, gate=0.45)
        for eighth in (1, 2, 4, 5):
            for strum, pitch in enumerate(chord.upper(66, 3)):
                mandolin.note(at + eighth * 0.5, 0.5, pitch, 66 if eighth in (1, 4) else 56, gate=0.3, strum=strum)
        for eighth in (2, 5):
            for strum, pitch in enumerate(chord.upper(55, 3)):
                guitar.note(at + eighth * 0.5, 0.5, pitch, 58, gate=0.35, strum=strum)


def shadow(s: Suite) -> None:
    """Anxiousness's Holloway stem (docs/16 §7.1): reedy bassoon and oboe trading minor seconds and
    tritones, musette bellows breathing a cluster with the chord's minor ninth, and a sul ponticello
    string shimmer high above."""
    reed = s.part(2, "bassoon", 96)
    oboe = s.part(2, "oboe", 84)
    bellows = s.part(2, "accordion", 70)
    shimmer = s.part(2, "tremolo", 56)
    for index, at, chord in s.each_bar():
        low = chord.bass(40)
        for offset, pitch, vel in [(0, low, 82), (0.5, low + 1, 70), (1.5, low, 74), (2, low + 6, 66)]:
            reed.note(at + offset, 0.5, pitch, vel, gate=0.7)
        top = chord.arp(67, 1)[0]
        if index % 2 == 0:
            for offset, pitch in [(1, top), (1.5, top + 1), (2, top + 6 if (top + 6) % 12 in chord.scale(s.key) else top + 5)]:
                oboe.note(at + offset, 0.5, pitch, 68, gate=0.9)
        cluster = chord.upper(55, 3) + [chord.root_at(55) + 1]
        for pitch in cluster:
            bellows.note(at, s.beats * 0.9, pitch, 46, gate=1.0)
        for pitch in chord.arp(83, 2):
            shimmer.note(at, s.beats, pitch, 40, gate=1.02)


def mosaic_layers(s: Suite, anxious: bool = False) -> None:
    """Stems 2 and 3 of a cell: the Holloway discord (Anxiousness's shadow, or the gentle reed
    invention every other cell holds for the Pre-Warm) and the Skirmish drive."""
    if anxious:
        shadow(s)
    else:
        invention(s)
    skirmish(s)


def crown_island() -> Mosaic:
    """The Crown: Joe Hisaishi's Town With An Ocean View by the sea, G Lydian and Ionian in 3/4 at 110,
    turning to misty E Dorian and E harmonic-minor bassoon along the cliffs and grottos."""
    m = Mosaic("crown_island", 110.0, "3/4")
    g_lydian, g_ionian, g_mixo = mode("G", LYDIAN), mode("G", IONIAN), mode("G", MIXOLYDIAN)
    e_dorian, e_minor = mode("E", DORIAN), mode("E", HARMONIC_MINOR)
    # Peace (cell F): pentatonic tunes over a G drone; a fiddle, then a recorder.
    s = m.cell("peace_a", "B", ["Gadd9", "C/G", "Em7/G", "D/G"], g_ionian)
    peace_bed(s)
    line(s.part(1, "violin", 92), 1, "D5:1 E5:.5 G5:.5 A5:1 | B5:2 A5:1 | G5:1 E5:.5 D5:.5 E5:1 | D5:2 r:1", vel=80)
    mosaic_layers(s)
    s = m.cell("peace_b", "D", ["Gadd9", "Em7/G", "C/G", "Gadd9"], g_ionian)
    peace_bed(s)
    line(s.part(1, "recorder", 96), 1, "B5:1.5 A5:.5 G5:1 | E5:2 D5:1 | E5:1 G5:.5 A5:.5 B5:1 | A5:2 r:1", vel=82)
    mosaic_layers(s)
    # Wonder (cell B, I II7 IVmaj7 I): the accordion's skyward leaps over the waltz, then the violin soaring in sixths.
    s = m.cell("wonder_a", "A", ["G", "A7", "Cmaj7", "G"], g_lydian)
    oompah(s, bassoon=False)
    line(s.part(1, "accordion", 100), 1, "D5:1 B5:1.5 A5:.5 | G5:1 C#6:1 E6:1 | D6:1.5 B5:.5 G5:1 | A5:2 r:1", vel=90)
    line(s.part(1, "bassoon", 92), 1, "G2:.5 r:.5 D3:.5 G3:.5 B3:.5 r:.5 | A2:.5 r:.5 E3:.5 G3:.5 C#4:.5 r:.5 |"
                                      "C3:.5 r:.5 G3:.5 B3:.5 E4:.5 D4:.5 | G3:.5 F#3:.5 E3:.5 D3:.5 B2:.5 A2:.5", vel=82, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("wonder_b", "B", ["Gmaj7", "A9", "Cmaj7#11", "Gadd9"], g_lydian)
    soar_bed(s)
    violin = s.part(1, "violin", 100)
    line(violin, 1, "G5:1 G6:1.5 F#6:.5 | E6:1 C#6:1 A5:1 | B5:1.5 E6:.5 G6:1 | F#6:1 D6:1 r:1", vel=88)
    parallel(violin, s.part(1, "violin", 78), s)
    harp_gliss(s.part(1, "harp", 90), s, 3, "G4 A4 B4 C#5 D5 E5 F#5 G5 A5 B5 C#6 D6")
    mosaic_layers(s)
    # Interest (cell A, I VI7 ii7 V7): the oboe's bouncy tune with the bassoon's answers, then the accordion.
    s = m.cell("interest_a", "C", ["G", "E7", "Am7", "D7"], g_ionian)
    walking(s)
    line(s.part(1, "oboe", 98), 1, "B4:.5 D5:.5 G5:1 F#5:.5 E5:.5 | G#5:1 E5:.5 D5:.5 B4:1 | C5:.5 E5:.5 A5:1 G5:.5 E5:.5 | F#5:1.5 r:1.5", vel=88)
    line(s.part(1, "bassoon", 94), 1, "r:3 | r:2 E3:.5 G#3:.5 | r:3 | r:1.5 D3:.5 F#3:.5 C4:.5", vel=86, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("interest_b", "A", ["G", "E7/G#", "Am7", "D7"], g_ionian)
    walking(s)
    line(s.part(1, "accordion", 100), 1, "G5:.5 A5:.5 B5:.5 D6:1 B5:.5 | G#5:1.5 E5:.5 D5:1 | E5:.5 F#5:.5 G5:.5 A5:1 C6:.5 | B5:1 A5:1 F#5:1", vel=88)
    line(s.part(1, "bassoon", 90), 1, "G2:.5 r:.5 B2:.5 D3:.5 G3:.5 r:.5 | G#2:.5 r:.5 B2:.5 D3:.5 E3:.5 r:.5 |"
                                      "A2:.5 C3:.5 E3:.5 G3:.5 A3:.5 r:.5 | D3:.5 r:.5 F#3:.5 A3:.5 C4:.5 A3:.5", vel=80, gate=STACCATO)
    mosaic_layers(s)
    # Curiosity (cell C, i IV i7 v in E Dorian): two-bar questions and answers, ending on a half-cadence.
    s = m.cell("curiosity_a", "C", ["Em", "A", "Em7", "Bm"], e_dorian)
    weave(s)
    line(s.part(1, "oboe", 96), 1, "E5:.5 F#5:.5 G5:.5 r:.5 B5:1 | C#6:.5 B5:.5 A5:1 r:1 | r:3 | r:1.5 D5:.5 E5:.5 F#5:.5", vel=86)
    line(s.part(1, "bassoon", 96), 1, "r:3 | r:3 | E3:.5 G3:.5 B3:.5 r:.5 D4:1 | C#4:.5 B3:.5 F#3:1 r:1", vel=88, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("curiosity_b", "D", ["Em", "A/E", "Em7", "Bm7"], e_dorian)
    weave(s)
    line(s.part(1, "whistle", 94), 1, "B5:.5 A5:.5 G5:.5 F#5:.5 E5:1 | C#6:1 B5:.5 A5:.5 E5:1 | r:3 | D6:.5 C#6:.5 B5:.5 A5:.5 F#5:1", vel=84)
    line(s.part(1, "bassoon", 94), 1, "r:3 | r:3 | E3:.5 B2:.5 E3:.5 G3:.5 B3:.5 D4:.5 | B2:1 r:2", vel=86, gate=STACCATO)
    mosaic_layers(s)
    # Anxiousness (cell E, i bVI #vii°7 V7b9 in E harmonic minor): a tiptoe under the musette, then the reeds' tritones.
    s = m.cell("anxious_a", "A", ["Em", "C", "D#dim7", "B7b9"], e_minor)
    tiptoe(s)
    line(s.part(1, "accordion", 94), 1, "E5:1 D#5:.5 E5:.5 G5:1 | E5:1.5 C5:.5 B4:1 | A4:1 F#4:.5 A4:.5 C5:1 | B4:2 r:1", vel=84)
    line(s.part(1, "bassoon", 92), 1, "E3:.5 r:.5 D#3:.5 E3:.5 r:1 | C3:.5 r:.5 G2:.5 C3:.5 r:1 |"
                                      "D#3:.5 F#3:.5 A3:.5 C4:.5 r:1 | B2:.5 C3:.5 B2:.5 A2:.5 F#2:.5 D#2:.5", vel=80, gate=STACCATO)
    mosaic_layers(s, anxious=True)
    s = m.cell("anxious_b", "C", ["Em", "C", "D#dim7", "B7b9"], e_minor)
    tiptoe(s)
    line(s.part(1, "oboe", 94), 1, "B5:.5 C6:.5 B5:1 G5:1 | E5:1 C5:.5 E5:.5 G5:1 | F#5:.5 A5:.5 C6:1 D#5:1 | D#5:1 C6:1 B5:1", vel=84)
    line(s.part(1, "bassoon", 94), 1, "E3:1 r:.5 A#2:.5 B2:1 | C3:1 r:.5 F#3:.5 G3:1 | A2:1 C3:.5 D#3:.5 F#3:1 | B2:2 r:1", vel=84, gate=0.7)
    mosaic_layers(s, anxious=True)
    # Mellow (cell D, vi iii IV I6 in G Mixolydian): a cello with a violin a sixth above, then a low whistle and English horn.
    s = m.cell("mellow_a", "B", ["Em", "Bm", "C", "G/B"], g_mixo)
    rolling_sixths(s)
    cello = s.part(1, "cello", 100)
    line(cello, 1, "B3:1.5 A3:.5 G3:1 | F#3:2 D3:1 | E3:1 F3:.5 G3:.5 C4:1 | B3:2 r:1", vel=88)
    parallel(cello, s.part(1, "violin", 76), s, below=False)
    mosaic_layers(s)
    s = m.cell("mellow_b", "D", ["Em7", "Bm7", "Cmaj7", "G/B"], g_mixo)
    rolling_sixths(s)
    flute = s.part(1, "flute", 100)
    line(flute, 1, "G5:1.5 F#5:.5 E5:1 | D5:2 B4:1 | C5:1 E5:1 G5:1 | F5:1 E5:.5 D5:.5 B4:1", vel=86)
    parallel(flute, s.part(1, "english_horn", 80), s)
    mosaic_layers(s)
    return m


def millers_holm() -> Mosaic:
    """Oakshire Holm, the mill-isle (the brief's Miller's Holm): Howard Shore's Concerning Hobbits and
    Hisaishi's Mother's Broom, F Lydian and D Dorian in 6/8 at 104 over a waterwheel's guitar and dulcimer."""
    m = Mosaic("millers_holm", 104.0, "6/8")
    f_lydian, f_ionian, f_mixo = mode("F", LYDIAN), mode("F", IONIAN), mode("F", MIXOLYDIAN)
    d_dorian, d_minor = mode("D", DORIAN), mode("D", HARMONIC_MINOR)
    s = m.cell("peace_a", "B", ["Fadd9", "Bb/F", "Dm7/F", "C/F"], f_ionian)
    peace_bed(s)
    line(s.part(1, "violin", 92), 1, "C5:1 D5:.5 F5:.5 G5:1 | A5:1.5 G5:1.5 | F5:1 D5:.5 C5:.5 D5:1 | C5:1.5 r:1.5", vel=80)
    mosaic_layers(s)
    s = m.cell("peace_b", "D", ["Fadd9", "Dm7/F", "Bb/F", "Fadd9"], f_ionian)
    peace_bed(s)
    line(s.part(1, "recorder", 96), 1, "A5:1.5 G5:.5 F5:1 | D5:1.5 C5:1.5 | D5:1 F5:.5 G5:.5 A5:1 | G5:1.5 r:1.5", vel=82)
    mosaic_layers(s)
    s = m.cell("wonder_a", "A", ["F", "G7", "Bbmaj7", "F"], f_lydian)
    waterwheel(s)
    line(s.part(1, "accordion", 100), 1, "C5:1.5 A5:1.5 | B5:1 G5:.5 D6:1.5 | D6:1 A5:.5 F5:1.5 | G5:1.5 r:1.5", vel=90)
    line(s.part(1, "bassoon", 90), 1, "F2:.5 r:1 C3:.5 F3:.5 A3:.5 | G2:.5 r:1 D3:.5 F3:.5 B3:.5 |"
                                      "Bb2:.5 r:1 F3:.5 A3:.5 D4:.5 | C3:.5 A2:.5 F2:.5 r:1.5", vel=82, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("wonder_b", "B", ["Fmaj7", "G9", "Bbmaj7#11", "Fadd9"], f_lydian)
    soar_bed(s)
    violin = s.part(1, "violin", 100)
    line(violin, 1, "F5:1.5 C6:1.5 | B5:1 D6:.5 G6:1.5 | F6:1 D6:.5 A5:1.5 | C6:1.5 A5:1.5", vel=88)
    parallel(violin, s.part(1, "violin", 78), s)
    harp_gliss(s.part(1, "harp", 90), s, 3, "F4 G4 A4 B4 C5 D5 E5 F5 G5 A5 B5 C6")
    mosaic_layers(s)
    s = m.cell("interest_a", "C", ["F", "D7", "Gm7", "C7"], f_ionian)
    jig(s)
    line(s.part(1, "oboe", 98), 1, "A5:.5 G5:.5 F5:.5 C5:1.5 | F#5:1 A5:.5 D6:1 C6:.5 | Bb5:.5 A5:.5 G5:.5 D5:1.5 | r:3", vel=88)
    line(s.part(1, "bassoon", 94), 1, "r:3 | r:3 | r:1.5 G2:.5 Bb2:.5 D3:.5 | C3:.5 E3:.5 G3:.5 Bb3:.5 G3:.5 E3:.5", vel=86, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("interest_b", "A", ["F", "D7/F#", "Gm7", "C7"], f_ionian)
    jig(s)
    line(s.part(1, "accordion", 100), 1, "F5:1 A5:.5 C6:1 A5:.5 | D6:1 C6:.5 A5:1 F#5:.5 | G5:1 Bb5:.5 D6:1 F5:.5 | E5:1.5 G5:1.5", vel=88)
    line(s.part(1, "bassoon", 90), 1, "F2:.5 r:.5 A2:.5 C3:1 r:.5 | F#2:.5 r:.5 A2:.5 D3:1 r:.5 |"
                                      "G2:.5 r:.5 Bb2:.5 D3:1 r:.5 | C3:.5 E3:.5 G3:.5 Bb3:.5 G3:.5 E3:.5", vel=80, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("curiosity_a", "C", ["Dm", "G", "Dm7", "Am"], d_dorian)
    weave(s)
    line(s.part(1, "oboe", 96), 1, "D5:.5 E5:.5 F5:.5 A5:1.5 | B5:.5 A5:.5 G5:.5 D5:1.5 | r:3 | r:1.5 C5:.5 D5:.5 E5:.5", vel=86)
    line(s.part(1, "bassoon", 96), 1, "r:3 | r:3 | D3:.5 F3:.5 A3:.5 C4:1.5 | A2:1.5 r:1.5", vel=88, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("curiosity_b", "D", ["Dm", "G/D", "Dm7", "Am7"], d_dorian)
    weave(s)
    line(s.part(1, "whistle", 94), 1, "A5:.5 G5:.5 F5:.5 E5:.5 D5:1 | B5:1 A5:.5 G5:.5 D5:1 | r:3 | C6:.5 B5:.5 A5:.5 G5:.5 E5:1", vel=84)
    line(s.part(1, "bassoon", 94), 1, "r:3 | r:3 | D3:.5 A2:.5 D3:.5 F3:.5 A3:.5 C4:.5 | A2:1 r:2", vel=86, gate=STACCATO)
    mosaic_layers(s)
    s = m.cell("anxious_a", "A", ["Dm", "Bb", "C#dim7", "A7b9"], d_minor)
    tiptoe(s)
    line(s.part(1, "accordion", 94), 1, "D5:1 C#5:.5 D5:.5 F5:1 | D5:1.5 Bb4:.5 A4:1 | G4:1 E4:.5 G4:.5 Bb4:1 | A4:1.5 r:1.5", vel=84)
    line(s.part(1, "bassoon", 92), 1, "D3:.5 r:.5 C#3:.5 D3:.5 r:1 | Bb2:.5 r:.5 F2:.5 Bb2:.5 r:1 |"
                                      "C#3:.5 E3:.5 G3:.5 Bb3:.5 r:1 | A2:.5 Bb2:.5 A2:.5 G2:.5 E2:.5 C#2:.5", vel=80, gate=STACCATO)
    mosaic_layers(s, anxious=True)
    s = m.cell("anxious_b", "C", ["Dm", "Bb", "C#dim7", "A7b9"], d_minor)
    tiptoe(s)
    line(s.part(1, "oboe", 94), 1, "A5:.5 Bb5:.5 A5:1 F5:1 | D5:1 Bb4:.5 D5:.5 F5:1 | E5:.5 G5:.5 Bb5:1 C#5:1 | C#5:1 Bb5:1 A5:1", vel=84)
    line(s.part(1, "bassoon", 94), 1, "D3:1 r:.5 G#2:.5 A2:1 | Bb2:1 r:.5 E3:.5 F3:1 | G2:1 Bb2:.5 C#3:.5 E3:1 | A2:2 r:1", vel=84, gate=0.7)
    mosaic_layers(s, anxious=True)
    s = m.cell("mellow_a", "B", ["Dm", "Am", "Bb", "F/A"], f_mixo)
    rolling_sixths(s)
    cello = s.part(1, "cello", 100)
    line(cello, 1, "A3:1.5 G3:.5 F3:1 | E3:1.5 C3:1.5 | D3:1 Eb3:.5 F3:.5 Bb3:1 | A3:1.5 r:1.5", vel=88)
    parallel(cello, s.part(1, "violin", 76), s, below=False)
    mosaic_layers(s)
    s = m.cell("mellow_b", "D", ["Dm7", "Am7", "Bbmaj7", "F/A"], f_mixo)
    rolling_sixths(s)
    flute = s.part(1, "flute", 100)
    line(flute, 1, "F5:1.5 E5:.5 D5:1 | C5:1.5 A4:1.5 | Bb4:1 D5:1 F5:1 | Eb5:1 D5:.5 C5:.5 A4:1", vel=86)
    parallel(flute, s.part(1, "english_horn", 80), s)
    mosaic_layers(s)
    return m


MOSAICS = [millers_holm, crown_island]


# --- One-shots (docs/16 §3, §4.1; AudioCues' musical cues) ---------------------------

def chord_shot(shot: Shot, inst: str, notes: list[int], step: float, ring: float, vel: int, start: float = 0.0,
               gate: float = 1.0) -> None:
    part = shot.part(inst)
    for index, pitch in enumerate(notes):
        part.note(start + index * step, ring, pitch, vel, gate=gate)


def g(names: str) -> list[int]:
    return [n(name) for name in names.split()]


def one_shots() -> list[Shot]:
    shots: list[Shot] = []

    def make(name: str, kind: str, stereo: bool = True, loop_sec: float = 0.0) -> Shot:
        shot = Shot(name, kind, stereo, loop_sec)
        shots.append(shot)
        return shot

    # Instrument samples (mono): ProceduralChamberSynth re-pitches these for runtime phrases.
    for name, inst, pitch, beats, vel, gate in [
            ("sample_bassoon_staccato_g2", "bassoon", "G2", 0.3, 96, 1.0), ("sample_bassoon_legato_d3", "bassoon_legato", "D3", 1.4, 88, 1.0),
            ("sample_oboe_legato_g4", "oboe", "G4", 1.4, 88, 1.0), ("sample_accordion_g4", "accordion", "G4", 1.3, 90, 1.0),
            ("sample_harp_pluck_g4", "harp", "G4", 1.6, 96, 1.0), ("sample_pizz_cello_g2", "pizz", "G2", 0.6, 104, 1.0),
            ("sample_violin_swell_g4", "violin", "G4", 1.6, 92, 1.0), ("sample_carillon_chime_g5", "carillon", "G5", 2.5, 100, 1.0),
            ("sample_mandolin_pluck_g4", "mandolin", "G4", 0.9, 96, 1.0), ("sample_guitar_pluck_g3", "guitar", "G3", 1.4, 96, 1.0),
            ("sample_whistle_g5", "whistle", "G5", 1.1, 90, 1.0), ("sample_dulcimer_g4", "dulcimer", "G4", 1.4, 96, 1.0)]:
        make(name, "sample", stereo=False).part(inst).note(0, beats, n(pitch), vel, gate=gate)
    make("sample_bodhran_hit", "sample", stereo=False).part("drums").note(0, 0.5, BOOM, 112, gate=1.0)
    shot = make("sample_accordion_lydian_chord", "sample", stereo=False)
    chord_shot(shot, "accordion", g("G3 B3 D4 F#4 C#5"), 0.0, 1.6, 84)
    # The oasis by a water-shrine or wind-lantern: a two-octave G Lydian harp glissando.
    shot = make("sample_harp_lydian_gliss", "stinger")
    chord_shot(shot, "harp", g("G4 A4 B4 C#5 D5 E5 F#5 G5 A5 B5 C#6 D6 E6 F#6"), 0.055, 2.4, 78)
    shot.part("celesta").note(14 * 0.055, 2.0, n("F#6"), 60)

    # The Four Signs' detonations, over G (AudioDirector re-pitches them to the zone's tonic).
    shot = make("sign_iron_root", "stinger")  # Shatterpoint: an open fifth, [0, 7, 12], an octave down
    chord_shot(shot, "pizz", g("G2 G3 D4"), 0.035, 1.0, 112)
    reed = shot.part("bassoon")
    reed.note(0, 0.8, n("G2"), 112, gate=1.0)
    reed.note(0.035, 0.8, n("G3"), 104, gate=1.0)
    chord_shot(shot, "tubular", g("G4 D5"), 0.05, 2.4, 92, start=0.07)
    chord_shot(shot, "church_bell", g("G3"), 0.0, 2.4, 70, start=0.07)
    shot = make("sign_rime_gale", "stinger")  # Glacial Rupture: a Lydian burst, [0, 4, 6, 7, 12]
    chord_shot(shot, "dulcimer", g("G4 B4 C#5 D5 G5"), 0.035, 1.6, 104)
    chord_shot(shot, "recorder", g("G5 A5 B5 C#6 D6"), 0.03, 0.12, 84, start=0.12)
    shot.parts[-1].notes[-1]["beats"] = 0.8
    chord_shot(shot, "celesta", g("G6 B6 C#7"), 0.04, 2.0, 80, start=0.2)
    shot = make("sign_warm_hearth", "stinger")  # Dawnburst: a major ninth, [0, 4, 7, 11, 14]
    chord_shot(shot, "accordion", g("G4 B4 D5 F#5 A5"), 0.0, 1.8, 80)
    chord_shot(shot, "harp", g("G3 B3 D4 F#4 G4 B4 D5 F#5 A5"), 0.05, 2.2, 82)
    shot = make("sign_star_tide", "stinger")  # Astral Chorus: a rising IV, [0, 5, 9, 12]
    tremolo = shot.part("mandolin")
    for step in range(12):
        for pitch in g("C5 E5"):
            tremolo.note(step * 0.07, 0.08, pitch, 82 - step * 2)
    oboe = shot.part("oboe")
    for index, pitch in enumerate(g("G4 C5 E5 G5")):
        oboe.note(index * 0.12, 0.14 if index < 3 else 1.0, pitch, 86)
    chord_shot(shot, "tubular", g("G5 C6"), 0.08, 2.4, 84, start=0.36)

    # The Sanctuary Cadence: Em9, A13, Cmaj7(#11), Gmaj9 (Barbeau's "coming home"), in G at 108.
    shot = make("stinger_sanctuary_cadence", "stinger")
    beat = 60.0 / 108.0
    harp = shot.part("harp")
    accordion = shot.part("accordion")
    reed = shot.part("bassoon_legato")
    for index, (bass, upper) in enumerate([("E3", "G4 B4 D5 F#5"), ("A2", "G4 C#5 F#5 B5"), ("C3", "E4 B4 F#5 G5"), ("G2", "B4 D5 F#5 A5")]):
        at = index * 1.5 * beat
        ring = 1.6 * beat if index < 3 else 4.0
        reed.note(at, ring, n(bass), 82)
        for step, pitch in enumerate(g(upper)):
            harp.note(at + step * 0.04, ring, pitch, 76)
            accordion.note(at, ring, pitch, 66)
    chord_shot(shot, "carillon", g("G5 D6"), 0.06, 3.0, 90, start=4.5 * beat)
    # The Restoration Exhale: a solo whistle, bassoon, cello and harp settle from E minor onto C(6/9).
    shot = make("stinger_restoration_exhale", "stinger")
    cello = shot.part("cello")
    cello.note(0, 1.1, n("E3"), 74)
    cello.note(1.1, 2.2, n("C3"), 70)
    reed = shot.part("bassoon_legato")
    reed.note(0, 1.1, n("B3"), 70)
    reed.note(1.1, 2.2, n("G3"), 66)
    chord_shot(shot, "harp", g("E3 B3 E4 G4 B4"), 0.07, 1.4, 70)
    chord_shot(shot, "harp", g("C3 G3 D4 E4 A4"), 0.07, 2.4, 66, start=1.1)
    whistle = shot.part("whistle")
    for at, beats, pitch in [(0, 0.5, "B5"), (0.5, 0.6, "A5"), (1.1, 1.6, "G5")]:
        whistle.note(at, beats, n(pitch), 78)
    # The Skirmish accent: a bodhran hit, a dulcimer roll and a mandolin slash, over G.
    shot = make("stinger_skirmish_accent", "stinger")
    shot.part("drums").note(0, 0.3, BOOM, 118)
    chord_shot(shot, "dulcimer", g("G3 D4 G4 D4 G4"), 0.03, 0.5, 98, start=0.02)
    chord_shot(shot, "mandolin", g("G4 D5 G5"), 0.012, 0.4, 92, start=0.04)
    # The Poise-Stagger Lydian window: Dmaj9(#11) on harp, musette accordion and brass carillon.
    shot = make("stinger_poise_stagger_lydian", "stinger")
    chord_shot(shot, "harp", g("D4 E4 F#4 G#4 A4 B4 C#5 D5 E5 F#5 G#5 A5 B5 C#6"), 0.035, 2.4, 84)
    chord_shot(shot, "accordion", g("D4 F#4 A4 C#5 E5 G#5"), 0.0, 2.2, 84)
    chord_shot(shot, "carillon", g("D5 A5"), 0.08, 3.0, 96, start=0.1)
    # The Co-Op Gate's A Lydian fanfare (A4 C#5 D#5 E5 A5) and its bronze toll.
    shot = make("stinger_gate_fanfare", "stinger")
    shot.part("church_bell").note(0, 3.0, n("A3"), 100)
    for inst, notes, vel in [("violin", "A4 C#5 E5 A5", 96), ("accordion", "E4 A4 C#5 E5", 84), ("oboe", "C#5 E5 D#5 E5", 86)]:
        part = shot.part(inst)
        for (at, beats), pitch in zip([(0.2, 0.18), (0.4, 0.12), (0.55, 0.12), (0.7, 1.8)], g(notes)):
            part.note(at, beats, pitch, vel)
    chord_shot(shot, "harp", g("A3 B3 C#4 D#4 E4 F#4 G#4 A4 B4 C#5 D#5 E5"), 0.04, 2.0, 78, start=0.7)
    bass = shot.part("pizz")
    bass.note(0.2, 0.3, n("A2"), 104)
    bass.note(0.7, 0.5, n("A2"), 108)
    shot.part("drums").note(0.7, 0.3, BOOM, 110)
    # The Wayfarer's Threshold (a portal): G sus2 add9 on chimes and harp.
    shot = make("stinger_wayfarers_threshold", "stinger")
    chord_shot(shot, "harp", g("G3 A3 D4 A4 D5"), 0.06, 2.4, 78)
    chord_shot(shot, "celesta", g("A5 D6 G6"), 0.08, 2.0, 64, start=0.2)
    chord_shot(shot, "tubular", g("D5"), 0.0, 2.6, 66, start=0.3)

    # The stations' loops (Ogg, looping): the Chime-Shrine's pentatonic carillon and the Co-Op
    # Gate's two plate harmonies (Plate 1 an accordion and cello A2 + E3, Plate 2 an oboe and
    # mandolin C#4 F#4 B4).
    shot = make("ambience_carillon", "loop", loop_sec=8.0)
    rng = random.Random(16)
    bells = shot.part("carillon")
    for strike in range(7):
        bells.note(strike * 8.0 / 7.0 + rng.random() * 0.3, 2.4, n(rng.choice(["G5", "A5", "B5", "D6", "E6", "G6"])), rng.randint(64, 84))
    shot = make("ambience_gate_drone", "loop", loop_sec=8.0)
    bellows = shot.part("accordion")
    for at in (0.0, 4.0):
        for pitch in g("A2 E3"):
            bellows.note(at, 4.1, pitch, 74, gate=1.0)
    cello = shot.part("cello")
    for at in (2.0, 6.0):
        cello.note(at, 4.1, n("A2"), 66, gate=1.0)
    shot = make("ambience_gate_counter", "loop", loop_sec=8.0)
    reed = shot.part("oboe")
    pluck = shot.part("mandolin")
    for index, pitch in enumerate(g("C#4 F#4 B4 F#4")):
        reed.note(index * 2.0, 2.05, pitch, 76, gate=1.0)
        for step in range(4):
            pluck.note(index * 2.0 + step * 0.5, 0.4, pitch + 12, 64 - step * 4)

    # AudioCues' musical cues (mono): the same notes the code-built cues used, on real instruments.
    def cue(name: str, *layers: tuple) -> None:
        shot = make("cue_" + name, "cue", stereo=False)
        for inst, notes, step, ring, vel, start in layers:
            chord_shot(shot, inst, g(notes), step, ring, vel, start=start)

    cue("seal_iron_root", ("bassoon", "E3", 0, 0.4, 100, 0), ("pizz", "E4 G#4 B4 E5", 0.07, 0.6, 100, 0), ("tubular", "E5", 0, 1.0, 70, 0.21))
    cue("seal_rime_gale", ("glock", "A5 C#6 E6 A6", 0.07, 1.0, 84, 0), ("recorder", "A6", 0, 0.4, 70, 0.21))
    cue("seal_warm_hearth", ("harp", "C5 E5 G5 C6", 0.08, 1.2, 92, 0), ("accordion", "C5 E5", 0, 0.8, 66, 0))
    cue("seal_star_tide", ("mandolin", "G4 D5 G5 D6 G6", 0.09, 0.8, 90, 0), ("oboe", "G4", 0, 0.9, 70, 0), ("cello", "G2", 0, 0.9, 70, 0))
    cue("card_chime", ("celesta", "G6", 0, 0.8, 90, 0), ("glock", "D7", 0, 0.6, 60, 0))
    cue("card_chime_foil", ("celesta", "G6", 0, 0.9, 92, 0), ("glock", "D7 G7", 0.04, 0.8, 68, 0))
    cue("card_chime_astral", ("celesta", "E6 A6 C7 E7 G7", 0.06, 1.0, 84, 0), ("harp", "G3 G4", 0, 1.4, 80, 0))
    cue("reward", ("harp", "B5 E6", 0.08, 0.9, 96, 0), ("glock", "E7", 0, 0.6, 54, 0.08))
    cue("join", ("mandolin", "C5 G5", 0.1, 0.5, 96, 0), ("harp", "C4", 0, 0.6, 70, 0))
    cue("portal_charge", ("harp", "G4 B4 D5", 0.18, 0.8, 86, 0), ("celesta", "G5 B5 D6", 0.18, 0.6, 56, 0))
    cue("portal", ("harp", "A3 C4 D4 E4 G4 A4 C5 D5 E5 G5 A5 C6 D6 E6", 0.05, 1.2, 84, 0), ("tubular", "A3", 0, 1.4, 70, 0))
    cue("victory", ("accordion", "G4 C5 E5 G5 C6", 0.11, 1.4, 88, 0), ("violin", "C5 E5 G5 C6", 0.11, 1.3, 84, 0.11),
        ("harp", "C3 G3 C4 E4 G4 C5", 0.06, 1.6, 84, 0.44), ("pizz", "C3", 0, 0.6, 104, 0.44), ("tubular", "C5 G5", 0.06, 1.8, 80, 0.44))
    cue("purchase", ("glock", "A5 E6", 0.07, 0.5, 86, 0), ("celesta", "A6", 0, 0.7, 70, 0.14))
    cue("chest", ("harp", "E6 G6 B6 E7", 0.05, 1.0, 90, 0), ("pizz", "E2", 0, 0.5, 100, 0), ("glock", "B6", 0, 0.6, 56, 0.2))
    cue("chime", ("tubular", "C6 G6", 0.11, 1.4, 92, 0))
    cue("lantern", ("celesta", "A6", 0, 1.0, 64, 0), ("glock", "E7", 0, 0.7, 40, 0.02))
    cue("shrine", ("harp", "E5 A5 C#6 E6 A6", 0.07, 1.2, 86, 0), ("celesta", "A6", 0, 0.8, 52, 0.28))
    cue("bell", ("church_bell", "G3", 0, 2.4, 110, 0), ("tubular", "G4", 0, 1.8, 70, 0))
    cue("camp_cleared", ("mandolin", "C5 E5 G5", 0.08, 0.6, 92, 0), ("whistle", "C6", 0, 0.5, 78, 0.24))
    cue("soak_ok", ("harp", "E5 B5", 0.0, 0.8, 92, 0), ("celesta", "B6", 0, 0.6, 54, 0))
    cue("heal", ("harp", "G5 D6", 0.1, 0.7, 88, 0), ("celesta", "D7", 0, 0.5, 50, 0.1))
    cue("perfect_guard", ("glock", "A6", 0, 0.8, 100, 0), ("tubular", "A5", 0, 1.0, 80, 0), ("celesta", "E7", 0, 0.6, 60, 0.01))
    cue("telegraph", ("bassoon", "A#2 A#2", 0.24, 0.16, 110, 0), ("pizz", "A#2 A#2", 0.24, 0.2, 96, 0))
    cue("soak_fail", ("bassoon", "G2 F#2", 0.22, 0.24, 104, 0))
    cue("refuse", ("bassoon", "G3 F#3", 0.09, 0.1, 96, 0))
    cue("equip", ("guitar", "E4 B4", 0.02, 0.4, 92, 0), ("pizz", "E3", 0, 0.3, 90, 0))
    cue("menu_move", ("celesta", "D6", 0, 0.12, 64, 0))
    cue("flow", ("celesta", "E6 A6", 0.04, 0.3, 80, 0))
    cue("knockdown", ("pizz", "C2", 0, 0.6, 120, 0), ("church_bell", "C3", 0, 1.0, 70, 0))
    shots[-1].part("drums").note(0, 0.5, BOOM, 124)
    shots[-1].part("drums").note(0, 0.5, KICK, 110)
    cue("gate", ("church_bell", "G2", 0, 2.0, 104, 0), ("tubular", "G4", 0, 1.0, 76, 1.0))
    shots[-1].part("drums").note(0, 0.5, BOOM, 110)
    return shots


# --- MIDI ------------------------------------------------------------------------------

def vlq(value: int) -> bytes:
    out = [value & 0x7F]
    value >>= 7
    while value:
        out.append((value & 0x7F) | 0x80)
        value >>= 7
    return bytes(reversed(out))


def chunk(tag: bytes, data: bytes) -> bytes:
    return tag + struct.pack(">I", len(data)) + data


def track(events: list[tuple[int, int, bytes]]) -> bytes:
    events.sort(key=lambda event: (event[0], event[1]))
    data = bytearray()
    now = 0
    for tick, _, message in events:
        data += vlq(tick - now) + message
        now = tick
    data += vlq(0) + b"\xff\x2f\x00"
    return chunk(b"MTrk", bytes(data))


def ticks(beats: float) -> int:
    return max(0, int(round(beats * PPQ)))


def cc(channel: int, number: int, value: int) -> bytes:
    return bytes([0xB0 | channel, number, max(0, min(127, int(value)))])


def sounding(part: Part, cycles: int, loop_beats: float) -> list[list]:
    """The part's notes unrolled over `cycles` loops: [start, end, pitch, vel] in beats, a note
    never overlapping the next of its pitch (MIDI can't tell them apart)."""
    notes: list[list] = []
    for cycle in range(cycles):
        offset = cycle * loop_beats
        for note in part.notes:
            start = note["start"] + note["jitter"] + offset
            end = note["start"] + offset + note["beats"] * note["gate"]
            notes.append([max(0.0, start), max(start + 0.02, end), note["pitch"], note["vel"]])
    notes.sort(key=lambda item: (item[0], item[2]))
    by_pitch: dict[int, list[list]] = {}
    for item in notes:
        by_pitch.setdefault(item[2], []).append(item)
    for same in by_pitch.values():
        for first, second in zip(same, same[1:]):
            if first[1] > second[0] - 0.01:
                first[1] = max(first[0] + 0.02, second[0] - 0.01)
    return notes


def expression(notes: list[list], channel: int, vibrato: bool, bpm: float) -> list[tuple[int, int, bytes]]:
    """CC11 swells over each phrase (an arch, with a lift on long notes) and CC1 vibrato that blooms
    after 0.2 s on notes long enough to hold it."""
    events: list[tuple[int, int, bytes]] = []
    phrases: list[list[list]] = []
    for item in notes:
        if phrases and item[0] <= max(other[1] for other in phrases[-1]) + 0.3:
            phrases[-1].append(item)
        else:
            phrases.append([item])
    for phrase in phrases:
        start = phrase[0][0]
        end = max(item[1] for item in phrase)
        span = max(end - start, 1e-6)
        last = -1
        at = start
        while at <= end:
            value = 82.0 + 32.0 * math.sin(math.pi * (at - start) / span) ** 0.8
            for item in phrase:
                if item[0] <= at < item[1] and item[1] - item[0] >= 1.4:
                    value += 7.0 * math.sin(math.pi * (at - item[0]) / (item[1] - item[0]))
            value = int(max(50, min(127, value)))
            if value != last:
                events.append((ticks(at), 2, cc(channel, 11, value)))
                last = value
            at += 0.125
    if vibrato:
        beat_sec = 60.0 / bpm
        for item in notes:
            events.append((ticks(item[0]), 2, cc(channel, 1, 0)))
            if (item[1] - item[0]) * beat_sec >= 0.45:
                for delay, depth in ((0.22, 26), (0.4, 48)):
                    events.append((ticks(item[0] + delay / beat_sec), 2, cc(channel, 1, depth)))
    return events


def write_midi(path: Path, piece: Piece, parts: list[Part], cycles: int, loop_beats: float, tail_beats: float) -> None:
    tempo = int(round(60_000_000 / piece.bpm))
    numerator, power = {"3/4": (3, 2), "6/8": (6, 3), "4/4": (4, 2)}[piece.meter]
    head = [(0, 0, b"\xff\x51\x03" + tempo.to_bytes(3, "big")), (0, 0, bytes([0xFF, 0x58, 4, numerator, power, 24, 8])),
            (ticks(cycles * loop_beats + tail_beats), 9, b"\xff\x01\x03end")]
    tracks = [track(head)]
    free = [channel for channel in range(16) if channel != 9]
    if sum(1 for part in parts if not part.inst.drum) > len(free):
        raise ValueError("too many parts for one MIDI file: %d" % len(parts))
    for part in parts:
        inst = part.inst
        channel = 9 if inst.drum else free.pop(0)
        events: list[tuple[int, int, bytes]] = []
        if not inst.drum:
            events += [(0, 0, cc(channel, 0, inst.bank)), (0, 0, cc(channel, 32, 0))]
        events += [(0, 0, bytes([0xC0 | channel, inst.program])), (0, 0, cc(channel, 7, part.volume)), (0, 0, cc(channel, 10, inst.pan)),
                   (0, 0, cc(channel, 91, inst.reverb)), (0, 0, cc(channel, 93, inst.chorus)), (0, 0, cc(channel, 11, 100)),
                   (0, 0, cc(channel, 1, 0))]
        notes = sounding(part, cycles, loop_beats)
        for start, end, pitch, vel in notes:
            on = ticks(start)
            events.append((on, 3, bytes([0x90 | channel, pitch, vel])))
            events.append((max(on + 1, ticks(end)), 1, bytes([0x80 | channel, pitch, 0])))
        if inst.legato:
            events += expression(notes, channel, inst.vibrato, piece.bpm)
        tracks.append(track(events))
    path.write_bytes(chunk(b"MThd", struct.pack(">HHH", 1, len(tracks), PPQ)) + b"".join(tracks))


# --- Rendering and mastering -----------------------------------------------------------

def run(command: list[str], data: bytes | None = None) -> subprocess.CompletedProcess:
    result = subprocess.run(command, input=data, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError("%s failed:\n%s" % (command[0], result.stderr.decode(errors="replace")[-2000:]))
    return result


def fluid_render(mid: Path, wav: Path) -> None:
    command = ["fluidsynth", "-n", "-i", "-q", "-g", "0.5", "-r", str(RATE), "-O", "float", "-T", "wav", "-F", str(wav)]
    for key, value in FLUID_SETTINGS.items():
        command += ["-o", "%s=%s" % (key, value)]
    run(command + [str(SOUNDFONT), str(mid)])


def read_f32(path: Path, channels: int) -> array.array:
    raw = run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", str(channels), "-ar", str(RATE), "-"]).stdout
    samples = array.array("f")
    samples.frombytes(raw)
    return samples


def loudness(samples: array.array, channels: int) -> tuple[float, float]:
    """Integrated loudness (LUFS) and true peak (dBTP), from ffmpeg's EBU R128 meter."""
    result = run(["ffmpeg", "-hide_banner", "-nostats", "-f", "f32le", "-ar", str(RATE), "-ac", str(channels), "-i", "-",
                  "-af", "loudnorm=print_format=json", "-f", "null", "-"], samples.tobytes())
    text = result.stderr.decode(errors="replace")
    report = json.loads(text[text.rfind("{"):text.rfind("}") + 1])
    return float(report["input_i"]), float(report["input_tp"])


def peak_db(samples: array.array) -> float:
    peak = max(max(samples), -min(samples)) if len(samples) else 0.0
    return 20.0 * math.log10(peak) if peak > 1e-9 else -120.0


def encode(samples: array.array, channels: int, gain_db: float, out: Path, codec: str, quality: str = OGG_QUALITY) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    source = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", str(channels), "-i", "-",
              "-af", "volume=%.3fdB" % gain_db, "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact"]
    if codec == "wav":
        run(source + ["-c:a", "pcm_s16le", str(out)], samples.tobytes())
        return
    with tempfile.TemporaryDirectory() as folder:
        master = Path(folder) / "master.wav"
        run(source + ["-c:a", "pcm_s24le", str(master)], samples.tobytes())
        run(["oggenc", "-Q", "-q", quality, "-s", OGG_SERIAL, "-o", str(out), str(master)])


def fold_seam(render: array.array, channels: int, start: int, end: int) -> array.array:
    """The loop [start, end) of a three-cycle render, its first SEAM_FADE samples crossfaded from
    what the render plays just after `end`, so the wrap is seamless sample for sample."""
    need = (end + SEAM_FADE) * channels
    if len(render) < need:
        render.extend([0.0] * (need - len(render)))
    loop = render[start * channels:end * channels]
    after = render[end * channels:(end + SEAM_FADE) * channels]
    for frame in range(SEAM_FADE):
        weight = frame / SEAM_FADE
        for channel in range(channels):
            index = frame * channels + channel
            loop[index] = after[index] * (1.0 - weight) + loop[index] * weight
    return loop


def trim(samples: array.array, channels: int) -> array.array:
    """A one-shot from its first sound to where its reverb falls under -54 dBFS, with a 120 ms fade."""
    frames = len(samples) // channels
    first = next((index for index, value in enumerate(samples) if value > 0.001 or value < -0.001), 0) // channels
    last = next((index for index in range(len(samples) - 1, -1, -1) if abs(samples[index]) > 0.002), len(samples) - 1) // channels
    first = max(0, first - 32)
    last = min(frames, last + RATE // 8)
    cut = samples[first * channels:last * channels]
    fade = min(RATE * 12 // 100, (last - first) // 2)
    total = len(cut) // channels
    for frame in range(fade):
        weight = frame / fade
        for channel in range(channels):
            cut[(total - 1 - frame) * channels + channel] *= weight
    return cut


def tempo_sec(bpm: float) -> float:
    """Seconds per beat as the MIDI file's whole-microsecond tempo plays it."""
    return round(60_000_000 / bpm) / 1_000_000


def bake_stem(suite: Suite, layer: int, work: Path) -> dict:
    loop = suite.loop_beats * tempo_sec(suite.bpm) * RATE
    start, end = int(round(loop)), int(round(2 * loop))
    mid = work / ("%s_%d.mid" % (suite.profile_id, layer))
    wav = work / ("%s_%d.wav" % (suite.profile_id, layer))
    write_midi(mid, suite, suite.stems[layer], 3, suite.loop_beats, 8.0 * suite.bpm / 60.0)
    fluid_render(mid, wav)
    samples = fold_seam(read_f32(wav, 2), 2, start, end)
    integrated, true_peak = loudness(samples, 2)
    gain = STEM_LUFS[layer] - integrated if math.isfinite(integrated) else 0.0
    gain = min(gain, TRUE_PEAK - true_peak)
    out = MUSIC / suite.profile_id / (STEM_FILES[layer] + ".ogg")
    encode(samples, 2, gain, out, "ogg")
    write_import(out, "oggvorbisstr", "AudioStreamOggVorbis", {"loop": "true", "loop_offset": "0", "bpm": _num(suite.bpm),
                 "beat_count": str(int(suite.loop_beats)), "bar_beats": str(suite.beats)})
    return {"file": str(out.relative_to(EVERWOOD)), "lufs": round(integrated + gain, 1), "true_peak": round(true_peak + gain, 1),
            "seconds": round((end - start) / RATE, 3), "notes": sum(len(part.notes) for part in suite.stems[layer])}


def bake_suite(suite: Suite, work: Path, pool: concurrent.futures.Executor) -> list[dict]:
    reports = list(pool.map(lambda layer: bake_stem(suite, layer, work), range(4)))
    score = {"profile_id": suite.profile_id, "bpm": suite.bpm, "beats_per_bar": suite.beats, "compound": suite.meter == "6/8",
             "bars": suite.bars, "stems": []}
    for parts in suite.stems:
        notes = []
        for part in parts:
            for note in part.notes:
                notes.append([round(note["start"], 4), round(note["beats"] * note["gate"], 4), note["pitch"], note["vel"], part.inst.voice])
        notes.sort(key=lambda item: (item[0], item[2]))
        score["stems"].append(notes)
    (MUSIC / suite.profile_id / "score.json").write_text(json.dumps(score, separators=(",", ":")) + "\n")
    preview(suite)
    return reports


def render_cell(cell: Suite, layer: int, work: Path) -> array.array:
    """One cell's stem: its four bars and TAIL_SEC of the notes and room ringing on, faded at the end."""
    name = cell.profile_id.replace("/", "_")
    mid = work / ("%s_%d.mid" % (name, layer))
    wav = work / ("%s_%d.wav" % (name, layer))
    write_midi(mid, cell, cell.stems[layer], 1, cell.loop_beats, 4.0 * cell.bpm / 60.0)
    fluid_render(mid, wav)
    samples = read_f32(wav, 2)
    body = int(round(cell.loop_beats * tempo_sec(cell.bpm) * RATE))
    total = body + int(TAIL_SEC * RATE)
    if len(samples) < total * 2:
        samples.extend([0.0] * (total * 2 - len(samples)))
    cut = samples[:total * 2]
    fade = int(TAIL_FADE_SEC * RATE)
    for frame in range(fade):
        weight = frame / fade
        cut[(total - 1 - frame) * 2] *= weight
        cut[(total - 1 - frame) * 2 + 1] *= weight
    return cut


def bake_mosaic(mosaic: Mosaic, work: Path, pool: concurrent.futures.Executor) -> list[dict]:
    """Every cell's four stems (one loudness per stem across the zone, so the moods keep their
    relative dynamics), the zone's score.json and its listening copy."""
    jobs = [(cell, layer) for cell in mosaic.cells for layer in range(4)]
    rendered = dict(zip(jobs, pool.map(lambda job: render_cell(job[0], job[1], work), jobs)))
    reports: list[dict] = []
    for layer in range(4):
        bodies = array.array("f")
        peak = -120.0
        for cell in mosaic.cells:
            samples = rendered[(cell, layer)]
            body = int(round(cell.loop_beats * tempo_sec(cell.bpm) * RATE))
            bodies.extend(samples[:body * 2])
            peak = max(peak, loudness(samples, 2)[1])
        integrated = loudness(bodies, 2)[0]
        gain = STEM_LUFS[layer] - integrated if math.isfinite(integrated) else 0.0
        gain = min(gain, TRUE_PEAK - peak)
        for cell in mosaic.cells:
            samples = rendered[(cell, layer)]
            out = MUSIC / cell.profile_id / (STEM_FILES[layer] + ".ogg")
            encode(samples, 2, gain, out, "ogg", MOSAIC_OGG_QUALITY[layer])
            write_import(out, "oggvorbisstr", "AudioStreamOggVorbis", {"loop": "false", "loop_offset": "0", "bpm": _num(cell.bpm),
                         "beat_count": str(int(cell.loop_beats)), "bar_beats": str(cell.beats)})
            reports.append({"file": str(out.relative_to(EVERWOOD)), "lufs": round(integrated + gain, 1), "true_peak": round(peak + gain, 1),
                            "seconds": round(len(samples) / 2 / RATE, 3), "notes": sum(len(part.notes) for part in cell.stems[layer])})
    # The score, cells end to end in suite order (ProceduralChamberSynth's fallback plays it as one loop).
    first = mosaic.cells[0]
    score = {"profile_id": mosaic.profile_id, "bpm": mosaic.bpm, "beats_per_bar": first.beats, "compound": mosaic.meter == "6/8",
             "bars": sum(cell.bars for cell in mosaic.cells), "stems": [[], [], [], []], "cells": []}
    offset = 0.0
    for cell in mosaic.cells:
        score["cells"].append({"id": cell.cell_id, "mood": cell.mood, "voice": cell.voice, "bars": cell.bars,
                               "chords": [chord.symbol for chord in cell.chords]})
        for layer, parts in enumerate(cell.stems):
            for part in parts:
                for note in part.notes:
                    score["stems"][layer].append([round(note["start"] + offset, 4), round(note["beats"] * note["gate"], 4), note["pitch"],
                                                  note["vel"], part.inst.voice])
        offset += cell.loop_beats
    for notes in score["stems"]:
        notes.sort(key=lambda item: (item[0], item[2]))
    (MUSIC / mosaic.profile_id / "score.json").write_text(json.dumps(score, separators=(",", ":")) + "\n")
    preview_mosaic(mosaic)
    return reports


def preview_mosaic(mosaic: Mosaic) -> None:
    """A listening copy (git-ignored): the twelve cells in suite order at their moods' mixes, each
    cell's tail ringing under the next, as the game chains them."""
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    command = ["ffmpeg", "-v", "error", "-y"]
    chains = []
    slot = 0
    at = 0.0
    for cell in mosaic.cells:
        for layer in (0, 1):
            command += ["-i", str(MUSIC / cell.profile_id / (STEM_FILES[layer] + ".ogg"))]
            delay = int(round(at * 1000))
            chains.append("[%d]adelay=%d|%d,volume=%.1fdB[s%d]" % (slot, delay, delay, MOOD_STEMS_DB[cell.mood][layer], slot))
            slot += 1
        at += cell.loop_beats * tempo_sec(cell.bpm)
    mix = ";".join(chains) + ";" + "".join("[s%d]" % index for index in range(slot)) + "amix=inputs=%d:normalize=0[out]" % slot
    run(command + ["-filter_complex", mix, "-map", "[out]", "-c:a", "aac", "-b:a", "192k",
                   str(PREVIEWS / ("%s_suite_order.m4a" % mosaic.profile_id))])


def bake_shot(shot: Shot, work: Path) -> dict:
    channels = 2 if shot.stereo else 1
    mid = work / (shot.name + ".mid")
    wav = work / (shot.name + ".wav")
    if shot.kind == "loop":
        loop = shot.loop_sec * RATE
        write_midi(mid, shot, shot.parts, 3, shot.loop_sec, 8.0)
        fluid_render(mid, wav)
        samples = fold_seam(read_f32(wav, channels), channels, int(round(loop)), int(round(2 * loop)))
        integrated, true_peak = loudness(samples, channels)
        gain = min(LOOP_LUFS - integrated, TRUE_PEAK - true_peak)
        out = SAMPLES / (shot.name + ".ogg")
        encode(samples, channels, gain, out, "ogg")
        write_import(out, "oggvorbisstr", "AudioStreamOggVorbis", {"loop": "true", "loop_offset": "0", "bpm": "0", "beat_count": "0", "bar_beats": "4"})
        return {"file": str(out.relative_to(EVERWOOD)), "lufs": round(integrated + gain, 1), "seconds": shot.loop_sec}
    length = max(note["start"] + note["beats"] for part in shot.parts for note in part.notes)
    write_midi(mid, shot, shot.parts, 1, length, 4.0)
    fluid_render(mid, wav)
    samples = trim(read_f32(wav, channels), channels)
    target = {"sample": SAMPLE_PEAK_DB, "cue": CUE_PEAK_DB}.get(shot.kind, STINGER_PEAK_DB)
    gain = target - peak_db(samples)
    if shot.name == "stinger_poise_stagger_lydian":
        out = SAMPLES / (shot.name + ".ogg")
        encode(samples, channels, gain, out, "ogg")
        write_import(out, "oggvorbisstr", "AudioStreamOggVorbis", {"loop": "false", "loop_offset": "0", "bpm": "0", "beat_count": "0", "bar_beats": "4"})
    else:
        out = SAMPLES / (shot.name + ".wav")
        encode(samples, channels, gain, out, "wav")
        write_import(out, "wav", "AudioStreamWAV", {"force/8_bit": "false", "force/mono": "false", "force/max_rate": "false",
                     "force/max_rate_hz": "44100", "edit/trim": "false", "edit/normalize": "false", "edit/loop_mode": "1",
                     "edit/loop_begin": "0", "edit/loop_end": "-1", "compress/mode": "0"})
    return {"file": str(out.relative_to(EVERWOOD)), "peak_db": round(peak_db(samples) + gain, 1),
            "seconds": round(len(samples) / channels / RATE, 2)}


def _num(value: float) -> str:
    return str(int(value)) if float(value).is_integer() else str(value)


def write_import(path: Path, importer: str, kind: str, params: dict[str, str]) -> None:
    """Godot's import settings for a baked file (a loop for stems, plain PCM for samples). An
    existing .import keeps its uid; Godot fills the rest in when it imports."""
    imported = path.with_name(path.name + ".import")
    if imported.exists():
        text = imported.read_text()
        for key, value in params.items():
            pattern = re.compile(r"^%s=.*$" % re.escape(key), re.M)
            if pattern.search(text):
                text = pattern.sub("%s=%s" % (key, value), text)
            else:
                text = text.rstrip("\n") + "\n%s=%s\n" % (key, value)
        imported.write_text(text)
        return
    body = "\n".join("%s=%s" % (key, value) for key, value in params.items())
    imported.write_text('[remap]\n\nimporter="%s"\ntype="%s"\n\n[params]\n\n%s\n' % (importer, kind, body))


def preview(suite: Suite) -> None:
    """Listening copies (git-ignored): the exploration mix and all four stems, each looped twice."""
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    folder = MUSIC / suite.profile_id
    mixes = {"explore": suite.explore_db, "all_stems": [0.0, 0.0, 0.0, 0.0], "skirmish": [0.0, -18.0, -3.0, 0.0]}
    if suite.profile_id == "cairnsmans_vigil":
        mixes = {"phase_one": suite.explore_db, "phase_two": [0.0, -80.0, 0.0, 0.0], "poise_stagger": [0.0, 0.0, -24.0, -14.0]}
    for label, volumes in mixes.items():
        command = ["ffmpeg", "-v", "error", "-y"]
        chains = []
        live = [layer for layer in range(4) if volumes[layer] > -79.0]
        for slot, layer in enumerate(live):
            command += ["-stream_loop", "1", "-i", str(folder / (STEM_FILES[layer] + ".ogg"))]
            chains.append("[%d]volume=%.1fdB[s%d]" % (slot, volumes[layer], slot))
        mix = ";".join(chains) + ";" + "".join("[s%d]" % slot for slot in range(len(live))) + "amix=inputs=%d:normalize=0[out]" % len(live)
        run(command + ["-filter_complex", mix, "-map", "[out]", "-c:a", "aac", "-b:a", "192k",
                       str(PREVIEWS / ("%s_%s.m4a" % (suite.profile_id, label)))])


# --- Checks ------------------------------------------------------------------------------

def spectral(path: Path) -> dict[str, float]:
    """Average spectral spread and flatness (ffmpeg's aspectralstats) over a file: a bare sine has
    almost no spread, white noise is flat, an acoustic ensemble is wide and far from flat."""
    result = run(["ffmpeg", "-v", "error", "-i", str(path), "-af",
                  "aformat=channel_layouts=mono,aspectralstats=measure=spread+flatness+centroid,ametadata=print:file=-", "-f", "null", "-"])
    sums: dict[str, list[float]] = {}
    for text in result.stdout.decode(errors="replace").splitlines():
        match = re.match(r"lavfi\.aspectralstats\.1\.(\w+)=(\S+)", text)
        if match and match.group(2) not in ("nan", "-nan", "inf"):
            sums.setdefault(match.group(1), []).append(float(match.group(2)))
    return {key: sum(values) / len(values) for key, values in sums.items() if values}


def probe(path: Path) -> dict:
    result = run(["ffprobe", "-v", "error", "-show_entries", "stream=codec_name,sample_rate,channels:format=duration", "-of", "json", str(path)])
    data = json.loads(result.stdout)
    stream = data["streams"][0]
    return {"codec": stream["codec_name"], "rate": int(stream["sample_rate"]), "channels": int(stream["channels"]),
            "seconds": float(data["format"]["duration"])}


def verify(reports: list[dict]) -> list[str]:
    """Every baked file decodes, isn't silent or clipped, and carries a wide acoustic spectrum."""
    problems: list[str] = []
    for report in reports:
        path = EVERWOOD / report["file"]
        info = probe(path)
        stats = spectral(path)
        report.update({"codec": info["codec"], "spread_hz": round(stats.get("spread", 0.0), 1), "flatness": round(stats.get("flatness", 1.0), 3)})
        if info["rate"] != RATE or info["seconds"] < 0.05:
            problems.append("%s: %d Hz, %.2f s" % (report["file"], info["rate"], info["seconds"]))
        if report.get("lufs", 0.0) < -40.0 or report.get("peak_db", 0.0) < -40.0:
            problems.append("%s is all but silent" % report["file"])
        if report.get("true_peak", -99.0) > -1.0 or report.get("peak_db", -99.0) > -0.5:
            problems.append("%s clips" % report["file"])
        if report["spread_hz"] < 150.0 or report["flatness"] > 0.5:
            problems.append("%s: spread %.0f Hz, flatness %.2f (not an acoustic ensemble)" % (report["file"], report["spread_hz"], report["flatness"]))
    return problems


# --- Main ----------------------------------------------------------------------------------

def ensure_tools() -> None:
    missing = [tool for tool in ("fluidsynth", "ffmpeg", "ffprobe", "oggenc") if shutil.which(tool) is None]
    if missing:
        sys.exit("Missing %s. On a Mac: brew install fluid-synth ffmpeg vorbis-tools" % ", ".join(missing))
    if not SOUNDFONT.exists():
        print("Fetching GeneralUser GS (32 MB) into %s ..." % SOUNDFONT.relative_to(EVERWOOD))
        SOUNDFONT.parent.mkdir(parents=True, exist_ok=True)
        part = SOUNDFONT.with_suffix(".part")
        urllib.request.urlretrieve(SOUNDFONT_URL, part)
        if part.read_bytes()[8:12] != b"sfbk":
            part.unlink()
            sys.exit("That download isn't a SoundFont.")
        part.rename(SOUNDFONT)


def godot_import() -> None:
    godot = shutil.which("godot")
    if godot is None:
        print("Godot isn't on PATH: open the project once (or run godot --headless --import) to import the audio.")
        return
    print("Importing into Godot ...")
    subprocess.run([godot, "--headless", "--path", str(EVERWOOD), "--import"], capture_output=True)
    result = subprocess.run([godot, "--headless", "--path", str(EVERWOOD), "-s", "res://tools/build_audio_resources.gd"],
                            capture_output=True, text=True)
    print("\n".join(line for line in result.stdout.splitlines() if line.startswith("[Audio]")))
    if result.returncode != 0:
        sys.exit("tools/build_audio_resources.gd failed:\n" + result.stdout[-2000:] + result.stderr[-2000:])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--only", action="append", help="bake only this suite (repeatable); skips the one-shots")
    parser.add_argument("--no-godot", action="store_true", help="don't import into Godot afterwards")
    args = parser.parse_args()
    ensure_tools()
    suites = [build() for build in SUITES]
    mosaics = [build() for build in MOSAICS]
    if args.only:
        suites = [suite for suite in suites if suite.profile_id in args.only]
        mosaics = [mosaic for mosaic in mosaics if mosaic.profile_id in args.only]
    reports: list[dict] = []
    with tempfile.TemporaryDirectory() as folder, concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        work = Path(folder)
        for suite in suites:
            print("Baking %s (%d bars of %s at %s BPM) ..." % (suite.profile_id, suite.bars, suite.meter, _num(suite.bpm)))
            reports += bake_suite(suite, work, pool)
        for mosaic in mosaics:
            print("Baking the %s mosaic (%d four-bar cells of %s at %s BPM) ..." % (mosaic.profile_id, len(mosaic.cells), mosaic.meter,
                                                                                  _num(mosaic.bpm)))
            reports += bake_mosaic(mosaic, work, pool)
        if not args.only:
            shots = one_shots()
            print("Baking %d one-shots and loops ..." % len(shots))
            reports += list(pool.map(lambda shot: bake_shot(shot, work), shots))
    problems = verify(reports)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    (PREVIEWS / "bake_report.json").write_text(json.dumps(reports, indent=1) + "\n")
    for report in reports:
        if "stem_" in report["file"]:
            print("  %-62s %6.2f s  %5.1f LUFS  %5.1f dBTP  spread %6.0f Hz  flatness %.2f" % (
                report["file"], report["seconds"], report["lufs"], report["true_peak"], report["spread_hz"], report["flatness"]))
    print("%d files baked; listening copies in %s" % (len(reports), PREVIEWS.relative_to(EVERWOOD)))
    if problems:
        sys.exit("Problems:\n  " + "\n  ".join(problems))
    if not args.no_godot:
        godot_import()


if __name__ == "__main__":
    main()
