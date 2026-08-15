extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	var menu := (load("res://scenes/rebuild/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for _frame in range(50):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/menu_preview.png")
	root.remove_child(menu)
	menu.free()
	quit()
