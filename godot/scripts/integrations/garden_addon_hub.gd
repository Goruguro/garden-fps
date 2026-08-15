class_name GardenAddonHub
extends Node

signal inventory_changed
signal quest_changed

const PROTOSET_PATH := "res://data/items/garden_items.json"

var inventory: Inventory
var quest_manager: QuestSystemManagerAPI
var first_job: Quest
var capabilities: Dictionary = {}


func configure() -> void:
	capabilities = {
		"terrain_3d": ClassDB.class_exists(&"Terrain3D"),
		"limbo_ai": ClassDB.class_exists(&"LimboHSM") or ClassDB.class_exists(&"BTPlayer"),
		"gloot": FileAccess.file_exists("res://addons/gloot/core/inventory.gd"),
		"quest_system": FileAccess.file_exists("res://addons/quest_system/quest_manager.gd"),
		"phantom_camera": FileAccess.file_exists("res://addons/phantom_camera/plugin.cfg"),
		"proton_scatter": FileAccess.file_exists("res://addons/proton_scatter/plugin.cfg"),
		"simple_asset_placer": FileAccess.file_exists("res://addons/simpleassetplacer/plugin.cfg"),
		"sky_3d": ClassDB.class_exists(&"Sky3D"),
		"state_charts": ClassDB.class_exists(&"StateChart"),
		"boujie_water": ClassDB.class_exists(&"Ocean"),
	}
	_setup_inventory()
	_setup_quests()


func _setup_inventory() -> void:
	if not capabilities.gloot:
		return
	inventory = Inventory.new()
	inventory.name = "GardenInventory"
	var protoset_resource := load(PROTOSET_PATH) as JSON
	if protoset_resource == null:
		push_warning("GLoot eşya kataloğu yüklenemedi.")
		return
	inventory.protoset = protoset_resource
	add_child(inventory)
	for prototype_id in ["eski_tirpan", "is_eldiveni", "sulama_kabi"]:
		inventory.create_and_add_item(prototype_id)
	inventory.item_added.connect(func(_item: InventoryItem) -> void: inventory_changed.emit())
	inventory.item_removed.connect(func(_item: InventoryItem) -> void: inventory_changed.emit())


func _setup_quests() -> void:
	if not capabilities.quest_system:
		return
	quest_manager = QuestSystemManagerAPI.new()
	quest_manager.name = "QuestSystem"
	add_child(quest_manager)
	first_job = Quest.new()
	first_job.id = 1001
	first_job.quest_name = "Mira'nın İlk İşi"
	first_job.quest_description = "Başlangıç bahçesindeki uzun otları biç ve Mira'ya dön."
	first_job.quest_objective = "12 uzun ot kümesini tırpanla biç."
	quest_manager.mark_quest_as_available(first_job)
	quest_manager.quest_accepted.connect(func(_quest: Quest) -> void: quest_changed.emit())
	quest_manager.quest_completed.connect(func(_quest: Quest) -> void: quest_changed.emit())


func sync_mission_stage(stage: int, grass_cut: int, grass_goal: int) -> void:
	if quest_manager == null or first_job == null:
		return
	if stage >= 1 and quest_manager.is_quest_available(first_job):
		quest_manager.start_quest(first_job, {"grass_goal": grass_goal})
	if stage >= 1 and stage < 3:
		first_job.objective_completed = grass_cut >= grass_goal
		quest_manager.update_quest(first_job, {"grass_cut": grass_cut, "grass_goal": grass_goal})
	if stage >= 3 and first_job.objective_completed:
		quest_manager.complete_quest(first_job, {"grass_cut": grass_cut})


func sync_inventory(session_inventory: Dictionary) -> void:
	if inventory == null:
		return
	inventory.clear()
	var prototype_ids := session_inventory.keys()
	prototype_ids.sort()
	for prototype_value: Variant in prototype_ids:
		var prototype_id := str(prototype_value)
		var remaining := maxi(0, int(session_inventory.get(prototype_id, 0)))
		while remaining > 0:
			var item := inventory.create_and_add_item(prototype_id)
			if item == null:
				break
			var stack_amount := mini(remaining, item.get_max_stack_size())
			item.set_stack_size(stack_amount)
			remaining -= stack_amount


func status_text() -> String:
	var active: PackedStringArray = []
	for key in capabilities:
		if capabilities[key]:
			active.append(str(key))
	return ", ".join(active)
