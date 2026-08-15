class_name TerrainHeightProvider
extends Node

var terrain: Node3D
var fallback_height := 0.0


func configure(terrain_node: Node3D, default_height := 0.0) -> void:
	terrain = terrain_node
	fallback_height = default_height


func get_height(world_position: Vector3) -> float:
	if terrain == null or not is_instance_valid(terrain):
		return fallback_height
	var terrain_data: Object = terrain.get("data")
	if terrain_data == null or not terrain_data.has_method("get_height"):
		return fallback_height
	var sampled_height := float(terrain_data.call("get_height", world_position))
	return fallback_height if is_nan(sampled_height) else sampled_height


func project(world_position: Vector3, vertical_offset := 0.0) -> Vector3:
	var result := world_position
	result.y = get_height(world_position) + vertical_offset
	return result


func place(node: Node3D, world_position: Vector3, vertical_offset := 0.0) -> void:
	node.global_position = project(world_position, vertical_offset)
