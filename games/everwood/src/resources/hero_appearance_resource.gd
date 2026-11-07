## How one hero looks (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md §1.3, §5.4):
## a Calling's headgear, beard, pauldrons and belt trinket, painted in the
## 60-30-10 Three-Value Harmony so every hero pops off the mid-value turf and
## flagstones in a four-way split-screen:
##   Value 1 (60%, luminance 0.16-0.38)  the grounded base: heritage wool coat,
##                                        bog-leather boots and breeches
##   Value 2 (30%, luminance 0.45-0.74)  tactile craft: hewn timber, oiled
##                                        leather, the Fellowship tunic, the
##                                        Calling's tabard
##   Value 3 (10%, luminance 0.78 up)    the Scribe Sign and Calling spark:
##                                        brass, Sign veins and the face
##
## The ArsenalCatalog registers one per Calling (its silhouette) and four
## heritage dye presets for couch co-op, so two siblings playing the same
## Calling still read apart (HeroAppearanceResource.with_dye). HeroMeshAtelier
## sculpts the hero from it; storybook_hero_atelier.gdshader paints it.
class_name HeroAppearanceResource
extends Resource

## The Three-Value Harmony's bands (relative luminance, Color.get_luminance()).
const VALUE_1_LUMINANCE_MIN: float = 0.16
const VALUE_1_LUMINANCE_MAX: float = 0.38
const VALUE_2_LUMINANCE_MIN: float = 0.45
const VALUE_2_LUMINANCE_MAX: float = 0.74
const VALUE_3_LUMINANCE_MIN: float = 0.78
const VALUE_3_EMISSION_MULT: float = 1.80

## The hero's build (§2.1): 4.5 heads to the crown at 1.75 m, a raised hood's peak at 1.85 m.
const HEADS_TALL: float = 4.5
const CROWN_HEIGHT_M: float = 1.75
const HOOD_PEAK_M: float = 1.85

## The Level 1 youth (21_WINGFEATHER_YOUTH_HERO.md; the Equipment & Grimoire
## doc §2): a 14-year-old on the same 24-bone skeleton drawn at 0.9, the head
## sculpted 1.18x round the neck joint and the hands and feet 1.22x round their
## joints, about 5.5 heads tall to a 1.6 m crown.
const BODY_ADULT: StringName = &"adult"
const BODY_YOUTH: StringName = &"youth_wingfeather"
const YOUTH_SKELETON_SCALE: float = 0.9
const YOUTH_HEAD_SCALE: float = 1.18
const YOUTH_EXTREMITY_SCALE: float = 1.22
const YOUTH_HEADS_TALL: float = 5.5
## The two Level 1 youths (docs/26 §7).
const YOUTH_BOY: StringName = &"boy"
const YOUTH_GIRL: StringName = &"girl"

## The four headgear styles.
const HEADGEAR_STYLES: Array[StringName] = [&"wayfarer_hood_up", &"hood_back_shaved_crown", &"stout_kettle_cap", &"scribe_feather_hat"]
const HEADGEAR_NAMES: Array[String] = ["Wayfarer Hood", "Shaved Crown and Folded Hood", "Stout Kettle-Cap", "Scribe Feather-Hat"]
## The four beard and hair styles.
const BEARD_STYLES: Array[StringName] = [&"woodsman_full_speckled", &"braided_hearth", &"mustache_sideburns", &"clean_youth"]
const BEARD_NAMES: Array[String] = ["Woodsman's Speckled Beard", "Hearth-Braids", "Mustache and Sideburns", "Clean-Cheeked"]
## Shoulder pieces, either side.
const PAULDRON_STYLES: Array[StringName] = [&"iron_wood_bark_pauldron", &"stitched_leather_cop", &"broad_warden_pauldron", &"saffron_stole", &"none"]
const PAULDRON_NAMES: Array[String] = ["Iron-Wood Bark Pauldron", "Stitched-Leather Cop", "Broad Warden Pauldron", "Saffron Stole", "Bare Shoulder"]
## Each Fellowship's tunic (Value 2) and silhouette rim (§4, Stage 4): Shield-Sworn, Wayfarers, Lantern-Bearers.
const FELLOWSHIP_TUNICS: Array[Color] = [Color(0.243, 0.357, 0.561), Color(0.231, 0.478, 0.278), Color(0.784, 0.588, 0.243)]
const FELLOWSHIP_RIMS: Array[Color] = [Color(0.949, 0.718, 0.286), Color(0.322, 0.769, 0.471), Color(0.345, 0.722, 0.949)]

@export var appearance_id: StringName = &"iron_woodsman_default"
## The Calling this look belongs to (CallingResource.calling_id), &"" for a dye preset.
@export var calling_id: StringName = &"iron_woodsman"
@export var display_name: String = "Iron-Woodsman"
@export var heritage_id: StringName = &"tizzi_wed_green"
@export var coat_dye_preset: StringName = &"tizzi_wed_pine"

## &"adult" (a Calling's sculpted hero) or &"youth_wingfeather" (the Unsworn Level 1 youth).
@export var body_build: StringName = BODY_ADULT
## Which youth (&"boy" or &"girl", docs/26 §7) when body_build is the youth.
@export var youth_style: StringName = YOUTH_BOY

@export_group("Value 1: the grounded base")
## #2E402B Deep Pine-Wool.
@export var value_1_coat_color: Color = Color(0.180, 0.251, 0.169)
## #36281E Oiled Bog-Leather.
@export var value_1_boot_color: Color = Color(0.212, 0.157, 0.118)
## #3A3F47 Slate-wool knee-breeches.
@export var value_1_breeches_color: Color = Color(0.227, 0.247, 0.278)

@export_group("Value 2: tactile craft and joinery")
## #9C7250 Hewn Hazel.
@export var value_2_timber_leather_color: Color = Color(0.612, 0.447, 0.314)
## #D6C7B2 Buff Gambeson.
@export var value_2_linen_color: Color = Color(0.839, 0.780, 0.698)
## #A06A4A Oiled saddle leather (straps, belts, bracers, the stitched cop).
@export var value_2_leather_color: Color = Color(0.627, 0.416, 0.290)
## The Fellowship's tunic (#3B7A47 Wayfarer Emerald for the Wayfarers).
@export var value_2_tunic_color: Color = Color(0.231, 0.478, 0.278)

@export_group("Face and beard")
@export var skin_tone_color: Color = Color(0.86, 0.68, 0.56)
## #4A3222 Bark-Brown.
@export var beard_primary_color: Color = Color(0.290, 0.196, 0.133)
## #B8C0C8 Light Ash-Gray, speckled through the beard.
@export var beard_speckle_color: Color = Color(0.722, 0.753, 0.784)
@export_range(0.0, 1.0) var beard_speckle_ratio: float = 0.28
## The eyes (19B §2): #F4EFE6 ivory sclera, a #5E4728 hazel-amber iris, a dark pupil.
@export var sclera_color: Color = Color(0.957, 0.937, 0.902)
@export var iris_color: Color = Color(0.369, 0.278, 0.157)
@export var eye_color: Color = Color(0.08, 0.06, 0.05)

@export_group("Silhouette")
@export var headgear_style: StringName = &"wayfarer_hood_up"
## A crest fin on a kettle-cap (the Shield-Sworn's).
@export var headgear_crest: bool = false
@export var beard_style: StringName = &"woodsman_full_speckled"
@export var left_pauldron_style: StringName = &"iron_wood_bark_pauldron"
@export var right_pauldron_style: StringName = &"stitched_leather_cop"
@export var belt_trinket_id: StringName = &"iron_splitting_wedges"
## A round oak-and-iron buckler-targe strapped across the back (the Stout Heart's mark).
@export var back_buckler_targe: bool = true
## The split-leather hewing apron, divided so each leg kicks free.
@export var split_hewing_apron: bool = true
## The Fellowship's silhouette rim (#52C478 for the Wayfarers).
@export var role_rim_color: Color = Color(0.322, 0.769, 0.471)
@export_group("Character (docs/26)")
## Freckles over the nose and cheeks (0 none, 1 a summer's worth).
@export_range(0.0, 1.0) var freckle_amount: float = 0.0
## How rosy the cheeks, nose tip and ear tips run (the shader's malar_mix).
@export_range(0.0, 1.0) var cheek_flush: float = 0.32
## The lips' rose.
@export var lip_color: Color = Color(0.62, 0.3, 0.27)

## The youth's knee patch (the hero shader's Calling trim slot; an Unsworn youth has no tabard).
@export var patch_color: Color = Color(0.494, 0.604, 0.416)
## A drop-in model that wins over the sculpted hero (res://assets/models/heroes/<calling_id>.glb).
@export var glb_override_path: String = "res://assets/models/heroes/iron_woodsman.glb"


## This look in a heritage dye (a co-op seat's own colours): the coat wool and
## headgear felt take the preset's Value 1 wool, everything else stays.
func with_dye(dye: HeroAppearanceResource) -> HeroAppearanceResource:
	if dye == null or dye.coat_dye_preset == coat_dye_preset:
		return self
	var dyed: HeroAppearanceResource = duplicate() as HeroAppearanceResource
	dyed.coat_dye_preset = dye.coat_dye_preset
	dyed.value_1_coat_color = dye.value_1_coat_color
	dyed.appearance_id = StringName("%s_%s" % [appearance_id, dye.coat_dye_preset])
	return dyed


## Whether this is the Level 1 youth's body.
func is_youth() -> bool:
	return body_build == BODY_YOUTH


## The name of a style id from one of the style lists ("Wayfarer Hood").
static func style_name(style: StringName) -> String:
	for pair: Array in [[HEADGEAR_STYLES, HEADGEAR_NAMES], [BEARD_STYLES, BEARD_NAMES], [PAULDRON_STYLES, PAULDRON_NAMES]]:
		var styles: Array = pair[0]
		var names: Array = pair[1]
		var index: int = styles.find(style)
		if index >= 0:
			return names[index]
	return String(style).capitalize()


## Which Three-Value band a colour's luminance falls in: 1, 2, 3, or 0 between bands.
static func value_band(color: Color) -> int:
	var luminance: float = color.get_luminance()
	if luminance >= VALUE_1_LUMINANCE_MIN and luminance <= VALUE_1_LUMINANCE_MAX:
		return 1
	if luminance >= VALUE_2_LUMINANCE_MIN and luminance <= VALUE_2_LUMINANCE_MAX:
		return 2
	if luminance >= VALUE_3_LUMINANCE_MIN:
		return 3
	return 0


## A key naming everything the sculpted body depends on, so identical heroes share meshes.
func sculpt_key() -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [body_build, youth_style, headgear_style, headgear_crest, beard_style, left_pauldron_style, right_pauldron_style,
		belt_trinket_id, back_buckler_targe, split_hewing_apron]
