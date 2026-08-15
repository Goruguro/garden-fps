extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	await physics_frame
	var profile := WorldLevelCatalog.get_generation_profile(&"home_garden")
	assert(world.outer_biome_ring != null, "Çit dışı çim halkası oluşturulmadı")
	assert(world.outer_biome_ring.total_clusters == profile.outer_grass_count, "Dış çim sayısı harita profiliyle eşleşmiyor")
	assert(world.outer_biome_ring.sector_data.size() == 12, "Dış çim LOD dilimleri eksik")
	var outside_tree_count := 0
	for tree_transform in world.foliage_scatter.tree_transforms:
		var flat := Vector2(tree_transform.origin.x, tree_transform.origin.z)
		if flat.length() >= profile.outer_ring_start - 0.5:
			outside_tree_count += 1
	assert(outside_tree_count >= int(profile.outer_tree_count * 0.9), "Çit dışında yeterli ağaç yok")
	assert(world.foliage_scatter.source_plant_count >= profile.understory_count + int(profile.outer_plant_count * 0.85), "Çit dışı alt bitkiler seyrek")
	assert(load("res://assets/third_party/quaternius_stylized_nature/CommonTree_1.gltf") is PackedScene, "Quaternius ağaçları içe aktarılmadı")
	print("OUTER_BIOME_OK: grass=%d outside_trees=%d total_plants=%d sectors=12" % [
		world.outer_biome_ring.total_clusters, outside_tree_count, world.foliage_scatter.source_plant_count
	])
	root.remove_child(world)
	world.free()
	packed = null
	await process_frame
	quit()
