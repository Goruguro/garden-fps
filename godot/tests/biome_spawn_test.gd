extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	for level_id in WorldLevelCatalog.ORDER:
		var session := GameSession.new()
		session.new_game()
		session.mission_stage = 4
		session.select_level(level_id)
		var world := packed.instantiate() as RebuiltGardenWorld
		world.configure_level(level_id)
		root.add_child(world)
		world.setup(session)
		await physics_frame
		var expected_spawn: Vector3 = WorldLevelCatalog.get_level(level_id)["spawn"]
		var ray := PhysicsRayQueryParameters3D.create(Vector3(expected_spawn.x, 10.0, expected_spawn.z), Vector3(expected_spawn.x, -3.0, expected_spawn.z), 1)
		ray.exclude = [world.player.get_rid()]
		var hit := root.world_3d.direct_space_state.intersect_ray(ray)
		print("BIOME_SPAWN_RAY: %s hit=%s normal=%s collider=%s shapes=%d" % [level_id, hit.get("position", Vector3.ZERO), hit.get("normal", Vector3.ZERO), (hit.get("collider") as Node).name if hit.get("collider") is Node else "none", PhysicsServer3D.body_get_shape_count(world.terrain_runtime.playable_collision.get_rid())])
		for _frame in 30:
			await physics_frame
		var terrain_y: float = world.terrain_provider.get_height(world.player.global_position)
		print("BIOME_SPAWN_SAMPLE: %s player=%s terrain_y=%.3f grounded=%s" % [level_id, world.player.global_position, terrain_y, world.player.is_grounded_for_gameplay()])
		assert(world.player.global_position.y >= terrain_y - 0.15, "Player spawned below terrain in %s" % level_id)
		assert(world.player.is_grounded_for_gameplay(), "Player did not settle on terrain in %s" % level_id)
		root.remove_child(world)
		world.free()
		await process_frame
	print("BIOME_SPAWN_OK: levels=%d" % WorldLevelCatalog.ORDER.size())
	packed = null
	await process_frame
	quit()
