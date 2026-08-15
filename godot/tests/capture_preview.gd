extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var requested_level := StringName(OS.get_environment("GARDEN_PREVIEW_LEVEL"))
	if not WorldLevelCatalog.is_valid(requested_level):
		requested_level = &"home_garden"
	var world := (load("res://scenes/rebuild/garden_world.tscn") as PackedScene).instantiate() as RebuiltGardenWorld
	world.configure_level(requested_level)
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	session.mission_stage = 4
	session.select_level(requested_level)
	world.setup(session)
	for _frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://tests/world_preview_%s.png" % requested_level)
	root.remove_child(world)
	world.free()
	quit()
