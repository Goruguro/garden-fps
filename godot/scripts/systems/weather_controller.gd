class_name GardenWeatherController
extends Node3D

signal rain_changed(raining: bool)

var environment: WorldEnvironment
var tracked_player: Node3D
var cloud_root: Node3D
var rain_root: Node3D
var rain_audio: AudioStreamPlayer
var ambience_audio: AudioStreamPlayer
var weather_timer := 52.0
var rain_time := 0.0
var rng := RandomNumberGenerator.new()
var raining := false
var rain_frequency_multiplier := 1.0


func configure(world_environment: WorldEnvironment, player: Node3D) -> void:
	environment = world_environment
	tracked_player = player
	rng.seed = 481516
	_build_clouds()
	_build_rain()
	_build_audio()


func advance(delta: float) -> void:
	if cloud_root == null:
		return
	cloud_root.position.x = fposmod(cloud_root.position.x + delta * 0.35 + 60.0, 120.0) - 60.0
	if rain_time > 0.0:
		_update_rain(delta)
	else:
		weather_timer -= delta
		if weather_timer <= 0.0:
			_start_rain()


func _build_clouds() -> void:
	cloud_root = Node3D.new()
	cloud_root.name = "Clouds"
	add_child(cloud_root)
	# Cloud detail now lives in the blended AllSky panoramas; nearby mesh clouds
	# looked like bright cut-outs and competed with the painted composition.


func _build_rain() -> void:
	rain_root = Node3D.new()
	rain_root.name = "Rain"
	rain_root.visible = false
	add_child(rain_root)
	var rain := GPUParticles3D.new()
	rain.name = "OptimizedRainDrops"
	rain.amount = 1450
	rain.lifetime = 1.15
	rain.visibility_aabb = AABB(Vector3(-20.0, -2.0, -20.0), Vector3(40.0, 20.0, 40.0))
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(18.0, 8.0, 18.0)
	process_material.direction = Vector3(0.08, -1.0, 0.04)
	process_material.spread = 4.0
	process_material.initial_velocity_min = 17.0
	process_material.initial_velocity_max = 23.0
	process_material.gravity = Vector3(0.8, -9.8, 0.35)
	rain.process_material = process_material
	var drop_mesh := BoxMesh.new()
	drop_mesh.size = Vector3(0.012, 0.42, 0.012)
	var rain_material := StandardMaterial3D.new()
	rain_material.albedo_color = Color(0.72, 0.88, 1.0, 0.46)
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mesh.material = rain_material
	rain.draw_pass_1 = drop_mesh
	rain_root.add_child(rain)


func _build_audio() -> void:
	ambience_audio = AudioStreamPlayer.new()
	ambience_audio.stream = load("res://audio/ambience/garden_day.wav")
	ambience_audio.volume_db = -15.0
	ambience_audio.autoplay = DisplayServer.get_name() != "headless"
	add_child(ambience_audio)
	rain_audio = AudioStreamPlayer.new()
	rain_audio.stream = load("res://audio/sfx/rain_soft.wav")
	rain_audio.volume_db = -12.0
	add_child(rain_audio)


func _update_rain(delta: float) -> void:
	rain_time -= delta
	if tracked_player != null:
		rain_root.position = tracked_player.position
	if rain_time <= 0.0:
		raining = false
		rain_root.visible = false
		rain_audio.stop()
		if environment != null:
			environment.environment.fog_density = 0.0022
		rain_changed.emit(false)


func _start_rain() -> void:
	weather_timer = rng.randf_range(95.0, 160.0) / maxf(rain_frequency_multiplier, 0.25)
	rain_time = rng.randf_range(14.0, 24.0)
	raining = true
	rain_root.visible = true
	rain_audio.play()
	if environment != null:
		environment.environment.fog_density = 0.006
	rain_changed.emit(true)
