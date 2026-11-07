## A hero, drawn and moved (19_HERO_CHARACTER_ART_AND_ANIMATION_RIG_GDD.md):
## the canonical 24-bone skeleton (HeroRigBuilder) wearing five continuous
## skinned surfaces sculpted for their Calling and coat (HeroMeshAtelier) in the
## Three-Value Harmony shader (storybook_hero_atelier.gdshader), its tiered
## weapon in the MainHandSocket (the bow in the OffHandSocket), and its kit on
## the BackStowSocket and HipSatchelSocket:
##   the Shield-Sworn    a kettle-cap, broad warden pauldrons and a banded
##                       oak-and-brass Greatshield on the off forearm
##   the Wayfarers       a hood, asymmetric hewing pauldrons, a quiver for the
##                       bow (and on a Stout Heart, a buckler-targe on the back)
##   the Lantern-Bearers a feather-hat, a saffron stole and a brass
##                       Tether-Lantern at the hip that really glows
## Every hero carries the Scribe Vellum Satchel at the hip, its flap opening for
## a card. Each tick HeroCombatAnimator poses the skeleton frame-locked to the
## action, and StorybookKinematicsModifier3D layers the cloak, beard, lean,
## foot-plant, grip, look-at and hit-stop on top. Out of a fight for 4 s the
## weapon goes on the back.
##
## Drop a model at res://assets/models/<class_id>.glb or
## res://assets/models/heroes/<calling_id>.glb and it's shown instead.
##
## It also shows what a hero's power just did (11_COMBAT_ONBOARDING_AND_FEEL_GDD.md
## §4.2, §6): R and L+R swell the weapon to 2x (2.4x) in its Sign's colour, or
## warm ivory-gold un-inked; a Flow-Link Pulse rings the waist white-gold; and
## a new trail level unfurls a Saffron-Gold Wayfarer Pennant overhead.
##
## And Sign-Flow's looks (14_SIGN_FLOW_AND_GRIMOIRE_UX_GDD.md §2, §5): the
## Hearth-Rite holds the weapon at 1.35x, glowing in its Place-Card's tint; a
## Sign-Flow cast flares it to 2.0x for 600 ms; a coat keeps a soft rim of its
## Sign. A Ward-Mantle wraps the shoulders in a ring of the Sign's crest, and a
## Lantern-Tether circles the hero with three glowing motes. The coat's Sign
## lights the hero's Maker-Seal veins; the solo Dread-Chill window frosts their
## boots and The Lantern's Promise warms their rim.
##
## And the card choreography (14 GDD §8), played on every peer:
## - the Overhead Pocket Blessing (the Hearth-Rite): the weapon is lowered and
##   put away, the right hand draws a glowing vellum card (0.18 x 0.26 m) from
##   the coat pocket and raises it overhead, never above 2.5 m, while a column
##   of the Sign's ink pours down round the hero; the card goes back in the
##   pocket and the weapon is drawn again, glowing at 1.35x;
## - the Offhand Pocket-Draw (a Sign-Flow cast): the off hand flicks the card
##   out of the pocket and sweeps it along the weapon as it ignites at 2.0x.
##
## And the Seal-and-Tuck Grimoire (docs/everwood_equipment_grimoire_architecture.md
## Part II §2.1, §3.2, §4.2, §6.6), driven by the hero's EquipmentSealComponent:
## - the Wingfeather youth proportions (apply_wingfeather_youth_proportions):
##   a 14-year-old's silhouette read from the 4.8 m camera, the head 1.22x,
##   the hands 1.28x, the boots 1.18x and the weapon 1.25x, with a Male Youth's
##   wider shoulders or a Female Youth's flared mantle, all as bone pose scales
##   on the same 24-bone rig;
## - the seven material tiers and the three pressed seals
##   (apply_equipment_tier_and_seals): one equipment_seal.gdshader, washed over
##   the sculpted weapon as a next_pass and worn by a buckler crest and a mantle
##   band, no new mesh per tier;
## - the Pocket-Pull flourish (play_pocket_pull_flourish): 18 frames (0.30 s)
##   in the hero's own space, the off hand to the pouch, a 1.6x card raised
##   overhead (never above 2.5 m), then slammed into the weapon as every seal
##   flares. It never touches a Camera3D.
class_name ActorVisuals
extends Node3D

enum Choreography { NONE, OVERHEAD_BLESSING, POCKET_DRAW, POCKET_PULL }

signal pocket_pull_started(card_id: StringName, slot_index: int)
signal pocket_pull_completed(card_id: StringName, slot_index: int)

const MODEL_FOLDER: String = "res://assets/models/"
## The Seal-and-Tuck Grimoire's master equipment shader.
const SEAL_SHADER: Shader = preload("res://src/actors/shaders/equipment_seal.gdshader")
## The Pocket-Pull: 18 frames at 60 fps, the card at 1.6x overhead with its top under 2.5 m,
## the seals flaring to 2.2 then settling to a 0.75 afterglow that fades away.
const POCKET_PULL_DURATION_SEC: float = 0.30
const POCKET_PULL_FRAMES: int = 18
const POCKET_PULL_CARD_SCALE: float = 1.6
const POCKET_PULL_CARD_HEIGHT: float = 2.15
const POCKET_PULL_CARD_CAP: float = 2.5
const POCKET_PULL_FLARE: float = 2.2
const POCKET_PULL_AFTERGLOW: float = 0.75
const AFTERGLOW_FADE_PER_SEC: float = 0.5
## The Wingfeather youth rig (§2.1): 5.5 heads tall, read from the 4.8 m camera.
const YOUTH_HEADS_TALL: float = 5.5
const YOUTH_HEAD_SCALE: Vector3 = Vector3(1.22, 1.22, 1.22)
const YOUTH_HAND_SCALE: Vector3 = Vector3(1.28, 1.28, 1.28)
const YOUTH_FOOT_SCALE: Vector3 = Vector3(1.18, 1.18, 1.18)
const YOUTH_WEAPON_SCALE: Vector3 = Vector3(1.25, 1.25, 1.25)
const YOUTH_MALE_SHOULDER: Vector3 = Vector3(1.04, 1.0, 1.0)
const YOUTH_FEMALE_SHOULDER: Vector3 = Vector3(0.96, 1.0, 1.0)
const YOUTH_MALE_MANTLE: Vector3 = Vector3(1.0, 1.0, 1.0)
const YOUTH_FEMALE_MANTLE: Vector3 = Vector3(1.08, 1.0, 1.08)
## The seal shader over the sculpted weapon: how much of the tier's tint washes the sculpt.
const WEAPON_SEAL_BLEND: float = 0.35
## The buckler crest on the off hand and the mantle band at the collar (one mesh each, every tier).
const CREST_RADIUS: float = 0.075
const CREST_THICKNESS: float = 0.012
const MANTLE_BAND_RADIUS: float = 0.25
const MANTLE_BAND_WIDTH: float = 0.045
const MANTLE_BAND_RISE: float = 0.17
const LANTERN_GLOW: Color = Color(1.0, 0.78, 0.4)
const VELLUM_COLOR: Color = Color(0.97, 0.93, 0.8)
const LANTERN_SWAY: float = 0.25
## Sprinting (K1): past this share of the hero's run pace, the lean may reach this far past a run's.
const SPRINT_LEAN_FROM: float = 1.2
const SPRINT_LEAN_REACH: float = 1.5
## The five skinned surfaces' nodes, in HeroMeshAtelier.REGIONS order.
const REGION_NODES: Array[String] = ["HeadHeritage", "TorsoCoat", "PauldronsTabard", "LimbsBoots", "BeltCloak"]
## Martial Imbuement's silhouette (11 GDD §4.2, Layer 2): R swells the weapon to
## 2x, L+R to 2.4x, over the 450 ms the skill channels, rimmed in its Sign's
## colour (or warm ivory-gold un-inked). It swells in the first 15% and
## settles in the last 20%.
const CHANNEL_TIME: float = 0.45
const CHANNEL_SCALE: float = 2.0
const ULT_CHANNEL_SCALE: float = 2.4
const CHANNEL_RISE: float = 0.15
const CHANNEL_FALL: float = 0.8
const CHANNEL_GLOW: float = 1.6
const UNINKED_CHANNEL_COLOR: Color = Color(1.0, 0.9, 0.62)
## The Flow-Link Pulse ring at the waist.
const FLOW_RING_TIME: float = 0.35
const FLOW_RING_RADIUS: float = 1.1
const FLOW_RING_HEIGHT: float = 0.95
## The Wayfarer Pennant (11 GDD §6): Saffron-Gold, 2.4 m above the head, 3 s.
const PENNANT_TIME: float = 3.0
const PENNANT_HEIGHT: float = 2.4
const PENNANT_UNFURL: float = 0.4
const PENNANT_COLOR: Color = Color(0.98, 0.72, 0.18)
const OAK_COLOR: Color = Color(0.46, 0.31, 0.18)
## Sign-Flow (SignFlowComponent.CoatLook): the tuck's steady size and glow, the flare's peak, the coat's soft rim.
const TRAIL_TUCK_SCALE: float = 1.35
const TRAIL_TUCK_GLOW: float = 0.6
const SIGN_FLOW_FLARE_SCALE: float = 2.0
const SIGN_FLOW_FLARE_TIME: float = 0.6
const COAT_GLOW: float = 0.35
## The flare rises over this share of its time and falls over the last share.
const FLARE_RISE: float = 0.1
const FLARE_FALL: float = 0.85
const MANTLE_HEIGHT: float = 1.42
const MANTLE_RADIUS: float = 0.62
const MOTE_HEIGHT: float = 1.0
const MOTE_RADIUS: float = 0.72
const MOTE_SIZE: float = 0.08
const MOTE_SPIN: float = 2.2
## The card choreography (14 GDD §8).
const CARD_SIZE: Vector3 = Vector3(0.18, 0.26, 0.01)
const CARD_GLOW: float = 3.2
## A rim of the Sign's colour round the card, so it reads from the split-screen camera.
const CARD_HALO: float = 0.08
## The card sits this far past the wrist, along the hand.
const CARD_IN_HAND: float = 0.17
const BLESSING_TIME: float = 1.5
const POCKET_DRAW_TIME: float = 0.42
## The ink column pours from here (the 3.2 m sightline cap stays clear above it) to the ground.
const INK_COLUMN_TOP: float = 2.5
const INK_COLUMN_RADIUS: float = 0.55
## The vein glow of each Sign-Flow look on the hero's Maker-Seal veins (0 to 2.4).
const TUCK_VEIN_GLOW: float = 1.2
const COAT_VEIN_GLOW: float = 0.8
const FLARE_VEIN_GLOW: float = 2.4
## A two-hander's off-hand grip slides from high on the haft (ready, wind-up)
## down beside the right hand as the blow lands (§3.2).
const GRIP_HIGH: Dictionary[int, float] = {EquipmentItemResource.WeaponType.HEAVY_AXE: 0.62, EquipmentItemResource.WeaponType.STAFF: 0.46}
const GRIP_LOW: Dictionary[int, float] = {EquipmentItemResource.WeaponType.HEAVY_AXE: 0.2, EquipmentItemResource.WeaponType.STAFF: 0.28}
## A weapon stowed on the back: across it diagonally, its edge out.
const STOW_BASIS: Basis = Basis(Vector3(-0.83, 0.56, 0.0), Vector3(0.56, 0.83, 0.0), Vector3(0.0, 0.0, -1.0))
## How far behind the chest the back's gear rides: out past the cloak lying flat
## on the back, so the two never cross (13_PLAYTEST §2.8; it was 0.27 m).
const BACK_GEAR_DEPTH: float = 0.31
## The greatshield on the off forearm: turned so its long side runs across the
## arm, set 11 cm out and 10 cm toward the wrist (13_PLAYTEST §2.7; it ran along
## the arm, its edge reaching back past the elbow into the shoulder and chest).
const SHIELD_ON_FOREARM: Transform3D = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.11, -0.1, 0.04))
## The Sign-stone's float and turn.
const STONE_BOB: float = 0.012
const STONE_SPIN: float = 2.0
## The Level 1 youth (21_WINGFEATHER_YOUTH_HERO.md): the satchel rides
## closer on the youth's slimmer hip; the Tier 1 tool and its quiver or shield
## stay tucked away out of a fight and pop into hand over DRAW_POP_TIME.
const YOUTH_SATCHEL_AT: Vector3 = Vector3(-0.178, -0.08, 0.05)
const DRAW_POP_TIME: float = 0.16
## Feet look for the ground this far above and below them.
const GROUND_PROBE_UP: float = 0.5
const GROUND_PROBE_DOWN: float = 0.9
const GROUND_MAX_STEP: float = 0.4

var actor: ActorBase
## Every material on the hero, lit together by a hit flash.
var materials: Array[Material] = []
## A dropped-in .glb model in use instead of the sculpted hero, if there is one.
var model: Node3D
## The sculpted hero: its look, skeleton, surfaces, motion and animation.
var appearance: HeroAppearanceResource
var skeleton: Skeleton3D
var body_material: ShaderMaterial
var surfaces: Array[MeshInstance3D] = []
var kinematics: StorybookKinematicsModifier3D
var animator: HeroCombatAnimator
## What the sculpt put on this hero, by part (headgear, beard, pauldrons, coat, props...).
var features: Dictionary = {}

var _lantern: Node3D
var _satchel_flap: Node3D
var _age: float = 0.0
## The weapon in hand (ActorBase's prop) and its mount on the hand socket.
var _weapon: Node3D
var _weapon_item: EquipmentItemResource
var _weapon_mount: Node3D
var _weapon_pivot: Vector3 = Vector3.ZERO
var _weapon_materials: Array[Material] = []
var _sign_stone: MeshInstance3D
var _channel_action: StringName = &""
var _channel_left: float = 0.0
var _channel_peak: float = 1.0
var _channel_color: Color = UNINKED_CHANNEL_COLOR
var _channel_lit: float = 0.0
var _pennant: Node3D
var _coat_look: int = SignFlowComponent.CoatLook.CLEAR
var _coat_ink: Color = UNINKED_CHANNEL_COLOR
var _coat_ambient: Color = UNINKED_CHANNEL_COLOR
var _coat_mode: int = ScribeCardResource.ManifestationMode.WEAPON_COAT
var _coat_left: float = 0.0
var _flare_left: float = 0.0
var _flare_ink: Color = UNINKED_CHANNEL_COLOR
var _mantle: Node3D
var _motes: Node3D
var _choreo: Choreography = Choreography.NONE
var _choreo_time: float = 0.0
var _choreo_color: Color = UNINKED_CHANNEL_COLOR
var _card: MeshInstance3D
var _card_material: StandardMaterial3D
var _ink_column: MeshInstance3D
var _ink_material: StandardMaterial3D
## How high the card's top edge rose in the last choreography (metres above the feet).
var _card_peak: float = 0.0
var _played: Dictionary[int, int] = {}
var _stowed: bool = false
## A shield, a quiver or a targe rides on the back.
var _back_gear: bool = false
var _grip_slide: float = 0.0
var _frost: float = 0.0
var _warmth: float = 0.0
var _hit_stop_left: float = 0.0
var _hit_stop_total: float = 0.0
## The youth's fight-only kit (a quiver, a shield), hidden with the tool while calm.
var _combat_kit: Array[Node3D] = []
## 1 just drawn, easing to 0: the tool grows into the youth's hand.
var _draw_pop: float = 0.0

## Whether an Unsworn player hero is drawn as the Level 1 youth (tests of the adult heroes on the trail turn it off).
static var youth_heroes: bool = true

## The Seal-and-Tuck Grimoire: the shield on the off hand, the three seal
## materials (the weapon's is a next_pass over the sculpt), the crest and band
## they paint, the youth scales in force, and the Pocket-Pull in flight.
var _shield: Node3D
var _weapon_seal_pass: ShaderMaterial
var _offhand_seal_material: ShaderMaterial
var _mantle_seal_material: ShaderMaterial
var _offhand_crest: MeshInstance3D
var _mantle_band: MeshInstance3D
var _overhead_card: MeshInstance3D
var _current_youth_scales: Dictionary = {}
var _body_type: int = -1
var _applied_tier_id: StringName = &""
var _seal_state: Dictionary = {}
var _is_flourishing: bool = false
var _flourish_card: StringName = &""
var _flourish_slot: int = -1
var _seal_flare: float = 0.0
var _seal_flare_shown: float = -1.0
var _pocket_pulls: int = 0


static func model_path(id: StringName) -> String:
	return MODEL_FOLDER + String(id) + ".glb"


## Whether a model was dropped in for this class, item or creature id.
static func has_model(id: StringName) -> bool:
	return id != &"" and ResourceLoader.exists(model_path(id))


## The dropped-in model for `id`, ready to add, or null.
static func load_model(id: StringName) -> Node3D:
	if not has_model(id):
		return null
	var scene: PackedScene = load(model_path(id)) as PackedScene
	return scene.instantiate() as Node3D if scene != null else null


func setup(for_actor: ActorBase) -> void:
	actor = for_actor
	name = "Puppet"


func _ready() -> void:
	rebuild()


## Whether this hero is the sculpted 24-bone rig (not a dropped-in model).
func has_rig() -> bool:
	return is_instance_valid(skeleton)


## Builds the hero for the actor's current loadout (again after a Scribe Desk swap or a new Calling).
func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	materials.clear()
	surfaces.clear()
	features.clear()
	skeleton = null
	kinematics = null
	animator = null
	_lantern = null
	_satchel_flap = null
	_card = null
	_ink_column = null
	_weapon = null
	_weapon_mount = null
	_sign_stone = null
	_shield = null
	_offhand_crest = null
	_mantle_band = null
	_overhead_card = null
	_applied_tier_id = &""
	_stowed = false
	_back_gear = false
	_combat_kit.clear()
	_draw_pop = 0.0
	_choreo = Choreography.NONE
	var loadout: ClassLoadoutResource = actor.loadout
	var column: int = Callings.resolve(loadout.class_id, loadout.calling)
	if is_youth_seat():
		appearance = ArsenalCatalog.current.youth_appearance_for_seat(loadout.class_id, actor.party_slot, youth_style_for_seat())
	else:
		appearance = ArsenalCatalog.current.hero_appearance_for_seat(loadout.class_id, column, actor.party_slot)
	model = load_model(loadout.class_id)
	if model == null:
		model = HeroMeshAtelier.hero_override(appearance)
	if model != null:
		add_child(model)
		return
	var row: int = Callings.fellowship_row(loadout.class_id)
	# Trim and tabard in the Secondary Calling's colour (its SecondaryCallingResource).
	var calling: SecondaryCallingResource = Callings.secondary(column)
	var trim: Color = calling.trim_color if calling != null else Callings.UNSWORN_TRIM
	var coat: StringName = loadout.armor.item_id if loadout.armor != null else &"ranger_leather"
	if appearance.is_youth():
		# The youth has no tabard: the trim slot paints the knee patch and the cape's lining.
		trim = appearance.patch_color
	skeleton = HeroRigBuilder.build_hero_skeleton()
	if appearance.is_youth():
		skeleton.scale = Vector3.ONE * HeroAppearanceResource.YOUTH_SKELETON_SCALE
	add_child(skeleton)
	body_material = HeroMeshAtelier.hero_material(appearance, trim)
	materials.append(body_material)
	var meshes: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(appearance, coat)
	for index: int in meshes.size():
		var surface: MeshInstance3D = MeshInstance3D.new()
		surface.name = REGION_NODES[index]
		surface.mesh = meshes[index]
		surface.skin = HeroRigBuilder.skin_of(skeleton)
		surface.material_override = body_material
		skeleton.add_child(surface)
		surface.skeleton = surface.get_path_to(skeleton)
		surfaces.append(surface)
	_build_kit(row, loadout)
	kinematics = StorybookKinematicsModifier3D.new()
	kinematics.name = "StorybookKinematics"
	skeleton.add_child(kinematics)
	animator = HeroCombatAnimator.new()
	animator.setup(actor, skeleton)
	animator.youth = appearance.is_youth()
	animator.youth_girl = appearance.is_youth() and appearance.youth_style == HeroAppearanceResource.YOUTH_GIRL
	add_child(animator)
	features = {
		"calling": appearance.calling_id, "headgear": appearance.headgear_style, "headgear_crest": appearance.headgear_crest,
		"beard": appearance.beard_style, "left_pauldron": appearance.left_pauldron_style, "right_pauldron": appearance.right_pauldron_style,
		"belt_trinket": appearance.belt_trinket_id, "back_buckler_targe": appearance.back_buckler_targe, "split_hewing_apron": appearance.split_hewing_apron,
		"coat": coat, "dye": appearance.coat_dye_preset, "trim": trim, "tunic": appearance.value_2_tunic_color, "rim": appearance.role_rim_color,
		"body_build": appearance.body_build,
	}
	# The Seal-and-Tuck Grimoire dresses the fresh rig: its youth silhouette, its tier and its seals.
	if actor.seal != null:
		actor.seal.apply_visuals()


## Whether this hero is drawn as the Level 1 youth: a player (not an AI
## companion) still Unsworn, on the trail before Level 10.
## Which youth this seat is (docs/26 §7): Player 1 the tale's own choice (PartyProgress.hero_style),
## the seats after alternate from it, so siblings on the couch read apart.
func youth_style_for_seat() -> StringName:
	var chosen: StringName = PartyProgress.current.hero_style if PartyProgress.current != null else HeroAppearanceResource.YOUTH_BOY
	if actor == null or actor.party_slot % 2 == 0:
		return chosen
	return HeroAppearanceResource.YOUTH_BOY if chosen == HeroAppearanceResource.YOUTH_GIRL else HeroAppearanceResource.YOUTH_GIRL


func is_youth_seat() -> bool:
	if not youth_heroes or actor == null or actor.is_companion or actor.loadout == null:
		return false
	return actor.loadout.calling == Callings.UNSWORN and ClassLoadouts.PLAYER_CLASSES.has(actor.loadout.class_id)


## Whether this hero is the Level 1 youth.
func is_youth() -> bool:
	return appearance != null and appearance.is_youth() and has_rig()


## The Fellowship's kit on the sockets: the satchel, an off-hand piece, what's on the back.
func _build_kit(row: int, loadout: ClassLoadoutResource) -> void:
	var satchel: Node3D = HeroMeshAtelier.build_scribe_satchel(body_material)
	satchel.position = YOUTH_SATCHEL_AT if appearance.is_youth() else Vector3(-0.215, -0.1, 0.07)
	socket(HeroRigBuilder.HIP_SATCHEL_SOCKET).add_child(satchel)
	_satchel_flap = satchel.get_node(^"Flap") as Node3D
	var weapon_type: int = loadout.weapon.weapon_type if loadout.weapon != null else EquipmentItemResource.WeaponType.LIGHT_SWORD
	var free_off_hand: bool = weapon_type == EquipmentItemResource.WeaponType.LIGHT_SWORD
	var back: Node3D = socket(HeroRigBuilder.BACK_STOW_SOCKET)
	var quivered: bool = loadout.is_ranged() and weapon_type == EquipmentItemResource.WeaponType.BOW
	match row:
		0:
			# The banded oak-and-brass Greatshield on the off forearm, or on the back for a two-hander.
			var shield: Node3D = HeroMeshAtelier.build_greatshield(body_material)
			if free_off_hand:
				# Strapped across the forearm, its long side across the arm, and a little out from it,
				# so it clears the shoulder, the head and the chest in every pose (13_PLAYTEST §2.7).
				shield.transform = SHIELD_ON_FOREARM
				socket(HeroRigBuilder.OFF_HAND_SOCKET).add_child(shield)
				if appearance.is_youth():
					_combat_kit.append(shield)
			else:
				shield.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(0.0, -0.06, BACK_GEAR_DEPTH + 0.04))
				back.add_child(shield)
				_back_gear = not appearance.is_youth()
				if appearance.is_youth():
					_combat_kit.append(shield)
			_shield = shield
		2:
			# The brass Tether-Lantern hanging at the left hip, really glowing.
			_lantern = HeroMeshAtelier.build_tether_lantern(body_material, LANTERN_GLOW)
			_lantern.position = Vector3(-0.235, -0.04, -0.1)
			socket(HeroRigBuilder.HIP_SATCHEL_SOCKET).add_child(_lantern)
	if quivered:
		var quiver: Node3D = HeroMeshAtelier.build_quiver(body_material)
		quiver.transform = Transform3D(Basis(Vector3.BACK, -0.35), Vector3(0.12, 0.02, BACK_GEAR_DEPTH - 0.04))
		back.add_child(quiver)
		_back_gear = not appearance.is_youth()
		if appearance.is_youth():
			_combat_kit.append(quiver)
	if appearance.back_buckler_targe and row != 0:
		var targe: Node3D = HeroMeshAtelier.build_buckler_targe(body_material)
		targe.position = Vector3(-0.05 if quivered else 0.0, -0.02, BACK_GEAR_DEPTH - 0.03)
		back.add_child(targe)
		_back_gear = true


## One of the skeleton's four sockets by name (HeroRigBuilder.MAIN_HAND_SOCKET...).
func socket(socket_name: StringName) -> BoneAttachment3D:
	return HeroRigBuilder.socket(skeleton, socket_name) if is_instance_valid(skeleton) else null


## Builds the weapon this hero holds, sculpted at its tier, and mounts it in
## hand (the bow in the off hand). Returns it, or null without a rig.
func mount_weapon(item: EquipmentItemResource) -> Node3D:
	if not has_rig() or item == null:
		return null
	var weapon: Node3D = HeroMeshAtelier.build_tiered_weapon(item.weapon_type, int(item.equipment_tier), item.item_id)
	_weapon_mount = Node3D.new()
	_weapon_mount.name = "WeaponMount"
	_weapon_mount.add_child(weapon)
	_hold(item)
	set_weapon(weapon, item)
	return weapon


func _hold(item: EquipmentItemResource) -> void:
	var bow: bool = item.weapon_type == EquipmentItemResource.WeaponType.BOW
	var hand: BoneAttachment3D = socket(HeroRigBuilder.OFF_HAND_SOCKET if bow else HeroRigBuilder.MAIN_HAND_SOCKET)
	if _weapon_mount.get_parent() != null:
		_weapon_mount.get_parent().remove_child(_weapon_mount)
	hand.add_child(_weapon_mount)
	_weapon_mount.transform = HeroMeshAtelier.GRIP_MOUNT
	# A youth's hand is already 1.28x; the weapon itself reads at 1.25x.
	_weapon_mount.scale = Vector3.ONE * _youth_weapon_scale() / _youth_hand_scale()
	_stowed = false


## Out of a fight a while, the weapon goes on the back; any action draws it
## again. The youth tucks it away altogether (empty hands on the orchard
## lanes) and draws it into hand when a fight starts.
func _stow(stowed: bool) -> void:
	if stowed == _stowed or not is_instance_valid(_weapon_mount) or _weapon_item == null:
		return
	if is_youth():
		_tuck_away(stowed)
		return
	if not stowed:
		_hold(_weapon_item)
		return
	_weapon_mount.get_parent().remove_child(_weapon_mount)
	socket(HeroRigBuilder.BACK_STOW_SOCKET).add_child(_weapon_mount)
	var half: float = HeroMeshAtelier.weapon_length(_weapon_item.weapon_type) * 0.5
	_weapon_mount.transform = Transform3D(STOW_BASIS, -STOW_BASIS.y * half * _youth_weapon_scale() + Vector3(0.0, 0.04, BACK_GEAR_DEPTH))
	_weapon_mount.scale = Vector3.ONE * _youth_weapon_scale()
	_stowed = true


## The youth's empty hands: hide the tool and its fight kit, or draw them with a pop and a reach.
func _tuck_away(hidden: bool) -> void:
	_stowed = hidden
	_weapon_mount.visible = not hidden
	for piece: Node3D in _combat_kit:
		if is_instance_valid(piece):
			piece.visible = not hidden
	if hidden:
		_draw_pop = 0.0
		_weapon_mount.scale = Vector3.ONE
		return
	_draw_pop = 1.0
	var bow: bool = _weapon_item.weapon_type == EquipmentItemResource.WeaponType.BOW
	animator.play_overlay(HeroCombatAnimator.YOUTH_DRAW_LEFT if bow else HeroCombatAnimator.YOUTH_DRAW_RIGHT)


## Whether the youth's hands are empty right now (the tool tucked away).
func is_empty_handed() -> bool:
	return is_youth() and (not is_instance_valid(_weapon_mount) or not _weapon_mount.visible)


## Whether the weapon is on the back right now.
func is_weapon_stowed() -> bool:
	return _stowed


## The weapon this hero holds (built here or by ActorBase from its item), so R and L+R can swell it.
func set_weapon(weapon_root: Node3D, item: EquipmentItemResource) -> void:
	_weapon = weapon_root
	_weapon_item = item
	# A sculpted weapon's grip is its origin; a part-built prop swells about its trail base (or the bow's grip).
	_weapon_pivot = Vector3.ZERO if has_rig() else item.trail_base
	_weapon_materials.clear()
	_channel_left = 0.0
	_sign_stone = weapon_root.find_child("SignStoneCore", true, false) as MeshInstance3D
	for mesh: Node in weapon_root.find_children("*", "MeshInstance3D", true, false):
		var shape: MeshInstance3D = mesh as MeshInstance3D
		var material: Material = shape.material_override
		if material == null and shape.mesh is PrimitiveMesh:
			material = (shape.mesh as PrimitiveMesh).material
		if material is ShaderMaterial:
			_weapon_materials.append(material)
	_attach_weapon_seal_pass()


## How big the weapon is drawn right now (2.0 at the height of an R channel).
func weapon_scale() -> float:
	return _weapon.scale.x if is_instance_valid(_weapon) else 1.0


## The world positions of the weapon's trail base and tip (empty without them).
func trail_points() -> PackedVector3Array:
	if not is_instance_valid(_weapon):
		return PackedVector3Array()
	var base: Node3D = _weapon.get_node_or_null(^"TrailBase") as Node3D
	var tip: Node3D = _weapon.get_node_or_null(^"TrailTip") as Node3D
	if base == null or tip == null:
		return PackedVector3Array()
	return PackedVector3Array([base.global_position, tip.global_position])


## The weapon root (for tests and the trail).
func weapon() -> Node3D:
	return _weapon if is_instance_valid(_weapon) else null


# --- Each tick ------------------------------------------------------------------

## Poses the hero for this tick: the animator's frame-locked clip, then the
## modifier's springs, IK and hit-stop, then the kit and the shader's play
## state. `moved` is the hero's velocity (worked out from its motion, so
## networked copies move too); `frozen` holds the clips still through a hit-stop.
func update_rig(delta: float, moved: Vector3, frozen: bool = false) -> void:
	_age += delta
	if _lantern != null:
		_lantern.rotation.z = sin(_age * 2.4) * LANTERN_SWAY * 0.4
		_lantern.rotation.x = sin(_age * 1.7) * LANTERN_SWAY * 0.3
	if not has_rig():
		return
	# Alive (docs/26 §8): the eyes blink on their own rhythm.
	body_material.set_shader_parameter(&"eye_blink", HeroMeshAtelier.blink_amount(_age, float(actor.party_slot) + 0.37))
	_hit_stop_left = maxf(0.0, _hit_stop_left - delta)
	if frozen and _hit_stop_left <= 0.0:
		_hit_stop_left = delta
	animator.vertical_speed = moved.y
	animator.update(delta, frozen)
	_stow(animator.calm)
	if _draw_pop > 0.0 and is_instance_valid(_weapon_mount):
		_draw_pop = maxf(0.0, _draw_pop - delta / DRAW_POP_TIME)
		# Grows into the hand with a little overshoot.
		var grow: float = 1.0 - _draw_pop
		_weapon_mount.scale = Vector3.ONE * clampf(0.25 + 0.75 * grow + 0.12 * sin(grow * PI), 0.01, 1.2)
	_feed_kinematics(delta, moved, frozen)
	skeleton.advance(delta)
	_update_kit(delta)
	_update_shader_state(delta)


func _feed_kinematics(delta: float, moved: Vector3, frozen: bool) -> void:
	var k: StorybookKinematicsModifier3D = kinematics
	k.velocity = Vector3.ZERO if frozen else moved
	k.move_speed = actor.loadout.stats.move_speed
	# Sprinting (K1) leans the hero further into the run, worked out from speed so a networked copy leans too.
	var flat_speed: float = Vector2(moved.x, moved.z).length()
	k.lean_reach = SPRINT_LEAN_REACH if not frozen and flat_speed > actor.loadout.stats.move_speed * SPRINT_LEAN_FROM else 1.0
	k.stamina_ratio = actor.stats.stamina / maxf(actor.stats.stats.max_stamina, 1.0) if actor.stats != null else 1.0
	k.winded = actor.is_multiplayer_authority() and actor.action_queue != null and actor.action_queue.winded
	k.hit_stop_left = _hit_stop_left if frozen else 0.0
	k.hit_stop_duration = _hit_stop_total
	k.foot_ik_weight = animator.foot_ik_weight
	var whole_body: bool = animator.clip == &"dodge_roll_evade" or animator.clip == &"hearth_rite_tuck" or animator.clip == &"downed_slump"
	k.lean_weight = 0.0 if whole_body else 1.0
	k.grip_weight = animator.grip_weight
	# Gear strapped on the back holds the cloak's top under it (13_PLAYTEST §2.8).
	k.back_strapped = _stowed or _back_gear
	k.draw_weight = animator.draw_weight
	if WorldAtmosphereDirector.current != null:
		k.wind = WorldAtmosphereDirector.current.wind
	# The off hand's grip on a two-hander slides down the haft as the blow lands.
	var grip: Node3D = _weapon.get_node_or_null(^"HaftGripMarker") as Node3D if is_instance_valid(_weapon) else null
	if grip != null and _weapon_item != null:
		var landing: bool = actor.current_phase() == ActionQueueComponent.Phase.ACTIVE
		_grip_slide = move_toward(_grip_slide, 1.0 if landing else 0.0, delta * 8.0)
		grip.position.y = lerpf(GRIP_HIGH.get(_weapon_item.weapon_type, 0.5), GRIP_LOW.get(_weapon_item.weapon_type, 0.3), _grip_slide)
		k.grip_in_hand = _weapon_mount.transform * _weapon.transform * grip.transform
	else:
		k.grip_weight = 0.0
	_probe_ground(k)
	k.has_look_target = false
	if actor.current_action() == null and not frozen:
		var target: Vector3 = _look_target()
		if target != Vector3.INF:
			k.has_look_target = true
			k.look_target = target


## Raycasts under each foot for the ground's height there, relative to the hero's feet.
func _probe_ground(k: StorybookKinematicsModifier3D) -> void:
	k.ground_left = 0.0
	k.ground_right = 0.0
	k.grounded = actor.is_on_floor() or not actor.is_multiplayer_authority()
	if not k.grounded or not actor.is_inside_tree():
		return
	var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
	var origin_y: float = actor.global_position.y
	var heights: Array[float] = []
	for bone: int in [HeroRigBuilder.Bone.FOOT_L, HeroRigBuilder.Bone.FOOT_R]:
		var foot: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			Vector3(foot.x, origin_y + GROUND_PROBE_UP, foot.z), Vector3(foot.x, origin_y - GROUND_PROBE_DOWN, foot.z),
			ActorBase.LAYER_WORLD | ActorBase.LAYER_LOW_SCENERY)
		var hit: Dictionary = space.intersect_ray(query)
		heights.append(clampf((hit["position"] as Vector3).y - origin_y, -GROUND_MAX_STEP, GROUND_MAX_STEP) if not hit.is_empty() else 0.0)
	# The modifier works in the skeleton's space (the youth's is drawn at 0.9).
	var scale_y: float = maxf(skeleton.scale.y, 0.01)
	k.ground_left = heights[0] / scale_y
	k.ground_right = heights[1] / scale_y


## A curious hob to parley with or an open Glimmer-Spot within 8 m (Vector3.INF for none).
func _look_target() -> Vector3:
	var best: Vector3 = Vector3.INF
	var nearest: float = StorybookKinematicsModifier3D.LOOK_RANGE
	for foe: ActorBase in CombatDirector.current.enemies():
		var curious: bool = foe.spectrum != null and foe.spectrum.is_parleyable()
		var glimmering: bool = foe.glimmer != null and foe.glimmer.is_open()
		if not curious and not glimmering:
			continue
		var distance: float = foe.global_position.distance_to(actor.global_position)
		if distance < nearest:
			nearest = distance
			best = foe.global_position + Vector3.UP * foe.body_height() * 0.75
	return best


## The kit's motion: the bowstring follows the draw hand, the Sign-stone floats
## and turns, the satchel's flap opens for a card.
func _update_kit(delta: float) -> void:
	if is_instance_valid(_weapon) and _weapon_item != null and _weapon_item.weapon_type == EquipmentItemResource.WeaponType.BOW:
		var mid: Node3D = _weapon.get_node_or_null(^"BowString/BowStringMid") as Node3D
		if mid != null:
			var rest: Vector3 = Vector3(0.0, 0.0, 0.12)
			var hand: Vector3 = _weapon.get_node(^"BowString").to_local(socket(HeroRigBuilder.MAIN_HAND_SOCKET).global_position)
			mid.position = rest.lerp(hand, animator.draw_weight)
			HeroMeshAtelier.update_bowstring(_weapon)
	if is_instance_valid(_sign_stone):
		var spot: Vector3 = _sign_stone.get_meta(&"rest_position", _sign_stone.position)
		_sign_stone.position = spot + Vector3(0.0, sin(_age * 2.6) * STONE_BOB, 0.0)
		_sign_stone.rotate_y(STONE_SPIN * delta)
	if _satchel_flap != null:
		var opening: bool = animator.clip.begins_with("card_invoke") or animator.clip == &"hearth_rite_tuck" or animator.overlay_clip() != &""
		_satchel_flap.rotation.z = move_toward(_satchel_flap.rotation.z, -1.1 if opening else 0.0, delta * 8.0)


## The shader's play state: the Sign veins, the solo Dread-Chill frost and The Lantern's Promise warmth.
func _update_shader_state(delta: float) -> void:
	var vein_color: Color = _coat_ink
	var vein: float = 0.0
	match sign_coat_look():
		SignFlowComponent.CoatLook.TRAIL_TUCK:
			vein_color = _coat_ambient
			vein = TUCK_VEIN_GLOW
		SignFlowComponent.CoatLook.COAT:
			vein = COAT_VEIN_GLOW
	if _flare_left > 0.0:
		vein_color = _flare_ink
		vein = FLARE_VEIN_GLOW
	if _channel_lit > vein / FLARE_VEIN_GLOW:
		vein_color = _channel_color
		vein = _channel_lit * FLARE_VEIN_GLOW
	var frost: bool = false
	var warm: bool = false
	var flow: SignFlowComponent = actor.sign_flow
	if flow != null and SignFlowComponent.enabled and flow.is_flow_window_open():
		var frames: int = flow.flow_window_frames()
		frost = frames == SignFlowComponent.DREAD_CHILL_WINDOW_FRAMES
		warm = frames == SignFlowComponent.LANTERNS_PROMISE_WINDOW_FRAMES
	_frost = move_toward(_frost, 1.0 if frost else 0.0, delta * 6.0)
	_warmth = move_toward(_warmth, 1.0 if warm else 0.0, delta * 6.0)
	body_material.set_shader_parameter(&"active_sign_color", vein_color)
	body_material.set_shader_parameter(&"sign_emission_strength", vein)
	body_material.set_shader_parameter(&"dread_chill_frost", _frost)
	body_material.set_shader_parameter(&"lantern_promise_warmth", _warmth)
	if is_instance_valid(_sign_stone):
		var primitive: PrimitiveMesh = _sign_stone.mesh as PrimitiveMesh
		var stone: StandardMaterial3D = primitive.material as StandardMaterial3D if primitive != null else null
		if stone != null:
			var tint: Color = vein_color if vein > 0.0 else ArsenalCatalog.SIGN_STONE_COLOR
			stone.albedo_color = tint
			stone.emission = tint


## The shader's state, for checks: the frost, the warmth and the vein glow.
func shader_state() -> Dictionary:
	if body_material == null:
		return {}
	return {"frost": float(body_material.get_shader_parameter(&"dread_chill_frost")), "warmth": float(body_material.get_shader_parameter(&"lantern_promise_warmth")),
		"sign": float(body_material.get_shader_parameter(&"sign_emission_strength"))}


## A hit-stop just froze this hero for `duration` seconds (the tremor and squash play through it).
func note_hit_stop(duration: float) -> void:
	if _hit_stop_left <= 0.0:
		_hit_stop_total = 0.0
	_hit_stop_left = maxf(_hit_stop_left, duration)
	_hit_stop_total = maxf(_hit_stop_total, duration)


# --- One-shots ------------------------------------------------------------------

## The Truce-Sign bow when a curious hob this hero greeted starts to dance.
func play_truce_sign_parley() -> void:
	if has_rig():
		animator.play_one_shot(&"truce_sign_parley")


## The lunging counter when this hero lands a Bravery Counter on a Glimmer-Spot.
func play_bravery_counter() -> void:
	if has_rig():
		animator.play_one_shot(&"bravery_counter_strike")


## The deflecting bash of a Perfect Guard.
func play_perfect_guard_parry() -> void:
	if has_rig():
		animator.play_one_shot(&"perfect_guard_parry")


# --- Martial Imbuement and Sign-Flow ---------------------------------------------

## Starts the swell when an R or L+R begins, and plays it out (every peer calls
## this each frame with the action the hero is doing).
func update_channel(delta: float, action: CombatActionResource) -> void:
	_update_seal_flare(delta)
	var action_id: StringName = action.action_id if action != null else &""
	if action_id != _channel_action:
		_channel_action = action_id
		if action != null and action.is_skill():
			_channel_left = CHANNEL_TIME
			_channel_peak = ULT_CHANNEL_SCALE if action.command == CombatActionResource.Command.TRIGGER_BOTH_ULT else CHANNEL_SCALE
			_channel_color = UNINKED_CHANNEL_COLOR if action.scribe_sign == ScribeSignResource.Sign.NONE \
				else ArsenalCatalog.current.sign_seal(action.scribe_sign).color
	if not is_instance_valid(_weapon):
		return
	var swell: float = 0.0
	if _channel_left > 0.0:
		_channel_left = maxf(0.0, _channel_left - delta)
		var t: float = 1.0 - _channel_left / CHANNEL_TIME
		swell = smoothstep(0.0, CHANNEL_RISE, t) * (1.0 - smoothstep(CHANNEL_FALL, 1.0, t))
	_channel_lit = swell
	var size: float = lerpf(1.0, _channel_peak, swell)
	var tint: Color = _channel_color
	var lit: float = swell
	# Sign-Flow: the Hearth-Rite's steady 1.35x in its Place-Card's tint, a cast's 2.0x flare, a coat's soft rim.
	var coat_size: float = 1.0
	var coat_tint: Color = _coat_ink
	var coat_lit: float = 0.0
	if _coat_look == SignFlowComponent.CoatLook.TRAIL_TUCK:
		coat_size = TRAIL_TUCK_SCALE
		coat_tint = _coat_ambient
		coat_lit = TRAIL_TUCK_GLOW
	elif _coat_left > 0.0:
		_coat_left = maxf(0.0, _coat_left - delta)
		coat_lit = COAT_GLOW
	if _flare_left > 0.0:
		_flare_left = maxf(0.0, _flare_left - delta)
		var t: float = 1.0 - _flare_left / SIGN_FLOW_FLARE_TIME
		var flare: float = smoothstep(0.0, FLARE_RISE, t) * (1.0 - smoothstep(FLARE_FALL, 1.0, t))
		coat_size = maxf(coat_size, lerpf(1.0, SIGN_FLOW_FLARE_SCALE, flare))
		if flare > coat_lit:
			coat_tint = _flare_ink
			coat_lit = flare
	size = maxf(size, coat_size)
	if coat_lit > lit:
		tint = coat_tint
		lit = coat_lit
	_weapon.scale = Vector3.ONE * size
	# Swell about the grip, wherever the swing has turned the weapon.
	_weapon.position = Basis.from_euler(_weapon.rotation) * (_weapon_pivot * (1.0 - size))
	var glow: Color = tint * CHANNEL_GLOW * lit
	for material: Material in _weapon_materials:
		StorybookMaterial.set_glow(material, glow)
		var cel: ShaderMaterial = material as ShaderMaterial
		if cel != null:
			cel.set_shader_parameter(&"rim_color", tint if lit > 0.0 else StorybookMaterial.WARM_RIM)
			cel.set_shader_parameter(&"rim_strength", lerpf(PropBuilder.PROP_RIM, 2.5, lit))
	_update_manifestation(delta)
	_update_choreography(delta)


## Sign-Flow's look on this hero, on every peer (CombatDirector.show_sign_coat):
## SignFlowComponent.CoatLook TRAIL_TUCK (until cleared), FLARE or COAT (for
## `seconds`), or CLEAR. `ink` is the leaf's Sign colour, `ambient` its Place-Card's tint.
func show_sign_coat(look: int, ink: Color, ambient: Color, mode: int, seconds: float) -> void:
	match look:
		SignFlowComponent.CoatLook.FLARE:
			_flare_left = maxf(seconds, 0.0)
			_flare_ink = ink
			play_pocket_draw_ignition(ink)
			return
		SignFlowComponent.CoatLook.BLESSING:
			play_overhead_blessing_choreography(ambient)
			return
		SignFlowComponent.CoatLook.COAT:
			_coat_left = maxf(seconds, 0.0)
		SignFlowComponent.CoatLook.CLEAR:
			_coat_left = 0.0
	_coat_look = look
	_coat_ink = ink
	_coat_ambient = ambient
	_coat_mode = mode


## The Sign-Flow look on now (SignFlowComponent.CoatLook): a tuck, a live coat, or CLEAR.
func sign_coat_look() -> int:
	if _coat_look == SignFlowComponent.CoatLook.COAT and _coat_left <= 0.0:
		return SignFlowComponent.CoatLook.CLEAR
	return _coat_look


## A Ward-Mantle's shoulder crest and a Lantern-Tether's motes, while a tuck or coat is on.
func _update_manifestation(delta: float) -> void:
	var on: int = sign_coat_look()
	var showing: bool = on == SignFlowComponent.CoatLook.TRAIL_TUCK or on == SignFlowComponent.CoatLook.COAT
	var color: Color = _coat_ambient if on == SignFlowComponent.CoatLook.TRAIL_TUCK else _coat_ink
	var mantle: bool = showing and _coat_mode == ScribeCardResource.ManifestationMode.WARD_MANTLE
	var tether: bool = showing and _coat_mode == ScribeCardResource.ManifestationMode.LANTERN_TETHER
	if mantle and not is_instance_valid(_mantle):
		_mantle = Node3D.new()
		_mantle.name = "WardMantle"
		_mantle.add_child(ShapeKit.no_shadow(ShapeKit.torus("Crest", MANTLE_RADIUS - 0.07, MANTLE_RADIUS, Vector3(0.0, MANTLE_HEIGHT, 0.0),
			StorybookMaterial.glowing(color, 2.5))))
		add_child(_mantle)
	if tether and not is_instance_valid(_motes):
		_motes = Node3D.new()
		_motes.name = "LanternMotes"
		_motes.position = Vector3(0.0, MOTE_HEIGHT, 0.0)
		for index: int in 3:
			var angle: float = TAU * index / 3.0
			_motes.add_child(ShapeKit.no_shadow(ShapeKit.sphere("Mote%d" % index, MOTE_SIZE, Vector3(cos(angle), 0.0, sin(angle)) * MOTE_RADIUS,
				StorybookMaterial.glowing(color, 3.0))))
		add_child(_motes)
	if is_instance_valid(_mantle):
		_mantle.visible = mantle
		if mantle:
			_tint_children(_mantle, color)
	if is_instance_valid(_motes):
		_motes.visible = tether
		if tether:
			_motes.rotate_y(MOTE_SPIN * delta)
			_tint_children(_motes, color)


# --- The card choreography (14 GDD §8) ----------------------------------------

## The Hearth-Rite's Overhead Pocket Blessing, in the Place-Card's tint.
func play_overhead_blessing_choreography(sign_color: Color) -> void:
	_start_choreography(Choreography.OVERHEAD_BLESSING, sign_color)


## A Sign-Flow cast's Offhand Pocket-Draw and blade ignition, in the leaf's Sign colour.
func play_pocket_draw_ignition(sign_color: Color) -> void:
	_start_choreography(Choreography.POCKET_DRAW, sign_color)


## The choreography playing now (Choreography.NONE when none is).
func choreography() -> Choreography:
	return _choreo


## How many times a choreography has played on this hero.
func choreography_count(kind: Choreography) -> int:
	return _played.get(kind, 0)


## How high the card's top edge rose in the last choreography, in metres above the hero's feet.
func card_peak_height() -> float:
	return _card_peak


## Whether the Overhead Pocket Blessing's ink column is pouring right now.
func is_ink_pouring() -> bool:
	return is_instance_valid(_ink_column) and _ink_column.visible


## Whether the weapon is drawn (the Overhead Pocket Blessing puts it away for a moment).
func is_weapon_drawn() -> bool:
	return not is_instance_valid(_weapon) or _weapon.visible


## Whether the vellum card is out of the pocket right now.
func is_card_out() -> bool:
	return is_instance_valid(_card) and _card.visible


func _start_choreography(kind: Choreography, color: Color) -> void:
	if not has_rig():
		return # A dropped-in model has no hands to play it with.
	_end_choreography()
	_choreo = kind
	_choreo_time = 0.0
	_choreo_color = color
	_card_peak = 0.0
	_played[kind] = _played.get(kind, 0) + 1
	var hand: BoneAttachment3D = socket(HeroRigBuilder.MAIN_HAND_SOCKET if kind == Choreography.OVERHEAD_BLESSING else HeroRigBuilder.OFF_HAND_SOCKET)
	match kind:
		Choreography.OVERHEAD_BLESSING:
			animator.play_overlay(&"overhead_pocket_blessing")
		Choreography.POCKET_PULL:
			animator.play_overlay(&"pocket_pull_flourish")
		_:
			animator.play_overlay(&"offhand_pocket_draw")
	if _card_material == null:
		_card_material = StorybookMaterial.glowing(VELLUM_COLOR, CARD_GLOW)
		_card_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_card_material.albedo_color = VELLUM_COLOR
	_card_material.emission = VELLUM_COLOR.lerp(color, 0.25)
	_card = ShapeKit.no_shadow(ShapeKit.box("VellumCard", CARD_SIZE, Vector3(0.0, CARD_IN_HAND, 0.0), _card_material))
	var halo: StandardMaterial3D = StorybookMaterial.glowing(color, 2.2)
	halo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.albedo_color = Color(color, 0.7)
	_card.add_child(ShapeKit.no_shadow(ShapeKit.box("SignHalo", Vector3(CARD_SIZE.x + CARD_HALO, CARD_SIZE.y + CARD_HALO, CARD_SIZE.z * 0.4),
		Vector3.ZERO, halo)))
	_card.visible = false
	hand.add_child(_card)
	if kind == Choreography.OVERHEAD_BLESSING:
		if _ink_material == null:
			_ink_material = StorybookMaterial.glowing(color, 1.8)
			_ink_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_ink_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_ink_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_ink_material.albedo_color = Color(color, 0.0)
		_ink_material.emission = color
		_ink_column = ShapeKit.no_shadow(ShapeKit.cylinder("InkColumn", INK_COLUMN_RADIUS, INK_COLUMN_RADIUS * 1.15, 1.0,
			Vector3(0.0, INK_COLUMN_TOP - 0.5, 0.0), _ink_material, 16))
		_ink_column.visible = false
		add_child(_ink_column)


## Plays the choreography out: the card and the ink column, keyed on its clock
## (the arm itself moves on the animator's overlay clip).
func _update_choreography(delta: float) -> void:
	if _choreo == Choreography.NONE:
		return
	_choreo_time += delta
	var length: float = POCKET_DRAW_TIME
	match _choreo:
		Choreography.OVERHEAD_BLESSING:
			_play_blessing(_choreo_time)
			length = BLESSING_TIME
		Choreography.POCKET_PULL:
			_play_pocket_pull(_choreo_time)
			length = POCKET_PULL_DURATION_SEC
		_:
			_play_pocket_draw(_choreo_time)
	if is_instance_valid(_card) and _card.visible:
		_card_peak = maxf(_card_peak, _card.global_position.y + CARD_SIZE.y * 0.5 - global_position.y)
	if is_instance_valid(_overhead_card) and _overhead_card.visible:
		_card_peak = maxf(_card_peak, _overhead_card.global_position.y + CARD_SIZE.y * POCKET_PULL_CARD_SCALE * 0.5 - global_position.y)
	if _choreo_time >= length:
		var finished: Choreography = _choreo
		_end_choreography()
		if finished == Choreography.POCKET_PULL:
			_finish_pocket_pull_flourish()


## 0-0.25 s to the pocket as the weapon is put away; up overhead with the card
## by 0.55; ink pours down to 1.05; back to the pocket by 1.3; the weapon drawn by 1.5.
func _play_blessing(t: float) -> void:
	_card.visible = t >= 0.25 and t < 1.25
	if is_instance_valid(_weapon):
		_weapon.visible = t < 0.12 or t >= 1.3
	if is_instance_valid(_ink_column):
		# The column pours down from 2.5 m, holds, then fades.
		var pour: float = smoothstep(0.55, 0.85, t)
		var fade: float = 1.0 - smoothstep(0.95, 1.2, t)
		_ink_column.visible = t >= 0.55 and t < 1.2
		var height: float = maxf(0.05, INK_COLUMN_TOP * pour)
		_ink_column.scale = Vector3(1.0, height, 1.0)
		_ink_column.position = Vector3(0.0, INK_COLUMN_TOP - height * 0.5, 0.0)
		_ink_material.albedo_color = Color(_choreo_color, 0.42 * fade)


## 0-0.08 s the off hand dips to the pocket; to 0.3 it sweeps the card along
## the weapon as it ignites; to 0.42 it's back, the card tucked away.
func _play_pocket_draw(t: float) -> void:
	_card.visible = t >= 0.08 and t < 0.36


func _end_choreography() -> void:
	if _choreo == Choreography.NONE:
		return
	if is_instance_valid(_weapon):
		_weapon.visible = true
	if is_instance_valid(_card):
		_card.queue_free()
	if is_instance_valid(_ink_column):
		_ink_column.queue_free()
	if is_instance_valid(_overhead_card):
		_overhead_card.queue_free()
	_card = null
	_ink_column = null
	_overhead_card = null
	_choreo = Choreography.NONE


# --- The Seal-and-Tuck Grimoire (docs/everwood_equipment_grimoire_architecture.md) ------------

## The Wingfeather youth silhouette (§2.1), read from the 4.8 m camera: the head
## 1.22x, the hands 1.28x, the boots 1.18x and the weapon 1.25x, with a Male
## Youth's shoulders 4% wider or a Female Youth's mantle flared 8%. All of it is
## bone pose scale on the same rig, so the hitbox, pace and clips never change.
func apply_wingfeather_youth_proportions(body_type: int) -> void:
	var male: bool = body_type == PlayerLoadoutResource.YouthBodyType.BODY_MALE_YOUTH
	_body_type = body_type
	_current_youth_scales = {
		"head": YOUTH_HEAD_SCALE,
		"hand": YOUTH_HAND_SCALE,
		"foot": YOUTH_FOOT_SCALE,
		"weapon": YOUTH_WEAPON_SCALE,
		"shoulder": YOUTH_MALE_SHOULDER if male else YOUTH_FEMALE_SHOULDER,
		"mantle": YOUTH_MALE_MANTLE if male else YOUTH_FEMALE_MANTLE,
		"heads_tall": YOUTH_HEADS_TALL,
	}
	if not has_rig():
		return
	const B = HeroRigBuilder.Bone
	skeleton.set_bone_pose_scale(B.HEAD, YOUTH_HEAD_SCALE)
	skeleton.set_bone_pose_scale(B.HAND_L, YOUTH_HAND_SCALE)
	skeleton.set_bone_pose_scale(B.HAND_R, YOUTH_HAND_SCALE)
	skeleton.set_bone_pose_scale(B.FOOT_L, YOUTH_FOOT_SCALE)
	skeleton.set_bone_pose_scale(B.FOOT_R, YOUTH_FOOT_SCALE)
	# A clavicle's local Y runs along it to the shoulder, so its width is its Y.
	var shoulder: Vector3 = _current_youth_scales["shoulder"]
	var along: Vector3 = Vector3(1.0, shoulder.x, 1.0)
	skeleton.set_bone_pose_scale(B.CLAVICLE_L, along)
	skeleton.set_bone_pose_scale(B.CLAVICLE_R, along)
	# The mantle hangs from the first cloak bone; it flares across and out, never down.
	skeleton.set_bone_pose_scale(B.CLOAK_01, _current_youth_scales["mantle"])
	if is_instance_valid(_weapon_mount):
		_weapon_mount.scale = Vector3.ONE * (_youth_weapon_scale() if _stowed else _youth_weapon_scale() / _youth_hand_scale())
	if is_instance_valid(_shield):
		_shield.scale = Vector3.ONE * (_youth_weapon_scale() / _youth_hand_scale() if _shield.get_parent() == socket(HeroRigBuilder.OFF_HAND_SOCKET)
			else _youth_weapon_scale())


## The scales in force ("head", "hand", "foot", "weapon", "shoulder", "mantle"), empty before any were applied.
func get_current_youth_scales() -> Dictionary:
	return _current_youth_scales


## The youth silhouette applied (PlayerLoadoutResource.YouthBodyType), -1 for the classic rig.
func youth_body_type() -> int:
	return _body_type


func _youth_weapon_scale() -> float:
	return YOUTH_WEAPON_SCALE.x if _body_type >= 0 else 1.0


func _youth_hand_scale() -> float:
	return YOUTH_HAND_SCALE.x if _body_type >= 0 else 1.0


## Dresses the weapon, the off hand and the mantle in a tier's recipe and the
## seals pressed on them (§3.2, §6.6): the same meshes, new uniforms. The weapon
## wears the shader as a next_pass over its sculpt; a buckler crest on the off
## hand and a band at the collar wear it outright, and show only while sealed.
func apply_equipment_tier_and_seals(catalog: ArsenalCatalog, loadout: PlayerLoadoutResource) -> void:
	_ensure_seal_materials()
	var tier: EquipmentTierResource = catalog.get_tier(loadout.equipped_tier_id) if loadout != null else null
	if tier == null:
		return
	_applied_tier_id = tier.tier_id
	var weapon_seal: ScribeCardResource = catalog.get_card(loadout.weapon_seal_card_id)
	var offhand_seal: ScribeCardResource = catalog.get_card(loadout.offhand_seal_card_id)
	var mantle_seal: ScribeCardResource = catalog.get_card(loadout.mantle_seal_card_id)
	_apply_tier_to_material(_weapon_seal_pass, tier, weapon_seal, 0.5, 0.2, WEAPON_SEAL_BLEND)
	_apply_tier_to_material(_offhand_seal_material, tier, offhand_seal, 0.5, 0.5, 1.0)
	_apply_tier_to_material(_mantle_seal_material, tier, mantle_seal, 0.5, 0.6, 1.0)
	_attach_weapon_seal_pass()
	if has_rig():
		_ensure_offhand_crest().visible = offhand_seal != null
		_ensure_mantle_band().visible = mantle_seal != null
	_seal_state = {
		"tier_id": tier.tier_id,
		"weapon_sealed": weapon_seal != null,
		"offhand_sealed": offhand_seal != null,
		"mantle_sealed": mantle_seal != null,
		"weapon_seal": weapon_seal.card_id if weapon_seal != null else &"",
		"offhand_seal": offhand_seal.card_id if offhand_seal != null else &"",
		"mantle_seal": mantle_seal.card_id if mantle_seal != null else &"",
	}


## The tier and seals shown now ("tier_id", "weapon_sealed", ...), empty before any were applied.
func seal_state() -> Dictionary:
	return _seal_state


## The seal materials, for checks: the weapon's pass, the off hand's and the mantle's.
func seal_materials() -> Array[ShaderMaterial]:
	_ensure_seal_materials()
	return [_weapon_seal_pass, _offhand_seal_material, _mantle_seal_material]


func _ensure_seal_materials() -> void:
	if _weapon_seal_pass != null:
		return
	_weapon_seal_pass = ShaderMaterial.new()
	_offhand_seal_material = ShaderMaterial.new()
	_mantle_seal_material = ShaderMaterial.new()
	for material: ShaderMaterial in [_weapon_seal_pass, _offhand_seal_material, _mantle_seal_material]:
		material.shader = SEAL_SHADER
	_weapon_seal_pass.set_shader_parameter(&"base_blend", WEAPON_SEAL_BLEND)


func _apply_tier_to_material(material: ShaderMaterial, tier: EquipmentTierResource, seal_card: ScribeCardResource,
		band_center: float, band_width: float, blend: float) -> void:
	if material == null:
		return
	var recipe: Dictionary = tier.shader_uniforms()
	for uniform: String in recipe:
		material.set_shader_parameter(StringName(uniform), recipe[uniform])
	material.set_shader_parameter(&"seal_band_center", band_center)
	material.set_shader_parameter(&"seal_band_width", band_width)
	material.set_shader_parameter(&"base_blend", blend)
	if seal_card != null:
		material.set_shader_parameter(&"has_scribe_seal", true)
		material.set_shader_parameter(&"ink_primary_color", seal_card.ink_primary_color)
		material.set_shader_parameter(&"ink_secondary_color", seal_card.ink_secondary_color)
		material.set_shader_parameter(&"foil_grade", int(seal_card.foil_grade))
	else:
		material.set_shader_parameter(&"has_scribe_seal", false)
		material.set_shader_parameter(&"foil_grade", 0)


## The weapon's sculpt keeps its own atelier material; the seal shader rides it as a next_pass.
func _attach_weapon_seal_pass() -> void:
	if _weapon_seal_pass == null or _applied_tier_id == &"":
		return
	for material: Material in _weapon_materials:
		if material != _weapon_seal_pass:
			material.next_pass = _weapon_seal_pass


## The buckler crest: a disc on the off hand's forearm (on the Greatshield's face for a Shield-Sworn).
func _ensure_offhand_crest() -> MeshInstance3D:
	if is_instance_valid(_offhand_crest):
		return _offhand_crest
	_offhand_crest = ShapeKit.no_shadow(ShapeKit.cylinder("SealCrest", CREST_RADIUS, CREST_RADIUS, CREST_THICKNESS,
		Vector3(-0.1, -0.13, -0.045), _offhand_seal_material))
	_offhand_crest.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	socket(HeroRigBuilder.OFF_HAND_SOCKET).add_child(_offhand_crest)
	return _offhand_crest


## The mantle band: a ring at the collar, hung from the chest so it rides the hero's lean.
func _ensure_mantle_band() -> MeshInstance3D:
	if is_instance_valid(_mantle_band):
		return _mantle_band
	_mantle_band = ShapeKit.no_shadow(ShapeKit.torus("SealMantleBand", MANTLE_BAND_RADIUS - MANTLE_BAND_WIDTH, MANTLE_BAND_RADIUS,
		Vector3(0.0, MANTLE_BAND_RISE, 0.0), _mantle_seal_material))
	socket(HeroRigBuilder.BACK_STOW_SOCKET).add_child(_mantle_band)
	return _mantle_band


## The 18-frame (0.30 s) Pocket-Pull (§4.2, §6.6), in the hero's own space: the
## off hand darts to the pouch (frames 1-5), whips a 1.6x glowing card high
## overhead (6-12) and slams its light into the weapon (13-18) as every seal
## flares and the swing trail takes the card's ink. No Camera3D is touched: the
## 4.8 m split-screen view never zooms, cuts or turns for it.
func play_pocket_pull_flourish(catalog: ArsenalCatalog, card_id: StringName, slot_index: int) -> void:
	var card: ScribeCardResource = catalog.get_card(card_id) if catalog != null else null
	if card == null:
		return
	_ensure_seal_materials()
	_is_flourishing = true
	_flourish_card = card_id
	_flourish_slot = slot_index
	_pocket_pulls += 1
	_seal_flare = POCKET_PULL_FLARE
	_push_seal_flare()
	pocket_pull_started.emit(card_id, slot_index)
	if has_rig():
		_start_choreography(Choreography.POCKET_PULL, card.ink_primary_color)
		_overhead_card = _build_overhead_card(card)
	elif is_inside_tree():
		var timer: SceneTreeTimer = get_tree().create_timer(POCKET_PULL_DURATION_SEC)
		timer.timeout.connect(_finish_pocket_pull_flourish)
	else:
		_finish_pocket_pull_flourish()


## Whether a Pocket-Pull is in flight, and how many have played on this hero.
func is_flourishing() -> bool:
	return _is_flourishing


func pocket_pull_count() -> int:
	return _pocket_pulls


## The seals' ignition flare right now (2.2 at the slam, fading from 0.75 after).
func seal_flare() -> float:
	return _seal_flare


## The 1.6x card raised overhead: a glowing slab in the card's inks with its own halo, its top under 2.5 m.
func _build_overhead_card(card: ScribeCardResource) -> MeshInstance3D:
	var face: StandardMaterial3D = StorybookMaterial.glowing(VELLUM_COLOR.lerp(card.ink_secondary_color, 0.35), CARD_GLOW)
	face.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var size: Vector3 = CARD_SIZE * POCKET_PULL_CARD_SCALE
	var height: float = minf(POCKET_PULL_CARD_HEIGHT, POCKET_PULL_CARD_CAP - size.y * 0.5)
	var raised: MeshInstance3D = ShapeKit.no_shadow(ShapeKit.box("OverheadCard", size, Vector3(0.0, height, 0.0), face))
	var halo: StandardMaterial3D = StorybookMaterial.glowing(card.ink_primary_color, 2.2)
	halo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.albedo_color = Color(card.ink_primary_color, 0.7)
	raised.add_child(ShapeKit.no_shadow(ShapeKit.box("SignHalo", Vector3(size.x + CARD_HALO * 2.0, size.y + CARD_HALO * 2.0, size.z * 0.4),
		Vector3.ZERO, halo)))
	raised.visible = false
	add_child(raised)
	return raised


## Frames 1-5 the small card leaves the pouch in the off hand; 6-12 the big one
## hangs overhead; 13-18 the slam: the hand card is tucked, the seals at their brightest.
func _play_pocket_pull(t: float) -> void:
	var frame: float = t * 60.0
	if is_instance_valid(_card):
		_card.visible = frame >= 3.0 and frame < 6.0
	if is_instance_valid(_overhead_card):
		_overhead_card.visible = frame >= 6.0 and frame < 13.0
		_overhead_card.rotation.y = sin(t * 14.0) * 0.25
	if frame >= 13.0:
		_seal_flare = POCKET_PULL_FLARE
		_push_seal_flare()


func _finish_pocket_pull_flourish() -> void:
	if not _is_flourishing:
		return
	_is_flourishing = false
	_seal_flare = POCKET_PULL_AFTERGLOW
	_push_seal_flare()
	var card_id: StringName = _flourish_card
	var slot: int = _flourish_slot
	_flourish_card = &""
	_flourish_slot = -1
	pocket_pull_completed.emit(card_id, slot)


## The afterglow fades once the pull is done.
func _update_seal_flare(delta: float) -> void:
	if _is_flourishing or _seal_flare <= 0.0:
		return
	_seal_flare = maxf(0.0, _seal_flare - AFTERGLOW_FADE_PER_SEC * delta)
	_push_seal_flare()


func _push_seal_flare() -> void:
	if _weapon_seal_pass == null or is_equal_approx(_seal_flare, _seal_flare_shown):
		return
	_seal_flare_shown = _seal_flare
	for material: ShaderMaterial in [_weapon_seal_pass, _offhand_seal_material, _mantle_seal_material]:
		material.set_shader_parameter(&"active_invocation_flare", _seal_flare)


static func _tint_children(root: Node3D, color: Color) -> void:
	for mesh: Node in root.get_children():
		var shape: MeshInstance3D = mesh as MeshInstance3D
		var material: StandardMaterial3D = (shape.mesh as PrimitiveMesh).material as StandardMaterial3D if shape != null else null
		if material != null:
			material.albedo_color = color
			material.emission = color


## The Flow-Link Pulse: a crisp white-gold ring that bursts out from the waist.
func flash_flow_ring() -> void:
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "FlowLinkRing"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.material = StorybookMaterial.glowing(ActorBase.FLOW_LINK_COLOR, 3.0)
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0.0, FLOW_RING_HEIGHT, 0.0)
	ring.scale = Vector3.ONE * 0.4
	add_child(ring)
	var tween: Tween = ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(FLOW_RING_RADIUS, 0.6, FLOW_RING_RADIUS), FLOW_RING_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(ring.queue_free)


## A Saffron-Gold Wayfarer Pennant unfurls over the hero for 3 s: the new
## level, and what it brought ("Hedgerow Iron Falchion").
func show_milestone_pennant(level: int, granted: String) -> void:
	if is_instance_valid(_pennant):
		_pennant.queue_free()
	_pennant = Node3D.new()
	_pennant.name = "WayfarerPennant"
	_pennant.position = Vector3(0.0, PENNANT_HEIGHT, 0.0)
	# On the hero itself, not the puppet, so it stays upright while they lean into swings.
	actor.add_child(_pennant)
	var pole: MeshInstance3D = ShapeKit.cylinder("Pole", 0.025, 0.025, 1.1, Vector3(-0.55, 0.0, 0.0), _cel(OAK_COLOR, PENNANT_COLOR))
	_pennant.add_child(pole)
	var cloth: Node3D = Node3D.new()
	cloth.name = "Cloth"
	cloth.position = Vector3(-0.55, 0.45, 0.0)
	_pennant.add_child(cloth)
	cloth.add_child(ShapeKit.box("Banner", Vector3(1.1, 0.42, 0.02), Vector3(0.55, -0.21, 0.0), StorybookMaterial.glowing(PENNANT_COLOR, 0.6)))
	cloth.add_child(ShapeKit.box("Hem", Vector3(1.1, 0.05, 0.03), Vector3(0.55, -0.44, 0.0), StorybookMaterial.glowing(PENNANT_COLOR.lightened(0.5), 1.2)))
	var title: Label3D = Label3D.new()
	title.name = "Title"
	title.text = "LEVEL %d" % level if granted == "" else "LEVEL %d\n%s" % [level, granted]
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.no_depth_test = true
	title.font_size = 44
	title.outline_size = 12
	title.pixel_size = 0.006
	title.modulate = PENNANT_COLOR.lightened(0.35)
	title.position = Vector3(0.0, 0.75, 0.0)
	_pennant.add_child(title)
	cloth.scale = Vector3(0.05, 1.0, 1.0)
	var tween: Tween = _pennant.create_tween()
	tween.tween_property(cloth, "scale", Vector3.ONE, PENNANT_UNFURL).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(PENNANT_TIME - PENNANT_UNFURL * 2.0)
	tween.tween_property(cloth, "scale", Vector3(0.05, 1.0, 1.0), PENNANT_UNFURL)
	tween.tween_callback(_pennant.queue_free)


## The pennant over the hero right now, or null.
func milestone_pennant() -> Node3D:
	return _pennant if is_instance_valid(_pennant) and not _pennant.is_queued_for_deletion() else null


## Lights the whole hero (a hit flash or flow glow); black turns it off.
func set_glow(color: Color) -> void:
	for material: Material in materials:
		StorybookMaterial.set_glow(material, color)


## A cel material for the pennant's pole.
func _cel(color: Color, rim: Color) -> Material:
	return StorybookMaterial.actor(color, rim)
