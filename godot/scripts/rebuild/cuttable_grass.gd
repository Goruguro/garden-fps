class_name CuttableGrass
extends StaticBody3D

const CLUSTER_COUNT := 96

var cut := false
var blade_root: MultiMeshInstance3D
var base_position: Vector3
var variations := PackedFloat32Array()
var tones := PackedFloat32Array()
var shapes := PackedFloat32Array()
var blade_x_positions := PackedFloat32Array()
var animated_blade_count := 0
var cutting := false
var cut_animation_duration := 0.52


func setup(seed_value: int, tint: Color) -> void:
	add_to_group("cuttable_grass")
	set_process(true)
	set_meta("interaction_kind", "grass")
	base_position = position
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = GrassVisualFactory.get_cluster_mesh()
	multimesh.instance_count = CLUSTER_COUNT
	variations.resize(CLUSTER_COUNT)
	tones.resize(CLUSTER_COUNT)
	shapes.resize(CLUSTER_COUNT)
	blade_x_positions.resize(CLUSTER_COUNT)
	for index in range(CLUSTER_COUNT):
		var local_position := Vector3(rng.randf_range(-0.76, 0.76), 0.0, rng.randf_range(-0.76, 0.76))
		var mirror_axis := -1.0 if rng.randf() < 0.46 else 1.0
		var scale_value := Vector3(rng.randf_range(0.9, 1.3) * mirror_axis, rng.randf_range(0.9, 1.5), rng.randf_range(0.9, 1.3))
		var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		if rng.randf() < 0.58:
			basis = basis.rotated(Vector3.RIGHT, deg_to_rad(rng.randf_range(-8.0, 8.0)))
			basis = basis.rotated(Vector3.FORWARD, deg_to_rad(rng.randf_range(-8.0, 8.0)))
		basis = basis.scaled(scale_value)
		var variation := rng.randf()
		var tone := rng.randf()
		var shape := rng.randf()
		variations[index] = variation
		tones[index] = tone
		shapes[index] = shape
		blade_x_positions[index] = local_position.x
		multimesh.set_instance_transform(index, Transform3D(basis, local_position))
		multimesh.set_instance_custom_data(index, Color(0.0, variation, tone, shape))
	blade_root = MultiMeshInstance3D.new()
	blade_root.name = "GrassClusters"
	blade_root.multimesh = multimesh
	blade_root.material_override = GrassVisualFactory.create_grass_material(tint.darkened(0.28), tint.lightened(0.22))
	blade_root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blade_root.custom_aabb = AABB(Vector3(-0.9, -0.1, -0.9), Vector3(1.8, 1.65, 1.8))
	add_child(blade_root)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.65, 1.2, 1.65)
	var collision := CollisionShape3D.new()
	collision.position.y = 0.6
	collision.shape = shape
	add_child(collision)


func _apply_cut_progress(raw_progress: float) -> void:
	if blade_root == null:
		return
	var progress := smoothstep(0.0, 1.0, raw_progress)
	var sweep_edge := lerpf(0.82, -0.82, progress)
	animated_blade_count = 0
	for index in range(blade_root.multimesh.instance_count):
		var blade_x := blade_x_positions[index]
		if blade_x >= sweep_edge:
			blade_root.multimesh.set_instance_custom_data(index, Color(1.0, variations[index], tones[index], shapes[index]))
			animated_blade_count += 1


func cut_grass() -> bool:
	if cut:
		return false
	cut = true
	cutting = true
	animated_blade_count = 0
	set_meta("interaction_kind", "cut_grass")
	var cut_tween := create_tween()
	cut_tween.tween_method(_apply_cut_progress, 0.0, 1.0, cut_animation_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cut_tween.tween_callback(func() -> void:
		cutting = false
		_apply_cut_progress(1.0)
		_disable_collision())
	return true


func _disable_collision() -> void:
	for child: Node in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)


func restore_cut_state(should_be_cut: bool) -> void:
	if not should_be_cut:
		return
	cut = true
	cutting = false
	animated_blade_count = CLUSTER_COUNT
	for index in range(blade_root.multimesh.instance_count):
		blade_root.multimesh.set_instance_custom_data(index, Color(1.0, variations[index], tones[index], shapes[index]))
	for child: Node in get_children():
		if child is CollisionShape3D:
			child.disabled = true
