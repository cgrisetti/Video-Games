## The kin's looks (docs/30_KIN_DESIGN_LANGUAGE.md §7): for each look, its
## skeleton's proportions at its sculpted size, its height there, the palette its
## material wears beside the variant's own three colours, the bones its blow
## strikes with, and its clips. MobVariantResource.kin_look picks one; an empty
## look takes its body's (BODY_LOOKS).
class_name KinLooks
extends RefCounted

const R = KinRigBuilder.Rig
const Body = MobVariantResource.Body

# Act I's kin (docs/28, docs/29 §5) and Embershore's roadside kin (Lv 1 to 5).
const HOUND: StringName = &"hound"
const PADFOOT: StringName = &"padfoot"
const BRISTLE_HOB: StringName = &"bristle_hob"
const PUDDLE_BUCCA: StringName = &"puddle_bucca"
const TAPROOT_STAG: StringName = &"taproot_stag"
const CAIRN_DRAKE: StringName = &"cairn_drake"
const WEEVIL: StringName = &"weevil"
const BARNACLE: StringName = &"barnacle"
const THORN_TAIL: StringName = &"thorn_tail"
const ASH_GRIG: StringName = &"ash_grig"
const IRON_MAN: StringName = &"iron_man"
const IRON_FLINGER: StringName = &"iron_flinger"
const IRON_GIANT: StringName = &"iron_giant"
const TIDE_WIGHT: StringName = &"tide_wight"
const SPRIGGAN: StringName = &"spriggan"
const BOG_HULK: StringName = &"bog_hulk"
const ROOT_LURKER: StringName = &"root_lurker"
const BRAMBLE_LASHER: StringName = &"bramble_lasher"
const SAP_BOGGART: StringName = &"sap_boggart"
const SPORE_LOB: StringName = &"spore_lob"

const ALL: Array[StringName] = [HOUND, PADFOOT, BRISTLE_HOB, PUDDLE_BUCCA, TAPROOT_STAG, CAIRN_DRAKE, WEEVIL, BARNACLE, THORN_TAIL,
	ASH_GRIG, IRON_MAN, IRON_FLINGER, IRON_GIANT, TIDE_WIGHT, SPRIGGAN, BOG_HULK, ROOT_LURKER, BRAMBLE_LASHER, SAP_BOGGART, SPORE_LOB]

## A body's look when its variant names none.
const BODY_LOOKS: Dictionary[int, StringName] = {
	Body.BOAR: BRISTLE_HOB, Body.SCUTTLER: THORN_TAIL, Body.WOLF: PADFOOT, Body.TOAD: PUDDLE_BUCCA,
	Body.HUMANOID: IRON_MAN, Body.VINE: BRAMBLE_LASHER, Body.SHAMBLER: SPORE_LOB, Body.HULK: BOG_HULK,
	Body.WIGHT: TIDE_WIGHT, Body.BEHEMOTH: CAIRN_DRAKE,
}

static var _specs: Dictionary[StringName, Dictionary] = {}


## The look a variant wears.
static func look_of(variant: MobVariantResource) -> StringName:
	if variant.kin_look != &"" and ALL.has(variant.kin_look):
		return variant.kin_look
	return BODY_LOOKS.get(variant.body, PADFOOT)


## A look's spec: "rig", "frame" (KinRigBuilder's points), "height" (its sculpted
## height), "palette" ({shader uniform: Color}), "strikes" ([[bone, shell radius]]),
## "attack" (its blow's clip), "gait" ("walk"/"run" metres a cycle) and "eyes_glow".
static func spec(look: StringName) -> Dictionary:
	if _specs.is_empty():
		_build()
	return _specs.get(look, _specs[PADFOOT])


static func rig_of(look: StringName) -> int:
	return int(spec(look)["rig"])


static func _build() -> void:
	# --- Four legs --------------------------------------------------------------------
	# The Un-Inked Bramble-Hound: a lean, deep-chested hedge-hound with brambles for hackles.
	_add(HOUND, R.QUADRUPED, 1.12, {
		"hips": Vector3(0.0, 0.62, 0.4), "chest": Vector3(0.0, 0.66, -0.2), "neck": Vector3(0.0, 0.78, -0.33),
		"head": Vector3(0.0, 0.92, -0.47), "snout": Vector3(0.0, 0.84, -0.8), "ear": Vector3(0.065, 1.0, -0.45), "ear_tip": Vector3(0.12, 1.12, -0.38),
		"tail": [Vector3(0.0, 0.66, 0.5), Vector3(0.0, 0.66, 0.64), Vector3(0.0, 0.6, 0.78), Vector3(0.0, 0.52, 0.9)],
		"shoulder": Vector3(0.11, 0.6, -0.2), "elbow": Vector3(0.12, 0.36, -0.18), "wrist": Vector3(0.12, 0.1, -0.2), "toe_f": Vector3(0.12, 0.03, -0.31),
		"hip": Vector3(0.11, 0.6, 0.38), "knee": Vector3(0.125, 0.4, 0.27), "hock": Vector3(0.125, 0.2, 0.44), "fetlock": Vector3(0.125, 0.07, 0.4), "toe_h": Vector3(0.125, 0.03, 0.29),
	}, {"thorn_color": Color(0.36, 0.2, 0.15), "petal_color": Color(0.96, 0.6, 0.7), "bud_color": Color(0.44, 0.52, 0.32), "horn_color": Color(0.2, 0.16, 0.14)},
		[[&"Jaw", 0.22]], &"attack_bite", 1.6, false)
	# A Padfoot: a shaggy mist-hound with a great ruff, padded paws and a brush of a tail.
	_add(PADFOOT, R.QUADRUPED, 1.1, {
		"hips": Vector3(0.0, 0.6, 0.38), "chest": Vector3(0.0, 0.66, -0.2), "neck": Vector3(0.0, 0.8, -0.34),
		"head": Vector3(0.0, 0.92, -0.46), "snout": Vector3(0.0, 0.85, -0.76), "ear": Vector3(0.07, 1.0, -0.44), "ear_tip": Vector3(0.1, 1.16, -0.42),
		"tail": [Vector3(0.0, 0.64, 0.48), Vector3(0.0, 0.62, 0.62), Vector3(0.0, 0.56, 0.76), Vector3(0.0, 0.5, 0.9)],
		"shoulder": Vector3(0.12, 0.6, -0.2), "elbow": Vector3(0.13, 0.36, -0.18), "wrist": Vector3(0.13, 0.11, -0.2), "toe_f": Vector3(0.13, 0.04, -0.32),
		"hip": Vector3(0.12, 0.58, 0.36), "knee": Vector3(0.13, 0.4, 0.26), "hock": Vector3(0.13, 0.2, 0.42), "fetlock": Vector3(0.13, 0.08, 0.38), "toe_h": Vector3(0.13, 0.04, 0.27),
	}, {"horn_color": Color(0.22, 0.2, 0.2)}, [[&"Jaw", 0.24]], &"attack_bite", 1.7, false)
	# A Bristle-Hob: a barrel of a boar-hob, a bristle crest, a snout disc and upcurled tusks.
	_add(BRISTLE_HOB, R.QUADRUPED, 0.92, {
		"hips": Vector3(0.0, 0.5, 0.3), "chest": Vector3(0.0, 0.54, -0.2), "neck": Vector3(0.0, 0.56, -0.34),
		"head": Vector3(0.0, 0.56, -0.44), "snout": Vector3(0.0, 0.42, -0.8), "ear": Vector3(0.1, 0.7, -0.44), "ear_tip": Vector3(0.18, 0.8, -0.4),
		"tail": [Vector3(0.0, 0.56, 0.44), Vector3(0.0, 0.6, 0.5), Vector3(0.0, 0.58, 0.56), Vector3(0.0, 0.52, 0.58)],
		"shoulder": Vector3(0.14, 0.44, -0.2), "elbow": Vector3(0.15, 0.27, -0.19), "wrist": Vector3(0.15, 0.08, -0.2), "toe_f": Vector3(0.15, 0.02, -0.27),
		"hip": Vector3(0.14, 0.46, 0.28), "knee": Vector3(0.15, 0.3, 0.22), "hock": Vector3(0.15, 0.16, 0.32), "fetlock": Vector3(0.15, 0.06, 0.3), "toe_h": Vector3(0.15, 0.02, 0.23),
	}, {"horn_color": Color(0.92, 0.86, 0.7)}, [[&"Head", 0.3]], &"attack_gore", 1.3, false)
	# A Puddle-Bucca: a broad toad-bucca with eyes up on its brow and a lily-leaf cap.
	_add(PUDDLE_BUCCA, R.QUADRUPED, 0.74, {
		"hips": Vector3(0.0, 0.38, 0.24), "chest": Vector3(0.0, 0.4, -0.08), "neck": Vector3(0.0, 0.45, -0.2),
		"head": Vector3(0.0, 0.5, -0.28), "snout": Vector3(0.0, 0.44, -0.62), "ear": Vector3(0.15, 0.64, -0.32), "ear_tip": Vector3(0.16, 0.76, -0.36),
		"tail": [Vector3(0.0, 0.36, 0.4), Vector3(0.0, 0.34, 0.44), Vector3(0.0, 0.32, 0.47), Vector3(0.0, 0.3, 0.5)],
		"shoulder": Vector3(0.2, 0.34, -0.14), "elbow": Vector3(0.29, 0.2, -0.2), "wrist": Vector3(0.29, 0.05, -0.27), "toe_f": Vector3(0.31, 0.02, -0.38),
		"hip": Vector3(0.2, 0.36, 0.2), "knee": Vector3(0.37, 0.3, 0.0), "hock": Vector3(0.35, 0.12, 0.3), "fetlock": Vector3(0.33, 0.05, 0.16), "toe_h": Vector3(0.32, 0.02, 0.0),
	}, {"leaf_color": Color(0.34, 0.54, 0.26), "petal_color": Color(0.98, 0.9, 0.7), "bud_color": Color(0.98, 0.9, 0.7)},
		[[&"Jaw", 0.26]], &"attack_lunge", 1.2, false)
	# The Blighted Taproot Stag: a stag as tall as a cottage, moss on its shoulders, roots for antlers.
	_add(TAPROOT_STAG, R.QUADRUPED, 3.6, {
		"hips": Vector3(0.0, 1.86, 0.74), "chest": Vector3(0.0, 1.96, -0.46), "neck": Vector3(0.0, 2.32, -0.78), "arch": 0.08,
		"head": Vector3(0.0, 2.72, -1.0), "snout": Vector3(0.0, 2.5, -1.5), "ear": Vector3(0.16, 2.84, -0.96), "ear_tip": Vector3(0.42, 2.92, -0.88),
		"tail": [Vector3(0.0, 1.96, 0.92), Vector3(0.0, 1.92, 1.02), Vector3(0.0, 1.82, 1.08), Vector3(0.0, 1.72, 1.1)],
		"shoulder": Vector3(0.24, 1.72, -0.46), "elbow": Vector3(0.25, 1.14, -0.4), "wrist": Vector3(0.25, 0.42, -0.42), "toe_f": Vector3(0.25, 0.02, -0.56),
		"hip": Vector3(0.24, 1.8, 0.7), "knee": Vector3(0.26, 1.24, 0.52), "hock": Vector3(0.26, 0.74, 0.86), "fetlock": Vector3(0.26, 0.2, 0.8), "toe_h": Vector3(0.26, 0.02, 0.66),
	}, {"bark_color": Color(0.36, 0.28, 0.2), "moss_color": Color(0.34, 0.48, 0.2), "horn_color": Color(0.26, 0.22, 0.2), "thorn_color": Color(0.3, 0.24, 0.2)},
		[[&"Head", 0.7]], &"attack_antlers", 3.8, true)
	# The Crag-Back Cairn-Drake: a heavy drake under a shell of stacked crag, a bell at its throat.
	_add(CAIRN_DRAKE, R.QUADRUPED, 1.75, {
		"hips": Vector3(0.0, 1.0, 0.8), "chest": Vector3(0.0, 1.05, -0.5), "neck": Vector3(0.0, 1.05, -0.95),
		"head": Vector3(0.0, 1.1, -1.25), "snout": Vector3(0.0, 0.95, -1.85), "ear": Vector3(0.16, 1.28, -1.25), "ear_tip": Vector3(0.3, 1.42, -1.1),
		"tail": [Vector3(0.0, 0.95, 1.1), Vector3(0.0, 0.8, 1.5), Vector3(0.0, 0.6, 1.9), Vector3(0.0, 0.45, 2.3)],
		"shoulder": Vector3(0.42, 0.95, -0.5), "elbow": Vector3(0.52, 0.6, -0.48), "wrist": Vector3(0.5, 0.16, -0.5), "toe_f": Vector3(0.5, 0.02, -0.72),
		"hip": Vector3(0.42, 0.95, 0.75), "knee": Vector3(0.52, 0.62, 0.6), "hock": Vector3(0.5, 0.36, 0.86), "fetlock": Vector3(0.5, 0.1, 0.84), "toe_h": Vector3(0.5, 0.02, 0.64),
	}, {"stone_color": Color(0.56, 0.56, 0.52), "moss_color": Color(0.32, 0.46, 0.2), "brass_color": Color(0.82, 0.64, 0.3), "horn_color": Color(0.5, 0.48, 0.44)},
		[[&"Head", 0.6], [&"Jaw", 0.4]], &"attack_gore", 2.6, false)
	# --- Six legs ---------------------------------------------------------------------
	# The Grey-Bark Weevil: domed bark wing-cases, a long curved snout, elbowed feelers.
	_add(WEEVIL, R.HEXAPOD, 0.54, {
		"body": Vector3(0.0, 0.27, -0.06), "abdomen": Vector3(0.0, 0.3, 0.14), "abdomen_tip": Vector3(0.0, 0.24, 0.46),
		"head": Vector3(0.0, 0.29, -0.2), "snout": Vector3(0.0, 0.29, -0.3), "snout_tip": Vector3(0.0, 0.15, -0.63),
		"antenna": Vector3(0.03, 0.27, -0.43), "antenna_tip": Vector3(0.17, 0.43, -0.5),
		"leg1": [Vector3(0.08, 0.2, -0.12), Vector3(0.18, 0.24, -0.2), Vector3(0.22, 0.07, -0.25), Vector3(0.24, 0.02, -0.31)],
		"leg2": [Vector3(0.09, 0.19, 0.02), Vector3(0.2, 0.24, 0.04), Vector3(0.26, 0.06, 0.06), Vector3(0.29, 0.02, 0.08)],
		"leg3": [Vector3(0.08, 0.19, 0.14), Vector3(0.18, 0.24, 0.26), Vector3(0.23, 0.06, 0.33), Vector3(0.25, 0.02, 0.39)],
	}, {"bark_color": Color(0.5, 0.4, 0.3), "horn_color": Color(0.24, 0.18, 0.14), "moss_color": Color(0.36, 0.46, 0.22)},
		[[&"Snout", 0.16]], &"attack_jab", 0.9, false)
	# A Barnacle Scuttler: a broad crab-shell crusted with barnacles, two great claws held up.
	_add(BARNACLE, R.HEXAPOD, 0.74, {
		"body": Vector3(0.0, 0.38, 0.0), "abdomen": Vector3(0.0, 0.34, 0.16), "abdomen_tip": Vector3(0.0, 0.28, 0.34),
		"head": Vector3(0.0, 0.4, -0.24), "snout": Vector3(0.0, 0.36, -0.32), "snout_tip": Vector3(0.0, 0.3, -0.38),
		"antenna": Vector3(0.09, 0.48, -0.26), "antenna_tip": Vector3(0.11, 0.66, -0.3),
		"leg1": [Vector3(0.24, 0.36, -0.2), Vector3(0.4, 0.44, -0.36), Vector3(0.34, 0.4, -0.54), Vector3(0.26, 0.36, -0.7)],
		"leg2": [Vector3(0.3, 0.32, -0.04), Vector3(0.5, 0.4, -0.06), Vector3(0.6, 0.12, -0.08), Vector3(0.64, 0.02, -0.1)],
		"leg3": [Vector3(0.28, 0.32, 0.14), Vector3(0.46, 0.4, 0.22), Vector3(0.56, 0.12, 0.3), Vector3(0.59, 0.02, 0.35)],
	}, {"barnacle_color": Color(0.88, 0.86, 0.78), "leaf_color": Color(0.2, 0.34, 0.24), "horn_color": Color(0.2, 0.16, 0.14)},
		[[&"Foot_R1", 0.24], [&"Foot_L1", 0.24]], &"attack_snip", 1.0, false)
	# A Thorn-Tail Hedgerow-Hob: a round hedge-beetle in a coat of thorns, its thorny tail curled over.
	_add(THORN_TAIL, R.HEXAPOD, 0.82, {
		"body": Vector3(0.0, 0.32, -0.04), "abdomen": Vector3(0.0, 0.34, 0.14),
		"tail": [Vector3(0.0, 0.42, 0.32), Vector3(0.0, 0.66, 0.4), Vector3(0.0, 0.8, 0.2)],
		"head": Vector3(0.0, 0.3, -0.24), "snout": Vector3(0.0, 0.27, -0.36), "snout_tip": Vector3(0.0, 0.24, -0.46),
		"antenna": Vector3(0.06, 0.38, -0.3), "antenna_tip": Vector3(0.12, 0.5, -0.36),
		"leg1": [Vector3(0.1, 0.2, -0.14), Vector3(0.21, 0.23, -0.21), Vector3(0.25, 0.07, -0.25), Vector3(0.27, 0.02, -0.3)],
		"leg2": [Vector3(0.12, 0.19, 0.0), Vector3(0.24, 0.23, 0.02), Vector3(0.29, 0.06, 0.04), Vector3(0.32, 0.02, 0.06)],
		"leg3": [Vector3(0.1, 0.19, 0.14), Vector3(0.21, 0.23, 0.25), Vector3(0.25, 0.06, 0.32), Vector3(0.27, 0.02, 0.37)],
	}, {"thorn_color": Color(0.42, 0.28, 0.18), "petal_color": Color(0.98, 0.95, 0.85), "bud_color": Color(0.98, 0.95, 0.85)},
		[[&"Tail_2", 0.2]], &"attack_tail", 1.0, false)
	# --- Two legs (the heroes' skeleton) ------------------------------------------------
	# An Ash-Grig: a little soot-hob with a big round head, long ears and a coal in its belly.
	_add(ASH_GRIG, R.BIPED, 1.92, {}, {"ember_color": Color(1.0, 0.5, 0.16)}, [[&"Hand_R", 0.16]], &"attack_throw", 1.2, true)
	# A Furrow Iron-Man: a plough-iron giant with a cauldron chest, a grate of coals and a bucket helm.
	_add(IRON_MAN, R.BIPED, 1.95, {}, {"ember_color": Color(1.0, 0.56, 0.2)}, [[&"Hand_R", 0.32], [&"Hand_L", 0.32]], &"attack_slam", 1.9, true)
	_add(IRON_FLINGER, R.BIPED, 1.9, {}, {"ember_color": Color(1.0, 0.56, 0.2)}, [[&"Hand_R", 0.26]], &"attack_throw", 1.9, true)
	_add(IRON_GIANT, R.BIPED, 1.95, {}, {"ember_color": Color(1.0, 0.56, 0.2)}, [[&"Hand_R", 0.34], [&"Hand_L", 0.34]], &"attack_slam", 1.9, true)
	# A Tide-Wight: sea-fret given a hooded shape, kelp at its shoulders, lantern eyes, no feet.
	_add(TIDE_WIGHT, R.BIPED, 1.86, {}, {"leaf_color": Color(0.18, 0.32, 0.26), "barnacle_color": Color(0.86, 0.86, 0.8)},
		[[&"Hand_R", 0.24]], &"attack_sweep", 2.0, true)
	# A Crag-Spriggan: a squat stone-guard in a moss cloak behind a round stone shield.
	_add(SPRIGGAN, R.BIPED, 1.72, {}, {"stone_color": Color(0.58, 0.57, 0.52), "moss_color": Color(0.32, 0.46, 0.2), "brass_color": Color(0.8, 0.62, 0.3)},
		[[&"Hand_R", 0.28]], &"attack_slam", 1.8, true)
	# A Bog-Hulk Boggart: a hunched peat-and-moss giant, knuckles to the ground, reeds down its back.
	_add(BOG_HULK, R.BIPED, 1.8, {}, {"moss_color": Color(0.3, 0.42, 0.18), "bark_color": Color(0.3, 0.24, 0.18), "leaf_color": Color(0.5, 0.56, 0.3)},
		[[&"Hand_R", 0.34], [&"Hand_L", 0.34]], &"attack_slam", 2.0, true)
	# --- Stalks ---------------------------------------------------------------------
	# A Root-Lurker: a knotted root reared out of the wall, a knot for a head, two root-whips.
	_add(ROOT_LURKER, R.STALK, 2.12, {
		"base": Vector3(0.0, 0.08, 0.0), "stalk": [Vector3(0.0, 0.3, 0.06), Vector3(0.0, 0.64, 0.04), Vector3(0.0, 0.98, -0.04), Vector3(0.0, 1.3, -0.1), Vector3(0.0, 1.56, -0.1)],
		"head": Vector3(0.0, 1.72, -0.12), "head_tip": Vector3(0.0, 2.0, -0.22),
		"whip": [Vector3(0.14, 0.7, 0.02), Vector3(0.46, 0.84, -0.12), Vector3(0.78, 0.62, -0.32)], "whip_from": 2,
	}, {"bark_color": Color(0.42, 0.32, 0.24), "moss_color": Color(0.34, 0.46, 0.2), "leaf_color": Color(0.42, 0.6, 0.28)},
		[[&"Head", 0.34]], &"attack_lash", 1.0, true)
	# A Bramble-Lasher Hob: a bundle of bramble canes under a great wild-rose bloom, two thorn-whips.
	_add(BRAMBLE_LASHER, R.STALK, 2.1, {
		"base": Vector3(0.0, 0.06, 0.0), "stalk": [Vector3(0.0, 0.3, 0.0), Vector3(0.0, 0.62, 0.02), Vector3(0.0, 0.96, 0.0), Vector3(0.0, 1.26, -0.04), Vector3(0.0, 1.52, -0.06)],
		"head": Vector3(0.0, 1.7, -0.08), "head_tip": Vector3(0.0, 2.0, -0.18),
		"whip": [Vector3(0.12, 0.98, 0.0), Vector3(0.5, 1.1, -0.14), Vector3(0.86, 0.9, -0.36)], "whip_from": 3,
	}, {"thorn_color": Color(0.32, 0.22, 0.16), "leaf_color": Color(0.32, 0.5, 0.22), "bud_color": Color(0.36, 0.46, 0.24)},
		[[&"Whip_R2", 0.26], [&"Whip_L2", 0.26]], &"attack_lash", 1.0, true)
	# --- Mounds ---------------------------------------------------------------------
	# A Sap-Boggart: a slumped mound of thick grey sap with an amber heart, dripping as it goes.
	_add(SAP_BOGGART, R.BLOB, 1.62, {
		"base": Vector3(0.0, 0.18, 0.0), "belly": Vector3(0.0, 0.58, 0.0), "crown": Vector3(0.0, 1.06, -0.02), "cap": Vector3(0.0, 1.34, -0.04), "cap_tip": Vector3(0.0, 1.6, -0.06),
		"arm": [Vector3(0.44, 0.94, -0.08), Vector3(0.7, 0.74, -0.18), Vector3(0.8, 0.48, -0.26)],
		"foot": [Vector3(0.22, 0.14, 0.0), Vector3(0.24, 0.03, -0.2)], "drip": [Vector3(0.12, 0.66, -0.4), Vector3(0.14, 0.24, -0.46)],
	}, {"bark_color": Color(0.3, 0.24, 0.18), "leaf_color": Color(0.5, 0.52, 0.3)}, [[&"Arm_R2", 0.3]], &"attack_slap", 1.0, true)
	# A Spore-Puff Lob: a stout mushroom-lob under a spotted puffball cap.
	_add(SPORE_LOB, R.BLOB, 1.6, {
		"base": Vector3(0.0, 0.16, 0.0), "belly": Vector3(0.0, 0.52, 0.0), "crown": Vector3(0.0, 0.94, 0.0), "cap": Vector3(0.0, 1.12, 0.0), "cap_tip": Vector3(0.0, 1.58, 0.0),
		"arm": [Vector3(0.32, 0.8, -0.04), Vector3(0.48, 0.6, -0.1), Vector3(0.52, 0.38, -0.14)],
		"foot": [Vector3(0.18, 0.14, 0.0), Vector3(0.2, 0.03, -0.16)], "drip": [Vector3(0.0, 0.62, -0.3), Vector3(0.0, 0.5, -0.34)],
	}, {}, [[&"Cap", 0.5]], &"attack_puff", 1.0, false)


static func _add(look: StringName, rig: int, height: float, frame: Dictionary, palette: Dictionary, strikes: Array, attack: StringName,
		gait_metres: float, eyes_glow: bool) -> void:
	var full: Dictionary = frame.duplicate()
	full["rig"] = rig
	_specs[look] = {"rig": rig, "frame": full, "height": height, "palette": palette, "strikes": strikes, "attack": attack,
		"gait": gait_metres, "eyes_glow": eyes_glow}
