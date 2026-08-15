class_name WorldLevelCatalog
extends RefCounted

const HOME_GARDEN_PROFILE := preload("res://data/maps/profiles/home_garden.tres")
const SHAPING_ESTATE_PROFILE := preload("res://data/maps/profiles/shaping_estate.tres")
const FOREST_PATH_PROFILE := preload("res://data/maps/profiles/forest_path.tres")
const GIANT_GARDEN_PROFILE := preload("res://data/maps/profiles/giant_garden.tres")

const ORDER: Array[StringName] = [
	&"home_garden",
	&"shaping_estate",
	&"forest_path",
	&"giant_garden",
]

const LEVELS := {
	&"home_garden": {
		"number": "01",
		"title": "EV BAHÇESİ",
		"description": "Mira, atölye ve Yuzu\nÇayır işleri ve ilk yükseltme",
		"unlock_stage": 0,
		"seed": 481516,
		"tree_count": 22,
		"understory_count": 105,
		"tree_scale": Vector2(0.82, 1.2),
		"plant_scale": Vector2(0.72, 1.28),
		"spawn": Vector3(3.5, 1.1, 27.0),
		"generation_profile": HOME_GARDEN_PROFILE,
	},
	&"shaping_estate": {
		"number": "02",
		"title": "ŞEKİLLENDİRME MALİKÂNESİ",
		"description": "Büyük makas işleri\nÇitler, bonsailer ve heykeller",
		"unlock_stage": 2,
		"seed": 725113,
		"tree_count": 28,
		"understory_count": 150,
		"tree_scale": Vector2(0.72, 1.02),
		"plant_scale": Vector2(0.6, 1.05),
		"spawn": Vector3(0.0, 1.1, 27.0),
		"generation_profile": SHAPING_ESTATE_PROFILE,
	},
	&"forest_path": {
		"number": "03",
		"title": "ORMAN YOLU",
		"description": "Defne'nin görevleri\nYabani otlar ve odunculuk",
		"unlock_stage": 3,
		"seed": 931247,
		"tree_count": 78,
		"understory_count": 235,
		"tree_scale": Vector2(0.9, 1.42),
		"plant_scale": Vector2(0.75, 1.5),
		"spawn": Vector3(0.0, 1.1, 30.0),
		"generation_profile": FOREST_PATH_PROFILE,
	},
	&"giant_garden": {
		"number": "04",
		"title": "DEVASA BAHÇE",
		"description": "Küçülmüş ölçekte keşif\nDev bitkiler ve Mini'nin işleri",
		"unlock_stage": 4,
		"seed": 340117,
		"tree_count": 34,
		"understory_count": 185,
		"tree_scale": Vector2(2.4, 4.2),
		"plant_scale": Vector2(2.5, 5.2),
		"spawn": Vector3(0.0, 1.1, 28.0),
		"generation_profile": GIANT_GARDEN_PROFILE,
	},
}


static func get_level(level_id: StringName) -> Dictionary:
	return Dictionary(LEVELS.get(level_id, LEVELS[&"home_garden"])).duplicate(true)


static func get_generation_profile(level_id: StringName) -> MapGenerationProfile:
	var level := LEVELS.get(level_id, LEVELS[&"home_garden"]) as Dictionary
	return level["generation_profile"] as MapGenerationProfile


static func is_valid(level_id: StringName) -> bool:
	return LEVELS.has(level_id)


static func is_unlocked(level_id: StringName, mission_stage: int) -> bool:
	return mission_stage >= int(get_level(level_id).get("unlock_stage", 0))
