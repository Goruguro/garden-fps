class_name GameSession
extends RefCounted

const SAVE_PATH := "user://garden_rebuild_save.json"

var money: int = 120
var mission_stage: int = 0
var grass_cut: int = 0
var grass_goal: int = 12
var selected_tool: String = "trimmer"
var owned_tools: PackedStringArray = PackedStringArray(["trimmer"])
var condition: Dictionary = {"trimmer": 100.0, "shears": 100.0}
var maintenance: Dictionary = {"trimmer": 100.0, "shears": 100.0}
var fuel: Dictionary = {"trimmer": 100.0}
var world_hour: float = 9.25
var current_level_id := &"home_garden"
var inventory: Dictionary = {}
var shaped_plants: Dictionary = {}
var world_day: int = 1
var season_index: int = 0
var crop_progress: Dictionary = {}
var fertilizer_bonus: float = 0.0
var irrigation_owned: bool = true
var irrigation_enabled: bool = true


func new_game() -> void:
	money = 120
	mission_stage = 0
	grass_cut = 0
	selected_tool = "trimmer"
	owned_tools = PackedStringArray(["trimmer"])
	condition = {"trimmer": 100.0, "shears": 100.0}
	maintenance = {"trimmer": 100.0, "shears": 100.0}
	fuel = {"trimmer": 100.0}
	world_hour = 9.25
	current_level_id = &"home_garden"
	inventory = _starter_inventory()
	shaped_plants = {}
	world_day = 1
	season_index = 0
	crop_progress = {}
	fertilizer_bonus = 0.0
	irrigation_owned = true
	irrigation_enabled = true


func save() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return true


func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return false
	from_dict(data)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func to_dict() -> Dictionary:
	return {
		"version": 7,
		"money": money,
		"mission_stage": mission_stage,
		"grass_cut": grass_cut,
		"selected_tool": selected_tool,
		"owned_tools": Array(owned_tools),
		"condition": condition.duplicate(true),
		"maintenance": maintenance.duplicate(true),
		"fuel": fuel.duplicate(true),
		"world_hour": world_hour,
		"current_level_id": String(current_level_id),
		"inventory": inventory.duplicate(true),
		"shaped_plants": shaped_plants.duplicate(true),
		"world_day": world_day,
		"season_index": season_index,
		"crop_progress": crop_progress.duplicate(true),
		"fertilizer_bonus": fertilizer_bonus,
		"irrigation_owned": irrigation_owned,
		"irrigation_enabled": irrigation_enabled,
	}


func from_dict(data: Dictionary) -> void:
	money = int(data.get("money", 120))
	mission_stage = clampi(int(data.get("mission_stage", 0)), 0, 4)
	grass_cut = clampi(int(data.get("grass_cut", 0)), 0, grass_goal)
	selected_tool = str(data.get("selected_tool", "trimmer"))
	owned_tools = PackedStringArray(data.get("owned_tools", ["trimmer"]))
	condition = Dictionary(data.get("condition", condition)).duplicate(true)
	maintenance = Dictionary(data.get("maintenance", maintenance)).duplicate(true)
	fuel = Dictionary(data.get("fuel", {"trimmer": 100.0})).duplicate(true)
	fuel["trimmer"] = clampf(float(fuel.get("trimmer", 100.0)), 0.0, 100.0)
	world_hour = float(data.get("world_hour", 9.25))
	current_level_id = StringName(data.get("current_level_id", "home_garden"))
	var saved_inventory: Variant = data.get("inventory", null)
	inventory = Dictionary(saved_inventory).duplicate(true) if saved_inventory is Dictionary else _starter_inventory()
	shaped_plants = Dictionary(data.get("shaped_plants", {})).duplicate(true)
	world_day = maxi(1, int(data.get("world_day", 1)))
	season_index = clampi(int(data.get("season_index", 0)), 0, 3)
	crop_progress = Dictionary(data.get("crop_progress", {})).duplicate(true)
	fertilizer_bonus = clampf(float(data.get("fertilizer_bonus", 0.0)), 0.0, 0.85)
	irrigation_owned = bool(data.get("irrigation_owned", true))
	irrigation_enabled = bool(data.get("irrigation_enabled", true))
	_sanitize_inventory()
	if not WorldLevelCatalog.is_valid(current_level_id) or not is_level_unlocked(current_level_id):
		current_level_id = &"home_garden"
	if not owned_tools.has(selected_tool):
		selected_tool = "trimmer"
	_sync_tool_items()


func add_item(item_id: String, amount := 1) -> int:
	if amount <= 0 or not GardenItemCatalog.has_item(item_id):
		return get_item_count(item_id)
	inventory[item_id] = get_item_count(item_id) + amount
	return int(inventory[item_id])


func remove_item(item_id: String, amount := 1) -> bool:
	if amount <= 0 or get_item_count(item_id) < amount:
		return false
	var remaining := get_item_count(item_id) - amount
	if remaining <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = remaining
	return true


func get_item_count(item_id: String) -> int:
	return maxi(0, int(inventory.get(item_id, 0)))


func inventory_item_count() -> int:
	var total := 0
	for amount: Variant in inventory.values():
		total += maxi(0, int(amount))
	return total


func grant_first_job_reward() -> void:
	add_item("gubre", 2)
	add_item("kir_cicegi_tohumu", 6)
	add_item("ot_demeti", grass_goal)


func register_owned_tool_item(tool_id: String) -> void:
	var item_id := "buyuk_makas" if tool_id == "shears" else "eski_tirpan"
	if get_item_count(item_id) <= 0:
		add_item(item_id)


func mark_plant_shaped(level_id: StringName, plant_id: String) -> void:
	shaped_plants["%s/%s" % [level_id, plant_id]] = true


func is_plant_shaped(level_id: StringName, plant_id: String) -> bool:
	return bool(shaped_plants.get("%s/%s" % [level_id, plant_id], false))


func _starter_inventory() -> Dictionary:
	return {
		"eski_tirpan": 1,
		"is_eldiveni": 1,
		"sulama_kabi": 1
	}


func _sanitize_inventory() -> void:
	for item_id: Variant in inventory.keys():
		if not GardenItemCatalog.has_item(str(item_id)) or int(inventory[item_id]) <= 0:
			inventory.erase(item_id)
		else:
			inventory[item_id] = int(inventory[item_id])


func _sync_tool_items() -> void:
	for tool_id in owned_tools:
		register_owned_tool_item(tool_id)


func is_level_unlocked(level_id: StringName) -> bool:
	return WorldLevelCatalog.is_unlocked(level_id, mission_stage)


func select_level(level_id: StringName) -> bool:
	if not WorldLevelCatalog.is_valid(level_id) or not is_level_unlocked(level_id):
		return false
	current_level_id = level_id
	return true


func wear_tool(tool_id: String, condition_loss: float, maintenance_loss: float) -> bool:
	var current_condition := float(condition.get(tool_id, 100.0))
	var current_maintenance := float(maintenance.get(tool_id, 100.0))
	if current_condition <= 0.0:
		return false
	var failure_risk := clampf((100.0 - current_maintenance) * 0.0025 + (100.0 - current_condition) * 0.001, 0.0, 0.32)
	if randf() < failure_risk:
		condition[tool_id] = maxf(0.0, current_condition - 4.0)
		return false
	condition[tool_id] = maxf(0.0, current_condition - condition_loss)
	maintenance[tool_id] = maxf(0.0, current_maintenance - maintenance_loss)
	return true


func consume_fuel(tool_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return float(fuel.get(tool_id, 0.0)) > 0.0
	var remaining := float(fuel.get(tool_id, 0.0))
	if remaining <= 0.0:
		return false
	fuel[tool_id] = maxf(0.0, remaining - amount)
	return float(fuel[tool_id]) > 0.0


func repair_selected_tool() -> int:
	var condition_value := float(condition.get(selected_tool, 100.0))
	var maintenance_value := float(maintenance.get(selected_tool, 100.0))
	var cost := maxi(15, int((200.0 - condition_value - maintenance_value) * 0.55))
	var fuel_value := float(fuel.get(selected_tool, 100.0))
	if condition_value >= 99.9 and maintenance_value >= 99.9 and fuel_value >= 99.9:
		return 0
	if money < cost:
		return -cost
	money -= cost
	condition[selected_tool] = 100.0
	maintenance[selected_tool] = 100.0
	if selected_tool == "trimmer":
		fuel[selected_tool] = 100.0
	return cost
