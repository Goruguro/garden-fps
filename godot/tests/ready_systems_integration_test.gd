extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	assert(packed != null, "Bahçe dünyası yüklenemedi")
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	await physics_frame
	await process_frame

	var minimap := world.hud.minimap
	assert(minimap != null, "DynamicMinimap HUD'a bağlanmadı")
	assert(minimap.get_script().resource_path == "res://addons/dynamic_minimap/minimap.gd", "Hazır DynamicMinimap betiği kullanılmıyor")
	assert(minimap.get("player_node") == world.player, "Minimap oyuncuyu takip etmiyor")
	var minimap_targets: Array = minimap.get("targets")
	assert(minimap_targets.size() >= 5, "Minimap oyuncu, NPC, görev ve companion hedeflerini kaydetmedi")

	var field := world.grass_field as DenseGrassField
	assert(field.grass_variant_usage.size() >= 1, "Çim şekli haritaya dağılmadı")
	var first_cell: Dictionary = field.cells[0]
	var lod_instances: Array = first_cell["instances"]
	assert((lod_instances[0] as GeometryInstance3D).visibility_range_end > (lod_instances[1] as GeometryInstance3D).visibility_range_begin, "Yakın ve orta LOD arasında boşluk var")
	assert((lod_instances[1] as GeometryInstance3D).visibility_range_end > (lod_instances[2] as GeometryInstance3D).visibility_range_begin, "Orta ve uzak LOD arasında boşluk var")
	assert((lod_instances[0] as GeometryInstance3D).visibility_range_end_margin >= 14.0, "Yakın LOD geçişi yeterince yumuşak değil")

	var runtime := world.terrain_runtime as GardenTerrainRuntime
	var snow_point := Vector3(runtime.snow_zone_center.x, 0.0, runtime.snow_zone_center.y)
	var snow_texture: Vector3 = runtime.terrain.data.get_texture_id(snow_point)
	assert(int(snow_texture.y) == 7 and snow_texture.z > 0.8, "Poly Haven kar katmanı Terrain3D alanına boyanmadı")

	var positions: PackedVector3Array = first_cell["positions"]
	var cut_target := positions[0]
	world.player.rotation.y = 0.0
	world.player.global_position = cut_target + Vector3(0.0, 0.02, 1.75)
	world.player.set_tool("trimmer")
	session.selected_tool = "trimmer"
	var before_cut := field.cut_clusters
	var removed := field.cut_at(cut_target)
	assert(removed > 0 and field.cut_clusters > before_cut, "Fiziksel alan çimi biçilmedi")
	assert(not field.has_uncut_at(cut_target, 0.12), "Tırpanın merkezindeki çim görünür kaldı")

	session.inventory.clear()
	world.addon_hub.sync_inventory(session.inventory)
	assert(world.addon_hub.inventory.get_item_count() == 0, "GLoot boş envanteri kabul etmedi")
	world.hud.show_journal(&"inventory", true)
	assert(world.hud.journal_dimmer.visible, "Boş envanter menüsü açılamadı")
	assert(world.hud.journal_content.get_child_count() > 0, "Boş envanter açıklaması gösterilmedi")
	world.hud.show_journal(&"quests", true)
	assert(world.hud.journal_title.text == "GÖREV DEFTERİ", "QuestSystem görev sayfası açılmadı")
	assert(world.addon_hub.quest_manager.get_available_quests().size() == 1, "Hazır QuestSystem başlangıç görevini sunmuyor")

	print("READY_SYSTEMS_OK: DynamicMinimap=true targets=%d GLoot_empty=true QuestSystem=true grass_variants=%d snow_texture=7 physical_cut=%d lod_crossfade=true" % [
		minimap_targets.size(), field.grass_variant_usage.size(), field.cut_clusters - before_cut
	])
	root.remove_child(world)
	world.free()
	packed = null
	await process_frame
	await process_frame
	quit()
