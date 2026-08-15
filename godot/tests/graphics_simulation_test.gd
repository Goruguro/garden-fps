extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	assert(packed != null, "Dünya sahnesi yüklenemedi")
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	session.add_item("gubre", 2)
	world.setup(session)
	await process_frame

	assert(world.environment is Sky3D, "Sky3D etkin dünya ortamı değil")
	assert(world.graphics_manager != null, "Grafik yöneticisi eksik")
	world.graphics_manager.apply_quality(3)
	assert(world.environment.environment.sdfgi_enabled, "Sinematik profilde SDFGI açılmadı")
	assert(world.environment.environment.ssil_enabled, "Sinematik profilde SSIL açılmadı")
	assert(world.environment.environment.ssao_enabled, "Sinematik profilde SSAO açılmadı")
	assert(world.environment.environment.volumetric_fog_enabled, "Sinematik profilde hacimsel sis açılmadı")
	world.graphics_manager.apply_feature_overrides({"sdfgi": false, "ssil": false})
	assert(not world.environment.environment.sdfgi_enabled and not world.environment.environment.ssil_enabled, "Grafik özellik anahtarları çalışmıyor")

	assert(world.terrain_runtime.terrain.assets.get_texture_count() >= 7, "Terrain3D katman kataloğu eksik")
	for texture_index in range(6):
		assert(world.terrain_runtime.terrain.assets.get_texture(texture_index) != null, "Terrain3D katmanı eksik: %d" % texture_index)
	var terrain_parameters: Dictionary = world.terrain_runtime.terrain.material.call("_get_shader_parameters")
	assert(terrain_parameters.get(&"auto_base_texture") == 5, "Eğimlerde kaya otomatik seçilmiyor")
	assert(terrain_parameters.get(&"auto_overlay_texture") == 0, "Düz alanlarda çimen otomatik seçilmiyor")
	assert(bool(terrain_parameters.get(&"enable_macro_variation")), "Uzak zemin renk varyasyonu etkin değil")

	assert(world.water_bodies.size() == 1, "Gelişmiş su gövdesi kurulmadı")
	assert(world.water_bodies[0].material != null, "Boujie su malzemesi eksik")
	assert(world.decal_system != null and world.decal_system.get_child_count() >= 14, "Decal sistemi kurulmadı")
	assert(world.atmosphere_effects != null and world.atmosphere_effects.mist_volume != null, "Atmosfer paketi kurulmadı")
	assert(world.get_node_or_null("Cottage/CottageReflectionProbe") is ReflectionProbe, "Ev ReflectionProbe eksik")
	assert(world.get_node_or_null("Cottage/CottageLightmapGI") is LightmapGI, "Ev LightmapGI eksik")
	assert(world.get_node_or_null("Cottage/StaticOccluder") is OccluderInstance3D, "Ev occluder eksik")

	assert(world.crop_system.plots.size() == 18, "Quaternius ekin parselleri eksik")
	assert(world.crop_system.get_stats().stages == 5, "Beş büyüme aşaması tanımlı değil")
	assert(world.crop_system.apply_fertilizer(), "Gübre ekinlere uygulanamadı")
	assert(session.fertilizer_bonus > 0.0, "Gübre büyüme bonusu oluşturmadı")
	assert(world.irrigation_system.sprinkler_heads.size() == 3, "Sprinkler sistemi eksik")
	world.irrigation_system.set_active(true)
	assert(world.irrigation_system.active and world.irrigation_system.water_particles[0].emitting, "Sulama animasyonu çalışmıyor")

	assert(world.state_coordinator.chart is StateChart, "Godot State Charts bağlantısı eksik")
	world.state_coordinator.send_domain_event(&"weather", &"rain")
	assert(world.state_coordinator.active_states.weather == &"rain", "Hava durum makinesi güncellenmedi")
	assert(world.npc_schedules.size() >= 3, "NPC günlük programları eksik")
	for schedule in world.npc_schedules:
		schedule.advance(0.2, 10.0, true)
		assert(schedule.activity == GardenNPCSchedule.Activity.SHELTER, "NPC yağmurdan kaçma durumuna geçmedi")

	assert(world.foliage_scatter.medium_proxy_count == 0, "Küresel orta LOD ağaç siluetleri kapatılmadı")
	assert(world.foliage_scatter.far_proxy_count == 0, "Küresel uzak LOD ağaç siluetleri kapatılmadı")
	assert(world.ground_detail_scatter != null and world.ground_detail_scatter.instance_count >= 900, "3B zemin mikro detayları eksik")
	var grass_shadow_found := false
	for cell: Dictionary in world.grass_field.cells:
		var instances: Array = cell.instances
		if not instances.is_empty() and (instances[0] as GeometryInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			grass_shadow_found = true
			break
	assert(grass_shadow_found, "Yakın çim gölgesi bulunamadı")

	print("GRAPHICS_SIMULATION_OK: 2K PBR Terrain3D, 3D ground scatter, proxy-free trees, Sky3D, water, decals, GI, seasons and NPC schedules")
	root.remove_child(world)
	world.free()
	await process_frame
	quit()
