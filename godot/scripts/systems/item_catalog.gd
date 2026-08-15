class_name GardenItemCatalog
extends RefCounted

const DATA_PATH := "res://data/items/garden_items.json"
const CATEGORY_NAMES := {
	"tool": "ALET",
	"equipment": "EKİPMAN",
	"consumable": "SARF MALZEMESİ",
	"seed": "TOHUM",
	"material": "MALZEME",
	"misc": "DİĞER"
}

static var _items: Dictionary = {}


static func get_item(item_id: String) -> Dictionary:
	_ensure_loaded()
	return Dictionary(_items.get(item_id, {})).duplicate(true)


static func has_item(item_id: String) -> bool:
	_ensure_loaded()
	return _items.has(item_id)


static func get_all_ids() -> PackedStringArray:
	_ensure_loaded()
	var ids := PackedStringArray()
	for item_id: Variant in _items.keys():
		if str(item_id) != "bahce_esyasi":
			ids.append(str(item_id))
	return ids


static func category_name(category: String) -> String:
	return str(CATEGORY_NAMES.get(category, "DİĞER"))


static func accent(item: Dictionary) -> Color:
	return Color(str(item.get("accent", "8aa06e")))


static func _ensure_loaded() -> void:
	if not _items.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Eşya kataloğu açılamadı: %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Eşya kataloğu geçerli JSON değil.")
		return
	var raw := parsed as Dictionary
	for item_id: Variant in raw.keys():
		_items[str(item_id)] = _resolve_item(str(item_id), raw, {})


static func _resolve_item(item_id: String, raw: Dictionary, resolving: Dictionary) -> Dictionary:
	if not raw.has(item_id) or resolving.has(item_id):
		return {}
	resolving[item_id] = true
	var item := Dictionary(raw[item_id]).duplicate(true)
	var parent_id := str(item.get("inherits", ""))
	var resolved := _resolve_item(parent_id, raw, resolving) if not parent_id.is_empty() else {}
	for key: Variant in item.keys():
		if str(key) != "inherits":
			resolved[key] = item[key]
	resolved["id"] = item_id
	return resolved
