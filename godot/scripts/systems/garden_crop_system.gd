class_name GardenCropSystem
extends Node3D

const CROP_ROOT := "res://assets/third_party/quaternius_ultimate_crops/"
const CROP_STAGES := {
	&"pancar": ["Beet_1.obj", "Beet_2.obj", "Beet_3.obj", "Beet_4.obj", "Beet_Crop.obj"],
	&"elma": ["Apple_1.obj", "Apple_2.obj", "Apple_3.obj", "Apple_4.obj", "Apple_Crop.obj"],
}

var session: GameSession
var season_system: GardenSeasonSystem
var height_provider: Node
var plots: Array[Dictionary] = []
var last_update_hour := -1.0


func build(active_session: GameSession, seasons: GardenSeasonSystem, provider: Node) -> void:
	session = active_session
	season_system = seasons
	height_provider = provider
	name = "QuaterniusFiveStageCrops"
	_build_bed(Vector3(24.0, 0.0, 7.0), &"pancar", 0)
	_build_bed(Vector3(29.0, 0.0, 7.0), &"pancar", 1)
	_build_bed(Vector3(24.0, 0.0, 11.0), &"elma", 2)


func advance(hour: float, irrigated: bool) -> void:
	if session == null or last_update_hour < 0.0:
		last_update_hour = hour
		return
	var elapsed := fposmod(hour - last_update_hour, 24.0)
	last_update_hour = hour
	if elapsed <= 0.0 or elapsed > 2.0:
		return
	var water_bonus := 1.42 if irrigated else 0.72
	var fertilizer_bonus := 1.0 + session.fertilizer_bonus
	var growth := elapsed * 0.032 * season_system.growth_multiplier() * water_bonus * fertilizer_bonus
	for plot in plots:
		var plot_id := str(plot.id)
		session.crop_progress[plot_id] = clampf(float(session.crop_progress.get(plot_id, 0.0)) + growth, 0.0, 1.0)
		_update_plot_stage(plot)
	session.fertilizer_bonus = move_toward(session.fertilizer_bonus, 0.0, elapsed * 0.012)


func apply_fertilizer() -> bool:
	if session == null or not session.remove_item("gubre"):
		return false
	session.fertilizer_bonus = minf(session.fertilizer_bonus + 0.35, 0.85)
	for plot in plots:
		var plot_id := str(plot.id)
		session.crop_progress[plot_id] = minf(float(session.crop_progress.get(plot_id, 0.0)) + 0.08, 1.0)
		_update_plot_stage(plot)
	session.save()
	return true


func get_stats() -> Dictionary:
	return {"plots": plots.size(), "stages": 5, "fertilizer_bonus": session.fertilizer_bonus if session != null else 0.0}


func _build_bed(center: Vector3, crop_id: StringName, bed_index: int) -> void:
	var root := Node3D.new()
	root.name = "CropBed_%s_%d" % [crop_id, bed_index]
	root.position = height_provider.project(center, 0.06) if height_provider != null else center
	add_child(root)
	var soil := MeshInstance3D.new()
	var soil_mesh := BoxMesh.new()
	soil_mesh.size = Vector3(3.8, 0.18, 2.8)
	soil.mesh = soil_mesh
	var soil_material := StandardMaterial3D.new()
	soil_material.albedo_color = Color("5d3c28")
	soil_material.roughness = 0.98
	soil.material_override = soil_material
	root.add_child(soil)
	if bed_index == 0:
		var interaction := InteractionTarget.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.2, 1.4, 3.2)
		interaction.configure(&"crop_beds", "Ekinlere gübre ve sulama uygula", shape, Vector3(0.0, 0.7, 0.0))
		root.add_child(interaction)
	for row in 2:
		for column in 3:
			var plot_id := "%s_%d_%d_%d" % [crop_id, bed_index, row, column]
			var crop_root := Node3D.new()
			crop_root.name = "Crop_%s" % plot_id
			crop_root.position = Vector3((float(column) - 1.0) * 1.05, 0.13, (float(row) - 0.5) * 1.05)
			root.add_child(crop_root)
			var plot := {"id": plot_id, "crop": crop_id, "root": crop_root, "stage": -1}
			plots.append(plot)
			_update_plot_stage(plot)


func _update_plot_stage(plot: Dictionary) -> void:
	var progress := float(session.crop_progress.get(str(plot.id), 0.0))
	var stage := clampi(int(floor(progress * 5.0)), 0, 4)
	if int(plot.stage) == stage:
		return
	plot.stage = stage
	var root: Node3D = plot.root
	for child in root.get_children():
		child.queue_free()
	var paths: Array = CROP_STAGES[plot.crop]
	var resource := load(CROP_ROOT + str(paths[stage]))
	if resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = resource as Mesh
		mesh_instance.scale = Vector3.ONE * (0.44 if plot.crop == &"pancar" else 0.24)
		mesh_instance.rotation.y = float(str(plot.id).hash() % 628) * 0.01
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(mesh_instance)
	elif resource is PackedScene:
		var instance := (resource as PackedScene).instantiate() as Node3D
		instance.scale = Vector3.ONE * 0.35
		root.add_child(instance)
