extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu := (load("res://scenes/rebuild/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	assert(menu.get("home_panel") != null, "Artistic home menu was not created")
	assert(menu.get("settings_panel") != null, "Settings menu was not created")
	assert(menu.get("continue_button") != null, "Continue action was not created")
	assert(menu.get("font_option") != null and menu.get("font_option").item_count == 4, "Font profiles were not created")
	assert(menu.get("fov_slider") != null and menu.get("fps_option") != null, "Expanded display settings were not created")
	assert(menu.get("ssao_check") != null and menu.get("sdfgi_check") != null, "Advanced graphics controls were not created")
	root.remove_child(menu)
	menu.free()
	var world := (load("res://scenes/rebuild/garden_world.tscn") as PackedScene).instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	await process_frame
	assert(world.hud.pause_panel != null, "Garden guide was not created")
	assert(world.hud.journal_panel != null, "Journal menu was not created")
	assert(world.environment is Sky3D and (world.environment as Sky3D).sky_material != null, "Sky3D atmosphere was not created")
	world._toggle_journal(&"map")
	assert(world.journal_open, "Map journal did not open")
	assert(world.hud.journal_dimmer.visible, "Map journal is not visible")
	assert(not world.player.controls_enabled, "Player controls remained enabled behind journal")
	world._toggle_journal(&"map")
	assert(not world.journal_open and world.player.controls_enabled, "Map journal did not close safely")
	assert(load("res://assets/third_party/kenney_ui/PNG/Green/Default/button_rectangle_depth_flat.png") is Texture2D, "Kenney UI textures were not imported")
	print("UI_VALIDATION_OK: menu, settings, HUD, pause guide, inventory and map journal")
	root.remove_child(world)
	world.free()
	quit()
