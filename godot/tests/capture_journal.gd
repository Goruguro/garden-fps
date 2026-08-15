extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	var world := (load("res://scenes/rebuild/garden_world.tscn") as PackedScene).instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	for _frame in range(16):
		await process_frame
	world.hud.show_journal(&"map", true)
	for _frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/journal_preview.png")
	root.remove_child(world)
	world.free()
	quit()
