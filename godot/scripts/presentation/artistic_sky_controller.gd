class_name ArtisticSkyController
extends Node

const DAY_PANORAMA := preload("res://assets/third_party/allsky_free/epic_blue.png")
const NIGHT_PANORAMA := preload("res://assets/third_party/allsky_free/cartoon_night.png")
const OVERCAST_PANORAMA := preload("res://assets/third_party/allsky_free/overcast.png")

var environment: Environment
var sky_material: ShaderMaterial
var raining := false
var current_hour := 9.25
var current_daylight := 1.0


func configure(target_environment: Environment) -> void:
	environment = target_environment
	var shader := Shader.new()
	shader.code = """
shader_type sky;
render_mode use_debanding;
uniform sampler2D day_panorama : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D night_panorama : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D overcast_panorama : source_color, filter_linear_mipmap_anisotropic;
uniform float night_mix : hint_range(0.0, 1.0) = 0.0;
uniform float storm_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec3 artistic_tint : source_color = vec3(1.0);
uniform float exposure = 1.0;
void sky() {
	vec3 day_color = texture(day_panorama, SKY_COORDS).rgb;
	vec3 night_color = texture(night_panorama, SKY_COORDS).rgb;
	vec3 storm_color = texture(overcast_panorama, SKY_COORDS).rgb;
	vec3 time_color = mix(day_color, night_color, night_mix);
	COLOR = mix(time_color, storm_color, storm_mix) * artistic_tint * exposure;
}
"""
	sky_material = ShaderMaterial.new()
	sky_material.shader = shader
	sky_material.set_shader_parameter("day_panorama", DAY_PANORAMA)
	sky_material.set_shader_parameter("night_panorama", NIGHT_PANORAMA)
	sky_material.set_shader_parameter("overcast_panorama", OVERCAST_PANORAMA)
	var sky := Sky.new()
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	sky.sky_material = sky_material
	environment.sky = sky
	apply_time(current_hour, current_daylight)


func apply_time(hour: float, daylight: float) -> void:
	current_hour = hour
	current_daylight = daylight
	if sky_material == null:
		return
	var night_mix := 1.0 - smoothstep(0.08, 0.42, daylight)
	var sunrise := 1.0 - clampf(absf(hour - 6.5) / 2.2, 0.0, 1.0)
	var sunset := 1.0 - clampf(absf(hour - 19.0) / 2.3, 0.0, 1.0)
	var golden_hour := maxf(sunrise, sunset)
	var tint := Color("fff4dc").lerp(Color("efad83"), golden_hour)
	sky_material.set_shader_parameter("night_mix", night_mix)
	sky_material.set_shader_parameter("storm_mix", 0.72 if raining else 0.0)
	sky_material.set_shader_parameter("artistic_tint", Vector3(tint.r, tint.g, tint.b))
	sky_material.set_shader_parameter("exposure", lerpf(0.52, 1.08, daylight))
	if environment != null:
		environment.background_energy_multiplier = lerpf(0.32, 0.78, daylight)
		environment.fog_light_color = Color("7284a8").lerp(Color("e7dfbf"), daylight)


func set_raining(value: bool) -> void:
	raining = value
	apply_time(current_hour, current_daylight)
