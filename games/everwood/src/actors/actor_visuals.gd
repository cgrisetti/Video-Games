## A hero's storybook puppet (07_EXPEDITION_HUD_AND_ART_GDD.md §4.1), built in code
## from simple shapes in the storybook cel look, so every Fellowship reads at a
## glance from the split-screen camera:
##   the Shield-Sworn   a crested warden helm, broad pauldrons in plate, a heavy
##                      cape and a banded oak-and-brass Greatshield
##   the Wayfarers      a feathered ranger hood, a travel cloak that streams out
##                      as they run, and a quiver (with a bow) or a Scribe Satchel
##   the Lantern-Bearers a pointed scribe hat, a mantle and a swinging brass
##                      Tether-Lantern that really glows
## The tunic keeps the seat's colour; a tabard front and back (so it reads from
## the camera behind you) shows the Secondary Calling's colour. Armor shows by
## weight (a sash, a leather jerkin, or plate), trimmed in the Calling's colour;
## the weapon in the right hand comes from its item (PropBuilder).
##
## Drop a model at res://assets/models/<class_id>.glb (say, a CC0 KayKit or
## Quaternius character named shield_tank.glb) and it's used instead of the
## procedural body.
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
## Lantern-Tether circles the hero with three glowing motes.
class_name ActorVisuals
extends Node3D

const MODEL_FOLDER: String = "res://assets/models/"
const SKIN_COLOR: Color = Color(0.96, 0.8, 0.66)
const TROUSER_COLOR: Color = Color(0.3, 0.26, 0.24)
const LEATHER_COLOR: Color = Color(0.45, 0.3, 0.18)
const METAL_COLOR: Color = Color(0.66, 0.68, 0.72)
const BRASS_COLOR: Color = Color(0.88, 0.68, 0.3)
const OAK_COLOR: Color = Color(0.46, 0.31, 0.18)
const EYE_COLOR: Color = Color(0.12, 0.1, 0.1)
const LANTERN_GLOW: Color = Color(1.0, 0.78, 0.4)
## Cape length per Fellowship: a heavy oilskin, a travel cloak, a short mantle.
const CAPE_LENGTHS: Array[float] = [1.0, 0.9, 0.6]
## The cape lifts back this far (radians) at full running speed...
const CAPE_SWING: float = 0.95
## ...hangs back with this tilt at rest (clear of the skirt), and follows this quickly.
## Heroes face -Z, so a cape tilts back with a negative turn about X and an arm
## reaches forward with a positive one.
const CAPE_REST: float = 0.2
const CAPE_SHARPNESS: float = 8.0
const LANTERN_SWAY: float = 0.25
## The tabard flaps hanging below the belt, front and back.
const TABARD_SIZE: Vector3 = Vector3(0.3, 0.4, 0.03)
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
## A bow swells from its grip in the left hand.
const BOW_GRIP: Vector3 = Vector3(-0.5, 1.15, -0.46)
## The Flow-Link Pulse ring at the waist.
const FLOW_RING_TIME: float = 0.35
const FLOW_RING_RADIUS: float = 1.1
const FLOW_RING_HEIGHT: float = 0.95
## The Wayfarer Pennant (11 GDD §6): Saffron-Gold, 2.4 m above the head, 3 s.
const PENNANT_TIME: float = 3.0
const PENNANT_HEIGHT: float = 2.4
const PENNANT_UNFURL: float = 0.4
const PENNANT_COLOR: Color = Color(0.98, 0.72, 0.18)
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

var actor: ActorBase
## Every cel material on the puppet, lit together by a hit flash.
var materials: Array[Material] = []
## A dropped-in .glb model in use instead of the procedural body, if there is one.
var model: Node3D

var _cape_pivot: Node3D
var _lantern: Node3D
var _age: float = 0.0
## The weapon in hand (ActorBase's prop) and where it swells from.
var _weapon: Node3D
var _weapon_pivot: Vector3 = Vector3.ZERO
var _weapon_materials: Array[Material] = []
var _channel_action: StringName = &""
var _channel_left: float = 0.0
var _channel_peak: float = 1.0
var _channel_color: Color = UNINKED_CHANNEL_COLOR
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


## Builds the puppet for the actor's current loadout (again after a Scribe Desk swap or a new Calling).
func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	materials.clear()
	_cape_pivot = null
	_lantern = null
	model = load_model(actor.loadout.class_id)
	if model != null:
		add_child(model)
		return
	var loadout: ClassLoadoutResource = actor.loadout
	var row: int = Callings.fellowship_row(loadout.class_id)
	# Trim and tabard in the Secondary Calling's colour (its SecondaryCallingResource).
	var calling: SecondaryCallingResource = Callings.secondary(Callings.resolve(loadout.class_id, loadout.calling))
	var trim: Color = calling.trim_color if calling != null else Callings.UNSWORN_TRIM
	var body: Color = loadout.body_color
	var weight: EquipmentItemResource.ArmorWeight = loadout.armor.armor_weight if loadout.armor != null else EquipmentItemResource.ArmorWeight.MEDIUM
	_build_body(body)
	_build_tabard(body, trim)
	_build_armor(weight, body, trim)
	_build_head(row, body, trim)
	_build_cape(row, body, trim)
	_build_off_hand(row, loadout, trim)


## The weapon this hero holds (built by ActorBase from its item), so R and L+R can swell it.
func set_weapon(weapon_root: Node3D, item: EquipmentItemResource) -> void:
	_weapon = weapon_root
	_weapon_pivot = BOW_GRIP if item.weapon_type == EquipmentItemResource.WeaponType.BOW else item.trail_base
	_weapon_materials.clear()
	_channel_left = 0.0
	for mesh: Node in weapon_root.find_children("*", "MeshInstance3D", true, false):
		var primitive: PrimitiveMesh = (mesh as MeshInstance3D).mesh as PrimitiveMesh
		if primitive != null and primitive.material != null:
			_weapon_materials.append(primitive.material)


## How big the weapon is drawn right now (2.0 at the height of an R channel).
func weapon_scale() -> float:
	return _weapon.scale.x if is_instance_valid(_weapon) else 1.0


## Starts the swell when an R or L+R begins, and plays it out (every peer calls
## this each frame with the action the hero is doing).
func update_channel(delta: float, action: CombatActionResource) -> void:
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


## Sign-Flow's look on this hero, on every peer (CombatDirector.show_sign_coat):
## SignFlowComponent.CoatLook TRAIL_TUCK (until cleared), FLARE or COAT (for
## `seconds`), or CLEAR. `ink` is the leaf's Sign colour, `ambient` its Place-Card's tint.
func show_sign_coat(look: int, ink: Color, ambient: Color, mode: int, seconds: float) -> void:
	match look:
		SignFlowComponent.CoatLook.FLARE:
			_flare_left = maxf(seconds, 0.0)
			_flare_ink = ink
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


## Lights the whole puppet (a hit flash or flow glow); black turns it off.
func set_glow(color: Color) -> void:
	for material: Material in materials:
		StorybookMaterial.set_glow(material, color)


## The cape streams back with speed; the lantern swings.
func update_motion(delta: float, velocity: Vector3, move_speed: float) -> void:
	_age += delta
	if _cape_pivot != null:
		var run: float = clampf(Vector2(velocity.x, velocity.z).length() / maxf(0.1, move_speed), 0.0, 1.0)
		var wanted: float = CAPE_REST + CAPE_SWING * run + sin(_age * 3.0) * 0.04
		_cape_pivot.rotation.x = lerpf(_cape_pivot.rotation.x, -wanted, 1.0 - exp(-CAPE_SHARPNESS * delta))
	if _lantern != null:
		_lantern.rotation.z = sin(_age * 2.4) * LANTERN_SWAY * 0.4
		_lantern.rotation.x = sin(_age * 1.7) * LANTERN_SWAY * 0.3


# --- Parts ------------------------------------------------------------------

func _build_body(body: Color) -> void:
	var trousers: Material = _cel(TROUSER_COLOR, body)
	for side: float in [-1.0, 1.0]:
		add_child(ShapeKit.capsule("Leg", 0.11, 0.8, Vector3(side * 0.14, 0.4, 0.0), trousers))
		add_child(ShapeKit.box("Boot", Vector3(0.16, 0.12, 0.26), Vector3(side * 0.14, 0.06, -0.04), _cel(LEATHER_COLOR.darkened(0.3), body)))
	var tunic: Material = _cel(body, body)
	add_child(ShapeKit.cylinder("Tunic", 0.31, 0.37, 0.72, Vector3(0.0, 1.06, 0.0), tunic))
	add_child(ShapeKit.cylinder("Skirt", 0.39, 0.35, 0.26, Vector3(0.0, 0.68, 0.0), _cel(body.darkened(0.2), body)))
	add_child(ShapeKit.cylinder("Belt", 0.38, 0.38, 0.08, Vector3(0.0, 0.82, 0.0), _cel(LEATHER_COLOR, body)))
	add_child(ShapeKit.box("Buckle", Vector3(0.1, 0.08, 0.04), Vector3(0.0, 0.82, -0.38), _cel(BRASS_COLOR, body)))
	# Arms: the right reaches forward to the weapon's grip, the left hangs to the off hand.
	var sleeve: Material = _cel(body.darkened(0.08), body)
	var right: Node3D = _pivot("RightArm", Vector3(0.39, 1.36, 0.0), Vector3(0.95, 0.0, 0.12))
	right.add_child(ShapeKit.capsule("Sleeve", 0.08, 0.6, Vector3(0.0, -0.28, 0.0), sleeve))
	right.add_child(ShapeKit.sphere("Hand", 0.07, Vector3(0.0, -0.6, 0.0), _cel(SKIN_COLOR, body)))
	var left: Node3D = _pivot("LeftArm", Vector3(-0.39, 1.36, 0.0), Vector3(0.35, 0.0, -0.15))
	left.add_child(ShapeKit.capsule("Sleeve", 0.08, 0.6, Vector3(0.0, -0.28, 0.0), sleeve))
	left.add_child(ShapeKit.sphere("Hand", 0.07, Vector3(0.0, -0.6, 0.0), _cel(SKIN_COLOR, body)))


## The Calling's tabard: a flap below the belt in front and one behind, flared a little.
func _build_tabard(body: Color, trim: Color) -> void:
	var cloth: Material = _cel(trim, body)
	for side: float in [-1.0, 1.0]:
		var flap: MeshInstance3D = ShapeKit.box("Tabard" if side < 0.0 else "TabardBack", TABARD_SIZE, Vector3(0.0, 0.57, side * 0.41), cloth)
		flap.rotation = Vector3(side * 0.08, 0.0, 0.0)
		add_child(flap)


func _build_armor(weight: EquipmentItemResource.ArmorWeight, body: Color, trim: Color) -> void:
	match weight:
		EquipmentItemResource.ArmorWeight.LIGHT:
			var sash: MeshInstance3D = ShapeKit.box("Sash", Vector3(0.09, 0.82, 0.05), Vector3(0.0, 1.08, -0.33), _cel(trim, body))
			sash.rotation = Vector3(0.0, 0.0, 0.62)
			add_child(sash)
		EquipmentItemResource.ArmorWeight.MEDIUM:
			add_child(ShapeKit.cylinder("Jerkin", 0.34, 0.39, 0.5, Vector3(0.0, 1.12, 0.0), _cel(LEATHER_COLOR, body)))
			add_child(ShapeKit.cylinder("JerkinTrim", 0.35, 0.35, 0.05, Vector3(0.0, 1.36, 0.0), _cel(trim, body)))
		EquipmentItemResource.ArmorWeight.HEAVY:
			var metal: Material = _cel(METAL_COLOR, body)
			add_child(ShapeKit.box("Breastplate", Vector3(0.6, 0.52, 0.14), Vector3(0.0, 1.12, -0.29), metal))
			for side: float in [-1.0, 1.0]:
				var pauldron: MeshInstance3D = ShapeKit.sphere("Pauldron", 0.22, Vector3(side * 0.42, 1.4, 0.0), metal)
				pauldron.scale = Vector3(1.15, 0.7, 1.2)
				add_child(pauldron)
				add_child(ShapeKit.torus("PauldronTrim", 0.2, 0.24, Vector3(side * 0.42, 1.36, 0.0), _cel(trim, body)))


func _build_head(row: int, body: Color, trim: Color) -> void:
	add_child(ShapeKit.sphere("Head", 0.21, Vector3(0.0, 1.62, 0.0), _cel(SKIN_COLOR, body)))
	# Two dark eyes show which way the hero faces.
	var eyes: StandardMaterial3D = StandardMaterial3D.new()
	eyes.albedo_color = EYE_COLOR
	for side: float in [-1.0, 1.0]:
		add_child(ShapeKit.sphere("Eye", 0.035, Vector3(side * 0.075, 1.65, -0.19), eyes))
	match row:
		0:
			var metal: Material = _cel(METAL_COLOR, body)
			add_child(ShapeKit.cylinder("Helm", 0.23, 0.23, 0.16, Vector3(0.0, 1.71, 0.0), metal))
			var dome: MeshInstance3D = ShapeKit.sphere("Dome", 0.23, Vector3(0.0, 1.78, 0.0), metal)
			dome.scale = Vector3(1.0, 0.72, 1.0)
			add_child(dome)
			add_child(ShapeKit.box("Crest", Vector3(0.06, 0.18, 0.4), Vector3(0.0, 1.98, 0.02), _cel(trim, body)))
		1:
			var hood: MeshInstance3D = ShapeKit.sphere("Hood", 0.26, Vector3(0.0, 1.68, 0.04), _cel(body.darkened(0.25), body))
			hood.scale = Vector3(1.0, 1.08, 1.05)
			add_child(hood)
			add_child(ShapeKit.tilted(ShapeKit.cone("HoodTip", 0.12, 0.3, Vector3(0.0, 1.82, 0.24), _cel(body.darkened(0.25), body)), Vector3(-1.0, 0.0, 0.0)))
			var feather: MeshInstance3D = ShapeKit.box("Feather", Vector3(0.03, 0.34, 0.07), Vector3(0.21, 1.86, 0.05), _cel(trim, body))
			feather.rotation = Vector3(0.0, 0.0, -0.45)
			add_child(feather)
		_:
			var hat: Material = _cel(body.darkened(0.3), body)
			add_child(ShapeKit.cylinder("Brim", 0.34, 0.34, 0.03, Vector3(0.0, 1.78, 0.0), hat))
			add_child(ShapeKit.tilted(ShapeKit.cone("Hat", 0.2, 0.5, Vector3(0.0, 2.04, 0.04), hat), Vector3(-0.18, 0.0, 0.0)))
			add_child(ShapeKit.cylinder("HatBand", 0.205, 0.205, 0.05, Vector3(0.0, 1.82, 0.0), _cel(trim, body)))


func _build_cape(row: int, body: Color, trim: Color) -> void:
	var length: float = CAPE_LENGTHS[row]
	_cape_pivot = _pivot("Cape", Vector3(0.0, 1.44, 0.27), Vector3(-CAPE_REST, 0.0, 0.0))
	_cape_pivot.add_child(ShapeKit.box("Cloth", Vector3(0.62, length, 0.04), Vector3(0.0, -length * 0.5, 0.0), _cel(body.darkened(0.35), body)))
	_cape_pivot.add_child(ShapeKit.box("Hem", Vector3(0.62, 0.06, 0.05), Vector3(0.0, -length + 0.03, 0.0), _cel(trim, body)))


func _build_off_hand(row: int, loadout: ClassLoadoutResource, trim: Color) -> void:
	var body: Color = loadout.body_color
	match row:
		0:
			# The banded oak-and-brass Greatshield on the left arm.
			var shield: Node3D = _pivot("Greatshield", Vector3(-0.5, 1.0, -0.12), Vector3(0.0, 0.22, 0.0))
			shield.add_child(ShapeKit.box("Board", Vector3(0.08, 0.95, 0.7), Vector3.ZERO, _cel(OAK_COLOR, body)))
			for y: float in [-0.28, 0.28]:
				shield.add_child(ShapeKit.box("Band", Vector3(0.1, 0.07, 0.72), Vector3(0.0, y, 0.0), _cel(BRASS_COLOR, body)))
			shield.add_child(ShapeKit.sphere("Boss", 0.09, Vector3(-0.05, 0.0, 0.0), _cel(BRASS_COLOR, body)))
			shield.add_child(ShapeKit.box("Emblem", Vector3(0.1, 0.22, 0.22), Vector3(-0.02, 0.0, 0.0), _cel(trim, body)))
		2:
			# The brass Tether-Lantern swinging from the left hand, really glowing.
			_lantern = _pivot("TetherLantern", Vector3(-0.47, 0.82, -0.18), Vector3.ZERO)
			_lantern.add_child(ShapeKit.cylinder("Cord", 0.012, 0.012, 0.22, Vector3(0.0, -0.11, 0.0), _cel(LEATHER_COLOR, body)))
			_lantern.add_child(ShapeKit.cylinder("Cage", 0.09, 0.11, 0.22, Vector3(0.0, -0.33, 0.0), _cel(BRASS_COLOR, body)))
			var flame: MeshInstance3D = ShapeKit.sphere("Flame", 0.065, Vector3(0.0, -0.33, 0.0), StorybookMaterial.glowing(LANTERN_GLOW, 3.0))
			flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_lantern.add_child(flame)
			_lantern.add_child(ShapeKit.cone("Cap", 0.11, 0.1, Vector3(0.0, -0.18, 0.0), _cel(BRASS_COLOR, body)))
			var light: OmniLight3D = OmniLight3D.new()
			light.name = "Light"
			light.light_color = LANTERN_GLOW
			light.light_energy = 0.8
			light.omni_range = 3.0
			light.position = Vector3(0.0, -0.33, 0.0)
			_lantern.add_child(light)
		_:
			if loadout.is_ranged():
				# A quiver on the back, arrows fletched in the Calling's colour.
				var quiver: Node3D = _pivot("Quiver", Vector3(0.16, 1.18, 0.3), Vector3(0.0, 0.0, -0.35))
				quiver.add_child(ShapeKit.cylinder("Case", 0.09, 0.08, 0.6, Vector3.ZERO, _cel(LEATHER_COLOR, body)))
				for index: int in 3:
					quiver.add_child(ShapeKit.box("Fletch", Vector3(0.03, 0.12, 0.05), Vector3((float(index) - 1.0) * 0.04, 0.36, 0.0), _cel(trim, body)))
			else:
				var satchel: Node3D = _pivot("ScribeSatchel", Vector3(0.36, 0.86, 0.06), Vector3.ZERO)
				satchel.add_child(ShapeKit.box("Bag", Vector3(0.12, 0.24, 0.28), Vector3.ZERO, _cel(LEATHER_COLOR, body)))
				satchel.add_child(ShapeKit.box("Flap", Vector3(0.13, 0.08, 0.29), Vector3(0.0, 0.1, 0.0), _cel(trim, body)))


# --- Shape helpers ----------------------------------------------------------

## A cel material rimmed in the hero's colour, remembered for hit flashes.
func _cel(color: Color, rim: Color) -> Material:
	var material: ShaderMaterial = StorybookMaterial.actor(color, rim)
	materials.append(material)
	return material


func _pivot(pivot_name: String, where: Vector3, rotation_radians: Vector3) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = pivot_name
	pivot.position = where
	pivot.rotation = rotation_radians
	add_child(pivot)
	return pivot
