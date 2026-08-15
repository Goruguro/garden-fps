class_name GardenIrrigationSystem
extends Node3D

var active := false
var session: GameSession
var sprinkler_heads: Array[Node3D] = []
var water_particles: Array[GPUParticles3D] = []


func build(active_session: GameSession, provider: Node) -> void:
	session = active_session
	name = "AutomaticIrrigation"
	_build_pipe_line(provider)
	for position_value in [Vector3(22.0, 0.0, 5.0), Vector3(27.0, 0.0, 5.0), Vector3(27.0, 0.0, 12.8)]:
		_build_sprinkler(provider.project(position_value, 0.0) if provider != null else position_value)
	set_active(session.irrigation_owned and session.irrigation_enabled)


func set_active(value: bool) -> void:
	active = value and session != null and session.irrigation_owned
	if session != null:
		session.irrigation_enabled = active
	for particles in water_particles:
		particles.emitting = active


func update_schedule(hour: float, raining: bool) -> void:
	if session == null or not session.irrigation_owned:
		set_active(false)
		return
	var scheduled := (hour >= 6.0 and hour < 8.5) or (hour >= 18.0 and hour < 19.5)
	set_active(scheduled and not raining)


func _build_pipe_line(provider: Node) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("315d5c")
	material.metallic = 0.42
	material.roughness = 0.38
	for index in 4:
		var pipe := MeshInstance3D.new()
		pipe.name = "IrrigationPipe"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.08
		mesh.bottom_radius = 0.08
		mesh.height = 4.8
		mesh.radial_segments = 10
		pipe.mesh = mesh
		pipe.rotation_degrees.z = 90.0
		var position_value := Vector3(20.0 + float(index) * 4.6, 0.18, 14.0)
		pipe.position = provider.project(position_value, 0.18) if provider != null else position_value
		pipe.material_override = material
		add_child(pipe)


func _build_sprinkler(position_value: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Sprinkler"
	root.position = position_value
	add_child(root)
	var post := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07
	mesh.bottom_radius = 0.09
	mesh.height = 0.9
	mesh.radial_segments = 10
	post.mesh = mesh
	post.position.y = 0.45
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("527873")
	material.metallic = 0.55
	material.roughness = 0.32
	post.material_override = material
	root.add_child(post)
	var particles := GPUParticles3D.new()
	particles.amount = 120
	particles.lifetime = 1.1
	particles.position.y = 0.92
	particles.emitting = false
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = 0.08
	process_material.direction = Vector3(1.0, 0.55, 0.0)
	process_material.spread = 42.0
	process_material.initial_velocity_min = 3.8
	process_material.initial_velocity_max = 5.6
	process_material.gravity = Vector3(0.0, -7.5, 0.0)
	particles.process_material = process_material
	var drop_mesh := SphereMesh.new()
	drop_mesh.radius = 0.018
	drop_mesh.height = 0.07
	particles.draw_pass_1 = drop_mesh
	root.add_child(particles)
	sprinkler_heads.append(root)
	water_particles.append(particles)
