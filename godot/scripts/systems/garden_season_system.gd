class_name GardenSeasonSystem
extends Node

signal season_changed(index: int, title: String)
signal day_changed(day: int)

const SEASONS := [
	{"id": &"ilkbahar", "title": "İlkbahar", "tint": Color("d8f1c4"), "growth": 1.20, "rain": 1.25},
	{"id": &"yaz", "title": "Yaz", "tint": Color("f4e3a5"), "growth": 1.05, "rain": 0.65},
	{"id": &"sonbahar", "title": "Sonbahar", "tint": Color("d69a64"), "growth": 0.82, "rain": 1.10},
	{"id": &"kis", "title": "Kış", "tint": Color("c9dce2"), "growth": 0.45, "rain": 0.72},
]

var session: GameSession
var last_hour := 0.0


func configure(active_session: GameSession) -> void:
	session = active_session
	last_hour = session.world_hour
	season_changed.emit(session.season_index, season_title())


func advance(hour: float) -> void:
	if session == null:
		return
	if hour + 0.01 < last_hour:
		session.world_day += 1
		day_changed.emit(session.world_day)
		if session.world_day > 1 and (session.world_day - 1) % 7 == 0:
			session.season_index = (session.season_index + 1) % SEASONS.size()
			season_changed.emit(session.season_index, season_title())
		session.save()
	last_hour = hour


func season_data() -> Dictionary:
	return SEASONS[clampi(session.season_index if session != null else 0, 0, SEASONS.size() - 1)]


func season_title() -> String:
	return str(season_data().title)


func tint() -> Color:
	return season_data().tint


func growth_multiplier() -> float:
	return float(season_data().growth)


func rain_multiplier() -> float:
	return float(season_data().rain)
