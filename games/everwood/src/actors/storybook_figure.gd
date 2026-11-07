## A sculpted storybook figure that isn't a hero (docs/24_PAINTED_WORLD_PASS.md
## §5): the townsfolk's bodies. The same 24-bone skeleton and sculpted surfaces
## as the heroes (HeroMeshAtelier, HeroYouthAtelier for a village child), in any
## Calling's look dyed in the townsfolk's own colours, posed straight from the
## shared clip library: the easy idle standing, the country walk strolling.
## It animates only near a camera (ANIMATE_RANGE), at ANIMATE_HZ; past that it
## holds its last pose, so a whole village costs little.
class_name StorybookFigure
extends Node3D

const ANIMATE_RANGE: float = 45.0
const ANIMATE_HZ: float = 30.0
## The clips a figure plays: standing (a grown-up's easy stance, a child's idle) and walking.
const ADULT_IDLE: StringName = &"idle_steward_calm"
const WALK: StringName = HeroCombatAnimator.YOUTH_WALK
## A walk cycle carries this far (the clip's own stride).
const WALK_METRES: float = HeroCombatAnimator.YOUTH_WALK_METRES

var skeleton: Skeleton3D
var look: HeroAppearanceResource
var material: ShaderMaterial
## How fast the figure is walking (m/s; 0 standing). The owner sets it.
var walk_speed: float = 0.0
var _idle: StringName = ADULT_IDLE
var _clock: float = 0.0
var _cycle: float = 0.0
var _since_pose: float = 1.0


## Builds the figure: `base` a Calling's look (or a youth's), dyed with `tunic`
## and `trim`, wearing `coat` (an armour item id), its clock started at `phase` seconds.
func build(base: HeroAppearanceResource, coat: StringName, tunic: Color, trim: Color, phase: float) -> void:
	look = base.duplicate() as HeroAppearanceResource
	look.value_2_tunic_color = tunic
	if look.is_youth():
		look.patch_color = trim
	_idle = HeroCombatAnimator.YOUTH_IDLE if look.is_youth() else ADULT_IDLE
	_clock = phase
	skeleton = HeroRigBuilder.build_hero_skeleton()
	if look.is_youth():
		skeleton.scale = Vector3.ONE * HeroAppearanceResource.YOUTH_SKELETON_SCALE
	add_child(skeleton)
	material = HeroMeshAtelier.hero_material(look, trim)
	var meshes: Array[ArrayMesh] = HeroMeshAtelier.build_hero_surfaces(look, coat)
	for index: int in meshes.size():
		var surface: MeshInstance3D = MeshInstance3D.new()
		surface.name = ActorVisuals.REGION_NODES[index]
		surface.mesh = meshes[index]
		surface.skin = HeroRigBuilder.skin_of(skeleton)
		surface.material_override = material
		skeleton.add_child(surface)
		surface.skeleton = surface.get_path_to(skeleton)
	_pose(0.0)


## Hangs a prop in a socket (HeroRigBuilder.MAIN_HAND_SOCKET...) at `where`.
func hold(socket_name: StringName, prop: Node3D, where: Transform3D = Transform3D.IDENTITY) -> void:
	var socket: BoneAttachment3D = HeroRigBuilder.socket(skeleton, socket_name)
	if socket == null:
		return
	prop.transform = where
	socket.add_child(prop)


func _process(delta: float) -> void:
	if skeleton == null:
		return
	_clock += delta
	_since_pose += delta
	if walk_speed > 0.05:
		_cycle = fmod(_cycle + walk_speed * delta / WALK_METRES, 1.0)
	if _since_pose < 1.0 / ANIMATE_HZ or not _near_a_camera():
		return
	_pose(_since_pose)
	_since_pose = 0.0


func _near_a_camera() -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	return camera == null or camera.global_position.distance_to(global_position) < ANIMATE_RANGE


func _pose(_step: float) -> void:
	var clip: StringName = WALK if walk_speed > 0.05 else _idle
	var frames: float = float(HeroCombatAnimator.clip_info(clip).get("frames", 60))
	var frame: float = _cycle * frames if clip == WALK else fmod(_clock * HeroCombatAnimator.FPS, frames)
	var pose: Dictionary = HeroCombatAnimator.sample_pose(clip, frame)
	var rotations: Array = pose["rotations"]
	for bone: int in HeroRigBuilder.BONE_COUNT:
		skeleton.set_bone_pose_rotation(bone, rotations[bone])
	skeleton.set_bone_pose_position(HeroRigBuilder.Bone.HIPS, HeroRigBuilder.local_rests()[HeroRigBuilder.Bone.HIPS].origin + (pose["hips"] as Vector3))
	skeleton.set_bone_pose_scale(HeroRigBuilder.Bone.HIPS, pose["scale"])
