## One audio cue of a film (docs/31): an id the adaptive score can hook a sound to, and
## when it falls on the film's clock. There are no film sounds yet: the film posts each
## cue to AudioDirector.post_cinematic_cue at its time and plays nothing.
class_name CinematicCueResource
extends Resource

## The contract with the score ("mus_bassoon_harp_pickup", "sfx_quill_scratch" ...).
@export var cue_id: StringName = &""
@export var at_s: float = 0.0


static func make(id: StringName, when_s: float) -> CinematicCueResource:
	var cue: CinematicCueResource = CinematicCueResource.new()
	cue.cue_id = id
	cue.at_s = when_s
	return cue
