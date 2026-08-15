class_name InteractionTarget
extends Area3D

signal interaction_requested(actor: Node)

@export var interaction_id: StringName
@export var prompt: String = "Etkileş"
@export var enabled := true


func configure(id: StringName, prompt_text: String, shape: Shape3D, offset := Vector3.ZERO) -> void:
	interaction_id = id
	prompt = prompt_text
	collision_layer = 2
	collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.position = offset
	collision.shape = shape
	add_child(collision)


func request_interaction(actor: Node) -> bool:
	if not enabled:
		return false
	interaction_requested.emit(actor)
	return true


static func find_from(collider: Object) -> InteractionTarget:
	var node := collider as Node
	while node != null:
		if node is InteractionTarget:
			return node as InteractionTarget
		node = node.get_parent()
	return null
