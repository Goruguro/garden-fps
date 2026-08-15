class_name ProceduralMapBuilder
extends Node3D

const COLLISION_FACTORY := preload("res://scripts/physics/garden_collision_factory.gd")

signal map_built(stats: Dictionary)

const PROP_PALETTES := {
	&"rocks": [
		"res://assets/third_party/kenney_nature_full/rock_smallA.glb",
		"res://assets/third_party/kenney_nature_full/rock_smallC.glb",
		"res://assets/third_party/kenney_nature_full/rock_smallF.glb",
	],
	&"stumps": [
		"res://assets/third_party/flo_bit_nature/tree_stump_1.glb",
		"res://assets/third_party/flo_bit_nature/tree_stump_2.glb",
	],
	&"flowers": [
		"res://assets/third_party/flo_bit_nature/flower_1.glb",
		"res://assets/third_party/flo_bit_nature/flower_2.glb",
		"res://assets/third_party/flo_bit_nature/flower_3.glb",
	],
	&"mushrooms": [
		"res://assets/third_party/flo_bit_nature/mushroom_1.glb",
		"res://assets/third_party/flo_bit_nature/mushroom_3.glb",
		"res://assets/third_party/flo_bit_nature/mushroom_group_1.glb",
	],
	&"fallen_wood": [
		"res://assets/third_party/kenney_nature_full/log.glb",
		"res://assets/third_party/kenney_nature_full/log_large.glb",
		"res://assets/third_party/kenney_nature_full/stump_old.glb",
	],
	&"giant_mushrooms": [
		"res://assets/third_party/flo_bit_nature/mushroom_5.glb",
		"res://assets/third_party/flo_bit_nature/mushroom_group_1.glb",
	],
	&"giant_flowers": [
		"res://assets/third_party/flo_bit_nature/flower_1.glb",
		"res://assets/third_party/flo_bit_nature/flower_3.glb",
	],
}

var height_provider: Node
var recipe: Dictionary = {}
var path_material: Material
var exclusion_zones: Array[Dictionary] = []
var path_nodes: Array[MeshInstance3D] = []
var decoration_nodes: Array[Node3D] = []
var path_vertex_count := 0
var build_signature := 0


func build(map_recipe: Dictionary, provider: Node, material: Material) -> Dictionary:
	var validation_errors := ProceduralMapRecipes.validate(map_recipe)
	if not validation_errors.is_empty():
		push_error("Harita tarifi geçersiz: %s" % ", ".join(validation_errors))
		return {}
	recipe = map_recipe.duplicate(true)
	height_provider = provider
	path_material = material
	_build_paths()
	_register_clearings()
	_build_decor_clusters()
	build_signature = _calculate_signature()
	var stats := get_stats()
	map_built.emit(stats)
	return stats


func get_stats() -> Dictionary:
	return {
		"id": recipe.get("id", &"unknown"),
		"seed": int(recipe.get("seed", 0)),
		"paths": path_nodes.size(),
		"path_vertices": path_vertex_count,
		"decorations": decoration_nodes.size(),
		"exclusions": exclusion_zones.size(),
		"signature": build_signature,
	}


func _build_paths() -> void:
	for path_value: Variant in recipe.get("paths", []):
		var path_data := path_value as Dictionary
		var samples := _sample_path(path_data.get("points", []), 5)
		if samples.size() < 2:
			continue
		var width := float(path_data.get("width", 2.5))
		var mesh := _create_path_mesh(samples, width)
		var instance := MeshInstance3D.new()
		instance.name = "GeneratedPath_%s" % str(path_data.get("id", path_nodes.size()))
		instance.mesh = mesh
		instance.material_override = path_material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end = 145.0
		instance.visibility_range_end_margin = 18.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(instance)
		path_nodes.append(instance)
		_register_path_exclusions(samples, width * 0.5 + 0.45)


func _sample_path(raw_points: Array, subdivisions: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_value: Variant in raw_points:
		points.append(point_value as Vector2)
	if points.size() < 2:
		return points
	var result := PackedVector2Array()
	for segment in range(points.size() - 1):
		var p0 := points[maxi(segment - 1, 0)]
		var p1 := points[segment]
		var p2 := points[segment + 1]
		var p3 := points[mini(segment + 2, points.size() - 1)]
		for step in range(subdivisions):
			var t := float(step) / float(subdivisions)
			result.append(_catmull_rom(p0, p1, p2, p3, t))
	result.append(points[points.size() - 1])
	return result


func _create_path_mesh(samples: PackedVector2Array, width: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var traveled := 0.0
	var seed_value := int(recipe.get("seed", 0))
	for index in range(samples.size()):
		var previous := samples[maxi(index - 1, 0)]
		var next := samples[mini(index + 1, samples.size() - 1)]
		var tangent := (next - previous).normalized()
		var right := Vector2(-tangent.y, tangent.x)
		var width_wave := sin(float(index) * 0.63 + float(seed_value % 97)) * 0.045 + 1.0
		var half_width := width * 0.5 * width_wave
		var left_point := samples[index] - right * half_width
		var right_point := samples[index] + right * half_width
		if index > 0:
			traveled += samples[index].distance_to(samples[index - 1])
		vertices.append(_project(left_point, 0.045))
		vertices.append(_project(right_point, 0.045))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0.0, traveled * 0.24))
		uvs.append(Vector2(1.0, traveled * 0.24))
		if index < samples.size() - 1:
			var current := index * 2
			indices.append_array(PackedInt32Array([
				current, current + 1, current + 3,
				current, current + 3, current + 2,
			]))
	path_vertex_count += vertices.size()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _register_path_exclusions(samples: PackedVector2Array, radius: float) -> void:
	for index in range(samples.size() - 1):
		exclusion_zones.append({
			"shape": &"segment",
			"start": samples[index],
			"end": samples[index + 1],
			"radius": radius,
		})


func _register_clearings() -> void:
	for clearing_value: Variant in recipe.get("clearings", []):
		var clearing := clearing_value as Dictionary
		exclusion_zones.append({
			"shape": &"circle",
			"center": clearing.get("center", Vector2.ZERO),
			"radius": float(clearing.get("radius", 4.0)),
		})


func _build_decor_clusters() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(recipe.get("seed", 0)) + 7781
	for cluster_value: Variant in recipe.get("decor_clusters", []):
		var cluster := cluster_value as Dictionary
		var palette_id: StringName = cluster.get("palette", &"rocks")
		var palette: Array = PROP_PALETTES.get(palette_id, PROP_PALETTES[&"rocks"])
		var center: Vector2 = cluster.get("center", Vector2.ZERO)
		var radius := float(cluster.get("radius", 5.0))
		var count := int(cluster.get("count", 5))
		var scale_multiplier := float(cluster.get("scale", 1.0))
		for index in range(count):
			var angle := rng.randf_range(0.0, TAU)
			var distance := radius * sqrt(rng.randf())
			var position_2d := center + Vector2(cos(angle), sin(angle)) * distance
			var asset_path: String = palette[rng.randi_range(0, palette.size() - 1)]
			var packed := load(asset_path) as PackedScene
			if packed == null:
				continue
			var instance := packed.instantiate() as Node3D
			if instance == null:
				continue
			instance.name = "GeneratedDecor_%s_%02d" % [palette_id, index]
			add_child(instance)
			instance.global_position = _project(position_2d, 0.02)
			instance.rotation.y = rng.randf_range(0.0, TAU)
			instance.scale = Vector3.ONE * rng.randf_range(0.72, 1.28) * scale_multiplier
			_configure_decor_lod(instance)
			_add_decor_hitbox(instance, palette_id)
			decoration_nodes.append(instance)


func _add_decor_hitbox(instance: Node3D, palette_id: StringName) -> void:
	match palette_id:
		&"rocks":
			COLLISION_FACTORY.add_visual_bounds_box(instance, "RockHitbox", Vector3(0.32, 0.24, 0.32), Vector3(0.82, 0.78, 0.82))
		&"stumps", &"fallen_wood":
			COLLISION_FACTORY.add_visual_bounds_box(instance, "WoodHitbox", Vector3(0.45, 0.35, 0.45), Vector3(0.76, 0.78, 0.76))
		&"giant_mushrooms", &"giant_flowers":
			COLLISION_FACTORY.add_cylinder(instance, "GiantPlantHitbox", Vector3(0.0, 0.8, 0.0), 0.22, 1.6)


func _configure_decor_lod(root: Node) -> void:
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D:
			var mesh_instance := current as MeshInstance3D
			mesh_instance.visibility_range_end = 62.0
			mesh_instance.visibility_range_end_margin = 10.0
			mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh_instance.lod_bias = 0.85
		for child in current.get_children():
			pending.append(child)


func _project(point: Vector2, offset: float) -> Vector3:
	var world_position := Vector3(point.x, 0.0, point.y)
	return height_provider.project(world_position, offset) if height_provider != null else world_position + Vector3.UP * offset


func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


func _calculate_signature() -> int:
	var signature_text := "%s|%d|%d|%d|%d" % [
		str(recipe.get("id", "unknown")),
		int(recipe.get("seed", 0)),
		path_nodes.size(),
		path_vertex_count,
		decoration_nodes.size(),
	]
	return signature_text.hash()
