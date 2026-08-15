class_name GardenDecalSystem
extends Node3D

const MAX_RUNTIME_DECALS := 32

var wet_material_texture: ImageTexture
var runtime_decals: Array[Decal] = []
var quality_profile := 2


func build_static_decals() -> void:
	wet_material_texture = _create_soft_circle_texture(128)
	for index in range(14):
		var angle := TAU * float(index) / 14.0
		var radius := 4.0 + float(index % 4) * 2.7
		spawn_decal(Vector3(cos(angle) * radius, 0.08, sin(angle) * radius - 3.0), 1.2 + float(index % 3) * 0.45, false)


func spawn_tool_mark(world_position: Vector3) -> void:
	spawn_decal(world_position + Vector3.UP * 0.06, 0.72, true)


func spawn_decal(world_position: Vector3, size_value: float, runtime := true) -> void:
	if quality_profile <= 0 or wet_material_texture == null:
		return
	var decal := Decal.new()
	decal.name = "ToolImpactDecal" if runtime else "GardenGroundDecal"
	decal.position = world_position
	decal.rotation_degrees.x = -90.0
	decal.size = Vector3(size_value, size_value * 1.35, size_value)
	decal.texture_albedo = wet_material_texture
	decal.modulate = Color(0.24, 0.18, 0.10, 0.24 if runtime else 0.11)
	decal.upper_fade = 0.35
	decal.lower_fade = 0.35
	decal.distance_fade_enabled = true
	decal.distance_fade_begin = 22.0
	decal.distance_fade_length = 12.0
	add_child(decal)
	if runtime:
		runtime_decals.append(decal)
		while runtime_decals.size() > MAX_RUNTIME_DECALS:
			var oldest: Decal = runtime_decals.pop_front()
			if is_instance_valid(oldest):
				oldest.queue_free()


func set_quality_profile(profile: int) -> void:
	quality_profile = clampi(profile, 0, 3)
	visible = quality_profile > 0


func _create_soft_circle_texture(size_value: int) -> ImageTexture:
	var image := Image.create_empty(size_value, size_value, false, Image.FORMAT_RGBA8)
	var center := Vector2.ONE * float(size_value - 1) * 0.5
	for y in size_value:
		for x in size_value:
			var normalized := Vector2(x, y).distance_to(center) / center.x
			var alpha := smoothstep(1.0, 0.42, normalized)
			var mottling := sin(float(x) * 0.31) * sin(float(y) * 0.23) * 0.08
			image.set_pixel(x, y, Color(0.32, 0.23, 0.12, clampf(alpha + mottling, 0.0, 1.0)))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
