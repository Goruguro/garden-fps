class_name OuterBiomeRing
extends Node3D

const SECTOR_COUNT := 12

var height_provider: Node
var generation_profile: MapGenerationProfile
var sector_data: Array[Dictionary] = []
var total_clusters := 0


func build(provider: Node, settings: MapGenerationProfile) -> void:
	height_provider = provider
	generation_profile = settings
	total_clusters = 0
	sector_data.clear()
	if generation_profile == null or generation_profile.outer_grass_count <= 0:
		return
	for sector_index in range(SECTOR_COUNT):
		_build_sector(sector_index)
	set_quality_profile(2)


func set_quality_profile(profile: int) -> void:
	var profile_index := clampi(profile, 0, 3)
	var density_ratio: float = [0.28, 0.52, 0.78, 1.0][profile_index]
	var medium_end: float = [22.0, 29.0, 38.0, 48.0][profile_index]
	var far_end: float = [90.0, 125.0, 165.0, 205.0][profile_index]
	for sector: Dictionary in sector_data:
		var medium_mesh := sector["medium_mesh"] as MultiMesh
		var low_mesh := sector["low_mesh"] as MultiMesh
		medium_mesh.visible_instance_count = maxi(1, int(medium_mesh.instance_count * density_ratio))
		low_mesh.visible_instance_count = maxi(1, int(low_mesh.instance_count * density_ratio * 0.62))
		var medium_instance := sector["medium_instance"] as MultiMeshInstance3D
		var low_instance := sector["low_instance"] as MultiMeshInstance3D
		medium_instance.visibility_range_end = medium_end
		low_instance.visibility_range_begin = maxf(14.0, medium_end - 10.0)
		low_instance.visibility_range_end = far_end


func _build_sector(sector_index: int) -> void:
	var count := generation_profile.outer_grass_count / SECTOR_COUNT
	if sector_index < generation_profile.outer_grass_count % SECTOR_COUNT:
		count += 1
	if count <= 0:
		return
	var middle_angle := (float(sector_index) + 0.5) * TAU / float(SECTOR_COUNT)
	var middle_radius := (generation_profile.outer_ring_start + generation_profile.outer_ring_end) * 0.5
	var sector_origin := Vector3(cos(middle_angle) * middle_radius, 0.0, sin(middle_angle) * middle_radius)
	var rng := RandomNumberGenerator.new()
	rng.seed = generation_profile.seed + sector_index * 193939
	var transforms: Array[Transform3D] = []
	var custom_data := PackedColorArray()
	var half_sector := TAU / float(SECTOR_COUNT) * 0.5
	for index in range(count):
		var angle := middle_angle + rng.randf_range(-half_sector, half_sector)
		var minimum_squared := generation_profile.outer_ring_start * generation_profile.outer_ring_start
		var maximum_squared := generation_profile.outer_ring_end * generation_profile.outer_ring_end
		var radius := sqrt(rng.randf_range(minimum_squared, maximum_squared))
		var position_value := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		position_value = height_provider.project(position_value, 0.015) if height_provider != null else position_value
		var patch := sin(position_value.x * 0.045 + sin(position_value.z * 0.031) * 2.4) * 0.5 + 0.5
		var base_height := lerpf(generation_profile.outer_grass_height_range.x, generation_profile.outer_grass_height_range.y, smoothstep(0.08, 0.92, patch))
		var mirrored := -1.0 if rng.randf() < generation_profile.grass_mirror_chance else 1.0
		var scale_value := Vector3(rng.randf_range(0.72, 1.36) * mirrored, base_height * rng.randf_range(0.86, 1.16), rng.randf_range(0.72, 1.36))
		var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(scale_value)
		transforms.append(Transform3D(basis, position_value - sector_origin))
		custom_data.append(Color(0.0, rng.randf(), rng.randf(), rng.randf()))
	var material := GrassVisualFactory.create_grass_material(Color("315f2b"), Color("78a947"))
	var instances: Array[MultiMeshInstance3D] = []
	var meshes: Array[MultiMesh] = []
	for lod_level in [GrassVisualFactory.LOD_MEDIUM, GrassVisualFactory.LOD_LOW]:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.mesh = GrassVisualFactory.get_cluster_mesh(lod_level)
		multimesh.instance_count = transforms.size()
		for index in range(transforms.size()):
			multimesh.set_instance_transform(index, transforms[index])
			multimesh.set_instance_custom_data(index, custom_data[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "OuterGrass_%02d_LOD%d" % [sector_index, lod_level]
		instance.position = sector_origin
		instance.multimesh = multimesh
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		instance.visibility_range_end_margin = 9.0
		instance.custom_aabb = AABB(Vector3(-75.0, -2.0, -75.0), Vector3(150.0, 8.0, 150.0))
		add_child(instance)
		meshes.append(multimesh)
		instances.append(instance)
	sector_data.append({
		"medium_mesh": meshes[0], "low_mesh": meshes[1],
		"medium_instance": instances[0], "low_instance": instances[1]
	})
	total_clusters += transforms.size()
