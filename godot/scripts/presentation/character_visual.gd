class_name GardenCharacterVisual
extends Node3D

@export var model_scene: PackedScene
@export var character_scale := 0.72
@export var idle_animation := "Idle"

var model: Node3D
var animation_player: AnimationPlayer
var current_animation := ""


func build() -> void:
	if model_scene == null or model != null:
		return
	model = model_scene.instantiate() as Node3D
	if model == null:
		return
	model.scale = Vector3.ONE * character_scale
	add_child(model)
	animation_player = _find_animation_player(model)
	_play_best_idle()


func play_animation(preferred: PackedStringArray) -> void:
	if animation_player == null:
		return
	for animation_name: String in preferred:
		if animation_player.has_animation(animation_name):
			if current_animation == animation_name and animation_player.is_playing():
				return
			current_animation = animation_name
			animation_player.play(animation_name, 0.2)
			return


func _play_best_idle() -> void:
	play_animation(PackedStringArray([idle_animation, "Idle_A", "Idle", "idle", "RESET"]))


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child: Node in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
