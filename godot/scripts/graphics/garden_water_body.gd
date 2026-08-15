class_name GardenWaterBody
extends Node3D

const BOUJIE_MATERIAL := preload("res://addons/boujie_water_shader/prefabs/outset_ocean_material.tres")

var surface: MeshInstance3D
var material: ShaderMaterial
var ripple_strength := 0.0


func build_pond(size_value := Vector2(11.2, 7.6)) -> void:
	name = "BoujieGardenWater"
	surface = MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size_value
	mesh.subdivide_width = 48
	mesh.subdivide_depth = 36
	surface.mesh = mesh
	material = BOUJIE_MATERIAL.duplicate(true) as ShaderMaterial
	material.set_shader_parameter("albedo", Color(0.08, 0.48, 0.58, 0.62))
	material.set_shader_parameter("color_shallow", Color(0.20, 0.72, 0.66, 0.58))
	material.set_shader_parameter("color_deep", Color(0.025, 0.16, 0.26, 0.94))
	material.set_shader_parameter("roughness", 0.12)
	material.set_shader_parameter("metallic", 0.02)
	material.set_shader_parameter("shore_start_blend", 0.35)
	material.set_shader_parameter("shore_end_blend", 1.8)
	material.set_shader_parameter("distance_fade_min", 46.0)
	material.set_shader_parameter("distance_fade_max", 74.0)
	material.set_shader_parameter("vertex_wave_fade_min", 24.0)
	material.set_shader_parameter("vertex_wave_fade_max", 58.0)
	material.set_shader_parameter("WaveAmplitudes", PackedFloat32Array([0.035, 0.018, 0.012, 0.009, 0.006]))
	material.set_shader_parameter("WaveFrequencies", PackedFloat32Array([0.22, 0.41, 0.58, 0.76, 1.05]))
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)


func add_ripple(_world_position: Vector3, strength := 1.0) -> void:
	ripple_strength = clampf(ripple_strength + strength, 0.0, 1.0)


func set_quality_profile(profile: int) -> void:
	if surface == null:
		return
	var quality := clampi(profile, 0, 3)
	surface.visibility_range_end = [38.0, 58.0, 82.0, 110.0][quality]
	material.set_shader_parameter("refraction", [0.0, 0.06, 0.10, 0.14][quality])
	material.set_shader_parameter("refraction_opacity", [0.0, 0.45, 0.62, 0.74][quality])


func _process(delta: float) -> void:
	ripple_strength = move_toward(ripple_strength, 0.0, delta * 0.55)
	if material != null:
		material.set_shader_parameter("specular", lerpf(0.44, 0.76, ripple_strength))
