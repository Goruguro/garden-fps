class_name GroundDetailScatter
extends Node3D

const FIELD_MIN := Vector2(-49.0, -43.0)
const FIELD_MAX := Vector2(49.0, 43.0)
const DETAIL_COUNT := 1450
const PEBBLE_PATHS := [
	"res://assets/third_party/quaternius_stylized_nature/Pebble_Round_1.gltf",
	"res://assets/third_party/quaternius_stylized_nature/Pebble_Round_2.gltf",
	"res://assets/third_party/quaternius_stylized_nature/Pebble_Round_3.gltf",
	"res://assets/third_party/quaternius_stylized_nature/Pebble_Round_4.gltf",
]

var height_provider: Node
var exclusions: Array[Dictionary] = []
var instance_count := 0
var multimesh_count := 0


func build(provider: Node, blocked_zones: Array, seed_value: int) -> void:
	height_provider = provider
	exclusions.clear()
	for zone_value: Variant in blocked_zones:
		exclusions.append(Dictionary(zone_value).duplicate(true))
	var buckets: Array = []
	for _index in range(PEBBLE_PATHS.size() + 2):
		buckets.append([])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 54091
	var patch_noise := FastNoiseLite.new()
	patch_noise.seed = seed_value + 8127
	patch_noise.frequency = 0.037
	patch_noise.fractal_octaves = 3
	var attempts := 0
	while instance_count < DETAIL_COUNT and attempts < DETAIL_COUNT * 5:
		attempts += 1
		var position := Vector3(
			rng.randf_range(FIELD_MIN.x, FIELD_MAX.x),
			0.0,
			rng.randf_range(FIELD_MIN.y, FIELD_MAX.y)
		)
		if _is_excluded(position):
			continue
		var patch := patch_noise.get_noise_2d(position.x, position.z) * 0.5 + 0.5
		if rng.randf() > lerpf(0.22, 0.88, smoothstep(0.12, 0.9, patch)):
			continue
		position.y = height_provider.get_height(position) + 0.012 if height_provider != null else 0.012
		var kind := rng.randi_range(0, PEBBLE_PATHS.size() + 1)
		var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		if kind < PEBBLE_PATHS.size():
			var scale_value := rng.randf_range(0.16, 0.42)
			basis = basis.scaled(Vector3(scale_value * rng.randf_range(0.75, 1.35), scale_value * rng.randf_range(0.55, 1.0), scale_value))
		elif kind == PEBBLE_PATHS.size():
			var clod_scale := rng.randf_range(0.075, 0.18)
			basis = basis.scaled(Vector3(clod_scale * rng.randf_range(1.0, 1.8), clod_scale * rng.randf_range(0.35, 0.7), clod_scale))
		else:
			var twig_width := rng.randf_range(0.025, 0.045)
			var twig_length := rng.randf_range(0.18, 0.48)
			var horizontal := Basis(
				Vector3(twig_width, 0.0, 0.0),
				Vector3(0.0, 0.0, twig_length),
				Vector3(0.0, -twig_width, 0.0)
			)
			basis = Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU)) * horizontal
		(buckets[kind] as Array).append(Transform3D(basis, position))
		instance_count += 1
	for index in range(PEBBLE_PATHS.size()):
		_add_multimesh("GroundPebbles%d" % index, _load_mesh(PEBBLE_PATHS[index]), buckets[index])
	_add_multimesh("GroundSoilClods", _create_clod_mesh(), buckets[PEBBLE_PATHS.size()])
	_add_multimesh("GroundTwigs", _create_twig_mesh(), buckets[PEBBLE_PATHS.size() + 1])


func set_quality_profile(profile: int) -> void:
	var ratio: float = [0.34, 0.62, 0.86, 1.0][clampi(profile, 0, 3)]
	for child in get_children():
		var instance := child as MultiMeshInstance3D
		if instance != null and instance.multimesh != null:
			instance.multimesh.visible_instance_count = maxi(1, int(round(instance.multimesh.instance_count * ratio)))


func _add_multimesh(node_name: String, mesh: Mesh, transforms: Array) -> void:
	if mesh == null or transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index] as Transform3D)
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.visibility_range_end = 46.0
	instance.visibility_range_end_margin = 14.0
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.custom_aabb = AABB(Vector3(FIELD_MIN.x, -1.0, FIELD_MIN.y), Vector3(FIELD_MAX.x - FIELD_MIN.x, 5.0, FIELD_MAX.y - FIELD_MIN.y))
	add_child(instance)
	multimesh_count += 1


func _load_mesh(path: String) -> Mesh:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var root := packed.instantiate()
	var pending: Array[Node] = [root]
	var result: Mesh
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D:
			result = (current as MeshInstance3D).mesh
			break
		for child in current.get_children():
			pending.append(child)
	root.free()
	return result


func _create_clod_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 7
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("584333")
	material.roughness = 1.0
	mesh.material = material
	return mesh


func _create_twig_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.25
	mesh.height = 2.0
	mesh.radial_segments = 5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("493428")
	material.roughness = 0.96
	mesh.material = material
	return mesh


func _is_excluded(position: Vector3) -> bool:
	var point := Vector2(position.x, position.z)
	for zone in exclusions:
		var radius := float(zone.get("radius", 0.0)) + 0.35
		match StringName(zone.get("shape", &"circle")):
			&"circle":
				var center: Vector2 = zone.get("center", Vector2.ZERO)
				if point.distance_squared_to(center) <= radius * radius:
					return true
			&"segment":
				var start: Vector2 = zone.get("start", Vector2.ZERO)
				var end: Vector2 = zone.get("end", Vector2.ZERO)
				var segment := end - start
				var length_squared := segment.length_squared()
				var t := clampf((point - start).dot(segment) / maxf(length_squared, 0.0001), 0.0, 1.0)
				if point.distance_squared_to(start + segment * t) <= radius * radius:
					return true
	return false
