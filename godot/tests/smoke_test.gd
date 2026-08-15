extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	assert(packed != null, "Garden world scene could not be loaded")
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	await process_frame
	assert(world.grass_nodes.size() == 12, "Expected 12 cuttable grass clumps")
	assert(world.grass_field != null, "Dense grass field was not created")
	assert(world.grass_field.total_clusters >= 15000, "Dense grass field is too sparse")
	assert(world.grass_field.cells.size() >= 80, "Grass field cell culling is incomplete")
	assert(world.map_builder != null, "Procedural map builder was not created")
	var map_stats := world.map_builder.get_stats()
	assert(int(map_stats["paths"]) == 3, "Home garden path recipe was not generated")
	assert(int(map_stats["path_vertices"]) > 40, "Generated garden paths are too coarse")
	assert(not world.grass_field.has_uncut_at(Vector3(0.0, 0.0, 10.0), 0.8), "Grass exclusion did not clear the generated main path")
	assert(world.grass_nodes[0].blade_root is MultiMeshInstance3D, "Mission grass is not GPU-instanced")
	assert(world.player != null, "Player was not created")
	assert(world.mission_system != null, "Mission system was not created")
	assert(world.tool_system != null, "Tool system was not created")
	assert(world.world_clock != null, "World clock was not created")
	assert(world.weather != null, "Weather controller was not created")
	assert(world.hud != null, "HUD module was not created")
	assert(world.terrain_runtime != null and world.terrain_runtime.enabled, "Terrain3D runtime was not created")
	assert(world.terrain_provider != null, "Terrain height provider was not created")
	assert(world.terrain_runtime.terrain.data.get_region_count() > 0, "Terrain3D has no regions")
	assert(absf(world.terrain_provider.get_height(Vector3.ZERO)) < 0.1, "Garden center should remain level")
	assert(world.addon_hub != null, "Addon integration hub was not created")
	assert(world.addon_hub.inventory != null, "GLoot inventory was not created")
	assert(world.addon_hub.inventory.get_item_count() == 3, "GLoot starter inventory is incorrect")
	assert(world.addon_hub.quest_manager != null, "QuestSystem manager was not created")
	assert(world.kaykit_decorator.get_child_count() >= 20, "KayKit environment decoration was not built")
	assert(world.get_node_or_null("Cottage/KayKitCottageVisual") != null, "KayKit cottage was not built")
	assert(world.get_node_or_null("Workshop/KayKitWorkshopVisual") != null, "KayKit workshop was not built")
	assert(load("res://assets/third_party/polyhaven/leafy_grass/leafy_grass_diff_1k.jpg") is Texture2D, "Poly Haven grass texture was not imported")
	assert(load("res://assets/third_party/polyhaven/grass_path_2/grass_path_2_normal_1k.jpg") is Texture2D, "Poly Haven path normal texture was not imported")
	assert(load("res://assets/third_party/kenney_nature_full/mushroom_redGroup.glb") is PackedScene, "Full Kenney Nature Kit was not imported")
	assert(load("res://audio/sfx/grass_cut.ogg") is AudioStream, "Grass cutting sound was not imported")
	assert(ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics", "Jolt Physics is not enabled")
	assert(load("res://dialogue/garden.dialogue") is DialogueResource, "Dialogue resource was not imported")
	world.mission_system.interact_with_mira()
	assert(session.mission_stage == 1, "Mira did not start the mission")
	assert(world.addon_hub.quest_manager.get_active_quests().size() == 1, "QuestSystem did not start Mira's quest")
	for grass: CuttableGrass in world.grass_nodes:
		assert(grass.cut_grass(), "Grass clump could not be cut")
		world.mission_system.register_grass_cut()
	assert(session.mission_stage == 2, "Cutting goal did not complete the mission")
	world.mission_system.interact_with_mira()
	assert(session.money == 380, "Mission payout is incorrect")
	assert(world.addon_hub.quest_manager.completed.get_all_quests().size() == 1, "QuestSystem did not complete Mira's quest")
	var workshop_result := world.tool_system.use_workshop()
	assert(workshop_result == &"workshop_upgrade", "Workshop did not return the upgrade result")
	assert(session.owned_tools.has("shears"), "Shears upgrade was not purchased")
	assert(session.money == 130, "Upgrade price is incorrect")
	assert(session.save(), "Session could not be saved")
	var loaded := GameSession.new()
	assert(loaded.load_save(), "Session could not be loaded")
	assert(loaded.mission_stage == 4, "Saved progression was not restored")
	print("SMOKE_TEST_OK: Terrain3D, height provider, GLoot, QuestSystem, KayKit, mission, HUD and save flow")
	root.remove_child(world)
	world.free()
	world = null
	packed = null
	await process_frame
	await process_frame
	quit()
