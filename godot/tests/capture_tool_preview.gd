extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var world := (load("res://scenes/rebuild/garden_world.tscn") as PackedScene).instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	session.mission_stage = 4
	session.owned_tools.append("shears")
	session.selected_tool = "shears"
	session.register_owned_tool_item("shears")
	world.setup(session)
	for _frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/shears_preview.png")
	root.remove_child(world)
	world.free()
	quit()
