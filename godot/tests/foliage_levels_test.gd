extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	assert(packed != null, "Garden world could not be loaded")
	var locked_session := GameSession.new()
	locked_session.new_game()
	assert(not locked_session.select_level(&"forest_path"), "Forest should remain locked at the start")
	var measurements: Dictionary = {}
	for level_id in WorldLevelCatalog.ORDER:
		var session := GameSession.new()
		session.new_game()
		session.mission_stage = 4
		assert(session.select_level(level_id), "Level could not be selected: %s" % level_id)
		var world := packed.instantiate() as RebuiltGardenWorld
		world.configure_level(level_id)
		root.add_child(world)
		world.setup(session)
		await physics_frame
		var foliage := world.foliage_scatter
		var level_profile := WorldLevelCatalog.get_generation_profile(level_id)
		assert(foliage != null, "LOD foliage system missing in %s" % level_id)
		assert(foliage.source_tree_count >= int(level_profile.tree_count) * 0.85, "Tree scatter is too sparse in %s" % level_id)
		assert(foliage.source_plant_count >= int(level_profile.understory_count) * 0.85, "Understory scatter is too sparse in %s" % level_id)
		assert(foliage.far_proxy_count == 0 and foliage.medium_proxy_count == 0, "Spherical tree proxy silhouettes are still active")
		assert(foliage.imported_mesh_count > 0, "No imported flo-bit meshes are active")
		assert(world.grass_field.biome_id == level_id, "Grass biome does not match the active level")
		var source_meshes := get_nodes_in_group("lod_foliage_source")
		var found_local_source := false
		for source_mesh_value in source_meshes:
			var source_mesh := source_mesh_value as MeshInstance3D
			if source_mesh != null and foliage.is_ancestor_of(source_mesh):
				found_local_source = true
				assert(source_mesh.visibility_range_end > 0.0, "Source foliage has no distance culling")
				break
		assert(found_local_source, "No local LOD source mesh found")
		var sample_source := source_meshes[0] as MeshInstance3D
		foliage.set_quality_profile(0)
		var performance_distance := sample_source.visibility_range_end
		foliage.set_quality_profile(3)
		assert(sample_source.visibility_range_end > performance_distance, "Foliage quality profile does not extend LOD distance")
		measurements[level_id] = {
			"trees": foliage.source_tree_count,
			"plants": foliage.source_plant_count,
			"grass_height": world.grass_field.maximum_height_factor,
			"pines": _usage_for_prefix(foliage.asset_usage, "pine_tree"),
			"mushrooms": _usage_for_prefix(foliage.asset_usage, "mushroom"),
		}
		root.remove_child(world)
		world.free()
		await process_frame
	assert(int(measurements[&"forest_path"]["trees"]) > int(measurements[&"home_garden"]["trees"]) * 2, "Forest level is not materially denser than the home garden")
	assert(float(measurements[&"giant_garden"]["grass_height"]) > float(measurements[&"home_garden"]["grass_height"]) * 1.8, "Giant garden grass is not giant enough")
	assert(int(measurements[&"forest_path"]["pines"]) > int(measurements[&"shaping_estate"]["pines"]) * 4, "Forest profile does not favor pine trees")
	assert(int(measurements[&"forest_path"]["mushrooms"]) > int(measurements[&"shaping_estate"]["mushrooms"]), "Forest profile does not favor mushrooms")
	print("FOLIAGE_LEVELS_OK: %s" % measurements)
	packed = null
	await process_frame
	quit()


func _usage_for_prefix(usage: Dictionary, prefix: String) -> int:
	var total := 0
	for asset_name: Variant in usage:
		if str(asset_name).begins_with(prefix):
			total += int(usage[asset_name])
	return total
