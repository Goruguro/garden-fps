extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var world := (load("res://scenes/rebuild/garden_world.tscn") as PackedScene).instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	world.player.process_mode = Node.PROCESS_MODE_DISABLED
	world.hud.visible = false
	world.grass_field.visible = false
	world.outer_biome_ring.visible = false
	for child in world.get_children():
		if child is Node3D and child != world.terrain_runtime and child != world.ground_detail_scatter:
			(child as Node3D).visible = false
	var detail_instance := world.ground_detail_scatter.get_child(0) as MultiMeshInstance3D
	var focus := Vector3.ZERO
	for index in range(detail_instance.multimesh.instance_count):
		var candidate := detail_instance.multimesh.get_instance_transform(index).origin
		if candidate.x > 5.0 and candidate.z > 2.0:
			focus = candidate
			break
	var camera := Camera3D.new()
	camera.position = focus + Vector3(0.9, 0.52, 1.3)
	camera.look_at_from_position(camera.position, focus + Vector3.UP * 0.02)
	camera.fov = 52.0
	root.add_child(camera)
	camera.current = true
	for _frame in range(16):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/ground_detail_preview.png")
	quit()
