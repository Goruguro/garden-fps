class_name KayKitEnvironmentDecorator
extends Node3D

const COLLISION_FACTORY := preload("res://scripts/physics/garden_collision_factory.gd")

const ASSETS := {
	"bench": preload("res://assets/third_party/kaykit_city/bench.gltf"),
	"bush": preload("res://assets/third_party/kaykit_city/bush.gltf"),
	"streetlight": preload("res://assets/third_party/kaykit_city/streetlight.gltf"),
	"tree_a": preload("res://assets/third_party/kaykit_medieval/decoration/nature/tree_single_A.gltf"),
	"tree_b": preload("res://assets/third_party/kaykit_medieval/decoration/nature/tree_single_B.gltf"),
	"barrel": preload("res://assets/third_party/kaykit_medieval/decoration/props/barrel.gltf"),
	"crate": preload("res://assets/third_party/kaykit_medieval/decoration/props/crate_A_big.gltf"),
	"well": preload("res://assets/third_party/kaykit_medieval/buildings/green/building_well_green.gltf")
}

var height_provider: Node


func build(provider: Node) -> void:
	height_provider = provider
	_spawn("well", Vector3(28, 0, -8), 0.55, -0.35)
	_spawn("bench", Vector3(11, 0, -9), 0.7, 1.45)
	_spawn("streetlight", Vector3(7, 0, 13), 0.72, 0.0)
	_spawn("streetlight", Vector3(-7, 0, 3), 0.72, 0.0)
	_spawn("barrel", Vector3(-15.5, 0, -7.2), 0.75, 0.2)
	_spawn("crate", Vector3(-17.0, 0, -7.8), 0.7, -0.18)
	for data in [
		["tree_a", Vector3(-46, 0, -34), 1.1, 0.2],
		["tree_b", Vector3(-38, 0, 42), 1.3, -0.8],
		["tree_a", Vector3(45, 0, 38), 1.2, 1.4],
		["tree_b", Vector3(48, 0, -36), 1.35, 0.6]
	]:
		_spawn(data[0], data[1], data[2], data[3])
	for index in 18:
		var angle := TAU * float(index) / 18.0
		var radius := 34.0 + float(index % 3) * 2.4
		_spawn("bush", Vector3(cos(angle) * radius, 0, sin(angle) * radius), 0.52 + (index % 4) * 0.05, angle)


func _spawn(asset_id: String, world_position: Vector3, scale_value: float, yaw: float) -> Node3D:
	var packed_scene: PackedScene = ASSETS[asset_id]
	var instance := packed_scene.instantiate() as Node3D
	if instance == null:
		return null
	instance.name = "KayKit_%s" % asset_id
	add_child(instance)
	instance.scale = Vector3.ONE * scale_value
	instance.rotation.y = yaw
	instance.global_position = height_provider.project(world_position, 0.02) if height_provider != null else world_position
	_add_asset_hitbox(instance, asset_id)
	return instance


func _add_asset_hitbox(instance: Node3D, asset_id: String) -> void:
	match asset_id:
		"well":
			COLLISION_FACTORY.add_visual_bounds_box(instance, "WellHitbox", Vector3(1.4, 1.2, 1.4), Vector3(0.88, 0.92, 0.88))
		"bench":
			COLLISION_FACTORY.add_visual_bounds_box(instance, "BenchHitbox", Vector3(1.0, 0.65, 0.42), Vector3(0.92, 0.82, 0.82))
		"streetlight":
			COLLISION_FACTORY.add_cylinder(instance, "StreetlightHitbox", Vector3(0.0, 1.75, 0.0), 0.16, 3.5)
		"barrel":
			COLLISION_FACTORY.add_cylinder(instance, "BarrelHitbox", Vector3(0.0, 0.55, 0.0), 0.44, 1.1)
		"crate":
			COLLISION_FACTORY.add_visual_bounds_box(instance, "CrateHitbox", Vector3(0.75, 0.75, 0.75), Vector3(0.92, 0.92, 0.92))
		"tree_a", "tree_b":
			COLLISION_FACTORY.add_cylinder(instance, "TreeTrunkHitbox", Vector3(0.0, 1.65, 0.0), 0.32, 3.3)
