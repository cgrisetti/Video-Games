## One narration caption of a film (docs/31): its words and when they show, on the
## film's own clock in seconds. Read from the timeline JSON by CinematicCatalog; the
## film's .srt holds the same words and times (the checks compare them).
class_name CinematicCaptionResource
extends Resource

@export var start_s: float = 0.0
@export var end_s: float = 0.0
@export_multiline var text: String = ""


static func make(from_s: float, to_s: float, words: String) -> CinematicCaptionResource:
	var caption: CinematicCaptionResource = CinematicCaptionResource.new()
	caption.start_s = from_s
	caption.end_s = to_s
	caption.text = words
	return caption


func covers(at_s: float) -> bool:
	return at_s >= start_s and at_s < end_s
