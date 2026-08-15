extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var terrain_runtime := GardenTerrainRuntime.new()
	root.add_child(terrain_runtime)
	terrain_runtime.build(481516, &"gentle", 0.35)
	_paint_material_strips(terrain_runtime.terrain)

	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color("8fb5c4")
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color("d8ecdf")
	environment_resource.ambient_light_energy = 0.62
	environment.environment = environment_resource
	root.add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
	sun.light_color = Color("ffe2ae")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	root.add_child(sun)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 13.5, 18.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, -1.0))
	camera.fov = 56.0
	root.add_child(camera)
	camera.current = true

	for _frame in range(16):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/stylized_terrain_preview.png")
	quit()


func _paint_material_strips(terrain: Terrain3D) -> void:
	for texture_id in range(7):
		var center_x := -15.0 + float(texture_id) * 5.0
		for z in range(-8, 9):
			for x_offset in range(-2, 3):
				var position := Vector3(center_x + float(x_offset), 0.0, float(z))
				terrain.data.set_control_auto(position, false)
				if texture_id == 0:
					terrain.data.set_control_base_id(position, 0)
					terrain.data.set_control_overlay_id(position, 1)
					terrain.data.set_control_blend(position, 0)
				else:
					terrain.data.set_control_overlay_id(position, texture_id)
					terrain.data.set_control_blend(position, 255)
	terrain.data.update_maps(Terrain3DRegion.TYPE_CONTROL, true, true)
