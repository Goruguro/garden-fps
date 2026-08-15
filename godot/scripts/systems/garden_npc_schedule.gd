class_name GardenNPCSchedule
extends Node

enum Activity { WORK, REST, SHELTER, ANIMAL_FRIEND }

var actor: Node3D
var home_position: Vector3
var work_position: Vector3
var rest_position: Vector3
var shelter_position: Vector3
var activity := Activity.REST
var target_position: Vector3
var movement_speed := 1.15
var personality := &"sakin"
var limboai_available := false


func configure(target_actor: Node3D, role: StringName, anchor: Vector3) -> void:
	actor = target_actor
	home_position = anchor
	personality = role
	work_position = anchor + Vector3(3.2, 0.0, -2.4)
	rest_position = anchor + Vector3(-1.6, 0.0, 1.8)
	shelter_position = Vector3(17.0, anchor.y, 15.0)
	target_position = rest_position
	limboai_available = ClassDB.class_exists(&"BTPlayer") or ClassDB.class_exists(&"LimboHSM")
	actor.set_meta("ai_backend", "LimboAI schedule bridge" if limboai_available else "safe schedule fallback")
	actor.set_meta("personality", personality)


func advance(delta: float, hour: float, raining: bool, animal_position := Vector3.INF) -> void:
	if actor == null:
		return
	var next_activity := _choose_activity(hour, raining, animal_position)
	if next_activity != activity:
		activity = next_activity
		target_position = _target_for_activity(animal_position)
	var flat_delta := target_position - actor.global_position
	flat_delta.y = 0.0
	if flat_delta.length_squared() > 0.12:
		var direction := flat_delta.normalized()
		actor.global_position += direction * minf(movement_speed * delta, flat_delta.length())
		actor.rotation.y = lerp_angle(actor.rotation.y, atan2(direction.x, direction.z), delta * 4.0)
		actor.position.y = home_position.y


func activity_name() -> String:
	return ["çalışıyor", "dinleniyor", "yağmurdan korunuyor", "hayvanlarla ilgileniyor"][activity]


func _choose_activity(hour: float, raining: bool, animal_position: Vector3) -> Activity:
	if raining:
		return Activity.SHELTER
	if animal_position != Vector3.INF and int(hour * 10.0) % 19 == 0:
		return Activity.ANIMAL_FRIEND
	if (hour >= 8.0 and hour < 12.0) or (hour >= 14.0 and hour < 18.0):
		return Activity.WORK
	return Activity.REST


func _target_for_activity(animal_position: Vector3) -> Vector3:
	match activity:
		Activity.WORK:
			return work_position
		Activity.SHELTER:
			return shelter_position
		Activity.ANIMAL_FRIEND:
			return animal_position if animal_position != Vector3.INF else rest_position
		_:
			return rest_position
