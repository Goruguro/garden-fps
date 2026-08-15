class_name ProceduralMapRecipes
extends RefCounted

const RECIPES := {
	&"home_garden": {
		"terrain_style": &"gentle",
		"terrain_amplitude": 0.003,
		"paths": [
			{"id": "main", "width": 3.2, "points": [Vector2(0, 30), Vector2(-0.4, 18), Vector2(0.5, 4), Vector2(0, -15)]},
			{"id": "house", "width": 2.3, "points": [Vector2(0, 17), Vector2(8, 17.4), Vector2(18, 17)]},
			{"id": "workshop", "width": 2.0, "points": [Vector2(0, -11), Vector2(-6, -10.4), Vector2(-14, -11)]},
		],
		"clearings": [
			{"center": Vector2(18, 18), "radius": 10.8},
			{"center": Vector2(-12, -10), "radius": 7.8},
			{"center": Vector2(15, -14), "radius": 6.5},
			{"center": Vector2(-2, -24), "radius": 6.8},
		],
		"decor_clusters": [
			{"center": Vector2(-30, 24), "radius": 7.0, "count": 7, "palette": &"rocks"},
			{"center": Vector2(31, -27), "radius": 6.0, "count": 6, "palette": &"stumps"},
		],
	},
	&"shaping_estate": {
		"terrain_style": &"terraced",
		"terrain_amplitude": 0.025,
		"paths": [
			{"id": "promenade", "width": 4.2, "points": [Vector2(0, 31), Vector2(-0.7, 15), Vector2(0.5, -4), Vector2(0, -30)]},
			{"id": "crosswalk", "width": 3.0, "points": [Vector2(-28, -4), Vector2(-14, -3.4), Vector2(0, -4), Vector2(14, -4.6), Vector2(28, -4)]},
			{"id": "rose_walk", "width": 1.8, "points": [Vector2(-21, 16), Vector2(-12, 10), Vector2(-4, 14), Vector2(5, 10), Vector2(14, 15), Vector2(22, 10)]},
		],
		"clearings": [
			{"center": Vector2(0, -29), "radius": 12.5},
			{"center": Vector2(-14, 12), "radius": 4.2},
			{"center": Vector2(14, 12), "radius": 4.2},
			{"center": Vector2(-14, -12), "radius": 4.2},
			{"center": Vector2(14, -12), "radius": 4.2},
		],
		"decor_clusters": [
			{"center": Vector2(-18, 5), "radius": 9.0, "count": 14, "palette": &"flowers"},
			{"center": Vector2(18, 4), "radius": 9.0, "count": 14, "palette": &"flowers"},
		],
	},
	&"forest_path": {
		"terrain_style": &"rolling",
		"terrain_amplitude": 0.12,
		"paths": [
			{"id": "forest_trail", "width": 3.0, "points": [Vector2(0, 34), Vector2(-3, 23), Vector2(2, 12), Vector2(-2, 1), Vector2(3, -11), Vector2(-1, -23), Vector2(2, -37)]},
			{"id": "forager_loop", "width": 1.65, "points": [Vector2(-2, 7), Vector2(-13, 4), Vector2(-21, -5), Vector2(-15, -15), Vector2(-3, -11)]},
		],
		"clearings": [
			{"center": Vector2(0, 28), "radius": 5.0},
			{"center": Vector2(-17, -7), "radius": 6.0},
			{"center": Vector2(2, -33), "radius": 5.0},
		],
		"decor_clusters": [
			{"center": Vector2(-17, -7), "radius": 8.0, "count": 16, "palette": &"mushrooms"},
			{"center": Vector2(20, 17), "radius": 10.0, "count": 12, "palette": &"fallen_wood"},
			{"center": Vector2(-27, 24), "radius": 8.0, "count": 10, "palette": &"rocks"},
		],
	},
	&"giant_garden": {
		"terrain_style": &"hummocks",
		"terrain_amplitude": 0.075,
		"paths": [
			{"id": "giant_trail", "width": 5.0, "points": [Vector2(0, 34), Vector2(2, 22), Vector2(-2, 10), Vector2(3, -4), Vector2(-3, -18), Vector2(0, -36)]},
			{"id": "root_tunnel", "width": 2.4, "points": [Vector2(1, 4), Vector2(12, 0), Vector2(21, -8), Vector2(16, -18)]},
		],
		"clearings": [
			{"center": Vector2(-8, 18), "radius": 8.0},
			{"center": Vector2(9, 16), "radius": 8.5},
			{"center": Vector2(0, -27), "radius": 9.0},
		],
		"decor_clusters": [
			{"center": Vector2(-20, -4), "radius": 12.0, "count": 12, "palette": &"giant_mushrooms", "scale": 4.0},
			{"center": Vector2(22, -18), "radius": 10.0, "count": 10, "palette": &"giant_flowers", "scale": 4.5},
		],
	},
}


static func get_recipe(level_id: StringName, seed_override := 0) -> Dictionary:
	var recipe := Dictionary(RECIPES.get(level_id, RECIPES[&"home_garden"])).duplicate(true)
	var generation_profile := WorldLevelCatalog.get_generation_profile(level_id)
	recipe["id"] = level_id
	recipe["seed"] = seed_override if seed_override != 0 else generation_profile.seed
	recipe["terrain_style"] = StringName(generation_profile.terrain_style)
	recipe["terrain_amplitude"] = generation_profile.terrain_amplitude
	recipe["generation_profile"] = generation_profile
	return recipe


static func create_variant(base_level_id: StringName, variant_id: StringName, seed: int, overrides := {}) -> Dictionary:
	var recipe := get_recipe(base_level_id, seed)
	recipe["id"] = variant_id
	for key: Variant in overrides:
		recipe[key] = overrides[key]
	return recipe


static func load_json_recipe(resource_path: String) -> Dictionary:
	if not FileAccess.file_exists(resource_path):
		push_error("Harita tarifi bulunamadı: %s" % resource_path)
		return {}
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Harita tarifi geçerli JSON değil: %s" % resource_path)
		return {}
	var source := parsed as Dictionary
	var base_level_id := StringName(source.get("base_level", "home_garden"))
	var recipe := get_recipe(base_level_id, int(source.get("seed", 0)))
	for key: Variant in source:
		recipe[key] = source[key]
	recipe["id"] = StringName(recipe.get("id", base_level_id))
	recipe["terrain_style"] = StringName(recipe.get("terrain_style", &"gentle"))
	_normalize_json_vectors(recipe)
	return recipe


static func _normalize_json_vectors(recipe: Dictionary) -> void:
	var normalized_paths: Array = []
	for path_value: Variant in recipe.get("paths", []):
		var path_data := Dictionary(path_value).duplicate(true)
		var points: Array[Vector2] = []
		for point_value: Variant in path_data.get("points", []):
			if point_value is Array and point_value.size() >= 2:
				points.append(Vector2(float(point_value[0]), float(point_value[1])))
			elif point_value is Vector2:
				points.append(point_value)
		path_data["points"] = points
		normalized_paths.append(path_data)
	recipe["paths"] = normalized_paths
	for collection_key in ["clearings", "decor_clusters"]:
		var normalized_collection: Array = []
		for item_value: Variant in recipe.get(collection_key, []):
			var item := Dictionary(item_value).duplicate(true)
			var center_value: Variant = item.get("center", Vector2.ZERO)
			if center_value is Array and center_value.size() >= 2:
				item["center"] = Vector2(float(center_value[0]), float(center_value[1]))
			if item.has("palette"):
				item["palette"] = StringName(item["palette"])
			normalized_collection.append(item)
		recipe[collection_key] = normalized_collection


static func validate(recipe: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not recipe.has("id"):
		errors.append("Harita kimliği eksik.")
	if not recipe.has("seed"):
		errors.append("Harita seed değeri eksik.")
	if not recipe.get("paths", []) is Array:
		errors.append("Yol listesi geçersiz.")
	for path_value: Variant in recipe.get("paths", []):
		if not path_value is Dictionary or (path_value as Dictionary).get("points", []).size() < 2:
			errors.append("Her yol en az iki kontrol noktası içermeli.")
	return errors
