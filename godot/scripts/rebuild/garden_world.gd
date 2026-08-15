class_name RebuiltGardenWorld
extends Node3D

signal exit_to_menu
signal level_change_requested(level_id: StringName)

const GRASS_SCRIPT := preload("res://scripts/rebuild/cuttable_grass.gd")
const SHAPEABLE_PLANT_SCRIPT := preload("res://scripts/rebuild/shapeable_plant.gd")
const FONT := preload("res://fonts/Bahnschrift.ttf")
const DIALOGUE := preload("res://dialogue/garden.dialogue")
const MIRA_MODEL := preload("res://assets/third_party/kaykit_characters/Mira.glb")
const TERRAIN_RUNTIME_SCRIPT := preload("res://scripts/terrain/garden_terrain_runtime.gd")
const HEIGHT_PROVIDER_SCRIPT := preload("res://scripts/terrain/terrain_height_provider.gd")
const ADDON_HUB_SCRIPT := preload("res://scripts/integrations/garden_addon_hub.gd")
const KAYKIT_DECORATOR_SCRIPT := preload("res://scripts/world/kaykit_environment_decorator.gd")
const ARTISTIC_SKY_SCRIPT := preload("res://scripts/presentation/artistic_sky_controller.gd")
const DENSE_GRASS_SCRIPT := preload("res://scripts/vegetation/dense_grass_field.gd")
const LOD_FOLIAGE_SCRIPT := preload("res://scripts/vegetation/lod_foliage_scatter.gd")
const GROUND_DETAIL_SCRIPT := preload("res://scripts/vegetation/ground_detail_scatter.gd")
const OUTER_BIOME_SCRIPT := preload("res://scripts/vegetation/outer_biome_ring.gd")
const MAP_BUILDER_SCRIPT := preload("res://scripts/world/procedural_map_builder.gd")
const GRAPHICS_MANAGER_SCRIPT := preload("res://scripts/graphics/garden_graphics_manager.gd")
const DECAL_SYSTEM_SCRIPT := preload("res://scripts/graphics/garden_decal_system.gd")
const WATER_BODY_SCRIPT := preload("res://scripts/graphics/garden_water_body.gd")
const ATMOSPHERE_EFFECTS_SCRIPT := preload("res://scripts/graphics/garden_atmosphere_effects.gd")
const SEASON_SYSTEM_SCRIPT := preload("res://scripts/systems/garden_season_system.gd")
const CROP_SYSTEM_SCRIPT := preload("res://scripts/systems/garden_crop_system.gd")
const IRRIGATION_SYSTEM_SCRIPT := preload("res://scripts/systems/garden_irrigation_system.gd")
const STATE_COORDINATOR_SCRIPT := preload("res://scripts/systems/garden_state_coordinator.gd")
const NPC_SCHEDULE_SCRIPT := preload("res://scripts/systems/garden_npc_schedule.gd")
const COLLISION_FACTORY := preload("res://scripts/physics/garden_collision_factory.gd")
const COTTAGE_MODEL := preload("res://assets/third_party/kaykit_medieval/buildings/green/building_home_A_green.gltf")
const WORKSHOP_MODEL := preload("res://assets/third_party/kaykit_medieval/buildings/green/building_blacksmith_green.gltf")
const PATH_DIFFUSE := preload("res://assets/third_party/polyhaven/grass_path_2/grass_path_2_diff_1k.jpg")
const PATH_NORMAL := preload("res://assets/third_party/polyhaven/grass_path_2/grass_path_2_normal_1k.jpg")
const PATH_ARM := preload("res://assets/third_party/polyhaven/grass_path_2/grass_path_2_arm_1k.jpg")
const NATURE_MODELS := {
	"tree_detailed": preload("res://assets/kenney_nature/tree_detailed.glb"),
	"tree_default": preload("res://assets/kenney_nature/tree_default.glb"),
	"tree_cone": preload("res://assets/kenney_nature/tree_cone.glb"),
	"bush_detailed": preload("res://assets/kenney_nature/plant_bushDetailed.glb"),
	"bush_large": preload("res://assets/kenney_nature/plant_bushLarge.glb"),
	"rock_large_a": preload("res://assets/kenney_nature/rock_largeA.glb"),
	"rock_large_c": preload("res://assets/kenney_nature/rock_largeC.glb"),
	"rock_small_a": preload("res://assets/kenney_nature/rock_smallA.glb"),
	"rock_small_c": preload("res://assets/kenney_nature/rock_smallC.glb"),
	"flower_red": preload("res://assets/kenney_nature/flower_redA.glb"),
	"flower_yellow": preload("res://assets/kenney_nature/flower_yellowB.glb"),
	"flower_purple": preload("res://assets/kenney_nature/flower_purpleC.glb"),
	"log_stack": preload("res://assets/kenney_nature/log_stack.glb"),
	"mushroom_red": preload("res://assets/third_party/kenney_nature_full/mushroom_redGroup.glb"),
	"mushroom_tan": preload("res://assets/third_party/kenney_nature_full/mushroom_tanGroup.glb"),
	"leaf_cluster": preload("res://assets/third_party/kenney_nature_full/grass_leafsLarge.glb"),
	"wild_plant": preload("res://assets/third_party/kenney_nature_full/plant_flatTall.glb"),
	"small_bush": preload("res://assets/third_party/kenney_nature_full/plant_bushSmall.glb"),
	"old_stump": preload("res://assets/third_party/kenney_nature_full/stump_roundDetailed.glb"),
	"fallen_log": preload("res://assets/third_party/kenney_nature_full/log_large.glb"),
	"lily_large": preload("res://assets/third_party/kenney_nature_full/lily_large.glb")
}

var session: GameSession
var grass_nodes: Array[CuttableGrass] = []
var shapeable_plants: Array[Node] = []
var grass_field: DenseGrassField
var foliage_scatter: LodFoliageScatter
var ground_detail_scatter: GroundDetailScatter
var outer_biome_ring: OuterBiomeRing
var map_builder: ProceduralMapBuilder
var sun: DirectionalLight3D
var environment: WorldEnvironment
var ground_material: ShaderMaterial
var mission_system: GardenMissionSystem
var tool_system: GardenToolSystem
var world_clock: GardenWorldClock
var weather: GardenWeatherController
var hud: GardenHUD
var terrain_runtime: Node3D
var terrain_provider: Node
var addon_hub: Node
var kaykit_decorator: Node3D
var artistic_sky: ArtisticSkyController
var graphics_manager: GardenGraphicsManager
var decal_system: GardenDecalSystem
var atmosphere_effects: GardenAtmosphereEffects
var season_system: GardenSeasonSystem
var crop_system: GardenCropSystem
var irrigation_system: GardenIrrigationSystem
var state_coordinator: GardenStateCoordinator
var water_bodies: Array[GardenWaterBody] = []
var npc_schedules: Array[GardenNPCSchedule] = []
var paused := false
var journal_open := false
var journal_page := &""
var grass_rng := RandomNumberGenerator.new()
var level_id := &"home_garden"
var level_profile: Dictionary = {}
var level_recipe: Dictionary = {}
var generation_profile: MapGenerationProfile
var trimmer_sweep_cooldown := 0.0
var trimmer_feedback_cooldown := 0.0

@onready var player: RebuildPlayerController = $Player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = 100
	level_profile = WorldLevelCatalog.get_level(level_id)
	generation_profile = WorldLevelCatalog.get_generation_profile(level_id)
	level_recipe = ProceduralMapRecipes.get_recipe(level_id)
	grass_rng.seed = generation_profile.seed
	_build_environment()
	_build_terrain()
	_build_landscape()
	if level_id == &"home_garden":
		_build_house()
		_build_work_yard()
	else:
		_build_region_landmark()
	_build_vegetation()
	_build_lod_foliage()
	if level_id == &"home_garden":
		_build_kaykit_environment()
		_build_characters()
		_build_grass_job()
	_build_services()
	_connect_player()
	_place_player_at_level_spawn()


func configure_level(active_level_id: StringName) -> void:
	level_id = active_level_id if WorldLevelCatalog.is_valid(active_level_id) else &"home_garden"


func _unhandled_input(event: InputEvent) -> void:
	if paused and event.is_action_pressed("pause_menu"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func setup(active_session: GameSession) -> void:
	session = active_session
	mission_system.configure(session)
	tool_system.configure(session)
	world_clock.configure(session)
	season_system.configure(session)
	if level_id == &"home_garden":
		crop_system.build(session, season_system, terrain_provider)
		irrigation_system.build(session, terrain_provider)
	hud.configure(session, mission_system, player, addon_hub)
	player.set_tool(session.selected_tool)
	_restore_progress()
	_sync_addons()
	hud.refresh()


func _process(delta: float) -> void:
	if session == null or paused:
		return
	world_clock.advance(delta)
	trimmer_sweep_cooldown = maxf(0.0, trimmer_sweep_cooldown - delta)
	trimmer_feedback_cooldown = maxf(0.0, trimmer_feedback_cooldown - delta)
	if player.trimmer_motor_active and not tool_system.consume_trimmer_fuel(delta):
		player.set_trimmer_motor_active(false)
		_show_message("Tırpanın benzini bitti. Atölyede depoyu doldur.", 3.0)
	weather.advance(delta)
	season_system.advance(session.world_hour)
	weather.rain_frequency_multiplier = season_system.rain_multiplier()
	if crop_system != null and level_id == &"home_garden":
		irrigation_system.update_schedule(session.world_hour, weather.raining)
		crop_system.advance(session.world_hour, irrigation_system.active or weather.raining)
	graphics_manager.apply_time(session.world_hour, weather.raining, season_system.tint())
	state_coordinator.send_domain_event(&"player", &"moving" if player.horizontal_speed_2d() > 0.2 else (&"crouched" if player.crouched else &"idle"))
	var animal_position := _nearest_animal_position()
	for schedule in npc_schedules:
		schedule.advance(delta, session.world_hour, weather.raining, animal_position)
	if grass_field != null:
		grass_field.set_interactor_position(player.global_position)
	_sync_addons()
	_update_prompt()
	hud.tick(delta)
	hud.refresh()


func _physics_process(_delta: float) -> void:
	if terrain_provider == null or player == null or player.velocity.y > 0.0:
		return
	var terrain_height: float = terrain_provider.get_height(player.global_position)
	if not player.is_on_floor() and player.global_position.y <= terrain_height + 0.08:
		player.recover_to_terrain(terrain_height)


func _connect_player() -> void:
	player.interact_requested.connect(_on_interact)
	player.tool_requested.connect(_on_use_tool)
	player.tool_switched.connect(_on_switch_tool)
	player.trimmer_motor_requested.connect(_on_trimmer_motor_requested)
	player.trimmer_sweep_requested.connect(_on_trimmer_sweep_requested)
	player.pause_requested.connect(_toggle_pause)
	player.journal_requested.connect(_toggle_journal)
	player.camera_changed.connect(func(is_third_person: bool) -> void:
		_show_message("Omuz kamerası" if is_third_person else "Birinci şahıs kamera"))
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager != null:
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)


func _toggle_journal(page: StringName) -> void:
	if paused or session == null:
		return
	journal_open = not journal_open if journal_page == page else true
	journal_page = page if journal_open else &""
	hud.show_journal(page, journal_open)
	player.set_controls_enabled(not journal_open)
	state_coordinator.send_domain_event(&"menu", &"journal" if journal_open else &"gameplay")


func _on_level_requested(requested_level_id: StringName) -> void:
	if session == null or not session.select_level(requested_level_id):
		_show_message("Bu bölge henüz hikâye görevleriyle açılmadı.")
		return
	session.save()
	level_change_requested.emit(requested_level_id)


func _on_interact() -> void:
	if session == null or paused:
		return
	var target := _get_interaction_target(player.get_aimed_object())
	var interaction_id := target.interaction_id if target != null else &""
	match interaction_id:
		"mira":
			_interact_mira()
		"workshop":
			_interact_workshop()
		"crop_beds":
			_interact_crop_beds()
		"yuzu":
			_show_dialogue(&"yuzu_chat")
		"worker_lale", "worker_arda":
			_show_worker_status(interaction_id)
		_:
			_show_message("Etkileşmek için bir karaktere veya istasyona nişan al.")


func _on_use_tool() -> void:
	if session == null or paused:
		return
	if session.selected_tool == "trimmer":
		_show_message("Motor için sol tıkı basılı tut; Alt + fare ile sağdan sola süpür.", 2.6)
		return
	player.play_tool_action()
	var target := player.get_aimed_object()
	if target != null and target.get_script() == SHAPEABLE_PLANT_SCRIPT:
		_try_shape_plant(target as Node)
		return
	if target is CuttableGrass:
		if not mission_system.can_cut_grass():
			_show_message("Önce Mira'dan işi al.")
			return
		if session.selected_tool != "trimmer":
			_show_message("Uzun otlar için tırpana geçmelisin.")
			return
		if not tool_system.try_use("trimmer"):
			return
		if target.cut_grass():
			grass_field.spawn_cut_effect(target.global_position + Vector3.UP * 0.35, 24)
			decal_system.spawn_tool_mark(target.global_position)
			mission_system.register_grass_cut()
		return
	if session.selected_tool != "trimmer":
		_show_message("Bu çimleri kesmek için tırpana geçmelisin.")
		return
	var cut_point := _project_to_terrain(player.get_trimmer_cut_point(), 0.02)
	if grass_field != null and grass_field.has_uncut_at(cut_point):
		var space_state := get_world_3d().direct_space_state
		if not grass_field.is_physics_reachable(cut_point, player.camera.global_position, space_state):
			_show_message("Çimlere biraz daha yaklaş.")
			return
		if not tool_system.try_use("trimmer"):
			return
		var removed := grass_field.cut_at(cut_point)
		if removed > 0:
			decal_system.spawn_tool_mark(cut_point)
			_show_message("%d çim kümesi biçildi." % removed, 1.2)
			return
	_show_message("Tırpanı uzun çimlere doğru kullan.")


func _on_trimmer_motor_requested(active: bool) -> void:
	if not active:
		player.set_trimmer_motor_active(false)
		return
	if session == null or paused or session.selected_tool != "trimmer":
		player.set_trimmer_motor_active(false)
		return
	player.set_trimmer_motor_active(tool_system.can_start_trimmer())
	if player.trimmer_motor_active:
		_show_message("Motor çalışıyor. Alt basılıyken sağdan sola kontrollü süpür.", 1.8)


func _on_trimmer_sweep_requested(speed: float) -> void:
	if session == null or paused or not player.trimmer_motor_active or trimmer_sweep_cooldown > 0.0:
		return
	trimmer_sweep_cooldown = 0.075
	if not tool_system.is_valid_trimmer_sweep(speed):
		if trimmer_feedback_cooldown <= 0.0:
			var feedback := "Çok hızlı! Otlar kesilmedi." if speed > GardenToolSystem.TRIMMER_MAX_SWEEP_SPEED else "Biraz daha kararlı süpür."
			_show_message(feedback, 1.1)
			trimmer_feedback_cooldown = 0.8
		return
	if not mission_system.can_cut_grass():
		if trimmer_feedback_cooldown <= 0.0:
			_show_message("Önce Mira'dan işi al.", 1.5)
			trimmer_feedback_cooldown = 1.0
		return
	var cut_point := _project_to_terrain(player.get_trimmer_cut_point(), 0.02)
	var contact_count := 0
	var job_patches_cut := 0
	for grass: CuttableGrass in grass_nodes:
		var grass_flat := Vector2(grass.global_position.x, grass.global_position.z)
		var cut_flat := Vector2(cut_point.x, cut_point.z)
		if grass.cut or grass_flat.distance_squared_to(cut_flat) > 1.65 * 1.65:
			continue
		if grass.cut_grass():
			contact_count += 24
			job_patches_cut += 1
			if grass_field != null:
				grass_field.spawn_cut_effect(grass.global_position + Vector3.UP * 0.35, 24)
			decal_system.spawn_tool_mark(grass.global_position)
			mission_system.register_grass_cut()
	if grass_field != null and grass_field.has_uncut_at(cut_point, 1.45):
		var space_state := get_world_3d().direct_space_state
		if grass_field.is_physics_reachable(cut_point, player.camera.global_position, space_state):
			var removed := grass_field.cut_at(cut_point, 1.45, true)
			contact_count += removed
			if removed > 0:
				decal_system.spawn_tool_mark(cut_point)
	if contact_count <= 0:
		return
	tool_system.register_grass_contact(contact_count)
	if job_patches_cut > 0:
		_show_message("Kontrollü biçim: %d görev kümesi kesildi." % job_patches_cut, 1.2)


func _try_shape_plant(plant: Node) -> bool:
	if plant == null or bool(plant.get("shaped")):
		_show_message("Bu çalı zaten biçimlendirildi.")
		return false
	if session.selected_tool != "shears":
		_show_message("Bu çalı için büyük bahçe makasına geçmelisin.")
		return false
	if not tool_system.try_use("shears"):
		return false
	if not bool(plant.call("shape_plant")):
		return false
	session.money += 18
	session.add_item("budama_demeti")
	session.mark_plant_shaped(level_id, str(plant.get("plant_id")))
	session.save()
	hud.refresh()
	_show_message("Çalı biçimlendirildi: +18 ₺ • +1 budama demeti", 2.4)
	return true


func _on_switch_tool() -> void:
	var selected := tool_system.switch_to_next()
	if not selected.is_empty():
		player.set_tool(selected)


func _interact_mira() -> void:
	_show_dialogue(mission_system.interact_with_mira())


func _interact_workshop() -> void:
	var title := tool_system.use_workshop()
	if title == &"workshop_upgrade":
		player.set_tool("shears")
	_show_dialogue(title)


func _interact_crop_beds() -> void:
	if crop_system.apply_fertilizer():
		_show_message("Ekinler gübrelendi. Büyüme hızı geçici olarak arttı.", 2.4)
	else:
		irrigation_system.set_active(not irrigation_system.active)
		_show_message("Otomatik sulama %s." % ("açıldı" if irrigation_system.active else "kapatıldı"), 2.0)


func _show_worker_status(worker_id: StringName) -> void:
	for schedule in npc_schedules:
		if schedule.personality == worker_id:
			_show_message("%s şu anda %s. LimboAI günlük programı etkin." % [String(worker_id).trim_prefix("worker_").capitalize(), schedule.activity_name()], 2.6)
			return


func _get_interaction_target(collider: Object) -> InteractionTarget:
	return InteractionTarget.find_from(collider)


func _update_prompt() -> void:
	var target := player.get_aimed_object()
	var interaction_target := _get_interaction_target(target)
	if interaction_target != null:
		hud.set_prompt("[E] %s" % interaction_target.prompt)
	elif target is CuttableGrass and not target.cut:
		hud.set_prompt("[SOL TIK BASILI] MOTOR  •  [ALT + FARE SOLA] BİÇ")
	elif target != null and target.get_script() == SHAPEABLE_PLANT_SCRIPT:
		hud.set_prompt("BİÇİMLENDİRİLDİ" if bool(target.get("shaped")) else "[SOL TIK] Büyük makasla biçimlendir")
	elif grass_field != null and grass_field.has_uncut_at(_project_to_terrain(player.get_trimmer_cut_point(), 0.02), 1.35):
		hud.set_prompt("[SOL TIK BASILI] MOTOR  •  [ALT + FARE SOLA] BİÇ")
	else:
		hud.set_prompt("")


func _restore_progress() -> void:
	for index in range(grass_nodes.size()):
		grass_nodes[index].restore_cut_state(index < session.grass_cut)
	for plant in shapeable_plants:
		if session.is_plant_shaped(level_id, str(plant.get("plant_id"))):
			plant.call("restore_shaped")


func _toggle_pause() -> void:
	if journal_open:
		journal_open = false
		hud.show_journal(&"inventory", false)
		player.set_controls_enabled(true)
		return
	paused = not paused
	state_coordinator.send_domain_event(&"menu", &"paused" if paused else &"gameplay")
	hud.set_paused(paused)
	player.set_controls_enabled(not paused)
	get_tree().paused = paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud.process_mode = Node.PROCESS_MODE_ALWAYS


func _show_message(text: String, duration := 2.5) -> void:
	hud.show_message(text, duration)


func _show_dialogue(title: StringName) -> void:
	var dialogue_manager := _get_dialogue_manager()
	if title != &"" and dialogue_manager != null:
		dialogue_manager.show_dialogue_balloon(DIALOGUE, title)


func _get_dialogue_manager() -> Node:
	return get_node_or_null("/root/DialogueManager")


func _on_dialogue_started(_resource: DialogueResource) -> void:
	player.set_controls_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if not paused:
		player.set_controls_enabled(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_services() -> void:
	mission_system = GardenMissionSystem.new()
	mission_system.name = "MissionSystem"
	add_child(mission_system)
	tool_system = GardenToolSystem.new()
	tool_system.name = "ToolSystem"
	add_child(tool_system)
	world_clock = GardenWorldClock.new()
	world_clock.name = "WorldClock"
	add_child(world_clock)
	weather = GardenWeatherController.new()
	weather.name = "Weather"
	add_child(weather)
	weather.configure(environment, player)
	season_system = SEASON_SYSTEM_SCRIPT.new()
	season_system.name = "SeasonSystem"
	add_child(season_system)
	crop_system = CROP_SYSTEM_SCRIPT.new()
	crop_system.name = "CropSystem"
	add_child(crop_system)
	irrigation_system = IRRIGATION_SYSTEM_SCRIPT.new()
	irrigation_system.name = "IrrigationSystem"
	add_child(irrigation_system)
	state_coordinator = STATE_COORDINATOR_SCRIPT.new()
	state_coordinator.name = "StateCoordinator"
	add_child(state_coordinator)
	state_coordinator.build()
	decal_system = DECAL_SYSTEM_SCRIPT.new()
	decal_system.name = "DecalSystem"
	add_child(decal_system)
	decal_system.build_static_decals()
	atmosphere_effects = ATMOSPHERE_EFFECTS_SCRIPT.new()
	atmosphere_effects.name = "AtmosphereEffects"
	add_child(atmosphere_effects)
	atmosphere_effects.build(player)
	hud = GardenHUD.new()
	hud.name = "GardenHUD"
	add_child(hud)
	addon_hub = ADDON_HUB_SCRIPT.new()
	addon_hub.name = "AddonHub"
	add_child(addon_hub)
	addon_hub.configure()
	mission_system.changed.connect(_sync_addons)
	mission_system.changed.connect(hud.refresh)
	mission_system.message_requested.connect(_show_message)
	tool_system.changed.connect(hud.refresh)
	tool_system.message_requested.connect(_show_message)
	world_clock.time_changed.connect(_apply_daylight)
	weather.rain_changed.connect(_apply_wetness)
	hud.resume_requested.connect(_toggle_pause)
	hud.exit_requested.connect(func() -> void:
		if paused:
			_toggle_pause()
		exit_to_menu.emit())
	hud.level_requested.connect(_on_level_requested)


func _sync_addons() -> void:
	if addon_hub != null and session != null:
		addon_hub.sync_mission_stage(session.mission_stage, session.grass_cut, session.grass_goal)
		addon_hub.sync_inventory(session.inventory)


func _build_terrain() -> void:
	terrain_runtime = TERRAIN_RUNTIME_SCRIPT.new()
	terrain_runtime.name = "GardenTerrainRuntime"
	add_child(terrain_runtime)
	if terrain_runtime.build(
		int(level_recipe.get("seed", level_profile["seed"])),
		StringName(level_recipe.get("terrain_style", &"gentle")),
		float(level_recipe.get("terrain_amplitude", 0.0)),
		generation_profile
	):
		terrain_provider = terrain_runtime.height_provider
	else:
		terrain_provider = HEIGHT_PROVIDER_SCRIPT.new()
		terrain_provider.name = "FlatTerrainHeightProvider"
		add_child(terrain_provider)
		terrain_provider.configure(null, 0.0)


func _build_kaykit_environment() -> void:
	kaykit_decorator = KAYKIT_DECORATOR_SCRIPT.new()
	kaykit_decorator.name = "KayKitEnvironment"
	add_child(kaykit_decorator)
	kaykit_decorator.build(terrain_provider)


func _build_environment() -> void:
	environment = Sky3D.new()
	environment.name = "Sky3D"
	add_child(environment)
	var sky_controller := environment as Sky3D
	sky_controller.game_time_enabled = false
	sky_controller.clouds_enabled = true
	# Environment fog handles the ground layer; disabling Sky3D's screen fog avoids a washed-out double pass.
	sky_controller.fog_enabled = false
	sky_controller.wind_speed = 2.2
	sky_controller.update_interval = 0.08
	sky_controller.camera_exposure = 1.08
	sky_controller.tonemap_exposure = 1.04
	sky_controller.skydome_energy = 1.18
	sky_controller.cloud_intensity = 0.82
	sky_controller.sun_energy = 1.25
	if sky_controller.sky != null:
		sky_controller.sky.exposure = 1.12
		sky_controller.sky.atm_day_tint = Color("79bce8")
		sky_controller.sky.atm_horizon_light_tint = Color("ffd09c")
		sky_controller.sky.atm_thickness = 0.56
		sky_controller.sky.atm_turbidity = 0.006
		sky_controller.sky.sun_disk_size = 0.026
		sky_controller.sky.sun_disk_intensity = 38.0
		sky_controller.sky.cirrus_coverage = 0.28
		sky_controller.sky.cirrus_intensity = 1.35
		sky_controller.sky.cumulus_coverage = 0.40
		sky_controller.sky.cumulus_intensity = 0.88
		sky_controller.sky.cumulus_thickness = 0.052
	var env := environment.environment
	env.background_mode = Environment.BG_SKY
	env.background_color = Color("5793bf")
	env.background_energy_multiplier = 0.42
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4d2bc")
	env.ambient_light_energy = 0.86
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.94
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_bloom = 0.08
	env.ssao_enabled = true
	env.ssao_radius = 2.2
	env.ssao_intensity = 2.0
	env.ssil_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color("d9e7d7")
	env.fog_density = 0.00135
	env.fog_sky_affect = 0.18
	env.volumetric_fog_enabled = false
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.98
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 1.08
	sun = sky_controller.sun
	if sun == null:
		sun = DirectionalLight3D.new()
		add_child(sun)
	sun.rotation_degrees = Vector3(-48, -38, 0)
	sun.light_color = Color("ffe3b0")
	sun.light_energy = 2.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 95.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	graphics_manager = GRAPHICS_MANAGER_SCRIPT.new()
	graphics_manager.name = "GardenGraphicsManager"
	add_child(graphics_manager)
	graphics_manager.configure(environment)


func _build_landscape() -> void:
	ground_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode diffuse_burley; uniform vec3 grass_a:source_color=vec3(0.16,0.31,0.15); uniform vec3 grass_b:source_color=vec3(0.25,0.42,0.20); uniform float wetness:hint_range(0.0,1.0)=0.0; float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);} void fragment(){float n=h(floor(VERTEX.xz*1.7)); vec3 dry=mix(grass_a,grass_b,n*0.55); ALBEDO=mix(dry,dry*0.48,wetness); ROUGHNESS=mix(0.96,0.34,wetness); SPECULAR=mix(0.25,0.65,wetness);}"
	ground_material.shader = shader
	if terrain_runtime == null or not terrain_runtime.enabled:
		_add_box("GroundFallback", Vector3(0, -0.45, 0), Vector3(110, 0.9, 100), ground_material, true)
	else:
		# A low emergency floor catches the player if terrain collision is still streaming.
		_add_box("TerrainSafetyFloor", Vector3(0, -2.2, 0), Vector3(110, 0.4, 100), ground_material, true)
	var path_material := _create_path_material()
	map_builder = MAP_BUILDER_SCRIPT.new() as ProceduralMapBuilder
	map_builder.name = "ProceduralMapBuilder"
	add_child(map_builder)
	map_builder.build(level_recipe, terrain_provider, path_material)
	_build_ground_details()
	if level_id == &"home_garden":
		_build_pond(Vector3(15, 0.0, -14))
		_build_fence()
	# Terrain3D supplies the horizon; the old stretched-sphere hills hid it.
	_build_decorative_grass()


func _build_house() -> void:
	var root := Node3D.new()
	root.name = "Cottage"
	root.position = _project_to_terrain(Vector3(18, 0, 18))
	add_child(root)
	var cottage := COTTAGE_MODEL.instantiate() as Node3D
	cottage.name = "KayKitCottageVisual"
	cottage.scale = Vector3.ONE * 12.0
	cottage.rotation.y = PI
	root.add_child(cottage)
	var reflection_probe := ReflectionProbe.new()
	reflection_probe.name = "CottageReflectionProbe"
	reflection_probe.position = Vector3(0.0, 3.4, 0.0)
	reflection_probe.size = Vector3(13.0, 8.0, 13.0)
	reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	root.add_child(reflection_probe)
	var lightmap := LightmapGI.new()
	lightmap.name = "CottageLightmapGI"
	lightmap.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	root.add_child(lightmap)
	_add_box_occluder(root, Vector3(0.0, 4.2, 0.0), Vector3(9.4, 8.4, 10.4))
	_add_invisible_collision(root, "CottageCollision", Vector3(0, 4.5, 0), Vector3(9.2, 9.0, 10.2))
	_spawn_nature("bush_detailed", root, Vector3(-5.7, 0, 3.8), 1.1, 0.2)
	_spawn_nature("bush_large", root, Vector3(5.5, 0, 3.1), 1.0, -0.3)
	for offset in [-3.8, -2.5, 2.5, 3.8]:
		_spawn_nature("flower_yellow", root, Vector3(offset, 0, 5.6), 0.75, offset)


func _build_work_yard() -> void:
	var root := Node3D.new()
	root.name = "Workshop"
	root.position = _project_to_terrain(Vector3(-12, 0, -10))
	add_child(root)
	var workshop := WORKSHOP_MODEL.instantiate() as Node3D
	workshop.name = "KayKitWorkshopVisual"
	workshop.scale = Vector3.ONE * 10.0
	workshop.rotation.y = PI
	root.add_child(workshop)
	_add_box_occluder(root, Vector3(0.0, 3.2, -0.4), Vector3(8.0, 6.4, 7.0))
	_add_invisible_collision(root, "WorkshopCollision", Vector3(0, 3.3, -0.4), Vector3(7.8, 6.6, 6.8))
	var area := InteractionTarget.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.4, 3.0, 2.5)
	area.configure(&"workshop", "Atölyeyi kullan", shape, Vector3(0, 1.5, 2.5))
	root.add_child(area)
	_add_label(root, "ATÖLYE", Vector3(0, 4.75, 2.5), Color("f0d69e"), 44)
	_spawn_nature("log_stack", root, Vector3(-5.0, 0.0, 0.1), 1.2, -0.18)


func _build_pond(center: Vector3) -> void:
	center = _project_to_terrain(center)
	var pond := WATER_BODY_SCRIPT.new() as GardenWaterBody
	pond.position = center + Vector3(0, 0.08, 0)
	add_child(pond)
	pond.build_pond(Vector2(11.2, 7.6))
	water_bodies.append(pond)
	var stone := _mat(Color("777a6d"), 0.98)
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		var radius := 5.45
		var rock_pos := _project_to_terrain(center + Vector3(cos(angle) * radius, 0.02, sin(angle) * radius * 0.68), 0.02)
		_spawn_nature("rock_small_a" if index % 2 == 0 else "rock_small_c", self, rock_pos, 0.72 + float(index % 3) * 0.08, angle)


func _build_fence() -> void:
	var wood := _mat(Color("806549"), 0.94)
	for x in range(-48, 49, 4):
		_add_box("FencePost", _project_to_terrain(Vector3(x, 0, -42), 0.8), Vector3(0.2, 1.6, 0.2), wood, true)
		_add_box("FencePost", _project_to_terrain(Vector3(x, 0, 42), 0.8), Vector3(0.2, 1.6, 0.2), wood, true)
		if x < 48:
			_add_box("FenceRail", _project_to_terrain(Vector3(x + 2, 0, -42), 1.05), Vector3(4.0, 0.14, 0.14), wood, false)
			_add_box("FenceRail", _project_to_terrain(Vector3(x + 2, 0, 42), 1.05), Vector3(4.0, 0.14, 0.14), wood, false)


func _build_distant_hills() -> void:
	var back := _mat(Color("58725c"), 1.0)
	var front := _mat(Color("3e6049"), 1.0)
	for index in range(9):
		var angle := TAU * float(index) / 9.0
		var hill_position := Vector3(cos(angle) * 62.0, -4.8, sin(angle) * 62.0)
		_add_sphere("DistantHill", hill_position, 13.0 + float(index % 3) * 2.0, back, false, Vector3(1.65, 0.55, 1.0))
	for index in range(7):
		var angle := TAU * (float(index) / 7.0 + 0.08)
		var hill_position := Vector3(cos(angle) * 51.0, -5.5, sin(angle) * 51.0)
		_add_sphere("NearHill", hill_position, 11.0 + float(index % 2) * 2.0, front, false, Vector3(1.5, 0.52, 1.0))


func _build_decorative_grass() -> void:
	grass_field = DENSE_GRASS_SCRIPT.new() as DenseGrassField
	grass_field.name = "DenseCuttableGrassField"
	add_child(grass_field)
	var exclusions: Array = map_builder.exclusion_zones if map_builder != null else []
	grass_field.build(terrain_provider, level_id, exclusions, generation_profile)
	grass_field.set_interactor_position(player.global_position)
	outer_biome_ring = OUTER_BIOME_SCRIPT.new() as OuterBiomeRing
	outer_biome_ring.name = "OuterBiomeGrassRing"
	add_child(outer_biome_ring)
	outer_biome_ring.build(terrain_provider, generation_profile)


func _build_ground_details() -> void:
	ground_detail_scatter = GROUND_DETAIL_SCRIPT.new() as GroundDetailScatter
	ground_detail_scatter.name = "GroundDetailScatter"
	add_child(ground_detail_scatter)
	var exclusions: Array = map_builder.exclusion_zones if map_builder != null else []
	ground_detail_scatter.build(terrain_provider, exclusions, generation_profile.seed)


func _build_lod_foliage() -> void:
	foliage_scatter = LOD_FOLIAGE_SCRIPT.new() as LodFoliageScatter
	foliage_scatter.name = "LodFoliageScatter"
	add_child(foliage_scatter)
	var exclusions: Array = map_builder.exclusion_zones if map_builder != null else []
	foliage_scatter.build(terrain_provider, level_id, exclusions, generation_profile)


func _build_vegetation() -> void:
	if level_id != &"home_garden":
		_build_biome_accents()
		return
	var tree_positions := [
		Vector3(-32, 0, -28), Vector3(-39, 0, -18), Vector3(-35, 0, 2), Vector3(-39, 0, 20),
		Vector3(-30, 0, 33), Vector3(-12, 0, 35), Vector3(8, 0, 36), Vector3(34, 0, 30),
		Vector3(40, 0, 12), Vector3(37, 0, -8), Vector3(33, 0, -30), Vector3(9, 0, -36)
	]
	for index in range(tree_positions.size()):
		_build_tree(tree_positions[index], 0.85 + float(index % 4) * 0.09, index)
	for bed in [Vector3(-6, 0, 18), Vector3(7, 0, 18), Vector3(24, 0, 9), Vector3(29, 0, 10)]:
		_build_flower_bed(bed)
	for position_value in [Vector3(-7, 0, 5), Vector3(7, 0, 5), Vector3(-7, 0, -3), Vector3(7, 0, -3)]:
		_build_shrub(position_value)
	_build_wild_understory()


func _build_biome_paths(path_material: Material) -> void:
	match level_id:
		&"shaping_estate":
			_add_box("EstateMainWalk", Vector3(0, 0.02, 1), Vector3(4.2, 0.08, 60), path_material, false)
			_add_box("EstateCrossWalk", Vector3(0, 0.025, -4), Vector3(54, 0.08, 3.0), path_material, false)
		&"forest_path":
			_add_box("ForestTrail", Vector3(0, 0.02, 0), Vector3(3.0, 0.08, 78), path_material, false)
		&"giant_garden":
			_add_box("GiantTrail", Vector3(0, 0.02, 2), Vector3(5.0, 0.08, 70), path_material, false)


func _build_biome_accents() -> void:
	match level_id:
		&"shaping_estate":
			for position_value in [Vector3(-14, 0, 12), Vector3(14, 0, 12), Vector3(-14, 0, -12), Vector3(14, 0, -12)]:
				_build_flower_bed(position_value)
				_build_shrub(position_value + Vector3(0, 0, 2.1))
			_build_shapeable_topiaries()
		&"forest_path":
			for data in [["fallen_log", Vector3(-9, 0, -13), 1.35, 0.7], ["old_stump", Vector3(11, 0, 5), 1.5, -0.4], ["fallen_log", Vector3(13, 0, 24), 1.2, -0.8]]:
				var position_value: Vector3 = data[1]
				var projected: Vector3 = terrain_provider.project(position_value, 0.02) if terrain_provider != null else position_value
				_spawn_nature(str(data[0]), self, projected, float(data[2]), float(data[3]))
		&"giant_garden":
			for position_value in [Vector3(-14, 0, 8), Vector3(14, 0, 4), Vector3(-16, 0, -17), Vector3(17, 0, -22)]:
				var projected: Vector3 = terrain_provider.project(position_value, 0.02) if terrain_provider != null else position_value
				_spawn_nature("flower_purple", self, projected, 5.5, position_value.x)
				_spawn_nature("leaf_cluster", self, projected + Vector3(2.0, 0, 1.0), 6.5, position_value.z)


func _build_shapeable_topiaries() -> void:
	var positions := [
		Vector3(-7.0, 0, 18.0), Vector3(7.0, 0, 18.0), Vector3(-12.0, 0, 10.0), Vector3(12.0, 0, 10.0),
		Vector3(-18.0, 0, 1.0), Vector3(18.0, 0, 1.0), Vector3(-12.0, 0, -9.0), Vector3(12.0, 0, -9.0),
		Vector3(-20.0, 0, -18.0), Vector3(20.0, 0, -18.0), Vector3(-8.0, 0, -23.0), Vector3(8.0, 0, -23.0)
	]
	for index in range(positions.size()):
		var plant := SHAPEABLE_PLANT_SCRIPT.new() as Node3D
		plant.position = _project_to_terrain(positions[index], 0.02)
		plant.rotation.y = float(index) * 0.71
		plant.scale = Vector3.ONE * (0.86 + float(index % 4) * 0.08)
		add_child(plant)
		plant.configure("topiary_%02d" % index, index)
		shapeable_plants.append(plant)


func _build_region_landmark() -> void:
	var title := str(level_profile.get("title", "VADİ"))
	_add_label(self, title, Vector3(0, 4.5, 20.0), Color("fff0c7"), 46)
	match level_id:
		&"shaping_estate":
			var manor := COTTAGE_MODEL.instantiate() as Node3D
			manor.name = "EstateManor"
			manor.position = _project_to_terrain(Vector3(0, 0, -29))
			manor.scale = Vector3.ONE * 17.0
			manor.rotation.y = PI
			add_child(manor)
			_add_invisible_collision(manor, "EstateCollision", Vector3(0, 5.5, 0), Vector3(13, 11, 11))
		&"forest_path":
			_spawn_nature("old_stump", self, _project_to_terrain(Vector3(-5, 0, 21), 0.02), 2.2, 0.3)
		&"giant_garden":
			_spawn_nature("mushroom_red", self, _project_to_terrain(Vector3(-8, 0, 18), 0.02), 9.0, 0.2)
			_spawn_nature("mushroom_tan", self, _project_to_terrain(Vector3(9, 0, 16), 0.02), 11.0, -0.4)


func _place_player_at_level_spawn() -> void:
	var spawn_position: Vector3 = level_profile.get("spawn", Vector3(3.5, 1.1, 27.0))
	if terrain_provider != null:
		spawn_position = terrain_provider.project(spawn_position, 1.1)
	player.global_position = spawn_position


func _build_wild_understory() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 992431
	var model_keys := ["leaf_cluster", "wild_plant", "small_bush", "mushroom_red", "mushroom_tan"]
	var placed := 0
	var attempts := 0
	while placed < 76 and attempts < 900:
		attempts += 1
		var candidate := Vector3(rng.randf_range(-43.0, 43.0), 0.0, rng.randf_range(-37.0, 37.0))
		if absf(candidate.x) < 3.0 and candidate.z > -20.0:
			continue
		if Vector2(candidate.x, candidate.z).distance_to(Vector2(18.0, 18.0)) < 10.5:
			continue
		if Vector2(candidate.x, candidate.z).distance_to(Vector2(-12.0, -10.0)) < 7.5:
			continue
		var model_key: String = model_keys[placed % model_keys.size()]
		var scale_value := rng.randf_range(0.62, 1.28)
		if model_key == "leaf_cluster" or model_key == "small_bush":
			scale_value *= 1.35
		var projected: Vector3 = terrain_provider.project(candidate, 0.02) if terrain_provider != null else candidate
		_spawn_nature(model_key, self, projected, scale_value, rng.randf_range(0.0, TAU))
		placed += 1
	for data in [
		["old_stump", Vector3(-28, 0, -12), 1.4, 0.4],
		["old_stump", Vector3(31, 0, 24), 1.15, -0.7],
		["fallen_log", Vector3(-33, 0, 15), 1.2, 1.1],
		["fallen_log", Vector3(29, 0, -28), 1.0, -0.2]
	]:
		var source_position: Vector3 = data[1]
		var projected: Vector3 = terrain_provider.project(source_position, 0.02) if terrain_provider != null else source_position
		_spawn_nature(data[0], self, projected, data[2], data[3])
	for index in range(9):
		var angle := TAU * float(index) / 9.0
		var lily_position := Vector3(15.0 + cos(angle) * 3.7, 0.0, -14.0 + sin(angle) * 2.2)
		lily_position.y = _project_to_terrain(Vector3(15.0, 0.0, -14.0), 0.12).y
		_spawn_nature("lily_large", self, lily_position, 0.72 + float(index % 3) * 0.08, angle)


func _build_tree(pos: Vector3, scale_value: float, variant: int) -> void:
	var root := Node3D.new()
	root.position = _project_to_terrain(pos)
	add_child(root)
	var model_keys := ["tree_detailed", "tree_default", "tree_cone"]
	_spawn_nature(model_keys[variant % model_keys.size()], root, Vector3.ZERO, scale_value * 4.8, float(variant) * 0.73)
	var body := StaticBody3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.55 * scale_value
	shape.height = 4.8 * scale_value
	var collision := CollisionShape3D.new()
	collision.position.y = shape.height * 0.5
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)


func _build_shrub(pos: Vector3) -> void:
	_spawn_nature("bush_detailed", self, _project_to_terrain(pos, 0.02), 2.15, pos.x * 0.12)
	_spawn_nature("bush_large", self, _project_to_terrain(pos + Vector3(0.7, 0, 0.2), 0.02), 1.65, pos.z * 0.16)


func _build_flower_bed(pos: Vector3) -> void:
	pos = _project_to_terrain(pos)
	var soil := _mat(Color("493629"), 1.0)
	_add_box("FlowerSoil", pos + Vector3(0, 0.14, 0), Vector3(4.8, 0.28, 1.65), soil, false)
	var flower_keys := ["flower_yellow", "flower_red", "flower_purple"]
	for index in range(16):
		var x := -2.0 + float(index % 8) * 0.57
		var z := -0.42 + float(index / 8) * 0.84
		_spawn_nature(flower_keys[index % flower_keys.size()], self, pos + Vector3(x, 0.28, z), 0.72 + float(index % 3) * 0.08, float(index) * 0.9)


func _build_characters() -> void:
	_build_npc(Vector3(4.3, 0, 18.3), "mira", Color("d78b58"), Color("496b52"), "MİRA")
	_build_npc(Vector3(-18.0, 0, -5.0), "worker_lale", Color("c9825d"), Color("7a5264"), "LALE")
	_build_npc(Vector3(22.0, 0, 2.0), "worker_arda", Color("9f684e"), Color("3d6670"), "ARDA")
	_build_cat(Vector3(8.0, 0, 17.2))


func _build_npc(pos: Vector3, kind: String, _skin: Color, _outfit: Color, label_text: String) -> void:
	var root := Node3D.new()
	root.name = label_text.capitalize()
	root.add_to_group("npc")
	if kind == "mira":
		root.add_to_group("quest")
	root.position = _project_to_terrain(pos)
	root.rotation.y = PI
	add_child(root)
	var visual := GardenCharacterVisual.new()
	visual.name = "AnimatedCharacter"
	visual.model_scene = MIRA_MODEL
	visual.character_scale = 0.92
	root.add_child(visual)
	visual.build()
	var character_hitbox := COLLISION_FACTORY.add_capsule(root, "CharacterHitbox", Vector3(0.0, 0.98, 0.0), 0.38, 1.96, true)
	character_hitbox.set_meta("owner_kind", StringName(kind))
	var area := InteractionTarget.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.55
	shape.height = 2.4
	area.configure(StringName(kind), "%s ile konuş" % label_text.capitalize(), shape, Vector3(0, 1.2, 0))
	root.add_child(area)
	_add_label(root, label_text, Vector3(0, 2.65, 0), Color("fff0c7"), 34)
	var schedule := NPC_SCHEDULE_SCRIPT.new() as GardenNPCSchedule
	schedule.name = "LimboAISchedule"
	root.add_child(schedule)
	schedule.configure(root, StringName(kind), root.global_position)
	npc_schedules.append(schedule)


func _build_cat(pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = "YuzuCompanion"
	root.position = _project_to_terrain(pos)
	root.add_to_group("garden_animals")
	root.add_to_group("companion")
	add_child(root)
	var fur := _mat(Color("d6a273"), 0.9)
	_add_capsule_to(root, Vector3(0, 0.38, 0), 0.22, 0.72, fur, false, Vector3(PI * 0.5, 0, 0))
	_add_sphere_to(root, Vector3(0, 0.58, -0.42), 0.24, fur)
	_add_box_to(root, "EarL", Vector3(-0.14, 0.82, -0.43), Vector3(0.13, 0.26, 0.08), fur, false, Vector3(0, 0, -0.28))
	_add_box_to(root, "EarR", Vector3(0.14, 0.82, -0.43), Vector3(0.13, 0.26, 0.08), fur, false, Vector3(0, 0, 0.28))
	var animal_hitbox := COLLISION_FACTORY.add_box(root, "AnimalHitbox", Vector3(0.0, 0.42, -0.08), Vector3(0.52, 0.58, 0.94), true)
	animal_hitbox.set_meta("owner_kind", &"yuzu")
	var area := InteractionTarget.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.65
	area.configure(&"yuzu", "Yuzu'yu sev", shape, Vector3(0, 0.45, 0))
	root.add_child(area)
	_add_label(root, "YUZU", Vector3(0, 1.25, 0), Color("ffe1c4"), 26)


func _build_grass_job() -> void:
	var center := Vector3(-2, 0, -24)
	for index in range(12):
		var grass := GRASS_SCRIPT.new() as CuttableGrass
		var column := index % 4
		var row := index / 4
		grass.position = _project_to_terrain(center + Vector3((float(column) - 1.5) * 2.2, 0.0, (float(row) - 1.0) * 2.2), 0.02)
		grass.collision_layer = 2
		add_child(grass)
		grass.setup(9100 + index * 37, Color("4f913b"))
		grass_nodes.append(grass)
	_add_label(self, "DERE KENARI", _project_to_terrain(center + Vector3(0, 0, 3.7), 2.6), Color("e8e0b6"), 38)


func _project_to_terrain(world_position: Vector3, vertical_offset := 0.0) -> Vector3:
	if terrain_provider == null:
		return Vector3(world_position.x, world_position.y + vertical_offset, world_position.z)
	return terrain_provider.project(world_position, vertical_offset)


func _nearest_animal_position() -> Vector3:
	var nearest := Vector3.INF
	var nearest_distance := INF
	for animal_node in get_tree().get_nodes_in_group("garden_animals"):
		var animal := animal_node as Node3D
		if animal == null or not is_ancestor_of(animal):
			continue
		var distance := player.global_position.distance_squared_to(animal.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = animal.global_position
	return nearest


func _apply_daylight(hour: float, daylight: float) -> void:
	if environment is Sky3D:
		(environment as Sky3D).current_time = hour
	var day_angle := (hour - 6.0) / 24.0 * TAU
	if not environment is Sky3D:
		sun.rotation.x = day_angle
	sun.light_energy = lerpf(0.1, 2.75, daylight)
	environment.environment.ambient_light_energy = lerpf(0.28, 0.92, daylight)
	var night_tint := Color("9ab2d0")
	var day_tint := Color("ffe3b0")
	sun.light_color = night_tint.lerp(day_tint, daylight)
	if artistic_sky != null:
		artistic_sky.apply_time(hour, daylight)
	if graphics_manager != null and season_system != null:
		graphics_manager.apply_time(hour, weather.raining if weather != null else false, season_system.tint())


func _apply_wetness(raining: bool) -> void:
	if artistic_sky != null:
		artistic_sky.set_raining(raining)
	if atmosphere_effects != null:
		atmosphere_effects.set_raining(raining)
	if graphics_manager != null:
		graphics_manager.set_raining(raining, session.world_hour if session != null else 12.0)
	state_coordinator.send_domain_event(&"weather", &"rain" if raining else &"clear")
	for water_body in water_bodies:
		water_body.add_ripple(water_body.global_position, 0.75 if raining else 0.1)
	if ground_material == null:
		return
	var parameter_value: Variant = ground_material.get_shader_parameter("wetness")
	var current_wetness: float = parameter_value if parameter_value is float else 0.0
	var tween := create_tween()
	var wetness_callback := func(value: float) -> void:
		ground_material.set_shader_parameter("wetness", value)
		if grass_field != null:
			grass_field.set_wetness(value)
	tween.tween_method(
		wetness_callback,
		current_wetness,
		1.0 if raining else 0.0,
		2.4
	)


func _mat(color: Color, roughness := 0.9, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _create_path_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = PATH_DIFFUSE
	material.normal_enabled = true
	material.normal_texture = PATH_NORMAL
	material.ao_enabled = true
	material.ao_texture = PATH_ARM
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness = 0.92
	material.uv1_triplanar = true
	material.uv1_scale = Vector3(0.42, 0.42, 0.42)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _add_invisible_collision(parent: Node3D, name_value: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	return COLLISION_FACTORY.add_box(parent, name_value, pos, size) as StaticBody3D


func _add_box_occluder(parent: Node3D, pos: Vector3, size: Vector3) -> OccluderInstance3D:
	var instance := OccluderInstance3D.new()
	instance.name = "StaticOccluder"
	instance.position = pos
	var resource := BoxOccluder3D.new()
	resource.size = size
	instance.occluder = resource
	parent.add_child(instance)
	return instance


func _add_box(name_value: String, pos: Vector3, size: Vector3, material: Material, collision_enabled: bool, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	return _add_box_to(self, name_value, pos, size, material, collision_enabled, rotation_value)


func _add_box_to(parent: Node3D, name_value: String, pos: Vector3, size: Vector3, material: Material, collision_enabled: bool, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_value
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.rotation = rotation_value
	node.material_override = material
	parent.add_child(node)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.position = pos
		body.rotation = rotation_value
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
	return node


func _add_cylinder(name_value: String, pos: Vector3, radius: float, height: float, material: Material, collision_enabled: bool) -> MeshInstance3D:
	return _add_cylinder_to(self, pos, radius, height, material, collision_enabled, Vector3.ZERO, name_value)


func _add_cylinder_to(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, collision_enabled: bool, rotation_value := Vector3.ZERO, name_value := "Cylinder") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_value
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.86
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.rotation = rotation_value
	node.material_override = material
	parent.add_child(node)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.position = pos
		body.rotation = rotation_value
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
	return node


func _add_sphere(name_value: String, pos: Vector3, radius: float, material: Material, collision_enabled: bool, scale_value := Vector3.ONE) -> MeshInstance3D:
	var node := _add_sphere_to(self, pos, radius, material)
	node.name = name_value
	node.scale = scale_value
	if collision_enabled:
		var body := StaticBody3D.new()
		body.position = pos
		var shape := SphereShape3D.new()
		shape.radius = radius * maxf(scale_value.x, scale_value.z)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	return node


func _add_sphere_to(parent: Node3D, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	parent.add_child(node)
	return node


func _add_capsule_to(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, collision_enabled := false, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.rotation = rotation_value
	node.material_override = material
	parent.add_child(node)
	return node


func _add_label(parent: Node3D, text_value: String, pos: Vector3, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = pos
	label.font = FONT
	label.font_size = font_size
	label.modulate = color
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label


func _spawn_nature(model_key: String, parent: Node3D, pos: Vector3, scale_value: float, rotation_y: float) -> Node3D:
	var packed := NATURE_MODELS.get(model_key) as PackedScene
	if packed == null:
		return Node3D.new()
	var instance := packed.instantiate() as Node3D
	instance.position = pos
	instance.rotation.y = rotation_y
	instance.scale = Vector3.ONE * scale_value
	parent.add_child(instance)
	_recolor_nature(instance, model_key)
	match model_key:
		"rock_large_a", "rock_large_c", "rock_small_a", "rock_small_c":
			COLLISION_FACTORY.add_visual_bounds_box(instance, "RockHitbox", Vector3(0.24, 0.18, 0.24), Vector3(0.82, 0.76, 0.82))
		"log_stack", "old_stump", "fallen_log":
			COLLISION_FACTORY.add_visual_bounds_box(instance, "WoodHitbox", Vector3(0.42, 0.32, 0.42), Vector3(0.76, 0.80, 0.76))
		"mushroom_red", "mushroom_tan":
			if scale_value >= 3.0:
				COLLISION_FACTORY.add_cylinder(instance, "GiantMushroomHitbox", Vector3(0.0, 0.8, 0.0), 0.20, 1.6)
	return instance


func _recolor_nature(instance: Node3D, model_key: String) -> void:
	for child: Node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var original: Material = mesh_instance.mesh.surface_get_material(surface_index)
			var original_name := original.resource_name.to_lower() if original != null else ""
			var replacement: StandardMaterial3D
			if model_key.begins_with("tree"):
				replacement = _mat(Color("477a3f") if "leaf" in original_name else Color("654735"), 0.9)
			elif model_key.begins_with("bush"):
				replacement = _mat(Color("3f763e"), 0.92)
			elif model_key.begins_with("rock"):
				replacement = _mat(Color("73796f"), 0.98)
			elif model_key == "log_stack":
				replacement = _mat(Color("694a35"), 0.94)
			else:
				continue
			mesh_instance.set_surface_override_material(surface_index, replacement)
