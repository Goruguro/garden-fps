class_name LodFoliageScatter
extends Node3D

const COLLISION_FACTORY := preload("res://scripts/physics/garden_collision_factory.gd")

const FLO_ROOT := "res://assets/third_party/flo_bit_nature/"
const KENNEY_ROOT := "res://assets/third_party/kenney_nature_full/"
const QUATERNIUS_ROOT := "res://assets/third_party/quaternius_stylized_nature/"
const TREE_ASSETS := [
	FLO_ROOT + "common_tree_1.glb", FLO_ROOT + "common_tree_2.glb", FLO_ROOT + "common_tree_3.glb",
	FLO_ROOT + "pine_tree_1.glb", FLO_ROOT + "pine_tree_2.glb", FLO_ROOT + "pine_tree_3.glb",
	KENNEY_ROOT + "tree_default.glb", KENNEY_ROOT + "tree_detailed.glb", KENNEY_ROOT + "tree_fat.glb",
	KENNEY_ROOT + "tree_oak.glb", KENNEY_ROOT + "tree_cone.glb",
	QUATERNIUS_ROOT + "CommonTree_1.gltf", QUATERNIUS_ROOT + "CommonTree_2.gltf",
	QUATERNIUS_ROOT + "CommonTree_3.gltf", QUATERNIUS_ROOT + "CommonTree_4.gltf",
	QUATERNIUS_ROOT + "TwistedTree_1.gltf", QUATERNIUS_ROOT + "TwistedTree_3.gltf",
	QUATERNIUS_ROOT + "Pine_1.gltf", QUATERNIUS_ROOT + "Pine_3.gltf",
]
const ESTATE_TREE_ASSETS := [
	FLO_ROOT + "common_tree_1.glb", FLO_ROOT + "common_tree_2.glb", FLO_ROOT + "common_tree_3.glb",
	KENNEY_ROOT + "tree_default.glb", KENNEY_ROOT + "tree_detailed.glb",
	QUATERNIUS_ROOT + "CommonTree_1.gltf", QUATERNIUS_ROOT + "CommonTree_2.gltf",
]
const FOREST_TREE_ASSETS := [
	FLO_ROOT + "pine_tree_1.glb", FLO_ROOT + "pine_tree_2.glb", FLO_ROOT + "pine_tree_3.glb",
	FLO_ROOT + "common_tree_1.glb", FLO_ROOT + "common_tree_2.glb", FLO_ROOT + "dead_tree_1.glb",
	KENNEY_ROOT + "tree_cone_dark.glb", KENNEY_ROOT + "tree_pineRoundA.glb",
	QUATERNIUS_ROOT + "Pine_1.gltf", QUATERNIUS_ROOT + "Pine_2.gltf", QUATERNIUS_ROOT + "Pine_4.gltf",
	QUATERNIUS_ROOT + "TwistedTree_2.gltf", QUATERNIUS_ROOT + "DeadTree_2.gltf",
]
const UNDERSTORY_ASSETS := [
	FLO_ROOT + "bush_1.glb", FLO_ROOT + "bush_3.glb", FLO_ROOT + "bush_5.glb",
	FLO_ROOT + "bush_berries_1.glb", FLO_ROOT + "plant_1.glb", FLO_ROOT + "plant_2.glb",
	FLO_ROOT + "flower_1.glb", FLO_ROOT + "flower_2.glb", FLO_ROOT + "mushroom_group_1.glb",
	KENNEY_ROOT + "plant_bushDetailed.glb", KENNEY_ROOT + "plant_bushLarge.glb",
	KENNEY_ROOT + "flower_purpleA.glb", KENNEY_ROOT + "flower_redB.glb", KENNEY_ROOT + "flower_yellowC.glb",
	KENNEY_ROOT + "grass_leafsLarge.glb", KENNEY_ROOT + "mushroom_redGroup.glb",
	QUATERNIUS_ROOT + "Bush_Common.gltf", QUATERNIUS_ROOT + "Bush_Common_Flowers.gltf",
	QUATERNIUS_ROOT + "Clover_1.gltf", QUATERNIUS_ROOT + "Clover_2.gltf", QUATERNIUS_ROOT + "Fern_1.gltf",
	QUATERNIUS_ROOT + "Flower_3_Group.gltf", QUATERNIUS_ROOT + "Flower_4_Group.gltf",
	QUATERNIUS_ROOT + "Plant_1.gltf", QUATERNIUS_ROOT + "Plant_7.gltf",
	QUATERNIUS_ROOT + "Mushroom_Common.gltf", QUATERNIUS_ROOT + "Mushroom_Laetiporus.gltf",
]

var height_provider: Node
var level_id := &"home_garden"
var generation_profile: MapGenerationProfile
var source_tree_count := 0
var source_plant_count := 0
var far_proxy_count := 0
var medium_proxy_count := 0
var imported_mesh_count := 0
var generated_lod_mesh_count := 0
var tree_collision_count := 0
var source_cache: Dictionary = {}
var tree_transforms: Array[Transform3D] = []
var map_exclusions: Array[Dictionary] = []
var asset_usage: Dictionary = {}


func build(provider: Node, active_level: StringName, exclusions: Array = [], settings: MapGenerationProfile = null) -> void:
	height_provider = provider
	level_id = active_level if WorldLevelCatalog.is_valid(active_level) else &"home_garden"
	generation_profile = settings if settings != null else WorldLevelCatalog.get_generation_profile(level_id)
	source_tree_count = 0
	source_plant_count = 0
	far_proxy_count = 0
	medium_proxy_count = 0
	imported_mesh_count = 0
	generated_lod_mesh_count = 0
	tree_collision_count = 0
	tree_transforms.clear()
	asset_usage.clear()
	map_exclusions.clear()
	for exclusion_value: Variant in exclusions:
		map_exclusions.append(Dictionary(exclusion_value).duplicate(true))
	var rng := RandomNumberGenerator.new()
	rng.seed = generation_profile.seed
	_scatter_trees(rng, generation_profile)
	_scatter_understory(rng, generation_profile)
	_scatter_outer_ring(rng, generation_profile)
	# The old spherical canopy proxies read as giant translucent circles above trees.
	# Imported low-poly sources are already inexpensive enough to remain visible at distance.


func set_quality_profile(profile: int) -> void:
	var profile_index := clampi(profile, 0, 3)
	var source_distance: float = [72.0, 96.0, 128.0, 158.0][profile_index]
	var plant_distance: float = [32.0, 44.0, 58.0, 72.0][profile_index]
	var proxy_distance: float = [98.0, 126.0, 158.0, 195.0][profile_index]
	for node in get_tree().get_nodes_in_group("lod_foliage_source"):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or not is_ancestor_of(mesh_instance):
			continue
		var is_tree := bool(mesh_instance.get_meta("is_tree", false))
		mesh_instance.visibility_range_end = source_distance if is_tree else plant_distance
		mesh_instance.visibility_range_end_margin = 20.0 if is_tree else 14.0
		mesh_instance.lod_bias = [0.45, 0.7, 1.0, 1.35][profile_index]
	for node in get_tree().get_nodes_in_group("lod_foliage_proxy"):
		var proxy := node as GeometryInstance3D
		if proxy == null or not is_ancestor_of(proxy):
			continue
		if StringName(proxy.get_meta("lod_level", &"far")) == &"medium":
			proxy.visibility_range_begin = maxf(20.0, source_distance - 30.0)
			proxy.visibility_range_end = minf(proxy_distance, source_distance + 54.0)
			proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if profile_index >= 2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			proxy.visibility_range_begin = maxf(38.0, source_distance + 8.0)
			proxy.visibility_range_end = proxy_distance


func _scatter_trees(rng: RandomNumberGenerator, profile: MapGenerationProfile) -> void:
	var target_count := profile.tree_count
	var scale_range := profile.tree_scale_range
	var placed_positions: Array[Vector3] = []
	var attempts := 0
	while source_tree_count < target_count and attempts < target_count * 35:
		attempts += 1
		var candidate := Vector3(rng.randf_range(-47.0, 47.0), 0.0, rng.randf_range(-40.0, 40.0))
		if not _is_tree_allowed(candidate) or not _is_separated(candidate, placed_positions, profile.tree_spacing):
			continue
		var asset_name := _pick_weighted_asset(_tree_palette(), rng, true)
		var scale_value := rng.randf_range(scale_range.x, scale_range.y)
		var transform := _spawn_source(asset_name, candidate, _tree_scale(scale_value, rng, profile), rng.randf_range(0.0, TAU), true, false, rng)
		if transform == Transform3D():
			continue
		placed_positions.append(candidate)
		tree_transforms.append(transform)
		asset_usage[asset_name] = int(asset_usage.get(asset_name, 0)) + 1
		source_tree_count += 1


func _scatter_understory(rng: RandomNumberGenerator, profile: MapGenerationProfile) -> void:
	var target_count := profile.understory_count
	var scale_range := profile.plant_scale_range
	var attempts := 0
	while source_plant_count < target_count and attempts < target_count * 14:
		attempts += 1
		var candidate := Vector3(rng.randf_range(-45.0, 45.0), 0.0, rng.randf_range(-38.0, 38.0))
		if not _is_plant_allowed(candidate):
			continue
		var patch := sin(candidate.x * 0.13 + sin(candidate.z * 0.07) * 2.1) * 0.5 + 0.5
		if rng.randf() > lerpf(0.3, 0.95, patch):
			continue
		var asset_name := _pick_weighted_asset(UNDERSTORY_ASSETS, rng, false)
		var scale_value := rng.randf_range(scale_range.x, scale_range.y)
		if _spawn_source(asset_name, candidate, _plant_scale(scale_value, rng, profile), rng.randf_range(0.0, TAU), false, false, rng) != Transform3D():
			asset_usage[asset_name] = int(asset_usage.get(asset_name, 0)) + 1
			source_plant_count += 1


func _scatter_outer_ring(rng: RandomNumberGenerator, profile: MapGenerationProfile) -> void:
	var outer_trees := 0
	var outer_plants := 0
	var placed_positions: Array[Vector3] = []
	var tree_attempts := 0
	while outer_trees < profile.outer_tree_count and tree_attempts < profile.outer_tree_count * 30:
		tree_attempts += 1
		var candidate := _random_annulus_position(rng, profile.outer_ring_start, profile.outer_ring_end)
		if not _is_separated(candidate, placed_positions, profile.tree_spacing * 0.82):
			continue
		var asset_path := _pick_weighted_asset(_tree_palette(), rng, true)
		var scale_value := rng.randf_range(profile.tree_scale_range.x, profile.tree_scale_range.y)
		var transform := _spawn_source(asset_path, candidate, _tree_scale(scale_value, rng, profile), rng.randf_range(0.0, TAU), true, true, rng)
		if transform == Transform3D():
			continue
		placed_positions.append(candidate)
		tree_transforms.append(transform)
		asset_usage[asset_path.get_file()] = int(asset_usage.get(asset_path.get_file(), 0)) + 1
		outer_trees += 1
		source_tree_count += 1
	var plant_attempts := 0
	while outer_plants < profile.outer_plant_count and plant_attempts < profile.outer_plant_count * 12:
		plant_attempts += 1
		var candidate := _random_annulus_position(rng, profile.outer_ring_start, profile.outer_ring_end)
		var patch := sin(candidate.x * 0.082 + sin(candidate.z * 0.041) * 3.0) * 0.5 + 0.5
		if rng.randf() > lerpf(0.22, 0.94, patch):
			continue
		var asset_path := _pick_weighted_asset(UNDERSTORY_ASSETS, rng, false)
		var scale_value := rng.randf_range(profile.plant_scale_range.x, profile.plant_scale_range.y)
		if _spawn_source(asset_path, candidate, _plant_scale(scale_value, rng, profile), rng.randf_range(0.0, TAU), false, true, rng) != Transform3D():
			asset_usage[asset_path.get_file()] = int(asset_usage.get(asset_path.get_file(), 0)) + 1
			outer_plants += 1
			source_plant_count += 1


func _random_annulus_position(rng: RandomNumberGenerator, minimum_radius: float, maximum_radius: float) -> Vector3:
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf_range(minimum_radius * minimum_radius, maximum_radius * maximum_radius))
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func _tree_scale(base_scale: float, rng: RandomNumberGenerator, profile: MapGenerationProfile) -> Vector3:
	var width := base_scale * rng.randf_range(profile.tree_width_multiplier_range.x, profile.tree_width_multiplier_range.y)
	var height := base_scale * rng.randf_range(profile.tree_height_multiplier_range.x, profile.tree_height_multiplier_range.y)
	return Vector3(width * (-1.0 if rng.randf() < profile.tree_mirror_chance else 1.0), height, width * rng.randf_range(0.86, 1.14))


func _plant_scale(base_scale: float, rng: RandomNumberGenerator, profile: MapGenerationProfile) -> Vector3:
	return Vector3(base_scale * rng.randf_range(0.72, 1.32) * (-1.0 if rng.randf() < profile.plant_mirror_chance else 1.0), base_scale * rng.randf_range(0.78, 1.3), base_scale * rng.randf_range(0.72, 1.32))


func _pick_weighted_asset(assets: Array, rng: RandomNumberGenerator, is_tree: bool) -> String:
	var total_weight := 0.0
	for asset_value: Variant in assets:
		var asset_name := str(asset_value).get_file()
		total_weight += generation_profile.get_tree_weight(asset_name) if is_tree else generation_profile.get_plant_weight(asset_name)
	if total_weight <= 0.0:
		return str(assets[0])
	var ticket := rng.randf() * total_weight
	for asset_value: Variant in assets:
		var asset_name := str(asset_value).get_file()
		ticket -= generation_profile.get_tree_weight(asset_name) if is_tree else generation_profile.get_plant_weight(asset_name)
		if ticket <= 0.0:
			return str(asset_value)
	return str(assets.back())


func _spawn_source(asset_path: String, world_position: Vector3, scale_value: Vector3, yaw: float, is_tree: bool, is_outer: bool, rng: RandomNumberGenerator) -> Transform3D:
	var packed := _load_source(asset_path)
	if packed == null:
		return Transform3D()
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return Transform3D()
	instance.name = "Foliage_%s" % asset_path.get_file().get_basename()
	add_child(instance)
	instance.scale = scale_value
	instance.rotation.y = yaw
	var tilt_limit := deg_to_rad(generation_profile.tree_max_tilt_degrees if is_tree else generation_profile.plant_max_tilt_degrees)
	instance.rotation.x = rng.randf_range(-tilt_limit, tilt_limit)
	instance.rotation.z = rng.randf_range(-tilt_limit, tilt_limit)
	instance.global_position = height_provider.project(world_position, 0.01) if height_provider != null else world_position
	if is_tree:
		var trunk_height := maxf(2.4, absf(scale_value.y) * 3.8)
		var trunk_radius := clampf(absf(scale_value.x) * 0.28, 0.22, 0.72)
		var trunk_position := instance.global_position + Vector3.UP * trunk_height * 0.5
		var trunk := COLLISION_FACTORY.add_cylinder(self, "FoliageTreeHitbox_%d" % tree_collision_count, trunk_position, trunk_radius, trunk_height)
		trunk.rotation.y = yaw
		trunk.set_meta("outer_tree", is_outer)
		tree_collision_count += 1
	var mesh_nodes := _find_mesh_instances(instance)
	for mesh_instance in mesh_nodes:
		mesh_instance.add_to_group("lod_foliage_source")
		mesh_instance.set_meta("is_tree", is_tree)
		mesh_instance.set_meta("is_outer", is_outer)
		mesh_instance.visibility_range_end = (128.0 if is_tree else 34.0) if is_outer else (118.0 if is_tree else 46.0)
		mesh_instance.visibility_range_end_margin = 20.0 if is_tree else 14.0
		mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if is_outer else (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if is_tree else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		mesh_instance.lod_bias = 1.0
		imported_mesh_count += 1
		if mesh_instance.mesh != null:
			generated_lod_mesh_count += 1
	return instance.global_transform


func _build_far_tree_proxies() -> void:
	if tree_transforms.is_empty():
		return
	_add_tree_proxy_pair(&"medium", _create_medium_trunk_mesh(), _create_medium_canopy_mesh(), 34.0, 122.0, true)
	_add_tree_proxy_pair(&"far", _create_proxy_trunk_mesh(), _create_proxy_canopy_mesh(), 68.0, 166.0, false)
	medium_proxy_count = tree_transforms.size()
	far_proxy_count = tree_transforms.size()


func _add_tree_proxy_pair(level_name: StringName, trunk_mesh: Mesh, canopy_mesh: Mesh, range_begin: float, range_end: float, shadows: bool) -> void:
	var trunk_multimesh := MultiMesh.new()
	trunk_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	trunk_multimesh.mesh = trunk_mesh
	trunk_multimesh.instance_count = tree_transforms.size()
	var canopy_multimesh := MultiMesh.new()
	canopy_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	canopy_multimesh.mesh = canopy_mesh
	canopy_multimesh.instance_count = tree_transforms.size()
	for index in range(tree_transforms.size()):
		var source_transform := tree_transforms[index]
		trunk_multimesh.set_instance_transform(index, source_transform * Transform3D(Basis(), Vector3(0.0, 2.3, 0.0)))
		canopy_multimesh.set_instance_transform(index, source_transform * Transform3D(Basis(), Vector3(0.0, 5.9, 0.0)))
	for data in [["%sTreeTrunks" % String(level_name).capitalize(), trunk_multimesh], ["%sTreeCanopies" % String(level_name).capitalize(), canopy_multimesh]]:
		var instance := MultiMeshInstance3D.new()
		instance.name = data[0]
		instance.multimesh = data[1]
		instance.visibility_range_begin = range_begin
		instance.visibility_range_end = range_end
		instance.visibility_range_begin_margin = 24.0
		instance.visibility_range_end_margin = 30.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.set_meta("lod_level", level_name)
		instance.add_to_group("lod_foliage_proxy")
		add_child(instance)


func _load_source(asset_path: String) -> PackedScene:
	if source_cache.has(asset_path):
		return source_cache[asset_path] as PackedScene
	var packed := load(asset_path) as PackedScene
	source_cache[asset_path] = packed
	return packed


func _tree_palette() -> Array:
	match level_id:
		&"shaping_estate":
			return ESTATE_TREE_ASSETS
		&"forest_path":
			return FOREST_TREE_ASSETS
		_:
			return TREE_ASSETS


func _find_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D:
			result.append(current as MeshInstance3D)
		for child in current.get_children():
			pending.append(child)
	return result


func _is_tree_allowed(position_value: Vector3) -> bool:
	if _is_map_excluded(position_value, 1.6):
		return false
	if level_id != &"home_garden":
		return absf(position_value.x) > 4.0 or position_value.z < -12.0
	var flat := Vector2(position_value.x, position_value.z)
	if absf(position_value.x) < 4.2 and position_value.z > -22.0:
		return false
	if flat.distance_to(Vector2(18.0, 18.0)) < 13.0 or flat.distance_to(Vector2(-12.0, -10.0)) < 10.0:
		return false
	if flat.distance_to(Vector2(15.0, -14.0)) < 8.0:
		return false
	return true


func _is_plant_allowed(position_value: Vector3) -> bool:
	if _is_map_excluded(position_value, 0.35):
		return false
	if level_id != &"home_garden":
		return absf(position_value.x) > 2.8 or position_value.z < -17.0
	var flat := Vector2(position_value.x, position_value.z)
	if absf(position_value.x) < 2.8 and position_value.z > -20.0:
		return false
	if flat.distance_to(Vector2(18.0, 18.0)) < 10.8 or flat.distance_to(Vector2(-12.0, -10.0)) < 7.8:
		return false
	return flat.distance_to(Vector2(15.0, -14.0)) > 6.3


func _is_map_excluded(position_value: Vector3, margin: float) -> bool:
	var point := Vector2(position_value.x, position_value.z)
	for zone in map_exclusions:
		var radius := float(zone.get("radius", 0.0)) + margin
		match StringName(zone.get("shape", &"circle")):
			&"circle":
				var center: Vector2 = zone.get("center", Vector2.ZERO)
				if point.distance_squared_to(center) <= radius * radius:
					return true
			&"segment":
				var start: Vector2 = zone.get("start", Vector2.ZERO)
				var end: Vector2 = zone.get("end", Vector2.ZERO)
				if _distance_to_segment_squared(point, start, end) <= radius * radius:
					return true
	return false


func _distance_to_segment_squared(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_squared_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(start + segment * t)


func _is_separated(candidate: Vector3, placed: Array[Vector3], minimum_distance: float) -> bool:
	for other in placed:
		if Vector2(candidate.x, candidate.z).distance_squared_to(Vector2(other.x, other.z)) < minimum_distance * minimum_distance:
			return false
	return true


func _create_proxy_trunk_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.34
	mesh.bottom_radius = 0.48
	mesh.height = 4.6
	mesh.radial_segments = 5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("65452f")
	material.roughness = 1.0
	mesh.material = material
	return mesh


func _create_proxy_canopy_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 2.2
	mesh.height = 4.4
	mesh.radial_segments = 7
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("416c3b")
	material.roughness = 1.0
	mesh.material = material
	return mesh


func _create_medium_trunk_mesh() -> CylinderMesh:
	var mesh := _create_proxy_trunk_mesh()
	mesh.radial_segments = 9
	return mesh


func _create_medium_canopy_mesh() -> SphereMesh:
	var mesh := _create_proxy_canopy_mesh()
	mesh.radial_segments = 12
	mesh.rings = 7
	return mesh
