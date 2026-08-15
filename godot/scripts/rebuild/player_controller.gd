class_name RebuildPlayerController
extends CharacterBody3D

const GARDENER_MODEL := preload("res://assets/third_party/kaykit_characters/Gardener.glb")

signal interact_requested
signal tool_requested
signal tool_switched
signal pause_requested
signal journal_requested(page: StringName)
signal camera_changed(third_person: bool)
signal trimmer_motor_requested(active: bool)
signal trimmer_sweep_requested(speed: float)

@export var walk_speed := 4.6
@export var sprint_speed := 7.4
@export var crouch_speed := 2.6
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0022

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var controls_enabled := true
var crouched := false
var third_person := false
var look_pitch := 0.0
var bob_time := 0.0
var tool_animating := false
var equipped_tool := "trimmer"
var viewmodel: Node3D
var tool_root: Node3D
var arm_root: Node3D
var body_visual: Node3D
var body_character: GardenCharacterVisual
var footstep_player: AudioStreamPlayer3D
var tool_player: AudioStreamPlayer
var switch_player: AudioStreamPlayer
var footstep_timer := 0.0
var footstep_index := 0
var footstep_cycle := 0
var footstep_streams: Array[AudioStream] = []
var terrain_grounded_frames := 0
var trimmer_head: Node3D
var shear_left: Node3D
var shear_right: Node3D
var material_cache: Dictionary = {}
var mouse_capture_request_count := 0
var ignored_capture_motion_events := 0
var trimmer_motor_active := false
var tool_aim_active := false
var tool_aim_yaw := 0.0
var tool_aim_pitch := 0.0
var last_tool_motion_msec := 0
var engine_player: AudioStreamPlayer

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var aim_ray: RayCast3D = $Head/Camera3D/AimRay
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var third_camera: Camera3D = $SpringArm3D/ThirdPersonCamera
@onready var collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("player")
	capture_mouse()
	_build_viewmodel()
	_build_body_visual()
	_build_audio()
	_set_camera_mode(false)


func _input(event: InputEvent) -> void:
	# Camera look must run before GUI controls can consume mouse motion.
	if event is InputEventMouseMotion and controls_enabled and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless"):
		if ignored_capture_motion_events > 0 and DisplayServer.get_name() != "headless":
			ignored_capture_motion_events -= 1
			return
		var safe_motion := Vector2(clampf(event.relative.x, -140.0, 140.0), clampf(event.relative.y, -140.0, 140.0))
		if equipped_tool == "trimmer" and event.alt_pressed:
			apply_tool_aim_delta(safe_motion)
		else:
			tool_aim_active = false
			apply_look_delta(safe_motion)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if equipped_tool == "trimmer":
			trimmer_motor_requested.emit(event.pressed)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and controls_enabled and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		capture_mouse()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_inventory"):
		journal_requested.emit(&"inventory")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_map"):
		journal_requested.emit(&"map")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_quests"):
		journal_requested.emit(&"quests")
		get_viewport().set_input_as_handled()
		return
	if not controls_enabled:
		return
	if event.is_action_pressed("interact"):
		interact_requested.emit()
	elif event.is_action_pressed("use_tool"):
		tool_requested.emit()
	elif event.is_action_pressed("switch_tool"):
		tool_switched.emit()
	elif event.is_action_pressed("toggle_camera"):
		_set_camera_mode(not third_person)


func apply_look_delta(relative_motion: Vector2) -> void:
	rotate_y(-relative_motion.x * mouse_sensitivity)
	rotation.y = wrapf(rotation.y, -PI, PI)
	look_pitch = clampf(look_pitch - relative_motion.y * mouse_sensitivity, -1.35, 1.35)
	head.rotation.x = look_pitch
	spring_arm.rotation.x = look_pitch * 0.55


func apply_tool_aim_delta(relative_motion: Vector2, forced_delta := -1.0) -> void:
	tool_aim_active = true
	var previous_yaw := tool_aim_yaw
	tool_aim_yaw = clampf(tool_aim_yaw + relative_motion.x * mouse_sensitivity * 1.45, -0.82, 0.82)
	tool_aim_pitch = clampf(tool_aim_pitch + relative_motion.y * mouse_sensitivity, -0.24, 0.32)
	var yaw_delta := tool_aim_yaw - previous_yaw
	var now := Time.get_ticks_msec()
	var elapsed := forced_delta
	if elapsed <= 0.0:
		elapsed = clampf(float(now - last_tool_motion_msec) * 0.001, 0.008, 0.08) if last_tool_motion_msec > 0 else 0.016
	last_tool_motion_msec = now
	# Negative screen motion is the deliberate right-to-left cutting stroke.
	if trimmer_motor_active and yaw_delta < -0.0005:
		trimmer_sweep_requested.emit(absf(yaw_delta) / elapsed)


func capture_mouse() -> void:
	mouse_capture_request_count += 1
	ignored_capture_motion_events = 2
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var grounded := is_grounded_for_gameplay()
	if not grounded:
		velocity.y = maxf(velocity.y - gravity * delta, -32.0)
	elif controls_enabled and Input.is_action_just_pressed("jump") and not crouched:
		velocity.y = jump_velocity

	var input_vector := Vector2.ZERO
	if controls_enabled:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	crouched = controls_enabled and Input.is_action_pressed("crouch")
	var sprinting := controls_enabled and Input.is_action_pressed("sprint") and not crouched and input_vector.y < 0.1
	var target_speed := crouch_speed if crouched else (sprint_speed if sprinting else walk_speed)
	var target_velocity := direction * target_speed
	var acceleration := 28.0 if grounded else 8.0
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	move_and_slide()
	_update_footsteps(delta, horizontal_speed_2d(), sprinting)
	_update_stance(delta)
	_update_motion_visuals(delta, input_vector.length(), sprinting)
	terrain_grounded_frames = maxi(terrain_grounded_frames - 1, 0)


func _process(delta: float) -> void:
	if equipped_tool != "trimmer" or tool_root == null:
		return
	tool_root.rotation.y = lerpf(tool_root.rotation.y, tool_aim_yaw, delta * 14.0)
	tool_root.rotation.x = lerpf(tool_root.rotation.x, tool_aim_pitch, delta * 12.0)
	var motor_vibration := sin(Time.get_ticks_msec() * 0.035) * 0.008 if trimmer_motor_active else 0.0
	tool_root.rotation.z = lerpf(tool_root.rotation.z, -tool_aim_yaw * 0.16 + motor_vibration, delta * 16.0)
	if trimmer_motor_active and trimmer_head != null:
		trimmer_head.rotate_y(delta * 58.0)
	var hand_offset := tool_aim_yaw * 0.11 if tool_aim_active else 0.0
	arm_root.rotation.x = lerpf(arm_root.rotation.x, -tool_aim_pitch * 0.24, delta * 10.0)
	arm_root.rotation.y = lerpf(arm_root.rotation.y, hand_offset, delta * 10.0)
	if body_visual != null and tool_aim_active:
		body_visual.rotation.y = lerpf(body_visual.rotation.y, -tool_aim_yaw * 0.22, delta * 8.0)


func recover_to_terrain(ground_height: float) -> void:
	global_position.y = ground_height + 0.018
	velocity.y = 0.0
	terrain_grounded_frames = 2


func is_grounded_for_gameplay() -> bool:
	return is_on_floor() or terrain_grounded_frames > 0


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if enabled:
		capture_mouse()
	else:
		set_trimmer_motor_active(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_process_input(enabled)


func get_aimed_object() -> Object:
	aim_ray.force_raycast_update()
	return aim_ray.get_collider() if aim_ray.is_colliding() else null


func get_aim_point() -> Vector3:
	aim_ray.force_raycast_update()
	return aim_ray.get_collision_point() if aim_ray.is_colliding() else camera.global_position + -camera.global_basis.z * 4.0


func get_trimmer_cut_point(distance := 1.75) -> Vector3:
	var camera_forward := -camera.global_basis.z
	var ground_forward := Vector3(camera_forward.x, 0.0, camera_forward.z).normalized()
	if ground_forward.length_squared() < 0.01:
		ground_forward = -global_basis.z.normalized()
	ground_forward = ground_forward.rotated(Vector3.UP, tool_aim_yaw)
	return global_position + ground_forward * distance


func set_tool(tool_id: String) -> void:
	if equipped_tool == "trimmer" and tool_id != "trimmer":
		set_trimmer_motor_active(false)
	equipped_tool = tool_id
	tool_aim_active = false
	tool_aim_yaw = 0.0
	tool_aim_pitch = 0.0
	if switch_player != null and DisplayServer.get_name() != "headless":
		switch_player.play()
	if tool_root == null:
		return
	var tween := create_tween()
	tween.tween_property(tool_root, "position:y", -0.55, 0.12)
	tween.tween_callback(_rebuild_tool_mesh)
	tween.tween_property(tool_root, "position:y", -0.18, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_tool_action() -> void:
	if tool_animating:
		return
	tool_animating = true
	if tool_player != null:
		tool_player.play()
	var start_rotation := tool_root.rotation
	var tween := create_tween()
	if equipped_tool == "shears":
		if shear_left != null and shear_right != null:
			var left_start := shear_left.rotation.y
			var right_start := shear_right.rotation.y
			tween.set_parallel(true)
			tween.tween_property(shear_left, "rotation:y", left_start - 0.34, 0.08)
			tween.tween_property(shear_right, "rotation:y", right_start + 0.34, 0.08)
			tween.tween_property(tool_root, "rotation:z", start_rotation.z - 0.18, 0.08)
			tween.set_parallel(false)
			tween.tween_property(shear_left, "rotation:y", left_start, 0.16).set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property(shear_right, "rotation:y", right_start, 0.16).set_trans(Tween.TRANS_BACK)
	else:
		tween.tween_property(tool_root, "rotation:y", start_rotation.y - 0.46, 0.10)
		if trimmer_head != null:
			tween.parallel().tween_property(trimmer_head, "rotation:y", trimmer_head.rotation.y + TAU * 2.0, 0.20)
	tween.tween_property(tool_root, "rotation", start_rotation, 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func() -> void: tool_animating = false)


func set_trimmer_motor_active(active: bool) -> void:
	trimmer_motor_active = active and equipped_tool == "trimmer" and controls_enabled
	if engine_player == null or DisplayServer.get_name() == "headless":
		return
	if trimmer_motor_active:
		if not engine_player.playing:
			engine_player.play()
	else:
		engine_player.stop()


func _set_camera_mode(use_third_person: bool) -> void:
	third_person = use_third_person
	camera.current = not third_person
	third_camera.current = third_person
	viewmodel.visible = not third_person
	body_visual.visible = third_person
	camera_changed.emit(third_person)


func _update_stance(delta: float) -> void:
	var target_head_y := 1.12 if crouched else 1.58
	head.position.y = move_toward(head.position.y, target_head_y, delta * 3.2)
	spring_arm.position.y = move_toward(spring_arm.position.y, target_head_y - 0.1, delta * 3.2)
	var capsule := collision.shape as CapsuleShape3D
	if capsule != null:
		capsule.height = move_toward(capsule.height, 1.15 if crouched else 1.72, delta * 2.6)
		collision.position.y = capsule.height * 0.5


func _update_motion_visuals(delta: float, input_amount: float, sprinting: bool) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if is_grounded_for_gameplay() and input_amount > 0.05:
		bob_time += delta * (11.5 if sprinting else 8.2)
		var bob := Vector3(cos(bob_time * 0.5) * 0.018, sin(bob_time) * 0.025, 0.0) * minf(horizontal_speed / walk_speed, 1.35)
		viewmodel.position = viewmodel.position.lerp(bob, delta * 10.0)
		arm_root.rotation.z = lerpf(arm_root.rotation.z, sin(bob_time * 0.5) * 0.018, delta * 8.0)
	else:
		viewmodel.position = viewmodel.position.lerp(Vector3.ZERO, delta * 8.0)
	var target_fov := 80.0 if sprinting else 76.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 5.0)
	third_camera.fov = lerpf(third_camera.fov, target_fov - 4.0, delta * 5.0)
	body_visual.rotation.x = sin(bob_time) * 0.018 if horizontal_speed > 0.2 else 0.0
	if body_character != null:
		if horizontal_speed < 0.2:
			body_character.play_animation(PackedStringArray(["Idle_A", "Idle", "idle"]))
		elif sprinting:
			body_character.play_animation(PackedStringArray(["Running_A", "Running", "Run", "run"]))
		else:
			body_character.play_animation(PackedStringArray(["Walking_A", "Walking", "Walk", "walk"]))


func horizontal_speed_2d() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _build_audio() -> void:
	footstep_streams = [
		load("res://audio/sfx/footstep_grass.wav"),
		load("res://audio/sfx/footstep_grass_02.wav"),
		load("res://audio/sfx/footstep_grass_03.wav")
	]
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.volume_db = -27.0
	footstep_player.max_distance = 14.0
	add_child(footstep_player)
	tool_player = AudioStreamPlayer.new()
	tool_player.stream = load("res://audio/sfx/tool_swing.wav")
	tool_player.volume_db = -7.0
	add_child(tool_player)
	switch_player = AudioStreamPlayer.new()
	switch_player.stream = load("res://audio/sfx/tool_switch.wav")
	switch_player.volume_db = -8.0
	add_child(switch_player)
	engine_player = AudioStreamPlayer.new()
	engine_player.stream = load("res://audio/third_party/freesound/gas_trimmer_running.ogg")
	engine_player.volume_db = -8.5
	if engine_player.stream is AudioStreamOggVorbis:
		(engine_player.stream as AudioStreamOggVorbis).loop = true
	add_child(engine_player)


func _update_footsteps(delta: float, speed: float, sprinting: bool) -> void:
	if not is_grounded_for_gameplay() or speed < 0.7:
		footstep_timer = 0.0
		return
	footstep_timer -= delta
	if footstep_timer > 0.0:
		return
	footstep_timer = 0.42 if sprinting else (0.78 if crouched else 0.62)
	footstep_cycle += 1
	if footstep_cycle % 3 != 0:
		return
	footstep_player.stream = footstep_streams[footstep_index % footstep_streams.size()]
	footstep_index += 1
	footstep_player.pitch_scale = 0.95 + float(footstep_index % 3) * 0.045
	footstep_player.play()


func _build_viewmodel() -> void:
	viewmodel = Node3D.new()
	viewmodel.name = "Viewmodel"
	camera.add_child(viewmodel)
	arm_root = Node3D.new()
	arm_root.position = Vector3(0.38, -0.47, -0.76)
	arm_root.scale = Vector3.ONE * 0.76
	viewmodel.add_child(arm_root)
	_add_capsule(arm_root, Vector3(-0.20, -0.08, 0.08), Vector3(0.062, 0.33, 0.062), Color("8da06a"), Vector3(0.34, 0.0, 0.18))
	_add_capsule(arm_root, Vector3(0.18, -0.07, 0.05), Vector3(0.062, 0.35, 0.062), Color("8da06a"), Vector3(0.26, 0.0, -0.16))
	_add_sphere(arm_root, Vector3(-0.18, -0.22, -0.01), 0.072, Color("765b3d"))
	_add_sphere(arm_root, Vector3(0.17, -0.22, -0.02), 0.072, Color("765b3d"))
	tool_root = Node3D.new()
	tool_root.position = Vector3(0.14, -0.25, -0.35)
	arm_root.add_child(tool_root)
	_rebuild_tool_mesh()


func _rebuild_tool_mesh() -> void:
	for child: Node in tool_root.get_children():
		child.free()
	trimmer_head = null
	shear_left = null
	shear_right = null
	if equipped_tool == "shears":
		_build_stylized_shears()
	else:
		_build_stylized_trimmer()


func _build_stylized_trimmer() -> void:
	var sage := Color("587456")
	var cream := Color("e2d2a4")
	var terracotta := Color("bd6848")
	var steel := Color("9ba6a0")
	var dark := Color("33443a")
	# Motor housing and fuel tank form a readable silhouette near the hands.
	_add_box(tool_root, Vector3(0.04, 0.01, 0.22), Vector3(0.28, 0.22, 0.30), sage, Vector3(-0.08, 0.0, 0.0))
	_add_sphere(tool_root, Vector3(0.04, 0.10, 0.20), 0.115, cream)
	_add_cylinder(tool_root, Vector3(0.04, 0.18, 0.18), 0.045, 0.07, terracotta)
	_add_box(tool_root, Vector3(0.16, 0.00, 0.22), Vector3(0.05, 0.14, 0.19), terracotta)
	# Long shaft, secondary grip and cable.
	_add_cylinder(tool_root, Vector3(0.02, -0.01, -0.22), 0.032, 0.78, steel, Vector3(PI * 0.5, 0.0, -0.08))
	_add_cylinder(tool_root, Vector3(-0.11, 0.05, -0.05), 0.036, 0.34, dark, Vector3(0.0, 0.0, PI * 0.5))
	_add_torus(tool_root, Vector3(-0.24, 0.05, -0.05), 0.045, 0.082, cream, Vector3(PI * 0.5, 0.0, 0.0))
	_add_cylinder(tool_root, Vector3(0.06, -0.03, -0.62), 0.062, 0.12, dark, Vector3(PI * 0.5, 0.0, 0.0))
	_add_box(tool_root, Vector3(0.06, 0.02, -0.70), Vector3(0.42, 0.045, 0.13), terracotta, Vector3(0.0, 0.0, 0.08))
	trimmer_head = Node3D.new()
	trimmer_head.name = "SpinningCutHead"
	trimmer_head.position = Vector3(0.06, -0.02, -0.71)
	tool_root.add_child(trimmer_head)
	_add_cylinder(trimmer_head, Vector3.ZERO, 0.09, 0.045, dark, Vector3(PI * 0.5, 0.0, 0.0))
	_add_box(trimmer_head, Vector3.ZERO, Vector3(0.52, 0.012, 0.018), Color("d9b94b"), Vector3(0.0, 0.0, 0.18))


func _build_stylized_shears() -> void:
	var steel_light := Color("bdc8bd")
	var steel_dark := Color("65726b")
	var terracotta := Color("bd6848")
	var cream := Color("e7d7aa")
	_add_cylinder(tool_root, Vector3(0.0, 0.0, -0.02), 0.07, 0.10, cream, Vector3(PI * 0.5, 0.0, 0.0))
	_add_sphere(tool_root, Vector3(0.0, 0.0, -0.02), 0.085, steel_dark)
	shear_left = Node3D.new()
	shear_left.name = "LeftShearHalf"
	shear_left.position = Vector3(0.0, 0.0, -0.02)
	tool_root.add_child(shear_left)
	shear_right = Node3D.new()
	shear_right.name = "RightShearHalf"
	shear_right.position = Vector3(0.0, 0.0, -0.02)
	tool_root.add_child(shear_right)
	_add_box(shear_left, Vector3(-0.08, 0.0, -0.25), Vector3(0.075, 0.035, 0.48), steel_light, Vector3(0.0, 0.0, -0.12))
	_add_box(shear_right, Vector3(0.08, 0.0, -0.25), Vector3(0.075, 0.035, 0.48), steel_dark, Vector3(0.0, 0.0, 0.12))
	_add_cylinder(shear_left, Vector3(-0.12, 0.0, 0.24), 0.045, 0.44, terracotta, Vector3(PI * 0.5, 0.0, -0.22))
	_add_cylinder(shear_right, Vector3(0.12, 0.0, 0.24), 0.045, 0.44, terracotta, Vector3(PI * 0.5, 0.0, 0.22))
	_add_torus(shear_left, Vector3(-0.20, 0.0, 0.46), 0.07, 0.13, cream, Vector3(PI * 0.5, 0.0, 0.0))
	_add_torus(shear_right, Vector3(0.20, 0.0, 0.46), 0.07, 0.13, cream, Vector3(PI * 0.5, 0.0, 0.0))


func _build_body_visual() -> void:
	body_visual = Node3D.new()
	body_visual.name = "CharacterBodyVisual"
	add_child(body_visual)
	body_character = GardenCharacterVisual.new()
	body_character.name = "AnimatedGardener"
	body_character.model_scene = GARDENER_MODEL
	body_character.character_scale = 0.92
	body_character.rotation.y = PI
	body_visual.add_child(body_character)
	body_character.build()


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.rotation = rotation_value
	node.material_override = _material(color, 0.72)
	parent.add_child(node)
	return node


func _add_capsule(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = size.x
	mesh.height = size.y
	node.mesh = mesh
	node.position = pos
	node.rotation = rotation_value
	node.material_override = _material(color, 0.82)
	parent.add_child(node)
	return node


func _add_sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color, 0.8)
	parent.add_child(node)
	return node


func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	node.mesh = mesh
	node.position = pos
	node.rotation = rotation_value
	node.material_override = _material(color, 0.68)
	parent.add_child(node)
	return node


func _add_torus(parent: Node3D, pos: Vector3, inner_radius: float, outer_radius: float, color: Color, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 12
	mesh.ring_segments = 8
	node.mesh = mesh
	node.position = pos
	node.rotation = rotation_value
	node.material_override = _material(color, 0.75)
	parent.add_child(node)
	return node


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var cache_key := "%s_%.2f" % [color.to_html(), roughness]
	if material_cache.has(cache_key):
		return material_cache[cache_key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.2 if color.v < 0.68 and color.s < 0.28 else 0.0
	material_cache[cache_key] = material
	return material
