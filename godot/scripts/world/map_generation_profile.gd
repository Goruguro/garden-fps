class_name MapGenerationProfile
extends Resource

@export_category("Kimlik")
@export var profile_id := &"home_garden"
@export var display_name := "Ev Bahçesi"
@export var seed := 481516
@export_enum("garden", "formal_garden", "forest", "giant_garden") var biome_type := "garden"

@export_category("Arazi")
@export_enum("gentle", "rolling", "terraced", "hummocks") var terrain_style := "rolling"
@export_range(0.0, 0.3, 0.005) var terrain_amplitude := 0.04
@export_range(0.001, 0.03, 0.0005) var terrain_broad_frequency := 0.0045
@export_range(0.003, 0.08, 0.001) var terrain_detail_frequency := 0.018
@export_range(0.0, 1.0, 0.05) var terrain_ridge_strength := 0.22

@export_category("Çim Dağılımı")
@export_range(0.25, 1.5, 0.05) var grass_density := 1.0
@export_range(0.1, 5.0, 0.05) var grass_min_height := 0.48
@export_range(0.1, 6.0, 0.05) var grass_max_height := 1.48
@export_range(0.005, 0.12, 0.001) var grass_patch_frequency := 0.022
@export_range(0.005, 0.2, 0.001) var grass_detail_frequency := 0.058
@export_range(0.005, 0.12, 0.001) var grass_density_frequency := 0.031

@export_category("Çim Biçimi")
@export_range(0.0, 1.0, 0.01) var grass_mirror_chance := 0.45
@export_range(0.0, 1.0, 0.01) var grass_tilt_chance := 0.58
@export_range(0.0, 18.0, 0.5) var grass_max_tilt_degrees := 8.0
@export_range(0.0, 1.0, 0.01) var grass_shape_variation := 0.9

@export_category("Ağaçlar ve Bitkiler")
@export_range(0, 300, 1) var tree_count := 22
@export_range(0, 800, 1) var understory_count := 105
@export var tree_scale_range := Vector2(0.82, 1.2)
@export var plant_scale_range := Vector2(0.72, 1.28)
@export_range(1.0, 12.0, 0.1) var tree_spacing := 4.1

@export_category("Model Biçim Çeşitliliği")
@export var tree_width_multiplier_range := Vector2(0.78, 1.28)
@export var tree_height_multiplier_range := Vector2(0.82, 1.32)
@export_range(0.0, 1.0, 0.01) var tree_mirror_chance := 0.28
@export_range(0.0, 14.0, 0.5) var tree_max_tilt_degrees := 3.5
@export_range(0.0, 1.0, 0.01) var plant_mirror_chance := 0.48
@export_range(0.0, 18.0, 0.5) var plant_max_tilt_degrees := 8.0

@export_category("Çit Dışı Biyom Halkası")
@export_range(40.0, 180.0, 1.0) var outer_ring_start := 48.0
@export_range(50.0, 240.0, 1.0) var outer_ring_end := 118.0
@export_range(0, 500, 1) var outer_tree_count := 90
@export_range(0, 1400, 1) var outer_plant_count := 280
@export_range(0, 30000, 100) var outer_grass_count := 9000
@export var outer_grass_height_range := Vector2(0.38, 1.15)

@export_category("Model Kullanım Oranları")
@export_multiline var weight_help := "Değer 0 ise model kullanılmaz. Değer büyüdükçe model daha sık seçilir. Listede olmayan modeller 1.0 ağırlık kullanır."
@export var tree_weights: Dictionary = {}
@export var plant_weights: Dictionary = {}


func get_tree_weight(asset_name: String) -> float:
	return maxf(float(tree_weights.get(asset_name, 1.0)), 0.0)


func get_plant_weight(asset_name: String) -> float:
	return maxf(float(plant_weights.get(asset_name, 1.0)), 0.0)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if grass_max_height < grass_min_height:
		errors.append("Çim maksimum yüksekliği minimumdan küçük olamaz.")
	if tree_scale_range.y < tree_scale_range.x:
		errors.append("Ağaç ölçek aralığı ters girilmiş.")
	if plant_scale_range.y < plant_scale_range.x:
		errors.append("Bitki ölçek aralığı ters girilmiş.")
	if outer_ring_end <= outer_ring_start:
		errors.append("Dış biyom halkasının bitişi başlangıcından büyük olmalı.")
	if tree_width_multiplier_range.y < tree_width_multiplier_range.x or tree_height_multiplier_range.y < tree_height_multiplier_range.x:
		errors.append("Ağaç en-boy çarpanı aralığı ters girilmiş.")
	if _sum_positive_weights(tree_weights) <= 0.0 and not tree_weights.is_empty():
		errors.append("En az bir ağaç modelinin ağırlığı sıfırdan büyük olmalı.")
	if _sum_positive_weights(plant_weights) <= 0.0 and not plant_weights.is_empty():
		errors.append("En az bir alt bitki modelinin ağırlığı sıfırdan büyük olmalı.")
	return errors


func _sum_positive_weights(weights: Dictionary) -> float:
	var total := 0.0
	for value: Variant in weights.values():
		total += maxf(float(value), 0.0)
	return total
