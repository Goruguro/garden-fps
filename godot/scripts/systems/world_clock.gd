class_name GardenWorldClock
extends Node

signal time_changed(hour: float, daylight: float)

@export var game_minutes_per_second := 1.08

var session: GameSession


func configure(active_session: GameSession) -> void:
	session = active_session
	emit_current_time()


func advance(delta: float) -> void:
	if session == null:
		return
	session.world_hour = fposmod(session.world_hour + delta * game_minutes_per_second / 60.0, 24.0)
	emit_current_time()


func daylight_strength() -> float:
	if session == null:
		return 1.0
	return clampf(sin((session.world_hour - 6.0) / 12.0 * PI), 0.04, 1.0)


func formatted_time() -> String:
	if session == null:
		return "--:--"
	return "%02d:%02d" % [int(session.world_hour), int(fposmod(session.world_hour, 1.0) * 60.0)]


func emit_current_time() -> void:
	if session != null:
		time_changed.emit(session.world_hour, daylight_strength())
