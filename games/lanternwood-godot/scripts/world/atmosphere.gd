@tool
class_name Atmosphere
extends RefCounted

# Life in the air: fireflies and floating motes that drift round the gnome, and leaves that
# tumble down from the trees. They follow the gnome, so there's always some nearby.

# Fireflies and dust motes: tiny glowing specks that wander and pulse.
static func fireflies(amount: int) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Fireflies"
	particles.amount = amount
	particles.lifetime = 7.0
	particles.preprocess = 7.0
	particles.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 8, 40))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(14, 1.6, 11)
	process.direction = Vector3(0, 1, 0)
	process.spread = 180.0
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.25
	process.gravity = Vector3(0, 0.02, 0)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.6
	process.turbulence_noise_scale = 3.0
	process.turbulence_influence_min = 0.05
	process.turbulence_influence_max = 0.15
	process.scale_min = 0.6
	process.scale_max = 1.3
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.3), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	particles.process_material = process
	particles.position = Vector3(0, 1.6, -5) # Ahead of the gnome, not round the camera.
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.vertex_color_use_as_albedo = true
	glow.albedo_color = Color(1.0, 0.85, 0.45) * 3.0
	glow.albedo_texture = _soft_dot()
	quad.material = glow
	particles.draw_pass_1 = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


# Leaves drifting down, turning over as they fall.
static func falling_leaves(amount: int) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "FallingLeaves"
	particles.amount = amount
	particles.lifetime = 9.0
	particles.preprocess = 9.0
	particles.visibility_aabb = AABB(Vector3(-25, -10, -25), Vector3(50, 20, 50))
	particles.transform_align = GPUParticles3D.TRANSFORM_ALIGN_DISABLED
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(16, 1, 10)
	process.direction = Vector3(1, -0.3, 0.4)
	process.spread = 40.0
	process.initial_velocity_min = 0.3
	process.initial_velocity_max = 0.8
	process.gravity = Vector3(0.15, -0.55, 0.05)
	process.angular_velocity_min = -160.0
	process.angular_velocity_max = 160.0
	process.particle_flag_rotate_y = true
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.2
	process.turbulence_influence_min = 0.1
	process.turbulence_influence_max = 0.2
	process.scale_min = 0.7
	process.scale_max = 1.2
	var tints := Gradient.new()
	tints.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	tints.colors = PackedColorArray([Color("#e8a23a"), Color("#d0602a"), Color("#c9b04a"), Color("#9cb54a")])
	var variety := GradientTexture1D.new()
	variety.gradient = tints
	process.color_initial_ramp = variety
	particles.process_material = process
	particles.position = Vector3(0, 5.0, -10)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.11, 0.11)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_texture = _single_leaf()
	leaf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	leaf.alpha_scissor_threshold = 0.5
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf.vertex_color_use_as_albedo = true
	leaf.backlight_enabled = true
	leaf.backlight = Color(0.5, 0.35, 0.2)
	leaf.roughness = 0.8
	quad.material = leaf
	particles.draw_pass_1 = quad
	return particles


static func _soft_dot() -> GradientTexture2D:
	var dot := GradientTexture2D.new()
	dot.width = 32
	dot.height = 32
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	dot.gradient = gradient
	return dot


static func _single_leaf() -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	Art._draw_leaf(image, Vector2(8, 56), -PI / 4.0, 70.0, 16.0, 1.0, false)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
