extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := GameSession.new()
	session.new_game()
	var tools := GardenToolSystem.new()
	root.add_child(tools)
	tools.configure(session)
	assert(tools.can_start_trimmer(), "Dolu ve sağlam tırpan çalışmadı")
	var maintenance_before := float(session.maintenance["trimmer"])
	var fuel_before := float(session.fuel["trimmer"])
	assert(tools.consume_trimmer_fuel(2.0), "Motor yakıt tüketirken beklenmedik biçimde durdu")
	assert(float(session.fuel["trimmer"]) < fuel_before, "Çalışan motor benzin tüketmedi")
	assert(is_equal_approx(float(session.maintenance["trimmer"]), maintenance_before), "Ota değmeden bakım azaldı")
	assert(not tools.is_valid_trimmer_sweep(GardenToolSystem.TRIMMER_MAX_SWEEP_SPEED + 0.5), "Aşırı hızlı süpürme kabul edildi")
	assert(tools.is_valid_trimmer_sweep(1.1), "Kontrollü süpürme reddedildi")
	assert(tools.register_grass_contact(18), "Ot teması kaydedilemedi")
	assert(float(session.maintenance["trimmer"]) < maintenance_before, "Ot teması bakımı azaltmadı")
	var saved := session.to_dict()
	assert(saved.has("fuel"), "Benzin kayıt verisine eklenmedi")

	var grass := CuttableGrass.new()
	root.add_child(grass)
	grass.setup(8080, Color("5f993f"))
	assert(grass.cut_grass(), "Ot kesme animasyonu başlamadı")
	var immediate_cut := grass.animated_blade_count
	assert(immediate_cut == 0, "Otlar animasyon başlamadan anında kesildi")
	# Unit-test the sweep sampler directly; runtime timing is owned by the Tween.
	grass._apply_cut_progress(0.45)
	var mid_cut := grass.animated_blade_count
	assert(mid_cut > 0 and mid_cut < CuttableGrass.CLUSTER_COUNT, "Ot kesimi kademeli ilerlemedi: %d" % mid_cut)
	grass._apply_cut_progress(1.0)
	assert(grass.animated_blade_count == CuttableGrass.CLUSTER_COUNT, "Ot kesme animasyonu tamamlanmadı")

	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	world.setup(session)
	await physics_frame
	var player := world.player
	player.set_trimmer_motor_active(true)
	var yaw_before := player.rotation.y
	var sweep_speeds: Array[float] = []
	player.trimmer_sweep_requested.connect(func(speed: float) -> void: sweep_speeds.append(speed))
	player.apply_tool_aim_delta(Vector2(-28.0, 3.0), 0.08)
	assert(is_equal_approx(player.rotation.y, yaw_before), "Alet nişanı kamerayı döndürdü")
	assert(player.tool_aim_yaw < 0.0, "Sağdan sola alet hareketi uygulanmadı")
	assert(not sweep_speeds.is_empty() and sweep_speeds[0] > 0.0, "Motor açıkken süpürme sinyali üretilmedi")

	print("TRIMMER_GAMEPLAY_OK: hold_motor=true fuel=true contact_wear=true speed_gate=true alt_aim=true animated_cut=true")
	root.remove_child(world)
	world.free()
	root.remove_child(grass)
	grass.free()
	root.remove_child(tools)
	tools.free()
	packed = null
	await process_frame
	quit()
