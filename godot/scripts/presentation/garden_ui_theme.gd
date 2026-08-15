class_name GardenUITheme
extends RefCounted

const FRAUNCES_FONT := preload("res://assets/third_party/google_fonts/Fraunces.ttf")
const NUNITO_FONT := preload("res://assets/third_party/google_fonts/Nunito.ttf")
const LORA_FONT := preload("res://assets/third_party/google_fonts/Lora.ttf")
const ATKINSON_REGULAR := preload("res://assets/third_party/google_fonts/AtkinsonRegular.ttf")
const ATKINSON_BOLD := preload("res://assets/third_party/google_fonts/AtkinsonBold.ttf")
const CLICK_SOUND := preload("res://assets/third_party/kenney_ui/Sounds/click-a.ogg")
const STAR_ICON := preload("res://assets/third_party/kenney_ui/PNG/Yellow/Default/star.png")
const CHECK_ICON := preload("res://assets/third_party/kenney_ui/PNG/Green/Default/icon_checkmark.png")
const GREEN_NORMAL := preload("res://assets/third_party/kenney_ui/PNG/Green/Default/button_rectangle_depth_flat.png")
const GREEN_HOVER := preload("res://assets/third_party/kenney_ui/PNG/Green/Default/button_rectangle_depth_gradient.png")
const YELLOW_NORMAL := preload("res://assets/third_party/kenney_ui/PNG/Yellow/Default/button_rectangle_depth_flat.png")
const YELLOW_HOVER := preload("res://assets/third_party/kenney_ui/PNG/Yellow/Default/button_rectangle_depth_gradient.png")
const GREY_NORMAL := preload("res://assets/third_party/kenney_ui/PNG/Grey/Default/button_rectangle_depth_flat.png")
const GREY_HOVER := preload("res://assets/third_party/kenney_ui/PNG/Grey/Default/button_rectangle_depth_gradient.png")

const INK := Color("26382d")
const CREAM := Color("f4ecd7")
const PAPER := Color("e7d7b5")
const MOSS := Color("49694d")
const LEAF := Color("76a66b")
const GOLD := Color("dbad52")
const TERRACOTTA := Color("ba6848")
const NIGHT := Color("18251e")

static var DISPLAY_FONT: Font = FRAUNCES_FONT
static var BODY_FONT: Font = NUNITO_FONT


static func label(text_value: String, size_value: int, color := INK, display := false) -> Label:
	var node := Label.new()
	node.text = text_value
	node.add_theme_font_override("font", DISPLAY_FONT if display else BODY_FONT)
	node.add_theme_font_size_override("font_size", size_value)
	node.add_theme_color_override("font_color", color)
	node.set_meta("ui_display", display)
	node.set_meta("ui_base_font_size", size_value)
	return node


static func panel(color := Color(0.91, 0.85, 0.71, 0.97), radius := 18, border := Color(0.2, 0.3, 0.22, 0.5), shadow := true) -> PanelContainer:
	var node := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	if shadow:
		style.shadow_color = Color(0.05, 0.08, 0.06, 0.38)
		style.shadow_size = 13
		style.shadow_offset = Vector2(0, 6)
	node.add_theme_stylebox_override("panel", style)
	return node


static func button(text_value: String, accent := false, compact := false) -> Button:
	var node := Button.new()
	node.text = text_value
	node.custom_minimum_size.y = 45 if compact else 56
	node.add_theme_font_override("font", DISPLAY_FONT)
	node.add_theme_font_size_override("font_size", 15 if compact else 18)
	node.set_meta("ui_display", true)
	node.set_meta("ui_base_font_size", 15 if compact else 18)
	node.add_theme_color_override("font_color", Color("fff8df") if not accent else Color("3c321d"))
	node.add_theme_color_override("font_hover_color", Color.WHITE if not accent else Color("2a2417"))
	node.add_theme_stylebox_override("normal", _texture_box(YELLOW_NORMAL if accent else GREEN_NORMAL, Color("e3b34d") if accent else Color("557c59")))
	node.add_theme_stylebox_override("hover", _texture_box(YELLOW_HOVER if accent else GREEN_HOVER, Color("f0c45e") if accent else Color("6a986b")))
	node.add_theme_stylebox_override("pressed", _texture_box(YELLOW_NORMAL if accent else GREEN_NORMAL, Color("c9993d") if accent else Color("3f6545"), 3))
	node.add_theme_stylebox_override("disabled", _texture_box(GREY_NORMAL, Color(0.43, 0.47, 0.43, 0.72)))
	return node


static func set_font_profile(profile: int) -> void:
	match profile:
		1:
			DISPLAY_FONT = NUNITO_FONT
			BODY_FONT = NUNITO_FONT
		2:
			DISPLAY_FONT = LORA_FONT
			BODY_FONT = NUNITO_FONT
		3:
			DISPLAY_FONT = ATKINSON_BOLD
			BODY_FONT = ATKINSON_REGULAR
		_:
			DISPLAY_FONT = FRAUNCES_FONT
			BODY_FONT = NUNITO_FONT


static func apply_typography(root: Node, font_scale := 1.0) -> void:
	if root is Control and root.has_meta("ui_base_font_size"):
		var control := root as Control
		var display := bool(control.get_meta("ui_display", false))
		control.add_theme_font_override("font", DISPLAY_FONT if display else BODY_FONT)
		control.add_theme_font_size_override("font_size", maxi(10, int(float(control.get_meta("ui_base_font_size")) * font_scale)))
	for child in root.get_children():
		apply_typography(child, font_scale)


static func wire_button_sound(button_node: Button, host: Node) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = CLICK_SOUND
	player.volume_db = -9.0
	host.add_child(player)
	button_node.pressed.connect(player.play)


static func progress(fill_color: Color, height := 10) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.max_value = 100.0
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.12, 0.18, 0.14, 0.7)
	background.set_corner_radius_all(height / 2)
	var fill := background.duplicate() as StyleBoxFlat
	fill.bg_color = fill_color
	fill.border_color = fill_color.lightened(0.18)
	fill.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func badge(text_value: String, color := MOSS) -> PanelContainer:
	var badge_panel := panel(color, 12, color.lightened(0.16), false)
	var badge_label := label(text_value, 13, CREAM, true)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_panel.add_child(badge_label)
	return badge_panel


static func divider(color := Color(0.3, 0.39, 0.29, 0.45)) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size = Vector2(0, 2)
	return rule


static func _texture_box(texture: Texture2D, tint: Color, pressed_offset := 0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 11.0)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 9 + pressed_offset
	style.content_margin_bottom = 12 - pressed_offset
	return style
