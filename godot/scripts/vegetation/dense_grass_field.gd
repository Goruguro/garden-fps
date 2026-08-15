class_name DenseGrassField
extends Node3D

signal grass_cut(world_position: Vector3, cluster_count: int)

const CELL_SIZE := 8.0
const FIELD_MIN := Vector2(-48.0, -42.0)
const FIELD_MAX := Vector2(48.0, 42.0)
const CLUSTERS_PER_CELL := 260
const LOD_DENSITY_RATIOS := [1.0, 0.72, 0.36]
const LOD_RANGES := [
	[0.0, 38.0, 0.0, 14.0],
	[18.0, 74.0, 16.0, 20.0],
	[48.0, 118.0, 22.0, 28.0],
]
const GRASS_CUT_SOUND := preload("res://audio/sfx/grass_cut.ogg")

var total_clusters := 0
var cut_clusters := 0
var mirrored_cluster_count := 0
var tilted_cluster_count := 0
var cells: Array[Dictionary] = []
var height_provider: Node
var generation_profile: MapGenerationProfile
var last_interactor_position := Vector3(100000.0, 100000.0, 100000.0)
var biome_id := &"home_garden"
var biome_height_scale := 1.0
var biome_density_scale := 1.0
var grass_min_height := 0.48
var grass_max_height := 1.48
var mirror_chance := 0.45
var tilt_chance := 0.58
var maximum_tilt_degrees := 8.0
var shape_variation := 0.9
var height_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var density_noise := FastNoiseLite.new()
var color_noise := FastNoiseLite.new()
var minimum_height_factor := INF
var maximum_height_factor := 0.0
var map_exclusions: Array[Dictionary] = []
var grass_variant_usage: Dictionary = {}
var snow_zone_center := Vector2(-34.0, -28.0)
var snow_zone_radius := 12.0
var animated_cut_queue: Array[Dictionary] = []


func build(provider: Node, active_biome := &"home_garden", exclusions: Array = [], settings: MapGenerationProfile = null) -> void:
	set_process(true)
	height_provider = provider
	generation_profile = settings if settings != null else WorldLevelCatalog.get_generation_profile(active_biome)
	total_clusters = 0
	cut_clusters = 0
	mirrored_cluster_count = 0
	tilted_cluster_count = 0
	minimum_height_factor = INF
	maximum_height_factor = 0.0
	grass_variant_usage.clear()
	cells.clear()
	map_exclusions.clear()
	for exclusion_value: Variant in exclusions:
		map_exclusions.append(Dictionary(exclusion_value).duplicate(true))
	_configure_biome(active_biome)
	_configure_noise()
	var columns := int(ceil((FIELD_MAX.x - FIELD_MIN.x) / CELL_SIZE))
	var rows := int(ceil((FIELD_MAX.y - FIELD_MIN.y) / CELL_SIZE))
	for row in range(rows):
		for column in range(columns):
			_build_cell(column, row)


func set_quality_profile(profile: int) -> void:
	var profile_index := clampi(profile, 0, 3)
	var density_ratio: float = [0.38, 0.66, 1.0, 1.0][profile_index]
	var profile_ranges := [
		[[0.0, 24.0, 0.0, 9.0], [11.0, 43.0, 10.0, 14.0], [29.0, 68.0, 15.0, 19.0]],
		[[0.0, 31.0, 0.0, 12.0], [15.0, 57.0, 13.0, 17.0], [39.0, 91.0, 18.0, 23.0]],
		LOD_RANGES,
		[[0.0, 46.0, 0.0, 17.0], [22.0, 88.0, 19.0, 25.0], [58.0, 142.0, 27.0, 34.0]],
	]
	for cell: Dictionary in cells:
		var multimeshes: Array = cell["multimeshes"]
		var instances: Array = cell["instances"]
		for lod_level in range(3):
			var multimesh := multimeshes[lod_level] as MultiMesh
			var instance := instances[lod_level] as MultiMeshInstance3D
			var lod_density: float = LOD_DENSITY_RATIOS[lod_level]
			var visible_count := clampi(int(round(float(multimesh.instance_count) * density_ratio * lod_density)), 1, multimesh.instance_count)
			multimesh.visible_instance_count = visible_count
			_apply_visibility_range(instance, profile_ranges[profile_index][lod_level])
		cell["active_count"] = (multimeshes[0] as MultiMesh).visible_instance_count


func set_interactor_position(world_position: Vector3) -> void:
	if last_interactor_position.distance_squared_to(world_position) < 0.0025:
		return
	last_interactor_position = world_position
	GrassVisualFactory.set_interactor_position(world_position)


func _process(delta: float) -> void:
	var animation_delta := minf(delta, 0.05)
	for queue_index in range(animated_cut_queue.size() - 1, -1, -1):
		var entry: Dictionary = animated_cut_queue[queue_index]
		entry["delay"] = float(entry["delay"]) - animation_delta
		if float(entry["delay"]) > 0.0:
			animated_cut_queue[queue_index] = entry
			continue
		var multimeshes: Array = entry["multimeshes"]
		var instance_index := int(entry["index"])
		var custom_data: Color = entry["custom_data"]
		for multimesh_value: Variant in multimeshes:
			(multimesh_value as MultiMesh).set_instance_custom_data(instance_index, custom_data)
		animated_cut_queue.remove_at(queue_index)


func set_wetness(value: float) -> void:
	GrassVisualFactory.set_wetness(value)


func get_rendered_blade_capacity() -> int:
	return total_clusters * 7


func get_height_factor_at(world_position: Vector3) -> float:
	var broad_patch := height_noise.get_noise_2d(world_position.x, world_position.z) * 0.5 + 0.5
	var soft_detail := detail_noise.get_noise_2d(world_position.x, world_position.z) * 0.5 + 0.5
	# Broad world-space noise owns the silhouette; detail only breaks uniformity without height walls.
	var blended := smoothstep(0.08, 0.92, broad_patch * 0.91 + soft_detail * 0.09)
	blended = blended * blended * (3.0 - 2.0 * blended)
	return lerpf(grass_min_height, grass_max_height, blended)


func has_uncut_at(world_position: Vector3, radius := 1.35) -> bool:
	for cell: Dictionary in cells:
		if not _cell_overlaps(cell, world_position, radius):
			continue
		var positions: PackedVector3Array = cell["positions"]
		var flags: PackedByteArray = cell["cut_flags"]
		for index in range(positions.size()):
			if flags[index] == 0 and _flat_distance_squared(positions[index], world_position) <= radius * radius:
				return true
	return false


func is_physics_reachable(world_position: Vector3, tool_origin: Vector3, space_state: PhysicsDirectSpaceState3D) -> bool:
	if tool_origin.distance_to(world_position) > 4.7:
		return false
	var shape := SphereShape3D.new()
	shape.radius = 0.46
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), world_position + Vector3.UP * 0.16)
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return not space_state.intersect_shape(query, 8).is_empty()


func cut_at(world_position: Vector3, radius := 1.45, create_effect := true) -> int:
	var removed := 0
	for cell: Dictionary in cells:
		if not _cell_overlaps(cell, world_position, radius):
			continue
		var positions: PackedVector3Array = cell["positions"]
		var variations: PackedFloat32Array = cell["variations"]
		var tones: PackedFloat32Array = cell["tones"]
		var shapes: PackedFloat32Array = cell["shapes"]
		var flags: PackedByteArray = cell["cut_flags"]
		var multimeshes: Array = cell["multimeshes"]
		var lod_cut_counts: Array = cell["lod_cut_counts"]
		var cell_changed := false
		for index in range(positions.size()):
			if flags[index] != 0 or _flat_distance_squared(positions[index], world_position) > radius * radius:
				continue
			flags[index] = 1
			# A right-to-left stroke reaches right-side blades first, then crosses the patch.
			var sweep_phase := clampf((world_position.x + radius - positions[index].x) / maxf(radius * 2.0, 0.01), 0.0, 1.0)
			animated_cut_queue.append({
				"delay": sweep_phase * 0.42 + float(index % 5) * 0.008,
				"multimeshes": multimeshes,
				"index": index,
				"custom_data": Color(1.0, variations[index], tones[index], shapes[index]),
			})
			for lod_level in range(multimeshes.size()):
				lod_cut_counts[lod_level] = int(lod_cut_counts[lod_level]) + 1
			removed += 1
			cell_changed = true
		if cell_changed:
			cell["cut_flags"] = flags
			cell["lod_cut_counts"] = lod_cut_counts
	cut_clusters += removed
	if removed > 0:
		if create_effect:
			spawn_cut_effect(world_position, removed)
		grass_cut.emit(world_position, removed)
	return removed


func spawn_cut_effect(world_position: Vector3, intensity := 18) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "GrassCutBurst"
	particles.position = world_position + Vector3.UP * 0.22
	particles.one_shot = true
	particles.amount = clampi(intensity * 2, 18, 56)
	particles.lifetime = 0.72
	particles.explosiveness = 0.96
	particles.randomness = 0.48
	particles.visibility_aabb = AABB(Vector3(-2.0, -1.0, -2.0), Vector3(4.0, 4.0, 4.0))
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = 0.42
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 62.0
	process_material.initial_velocity_min = 1.5
	process_material.initial_velocity_max = 3.8
	process_material.gravity = Vector3(0.0, -7.2, 0.0)
	process_material.angular_velocity_min = -220.0
	process_material.angular_velocity_max = 220.0
	process_material.scale_min = 0.7
	process_material.scale_max = 1.35
	particles.process_material = process_material
	var fragment_mesh := QuadMesh.new()
	fragment_mesh.size = Vector2(0.035, 0.16)
	var fragment_material := StandardMaterial3D.new()
	fragment_material.albedo_color = Color("78ad39")
	fragment_material.roughness = 0.9
	fragment_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	fragment_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fragment_mesh.material = fragment_material
	particles.draw_pass_1 = fragment_mesh
	add_child(particles)
	particles.emitting = true
	var cut_audio := AudioStreamPlayer3D.new()
	cut_audio.name = "GrassCutAudio"
	cut_audio.stream = GRASS_CUT_SOUND
	cut_audio.position = world_position + Vector3.UP * 0.25
	cut_audio.volume_db = -7.0
	cut_audio.pitch_scale = randf_range(0.92, 1.08)
	cut_audio.max_distance = 18.0
	add_child(cut_audio)
	cut_audio.play()
	var cleanup := get_tree().create_timer(1.35)
	cleanup.timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.queue_free()
		if is_instance_valid(cut_audio):
			cut_audio.queue_free())


func _build_cell(column: int, row: int) -> void:
	var center_2d := FIELD_MIN + Vector2((float(column) + 0.5) * CELL_SIZE, (float(row) + 0.5) * CELL_SIZE)
	var rng := RandomNumberGenerator.new()
	rng.seed = (generation_profile.seed if generation_profile != null else 193939) + column * 92821 + row * 68917
	var positions := PackedVector3Array()
	var variations := PackedFloat32Array()
	var tones := PackedFloat32Array()
	var shapes := PackedFloat32Array()
	var height_factors := PackedFloat32Array()
	var density_value := density_noise.get_noise_2d(center_2d.x, center_2d.y) * 0.5 + 0.5
	var target_count := clampi(int(round(float(CLUSTERS_PER_CELL) * lerpf(0.55, 1.2, smoothstep(0.08, 0.92, density_value)) * biome_density_scale)), 72, int(float(CLUSTERS_PER_CELL) * 1.3))
	var attempts := 0
	while positions.size() < target_count and attempts < target_count * 7:
		attempts += 1
		var candidate := Vector3(
			center_2d.x + rng.randf_range(-CELL_SIZE * 0.5, CELL_SIZE * 0.5),
			0.0,
			center_2d.y + rng.randf_range(-CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		)
		if not _is_grass_allowed(candidate):
			continue
		candidate.y = height_provider.get_height(candidate) + 0.015 if height_provider != null else 0.015
		positions.append(candidate)
		variations.append(rng.randf())
		tones.append(rng.randf())
		shapes.append(lerpf(0.5, rng.randf(), shape_variation))
		var height_factor := get_height_factor_at(candidate)
		height_factors.append(height_factor)
		minimum_height_factor = minf(minimum_height_factor, height_factor)
		maximum_height_factor = maxf(maximum_height_factor, height_factor)
	if positions.is_empty():
		return
	var transforms: Array[Transform3D] = []
	var custom_data := PackedColorArray()
	for index in range(positions.size()):
		var mirrored := rng.randf() < mirror_chance
		var tilted := rng.randf() < tilt_chance
		var mirror_axis := -1.0 if mirrored else 1.0
		var scale_value := Vector3(
			rng.randf_range(0.86, 1.14) * mirror_axis,
			height_factors[index] * rng.randf_range(0.96, 1.04),
			rng.randf_range(0.86, 1.14)
		)
		var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		if tilted:
			var tilt_limit := deg_to_rad(maximum_tilt_degrees)
			basis = basis.rotated(Vector3.RIGHT, rng.randf_range(-tilt_limit, tilt_limit))
			basis = basis.rotated(Vector3.FORWARD, rng.randf_range(-tilt_limit, tilt_limit))
			tilted_cluster_count += 1
		if mirrored:
			mirrored_cluster_count += 1
		basis = basis.scaled(scale_value)
		transforms.append(Transform3D(basis, positions[index] - Vector3(center_2d.x, 0.0, center_2d.y)))
		custom_data.append(Color(0.0, variations[index], tones[index], shapes[index]))
	var multimeshes: Array[MultiMesh] = []
	var instances: Array[MultiMeshInstance3D] = []
	var palette := _grass_palette_at(center_2d)
	var grass_material := GrassVisualFactory.create_grass_material(palette[0], palette[1])
	# Imported tall/short assets have incompatible source scales and formed visible 8 m cell walls.
	var ready_variant := 0
	grass_variant_usage[ready_variant] = int(grass_variant_usage.get(ready_variant, 0)) + positions.size()
	for lod_level in range(3):
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.mesh = GrassVisualFactory.get_cluster_mesh(lod_level, ready_variant)
		multimesh.instance_count = positions.size()
		multimesh.visible_instance_count = clampi(int(round(float(positions.size()) * float(LOD_DENSITY_RATIOS[lod_level]))), 1, positions.size())
		for index in range(positions.size()):
			multimesh.set_instance_transform(index, transforms[index])
			multimesh.set_instance_custom_data(index, custom_data[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "GrassCell_%02d_%02d_LOD%d" % [column, row, lod_level]
		instance.position = Vector3(center_2d.x, 0.0, center_2d.y)
		instance.multimesh = multimesh
		instance.material_override = grass_material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if lod_level == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		instance.custom_aabb = AABB(Vector3(-CELL_SIZE * 0.5, -0.5, -CELL_SIZE * 0.5), Vector3(CELL_SIZE, maxf(3.4, grass_max_height * 2.1), CELL_SIZE))
		_apply_visibility_range(instance, LOD_RANGES[lod_level])
		add_child(instance)
		multimeshes.append(multimesh)
		instances.append(instance)
	var flags := PackedByteArray()
	flags.resize(positions.size())
	flags.fill(0)
	cells.append({
		"center": Vector3(center_2d.x, 0.0, center_2d.y),
		"positions": positions,
		"variations": variations,
		"tones": tones,
		"shapes": shapes,
		"height_factors": height_factors,
		"cut_flags": flags,
		"active_count": positions.size(),
		"multimesh": multimeshes[0],
		"instance": instances[0],
		"multimeshes": multimeshes,
		"instances": instances,
		"lod_cut_counts": [0, 0, 0]
	})
	total_clusters += positions.size()


func _configure_biome(active_biome: StringName) -> void:
	biome_id = active_biome
	match biome_id:
		&"shaping_estate":
			snow_zone_center = Vector2(-30.0, -25.0)
			snow_zone_radius = 14.0
		&"forest_path":
			snow_zone_center = Vector2(-31.0, -20.0)
			snow_zone_radius = 18.0
		&"giant_garden":
			snow_zone_center = Vector2(-32.0, -24.0)
			snow_zone_radius = 15.0
		_:
			snow_zone_center = Vector2(-34.0, -28.0)
			snow_zone_radius = 12.0
	if generation_profile != null:
		biome_height_scale = 1.0
		biome_density_scale = generation_profile.grass_density
		grass_min_height = generation_profile.grass_min_height
		grass_max_height = generation_profile.grass_max_height
		mirror_chance = generation_profile.grass_mirror_chance
		tilt_chance = generation_profile.grass_tilt_chance
		maximum_tilt_degrees = generation_profile.grass_max_tilt_degrees
		shape_variation = generation_profile.grass_shape_variation
		return
	match biome_id:
		&"shaping_estate":
			biome_height_scale = 0.78
			biome_density_scale = 0.86
		&"forest_path":
			biome_height_scale = 1.08
			biome_density_scale = 1.12
		&"giant_garden":
			biome_height_scale = 2.25
			biome_density_scale = 1.0
		_:
			biome_height_scale = 1.0
			biome_density_scale = 1.0


func _configure_noise() -> void:
	var biome_seed_offset := generation_profile.seed if generation_profile != null else int(biome_id.hash() % 100000)
	height_noise.seed = 71237 + biome_seed_offset
	height_noise.frequency = generation_profile.grass_patch_frequency if generation_profile != null else 0.022
	height_noise.fractal_octaves = 3
	height_noise.fractal_gain = 0.52
	detail_noise.seed = 19087 + biome_seed_offset
	detail_noise.frequency = generation_profile.grass_detail_frequency if generation_profile != null else 0.058
	detail_noise.fractal_octaves = 2
	detail_noise.fractal_gain = 0.45
	density_noise.seed = 88231 + biome_seed_offset
	density_noise.frequency = generation_profile.grass_density_frequency if generation_profile != null else 0.031
	density_noise.fractal_octaves = 2
	color_noise.seed = 44771 + biome_seed_offset
	color_noise.frequency = 0.026
	color_noise.fractal_octaves = 3


func _grass_palette_at(center: Vector2) -> Array[Color]:
	var snow_distance := center.distance_to(snow_zone_center)
	if snow_distance < snow_zone_radius + 3.0:
		var frost := 1.0 - smoothstep(snow_zone_radius - 3.0, snow_zone_radius + 3.0, snow_distance)
		return [Color("42594b").lerp(Color("7e8e83"), frost), Color("8eb676").lerp(Color("d8e1cf"), frost)]
	var value := color_noise.get_noise_2d(center.x, center.y) * 0.5 + 0.5
	var dry_blend := smoothstep(0.62, 0.9, value)
	var lush_blend := 1.0 - smoothstep(0.08, 0.38, value)
	var base := Color("29452a").lerp(Color("59603a"), dry_blend)
	var tip := Color("66834b").lerp(Color("a18e50"), dry_blend)
	base = base.lerp(Color("1f4b32"), lush_blend * 0.42)
	tip = tip.lerp(Color("5e8d5b"), lush_blend * 0.46)
	return [base, tip]


func _is_grass_allowed(position_value: Vector3) -> bool:
	if _is_map_excluded(position_value):
		return false
	var flat := Vector2(position_value.x, position_value.z)
	if absf(position_value.x) < 2.15 and position_value.z > -18.5:
		return false
	if flat.distance_to(Vector2(18.0, 18.0)) < 10.0:
		return false
	if flat.distance_to(Vector2(-12.0, -10.0)) < 7.0:
		return false
	if flat.distance_to(Vector2(15.0, -14.0)) < 6.5:
		return false
	if position_value.x > 0.0 and position_value.x < 20.5 and absf(position_value.z - 17.0) < 1.45:
		return false
	if position_value.x > -20.5 and position_value.x < 0.5 and absf(position_value.z + 11.0) < 1.35:
		return false
	if position_value.x > -8.0 and position_value.x < 4.0 and position_value.z > -29.5 and position_value.z < -18.5:
		return false
	return true


func _is_map_excluded(position_value: Vector3) -> bool:
	var point := Vector2(position_value.x, position_value.z)
	for zone in map_exclusions:
		var radius := float(zone.get("radius", 0.0))
		match StringName(zone.get("shape", &"circle")):
			&"circle":
				var center: Vector2 = zone.get("center", Vector2.ZERO)
				if point.distance_squared_to(center) <= radius * radius:
					return true
			&"segment":
				var start: Vector2 = zone.get("start", Vector2.ZERO)
				var end: Vector2 = zone.get("end", Vector2.ZERO)
				if _distance_to_segment_squared(point, start, end) <= radius * radius:
					return true
	return false


func _distance_to_segment_squared(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_squared_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(start + segment * t)


func _cell_overlaps(cell: Dictionary, world_position: Vector3, radius: float) -> bool:
	var center: Vector3 = cell["center"]
	return absf(center.x - world_position.x) <= CELL_SIZE * 0.5 + radius and absf(center.z - world_position.z) <= CELL_SIZE * 0.5 + radius


func _apply_visibility_range(instance: MultiMeshInstance3D, range_values: Array) -> void:
	instance.visibility_range_begin = float(range_values[0])
	instance.visibility_range_end = float(range_values[1])
	instance.visibility_range_begin_margin = float(range_values[2])
	instance.visibility_range_end_margin = float(range_values[3])


func _flat_distance_squared(a: Vector3, b: Vector3) -> float:
	var dx := a.x - b.x
	var dz := a.z - b.z
	return dx * dx + dz * dz
