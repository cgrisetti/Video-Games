extends SceneTree

# Bakes the fox's seamless skin from its shape (scripts/fox_shape.gd) into models/fox_body.res
# and models/fox_jaw.res. Run it after changing the fox's shape. From this folder:
#   godot --headless --path . --script res://tools/make_fox.gd
# It takes a minute or so.


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var fox: CharacterBody3D = load("res://scripts/fox.gd").new()
	fox._build_skeleton()
	var rest := {}
	for bone: String in FoxShape.BONES:
		rest[bone] = fox.rest_of(bone)
	print("Baking the fox's skin...")
	var meshes := FoxShape.bake(rest, fox.LEG_LENGTHS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://models"))
	for part: String in ["body", "jaw"]:
		var path := "res://models/fox_%s.res" % part
		var error := ResourceSaver.save(meshes[part], path, ResourceSaver.FLAG_COMPRESS)
		print("  saved %s%s" % [path, "" if error == OK else " (failed: %s)" % error_string(error)])
	fox.free()
	print("Done in %.0f s." % ((Time.get_ticks_msec() - started) / 1000.0))
	quit()
