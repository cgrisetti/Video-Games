## The playing deck's beat grid (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §7.3): seconds since
## the deck's first downbeat, read as beats, bars and phrases. AudioDirector advances it
## every frame and it says when a bar or a phrase begins; MusicMoodEngine chooses the
## next phrase cell in the last bar of each phrase, and stingers wait for its next eighth
## note or bar line.
##
## The grid is the director's own time, so a headless run (no audio playing) keeps the
## same bars. With a mosaic actually playing, AudioDirector lines the grid up with the
## audio each time a new cell starts (nudge()), so frame time never drifts from it.
class_name MusicalClock
extends RefCounted

signal bar_started(bar: int)
signal phrase_started(phrase: int)

var bpm: float = 108.0
var beats_per_bar: int = 3
var phrase_bars: int = 4
## Seconds since the first downbeat.
var elapsed: float = 0.0
## The bar and phrase now playing (from 0).
var bar: int = 0
var phrase: int = 0


func _init(tempo: float = 108.0, beats: int = 3, bars_per_phrase: int = 4) -> void:
	setup(tempo, beats, bars_per_phrase)


## Starts the grid over at a downbeat.
func setup(tempo: float, beats: int, bars_per_phrase: int) -> void:
	bpm = maxf(tempo, 1.0)
	beats_per_bar = maxi(1, beats)
	phrase_bars = maxi(1, bars_per_phrase)
	elapsed = 0.0
	bar = 0
	phrase = 0


func beat_sec() -> float:
	return 60.0 / bpm


func bar_sec() -> float:
	return beat_sec() * beats_per_bar


func phrase_sec() -> float:
	return bar_sec() * phrase_bars


## Moves the grid on by `delta` seconds, saying each bar and phrase that begins.
func advance(delta: float) -> void:
	elapsed += maxf(delta, 0.0)
	_announce()


## Shifts the grid by `seconds` (positive: the music is further on than the grid thought).
func nudge(seconds: float) -> void:
	elapsed = maxf(0.0, elapsed + seconds)
	_announce()


## Seconds since the current phrase began.
func phrase_elapsed() -> float:
	return elapsed - phrase * phrase_sec()


## Seconds until the next phrase begins.
func seconds_to_phrase_end() -> float:
	return (phrase + 1) * phrase_sec() - elapsed


## The bar within the current phrase (0 to phrase_bars - 1).
func bar_in_phrase() -> int:
	return bar - phrase * phrase_bars


## Seconds from now to the next multiple of `beats` (0.5: the next eighth note; a bar's beats: the next bar line).
func seconds_to_next(beats: float) -> float:
	var step: float = beat_sec() * maxf(beats, 0.001)
	return ceilf(elapsed / step - 0.0001) * step - elapsed


func _announce() -> void:
	var now_bar: int = floori(elapsed / bar_sec() + 0.000001)
	while bar < now_bar:
		bar += 1
		bar_started.emit(bar)
		if bar % phrase_bars == 0:
			phrase = floori(bar / float(phrase_bars))
			phrase_started.emit(phrase)
	# A nudge backwards (rare) just re-reads where the grid is.
	if now_bar < bar:
		bar = now_bar
		phrase = floori(bar / float(phrase_bars))
