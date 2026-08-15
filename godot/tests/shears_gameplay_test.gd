extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	var world := packed.instantiate() as RebuiltGardenWorld
	world.configure_level(&"shaping_estate")
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	session.mission_stage = 4
	session.owned_tools.append("shears")
	session.register_owned_tool_item("shears")
	session.select_level(&"shaping_estate")
	world.setup(session)
	await physics_frame
	assert(world.shapeable_plants.size() == 12, "Malikânede 12 şekillendirilebilir çalı kurulmadı")
	var plant: Node = world.shapeable_plants[0]
	var money_before := session.money
	session.selected_tool = "trimmer"
	assert(not world._try_shape_plant(plant), "Tırpan topiary çalısını şekillendirdi")
	assert(not bool(plant.get("shaped")), "Yanlış alet çalının durumunu değiştirdi")
	session.selected_tool = "shears"
	var condition_before := float(session.condition["shears"])
	var maintenance_before := float(session.maintenance["shears"])
	assert(world._try_shape_plant(plant), "Makas çalıyı şekillendiremedi")
	assert(bool(plant.get("shaped")), "Çalının görsel durumu değişmedi")
	assert(session.money == money_before + 18, "Şekillendirme ödemesi yanlış")
	assert(session.get_item_count("budama_demeti") == 1, "Budama demeti çantaya eklenmedi")
	assert(float(session.condition["shears"]) < condition_before, "Makas kondisyonu azalmadı")
	assert(float(session.maintenance["shears"]) < maintenance_before, "Makas bakımı azalmadı")
	assert(session.is_plant_shaped(&"shaping_estate", str(plant.get("plant_id"))), "Şekillendirme kayda işlenmedi")
	var restored := GameSession.new()
	restored.from_dict(session.to_dict())
	assert(restored.is_plant_shaped(&"shaping_estate", str(plant.get("plant_id"))), "Şekillendirme kayıt dönüşünde kayboldu")
	assert(not world._try_shape_plant(plant), "Aynı çalıdan iki kez ödül alındı")
	print("SHEARS_GAMEPLAY_OK: targets=12 wrong_tool_blocked=true reward=true wear=true save=true")
	root.remove_child(world)
	world.free()
	packed = null
	await process_frame
	quit()
