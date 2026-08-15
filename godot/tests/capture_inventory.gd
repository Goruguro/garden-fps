extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	var world := (load("res://scenes/rebuild/garden_world.tscn") as PackedScene).instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	session.mission_stage = 4
	session.money = 410
	session.grant_first_job_reward()
	session.owned_tools.append("shears")
	session.register_owned_tool_item("shears")
	session.add_item("otomasyon_parcasi", 4)
	world.setup(session)
	for _frame in range(14):
		await process_frame
	world.hud.show_journal(&"inventory", true)
	for _frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/inventory_preview.png")
	root.remove_child(world)
	world.free()
	quit()
