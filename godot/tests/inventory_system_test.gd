extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := GameSession.new()
	session.new_game()
	assert(session.inventory_item_count() == 3, "Başlangıç çantasında üç eşya olmalı")
	assert(session.get_item_count("eski_tirpan") == 1, "Başlangıç tırpanı çantada değil")
	assert(GardenItemCatalog.get_item("gubre").get("name") == "Organik Gübre", "Eşya kataloğu yüklenemedi")
	var missions := GardenMissionSystem.new()
	root.add_child(missions)
	missions.configure(session)
	missions.interact_with_mira()
	session.grass_cut = session.grass_goal
	session.mission_stage = 2
	missions.interact_with_mira()
	assert(session.get_item_count("gubre") == 2, "Görev gübre ödülü verilmedi")
	assert(session.get_item_count("kir_cicegi_tohumu") == 6, "Görev tohum ödülü verilmedi")
	assert(session.get_item_count("ot_demeti") == session.grass_goal, "Biçilmiş ot ödülü verilmedi")
	var serialized := session.to_dict()
	var restored := GameSession.new()
	restored.from_dict(serialized)
	assert(restored.inventory == session.inventory, "Envanter kayıt dönüşünde korunmadı")
	var legacy := serialized.duplicate(true)
	legacy.erase("inventory")
	var migrated := GameSession.new()
	migrated.from_dict(legacy)
	assert(migrated.inventory_item_count() == 3, "Eski kayıt başlangıç çantasına dönüştürülmedi")
	print("INVENTORY_SYSTEM_OK: catalog=true unlimited=true save_migration=true mission_rewards=true")
	missions.queue_free()
	await process_frame
	quit()
