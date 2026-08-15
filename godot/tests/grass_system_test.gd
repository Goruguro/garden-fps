extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var started_at := Time.get_ticks_msec()
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	assert(packed != null, "Garden world could not be loaded")
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	await physics_frame
	var field := world.grass_field
	assert(field != null, "Dense grass field is missing")
	assert(field.total_clusters >= 25000, "Expected at least 25,000 GPU grass clusters")
	assert(field.get_rendered_blade_capacity() >= 175000, "Expected at least 175,000 detailed blade capacity")
	var sampled_height_range := field.maximum_height_factor - field.minimum_height_factor
	assert(sampled_height_range > 0.24, "Grass height field is too uniform")
	assert(sampled_height_range < 0.58, "Grass height field still contains excessive walls")
	assert(field.mirrored_cluster_count > field.total_clusters * 0.35, "Grass mirroring is too rare to break repetition")
	assert(field.tilted_cluster_count > field.total_clusters * 0.42, "Grass tilt variation is too rare")
	var first_shape_values: PackedFloat32Array = field.cells[0]["shapes"]
	var shape_min := 1.0
	var shape_max := 0.0
	for shape_value in first_shape_values:
		shape_min = minf(shape_min, shape_value)
		shape_max = maxf(shape_max, shape_value)
	assert(shape_min < 0.2 and shape_max > 0.8, "Grass curve shapes do not cover a natural range")
	var local_height_a := field.get_height_factor_at(Vector3(12.0, 0.0, 8.0))
	var local_height_b := field.get_height_factor_at(Vector3(12.35, 0.0, 8.2))
	assert(absf(local_height_a - local_height_b) < 0.12, "Grass height changes abruptly inside a patch")
	assert(field.cells.size() >= 80, "Expected spatial grass cells for distance culling")
	field.set_quality_profile(0)
	var quality_cell: Dictionary = field.cells[0]
	var lod_multimeshes: Array = quality_cell["multimeshes"]
	var lod_instances: Array = quality_cell["instances"]
	assert(lod_multimeshes.size() == 3 and lod_instances.size() == 3, "Grass does not provide three LOD tiers")
	assert((lod_multimeshes[0] as MultiMesh).mesh != (lod_multimeshes[1] as MultiMesh).mesh, "Near and medium grass use the same geometry")
	assert((lod_multimeshes[1] as MultiMesh).mesh != (lod_multimeshes[2] as MultiMesh).mesh, "Medium and far grass use the same geometry")
	assert((lod_instances[0] as MultiMeshInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Near grass should cast shadows")
	assert((lod_instances[1] as MultiMeshInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Medium grass should not cast shadows")
	assert((lod_instances[2] as MultiMeshInstance3D).visibility_range_begin > 0.0, "Far grass LOD begins too close to the camera")
	var quality_multimesh := quality_cell["multimesh"] as MultiMesh
	assert(quality_multimesh.visible_instance_count < quality_multimesh.instance_count, "Performance profile did not reduce grass density")
	field.set_quality_profile(2)
	assert(quality_multimesh.visible_instance_count == quality_multimesh.instance_count, "High profile did not restore full grass density")
	var first_cell: Dictionary = field.cells[0]
	var positions: PackedVector3Array = first_cell["positions"]
	assert(not positions.is_empty(), "First grass cell contains no instances")
	var cut_point := positions[0]
	assert(field.has_uncut_at(cut_point, 0.4), "Test grass is not available before cutting")
	var nearby_origin := cut_point + Vector3(0.0, 2.0, 2.0)
	assert(field.is_physics_reachable(cut_point, nearby_origin, root.world_3d.direct_space_state), "Jolt terrain reach query failed")
	var removed := field.cut_at(cut_point, 1.25, false)
	assert(removed > 0, "Trimmer cut did not remove grass")
	assert(field.cut_clusters == removed, "Cut counter does not match changed instances")
	var lod_cut_counts: Array = first_cell["lod_cut_counts"]
	assert(lod_cut_counts[0] == lod_cut_counts[1] and lod_cut_counts[1] == lod_cut_counts[2], "Cut state did not synchronize across every grass LOD")
	assert(int(lod_cut_counts[0]) > 0, "LOD cut counters were not updated")
	assert(not field.has_uncut_at(cut_point, 0.18), "Grass remained at the center of the cut")
	field.spawn_cut_effect(cut_point, removed)
	await process_frame
	assert(field.get_node_or_null("GrassCutBurst") is GPUParticles3D, "Grass fragment effect was not created")
	assert(field.get_node_or_null("GrassCutAudio") is AudioStreamPlayer3D, "Spatial grass cutting sound was not created")
	assert(ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics", "Jolt Physics is not active")
	var elapsed := Time.get_ticks_msec() - started_at
	print("GRASS_SYSTEM_OK: clusters=%d blades=%d height_range=%.2f-%.2f mirrored=%d tilted=%d cells=%d lods=3 cut=%d build_ms=%d Jolt=true" % [
		field.total_clusters,
		field.get_rendered_blade_capacity(),
		field.minimum_height_factor,
		field.maximum_height_factor,
		field.mirrored_cluster_count,
		field.tilted_cluster_count,
		field.cells.size(),
		removed,
		elapsed
	])
	root.remove_child(world)
	world.free()
	packed = null
	await process_frame
	await process_frame
	quit()
