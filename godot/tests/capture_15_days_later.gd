extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var world := (load("res://scenes/rebuild/garden_world.tscn") as PackedScene).instantiate() as RebuiltGardenWorld
	world.configure_level(&"home_garden")
	root.add_child(world)

	var session := GameSession.new()
	session.new_game()
	session.world_day = 16 # 15 gün sonra (16. Gün)
	session.world_hour = 14.5 # Öğleden sonra güneşi
	session.money = 380
	session.mission_stage = 2
	session.grass_cut = 8
	session.grass_goal = 12
	world.setup(session)

	# 15 gün boyunca farklı zamanlarda yapılan biçme ve büyüme simülasyonu:
	if world.grass_field != null:
		# 13 gün önce biçilen alan (13 gün büyümüş, ~0.45 boy)
		world.grass_field.cut_at(Vector3(4.0, 0.0, -16.0), 2.2, false)
		world.grass_field.advance_growth(190.0)

		# 6 gün önce biçilen alan (6 gün büyümüş, ~0.22 boy)
		world.grass_field.cut_at(Vector3(-4.0, 0.0, -20.0), 2.0, false)
		world.grass_field.advance_growth(120.0)

		# Dün biçilen alan (Bekleme süresinde, 0.08 kısa dip sapı)
		world.grass_field.cut_at(Vector3(0.0, 0.0, -22.0), 2.4, false)
		world.grass_field.advance_growth(24.0)

	world.hud.refresh()

	for _frame in range(25):
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	image.save_png("res://tests/world_preview_day16.png")
	root.remove_child(world)
	world.free()
	quit()
