extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	assert(packed != null, "Garden world could not be loaded")
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	var start_y := world.player.global_position.y
	var local_heights := PackedFloat32Array()
	for sample_position in [Vector3.ZERO, Vector3(24, 0, 24), Vector3(48, 0, 48), Vector3(96, 0, 96), Vector3(-96, 0, 64)]:
		if absf(sample_position.x) <= 48.0 and absf(sample_position.z) <= 48.0:
			local_heights.append(world.terrain_provider.get_height(sample_position))
		print("TERRAIN_SAMPLE: position=%s height=%.3f texture=%s" % [
			sample_position,
			world.terrain_provider.get_height(sample_position),
			world.terrain_runtime.terrain.data.get_texture_id(sample_position)
		])
	var local_min := INF
	var local_max := -INF
	for local_height in local_heights:
		local_min = minf(local_min, local_height)
		local_max = maxf(local_max, local_height)
	assert(local_max - local_min > 0.25, "The playable home garden is still visually flat")
	var collision_rid: RID = world.terrain_runtime.terrain.collision.get_rid()
	print("TERRAIN_COLLISION_STATE: mode=%s enabled=%s rid=%s shapes=%d" % [
		world.terrain_runtime.terrain.collision.mode,
		world.terrain_runtime.terrain.collision.is_enabled(),
		collision_rid.is_valid(),
		PhysicsServer3D.body_get_shape_count(collision_rid) if collision_rid.is_valid() else -1
	])
	if collision_rid.is_valid() and PhysicsServer3D.body_get_shape_count(collision_rid) > 0:
		var shape_rid := PhysicsServer3D.body_get_shape(collision_rid, 0)
		print("TERRAIN_COLLISION_BODY: transform=%s shape_transform=%s shape_type=%s layer=%s in_world=%s" % [
			PhysicsServer3D.body_get_state(collision_rid, PhysicsServer3D.BODY_STATE_TRANSFORM),
			PhysicsServer3D.body_get_shape_transform(collision_rid, 0),
			PhysicsServer3D.shape_get_type(shape_rid),
			PhysicsServer3D.body_get_collision_layer(collision_rid),
			PhysicsServer3D.body_get_space(collision_rid) == root.world_3d.space
		])
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(3.5, 40.0, 27.0), Vector3(3.5, -10.0, 27.0), 1)
	query.exclude = [world.player.get_rid()]
	var hit := root.world_3d.direct_space_state.intersect_ray(query)
	print("TERRAIN_RAY_HIT: %s" % hit)
	for _frame in 90:
		await physics_frame
	var terrain_y: float = world.terrain_provider.get_height(world.player.global_position)
	print("TERRAIN_PHYSICS_SAMPLE: player_y=%.3f terrain_y=%.3f grounded=%s" % [world.player.global_position.y, terrain_y, world.player.is_grounded_for_gameplay()])
	assert(world.player.global_position.y > terrain_y - 0.2, "Player fell through Terrain3D")
	assert(world.player.global_position.y < start_y + 0.2, "Player did not settle on terrain")
	assert(world.player.is_grounded_for_gameplay(), "Player is not grounded on terrain")
	print("TERRAIN_PHYSICS_OK: player_y=%.3f terrain_y=%.3f grounded=true" % [world.player.global_position.y, terrain_y])
	root.remove_child(world)
	world.free()
	await process_frame
	quit()
