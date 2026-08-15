extends SceneTree

const DENSE_GRASS_SCRIPT := preload("res://scripts/vegetation/dense_grass_field.gd")


class DummyHeightProvider:
	extends Node3D
	func get_height(_pos: Vector3) -> float:
		return 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dummy_height_provider := DummyHeightProvider.new()
	root.add_child(dummy_height_provider)

	var field := DENSE_GRASS_SCRIPT.new() as DenseGrassField
	dummy_height_provider.add_child(field)
	field.build(dummy_height_provider, &"home_garden")

	assert(field.growth_image != null, "Growth image oluşturulamadı")
	assert(field.growth_texture != null, "Growth texture oluşturulamadı")
	assert(field.growth_grid.size() == 64 * 64, "Growth grid boyutu 4096 olmalı")

	# 1. Başlangıç Yükseklikleri Kontrolü
	var initial_sum := 0.0
	for val: float in field.growth_grid:
		assert(val >= 0.65 and val <= 0.95, "Başlangıç çim boyu doğal sınırların dışında: %f" % val)
		initial_sum += val
	var initial_avg := initial_sum / float(field.growth_grid.size())

	# 2. Kesim Alanı ve Bekleme Süresi Kontrolü
	var cut_center := Vector3(0.0, 0.0, 0.0)
	var removed := field.cut_at(cut_center, 3.5, false)
	assert(removed > 0, "Çim kesimi gerçekleşmedi")

	var center_u := clampf((cut_center.x - DenseGrassField.FIELD_MIN.x) / (DenseGrassField.FIELD_MAX.x - DenseGrassField.FIELD_MIN.x), 0.0, 1.0)
	var center_v := clampf((cut_center.z - DenseGrassField.FIELD_MIN.y) / (DenseGrassField.FIELD_MAX.y - DenseGrassField.FIELD_MIN.y), 0.0, 1.0)
	var center_px := int(center_u * 63.0)
	var center_py := int(center_v * 63.0)
	var center_idx := center_py * 64 + center_px

	assert(field.growth_grid[center_idx] <= 0.10, "Kesilen çim boyu 0.08 dip sapına inmedi: %f" % field.growth_grid[center_idx])
	assert(field.regrow_wait_grid[center_idx] > 30.0, "Kesilen çime bekleme süresi atanmadı")

	# 3. Bekleme Süresi Boyunca Kısa Kalma
	field.advance_growth(24.0) # 1 oyun günü ilerlet
	assert(field.growth_grid[center_idx] <= 0.10, "Çim bekleme süresi dolmadan uzamaya başladı")

	# 4. Bekleme Süresi Bitince Yeniden Büyüme
	field.advance_growth(100.0) # Bekleme süresini bitir
	assert(field.regrow_wait_grid[center_idx] == 0.0, "Bekleme süresi sıfırlanmadı")
	assert(field.growth_grid[center_idx] > 0.08, "Çim bekleme süresi bitince uzamadı: %f" % field.growth_grid[center_idx])

	# 5. 1 Aylık Simülasyon (720 Saat) & %80 Doygunluk Dengesi
	field.advance_growth(720.0)

	var max_neighbor_diff := 0.0
	var final_sum := 0.0
	for y in range(64):
		for x in range(64):
			var idx := y * 64 + x
			var val := field.growth_grid[idx]
			final_sum += val
			if x < 63:
				var diff_x := absf(val - field.growth_grid[idx + 1])
				max_neighbor_diff = maxf(max_neighbor_diff, diff_x)
			if y < 63:
				var diff_y := absf(val - field.growth_grid[idx + 64])
				max_neighbor_diff = maxf(max_neighbor_diff, diff_y)

	var final_avg := final_sum / float(field.growth_grid.size())
	assert(final_avg >= 0.70 and final_avg <= 0.95, "1 aylık simülasyon sonrası çayır dengesi bozuldu: %f" % final_avg)
	assert(max_neighbor_diff <= 0.13, "Komşular arası boy farkı sınırı aşıldı: %f" % max_neighbor_diff)

	print("GRASS_GROWTH_OK: initial_avg=%.2f final_avg=%.2f max_neighbor_diff=%.3f cut_dip=%.2f regrow=true" % [
		initial_avg,
		final_avg,
		max_neighbor_diff,
		field.growth_grid[center_idx]
	])

	dummy_height_provider.free()
	quit()
