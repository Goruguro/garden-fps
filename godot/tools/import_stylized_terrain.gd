extends SceneTree

const OUTPUT_SIZE := 2048
const SOURCE_ROOT := "res://.downloads/stylized_sources"
const OUTPUT_ROOT := "res://assets/third_party/stylized_textures/terrain"
const MATERIALS := [
	"Stylized_Grass_001",
	"Stylized_Grass_002",
	"Stylized_Grass_003",
	"Stylized_Ground_002",
	"Stylized_Dry_Mud_001",
	"Stylized_Rocks_001",
	"Stylized_Rocks_003",
	"Stylized_Ice_001",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	for material_name: String in MATERIALS:
		var target_name := material_name.to_snake_case()
		_import_map(material_name, "basecolor", target_name + "_albedo.png")
		_import_map(material_name, "normal", target_name + "_normal.png")
	quit()


func _import_map(material_name: String, map_name: String, output_name: String) -> void:
	var output_path := "%s/%s" % [OUTPUT_ROOT, output_name]
	if FileAccess.file_exists(output_path):
		print("STYLIZED_TERRAIN_SKIPPED ", output_path)
		return
	var source_path := "%s/%s/%s.png" % [SOURCE_ROOT, material_name, map_name]
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		push_error("Stilistik zemin kaynağı okunamadı: %s" % source_path)
		return
	if image.get_width() != OUTPUT_SIZE or image.get_height() != OUTPUT_SIZE:
		image.resize(OUTPUT_SIZE, OUTPUT_SIZE, Image.INTERPOLATE_LANCZOS)
	var error := image.save_png(output_path)
	if error != OK:
		push_error("Stilistik zemin çıktısı yazılamadı: %s" % output_path)
	else:
		print("STYLIZED_TERRAIN_IMPORTED ", output_path, " ", image.get_size())
