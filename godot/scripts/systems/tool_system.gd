class_name GardenToolSystem
extends Node

signal changed
signal message_requested(text: String, duration: float)

const SHEARS_PRICE := 250
const TRIMMER_FUEL_PER_SECOND := 0.82
const TRIMMER_MIN_SWEEP_SPEED := 0.24
const TRIMMER_MAX_SWEEP_SPEED := 2.65

var session: GameSession


func configure(active_session: GameSession) -> void:
	session = active_session


func try_use(tool_id: String) -> bool:
	if session == null:
		return false
	var condition_loss := 1.4 if tool_id == "trimmer" else 0.8
	var maintenance_loss := 2.6 if tool_id == "trimmer" else 1.2
	if session.wear_tool(tool_id, condition_loss, maintenance_loss):
		changed.emit()
		return true
	message_requested.emit("%s tekledi. Atölyede bakım yaptır." % display_name(tool_id), 3.0)
	changed.emit()
	return false


func can_start_trimmer() -> bool:
	if session == null:
		return false
	if float(session.condition.get("trimmer", 100.0)) <= 0.0:
		message_requested.emit("Tırpan çalışmıyor. Atölyede bakım yaptır.", 2.8)
		return false
	if float(session.fuel.get("trimmer", 0.0)) <= 0.0:
		message_requested.emit("Tırpanın benzini bitti. Atölyede depoyu doldur.", 2.8)
		return false
	return true


func consume_trimmer_fuel(delta: float) -> bool:
	if session == null:
		return false
	return session.consume_fuel("trimmer", TRIMMER_FUEL_PER_SECOND * maxf(delta, 0.0))


func is_valid_trimmer_sweep(speed: float) -> bool:
	return speed >= TRIMMER_MIN_SWEEP_SPEED and speed <= TRIMMER_MAX_SWEEP_SPEED


func register_grass_contact(cluster_count: int) -> bool:
	if session == null or cluster_count <= 0:
		return false
	# Engine runtime consumes fuel; only vegetation resistance wears the machine.
	var condition_loss := clampf(float(cluster_count) * 0.006, 0.025, 0.34)
	var maintenance_loss := clampf(float(cluster_count) * 0.012, 0.05, 0.68)
	if session.wear_tool("trimmer", condition_loss, maintenance_loss):
		changed.emit()
		return true
	message_requested.emit("Tırpan otların içinde tekledi. Bakım yaptırmalısın.", 2.5)
	changed.emit()
	return false


func switch_to_next() -> String:
	if session == null or session.owned_tools.size() < 2:
		message_requested.emit("Henüz başka bir aletin yok.", 2.5)
		return ""
	var index := session.owned_tools.find(session.selected_tool)
	session.selected_tool = session.owned_tools[(index + 1) % session.owned_tools.size()]
	message_requested.emit("Alet: %s" % display_name(session.selected_tool), 2.0)
	_save_and_notify()
	return session.selected_tool


func use_workshop() -> StringName:
	if session == null:
		return &""
	if session.mission_stage >= 3 and not session.owned_tools.has("shears"):
		if session.money < SHEARS_PRICE:
			message_requested.emit("Büyük bahçe makası 250 ₺. Yeterli paran yok.", 3.0)
			return &"workshop_no_money"
		session.money -= SHEARS_PRICE
		session.owned_tools.append("shears")
		session.register_owned_tool_item("shears")
		session.selected_tool = "shears"
		session.mission_stage = 4
		message_requested.emit("Büyük bahçe makası alındı. Q ile alet değiştirebilirsin.", 4.0)
		_save_and_notify()
		return &"workshop_upgrade"
	var repair_result := session.repair_selected_tool()
	if repair_result > 0:
		message_requested.emit("%s bakımı tamamlandı: %d ₺" % [display_name(session.selected_tool), repair_result], 3.0)
	elif repair_result == 0:
		message_requested.emit("Bu alet zaten kusursuz durumda.", 2.5)
	else:
		message_requested.emit("Bakım için %d ₺ gerekiyor." % abs(repair_result), 2.5)
	_save_and_notify()
	return &"workshop_maintenance"


static func display_name(tool_id: String) -> String:
	return "Büyük Bahçe Makası" if tool_id == "shears" else "Benzinli Tırpan"


func _save_and_notify() -> void:
	session.save()
	changed.emit()
