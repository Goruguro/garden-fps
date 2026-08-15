extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	var menu := (load("res://scenes/rebuild/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for _frame in range(25):
		await process_frame
	menu.get("home_panel").visible = false
	menu.get("settings_panel").visible = true
	var tabs := menu.get("settings_panel").find_children("*", "TabContainer", true, false)[0] as TabContainer
	for page in range(3):
		tabs.current_tab = page
		for _frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		var output := "res://tests/settings_preview.png" if page == 0 else "res://tests/settings_%s_preview.png" % ("interface" if page == 1 else "controls")
		root.get_texture().get_image().save_png(output)
	root.remove_child(menu)
	menu.free()
	quit()
