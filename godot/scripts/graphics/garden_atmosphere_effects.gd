class_name GardenAtmosphereEffects
extends Node3D

var tracked_player: Node3D
var pollen: GPUParticles3D
var drifting_leaves: GPUParticles3D
var mist_volume: FogVolume
var quality_profile := 2


func build(player: Node3D) -> void:
	tracked_player = player
	name = "AtmosphereEffectPack"
	pollen = _create_particles("Pollen", 120, Color(1.0, 0.82, 0.34, 0.48), Vector3(0.0, 0.06, 0.0), 0.018)
	drifting_leaves = _create_particles("DriftingLeaves", 54, Color(0.55, 0.72, 0.28, 0.72), Vector3(0.3, -0.12, 0.16), 0.052)
	mist_volume = FogVolume.new()
	mist_volume.name = "ValleyMist"
	mist_volume.size = Vector3(96.0, 7.0, 84.0)
	mist_volume.position.y = 1.4
	var fog_material := FogMaterial.new()
	fog_material.density = 0.008
	fog_material.albedo = Color("c9dbcf")
	fog_material.emission = Color("789481")
	mist_volume.material = fog_material
	add_child(mist_volume)
	set_quality_profile(quality_profile)


func set_quality_profile(profile: int) -> void:
	quality_profile = clampi(profile, 0, 3)
	if pollen != null:
		pollen.amount = [18, 58, 120, 190][quality_profile]
		drifting_leaves.amount = [8, 24, 54, 80][quality_profile]
		mist_volume.visible = quality_profile >= 2


func set_raining(raining: bool) -> void:
	if pollen != null:
		pollen.emitting = not raining and quality_profile > 0
		drifting_leaves.emitting = not raining and quality_profile > 0
	if mist_volume != null:
		mist_volume.visible = quality_profile >= 2
		(mist_volume.material as FogMaterial).density = 0.028 if raining else 0.008


func _process(_delta: float) -> void:
	if tracked_player != null:
		global_position.x = tracked_player.global_position.x
		global_position.z = tracked_player.global_position.z


func _create_particles(title: String, amount_value: int, color: Color, direction: Vector3, radius: float) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = title
	particles.amount = amount_value
	particles.lifetime = 7.0
	particles.randomness = 0.75
	particles.visibility_aabb = AABB(Vector3(-24.0, -2.0, -24.0), Vector3(48.0, 16.0, 48.0))
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(20.0, 5.0, 20.0)
	process_material.direction = direction.normalized()
	process_material.spread = 70.0
	process_material.initial_velocity_min = 0.08
	process_material.initial_velocity_max = 0.34
	process_material.gravity = direction
	process_material.color = color
	particles.process_material = process_material
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE * radius
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = material
	particles.draw_pass_1 = mesh
	add_child(particles)
	return particles
