## One zone of the Six-Zone Stewardship Atlas (15_THE_MYTHOPOETIC_LENS.md §5):
## its Map-Sense name, its Cooper Sign, the crack the First-Quiet rises through,
## the kin it wakes, and the nursery rhyme the Chime-Post ribbon sings there.
## Pure data; MythopoeticAtlas registers the six.
class_name StewardshipZoneResource
extends Resource

@export var zone_id: StringName = &""
## The Map-Sense compound ("Tizzi-Wed-Green").
@export var display_name: String = ""
## Its Cooper Sign ("Sign of Wood").
@export var cooper_sign: String = ""
## The Scribe Signs in harmony there (ScribeSignResource.Sign).
@export var harmony_signs: Array[int] = []
## Where the First-Quiet rises ("Hollow oak roots, loose cellar flagstones").
@export var crack: String = ""
## The kin it wakes there.
@export var kin: String = ""
## The village rhyme, four lines: two couplets.
@export var rhyme_lines: PackedStringArray = PackedStringArray()
## Words in the rhyme tinted by the Sign they coach (phrase -> ScribeSignResource.Sign).
@export var tinted_phrases: Dictionary[String, int] = {}
## How the stewards win there, in a line.
@export var payoff: String = ""


func couplet_count() -> int:
	return rhyme_lines.size() / 2


## Couplet `index` (wrapping) as two plain lines.
func couplet(index: int) -> String:
	if rhyme_lines.size() < 2:
		return ""
	var first: int = (index % couplet_count()) * 2
	return "%s\n%s" % [rhyme_lines[first], rhyme_lines[first + 1]]


## Couplet `index` with its coaching words tinted by Sign, as BBCode.
func couplet_bbcode(index: int, sign_colors: Dictionary[int, Color]) -> String:
	var text: String = couplet(index)
	for phrase: String in tinted_phrases:
		var color: Color = sign_colors.get(tinted_phrases[phrase], Color.WHITE)
		text = text.replace(phrase, "[color=#%s]%s[/color]" % [color.to_html(false), phrase])
	return text


## The Sign a phrase of the rhyme is tinted with (ScribeSignResource.Sign.NONE when untinted).
func phrase_sign(phrase: String) -> int:
	return tinted_phrases.get(phrase, ScribeSignResource.Sign.NONE)
