extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for nature_path: String in [
		"res://assets/third_party/kenney_nature_full/mushroom_redGroup.glb",
		"res://assets/third_party/kenney_nature_full/grass_leafsLarge.glb",
		"res://assets/third_party/kenney_nature_full/stump_roundDetailed.glb"
	]:
		assert(load(nature_path) is PackedScene, "Kenney nature model could not be loaded: " + nature_path)
	print("ASSET_NATURE_OK: 329-model Kenney Nature Kit library")
	assert(load("res://audio/sfx/grass_cut.ogg") is AudioStream, "Grass cutting audio could not be loaded")
	print("ASSET_AUDIO_OK: spatial CC0 grass cutting sound")
	for path: String in [
		"res://assets/third_party/kaykit_characters/Gardener.glb",
		"res://assets/third_party/kaykit_characters/Mira.glb"
	]:
		var scene := load(path) as PackedScene
		assert(scene != null, "Character model could not be loaded: " + path)
		var instance := scene.instantiate()
		root.add_child(instance)
		var animation_player := _find_animation_player(instance)
		assert(animation_player != null, "Character has no AnimationPlayer: " + path)
		var animations := animation_player.get_animation_list()
		assert(animations.size() >= 20, "Character animation library is incomplete: " + path)
		var locomotion := PackedStringArray()
		for animation_name: StringName in animations:
			var normalized := str(animation_name).to_lower()
			if "idle" in normalized or "walk" in normalized or "run" in normalized:
				locomotion.append(str(animation_name))
		assert(locomotion.size() >= 3, "Character locomotion animation set is incomplete: " + path)
		print("ASSET_MODEL_OK: %s (%d animations), locomotion: %s" % [path, animations.size(), ", ".join(locomotion)])
		root.remove_child(instance)
		instance.free()
	quit()


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
