class_name GardenGraphicsManager
extends Node

signal quality_changed(profile: int)
signal atmosphere_changed(profile_name: StringName)

const PROFILE_NAMES := [&"performans", &"dengeli", &"yuksek", &"sinematik"]
const ATMOSPHERE_COLORS := {
	&"sabah": [Color("dbe9d4"), Color("ffd49b"), 0.96, 1.02],
	&"ogle": [Color("cfe0d1"), Color("fff0c5"), 1.02, 1.08],
	&"gun_batimi": [Color("d8b69f"), Color("ff9c6b"), 0.94, 1.16],
	&"yagmur": [Color("82969a"), Color("a9b7b4"), 0.78, 0.82],
	&"gece": [Color("35465f"), Color("8198c4"), 0.60, 0.72],
}

var world_environment: WorldEnvironment
var camera_attributes: CameraAttributesPractical
var quality_profile := 2
var current_atmosphere := &"sabah"
var season_tint := Color.WHITE
var raining := false


func configure(target: WorldEnvironment) -> void:
	world_environment = target
	if world_environment == null or world_environment.environment == null:
		return
	camera_attributes = CameraAttributesPractical.new()
	camera_attributes.dof_blur_far_enabled = true
	camera_attributes.dof_blur_far_distance = 36.0
	camera_attributes.dof_blur_far_transition = 18.0
	camera_attributes.dof_blur_amount = 0.08
	world_environment.camera_attributes = camera_attributes
	apply_quality(quality_profile)


func apply_quality(profile: int) -> void:
	quality_profile = clampi(profile, 0, 3)
	if world_environment == null or world_environment.environment == null:
		return
	var env := world_environment.environment
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = quality_profile >= 1
	env.glow_intensity = [0.0, 0.36, 0.55, 0.72][quality_profile]
	env.glow_bloom = [0.0, 0.025, 0.045, 0.065][quality_profile]
	env.ssao_enabled = quality_profile >= 1
	env.ssao_radius = [1.0, 1.55, 2.15, 2.65][quality_profile]
	env.ssao_intensity = [0.0, 1.25, 1.8, 2.15][quality_profile]
	env.ssil_enabled = quality_profile >= 2
	env.ssil_radius = [1.0, 1.0, 3.0, 4.5][quality_profile]
	env.ssil_intensity = [0.0, 0.0, 0.72, 1.0][quality_profile]
	env.sdfgi_enabled = quality_profile >= 3
	env.sdfgi_cascades = 4 if quality_profile >= 3 else 2
	env.volumetric_fog_enabled = quality_profile >= 2
	env.volumetric_fog_density = [0.0, 0.0, 0.0022, 0.0038][quality_profile]
	env.volumetric_fog_length = [16.0, 32.0, 56.0, 72.0][quality_profile]
	if camera_attributes != null:
		camera_attributes.dof_blur_far_enabled = quality_profile >= 2
		camera_attributes.dof_blur_amount = [0.0, 0.0, 0.055, 0.085][quality_profile]
	quality_changed.emit(quality_profile)


func apply_feature_overrides(options: Dictionary) -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env := world_environment.environment
	env.ssao_enabled = bool(options.get("ssao", env.ssao_enabled))
	env.ssil_enabled = bool(options.get("ssil", env.ssil_enabled))
	env.sdfgi_enabled = bool(options.get("sdfgi", env.sdfgi_enabled))
	env.volumetric_fog_enabled = bool(options.get("volumetric_fog", env.volumetric_fog_enabled))
	if camera_attributes != null:
		camera_attributes.dof_blur_far_enabled = bool(options.get("dof", camera_attributes.dof_blur_far_enabled))


func apply_time(hour: float, is_raining: bool, tint: Color = Color.WHITE) -> void:
	raining = is_raining
	season_tint = tint
	var next_profile := &"yagmur" if raining else _profile_for_hour(hour)
	if next_profile != current_atmosphere:
		current_atmosphere = next_profile
		atmosphere_changed.emit(current_atmosphere)
	_apply_color_profile()


func set_raining(value: bool, hour := 12.0) -> void:
	apply_time(hour, value, season_tint)


func profile_summary() -> Dictionary:
	return {
		"quality": PROFILE_NAMES[quality_profile],
		"atmosphere": current_atmosphere,
		"ssao": quality_profile >= 1,
		"ssil": quality_profile >= 2,
		"sdfgi": quality_profile >= 3,
		"volumetric_fog": quality_profile >= 2,
		"dof": quality_profile >= 2,
	}


func _profile_for_hour(hour: float) -> StringName:
	if hour < 5.5 or hour >= 20.5:
		return &"gece"
	if hour < 10.0:
		return &"sabah"
	if hour < 17.0:
		return &"ogle"
	return &"gun_batimi"


func _apply_color_profile() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env := world_environment.environment
	var values: Array = ATMOSPHERE_COLORS[current_atmosphere]
	var fog_color: Color = values[0]
	var ambient_color: Color = values[1]
	env.fog_light_color = fog_color.lerp(season_tint, 0.12)
	env.ambient_light_color = ambient_color.lerp(season_tint, 0.16)
	env.adjustment_enabled = true
	env.adjustment_brightness = float(values[2])
	env.adjustment_saturation = float(values[3])
	env.adjustment_contrast = 1.035 if current_atmosphere != &"yagmur" else 0.96
	env.fog_density = 0.0042 if current_atmosphere == &"yagmur" else (0.0018 if current_atmosphere == &"gece" else 0.00072)
