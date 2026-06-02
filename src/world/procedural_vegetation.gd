class_name ProceduralVegetation
extends Node3D

const WORLD_PROFILE_SCRIPT = preload("res://src/world/world_profile.gd")
const FOLIAGE_SHADER = preload("res://shaders/foliage_wind.gdshader")
const SOLID_SHADER = preload("res://shaders/solid_painterly.gdshader")

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_size: float = 64.0
var world_profile: RefCounted
var seed: int = 0
var lod_level: int = 0
var _build_visuals: bool = true

var _tree_material: ShaderMaterial
var _trunk_material: ShaderMaterial
var _grass_material: ShaderMaterial
var _reed_material: ShaderMaterial
var _bush_material: ShaderMaterial
var _rock_material: ShaderMaterial
var _flower_material: ShaderMaterial

var _generated_transforms: Dictionary = {
	"grass": [],
	"flowers": [],
	"reeds": [],
	"bushes": [],
	"rocks": [],
	"trees_leaves": [],
	"trees_trunks": [],
	"distant_canopies": []
}

var _metrics: Dictionary = {
	"grass": 0,
	"flowers": 0,
	"trees": 0,
	"crowns": 0,
	"reeds": 0,
	"bushes": 0,
	"rocks": 0,
	"distant_canopies": 0,
	"max_tree_height": 0.0,
}

var _is_data_ready: bool = false


func setup(p_chunk_coord: Vector2i, p_chunk_size: float, p_world_profile: RefCounted, p_seed: int, p_lod_level: int, p_build_visuals: bool = true) -> void:
	chunk_coord = p_chunk_coord
	chunk_size = p_chunk_size
	world_profile = p_world_profile
	seed = p_seed
	lod_level = p_lod_level
	_build_visuals = p_build_visuals
	position = Vector3.ZERO


# Executado em Background recebendo referências de dados de faces do TerrainChunk correspondente
func generate_vegetation_from_faces(faces_pos: PackedVector3Array, faces_norm: PackedVector3Array) -> void:
	if faces_pos.is_empty():
		_is_data_ready = true
		return

	_scatter_on_faces(faces_pos, faces_norm)
	_is_data_ready = true


func _scatter_on_faces(faces_pos: PackedVector3Array, faces_norm: PackedVector3Array) -> void:
	var grass_transforms: Array[Transform3D] = []
	var flower_transforms: Array[Transform3D] = []
	var tree_trunk_transforms: Array[Transform3D] = []
	var tree_leaf_transforms: Array[Transform3D] = []
	var bush_transforms: Array[Transform3D] = []
	var rock_transforms: Array[Transform3D] = []
	
	var total_triangles: int = faces_pos.size() / 3
	var max_tree_height: float = 0.0

	for t: int in range(total_triangles):
		var idx: int = t * 3
		var v0: Vector3 = faces_pos[idx]
		var v1: Vector3 = faces_pos[idx + 1]
		var v2: Vector3 = faces_pos[idx + 2]
		var normal: Vector3 = faces_norm[idx]

		# Determinar ponto central do triângulo para controle probabilístico de sementes
		var center: Vector3 = (v0 + v1 + v2) / 3.0
		var world_x: float = float(chunk_coord.x) * chunk_size + center.x
		var world_z: float = float(chunk_coord.y) * chunk_size + center.z
		
		var sample: Dictionary = world_profile.sample_world(world_x, world_z)
		var biome: int = int(sample["biome"])
		var slope: float = float(sample["slope"])
		var fertility: float = float(sample["fertility"])
		var moisture: float = float(sample["moisture"])

		# 1. Algoritmo de Distribuição Baricêntrica para Grama e Flores (Densidade Alta e Uniforme)
		var grass_density: int = 12 if lod_level == 0 else (5 if lod_level == 1 else 0)
		if biome == WORLD_PROFILE_SCRIPT.Biome.MEADOW or biome == WORLD_PROFILE_SCRIPT.Biome.FOREST:
			for g: int in range(grass_density):
				var r1: float = _hash_unit(t, g, 101)
				var r2: float = _hash_unit(t, g, 202)
				if (r1 + r2) > 1.0:
					r1 = 1.0 - r1
					r2 = 1.0 - r2
				var p: Vector3 = (1.0 - r1 - r2) * v0 + r1 * v1 + r2 * v2
				
				var scale_y: float = (0.35 + moisture * 0.40 + _hash_unit(t, g, 303) * 0.3) * 0.5
				var scale_xz: float = (0.60 + _hash_unit(t, g, 404) * 0.3) * 0.4
				var basis: Basis = Basis(Vector3.UP, _hash_unit(t, g, 505) * TAU).scaled(Vector3(scale_xz, scale_y, scale_xz))
				grass_transforms.append(Transform3D(basis, p + Vector3(0, 0.02, 0)))

		# 2. Distribuição Estreita para Árvores Majestosas com Galhos Estruturados
		if biome == WORLD_PROFILE_SCRIPT.Biome.FOREST and slope < 0.35 and t % 17 == 0:
			if _hash_unit(t, 99, 777) < 0.65 + fertility * 0.30:
				var tree_scale: float = 1.8 + _hash_unit(t, 1, 888) * 1.6
				var trunk_height: float = 26.0 + tree_scale * 7.0
				var yaw: float = _hash_unit(t, 2, 999) * TAU
				var trunk_radius: float = 1.6 + _hash_unit(t, 3, 111) * 0.6
				
				max_tree_height = maxf(max_tree_height, trunk_height + 15.0)
				var trunk_basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3(trunk_radius, trunk_height, trunk_radius))
				tree_trunk_transforms.append(Transform3D(trunk_basis, center))

				# Adição de Copas e Galhos Secundários nas extremidades superiores
				for b_idx: int in range(4):
					var branch_angle: float = yaw + float(b_idx) * (TAU / 4.0) + (_hash_unit(t, b_idx, 55) * 0.5)
					var branch_dist: float = 2.5 + _hash_unit(t, b_idx, 66) * 3.0
					var b_x: float = center.x + cos(branch_angle) * branch_dist
					var b_z: float = center.z + sin(branch_angle) * branch_dist
					var b_y: float = center.y + trunk_height * 0.65 + float(b_idx) * 2.5
					
					var c_size: float = 12.0 + _hash_unit(t, b_idx, 77) * 6.0
					var leaf_basis: Basis = Basis(Vector3.UP, branch_angle).scaled(Vector3(c_size, c_size * 0.8, c_size))
					tree_leaf_transforms.append(Transform3D(leaf_basis, Vector3(b_x, b_y, b_z)))

	_metrics["grass"] = grass_transforms.size()
	_metrics["trees"] = tree_trunk_transforms.size()
	_metrics["max_tree_height"] = max_tree_height
	
	_generated_transforms["grass"] = grass_transforms
	_generated_transforms["trees_trunks"] = tree_trunk_transforms
	_generated_transforms["trees_leaves"] = tree_leaf_transforms


func finalize_vegetation_on_main_thread() -> void:
	if not _is_data_ready:
		return
		
	if _build_visuals:
		_create_materials()
		
		var typed_grass: Array[Transform3D] = []
		typed_grass.assign(_generated_transforms["grass"])
		_create_multimesh("GrassTufts", _make_grass_mesh(), _grass_material, typed_grass)
		
		var typed_trunks: Array[Transform3D] = []
		typed_trunks.assign(_generated_transforms["trees_trunks"])
		_create_multimesh("TreeTrunks", _make_branchy_trunk_mesh(), _trunk_material, typed_trunks)
		
		var typed_leaves: Array[Transform3D] = []
		typed_leaves.assign(_generated_transforms["trees_leaves"])
		_create_multimesh("TreeCrowns", _make_crown_mesh(), _tree_material, typed_leaves)


func _create_materials() -> void:
	_tree_material = _make_foliage_material(Color(0.16, 0.44, 0.20), 0.12, 0.30, 1.0)
	_grass_material = _make_foliage_material(Color(0.28, 0.58, 0.18), 0.20, 0.65, 0.0)
	_trunk_material = _make_solid_material(Color(0.32, 0.22, 0.12))


func _make_foliage_material(color: Color, wind_strength: float, wind_speed: float, spherical_normal_strength: float) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FOLIAGE_SHADER
	material.set_shader_parameter("foliage_color", color)
	material.set_shader_parameter("wind_strength", wind_strength)
	material.set_shader_parameter("wind_speed", wind_speed)
	material.set_shader_parameter("spherical_normal_strength", spherical_normal_strength)
	return material


func _make_solid_material(color: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SOLID_SHADER
	material.set_shader_parameter("albedo_color", color)
	return material


func _create_multimesh(node_name: String, source_mesh: Mesh, material: Material, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = source_mesh
	multimesh.instance_count = transforms.size()
	for index: int in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	add_child(instance)


func _make_grass_mesh() -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade_index: int in range(3):
		var yaw: float = float(blade_index) * TAU / 3.0
		var right: Vector3 = Vector3(cos(yaw), 0.0, sin(yaw)) * 0.34
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		var a: Vector3 = -right
		var b: Vector3 = right
		var c: Vector3 = right * 0.52 + up
		var d: Vector3 = -right * 0.52 + up
		_add_leaf_quad(surface_tool, a, b, c, d)
	surface_tool.generate_normals()
	return surface_tool.commit()


# Criação procedural de Troncos Majestosos com Galhos estruturais salientes externos
func _make_branchy_trunk_mesh() -> ArrayMesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 8
	var rings: int = 6
	
	for ring_index: int in range(rings + 1):
		var t: float = float(ring_index) / float(rings)
		var radius: float = lerpf(0.45, 0.15, t)
		var y: float = t
		
		for segment_index: int in range(segments):
			var angle: float = float(segment_index) * TAU / float(segments)
			
			# Modulação para forçar protuberâncias de galhos físicos nos anéis superiores
			var branch_extinction: float = 0.0
			if ring_index > 3:
				branch_extinction = sin(angle * 3.0 + t * 10.0) * 0.18 * (t - 0.4)
				
			var rx: float = cos(angle) * (radius + branch_extinction)
			var rz: float = sin(angle) * (radius + branch_extinction)
			surface_tool.add_vertex(Vector3(rx, y, rz))

	for ring_index: int in range(rings):
		for segment_index: int in range(segments):
			var next_segment: int = (segment_index + 1) % segments
			var a: int = ring_index * segments + segment_index
			var b: int = ring_index * segments + next_segment
			var c: int = (ring_index + 1) * segments + segment_index
			var d: int = (ring_index + 1) * segments + next_segment
			surface_tool.add_index(a); surface_tool.add_index(c); surface_tool.add_index(b)
			surface_tool.add_index(b); surface_tool.add_index(c); surface_tool.add_index(d)

	surface_tool.generate_normals()
	return surface_tool.commit()


func _make_crown_mesh() -> ArrayMesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for plane_index: int in range(4):
		var yaw: float = float(plane_index) * TAU / 4.0
		var right: Vector3 = Vector3(cos(yaw), 0.0, sin(yaw))
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		_add_leaf_quad(surface_tool, -right - up * 0.5, right - up * 0.5, right * 0.8 + up * 0.8, -right * 0.8 + up * 0.8)
	surface_tool.generate_normals()
	return surface_tool.commit()


func _add_leaf_quad(surface_tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface_tool.add_vertex(a); surface_tool.add_vertex(b); surface_tool.add_vertex(c)
	surface_tool.add_vertex(a); surface_tool.add_vertex(c); surface_tool.add_vertex(d)
	surface_tool.add_vertex(c); surface_tool.add_vertex(b); surface_tool.add_vertex(a)
	surface_tool.add_vertex(d); surface_tool.add_vertex(c); surface_tool.add_vertex(a)


func _hash_unit(x_index: int, z_index: int, salt: int) -> float:
	var hash: int = int(chunk_coord.x * 73856093) ^ int(chunk_coord.y * 19349663) ^ int(x_index * 83492791) ^ int(z_index * 2654435761) ^ int(seed + salt * 374761393)
	hash = (hash ^ (hash >> 13)) * 1274126177
	hash = hash ^ (hash >> 16)
	return float(hash & 0xffff) / 65535.0
