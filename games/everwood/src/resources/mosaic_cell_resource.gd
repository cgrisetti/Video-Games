## One phrase cell of a zone's Chamber-Folk Audio Mosaic (16_ADAPTIVE_AUDIO_ARCHITECTURE.md
## §7): a four-bar phrase in one of the six moods, its lead carried by one of the four
## Hisaishi Quartet voicings, baked by tools/build_audio_stems.py as its own four
## phase-locked stems (res://assets/audio/music/<profile_id>/<cell_id>/stem_*.ogg). The
## stems hold the four bars and then let their last notes and the room ring on, so the
## next cell starts on the bar line while this one's tail fades under it.
##
## Pure data. ZoneMusicProfileResource lists a zone's cells, MusicMoodEngine picks which
## plays next at each phrase boundary, and AudioDirector chains them sample-accurately
## in an AudioStreamInteractive.
class_name MosaicCellResource
extends Resource

## Which half of its mood's pair a cell is: each mood has two cells with different leads.
enum Half { FIRST = 0, SECOND = 1 }

## The cell's folder under its zone's music folder, and its clip name.
@export var cell_id: StringName = &""
@export var mood: ZoneMusicProfileResource.MoodState = ZoneMusicProfileResource.MoodState.WONDER
@export var half: Half = Half.FIRST
## The Hisaishi Quartet voicing that carries the lead.
@export var lead_voice: ZoneMusicProfileResource.LeadVoice = ZoneMusicProfileResource.LeadVoice.OCEAN_VIEW
## The lead's instruments as the F4 line shows them ("Violin/Harp").
@export var voice_label: String = ""
## The chord cell (the A-F cells of the mosaic suite) and its chords, one per bar.
@export var chord_cell: StringName = &"A"
@export var chords: PackedStringArray = PackedStringArray()
## The cell's own key and mode ("E_DORIAN"), for the F4 line.
@export var mode_label: StringName = &""
@export var bars: int = 4
## The cell that follows when nothing chooses one (the suite order); -1 for the next in the list.
@export var fallback_next: int = -1


func describe() -> String:
	return "%s (%s · %s)" % [cell_id, ZoneMusicProfileResource.mood_name(mood), voice_label]
