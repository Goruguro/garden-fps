class_name GardenCollisionFactory
extends RefCounted

const WORLD_LAYER := 1


static func add_box(parent: Node3D, name_value: String, position_value: Vector3, size_value: Vector3, moving := false) -> PhysicsBody3D:
	var body: PhysicsBody3D = AnimatableBody3D.new() if moving else StaticBody3D.new()
	body.name = name_value
	body.position = position_value
	body.collision_layer = WORLD_LAYER
	body.collision_mask = WORLD_LAYER
	var shape := BoxShape3D.new()
	shape.size = size_value.abs().max(Vector3.ONE * 0.08)
	var collision := CollisionShape3D.new()
	collision.name = "Hitbox"
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.add_to_group("solid_world_content")
	return body


static func add_capsule(parent: Node3D, name_value: String, position_value: Vector3, radius: float, height: float, moving := false) -> PhysicsBody3D:
	var body: PhysicsBody3D = AnimatableBody3D.new() if moving else StaticBody3D.new()
	body.name = name_value
	body.position = position_value
	body.collision_layer = WORLD_LAYER
	body.collision_mask = WORLD_LAYER
	var shape := CapsuleShape3D.new()
	shape.radius = maxf(radius, 0.08)
	shape.height = maxf(height, shape.radius * 2.0)
	var collision := CollisionShape3D.new()
	collision.name = "Hitbox"
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.add_to_group("solid_world_content")
	return body


static func add_cylinder(parent: Node3D, name_value: String, position_value: Vector3, radius: float, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name_value
	body.position = position_value
	body.collision_layer = WORLD_LAYER
	body.collision_mask = WORLD_LAYER
	var shape := CylinderShape3D.new()
	shape.radius = maxf(radius, 0.08)
	shape.height = maxf(height, 0.08)
	var collision := CollisionShape3D.new()
	collision.name = "Hitbox"
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.add_to_group("solid_world_content")
	return body


static func add_visual_bounds_box(visual_root: Node3D, name_value := "ModelHitbox", minimum_size := Vector3(0.25, 0.25, 0.25), shrink := Vector3.ONE) -> StaticBody3D:
	var local_bounds := _collect_visual_bounds(visual_root)
	if local_bounds.size.length_squared() <= 0.0001:
		return add_box(visual_root, name_value, Vector3.UP * minimum_size.y * 0.5, minimum_size) as StaticBody3D
	var size_value := (local_bounds.size * shrink).max(minimum_size)
	var center := local_bounds.get_center()
	# Most decorative props should rest on the terrain even if their imported origin is offset.
	center.y = maxf(center.y, size_value.y * 0.5)
	return add_box(visual_root, name_value, center, size_value) as StaticBody3D


static func count_valid_hitboxes(root: Node) -> int:
	var count := 0
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is CollisionShape3D and (current as CollisionShape3D).shape != null:
			count += 1
		for child in current.get_children():
			pending.append(child)
	return count


static func _collect_visual_bounds(root: Node3D) -> AABB:
	var result := AABB()
	var has_bounds := false
	var inverse_root := root.global_transform.affine_inverse()
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D:
			var mesh_instance := current as MeshInstance3D
			if mesh_instance.mesh != null:
				var relative_transform := inverse_root * mesh_instance.global_transform
				var transformed_bounds: AABB = relative_transform * mesh_instance.get_aabb()
				result = result.merge(transformed_bounds) if has_bounds else transformed_bounds
				has_bounds = true
		for child in current.get_children():
			pending.append(child)
	return result if has_bounds else AABB()
