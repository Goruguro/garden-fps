extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profiles: Dictionary = {}
	for level_id in WorldLevelCatalog.ORDER:
		var profile := WorldLevelCatalog.get_generation_profile(level_id)
		assert(profile != null, "Generation profile is missing: %s" % level_id)
		assert(profile.profile_id == level_id, "Profile id does not match the level: %s" % level_id)
		assert(profile.validate().is_empty(), "Generation profile is invalid: %s" % level_id)
		assert(profile.grass_max_height > profile.grass_min_height, "Grass height range is empty: %s" % level_id)
		assert(profile.grass_mirror_chance > 0.25, "Grass mirroring is disabled: %s" % level_id)
		var recipe := ProceduralMapRecipes.get_recipe(level_id)
		assert(recipe["seed"] == profile.seed, "Map recipe seed drifted from the central profile")
		assert(is_equal_approx(float(recipe["terrain_amplitude"]), profile.terrain_amplitude), "Terrain recipe drifted from the central profile")
		profiles[level_id] = profile
	assert((profiles[&"forest_path"] as MapGenerationProfile).tree_count > (profiles[&"home_garden"] as MapGenerationProfile).tree_count * 3, "Forest biome is not dense enough")
	assert((profiles[&"forest_path"] as MapGenerationProfile).terrain_amplitude > (profiles[&"home_garden"] as MapGenerationProfile).terrain_amplitude * 2.5, "Forest terrain is not distinct enough")
	assert((profiles[&"giant_garden"] as MapGenerationProfile).grass_max_height > (profiles[&"home_garden"] as MapGenerationProfile).grass_max_height * 2.0, "Giant biome scale is not distinct enough")
	print("MAP_GENERATION_PROFILES_OK: profiles=%d central_settings=true weighted_assets=true" % profiles.size())
	await process_frame
	quit()
