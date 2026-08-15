extends Node

const WORLD_SCENE := preload("res://scenes/rebuild/garden_world.tscn")
const UI := preload("res://scripts/presentation/garden_ui_theme.gd")

var session := GameSession.new()
var world: RebuiltGardenWorld
var menu_layer: CanvasLayer
var menu_root: Control
var home_panel: PanelContainer
var settings_panel: PanelContainer
var saves_panel: PanelContainer
var continue_button: Button
var save_summary_label: Label
var save_slot_label: Label
var save_slot_continue_button: Button
var new_game_dialog: ConfirmationDialog
var delete_save_dialog: ConfirmationDialog
var volume_slider: HSlider
var sensitivity_slider: HSlider
var quality_option: OptionButton
var font_option: OptionButton
var ui_scale_slider: HSlider
var fov_slider: HSlider
var fullscreen_check: CheckButton
var vsync_check: CheckButton
var fps_option: OptionButton
var reduced_motion_check: CheckButton
var crosshair_slider: HSlider
var ssao_check: CheckButton
var ssil_check: CheckButton
var sdfgi_check: CheckButton
var volumetric_fog_check: CheckButton
var dof_check: CheckButton
var decal_check: CheckButton
var minimap_check: CheckButton
var minimap_rotate_check: CheckButton
var minimap_range_slider: HSlider


func _ready() -> void:
	_ensure_input_actions()
	_build_menu()
	_apply_saved_preferences()
	_refresh_continue_button()
	_play_intro()


func _start_new_game() -> void:
	session.new_game()
	session.save()
	_start_world()


func _continue_game() -> void:
	if session.load_save():
		_start_world()


func _start_world() -> void:
	if world != null:
		var previous_world := world
		world = null
		remove_child(previous_world)
		previous_world.queue_free()
	world = WORLD_SCENE.instantiate() as RebuiltGardenWorld
	world.configure_level(session.current_level_id)
	add_child(world)
	world.setup(session)
	_apply_preferences(false)
	world.exit_to_menu.connect(_return_to_menu)
	world.level_change_requested.connect(_change_level)
	menu_layer.visible = false


func _change_level(level_id: StringName) -> void:
	if not session.select_level(level_id):
		return
	session.save()
	call_deferred("_start_world")


func _return_to_menu() -> void:
	if world != null:
		remove_child(world)
		world.queue_free()
		world = null
	menu_layer.visible = true
	_refresh_continue_button()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _request_new_game() -> void:
	if session.has_save():
		new_game_dialog.popup_centered()
	else:
		_start_new_game()


func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 20
	add_child(menu_layer)
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(menu_root)
	_build_art_background()
	_build_brand_story()
	_build_world_cards()
	home_panel = _build_home_panel()
	settings_panel = _build_settings_panel()
	saves_panel = _build_saves_panel()
	menu_root.add_child(home_panel)
	menu_root.add_child(settings_panel)
	menu_root.add_child(saves_panel)
	_build_footer()
	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.title = "Yeni Bahçe"
	new_game_dialog.dialog_text = "Eski kayıt korunmayacak. Yeni bir bahçe defteri açmak istiyor musun?"
	new_game_dialog.ok_button_text = "Yeni Bahçeyi Kur"
	new_game_dialog.cancel_button_text = "Vazgeç"
	new_game_dialog.confirmed.connect(_start_new_game)
	menu_root.add_child(new_game_dialog)
	delete_save_dialog = ConfirmationDialog.new()
	delete_save_dialog.title = "Kayıt Defteri"
	delete_save_dialog.dialog_text = "Bu kayıt kalıcı olarak silinecek. Bahçeyi kapatmak istediğine emin misin?"
	delete_save_dialog.ok_button_text = "Kaydı Sil"
	delete_save_dialog.cancel_button_text = "Vazgeç"
	delete_save_dialog.confirmed.connect(_delete_save)
	menu_root.add_child(delete_save_dialog)


func _build_art_background() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("b8d5c0"), Color("71977a"), Color("315640")])
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 1600
	texture.height = 900
	texture.fill_from = Vector2(0.15, 0.0)
	texture.fill_to = Vector2(0.9, 1.0)
	backdrop.texture = texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(backdrop)
	var sun := Polygon2D.new()
	sun.name = "SunIllustration"
	sun.polygon = PackedVector2Array([Vector2(0, -92), Vector2(66, -66), Vector2(92, 0), Vector2(66, 66), Vector2(0, 92), Vector2(-66, 66), Vector2(-92, 0), Vector2(-66, -66)])
	sun.position = Vector2(310, 145)
	sun.color = Color(0.97, 0.75, 0.31, 0.68)
	menu_root.add_child(sun)
	for index in range(5):
		var hill := Polygon2D.new()
		hill.polygon = PackedVector2Array([
			Vector2(-80, 900), Vector2(-80, 590 - index * 15), Vector2(220, 470 + index * 22),
			Vector2(530, 610 - index * 14), Vector2(820, 445 + index * 29), Vector2(1110, 620),
			Vector2(1430, 500 + index * 18), Vector2(1720, 570), Vector2(1720, 900)
		])
		hill.color = Color(0.13 + index * 0.025, 0.31 + index * 0.026, 0.20 + index * 0.018, 0.82)
		hill.position.y = index * 42
		menu_root.add_child(hill)
	for data in [[90, 705, 1.1], [230, 760, 0.75], [770, 715, 0.9], [930, 770, 0.65]]:
		_build_leaf_sprig(Vector2(data[0], data[1]), data[2])
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.04, 0.09, 0.055, 0.15)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(veil)


func _build_leaf_sprig(pos: Vector2, scale_value: float) -> void:
	var sprig := Control.new()
	sprig.position = pos
	sprig.scale = Vector2.ONE * scale_value
	sprig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(sprig)
	var stem := ColorRect.new()
	stem.color = Color("d6bd73")
	stem.position = Vector2(-2, -70)
	stem.size = Vector2(4, 140)
	stem.rotation = -0.32
	sprig.add_child(stem)
	for index in range(5):
		for side in [-1, 1]:
			var leaf := Polygon2D.new()
			leaf.polygon = PackedVector2Array([Vector2(0, 0), Vector2(25 * side, -10), Vector2(40 * side, 3), Vector2(22 * side, 16)])
			leaf.position = Vector2(index * -7, -48 + index * 25)
			leaf.color = Color("8fba73") if index % 2 == 0 else Color("6f9e62")
			sprig.add_child(leaf)


func _build_brand_story() -> void:
	var brand := VBoxContainer.new()
	brand.name = "BrandStory"
	brand.position = Vector2(78, 66)
	brand.size = Vector2(760, 350)
	brand.add_theme_constant_override("separation", 8)
	menu_root.add_child(brand)
	var eyebrow_row := HBoxContainer.new()
	eyebrow_row.add_theme_constant_override("separation", 10)
	var star := TextureRect.new()
	star.texture = UI.STAR_ICON
	star.custom_minimum_size = Vector2(28, 28)
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	eyebrow_row.add_child(star)
	eyebrow_row.add_child(UI.label("YEŞİL VADİ • 1. SEZON", 17, Color("fff2c6"), true))
	brand.add_child(eyebrow_row)
	var title := UI.label("BAHÇIVAN", 76, Color("fff9e8"), true)
	title.add_theme_color_override("font_shadow_color", Color(0.08, 0.16, 0.10, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 5)
	brand.add_child(title)
	var subtitle := UI.label("Toprağın ritmini bul, vadinin hikâyesini büyüt.", 25, Color("e7efd9"))
	brand.add_child(subtitle)
	var rule := UI.divider(Color("efd078"))
	rule.custom_minimum_size.x = 190
	brand.add_child(rule)
	var description := UI.label("Mira'nın küçük işleriyle başlayan yolculuk; bakımlı makineler, şekillenen bahçeler ve keşfedilecek tuhaf bölgelerle yaşayan bir çiftliğe dönüşüyor.", 17, Color("eff5e9"))
	description.custom_minimum_size.x = 700
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brand.add_child(description)


func _build_world_cards() -> void:
	var row := HBoxContainer.new()
	row.name = "WorldCards"
	row.position = Vector2(72, 445)
	row.size = Vector2(860, 175)
	row.add_theme_constant_override("separation", 14)
	menu_root.add_child(row)
	row.add_child(_info_card("BUGÜN", "Yumuşak gün ışığı", "Bahçe işleri için sakin bir sabah.", UI.GOLD))
	row.add_child(_info_card("HEDEF", "İlk profesyonel iş", "Mira ile konuş, 12 ot kümesini biç.", UI.LEAF))
	row.add_child(_info_card("VADİ", "4 farklı bölge", "Orman, malikâne ve devasa bahçe seni bekliyor.", UI.TERRACOTTA))


func _info_card(kicker: String, title: String, body: String, accent: Color) -> PanelContainer:
	var card := UI.panel(Color(0.91, 0.86, 0.72, 0.94), 16, Color(0.22, 0.31, 0.22, 0.45))
	card.custom_minimum_size = Vector2(270, 162)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	var top := HBoxContainer.new()
	var dot := ColorRect.new()
	dot.color = accent
	dot.custom_minimum_size = Vector2(7, 23)
	top.add_child(dot)
	top.add_child(UI.label(kicker, 13, UI.MOSS, true))
	box.add_child(top)
	box.add_child(UI.label(title, 18, UI.INK, true))
	var text_node := UI.label(body, 14, Color("405145"))
	text_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text_node)
	return card


func _build_home_panel() -> PanelContainer:
	var panel := UI.panel(Color(0.94, 0.89, 0.77, 0.98), 22, Color(0.21, 0.30, 0.21, 0.62))
	panel.name = "HomePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.position = Vector2(-514, -350)
	panel.size = Vector2(454, 700)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	box.add_child(UI.badge("BAHÇE DEFTERİ • NO. 01", UI.MOSS))
	box.add_child(UI.label("Yeni bir gün", 31, UI.INK, true))
	box.add_child(UI.label("Vadide bıraktığın iz büyümeye devam ediyor.", 15, Color("526356")))
	box.add_child(UI.divider())
	var play := UI.button("YENİ BAHÇE KUR", true)
	play.pressed.connect(_request_new_game)
	UI.wire_button_sound(play, self)
	box.add_child(play)
	continue_button = UI.button("KALDIĞIN YERDEN DEVAM ET")
	continue_button.pressed.connect(_continue_game)
	UI.wire_button_sound(continue_button, self)
	box.add_child(continue_button)
	var saves := UI.button("KAYITLAR")
	saves.pressed.connect(func() -> void:
		home_panel.visible = false
		saves_panel.visible = true
		_refresh_continue_button())
	UI.wire_button_sound(saves, self)
	box.add_child(saves)
	var settings := UI.button("AYARLAR VE ERİŞİLEBİLİRLİK")
	settings.pressed.connect(func() -> void:
		home_panel.visible = false
		settings_panel.visible = true)
	UI.wire_button_sound(settings, self)
	box.add_child(settings)
	var quit := UI.button("VADİDEN AYRIL", false, true)
	quit.pressed.connect(func() -> void: get_tree().quit())
	UI.wire_button_sound(quit, self)
	box.add_child(quit)
	box.add_child(UI.divider())
	save_summary_label = UI.label("KAYIT YOK\nYeni bir bahçe kurarak ilk sayfayı aç.", 14, Color("455849"))
	save_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(save_summary_label)
	var tip := UI.panel(Color("d8c89f"), 13, Color("a88b50"), false)
	var tip_text := UI.label("BAHÇIVAN NOTU\nBakımı düşen makineler daha sık tekler. Atölyeyi ziyaret etmeyi unutma.", 13, Color("4d452d"))
	tip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_child(tip_text)
	box.add_child(tip)
	return panel


func _build_saves_panel() -> PanelContainer:
	var panel := UI.panel(Color(0.94, 0.89, 0.77, 0.99), 22, Color(0.21, 0.30, 0.21, 0.62))
	panel.name = "SavesPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.position = Vector2(-514, -350)
	panel.size = Vector2(454, 700)
	panel.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UI.badge("KAYIT DEFTERİ", UI.GOLD))
	box.add_child(UI.label("Bahçe kayıtları", 31, UI.INK, true))
	box.add_child(UI.label("İlerlemen, çantan ve makine bakımların birlikte saklanır.", 14, Color("526356")))
	box.add_child(UI.divider())
	var slot := UI.panel(Color("ded1ad"), 16, UI.MOSS, false)
	slot.custom_minimum_size.y = 230
	box.add_child(slot)
	var slot_box := VBoxContainer.new()
	slot_box.add_theme_constant_override("separation", 10)
	slot.add_child(slot_box)
	var slot_header := HBoxContainer.new()
	var slot_title := UI.label("KAYIT 01", 18, UI.INK, true)
	slot_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_header.add_child(slot_title)
	slot_header.add_child(UI.badge("OTOMATİK", UI.MOSS))
	slot_box.add_child(slot_header)
	slot_box.add_child(UI.divider(Color("a88b50")))
	save_slot_label = UI.label("Henüz bir bahçe kaydı yok.", 14, Color("485548"))
	save_slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_slot_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_box.add_child(save_slot_label)
	save_slot_continue_button = UI.button("BU KAYDI AÇ", true, true)
	save_slot_continue_button.pressed.connect(_continue_game)
	UI.wire_button_sound(save_slot_continue_button, self)
	slot_box.add_child(save_slot_continue_button)
	var delete_button := UI.button("KAYDI SİL", false, true)
	delete_button.pressed.connect(func() -> void: delete_save_dialog.popup_centered())
	UI.wire_button_sound(delete_button, self)
	box.add_child(delete_button)
	var note := UI.panel(Color("d8c89f"), 13, Color("a88b50"), false)
	var note_text := UI.label("KAYIT KAPSAMI\nGörevler • Para • Envanter • Alet kondisyonu • Bakım • Saat • Açılan bölgeler", 13, Color("4d452d"))
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_child(note_text)
	box.add_child(note)
	var back := UI.button("BAHÇE DEFTERİNE DÖN", false, true)
	back.pressed.connect(func() -> void:
		panel.visible = false
		home_panel.visible = true)
	UI.wire_button_sound(back, self)
	box.add_child(back)
	return panel


func _delete_save() -> void:
	var absolute_path := ProjectSettings.globalize_path(GameSession.SAVE_PATH)
	if FileAccess.file_exists(GameSession.SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
	_refresh_continue_button()


func _build_settings_panel() -> PanelContainer:
	var panel := UI.panel(Color(0.94, 0.89, 0.77, 0.99), 22, Color(0.21, 0.30, 0.21, 0.62))
	panel.name = "SettingsPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.position = Vector2(-534, -350)
	panel.size = Vector2(474, 700)
	panel.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(UI.badge("OYUN TERCİHLERİ", UI.TERRACOTTA))
	box.add_child(UI.label("Ayarlar", 31, UI.INK, true))
	box.add_child(UI.label("Görüntü, arayüz ve kontrol deneyimini kendine göre düzenle.", 14, Color("526356")))
	box.add_child(UI.divider())
	var tabs := TabContainer.new()
	tabs.custom_minimum_size.y = 425
	tabs.add_theme_font_override("font", UI.BODY_FONT)
	tabs.add_theme_font_size_override("font_size", 14)
	_style_tabs(tabs)
	box.add_child(tabs)
	var display_page := _settings_page("GÖRÜNTÜ")
	tabs.add_child(display_page)
	display_page.add_child(_setting_title("KALİTE", "Çözünürlük, kenar yumuşatma ve bitki yoğunluğu"))
	quality_option = _option(["Performans", "Dengeli", "Yüksek", "Sinematik"], 2)
	display_page.add_child(quality_option)
	display_page.add_child(_setting_title("GÖRÜŞ AÇISI", "70° - 100°"))
	fov_slider = _slider(70.0, 100.0, 1.0, 76.0)
	display_page.add_child(fov_slider)
	fullscreen_check = _check("Tam ekran kullan", false)
	display_page.add_child(fullscreen_check)
	vsync_check = _check("Dikey eşitleme (VSync)", true)
	display_page.add_child(vsync_check)
	display_page.add_child(_setting_title("FPS SINIRI", "Donanıma göre sınırla"))
	fps_option = _option(["30 FPS", "60 FPS", "90 FPS", "120 FPS", "Sınırsız"], 1)
	display_page.add_child(fps_option)
	var interface_page := _settings_page("ARAYÜZ")
	tabs.add_child(interface_page)
	interface_page.add_child(_setting_title("YAZI PROFİLİ", "Türkçe karakter destekli"))
	font_option = _option(["Kır Günlüğü", "Yumuşak", "Klasik", "Yüksek Okunabilirlik"], 0)
	interface_page.add_child(font_option)
	interface_page.add_child(_setting_title("YAZI ÖLÇEĞİ", "%85 - %125"))
	ui_scale_slider = _slider(0.85, 1.25, 0.05, 1.0)
	interface_page.add_child(ui_scale_slider)
	interface_page.add_child(_setting_title("NİŞANGÂH", "Boyut"))
	crosshair_slider = _slider(0.7, 1.6, 0.1, 1.0)
	interface_page.add_child(crosshair_slider)
	reduced_motion_check = _check("Arayüz hareketlerini azalt", false)
	interface_page.add_child(reduced_motion_check)
	interface_page.add_child(_setting_title("MİNİ HARİTA", "Görünürlük, dönüş ve menzil"))
	minimap_check = _check("Mini haritayı göster", true)
	minimap_rotate_check = _check("Mini harita oyuncuyla dönsün", true)
	minimap_range_slider = _slider(36.0, 90.0, 2.0, 52.0)
	interface_page.add_child(minimap_check)
	interface_page.add_child(minimap_rotate_check)
	interface_page.add_child(minimap_range_slider)
	var advanced_page := _settings_page("GRAFİK TEKNOLOJİLERİ")
	tabs.add_child(advanced_page)
	advanced_page.add_child(_setting_title("AYDINLATMA", "Forward+ efektlerini ayrı ayrı yönet"))
	ssao_check = _check("SSAO: temas gölgeleri", true)
	ssil_check = _check("SSIL: ekran alanı dolaylı ışık", true)
	sdfgi_check = _check("SDFGI: açık dünya dinamik ışığı", false)
	volumetric_fog_check = _check("Hacimsel sis ve ışık huzmeleri", true)
	dof_check = _check("Hafif sinematik alan derinliği", true)
	decal_check = _check("Toprak, çamur ve alet izleri", true)
	for feature_check in [ssao_check, ssil_check, sdfgi_check, volumetric_fog_check, dof_check, decal_check]:
		advanced_page.add_child(feature_check)
	var control_page := _settings_page("SES & KONTROL")
	tabs.add_child(control_page)
	control_page.add_child(_setting_title("ANA SES", "Tüm seslerin düzeyi"))
	volume_slider = _slider(0.0, 1.0, 0.05, 0.8)
	control_page.add_child(volume_slider)
	control_page.add_child(_setting_title("FARE", "Bakış hassasiyeti"))
	sensitivity_slider = _slider(0.5, 2.0, 0.05, 1.0)
	control_page.add_child(sensitivity_slider)
	var controls := UI.panel(Color("d8c89f"), 12, Color("9b8357"), false)
	var controls_text := UI.label("HIZLI TUŞLAR\nV kamera • C eğil • ESC rehber\nI çanta • M harita • J görevler • Q alet değiştir", 13, Color("4d452d"))
	controls_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_child(controls_text)
	control_page.add_child(controls)
	var apply := UI.button("AYARLARI UYGULA", true, true)
	apply.pressed.connect(_apply_preferences)
	UI.wire_button_sound(apply, self)
	box.add_child(apply)
	var back := UI.button("BAHÇE DEFTERİNE DÖN", false, true)
	back.pressed.connect(func() -> void:
		settings_panel.visible = false
		home_panel.visible = true)
	UI.wire_button_sound(back, self)
	box.add_child(back)
	return panel


func _settings_page(title: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = title
	page.add_theme_constant_override("separation", 9)
	return page


func _style_tabs(tabs: TabContainer) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("ded1ad")
	panel_style.border_color = Color("a99362")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	tabs.add_theme_stylebox_override("panel", panel_style)
	var selected := StyleBoxFlat.new()
	selected.bg_color = UI.MOSS
	selected.set_corner_radius_all(7)
	selected.content_margin_left = 12
	selected.content_margin_right = 12
	selected.content_margin_top = 7
	selected.content_margin_bottom = 7
	var unselected := selected.duplicate() as StyleBoxFlat
	unselected.bg_color = Color("b8aa84")
	tabs.add_theme_stylebox_override("tab_selected", selected)
	tabs.add_theme_stylebox_override("tab_unselected", unselected)
	tabs.add_theme_color_override("font_selected_color", UI.CREAM)
	tabs.add_theme_color_override("font_unselected_color", Color("4f5b4f"))


func _option(items: Array[String], selected_index: int) -> OptionButton:
	var option := OptionButton.new()
	for item in items:
		option.add_item(item)
	option.selected = selected_index
	option.custom_minimum_size.y = 42
	option.add_theme_font_override("font", UI.BODY_FONT)
	option.add_theme_font_size_override("font_size", 15)
	option.set_meta("ui_display", false)
	option.set_meta("ui_base_font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("eee2c4")
	normal.border_color = Color("9f8c60")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 12
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("f7edda")
	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_stylebox_override("hover", hover)
	option.add_theme_stylebox_override("pressed", hover)
	option.add_theme_color_override("font_color", UI.INK)
	option.add_theme_color_override("font_hover_color", UI.INK)
	return option


func _check(text_value: String, enabled: bool) -> CheckButton:
	var check := CheckButton.new()
	check.text = text_value
	check.button_pressed = enabled
	check.add_theme_font_override("font", UI.BODY_FONT)
	check.add_theme_font_size_override("font_size", 14)
	check.set_meta("ui_display", false)
	check.set_meta("ui_base_font_size", 14)
	check.add_theme_color_override("font_color", Color("465548"))
	return check


func _setting_title(kicker: String, description: String) -> Control:
	var row := HBoxContainer.new()
	row.add_child(UI.label(kicker, 13, UI.MOSS, true))
	var desc := UI.label(description, 14, Color("526356"))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(desc)
	return row


func _slider(minimum: float, maximum: float, step_value: float, current: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step_value
	slider.value = current
	slider.custom_minimum_size.y = 24
	return slider


func _build_footer() -> void:
	var footer := UI.label("SÜRÜM 0.4  •  TERRAIN3D  •  CC0 SANAT PAKETLERİ  •  TÜRKÇE", 12, Color(1, 1, 1, 0.72), true)
	footer.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(74, -36)
	footer.size = Vector2(800, 24)
	menu_root.add_child(footer)


func _play_intro() -> void:
	if reduced_motion_check != null and reduced_motion_check.button_pressed:
		return
	var brand := menu_root.get_node_or_null("BrandStory") as Control
	var cards := menu_root.get_node_or_null("WorldCards") as Control
	if brand == null or cards == null:
		return
	brand.modulate.a = 0.0
	brand.position.x -= 35
	cards.modulate.a = 0.0
	cards.position.y += 24
	home_panel.modulate.a = 0.0
	home_panel.position.x += 26
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(brand, "modulate:a", 1.0, 0.7)
	tween.tween_property(brand, "position:x", brand.position.x + 35, 0.7)
	tween.tween_property(cards, "modulate:a", 1.0, 0.75).set_delay(0.18)
	tween.tween_property(cards, "position:y", cards.position.y - 24, 0.75).set_delay(0.18)
	tween.tween_property(home_panel, "modulate:a", 1.0, 0.7).set_delay(0.28)
	tween.tween_property(home_panel, "position:x", home_panel.position.x - 26, 0.7).set_delay(0.28)


func _apply_saved_preferences() -> void:
	var config := ConfigFile.new()
	if config.load("user://garden_preferences.cfg") != OK:
		return
	volume_slider.value = float(config.get_value("audio", "master", 0.8))
	sensitivity_slider.value = float(config.get_value("controls", "sensitivity", 1.0))
	quality_option.selected = int(config.get_value("video", "quality", 2))
	font_option.selected = int(config.get_value("interface", "font_profile", 0))
	ui_scale_slider.value = float(config.get_value("interface", "font_scale", 1.0))
	crosshair_slider.value = float(config.get_value("interface", "crosshair_scale", 1.0))
	reduced_motion_check.button_pressed = bool(config.get_value("interface", "reduced_motion", false))
	minimap_check.button_pressed = bool(config.get_value("interface", "minimap_visible", true))
	minimap_rotate_check.button_pressed = bool(config.get_value("interface", "minimap_rotate", true))
	minimap_range_slider.value = float(config.get_value("interface", "minimap_range", 52.0))
	ssao_check.button_pressed = bool(config.get_value("graphics", "ssao", true))
	ssil_check.button_pressed = bool(config.get_value("graphics", "ssil", true))
	sdfgi_check.button_pressed = bool(config.get_value("graphics", "sdfgi", false))
	volumetric_fog_check.button_pressed = bool(config.get_value("graphics", "volumetric_fog", true))
	dof_check.button_pressed = bool(config.get_value("graphics", "dof", true))
	decal_check.button_pressed = bool(config.get_value("graphics", "decals", true))
	fov_slider.value = float(config.get_value("video", "fov", 76.0))
	fullscreen_check.button_pressed = bool(config.get_value("video", "fullscreen", false))
	vsync_check.button_pressed = bool(config.get_value("video", "vsync", true))
	fps_option.selected = int(config.get_value("video", "fps_limit", 1))
	_apply_preferences(false)


func _apply_preferences(save_file := true) -> void:
	var volume := maxf(0.001, volume_slider.value)
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	var viewport := get_viewport()
	UI.set_font_profile(font_option.selected)
	UI.apply_typography(menu_root, ui_scale_slider.value)
	match quality_option.selected:
		0:
			viewport.scaling_3d_scale = 0.72
			viewport.msaa_3d = Viewport.MSAA_DISABLED
		1:
			viewport.scaling_3d_scale = 0.86
			viewport.msaa_3d = Viewport.MSAA_2X
		2:
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_4X
		3:
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_8X
	if world != null:
		if world.grass_field != null:
			world.grass_field.set_quality_profile(quality_option.selected)
		if world.foliage_scatter != null:
			world.foliage_scatter.set_quality_profile(quality_option.selected)
		if world.ground_detail_scatter != null:
			world.ground_detail_scatter.set_quality_profile(quality_option.selected)
		if world.outer_biome_ring != null:
			world.outer_biome_ring.set_quality_profile(quality_option.selected)
		if world.graphics_manager != null:
			world.graphics_manager.apply_quality(quality_option.selected)
			world.graphics_manager.apply_feature_overrides({
				"ssao": ssao_check.button_pressed,
				"ssil": ssil_check.button_pressed,
				"sdfgi": sdfgi_check.button_pressed,
				"volumetric_fog": volumetric_fog_check.button_pressed,
				"dof": dof_check.button_pressed,
			})
		if world.decal_system != null:
			world.decal_system.set_quality_profile(quality_option.selected if decal_check.button_pressed else 0)
		if world.atmosphere_effects != null:
			world.atmosphere_effects.set_quality_profile(quality_option.selected)
		for water_body in world.water_bodies:
			water_body.set_quality_profile(quality_option.selected)
		world.player.mouse_sensitivity = 0.0022 * sensitivity_slider.value
		world.player.camera.fov = fov_slider.value
		world.player.third_camera.fov = fov_slider.value - 4.0
		world.hud.set_crosshair_scale(crosshair_slider.value)
		world.hud.set_minimap_preferences(minimap_check.button_pressed, minimap_rotate_check.button_pressed, minimap_range_slider.value)
		UI.apply_typography(world.hud, ui_scale_slider.value)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_check.button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_check.button_pressed else DisplayServer.VSYNC_DISABLED)
	var fps_values := [30, 60, 90, 120, 0]
	Engine.max_fps = fps_values[fps_option.selected]
	if save_file:
		var config := ConfigFile.new()
		config.set_value("audio", "master", volume_slider.value)
		config.set_value("controls", "sensitivity", sensitivity_slider.value)
		config.set_value("video", "quality", quality_option.selected)
		config.set_value("video", "fov", fov_slider.value)
		config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
		config.set_value("video", "vsync", vsync_check.button_pressed)
		config.set_value("video", "fps_limit", fps_option.selected)
		config.set_value("interface", "font_profile", font_option.selected)
		config.set_value("interface", "font_scale", ui_scale_slider.value)
		config.set_value("interface", "crosshair_scale", crosshair_slider.value)
		config.set_value("interface", "reduced_motion", reduced_motion_check.button_pressed)
		config.set_value("interface", "minimap_visible", minimap_check.button_pressed)
		config.set_value("interface", "minimap_rotate", minimap_rotate_check.button_pressed)
		config.set_value("interface", "minimap_range", minimap_range_slider.value)
		config.set_value("graphics", "ssao", ssao_check.button_pressed)
		config.set_value("graphics", "ssil", ssil_check.button_pressed)
		config.set_value("graphics", "sdfgi", sdfgi_check.button_pressed)
		config.set_value("graphics", "volumetric_fog", volumetric_fog_check.button_pressed)
		config.set_value("graphics", "dof", dof_check.button_pressed)
		config.set_value("graphics", "decals", decal_check.button_pressed)
		config.save("user://garden_preferences.cfg")


func _refresh_continue_button() -> void:
	var has_save := session.has_save()
	continue_button.disabled = not has_save
	if save_slot_continue_button != null:
		save_slot_continue_button.disabled = not has_save
	if has_save:
		var preview := GameSession.new()
		if preview.load_save():
			save_summary_label.text = "SON KAYIT\n%d ₺ • %02d:%02d • Görev aşaması %d\n%d/%d ot • Çantada %d eşya" % [
				preview.money, int(preview.world_hour), int(fposmod(preview.world_hour, 1.0) * 60.0),
				preview.mission_stage + 1, preview.grass_cut, preview.grass_goal, preview.inventory_item_count()
			]
			if save_slot_label != null:
				save_slot_label.text = "AKTİF BAHÇE\n%d ₺ • Saat %02d:%02d\nGörev aşaması %d • Çantada %d eşya\nKonum: %s" % [
					preview.money, int(preview.world_hour), int(fposmod(preview.world_hour, 1.0) * 60.0),
					preview.mission_stage + 1, preview.inventory_item_count(),
					str(WorldLevelCatalog.get_level(preview.current_level_id).get("title", "Ev Bahçesi"))
				]
	else:
		save_summary_label.text = "KAYIT YOK\nYeni bir bahçe kurarak ilk sayfayı aç."
		if save_slot_label != null:
			save_slot_label.text = "BOŞ KAYIT\nYeni bir bahçe kurduğunda görevler, envanter ve dünya ilerlemesi burada görünecek."


func _ensure_input_actions() -> void:
	_set_key_action("sprint", KEY_SHIFT)
	_add_key_action("pause_menu", KEY_ESCAPE)
	_add_key_action("crouch", KEY_C)
	_add_key_action("toggle_camera", KEY_V)
	_add_key_action("toggle_quests", KEY_J)


func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func _set_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
