# Everwood's baked audio

Everything in this folder is made by `tools/build_audio_stems.py`. Don't edit these files by hand: change the composition or the instruments in that script and bake again.

```
python3 tools/build_audio_stems.py
```

It composes each zone's suite as MIDI, renders it through FluidSynth with the GeneralUser GS SoundFont, masters it with ffmpeg and oggenc, imports the files into Godot and writes each zone's `music/<profile_id>_sync.tres`. It needs `fluidsynth`, `ffmpeg` and `oggenc` (on a Mac: `brew install fluid-synth ffmpeg vorbis-tools`). It downloads the SoundFont (32 MB) into `tools/soundfonts/` the first time; git ignores that folder. A full bake takes about a minute. Listening copies of every zone's mixes land in `tools/audio_previews/` (also ignored) as `.m4a` files that play in Finder.

- `music/<profile_id>/stem_0_folk_base.ogg` to `stem_3_skirmish_drive.ogg`: the four phase-locked layers of a zone's music, Ogg Vorbis, looping without a seam.
- `music/<profile_id>/score.json`: the same arrangement as notes. `ProceduralChamberSynth` plays it on its physical models if the stems are missing.
- `music/<profile_id>_sync.tres`: the four stems as one `AudioStreamSynchronized`, which `AudioDirector` loads first.
- `samples/sample_*.wav`: single acoustic notes that the game re-pitches to build short phrases, such as a Calling's motif.
- `samples/sign_*.wav`, `samples/stinger_*`: the Four Signs' chords and the cadences and fanfares. These are baked over G and re-pitched to each zone's key, except the gate's fanfare, the portal's chord and the Cairnsman's flourish, which play as baked.
- `samples/ambience_*.ogg`: the Chime-Shrine's carillon and the Co-Op Gate's two plate harmonies, as loops.
- `samples/cue_*.wav`: the musical sounds `AudioCues` plays (chimes, rewards, the victory, bells, warnings).

## Credits

The instruments are the GeneralUser GS SoundFont v2.0.3 by S. Christian Collins (https://www.schristiancollins.com/generaluser). Its license allows use without restriction in music and software, including commercial use.
