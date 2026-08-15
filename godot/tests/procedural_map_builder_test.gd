extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var provider := TerrainHeightProvider.new()
	provider.configure(null, 0.0)
	root.add_child(provider)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8a805e")
	var signatures: Dictionary = {}
	for level_id in WorldLevelCatalog.ORDER:
		var recipe := ProceduralMapRecipes.get_recipe(level_id)
		assert(ProceduralMapRecipes.validate(recipe).is_empty(), "Built-in map recipe is invalid: %s" % level_id)
		var builder := ProceduralMapBuilder.new()
		root.add_child(builder)
		var started_at := Time.get_ticks_msec()
		var stats := builder.build(recipe, provider, material)
		var elapsed := Time.get_ticks_msec() - started_at
		assert(int(stats["paths"]) == recipe["paths"].size(), "Not every recipe path was generated")
		assert(int(stats["path_vertices"]) >= int(stats["paths"]) * 12, "Generated path mesh is too coarse")
		assert(int(stats["exclusions"]) > int(stats["paths"]), "Path and clearing exclusions were not generated")
		assert(int(stats["decorations"]) > 0, "Automatic decoration clusters are empty")
		assert(elapsed < 1000, "Map skeleton generation is unexpectedly slow")
		signatures[level_id] = stats["signature"]
		root.remove_child(builder)
		builder.free()
	var json_recipe := ProceduralMapRecipes.load_json_recipe("res://data/maps/map_template.json")
	assert(json_recipe.get("id") == &"wildflower_valley", "JSON map id was not loaded")
	assert(ProceduralMapRecipes.validate(json_recipe).is_empty(), "JSON map template is invalid")
	var first_builder := ProceduralMapBuilder.new()
	var second_builder := ProceduralMapBuilder.new()
	root.add_child(first_builder)
	root.add_child(second_builder)
	var first_stats := first_builder.build(json_recipe, provider, material)
	var second_stats := second_builder.build(json_recipe, provider, material)
	assert(first_stats["signature"] == second_stats["signature"], "The same seed did not produce a deterministic map")
	var variant := ProceduralMapRecipes.create_variant(&"forest_path", &"forest_variant", 998877, {"terrain_amplitude": 0.18})
	assert(variant["id"] == &"forest_variant" and variant["seed"] == 998877, "Runtime map variant could not be created")
	var unique_signatures: Dictionary = {}
	for signature: Variant in signatures.values():
		unique_signatures[signature] = true
	assert(unique_signatures.size() == WorldLevelCatalog.ORDER.size(), "Built-in maps did not produce unique signatures")
	print("PROCEDURAL_MAP_BUILDER_OK: maps=%d json=true deterministic=true signatures=%s" % [signatures.size(), signatures])
	root.remove_child(first_builder)
	root.remove_child(second_builder)
	first_builder.free()
	second_builder.free()
	root.remove_child(provider)
	provider.free()
	await process_frame
	quit()
