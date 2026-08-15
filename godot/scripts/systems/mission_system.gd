class_name GardenMissionSystem
extends Node

signal changed
signal message_requested(text: String, duration: float)

const PAYOUT := 260

var session: GameSession


func configure(active_session: GameSession) -> void:
	session = active_session


func interact_with_mira() -> StringName:
	if session == null:
		return &""
	var dialogue_title: StringName
	match session.mission_stage:
		0:
			session.mission_stage = 1
			dialogue_title = &"mira_job_offer"
		1:
			dialogue_title = &"mira_job_progress"
		2:
			session.money += PAYOUT
			session.grant_first_job_reward()
			session.mission_stage = 3
			dialogue_title = &"mira_job_complete"
		3:
			dialogue_title = &"mira_upgrade_hint"
		_:
			dialogue_title = &"mira_after_upgrade"
	_save_and_notify()
	return dialogue_title


func can_cut_grass() -> bool:
	return session != null and session.mission_stage == 1


func register_grass_cut() -> void:
	if session == null:
		return
	session.grass_cut = mini(session.grass_goal, session.grass_cut + 1)
	if session.grass_cut >= session.grass_goal:
		session.mission_stage = 2
		message_requested.emit("Alan temiz! Ödemen için Mira'ya dön.", 4.0)
	else:
		message_requested.emit("Temizlenen ot: %d / %d" % [session.grass_cut, session.grass_goal], 1.4)
	_save_and_notify()


func get_task() -> Dictionary:
	if session == null:
		return {"title": "HAZIRLANIYOR", "detail": "Bahçe yükleniyor."}
	match session.mission_stage:
		0:
			return {"title": "GÜNE BAŞLA", "detail": "Mira ile konuş ve ilk işi öğren."}
		1:
			return {"title": "DERE KENARI TEMİZLİĞİ", "detail": "Uzun otları biç: %d / %d" % [session.grass_cut, session.grass_goal]}
		2:
			return {"title": "İŞ TAMAMLANDI", "detail": "Ödemeni almak için Mira'ya dön."}
		3:
			return {"title": "İLK YÜKSELTME", "detail": "Ödüllerin çantanda. Atölyeden büyük bahçe makasını satın al."}
		_:
			return {"title": "BAHÇE USTASI", "detail": "İlk oynanış döngüsü tamamlandı."}


func _save_and_notify() -> void:
	session.save()
	changed.emit()
