## Writes each zone's AudioStreamSynchronized from its four baked acoustic stems
## (16_ADAPTIVE_AUDIO_ARCHITECTURE.md §1.1, Tier 1): res://assets/audio/music/<profile_id>_sync.tres,
## which AudioDirector loads before anything else. tools/build_audio_stems.py runs it after
## Godot has imported the .ogg files; to run it alone:
##   godot --headless --path . -s res://tools/build_audio_resources.gd
## It checks every stem loops, that the four of a zone are one length, and that the length is
## the profile's loop (its bars at its tempo), and fails if not.
extends SceneTree

const LENGTH_TOLERANCE_SEC: float = 0.02


func _initialize() -> void:
	var written: int = 0
	var problems: Array[String] = []
	for profile: ZoneMusicProfileResource in AudioCatalog.zones():
		var stems: Array[AudioStream] = AudioDirector.baked_stems(profile.profile_id)
		if stems.size() != ZoneMusicProfileResource.STEM_COUNT:
			problems.append("%s: its four stems aren't all baked and imported" % profile.profile_id)
			continue
		var sync: AudioStreamSynchronized = AudioStreamSynchronized.new()
		sync.stream_count = ZoneMusicProfileResource.STEM_COUNT
		for layer: int in ZoneMusicProfileResource.STEM_COUNT:
			var stem: AudioStreamOggVorbis = stems[layer] as AudioStreamOggVorbis
			if stem == null or not stem.loop:
				problems.append("%s stem %d isn't a looping Ogg Vorbis stream" % [profile.profile_id, layer])
			elif absf(stem.get_length() - profile.loop_sec()) > LENGTH_TOLERANCE_SEC:
				problems.append("%s stem %d is %.3f s, but the profile loops %.3f s" % [profile.profile_id, layer, stem.get_length(), profile.loop_sec()])
			sync.set_sync_stream(layer, stems[layer])
			sync.set_sync_stream_volume(layer, profile.explore_db(layer))
		var path: String = AudioDirector.sync_path(profile.profile_id)
		var error: Error = ResourceSaver.save(sync, path)
		if error != OK:
			problems.append("couldn't save %s (error %d)" % [path, error])
			continue
		written += 1
		print("[Audio] %s: %.2f s, %d stems" % [path, profile.loop_sec(), ZoneMusicProfileResource.STEM_COUNT])
	for problem: String in problems:
		printerr("[Audio] %s" % problem)
	print("[Audio] %d AudioStreamSynchronized resources written" % written)
	quit(0 if problems.is_empty() else 1)
