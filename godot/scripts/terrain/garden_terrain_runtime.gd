class_name GardenTerrainRuntime
extends Node3D

const MAP_SIZE := 512
const REGION_SIZE := 256
const TERRAIN_HALF_SIZE := MAP_SIZE / 2.0
const HEIGHT_PROVIDER_SCRIPT := preload("res://scripts/terrain/terrain_height_provider.gd")
const PBR_ROOT := "res://assets/third_party/polyhaven_2k_ground/"
const GRASS_ALBEDO := preload(PBR_ROOT + "sparse_grass/sparse_grass_diff_2k.jpg")
const GRASS_NORMAL := preload(PBR_ROOT + "sparse_grass/sparse_grass_normal_2k.jpg")
const DIRT_ALBEDO := preload(PBR_ROOT + "dirt/dirt_diff_2k.jpg")
const DIRT_NORMAL := preload(PBR_ROOT + "dirt/dirt_normal_2k.jpg")
const FOREST_ALBEDO := preload(PBR_ROOT + "forest_floor/forest_floor_diff_2k.jpg")
const FOREST_NORMAL := preload(PBR_ROOT + "forest_floor/forest_floor_normal_2k.jpg")
const DRY_GROUND_ALBEDO := preload(PBR_ROOT + "forrest_ground_03/forrest_ground_03_diff_2k.jpg")
const DRY_GROUND_NORMAL := preload(PBR_ROOT + "forrest_ground_03/forrest_ground_03_normal_2k.jpg")
const MUD_ALBEDO := preload(PBR_ROOT + "mud_forest/mud_forest_diff_2k.jpg")
const MUD_NORMAL := preload(PBR_ROOT + "mud_forest/mud_forest_normal_2k.jpg")
const STONY_ALBEDO := preload(PBR_ROOT + "stony_dirt_path/stony_dirt_path_diff_2k.jpg")
const STONY_NORMAL := preload(PBR_ROOT + "stony_dirt_path/stony_dirt_path_normal_2k.jpg")
const PATH_ALBEDO := preload(PBR_ROOT + "grass_path_3/grass_path_3_diff_2k.jpg")
const PATH_NORMAL := preload(PBR_ROOT + "grass_path_3/grass_path_3_normal_2k.jpg")
const SNOW_ALBEDO := preload(PBR_ROOT + "snow_02/snow_02_diff_2k.jpg")
const SNOW_NORMAL := preload(PBR_ROOT + "snow_02/snow_02_normal_2k.jpg")

var terrain: Terrain3D
var height_provider: Node
var enabled := false
var terrain_seed := 481516
var terrain_style := &"gentle"
var terrain_amplitude := 0.0
var terrain_broad_frequency := 0.0045
var terrain_detail_frequency := 0.018
var terrain_ridge_strength := 0.22
var playable_collision: StaticBody3D
var map_profile_id := &"home_garden"
var snow_zone_center := Vector2(-34.0, -28.0)
var snow_zone_radius := 12.0


func build(seed_value := 481516, style := &"gentle", local_amplitude := 0.0, settings: MapGenerationProfile = null) -> bool:
	terrain_seed = seed_value
	terrain_style = style
	terrain_amplitude = maxf(local_amplitude, 0.0)
	if settings != null:
		map_profile_id = settings.profile_id
		terrain_seed = settings.seed
		terrain_style = StringName(settings.terrain_style)
		terrain_amplitude = settings.terrain_amplitude
		terrain_broad_frequency = settings.terrain_broad_frequency
		terrain_detail_frequency = settings.terrain_detail_frequency
		terrain_ridge_strength = settings.terrain_ridge_strength
	if not ClassDB.class_exists(&"Terrain3D"):
		push_warning("Terrain3D bulunamadı; güvenli düz zemin kullanılacak.")
		return false

	terrain = Terrain3D.new()
	terrain.name = "Terrain3D"
	add_child(terrain)
	terrain.region_size = REGION_SIZE
	terrain.material.world_background = Terrain3DMaterial.NONE
	terrain.material.auto_shader = true
	terrain.material.set_shader_param("auto_slope", 7.5)
	# Terrain3D blends toward the overlay on flat normals and toward the base on slopes.
	terrain.material.set_shader_param("auto_base_texture", 5)
	terrain.material.set_shader_param("auto_overlay_texture", 0)
	terrain.material.set_shader_param("blend_sharpness", 0.76)
	terrain.material.set_shader_param("enable_macro_variation", true)
	terrain.material.set_shader_param("macro_variation1", Color(0.78, 0.86, 0.76, 1.0))
	terrain.material.set_shader_param("macro_variation2", Color(1.04, 0.96, 0.84, 1.0))
	terrain.material.set_shader_param("macro_variation_slope", 0.68)
	terrain.material.set_shader_param("noise1_scale", 0.014)
	terrain.material.set_shader_param("noise1_angle", 0.33)
	terrain.material.set_shader_param("noise1_offset", Vector2(0.17, -0.24))
	terrain.material.set_shader_param("noise2_scale", 0.0065)
	terrain.assets = Terrain3DAssets.new()
	terrain.assets.set_texture(0, _create_pbr_texture_asset(
		"Poly Haven Sparse Grass 2K", GRASS_ALBEDO, GRASS_NORMAL, 0.30,
		Color(0.78, 0.90, 0.72), 0.88, 1.38
	))
	terrain.assets.set_texture(1, _create_pbr_texture_asset(
		"Poly Haven Dirt 2K", DIRT_ALBEDO, DIRT_NORMAL, 0.34,
		Color(1.02, 0.96, 0.88), 0.94, 1.58
	))
	terrain.assets.set_texture(2, _create_pbr_texture_asset(
		"Poly Haven Forest Floor 2K", FOREST_ALBEDO, FOREST_NORMAL, 0.30,
		Color(0.92, 0.96, 0.86), 0.93, 1.52
	))
	terrain.assets.set_texture(3, _create_pbr_texture_asset(
		"Poly Haven Dry Forest Ground 2K", DRY_GROUND_ALBEDO, DRY_GROUND_NORMAL, 0.31,
		Color(1.04, 0.96, 0.78), 0.95, 1.50
	))
	terrain.assets.set_texture(4, _create_pbr_texture_asset(
		"Poly Haven Mud Forest 2K", MUD_ALBEDO, MUD_NORMAL, 0.34,
		Color(0.92, 0.88, 0.82), 0.82, 1.62
	))
	terrain.assets.set_texture(5, _create_pbr_texture_asset(
		"Poly Haven Stony Dirt 2K", STONY_ALBEDO, STONY_NORMAL, 0.32,
		Color(0.92, 0.94, 0.90), 0.96, 1.72
	))
	terrain.assets.set_texture(6, _create_pbr_texture_asset(
		"Poly Haven Grass Path 2K", PATH_ALBEDO, PATH_NORMAL, 0.36,
		Color(1.02, 0.98, 0.88), 0.93, 1.58
	))
	terrain.assets.set_texture(7, _create_pbr_texture_asset(
		"Poly Haven Snow 2K", SNOW_ALBEDO, SNOW_NORMAL, 0.30,
		Color(0.96, 1.00, 1.06), 0.78, 1.42
	))

	var height_map := _create_height_map()
	terrain.data.import_images(
		[height_map, null, null],
		Vector3(-TERRAIN_HALF_SIZE, 0.0, -TERRAIN_HALF_SIZE),
		0.0,
		22.0
	)
	if terrain.data.get_region_count() == 0:
		push_warning("Terrain3D yükseklik haritası alınamadı; düz zemin kullanılacak.")
		terrain.queue_free()
		terrain = null
		return false
	_paint_snow_zone()

	terrain.collision_mode = Terrain3DCollision.FULL_GAME
	# Terrain3D remains visual; the deterministic playable height map below owns Jolt collisions.
	terrain.collision_layer = 0
	terrain.collision_mask = 0
	terrain.collision.update(true)
	height_provider = HEIGHT_PROVIDER_SCRIPT.new()
	height_provider.name = "TerrainHeightProvider"
	add_child(height_provider)
	height_provider.configure(terrain)
	_build_playable_collision()
	enabled = true
	return true


func _paint_snow_zone() -> void:
	match map_profile_id:
		&"shaping_estate":
			snow_zone_center = Vector2(-30.0, -25.0)
			snow_zone_radius = 14.0
		&"forest_path":
			snow_zone_center = Vector2(-31.0, -20.0)
			snow_zone_radius = 18.0
		&"giant_garden":
			snow_zone_center = Vector2(-32.0, -24.0)
			snow_zone_radius = 15.0
		_:
			snow_zone_center = Vector2(-34.0, -28.0)
			snow_zone_radius = 12.0
	var edge_noise := FastNoiseLite.new()
	edge_noise.seed = terrain_seed + 77191
	edge_noise.frequency = 0.11
	var extent := ceili(snow_zone_radius + 5.0)
	for z in range(floori(snow_zone_center.y) - extent, ceili(snow_zone_center.y) + extent + 1):
		for x in range(floori(snow_zone_center.x) - extent, ceili(snow_zone_center.x) + extent + 1):
			var point := Vector2(float(x), float(z))
			var noisy_radius := snow_zone_radius + edge_noise.get_noise_2d(x, z) * 2.8
			var distance := point.distance_to(snow_zone_center)
			if distance > noisy_radius + 3.5:
				continue
			var blend := 1.0 - smoothstep(noisy_radius - 3.5, noisy_radius + 3.5, distance)
			var world_position := Vector3(float(x), 0.0, float(z))
			terrain.data.set_control_auto(world_position, false)
			terrain.data.set_control_overlay_id(world_position, 7)
			terrain.data.set_control_blend(world_position, clampi(int(round(blend * 255.0)), 0, 255))
	terrain.data.update_maps(Terrain3DRegion.TYPE_CONTROL, true, true)


func get_height(world_position: Vector3) -> float:
	return height_provider.get_height(world_position) if height_provider != null else 0.0


func _build_playable_collision() -> void:
	playable_collision = StaticBody3D.new()
	playable_collision.name = "PlayableTerrainJoltCollision"
	playable_collision.collision_layer = 1
	playable_collision.collision_mask = 1
	var step := 2.0
	# Offset the grid so common spawn coordinates never sit exactly on a triangle seam.
	var minimum := Vector2(-51.3, -45.7)
	var maximum := Vector2(51.3, 45.7)
	var columns := int((maximum.x - minimum.x) / step)
	var rows := int((maximum.y - minimum.y) / step)
	var faces := PackedVector3Array()
	for row in range(rows):
		for column in range(columns):
			var x0 := minimum.x + float(column) * step
			var z0 := minimum.y + float(row) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var top_left := Vector3(x0, height_provider.get_height(Vector3(x0, 0.0, z0)), z0)
			var top_right := Vector3(x1, height_provider.get_height(Vector3(x1, 0.0, z0)), z0)
			var bottom_left := Vector3(x0, height_provider.get_height(Vector3(x0, 0.0, z1)), z1)
			var bottom_right := Vector3(x1, height_provider.get_height(Vector3(x1, 0.0, z1)), z1)
			faces.append_array(PackedVector3Array([
				top_left, bottom_left, top_right,
				top_right, bottom_left, bottom_right,
			]))
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = shape
	playable_collision.add_child(collision_shape)
	add_child(playable_collision)


func _create_pbr_texture_asset(
	asset_name: String,
	albedo: Texture2D,
	normal: Texture2D,
	uv_scale: float,
	tint: Color,
	roughness_value: float,
	normal_strength: float
) -> Terrain3DTextureAsset:
	var asset := Terrain3DTextureAsset.new()
	asset.name = asset_name
	asset.albedo_texture = albedo
	asset.normal_texture = normal
	asset.albedo_color = tint
	asset.roughness = roughness_value
	# Strong close-up relief fades naturally through imported mipmaps.
	asset.normal_depth = normal_strength
	asset.uv_scale = uv_scale
	# Terrain3D detiling prevents repeated blocks in the distant macro color field.
	asset.detiling_rotation = 0.31
	return asset


func _create_height_map() -> Image:
	var image := Image.create_empty(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RF)
	var broad_noise := FastNoiseLite.new()
	broad_noise.seed = terrain_seed
	broad_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	broad_noise.frequency = terrain_broad_frequency
	broad_noise.fractal_octaves = 5
	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = terrain_seed + 333646
	detail_noise.frequency = terrain_detail_frequency
	var ridge_noise := FastNoiseLite.new()
	ridge_noise.seed = terrain_seed - 286565
	ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ridge_noise.frequency = 0.009
	ridge_noise.fractal_octaves = 4
	for z in MAP_SIZE:
		for x in MAP_SIZE:
			var world_x := float(x) - TERRAIN_HALF_SIZE
			var world_z := float(z) - TERRAIN_HALF_SIZE
			# Keep the authored garden level, then blend into a clearly rolling horizon.
			var outside_x := maxf(absf(world_x) - 52.0, 0.0)
			var outside_z := maxf(absf(world_z) - 46.0, 0.0)
			var outside_distance := Vector2(outside_x, outside_z).length()
			var outer_blend := smoothstep(0.0, 28.0, outside_distance)
			var broad := broad_noise.get_noise_2d(world_x, world_z) * 0.42
			var detail := detail_noise.get_noise_2d(world_x, world_z) * 0.12
			var folded_ridge := absf(ridge_noise.get_noise_2d(world_x, world_z)) * 0.42
			var distant_lift := smoothstep(24.0, 150.0, outside_distance) * 0.30
			var local_ridge := absf(ridge_noise.get_noise_2d(world_x, world_z)) - 0.34
			var local_shape := broad_noise.get_noise_2d(world_x, world_z) * 0.72 + detail_noise.get_noise_2d(world_x, world_z) * 0.28
			local_shape += local_ridge * terrain_ridge_strength
			match terrain_style:
				&"terraced":
					var terrace_level := roundf(local_shape * 5.0) / 5.0
					local_shape = lerpf(local_shape, terrace_level, 0.48)
				&"hummocks":
					local_shape = absf(local_shape) * 0.82 - 0.18
			var local_height := local_shape * terrain_amplitude
			var horizon_height := broad + detail + folded_ridge + distant_lift
			var height_value := lerpf(local_height, horizon_height, outer_blend)
			image.set_pixel(x, z, Color(height_value, 0.0, 0.0, 1.0))
	return image


func _create_texture_asset(asset_name: String, dark: Color, light: Color, roughness: float) -> Terrain3DTextureAsset:
	var size := 256
	var noise := FastNoiseLite.new()
	noise.seed = asset_name.hash()
	noise.frequency = 0.035
	var albedo_image := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	var normal_image := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var value := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var color := dark.lerp(light, value)
			color.a = value
			albedo_image.set_pixel(x, y, color)
			normal_image.set_pixel(x, y, Color(0.5, 0.5, 1.0, roughness))
	albedo_image.generate_mipmaps()
	normal_image.generate_mipmaps()
	var asset := Terrain3DTextureAsset.new()
	asset.name = asset_name
	asset.albedo_texture = ImageTexture.create_from_image(albedo_image)
	asset.normal_texture = ImageTexture.create_from_image(normal_image)
	asset.uv_scale = 0.14
	asset.detiling_rotation = 0.12
	return asset
