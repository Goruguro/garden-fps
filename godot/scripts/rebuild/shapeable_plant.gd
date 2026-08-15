class_name ShapeablePlant
extends StaticBody3D

var plant_id := ""
var shaped := false
var visual_root: Node3D
var foliage_parts: Array[MeshInstance3D] = []


func configure(id: String, variant: int) -> void:
	plant_id = id
	name = "ShapeableTopiary_%s" % id
	_build_visual(variant)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.05
	collision.position.y = 1.05
	collision.shape = shape
	add_child(collision)


func shape_plant(animated := true) -> bool:
	if shaped:
		return false
	shaped = true
	_apply_shaped_form(animated)
	return true


func restore_shaped() -> void:
	shaped = true
	_apply_shaped_form(false)


func _build_visual(variant: int) -> void:
	visual_root = Node3D.new()
	visual_root.name = "TopiaryVisual"
	add_child(visual_root)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.13
	trunk_mesh.bottom_radius = 0.19
	trunk_mesh.height = 1.4
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.position.y = 0.7
	trunk.material_override = _material(Color("76583b"))
	visual_root.add_child(trunk)
	var palettes := [
		[Color("52754b"), Color("75935d")],
		[Color("416b58"), Color("70a078")],
		[Color("667548"), Color("9ca85f")],
	]
	var palette: Array = palettes[variant % palettes.size()]
	var positions := [
		Vector3(-0.48, 1.18, 0.02), Vector3(0.43, 1.22, 0.08),
		Vector3(0.0, 1.65, -0.02), Vector3(-0.24, 1.92, 0.03), Vector3(0.30, 1.88, 0.0)
	]
	for index in range(positions.size()):
		var part := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.62 + float((index + variant) % 3) * 0.08
		mesh.height = mesh.radius * 1.72
		mesh.radial_segments = 9
		mesh.rings = 5
		part.mesh = mesh
		part.position = positions[index]
		part.rotation.y = float(index) * 0.73
		part.scale = Vector3(1.12, 0.92 + float(index % 2) * 0.16, 0.96)
		part.material_override = _material(palette[index % 2])
		visual_root.add_child(part)
		foliage_parts.append(part)
	for side in [-1.0, 1.0]:
		var flower := MeshInstance3D.new()
		var flower_mesh := SphereMesh.new()
		flower_mesh.radius = 0.10
		flower_mesh.height = 0.16
		flower_mesh.radial_segments = 7
		flower_mesh.rings = 4
		flower.mesh = flower_mesh
		flower.position = Vector3(side * 0.48, 1.62 + side * 0.08, -0.48)
		flower.material_override = _material(Color("e6b85d") if variant % 2 == 0 else Color("d88985"))
		visual_root.add_child(flower)


func _apply_shaped_form(animated: bool) -> void:
	var target_positions := [
		Vector3(-0.34, 1.12, 0.0), Vector3(0.34, 1.12, 0.0),
		Vector3(0.0, 1.48, 0.0), Vector3(-0.20, 1.76, 0.0), Vector3(0.20, 1.76, 0.0)
	]
	for index in range(foliage_parts.size()):
		var part := foliage_parts[index]
		var target_scale := Vector3(0.82, 0.72, 0.82) if index < 2 else Vector3(0.66, 0.60, 0.66)
		if animated:
			var tween := create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(part, "position", target_positions[index], 0.34).set_delay(float(index) * 0.025)
			tween.tween_property(part, "scale", target_scale, 0.34).set_delay(float(index) * 0.025)
		else:
			part.position = target_positions[index]
			part.scale = target_scale


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material
