## The Mood State Machine of a Chamber-Folk Audio Mosaic (16_ADAPTIVE_AUDIO_ARCHITECTURE.md
## §7.1-7.2): at every phrase boundary it picks the zone's next four-bar cell, walking a
## weighted Markov chain through the six moods (Wonder, Interest, Mellow, Peace,
## Curiosity, Anxiousness), nudged by where the party is and what it's doing.
##
## Its rules, so the score never sounds like a loop:
##   1. never the same cell twice in a row (its chords, mood and lead voice);
##   2. the lead voice changes at every phrase (the Hisaishi Quartet trading the tune);
##   3. no mood holds more than two phrases (bar the Peace breath and a held threat);
##   4. a mood heard in the last four phrases is unlikely to come straight back;
##   5. two phrases never repeat as an eight-bar pair (A B A B).
## Context: hearths, springs, shrines and towns favour Peace, Mellow and Wonder; the wild
## edges, holloways and galleries favour Curiosity, Interest and Anxiousness; high ground
## lifts Wonder; sprinting quickens Interest and standing still settles into Peace. An
## awake foe within 35 m (the Proximity Pre-Warm) turns the next phrase to Anxiousness,
## a fight keeps to the driving moods, and the phrases after a fight's exhale ease into
## Mellow or Peace. Every so often Peace opens the Emergent Silence breath: two to four
## Peace cells with the melody gone and the harp fading, then the music re-emerges.
##
## Pure logic over a ZoneMusicProfileResource's cells with its own seeded generator, so
## the same seed and contexts always give the same phrases (tests rely on it).
class_name MusicMoodEngine
extends RefCounted

## Base weights from a mood (row) to the next (column), in MoodState order:
## WONDER, INTEREST, MELLOW, PEACE, CURIOSITY, ANXIOUSNESS. The brief's walk is
## Peace -> Wonder -> Interest -> Curiosity -> Mellow -> Peace, with Curiosity <-> Anxiousness.
const MARKOV: Array[Array] = [
	[0.0, 0.45, 0.15, 0.15, 0.25, 0.0],
	[0.25, 0.0, 0.2, 0.05, 0.4, 0.1],
	[0.2, 0.15, 0.0, 0.45, 0.2, 0.0],
	[0.45, 0.15, 0.25, 0.0, 0.15, 0.0],
	[0.25, 0.25, 0.35, 0.0, 0.0, 0.15],
	[0.15, 0.1, 0.3, 0.0, 0.45, 0.0],
]
## Weight for staying in the mood (its other cell) instead of moving on.
const STAY_WEIGHT: float = 0.35
## A mood plays at most this many phrases in a row (rule 3).
const MAX_MOOD_PHRASES: int = 2
## Moods heard within this many phrases come back at this share of their weight (rule 4).
const RECENT_PHRASES: int = 4
const RECENCY: float = 0.12
## Entering a mood on its second cell instead of its first.
const SECOND_ENTRY: float = 0.6
## The fight's moods (Skirmish): the driving ones.
const FIGHT_MOODS: Array[int] = [ZoneMusicProfileResource.MoodState.INTEREST, ZoneMusicProfileResource.MoodState.CURIOSITY,
	ZoneMusicProfileResource.MoodState.ANXIOUSNESS]
## Each mood's stems in exploration (dB): FOLK_BASE, PASTORAL_LEAD, HOLLOWAY_DISCORD, SKIRMISH_DRIVE.
const MOOD_STEMS_DB: Array[Array] = [
	[0.0, 0.0, -80.0, -80.0],
	[0.0, -1.0, -80.0, -80.0],
	[-1.5, -1.0, -80.0, -80.0],
	[-2.0, -1.5, -80.0, -80.0],
	[-1.0, 0.0, -24.0, -80.0],
	[-2.0, -2.5, -12.0, -80.0],
]
## Anxiousness swells the Holloway discord from -12 dB to this as the foe comes from 35 m to 14 m.
const ANXIOUS_DISCORD_FULL_DB: float = -4.0
## The Emergent Silence breath: its first cell's harp at this level, each later one this much lower.
const BREATH_BASE_DB: float = -14.0
const BREATH_STEP_DB: float = 6.0
const BREATH_MIN_CELLS: int = 2
const BREATH_MAX_CELLS: int = 4
## Pulls toward Peace once a breath is due, and toward Wonder as the music re-emerges.
const BREATH_DUE_PULL: float = 4.0
const EMERGE_PULL: float = 5.0
const HISTORY_SIZE: int = 16
const MUTED_DB: float = -80.0


## What the party is doing and where, sampled each heartbeat (0..1 unless a flag).
class Context:
	## By a hearth: a campfire, a warm spring, a water-shrine or a wind-lantern.
	var hearth: float = 0.0
	## In a town, market, quay, landing or orchard.
	var settled: float = 0.0
	## Out on the island's wild edges and places (strait shores, cliffs, grottos, the Ring Path).
	var wild: float = 0.0
	## High ground: 0 at the shore, 1 well above it.
	var height: float = 0.0
	## Below ground or down a holloway.
	var underground: float = 0.0
	## Standing still a while.
	var still: float = 0.0
	## Sprinting.
	var hurry: float = 0.0
	## An awake foe within 35 m (Stage A, the Proximity Pre-Warm).
	var threat: bool = false
	## A skirmish or boss fight.
	var fighting: bool = false
	## The phrases just after a fight's exhale.
	var relief: bool = false

	func calm() -> float:
		return maxf(hearth, settled)


var profile: ZoneMusicProfileResource
## The cell playing now (an index into profile.mosaic_cells) and those before it, oldest first.
var current_cell: int = -1
var history: PackedInt32Array = PackedInt32Array()
## The next cell as last chosen (-1 before the choice), and whether it's a breath cell.
var chosen_cell: int = -1
## The breath step of the cell playing (0 = its first breath cell), or -1 when it isn't one.
var breath_step: int = -1
var phrases_since_breath: int = 0
var breaths: int = 0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _moods: PackedInt32Array = PackedInt32Array()
var _breath_left: int = 0
var _chosen_breath_step: int = -1
var _chosen_breath_left: int = 0
var _emerging: bool = false


## Starts over on a zone's cells; returns the cell to open on.
func reset(zone: ZoneMusicProfileResource, seed_value: int, context: Context = null) -> int:
	profile = zone
	_rng.seed = seed_value
	history = PackedInt32Array()
	_moods = PackedInt32Array()
	current_cell = -1
	chosen_cell = -1
	breath_step = -1
	_breath_left = 0
	_chosen_breath_step = -1
	_emerging = false
	phrases_since_breath = 0
	var first: int = clampi(zone.opening_cell, 0, zone.mosaic_cells.size() - 1)
	if context != null and context.threat:
		first = _first_of(ZoneMusicProfileResource.MoodState.ANXIOUSNESS, first)
	elif context != null and context.relief:
		first = _first_of(ZoneMusicProfileResource.MoodState.MELLOW, first)
	commit(first)
	return first


## The cell playing now.
func cell() -> MosaicCellResource:
	return profile.cell(current_cell) if profile != null else null


func mood() -> int:
	var playing: MosaicCellResource = cell()
	return playing.mood if playing != null else -1


func lead_voice() -> int:
	var playing: MosaicCellResource = cell()
	return playing.lead_voice if playing != null else -1


func in_breath() -> bool:
	return breath_step >= 0


## The breath step the chosen next cell will play at (-1 when it isn't a breath cell).
func chosen_breath_step() -> int:
	return _chosen_breath_step


## Whether the next Peace phrase opens the silence breath.
func breath_due() -> bool:
	return profile != null and phrases_since_breath * profile.cell_sec() >= profile.music_cycle_sec


## Chooses the cell to follow the one playing (it can be asked again before the phrase ends,
## when the context changes). Returns its index.
func choose_next(context: Context) -> int:
	_chosen_breath_step = -1
	_chosen_breath_left = 0
	if profile == null or profile.mosaic_cells.size() < 2:
		chosen_cell = current_cell
		return chosen_cell
	var calm_now: bool = not context.threat and not context.fighting
	# The breath carries on through the Peace cells, its harp fading, unless a threat breaks it.
	if calm_now and (_breath_left > 0 or (mood() == ZoneMusicProfileResource.MoodState.PEACE and breath_step < 0 and breath_due())):
		var partner: int = _partner(current_cell)
		if partner >= 0:
			var left: int = _breath_left if _breath_left > 0 else _breath_length()
			_chosen_breath_step = breath_step + 1
			_chosen_breath_left = left - 1
			chosen_cell = partner
			return chosen_cell
	if context.threat:
		chosen_cell = _forced(context)
		return chosen_cell
	chosen_cell = _weighted(context)
	return chosen_cell


## The cell that is now playing (the one chosen, or another if the audio played something else).
func commit(index: int) -> void:
	var taken: bool = index == chosen_cell and chosen_cell >= 0
	current_cell = index
	history.append(index)
	if history.size() > HISTORY_SIZE:
		history = history.slice(history.size() - HISTORY_SIZE)
	var playing: MosaicCellResource = cell()
	_moods.append(playing.mood if playing != null else -1)
	if _moods.size() > HISTORY_SIZE:
		_moods = _moods.slice(_moods.size() - HISTORY_SIZE)
	breath_step = _chosen_breath_step if taken else -1
	_breath_left = _chosen_breath_left if taken and breath_step >= 0 else 0
	if breath_step >= 0:
		if breath_step == 0:
			breaths += 1
		phrases_since_breath = 0
		# The breath's last cell: the phrase after it re-emerges, most likely in Wonder.
		_emerging = _breath_left == 0
	else:
		phrases_since_breath += 1
		_emerging = false
	chosen_cell = -1
	_chosen_breath_step = -1
	_chosen_breath_left = 0


## The stems' exploration levels for the cell playing (dB): its mood's mix, Anxiousness
## swelling the discord with the threat, or the breath's fading harp.
func stem_targets(proximity: float) -> PackedFloat32Array:
	return stem_targets_for(current_cell, breath_step, proximity)


## The same for any cell of the zone (the one chosen next, at its breath step or -1).
func stem_targets_for(index: int, step: int, proximity: float) -> PackedFloat32Array:
	var playing: MosaicCellResource = profile.cell(index) if profile != null else null
	if playing == null:
		return PackedFloat32Array([0.0, 0.0, MUTED_DB, MUTED_DB])
	if step >= 0:
		return PackedFloat32Array([BREATH_BASE_DB - BREATH_STEP_DB * step, MUTED_DB, MUTED_DB, MUTED_DB])
	var levels: PackedFloat32Array = PackedFloat32Array()
	for value: Variant in MOOD_STEMS_DB[playing.mood]:
		levels.append(float(value))
	if playing.mood == ZoneMusicProfileResource.MoodState.ANXIOUSNESS:
		levels[2] = lerpf(float(MOOD_STEMS_DB[playing.mood][2]), ANXIOUS_DISCORD_FULL_DB, clampf(proximity, 0.0, 1.0))
	return levels


## A phrase's signature (its mood, lead voice and stem levels), for checks and the log.
func signature(levels: PackedFloat32Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for value: float in levels:
		parts.append("%.0f" % value)
	return "%s/%s/%s" % [ZoneMusicProfileResource.mood_name(mood()), lead_voice(), "/".join(parts)]


## How many phrases in a row the current mood has played.
func mood_run() -> int:
	var run: int = 0
	var now: int = mood()
	for index: int in range(_moods.size() - 1, -1, -1):
		if _moods[index] != now:
			break
		run += 1
	return run


# --- Choosing -----------------------------------------------------------------------

func _weighted(context: Context) -> int:
	# Rules 1-5 first; if nothing passes, ease off rule 5, then 3 and 4, then everything but rule 1.
	for strictness: int in [3, 2, 1]:
		var picks: Array[int] = []
		var weights: PackedFloat32Array = PackedFloat32Array()
		for index: int in profile.mosaic_cells.size():
			if not _allowed(index, strictness):
				continue
			var weight: float = _weight(index, context, strictness >= 2)
			if weight > 0.0:
				picks.append(index)
				weights.append(weight)
		if not picks.is_empty():
			return picks[_rng.rand_weighted(weights)]
	return _any_but_current()


## Rule checks: 1 (another cell) always; 2 (another lead voice) unless strictness is 1;
## 5 (no A B A B) at strictness 3.
func _allowed(index: int, strictness: int) -> bool:
	if index == current_cell:
		return false
	var next: MosaicCellResource = profile.cell(index)
	var playing: MosaicCellResource = cell()
	if strictness >= 2 and playing != null and next.lead_voice == playing.lead_voice:
		return false
	if strictness >= 3 and history.size() >= 3 and history[history.size() - 3] == current_cell and history[history.size() - 2] == index:
		return false
	return true


func _weight(index: int, context: Context, with_variety: bool) -> float:
	var next: MosaicCellResource = profile.cell(index)
	var now: int = mood()
	var weight: float
	if next.mood == now:
		weight = STAY_WEIGHT if mood_run() < MAX_MOOD_PHRASES or not with_variety else 0.0
	else:
		weight = float(MARKOV[now][next.mood]) if now >= 0 else 1.0
		if with_variety and _recent(next.mood):
			weight *= RECENCY
		if next.half == MosaicCellResource.Half.SECOND:
			weight *= SECOND_ENTRY
	weight *= _bias(next.mood, context)
	if next.mood == ZoneMusicProfileResource.MoodState.PEACE and breath_due() and not context.threat:
		weight *= BREATH_DUE_PULL
	if next.mood == ZoneMusicProfileResource.MoodState.WONDER and _emerging:
		weight *= EMERGE_PULL
	return weight


## The context's nudge on a mood's weight.
func _bias(mood_id: int, context: Context) -> float:
	var calm: float = context.calm()
	var bias: float = 1.0
	match mood_id:
		ZoneMusicProfileResource.MoodState.WONDER:
			bias *= (1.0 + 0.8 * calm) * (1.0 + 2.0 * context.height) * (1.0 + 0.4 * context.hurry) * (1.0 - 0.7 * context.underground)
		ZoneMusicProfileResource.MoodState.INTEREST:
			bias *= (1.0 + 0.8 * context.wild) * (1.0 + 1.2 * context.hurry)
		ZoneMusicProfileResource.MoodState.MELLOW:
			bias *= (1.0 + 1.2 * calm) * (1.0 + 0.8 * context.still) * (3.0 if context.relief else 1.0)
		ZoneMusicProfileResource.MoodState.PEACE:
			bias *= (1.0 + 2.0 * calm) * (1.0 + 1.0 * context.still) * (1.0 - 0.6 * context.wild) * (1.0 - 0.6 * context.hurry) \
				* (1.0 - 0.8 * context.underground) * (2.0 if context.relief else 1.0)
		ZoneMusicProfileResource.MoodState.CURIOSITY:
			bias *= (1.0 - 0.5 * calm) * (1.0 + 1.5 * context.wild) * (1.0 + 1.5 * context.underground)
		ZoneMusicProfileResource.MoodState.ANXIOUSNESS:
			bias *= (1.0 - 0.8 * calm) * (1.0 + 1.2 * context.wild) * (1.0 + 2.0 * context.underground) * (0.0 if context.relief else 1.0)
	if context.fighting:
		bias *= (1.5 if mood_id == ZoneMusicProfileResource.MoodState.ANXIOUSNESS else 1.0) if FIGHT_MOODS.has(mood_id) else 0.0
	return maxf(bias, 0.0)


## A held threat: Anxiousness whenever the rules allow it, else Curiosity, its darker sibling.
func _forced(context: Context) -> int:
	# Every rule first (Curiosity before an A B A B of the two Anxiousness cells), then without rule 5.
	for strictness: int in [3, 2]:
		for wanted: int in [ZoneMusicProfileResource.MoodState.ANXIOUSNESS, ZoneMusicProfileResource.MoodState.CURIOSITY]:
			var picks: Array[int] = []
			for index: int in profile.mosaic_cells.size():
				if profile.cell(index).mood == wanted and _allowed(index, strictness):
					picks.append(index)
			if not picks.is_empty():
				return picks[_rng.randi_range(0, picks.size() - 1)]
	return _weighted(context)


func _recent(mood_id: int) -> bool:
	var count: int = 0
	for index: int in range(_moods.size() - 1, -1, -1):
		if count >= RECENT_PHRASES:
			break
		count += 1
		if _moods[index] == mood_id:
			return true
	return false


## The other cell of the playing cell's mood (-1 if it has none).
func _partner(index: int) -> int:
	var playing: MosaicCellResource = profile.cell(index)
	if playing == null:
		return -1
	for other: int in profile.mosaic_cells.size():
		if other != index and profile.cell(other).mood == playing.mood:
			return other
	return -1


func _first_of(mood_id: int, otherwise: int) -> int:
	for index: int in profile.mosaic_cells.size():
		var each: MosaicCellResource = profile.cell(index)
		if each.mood == mood_id and each.half == MosaicCellResource.Half.FIRST:
			return index
	return otherwise


func _breath_length() -> int:
	var span: Vector2 = profile.silence_interval_range_sec
	var seconds: float = _rng.randf_range(span.x, span.y)
	return clampi(roundi(seconds / maxf(profile.cell_sec(), 0.1)), BREATH_MIN_CELLS, BREATH_MAX_CELLS)


func _any_but_current() -> int:
	return (current_cell + 1 + _rng.randi_range(0, profile.mosaic_cells.size() - 2)) % profile.mosaic_cells.size()
