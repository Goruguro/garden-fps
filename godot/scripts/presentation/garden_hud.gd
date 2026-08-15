class_name GardenHUD
extends CanvasLayer

signal exit_requested
signal resume_requested
signal level_requested(level_id: StringName)

const UI := preload("res://scripts/presentation/garden_ui_theme.gd")
const MINIMAP_SCRIPT := preload("res://addons/dynamic_minimap/minimap.gd")
const MINIMAP_ICON_SCRIPT := preload("res://addons/dynamic_minimap/IconType.gd")

var session: GameSession
var mission_system: GardenMissionSystem
var addon_hub: GardenAddonHub
var root: Control
var task_label: Label
var task_detail: Label
var task_progress: Label
var money_label: Label
var tool_label: Label
var condition_bar: ProgressBar
var maintenance_bar: ProgressBar
var fuel_bar: ProgressBar
var prompt_label: Label
var message_label: Label
var hotbar_label: Label
var secondary_slot_label: Label
var clock_label: Label
var season_label: Label
var pause_panel: PanelContainer
var journal_dimmer: ColorRect
var journal_panel: PanelContainer
var journal_title: Label
var journal_content: VBoxContainer
var crosshair_ring: PanelContainer
var minimap: Control
var minimap_enabled := true
var message_time := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func configure(active_session: GameSession, missions: GardenMissionSystem, tracked_player: Node = null, addons: GardenAddonHub = null) -> void:
	session = active_session
	mission_system = missions
	addon_hub = addons
	if minimap != null:
		minimap.set("player_node", tracked_player)
		_register_minimap_targets(tracked_player)
	refresh()


func tick(delta: float) -> void:
	if message_time <= 0.0:
		return
	message_time -= delta
	if message_time <= 0.0:
		message_label.text = ""


func refresh() -> void:
	if session == null or mission_system == null:
		return
	money_label.text = "%d ₺" % session.money
	tool_label.text = GardenToolSystem.display_name(session.selected_tool).to_upper()
	condition_bar.value = float(session.condition.get(session.selected_tool, 100.0))
	maintenance_bar.value = float(session.maintenance.get(session.selected_tool, 100.0))
	fuel_bar.value = float(session.fuel.get("trimmer", 100.0)) if session.selected_tool == "trimmer" else 100.0
	clock_label.text = "%02d:%02d" % [int(session.world_hour), int(fposmod(session.world_hour, 1.0) * 60.0)]
	season_label.text = "%s  •  %d. GÜN  •  YAŞAYAN VADİ" % [["İLKBAHAR", "YAZ", "SONBAHAR", "KIŞ"][clampi(session.season_index, 0, 3)], session.world_day]
	hotbar_label.text = "[1]  TIRPAN%s" % ("  • SEÇİLİ" if session.selected_tool == "trimmer" else "")
	secondary_slot_label.text = "[2]  BÜYÜK MAKAS%s" % (
		("  • SEÇİLİ" if session.selected_tool == "shears" else "") if session.owned_tools.has("shears") else "  • KİLİTLİ"
	)
	var task := mission_system.get_task()
	task_label.text = str(task.title).to_upper()
	task_detail.text = str(task.detail)
	task_progress.text = "%d / %d" % [session.grass_cut, session.grass_goal] if session.grass_goal > 0 else "YENİ"


func set_prompt(text: String) -> void:
	prompt_label.text = text


func show_message(text: String, duration := 2.5) -> void:
	message_label.text = text
	message_time = duration


func set_paused(value: bool) -> void:
	pause_panel.visible = value
	root.visible = not value


func set_crosshair_scale(value: float) -> void:
	if crosshair_ring != null:
		crosshair_ring.scale = Vector2.ONE * value


func set_minimap_preferences(visible_value: bool, rotate_value: bool, scale_value: float) -> void:
	minimap_enabled = visible_value
	if minimap == null:
		return
	minimap.visible = visible_value and not journal_dimmer.visible
	minimap.set("rotate_with_player", rotate_value)
	minimap.set("world_scale", scale_value)


func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_task_card()
	_build_status_card()
	_build_center_elements()
	_build_hotbar()
	_build_minimap()
	_build_journal()
	_build_pause_menu()


func show_journal(page: StringName, visible_value: bool) -> void:
	journal_dimmer.visible = visible_value
	if minimap != null:
		minimap.visible = minimap_enabled and not visible_value
	if not visible_value or session == null:
		return
	for child in journal_content.get_children():
		child.queue_free()
	match page:
		&"map":
			_populate_map()
		&"quests":
			_populate_quests()
		_:
			_populate_inventory()


func _build_minimap() -> void:
	minimap = MINIMAP_SCRIPT.new() as Control
	minimap.name = "DynamicMinimap"
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.set("radius", 76.0)
	minimap.set("world_scale", 52.0)
	minimap.set("icon_size", 13.0)
	minimap.set("bg_color", Color(0.055, 0.10, 0.065, 0.82))
	minimap.set("border_color", UI.GOLD.lightened(0.18))
	minimap.set("border_width", 3.0)
	minimap.set("use_default_icons", false)
	minimap.set("enabled_auto_register", false)
	var icon_types: Array[IconType] = []
	for icon_data in [
		["player", Color("f3df9b")],
		["npc", Color("8fd0a1")],
		["quest", Color("ffd35c")],
		["companion", Color("e99a77")],
	]:
		var icon_type := MINIMAP_ICON_SCRIPT.new() as IconType
		icon_type.type = str(icon_data[0])
		icon_type.color = icon_data[1] as Color
		icon_types.append(icon_type)
	minimap.set("icons", icon_types)
	root.add_child(minimap)
	get_viewport().size_changed.connect(_position_minimap)
	_position_minimap.call_deferred()


func _register_minimap_targets(tracked_player: Node) -> void:
	if minimap == null:
		return
	if tracked_player != null:
		minimap.call("add_target", tracked_player, "player")
	for group_name in ["quest", "npc", "companion"]:
		for target in get_tree().get_nodes_in_group(group_name):
			minimap.call("add_target", target, group_name)


func _position_minimap() -> void:
	if minimap == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	minimap.position = Vector2(viewport_size.x - minimap.size.x - 28.0, viewport_size.y - minimap.size.y - 28.0)


func _build_task_card() -> void:
	var panel := UI.panel(Color(0.92, 0.86, 0.72, 0.94), 17, Color(0.23, 0.34, 0.24, 0.62))
	panel.position = Vector2(25, 25)
	panel.size = Vector2(425, 154)
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	panel.add_child(row)
	var marker := VBoxContainer.new()
	marker.custom_minimum_size.x = 54
	var icon_plate := UI.panel(UI.MOSS, 13, UI.LEAF, false)
	icon_plate.custom_minimum_size = Vector2(52, 52)
	var icon := TextureRect.new()
	icon.texture = UI.CHECK_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(31, 31)
	icon_plate.add_child(icon)
	marker.add_child(icon_plate)
	task_progress = UI.label("YENİ", 13, UI.MOSS, true)
	task_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.add_child(task_progress)
	row.add_child(marker)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	row.add_child(box)
	box.add_child(UI.label("GÜNLÜK İŞ", 12, UI.TERRACOTTA, true))
	task_label = UI.label("GÜNE BAŞLA", 19, UI.INK, true)
	box.add_child(task_label)
	task_detail = UI.label("Mira ile konuş.", 15, Color("415247"))
	task_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(task_detail)


func _build_status_card() -> void:
	var panel := UI.panel(Color(0.11, 0.18, 0.14, 0.94), 17, Color(0.50, 0.68, 0.49, 0.52))
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.position = Vector2(-346, 25)
	panel.size = Vector2(321, 222)
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var top := HBoxContainer.new()
	money_label = UI.label("120 ₺", 23, UI.GOLD, true)
	clock_label = UI.label("09:15", 17, UI.CREAM, true)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(money_label)
	top.add_child(clock_label)
	box.add_child(top)
	season_label = UI.label("İLKBAHAR  •  1. GÜN  •  YAŞAYAN VADİ", 11, Color("9fc39c"), true)
	box.add_child(season_label)
	box.add_child(UI.divider(Color(0.53, 0.68, 0.51, 0.28)))
	tool_label = UI.label("BENZİNLİ TIRPAN", 15, UI.CREAM, true)
	box.add_child(tool_label)
	box.add_child(_meter_title("KONDİSYON", "makine sağlığı"))
	condition_bar = UI.progress(UI.TERRACOTTA, 10)
	box.add_child(condition_bar)
	box.add_child(_meter_title("BAKIM", "tekleme riski"))
	maintenance_bar = UI.progress(UI.LEAF, 10)
	box.add_child(maintenance_bar)
	box.add_child(_meter_title("BENZİN", "motor çalışırken azalır"))
	fuel_bar = UI.progress(UI.GOLD, 10)
	box.add_child(fuel_bar)


func _meter_title(left_text: String, right_text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_child(UI.label(left_text, 10, Color("c9d9c8"), true))
	var right := UI.label(right_text, 10, Color("829b87"))
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	return row


func _build_center_elements() -> void:
	crosshair_ring = PanelContainer.new()
	crosshair_ring.set_anchors_preset(Control.PRESET_CENTER)
	crosshair_ring.position = Vector2(-13, -13)
	crosshair_ring.size = Vector2(26, 26)
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0.95, 0.91, 0.75, 0.12)
	ring_style.border_color = Color(0.97, 0.94, 0.82, 0.88)
	ring_style.set_border_width_all(2)
	ring_style.set_corner_radius_all(13)
	crosshair_ring.add_theme_stylebox_override("panel", ring_style)
	root.add_child(crosshair_ring)
	var dot := ColorRect.new()
	dot.color = Color("fff5d5")
	dot.position = Vector2(10, 10)
	dot.size = Vector2(6, 6)
	crosshair_ring.add_child(dot)
	prompt_label = UI.label("", 16, UI.CREAM, true)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-300, -184)
	prompt_label.size = Vector2(600, 34)
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(prompt_label)
	message_label = UI.label("", 17, Color("fff8df"), true)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.position = Vector2(-380, -140)
	message_label.size = Vector2(760, 38)
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	root.add_child(message_label)


func _build_hotbar() -> void:
	var tray := HBoxContainer.new()
	tray.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tray.position = Vector2(-270, -89)
	tray.size = Vector2(540, 66)
	tray.add_theme_constant_override("separation", 10)
	root.add_child(tray)
	hotbar_label = _tool_slot("[1]  TIRPAN", UI.MOSS, tray)
	secondary_slot_label = _tool_slot("[2]  BÜYÜK MAKAS  • KİLİTLİ", Color("5f655c"), tray)


func _tool_slot(title: String, color: Color, parent: Control) -> Label:
	var slot := UI.panel(Color(0.10, 0.16, 0.12, 0.91), 13, color, true)
	slot.custom_minimum_size = Vector2(265, 61)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	slot.add_child(row)
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(7, 30)
	row.add_child(swatch)
	var label_node := UI.label(title, 13, UI.CREAM, true)
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label_node)
	parent.add_child(slot)
	return label_node


func _build_journal() -> void:
	journal_dimmer = ColorRect.new()
	journal_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	journal_dimmer.color = Color(0.025, 0.055, 0.035, 0.76)
	journal_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	journal_dimmer.visible = false
	add_child(journal_dimmer)
	journal_panel = UI.panel(Color(0.94, 0.89, 0.77, 0.99), 24, Color(0.20, 0.31, 0.21, 0.8))
	journal_panel.set_anchors_preset(Control.PRESET_CENTER)
	journal_panel.position = Vector2(-500, -325)
	journal_panel.size = Vector2(1000, 650)
	journal_dimmer.add_child(journal_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	journal_panel.add_child(outer)
	var header := HBoxContainer.new()
	journal_title = UI.label("ALET ÇANTASI", 31, UI.INK, true)
	journal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(journal_title)
	header.add_child(UI.badge("I / M / J İLE KAPAT", UI.MOSS))
	outer.add_child(header)
	outer.add_child(UI.divider())
	journal_content = VBoxContainer.new()
	journal_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_content.add_theme_constant_override("separation", 12)
	outer.add_child(journal_content)


func _populate_inventory() -> void:
	journal_title.text = "ALET ÇANTASI"
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 12)
	journal_content.add_child(summary)
	summary.add_child(_summary_tile("PARA", "%d ₺" % session.money, UI.GOLD))
	summary.add_child(_summary_tile("KAPASİTE", "%d / SINIRSIZ" % session.inventory_item_count(), UI.LEAF))
	summary.add_child(_summary_tile("SEÇİLİ ALET", GardenToolSystem.display_name(session.selected_tool), UI.TERRACOTTA))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_content.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation", 9)
	scroll.add_child(items)
	items.add_child(UI.label("ENVANTER", 16, UI.MOSS, true))
	var inventory_rows: Array[Dictionary] = _get_inventory_rows()
	if inventory_rows.is_empty():
		var empty_label := UI.label("Çantan şu anda boş. Yine de her zaman açık kalır; topladığın ilk eşya burada görünecek.", 14, Color("536054"))
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		items.add_child(empty_label)
	for row_data in inventory_rows:
		var item_id := str(row_data.get("id", ""))
		var amount := int(row_data.get("amount", 0))
		if amount <= 0:
			continue
		var item := GardenItemCatalog.get_item(item_id)
		var state := "x%d" % amount
		if str(item.get("category", "")) == "tool":
			var tool_id := "shears" if item_id == "buyuk_makas" else "trimmer"
			state = "%d%%" % int(session.condition.get(tool_id, 100.0))
		items.add_child(_inventory_item(
			str(item.get("name", item_id)).to_upper(),
			str(item.get("description", GardenItemCatalog.category_name(str(item.get("category", "misc"))))),
			state,
			GardenItemCatalog.accent(item)
		))
	var details := UI.panel(Color("d7c79f"), 15, Color("a58b55"), false)
	details.custom_minimum_size = Vector2(360, 0)
	columns.add_child(details)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 9)
	details.add_child(detail_box)
	detail_box.add_child(UI.label("GÖREV DEFTERİ", 17, UI.TERRACOTTA, true))
	detail_box.add_child(UI.divider(Color("a88b50")))
	var copy := UI.label("1. Mira ile konuş ve ilk işi al.\n2. Dere kenarında 12 ot kümesini biç.\n3. Mira'dan 260 ₺, gübre ve tohum al.\n4. Atölyeden büyük makası satın al.", 14, Color("4f503b"))
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(copy)
	detail_box.add_child(UI.divider(Color("a88b50")))
	detail_box.add_child(UI.label("ÇANTA BİLGİSİ", 13, UI.MOSS, true))
	var inventory_help := UI.label("Kapasite sınırsızdır. Toplanan gübre, tohum, ot demeti ve otomasyon parçaları kayıt dosyasında korunur.\n\nI  Çantayı aç/kapat\nJ  Görev defteri\n1–2  Alet seç\nQ  Sonraki alet", 13, Color("485548"))
	inventory_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(inventory_help)


func _get_inventory_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if addon_hub != null and addon_hub.inventory != null:
		for inventory_item: InventoryItem in addon_hub.inventory.get_items():
			var prototype := inventory_item.get_prototype()
			if prototype == null:
				continue
			rows.append({
				"id": str(prototype.get_prototype_id()),
				"amount": inventory_item.get_stack_size(),
			})
		return rows
	for item_id: Variant in session.inventory.keys():
		rows.append({"id": str(item_id), "amount": session.get_item_count(str(item_id))})
	return rows


func _populate_quests() -> void:
	journal_title.text = "GÖREV DEFTERİ"
	var task := mission_system.get_task()
	var intro := UI.label("Hazır QuestSystem görevleri kullanılmaktadır. Aktif, bekleyen ve tamamlanan işler aşağıda ayrı tutulur.", 14, Color("526356"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_content.add_child(intro)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_content.add_child(columns)
	var active_quests: Array[Quest] = []
	var available_quests: Array[Quest] = []
	var completed_quests: Array[Quest] = []
	if addon_hub != null and addon_hub.quest_manager != null:
		active_quests = addon_hub.quest_manager.get_active_quests()
		available_quests = addon_hub.quest_manager.get_available_quests()
		completed_quests = addon_hub.quest_manager.completed.get_all_quests()
	columns.add_child(_quest_column("AKTİF", active_quests, str(task.get("detail", "")), UI.LEAF))
	columns.add_child(_quest_column("BEKLEYEN", available_quests, "NPC ile konuşarak görevi kabul et.", UI.GOLD))
	columns.add_child(_quest_column("TAMAMLANAN", completed_quests, "Tamamlanan görevler burada saklanır.", UI.TERRACOTTA))


func _quest_column(title: String, quests: Array[Quest], fallback: String, accent: Color) -> PanelContainer:
	var panel := UI.panel(Color("ded1ad"), 14, accent.darkened(0.2), false)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(UI.label(title, 15, accent.darkened(0.2), true))
	box.add_child(UI.divider(accent.darkened(0.1)))
	if quests.is_empty():
		var empty := UI.label(fallback, 13, Color("536054"))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
	for quest in quests:
		box.add_child(UI.label(quest.quest_name.to_upper(), 15, UI.INK, true))
		var description := UI.label(quest.quest_description + "\n\n" + quest.quest_objective, 13, Color("536054"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(description)
	return panel


func _populate_map() -> void:
	journal_title.text = "VADİ HARİTASI"
	var intro := UI.label("NPC görevleri tamamlandıkça yeni yollar, işler ve bahçe türleri açılır.", 14, Color("526356"))
	journal_content.add_child(intro)
	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 12)
	map_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_content.add_child(map_row)
	var accents := [UI.LEAF, UI.GOLD, UI.MOSS, UI.TERRACOTTA]
	for index in range(WorldLevelCatalog.ORDER.size()):
		var level_id := WorldLevelCatalog.ORDER[index]
		var level := WorldLevelCatalog.get_level(level_id)
		map_row.add_child(_region_card(level_id, level, accents[index]))
	var legend := UI.panel(Color("d7c79f"), 13, Color("a58b55"), false)
	var legend_text := UI.label("HARİTA NOTU  •  Açık bölgeler arasında yol tabelalarıyla seyahat edilecek. Yeni bölgeler para ile değil, hikâye görevleriyle açılır.", 13, Color("4f503b"))
	legend_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.add_child(legend_text)
	journal_content.add_child(legend)


func _summary_tile(kicker: String, value: String, accent: Color) -> PanelContainer:
	var tile := UI.panel(Color("ded1ad"), 13, accent.darkened(0.2), false)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	tile.add_child(box)
	box.add_child(UI.label(kicker, 11, accent.darkened(0.25), true))
	box.add_child(UI.label(value, 17, UI.INK, true))
	return tile


func _inventory_item(title: String, description: String, state: String, accent: Color) -> PanelContainer:
	var card := UI.panel(Color("e7dbbb"), 12, Color("ad9b70"), false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var marker := ColorRect.new()
	marker.color = accent
	marker.custom_minimum_size = Vector2(7, 52)
	row.add_child(marker)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(UI.label(title, 14, UI.INK, true))
	copy.add_child(UI.label(description, 13, Color("536054")))
	row.add_child(copy)
	row.add_child(UI.badge(state, accent.darkened(0.18)))
	return card


func _region_card(level_id: StringName, level: Dictionary, accent: Color) -> PanelContainer:
	var unlocked := session.is_level_unlocked(level_id)
	var is_current := session.current_level_id == level_id
	var state := "BURADASIN" if is_current else ("AÇIK" if unlocked else "KİLİTLİ")
	var card := UI.panel(Color("ded1ad"), 15, accent.darkened(0.25), false)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var top := HBoxContainer.new()
	var number_label := UI.label(str(level["number"]), 24, accent, true)
	number_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(number_label)
	top.add_child(UI.badge(state, accent.darkened(0.15)))
	box.add_child(top)
	box.add_child(UI.divider(accent.darkened(0.1)))
	var title_label := UI.label(str(level["title"]), 15, UI.INK, true)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)
	var body_label := UI.label(str(level["description"]), 13, Color("536054"))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body_label)
	var travel := UI.button("BURADASIN" if is_current else ("SEYAHAT ET" if unlocked else "GÖREVLE AÇILIR"), unlocked and not is_current, true)
	travel.disabled = not unlocked or is_current
	travel.pressed.connect(func() -> void:
		journal_dimmer.visible = false
		level_requested.emit(level_id))
	box.add_child(travel)
	return card


func _build_pause_menu() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.025, 0.055, 0.035, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	pause_panel = UI.panel(Color(0.94, 0.89, 0.77, 0.99), 24, Color(0.20, 0.31, 0.21, 0.8))
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-520, -345)
	pause_panel.size = Vector2(1040, 690)
	dimmer.add_child(pause_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	pause_panel.add_child(outer)
	var heading := HBoxContainer.new()
	var heading_text := VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_text.add_child(UI.label("BAHÇE REHBERİ", 32, UI.INK, true))
	heading_text.add_child(UI.label("Alet çantası, hareket ve vadideki sistemler için hızlı başvuru.", 14, Color("526356")))
	heading.add_child(heading_text)
	heading.add_child(UI.badge("OYUN DURAKLATILDI", UI.TERRACOTTA))
	outer.add_child(heading)
	outer.add_child(UI.divider())
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	outer.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)
	left.add_child(_guide_card("HAREKET", "WASD", "Yürü ve yönlen", "SHIFT", "Koş", "SPACE", "Zıpla", "C", "Eğil"))
	left.add_child(_guide_card("BAKIŞ", "FARE", "Çevreye bak", "V", "Kamera değiştir", "ESC", "Bu rehber", "M", "Harita"))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	right.add_child(_guide_card("BAHÇECİLİK", "SOL TIK", "Tırpan motorunu çalıştır", "ALT + FARE", "Tırpanı bağımsız yönlendir", "SAĞDAN SOLA", "Kontrollü hızda biç", "E", "Etkileş / konuş"))
	right.add_child(_system_card())
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	outer.add_child(actions)
	var resume := UI.button("OYUNA DÖN", true, true)
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.pressed.connect(func() -> void: resume_requested.emit())
	UI.wire_button_sound(resume, self)
	actions.add_child(resume)
	var exit_button := UI.button("ANA MENÜYE DÖN", false, true)
	exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_button.pressed.connect(func() -> void: exit_requested.emit())
	UI.wire_button_sound(exit_button, self)
	actions.add_child(exit_button)
	pause_panel.visible = false
	dimmer.visible = false
	pause_panel.visibility_changed.connect(func() -> void: dimmer.visible = pause_panel.visible)


func _guide_card(title: String, key_a: String, value_a: String, key_b: String, value_b: String, key_c: String, value_c: String, key_d: String, value_d: String) -> PanelContainer:
	var card := UI.panel(Color("ded1ad"), 14, Color("a99362"), false)
	card.custom_minimum_size.y = 205
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	box.add_child(UI.label(title, 16, UI.MOSS, true))
	box.add_child(UI.divider(Color("aa9564")))
	for pair in [[key_a, value_a], [key_b, value_b], [key_c, value_c], [key_d, value_d]]:
		var row := HBoxContainer.new()
		var key_badge := UI.badge(pair[0], UI.MOSS)
		key_badge.custom_minimum_size.x = 105
		row.add_child(key_badge)
		var value := UI.label(pair[1], 14, Color("485548"))
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(value)
		box.add_child(row)
	return card


func _system_card() -> PanelContainer:
	var card := UI.panel(Color("d4c394"), 14, Color("9d8149"), false)
	card.custom_minimum_size.y = 205
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(UI.label("VADİ SİSTEMLERİ", 16, UI.TERRACOTTA, true))
	box.add_child(UI.divider(Color("a88b50")))
	var copy := UI.label(
		"• Sol tık basılıyken motor çalışır ve benzin tüketir.\n• Yalnızca ot teması kondisyon ve bakım düşürür.\n• Alt basılıyken fare kamerayı değil tırpanı yönlendirir.\n• Çok hızlı veya ters yöndeki süpürme otu kesmez.\n• Atölye seçili aleti yeniler ve depoyu doldurur.",
		14,
		Color("4f503b")
	)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(copy)
	return card
