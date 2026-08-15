class_name GrassVisualFactory
extends RefCounted

const LOD_HIGH := 0
const LOD_MEDIUM := 1
const LOD_LOW := 2
const READY_GRASS_PATHS := [
	"res://assets/third_party/quaternius_stylized_nature/Grass_Common_Short.gltf",
	"res://assets/third_party/quaternius_stylized_nature/Grass_Common_Tall.gltf",
	"res://assets/third_party/quaternius_stylized_nature/Grass_Wispy_Short.gltf",
	"res://assets/third_party/quaternius_stylized_nature/Grass_Wispy_Tall.gltf",
]

static var _cluster_meshes: Dictionary = {}
static var _grass_shader: Shader
static var _material_cache: Dictionary = {}


static func get_cluster_mesh(lod_level := LOD_MEDIUM, ready_variant := 0) -> ArrayMesh:
	var safe_level := clampi(lod_level, LOD_HIGH, LOD_LOW)
	var safe_variant := clampi(ready_variant, 0, READY_GRASS_PATHS.size()) if safe_level == LOD_HIGH else 0
	var cache_key := Vector2i(safe_level, safe_variant)
	if _cluster_meshes.has(cache_key):
		return _cluster_meshes[cache_key] as ArrayMesh
	var mesh := _load_ready_grass_mesh(safe_variant - 1) if safe_variant > 0 else _build_cluster_mesh(safe_level)
	if mesh == null:
		mesh = _build_cluster_mesh(safe_level)
	_cluster_meshes[cache_key] = mesh
	return mesh


static func _load_ready_grass_mesh(path_index: int) -> ArrayMesh:
	var packed := load(READY_GRASS_PATHS[path_index]) as PackedScene
	if packed == null:
		return null
	var root := packed.instantiate()
	var pending: Array[Node] = [root]
	var result: ArrayMesh
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D and (current as MeshInstance3D).mesh is ArrayMesh:
			result = (current as MeshInstance3D).mesh.duplicate(true) as ArrayMesh
			break
		for child in current.get_children():
			pending.append(child)
	root.free()
	return result


static func create_grass_material(base_color: Color, tip_color: Color) -> ShaderMaterial:
	var cache_key := "%s_%s" % [base_color.to_html(), tip_color.to_html()]
	if _material_cache.has(cache_key):
		return _material_cache[cache_key] as ShaderMaterial
	if _grass_shader == null:
		_grass_shader = Shader.new()
		_grass_shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform vec4 base_color : source_color = vec4(0.12, 0.31, 0.08, 1.0);
uniform vec4 tip_color : source_color = vec4(0.38, 0.69, 0.18, 1.0);
uniform vec4 cut_color : source_color = vec4(0.32, 0.37, 0.12, 1.0);
uniform float wind_strength : hint_range(0.0, 0.25) = 0.082;
uniform vec3 interactor_position = vec3(0.0);
uniform float interaction_radius : hint_range(0.1, 3.0) = 1.35;
uniform float interaction_strength : hint_range(0.0, 0.8) = 0.34;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;

varying float blade_height;
varying float blade_variation;
varying float blade_tone;
varying float blade_cut;
varying float blade_shape;

void vertex() {
	blade_height = clamp(VERTEX.y / 1.08, 0.0, 1.0);
	blade_cut = INSTANCE_CUSTOM.r;
	blade_variation = INSTANCE_CUSTOM.g;
	blade_tone = INSTANCE_CUSTOM.b;
	blade_shape = INSTANCE_CUSTOM.a;
	float alive = 1.0 - blade_cut;
	float signed_shape = blade_shape * 2.0 - 1.0;
	float shape_angle = blade_shape * 6.2831853 + blade_variation * 2.1;
	vec2 shape_direction = vec2(cos(shape_angle), sin(shape_angle));
	float mid_curve = sin(blade_height * 3.1415926);
	float tip_curl = blade_height * blade_height * blade_height;
	VERTEX.xz += shape_direction * (mid_curve * signed_shape * 0.045 + tip_curl * signed_shape * 0.07);
	vec3 world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float breeze = sin(TIME * 1.38 + world_origin.x * 0.31 + world_origin.z * 0.23);
	float crosswind = sin(TIME * 0.77 - world_origin.x * 0.16 + world_origin.z * 0.12);
	float gust = sin(TIME * 0.49 + world_origin.x * 0.065 - world_origin.z * 0.09) * 0.38 + 0.62;
	vec2 wind_direction = normalize(vec2(0.82, 0.48) + vec2(crosswind * 0.12, -crosswind * 0.08));
	VERTEX.xz += wind_direction * breeze * gust * wind_strength * blade_height * blade_height * alive;

	vec2 interaction_delta = world_origin.xz - interactor_position.xz;
	float interaction_distance = length(interaction_delta);
	vec2 interaction_direction = interaction_distance > 0.001 ? interaction_delta / interaction_distance : vec2(1.0, 0.0);
	float interaction = 1.0 - smoothstep(interaction_radius * 0.22, interaction_radius, interaction_distance);
	VERTEX.xz += interaction_direction * interaction * interaction_strength * blade_height * blade_height * alive;
	VERTEX.y *= mix(1.0, 0.075, blade_cut);
}

void fragment() {
	vec3 living = mix(base_color.rgb * 0.72, tip_color.rgb, smoothstep(0.0, 1.0, blade_height));
	living *= mix(0.88, 1.08, blade_variation);
	living = mix(living, living * vec3(0.86, 1.02, 0.89), blade_tone * 0.24);
	ALBEDO = mix(living, cut_color.rgb, blade_cut);
	ROUGHNESS = mix(0.92, 0.48, wetness);
	SPECULAR = mix(0.14, 0.34, wetness);
	AO = mix(0.55, 1.0, blade_height);
	AO_LIGHT_AFFECT = 0.28;
	BACKLIGHT = living * 0.14 * (1.0 - blade_cut);
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.24));
}
"""
	var material := ShaderMaterial.new()
	material.shader = _grass_shader
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("tip_color", tip_color)
	_material_cache[cache_key] = material
	return material


static func set_interactor_position(world_position: Vector3) -> void:
	for cached_material: Variant in _material_cache.values():
		(cached_material as ShaderMaterial).set_shader_parameter("interactor_position", world_position)


static func set_wetness(value: float) -> void:
	var safe_value := clampf(value, 0.0, 1.0)
	for cached_material: Variant in _material_cache.values():
		(cached_material as ShaderMaterial).set_shader_parameter("wetness", safe_value)


static func _build_cluster_mesh(lod_level: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	if lod_level == LOD_HIGH:
		var high_blades := [
			[0.00, 0.00, 0.00, 0.046, 1.08, 0.14],
			[0.90, 0.09, 0.02, 0.041, 0.88, 0.11],
			[1.82, -0.06, 0.08, 0.050, 0.96, 0.16],
			[2.72, -0.10, -0.03, 0.038, 0.78, 0.10],
			[3.62, 0.03, -0.10, 0.044, 0.91, 0.13],
			[4.53, 0.12, -0.06, 0.036, 0.73, 0.09],
			[5.42, 0.06, 0.11, 0.047, 0.84, 0.12],
		]
		for blade: Array in high_blades:
			_append_blade(vertices, normals, uvs, indices, float(blade[0]), Vector3(float(blade[1]), 0.0, float(blade[2])), float(blade[3]), float(blade[4]), 4, float(blade[5]))
	elif lod_level == LOD_MEDIUM:
		for blade: Array in [
			[0.0, 0.02, 0.01, 0.058, 0.94, 0.11],
			[2.1, -0.05, 0.06, 0.052, 0.78, 0.09],
			[4.2, 0.07, -0.05, 0.055, 0.86, 0.10],
		]:
			_append_blade(vertices, normals, uvs, indices, float(blade[0]), Vector3(float(blade[1]), 0.0, float(blade[2])), float(blade[3]), float(blade[4]), 2, float(blade[5]))
	else:
		_append_blade(vertices, normals, uvs, indices, 0.0, Vector3.ZERO, 0.105, 0.83, 1, 0.04)
		_append_blade(vertices, normals, uvs, indices, PI * 0.5, Vector3.ZERO, 0.095, 0.76, 1, 0.03)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _append_blade(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	angle: float,
	offset: Vector3,
	half_width: float,
	height: float,
	segments: int,
	lean: float
) -> void:
	var right := Vector3(cos(angle), 0.0, sin(angle))
	var lean_direction := Vector3(cos(angle + 0.67), 0.0, sin(angle + 0.67))
	var normal := Vector3(-right.z, 0.22, right.x).normalized()
	var base_index := vertices.size()
	for row in range(segments + 1):
		var t := float(row) / float(segments)
		var center := offset + Vector3.UP * height * t + lean_direction * lean * t * t
		var width := half_width * lerpf(1.0, 0.08, t)
		vertices.append(center - right * width)
		vertices.append(center + right * width)
		normals.append(normal)
		normals.append(normal)
		uvs.append(Vector2(0.0, t))
		uvs.append(Vector2(1.0, t))
	for segment in range(segments):
		var current := base_index + segment * 2
		indices.append_array(PackedInt32Array([
			current, current + 1, current + 3,
			current, current + 3, current + 2,
		]))
