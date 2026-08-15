extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	await physics_frame
	var player := world.player
	var yaw_before := player.rotation.y
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120.0, -45.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for _event_index in range(3):
		player._input(motion)
	assert(absf(player.rotation.y - yaw_before) > 0.20, "Fare yatay kamera dönüşünü değiştirmedi")
	assert(player.look_pitch > 0.08, "Fare dikey kamera açısını değiştirmedi")
	var locked_yaw := player.rotation.y
	player.set_controls_enabled(false)
	player._input(motion)
	assert(is_equal_approx(player.rotation.y, locked_yaw), "Kapalı kontrollerde kamera döndü")
	player.set_controls_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var capture_requests := player.mouse_capture_request_count
	player._input(click)
	assert(player.mouse_capture_request_count == capture_requests + 1, "Pencere tıklaması fare yakalama yolunu çağırmadı")
	if DisplayServer.get_name() != "headless":
		assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Pencere tıklaması fareyi yeniden yakalamadı")
	var start_position := player.global_position
	Input.action_press("move_forward")
	for _frame in range(30):
		await physics_frame
	Input.action_release("move_forward")
	assert(Vector2(player.global_position.x - start_position.x, player.global_position.z - start_position.z).length() > 0.25, "WASD hareketi oyuncuyu ilerletmedi")
	assert(player.trimmer_head != null, "Stilize tırpan kesici kafası kurulmadı")
	player.play_tool_action()
	await create_timer(0.45).timeout
	assert(not player.tool_animating, "Tırpan animasyonu tamamlanmadı")
	player.set_tool("shears")
	await create_timer(0.45).timeout
	assert(player.shear_left != null and player.shear_right != null, "Stilize makas mekanizması kurulmadı")
	player.play_tool_action()
	await create_timer(0.45).timeout
	assert(not player.tool_animating, "Makas animasyonu tamamlanmadı")
	var camera_event := InputEventAction.new()
	camera_event.action = &"toggle_camera"
	camera_event.pressed = true
	player._unhandled_input(camera_event)
	assert(player.third_person and player.third_camera.current, "Üçüncü şahıs kamera değişimi çalışmadı")
	print("PLAYER_CONTROLS_OK: mouse_look=true recapture=true movement=true trimmer=true shears=true camera=true")
	root.remove_child(world)
	world.free()
	packed = null
	await process_frame
	quit()
